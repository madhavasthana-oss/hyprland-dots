#!/usr/bin/env bash
# Apply Doomslayer-mod Hypr config --> live ~/.config/hypr
set -euo pipefail

SRC="${HOME}/Doomslayer-mod/.config/hypr"
DST="${HOME}/.config/hypr"

if [[ ! -d "$SRC" ]]; then
	echo "error: source missing: $SRC" >&2
	exit 1
fi

echo "--> syncing (mod --> live)"
echo "    $SRC/"
echo "    ==> $DST/"
mkdir -p "$DST"
rsync -a --delete "$SRC/" "$DST/"

echo "==> synced successfully; reloading Hyprland"
hyprctl reload
echo "==> done"
