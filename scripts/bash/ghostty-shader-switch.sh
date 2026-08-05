#!/usr/bin/env bash
# ghostty-shader-switch.sh — cycle / set Ghostty cursor shaders
# Usage:
#   ./ghostty-shader-switch.sh              # list
#   ./ghostty-shader-switch.sh --next
#   ./ghostty-shader-switch.sh --set cursor_sweep
#   ./ghostty-shader-switch.sh --off        # comment out custom-shader
#   ./ghostty-shader-switch.sh --status

set -euo pipefail

GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
SHADER_DIR="$GHOSTTY_DIR/shaders"
# Files that commonly hold custom-shader lines
CONFIG_FILES=(
    "$GHOSTTY_DIR/config.ghostty"
    "$GHOSTTY_DIR/console-dropdown.conf"
    "$GHOSTTY_DIR/config"
)

usage() {
    cat <<EOF
Usage: $0 [--list|--status|--next|--off|--set <name>]

Cycle Ghostty custom cursor shaders under ~/.config/ghostty/shaders.

  --list              List available .glsl shaders
  --status            Show the currently selected shader
  --next              Cycle to the next shader
  --set <name>        Set shader by basename (with or without .glsl)
  --off               Disable custom-shader (comment lines out)
  -h, --help          This help

Updates every config file that already contains a custom-shader line.
Ghostty reloads config on its own for many keys; reopen the terminal if not.
EOF
    exit 0
}

notify() {
    local title="$1" body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Doomslayer" "$title" "$body" 2>/dev/null || true
    fi
}

list_shaders() {
    local f
    if [[ ! -d "$SHADER_DIR" ]]; then
        echo "error: shader dir missing: $SHADER_DIR" >&2
        exit 1
    fi
    mapfile -t shaders < <(find "$SHADER_DIR" -maxdepth 1 -type f -name '*.glsl' -printf '%f\n' | sort)
    local cur
    cur="$(current_shader || true)"
    echo "Ghostty cursor shaders ($SHADER_DIR):"
    for f in "${shaders[@]}"; do
        local mark=" "
        [[ "$f" == "$cur" ]] && mark="*"
        echo "  ${mark} ${f%.glsl}"
    done
    echo ""
    echo "Active: ${cur:-none}"
}

current_shader() {
    local file line
    for file in "${CONFIG_FILES[@]}"; do
        [[ -f "$file" ]] || continue
        line="$(grep -E '^[[:space:]]*custom-shader[[:space:]]*=' "$file" | head -1 || true)"
        [[ -n "$line" ]] || continue
        # extract path after =
        local val
        val="$(echo "$line" | sed -E 's/^[[:space:]]*custom-shader[[:space:]]*=[[:space:]]*//')"
        basename "$val"
        return 0
    done
    echo ""
    return 1
}

shader_files() {
    find "$SHADER_DIR" -maxdepth 1 -type f -name '*.glsl' -printf '%f\n' | sort
}

set_shader() {
    local raw="$1"
    local base="${raw%.glsl}"
    local file_name="${base}.glsl"
    local full="$SHADER_DIR/$file_name"

    if [[ ! -f "$full" ]]; then
        echo "error: shader not found: $full" >&2
        echo "Available:" >&2
        shader_files | sed 's/^/  /; s/\.glsl$//' >&2
        exit 1
    fi

    # Relative path as used in existing configs
    local rel="shaders/${file_name}"
    local updated=0
    local file

    for file in "${CONFIG_FILES[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -qE '^[[:space:]]*#?[[:space:]]*custom-shader[[:space:]]*=' "$file"; then
            local bak="${file}.bak.shader-switch"
            [[ -f "$bak" ]] || cp -a "$file" "$bak"
            # Uncomment if needed and set value
            sed -i -E "s|^[[:space:]]*#?[[:space:]]*custom-shader[[:space:]]*=.*|custom-shader = ${rel}|" "$file"
            updated=$((updated + 1))
        fi
    done

    if [[ $updated -eq 0 ]]; then
        # No existing line — append to config.ghostty or config
        local target=""
        for file in "$GHOSTTY_DIR/config.ghostty" "$GHOSTTY_DIR/config"; do
            [[ -f "$file" ]] && { target="$file"; break; }
        done
        if [[ -z "$target" ]]; then
            echo "error: no ghostty config found under $GHOSTTY_DIR" >&2
            exit 1
        fi
        {
            echo ""
            echo "# managed by ghostty-shader-switch.sh"
            echo "custom-shader = ${rel}"
        } >> "$target"
        updated=1
    fi

    echo "Ghostty shader → $base"
    echo "  Path: shaders/${file_name}"
    echo "  Updated $updated config file(s). Reopen Ghostty if needed."
    notify "Ghostty shader" "$base"
}

disable_shader() {
    local file updated=0
    for file in "${CONFIG_FILES[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -qE '^[[:space:]]*custom-shader[[:space:]]*=' "$file"; then
            local bak="${file}.bak.shader-switch"
            [[ -f "$bak" ]] || cp -a "$file" "$bak"
            sed -i -E 's|^([[:space:]]*)custom-shader[[:space:]]*=|# custom-shader =|' "$file"
            # Fix double-comment if sed only partially matched — normalize
            sed -i -E 's|^[[:space:]]*#[[:space:]]*# custom-shader|# custom-shader|' "$file"
            updated=$((updated + 1))
        fi
    done
    echo "Ghostty custom-shader disabled ($updated file(s))."
    notify "Ghostty shader" "disabled"
}

next_shader() {
    mapfile -t shaders < <(shader_files)
    [[ ${#shaders[@]} -gt 0 ]] || { echo "error: no .glsl shaders in $SHADER_DIR" >&2; exit 1; }

    local cur idx=0
    cur="$(current_shader || true)"
    if [[ -n "$cur" ]]; then
        local i
        for i in "${!shaders[@]}"; do
            if [[ "${shaders[$i]}" == "$cur" ]]; then
                idx=$(( (i + 1) % ${#shaders[@]} ))
                break
            fi
        done
    fi
    set_shader "${shaders[$idx]}"
}

ACTION="list"
SET_ARG=""
case "${1:-}" in
    ""|--list|-l) ACTION="list" ;;
    --status|-s)  ACTION="status" ;;
    --next|-n)    ACTION="next" ;;
    --off|--disable) ACTION="off" ;;
    --set)
        [[ $# -lt 2 ]] && usage
        ACTION="set"
        SET_ARG="$2"
        ;;
    -h|--help) usage ;;
    *)
        ACTION="set"
        SET_ARG="$1"
        ;;
esac

case "$ACTION" in
    list)   list_shaders ;;
    status)
        cur="$(current_shader || true)"
        echo "ghostty shader: ${cur:-none (disabled or unset)}"
        echo "  dir: $SHADER_DIR"
        ;;
    next)   next_shader ;;
    set)    set_shader "$SET_ARG" ;;
    off)    disable_shader ;;
esac
