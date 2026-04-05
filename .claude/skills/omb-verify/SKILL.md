# OMB-PLAN-000028: restructured into 5-phase verification
---
name: omb-verify
user-invocable: true
description: >
  Use when verifying completed work, running tests, collecting evidence, or
  running Step 4 of the omb workflow. Triggers on: "verify", "run tests",
  "check implementation", "collect evidence", "verification", "Step 4",
  "is it working", "prove it works", "verify it", "test it", "check it",
  "run verification", "did it pass". Spawns parallel verifier agents per stack
  layer with bounded fix loops. Do NOT use for planning (use
  omb-create-plan) or executing code (use omb-execute).
argument-hint: "[plan-file-path]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# Verification Workflow

Verify completed work by detecting stack layers, spawning parallel verifier agents, running 5 verification phases, and producing a verification record with evidence.

<references>
- `${CLAUDE_SKILL_DIR}/reference.md` § 1 — verifier agent templates. Read in STEP 4 to build per-layer verifier prompts.
- `${CLAUDE_SKILL_DIR}/reference.md` § 2 — stack layer detection rules. Read in STEP 1 if `detect-stack-layers.sh` output needs manual interpretation.
- `${CLAUDE_SKILL_DIR}/reference.md` § 3 — evidence format and examples. Read in STEP 4 when processing verifier output.
- `${CLAUDE_SKILL_DIR}/reference.md` § 4 — fix loop policy and agent routing table. Read in STEP 9 to route failures to fix agents.
- `${CLAUDE_SKILL_DIR}/reference.md` § 5 — verification record template. Read in STEP 10 to write the record.
- `${CLAUDE_SKILL_DIR}/reference.md` § 6 — verification state JSON schema. Read in STEP 2 to initialize state.
- `${CLAUDE_SKILL_DIR}/reference.md` § 7 — tiered verification (LIGHT/STANDARD/THOROUGH). Read in STEP 1 when determining tier scope.
- `${CLAUDE_SKILL_DIR}/reference.md` § 8 — regression check patterns. Read in STEP 9 during fix-verify cycles.
- `${CLAUDE_SKILL_DIR}/reference.md` § 9 — quality analysis template. Read in STEP 6.
- `${CLAUDE_SKILL_DIR}/reference.md` § 10 — side-effect team definitions. Read in STEP 7.
- `${CLAUDE_SKILL_DIR}/reference.md` § 11 — coverage enforcement rules. Read in STEP 5.
- `${CLAUDE_SKILL_DIR}/reference.md` § 12 — harsh critic gate template. Read in STEP 8.
- `${CLAUDE_SKILL_DIR}/reference.md` § 13 — enhanced fix loop policy. Read in STEP 9.
- `.claude/rules/04-verify.md` — iron law, evidence requirements, recovery path
</references>

<completion_criteria>
The verification is complete when ALL of these hold:
- Every detected stack layer has been verified (PASS, FAIL, PARTIAL, or BLOCKED)
- Every phase (1-5) has a final status (PASS, FAIL, PARTIAL, BLOCKED, or SKIPPED)
- Fix loops completed or exhausted (max 3 cycles)
- Critic approved or max 3 iterations reached (MoAI compliant)
- Coverage data generated in Phase 1 and consumed by Phase 2
- Verification record written to `.omb/verifications/`
- Verification state updated with final status
- User presented with status report and next step recommendation

Status codes: PASS | FAIL | PARTIAL
</completion_criteria>

<ambiguity_policy>
- Plan has no Verification Criteria section: fall back to layer-default checks (pytest for Python, vitest for TypeScript, tsc --noEmit for types) — log "No explicit criteria; using layer defaults"
- Verification criterion is prose-only ("auth works correctly"): map to runnable commands using layer detection + keyword heuristics (e.g., "auth" + python layer → `pytest tests/auth/ -v` + `curl`)
- Test infrastructure unavailable (no pytest, no vitest, no Docker): mark layer as BLOCKED with reason "tool not found", continue other layers — never silently skip
- Execution state file not found: warn user "No execution state found. Run `/omb exec` first or provide a plan file path." via AskUserQuestion
- Flaky test detected (passes sometimes, fails sometimes): report as FAIL with flaky flag — never silently retry until green
- Verifier agent returns non-standard output (no STATUS line): extract what you can, mark layer PARTIAL, log "non-standard output from verifier on layer [name]"
- Fix agent introduces regression (previously passing test now fails): count as a new failure, do NOT reset the fix loop counter — regressions compound
- Quality analyzer returns SUBOPTIMAL but all tests pass: still FAIL — quality analysis failure is a real failure
- Side-effect team finds P0 but critic says APPROVE: REJECT — P0 issues override critic verdict
- Coverage tool unavailable: report BLOCKED for coverage phase, do NOT fail overall — continue with remaining phases
</ambiguity_policy>

<scope_boundaries>
This skill verifies implementations — it does NOT:
- Create or modify plans (use omb-create-plan)
- Execute code or implement features (use omb-execute)
- Generate documentation (use `/omb doc`)
- Create PRs (Step 6)
- Make architecture decisions
- Fix code directly — it routes failures to appropriate fix agents

This skill NOW includes quality analysis and side-effect detection in addition to test verification.
Fix loop fixes are scoped to verification failures only — no feature additions.
</scope_boundaries>

<anti_patterns>
- Claiming "tests pass" without running them — verification without evidence is just assertion; downstream steps trust your claim and ship broken code
- Checking exit codes only without reading output — exit code 0 does not mean all tests passed (some frameworks exit 0 with skipped tests)
- Verifying only one stack layer when changes span multiple — partial verification creates false confidence; untested layers fail in production
- Silently retrying flaky tests until they pass — masks real intermittent failures that will bite users; report flakiness as FAIL with evidence
- Running fix loops without regression re-verification — fixes that break previously-passing tests compound failures instead of resolving them
- Skipping verification because "the code looks right" — code review is not verification; only runnable evidence counts
- Verifying FAILED/SKIPPED tasks from execution — there is no implementation to verify; note them in the record for completeness but do not spawn verifiers
- Spawning verifier agents sequentially when they can run in parallel — wastes time without quality gain; all layers are independent
- Running only Phase 1 and skipping other phases when tier is STANDARD or THOROUGH — partial phase execution misses quality and side-effect issues
- Letting the critic agent fix code directly instead of routing to fix agents — critic gate is read-only; fixes must go through executor or domain specialists
- Running phases sequentially when 2-4 can run in parallel — Phases 2, 3, and 4 are independent; spawn all three in one batch
- Running tests twice — Phase 1 generates coverage data, Phase 2 reads it; never re-run tests for coverage
</anti_patterns>

<examples>
<example type="positive" label="Full verification with fix loop">
Plan: BCRW-PLAN-000042 (auth middleware). Layers detected: python, typescript.
STEP 4 spawns 2 verifier agents in parallel (one per layer) with --cov flags.
Python verifier: runs `pytest --cov --cov-report=json tests/auth/ -v` → 8 passed, 1 failed (test_refresh_expired). Coverage JSON written.
TypeScript verifier: runs `npx vitest run --coverage --coverage.reporter=json tests/auth/` → 5 passed, `tsc --noEmit` → 0 errors. STATUS: PASS.
STEP 5 (Phase 2): coverage enforcement at 85% threshold — python: 91% PASS, typescript: 88% PASS.
STEP 6 (Phase 3): quality analyzer spawned — SUBOPTIMAL on error handling pattern.
STEP 7 (Phase 4): V1 (general) and V3 (security) teams spawned in parallel — V1 finds no issues, V3 flags missing rate limiting (P1).
STEP 8 (Phase 5): critic reviews all phases — REJECT (python test failure + quality SUBOPTIMAL).
STEP 9 fix loop: routes python failure to `executor` (sonnet). Fix applied. Re-run all phases: 9 passed, quality PASS.
Final: PASS. Record written to `.omb/verifications/2026-03-20-auth-middleware.md`.
</example>
<example type="negative" label="Bad: exit-code-only checking">
Plan: BCRW-PLAN-000042. Verifier runs `pytest tests/auth/` and checks `$?` = 0.
Reports "PASS" without reading actual output. In reality, 3 tests were skipped and 1 was xfail.
Fix: Always read full command output. Report actual pass/fail/skip counts.
</example>
<example type="negative" label="Bad: single-layer verification on cross-stack change">
Plan touches Python backend + React frontend. Verifier only runs `pytest`.
Reports "PASS" even though React components have type errors caught by `tsc --noEmit`.
Fix: Detect ALL affected layers and verify each one.
</example>
<example type="positive" label="Partial: environment-blocked layers handled correctly">
Plan: BCRW-PLAN-000099. Layers detected: python, typescript, redis.
STEP 4 spawns 3 verifier agents in parallel with coverage flags.
Python verifier: `pytest --cov --cov-report=json tests/ -v` → 15 passed. `pyright` → 0 errors. STATUS: PASS.
TypeScript verifier: `npx vitest run --coverage --coverage.reporter=json` → 8 passed. `tsc --noEmit` → 0 errors. STATUS: PASS.
Redis verifier: `redis-cli PING` → BLOCKED (redis-cli not found). STATUS: BLOCKED with reason.
STEP 5 (Phase 2): coverage tool available for python/typescript — both pass. Redis coverage BLOCKED (not applicable).
STEP 6-8 (Phases 3-5): STANDARD tier, quality and side-effect analysis run. Critic APPROVE.
Final: PARTIAL — ENVIRONMENT_BLOCKED (redis layer). Record notes which layers verified, which blocked and why.
Next step: proceed to documentation noting partial verification.
</example>
</examples>

---

## STEP 0 — Locate and Load Execution Context

1. Parse `$ARGUMENTS` for plan file path.

2. If no path provided:
   ```bash
   ls -t .omb/plans/*.md 2>/dev/null | head -5
   ```
   Also check for execution state:
   ```bash
   ls -t .omb/executions/state/*.json 2>/dev/null | head -5
   ```
   Ask the user which plan to verify via `AskUserQuestion`.

3. Locate the execution state file at `.omb/executions/state/{plan-filename}.json`.
   - If not found: warn user "No execution state found for this plan. Run `/omb exec` first or verify manually." via `AskUserQuestion`. If user wants to proceed without execution state, continue with plan-only mode (extract file paths from plan's Deliverable column).

4. Read the plan file. Extract:
   - Tracking code (pattern: `[A-Z]{2,6}-PLAN-\d{6}`)
   - Verification Criteria section
   - Tasks table (to identify deliverables)

5. Read the execution state file (if exists). Extract:
   - Tasks with status DONE — these are the tasks to verify
   - Files created and modified per task
   - Tasks with status FAILED/SKIPPED — note for the record but do not verify

6. Ensure verification directories exist:
   ```bash
   mkdir -p .omb/verifications/state
   ```

**Step output:** Execution state loaded. Tracking code extracted: `{TRACKING_CODE}`. DONE task file lists collected. Plan verification criteria captured. FAILED/SKIPPED tasks noted for record.

---

## STEP 1 — Detect Stack Layers and Determine Tier

1. Run the detection script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/detect-stack-layers.sh <execution-state-path-or-plan-path>
   ```
   Capture the JSON output.

2. Parse the JSON result. The script outputs:
   - `layers`: array of detected layers (e.g., `["python", "typescript", "redis"]`)
   - `tier`: suggested tier (`LIGHT`, `STANDARD`, or `THOROUGH`)
   - `totalFiles`: count of files to verify
   - `securityRelated`: boolean (true if auth/security files detected)

3. Present detected layers and tier to user:
   ```
   Stack layers detected: python, typescript
   Suggested verification tier: STANDARD (12 files, no security layer)

   Tiers:
   - LIGHT: basic checks only (pytest/vitest pass, tsc clean)
   - STANDARD: full test suites + type checks + endpoint verification
   - THOROUGH: all of STANDARD + security audit + load testing + manual checks

   Phase coverage per tier:
   | Tier     | Phase 1      | Phase 2       | Phase 3  | Phase 4                 | Phase 5           |
   |----------|--------------|---------------|----------|-------------------------|-------------------|
   | LIGHT    | Run (+cov)   | Run (75%)     | Skip     | Skip                    | Skip (auto-PASS)  |
   | STANDARD | Run (+cov)   | Run (85%)     | Run      | Run                     | Run (critic sonnet) |
   | THOROUGH | Run (+cov)   | Run (90%)     | Run      | Run (+security audit)   | Run (critic opus) |

   Proceed with STANDARD? Override? [y/light/thorough]
   ```
   Use `AskUserQuestion` for confirmation.

4. Apply user override if any.

**Step output:** `{layers: [...], tier: "STANDARD", totalFiles: N}` confirmed by user. Tier selection gates model cost and verification depth — wrong tier wastes resources (THOROUGH on trivial change) or misses issues (LIGHT on security change).

---

## STEP 2 — Initialize Verification State

1. Check for existing state file at `.omb/verifications/state/{plan-filename}.json`.

2. If exists:
   | Existing Status | Prompt via AskUserQuestion | Options |
   |---|---|---|
   | `IN_PROGRESS` | "Previous verification incomplete." | resume / restart |
   | `PASS` | "Plan already verified." | re-verify / abort |
   | `PARTIAL` | "Previous verification partially complete." | resume / restart |
   | `FAIL` | "Previous verification failed." | retry / restart |

3. Create or update state file (schema in `${CLAUDE_SKILL_DIR}/reference.md` § 6):
   ```json
   {
     "planFile": "<relative-path>",
     "trackingCode": "<extracted-code>",
     "startedAt": "<ISO-8601>",
     "completedAt": null,
     "status": "IN_PROGRESS",
     "tier": "STANDARD",
     "layers": {
       "python": {"status": "PENDING", "checks": [], "evidence": []},
       "typescript": {"status": "PENDING", "checks": [], "evidence": []}
     },
     "fixLoops": 0,
     "maxFixLoops": 3,
     "masterLoop": {"iteration": 0, "maxIterations": 3, "history": []},
     "phases": {
       "testAndType": {"status": "PENDING", "completedAt": null},
       "coverage": {"status": "PENDING", "completedAt": null},
       "qualityAnalysis": {"status": "PENDING", "completedAt": null},
       "sideEffectAnalysis": {"status": "PENDING", "completedAt": null},
       "criticGate": {"status": "PENDING", "completedAt": null}
     },
     "criteria": []
   }
   ```

**Step output:** State file written to `.omb/verifications/state/{plan-filename}.json` with status `IN_PROGRESS`. All layers initialized as `PENDING`.

---

## STEP 3 — Build Verification Plan from Plan Criteria

1. Read the plan's Verification Criteria section.

2. For each criterion, classify:
   - **Runnable** — contains a command (e.g., `pytest tests/ -v`, `grep -c "verify" README.md`)
   - **Prose** — descriptive only (e.g., "JWT refresh works correctly")

3. Map each criterion to a layer and check — prose criteria ("auth works correctly") cannot be verified directly; without translation to runnable commands they remain unverifiable claims:
   - Runnable criteria: use the command directly
   - Prose criteria: translate using layer defaults and keyword heuristics:
     | Keyword Pattern | Layer | Generated Check |
     |---|---|---|
     | auth, jwt, token | python | `pytest tests/auth/ -v` + `curl` endpoint checks |
     | component, render, UI | typescript | `npx vitest run` + `tsc --noEmit` |
     | schema, migration, table | db | `alembic current` + schema verification |
     | redis, cache, TTL | redis | `redis-cli PING` + key pattern checks |
     | endpoint, API, route | python/node | `curl` with expected status codes |

4. Add layer-default checks not covered by criteria (see `${CLAUDE_SKILL_DIR}/reference.md` § 2):
   - Python layer: `pytest -v`, `pyright` or `mypy --strict`
   - TypeScript layer: `npx vitest run`, `tsc --noEmit`
   - Node.js layer: `npx jest` or `npx vitest run`, `tsc --noEmit`
   - DB layer: migration status, schema verification
   - Redis layer: connection check, key pattern verification

5. For THOROUGH tier: add security checks, endpoint stress tests, manual verification items.

**Step output:** Checks array per layer, each with `{command, expectedOutcome, source}`. Source is either "plan-criteria" or "layer-default".

---

## STEP 4 — Phase 1: Test & Type Verification + Coverage Data Generation

For each detected layer, build a verifier agent prompt using templates from `${CLAUDE_SKILL_DIR}/reference.md` § 1.

1. Fill placeholders:
   - `{LAYER}` — the stack layer name
   - `{TRACKING_CODE}` — from plan
   - `{CHECKS}` — the checks array for this layer from STEP 3
   - `{FILES}` — files to verify from execution state (filtered by layer)
   - `{TIER}` — verification tier (LIGHT/STANDARD/THOROUGH)
   - `{CRITERIA}` — relevant plan criteria for this layer

2. Set model tier based on verification tier:
   - LIGHT: haiku
   - STANDARD: sonnet
   - THOROUGH: opus (for security layer), sonnet (for others)

3. **Coverage flags are mandatory** — include coverage collection in all test commands:
   - Python: `pytest --cov --cov-report=json {test_paths} -v`
   - TypeScript: `npx vitest run --coverage --coverage.reporter=json {test_paths}`
   - Node.js: `npx jest --coverage --coverageReporters=json {test_paths}`

4. Invoke the `Agent` tool for all verifier agents in a single parallel batch (one call per layer, all in the same response) — set `subagent_type: "verifier"` and `model` per the tier table above. Layers are independent and sequential spawning wastes time without quality gain.

5. After all verifier agents complete:
   - Parse output for STATUS (PASS / FAIL / PARTIAL / BLOCKED)
   - Record evidence table (check name, result, evidence text) per layer
   - Record coverage data file paths for each layer (e.g., `.coverage/coverage-summary.json`, `coverage/coverage-summary.json`)
   - Update verification state per layer in disk

**Phase 1 status**: Aggregate per-layer results. Any FAIL means Phase 1 = FAIL.

**Step output:** All verifier agents launched (one per layer) with coverage flags. Phase 1 status determined. Coverage data file paths recorded for Phase 2.

---

## STEP 5 — Phase 2: Coverage Enforcement

Read `${CLAUDE_SKILL_DIR}/reference.md` § 11 for tier thresholds before running.

Tier thresholds:
- LIGHT: 75%
- STANDARD: 85%
- THOROUGH: 90%

For each detected layer that produced coverage data in Phase 1:

1. Run the coverage enforcement script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/run-coverage.sh <layer> <coverage-file-path>
   ```

2. Interpret results:
   - **PASS**: coverage meets or exceeds threshold — record percentage
   - **FAIL**: coverage below threshold — list files below threshold with their percentages
   - **BLOCKED**: coverage tool not found or coverage file missing — mark phase BLOCKED for this layer, do NOT fail overall

3. Aggregate Phase 2 status:
   - All layers PASS → Phase 2 = PASS
   - Any layer FAIL → Phase 2 = FAIL (list failing files)
   - Any layer BLOCKED but no FAIL → Phase 2 = PARTIAL

NOTE: Phase 2 does NOT re-run tests. It reads the coverage data files produced in Phase 1. If coverage data is missing for a layer, report BLOCKED for that layer.

**Step output:** Per-layer coverage percentages and PASS/FAIL/BLOCKED status. Phase 2 overall status.

---

## STEP 6 — Phase 3: Implementation Quality Analysis

**Tier guard**: if tier == LIGHT, mark Phase 3 as SKIPPED and proceed to STEP 10 (collect results from all phases).

Read `${CLAUDE_SKILL_DIR}/reference.md` § 9 for the quality analysis template before spawning.

1. Read plan context and architecture decisions from the plan file.

2. Invoke the `Agent` tool with `subagent_type: "reviewer"` using the template from reference.md § 9:
   - Model: sonnet for STANDARD, opus for THOROUGH
   - Provide: plan context, architecture decisions, list of changed files, tier

3. Quality analyzer evaluates:
   - Code structure adherence to plan's architecture decisions
   - Error handling completeness at system boundaries
   - Type safety (no `any` without justification, no missing type hints)
   - Naming consistency (follows code-conventions.md)
   - Dead code or unreachable branches introduced

4. Quality analyzer returns one of (per reference.md §9 output contract):
   - **PASS**: implementation meets quality standards
   - **CONCERNS**: implementation works but has quality issues — any SUBOPTIMAL/BLOATED/DEVIATES/VIOLATES dimension (treated as FAIL)
   - **FAIL**: critical quality problems found
   - **BLOCKED**: cannot analyze (missing files, tool error)

5. Phase 3 status: PASS maps to PASS; CONCERNS maps to FAIL (functionally blocking); FAIL maps to FAIL; BLOCKED maps to BLOCKED.

**Step output:** Quality analysis complete. Phase 3 status. List of quality issues found (if any).

---

## STEP 7 — Phase 4: Side-Effect Analysis

**Tier guard**: if tier == LIGHT, mark Phase 4 as SKIPPED and proceed to STEP 10.

Read `${CLAUDE_SKILL_DIR}/reference.md` § 10 for V-team definitions before spawning.

1. Reuse the `detect-stack-layers.sh` output from STEP 1 to determine which V-teams to spawn.

2. V-team spawning rules:
   - **V1 (General Impact)**: ALWAYS spawns for every verification run
   - **V2 (API Contract)**: spawns if API files changed (api-specialist, sonnet)
   - **V3 (Data Integrity)**: spawns if `database` or `redis` layer detected (db-specialist, sonnet)
   - **V4 (Security Regression)**: spawns if `securityRelated == true` or tier == THOROUGH (security-reviewer, opus)
   - **V5 (Frontend Regression)**: spawns if `typescript` layer with UI files detected (frontend-engineer, sonnet)
   - **V6 (Async/Concurrency)**: spawns if async/concurrent code changed (async-coder, sonnet)

3. Invoke the `Agent` tool for ALL applicable V-teams in a single parallel batch (one call per V-team). Set `subagent_type` per the V-team table (e.g., V2 → `subagent_type: "api-specialist"`, V4 → `subagent_type: "security-reviewer"`).

4. Collect findings from all V-teams:
   - Assign VER-NNN IDs sequentially to each finding
   - Deduplicate: same file + same line + same issue type → keep highest severity
   - Tag each finding with: team, severity (P0/P1/P2/P3), file, description

5. For THOROUGH tier: V3 additionally runs a security audit using OWASP patterns.

6. Phase 4 status:
   - No P0 findings → PASS
   - P1+ findings only → PASS with warnings listed
   - Any P0 findings → FAIL (P0 issues are blocking)
   - BLOCKED → tool errors prevented analysis

**Step output:** V-teams spawned in parallel. Findings collected, deduplicated, and tagged. Phase 4 status.

---

**PARALLELIZATION NOTE**: Phases 2, 3, and 4 (STEPs 5, 6, 7) are INDEPENDENT of each other. After Phase 1 (STEP 4) completes, spawn all agents for Phases 2, 3, and 4 in a single batch. Phase 5 (STEP 8) waits for all three to complete before running.

---

## STEP 8 — Phase 5: Harsh Critic Gate

**Tier guard**: if tier == LIGHT, mark Phase 5 as SKIPPED (auto-PASS) and proceed to STEP 10.

Read `${CLAUDE_SKILL_DIR}/reference.md` § 12 for the harsh critic gate template before spawning.

1. **P0 override check**: If any phase (1-4) has unresolved P0 issues, set Phase 5 = REJECT immediately without spawning critic. P0 issues override critic verdict.

2. Spawn critic agent using the template from reference.md § 12:
   - Model: sonnet for STANDARD, opus for THOROUGH
   - Provide: all phase results, evidence tables, quality findings, side-effect findings, plan criteria

3. Critic evaluates holistically:
   - Are all plan verification criteria met?
   - Do quality issues block delivery?
   - Are side-effect findings acceptable at this tier?
   - Is coverage adequate for the change size?

4. Critic verdict:
   - **APPROVE**: proceed to STEP 10 (write record)
   - **REJECT**: enter STEP 9 (fix loop)

5. Phase 5 status = critic verdict (APPROVE → PASS, REJECT → FAIL).

**Step output:** Critic verdict. Phase 5 status. If REJECT, list of issues the critic flagged.

---

## STEP 9 — Fix Loop

Read `${CLAUDE_SKILL_DIR}/reference.md` § 13 for the enhanced fix loop routing table before routing.

If Phase 5 = REJECT or any phase = FAIL:

1. **Diagnose**: for each failure across ALL phases, determine the fix agent using the routing table:
   | Failure Type | Fix Agent | Model |
   |---|---|---|
   | Python test failure | executor | sonnet |
   | TypeScript test failure | executor | sonnet |
   | Type check error | executor | sonnet |
   | API endpoint error | api-specialist | sonnet |
   | DB migration failure | db-specialist | sonnet |
   | Redis connection/state | db-specialist | sonnet |
   | Security vulnerability (P0) | security-reviewer | opus |
   | Build/compile error | executor | sonnet |
   | Coverage below threshold | executor | sonnet |
   | Quality analysis FAIL | executor | sonnet |
   | Side-effect P0 finding | security-reviewer or db-specialist | opus |

2. **Fix**: spawn fix agent(s) with failure context. Fix scope is limited to resolving verification failures — no feature additions.

3. **Re-run ALL phases**: after fix, loop back to STEP 4 (full master loop). This ensures Phase 1 regenerates coverage data and all downstream phases receive fresh results.

4. **Master loop tracking**:
   - Increment `masterLoop.iteration` each cycle
   - Record which fixes were attempted per iteration
   - Same-failure-3-times rule: if the identical failure appears in 3 consecutive iterations, mark it as unresolvable (do NOT continue fixing)

5. **Master loop gate**:
   - Fix successful + all phases PASS → proceed to STEP 10
   - `masterLoop.iteration >= 3` → stop fix loop, escalate via `AskUserQuestion`:
     ```
     Verification fix loop exhausted (3 master iterations).
     Unresolved failures:
     - [list each unresolved failure with VER-NNN ID]

     Options: [abort] [skip and document] [manual fix then re-verify]
     ```

**Step output:** Fix loop complete. Master iteration count recorded. Unresolved failures listed (if any). State updated.

---

## STEP 10 — Write Verification Record

Write the verification record to `.omb/verifications/{plan-filename}.md` using the template from `${CLAUDE_SKILL_DIR}/reference.md` § 5.

The record includes:
- **Metadata**: plan file, tracking code, timestamps, tier, duration
- **Plan Criteria Mapping**: each plan criterion → check command → result (PASS/FAIL)
- **Phase Results Summary**: per-phase status table (Phase 1-5)
- **Layer Evidence**: per-layer evidence table with actual command output
- **Coverage Results**: per-layer coverage percentage vs threshold (Phase 2)
- **Quality Analysis**: findings from Phase 3 quality analyzer (if run)
- **Side-Effect Findings**: VER-NNN tagged findings from Phase 4 V-teams (if run)
- **Critic Verdict**: Phase 5 critic decision with rationale (if run)
- **Fix History**: fix attempts, agents used, outcomes (if any fix loops ran)
- **Unverified Tasks**: FAILED/SKIPPED tasks from execution (noted for completeness)
- **Environment Limitations**: any checks skipped due to missing tools/services

Use the `Write` tool to create the record file.

**Step output:** Record file written to `.omb/verifications/{plan-filename}.md` with full evidence trail including all 5 phase results.

---

## STEP 11 — Report to User

1. Update verification state:
   - Determine final status:
     - **PASS** — all phases passed (or passed after fix loops)
     - **FAIL** — one or more phases failed after fix loops exhausted
     - **PARTIAL** — some layers/phases passed, some blocked due to environment limitations
   - Set `completedAt` to current ISO timestamp
   - Write final state to disk

2. Present the verification summary with per-phase status:

### If PASS:
```
**Verification PASS**
- Layers verified: {N}/{N} passed
- Phase 1 (Tests):    PASS ({N} passed, {N} failed)
- Phase 2 (Coverage): PASS ({N}% avg, threshold {T}%)
- Phase 3 (Quality):  PASS | SKIPPED (tier: LIGHT)
- Phase 4 (Side-FX):  PASS | SKIPPED (tier: LIGHT)
- Phase 5 (Critic):   APPROVE | SKIPPED (tier: LIGHT)
- Fix loops: {N} master iterations
- Evidence: .omb/verifications/{filename}.md

Next step: Proceed to Step 5: Document (`/omb doc`)
```

### If FAIL:
```
**Verification FAIL**
- Layers: {passed}/{total} passed, {failed} failed
- Phase 1 (Tests):    {STATUS}
- Phase 2 (Coverage): {STATUS}
- Phase 3 (Quality):  {STATUS}
- Phase 4 (Side-FX):  {STATUS}
- Phase 5 (Critic):   {VERDICT}
- Unresolved failures: {list with VER-NNN IDs}
- Fix loops: {N}/{max} master iterations exhausted
- Evidence: .omb/verifications/{filename}.md

{failed} phases need attention. Review the verification record for details.
Recommended: fix failures manually, then re-run `/omb verify`
```

### If PARTIAL:
```
**Verification PARTIAL**
- Layers: {passed}/{total} passed, {blocked} blocked (environment)
- Phase 2 (Coverage): BLOCKED ({list} — coverage tool not found)
- Blocked layers: {list with reasons}
- Evidence: .omb/verifications/{filename}.md

Environment limitations prevented full verification. Blocked checks noted in record.
Next step: Proceed to Step 5: Document (`/omb doc`) — note partial verification in docs
```

**Step output:** User receives summary with per-phase status + next step recommendation. State file finalized.

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>verify(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
