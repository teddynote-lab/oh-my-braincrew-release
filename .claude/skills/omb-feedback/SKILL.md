---
name: omb-feedback
user-invocable: true
description: >
  Use when submitting harness feedback or reporting issues to GitHub.
  Triggers on: feedback, report issue, submit feedback.
  Routes feedback via gh CLI or browser URL fallback.
argument-hint: "[feedback message]"
allowed-tools: Bash, Read, AskUserQuestion
---

# Feedback Submission

Submit feedback as a GitHub issue via the `omb` CLI.

## Step 1: Collect Feedback Message

Read the message from `$ARGUMENTS`.

- If `$ARGUMENTS` is empty or blank, use AskUserQuestion: "What feedback would you like to submit?"
- If the user declines or provides no message, abort with: "No feedback message provided."

## Step 2: Submit Feedback

Run the CLI command:

```
omb feedback "<message>"
```

The CLI handles:
1. Building the issue title: `[Feedback] ` prefix + first 80 characters
2. Attempting submission via `gh` CLI (if installed)
3. Falling back to a browser URL if `gh` is unavailable
4. Always printing the GitHub issue URL

## Step 3: Report Result

Report the CLI output to the user. Include the GitHub issue URL so they can track or edit the issue.

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately. Do NOT invoke the next skill or output additional commentary. The pipeline system handles step transitions.
