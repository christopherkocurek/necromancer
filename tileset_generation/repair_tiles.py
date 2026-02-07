#!/usr/bin/env python3
"""
Tileset Tile Repair Script

Repairs tiles damaged by over-aggressive BG removal in the existing pipeline.
The old pipeline used hue 280-340, sat>0.3, val>0.3 which was too broad,
eating into warm browns, reds, and purples. Passes 2-3 (interior scanning)
created interior holes in sprites.

Repair strategy:
  1. Player sprites with residual magenta: extract from tileset, apply tight
     magenta removal (edge-only flood-fill), patch back.
  2. Items/Artefacts/Monsters with raw sprites available: re-process from raw
     with tighter thresholds and edge-only BG removal (NO interior scanning).
  3. Tiles without raw sprites: fill interior holes by interpolating from
     neighboring pixels (conservative fallback).

CRITICAL RULES:
  - Hue-shift FIRST, then BG removal. NEVER strip R/B channels.
  - Edge-only flood-fill: start from border pixels, flood inward through
    magenta-range pixels. Do NOT scan interior.
  - Player sprites at rows 6-9, cols 0-11 ONLY. Do NOT touch cols 12-31.

Usage:
    python3 repair_tiles.py --all           # Full repair pipeline
    python3 repair_tiles.py --players       # Player sprites only
    python3 repair_tiles.py --items         # Items only
    python3 repair_tiles.py --artefacts     # Artefacts only
    python3 repair_tiles.py --monsters      # Monsters only
    python3 repair_tiles.py --dry-run       # Show what would be repaired
"""

import argparse
import json
import shutil
import sys
from collections import deque
from pathlib import Path

try:
    from PIL import Image, ImageEnhance
    import numpy as np
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install: pip3 install pillow numpy")
    sys.exit(1)

# ============================================================================
# PATHS & CONSTANTS
# ============================================================================

BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
BACKUP_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.pre_repair.png"

MONSTER_RAW_DIR = BASE_DIR / "monster_v2" / "raw"
ITEM_RAW_DIR = BASE_DIR / "item_v2" / "raw"
ARTEFACT_RAW_DIR = BASE_DIR / "artefact_v2" / "raw"
PLAYER_V2_DIR = BASE_DIR / "player_v2"

ITEM_PROGRESS_PATH = BASE_DIR / "item_v2_progress.json"

TILE_SIZE = 64
GRID_SIZE = 32
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048

# Tighter magenta thresholds (old was 280-340, sat>0.3)
TIGHT_HUE_MIN = 290
TIGHT_HUE_MAX = 320
TIGHT_SAT_MIN = 0.5
TIGHT_VAL_MIN = 0.3

# For edge flood-fill BG removal seeding/spreading
# These are RGB-based checks for the bright magenta background
SEED_R_MIN = 120
SEED_G_RATIO = 0.55   # g < r * ratio
SEED_DIFF_MIN = 60     # r - g > diff

SPREAD_R_MIN = 100
SPREAD_G_RATIO = 0.6
SPREAD_DIFF_MIN = 45

# Monster layout
ALL_MONSTER_IDS = sorted([
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 51,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 71, 73, 80, 85,
    72, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 86, 91, 100,
    92, 93, 94, 95, 96, 97, 98, 99, 101, 102, 103, 104, 111,
    112, 113, 114, 115, 116, 117, 118, 131, 136,
    132, 133, 134, 135, 137,
    301, 302, 303, 304, 305, 306, 307, 308, 309, 310,
])
MONSTER_START_ROW = 24
ITEM_START_ROW = 11

# Artefact category layout: row 19, cols 0-18
ARTEFACT_ROW = 19
ARTEFACT_CATEGORIES = {
    0: "sword", 1: "axe", 2: "spear", 3: "staff", 4: "hammer",
    5: "pickaxe", 6: "bow", 7: "arrow", 8: "ring", 9: "amulet",
    10: "robe", 11: "mail", 12: "shield", 13: "helm", 14: "crown",
    15: "cloak", 16: "boots", 17: "gloves", 18: "light_source",
}

# Per-type hue-shift targets (used during HSV correction before BG removal)
# Maps category/type to target hue for magenta-zone pixels
MONSTER_COLORS = {
    11: {"hue_deg": 25,  "achromatic": False},
    12: {"hue_deg": 25,  "achromatic": False},
    13: {"hue_deg": 0,   "achromatic": True},
    14: {"hue_deg": 0,   "achromatic": True},
    15: {"hue_deg": 100, "achromatic": False},
    16: {"hue_deg": 0,   "achromatic": True},
    17: {"hue_deg": 0,   "achromatic": True},
    18: {"hue_deg": 80,  "achromatic": False},
    19: {"hue_deg": 120, "achromatic": False},
    20: {"hue_deg": 25,  "achromatic": False},
    21: {"hue_deg": 30,  "achromatic": False},
    22: {"hue_deg": 25,  "achromatic": False},
    31: {"hue_deg": 80,  "achromatic": False},
    32: {"hue_deg": 80,  "achromatic": False},
    33: {"hue_deg": 80,  "achromatic": False},
    34: {"hue_deg": 0,   "achromatic": True},
    35: {"hue_deg": 80,  "achromatic": False},
    36: {"hue_deg": 80,  "achromatic": False},
    37: {"hue_deg": 80,  "achromatic": False},
    38: {"hue_deg": 0,   "achromatic": True},
    39: {"hue_deg": 0,   "achromatic": True},
    40: {"hue_deg": 80,  "achromatic": False},
    51: {"hue_deg": 260, "achromatic": False},
    52: {"hue_deg": 0,   "achromatic": True},
    53: {"hue_deg": 100, "achromatic": False},
    54: {"hue_deg": 30,  "achromatic": False},
    55: {"hue_deg": 0,   "achromatic": True},
    56: {"hue_deg": 0,   "achromatic": True},
    57: {"hue_deg": 40,  "achromatic": False},
    58: {"hue_deg": 100, "achromatic": False},
    59: {"hue_deg": 5,   "achromatic": False},
    60: {"hue_deg": 260, "achromatic": False},
    71: {"hue_deg": 40,  "achromatic": False},
    72: {"hue_deg": 40,  "achromatic": False},
    73: {"hue_deg": 100, "achromatic": False},
    74: {"hue_deg": 200, "achromatic": False},
    75: {"hue_deg": 60,  "achromatic": False},
    76: {"hue_deg": 100, "achromatic": False},
    77: {"hue_deg": 0,   "achromatic": True},
    78: {"hue_deg": 40,  "achromatic": False},
    79: {"hue_deg": 260, "achromatic": False},
    80: {"hue_deg": 0,   "achromatic": True},
    81: {"hue_deg": 0,   "achromatic": True},
    82: {"hue_deg": 260, "achromatic": False},
    83: {"hue_deg": 210, "achromatic": False},
    84: {"hue_deg": 210, "achromatic": False},
    85: {"hue_deg": 25,  "achromatic": False},
    86: {"hue_deg": 0,   "achromatic": True},
    91: {"hue_deg": 0,   "achromatic": True},
    92: {"hue_deg": 0,   "achromatic": True},
    93: {"hue_deg": 0,   "achromatic": True},
    94: {"hue_deg": 0,   "achromatic": True},
    95: {"hue_deg": 260, "achromatic": False},
    96: {"hue_deg": 0,   "achromatic": True},
    97: {"hue_deg": 0,   "achromatic": True},
    98: {"hue_deg": 0,   "achromatic": True},
    99: {"hue_deg": 0,   "achromatic": True},
    100: {"hue_deg": 0,  "achromatic": True},
    101: {"hue_deg": 30, "achromatic": False},
    102: {"hue_deg": 210, "achromatic": False},
    103: {"hue_deg": 120, "achromatic": False},
    104: {"hue_deg": 100, "achromatic": False},
    111: {"hue_deg": 0,  "achromatic": True},
    112: {"hue_deg": 0,  "achromatic": True},
    113: {"hue_deg": 0,  "achromatic": True},
    114: {"hue_deg": 260, "achromatic": False},
    115: {"hue_deg": 5,  "achromatic": False},
    116: {"hue_deg": 0,  "achromatic": True},
    117: {"hue_deg": 20, "achromatic": False},
    118: {"hue_deg": 0,  "achromatic": True},
    131: {"hue_deg": 0,  "achromatic": True},
    132: {"hue_deg": 0,  "achromatic": True},
    133: {"hue_deg": 260, "achromatic": False},
    134: {"hue_deg": 200, "achromatic": False},
    135: {"hue_deg": 40, "achromatic": False},
    136: {"hue_deg": 260, "achromatic": False},
    137: {"hue_deg": 0,  "achromatic": True},
    301: {"hue_deg": 0,  "achromatic": True},
    302: {"hue_deg": 100, "achromatic": False},
    303: {"hue_deg": 0,  "achromatic": True},
    304: {"hue_deg": 220, "achromatic": False},
    305: {"hue_deg": 220, "achromatic": False},
    306: {"hue_deg": 25, "achromatic": False},
    307: {"hue_deg": 25, "achromatic": False},
    308: {"hue_deg": 35, "achromatic": False},
    309: {"hue_deg": 210, "achromatic": False},
    310: {"hue_deg": 25, "achromatic": False},
}

ITEM_CATEGORY_COLORS = {
    "sword":            {"hue_deg": 210, "achromatic": True},
    "polearm":          {"hue_deg": 25,  "achromatic": False},
    "hafted":           {"hue_deg": 25,  "achromatic": False},
    "bow":              {"hue_deg": 25,  "achromatic": False},
    "body_armor":       {"hue_deg": 0,   "achromatic": True},
    "soft_armor":       {"hue_deg": 25,  "achromatic": False},
    "shield":           {"hue_deg": 0,   "achromatic": True},
    "helm":             {"hue_deg": 0,   "achromatic": True},
    "crown":            {"hue_deg": 45,  "achromatic": False},
    "gloves":           {"hue_deg": 25,  "achromatic": False},
    "boots":            {"hue_deg": 25,  "achromatic": False},
    "cloak":            {"hue_deg": 120, "achromatic": False},
    "ring":             {"hue_deg": 45,  "achromatic": False},
    "amulet":           {"hue_deg": 45,  "achromatic": False},
    "potion":           {"hue_deg": 210, "achromatic": False},
    "herb":             {"hue_deg": 120, "achromatic": False},
    "scroll":           {"hue_deg": 40,  "achromatic": False},
    "document":         {"hue_deg": 40,  "achromatic": False},
    "wand":             {"hue_deg": 25,  "achromatic": False},
    "horn":             {"hue_deg": 40,  "achromatic": False},
    "light":            {"hue_deg": 40,  "achromatic": False},
    "arrow":            {"hue_deg": 25,  "achromatic": False},
    "sling":            {"hue_deg": 25,  "achromatic": False},
    "sling_stone":      {"hue_deg": 0,   "achromatic": True},
    "digging":          {"hue_deg": 0,   "achromatic": True},
    "chest":            {"hue_deg": 25,  "achromatic": False},
    "skeleton":         {"hue_deg": 40,  "achromatic": False},
    "oil":              {"hue_deg": 35,  "achromatic": False},
    "special_material": {"hue_deg": 0,   "achromatic": True},
    "unknown":          {"hue_deg": 0,   "achromatic": True},
}

ARTEFACT_CATEGORY_COLORS = {
    0:  {"hue_deg": 210, "achromatic": True},   # sword
    1:  {"hue_deg": 0,   "achromatic": True},   # axe
    2:  {"hue_deg": 25,  "achromatic": False},  # spear
    3:  {"hue_deg": 25,  "achromatic": False},  # staff
    4:  {"hue_deg": 0,   "achromatic": True},   # hammer
    5:  {"hue_deg": 25,  "achromatic": False},  # pickaxe
    6:  {"hue_deg": 25,  "achromatic": False},  # bow
    7:  {"hue_deg": 25,  "achromatic": False},  # arrow
    8:  {"hue_deg": 45,  "achromatic": False},  # ring
    9:  {"hue_deg": 45,  "achromatic": False},  # amulet
    10: {"hue_deg": 25,  "achromatic": False},  # robe
    11: {"hue_deg": 0,   "achromatic": True},   # mail
    12: {"hue_deg": 210, "achromatic": False},  # shield
    13: {"hue_deg": 0,   "achromatic": True},   # helm
    14: {"hue_deg": 45,  "achromatic": False},  # crown
    15: {"hue_deg": 120, "achromatic": False},  # cloak
    16: {"hue_deg": 25,  "achromatic": False},  # boots
    17: {"hue_deg": 25,  "achromatic": False},  # gloves
    18: {"hue_deg": 40,  "achromatic": False},  # light_source
}

# Player sprite grid mapping: (col, row) -> raw file key
# Row 6: Elf, Row 7: Man, Row 8: Dwarf, Row 9: Hobbit
# Cols 0-5: light (h_male, h_female alternating per house), Cols 6-11: dark
PLAYER_GRID = {
    # Elf (row 6)
    (0, 6): ("elf", "h0", "male"),    (1, 6): ("elf", "h0", "female"),
    (2, 6): ("elf", "h1", "male"),    (3, 6): ("elf", "h1", "female"),
    (4, 6): ("elf", "h2", "male"),    (5, 6): ("elf", "h2", "female"),
    # Man (row 7)
    (0, 7): ("man", "h3", "male"),    (1, 7): ("man", "h3", "female"),
    (2, 7): ("man", "h4", "male"),    (3, 7): ("man", "h4", "female"),
    (4, 7): ("man", "h5", "male"),    (5, 7): ("man", "h5", "female"),
    # Dwarf (row 8)
    (0, 8): ("dwarf", "h6", "male"),  (1, 8): ("dwarf", "h6", "female"),
    (2, 8): ("dwarf", "h7", "male"),  (3, 8): ("dwarf", "h7", "female"),
    (4, 8): ("dwarf", "h8", "male"),  (5, 8): ("dwarf", "h8", "female"),
    # Hobbit (row 9)
    (0, 9): ("hobbit", "h9", "male"),   (1, 9): ("hobbit", "h9", "female"),
    (2, 9): ("hobbit", "h10", "male"),  (3, 9): ("hobbit", "h10", "female"),
    (4, 9): ("hobbit", "h11", "male"),  (5, 9): ("hobbit", "h11", "female"),
}

# Dark variant grid (cols 6-11)
PLAYER_DARK_GRID = {}
for (col, row), (race, house, gender) in PLAYER_GRID.items():
    PLAYER_DARK_GRID[(col + 6, row)] = (race, house, gender)


# ============================================================================
# HSV CONVERSION (vectorized numpy)
# ============================================================================

def rgb_to_hsv(rgb_array):
    """RGB (0-255) -> HSV (H=0-360, S=0-1, V=0-1)."""
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
    """HSV (H=0-360, S=0-1, V=0-1) -> RGB (0-255)."""
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
# CORE: TIGHT MAGENTA HSV CORRECTION
# ============================================================================

def hue_shift_magenta(img, target_hue_deg, achromatic=False, broad=False):
    """
    Shift magenta-range pixels toward a target hue.

    When broad=False (default, for already-processed sprites):
      Uses TIGHT thresholds: hue 290-320, sat>0.5, val>0.3.
      This preserves warm browns, reds, and purples.

    When broad=True (for raw DALL-E sprites):
      Uses BROAD thresholds: hue 275-335, sat>0.12, val>0.3.
      This catches the full DALL-E magenta bleed zone.
    """
    rgba = np.array(img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    if broad:
        # Broad magenta zone for raw DALL-E sprites
        in_magenta = (
            (hue >= 275) & (hue <= 335) &
            (sat > 0.12) & (val > 0.3)
        )
    else:
        # Tight magenta detection for already-processed sprites
        in_magenta = (
            (hue >= TIGHT_HUE_MIN) & (hue <= TIGHT_HUE_MAX) &
            (sat > TIGHT_SAT_MIN) & (val > TIGHT_VAL_MIN)
        )

    magenta_count = int(np.sum(in_magenta))
    if magenta_count == 0:
        return img

    new_hue = hue.copy()
    new_sat = sat.copy()

    if achromatic:
        # Desaturate magenta zone for black/gray/white sprites
        new_sat = np.where(in_magenta, sat * 0.05, sat)
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        strength = 0.9
        new_hue = np.where(in_magenta, (hue + diff * strength) % 360, hue)
        new_sat = np.where(in_magenta & (sat > 0.6), sat * 0.85, sat)

    new_hsv = np.stack([new_hue, new_sat, val], axis=-1)
    new_rgb = hsv_to_rgb(new_hsv)

    result = rgba.copy()
    result[:, :, :3] = np.where(in_magenta[:, :, np.newaxis], new_rgb, rgb)
    result[:, :, 3] = alpha

    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


def cleanup_post_bg_pink(img, target_hue_deg, achromatic=False):
    """
    Post-BG-removal cleanup: fix remaining pink/magenta on visible pixels.
    After BG removal, every visible pixel IS the sprite.
    Any remaining pink/magenta hue is leftover DALL-E bleed.
    Wide zone: 250-360 and 0-20, sat>0.15.
    """
    rgba = np.array(img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    visible = alpha > 10
    visible_count = int(np.sum(visible))
    if visible_count == 0:
        return img

    hsv = rgb_to_hsv(rgb)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]

    # Wide pink/magenta zone
    in_pink = visible & (
        ((hue >= 250) & (hue <= 360)) |
        ((hue >= 0) & (hue <= 20))
    ) & (sat > 0.15)

    pink_count = int(np.sum(in_pink))
    if pink_count == 0:
        return img

    new_hue = hue.copy()
    new_sat = sat.copy()

    if achromatic:
        new_sat = np.where(in_pink, sat * 0.05, sat)
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        strength = 0.85
        new_hue = np.where(in_pink, (hue + diff * strength) % 360, hue)
        new_sat = np.where(in_pink & (sat > 0.4), sat * 0.75, sat)

    new_hsv = np.stack([new_hue, new_sat, val], axis=-1)
    new_rgb = hsv_to_rgb(new_hsv)

    result = rgba.copy()
    result[:, :, :3] = np.where(visible[:, :, np.newaxis], new_rgb, rgb)
    result[:, :, 3] = alpha
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


# ============================================================================
# CORE: EDGE-ONLY FLOOD-FILL BG REMOVAL
# ============================================================================

def is_magenta_seed(r, g, b):
    """Check if a pixel is a strong magenta seed for flood-fill start."""
    return (r > SEED_R_MIN and g < r * SEED_G_RATIO and
            (r - g) > SEED_DIFF_MIN and b > g * 0.7)


def is_magenta_spread(r, g, b):
    """Check if a pixel is magenta enough to spread through during flood-fill."""
    return (r > SPREAD_R_MIN and g < r * SPREAD_G_RATIO and
            (r - g) > SPREAD_DIFF_MIN and b > g * 0.6)


def edge_only_bg_remove(img):
    """
    Remove magenta background using edge-only flood-fill.

    ONLY starts from border pixels (edges of the 64x64 or 1024x1024 image).
    Flood-fills inward through magenta-range pixels, marking them as background.
    Does NOT scan interior pixels independently -- this prevents creating
    interior holes in the sprite.
    """
    arr = np.array(img.convert("RGBA"))
    h, w = arr.shape[:2]
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    visited = np.zeros((h, w), dtype=bool)
    removed = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Seed from ALL border pixels (top, bottom, left, right edges)
    for x in range(w):
        for y in [0, h - 1]:
            if a[y, x] > 0 and is_magenta_seed(int(r[y, x]), int(g[y, x]), int(b[y, x])):
                queue.append((y, x))
                visited[y, x] = True
    for y in range(1, h - 1):
        for x in [0, w - 1]:
            if not visited[y, x] and a[y, x] > 0 and is_magenta_seed(int(r[y, x]), int(g[y, x]), int(b[y, x])):
                queue.append((y, x))
                visited[y, x] = True

    # 8-directional BFS flood fill
    while queue:
        cy, cx = queue.popleft()
        removed[cy, cx] = True
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and a[ny, nx] > 0:
                    visited[ny, nx] = True
                    if is_magenta_spread(int(r[ny, nx]), int(g[ny, nx]), int(b[ny, nx])):
                        queue.append((ny, nx))

    # One gentle fringe pass: remove magenta-ish pixels adjacent to removed pixels
    # This handles anti-aliased edges. Only ONE pass, not two.
    fringe = np.zeros((h, w), dtype=bool)
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if removed[y, x] or a[y, x] == 0:
                continue
            # Check if adjacent to a removed pixel
            has_removed_neighbor = False
            for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                if removed[y + dy, x + dx]:
                    has_removed_neighbor = True
                    break
            if has_removed_neighbor:
                rv, gv, bv = int(r[y, x]), int(g[y, x]), int(b[y, x])
                # Only remove if clearly magenta-ish (tighter than the spread check)
                if rv > 80 and gv < rv * 0.5 and bv > gv * 0.9 and (rv - gv) > 35:
                    fringe[y, x] = True
    removed |= fringe

    arr[removed, 3] = 0
    total = int(np.sum(removed))
    return Image.fromarray(arr), total


# ============================================================================
# CORE: INTERIOR HOLE FILLING (FALLBACK)
# ============================================================================

def fill_interior_holes(img):
    """
    Fill transparent interior holes in a sprite.
    A hole is a transparent pixel (alpha=0) surrounded by >= 6 opaque neighbors
    out of 8. Fill with the average color of opaque neighbors.
    Returns (repaired_image, holes_filled).
    """
    arr = np.array(img.convert("RGBA")).copy()
    h, w = arr.shape[:2]
    alpha = arr[:, :, 3]
    opaque = (alpha > 0).astype(np.int32)

    # Pad for neighbor counting
    padded = np.pad(opaque, 1, mode='constant', constant_values=0)

    total_filled = 0
    # Multiple passes to fill progressively
    for pass_num in range(5):
        filled_this_pass = 0
        new_arr = arr.copy()
        alpha = arr[:, :, 3]
        opaque = (alpha > 0)

        for y in range(h):
            for x in range(w):
                if alpha[y, x] > 0:
                    continue  # Already opaque

                # Count opaque neighbors and average their colors
                neighbor_count = 0
                r_sum, g_sum, b_sum, a_sum = 0.0, 0.0, 0.0, 0.0
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dy == 0 and dx == 0:
                            continue
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < w and arr[ny, nx, 3] > 0:
                            neighbor_count += 1
                            r_sum += arr[ny, nx, 0]
                            g_sum += arr[ny, nx, 1]
                            b_sum += arr[ny, nx, 2]
                            a_sum += arr[ny, nx, 3]

                if neighbor_count >= 6:
                    new_arr[y, x, 0] = int(r_sum / neighbor_count)
                    new_arr[y, x, 1] = int(g_sum / neighbor_count)
                    new_arr[y, x, 2] = int(b_sum / neighbor_count)
                    new_arr[y, x, 3] = int(a_sum / neighbor_count)
                    filled_this_pass += 1

        arr = new_arr
        total_filled += filled_this_pass
        if filled_this_pass == 0:
            break

    return Image.fromarray(arr), total_filled


# ============================================================================
# POST-PROCESSING HELPERS
# ============================================================================

def auto_crop_square(img):
    """Crop to content bounding box, then pad to square."""
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
    """Dark/FOV variant: desaturate 60%, darken 40%, cool blue tint."""
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
# ITEM DATA HELPERS
# ============================================================================

def load_item_info():
    """Load item_v2_progress.json to get category info per item."""
    if not ITEM_PROGRESS_PATH.exists():
        return {}, {}
    with open(ITEM_PROGRESS_PATH, "r") as f:
        progress = json.load(f)

    items = {}       # item_id -> {category, name}
    dup_map = {}     # dup_id -> canonical_id

    for key, info in progress.get("sprites", {}).items():
        if info.get("status") != "completed":
            continue
        item_id = info.get("item_id")
        if item_id is None:
            continue
        canonical = info.get("canonical_id")
        if canonical is not None and canonical != item_id:
            dup_map[item_id] = canonical
        else:
            items[item_id] = {
                "name": info.get("name", f"item_{item_id}"),
                "category": info.get("category", "unknown"),
            }

    return items, dup_map


def compute_item_layout(item_ids):
    """Compute grid coordinates for items. Returns {item_id: (col, row)}."""
    layout = {}
    for i, iid in enumerate(sorted(item_ids)):
        col = i % GRID_SIZE
        row = ITEM_START_ROW + i // GRID_SIZE
        layout[iid] = (col, row)
    return layout


def compute_monster_layout():
    """Compute grid coordinates for monsters. Returns {monster_id: (col, row)}."""
    layout = {}
    for i, mid in enumerate(ALL_MONSTER_IDS):
        col = i % GRID_SIZE
        row = MONSTER_START_ROW + i // GRID_SIZE
        layout[mid] = (col, row)
    return layout


# ============================================================================
# REPAIR: PLAYER SPRITES
# ============================================================================

def repair_player_sprites(tileset, dry_run=False):
    """
    Repair player sprites with magenta residue.
    Priority 1 tiles from the audit:
      (5,8) 43% magenta, (4,8) 13%, (2,9) 10%, (4,6) 9%, (3,8) 6%

    Also repair all other player tiles that have magenta > 2%.
    """
    print(f"\n{'=' * 60}")
    print(f"PLAYER SPRITE REPAIR")
    print(f"{'=' * 60}")

    repaired = []
    skipped = []

    # Check all player light tiles (cols 0-5, rows 6-9)
    for row in range(6, 10):
        for col in range(6):
            x0 = col * TILE_SIZE
            y0 = row * TILE_SIZE
            tile = tileset.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))
            tile_arr = np.array(tile)
            alpha = tile_arr[:, :, 3]
            opaque_count = int(np.sum(alpha > 0))

            if opaque_count < 10:
                continue

            # Check magenta percentage
            rgb = tile_arr[:, :, :3].astype(np.float64)
            hsv = rgb_to_hsv(rgb)
            hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
            opaque_mask = alpha > 0
            magenta_mask = (
                opaque_mask &
                (hue >= 280) & (hue <= 340) &
                (sat > 0.3) & (val > 0.3)
            )
            magenta_count = int(np.sum(magenta_mask))
            magenta_pct = magenta_count / max(opaque_count, 1) * 100

            if magenta_pct < 2.0:
                continue

            grid_key = (col, row)
            race_info = PLAYER_GRID.get(grid_key)
            if not race_info:
                continue

            race, house, gender = race_info
            label = f"({col},{row}) {race}_{house}_{gender}"

            if dry_run:
                print(f"  WOULD REPAIR: {label} ({magenta_pct:.1f}% magenta)")
                repaired.append(label)
                continue

            print(f"\n  Repairing {label} ({magenta_pct:.1f}% magenta)...")

            # Strategy: find the raw 1024px sprite and re-process it
            raw_path = PLAYER_V2_DIR / "raw" / f"player_{race}_{house}_{gender}_1024.png"
            if raw_path.exists():
                print(f"    Found raw sprite: {raw_path.name}")
                raw_img = Image.open(raw_path).convert("RGBA")

                # Step 1: BROAD HSV hue-shift magenta pixels (raw DALL-E needs broad)
                corrected = hue_shift_magenta(raw_img, target_hue_deg=25, achromatic=False, broad=True)

                # Step 2: Edge-only flood-fill BG removal
                transparent, bg_removed = edge_only_bg_remove(corrected)
                print(f"    Edge-only BG removed: {bg_removed:,} pixels")

                # Step 3: Post-BG pink cleanup (catch remaining bleed)
                cleaned = cleanup_post_bg_pink(transparent, target_hue_deg=25, achromatic=False)

                # Step 4: Crop + resize to 64x64
                cropped = auto_crop_square(cleaned)
                repaired_tile = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

                # Step 5: Patch into tileset
                tileset.paste(repaired_tile, (x0, y0), repaired_tile)
                print(f"    Patched at ({col},{row})")

                # Step 6: Also regenerate + patch the dark variant (col+6)
                dark = generate_dark_variant(repaired_tile)
                dark_x0 = (col + 6) * TILE_SIZE
                tileset.paste(dark, (dark_x0, y0), dark)
                print(f"    Dark variant patched at ({col + 6},{row})")

                repaired.append(label)
            else:
                # Fallback: repair in-place from tileset extraction
                print(f"    No raw sprite found, repairing in-place...")
                # Apply tight magenta removal to the extracted tile
                corrected = hue_shift_magenta(tile, target_hue_deg=25, achromatic=False)
                # Edge-only BG removal on the 64x64 tile
                transparent, bg_removed = edge_only_bg_remove(corrected)
                print(f"    Edge-only BG removed: {bg_removed} pixels")
                # Fill any interior holes
                filled_img, holes_filled = fill_interior_holes(transparent)
                if holes_filled > 0:
                    print(f"    Filled {holes_filled} interior holes")
                # Patch back
                tileset.paste(filled_img, (x0, y0), filled_img)
                print(f"    Patched at ({col},{row})")

                # Also fix the dark variant
                dark = generate_dark_variant(filled_img)
                dark_x0 = (col + 6) * TILE_SIZE
                tileset.paste(dark, (dark_x0, y0), dark)
                print(f"    Dark variant patched at ({col + 6},{row})")

                repaired.append(label)

    # Also handle player tiles with interior holes/fragmentation (no magenta but damaged)
    for row in range(6, 10):
        for col in range(12):  # Both light (0-5) and dark (6-11)
            x0 = col * TILE_SIZE
            y0 = row * TILE_SIZE
            tile = tileset.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))
            tile_arr = np.array(tile)
            alpha = tile_arr[:, :, 3]
            opaque_count = int(np.sum(alpha > 0))

            if opaque_count < 10:
                continue

            label = f"({col},{row}) player"

            # Already repaired above?
            if any(label.startswith(f"({col},{row})") for label in repaired):
                continue

            # Count interior holes
            opaque_i32 = (alpha > 0).astype(np.int32)
            h, w = opaque_i32.shape
            padded = np.pad(opaque_i32, 1, mode='constant', constant_values=0)
            neighbor_count = np.zeros_like(opaque_i32, dtype=np.int32)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dy == 0 and dx == 0:
                        continue
                    neighbor_count += padded[1+dy:h+1+dy, 1+dx:w+1+dx]
            holes = int(np.sum((alpha == 0) & (neighbor_count >= 6)))

            if holes < 5:
                continue

            if dry_run:
                print(f"  WOULD FILL HOLES: {label} ({holes} interior holes)")
                repaired.append(label)
                continue

            print(f"\n  Filling holes in {label} ({holes} interior holes)...")
            filled_img, holes_filled = fill_interior_holes(tile)
            if holes_filled > 0:
                tileset.paste(filled_img, (x0, y0), filled_img)
                print(f"    Filled {holes_filled} holes, patched at ({col},{row})")
                repaired.append(label)

    print(f"\n  Player sprites repaired: {len(repaired)}")
    return repaired


# ============================================================================
# REPAIR: ITEMS
# ============================================================================

def repair_items(tileset, dry_run=False):
    """
    Repair damaged item tiles. Strategy:
    1. For items with raw 1024px sprites: re-process from raw with tight thresholds.
    2. For items without raw: fill interior holes as fallback.
    """
    print(f"\n{'=' * 60}")
    print(f"ITEM SPRITE REPAIR")
    print(f"{'=' * 60}")

    item_info, dup_map = load_item_info()
    item_ids = sorted(item_info.keys())
    item_layout = compute_item_layout(item_ids)

    repaired = []
    no_raw = []
    fallback_repaired = []

    for iid in item_ids:
        if iid not in item_layout:
            continue
        col, row = item_layout[iid]
        x0 = col * TILE_SIZE
        y0 = row * TILE_SIZE

        # Check if this tile needs repair: count holes and fragments
        tile = tileset.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))
        tile_arr = np.array(tile)
        alpha = tile_arr[:, :, 3]
        opaque_count = int(np.sum(alpha > 0))

        if opaque_count < 10:
            continue

        # Count interior holes
        opaque_i32 = (alpha > 0).astype(np.int32)
        h, w = opaque_i32.shape
        padded = np.pad(opaque_i32, 1, mode='constant', constant_values=0)
        neighbor_count = np.zeros_like(opaque_i32, dtype=np.int32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                neighbor_count += padded[1+dy:h+1+dy, 1+dx:w+1+dx]
        holes = int(np.sum((alpha == 0) & (neighbor_count >= 6)))

        # Count fragments (simple BFS)
        opaque_mask = (alpha > 0)
        visited = np.zeros_like(opaque_mask, dtype=bool)
        fragments = 0
        for iy in range(h):
            for ix in range(w):
                if opaque_mask[iy, ix] and not visited[iy, ix]:
                    fragments += 1
                    fq = deque()
                    fq.append((iy, ix))
                    visited[iy, ix] = True
                    while fq:
                        cy, cx = fq.popleft()
                        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and opaque_mask[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                fq.append((ny, nx))

        # Only repair if significantly damaged
        needs_repair = holes > 5 or fragments > 5
        if not needs_repair:
            continue

        info = item_info.get(iid, {"name": f"item_{iid}", "category": "unknown"})
        cat = info["category"]
        name = info["name"]
        label = f"item_{iid} ({name})"

        # Try to find raw sprite
        raw_path = ITEM_RAW_DIR / f"item_{iid}_1024.png"

        if dry_run:
            src = "raw" if raw_path.exists() else "fallback"
            print(f"  WOULD REPAIR [{src}]: ({col},{row}) {label} "
                  f"(holes={holes}, frags={fragments})")
            repaired.append(label)
            continue

        if raw_path.exists():
            # Full re-process from raw with broad hue-shift + edge-only BG removal
            raw_img = Image.open(raw_path).convert("RGBA")

            # Step 1: BROAD HSV hue-shift (raw DALL-E needs broad detection)
            colors = ITEM_CATEGORY_COLORS.get(cat, ITEM_CATEGORY_COLORS["unknown"])
            corrected = hue_shift_magenta(
                raw_img,
                target_hue_deg=colors["hue_deg"],
                achromatic=colors["achromatic"],
                broad=True,
            )

            # Step 2: Edge-only BG removal (NO interior scanning)
            transparent, bg_removed = edge_only_bg_remove(corrected)

            # Step 3: Post-BG pink cleanup
            cleaned = cleanup_post_bg_pink(
                transparent,
                target_hue_deg=colors["hue_deg"],
                achromatic=colors["achromatic"],
            )

            # Step 4: Crop + resize
            cropped = auto_crop_square(cleaned)
            repaired_tile = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

            # Step 5: Patch into tileset (clear first, then paste)
            clear = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear, (x0, y0))
            tileset.paste(repaired_tile, (x0, y0), repaired_tile)

            repaired.append(label)
            if len(repaired) % 20 == 0:
                print(f"    Repaired {len(repaired)} items so far...")
        else:
            # Fallback: fill interior holes in the existing tile
            filled_img, holes_filled = fill_interior_holes(tile)
            if holes_filled > 0:
                tileset.paste(filled_img, (x0, y0), filled_img)
                fallback_repaired.append(label)
            no_raw.append(iid)

    print(f"\n  Items repaired from raw: {len(repaired)}")
    print(f"  Items repaired (hole fill fallback): {len(fallback_repaired)}")
    if no_raw:
        print(f"  Items without raw sprites: {len(no_raw)}")

    return repaired + fallback_repaired


# ============================================================================
# REPAIR: ARTEFACTS
# ============================================================================

def repair_artefacts(tileset, dry_run=False):
    """
    Repair artefact category sprites at row 19, cols 0-18.
    Re-process from raw 1024px sprites.
    """
    print(f"\n{'=' * 60}")
    print(f"ARTEFACT SPRITE REPAIR")
    print(f"{'=' * 60}")

    repaired = []

    for cat_id, cat_name in ARTEFACT_CATEGORIES.items():
        col = cat_id
        row = ARTEFACT_ROW
        x0 = col * TILE_SIZE
        y0 = row * TILE_SIZE

        # Check if damaged
        tile = tileset.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))
        tile_arr = np.array(tile)
        alpha = tile_arr[:, :, 3]
        opaque_count = int(np.sum(alpha > 0))

        if opaque_count < 10:
            continue

        # Count holes
        opaque_i32 = (alpha > 0).astype(np.int32)
        h, w = opaque_i32.shape
        padded = np.pad(opaque_i32, 1, mode='constant', constant_values=0)
        neighbor_count = np.zeros_like(opaque_i32, dtype=np.int32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                neighbor_count += padded[1+dy:h+1+dy, 1+dx:w+1+dx]
        holes = int(np.sum((alpha == 0) & (neighbor_count >= 6)))

        # Count fragments
        opaque_mask = (alpha > 0)
        visited = np.zeros_like(opaque_mask, dtype=bool)
        fragments = 0
        for iy in range(h):
            for ix in range(w):
                if opaque_mask[iy, ix] and not visited[iy, ix]:
                    fragments += 1
                    fq = deque()
                    fq.append((iy, ix))
                    visited[iy, ix] = True
                    while fq:
                        cy, cx = fq.popleft()
                        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and opaque_mask[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                fq.append((ny, nx))

        needs_repair = holes > 3 or fragments > 3
        if not needs_repair:
            continue

        label = f"artefact_{cat_id} ({cat_name})"
        raw_path = ARTEFACT_RAW_DIR / f"artefact_{cat_id}_{cat_name}_1024.png"

        if dry_run:
            src = "raw" if raw_path.exists() else "fallback"
            print(f"  WOULD REPAIR [{src}]: ({col},{row}) {label} "
                  f"(holes={holes}, frags={fragments})")
            repaired.append(label)
            continue

        if raw_path.exists():
            raw_img = Image.open(raw_path).convert("RGBA")

            # Step 1: BROAD HSV hue-shift (raw DALL-E needs broad detection)
            colors = ARTEFACT_CATEGORY_COLORS.get(cat_id, {"hue_deg": 0, "achromatic": True})
            corrected = hue_shift_magenta(
                raw_img,
                target_hue_deg=colors["hue_deg"],
                achromatic=colors["achromatic"],
                broad=True,
            )

            # Step 2: Edge-only BG removal
            transparent, bg_removed = edge_only_bg_remove(corrected)

            # Step 3: Post-BG pink cleanup
            cleaned = cleanup_post_bg_pink(
                transparent,
                target_hue_deg=colors["hue_deg"],
                achromatic=colors["achromatic"],
            )

            # Step 4: Crop + resize
            cropped = auto_crop_square(cleaned)
            repaired_tile = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

            # Step 5: Patch into tileset
            clear = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear, (x0, y0))
            tileset.paste(repaired_tile, (x0, y0), repaired_tile)

            print(f"  Repaired: ({col},{row}) {label}")
            repaired.append(label)
        else:
            # Fallback: fill interior holes
            filled_img, holes_filled = fill_interior_holes(tile)
            if holes_filled > 0:
                tileset.paste(filled_img, (x0, y0), filled_img)
                print(f"  Fallback filled: ({col},{row}) {label} ({holes_filled} holes)")
                repaired.append(label)

    print(f"\n  Artefacts repaired: {len(repaired)}")
    return repaired


# ============================================================================
# REPAIR: MONSTERS
# ============================================================================

def repair_monsters(tileset, dry_run=False):
    """
    Repair damaged monster tiles on rows 24-26.
    Only repairs tiles flagged as HIGH severity by the audit.
    """
    print(f"\n{'=' * 60}")
    print(f"MONSTER SPRITE REPAIR")
    print(f"{'=' * 60}")

    monster_layout = compute_monster_layout()
    repaired = []

    for mid in ALL_MONSTER_IDS:
        if mid not in monster_layout:
            continue
        col, row = monster_layout[mid]
        x0 = col * TILE_SIZE
        y0 = row * TILE_SIZE

        # Check if damaged
        tile = tileset.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))
        tile_arr = np.array(tile)
        alpha = tile_arr[:, :, 3]
        opaque_count = int(np.sum(alpha > 0))

        if opaque_count < 10:
            continue

        # Count holes
        opaque_i32 = (alpha > 0).astype(np.int32)
        h, w = opaque_i32.shape
        padded = np.pad(opaque_i32, 1, mode='constant', constant_values=0)
        neighbor_count = np.zeros_like(opaque_i32, dtype=np.int32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                neighbor_count += padded[1+dy:h+1+dy, 1+dx:w+1+dx]
        holes = int(np.sum((alpha == 0) & (neighbor_count >= 6)))

        # Count fragments
        opaque_mask = (alpha > 0)
        visited = np.zeros_like(opaque_mask, dtype=bool)
        fragments = 0
        for iy in range(h):
            for ix in range(w):
                if opaque_mask[iy, ix] and not visited[iy, ix]:
                    fragments += 1
                    fq = deque()
                    fq.append((iy, ix))
                    visited[iy, ix] = True
                    while fq:
                        cy, cx = fq.popleft()
                        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and opaque_mask[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                fq.append((ny, nx))

        # Only repair high-severity damage
        needs_repair = holes > 15 or fragments > 10
        if not needs_repair:
            continue

        colors = MONSTER_COLORS.get(mid, {"hue_deg": 0, "achromatic": True})
        label = f"monster_{mid}"
        raw_path = MONSTER_RAW_DIR / f"monster_{mid}_1024.png"

        if dry_run:
            src = "raw" if raw_path.exists() else "fallback"
            print(f"  WOULD REPAIR [{src}]: ({col},{row}) {label} "
                  f"(holes={holes}, frags={fragments})")
            repaired.append(label)
            continue

        if raw_path.exists():
            raw_img = Image.open(raw_path).convert("RGBA")

            # Step 1: BROAD HSV hue-shift (raw DALL-E needs broad detection)
            corrected = hue_shift_magenta(
                raw_img,
                target_hue_deg=colors["hue_deg"],
                achromatic=colors["achromatic"],
                broad=True,
            )

            # Step 2: Edge-only BG removal
            transparent, bg_removed = edge_only_bg_remove(corrected)

            # Step 3: Post-BG pink cleanup
            cleaned = cleanup_post_bg_pink(
                transparent,
                target_hue_deg=colors["hue_deg"],
                achromatic=colors["achromatic"],
            )

            # Step 4: Crop + resize
            cropped = auto_crop_square(cleaned)
            repaired_tile = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

            # Step 5: Patch
            clear = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear, (x0, y0))
            tileset.paste(repaired_tile, (x0, y0), repaired_tile)

            print(f"  Repaired: ({col},{row}) {label}")
            repaired.append(label)
        else:
            # Fallback
            filled_img, holes_filled = fill_interior_holes(tile)
            if holes_filled > 0:
                tileset.paste(filled_img, (x0, y0), filled_img)
                print(f"  Fallback filled: ({col},{row}) {label} ({holes_filled} holes)")
                repaired.append(label)

    print(f"\n  Monsters repaired: {len(repaired)}")
    return repaired


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Repair damaged tileset tiles")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--all", action="store_true", help="Full repair: players + items + artefacts + monsters")
    group.add_argument("--players", action="store_true", help="Player sprites only")
    group.add_argument("--items", action="store_true", help="Items only")
    group.add_argument("--artefacts", action="store_true", help="Artefacts only")
    group.add_argument("--monsters", action="store_true", help="Monsters only")
    group.add_argument("--dry-run", action="store_true", help="Show what would be repaired")

    args = parser.parse_args()

    if not any([args.all, args.players, args.items, args.artefacts, args.monsters, args.dry_run]):
        parser.print_help()
        return

    if not TILESET_PATH.exists():
        print(f"ERROR: Tileset not found: {TILESET_PATH}")
        return

    # Back up tileset before any modifications
    if not args.dry_run:
        if not BACKUP_PATH.exists():
            print(f"Backing up tileset to {BACKUP_PATH.name}...")
            shutil.copy2(TILESET_PATH, BACKUP_PATH)
            print(f"  Backup saved: {BACKUP_PATH}")
        else:
            print(f"Backup already exists: {BACKUP_PATH.name}")

    # Load tileset
    tileset = Image.open(TILESET_PATH).convert("RGBA")
    print(f"Loaded tileset: {tileset.size[0]}x{tileset.size[1]}")

    all_repaired = {}

    do_players = args.all or args.players or args.dry_run
    do_items = args.all or args.items or args.dry_run
    do_artefacts = args.all or args.artefacts or args.dry_run
    do_monsters = args.all or args.monsters or args.dry_run

    if do_players:
        all_repaired["players"] = repair_player_sprites(tileset, dry_run=args.dry_run)

    if do_items:
        all_repaired["items"] = repair_items(tileset, dry_run=args.dry_run)

    if do_artefacts:
        all_repaired["artefacts"] = repair_artefacts(tileset, dry_run=args.dry_run)

    if do_monsters:
        all_repaired["monsters"] = repair_monsters(tileset, dry_run=args.dry_run)

    # Save tileset
    if not args.dry_run:
        tileset.save(TILESET_PATH, "PNG")
        print(f"\nTileset saved: {TILESET_PATH}")

    # Summary
    print(f"\n{'=' * 60}")
    print(f"REPAIR SUMMARY")
    print(f"{'=' * 60}")
    total = 0
    for category, items in all_repaired.items():
        print(f"  {category}: {len(items)} repaired")
        total += len(items)
    print(f"  TOTAL: {total} tiles repaired")

    if not args.dry_run:
        print(f"\n  Backup: {BACKUP_PATH}")
        print(f"  Run audit to verify: python3 tileset_generation/audit_tile_damage.py")


if __name__ == "__main__":
    main()
