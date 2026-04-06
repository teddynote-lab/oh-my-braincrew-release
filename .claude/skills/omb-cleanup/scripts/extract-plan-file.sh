#!/usr/bin/env bash
# Extracts the plan_file value from a session JSON file
# Usage: extract-plan-file.sh <session-file>
# Output: plan_file value (or empty string if not set)
# Exit: 0 on success, 1 if session file not found
# OMB-PLAN-000082
set -euo pipefail

SESSION_FILE="${1:?Usage: extract-plan-file.sh <session-file>}"

if [[ ! -f "$SESSION_FILE" ]]; then
  echo "ERROR: Session file not found: $SESSION_FILE" >&2
  exit 1
fi

python3 -c "
import json, sys
with open(sys.argv[1]) as fh:
    d = json.load(fh)
print(d.get('plan_file', ''))
" "$SESSION_FILE"
