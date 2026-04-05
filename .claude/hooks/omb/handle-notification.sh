#!/usr/bin/env bash
# Forward Notification event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "Notification" "notification" 10
