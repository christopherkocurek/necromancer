#!/usr/bin/env python3
"""
Fix Magenta Background in Artefact Category Sprites

Processes the 19 category sprites from artefact_gen.py:
  1. HSV magenta correction (category-specific colors)
  2. 3-pass BG removal
  3. Post-BG pink cleanup
  4. Auto-crop + resize to 64x64
  5. Generate dark variant

Usage:
    python3 fix_artefact_magenta.py --all          # Process ALL 19 categories
    python3 fix_artefact_magenta.py --single 0 8   # Process specific category IDs
"""

import argparse
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

BASE_DIR = Path(__file__).parent
RAW_DIR = BASE_DIR / "artefact_v2" / "raw"
OUTPUT_DIR = BASE_DIR / "artefact_v2"
TILE_SIZE = 64

MAGENTA_ZONE_MIN = 275
MAGENTA_ZONE_MAX = 335
MAGENTA_CENTER = 300
MAX_BLEED_DISTANCE = 60
GAUSSIAN_SIGMA = 5

# Category color configs for HSV correction
CATEGORY_COLORS = {
    0:  {"name": "sword",        "hue_deg": 210, "achromatic": True},   # steel
    1:  {"name": "axe",          "hue_deg": 0,   "achromatic": True},   # iron
    2:  {"name": "spear",        "hue_deg": 25,  "achromatic": False},  # wood+steel
    3:  {"name": "staff",        "hue_deg": 25,  "achromatic": False},  # wood
    4:  {"name": "hammer",       "hue_deg": 0,   "achromatic": True},   # iron
    5:  {"name": "pickaxe",      "hue_deg": 25,  "achromatic": False},  # wood+metal
    6:  {"name": "bow",          "hue_deg": 25,  "achromatic": False},  # wood
    7:  {"name": "arrow",        "hue_deg": 25,  "achromatic": False},  # wood+steel
    8:  {"name": "ring",         "hue_deg": 45,  "achromatic": False},  # gold
    9:  {"name": "amulet",       "hue_deg": 45,  "achromatic": False},  # gold/gem
    10: {"name": "robe",         "hue_deg": 25,  "achromatic": False},  # cloth
    11: {"name": "mail",         "hue_deg": 0,   "achromatic": True},   # iron
    12: {"name": "shield",       "hue_deg": 210, "achromatic": False},  # blue/iron
    13: {"name": "helm",         "hue_deg": 0,   "achromatic": True},   # iron
    14: {"name": "crown",        "hue_deg": 45,  "achromatic": False},  # gold
    15: {"name": "cloak",        "hue_deg": 120, "achromatic": False},  # green
    16: {"name": "boots",        "hue_deg": 25,  "achromatic": False},  # leather
    17: {"name": "gloves",       "hue_deg": 25,  "achromatic": False},  # leather
    18: {"name": "light_source", "hue_deg": 40,  "achromatic": False},  # warm glow
}


# ============================================================================
# HSV CONVERSION
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
    r = np.zeros_like(h); g = np.zeros_like(h); b = np.zeros_like(h)
    s0 = (h_prime >= 0) & (h_prime < 1); s1 = (h_prime >= 1) & (h_prime < 2)
    s2 = (h_prime >= 2) & (h_prime < 3); s3 = (h_prime >= 3) & (h_prime < 4)
    s4 = (h_prime >= 4) & (h_prime < 5); s5 = (h_prime >= 5) & (h_prime < 6)
    r[s0], g[s0], b[s0] = c[s0], x[s0], 0
    r[s1], g[s1], b[s1] = x[s1], c[s1], 0
    r[s2], g[s2], b[s2] = 0, c[s2], x[s2]
    r[s3], g[s3], b[s3] = 0, x[s3], c[s3]
    r[s4], g[s4], b[s4] = x[s4], 0, c[s4]
    r[s5], g[s5], b[s5] = c[s5], 0, x[s5]
    rgb = np.stack([r + m, g + m, b + m], axis=-1)
    return np.clip(rgb * 255.0, 0, 255)


# ============================================================================
# MAGENTA BLEED CORRECTION
# ============================================================================

def correct_magenta_bleed(img, target_hue_deg, achromatic=False):
    rgba = img.convert("RGBA")
    arr = np.array(rgba).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    bg_mask = (r > 150) & (g < r * 0.55) & ((r - g) > 70) & (b > g * 0.8)
    creature_mask = ~bg_mask
    creature_count = int(np.sum(creature_mask))
    print(f"    BG: {np.sum(bg_mask):,} px | Object: {creature_count:,} px")

    dist = distance_transform_edt(creature_mask.astype(np.float64))
    bleed_factor = np.clip(1.0 - dist / MAX_BLEED_DISTANCE, 0, 1)
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
    print(f"    Magenta pixels: {correction_count:,} ({pct:.1f}%)")

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
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        new_hue = np.where(needs_correction, (hue + diff * strength) % 360, hue)
        mild_desat = strength * 0.15
        new_sat = np.where(needs_correction, sat * (1 - mild_desat), sat)

    new_hsv = np.stack([new_hue, new_sat, val], axis=-1)
    new_rgb = hsv_to_rgb(new_hsv)
    result_rgb = rgb.copy()
    result_rgb[needs_correction] = new_rgb[needs_correction]
    result = np.zeros_like(arr)
    result[:, :, :3] = result_rgb
    result[:, :, 3] = alpha
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


# ============================================================================
# BG REMOVAL (3-pass flood fill)
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
                queue.append((y, x)); visited[y, x] = True
    for y in range(h):
        for x in [0, w - 1]:
            if not visited[y, x] and is_seed(r[y, x], g[y, x], b[y, x]):
                queue.append((y, x)); visited[y, x] = True

    while queue:
        cy, cx = queue.popleft()
        removed[cy, cx] = True
        for dy, dx in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
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
                for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
                    if removed[y + dy, x + dx]:
                        has_neighbor = True; break
                if has_neighbor:
                    rv, gv, bv = int(r[y, x]), int(g[y, x]), int(b[y, x])
                    if rv > 40 and gv < rv * 0.55 and bv > gv * 1.1 and (rv - gv) > 15:
                        fringe[y, x] = True
        removed |= fringe
        pass3 += int(np.sum(fringe))

    arr[removed, 3] = 0
    total = int(np.sum(removed))
    pct = total / (h * w) * 100
    print(f"    BG removed: {total:,}/{h*w:,} ({pct:.1f}%)")
    return Image.fromarray(arr)


def cleanup_remaining_pink(img, target_hue_deg, achromatic=False):
    rgba = np.array(img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]
    visible = alpha > 10
    visible_count = int(np.sum(visible))
    if visible_count == 0:
        return img

    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
    in_pink = visible & (((hue >= 230) & (hue <= 360)) | ((hue >= 0) & (hue <= 30))) & (sat > 0.06)
    pink_count = int(np.sum(in_pink))
    if pink_count == 0:
        print(f"    Cleanup: no pink pixels")
        return img

    pct = pink_count / max(visible_count, 1) * 100
    print(f"    Cleanup: {pink_count:,} pink ({pct:.1f}%)")

    new_hue = hue.copy()
    new_sat = sat.copy()
    if achromatic:
        new_sat = np.where(in_pink, sat * 0.05, sat)
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        new_hue = np.where(in_pink, (hue + diff * 0.92) % 360, hue)
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
    rmin = max(0, rmin - pad); rmax = min(arr.shape[0], rmax + pad + 1)
    cmin = max(0, cmin - pad); cmax = min(arr.shape[1], cmax + pad + 1)
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
        alpha = img.split()[3]; rgb = img.convert("RGB")
    else:
        alpha = None; rgb = img.convert("RGB")
    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)
    darkened = ImageEnhance.Brightness(desaturated).enhance(0.6)
    arr = np.array(darkened).astype(np.float32)
    arr[:, :, 0] *= 0.85; arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    result = Image.fromarray(arr, "RGB")
    if alpha is not None:
        result = result.convert("RGBA"); result.putalpha(alpha)
    return result


# ============================================================================
# PIPELINE
# ============================================================================

def process_category(cat_id):
    cfg = CATEGORY_COLORS.get(cat_id)
    if not cfg:
        print(f"  Unknown category ID: {cat_id}")
        return False

    name = cfg["name"]
    raw_path = RAW_DIR / f"artefact_{cat_id}_{name}_1024.png"
    if not raw_path.exists():
        print(f"  SKIP: {raw_path.name} not found")
        return False

    print(f"\n  [{cat_id}] {name}")
    img = Image.open(raw_path).convert("RGBA")

    # Step 1: HSV correction
    print(f"    HSV correction...")
    corrected = correct_magenta_bleed(img, cfg["hue_deg"], cfg["achromatic"])

    # Step 2: BG removal
    print(f"    BG removal...")
    transparent = bg_remove_3pass(corrected)

    # Step 3: Pink cleanup
    print(f"    Pink cleanup...")
    cleaned = cleanup_remaining_pink(transparent, cfg["hue_deg"], cfg["achromatic"])

    # Step 4: Crop + resize
    cropped = auto_crop_square(cleaned)
    print(f"    Cropped: {cropped.size[0]}x{cropped.size[1]}")
    img_64 = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

    # Step 5: Save light
    light_path = OUTPUT_DIR / f"artefact_{cat_id}_{name}_light.png"
    img_64.save(light_path)
    print(f"    Saved: {light_path.name}")

    # Step 6: Dark variant
    dark = generate_dark_variant(img_64)
    dark_path = OUTPUT_DIR / f"artefact_{cat_id}_{name}_dark.png"
    dark.save(dark_path)
    print(f"    Saved: {dark_path.name}")

    return True


def main():
    parser = argparse.ArgumentParser(description="Fix magenta in artefact category sprites")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all", action="store_true", help="Process all 19 categories")
    group.add_argument("--single", nargs="+", type=int, help="Process specific category IDs")
    args = parser.parse_args()

    ids = list(range(19)) if args.all else args.single
    print(f"{'=' * 60}")
    print(f"ARTEFACT BG REMOVAL - {len(ids)} categories")
    print(f"{'=' * 60}")

    ok = sum(1 for cid in ids if process_category(cid))
    print(f"\nDone: {ok}/{len(ids)} processed")


if __name__ == "__main__":
    main()
