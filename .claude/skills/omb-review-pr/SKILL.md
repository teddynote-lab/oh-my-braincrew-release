---
name: omb-review-pr
user-invocable: true
description: >
  Use when reviewing a pull request with multi-agent analysis. Fetches PR metadata,
  auto-detects technical domains from changed files, spawns minimum 3 review agents
  (always including critic), runs a commit relevance audit to catch unrelated or
  unnecessary changes that crept in during development, aggregates findings into a
  structured report, posts verdict as PR comment. Returns APPROVED or NEED_REVISION.
argument-hint: "[PR-number]"
allowed-tools: Read, Bash, Grep, Glob, Agent, Write
---

# PR Review Skill

Reviews a single PR using auto-detected agent teams. Minimum 3 agents, always including critic.

<completion_criteria>
- PR metadata fetched and analyzed
- Agent teams spawned and reports collected
- Commit relevance audit completed (all files classified)
- Verdict determined (APPROVED or NEED_REVISION)
- Structured review comment posted via gh pr comment
- Review record saved to .omb/reviews/
- Pipeline completion marker emitted

Status codes: APPROVED (emits PIPELINE_COMPLETE) | NEED_REVISION (emits DONE)
</completion_criteria>

<scope_boundaries>
This skill reviews PRs — it does NOT:
- Create improvement plans (that's the next pipeline step)
- Execute fixes (that's omb-execute)
- Commit changes (that's omb-commit-to-pr)
</scope_boundaries>

## Step 1: Identify PR

If a PR number argument is provided, use it directly.

If no PR number provided:
```bash
gh pr list --state open --json number,title,author --limit 50
```
Pick the first (lowest number) open PR.
If no open PRs exist: emit PIPELINE_COMPLETE with "No open PRs to review".

## Step 2: Fetch PR Metadata

Run in parallel:
```bash
gh pr view {PR_NUMBER} --json title,body,author,baseRefName,headRefName,commits,files
gh pr diff {PR_NUMBER}
```

Store the PR title, body, changed files list, and full diff.

## Step 3: Auto-Detect Domains

Analyze changed file paths to detect technical domains:

| File Pattern | Domain | Agent |
|-------------|--------|-------|
| `*.py`, `**/api/**`, `**/routes/**` | Python/API | api-specialist |
| `*.tsx`, `*.jsx`, `**/components/**` | React/Frontend | frontend-engineer |
| `*.go` | Go | reviewer |
| `**/migrations/**`, `*.sql`, `**/models/**` | Database | db-specialist |
| `*.ts` (non-React) | TypeScript | reviewer |
| `**/langchain/**`, `**/langgraph/**` | LangChain | langgraph-engineer |
| `Dockerfile`, `*.yml` (CI) | Infrastructure | infra-engineer |
| `**/electron/**`, `preload.*` | Electron | electron-specialist |

Always include: `critic` (architecture review)
Minimum 3 agents. If auto-detection yields < 2 domain agents, add `reviewer` as fallback.

## Step 4: Spawn Agent Review Teams

Invoke the `Agent` tool for all detected agents in a single parallel batch. For each agent, set `subagent_type` to the agent name from the domain mapping table (matching `.claude/agents/omb/{name}.md`), set `model` per the domain table, and include `description` and `prompt`.

Each agent receives:
- PR title and description
- Full diff of changed files
- List of changed files with line counts
- Instructions to evaluate: code quality, correctness, security, adherence to conventions

Each agent returns a structured review:
```
## [Agent Name] Review
**Verdict:** APPROVE / REQUEST_CHANGES / COMMENT
**Findings:**
- [P0] Critical: ...
- [P1] Major: ...
- [P2] Minor: ...
- [P3] Suggestion: ...
```

## Step 5: Commit Relevance Audit

After domain reviews complete, audit every changed file against the PR's stated purpose. During development with AI coding assistants, unrelated changes often sneak into commits — debug leftovers, accidental reformatting, exploratory edits that were never reverted, or files touched while navigating the codebase. These dilute the PR's intent and make reviews harder.

**Inputs:**
- PR title and body (the stated purpose / original issue)
- Full list of changed files with their diffs (from Step 2)
- Agent findings from Step 4 (for additional context on what the PR actually does)

**Process:**

Spawn a single `critic` agent (opus) with the full diff and PR context. The agent classifies each changed file into one of:

| Classification | Meaning | Action |
|---------------|---------|--------|
| **ESSENTIAL** | Directly implements the PR's stated goal | Keep |
| **SUPPORTING** | Enables an essential change (types, imports, test updates, config) | Keep |
| **COSMETIC** | Formatting-only, whitespace, import reordering with no functional impact | Flag as P2 |
| **UNRELATED** | Functional change that does not serve the PR's purpose | Flag as P1 |
| **SUSPICIOUS** | Debug code, console.log, commented-out blocks, TODO without issue ref | Flag as P1-P2 depending on severity |

The agent returns a structured audit:
```
## Commit Relevance Audit
**PR Purpose:** {1-sentence summary of what this PR is supposed to do}
**Files Reviewed:** {count}
**Verdict:** CLEAN / HAS_UNRELATED_CHANGES

### File Classifications
| File | Classification | Rationale |
|------|---------------|-----------|
| src/api/auth.ts | ESSENTIAL | Implements the JWT refresh endpoint |
| src/utils/format.ts | UNRELATED | Reformatted file not related to auth |
| src/db/schema.sql | SUPPORTING | Adds refresh_token column needed by auth |

### Flagged Files
- [P1] `src/utils/format.ts` — Unrelated reformatting. Should be a separate PR or reverted.
- [P2] `src/api/debug.ts` — Contains `console.log("DEBUG")` left from development.
```

**Classification guidance for the critic agent:**
- A file that only changes whitespace or import order is COSMETIC, not UNRELATED — it's low-harm but still worth flagging because it creates noise in the diff.
- Test files that test the PR's new behavior are SUPPORTING, even if they touch existing test utilities.
- Config file changes (tsconfig, eslint, package.json) are SUPPORTING only if the PR's code changes require them. Otherwise they're UNRELATED.
- If the PR description is vague or missing, the agent should infer purpose from the essential changes and note the ambiguity.

**Integration with verdict:**
Flagged files from this audit feed into Step 6 (Aggregate and Decide) as additional findings:
- UNRELATED files count as P1 findings from the critic
- SUSPICIOUS files with debug artifacts count as P1
- COSMETIC-only flags count as P2 (informational, don't block approval)

## Step 6: Aggregate and Decide

Aggregate all agent findings **including commit relevance audit flags from Step 5**:
- If any agent has P0 findings: verdict = NEED_REVISION
- If 2 or more agents independently report P1-severity findings: verdict = NEED_REVISION
- If the commit relevance audit found UNRELATED files: verdict = NEED_REVISION (even if domain agents approved, unrelated changes must be removed or justified)
- Otherwise: verdict = APPROVED

## Step 7: Post Review Comment

Post structured markdown comment via `gh pr comment {PR_NUMBER} --body "..."`:

```markdown
## PR Review Report

**PR:** #{PR_NUMBER} — {TITLE}
**Verdict:** APPROVED / NEED_REVISION
**Reviewed by:** {agent_count} agents ({agent_names})

### Summary
{1-3 sentence summary of overall assessment}

### Agent Findings

#### {Agent 1 Name}
{Findings}

#### {Agent 2 Name}
{Findings}

### Commit Relevance Audit
| File | Classification | Rationale |
|------|---------------|-----------|

{If UNRELATED or SUSPICIOUS files found:}
**Action Required:** The following files should be removed from this PR or split into a separate PR:
- {file1} — {reason}
- {file2} — {reason}

### Issues Found
| # | Severity | Agent | Finding | File |
|---|----------|-------|---------|------|

### Recommended Changes (if NEED_REVISION)
- {Change 1}
- {Change 2}

---
<!-- oh-my-braincrew | PR Review | {DATE} -->
```

## Step 8: Save Review Record

```bash
mkdir -p .omb/reviews
```
Write review to `.omb/reviews/PR-{NUMBER}-{DATE}.md`

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>review-pr(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
