# omb-setup Reference

Reference material for the `omb-setup` skill. Merges content from `omb-init-survey` and `omb-init-project` references. Each section is loaded by specific steps in SKILL.md.

---

## Section 1: Profile JSON Schema

**Location:** `~/.omb/profile.json`

```json
{
  "username": "string — required, user's display name or GitHub username",
  "notes": "string — optional, free-text project conventions/preferences for init-project injection",
  "community_joined": "boolean — true if user posted to GitHub Discussions",
  "repo_starred": "boolean — true if user starred the repo via gh api",
  "created_at": "string — ISO 8601 timestamp, set on first creation",
  "updated_at": "string — ISO 8601 timestamp, updated on every write"
}
```

**Example:**
```json
{
  "username": "teddy",
  "notes": "I prefer Python for backend with strict type hints. All projects use pytest + vitest. Redis for caching, Postgres for persistence.",
  "community_joined": true,
  "repo_starred": true,
  "created_at": "2026-03-24T09:00:00Z",
  "updated_at": "2026-03-24T09:05:00Z"
}
```

**Validation rules:**
- `username` must be non-empty string (1-100 chars)
- `notes` may be empty string
- `community_joined` and `repo_starred` default to `false`
- `created_at` is immutable after first write
- `updated_at` must be refreshed on every write

---

## Section 2: GitHub Discussions GraphQL Mutation

### Step 1: Query Discussion Category ID

The `createDiscussion` mutation requires a `categoryId` (opaque node ID). Query it first:

```bash
gh api graphql -f query='
  query {
    repository(owner: "teddynote-lab", name: "oh-my-braincrew") {
      discussionCategories(first: 10) {
        nodes {
          id
          name
        }
      }
    }
  }
'
```

Parse the JSON response to find the node where `name` is `"General"`. Extract its `id` field.

**Error handling:**
- If the query fails (403, network error): skip to browser URL fallback (Section 3)
- If "General" category not found: use the first available category, or fallback to browser URL

### Step 2: Create Discussion

```bash
gh api graphql -f query='
  mutation($repoId: ID!, $catId: ID!, $title: String!, $body: String!) {
    createDiscussion(input: {
      repositoryId: $repoId,
      categoryId: $catId,
      title: $title,
      body: $body
    }) {
      discussion {
        url
      }
    }
  }
' -f repoId="{{REPO_NODE_ID}}" -f catId="{{CATEGORY_NODE_ID}}" -f title="{{TITLE}}" -f body="{{BODY}}"
```

**Getting the repository node ID:**

Query it alongside the category lookup:

```bash
gh api graphql -f query='
  query {
    repository(owner: "teddynote-lab", name: "oh-my-braincrew") {
      id
      discussionCategories(first: 10) {
        nodes {
          id
          name
        }
      }
    }
  }
'
```

The `repository.id` field is the `repoId` for the mutation.

### Discussion Post Template

**Title:** `Hello from {{username}}!`

**Body:**
```markdown
## New omb user

- **Username:** {{username}}
- **OS:** {{os_name}} (from `uname -s`)
- **Date:** {{iso8601_date}}

### What I plan to build
{{user_plans_or_default}}

### How I feel about omb
{{user_feelings_or_default}}

---
*Posted via `omb init` survey*
```

**Default values (when user selects "Use default"):**
- plans: "Exploring omb for multi-agent orchestration"
- feelings: "Excited to get started!"

---

## Section 3: Browser URL Fallback

When `gh api graphql` fails (403, 401, network error, or `gh` not available), construct a browser URL:

```
https://github.com/teddynote-lab/oh-my-braincrew/discussions/new?category=general&title=Hello+from+{{username}}!&body={{url_encoded_body}}
```

Display to user:
```
Could not post to GitHub Discussions automatically.
You can post manually by visiting:
https://github.com/teddynote-lab/oh-my-braincrew/discussions/new?category=general
```

Do NOT attempt to URL-encode the full body — it is too long for query params. Just link to the new discussion page with the category pre-selected.

---

## Section 4: CLAUDE.md Template

Target: 150-200 lines. The template uses `{{placeholder}}` markers that the skill replaces with detected/confirmed values.

```markdown
<!-- omb:init-project v1 | {{date}} -->

# {{project_name}}

<hard_rules>

- [HARD] Read PROJECT.md at session start before any work
- [HARD] Always write in English — all comments, documents, code comments, and outputs
- [HARD] No completion claims without fresh verification evidence — run the proof, read the output, then claim
- [HARD] Never self-approve — use a separate review pass for approval
- [HARD] Never hardcode secrets, tokens, API keys, or connection strings
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
- Body: wrap at 72 characters. Explain what and why, not how.
- One logical change per commit.
- Every commit includes trailer: `Co-Authored-By: Braincrew(dev@brain-crew.com)`

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
| `{{date}}` | Current date | `2026-03-22` |
| `{{project_name}}` | Q1 / README / package.json | `my-awesome-app` |
| `{{additional_hard_rules}}` | Q7 user input | `- [HARD] All API responses under 200ms` |
| `{{tech_stack_rows}}` | Explore agent + Q4 | `\| Backend \| FastAPI \| 0.115 \|` |
| `{{build_commands_rows}}` | package.json scripts / Makefile | `\| Dev server \| npm run dev \|` |
| `{{language_conventions_sections}}` | Section 7 tables + detected languages | Per-language convention subsections with import/type safety rules |
| `{{linter_rows}}` | Detected linters | `\| ruff \| Python \| ruff check . \|` |
| `{{test_framework_rows}}` | Detected / Q5 | `\| pytest \| Backend \| pytest -v \|` |
| `{{project_notes}}` | Q8 user input | Free-form notes |
| `{{related_repos_section}}` | Q2/Q3 (multi-repo only) | Related Repositories header + table (omitted if not multi-repo) |

---

## Section 5: PROJECT.md Template

Target: under 200 lines. Table-first format for quick reference.

```markdown
# {{project_name}}

> {{project_description}}

## Architecture

{{architecture_section}}

## Tech Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
{{tech_stack_detail_rows}}

## Key Entry Points

| File | Purpose |
|------|---------|
{{entry_points_rows}}

## Development Setup

### Prerequisites

{{prerequisites}}

### Quick Start

```bash
{{quickstart_commands}}
```

### Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
{{env_vars_rows}}

## CI/CD

{{cicd_section}}

{{related_repos_section}}

## Notes

{{notes}}
```

### Architecture Section Variants

**Single Repo:**
```markdown
Single repository. Key directories:

| Directory | Purpose |
|-----------|---------|
{{directory_table}}
```

**Monorepo:**
```markdown
Monorepo managed by {{monorepo_tool}}.

| Workspace | Path | Purpose |
|-----------|------|---------|
{{workspace_table}}
```

**Multi-Repo:**
```markdown
Multi-repository project. This is the {{role}} repository.

| Repository | Path | Purpose |
|-----------|------|---------|
{{repo_table}}
```

---

## Section 6: Explore Agent Prompts

### Agent 1: Tech Stack Scanner

```
Scan this project to detect the complete technology stack. Report findings as structured data.

CHECK THESE FILES (read each if it exists):
- package.json (dependencies, devDependencies, scripts)
- pyproject.toml / setup.py / requirements.txt / Pipfile
- go.mod
- Cargo.toml
- Gemfile
- Makefile
- docker-compose.yml / Dockerfile
- .github/workflows/*.yml
- vercel.json / netlify.toml / fly.toml
- tsconfig.json
- next.config.* / vite.config.* / webpack.config.*
- .eslintrc* / .prettierrc* / biome.json
- ruff.toml / .ruff.toml / pyproject.toml [tool.ruff]
- .flake8 / setup.cfg [flake8]
- jest.config.* / vitest.config.* / pytest.ini / conftest.py
- .env.example / .env.template

REPORT FORMAT (use exactly this structure):

LANGUAGES:
- [language]: [version if detectable]

FRAMEWORKS:
- [framework]: [version]

DATABASES:
- [database]: [connection method if detectable]

BUILD_TOOLS:
- [tool]: [purpose]

LINTERS:
- [linter]: [scope (e.g., Python, TypeScript)]

FORMATTERS:
- [formatter]: [scope]

TEST_FRAMEWORKS:
- [framework]: [scope] [command if in scripts]

PACKAGE_MANAGERS:
- [manager]: [lockfile detected]

CI_CD:
- [platform]: [config file]

DEPLOYMENT:
- [platform]: [config file]

BUILD_COMMANDS:
- [name]: [command] (from package.json scripts, Makefile targets, etc.)

ENV_VARS:
- [name]: [purpose] (from .env.example or .env.template)
```

### Agent 2: Structure Scanner

```
Scan this project to understand its repository structure and architecture. Report findings as structured data.

TASKS:
1. Determine repo type:
   - Check for workspaces in package.json, pnpm-workspace.yaml, lerna.json, turbo.json
   - Check for multiple go.mod files
   - If workspaces found: MONOREPO
   - If single root with standard dirs: SINGLE_REPO
   - Default: SINGLE_REPO

2. Map key directories (top 2 levels):
   - List directories with their apparent purpose
   - Identify: src/, app/, lib/, pkg/, internal/, cmd/, tests/, docs/, scripts/, config/

3. Identify entry points:
   - Main application files (main.go, app.py, index.ts, etc.)
   - API route directories
   - Configuration entry points

4. Extract project identity:
   - README.md first paragraph (project description)
   - package.json name + description
   - pyproject.toml [project] name + description
   - go.mod module path

5. Detect monorepo workspaces (if applicable):
   - List all workspace paths and their package names
   - Identify shared packages vs applications

REPORT FORMAT:

REPO_TYPE: [SINGLE_REPO | MONOREPO]
MONOREPO_TOOL: [turborepo | pnpm | lerna | yarn | nx | none]

PROJECT_NAME: [detected name]
PROJECT_DESCRIPTION: [first paragraph of README or package description]

DIRECTORIES:
- [path]: [purpose]

ENTRY_POINTS:
- [file]: [purpose]

WORKSPACES (if monorepo):
- [path]: [name] - [purpose]

README_EXTRACT: |
  [First 3-5 sentences of README.md]
```

---

## Section 7: Detection Mapping Tables

### Language to Convention Mapping

| Language | Var/Function | Class/Type | Constant | File | Line Length |
|----------|-------------|-----------|----------|------|-------------|
| Python | `snake_case` | `PascalCase` | `UPPER_SNAKE` | `snake_case.py` | 120 |
| TypeScript | `camelCase` | `PascalCase` | `UPPER_SNAKE` | `camelCase.ts` / `PascalCase.tsx` | 120 |
| JavaScript | `camelCase` | `PascalCase` | `UPPER_SNAKE` | `camelCase.js` / `PascalCase.jsx` | 120 |
| Go | `camelCase` (unexported) / `PascalCase` (exported) | `PascalCase` | `PascalCase` or `UPPER_SNAKE` | `snake_case.go` | 120 |
| Rust | `snake_case` | `PascalCase` | `UPPER_SNAKE` | `snake_case.rs` | 100 |
| Ruby | `snake_case` | `PascalCase` | `UPPER_SNAKE` | `snake_case.rb` | 120 |
| Java | `camelCase` | `PascalCase` | `UPPER_SNAKE` | `PascalCase.java` | 120 |
| Kotlin | `camelCase` | `PascalCase` | `UPPER_SNAKE` | `PascalCase.kt` | 120 |
| Swift | `camelCase` | `PascalCase` | `camelCase` | `PascalCase.swift` | 120 |
| C# | `camelCase` | `PascalCase` | `PascalCase` | `PascalCase.cs` | 120 |

### Language to Import Order Mapping

| Language | Import Order |
|----------|-------------|
| Python | stdlib > third-party > local (enforced by isort/ruff) |
| TypeScript | node builtins > external packages > internal aliases > relative imports |
| JavaScript | node builtins > external packages > internal aliases > relative imports |
| Go | stdlib > third-party > local (enforced by goimports) |
| Rust | std > external crates > crate modules |
| Ruby | stdlib > gems > local |
| Java | java.* > javax.* > third-party > project |

### Language to Type Safety Mapping

| Language | Type Safety Guidance |
|----------|---------------------|
| Python | Type hints on all function signatures. Use `mypy --strict` or Pyright. |
| TypeScript | `strict: true` in tsconfig. No `any` unless explicitly justified. |
| Go | Exported functions must have godoc. Use `golangci-lint`. |
| Rust | Leverage the type system fully. Avoid `unwrap()` in library code. |
| Java | Use `@Nullable` / `@NonNull` annotations. Prefer `Optional<T>` over null. |
| Kotlin | Prefer non-nullable types. Use `?.` safe calls over `!!`. |
| Swift | Prefer non-optional types. Use `guard let` for early unwrapping. |

### Config File to Framework Mapping

| Config File | Framework | Category |
|------------|-----------|----------|
| `next.config.*` | Next.js | Frontend |
| `vite.config.*` | Vite | Build Tool |
| `webpack.config.*` | Webpack | Build Tool |
| `astro.config.*` | Astro | Frontend |
| `svelte.config.*` | SvelteKit | Frontend |
| `nuxt.config.*` | Nuxt | Frontend |
| `angular.json` | Angular | Frontend |
| `remix.config.*` | Remix | Frontend |
| `turbo.json` | Turborepo | Monorepo |
| `lerna.json` | Lerna | Monorepo |
| `nx.json` | Nx | Monorepo |
| `docker-compose.yml` | Docker Compose | Infrastructure |
| `vercel.json` | Vercel | Deployment |
| `fly.toml` | Fly.io | Deployment |
| `netlify.toml` | Netlify | Deployment |
| `railway.json` | Railway | Deployment |

### Linter/Formatter Detection

| Config File | Tool | Type | Scope |
|------------|------|------|-------|
| `.eslintrc*` / `eslint.config.*` | ESLint | Linter | JavaScript/TypeScript |
| `.prettierrc*` | Prettier | Formatter | JavaScript/TypeScript/CSS |
| `biome.json` | Biome | Linter+Formatter | JavaScript/TypeScript |
| `ruff.toml` / `.ruff.toml` / `pyproject.toml [tool.ruff]` | ruff | Linter+Formatter | Python |
| `.flake8` / `setup.cfg [flake8]` | flake8 | Linter | Python |
| `.pylintrc` | pylint | Linter | Python |
| `mypy.ini` / `pyproject.toml [tool.mypy]` | mypy | Type Checker | Python |
| `.golangci.yml` | golangci-lint | Linter | Go |
| `rustfmt.toml` | rustfmt | Formatter | Rust |
| `clippy.toml` | clippy | Linter | Rust |
| `.rubocop.yml` | RuboCop | Linter+Formatter | Ruby |
| `checkstyle.xml` | Checkstyle | Linter | Java |
| `.swiftlint.yml` | SwiftLint | Linter | Swift |

---

## Section 8: Merge Strategy for Existing CLAUDE.md

### CREATE Mode

Full write with version marker at top. No merge needed.

### UPDATE Mode

#### Step 0: Resolve Paths

Determine `claudePath` and `backupPath` based on which file was detected in Step 1:

| Detected Location | `claudePath` | `backupPath` |
|-------------------|-------------|--------------|
| `./CLAUDE.md` (root — preferred) | `./CLAUDE.md` | `./CLAUDE.md.bak` |
| `./.claude/CLAUDE.md` (fallback) | `./.claude/CLAUDE.md` | `./.claude/CLAUDE.md.bak` |

Use `claudePath` and `backupPath` consistently in all subsequent steps and confirmation messages.

#### Step 1: Backup

Copy `claudePath` to `backupPath` before any modifications.

#### Step 2: Parse Existing Sections

Split existing CLAUDE.md by `##` headers. Store as ordered map:
```
{ "header_text": "section_content", ... }
```

#### Step 3: Check Version Marker

Search the **entire file** for `<!-- omb:init-project` (not just the top — a previous no-marker UPDATE may have appended it inside a divider block). This ensures re-runs are idempotent.

#### Step 4A: Marker Found (Previously Generated)

The file was previously generated by this skill.

- Sections containing `<!-- AUTO-GENERATED -->` comment: **replace** with new content
- Sections WITHOUT `<!-- AUTO-GENERATED -->` comment: **preserve** unchanged
- Sections in template but missing from file: **append** at end
- Always update the version marker date

Example auto-generated section:
```markdown
## Tech Stack
<!-- AUTO-GENERATED -->

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend | FastAPI | 0.115 |
```

#### Step 4B: No Marker (Manually Written)

The file was written by a human or another tool. Respect it fully.

- **Do not modify** existing content, with one exception (see below)
- **Append** new sections under a divider:
  ```markdown

  ---

  ## Generated by omb:init-project
  <!-- omb:init-project v1 | {{date}} -->

  [new sections here]
  ```
- **Single exception** — PROJECT.md reference: if the existing file does not contain `Read PROJECT.md`, insert `- [HARD] Read PROJECT.md at session start before any work` after the first `#` header. This is the ONLY permitted modification to existing content. Explain this insertion in the diff summary.
- Present clear summary of what will be appended

#### Diff Summary Format

Before writing, present to user:
```
UPDATE Summary:
- Sections preserved (unchanged): [list]
- Sections replaced (AUTO-GENERATED): [list]
- Sections added (new): [list]
- Backup saved to: {{backupPath}}
- PROJECT.md reference: [inserted / already present]
```

---

## Section 9: Slack Credential Format

**Location:** `~/.claude/channels/slack/.env`

```
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=...
SLACK_CHANNEL_ID=C01234ABCDE
```

**File permissions:** 0600 (owner read/write only)

**Validation rules:**
- `SLACK_BOT_TOKEN` must start with `xoxb-`
- `SLACK_CHANNEL_ID` must match pattern `^[A-Z][A-Z0-9]{10}$`
- `SLACK_SIGNING_SECRET` must be non-empty

---

## Section 10: Error Handling

| Command | Possible Error | Behavior |
|---------|---------------|----------|
| `gh auth status` | gh not installed | Set `gh_available=false`, show warning, skip steps 5-6 |
| `gh auth status` | Not logged in | Set `gh_available=false`, show "Run `gh auth login`" message |
| `gh api graphql` (category query) | 403 Forbidden | Token lacks scope. Show browser URL fallback |
| `gh api graphql` (category query) | Network error | Show browser URL fallback |
| `gh api graphql` (create discussion) | 403 Forbidden | Missing `discussion` write scope. Show browser URL fallback |
| `gh api graphql` (create discussion) | 422 Unprocessable | Duplicate title or invalid input. Show browser URL fallback |
| `gh api -X PUT /user/starred/...` | 403 Forbidden | Token lacks `starring` scope. Log, continue |
| `gh api -X PUT /user/starred/...` | 404 Not Found | Repo not found. Log, continue |
| `gh api -X PUT /user/starred/...` | Network error | Log, continue |
| `Write ~/.omb/profile.json` | Permission denied | Fatal — show error message. Cannot continue without profile write access |
| `Read ~/.omb/profile.json` | File not found | Normal — first-time user, proceed with empty profile |
| `Read ~/.omb/profile.json` | Parse error (invalid JSON) | Treat as corrupted, offer "Start fresh" |

---

## Section 11: gh auth Status Parsing

The `gh auth status` command outputs to stderr (not stdout). Capture with `2>&1`.

**Authenticated output pattern:**
```
github.com
  ✓ Logged in to github.com account {{username}} (keyring)
  - Active account: true
  - Git operations protocol: https
  - Token: gho_****
  - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

**Not authenticated pattern:**
```
You are not logged into any GitHub hosts. Run gh auth login to authenticate.
```

**Detection logic:**
1. Run `gh auth status 2>&1`
2. If output contains "Logged in to" → `gh_available = true`
3. If output contains "not logged in" → `gh_available = false`
4. If command not found → `gh_available = false`

**Username extraction (optional):**
Parse "Logged in to github.com account {{username}}" to pre-fill Step 2.

---

## Section 12: Gitignore Required Entries

Step 3.1.5 uses these tables to ensure `.gitignore` coverage. All additions are idempotent — check before appending.

### Harness Entries (always added)

These entries are required for any project using oh-my-braincrew:

| Entry | Reason |
|---|---|
| `.omb/` | Harness runtime state, plans, sessions, logs |
| `.claude/plans/` | Claude Code plan files (session-local) |
| `.claude/agent-memory/` | Agent memory state |
| `.claude/worktrees/` | Agent worktree checkouts |
| `.claude/skills/*-workspace/` | Skill iteration/eval artifacts |

### Language-Specific Entries (added when detected)

Added based on languages/frameworks found during Phase 3 scan:

| Detected Language | Entries |
|---|---|
| Python | `__pycache__/`, `*.pyc`, `.venv/`, `dist/`, `*.egg-info/`, `.ruff_cache/`, `.pytest_cache/`, `.coverage` |
| TypeScript / JavaScript | `node_modules/`, `dist/`, `coverage/` |
| Go | `bin/`, `*.exe`, `coverage.out` |

### Common Entries (always added)

| Entry | Reason |
|---|---|
| `.env` | Environment secrets |
| `.env.local` | Local environment overrides |
| `.env*.local` | Variant local env files |
| `.DS_Store` | macOS Finder metadata |
