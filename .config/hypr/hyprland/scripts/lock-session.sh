#!/usr/bin/env bash
# lock-session.sh — Astral-Vagabond session lock
#
# Quickshell holds ext-session-lock-v1 and draws the PAM UI.
# hyprlock is only used when no astral-vagabond instance is running.
# Do not start hyprlock "just in case": two lock clients cannot share
# the protocol, and a slow isLocked poll was making Super+L open hyprlock
# while the shell was alive.

set -u

QS="${QS_BIN:-/usr/bin/qs}"
QS_CONFIG="${QS_LOCK_CONFIG:-astral-vagabond}"
HYPRLOCK="${HYPRLOCK_BIN:-/usr/bin/hyprlock}"

if pidof -q hyprlock 2>/dev/null; then
    exit 0
fi

if command -v "$QS" >/dev/null 2>&1 || [[ -x "$QS" ]]; then
    if "$QS" -c "$QS_CONFIG" list >/dev/null 2>&1; then
        exec "$QS" -c "$QS_CONFIG" ipc call lock lock
    fi
fi

if [[ -x "$HYPRLOCK" ]]; then
    exec "$HYPRLOCK" "$@"
fi

echo "lock-session: astral-vagabond is not running and $HYPRLOCK is missing" >&2
exit 1
