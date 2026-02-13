#!/usr/bin/env python3
"""
Tier 3 Round 2 Fixes — Targeted pixel-level cleanup + color merge weapon recovery.

Fixes:
- #54 Easterling Warrior: Recover missing scimitar via rembg + color merge technique
- #57 Easterling Champion: Remove magenta background blotch
- #58 Ghast: Clean up green edge artifacts
- #73 Zombie: Remove white-pink-beige halo around figure
- #80 Easterling Infiltrator: Remove pink BG under crouching legs

Usage:
    python3 fix_tier3_round2.py                # Fix all
    python3 fix_tier3_round2.py --ids 54 57    # Fix specific
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_erosion, binary_dilation

BASE_DIR = Path(__file__).parent
TIER_DIR = BASE_DIR / "monster_v3" / "tier_3"
RAW_DIR = BASE_DIR / "monster_v2" / "raw"
CORRECTED_DIR = BASE_DIR / "monster_v2" / "corrected"

try:
    from rembg import remove as rembg_remove
except ImportError:
    rembg_remove = None


# ============================================================================
# HSV Utilities
# ============================================================================

def compute_hsv(rgb):
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc

    hue = np.zeros_like(maxc)
    nz = diff > 0.001
    mr = (maxc == r) & nz
    mg = (maxc == g) & nz & ~mr
    mb = (maxc == b) & nz & ~mr & ~mg

    hue[mr] = 60.0 * (((g[mr] - b[mr]) / diff[mr]) % 6)
    hue[mg] = 60.0 * (((b[mg] - r[mg]) / diff[mg]) + 2)
    hue[mb] = 60.0 * (((r[mb] - g[mb]) / diff[mb]) + 4)

    sat = np.where(maxc > 0.001, diff / maxc, 0.0)
    return hue, sat, maxc


def hsv_to_rgb(hue, sat, val):
    c = val * sat
    hp = hue / 60.0
    x = c * (1 - np.abs(hp % 2 - 1))
    z = np.zeros_like(c)
    m = val - c

    rgb = np.zeros((*hue.shape, 3))
    for mask, rc, gc, bc in [
        ((hp >= 0) & (hp < 1), c, x, z),
        ((hp >= 1) & (hp < 2), x, c, z),
        ((hp >= 2) & (hp < 3), z, c, x),
        ((hp >= 3) & (hp < 4), z, x, c),
        ((hp >= 4) & (hp < 5), x, z, c),
        ((hp >= 5) & (hp < 6), c, z, x),
    ]:
        rgb[mask, 0] = rc[mask]
        rgb[mask, 1] = gc[mask]
        rgb[mask, 2] = bc[mask]

    rgb[:, :, 0] += m
    rgb[:, :, 1] += m
    rgb[:, :, 2] += m
    return np.clip(rgb, 0, 1)


# ============================================================================
# Dark Variant
# ============================================================================

def generate_dark_variant(img_rgba):
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]

    if not np.any(alpha > 0):
        return img_rgba

    gray = np.mean(rgb, axis=2, keepdims=True)
    rgb = rgb * 0.4 + gray * 0.6
    rgb *= 0.6
    rgb[:, :, 0] *= 0.85
    rgb[:, :, 1] *= 0.90
    rgb[:, :, 2] = np.minimum(rgb[:, :, 2] * 1.15, 255)

    result = np.zeros_like(arr)
    result[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    result[:, :, 3] = alpha
    return Image.fromarray(result.astype(np.uint8), "RGBA")


# ============================================================================
# Fix: #54 Easterling Warrior — Recover sword via rembg + color merge
# ============================================================================

def fix_easterling_sword(monster_id=54):
    """Recover missing scimitar blade using rembg + color merge technique.

    The blade is bright metal on magenta BG — rembg removes it entirely.
    Fix: run rembg for body, color-extract non-magenta pixels from raw, merge.
    Then auto-crop and resize to 64x64.
    """
    print(f"\n  #{monster_id} Easterling Warrior — rembg + color merge for sword:")

    if rembg_remove is None:
        print(f"    ERROR: rembg not available")
        return False

    # Find source file
    corrected = CORRECTED_DIR / f"monster_{monster_id}_corrected.png"
    raw = RAW_DIR / f"monster_{monster_id}_1024.png"
    source = corrected if corrected.exists() else raw
    if not source.exists():
        print(f"    ERROR: No source found at {source}")
        return False

    print(f"    Source: {source.name}")
    raw_img = Image.open(source).convert("RGBA")
    raw_arr = np.array(raw_img).astype(np.float64) / 255.0

    # Step 1: rembg for body
    print(f"    Step 1: rembg extraction...")
    rembg_result = rembg_remove(raw_img)
    rembg_arr = np.array(rembg_result)
    rembg_alpha = rembg_arr[:, :, 3] > 127
    rembg_pct = 100 * np.sum(rembg_alpha) / rembg_alpha.size
    print(f"    rembg: {rembg_pct:.1f}% opaque")

    # Step 2: Color-based extraction for blade/weapon
    print(f"    Step 2: Color-based non-magenta extraction...")
    r, g, b = raw_arr[:, :, 0], raw_arr[:, :, 1], raw_arr[:, :, 2]

    # Detect magenta BG: high red, low green, high blue
    is_magenta = (r > 0.6) & (g < 0.25) & (b > 0.4)
    # Detect non-magenta content: has green channel OR is warm-toned
    is_not_magenta = (g > 0.15) | ((r > 0.3) & (b < r * 0.7))
    # Dark content (dark metals, shadows)
    brightness = (r + g + b) / 3
    is_dark_content = (brightness > 0.02) & (brightness < 0.25)

    creature_mask = (is_not_magenta | is_dark_content) & ~is_magenta

    color_pct = 100 * np.sum(creature_mask) / creature_mask.size
    print(f"    Color mask: {color_pct:.1f}% non-magenta")

    # Step 3: Merge masks
    combined = rembg_alpha | creature_mask
    from scipy.ndimage import binary_closing, binary_fill_holes
    combined = binary_fill_holes(combined)
    combined = binary_closing(combined, iterations=2)

    combined_pct = 100 * np.sum(combined) / combined.size
    print(f"    Combined: {combined_pct:.1f}% opaque")

    # Step 4: Edge cleanup — desaturate magenta-hued pixels on edges
    interior = binary_erosion(combined, iterations=3)
    edge = combined & ~interior

    hue, sat, val = compute_hsv(raw_arr[:, :, :3])
    is_edge_magenta = edge & (
        ((hue >= 280) & (hue <= 360)) | (hue < 20)
    ) & (sat > 0.25) & (val > 0.15)

    edge_count = np.sum(is_edge_magenta)
    print(f"    Edge magenta: {edge_count} px -> 95% desaturate")

    sat[is_edge_magenta] *= 0.05

    # Also desaturate interior magenta remnants
    is_interior_mag = interior & combined & (
        ((hue >= 290) & (hue <= 360)) | (hue < 10)
    ) & (sat > 0.35) & (val > 0.20)
    int_count = np.sum(is_interior_mag)
    if int_count > 0:
        print(f"    Interior magenta: {int_count} px -> 80% desaturate")
        sat[is_interior_mag] *= 0.20

    # Rebuild image
    new_rgb = hsv_to_rgb(hue, sat, val)
    output_arr = np.zeros((*raw_arr.shape[:2], 4))
    output_arr[:, :, :3] = new_rgb * 255
    output_arr[:, :, 3] = combined.astype(np.float64) * 255
    output_img = Image.fromarray(np.clip(output_arr, 0, 255).astype(np.uint8), "RGBA")

    # Step 5: Auto-crop and resize to 64x64
    bbox = output_img.getbbox()
    if bbox:
        cropped = output_img.crop(bbox)
    else:
        cropped = output_img

    # Fit into 64x64 with aspect ratio preserved
    w, h = cropped.size
    scale = min(64 / w, 64 / h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = cropped.resize((new_w, new_h), Image.NEAREST)

    # Center on 64x64 canvas
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    paste_x = (64 - new_w) // 2
    paste_y = 64 - new_h  # Bottom-align
    canvas.paste(resized, (paste_x, paste_y))

    # Save
    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    canvas.save(light_path)
    dark = generate_dark_variant(canvas)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# Fix: #57 Easterling Champion — Remove magenta blotch
# ============================================================================

def fix_champion_blotch(monster_id=57):
    """Remove magenta background blotch/square from Easterling Champion."""
    print(f"\n  #{monster_id} Easterling Champion — remove magenta blotch:")

    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Find obviously magenta pixels (high sat, magenta hue, bright enough)
    is_mag = visible & (
        ((hue >= 280) & (hue <= 360)) | (hue < 15)
    ) & (sat > 0.30) & (val > 0.15)

    count = np.sum(is_mag)
    if count == 0:
        print(f"    No magenta blotch found")
        return False

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Magenta blotch: {count} px ({pct:.1f}%)")

    # Make strongly magenta pixels transparent (they're BG remnants)
    strong_mag = visible & (
        ((hue >= 290) & (hue <= 360)) | (hue < 10)
    ) & (sat > 0.40) & (val > 0.20)

    strong_count = np.sum(strong_mag)
    if strong_count > 0:
        print(f"    Removing {strong_count} strong magenta px -> transparent")
        arr[strong_mag, 3] = 0

    # Desaturate remaining mild magenta (edge pixels)
    mild_mag = is_mag & ~strong_mag
    mild_count = np.sum(mild_mag)
    if mild_count > 0:
        print(f"    Desaturating {mild_count} mild magenta px")
        sat[mild_mag] *= 0.10
        new_rgb = hsv_to_rgb(hue, sat, val)
        arr[:, :, :3] = np.clip(new_rgb * 255, 0, 255)

    result = Image.fromarray(arr.astype(np.uint8), "RGBA")
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    result.save(light_path)
    dark = generate_dark_variant(result)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# Fix: #58 Ghast — Clean green edge artifacts
# ============================================================================

def fix_ghast_edges(monster_id=58):
    """Clean up bright green edge artifacts on Ghast.

    The Ghast has intentional green body coloring (putrid flesh), so we only
    target BRIGHT/SATURATED green pixels that are near transparent edges.
    """
    print(f"\n  #{monster_id} Ghast — green edge artifact cleanup:")

    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Find edge pixels (within 2px of transparency)
    opaque_mask = alpha > 0
    eroded = binary_erosion(opaque_mask, iterations=2)
    edge_zone = opaque_mask & ~eroded

    # Target BRIGHT green pixels on edges only (BG remnants, not body green)
    is_bright_green = edge_zone & (hue >= 80) & (hue <= 160) & (sat > 0.50) & (val > 0.40)

    count = np.sum(is_bright_green)
    if count == 0:
        print(f"    No bright green edge artifacts found")
        return False

    print(f"    Bright green edges: {count} px -> transparent")
    arr[is_bright_green, 3] = 0

    result = Image.fromarray(arr.astype(np.uint8), "RGBA")
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    result.save(light_path)
    dark = generate_dark_variant(result)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# Fix: #73 Zombie — Remove white-pink-beige halo
# ============================================================================

def fix_zombie_halo(monster_id=73):
    """Remove white-pink-beige halo around the zombie figure.

    The halo is composed of light-colored pixels around the edges that should
    be transparent. These are BG remnants that survived the pipeline.
    """
    print(f"\n  #{monster_id} Zombie — remove halo:")

    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Find edge pixels (within 3px of transparency for wider halo)
    opaque_mask = alpha > 0
    eroded = binary_erosion(opaque_mask, iterations=3)
    edge_zone = opaque_mask & ~eroded

    # Target the halo: light/bright pixels on edges with pink/beige hue
    # Pink-beige: hue 0-40 or 300-360, relatively light, low-mid saturation
    is_halo = edge_zone & (
        (
            ((hue >= 300) & (hue <= 360)) | (hue < 40)  # Pink/warm hues
        ) & (val > 0.30) & (sat < 0.60)  # Light, not deeply colored
    ) | (
        edge_zone & (val > 0.55) & (sat < 0.15)  # Also catch very light desaturated pixels (white-ish)
    )

    count = np.sum(is_halo)
    if count == 0:
        print(f"    No halo found")
        return False

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Halo pixels: {count} ({pct:.1f}%) -> transparent")
    arr[is_halo, 3] = 0

    result = Image.fromarray(arr.astype(np.uint8), "RGBA")
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    result.save(light_path)
    dark = generate_dark_variant(result)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# Fix: #80 Easterling Infiltrator — Remove pink under legs
# ============================================================================

def fix_infiltrator_pink(monster_id=80):
    """Remove pink BG remnant under the crouching infiltrator's legs.

    The pink is in the gap between/beneath the legs from the crouching pose.
    Target: magenta/pink pixels in the lower portion of the sprite.
    """
    print(f"\n  #{monster_id} Easterling Infiltrator — remove pink under legs:")

    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Target pink/magenta pixels anywhere (but especially lower half)
    is_pink = visible & (
        ((hue >= 290) & (hue <= 360)) | (hue < 20)
    ) & (sat > 0.15) & (val > 0.10)

    # Also catch desaturated pinkish pixels (the "beige-pink" the user described)
    is_light_pink = visible & (
        ((hue >= 300) & (hue <= 360)) | (hue < 30)
    ) & (val > 0.25) & (sat > 0.08) & (sat < 0.40)

    combined_pink = is_pink | is_light_pink

    count = np.sum(combined_pink)
    if count == 0:
        print(f"    No pink found")
        return False

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Pink pixels: {count} ({pct:.1f}%)")

    # Strong pink -> transparent
    strong_pink = visible & (
        ((hue >= 290) & (hue <= 360)) | (hue < 15)
    ) & (sat > 0.25) & (val > 0.15)

    strong_count = np.sum(strong_pink)
    if strong_count > 0:
        print(f"    Removing {strong_count} strong pink px -> transparent")
        arr[strong_pink, 3] = 0

    # Mild pink -> desaturate
    mild_pink = combined_pink & ~strong_pink
    mild_count = np.sum(mild_pink)
    if mild_count > 0:
        print(f"    Desaturating {mild_count} mild pink px")
        sat[mild_pink] *= 0.15
        new_rgb = hsv_to_rgb(hue, sat, val)
        # Only update the mild pink pixels
        for c in range(3):
            arr[mild_pink, c] = np.clip(new_rgb[:, :, c][mild_pink] * 255, 0, 255)

    result = Image.fromarray(arr.astype(np.uint8), "RGBA")
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    result.save(light_path)
    dark = generate_dark_variant(result)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# Main
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Tier 3 Round 2 Fixes")
    parser.add_argument("--ids", type=int, nargs="+",
                        help="Fix specific monster IDs only")
    args = parser.parse_args()

    fix_map = {
        54: fix_easterling_sword,
        57: fix_champion_blotch,
        58: fix_ghast_edges,
        73: fix_zombie_halo,
        80: fix_infiltrator_pink,
    }

    if args.ids:
        fix_ids = args.ids
    else:
        fix_ids = [54, 57, 58, 73, 80]

    print(f"\n{'='*60}")
    print(f"Tier 3 Round 2 Fixes")
    print(f"Sprites: {fix_ids}")
    print(f"{'='*60}")

    success = 0
    for mid in fix_ids:
        if mid in fix_map:
            if fix_map[mid](mid):
                success += 1
        else:
            print(f"\n  #{mid}: No fix defined")

    print(f"\n{'='*60}")
    print(f"Done: {success}/{len(fix_ids)} sprites fixed")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
