#!/usr/bin/env bash
# Forward Stop event to omb Python module (with infinite loop guard)
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch_stop "Stop" "stop" 10
