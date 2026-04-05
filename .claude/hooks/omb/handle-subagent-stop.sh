#!/usr/bin/env bash
# Forward SubagentStop event to omb Python module (with infinite loop guard)
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch_stop "SubagentStop" "subagent-stop" 10
