---
name: omb-execute
user-invocable: true
description: >
  Use when executing an approved plan from .omb/plans/, implementing tasks
  via TDD agents, or running Step 3 of the omb workflow. Triggers on:
  "execute plan", "implement plan", "run plan", "start execution", "build this
  plan", "kick off the plan", "start implementing", "run the tasks", "execute
  [plan-name]", or when the user points to a plan file and expects implementation.
  Also use after a plan passes review and the user says "go", "ship it", "let's
  build", or "proceed". Spawns parallel agent teams per task table with
  dependency-aware wave scheduling. Do NOT use for planning (use
  omb-create-plan) or reviewing (use omb-review-plan).
argument-hint: "[plan-file-path]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, Skill, AskUserQuestion
---

# Plan Execution Workflow

Execute an approved plan from `.omb/plans/` by spawning agent teams with dependency-aware wave scheduling and TDD enforcement.

<references>
- `${CLAUDE_SKILL_DIR}/reference.md` § 1 — agent prompt templates (executor, domain specialist, test engineer)
- `${CLAUDE_SKILL_DIR}/reference.md` § 2 — agent name mapping and fallback rules
- `${CLAUDE_SKILL_DIR}/reference.md` § 4 — execution state JSON schema
- `${CLAUDE_SKILL_DIR}/reference.md` § 5 — execution log template
- `${CLAUDE_SKILL_DIR}/reference.md` § 6 — wave computation (topological sort)
- `${CLAUDE_SKILL_DIR}/reference.md` § 7 — retry and fix loop policy
- `${CLAUDE_SKILL_DIR}/reference.md` § 8 — resume protocol
- `.claude/rules/03-execute-tdd.md` — TDD phases and rules
</references>

<completion_criteria>
The execution is complete when ALL of these hold:
- Every task in the plan has been attempted (DONE, FAILED, or SKIPPED)
- Execution state file updated with final status
- Execution log written to `.omb/executions/`
- User presented with status report and next step recommendation
- Agent output includes structured TEST_RESULTS field when tests were run

Status codes: COMPLETE | PARTIAL | FAILED
</completion_criteria>

<ambiguity_policy>
- Agent returns non-standard output (no STATUS line): extract what you can, mark task DONE_WITH_CONCERNS, log "non-standard output from [agent] on task [id]"
- Unknown agent name in plan: fall back to `executor` agent, log warning "Unknown agent '[name]', falling back to executor"
- Vague deliverable (no file path): invoke `Agent` tool with `subagent_type: "explore"` and `model: "haiku"` to determine the correct path BEFORE executing the task
- Dependency cascade: if a task fails after retries, mark ALL transitive dependents as SKIPPED — do not attempt them
- Resume detection: if state file exists with IN_PROGRESS status, ask user "Resume or restart?" via AskUserQuestion — never silently overwrite
- Plan mismatch (NEEDS_CONTEXT): pause ALL pending tasks, report evidence to user via AskUserQuestion — do not continue silently
</ambiguity_policy>

<scope_boundaries>
This skill executes plans — it does NOT:
- Create or modify plans (use omb-create-plan)
- Review plans (use omb-review-plan)
- Run the verification step (Step 4 — use `/omb verify`)
- Allocate tracking codes with `omb tracking next <TYPE>`
- Make architecture decisions — it implements what the plan says
- Modify files outside the plan's deliverable scope
</scope_boundaries>

<anti_patterns>
- Executing an unreviewed plan — unreviewed plans contain unchecked assumptions that cascade into wasted agent work
- Ignoring task dependencies (running Wave 2 before Wave 1 completes) — dependent tasks consume stale inputs and produce broken outputs
- Continuing after a critical infrastructure task fails (DB migration, auth middleware) — downstream tasks depend on infrastructure state and will fail or silently corrupt
- Silently skipping tasks without marking SKIPPED with reason — invisible skips create gaps that surface as bugs weeks later
- Running tasks sequentially when the wave allows parallel execution — serializing independent tasks wastes time without improving quality
- Spawning agents without tracking code in their prompt — agents without tracking instructions produce untracked deliverables that fail STEP 4 verification
- Implementing without writing tests first — tests define the specification; code without tests has no behavioral contract and no regression safety
- Claiming task DONE when tests exist but are not all passing — tests are the specification; failing tests mean the specification is not met
- Accepting DONE status from agent when TEST_RESULTS shows failures — parse the structured TEST_RESULTS field and override to FAILED (test failure) for in-scope failures
</anti_patterns>

---

## STEP 0 — Locate and Validate Plan

1. Parse `$ARGUMENTS` for plan file path.

2. If no path provided:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/../omb-create-plan/scripts/list-prior-plans.sh
   ```
   Ask the user which plan to execute via `AskUserQuestion`.

3. Ensure execution directories exist:
   ```bash
   mkdir -p .omb/executions/state
   ```

4. Read the plan file. Abort if missing: "Plan file not found: {path}"

5. Validate the plan:
   - **Tasks table exists** with columns: #, Task, Agent, Model, Depends On, Deliverable
   - **Tracking code extractable** — scan for pattern `[A-Z]{2,6}-PLAN-\d{6}` in the title line
   - **Verification Criteria section present**
   - Abort if invalid: "Plan validation failed: {reason}"

6. **Criteria quality check**: scan the Verification Criteria section. If more than 50% of criteria are prose-only (no runnable command like `pytest`, `tsc`, `curl`, `grep`, `vitest`), warn the user:
   > "Plan has vague verification criteria. Consider adding runnable commands before execution. Proceed anyway? [y/N]"

   Use `AskUserQuestion` for the prompt. If user declines, abort.

**Step output:** Plan content validated. Tracking code extracted (store as `{TRACKING_CODE}`). Execution directories created. Proceed to STEP 1.

---

## STEP 1 — Parse Tasks & Build Dependency Graph

1. Run the task parser:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/parse-plan-tasks.sh <plan-path>
   ```
   Capture the JSON output.

2. Build the dependency graph and compute execution waves via topological sort (see `${CLAUDE_SKILL_DIR}/reference.md` § 6):
   - **Wave 1**: tasks with no dependencies (run in parallel)
   - **Wave 2**: tasks depending only on Wave 1 tasks (run in parallel)
   - **Wave N**: tasks depending on Wave N-1 tasks
   - Detect circular dependencies — abort if found: "Circular dependency detected among tasks: [list]"

3. If no `Depends On` data (all empty/dash): treat all tasks as Wave 1 (fully parallel).

4. Report wave structure to user:
   ```
   Dependency graph computed:
   Wave 1: Tasks [1, 4, 9, 10, 14] (parallel)
   Wave 2: Tasks [2, 6, 8, 11] (parallel)
   Wave 3: Tasks [3, 5, 7, 12, 15] (parallel)
   ...
   ```

**Step output:** JSON task array parsed. Waves computed: `waves[][]` with task IDs grouped by dependency depth. Report wave structure to user before proceeding.

---

## STEP 2 — Initialize Execution State

1. Check for existing state file at `.omb/executions/state/{plan-filename}.json`.

2. If exists: follow resume protocol from `${CLAUDE_SKILL_DIR}/reference.md` § 8.

   | Existing Status | Prompt via AskUserQuestion | Options |
   |---|---|---|
   | `IN_PROGRESS` | "Previous execution incomplete." | resume / restart |
   | `COMPLETE` | "Plan already executed." | re-run / abort |
   | `PARTIAL` | "Previous execution partially complete." | resume / restart |
   | `FAILED` | "Previous execution failed." | retry failed / restart |

3. Create or update state file (schema in `${CLAUDE_SKILL_DIR}/reference.md` § 4):
   ```json
   {
     "planFile": "<relative-path>",
     "trackingCode": "<extracted-code>",
     "startedAt": "<ISO-8601>",
     "completedAt": null,
     "status": "IN_PROGRESS",
     "waves": [[1, 4], [2, 3, 5], [6, 7]],
     "currentWave": 0,
     "tasks": {
       "1": {"status": "PENDING", "agent": "executor", "model": "sonnet", "testRetries": 0, "implRetries": 0, "failureType": null, "testResults": {"passed": 0, "failed": 0, "coverage": null, "scope": null}, ...}
     }
   }
   ```

**Step output:** State file written to `.omb/executions/state/{plan-filename}.json` with status `IN_PROGRESS`. All tasks initialized as `PENDING`.

---

## STEP 3 — Execute Waves (Main Loop)

This is the core execution step. For each wave:

### 3a. Prepare Agent Prompts

For each task in the current wave, build the agent prompt using templates from `${CLAUDE_SKILL_DIR}/reference.md` § 1:

1. **Select template**: executor template (default) or domain specialist template (if agent is a specialist)
2. **Fill placeholders**:
   - `{TASK_DESCRIPTION}` — from plan's Task column
   - `{TRACKING_CODE}` — extracted in STEP 0
   - `{DELIVERABLE_PATH}` — from plan's Deliverable column
   - `{DEPENDENCY_RESULTS}` — files created/modified by completed dependency tasks
   - `{AGENT_NAME}`, `{MODEL}`, `{TASK_ID}` — from plan and state
   - `{TOTAL_TASKS}` — total number of tasks in the plan
3. **Agent mapping**: set `subagent_type` to the plan's Agent column value — this MUST match a filename (without `.md`) in `.claude/agents/omb/`. Verify against `${CLAUDE_SKILL_DIR}/reference.md` § 2. Unknown agent → fallback to `subagent_type: "executor"` with warning logged.
4. **Model**: set `model` to the plan's Model column value (haiku/sonnet/opus). If omitted, the agent definition's default model applies.

### 3b. Spawn Wave Agents

Invoke the `Agent` tool for ALL tasks in the current wave **in a single parallel batch** — one `Agent` call per task, all in the same response. Each call specifies `subagent_type`, `model`, `prompt`, and `description`.

### 3c. Process Results

For each completed agent:

1. Parse the output for STATUS, files created/modified, summary, and **structured TEST_RESULTS field**
2. **Classify failure type** (if FAILED):
   - **Test failure**: TEST_RESULTS field shows FAIL, or agent output contains test runner output (pytest/vitest/jest patterns) with failing tests but implementation exists
   - **Implementation error**: agent output contains syntax errors, import failures, type errors, or no test output
   - **Environment error**: agent output contains tool/dependency missing errors (missing packages, unavailable services)
3. Update execution state based on failure type:
   - `DONE` → mark task complete, record files and summary
   - `DONE_WITH_CONCERNS` → mark complete, record concerns
   - `FAILED (test failure)` → increment test retry counter
     - If test retries < 3: re-spawn with test-specific error context (see `${CLAUDE_SKILL_DIR}/reference.md` § 7)
     - If test retries >= 3: mark FAILED, mark all dependent tasks SKIPPED
   - `FAILED (implementation error)` → increment implementation retry counter
     - If impl retries < 2: re-spawn with error context (see `${CLAUDE_SKILL_DIR}/reference.md` § 7)
     - If impl retries >= 2: mark FAILED, mark all dependent tasks SKIPPED
   - `FAILED (environment error)` → mark BLOCKED immediately (no retries — environment issues require user intervention)
   - `BLOCKED` → mark BLOCKED, mark all dependent tasks SKIPPED
   - `NEEDS_CONTEXT` (plan mismatch OR bad test escape) → **PAUSE all pending tasks**, report evidence to user via `AskUserQuestion`. Do NOT continue silently.

4. **Test pass verification gate**: Before accepting DONE status, check TEST_RESULTS field. If TEST_RESULTS reports FAIL AND failing tests are within the task's declared test scope: override to FAILED (test failure). Out-of-scope test failures → DONE_WITH_CONCERNS.

5. Write updated state to disk after each task completes.

### 3d. Wave Completion Gate

| Condition | Action |
|-----------|--------|
| All tasks DONE | Advance to next wave |
| Any FAILED (test) after 3 test retries | Ask user via `AskUserQuestion`: "Task {id} failed after 3 test retry iterations. Tests still not passing. Continue to next wave or abort?" |
| Any FAILED (impl) after 2 impl retries | Ask user: "Task {id} has implementation errors after 2 retries. Continue or abort?" |
| Critical infra task FAILED | Recommend abort: "Critical task {id} ({type}) failed. Dependent tasks will likely fail." |
| All remaining tasks SKIPPED | Skip to STEP 4 |

### 3e. Repeat

Continue until all waves are processed or execution is aborted.

**Step output:** Every task in every wave has a terminal status (DONE, FAILED, BLOCKED, or SKIPPED). State file reflects per-task results including files created/modified.

---

## STEP 4 — Verify Spec-Code Comments

1. Collect all deliverable file paths from completed tasks (status DONE).

2. Run the verification script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/check-spec-comments.sh <tracking-code> <file1> <file2> ...
   ```

3. If any files are missing the tracking code:
   - Invoke `Agent` tool with `subagent_type: "executor"` and `model: "haiku"` for each missing file to add the tracking comment
   - Re-run verification to confirm

4. Report results:
   ```
   Spec-code verification: 12/14 files passed, 2 fixed
   ```

**Step output:** All deliverable files verified for tracking code presence. Count reported: `{passed}/{total} files passed, {fixed} fixed`.

---

## STEP 5 — Generate Execution Log

Write the execution log to `.omb/executions/{plan-filename}.md` using the template from `${CLAUDE_SKILL_DIR}/reference.md` § 5.

Aggregate from execution state:
- **Metadata**: plan file, tracking code, timestamps, duration
- **Summary metrics**: total/completed/failed/skipped counts
- **Changes table**: all files created and modified across all tasks
- **Per-task reports**: agent, model, status, files, duration, summary
- **Failed tasks table**: if any tasks failed

Use the `Write` tool to create the log file.

**Step output:** Execution log written to `.omb/executions/{plan-filename}.md` with metadata, summary metrics, changes table, and per-task reports.

---

## STEP 6 — Update Execution State

1. Determine final status:
   - **COMPLETE** — all tasks DONE
   - **PARTIAL** — some tasks DONE, some FAILED or SKIPPED
   - **FAILED** — no tasks completed successfully, or critical task failed

2. Update state file:
   - Set `status` to final status
   - Set `completedAt` to current ISO timestamp

**Step output:** State file updated with final `status` (COMPLETE/PARTIAL/FAILED) and `completedAt` timestamp.

---

## STEP 7 — Report to User

Present the execution summary:

### If COMPLETE:
```
**Execution COMPLETE**
- Tasks: {N}/{N} completed
- Files changed: {N}
- Execution log: .omb/executions/{filename}.md

Next step: Proceed to Step 4: Verify (run `/omb verify` to collect evidence)
Then Step 5: Document (run `/omb doc` to generate documentation)
```

### If PARTIAL:
```
**Execution PARTIAL**
- Tasks: {completed}/{total} completed, {failed} failed, {skipped} skipped
- Files changed: {N}
- Execution log: .omb/executions/{filename}.md

{failed} tasks need attention. Review the execution log for details.
After resolving failures, proceed to Step 4: Verify (`/omb verify`)
Then Step 5: Document (`/omb doc`)
```

### If FAILED:
```
**Execution FAILED**
- Tasks: {completed}/{total} completed
- Execution log: .omb/executions/{filename}.md

Execution blocked. See execution log for error details.
```

**Step output:** User receives execution summary with status, counts, log path, and explicit next step recommendation.

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>execute(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
