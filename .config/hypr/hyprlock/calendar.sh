#!/usr/bin/env bash
# Month calendar for hyprlock — pango markup, today highlighted.
#
# NOTE: hyprlock only rewrites <br/> → newline on *static* label text
# (formatString), not on cmd[] output. Use real newlines in cmd output.

set -euo pipefail

/usr/bin/python3 - <<'PY'
import calendar
from datetime import date

d = date.today()
cal = calendar.Calendar(firstweekday=0)  # Monday
weeks = cal.monthdayscalendar(d.year, d.month)

# Ash palette (matches colors.conf)
muted = "#6B6B6B"
secondary = "#A3A3A3"
accent = "#C8C8C8"
today_fg = "#121212"
today_bg = "#C8C8C8"
weekend = "#737373"

lines = []
title = d.strftime("%B %Y").upper()
lines.append(f'<span foreground="{accent}" font_weight="bold">{title}</span>')
lines.append(f'<span foreground="{muted}">Mo Tu We Th Fr Sa Su</span>')

for week in weeks:
    cells = []
    for i, day in enumerate(week):
        if day == 0:
            cells.append("  ")
            continue
        if day == d.day:
            cells.append(
                f'<span foreground="{today_fg}" background="{today_bg}"'
                f' font_weight="bold">{day:2d}</span>'
            )
        else:
            color = weekend if i >= 5 else secondary
            cells.append(f'<span foreground="{color}">{day:2d}</span>')
    lines.append(" ".join(cells))

# Real newlines — required for cmd[] output (see note above)
body = "\n".join(lines)
print(f'<span allow_breaks="true">{body}</span>', end="")
PY
