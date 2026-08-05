#!/usr/bin/env bash
# DEPRECATED: rofi was replaced by fuzzel.
# Forwards to configure_fuzzel.sh so old docs/scripts keep working.
set -euo pipefail

echo "note: rofi is deprecated in Doomslayer-mod; configuring fuzzel instead" >&2
exec "$(dirname "$0")/configure_fuzzel.sh"
