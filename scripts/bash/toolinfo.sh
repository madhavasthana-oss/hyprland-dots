#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Usage:
  toolinfo <package>
  toolinfo <package> -o <file>

Examples:
  toolinfo ags
  toolinfo waybar -o waybar.json
EOF
    exit 1
}

[[ $# -lt 1 ]] && usage

TARGET="$1"
OUTPUT=""

shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            [[ $# -lt 2 ]] && usage
            OUTPUT="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

json_escape() {
    sed 's/\\/\\\\/g; s/"/\\"/g'
}

get_version() {
    if command -v "$TARGET" >/dev/null 2>&1; then
        "$TARGET" --version 2>/dev/null \
        || "$TARGET" -V 2>/dev/null \
        || "$TARGET" version 2>/dev/null \
        || true
    fi
}

BIN_PATH="$(command -v "$TARGET" 2>/dev/null || true)"
VERSION="$(get_version | head -n1 | json_escape)"

PACKAGE_INFO="$(pacman -Qi "$TARGET" 2>/dev/null || true)"

PACKAGE_VERSION="$(printf '%s\n' "$PACKAGE_INFO" \
    | awk -F':' '/^Version/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')"

DESCRIPTION="$(printf '%s\n' "$PACKAGE_INFO" \
    | awk -F':' '/^Description/ {gsub(/^[ \t]+/,"",$2); print $2; exit}' \
    | json_escape)"

FILES_JSON="[]"

if pacman -Ql "$TARGET" >/dev/null 2>&1; then
    FILES_JSON="$(
        pacman -Ql "$TARGET" \
        | awk '{print $2}' \
        | sed 's/\\/\\\\/g; s/"/\\"/g' \
        | awk '
            BEGIN { printf "[" }
            {
                if (NR > 1) printf ","
                printf "\"" $0 "\""
            }
            END { printf "]" }
        '
    )"
fi

CONFIG_JSON="$(
{
    [[ -e "$HOME/.config/$TARGET" ]] && echo "$HOME/.config/$TARGET"
    [[ -e "/etc/$TARGET" ]] && echo "/etc/$TARGET"
    [[ -e "/usr/share/$TARGET" ]] && echo "/usr/share/$TARGET"
} | sed 's/\\/\\\\/g; s/"/\\"/g' \
  | awk '
        BEGIN { printf "[" }
        {
            if (NR > 1) printf ","
            printf "\"" $0 "\""
        }
        END { printf "]" }
    '
)"

PROCESS_JSON="$(
pgrep -af "$TARGET" 2>/dev/null \
| sed 's/\\/\\\\/g; s/"/\\"/g' \
| awk '
    BEGIN { printf "[" }
    {
        if (NR > 1) printf ","
        printf "\"" $0 "\""
    }
    END { printf "]" }
'
)"

JSON="$(
cat <<EOF
{
  "name": "$TARGET",
  "binary": "${BIN_PATH}",
  "version": "${VERSION}",
  "package_version": "${PACKAGE_VERSION}",
  "description": "${DESCRIPTION}",
  "config_dirs": ${CONFIG_JSON},
  "running_processes": ${PROCESS_JSON},
  "installed_files": ${FILES_JSON}
}
EOF
)"

if [[ -n "$OUTPUT" ]]; then
    printf '%s\n' "$JSON" > "$OUTPUT"
    echo "Saved to: $OUTPUT"
else
    printf '%s\n' "$JSON"
fi
