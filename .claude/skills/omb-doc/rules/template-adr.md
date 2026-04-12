---
title: Architecture Decision Record (ADR) Template
impact: HIGH
tags: template, adr, architecture, decision
---

## Architecture Decision Record (ADR) Template

Architecture Decision Records capture significant technical decisions: why a choice was made, what alternatives were rejected, and what consequences the team accepted. Store ADRs in `docs/architecture/adr/` using the filename format `NNN-kebab-case-title.md` (e.g., `001-use-postgres.md`).

ADRs are permanent records. Once accepted, they are never deleted — they are superseded by newer ADRs. The date and status fields tell the reader whether the decision is still in force.

Write ADRs at decision time, not after implementation. A decision written retrospectively loses the context that made the alternatives feel real. If the decision was already made, write it anyway and date it accurately.

**Incorrect (no alternatives, no consequences, status missing, wrong frontmatter):**

```markdown
---
title: We Use PostgreSQL
---

We decided to use PostgreSQL as our database because it is reliable and
well-supported. Redis is used for caching.
```

Problems with the above:
- No ADR number in the title.
- Missing `status`, `created`, `updated`, `category`, `tags` frontmatter fields.
- No context explaining what drove the decision.
- No alternatives considered — the decision looks unexamined.
- No consequences — the reader cannot assess what was accepted.

**Correct (full MADR template with all required sections):**

```markdown
---
title: "ADR-001: Use PostgreSQL as the Primary Database"
category: architecture
status: accepted
created: 2026-04-10
updated: 2026-04-10
tags: adr, database, postgresql, storage
relates-to: src/db
depends-on: docs/architecture/_overview.md
supersedes:        # path to the ADR this one replaces, if any
superseded-by:     # path to the newer ADR, filled in when this one is superseded
---

# ADR-001: Use PostgreSQL as the Primary Database

## Status

`accepted` — Adopted on 2026-04-10. Implemented in `src/db/` using SQLAlchemy
2.0 async. Reviewed by: [Name], [Name].

Valid statuses: `proposed` | `accepted` | `deprecated` | `superseded`

When superseding this ADR, set `status: superseded` and fill in `superseded-by`
with the path to the new ADR. Do not delete this file.

---

## Context

Describe the situation that forced a decision. Include:
- What was being built and what data it needed to store
- Which constraints applied (team familiarity, compliance, cost, scale)
- What was the cost of delaying the decision
- What was uncertain at the time

Example:

The [service name] needs a persistent store for user accounts, orders, and
transactional records. The data is relational: orders reference users, line
items reference products, and payments reference orders. We need ACID
transactions across multiple tables for payment operations, and the compliance
requirement mandates point-in-time recovery with a 30-day retention window.

The team of [N] engineers has strong experience with SQL and SQLAlchemy but
limited experience with document stores. We are targeting an initial load of
~10k daily active users with a projected growth to ~100k within 18 months.
Read/write ratio is estimated at 80/20.

This decision was made before any implementation began. Changing it after
schema establishment would require a full migration.

---

## Decision

State the decision in one sentence. Then explain why this option was chosen
over the alternatives. Reference specific constraints from the Context section.

**We will use PostgreSQL 16 as the primary relational database, accessed via
SQLAlchemy 2.0 async ORM, deployed on AWS RDS Multi-AZ.**

Rationale:
- The data model is inherently relational; foreign key constraints and JOIN
  queries are natural fits.
- ACID transactions with `SERIALIZABLE` isolation cover the payment use case
  without application-layer locking.
- RDS Multi-AZ provides the point-in-time recovery required by compliance at a
  managed-service cost lower than self-hosting.
- The team's existing SQLAlchemy expertise reduces ramp-up time and the risk of
  ORM-related bugs.
- PostgreSQL's JSONB column type preserves the ability to store semi-structured
  data (e.g., provider webhook payloads) without a separate document store.

---

## Consequences

List every consequence the team knowingly accepted. Include positive outcomes,
negative trade-offs, and neutral effects (things that are now true but neither
good nor bad). Omitting negative consequences is a red flag that the decision
was not examined honestly.

### Positive

- Strong consistency guarantees simplify application logic; no eventual
  consistency edge cases to handle.
- A single database technology reduces operational complexity (one monitoring
  stack, one backup strategy, one on-call runbook).
- SQL literacy is widespread; future engineers are unlikely to be blocked.
- Rich ecosystem: `pg_stat_statements`, `pgvector` for future ML features,
  PostGIS if geospatial data is needed.

### Negative

- Vertical scaling limit: RDS PostgreSQL scales to ~96 vCPUs / 768 GB RAM.
  Beyond that, horizontal partitioning (Citus, sharding) would require a
  migration.
- Schema migrations are synchronous; large table alterations require careful
  planning with tools like `pg_repack` or `pglogical`.
- RDS is more expensive than a managed document store (e.g., DynamoDB) at high
  read-heavy workloads above ~1M req/day.

### Neutral

- The team must maintain Alembic migration files. Migrations are reviewed in
  every PR touching the schema.
- Redis is still used for ephemeral caching and session storage; PostgreSQL
  does not replace it for those use cases.
- The async driver (`asyncpg`) requires async-aware code throughout the data
  layer. This is consistent with our FastAPI async pattern.

---

## Alternatives Considered

| Alternative | Pros | Cons | Reason Rejected |
|---|---|---|---|
| **MongoDB (Atlas)** | Flexible schema; good for document-centric data; managed service | Weak transactions (pre-4.0 style); team unfamiliarity; document model fights our relational data | Relational model fits our data; team has no MongoDB production experience |
| **MySQL 8** | Widely known; strong ecosystem; RDS-managed | Weaker JSON support; `ONLY_FULL_GROUP_BY` edge cases; fewer advanced index types | PostgreSQL is a strict superset of MySQL's feature set for our use case |
| **DynamoDB** | Infinite horizontal scale; serverless; low ops burden | No JOINs; limited transaction support; complex access patterns must be designed upfront | Relational access patterns are a poor fit; redesigning the data model would take 3+ weeks |
| **CockroachDB** | Distributed SQL; automatic sharding; Postgres-compatible | Higher latency per query; licensing costs at scale; team has no experience | Premature optimization for a team at our current scale |
| **SQLite** | Zero ops; perfect for development | Not suitable for multi-process production deployments; no Multi-AZ | Development convenience only; cannot serve as a production primary |

---

## Changelog

| Date | Change |
|---|---|
| YYYY-MM-DD | Initial draft |
| YYYY-MM-DD | Accepted after team review |
```

Reference: [MADR (Markdown Architectural Decision Records)](https://adr.github.io/madr/) | [Michael Nygard — Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
