#!/usr/bin/env bash
# Compatibility shim — real script lives in astral-vagabond/utils/scripts/
# Prefer dots tree when testing; fall back to live config path.
ROOT="${HYPRLAND_DOTS:-$HOME/hyprland-dots}"
for candidate in \
    "${ROOT}/.config/quickshell/astral-vagabond/utils/scripts/cava-overlay.sh" \
    "${HOME}/.config/quickshell/astral-vagabond/utils/scripts/cava-overlay.sh"
do
    if [[ -x "$candidate" ]]; then
        exec "$candidate" "$@"
    fi
done
echo "error: astral-vagabond cava-overlay.sh not found" >&2
exit 1
