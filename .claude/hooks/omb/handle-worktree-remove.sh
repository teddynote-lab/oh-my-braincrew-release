#!/usr/bin/env bash
# Forward WorktreeRemove event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "WorktreeRemove" "worktree-remove" 10
