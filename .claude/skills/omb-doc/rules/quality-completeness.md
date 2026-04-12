---
title: Completeness Check
impact: MEDIUM
tags: quality, completeness, template
---

## Completeness Check

Every document must fill all required template sections. Placeholder text, empty sections, and TODO markers indicate an incomplete document.

### Rules

- All required sections from the category template must be present
- No placeholder text: `[TODO]`, `TBD`, `...`, `Lorem ipsum`
- No empty tables (headers with no rows)
- No empty code blocks
- Frontmatter must have all required fields filled (not `title: ""`)
- If a section genuinely does not apply, replace it with: `N/A — [brief reason]`

### Completeness by Status

| Status | Completeness Requirement |
|--------|------------------------|
| `draft` | Frontmatter complete, at least Overview section filled, other sections may have `[DRAFT]` markers |
| `active` | All template sections filled, no placeholders, all examples verified |
| `deprecated` | Deprecation banner present, link to replacement |

**Incorrect (incomplete active document):**

```yaml
---
title: Payment API
status: active
---
# Payment API

## Overview
TODO: describe the payment API

## Endpoints
| Method | Path | Description |
|--------|------|-------------|

## Rate Limits
TBD
```

**Correct (complete active document):**

```yaml
---
title: Payment API
status: active
created: 2026-04-10
updated: 2026-04-10
tags: api, payment, stripe
relates-to: src/routes/payment.py
---
# Payment API

## Overview
Handles payment processing via Stripe integration.

## Endpoints
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/payments | Create a payment intent |
| GET | /api/v1/payments/:id | Get payment status |

## Rate Limits
| Endpoint | Limit | Window |
|----------|-------|--------|
| POST /api/v1/payments | 100 | 1 minute |
```
