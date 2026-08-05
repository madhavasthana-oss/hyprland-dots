#!/usr/bin/env python3
"""
img_to_ascii.py — Convert an image to ASCII art (grayscale, high quality).

Usage:
    python img_to_ascii.py <image_path> [options]

Examples:
    python img_to_ascii.py photo.jpg
    python img_to_ascii.py photo.jpg --width 160 --charset blocks
    python img_to_ascii.py photo.jpg --invert --dither -o out.txt
    python img_to_ascii.py logo.png --width 80 --gamma 0.9 --contrast 1.2
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance

# ── Character sets, ordered dark → light ───────────────────────────────────
CHARSETS = {
    "simple":   " .:-=+*#%@",
    "detailed": " .'`^\",:;Il!i><~+_-?][}{1)(|\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$",
    "blocks":   " ░▒▓█",
    "binary":   " @",
}

# A real monospace terminal cell is about twice as tall as it is wide, so a
# single ASCII "pixel" needs the source image compressed vertically to keep
# the picture from looking stretched. 0.5 matches a typical cell (e.g. 8x16px).
DEFAULT_CHAR_ASPECT = 0.5


def _load_grayscale(path: str) -> tuple:
    """Return (grayscale_image, alpha_or_None). alpha is a mode-'L' mask image
    if the source has transparency, else None."""
    img = Image.open(path)
    alpha = None
    if img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info):
        img = img.convert("RGBA")
        alpha = img.getchannel("A")
        # Flatten onto white for the grayscale/brightness computation so
        # antialiased edges of opaque content don't get an artificial black
        # fringe from a black default background.
        bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
        flat = Image.alpha_composite(bg, img).convert("RGB")
        gray = flat.convert("L")
    else:
        gray = img.convert("L")
    return gray, alpha


def image_to_ascii(
    image_path: str,
    width: int = 100,
    charset: str = "detailed",
    invert: bool = False,
    char_aspect: float = DEFAULT_CHAR_ASPECT,
    gamma: float = 1.0,
    contrast: float = 1.0,
    dither: bool = False,
    transparent_bg: bool = False,
    alpha_threshold: int = 16,
) -> str:
    """Return an ASCII-art string rendering of the given image.

    If transparent_bg is True and the source image has an alpha channel,
    pixels below alpha_threshold are rendered as a blank space instead of
    being mapped to a density character — so a transparent background stays
    blank rather than becoming solid dark/light art.
    """
    chars = CHARSETS.get(charset, CHARSETS["detailed"])
    if invert:
        chars = chars[::-1]
    n = len(chars) - 1
    if n <= 0:
        raise ValueError("charset must contain at least 2 characters")

    img, alpha = _load_grayscale(image_path)

    if contrast != 1.0:
        img = ImageEnhance.Contrast(img).enhance(contrast)

    orig_w, orig_h = img.size
    if orig_w == 0 or orig_h == 0:
        raise ValueError("image has zero width or height")

    height = max(1, round(orig_h / orig_w * width * char_aspect))
    width = max(1, width)
    img = img.resize((width, height), Image.LANCZOS)

    alpha_mask = None
    if transparent_bg and alpha is not None:
        alpha_small = alpha.resize((width, height), Image.LANCZOS)
        alpha_mask = np.asarray(alpha_small, dtype=np.uint8) < alpha_threshold

    arr = np.asarray(img, dtype=np.float64) / 255.0

    if gamma != 1.0:
        arr = np.power(arr, gamma)

    if dither:
        # Floyd–Steinberg error diffusion for smoother gradients at low char counts.
        levels = np.round(arr * n).astype(np.int64)
        err = arr * n - levels
        h, w = arr.shape
        work = arr * n
        for y in range(h):
            for x in range(w):
                old = work[y, x]
                new = round(old)
                new = min(max(new, 0), n)
                delta = old - new
                work[y, x] = new
                if x + 1 < w:
                    work[y, x + 1] += delta * 7 / 16
                if y + 1 < h:
                    if x > 0:
                        work[y + 1, x - 1] += delta * 3 / 16
                    work[y + 1, x] += delta * 5 / 16
                    if x + 1 < w:
                        work[y + 1, x + 1] += delta * 1 / 16
        indices = np.clip(work, 0, n).astype(int)
    else:
        indices = np.clip(np.round(arr * n), 0, n).astype(int)

    if alpha_mask is not None:
        # Blank out transparent regions regardless of their computed brightness.
        space_idx = chars.index(" ") if " " in chars else 0
        indices = np.where(alpha_mask, space_idx, indices)

    lines = ["".join(chars[i] for i in row) for row in indices]
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Convert an image to ASCII art with correct aspect ratio.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("image", help="Path to the input image")
    p.add_argument("--width", type=int, default=100, help="Width in characters")
    p.add_argument("--output", "-o", default=None, help="Save to file instead of printing to stdout")
    p.add_argument("--charset", choices=list(CHARSETS.keys()), default="detailed",
                    help="Character density set to use")
    p.add_argument("--invert", action="store_true", help="Invert brightness mapping")
    p.add_argument("--char-aspect", type=float, default=DEFAULT_CHAR_ASPECT,
                    help="Height compression factor to correct for font cell shape")
    p.add_argument("--gamma", type=float, default=1.0,
                    help="Gamma correction (<1 brightens midtones, >1 darkens)")
    p.add_argument("--contrast", type=float, default=1.0, help="Contrast multiplier")
    p.add_argument("--dither", action="store_true",
                    help="Apply Floyd-Steinberg dithering for smoother gradients")
    p.add_argument("--transparent-bg", action="store_true",
                    help="Preserve source transparency: transparent pixels become blank "
                         "space instead of being converted to a density character "
                         "(requires a PNG/GIF/etc. with an alpha channel)")
    p.add_argument("--alpha-threshold", type=int, default=16,
                    help="Alpha value (0-255) below which a pixel is treated as "
                         "transparent when --transparent-bg is set")
    return p.parse_args()


def main() -> None:
    args = parse_args()

    path = Path(args.image)
    if not path.exists():
        print(f"[error] File not found: {path}", file=sys.stderr)
        sys.exit(1)
    if args.width <= 0:
        print("[error] --width must be positive", file=sys.stderr)
        sys.exit(1)

    print(f"Converting '{path.name}'  width={args.width}  charset={args.charset}", file=sys.stderr)

    try:
        art = image_to_ascii(
            str(path),
            width=args.width,
            charset=args.charset,
            invert=args.invert,
            char_aspect=args.char_aspect,
            gamma=args.gamma,
            contrast=args.contrast,
            dither=args.dither,
            transparent_bg=args.transparent_bg,
            alpha_threshold=args.alpha_threshold,
        )
    except Exception as e:
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)

    if args.output:
        out = Path(args.output)
        out.write_text(art, encoding="utf-8")
        print(f"Saved → {out}", file=sys.stderr)
    else:
        print(art)


if __name__ == "__main__":
    main()
