#!/usr/bin/env bash
# Forward TeammateIdle event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "TeammateIdle" "teammate-idle" 10
