#!/usr/bin/env python3
"""
Monster Sprite Processor v3 — ML-Based BG Removal Pipeline

Uses rembg (U2NET) for shape-based background removal instead of color-based
approaches. This solves the fundamental problem: many DALL-E monsters have
magenta/purple body tones that color-based removal can't distinguish from BG.

Pipeline:
  1. rembg removes background using ML segmentation (shape, not color)
  2. Morphological cleanup: fill holes, remove fragments, close gaps
  3. Magenta desaturation: clean up BG color bleed on creature edges
  4. Auto-crop + NEAREST resize to 64x64
  5. Dark variant generation

Usage:
    python3 process_monsters_v3.py --tier 1              # Process Tier 1 from corrected/
    python3 process_monsters_v3.py --tier 1 --from-raw   # Use raw DALL-E files
    python3 process_monsters_v3.py --ids 11 13 16        # Specific monsters
    python3 process_monsters_v3.py --tier 1 --montage-only
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
    from scipy.ndimage import (
        binary_fill_holes,
        binary_closing,
        binary_dilation,
        binary_erosion,
        label as scipy_label,
    )
    from rembg import remove as rembg_remove
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install: pip3 install pillow numpy scipy rembg[cpu]")
    sys.exit(1)

# ============================================================================
# PATHS & CONSTANTS
# ============================================================================

BASE_DIR = Path(__file__).parent
RAW_DIR = BASE_DIR / "monster_v2" / "raw"
CORRECTED_DIR = BASE_DIR / "monster_v2" / "corrected"
OUTPUT_DIR = BASE_DIR / "monster_v3"

TILE_SIZE = 64

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

MONSTER_COLORS = {
    11: {"name": "Mirkwood Spider",  "achromatic": False},
    12: {"name": "Giant Rat",        "achromatic": False},
    13: {"name": "Black Squirrel",   "achromatic": True},
    14: {"name": "Crebain",          "achromatic": True},
    15: {"name": "Tanglethorn",      "achromatic": False},
    16: {"name": "Giant Bat",        "achromatic": True},
    17: {"name": "Web Spinner",      "achromatic": True},
    18: {"name": "Orc Scout",        "achromatic": False},
    19: {"name": "Swamp Adder",      "achromatic": False},
    20: {"name": "Great Spider",     "achromatic": False},
    21: {"name": "Warg Pup",         "achromatic": False},
    22: {"name": "Broodmother",      "achromatic": False},
    31: {"name": "Orc Slave",        "achromatic": False},
    32: {"name": "Orc Soldier",      "achromatic": False},
    33: {"name": "Orc Crossbowman",  "achromatic": False},
    34: {"name": "Warg",             "achromatic": True},
    35: {"name": "Orc Thrallmaster", "achromatic": False},
    36: {"name": "Orc Captain",      "achromatic": False},
    37: {"name": "Warg Rider",       "achromatic": False},
    38: {"name": "Hill Troll",       "achromatic": True},
    39: {"name": "Gashnak",          "achromatic": True},
    40: {"name": "Orc Warchief",     "achromatic": False},
    51: {"name": "Dark Acolyte",     "achromatic": False},
    52: {"name": "Ghoul",            "achromatic": True},
    53: {"name": "Mirk-troll",       "achromatic": False},
    54: {"name": "Easterling War.",   "achromatic": False},
    55: {"name": "Dark Sorcerer",    "achromatic": True},
    56: {"name": "Tortured Wretch",  "achromatic": True},
    57: {"name": "Easterling Champ", "achromatic": False},
    58: {"name": "Ghast",            "achromatic": True},
    59: {"name": "Karvag",           "achromatic": False},
    60: {"name": "Master Sorcerer",  "achromatic": False},
    71: {"name": "Skeleton",         "achromatic": True},
    72: {"name": "Skeleton Warrior", "achromatic": False},
    73: {"name": "Zombie",           "achromatic": False},
    74: {"name": "Wight",            "achromatic": True},
    75: {"name": "Corpse-candle",    "achromatic": False},
    76: {"name": "Necromancer Adept","achromatic": False},
    77: {"name": "Barrow-wight",     "achromatic": True},
    78: {"name": "Bone Golem",       "achromatic": True},
    79: {"name": "Grishnakh",        "achromatic": False},
    80: {"name": "East. Infiltr.",   "achromatic": False},
    81: {"name": "Cave Troll",       "achromatic": True},
    82: {"name": "Dark Ritualist",   "achromatic": False},
    83: {"name": "Corsair",          "achromatic": False},
    84: {"name": "Dunlending",       "achromatic": False},
    85: {"name": "Tunnel Crawler",   "achromatic": False},
    86: {"name": "Pale Crawler",     "achromatic": True},
    91: {"name": "Phantom",          "achromatic": True},
    92: {"name": "Shadow",           "achromatic": True},
    93: {"name": "Whispering Shade", "achromatic": True},
    94: {"name": "Wraith",           "achromatic": True},
    95: {"name": "Fell Spirit",      "achromatic": False},
    96: {"name": "Spectre",          "achromatic": True},
    97: {"name": "Vampire Thrall",   "achromatic": True},
    98: {"name": "Wailing Horror",   "achromatic": True},
    99: {"name": "Uvatha",           "achromatic": True},
    100: {"name": "BN Acolyte",      "achromatic": False},
    101: {"name": "Haradrim Assn.",  "achromatic": False},
    102: {"name": "Cave Worm",       "achromatic": False},
    103: {"name": "Oathbreaker",     "achromatic": True},
    104: {"name": "Morgul Sorcerer", "achromatic": False},
    111: {"name": "Black Numenorean","achromatic": True},
    112: {"name": "Olog-hai",        "achromatic": True},
    113: {"name": "Vampire",         "achromatic": True},
    114: {"name": "Greater Wraith",  "achromatic": True},
    115: {"name": "Vampire Lord",    "achromatic": False},
    116: {"name": "Shadow Lord",     "achromatic": True},
    117: {"name": "Maia Thrall",     "achromatic": False},
    118: {"name": "Khamul",          "achromatic": True},
    131: {"name": "Elite Olog-hai",  "achromatic": True},
    132: {"name": "Greater Shadow",  "achromatic": True},
    133: {"name": "Void Wraith",     "achromatic": False},
    134: {"name": "Thrain's Shade",  "achromatic": True},
    135: {"name": "Sauron",          "achromatic": False},
    136: {"name": "BN Lord",         "achromatic": False},
    137: {"name": "Mouth of Sauron", "achromatic": True},
    301: {"name": "Gandalf",         "achromatic": True},
    302: {"name": "Thranduil",       "achromatic": False},
    303: {"name": "Galadriel",       "achromatic": True},
    304: {"name": "Elrond",          "achromatic": False},
    305: {"name": "Thorin",          "achromatic": False},
    306: {"name": "Beorn",           "achromatic": False},
    307: {"name": "Radagast",        "achromatic": False},
    308: {"name": "Eagle",           "achromatic": False},
    309: {"name": "Great Elk",       "achromatic": False},
    310: {"name": "Ent",             "achromatic": False},
}


# ============================================================================
# CORE: rembg ML Background Removal + Morphological Cleanup
# ============================================================================

def remove_background_ml(img_1024, monster_id=None):
    """Remove background using rembg (U2NET ML segmentation).

    rembg detects the foreground object by shape, not color — this solves
    the fundamental problem of magenta-bodied creatures on magenta backgrounds.

    After rembg, we apply morphological cleanup to:
    - Fill small interior holes
    - Remove tiny fragments
    - Close small gaps in the mask
    """
    result = rembg_remove(img_1024)

    arr = np.array(result)
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    # Per-monster alpha threshold (lower = keep more of soft-alpha regions)
    alpha_thresh = ALPHA_THRESHOLD.get(monster_id, 127)
    if alpha_thresh != 127:
        print(f"      Custom alpha threshold: {alpha_thresh}")
    creature_mask = alpha > alpha_thresh

    opaque_before = np.sum(creature_mask)
    print(f"      rembg raw: {100 * opaque_before / (h * w):.1f}% opaque")

    # Morphological closing: seal small gaps (5px radius at 1024x1024)
    struct = np.ones((11, 11), dtype=bool)
    creature_closed = binary_closing(creature_mask, structure=struct, iterations=1)

    # Fill interior holes
    creature_filled = binary_fill_holes(creature_closed)
    filled_diff = np.sum(creature_filled) - np.sum(creature_closed)
    print(f"      Holes filled: {filled_diff} pixels recovered")

    # Remove small fragments — keep components > threshold% of largest
    frag_thresh = FRAGMENT_THRESHOLD.get(monster_id, 0.02)
    if frag_thresh != 0.02:
        print(f"      Custom fragment threshold: {frag_thresh}")
    labeled, num_features = scipy_label(creature_filled)
    if num_features > 1:
        component_sizes = np.bincount(labeled.ravel())[1:]
        largest_size = component_sizes.max()
        keep_mask = np.zeros_like(creature_filled)
        kept = 0
        for lbl in range(1, num_features + 1):
            if component_sizes[lbl - 1] > largest_size * frag_thresh:
                keep_mask |= (labeled == lbl)
                kept += 1
        creature_final = keep_mask
        print(f"      Fragments: {num_features} components, kept {kept}")
    else:
        creature_final = creature_filled
        print(f"      Fragments: 1 component (clean)")

    # Apply cleaned mask back to original RGBA
    clean_alpha = (creature_final * 255).astype(np.uint8)
    arr[:, :, 3] = clean_alpha

    opaque_after = np.sum(creature_final)
    print(f"      After cleanup: {100 * opaque_after / (h * w):.1f}% opaque")

    return Image.fromarray(arr, "RGBA")


# ============================================================================
# Color-Merge Recovery: Recover thin features rembg misses
# ============================================================================

def color_merge_recovery(img_rembg, img_raw, monster_id):
    """Merge color-extracted non-BG pixels from raw into rembg result.

    rembg classifies thin features (sword blades, chains, weapon glow) as
    background because it detects by shape/contour, not color. This function:
    1. Takes the rembg result (body detected)
    2. Color-extracts non-BG pixels from the raw image (the weapon/feature)
    3. Merges the two masks with OR
    4. Applies morphological closing to seal gaps

    Only works for GREEN_BG_MONSTERS — green is easy to distinguish from
    metallic/warm weapon colors.
    """
    rembg_arr = np.array(img_rembg).copy()
    raw_arr = np.array(img_raw).astype(np.float64) / 255.0
    h, w = raw_arr.shape[:2]

    r, g, b = raw_arr[:, :, 0], raw_arr[:, :, 1], raw_arr[:, :, 2]
    rembg_alpha = rembg_arr[:, :, 3] > 127

    is_green_bg = monster_id in GREEN_BG_MONSTERS

    if is_green_bg:
        # Green BG: detect pixels with significant non-green content.
        # Conservative — targets weapon metal, armor, skin. Not "everything
        # that isn't green" (which grabs BG shadows and gradients).
        # A pixel is "creature" if it has meaningful red OR blue channel,
        # indicating warm/metallic/neutral tones rather than green BG.
        has_red = (r > 0.20) & (r > g * 0.7)
        has_blue = (b > 0.20) & (b > g * 0.7)
        # Also catch dark content (dark armor, shadows) that isn't green-tinted
        brightness = (r + g + b) / 3
        is_dark_content = (brightness > 0.03) & (brightness < 0.18) & (g < r * 1.5) & (g < b * 1.5)
        creature_color = has_red | has_blue | is_dark_content
    else:
        # Magenta BG: anything not magenta with meaningful content
        is_mag = (r > 0.55) & (g < 0.30) & (b > 0.35)
        has_green = (g > 0.20) & (g > r * 0.7) & (g > b * 0.7)
        brightness = (r + g + b) / 3
        is_dark_content = (brightness > 0.03) & (brightness < 0.18) & ~is_mag
        creature_color = (has_green | is_dark_content) & ~is_mag

    # Merge: rembg body + color-extracted features
    combined = rembg_alpha | creature_color

    # Close small gaps but don't fill large holes (would fill BG pockets)
    combined = binary_closing(combined, iterations=2)

    # Fragment removal — keep components that are either:
    # (a) large (> 2% of largest), OR
    # (b) near the rembg body (within 30px) — these are weapon/detail fragments
    rembg_dilated = binary_dilation(rembg_alpha, iterations=30)
    labeled, n_features = scipy_label(combined)
    if n_features > 1:
        sizes = np.bincount(labeled.ravel())[1:]
        max_size = sizes.max()
        frag_thresh = FRAGMENT_THRESHOLD.get(monster_id, 0.02)
        keep = np.zeros_like(combined)
        kept = 0
        for i in range(1, n_features + 1):
            component = (labeled == i)
            is_large = sizes[i - 1] > max_size * frag_thresh
            is_near_body = np.any(component & rembg_dilated)
            # Keep if large OR near the body (min 10px to skip single-pixel noise)
            if is_large or (is_near_body and sizes[i - 1] >= 10):
                keep |= component
                kept += 1
        combined = keep
        print(f"      Color merge: {n_features} components -> kept {kept}")

    combined_pct = 100 * np.sum(combined) / (h * w)
    added = np.sum(combined & ~rembg_alpha)
    print(f"      Color merge: recovered {added} px ({100*added/(h*w):.1f}%), total {combined_pct:.1f}%")

    # Apply merged mask to the raw image RGB (not the rembg-processed one,
    # which may have altered colors in removed areas)
    out_arr = np.zeros((h, w, 4), dtype=np.uint8)
    out_arr[:, :, :3] = (raw_arr[:, :, :3] * 255).astype(np.uint8)
    out_arr[:, :, 3] = (combined * 255).astype(np.uint8)

    return Image.fromarray(out_arr, "RGBA")


# ============================================================================
# Post-processing: Hard BG Remnant Removal
# ============================================================================

def remove_bg_remnants(img_rgba, bg_type="magenta"):
    """Make pixels that are clearly BG color fully transparent.

    rembg sometimes includes BG-colored pixels in the foreground mask,
    especially between thin appendages (spider legs, bat wing tips).
    This pass makes very bright, saturated BG-colored pixels transparent.

    Unlike the soft desaturation passes, this is a hard removal — pixels
    are either kept or made transparent.

    bg_type: "magenta" (hue 280-360/0-20°) or "green" (hue 80-160°)
    """
    arr = np.array(img_rgba).copy()
    rgb = arr[:, :, :3].astype(np.float64) / 255.0
    alpha = arr[:, :, 3]

    visible = alpha > 0
    if not np.any(visible):
        return img_rgba

    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc

    hue = np.zeros_like(maxc)
    mask_nonzero = diff > 0.001
    mask_r = (maxc == r) & mask_nonzero
    mask_g = (maxc == g) & mask_nonzero & ~mask_r
    mask_b = (maxc == b) & mask_nonzero & ~mask_r & ~mask_g

    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / diff[mask_r]) % 6)
    hue[mask_g] = 60.0 * (((b[mask_g] - r[mask_g]) / diff[mask_g]) + 2)
    hue[mask_b] = 60.0 * (((r[mask_b] - g[mask_b]) / diff[mask_b]) + 4)

    sat = np.where(maxc > 0.001, diff / maxc, 0.0)

    if bg_type == "green":
        # Bright saturated green: clearly BG remnant
        is_bg = visible & (hue >= 80) & (hue <= 160) & (sat > 0.40) & (maxc > 0.35)
    else:
        # Bright saturated magenta/pink: clearly BG remnant
        is_bg = visible & (
            ((hue >= 280) & (hue <= 360)) | (hue < 20)
        ) & (sat > 0.40) & (maxc > 0.35)

    bg_count = np.sum(is_bg)
    if bg_count == 0:
        print(f"      BG remnant removal ({bg_type}): none found")
        return img_rgba

    visible_count = np.sum(visible)
    bg_pct = 100 * bg_count / visible_count
    print(f"      BG remnant removal ({bg_type}): {bg_count} pixels ({bg_pct:.1f}%) → transparent")

    arr[:, :, 3][is_bg] = 0
    return Image.fromarray(arr, "RGBA")


# ============================================================================
# Post-processing: Soft BG Bleed Desaturation, Crop, Resize, Dark Variant
# ============================================================================

def cleanup_magenta_bleed(img_rgba):
    """Edge-aware magenta desaturation on creature body.

    DALL-E's magenta BG isn't a single color code — it's a gradient of
    magenta-ish tones that bleeds into creature edges. After BG removal,
    we aggressively desaturate remaining magenta, with extra strength
    near the transparency boundary (where BG bleed concentrates).

    Two zones:
    - EDGE (within 30px of transparency): 95% desaturation (nearly full)
    - INTERIOR (deep in body): 80% desaturation (strong but preserves hints)
    """
    from scipy.ndimage import distance_transform_edt

    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]

    visible = alpha > 0
    if not np.any(visible):
        return img_rgba

    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc

    # Compute hue
    hue = np.zeros_like(maxc)
    mask_nonzero = diff > 0.001
    mask_r = (maxc == r) & mask_nonzero
    mask_g = (maxc == g) & mask_nonzero & ~mask_r
    mask_b = (maxc == b) & mask_nonzero & ~mask_r & ~mask_g

    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / diff[mask_r]) % 6)
    hue[mask_g] = 60.0 * (((b[mask_g] - r[mask_g]) / diff[mask_g]) + 2)
    hue[mask_b] = 60.0 * (((r[mask_b] - g[mask_b]) / diff[mask_b]) + 4)

    # Saturation
    sat = np.where(maxc > 0.001, diff / maxc, 0.0)

    # Find magenta pixels: hue 270-360° or 0-10° (wraps around red), sat > 0.15
    # Lower threshold (0.15 vs 0.20) to catch more of the BG bleed tones
    is_magenta = visible & (
        ((hue >= 270) & (hue <= 360)) | (hue < 10)
    ) & (sat > 0.15)

    magenta_count = np.sum(is_magenta)
    if magenta_count == 0:
        print(f"      Magenta cleanup: no magenta pixels found")
        return img_rgba

    visible_count = np.sum(visible)
    magenta_pct = 100 * magenta_count / visible_count
    print(f"      Magenta cleanup: {magenta_count} pixels ({magenta_pct:.1f}% of creature)")

    # Compute distance from transparency boundary for edge-aware strength
    # Distance transform: each opaque pixel gets its distance to nearest transparent pixel
    dist_from_edge = distance_transform_edt(visible)
    edge_zone = 30  # pixels at 1024x1024 scale

    # Desaturation strength: 95% at edges, 80% in interior
    # Smooth blend between zones
    edge_blend = np.clip(dist_from_edge / edge_zone, 0, 1)  # 0=at edge, 1=deep interior
    desat_strength = 0.95 - (edge_blend * 0.15)  # 0.95 at edge → 0.80 deep inside

    # Compute fully desaturated version
    gray = np.mean(rgb, axis=2, keepdims=True)
    gray_broadcast = np.broadcast_to(gray, rgb.shape)

    # Apply variable desaturation to magenta pixels
    result_rgb = rgb.copy()
    for c in range(3):
        channel = result_rgb[:, :, c]
        gray_c = gray_broadcast[:, :, c]
        # Blend: result = original * (1 - strength) + gray * strength
        channel[is_magenta] = (
            channel[is_magenta] * (1 - desat_strength[is_magenta]) +
            gray_c[is_magenta] * desat_strength[is_magenta]
        )

    edge_magenta = np.sum(is_magenta & (dist_from_edge < edge_zone))
    interior_magenta = np.sum(is_magenta & (dist_from_edge >= edge_zone))
    print(f"      Edge magenta (95% desat): {edge_magenta}, Interior (80% desat): {interior_magenta}")

    result = np.zeros_like(arr)
    result[:, :, :3] = np.clip(result_rgb * 255, 0, 255)
    result[:, :, 3] = alpha
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def cleanup_green_bleed(img_rgba):
    """Edge-aware green desaturation for sprites generated on green BG.

    Same approach as magenta cleanup but targets green hue range (80-160°).
    Only desaturates BRIGHT saturated greens (BG bleed), not dark muted greens
    (legitimate creature colors like orc skin).

    Edge zone gets 95% desaturation, interior gets 70% (lower than magenta
    since some creatures legitimately have green tones).
    """
    from scipy.ndimage import distance_transform_edt

    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]

    visible = alpha > 0
    if not np.any(visible):
        return img_rgba

    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc

    hue = np.zeros_like(maxc)
    mask_nonzero = diff > 0.001
    mask_r = (maxc == r) & mask_nonzero
    mask_g = (maxc == g) & mask_nonzero & ~mask_r
    mask_b = (maxc == b) & mask_nonzero & ~mask_r & ~mask_g

    hue[mask_r] = 60.0 * (((g[mask_r] - b[mask_r]) / diff[mask_r]) % 6)
    hue[mask_g] = 60.0 * (((b[mask_g] - r[mask_g]) / diff[mask_g]) + 2)
    hue[mask_b] = 60.0 * (((r[mask_b] - g[mask_b]) / diff[mask_b]) + 4)

    sat = np.where(maxc > 0.001, diff / maxc, 0.0)

    # Bright saturated green: hue 80-160°, saturation > 0.25, brightness > 0.20
    # Higher sat threshold than magenta to avoid hitting dark muted greens
    is_green_bleed = visible & (
        (hue >= 80) & (hue <= 160)
    ) & (sat > 0.25) & (maxc > 0.20)

    green_count = np.sum(is_green_bleed)
    if green_count == 0:
        print(f"      Green cleanup: no green bleed found")
        return img_rgba

    visible_count = np.sum(visible)
    green_pct = 100 * green_count / visible_count
    print(f"      Green cleanup: {green_count} pixels ({green_pct:.1f}% of creature)")

    dist_from_edge = distance_transform_edt(visible)
    edge_zone = 30

    edge_blend = np.clip(dist_from_edge / edge_zone, 0, 1)
    # 95% at edges, 70% interior (less aggressive than magenta — preserve legitimate greens)
    desat_strength = 0.95 - (edge_blend * 0.25)

    gray = np.mean(rgb, axis=2, keepdims=True)
    gray_broadcast = np.broadcast_to(gray, rgb.shape)

    result_rgb = rgb.copy()
    for c in range(3):
        channel = result_rgb[:, :, c]
        gray_c = gray_broadcast[:, :, c]
        channel[is_green_bleed] = (
            channel[is_green_bleed] * (1 - desat_strength[is_green_bleed]) +
            gray_c[is_green_bleed] * desat_strength[is_green_bleed]
        )

    edge_green = np.sum(is_green_bleed & (dist_from_edge < edge_zone))
    interior_green = np.sum(is_green_bleed & (dist_from_edge >= edge_zone))
    print(f"      Edge green (95% desat): {edge_green}, Interior (70% desat): {interior_green}")

    result = np.zeros_like(arr)
    result[:, :, :3] = np.clip(result_rgb * 255, 0, 255)
    result[:, :, 3] = alpha
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def auto_crop_and_resize(img_rgba, target_size=TILE_SIZE, padding=4):
    """Crop to content bounding box, pad to square, resize to target."""
    arr = np.array(img_rgba)
    alpha = arr[:, :, 3]

    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)

    if not np.any(rows) or not np.any(cols):
        return Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]

    rmin = max(0, rmin - padding)
    rmax = min(arr.shape[0] - 1, rmax + padding)
    cmin = max(0, cmin - padding)
    cmax = min(arr.shape[1] - 1, cmax + padding)

    cropped = img_rgba.crop((cmin, rmin, cmax + 1, rmax + 1))

    cw, ch = cropped.size
    side = max(cw, ch)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    offset_x = (side - cw) // 2
    offset_y = (side - ch) // 2
    square.paste(cropped, (offset_x, offset_y), cropped)

    resized = square.resize((target_size, target_size), Image.Resampling.NEAREST)
    return resized


def generate_dark_variant(img_rgba):
    """Generate dark/unlit variant: 60% desaturate, 40% darken, cool blue tint."""
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]

    mask = alpha > 0
    if not np.any(mask):
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
# Main Processing Pipeline
# ============================================================================

# Monsters that MUST use raw files (corrected version destroys features)
FORCE_RAW = set()  # None currently — corrected files work better with rembg

# Per-monster rembg alpha threshold (default 127).
# Lower = keep more of rembg's soft-alpha regions (faded wings, translucent parts)
ALPHA_THRESHOLD = {
    16: 10,   # Giant Bat — wings live in soft alpha range
}

# Per-monster fragment keep threshold (default 0.02 = 2% of largest component).
# Lower = keep smaller fragments (thin limbs that get detached by morphological ops)
FRAGMENT_THRESHOLD = {
    35: 0.0,    # Orc Thrallmaster — keep ALL fragments (chain flail is tiny separate component)
    40: 0.0,    # Orc Warchief — keep ALL fragments (lower torso/legs detach)
    53: 0.0,    # Mirk-troll — regen on green BG, keep all fragments
    104: 0.0,   # Morgul Sorcerer — keep staff fragment (detached from body by rembg)
    113: 0.0,   # Vampire — keep wing fragments (8 components, wings detached)
    117: 0.0,   # Maia Thrall — keep fire fragments (5 components, fire mane detached)
    118: 0.0,   # Khamul — keep sword/arm fragments (detached from body by rembg)
    132: 0.0,   # Greater Shadow — keep shadow tendrils (12 components)
    133: 0.0,   # Void Wraith — keep spectral fragments (20 components)
    135: 0.0,   # Sauron — keep all dark fire/shadow fragments
    302: 0.0,   # Thranduil — green armor fragments on green BG (14 components)
    307: 0.0,   # Radagast — brown robes fragment on green BG (6 components)
    308: 0.0,   # Eagle — feather fragments on green BG (6 components)
    301: 0.0,   # Gandalf — keep staff/hat fragments on magenta BG
    304: 0.0,   # Elrond — keep robe/circlet fragments on magenta BG
    310: 0.0,   # Ent — tree fragments on magenta BG
}

# Skip all BG cleanup for these monsters
SKIP_BG_CLEANUP = {
    16,  # Giant Bat — body IS magenta/purple, cleanup destroys it
    32,  # Orc Soldier — magenta cleanup eats sword blade, use gentle postprocess instead
}

# Monsters regenerated on GREEN BG — need green cleanup instead of magenta
GREEN_BG_MONSTERS = {
    12,  # Giant Rat (regen v2)
    13,  # Black Squirrel (regen v2)
    17,  # Web Spinner (regen v2)
    33,  # Orc Crossbowman (regen v3 — both legs visible)
    34,  # Warg (regen v3 — dark fur, no pink underside)
    20,  # Great Spider (regen v2)
    31,  # Orc Slave (regen v2)
    35,  # Orc Thrallmaster (regen v2 — green BG, bright whip)
    37,  # Warg Rider (regen v2 — green BG)
    39,  # Gashnak (regen v2 — green BG, red accents)
    40,  # Orc Warchief (regen v2 — green BG)
    53,  # Mirk-troll (regen v3 — green BG, massive dark troll)
    60,  # Master Sorcerer (regen v3 — green BG, purple magic)
    85,  # Tunnel Crawler (regen v3 — green BG, yellow/amber accents)
    54,  # Easterling Warrior (regen v3 — green BG, bronze armor + scimitar)
    57,  # Easterling Champion (regen v3 — green BG, gold plate + greatsword)
    58,  # Ghast (regen v3 — green BG, gray-white undead)
    71,  # Skeleton (regen v3 — green BG, ivory bones)
    73,  # Zombie (regen v3 — green BG, gray-blue decaying corpse)
    52,  # Ghoul (regen v4 — green BG, pale gray-blue undead)
    59,  # Karvag the Torturer (regen v4 — green BG, reddish-brown troll)
    55,  # Dark Sorcerer (regen v5 — green BG, purple robes + shadow magic)
    56,  # Tortured Wretch (regen v5 — green BG, gaunt mad prisoner)
    # Tier 4 — full fresh generation on green BG
    72,  # Skeleton Warrior
    74,  # Wight
    75,  # Corpse-candle
    76,  # Necromancer Adept
    77,  # Barrow-wight
    78,  # Bone Golem
    79,  # Grishnakh Crypt Lord
    81,  # Cave Troll
    82,  # Dark Ritualist
    83,  # Corsair of Umbar
    84,  # Dunlending Berserker
    86,  # Pale Crawler
    91,  # Phantom
    100, # Black Numenorean Acolyte
    # Tier 5 — fresh generation on green BG
    92,  # Shadow
    93,  # Whispering Shade
    94,  # Wraith
    95,  # Fell Spirit
    96,  # Spectre
    97,  # Vampire Thrall
    98,  # The Wailing Horror
    99,  # Uvatha the Horseman
    101, # Haradrim Assassin
    102, # Cave Worm
    103, # Oathbreaker Captain
    104, # Morgul Sorcerer
    111, # Black Numenorean
    # Tier 6 — fresh generation on green BG
    112, # Olog-hai
    113, # Vampire
    114, # Greater Wraith
    115, # Vampire Lord
    116, # Shadow Lord
    117, # Maia Thrall
    118, # Khamul
    131, # Elite Olog-hai
    136, # Black Numenorean Lord
    # Tier 7 — deep combat + boss monsters, fresh generation on green BG
    80,  # Easterling Infiltrator
    87,  # Werewolf
    132, # Greater Shadow
    133, # Void Wraith
    134, # Thrain's Shade
    # 135 — Sauron uses MAGENTA BG (green BG bleeds into dark armor accents)
    137, # Mouth of Sauron
    # Tier 8 — only Radagast on green BG (brown robes work fine)
    307, # Radagast the Brown
    # 301-306, 308-310 use MAGENTA BG (green BG contaminates skin/natural colors)
}

# Monsters that need color-merge recovery (rembg strips thin features like
# sword blades, whip chains, weapon glow). After rembg runs, we merge in
# non-BG pixels from the raw source to recover these features.
# Works best on GREEN_BG_MONSTERS where the BG color is easy to distinguish.
COLOR_MERGE_MONSTERS = {
    54,  # Easterling Warrior — scimitar blade stripped by rembg
    55,  # Dark Sorcerer — purple robes stripped by rembg (dark on green BG)
    72,  # Skeleton Warrior — blue fire hand stripped by rembg
    74,  # Wight — pale white aura hand stripped by rembg
    76,  # Necromancer Adept — blue light + magic hand stripped by rembg
    100, # Black Numenorean Acolyte — red blood magic hand stripped by rembg
    304, # Elrond — 22% rembg, blue robes on magenta BG needs color recovery
    310, # Ent — 6.6% rembg, bark body on magenta BG needs full color recovery
}

# Monsters that need hard BG remnant removal (bright BG pixels → transparent)
HARD_BG_REMOVAL = {
    17,  # Web Spinner — green between legs
    19,  # Swamp Adder — pink patch under jaw
}

def find_source(monster_id, prefer_corrected=True):
    """Find the source 1024x1024 file for a monster."""
    if monster_id in FORCE_RAW:
        prefer_corrected = False

    if prefer_corrected:
        corrected = CORRECTED_DIR / f"monster_{monster_id}_corrected.png"
        if corrected.exists():
            return corrected

    raw = RAW_DIR / f"monster_{monster_id}_1024.png"
    if raw.exists():
        return raw

    return None


def process_monster(monster_id, tier_num, prefer_corrected=True):
    """Full pipeline: rembg BG removal → magenta cleanup → crop → resize → dark."""
    name = MONSTER_COLORS.get(monster_id, {}).get("name", f"Monster {monster_id}")

    src = find_source(monster_id, prefer_corrected)
    if src is None:
        print(f"  [{monster_id}] {name}: NO SOURCE FILE FOUND")
        return False

    print(f"  [{monster_id}] {name} (from {src.name})")

    img = Image.open(src).convert("RGBA")

    # Step 1: ML-based BG removal
    rgba = remove_background_ml(img, monster_id)

    # Step 1b: Color-merge recovery (recover thin features rembg missed)
    if monster_id in COLOR_MERGE_MONSTERS:
        rgba = color_merge_recovery(rgba, img, monster_id)

    # Step 2a: Hard BG remnant removal (bright BG pixels → transparent)
    if monster_id in HARD_BG_REMOVAL:
        bg_type = "green" if monster_id in GREEN_BG_MONSTERS else "magenta"
        rgba = remove_bg_remnants(rgba, bg_type)

    # Step 2b: Soft BG bleed desaturation on creature body
    if monster_id in SKIP_BG_CLEANUP:
        print(f"      BG cleanup: SKIPPED (per-monster override)")
    elif monster_id in GREEN_BG_MONSTERS:
        rgba = cleanup_green_bleed(rgba)
    else:
        rgba = cleanup_magenta_bleed(rgba)

    # Step 3: Crop and resize to 64x64
    light = auto_crop_and_resize(rgba)

    # Step 4: Dark variant
    dark = generate_dark_variant(light)

    # Save
    tier_out = OUTPUT_DIR / f"tier_{tier_num}"
    tier_out.mkdir(parents=True, exist_ok=True)

    light.save(tier_out / f"monster_{monster_id}_light.png")
    dark.save(tier_out / f"monster_{monster_id}_dark.png")

    # Report opacity
    light_arr = np.array(light)
    opaque_pct = 100 * np.sum(light_arr[:, :, 3] > 0) / (TILE_SIZE * TILE_SIZE)
    print(f"      Final: {opaque_pct:.1f}% opaque at 64x64")

    return True


def build_montage(tier_num, ids, scale=4):
    """Build a tier montage at scale x zoom for visual review."""
    tier_dir = OUTPUT_DIR / f"tier_{tier_num}"
    if not tier_dir.exists():
        print(f"  No output for tier {tier_num}")
        return

    sprites = []
    for mid in ids:
        light_path = tier_dir / f"monster_{mid}_light.png"
        if light_path.exists():
            sprites.append(Image.open(light_path))
        else:
            sprites.append(Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0)))

    cols_per_row = min(len(sprites), 8)
    rows = (len(sprites) + cols_per_row - 1) // cols_per_row
    tile_scaled = TILE_SIZE * scale

    montage = Image.new("RGBA",
                        (cols_per_row * tile_scaled, rows * tile_scaled),
                        (32, 32, 32, 255))

    for i, sprite in enumerate(sprites):
        col = i % cols_per_row
        row = i // cols_per_row
        big = sprite.resize((tile_scaled, tile_scaled), Image.Resampling.NEAREST)
        montage.paste(big, (col * tile_scaled, row * tile_scaled), big)

    montage_path = OUTPUT_DIR / f"T{tier_num}_montage.png"
    montage.save(montage_path)
    print(f"\n  Montage saved: {montage_path}")
    return montage_path


# ============================================================================
# Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Monster Sprite Processor v3")
    parser.add_argument("--tier", type=int, help="Process a specific tier (1-8)")
    parser.add_argument("--ids", type=int, nargs="+", help="Process specific monster IDs")
    parser.add_argument("--from-raw", action="store_true",
                        help="Use raw files (skip color correction)")
    parser.add_argument("--montage-only", action="store_true",
                        help="Only build montage from existing output")
    args = parser.parse_args()

    prefer_corrected = not args.from_raw

    if args.ids:
        ids = args.ids
        tier_num = 0
        for t, t_ids in TIER_IDS.items():
            if ids[0] in t_ids:
                tier_num = t
                break
    elif args.tier:
        tier_num = args.tier
        ids = TIER_IDS.get(tier_num, [])
    else:
        print("Specify --tier N or --ids ID1 ID2 ...")
        sys.exit(1)

    if not ids:
        print(f"No monsters found for tier {tier_num}")
        sys.exit(1)

    if args.montage_only:
        build_montage(tier_num, ids)
        return

    print(f"\n{'='*60}")
    print(f"Monster Sprite Processor v3 — Tier {tier_num}")
    print(f"Processing {len(ids)} monsters: {ids}")
    print(f"Source: {'raw' if args.from_raw else 'corrected (fallback raw)'}")
    print(f"Method: rembg (U2NET ML segmentation)")
    print(f"Output: {OUTPUT_DIR / f'tier_{tier_num}'}")
    print(f"{'='*60}\n")

    success = 0
    failed = 0
    for mid in ids:
        ok = process_monster(mid, tier_num, prefer_corrected)
        if ok:
            success += 1
        else:
            failed += 1
        print()

    print(f"{'='*60}")
    print(f"Done: {success} processed, {failed} failed")

    montage_path = build_montage(tier_num, ids)

    if montage_path:
        print(f"\nReview montage: {montage_path}")
    print()


if __name__ == "__main__":
    main()
