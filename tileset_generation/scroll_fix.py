#!/usr/bin/env python3
"""
Fix scroll assets:
1. Generate procedural parchment background (no DALL-E, free)
2. Better green screen removal on the roller
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageFilter, ImageDraw
    import numpy as np
except ImportError:
    print("Required: pip install pillow numpy")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "ui" / "tome"


def generate_procedural_parchment(width: int = 512, height: int = 640) -> Image.Image:
    """Create an aged parchment texture procedurally."""
    rng = np.random.RandomState(42)

    # Base warm parchment color (lighter for better text contrast)
    base_r, base_g, base_b = 210, 192, 155

    # Create base with subtle noise
    r = np.full((height, width), base_r, dtype=np.float32) + rng.normal(0, 6, (height, width))
    g = np.full((height, width), base_g, dtype=np.float32) + rng.normal(0, 5, (height, width))
    b = np.full((height, width), base_b, dtype=np.float32) + rng.normal(0, 5, (height, width))

    # Add large-scale color variation (Perlin-like via multi-scale noise)
    for scale in [32, 64, 128, 256]:
        noise_small = rng.normal(0, 1, (height // scale + 2, width // scale + 2))
        # Upscale with interpolation
        noise_big = np.array(
            Image.fromarray(noise_small.astype(np.float32)).resize(
                (width, height), Image.Resampling.BILINEAR
            )
        )
        intensity = 12.0 * (scale / 64.0)
        r += noise_big * intensity * 0.8
        g += noise_big * intensity * 0.7
        b += noise_big * intensity * 0.5

    # Darken edges (vignette)
    y_grid, x_grid = np.mgrid[0:height, 0:width]
    cx, cy = width / 2.0, height / 2.0
    dist = np.sqrt(((x_grid - cx) / cx) ** 2 + ((y_grid - cy) / cy) ** 2)
    vignette = np.clip(1.0 - (dist - 0.6) * 0.5, 0.55, 1.0)
    r *= vignette
    g *= vignette
    b *= vignette

    # Add foxing spots (subtle, fewer for readability)
    num_spots = 12
    for _ in range(num_spots):
        sx = rng.randint(30, width - 30)
        sy = rng.randint(30, height - 30)
        sr = rng.randint(2, 8)
        spot_mask = ((x_grid - sx) ** 2 + (y_grid - sy) ** 2) < sr ** 2
        darken = rng.uniform(0.90, 0.96)
        r[spot_mask] *= darken
        g[spot_mask] *= darken
        b[spot_mask] *= darken

    # Add subtle horizontal fiber lines
    for _ in range(20):
        ly = rng.randint(0, height)
        lx1, lx2 = sorted(rng.randint(0, width, 2))
        thickness = rng.randint(1, 2)
        darken = rng.uniform(0.95, 0.98)
        for dy in range(thickness):
            yy = min(ly + dy, height - 1)
            r[yy, lx1:lx2] *= darken
            g[yy, lx1:lx2] *= darken
            b[yy, lx1:lx2] *= darken

    # Clamp and convert
    r = np.clip(r, 0, 255).astype(np.uint8)
    g = np.clip(g, 0, 255).astype(np.uint8)
    b = np.clip(b, 0, 255).astype(np.uint8)
    a = np.full((height, width), 255, dtype=np.uint8)

    img = np.stack([r, g, b, a], axis=2)
    return Image.fromarray(img, "RGBA")


def fix_roller_chroma(input_path: Path, output_path: Path):
    """Better green screen removal for scroll roller."""
    img = Image.open(input_path).convert("RGBA")
    arr = np.array(img, dtype=np.float32)

    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    # Aggressive green removal
    # Method: compute "greenness" ratio
    max_rb = np.maximum(r, b)
    greenness = g - max_rb

    # Strong green: definitely background
    strong_green = greenness > 20
    # Moderate green with high brightness: also background
    moderate_green = (greenness > 5) & (g > 100)
    # Near-white: background
    near_white = (r > 210) & (g > 210) & (b > 210)
    # Light gray/white edges
    light_bg = ((r + g + b) / 3 > 200) & (greenness > -10)

    remove_mask = strong_green | moderate_green | near_white | light_bg

    # Create alpha: 0 for background, 255 for foreground
    new_alpha = np.where(remove_mask, 0, 255).astype(np.uint8)

    # Also remove any green tint from edge pixels of the roller
    # (spill suppression)
    edge_zone = ~remove_mask & (greenness > -5) & (g > 60)
    # Reduce green channel in edge zone to suppress spill
    g_fixed = g.copy()
    g_fixed[edge_zone] = np.minimum(g[edge_zone], (r[edge_zone] + b[edge_zone]) / 2 + 5)

    # Smooth alpha edges
    alpha_img = Image.fromarray(new_alpha)
    # Erode slightly to remove fringe
    alpha_img = alpha_img.filter(ImageFilter.MinFilter(3))
    # Then blur for soft edges
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=1.2))
    new_alpha = np.array(alpha_img)
    # Re-threshold
    new_alpha[new_alpha < 40] = 0

    result_arr = np.stack([
        np.clip(r, 0, 255).astype(np.uint8),
        np.clip(g_fixed, 0, 255).astype(np.uint8),
        np.clip(b, 0, 255).astype(np.uint8),
        new_alpha
    ], axis=2)

    result = Image.fromarray(result_arr, "RGBA")
    result.save(output_path, "PNG")
    print(f"  Fixed: {output_path}")
    return result


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Generate procedural parchment background
    print("=== Generating procedural parchment background ===")
    parchment = generate_procedural_parchment(512, 640)
    bg_path = OUTPUT_DIR / "scroll_bg.png"
    parchment.save(bg_path, "PNG")
    print(f"  Saved: {bg_path}")

    # 2. Fix roller chroma key
    roller_path = OUTPUT_DIR / "scroll_roller.png"
    if not roller_path.exists():
        print(f"  No roller found at {roller_path}, skipping fix")
        return

    print("\n=== Fixing scroll roller chroma key ===")
    # Work on original (before previous processing damaged it)
    # Re-read the current roller
    fixed = fix_roller_chroma(roller_path, roller_path)

    # Create mirrored right version
    mirrored = fixed.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    mirror_path = OUTPUT_DIR / "scroll_roller_right.png"
    mirrored.save(mirror_path, "PNG")
    print(f"  Mirrored: {mirror_path}")

    print("\n=== Done! (zero DALL-E cost) ===")


if __name__ == "__main__":
    main()
