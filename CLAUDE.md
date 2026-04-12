<!-- omb:setup v1 | 2026-04-11 -->

# oh-my-braincrew (omb)

Multi-domain development harness for Claude Code. Orchestrates specialized sub-agents across Python/FastAPI, React/TypeScript, Electron, LangGraph, Postgres/Redis, Docker/GHA/K8s/Terraform.

## HARD Rules

1. **English only** — All prompts, rules, skills, hooks, code comments, commit messages, and agent output MUST be in English.
2. **No sub-agent spawning from sub-agents** — Only the main session spawns agents via `Agent()`. Sub-agents cannot call Agent().
3. **Result envelope required** — Every sub-agent MUST end with an `<omb>STATUS</omb>` tag + `result` envelope (see `.claude/rules/output-contract.md`). Only 3 statuses: DONE, RETRY, BLOCKED.
4. **Scope guard** — Implement agents MUST only change what the design specifies. No unsolicited refactoring, no "improvements" beyond scope.
5. **Secrets in env vars** — Never hardcode secrets, API keys, or credentials in code.
6. **Input validation at boundaries** — All system boundaries (API endpoints, IPC handlers, CLI args) must validate input.

## Domain Routing

Route tasks to the correct domain based on what the user is working on:

| Signal | Domain | Orchestration Skill |
|--------|--------|-------------------|
| FastAPI, endpoints, Pydantic, middleware, REST, Express, Fastify | API | `omb-orch-api` |
| Postgres, SQLAlchemy, Alembic, migrations, Redis, queries, schema | DB | `omb-orch-db` |
| React, components, hooks, Tailwind, Vite, frontend, CSS | UI | `omb-orch-ui` |
| Electron, IPC, preload, BrowserWindow, desktop | Electron | `omb-orch-electron` |
| LangGraph, LangChain, agents, prompts, RAG, workflows | AI | `omb-orch-ai` |
| Docker, GHA, K8s, Terraform, CI/CD, deploy, infra | Infra | `omb-orch-infra` |
| Auth, OWASP, secrets, vulnerabilities, security audit | Security | `omb-orch-security` |
| Code review, debugging, testing, linting, refactoring | Code | `omb-orch-code` |
| Codebase exploration, "where is X?", "find all Y" | Core | `omb-orch-core` |
| settings.json, CLAUDE.md, hooks, skills, agents, rules, permissions, MCP, harness config | Harness | `omb-orch-harness` |

## Orchestration Model

```
User request
  ↓
CLAUDE.md (main session) — identify domain
  ↓
Skill("omb-orch-{domain}") — loads orchestration guide into main session
  ↓
Main session spawns sub-agents in sequence via Agent():
  {domain}-design → core-critique → {domain}-implement → {domain}-verify
```

### Status Tags
Agents signal orchestration flow with exactly 3 statuses:
- `<omb>DONE</omb>` — proceed to next step (domain-specific verdict in `verdict:` field)
- `<omb>RETRY</omb>` — retry with feedback (critique rejection, verification failure)
- `<omb>BLOCKED</omb>` — escalate to user (missing context, unresolvable dependency)

### Retry Policy
- Design retries after critique `<omb>RETRY</omb>`: max 2
- Implement retries after verify `<omb>RETRY</omb>`: spawn `code-debug` first, then retry — max 3
- After max retries: ask the user for guidance

### Context Passing
Pass each agent's result summary to the next agent. Include:
- Original task description
- Design decisions and constraints
- Critique concerns (if any)
- Changed files list (for verify)

## Sub-Agent Inventory

### Read-Only Agents (permissionMode: default, disallowedTools: Edit, Write)
| Agent | Model | Purpose |
|-------|-------|---------|
| core-explore | haiku | Fast codebase discovery — files, symbols, dependencies |
| core-critique | opus | Pre-mortem analysis, assumption verification |
| api-design | sonnet | API contract and endpoint design |
| db-design | sonnet | Schema, migration, and query design |
| ui-design | sonnet | Component tree, hook API, layout design |
| electron-design | sonnet | IPC protocol, window, security boundary design |
| ai-design | sonnet | LangGraph workflow and prompt chain design |
| infra-design | sonnet | Docker, CI/CD, K8s, Terraform design |
| code-review | sonnet | Code change review for correctness and security |
| code-debug | sonnet | Root cause diagnosis for failures |
| security-audit | sonnet | OWASP audit, auth flow, secret exposure |
| infra-critique | sonnet | Infra design review for security and cost |
| infra-k8s | sonnet | K8s manifest analysis |
| infra-cloud | sonnet | Cloud architecture review |
| ops-leak-audit | sonnet | Secret and credential leak detection |
| harness-explorer | sonnet | Harness configuration discovery and cataloging |
| harness-design | sonnet | Harness configuration design (agents, skills, hooks, rules) |
| harness-verify | sonnet | Harness configuration verification and quality gate |

### Write Agents (permissionMode: acceptEdits)
| Agent | Model | Purpose |
|-------|-------|---------|
| api-implement | sonnet | FastAPI/Express endpoint implementation |
| db-implement | sonnet | SQLAlchemy models, Alembic migrations, Redis |
| ui-implement | sonnet | React components, hooks, Tailwind |
| electron-implement | sonnet | Electron main/renderer, IPC handlers |
| ai-implement | sonnet | LangGraph nodes, tools, prompt chains |
| infra-implement | sonnet | Dockerfiles, GHA workflows, K8s, Terraform |
| security-implement | sonnet | Auth middleware, RBAC, input sanitization |
| code-test | sonnet | Test file creation (pytest, vitest) |
| doc-writer | sonnet | Documentation writing and updates |
| harness-prompt-engineer | sonnet | Review and improve prompts in .claude/ harness .md files |
| harness-implement | sonnet | Harness configuration implementation (agents, skills, hooks, rules, settings) |
| ai-prompt-engineer | sonnet | Review and improve prompts in AI service Python code |

### Utility Agents
| Agent | Model | Purpose |
|-------|-------|---------|
| git-commit | haiku | Conventional commit creation; in PR mode also pushes and creates PRs with labels |

## Verification Strategy

### Layer 0: PreToolUse Hook (PR lint gate)
`pr-lint-gate.sh` runs before Bash tool calls:
- Blocks `gh pr create` unless `.omb/.lint-passed` marker exists and is fresh (< 10 min)
- Enforces that `/omb-lint-check` must pass before any PR submission
- Fail-open: missing `jq` produces no block

### Layer 1: PostToolUse Hook (file-local lint)
Runs automatically after every Write/Edit:
- `*.py` → `ruff check {file}`
- `*.ts/*.tsx` → `npx eslint {file}`
- `Dockerfile*` → `hadolint {file}`
- Fail-open: missing tools produce warnings, not blocks

### Layer 2: *-verify Agents (repo-wide checks)
Run after implementation is complete:
- `api-verify`: pyright + ruff + pytest
- `ui-verify`: tsc --noEmit + eslint + vitest
- `infra-verify`: terraform validate + hadolint + actionlint

### Layer 3: Stop Hook (status gate)
`omb-status-router.sh` runs after every Agent call:
- `<omb>DONE</omb>` / `<omb>RETRY</omb>` → pass through (orchestrator handles branching)
- `<omb>BLOCKED</omb>` → force stop, surfaces to user

## Available Skills

### Orchestration (user-invocable)
omb-orch-core, omb-orch-api, omb-orch-db, omb-orch-ui, omb-orch-electron, omb-orch-ai, omb-orch-infra, omb-orch-security, omb-orch-code, omb-orch-harness, omb-release

### LSP (agent-loaded)
omb-lsp-common, omb-lsp-python, omb-lsp-typescript, omb-lsp-go, omb-lsp-rust, omb-lsp-yaml, omb-lsp-docker, omb-lsp-terraform, omb-lsp-css, omb-lsp-json

### React Quality (agent-loaded)
omb-react-perf, omb-react-composition, omb-ui-guidelines, omb-react-native

### Git/PR (user-invocable)
omb-pr, omb-lint-check

### Codex Integration (user-invocable)
omb-codex, omb-codex-review, omb-codex-adv-review, omb-codex-run, omb-codex-setup

### Deployment (user-invocable)
omb-deploy-vercel, omb-vercel-cli

### CI/Setup (user-invocable)
omb-ci-python, omb-ci-typescript, omb-ci-infra, omb-setup

## Setup

First run: `./install-lsp.sh --all` to install LSP servers and linters.
The SessionStart hook checks for missing dependencies and warns (does not block).

---

## Tech Stack
<!-- AUTO-GENERATED -->

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend | FastAPI | >=0.115.0 |
| Backend ORM | SQLAlchemy 2.0 async | >=2.0.36 |
| Migrations | Alembic | >=1.14.0 |
| Database | PostgreSQL | 17 |
| Cache | Redis | 7 |
| AI Framework | LangGraph | >=0.3.30 |
| AI Core | LangChain Core | >=0.3.40 |
| AI Provider | langchain-anthropic | >=0.3.12 |
| Frontend | React | ^19.1.0 |
| Frontend Build | Vite | ^6.3.1 |
| Styling | Tailwind CSS | ^4.1.3 |
| Monorepo | Turborepo | ^2.5.0 |
| Python | >=3.12 | — |
| TypeScript | ^5.8.3 | — |
| Harness Hooks | oh-my-braincrew (Python) | 0.1.0 |

## Build and Test Commands
<!-- AUTO-GENERATED -->

| Action | Command |
|--------|---------|
| Dev (web) | `cd apps/web && npm run dev` |
| Dev (api) | `cd apps/api && uvicorn api.main:app --reload` |
| Dev (ai) | `cd apps/ai && langgraph dev` |
| Build (web) | `cd apps/web && npm run build` |
| Build (api) | `cd apps/api && docker build -t omb-api .` |
| Build (ai) | `cd apps/ai && langgraph build -t omb-ai` |
| Test (api) | `cd apps/api && pytest tests/ -v` |
| Test (ai) | `cd apps/ai && pytest tests/ -v` |
| Test (web) | `cd apps/web && npx vitest run` |
| Test (hooks) | `pytest tests/ -v` (project root) |
| Lint (Python) | `ruff check apps/api/ apps/ai/ && pyright apps/api/ apps/ai/` |
| Lint (TypeScript) | `cd apps/web && npx eslint . && npx tsc --noEmit` |
| Full stack | `docker-compose -f infra/docker-compose.yml up` |

## omb Commands

Run step-by-step for a complete development cycle, or invoke individually.

### Workflow (recommended order)

| # | Command | Description | --worktree |
|---|---------|-------------|------------|
| 1 | `omb:interview` | Requirements interview. Saves to .omb/interviews/ | Yes |
| 2 | `omb:plan` | Generate implementation plan. Saves to .omb/plans/ | Yes |
| 3 | `omb:plan-review` | Review and score an existing plan | -- |
| 4 | `omb:run [plan]` | Execute plan. Tracks progress in .omb/todo/ | Yes |
| 5 | `omb:verify [plan]` | Post-implementation verification with parallel verifier pool | Yes |
| 6 | `omb:doc` | Generate or update documentation | Yes |
| 7 | `omb:pr` | Create GitHub PR with lint gate | Yes |
| 8 | `omb:release` | Version release with changelog and binary builds | No |
| 9 | `omb:codex` | Codex CLI code review, adversarial review, and task delegation | No |
| 10 | `omb:harness` | Harness configuration management | -- |

### Utilities

| Command | Description |
|---------|-------------|
| `omb:prompt-guide` | Prompt engineering reference |
| `omb:prompt-review` | Iterative prompt scoring and improvement |
| `omb:lint-check` | Stack-aware linter. Must pass before PR |
| `omb:brainstorming` | Collaborative idea exploration |
| `omb:mermaid` | Mermaid diagram generation |
| `omb:setup` | Project scaffolding and configuration |
| `omb:worktree` | Worktree management (create, status, clean, resume) |
| `omb:clean` | Worktree cleanup and completion |

### CLI Commands

| Command | Description |
|---------|-------------|
| `omb init [path]` | Download and install harness files from latest release |
| `omb update [path]` | Update binary and refresh harness files |
| `omb version` | Print installed version |

### Worktree Management

Use `omb:worktree` to manage isolated git worktrees with persistent SQLite state tracking (`.omb/db/worktrees.db`). Worktree state persists across sessions and `/clear` commands.

- `omb worktree create <branch>` — create a new worktree
- `omb worktree status` — show all worktree states
- `omb worktree resume <branch>` — switch to an existing worktree
- `omb clean <branch>` — remove worktree and mark done

The `--worktree` column in the Workflow table indicates which commands automatically detect and use the active worktree context via `omb:worktree context`.

## .omb/ Directory

```
.omb/
├── db/           # SQLite worktree state (worktrees.db) — do not manually edit
├── plans/        # Implementation plans (omb:plan output)
├── todo/         # Execution tracking (omb:run progress)
└── interviews/   # Interview summaries (omb:interview output)
```

Do not manually edit `.omb/todo/` or `.omb/db/` files — they are managed by `omb:run` and `omb:worktree` respectively.

## Code Conventions
<!-- AUTO-GENERATED -->

### Python
- Import style: `from module import name` (no wildcard imports)
- Type hints: required on all function signatures (Pyright strict)
- String formatting: f-strings preferred
- Async: use `async/await` for I/O-bound operations
- Naming: `snake_case` for functions/variables, `PascalCase` for classes

### TypeScript
- Strict mode: `"strict": true` in tsconfig.json
- Import style: named imports preferred over default exports
- Type annotations: explicit return types on public functions
- Prefer `const` over `let`, no `var`
- Naming: `camelCase` for variables/functions, `PascalCase` for types/classes/components

## Linting and Formatting
<!-- AUTO-GENERATED -->

| Tool | Scope | Command |
|------|-------|---------|
| ruff | Python (api, ai, hooks) | `ruff check .` |
| pyright | Python type checking | `pyright --project apps/api` |
| eslint | TypeScript (web) | `cd apps/web && npx eslint .` |
| tsc | TypeScript type checking | `cd apps/web && npx tsc --noEmit` |

## Testing Strategy
<!-- AUTO-GENERATED -->

| Framework | Layer | Command |
|-----------|-------|---------|
| pytest | Backend API | `cd apps/api && pytest tests/ -v` |
| pytest | AI Service | `cd apps/ai && pytest tests/ -v` |
| pytest | Hooks | `pytest tests/ -v` |
| vitest | Frontend | `cd apps/web && npx vitest run` |

- Write tests before implementation (TDD).
- Integration tests for cross-layer contracts.
- No test skipping — if a test is hard to write, the design needs improvement.

## Monorepo Structure

```
oh-my-braincrew/
├── apps/
│   ├── api/          # FastAPI backend (Python)
│   ├── ai/           # LangGraph AI service (Python)
│   └── web/          # React frontend (TypeScript)
├── packages/
│   └── shared/       # Shared types/constants (TypeScript)
├── infra/            # docker-compose, terraform
├── src/hook/         # oh-my-braincrew CLI (harness Python package)
├── tests/            # Hook tests
├── .claude/          # Harness config (agents, skills, rules, hooks)
├── .omb/             # Working directories (plans, todo, interviews)
└── docs/             # Project documentation
```

## Quality Gates

Before claiming any task complete:

- [ ] All tests pass
- [ ] Type checking passes with zero errors
- [ ] No hardcoded secrets or credentials
- [ ] Linter passes with zero errors
- [ ] Documentation updated for public API changes
