#!/usr/bin/env bash
# Forward FileChanged event to omb Python module
source "$(dirname "$0")/_omb-hook-lib.sh"
omb_hook_dispatch "FileChanged" "file-changed" 10
