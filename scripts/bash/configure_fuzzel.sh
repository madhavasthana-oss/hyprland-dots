#!/usr/bin/env bash
# Apply hyprland-dots fuzzel config --> live ~/.config/fuzzel
set -euo pipefail

MOD_ROOT="${HOME}/hyprland-dots"
SRC="${MOD_ROOT}/.config/fuzzel"
DST="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel"

if [[ ! -d "$SRC" ]]; then
	echo "error: source missing: $SRC" >&2
	exit 1
fi

echo "--> syncing (mod --> live)"
echo "    $SRC/"
echo "    ==> $DST/"
mkdir -p "$DST"
rsync -a --delete "$SRC/" "$DST/"
chmod +x "$DST/launch.sh" 2>/dev/null || true

echo "==> synced successfully"
echo "    try: ~/.config/fuzzel/launch.sh"
echo "    or:  Super+A (appManager)"
echo "    emoji: Super+. (fuzzel-emoji.sh)"
echo "==> done"
