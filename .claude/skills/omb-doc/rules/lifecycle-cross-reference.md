---
title: Cross-Reference Maintenance
impact: HIGH
tags: lifecycle, cross-reference, links
---

## Cross-Reference Maintenance

Documents reference each other via `depends-on` frontmatter and inline links. When updating one document, check whether dependent documents need updates too.

### Types of References

| Field | Direction | Meaning |
|-------|-----------|---------|
| `relates-to` | Doc → Code | Source code paths this doc describes |
| `depends-on` | Doc → Doc | Other docs this one depends on (must be accurate for this doc to be useful) |
| Inline links | Doc → Doc | Markdown links `[text](../path.md)` within the body |

### Update Cascade

When updating a document:

1. Check if any other documents have `depends-on: {this document's path}`
   - Grep for the document's path across all `docs/**/*.md` frontmatter
2. If the change is structural (renamed sections, changed schemas, removed endpoints):
   - Update dependent documents or flag them for review
3. If the change is content-only (clarification, typo fix):
   - No cascade needed

### Rules

- Use relative paths in `depends-on`: `docs/api/users.md` not absolute paths
- Use relative markdown links in body text: `[Users API](../api/users.md)`
- When renaming a document, search for all references and update them
- When deleting/deprecating a document, check for and update all inbound references

**Incorrect (broken cross-references):**

```yaml
---
title: User Registration Feature
depends-on: docs/api/auth.md  # This file was renamed to docs/api/authentication.md
---
# References [Auth API](../api/auth.md) which no longer exists
```

**Correct (maintained cross-references):**

```yaml
---
title: User Registration Feature
depends-on: docs/api/authentication.md
---
# References [Auth API](../api/authentication.md) — updated after rename
```
