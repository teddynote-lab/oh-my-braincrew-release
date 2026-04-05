---
name: omb-fallback-decide
user-invocable: false
description: >
  Use when the Stop hook fails to parse a structured <omb> response schema
  from the previous skill output. Reads session state and previous response,
  determines the correct decision, and emits the proper <omb> schema.
allowed-tools: Read, Bash
---

# Fallback Decision Skill

The pipeline Stop hook could not parse a structured `<omb>` response from the
previous skill output. Your job: determine what happened and emit the proper schema.

## Input

`$ARGUMENTS` contains: `<session_id>`

## Steps

1. Read `.omb/sessions/<session_id>.json` — find the active task (`"status": "active"`)
2. Review the conversation context above — the previous skill's output is visible
3. Determine the decision based on the previous output:
   - Did the skill complete successfully? → `DONE`
   - Did a review approve the plan? → `APPROVED`
   - Did a review reject with revision requests? → `NEEDS_REVISION`
   - Did something fail with errors? → `FAILED`
   - Is more context needed from the user? → `NEEDS_CONTEXT`
   - Is there an external blocker? → `BLOCKED`
4. Emit the response schema

## Response Schema

[HARD] You MUST emit this exact XML block as your FINAL output:

```
<omb>
<task>ACTIVE_TASK_NAME(brief summary of what happened)</task>
<decision>YOUR_DECISION</decision>
</omb>
```

Where:
- `ACTIVE_TASK_NAME` is the `task_name` from the active task in the session JSON
- `YOUR_DECISION` is one of: `DONE`, `DONE_WITH_CONCERNS`, `APPROVED`, `NEEDS_REVISION`, `REJECT`, `FAILED`, `NEEDS_CONTEXT`, `BLOCKED`

## Rules

- [HARD] Always emit the `<omb>` block — this is the ONLY purpose of this skill
- [HARD] If uncertain, default to `DONE` for skills that appeared to complete work
- [HARD] Keep analysis brief — speed matters, this is a recovery path
- [HARD] Do NOT modify session JSON directly
- [HARD] Do NOT invoke other skills
- [HARD] Do NOT ask the user questions — make the best judgment from available context
