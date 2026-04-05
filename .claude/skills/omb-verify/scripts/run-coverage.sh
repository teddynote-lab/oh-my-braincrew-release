#!/usr/bin/env bash
# OMB-PLAN-000028: Coverage enforcement script for Python (pytest-cov) and TypeScript (vitest).
# Usage: bash run-coverage.sh <layer> [coverage-file-path] [changed-files-list]
# Output: JSON with per-file coverage results and overall PASS/FAIL/BLOCKED status.
# Status values are UPPER_CASE: PASS, FAIL, BLOCKED.
#
# Layers: python, typescript
# Environment:
#   THRESHOLD  — minimum line coverage percentage (default: 85)
#
# Phase modes:
#   Phase 1 (run + parse): no coverage-file-path provided — runs pytest/vitest to generate report
#   Phase 2 (parse only): coverage-file-path provided — parses existing report file
set -euo pipefail

LAYER="${1:-}"
COVERAGE_FILE="${2:-}"
CHANGED_FILES="${3:-}"
THRESHOLD="${THRESHOLD:-85}"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
if [[ "$LAYER" == "--help" || "$LAYER" == "-h" ]]; then
  cat <<'HELP'
Usage: bash run-coverage.sh <layer> [coverage-file-path] [changed-files-list]

Check test coverage for changed files against a threshold.

Layers: python, typescript
Optional coverage-file-path: path to existing coverage JSON file to parse
Optional changed-files-list: comma- or newline-separated list of files to check
Environment:
  THRESHOLD  minimum line coverage percentage (default: 85)

Output: JSON with per-file coverage and overall status (PASS/FAIL/BLOCKED)

Examples:
  bash run-coverage.sh python coverage.json
  bash run-coverage.sh typescript coverage-summary.json
  THRESHOLD=90 bash run-coverage.sh python coverage.json
HELP
  exit 0
fi

if [[ -z "$LAYER" ]]; then
  echo "ERROR: Layer name required. Use --help for usage." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

json_escape() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

output_blocked() {
  local reason="$1"
  local escaped
  escaped=$(json_escape "$reason")
  cat <<EOF
{
  "layer": "$LAYER",
  "status": "BLOCKED",
  "threshold": $THRESHOLD,
  "reason": "$escaped",
  "files": [],
  "summary": {"total": 0, "passed": 0, "failed": 0, "blocked": 1}
}
EOF
}

# ---------------------------------------------------------------------------
# Validate coverage file if provided
# ---------------------------------------------------------------------------
if [[ -n "$COVERAGE_FILE" && ! -f "$COVERAGE_FILE" ]]; then
  output_blocked "coverage file not found: $COVERAGE_FILE"
  exit 0
fi

# ---------------------------------------------------------------------------
# Phase 1: Run coverage tool to generate report (no file provided)
# ---------------------------------------------------------------------------
if [[ -z "$COVERAGE_FILE" ]]; then
  case "$LAYER" in
    python)
      if ! cmd_exists pytest; then
        output_blocked "pytest not installed"
        exit 0
      fi
      COVERAGE_FILE="coverage.json"
      if ! pytest --cov --cov-report=json:"$COVERAGE_FILE" -q >/dev/null 2>&1; then
        output_blocked "pytest --cov run failed — check test errors"
        exit 0
      fi
      ;;
    typescript)
      if ! cmd_exists npx; then
        output_blocked "npx not found"
        exit 0
      fi
      COVERAGE_FILE="coverage/coverage-summary.json"
      if ! npx vitest run --coverage --coverage.reporter=json-summary >/dev/null 2>&1; then
        output_blocked "vitest --coverage run failed — check test errors"
        exit 0
      fi
      ;;
    *)
      output_blocked "unsupported layer: $LAYER (supported: python, typescript)"
      exit 0
      ;;
  esac

  if [[ ! -f "$COVERAGE_FILE" ]]; then
    output_blocked "coverage report not generated at: $COVERAGE_FILE"
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Phase 2: Parse coverage JSON
# ---------------------------------------------------------------------------
if ! cmd_exists python3; then
  output_blocked "python3 not available for JSON parsing"
  exit 0
fi

# Build per-layer parse script
case "$LAYER" in
  python)
    # pytest-cov coverage.json format:
    # { "files": { "path": { "summary": { "percent_covered": N } } } }
    PARSE_SCRIPT=$(cat <<'PYEOF'
import sys, json

coverage_file = sys.argv[1]
threshold = float(sys.argv[2])
changed_files_arg = sys.argv[3] if len(sys.argv) > 3 else ""

with open(coverage_file) as f:
    data = json.load(f)

all_files = data.get("files", {})

# Filter to changed files if specified
if changed_files_arg:
    changed = set(p.strip() for p in changed_files_arg.replace(",", "\n").split("\n") if p.strip())
    files_to_check = {k: v for k, v in all_files.items() if k in changed}
else:
    files_to_check = all_files

results = []
passed = 0
failed = 0

for filepath, fdata in files_to_check.items():
    summary = fdata.get("summary", {})
    pct = summary.get("percent_covered", 0.0)
    covered = summary.get("covered_lines", 0)
    total = summary.get("num_statements", 0)
    missing = summary.get("missing_lines", 0)
    file_status = "PASS" if pct >= threshold else "FAIL"
    if file_status == "PASS":
        passed += 1
    else:
        failed += 1
    results.append({
        "file": filepath,
        "pct": round(pct, 1),
        "covered": covered,
        "total": total,
        "missing": missing,
        "status": file_status
    })

overall = "PASS" if failed == 0 and len(results) > 0 else ("FAIL" if failed > 0 else "BLOCKED")
summary_out = {"total": len(results), "passed": passed, "failed": failed, "blocked": 0}
print(json.dumps({"files": results, "overall": overall, "summary": summary_out}))
PYEOF
)
    PARSE_ARGS=("$COVERAGE_FILE" "$THRESHOLD" "${CHANGED_FILES:-}")
    ;;

  typescript)
    # vitest coverage-summary.json format:
    # { "total": {...}, "src/file.ts": { "lines": { "pct": N } } }
    PARSE_SCRIPT=$(cat <<'PYEOF'
import sys, json

coverage_file = sys.argv[1]
threshold = float(sys.argv[2])
changed_files_arg = sys.argv[3] if len(sys.argv) > 3 else ""

with open(coverage_file) as f:
    data = json.load(f)

# Filter out the "total" key — it's not a real file
all_files = {k: v for k, v in data.items() if k != "total"}

# Filter to changed files if specified
if changed_files_arg:
    changed = set(p.strip() for p in changed_files_arg.replace(",", "\n").split("\n") if p.strip())
    files_to_check = {k: v for k, v in all_files.items() if k in changed}
else:
    files_to_check = all_files

results = []
passed = 0
failed = 0

for filepath, fdata in files_to_check.items():
    lines = fdata.get("lines", {})
    pct = float(lines.get("pct", 0))
    covered = lines.get("covered", 0)
    total = lines.get("total", 0)
    missing = total - covered
    file_status = "PASS" if pct >= threshold else "FAIL"
    if file_status == "PASS":
        passed += 1
    else:
        failed += 1
    results.append({
        "file": filepath,
        "pct": round(pct, 1),
        "covered": covered,
        "total": total,
        "missing": missing,
        "status": file_status
    })

overall = "PASS" if failed == 0 and len(results) > 0 else ("FAIL" if failed > 0 else "BLOCKED")
summary_out = {"total": len(results), "passed": passed, "failed": failed, "blocked": 0}
print(json.dumps({"files": results, "overall": overall, "summary": summary_out}))
PYEOF
)
    PARSE_ARGS=("$COVERAGE_FILE" "$THRESHOLD" "${CHANGED_FILES:-}")
    ;;

  *)
    output_blocked "unsupported layer: $LAYER (supported: python, typescript)"
    exit 0
    ;;
esac

# Run the parse script
PARSE_OUTPUT=""
PARSE_EXIT=0
PARSE_OUTPUT=$(python3 -c "$PARSE_SCRIPT" "${PARSE_ARGS[@]}" 2>&1) || PARSE_EXIT=$?

if [[ $PARSE_EXIT -ne 0 ]]; then
  output_blocked "JSON parsing failed: $PARSE_OUTPUT"
  exit 0
fi

# Extract fields from parse output
OVERALL=$(echo "$PARSE_OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['overall'])" 2>/dev/null || echo "BLOCKED")
FILES_JSON=$(echo "$PARSE_OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(json.dumps(d['files']))" 2>/dev/null || echo "[]")
TOTAL=$(echo "$PARSE_OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['summary']['total'])" 2>/dev/null || echo "0")
PASSED=$(echo "$PARSE_OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['summary']['passed'])" 2>/dev/null || echo "0")
FAILED=$(echo "$PARSE_OUTPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d['summary']['failed'])" 2>/dev/null || echo "0")

# ---------------------------------------------------------------------------
# Output JSON
# ---------------------------------------------------------------------------
cat <<EOF
{
  "layer": "$LAYER",
  "status": "$OVERALL",
  "threshold": $THRESHOLD,
  "files": $FILES_JSON,
  "summary": {"total": $TOTAL, "passed": $PASSED, "failed": $FAILED, "blocked": 0}
}
EOF
