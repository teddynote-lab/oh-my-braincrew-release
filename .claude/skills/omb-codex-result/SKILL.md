---
name: omb-codex-result
description: >
  Use when retrieving the stored final output for a finished Codex job.
user-invocable: true
argument-hint: "[job-id]"
allowed-tools: Bash
---

# Codex Result

Retrieve the stored final output for a finished Codex job in this repository.

## Step 1: Run the Result Command

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" result $ARGUMENTS
```

## Step 2: Present the Output

Present the full command output verbatim. Do not summarize or condense it. Preserve all details including:
- Job ID and status
- The complete result payload, including verdict, summary, findings, details, artifacts, and next steps
- File paths and line numbers exactly as reported
- Any error messages or parse errors
- Follow-up commands such as `/omb:codex-status <id>` and `/omb:codex-review`

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately. Do NOT invoke the next skill or output additional commentary. The pipeline system handles step transitions.
