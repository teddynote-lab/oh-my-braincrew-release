---
name: omb-improve-plan
description: "Plan improvement guide — fix strategies by root cause category for implementation plan quality issues identified by omb-evaluation-plan."
---

# Plan Improvement Guide

Provides root cause diagnosis and fix strategy templates for improving implementation plans based on P0-P3 issue tickets from `omb-evaluation-plan`.

This skill is loaded by the `plan-improver` agent. It is NOT user-invocable.

## Improvement Workflow

1. **Receive tickets** — Accept the evaluation score sheet and P0-P3 issue tickets
2. **Diagnose root causes** — Cluster related failures by underlying root cause
3. **Plan fixes** — One fix per root cause (not per item). P0 before P1.
4. **Apply fixes** — Edit the plan document using fix strategy templates
5. **Verify no regression** — Produce regression diff table
6. **Report** — Output changes made + regression check

## Root Cause Categories

Before fixing individual issues, cluster related failures by root cause. Multiple FAIL items often share a single underlying problem. Fixing the root cause resolves multiple items at once.

| Category | Signal | Fix Approach |
|----------|--------|-------------|
| **REQUIREMENTS-GAP** | Multiple `req.*` failures | Add missing sections: summary, scope boundaries, acceptance criteria. Interview-style: "What does the user actually need?" |
| **DOMAIN-MISMATCH** | Multiple `domain.*` failures | Split compound tasks into single-domain tasks. Reassign @agent precisely using the domain mapping table. Ensure domain column uses exact values. |
| **DELEGATION-ERROR** | Multiple `agent.*` failures | Cross-reference @agent names against `.claude/agents/omb/`. Add missing Skill() references. Verify each agent file exists. |
| **UNDERSPECIFIED-TECH** | Multiple `tech.*` failures | Read the codebase to find actual file:line references. Complete the tech stack table. Document architecture decisions with rationale. |
| **MISSING-TDD** | Multiple `tdd.*` failures | Add Section 6 using the template from 01-plan-writing.md. Specify pytest/vitest per domain. Set coverage targets (85%+ line, 80%+ branch). Add `Skill("omb-tdd")` reference. |
| **PHASE-DISORDER** | Multiple `phase.*` failures | Reorder phases by dependency graph. Add "의존성" column. Group independent tasks for parallel execution. Mark critical path with [CP]. |
| **DOCS-MISSING** | Multiple `docs.*` failures | Add Section 7 using the template from 01-plan-writing.md. List specific `docs/` paths with create/update actions. Add `Skill("omb-doc")` and @doc-writer references. |
| **RISK-BLIND** | Multiple `risk.*` failures | Add Section 8. List concrete risks with likelihood/impact/mitigation table. Add user verification checklist for unverified assumptions. |
| **INCOMPLETE** | Multiple `complete.*` failures | Fill all 8 section headers. Align TODO checklist with phase tasks. Replace all placeholders ({}, TBD, TODO). Add plan metadata (date, status). |

## Fix Strategy Templates

### REQUIREMENTS-GAP fixes

1. **Add summary** (if `req.summary` FAIL):
   - Write a 1-3 sentence summary answering: "What is being built and for whom?"
   - Must state the problem being solved, not just the solution

2. **Add scope boundaries** (if `req.scope-in` or `req.scope-out` FAIL):
   - List concrete deliverables under "범위 내"
   - List explicit non-goals under "범위 외" (what will NOT be built)

3. **Add acceptance criteria** (if `req.acceptance` FAIL):
   - Write testable criteria with checkboxes
   - Each criterion must be verifiable (not "works well" but "returns 200 for valid input")

### DOMAIN-MISMATCH fixes

1. **Split compound tasks** (if `domain.split` FAIL):
   - Find tasks with descriptions spanning two domains (e.g., "Add endpoint with DB model")
   - Split into separate tasks: Task A (API domain) + Task B (DB domain)
   - Update TODO checklist to reflect the split

2. **Use precise domain values** (if `domain.precise` FAIL):
   - Replace vague labels ("backend", "server") with exact domain values from 01-plan-writing.md
   - Valid values: API, DB, UI, Electron, AI, Infra, Security, Code

3. **Add missing domains** (if `domain.coverage` FAIL):
   - Review features against domain mapping table
   - Add tasks for any domain that's needed but not covered

### DELEGATION-ERROR fixes

1. **Add @agent references** (if `agent.assigned` FAIL):
   - Every task MUST have exactly one @agent-name
   - Use the domain mapping table to select the correct agent

2. **Verify agent names** (if `agent.valid` FAIL):
   - Cross-reference every @agent-name against actual files in `.claude/agents/omb/`
   - Fix any invented names to match real agents

3. **Add Skill() references** (if `agent.skill-ref` FAIL):
   - Add `Skill("omb-orch-{domain}")` for each task based on its domain
   - Include domain-specific skills (omb-tdd, omb-mermaid, omb-doc) where relevant

### UNDERSPECIFIED-TECH fixes

1. **Complete tech stack table** (if `tech.stack-table` FAIL):
   - Fill all columns: 기능, 기술 스택, 참고 코드, 도메인, 비고
   - List specific frameworks/libraries, not generic "Python" or "TypeScript"

2. **Add file:line references** (if `tech.file-refs` FAIL):
   - Read the codebase to find actual reference files
   - Use `file.py:42` format in the "참고 코드" column
   - If no existing code, note "신규 생성" with target path

3. **Document architecture decisions** (if `tech.arch-decisions` FAIL):
   - For each non-obvious choice: state the decision, rationale, and alternatives considered
   - Pattern: "{결정}: {근거}. 대안: {기각된 옵션과 사유}"

### MISSING-TDD fixes

1. **Add TDD section** (if `tdd.section` FAIL):
   - Copy Section 6 template from 01-plan-writing.md
   - Fill in stack-specific details

2. **Specify test commands** (if `tdd.commands` FAIL):
   - Python: `pytest tests/{module}/ -v --cov={source} --cov-report=term-missing`
   - TypeScript: `npx vitest run --coverage`
   - Include specific test file paths

3. **Set coverage targets** (if `tdd.coverage` FAIL):
   - Standard: 85%+ line, 80%+ branch
   - Critical paths: 95%+ line, 90%+ branch
   - Identify which tasks are critical path

### PHASE-DISORDER fixes

1. **Reorder by dependency** (if `phase.ordered` FAIL):
   - Build a dependency graph from task deliverables and inputs
   - Ensure no task starts before its dependencies are complete

2. **Add dependency column** (if `phase.deps-explicit` FAIL):
   - Use `#N` references for dependencies, `—` for no dependencies
   - Comma-separate multiple dependencies: `#1, #3`

3. **Group parallel tasks** (if `phase.parallel` FAIL):
   - Independent tasks within the same phase can run concurrently
   - Move independent tasks into the same phase

4. **Mark critical path** (if `phase.critical-path` FAIL):
   - Identify the longest dependency chain
   - Add `[CP]` marker to critical path tasks in the TODO checklist

### DOCS-MISSING fixes

Add Section 7 with:
- Specific `docs/` file paths (not generic "update docs")
- Create/update action per file
- @doc-writer agent assignment
- `Skill("omb-doc")` reference

### RISK-BLIND fixes

Add Section 8 with:
- At least 3 risks for non-trivial plans
- 가능성/영향도 ratings (높음/중간/낮음)
- Concrete mitigation actions (not vague "be careful")
- User verification checklist for unverified assumptions

### INCOMPLETE fixes

- Scan for missing section headers (1-8) and add them
- Compare TODO checklist items against phase task tables — fix mismatches
- Search for placeholder patterns (`{}`, `TBD`, `TODO`, `...`) and replace with real content
- Add metadata header (creation date, status, evaluation score)

## Regression Check

After applying fixes, produce a regression diff table:

```
| Item ID | Before | After | Delta |
|---------|--------|-------|-------|
| req.summary | FAIL | PASS | +1 |
| domain.single | PASS | PASS | 0 |
| agent.assigned | PASS | FAIL | -1 REGRESSION |
```

**Any REGRESSION (-1) entries must be fixed before reporting DONE.** If a fix introduces a regression, the fix is wrong — revise it.

## Rules

- **Do not regress** — Each improvement must preserve all previously passing items
- **Diagnose before fixing** — Cluster failures by root cause before applying fixes
- **P0 before P1** — Always fix critical issues first
- **P2/P3 are optional** — Only fix if P0/P1 are already resolved
- **Minimal changes** — Fix the issue without rewriting unaffected sections
- **Evidence in tickets** — Reference the evaluation ticket ID for each fix applied
- **Write only to .omb/plans/** — Do not modify any other files
