---
name: omb-cleanup
user-invocable: true
description: >
  (omb) Use when cleaning up stale pipeline session files, exiting a worktree after work is done,
  or resetting the workspace to a clean state. Triggers on: cleanup, clean, tidy, reset workspace,
  exit worktree, done with worktree, stale pipelines, clean sessions.
argument-hint: ""
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

## OMB Cleanup — Pipeline Session State and Worktree Cleanup

This skill cleans up stale pipeline session files and exits worktrees safely.

### HARD RULES

- [HARD] NEVER archive or modify unrelated active pipelines. Only clean up the pipeline the user explicitly named or the one that just completed in this session.
- [HARD] NEVER modify session files that belong to pipelines the user did not specifically target. If multiple active pipelines exist, you MUST use AskUserQuestion to ask the user which one(s) to clean — listing each by ID, name, and current step.
- [HARD] Active pipelines with `status: "active"` or `status: "paused"` are UNTOUCHABLE unless the user names them explicitly by ID.
- [HARD] When completing a pipeline from this session, ONLY archive THAT specific pipeline by ID. Do NOT touch any other active pipeline even if it looks stale.
- [HARD] Before ANY action on active pipelines, read `.omb/sessions/*.json` directly and present the full list to the user. Confirm which specific pipeline(s) the user wants cleaned.

### Overview

Two independent cleanup operations, executed in order:

1. **Worktree cleanup** — if currently on a worktree, safely exit and return to main
2. **Session state cleanup** — move stale pipeline session files from `.omb/sessions/` to `finished/`

Both operations are safe — they check preconditions before acting and ask the user when destructive choices are needed.

---

### Step 1: Detect Worktree

Check if the current working directory is inside a git worktree:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && git worktree list --porcelain 2>/dev/null | head -20
```

Also check the current branch:

```bash
git branch --show-current 2>/dev/null
```

**Decision logic:**
- If the current branch starts with `worktree/` OR the CWD is inside `worktrees/`, proceed to Step 2 (worktree cleanup).
- Otherwise, skip to Step 3 (session state cleanup).

### Step 2: Worktree Cleanup (Safe-Exit Flow)

Four sub-steps, executed in order. Each sub-step has a gate — if the gate fails, the flow stops and asks the user before proceeding.

#### 2a: Check for uncommitted changes

```bash
git status --porcelain 2>/dev/null
```

**If output is non-empty** (uncommitted changes exist):

Use `AskUserQuestion` with these options:

| Option | Description |
|--------|-------------|
| **Stash changes** | Save to git stash. Recoverable with `git stash pop`. |
| **Commit changes** | Create a commit on the worktree branch before cleanup. |
| **Discard changes** | Throw away all uncommitted changes. Irreversible. |
| *(Other)* | User provides custom instructions. |

Execute the user's choice:
- **Stash**: `git stash push -m "omb-cleanup: stashed from worktree $(git branch --show-current)"`
- **Commit**: `git add -A && git commit -m "chore: save work before worktree cleanup\n\nCo-Authored-By: Braincrew(dev@brain-crew.com)"`
- **Discard**: `git checkout -- . && git clean -fd`

**If output is empty**, proceed to 2b.

#### 2b: Find associated plan file

Identify the worktree branch and trace it back to a pipeline + plan:

```bash
WORKTREE_BRANCH=$(git branch --show-current)
```

Search pipeline state files (both active/ and finished/) for a matching branch or context:

```bash
grep -rl "$WORKTREE_BRANCH" .omb/sessions/finished/ 2>/dev/null
grep -rl "$WORKTREE_BRANCH" .omb/sessions/ 2>/dev/null
```

If no direct branch match, extract the worktree timestamp suffix (e.g., `wt-1774692357356` from `worktree/wt-1774692357356`) and search pipeline IDs:

```bash
WT_ID=$(echo "$WORKTREE_BRANCH" | sed 's/worktree\/wt-//')
grep -rl "$WT_ID" .omb/sessions/finished/ .omb/sessions/ 2>/dev/null
```

If a matching pipeline JSON is found, read the `plan_file` field:

```bash
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('plan_file',''))" "<matched-pipeline>.json"
```

**Decision logic:**

| Result | Action |
|--------|--------|
| `plan_file` found and file exists | Report: "This worktree is associated with plan: `<plan_file>`". Proceed to 2c. |
| `plan_file` found but file missing | Warn: "Plan file `<path>` referenced but not found on disk." Proceed to 2c (PR check is still valuable). |
| No matching pipeline found | Warn: "No pipeline state found for this worktree branch." Use `AskUserQuestion`: "No plan file associated with this worktree. Proceed with removal anyway?" |
| Pipeline found but `plan_file` is empty | Warn: "Pipeline exists but no plan file was generated (e.g., pipeline was cancelled early)." Proceed to 2c. |

#### 2c: Check if PR is merged to main

Using the worktree branch, check for an associated PR and its merge status:

```bash
gh pr list --head "$WORKTREE_BRANCH" --state merged --json number,title,mergedAt --limit 1
```

**Decision logic:**

| Result | Action |
|--------|--------|
| Merged PR found | Report: "PR #N `<title>` was merged on `<date>`." Safe to remove — proceed to 2d. |
| No merged PR, but open PR exists | Run `gh pr list --head "$WORKTREE_BRANCH" --state open --json number,title,url --limit 1`. Warn: "PR #N is still OPEN: `<url>`". Use `AskUserQuestion`: "PR is not yet merged. Remove worktree anyway?" |
| No PR at all | Warn: "No PR found for branch `$WORKTREE_BRANCH`." Use `AskUserQuestion`: "No PR was created from this worktree. Remove worktree anyway?" |
| `gh` CLI unavailable | Warn: "Cannot check PR status — `gh` CLI not found or not authenticated." Use `AskUserQuestion`: "Skip PR verification and proceed with removal?" |

#### 2d: Checkout to main and remove worktree

Identify paths from `git worktree list`:

```bash
git worktree list
```

Record:
- `MAIN_PATH` — the main working tree path (first entry)
- `WORKTREE_PATH` — the current worktree path (CWD)

Execute:

```bash
cd "$MAIN_PATH"
git checkout main
git worktree remove "$WORKTREE_PATH"
```

If `git worktree remove` fails, do NOT use `--force`. Report the error and ask the user.

After successful removal, confirm:
- Which worktree was removed and its path
- Which branch it was on (branch is NOT deleted — only the worktree link)
- Plan file association (if found in 2b)
- PR merge status (if checked in 2c)
- That CWD is now the main working tree on `main` branch

### Step 3: Session State Cleanup

#### 3a: List ALL pipelines (mandatory before any action)

Read every JSON file in `.omb/sessions/` (excluding `finished/`) directly:

```bash
ls .omb/sessions/*.json 2>/dev/null
```

For each file found, extract key fields:

```bash
python3 -c "
import json, sys, glob
for f in sorted(glob.glob('.omb/sessions/*.json')):
    try:
        d = json.load(open(f))
        print(f\"{f}: id={d.get('id','?')} name={d.get('name','?')} status={d.get('status','?')} step={d.get('current_step','?')}\")
    except Exception as e:
        print(f\"{f}: malformed — {e}\")
"
```

Present the FULL pipeline list to the user. Count how many have `active` or `paused` status.

**If 2+ active/paused pipelines exist:** You MUST use `AskUserQuestion` to confirm which specific pipeline(s) the user wants cleaned. Show each pipeline's ID, name, status, and current step. Do NOT assume — the user may have multiple concurrent workstreams.

#### 3b: Check active directory for orphaned state files

```bash
ls -la .omb/sessions/ 2>/dev/null
```

If the directory is empty or doesn't exist, report "No active pipeline state files found" and finish.

#### 3c: Identify stale pipelines

For each JSON file in `.omb/sessions/`, read the file and check the `status` field:

| Status | Action |
|--------|--------|
| `completed` | Stale — should have been archived. Move to `finished/`. |
| `cancelled` | Stale — should have been archived. Move to `finished/`. |
| `stalled` | Stale — pipeline failed and needs manual intervention. Move to `finished/`. |
| `active` | **UNTOUCHABLE** — do NOT auto-move. Report to user. Only act if user explicitly names this pipeline. |
| `paused` | **UNTOUCHABLE** — pipeline is waiting for user approval. Leave it. Report to user. |

**Critical:** `active` pipelines are NEVER auto-cleaned, even if `updated_at` is old. They may be from a different session or a different user's work. Always ask.

#### 3c: Move stale files

For each stale file identified:

```bash
mkdir -p .omb/sessions/finished/
mv .omb/sessions/<filename>.json .omb/sessions/finished/
```

#### 3d: Remove stale lock files

The `omb advance` CLI creates `.lock` files in `.omb/sessions/` to prevent concurrent state modifications. These are 0-byte files that accumulate over time and are never auto-cleaned.

```bash
ls .omb/sessions/*.lock 2>/dev/null | wc -l
```

If lock files exist:
- Count them and report: "Found N stale lock files"
- Delete all lock files — they are safe to remove when no pipeline is actively advancing:

```bash
rm .omb/sessions/*.lock 2>/dev/null
```

Lock files whose corresponding session JSON has been archived to `finished/` or deleted are always safe to remove. Lock files for active sessions are also safe because the lock is only held during the brief `omb advance` CLI execution (not across sessions).

#### 3e: Check for legacy root files

Also check for any JSON files directly in `.omb/sessions/` (not in finished/ subdirectory):

```bash
ls .omb/sessions/*.json 2>/dev/null
```

If found, these are legacy files that should be archived. Move them to `finished/`:

```bash
mv .omb/sessions/<filename>.json .omb/sessions/finished/
```

### Step 4: Report

Print a summary of what was cleaned up:

```
## Cleanup Summary

### Worktree
- [Removed worktree at worktrees/wt-XXXXX (branch: worktree/wt-XXXXX)]
- [Associated plan: .omb/plans/<session_id>.md] OR [No plan file found]
- [PR #N merged on YYYY-MM-DD] OR [PR #N still open] OR [No PR found]
  OR
- [No worktree detected — skipped]

### Session Pipelines
- Moved N stale session file(s) to .omb/sessions/finished/
- Moved N legacy file(s) from .omb/sessions/ root to finished/
- Removed N stale lock file(s)
- N active/paused pipeline(s) left untouched
  OR
- No stale pipeline session files found
```

### Error Recovery

- **Worktree remove fails**: Do NOT use `--force`. Report the error and ask the user.
- **State file is malformed JSON**: Report the filename and skip it. Do not move broken files.
- **Permission errors**: Report and skip. Do not escalate to sudo or chmod.

### What This Skill Does NOT Do

- [HARD] Does NOT archive or touch unrelated active/paused pipeline session files — only the one the user explicitly targets by ID.
- [HARD] Does NOT assume which pipeline to clean when multiple active pipelines exist. Always reads `.omb/sessions/*.json` directly and asks the user first, showing each pipeline's ID, name, and current step.
- [HARD] Does NOT assume a pipeline is "stale" based on age alone. An active pipeline from yesterday may still be valid work-in-progress from a different session.
- Does NOT delete finished state files — they serve as audit trail.
- Does NOT delete worktree branches — only removes the worktree link.
- Does NOT touch `.omb/plans/`, `.omb/verifications/`, or other state directories.
