#!/usr/bin/env bash
# Forward TaskCompleted event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "TaskCompleted" "task-completed" 10
