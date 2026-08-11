#!/usr/bin/env bash
# wallpaper.sh — set / cycle Doomslayer-mod wallpapers
# Usage:
#   ./wallpaper.sh --list
#   ./wallpaper.sh --next
#   ./wallpaper.sh --random
#   ./wallpaper.sh --set <name-or-path>
#   ./wallpaper.sh --live              # prefer live video wallpapers
#   ./wallpaper.sh --status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOD_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
WALL_DIR="${MOD_ROOT}/Pictures/Wallpapers"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/doomslayer"
STATE_FILE="$STATE_DIR/wallpaper.state"
LIVE=false

# Animated switch defaults (override with env if you want)
TRANSITION_TYPE="${AWWW_TRANSITION:-random}"
TRANSITION_DURATION="${AWWW_TRANSITION_DURATION:-2}"
TRANSITION_FPS="${AWWW_TRANSITION_FPS:-60}"

usage() {
    cat <<EOF
Usage: $0 [--list|--next|--random|--status|--set <name>] [--live]

Apply wallpapers from the Doomslayer-mod collection without depending on
HyDE theme wallpaper caches.

  --list              List available wallpapers (static + live)
  --next              Cycle to the next wallpaper in order
  --random            Pick a random wallpaper
  --set <name|path>   Set by filename fragment or absolute path
  --live              Prefer video wallpapers under live-wallpapers-*/
  --status            Show last applied wallpaper
  -h, --help          This help

Static images + animated GIFs use awww (with transition animations).
Videos use mpvpaper when installed.

Env (awww transitions):
  AWWW_TRANSITION            type (default: random)
  AWWW_TRANSITION_DURATION   seconds (default: 2)
  AWWW_TRANSITION_FPS        fps (default: 60)
EOF
    exit 0
}

notify() {
    local title="$1" body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

# Collect wallpaper paths (one per line, sorted)
collect_walls() {
    local prefer_live="$1"
    local -a statics lives
    local f

    while IFS= read -r -d '' f; do
        statics+=("$f")
    done < <(find "$WALL_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
        -print0 2>/dev/null | sort -z)

    while IFS= read -r -d '' f; do
        lives+=("$f")
    done < <(find "$WALL_DIR" -mindepth 2 -type f \
        \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.gif' \) \
        -print0 2>/dev/null | sort -z)

    if [[ "$prefer_live" == "true" ]]; then
        printf '%s\n' "${lives[@]:-}" "${statics[@]:-}"
    else
        printf '%s\n' "${statics[@]:-}" "${lives[@]:-}"
    fi
}

is_video() {
    local mime
    mime="$(file --mime-type -b "$1" 2>/dev/null || true)"
    [[ "$mime" == video/* ]] || [[ "$1" == *.mp4 ]] || [[ "$1" == *.webm ]] || [[ "$1" == *.mkv ]]
}

is_gif() {
    local mime
    mime="$(file --mime-type -b "$1" 2>/dev/null || true)"
    [[ "$mime" == image/gif ]] || [[ "$1" == *.gif ]]
}

stop_live() {
    pkill -u "$USER" -x mpvpaper 2>/dev/null || true
}

stop_hyprpaper() {
    pkill -u "$USER" -x hyprpaper 2>/dev/null || true
}

ensure_awww() {
    if ! command -v awww >/dev/null 2>&1; then
        echo "error: awww not installed (pacman -S awww)" >&2
        return 1
    fi

    stop_hyprpaper

    if ! pgrep -u "$USER" -x awww-daemon >/dev/null 2>&1; then
        awww-daemon >/dev/null 2>&1 &
        disown 2>/dev/null || true
        local i
        for i in {1..50}; do
            if awww query >/dev/null 2>&1; then
                return 0
            fi
            sleep 0.1
        done
        echo "error: awww-daemon failed to start" >&2
        return 1
    fi
    return 0
}

apply_static() {
    local path="$1"
    stop_live
    ensure_awww || return 1

    awww img "$path" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps "$TRANSITION_FPS" \
        --resize crop
}

apply_live() {
    local path="$1"

    # awww natively animates GIFs — prefer it over mpvpaper
    if is_gif "$path"; then
        apply_static "$path"
        return 0
    fi

    if ! command -v mpvpaper >/dev/null 2>&1; then
        echo "warning: mpvpaper not installed; cannot play video wallpaper" >&2
        return 1
    fi

    stop_live
    stop_hyprpaper

    # Drop awww so mpvpaper owns the background layer
    if pgrep -u "$USER" -x awww-daemon >/dev/null 2>&1; then
        awww kill >/dev/null 2>&1 || pkill -u "$USER" -x awww-daemon 2>/dev/null || true
        sleep 0.2
    fi

    # Cover all monitors ("*")
    mpvpaper -o "no-audio --loop-file=inf --hwdec=auto" '*' "$path" >/dev/null 2>&1 &
    disown 2>/dev/null || true
}

# Theme astral-vagabond + hypr borders from whatever awww is currently showing.
# Falls back to the just-applied path if awww has no image (e.g. mpvpaper video).
# load-wallust-colors.sh also rewrites hyprland/colors.lua and applies live borders.
theme_astral_vagabond_from_awww() {
    local fallback="${1:-}"
    local theme_script="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/astral-vagabond/utils/scripts/load-wallust-colors.sh"

    if [[ ! -x "$theme_script" ]]; then
        echo "warning: astral-vagabond theme script missing: $theme_script" >&2
        return 0
    fi

    # Brief settle so awww query sees the new image after transition start
    sleep 0.15

    if "$theme_script" --from-awww; then
        notify "Theme" "wallust ← awww (astral-vagabond + hypr)"
        return 0
    fi

    if [[ -n "$fallback" && -f "$fallback" ]] && ! is_video "$fallback"; then
        if "$theme_script" "$fallback"; then
            notify "Theme" "wallust ← $(basename "$fallback") (astral-vagabond + hypr)"
            return 0
        fi
    fi

    echo "warning: wallust theme failed (wallpaper still applied)" >&2
    return 0
}

apply_wall() {
    local path="$1"
    path="$(readlink -f "$path")"
    if [[ ! -f "$path" ]]; then
        echo "error: not a file: $path" >&2
        exit 1
    fi

    mkdir -p "$STATE_DIR"
    echo "$path" > "$STATE_FILE"

    if is_video "$path"; then
        apply_live "$path"
        echo "Wallpaper (live): $path"
    elif is_gif "$path"; then
        apply_live "$path"
        echo "Wallpaper (gif): $path"
    else
        apply_static "$path"
        echo "Wallpaper: $path"
    fi
    notify "Wallpaper" "$(basename "$path")"

    # SUPER+W path: recolor quickshell from the live awww image
    theme_astral_vagabond_from_awww "$path"
}

list_walls() {
    local prefer_live="false"
    $LIVE && prefer_live="true"
    local i=0 path
    echo "Doomslayer wallpapers ($WALL_DIR):"
    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        i=$((i + 1))
        local tag="img"
        is_video "$path" && tag="vid"
        is_gif "$path" && tag="gif"
        printf "  %2d  [%s]  %s\n" "$i" "$tag" "${path#"$WALL_DIR"/}"
    done < <(collect_walls "$prefer_live")
    if [[ $i -eq 0 ]]; then
        echo "  (none found)"
    fi
}

resolve_set_arg() {
    local arg="$1"
    if [[ -f "$arg" ]]; then
        echo "$arg"
        return
    fi
    if [[ -f "$WALL_DIR/$arg" ]]; then
        echo "$WALL_DIR/$arg"
        return
    fi
    # fuzzy basename match
    local prefer_live="false"
    $LIVE && prefer_live="true"
    local path
    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        if [[ "$(basename "$path")" == *"$arg"* ]]; then
            echo "$path"
            return
        fi
    done < <(collect_walls "$prefer_live")
    return 1
}

next_wall() {
    local prefer_live="false"
    $LIVE && prefer_live="true"
    mapfile -t walls < <(collect_walls "$prefer_live")
    [[ ${#walls[@]} -gt 0 ]] || { echo "error: no wallpapers found in $WALL_DIR" >&2; exit 1; }

    local current="" idx=0
    [[ -f "$STATE_FILE" ]] && current="$(cat "$STATE_FILE")"

    if [[ -n "$current" ]]; then
        local i
        for i in "${!walls[@]}"; do
            if [[ "${walls[$i]}" == "$current" ]]; then
                idx=$(( (i + 1) % ${#walls[@]} ))
                break
            fi
        done
    fi
    apply_wall "${walls[$idx]}"
}

random_wall() {
    local prefer_live="false"
    $LIVE && prefer_live="true"
    mapfile -t walls < <(collect_walls "$prefer_live")
    [[ ${#walls[@]} -gt 0 ]] || { echo "error: no wallpapers found in $WALL_DIR" >&2; exit 1; }
    local n=$((RANDOM % ${#walls[@]}))
    apply_wall "${walls[$n]}"
}

status() {
    if [[ -f "$STATE_FILE" ]]; then
        echo "last wallpaper: $(cat "$STATE_FILE")"
    else
        echo "last wallpaper: (none recorded)"
    fi
    if pgrep -u "$USER" -x mpvpaper >/dev/null 2>&1; then
        echo "live engine: mpvpaper running"
    elif pgrep -u "$USER" -x awww-daemon >/dev/null 2>&1; then
        echo "static engine: awww-daemon running"
        awww query 2>/dev/null || true
    elif pgrep -u "$USER" -x hyprpaper >/dev/null 2>&1; then
        echo "static engine: hyprpaper running (legacy — switch to awww)"
    else
        echo "engine: none detected"
    fi
    echo "collection: $WALL_DIR"
}

# arg parse
ACTION="list"
SET_ARG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --list|-l)    ACTION="list" ;;
        --next|-n)    ACTION="next" ;;
        --random|-r)  ACTION="random" ;;
        --status|-s)  ACTION="status" ;;
        --live)       LIVE=true ;;
        --set)
            [[ $# -lt 2 ]] && usage
            ACTION="set"
            SET_ARG="$2"
            shift
            ;;
        -h|--help) usage ;;
        *)
            # bare path/name
            ACTION="set"
            SET_ARG="$1"
            ;;
    esac
    shift
done

[[ -d "$WALL_DIR" ]] || { echo "error: wallpaper dir missing: $WALL_DIR" >&2; exit 1; }

case "$ACTION" in
    list)   list_walls ;;
    next)   next_wall ;;
    random) random_wall ;;
    status) status ;;
    set)
        resolved="$(resolve_set_arg "$SET_ARG")" || {
            echo "error: no wallpaper matching '$SET_ARG'" >&2
            exit 1
        }
        apply_wall "$resolved"
        ;;
esac
