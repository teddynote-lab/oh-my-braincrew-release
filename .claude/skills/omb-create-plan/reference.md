# Plan Skill Reference

## Approach Format Template

Use this format when presenting approaches in Step 2:

```markdown
### Approach A: [Name]
**Strategy:** [1-2 sentences describing the approach]
**Affected layers:** [Python backend, Node.js, React frontend, Electron, data, infra]
**Pros:**
- [Concrete benefit]
- [Concrete benefit]
**Cons:**
- [Concrete drawback]
- [Concrete drawback]
**Complexity:** [Low / Medium / High] — [agent count estimate]

### Approach B: [Name]
**Strategy:** [1-2 sentences]
**Affected layers:** [layers]
**Pros:** ...
**Cons:** ...
**Complexity:** ...

### Recommendation
[Which approach and why. Reference specific project constraints.]
```

## Approach Evaluation Criteria

When comparing approaches, evaluate each against these dimensions:

| Dimension | Question | Weight |
|-----------|----------|--------|
| Correctness Risk | How likely to introduce bugs? | High |
| Reversibility | Can we undo if it fails? | High |
| Complexity Budget | How many agents/files/layers? | Medium |
| Time-to-Value | How fast to deliver working increment? | Medium |
| Testing Burden | How hard to verify? | Medium |
| TDD Readiness | How testable is this approach? | High |

Score each approach Low/Medium/High per dimension. Prefer the approach that minimizes High scores in high-weight dimensions.

## Explore Agent Prompt Templates

### 1. Structure Explorer
```
Find the file structure, modules, routes, and entry points for: {AREA}

Search for:
- Python: FastAPI route files (@router, @app, APIRouter), Pydantic models, LangGraph nodes
- Node.js: Express/Fastify route handlers, middleware
- React: component exports, page components, layout files
- Electron: main process entry, preload scripts, IPC bridges
- Config: package.json, pyproject.toml, docker-compose.yml

Return: file:line + one-sentence summary for each finding.
Map the dependency graph between found modules.

IMPORTANT: For each relevant function/class found, include:
- The function/method signature (full signature, not just name)
- 3-5 lines of surrounding code showing the context
- Any existing patterns that new code must follow

Maps to plan sections:
- File paths → Tasks table (Deliverable column)
- Module boundaries → Architecture Decisions
- Dependencies → Tasks table (Depends On column)
- Code context → Task detail Implementation sections (insertion points)
```

### 2. Pattern Explorer
```
Find code patterns and conventions for: {AREA}

Use ast_grep_search for semantic patterns:

Python:
- Function signatures: `async def $NAME($PARAMS): $$$`
- Pydantic models: `class $NAME(BaseModel): $$$`
- LangGraph nodes: `def $NAME(state: $STATE_TYPE): $$$`
- Decorated functions: `@$DECORATOR def $NAME($PARAMS): $$$`

TypeScript/React:
- Component exports: `export function $NAME($PROPS) { $$$ }`
- Default exports: `export default function $NAME($PROPS) { $$$ }`
- Hook definitions: `function use$NAME($PARAMS) { $$$ }`
- Express routes: `app.$METHOD($PATH, $HANDLER)`
- Fastify routes: `fastify.$METHOD($PATH, $HANDLER)`

General:
- Class definitions: `class $NAME { $$$ }`
- Try/catch blocks: `try { $$$ } catch ($ERR) { $$$ }`

Use Grep for textual patterns:
- Import conventions (absolute vs relative, aliases)
- Error handling patterns (try/catch, HTTPException, error boundaries)
- Naming conventions (camelCase, snake_case usage)
- Test patterns (describe/it, pytest fixtures)

Return: pattern + example file:line for each finding.

Maps to plan sections:
- Conventions → Tasks table (implementation constraints)
- Patterns → Architecture Decisions (follow or break)
- Naming → Code style notes in plan Context
```

### 3. Reference Explorer
```
Search reference projects for patterns related to: {AREA}

Reference project paths (from .omb/config.json):
{REFERENCE_PATHS}

Look for:
- Similar features or implementations
- Agent/skill/hook patterns that solve comparable problems
- Architecture decisions (CLAUDE.md, ADRs, README)
- Test strategies for similar components

Return: project + file:line + one-sentence summary for each relevant finding.

Maps to plan sections:
- Patterns → Architecture Decisions (prior art)
- Test strategies → Verification Criteria
```

### 4. Test Explorer
```
Find test infrastructure and patterns for: {AREA}

Search for:
- Python: pytest conftest.py, fixtures, test files matching test_*.py or *_test.py
- TypeScript: vitest config, test files matching *.test.ts or *.spec.ts
- Node.js: jest config, test utilities, mock patterns
- Integration: testcontainers, docker-compose.test.yml, API test clients

Return: file:line + what the test covers + framework used.
Note any gaps in test coverage for the affected area.

Maps to plan sections:
- Test files → Tasks table (test task deliverables)
- Coverage gaps → Risks table
- Fixtures → Tasks table (dependencies)

Additionally report:
- Existing coverage percentage per module (if coverage reports exist)
- Test naming conventions used in the project
- Fixture patterns available for reuse in new tests
- Integration test boundaries (what is mocked vs real)

Maps to NEW plan sections:
- Coverage data → TDD Implementation Plan (coverage target baseline)
- Test patterns → TDD Implementation Plan (test naming, fixture reuse)
- Gaps → TDD Implementation Plan (test cases for uncovered areas)
```

### 5. Schema/API Explorer (conditional)
```
Find data models and API contracts for: {AREA}

Search for:
- Postgres: SQLAlchemy models, Alembic migrations, schema definitions
- Redis: key patterns (GET/SET/HSET calls), TTL configurations, pub/sub channels
- FastAPI: Pydantic request/response models, OpenAPI schema annotations
- TypeScript: interface/type definitions, zod schemas, API client types
- GraphQL: schema definitions, resolvers (if applicable)

Return: file:line + model/type name + field summary.
Map relationships between models (foreign keys, references).

Maps to plan sections:
- Models → Tasks table (schema change deliverables)
- Relationships → Tasks table (Depends On column)
- API contracts → Verification Criteria
```

### 6. Prior Plan Explorer (conditional)
```
Search .omb/plans/ for existing plans related to: {AREA}

Look for:
- Architecture decisions that constrain the current task
- Prior risk assessments for the same stack layers
- Dependency patterns from previous plans
- Active plans that may conflict with or overlap the current scope

Return: plan filename + relevant decision + whether it applies or is superseded.

Maps to plan sections:
- Architecture Decisions (inherited constraints)
- Risks table (known risks from prior plans)
```

## Stack-Specific Planning Heuristics

When a plan touches these stack layers, auto-include the corresponding task:

| Stack Layer | Auto-Include Task | Why |
|-------------|-------------------|-----|
| Postgres schema | Rollback migration task | Schema changes need explicit rollback |
| Redis keys | TTL audit task | Keys without TTL cause memory leaks |
| FastAPI routes | OpenAPI spec update | Contract docs must match implementation |
| React components | Component test task | UI changes without tests create regressions |
| Electron IPC | Security review task | IPC channels are RCE vectors |
| LangGraph nodes | State schema validation | Node changes can break checkpoint compat |
| Alembic migrations | DB→API→frontend ordering | Wrong order breaks running deployments |

## Plan Output Template

### STANDARD Template

```markdown
## Plan: [Title]

**Tracking:** [BCRW-PLAN-NNNNNN]
**Tier:** STANDARD

### Context
[What we're doing and why — 2-3 sentences]

### Architecture Decisions
- [Decision]: [Rationale]

### Tasks Summary
| # | Task | Agent | Model | Depends On | Deliverable |
|---|------|-------|-------|------------|-------------|
| 1 | ... | executor | sonnet | — | path/to/file.ts |
| 2 | ... | db-specialist | sonnet | 1 | migrations/001_xxx.py |

### Parallelization
[Which tasks can run concurrently. e.g., "Tasks 1-3 are independent and can run in parallel. Task 4 depends on 1 and 2."]

---

## Task 1: [Task Title]

**File:** `[absolute or relative path to the primary file]`

**Agent:** [agent-name] ([model])

**Problem:** [Specific description of what is wrong or missing. Include line numbers, function names, and the observable symptom. Reference specific code constructs.]

**Rules:** [Which `.claude/rules/` files apply to this task. e.g., `code-conventions.md` (naming), `backend/fastapi-patterns.md` (route structure). Only list rules that constrain implementation decisions.]

**Critical Fix:** [One-sentence summary of the essential change. What MUST happen for this task to succeed.]

**Implementation:**
[Code snippets showing the exact changes. Use diff-style or annotated code blocks. Mark new code with `# [NEW]` or `// [NEW]` comments. Show enough surrounding context for the executor to locate the insertion point.]

```python
# path/to/file.py — function_name() modification
@router.post("/endpoint", response_model=ResponseModel)
async def function_name(request: RequestModel, current_user: User):
    # existing logic...

    # [NEW] Add validation before processing
    validated = await validate_input(request.field)
    if not validated:
        raise HTTPException(status_code=422, detail={"code": "INVALID", "message": "..."})

    result = await process(validated)
    return result
```

**Key Design Decisions:**
- [Decision 1]: [Why this approach over alternatives]
- [Decision 2]: [Why this approach over alternatives]

**Test Strategy:**
| Test Name | Type | Framework | Key Assertions |
|-----------|------|-----------|----------------|
| test_[name]_happy_path | unit | pytest | [expected behavior] |
| test_[name]_invalid_input | unit | pytest | [raises specific error] |
| test_[name]_edge_case | unit | pytest | [boundary condition] |

---

## Task 2: [Task Title]

[Same structure as Task 1...]

---

[Repeat for each task...]

---

## Edge Cases & Solutions

| Edge Case | Solution |
|-----------|----------|
| [Scenario 1] | [How the implementation handles it — reference which Task covers it] |
| [Scenario 2] | [How the implementation handles it] |

---

## Critical Files

| File | Change | Layer |
|------|--------|-------|
| `path/to/new-file.py` | **NEW**: [purpose] | Backend |
| `path/to/existing-file.tsx` | [what changes] | Frontend |
| `path/to/config.json` | [what changes] | Config |

**Unchanged (reuse only):** `[list files that are read/imported but not modified]`

---

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|

---

## Verification

[Numbered list of testable scenarios. Each item describes a user action or system state and the expected outcome.]

1. **[Scenario name]:** [action] → [expected result]
2. **[Scenario name]:** [action] → [expected result]
3. **TypeScript build:** `tsc --noEmit` — zero errors
4. **Python tests:** `pytest -v tests/` — all pass
5. **Lint:** `ruff check` / `eslint .` — no new warnings

---

## Test Cases (Overall)

**Coverage Target:** [see domain table below — state target and any exclusions]

| Domain | Target | Rationale |
|--------|--------|-----------|
| Python backend (FastAPI, Node.js) | 85%+ | Full control of business logic |
| React component logic | 70%+ | Excluding render/CSS behavior |
| Electron IPC | 60%+ | Excluding native process boundaries |
| LangGraph workflows | 75%+ | Excluding checkpoint replay internals |

**All Test Cases:**
| Task # | Test Name | Type | Target Module | Framework | Key Assertions |
|--------|-----------|------|---------------|-----------|----------------|
| 1 | test_[name]_happy_path | unit | path/to/module | pytest | [expected behavior] |
| 1 | test_[name]_invalid_input | unit | path/to/module | pytest | [raises ValueError] |
| 2 | test_[name]_render | unit | path/to/component | vitest | [renders correctly] |

- Type: `unit | integration | e2e | contract`
- Framework: `pytest` (Python), `vitest` (TS/React), `jest` (Node.js)
- Entries may use "TBD — [rationale]" for Test Name and Key Assertions at plan time; these MUST be resolved before execute STEP 0 validation passes
- Only implementation tasks need test cases (agent: executor, api-specialist, db-specialist, frontend-engineer, langgraph-engineer, async-coder). Tasks with agent doc-writer, git-master, or infra-engineer (config-only) are exempt.

**Test-First Execution Order:**
- Phase 1: Scaffolding — types, interfaces, contracts (no tests yet)
- Phase 2: Tests — write all tests from the table above (red phase, all should fail)
- Phase 3: Implementation — make tests pass task by task (green phase)
- Phase 4: Integration — cross-layer tests, full suite run
```

### TRIVIAL Template (inline, no file)

```markdown
- **What**: [1 sentence]
- **File**: [single file path]
- **Agent**: [executor/specialist]
- **Verify**: [single test command]
```

### EMERGENCY Template (minimal file)

```markdown
## Plan: [HOTFIX] [Title]

**Tier:** EMERGENCY

### What Broke
[1-2 sentences]

### Fix
| # | Task | Agent | Deliverable |
|---|------|-------|-------------|

### Verify
- [ ] [Single critical verification command]

### Skipped
plan,review,docs | hotfix urgency
```

## Critic Handoff Format

After generating a plan, output this self-assessment to facilitate critic review:

```markdown
### Self-Assessment
| Aspect | Confidence | Weakest Assumption |
|--------|-----------|-------------------|
| Dependencies | high/medium/low | [What could be wrong about task ordering] |
| Agent assignments | high/medium/low | [Which assignment is least certain] |
| Code specificity | high/medium/low | [Which task has the vaguest implementation snippets] |
| Risk coverage | high/medium/low | [What risk might be missing] |
| Verification | high/medium/low | [Which criterion is hardest to run] |
| TDD coverage | high/medium/low | [Which task has weakest test case design] |
```

The critic should focus on low-confidence aspects first. This format aligns with the review checklist in `.claude/rules/02-review-plan.md`.
