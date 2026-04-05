#!/usr/bin/env bash
# Forward CwdChanged event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "CwdChanged" "cwd-changed" 10
