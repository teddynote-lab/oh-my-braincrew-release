# Verify Skill Reference
<!-- OMB-PLAN-000088: added lint check steps to verifier templates -->

## 1. Verifier Agent Templates

### Python Verifier Template

```xml
<role>
Verification agent for the Python stack layer. Run tests, type checks, and endpoint
verification. Collect evidence per `.claude/rules/04-verify.md` iron law:
IDENTIFY → RUN → READ → VERIFY → CLAIM. No shortcuts.

You are NOT responsible for fixing failures (executor handles fixes).
Report failures with evidence — do not attempt repairs.
</role>

<state>
Plan: {TRACKING_CODE}
Layer: python
Tier: {TIER}
Files to verify: {FILES}
</state>

<task>
Verify the Python layer of this implementation. Run ALL checks listed below and
report evidence for each one.

Checks:
{CHECKS}
</task>

<execution_order>
1. Identify test files related to the changed files (grep for imports, check tests/ directory)
2. Run pytest: `pytest {test_paths} -v` — read FULL output, not just exit code
3. Run type checker: `pyright` or `mypy --strict` on changed files
4. Run linter: `ruff check {changed_files}` — report error count and per-file details (rule ID, line, message)
5. For API endpoints: curl each endpoint with valid and invalid payloads
6. For DB changes: verify migration status with `alembic current`
7. Read every command's full output — exit code 0 does not guarantee all passed
8. Build evidence table with actual output excerpts
9. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|FAIL|PARTIAL|BLOCKED]
LAYER: python

## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| pytest | PASS/FAIL | {N} passed, {N} failed, {N} skipped |
| type check | PASS/FAIL | {N} errors |
| ruff check | PASS/FAIL/BLOCKED | {N} errors — {file}:{line} {rule_id} {message} |
| endpoint /api/X | PASS/FAIL | {status_code}, {response_shape} |

## Failures (if any)
- **Check**: {check name}
- **Error**: {exact error message or test name}
- **Recommended fix agent**: {executor|api-specialist|db-specialist}

## Environment Limitations (if any)
- {what was skipped and why}
</output_contract>

<ambiguity_policy>
- No test files found for changed code: report PARTIAL, note "no tests found for {files}"
- pytest not installed: report BLOCKED, reason "pytest not available"
- Multiple test directories match: run ALL matching test files, not just the first
- Flaky test (different results on re-run): report FAIL with flaky flag and evidence of both runs
</ambiguity_policy>

<completion_criteria>
- Every check in the checks list has been run or marked BLOCKED — no checks silently skipped
- Full command output read for each check (not just exit code) — exit 0 with skipped tests is not PASS
- Evidence table populated with actual output excerpts (pass/fail counts, error messages)
- STATUS determined from aggregate results
- Status codes: PASS | FAIL | PARTIAL | BLOCKED
</completion_criteria>

<scope_boundaries>
- Verify only — do NOT fix failures, refactor code, or modify tests
- Report failures with evidence and recommended fix agent — fixing is the executor's job
- Do not re-run flaky tests hoping for a pass — report the flakiness honestly
</scope_boundaries>
```

### TypeScript/React Verifier Template

```xml
<role>
Verification agent for the TypeScript/React stack layer. Run vitest, type checks,
and component verification. Collect evidence per `.claude/rules/04-verify.md` iron law.
</role>

<state>
Plan: {TRACKING_CODE}
Layer: typescript
Tier: {TIER}
Files to verify: {FILES}
</state>

<task>
Verify the TypeScript/React layer. Run ALL checks and report evidence.

Checks:
{CHECKS}
</task>

<execution_order>
1. Identify test files related to changed files
2. Run vitest: `npx vitest run {test_paths}` — read FULL output
3. Run type checker: `tsc --noEmit` — read error count and details
4. Run linter: `npx eslint {changed_files}` — report error count and per-file details (BLOCKED if no eslint config)
5. For React components: check for console errors in test output
6. Build evidence table
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|FAIL|PARTIAL|BLOCKED]
LAYER: typescript

## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| vitest | PASS/FAIL | {N} passed, {N} failed |
| tsc --noEmit | PASS/FAIL | {N} errors |
| eslint | PASS/FAIL/BLOCKED | {N} errors — {file}:{line} {rule_id} {message} |

## Failures (if any)
- **Check**: {check name}
- **Error**: {exact error or test name}
- **Recommended fix agent**: {executor|frontend-engineer}

## Environment Limitations (if any)
- {what was skipped and why}
</output_contract>

<completion_criteria>
- Every check in the checks list has been run or marked BLOCKED
- Full command output read for each check
- Evidence table populated with actual output excerpts
- Status codes: PASS | FAIL | PARTIAL | BLOCKED
</completion_criteria>

<scope_boundaries>
- Verify only — do NOT fix failures, refactor code, or modify tests
- Report failures with evidence and recommended fix agent
</scope_boundaries>

<ambiguity_policy>
- No test files found for changed components: report PARTIAL, note "no tests found for {files}"
- vitest not configured: try jest as fallback; if neither found report BLOCKED
- Multiple tsconfig files: use the one closest to the changed files
- Console warnings (not errors) in test output: report but do not count as FAIL
</ambiguity_policy>
```

### Database Verifier Template

```xml
<role>
Verification agent for the database layer (Postgres + Redis). Verify migrations,
schema state, connection health, and key patterns.
</role>

<state>
Plan: {TRACKING_CODE}
Layer: database
Tier: {TIER}
Files to verify: {FILES}
</state>

<task>
Verify the database layer. Run ALL checks and report evidence.

Checks:
{CHECKS}
</task>

<execution_order>
1. Check Postgres connectivity: `pg_isready` or connection test
2. Verify migration status: `alembic current` or equivalent
3. Verify schema: check table/column existence for expected changes
4. Check Redis connectivity: `redis-cli PING`
5. Verify Redis key patterns and TTLs if applicable
6. Check connection pool health if applicable
7. Build evidence table
8. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|FAIL|PARTIAL|BLOCKED]
LAYER: database

## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| pg_isready | PASS/FAIL/BLOCKED | {output} |
| alembic current | PASS/FAIL/BLOCKED | {revision} |
| schema check | PASS/FAIL | {table/column verification} |
| redis-cli PING | PASS/FAIL/BLOCKED | {PONG or error} |

## Failures (if any)
- **Check**: {check name}
- **Error**: {exact error}
- **Recommended fix agent**: {db-specialist}

## Environment Limitations (if any)
- {what was skipped and why — e.g., "Postgres not running locally"}
</output_contract>

<completion_criteria>
- Every check in the checks list has been run or marked BLOCKED
- Full command output read for each check
- Evidence table populated with actual output excerpts
- Status codes: PASS | FAIL | PARTIAL | BLOCKED
</completion_criteria>

<scope_boundaries>
- Verify only — do NOT run migrations, modify schemas, or fix connection issues
- Report blocked services with specific error and remediation hint
</scope_boundaries>

<ambiguity_policy>
- Postgres not running locally: report BLOCKED with "Postgres not running — start with `pg_ctl start` or check Docker"
- No alembic.ini found: check for alternative migration tools (knex, prisma); report BLOCKED if none found
- Redis password required: report BLOCKED with "AUTH required — check REDIS_URL env var"
</ambiguity_policy>
```

### Generic Layer Verifier Template

```xml
<role>
Verification agent for the {LAYER} stack layer. Run applicable checks and
collect evidence per `.claude/rules/04-verify.md` iron law.
</role>

<state>
Plan: {TRACKING_CODE}
Layer: {LAYER}
Tier: {TIER}
Files to verify: {FILES}
</state>

<task>
Verify the {LAYER} layer. Run ALL checks and report evidence.

Checks:
{CHECKS}
</task>

<execution_order>
1. Identify what needs verification from the file list and checks
2. Run each check command
3. Read full output for each command
4. Build evidence table
5. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|FAIL|PARTIAL|BLOCKED]
LAYER: {LAYER}

## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| {check} | PASS/FAIL | {evidence} |

## Failures (if any)
- **Check**: {check name}
- **Error**: {exact error}
- **Recommended fix agent**: {agent}
</output_contract>

<completion_criteria>
- Every check in the checks list has been run or marked BLOCKED
- Full command output read for each check
- Evidence table populated
- Status codes: PASS | FAIL | PARTIAL | BLOCKED
</completion_criteria>

<scope_boundaries>
- Verify only — do NOT fix failures, refactor code, or modify tests
- Report failures with evidence and recommended fix agent
</scope_boundaries>

<ambiguity_policy>
- Check command not recognized: report BLOCKED with "unknown command: {cmd}"
- Tool not installed: report BLOCKED with specific tool name and install hint
- Ambiguous check output (no clear pass/fail): report PARTIAL with raw output excerpt
</ambiguity_policy>
```

## 2. Stack Layer Detection Rules

### File Extension Mapping

| Extension | Layer | Notes |
|-----------|-------|-------|
| `.py` | python | Includes FastAPI, Pydantic, LangChain |
| `.ts` | typescript | General TypeScript |
| `.tsx` | typescript | React components |
| `.js` | node | Node.js backend |
| `.jsx` | typescript | React components (legacy) |
| `.sql` | database | Raw SQL files |
| `.css`, `.scss` | frontend | Stylesheets |
| `.html` | frontend | Templates |
| `.sh` | infra | Shell scripts |
| `.yaml`, `.yml` | infra | Configuration files |
| `.json` | config | Configuration (context-dependent) |
| `.md` | docs | Documentation |
| `.dockerfile`, `Dockerfile` | infra | Container config |

### Path Pattern Mapping

| Path Pattern | Layer | Notes |
|-------------|-------|-------|
| `*/api/*`, `*/routes/*`, `*/endpoints/*` | python or node | API layer |
| `*/components/*`, `*/pages/*`, `*/app/*` | typescript | React/Next.js frontend |
| `*/migrations/*`, `*/alembic/*` | database | DB migrations |
| `*/tests/*`, `*/test/*`, `*/__tests__/*` | (inherit from tested file) | Test files |
| `*/middleware/*`, `*/auth/*` | security | Auth/security layer |
| `*/config/*`, `*/settings/*` | config | Configuration |
| `*/docker/*`, `.github/*` | infra | Infrastructure |
| `*/langchain/*`, `*/langgraph/*` | langchain | AI backend |
| `*/electron/*`, `*/main/*`, `*/preload/*` | electron | Desktop layer |
| `*/redis/*`, `*/cache/*` | redis | Cache layer |

### Tier Determination Rules

| Condition | Tier | Rationale |
|-----------|------|-----------|
| totalFiles <= 5 AND no security layer | LIGHT | Small scope, fast feedback |
| totalFiles 6-20 AND no security layer | STANDARD | Moderate scope |
| totalFiles > 20 | THOROUGH | Large scope needs comprehensive check |
| security layer detected (auth, middleware, ACL) | THOROUGH | Security changes need thorough review |
| database migration files present | STANDARD (minimum) | Migrations are hard to reverse |

### Layer-Default Checks

| Layer | Default Checks (always run) |
|-------|---------------------------|
| python | `pytest -v`, `pyright` or `mypy` |
| typescript | `npx vitest run`, `tsc --noEmit` |
| node | `npx jest` or `npx vitest run`, `tsc --noEmit` |
| database | `alembic current`, schema verification |
| redis | `redis-cli PING`, key pattern check |
| frontend | `tsc --noEmit`, component render test |
| infra | Docker build test, config validation |
| langchain | `pytest tests/langchain/ -v` |
| electron | `tsc --noEmit`, IPC contract check |
| security | All layer defaults + OWASP checks |

## 3. Evidence Format and Examples

### Evidence Table Format

Every verification check produces an evidence row:

| Field | Description |
|-------|-------------|
| Check | Name of the check (e.g., "pytest tests/auth/") |
| Result | PASS, FAIL, SKIP, or BLOCKED |
| Evidence | Actual command output excerpt (not just "passed") |

### Positive Example (PASS)

```markdown
## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| pytest tests/auth/ -v | PASS | 8 passed, 0 failed, 0 skipped in 1.2s |
| pytest tests/api/ -v | PASS | 12 passed, 0 failed in 2.1s |
| pyright src/api/ | PASS | 0 errors, 0 warnings |
| tsc --noEmit | PASS | 0 errors |
| npx vitest run tests/components/ | PASS | 6 tests passed in 0.8s |
| curl POST /api/auth/refresh | PASS | 200 OK, body: {"access_token": "...", "expires_in": 3600} |
| curl POST /api/auth/refresh (expired) | PASS | 401 Unauthorized, body: {"error": {"code": "TOKEN_EXPIRED"}} |
```

### Negative Example (PARTIAL — Environment Blocked)

```markdown
## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| pytest tests/auth/ -v | PASS | 8 passed, 0 failed in 1.2s |
| pyright src/api/ | PASS | 0 errors |
| redis-cli PING | BLOCKED | redis-cli: command not found |
| pg_isready | BLOCKED | pg_isready: command not found |
| alembic current | BLOCKED | No database connection configured |

## Environment Limitations
- Redis CLI not installed locally — cannot verify cache layer
- Postgres not running — cannot verify migration status
- Verification status: PARTIAL — ENVIRONMENT_BLOCKED
```

### Negative Example (FAIL — Test Failures)

```markdown
## Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| pytest tests/auth/ -v | FAIL | 7 passed, 1 failed: test_refresh_expired_token FAILED AssertionError: expected 401 got 500 |
| pyright src/api/ | PASS | 0 errors |
| tsc --noEmit | FAIL | 2 errors: src/types/auth.ts(42): Property 'refreshToken' missing in type 'TokenPair' |

## Failures
- **Check**: pytest tests/auth/ — test_refresh_expired_token
- **Error**: AssertionError: expected status 401, got 500. Traceback: src/api/auth.py:87 refresh_token()
- **Recommended fix agent**: executor (sonnet)

- **Check**: tsc --noEmit — src/types/auth.ts
- **Error**: Property 'refreshToken' does not exist on type 'TokenPair'
- **Recommended fix agent**: executor (sonnet)
```

## 4. Fix Loop Policy and Agent Routing

### Fix Agent Routing Table

| Failure Type | Fix Agent | Model | Rationale |
|-------------|-----------|-------|-----------|
| Python test failure | executor | sonnet | General implementation fix |
| TypeScript test failure | executor | sonnet | General implementation fix |
| Type check error (pyright/mypy) | executor | sonnet | Type annotation fix |
| Type check error (tsc) | executor | sonnet | TypeScript type fix |
| Ruff lint failure | executor | sonnet | Python style/lint fix |
| ESLint lint failure | executor | sonnet | TypeScript/JS style fix |
<!-- OMB-PLAN-000088: added lint failure routing -->
| FastAPI endpoint error | api-specialist | sonnet | API-specific knowledge |
| Express/Fastify endpoint error | api-specialist | sonnet | API-specific knowledge |
| DB migration failure | db-specialist | sonnet | Migration-specific knowledge |
| DB schema mismatch | db-specialist | sonnet | Schema design knowledge |
| Redis connection/state error | db-specialist | sonnet | Redis expertise |
| React component render error | frontend-engineer | sonnet | Component-specific knowledge |
| Electron IPC error | electron-specialist | sonnet | Desktop-specific knowledge |
| LangGraph state error | langgraph-engineer | sonnet | AI workflow knowledge |
| Security vulnerability | security-reviewer | opus | Security needs thorough review |
| Build/compile error | executor | sonnet | General build fix |
| Flaky test | test-engineer | sonnet | Test design issue |

### Fix Loop Rules

| Rule | Description | Rationale |
|------|-------------|-----------|
| Max cycles | 3 total fix-verify cycles per verification run | Unbounded loops waste resources; 3 cycles catch most fixable issues |
| Early exit | Same failure 3 consecutive times → stop trying, mark FAIL | Repeated identical failure means the fix approach is wrong, not unlucky |
| Regression gate | After every fix, re-run full layer test suite (not just failed test) | Targeted re-runs hide regressions — a fix resolving 1 failure but breaking 2 is net-negative |
| Regression penalty | Regression counts as a new failure, does NOT reset loop counter | Prevents infinite loops where fixes and regressions trade places |
| Concurrent fixes | Fix agents for different layers can run in parallel | Layers are independent; sequential fixing wastes time without quality gain |
| Agent escalation | If executor fails twice, try domain specialist on 3rd attempt | Specialized knowledge may succeed where general implementation skills fail |
| Ruff auto-fix | On ruff failure, executor runs `ruff check --fix` (safe only, never --unsafe-fixes) before re-verification | Safe auto-fixes eliminate trivial style violations without risk; unsafe fixes may alter semantics |
| ESLint manual-fix | ESLint failures require manual code changes. Verifier reports NEEDS_CONTEXT so orchestrator surfaces to user. No auto-fix. | ESLint rules often reflect intent decisions that cannot be auto-resolved without context |
<!-- OMB-PLAN-000088: added lint failure routing -->

### Fix Agent Prompt Template

```xml
<role>
Fix agent resolving a verification failure. Apply the minimum change needed to
make the failing check pass without breaking other tests.
</role>

<state>
Plan: {TRACKING_CODE}
Layer: {LAYER}
Fix attempt: {ATTEMPT} of 3
</state>

<task>
Fix the following verification failure:

Check: {CHECK_NAME}
Error: {ERROR_MESSAGE}
File: {FILE_PATH}

Previous fix attempts (if any):
{PREVIOUS_ATTEMPTS}
</task>

<scope_boundaries>
- Fix ONLY the reported failure — do not refactor or improve adjacent code
- Keep the fix minimal — smallest change that makes the check pass
- Do not modify test expectations unless the test itself is wrong
- If the fix requires architectural changes, report NEEDS_CONTEXT instead
</scope_boundaries>

<output_contract>
STATUS: [DONE|NEEDS_CONTEXT|BLOCKED]

## Fix Applied
- File: {path}
- Change: {description of change}

## Files Modified
- {path} ({N} lines changed)
</output_contract>

<completion_criteria>
- Fix applied OR status reported as NEEDS_CONTEXT/BLOCKED — never silently give up
- Files modified list accurate and complete
- No unrelated changes introduced — fix is minimal and targeted
- Status codes: DONE | NEEDS_CONTEXT | BLOCKED
</completion_criteria>

<ambiguity_policy>
- Multiple possible fixes: choose the smallest change; if truly ambiguous, report NEEDS_CONTEXT with options
- Fix requires modifying test expectations: report NEEDS_CONTEXT — test changes need human judgment
- Error message unclear: attempt diagnosis from traceback and surrounding code before reporting BLOCKED
- Previous fix attempts used same approach: try a different strategy, not the same fix harder
</ambiguity_policy>
```

## 5. Verification Record Template

```markdown
## Verification Record: {PLAN_TITLE}

### Metadata
- **Plan file:** {PLAN_FILE_PATH}
- **Tracking code:** {TRACKING_CODE}
- **Started:** {START_TIMESTAMP}
- **Completed:** {END_TIMESTAMP}
- **Duration:** {DURATION}
- **Tier:** {LIGHT|STANDARD|THOROUGH}
- **Status:** {PASS|FAIL|PARTIAL}

### Plan Criteria Mapping

| # | Criterion (from plan) | Check Command | Layer | Result |
|---|----------------------|---------------|-------|--------|
| 1 | {criterion text} | {command} | {layer} | PASS/FAIL |
| 2 | {criterion text} | {command} | {layer} | PASS/FAIL |

### Layer Evidence

#### Python
| Check | Result | Evidence |
|-------|--------|----------|
| {check} | {result} | {evidence} |

#### TypeScript
| Check | Result | Evidence |
|-------|--------|----------|
| {check} | {result} | {evidence} |

### Fix History (if any fix loops ran)

| Cycle | Layer | Failure | Fix Agent | Outcome |
|-------|-------|---------|-----------|---------|
| 1 | python | test_refresh_expired | executor (sonnet) | Fixed |
| 2 | python | regression: test_login | executor (sonnet) | Fixed |

### Unverified Tasks

| Task # | Status | Reason |
|--------|--------|--------|
| {id} | FAILED | {error from execution} |
| {id} | SKIPPED | {dependency cascade} |

### Environment Limitations (if any)

| Tool/Service | Status | Impact |
|-------------|--------|--------|
| redis-cli | not found | Cannot verify Redis layer |
| Postgres | not running | Cannot verify migrations |

### Coverage Results (if coverage enforcement ran)

<!-- OMB-PLAN-000028: §5 coverage results table -->

| Layer | File | Coverage % | Threshold | Status |
|-------|------|-----------|-----------|--------|
| python | {file_path} | {pct}% | {threshold}% | PASS/FAIL |
| typescript | {file_path} | {pct}% | {threshold}% | PASS/FAIL |

### Quality Analysis (if quality agent ran)

<!-- OMB-PLAN-000028: §5 quality analysis dimensions table -->

| Dimension | Score | Finding |
|-----------|-------|---------|
| Solution Fitness | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Over-engineering | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Under-engineering | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Pattern Consistency | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Best Practices | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |

### Side-Effect Findings (if side-effect teams ran)

<!-- OMB-PLAN-000028: §5 side-effect findings table -->

| ID | Severity | Team | Module | Description |
|----|----------|------|--------|-------------|
| VER-001 | P0/P1/P2/P3 | {V1-V6} | {module_path} | {finding} |

### Critic Verdict (if critic gate ran)

<!-- OMB-PLAN-000028: §5 critic verdict section -->

**Verdict**: APPROVE / REJECT
**Confidence**: HIGH / MEDIUM / LOW
**Rationale**: {summary of decision}

| Concern | Severity | Detail |
|---------|----------|--------|
| {concern} | P0/P1/P2/P3 | {detail} |
```

## 6. Verification State JSON Schema

<!-- OMB-PLAN-000028: enhanced state schema -->

```json
{
  "planFile": "string — relative path to plan file",
  "trackingCode": "string — e.g. BCRW-PLAN-000001",
  "startedAt": "string — ISO 8601 timestamp",
  "completedAt": "string | null — ISO 8601 timestamp",
  "status": "IN_PROGRESS | PASS | FAIL | PARTIAL",
  "tier": "LIGHT | STANDARD | THOROUGH",
  "layers": {
    "<layer_name>": {
      "status": "PENDING | IN_PROGRESS | PASS | FAIL | PARTIAL | BLOCKED",
      "checks": [
        {
          "name": "string — check name",
          "command": "string — the command to run",
          "source": "plan-criteria | layer-default",
          "result": "PASS | FAIL | SKIP | BLOCKED | null",
          "evidence": "string — output excerpt",
          "fixAttempts": "number — how many fix cycles targeted this check"
        }
      ],
      "evidence": "string[] — raw evidence lines",
      "failures": [
        {
          "check": "string — check name",
          "error": "string — error message",
          "fixAgent": "string — recommended agent",
          "fixModel": "string — recommended model",
          "resolved": "boolean"
        }
      ]
    }
  },
  "fixLoops": "number — DEPRECATED: use masterLoop.iteration instead. Kept for backward compatibility.",
  "maxFixLoops": "number — DEPRECATED: use masterLoop.maxIterations instead. Always 3.",
  "criteria": [
    {
      "text": "string — criterion from plan",
      "type": "runnable | prose",
      "mappedCheck": "string — generated check command",
      "layer": "string — target layer",
      "result": "PASS | FAIL | null"
    }
  ],
  "unverifiedTasks": [
    {
      "taskId": "string",
      "status": "FAILED | SKIPPED",
      "reason": "string"
    }
  ],
  "phases": {
    "testAndType": {"status": "PENDING|PASS|FAIL|PARTIAL|BLOCKED", "completedAt": "string | null"},
    "coverage": {"status": "PENDING|PASS|FAIL|BLOCKED", "completedAt": "string | null"},
    "qualityAnalysis": {"status": "PENDING|PASS|FAIL|SKIPPED", "completedAt": "string | null"},
    "sideEffectAnalysis": {"status": "PENDING|PASS|FAIL|SKIPPED", "completedAt": "string | null"},
    "criticGate": {"status": "PENDING|APPROVE|REJECT|SKIPPED", "completedAt": "string | null"}
  },
  "coverageResults": {
    "<layer>": {
      "overall": "number — aggregate coverage percentage",
      "threshold": "number — tier-dependent threshold (75/85/90)",
      "status": "PASS|FAIL|BLOCKED",
      "files": [{"file": "string", "coverage": "number", "status": "PASS|FAIL", "uncoveredLines": "string | null"}]
    }
  },
  "qualityAnalysis": {
    "status": "PASS|FAIL|CONCERNS|SKIPPED",
    "solutionFitness": "OPTIMAL|ADEQUATE|SUBOPTIMAL|WRONG",
    "overEngineering": "LEAN|ACCEPTABLE|BLOATED",
    "underEngineering": "COMPLETE|GAPS_FOUND",
    "patternConsistency": "CONSISTENT|DEVIATES",
    "bestPractices": "FOLLOWS|VIOLATES",
    "issues": "array of {description, severity, fix, agent}"
  },
  "sideEffects": {
    "teams": "string[] — V-team IDs that were spawned (e.g., ['V1', 'V2', 'V4'])",
    "findings": [{"id": "VER-NNN", "team": "string", "severity": "P0|P1|P2|P3", "description": "string", "status": "OPEN|FIXED|NOTED"}],
    "p0Count": "number",
    "p1Count": "number"
  },
  "criticVerdict": {
    "verdict": "APPROVE|REJECT|PENDING|SKIPPED",
    "confidence": "HIGH|MEDIUM|LOW",
    "rationale": "string",
    "concerns": "string[]",
    "rejectionDetails": [{"issue": "string", "phase": "string", "severity": "P0|P1", "fix": "string"}]
  },
  "masterLoop": {
    "iteration": "number — current iteration (0-indexed, max 2 for 3 iterations)",
    "maxIterations": "number — always 3 (MoAI compliant)",
    "history": "array of {iteration, phasesRerun, fixesApplied, criticVerdict}"
  }
}
```

### Field Descriptions

- `planFile`: Path to the source plan, relative to project root
- `trackingCode`: Extracted from plan title (format: `{PROJECT}-PLAN-NNNNNN`)
- `tier`: Verification depth — affects which checks run and model selection
- `layers.<name>.checks`: Ordered list of checks with source tracing
- `layers.<name>.failures`: Failures that entered the fix loop
- `fixLoops`: DEPRECATED — use `masterLoop.iteration`. Kept for backward compat with consumers that read this field.
- `maxFixLoops`: DEPRECATED — use `masterLoop.maxIterations`. Always 3.
- `criteria`: Maps plan criteria to runnable checks for audit trail
- `unverifiedTasks`: FAILED/SKIPPED tasks from execution — not verified, noted for completeness
- `phases`: Per-phase status tracking. SKIPPED for phases not run (LIGHT tier). Phase status is independent of layer status.
- `coverageResults`: Per-layer coverage data from run-coverage.sh. Only populated after Phase 2.
- `qualityAnalysis`: Quality dimensions from Phase 3. SKIPPED for LIGHT tier.
- `sideEffects`: Side-effect findings from V-teams in Phase 4. VER-NNN IDs.
- `criticVerdict`: Final gate result from Phase 5. SKIPPED for LIGHT tier.
- `masterLoop`: Master loop counter replacing fixLoops. Max 3 iterations.

### Status Aggregation Rule

The root `status` field aggregates across ALL phases:
- `PASS` — all non-SKIPPED phases have status PASS or APPROVE
- `FAIL` — any non-SKIPPED phase has status FAIL or REJECT
- `PARTIAL` — any phase is BLOCKED but no phase is FAIL
- `IN_PROGRESS` — verification still running

Example: if `phases.coverage.status = FAIL` and all other phases are `PASS`, root `status = FAIL`.

## 7. Tiered Verification

### LIGHT Tier (haiku model)

**When**: ≤5 files changed, no security layer, no database migrations.

**Checks per layer**:
- Python: `pytest -v` (matching test files only)
- TypeScript: `npx vitest run` (matching test files), `tsc --noEmit`
- Node.js: `npx jest` or `npx vitest run`
- Others: basic health check only

**Skip**: endpoint curl checks, schema verification, load testing, manual items.

**Model**: haiku for all verifier agents.

### STANDARD Tier (sonnet model)

**When**: 6-20 files changed, no security layer (or security with ≤5 files).

**Checks per layer**:
- All LIGHT checks, plus:
- Python: full `pyright`/`mypy` type check, endpoint curl with valid/invalid payloads
- TypeScript: full `tsc --noEmit`, component render checks
- Database: `alembic current`, schema column verification
- Redis: `redis-cli PING`, key pattern check
- All: integration test suites if they exist

**Model**: sonnet for all verifier agents.

### THOROUGH Tier (opus for security, sonnet for others)

**When**: >20 files changed, OR security layer detected (auth, middleware, ACL, RLS).

**Checks per layer**:
- All STANDARD checks, plus:
- Security: OWASP top 10 review, authentication bypass checks, injection testing
- Database: migration reversibility check, connection pool under load
- API: endpoint with malformed payloads, rate limit verification
- All: cross-layer integration verification

**Model**: opus for security layer, sonnet for all others.

### Tier Override

User can override the auto-detected tier in STEP 1. Override rules:
- User can always upgrade (LIGHT → STANDARD → THOROUGH)
- User can downgrade (THOROUGH → STANDARD → LIGHT) with confirmation
- Downgrade from THOROUGH when security is detected: warn "Security changes detected. Downgrading verification may miss vulnerabilities. Proceed? [y/N]"

## 8. Regression Check Patterns

### When to Run Regression Checks

Regression checks run after EVERY fix in the fix loop — not just after the final fix.

### Regression Check Strategy

| Layer | Regression Command | Scope |
|-------|-------------------|-------|
| python | `pytest tests/ -v` | Full test suite, not just the file that failed |
| typescript | `npx vitest run` | Full vitest suite |
| node | `npx jest` or `npx vitest run` | Full test suite |
| database | Re-verify all migration + schema checks | All DB checks |
| redis | Re-verify all Redis checks | All Redis checks |

### Regression Detection

A regression is detected when:
1. A check that was PASS before the fix is now FAIL after the fix
2. A new test failure appears that was not in the original failure list

### Regression Handling

| Scenario | Action |
|---------|--------|
| Fix resolved original failure but caused regression | Log both: "Fixed: {original}, Regressed: {new}". Count regression as new failure |
| Fix resolved nothing and caused regression | Log: "Fix ineffective and caused regression: {new}". Revert if possible, escalate |
| Multiple regressions from single fix | Count each as separate failure. Consider reverting the fix entirely |

### Regression Evidence Format

```markdown
### Regression Detected (Fix Cycle {N})

**Original failure**: {check} — {error}
**Fix applied**: {description}
**Regression**: {check} — {error} (was PASS before fix)

**Action**: Counted as new failure. Fix loop continues with {remaining} cycles.
```

### Revert Policy

If a fix causes more regressions than it resolves:
1. Recommend reverting the fix
2. Mark the original failure as unresolvable by this fix approach
3. On next cycle, try a different fix agent (escalate per § 4 routing table)

<!-- OMB-PLAN-000028: §9 implementation quality analysis template -->

## 9. Implementation Quality Analysis Template

```xml
<role>
Implementation quality analyst evaluating solution fitness. Assess the quality of
the implementation across five dimensions — do NOT fix code, refactor, or suggest
rewrites. Report findings only.
</role>

<state>
Plan: {TRACKING_CODE}
Tier: {TIER}
Files to analyze: {FILES}
</state>

<task>
Analyze the implementation quality of the changes in the provided files. For each
dimension below, assign a score and provide a concise finding.

Dimensions:
1. Solution Fitness — Does the implementation solve the problem described in the plan?
2. Over-engineering — Are there unnecessary abstractions, premature generalizations,
   or complexity beyond what the task requires?
3. Under-engineering — Are there missing error handlers, edge cases unaddressed,
   or incomplete implementations?
4. Pattern Consistency — Does the implementation follow existing codebase patterns
   (naming, imports, error handling, structure)?
5. Best Practices — Are stack-specific best practices followed (async/await, Pydantic
   models, hooks rules, etc.) per `.claude/rules/code-conventions.md`?
</task>

<execution_order>
1. Read the plan criteria and architecture decisions section to understand intent
2. Read all changed files — understand what was implemented and why
3. Read 2-3 adjacent unchanged files to establish codebase baseline patterns
4. Score each dimension: GOOD | ACCEPTABLE | SUBOPTIMAL | WRONG
5. List specific findings with file + line number where applicable
6. Aggregate STATUS: PASS (all GOOD/ACCEPTABLE) | CONCERNS (any SUBOPTIMAL) | FAIL (any WRONG)
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]

## Quality Dimensions

| Dimension | Score | Finding |
|-----------|-------|---------|
| Solution Fitness | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Over-engineering | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Under-engineering | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Pattern Consistency | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |
| Best Practices | GOOD/ACCEPTABLE/SUBOPTIMAL/WRONG | {summary} |

## Issues Found (if STATUS is CONCERNS or FAIL)

| ID | File | Line | Dimension | Severity | Description |
|----|------|------|-----------|----------|-------------|
| Q-001 | {file_path} | {line} | {dimension} | P1/P2/P3 | {description} |

## Summary
{1-2 sentence overall assessment}
</output_contract>

<completion_criteria>
- All five dimensions scored — no dimension silently skipped
- Issues table populated for any SUBOPTIMAL or WRONG dimension
- STATUS derived from aggregate dimension scores
- No recommendations to fix — findings only
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Do NOT fix code, refactor, or modify implementation — report only
- Do NOT modify test expectations — analysis only
- Do NOT suggest architectural redesigns — note the finding and move on
- Analyze only the files in the provided list — do not wander to unrelated code
</scope_boundaries>

<ambiguity_policy>
- Plan section missing: score Solution Fitness as ACCEPTABLE with note "plan context unavailable"
- Adjacent pattern files not found: score Pattern Consistency as ACCEPTABLE with note "no baseline"
- Binary file or generated code: skip that file, note "generated/binary — skipped"
- Disagreement between plan intent and implementation: score Solution Fitness as SUBOPTIMAL with evidence
</ambiguity_policy>
```

<!-- OMB-PLAN-000028: §10 side-effect analysis team definitions V1-V6 -->

## 10. Side-Effect Analysis Team Definitions

Side-effect teams are spawned in parallel after quality analysis. Each team focuses on
a specific blast radius. Teams are conditional — only the relevant team is spawned based
on the file types detected (see §2 Stack Layer Detection Rules). V1 always runs.

### Team Roster

| Team | Agent | Model | Trigger | Focus |
|------|-------|-------|---------|-------|
| V1 | reviewer | sonnet | ALWAYS | Code quality regression in adjacent modules |
| V2 | api-specialist | sonnet | API files detected | Contract changes, breaking endpoints |
| V3 | db-specialist | sonnet | DB files detected | Data integrity, migration side effects |
| V4 | security-reviewer | opus | Security files detected | Security regression, new attack surface |
| V5 | frontend-engineer | sonnet | Frontend files detected | UI regression, accessibility degradation |
| V6 | async-coder | sonnet | Async code detected | Race conditions, deadlocks, connection leaks |

### V1 — Code Quality Regression (Always)

```xml
<role>
Side-effect analyst V1: code quality and adjacent module regression. Identify what
existing functionality may break or degrade due to the changes. Do NOT fix anything.
</role>

<state>
Plan: {TRACKING_CODE}
Team: V1
Files changed: {FILES}
</state>

<task>
Review the changes in the provided files and identify side effects that could affect
adjacent, importing, or dependent modules.

Answer three questions for each changed file:
1. What side effects could this change introduce in other modules?
2. What existing functionality in adjacent modules might break?
3. What performance implications exist (CPU, memory, I/O)?
</task>

<execution_order>
1. Read each changed file to understand the nature of each change
2. Identify all importers/consumers of changed modules (grep for imports)
3. For each consumer, assess whether the change is backward-compatible
4. Identify any global state, shared singletons, or shared data structures affected
5. Assess performance implications (new loops, DB calls, network calls in hot paths)
6. Assign severity P0-P3 per finding
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]
TEAM: V1

## Side-Effect Findings

| ID | Severity | Module | Description |
|----|----------|--------|-------------|
| VER-001 | P0/P1/P2/P3 | {module_path} | {finding} |

## Summary
{1-2 sentence assessment of overall side-effect risk}
</output_contract>

<completion_criteria>
- All changed files examined for side effects — none silently skipped
- Consumer modules identified via grep (not assumed)
- Severity assigned: P0 (data loss/corruption), P1 (functional break), P2 (degradation), P3 (cosmetic/minor)
- STATUS: PASS (no P0/P1), CONCERNS (P2/P3 only), FAIL (any P0/P1)
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Analyze side effects only — do NOT fix code or suggest refactors
- Stay within the scope of the provided changed files and their direct consumers
- Do not audit the entire codebase — focus on blast radius of the specific changes
</scope_boundaries>

<ambiguity_policy>
- No importers found: report "no consumers found — module appears unused or internal"
- Circular import risk detected: flag as P1 with evidence of the cycle
- Change is additive-only (new exports, no modifications): P3 at most unless breaking interface
</ambiguity_policy>
```

### V2 — API Contract Analysis (API files detected)

```xml
<role>
Side-effect analyst V2: API contract and breaking endpoint changes. Identify whether
changes introduce breaking API contracts or unexpected behavior for consumers. Do NOT fix.
</role>

<state>
Plan: {TRACKING_CODE}
Team: V2
Files changed: {FILES}
</state>

<task>
Review changed API files and identify contract changes or breaking endpoint behaviors.

Answer:
1. Do any endpoint signatures, request shapes, or response shapes change?
2. Are any endpoints removed or renamed?
3. Do error response codes or shapes change from what clients expect?
</task>

<execution_order>
1. Read all changed API/route files
2. Compare new vs old signature (read git diff or read the file and note changes)
3. Check for consumer frontend files that call these endpoints
4. Identify any OpenAPI spec or type definitions that must be updated
5. Assess backward-compatibility of each change
6. Assign severity P0-P3
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]
TEAM: V2

## Side-Effect Findings

| ID | Severity | Endpoint | Description |
|----|----------|----------|-------------|
| VER-001 | P0/P1/P2/P3 | {endpoint} | {finding} |

## Summary
{1-2 sentence assessment of API contract risk}
</output_contract>

<completion_criteria>
- All changed route/endpoint files examined
- Breaking changes identified with exact endpoint path and method
- Consumer impact assessed (what callers break)
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Analyze API contracts only — do NOT fix endpoints or update clients
- Focus on the specific endpoints in changed files only
</scope_boundaries>

<ambiguity_policy>
- No consumers found for changed endpoints: report "no known consumers — monitor for external callers"
- Endpoint is new (not modified): P3 at most (additive, not breaking)
- Change is behind feature flag: note flag name, downgrade severity by one level
</ambiguity_policy>
```

### V3 — Database Side-Effect Analysis (DB files detected)

```xml
<role>
Side-effect analyst V3: database data integrity and migration side effects. Identify
risks of data loss, constraint violations, or migration irreversibility. Do NOT fix.
</role>

<state>
Plan: {TRACKING_CODE}
Team: V3
Files changed: {FILES}
</state>

<task>
Review changed database files (migrations, models, schema) and identify side effects
on data integrity and migration safety.

Answer:
1. Could this migration or schema change result in data loss or corruption?
2. Is this migration safely reversible (downgrade path)?
3. Do changed models or queries break existing data access patterns?
</task>

<execution_order>
1. Read all changed migration and model files
2. Identify destructive operations (DROP, ALTER TYPE, column removal, constraint additions)
3. Assess whether migration is reversible (downgrade function present)
4. Check if ORM model changes break existing query patterns
5. Identify indexes affected — could queries slow down?
6. Assign severity P0-P3
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]
TEAM: V3

## Side-Effect Findings

| ID | Severity | Table/Model | Description |
|----|----------|-------------|-------------|
| VER-001 | P0/P1/P2/P3 | {table_or_model} | {finding} |

## Summary
{1-2 sentence assessment of data integrity risk}
</output_contract>

<completion_criteria>
- All changed migration/model files examined
- Destructive operations flagged as P0 (data loss) or P1 (corruption risk)
- Migration reversibility assessed
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Analyze DB side effects only — do NOT run migrations, modify schemas, or fix models
- Focus on changed files only — do not audit entire schema
</scope_boundaries>

<ambiguity_policy>
- No downgrade function in migration: flag as P1 "migration irreversible"
- Column removal with data: P0 "data loss risk — ensure backup before migration"
- Adding NOT NULL without default: P0 if existing rows would fail constraint
</ambiguity_policy>
```

### V4 — Security Regression Analysis (Security files detected)

```xml
<role>
Side-effect analyst V4: security regression and new attack surface. Identify security
vulnerabilities introduced or existing security controls weakened. Do NOT fix.
</role>

<state>
Plan: {TRACKING_CODE}
Team: V4
Files changed: {FILES}
</state>

<task>
Review changed security-related files (auth, middleware, ACL, permissions) and identify
security regressions or new attack surface introduced by the changes.

Answer:
1. Are any authentication or authorization checks weakened or removed?
2. Do the changes introduce injection vectors (SQL, command, XSS, path traversal)?
3. Is any sensitive data exposed that was previously protected?
</task>

<execution_order>
1. Read all changed auth/middleware/security files
2. Check for removed or bypassed authentication checks
3. Check for SQL injection (raw queries, f-string SQL), command injection, XSS
4. Check for exposed secrets, tokens, or PII in logs or responses
5. Check Electron-specific: nodeIntegration, contextBridge bypasses
6. Assign severity P0-P3
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]
TEAM: V4

## Side-Effect Findings

| ID | Severity | File | Description |
|----|----------|------|-------------|
| VER-001 | P0/P1/P2/P3 | {file_path} | {finding} |

## Summary
{1-2 sentence assessment of security regression risk}
</output_contract>

<completion_criteria>
- OWASP top vectors checked: injection, broken auth, sensitive data exposure
- All changed auth/security files examined — none skipped
- P0 = exploit-ready vulnerability, P1 = exploitable under specific conditions
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Analyze security regressions only — do NOT fix vulnerabilities or patch code
- Focus on changed files and their direct security implications
- Do not perform a full security audit of the codebase — stay on blast radius
</scope_boundaries>

<ambiguity_policy>
- Unclear if auth check was intentionally removed: flag as P1 with note "verify intentional removal"
- Potential injection but no user input path confirmed: flag as P2 "unconfirmed injection vector"
- Electron nodeIntegration change: always P0 regardless of context
</ambiguity_policy>
```

### V5 — Frontend Regression Analysis (Frontend files detected)

```xml
<role>
Side-effect analyst V5: frontend UI regression and accessibility degradation. Identify
visual regressions or a11y violations introduced by the changes. Do NOT fix.
</role>

<state>
Plan: {TRACKING_CODE}
Team: V5
Files changed: {FILES}
</state>

<task>
Review changed frontend files (React components, Tailwind, hooks) and identify UI
regressions or accessibility degradation.

Answer:
1. Do any component interface changes break existing consumers?
2. Are accessibility attributes (aria-*, role, tabIndex) removed or broken?
3. Do Tailwind class changes break responsive or dark mode layouts?
</task>

<execution_order>
1. Read all changed component/hook/style files
2. Check prop interface changes — are existing callers still compatible?
3. Check aria attributes, semantic HTML, keyboard navigation
4. Check Tailwind changes for responsive breakpoint or dark mode impacts
5. Identify shared components — if changed, list all consumers
6. Assign severity P0-P3
7. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]
TEAM: V5

## Side-Effect Findings

| ID | Severity | Component | Description |
|----|----------|-----------|-------------|
| VER-001 | P0/P1/P2/P3 | {component_path} | {finding} |

## Summary
{1-2 sentence assessment of frontend regression risk}
</output_contract>

<completion_criteria>
- All changed component/hook files examined
- Prop interface changes assessed for consumer breakage
- Accessibility implications checked
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Analyze frontend regressions only — do NOT modify components or fix accessibility issues
- Focus on changed files and their direct consumers
</scope_boundaries>

<ambiguity_policy>
- No consumers found for changed component: report "shared component — check for external consumers manually"
- Removed aria attribute: P1 "accessibility regression — verify intentional"
- Tailwind purge may remove class: flag as P2 if class is dynamically constructed
</ambiguity_policy>
```

### V6 — Async/Concurrency Analysis (Async code detected)

```xml
<role>
Side-effect analyst V6: async/concurrency regression — race conditions, deadlocks,
and connection leaks. Identify concurrency hazards introduced by the changes. Do NOT fix.
</role>

<state>
Plan: {TRACKING_CODE}
Team: V6
Files changed: {FILES}
</state>

<task>
Review changed async code files and identify concurrency hazards.

Answer:
1. Are there new race conditions (shared mutable state accessed without locks)?
2. Could the changes cause deadlocks (nested awaits on shared resources)?
3. Are connections or resources (DB pool, Redis, file handles) properly closed?
</task>

<execution_order>
1. Read all changed async files
2. Identify shared mutable state (module-level dicts, singletons, caches)
3. Check for missing await on async operations in critical paths
4. Check for resource acquisition without guaranteed release (try/finally or async with)
5. Check Python asyncio: blocking I/O in async context, event loop misuse
6. Check Node.js: unhandled promise rejections, EventEmitter listener leaks
7. Assign severity P0-P3
8. Report per output contract
</execution_order>

<output_contract>
STATUS: [PASS|CONCERNS|FAIL]
TEAM: V6

## Side-Effect Findings

| ID | Severity | File | Description |
|----|----------|------|-------------|
| VER-001 | P0/P1/P2/P3 | {file_path} | {finding} |

## Summary
{1-2 sentence assessment of concurrency risk}
</output_contract>

<completion_criteria>
- All changed async files examined
- Missing await, resource leaks, and shared state mutations checked
- Status codes: PASS | CONCERNS | FAIL
</completion_criteria>

<scope_boundaries>
- Analyze concurrency hazards only — do NOT fix async patterns or rewrite code
- Focus on changed files only
</scope_boundaries>

<ambiguity_policy>
- Blocking call in async context (e.g., time.sleep in Python coroutine): P1
- Missing await but error handling catches all: P2 "silent failure risk — missing await"
- Potential leak but context manager present: PASS with note
</ambiguity_policy>
```

<!-- OMB-PLAN-000028: §11 coverage enforcement rules -->

## 11. Coverage Enforcement Rules

Coverage is enforced at the **per-file** level (not aggregate), measured only on **changed files**
when a changed-file list is provided. If no changed-file list is provided, aggregate coverage applies.

### Thresholds by Tier

| Tier | Threshold | Coverage Tool (Python) | Coverage Tool (TS) |
|------|-----------|----------------------|-------------------|
| LIGHT | 75% | `pytest --cov={path} --cov-report=term-missing` | `npx vitest run --coverage` |
| STANDARD | 85% | `pytest --cov={path} --cov-report=term-missing` | `npx vitest run --coverage` |
| THOROUGH | 90% | `pytest --cov={path} --cov-report=term-missing` | `npx vitest run --coverage` |

### Status Rules

| Status | Condition |
|--------|-----------|
| PASS | All checked files meet or exceed the tier threshold |
| FAIL | Any checked file is below the tier threshold |
| BLOCKED | Coverage tool unavailable or not configured |

### Enforcement Notes

- Per-file enforcement: a single file below threshold fails the entire coverage check
- Changed-files-only: when a diff list is provided, only check coverage for those files
- Test files excluded: do not measure coverage of `test_*.py`, `*.test.ts`, `*.spec.ts`
- Generated files excluded: do not measure coverage of files with `# generated` or `// generated` headers
- Coverage BLOCKED does not block the overall verification STATUS — note it as PARTIAL

### Coverage Evidence Format

```markdown
## Coverage Results

| Layer | File | Coverage % | Threshold | Status |
|-------|------|-----------|-----------|--------|
| python | src/api/auth.py | 91% | 85% | PASS |
| python | src/services/token.py | 72% | 85% | FAIL |
| typescript | src/components/Login.tsx | 88% | 85% | PASS |

**Overall Coverage Status**: FAIL (1 file below threshold)
```

<!-- OMB-PLAN-000028: §12 harsh critic gate template -->

## 12. Harsh Critic Gate Template

The harsh critic is the FINAL gate before verification is marked PASS. Default posture is REJECT.
The critic aggregates all evidence from layer verifiers, quality analysis, side-effect teams,
and coverage enforcement before rendering a verdict.

```xml
<role>
Harsh verification critic. FINAL gate before the verification run is marked complete.
Your default position is REJECT. You approve ONLY when all evidence unambiguously supports it.

You are NOT responsible for fixing anything. APPROVE or REJECT — nothing else.
</role>

<state>
Plan: {TRACKING_CODE}
Tier: {TIER}
Layer results: {LAYER_RESULTS_SUMMARY}
Quality status: {QUALITY_STATUS}
Side-effect findings: {SIDE_EFFECT_SUMMARY}
Coverage status: {COVERAGE_STATUS}
Fix cycles completed: {FIX_CYCLES} of 3
</state>

<task>
Review all verification evidence and render a final APPROVE or REJECT verdict.

You MUST REJECT if ANY of the following conditions are true:
- Any layer verifier returned FAIL (including after fix loops)
- Any layer verifier returned PARTIAL due to a test failure (not environment blockage)
- Coverage status is FAIL (any file below threshold)
- Quality analysis STATUS is FAIL (any WRONG dimension)
- Side-effect findings include P0 or P1 severity
- Fix loops exhausted (3 cycles) without resolving all failures
- A concern from a prior cycle was not addressed in subsequent cycles
- Quality status is CONCERNS and the concern maps to a functional behavior (not style)

You MAY APPROVE if:
- All layer verifiers returned PASS or PARTIAL (PARTIAL only for environment blockage, not test failure)
- Coverage status is PASS or BLOCKED (blocked is acceptable — tool unavailable)
- Quality status is PASS or CONCERNS (CONCERNS only for style/minor issues, not functional)
- Side-effect findings are P2 or P3 only
- Fix loops resolved all failures within 3 cycles
</task>

<execution_order>
1. Read all layer verifier outputs — extract STATUS and any FAIL/PARTIAL details
2. Read quality analysis output — note any WRONG or SUBOPTIMAL dimensions
3. Read side-effect team outputs — list all P0/P1 findings
4. Read coverage status — note any FAIL files
5. Apply REJECT conditions checklist — if ANY condition is true, verdict is REJECT
6. If no REJECT condition is true, apply APPROVE conditions — if ALL are satisfied, verdict is APPROVE
7. If ambiguous: default to REJECT
8. Report per output contract
</execution_order>

<output_contract>
VERDICT: [APPROVE|REJECT]
CONFIDENCE: [HIGH|MEDIUM|LOW]

## Rationale
{2-3 sentence summary of the verdict basis}

## Concerns (if REJECT or CONFIDENCE < HIGH)

| Concern | Severity | Source | Detail |
|---------|----------|--------|--------|
| {concern} | P0/P1/P2/P3 | {layer/team} | {detail} |

## Rejection Details (if REJECT)

| Condition | Met | Evidence |
|-----------|-----|----------|
| Layer verifier FAIL | YES/NO | {evidence} |
| Coverage FAIL | YES/NO | {evidence} |
| Quality FAIL | YES/NO | {evidence} |
| P0/P1 side effects | YES/NO | {evidence} |
| Fix loops exhausted | YES/NO | {evidence} |
</output_contract>

<completion_criteria>
- All REJECT conditions explicitly checked — none silently skipped
- VERDICT is APPROVE or REJECT — no PARTIAL, no "needs more info"
- If REJECT: at least one condition row shows YES with evidence
- If APPROVE: rationale explains why all conditions were satisfied
- CONFIDENCE: HIGH (clear evidence), MEDIUM (borderline), LOW (insufficient evidence to decide)
- Status codes: APPROVE | REJECT
</completion_criteria>

<scope_boundaries>
- Do NOT fix code, run additional checks, or request more information
- Do NOT modify test expectations or suggest workarounds
- Render the verdict from the evidence provided — if evidence is insufficient, REJECT with LOW confidence
- Do not approve on the basis of "probably fine" — require actual evidence
</scope_boundaries>

<ambiguity_policy>
- Evidence missing for a layer: treat as FAIL for that layer
- Conflicting layer results (one PASS, one FAIL for same check): treat as FAIL
- Quality CONCERNS without file/line specificity: treat as acceptable (P3) unless functional
- Side-effect P2/P3 only: APPROVE allowed, note concerns
- All 3 fix cycles exhausted: REJECT regardless of final state
</ambiguity_policy>
```

<!-- OMB-PLAN-000028: §13 enhanced fix loop policy multi-phase -->

## 13. Enhanced Fix Loop Policy (Multi-Phase)

This section supersedes and extends §4 Fix Loop Policy. The enhanced policy introduces a
**master loop** concept that coordinates across all verification phases.

### Master Loop Structure

| Phase | Failure Type | Fix Agent | Model |
|-------|-------------|-----------|-------|
| Layer verification | Python test failure | executor | sonnet |
| Layer verification | TypeScript test failure | executor | sonnet |
| Layer verification | Type check error | executor | sonnet |
| Layer verification | Ruff lint failure | executor | sonnet |
| Layer verification | ESLint lint failure | executor | sonnet |
<!-- OMB-PLAN-000088: added lint failure routing -->
| Layer verification | FastAPI endpoint error | api-specialist | sonnet |
| Layer verification | DB migration failure | db-specialist | sonnet |
| Layer verification | React component error | frontend-engineer | sonnet |
| Layer verification | Electron IPC error | electron-specialist | sonnet |
| Layer verification | LangGraph state error | langgraph-engineer | sonnet |
| Layer verification | Security vulnerability | security-reviewer | opus |
| Quality analysis | WRONG dimension | executor | sonnet |
| Quality analysis | SUBOPTIMAL (functional) | executor | sonnet |
| Side-effect finding | P0 data loss/corruption | db-specialist | opus |
| Side-effect finding | P0/P1 security | security-reviewer | opus |
| Side-effect finding | P1 API contract break | api-specialist | sonnet |
| Side-effect finding | P1 concurrency hazard | async-coder | sonnet |
| Coverage enforcement | File below threshold | test-engineer | sonnet |
| Critic gate | REJECT (any condition) | (routed per condition above) | (per routing) |

### Master Loop Rules

| Rule | Value | Rationale |
|------|-------|-----------|
| `masterLoop.maxIterations` | 3 | MoAI constitution: maximum 3 retries per operation |
| `masterLoop.iteration` | 0-based counter | Replaces deprecated `fixLoops` field |
| Same issue 3 times | Mark UNRESOLVABLE, stop | Identical failure 3× means fix approach is wrong |
| After 3rd critic REJECT | Escalate to user | Critic REJECT after all cycles exhausted → human decision |
| Concurrent phase fixes | Allowed | Different phase failures can be fixed in parallel |
| Regression after fix | New failure, NO loop reset | Regressions consume master loop budget |

### Deprecated Fields

The following JSON state fields are **deprecated** and replaced:

| Deprecated Field | Replacement | Notes |
|-----------------|-------------|-------|
| `fixLoops` | `masterLoop.iteration` | Old per-phase counter replaced by global master counter |
| `maxFixLoops` | `masterLoop.maxIterations` | Always 3 — no longer configurable |

### Master Loop State Schema (extension to §6)

```json
{
  "masterLoop": {
    "iteration": "number — current iteration (0-based, max 3)",
    "maxIterations": 3,
    "phases": {
      "layerVerification": "PENDING | PASS | FAIL | FIXED | UNRESOLVABLE",
      "qualityAnalysis": "PENDING | PASS | CONCERNS | FAIL | FIXED | SKIPPED",
      "sideEffectAnalysis": "PENDING | PASS | CONCERNS | FAIL | FIXED | SKIPPED",
      "coverageEnforcement": "PENDING | PASS | FAIL | BLOCKED | FIXED",
      "criticGate": "PENDING | APPROVE | REJECT"
    },
    "unresolvableIssues": [
      {
        "issue": "string — exact failure/finding",
        "phase": "string — which phase",
        "attempts": "number — how many fix cycles tried"
      }
    ],
    "escalatedToUser": "boolean — true after 3rd critic REJECT"
  }
}
```

### Escalation Protocol

When `masterLoop.iteration` reaches 3 and critic verdict is still REJECT:

1. Set `masterLoop.escalatedToUser = true`
2. Set overall verification STATUS to `FAIL`
3. Report to orchestrator:

```markdown
## Escalation Required

Verification failed after 3 master loop iterations. Critic verdict: REJECT.

### Unresolvable Issues
{list from masterLoop.unresolvableIssues}

### Recommended Action
- Review unresolvable issues with the user
- Consider plan revision (return to Step 1)
- Or accept FAIL with documented risk
```
