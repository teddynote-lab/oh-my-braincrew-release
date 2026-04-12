---
title: Frontmatter Schema
impact: CRITICAL
tags: foundation, frontmatter, metadata
---

## Frontmatter Schema

Every document in `docs/` must begin with YAML frontmatter. Frontmatter is the machine-readable layer that enables agents to filter, sort, and cross-reference documents without reading the full content. A document without valid frontmatter cannot be indexed.

### Required Fields

| Field | Type | Values |
|-------|------|--------|
| `title` | string | Human-readable document title |
| `category` | enum | `api` \| `database` \| `backend` \| `frontend` \| `features` \| `architecture` \| `deployment` \| `security` \| `integrations` \| `common-rules` |
| `status` | enum | `draft` \| `active` \| `deprecated` |
| `created` | ISO date | Date of first creation — never changes after set |
| `updated` | ISO date | Date of last update — must be updated on every change |
| `tags` | comma-separated | Keywords for Grep discovery — at least 2 |

### Optional Fields

| Field | Type | Purpose |
|-------|------|---------|
| `author` | string | Who created or last updated (e.g. `agent:doc-writer`) |
| `relates-to` | comma-separated paths | Source code paths this document describes |
| `depends-on` | comma-separated paths | Other docs this document depends on for accuracy |
| `stale-since` | ISO date | Set when staleness is detected; cleared when resolved |

### Full Template

```yaml
---
title: User Profile API
category: api
status: active
created: 2026-04-10
updated: 2026-04-10
tags: user, profile, rest
author: agent:doc-writer
relates-to: src/api/routes/user.py, src/api/schemas/user.py
depends-on: docs/database/schema-user.md
---
```

**Incorrect (no frontmatter):**

```markdown
# User Profile API

GET /api/v1/users/{id} returns the user profile.
```

Why this fails: agents cannot determine this document's category, status, or staleness date without reading the full content. It will be skipped during indexed lookups.

**Correct (complete frontmatter before content):**

```markdown
---
title: User Profile API
category: api
status: active
created: 2026-04-10
updated: 2026-04-10
tags: user, profile, rest
---

# User Profile API

GET /api/v1/users/{id} returns the user profile.
```

---

**Incorrect (missing required fields, wrong enum value):**

```yaml
---
title: Payment Webhook
category: webhooks       # Wrong: not a valid category enum value
updated: 2026-04-10      # Missing: created, status, tags
---
```

**Correct (all required fields, valid enum):**

```yaml
---
title: Payment Webhook
category: integrations
status: draft
created: 2026-04-10
updated: 2026-04-10
tags: payment, webhook, stripe
---
```
