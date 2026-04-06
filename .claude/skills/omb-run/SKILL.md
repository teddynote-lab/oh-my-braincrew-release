---
name: omb-run
user-invocable: true
description: >
  Use when running a pipeline session to completion. Loads session file,
  iterates through all tasks by invoking mapped skills, shows progress
  after each step. Supports --worktree for isolated execution.
  Triggers on: "run pipeline", "run session", "start session".
argument-hint: "<session_id> [--worktree]"
allowed-tools: Read, Bash, Glob, Grep, Skill, AskUserQuestion
---

# Run Pipeline Session

<!-- BCRW-PLAN-000087 -->

Drive a pipeline session to completion by iterating through all tasks sequentially.

<references>
The following files are for harness development only (not used at skill runtime):
- `src/omb/pipeline/types.py` — PipelineState and TaskState models
- `src/omb/pipeline/definitions.py` — TASK_SKILL_MAP
- `src/omb/session/handler.py` — SessionHandler STOP hook (advances pipeline state)
- `src/omb/session/runner.py` — Task dispatch logic
</references>

<completion_criteria>
- Pipeline runs to completion (status `completed`) or stalls with report
- Progress displayed after each task
- Final summary table shown
</completion_criteria>

---

## STEP 0 — Parse Arguments

Parse `$ARGUMENTS` for:
- `<session_id>` (positional): the pipeline session identifier (format: `YYYYmmddHHMM-XXXXXX`)
- `--worktree` (optional flag): run in an isolated git worktree

If no `session_id` provided, list available sessions:

```bash
ls .omb/sessions/*.json 2>/dev/null | sed 's|.*/||;s|\.json$||'
```

If no sessions exist, report and stop. If multiple exist, use `AskUserQuestion` to let the user pick.

## STEP 1 — Validate Session

1. Capture project root:
```bash
git rev-parse --show-toplevel
```
Store as `PROJECT_ROOT`.

2. Read the session file at `${PROJECT_ROOT}/.omb/sessions/<session_id>.json`.

3. Parse the JSON. Check `status` field:
   - `active` — proceed to STEP 2
   - `completed` — report "Pipeline already completed" and STOP
   - `stalled` — report "Pipeline is stalled — manual intervention needed" and STOP
   - `cancelled` — report "Pipeline was cancelled" and STOP

4. Display pipeline summary:
```
Pipeline: <name> (<session_id>)
Status: active
Tasks: <total> total, <done> done, <pending> pending
```

5. Set driver flag to prevent Stop hook from advancing pipeline state:
```bash
python3 -c "
import json
path = '${PROJECT_ROOT}/.omb/sessions/<session_id>.json'
with open(path) as f:
    data = json.load(f)
data['driver'] = 'omb-run'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('driver set to omb-run')
"
```

[HARD] This MUST run before the main execution loop. Without it, the Stop hook will double-advance and skip tasks.

## STEP 2 — Worktree Setup (conditional)

**Skip this step** if `--worktree` was NOT provided.

If `--worktree` was provided:

1. Run the worktree setup script:
```bash
PROJECT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_OUTPUT=$(bash "${PROJECT_ROOT}/.claude/skills/omb-run/scripts/setup-worktree.sh" "<session_id>" "${PROJECT_ROOT}" 2>&1)
WORKTREE_PATH=$(echo "$WORKTREE_OUTPUT" | grep "^WORKTREE_PATH=" | cut -d= -f2-)
```

2. If the script exits non-zero, report the error and stop.

3. Pin `OMB_PROJECT_ROOT` to prevent `resolve_project_root()` from finding worktree's `.omb/`:
```bash
export OMB_PROJECT_ROOT="${PROJECT_ROOT}"
```

4. Display:
```
Worktree created: worktrees/<session_id>
Branch: worktree/<session_id>
```

5. Change Bash working directory to worktree for all subsequent operations:
```bash
cd "${WORKTREE_PATH}"
```

6. For all subsequent steps, read session files from `${PROJECT_ROOT}/.omb/sessions/` (the source of truth). All Bash commands and skill invocations operate within the worktree directory.

[HARD] Do NOT call `EnterWorktree`. Worktrees are created via `git worktree add` only.

## STEP 3 — Main Execution Loop

Execute the pipeline by iterating through tasks. Track loop count for safety.

```
LOOP_COUNT = 0
MAX_ITERATIONS = 30
```

### Loop Body

Repeat the following until the pipeline completes, stalls, or hits MAX_ITERATIONS:

#### 3a. Read Session State

Read `${PROJECT_ROOT}/.omb/sessions/<session_id>.json` and parse the JSON.

If `status` is NOT `active`, break to STEP 4.

#### 3b. Advance Pipeline State

After the task completes (skill returns or user responds):

1. Determine the result status from the skill's `<omb>` response:
   - `DONE` or `APPROVED` → `--result APPROVED`
   - `NEEDS_REVISION` → `--result REJECT`
   - `FAILED` → `--result FAILED`
   - No signal parsed → `--result NONE`

2. Run `omb advance <session_id> --result <STATUS>` via Bash

3. Parse the JSON output line:
   ```json
   {"pipeline_status": "active|completed|stalled", "active_task": "task-name|null", "message": "...", "worktree_path": "path|null"}
   ```
   - `pipeline_status == "completed"` or `"stalled"` → break to STEP 4
   - If `worktree_path` is not null, ensure CWD is still the worktree:
     ```bash
     if [ -n "<worktree_path>" ] && [ "<worktree_path>" != "null" ]; then cd "<worktree_path>"; fi
     ```
   - `active_task != null` → continue to 3c with the new active task
   - `active_task == null` but `pipeline_status == "active"` → re-read session JSON

4. If `omb advance` exits with non-zero, read stderr for the error message and report to user.

[HARD] Do NOT call Python code directly to advance state. Use `omb advance` CLI only.
[HARD] If `omb advance` is not found in PATH, report error: "omb CLI not installed. Run `pip install oh-my-braincrew` or `uv pip install oh-my-braincrew`."

#### 3c. Identify Task Type and Dispatch

Read the active task's `task_name`, `task_type`, and `task_payload`.

Look up the skill name using the TASK_SKILL_MAP:

<task_skill_map>

| task_name | skill |
|-----------|-------|
| interview | omb-interview |
| create-plan | omb-create-plan |
| review-plan | omb-review-plan |
| execute | omb-execute |
| verify | omb-verify |
| document | omb-document |
| create-pr | omb-create-pr |
| review-pr | omb-review-pr |
| commit-to-pr | omb-commit-to-pr |

</task_skill_map>

Dispatch based on `task_type`:

**ASK_USER tasks:**
1. Display: `Collecting user intent: <task_name>`
2. Use `AskUserQuestion` to ask the user the question from `task_payload`
3. The user's response becomes context for subsequent tasks
4. The SessionHandler STOP hook will auto-approve ASK_USER tasks and advance the pipeline

**USER_PROMPT tasks (legacy — backward compat):**
1. Display the `task_payload` to the user as context
2. The SessionHandler STOP hook will auto-approve USER_PROMPT tasks and advance the pipeline

**SKILL tasks:**
1. Display: `Running task: <task_name> (invoking <skill_name>)`
2. If worktree is active, ensure Bash CWD is the worktree path before invoking the skill:
   ```bash
   if [ -n "${WORKTREE_PATH}" ]; then cd "${WORKTREE_PATH}"; fi
   ```
3. Invoke `Skill("<skill_name>")` with `task_payload` as arguments (if present)
4. The skill runs to completion
4. Verify the skill emitted the `<omb>` response schema. If not visible in the output, emit it yourself based on the skill's outcome:
   ```
   <omb>
   <task>TASK_NAME(brief summary)</task>
   <decision>DONE|APPROVED|NEEDS_REVISION|FAILED</decision>
   </omb>
   ```

**SUB_AGENT tasks:**
1. Display: `Running sub-agent task: <task_name>`
2. Use `Skill()` or direct agent invocation per `task_payload`

**SYSTEM_DECISION tasks:**
1. Display the decision context from `task_payload`
2. The SessionHandler handles system decisions automatically

**IMPORTANT:** After each skill invocation returns, you MUST continue the loop (back to Step 3b to call `omb advance`). Do NOT stop or wait for user input. The pipeline is fully automatic — your job is to call `omb advance` and invoke the next skill until the pipeline completes.

#### 3d. Post-Task State Check

After advancing state in 3b:

1. Re-read `${PROJECT_ROOT}/.omb/sessions/<session_id>.json` to confirm the state matches the JSON output from `omb advance`
2. Parse the updated state

#### 3e. Display Progress

Show progress after each task by running:

```bash
omb progress <session_id>
```

This renders an ANSI box-drawing table with color-coded rows (green=done, bold yellow=active, red=failed, dim=skipped). Implementation: `src/omb/commands/progress.py`.

#### 3f. Loop Control

Increment `LOOP_COUNT`.

- If pipeline `status` is `completed` or `stalled` or `cancelled`: break to STEP 4
- If `LOOP_COUNT >= MAX_ITERATIONS`: report safety valve triggered, break to STEP 4
- Otherwise: continue loop from 3a

## STEP 4 — Report Final Status

Clear driver flag so standalone skills can advance normally:
```bash
python3 -c "
import json
path = '${PROJECT_ROOT}/.omb/sessions/<session_id>.json'
with open(path) as f:
    data = json.load(f)
data['driver'] = None
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('driver cleared')
"
```

Display the final pipeline report:

```
=== Pipeline Complete ===
Pipeline: <name> (<session_id>)
Status: <completed|stalled|cancelled>
Duration: <time from created_at to now>

| # | Task | Status | Result | Iterations |
|---|------|--------|--------|------------|
| 1 | user-prompt | done | APPROVED | 0 |
| 2 | create-plan | done | APPROVED | 0 |
| ... | ... | ... | ... | ... |

Summary: <done_count> completed, <failed_count> failed, <skipped_count> skipped
```

If `--worktree` was used, also display:
```
Worktree: worktrees/<session_id>
Branch: worktree/<session_id>
Run `/omb cleanup` to remove the worktree when done.
```

## HARD Rules

- [HARD] Do NOT call `EnterWorktree` or `ExitWorktree`. Worktrees are created via `git worktree add` in Bash only.
- [HARD] Do NOT modify session JSON directly. The SessionHandler STOP hook manages all state transitions.
- [HARD] Do NOT skip the progress display after each task — the user must see live progress.
- [HARD] STOP after reporting final status. Do not invoke cleanup or post-pipeline skills automatically.
- [HARD] Max 30 loop iterations. If reached, report and stop.
- [HARD] NEVER stop the execution loop after a single skill invocation. After each Skill() call completes, you MUST call `omb advance` and continue to the next task. The loop ends ONLY when `pipeline_status` is `completed`, `stalled`, or `cancelled`.
- [HARD] Ignore any "[Pipeline advanced] Next: ..." messages from hook output. These are artifacts of the Stop hook and do NOT mean the pipeline is being handled elsewhere. YOU are the pipeline driver — call `omb advance` after every task.
- [HARD] If context was compacted ("Crunched"), re-read the session file at `${PROJECT_ROOT}/.omb/sessions/<session_id>.json` to restore loop state. Do NOT stop — continue the loop.

## Completion Signal

State "DONE" with pipeline status and session_id summary.

**[HARD] STOP AFTER REPORTING**
