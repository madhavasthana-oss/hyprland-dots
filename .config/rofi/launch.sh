#!/usr/bin/env bash
# DEPRECATED: rofi was replaced by fuzzel.
# Forwards to ~/.config/fuzzel/launch.sh so old Super+A / scripts keep working.
set -euo pipefail

# Old usage: launch.sh [drun|run|window|emoji]
# fuzzel is always app-launcher unless --dmenu; emoji has its own script.
MODE="${1:-drun}"
FUZZEL_LAUNCH="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel/launch.sh"

case "$MODE" in
	emoji)
		exec "$HOME/.config/hypr/hyprland/scripts/fuzzel-emoji.sh" both
		;;
	drun|run|window|"")
		exec "$FUZZEL_LAUNCH"
		;;
	*)
		# Unknown mode: still open app launcher
		exec "$FUZZEL_LAUNCH"
		;;
esac
