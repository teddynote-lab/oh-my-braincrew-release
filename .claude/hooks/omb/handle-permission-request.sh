#!/usr/bin/env bash
# Forward PermissionRequest event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PermissionRequest" "permission-request" 10
