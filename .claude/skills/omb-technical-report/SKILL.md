---
name: omb-technical-report
user-invocable: true
description: >
  Use when analyzing a target project's codebase and generating comprehensive
  technical reports as per-domain markdown files. Covers architecture, features,
  API specs, DB schemas, infra, security, risks, and lessons learned.
  Triggers on: technical-report, tech report, codebase analysis, project report,
  analyze architecture, generate technical docs, project analysis, codebase report.
argument-hint: "[path-to-target-project]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, AskUserQuestion, Skill
---

# Technical Report Generator

Analyze a target project's codebase and generate comprehensive per-domain technical reports as structured markdown files.

<references>
- `${CLAUDE_SKILL_DIR}/reference.md` § 1 — Explorer prompt templates
- `${CLAUDE_SKILL_DIR}/reference.md` § 2 — Clustering rules
- `${CLAUDE_SKILL_DIR}/reference.md` § 3 — Document templates (per-category)
- `${CLAUDE_SKILL_DIR}/reference.md` § 4 — Mermaid diagram templates
- `${CLAUDE_SKILL_DIR}/reference.md` § 5 — Risk matrix template (P0-P3)
- `${CLAUDE_SKILL_DIR}/reference.md` § 6 — Master document template (PROJECT-REPORT.md)
- `${CLAUDE_SKILL_DIR}/reference.md` § 7 — Doc-writer agent prompt template
- `${CLAUDE_SKILL_DIR}/TECH-REPORT-CHECKLIST.md` — Checklist template for TODO tracking
</references>

<completion_criteria>
The report is complete when ALL of these hold:
- All confirmed sub-domain documents generated in `docs/technical-report/<domain>/`
- Master document `docs/technical-report/PROJECT-REPORT.md` created with links to all sub-docs
- Minimum 3 review iterations completed with themed focus
- `.omb/technical-report/REPORT-JOB-TODO.md` shows all critical items checked
- Each `.md` file is under 500 lines

Status codes: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT
</completion_criteria>

<scope_boundaries>
This skill generates technical reports — it does NOT:
- Modify application source code
- Create or execute plans
- Run tests or verification
- Make architecture decisions or refactoring suggestions that require code changes
</scope_boundaries>

---

## Step 0 — Target Resolution & Language

### 0.1 Resolve Target Project

Parse `$ARGUMENTS` for the target project path.

- If `$ARGUMENTS` contains a path: validate it exists and contains code files
- If `$ARGUMENTS` is empty or ambiguous: use `AskUserQuestion` to get the target path
- If path is `.` or not specified: use the current working directory

### 0.2 Gather Project Context

Before any code exploration, read existing project-level documentation to build foundational context. This context is passed to all explorer agents so they understand the project's purpose, architecture decisions, and conventions upfront — producing more accurate and relevant findings.

**Read in order (stop at first found for each):**

1. **PROJECT.md** at `{TARGET_PATH}/PROJECT.md` — project overview, goals, architecture summary
2. **CLAUDE.md** at `{TARGET_PATH}/CLAUDE.md` — development conventions, tech stack rules, agent instructions
3. **README.md** at `{TARGET_PATH}/README.md` (fallback) — if neither PROJECT.md nor CLAUDE.md exists

For each file found, extract:
- Project name and purpose
- Tech stack declarations
- Architecture overview or key design decisions
- Team conventions or constraints
- Any domain-specific terminology

Store the combined context as `PROJECT_CONTEXT` — a structured summary (max ~2000 words) passed to every explorer and doc-writer agent prompt. If no project docs exist, set `PROJECT_CONTEXT` to empty and proceed (the explorers will infer from code).

### 0.3 Detect Tech Stack (augmented by PROJECT_CONTEXT)

Scan the target project root for tech stack indicators:

```bash
ls {TARGET_PATH}/package.json {TARGET_PATH}/pyproject.toml {TARGET_PATH}/go.mod \
   {TARGET_PATH}/Cargo.toml {TARGET_PATH}/pom.xml {TARGET_PATH}/build.gradle \
   {TARGET_PATH}/Gemfile {TARGET_PATH}/composer.json 2>/dev/null
```

Also check for framework-specific markers: `next.config.*`, `vite.config.*`, `manage.py`, `Dockerfile`, `.github/workflows/`, etc.

### 0.4 Ask Language Preference

Use `AskUserQuestion`:

> Which language should the technical reports be written in?
> 1. Korean (한국어) — recommended
> 2. English
> 3. Japanese (日本語)
> 4. Chinese (中文)
> 5. Other (please specify)

Store the chosen language as `REPORT_LANGUAGE` — pass it to ALL subsequent agent prompts.

### 0.5 Initialize Output & TODO

```bash
mkdir -p docs/technical-report
mkdir -p .omb/technical-report
```

If `.omb/technical-report/REPORT-JOB-TODO.md` already exists (previous run), read it and append a new section:
```markdown
---
## Run: {YYYY-MM-DD HH:MM} (Incremental Update)
```

If it does not exist, copy the template:
```bash
cp ${CLAUDE_SKILL_DIR}/TECH-REPORT-CHECKLIST.md .omb/technical-report/REPORT-JOB-TODO.md
```

Update the TODO header with: target path, detected tech stack, language preference, timestamp.

---

## Step 1 — Code Explorer

Spawn 5-7 parallel explore agents in a single `Agent()` batch. Each agent scopes to a specific domain. Use `subagent_type: "explore"` with `model: "haiku"` for all.

**Conditional spawning** — only spawn explorers for detected domains:
- **Backend Explorer**: spawn if `.py`, `.go`, `.java`, `.rb` files exist in service/API directories
- **Frontend Explorer**: spawn if `.tsx`, `.jsx`, `.vue`, `.svelte` files exist
- **API Explorer**: always spawn (looks for route definitions, OpenAPI specs, middleware)
- **DB Explorer**: spawn if migration files, schema files, or ORM models exist
- **Infra Explorer**: spawn if `Dockerfile`, `docker-compose*`, `.github/workflows/`, terraform files exist
- **Security Explorer**: always spawn (looks for auth, middleware, secrets, dependency manifests)
- **General Explorer**: always spawn (project structure, config, dependencies, README)

Each explorer receives a prompt from `${CLAUDE_SKILL_DIR}/reference.md` § 1, parameterized with:
- `{TARGET_PATH}`: the target project root
- `{REPORT_LANGUAGE}`: the chosen language

Each explorer is capped at **20 findings** with file:line evidence.

Update TODO: check off "Code Exploration" items for each domain explored.

---

## Step 2 — Knowledge Clustering

Take all explorer findings and cluster them into document categories using rules from `${CLAUDE_SKILL_DIR}/reference.md` § 2.

**Default categories** (auto-detected — skip empty ones):

| Category | Directory Name | Content |
|----------|---------------|---------|
| Architecture | `architecture/` | System design, component relationships, design patterns, data flow |
| Backend | `backend/` | Service architecture, business logic, middleware patterns |
| Frontend | `frontend/` | UI components, state management, routing, build system |
| API | `api/` | Endpoint inventory, request/response specs, auth, error handling |
| Database | `database/` | Schema design, ER diagrams, migrations, query patterns |
| Infrastructure | `infrastructure/` | Deployment topology, CI/CD, containerization, monitoring |
| Security | `security/` | Auth flows, secret management, OWASP considerations, dependency audit |
| Features | `features/` | Feature definitions, operation flows, user journeys |
| Lessons Learned | `lessons-learned/` | Code patterns, anti-patterns, improvement opportunities |
| Risks | `risks/` | P0-P3 risk matrix, mitigation strategies, improvement roadmap |

For each category: compile relevant findings, file paths, code snippets, and relationships.

---

## Step 3 — User Confirmation (AskUserQuestion)

Present the proposed document structure to the user:

> Based on codebase analysis, I propose these report documents:
>
> 1. **architecture/** — System design, {N} components found, {N} patterns identified
> 2. **backend/** — {N} services, middleware patterns, error handling
> 3. **api/** — {N} endpoints found, auth patterns
> [... list all non-empty categories ...]
>
> Would you like to:
> - Approve this structure as-is
> - Merge categories (e.g., combine backend + api)
> - Split a category (e.g., separate auth from security)
> - Add a custom category
> - Remove a category

Apply user modifications. Update the TODO with the confirmed categories.

---

## Step 4 — TOC Proposal (AskUserQuestion)

For each confirmed category, generate a proposed Table of Contents based on the clustered findings. Then ask the user:

> Here are the proposed tables of contents for each document:
>
> **architecture/**
> - 01-system-overview.md — Overall architecture, tech stack summary
> - 02-component-relationships.md — Component diagram (mermaid), dependencies
> - 03-data-flow.md — Data flow between components
>
> **api/**
> - 01-endpoint-inventory.md — All endpoints with methods, paths, auth requirements
> - 02-request-response-specs.md — Detailed request/response schemas
> [...]
>
> Additionally:
> - **API spec depth**: Summary only / Full request-response shapes / Including examples?
> - **Mermaid diagrams**: Include in all relevant docs / Only architecture overview?
> - **Risk detail level**: Summary matrix only / Detailed per-risk analysis?

Apply user preferences. Update the TODO with confirmed TOCs.

---

## Step 5 — Draft & Feedback

For each confirmed document, generate a brief **outline draft** (not full content) showing:
- Section headers
- Key bullet points per section
- Placeholder mermaid diagram descriptions
- Key findings that will be expanded

Present all outlines to the user via output text (not AskUserQuestion — just show them). Then use `AskUserQuestion`:

> I've shown the draft outlines above. Please review and provide feedback:
> - Any sections to add, remove, or restructure?
> - Any emphasis areas (more detail on X, less on Y)?
> - Ready to proceed with full document generation?

Iterate max 2 feedback rounds. Update the TODO after each round.

---

## Step 6 — Parallel Document Generation

Spawn doc-writer agents in parallel, one per confirmed category. Use `Agent()` with `subagent_type: "doc-writer"`.

**Model routing:**
- `model: "sonnet"` for: architecture, risks, lessons-learned, security (need deeper analysis)
- `model: "haiku"` for: all other categories (straightforward documentation)

Each agent receives a prompt from `${CLAUDE_SKILL_DIR}/reference.md` § 7, parameterized with:
- `{CATEGORY}`: the category name
- `{TOC}`: the confirmed table of contents for this category
- `{FINDINGS}`: the clustered findings for this category
- `{TARGET_PATH}`: the target project root
- `{REPORT_LANGUAGE}`: the chosen language
- `{OUTPUT_DIR}`: `docs/technical-report/{category}/`

**Document constraints:**
- Each `.md` file: max 500 lines — if content exceeds, split into additional numbered files
- Numbering: book-style sequential (`01-`, `02-`, `03-`, ...)
- Include mermaid diagrams where relevant (use templates from reference.md § 4)
- Include risk callouts where relevant (use templates from reference.md § 5)

### 6.1 Generate Master Document

After all category agents complete, create `docs/technical-report/PROJECT-REPORT.md` using the template from `${CLAUDE_SKILL_DIR}/reference.md` § 6.

The master document contains:
- Project name and overview (2-3 paragraphs)
- Tech stack summary table
- Architecture overview mermaid diagram (high-level system diagram)
- Key features summary with brief descriptions
- Risk summary (P0-P3 counts)
- Document index table with relative links to all sub-domain docs:

```markdown
| # | Domain | Documents | Description |
|---|--------|-----------|-------------|
| 1 | Architecture | [01-system-overview](architecture/01-system-overview.md), ... | System design and patterns |
| 2 | API | [01-endpoint-inventory](api/01-endpoint-inventory.md), ... | API design and specs |
```

Update the TODO: check off all "Document Generation" items.

---

## Step 7 — Iterative Review & Improvement

Run a themed review-improve loop. Each iteration focuses on a **different review theme**. Minimum 3 iterations, maximum 7.

| Iteration | Theme | Review Focus | Agent | Model |
|-----------|-------|-------------|-------|-------|
| 1 | Architecture | System design accuracy, component relationships, mermaid diagram correctness, missing architectural patterns | critic | sonnet |
| 2 | Features | Feature completeness, operation flow accuracy, missing feature definitions, user flow gaps | reviewer | sonnet |
| 3 | API | Endpoint coverage, request/response spec accuracy, missing error codes, auth pattern gaps | api-specialist | sonnet |
| 4 | Database & Infra | Schema accuracy, migration coverage, deployment topology, CI/CD gaps | db-specialist | sonnet |
| 5 | Security & Risks | Risk matrix completeness, missing P0/P1 risks, security gap analysis, improvement roadmap quality | security-reviewer | sonnet |
| 6 | Lessons Learned | Code pattern accuracy, anti-pattern coverage, improvement suggestion quality, cross-domain insights | reviewer | opus |
| 7 | Final Polish | Cross-document consistency, link integrity, mermaid rendering, numbering correctness, 500-line limit compliance | reviewer | haiku |

### Per-iteration workflow

**7.1 Review**: Spawn the themed reviewer agent (using `Agent()` with the specified `subagent_type` and `model`) to audit all generated docs from that theme's perspective. The agent receives:
- All generated `.md` files in `docs/technical-report/`
- The original explorer findings for cross-reference
- The `REPORT_LANGUAGE` setting
- Instructions to report findings as: `{severity: critical|important|minor, file, section, issue, suggestion}`

**7.2 Identify**: Compile the agent's findings into a structured list with severity levels.

**7.3 Improve**: For each critical/important finding, spawn a doc-writer agent to fix the issue. Minor findings are logged but not necessarily fixed.

**7.4 TODO Check**: Read `.omb/technical-report/REPORT-JOB-TODO.md`:
- Mark completed items as checked `[x]`
- Add any new items discovered during review
- Write the updated TODO back
- Log the iteration results: `## Iteration {N}: {THEME} — {findings_count} findings, {fixed_count} fixed`

**7.5 Gate Check**:
- Iterations 1-3: always continue to next iteration
- Iterations 4+: if review finds 0 critical/important issues AND all critical TODO items are checked → terminate early
- Iteration 7: always terminate — report any remaining issues in completion summary

---

## Completion

After the review loop completes:

1. Read the final TODO and summarize status
2. Report to user:
   - Total documents generated (count, total lines)
   - Review iterations completed
   - Remaining issues (if any, from final iteration)
   - Path to master document: `docs/technical-report/PROJECT-REPORT.md`

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately. Do NOT invoke the next skill or output additional commentary. The pipeline system handles step transitions.
