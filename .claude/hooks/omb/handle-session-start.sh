#!/usr/bin/env bash
# Forward SessionStart event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "SessionStart" "session-start" 10
