# omb-setup Reference

Reference material for the `omb-setup` skill. Contains templates, schemas, explore prompts, and merge strategy.

---

## Section 1: Templates

All 6 project templates with full directory trees, dependency lists, and configuration details.

### fastapi

```
<project-name>/
├── src/
│   └── api/
│       ├── __init__.py
│       ├── main.py              # FastAPI app entry point
│       ├── config.py            # Settings via pydantic-settings
│       ├── dependencies.py      # Shared dependencies
│       └── routers/
│           ├── __init__.py
│           └── health.py        # Health check endpoint
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # Fixtures (TestClient, DB session)
│   └── test_health.py
├── alembic/
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── alembic.ini
├── pyproject.toml               # Project metadata, dependencies, tool config
├── Dockerfile                   # Multi-stage build
├── docker-compose.yml           # App + PostgreSQL + Redis
├── .dockerignore
├── .github/
│   └── workflows/
│       └── ci.yml               # Generated via omb-ci-python skill
├── .gitignore
├── .env.example
└── CLAUDE.md
```

Key configuration in `pyproject.toml`:
- Build system: hatchling
- Dependencies: fastapi, uvicorn, pydantic-settings, sqlalchemy, alembic
- Dev dependencies: pytest, pytest-cov, pytest-asyncio, ruff, pyright, httpx
- Ruff config: line-length 100, select rules (E, F, I, UP, B, SIM)
- Pyright: strict mode

### react

```
<project-name>/
├── src/
│   ├── components/
│   │   └── ui/                  # Reusable UI primitives
│   ├── hooks/
│   │   └── use-media-query.ts   # Example custom hook
│   ├── pages/
│   │   └── home.tsx
│   ├── lib/
│   │   └── utils.ts             # Utility functions
│   ├── styles/
│   │   └── globals.css          # Tailwind directives
│   ├── types/
│   │   └── index.ts             # Shared type definitions
│   ├── App.tsx
│   ├── main.tsx                 # Entry point
│   └── vite-env.d.ts
├── public/
│   └── favicon.svg
├── index.html
├── package.json
├── tsconfig.json
├── tsconfig.node.json
├── vite.config.ts
├── vitest.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── eslint.config.js             # Flat config
├── .github/
│   └── workflows/
│       └── ci.yml               # Generated via omb-ci-typescript skill
├── .gitignore
└── CLAUDE.md
```

Key dependencies:
- react, react-dom, react-router-dom
- tailwindcss, postcss, autoprefixer
- Dev: typescript, vite, vitest, @testing-library/react, eslint, @typescript-eslint/parser

### electron

```
<project-name>/
├── src/
│   ├── main/
│   │   ├── index.ts             # Main process entry
│   │   ├── window.ts            # Window management
│   │   └── ipc.ts               # IPC handlers
│   ├── renderer/
│   │   ├── index.html
│   │   ├── main.tsx             # Renderer entry point
│   │   ├── App.tsx
│   │   ├── components/
│   │   ├── hooks/
│   │   └── styles/
│   │       └── globals.css
│   └── preload/
│       └── index.ts             # Context bridge
├── resources/
│   └── icon.png
├── package.json
├── tsconfig.json
├── tsconfig.node.json
├── vite.config.ts               # Renderer bundling
├── electron-builder.config.js   # Build/packaging config
├── eslint.config.js
├── vitest.config.ts
├── .github/
│   └── workflows/
│       └── ci.yml
├── .gitignore
└── CLAUDE.md
```

Key dependencies:
- electron, electron-builder
- vite, @vitejs/plugin-react
- Dev: typescript, vitest, eslint

`electron-builder.config.js` should include:
- appId, productName, directories (output: dist-electron)
- macOS: dmg + zip targets
- Windows: nsis target
- Linux: AppImage + deb targets

### fullstack

```
<project-name>/
├── apps/
│   ├── api/                     # FastAPI backend (fastapi template)
│   │   ├── src/api/
│   │   ├── tests/
│   │   ├── alembic/
│   │   ├── pyproject.toml
│   │   └── Dockerfile
│   └── web/                     # React frontend (react template)
│       ├── src/
│       ├── package.json
│       ├── vite.config.ts
│       └── vitest.config.ts
├── packages/
│   └── shared/                  # Shared types/constants
│       ├── src/
│       │   └── index.ts
│       ├── package.json
│       └── tsconfig.json
├── infra/
│   ├── docker-compose.yml       # Full stack compose
│   └── terraform/               # Optional IaC
├── package.json                 # Workspace root (npm workspaces)
├── turbo.json                   # Turborepo config
├── .github/
│   └── workflows/
│       ├── ci-api.yml
│       └── ci-web.yml
├── .gitignore
└── CLAUDE.md
```

The root `package.json` uses npm workspaces pointing to `apps/*` and `packages/*`. `turbo.json` defines the task pipeline (lint, test, build).

### fullstack-ai

```
<project-name>/
├── apps/
│   ├── api/                         # FastAPI backend
│   │   ├── src/api/
│   │   │   ├── __init__.py
│   │   │   ├── main.py              # FastAPI app entry point
│   │   │   ├── config.py            # Settings via pydantic-settings
│   │   │   ├── dependencies.py      # Shared dependencies (DB session, etc.)
│   │   │   ├── routers/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── health.py        # Health check endpoint
│   │   │   │   └── chat.py          # AI chat endpoint (streaming)
│   │   │   └── models/
│   │   │       ├── __init__.py
│   │   │       └── base.py          # SQLAlchemy Base + mixins
│   │   ├── tests/
│   │   │   ├── __init__.py
│   │   │   ├── conftest.py          # Fixtures (TestClient, DB session, mock LLM)
│   │   │   ├── test_health.py
│   │   │   └── test_chat.py
│   │   ├── alembic/
│   │   │   ├── env.py
│   │   │   ├── script.py.mako
│   │   │   └── versions/
│   │   ├── alembic.ini
│   │   ├── pyproject.toml
│   │   └── Dockerfile
│   ├── ai/                          # LangGraph AI service
│   │   ├── src/<package_name>/
│   │   │   ├── __init__.py
│   │   │   ├── graph.py             # StateGraph definition + .compile()
│   │   │   ├── state.py             # State schemas (TypedDict + add_messages)
│   │   │   ├── tools.py             # @tool definitions
│   │   │   ├── context.py           # Runtime config @dataclass
│   │   │   ├── prompts.py           # System prompt constants
│   │   │   └── utils.py             # Helper utilities
│   │   ├── tests/
│   │   │   ├── __init__.py
│   │   │   ├── conftest.py          # Fixtures (graph instance, mock tools)
│   │   │   └── test_graph.py
│   │   ├── langgraph.json           # LangGraph CLI configuration
│   │   ├── pyproject.toml
│   │   └── Dockerfile
│   └── web/                         # React TypeScript frontend
│       ├── src/
│       │   ├── components/
│       │   │   └── ui/              # Reusable UI primitives
│       │   ├── hooks/
│       │   │   ├── use-media-query.ts
│       │   │   └── use-chat.ts      # AI chat hook (streaming)
│       │   ├── pages/
│       │   │   └── home.tsx
│       │   ├── lib/
│       │   │   ├── utils.ts
│       │   │   └── api-client.ts    # Typed API client
│       │   ├── styles/
│       │   │   └── globals.css      # Tailwind directives
│       │   ├── types/
│       │   │   └── index.ts         # Shared type definitions
│       │   ├── App.tsx
│       │   ├── main.tsx
│       │   └── vite-env.d.ts
│       ├── public/
│       │   └── favicon.svg
│       ├── index.html
│       ├── package.json
│       ├── tsconfig.json
│       ├── tsconfig.node.json
│       ├── vite.config.ts
│       ├── vitest.config.ts
│       ├── tailwind.config.ts
│       ├── postcss.config.js
│       └── eslint.config.js
├── packages/
│   └── shared/                      # Shared types/constants
│       ├── src/
│       │   └── index.ts
│       ├── package.json
│       └── tsconfig.json
├── infra/
│   ├── docker-compose.yml           # Full stack: API + AI + Web + PostgreSQL + Redis
│   └── terraform/                   # Optional IaC
├── package.json                     # Workspace root (npm workspaces)
├── turbo.json                       # Turborepo config
├── .github/
│   └── workflows/
│       ├── ci-api.yml
│       ├── ci-ai.yml
│       └── ci-web.yml
├── .gitignore
├── .env.example
└── CLAUDE.md
```

Monorepo with 3 apps:
- **apps/api**: FastAPI backend with SQLAlchemy 2.0 async ORM, Alembic migrations, PostgreSQL
- **apps/ai**: LangGraph AI service with StateGraph, tools, and prompts
- **apps/web**: React TypeScript frontend with Vite, Tailwind, streaming chat support

Key configuration:
- Root `package.json` uses npm workspaces pointing to `apps/web`, `packages/*`
- `turbo.json` defines task pipeline (lint, test, build) for JS/TS packages
- Python apps (api, ai) managed independently via `pyproject.toml` each
- `docker-compose.yml` orchestrates all services + PostgreSQL + Redis

**apps/api/pyproject.toml**:
- Build system: hatchling
- Dependencies: fastapi, uvicorn, pydantic-settings, sqlalchemy[asyncio], asyncpg, alembic, redis
- Dev dependencies: pytest, pytest-cov, pytest-asyncio, ruff, pyright, httpx

**apps/ai/pyproject.toml**:
- Build system: hatchling
- Dependencies: use versions from `omb-langchain-dependencies` skill
- Dev dependencies: pytest, pytest-cov, pytest-asyncio, ruff, pyright, `langgraph-cli[inmem]`

**apps/web/package.json**:
- Dependencies: react, react-dom, react-router-dom
- Dependencies: tailwindcss, postcss, autoprefixer
- Dev: typescript, vite, vitest, @testing-library/react, eslint, @typescript-eslint/parser

**apps/ai/langgraph.json**:
```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./src/<package_name>/graph.py:graph"
  },
  "env": "../.env"
}
```

### langgraph

```
<project-name>/
├── src/<package_name>/
│   ├── __init__.py
│   ├── graph.py           # StateGraph definition + .compile()
│   ├── state.py           # State schemas (TypedDict + add_messages)
│   ├── tools.py           # @tool definitions
│   ├── context.py         # Runtime config @dataclass
│   ├── prompts.py         # System prompt constants
│   └── utils.py           # Helper utilities
├── tests/
│   ├── __init__.py
│   ├── conftest.py        # Fixtures (graph instance, mock tools)
│   └── test_graph.py
├── langgraph.json         # LangGraph configuration (required for CLI)
├── pyproject.toml         # Project metadata, dependencies, tool config
├── Makefile               # test, lint, format, dev commands
├── Dockerfile             # Multi-stage build
├── .env.example           # API keys template
├── .gitignore
└── CLAUDE.md
```

Key configuration in `langgraph.json`:
```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./src/<package_name>/graph.py:graph"
  },
  "env": ".env"
}
```

Key configuration in `pyproject.toml`:
- Build system: hatchling
- Dependencies: use versions from `omb-langchain-dependencies` skill
- Dev dependencies: pytest, pytest-cov, pytest-asyncio, ruff, pyright, `langgraph-cli[inmem]`
- Ruff config: line-length 100, select rules (E, F, I, UP, B, SIM)
- Pyright: strict mode

### langgraph-multi

```
<project-name>/
├── src/
│   ├── orchestrator/          # Main orchestrator graph
│   │   ├── __init__.py
│   │   ├── agent.py           # Orchestrator StateGraph + .compile()
│   │   ├── state.py           # Orchestrator state schema
│   │   ├── prompt.py          # Orchestrator system prompt
│   │   └── tools.py           # Orchestrator tools
│   ├── agents/                # Subagent modules
│   │   ├── __init__.py
│   │   └── <agent_name>/      # One directory per subagent
│   │       ├── __init__.py
│   │       ├── agent.py       # Subagent graph + .compile()
│   │       ├── state.py       # Subagent state schema
│   │       ├── prompt.py      # Subagent system prompt
│   │       └── tools.py       # Subagent tools
│   └── shared/                # Shared utilities across agents
│       ├── __init__.py
│       ├── models.py          # Shared Pydantic models / schemas
│       └── config.py          # Shared configuration
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_orchestrator.py
│   └── test_<agent_name>.py
├── langgraph.json             # Multiple graph endpoints
├── pyproject.toml
├── Makefile
├── Dockerfile
├── .env.example
├── .gitignore
└── CLAUDE.md
```

Key configuration in `langgraph.json`:
```json
{
  "dependencies": ["."],
  "graphs": {
    "orchestrator": "./src/orchestrator/agent.py:graph",
    "<agent_name>": "./src/agents/<agent_name>/agent.py:graph"
  },
  "env": ".env"
}
```

---

## Section 2: CLAUDE.md Template

Target: 150-250 lines after slot filling. Under 500 lines absolute maximum.

```markdown
<!-- omb:setup v1 | {{date}} -->

# {{project_name}}

{{project_description}}

<hard_rules>

- [HARD] Never hardcode secrets, tokens, API keys, or connection strings
- [HARD] No completion claims without fresh verification evidence — run the proof, read the output, then claim
- [HARD] Never self-approve — use a separate review pass for approval
{{additional_hard_rules}}

</hard_rules>

## Tech Stack
<!-- AUTO-GENERATED -->

| Layer | Technology | Version |
|-------|-----------|---------|
{{tech_stack_rows}}

## Build and Test Commands
<!-- AUTO-GENERATED -->

| Action | Command |
|--------|---------|
{{build_commands_rows}}

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

## Workflow

- For non-trivial tasks (2+ files, schema/API changes): produce a plan before writing code.
- Follow test-driven development: write tests before implementation.
- One logical change per commit.
- Verify before claiming completion: run tests, read output, confirm success.

## Code Conventions
<!-- AUTO-GENERATED -->

{{language_conventions_sections}}

## Linting and Formatting
<!-- AUTO-GENERATED -->

| Tool | Scope | Command |
|------|-------|---------|
{{linter_rows}}

## Commit Conventions

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`.

- Subject line: imperative mood, lowercase, no period, max 72 characters.
- Body: wrap at 72 chars. Explain what and why, not how.
- One logical change per commit.

## Testing Strategy
<!-- AUTO-GENERATED -->

| Framework | Layer | Command |
|-----------|-------|---------|
{{test_framework_rows}}

- Write tests before implementation (TDD).
- Integration tests for cross-layer contracts.
- No test skipping — if a test is hard to write, the design needs improvement.

## Error Handling

- Handle errors explicitly at system boundaries (API routes, IPC handlers, external calls).
- Never swallow errors silently — log or propagate.
- Use structured error responses with consistent shape.

## Quality Gates

Before claiming any task complete:

- [ ] All tests pass
- [ ] Type checking passes with zero errors
- [ ] No hardcoded secrets or credentials
- [ ] Linter passes with zero errors
- [ ] Documentation updated for public API changes

## Project-Specific Notes

{{project_notes}}
```

### Template Variables Reference

| Variable | Source | Example |
|----------|--------|---------|
| `{{date}}` | Current date | `2026-04-11` |
| `{{project_name}}` | Phase 1 | `my-awesome-app` |
| `{{project_description}}` | Phase 3 Step 3.1 | `FastAPI backend for...` |
| `{{additional_hard_rules}}` | Phase 3 Step 3.3 | `- [HARD] All API responses under 200ms` |
| `{{tech_stack_rows}}` | Scan + Phase 3 Step 3.2 | `\| Backend \| FastAPI \| 0.115 \|` |
| `{{build_commands_rows}}` | Scan results | `\| Dev server \| uvicorn src.api.main:app --reload \|` |
| `{{language_conventions_sections}}` | Section 4 tables + detected languages | Per-language convention subsections |
| `{{linter_rows}}` | Detected linters | `\| ruff \| Python \| ruff check . \|` |
| `{{test_framework_rows}}` | Detected / confirmed | `\| pytest \| Backend \| pytest -v \|` |
| `{{project_notes}}` | Phase 3 Step 3.3 | Free-form notes |

---

## Section 3: Stack-to-Slot Mapping

| Template | DEV_CMD | BUILD_CMD | TEST_CMD | LINT_CMD | EXTRA |
|----------|---------|-----------|----------|----------|-------|
| fastapi | `uvicorn src.api.main:app --reload` | `docker build -t app .` | `pytest tests/ -v` | `ruff check . && pyright` | — |
| react | `npm run dev` | `npm run build` | `npx vitest run` | `npx eslint . && npx tsc --noEmit` | — |
| electron | `npm run dev` | `npm run build` | `npx vitest run` | `npx eslint . && npx tsc --noEmit` | `npm run package` |
| fullstack | `turbo dev` | `turbo build` | `turbo test` | `turbo lint` | — |
| fullstack-ai | `turbo dev` (web) / `uvicorn` (api) / `langgraph dev` (ai) | `turbo build` (web) / `docker build` (api, ai) | `pytest apps/api/tests/ -v && pytest apps/ai/tests/ -v && cd apps/web && npx vitest run` | `ruff check apps/api/ apps/ai/ && pyright apps/api/ apps/ai/ && cd apps/web && npx eslint . && npx tsc --noEmit` | `docker-compose up` (full stack) |
| langgraph | `langgraph dev` | `langgraph build -t app` | `pytest tests/ -v` | `ruff check . && pyright` | `langgraph up` (Docker, port 8123) |
| langgraph-multi | `langgraph dev` | `langgraph build -t app` | `pytest tests/ -v` | `ruff check . && pyright` | `langgraph up` (Docker, port 8123) |

---

## Section 4: Language Convention Tables

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

### Go
- Format: `gofmt` enforced
- Error handling: explicit error checks, no `_` for errors
- Naming: short, clear names per Go conventions
- Testing: table-driven tests

---

## Section 5: Merge Strategy (UPDATE mode)

When CLAUDE.md already exists:

1. **Backup**: Copy existing file to `CLAUDE.md.bak`
2. **Parse**: Split existing content by `##` headers into sections
3. **Check marker**: Look for `<!-- omb:setup` anywhere in the file
4. **If marker found** (previous omb-setup run):
   - Replace sections marked `<!-- AUTO-GENERATED -->` with new content
   - Preserve all other sections unchanged
   - Update the marker date
5. **If no marker** (user-written CLAUDE.md):
   - Append a divider: `---`
   - Append the omb Commands section and .omb/ Directory section
   - Add the marker at the top
   - Do NOT replace any existing sections

---

## Section 6: Gitignore Entries

### Common (all templates)
```
.omb/.lint-passed
.env
.env.*
!.env.example
*.log
.DS_Store
```

### Python
```
__pycache__/
*.py[cod]
*.egg-info/
dist/
.ruff_cache/
.mypy_cache/
.pyright/
.pytest_cache/
htmlcov/
.coverage
```

### TypeScript / Node.js
```
node_modules/
dist/
.turbo/
*.tsbuildinfo
coverage/
```

### Electron
```
dist-electron/
out/
```

---

## Section 7: Convention Presets

Popular conventions proposed during setup Step 3.3. Each category has 2-4 options with a recommended default per template.

### Category Definitions

#### 1. Project Structure
Applies to: **all templates**

| Option | Description |
|--------|-------------|
| **Feature-based (Recommended)** | Group files by feature/domain (e.g., `src/auth/`, `src/billing/`). Scales well, reduces cross-cutting imports. |
| Layer-based | Group files by type (e.g., `src/controllers/`, `src/services/`, `src/models/`). Simple but creates wide directories. |
| Hybrid | Feature folders with shared layer directories (e.g., `src/features/auth/` + `src/shared/utils/`). |

#### 2. API Style
Applies to: **fastapi, fullstack, fullstack-ai**

| Option | Description |
|--------|-------------|
| **REST resource-oriented (Recommended)** | Plural noun URLs (`/users`, `/orders/{id}`), HTTP verbs for actions, consistent response envelope. |
| RPC-style | Action-based URLs (`/createUser`, `/getOrders`). Simpler for internal APIs, less discoverable. |
| GraphQL | Single endpoint, client-driven queries. Best for complex nested data and multiple consumers. |

#### 3. State Management
Applies to: **react, electron, fullstack, fullstack-ai**

| Option | Description |
|--------|-------------|
| **Zustand (Recommended)** | Minimal boilerplate, no providers needed, works with React Server Components. |
| React Context + useReducer | Built-in, no dependencies. Good for small/medium apps with limited global state. |
| Redux Toolkit | Full-featured, DevTools, middleware. Best for large apps with complex state flows. |
| Jotai | Atomic state model, fine-grained reactivity. Good for independent pieces of state. |

#### 4. CSS Methodology
Applies to: **react, electron, fullstack, fullstack-ai**

| Option | Description |
|--------|-------------|
| **Tailwind utility-first (Recommended)** | Utility classes in JSX, design tokens via config. Fast iteration, consistent spacing/colors. |
| CSS Modules | Scoped CSS files per component. Good for teams familiar with traditional CSS. |
| Styled Components / Emotion | CSS-in-JS, dynamic styles based on props. Good for complex theming. |

#### 5. Error Handling
Applies to: **all templates**

| Option | Description |
|--------|-------------|
| **Typed error classes (Recommended)** | Custom error hierarchy (e.g., `NotFoundError`, `ValidationError`). Explicit, catchable by type. |
| Result/Either pattern | Return `Result<T, E>` instead of throwing. Functional style, forces callers to handle errors. |
| HTTP codes + structured JSON | Rely on HTTP status codes with consistent error response shape `{ error, message, details }`. |

#### 6. Testing Strategy
Applies to: **all templates**

| Option | Description |
|--------|-------------|
| **TDD strict (Recommended)** | Red-green-improve cycle. Write failing test first, then implement. Enforced via `omb-tdd` skill. |
| Test-after | Write implementation first, then add tests. Faster initial velocity, risk of undertesting. |
| Integration-first | Prioritize integration/E2E tests over unit tests. Good for API-heavy projects. |

#### 7. Git Workflow
Applies to: **all templates**

| Option | Description |
|--------|-------------|
| **Trunk-based (Recommended)** | Short-lived feature branches (< 5 days), squash merge to main. Simple, fast CI feedback. |
| GitHub Flow | Feature branches + PR reviews + merge. Standard for open-source and team projects. |
| Git Flow | develop/release/hotfix branches. Formal release process, best for versioned software. |

#### 8. API Versioning
Applies to: **fastapi, fullstack, fullstack-ai**

| Option | Description |
|--------|-------------|
| **URL path versioning (Recommended)** | `/v1/users`, `/v2/users`. Explicit, easy to route, cacheable. Most common pattern. |
| Header-based | `Accept: application/vnd.api+json;version=2`. Cleaner URLs, harder to test in browser. |
| No versioning | Single version, breaking changes handled via deprecation. Simplest for internal APIs. |

#### 9. Database Naming
Applies to: **fastapi, fullstack, fullstack-ai**

| Option | Description |
|--------|-------------|
| **snake_case plural (Recommended)** | `users`, `order_items`, `payment_methods`. PostgreSQL convention, ORM-friendly. |
| snake_case singular | `user`, `order_item`. Matches model class names. Popular in some ORMs. |
| Prefixed | `tbl_users`, `tbl_orders`. Disambiguates in complex schemas. Less common in modern stacks. |

#### 10. Logging
Applies to: **all templates**

| Option | Description |
|--------|-------------|
| **Structured JSON (Recommended)** | JSON log lines with `structlog` (Python) or `pino` (Node.js). Machine-parseable, searchable. |
| Plain text | Human-readable logs. Simple for development, harder to parse in production. |
| OpenTelemetry | Traces + metrics + logs unified. Best for distributed systems and observability platforms. |

### Template Presets

Default convention selections per template. Only applicable categories are included.

#### fastapi

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| API Style | REST resource-oriented |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| API Versioning | URL path versioning |
| Database Naming | snake_case plural |
| Logging | Structured JSON |

#### react

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| State Management | Zustand |
| CSS Methodology | Tailwind utility-first |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| Logging | Structured JSON |

#### electron

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| State Management | Zustand |
| CSS Methodology | Tailwind utility-first |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| Logging | Structured JSON |

#### fullstack

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| API Style | REST resource-oriented |
| State Management | Zustand |
| CSS Methodology | Tailwind utility-first |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| API Versioning | URL path versioning |
| Database Naming | snake_case plural |
| Logging | Structured JSON |

#### fullstack-ai

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| API Style | REST resource-oriented |
| State Management | Zustand |
| CSS Methodology | Tailwind utility-first |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| API Versioning | URL path versioning |
| Database Naming | snake_case plural |
| Logging | Structured JSON |

#### langgraph

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| Logging | Structured JSON |

#### langgraph-multi

| Category | Default |
|----------|---------|
| Project Structure | Feature-based |
| Error Handling | Typed error classes |
| Testing Strategy | TDD strict |
| Git Workflow | Trunk-based |
| Logging | Structured JSON |

### Convention Defaults Summary Format

When building `{{convention_defaults_summary}}` for Step 3.3a, use this format:

```
- Project Structure: Feature-based (group by feature/domain)
- API Style: REST resource-oriented (plural URLs, HTTP verbs)
- State Management: Zustand (minimal boilerplate)
- CSS Methodology: Tailwind utility-first (utility classes, design tokens)
- Error Handling: Typed error classes (custom hierarchy)
- Testing Strategy: TDD strict (red-green-improve)
- Git Workflow: Trunk-based (short-lived branches, squash merge)
- API Versioning: URL path (/v1/users)
- Database Naming: snake_case plural (users, order_items)
- Logging: Structured JSON (structlog/pino)
```

Only include categories that apply to the selected template.
