---
title: Category Structure
impact: CRITICAL
tags: foundation, categories, structure
---

## Category Structure

All service documentation lives in `docs/` under exactly 10 category folders. Every document belongs to exactly one category. Choosing the right folder determines whether a document can be found by agents and humans alike — a misplaced document is effectively invisible.

The 10 categories and their ownership boundaries:

| Folder | Purpose |
|--------|---------|
| `docs/architecture/` | System-level architecture, C4 diagrams, ADRs (subdirectory: `adr/`) |
| `docs/api/` | API contracts, endpoints, request/response schemas, error codes |
| `docs/database/` | Schemas, ERDs, migrations, Redis key patterns |
| `docs/backend/` | Server-side services, middleware, business logic flows |
| `docs/frontend/` | Components, state management, routing, design system tokens |
| `docs/features/` | Feature specs, user stories, acceptance criteria |
| `docs/deployment/` | Docker, CI/CD pipelines, environments, infrastructure runbooks |
| `docs/security/` | Auth/authz design, OWASP compliance, audit records |
| `docs/integrations/` | Third-party services, webhooks, OAuth flows |
| `docs/common-rules/` | Cross-cutting conventions, error handling patterns, logging standards |

Special files that live outside category folders:

- `docs/README.md` — category index and navigation guide
- `docs/GLOSSARY.md` — domain terms and abbreviations
- Each category must contain `_overview.md` — the entry point for that category

The `docs/architecture/adr/` subdirectory is the only permitted subdirectory. All other categories are flat — no nested subdirectories.

**Incorrect (API doc placed in the backend folder):**

```
docs/
  backend/
    users-api.md        # Wrong: API contracts belong in docs/api/
    auth-middleware.md
```

**Correct (each document in its owning category):**

```
docs/
  api/
    user.md             # Correct: API contract lives in docs/api/
  backend/
    auth-middleware.md  # Correct: middleware is server-side logic
```

**Incorrect (inventing a new top-level folder):**

```
docs/
  services/             # Wrong: not one of the 10 categories
    payment-service.md
```

**Correct (route to the closest matching category):**

```
docs/
  backend/
    payment-service.md  # Correct: server-side service lives in docs/backend/
```
