---
description: "Conventional commit format with structured trailers for decision context preservation"
---

# Commit Conventions

## Format

```
type(scope): description

[optional body — what and why, not how]

[trailers]

Co-Authored-By: Braincrew(dev@brain-crew.com)
```

## Types

| Type | When |
|------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `chore` | Tooling, config, dependency updates |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |

## Scope

Use the primary affected module: `api`, `auth`, `db`, `ui`, `electron`, `infra`, `langraph`, `slack`, `redis`.
For cross-cutting changes, use the most impacted scope.

## Trailers

Include when applicable — skip for trivial commits:

| Trailer | Purpose | Example |
|---------|---------|---------|
| `Constraint:` | Active constraint that shaped this decision | `Constraint: Redis TTL must match JWT exp` |
| `Rejected:` | Alternative considered and why rejected | `Rejected: Background timer \| race condition` |
| `Directive:` | Warning for future modifiers | `Directive: Do not cache without TTL` |
| `Confidence:` | How sure we are | `Confidence: high` |
| `Scope-risk:` | Blast radius | `Scope-risk: narrow` |
| `Not-tested:` | Known untested edge cases | `Not-tested: concurrent token refresh` |
| `Co-Authored-By:` | Always include | `Co-Authored-By: Braincrew(dev@brain-crew.com)` |

## Rules

- Subject line: imperative mood, lowercase, no period, max 72 characters.
- Body: wrap at 72 characters. Explain what and why, not how.
- One logical change per commit — don't mix features with refactors.
- Trailers separated from body by a blank line.
- [HARD] Never include "Generated with Claude Code" or any variation in commit messages. The only attribution is the `Co-Authored-By: Braincrew(dev@brain-crew.com)` trailer.

## Examples

```
feat(api): add JWT refresh endpoint

Adds POST /api/auth/refresh that accepts a valid refresh token
and returns a new access/refresh token pair.

Constraint: Redis TTL must match JWT exp claim
Rejected: Cookie-based refresh | XSS risk in Electron renderer
Confidence: high
Scope-risk: narrow

Co-Authored-By: Braincrew(dev@brain-crew.com)
```

```
fix(db): prevent connection pool exhaustion under load

Reduces max pool size from 50 to 20 and adds connection timeout.
Pool exhaustion was causing 503s under sustained concurrent requests.

Constraint: asyncpg pool must not exceed Postgres max_connections
Not-tested: behavior under 1000+ concurrent connections
Confidence: medium
Scope-risk: moderate

Co-Authored-By: Braincrew(dev@brain-crew.com)
```
