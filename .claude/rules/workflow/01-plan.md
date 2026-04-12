---
description: Plan structure requirements, writing conventions, Korean template, and agent delegation notation
paths: ["*.md", ".omb/plans/*.md"]
---

# Plan Writing Rules

Defines the structure, language, notation, and quality gates for implementation plans produced by `omb-plan`.

## Workflow Overview

```
Skill("omb-plan") orchestrates:
  1. omb-explore (parallel domain explorers)
  2. @plan-writer (initial draft → .omb/plans/)
  3. @plan-evaluator (rubric scoring via omb-evaluation-plan)
  4. @plan-improver (fix issues via omb-improve-plan)
  5. Loop 3-4 up to 3 iterations until PASS
```

## File Naming Convention

```
.omb/plans/YYYY-MM-DD-kebab-case-name.md
```

- Date is the **creation date** (use today's date)
- Name is a short English kebab-case description (2-5 words)
- Examples:
  - `.omb/plans/2026-04-11-user-auth-flow.md`
  - `.omb/plans/2026-04-11-dashboard-redesign.md`

## Language Rule

Plan documents are written in **Korean** (user-facing output). The following remain in **English**:

- File paths and code references (`src/api/routes.py:42`)
- Agent names (`@api-design`, `@db-implement`)
- Skill invocations (`Skill("omb-tdd")`)
- MCP tool references (`mcp__server__tool`)
- Technical terms may use English with Korean explanation: `ISR(Incremental Static Regeneration)`

## Plan Structure (8 Sections)

Every plan document MUST include these sections in order:

### Section 1: 사용자 요구사항
- **1.1 요구사항 요약** — Problem statement in 1-3 sentences
- **1.2 상세 요구사항** — Specific functional requirements (bullet list)
- **1.3 범위 및 제약사항** — In-scope, out-of-scope, constraints
- **1.4 수용 기준** — Measurable acceptance criteria (checkboxes)

### Section 2: 기능 정의 및 기술 분석
- Tech stack table: 기능 | 기술 스택 | 참고 코드 (`file:line`) | 도메인 | 비고
- **2.1 아키텍처 결정 사항** — Key decisions with rationale
- **2.2 사전 조사 (Prior Art)** — What was searched (GitHub, npm, PyPI, Context7) and why adopted/rejected

### Section 3: TODO 체크리스트
- Ordered by implementation sequence (dependencies first)
- Format: `- [ ] #{n} [CP] {task} → @{agent} | Skill("{skill}")`
- `[CP]` marks critical path tasks
- Includes ALL tasks from all phases

### Section 4: 구현 계획 상세
- Phased breakdown ordered for efficiency
- Per phase: 목표 + Tasks Table (# | 태스크 | 에이전트 | 스킬 | MCP 도구 | 의존성 | 산출물) + 구현 참고사항

### Section 5: 아키텍처 다이어그램 (optional)
- Include when 3+ components interact
- Use Skill("omb-mermaid")

### Section 6: TDD 검증 계획
- Test frameworks per domain (pytest / vitest)
- Coverage targets: 85%+ line, 80%+ branch (critical: 95%+)
- Specific test commands to run
- Reference Skill("omb-tdd")

### Section 7: 문서 업데이트 계획
- Table: 문서 경로 | 액션(생성/수정) | 내용 | 담당(@doc-writer)
- Reference Skill("omb-doc")

### Section 8: 리스크 및 확인 사항
- Risk table: 리스크 | 가능성 | 영향도 | 완화 방안
- User verification checklist for unverified assumptions

## Agent Delegation Notation

### @agent-name

References a sub-agent in `.claude/agents/omb/`. The `@` prefix signals delegation via `Agent()`.

```markdown
@api-design → API endpoint 설계
@db-implement → SQLAlchemy 모델 구현
@code-test → 테스트 파일 작성
```

### Skill("skill-name")

References a skill in `.claude/skills/`.

```markdown
Skill("omb-tdd") → TDD 사이클 강제
Skill("omb-mermaid") → 아키텍처 다이어그램 생성
Skill("omb-doc") → 문서 업데이트
```

### Rules

- Every task MUST have at least one `@agent` assignment
- `@agent` references MUST match actual agent file names in `.claude/agents/omb/`
- `Skill("name")` references MUST match actual skill names in `.claude/skills/`
- Do NOT invent agent or skill names — verify they exist

## Domain Mapping Table

Each task maps to **exactly one domain**. If a task spans two domains, split it.

| Domain | Design Agent | Implement Agent | Explorer | Orchestration Skill |
|--------|-------------|----------------|----------|-------------------|
| API/Backend | @api-design | @api-implement | @api-explorer | Skill("omb-orch-api") |
| Database | @db-design | @db-implement | @db-explorer | Skill("omb-orch-db") |
| UI/Frontend | @ui-design | @ui-implement | @ui-explorer | Skill("omb-orch-ui") |
| Electron | @electron-design | @electron-implement | @electron-explorer | Skill("omb-orch-electron") |
| AI/ML | @ai-design | @ai-implement | @ai-explorer | Skill("omb-orch-ai") |
| Infrastructure | @infra-design | @infra-implement | @infra-explorer | Skill("omb-orch-infra") |
| Security | @security-audit | @security-implement | — | Skill("omb-orch-security") |
| Code Quality | @code-review | @code-test | — | Skill("omb-orch-code") |
| General | — | — | @general-explorer | — |
| Documentation | — | @doc-writer | @doc-explorer | — |

## Efficiency Ordering Rules

1. Independent tasks within a phase CAN run concurrently
2. Dependencies between phases MUST be explicit (`Depends-on` column)
3. Critical path tasks marked with `[CP]`
4. Group parallelizable tasks into the same phase
5. Never create a phase with a single trivial task — merge with adjacent phase

## Quality Gate

Plans are evaluated by `@plan-evaluator` using `omb-evaluation-plan` rubric (~44 items, 9 dimensions):

| Verdict | Condition | Action |
|---------|-----------|--------|
| **PASS** | 0 P0 + 0 P1 + score ≥80% | Deliver plan |
| **CONDITIONAL PASS** | 0 P0 + 0 P1 + score 65-79% | Deliver with P2/P3 notes |
| **FAIL** | P0 or P1 remain | Trigger @plan-improver, re-evaluate (max 3 iterations) |

## Plan Document Template (Korean)

```markdown
# 구현 계획: {제목}

> 생성일: YYYY-MM-DD
> 상태: 초안 | 검토중 | 승인됨
> 평가 점수: XX% (Grade X)

## 1. 사용자 요구사항

### 1.1 요구사항 요약
{사용자가 요청한 내용 1-3문장}

### 1.2 상세 요구사항
- {기능 요구사항 1}
- {기능 요구사항 2}

### 1.3 범위 및 제약사항
- **범위 내**: {구현할 것}
- **범위 외**: {구현하지 않을 것}
- **제약사항**: {기술적/비즈니스적 제약}

### 1.4 수용 기준
- [ ] {측정 가능한 수용 기준 1}
- [ ] {측정 가능한 수용 기준 2}

## 2. 기능 정의 및 기술 분석

| 기능 | 기술 스택 | 참고 코드 | 도메인 | 비고 |
|------|-----------|-----------|--------|------|
| {기능명} | {프레임워크/라이브러리} | `file:line` | {API/DB/UI/...} | {참고사항} |

### 2.1 아키텍처 결정 사항
- {결정 1}: {근거}
- {결정 2}: {근거}

### 2.2 사전 조사 (Prior Art)
- 검색한 내용: {GitHub, npm, PyPI, Context7}
- 기존 솔루션: {채택/기각 사유}

## 3. TODO 체크리스트

{구현 순서대로 정렬. 모든 Phase의 태스크를 포함.}

- [ ] #1 [CP] {태스크} → @{agent} | Skill("{skill}")
- [ ] #2 {태스크} → @{agent} | Skill("{skill}")
- ...

## 4. 구현 계획 상세

### Phase 1: {Phase 제목}

**목표:** {이 Phase의 목표}

| # | 태스크 | 에이전트 | 스킬 | MCP 도구 | 의존성 | 산출물 |
|---|--------|---------|------|----------|--------|--------|
| 1 | {태스크} | @{agent} | Skill("{skill}") | {MCP tool or —} | — | {파일/결과물} |

**구현 참고사항:**
- {구현시 주의할 점}

### Phase 2: {Phase 제목}
...

## 5. 아키텍처 다이어그램

{3개 이상 컴포넌트가 상호작용할 때 포함. Skill("omb-mermaid") 활용.}

## 6. TDD 검증 계획

### 테스트 전략
- **프레임워크**: {pytest / vitest / ...}
- **커버리지 목표**: 라인 85%+, 브랜치 80%+
- **크리티컬 패스**: {95%+ 필요한 영역}

### 도메인별 테스트 계획

| 도메인 | 테스트 유형 | 명령어 | 대상 파일 |
|--------|-----------|--------|-----------|
| API | 통합 테스트 | `pytest tests/api/ -v` | tests/api/test_*.py |
| UI | 컴포넌트 테스트 | `npx vitest run` | src/**/*.test.tsx |

Skill("omb-tdd") 로 TDD 사이클(RED-GREEN-IMPROVE) 강제.

## 7. 문서 업데이트 계획

| 문서 경로 | 액션 | 내용 | 담당 |
|-----------|------|------|------|
| docs/{category}/{file}.md | 생성/수정 | {내용} | @doc-writer |

Skill("omb-doc") 로 문서 작성 가이드라인 적용.

## 8. 리스크 및 확인 사항

### 리스크

| 리스크 | 가능성 | 영향도 | 완화 방안 |
|--------|--------|--------|-----------|
| {리스크} | 높음/중간/낮음 | 높음/중간/낮음 | {구체적 완화 방안} |

### 사용자 확인 필요 사항
- [ ] {미검증 가정 또는 확인 필요 항목}
```
