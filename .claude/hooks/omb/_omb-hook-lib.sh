#!/usr/bin/env bash
# Shared hook runtime library for oh-my-braincrew
# Source this file from individual hook scripts to get robust stdin reading,
# JSON validation, timeout handling, plugin root resolution, and Python forwarding.
#
# Usage in hook scripts:
#   #!/usr/bin/env bash
#   source "$(dirname "$0")/_omb-hook-lib.sh"
#   omb_hook_dispatch "EventName" "subcmd-name"
#
# For Stop/SubagentStop (infinite loop guard):
#   omb_hook_dispatch_stop "Stop" "stop"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Isolate stdout from shell profile noise.
# Saves original stdout to fd 3; suppresses all other stdout so stray profile
# echo statements (e.g. from ~/.zshrc) cannot contaminate our JSON response.
_omb_init_stdout() {
    exec 3>&1
    exec 1>/dev/null
}

# Restore fd 3 on exit — prevents fd leak if script is interrupted.
_omb_cleanup() {
    exec 3>&- 2>/dev/null || true
}
trap _omb_cleanup EXIT

# Portable timeout wrapper — works on Linux (coreutils timeout),
# macOS with Homebrew (gtimeout), and falls back to plain cat.
_omb_timeout_cat() {
    local secs="$1"
    if command -v timeout &>/dev/null; then
        timeout "$secs" cat <&0
    elif command -v gtimeout &>/dev/null; then
        gtimeout "$secs" cat <&0
    else
        # No timeout available — cat returns when pipe closes (normal behavior).
        cat <&0
    fi
}

# Read stdin with timeout guard to prevent indefinite blocking.
# Sets STDIN_DATA on success; returns 1 on failure.
_omb_read_stdin() {
    local timeout_secs="${1:-10}"
    local event_name="${2:-unknown}"

    STDIN_DATA="$(_omb_timeout_cat "$timeout_secs")" || {
        echo "[omb-hook] ERROR: stdin read timed out or failed for $event_name" >&2
        return 1
    }

    # Validate non-empty stdin — Claude Code always sends a JSON payload.
    if [ -z "$STDIN_DATA" ]; then
        echo "[omb-hook] WARNING: empty stdin for $event_name" >&2
        return 1
    fi

    # Lightweight JSON validation — check that payload starts with '{'.
    # Catches shell profile noise that prepends text before JSON.
    local trimmed
    trimmed="${STDIN_DATA#"${STDIN_DATA%%[![:space:]]*}"}"
    if [ "${trimmed:0:1}" != "{" ]; then
        echo "[omb-hook] ERROR: stdin for $event_name is not valid JSON (starts with: ${trimmed:0:20})" >&2
        return 1
    fi

    export STDIN_DATA
}

# Resolve plugin root: prefer CLAUDE_PLUGIN_ROOT, fall back to CLAUDE_PROJECT_DIR.
_omb_resolve_root() {
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-}}"
    if [ -z "$PLUGIN_ROOT" ]; then
        echo "[omb-hook] WARNING: neither CLAUDE_PLUGIN_ROOT nor CLAUDE_PROJECT_DIR set" >&2
        return 1
    fi
    export PLUGIN_ROOT
}

# BCRW-PLAN-000087: Detect omb CLI or uv in PATH for hook dispatch.
_omb_check_runtime() {
    # Try omb CLI first (pip/pipx installed)
    if command -v omb &>/dev/null; then
        OMB_RUNTIME="omb"
        return 0
    fi
    # Fallback: uv run with plugin project
    if command -v uv &>/dev/null; then
        OMB_RUNTIME="uv"
        return 0
    fi
    echo "[omb-hook] WARNING: neither omb nor uv found in PATH — hooks disabled" >&2
    return 1
}

# Forward stdin data to the Python hook handler via detected runtime.
_omb_forward() {
    local subcmd="$1"
    if [[ "$OMB_RUNTIME" == "omb" ]]; then
        printf '%s' "$STDIN_DATA" | omb hook "$subcmd" >&3
    else
        printf '%s' "$STDIN_DATA" | uv run --project "$PLUGIN_ROOT" python -m omb hook "$subcmd" >&3
    fi
    return $?
}

# Check if a JSON boolean field is true using lightweight string matching.
# Handles both camelCase (wire format) and snake_case (normalized) field names.
# Usage: _omb_json_bool_true "$STDIN_DATA" "stopHookActive" "stop_hook_active"
_omb_json_bool_true() {
    local json="$1"
    shift
    for field_name in "$@"; do
        if printf '%s' "$json" | grep -qE "\"${field_name}\"[[:space:]]*:[[:space:]]*true"; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Public dispatch functions
# ---------------------------------------------------------------------------

# Standard hook dispatch: read stdin → resolve deps → forward to Python.
# All failures are non-blocking (exit 0) to avoid breaking Claude Code lifecycle.
#
# Args:
#   $1 - event name (e.g. "SessionStart") for logging
#   $2 - CLI subcommand name (e.g. "session-start") for `omb hook <subcmd>`
#   $3 - stdin read timeout in seconds (default: 10)
omb_hook_dispatch() {
    local event_name="$1"
    local subcmd="$2"
    local timeout="${3:-10}"

    _omb_init_stdout
    _omb_read_stdin "$timeout" "$event_name" || exit 0
    _omb_resolve_root || exit 0
    _omb_check_runtime || exit 0
    _omb_forward "$subcmd"
    exit $?
}

# Stop-aware hook dispatch with infinite loop prevention.
# Checks stop_hook_active / stopHookActive before forwarding.
# Use for Stop and SubagentStop events.
#
# Args: same as omb_hook_dispatch
omb_hook_dispatch_stop() {
    local event_name="$1"
    local subcmd="$2"
    local timeout="${3:-10}"

    _omb_init_stdout
    _omb_read_stdin "$timeout" "$event_name" || exit 0
    # stop_hook_active guard moved to Python handler — shell always forwards
    # so fallback skill output can be parsed on the second Stop event.
    _omb_resolve_root || exit 0
    _omb_check_runtime || exit 0
    _omb_forward "$subcmd"
    exit $?
}
