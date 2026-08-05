#!/usr/bin/env bash
# Doomslayer fuzzel launcher --- fix locale for xkb compose, then launch.
# LANG=en_IN (non-UTF-8) maps to en_IN.ISO8859-1 which has no Compose file.
# Args are forwarded to fuzzel (e.g. none = app launcher / drun).
set -euo pipefail

# Prefer system India UTF-8, then C.UTF-8. Leave other LC_* alone if set.
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

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel/fuzzel.ini"
exec fuzzel --config "$CONFIG" "$@"
