#!/usr/bin/env bash
# Forward InstructionsLoaded event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "InstructionsLoaded" "instructions-loaded" 10
