---
name: omb-codex-setup
description: >
  Use when checking Codex CLI readiness, installing Codex, toggling the review gate,
  or when another codex skill reports Codex is missing.
user-invocable: true
argument-hint: "[--enable-review-gate|--disable-review-gate]"
allowed-tools: Bash, AskUserQuestion
---

# Codex Setup Skill

Checks whether the local Codex CLI is ready and optionally toggles the stop-time review gate.

## Step 1: Run Setup Companion

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" setup --json $ARGUMENTS
```

Parse the JSON output to determine the current Codex readiness state.

## Step 2: Handle Codex Unavailable + npm Available

If the result indicates Codex is unavailable **and** npm is available:

- Use `AskUserQuestion` exactly once to ask whether Claude should install Codex now.
- Put the install option first and suffix it with `(Recommended)`.
- Use these two options:
  - `Install Codex (Recommended)`
  - `Skip for now`

If the user chooses **Install Codex**:

```bash
npm install -g @openai/codex
```

Then rerun:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" setup --json $ARGUMENTS
```

Use the rerun output as the final setup result.

If the user chooses **Skip for now**: use the original setup output as the final result.

## Step 3: Skip Installation Prompt When Not Applicable

If Codex is already installed **or** npm is unavailable: do not ask about installation. Proceed directly to Step 4.

## Step 4: Present Final Output

Present the final setup output to the user:

- If Codex is installed but not authenticated, preserve the guidance to run `!codex login`.
- If the review gate was toggled (via `--enable-review-gate` or `--disable-review-gate`), confirm the new gate state.
- If installation was skipped, present the original setup output.

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>codex-setup(brief summary of outcome)</task>
<decision>DONE|BLOCKED</decision>
</omb>
```

Decision values for this skill:
- `DONE` — Codex is ready, or user acknowledged the current state
- `BLOCKED` — Codex unavailable and user chose to skip installation (cannot proceed with codex-dependent skills)
