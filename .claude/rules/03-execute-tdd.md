---
description: "Step 3 of the 6-step workflow: TDD execution phases and test-first approach"
---

# Step 3: Execute (TDD)

> **Skill available:** Use `/omb exec` to automate this step with agent teams, dependency-aware wave scheduling, and spec-code tracking.

Execution follows a phase-based approach with tests written before implementation.

## Execution Phases

Every implementation MUST define and follow these phases:

### Phase 1: Scaffolding and Types
- Create file structure, module boundaries, TypeScript interfaces, Pydantic models.
- Define API contracts (request/response shapes) before implementation.
- No business logic in this phase — just structure.

### Phase 2: Tests
- Write tests BEFORE implementation code.
- Tests define expected behavior — they are the specification.
- Use appropriate test framework per layer:
  - Python: pytest. See `.claude/rules/testing/pytest-standards.md`.
  - TypeScript/React: vitest. See `.claude/rules/testing/vitest-standards.md`.
  - Integration: see `.claude/rules/testing/integration-tests.md`.
- Tests SHOULD fail at this point (red phase).

### Phase 3: Implementation
- Write code to make tests pass (green phase).
- Follow conventions in `.claude/rules/code-conventions.md`.
- Follow stack-specific rules in `.claude/rules/backend/`, `.claude/rules/frontend/`, `.claude/rules/langchain/`, etc.
- One logical change per commit.

### Phase 4: Integration
- Wire components together across layers.
- Run full test suite — unit + integration.
- Verify cross-layer contracts (API response matches frontend expectations).

## TDD Rules

- **Test first**: write the test, see it fail, then write the code.
- **Minimal implementation**: write only enough code to make the test pass.
- **Refactor**: clean up after green, keeping tests passing.
- **No test skipping**: if a test is hard to write, the design needs improvement.

## Test Retry Policy

When tests fail during execution, the execute skill uses a test-aware retry mechanism:

- **Test failures** (tests exist but some fail): up to **3 retries** with progressive error context injection
- **Implementation errors** (code does not compile/parse): up to **2 retries** (standard retry policy)
- **Environment errors** (tools/services unavailable): **BLOCKED immediately** (no retries — requires user intervention)

The test retry limit of 3 complies with the MoAI constitution's "Maximum 3 retries per operation" rule.

On each test retry, the agent receives:
1. Which specific tests failed and their assertion errors
2. The implementation files from the previous attempt (to modify, not recreate)
3. Instructions to fix the implementation to make tests pass (not modify tests)

If the agent believes a test itself is wrong on the final retry, it may report `NEEDS_CONTEXT` with evidence. The orchestrator escalates to the user.

Authoritative source: `skills/omb-execute/reference.md` § 7 — Retry & Fix Loop.

## Execute vs Verify Retry Relationship

The verify skill (`.claude/rules/04-verify.md`) has a separate fix loop with a maximum of 3 cycles. These two retry mechanisms serve different purposes:

- **Execute retries** (this step): per-task retries during implementation. Goal: make each task's tests pass before moving to the next wave.
- **Verify fix loops** (Step 4): holistic verification across all completed tasks. Goal: ensure the entire plan's verification criteria are met end-to-end.

These are complementary, not additive. A task that passes execute retries may still fail during verify if cross-layer integration introduces regressions. Each mechanism has its own independent retry budget.

## Agent Routing

- `executor` (sonnet): primary implementation agent.
- `test-engineer` (sonnet): test design and complex test implementation.
- Domain specialists: when implementation is narrow to one stack layer.

## When the Plan is Wrong

If during execution the plan doesn't match reality:
1. STOP implementation.
2. Report back to orchestrator with evidence of the discrepancy.
3. Do NOT freelance — deviating from the plan without approval creates hidden risk.

## Commit Cadence

- Commit after each phase completes successfully.
- Commit message references the plan: `feat(auth): add JWT middleware [plan: 2026-03-20-auth]`.
