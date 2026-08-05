#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
#  HYDE SECURITY AUDIT
#  Checks every file touched this session against:
#  1. pacman ownership (distro/package managed)
#  2. HyDE git tracking (HyDE managed)
#  3. Whether it existed before or is new
# ─────────────────────────────────────────────────────

RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
DIM='\033[2;37m'
RESET='\033[0m'

HYDE_DIR="$HOME/HyDE"

# ── Files touched this session ────────────────────────
declare -A FILES
FILES["$HOME/.config/zsh/user.zsh"]="edited line 12 — fastfetch alias"
FILES["$HOME/.config/fastfetch/config.jsonc"]="changed logo type + source"
FILES["$HOME/Pictures/logos/mark.txt"]="replaced with ANSI ascii art"
FILES["$HOME/HyDE/Scripts/welcome.sh"]="NEW file — created by us"
FILES["$HOME/HyDE/Scripts/colors.sh"]="NEW file — created by us"

echo ""
echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
echo -e "${RED}  HYDE SECURITY AUDIT${RESET}"
echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
echo ""

for FILE in "${!FILES[@]}"; do
    REASON="${FILES[$FILE]}"
    echo -e "${YLW}▸ $FILE${RESET}"
    echo -e "  ${DIM}reason : $REASON${RESET}"

    # ── 1. Does the file exist? ───────────────────────
    if [ ! -f "$FILE" ]; then
        echo -e "  ${DIM}status : file does not exist on disk (never created or wrong path)${RESET}"
        echo ""
        continue
    fi

    # ── 2. Pacman ownership check ─────────────────────
    PACMAN_OWNER=$(pacman -Qo "$FILE" 2>&1)
    if echo "$PACMAN_OWNER" | grep -q "No package owns"; then
        echo -e "  ${GRN}pacman : NOT owned by any package ✓${RESET}"
    else
        PKG=$(echo "$PACMAN_OWNER" | awk '{print $(NF-1), $NF}')
        echo -e "  ${RED}pacman : OWNED BY PACKAGE → $PKG ⚠${RESET}"
    fi

    # ── 3. HyDE git tracking check ───────────────────
    if [ -d "$HYDE_DIR/.git" ]; then
        REL_PATH="${FILE/#$HOME\//}"  # strip $HOME/ prefix for git
        GIT_STATUS=$(git -C "$HYDE_DIR" ls-files --error-unmatch "$REL_PATH" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo -e "  ${RED}hyde   : TRACKED BY HYDE GIT ⚠ — changes will conflict on HyDE update${RESET}"
            # Show what changed vs git HEAD
            DIFF=$(git -C "$HYDE_DIR" diff HEAD -- "$REL_PATH" 2>/dev/null | head -20)
            if [ -n "$DIFF" ]; then
                echo -e "  ${DIM}diff vs HEAD:${RESET}"
                echo "$DIFF" | sed 's/^/    /'
            fi
        else
            echo -e "  ${GRN}hyde   : NOT tracked by HyDE git ✓${RESET}"
        fi
    else
        echo -e "  ${DIM}hyde   : HyDE dir not found at $HYDE_DIR — skipping git check${RESET}"
    fi

    # ── 4. HyDE restore script awareness ─────────────
    BASENAME=$(basename "$FILE")
    HYDE_REF=$(grep -rl "$BASENAME" "$HYDE_DIR" 2>/dev/null | grep -v ".git" | head -3)
    if [ -n "$HYDE_REF" ]; then
        echo -e "  ${YLW}hyde   : filename referenced in HyDE scripts:${RESET}"
        echo "$HYDE_REF" | sed 's/^/    /'
    else
        echo -e "  ${GRN}hyde   : filename not referenced in any HyDE script ✓${RESET}"
    fi

    echo ""
done

echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
echo -e "${DIM}  ⚠  = investigate before next HyDE update${RESET}"
echo -e "${DIM}  ✓  = safe, yours to own${RESET}"
echo -e "${DIM}────────────────────────────────────────────────────${RESET}"
echo ""
