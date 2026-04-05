#!/usr/bin/env bash
# Run Python CI checks locally before PR creation.
# Mirrors .github/workflows/python-ci.yml — keep in sync when CI changes.
# Output: JSON array with per-check {name, status, detail}
# Dependencies: python3, ruff, pyright, pytest (checks availability before running)
set -uo pipefail

CHECKS="[]"
OVERALL_STATUS=0

add_check() {
  local name="$1" status="$2" detail="$3"
  CHECKS=$(python3 -c "
import json, sys
checks = json.loads(sys.argv[1])
checks.append({'name': sys.argv[2], 'status': sys.argv[3], 'detail': sys.argv[4]})
print(json.dumps(checks))
" "$CHECKS" "$name" "$status" "$detail")
}

# Verify python3 is available
if ! command -v python3 &>/dev/null; then
  echo '[{"name": "python_ci", "status": "fail", "detail": "python3 not found in PATH"}]'
  exit 1
fi

# Check if relevant files were changed (mirrors CI on.paths triggers)
BASE_BRANCH="main"
if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
  BASE_BRANCH="master"
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [[ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]]; then
  CHANGED_FILES=$(git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null || echo "")
else
  CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
fi

# Mirror CI trigger paths: src/**, tests/**, pyproject.toml
RELEVANT_FILES=$(echo "$CHANGED_FILES" | grep -E '^(src/|tests/|pyproject\.toml)' || true)

if [[ -z "$RELEVANT_FILES" ]]; then
  add_check "python_ci" "pass" "No relevant files changed (src/, tests/, pyproject.toml) — skipping Python CI checks"
  echo "$CHECKS" | python3 -c "import json,sys; print(json.dumps(json.loads(sys.stdin.read()), indent=2))"
  exit 0
fi

RELEVANT_COUNT=$(echo "$RELEVANT_FILES" | wc -l | tr -d ' ')

# 1. Lint (ruff) — mirrors: ruff check src/ tests/
if command -v ruff &>/dev/null; then
  RUFF_OUTPUT=$(ruff check src/ tests/ 2>&1)
  RUFF_EXIT=$?
  if [[ $RUFF_EXIT -eq 0 ]]; then
    add_check "ruff_lint" "pass" "ruff check passed (${RELEVANT_COUNT} relevant files changed)"
  else
    ERROR_COUNT=$(echo "$RUFF_OUTPUT" | grep -cE '^\S+:\d+:\d+' || echo "0")
    add_check "ruff_lint" "fail" "${ERROR_COUNT} lint error(s) found"
    OVERALL_STATUS=1
  fi
else
  add_check "ruff_lint" "fail" "ruff not installed — run: pip install ruff"
  OVERALL_STATUS=1
fi

# 2. Type check (pyright) — mirrors: pyright src/
if command -v pyright &>/dev/null; then
  PYRIGHT_OUTPUT=$(pyright src/ 2>&1)
  PYRIGHT_EXIT=$?
  if [[ $PYRIGHT_EXIT -eq 0 ]]; then
    add_check "pyright_typecheck" "pass" "pyright passed (strict mode)"
  else
    ERROR_COUNT=$(echo "$PYRIGHT_OUTPUT" | grep -oE '[0-9]+ error' | head -1 | grep -oE '[0-9]+' || echo "?")
    add_check "pyright_typecheck" "fail" "${ERROR_COUNT} type error(s) found"
    OVERALL_STATUS=1
  fi
else
  add_check "pyright_typecheck" "fail" "pyright not installed — run: pip install pyright"
  OVERALL_STATUS=1
fi

# 3. Test (pytest) — mirrors: pytest -v
if command -v pytest &>/dev/null; then
  PYTEST_OUTPUT=$(pytest -v 2>&1)
  PYTEST_EXIT=$?
  if [[ $PYTEST_EXIT -eq 0 ]]; then
    SUMMARY=$(echo "$PYTEST_OUTPUT" | tail -1)
    add_check "pytest_tests" "pass" "Tests passed: ${SUMMARY}"
  else
    SUMMARY=$(echo "$PYTEST_OUTPUT" | grep -E '(FAILED|ERROR|failed)' | tail -3 | tr '\n' '; ')
    add_check "pytest_tests" "fail" "Tests failed: ${SUMMARY}"
    OVERALL_STATUS=1
  fi
else
  add_check "pytest_tests" "fail" "pytest not installed — run: pip install pytest"
  OVERALL_STATUS=1
fi

echo "$CHECKS" | python3 -c "import json,sys; print(json.dumps(json.loads(sys.stdin.read()), indent=2))"
exit $OVERALL_STATUS
