#!/usr/bin/env python3
"""
fix_item_multicolor.py — Multi-color adaptive background removal for item sprites.

Replaces the single-hue fix_item_magenta.py with a color-agnostic approach that
handles gold/amber, blue/navy, green, white/cream, and magenta backgrounds.

Pipeline per tile:
  1. Load raw 1024x1024 DALL-E sprite
  2. Adaptive border-seeded flood fill (color-agnostic BG removal)
  3. Particle removal (connected components < threshold)
  4. Color fringe desaturation on subject edges
  5. Alpha erosion for halo cleanup
  6. Auto-crop to content bounds + square padding
  7. Nearest-neighbor resize to 64x64
  8. Paste into game tileset

Usage:
  python fix_item_multicolor.py                        # All categories
  python fix_item_multicolor.py --category bg_removal  # Specific category
  python fix_item_multicolor.py --ids 1,2,3            # Specific item IDs
  python fix_item_multicolor.py --dry-run              # Preview only
"""

import numpy as np
from PIL import Image
from scipy.ndimage import label, binary_erosion, distance_transform_edt
from collections import deque
from pathlib import Path
import shutil, sys, argparse, time

# === Paths ===
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
RAW_DIR = SCRIPT_DIR / "item_v2" / "raw"
OUTPUT_DIR = SCRIPT_DIR / "item_v2" / "multicolor_fixed"
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
BACKUP_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.pre_multicolor.png"

TILE_SIZE = 64

# === Tile Catalogue (from TILE_CLEANUP_CATALOGUE.md) ===
# Format: item_id -> (row, col) on tileset grid

BG_REMOVAL = {
    # Gold/Amber backgrounds
    1: (11, 1), 19: (11, 7), 20: (11, 8), 22: (11, 10), 23: (11, 11),
    26: (11, 12), 27: (11, 13), 41: (11, 18),
    72: (12, 0), 74: (12, 1), 76: (12, 2), 77: (12, 3), 81: (12, 4),
    86: (12, 5), 89: (12, 6), 101: (12, 10), 102: (12, 11), 104: (12, 13),
    110: (12, 18), 111: (12, 19), 112: (12, 20), 116: (12, 21), 118: (12, 22),
    119: (12, 23), 122: (12, 25), 123: (12, 26), 124: (12, 27), 125: (12, 28),
    127: (12, 30), 128: (12, 31),
    129: (13, 0), 130: (13, 1), 131: (13, 2), 132: (13, 3), 134: (13, 5),
    136: (13, 7), 150: (13, 11), 151: (13, 12), 155: (13, 16), 156: (13, 17),
    158: (13, 19), 159: (13, 20), 160: (13, 21), 162: (13, 23), 171: (13, 24),
    191: (13, 25), 192: (13, 26), 195: (13, 28), 197: (13, 30), 198: (13, 31),
    199: (14, 0), 200: (14, 1), 201: (14, 2), 202: (14, 3), 203: (14, 4),
    206: (14, 6), 210: (14, 7), 211: (14, 8),
    220: (14, 9), 221: (14, 10), 223: (14, 12), 224: (14, 13), 225: (14, 14),
    240: (14, 15), 241: (14, 16), 242: (14, 17), 243: (14, 18), 251: (14, 20),
    530: (16, 23), 554: (16, 31), 402: (15, 31),
    # Blue/Navy backgrounds
    313: (14, 21), 315: (14, 22), 316: (14, 23), 317: (14, 24), 318: (14, 25),
    320: (14, 27), 321: (14, 28), 322: (14, 29), 323: (14, 30), 324: (14, 31),
    327: (15, 0), 328: (15, 1), 329: (15, 2), 330: (15, 3),
    343: (15, 4), 344: (15, 5), 345: (15, 6), 346: (15, 7), 348: (15, 8),
    350: (15, 9),
    # Green backgrounds
    107: (12, 15), 108: (12, 16),
    380: (15, 17), 381: (15, 18), 382: (15, 19), 383: (15, 20), 384: (15, 21),
    386: (15, 23), 387: (15, 24), 388: (15, 25), 389: (15, 26), 390: (15, 27),
    399: (15, 28), 400: (15, 29), 401: (15, 30),
    403: (16, 0), 404: (16, 1), 412: (16, 4), 413: (16, 5), 414: (16, 6),
    418: (16, 10),
}

EDGE_CLEANUP = {
    38: (11, 16), 46: (11, 22), 68: (11, 28),
    109: (12, 17), 126: (12, 29), 543: (16, 27),
}

MULTI_PASS = {
    106: (12, 14), 138: (13, 9), 204: (14, 5),
    250: (14, 19), 319: (14, 26),
}

# Items with green subjects — use tighter tolerance to avoid eating subject
GREEN_SUBJECT_IDS = {
    107, 108, 380, 381, 382, 383, 384, 386, 387, 388, 389, 390,
    399, 400, 401, 403, 404, 412, 413, 414, 418,
}


# === Color Conversion ===

def rgb_to_hsv(rgb):
    """Vectorized RGB (0-255 float) -> HSV (H:0-360, S/V:0-1)."""
    rgb_n = rgb / 255.0
    r, g, b = rgb_n[..., 0], rgb_n[..., 1], rgb_n[..., 2]
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin + 1e-10

    h = np.zeros_like(r)
    mask_r = (cmax == r)
    mask_g = (cmax == g) & ~mask_r
    mask_b = ~mask_r & ~mask_g
    h[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6)
    h[mask_g] = 60.0 * ((b[mask_g] - r[mask_g]) / delta[mask_g] + 2)
    h[mask_b] = 60.0 * ((r[mask_b] - g[mask_b]) / delta[mask_b] + 4)

    s = np.where(cmax > 1e-10, (cmax - cmin) / (cmax + 1e-10), 0.0)
    return np.stack([h, s, cmax], axis=-1)


def hsv_to_rgb(hsv):
    """Vectorized HSV (H:0-360, S/V:0-1) -> RGB (0-255)."""
    h, s, v = hsv[..., 0] / 60.0, hsv[..., 1], hsv[..., 2]
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)

    conditions = [i == 0, i == 1, i == 2, i == 3, i == 4, i == 5]
    r = np.select(conditions, [v, q, p, p, t, v])
    g = np.select(conditions, [t, v, v, q, p, p])
    b = np.select(conditions, [p, p, t, v, v, q])
    return np.stack([r, g, b], axis=-1) * 255.0


# === Background Detection ===

def detect_background_color(arr):
    """
    Detect dominant background color from border pixels.
    Returns (median_rgb, auto_tolerance) or None if insufficient border data.
    """
    h, w = arr.shape[:2]
    alpha = arr[:, :, 3]
    rgb = arr[:, :, :3].astype(np.float64)

    # Collect opaque border pixels (3px border band)
    border_mask = np.zeros((h, w), dtype=bool)
    border_mask[:3, :] = True
    border_mask[-3:, :] = True
    border_mask[:, :3] = True
    border_mask[:, -3:] = True
    border_opaque = border_mask & (alpha > 128)

    count = border_opaque.sum()
    if count < 20:
        return None

    border_rgb = rgb[border_opaque]

    # Median is more robust than mean against outliers
    median_color = np.median(border_rgb, axis=0)

    # Estimate spread: use 75th percentile of distances
    distances = np.sqrt(np.sum((border_rgb - median_color) ** 2, axis=1))
    p75 = np.percentile(distances, 75)

    # Auto tolerance: at least 40, scaled from border spread
    auto_tol = max(p75 * 1.8, 40.0)
    return median_color, auto_tol


def detect_secondary_bg(arr, primary_removed):
    """
    After primary BG removal, check if there's a secondary background color
    visible on remaining border pixels. Useful for gradient backgrounds.
    """
    h, w = arr.shape[:2]
    alpha = arr[:, :, 3]
    rgb = arr[:, :, :3].astype(np.float64)

    border_mask = np.zeros((h, w), dtype=bool)
    border_mask[:3, :] = True
    border_mask[-3:, :] = True
    border_mask[:, :3] = True
    border_mask[:, -3:] = True
    remaining_border = border_mask & (alpha > 128) & ~primary_removed

    count = remaining_border.sum()
    if count < 15:
        return None

    border_rgb = rgb[remaining_border]
    median_color = np.median(border_rgb, axis=0)
    distances = np.sqrt(np.sum((border_rgb - median_color) ** 2, axis=1))
    p75 = np.percentile(distances, 75)
    auto_tol = max(p75 * 1.5, 35.0)
    return median_color, auto_tol


# === Flood Fill Background Removal ===

def flood_fill_bg_remove(arr, bg_color, seed_tolerance, spread_tolerance):
    """
    Edge-only flood fill BG removal. Color-agnostic.

    Seeds from border pixels matching bg_color within seed_tolerance.
    Spreads to 8-connected neighbors within spread_tolerance of bg_color.

    Returns (modified_array, removed_mask).
    """
    h, w = arr.shape[:2]
    result = arr.copy()
    rgb = arr[:, :, :3].astype(np.float64)
    alpha = arr[:, :, 3]

    visited = np.zeros((h, w), dtype=bool)
    removed = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Precompute per-pixel distance to background color (vectorized)
    dist_map = np.sqrt(np.sum((rgb - bg_color.reshape(1, 1, 3)) ** 2, axis=2))

    # Seed from border pixels (2px band)
    for y in range(h):
        for x in range(w):
            is_border = (y < 2 or y >= h - 2 or x < 2 or x >= w - 2)
            if not is_border:
                continue
            visited[y, x] = True
            if alpha[y, x] < 10:
                removed[y, x] = True
                queue.append((y, x))
            elif dist_map[y, x] < seed_tolerance:
                removed[y, x] = True
                queue.append((y, x))

    # 8-directional BFS
    dirs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

    while queue:
        cy, cx = queue.popleft()
        for dy, dx in dirs:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if alpha[ny, nx] < 10:
                    removed[ny, nx] = True
                    queue.append((ny, nx))
                elif dist_map[ny, nx] < spread_tolerance:
                    removed[ny, nx] = True
                    queue.append((ny, nx))

    result[removed, 3] = 0
    return result, removed


# === Post-Processing ===

def remove_small_islands(arr, min_area=80):
    """Remove small disconnected opaque regions (particles/sparkles)."""
    result = arr.copy()
    alpha = result[:, :, 3]
    opaque = alpha > 0

    labeled, num_features = label(opaque)
    if num_features <= 1:
        return result, 0

    # Find component sizes
    component_sizes = []
    for i in range(1, num_features + 1):
        size = int(np.sum(labeled == i))
        component_sizes.append((size, i))

    removed_count = 0
    for size, label_id in component_sizes:
        if size < min_area:
            mask = labeled == label_id
            result[mask, 3] = 0
            removed_count += 1

    return result, removed_count


def desaturate_fringe(arr, strength=0.4, width=3):
    """Desaturate pixels near transparent edge to reduce color fringe."""
    result = arr.copy()
    alpha = result[:, :, 3]
    rgb = result[:, :, :3].astype(np.float64)

    opaque = alpha > 0
    if not opaque.any():
        return result

    # Distance from transparent edge
    dist = distance_transform_edt(opaque)

    # Only affect pixels within `width` of edge
    fringe_mask = (dist > 0) & (dist <= width)
    if not fringe_mask.any():
        return result

    # Convert to HSV
    hsv = rgb_to_hsv(rgb)

    # Reduce saturation proportionally: closer to edge = more desaturation
    fringe_factor = np.ones_like(dist)
    fringe_factor[fringe_mask] = 1.0 - strength * (1.0 - dist[fringe_mask] / width)
    hsv[:, :, 1] *= fringe_factor

    # Convert back
    new_rgb = hsv_to_rgb(hsv)
    result[:, :, :3] = np.clip(new_rgb, 0, 255).astype(np.uint8)
    return result


def erode_alpha_fringe(arr, iterations=1):
    """Erode semi-transparent edges to remove halos."""
    result = arr.copy()
    alpha = result[:, :, 3]
    opaque = alpha > 0

    if not opaque.any():
        return result

    eroded = binary_erosion(opaque, iterations=iterations)
    fringe = opaque & ~eroded
    result[fringe, 3] = 0
    return result


def auto_crop_square(img, pad=4):
    """Crop to content bounds, pad to square."""
    arr = np.array(img)
    alpha = arr[:, :, 3]

    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)

    if not rows.any() or not cols.any():
        return img

    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]

    # Apply padding (clamp to image bounds)
    h, w = arr.shape[:2]
    y_min = max(0, y_min - pad)
    y_max = min(h - 1, y_max + pad)
    x_min = max(0, x_min - pad)
    x_max = min(w - 1, x_max + pad)

    cropped = img.crop((x_min, y_min, x_max + 1, y_max + 1))

    # Pad to square
    cw, ch = cropped.size
    size = max(cw, ch)
    square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    square.paste(cropped, ((size - cw) // 2, (size - ch) // 2))
    return square


# === Processing Pipelines ===

def process_bg_removal(item_id, raw_path, is_green_subject=False):
    """
    Full BG removal pipeline for one tile.
    Self-healing: retries with tighter tolerance if too much subject is removed.
    Returns processed 64x64 RGBA image and stats dict.
    """
    img = Image.open(raw_path).convert("RGBA")
    arr_original = np.array(img)
    total_pixels = arr_original.shape[0] * arr_original.shape[1]
    total_opaque_before = int(np.sum(arr_original[:, :, 3] > 0))

    # 1. Detect background color
    bg_info = detect_background_color(arr_original)
    if bg_info is None:
        return None, {"status": "SKIP", "reason": "no background detected"}

    bg_color, auto_tolerance = bg_info
    bg_str = f"({bg_color[0]:.0f},{bg_color[1]:.0f},{bg_color[2]:.0f})"

    # Self-healing retry loop: try progressively tighter tolerances
    MIN_SUBJECT_RATIO = 0.08  # At least 8% of pixels should remain opaque
    tolerance_scales = [1.0, 0.65, 0.45] if not is_green_subject else [0.7, 0.5, 0.35]
    best_result = None
    best_stats = None

    for attempt, scale in enumerate(tolerance_scales):
        arr = arr_original.copy()

        if is_green_subject:
            seed_tol = min(auto_tolerance * scale * 1.1, 50)
            spread_tol = seed_tol * 0.65
        else:
            seed_tol = auto_tolerance * scale * 1.2
            spread_tol = auto_tolerance * scale * 0.8

        # Cap spread tolerance to avoid eating subjects
        spread_tol = min(spread_tol, 55)

        # 2. Primary flood fill BG removal
        arr, removed_primary = flood_fill_bg_remove(arr, bg_color, seed_tol, spread_tol)

        # 3. Secondary background (only on first attempt, skip if retrying)
        removed_secondary_count = 0
        if attempt == 0:
            secondary = detect_secondary_bg(arr, removed_primary)
            if secondary is not None:
                sec_color, sec_tol = secondary
                sec_seed = sec_tol * 1.1
                sec_spread = sec_tol * 0.75
                arr, removed_sec = flood_fill_bg_remove(arr, sec_color, sec_seed, sec_spread)
                removed_secondary_count = int(removed_sec.sum())

        # 4. Remove particles (adaptive threshold based on attempt)
        particle_min = 150 if is_green_subject else (80 if attempt == 0 else 200)
        arr, particles_removed = remove_small_islands(arr, min_area=particle_min)

        # Check subject survival
        opaque_after_removal = int(np.sum(arr[:, :, 3] > 0))
        subject_ratio = opaque_after_removal / total_pixels

        if subject_ratio >= MIN_SUBJECT_RATIO:
            # 5. Desaturate fringe
            arr = desaturate_fringe(arr, strength=0.4, width=3)

            # 6. Alpha erosion (1 pixel for halos)
            arr = erode_alpha_fringe(arr, iterations=1)

            total_opaque_after = int(np.sum(arr[:, :, 3] > 0))
            removed_pct = 100.0 * (1 - total_opaque_after / max(total_opaque_before, 1))

            # 7. Crop and resize
            result_img = Image.fromarray(arr)
            result_img = auto_crop_square(result_img, pad=4)
            result_img = result_img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

            stats = {
                "status": "OK",
                "bg_color": bg_str,
                "seed_tol": f"{seed_tol:.0f}",
                "spread_tol": f"{spread_tol:.0f}",
                "removed_pct": f"{removed_pct:.1f}%",
                "secondary_removed": removed_secondary_count,
                "particles_removed": particles_removed,
                "green_subject": is_green_subject,
                "attempt": attempt + 1,
            }
            return result_img, stats
        else:
            # Too aggressive, save as fallback and retry tighter
            if best_result is None or subject_ratio > 0:
                best_result = arr.copy()
                best_stats = {
                    "seed_tol": seed_tol, "spread_tol": spread_tol,
                    "subject_ratio": subject_ratio, "attempt": attempt + 1
                }

    # All attempts too aggressive — use the least-bad result
    if best_result is not None:
        arr = best_result
        arr = desaturate_fringe(arr, strength=0.4, width=3)
        arr = erode_alpha_fringe(arr, iterations=1)
        total_opaque_after = int(np.sum(arr[:, :, 3] > 0))
        removed_pct = 100.0 * (1 - total_opaque_after / max(total_opaque_before, 1))

        result_img = Image.fromarray(arr)
        result_img = auto_crop_square(result_img, pad=4)
        result_img = result_img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

        stats = {
            "status": "WARN_OVERSTRIP",
            "bg_color": bg_str,
            "seed_tol": f"{best_stats['seed_tol']:.0f}",
            "spread_tol": f"{best_stats['spread_tol']:.0f}",
            "removed_pct": f"{removed_pct:.1f}%",
            "subject_ratio": f"{best_stats['subject_ratio']:.3f}",
            "attempt": best_stats['attempt'],
            "green_subject": is_green_subject,
        }
        return result_img, stats

    return None, {"status": "FAIL", "reason": "all attempts over-stripped"}


def process_edge_cleanup(item_id, tileset, row, col):
    """
    Edge cleanup for tiles with minor halo/glow issues.
    Extracts from tileset, cleans edges, returns 64x64 image.
    """
    x, y = col * TILE_SIZE, row * TILE_SIZE
    tile = tileset.crop((x, y, x + TILE_SIZE, y + TILE_SIZE)).copy()
    arr = np.array(tile)

    # Desaturate fringe (stronger for edge cleanup)
    arr = desaturate_fringe(arr, strength=0.6, width=2)

    # Light alpha erosion
    arr = erode_alpha_fringe(arr, iterations=1)

    stats = {"status": "OK", "type": "edge_cleanup"}
    return Image.fromarray(arr), stats


def process_multi_pass(item_id, raw_path):
    """
    Multi-pass treatment for complex tiles.
    More aggressive BG removal + particle cleanup.
    """
    img = Image.open(raw_path).convert("RGBA")
    arr = np.array(img)
    total_opaque_before = int(np.sum(arr[:, :, 3] > 0))

    bg_info = detect_background_color(arr)
    if bg_info is None:
        return None, {"status": "SKIP", "reason": "no background detected"}

    bg_color, auto_tolerance = bg_info

    # More aggressive tolerance for multi-pass
    seed_tol = auto_tolerance * 1.4
    spread_tol = auto_tolerance * 1.0

    bg_str = f"({bg_color[0]:.0f},{bg_color[1]:.0f},{bg_color[2]:.0f})"

    # Primary BG removal
    arr, removed_primary = flood_fill_bg_remove(arr, bg_color, seed_tol, spread_tol)

    # Secondary pass
    secondary = detect_secondary_bg(arr, removed_primary)
    if secondary is not None:
        sec_color, sec_tol = secondary
        arr, _ = flood_fill_bg_remove(arr, sec_color, sec_tol * 1.2, sec_tol * 0.85)

    # Aggressive particle cleanup
    arr, particles_removed = remove_small_islands(arr, min_area=120)

    # Stronger desaturation
    arr = desaturate_fringe(arr, strength=0.6, width=4)

    # Double alpha erosion
    arr = erode_alpha_fringe(arr, iterations=2)

    total_opaque_after = int(np.sum(arr[:, :, 3] > 0))
    removed_pct = 100.0 * (1 - total_opaque_after / max(total_opaque_before, 1))

    img = Image.fromarray(arr)
    img = auto_crop_square(img, pad=4)
    img = img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

    stats = {
        "status": "OK",
        "bg_color": bg_str,
        "removed_pct": f"{removed_pct:.1f}%",
        "particles_removed": particles_removed,
        "type": "multi_pass",
    }
    return img, stats


# === Tileset Integration ===

def integrate_into_tileset(tileset, processed_tiles):
    """Paste processed tiles into tileset at their grid positions."""
    for item_id, (row, col), img in processed_tiles:
        x, y = col * TILE_SIZE, row * TILE_SIZE
        # Clear the tile area first
        clear = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
        tileset.paste(clear, (x, y))
        # Paste new tile with alpha
        tileset.paste(img, (x, y), img)
    return tileset


# === Main ===

def main():
    parser = argparse.ArgumentParser(description="Multi-color BG removal for item sprites")
    parser.add_argument("--dry-run", action="store_true", help="Preview without saving tileset")
    parser.add_argument("--category", choices=["bg_removal", "edge_cleanup", "multi_pass", "all"],
                        default="all", help="Category to process")
    parser.add_argument("--ids", help="Comma-separated item IDs to process")
    parser.add_argument("--no-backup", action="store_true", help="Skip tileset backup")
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Loading tileset: {TILESET_PATH}")
    tileset = Image.open(TILESET_PATH).convert("RGBA")

    # Backup
    if not args.dry_run and not args.no_backup:
        if not BACKUP_PATH.exists():
            print(f"Backing up tileset to {BACKUP_PATH.name}")
            shutil.copy2(TILESET_PATH, BACKUP_PATH)
        else:
            print(f"Backup already exists: {BACKUP_PATH.name}")

    processed_tiles = []
    all_stats = {}

    # Parse --ids filter
    id_filter = None
    if args.ids:
        id_filter = set(int(x) for x in args.ids.split(","))

    t0 = time.time()

    # --- BG_REMOVAL ---
    if args.category in ("bg_removal", "all"):
        total = len(BG_REMOVAL)
        if id_filter:
            total = len([i for i in BG_REMOVAL if i in id_filter])
        print(f"\n{'='*60}")
        print(f"BG_REMOVAL: {total} tiles")
        print(f"{'='*60}")

        done = 0
        for item_id, (row, col) in sorted(BG_REMOVAL.items()):
            if id_filter and item_id not in id_filter:
                continue
            raw_path = RAW_DIR / f"item_{item_id}_1024.png"
            if not raw_path.exists():
                print(f"  [SKIP] item_{item_id}: raw not found")
                continue

            done += 1
            is_green = item_id in GREEN_SUBJECT_IDS
            green_tag = " [GREEN]" if is_green else ""
            print(f"  [{done}/{total}] item_{item_id} -> ({row},{col}){green_tag}", end="")

            result, stats = process_bg_removal(item_id, raw_path, is_green_subject=is_green)
            all_stats[item_id] = stats

            if result:
                out_path = OUTPUT_DIR / f"item_{item_id}_fixed.png"
                result.save(out_path)
                processed_tiles.append((item_id, (row, col), result))
                print(f" — removed {stats['removed_pct']} bg, "
                      f"{stats['particles_removed']} particles")
            else:
                print(f" — {stats.get('reason', 'FAILED')}")

    # --- EDGE_CLEANUP ---
    if args.category in ("edge_cleanup", "all"):
        total = len(EDGE_CLEANUP)
        if id_filter:
            total = len([i for i in EDGE_CLEANUP if i in id_filter])
        print(f"\n{'='*60}")
        print(f"EDGE_CLEANUP: {total} tiles")
        print(f"{'='*60}")

        done = 0
        for item_id, (row, col) in sorted(EDGE_CLEANUP.items()):
            if id_filter and item_id not in id_filter:
                continue
            done += 1
            print(f"  [{done}/{total}] item_{item_id} -> ({row},{col})", end="")

            result, stats = process_edge_cleanup(item_id, tileset, row, col)
            all_stats[item_id] = stats

            if result:
                out_path = OUTPUT_DIR / f"item_{item_id}_fixed.png"
                result.save(out_path)
                processed_tiles.append((item_id, (row, col), result))
                print(f" — edge cleanup done")
            else:
                print(f" — FAILED")

    # --- MULTI_PASS ---
    if args.category in ("multi_pass", "all"):
        total = len(MULTI_PASS)
        if id_filter:
            total = len([i for i in MULTI_PASS if i in id_filter])
        print(f"\n{'='*60}")
        print(f"MULTI_PASS: {total} tiles")
        print(f"{'='*60}")

        done = 0
        for item_id, (row, col) in sorted(MULTI_PASS.items()):
            if id_filter and item_id not in id_filter:
                continue
            raw_path = RAW_DIR / f"item_{item_id}_1024.png"
            if not raw_path.exists():
                print(f"  [SKIP] item_{item_id}: raw not found")
                continue

            done += 1
            print(f"  [{done}/{total}] item_{item_id} -> ({row},{col})", end="")

            result, stats = process_multi_pass(item_id, raw_path)
            all_stats[item_id] = stats

            if result:
                out_path = OUTPUT_DIR / f"item_{item_id}_fixed.png"
                result.save(out_path)
                processed_tiles.append((item_id, (row, col), result))
                print(f" — removed {stats['removed_pct']} bg, "
                      f"{stats['particles_removed']} particles")
            else:
                print(f" — {stats.get('reason', 'FAILED')}")

    # --- Integration ---
    elapsed = time.time() - t0
    print(f"\n{'='*60}")
    print(f"RESULTS: {len(processed_tiles)} tiles processed in {elapsed:.1f}s")
    print(f"{'='*60}")

    if not args.dry_run and processed_tiles:
        print(f"Integrating {len(processed_tiles)} tiles into tileset...")
        tileset = integrate_into_tileset(tileset, processed_tiles)
        tileset.save(TILESET_PATH, "PNG")
        print(f"Tileset saved: {TILESET_PATH}")
    elif args.dry_run:
        print("[DRY RUN] Would have updated tileset")

    # Summary
    ok_count = sum(1 for s in all_stats.values() if s.get("status") == "OK")
    skip_count = sum(1 for s in all_stats.values() if s.get("status") == "SKIP")
    print(f"\nSummary: {ok_count} OK, {skip_count} skipped")
    print(f"Individual sprites saved to: {OUTPUT_DIR}")

    return len(processed_tiles)


if __name__ == "__main__":
    sys.exit(0 if main() > 0 else 1)
