---
name: omb-resolve-issue
description: >
  Use when resolving open GitHub issues automatically. Fetches issues, prioritizes by severity,
  and spawns parallel session-driven pipelines to create fix PRs linked to each issue.
  Triggers on: resolve-issue, resolve issues, fix issues, auto-fix issues.
user-invocable: true
argument-hint: "[--count N] [--dry-run] [--label filter]"
allowed-tools: Agent, Bash, Read, Grep, Glob, AskUserQuestion, Skill
---

# Resolve GitHub Issues

Automatically fetch, prioritize, and resolve open GitHub issues via parallel session-driven pipelines.

## Step 0: Preflight Checks

```bash
gh auth status
gh repo view --json nameWithOwner --jq '.nameWithOwner'
```

If either check fails, abort:
- `gh` not found: "Install GitHub CLI: https://cli.github.com/ then run `gh auth login`"
- Not authenticated: "Run `gh auth login` to authenticate with GitHub"
- No repo: "No GitHub remote detected. Run `gh repo create` or add a remote."

## Step 1: Parse Arguments

Parse `$ARGUMENTS` for flags:
- `--count N` → resolve N issues (default: 1)
- `--dry-run` → preview selection only, do not execute
- `--label <label>` → filter to issues with this label only

## Step 2: Fetch and Prioritize Issues

Fetch all open issues excluding `wontfix` and `on-hold` labels:

```bash
gh issue list --state open --json number,title,labels,body,url --limit 50
```

### Priority Algorithm

1. **Severity score:** high=3, medium=2, low=1, unlabeled=0
2. **Category tiebreaker:** security=4, performance=3, architecture=2, code-quality=1
3. **Sort descending** by (severity_score * 10 + category_score)
4. **Skip** issues labeled `wontfix` or `on-hold`
5. **Skip** issues that already have an open PR (check with `gh pr list --state open --json number,body --jq '.[] | select(.body | test("Closes #N|closes #N|Fixes #N|fixes #N"))'` — search PR bodies, not titles)

Select the top N issues (where N = `--count` value).

## Step 3: Dry-Run Check

If `--dry-run` was specified, display a table of selected issues and exit:

```
# | Issue | Severity | Category | URL
1 | #44 [high][security] Dependency CVE... | high | security | https://...
2 | #47 [high][performance] PreToolUse... | high | performance | https://...
```

Report "Dry run complete. No pipelines started." and stop.

## Step 4: Execute Parallel Resolutions

[HARD] Max 3 concurrent resolutions. Queue remaining issues.

For each selected issue (up to 3 at a time), invoke the `Agent` tool:

```
Agent({
  description: "Resolve issue #N",
  // TODO: Replace with session-driven pipeline invocation once the new pipeline API is available.
  prompt: "Resolve this GitHub issue by creating a fix and PR.\n\nIssue #<NUMBER>: <TITLE>\n<BODY>\n\nURL: <URL>\n\n[HARD] Implement a targeted fix for this issue in an isolated worktree branch.\nPR body MUST include 'Closes #<NUMBER>' and link to <URL>. Branch: fix/issue-<NUMBER>-<slug>\n\nAfter implementing the fix, create a PR and return the PR URL.",
  subagent_type: "general-purpose",
  model: "sonnet"
})
```

Invoke up to 3 `Agent` calls in a single response for parallelism. If `--count` > 3, wait for the first batch to complete, then invoke the next batch.

Collect results from each agent: PR URL (success) or error message (failure).

## Step 5: Generate Summary Report

Create `.omb/reports/resolve-issue-YYYY-MM-DD.md`:

```markdown
# Issue Resolution Report

**Date:** YYYY-MM-DD
**Issues Attempted:** N
**Resolved:** M
**Failed:** K

| # | Issue | Severity | Status | PR |
|---|-------|----------|--------|-----|
| 1 | #44 [title] | high | Resolved | PR #XX |
| 2 | #47 [title] | high | Failed | Error: [reason] |
```

Also print the summary table to the console.

## Completion

This skill does NOT emit pipeline markers — it is a standalone command, not a pipeline step.
Report the summary and stop.
