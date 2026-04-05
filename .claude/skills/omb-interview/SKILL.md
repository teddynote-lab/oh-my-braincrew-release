---
name: omb-interview
user-invocable: true
description: >
  (omb) Use when thorough requirements gathering is needed before planning.
  Asks probing questions via AskUserQuestion from multiple angles: functional
  requirements, edge cases, constraints, integrations, data model, API contracts,
  error handling, security, and UX expectations. Produces a structured interview
  summary in .omb/interviews/. Triggers on: interview, gather requirements,
  requirements discovery, "before we plan".
argument-hint: "[description of what to build]"
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion, Agent, Write
---

# Interview Skill

Gather comprehensive requirements through structured multi-round questioning
before planning begins.

## HARD RULES

[HARD] Do NOT produce the interview summary until convergence criteria are met.
[HARD] Ask ONE question at a time using AskUserQuestion. Never batch questions.
[HARD] Prefer multiple-choice options (2-4 choices) when possible.
[HARD] Maximum 15 question rounds. If reached, save what you have.

## Pre-Interview Context

Before asking any questions, silently gather codebase context:

1. Read project structure: !`ls -la 2>/dev/null | head -20`
2. Check existing interviews: !`ls -t .omb/interviews/*.md 2>/dev/null | head -3`
3. Check tech stack: !`cat .omb/config.json 2>/dev/null | head -10`
4. Recent changes: !`git log --oneline -5 2>/dev/null`
5. Check for existing plans: !`ls -t .omb/plans/*.md 2>/dev/null | head -3`

If a partial interview file exists from a previous session, mention it:
"I found a previous interview draft. Starting fresh, but I'll reference it."

## Interview Dimensions

Cover ALL applicable dimensions. For each, ask 1-3 targeted questions.
Skip dimensions clearly not applicable to the user's description.

### 1. Scope and Purpose
- What problem are we solving? Who are the users?
- What does "done" look like?

### 2. Functional Requirements
- Core behaviors and user stories
- Input/output specifications
- Acceptance criteria

### 3. Constraints and Boundaries
- Timeline pressure? Breaking changes allowed?
- Backward compatibility? Budget/resource limits?

### 4. Tech Stack Decisions
- Which layers? (Python/FastAPI, Node.js, React, Electron, Redis, Postgres)
- Preferred libraries or patterns?
- Integration points with existing systems?

### 5. Data Model
- Entities/data structures needed?
- Storage (Postgres, Redis, filesystem)?
- Relationships and access patterns?

### 6. API Contracts
- Endpoint design (REST, GraphQL, IPC)?
- Request/response shapes?
- Auth requirements?

### 7. Error Handling and Edge Cases
- Known failure modes?
- Recovery strategies?
- What must NOT happen?

### 8. Security Considerations
- Sensitive data? Auth? Input validation?

### 9. UX/UI Expectations (if applicable)
- Interaction patterns? Visual requirements? Accessibility?

### 10. Testing Strategy
- Critical test scenarios?
- Performance requirements?
- Integration test boundaries?

## Question Best Practices

- Lead with codebase context: "I see you're using FastAPI with async routes.
  For this new endpoint, should we..."
- Offer concrete options: Use AskUserQuestion with 2-4 labeled choices.
- Reference discoveries: "I found 3 existing migration files. Should this
  feature add a new migration?"
- Build on answers: "You mentioned real-time updates. That means we should
  consider websocket vs SSE — which do you prefer?"

## Convergence Detection

Convergence is reached when ANY of:
- All applicable dimensions explored (1+ question per relevant dimension)
- No new requirements discovered in the last 2 questions
- User signals done ("that's it", "nothing else", "move on", "let's go")
- Maximum 15 question rounds reached

When convergence detected, present a bullet-point summary per dimension
and ask the user to confirm before saving.

## Interview Summary Document

### Directory Setup
!`mkdir -p .omb/interviews`

### File Location
`.omb/interviews/YYYY-MM-DD-{slug}.md`

### Document Template

```markdown
# Interview Summary: [Title]

**Date:** YYYY-MM-DD
**Context:** [Original user description]
**Pipeline:** full
**Questions Asked:** [N]

## Scope and Purpose
[Summary]

## Functional Requirements
- [Requirement 1]
- [Requirement 2]

## Constraints
- [Constraint 1]

## Tech Stack
- [Decision 1]

## Data Model
- [Entity/relationship summary]

## API Contracts
- [Contract 1]

## Error Handling
- [Strategy 1]

## Security
- [Consideration 1]

## UX/UI
- [Expectation 1] (or "N/A — backend only")

## Testing Strategy
- [Approach 1]

## Open Questions
- [Any unresolved items]

## Recommended Focus Areas
- [Key areas for the planning phase]
```

## Escape Hatch

If the user says "skip interview", "just plan it", or "no questions":
1. Save a minimal summary noting the interview was skipped
2. Emit the DONE marker immediately

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>interview(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
