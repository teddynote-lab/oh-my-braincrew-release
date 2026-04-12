---
name: omb-evaluation-plan
description: "Plan quality evaluation with binary rubric scoring and P0-P3 issue tickets. Evaluates implementation plans against ~44 checklist items across 9 dimensions using evidence-based scoring."
---

# Plan Evaluation (Quantitative)

Evaluate an implementation plan using an evidence-anchored binary (PASS/FAIL) rubric across ~44 checklist items in 9 dimensions. Each verdict requires quoted evidence from the plan document. Produces a quantitative score sheet and prioritized P0-P3 issue tickets.

This skill is loaded by the `plan-evaluator` agent. It is NOT user-invocable.

## Evaluation Workflow

1. **Ingest** — Read the plan document from the provided file path
2. **Classify plan scope** — Determine N/A items using the N/A Decision Tree (below)
3. **Score** — For each applicable item: search for observable markers → quote evidence → render PASS/FAIL
4. **Aggregate** — Compute dimension scores and overall score as pass-rate percentages
5. **Classify** — Map FAIL items to P0-P3 priority levels based on impact
6. **Report** — Output the score sheet + issue tickets with quoted evidence

## Scoring Dimensions

| # | Dimension | Items | Weight | Focus |
|---|-----------|-------|--------|-------|
| 1 | Requirements Clarity | 6 | 15% | User needs captured, scope defined, non-goals stated |
| 2 | Domain Decomposition | 5 | 12% | Tasks split by domain, exact assignment, no cross-domain tasks |
| 3 | Agent Delegation | 5 | 12% | @agent references valid, Skill() calls present, MCP tools listed |
| 4 | Technical Specification | 6 | 15% | Tech stack table complete, file:line refs, architecture decisions |
| 5 | TDD & Verification | 5 | 12% | Test strategy per domain, coverage targets, omb-tdd referenced |
| 6 | Phase Structure | 5 | 10% | Efficient ordering, dependencies explicit, parallelization, [CP] marks |
| 7 | Documentation Plan | 4 | 8% | docs/ update plan, omb-doc referenced, specific paths |
| 8 | Risk Analysis | 4 | 8% | Risks with likelihood/impact, concrete mitigations, user verification items |
| 9 | Completeness | 4 | 8% | All 8 sections present, TODO matches phases, no placeholders |

## Checklist Items

### 1. Requirements Clarity (6 items, 15%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| req.summary | Requirements summary present | Section 1.1 exists with 1-3 sentence summary | PASS: clear problem statement. FAIL: missing or vague "implement feature" |
| req.detailed | Detailed requirements listed | Section 1.2 with bullet list | PASS: specific functional requirements. FAIL: single line or absent |
| req.scope-in | In-scope boundaries defined | "범위 내" section | PASS: explicit list of what WILL be implemented. FAIL: missing |
| req.scope-out | Out-of-scope explicitly stated | "범위 외" section | PASS: explicit non-goals. FAIL: missing (everything seems in scope) |
| req.constraints | Constraints documented | "제약사항" section | PASS: technical or business constraints listed. FAIL: missing |
| req.acceptance | Measurable acceptance criteria | Section 1.4 with checkboxes | PASS: testable criteria (not vague). FAIL: no criteria or untestable |

### 2. Domain Decomposition (5 items, 12%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| domain.single | Each task maps to one domain | Tasks Table "도메인" column | PASS: every task has exactly one domain. FAIL: "fullstack" or dual domains |
| domain.precise | Domains match routing table | Domain values from 01-plan-writing.md | PASS: API/DB/UI/Electron/AI/Infra/Security/Code. FAIL: vague "backend" |
| domain.split | Cross-domain work is split | No single task spans multiple domains | PASS: compound tasks decomposed. FAIL: "Add endpoint with DB model" as one task |
| domain.coverage | All affected domains identified | Compare features to domain assignments | PASS: no domain gaps. FAIL: feature needs DB but no DB tasks |
| domain.granularity | Tasks are appropriately granular | Task descriptions | PASS: 1-4 hour tasks. FAIL: "Build entire auth system" as one task |

### 3. Agent Delegation (5 items, 12%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| agent.assigned | Every task has @agent | Tasks Table "@" column | PASS: all tasks have @agent-name. FAIL: any task missing agent |
| agent.valid | @agent names exist | Cross-reference with .claude/agents/omb/ | PASS: all referenced agents exist. FAIL: invented agent names |
| agent.skill-ref | Skill() references present | Tasks Table "스킬" column | PASS: orchestration skill per task. FAIL: missing Skill() |
| agent.skill-valid | Skill() names exist | Cross-reference with .claude/skills/ | PASS: all referenced skills exist. FAIL: invented skill names |
| agent.mcp-tools | MCP tools listed when needed | Tasks Table "MCP 도구" column | PASS: relevant MCP tools cited or "—". FAIL: column missing |

### 4. Technical Specification (6 items, 15%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| tech.stack-table | Tech stack table present | Section 2 markdown table | PASS: table with 기능/기술 스택/참고 코드/도메인 columns. FAIL: missing |
| tech.file-refs | Reference code with file:line | "참고 코드" column values | PASS: `src/file.py:42` format. FAIL: vague "see backend code" |
| tech.arch-decisions | Architecture decisions documented | Section 2.1 | PASS: decisions with rationale. FAIL: missing or no rationale |
| tech.prior-art | Prior art search documented | Section 2.2 | PASS: what was searched and why adopted/rejected. FAIL: missing |
| tech.dependencies | External dependencies listed | Architecture decisions or constraints | PASS: libraries, services, APIs identified. FAIL: implicit dependencies |
| tech.deliverables | Concrete deliverables per task | Tasks Table "산출물" column | PASS: specific files/artifacts. FAIL: vague "implementation" |

### 5. TDD & Verification (5 items, 12%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| tdd.section | TDD section present | Section 6 exists | PASS: dedicated TDD section. FAIL: no Section 6 |
| tdd.framework | Test frameworks specified | Framework per tech stack | PASS: pytest/vitest per domain. FAIL: generic "write tests" |
| tdd.coverage | Coverage targets stated | Numeric targets | PASS: 85%+ line, 80%+ branch explicitly stated. FAIL: no numbers |
| tdd.commands | Test commands listed | Runnable commands | PASS: `pytest tests/api/ -v` style commands. FAIL: "run tests" |
| tdd.skill-ref | omb-tdd skill referenced | Skill("omb-tdd") in section | PASS: explicit reference. FAIL: missing |

### 6. Phase Structure (5 items, 10%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| phase.ordered | Phases ordered by dependency | Phase sequence | PASS: dependent tasks come after prerequisites. FAIL: circular or wrong order |
| phase.deps-explicit | Dependencies documented | "의존성" column in Tasks Table | PASS: # references or "—". FAIL: column missing or all blank |
| phase.parallel | Parallelizable tasks grouped | Same-phase independent tasks | PASS: independent tasks in same phase. FAIL: sequential when could parallel |
| phase.critical-path | Critical path marked | [CP] markers in TODO checklist | PASS: at least one [CP] mark. FAIL: no critical path identified |
| phase.goals | Each phase has stated goal | "목표:" line per phase | PASS: clear phase objective. FAIL: phase header only |

### 7. Documentation Plan (4 items, 8%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| docs.section | Documentation section present | Section 7 exists | PASS: dedicated section. FAIL: no Section 7 |
| docs.paths | Specific docs/ paths listed | Table with file paths | PASS: `docs/api/auth.md` style paths. FAIL: "update docs" |
| docs.actions | Create/update actions specified | "액션" column | PASS: 생성/수정 per file. FAIL: missing action type |
| docs.skill-ref | omb-doc skill referenced | Skill("omb-doc") in section | PASS: explicit reference. FAIL: missing |

### 8. Risk Analysis (4 items, 8%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| risk.section | Risk section present | Section 8 exists | PASS: dedicated section. FAIL: no Section 8 |
| risk.identified | Risks listed with severity | Risk table | PASS: risks with 가능성/영향도. FAIL: empty or no table |
| risk.mitigations | Concrete mitigations stated | "완화 방안" column | PASS: actionable mitigations. FAIL: vague "be careful" |
| risk.user-verify | User verification items listed | Checklist in Section 8 | PASS: specific items needing user confirmation. FAIL: missing |

### 9. Completeness (4 items, 8%)

| ID | Item | Evidence Required | Observable Markers |
|----|------|-------------------|-------------------|
| complete.all-sections | All 8 sections present | Section headers 1-8 | PASS: all headers exist. FAIL: any section missing |
| complete.todo-match | TODO checklist matches phases | Cross-reference Section 3 vs 4 | PASS: every phase task in checklist. FAIL: mismatch |
| complete.no-placeholders | No placeholder content | Scan for {}, TBD, TODO, ... | PASS: all content filled. FAIL: template placeholders remain |
| complete.metadata | Plan metadata present | Header with date, status, score | PASS: creation date + status. FAIL: missing metadata |

## Evidence-Anchored Scoring Method

Each checklist item is evaluated with mandatory evidence:

1. **Search** — Scan the plan for the observable markers listed in the checklist
2. **Quote** — Quote the specific text found (or state "not found")
3. **Verdict** — Render PASS/FAIL based on the evidence, not impression

- **PASS (1)** — Evidence found that satisfies the criterion
- **FAIL (0)** — No evidence found, or evidence contradicts the criterion
- **N/A** — Not applicable per the N/A Decision Tree (excluded from scoring)

```
dimension_score = (pass_count / applicable_count) * 100%
overall_score   = weighted_average(dimension_scores, weights)
```

### Scoring Consistency Protocol

- **Quote before verdict:** Never render PASS/FAIL without first quoting evidence
- **Atomic evaluation:** Evaluate each criterion independently — one item's result must not influence another
- **Evidence in tickets:** Every issue ticket must include the quoted evidence that triggered the FAIL

## N/A Decision Tree

```
1. Is this a single-domain plan (only one domain involved)?
   Yes → N/A domain.split, domain.coverage, phase.parallel

2. Does the plan involve no external documentation updates?
   Yes → N/A docs.paths, docs.actions (keep docs.section and docs.skill-ref)

3. Is this a documentation-only or config-only plan?
   Yes → N/A tdd.framework, tdd.coverage, tdd.commands (keep tdd.section)

4. Is this a quick fix (< 3 tasks)?
   Yes → N/A phase.parallel, phase.critical-path, risk.section
```

## Priority Classification (P0-P3)

| Priority | Severity | Criteria |
|----------|----------|----------|
| **P0** | Critical | Plan will produce incorrect implementation or miss core requirements |
| **P1** | High | Significant quality degradation or agent routing errors |
| **P2** | Medium | Noticeable gap but plan still executable |
| **P3** | Low | Minor polish; plan works but could be better |

### Priority Mapping

- **P0**: FAIL in `req.summary`, `req.acceptance`, `domain.single`, `agent.assigned`, `agent.valid`, `tech.deliverables`, `complete.all-sections`
- **P1**: FAIL in `req.scope-in`, `req.scope-out`, `domain.precise`, `domain.split`, `agent.skill-ref`, `agent.skill-valid`, `tech.stack-table`, `tech.file-refs`, `tdd.section`, `tdd.coverage`, `phase.ordered`, `phase.deps-explicit`
- **P2**: FAIL in `req.detailed`, `req.constraints`, `domain.coverage`, `domain.granularity`, `agent.mcp-tools`, `tech.arch-decisions`, `tech.prior-art`, `tech.dependencies`, `tdd.framework`, `tdd.commands`, `tdd.skill-ref`, `phase.parallel`, `phase.critical-path`, `phase.goals`, `docs.section`, `docs.paths`, `docs.actions`, `docs.skill-ref`
- **P3**: FAIL in `risk.section`, `risk.identified`, `risk.mitigations`, `risk.user-verify`, `complete.todo-match`, `complete.no-placeholders`, `complete.metadata`

## Output Format

### Section 1: Score Sheet

```
## Plan Evaluation Score Sheet

**Overall Score: XX% (Grade: X)**
**Pass: XX / XX items | Fail: XX | N/A: XX**

| # | Dimension | Pass | Fail | N/A | Score | Weight | Weighted |
|---|-----------|------|------|-----|-------|--------|----------|
| 1 | Requirements Clarity | X | X | X | XX% | 15% | XX% |
| 2 | Domain Decomposition | X | X | X | XX% | 12% | XX% |
| 3 | Agent Delegation | X | X | X | XX% | 12% | XX% |
| 4 | Technical Specification | X | X | X | XX% | 15% | XX% |
| 5 | TDD & Verification | X | X | X | XX% | 12% | XX% |
| 6 | Phase Structure | X | X | X | XX% | 10% | XX% |
| 7 | Documentation Plan | X | X | X | XX% | 8% | XX% |
| 8 | Risk Analysis | X | X | X | XX% | 8% | XX% |
| 9 | Completeness | X | X | X | XX% | 8% | XX% |
| | **Total** | | | | | | **XX%** |
```

### Section 2: Issue Tickets (EP-P0 through EP-P3)

> Ticket format: See `.claude/rules/workflow/09-ticket-schema.md` for canonical schema, field definitions, and prefix conventions.

Each FAIL item produces a ticket with prefix `EP-P{0-3}-{NNN}`. All tickets are created with `Status: OPEN`. Root Cause is optional for plan evaluation tickets.

### Section 3: Summary

```
## Issue Summary

| Priority | Count | Status |
|----------|-------|--------|
| P0 | X | Must fix |
| P1 | X | Should fix |
| P2 | X | Can fix |
| P3 | X | Nice to have |

**Verdict:** PASS | CONDITIONAL PASS | FAIL
```

## Grade Thresholds

| Grade | Score | Condition |
|-------|-------|-----------|
| A | >=90% | AND 0 P0, 0 P1 |
| B | >=80% | AND 0 P0 |
| C | >=65% | AND 0 P0 |
| D | >=50% | — |
| F | <50% | — |
