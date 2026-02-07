#!/usr/bin/env python3
"""
Fix Magenta Bleed in Monster Sprites v2 - HSV Hue Rotation

CRITICAL LESSONS FROM V1 (DO NOT REPEAT):
  - NEVER use RGB channel reduction -> destroys all color, turns sprites B&W
  - MUST work in HSV color space and ROTATE hues, preserving brightness
  - Color correction MUST happen BEFORE background removal (separate steps)

Algorithm:
  1. Load raw 1024x1024 from DALL-E
  2. Create background mask (strict magenta detection in RGB)
  3. Compute distance-from-background field (scipy EDT)
  4. Convert to HSV color space
  5. For creature pixels in the magenta hue zone (275-335 deg):
     - Correction strength = f(hue closeness to 300, distance from BG, saturation)
     - Achromatic creatures: desaturate the magenta zone
     - Chromatic creatures: rotate hue toward target color
  6. Convert back to RGB, save corrected image (still has magenta BG)

Then separately:
  7. 3-pass BG removal (proven from player sprites)
  8. Auto-crop + resize to 64x64
  9. Generate dark variant for FOV

Usage:
    python3 fix_monster_magenta_v2.py --correct 12 13 16 21  # Color correct specific
    python3 fix_monster_magenta_v2.py --correct-all           # Color correct ALL monsters
    python3 fix_monster_magenta_v2.py --process 12 13 16 21   # BG remove + resize
    python3 fix_monster_magenta_v2.py --process-all            # Process ALL monsters
    python3 fix_monster_magenta_v2.py --full 12 13 16 21      # Both steps
    python3 fix_monster_magenta_v2.py --full-all               # Everything, ALL monsters
    python3 fix_monster_magenta_v2.py --compare 12 13 16 21   # Before/after preview
"""

import argparse
import sys
from pathlib import Path
from collections import deque

try:
    from PIL import Image, ImageEnhance, ImageDraw
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
RAW_DIR = BASE_DIR / "monster_v2" / "raw"
TIER_DIR = BASE_DIR / "monster_v2"  # Tier subdirs created dynamically
CORRECTED_DIR = BASE_DIR / "monster_v2" / "corrected"
COMPARE_DIR = BASE_DIR / "monster_v2" / "comparisons"

TILE_SIZE = 64

TIER_1_IDS = [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 31]

# All monster IDs grouped by tier
TIER_IDS = {
    1: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 31],
    2: [32, 33, 34, 35, 36, 37, 38, 39, 40, 51],
    3: [52, 53, 54, 55, 56, 57, 58, 59, 60, 71, 73, 80, 85],
    4: [72, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 86, 91, 100],
    5: [92, 93, 94, 95, 96, 97, 98, 99, 101, 102, 103, 104, 111],
    6: [112, 113, 114, 115, 116, 117, 118, 131, 136],
    7: [132, 133, 134, 135, 137],
    8: [301, 302, 303, 304, 305, 306, 307, 308, 309, 310],
}

# ============================================================================
# PER-MONSTER COLOR TARGETS
# ============================================================================
# hue_deg: intended dominant hue (0-360 degrees)
# achromatic: if True, desaturate magenta zone instead of rotating hue
# bleed: 0=no correction needed, 1=normal, 2=heavy (user-identified worst cases)

MONSTER_COLORS = {
    # === TIER 1: OUTER PITS (Depths 1-3) ===
    11: {"name": "Mirkwood Spider",  "hue_deg": 25,  "achromatic": False, "bleed": 1},  # dark brown
    12: {"name": "Giant Rat",        "hue_deg": 25,  "achromatic": False, "bleed": 2},  # dark brown
    13: {"name": "Black Squirrel",   "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # jet black
    14: {"name": "Crebain",          "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # glossy black
    15: {"name": "Tanglethorn",      "hue_deg": 100, "achromatic": False, "bleed": 1},  # green/brown
    16: {"name": "Giant Bat",        "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # dark gray-black
    17: {"name": "Web Spinner",      "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # pale white/silver
    18: {"name": "Orc Scout",        "hue_deg": 80,  "achromatic": False, "bleed": 1},  # yellow-green
    19: {"name": "Swamp Adder",      "hue_deg": 120, "achromatic": False, "bleed": 1},  # green
    20: {"name": "Great Spider",     "hue_deg": 25,  "achromatic": False, "bleed": 1},  # dark brown-black
    21: {"name": "Warg Pup",         "hue_deg": 30,  "achromatic": False, "bleed": 2},  # tawny brown
    22: {"name": "Broodmother",      "hue_deg": 25,  "achromatic": False, "bleed": 1},  # brown-black
    31: {"name": "Orc Slave",        "hue_deg": 80,  "achromatic": False, "bleed": 1},  # gray-green
    # === TIER 2: LOWER HALLS (Depths 4-6) ===
    32: {"name": "Orc Soldier",      "hue_deg": 80,  "achromatic": False, "bleed": 1},  # dark green skin
    33: {"name": "Orc Crossbowman",  "hue_deg": 80,  "achromatic": False, "bleed": 1},  # dark green skin
    34: {"name": "Warg",             "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # dark gray fur
    35: {"name": "Orc Thrallmaster", "hue_deg": 80,  "achromatic": False, "bleed": 1},  # dark green skin
    36: {"name": "Orc Captain",      "hue_deg": 80,  "achromatic": False, "bleed": 1},  # dark green, iron
    37: {"name": "Warg Rider",       "hue_deg": 80,  "achromatic": False, "bleed": 1},  # green orc + gray warg
    38: {"name": "Hill Troll",       "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # gray rocky skin
    39: {"name": "Gashnak Warg-lord","hue_deg": 0,   "achromatic": True,  "bleed": 2},  # white fur, battle scars
    40: {"name": "Orc Warchief",     "hue_deg": 80,  "achromatic": False, "bleed": 1},  # dark green, black iron
    51: {"name": "Dark Acolyte",     "hue_deg": 260, "achromatic": False, "bleed": 1},  # dark violet robes
    # === TIER 3: DARK HALLS (Depths 7-9) ===
    52: {"name": "Ghoul",            "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # gray rotting flesh
    53: {"name": "Mirk-troll",       "hue_deg": 100, "achromatic": False, "bleed": 1},  # black-green hide
    54: {"name": "Easterling Warrior","hue_deg": 30, "achromatic": False, "bleed": 1},  # bronze armor, olive
    55: {"name": "Dark Sorcerer",    "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # black robes, pale
    56: {"name": "Tortured Wretch",  "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # pale skin, bloody
    57: {"name": "Easterling Champion","hue_deg": 40,"achromatic": False, "bleed": 1},  # gold-red armor
    58: {"name": "Ghast",            "hue_deg": 100, "achromatic": False, "bleed": 1},  # sickly green flesh
    59: {"name": "Karvag Torturer",  "hue_deg": 5,   "achromatic": False, "bleed": 1},  # blood-red skin
    60: {"name": "Master Sorcerer",  "hue_deg": 260, "achromatic": False, "bleed": 1},  # violet robes, gold
    71: {"name": "Skeleton",         "hue_deg": 40,  "achromatic": False, "bleed": 1},  # yellowed bone
    73: {"name": "Zombie",           "hue_deg": 100, "achromatic": False, "bleed": 1},  # gray-green flesh
    80: {"name": "Easterling Infiltrator","hue_deg": 0,"achromatic": True,"bleed": 1},  # dark blue-black
    85: {"name": "Tunnel Crawler",   "hue_deg": 25,  "achromatic": False, "bleed": 1},  # brown carapace
    # === TIER 4: NECROPOLIS (Depths 10-12) ===
    72: {"name": "Skeleton Warrior",  "hue_deg": 40, "achromatic": False, "bleed": 1},  # bone, rusted iron
    74: {"name": "Wight",            "hue_deg": 200, "achromatic": False, "bleed": 1},  # pale blue glow
    75: {"name": "Corpse-candle",    "hue_deg": 60,  "achromatic": False, "bleed": 1},  # yellow-green glow
    76: {"name": "Necromancer Adept","hue_deg": 100, "achromatic": False, "bleed": 1},  # dark robes, green
    77: {"name": "Barrow-wight",     "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # dark rotting, frost
    78: {"name": "Bone Golem",       "hue_deg": 40,  "achromatic": False, "bleed": 1},  # bone white
    79: {"name": "Grishnakh",        "hue_deg": 260, "achromatic": False, "bleed": 1},  # dark armor, violet
    81: {"name": "Cave Troll",       "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # gray stone skin
    82: {"name": "Dark Ritualist",   "hue_deg": 260, "achromatic": False, "bleed": 1},  # violet robes
    83: {"name": "Corsair of Umbar", "hue_deg": 210, "achromatic": False, "bleed": 1},  # dark blue leather
    84: {"name": "Dunlending",       "hue_deg": 210, "achromatic": False, "bleed": 1},  # blue woad, pale
    86: {"name": "Pale Crawler",     "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # chalk white
    91: {"name": "Phantom",          "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # translucent gray
    100:{"name": "BN Acolyte",       "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # dark robes, pale
    # === TIER 5: PITS OF DESPAIR (Depths 13-15) ===
    92: {"name": "Shadow",           "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # pure black
    93: {"name": "Whispering Shade", "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # black smoke
    94: {"name": "Wraith",           "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # dark gray robes
    95: {"name": "Fell Spirit",      "hue_deg": 260, "achromatic": False, "bleed": 1},  # dark violet energy
    96: {"name": "Spectre",          "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # pale white mist
    97: {"name": "Vampire Thrall",   "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # ashen gray
    98: {"name": "Wailing Horror",   "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # pale white
    99: {"name": "Uvatha",           "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # pitch black
    101:{"name": "Haradrim Assassin","hue_deg": 30,  "achromatic": False, "bleed": 1},  # dark robes, dark skin
    102:{"name": "Cave Worm",        "hue_deg": 210, "achromatic": False, "bleed": 1},  # blue-gray armored
    103:{"name": "Oathbreaker",      "hue_deg": 120, "achromatic": False, "bleed": 1},  # spectral green
    104:{"name": "Morgul Sorcerer",  "hue_deg": 100, "achromatic": False, "bleed": 1},  # sickly green runes
    111:{"name": "Black Numenorean", "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # dark plate, pale
    # === TIER 6: INNER SANCTUM (Depths 16-18) ===
    112:{"name": "Olog-hai",         "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # dark gray, black iron
    113:{"name": "Vampire",          "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # dark leathery
    114:{"name": "Greater Wraith",   "hue_deg": 260, "achromatic": False, "bleed": 1},  # dark violet robes
    115:{"name": "Vampire Lord",     "hue_deg": 5,   "achromatic": False, "bleed": 1},  # crimson cloak, pale
    116:{"name": "Shadow Lord",      "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # absolute black
    117:{"name": "Maia Thrall",      "hue_deg": 20,  "achromatic": False, "bleed": 1},  # orange-red fire
    118:{"name": "Khamul",           "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # pitch black
    131:{"name": "Elite Olog-hai",   "hue_deg": 0,   "achromatic": True,  "bleed": 2},  # black iron armor
    136:{"name": "BN Lord",          "hue_deg": 260, "achromatic": False, "bleed": 1},  # dark armor, purple
    # === TIER 7: THRONE ROOM (Depths 19-20) ===
    132:{"name": "Greater Shadow",   "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # void black
    133:{"name": "Void Wraith",      "hue_deg": 260, "achromatic": False, "bleed": 1},  # void-black, violet
    134:{"name": "Thrain's Shade",   "hue_deg": 200, "achromatic": False, "bleed": 1},  # blue-white spectral
    135:{"name": "Sauron",           "hue_deg": 40,  "achromatic": False, "bleed": 1},  # black+burning gold
    137:{"name": "Mouth of Sauron",  "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # black armor
    # === TIER 8: HALLUCINATIONS ===
    301:{"name": "Gandalf",          "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # gray robes
    302:{"name": "Thranduil",        "hue_deg": 100, "achromatic": False, "bleed": 1},  # silver-green
    303:{"name": "Galadriel",        "hue_deg": 0,   "achromatic": True,  "bleed": 1},  # white glowing
    304:{"name": "Elrond",           "hue_deg": 220, "achromatic": False, "bleed": 1},  # dark blue robes
    305:{"name": "Thorin",           "hue_deg": 220, "achromatic": False, "bleed": 1},  # blue-silver armor
    306:{"name": "Beorn",            "hue_deg": 25,  "achromatic": False, "bleed": 1},  # bear-brown
    307:{"name": "Radagast",         "hue_deg": 25,  "achromatic": False, "bleed": 1},  # brown robes
    308:{"name": "Eagle",            "hue_deg": 35,  "achromatic": False, "bleed": 1},  # golden-brown
    309:{"name": "Great Elk",        "hue_deg": 210, "achromatic": False, "bleed": 1},  # blue-gray fur
    310:{"name": "Ent",              "hue_deg": 25,  "achromatic": False, "bleed": 1},  # dark brown bark
}

ALL_IDS = sorted(MONSTER_COLORS.keys())

# Magenta hue zone (degrees)
MAGENTA_ZONE_MIN = 275
MAGENTA_ZONE_MAX = 335
MAGENTA_CENTER = 300

# Distance field parameters (in 1024-pixel space)
MAX_BLEED_DISTANCE = 60
GAUSSIAN_SIGMA = 5


# ============================================================================
# HSV CONVERSION (vectorized numpy, no external deps)
# ============================================================================

def rgb_to_hsv(rgb_array):
    """
    RGB -> HSV, vectorized.
    Input:  float64 (H, W, 3), values 0-255
    Output: float64 (H, W, 3), H=0-360, S=0-1, V=0-1
    """
    arr = rgb_array / 255.0
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    hue = np.zeros_like(cmax)
    nonzero = delta > 1e-10

    # Priority: r > g > b for tie-breaking
    mask_r = nonzero & (cmax == r)
    mask_g = nonzero & (cmax == g) & ~mask_r
    mask_b = nonzero & ~mask_r & ~mask_g

    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6.0)
    hue[mask_g] = 60.0 * ((b[mask_g] - r[mask_g]) / delta[mask_g] + 2.0)
    hue[mask_b] = 60.0 * ((r[mask_b] - g[mask_b]) / delta[mask_b] + 4.0)
    hue = hue % 360.0

    sat = np.where(cmax > 1e-10, delta / cmax, 0.0)
    val = cmax

    return np.stack([hue, sat, val], axis=-1)


def hsv_to_rgb(hsv_array):
    """
    HSV -> RGB, vectorized.
    Input:  float64 (H, W, 3), H=0-360, S=0-1, V=0-1
    Output: float64 (H, W, 3), values 0-255
    """
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
# CORE: MAGENTA BLEED CORRECTION
# ============================================================================

def correct_magenta_bleed(img, target_hue_deg, achromatic=False, bleed_severity=1):
    """
    Fix magenta bleed using HSV hue rotation.

    For creature pixels whose hue falls in the magenta zone:
    - Chromatic: rotate hue toward target_hue_deg
    - Achromatic: desaturate to remove the pink tint

    Correction strength is modulated by:
    - Distance from background (closer = stronger bleed = more correction)
    - Hue proximity to pure magenta (300 deg)
    - Pixel saturation (more saturated magenta = more obvious)

    Returns corrected image (still has magenta BG - removal is separate).
    """
    if bleed_severity == 0:
        print("    Bleed severity 0 - no correction needed")
        return img

    rgba = img.convert("RGBA")
    arr = np.array(rgba).astype(np.float64)
    h, w = arr.shape[:2]

    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    # --- Background mask (strict magenta) ---
    bg_mask = (r > 150) & (g < r * 0.55) & ((r - g) > 70) & (b > g * 0.8)
    creature_mask = ~bg_mask
    creature_count = int(np.sum(creature_mask))
    print(f"    BG: {np.sum(bg_mask):,} px | Creature: {creature_count:,} px")

    # --- Distance from background (EDT) ---
    dist = distance_transform_edt(creature_mask.astype(np.float64))
    if bleed_severity >= 2:
        # Heavy bleed: DALL-E tints the ENTIRE creature, not just edges.
        # Use a minimum floor so interior pixels still get corrected.
        bleed_range = MAX_BLEED_DISTANCE * 5.0  # 300px range
        bleed_factor = np.clip(1.0 - dist / bleed_range, 0, 1)
        bleed_factor = gaussian_filter(bleed_factor, sigma=GAUSSIAN_SIGMA)
        bleed_factor = np.maximum(bleed_factor, 0.6)  # floor: 60% correction everywhere
    else:
        bleed_range = MAX_BLEED_DISTANCE
        bleed_factor = np.clip(1.0 - dist / bleed_range, 0, 1)
        bleed_factor = gaussian_filter(bleed_factor, sigma=GAUSSIAN_SIGMA)

    # --- Convert to HSV ---
    hsv = rgb_to_hsv(rgb)
    hue = hsv[:, :, 0]
    sat = hsv[:, :, 1]
    val = hsv[:, :, 2]

    # --- Identify magenta zone pixels ---
    if bleed_severity >= 2:
        # Heavy bleed: DALL-E shifts creature hues far from magenta.
        # Zone wraps around 360/0: 255-360 AND 0-25 (warm pinks/reds)
        in_magenta = ((hue >= 255) & (hue <= 360)) | ((hue >= 0) & (hue <= 25))
        min_sat = 0.06
    else:
        in_magenta = (hue >= MAGENTA_ZONE_MIN) & (hue <= MAGENTA_ZONE_MAX)
        min_sat = 0.12
    needs_correction = creature_mask & in_magenta & (sat > min_sat) & (bleed_factor > 0.02)

    correction_count = int(np.sum(needs_correction))
    if correction_count == 0:
        print("    No pixels need correction")
        return img

    pct = correction_count / max(creature_count, 1) * 100
    print(f"    Magenta zone pixels: {correction_count:,} ({pct:.1f}% of creature)")

    # --- Per-pixel correction strength ---
    # Factor 1: hue proximity to magenta center (300 deg)
    hue_dist = np.minimum(
        np.abs(hue - MAGENTA_CENTER),
        360 - np.abs(hue - MAGENTA_CENTER)
    )
    if bleed_severity >= 2:
        hue_zone_width = 52.5  # half of the 255-360+0-25 = 130deg zone
    else:
        hue_zone_width = (MAGENTA_ZONE_MAX - MAGENTA_ZONE_MIN) / 2.0
    hue_weight = np.clip(1.0 - hue_dist / hue_zone_width, 0, 1)

    if bleed_severity >= 2:
        # Heavy bleed: DALL-E tinted the ENTIRE creature toward magenta.
        # Use aggressive correction - hue proximity is the main factor,
        # with a high floor so even zone-edge pixels get corrected.
        strength = np.clip(hue_weight + 0.35, 0, 1.0)
        # Edge pixels get a small extra boost
        edge_boost = np.clip(bleed_factor * 0.15, 0, 0.15)
        strength = np.clip(strength + edge_boost, 0, 1.0)
    else:
        # Mild bleed: mostly edge effect, use distance + saturation modulation
        sat_weight = np.clip(sat * 2.0, 0, 1)
        strength = hue_weight * bleed_factor * sat_weight
        strength = np.clip(strength, 0, 1)

    # --- Apply correction ---
    new_hue = hue.copy()
    new_sat = sat.copy()

    if achromatic:
        desat = strength * 0.95  # aggressive desaturation for black/gray creatures
        new_sat = np.where(needs_correction, sat * (1 - desat), sat)
        print(f"    Mode: achromatic desaturation (95%)")
    else:
        target = float(target_hue_deg)
        diff = target - hue
        diff = ((diff + 180) % 360) - 180  # shortest rotation

        new_hue = np.where(needs_correction, (hue + diff * strength) % 360, hue)
        mild_desat = strength * 0.15
        new_sat = np.where(needs_correction, sat * (1 - mild_desat), sat)

        rotation = abs(((target - MAGENTA_CENTER + 180) % 360) - 180)
        print(f"    Mode: hue rotation {MAGENTA_CENTER} -> {target_hue_deg} deg (max {rotation:.0f} deg)")

    # --- Convert back to RGB ---
    new_hsv = np.stack([new_hue, new_sat, val], axis=-1)
    new_rgb = hsv_to_rgb(new_hsv)

    # Only replace corrected pixels
    result_rgb = rgb.copy()
    result_rgb[needs_correction] = new_rgb[needs_correction]

    result = np.zeros_like(arr)
    result[:, :, :3] = result_rgb
    result[:, :, 3] = alpha

    print(f"    Corrected {correction_count:,} pixels")
    return Image.fromarray(np.clip(result, 0, 255).astype(np.uint8), "RGBA")


# ============================================================================
# BG REMOVAL (proven 3-pass from player sprites / v1)
# ============================================================================

def bg_remove_3pass(img):
    """
    3-pass magenta background removal.
    Pass 1: Edge flood fill (8-directional BFS from borders)
    Pass 2: Interior pink cleanup (enclosed pockets)
    Pass 3: Fringe cleanup (anti-aliasing, 2 iterations)
    """
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


# ============================================================================
# POST-BG CLEANUP: Kill ALL remaining pink/magenta on creature
# ============================================================================

def cleanup_remaining_pink(img, target_hue_deg, achromatic=False):
    """
    Aggressive post-BG-removal cleanup.

    After background removal, every visible pixel IS the creature.
    ANY pink/magenta/purple hue on it is wrong and gets fixed.

    Zone: 230-360 and 0-30 (very wide - catches all pinks, magentas, purples)
    Strength: 0.92 (near-full rotation/desaturation)
    No distance modulation - every pink pixel gets fixed.
    """
    rgba = np.array(img.convert("RGBA")).astype(np.float64)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    visible = alpha > 10
    visible_count = int(np.sum(visible))
    if visible_count == 0:
        return img

    hsv = rgb_to_hsv(rgb)
    hue = hsv[:, :, 0]
    sat = hsv[:, :, 1]
    val = hsv[:, :, 2]

    # Very wide pink/magenta/purple zone: 230-360 and 0-30
    in_pink = visible & (
        ((hue >= 230) & (hue <= 360)) |
        ((hue >= 0) & (hue <= 30))
    ) & (sat > 0.06)

    pink_count = int(np.sum(in_pink))
    if pink_count == 0:
        print(f"    Cleanup: no pink pixels found")
        return img

    pct = pink_count / max(visible_count, 1) * 100
    print(f"    Cleanup: {pink_count:,} pink pixels ({pct:.1f}% of creature)")

    new_hue = hue.copy()
    new_sat = sat.copy()

    if achromatic:
        # Kill saturation entirely for black/gray/white creatures
        new_sat = np.where(in_pink, sat * 0.05, sat)
        print(f"    Cleanup mode: achromatic (95% desaturation)")
    else:
        target = float(target_hue_deg)
        diff = ((target - hue + 180) % 360) - 180
        strength = 0.92
        new_hue = np.where(in_pink, (hue + diff * strength) % 360, hue)
        # Also slightly desaturate highly-saturated pink remnants
        new_sat = np.where(in_pink & (sat > 0.4), sat * 0.8, sat)
        print(f"    Cleanup mode: hue rotation -> {target_hue_deg} deg at {strength}")

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
# PIPELINE FUNCTIONS
# ============================================================================

def correct_monster(monster_id):
    """Step 1: Color correction only. Saves to corrected/ dir."""
    raw_path = RAW_DIR / f"monster_{monster_id}_1024.png"
    if not raw_path.exists():
        print(f"  SKIP: {raw_path.name} not found")
        return False

    config = MONSTER_COLORS.get(monster_id)
    if not config:
        print(f"  SKIP: no color config for monster_{monster_id}")
        return False

    print(f"\n  [{monster_id}] {config['name']} - Color correction")
    img = Image.open(raw_path).convert("RGBA")

    corrected = correct_magenta_bleed(
        img,
        target_hue_deg=config["hue_deg"],
        achromatic=config["achromatic"],
        bleed_severity=config["bleed"],
    )

    CORRECTED_DIR.mkdir(parents=True, exist_ok=True)
    out_path = CORRECTED_DIR / f"monster_{monster_id}_corrected.png"
    corrected.save(out_path)
    print(f"    Saved: {out_path}")
    return True


def get_tier_for_monster(monster_id):
    """Determine which tier a monster belongs to."""
    for tier, ids in TIER_IDS.items():
        if monster_id in ids:
            return tier
    return 1  # fallback


def process_monster(monster_id):
    """Step 2: BG removal + aggressive pink cleanup + crop + resize + dark."""
    # Prefer corrected version, fall back to raw
    corrected_path = CORRECTED_DIR / f"monster_{monster_id}_corrected.png"
    raw_path = RAW_DIR / f"monster_{monster_id}_1024.png"

    if corrected_path.exists():
        src = corrected_path
        print(f"\n  [{monster_id}] Processing (from corrected)")
    elif raw_path.exists():
        src = raw_path
        print(f"\n  [{monster_id}] Processing (from raw - no correction applied)")
    else:
        print(f"  SKIP: no source for monster_{monster_id}")
        return False

    config = MONSTER_COLORS.get(monster_id, {"hue_deg": 25, "achromatic": False})
    img = Image.open(src).convert("RGBA")

    # BG removal
    print(f"    BG removal...")
    transparent = bg_remove_3pass(img)

    # AGGRESSIVE POST-BG CLEANUP: kill ALL remaining pink/magenta
    print(f"    Post-BG pink cleanup...")
    cleaned = cleanup_remaining_pink(
        transparent,
        target_hue_deg=config["hue_deg"],
        achromatic=config["achromatic"],
    )

    # Crop + square
    cropped = auto_crop_square(cleaned)
    print(f"    Cropped: {cropped.size[0]}x{cropped.size[1]}")

    # Resize
    img_64 = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

    # Save light into correct tier subdir
    tier = get_tier_for_monster(monster_id)
    tier_dir = TIER_DIR / f"tier_{tier}"
    tier_dir.mkdir(parents=True, exist_ok=True)
    light_path = tier_dir / f"monster_{monster_id}_light.png"
    img_64.save(light_path)
    print(f"    Saved: {light_path.name} (tier_{tier}/)")

    # Dark variant
    dark = generate_dark_variant(img_64)
    dark_path = tier_dir / f"monster_{monster_id}_dark.png"
    dark.save(dark_path)
    print(f"    Saved: {dark_path.name}")

    return True


def save_comparison(monster_ids):
    """Generate side-by-side comparison: original raw crop vs corrected crop."""
    COMPARE_DIR.mkdir(parents=True, exist_ok=True)

    # Show 200x200 center crops from 1024 images
    crop_size = 300
    scale = 1
    margin = 8
    label_h = 20

    n = len(monster_ids)
    cols = min(n, 4)
    rows = (n + cols - 1) // cols

    cell_w = crop_size * 2 + margin * 3
    cell_h = crop_size + label_h + margin

    out_w = cell_w * cols + margin
    out_h = cell_h * rows + label_h + margin * 2

    out = Image.new("RGB", (out_w, out_h), (30, 30, 30))
    draw = ImageDraw.Draw(out)
    draw.text((margin, 4), "MAGENTA BLEED FIX v2 - Original (left) vs Corrected (right)", fill=(255, 255, 200))

    for i, mid in enumerate(monster_ids):
        r = i // cols
        c = i % cols
        x_base = margin + c * cell_w
        y_base = label_h + margin + r * cell_h

        config = MONSTER_COLORS.get(mid, {"name": f"#{mid}", "bleed": 0})

        # Load original raw
        raw_path = RAW_DIR / f"monster_{mid}_1024.png"
        corrected_path = CORRECTED_DIR / f"monster_{mid}_corrected.png"

        if raw_path.exists():
            raw_img = Image.open(raw_path).convert("RGB")
            cx, cy = raw_img.size[0] // 2, raw_img.size[1] // 2
            half = crop_size // 2
            crop_box = (cx - half, cy - half, cx + half, cy + half)
            raw_crop = raw_img.crop(crop_box)
            out.paste(raw_crop, (x_base, y_base))

        if corrected_path.exists():
            cor_img = Image.open(corrected_path).convert("RGB")
            cx, cy = cor_img.size[0] // 2, cor_img.size[1] // 2
            cor_crop = cor_img.crop(crop_box)
            out.paste(cor_crop, (x_base + crop_size + margin, y_base))
        else:
            draw.text(
                (x_base + crop_size + margin + 20, y_base + crop_size // 2),
                "Not corrected yet",
                fill=(255, 100, 100),
            )

        bleed_tag = ["none", "mild", "HEAVY"][config["bleed"]]
        label = f"m_{mid} {config['name']} (bleed: {bleed_tag})"
        draw.text((x_base, y_base + crop_size + 2), label, fill=(200, 200, 200))

    comp_path = COMPARE_DIR / f"comparison_{'_'.join(str(m) for m in monster_ids)}.png"
    out.save(comp_path)
    print(f"\nComparison saved: {comp_path}")
    return comp_path


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Fix magenta bleed v2 - HSV hue rotation")

    group = parser.add_mutually_exclusive_group()
    group.add_argument("--correct", nargs="+", type=int, metavar="ID",
                       help="Color correct specific monster IDs")
    group.add_argument("--correct-all", action="store_true",
                       help="Color correct ALL monsters (all tiers)")
    group.add_argument("--process", nargs="+", type=int, metavar="ID",
                       help="BG remove + resize specific IDs (after correction)")
    group.add_argument("--process-all", action="store_true",
                       help="BG remove + resize ALL monsters (all tiers)")
    group.add_argument("--full", nargs="+", type=int, metavar="ID",
                       help="Full pipeline (correct + process) specific IDs")
    group.add_argument("--full-all", action="store_true",
                       help="Full pipeline ALL monsters (all tiers)")
    group.add_argument("--compare", nargs="+", type=int, metavar="ID",
                       help="Generate before/after comparison image")

    args = parser.parse_args()

    if args.correct:
        ids = args.correct
        print(f"{'=' * 60}")
        print(f"COLOR CORRECTION (HSV hue rotation) - {len(ids)} monsters")
        print(f"{'=' * 60}")
        ok = sum(1 for mid in ids if correct_monster(mid))
        print(f"\nDone: {ok}/{len(ids)} corrected")

    elif args.correct_all:
        ids = ALL_IDS
        print(f"{'=' * 60}")
        print(f"COLOR CORRECTION ALL MONSTERS - {len(ids)} monsters")
        print(f"{'=' * 60}")
        ok = sum(1 for mid in ids if correct_monster(mid))
        print(f"\nDone: {ok}/{len(ids)} corrected")

    elif args.process:
        ids = args.process
        print(f"{'=' * 60}")
        print(f"BG REMOVAL + RESIZE - {len(ids)} monsters")
        print(f"{'=' * 60}")
        ok = sum(1 for mid in ids if process_monster(mid))
        print(f"\nDone: {ok}/{len(ids)} processed")

    elif args.process_all:
        ids = ALL_IDS
        print(f"{'=' * 60}")
        print(f"BG REMOVAL + RESIZE ALL MONSTERS - {len(ids)} monsters")
        print(f"{'=' * 60}")
        ok = sum(1 for mid in ids if process_monster(mid))
        print(f"\nDone: {ok}/{len(ids)} processed")

    elif args.full:
        ids = args.full
        print(f"{'=' * 60}")
        print(f"FULL PIPELINE - {len(ids)} monsters")
        print(f"{'=' * 60}")
        print("\n--- Step 1: Color Correction ---")
        for mid in ids:
            correct_monster(mid)
        print("\n--- Step 2: BG Removal + Resize ---")
        ok = sum(1 for mid in ids if process_monster(mid))
        print(f"\nDone: {ok}/{len(ids)} fully processed")

    elif args.full_all:
        ids = ALL_IDS
        print(f"{'=' * 60}")
        print(f"FULL PIPELINE ALL MONSTERS - {len(ids)} monsters")
        print(f"{'=' * 60}")
        print("\n--- Step 1: Color Correction ---")
        for mid in ids:
            correct_monster(mid)
        print("\n--- Step 2: BG Removal + Resize ---")
        ok = sum(1 for mid in ids if process_monster(mid))
        print(f"\nDone: {ok}/{len(ids)} fully processed")

    elif args.compare:
        ids = args.compare
        save_comparison(ids)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
