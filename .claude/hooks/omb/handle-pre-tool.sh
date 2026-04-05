#!/usr/bin/env bash
# Forward PreToolUse event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PreToolUse" "pre-tool-use" 10
