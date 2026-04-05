---
description: "Security checklist: OWASP for FastAPI/Node.js, Electron RCE, React XSS, data layer security"
paths: ["**/auth/**", "**/middleware/**", "**/security/**", "**/api/**/*.py", "**/routes/**/*.ts", "**/electron/**/*"]
---

# Security Checklist

## Authentication and Authorization

- [ ] Auth on every protected route — no route without explicit auth check.
- [ ] JWT validation: verify signature, issuer, audience, and expiration.
- [ ] Token storage: httpOnly cookies preferred over localStorage (XSS protection).
- [ ] Role-based access control (RBAC) at the route level.
- [ ] Session invalidation: revoke tokens on logout, password change.

## Injection Prevention

### SQL Injection
- [ ] All database queries use parameterized queries or ORM expressions.
- [ ] No string concatenation or f-strings in SQL.
- [ ] Input validation before database operations.

### XSS (Cross-Site Scripting)
- [ ] React: never use `dangerouslySetInnerHTML` without sanitization.
- [ ] Escape user-generated content in templates.
- [ ] CSP headers configured: `Content-Security-Policy`.

### Command Injection
- [ ] No `subprocess.shell=True` with user input.
- [ ] No `eval()`, `exec()`, or `Function()` with dynamic input.
- [ ] Whitelist allowed commands if shell execution is necessary.

## Electron Security

- [ ] `nodeIntegration: false` in all renderer processes.
- [ ] `contextIsolation: true` — always.
- [ ] Validate ALL IPC inputs — treat renderer as untrusted.
- [ ] No `shell.openExternal()` with unvalidated URLs.
- [ ] CSP in renderer HTML: no `unsafe-inline`, no `unsafe-eval`.
- [ ] Disable `remote` module entirely.

## Data Layer

### Postgres
- [ ] Row-Level Security (RLS) for multi-tenant data.
- [ ] Least-privilege database users — app user cannot DROP tables.
- [ ] Encrypted connections (TLS) in production.
- [ ] Sensitive data encrypted at rest (PII columns).

### Redis
- [ ] ACLs configured — no default user in production.
- [ ] Bound to internal network only.
- [ ] TLS for connections over untrusted networks.
- [ ] No `FLUSHALL` or `FLUSHDB` permissions for app user.

## API Security

- [ ] Rate limiting on auth endpoints (login, register, password reset).
- [ ] Request size limits configured.
- [ ] CORS configured for specific origins — no wildcard in production.
- [ ] Security headers: HSTS, X-Content-Type-Options, X-Frame-Options.
- [ ] No secrets in error responses or logs.

## Dependencies

- [ ] Regular dependency audit: `uv pip audit`, `npm audit`.
- [ ] Pin dependency versions — no floating ranges for security-critical packages.
- [ ] Review new dependencies before adding — check maintenance status and known CVEs.

## Secrets

- [ ] No secrets in source code, Dockerfiles, or CI config files.
- [ ] All secrets in environment variables or secrets management.
- [ ] Rotate secrets on schedule and after any potential exposure.
- [ ] `.env` files in `.gitignore`.
