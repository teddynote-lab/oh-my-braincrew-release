---
name: omb-codex-adv-review
description: "Run adversarial Codex review — challenges assumptions, finds failure modes, and pressure-tests implementation choices. Core Codex feature for deep code analysis."
user-invocable: true
argument-hint: "[--base <ref>] [focus-text]"
allowed-tools: Bash, Read, Grep, Glob
---

# Codex Adversarial Review

Run an adversarial code review using the Codex CLI. Unlike standard review, this mode actively challenges the implementation — finding failure modes, security risks, race conditions, and design weaknesses.

## Pre-execution Check

!`which codex 2>/dev/null || echo "NOT_FOUND"`

If `codex` is not found, stop and tell the user:
```
Codex CLI is not installed. Run: npm install -g @openai/codex
```

## Arguments

$ARGUMENTS

## Execution

1. Determine the review scope:
   - `--base <ref>` — review changes against a base branch
   - No base flag — defaults to uncommitted changes
   - Any remaining text after flags is treated as **focus text** (directs Codex to challenge specific areas)

2. Build the adversarial review command. The `codex review` CLI does not have a `--adversarial` flag. Instead, pass adversarial review instructions as the prompt argument:
   - If `$ARGUMENTS` contains `--base <ref>`: extract the base flag and combine with adversarial prompt
   - If `$ARGUMENTS` has focus text: incorporate it into the adversarial prompt
   - Default (no args): use `--uncommitted` with the adversarial prompt

**Important:** `--uncommitted` and `[PROMPT]` are mutually exclusive in the codex CLI. When providing adversarial instructions as a prompt, do NOT add `--uncommitted` — the prompt implicitly reviews uncommitted changes.

```bash
# Default: adversarial review of uncommitted changes (prompt-only, no --uncommitted)
codex review "Act as an adversarial reviewer. Challenge assumptions, find failure modes, race conditions, auth bypass, data loss scenarios, and rollback safety issues. Report only material findings with evidence."

# With base branch (--base is compatible with PROMPT)
codex review --base main "Act as an adversarial reviewer. Challenge assumptions, find failure modes, race conditions, auth bypass, data loss scenarios, and rollback safety issues. Report only material findings with evidence."

# With user focus text (e.g., user said "challenge the caching design")
codex review "Act as an adversarial reviewer. Focus on: challenge the caching design. Find failure modes, race conditions, auth bypass, data loss scenarios, and rollback safety issues."
```

3. Return the Codex output **verbatim**. Do not paraphrase, summarize, or add commentary.

4. After presenting findings, **STOP**. Do not auto-apply fixes unless the user explicitly asks.

## Focus Text Examples

- `adversarial-review --base main challenge the caching design` — pressure-test caching choices
- `adversarial-review check for race conditions in auth flow` — find concurrency issues
- `adversarial-review` — general adversarial review of all changes

## Attack Surface

Codex adversarial review focuses on:
- Auth/permissions bypass
- Data loss scenarios
- Race conditions and concurrency bugs
- Rollback safety
- Observability gaps
- Error handling completeness

## Rules

- This command is review-only. Do not fix issues.
- Preserve all file paths, line numbers, and confidence scores exactly as reported.
- If Codex reports no material findings, say so and stop.
- If the review fails (non-zero exit), report the error and stop.
