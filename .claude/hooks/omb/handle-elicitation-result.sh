#!/usr/bin/env bash
# Forward ElicitationResult event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "ElicitationResult" "elicitation-result" 10
