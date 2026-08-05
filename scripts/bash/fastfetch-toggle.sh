#!/usr/bin/env bash
# fastfetch-toggle.sh — disable fastfetch globally (HyDE-aware)
# Usage:
#   ./fastfetch-toggle.sh          # disable
#   ./fastfetch-toggle.sh --enable # re-enable

set -euo pipefail

ENABLE=false
[[ "${1:-}" == "--enable" ]] && ENABLE=true
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && {
    echo "Usage: $0 [--enable]"
    exit 0
}

HOME="${HOME:-$(eval echo ~"$USER")}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
FLAG_FILE="$CONFIG_DIR/fastfetch/.disabled"
STUB="$LOCAL_BIN/fastfetch"
REAL_FASTFETCH="/usr/bin/fastfetch"
USER_ZSH="$CONFIG_DIR/zsh/user.zsh"
ENV_D="$CONFIG_DIR/environment.d/fastfetch-toggle.conf"
MARKER_BEGIN="# >>> fastfetch-toggle >>>"
MARKER_END="# <<< fastfetch-toggle <<<"

backup() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    local bak="${file}.bak.fastfetch-toggle"
    [[ -f "$bak" ]] || cp -a "$file" "$bak"
}

patch_user_zsh() {
    [[ -f "$USER_ZSH" ]] || return 0
    backup "$USER_ZSH"

    if grep -qF "$MARKER_BEGIN" "$USER_ZSH"; then
        return 0
    fi

    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
        /elif command -v fastfetch/ { print begin; print "    # fastfetch disabled globally"; print "    :"; print end; skip=1; next }
        skip && /fi/ { skip=0; next }
        skip { next }
        { print }
    ' "$USER_ZSH" > "${USER_ZSH}.tmp" && mv "${USER_ZSH}.tmp" "$USER_ZSH"
}

unpatch_user_zsh() {
    [[ -f "$USER_ZSH" ]] || return 0

    # Always restore the pre-disable backup so the original fastfetch block
    # comes back. Stripping markers alone only removes the noop placeholder.
    if [[ -f "${USER_ZSH}.bak.fastfetch-toggle" ]]; then
        cp -a "${USER_ZSH}.bak.fastfetch-toggle" "$USER_ZSH"
        return 0
    fi

    if grep -qF "$MARKER_BEGIN" "$USER_ZSH"; then
        awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
            $0 ~ begin { skip=1; next }
            $0 ~ end   { skip=0; next }
            skip { next }
            { print }
        ' "$USER_ZSH" > "${USER_ZSH}.tmp" && mv "${USER_ZSH}.tmp" "$USER_ZSH"
    fi
}

install_stub() {
    mkdir -p "$LOCAL_BIN" "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"

    cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
# fastfetch stub — installed by fastfetch-toggle.sh
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/.disabled" ]]; then
    exit 0
fi
exec /usr/bin/fastfetch "$@"
EOF
    chmod +x "$STUB"
}

remove_stub() {
    rm -f "$FLAG_FILE" "$STUB"
    rmdir "$CONFIG_DIR/fastfetch" 2>/dev/null || true
}

install_env() {
    mkdir -p "$(dirname "$ENV_D")"
    echo "DISABLE_FASTFETCH=1" > "$ENV_D"
}

remove_env() {
    rm -f "$ENV_D"
}

disable() {
    install_stub
    patch_user_zsh
    install_env
    echo "fastfetch disabled."
    echo "  Flag:  $FLAG_FILE"
    echo "  Stub:  $STUB  (shadows /usr/bin/fastfetch via ~/.local/bin)"
    echo "  Env:   $ENV_D"
    echo "Open a new terminal to apply."
}

enable() {
    remove_stub
    unpatch_user_zsh
    remove_env
    echo "fastfetch re-enabled. Open a new terminal to apply."
}

if $ENABLE; then
    enable
else
    disable
fi