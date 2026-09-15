#!/usr/bin/env bash
# Toggle a transparent glava overlay along the full bottom of the screen.
# Lives under <shell>/utils/scripts; shaders at <shell>/assets/glava/
set -uo pipefail

# utils/scripts -> shell root (folder with shell.qml)
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHELL_NAME="$(basename "$SHELL_DIR")"
TITLE="${SHELL_NAME}-glava"
CLASS="GLava"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/${SHELL_NAME}-glava.pid"
SYS_GLAVA="/etc/xdg/glava"
ASSET_DIR="${SHELL_DIR}/assets/glava"

if [[ ! -f "${ASSET_DIR}/rc.glsl" ]]; then
  echo "glava config missing: ${ASSET_DIR}/rc.glsl" >&2
  exit 1
fi
if ! command -v glava >/dev/null 2>&1; then
  echo "need glava" >&2
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

# Rewrite COLOR / BAR_OUTLINE from the live Theme JSON (wallust or Ash).
paint_bars() {
  local dest="$1"
  local json="${SHELL_DIR}/colors/active-colors.json"
  if ! python3 - "$json" "${ASSET_DIR}/bars.glsl" "$dest" <<'PY'
import json, re, sys
from pathlib import Path

json_path, src_path, dest_path = map(Path, sys.argv[1:4])
lo, hi, outline = "#454545", "#C8C8C8", "#333333"

def hx(data, *keys, fallback):
    for key in keys:
        raw = str(data.get(key) or "").strip()
        if raw.startswith("#"):
            raw = raw[1:]
        raw = raw[:6].upper()
        if len(raw) == 6 and all(c in "0123456789ABCDEF" for c in raw):
            return f"#{raw}"
    return fallback

try:
    data = json.loads(json_path.read_text())
    lo = hx(data, "textDim", fallback=lo)
    hi = hx(data, "accent", "borderActive", fallback=hi)
    outline = hx(data, "borderIdle", fallback=outline)
except Exception:
    pass

text = src_path.read_text()
text, n_color = re.subn(
    r"^#define COLOR\s+.*$",
    f"#define COLOR mix({lo}, {hi}, GRADIENT)",
    text,
    count=1,
    flags=re.M,
)
text, n_out = re.subn(
    r"^#define BAR_OUTLINE\s+.*$",
    f"#define BAR_OUTLINE {outline}",
    text,
    count=1,
    flags=re.M,
)
dest_path.write_text(text)
print(f"glava bars: lo={lo} hi={hi} outline={outline}", file=sys.stderr)
PY
  then
    cp -f "${ASSET_DIR}/bars.glsl" "$dest"
  fi
}

# User overrides + system module/util links so GLava can resolve #include ":…".
prep_conf() {
  local root="${XDG_RUNTIME_DIR:-/tmp}/${SHELL_NAME}-glava-conf"
  local dest="${root}/glava"
  mkdir -p "$dest"
  cp -f "${ASSET_DIR}/rc.glsl" "${dest}/rc.glsl"
  paint_bars "${dest}/bars.glsl"
  if [[ -d "$SYS_GLAVA" ]]; then
    local name bn
    for name in bars circle graph radial wave util; do
      [[ -e "${SYS_GLAVA}/${name}" ]] || continue
      [[ -e "${dest}/${name}" ]] || ln -sfn "${SYS_GLAVA}/${name}" "${dest}/${name}"
    done
    for f in "${SYS_GLAVA}"/*.glsl; do
      [[ -f "$f" ]] || continue
      bn="$(basename "$f")"
      [[ "$bn" == "rc.glsl" || "$bn" == "bars.glsl" ]] && continue
      [[ -e "${dest}/${bn}" ]] || ln -sfn "$f" "${dest}/${bn}"
    done
  fi
  printf '%s' "$root"
}

glava_running() {
  if [[ -f "$PIDFILE" ]]; then
    local pid
    pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  pgrep -x glava >/dev/null 2>&1
}

stop_glava() {
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
  pgrep -x glava >/dev/null 2>&1 && pkill -x glava || true
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys,os,signal
try:
  clients=json.load(sys.stdin)
except Exception:
  sys.exit(0)
for c in clients:
  cls=c.get('class') or ''
  title=c.get('title') or ''
  if cls=='${CLASS}' or title=='${TITLE}':
    pid=c.get('pid')
    if pid:
      try: os.kill(int(pid), signal.SIGTERM)
      except Exception: pass
" 2>/dev/null || true
  fi
}

place_bottom() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  # Do not focus the overlay — pin + size/move rules already place it.
  hyprctl dispatch resizewindowpixel "exact ${MON_W} ${STRIP_H},class:^(${CLASS})$" >/dev/null 2>&1 || true
  hyprctl dispatch movewindowpixel "exact 0 ${STRIP_Y},class:^(${CLASS})$" >/dev/null 2>&1 || true
}

start_glava() {
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

  local conf_root
  conf_root="$(prep_conf)"

  env XDG_CONFIG_HOME="${conf_root}" glava \
    --request="settitle \"${TITLE}\"" \
    --request="setgeometry 0 ${STRIP_Y} ${MON_W} ${STRIP_H}" \
    --request="setfloating true" \
    --request="setdecorated false" \
    --request="setfocused false" \
    --request="setprintframes false" \
    --request="setclickthrough true" \
    --request="setopacity \"native\"" \
    --request="setbg 00000000" &
  echo $! >"$PIDFILE"

  sleep 0.35
  place_bottom
  sleep 0.15
  place_bottom
}

case "${1:-toggle}" in
  on|start)
    stop_glava
    start_glava
    sleep 0.25
    if glava_running; then echo "on"; else echo "off"; fi
    ;;
  off|stop)
    stop_glava
    echo "off"
    ;;
  status)
    if glava_running; then echo "on"; else echo "off"; fi
    ;;
  recolor|reload)
    # Wallust / Ash loaders call this. Restart only if the overlay is up.
    if glava_running; then
      stop_glava
      start_glava
      sleep 0.25
      if glava_running; then
        echo "glava: recolored"
      else
        echo "warning: glava recolor restart failed" >&2
      fi
    else
      echo "glava: not running"
    fi
    ;;
  toggle|*)
    if glava_running; then
      stop_glava
      echo "off"
    else
      start_glava
      sleep 0.25
      if glava_running; then echo "on"; else echo "off"; fi
    fi
    ;;
esac
