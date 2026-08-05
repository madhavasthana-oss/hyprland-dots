#!/usr/bin/env bash
# Caps lock indicator — Monoshell hyprlock

MAIN_KB_CAPS=$(hyprctl devices 2>/dev/null \
    | grep -B 6 "main: yes" \
    | grep "capsLock" \
    | head -1 \
    | awk '{print $2}')

if [[ "$MAIN_KB_CAPS" == "yes" ]]; then
    echo "⚠  CAPS LOCK"
else
    echo ""
fi
