#!/usr/bin/env bash
# Refresh the driver heartbeat for an active session.
# Usage: touch-driver-heartbeat.sh <session_id> <project_root>
# Output: prints confirmation message on success
# Exit: 0 on success, 1 on failure
set -euo pipefail

SESSION_ID="${1:?Usage: touch-driver-heartbeat.sh <session_id> <project_root>}"
PROJECT_ROOT="${2:?Usage: touch-driver-heartbeat.sh <session_id> <project_root>}"

SESSION_FILE="${PROJECT_ROOT}/.omb/sessions/${SESSION_ID}.json"

if [ ! -f "${SESSION_FILE}" ]; then
  echo "[touch-driver-heartbeat] session file not found: ${SESSION_FILE}" >&2
  exit 1
fi

python3 - "${SESSION_FILE}" <<'PYEOF'
import json, sys
from datetime import datetime, timezone

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data['driver_heartbeat'] = datetime.now(timezone.utc).isoformat()
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('driver heartbeat refreshed')
PYEOF
