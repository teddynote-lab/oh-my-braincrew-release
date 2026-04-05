#!/usr/bin/env bash
# Forward TaskCreated event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "TaskCreated" "task-created" 10
