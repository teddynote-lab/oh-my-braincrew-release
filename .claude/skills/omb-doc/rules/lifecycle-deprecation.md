---
title: Deprecation Protocol
impact: HIGH
tags: lifecycle, deprecation, versioning
---

## Deprecation Protocol

When content is replaced, outdated, or removed, follow a structured deprecation process. Never silently delete documentation — mark it deprecated and link to the replacement.

### Document-Level Deprecation

Set `status: deprecated` in frontmatter and add a banner:

```yaml
---
title: Users API (v1)
status: deprecated
---
> **DEPRECATED:** This API version is deprecated as of 2026-04-01. See [Users API v2](../api/users-v2.md) for the current version.
```

### Section-Level Deprecation

For deprecated sections within an active document, use a blockquote:

```markdown
> **DEPRECATED (2026-04-01):** This authentication method is no longer supported. Use OAuth2 instead. See [Auth Design](../security/auth-design.md).
```

### ADR Deprecation

ADRs are immutable once accepted. To supersede:
1. Create a new ADR referencing the old one
2. Update the old ADR frontmatter: `status: superseded`, `superseded-by: docs/architecture/adr/NNN-new.md`
3. Update the new ADR frontmatter: `supersedes: docs/architecture/adr/NNN-old.md`

### Rules

- Never delete documentation without a replacement in place
- Always link to the replacement in the deprecation banner
- Keep deprecated documents accessible for historical reference
- Remove deprecated documents only after 90 days AND confirmation that no references remain

**Incorrect (silent deletion):**

```markdown
# Deleted docs/api/users-v1.md without any trace
# Team members still referencing the old URL get 404
```

**Correct (structured deprecation):**

```markdown
# docs/api/users-v1.md still exists with:
# status: deprecated
# Banner pointing to docs/api/users-v2.md
# Will be removed after 90 days if no remaining references
```
