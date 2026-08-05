#!/usr/bin/env bash
# slayer-mode.sh — one-shot "Fortress of Doom" desktop mode
# Composes waybar-toggle, notifications-toggle, idle-toggle, and optional HyDE gamemode.
#
# Usage:
#   ./slayer-mode.sh              # enter slayer mode
#   ./slayer-mode.sh --off        # exit slayer mode
#   ./slayer-mode.sh --toggle
#   ./slayer-mode.sh --status
#   ./slayer-mode.sh --enter --no-game --keep-idle

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/doomslayer"
STATE_FILE="$STATE_DIR/slayer-mode.json"
WAYBAR_TOGGLE="$SCRIPT_DIR/waybar-toggle.sh"
NOTIF_TOGGLE="$SCRIPT_DIR/notifications-toggle.sh"
IDLE_TOGGLE="$SCRIPT_DIR/idle-toggle.sh"

ACTION="enter"
USE_GAME=true
KILL_IDLE=true
KILL_WAYBAR=true
KILL_NOTIF=true

usage() {
    cat <<EOF
Usage: $0 [--enter|--off|--toggle|--status] [options]

Slayer Mode: a clean, distraction-free Hyprland session for gaming / focus /
doomshell-only setups.

  (default) / --enter   Enable slayer mode
  --off / --exit        Restore previous desktop state
  --toggle              Flip state
  --status              Show whether slayer mode is active

Options (for --enter only):
  --no-game             Skip HyDE gamemode (animations/blur workflow)
  --keep-idle           Leave hypridle running
  --keep-waybar         Leave waybar running
  --keep-notif          Leave notifications running

Components:
  • waybar-toggle.sh
  • notifications-toggle.sh
  • idle-toggle.sh
  • hyde-shell gamemode  (optional)
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --enter|--on)   ACTION="enter" ;;
        --off|--exit)   ACTION="exit"  ;;
        --toggle|-t)    ACTION="toggle" ;;
        --status|-s)    ACTION="status" ;;
        --no-game)      USE_GAME=false ;;
        --keep-idle)    KILL_IDLE=false ;;
        --keep-waybar)  KILL_WAYBAR=false ;;
        --keep-notif)   KILL_NOTIF=false ;;
        -h|--help)      usage ;;
        *)
            echo "error: unknown option '$1' (try --help)" >&2
            exit 1
            ;;
    esac
    shift
done

for req in "$WAYBAR_TOGGLE" "$NOTIF_TOGGLE" "$IDLE_TOGGLE"; do
    if [[ ! -x "$req" ]]; then
        echo "error: missing sibling utility: $req" >&2
        exit 1
    fi
done

is_active() {
    [[ -f "$STATE_FILE" ]]
}

notify() {
    local title="$1" body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        # Prefer real dunst path in case stubs are installed mid-flight
        notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

gamemode_is_on() {
    [[ -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyde/gamemode.lck" ]]
}

gamemode_on() {
    if command -v hyde-shell >/dev/null 2>&1; then
        if ! gamemode_is_on; then
            hyde-shell gamemode >/dev/null 2>&1 || true
        fi
    elif [[ -x "${HOME}/.local/lib/hyde/gamemode.sh" ]]; then
        if ! gamemode_is_on; then
            bash "${HOME}/.local/lib/hyde/gamemode.sh" >/dev/null 2>&1 || true
        fi
    fi
}

gamemode_off() {
    if gamemode_is_on; then
        if command -v hyde-shell >/dev/null 2>&1; then
            hyde-shell gamemode >/dev/null 2>&1 || true
        elif [[ -x "${HOME}/.local/lib/hyde/gamemode.sh" ]]; then
            bash "${HOME}/.local/lib/hyde/gamemode.sh" >/dev/null 2>&1 || true
        fi
    fi
}

snapshot_and_enter() {
    mkdir -p "$STATE_DIR"

    local waybar_was_disabled=false
    local notif_was_disabled=false
    local idle_was_disabled=false
    local game_was_on=false

    [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.disabled" ]] && waybar_was_disabled=true
    [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dunst/.disabled" ]] && notif_was_disabled=true
    [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/hypridle/.disabled" ]] && idle_was_disabled=true
    gamemode_is_on && game_was_on=true

    cat > "$STATE_FILE" <<EOF
{
  "active": true,
  "entered_at": "$(date -Iseconds)",
  "prior": {
    "waybar_disabled": $waybar_was_disabled,
    "notif_disabled": $notif_was_disabled,
    "idle_disabled": $idle_was_disabled,
    "gamemode_on": $game_was_on
  },
  "options": {
    "kill_waybar": $KILL_WAYBAR,
    "kill_notif": $KILL_NOTIF,
    "kill_idle": $KILL_IDLE,
    "use_game": $USE_GAME
  }
}
EOF

    # Apply components (notify last so a final alert can still fire if notif stays)
    if $KILL_WAYBAR && ! $waybar_was_disabled; then
        "$WAYBAR_TOGGLE" --disable
    fi
    if $KILL_IDLE && ! $idle_was_disabled; then
        "$IDLE_TOGGLE" --disable
    fi
    if $USE_GAME && ! $game_was_on; then
        gamemode_on
    fi
    if $KILL_NOTIF && ! $notif_was_disabled; then
        # Last notify before we kill the daemon
        notify "Slayer Mode" "RIP AND TEAR — clean desktop engaged"
        sleep 0.15
        "$NOTIF_TOGGLE" --disable
    else
        notify "Slayer Mode" "RIP AND TEAR — clean desktop engaged"
    fi

    echo "Slayer Mode: ON"
    echo "  waybar:        $($KILL_WAYBAR && echo off || echo kept)"
    echo "  notifications: $($KILL_NOTIF && echo off || echo kept)"
    echo "  hypridle:      $($KILL_IDLE && echo off || echo kept)"
    echo "  gamemode:      $($USE_GAME && echo on || echo skipped)"
    echo "  state: $STATE_FILE"
}

restore_and_exit() {
    if ! is_active; then
        echo "Slayer Mode is already off."
        return 0
    fi

    local waybar_was_disabled notif_was_disabled idle_was_disabled game_was_on
    local kill_waybar kill_notif kill_idle use_game

    # Parse with python for reliability (json may be multi-line)
    eval "$(python3 - "$STATE_FILE" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
p = data.get("prior", {})
o = data.get("options", {})
def b(v, default=False):
    return "true" if v else "false"
print(f"waybar_was_disabled={b(p.get('waybar_disabled', False))}")
print(f"notif_was_disabled={b(p.get('notif_disabled', False))}")
print(f"idle_was_disabled={b(p.get('idle_disabled', False))}")
print(f"game_was_on={b(p.get('gamemode_on', False))}")
print(f"kill_waybar={b(o.get('kill_waybar', True))}")
print(f"kill_notif={b(o.get('kill_notif', True))}")
print(f"kill_idle={b(o.get('kill_idle', True))}")
print(f"use_game={b(o.get('use_game', True))}")
PY
)"

    # Restore only what we changed
    if $kill_notif && ! $notif_was_disabled; then
        "$NOTIF_TOGGLE" --enable
    fi
    if $kill_waybar && ! $waybar_was_disabled; then
        "$WAYBAR_TOGGLE" --enable
    fi
    if $kill_idle && ! $idle_was_disabled; then
        "$IDLE_TOGGLE" --enable
    fi
    if $use_game && ! $game_was_on; then
        gamemode_off
    fi

    rm -f "$STATE_FILE"
    echo "Slayer Mode: OFF — desktop restored."
    notify "Slayer Mode off" "Desktop components restored"
}

status() {
    if is_active; then
        echo "slayer-mode: ACTIVE"
        if command -v python3 >/dev/null 2>&1; then
            python3 - "$STATE_FILE" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
print(f"  entered: {d.get('entered_at', '?')}")
o = d.get("options", {})
print(f"  waybar:        {'off' if o.get('kill_waybar', True) else 'kept'}")
print(f"  notifications: {'off' if o.get('kill_notif', True) else 'kept'}")
print(f"  hypridle:      {'off' if o.get('kill_idle', True) else 'kept'}")
print(f"  gamemode:      {'on' if o.get('use_game', True) else 'skipped'}")
PY
        fi
        echo "  state: $STATE_FILE"
    else
        echo "slayer-mode: INACTIVE"
    fi
    # Live component snapshot
    echo "--- live ---"
    "$WAYBAR_TOGGLE" --status | head -1
    "$NOTIF_TOGGLE" --status | head -1
    "$IDLE_TOGGLE" --status | head -1
    if gamemode_is_on; then
        echo "gamemode: ON"
    else
        echo "gamemode: OFF"
    fi
}

case "$ACTION" in
    status) status ;;
    enter)
        if is_active; then
            echo "Slayer Mode is already active (state: $STATE_FILE)."
            echo "Use --off first, or --toggle."
            exit 0
        fi
        snapshot_and_enter
        ;;
    exit)
        restore_and_exit
        ;;
    toggle)
        if is_active; then
            restore_and_exit
        else
            snapshot_and_enter
        fi
        ;;
esac
