#!/usr/bin/env bash
# Remove sensitive env keys from .claude/settings.json before release packaging.
# Usage: sanitize-settings.sh <repo_dir>
# Output: Reports removed keys to stderr for audit trail; exits 0 if clean or skipped
# Exit: 0 on success or skip, 1 on failure
# OMB-PLAN-000082
set -euo pipefail

REPO_DIR="${1:?Usage: sanitize-settings.sh <repo_dir>}"
SETTINGS_FILE="${REPO_DIR}/.claude/settings.json"

if [ ! -f "${SETTINGS_FILE}" ]; then
  echo "[sanitize-settings] settings.json not found at ${SETTINGS_FILE} — skipping" >&2
  exit 0
fi

python3 << PYEOF
import json, pathlib, sys

settings_path = pathlib.Path("${SETTINGS_FILE}")
data = json.loads(settings_path.read_text())

removed_keys = []
if "env" in data:
    sensitive_patterns = ("KEY", "TOKEN", "SECRET", "PASSWORD")
    for k in list(data["env"]):
        if any(s in k for s in sensitive_patterns):
            del data["env"][k]
            removed_keys.append(k)

settings_path.write_text(json.dumps(data, indent=2) + "\n")

if removed_keys:
    for k in removed_keys:
        print(f"[sanitize-settings] removed sensitive key: {k}", file=sys.stderr)
    print(f"[sanitize-settings] removed {len(removed_keys)} sensitive env key(s)", file=sys.stderr)
else:
    print("[sanitize-settings] no sensitive keys found — settings unchanged", file=sys.stderr)
PYEOF
