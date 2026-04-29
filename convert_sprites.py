#!/usr/bin/env python3
"""
Convert BMP sprite files to PNG with alpha channel.
Black (0, 0, 0) pixels become fully transparent.
Skips back_*.bmp background tiles (used opaque).
"""
import os
from PIL import Image

SPRITES_DIR = os.path.join(os.path.dirname(__file__), "sprites")
SKIP_PREFIXES = ("back_",)  # background tiles used opaque

def convert_bmp_to_png(bmp_path, png_path):
    img = Image.open(bmp_path).convert("RGB")
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if r == 0 and g == 0 and b == 0:
                pixels[x, y] = (0, 0, 0, 0)
    rgba.save(png_path, "PNG")

def should_skip(filename):
    name = os.path.basename(filename).lower()
    return any(name.startswith(p) for p in SKIP_PREFIXES)

converted = 0
skipped = 0

for dirpath, dirnames, filenames in os.walk(SPRITES_DIR):
    # Skip non-sprite subdirs (enemy, enemy2, level already have PNGs)
    dirnames[:] = [d for d in dirnames if d.lower() in ("font",)]
    for filename in filenames:
        if not filename.lower().endswith(".bmp"):
            continue
        if should_skip(filename):
            print(f"  skip: {filename}")
            skipped += 1
            continue
        bmp_path = os.path.join(dirpath, filename)
        png_path = os.path.splitext(bmp_path)[0] + ".png"
        convert_bmp_to_png(bmp_path, png_path)
        converted += 1

print(f"\nDone: {converted} converted, {skipped} skipped")
