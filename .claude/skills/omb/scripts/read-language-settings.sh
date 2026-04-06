#!/usr/bin/env bash
# Reads OMB_LANGUAGE and OMB_DOC_LANGUAGE from .claude/settings.json.
# Usage: bash read-language-settings.sh [settings-file]
# Output: KEY=VALUE lines (OMB_LANGUAGE=<value> and OMB_DOC_LANGUAGE=<value>)
# Exit: 0 always (best-effort reader, not a validator)
# OMB-PLAN-000082
set -euo pipefail

SETTINGS_FILE="${1:-.claude/settings.json}"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "OMB_LANGUAGE=en"
  echo "OMB_DOC_LANGUAGE=en"
  exit 0
fi

python3 -c "
import sys, json
with open('$SETTINGS_FILE', 'r') as f:
    d = json.load(f)
e = d.get('env', {})
print('OMB_LANGUAGE=' + e.get('OMB_LANGUAGE', 'en'))
print('OMB_DOC_LANGUAGE=' + e.get('OMB_DOC_LANGUAGE', 'en'))
" 2>/dev/null || {
  echo "OMB_LANGUAGE=en"
  echo "OMB_DOC_LANGUAGE=en"
}

exit 0
