#!/usr/bin/env bash
# Compatibility shim — real script lives in monoshell/utils/scripts/
ROOT="${HYPRLAND_DOTS:-$HOME/hyprland-dots}"
for candidate in \
    "${ROOT}/.config/quickshell/monoshell/utils/scripts/gpu-info.sh" \
    "${HOME}/.config/quickshell/monoshell/utils/scripts/gpu-info.sh"
do
    if [[ -x "$candidate" ]]; then
        exec "$candidate" "$@"
    fi
done
echo "error: monoshell gpu-info.sh not found" >&2
exit 1
