---
description: "Step 2 of the 6-step workflow: Plan review checklist and approval process"
---

# Step 2: Review Plan

Every plan MUST be reviewed before execution. No self-approval — the plan author cannot be the reviewer.

## Reviewer Assignment

- Default: `critic` agent (opus) for architecture-heavy plans.
- Alternative: `reviewer` agent (opus) for implementation-focused plans.
- Both may be used for large, cross-cutting plans.

## Review Checklist

The reviewer MUST evaluate:

### Completeness
- [ ] All affected stack layers identified (Python, Node.js, React, Electron, data, infra).
- [ ] Every task has an assigned agent, model tier, and deliverable.
- [ ] Dependencies between tasks are explicit and correct.
- [ ] Verification criteria are specific and measurable.

### Dependency Correctness
- [ ] DB changes come before API changes that depend on them.
- [ ] API changes come before frontend changes that consume them.
- [ ] No circular dependencies between tasks.
- [ ] Parallelizable tasks are correctly identified.

### Risk Coverage
- [ ] Cross-layer risks identified (e.g., schema change breaking API contract).
- [ ] Rollback strategy for risky steps.
- [ ] Security implications assessed (auth, injection, data exposure).

### Pre-Mortem (MANDATORY)
Answer: "If this fails in 3 months, the most likely reason is: ___"
This forces consideration of long-term failure modes, not just immediate implementation risks.

## Verdicts

| Verdict | Meaning | Next Step |
|---------|---------|-----------|
| APPROVED | Plan is sound, proceed to execution | Step 3: Execute |
| NEEDS REVISION | Specific issues must be addressed | Revise plan, re-review |
| BLOCKED | External dependency or missing information | Resolve blocker, then re-review |

## Output Format

```markdown
## Critique: [Plan Title]

### Verdict: APPROVED / NEEDS REVISION / BLOCKED

### Blocking Concerns
- [BLOCKING] [Concern]: [Evidence and impact]

### Warnings
- [WARNING] [Concern]: [Why this matters]

### Pre-Mortem
"If this fails in 3 months, the most likely reason is: [specific failure mode]"

### Assumptions Verified
- [Assumption] — [Confirmed/Unconfirmed] — [Evidence]
```

## Revision Bounds

Maximum 2 revision rounds. After 2 NEEDS REVISION verdicts, escalate to user for decision. This prevents infinite ping-pong between critic and planner on opus tier.
