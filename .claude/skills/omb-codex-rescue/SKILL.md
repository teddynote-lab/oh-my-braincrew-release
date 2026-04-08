---
name: omb-codex-rescue
description: >
  Use when delegating investigation, fix requests, or follow-up rescue work to the
  Codex rescue subagent. Supports resume/fresh thread modes and model/effort selection.
user-invocable: true
context: fork
argument-hint: "[--background|--wait] [--resume|--fresh] [--model <model|spark>] [--effort <level>] [task description]"
allowed-tools: Bash, AskUserQuestion, Agent
---

# Codex Rescue

Delegate investigation, an explicit fix request, or follow-up rescue work to the Codex
rescue subagent. The final user-visible response must be Codex's output verbatim.

Raw user request:
$ARGUMENTS

## Step 1: Validate Input

If no task description was provided in `$ARGUMENTS` (after stripping execution/routing
flags), use `AskUserQuestion` to ask what Codex should investigate or fix before
proceeding.

## Step 2: Determine Execution Mode

Parse the following flags from `$ARGUMENTS`. These are execution controls — do not
treat them as part of the natural-language task text and do not forward them to the
subagent as task text:

- `--background` — run the subagent in the background
- `--wait` — run the subagent in the foreground (default when neither flag is present)
- `--resume` — skip the thread-continuation question; continue the existing thread
- `--fresh` — skip the thread-continuation question; start a new thread
- `--model <value>` — runtime model selection; preserve and forward to the subagent
- `--effort <value>` — runtime effort selection; preserve and forward to the subagent

## Step 3: Check for Resumable Thread (skip if --resume or --fresh is present)

If neither `--resume` nor `--fresh` was supplied, run:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" task-resume-candidate --json
```

If the helper is missing or exits with an error indicating Codex is not installed or
unauthenticated, stop immediately and tell the user to run `/omb codex-setup`.

If the helper reports `available: true`, use `AskUserQuestion` exactly once to ask
whether to continue the current Codex thread or start a new one.

Choices must be:
- If the user's request is clearly a follow-up ("continue", "keep going", "resume",
  "apply the top fix", "dig deeper"): put `Continue current Codex thread (Recommended)`
  first, then `Start a new Codex thread`.
- Otherwise: put `Start a new Codex thread (Recommended)` first, then
  `Continue current Codex thread`.

After the user answers:
- "Continue..." → treat as `--resume` for the forwarded call
- "Start new..." → treat as `--fresh` for the forwarded call

If the helper reports `available: false`, skip the question and route normally.

## Step 4: Route to the Codex Rescue Subagent

Invoke the `codex-rescue` subagent via the Agent tool. Pass the processed task
description (natural-language portion only, with all execution/routing flags stripped)
plus any preserved `--model` and `--effort` values and the resolved `--resume` or
`--fresh` flag.

```
Agent(
  subagent_type: "codex-rescue",
  prompt: "<processed task text with --model, --effort, and --resume/--fresh as applicable>"
)
```

- If `--background` was supplied, invoke the Agent tool in a non-blocking manner.
- Otherwise invoke it in the foreground (default).

## Step 5: Return Output Verbatim

Return the subagent's output exactly as-is.

- Do not paraphrase, summarize, rewrite, or add commentary before or after it.
- Do not ask the subagent to inspect files, monitor progress, poll status, fetch
  results, cancel jobs, or do any follow-up work of its own.

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately.
Do NOT invoke the next skill or output additional commentary. The pipeline system handles
step transitions.
