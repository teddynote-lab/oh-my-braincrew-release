#!/usr/bin/env bash
# Forward Setup event to omb Python module (deprecated — not in official docs)
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "Setup" "setup" 10
