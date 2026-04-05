#!/usr/bin/env bash
# Forward PostCompact event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PostCompact" "post-compact" 10
