---
title: Naming Convention
impact: CRITICAL
tags: foundation, naming, files
---

## Naming Convention

All filenames in `docs/` are lowercase kebab-case, topic-first, singular nouns, with no dates. Consistent filenames make documents findable by glob patterns, prevent duplicates, and group related files alphabetically in directory listings.

Rules at a glance:

| Rule | Rationale |
|------|-----------|
| Lowercase kebab-case only | Prevents case-sensitivity bugs across OS and tools |
| No category prefix in the filename | The folder is the category — `docs/api/user.md` not `docs/api/api-user.md` |
| Topic-first for subtopics | Groups related files: `auth-flow.md`, `auth-middleware.md`, `auth-rbac.md` |
| No dates in filenames | Dates belong in YAML frontmatter `created:` and `updated:` fields |
| Singular nouns | `user-profile.md` not `user-profiles.md` |
| `_overview.md` per category | Underscore prefix sorts first in every directory listing |
| ADR exception: `NNN-title.md` | Sequential numbering enables ordering: `001-use-postgres.md` |

Glob patterns that must resolve correctly under these rules:

```
docs/api/*.md                    # All API documents
docs/database/schema-*.md        # All schema files
docs/**/_overview.md             # Every category overview
docs/architecture/adr/???.md     # All ADRs
```

**Incorrect (date in filename, plural noun, category prefix repeated):**

```
docs/api/2026-04-10-user-profiles-api.md
```

Why this fails:
- `2026-04-10` — date belongs in frontmatter, not the filename
- `user-profiles` — plural; use the singular `user-profile`
- `-api` suffix — the `docs/api/` folder already provides this context

**Correct (topic-first, singular, no date, no redundant prefix):**

```
docs/api/user-profile.md
```

---

**Incorrect (no topic grouping, category prefix repeated in name):**

```
docs/backend/
  middleware.md
  api-auth-middleware.md
  logging-middleware.md
```

**Correct (topic-first grouping, prefix removed):**

```
docs/backend/
  _overview.md
  middleware-auth.md
  middleware-logging.md
```

---

**Incorrect (ADR without sequential number):**

```
docs/architecture/adr/use-postgres.md
```

**Correct (ADR with three-digit sequential prefix):**

```
docs/architecture/adr/001-use-postgres.md
```
