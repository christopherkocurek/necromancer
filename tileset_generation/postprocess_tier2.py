#!/usr/bin/env python3
"""
Post-processing fixes for Tier 2 monster sprites.

Runs on 64x64 tiles AFTER pipeline processing. Fixes:
- #32, #33, #35, #36: Orc skin hue shift (Warcraft green -> olive/sallow Tolkien)
- #34: Warg pink spot cleanup (underside BG bleed)
- #38: Hill Troll color boost + greenish loincloth
- #51: Dark Acolyte energy recolor (purple -> yellow-orange flame)
- #32, #33, #34, #35: Gentle magenta edge cleanup (for SKIP_BG_CLEANUP sprites)

Usage:
    python3 postprocess_tier2.py                  # Fix all
    python3 postprocess_tier2.py --ids 34 38      # Fix specific monsters
    python3 postprocess_tier2.py --review          # Generate review HTML only
"""

import argparse
import base64
import sys
from pathlib import Path
from io import BytesIO

import numpy as np
from PIL import Image

BASE_DIR = Path(__file__).parent
TIER_DIR = BASE_DIR / "monster_v3" / "tier_2"

MONSTER_NAMES = {
    32: "Orc Soldier", 33: "Orc Crossbowman", 34: "Warg",
    35: "Orc Thrallmaster", 36: "Orc Captain", 37: "Warg Rider",
    38: "Hill Troll", 39: "Gashnak", 40: "Orc Warchief", 51: "Dark Acolyte",
}


# ============================================================================
# HSV Utilities
# ============================================================================

def compute_hsv(rgb):
    """Compute H, S, V from RGB array (0-1 float)."""
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
    return hue, sat, maxc  # maxc = value


def hsv_to_rgb(hue, sat, val):
    """Convert HSV arrays back to RGB array (0-1 float)."""
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
# Fix Functions
# ============================================================================

def gentle_magenta_cleanup(img_rgba, monster_id):
    """Gentle magenta cleanup for SKIP_BG_CLEANUP sprites.

    Only targets obviously magenta pixels (high sat, magenta hue)
    to remove BG remnants without damaging dark features like swords/whips.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Very selective: only obviously-magenta (high sat, bright)
    is_mag = visible & (
        ((hue >= 290) & (hue <= 360)) | (hue < 15)
    ) & (sat > 0.45) & (val > 0.25)

    count = np.sum(is_mag)
    if count == 0:
        print(f"    Gentle magenta: none found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Gentle magenta: {count} px ({pct:.1f}%) -> desaturating")

    sat[is_mag] *= 0.10
    new_rgb = hsv_to_rgb(hue, sat, val)

    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def fix_orc_skin(img_rgba, monster_id):
    """Shift orc green skin from Warcraft-bright to olive/sallow Tolkien tone.

    Targets bright green pixels and shifts them toward olive-brown:
    - Hue: shift -30 degrees (green 120 -> olive 90)
    - Saturation: reduce by 45%
    - Value: reduce by 15%
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Target bright green skin: hue 70-170, sat > 0.20, val > 0.12
    is_green = visible & (hue >= 70) & (hue <= 170) & (sat > 0.20) & (val > 0.12)

    count = np.sum(is_green)
    if count == 0:
        print(f"    Orc skin: no green pixels found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Orc skin: {count} px ({pct:.1f}%) -> olive shift")

    hue[is_green] = np.clip(hue[is_green] - 30, 50, 120)
    sat[is_green] *= 0.55
    val[is_green] *= 0.85

    new_rgb = hsv_to_rgb(hue, sat, val)

    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def fix_warg_pink(img_rgba, monster_id):
    """Remove clearly-pink BG bleed on Warg underside.

    Only targets obviously pink/magenta pixels (sat > 0.20) and makes them
    transparent. Does NOT touch desaturated body pixels — the previous version
    stripped too much of the warg's interior body color.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Only clearly pink pixels (higher sat threshold to preserve body)
    is_pink = visible & (
        ((hue >= 300) & (hue <= 360)) | (hue < 15)
    ) & (sat > 0.20) & (val > 0.15)

    count = np.sum(is_pink)
    if count == 0:
        print(f"    Warg pink: none found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Warg pink: {count} px ({pct:.1f}%) -> TRANSPARENT")

    arr[is_pink, 3] = 0
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def fix_hill_troll(img_rgba, monster_id):
    """Boost Hill Troll color and add greenish loincloth tint.

    Aggressive color restoration — the pipeline stripped color from the
    stone-gray troll body. Also tint warm/red pixels green for loincloth.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Strong global saturation boost (+50%)
    sat[visible] = np.clip(sat[visible] * 1.50, 0, 1)
    # Moderate brightness boost (+15%)
    val[visible] = np.clip(val[visible] * 1.15, 0, 1)

    # Find warm/red pixels anywhere (loincloth/cloth accents)
    # Tech expert noted "Red cloth belt" and "red loincloth" — these are warm-hued
    h, w = alpha.shape
    is_warm = visible & (
        ((hue >= 0) & (hue <= 40)) | ((hue >= 330) & (hue <= 360))
    ) & (sat > 0.05) & (val > 0.08)

    warm_count = np.sum(is_warm)
    if warm_count > 0:
        print(f"    Loincloth: {warm_count} warm px -> greenish tint")
        hue[is_warm] = 85.0  # Olive-green
        sat[is_warm] = np.clip(sat[is_warm] + 0.25, 0.20, 0.55)

    total = np.sum(visible)
    print(f"    Color boost: {total} px (+50% sat, +15% val), {warm_count} loincloth")

    new_rgb = hsv_to_rgb(hue, sat, val)
    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def fix_yellow_skin(img_rgba, monster_id):
    """Shift skin tone to vivid sickly yellow for the Thrallmaster.

    Aggressively targets all skin-toned pixels (head, hands, exposed skin)
    and shifts them to a distinct bright sickly yellow.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Wide target: olive/brown/green/warm skin pixels (hue 20-160, very low sat threshold)
    is_skin = visible & (hue >= 20) & (hue <= 160) & (sat > 0.06) & (val > 0.08)

    count = np.sum(is_skin)
    if count == 0:
        print(f"    Yellow skin: no skin pixels found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Yellow skin: {count} px ({pct:.1f}%) -> vivid sickly yellow")

    hue[is_skin] = 50.0  # Brighter sickly yellow
    sat[is_skin] = np.clip(sat[is_skin] * 1.8, 0.35, 0.85)  # Strong saturation boost
    val[is_skin] = np.clip(val[is_skin] * 1.15, 0, 1.0)  # Brighter too

    new_rgb = hsv_to_rgb(hue, sat, val)
    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def fix_acolyte_energy(img_rgba, monster_id):
    """Change Dark Acolyte energy from purple to yellow-orange flame.

    The robes have already been desaturated to blue-gray by the pipeline.
    Remaining bright purple pixels are the magical energy between hands.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Target bright purple/violet pixels (the energy glow, not the dark robes)
    is_energy = visible & (hue >= 220) & (hue <= 310) & (val > 0.35) & (sat > 0.08)

    count = np.sum(is_energy)
    if count == 0:
        print(f"    Acolyte energy: no purple glow pixels found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Acolyte energy: {count} px ({pct:.1f}%) -> yellow-orange flame")

    # Shift from purple (270) to yellow-orange (40)
    hue[is_energy] = 40.0
    sat[is_energy] = np.clip(sat[is_energy] * 1.4, 0.30, 1.0)
    val[is_energy] = np.clip(val[is_energy] * 1.15, 0, 1.0)

    new_rgb = hsv_to_rgb(hue, sat, val)

    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


# ============================================================================
# Dark Variant (matches process_monsters_v3.py)
# ============================================================================

def generate_dark_variant(img_rgba):
    """Generate dark/unlit variant: 60% desaturate, 40% darken, cool blue tint."""
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
# Main Processing
# ============================================================================

def apply_fixes(monster_id):
    """Apply all relevant fixes to a single monster sprite."""
    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"

    if not light_path.exists():
        print(f"  #{monster_id} {MONSTER_NAMES.get(monster_id, '?')}: NOT FOUND")
        return False

    name = MONSTER_NAMES.get(monster_id, f"Monster {monster_id}")
    print(f"\n  #{monster_id} {name}:")

    img = Image.open(light_path).convert("RGBA")

    # Phase 1: Gentle magenta cleanup (for SKIP_BG_CLEANUP sprites)
    if monster_id in {32}:
        img = gentle_magenta_cleanup(img, monster_id)

    # Phase 2: Orc skin desaturation
    if monster_id in {32, 35, 36}:
        img = fix_orc_skin(img, monster_id)

    # Phase 3: Monster-specific fixes
    if monster_id == 35:
        img = fix_yellow_skin(img, monster_id)
    elif monster_id == 38:
        img = fix_hill_troll(img, monster_id)
    elif monster_id == 51:
        img = fix_acolyte_energy(img, monster_id)

    # Save light + regenerate dark
    img.save(light_path)
    dark = generate_dark_variant(img)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")
    return True


# ============================================================================
# Review HTML Generator
# ============================================================================

def img_to_base64(path):
    """Convert image file to base64 data URI."""
    with open(path, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    return f"data:image/png;base64,{data}"


def generate_review_html():
    """Generate review HTML for all Tier 2 sprites."""
    tier_ids = [32, 33, 34, 35, 36, 37, 38, 39, 40, 51]

    rows_html = []
    for mid in tier_ids:
        name = MONSTER_NAMES.get(mid, f"Monster {mid}")
        light_path = TIER_DIR / f"monster_{mid}_light.png"
        dark_path = TIER_DIR / f"monster_{mid}_dark.png"

        if not light_path.exists():
            rows_html.append(f'<tr><td>#{mid} {name}</td><td colspan="2">NOT FOUND</td></tr>')
            continue

        light_b64 = img_to_base64(light_path)
        dark_b64 = img_to_base64(dark_path) if dark_path.exists() else ""

        rows_html.append(f'''<tr>
            <td class="label">#{mid}<br><b>{name}</b></td>
            <td class="sprite"><img src="{light_b64}" width="256" height="256" style="image-rendering:pixelated"></td>
            <td class="sprite dark"><img src="{dark_b64}" width="256" height="256" style="image-rendering:pixelated"></td>
        </tr>''')

    html = f'''<!DOCTYPE html>
<html><head><title>Tier 2 Monster Sprites — Post-Fix Review</title>
<style>
    body {{ background: #1a1a2e; color: #eee; font-family: monospace; padding: 20px; }}
    h1 {{ color: #e94560; }}
    table {{ border-collapse: collapse; margin: 20px 0; }}
    td {{ padding: 10px; border: 1px solid #333; vertical-align: middle; text-align: center; }}
    .label {{ width: 140px; font-size: 14px; }}
    .sprite {{ background: #2a2a3e; }}
    .dark {{ background: #0a0a1e; }}
    img {{ display: block; margin: 0 auto; }}
</style></head>
<body>
<h1>Tier 2: Lower Halls — Post-Fix Review</h1>
<p>Pipeline: rembg ML BG removal + SKIP_BG_CLEANUP + post-processing color fixes</p>
<table>
<tr><th>Monster</th><th>Light (4x)</th><th>Dark (4x)</th></tr>
{"".join(rows_html)}
</table>
</body></html>'''

    review_path = BASE_DIR / "monster_t2_review_v2.html"
    with open(review_path, "w") as f:
        f.write(html)
    print(f"\nReview HTML: {review_path}")
    return review_path


def main():
    parser = argparse.ArgumentParser(description="Tier 2 Post-Processing Fixes")
    parser.add_argument("--ids", type=int, nargs="+",
                        help="Fix specific monster IDs only")
    parser.add_argument("--review", action="store_true",
                        help="Generate review HTML only (no fixes)")
    args = parser.parse_args()

    if args.review:
        generate_review_html()
        return

    # Determine which monsters to fix
    if args.ids:
        fix_ids = args.ids
    else:
        fix_ids = [32, 35, 36, 38, 51]

    print(f"\n{'='*60}")
    print(f"Tier 2 Post-Processing Fixes")
    print(f"Sprites: {fix_ids}")
    print(f"Working dir: {TIER_DIR}")
    print(f"{'='*60}")

    success = 0
    for mid in fix_ids:
        if apply_fixes(mid):
            success += 1

    print(f"\n{'='*60}")
    print(f"Done: {success}/{len(fix_ids)} sprites fixed")
    print(f"{'='*60}")

    # Generate review HTML
    generate_review_html()


if __name__ == "__main__":
    main()
