# Create PR Reference

## 1. PR Template

### STANDARD Tier (planned work)

```markdown
## {PR_TITLE}

<!-- oh-my-braincrew | PR: {BCRW-PR-NNNNNN} | Plan: {BCRW-PLAN-NNNNNN} -->

### Tracking

| Code | Value |
|------|-------|
| PR | `{BCRW-PR-NNNNNN}` |
| Plan | `{BCRW-PLAN-NNNNNN}` |
| Plan file | `{.omb/plans/<session_id>.md}` |
| Branch | `{feature/slug}` → `{main}` |

### Category
<!-- Auto-detected, check all that apply -->
- [ ] `backend` — FastAPI, Node.js, API routes
- [ ] `frontend` — React, Vite, Tailwind CSS
- [ ] `database` — Postgres, Redis, migrations
- [ ] `security` — Auth, middleware, ACLs, RLS
- [ ] `infra` — Docker, CI/CD, monitoring, Slack, pipelines
- [ ] `ai-ml` — LangChain, LangGraph, RAG, embeddings
- [ ] `electron` — Desktop, IPC, packaging
- [ ] `performance` — Optimization, caching, profiling
- [ ] `docs` — Documentation only
- [ ] `testing` — Test infrastructure, coverage
- [ ] `config` — Configuration, env vars

---

### Summary
<!-- What this PR does — 2-3 sentences derived from plan Context -->
{what the PR accomplishes and its scope}

### Motivation
<!-- Why this work was needed — business impact, user pain, technical risk -->
{why this change matters — from plan Context section}

### Approach
<!-- Architectural approach, key decisions, rejected alternatives -->
{how the problem was solved — from plan Architecture Decisions}

---

### Changes
<!-- Only include subsections for checked categories. Omit empty subsections. -->

#### Backend
- `{file path}`: {what changed and why}

#### Frontend
- `{file path}`: {what changed and why}

#### Database
- `{file path}`: {what changed and why}

#### AI/ML
- `{file path}`: {what changed and why}

#### Electron
- `{file path}`: {what changed and why}

#### Infra
- `{file path}`: {what changed and why}

### Plan Tasks
<!-- Map tasks from the original plan to this PR. Shows traceability. -->

| # | Task | Deliverable | Status |
|---|------|-------------|--------|
| {N} | {task from plan} | `{deliverable path}` | {Done / Partial / Skipped} |

---

### Test Plan

| Tool | Target | Result |
|------|--------|--------|
| `pytest` | {test files/suites} | {pass / fail / not run} |
| `pyright` | zero type errors | {pass / fail / not run} |
| `vitest` | {test files/suites} | {pass / fail / not run} |
| `tsc --noEmit` | zero type errors | {pass / fail / not run} |
| Manual | {what was checked} | {pass / fail / not run} |

<details><summary>Verification Evidence</summary>

| Field | Value |
|-------|-------|
| Status | `{PASS / FAIL / PARTIAL / NOT RUN}` |
| Record | `{.omb/verifications/filename.md}` |

</details>

### Documentation

| Update | Status |
|--------|--------|
| README | {Updated / Not needed} |
| ADR | {`docs/adr/NNN-title.md` / Not needed} |
| API docs | {Updated / Not needed} |
| Migration guide | {Created / Not needed} |

<details><summary>Document Record</summary>

| Field | Value |
|-------|-------|
| Status | `{COMPLETE / PARTIAL / NOT RUN}` |
| Record | `{.omb/documents/filename.md}` |

</details>

### Breaking Changes
<!-- None / List each breaking change with migration steps -->
None

---

### Checklist

- [ ] All tests pass (pytest + vitest + tsc + pyright)
- [ ] No hardcoded secrets or credentials
- [ ] Documentation updated (Step 5)
- [ ] Conventional commits with `Co-Authored-By: Braincrew(dev@brain-crew.com)` trailer
- [ ] Branch rebased on latest main
- [ ] No unrelated changes included
- [ ] Verification evidence collected (Step 4)

### Additional Context
<!-- Screenshots, architecture diagrams (Mermaid), performance benchmarks, related PRs -->
```

### LIGHT Tier (trivial/unplanned work)

```markdown
## {PR_TITLE}

<!-- oh-my-braincrew | PR: {BCRW-PR-NNNNNN} | Ad-hoc -->

### Tracking

| Code | Value |
|------|-------|
| PR | `{BCRW-PR-NNNNNN}` |
| Branch | `{branch}` → `{main}` |

### Category
- [ ] {auto-detected categories}

### Changes
- {bullet list of changes}

### Test Plan
- [ ] Tests pass
- [ ] `tsc --noEmit`: zero errors

### Breaking Changes
None
```

---

## 2. Git-Master Agent Prompt

Use this prompt template when delegating PR creation to the `git-master` agent in STEP 8:

```
You are the git-master agent creating a PR for tracking code {TRACKING_CODE}.

## Context
- Branch: {BRANCH_NAME} (already created and checked out)
- Base: {BASE_BRANCH}
- PR code: {PR_CODE}
- Plan code: {PLAN_CODE}
- Plan filename: {PLAN_FILENAME}
- Plan spec code: {PLAN_SPEC_CODE}
- PR tier: {TIER} (STANDARD or LIGHT)

## Task
1. Stage pipeline artifact directories and tracked modifications:
   ```bash
   git add .omb/plans/ .claude/plans/ 2>/dev/null || true
   git add .omb/verifications/ .omb/documents/ .omb/executions/ .omb/prs/ .omb/reviews/ 2>/dev/null || true
   git add -u
   ```
2. Ensure all staged changes are committed with conventional commits and `Co-Authored-By: Braincrew(dev@brain-crew.com)` trailer
3. Check for existing PR on this branch: `gh pr list --head {BRANCH_NAME} --json number,url`
   - If exists: report the existing PR URL and skip creation
4. Push branch to remote: `git push -u origin {BRANCH_NAME}`
5. Create PR:
   ```bash
   gh pr create --title "{PR_TITLE}" --base {BASE_BRANCH} --body "$(cat <<'EOF'
   {PR_BODY_CONTENT}
   EOF
   )"
   ```
6. Report the PR URL

## PR Title
{PR_TITLE}

## PR Body
{PR_BODY_CONTENT}

## Fallback
If `gh` is not available or not authenticated:
1. Write the PR body to `.omb/prs/{PR_CODE}-body.md`
2. Report: "PR body saved to .omb/prs/{PR_CODE}-body.md — create the PR manually on GitHub"

Report STATUS: DONE with the PR URL, or DONE_WITH_CONCERNS if fallback was used.
```

---

## 3. Category Detection Rules

The 11 categories and their file pattern triggers:

| Category | File Patterns | Keywords |
|----------|--------------|----------|
| `backend` | `*.py`, `*.ts` (non-frontend) | FastAPI, Express, Fastify, route, endpoint, API |
| `frontend` | `*.tsx`, `*.jsx`, `*.css` | component, hook, Tailwind, Vite, React |
| `database` | `*.sql`, `*migration*`, `*alembic*` | schema, model, Redis, cache, Postgres |
| `security` | `*auth*`, `*security*`, `*middleware/jwt*` | ACL, RLS, permission, token, OWASP |
| `infra` | `*docker*`, `*.github/*`, `*ci/*` | deploy, monitoring, Slack, nginx, pipeline |
| `ai-ml` | `*langchain*`, `*langgraph*`, `*rag*` | embedding, LLM, agent, prompt, RAG |
| `electron` | `*electron*`, `*preload*`, `*ipc*` | main-process, renderer, contextBridge |
| `performance` | `*perf*`, `*benchmark*`, `*profil*` | optimize, cache, leak, memory |
| `docs` | `*.md`, `*docs/*`, `*README*` | ADR, changelog, guide |
| `testing` | `*test*`, `*spec.*`, `*__tests__*` | fixture, conftest, coverage |
| `config` | `*.env*`, `*config*`, `*settings*` | tsconfig, pyproject, package.json |

Priority order for primary category: security > backend > frontend > database > ai-ml > electron > infra > performance > testing > config > docs.

---

## 4. PR Record Schema

### State JSON

Written to `.omb/prs/state/{plan-filename}.json` (STANDARD) or `.omb/prs/state/{pr-code}.json` (LIGHT):

```json
{
  "prCode": "BCRW-PR-000001",
  "planCode": "BCRW-PLAN-000042",
  "planFile": ".omb/plans/202603211045-abc123.md",
  "tier": "STANDARD",
  "branch": "feature/add-auth-middleware",
  "baseBranch": "main",
  "prUrl": "https://github.com/org/repo/pull/42",
  "prBodyFile": null,
  "categories": ["backend", "security"],
  "primaryCategory": "security",
  "verificationStatus": "PASS",
  "documentationStatus": "COMPLETE",
  "checklistResults": {
    "uncommitted_changes": "pass",
    "branch_check": "pass",
    "conventional_commits": "pass",
    "no_secrets": "pass",
    "gh_auth": "pass",
    "co_authored_trailer": "pass"
  },
  "changeSummary": {
    "files_changed": 12,
    "insertions": 340,
    "deletions": 45
  },
  "createdAt": "2026-03-21T10:30:00.000Z"
}
```

---

## 5. PR Record Template

Written to `.omb/prs/{plan-filename}.md` (STANDARD) or `.omb/prs/{pr-code}.md` (LIGHT):

```markdown
# PR Record: {PR_CODE}

## Metadata

| Field | Value |
|-------|-------|
| PR Code | `{PR_CODE}` |
| Plan Code | `{PLAN_CODE}` |
| Plan | `{PLAN_FILE}` |
| Tier | {TIER} |
| Branch | `{BRANCH}` → `{BASE_BRANCH}` |
| PR URL | {PR_URL or "N/A — saved as markdown"} |
| Created | {ISO_TIMESTAMP} |

## Categories

{CATEGORY_LIST}

## Change Summary

| Metric | Value |
|--------|-------|
| Files changed | {N} |
| Insertions | {N} |
| Deletions | {N} |

## Upstream Records

| Step | Status | Record |
|------|--------|--------|
| Execution | {STATUS} | `{EXECUTION_LOG_PATH}` |
| Verification | {STATUS} | `{VERIFICATION_RECORD_PATH}` |
| Documentation | {STATUS} | `{DOCUMENT_RECORD_PATH}` |

## Checklist Results

| Check | Status | Detail |
|-------|--------|--------|
{CHECKLIST_ROWS}

## PR Body

<details><summary>Full PR body</summary>

{PR_BODY_CONTENT}

</details>
```

---

## 6. Checklist Validation

The `validate-pr-checklist.sh` script checks these items:

| Check | Pass | Warn | Fail |
|-------|------|------|------|
| `uncommitted_changes` | Working tree clean | N uncommitted files | — |
| `branch_check` | On feature branch | On main/master | — |
| `conventional_commits` | All commits match `type(scope):` | Some non-conventional | — |
| `no_secrets` | No patterns found | — | Secret patterns detected |
| `gh_auth` | gh authenticated | gh missing or unauthenticated | — |
| `co_authored_trailer` | Trailer present in last commit | Trailer missing | — |

Checklist failures:
- `fail` status on `no_secrets` → block PR creation, ask user to review
- `warn` status on any check → proceed with warning in PR record
- `warn` on `gh_auth` → use markdown file fallback instead of `gh pr create`
