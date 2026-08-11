#!/usr/bin/env bash
# Toggle doom-themed cava overlay along the full bottom of the screen.
# Lives under astral-vagabond/utils/scripts; cava config at astral-vagabond/assets/cava/config
set -uo pipefail

CLASS="astral-vagabond-cava"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/astral-vagabond-cava.pid"
# utils/scripts -> shell root (folder with shell.qml)
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CAVA_CONF="${SHELL_DIR}/assets/cava/config"
# Fallback if running from an older tree layout
[[ -f "$CAVA_CONF" ]] || CAVA_CONF="${HOME}/.config/quickshell/astral-vagabond/assets/cava/config"
[[ -f "$CAVA_CONF" ]] || CAVA_CONF="${HOME}/Doomslayer-mod/.config/quickshell/astral-vagabond/assets/cava/config"

if [[ ! -f "$CAVA_CONF" ]]; then
  echo "cava config missing: $CAVA_CONF" >&2
  exit 1
fi
if ! command -v cava >/dev/null 2>&1 || ! command -v kitty >/dev/null 2>&1; then
  echo "need cava + kitty" >&2
  exit 1
fi

MON_W=1920
MON_H=1080
if command -v hyprctl >/dev/null 2>&1; then
  read -r MON_W MON_H < <(hyprctl monitors -j 2>/dev/null | python3 -c "
import json,sys
try:
  m=json.load(sys.stdin)[0]
  print(int(m['width']), int(m['height']))
except Exception:
  print(1920, 1080)
" 2>/dev/null || echo "1920 1080")
fi

STRIP_H=$(( MON_H * 22 / 100 ))
[[ "$STRIP_H" -lt 120 ]] && STRIP_H=120
STRIP_Y=$(( MON_H - STRIP_H ))

stop_cava() {
  if [[ -f "$PIDFILE" ]]; then
    local pid
    pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 0.1
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
  fi
  pgrep -x cava >/dev/null 2>&1 && pkill -x cava || true
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys,os,signal
try:
  clients=json.load(sys.stdin)
except Exception:
  sys.exit(0)
for c in clients:
  if c.get('class')=='${CLASS}' or c.get('initialClass')=='${CLASS}':
    pid=c.get('pid')
    if pid:
      try: os.kill(int(pid), signal.SIGTERM)
      except Exception: pass
" 2>/dev/null || true
  fi
}

# Place astral-vagabond-cava at full bottom strip via hyprlua (works on this stack)
place_bottom() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  hyprctl eval "
for _, w in ipairs(hl.get_windows() or {}) do
  if w.class == '${CLASS}' then
    hl.dispatch(hl.dsp.focus({ window = w }))
    hl.dispatch(hl.dsp.window.resize({ x = ${MON_W}, y = ${STRIP_H}, 'exact' }))
    hl.dispatch(hl.dsp.window.move({ x = 0, y = ${STRIP_Y}, 'exact' }))
  end
end
" >/dev/null 2>&1 || true
}

start_cava() {
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl --batch "\
keyword windowrulev2 float, class:^(${CLASS})$;\
keyword windowrulev2 pin, class:^(${CLASS})$;\
keyword windowrulev2 bordersize 0, class:^(${CLASS})$;\
keyword windowrulev2 noshadow, class:^(${CLASS})$;\
keyword windowrulev2 noinitialfocus, class:^(${CLASS})$;\
keyword windowrulev2 size 100% 22%, class:^(${CLASS})$;\
keyword windowrulev2 move 0 78%, class:^(${CLASS})$" >/dev/null 2>&1 || true
  fi

  kitty --class "${CLASS}" --title cava-overlay \
    -o font_size=10 \
    -o background_opacity=0.0 \
    -o dynamic_background_opacity=yes \
    -o background='#000000' \
    -o foreground='#C8C8C8' \
    -o hide_window_decorations=yes \
    -o confirm_os_window_close=0 \
    -o remember_window_size=no \
    -o initial_window_width="${MON_W}" \
    -o initial_window_height="${STRIP_H}" \
    -o window_padding_width=0 \
    -o window_margin_width=0 \
    cava -p "${CAVA_CONF}" &
  echo $! >"$PIDFILE"

  # rules often center on first map — pin to bottom after it exists
  sleep 0.35
  place_bottom
  sleep 0.15
  place_bottom
}

case "${1:-toggle}" in
  on|start)
    stop_cava
    start_cava
    sleep 0.25
    if pgrep -x cava >/dev/null 2>&1; then echo "on"; else echo "off"; fi
    ;;
  off|stop)
    stop_cava
    echo "off"
    ;;
  status)
    if pgrep -x cava >/dev/null 2>&1; then echo "on"; else echo "off"; fi
    ;;
  toggle|*)
    if pgrep -x cava >/dev/null 2>&1; then
      stop_cava
      echo "off"
    else
      start_cava
      sleep 0.25
      if pgrep -x cava >/dev/null 2>&1; then echo "on"; else echo "off"; fi
    fi
    ;;
esac
