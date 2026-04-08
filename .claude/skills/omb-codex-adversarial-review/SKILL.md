---
name: omb-codex-adversarial-review
description: >
  Use when running an adversarial Codex review that challenges the implementation approach,
  design choices, tradeoffs, and assumptions. Not just stricter bug detection.
user-invocable: true
argument-hint: "[--wait|--background] [--base <ref>] [--scope auto|working-tree|branch] [focus ...]"
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

# Codex Adversarial Review

Run an adversarial Codex review through the shared built-in reviewer. Position this as a
challenge review that questions the chosen implementation, design choices, tradeoffs, and
assumptions — not just a stricter pass over implementation defects.

Unlike `/omb codex-review`, this skill supports extra focus text after the flags to direct
the adversarial framing toward a specific concern.

Raw slash-command arguments:
`$ARGUMENTS`

## Core Constraint

- This skill is **review-only**.
- Do not fix issues, apply patches, or suggest that you are about to make changes.
- Your only job is to run the adversarial review and return Codex's output verbatim to the user.
- Keep the framing focused on whether the current approach is the right one, what assumptions
  it depends on, and where the design could fail under real-world conditions.
- Do not weaken the adversarial framing or rewrite the user's focus text.

## Execution Mode Rules

Determine how to run the review before proceeding:

1. If `$ARGUMENTS` includes `--wait` — do not ask. Run the review in the foreground immediately.
2. If `$ARGUMENTS` includes `--background` — do not ask. Run the review as a background task immediately.
3. Otherwise, estimate the review size first, then ask:

### Size Estimation Logic

- For working-tree review: run `git status --short --untracked-files=all`.
- For working-tree review: also inspect both `git diff --shortstat --cached` and `git diff --shortstat`.
- For base-branch review (when `--base <ref>` is present): run `git diff --shortstat <base>...HEAD`.
- Treat untracked files or directories as reviewable work even when `git diff --shortstat` is empty.
- Only conclude there is nothing to review when the relevant working-tree status is empty **or** the explicit branch diff is empty.
- Recommend **foreground (wait)** only when the review is clearly tiny — roughly 1–2 files total and no sign of a broader directory-sized change.
- In every other case, including unclear size, recommend **background**.
- When in doubt, run the review instead of declaring that there is nothing to review.

### AskUserQuestion (exactly once)

After estimating size, use `AskUserQuestion` exactly once with two options. Put the recommended option first and suffix its label with `(Recommended)`:

- `Wait for results`
- `Run in background`

## Argument Handling Rules

- Preserve the user's arguments exactly — pass `$ARGUMENTS` as-is to the companion script.
- Do not strip `--wait` or `--background` yourself; the companion script parses these flags.
- Do not add extra review instructions or rewrite the user's intent.
- Claude Code's `Bash(..., run_in_background: true)` is what actually detaches the run — the companion script does not handle detachment.
- This skill does **not** support `--scope staged` or `--scope unstaged`.
- Unlike `/omb codex-review`, focus text after the flags is supported and preserved verbatim.

## Foreground Flow

Run the adversarial review synchronously:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" adversarial-review "$ARGUMENTS"
```

- Return the command stdout **verbatim**, exactly as-is.
- Do not paraphrase, summarize, or add commentary before or after the output.
- Do not fix any issues mentioned in the review output.

## Background Flow

Launch the adversarial review detached:

```typescript
Bash({
  command: `node "${CLAUDE_PLUGIN_ROOT}/scripts/codex/codex-companion.mjs" adversarial-review "$ARGUMENTS"`,
  description: "Codex adversarial review",
  run_in_background: true
})
```

- Do not call `BashOutput` or wait for completion in this turn.
- After launching, tell the user: "Codex adversarial review started in the background. Check `/omb codex-status` for progress."

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately. Do NOT invoke the next skill or output additional commentary. The pipeline system handles step transitions.
