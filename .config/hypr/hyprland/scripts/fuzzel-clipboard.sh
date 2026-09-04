#!/usr/bin/env bash
# Clipboard history via fuzzel (dmenu) + cliphist.
# Bound to Super+V (pick) and Super+Shift+V (wipe + reset index).
set -euo pipefail

# Prefer UTF-8 locale so compose / dmenu text behave (same idea as fuzzel/launch.sh).
if locale -a 2>/dev/null | grep -qiE '^en_IN\.utf-?8$'; then
	export LANG=en_IN.UTF-8
	export LC_CTYPE=en_IN.UTF-8
elif locale -a 2>/dev/null | grep -qiE '^C\.utf-?8$'; then
	export LANG=C.UTF-8
	export LC_CTYPE=C.UTF-8
elif locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
	export LANG=en_US.UTF-8
	export LC_CTYPE=en_US.UTF-8
fi
unset LC_ALL 2>/dev/null || true

cliphist_db() {
	if [[ -n "${CLIPHIST_DB_PATH:-}" ]]; then
		printf '%s\n' "$CLIPHIST_DB_PATH"
		return
	fi
	local from_ver
	from_ver="$(cliphist version 2>&1 | awk -F '\t' '$1 == "db-path" { print $2; exit }')"
	if [[ -n "$from_ver" ]]; then
		printf '%s\n' "$from_ver"
		return
	fi
	printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/db"
}

wipe_reset() {
	# cliphist wipe deletes entries but leaves BoltDB's bucket sequence, so IDs
	# keep growing (1, 2, ... 1064, ...). Removing the db file resets the index
	# so the next store starts at 1 again.
	local db
	db="$(cliphist_db)"
	cliphist wipe >/dev/null 2>&1 || true
	rm -f "$db"
	notify-send -a Hyprland 'Clipboard' 'History wiped (index reset)'
}

pick() {
	local config="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel/fuzzel.ini"
	local fuzzel_args=(--dmenu --mesg CLIP --prompt "󰅌  " --placeholder "search clipboard...")
	if [[ -f "$config" ]]; then
		fuzzel_args+=(--config "$config")
	fi
	local sel
	sel="$(cliphist list | fuzzel "${fuzzel_args[@]}")" || exit 0
	[[ -n "$sel" ]] || exit 0
	cliphist decode <<<"$sel" | wl-copy
}

case "${1:-pick}" in
	wipe | --wipe | -w) wipe_reset ;;
	pick | --pick) pick ;;
	*)
		echo "usage: $0 [pick|wipe]" >&2
		exit 2
		;;
esac
