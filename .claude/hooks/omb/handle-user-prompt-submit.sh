#!/usr/bin/env bash
# Forward UserPromptSubmit event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "UserPromptSubmit" "user-prompt-submit" 10
