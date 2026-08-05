#!/usr/bin/env python3
"""
flatten-logo.py — flatten a transparent PNG onto a solid background color.

Why: chafa (and most terminal image-art tools) treat transparent pixels
as "draw nothing." If your PNG is mostly transparent (like
ultra-nightmare-ascii.png, which is ~99% alpha=0), chafa ends up
rendering blank output because there's no contrast for it to sample.
Flattening bakes the image onto a solid background first, so every
pixel has real color for chafa to work with.

Usage:
    python3 flatten-logo.py INPUT.png OUTPUT.png [HEX_COLOR]

    HEX_COLOR defaults to 0D0000 (Doomshell's bgPrimary / void color).

Examples:
    python3 flatten-logo.py ultra-nightmare-ascii.png ultra-nightmare-ascii-flat.png
    python3 flatten-logo.py logo.png logo-flat.png 000000
    python3 flatten-logo.py logo.png logo-flat.png "#1A0000"
"""

import sys

try:
    from PIL import Image
except ImportError:
    sys.exit(
        "Pillow is required. Install it with:\n"
        "  pip install pillow --break-system-packages\n"
        "or\n"
        "  pip install pillow   (inside a venv)"
    )

DEFAULT_BG = "0D0000"  # Doomshell bgPrimary


def parse_hex_color(s: str) -> tuple[int, int, int]:
    s = s.strip().lstrip("#")
    if len(s) != 6:
        sys.exit(f"Invalid hex color: {s!r} (expected 6 hex digits, e.g. 0D0000)")
    try:
        r = int(s[0:2], 16)
        g = int(s[2:4], 16)
        b = int(s[4:6], 16)
    except ValueError:
        sys.exit(f"Invalid hex color: {s!r}")
    return (r, g, b)


def flatten(input_path: str, output_path: str, bg_hex: str) -> None:
    r, g, b = parse_hex_color(bg_hex)

    im = Image.open(input_path).convert("RGBA")

    # Report transparency stats so you can see whether this was actually
    # the problem before/after.
    alpha = im.getchannel("A")
    hist = alpha.histogram()
    total = im.size[0] * im.size[1]
    fully_transparent = hist[0]
    fully_opaque = hist[255]
    print(f"Input:  {input_path}")
    print(f"  size: {im.size[0]}x{im.size[1]}  ({total} px)")
    print(f"  fully transparent px: {fully_transparent} ({100 * fully_transparent / total:.1f}%)")
    print(f"  fully opaque px:      {fully_opaque} ({100 * fully_opaque / total:.1f}%)")

    bg = Image.new("RGBA", im.size, (r, g, b, 255))
    flat = Image.alpha_composite(bg, im).convert("RGB")
    flat.save(output_path)

    print(f"Output: {output_path}")
    print(f"  flattened onto #{bg_hex.lstrip('#').upper()}")


def main() -> None:
    args = sys.argv[1:]
    if len(args) not in (2, 3):
        print(__doc__)
        sys.exit(1)

    input_path, output_path = args[0], args[1]
    bg_hex = args[2] if len(args) == 3 else DEFAULT_BG

    flatten(input_path, output_path, bg_hex)


if __name__ == "__main__":
    main()
