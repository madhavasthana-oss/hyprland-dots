#!/usr/bin/env bash
# ─────────────────────────────────────────
#  ASH COLOR PALETTE — source this file
#  Soft monochrome greys for terminal scripts
#  Usage: source "$(dirname "$0")/colors.sh"
# ─────────────────────────────────────────

# Reset
RESET='\033[0m'

# Grey family (Ash monochrome)
GREY_HOT='\033[38;5;252m'    # Near-white  — banners, highlights  (~#E5E5E5)
GREY_MID='\033[38;5;248m'    # Soft silver — values, prompts      (~#C8C8C8)
GREY_DIM='\033[38;5;245m'    # Medium grey — separators, labels   (~#A3A3A3)
GREY_MUTED='\033[38;5;240m'  # Muted       — secondary text       (~#6B6B6B)
GREY_ASH='\033[38;5;236m'    # Deep ash    — background text      (~#333333)
GREY_VOID='\033[38;5;233m'   # Near black  — deepest              (~#121212)

# Legacy aliases (scripts that still use RED_*)
RED_HOT="$GREY_HOT"
RED_MID="$GREY_MID"
RED_DIM="$GREY_DIM"
RED_BLOOD="$GREY_MUTED"
RED_EMBER="$GREY_DIM"
RED_ASH="$GREY_ASH"
ORANGE_DARK="$GREY_MID"
ORANGE_DIM="$GREY_MUTED"

# Text modifiers
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

# Utility
SEP="${GREY_ASH}───────────────────────────────────────────────────────${RESET}"
ARROW="${GREY_DIM}▸${RESET}"
PROMPT_CHAR="${GREY_HOT}❯${RESET}"
