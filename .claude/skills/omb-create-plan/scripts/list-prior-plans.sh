#!/usr/bin/env bash
# Lists existing plans with title and date for prior plan awareness
set -euo pipefail
PLANS_DIR="${1:-.omb/plans}"
if [[ ! -d "$PLANS_DIR" ]]; then
  echo "No plans directory found"; exit 0
fi
for f in "$PLANS_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  title=$(head -5 "$f" | grep -m1 "^## Plan:" | sed 's/^## Plan: //' || echo "Untitled")
  echo "$(basename "$f"): $title"
done
