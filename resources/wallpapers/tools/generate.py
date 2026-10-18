#!/usr/bin/env python3
"""Procedural wallpapers drawn straight from a palette.

Renders the wallpaper set for a theme using only that theme's own colors, so
every image is on-palette by construction (no recoloring, no licensing). The
committed images in ../<theme>/ are the output of this script; it exists so
they can be reproduced, tweaked, or regenerated for a new palette.

    nix shell nixpkgs#python3Packages.{numpy,pillow,scipy} -c \
        python resources/wallpapers/tools/generate.py catppuccin-macchiato

Output: ../<theme>/<name>.jpg at 3840x2400 (16:10). The wallpaper daemon crops
to fill, so 16:9 screens see the central 3840x2160. Compositions keep their
focal point inside that band. Seeds are fixed, so output is reproducible.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, gaussian_filter1d

W, H = 3840, 2400

PALETTES = {
    "catppuccin-macchiato": {
        "crust": "181926", "mantle": "1e2030", "base": "24273a",
        "surface0": "363a4f", "surface1": "494d64", "surface2": "5b6078",
        "overlay0": "6e738d", "overlay1": "8087a2", "overlay2": "939ab7",
        "subtext0": "a5adcb", "subtext1": "b8c0e0", "text": "cad3f5",
        "lavender": "b7bdf8", "blue": "8aadf4", "sapphire": "7dc4e4",
        "sky": "91d7e3", "teal": "8bd5ca", "green": "a6da95",
        "yellow": "eed49f", "peach": "f5a97f", "maroon": "ee99a0",
        "red": "ed8796", "mauve": "c6a0f6", "pink": "f5bde6",
        "flamingo": "f0c6c6", "rosewater": "f4dbd6",
    },
}


# --- color helpers -----------------------------------------------------------
# Blend in linear light, store as sRGB: gradients stay luminous instead of going
# muddy in the middle.

def _to_lin(c):
    c = np.asarray(c, dtype=np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _to_srgb(c):
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


class Canvas:
    def __init__(self, palette, seed):
        self.p = palette
        self.rng = np.random.default_rng(seed)
        self.y = np.linspace(0.0, 1.0, H, dtype=np.float32)[:, None]
        self.x = np.linspace(0.0, 1.0, W, dtype=np.float32)[None, :]
        self.px = np.arange(W, dtype=np.float32)[None, :]
        self.py = np.arange(H, dtype=np.float32)[:, None]
        self.img = np.zeros((H, W, 3), dtype=np.float32)  # linear light

    def col(self, name, k=1.0, mix=None, t=0.0):
        """Palette color (linear), optionally mixed toward another and scaled."""
        a = _to_lin(np.array([int(self.p[name][i:i + 2], 16) for i in (0, 2, 4)]) / 255)
        if mix:
            b = _to_lin(np.array([int(self.p[mix][i:i + 2], 16) for i in (0, 2, 4)]) / 255)
            a = a * (1 - t) + b * t
        return (a * k).astype(np.float32)

    def gradient(self, stops, axis="y"):
        """stops: [(t, color)] along y (or x). Interpolated in sRGB (perceptual)
        space, so dark-to-light ramps look smooth, then returned in linear light."""
        ts = np.array([s[0] for s in stops], dtype=np.float32)
        cs = _to_srgb(np.stack([s[1] for s in stops]).astype(np.float32))
        t = self.y if axis == "y" else self.x
        flat = t.reshape(-1)
        out = np.stack([np.interp(flat, ts, cs[:, i]) for i in range(3)], axis=-1)
        out = _to_lin(out).astype(np.float32)
        return out[:, None, :] if axis == "y" else out[None, :, :]

    def fbm1d(self, n, octaves=7, base=3, persistence=0.52):
        out = np.zeros(n, dtype=np.float64)
        amp, total = 1.0, 0.0
        for o in range(octaves):
            pts = self.rng.random(base * 2 ** o + 1)
            xs = np.linspace(0, len(pts) - 1, n)
            i = np.minimum(np.floor(xs).astype(int), len(pts) - 2)
            f = xs - i
            f = (1 - np.cos(f * np.pi)) / 2
            out += amp * ((1 - f) * pts[i] + f * pts[i + 1])
            total += amp
            amp *= persistence
        return (out / total).astype(np.float32)

    def noise2d(self, scale, octaves=1, persistence=0.5):
        """Smooth 2-D noise in 0..1; `scale` = feature size in pixels."""
        out = np.zeros((H, W), dtype=np.float32)
        amp, total = 1.0, 0.0
        for _ in range(octaves):
            h, w = max(2, int(H / scale)), max(2, int(W / scale))
            small = self.rng.standard_normal((h + 8, w + 8)).astype(np.float32)
            small = gaussian_filter(small, 1.2)[4:-4, 4:-4]
            big = np.array(
                Image.fromarray(small).resize((W, H), Image.BICUBIC), dtype=np.float32
            )
            out += amp * big
            total += amp
            amp *= persistence
            scale /= 2
        out /= total
        out -= out.min()
        return out / out.max()

    def over(self, color, alpha):
        """Composite `color` (3,) or (H,W,3) over the image with alpha (H,W)|(H,1)."""
        a = np.asarray(alpha, dtype=np.float32)
        if a.ndim == 2:
            a = a[..., None]
        self.img = self.img * (1 - a) + np.asarray(color, dtype=np.float32) * a

    def add(self, color, amount):
        a = np.asarray(amount, dtype=np.float32)
        if a.ndim == 2:
            a = a[..., None]
        self.img += np.asarray(color, dtype=np.float32) * a

    def glow(self, cx, cy, radius, power=2.2):
        d = np.sqrt((self.px - cx * W) ** 2 + (self.py - cy * H) ** 2) / radius
        return np.clip(1 - d, 0, 1) ** power

    def disc(self, cx, cy, r, softness=1.5):
        d = np.sqrt((self.px - cx * W) ** 2 + (self.py - cy * H) ** 2)
        return np.clip((r - d) / softness + 0.5, 0, 1)

    def stars(self, count, region=(0.0, 0.55), color=None, strength=1.0):
        color = self.col("text") if color is None else color
        layer = np.zeros((H, W), dtype=np.float32)
        ys = (self.rng.random(count) ** 1.4 * (region[1] - region[0]) + region[0]) * H
        xs = self.rng.random(count) * W
        br = self.rng.random(count) ** 3
        for x, y, b in zip(xs.astype(int), ys.astype(int), br):
            layer[y, x] = max(layer[y, x], 0.15 + 0.85 * b)
        layer = gaussian_filter(layer, 1.1) * 5.0
        self.add(color * 0.9 * strength, np.clip(layer, 0, 1))

    def save(self, path, grain=1.3):
        out = _to_srgb(self.img)
        # Dither so dark gradients don't band after 8-bit quantization.
        out = out + self.rng.normal(0, grain / 255, out.shape).astype(np.float32)
        out = np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8)
        Image.fromarray(out).save(path, quality=92, subsampling=0, optimize=True)


# --- wallpapers ----------------------------------------------------------------

def ridges(c, haze_name, layers, base_y, spread, amp, moon=None):
    """Draw receding mountain layers, far (hazy) to near (dark)."""
    for i in range(layers):
        t = i / max(1, layers - 1)  # 0 far .. 1 near
        profile = c.fbm1d(W, octaves=7 - int(t * 2), base=2 + i)
        ridge_y = (base_y + spread * t + (profile - 0.5) * amp * (0.6 + 0.8 * t)) * H
        edge = np.clip((c.py - ridge_y[None, :]) / 1.6 + 0.5, 0, 1)
        fog = 1.0 - t
        top = c.col(haze_name, 0.55 + 0.35 * fog, mix="base", t=0.35 + 0.4 * t)
        top = top * (1 - 0.82 * t) + c.col("crust") * (0.82 * t)
        bottom = top * (0.55 + 0.25 * fog) + c.col("crust") * 0.2
        depth = np.clip((c.py - ridge_y[None, :]) / (0.28 * H), 0, 1)[..., None]
        layer = top * (1 - depth) + bottom * depth
        c.over(layer, edge)
    return


def dusk_ridges(p):
    c = Canvas(p, seed=11)
    sky = c.gradient([
        (0.00, c.col("crust")),
        (0.30, c.col("mantle")),
        (0.48, c.col("base", mix="mauve", t=0.18)),
        (0.60, c.col("base", mix="mauve", t=0.42)),
        (0.68, c.col("mauve", 0.62, mix="pink", t=0.45)),
        (0.74, c.col("pink", 0.62, mix="peach", t=0.40)),
        (1.00, c.col("mantle")),
    ])
    c.img = np.broadcast_to(sky, (H, W, 3)).copy()
    c.stars(260, region=(0.0, 0.42), strength=0.8)
    c.add(c.col("peach", 0.5, mix="pink", t=0.4), c.glow(0.64, 0.62, 900, 2.6) * 0.55)
    c.over(c.col("rosewater", 0.95, mix="flamingo", t=0.3), c.disc(0.64, 0.585, 150, 2.0) * 0.96)
    c.add(c.col("flamingo", 0.8), c.glow(0.64, 0.585, 330, 2.0) * 0.30)
    ridges(c, "mauve", layers=7, base_y=0.60, spread=0.30, amp=0.17)
    c.save(OUT / "dusk-ridges.jpg")


def aurora_veil(p):
    c = Canvas(p, seed=23)
    sky = c.gradient([
        (0.0, c.col("crust")), (0.55, c.col("mantle")), (1.0, c.col("base", 0.8, mix="crust", t=0.3))
    ])
    c.img = np.broadcast_to(sky, (H, W, 3)).copy()
    c.stars(420, region=(0.0, 0.85), strength=0.7)
    drift = c.noise2d(900, octaves=3)
    # (height, wave amp, wave freq, phase, strength, hue shift)
    ribbons = [
        (0.30, 0.07, 5.0, 2.4, 0.55, 0.30),
        (0.40, 0.10, 6.2, 1.3, 1.00, 0.00),
        (0.50, 0.06, 7.5, 4.0, 0.45, -0.25),
    ]
    teal, mauve, blue = c.col("teal"), c.col("mauve"), c.col("blue")
    for y0, amp, freq, ph, k, hs in ribbons:
        ribbon_y = y0 + amp * np.sin(c.x * freq + ph + 2.0 * (drift - 0.5)) + 0.03 * np.sin(c.x * 15.0 + ph)
        h = c.y - ribbon_y
        streaks = gaussian_filter(c.rng.random((1, W)).astype(np.float32), (0, 3))
        streaks = (streaks - streaks.min()) / (streaks.max() - streaks.min())
        body = np.exp(-np.clip(h, 0, None) * 7.0) * (h > 0)       # fades downward
        lead = np.exp(-np.abs(h) * 75.0)                           # bright leading edge
        curtain = (0.55 * body * (0.15 + 0.85 * streaks ** 1.6) + 0.9 * lead) * (0.5 + 0.8 * drift) * k
        curtain = gaussian_filter(curtain, 5).astype(np.float32)
        hue = np.clip(c.x * 1.1 - 0.05 + hs + 0.3 * (drift - 0.5), 0, 1)[..., None]
        color = teal * (1 - hue) + mauve * hue * 0.9 + blue * 0.25
        c.add(color * 0.55, curtain)
    c.add(c.col("blue", 0.5), c.glow(0.5, 0.45, 1500, 2.0) * 0.10)
    prof = c.fbm1d(W, octaves=6, base=3)
    ground = (0.90 + (prof - 0.5) * 0.10) * H
    c.over(c.col("crust", 0.9), np.clip((c.py - ground[None, :]) / 1.6 + 0.5, 0, 1))
    c.save(OUT / "aurora-veil.jpg")


def contours(p):
    c = Canvas(p, seed=5)
    field = c.noise2d(1100, octaves=4, persistence=0.55)
    field = gaussian_filter(field, 3)
    c.img = np.broadcast_to(c.col("base", 0.92, mix="mantle", t=0.5), (H, W, 3)).copy()
    levels = 38
    f = field * levels
    d = np.abs(f - np.round(f))                       # distance to nearest iso-level (in level units)
    grad = np.sqrt(sum(g ** 2 for g in np.gradient(f)))  # level units per pixel
    dist_px = d / np.maximum(grad, 1e-4)
    line = np.clip(1.6 - dist_px / 1.1, 0, 1)         # ~2.5 px antialiased line
    major = (np.round(f) % 5 == 0).astype(np.float32)
    c.add(c.col("overlay0", 0.55), line * (1 - major) * 0.70)
    c.add(c.col("blue", 0.75, mix="lavender", t=0.4), line * major * 0.85)
    # Slow vignette + one soft accent bloom.
    c.add(c.col("mauve", 0.5), c.glow(0.72, 0.38, 1700, 2.0) * 0.10)
    vign = np.clip(np.sqrt(((c.x - 0.5) * 1.3) ** 2 + ((c.y - 0.5) * 1.6) ** 2), 0, 1)
    c.over(c.col("crust", 0.7), vign ** 2.2 * 0.55)
    c.save(OUT / "contours.jpg")


def eclipse(p):
    c = Canvas(p, seed=41)
    sky = c.gradient([(0.0, c.col("crust")), (0.5, c.col("mantle", 0.9)), (1.0, c.col("crust"))])
    c.img = np.broadcast_to(sky, (H, W, 3)).copy()
    c.stars(520, region=(0.0, 1.0), strength=0.65)
    cx, cy, r = 0.5, 0.5, 410
    # Corona: wide soft halo + a tight bright rim hugging the disc.
    d = np.sqrt((c.px - cx * W) ** 2 + (c.py - cy * H) ** 2)
    halo = np.exp(-np.clip(d - r, 0, None) / 260.0)
    rim = np.exp(-np.clip(d - r, 0, None) / 18.0)
    ang = np.arctan2(c.py - cy * H, c.px - cx * W)
    tint = (0.5 + 0.5 * np.sin(ang + 0.6))[..., None]
    warm = c.col("peach", 0.8, mix="pink", t=0.5)
    cool = c.col("blue", 0.85, mix="mauve", t=0.55)
    ring = warm * tint + cool * (1 - tint)
    c.add(ring * 0.5, halo[..., None] * 0.55 * (d > r)[..., None])
    c.add(ring * 1.2, rim[..., None] * (d > r)[..., None])
    # Dark disc over everything.
    c.over(c.col("crust", 0.85), c.disc(cx, cy, r, 1.6))
    c.add(c.col("lavender", 0.4), (np.exp(-np.abs(d - r) / 3.0) * 0.45)[..., None] * 0.6)
    c.save(OUT / "eclipse.jpg")


def horizon(p):
    c = Canvas(p, seed=77)
    hy = 0.62
    sky = c.gradient([
        (0.00, c.col("crust")),
        (0.28, c.col("mantle")),
        (0.50, c.col("base", mix="blue", t=0.22)),
        (hy,   c.col("blue", 0.55, mix="lavender", t=0.35)),
        (hy + 0.0001, c.col("mantle")),
        (1.00, c.col("crust")),
    ])
    c.img = np.broadcast_to(sky, (H, W, 3)).copy()
    c.stars(300, region=(0.0, 0.5), strength=0.75)
    mx, my, mr = 0.5, 0.40, 120
    c.add(c.col("lavender", 0.6), c.glow(mx, my, 900, 2.4) * 0.35)
    c.over(c.col("text", 0.95, mix="rosewater", t=0.25), c.disc(mx, my, mr, 2.0))
    # Water: gentle horizontal ripples, with the moon's reflection as a column.
    below = (c.y > hy).astype(np.float32)
    depth = np.clip((c.y - hy) / (1 - hy), 0, 1)
    n = c.noise2d(700, octaves=3)
    ripple = np.sin(depth ** 0.55 * 260 + 6 * (n - 0.5)) * 0.5 + 0.5
    water = c.col("mantle", 0.95) * (1 - depth[..., None]) + c.col("crust") * depth[..., None]
    c.over(water, below)
    col_w = np.exp(-((c.x - mx) * W / (70 + 260 * depth)) ** 2)
    refl = col_w * (0.25 + 0.75 * ripple) * (1 - depth) ** 1.4 * below
    c.add(c.col("lavender", 0.9, mix="text", t=0.35), refl * 0.65)
    c.add(c.col("blue", 0.6), np.exp(-np.abs(c.y - hy) * 110) * 0.55)   # horizon line glow
    c.save(OUT / "horizon.jpg")


def mesh(p):
    c = Canvas(p, seed=99)
    c.img = np.broadcast_to(c.col("crust", 1.0, mix="mantle", t=0.5), (H, W, 3)).copy()
    blobs = [
        (0.18, 0.30, 1250, "blue", 0.30), (0.62, 0.22, 1050, "mauve", 0.28),
        (0.88, 0.62, 1250, "pink", 0.14), (0.40, 0.82, 1150, "lavender", 0.20),
        (0.70, 0.88, 800, "sapphire", 0.16), (0.08, 0.80, 800, "teal", 0.12),
    ]
    warp = c.noise2d(1300, octaves=2)
    for x, y, r, name, k in blobs:
        dx = (c.px - x * W) + 220 * (warp - 0.5)
        dy = (c.py - y * H) + 220 * (np.roll(warp, 300, axis=1) - 0.5)
        g = np.exp(-(dx ** 2 + dy ** 2) / (2 * (r * 0.62) ** 2))
        c.add(c.col(name, k), g)
    vign = np.clip(np.sqrt(((c.x - 0.5) * 1.2) ** 2 + ((c.y - 0.5) * 1.5) ** 2), 0, 1)
    c.over(c.col("crust", 0.8), vign ** 2.4 * 0.7)
    c.save(OUT / "mesh.jpg", grain=1.8)


def moonlit_dunes(p):
    c = Canvas(p, seed=63)
    sky = c.gradient([
        (0.00, c.col("crust")), (0.30, c.col("mantle")),
        (0.55, c.col("base", mix="lavender", t=0.16)),
        (0.70, c.col("lavender", 0.42, mix="pink", t=0.3)),
        (1.00, c.col("mantle")),
    ])
    c.img = np.broadcast_to(sky, (H, W, 3)).copy()
    c.stars(300, region=(0.0, 0.5), strength=0.7)
    mx, my = 0.30, 0.34
    c.add(c.col("flamingo", 0.55, mix="lavender", t=0.4), c.glow(mx, my, 1000, 2.5) * 0.30)
    c.over(c.col("rosewater", 0.95), c.disc(mx, my, 140, 2.0))
    # Dunes: long sweeping sine crests plus a little fbm. Crests are 1-D (per x).
    x1 = c.x[0]
    for i in range(6):
        t = i / 5
        base = 0.62 + 0.30 * t
        crest = (0.045 + 0.05 * t) * np.sin(x1 * (2.2 + 1.3 * t) * np.pi + i * 1.7)
        crest = crest + 0.02 * np.sin(x1 * 9.0 + i * 3.1) * t
        crest = crest + (c.fbm1d(W, octaves=4, base=2) - 0.5) * 0.05
        ridge_y = ((base + crest) * H).astype(np.float32)[None, :]
        edge = np.clip((c.py - ridge_y) / 1.6 + 0.5, 0, 1)
        light = c.col("lavender", 0.55 - 0.40 * t, mix="mauve", t=0.35)
        shade = c.col("mantle", 1.0 - 0.45 * t, mix="crust", t=0.4 + 0.5 * t)
        # Lit face on the moon side of each crest, deep shade falling away.
        slope = gaussian_filter1d(np.gradient(crest * H), 180)
        slope = slope / (np.abs(slope).max() + 1e-6)
        lit = np.clip(0.5 - 0.55 * slope, 0, 1).astype(np.float32)[None, :, None]
        depth = np.clip((c.py - ridge_y) / (0.2 * H), 0, 1)[..., None]
        top = shade * (1 - lit * 0.9) + light * lit * 0.9
        layer = top * (1 - depth) + shade * depth
        c.over(layer, edge)
    c.save(OUT / "moonlit-dunes.jpg")


def grid_fade(p):
    c = Canvas(p, seed=3)
    c.img = np.broadcast_to(c.col("base", 0.95, mix="mantle", t=0.35), (H, W, 3)).copy()
    step = 64
    gx = np.abs(((c.px + step / 2) % step) - step / 2)
    gy = np.abs(((c.py + step / 2) % step) - step / 2)
    dot = np.clip(3.2 - np.sqrt(gx ** 2 + gy ** 2) / 1.0, 0, 1)
    fall = np.clip(1 - np.sqrt(((c.x - 0.5) * 1.1) ** 2 + ((c.y - 0.5) * 1.4) ** 2) * 1.25, 0, 1) ** 1.1
    c.add(c.col("blue", 0.95, mix="lavender", t=0.4), dot * fall)
    c.add(c.col("blue", 0.5, mix="mauve", t=0.5), c.glow(0.5, 0.5, 1300, 2.4) * 0.18)
    c.save(OUT / "grid-fade.jpg")


SCENES = [dusk_ridges, aurora_veil, contours, eclipse, horizon, mesh, moonlit_dunes, grid_fade]

if __name__ == "__main__":
    theme = sys.argv[1] if len(sys.argv) > 1 else "catppuccin-macchiato"
    only = set(sys.argv[2:])
    OUT = Path(__file__).resolve().parent.parent / theme
    OUT.mkdir(parents=True, exist_ok=True)
    palette = PALETTES[theme]
    for scene in SCENES:
        if only and scene.__name__ not in only:
            continue
        print("rendering", scene.__name__, flush=True)
        scene(palette)
