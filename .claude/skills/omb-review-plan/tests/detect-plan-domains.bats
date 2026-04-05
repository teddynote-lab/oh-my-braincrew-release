#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts"
FIXTURE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fixtures"

@test "detects prompt scope from compound keywords" {
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$FIXTURE_DIR/plan-prompt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"prompt":true'* ]]
  # Cross-domain false positive guards
  [[ "$output" == *'"designer":false'* ]]
  [[ "$output" == *'"architect":false'* ]]
  [[ "$output" == *'"infra":false'* ]]
  [[ "$output" == *'"security":false'* ]]
}

@test "detects designer scope" {
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$FIXTURE_DIR/plan-designer.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"designer":true'* ]]
  # Cross-domain false positive guards
  [[ "$output" == *'"prompt":false'* ]]
  [[ "$output" == *'"architect":false'* ]]
  [[ "$output" == *'"security":false'* ]]
}

@test "detects architect scope" {
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$FIXTURE_DIR/plan-architect.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"architect":true'* ]]
  [[ "$output" == *'"prompt":false'* ]]
  [[ "$output" == *'"designer":false'* ]]
}

@test "no false positive when no new keywords present" {
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$FIXTURE_DIR/plan-no-new-scopes.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"prompt":false'* ]]
  [[ "$output" == *'"designer":false'* ]]
  [[ "$output" == *'"architect":false'* ]]
}

@test "prompt verb alone does not trigger prompt scope" {
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$FIXTURE_DIR/plan-prompt-verb.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"prompt":false'* ]]
}

@test "existing domains unchanged after modification" {
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$FIXTURE_DIR/plan-no-new-scopes.md"
  [ "$status" -eq 0 ]
  # All 11 fields verified
  [[ "$output" == *'"frontend":true'* ]]
  [[ "$output" == *'"backend_api":true'* ]]
  [[ "$output" == *'"electron":false'* ]]
  [[ "$output" == *'"database":false'* ]]
  [[ "$output" == *'"langchain":false'* ]]
  [[ "$output" == *'"security":false'* ]]
  [[ "$output" == *'"infra":false'* ]]
  [[ "$output" == *'"async":false'* ]]
  [[ "$output" == *'"prompt":false'* ]]
  [[ "$output" == *'"designer":false'* ]]
  [[ "$output" == *'"architect":false'* ]]
}

@test "bare layout or animation words do not trigger designer scope" {
  local tmpfile="$(mktemp)"
  cat > "$tmpfile" << 'PLAN'
## Plan: Frontend Layout Refactor
### Context
Improve the grid layout and add animation transitions to the card component.
### Tasks
| # | Task | Agent | Deliverable |
|---|------|-------|-------------|
| 1 | Refactor layout grid | frontend-engineer | `src/Grid.tsx` |
PLAN
  run bash "$SCRIPT_DIR/detect-plan-domains.sh" "$tmpfile"
  rm -f "$tmpfile"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"designer":false'* ]]
  [[ "$output" == *'"frontend":true'* ]]
}
