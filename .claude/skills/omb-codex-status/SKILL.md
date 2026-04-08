---
name: omb-codex-status
description: >
  Use when checking active and recent Codex jobs, including review-gate status.
user-invocable: true
argument-hint: "[job-id] [--wait] [--timeout-ms <ms>] [--all]"
allowed-tools: Bash
---

# Codex Status

Show active and recent Codex jobs for this repository, including review-gate status.

## Step 1: Run the Status Command

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" status $ARGUMENTS
```

## Step 2: Present the Output

If the user did not pass a job ID:
- Render the command output as a single compact Markdown table covering current and past runs in this session.
- Include the actionable fields: job ID, kind, status, phase, elapsed or duration, summary, and follow-up commands.
- Do not include progress blocks or extra prose outside the table.

If the user did pass a job ID:
- Present the full command output verbatim.
- Do not summarize or condense it.

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately. Do NOT invoke the next skill or output additional commentary. The pipeline system handles step transitions.
