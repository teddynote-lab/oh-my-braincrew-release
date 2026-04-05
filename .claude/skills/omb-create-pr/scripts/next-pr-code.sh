#!/usr/bin/env bash
# Worktree-safe PR tracking code shim.
# Usage: bash next-pr-code.sh
# Output: BCRW-PR-000001 (to stdout)
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: bash next-pr-code.sh" >&2
  exit 2
fi

if command -v omb >/dev/null 2>&1; then
  exec omb tracking next PR
fi

if [[ -x "${HOME}/go/bin/omb" ]]; then
  exec "${HOME}/go/bin/omb" tracking next PR
fi

echo "ERROR: omb binary not found in PATH or \$HOME/go/bin" >&2
exit 1
