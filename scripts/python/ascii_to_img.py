#!/usr/bin/env python3
"""
ascii_to_img.py — Render ASCII art text as a PNG image.

Usage:
    python ascii_to_img.py input.txt [options]

Examples:
    python ascii_to_img.py art.txt
    python ascii_to_img.py art.txt --fg "#00FF00" --bg transparent
    python ascii_to_img.py art.txt --fg "#FF2222" --bg "#000000" --size 18 --padding 20
    python ascii_to_img.py art.txt --bg-image photo.png
"""

import argparse
import sys
from pathlib import Path
from typing import Optional, Tuple

from PIL import Image, ImageDraw, ImageFont

DEFAULT_FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
DEFAULT_FG = "#FF2222"


def parse_color(value: str) -> Optional[Tuple[int, int, int, int]]:
    """Parse a color string into an RGBA tuple. Returns None for 'transparent'/'none'."""
    v = value.strip().lower()
    if v in ("transparent", "none"):
        return None
    v = value.strip()
    if v.startswith("#"):
        hex_str = v[1:]
        if len(hex_str) == 6:
            r, g, b = (int(hex_str[i:i + 2], 16) for i in (0, 2, 4))
            return (r, g, b, 255)
        if len(hex_str) == 8:
            r, g, b, a = (int(hex_str[i:i + 2], 16) for i in (0, 2, 4, 6))
            return (r, g, b, a)
        raise ValueError(f"Invalid hex color: {value}")
    # Named colors (PIL understands these directly).
    from PIL import ImageColor
    r, g, b = ImageColor.getrgb(v)
    return (r, g, b, 255)


def measure_cell(font: ImageFont.FreeTypeFont) -> Tuple[float, float]:
    """Return (char_width, line_height) for a monospace font using real metrics."""
    char_width = font.getlength("M")
    ascent, descent = font.getmetrics()
    line_height = ascent + descent
    return char_width, line_height


def ascii_to_image(
    art: str,
    font_path: str = DEFAULT_FONT,
    font_size: int = 14,
    fg=(255, 34, 34, 255),
    bg=(0, 0, 0, 0),
    padding: int = 12,
    line_spacing: float = 1.0,
    bg_image_path: Optional[str] = None,
) -> Image.Image:
    # Normalize tabs and drop a trailing blank line some editors add.
    lines = art.replace("\t", "    ").splitlines()
    while lines and lines[-1] == "":
        lines.pop()
    if not lines:
        raise ValueError("input contains no text")

    font = ImageFont.truetype(font_path, font_size)
    char_width, base_line_height = measure_cell(font)
    line_height = base_line_height * line_spacing

    max_line_len = max(len(line) for line in lines)
    content_w = char_width * max_line_len
    content_h = line_height * len(lines)

    img_width = int(round(content_w)) + padding * 2
    img_height = int(round(content_h)) + padding * 2

    if bg_image_path:
        base = Image.open(bg_image_path).convert("RGBA")
        base = base.resize((img_width, img_height), Image.LANCZOS)
        img = base
    else:
        img = Image.new("RGBA", (img_width, img_height), bg if bg is not None else (0, 0, 0, 0))

    draw = ImageDraw.Draw(img)
    for i, line in enumerate(lines):
        y = padding + i * line_height
        draw.text((padding, y), line, font=font, fill=fg)

    return img


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Render an ASCII art text file as a PNG image.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("input", help="Path to ASCII art text file")
    p.add_argument("--output", "-o", default=None,
                    help="Output PNG path (default: <input-stem>.png)")
    p.add_argument("--font", default=DEFAULT_FONT, help="Path to a monospace .ttf font")
    p.add_argument("--size", type=int, default=14, help="Font size in points")
    p.add_argument("--fg", default=DEFAULT_FG,
                    help="Foreground color: hex (#RRGGBB or #RRGGBBAA) or named color")
    p.add_argument("--bg", default="transparent",
                    help="Background color: hex, named color, or 'transparent'")
    p.add_argument("--bg-image", default=None,
                    help="Path to an image to use as the background (stretched to fit)")
    p.add_argument("--padding", type=int, default=12, help="Padding in pixels around the text")
    p.add_argument("--line-spacing", type=float, default=1.0,
                    help="Line height multiplier (1.0 = font's natural spacing)")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    src = Path(args.input)
    if not src.exists():
        print(f"[error] File not found: {src}", file=sys.stderr)
        sys.exit(1)

    if args.bg_image and not Path(args.bg_image).exists():
        print(f"[error] Background image not found: {args.bg_image}", file=sys.stderr)
        sys.exit(1)

    try:
        fg = parse_color(args.fg)
        if fg is None:
            print("[error] --fg cannot be transparent", file=sys.stderr)
            sys.exit(1)
        bg = parse_color(args.bg)
    except ValueError as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)

    stem = src.stem
    if stem.endswith(".ascii"):
        stem = stem[: -len(".ascii")]
    out = Path(args.output) if args.output else src.with_name(f"{stem}.png")

    art = src.read_text(encoding="utf-8")

    try:
        img = ascii_to_image(
            art,
            font_path=args.font,
            font_size=args.size,
            fg=fg,
            bg=bg,
            padding=args.padding,
            line_spacing=args.line_spacing,
            bg_image_path=args.bg_image,
        )
    except Exception as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)

    img.save(out)

    w, h = img.size
    print(f"Saved → {out}", file=sys.stderr)
    print(f"Image size: {w}x{h}, aspect ratio: {w / h:.3f}")


if __name__ == "__main__":
    main()
