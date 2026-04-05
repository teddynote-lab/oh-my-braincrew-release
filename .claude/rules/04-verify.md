---
description: "Step 4 of the 6-step workflow: Verification gate and evidence requirements"
---

# Step 4: Verify

Iron law: NO completion claims without fresh verification evidence.

## Verification Gate

Every task must pass through this gate before claiming completion:

1. **IDENTIFY** — what specific proof is needed (tests, endpoint responses, type checks).
2. **RUN** — execute the verification commands.
3. **READ** — read the full output, not just the exit code.
4. **VERIFY** — confirm output matches success criteria.
5. **CLAIM** — report with evidence attached.

If any step fails, iterate — do not claim partial success.

## Verifier Routing

| Task Size | Model | When |
|-----------|-------|------|
| Small (<5 files) | haiku | Single-layer changes, simple fixes |
| Standard | sonnet | Multi-file, multi-layer changes |
| Large / Security-sensitive | opus | Auth, data access, Electron security, migrations |

## Required Evidence by Layer

### Python / FastAPI
- `pytest -v` output with pass/fail counts.
- `mypy --strict` or `pyright` with zero errors.
- For API changes: curl/httpie response showing correct status and body.

### TypeScript / React
- `npx vitest run` output with pass/fail counts.
- `tsc --noEmit` with zero errors.
- For component changes: no console errors in test output.

### Node.js
- `npx jest` or `npx vitest run` output.
- `tsc --noEmit` with zero errors.

### Database
- Migration status: `alembic current` or equivalent.
- Schema verification: table/column existence check.
- For Redis: `redis-cli PING` → PONG, key pattern verification.

### Integration
- Cross-layer contract verification: API response matches frontend consumption.
- Docker health checks passing (if applicable).
- CI pipeline green (if applicable).

## Evidence Format

```markdown
## Verification Report

### Status: PASS / FAIL / PARTIAL

### Evidence
| Check | Result | Evidence |
|-------|--------|----------|
| pytest | PASS | 42 passed, 0 failed |
| tsc | PASS | 0 errors |
| endpoint /api/users | PASS | 200 OK, correct shape |

### Failures (if any)
- **What failed**: [specific test/check]
- **Error**: [exact error message]
- **Recommended fix agent**: [executor/db-specialist/etc.]
```

## Anti-Patterns

- Claiming "tests pass" without running them.
- Reading only the exit code, not the actual output.
- Retrying flaky tests silently until they pass.
- Reporting only the first failure when there are multiple.

## Recovery Path

When verification fails:
1. Report failure with evidence to orchestrator.
2. Orchestrator routes to appropriate fix agent (executor, db-specialist, etc.).
3. Fix agent implements correction.
4. Return to IDENTIFY step — re-run full verification.
5. Maximum 3 retry cycles. After 3 failures, escalate to user.

## Environment Limitations

When verification infrastructure is unavailable (no local DB, no Docker), document which checks were skipped and why. Mark report as `PARTIAL — ENVIRONMENT BLOCKED`. Never silently omit checks.

<!-- OMB-PLAN-000028: enhanced verification phases -->

## Enhanced Verification Phases

The verify skill runs up to 5 phases depending on tier:

| Phase | Name | What It Checks | Tier |
|-------|------|---------------|------|
| 1 | Test & Type + Coverage Data | pytest, vitest, tsc, pyright + generate coverage data via --cov flags | All |
| 2 | Coverage Enforcement | Per-file line coverage vs threshold (LIGHT 75%, STANDARD 85%, THOROUGH 90%) | All |
| 3 | Implementation Quality | Solution fitness, over/under-engineering, pattern consistency, best practices | STANDARD+ |
| 4 | Side-Effect Analysis | API contract breaks, security regression, data integrity, race conditions | STANDARD+ |
| 5 | Harsh Critic Gate | Final holistic review — APPROVE or REJECT | STANDARD+ |

The iron law (IDENTIFY → RUN → READ → VERIFY → CLAIM) applies to EACH phase, not just Phase 1.

## Coverage Evidence

| Layer | Tool | Threshold (STANDARD) |
|-------|------|---------------------|
| Python | pytest-cov (coverage.json) | 85% per changed file |
| TypeScript | vitest --coverage (coverage-summary.json) | 85% per changed file |

Coverage is enforced per-file, not aggregate. A project with 95% overall coverage can still fail if a single changed file is at 70%.

## Quality Analysis Evidence

| Dimension | Ratings | FAIL When |
|-----------|---------|-----------|
| Solution Fitness | OPTIMAL / ADEQUATE / SUBOPTIMAL / WRONG | SUBOPTIMAL or WRONG |
| Over-engineering | LEAN / ACCEPTABLE / BLOATED | BLOATED |
| Under-engineering | COMPLETE / GAPS_FOUND | GAPS_FOUND with P0/P1 gaps |
| Pattern Consistency | CONSISTENT / DEVIATES | DEVIATES on critical patterns |
| Best Practices | FOLLOWS / VIOLATES | VIOLATES on OWASP/security items |

## Side-Effect Analysis Evidence

Side-effect findings use VER-NNN IDs with P0-P3 severity:
- P0/P1: must fix before approval — enters fix loop
- P2/P3: noted in verification record, does not block

Side-effect teams (V1-V6) are spawned based on detected stack layers. V1 (code quality regression) always runs for STANDARD+ tier.

## Enhanced Recovery Path

When verification fails across multiple phases:
1. Critic provides rejection details with per-phase breakdown.
2. Fix loop routes each failure to the appropriate agent per phase (see reference.md §13).
3. After fix: ALL phases re-run (not just the failed one) — regression detection spans phases.
4. Max 3 master iterations (MoAI compliant). After 3rd critic rejection, escalate to user.
5. Same issue appearing 3 times consecutively: mark as unresolvable, stop trying.
6. Unresolvable issues after 3 iterations: mark FAIL, document in verification record.

## Tier-Based Phase Selection

| Tier | Phases Run | Phases Skipped |
|------|-----------|---------------|
| LIGHT | 1, 2 (at 75%) | 3, 4, 5 (auto-approve) |
| STANDARD | 1, 2 (at 85%), 3, 4, 5 (critic: sonnet) | — |
| THOROUGH | 1, 2 (at 90%), 3, 4 (+security audit), 5 (critic: opus) | — |

LIGHT tier is appropriate for trivial changes (<=5 files, no security). STANDARD is the default. THOROUGH is auto-selected when security files are detected or >20 files changed.
