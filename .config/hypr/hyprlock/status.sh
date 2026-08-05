#!/usr/bin/env bash
# Compact status for the right island (battery only when present)

capacity=""
charging=false

for battery in /sys/class/power_supply/*BAT*; do
    if [[ -f "$battery/uevent" ]]; then
        capacity=$(cat /sys/class/power_supply/*/capacity 2>/dev/null | head -1)
        if [[ $(cat /sys/class/power_supply/*/status 2>/dev/null | head -1) == "Charging" ]]; then
            charging=true
        fi
        break
    fi
done

if [[ -n "$capacity" ]]; then
    if [[ $charging == true ]]; then
        echo "⚡ ${capacity}%"
    else
        echo "▮ ${capacity}%"
    fi
else
    # Desktop / no battery — short host tag so the island isn't empty
    echo "◆ $(hostname -s 2>/dev/null || echo hell)"
fi
