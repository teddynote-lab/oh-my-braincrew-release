#!/usr/bin/env bash
# Returns the next ADR number (zero-padded to 3 digits).
# Reads docs/adr/ for existing ADR files matching NNN-*.md pattern.
# Usage: bash next-adr-number.sh
# Output: "001" (or next available number)
set -euo pipefail

ADR_DIR="docs/adr"

if [[ ! -d "$ADR_DIR" ]]; then
  echo "001"
  exit 0
fi

HIGHEST=$(ls "$ADR_DIR" 2>/dev/null | grep -oE '^[0-9]{3}' | sort -rn | head -1)

if [[ -z "$HIGHEST" ]]; then
  echo "001"
else
  NEXT=$((10#$HIGHEST + 1))
  printf "%03d\n" "$NEXT"
fi
