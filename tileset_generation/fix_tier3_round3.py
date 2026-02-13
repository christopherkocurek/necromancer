#!/usr/bin/env python3
"""
Tier 3 Round 3 Fixes — Improved color merge for #54 and #60.

- #54 Easterling Warrior: Tighter color merge (sword only, not BG)
- #60 Master Sorcerer: Color merge on GREEN BG (rembg failed at 4.4%)

Usage:
    python3 fix_tier3_round3.py
    python3 fix_tier3_round3.py --ids 54
    python3 fix_tier3_round3.py --ids 60
"""

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import (
    binary_erosion, binary_dilation, binary_closing, binary_fill_holes,
    label as scipy_label,
)

try:
    from rembg import remove as rembg_remove
except ImportError:
    print("ERROR: rembg not available. pip3 install rembg[cpu]")
    sys.exit(1)

BASE_DIR = Path(__file__).parent
TIER_DIR = BASE_DIR / "monster_v3" / "tier_3"
RAW_DIR = BASE_DIR / "monster_v2" / "raw"
CORRECTED_DIR = BASE_DIR / "monster_v2" / "corrected"


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


def autocrop_resize(img, size=64):
    """Auto-crop transparent border and resize to size x size."""
    bbox = img.getbbox()
    if bbox:
        cropped = img.crop(bbox)
    else:
        cropped = img
    w, h = cropped.size
    scale = min(size / w, size / h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = cropped.resize((new_w, new_h), Image.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    paste_x = (size - new_w) // 2
    paste_y = size - new_h  # Bottom-align
    canvas.paste(resized, (paste_x, paste_y))
    return canvas


# ============================================================================
# #54 Easterling Warrior — Tighter color merge (sword recovery)
# ============================================================================

def fix_easterling_sword(monster_id=54):
    """Recover missing scimitar via rembg + TIGHT color merge.

    Previous attempt was too aggressive (98.7% opaque = included BG).
    This version:
    - Uses rembg mask as the base (37.8% = body)
    - Only adds BRIGHT METALLIC pixels that rembg missed (the sword blade)
    - Does NOT use is_dark_content catch-all
    - Does NOT use binary_fill_holes (that fills BG gaps)
    """
    print(f"\n  #{monster_id} Easterling Warrior — tight color merge for sword:")

    corrected = CORRECTED_DIR / f"monster_{monster_id}_corrected.png"
    raw = RAW_DIR / f"monster_{monster_id}_1024.png"
    source = corrected if corrected.exists() else raw
    if not source.exists():
        print(f"    ERROR: No source at {source}")
        return False

    print(f"    Source: {source.name}")
    raw_img = Image.open(source).convert("RGBA")
    raw_arr = np.array(raw_img).astype(np.float64) / 255.0
    r, g, b = raw_arr[:, :, 0], raw_arr[:, :, 1], raw_arr[:, :, 2]

    # Step 1: rembg for body
    print(f"    Step 1: rembg extraction...")
    rembg_result = rembg_remove(raw_img)
    rembg_arr = np.array(rembg_result)
    rembg_alpha = rembg_arr[:, :, 3] > 127
    print(f"    rembg: {100 * np.sum(rembg_alpha) / rembg_alpha.size:.1f}% opaque")

    # Step 2: TIGHT color extraction — only non-magenta, non-dark-BG pixels
    # Strict magenta detection
    is_magenta = (r > 0.55) & (g < 0.30) & (b > 0.35)
    # Non-magenta content: must have significant green channel (blade metal, armor, skin)
    is_content = (g > 0.20) & ~is_magenta
    # Also include warm metallic pixels (bronze armor, blade glint) with low blue
    is_metallic = (r > 0.35) & (b < r * 0.6) & (g > 0.10) & ~is_magenta

    creature_mask = is_content | is_metallic
    color_pct = 100 * np.sum(creature_mask) / creature_mask.size
    print(f"    Tight color mask: {color_pct:.1f}% (should be 30-50%)")

    # Step 3: Merge — rembg body + color-extracted blade/details
    combined = rembg_alpha | creature_mask
    # Close small gaps but do NOT fill holes (that would fill BG between arm and body)
    combined = binary_closing(combined, iterations=2)

    combined_pct = 100 * np.sum(combined) / combined.size
    print(f"    Combined: {combined_pct:.1f}% opaque")

    # Step 4: Fragment removal — keep only largest component + nearby fragments
    labeled, n_features = scipy_label(combined)
    if n_features > 1:
        sizes = [(labeled == i).sum() for i in range(1, n_features + 1)]
        max_size = max(sizes)
        # Keep components that are at least 2% of largest
        keep = np.zeros_like(combined)
        for i in range(1, n_features + 1):
            if sizes[i-1] >= max_size * 0.02:
                keep |= (labeled == i)
        removed = np.sum(combined) - np.sum(keep)
        print(f"    Fragments: {n_features} -> kept {np.sum([1 for s in sizes if s >= max_size * 0.02])}, removed {removed} px")
        combined = keep

    # Step 5: Edge magenta desaturation
    hue, sat, val = compute_hsv(raw_arr[:, :, :3])
    interior = binary_erosion(combined, iterations=3)
    edge = combined & ~interior

    is_edge_mag = edge & (
        ((hue >= 280) & (hue <= 360)) | (hue < 20)
    ) & (sat > 0.20) & (val > 0.10)
    print(f"    Edge magenta: {np.sum(is_edge_mag)} px -> 95% desaturate")
    sat[is_edge_mag] *= 0.05

    # Interior magenta
    is_int_mag = interior & combined & (
        ((hue >= 290) & (hue <= 360)) | (hue < 10)
    ) & (sat > 0.35) & (val > 0.15)
    if np.sum(is_int_mag) > 0:
        print(f"    Interior magenta: {np.sum(is_int_mag)} px -> 80% desaturate")
        sat[is_int_mag] *= 0.20

    # Rebuild
    new_rgb = hsv_to_rgb(hue, sat, val)
    output_arr = np.zeros((*raw_arr.shape[:2], 4))
    output_arr[:, :, :3] = new_rgb * 255
    output_arr[:, :, 3] = combined.astype(np.float64) * 255
    output_img = Image.fromarray(np.clip(output_arr, 0, 255).astype(np.uint8), "RGBA")

    # Auto-crop and resize
    result = autocrop_resize(output_img)

    # Save
    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    result.save(light_path)
    dark = generate_dark_variant(result)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# #60 Master Sorcerer — Color merge on GREEN BG (rembg failed)
# ============================================================================

def fix_master_sorcerer(monster_id=60):
    """Recover Master Sorcerer via rembg + color merge on GREEN BG.

    rembg only extracted 4.4% — the sorcerer's dark robes on green BG confused it.
    Use color-based extraction: anything not pure green is creature.
    """
    print(f"\n  #{monster_id} Master Sorcerer — color merge on GREEN BG:")

    raw = RAW_DIR / f"monster_{monster_id}_1024.png"
    if not raw.exists():
        print(f"    ERROR: No raw at {raw}")
        return False

    print(f"    Source: {raw.name}")
    raw_img = Image.open(raw).convert("RGBA")
    raw_arr = np.array(raw_img).astype(np.float64) / 255.0
    r, g, b = raw_arr[:, :, 0], raw_arr[:, :, 1], raw_arr[:, :, 2]

    # Step 1: rembg for body (may be minimal)
    print(f"    Step 1: rembg extraction...")
    rembg_result = rembg_remove(raw_img)
    rembg_arr = np.array(rembg_result)
    rembg_alpha = rembg_arr[:, :, 3] > 127
    print(f"    rembg: {100 * np.sum(rembg_alpha) / rembg_alpha.size:.1f}% opaque")

    # Step 2: Color-based extraction for GREEN BG
    # Green BG = high green, low red and blue
    is_green_bg = (g > 0.45) & (g > r * 1.4) & (g > b * 1.4)
    # Creature = anything NOT green BG
    creature_mask = ~is_green_bg

    # Also include dark content (dark robes, shadows — very important for sorcerer)
    brightness = (r + g + b) / 3
    is_dark = (brightness > 0.01) & (brightness < 0.30) & ~is_green_bg

    creature_mask = creature_mask | is_dark
    color_pct = 100 * np.sum(creature_mask) / creature_mask.size
    print(f"    Color mask (non-green): {color_pct:.1f}%")

    # Step 3: Merge
    combined = rembg_alpha | creature_mask
    combined = binary_closing(combined, iterations=2)
    # Fill holes ONLY within the creature body, not the whole image
    # Use a more targeted approach: fill holes, then intersect with dilated rembg
    if np.sum(rembg_alpha) > 100:
        # If rembg got something, use it as anchor
        dilated_rembg = binary_dilation(rembg_alpha, iterations=50)
        filled = binary_fill_holes(combined)
        # Only fill holes near the rembg body
        combined = (filled & dilated_rembg) | combined
    else:
        # rembg got nothing useful — rely on color mask only
        combined = binary_fill_holes(combined)

    combined_pct = 100 * np.sum(combined) / combined.size
    print(f"    Combined: {combined_pct:.1f}% opaque")

    # Step 4: Fragment removal
    labeled, n_features = scipy_label(combined)
    if n_features > 1:
        sizes = [(labeled == i).sum() for i in range(1, n_features + 1)]
        max_size = max(sizes)
        keep = np.zeros_like(combined)
        kept = 0
        for i in range(1, n_features + 1):
            if sizes[i-1] >= max_size * 0.02:
                keep |= (labeled == i)
                kept += 1
        print(f"    Fragments: {n_features} -> kept {kept}")
        combined = keep

    # Step 5: Edge green desaturation
    hue, sat, val = compute_hsv(raw_arr[:, :, :3])
    interior = binary_erosion(combined, iterations=3)
    edge = combined & ~interior

    is_edge_green = edge & (hue >= 80) & (hue <= 160) & (sat > 0.30) & (val > 0.20)
    print(f"    Edge green: {np.sum(is_edge_green)} px -> 95% desaturate")
    sat[is_edge_green] *= 0.05

    # Interior bright green (BG bleed, not creature green)
    is_int_green = interior & combined & (hue >= 90) & (hue <= 150) & (sat > 0.50) & (val > 0.40)
    if np.sum(is_int_green) > 0:
        print(f"    Interior green: {np.sum(is_int_green)} px -> 70% desaturate")
        sat[is_int_green] *= 0.30

    # Rebuild
    new_rgb = hsv_to_rgb(hue, sat, val)
    output_arr = np.zeros((*raw_arr.shape[:2], 4))
    output_arr[:, :, :3] = new_rgb * 255
    output_arr[:, :, 3] = combined.astype(np.float64) * 255
    output_img = Image.fromarray(np.clip(output_arr, 0, 255).astype(np.uint8), "RGBA")

    # Auto-crop and resize
    result = autocrop_resize(output_img)

    # Save
    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
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
    parser = argparse.ArgumentParser(description="Tier 3 Round 3 Fixes")
    parser.add_argument("--ids", type=int, nargs="+")
    args = parser.parse_args()

    fix_map = {
        54: fix_easterling_sword,
        60: fix_master_sorcerer,
    }

    fix_ids = args.ids if args.ids else [54, 60]

    print(f"\n{'='*60}")
    print(f"Tier 3 Round 3 — Color Merge Fixes")
    print(f"Sprites: {fix_ids}")
    print(f"{'='*60}")

    success = 0
    for mid in fix_ids:
        if mid in fix_map:
            if fix_map[mid](mid):
                success += 1

    print(f"\n{'='*60}")
    print(f"Done: {success}/{len(fix_ids)} sprites fixed")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
