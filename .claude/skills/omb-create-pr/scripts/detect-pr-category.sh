#!/usr/bin/env bash
# Detect PR categories from changed files.
# Usage: bash detect-pr-category.sh [plan-file-path] [execution-state-path]
# Output: JSON with categories array and primary category
set -euo pipefail

PLAN_FILE="${1:-}"
EXEC_STATE="${2:-}"

# Collect changed file paths
FILES=""

# Try execution state first
if [[ -n "$EXEC_STATE" && -f "$EXEC_STATE" ]]; then
  FILES=$(jq -r '
    .tasks | to_entries[]
    | select(.value.status == "DONE" or .value.status == "DONE_WITH_CONCERNS")
    | .value.files // [] | .[]
  ' "$EXEC_STATE" 2>/dev/null || true)
fi

# Fall back to git diff
if [[ -z "$FILES" ]]; then
  BASE_BRANCH="main"
  if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    BASE_BRANCH="master"
  fi

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" || -z "$CURRENT_BRANCH" ]]; then
    FILES=$(git diff --cached --name-only 2>/dev/null || true)
    if [[ -z "$FILES" ]]; then
      FILES=$(git diff --name-only HEAD~1 2>/dev/null || true)
    fi
  else
    FILES=$(git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null || true)
  fi
fi

# Fall back to plan file analysis
if [[ -z "$FILES" && -n "$PLAN_FILE" && -f "$PLAN_FILE" ]]; then
  FILES=$(grep -oE '[a-zA-Z0-9_./-]+\.(py|ts|tsx|js|jsx|sql|sh|yml|yaml|json|css|html|md)' "$PLAN_FILE" 2>/dev/null || true)
fi

if [[ -z "$FILES" ]]; then
  echo '{"categories": [], "primary": null}'
  exit 0
fi

# Category tracking — use plain string set (bash 3.2 compatible)
CATS_LIST=""

has_cat() {
  local cat="$1"
  echo "$CATS_LIST" | grep -qF "|${cat}|"
}

add_cat() {
  local cat="$1"
  if ! has_cat "$cat"; then
    CATS_LIST="${CATS_LIST}|${cat}|"
  fi
}

detect_category() {
  local file="$1"
  case "$file" in
    # Security
    *auth*|*security*|*middleware/jwt*|*acl*|*rls*|*permission*)
      add_cat "security" ;;
  esac
  case "$file" in
    # Database
    *migration*|*alembic*|*.sql|*schema*|*models/db*|*redis*|*cache*)
      add_cat "database" ;;
  esac
  case "$file" in
    # AI/ML
    *langchain*|*langgraph*|*rag*|*embedding*|*llm*|*agent*|*prompt*)
      add_cat "ai-ml" ;;
  esac
  case "$file" in
    # Electron
    *electron*|*main-process*|*renderer*|*preload*|*ipc*)
      add_cat "electron" ;;
  esac
  case "$file" in
    # Infra
    *docker*|*Dockerfile*|*.github/*|*ci/*|*cd/*|*deploy*|*monitoring*|*slack*|*nginx*|*caddy*)
      add_cat "infra" ;;
  esac
  case "$file" in
    # Performance
    *perf*|*benchmark*|*profil*|*optimi*)
      add_cat "performance" ;;
  esac
  case "$file" in
    # Testing
    *test*|*spec.*|*__tests__*|*conftest*|*fixture*)
      add_cat "testing" ;;
  esac
  case "$file" in
    # Config
    *.env*|*config*|*settings*|*vercel.json|*tsconfig*|*pyproject*|*package.json)
      add_cat "config" ;;
  esac
  case "$file" in
    # Frontend
    *.tsx|*.jsx|*.css|*component*|*hook*|*tailwind*|*vite*)
      add_cat "frontend" ;;
  esac
  case "$file" in
    # Backend (Python)
    *.py)
      add_cat "backend" ;;
  esac
  case "$file" in
    # Backend (Node.js/TypeScript non-frontend)
    *.ts)
      # Only if not already frontend
      if [[ "$file" != *".tsx" && "$file" != *"component"* && "$file" != *"hook"* ]]; then
        add_cat "backend"
      fi
      ;;
  esac
  case "$file" in
    # Docs
    *.md|*docs/*|*README*|*CHANGELOG*|*ADR*)
      add_cat "docs" ;;
  esac
}

while IFS= read -r file; do
  [[ -n "$file" ]] && detect_category "$file"
done <<< "$FILES"

# Build sorted categories list
ALL_KNOWN=(security backend frontend database ai-ml electron infra performance testing config docs)
SORTED=()
for cat in "${ALL_KNOWN[@]}"; do
  if has_cat "$cat"; then
    SORTED+=("\"$cat\"")
  fi
done

# Determine primary (highest priority category present)
PRIMARY="null"
PRIORITY_ORDER=(security backend frontend database ai-ml electron infra performance testing config docs)
for pcat in "${PRIORITY_ORDER[@]}"; do
  if has_cat "$pcat"; then
    PRIMARY="\"$pcat\""
    break
  fi
done

# Format JSON
if [[ ${#SORTED[@]} -eq 0 ]]; then
  echo '{"categories": [], "primary": null}'
else
  JOINED=$(printf ",%s" "${SORTED[@]}")
  JOINED="${JOINED:1}"
  echo "{\"categories\": [${JOINED}], \"primary\": ${PRIMARY}}"
fi
