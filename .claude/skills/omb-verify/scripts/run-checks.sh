#!/usr/bin/env bash
# Run verification checks for a single stack layer.
# Usage: bash run-checks.sh <layer> [test-path]
# Output: JSON with per-check results.
# Optional convenience wrapper — verifier agents can invoke commands directly.
set -uo pipefail

LAYER="${1:-}"
TEST_PATH="${2:-}"
LINT_PATH="${3:-}"

# Help flag
if [[ "$LAYER" == "--help" || "$LAYER" == "-h" ]]; then
  cat <<'HELP'
Usage: bash run-checks.sh <layer> [test-path] [lint-path]

Run verification checks for a single stack layer.
Outputs JSON with per-check results.

Layers: python, typescript, node, database, redis
Optional test-path: specific test directory or file to run
Optional lint-path: specific path for ruff/eslint to scan (defaults to .)

Examples:
  bash run-checks.sh python tests/auth/
  bash run-checks.sh python tests/auth/ src/
  bash run-checks.sh typescript
  bash run-checks.sh typescript "" src/
  bash run-checks.sh database
HELP
  exit 0
fi

if [[ -z "$LAYER" ]]; then
  echo "ERROR: Layer name required. Use --help for usage." >&2
  exit 1
fi

# Check if a command exists
cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Run a check and capture result
# Args: check_name command...
# Sets: LAST_RESULT (pass/fail/blocked), LAST_EVIDENCE (output excerpt)
LAST_RESULT=""
LAST_EVIDENCE=""

run_check() {
  local name="$1"
  shift
  local cmd="$*"

  # Check if primary command exists
  local primary_cmd
  primary_cmd=$(echo "$cmd" | awk '{print $1}')
  # Handle npx commands
  if [[ "$primary_cmd" == "npx" ]]; then
    if ! cmd_exists npx; then
      LAST_RESULT="blocked"
      LAST_EVIDENCE="npx not found"
      return
    fi
  elif ! cmd_exists "$primary_cmd"; then
    LAST_RESULT="blocked"
    LAST_EVIDENCE="$primary_cmd not found"
    return
  fi

  local output
  local exit_code
  output=$(eval "$cmd" 2>&1) && exit_code=0 || exit_code=$?

  # Truncate long output for JSON (keep first 500 chars)
  local truncated
  truncated=$(echo "$output" | head -c 500)

  if [[ $exit_code -eq 0 ]]; then
    LAST_RESULT="pass"
  else
    LAST_RESULT="fail"
  fi
  LAST_EVIDENCE="$truncated"
}

# Escape string for JSON output
json_escape() {
  local str="$1"
  # Strip ANSI escape sequences first (color codes, cursor movement, etc.)
  str=$(printf '%s' "$str" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' 2>/dev/null || printf '%s' "$str")
  # Remove remaining control characters (0x00-0x1f except \n \r \t)
  str=$(printf '%s' "$str" | tr -d '\000-\010\013\014\016-\037' 2>/dev/null || printf '%s' "$str")
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

# Collect results
RESULTS=""
add_result() {
  local name="$1"
  local result="$2"
  local evidence="$3"
  local escaped_evidence
  escaped_evidence=$(json_escape "$evidence")

  local entry="{\"check\": \"$name\", \"result\": \"$result\", \"evidence\": \"$escaped_evidence\"}"

  if [[ -n "$RESULTS" ]]; then
    RESULTS="$RESULTS, $entry"
  else
    RESULTS="$entry"
  fi
}

# Execute checks per layer
case "$LAYER" in
  python)
    # pytest
    if cmd_exists pytest; then
      local_path="${TEST_PATH:-tests/}"
      run_check "pytest" "pytest $local_path -v --tb=short 2>&1"
      add_result "pytest" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "pytest" "blocked" "pytest not installed"
    fi

    # Type checker (pyright preferred, fallback to mypy)
    if cmd_exists pyright; then
      run_check "pyright" "pyright 2>&1"
      add_result "type-check (pyright)" "$LAST_RESULT" "$LAST_EVIDENCE"
    elif cmd_exists mypy; then
      run_check "mypy" "mypy --strict . 2>&1"
      add_result "type-check (mypy)" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "type-check" "blocked" "neither pyright nor mypy found"
    fi

    # OMB-PLAN-000088: ruff lint check
    if cmd_exists ruff; then
      if [[ -n "$LINT_PATH" ]]; then
        run_check "ruff" "ruff check $LINT_PATH 2>&1"
      else
        run_check "ruff" "ruff check . 2>&1"
      fi
      add_result "ruff check" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "ruff check" "blocked" "ruff not installed"
    fi
    ;;

  typescript)
    # vitest
    if cmd_exists npx; then
      local_path="${TEST_PATH:-}"
      if [[ -n "$local_path" ]]; then
        run_check "vitest" "npx vitest run $local_path 2>&1"
      else
        run_check "vitest" "npx vitest run 2>&1"
      fi
      add_result "vitest" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "vitest" "blocked" "npx not found"
    fi

    # tsc type check
    if cmd_exists npx; then
      run_check "tsc" "npx tsc --noEmit 2>&1"
      add_result "tsc --noEmit" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "tsc --noEmit" "blocked" "npx not found"
    fi

    # OMB-PLAN-000088: eslint lint check
    if cmd_exists npx; then
      # Determine lint target directory for config detection
      ESLINT_LINT_DIR="${LINT_PATH:-.}"
      # Check if eslint config exists in lint target or project root
      ESLINT_HAS_CONFIG=false
      for ESLINT_CONFIG_FILE in ".eslintrc" ".eslintrc.js" ".eslintrc.json" ".eslintrc.yml" "eslint.config.js" "eslint.config.mjs" "eslint.config.ts"; do
        if [[ -f "${ESLINT_LINT_DIR}/${ESLINT_CONFIG_FILE}" || -f "./${ESLINT_CONFIG_FILE}" ]]; then
          ESLINT_HAS_CONFIG=true
          break
        fi
      done

      if [[ "$ESLINT_HAS_CONFIG" == "true" ]]; then
        if [[ -n "$LINT_PATH" ]]; then
          run_check "eslint" "npx eslint $LINT_PATH 2>&1"
        else
          run_check "eslint" "npx eslint . 2>&1"
        fi
        add_result "eslint" "$LAST_RESULT" "$LAST_EVIDENCE"
      else
        add_result "eslint" "blocked" "no eslint config found"
      fi
    else
      add_result "eslint" "blocked" "npx not found"
    fi
    ;;

  node)
    # jest or vitest
    if cmd_exists npx; then
      local_path="${TEST_PATH:-}"
      # Try vitest first, fall back to jest
      if [[ -f "vitest.config.ts" || -f "vitest.config.js" ]]; then
        if [[ -n "$local_path" ]]; then
          run_check "vitest" "npx vitest run $local_path 2>&1"
        else
          run_check "vitest" "npx vitest run 2>&1"
        fi
        add_result "vitest" "$LAST_RESULT" "$LAST_EVIDENCE"
      else
        if [[ -n "$local_path" ]]; then
          run_check "jest" "npx jest $local_path 2>&1"
        else
          run_check "jest" "npx jest 2>&1"
        fi
        add_result "jest" "$LAST_RESULT" "$LAST_EVIDENCE"
      fi
    else
      add_result "test-runner" "blocked" "npx not found"
    fi

    # tsc type check
    if cmd_exists npx; then
      run_check "tsc" "npx tsc --noEmit 2>&1"
      add_result "tsc --noEmit" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "tsc --noEmit" "blocked" "npx not found"
    fi
    ;;

  database)
    # Postgres connectivity
    if cmd_exists pg_isready; then
      run_check "pg_isready" "pg_isready 2>&1"
      add_result "pg_isready" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "pg_isready" "blocked" "pg_isready not found"
    fi

    # Alembic migration status
    if cmd_exists alembic; then
      run_check "alembic" "alembic current 2>&1"
      add_result "alembic current" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "alembic current" "blocked" "alembic not found"
    fi
    ;;

  redis)
    # Redis connectivity
    if cmd_exists redis-cli; then
      run_check "redis-cli" "redis-cli PING 2>&1"
      add_result "redis-cli PING" "$LAST_RESULT" "$LAST_EVIDENCE"
    else
      add_result "redis-cli PING" "blocked" "redis-cli not found"
    fi
    ;;

  *)
    echo "ERROR: Unknown layer: $LAYER. Supported: python, typescript, node, database, redis" >&2
    exit 1
    ;;
esac

# Count results
TOTAL=0
PASSED=0
FAILED=0
BLOCKED=0

# Count from results string (simple approach — grep exits 1 with no matches, so || true)
PASSED=$(echo "$RESULTS" | grep -o '"result": "pass"' | wc -l | tr -d ' ' || true)
FAILED=$(echo "$RESULTS" | grep -o '"result": "fail"' | wc -l | tr -d ' ' || true)
BLOCKED=$(echo "$RESULTS" | grep -o '"result": "blocked"' | wc -l | tr -d ' ' || true)
TOTAL=$((PASSED + FAILED + BLOCKED))

# Determine overall status
OVERALL="pass"
if [[ "$FAILED" -gt 0 ]]; then
  OVERALL="fail"
elif [[ "$BLOCKED" -gt 0 && "$PASSED" -eq 0 ]]; then
  OVERALL="blocked"
elif [[ "$BLOCKED" -gt 0 ]]; then
  OVERALL="partial"
fi

# Output JSON
cat <<EOF
{
  "layer": "$LAYER",
  "status": "$OVERALL",
  "summary": {"total": $TOTAL, "passed": $PASSED, "failed": $FAILED, "blocked": $BLOCKED},
  "checks": [$RESULTS]
}
EOF
