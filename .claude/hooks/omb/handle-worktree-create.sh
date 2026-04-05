#!/usr/bin/env bash
# Forward WorktreeCreate event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "WorktreeCreate" "worktree-create" 10
