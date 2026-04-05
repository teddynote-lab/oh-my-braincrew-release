#!/usr/bin/env bash
# Forward PreCompact event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PreCompact" "pre-compact" 10
