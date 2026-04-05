#!/usr/bin/env bash
# Counts P0 and P1 OPEN issues from a review tracker table on stdin.
# Usage: echo "<tracker-table>" | bash count-open-blockers.sh
# Output: P0=N P1=N
set -euo pipefail

INPUT=$(cat)

P0_COUNT=$(echo "$INPUT" | grep -ciE '\|\s*P0\s*\|.*\|\s*OPEN\s*\|' || echo "0")
P1_COUNT=$(echo "$INPUT" | grep -ciE '\|\s*P1\s*\|.*\|\s*OPEN\s*\|' || echo "0")

echo "P0=$P0_COUNT P1=$P1_COUNT"
