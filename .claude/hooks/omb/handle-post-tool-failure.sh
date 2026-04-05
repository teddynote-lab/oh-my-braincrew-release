#!/usr/bin/env bash
# Forward PostToolUseFailure event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PostToolUseFailure" "post-tool-failure" 10
