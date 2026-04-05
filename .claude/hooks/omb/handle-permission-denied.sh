#!/usr/bin/env bash
# Forward PermissionDenied event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "PermissionDenied" "permission-denied" 10
