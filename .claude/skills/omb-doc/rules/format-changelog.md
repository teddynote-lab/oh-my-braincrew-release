---
title: Per-Document Changelog
impact: MEDIUM-HIGH
tags: format, changelog, versioning
---

## Per-Document Changelog

API and database documents must include a changelog table at the bottom tracking significant changes. This provides at-a-glance history without requiring git log.

### Rules

- Required for `api/` and `database/` documents. Optional for others.
- Place the changelog as the last section before the document ends.
- Sort rows by date descending (newest first).
- Mark breaking changes explicitly with `Yes` in the Breaking column.
- Keep descriptions concise (one line).
- Include the date, what changed, and whether it is a breaking change.

**Incorrect (no changelog, or changelog with vague entries):**

```markdown
## Changelog
- Updated stuff
- Fixed things
- Changed the API
```

**Correct (structured table with specific entries):**

```markdown
## Changelog

| Date | Change | Breaking |
|------|--------|----------|
| 2026-04-10 | Add `email_verified` field to response | No |
| 2026-03-15 | Change `name` from optional to required | Yes |
| 2026-02-01 | Initial endpoint documentation | — |
```

For breaking changes, include a migration note below the table:

```markdown
> **Breaking (2026-03-15):** The `name` field is now required on `POST /api/v1/users`. Clients must include `name` in request body. Returns 400 if missing.
```
