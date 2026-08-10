#!/usr/bin/env bash
# idle-toggle.sh — disable hypridle globally (HyDE-aware)
# Usage:
#   ./idle-toggle.sh            # disable idle lock/suspend
#   ./idle-toggle.sh --enable   # re-enable
#   ./idle-toggle.sh --status
#   ./idle-toggle.sh --toggle

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

Disable or re-enable hypridle (auto lock / DPMS / suspend) system-wide.

  (default) / --disable   Stop hypridle and block future launches
  --enable                Remove the block and start hypridle again
  --toggle                Flip state
  --status                Print current state

How it works:
  • Flag:  ~/.config/hypridle/.disabled
  • Stub:  ~/.local/bin/hypridle
  • Stops hyde-*-idle.service and hypridle processes

Note: this is stronger than HyDE's idle-inhibitor (which is temporary).
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
FLAG_FILE="$CONFIG_DIR/hypridle/.disabled"
STUB="$LOCAL_BIN/hypridle"
REAL_IDLE="/usr/bin/hypridle"
ENV_D="$CONFIG_DIR/environment.d/idle-toggle.conf"

is_disabled() {
    [[ -f "$FLAG_FILE" ]]
}

notify() {
    local title="$1" body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

stop_idle() {
    local unit
    while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        systemctl --user stop "$unit" 2>/dev/null || true
        systemctl --user reset-failed "$unit" 2>/dev/null || true
    done < <(systemctl --user list-units --type=service --all --no-legend 'hyde-*-idle.service' 2>/dev/null | awk '{print $1}')

    systemctl --user stop "hyde-${XDG_SESSION_DESKTOP:-Hyprland}-idle.service" 2>/dev/null || true
    systemctl --user stop hypridle.service 2>/dev/null || true
    pkill -u "$USER" -x hypridle 2>/dev/null || true
    pkill -u "$USER" -f '[/]usr/bin/hypridle' 2>/dev/null || true
}

install_stub() {
    mkdir -p "$LOCAL_BIN" "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"
    cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
# hypridle stub — installed by idle-toggle.sh
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/hypridle/.disabled" ]]; then
    exit 0
fi
exec /usr/bin/hypridle "$@"
EOF
    chmod +x "$STUB"
}

remove_stub() {
    rm -f "$FLAG_FILE" "$STUB"
}

install_env() {
    mkdir -p "$(dirname "$ENV_D")"
    echo "DISABLE_HYPRIDLE=1" > "$ENV_D"
}

remove_env() {
    rm -f "$ENV_D"
}

start_idle() {
    if [[ ! -x "$REAL_IDLE" ]]; then
        echo "warning: $REAL_IDLE not found" >&2
        return 1
    fi
    local unit="hyde-${XDG_SESSION_DESKTOP:-Hyprland}-idle.service"
    systemctl --user stop "$unit" 2>/dev/null || true
    systemd-run --user \
        --unit="$unit" \
        --slice=app-graphical.slice \
        --property=Type=exec \
        --property=ExitType=cgroup \
        --property=After=graphical-session.target \
        --property=PartOf=graphical-session.target \
        --quiet \
        -- "$REAL_IDLE" 2>/dev/null || "$REAL_IDLE" &
    disown 2>/dev/null || true
}

status() {
    if is_disabled; then
        echo "hypridle: DISABLED"
        echo "  Flag: $FLAG_FILE"
        [[ -x "$STUB" ]] && echo "  Stub: $STUB"
        if pgrep -u "$USER" -x hypridle >/dev/null 2>&1; then
            echo "  Note: hypridle still running (re-run --disable)"
        else
            echo "  Process: not running"
        fi
    else
        echo "hypridle: ENABLED"
        if pgrep -u "$USER" -x hypridle >/dev/null 2>&1; then
            echo "  Process: running (pid $(pgrep -u "$USER" -x hypridle | tr '\n' ' '))"
        else
            echo "  Process: not running"
        fi
    fi
}

disable() {
    install_stub
    install_env
    stop_idle
    sleep 0.2
    stop_idle
    echo "hypridle disabled — no auto-lock / idle suspend."
    echo "  Flag:  $FLAG_FILE"
    echo "  Stub:  $STUB"
    notify "Idle disabled" "Screen will not auto-lock"
}

enable() {
    remove_stub
    remove_env
    start_idle
    echo "hypridle re-enabled."
    if pgrep -u "$USER" -x hypridle >/dev/null 2>&1; then
        echo "  Process started."
    else
        echo "  Launch requested; if idle, run: /usr/bin/hypridle &"
    fi
    notify "Idle enabled" "Auto-lock is back"
}

case "$ACTION" in
    status)  status ;;
    toggle)
        if is_disabled; then enable; else disable; fi
        ;;
    enable)  enable ;;
    disable) disable ;;
esac
