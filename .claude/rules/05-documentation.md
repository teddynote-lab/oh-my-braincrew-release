---
description: "Step 5 of the 6-step workflow: Documentation types and when they are required"
---

# Step 5: Documentation

> **Skill available:** Use `/omb doc` to automate this step. Spawns parallel doc-writer agents for each documentation type needed, writes a document record to `.omb/documents/`, and verifies all generated docs.

Every feature or significant change MUST update documentation before creating a PR.

## When Documentation is Required

| Change Type | Required Documentation |
|-------------|----------------------|
| New feature | README section + API docs (if endpoint) |
| Setup change | README quick start update |
| Architecture decision | ADR in `docs/adr/` |
| Breaking change | Migration guide |
| API endpoint change | OpenAPI/route docs update |
| New agent/skill/hook | Harness component docs |
| Bug fix (non-trivial) | Root cause note in commit or ADR |

## Documentation Types

### README Updates
- Quick start must get a new developer running in <5 minutes.
- Configuration reference for any new env vars or config options.
- Architecture overview diagram (Mermaid) if system topology changes.

### Architecture Decision Records (ADR)
Location: `docs/adr/NNN-title.md`

Format:
```markdown
# NNN: [Decision Title]

## Status
[Proposed / Accepted / Deprecated / Superseded by NNN]

## Context
[What decision was needed and why]

## Decision
[What was chosen]

## Consequences
[Tradeoffs accepted — both positive and negative]
```

Number ADRs sequentially. Never delete an ADR — mark it deprecated or superseded.

### Migration Guides
Required for any breaking change. Must include:
1. Step-by-step migration instructions.
2. Verification at each step.
3. Rollback procedure.
4. Timeline (if deprecation period applies).

### API Documentation
- FastAPI: enhance auto-docs with docstrings, response descriptions, example values.
- Node.js: JSDoc annotations on route handlers.
- Include error responses and edge cases.

## docs/ Folder Structure

```
docs/
├── api/                    # FastAPI/Express endpoint documentation
├── db/                     # Postgres schema, Redis patterns, migrations
├── architecture/           # System design, component diagrams, data flow
├── adr/                    # Architecture Decision Records (sequential NNN-slug.md)
├── guides/                 # Setup, deployment, migration guides
│   └── migration/          # Breaking change migration guides
├── langchain/              # LangChain/LangGraph workflow documentation
├── frontend/               # React component catalog, state management
├── electron/               # IPC protocol, security model, packaging
├── infra/                  # Docker, CI/CD, monitoring, Slack alerts
├── testing/                # Test strategy, fixtures, coverage targets
├── security/               # Security model, trust boundaries, audit results
├── prompts/                # LLM prompt documentation, template reference
└── claude-code-docs/       # [READ ONLY — authoritative harness reference]
```

## Document Record

Every `/omb doc` invocation writes a record to `.omb/documents/{plan-filename}.md` for audit trail. The record tracks which doc types were generated, which were skipped, and verification results.

## Incremental Update Rules

- Update existing docs at the **section level** — never rewrite an entire file.
- Append-only sections: Changelog, Known Issues, Troubleshooting, FAQ.
- If an update would change >30% of a file, present the diff for user approval.
- Existing sections not mentioned in the update are preserved untouched.

## Agent Routing

- Delegate to `doc-writer` (haiku) for standard documentation.
- Use `sonnet` model for ADRs that require architectural reasoning.

## Quality Checks

- Documentation must be in English.
- Verify accuracy by reading the code — never document assumed behavior.
- Keep docs close to the code they describe (co-located > centralized).
- Use Mermaid for diagrams, not ASCII art.
