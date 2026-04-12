---
title: Security Document Template
impact: HIGH
tags: template, security, auth, compliance
---

## Security Document Template

Security documents record how a service authenticates users, authorizes access, protects data, manages secrets, and responds to incidents. They are required for every service that handles user data or sits behind an authentication boundary.

A security doc serves three purposes: onboarding new engineers to the auth model, satisfying compliance reviewers, and guiding incident responders. Write it so that a security engineer unfamiliar with the service can reconstruct the threat model from the document alone.

**Incorrect (no auth flow, no threat model, no actionable incident response):**

```markdown
---
title: Security Notes
status: active
---

We use JWT tokens for auth. Secrets are in environment variables.
Contact the backend team if there's an incident.
```

**Correct (full template with all required sections):**

```markdown
---
title: [Service Name] Security
category: security
status: draft | active | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: security, auth, [service-name]
relates-to: src/[auth-path]
depends-on: docs/security/_overview.md
---

# [Service Name] Security

## Overview

One paragraph describing the service's security posture: what data it handles
(PII, financial, health, public), which authentication mechanism it uses, what
regulatory requirements apply (GDPR, SOC 2, HIPAA), and the primary threat
actors being defended against (unauthenticated external, authenticated insider,
compromised dependency).

---

## Authentication Flow

<!-- Sequence diagram showing the full login and token lifecycle.
     Include every actor: user, browser, API, identity provider, token store. -->

\`\`\`mermaid
sequenceDiagram
    participant U as User
    participant FE as Frontend
    participant API as API Gateway
    participant IDP as Identity Provider (Auth0)
    participant DB as User DB

    U->>FE: Submit credentials
    FE->>IDP: POST /oauth/token {email, password}
    IDP-->>FE: {access_token, refresh_token, expires_in}
    FE->>FE: Store access_token in memory,<br/>refresh_token in httpOnly cookie

    U->>FE: Request protected resource
    FE->>API: GET /resource<br/>Authorization: Bearer {access_token}
    API->>IDP: GET /userinfo (verify token)
    IDP-->>API: {sub, email, roles}
    API->>DB: Fetch resource by user ID
    DB-->>API: Resource data
    API-->>FE: 200 OK {resource}

    Note over FE,API: Token refresh flow
    FE->>IDP: POST /oauth/token {grant_type: refresh_token}
    IDP-->>FE: New {access_token, refresh_token}
\`\`\`

**Token properties:**

| Property | Value | Rationale |
|---|---|---|
| Access token lifetime | 15 minutes | Short-lived to limit blast radius |
| Refresh token lifetime | 7 days | Balanced UX vs. security |
| Storage (access token) | In-memory only | Prevents XSS token theft |
| Storage (refresh token) | httpOnly cookie | Prevents JS access |
| Algorithm | RS256 | Asymmetric; verify without private key |

---

## Authorization Model

<!-- Document the roles/permissions model. Use RBAC or ABAC.
     Every permission must map to a concrete API action. -->

### Roles and Permissions (RBAC)

| Role | Permissions | Description |
|---|---|---|
| `anonymous` | `read:public` | Unauthenticated users; read-only public content |
| `member` | `read:own`, `write:own`, `delete:own` | Authenticated users; own resources only |
| `moderator` | `member` + `read:all`, `delete:any` | Content moderation; cannot write others' data |
| `admin` | `moderator` + `write:config`, `manage:users` | Full access; requires MFA |
| `service` | `read:all`, `write:all` | Machine-to-machine; no user context |

### Permission Enforcement

Permissions are enforced at the API gateway layer before the request reaches the
service. The service additionally validates resource ownership for `write:own`
and `delete:own` to defend against parameter tampering.

\`\`\`python
# Middleware: src/middleware/auth.py
def require_permission(permission: str):
    def decorator(func):
        @wraps(func)
        async def wrapper(request: Request, *args, **kwargs):
            user = request.state.user
            if permission not in user.permissions:
                raise HTTPException(status_code=403, detail="Forbidden")
            return await func(request, *args, **kwargs)
        return wrapper
    return decorator
\`\`\`

---

## Data Classification

Every piece of data the service handles must be classified. Classification
determines storage requirements, access controls, and retention policy.

| Data | Classification | Storage | Access | Retention |
|---|---|---|---|---|
| User email | PII — Confidential | Encrypted at rest (AES-256) | `admin`, `service` | Until account deletion + 30 days |
| Password hash | Sensitive | Bcrypt (cost 12), never logged | `service` only | Until account deletion |
| Session token | Sensitive | Redis (TTL = token lifetime) | `service` only | Auto-expired |
| Usage metrics | Internal | Aggregated, no PII | `admin`, `moderator` | 12 months |
| Public profile | Public | No special protection | All roles | Until deletion |
| Payment card | PCI — Restricted | Tokenized via Stripe; never stored raw | Never stored | Not retained |

Data handling rules:
- PII must never appear in logs. Use structured logging with a `[REDACTED]` mask.
- Sensitive fields must be excluded from API responses unless explicitly needed.
- PCI data is tokenized at the edge; raw card data never touches our systems.

---

## Secret Management

Secrets are stored in AWS Secrets Manager. No secrets are committed to version
control or embedded in Docker images.

| Secret | Path | Rotation Period | Rotation Method |
|---|---|---|---|
| Database credentials | `/[svc]/[env]/DATABASE_URL` | 90 days | Automated via Secrets Manager rotation |
| JWT private key | `/[svc]/[env]/JWT_PRIVATE_KEY` | 180 days | Manual rotation with key overlap period |
| OAuth client secret | `/[svc]/[env]/OAUTH_CLIENT_SECRET` | 90 days | Rotate in IdP first, then update secret |
| Stripe API key | `/[svc]/[env]/STRIPE_SECRET_KEY` | 90 days | Generate new key in Stripe dashboard |

**Rotation procedure:**

1. Generate the new secret value in the upstream system (IdP, cloud console, etc.).
2. Update the secret in AWS Secrets Manager.
3. Trigger a force-new-deployment so running tasks pick up the new value.
4. Verify the health endpoint and monitor error rates for 10 minutes.
5. Revoke the old secret value in the upstream system.
6. Record the rotation in the changelog below.

**Detection:** `ops-leak-audit` agent scans for secrets in git history and code.
Run manually with: `omb ops-leak-audit`.

---

## Compliance Checklist

Check each item against the current implementation. Mark items FAIL with a
linked issue tracking remediation.

### OWASP Top 10

| # | Vulnerability | Status | Evidence |
|---|---|---|---|
| A01 | Broken Access Control | PASS | RBAC enforced in middleware; ownership check on mutations |
| A02 | Cryptographic Failures | PASS | TLS 1.2+ enforced; AES-256 at rest; bcrypt for passwords |
| A03 | Injection | PASS | SQLAlchemy parameterized queries; no raw SQL |
| A04 | Insecure Design | PASS | Threat model reviewed by security team on YYYY-MM-DD |
| A05 | Security Misconfiguration | PASS | Hardened Docker image; security headers via middleware |
| A06 | Vulnerable Components | PASS | Dependabot enabled; weekly `pip-audit` in CI |
| A07 | Auth and Session Failures | PASS | Short-lived tokens; httpOnly cookies; MFA for admin |
| A08 | Software Integrity Failures | PASS | Docker image digest pinning; signed commits required |
| A09 | Security Logging Failures | PASS | Structured audit log; all auth events captured |
| A10 | SSRF | PASS | No user-supplied URLs fetched by backend |

### Additional Controls

- [ ] MFA enforced for `admin` role
- [ ] API rate limiting enabled (see `docs/api/[service]-rate-limits.md`)
- [ ] Security headers present: `CSP`, `HSTS`, `X-Frame-Options`
- [ ] CORS restricted to known origins
- [ ] Dependency scanning in CI (`pip-audit`, `npm audit`)

---

## Audit Log

The service logs the following security events. All audit records are immutable
and retained for 12 months in CloudWatch Logs.

| Event | Log Level | Fields Captured | Retention |
|---|---|---|---|
| Successful login | INFO | `user_id`, `ip`, `user_agent`, `timestamp` | 12 months |
| Failed login (3+ attempts) | WARN | `email_hash`, `ip`, `attempt_count`, `timestamp` | 12 months |
| Password change | INFO | `user_id`, `ip`, `timestamp` | 12 months |
| Role change | INFO | `actor_id`, `target_user_id`, `old_role`, `new_role` | 12 months |
| Resource deletion | INFO | `user_id`, `resource_type`, `resource_id` | 12 months |
| Privilege escalation attempt | ERROR | `user_id`, `ip`, `attempted_permission` | 12 months |
| Secret rotation | INFO | `secret_path`, `actor`, `timestamp` | 12 months |

Log format (structured JSON):

\`\`\`json
{
  "timestamp": "2026-04-10T14:32:00Z",
  "event": "auth.login.success",
  "user_id": "usr_abc123",
  "ip": "203.0.113.42",
  "user_agent": "Mozilla/5.0 ...",
  "request_id": "req_xyz789"
}
\`\`\`

---

## Incident Response

### Escalation Path

\`\`\`mermaid
flowchart TD
    A[Security alert triggered] --> B{Severity?}
    B -->|P0 — data breach / active attack| C[Page on-call engineer immediately]
    B -->|P1 — auth failure spike / anomalous access| D[Notify #security-alerts in Slack]
    B -->|P2 — compliance violation / secret exposure| E[File incident ticket, respond within 4h]
    C --> F[Engage security lead within 15 min]
    F --> G[Declare incident in PagerDuty]
    G --> H[Begin containment: revoke tokens, rotate secrets, isolate service]
    H --> I[Notify legal and DPO if PII is involved]
    D --> J[On-call investigates; escalate to P0 if scope expands]
    E --> K[Security team triages and assigns owner]
\`\`\`

### Immediate Response Steps

1. **Contain:** Revoke affected tokens/sessions via the admin API.
   `POST /admin/sessions/revoke {"user_id": "[id]", "all": true}`
2. **Rotate:** Rotate all secrets that may be compromised (see Secret Management).
3. **Isolate:** If the service itself is compromised, disable the ECS service:
   `aws ecs update-service --cluster [cluster] --service [svc] --desired-count 0`
4. **Preserve evidence:** Export logs before any rollback or restart.
   `aws logs export-task ...`
5. **Notify:** Alert the security lead and, if PII is involved, the DPO.
6. **Post-mortem:** Complete a blameless post-mortem within 5 business days.

---

## Changelog

| Date | Change | Breaking |
|---|---|---|
| YYYY-MM-DD | Initial document | no |
```

Reference: [OWASP Top 10](https://owasp.org/www-project-top-ten/) | [MASVS](https://mas.owasp.org/MASVS/)
