---
title: Staleness Detection
impact: HIGH
tags: lifecycle, staleness, freshness
---

## Staleness Detection

Documents become stale when the code they describe changes but the document does not. Detect and mark stale documents to prevent misleading information.

### Detection Method

A document is potentially stale when:
1. The `updated` date is 30+ days old, AND
2. The files in `relates-to` have git commits since the `updated` date

Check with: `git log --since="{updated date}" -- {relates-to paths}`

If commits exist, the document may be stale.

### Marking Stale Documents

Add to frontmatter:
```yaml
stale-since: 2026-04-10
```

Add a banner at the top of the document body (after frontmatter):

```markdown
> **STALE:** This document has not been updated since 2026-03-01. The related code at `src/services/auth.py` has changed. Review needed.
```

### Resolution

- If the document is still accurate: remove the `stale-since` field and banner, update the `updated` date
- If the document needs updates: update the content, remove the stale marker, update the `updated` date
- If the document is no longer relevant: set `status: deprecated`

**Incorrect (silently stale document):**

```yaml
---
title: Auth Service
updated: 2025-12-15
relates-to: src/services/auth.py
---
# Auth Service
Uses basic token authentication...
# (Code was refactored to OAuth2 in January, but doc was never updated)
```

**Correct (stale document properly marked):**

```yaml
---
title: Auth Service
updated: 2025-12-15
stale-since: 2026-04-10
relates-to: src/services/auth.py
---
> **STALE:** This document has not been updated since 2025-12-15. The related code at `src/services/auth.py` has 12 commits since then. Review needed.

# Auth Service
Uses basic token authentication...
```
