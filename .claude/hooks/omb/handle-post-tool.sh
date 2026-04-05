#!/usr/bin/env bash
# Forward PostToolUse event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PostToolUse" "post-tool-use" 10
