#!/usr/bin/env bash
# Fast Intel iGPU stats: usage (%) and frequency (MHz).
# Much lighter than turbostat — sysfs for clock, nvtop snapshot for util.
#
# Usage:
#   gpu-info              # one-shot: "13% @ 600MHz"
#   gpu-info -r           # raw: "13 600"
#   gpu-info -f           # frequency only (sysfs, ~4ms)
#   gpu-info -u           # usage only (nvtop, ~150ms)
#   gpu-info -w [N]       # watch every N seconds (default 1)
#   gpu-info -j           # JSON: {"usage":13,"freq_mhz":600}

set -euo pipefail

CARD="${GPU_CARD:-/sys/class/drm/card1}"
GT="${CARD}/gt/gt0"

usage() {
    sed -n '2,14p' "$0" | sed 's/^# \?//'
    exit 0
}

read_sysfs() {
    # Prefer cat over bash $(<file) so redirections/errors stay predictable.
    cat "$1" 2>/dev/null | tr -d '[:space:]' || true
}

read_freq_mhz() {
    local act cur
    act=$(read_sysfs "${GT}/rps_act_freq_mhz")
    cur=$(read_sysfs "${GT}/rps_cur_freq_mhz")
    # Actual freq is 0 when the GT is parked; fall back to requested/current.
    if [[ -n "${act}" && "$act" != "0" ]]; then
        echo "$act"
    elif [[ -n "${cur}" ]]; then
        echo "$cur"
    else
        # Legacy sysfs paths (some kernels)
        act=$(read_sysfs "${CARD}/gt_act_freq_mhz")
        cur=$(read_sysfs "${CARD}/gt_cur_freq_mhz")
        if [[ -n "${act}" && "$act" != "0" ]]; then
            echo "$act"
        else
            echo "${cur:-0}"
        fi
    fi
}

read_usage_pct() {
    if ! command -v nvtop >/dev/null 2>&1; then
        echo "nvtop not found (pacman -S nvtop)" >&2
        return 1
    fi
    # Snapshot JSON is ~100–150ms; no TUI, no root.
    if command -v jq >/dev/null 2>&1; then
        nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // empty' | tr -d '%'
    else
        # Minimal parser if jq is missing
        nvtop -s 2>/dev/null | grep -o '"gpu_util"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '[0-9]\+'
    fi
}

print_once() {
    local mode=$1
    local util freq
    case "$mode" in
        freq)
            freq=$(read_freq_mhz)
            echo "${freq}MHz"
            ;;
        usage)
            util=$(read_usage_pct)
            echo "${util}%"
            ;;
        raw)
            util=$(read_usage_pct)
            freq=$(read_freq_mhz)
            echo "${util} ${freq}"
            ;;
        json)
            util=$(read_usage_pct)
            freq=$(read_freq_mhz)
            printf '{"usage":%s,"freq_mhz":%s}\n' "${util:-null}" "${freq:-null}"
            ;;
        *)
            util=$(read_usage_pct)
            freq=$(read_freq_mhz)
            echo "${util}% @ ${freq}MHz"
            ;;
    esac
}

MODE=human
WATCH=0
INTERVAL=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -f|--freq) MODE=freq; shift ;;
        -u|--usage) MODE=usage; shift ;;
        -r|--raw) MODE=raw; shift ;;
        -j|--json) MODE=json; shift ;;
        -w|--watch)
            WATCH=1
            shift
            if [[ $# -gt 0 && "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                INTERVAL=$1
                shift
            fi
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

if [[ ! -d "$CARD" ]]; then
    echo "No DRM card at $CARD (set GPU_CARD=...)" >&2
    exit 1
fi

if [[ $WATCH -eq 1 ]]; then
    while true; do
        print_once "$MODE"
        sleep "$INTERVAL"
    done
else
    print_once "$MODE"
fi
