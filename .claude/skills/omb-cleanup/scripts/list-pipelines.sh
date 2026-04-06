#!/usr/bin/env bash
# Lists active pipeline sessions with id, name, status, and current task
# Usage: list-pipelines.sh [sessions-dir]
# Output: one line per session file: <file>: session_id=? name=? status=? current_task=?
# Exit: 0 always (missing directory is not an error)
# OMB-PLAN-000082
set -euo pipefail

SESSIONS_DIR="${1:-.omb/sessions}"

if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "No sessions directory found: $SESSIONS_DIR" >&2
  exit 0
fi

python3 -c "
import json, sys, glob, os

sessions_dir = sys.argv[1]
for f in sorted(glob.glob(os.path.join(sessions_dir, '*.json'))):
    try:
        with open(f) as fh:
            d = json.load(fh)
        print('{}: session_id={} name={} status={} current_task={}'.format(
            f,
            d.get('session_id', '?'),
            d.get('name', '?'),
            d.get('status', '?'),
            d.get('current_task', '?'),
        ))
    except Exception as e:
        print('{}: malformed -- {}'.format(f, e))
" "$SESSIONS_DIR"
