#!/usr/bin/env bash
# waybar-toggle.sh — disable waybar globally (HyDE-aware)
# Usage:
#   ./waybar-toggle.sh            # disable
#   ./waybar-toggle.sh --enable   # re-enable
#   ./waybar-toggle.sh --status   # show current state
#   ./waybar-toggle.sh --toggle   # flip state

set -euo pipefail

ACTION="disable"
case "${1:-}" in
    --enable|-e)  ACTION="enable"  ;;
    --disable|-d) ACTION="disable" ;;
    --toggle|-t)  ACTION="toggle"  ;;
    --status|-s)  ACTION="status"  ;;
    -h|--help)
        cat <<EOF
Usage: $0 [--disable|--enable|--toggle|--status]

Disable or re-enable waybar system-wide for the current user.

  (default) / --disable   Stop waybar and block future launches
  --enable                Remove the block and start waybar again
  --toggle                Flip between disabled and enabled
  --status                Print whether waybar is currently disabled

How it works:
  • Flag:  ~/.config/waybar/.disabled
  • Stub:  ~/.local/bin/waybar  (shadows /usr/bin/waybar via PATH)
  • Stops HyDE bar units (hyde-*-bar.service) and any waybar processes
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
FLAG_FILE="$CONFIG_DIR/waybar/.disabled"
STUB="$LOCAL_BIN/waybar"
REAL_WAYBAR="/usr/bin/waybar"
ENV_D="$CONFIG_DIR/environment.d/waybar-toggle.conf"

is_disabled() {
    [[ -f "$FLAG_FILE" ]]
}

notify() {
    local title="$1" body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

# Stop every HyDE transient bar unit and any leftover waybar process.
stop_waybar() {
    local unit
    # hyde-Hyprland-bar.service and any similar desktop variants
    while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        systemctl --user stop "$unit" 2>/dev/null || true
        systemctl --user reset-failed "$unit" 2>/dev/null || true
    done < <(systemctl --user list-units --type=service --all --no-legend 'hyde-*-bar.service' 2>/dev/null | awk '{print $1}')

    # Also try the common fixed name if list-units missed it
    systemctl --user stop "hyde-${XDG_SESSION_DESKTOP:-Hyprland}-bar.service" 2>/dev/null || true

    # Official waybar user unit (usually disabled, but harmless)
    systemctl --user stop waybar.service 2>/dev/null || true

    # HyDE helper, if available
    if command -v hyde-shell >/dev/null 2>&1; then
        hyde-shell waybar --kill >/dev/null 2>&1 || true
    elif [[ -x "${HOME}/.local/lib/hyde/waybar.py" ]]; then
        python3 "${HOME}/.local/lib/hyde/waybar.py" --kill >/dev/null 2>&1 || true
    fi

    # Final sweep for any PATH-spawned or orphaned instances
    pkill -u "$USER" -x waybar 2>/dev/null || true
    pkill -u "$USER" -f '[/]usr/bin/waybar' 2>/dev/null || true
}

install_stub() {
    mkdir -p "$LOCAL_BIN" "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"

    cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
# waybar stub — installed by waybar-toggle.sh
# When ~/.config/waybar/.disabled exists, refuse to start.
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.disabled" ]]; then
    exit 0
fi
exec /usr/bin/waybar "$@"
EOF
    chmod +x "$STUB"
}

remove_stub() {
    rm -f "$FLAG_FILE" "$STUB"
}

install_env() {
    mkdir -p "$(dirname "$ENV_D")"
    echo "DISABLE_WAYBAR=1" > "$ENV_D"
}

remove_env() {
    rm -f "$ENV_D"
}

start_waybar() {
    if [[ ! -x "$REAL_WAYBAR" ]]; then
        echo "warning: $REAL_WAYBAR not found; cannot start waybar" >&2
        return 1
    fi

    # Prefer HyDE's launcher so config/style update + unit wiring stay consistent
    if command -v hyde-shell >/dev/null 2>&1; then
        hyde-shell waybar >/dev/null 2>&1 || true
    elif [[ -x "${HOME}/.local/lib/hyde/waybar.py" ]]; then
        python3 "${HOME}/.local/lib/hyde/waybar.py" >/dev/null 2>&1 || true
    else
        # Fallback: transient user unit matching HyDE's pattern
        local unit="hyde-${XDG_SESSION_DESKTOP:-Hyprland}-bar.service"
        systemctl --user stop "$unit" 2>/dev/null || true
        systemd-run --user \
            --unit="$unit" \
            --slice=app-graphical.slice \
            --property=Type=exec \
            --property=ExitType=cgroup \
            --property=After=graphical-session.target \
            --property=PartOf=graphical-session.target \
            --quiet \
            -- "$REAL_WAYBAR" 2>/dev/null || "$REAL_WAYBAR" &
        disown 2>/dev/null || true
    fi
}

status() {
    if is_disabled; then
        echo "waybar: DISABLED"
        echo "  Flag: $FLAG_FILE"
        [[ -x "$STUB" ]] && echo "  Stub: $STUB"
        [[ -f "$ENV_D" ]] && echo "  Env:  $ENV_D"
        if pgrep -u "$USER" -x waybar >/dev/null 2>&1; then
            echo "  Note: a waybar process is still running (re-run --disable to stop it)"
        else
            echo "  Process: not running"
        fi
    else
        echo "waybar: ENABLED"
        if pgrep -u "$USER" -x waybar >/dev/null 2>&1; then
            echo "  Process: running (pid $(pgrep -u "$USER" -x waybar | tr '\n' ' '))"
        else
            echo "  Process: not running"
        fi
    fi
}

disable() {
    install_stub
    install_env
    stop_waybar
    # Brief re-check: HyDE watchers sometimes respawn once
    sleep 0.3
    stop_waybar

    echo "waybar disabled."
    echo "  Flag:  $FLAG_FILE"
    echo "  Stub:  $STUB  (shadows /usr/bin/waybar via ~/.local/bin)"
    echo "  Env:   $ENV_D"
    echo "Survives theme reloads and new logins until you re-enable."
    notify "Waybar disabled" "Status bar is off system-wide"
}

enable() {
    remove_stub
    remove_env
    start_waybar
    echo "waybar re-enabled."
    if pgrep -u "$USER" -x waybar >/dev/null 2>&1; then
        echo "  Process started."
    else
        echo "  Started launch request; if it does not appear, run: hyde-shell waybar"
    fi
    notify "Waybar enabled" "Status bar is back"
}

case "$ACTION" in
    status)
        status
        ;;
    toggle)
        if is_disabled; then
            enable
        else
            disable
        fi
        ;;
    enable)
        enable
        ;;
    disable)
        disable
        ;;
esac
