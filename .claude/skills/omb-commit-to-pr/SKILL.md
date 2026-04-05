---
name: omb-commit-to-pr
user-invocable: false
description: >
  Use when committing review-driven changes to an existing PR branch. Checks out
  the PR branch via gh pr checkout, commits fixes with conventional commit format,
  pushes, and posts a review comment summarizing the changes made. Reads PR number
  from pipeline state (step.Result of review-pr step).
argument-hint: "[PR-number]"
allowed-tools: Read, Bash, Grep, Glob, Write
---

# Commit to PR Skill

Commits review-driven changes to an existing PR branch and posts a summary comment.
This skill is internal to the review-pr pipeline (user-invocable: false).

<completion_criteria>
- PR branch checked out successfully
- Changes committed with conventional commit format
- Changes pushed to remote
- Review comment posted via gh pr comment
- Pipeline marker emitted

Status codes: DONE | STALLED (on checkout/push failure)
</completion_criteria>

<scope_boundaries>
This skill commits to PRs — it does NOT:
- Review code (that's omb-review-pr)
- Create plans (that's omb-create-plan)
- Run verification (that's omb-verify)
</scope_boundaries>

## Step 1: Identify PR Number

Extract PR number from:
1. Arguments (if provided directly)
2. Pipeline state: read the `review-pr` step's Result field for `pr={NUMBER}` pattern

If PR number cannot be determined: emit STALLED marker.

## Step 2: Checkout PR Branch

```bash
gh pr checkout {PR_NUMBER}
```

If checkout fails: emit STALLED with error details.

## Step 3: Stage and Commit

```bash
git add .omb/plans/ .claude/plans/ .omb/verifications/ .omb/documents/ .omb/executions/ .omb/prs/ .omb/reviews/ 2>/dev/null || true
git add -u
git diff --cached --stat
```

If no changes staged: post a comment "No changes to commit" and emit DONE.

```bash
git commit -m "$(cat <<'EOF'
fix(review): apply review improvements

Co-Authored-By: Braincrew(dev@brain-crew.com)
EOF
)"
git push
```

## Step 4: Post Comment

```bash
gh pr comment {PR_NUMBER} --body "$(cat <<'EOF'
## Review Changes Applied

Changes have been committed directly to this PR branch based on the automated review.

### Changes Made
{list of changes from git diff --stat}

---
<!-- oh-my-braincrew | Review Fix | {DATE} -->
EOF
)"
```

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>commit-to-pr(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
