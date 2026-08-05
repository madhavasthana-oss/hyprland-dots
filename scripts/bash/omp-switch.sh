#!/usr/bin/env bash
# doom-omp-switch — switch Doomslayer oh-my-posh themes
# Usage:
#   ./doom-omp-switch                  # list themes
#   ./doom-omp-switch --list
#   ./doom-omp-switch --next           # cycle to next theme
#   ./doom-omp-switch --set pill
#   ./doom-omp-switch --set ribbon
#   ./doom-omp-switch --set info-util
#   ./doom-omp-switch --status

set -euo pipefail

# Resolve symlinks so ~/.local/bin/doom-omp-switch still finds the mod root
_src="${BASH_SOURCE[0]}"
while [[ -L "$_src" ]]; do
    _dir="$(cd -P "$(dirname "$_src")" && pwd)"
    _src="$(readlink "$_src")"
    [[ "$_src" != /* ]] && _src="$_dir/$_src"
done
SCRIPT_DIR="$(cd -P "$(dirname "$_src")" && pwd)"
MOD_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OMP_DIR="${MOD_ROOT}/config/CLI-HUD/oh-my-posh"
PROMPT_ZSH="${MOD_ROOT}/config/CLI-HUD/zsh/prompt.zsh"

# name → filename (without path)
declare -A THEMES=(
    [info-util]="doomslayer-info-util.omp.json"
    [pill]="doomslayer-pill.omp.json"
    [ribbon]="doomslayer-ribbon.omp.json"
)
ORDER=(info-util pill ribbon)

usage() {
    cat <<EOF
Usage: $0 [--list|--status|--next|--set <name>]

Switch the active oh-my-posh theme used by Doomslayer-mod/config/CLI-HUD/zsh/prompt.zsh.

Themes (from Doomslayer-mod):
  info-util   doomslayer-info-util.omp.json
  pill        doomslayer-pill.omp.json
  ribbon      doomslayer-ribbon.omp.json

  --list              List available themes
  --status            Show the currently selected theme
  --next              Cycle to the next theme
  --set <name>        Set a specific theme by short name
  -h, --help          This help

Open a new shell (or re-source prompt.zsh) after switching.
EOF
    exit 0
}

theme_path() {
    local name="$1"
    local file="${THEMES[$name]:-}"
    [[ -n "$file" ]] || return 1
    echo "${OMP_DIR}/${file}"
}

current_theme() {
    [[ -f "$PROMPT_ZSH" ]] || { echo "unknown"; return; }
    local line
    line="$(grep -E 'oh-my-posh init zsh --config' "$PROMPT_ZSH" | head -1 || true)"
    [[ -n "$line" ]] || { echo "none"; return; }
    local base
    base="$(basename "$(echo "$line" | sed -n 's/.*--config[[:space:]]*\([^"'"'"')]*\).*/\1/p' | tr -d '"' | tr -d "'")")"
    for name in "${ORDER[@]}"; do
        if [[ "$base" == "${THEMES[$name]}" ]]; then
            echo "$name"
            return
        fi
    done
    echo "custom:$base"
}

list_themes() {
    local cur
    cur="$(current_theme)"
    echo "Available oh-my-posh themes:"
    for name in "${ORDER[@]}"; do
        local mark=" "
        [[ "$name" == "$cur" ]] && mark="*"
        local path
        path="$(theme_path "$name")"
        if [[ -f "$path" ]]; then
            echo "  ${mark} ${name}  →  $(basename "$path")"
        else
            echo "  ${mark} ${name}  →  MISSING: $path"
        fi
    done
    echo ""
    echo "Active: $cur"
    echo "Prompt: $PROMPT_ZSH"
}

set_theme() {
    local name="${1,,}"
    name="${name//_/-}"
    # allow aliases
    case "$name" in
        info|info-util|infoutil|util) name="info-util" ;;
        pill|pills) name="pill" ;;
        ribbon|ribbons) name="ribbon" ;;
    esac

    if [[ -z "${THEMES[$name]+x}" ]]; then
        echo "error: unknown theme '$1' (use: ${ORDER[*]})" >&2
        exit 1
    fi

    local path
    path="$(theme_path "$name")"
    if [[ ! -f "$path" ]]; then
        echo "error: theme file missing: $path" >&2
        exit 1
    fi

    if [[ ! -f "$PROMPT_ZSH" ]]; then
        echo "error: prompt file not found: $PROMPT_ZSH" >&2
        exit 1
    fi

    local cur
    cur="$(current_theme)"
    if [[ "$cur" == "$name" ]]; then
        echo "Already using theme: $name"
        exit 0
    fi

    local bak="${PROMPT_ZSH}.bak.omp-switch"
    [[ -f "$bak" ]] || cp -a "$PROMPT_ZSH" "$bak"

    # Prefer home-relative path for portability
    local config_ref="${path/#$HOME/\$HOME}"
    # If path is under MOD_ROOT and home contains Doomslayer-mod, use ~/ form
    if [[ "$path" == "$HOME/"* ]]; then
        config_ref="~/${path#"$HOME/"}"
    fi

    if grep -qE 'oh-my-posh init zsh --config' "$PROMPT_ZSH"; then
        sed -i -E "s|(oh-my-posh init zsh --config[[:space:]]+)[^\"')]+|\\1${config_ref}|" "$PROMPT_ZSH"
    else
        # Insert eval line near the top after any comment header
        {
            echo "# Add you own custom prompt here"
            echo ""
            echo "eval \"\$(oh-my-posh init zsh --config ${config_ref})\""
            echo ""
            cat "$PROMPT_ZSH"
        } > "${PROMPT_ZSH}.tmp" && mv "${PROMPT_ZSH}.tmp" "$PROMPT_ZSH"
    fi

    echo "oh-my-posh theme → $name"
    echo "  File:   $path"
    echo "  Prompt: $PROMPT_ZSH"
    echo "Open a new shell or run: source $PROMPT_ZSH"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Doomslayer" "Prompt theme" "oh-my-posh → $name" 2>/dev/null || true
    fi
}

next_theme() {
    local cur i next
    cur="$(current_theme)"
    next="${ORDER[0]}"
    for i in "${!ORDER[@]}"; do
        if [[ "${ORDER[$i]}" == "$cur" ]]; then
            next="${ORDER[$(( (i + 1) % ${#ORDER[@]} ))]}"
            break
        fi
    done
    set_theme "$next"
}

ACTION="list"
TARGET=""
case "${1:-}" in
    ""|--list|-l) ACTION="list" ;;
    --status|-s)  ACTION="status" ;;
    --next|-n)    ACTION="next" ;;
    --set)
        [[ $# -lt 2 ]] && usage
        ACTION="set"
        TARGET="$2"
        ;;
    -h|--help) usage ;;
    *)
        # bare name: treat as --set
        if [[ -n "${THEMES[${1,,}]+x}" ]] || [[ "$1" =~ ^(pill|ribbon|info) ]]; then
            ACTION="set"
            TARGET="$1"
        else
            echo "error: unknown option '$1' (try --help)" >&2
            exit 1
        fi
        ;;
esac

case "$ACTION" in
    list)   list_themes ;;
    status)
        echo "oh-my-posh: $(current_theme)"
        echo "  Prompt: $PROMPT_ZSH"
        echo "  Dir:    $OMP_DIR"
        ;;
    next)   next_theme ;;
    set)    set_theme "$TARGET" ;;
esac
