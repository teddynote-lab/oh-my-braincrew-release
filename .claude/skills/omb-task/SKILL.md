---
name: omb-task
user-invocable: true
description: >
  Use when initializing a new pipeline session. Creates a session schema file
  (.omb/sessions/<session_id>.json) from pre-made templates or interactive Manual mode.
  Validates schema before saving. Triggers on:
  "task", "init pipeline", "create pipeline", "start pipeline", "new session".
argument-hint: "[template-name|manual] [--name '<pipeline-name>'] [--description '<desc>']"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# Init Pipeline

Create a new pipeline session file from a pre-made schema template or via interactive Manual mode.

<references>
The following files are for harness development only (not used at skill runtime):
- `src/omb/pipeline/types.py` — PipelineState and TaskState models
- `src/omb/pipeline/definitions.py` — Pipeline templates
- `src/omb/pipeline/validation.py` — Schema validation
- `src/omb/pipeline/waves.py` — Wave computation

Pre-made schema templates are stored in `.omb/schema/`.
</references>

<completion_criteria>
- Session JSON file created at `.omb/sessions/<session_id>.json`
- Schema passes all 6 validation rules
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
3. **Checkpoints**: Any steps that need approval before continuing? (suggest review-plan)
4. **Dependencies**: Sequential or parallel execution?
5. **Branching**: Any conditional logic (SYSTEM_DECISION)?

### 2A-3. Propose and iterate

Present the proposed pipeline as a table:

```
| # | task_name | task_type | checkpoint | max_retries | depends_on |
|---|-----------|-----------|-----------|-------------|------------|
| 0 | ask-user  | ASK_USER  | false     | 0           | —          |
| 1 | ...       | SKILL     | false     | 0           | task 0     |
```

Ask user if they want to modify. Repeat until confirmed.

### 2A-4. Save as template (optional)

Ask via `AskUserQuestion`: "Save this pipeline as a reusable template in `.omb/schema/`?"
- If yes: ask for a template name, slugify it, and save to `.omb/schema/<slugified-name>.json`
- If no: proceed to STEP 3

Then proceed to STEP 2C with the manually designed task list.

## STEP 2B — Pre-made Template Mode

### 2B-1. Load schema template

Read the corresponding schema file from `.omb/schema/`:

| Template | Schema File |
|----------|------------|
| Interview - Plan - Review - Execute - Verify - Document - Create PR | `.omb/schema/interview--plan-review-execute-verify-document-create-pr.json` |
| ASK_USER - Plan - Review - Execute - Verify - Document - Create PR | `.omb/schema/ask-user--plan-review-execute-verify-document-create-pr.json` |
| ASK_USER - Plan - Review | `.omb/schema/ask-user--plan-review.json` |
| ASK_USER - Execute - Verify - Document - Create PR | `.omb/schema/ask-user--execute-verify-document-create-pr.json` |
| ASK_USER - Review PR - Judge - Plan - Review - Execute - Verify - Document - Create PR | `.omb/schema/ask-user--review-pr-judge-plan-review-execute-verify-document-create-pr.json` |

### 2B-2. Prepare for instantiation

Read the schema JSON file. Then proceed to STEP 2C using the loaded task list.

## STEP 2C — Build Pipeline State

### 2C-1. Generate session_id

Format: `YYYYmmddHHMM-XXXXXX`
- `YYYYmmddHHMM` = current UTC datetime (e.g., `202604041523`)
- `XXXXXX` = 6 random lowercase alphanumeric characters (`a-z`, `0-9`)
- Example: `202604041523-x7k2mq`

### 2C-2. Generate task_ids

For each task in the loaded/designed template:
1. Generate a unique `task_id`: 6 random lowercase alphanumeric characters (`a-z`, `0-9`)
2. Ensure all task_ids are unique within the pipeline
3. Re-wire `depends_on` references to use the newly generated task_ids

### 2C-3. Build the full JSON

Construct the PipelineState JSON:

```json
{
  "session_id": "<generated session_id>",
  "name": "<pipeline-name from args or template display name>",
  "description": "<description from args or template description>",
  "status": "active",
  "user_id": null,
  "claude_session_id": null,
  "created_at": "<current UTC datetime in ISO 8601 format, e.g. 2026-04-04T15:23:00+00:00>",
  "current_task": 0,
  "notification": {
    "on_step_complete": true,
    "on_pipeline_complete": true,
    "on_failure": true
  },
  "tasks": [...]
}
```

**[HARD]** Required fields:
- `claude_session_id`: set to `null` (populated by session handler at runtime, used for fallback)
- `created_at`: set to current UTC datetime in ISO 8601 format
- Do NOT include `modified_at` field
- Each task must have: `task_id` (6-char lowercase alphanumeric), `task_name`, `task_type`, `task_payload`, `status`, `result`, `iteration`, `checkpoint`, `max_retries`, `notification`, `depends_on`, `recovery_depth`

**Task field reference:**
| Field | Type | Description |
|-------|------|-------------|
| `task_id` | string | 6-char lowercase alphanumeric, auto-generated |
| `task_name` | string | Name of the task (e.g., `ask-user`, `create-plan`, `judge`) |
| `task_type` | enum | One of: `SKILL`, `SUB-AGENT`, `ASK_USER`, `USER_PROMPT`, `SYSTEM_DECISION` |
| `task_payload` | string or null | Additional description/instructions for the task |

**[HARD]** Set `task_type` per the template: `"ASK_USER"` for `ask-user` tasks, `"SYSTEM_DECISION"` for `judge` tasks, `"SKILL"` for skill-mapped tasks. Set `checkpoint` and `max_retries` per the template. The `ask-user` task should have `task_payload` set to template-specific guidance text.

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

<system_decision_branching>
### SYSTEM_DECISION: judge task behavior

The `judge` task in the review-pr pipeline performs conditional branching:

1. Read the result of the immediately preceding task (`review-pr`)
2. **If `APPROVED`**: mark all subsequent tasks (create-plan through create-pr) as `SKIPPED`, set judge result to `APPROVED`
3. **If `NEEDS_REVISION` or `REJECT`**: set judge result to `APPROVED` and let the pipeline continue normally to create-plan

The `omb-run` skill handles SYSTEM_DECISION task execution by reading the previous task's result and applying skip logic.
</system_decision_branching>

### 2C-4. Wire depends_on (sequential linking)

Each task depends on the previous task in the template order:
- Task at order 0: `depends_on: []` (no dependencies)
- Task at order N (N > 0): `depends_on: ["<task_id of task at order N-1>"]`

## STEP 3 — Validate Schema

Apply all 6 validation rules to the constructed JSON. Collect ALL errors before reporting.

<validation_rules>

### Rule 1: Structural validation
Every required field must be present with the correct type:
- `session_id`: string
- `name`: string
- `status`: one of `active`, `completed`, `stalled`, `cancelled`
- `claude_session_id`: string or null
- `created_at`: valid ISO 8601 datetime string
- Each task must have: `task_id` (string), `task_name` (string), `task_type` (one of `SKILL`, `SUB-AGENT`, `USER_PROMPT`, `ASK_USER`, `SYSTEM_DECISION`), `status` (one of `pending`, `active`, `done`, `failed`, `skipped`), `depends_on` (list of strings)

### Rule 2: task_id uniqueness
No two tasks may share the same `task_id`.

### Rule 3: depends_on references must exist
Every `task_id` referenced in any task's `depends_on` must be a `task_id` of another task in the pipeline.

### Rule 4: No self-referential depends_on
A task's `depends_on` must not contain its own `task_id`.

### Rule 5: No circular dependencies
Apply Kahn's topological sort (see Step 4). If any tasks remain unvisited after the algorithm completes, a circular dependency exists.

### Rule 6: SKILL task_name must exist in TASK_SKILL_MAP
Every task with `task_type: "SKILL"` must have a `task_name` that maps to a known skill:

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

</validation_rules>

If validation fails, automatically fix the errors (e.g., regenerate duplicate task_ids, repair broken depends_on references) and re-validate. Only prompt the user if the errors cannot be automatically corrected.

## STEP 4 — Compute and Display Waves

Perform Kahn's topological sort to group tasks into waves:

1. For each task, count how many `depends_on` entries it has (its **in-degree**).
2. Start with all tasks that have in-degree 0 — these form **Wave 0**.
3. Remove Wave 0 tasks from the graph: for each task that depended on a Wave 0 task, decrement its in-degree.
4. All tasks now with in-degree 0 form **Wave 1**.
5. Repeat until all tasks are assigned to waves.
6. If any tasks remain with in-degree > 0 after the algorithm completes, report a circular dependency error.

Display the wave structure:
```
Wave 0: [task_name_1]
Wave 1: [task_name_2]
Wave 2: [task_name_3, task_name_4]
...
```

## STEP 5 — Save Session

```bash
mkdir -p .omb/sessions
```

Then use the `Write` tool to save the JSON to `.omb/sessions/<session_id>.json`.

## STEP 6 — Report and Transition

Display:
- Session ID
- Pipeline name and description
- Wave structure (from Step 4)
- First task to execute
- SYSTEM_DECISION branching info (if review-pr pipeline)

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
