#!/usr/bin/env python3
"""
Item Sprite Processor v3 — ML-Based BG Removal Pipeline

Adapted from process_monsters_v3.py for item sprites. Uses rembg (U2NET) for
shape-based background removal with item-specific tuning:
  - Same color-merge thresholds as monsters (0.20) — 0.15 grabbed BG gradients
  - Wider proximity radius (50px vs 30px) for blade tips far from body
  - Slightly tighter edge zone (25px vs 30px) for compact item shapes
  - Interior desaturation 75% (vs 80% for monsters) — preserve item color variety

Pipeline:
  1. rembg removes background using ML segmentation (shape, not color)
  2. Color-merge recovery: OR-merge rembg mask with color-extracted non-BG pixels
  3. Hard BG remnant removal: bright saturated BG pixels -> transparent
  4. Soft BG bleed desaturation: edge-aware HSV cleanup
  5. Auto-crop + NEAREST resize to 64x64
  6. Dark variant generation: 60% desat, 40% darken, blue tint

Usage:
    python3 process_items_v3.py --category sword       # Process one category
    python3 process_items_v3.py --ids 56 64 68         # Process specific items
    python3 process_items_v3.py --all                   # Process everything
    python3 process_items_v3.py --montage sword         # Generate 4x review montage
"""

import argparse
import json
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
OUTPUT_DIR = BASE_DIR / "item_v3"
RAW_DIR = OUTPUT_DIR / "raw"
PROGRESS_PATH = BASE_DIR / "item_v3_progress.json"
TILE_SIZE = 64

# Category names (tval -> category string)
CATEGORY_NAMES = {
    23: "sword",
    22: "polearm",
    21: "hafted",
    20: "digging",
    19: "bow",
    18: "sling",
    17: "arrow",
    16: "sling_stone",
    37: "body_armor",
    36: "soft_armor",
    32: "helm",
    33: "crown",
    34: "shield",
    35: "cloak",
    30: "boots",
    31: "gloves",
    45: "ring",
    40: "amulet",
    75: "potion",
    80: "herb",
    55: "scroll",
    56: "wand",
    66: "horn",
    77: "oil",
    39: "light",
    7: "chest",
    3: "skeleton",
    4: "special_material",
    2: "document",
}

# ============================================================================
# ITEM-SPECIFIC OVERRIDE DICTIONARIES
# ============================================================================

# Items generated on MAGENTA BG (green-colored items that would blend into green BG)
MAGENTA_BG_ITEMS = {
    383, 387, 389, 390, 404, 412, 413, 416,  # green herbs
    321, 344,   # green potions
    135, 162, 171,  # green jewelry
    74,         # green weapons (Morgul Glaive)
    204,        # green scroll
    23,         # green-brown armor
    110,        # Silvan Bow — brown wood invisible on green BG
    71,         # Hunting Spear — brown shaft on green BG
    86,         # Oak Staff — brown wood on green BG
    20,         # Iron Crown — dark iron picks up green ambient light
    104,        # Golden Crown — gold picks up green ambient light
    43,         # Buckler — dark wood/iron on magenta BG
    44,         # Tower Shield — iron-banded oak, cold moonlight
    46,         # Mithril Shield — silver, pale blue starlight
    422,        # Shattered Shield — splintered wood/iron on magenta BG
    225,  # Wand of Sleep — kept from magenta gen
    451, 540, 530, 552, 543, 556, 554, 410,  # Documents + mithril ore regens
    152, 158, 161, 162, 171,                   # Ring fix regens (magenta BG)
    173, 174, 175, 176, 177, 178,             # Ring hard regens (magenta BG)
    2,                                            # Plain Ring — pale gold on magenta BG
    3, 5, 6, 140, 142, 143, 144, 145,            # Amulet regens (magenta BG)
    494,                                          # Twisted Shadow-plate (magenta BG)
    179, 180,                                   # Ring hard regens (magenta BG)
    # 181 Wrathful Fire now on green BG
}

# tvals where ALL items get color-merge recovery (truly thin items only).
# Weapons (swords, polearms, etc.) are NOT included by default because color merge
# grabs green BG texture around the blade. Add specific weapon IDs to COLOR_MERGE_ITEMS
# only if rembg strips the blade entirely (< 5% opaque).
COLOR_MERGE_TVALS = {17}  # arrows (thin shafts). Wands removed — thematic lighting makes color merge too aggressive

# Individual items for color merge (add weapon/jewelry IDs as needed during review)
# Added during Phase 2 review — items with <10% rembg opacity that need recovery
COLOR_MERGE_ITEMS = {
    # 494 removed — regen on magenta BG, rembg alone sufficient now
    176,   # Iron Will ring (6.9% -> 14.5%)
    177,   # the Greenwood ring (6.9% -> 19.0%)
}

# tvals with fragment threshold = 0 (keep all fragments)
FRAG_ZERO_TVALS = {17, 3, 39, 55}  # arrows, skeletons, lights, scrolls

# tvals needing hard BG remnant removal (BG between thin parts)
HARD_BG_TVALS = {17, 3, 45}  # arrows, skeletons, rings (green BG in ring interior)
HARD_BG_ITEMS = {
    58,    # Curved Sword — rembg keeps green BG mass around wide blade
}

# Items where green cleanup should make green pixels TRANSPARENT instead of just desaturating.
# Use for items where rembg includes large areas of green BG as part of the object
# (e.g. curved blades where the interior of the curve is all green).
GREEN_TO_TRANSPARENT_ITEMS = {
    58,    # Curved Sword — scimitar curve encloses green BG
    154,   # Ring of Strength — green BG inside band loop
    155,   # Ring of Dexterity — green/yellow gradient inside band loop
}

# Per-item alpha threshold (default 127)
# Lower = keep more of rembg's soft-alpha regions (glow, translucent parts)
ALPHA_THRESHOLD = {
    21: 30,    # Elven light crystal (soft glow)
    130: 30,   # Jewel-lamp (magical light)
    131: 30,   # Star-glass (brilliant starlight)
}

# Per-item fragment threshold overrides (default 0.02)
# Set to 0.0 to keep ALL fragments
FRAGMENT_THRESHOLD = {}

# Per-item skip BG cleanup
SKIP_BG_CLEANUP = set()

# Items needing thin-artifact removal (decorative flourishes, ghost lines from DALL-E).
# Maps item_id -> min_thickness in pixels at 1024x1024 scale.
# Features thinner than this are removed via erosion-dilation.
THIN_ARTIFACT_REMOVAL = {
    58: 35,  # Curved Sword — DALL-E added decorative flourish arc behind scimitar
}


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def remove_thin_artifacts(img_rgba, min_thickness=35):
    """Remove thin decorative artifacts (flourishes, ghost lines) from post-rembg RGBA.

    Works at 1024x1024 scale. Uses erosion-dilation: erode to kill features thinner
    than min_thickness, then dilate back and intersect with original mask to recover
    exact edges of thick features.

    For item 58 (Curved Sword): main blade ~60-120px wide, flourish arc ~10-20px.
    min_thickness=35 cleanly separates them.
    """
    from scipy.ndimage import binary_erosion, binary_dilation

    arr = np.array(img_rgba).copy()
    alpha = arr[:, :, 3]
    fg_mask = alpha > 127

    erosion_radius = min_thickness // 2
    struct = np.ones((3, 3), dtype=bool)

    # Erode: thin features vanish entirely
    eroded = binary_erosion(fg_mask, structure=struct, iterations=erosion_radius)

    # Dilate back: thick features recover approximate shape
    recovered = binary_dilation(eroded, structure=struct, iterations=erosion_radius)

    # Dilate a bit more to create influence zone, then intersect with original
    # to get exact original pixel edges of thick features
    influence = binary_dilation(recovered, structure=struct, iterations=5)
    cleaned = fg_mask & influence

    removed = int(np.sum(fg_mask)) - int(np.sum(cleaned))
    total_fg = max(1, int(np.sum(fg_mask)))
    print(f"      Thin artifact removal: {removed} pixels removed "
          f"({100 * removed / total_fg:.1f}% of foreground, min_thickness={min_thickness})")

    arr[:, :, 3] = np.where(cleaned, alpha, 0).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def should_color_merge(item_id, tval):
    """Check if item needs color-merge recovery for thin features."""
    return tval in COLOR_MERGE_TVALS or item_id in COLOR_MERGE_ITEMS


def should_hard_bg_removal(item_id, tval):
    """Check if item needs hard BG remnant removal."""
    return tval in HARD_BG_TVALS or item_id in HARD_BG_ITEMS


def get_frag_threshold(item_id, tval):
    """Get fragment threshold for item. Per-item overrides > tval rules > default."""
    if item_id in FRAGMENT_THRESHOLD:
        return FRAGMENT_THRESHOLD[item_id]
    if tval in FRAG_ZERO_TVALS:
        return 0.0
    return 0.02


def get_alpha_threshold(item_id):
    """Get rembg alpha threshold for item."""
    return ALPHA_THRESHOLD.get(item_id, 127)


def find_source(item_id):
    """Find the source 1024x1024 file for an item."""
    path = RAW_DIR / f"item_{item_id}_1024.png"
    return path if path.exists() else None


def load_progress():
    """Load item progress file for category/tval info."""
    if not PROGRESS_PATH.exists():
        return {}
    with open(PROGRESS_PATH) as f:
        return json.load(f)


def get_item_info(progress_data):
    """Extract item_id -> {tval, category} mapping from progress data."""
    items = {}
    sprites = progress_data.get("sprites", {})
    for key, entry in sprites.items():
        item_id = entry.get("item_id")
        tval = entry.get("tval")
        category = entry.get("category", CATEGORY_NAMES.get(tval, "unknown"))
        if item_id is not None and tval is not None:
            items[item_id] = {"tval": tval, "category": category}
    return items


# ============================================================================
# CORE: rembg ML Background Removal + Morphological Cleanup
# ============================================================================

def remove_background_ml(img_1024, item_id=None):
    """Remove background using rembg (U2NET ML segmentation).

    rembg detects the foreground object by shape, not color -- this solves
    the fundamental problem of colored items on matching-color backgrounds.

    After rembg, we apply morphological cleanup to:
    - Fill small interior holes
    - Remove tiny fragments
    - Close small gaps in the mask
    """
    result = rembg_remove(img_1024)

    arr = np.array(result)
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    # Per-item alpha threshold (lower = keep more of soft-alpha regions)
    alpha_thresh = get_alpha_threshold(item_id)
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

    # Remove small fragments -- keep components > threshold% of largest
    frag_thresh = get_frag_threshold(item_id, None)
    # If we have tval info from the caller, that will be used via process_item;
    # here we use the per-item override or default
    if item_id in FRAGMENT_THRESHOLD:
        frag_thresh = FRAGMENT_THRESHOLD[item_id]
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


def remove_background_ml_with_tval(img_1024, item_id, tval):
    """Remove background using rembg, with tval-aware fragment threshold."""
    result = rembg_remove(img_1024)

    arr = np.array(result)
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    alpha_thresh = get_alpha_threshold(item_id)
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

    # Remove small fragments
    frag_thresh = get_frag_threshold(item_id, tval)
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

    clean_alpha = (creature_final * 255).astype(np.uint8)
    arr[:, :, 3] = clean_alpha

    opaque_after = np.sum(creature_final)
    print(f"      After cleanup: {100 * opaque_after / (h * w):.1f}% opaque")

    return Image.fromarray(arr, "RGBA")


# ============================================================================
# Color-Merge Recovery: Recover thin features rembg misses
# ============================================================================

def color_merge_recovery(img_rembg, img_raw, item_id):
    """Merge color-extracted non-BG pixels from raw into rembg result.

    rembg classifies thin features (sword blades, arrow shafts, chain links,
    wand tips) as background because it detects by shape/contour, not color.
    This function:
    1. Takes the rembg result (item body detected)
    2. Color-extracts non-BG pixels from the raw image (the thin feature)
    3. Merges the two masks with OR
    4. Applies morphological closing to seal gaps

    Item-specific tuning vs monsters:
    - Lower color thresholds (0.15 vs 0.20) for thin metal glints
    - Wider proximity radius (50px vs 30px) for blade tips far from body
    """
    rembg_arr = np.array(img_rembg).copy()
    raw_arr = np.array(img_raw).astype(np.float64) / 255.0
    h, w = raw_arr.shape[:2]

    r, g, b = raw_arr[:, :, 0], raw_arr[:, :, 1], raw_arr[:, :, 2]
    rembg_alpha = rembg_arr[:, :, 3] > 127

    is_green_bg = item_id not in MAGENTA_BG_ITEMS

    if is_green_bg:
        # Green BG: detect pixels with significant non-green content.
        # Same threshold as monster pipeline — 0.15 was too aggressive, grabbed BG gradients.
        has_red = (r > 0.20) & (r > g * 0.7)
        has_blue = (b > 0.20) & (b > g * 0.7)
        # Also catch dark content (dark metal, shadows) that isn't green-tinted
        brightness = (r + g + b) / 3
        is_dark_content = (brightness > 0.03) & (brightness < 0.18) & (g < r * 1.5) & (g < b * 1.5)
        creature_color = has_red | has_blue | is_dark_content
    else:
        # Magenta BG: anything not magenta with meaningful content
        is_mag = (r > 0.55) & (g < 0.30) & (b > 0.35)
        has_green = (g > 0.15) & (g > r * 0.7) & (g > b * 0.7)
        brightness = (r + g + b) / 3
        is_dark_content = (brightness > 0.03) & (brightness < 0.18) & ~is_mag
        creature_color = (has_green | is_dark_content) & ~is_mag

    # Merge: rembg body + color-extracted features
    combined = rembg_alpha | creature_color

    # Close small gaps but don't fill large holes (would fill BG pockets)
    combined = binary_closing(combined, iterations=2)

    # Fragment removal -- keep components that are either:
    # (a) large (> threshold% of largest), OR
    # (b) near the rembg body (within 50px) -- wider than monsters (30px)
    #     because blade tips can be far from the item body
    rembg_dilated = binary_dilation(rembg_alpha, iterations=50)
    labeled, n_features = scipy_label(combined)
    if n_features > 1:
        sizes = np.bincount(labeled.ravel())[1:]
        max_size = sizes.max()
        frag_thresh = FRAGMENT_THRESHOLD.get(item_id, 0.02)
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
    especially between thin parts (arrow fletching, skeleton ribs).
    This pass makes very bright, saturated BG-colored pixels transparent.

    Unlike the soft desaturation passes, this is a hard removal -- pixels
    are either kept or made transparent.

    bg_type: "magenta" (hue 280-360/0-20) or "green" (hue 80-160)
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
    print(f"      BG remnant removal ({bg_type}): {bg_count} pixels ({bg_pct:.1f}%) -> transparent")

    arr[:, :, 3][is_bg] = 0
    return Image.fromarray(arr, "RGBA")


# ============================================================================
# Post-processing: Soft BG Bleed Desaturation, Crop, Resize, Dark Variant
# ============================================================================

def cleanup_magenta_bleed(img_rgba):
    """Edge-aware magenta desaturation on item body.

    DALL-E's magenta BG bleeds into item edges. After BG removal, we
    aggressively desaturate remaining magenta, with extra strength near
    the transparency boundary.

    Item-specific tuning vs monsters:
    - Edge zone: 20px (vs 30px) -- items are tighter shapes
    - Interior desaturation: 60% (vs 80%) -- items have more color variety

    Two zones:
    - EDGE (within 20px of transparency): 95% desaturation (nearly full)
    - INTERIOR (deep in body): 60% desaturation (preserve item colors)
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

    # Find magenta pixels: hue 270-360 or 0-10 (wraps around red), sat > 0.15
    is_magenta = visible & (
        ((hue >= 270) & (hue <= 360)) | (hue < 10)
    ) & (sat > 0.15)

    magenta_count = np.sum(is_magenta)
    if magenta_count == 0:
        print(f"      Magenta cleanup: no magenta pixels found")
        return img_rgba

    visible_count = np.sum(visible)
    magenta_pct = 100 * magenta_count / visible_count
    print(f"      Magenta cleanup: {magenta_count} pixels ({magenta_pct:.1f}% of item)")

    # Compute distance from transparency boundary for edge-aware strength
    dist_from_edge = distance_transform_edt(visible)
    edge_zone = 25  # pixels at 1024x1024 scale

    # Desaturation strength: 95% at edges, 75% in interior
    # Smooth blend between zones
    edge_blend = np.clip(dist_from_edge / edge_zone, 0, 1)  # 0=at edge, 1=deep interior
    desat_strength = 0.95 - (edge_blend * 0.20)  # 0.95 at edge -> 0.75 deep inside

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
    print(f"      Edge magenta (95% desat): {edge_magenta}, Interior (60% desat): {interior_magenta}")

    result = np.zeros_like(arr)
    result[:, :, :3] = np.clip(result_rgb * 255, 0, 255)
    result[:, :, 3] = alpha
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def cleanup_green_bleed(img_rgba, make_transparent=False):
    """Edge-aware green desaturation for items generated on green BG.

    If make_transparent=True, green pixels are made fully transparent instead of
    desaturated. Use for items where rembg includes large green BG areas as object.

    Same approach as magenta cleanup but targets green hue range (80-160).
    Only desaturates BRIGHT saturated greens (BG bleed), not dark muted greens
    (legitimate item colors like gem tints).

    Item-specific tuning vs monsters:
    - Edge zone: 20px (vs 30px) -- items are tighter shapes
    - Interior desaturation: 60% (vs 70%) -- items have more color variety
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

    # Bright saturated green: hue 80-160, saturation > 0.25, brightness > 0.20
    is_green_bleed = visible & (
        (hue >= 80) & (hue <= 160)
    ) & (sat > 0.25) & (maxc > 0.20)

    green_count = np.sum(is_green_bleed)
    if green_count == 0:
        print(f"      Green cleanup: no green bleed found")
        return img_rgba

    visible_count = np.sum(visible)
    green_pct = 100 * green_count / visible_count
    print(f"      Green cleanup: {green_count} pixels ({green_pct:.1f}% of item)")

    if make_transparent:
        # Aggressive mode: make all green pixels fully transparent
        # Primary pass: standard green bleed detection
        result = arr.copy()
        result[is_green_bleed, 3] = 0
        removed_primary = int(np.sum(is_green_bleed))
        print(f"      Green -> transparent: {removed_primary} pixels removed")
        return Image.fromarray(result.astype(np.uint8), "RGBA")

    dist_from_edge = distance_transform_edt(visible)
    edge_zone = 25  # slightly tighter than monsters' 30px

    edge_blend = np.clip(dist_from_edge / edge_zone, 0, 1)
    # 95% at edges, 75% interior
    desat_strength = 0.95 - (edge_blend * 0.20)

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
    print(f"      Edge green (95% desat): {edge_green}, Interior (60% desat): {interior_green}")

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

def process_item(item_id, tval, category):
    """Full pipeline: rembg -> color merge -> cleanup -> crop -> dark."""
    src = find_source(item_id)
    if not src:
        print(f"  [{item_id}] NO SOURCE FILE")
        return False

    print(f"  [{item_id}] category={category}, tval={tval} (from {src.name})")

    img = Image.open(src).convert("RGBA")

    # Step 1: ML-based BG removal (tval-aware fragment threshold)
    rgba = remove_background_ml_with_tval(img, item_id, tval)

    # Step 1a: Remove thin decorative artifacts (before closing connects them)
    if item_id in THIN_ARTIFACT_REMOVAL:
        min_thick = THIN_ARTIFACT_REMOVAL[item_id]
        rgba = remove_thin_artifacts(rgba, min_thickness=min_thick)

    # Step 1b: Color-merge recovery (recover thin features rembg missed)
    if should_color_merge(item_id, tval):
        rgba = color_merge_recovery(rgba, img, item_id)

    # Step 2a: Hard BG remnant removal (bright BG pixels -> transparent)
    if should_hard_bg_removal(item_id, tval):
        bg_type = "magenta" if item_id in MAGENTA_BG_ITEMS else "green"
        rgba = remove_bg_remnants(rgba, bg_type)

    # Step 2b: Soft BG bleed desaturation on item body
    if item_id in SKIP_BG_CLEANUP:
        print(f"      BG cleanup: SKIPPED (per-item override)")
    elif item_id in MAGENTA_BG_ITEMS:
        rgba = cleanup_magenta_bleed(rgba)
    else:
        aggressive = item_id in GREEN_TO_TRANSPARENT_ITEMS
        rgba = cleanup_green_bleed(rgba, make_transparent=aggressive)

    # Step 3: Crop and resize to 64x64
    light = auto_crop_and_resize(rgba)

    # Step 4: Dark variant
    dark = generate_dark_variant(light)

    # Save
    cat_dir = OUTPUT_DIR / category
    cat_dir.mkdir(parents=True, exist_ok=True)

    light.save(cat_dir / f"item_{item_id}_light.png")
    dark.save(cat_dir / f"item_{item_id}_dark.png")

    # Report opacity
    light_arr = np.array(light)
    opaque_pct = 100 * np.sum(light_arr[:, :, 3] > 0) / (TILE_SIZE * TILE_SIZE)
    print(f"      Final: {opaque_pct:.1f}% opaque at 64x64")

    return True


# ============================================================================
# Montage Generation
# ============================================================================

def build_montage(category, item_ids, scale=4):
    """Build a category montage at scale x zoom for visual review."""
    cat_dir = OUTPUT_DIR / category
    if not cat_dir.exists():
        print(f"  No output for category '{category}'")
        return None

    sprites = []
    labels = []
    for iid in item_ids:
        light_path = cat_dir / f"item_{iid}_light.png"
        if light_path.exists():
            sprites.append(Image.open(light_path))
            labels.append(iid)
        else:
            sprites.append(Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0)))
            labels.append(iid)

    if not sprites:
        print(f"  No sprites found for category '{category}'")
        return None

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

    montage_dir = OUTPUT_DIR / "montages"
    montage_dir.mkdir(parents=True, exist_ok=True)
    montage_path = montage_dir / f"{category}_montage.png"
    montage.save(montage_path)
    print(f"\n  Montage saved: {montage_path}")
    return montage_path


# ============================================================================
# Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Item Sprite Processor v3")
    parser.add_argument("--category", type=str,
                        help="Process all items in a category (e.g. sword, helm, potion)")
    parser.add_argument("--ids", type=int, nargs="+",
                        help="Process specific item IDs")
    parser.add_argument("--all", action="store_true",
                        help="Process all items with source files")
    parser.add_argument("--montage", type=str,
                        help="Generate montage for a category (from existing output)")
    args = parser.parse_args()

    # Load progress data for item metadata
    progress = load_progress()
    item_info = get_item_info(progress)

    if not item_info and not args.montage:
        print(f"WARNING: No item info loaded from {PROGRESS_PATH}")
        print("The progress file is needed to know each item's tval and category.")
        print("Falling back to raw directory scan...")
        # Scan raw directory for available items
        if RAW_DIR.exists():
            for f in sorted(RAW_DIR.glob("item_*_1024.png")):
                try:
                    iid = int(f.stem.split("_")[1])
                    if iid not in item_info:
                        item_info[iid] = {"tval": 0, "category": "unknown"}
                except (ValueError, IndexError):
                    pass
        if not item_info:
            print("No items found. Ensure raw files exist in item_v3/raw/")
            sys.exit(1)

    # Handle --montage (no processing, just build montage from existing output)
    if args.montage:
        category = args.montage
        # Find all item IDs for this category
        cat_ids = sorted([
            iid for iid, info in item_info.items()
            if info["category"] == category
        ])
        if not cat_ids:
            # Try to find from existing output files
            cat_dir = OUTPUT_DIR / category
            if cat_dir.exists():
                cat_ids = sorted([
                    int(f.stem.split("_")[1])
                    for f in cat_dir.glob("item_*_light.png")
                ])
        if not cat_ids:
            print(f"No items found for category '{category}'")
            sys.exit(1)
        build_montage(category, cat_ids)
        return

    # Determine which items to process
    if args.ids:
        process_ids = args.ids
    elif args.category:
        process_ids = sorted([
            iid for iid, info in item_info.items()
            if info["category"] == args.category
        ])
        if not process_ids:
            print(f"No items found for category '{args.category}'")
            print(f"Available categories: {sorted(set(info['category'] for info in item_info.values()))}")
            sys.exit(1)
    elif args.all:
        process_ids = sorted(item_info.keys())
    else:
        print("Specify --category NAME, --ids ID1 ID2 ..., --all, or --montage CATEGORY")
        sys.exit(1)

    if not process_ids:
        print("No items to process")
        sys.exit(1)

    # Determine categories being processed for summary
    categories_in_batch = set()
    for iid in process_ids:
        info = item_info.get(iid, {"tval": 0, "category": "unknown"})
        categories_in_batch.add(info["category"])

    print(f"\n{'='*60}")
    print(f"Item Sprite Processor v3")
    print(f"Processing {len(process_ids)} items: {process_ids[:20]}{'...' if len(process_ids) > 20 else ''}")
    print(f"Categories: {sorted(categories_in_batch)}")
    print(f"Method: rembg (U2NET ML segmentation)")
    print(f"Output: {OUTPUT_DIR}")
    print(f"{'='*60}\n")

    success = 0
    failed = 0
    processed_categories = {}  # category -> [item_ids]

    for iid in process_ids:
        info = item_info.get(iid, {"tval": 0, "category": "unknown"})
        tval = info["tval"]
        category = info["category"]

        ok = process_item(iid, tval, category)
        if ok:
            success += 1
            processed_categories.setdefault(category, []).append(iid)
        else:
            failed += 1
        print()

    print(f"{'='*60}")
    print(f"Done: {success} processed, {failed} failed")

    # Build montages for each processed category
    for category, ids in sorted(processed_categories.items()):
        build_montage(category, ids)

    print()


if __name__ == "__main__":
    main()
