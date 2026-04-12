---
name: omb-setup
user-invocable: true
description: >
  (omb) Set up omb in a project — scaffold directory structure, generate CLAUDE.md with omb usage guide,
  create .omb/ working directories, and configure settings.json with hooks and env vars.
  Triggers on: setup, init, initialize, first-time setup, configure project.
argument-hint: "[template: fastapi | react | electron | fullstack | fullstack-ai | langgraph | langgraph-multi] [project-name]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent
---

# Project Setup

Set up a new project with omb orchestration support. Scaffolds directory structure, generates CLAUDE.md with omb command guide, creates `.omb/` working directories, and configures `settings.json`.

## HARD RULES

- [HARD] All output in English
- [HARD] Ask ONE question at a time via AskUserQuestion (never batch multiple questions)
- [HARD] Never store secrets — rely on environment variables only
- [HARD] If CLAUDE.md exists: READ first, backup to `.bak`, then UPDATE (never blind overwrite)
- [HARD] If CLAUDE.md exists and no `--force`: ask user before overwriting
- [HARD] CLAUDE.md must stay under 500 lines
- [HARD] Explore agents must complete BEFORE asking project questions (Phase 3)
- [HARD] Preserve existing settings.json keys — merge, never overwrite the entire file

## Pre-execution Context

!`ls CLAUDE.md .claude/CLAUDE.md .omb/ 2>/dev/null || echo "no existing files"`
!`git branch --show-current 2>/dev/null || echo "not a git repo"`

Parse pre-execution output to set flags:
- `claudemd_exists`: true if CLAUDE.md or .claude/CLAUDE.md was listed
- `omb_dir_exists`: true if .omb/ was listed
- `is_git_repo`: true if branch name was returned

## Arguments

$ARGUMENTS

If arguments contain `--force`: ignore existing files, run full setup from scratch.

---

## Phase 1: Template Selection

### Step 1.1: Template Choice

If the template is not specified in arguments:

```
AskUserQuestion:
  question: "What type of project are you setting up?"
  header: "Template"
  options:
    - label: "FastAPI (Python backend)"
      description: "FastAPI + SQLAlchemy + Alembic + pytest"
    - label: "React (TypeScript frontend)"
      description: "React + Vite + Tailwind + vitest"
    - label: "Electron (Desktop app)"
      description: "Electron + React renderer + IPC"
    - label: "Full-stack (Monorepo)"
      description: "FastAPI backend + React frontend + Turborepo"
    - label: "Full-stack AI (Monorepo)"
      description: "FastAPI + PostgreSQL + LangGraph AI + React frontend + pytest + ORM"
    - label: "LangGraph (AI agent)"
      description: "LangGraph + single StateGraph + tools"
    - label: "LangGraph Multi-Agent"
      description: "LangGraph orchestrator + modular subagents"
```

Map response to template key: `fastapi`, `react`, `electron`, `fullstack`, `fullstack-ai`, `langgraph`, `langgraph-multi`.

### Step 1.2: Project Name

If project name is not in arguments:

```
AskUserQuestion:
  question: "What is the project name? (lowercase, kebab-case recommended)"
  header: "Name"
  options:
    - label: "{{detected_dir_name}}"
      description: "Use current directory name"
```

Store as `project_name`.

---

## Phase 2: Project Scan (Silent Discovery)

No user interaction. Scan the codebase to prepare for questions.

### Step 2.1: Concurrent Scan

Invoke the `Agent` tool twice with `subagent_type: "Explore"` and `model: "haiku"` — issue both calls in a single parallel batch.

**Agent 1: Tech Stack Scanner**
```
Scan the project at {{project_path}} and report:
- Programming languages detected (with file counts)
- Frameworks and libraries (from package.json, pyproject.toml, go.mod, etc.)
- Database systems (from docker-compose, connection strings, ORM configs)
- Linters and formatters configured
- Test frameworks detected
- Build commands (from scripts, Makefile, etc.)
- Dev server commands

Output as structured data. Do NOT modify any files.
```

**Agent 2: Structure Scanner**
```
Scan the project at {{project_path}} and report:
- Repository type (monorepo, single-package, multi-package)
- Key directories and their purpose
- Entry points (main files, API routes, CLI entry)
- Project identity (name from package.json/pyproject.toml, description from README)
- Workspace configuration (if monorepo)

Output as structured data. Do NOT modify any files.
```

Both agents MUST complete before proceeding to Phase 3.

Collect and merge results into a `scan_results` object.

---

## Phase 3: Project Questions (Interactive)

### Step 3.1: Project Description

Generate 2-3 project description suggestions from scan results.

```
AskUserQuestion:
  question: "Based on the scan, here are suggested project descriptions:\n\n1. {{suggestion_1}}\n2. {{suggestion_2}}\n3. {{suggestion_3}}\n\nWhich best describes this project?"
  header: "Description"
  options:
    - label: "Option 1 (Recommended)"
      description: "{{suggestion_1}}"
    - label: "Option 2"
      description: "{{suggestion_2}}"
    - label: "Option 3"
      description: "{{suggestion_3}}"
```

### Step 3.2: Tech Stack Gaps

If scan missed anything:

```
AskUserQuestion:
  question: "Detected tech stack:\n{{detected_stack_summary}}\n\nAnything missing or incorrect?"
  header: "Tech Stack"
  options:
    - label: "Looks correct"
      description: "Proceed with detected stack"
    - label: "Add/correct items"
      description: "Provide corrections (use 'Other' to type)"
```

### Step 3.3: Project Conventions

Based on `scan_results` and the chosen template, select applicable convention categories from @reference.md Section 7.

#### Step 3.3a: Convention Defaults Summary

Build a defaults summary from the template's recommended preset in @reference.md Section 7. Filter categories by template applicability. Format the summary as a compact list showing each category and its default choice.

```
AskUserQuestion:
  question: "Based on your {{template}} stack, here are recommended conventions:\n\n{{convention_defaults_summary}}\n\nHow would you like to proceed?"
  header: "Conventions"
  options:
    - label: "Accept defaults (Recommended)"
      description: "Use these conventions as-is"
    - label: "Customize"
      description: "Walk through each category to adjust"
    - label: "Skip for now"
      description: "No conventions — can be added to CLAUDE.md later"
```

If "Accept defaults": store the default preset as `convention_selections`, proceed to Step 3.4.
If "Skip": store empty `convention_selections`, proceed to Step 3.4.

#### Step 3.3b: Customize (only if user chose "Customize")

For each applicable category (filtered by template, ordered by impact from @reference.md Section 7), ask ONE question at a time:

```
AskUserQuestion:
  question: "{{category_name}}:"
  header: "Convention"
  options:
    - label: "{{option_1}} (Recommended)"
      description: "{{option_1_description}}"
    - label: "{{option_2}}"
      description: "{{option_2_description}}"
    - label: "{{option_3}}"
      description: "{{option_3_description}}"
```

After all categories are answered, store results as `convention_selections`.

#### Convention Output

The `convention_selections` are rendered into the CLAUDE.md `{{project_notes}}` slot as a structured list:

```markdown
## Project-Specific Notes

### Conventions
- **API Style**: REST (resource-oriented URLs, plural nouns, HTTP verbs)
- **State Management**: Zustand (minimal boilerplate, no providers)
- **Project Structure**: Feature-based (group files by feature, not by type)
...
```

### Step 3.4: Documentation Language

```
AskUserQuestion:
  question: "Select the language for generated documents.\nThis applies to plans (.omb/plans/), docs/ files, and README.md.\n\nNote: CLAUDE.md and MEMORY.md are ALWAYS written in English regardless of this setting."
  header: "Doc Language"
  options:
    - label: "English (Recommended)"
      description: "All documents in English — best for open-source and international teams"
    - label: "Korean"
      description: "Plans, documents, README in Korean"
```

Store as `doc_language`. Map: "English (Recommended)" -> `en`, "Korean" -> `ko`.

**Escape Hatch:** If user says "skip", "just generate", or "generate now" at ANY question:
1. Proceed with detected/default data only
2. Flag unconfirmed sections with `<!-- unconfirmed: auto-detected -->` comments
3. Continue to Phase 4

---

## Phase 4: Project Scaffolding

Create the directory structure based on the chosen template. Each template is documented in detail in @reference.md Section 1 (Templates).

### Execution

1. Create all directories and files per the template spec
2. For `langgraph` and `langgraph-multi` templates, consult `Skill("omb-langchain-dependencies")` for current package versions
3. Generate configuration files with real, working content:
   - `pyproject.toml` / `package.json` with actual dependency versions
   - `tsconfig.json` with strict mode enabled
   - `langgraph.json` for LangGraph templates
   - Linter/formatter configs with recommended rule sets
   - Dockerfiles with multi-stage builds
   - `.gitignore` appropriate for the stack
4. Generate CI workflows using `omb-ci-python` or `omb-ci-typescript` skill patterns

---

## Phase 5: .omb/ Directory Setup

Create the working directory structure:

```
.omb/
├── plans/        # Implementation plans (omb:plan output)
├── todo/         # Execution tracking (omb:run progress)
└── interviews/   # Interview summaries (omb:interview output)
```

```bash
mkdir -p .omb/plans .omb/todo .omb/interviews
```

Only these 3 directories. Nothing else is created at setup time.

NOTE: `.omb/.lint-passed` is a runtime marker file written by `omb-lint-check` and consumed by the `omb-hook.sh PreToolUse` hook. It is NOT created during setup.

---

## Phase 6: settings.json Configuration

Configure the target project's `.claude/settings.json` programmatically via the init script.

### Step 6.1: Run settings init script

```bash
bash "$CLAUDE_PROJECT_DIR/.claude/hooks/omb/omb-setup-settings.sh" "{{doc_language}}"
```

Where `{{doc_language}}` is from Phase 3 Step 3.4 (`"en"` or `"ko"`).

The script will:
- Read existing `.claude/settings.json` (or create from `{}`)
- Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` to `env` (enables agent teams)
- Add `OMB_DOCUMENTATION_LANGUAGE: "{{doc_language}}"` to `env`
- Merge all 4 hook lifecycle events (SessionStart, PreToolUse, PostToolUse, Stop)
- Set permissions (bypassPermissions mode with standard tool allowlist)
- Set `respectGitignore: true`
- Preserve all existing settings.json keys not managed by omb
- Write atomically (temp file + rename)

- [HARD] Preserve ALL existing env vars — the script only adds/updates omb-specific keys
- [HARD] Preserve existing hook entries for other events — only add/update the 4 omb events

### Step 6.2: Verify

Read `.claude/settings.json` and confirm:
- [ ] `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is `"1"`
- [ ] `env.OMB_DOCUMENTATION_LANGUAGE` matches the selected language
- [ ] All 4 hook events are present with `omb-hook.sh` commands
- [ ] Permissions and respectGitignore are set

---

## Phase 7: CLAUDE.md Generation

Generate the project's CLAUDE.md using the template from @reference.md Section 2.

### Step 7.1: Determine Mode

- **CREATE**: No existing CLAUDE.md -> generate from template
- **UPDATE**: CLAUDE.md exists -> backup to `.bak`, then merge

For UPDATE mode:
1. Read existing CLAUDE.md
2. Copy to `CLAUDE.md.bak`
3. Check for `<!-- omb:setup` version marker
4. If marker found: replace AUTO-GENERATED sections, preserve user sections
5. If no marker: append omb sections under a divider

### Step 7.2: Fill Template

Fill the template from @reference.md Section 2 with:
- `{{project_name}}` from Phase 1
- `{{project_description}}` from Phase 3 Step 3.1
- `{{tech_stack_rows}}` from scan results + Phase 3 Step 3.2
- `{{build_commands_rows}}` from scan results (stack-to-slot mapping in @reference.md Section 3)
- `{{language_conventions_sections}}` from @reference.md Section 4
- `{{linter_rows}}` from scan results
- `{{test_framework_rows}}` from scan results
- `{{project_notes}}` from Phase 3 Step 3.3

### Step 7.3: Write Confirmation

```
AskUserQuestion:
  question: "Ready to generate CLAUDE.md ({{N}} lines). Write now?"
  header: "CLAUDE.md"
  options:
    - label: "Write now (Recommended)"
      description: "Generate CLAUDE.md to project root"
    - label: "Show preview first"
      description: "Display generated content before writing"
```

If "Show preview first": display the content, then ask again to confirm write.

### Step 7.4: Write File

Write CLAUDE.md to the project root. Verify:
- [ ] Under 500 lines
- [ ] No `{{` placeholders remaining
- [ ] Contains omb Commands section with all 11 commands
- [ ] No empty `##` sections

---

## Phase 7.5: Codex CLI Integration (Optional)

Ask the user via `AskUserQuestion`:
```
Enable Codex CLI integration for code review and task delegation?
Options:
1. Yes — check installation, authenticate, and test
2. Skip — do not configure Codex
```

If the user selects **Yes**:

### Step 7.5.1: Check Installation
```bash
which codex 2>/dev/null && codex --version 2>&1
```
- If found: proceed to Step 7.5.2
- If not found: suggest `npm install -g @openai/codex` and ask to retry

### Step 7.5.2: Check Authentication
```bash
codex login status 2>&1
```
- If authenticated: proceed to Step 7.5.3
- If not: tell the user to run `codex login` or set `OPENAI_API_KEY`

### Step 7.5.3: Quick Smoke Test
```bash
codex review --help 2>&1 | head -3
```
- If the command responds: report "Codex integration complete"
- If it fails: report the error and suggest troubleshooting

After all steps pass, inform the user:
```
Codex CLI integrated successfully.
  Use: /omb codex review     — code review
  Use: /omb codex adv-review  — adversarial review
  Use: /omb codex run        — delegate tasks
```

---

## Phase 8: Git Init + Summary

### Step 8.1: Git Initialization

If `is_git_repo` is false:
```bash
git init
```

### Step 8.2: Summary

Display completion summary:

```markdown
## omb Setup Complete

| Category | Status |
|----------|--------|
| **Template** | {{template}} |
| **Project** | {{project_name}} |
| **CLAUDE.md** | {{created / updated}} ({{line_count}} lines) |
| **.omb/** | Created (plans/, todo/, interviews/) |
| **settings.json** | Updated (env + hooks) |
| **Git** | {{initialized / already initialized}} |

### Configuration

| Setting | Value |
|---------|-------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | 1 |
| `OMB_DOCUMENTATION_LANGUAGE` | {{doc_language}} |

### Next Steps

- Review the generated CLAUDE.md
- Run `omb:interview` to gather requirements for your first task
- Run `omb:plan` to create an implementation plan
- Run `omb:run` to execute the plan
```

---

## Templates

All 6 project templates are documented in @reference.md Section 1 with full directory trees, dependency lists, and configuration details.

| Template | Stack | Key Deps |
|----------|-------|----------|
| `fastapi` | Python/FastAPI | FastAPI, SQLAlchemy, Alembic, pytest |
| `react` | TypeScript/React | React, Vite, Tailwind, vitest |
| `electron` | Electron + React | Electron, electron-builder, Vite |
| `fullstack` | Monorepo | FastAPI + React + Turborepo |
| `fullstack-ai` | Full-stack AI Monorepo | FastAPI + PostgreSQL + LangGraph + React + pytest + SQLAlchemy ORM |
| `langgraph` | LangGraph single | LangGraph, LangChain, langsmith |
| `langgraph-multi` | LangGraph multi | LangGraph, orchestrator + subagents |

---

## Customization Notes

- All templates include strict type checking (strict Pyright / strict TypeScript).
- The `fullstack` template reuses `fastapi` and `react` as subdirectories with npm workspaces + Turborepo.
- The `fullstack-ai` template extends `fullstack` with a dedicated `apps/ai` LangGraph service and PostgreSQL + SQLAlchemy ORM in the API layer. Python apps (api, ai) use separate `pyproject.toml` files; the web app is managed via Turborepo.
- For Electron, the IPC layer includes a typed context bridge for safe renderer-main communication.
- Both LangGraph templates reference `omb-langchain-dependencies` for dependency versions. Model provider packages are not included by default.
- The `langgraph.json` file is required for `langgraph dev` and `langgraph build` CLI commands.

## Completion Signal

When this skill completes, report your result clearly:
- On success: State "DONE" with summary
- On failure: State "FAILED" with reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

[HARD] STOP AFTER REPORTING: After reporting, do NOT invoke the next skill or output additional commentary.
