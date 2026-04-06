#!/usr/bin/env bash
# Set the driver field in a session JSON to 'omb-run' with a UTC heartbeat timestamp.
# Usage: set-driver.sh <session_id> <project_root>
# Output: prints confirmation message on success
# Exit: 0 on success, 1 on failure
# OMB-PLAN-000082
set -euo pipefail

SESSION_ID="${1:?Usage: set-driver.sh <session_id> <project_root>}"
PROJECT_ROOT="${2:?Usage: set-driver.sh <session_id> <project_root>}"

SESSION_FILE="${PROJECT_ROOT}/.omb/sessions/${SESSION_ID}.json"

if [ ! -f "${SESSION_FILE}" ]; then
  echo "[set-driver] session file not found: ${SESSION_FILE}" >&2
  exit 1
fi

python3 - "${SESSION_FILE}" <<'PYEOF'
import json, os, sys
from datetime import datetime, timezone

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
data['driver'] = 'omb-run'
data['driver_heartbeat'] = datetime.now(timezone.utc).isoformat()
claude_uuid = os.environ.get('CLAUDE_SESSION_ID', '')
if claude_uuid and not data.get('claude_session_id'):
    data['claude_session_id'] = claude_uuid
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('driver set to omb-run with heartbeat')
PYEOF
