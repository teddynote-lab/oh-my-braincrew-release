#!/usr/bin/env bash
# Clear the driver field in a session JSON (set to null).
# Usage: clear-driver.sh <session_id> <project_root>
# Output: prints confirmation message on success
# Exit: 0 on success, 1 on failure
# OMB-PLAN-000082
set -euo pipefail

SESSION_ID="${1:?Usage: clear-driver.sh <session_id> <project_root>}"
PROJECT_ROOT="${2:?Usage: clear-driver.sh <session_id> <project_root>}"

SESSION_FILE="${PROJECT_ROOT}/.omb/sessions/${SESSION_ID}.json"

if [ ! -f "${SESSION_FILE}" ]; then
  echo "[clear-driver] session file not found: ${SESSION_FILE}" >&2
  exit 1
fi

python3 - "${SESSION_FILE}" <<'PYEOF'
import json, sys

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data['driver'] = None
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('driver cleared')
PYEOF
