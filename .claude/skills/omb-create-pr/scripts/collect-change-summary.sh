#!/usr/bin/env bash
# Collect git change summary for PR body.
# Detects base branch automatically (main or master).
# Usage: bash collect-change-summary.sh
# Output: JSON with files_changed, insertions, deletions, commits, base_branch
set -euo pipefail

# Detect base branch
BASE_BRANCH="main"
if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
  BASE_BRANCH="master"
  if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    echo '{"error": "No main or master branch found", "files_changed": 0, "insertions": 0, "deletions": 0, "commits": [], "base_branch": null}'
    exit 0
  fi
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" || -z "$CURRENT_BRANCH" || "$CURRENT_BRANCH" == "HEAD" ]]; then
  # On base branch: use cached diff + recent commits
  STAT=$(git diff --cached --shortstat 2>/dev/null || echo "")
  COMMITS=$(git log -10 --oneline --no-decorate 2>/dev/null || echo "")
  ON_BASE=true
else
  # On feature branch: diff against base
  STAT=$(git diff "${BASE_BRANCH}...HEAD" --shortstat 2>/dev/null || echo "")
  COMMITS=$(git log "${BASE_BRANCH}..HEAD" --oneline --no-decorate 2>/dev/null || echo "")
  ON_BASE=false
fi

# Parse shortstat
FILES_CHANGED=0
INSERTIONS=0
DELETIONS=0

if [[ -n "$STAT" ]]; then
  FILES_CHANGED=$(echo "$STAT" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo 0)
  INSERTIONS=$(echo "$STAT" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
  DELETIONS=$(echo "$STAT" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
fi

# Build commits JSON array
COMMITS_JSON="[]"
if [[ -n "$COMMITS" ]]; then
  COMMITS_JSON=$(echo "$COMMITS" | jq -R -s 'split("\n") | map(select(length > 0))')
fi

# Output JSON
jq -n \
  --argjson files "${FILES_CHANGED:-0}" \
  --argjson ins "${INSERTIONS:-0}" \
  --argjson del "${DELETIONS:-0}" \
  --argjson commits "$COMMITS_JSON" \
  --arg base "$BASE_BRANCH" \
  --argjson on_base "${ON_BASE}" \
  '{
    files_changed: $files,
    insertions: $ins,
    deletions: $del,
    commits: $commits,
    base_branch: $base,
    on_base_branch: $on_base
  }'
