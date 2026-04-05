#!/usr/bin/env bash
# Validate PR readiness checklist.
# Checks: uncommitted changes, conventional commits, branch != main, no secrets, gh auth.
# Usage: bash validate-pr-checklist.sh
# Output: JSON with per-check {name, status, detail}
set -euo pipefail

CHECKS="[]"

add_check() {
  local name="$1" status="$2" detail="$3"
  CHECKS=$(echo "$CHECKS" | jq --arg n "$name" --arg s "$status" --arg d "$detail" \
    '. + [{"name": $n, "status": $s, "detail": $d}]')
}

# 1. Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null || echo "")
if [[ -z "$UNCOMMITTED" ]]; then
  add_check "uncommitted_changes" "pass" "Working tree clean"
else
  COUNT=$(echo "$UNCOMMITTED" | wc -l | tr -d ' ')
  add_check "uncommitted_changes" "warn" "${COUNT} uncommitted file(s) — consider committing or stashing"
fi

# 2. Check branch is not main/master
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  add_check "branch_check" "warn" "Currently on ${CURRENT_BRANCH} — PRs usually come from feature branches"
else
  add_check "branch_check" "pass" "On branch: ${CURRENT_BRANCH}"
fi

# 3. Check conventional commits
BASE_BRANCH="main"
if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
  BASE_BRANCH="master"
fi

if [[ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]]; then
  COMMITS=$(git log "${BASE_BRANCH}..HEAD" --oneline --no-decorate 2>/dev/null || echo "")
else
  COMMITS=$(git log -5 --oneline --no-decorate 2>/dev/null || echo "")
fi

if [[ -n "$COMMITS" ]]; then
  NON_CONVENTIONAL=$(echo "$COMMITS" | grep -cvE '^[a-f0-9]+ (feat|fix|refactor|docs|test|chore|perf|ci)\(' || true)
  TOTAL=$(echo "$COMMITS" | wc -l | tr -d ' ')
  if [[ "$NON_CONVENTIONAL" -eq 0 ]]; then
    add_check "conventional_commits" "pass" "All ${TOTAL} commit(s) follow conventional format"
  else
    add_check "conventional_commits" "warn" "${NON_CONVENTIONAL}/${TOTAL} commit(s) do not follow conventional format"
  fi
else
  add_check "conventional_commits" "warn" "No commits found to check"
fi

# 4. Check for secrets patterns
SECRET_PATTERNS='(PRIVATE_KEY|SECRET_KEY|API_KEY|PASSWORD|TOKEN|Bearer\s+[a-zA-Z0-9._-]{20,})'
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
if [[ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]]; then
  BRANCH_FILES=$(git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null || echo "")
else
  BRANCH_FILES=""
fi
ALL_FILES=$(echo -e "${STAGED_FILES}\n${BRANCH_FILES}" | sort -u | grep -v '^$' || true)

SECRETS_FOUND=false
if [[ -n "$ALL_FILES" ]]; then
  while IFS= read -r file; do
    if [[ -f "$file" && ! "$file" =~ \.(md|lock|sum)$ ]]; then
      if grep -qE "$SECRET_PATTERNS" "$file" 2>/dev/null; then
        SECRETS_FOUND=true
        break
      fi
    fi
  done <<< "$ALL_FILES"
fi

if [[ "$SECRETS_FOUND" == "true" ]]; then
  add_check "no_secrets" "fail" "Potential secrets detected in changed files — review before pushing"
else
  add_check "no_secrets" "pass" "No secret patterns detected"
fi

# 5. Check gh CLI authentication
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null 2>&1; then
    add_check "gh_auth" "pass" "gh CLI authenticated"
  else
    add_check "gh_auth" "warn" "gh CLI not authenticated — PR will be saved as markdown file instead"
  fi
else
  add_check "gh_auth" "warn" "gh CLI not installed — PR will be saved as markdown file instead"
fi

# 6. Check Co-Authored-By trailer
if [[ -n "$COMMITS" ]]; then
  # Check last commit for trailer
  LAST_COMMIT_BODY=$(git log -1 --format=%B 2>/dev/null || echo "")
  if echo "$LAST_COMMIT_BODY" | grep -q "Co-Authored-By: Braincrew(dev@brain-crew.com)"; then
    add_check "co_authored_trailer" "pass" "Co-Authored-By trailer present"
  else
    add_check "co_authored_trailer" "warn" "Co-Authored-By: Braincrew(dev@brain-crew.com) trailer missing from last commit"
  fi
else
  add_check "co_authored_trailer" "warn" "No commits to check for trailer"
fi

echo "$CHECKS" | jq '.'
