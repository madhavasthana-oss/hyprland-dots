#!/usr/bin/env bash
# load-wallust-colors.sh — wallpaper tints TEXT + ICON accents only
#
# Usage:
#   load-wallust-colors.sh                 # wallpaper from running awww, then activate
#   load-wallust-colors.sh --from-awww     # same (explicit)
#   load-wallust-colors.sh /path/to/img    # wallust that image, then activate
#   load-wallust-colors.sh --activate      # only promote existing wallust-colors.json
#   load-wallust-colors.sh --status
#
# Theme.qml watches: <monoshell>/colors/active-colors.json
# Hyprland: also rewrites ~/.config/hypr/hyprland/colors.lua + live hyprctl keywords
#
# Ash monochrome BASE is always kept for surfaces/chrome:
#   bgPrimary, bgSurface, bgElevated, bgConsole, borderIdle, borderConsole,
#   stateCritical / stateSafe / stateWarning
#
# Wallust only replaces (monoshell Theme):
#   accent, accentWarm, accentSoft  (icons, highlights)
#   textPrimary, textSecondary, textMuted, textDim
#   borderActive, glowConsole       (follow accent)
#
# Hyprland mapping (same idea — chrome stays Ash, accents from wallpaper):
#   general.col.active_border   ← accent / borderActive
#   general.col.inactive_border ← borderIdle (Ash)
#   misc.background_color       ← bgPrimary (Ash)
#   pin window_rule border      ← accent + alpha

set -euo pipefail

# qs Process env is often PATH-stripped; always include cargo/local bins
export PATH="${HOME}/.cargo/bin:/usr/local/bin:${PATH:-/usr/bin:/bin}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOSHELL_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COLORS_DIR="${MONOSHELL_DIR}/colors"
WALLUST_JSON="${COLORS_DIR}/wallust-colors.json"
ACTIVE_JSON="${COLORS_DIR}/active-colors.json"
SOURCE_FILE="${COLORS_DIR}/source"

usage() {
    sed -n '2,16p' "$0" | sed 's/^# \?//'
    exit 0
}

find_wallust() {
    if command -v wallust >/dev/null 2>&1; then
        command -v wallust
        return 0
    fi
    for c in "${HOME}/.cargo/bin/wallust" /usr/bin/wallust /usr/local/bin/wallust; do
        if [[ -x "$c" ]]; then
            printf '%s' "$c"
            return 0
        fi
    done
    return 1
}

# Parse `awww query` lines like:
#   : eDP-1: 1920x1080, scale: 1, currently displaying: image: /path/to/wall.jpg
get_awww_wallpaper() {
    if ! command -v awww >/dev/null 2>&1; then
        echo "error: awww not found in PATH" >&2
        return 1
    fi
    if ! pgrep -u "$USER" -x awww-daemon >/dev/null 2>&1; then
        echo "error: awww-daemon is not running" >&2
        return 1
    fi

    local line path
    while IFS= read -r line; do
        if [[ "$line" =~ currently\ displaying:\ image:\ (.+)$ ]]; then
            path="${BASH_REMATCH[1]}"
            path="${path%%$'\r'}"
            path="${path%"${path##*[![:space:]]}"}"
        elif [[ "$line" =~ image:\ (/[^[:space:]].*)$ ]]; then
            path="${BASH_REMATCH[1]}"
            path="${path%%$'\r'}"
            path="${path%"${path##*[![:space:]]}"}"
        else
            continue
        fi

        if [[ -f "$path" ]]; then
            readlink -f "$path"
            return 0
        fi
        if [[ -f "$HOME/$path" ]]; then
            readlink -f "$HOME/$path"
            return 0
        fi
    done < <(awww query 2>/dev/null || true)

    echo "error: awww query did not report a current image path" >&2
    awww query 2>&1 | sed 's/^/  /' >&2 || true
    return 1
}

normalize_hex() {
    local h="${1^^}"
    h="${h//$'\r'/}"
    h="${h// /}"
    [[ "$h" =~ ^#[0-9A-F]{6}$ ]] || return 1
    printf '%s' "$h"
}

# Direct role map from wallust dark16 scheme (color0..15). NO lighten/darken.
# color0  bg black      color8  bright black
# color1  red           color9  bright red
# color2  green         color10 bright green
# color3  yellow        color11 bright yellow
# color4  blue          color12 bright blue
# color5  magenta       color13 bright magenta
# color6  cyan          color14 bright cyan
# color7  white         color15 bright white
#
# Surfaces stay Ash (from legacy-colors.json). Wallust only tints text + accents.
write_palette_from_scheme() {
    local wallpaper="$1"
    shift
    local -a c=("$@")
    if [[ ${#c[@]} -lt 16 ]]; then
        echo "error: need 16 scheme colors, got ${#c[@]}" >&2
        return 1
    fi

    local LEGACY_JSON="${COLORS_DIR}/legacy-colors.json"
    mkdir -p "$COLORS_DIR"
    python3 - "$WALLUST_JSON" "$wallpaper" "$LEGACY_JSON" \
        "${c[0]}" "${c[1]}" "${c[2]}" "${c[3]}" \
        "${c[4]}" "${c[5]}" "${c[6]}" "${c[7]}" \
        "${c[8]}" "${c[9]}" "${c[10]}" "${c[11]}" \
        "${c[12]}" "${c[13]}" "${c[14]}" "${c[15]}" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

out, wallpaper, legacy_path = sys.argv[1], sys.argv[2], sys.argv[3]
cols = sys.argv[4:20]
(
    c0, c1, c2, c3, c4, c5, c6, c7,
    c8, c9, c10, c11, c12, c13, c14, c15,
) = cols

# Fixed Ash chrome — never overridden by wallust
ASH = {
    "bgPrimary":     "#121212",
    "bgSurface":     "#1A1A1A",
    "bgElevated":    "#242424",
    "bgConsole":     "#161616",
    "borderIdle":    "#333333",
    "borderConsole": "#333333",
    "stateCritical": "#E8E8E8",
    "stateSafe":     "#8A8A8A",
    "stateWarning":  "#B8B8B8",
}
# Prefer live legacy file if present (keeps a single source of truth for Ash base)
try:
    leg = json.loads(Path(legacy_path).read_text())
    for k in ASH:
        if k in leg and str(leg[k]).strip():
            ASH[k] = str(leg[k]).strip()
except Exception:
    pass

def lum(h: str) -> float:
    h = h.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def sat(h: str) -> float:
    h = h.lstrip("#")
    r, g, b = int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255
    mx, mn = max(r, g, b), min(r, g, b)
    if mx <= 0:
        return 0.0
    return (mx - mn) / mx

# --- wallust → text + icon/accent only (raw hex picks, no lighten/darken) ---
by_lum = sorted(cols, key=lum)
light = [c for c in reversed(by_lum) if lum(c) > 140] or list(reversed(by_lum[-3:]))
mid = [c for c in cols if 40 <= lum(c) <= 200]
if not mid:
    mid = by_lum[len(by_lum) // 2 : len(by_lum) // 2 + 3]
muted_pool = [c for c in by_lum if 35 <= lum(c) <= 130]

# Icons / highlights: most saturated mid hues from the wallpaper
accent_pool = sorted(
    set(mid + [c4, c12, c1, c9, c5, c13, c3, c11, c6, c14]),
    key=lambda h: -sat(h),
)
accent = accent_pool[0] if accent_pool else c4
accent_warm = next((h for h in accent_pool if h != accent), c3)
accent_soft = next((h for h in accent_pool if h not in (accent, accent_warm)), c5)

# Text: light scheme colors (readable on fixed Ash bg)
text_primary = light[0]
text_secondary = light[1] if len(light) > 1 else light[0]
text_muted = muted_pool[len(muted_pool) // 2] if muted_pool else c8
text_dim = muted_pool[0] if muted_pool else c8

data = {
    "_comment": "Monoshell wallust — Ash surfaces fixed; only text + accents from wallpaper",
    "_source": "wallust",
    "_mode": "accents-and-text",
    "_wallpaper": wallpaper,
    "_generated": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
    # Chrome (Ash) — monochrome vibe preserved
    **ASH,
    # Wallpaper-tinted (icons, labels, active stroke)
    "accent":        accent,
    "accentWarm":    accent_warm,
    "accentSoft":    accent_soft,
    "textPrimary":   text_primary,
    "textSecondary": text_secondary,
    "textMuted":     text_muted,
    "textDim":       text_dim,
    "borderActive":  accent,
    "glowConsole":   accent_warm,
    # Raw scheme for debugging
    "color0": c0, "color1": c1, "color2": c2, "color3": c3,
    "color4": c4, "color5": c5, "color6": c6, "color7": c7,
    "color8": c8, "color9": c9, "color10": c10, "color11": c11,
    "color12": c12, "color13": c13, "color14": c14, "color15": c15,
}

with open(out, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"wrote: {out}")
print(f"  surfaces=Ash fixed  accent={accent}  text={text_primary}/{text_secondary}")
PY
}

# Write hyprland/colors.lua + apply live borders from a monoshell role JSON.
# Same philosophy as Theme: only active/pin borders take wallpaper accent.
apply_hyprland_colors_from_json() {
    local json="$1"
    local out="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland/colors.lua"
    local triple

    if [[ ! -f "$json" ]]; then
        echo "warning: skip hyprland colors — missing $json" >&2
        return 0
    fi

    if ! triple="$(python3 - "$json" "$out" <<'PY'
import json, sys
from pathlib import Path

src, out = Path(sys.argv[1]), Path(sys.argv[2])
data = json.loads(src.read_text())

def hex6(*keys, fallback="C8C8C8"):
    for key in keys:
        v = str(data.get(key) or "").strip()
        if not v:
            continue
        v = v[1:] if v.startswith("#") else v
        v = v.upper()
        if len(v) == 6 and all(c in "0123456789ABCDEF" for c in v):
            return v.lower()
    return fallback.lower()

active = hex6("borderActive", "accent", fallback="C8C8C8")
idle = hex6("borderIdle", fallback="333333")
bg = hex6("bgPrimary", fallback="121212")

out.parent.mkdir(parents=True, exist_ok=True)
text = f"""hl.config({{
    general = {{
        col = {{
            active_border   = "rgb({active})",
            inactive_border = "rgb({idle})",
        }},
    }},
    misc = {{
        background_color = "rgb({bg})",
    }},
}})

hl.window_rule({{
    match        = {{ pin = 1 }},
    border_color = "rgba({active}AA) rgba({active}77)",
}})
"""
tmp = out.with_suffix(".lua.tmp")
tmp.write_text(text)
tmp.replace(out)
# stdout: bare hex triple for shell/hyprctl
print(f"{active} {idle} {bg}")
PY
)"; then
        echo "warning: failed to write hyprland colors.lua" >&2
        return 0
    fi

    local active idle bg
    read -r active idle bg <<< "$triple"
    echo "hyprland: wrote $out"
    echo "  active_border=rgb(${active})  inactive=rgb(${idle})  bg=rgb(${bg})"

    # Live apply without full config reload (pin window_rule needs reload/login)
    if command -v hyprctl >/dev/null 2>&1 && hyprctl -j monitors &>/dev/null; then
        hyprctl --batch "\
keyword general:col.active_border rgb(${active}) ;\
keyword general:col.inactive_border rgb(${idle}) ;\
keyword misc:background_color rgb(${bg})" >/dev/null 2>&1 \
            && echo "hyprland: live borders applied (hyprctl)" \
            || echo "warning: hyprctl keyword apply failed" >&2
    else
        echo "hyprland: not running — colors.lua only (apply on next reload)"
    fi
}

activate_wallust() {
    mkdir -p "$COLORS_DIR"
    if [[ ! -f "$WALLUST_JSON" ]]; then
        echo "error: missing $WALLUST_JSON" >&2
        echo "hint: run with --from-awww or a wallpaper path first" >&2
        exit 1
    fi
    python3 - "$WALLUST_JSON" <<'PY'
import json, sys
required = [
    "bgPrimary", "bgSurface", "bgElevated",
    "accent", "accentWarm", "accentSoft",
    "textPrimary", "textSecondary", "textMuted", "textDim",
    "stateCritical", "stateSafe", "stateWarning",
    "borderActive", "borderIdle",
    "bgConsole", "borderConsole", "glowConsole",
]
data = json.load(open(sys.argv[1]))
missing = [k for k in required if k not in data or not str(data[k]).strip()]
if missing:
    sys.stderr.write("error: wallust-colors.json missing keys: " + ", ".join(missing) + "\n")
    sys.exit(1)
PY
    cp -f "$WALLUST_JSON" "${ACTIVE_JSON}.tmp"
    mv -f "${ACTIVE_JSON}.tmp" "$ACTIVE_JSON"
    printf 'wallust\n' > "$SOURCE_FILE"
    echo "activated: wallust → $ACTIVE_JSON"
    apply_hyprland_colors_from_json "$ACTIVE_JSON"
}

run_wallust_on() {
    local img="$1"
    local bin
    if ! bin="$(find_wallust)"; then
        echo "error: wallust not found (install or put it on PATH / ~/.cargo/bin)" >&2
        exit 1
    fi
    if [[ ! -f "$img" ]]; then
        echo "error: not a file: $img" >&2
        exit 1
    fi
    img="$(readlink -f "$img")"
    echo "wallust: $bin"
    echo "image:   $img"

    # Prefer dark16 for a full 16-color map; skip terminal sequences (shell only)
    local raw
    if ! raw="$("$bin" run -s -N -p dark16 --print-scheme "$img" 2>/dev/null)"; then
        # Fallback without palette flag if older wallust
        if ! raw="$("$bin" run -s -N --print-scheme "$img" 2>/dev/null)"; then
            echo "error: wallust failed to generate a scheme for: $img" >&2
            "$bin" run -s -N --print-scheme "$img" >&2 || true
            exit 1
        fi
    fi

    local -a colors=()
    local line hx
    while IFS= read -r line; do
        line="${line//$'\r'/}"
        line="${line// /}"
        # Accept "#RRGGBB" or bare RRGGBB; ignore log lines
        if [[ "$line" =~ ^#?[0-9A-Fa-f]{6}$ ]]; then
            hx="$line"
            [[ "$hx" == \#* ]] || hx="#$hx"
            if hx="$(normalize_hex "$hx")"; then
                colors+=("$hx")
            fi
        fi
    done <<< "$raw"

    if [[ ${#colors[@]} -lt 16 ]]; then
        echo "error: wallust --print-scheme returned ${#colors[@]} colors (need 16)" >&2
        echo "raw output:" >&2
        printf '%s\n' "$raw" | sed 's/^/  /' >&2
        exit 1
    fi

    # First 16 only — monoshell accents + text (Ash surfaces kept)
    write_palette_from_scheme "$img" "${colors[@]:0:16}"
}

status() {
    local src="(none)"
    [[ -f "$SOURCE_FILE" ]] && src="$(tr -d '\n' < "$SOURCE_FILE")"
    local bin="(missing)"
    if b="$(find_wallust 2>/dev/null)"; then bin="$b"; fi
    echo "monoshell:  $MONOSHELL_DIR"
    echo "source:     $src"
    echo "wallust:    $bin"
    echo "palette:    $WALLUST_JSON$([ -f "$WALLUST_JSON" ] && echo ' (ok)' || echo ' (missing)')"
    echo "active:     $ACTIVE_JSON$([ -f "$ACTIVE_JSON" ] && echo ' (ok)' || echo ' (missing)')"
    if [[ -f "$ACTIVE_JSON" ]]; then
        python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for k in ("bgPrimary", "accent", "textPrimary", "stateCritical", "_source", "_wallpaper"):
    if k in d:
        print(f"  {k:16} {d[k]}")
' "$ACTIVE_JSON"
    fi
    if command -v awww >/dev/null 2>&1 && pgrep -u "$USER" -x awww-daemon >/dev/null 2>&1; then
        local cur
        if cur="$(get_awww_wallpaper 2>/dev/null)"; then
            echo "awww image: $cur"
        else
            echo "awww image: (unavailable)"
        fi
    else
        echo "awww image: (daemon not running)"
    fi
}

ACTION="from-awww"
WALL_IMG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        --status) ACTION="status" ;;
        --activate) ACTION="activate" ;;
        --from-awww) ACTION="from-awww" ;;
        *)
            WALL_IMG="$1"
            ACTION="run-path"
            ;;
    esac
    shift
done

case "$ACTION" in
    status)
        status
        ;;
    activate)
        activate_wallust
        status
        ;;
    from-awww)
        WALL_IMG="$(get_awww_wallpaper)"
        run_wallust_on "$WALL_IMG"
        activate_wallust
        status
        ;;
    run-path)
        run_wallust_on "$WALL_IMG"
        activate_wallust
        status
        ;;
esac
