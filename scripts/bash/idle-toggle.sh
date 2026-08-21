#!/usr/bin/env bash
# idle-toggle.sh — start/stop hypridle (auto lock / DPMS / suspend)
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
  • Flag:  ~/.config/hypridle/.disabled  (Hyprland execs.lua honors this)
  • Stub:  ~/.local/bin/hypridle         (only if ~/.local/bin is first in PATH)
  • Kills hypridle and any hyde-*-idle / hypridle user units
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

# Minimal environments (Quickshell Process) may omit USER
USER="${USER:-$(id -un 2>/dev/null || true)}"
USER="${USER:-$(id -u)}"
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

is_running() {
    pgrep -u "$USER" -x hypridle >/dev/null 2>&1 \
        || pgrep -u "$USER" -f '[/]usr/bin/hypridle' >/dev/null 2>&1
}

notify() {
    local title="$1" body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        timeout 1s notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

# systemctl can block on a missing bus; never wait on it before pkill
sys_stop() {
    systemctl --user --no-block stop "$1" >/dev/null 2>&1 || true
    systemctl --user --no-block reset-failed "$1" >/dev/null 2>&1 || true
}

stop_idle() {
    local unit
    while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        sys_stop "$unit"
    done < <(systemctl --user list-units --type=service --all --no-legend 'hyde-*-idle.service' 2>/dev/null | awk '{print $1}' || true)

    sys_stop "hyde-${XDG_SESSION_DESKTOP:-Hyprland}-idle.service"
    sys_stop hypridle.service

    pkill -u "$USER" -x hypridle 2>/dev/null || true
    pkill -u "$USER" -f '[/]usr/bin/hypridle' 2>/dev/null || true

    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        if ! is_running; then
            return 0
        fi
        pkill -u "$USER" -x hypridle 2>/dev/null || true
        pkill -KILL -u "$USER" -x hypridle 2>/dev/null || true
        sleep 0.1
    done

    if is_running; then
        echo "warning: hypridle still running after stop" >&2
        return 1
    fi
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
    if is_running; then
        return 0
    fi

    # New session + closed stdio: survives Quickshell Process teardown and
    # never pins the parent's stdout pipe (which would stall the widget).
    if command -v setsid >/dev/null 2>&1; then
        if ! setsid --fork "$REAL_IDLE" </dev/null >/dev/null 2>&1; then
            setsid "$REAL_IDLE" </dev/null >/dev/null 2>&1 &
            disown 2>/dev/null || true
        fi
    else
        nohup "$REAL_IDLE" </dev/null >/dev/null 2>&1 &
        disown 2>/dev/null || true
    fi

    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        if is_running; then
            return 0
        fi
        sleep 0.1
    done
    echo "warning: hypridle did not start" >&2
    return 1
}

status() {
    local running=0
    is_running && running=1

    if is_disabled; then
        echo "hypridle: DISABLED"
        echo "  Flag: $FLAG_FILE"
        [[ -x "$STUB" ]] && echo "  Stub: $STUB"
        if (( running )); then
            echo "  Note: hypridle still running (re-run --disable)"
            echo "  Process: running (pid $(pgrep -u "$USER" -x hypridle | tr '\n' ' '))"
        else
            echo "  Process: not running"
        fi
        echo "STATE=disabled RUNNING=$running"
    else
        echo "hypridle: ENABLED"
        if (( running )); then
            echo "  Process: running (pid $(pgrep -u "$USER" -x hypridle | tr '\n' ' '))"
        else
            echo "  Process: not running"
        fi
        echo "STATE=enabled RUNNING=$running"
    fi
}

disable() {
    local ok=0
    install_stub
    install_env
    stop_idle || ok=1
    echo "hypridle disabled — no auto-lock / idle suspend."
    echo "  Flag:  $FLAG_FILE"
    echo "  Stub:  $STUB"
    notify "Idle disabled" "Screen will not auto-lock"
    return "$ok"
}

enable() {
    local ok=0
    remove_stub
    remove_env
    start_idle || ok=1
    echo "hypridle re-enabled."
    if is_running; then
        echo "  Process started."
    else
        echo "  Launch requested; if idle, run: /usr/bin/hypridle &"
        ok=1
    fi
    notify "Idle enabled" "Auto-lock is back"
    return "$ok"
}

st=0
case "$ACTION" in
    status)  status ;;
    toggle)
        if is_disabled; then enable || st=$?; else disable || st=$?; fi
        status
        exit "$st"
        ;;
    enable)
        enable || st=$?
        status
        exit "$st"
        ;;
    disable)
        disable || st=$?
        status
        exit "$st"
        ;;
esac
