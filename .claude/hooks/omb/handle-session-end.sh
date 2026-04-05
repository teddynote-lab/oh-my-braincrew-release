#!/usr/bin/env bash
# Forward SessionEnd event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "SessionEnd" "session-end" 10
