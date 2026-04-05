#!/usr/bin/env bash
# Worktree-safe PLAN tracking code shim.
# Usage: bash next-plan-code.sh
# Output: BCRW-PLAN-000001 (to stdout)
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: bash next-plan-code.sh" >&2
  exit 2
fi

if command -v omb >/dev/null 2>&1; then
  exec omb tracking next PLAN
fi

if [[ -x "${HOME}/go/bin/omb" ]]; then
  exec "${HOME}/go/bin/omb" tracking next PLAN
fi

echo "ERROR: omb binary not found in PATH or \$HOME/go/bin" >&2
exit 1
