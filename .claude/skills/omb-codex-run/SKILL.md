---
name: omb-codex-run
description: "Delegate a coding task to Codex CLI — runs codex exec with the given prompt for investigation, bug fixes, or implementation."
user-invocable: true
argument-hint: "<task-description>"
allowed-tools: Bash, Read, Grep, Glob
---

# Codex Task Execution

Delegate a coding task to the Codex CLI. Codex runs independently and returns the result.

## Pre-execution Check

!`which codex 2>/dev/null || echo "NOT_FOUND"`

If `codex` is not found, stop and tell the user:
```
Codex CLI is not installed. Run: npm install -g @openai/codex
```

## Arguments

$ARGUMENTS

## Execution

1. If no task description is provided, ask the user what they want Codex to do.

2. Run the task:
```bash
codex exec "$ARGUMENTS"
```

3. Return the Codex output **verbatim**.

4. If Codex made file changes, summarize what was changed so the user can review.

## Options

- The task description should be a clear, specific prompt describing what Codex should do.
- Codex runs in a sandboxed environment by default.

## Examples

```
/omb codex run "investigate why the login API returns 500 on empty password"
/omb codex run "add input validation to the user registration endpoint"
/omb codex run "refactor the payment service to use async/await"
```

## Rules

- Pass the user's task description to Codex exactly as provided.
- Do not modify or "improve" the user's prompt before passing it to Codex.
- After Codex completes, present the result and let the user decide next steps.
- If Codex fails, report the error without attempting alternative solutions.
