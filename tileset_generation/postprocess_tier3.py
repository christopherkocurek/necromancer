#!/usr/bin/env python3
"""
Post-processing fixes for Tier 3 monster sprites.

Runs on 64x64 tiles AFTER pipeline processing. Fixes:
- #55: Dark Sorcerer — restore purple robe saturation (killed by magenta cleanup)
- #59: Karvag — gentle magenta cleanup + boost red skin saturation
- #85: Tunnel Crawler — gentle magenta cleanup + restore brown/purple palette

Usage:
    python3 postprocess_tier3.py                  # Fix all
    python3 postprocess_tier3.py --ids 55 59      # Fix specific monsters
    python3 postprocess_tier3.py --review          # Generate review HTML only
"""

import argparse
import base64
import sys
from pathlib import Path
from io import BytesIO

import numpy as np
from PIL import Image

BASE_DIR = Path(__file__).parent
TIER_DIR = BASE_DIR / "monster_v3" / "tier_3"

MONSTER_NAMES = {
    52: "Ghoul", 53: "Mirk-troll", 54: "Easterling Warrior",
    55: "Dark Sorcerer", 56: "Tortured Wretch", 57: "Easterling Champion",
    58: "Ghast", 59: "Karvag the Torturer", 60: "Master Sorcerer",
    71: "Skeleton", 73: "Zombie", 80: "Easterling Infiltrator",
    85: "Tunnel Crawler",
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
    to remove BG remnants without damaging creature colors.
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


def fix_dark_sorcerer(img_rgba, monster_id):
    """Restore purple/violet robes desaturated by magenta cleanup.

    The pipeline's magenta desaturation step killed the purple robe colors.
    With SKIP_BG_CLEANUP, the rembg extraction should preserve purple.
    After gentle magenta cleanup, boost any remaining desaturated purples.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Boost purple/violet hues (220-310) that were desaturated
    is_purple = visible & (hue >= 220) & (hue <= 310) & (val > 0.08)
    # Also boost blue-gray areas that should be purple (low sat, blue-ish)
    is_desaturated_purple = visible & (hue >= 200) & (hue <= 320) & (sat < 0.25) & (val > 0.10)

    combined = is_purple | is_desaturated_purple
    count = np.sum(combined)
    if count == 0:
        print(f"    Sorcerer purple: no purple pixels found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Sorcerer purple: {count} px ({pct:.1f}%) -> saturation boost")

    # Moderate saturation boost to restore richness
    sat[combined] = np.clip(sat[combined] * 1.5 + 0.05, 0, 0.8)

    new_rgb = hsv_to_rgb(hue, sat, val)
    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def fix_karvag(img_rgba, monster_id):
    """Restore red troll skin desaturated by magenta cleanup.

    Karvag has deep red skin that the magenta pipeline interpreted as BG.
    With SKIP_BG_CLEANUP, rembg should preserve the reds. After gentle
    magenta cleanup, boost remaining reds for boss-level visual punch.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Target red/warm hues (0-40, 330-360)
    is_red = visible & (
        ((hue >= 0) & (hue <= 40)) | ((hue >= 330) & (hue <= 360))
    ) & (val > 0.08)

    # Also boost any desaturated warm tones
    is_desat_warm = visible & (
        ((hue >= 0) & (hue <= 50)) | ((hue >= 320) & (hue <= 360))
    ) & (sat < 0.20) & (val > 0.10)

    combined = is_red | is_desat_warm
    count = np.sum(combined)
    if count == 0:
        print(f"    Karvag red: no red/warm pixels found")
        return img_rgba

    pct = 100 * count / max(np.sum(visible), 1)
    print(f"    Karvag red: {count} px ({pct:.1f}%) -> saturation + value boost")

    # Aggressive saturation boost for boss impact
    sat[combined] = np.clip(sat[combined] * 1.8 + 0.08, 0, 0.85)
    val[combined] = np.clip(val[combined] * 1.15, 0, 1.0)

    new_rgb = hsv_to_rgb(hue, sat, val)
    result = arr.copy()
    result[:, :, :3] = np.clip(new_rgb * 255, 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def fix_tunnel_crawler(img_rgba, monster_id):
    """Restore brown/purple palette destroyed by magenta cleanup.

    The crawler has brown armored carapace with purple accents. With
    SKIP_BG_CLEANUP, colors should be preserved. Boost saturation
    to restore vibrancy.
    """
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    visible = alpha > 0

    hue, sat, val = compute_hsv(rgb)

    # Global mild saturation boost on all visible pixels
    count = np.sum(visible)
    print(f"    Crawler colors: {count} px -> global saturation + warmth boost")

    sat[visible] = np.clip(sat[visible] * 1.4 + 0.03, 0, 0.8)
    val[visible] = np.clip(val[visible] * 1.10, 0, 1.0)

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
    if monster_id in {55, 59, 85}:
        img = gentle_magenta_cleanup(img, monster_id)

    # Phase 2: Monster-specific color fixes
    if monster_id == 55:
        img = fix_dark_sorcerer(img, monster_id)
    elif monster_id == 59:
        img = fix_karvag(img, monster_id)
    elif monster_id == 85:
        img = fix_tunnel_crawler(img, monster_id)

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
    """Generate review HTML for all Tier 3 sprites."""
    tier_ids = [52, 53, 54, 55, 56, 57, 58, 59, 60, 71, 73, 80, 85]

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
<html><head><title>Tier 3 Monster Sprites — Post-Fix Review</title>
<style>
    body {{ background: #1a1a2e; color: #eee; font-family: monospace; padding: 20px; }}
    h1 {{ color: #4ecdc4; }}
    table {{ border-collapse: collapse; margin: 20px 0; }}
    td {{ padding: 10px; border: 1px solid #333; vertical-align: middle; text-align: center; }}
    .label {{ width: 140px; font-size: 14px; }}
    .sprite {{ background: #2a2a3e; }}
    .dark {{ background: #0a0a1e; }}
    img {{ display: block; margin: 0 auto; }}
</style></head>
<body>
<h1>Tier 3: Dark Halls — Post-Fix Review</h1>
<p>Pipeline: rembg ML BG removal + SKIP_BG_CLEANUP for #55/#59/#85 + #53 regen + post-processing</p>
<table>
<tr><th>Monster</th><th>Light (4x)</th><th>Dark (4x)</th></tr>
{"".join(rows_html)}
</table>
</body></html>'''

    review_path = BASE_DIR / "monster_t3_review_v2.html"
    with open(review_path, "w") as f:
        f.write(html)
    print(f"\nReview HTML: {review_path}")
    return review_path


def main():
    parser = argparse.ArgumentParser(description="Tier 3 Post-Processing Fixes")
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
        fix_ids = [55, 59, 85]

    print(f"\n{'='*60}")
    print(f"Tier 3 Post-Processing Fixes")
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
