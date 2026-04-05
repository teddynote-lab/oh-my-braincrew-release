---
name: omb-task
user-invocable: true
description: >
  Use when initializing a new pipeline session. Creates a session schema file
  (.omb/sessions/<session_id>.json) from pre-made templates or interactive Manual mode.
  Validates schema before saving. Triggers on:
  "task", "init pipeline", "create pipeline", "start pipeline", "new session".
argument-hint: "[template-name|manual] [--name '<pipeline-name>'] [--description '<desc>']"
allowed-tools: Read, Bash, Grep, Glob, Agent, AskUserQuestion
---

# Init Pipeline

Create a new pipeline session file deterministically via the `omb task init` CLI command.
All ID generation, validation, wave computation, and file saving are handled by the CLI — not by inline JSON generation.

<references>
CLI implementation:
- `src/omb/commands/task.py` — `omb task init` and `omb task checkpoint` commands
- `src/omb/pipeline/factory.py` — Pipeline instantiation logic
- `scripts/init-pipeline.sh` — Shell wrapper for `omb task init`

Data layer (for reference only — not invoked directly):
- `src/omb/pipeline/types.py` — PipelineState and TaskState models
- `src/omb/pipeline/definitions.py` — Pipeline templates
- `src/omb/pipeline/validation.py` — Schema validation
- `src/omb/pipeline/waves.py` — Wave computation

Pre-made schema templates are stored in `.omb/schema/`.
</references>

<completion_criteria>
- Session JSON file created at `.omb/sessions/<session_id>.json`
- Schema passes all 6 validation rules (enforced by CLI)
- Wave structure displayed to user
- Session ID returned for pipeline activation
- User asked whether to start pipeline via `omb:run`
</completion_criteria>

---

## STEP 1 — Parse Arguments and Select Template

Parse `$ARGUMENTS` for:
- Template selector (positional): one of the display names below, an old alias, or `manual`
- `--name '<pipeline-name>'` (optional, defaults to template display name)
- `--description '<desc>'` (optional, defaults to "")

If no template specified, ask the user via `AskUserQuestion`:

| Option | Display Name | Description |
|--------|-------------|-------------|
| 1 | Manual | Design a custom pipeline interactively |
| 2 | Interview - Plan - Review - Execute - Verify - Document - Create PR | Full pipeline with requirements interview |
| 3 | ASK_USER - Plan - Review - Execute - Verify - Document - Create PR | Standard pipeline for bug fixes and tasks |
| 4 | ASK_USER - Plan - Review | Planning-only pipeline |
| 5 | ASK_USER - Execute - Verify - Document - Create PR | Execution-only (plan already exists) |
| 6 | ASK_USER - Review PR - Judge - Plan - Review - Execute - Verify - Document - Create PR | PR review with conditional branching |

<old_alias_mapping>
For backward compatibility, these old names are also accepted:
- `full` → Interview - Plan - Review - Execute - Verify - Document - Create PR
- `fix` → ASK_USER - Plan - Review - Execute - Verify - Document - Create PR
- `plan` → ASK_USER - Plan - Review
- `exec` → ASK_USER - Execute - Verify - Document - Create PR
- `review-pr` → ASK_USER - Review PR - Judge - Plan - Review - Execute - Verify - Document - Create PR
</old_alias_mapping>

If the user selects **Manual**, go to STEP 2A.
Otherwise, go to STEP 2B.

## STEP 2A — Manual Mode (Interactive Pipeline Design)

### 2A-1. Show available building blocks

Read available skills from `.claude/skills/` directory and sub-agents from `.claude/agents/omb/` directory. Display them grouped:

**Available Task Types:**
- `SKILL` — Invokes a skill (e.g., `omb-create-plan`, `omb-execute`)
- `SUB-AGENT` — Invokes a sub-agent (e.g., `executor`, `critic`, `reviewer`)
- `ASK_USER` — Collects user input via AskUserQuestion
- `SYSTEM_DECISION` — Conditional branching based on previous task result

**Available Skills (SKILL type):**
| task_name | Skill | Description |
|-----------|-------|-------------|
| interview | omb-interview | Requirements gathering |
| create-plan | omb-create-plan | Planning workflow |
| review-plan | omb-review-plan | Multi-agent plan review |
| execute | omb-execute | TDD execution |
| verify | omb-verify | Verification with evidence |
| document | omb-document | Documentation generation |
| create-pr | omb-create-pr | PR creation |
| review-pr | omb-review-pr | PR review |
| commit-to-pr | omb-commit-to-pr | Commit to existing PR |

**Available Sub-Agents (SUB-AGENT type):**
List agent names from `.claude/agents/omb/*.md` (e.g., executor, critic, reviewer, planner, etc.)

### 2A-2. Gather pipeline design

Use `AskUserQuestion` iteratively to gather:
1. **Goal**: What is this pipeline for?
2. **Steps**: Which steps are needed? (propose based on goal)
3. **Dependencies**: Sequential or parallel execution?
4. **Branching**: Any conditional logic (SYSTEM_DECISION)?

Note: Checkpoint configuration is handled in STEP 2D (after pipeline state is built).

### 2A-3. Propose and iterate

Present the proposed pipeline as a table:

```
| # | task_name | task_type | checkpoint | max_retries | depends_on |
|---|-----------|-----------|-----------|-------------|------------|
| 0 | ask-user  | ASK_USER  | false     | 0           | —          |
| 1 | ...       | SKILL     | false     | 0           | task 0     |
```

Ask user if they want to modify. Repeat until confirmed.

### 2A-4. Build tasks JSON and initialize via CLI

Convert the confirmed pipeline design into a JSON array where each task has:
- `task_name` (string)
- `task_type` (string: SKILL, SUB-AGENT, ASK_USER, SYSTEM_DECISION)
- `task_payload` (string or null)
- `checkpoint` (boolean)
- `max_retries` (integer)
- `depends_on_index` (list of integer indices referencing other tasks by position)

Then run via Bash:

```bash
omb task init --manual --tasks-json '<tasks_json>' --name '<name>' --description '<desc>'
```

Extract `session_id` from the output. Then proceed to STEP 2D.

### 2A-5. Save as template (optional)

Ask via `AskUserQuestion`: "Save this pipeline as a reusable template in `.omb/schema/`?"
- If yes: copy the session file to `.omb/schema/<slugified-name>.json` with `session_id` set to `"TEMPLATE"`
- If no: proceed to STEP 3

## STEP 2B — Pre-made Template Mode

### 2B-1. Initialize pipeline via CLI

Run the shell script with the selected template:

```bash
omb task init "<template_name_or_alias>" --name "<name>" --description "<desc>"
```

**Examples:**
```bash
# Using alias
omb task init fix --name "Fix login bug"

# Using full display name
omb task init "ASK_USER - Plan - Review" --name "Auth refactor"

# With description
omb task init full --name "New feature" --description "Add user settings page"
```

### 2B-2. Capture output

The CLI outputs:
```
session_id: 202604061523-x7k2mq
name: Fix login bug

Wave 0: [ask-user]
Wave 1: [create-plan]
Wave 2: [review-plan]
...

Saved: .omb/sessions/202604061523-x7k2mq.json
```

Extract the `session_id` from the first line. If the CLI exits non-zero, report the error from stderr and stop.

Then proceed to STEP 2D.

## STEP 2D — Checkpoint Configuration

After the pipeline is initialized, ask the user about checkpoint (Human Review) preferences.

### 2D-1. Identify SKILL tasks

From the CLI output or by reading the session file, identify all tasks with `task_type: "SKILL"`. These are the eligible checkpoint candidates. Exclude `ASK_USER` and `SYSTEM_DECISION` tasks.

### 2D-2. Ask checkpoint preference

Use `AskUserQuestion` with the following format:

> Pipeline 실행 중 중간에 멈추고 사람이 확인(Human Review)할 단계를 선택하세요.
> Checkpoint가 설정된 단계에서는 pipeline이 일시 정지되고, 사용자 확인 후 다음 단계로 진행됩니다.

Options (numbered list):
1. **모두 자동으로 진행** (checkpoint 없음) — Pipeline이 처음부터 끝까지 자동으로 실행됩니다
2. Each SKILL task_name from the pipeline (e.g., `interview`, `create-plan`, `review-plan`, `execute`, `verify`, `document`, `create-pr`)

The user may select one or multiple step names (comma-separated).

### 2D-3. Apply checkpoint settings via CLI

- If the user selects **"모두 자동으로 진행"** (option 1):
  - No action needed. Proceed to STEP 3.

- If the user selects specific step(s):
  - Run via Bash:
    ```bash
    omb task checkpoint <session_id> --tasks "review-plan,verify"
    ```
  - Display the CLI output confirming checkpoint configuration.
  - Proceed to STEP 3.

## STEP 3 — Verification (CLI-handled)

Validation, wave computation, and save are all performed by `omb task init`. This step only applies if you need to verify an existing session:

```bash
# Re-read the session to confirm it's valid
omb progress <session_id>
```

If the CLI reported errors during STEP 2B or 2A-4, fix the input and re-run. Do NOT manually construct JSON.

## STEP 4 — Report and Transition

Display:
- Session ID
- Pipeline name and description
- Wave structure (from CLI output in STEP 2B)
- First task to execute
- SYSTEM_DECISION branching info (if review-pr pipeline)

<system_decision_branching>
### SYSTEM_DECISION: judge task behavior

The `judge` task in the review-pr pipeline performs conditional branching:

1. Read the result of the immediately preceding task (`review-pr`)
2. **If `APPROVED`**: mark all subsequent tasks (create-plan through create-pr) as `SKIPPED`, set judge result to `APPROVED`
3. **If `NEEDS_REVISION` or `REJECT`**: set judge result to `APPROVED` and let the pipeline continue normally to create-plan

The `omb-run` skill handles SYSTEM_DECISION task execution by reading the previous task's result and applying skip logic.
</system_decision_branching>

Then ask the user via `AskUserQuestion`:
- "Start pipeline now? (recommended: --worktree mode for isolated execution)"
- Options:
  - Yes, with --worktree (recommended)
  - Yes, without --worktree
  - No (I'll start it later)

If the user selects **Yes, with --worktree**: invoke `Skill("omb-run")` with arguments `--worktree <session_id>`.
If the user selects **Yes, without --worktree**: invoke `Skill("omb-run")` with arguments `<session_id>`.
If the user selects **No**: display both run commands for later use:
  - `/omb run --worktree <session_id>` (recommended)
  - `/omb run <session_id>`

## Completion Signal

State "DONE" with session_id and pipeline summary.

**[HARD] STOP AFTER REPORTING OR AFTER omb-run INVOCATION**

---

## Pipeline Templates Reference

<pipeline_templates>

### Interview - Plan - Review - Execute - Verify - Document - Create PR
| Order | task_name | task_type | checkpoint | max_retries |
|-------|-----------|-----------|-----------|-------------|
| 0 | ask-user | ASK_USER | false | 0 |
| 1 | interview | SKILL | false | 0 |
| 2 | create-plan | SKILL | false | 0 |
| 3 | review-plan | SKILL | true | 2 |
| 4 | execute | SKILL | false | 0 |
| 5 | verify | SKILL | false | 0 |
| 6 | document | SKILL | false | 0 |
| 7 | create-pr | SKILL | false | 0 |

### ASK_USER - Plan - Review - Execute - Verify - Document - Create PR
| Order | task_name | task_type | checkpoint | max_retries |
|-------|-----------|-----------|-----------|-------------|
| 0 | ask-user | ASK_USER | false | 0 |
| 1 | create-plan | SKILL | false | 0 |
| 2 | review-plan | SKILL | true | 2 |
| 3 | execute | SKILL | false | 0 |
| 4 | verify | SKILL | false | 0 |
| 5 | document | SKILL | false | 0 |
| 6 | create-pr | SKILL | false | 0 |

### ASK_USER - Plan - Review
| Order | task_name | task_type | checkpoint | max_retries |
|-------|-----------|-----------|-----------|-------------|
| 0 | ask-user | ASK_USER | false | 0 |
| 1 | create-plan | SKILL | false | 0 |
| 2 | review-plan | SKILL | true | 2 |

### ASK_USER - Execute - Verify - Document - Create PR
| Order | task_name | task_type | checkpoint | max_retries |
|-------|-----------|-----------|-----------|-------------|
| 0 | ask-user | ASK_USER | false | 0 |
| 1 | execute | SKILL | false | 0 |
| 2 | verify | SKILL | false | 0 |
| 3 | document | SKILL | false | 0 |
| 4 | create-pr | SKILL | false | 0 |

### ASK_USER - Review PR - Judge - Plan - Review - Execute - Verify - Document - Create PR
| Order | task_name | task_type | checkpoint | max_retries |
|-------|-----------|-----------|-----------|-------------|
| 0 | ask-user | ASK_USER | false | 0 |
| 1 | review-pr | SKILL | false | 0 |
| 2 | judge | SYSTEM_DECISION | false | 0 |
| 3 | create-plan | SKILL | false | 0 |
| 4 | review-plan | SKILL | true | 2 |
| 5 | execute | SKILL | false | 0 |
| 6 | verify | SKILL | false | 0 |
| 7 | document | SKILL | false | 0 |
| 8 | create-pr | SKILL | false | 0 |

</pipeline_templates>
