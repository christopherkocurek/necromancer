#!/usr/bin/env python3
"""
Batch Recolor - In-place tileset sprite recoloring via HSV correction.

Applies targeted HSV hue rotation / achromatic desaturation to specific tiles
in the assembled tileset PNG. No DALL-E regeneration - just color fixes.

Recolor Targets:
  A1. Scrolls (IDs 191-211) - 15 sprites -> parchment hue (38 deg)
  A2. Documents (IDs 451, 500-556) - 14 sprites -> parchment hue (38 deg)
  A3. Torches (IDs 128-131, 411) - 5 sprites -> amber/flame hue (35 deg)
  A4. Sylvan Blade (ID 59) - 1 sprite -> green hue (120 deg)
  A5. Web Spinner (Monster ID 17) - 1 sprite -> achromatic + darken
  A6. Orc Slave (Monster ID 31) - 1 sprite -> skin tone hue (80 deg)
  A7. Buckler (Item ID 43) - 1 sprite -> conservative BG removal (pass 1 only)

Usage:
    python3 batch_recolor.py           # Process all targets
    python3 batch_recolor.py --dry-run # Show what would be done without modifying

CRITICAL HSV RULES:
  - Hue-shift pink/magenta pixels toward natural colors in HSV space FIRST
  - NEVER strip R/B channels - that destroys color
  - The fix is hue rotation, not channel reduction
"""

import argparse
import sys
from pathlib import Path
from collections import deque

try:
    from PIL import Image
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
PROJECT_DIR = BASE_DIR.parent
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"

TILE_SIZE = 64
GRID_COLS = 32
GRID_ROWS = 32

# Magenta hue zone (degrees)
MAGENTA_ZONE_MIN = 275
MAGENTA_ZONE_MAX = 335
MAGENTA_CENTER = 300
MAX_BLEED_DISTANCE = 60
GAUSSIAN_SIGMA = 5


# ============================================================================
# HSV CONVERSION (proven from fix_item_magenta.py / fix_monster_magenta_v2.py)
# ============================================================================

def rgb_to_hsv(rgb_array):
    """RGB -> HSV. Input: float64 (H,W,3) 0-255. Output: (H,W,3) H=0-360, S/V=0-1."""
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
    """HSV -> RGB. Input: (H,W,3) H=0-360, S/V=0-1. Output: (H,W,3) 0-255."""
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
# MAGENTA BLEED CORRECTION (from fix_item_magenta.py, adapted for tiles)
# ============================================================================

def correct_magenta_bleed_tile(tile_img, target_hue_deg, achromatic=False, bleed_severity=1):
    """
    Fix magenta bleed on a single 64x64 tile using HSV hue rotation.

    For pixels whose hue falls in the magenta zone:
    - Chromatic: rotate hue toward target_hue_deg
    - Achromatic: desaturate to remove the pink tint
    """
    if bleed_severity == 0:
        return tile_img

    rgba = tile_img.convert("RGBA")
    arr = np.array(rgba).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    # Background mask (strict magenta)
    bg_mask = (r > 150) & (g < r * 0.55) & ((r - g) > 70) & (b > g * 0.8)
    creature_mask = ~bg_mask
    creature_count = int(np.sum(creature_mask))

    # Distance from background (EDT)
    dist = distance_transform_edt(creature_mask.astype(np.float64))
    if bleed_severity >= 2:
        bleed_range = MAX_BLEED_DISTANCE * 5.0
        bleed_factor = np.clip(1.0 - dist / bleed_range, 0, 1)
        bleed_factor = gaussian_filter(bleed_factor, sigma=GAUSSIAN_SIGMA)
        bleed_factor = np.maximum(bleed_factor, 0.6)
    else:
        bleed_range = MAX_BLEED_DISTANCE
        bleed_factor = np.clip(1.0 - dist / bleed_range, 0, 1)
        bleed_factor = gaussian_filter(bleed_factor, sigma=GAUSSIAN_SIGMA)

    # Convert to HSV
    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    # Identify magenta zone pixels
    if bleed_severity >= 2:
        in_magenta = ((hue >= 255) & (hue <= 360)) | ((hue >= 0) & (hue <= 25))
        min_sat = 0.06
    else:
        in_magenta = (hue >= MAGENTA_ZONE_MIN) & (hue <= MAGENTA_ZONE_MAX)
        min_sat = 0.12
    needs_correction = creature_mask & in_magenta & (sat > min_sat) & (bleed_factor > 0.02)

    correction_count = int(np.sum(needs_correction))
    if correction_count == 0:
        return tile_img

    # Per-pixel correction strength
    hue_dist = np.minimum(
        np.abs(hue - MAGENTA_CENTER),
        360 - np.abs(hue - MAGENTA_CENTER)
    )
    if bleed_severity >= 2:
        hue_zone_width = 52.5
    else:
        hue_zone_width = (MAGENTA_ZONE_MAX - MAGENTA_ZONE_MIN) / 2.0
    hue_weight = np.clip(1.0 - hue_dist / hue_zone_width, 0, 1)

    if bleed_severity >= 2:
        strength = np.clip(hue_weight + 0.35, 0, 1.0)
        edge_boost = np.clip(bleed_factor * 0.15, 0, 0.15)
        strength = np.clip(strength + edge_boost, 0, 1.0)
    else:
        sat_weight = np.clip(sat * 2.0, 0, 1)
        strength = hue_weight * bleed_factor * sat_weight
        strength = np.clip(strength, 0, 1)

    # Apply correction
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


def cleanup_remaining_pink_tile(tile_img, target_hue_deg, achromatic=False):
    """Post-BG aggressive pink cleanup on a tile. Wide zone: 230-360 and 0-30."""
    rgba = np.array(tile_img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    visible = alpha > 10
    visible_count = int(np.sum(visible))
    if visible_count == 0:
        return tile_img

    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    in_pink = visible & (
        ((hue >= 230) & (hue <= 360)) |
        ((hue >= 0) & (hue <= 30))
    ) & (sat > 0.06)

    pink_count = int(np.sum(in_pink))
    if pink_count == 0:
        return tile_img

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
# BG REMOVAL - Pass 1 only (conservative, for buckler A7)
# ============================================================================

def bg_remove_pass1_only(tile_img):
    """
    Conservative BG removal: pass 1 (edge flood fill) ONLY.
    Skips passes 2-3 to prevent interior hollowing on shield sprites.
    """
    arr = np.array(tile_img.convert("RGBA")).copy()
    h, w = arr.shape[:2]
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    removed = np.zeros((h, w), dtype=bool)

    def is_seed(rv, gv, bv):
        return rv > 100 and gv < rv * 0.55 and (rv - gv) > 50

    def is_spread(rv, gv, bv):
        return rv > 80 and gv < rv * 0.6 and bv > gv and (rv - gv) > 40

    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Seed from edges
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

    # 8-directional BFS flood fill
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

    total = int(np.sum(removed))
    arr[removed, 3] = 0
    return Image.fromarray(arr), total


# ============================================================================
# BRIGHTNESS MULTIPLIER (for Web Spinner darkening)
# ============================================================================

def apply_brightness_multiplier(tile_img, multiplier):
    """Multiply brightness (V channel in HSV) by a factor. Preserves alpha."""
    rgba = np.array(tile_img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    visible = alpha > 10
    if not np.any(visible):
        return tile_img

    hsv = rgb_to_hsv(rgb)
    hsv[:, :, 2] = np.where(visible, np.clip(hsv[:, :, 2] * multiplier, 0, 1.0), hsv[:, :, 2])
    new_rgb = hsv_to_rgb(hsv)

    result = rgba.copy()
    result[:, :, :3] = np.where(visible[:, :, np.newaxis], new_rgb, rgb)
    result[:, :, 3] = alpha
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


# ============================================================================
# TILE EXTRACTION / PATCHING
# ============================================================================

def extract_tile(tileset, col, row):
    """Extract a 64x64 tile from the tileset at grid position (col, row)."""
    x = col * TILE_SIZE
    y = row * TILE_SIZE
    return tileset.crop((x, y, x + TILE_SIZE, y + TILE_SIZE))


def patch_tile(tileset, col, row, tile_img):
    """Paste a 64x64 tile back into the tileset at grid position (col, row)."""
    x = col * TILE_SIZE
    y = row * TILE_SIZE
    tileset.paste(tile_img, (x, y))


# ============================================================================
# RECOLOR TARGETS
# ============================================================================

# A1: Scrolls (IDs 191-211) - coords from tile_mapper.gd
SCROLL_COORDS = [
    (25, 13),  # 191 Imprisonment
    (26, 13),  # 192 Freedom
    (27, 13),  # 193 Light
    (28, 13),  # 195 Sanctity
    (29, 13),  # 196 Understanding
    (30, 13),  # 197 Revelations
    (31, 13),  # 198 Treasures
    (0, 14),   # 199 Foes
    (1, 14),   # 200 Slumber
    (2, 14),   # 201 Majesty
    (3, 14),   # 202 Self Knowledge
    (4, 14),   # 203 Warding
    (5, 14),   # 204 Dismay
    (6, 14),   # 206 Recharging
    (7, 14),   # 210 Summoning
    (8, 14),   # 211 Shadows
]

# A2: Documents (IDs 451, 500-556) - coords from tile_mapper.gd
# Unique positions only (many share the same tile)
DOCUMENT_COORDS = [
    (14, 16),  # 451 Note (also 452-490 duplicates)
    (20, 16),  # 500 Thrain's Memory (also 501-507)
    (21, 16),  # 510 Shadow Fragment (also 511-515)
    (22, 16),  # 520 Ancient Glyph (also 521-526)
    (23, 16),  # 530 Palantir Shard (also 531-533)
    (24, 16),  # 540 Mithril Brooch
    (25, 16),  # 541 Thror's Coin
    (26, 16),  # 542 Dragon-Touched Gem
    (27, 16),  # 543 Dwarven Chronicle Page
    (28, 16),  # 544 Durin's Day Fragment
    (29, 16),  # 550 Prisoner's Account
    (30, 16),  # 552 Orc Report
    (31, 16),  # 554 Historical Fragment
    (0, 17),   # 556 Necromancer Sighting
]

# A3: Torches (IDs 128-131, 411)
TORCH_COORDS = [
    (31, 12),  # 128 Wooden Torch
    (0, 13),   # 129 Brass Lantern
    (1, 13),   # 130 Jewel-lamp
    (2, 13),   # 131 Star-glass
    (3, 16),   # 411 Mallorn Torch
]

# A4: Sylvan Blade (ID 59)
SYLVAN_BLADE_COORD = (2, 17)

# A5: Web Spinner (Monster ID 17)
WEB_SPINNER_COORD = (6, 24)

# A6: Orc Slave (Monster ID 31)
ORC_SLAVE_COORD = (12, 24)

# A7: Buckler (Item ID 43)
BUCKLER_COORD = (20, 11)


# ============================================================================
# MAIN PIPELINE
# ============================================================================

def process_all(tileset, dry_run=False):
    """Process all recolor targets. Returns count of modified tiles."""
    modified = 0

    # --- A1: Scrolls -> parchment hue ---
    print("\n=== A1: SCROLLS (parchment hue 38 deg) ===")
    for col, row in SCROLL_COORDS:
        tile = extract_tile(tileset, col, row)
        label = f"  ({col},{row})"

        corrected = correct_magenta_bleed_tile(tile, target_hue_deg=38, achromatic=False, bleed_severity=2)
        corrected = cleanup_remaining_pink_tile(corrected, target_hue_deg=38, achromatic=False)

        if not dry_run:
            patch_tile(tileset, col, row, corrected)
        print(f"{label} - done")
        modified += 1

    # --- A2: Documents -> parchment hue ---
    print("\n=== A2: DOCUMENTS (parchment hue 38 deg) ===")
    for col, row in DOCUMENT_COORDS:
        tile = extract_tile(tileset, col, row)
        label = f"  ({col},{row})"

        corrected = correct_magenta_bleed_tile(tile, target_hue_deg=38, achromatic=False, bleed_severity=2)
        corrected = cleanup_remaining_pink_tile(corrected, target_hue_deg=38, achromatic=False)

        if not dry_run:
            patch_tile(tileset, col, row, corrected)
        print(f"{label} - done")
        modified += 1

    # --- A3: Torches -> amber/flame hue ---
    print("\n=== A3: TORCHES (amber hue 35 deg) ===")
    for col, row in TORCH_COORDS:
        tile = extract_tile(tileset, col, row)
        label = f"  ({col},{row})"

        corrected = correct_magenta_bleed_tile(tile, target_hue_deg=35, achromatic=False, bleed_severity=2)
        corrected = cleanup_remaining_pink_tile(corrected, target_hue_deg=35, achromatic=False)

        if not dry_run:
            patch_tile(tileset, col, row, corrected)
        print(f"{label} - done")
        modified += 1

    # --- A4: Sylvan Blade -> green hue ---
    print("\n=== A4: SYLVAN BLADE (green hue 120 deg) ===")
    col, row = SYLVAN_BLADE_COORD
    tile = extract_tile(tileset, col, row)
    # Sylvan Blade: mild bleed, standard correction + cleanup
    corrected = correct_magenta_bleed_tile(tile, target_hue_deg=120, achromatic=False, bleed_severity=1)
    corrected = cleanup_remaining_pink_tile(corrected, target_hue_deg=120, achromatic=False)
    if not dry_run:
        patch_tile(tileset, col, row, corrected)
    print(f"  ({col},{row}) - done")
    modified += 1

    # --- A5: Web Spinner -> achromatic + darken ---
    print("\n=== A5: WEB SPINNER (achromatic + darken 0.7x) ===")
    col, row = WEB_SPINNER_COORD
    tile = extract_tile(tileset, col, row)
    # Achromatic desaturation with bleed=2
    corrected = correct_magenta_bleed_tile(tile, target_hue_deg=0, achromatic=True, bleed_severity=2)
    corrected = cleanup_remaining_pink_tile(corrected, target_hue_deg=0, achromatic=True)
    # Post-BG brightness multiplier 0.7x (darker gray)
    corrected = apply_brightness_multiplier(corrected, 0.7)
    if not dry_run:
        patch_tile(tileset, col, row, corrected)
    print(f"  ({col},{row}) - done")
    modified += 1

    # --- A6: Orc Slave -> skin tone hue ---
    print("\n=== A6: ORC SLAVE (skin tone hue 80 deg) ===")
    col, row = ORC_SLAVE_COORD
    tile = extract_tile(tileset, col, row)
    corrected = correct_magenta_bleed_tile(tile, target_hue_deg=80, achromatic=False, bleed_severity=2)
    corrected = cleanup_remaining_pink_tile(corrected, target_hue_deg=80, achromatic=False)
    if not dry_run:
        patch_tile(tileset, col, row, corrected)
    print(f"  ({col},{row}) - done")
    modified += 1

    # --- A7: Buckler -> conservative BG removal (pass 1 only) ---
    print("\n=== A7: BUCKLER (conservative BG removal, pass 1 only) ===")
    col, row = BUCKLER_COORD
    tile = extract_tile(tileset, col, row)
    corrected, removed_count = bg_remove_pass1_only(tile)
    if not dry_run:
        patch_tile(tileset, col, row, corrected)
    print(f"  ({col},{row}) - removed {removed_count} BG pixels (pass 1 only)")
    modified += 1

    return modified


def main():
    parser = argparse.ArgumentParser(description="Batch recolor tileset sprites")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be done without modifying the tileset")
    args = parser.parse_args()

    if not TILESET_PATH.exists():
        print(f"ERROR: Tileset not found at {TILESET_PATH}")
        sys.exit(1)

    print(f"{'=' * 60}")
    print(f"BATCH RECOLOR - Tileset Sprite Fix")
    print(f"{'=' * 60}")
    print(f"Tileset: {TILESET_PATH}")
    print(f"Grid: {GRID_COLS}x{GRID_ROWS}, Tile size: {TILE_SIZE}x{TILE_SIZE}")

    if args.dry_run:
        print("MODE: DRY RUN (no modifications)")

    # Load tileset
    tileset = Image.open(TILESET_PATH).convert("RGBA")
    print(f"Loaded: {tileset.size[0]}x{tileset.size[1]} {tileset.mode}")

    # Process all targets
    modified = process_all(tileset, dry_run=args.dry_run)

    # Save
    if not args.dry_run:
        # Backup first
        backup_path = TILESET_PATH.with_suffix(".pre_recolor.png")
        if not backup_path.exists():
            import shutil
            shutil.copy2(TILESET_PATH, backup_path)
            print(f"\nBackup saved: {backup_path.name}")

        tileset.save(TILESET_PATH)
        print(f"\nTileset saved: {TILESET_PATH}")
    else:
        print(f"\nDRY RUN complete - no files modified")

    print(f"\nTotal tiles recolored: {modified}")


if __name__ == "__main__":
    main()
