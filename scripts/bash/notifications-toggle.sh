#!/usr/bin/env bash
# notifications-toggle.sh — disable notification daemons globally (HyDE-aware)
# Usage:
#   ./notifications-toggle.sh            # disable
#   ./notifications-toggle.sh --enable   # re-enable
#   ./notifications-toggle.sh --status   # show current state
#   ./notifications-toggle.sh --toggle   # flip state
#   ./notifications-toggle.sh --dnd      # pause notifications without killing daemon
#   ./notifications-toggle.sh --dnd-off  # unpause (DND off)

set -euo pipefail

ACTION="disable"
case "${1:-}" in
    --enable|-e)   ACTION="enable"  ;;
    --disable|-d)  ACTION="disable" ;;
    --toggle|-t)   ACTION="toggle"  ;;
    --status|-s)   ACTION="status"  ;;
    --dnd)         ACTION="dnd"     ;;
    --dnd-off)     ACTION="dnd_off" ;;
    -h|--help)
        cat <<EOF
Usage: $0 [--disable|--enable|--toggle|--status|--dnd|--dnd-off]

Disable or re-enable desktop notifications system-wide for the current user.

  (default) / --disable   Stop dunst/swaync/mako and block future launches
  --enable                Remove the block and start notifications again
  --toggle                Flip between disabled and enabled
  --status                Print whether notifications are currently disabled
  --dnd                   Soft mute: pause dunst (keeps daemon, history intact)
  --dnd-off               Unpause dunst

How it works (full disable):
  • Flag:  ~/.config/dunst/.disabled
  • Stub:  ~/.local/bin/dunst  (shadows /usr/bin/dunst via PATH)
  • Stops HyDE unit hyde-*-notifications.service and daemon processes
EOF
        exit 0
        ;;
    "")
        ACTION="disable"
        ;;
    *)
        echo "error: unknown option '$1' (try --help)" >&2
        exit 1
        ;;
esac

HOME="${HOME:-$(eval echo ~"$USER")}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
FLAG_FILE="$CONFIG_DIR/dunst/.disabled"
STUB_DUNST="$LOCAL_BIN/dunst"
STUB_SWAYNC="$LOCAL_BIN/swaync"
REAL_DUNST="/usr/bin/dunst"
REAL_SWAYNC="/usr/bin/swaync"
ENV_D="$CONFIG_DIR/environment.d/notifications-toggle.conf"

is_disabled() {
    [[ -f "$FLAG_FILE" ]]
}

notify() {
    local title="$1" body="$2"
    # Only try to notify when the daemon should actually be alive
    if ! is_disabled && command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

stop_notifications() {
    local unit
    while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        systemctl --user stop "$unit" 2>/dev/null || true
        systemctl --user reset-failed "$unit" 2>/dev/null || true
    done < <(systemctl --user list-units --type=service --all --no-legend 'hyde-*-notifications.service' 2>/dev/null | awk '{print $1}')

    systemctl --user stop "hyde-${XDG_SESSION_DESKTOP:-Hyprland}-notifications.service" 2>/dev/null || true
    systemctl --user stop dunst.service swaync.service 2>/dev/null || true

    pkill -u "$USER" -x dunst 2>/dev/null || true
    pkill -u "$USER" -x swaync 2>/dev/null || true
    pkill -u "$USER" -x mako 2>/dev/null || true
    pkill -u "$USER" -f '[/]usr/bin/dunst' 2>/dev/null || true
    pkill -u "$USER" -f '[/]usr/bin/swaync' 2>/dev/null || true
}

install_stub() {
    mkdir -p "$LOCAL_BIN" "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"

    cat > "$STUB_DUNST" <<'EOF'
#!/usr/bin/env bash
# dunst stub — installed by notifications-toggle.sh
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dunst/.disabled" ]]; then
    exit 0
fi
exec /usr/bin/dunst "$@"
EOF
    chmod +x "$STUB_DUNST"

    if [[ -x "$REAL_SWAYNC" ]]; then
        cat > "$STUB_SWAYNC" <<'EOF'
#!/usr/bin/env bash
# swaync stub — installed by notifications-toggle.sh
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dunst/.disabled" ]]; then
    exit 0
fi
exec /usr/bin/swaync "$@"
EOF
        chmod +x "$STUB_SWAYNC"
    fi
}

remove_stub() {
    rm -f "$FLAG_FILE" "$STUB_DUNST" "$STUB_SWAYNC"
}

install_env() {
    mkdir -p "$(dirname "$ENV_D")"
    echo "DISABLE_NOTIFICATIONS=1" > "$ENV_D"
}

remove_env() {
    rm -f "$ENV_D"
}

start_notifications() {
    # Prefer HyDE's session launcher pattern
    if [[ -x "$REAL_DUNST" ]]; then
        local unit="hyde-${XDG_SESSION_DESKTOP:-Hyprland}-notifications.service"
        systemctl --user stop "$unit" 2>/dev/null || true
        systemd-run --user \
            --unit="$unit" \
            --slice=app-graphical.slice \
            --property=Type=exec \
            --property=ExitType=cgroup \
            --property=After=graphical-session.target \
            --property=PartOf=graphical-session.target \
            --quiet \
            -- "$REAL_DUNST" 2>/dev/null || "$REAL_DUNST" &
        disown 2>/dev/null || true
    elif [[ -x "$REAL_SWAYNC" ]]; then
        "$REAL_SWAYNC" &
        disown 2>/dev/null || true
    else
        echo "warning: no notification daemon found (dunst/swaync)" >&2
        return 1
    fi
}

status() {
    if is_disabled; then
        echo "notifications: DISABLED"
        echo "  Flag: $FLAG_FILE"
        [[ -x "$STUB_DUNST" ]] && echo "  Stub: $STUB_DUNST"
        [[ -f "$ENV_D" ]] && echo "  Env:  $ENV_D"
        if pgrep -u "$USER" -x dunst >/dev/null 2>&1 || pgrep -u "$USER" -x swaync >/dev/null 2>&1; then
            echo "  Note: a notification process is still running (re-run --disable)"
        else
            echo "  Process: not running"
        fi
    else
        echo "notifications: ENABLED"
        if pgrep -u "$USER" -x dunst >/dev/null 2>&1; then
            echo "  Process: dunst (pid $(pgrep -u "$USER" -x dunst | tr '\n' ' '))"
            if command -v dunstctl >/dev/null 2>&1; then
                local paused
                paused="$(dunstctl is-paused 2>/dev/null || echo unknown)"
                echo "  DND/paused: $paused"
            fi
        elif pgrep -u "$USER" -x swaync >/dev/null 2>&1; then
            echo "  Process: swaync (pid $(pgrep -u "$USER" -x swaync | tr '\n' ' '))"
        else
            echo "  Process: not running"
        fi
    fi
}

disable() {
    install_stub
    install_env
    stop_notifications
    sleep 0.3
    stop_notifications

    echo "notifications disabled."
    echo "  Flag:  $FLAG_FILE"
    echo "  Stub:  $STUB_DUNST  (shadows /usr/bin/dunst via ~/.local/bin)"
    echo "  Env:   $ENV_D"
    echo "Survives theme reloads and new logins until you re-enable."
}

enable() {
    remove_stub
    remove_env
    start_notifications
    sleep 0.2
    echo "notifications re-enabled."
    if pgrep -u "$USER" -x dunst >/dev/null 2>&1 || pgrep -u "$USER" -x swaync >/dev/null 2>&1; then
        echo "  Process started."
        notify "Notifications enabled" "Desktop alerts are back"
    else
        echo "  Launch requested; if silent, run: /usr/bin/dunst &"
    fi
}

dnd_on() {
    if is_disabled; then
        echo "notifications are fully disabled; use --enable first" >&2
        exit 1
    fi
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused true
        echo "DND on (dunst paused)."
        # Can't notify while paused — intentional
    elif command -v swaync-client >/dev/null 2>&1; then
        swaync-client --dnd-on
        echo "DND on (swaync)."
    else
        echo "error: no dunstctl/swaync-client available for soft mute" >&2
        exit 1
    fi
}

dnd_off() {
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused false
        echo "DND off (dunst unpaused)."
        notify "DND off" "Notifications will show again"
    elif command -v swaync-client >/dev/null 2>&1; then
        swaync-client --dnd-off
        echo "DND off (swaync)."
    else
        echo "error: no dunstctl/swaync-client available" >&2
        exit 1
    fi
}

case "$ACTION" in
    status)  status ;;
    toggle)
        if is_disabled; then enable; else disable; fi
        ;;
    enable)  enable ;;
    disable) disable ;;
    dnd)     dnd_on ;;
    dnd_off) dnd_off ;;
esac
