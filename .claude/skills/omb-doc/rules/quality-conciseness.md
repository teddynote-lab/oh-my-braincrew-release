---
title: Conciseness and No-Duplication
impact: MEDIUM
tags: quality, conciseness, duplication
---

## Conciseness and No-Duplication

Documentation should be concise and authoritative. Each piece of information lives in exactly one place. Link to the source of truth instead of duplicating content.

### Rules

- One source of truth per topic. If the auth flow is documented in `docs/security/auth-design.md`, other documents link to it rather than re-explaining.
- Keep documents focused. A document over 400 lines likely covers too much — consider splitting.
- Use tables over prose for structured data (config vars, error codes, endpoints).
- Avoid repeating information that is obvious from the code itself. Document the WHY, not the WHAT.
- Prefer linking: `See [Auth Design](../security/auth-design.md)` over copying the auth section.

### Link vs Duplicate Decision

| Scenario | Action |
|----------|--------|
| Exact same information needed in two places | Link to the authoritative source |
| Brief context needed before linking | 1-2 sentence summary + link |
| Information is foundational to understanding the current doc | Inline it, but note the source |

**Incorrect (duplicated content across documents):**

```markdown
# docs/api/users.md
## Authentication
Users authenticate via JWT tokens. The token is passed in the Authorization
header as Bearer token. Tokens expire after 1 hour. Refresh tokens are valid
for 30 days... (50 lines of auth explanation)

# docs/api/orders.md
## Authentication
Users authenticate via JWT tokens. The token is passed in the Authorization
header as Bearer token. Tokens expire after 1 hour. Refresh tokens are valid
for 30 days... (same 50 lines copied)
```

**Correct (single source with links):**

```markdown
# docs/api/users.md
## Authentication
Bearer JWT required. See [Auth Design](../security/auth-design.md) for token lifecycle and refresh flow.

# docs/api/orders.md
## Authentication
Bearer JWT required. See [Auth Design](../security/auth-design.md) for token lifecycle and refresh flow.
```
