#!/usr/bin/env python3
"""
Fix Magenta Background in Item Sprites - HSV Correction + BG Removal

Items are hard-edged objects (swords, potions, armor) so magenta bleed is
lighter than organic monsters. Pipeline:
  1. Light HSV magenta correction (category-based color defaults)
  2. 3-pass BG removal (proven from player/monster sprites)
  3. Post-BG aggressive pink cleanup
  4. Auto-crop + resize to 64x64
  5. Generate dark variant for FOV

Uses item_v2_progress.json to know which category each item belongs to.
Overwrites the light/dark 64px files that item_gen.py created (those lack BG removal).

Usage:
    python3 fix_item_magenta.py --full-all              # Process ALL items
    python3 fix_item_magenta.py --full 64 65 66         # Process specific item IDs
    python3 fix_item_magenta.py --status                # Show what's available
    python3 fix_item_magenta.py --category sword        # Process one category
"""

import argparse
import json
import sys
from pathlib import Path
from collections import deque

try:
    from PIL import Image, ImageEnhance
    import numpy as np
    from scipy.ndimage import distance_transform_edt, gaussian_filter
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install: pip3 install pillow numpy scipy")
    sys.exit(1)

# ============================================================================
# PATHS & CONSTANTS
# ============================================================================

BASE_DIR = Path(__file__).parent
RAW_DIR = BASE_DIR / "item_v2" / "raw"
OUTPUT_DIR = BASE_DIR / "item_v2"
CORRECTED_DIR = BASE_DIR / "item_v2" / "corrected"
PROGRESS_PATH = BASE_DIR / "item_v2_progress.json"

TILE_SIZE = 64

# Magenta hue zone (degrees)
MAGENTA_ZONE_MIN = 275
MAGENTA_ZONE_MAX = 335
MAGENTA_CENTER = 300
MAX_BLEED_DISTANCE = 60
GAUSSIAN_SIGMA = 5

# ============================================================================
# CATEGORY COLOR DEFAULTS
# ============================================================================
# Items are grouped by category. Each gets a default target hue for correction.
# Items are hard-edged objects, so bleed is generally mild (1).

CATEGORY_COLORS = {
    "sword":            {"hue_deg": 210, "achromatic": True,  "bleed": 1},  # steel/silver
    "polearm":          {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # wood + steel
    "hafted":           {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # wood + iron
    "bow":              {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # wood
    "body_armor":       {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # iron/steel
    "soft_armor":       {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # leather
    "shield":           {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # iron/wood
    "helm":             {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # iron
    "crown":            {"hue_deg": 45,  "achromatic": False, "bleed": 1},  # gold
    "gloves":           {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # leather
    "boots":            {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # leather
    "cloak":            {"hue_deg": 120, "achromatic": False, "bleed": 1},  # green/varied
    "ring":             {"hue_deg": 45,  "achromatic": False, "bleed": 1},  # gold/silver
    "amulet":           {"hue_deg": 45,  "achromatic": False, "bleed": 1},  # gold/gem
    "potion":           {"hue_deg": 210, "achromatic": False, "bleed": 1},  # glass bottles
    "herb":             {"hue_deg": 120, "achromatic": False, "bleed": 1},  # green plants
    "scroll":           {"hue_deg": 40,  "achromatic": False, "bleed": 1},  # parchment
    "document":         {"hue_deg": 40,  "achromatic": False, "bleed": 1},  # parchment
    "wand":             {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # wood
    "horn":             {"hue_deg": 40,  "achromatic": False, "bleed": 1},  # bone/ivory
    "light":            {"hue_deg": 40,  "achromatic": False, "bleed": 1},  # fire/glow
    "arrow":            {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # wood/steel
    "sling":            {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # leather
    "sling_stone":      {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # gray stone
    "digging":          {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # metal pick
    "chest":            {"hue_deg": 25,  "achromatic": False, "bleed": 1},  # wood/iron
    "skeleton":         {"hue_deg": 40,  "achromatic": False, "bleed": 1},  # bone
    "oil":              {"hue_deg": 35,  "achromatic": False, "bleed": 1},  # amber
    "special_material": {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # metal
    "unknown":          {"hue_deg": 0,   "achromatic": True,  "bleed": 1},  # fallback
}


# ============================================================================
# HSV CONVERSION (same proven functions as fix_monster_magenta_v2.py)
# ============================================================================

def rgb_to_hsv(rgb_array):
    arr = rgb_array / 255.0
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    hue = np.zeros_like(cmax)
    nonzero = delta > 1e-10
    mask_r = nonzero & (cmax == r)
    mask_g = nonzero & (cmax == g) & ~mask_r
    mask_b = nonzero & ~mask_r & ~mask_g

    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6.0)
    hue[mask_g] = 60.0 * ((b[mask_g] - r[mask_g]) / delta[mask_g] + 2.0)
    hue[mask_b] = 60.0 * ((r[mask_b] - g[mask_b]) / delta[mask_b] + 4.0)
    hue = hue % 360.0
    sat = np.where(cmax > 1e-10, delta / cmax, 0.0)
    return np.stack([hue, sat, cmax], axis=-1)


def hsv_to_rgb(hsv_array):
    h, s, v = hsv_array[:, :, 0], hsv_array[:, :, 1], hsv_array[:, :, 2]
    c = v * s
    h_prime = h / 60.0
    x = c * (1.0 - np.abs(h_prime % 2.0 - 1.0))
    m = v - c

    r = np.zeros_like(h)
    g = np.zeros_like(h)
    b = np.zeros_like(h)

    s0 = (h_prime >= 0) & (h_prime < 1)
    s1 = (h_prime >= 1) & (h_prime < 2)
    s2 = (h_prime >= 2) & (h_prime < 3)
    s3 = (h_prime >= 3) & (h_prime < 4)
    s4 = (h_prime >= 4) & (h_prime < 5)
    s5 = (h_prime >= 5) & (h_prime < 6)

    r[s0], g[s0], b[s0] = c[s0], x[s0], 0
    r[s1], g[s1], b[s1] = x[s1], c[s1], 0
    r[s2], g[s2], b[s2] = 0, c[s2], x[s2]
    r[s3], g[s3], b[s3] = 0, x[s3], c[s3]
    r[s4], g[s4], b[s4] = x[s4], 0, c[s4]
    r[s5], g[s5], b[s5] = c[s5], 0, x[s5]

    rgb = np.stack([r + m, g + m, b + m], axis=-1)
    return np.clip(rgb * 255.0, 0, 255)


# ============================================================================
# MAGENTA BLEED CORRECTION (lighter version for items)
# ============================================================================

def correct_magenta_bleed(img, target_hue_deg, achromatic=False, bleed_severity=1):
    """Fix magenta bleed for items. Same algorithm as monsters but lighter touch."""
    if bleed_severity == 0:
        return img

    rgba = img.convert("RGBA")
    arr = np.array(rgba).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    bg_mask = (r > 150) & (g < r * 0.55) & ((r - g) > 70) & (b > g * 0.8)
    creature_mask = ~bg_mask
    creature_count = int(np.sum(creature_mask))
    print(f"    BG: {np.sum(bg_mask):,} px | Item: {creature_count:,} px")

    dist = distance_transform_edt(creature_mask.astype(np.float64))
    bleed_range = MAX_BLEED_DISTANCE
    bleed_factor = np.clip(1.0 - dist / bleed_range, 0, 1)
    bleed_factor = gaussian_filter(bleed_factor, sigma=GAUSSIAN_SIGMA)

    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    in_magenta = (hue >= MAGENTA_ZONE_MIN) & (hue <= MAGENTA_ZONE_MAX)
    needs_correction = creature_mask & in_magenta & (sat > 0.12) & (bleed_factor > 0.02)

    correction_count = int(np.sum(needs_correction))
    if correction_count == 0:
        print("    No pixels need correction")
        return img

    pct = correction_count / max(creature_count, 1) * 100
    print(f"    Magenta zone pixels: {correction_count:,} ({pct:.1f}% of item)")

    hue_dist = np.minimum(np.abs(hue - MAGENTA_CENTER), 360 - np.abs(hue - MAGENTA_CENTER))
    hue_zone_width = (MAGENTA_ZONE_MAX - MAGENTA_ZONE_MIN) / 2.0
    hue_weight = np.clip(1.0 - hue_dist / hue_zone_width, 0, 1)
    sat_weight = np.clip(sat * 2.0, 0, 1)
    strength = hue_weight * bleed_factor * sat_weight
    strength = np.clip(strength, 0, 1)

    new_hue = hue.copy()
    new_sat = sat.copy()

    if achromatic:
        desat = strength * 0.95
        new_sat = np.where(needs_correction, sat * (1 - desat), sat)
        print(f"    Mode: achromatic desaturation")
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        new_hue = np.where(needs_correction, (hue + diff * strength) % 360, hue)
        mild_desat = strength * 0.15
        new_sat = np.where(needs_correction, sat * (1 - mild_desat), sat)
        print(f"    Mode: hue rotation -> {target_hue_deg} deg")

    new_hsv = np.stack([new_hue, new_sat, val], axis=-1)
    new_rgb = hsv_to_rgb(new_hsv)

    result_rgb = rgb.copy()
    result_rgb[needs_correction] = new_rgb[needs_correction]

    result = np.zeros_like(arr)
    result[:, :, :3] = result_rgb
    result[:, :, 3] = alpha

    print(f"    Corrected {correction_count:,} pixels")
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


# ============================================================================
# BG REMOVAL (proven 3-pass from player/monster sprites)
# ============================================================================

def bg_remove_3pass(img):
    arr = np.array(img.convert("RGBA"))
    h, w = arr.shape[:2]
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    removed = np.zeros((h, w), dtype=bool)

    def is_seed(rv, gv, bv):
        return rv > 100 and gv < rv * 0.55 and (rv - gv) > 50

    def is_spread(rv, gv, bv):
        return rv > 80 and gv < rv * 0.6 and bv > gv and (rv - gv) > 40

    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    for x in range(w):
        for y in [0, h - 1]:
            if is_seed(r[y, x], g[y, x], b[y, x]):
                queue.append((y, x))
                visited[y, x] = True
    for y in range(h):
        for x in [0, w - 1]:
            if not visited[y, x] and is_seed(r[y, x], g[y, x], b[y, x]):
                queue.append((y, x))
                visited[y, x] = True

    while queue:
        cy, cx = queue.popleft()
        removed[cy, cx] = True
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1),
                       (-1, -1), (-1, 1), (1, -1), (1, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_spread(r[ny, nx], g[ny, nx], b[ny, nx]):
                    queue.append((ny, nx))

    pass1 = int(np.sum(removed))

    for y in range(h):
        for x in range(w):
            if not removed[y, x] and a[y, x] > 0:
                rv, gv, bv = int(r[y, x]), int(g[y, x]), int(b[y, x])
                if rv > 60 and gv < rv * 0.6 and bv > gv and (rv - gv) > 30:
                    removed[y, x] = True

    pass2 = int(np.sum(removed)) - pass1

    pass3 = 0
    for _ in range(2):
        fringe = np.zeros((h, w), dtype=bool)
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if removed[y, x] or a[y, x] == 0:
                    continue
                has_neighbor = False
                for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    if removed[y + dy, x + dx]:
                        has_neighbor = True
                        break
                if has_neighbor:
                    rv, gv, bv = int(r[y, x]), int(g[y, x]), int(b[y, x])
                    if rv > 40 and gv < rv * 0.55 and bv > gv * 1.1 and (rv - gv) > 15:
                        fringe[y, x] = True
        removed |= fringe
        pass3 += int(np.sum(fringe))

    arr[removed, 3] = 0
    total = int(np.sum(removed))
    pct = total / (h * w) * 100
    print(f"    BG removed: {total:,}/{h * w:,} ({pct:.1f}%)")
    print(f"    Pass 1: {pass1:,} | Pass 2: {pass2:,} | Pass 3: {pass3:,}")
    return Image.fromarray(arr)


def cleanup_remaining_pink(img, target_hue_deg, achromatic=False):
    """Post-BG aggressive pink cleanup. Same as monster version."""
    rgba = np.array(img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    visible = alpha > 10
    visible_count = int(np.sum(visible))
    if visible_count == 0:
        return img

    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    in_pink = visible & (
        ((hue >= 230) & (hue <= 360)) |
        ((hue >= 0) & (hue <= 30))
    ) & (sat > 0.06)

    pink_count = int(np.sum(in_pink))
    if pink_count == 0:
        print(f"    Cleanup: no pink pixels found")
        return img

    pct = pink_count / max(visible_count, 1) * 100
    print(f"    Cleanup: {pink_count:,} pink pixels ({pct:.1f}% of item)")

    new_hue = hue.copy()
    new_sat = sat.copy()

    if achromatic:
        new_sat = np.where(in_pink, sat * 0.05, sat)
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        strength = 0.92
        new_hue = np.where(in_pink, (hue + diff * strength) % 360, hue)
        new_sat = np.where(in_pink & (sat > 0.4), sat * 0.8, sat)

    new_hsv = np.stack([new_hue, new_sat, val], axis=-1)
    new_rgb = hsv_to_rgb(new_hsv)

    result = rgba.copy()
    result[:, :, :3] = np.where(visible[:, :, np.newaxis], new_rgb, rgb)
    result[:, :, 3] = alpha
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


# ============================================================================
# POST-PROCESSING
# ============================================================================

def auto_crop_square(img):
    arr = np.array(img)
    if arr.shape[2] == 4:
        alpha = arr[:, :, 3]
        rows = np.any(alpha > 0, axis=1)
        cols = np.any(alpha > 0, axis=0)
    else:
        return img

    if not np.any(rows) or not np.any(cols):
        return img

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]

    pad = 4
    rmin = max(0, rmin - pad)
    rmax = min(arr.shape[0], rmax + pad + 1)
    cmin = max(0, cmin - pad)
    cmax = min(arr.shape[1], cmax + pad + 1)

    cropped = img.crop((cmin, rmin, cmax, rmax))
    w, h = cropped.size
    if w != h:
        s = max(w, h)
        sq = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        sq.paste(cropped, ((s - w) // 2, (s - h) // 2))
        cropped = sq
    return cropped


def generate_dark_variant(img):
    if img.mode == "RGBA":
        alpha = img.split()[3]
        rgb = img.convert("RGB")
    else:
        alpha = None
        rgb = img.convert("RGB")

    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)
    darkened = ImageEnhance.Brightness(desaturated).enhance(0.6)

    arr = np.array(darkened).astype(np.float32)
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, "RGB")
    if alpha is not None:
        result = result.convert("RGBA")
        result.putalpha(alpha)
    return result


# ============================================================================
# ITEM PROGRESS & CATEGORIZATION
# ============================================================================

def load_progress():
    """Load item_v2_progress.json to get category info per item."""
    if PROGRESS_PATH.exists():
        with open(PROGRESS_PATH, "r") as f:
            return json.load(f)
    return {"sprites": {}}


def get_item_info(progress):
    """Build a dict of item_id -> {category, name} from progress file."""
    items = {}
    for key, info in progress.get("sprites", {}).items():
        if info.get("status") != "completed":
            continue
        item_id = info.get("item_id")
        if item_id is None:
            continue
        # Skip duplicates that point to a canonical
        canonical = info.get("canonical_id")
        if canonical is not None and canonical != item_id:
            continue
        items[item_id] = {
            "name": info.get("name", f"item_{item_id}"),
            "category": info.get("category", "unknown"),
        }
    return items


def get_raw_ids():
    """Find all raw 1024px PNGs available."""
    ids = []
    if RAW_DIR.exists():
        for f in RAW_DIR.glob("item_*_1024.png"):
            try:
                item_id = int(f.stem.split("_")[1])
                ids.append(item_id)
            except (ValueError, IndexError):
                pass
    return sorted(ids)


# ============================================================================
# PIPELINE
# ============================================================================

def process_item(item_id, item_info):
    """Full pipeline: correct + BG remove + crop + resize + dark."""
    raw_path = RAW_DIR / f"item_{item_id}_1024.png"
    if not raw_path.exists():
        print(f"  SKIP: {raw_path.name} not found")
        return False

    info = item_info.get(item_id, {"name": f"item_{item_id}", "category": "unknown"})
    cat_name = info["category"]
    colors = CATEGORY_COLORS.get(cat_name, CATEGORY_COLORS["unknown"])

    print(f"\n  [{item_id}] {info['name']} ({cat_name})")

    img = Image.open(raw_path).convert("RGBA")

    # Step 1: Light magenta bleed correction
    print(f"    Color correction...")
    corrected = correct_magenta_bleed(
        img,
        target_hue_deg=colors["hue_deg"],
        achromatic=colors["achromatic"],
        bleed_severity=colors["bleed"],
    )

    # Save corrected (for review/debugging)
    CORRECTED_DIR.mkdir(parents=True, exist_ok=True)
    corrected.save(CORRECTED_DIR / f"item_{item_id}_corrected.png")

    # Step 2: BG removal
    print(f"    BG removal...")
    transparent = bg_remove_3pass(corrected)

    # Step 3: Post-BG pink cleanup
    print(f"    Post-BG pink cleanup...")
    cleaned = cleanup_remaining_pink(
        transparent,
        target_hue_deg=colors["hue_deg"],
        achromatic=colors["achromatic"],
    )

    # Step 4: Crop + resize
    cropped = auto_crop_square(cleaned)
    print(f"    Cropped: {cropped.size[0]}x{cropped.size[1]}")
    img_64 = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

    # Step 5: Save light variant (overwrite item_gen.py's version)
    cat_dir = OUTPUT_DIR / cat_name
    cat_dir.mkdir(parents=True, exist_ok=True)
    light_path = cat_dir / f"item_{item_id}_light.png"
    img_64.save(light_path)
    print(f"    Saved: {light_path.name}")

    # Step 6: Dark variant
    dark = generate_dark_variant(img_64)
    dark_path = cat_dir / f"item_{item_id}_dark.png"
    dark.save(dark_path)
    print(f"    Saved: {dark_path.name}")

    return True


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Fix magenta in item sprites")

    group = parser.add_mutually_exclusive_group()
    group.add_argument("--full", nargs="+", type=int, metavar="ID",
                       help="Full pipeline for specific item IDs")
    group.add_argument("--full-all", action="store_true",
                       help="Full pipeline for ALL items with raw PNGs")
    group.add_argument("--category", type=str, metavar="CAT",
                       help="Process all items in a category (e.g. sword, potion)")
    group.add_argument("--status", action="store_true",
                       help="Show available raw PNGs and categories")

    args = parser.parse_args()

    progress = load_progress()
    item_info = get_item_info(progress)

    if args.status:
        raw_ids = get_raw_ids()
        print(f"{'=' * 60}")
        print(f"ITEM SPRITE FIX STATUS")
        print(f"{'=' * 60}")
        print(f"  Raw 1024px PNGs available: {len(raw_ids)}")
        print(f"  Items in progress.json:    {len(item_info)}")

        # Group by category
        by_cat = {}
        for iid in raw_ids:
            info = item_info.get(iid, {"category": "unknown"})
            cat = info["category"]
            by_cat.setdefault(cat, []).append(iid)

        print(f"\n  By category:")
        for cat in sorted(by_cat.keys()):
            ids = by_cat[cat]
            # Check how many already have processed light files
            processed = 0
            for iid in ids:
                cat_dir = OUTPUT_DIR / cat
                light = cat_dir / f"item_{iid}_light.png"
                corr = CORRECTED_DIR / f"item_{iid}_corrected.png"
                if corr.exists():
                    processed += 1
            print(f"    {cat:20s}: {len(ids):3d} raw | {processed:3d} corrected")

        print(f"\n  Categories with color configs: {len(CATEGORY_COLORS)}")
        return

    if args.full:
        ids = args.full
        print(f"{'=' * 60}")
        print(f"FULL PIPELINE - {len(ids)} items")
        print(f"{'=' * 60}")
        ok = sum(1 for iid in ids if process_item(iid, item_info))
        print(f"\nDone: {ok}/{len(ids)} processed")

    elif args.full_all:
        ids = get_raw_ids()
        if not ids:
            print("No raw PNGs found in", RAW_DIR)
            return
        print(f"{'=' * 60}")
        print(f"FULL PIPELINE ALL ITEMS - {len(ids)} items")
        print(f"{'=' * 60}")
        ok = sum(1 for iid in ids if process_item(iid, item_info))
        print(f"\nDone: {ok}/{len(ids)} processed")

    elif args.category:
        cat = args.category
        if cat not in CATEGORY_COLORS:
            print(f"Unknown category: {cat}")
            print(f"Available: {', '.join(sorted(CATEGORY_COLORS.keys()))}")
            return
        raw_ids = get_raw_ids()
        ids = [iid for iid in raw_ids
               if item_info.get(iid, {}).get("category") == cat]
        if not ids:
            print(f"No raw PNGs found for category: {cat}")
            return
        print(f"{'=' * 60}")
        print(f"FULL PIPELINE - category '{cat}' - {len(ids)} items")
        print(f"{'=' * 60}")
        ok = sum(1 for iid in ids if process_item(iid, item_info))
        print(f"\nDone: {ok}/{len(ids)} processed")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
