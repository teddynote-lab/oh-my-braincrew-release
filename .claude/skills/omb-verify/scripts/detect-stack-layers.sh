#!/usr/bin/env bash
# Detect stack layers from execution state JSON or plan file.
# Usage: bash detect-stack-layers.sh <execution-state.json | plan-file.md>
# Output: JSON with detected layers, suggested tier, file count, and security flag.
# No jq dependency — pure bash (grep/sed).
set -euo pipefail

INPUT_FILE="${1:-}"

# Help flag
if [[ "$INPUT_FILE" == "--help" || "$INPUT_FILE" == "-h" ]]; then
  cat <<'HELP'
Usage: bash detect-stack-layers.sh <execution-state.json | plan-file.md>

Detects stack layers from files referenced in execution state or plan.
Outputs JSON:
  {
    "layers": ["python", "typescript", ...],
    "tier": "LIGHT|STANDARD|THOROUGH",
    "totalFiles": N,
    "securityRelated": true|false
  }

Input formats:
  .json  — Reads filesCreated/filesModified from execution state
  .md    — Reads Deliverable column from plan Tasks table
HELP
  exit 0
fi

if [[ -z "$INPUT_FILE" ]]; then
  echo "ERROR: Input file path required. Use --help for usage." >&2
  exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: File not found: $INPUT_FILE" >&2
  exit 1
fi

# Collect file paths from input
FILE_LIST=""

if [[ "$INPUT_FILE" == *.json ]]; then
  # Extract file paths from JSON execution state
  # Match "filesCreated": ["path", ...] and "filesModified": ["path", ...]
  # Pure bash: grep for quoted strings after filesCreated/filesModified
  FILE_LIST=$(grep -oE '"[^"]+\.(py|ts|tsx|js|jsx|sql|css|scss|html|sh|yaml|yml|json|md|dockerfile)"' "$INPUT_FILE" 2>/dev/null | tr -d '"' || true)
elif [[ "$INPUT_FILE" == *.md ]]; then
  # Extract deliverable paths from plan Tasks table
  # Tasks table rows: | # | Task | Agent | Model | Depends On | Deliverable |
  # Extract the last column (Deliverable) from table rows
  FILE_LIST=$(grep -E '^\|[[:space:]]*[0-9]' "$INPUT_FILE" 2>/dev/null | \
    sed 's/.*|[^|]*//' | \
    grep -oE '[a-zA-Z0-9_./-]+\.[a-zA-Z]+' || true)

  # Also look for file paths in backticks throughout the plan
  BACKTICK_FILES=$(grep -oE '`[a-zA-Z0-9_./-]+\.[a-zA-Z]+`' "$INPUT_FILE" 2>/dev/null | tr -d '`' || true)
  FILE_LIST="$FILE_LIST
$BACKTICK_FILES"
else
  echo "ERROR: Unsupported file type. Use .json or .md" >&2
  exit 1
fi

# Deduplicate and clean
FILE_LIST=$(echo "$FILE_LIST" | sort -u | grep -v '^$' || true)
TOTAL_FILES=$(echo "$FILE_LIST" | grep -c '[^[:space:]]' 2>/dev/null || true)
TOTAL_FILES="${TOTAL_FILES:-0}"
# grep -c may produce "0\n0" if FILE_LIST is empty and contains a blank line; take first line only
TOTAL_FILES=$(echo "$TOTAL_FILES" | head -1)

# Layer detection flags
HAS_PYTHON=false
HAS_TYPESCRIPT=false
HAS_NODE=false
HAS_DATABASE=false
HAS_REDIS=false
HAS_FRONTEND=false
HAS_INFRA=false
HAS_LANGCHAIN=false
HAS_ELECTRON=false
HAS_SECURITY=false

# Classify by extension
if echo "$FILE_LIST" | grep -qE '\.py$'; then
  HAS_PYTHON=true
fi

if echo "$FILE_LIST" | grep -qE '\.(ts|tsx)$'; then
  HAS_TYPESCRIPT=true
fi

if echo "$FILE_LIST" | grep -qE '\.(js|jsx)$'; then
  # Check if React (jsx) or Node
  if echo "$FILE_LIST" | grep -qE '\.jsx$'; then
    HAS_TYPESCRIPT=true  # React components
  else
    HAS_NODE=true
  fi
fi

if echo "$FILE_LIST" | grep -qE '\.sql$'; then
  HAS_DATABASE=true
fi

if echo "$FILE_LIST" | grep -qE '\.(css|scss|html)$'; then
  HAS_FRONTEND=true
fi

if echo "$FILE_LIST" | grep -qiE '\.(sh|yaml|yml|dockerfile)$'; then
  HAS_INFRA=true
fi

# Classify by path patterns
if echo "$FILE_LIST" | grep -qiE '(migration|alembic|schema)'; then
  HAS_DATABASE=true
fi

if echo "$FILE_LIST" | grep -qiE '(redis|cache)'; then
  HAS_REDIS=true
fi

if echo "$FILE_LIST" | grep -qiE '(langchain|langgraph)'; then
  HAS_LANGCHAIN=true
fi

if echo "$FILE_LIST" | grep -qiE '(electron|preload|main/.*\.(ts|js))'; then
  HAS_ELECTRON=true
fi

if echo "$FILE_LIST" | grep -qiE '(components/|pages/|app/.*\.(tsx|jsx))'; then
  HAS_FRONTEND=true
fi

if echo "$FILE_LIST" | grep -qiE '(docker|\.github|ci|deploy)'; then
  HAS_INFRA=true
fi

# Security detection
if echo "$FILE_LIST" | grep -qiE '(auth|security|middleware|permission|acl|rls|jwt|token)'; then
  HAS_SECURITY=true
fi

# Build layers array (pure bash, no jq)
LAYERS=""
add_layer() {
  if [[ -n "$LAYERS" ]]; then
    LAYERS="$LAYERS, \"$1\""
  else
    LAYERS="\"$1\""
  fi
}

if [[ "$HAS_PYTHON" == "true" ]]; then add_layer "python"; fi
if [[ "$HAS_TYPESCRIPT" == "true" ]]; then add_layer "typescript"; fi
if [[ "$HAS_NODE" == "true" ]]; then add_layer "node"; fi
if [[ "$HAS_DATABASE" == "true" ]]; then add_layer "database"; fi
if [[ "$HAS_REDIS" == "true" ]]; then add_layer "redis"; fi
if [[ "$HAS_FRONTEND" == "true" ]]; then add_layer "frontend"; fi
if [[ "$HAS_INFRA" == "true" ]]; then add_layer "infra"; fi
if [[ "$HAS_LANGCHAIN" == "true" ]]; then add_layer "langchain"; fi
if [[ "$HAS_ELECTRON" == "true" ]]; then add_layer "electron"; fi
if [[ "$HAS_SECURITY" == "true" ]]; then add_layer "security"; fi

# Determine tier
TIER="STANDARD"
if [[ "$HAS_SECURITY" == "true" ]]; then
  TIER="THOROUGH"
elif (( TOTAL_FILES > 20 )); then
  TIER="THOROUGH"
elif (( TOTAL_FILES <= 5 )); then
  TIER="LIGHT"
fi

# Security flag
SECURITY_RELATED="false"
if [[ "$HAS_SECURITY" == "true" ]]; then
  SECURITY_RELATED="true"
fi

# Output JSON
cat <<EOF
{
  "layers": [$LAYERS],
  "tier": "$TIER",
  "totalFiles": $TOTAL_FILES,
  "securityRelated": $SECURITY_RELATED
}
EOF
