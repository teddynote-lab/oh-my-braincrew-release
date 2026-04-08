#!/usr/bin/env bash
# Clear the driver field in a session JSON (set to null).
# Usage: clear-driver.sh <session_id> <project_root>
# Output: prints confirmation message on success
# Exit: 0 on success or when session already archived, 1 on truly missing session
# OMB-PLAN-000082
# OMB-PLAN-000085: clear-driver archive tolerance
set -euo pipefail

SESSION_ID="${1:?Usage: clear-driver.sh <session_id> <project_root>}"
PROJECT_ROOT="${2:?Usage: clear-driver.sh <session_id> <project_root>}"

# NOTE: This regex is intentionally stricter than Python's _validate_session_id()
# (which uses a denylist: /, \, \x00, ..). Shell-level allowlist is defense-in-depth.
[[ "$SESSION_ID" =~ ^[0-9]{12}-[a-z0-9]+$ ]] || { echo "[clear-driver] invalid session_id format: ${SESSION_ID}" >&2; exit 1; }

SESSION_FILE="${PROJECT_ROOT}/.omb/sessions/${SESSION_ID}.json"

FINISHED_FILE="${PROJECT_ROOT}/.omb/sessions/finished/${SESSION_ID}.json"
if [ ! -f "${SESSION_FILE}" ]; then
  if [ -f "${FINISHED_FILE}" ]; then
    # Path convention: must match PipelineStorage.archive() in src/omb/pipeline/storage.py
    echo "[clear-driver] session already archived (finished/), driver implicitly cleared"
    exit 0
  fi
  echo "[clear-driver] session file not found (not in sessions/ or finished/): ${SESSION_ID}" >&2
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
