#!/usr/bin/env bash
# Setup a git worktree for isolated pipeline execution.
# Usage: setup-worktree.sh <session_id> [project_root]
# Output: WORKTREE_PATH=<path> on stdout
# Exit: 0 on success, 1 on failure
# OMB-PLAN-000077
set -euo pipefail

SESSION_ID="${1:?Usage: setup-worktree.sh <session_id> [project_root]}"
PROJECT_ROOT="${2:-$(git rev-parse --show-toplevel)}"

WORKTREE_PATH="${PROJECT_ROOT}/worktrees/${SESSION_ID}"

# Step 1: Create worktree branch (idempotent)
if [ -d "${WORKTREE_PATH}" ]; then
  echo "[setup-worktree] worktree already exists: ${WORKTREE_PATH}" >&2
  echo "WORKTREE_PATH=${WORKTREE_PATH}"
  exit 0
fi

git worktree add -b "worktree/${SESSION_ID}" "${WORKTREE_PATH}" 2>&1

# Step 2: Ensure .omb/sessions/ exists in worktree and copy session file
mkdir -p "${WORKTREE_PATH}/.omb/sessions"
cp "${PROJECT_ROOT}/.omb/sessions/${SESSION_ID}.json" "${WORKTREE_PATH}/.omb/sessions/"

# Step 3: Update worktree_path in session JSON via CLI
omb session set "${SESSION_ID}" --field worktree_path --value "${WORKTREE_PATH}"

# Step 4: Output for caller
echo "WORKTREE_PATH=${WORKTREE_PATH}"
