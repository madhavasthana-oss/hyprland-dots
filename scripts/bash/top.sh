#!/usr/bin/env bash
source "$(dirname "$0")/colors.sh"

LOGO_PATH="~/Doomslayer-mod/config/logos/mark-img.png"

# ─── Helpers ──────────────────────────────────────────────────────────────────

print_sep()   { echo -e "$SEP"; }
print_blank() { echo ""; }

draw_logo() {
    kitty +kitten icat \
        --align center \
        "$LOGO_PATH" 2>/dev/null
}

clear_logo() {
    kitty +kitten icat --clear 2>/dev/null
}

# ─── Banner ───────────────────────────────────────────────────────────────────

show_banner() {
    print_sep
    echo -e "${RED_HOT}  W E L C O M E ,   S L A Y E R${RESET}"
    print_sep
    print_blank
}

# ─── System Info ──────────────────────────────────────────────────────────────

show_sysinfo() {
    local kernel host wm cpu ram

    kernel=$(uname -r)
    host=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')
    wm="${XDG_CURRENT_DESKTOP:-Hyprland}"
    cpu=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    ram=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')

    echo -e "${RED_DIM}▸ OS        ${RED_MID}CachyOS Linux${RESET}"
    echo -e "${RED_DIM}▸ KERNEL    ${RED_MID}${kernel}${RESET}"
    echo -e "${RED_DIM}▸ HOST      ${RED_MID}${host}${RESET}"
    echo -e "${RED_DIM}▸ WM        ${RED_MID}${wm}${RESET}"
    echo -e "${RED_DIM}▸ TERMINAL  ${RED_MID}kitty 0.47.1${RESET}"
    echo -e "${RED_DIM}▸ CPU       ${RED_MID}${cpu}${RESET}"
    echo -e "${RED_DIM}▸ RAM       ${RED_MID}${ram}${RESET}"
    print_blank
    print_sep
    print_blank
}

# ─── Top launcher ─────────────────────────────────────────────────────────────

launch_top() {
    echo -e "${RED_DIM}[ launching monitor — standing by ]${RESET}"
    sleep 0.4
    clear_logo          # wipe the icat render
    sleep 0.3           # let kitty fully flush the clear before top grabs the screen
    top </dev/tty >/dev/tty 2>&1   # force top onto the real TTY
    # ── top exits here; restore the environment ──
    clear
    draw_logo
    print_blank
    echo -e "${RED_DIM}[$(date '+%m/%d/%Y @ %I:%M:%S %p %Z')]${RESET}"
    echo -e "${RED_MID}~/HyDE/Scripts ${PROMPT_CHAR} ${RESET}"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

clear
show_banner
draw_logo
print_blank
show_sysinfo
sleep 0.6
launch_top
