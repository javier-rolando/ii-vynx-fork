#!/usr/bin/env python3
"""
recolor_remote_image.py — Tint a remotely-fetched image (e.g. a sports team
badge) with the same Material You gradient used for local app icons.

Only imports get_icon_colors() from recolor_icons.py (unmodified, existing
function) to read the current palette — the gradient LUT logic itself is
duplicated here rather than shared, so this file never needs to touch
recolor_icons.py and can't conflict with upstream changes to it.

Results are cached on disk keyed by (url, colors hash) so repeated calls for
the same badge/theme are instant.

Usage: recolor_remote_image.py <url>
Prints the local path to the tinted PNG on success, or the original URL
unchanged if anything fails (network error, bad image, no Pillow, etc.) so
the caller can always fall back to displaying the original.
"""
import hashlib
import io
import json
import os
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from recolor_icons import get_icon_colors

CACHE_DIR = os.path.expanduser("~/.cache/quickshell/tinted-remote-images")


def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))


def build_gradient_lut(colors):
    def get_luminance(rgb):
        return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]

    raw_palette = [
        hex_to_rgb(colors.get('on_primary', '#000000')),
        hex_to_rgb(colors.get('on_secondary', '#111111')),
        hex_to_rgb(colors.get('secondary_container', '#222222')),
        hex_to_rgb(colors.get('primary_container', '#444444')),
        hex_to_rgb(colors.get('secondary', '#888888')),
        hex_to_rgb(colors.get('primary', '#ffffff'))
    ]
    raw_palette.sort(key=get_luminance)

    r_lut, g_lut, b_lut = [], [], []
    num_colors = len(raw_palette)
    for i in range(256):
        t = i / 255.0
        scaled_t = t * (num_colors - 1)
        idx = int(scaled_t)
        if idx >= num_colors - 1:
            c = raw_palette[-1]
        else:
            fraction = scaled_t - idx
            c1 = raw_palette[idx]
            c2 = raw_palette[idx + 1]
            c = (
                int(c1[0] + (c2[0] - c1[0]) * fraction),
                int(c1[1] + (c2[1] - c1[1]) * fraction),
                int(c1[2] + (c2[2] - c1[2]) * fraction)
            )
        r_lut.append(c[0])
        g_lut.append(c[1])
        b_lut.append(c[2])
    return r_lut, g_lut, b_lut


def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        return
    url = sys.argv[1]

    colors = get_icon_colors()
    if not colors:
        print(url)
        return

    colors_hash = hashlib.md5(json.dumps(colors, sort_keys=True).encode()).hexdigest()[:10]
    url_hash = hashlib.md5(url.encode()).hexdigest()[:16]
    cache_file = os.path.join(CACHE_DIR, f"{url_hash}-{colors_hash}.png")

    if os.path.isfile(cache_file):
        print(cache_file)
        return

    try:
        from PIL import Image

        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = resp.read()

        img = Image.open(io.BytesIO(data)).convert("RGBA")
        alpha = img.split()[3]
        gray = img.convert("L")

        r_lut, g_lut, b_lut = build_gradient_lut(colors)
        r = gray.point(r_lut)
        g = gray.point(g_lut)
        b = gray.point(b_lut)
        mapped = Image.merge("RGB", (r, g, b))
        mapped.putalpha(alpha)

        os.makedirs(CACHE_DIR, exist_ok=True)
        mapped.save(cache_file, "PNG")
        print(cache_file)
    except Exception:
        print(url)


if __name__ == "__main__":
    main()
