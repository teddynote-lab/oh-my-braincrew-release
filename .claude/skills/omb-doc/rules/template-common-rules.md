---
title: Common Rules Document Template
impact: HIGH
tags: template, common-rules, conventions, standards
---

## Common Rules Document Template

Common rules documents record cross-cutting conventions that apply to multiple parts of the codebase: error handling patterns, logging standards, naming conventions, API contract rules, and similar standards that every engineer must follow regardless of domain. Use this template for every file in `docs/common-rules/`.

A common rules document is not a style guide or preference list. Each rule must state exactly what is required, why it exists, and how it is enforced. If there is no enforcement mechanism, the rule will be ignored.

**Incorrect (rule stated as vague preference, no enforcement, no examples):**

```markdown
---
title: Logging
status: active
---

We should log important things. Use structured logging when possible.
Try not to log sensitive data.
```

**Correct (full template with all required sections):**

```markdown
---
title: [Convention Name]
category: common-rules
status: draft | active | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: common-rules, [topic], [scope]
relates-to: src/[relevant-path]
depends-on: docs/common-rules/_overview.md
---

# [Convention Name]

## Overview

One paragraph describing what this rule governs, why it was established, and
what problem it solves. Reference the incident or code review that motivated
the rule if applicable. Readers who understand the "why" are far more likely to
follow the rule than those who are told to comply.

Example motivations to include:
- "This rule was introduced after an incident where a missing correlation ID
  made it impossible to trace a request across three services."
- "Payment team reported that inconsistent error shapes were causing the mobile
  client to silently swallow errors."

---

## Scope

State precisely which parts of the codebase and which teams this rule applies
to. Ambiguous scope is the most common reason rules are ignored.

**Applies to:**
- All FastAPI route handlers in `src/api/`
- All Celery task functions in `src/tasks/`
- All service-layer functions in `src/services/` that are called from an API boundary

**Does not apply to:**
- Internal utility functions not reachable from an API or task boundary
- Scripts in `scripts/` (use best effort)
- Test code — test helpers may use simplified patterns

---

## Rule Definition

State the rule as a clear, imperative instruction. One rule per document. If
you have multiple related rules, create multiple documents and link them.

> **[Rule stated as an imperative sentence.  Start with "Always", "Never",
> "Every X must", "Do not", etc.]**

Expand the rule with any sub-clauses needed for precision:

1. Sub-clause one: exact requirement with measurable criterion.
2. Sub-clause two: exact requirement with measurable criterion.
3. Sub-clause three: allowed exception with the condition that triggers it.

If the rule has variants by language or framework, document each:

**Python (FastAPI):** [Specific form of the rule]
**TypeScript (Express):** [Specific form of the rule]

---

## Examples

### Incorrect

Brief label describing what is wrong and why it violates the rule.

\`\`\`python
# Wrong: generic exception type loses context; string message is not parseable
@router.post("/orders")
async def create_order(payload: OrderCreate):
    try:
        result = await order_service.create(payload)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
\`\`\`

Problems with the above:
- `str(e)` may expose internal stack traces or secrets in the response body.
- `status_code=500` is hardcoded; payment failures should return 402.
- The exception is not logged, so no trace exists in the audit log.

### Correct

Brief label describing what makes this correct.

\`\`\`python
# Correct: typed exceptions, structured logging, appropriate status codes
import logging
from src.exceptions import PaymentDeclinedError, ResourceNotFoundError

logger = logging.getLogger(__name__)

@router.post("/orders")
async def create_order(payload: OrderCreate, request: Request):
    try:
        result = await order_service.create(payload)
        return result
    except PaymentDeclinedError as exc:
        logger.warning(
            "payment_declined",
            extra={"user_id": payload.user_id, "reason": exc.decline_code},
        )
        raise HTTPException(status_code=402, detail="Payment declined")
    except ResourceNotFoundError as exc:
        raise HTTPException(status_code=404, detail=exc.message)
    except Exception:
        logger.exception(
            "create_order_unexpected_error",
            extra={"user_id": payload.user_id, "request_id": request.state.request_id},
        )
        raise HTTPException(status_code=500, detail="Internal server error")
\`\`\`

Why this is correct:
- Each exception type maps to a specific HTTP status code.
- Structured log fields are machine-parseable and contain no sensitive data.
- The generic handler logs the full exception but returns a safe error message.
- `request_id` ties the log entry to the distributed trace.

---

## Exceptions

List the conditions under which this rule does not apply. If there are no
exceptions, write "None." Do not omit this section — its presence signals
that exceptions were considered.

| Situation | Exception | Approval Required |
|---|---|---|
| Background task with no HTTP context | May raise bare exceptions; caller handles | No |
| Health check endpoint (`/health`) | Return 200 or 503 only; no structured error | No |
| Third-party webhook handlers | May return 200 always to prevent provider retry storms | Yes — document in integration doc |

---

## Enforcement

State exactly how compliance with this rule is verified. "Code review" alone
is not sufficient — automated enforcement must be the primary gate.

| Layer | Tool | Configuration | Enforces |
|---|---|---|---|
| Linter (automatic) | `ruff` rule `B904` | `.ruff.toml` | Bare `raise` in except block |
| Type checker (automatic) | `mypy` | `mypy.ini` | Exception subclass hierarchy |
| CI (blocking) | `pytest` + `httpx` | `tests/test_error_handling.py` | HTTP status code mapping |
| Code review (manual) | PR checklist | `.github/pull_request_template.md` | Edge cases not caught by tools |

To run enforcement checks locally:

\`\`\`bash
# Linter
ruff check src/

# Type checker
mypy src/ --strict

# Error handling tests
pytest tests/test_error_handling.py -v
\`\`\`

If the automated checks pass but a reviewer identifies a violation in review,
file a rule improvement issue to add a new automated check.

---

## Related Rules

- [Link to related rule document](./[related-rule].md) — brief description of relationship
- [Link to related rule document](./[related-rule].md) — brief description of relationship

---

## Changelog

| Date | Change | Breaking |
|---|---|---|
| YYYY-MM-DD | Initial document | no |
```
