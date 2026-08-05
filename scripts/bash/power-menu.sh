#!/usr/bin/env bash
RED='\033[0;31m'
DRED='\033[2;31m'
BRED='\033[1;31m'
DIM='\033[2m'
RESET='\033[0m'

clear
echo -e "${DRED}───────────────────────────────────────────────────────${RESET}"
echo -e "${BRED}  W E L C O M E ,   S L A Y E R${RESET}"
echo -e "${DRED}───────────────────────────────────────────────────────${RESET}"
echo ""
sleep 0.4
echo -e "${DRED}▸ OS        ${RED}CachyOS Linux${RESET}"
echo -e "${DRED}▸ KERNEL    ${RED}$(uname -r)${RESET}"
echo -e "${DRED}▸ HOST      ${RED}$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')${RESET}"
echo -e "${DRED}▸ WM        ${RED}${XDG_CURRENT_DESKTOP:-Hyprland}${RESET}"
echo -e "${DRED}▸ TERMINAL  ${RED}kitty 0.47.1${RESET}"
echo -e "${DRED}▸ CPU       ${RED}$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)${RESET}"
echo -e "${DRED}▸ RAM       ${RED}$(free -h | awk '/^Mem:/ {print $3 " / " $2}')${RESET}"
echo ""
echo -e "${DRED}───────────────────────────────────────────────────────${RESET}"
echo ""
sleep 0.3
kitty +kitten icat \
    --align center \
    ~/Doomslayer-mod/config/logos/mark-img.png 2>/dev/null
echo ""
echo -e "${DRED}[$(date '+%m/%d/%Y @ %I:%M:%S %p %Z')]${RESET}"
echo ""
echo -e "${DRED}───────────────────────────────────────────────────────${RESET}"
echo -e "${DRED}  P O W E R   M E N U${RESET}"
echo -e "${DRED}───────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "${DRED}  [1]${RED}  Sleep${RESET}"
echo -e "${DRED}  [2]${RED}  Reboot${RESET}"
echo -e "${DRED}  [3]${RED}  Logout${RESET}"
echo -e "${DRED}  [4]${RED}  Shutdown${RESET}"
echo -e "${DRED}  [0]${RED}  Exit${RESET}"
echo ""
echo -e "${DRED}───────────────────────────────────────────────────────${RESET}"
echo ""
printf "${RED}𒉭𒉭𒉭 ❯> ${RESET}"
read -r choice

case $choice in
    1) systemctl suspend ;;
    2) systemctl reboot ;;
    3) hyprctl dispatch exit ;;
    4) systemctl poweroff ;;
    0) exit 0 exit ;;
    *) echo -e "${BRED}Invalid choice. Exiting.${RESET}"; sleep 1; exit 1 ;;
esac