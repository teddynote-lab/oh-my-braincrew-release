#!/usr/bin/env bash
# Forward Elicitation event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "Elicitation" "elicitation" 10
