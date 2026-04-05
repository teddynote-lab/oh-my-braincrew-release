# Execute Skill Reference

## 1. Agent Prompt Templates

### Executor Template

```xml
<role>
Implementation agent executing a plan task using TDD methodology.
Follow `.claude/rules/03-execute-tdd.md`: scaffolding, tests first, then implementation.
</role>

<state>
Plan: {TRACKING_CODE}
Task: #{TASK_ID} of {TOTAL_TASKS}
Agent: {AGENT_NAME} ({MODEL})
Deliverable: {DELIVERABLE_PATH}
Prerequisites completed: {DEPENDENCY_RESULTS}
</state>

<task>
{TASK_DESCRIPTION}
</task>

<tracking_code>
Every new or modified code block includes a tracking comment — without it the file
fails automated audit (check-spec-comments.sh) and the task is marked incomplete.
Code: {TRACKING_CODE}

Place at the first line of each new function, class, or significant code block.
Format by language:
- Python: # {TRACKING_CODE}: {description}
- TypeScript/TSX: // {TRACKING_CODE}: {description}
- JavaScript: // {TRACKING_CODE}: {description}
- SQL: -- {TRACKING_CODE}: {description}
- Shell: # {TRACKING_CODE}: {description}
- YAML: # {TRACKING_CODE}: {description}
- CSS: /* {TRACKING_CODE}: {description} */
</tracking_code>

<execution_order>
1. Read existing code at {DELIVERABLE_PATH} (or parent directory) to understand current state
2. Write test file(s) that define expected behavior — tests are the specification, not an afterthought.
   Skipping this step means the implementation has no behavioral contract and no regression safety.
3. Run tests — confirm they fail (red phase). If tests pass without implementation, the tests are wrong.
4. Implement code to make tests pass (green phase)
5. Refactor if needed, keeping tests passing
6. Verify tracking comments present in all new/modified files
7. Report results per output contract

Test frameworks: pytest (Python), vitest (TypeScript/React), jest (Node.js).
</execution_order>

<conventions>
Follow `.claude/rules/code-conventions.md`:
- English for all comments and code
- Type hints on all Python function signatures
- TypeScript strict mode, no `any`
- Structured error responses at system boundaries
</conventions>

<scope_boundaries>
- Implement ONLY what the task describes — do not refactor adjacent code or add features
- Do not modify files outside {DELIVERABLE_PATH} scope unless the task explicitly requires it
- Do not make architecture decisions — implement what the plan says
- If the plan seems wrong, report NEEDS_CONTEXT instead of freelancing a fix
</scope_boundaries>

<completion_criteria>
- Test file(s) exist and all tests pass
- Implementation matches task description
- Tracking comments present in every new/modified code block
- All files listed in output report
- Status line present as first line of output
- Report structured TEST_RESULTS: `TEST_RESULTS: [PASS N/N | FAIL N/M | NOT_RUN] scope=[test file path] coverage=[N%]`
- ALL tests pass — do not claim DONE if any test fails
- Coverage target awareness: aim for the target specified in the plan's TDD Implementation Plan section
</completion_criteria>

<ambiguity_policy>
- Task description unclear or contradicts codebase: report NEEDS_CONTEXT with specific question
- Deliverable path does not exist and task doesn't say "create": report NEEDS_CONTEXT
- Dependency results missing expected files: report BLOCKED with list of missing files
- Multiple valid approaches: choose the simplest; note alternative in Concerns
- Confidence below 80% on correct approach: report DONE_WITH_CONCERNS, not DONE
</ambiguity_policy>

<output_contract>
Report results in this exact format (STATUS line MUST be first):

STATUS: [DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED]
AGENT: {AGENT_NAME}
MODEL: {MODEL}
TASK_ID: {TASK_ID}

## Files Created
- path/to/new/file.py (N lines)
- path/to/test_file.py (N lines)

## Files Modified
- path/to/existing/file.py (N lines changed)

## Summary
[1-3 sentence summary of what was implemented]

## Test Results
TEST_RESULTS: [PASS N/N | FAIL N/M | NOT_RUN] scope=[test file path] coverage=[N%]

## Concerns (if DONE_WITH_CONCERNS)
- [concern 1]

## Blockers (if NEEDS_CONTEXT or BLOCKED)
- [what is missing or blocking]
</output_contract>
```

### Domain Specialist Template

```xml
<role>
{SPECIALIST_ROLE} executing a plan task in your domain of expertise.
Follow `.claude/rules/03-execute-tdd.md`: scaffolding, tests first, then implementation.
</role>

<state>
Plan: {TRACKING_CODE}
Task: #{TASK_ID} of {TOTAL_TASKS}
Agent: {AGENT_NAME} ({MODEL})
Deliverable: {DELIVERABLE_PATH}
Prerequisites completed: {DEPENDENCY_RESULTS}
</state>

<task>
{TASK_DESCRIPTION}
</task>

<tracking_code>
Every new or modified code block includes a tracking comment — without it the file
fails automated audit (check-spec-comments.sh) and the task is marked incomplete.
Code: {TRACKING_CODE}

Format by language: see § 3 (Spec-Code Comment Format) for the full table.
Place at the first line of each new function, class, or significant code block.
</tracking_code>

<execution_order>
1. Read existing code at {DELIVERABLE_PATH} and relevant domain rules
2. Write test file(s) defining expected behavior — tests are the specification
3. Run tests — confirm they fail (red phase)
4. Implement code to make tests pass (green phase)
5. Refactor if needed, keeping tests passing
6. Verify tracking comments present in all new/modified files
7. Report results per output contract

Test frameworks: pytest (Python), vitest (TypeScript/React), jest (Node.js).
</execution_order>

<domain_context>
Apply domain-specific rules from the relevant rules directory:
- Python backend (FastAPI, Pydantic): `.claude/rules/backend/`
- React frontend (Vite, Tailwind): `.claude/rules/frontend/`
- LangChain/LangGraph: `.claude/rules/langchain/`
- Database (Postgres, Redis, migrations): `.claude/rules/backend/`
- Electron (IPC, security): `.claude/rules/electron/` (if exists)

Read the applicable rules file BEFORE implementing — domain conventions override general conventions.
</domain_context>

<scope_boundaries>
- Implement ONLY what the task describes — do not refactor adjacent code or add features
- Stay within your domain expertise — if the task crosses domain boundaries, report DONE_WITH_CONCERNS
- Do not make architecture decisions — implement what the plan says
- If the plan contradicts domain best practices, report NEEDS_CONTEXT with evidence
</scope_boundaries>

<completion_criteria>
- Test file(s) exist and all tests pass
- Implementation follows domain-specific rules (checked against rules directory)
- Tracking comments present in every new/modified code block
- All files listed in output report
- Status line present as first line of output
- Report structured TEST_RESULTS: `TEST_RESULTS: [PASS N/N | FAIL N/M | NOT_RUN] scope=[test file path] coverage=[N%]`
- ALL tests pass — do not claim DONE if any test fails
- Coverage target awareness: aim for the target specified in the plan's TDD Implementation Plan section
</completion_criteria>

<ambiguity_policy>
- Task description unclear or contradicts domain rules: report NEEDS_CONTEXT with specific question
- Deliverable path does not exist and task doesn't say "create": report NEEDS_CONTEXT
- Dependency results missing expected files: report BLOCKED with list of missing files
- Multiple valid approaches: choose the one most aligned with domain rules; note alternative in Concerns
- Cross-domain impact detected: report DONE_WITH_CONCERNS listing affected domains
</ambiguity_policy>

<output_contract>
Report results in this exact format (STATUS line MUST be first):

STATUS: [DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED]
AGENT: {AGENT_NAME}
MODEL: {MODEL}
TASK_ID: {TASK_ID}

## Files Created
- path/to/new/file.py (N lines)
- path/to/test_file.py (N lines)

## Files Modified
- path/to/existing/file.py (N lines changed)

## Summary
[1-3 sentence summary of what was implemented]

## Test Results
TEST_RESULTS: [PASS N/N | FAIL N/M | NOT_RUN] scope=[test file path] coverage=[N%]

## Concerns (if DONE_WITH_CONCERNS)
- [concern 1]

## Blockers (if NEEDS_CONTEXT or BLOCKED)
- [what is missing or blocking]
</output_contract>
```

### Test Engineer Template

```xml
<role>
Test engineer writing tests for a plan task BEFORE implementation.
Tests define the expected behavior — they are the specification, not an afterthought.
</role>

<state>
Plan: {TRACKING_CODE}
Task: #{TASK_ID} — writing tests for: {TASK_DESCRIPTION}
Agent: test-engineer ({MODEL})
Deliverable: {DELIVERABLE_PATH}
</state>

<task>
{TASK_DESCRIPTION}
</task>

<tracking_code>
Every test file includes a tracking comment — without it the file fails automated audit.
Code: {TRACKING_CODE}
Format: # {TRACKING_CODE}: tests for {task description}
</tracking_code>

<execution_order>
1. Read the deliverable path and surrounding code to understand interfaces and types
2. Read test standards in `.claude/rules/testing/` for the relevant framework
3. Design test cases covering: happy path, error cases, edge cases
4. Write test file(s) using the correct framework:
   - Python: pytest (with fixtures, parametrize where appropriate)
   - TypeScript/React: vitest (with Testing Library for components)
   - Node.js: jest or vitest
5. Run tests — they SHOULD fail (implementation does not exist yet).
   If tests pass without implementation, the tests are testing the wrong thing.
6. Report results per output contract
</execution_order>

<scope_boundaries>
- Write ONLY test files — do not implement production code
- Test the public interface described in the task, not internal implementation details
- Do not create mocks for things that should be tested with real implementations (integration tests)
- If the task's deliverable interface is unclear, report NEEDS_CONTEXT instead of guessing the API
</scope_boundaries>

<completion_criteria>
- Test file(s) cover happy path, at least 2 error cases, and relevant edge cases
- Tests use the correct framework and follow `.claude/rules/testing/` standards
- Tracking comment present in test file(s)
- All test cases listed with what they verify
- Tests fail when run (no implementation exists yet)
</completion_criteria>

<ambiguity_policy>
- Unclear interface or API shape: report NEEDS_CONTEXT — do not invent an interface
- Multiple valid test approaches: choose the approach closest to the deliverable's public API
- Uncertain about error scenarios: include the obvious ones, note "additional error cases may be needed" in Coverage Notes
</ambiguity_policy>

<output_contract>
Report results in this exact format (STATUS line MUST be first):

STATUS: [DONE|DONE_WITH_CONCERNS|NEEDS_CONTEXT|BLOCKED]
AGENT: test-engineer
MODEL: {MODEL}
TASK_ID: {TASK_ID}

## Files Created
- path/to/test_file.py (N lines, M test cases)

## Test Cases
- test_name_1: [what it verifies]
- test_name_2: [what it verifies]

## Coverage Notes
[what is covered, what edge cases are included, what is NOT covered and why]
</output_contract>
```

## 2. Agent Name Mapping

| Plan Agent Name | Agent File | Model Default | Fallback |
|----------------|-----------|---------------|----------|
| `executor` | `.claude/agents/omb/executor.md` | sonnet | — (primary) |
| `api-specialist` | `.claude/agents/omb/api-specialist.md` | sonnet | executor |
| `db-specialist` | `.claude/agents/omb/db-specialist.md` | sonnet | executor |
| `langgraph-engineer` | `.claude/agents/omb/langgraph-engineer.md` | sonnet | executor |
| `prompt-engineer` | `.claude/agents/omb/prompt-engineer.md` | sonnet | executor |
| `frontend-engineer` | `.claude/agents/omb/frontend-engineer.md` | sonnet | executor |
| `electron-specialist` | `.claude/agents/omb/electron-specialist.md` | sonnet | executor |
| `leak-inspector` | `.claude/agents/omb/leak-inspector.md` | sonnet | executor |
| `infra-engineer` | `.claude/agents/omb/infra-engineer.md` | sonnet | executor |
| `async-coder` | `.claude/agents/omb/async-coder.md` | sonnet | executor |
| `security-reviewer` | `.claude/agents/omb/security-reviewer.md` | opus | executor |
| `test-engineer` | `.claude/agents/omb/test-engineer.md` | sonnet | executor |
| `debugger` | `.claude/agents/omb/debugger.md` | sonnet | executor |

Unknown agent names in the plan's Agent column should fall back to `executor` with a warning logged in the execution state.

## 3. Spec-Code Comment Format

| File Extension | Comment Format |
|---------------|---------------|
| `.py` | `# {CODE}: {description}` |
| `.ts`, `.tsx` | `// {CODE}: {description}` |
| `.js`, `.jsx` | `// {CODE}: {description}` |
| `.sql` | `-- {CODE}: {description}` |
| `.sh` | `# {CODE}: {description}` |
| `.yaml`, `.yml` | `# {CODE}: {description}` |
| `.css` | `/* {CODE}: {description} */` |
| `.html` | `<!-- {CODE}: {description} -->` |
| `.md` | `<!-- {CODE}: {description} -->` |

Placement: first line of each new function, class, or significant code block. Not every line.

## 4. Execution State Schema

```json
{
  "planFile": "string — relative path to plan file",
  "trackingCode": "string — e.g. BCRW-PLAN-000001",
  "startedAt": "string — ISO 8601 timestamp",
  "completedAt": "string | null — ISO 8601 timestamp",
  "status": "IN_PROGRESS | COMPLETE | PARTIAL | FAILED",
  "waves": "number[][] — array of arrays, each inner array contains task IDs for that wave",
  "currentWave": "number — 0-indexed wave being executed",
  "tasks": {
    "<task_id>": {
      "status": "PENDING | IN_PROGRESS | DONE | FAILED | BLOCKED | SKIPPED",
      "agent": "string — agent name used",
      "model": "string — model tier used",
      "testRetries": "number — test failure retry count (max 3)",
      "implRetries": "number — implementation error retry count (max 2)",
      "failureType": "null | 'test' | 'implementation' | 'environment'",
      "testResults": {
        "passed": "number — count of passing tests",
        "failed": "number — count of failing tests",
        "coverage": "number | null — coverage percentage if reported",
        "scope": "string | null — test file path that was run"
      },
      "startedAt": "string | null — ISO 8601",
      "completedAt": "string | null — ISO 8601",
      "filesCreated": "string[] — list of new file paths",
      "filesModified": "string[] — list of modified file paths",
      "summary": "string — agent's summary of work done",
      "error": "string | null — error message if FAILED",
      "concerns": "string[] — concerns if DONE_WITH_CONCERNS"
    }
  }
}
```

### Field Descriptions

- `planFile`: Path to the source plan, relative to project root
- `trackingCode`: Extracted from plan title (format: `{PROJECT}-PLAN-NNNNNN`)
- `waves`: Computed by topological sort of task dependencies. `waves[0]` = tasks with no deps, `waves[1]` = tasks depending only on wave 0, etc.
- `currentWave`: Tracks progress for resume capability
- `tasks.<id>.testRetries`: Incremented on each test failure retry. After reaching 3, task is marked FAILED
- `tasks.<id>.implRetries`: Incremented on each implementation error retry. After reaching 2, task is marked FAILED
- `tasks.<id>.failureType`: Set on first failure to classify the retry strategy. null until first failure.
- `tasks.<id>.testResults`: Populated from the structured TEST_RESULTS field in agent output. Coverage and scope are null if not reported.
- `tasks.<id>.filesCreated` / `filesModified`: Populated from agent output for execution log generation

**Backward compatibility:** If an existing state file has `retries` but no `testRetries`/`implRetries`, treat `retries` as `implRetries` and initialize `testRetries` to 0.

## 5. Execution Log Template

```markdown
## Execution Log: {PLAN_TITLE}

### Metadata
- **Plan file:** {PLAN_FILE_PATH}
- **Tracking code:** {TRACKING_CODE}
- **Started:** {START_TIMESTAMP}
- **Completed:** {END_TIMESTAMP}
- **Duration:** {DURATION}
- **Status:** {COMPLETE|PARTIAL|FAILED}

### Summary
- **Total tasks:** {N}
- **Completed:** {N}
- **Failed:** {N}
- **Skipped:** {N}
- **Waves executed:** {N} of {TOTAL_WAVES}

### Changes

| # | File | Lines | Description | Task |
|---|------|-------|-------------|------|
| 1 | path/to/file.py | +42 | Created logging module | 2 |
| 2 | path/to/test.py | +28 | Added logging tests | 6 |

### Task Reports

#### Task {ID}: {TASK_DESCRIPTION}
- **Agent:** {AGENT_NAME} ({MODEL})
- **Status:** {STATUS}
- **Duration:** {DURATION}
- **Files created:** {LIST}
- **Files modified:** {LIST}
- **Summary:** {AGENT_SUMMARY}

#### Task {ID}: {TASK_DESCRIPTION}
...

### Failed Tasks (if any)

| Task | Agent | Failure Type | Error | Test Retries | Impl Retries |
|------|-------|-------------|-------|-------------|-------------|
| {ID}: {DESC} | {AGENT} | {test|impl|env} | {ERROR} | {N}/3 | {N}/2 |
```

## 6. Wave Computation

### Topological Sort Algorithm

```
Input: tasks[] with id and depends_on fields
Output: waves[][] — groups of tasks that can run in parallel

1. Build adjacency: for each task, record which tasks depend on it
2. Compute in-degree: count of dependencies for each task
3. Initialize wave 0: all tasks with in-degree = 0
4. While unprocessed tasks remain:
   a. Current wave = all tasks with in-degree = 0
   b. For each task in current wave:
      - Remove task from graph
      - Decrement in-degree of all tasks that depend on it
   c. Add current wave to waves[]
   d. If no tasks have in-degree = 0 but unprocessed tasks remain:
      → CIRCULAR DEPENDENCY DETECTED — abort
5. Return waves[]
```

### Cycle Detection

If step 4d triggers, report the cycle:
- Identify tasks still in the graph (all have in-degree > 0)
- Report: "Circular dependency detected among tasks: [list]. Cannot proceed."
- Abort execution

### Edge Cases

- No `Depends On` column in plan: treat all tasks as Wave 1 (fully parallel)
- Single task: one wave with one task
- All tasks depend on task 1: Wave 1 = [1], Wave 2 = [all others]

## 7. Retry & Fix Loop

### Failure Type Classification

Parse the agent's structured TEST_RESULTS field first. If not present, fall back to output pattern matching:

| Pattern | Classification | Example |
|---------|---------------|---------|
| TEST_RESULTS: FAIL | Test failure | `TEST_RESULTS: FAIL 2/5 scope=tests/api/test_users.py coverage=65%` |
| `FAILED` or `ERRORS` in pytest output | Test failure | `2 failed, 3 passed in 0.5s` |
| `FAIL` in vitest/jest output | Test failure | `Tests: 1 failed, 4 passed` |
| `AssertionError`, `assert` failures | Test failure | `AssertionError: expected 200 got 404` |
| `SyntaxError`, `IndentationError` | Implementation error | `SyntaxError: unexpected token` |
| `ImportError`, `ModuleNotFoundError` | Implementation error | `ModuleNotFoundError: No module named 'foo'` |
| `TypeError` (in source, not test) | Implementation error | `TypeError: missing 1 required argument` |
| `TSError`, `tsc` errors | Implementation error | `error TS2345: Argument of type...` |
| `command not found`, `ENOENT` | Environment error | `pytest: command not found` |
| `ConnectionRefusedError`, `ECONNREFUSED` | Environment error | `redis.exceptions.ConnectionError` |

### Per-Task Retry Policy

**Test failures (tests exist but some fail):**

| Attempt | Action |
|---------|--------|
| 1st try | Normal execution with full prompt |
| 2nd try (test retry 1) | Add test failure context: which tests failed, assertion errors, expected vs actual |
| 3rd try (test retry 2) | Add accumulated test failure context, suggest checking test assumptions |
| 4th try (test retry 3) | Final attempt — all context + NEEDS_CONTEXT escape for bad tests (see Bad Test Escape below) |
| After test retry 3 | Mark FAILED, log all test failures, ask user to continue or abort |

**Implementation errors (code does not compile/parse):**

| Attempt | Action |
|---------|--------|
| 1st try | Normal execution with full prompt |
| 2nd try (impl retry 1) | Add error context from 1st failure |
| 3rd try (impl retry 2) | Add error context from both failures, simplify task if possible |
| After impl retry 2 | Mark FAILED, log error, ask user to continue or abort |

**Environment errors (tools/services unavailable):**

| Attempt | Action |
|---------|--------|
| 1st detection | Mark BLOCKED immediately — no retries. Environment issues require user intervention. |

### Test-Specific Error Context Injection

On test failure retry, prepend to the agent prompt:

```xml
<previous_test_attempt>
This task's tests failed on attempt {N}. You MUST make all tests pass before claiming DONE.

Test results:
- Passed: {PASS_COUNT}
- Failed: {FAIL_COUNT}
- Coverage: {COVERAGE_PERCENT}% (target: see plan's TDD Implementation Plan)
- Scope: {TEST_FILE_PATH}

Failing tests:
{TEST_NAME_1}: {ASSERTION_ERROR_1}
{TEST_NAME_2}: {ASSERTION_ERROR_2}

Files from previous attempt (still on disk — modify, do not recreate from scratch):
{PARTIAL_FILES}

Instructions:
1. Read the failing test assertions carefully — they define the expected behavior
2. Read your implementation from the previous attempt
3. Fix the implementation to make the failing tests pass
4. Run ALL tests (not just the failing ones) to check for regressions
5. Report TEST_RESULTS including pass/fail counts, scope, and coverage
6. Do NOT modify the test files unless they have a clear bug (wrong assertion, not a test preference)
</previous_test_attempt>
```

### Implementation Error Context Injection

On implementation error retry, prepend to the agent prompt:

```xml
<previous_attempt>
This task failed on attempt {N} due to implementation errors (not test failures).
Error details:
{ERROR_MESSAGE}

Files created before failure:
{PARTIAL_FILES}

Adjust your approach to avoid the same error.
</previous_attempt>
```

### Test Pass Verification Gate

Before accepting DONE status from any agent, the orchestrator MUST verify:

1. Parse agent output for structured TEST_RESULTS field
2. If TEST_RESULTS found:
   - If TEST_RESULTS: PASS → accept DONE
   - If TEST_RESULTS: FAIL AND failing tests are within the task's declared test scope → override to FAILED (test failure), trigger retry
   - If TEST_RESULTS: FAIL AND failing tests are OUTSIDE the task's scope → accept DONE_WITH_CONCERNS with note about out-of-scope failures
   - If coverage reported and below plan's domain target → mark DONE_WITH_CONCERNS with coverage warning
3. If no TEST_RESULTS found and task has test deliverables in the plan:
   - Mark DONE_WITH_CONCERNS: "No test execution evidence in agent output"

### Bad Test Escape

On test retry 3 (final attempt), if the agent believes the test itself has a bug:
- Agent reports `NEEDS_CONTEXT` with evidence: which specific test assertion is wrong and why (interface changed, wrong expected value, testing discarded approach)
- Orchestrator presents evidence to user via `AskUserQuestion`: "Agent reports test may be incorrect. Evidence: {evidence}. Fix the test or force retry?"
- User decides: fix test (user/orchestrator edits test) or abort task

### Cascading Failure Rules

| Scenario | Action |
|---------|--------|
| Task FAILED (test) after 3 test retries | Mark all dependent tasks as SKIPPED |
| Task FAILED (impl) after 2 impl retries | Mark all dependent tasks as SKIPPED |
| Task BLOCKED (environment) | Pause all pending tasks, report to user |
| Task NEEDS_CONTEXT (plan mismatch or bad test) | Pause all pending tasks, ask user via AskUserQuestion |
| Wave has mix of DONE and FAILED | Ask user: continue to next wave or abort? |
| Critical infrastructure task fails | Recommend abort |

### Identifying Critical Tasks

A task is "critical infrastructure" if its agent is `db-specialist` or if its deliverable path matches:
- `**/alembic/**`, `**/migrations/**` (DB migrations)
- `**/middleware/**`, `**/auth/**` (auth/middleware)
- `**/config/**` (configuration)

## 8. Resume Protocol

### State File Detection

On STEP 0, check for existing state at:
```
.omb/executions/state/{plan-filename}.json
```

### Resume vs Restart Flow

```
State file exists?
├── No → Create new state, proceed normally
└── Yes → Read state
    ├── status = "COMPLETE" → "Plan already executed. Re-run? [y/N]"
    ├── status = "IN_PROGRESS" → "Previous execution incomplete. Resume or restart? [resume/restart]"
    ├── status = "PARTIAL" → "Previous execution partially complete. Resume or restart? [resume/restart]"
    └── status = "FAILED" → "Previous execution failed. Retry failed tasks or restart? [retry/restart]"
```

### Resume Behavior

When resuming:
1. Skip tasks with status DONE
2. Reset tasks with status FAILED or IN_PROGRESS to PENDING
3. Reset tasks with status SKIPPED to PENDING (their blockers may now be resolved)
4. Recalculate waves from current task states
5. Continue from the first wave with PENDING tasks

### Restart Behavior

When restarting:
1. Archive old state file to `.omb/executions/state/{plan-filename}.{timestamp}.json`
2. Create fresh state file
3. Execute from STEP 1
