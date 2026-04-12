---
name: omb-doc
description: "Service documentation authoring guide — category structure, naming conventions, templates, and lifecycle rules for the docs/ folder. Load this skill when creating or updating service documentation."
user-invocable: true
argument-hint: "[--worktree] [category or document path]"
---

# Service Documentation Guide

Comprehensive guide for writing and maintaining living service documentation in `docs/`. Contains 26 rules across 5 categories covering folder structure, document templates, formatting standards, lifecycle management, and quality criteria.

## Language Setting

Check the `OMB_DOCUMENTATION_LANGUAGE` environment variable to determine document language:
- `en` (default): Write all documentation in English
- `ko`: Write documentation in Korean

This applies to: plans (`.omb/plans/`), `docs/` files, `README.md`.
Does NOT apply to: `CLAUDE.md`, `MEMORY.md` (always English).

## Argument Parsing

```
omb-doc [--worktree] [category or document path]
```

1. Check if the argument string contains `--worktree`
2. If yes: set `worktree_mode = true`, strip `--worktree` from the argument string
3. Pass the remaining string as the category or document path

## Execution Workflow

```
Step 0: Parse Arguments
Step 1: Worktree Setup (conditional — if --worktree)
Step 2: Document Authoring (existing rules below)
Step 3: Worktree Teardown (conditional — if --worktree)
```

### Step 1: Worktree Setup (conditional)

**Only execute when `worktree_mode = true`.** Follow `.claude/rules/workflow/07-worktree-protocol.md`.

<execution_order>
1. Derive branch name: `docs/{slug-from-category-or-path}`. The type defaults to `docs/` for documentation tasks.
2. Run the worktree setup script:
   ```bash
   bash .claude/hooks/omb/omb-hook.sh WorktreeSetup docs/{slug}
   ```
3. Enter the worktree and verify `pwd`:
   ```bash
   cd worktrees/docs/{slug} && pwd
   ```
4. If setup fails or `pwd` mismatches: report BLOCKED and stop.
</execution_order>

Record `worktree_active = true`, `worktree_branch`, and `worktree_path` for Step 3.

### Step 3: Worktree Teardown (conditional)

**Only execute when `worktree_active = true`.** Follow `.claude/rules/workflow/07-worktree-protocol.md`.

<execution_order>
1. Ask the user via `AskUserQuestion`:
   ```
   Documentation complete in worktree branch `{worktree_branch}`.
   Recommended action: Merge
   Options:
   1. Merge — merge changes into the original branch, then remove worktree
   2. Keep — keep worktree for manual review
   3. Discard — remove worktree and delete branch
   ```
2. Execute chosen action:
   - **Merge**: `cd {project-root} && git merge {worktree_branch}` then `bash .claude/hooks/omb/omb-hook.sh WorktreeTeardown {worktree_branch} --delete-branch`
   - **Keep**: `cd {project-root}`
   - **Discard**: `cd {project-root} && bash .claude/hooks/omb/omb-hook.sh WorktreeTeardown {worktree_branch} --delete-branch`
3. Verify return: run `pwd` and confirm CWD is back at the original project root.
</execution_order>

## When to Apply

Reference these guidelines when:
- Creating new service documentation in `docs/`
- Updating existing documentation after implementation changes
- Writing API endpoint documentation
- Documenting database schemas and migrations
- Creating architecture decision records (ADRs)
- Writing feature specifications
- Documenting deployment and infrastructure setup
- The `doc-writer` agent is invoked

## Rule Categories by Priority

| Priority | Category | Impact | Prefix | Rules |
|----------|----------|--------|--------|-------|
| 1 | Foundation | CRITICAL | `foundation-` | 4 |
| 2 | Templates | HIGH | `template-` | 11 |
| 3 | Format | MEDIUM-HIGH | `format-` | 4 |
| 4 | Lifecycle | HIGH | `lifecycle-` | 4 |
| 5 | Quality | MEDIUM | `quality-` | 3 |

## Quick Reference

### 1. Foundation (CRITICAL)

- `foundation-category-structure` — 10 category folders under `docs/` with clear ownership boundaries
- `foundation-naming-convention` — Lowercase kebab-case, topic-first, no dates in filenames
- `foundation-frontmatter` — YAML frontmatter with title, category, status, dates, tags, relates-to
- `foundation-update-protocol` — Read before writing, preserve structure, update frontmatter dates

### 2. Templates (HIGH)

- `template-architecture` — System overview, C4 diagrams, component tables, quality attributes
- `template-api` — Endpoints, request/response schemas, error codes, rate limits
- `template-database` — ERD, table definitions, indexes, constraints, migration log
- `template-backend` — Service descriptions, middleware, business logic flows
- `template-frontend` — Component hierarchy, state management, routing, design tokens
- `template-feature` — User stories, acceptance criteria, user flows, dependencies
- `template-deployment` — Docker, CI/CD, environment configs, runbooks
- `template-security` — Auth design, OWASP compliance, secret management, audit log
- `template-integration` — Third-party service contracts, webhooks, auth setup
- `template-common-rules` — Cross-cutting conventions, error handling, logging standards
- `template-adr` — Context, decision, consequences in MADR format

### 3. Format (MEDIUM-HIGH)

- `format-mermaid` — Basic diagram formatting (for comprehensive Mermaid guidance, load `omb-mermaid` skill)
- `format-code-blocks` — Language tags, file path comments, line limits
- `format-tables` — Column alignment, header conventions, when to use tables vs lists
- `format-changelog` — Per-document changelog tables with date, change, breaking flag

### 4. Lifecycle (HIGH)

- `lifecycle-create-vs-update` — When to create a new document vs update an existing one
- `lifecycle-staleness` — Detect and mark stale documents using git history
- `lifecycle-deprecation` — Mark deprecated content, link to replacement
- `lifecycle-cross-reference` — Check and maintain depends-on and relates-to links

### 5. Quality (MEDIUM)

- `quality-accuracy` — Verify code examples, commands, and file paths exist
- `quality-completeness` — All template sections filled, no placeholder text
- `quality-conciseness` — No redundant content, link instead of duplicate

## Category Index

| # | Folder | Purpose |
|---|--------|---------|
| 1 | `docs/architecture/` | System-level architecture, C4 diagrams, ADRs |
| 2 | `docs/api/` | API contracts, endpoints, error codes |
| 3 | `docs/database/` | Schemas, ERDs, migrations, Redis keys |
| 4 | `docs/backend/` | Server-side services, middleware, business logic |
| 5 | `docs/frontend/` | Components, state, routing, design system |
| 6 | `docs/features/` | Feature specs, user stories, acceptance criteria |
| 7 | `docs/deployment/` | Docker, CI/CD, environments, infra |
| 8 | `docs/security/` | Auth/authz design, OWASP, audit records |
| 9 | `docs/integrations/` | Third-party services, webhooks, OAuth |
| 10 | `docs/common-rules/` | Cross-cutting conventions, error patterns, logging |

Special files: `docs/README.md` (category index), `docs/GLOSSARY.md` (domain terms), `docs/architecture/adr/` (ADR subdirectory).

## Naming Convention Summary

- **Lowercase kebab-case**: `auth-flow.md`, `schema-users.md`
- **Topic-first**: group related files alphabetically (`payment-stripe.md`, `payment-webhook.md`)
- **No dates in filenames**: dates live in YAML frontmatter only
- **ADR exception**: `NNN-title.md` (e.g., `001-use-postgres.md`)
- **Category overview**: `_overview.md` per category (underscore sorts first)
- **Singular nouns**: `user-profile.md` not `user-profiles.md`

## How to Use

Read individual rule files for detailed templates and examples:

```
rules/foundation-category-structure.md   # Category definitions
rules/template-api.md                    # API doc template
rules/format-mermaid.md                  # Mermaid diagram guidelines
rules/lifecycle-create-vs-update.md      # When to create vs update
```

Each rule file contains:
- Explanation of the rule and why it matters
- Incorrect example with explanation
- Correct example with explanation
- Full template (for template-* rules)
