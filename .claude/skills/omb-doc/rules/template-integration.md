---
title: Integration Document Template
impact: HIGH
tags: template, integration, third-party, webhook
---

## Integration Document Template

Integration documents record how the service connects to a third-party provider: authentication setup, endpoints consumed, webhook configuration, data mapping, and error handling. Use this template for every file in `docs/integrations/`.

Integration docs have two audiences: an engineer setting up the integration for the first time and an on-call engineer debugging a production failure at midnight. Both must be able to work through the document without access to Slack or a subject-matter expert.

**Incorrect (provider named but no auth details, no error codes, no data mapping):**

```markdown
---
title: Stripe
status: active
---

We use Stripe for payments. See the Stripe docs for details.
The webhook endpoint is `/api/webhooks/stripe`.
```

**Correct (full template with all required sections):**

```markdown
---
title: [Provider Name] Integration
category: integrations
status: draft | active | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: integration, [provider-name], [capability]
relates-to: src/integrations/[provider-name]
depends-on: docs/integrations/_overview.md
---

# [Provider Name] Integration

## Overview

One paragraph describing what this integration does for the product, which
provider is used, and what the integration enables (e.g., "Stripe handles
payment processing and subscription billing; we use their Payment Intents API
to accept cards and their Billing API to manage recurring subscriptions").

Also note the integration's operational criticality: is it on the critical path
(service degrades without it) or a best-effort enhancement?

---

## Service Details

| Property | Value |
|---|---|
| Provider | [Provider Name] |
| API version | `v[N]` (pinned; see note below) |
| Official docs | [https://docs.provider.example/api](https://docs.provider.example/api) |
| SDK / library | `[package-name] >= [version]` |
| Status page | [https://status.provider.example](https://status.provider.example) |
| Support contact | support@provider.example / Slack `#[provider]-support` |
| Current status | Active / Deprecated / Under evaluation |
| Environments | Sandbox (testing), Production |

**API version pinning:** We pin to `v[N]` and review upgrade notices quarterly.
The provider's deprecation policy gives 12 months notice before removing a
version. Track upgrades in the changelog at the bottom of this document.

---

## Authentication

Document exactly how the service authenticates with the provider, where
credentials are stored, and how they are loaded at runtime.

### Method: [API Key / OAuth 2.0 / Mutual TLS / HMAC Signature]

\`\`\`python
# src/integrations/[provider_name]/client.py
import os
import [provider_sdk]

client = [provider_sdk].Client(
    api_key=os.environ["[PROVIDER]_API_KEY"],  # loaded from AWS Secrets Manager
    timeout=10,
)
\`\`\`

| Credential | Environment Variable | Secret Path | Rotation Period |
|---|---|---|---|
| API key (production) | `[PROVIDER]_API_KEY` | `/[svc]/production/[PROVIDER]_API_KEY` | 90 days |
| API key (staging) | `[PROVIDER]_API_KEY` | `/[svc]/staging/[PROVIDER]_API_KEY` | 90 days |
| Webhook secret | `[PROVIDER]_WEBHOOK_SECRET` | `/[svc]/production/[PROVIDER]_WEBHOOK_SECRET` | On rotation |

**Obtaining credentials:**
1. Log in to [Provider dashboard](https://dashboard.provider.example).
2. Navigate to Settings > API Keys.
3. Generate a restricted key with only the permissions listed in the Endpoints
   table below.
4. Store in AWS Secrets Manager using the path above.

---

## Endpoints Used

List only the endpoints this integration actively calls. Do not list every
available endpoint — only what the code uses.

| Endpoint | Method | Purpose | Rate Limit | Timeout |
|---|---|---|---|---|
| `/v1/[resource]` | POST | Create a new resource | 100 req/min | 10s |
| `/v1/[resource]/{id}` | GET | Fetch resource by ID | 500 req/min | 5s |
| `/v1/[resource]/{id}` | PATCH | Update resource fields | 100 req/min | 10s |
| `/v1/[resource]/{id}` | DELETE | Soft-delete a resource | 50 req/min | 10s |
| `/v1/[report-type]` | GET | Pull usage/billing report | 10 req/min | 30s |

**Rate limit handling:** We use exponential backoff with jitter starting at 1s,
doubling to a maximum of 32s, with a maximum of 5 retries. After 5 retries the
request is dead-lettered to SQS for manual review.

\`\`\`python
# src/integrations/[provider_name]/retry.py
from tenacity import retry, stop_after_attempt, wait_exponential_jitter

@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential_jitter(initial=1, max=32),
    reraise=True,
)
async def call_with_retry(func, *args, **kwargs):
    return await func(*args, **kwargs)
\`\`\`

---

## Webhook Configuration

Complete this section only if the provider sends events to the service via
webhooks. Delete it if the integration is outbound-only.

### Registered Endpoints

| Environment | Webhook URL | Registered Events |
|---|---|---|
| Production | `https://[domain]/api/webhooks/[provider]` | `[event.created]`, `[event.updated]`, `[event.failed]` |
| Staging | `https://staging.[domain]/api/webhooks/[provider]` | All events |

### Signature Verification

The service verifies every incoming webhook using HMAC-SHA256. Requests failing
verification are rejected with `400 Bad Request` and logged.

\`\`\`python
# src/api/webhooks/[provider_name].py
import hmac
import hashlib
import os

def verify_webhook(payload: bytes, signature_header: str) -> bool:
    secret = os.environ["[PROVIDER]_WEBHOOK_SECRET"].encode()
    expected = hmac.new(secret, payload, hashlib.sha256).hexdigest()
    received = signature_header.removeprefix("[Provider]-Signature-256=")
    return hmac.compare_digest(expected, received)
\`\`\`

### Events Handled

| Event | Handler | Action Taken |
|---|---|---|
| `[resource].created` | `handle_resource_created` | Create local record, emit `ResourceCreated` domain event |
| `[resource].updated` | `handle_resource_updated` | Sync local record with provider state |
| `[resource].failed` | `handle_resource_failed` | Mark record failed, notify user, trigger retry |
| `[subscription].cancelled` | `handle_subscription_cancelled` | Downgrade account, send cancellation email |

---

## Data Mapping

Document every field transformation between the provider's data model and the
service's internal domain model. This is critical for debugging data
inconsistencies.

| Our Field | Their Field | Type | Transform |
|---|---|---|---|
| `user.external_id` | `customer.id` | `string` | Stored as-is |
| `order.amount_cents` | `charge.amount` | `integer` | Provider uses smallest currency unit; no conversion needed |
| `order.currency` | `charge.currency` | `string` | Uppercase to lowercase: `"USD"` → `"usd"` |
| `order.status` | `charge.status` | `enum` | See status map below |
| `order.paid_at` | `charge.created` | `datetime` | Unix timestamp → ISO 8601 UTC |
| `product.provider_id` | `price.id` | `string` | Stored as-is; used for checkout session creation |

**Status mapping:**

| Provider Status | Our Status | Notes |
|---|---|---|
| `succeeded` | `paid` | |
| `pending` | `processing` | Polling not required; provider sends webhook on resolution |
| `failed` | `failed` | Retry window: 3 days |
| `refunded` | `refunded` | Partial refunds use `partially_refunded` |
| `disputed` | `disputed` | Requires manual review |

---

## Error Handling

Document provider-specific error codes and how the service responds to each.
Generic network errors (timeouts, 5xx) are handled by the retry policy above.

| Error Code | HTTP Status | Meaning | Our Response |
|---|---|---|---|
| `invalid_api_key` | 401 | API key is wrong or revoked | Log CRITICAL, alert on-call, halt all requests |
| `rate_limit_exceeded` | 429 | Too many requests | Backoff and retry (see retry policy) |
| `resource_not_found` | 404 | Resource does not exist on provider | Return 404 to caller; do not retry |
| `invalid_request` | 400 | Malformed request body | Log ERROR with request details; do not retry |
| `idempotency_error` | 400 | Same idempotency key, different params | Log WARNING; return original response |
| `[provider_specific]` | 402 | [Provider-specific meaning] | [How we handle it] |

**Idempotency:** All POST requests include an `Idempotency-Key` header set to
the internal operation ID. This prevents duplicate charges if a request is
retried after a network timeout.

\`\`\`python
response = client.post(
    "/v1/[resource]",
    json=payload,
    headers={"Idempotency-Key": str(operation.id)},
)
\`\`\`

---

## Testing

### Sandbox Environment

| Property | Value |
|---|---|
| Base URL | `https://api.sandbox.provider.example` |
| Dashboard | `https://dashboard.sandbox.provider.example` |
| Test API key variable | `[PROVIDER]_API_KEY` (use sandbox value in `.env.test`) |
| Test card numbers | See [provider test cards doc](https://docs.provider.example/testing) |

### Local Webhook Testing

Use the provider's CLI to forward webhooks to localhost during development:

\`\`\`bash
# Install provider CLI
brew install [provider]-cli

# Forward events to local dev server
[provider] listen --forward-to localhost:8000/api/webhooks/[provider]
\`\`\`

### Key Test Cases

- [ ] Successful payment flow end-to-end
- [ ] Payment failure (use test card `4000000000000002`)
- [ ] Webhook delivery and signature verification
- [ ] Rate limit retry behavior (use sandbox rate limit trigger)
- [ ] Idempotency key deduplication

---

## Changelog

| Date | Change | Breaking |
|---|---|---|
| YYYY-MM-DD | Initial document | no |
```
