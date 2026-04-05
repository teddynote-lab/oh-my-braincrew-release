#!/usr/bin/env bash
# Forward SubagentStart event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "SubagentStart" "subagent-start" 10
