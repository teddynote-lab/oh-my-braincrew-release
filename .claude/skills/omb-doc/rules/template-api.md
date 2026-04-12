---
title: API Endpoint Document Template
impact: HIGH
tags: template, api
---

## API Endpoint Document Template

API documentation must be precise enough for a consumer to integrate without reading source code. Every endpoint needs a method, path, purpose, request schema, response schema, and error table. Missing any of these forces the consumer to guess or read implementation code. Use this template for files under `docs/api/`.

The full template to copy and fill in:

```markdown
---
title: [Service Name] API
category: api
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: api, [domain], [version]
relates-to: src/[api/path]
depends-on: docs/architecture/[service].md
---

# [Service Name] API

## Overview

[1-2 sentences. What does this API do and who consumes it? Mention the
protocol (REST, GraphQL, etc.) and the primary data domain.]

## Base Path

```
/api/v[N]/[resource]
```

## Authentication

[Describe the auth mechanism. Examples:]
- Bearer token in `Authorization` header (JWT, scope: `[scope]`)
- API key in `X-API-Key` header
- mTLS certificate (internal services only)

All endpoints require authentication unless marked **public**.

---

## Endpoints

### [HTTP METHOD] [/path/{param}]

**Purpose:** [One sentence describing what this endpoint does.]

**Request**

```json
{
  "field_name": "string",
  "count": 0,
  "optional_field": "string | null"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `field_name` | string | yes | [Description] |
| `count` | integer | yes | [Description, valid range] |
| `optional_field` | string | no | [Description, default behavior when omitted] |

**Response** `200 OK`

```json
{
  "id": "uuid",
  "field_name": "string",
  "created_at": "2026-01-01T00:00:00Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID string | Unique identifier |
| `field_name` | string | [Description] |
| `created_at` | ISO 8601 datetime | Creation timestamp (UTC) |

**Errors**

| Status | Code | Description |
|--------|------|-------------|
| 400 | `VALIDATION_ERROR` | Request body failed schema validation |
| 401 | `UNAUTHORIZED` | Missing or expired token |
| 403 | `FORBIDDEN` | Token lacks required scope |
| 404 | `NOT_FOUND` | Resource does not exist |
| 409 | `CONFLICT` | [Resource-specific conflict description] |
| 422 | `UNPROCESSABLE` | Semantically invalid input (e.g., negative amount) |
| 500 | `INTERNAL_ERROR` | Unexpected server error |

---

### [HTTP METHOD] [/path/{param}/[sub-resource]]

[Repeat the block above for each endpoint]

---

## Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /[resource]` | [N] requests | [per minute / per hour] |
| `GET /[resource]` | [N] requests | [per minute / per hour] |
| All endpoints | [N] requests | per day per API key |

Exceeded limits return `429 Too Many Requests` with a `Retry-After` header.

## Changelog

| Date | Change | Breaking |
|------|--------|----------|
| YYYY-MM-DD | [Description of change] | yes / no |
```

---

**Incorrect (incomplete structure, no schemas, no error table):**

```markdown
---
title: User API
category: api
status: draft
created: 2026-04-10
updated: 2026-04-10
tags: api
relates-to: src/api/users
depends-on:
---

# User API

## Endpoints

### POST /users

Creates a user. Send name and email. Returns the created user.

### GET /users/{id}

Returns a user by ID. Returns 404 if not found.
```

Problems: no base path, no authentication section, no JSON request/response schemas, no field tables, no error tables, no rate limits, no changelog.

---

**Correct (all sections present with schemas and error tables):**

```markdown
---
title: User API
category: api
status: active
created: 2026-02-01
updated: 2026-04-10
tags: api, users, v1
relates-to: src/api/users
depends-on: docs/architecture/user-service.md
---

# User API

## Overview

The User API manages user accounts for the platform. It is consumed by the
web frontend, mobile clients, and internal services. All endpoints follow
REST conventions and return JSON.

## Base Path

```
/api/v1/users
```

## Authentication

Bearer token in the `Authorization` header. Token must carry the `users:read`
scope for GET endpoints and `users:write` for POST, PATCH, and DELETE.

---

## Endpoints

### POST /users

**Purpose:** Create a new user account.

**Request**

```json
{
  "email": "user@example.com",
  "display_name": "Jane Smith",
  "role": "member"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | yes | Valid email address, must be unique |
| `display_name` | string | yes | 2–100 characters |
| `role` | string | no | `member` or `admin`, defaults to `member` |

**Response** `201 Created`

```json
{
  "id": "01HZ9X2K3V4W5Y6Z7A8B9C0D",
  "email": "user@example.com",
  "display_name": "Jane Smith",
  "role": "member",
  "created_at": "2026-04-10T14:32:00Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | ULID string | Unique user identifier |
| `email` | string | Verified email address |
| `display_name` | string | User's chosen display name |
| `role` | string | Assigned role |
| `created_at` | ISO 8601 datetime | Account creation timestamp (UTC) |

**Errors**

| Status | Code | Description |
|--------|------|-------------|
| 400 | `VALIDATION_ERROR` | Request body failed schema validation |
| 401 | `UNAUTHORIZED` | Missing or expired token |
| 403 | `FORBIDDEN` | Token lacks `users:write` scope |
| 409 | `CONFLICT` | Email address is already registered |
| 500 | `INTERNAL_ERROR` | Unexpected server error |

---

### GET /users/{id}

**Purpose:** Retrieve a single user by their ID.

**Request**

No body. Path parameter:

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | ULID string | User identifier returned from POST /users |

**Response** `200 OK`

```json
{
  "id": "01HZ9X2K3V4W5Y6Z7A8B9C0D",
  "email": "user@example.com",
  "display_name": "Jane Smith",
  "role": "member",
  "created_at": "2026-04-10T14:32:00Z"
}
```

**Errors**

| Status | Code | Description |
|--------|------|-------------|
| 401 | `UNAUTHORIZED` | Missing or expired token |
| 403 | `FORBIDDEN` | Token lacks `users:read` scope |
| 404 | `NOT_FOUND` | No user with the given ID exists |
| 500 | `INTERNAL_ERROR` | Unexpected server error |

---

## Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /users` | 10 requests | per minute per API key |
| `GET /users/{id}` | 300 requests | per minute per API key |
| All endpoints | 5,000 requests | per day per API key |

Exceeded limits return `429 Too Many Requests` with a `Retry-After` header (seconds).

## Changelog

| Date | Change | Breaking |
|------|--------|----------|
| 2026-04-10 | Added `role` field to POST request and response | no |
| 2026-02-01 | Initial release | no |
```
