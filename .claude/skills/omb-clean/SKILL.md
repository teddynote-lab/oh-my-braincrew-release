---
name: omb-clean
description: "Worktree cleanup — remove worktrees, mark DONE in DB, optionally delete branches. Detects if running inside a worktree and runs a guided sequential cleanup flow."
user-invocable: true
argument-hint: "[<branch> | --all]"
---

# Worktree Cleanup

Remove completed or abandoned worktrees and update the DB. When invoked from inside a worktree, runs a guided sequential cleanup flow. When invoked from outside, accepts a branch argument or `--all`.

## Pre-execution Context

!`CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew worktree-status 2>/dev/null || echo "[]"`

## When to Use

- After a PR has been merged and the worktree is no longer needed
- To clean up abandoned worktrees
- To free disk space from stale worktrees
- User says "clean up", "remove worktree", or "I'm done with this branch"

## Arguments

`$ARGUMENTS`

## Execution

<execution_order>

### Step 0: Worktree Context Detection

**0a. Check if `$ARGUMENTS` is provided.** If the user passed a branch name or `--all`, skip context detection entirely and go directly to the **External Flow** — the user explicitly specified what to clean.

**0b. Detect CWD position.** Run:

```bash
pwd
```

Compare the output against `${CLAUDE_PROJECT_DIR}/worktrees/`. If the current working directory is **under** the `worktrees/` subdirectory, the session is inside a worktree. If not, go to the **External Flow**.

**0c. Get worktree details.** When inside a worktree (0b confirmed), invoke `Skill("omb-worktree")` with argument `"context"` to retrieve the active worktree's metadata: `branch`, `status`, `plan_file`, `todo_file`, `pr_url`. Proceed to the **Worktree-Internal Flow** (Steps 1–6 below).

If `Skill("omb-worktree") context` returns no matching record for the current worktree directory, treat this as the **DB record not found** case (Step 2A).

---

### Worktree-Internal Flow

Execute Steps 1–6 only when Step 0 determines the current session is inside a worktree.

#### Step 1: Display Current State

Show the user:

```
Current worktree: {branch} (status: {status})
PR: {pr_url or "none"}
```

#### Step 1.5: PR Status Check

If `pr_url` exists in the worktree context, check remote PR state:

```bash
gh pr view {pr_url} --json state,mergedAt 2>/dev/null
```

Record the result as `pr_state`:
- `"MERGED"` — PR was merged successfully
- `"OPEN"` — PR is still open
- `"CLOSED"` — PR was closed without merging
- `gh` command fails — set `pr_state` to `"UNKNOWN"`

If no `pr_url` exists, set `pr_state` to `"NONE"`.

Show the user: `"PR status: {pr_state}"`

#### Step 2: Status Branching

Branch based on the DB record and current status:

**A) DB record not found** (branch was not created via `omb:worktree`):

- Inform the user: "This branch has no record in the omb worktree DB."
- Ask the user (`AskUserQuestion`) with options:
  1. "Force cleanup — delete worktree directory only"
  2. "Cancel — keep current state"
- On option 1: skip to Step 5 (delete worktree directory only, no DB update).
- On option 2: stop.

**B) status == DONE**:

- If `pr_state` is `"MERGED"`: proceed directly to Step 4 (cleanup — no further verification needed).
- Otherwise: proceed to Step 3 (PR/merge verification).

**C) status is IDLE, PLAN, or PROGRESS**:

- Check for uncommitted changes:
  ```bash
  git status --porcelain
  ```
- If uncommitted changes exist, warn: "Uncommitted changes detected. Force cleanup will discard these changes."

**C1) If `pr_state` is `"MERGED"`:**

- Inform: "PR is already merged. Safe to clean up."
- Ask the user (`AskUserQuestion`) with options:
  1. "Cleanup — mark DONE and delete worktree"
  2. "Cancel — keep current state"
- On option 1: run `CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew worktree-update {branch} --status DONE`, then proceed to Step 4.
- On option 2: stop.

**C2) If `pr_state` is `"OPEN"`:**

- Warn: "PR is still open and not yet merged."
- Ask the user (`AskUserQuestion`) with options:
  1. "Force cleanup — discard work and delete worktree (PR stays open on GitHub)"
  2. "Cancel — keep working"
- On option 1: proceed to Step 5.
- On option 2: stop.

**C3) If `pr_state` is `"CLOSED"`, `"UNKNOWN"`, or `"NONE"`:**

- Ask the user (`AskUserQuestion`) with options:
  1. "Force cleanup — discard work and delete worktree"
  2. "Mark DONE then cleanup — update DB to DONE and proceed to Step 3"
  3. "Cancel — keep current state"
- On option 1: proceed to Step 5.
- On option 2: run `CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew worktree-update {branch} --status DONE`, then proceed to Step 3.
- On option 3: stop.

#### Step 3: PR/Merge Verification (when DONE, `pr_state` not yet MERGED)

Uses `pr_state` from Step 1.5 — no need to re-run `gh pr view`.

- **`pr_state` is `"MERGED"`:** proceed to Step 4.
- **`pr_state` is `"OPEN"` or `"CLOSED"`:** inform "PR state: {pr_state}." Ask the user (`AskUserQuestion`):
  1. "Wait — keep worktree as-is"
  2. "Force cleanup — delete worktree anyway"
  - On option 1: stop.
  - On option 2: proceed to Step 4.
- **`pr_state` is `"UNKNOWN"`:** inform "Cannot verify PR state." Ask the user (`AskUserQuestion`):
  1. "Force cleanup — delete worktree anyway"
  2. "Cancel — keep current state"
  - On option 1: proceed to Step 4.
  - On option 2: stop.
- **`pr_state` is `"NONE"`:** inform "No PR found." Ask the user (`AskUserQuestion`):
  1. "Cleanup without PR — delete worktree"
  2. "Cancel — keep current state"
  - On option 1: proceed to Step 4.
  - On option 2: stop.

#### Step 4: Navigate to Project Root

Run:

```bash
cd "${CLAUDE_PROJECT_DIR}"
pwd
```

Verify that the printed path matches `${CLAUDE_PROJECT_DIR}`. Note: `git checkout main` is NOT needed — worktrees and the main working tree are separate filesystem paths. Simply navigating to `${CLAUDE_PROJECT_DIR}` is sufficient.

#### Step 5: Delete Worktree

Check whether the worktree directory exists:

```bash
ls "${CLAUDE_PROJECT_DIR}/worktrees/{branch}" 2>/dev/null
```

**If the directory exists**, run the teardown via the unified hook dispatcher:

```bash
bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/omb/omb-hook.sh" WorktreeTeardown {branch} --delete-branch
```

Verify deletion:

```bash
! test -d "${CLAUDE_PROJECT_DIR}/worktrees/{branch}"
```

**If the directory does NOT exist** (stale DB record only), update the DB to DONE without filesystem operations:

```bash
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew worktree-update {branch} --status DONE
```

#### Step 6: Report Result

Show the user:

- The branch that was cleaned and its former path
- Updated worktree DB status:
  ```bash
  CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew worktree-status 2>/dev/null || echo "[]"
  ```
- "Cleanup complete."

---

### External Flow

Execute this flow only when Step 0 determines the current session is NOT inside a worktree.

1. **Parse arguments**:
   - `<branch>`: clean a specific worktree
   - `--all`: clean all worktrees with DONE status
   - (none): show active worktrees and ask which to clean

2. **If specific branch**:
   a. Look up the branch in the pre-execution context.
   b. Warn if status is PROGRESS (work may be in flight).
   c. Confirm with the user: "Remove worktree `<branch>` and delete the branch? [yes/no]"
   d. On confirmation, run:
      ```bash
      echo '{}' | CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}" uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew WorktreeTeardown <branch> --delete-branch
      ```
   e. Verify CWD is not inside the removed worktree. If so, `cd` back to project root.

3. **If `--all`**:
   a. List all DONE worktrees from the DB.
   b. For each, attempt `git worktree remove` (directory cleanup only, DB records preserved).
   c. Report what was cleaned.

4. **If no arguments**:
   a. Show the pre-execution context as a table.
   b. Ask the user which worktree to clean.
   c. Proceed as in step 2.

5. **Report result**: Show updated worktree status.

</execution_order>

## Rules

- Always confirm before removing a worktree — never auto-clean without user approval (`AskUserQuestion` required at every branch point).
- DONE records are preserved in the DB for history (never deleted).
- Detect worktree context by CWD position (`pwd` under `${CLAUDE_PROJECT_DIR}/worktrees/`), then use `Skill("omb-worktree")` with argument `"context"` for metadata retrieval.
- If `$ARGUMENTS` is provided, always use the External Flow regardless of CWD position.
- Use `uv run --project "${CLAUDE_PROJECT_DIR}" oh-my-braincrew worktree-update {branch} --status DONE` to mark a worktree DONE — never modify the DB file directly.
- Use `${CLAUDE_PROJECT_DIR}` for all project root references — never hardcode paths.
- Do NOT run `git checkout main` before teardown — worktrees are separate working trees.
- If the current CWD is inside the worktree being removed, navigate to `${CLAUDE_PROJECT_DIR}` first (Step 4).
- Warn before cleaning PROGRESS worktrees — they may have uncommitted work.

## Examples

| Invocation | CWD | Effect |
|------------|-----|--------|
| `/omb:clean` | inside worktree | Guided internal flow (PR check, status branching, confirm, delete) |
| `/omb:clean feat/auth` | anywhere | External flow: clean specific worktree by branch name |
| `/omb:clean --all` | outside worktree | External flow: clean all DONE worktrees |
| `/omb:clean` | project root | External flow: show worktrees and ask which to clean |

## Output Contract

Cleanup success:

```
Cleanup complete.
Removed: {branch} ({former_path})
```

Cleanup cancelled:

```
Cleanup cancelled. Worktree {branch} unchanged.
```
