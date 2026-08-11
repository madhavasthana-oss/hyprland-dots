#!/usr/bin/env bash
# Compatibility shim — real script lives in astral-vagabond/utils/scripts/
ROOT="${HYPRLAND_DOTS:-$HOME/hyprland-dots}"
for candidate in \
    "${ROOT}/.config/quickshell/astral-vagabond/utils/scripts/gpu-info.sh" \
    "${HOME}/.config/quickshell/astral-vagabond/utils/scripts/gpu-info.sh"
do
    if [[ -x "$candidate" ]]; then
        exec "$candidate" "$@"
    fi
done
echo "error: astral-vagabond gpu-info.sh not found" >&2
exit 1
