#!/usr/bin/env bash
# Set doomslayer-rain.conf as the active sddm-astronaut-theme config.
# Usage: set-sddm-doomslayer.sh [--purge-leftovers] [--preview]
set -euo pipefail

RED='\033[0;31m'
BRED='\033[1;31m'
DIM='\033[2m'
RESET='\033[0m'

THEME_NAME="sddm-astronaut-theme"
THEME_DIR="/usr/share/sddm/themes/${THEME_NAME}"
MOD_ROOT="${DOOMSLAYER_MOD:-$HOME/Doomslayer-mod}"
CONF_SRC="${MOD_ROOT}/.config/sddm/doomslayer-rain.conf"
VIDEO_SRC="${MOD_ROOT}/Pictures/Wallpapers/live-wallpapers-1/doom-live-4k.mp4"
FONT_SRC="${MOD_ROOT}/.config/doomshell/assets/fonts/KogniGear.ttf"

PURGE=0
PREVIEW=0
for arg in "$@"; do
  case "$arg" in
    --purge-leftovers) PURGE=1 ;;
    --preview) PREVIEW=1 ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--purge-leftovers] [--preview]"
      echo "  Installs doomslayer-rain as the active astronaut theme config."
      echo "  --purge-leftovers  remove timestamped theme clones (system + home)"
      echo "  --preview          open sddm-greeter test mode after install"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${RESET}" >&2
      exit 1
      ;;
  esac
done

need_root() {
  if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      echo -e "${RED}Need root for: $*${RESET}" >&2
      exit 1
    fi
  else
    "$@"
  fi
}

echo -e "${BRED}==> SDDM doomslayer-rain setup${RESET}"

if [[ ! -d "$THEME_DIR" ]]; then
  echo -e "${RED}ERROR: Active theme not found: $THEME_DIR${RESET}" >&2
  echo "Install sddm-astronaut-theme first, and set Current=${THEME_NAME} in /etc/sddm.conf"
  exit 1
fi
if [[ ! -f "$CONF_SRC" ]]; then
  echo -e "${RED}ERROR: Config not found: $CONF_SRC${RESET}" >&2
  exit 1
fi
if [[ ! -f "$VIDEO_SRC" ]]; then
  echo -e "${RED}ERROR: Video not found: $VIDEO_SRC${RESET}" >&2
  exit 1
fi

# Ensure sddm.conf points at the canonical theme name (not a leftover clone).
if [[ -f /etc/sddm.conf ]]; then
  CURRENT=$(awk -F= '/^[[:space:]]*Current=/{gsub(/[[:space:]]/,"",$2); print $2}' /etc/sddm.conf || true)
  if [[ -n "${CURRENT:-}" && "$CURRENT" != "$THEME_NAME" ]]; then
    echo -e "${DIM}Updating /etc/sddm.conf Current=${THEME_NAME} (was ${CURRENT})${RESET}"
    need_root sed -i "s|^[[:space:]]*Current=.*|Current=${THEME_NAME}|" /etc/sddm.conf
  fi
fi

echo -e "${DIM}Installing Themes/doomslayer-rain.conf${RESET}"
need_root install -m 644 "$CONF_SRC" "$THEME_DIR/Themes/doomslayer-rain.conf"

echo -e "${DIM}Installing Backgrounds/doom-live-4k.mp4${RESET}"
need_root install -m 644 "$VIDEO_SRC" "$THEME_DIR/Backgrounds/doom-live-4k.mp4"

# Prefer theme font, fall back to Doomslayer-mod asset.
if [[ -f "$THEME_DIR/Fonts/KogniGear.ttf" ]]; then
  need_root install -m 644 "$THEME_DIR/Fonts/KogniGear.ttf" /usr/share/fonts/KogniGear.ttf
elif [[ -f "$FONT_SRC" ]]; then
  need_root install -m 644 "$FONT_SRC" /usr/share/fonts/KogniGear.ttf
  need_root install -m 644 "$FONT_SRC" "$THEME_DIR/Fonts/KogniGear.ttf"
fi
need_root fc-cache -f >/dev/null 2>&1 || true

echo -e "${DIM}Setting metadata ConfigFile=Themes/doomslayer-rain.conf${RESET}"
need_root sed -i 's|^ConfigFile=.*|ConfigFile=Themes/doomslayer-rain.conf|' "$THEME_DIR/metadata.desktop"

if [[ "$PURGE" -eq 1 ]]; then
  echo -e "${BRED}==> Purging leftover astronaut theme clones${RESET}"
  # System leftovers: sddm-astronaut-theme_<timestamp>
  shopt -s nullglob
  for d in /usr/share/sddm/themes/${THEME_NAME}_*; do
    echo -e "${DIM}Removing $d${RESET}"
    need_root rm -rf "$d"
  done
  # Home working clones (never loaded by SDDM)
  for d in "$HOME"/${THEME_NAME} "$HOME"/${THEME_NAME}_*; do
    if [[ -d "$d" ]]; then
      echo -e "${DIM}Removing $d${RESET}"
      rm -rf "$d"
    fi
  done
  shopt -u nullglob
fi

echo
echo -e "${BRED}=== Active theme ===${RESET}"
echo "Path:       $THEME_DIR"
grep -E '^(Name|ConfigFile)=' "$THEME_DIR/metadata.desktop" || true
echo -e "${DIM}Background:${RESET} $(grep '^Background=' "$THEME_DIR/Themes/doomslayer-rain.conf" || true)"
ls -lh "$THEME_DIR/Backgrounds/doom-live-4k.mp4" 2>/dev/null || true
echo
echo -e "${DIM}Preview: sddm-greeter-qt6 --test-mode --theme $THEME_DIR${RESET}"
echo -e "${DIM}Or log out / reboot for the real greeter.${RESET}"

if [[ "$PREVIEW" -eq 1 ]]; then
  if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    sddm-greeter-qt6 --test-mode --theme "$THEME_DIR"
  else
    echo -e "${RED}sddm-greeter-qt6 not found; skip preview${RESET}" >&2
  fi
fi
