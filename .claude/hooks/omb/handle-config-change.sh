#!/usr/bin/env bash
# Forward ConfigChange event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "ConfigChange" "config-change" 10
