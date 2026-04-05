#!/usr/bin/env bash
# OMB-PLAN-000028: Test suite for run-coverage.sh coverage enforcement script.
# Usage: bash run-coverage.test.sh
# Run from any directory — paths are resolved relative to this script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COVERAGE_SCRIPT="$SCRIPT_DIR/run-coverage.sh"
FIXTURES_DIR="$SCRIPT_DIR/../tests/fixtures"

# Test harness
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

pass() {
  local name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  [PASS] $name"
}

fail() {
  local name="$1"
  local reason="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "  [FAIL] $name: $reason"
  FAILURES="$FAILURES\n  - $name: $reason"
}

assert_json_field() {
  local json="$1"
  local field="$2"
  local expected="$3"
  local actual
  actual=$(echo "$json" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d$field)" 2>/dev/null || echo "__parse_error__")
  if [[ "$actual" == "$expected" ]]; then
    return 0
  else
    echo "    expected $field=$expected, got $actual"
    return 1
  fi
}

echo "=== run-coverage.sh test suite ==="
echo ""

# ----------------------------------------------------------------------------
# Test 1: Python pass fixture → status PASS
# ----------------------------------------------------------------------------
echo "Test 1: Python pass fixture (86% ≥ 85% threshold) → PASS"
OUTPUT=$(bash "$COVERAGE_SCRIPT" python "$FIXTURES_DIR/coverage-pass.json" 2>&1) || true

if assert_json_field "$OUTPUT" "['status']" "PASS"; then
  pass "Test 1: Python pass fixture → status PASS"
else
  fail "Test 1: Python pass fixture → status PASS" "status was not PASS; output: $OUTPUT"
fi

# ----------------------------------------------------------------------------
# Test 2: Python fail fixture → status FAIL
# ----------------------------------------------------------------------------
echo "Test 2: Python fail fixture (84% < 85% threshold) → FAIL"
OUTPUT=$(bash "$COVERAGE_SCRIPT" python "$FIXTURES_DIR/coverage-fail.json" 2>&1) || true

if assert_json_field "$OUTPUT" "['status']" "FAIL"; then
  pass "Test 2: Python fail fixture → status FAIL"
else
  fail "Test 2: Python fail fixture → status FAIL" "status was not FAIL; output: $OUTPUT"
fi

# ----------------------------------------------------------------------------
# Test 3: TypeScript fixture → layer typescript, correct per-file data
# ----------------------------------------------------------------------------
echo "Test 3: TypeScript fixture → layer=typescript, files correct"
OUTPUT=$(bash "$COVERAGE_SCRIPT" typescript "$FIXTURES_DIR/vitest-coverage-summary.json" 2>&1) || true

LAYER_OK=false
if assert_json_field "$OUTPUT" "['layer']" "typescript" 2>/dev/null; then
  LAYER_OK=true
fi

# Check Chat.tsx is present with pct=88
CHAT_PCT=$(echo "$OUTPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
files = d.get('files', [])
for f in files:
    if 'Chat.tsx' in f.get('file', ''):
        print(f['pct'])
        break
else:
    print('not_found')
" 2>/dev/null || echo "parse_error")

# Check format.ts is present with pct=72
FMT_PCT=$(echo "$OUTPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
files = d.get('files', [])
for f in files:
    if 'format.ts' in f.get('file', ''):
        print(f['pct'])
        break
else:
    print('not_found')
" 2>/dev/null || echo "parse_error")

if [[ "$LAYER_OK" == "true" && "$CHAT_PCT" == "88.0" && "$FMT_PCT" == "72.0" ]]; then
  pass "Test 3: TypeScript fixture → layer and per-file data correct"
else
  fail "Test 3: TypeScript fixture → layer and per-file data correct" "layer_ok=$LAYER_OK chat_pct=$CHAT_PCT fmt_pct=$FMT_PCT; output: $OUTPUT"
fi

# ----------------------------------------------------------------------------
# Test 4: Missing coverage file → status BLOCKED (no crash)
# ----------------------------------------------------------------------------
echo "Test 4: Missing coverage file → status BLOCKED (no crash)"
OUTPUT=$(bash "$COVERAGE_SCRIPT" python "/tmp/nonexistent-coverage-file-$(date +%s).json" 2>&1) || true

if assert_json_field "$OUTPUT" "['status']" "BLOCKED"; then
  pass "Test 4: Missing file → status BLOCKED"
else
  fail "Test 4: Missing file → status BLOCKED" "status was not BLOCKED; output: $OUTPUT"
fi

# ----------------------------------------------------------------------------
# Test 5: Threshold override via THRESHOLD env var
# ----------------------------------------------------------------------------
echo "Test 5: THRESHOLD=90 → fail fixture (84%) → FAIL, pass fixture (86%) → FAIL"
# With threshold=90, even the "pass" fixture (86%) should fail
OUTPUT=$(THRESHOLD=90 bash "$COVERAGE_SCRIPT" python "$FIXTURES_DIR/coverage-pass.json" 2>&1) || true

if assert_json_field "$OUTPUT" "['status']" "FAIL"; then
  pass "Test 5: THRESHOLD=90 override → 86% reports FAIL"
else
  fail "Test 5: THRESHOLD=90 override → 86% reports FAIL" "status was not FAIL at threshold=90; output: $OUTPUT"
fi

# Also verify threshold=80 makes the fail fixture (84%) pass
OUTPUT=$(THRESHOLD=80 bash "$COVERAGE_SCRIPT" python "$FIXTURES_DIR/coverage-fail.json" 2>&1) || true

if assert_json_field "$OUTPUT" "['status']" "PASS"; then
  pass "Test 5b: THRESHOLD=80 override → 84% reports PASS"
else
  fail "Test 5b: THRESHOLD=80 override → 84% reports PASS" "status was not PASS at threshold=80; output: $OUTPUT"
fi

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
echo ""
echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed ==="
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "Failures:$FAILURES"
  exit 1
fi
exit 0
