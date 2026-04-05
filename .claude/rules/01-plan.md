---
description: "Step 1 of the 6-step workflow: Planning standards for task decomposition"
---

# Step 1: Plan

Every non-trivial task MUST produce a plan in `.omb/plans/` before any code is written.

## When to Plan

- Any task touching 2+ files or 2+ stack layers.
- Any task involving schema changes, API changes, or breaking changes.
- Any task that requires coordination between agents.
- Exception: trivial tasks (<10 lines, single file) get a lightweight inline plan in the task description.

## Workflow Tiers

| Tier | Criteria | Steps | Notes |
|------|----------|-------|-------|
| TRIVIAL | <10 lines, 1 file, no behavior change | 3-6 only | No plan file, no critic review |
| STANDARD | Most tasks | All 6 | Full workflow |
| EMERGENCY | Production hotfix, user says "skip plan" | 3→4→6 | Document in trailer: `Skipped: plan,review,docs \| hotfix urgency` |

The orchestrator determines the tier at task start. If in doubt, default to STANDARD.

## Plan Structure

Every plan MUST follow this structure:

```markdown
## Plan: [Title]

### Context
[What we're doing and why — 2-3 sentences]

### Architecture Decisions
- [Decision]: [Rationale]

### Tasks
| # | Task | Agent | Model | Depends On | Deliverable |
|---|------|-------|-------|------------|-------------|
| 1 | ... | executor | sonnet | — | ... |

### Risks
| Risk | Impact | Mitigation |
|------|--------|------------|

### Verification Criteria
- [ ] [What proves success — specific, measurable]

### Parallelization
[Which tasks can run concurrently]
```

## Dependency Ordering

Plans MUST respect this dependency order:
1. DB migrations / schema changes
2. Backend API endpoints
3. Frontend components / UI
4. Integration between layers
5. Verification and testing

## Agent Assignment

Each task MUST name:
- **Agent**: which agent executes it (executor, db-specialist, frontend-engineer, etc.)
- **Model tier**: haiku (quick), sonnet (standard), opus (deep/security)
- **Deliverable**: what the task produces (file path, test result, endpoint)

## Plan File Naming

`<session_id>.md` in `.omb/plans/`. Example: `202604041523-x7k2mq.md`.
