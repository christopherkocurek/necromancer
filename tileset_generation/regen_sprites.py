#!/usr/bin/env python3
"""
Necromancer Sprite Regenerator
Generates 7 specific sprites via DALL-E 3, post-processes them, integrates into
the tileset PNG, and updates tile_mapper.gd coordinates.

Targets:
  B1. Curved Sword (Item ID 58) - NEW item sprite
  B2. Vine Floor Terrain (Level.Tile 17) - REGENERATE terrain
  B3. Web Terrain (Level.Tile 19) - NEW terrain
  B4. Stairs Down (Level.Tile 5) - REGENERATE terrain
  B5. Poison Stream - NEW terrain
  B6. Wanderer's Robe (Item ID 22) - REGENERATE item
  B7. HP/Voice Orb Watcher Frame - NEW UI artwork

Usage:
    python3 regen_sprites.py                # Run all 7 targets
    python3 regen_sprites.py --target B1    # Run single target
    python3 regen_sprites.py --dry-run      # Show plan without API calls
    python3 regen_sprites.py --skip-api     # Skip DALL-E, only do integration
"""

import os
import sys
import json
import time
import base64
import argparse
import math
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, Tuple
from collections import deque
import io

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter, ImageEnhance, ImageDraw
    import numpy as np
    from scipy.ndimage import distance_transform_edt, gaussian_filter
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install: pip3 install openai pillow python-dotenv numpy scipy")
    sys.exit(1)

# ============================================================================
# PATHS & CONSTANTS
# ============================================================================

BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
TILE_MAPPER_PATH = PROJECT_DIR / "scripts" / "core" / "tile_mapper.gd"
OUTPUT_DIR = BASE_DIR / "regen_v1"
ORB_OUTPUT_DIR = PROJECT_DIR / "assets" / "ui" / "orbs"

TILE_SIZE = 64
GRID_SIZE = 32
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048
COST_PER_IMAGE = 0.04
RATE_LIMIT_DELAY = 2.5
MAX_RETRIES = 3
WHITE_THRESHOLD = 240

# Magenta processing constants
MAGENTA_ZONE_MIN = 275
MAGENTA_ZONE_MAX = 335
MAGENTA_CENTER = 300
MAX_BLEED_DISTANCE = 60
GAUSSIAN_SIGMA = 5


# ============================================================================
# SPRITE TARGET DEFINITIONS
# ============================================================================

TARGETS = {
    "B1": {
        "name": "Curved Sword",
        "type": "item",
        "item_id": 58,
        "prompt": (
            "On a completely solid flat hot magenta background (hex FF00FF), "
            "a vivid fantasy illustration of a single curved scimitar-style sword "
            "with a bronze crossguard and leather-wrapped handle, lying diagonally "
            "across the frame, blade gleaming. "
            "Vivid striking colors: curved steel blade, bronze crossguard, dark leather grip. "
            "Strong readable silhouette against the magenta. "
            "The background must be entirely uniform solid magenta with absolutely nothing else. "
            "A single item only, no hands, no characters, no other elements. "
            "Painted in a clean illustrative style."
        ),
        "style": "vivid",
        "tileset_pos": (1, 17),  # Vector2i(1, 17)
        "post_process": "item_magenta",
        "magenta_params": {"hue_deg": 210, "achromatic": True, "bleed": 1},
    },
    "B2": {
        "name": "Vine Floor",
        "type": "terrain",
        "prompt": (
            "A flat overhead painting of dark stone dungeon floor covered with "
            "thick green creeping vines and roots growing through cracks between "
            "weathered flagstones, tangled vegetation spreading across ancient stone. "
            "Bird's eye view looking straight down. "
            "Dark fantasy style, gritty and worn. "
            "The stone surface fills the entire image completely, "
            "extending beyond all four edges. "
            "Painted in a retro low-resolution blocky style with chunky details. "
            "Very dark color palette: charcoal gray, near-black, dark green vines."
        ),
        "style": "natural",
        "tileset_light": (16, 18),
        "tileset_dark": (17, 18),
        "post_process": "terrain",
        "terrain_tile_id": 17,  # Level.Tile VINE_FLOOR
    },
    "B3": {
        "name": "Web Terrain",
        "type": "terrain",
        "prompt": (
            "A flat overhead painting of dense white spider webs stretched over "
            "dark stone dungeon floor, thick sticky cobwebs covering ancient flagstones, "
            "silky strands spanning across the surface. "
            "Bird's eye view looking straight down. "
            "Dark fantasy style, gritty and ancient. "
            "The stone surface fills the entire image completely, "
            "extending beyond all four edges. "
            "Painted in a retro low-resolution blocky style with chunky details. "
            "Very dark color palette: charcoal gray, near-black, white web strands."
        ),
        "style": "natural",
        "tileset_light": (0, 18),
        "tileset_dark": (1, 18),
        "post_process": "terrain",
        "terrain_tile_id": 19,  # Level.Tile WEB
    },
    "B4": {
        "name": "Stairs Down",
        "type": "terrain",
        "prompt": (
            "A painting of a dark dungeon stone floor with a stone stairway opening "
            "descending into darkness, carved stone steps going down into a dark pit, "
            "ancient worn steps in the center of the floor. "
            "Bird's eye view looking straight down from above. "
            "The dark stone floor fills the entire image edge to edge, "
            "with the stairway opening in the center of the floor. "
            "Dark fantasy style. "
            "Painted in a retro low-resolution blocky style. "
            "Very dark color palette: charcoal gray, near-black, dark brown."
        ),
        "style": "natural",
        "tileset_light": (18, 18),
        "tileset_dark": (19, 18),
        "post_process": "terrain",
        "terrain_tile_id": 5,  # Level.Tile STAIRS_DOWN
    },
    "B5": {
        "name": "Poison Stream",
        "type": "terrain",
        "prompt": (
            "A flat overhead painting of a sickly green glowing stream of poisonous "
            "liquid flowing across dark stone dungeon floor, toxic green water in a "
            "narrow channel carved between weathered flagstones. "
            "Bird's eye view looking straight down. "
            "Dark fantasy style, gritty and worn. "
            "The stone surface fills the entire image completely, "
            "extending beyond all four edges. "
            "Painted in a retro low-resolution blocky style with chunky details. "
            "Dark color palette: charcoal gray, near-black, with sickly green glow."
        ),
        "style": "natural",
        "tileset_light": (20, 18),
        "tileset_dark": (21, 18),
        "post_process": "terrain",
        "terrain_tile_id": 18,  # Level.Tile POISON_STREAM
    },
    "B6": {
        "name": "Wanderer's Robe",
        "type": "item",
        "item_id": 22,
        "prompt": (
            "On a completely solid flat hot magenta background (hex FF00FF), "
            "a vivid fantasy illustration of a traveler's hooded brown robe with "
            "a rope belt and leather shoulder patches, worn and weathered, "
            "displayed front-facing as if worn by an invisible figure. "
            "Vivid striking colors: brown homespun cloth, rope belt, leather patches. "
            "Strong readable silhouette against the magenta. "
            "The background must be entirely uniform solid magenta with absolutely nothing else. "
            "A single item only, no hands, no characters, no other elements. "
            "Painted in a clean illustrative style."
        ),
        "style": "vivid",
        "tileset_pos": (10, 11),  # Overwrite in-place at Vector2i(10, 11)
        "post_process": "item_magenta",
        "magenta_params": {"hue_deg": 25, "achromatic": False, "bleed": 1},
    },
    "B7": {
        "name": "Orb Watcher Frame",
        "type": "ui",
        "prompt": (
            "A painting of a wrought iron circular frame in the style of a dark "
            "fortress watchtower, ornate dark iron with spikes and rivets forming "
            "a round window frame, gothic dark fantasy metalwork, "
            "retro low-resolution blocky illustration, on solid black background. "
            "A single circular ornamental frame, no text, no other elements."
        ),
        "style": "natural",
        "output_path": "orb_frame_watcher.png",
        "output_size": 100,
        "post_process": "orb_frame",
    },
}


# ============================================================================
# HSV CONVERSION (same proven functions as fix_item_magenta.py)
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
# MAGENTA CORRECTION + BG REMOVAL (from fix_item_magenta.py)
# ============================================================================

def correct_magenta_bleed(img, target_hue_deg, achromatic=False, bleed_severity=1):
    """Fix magenta bleed for items."""
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


def bg_remove_3pass(img):
    """3-pass magenta BG removal (proven from player/monster sprites)."""
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
    """Post-BG aggressive pink cleanup."""
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
# IMAGE PROCESSING (from existing pipeline scripts)
# ============================================================================

def auto_crop_and_resize(img: Image.Image, target_size: int = TILE_SIZE) -> Image.Image:
    """Auto-crop white borders and resize for terrain tiles."""
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]
    r, g, b = img_array[:, :, 0], img_array[:, :, 1], img_array[:, :, 2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD
    rows_with_content = np.any(content_mask, axis=1)
    cols_with_content = np.any(content_mask, axis=0)
    if not np.any(rows_with_content) or not np.any(cols_with_content):
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)
    row_start = np.argmax(rows_with_content)
    row_end = h - np.argmax(rows_with_content[::-1])
    col_start = np.argmax(cols_with_content)
    col_end = w - np.argmax(cols_with_content[::-1])
    border_top = row_start
    border_bottom = h - row_end
    border_left = col_start
    border_right = w - col_end
    min_border = int(h * 0.02)
    if (border_top > min_border or border_bottom > min_border or
            border_left > min_border or border_right > min_border):
        padding = 2
        row_start = max(0, row_start - padding)
        row_end = min(h, row_end + padding)
        col_start = max(0, col_start - padding)
        col_end = min(w, col_end + padding)
        cropped = img.crop((col_start, row_start, col_end, row_end))
        crop_w, crop_h = cropped.size
        if crop_w != crop_h:
            max_dim = max(crop_w, crop_h)
            square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 255))
            paste_x = (max_dim - crop_w) // 2
            paste_y = (max_dim - crop_h) // 2
            square.paste(cropped, (paste_x, paste_y))
            cropped = square
        return cropped.resize((target_size, target_size), Image.Resampling.NEAREST)
    else:
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)


def auto_crop_square_item(img):
    """Crop item sprite to content bounds and square it."""
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


def generate_dark_variant(img: Image.Image) -> Image.Image:
    """Generate dark/FOV variant: desaturate 60%, darken 40%, cool blue tint."""
    if img.mode == "RGBA":
        alpha = img.split()[3]
        rgb = img.convert("RGB")
    else:
        alpha = None
        rgb = img.convert("RGB")
    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)
    darkener = ImageEnhance.Brightness(desaturated)
    darkened = darkener.enhance(0.6)
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


def process_orb_frame(img_1024: Image.Image, output_size: int = 100) -> Image.Image:
    """Process orb frame: resize, make center circle + corners transparent."""
    # Resize to output size
    img = img_1024.convert("RGBA").resize(
        (output_size, output_size), Image.Resampling.LANCZOS
    )
    arr = np.array(img)
    h, w = arr.shape[:2]
    cx, cy = w / 2.0, h / 2.0
    radius_outer = min(cx, cy)  # Full circle radius
    radius_inner = radius_outer * 0.65  # Inner cutout (65% of radius)

    for y in range(h):
        for x in range(w):
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            # Make corners transparent (outside circle)
            if dist > radius_outer:
                arr[y, x, 3] = 0
            # Make center transparent (inside inner circle)
            elif dist < radius_inner:
                arr[y, x, 3] = 0
            # Smooth inner edge (anti-alias)
            elif dist < radius_inner + 2:
                factor = (dist - radius_inner) / 2.0
                arr[y, x, 3] = int(arr[y, x, 3] * factor)

    return Image.fromarray(arr)


# ============================================================================
# DALL-E GENERATION
# ============================================================================

class SpriteRegenerator:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.total_cost = 0.0
        self.api_calls = 0
        self.results = {}

    def generate_image(self, target_key: str, target: Dict, retry: int = 0) -> Optional[Image.Image]:
        """Call DALL-E 3 and return the 1024x1024 PIL image."""
        prompt = target["prompt"]
        style = target.get("style", "natural")

        print(f"\n  Calling DALL-E 3 (style={style})...")
        print(f"  Prompt: {prompt[:120]}...")

        try:
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style=style,
                n=1,
                response_format="b64_json",
            )

            self.api_calls += 1
            self.total_cost += COST_PER_IMAGE

            img_data = base64.b64decode(response.data[0].b64_json)
            img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")

            revised = getattr(response.data[0], "revised_prompt", None)
            if revised:
                print(f"  DALL-E revised: {revised[:120]}...")

            # Save raw 1024x1024
            raw_dir = self.output_dir / "raw"
            raw_dir.mkdir(exist_ok=True)
            raw_path = raw_dir / f"{target_key}_1024.png"
            img_1024.save(raw_path)
            print(f"  Saved raw: {raw_path.name}")

            return img_1024

        except Exception as e:
            print(f"  ERROR: {e}")
            if retry < MAX_RETRIES:
                print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                time.sleep(RATE_LIMIT_DELAY * 2)
                return self.generate_image(target_key, target, retry + 1)
            return None

    def process_item(self, target_key: str, target: Dict, img_1024: Image.Image) -> Optional[Image.Image]:
        """Process an item sprite: magenta correction + BG removal + crop + resize."""
        params = target.get("magenta_params", {})
        hue_deg = params.get("hue_deg", 0)
        achromatic = params.get("achromatic", True)
        bleed = params.get("bleed", 1)

        print(f"  Step 1: Magenta correction (hue={hue_deg}, achromatic={achromatic})")
        corrected = correct_magenta_bleed(img_1024, hue_deg, achromatic, bleed)

        # Save corrected for review
        corrected_dir = self.output_dir / "corrected"
        corrected_dir.mkdir(exist_ok=True)
        corrected.save(corrected_dir / f"{target_key}_corrected.png")

        print(f"  Step 2: BG removal")
        transparent = bg_remove_3pass(corrected)

        print(f"  Step 3: Pink cleanup")
        cleaned = cleanup_remaining_pink(transparent, hue_deg, achromatic)

        print(f"  Step 4: Crop + resize to {TILE_SIZE}x{TILE_SIZE}")
        cropped = auto_crop_square_item(cleaned)
        img_64 = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

        # Save processed
        processed_dir = self.output_dir / "processed"
        processed_dir.mkdir(exist_ok=True)
        img_64.save(processed_dir / f"{target_key}_light.png")
        print(f"  Saved: {target_key}_light.png ({img_64.size[0]}x{img_64.size[1]})")

        return img_64

    def process_terrain(self, target_key: str, target: Dict, img_1024: Image.Image) -> Tuple[Optional[Image.Image], Optional[Image.Image]]:
        """Process a terrain sprite: crop + resize + generate dark variant."""
        print(f"  Step 1: Auto-crop and resize to {TILE_SIZE}x{TILE_SIZE}")
        img_64 = auto_crop_and_resize(img_1024, TILE_SIZE)

        # Save light
        processed_dir = self.output_dir / "processed"
        processed_dir.mkdir(exist_ok=True)
        light_path = processed_dir / f"{target_key}_light.png"
        img_64.save(light_path)
        print(f"  Saved light: {target_key}_light.png")

        # Generate dark variant
        print(f"  Step 2: Generating dark variant")
        img_dark = generate_dark_variant(img_64)
        dark_path = processed_dir / f"{target_key}_dark.png"
        img_dark.save(dark_path)
        print(f"  Saved dark: {target_key}_dark.png")

        return img_64, img_dark

    def process_orb(self, target_key: str, target: Dict, img_1024: Image.Image) -> Optional[Image.Image]:
        """Process orb frame: resize + make center/corners transparent."""
        output_size = target.get("output_size", 100)
        print(f"  Step 1: Processing orb frame ({output_size}x{output_size})")
        result = process_orb_frame(img_1024, output_size)

        # Save to both output dir and final location
        processed_dir = self.output_dir / "processed"
        processed_dir.mkdir(exist_ok=True)
        result.save(processed_dir / f"{target_key}.png")

        # Save to final location
        final_path = ORB_OUTPUT_DIR / target["output_path"]
        ORB_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        result.save(final_path)
        print(f"  Saved orb frame: {final_path}")

        return result

    def integrate_tileset(self, sprites: Dict[str, Dict]):
        """Paste all generated sprites into the tileset and update tile_mapper.gd."""
        if not TILESET_PATH.exists():
            print(f"\n  ERROR: Tileset not found: {TILESET_PATH}")
            return False

        tileset = Image.open(TILESET_PATH).convert("RGBA")
        print(f"\n  Loaded tileset: {tileset.size[0]}x{tileset.size[1]}")

        changes = 0
        for key, data in sprites.items():
            target = TARGETS[key]
            sprite_type = target["type"]

            if sprite_type == "item":
                col, row = target["tileset_pos"]
                light_img = data.get("light")
                if light_img:
                    x, y = col * TILE_SIZE, row * TILE_SIZE
                    tileset.paste(light_img, (x, y), light_img)
                    print(f"  Pasted {key} ({target['name']}) at ({col}, {row})")
                    changes += 1

            elif sprite_type == "terrain":
                light_col, light_row = target["tileset_light"]
                dark_col, dark_row = target["tileset_dark"]

                light_img = data.get("light")
                dark_img = data.get("dark")

                if light_img:
                    x, y = light_col * TILE_SIZE, light_row * TILE_SIZE
                    tileset.paste(light_img, (x, y))
                    print(f"  Pasted {key} light ({target['name']}) at ({light_col}, {light_row})")
                    changes += 1

                if dark_img:
                    x, y = dark_col * TILE_SIZE, dark_row * TILE_SIZE
                    tileset.paste(dark_img, (x, y))
                    print(f"  Pasted {key} dark ({target['name']}) at ({dark_col}, {dark_row})")
                    changes += 1

        if changes > 0:
            tileset.save(TILESET_PATH, "PNG")
            print(f"\n  Tileset saved with {changes} sprite changes")
        else:
            print(f"\n  No sprites to integrate into tileset")

        return changes > 0

    def update_tile_mapper(self, sprites: Dict[str, Dict]):
        """Update tile_mapper.gd with new coordinate entries."""
        if not TILE_MAPPER_PATH.exists():
            print(f"\n  ERROR: tile_mapper.gd not found")
            return False

        content = TILE_MAPPER_PATH.read_text()
        updates = []

        for key, data in sprites.items():
            target = TARGETS[key]

            if key == "B1":
                # Add item_coords[58] = Vector2i(1, 17)
                # Insert after the last item_coords entry before duplicates section
                col, row = target["tileset_pos"]
                new_line = f"\titem_coords[58] = Vector2i({col}, {row})  # Curved Sword"
                # Find where to insert - after item_coords[557]
                if "item_coords[58]" not in content:
                    # Insert after item_coords[557] line
                    insert_after = "item_coords[557] = Vector2i(0, 17)  # -> item_556"
                    if insert_after in content:
                        content = content.replace(
                            insert_after,
                            insert_after + "\n" + new_line
                        )
                        updates.append(f"  Added item_coords[58] = Vector2i({col}, {row})")
                    else:
                        # Try inserting after item_coords[556]
                        insert_after2 = "item_coords[556] = Vector2i(0, 17)  # Necromancer Sighting"
                        if insert_after2 in content:
                            content = content.replace(
                                insert_after2,
                                insert_after2 + "\n" + new_line
                            )
                            updates.append(f"  Added item_coords[58] = Vector2i({col}, {row})")

            elif key == "B2":
                # Update terrain_coords[17] for VINE_FLOOR
                light_col, light_row = target["tileset_light"]
                dark_col, dark_row = target["tileset_dark"]
                old_line = '\tterrain_coords[17] = {"light": Vector2i(12, 5), "dark": Vector2i(13, 5)}    # VINE_FLOOR ->  (terrain 86)'
                new_line = f'\tterrain_coords[17] = {{"light": Vector2i({light_col}, {light_row}), "dark": Vector2i({dark_col}, {dark_row})}}    # VINE_FLOOR -> DALL-E regen'
                if old_line in content:
                    content = content.replace(old_line, new_line)
                    updates.append(f"  Updated terrain_coords[17] (VINE_FLOOR)")

            elif key == "B3":
                # Update terrain_coords[19] for WEB
                light_col, light_row = target["tileset_light"]
                dark_col, dark_row = target["tileset_dark"]
                old_line = '\tterrain_coords[19] = {"light": Vector2i(0, 18), "dark": Vector2i(1, 18)}    # WEB'
                new_line = f'\tterrain_coords[19] = {{"light": Vector2i({light_col}, {light_row}), "dark": Vector2i({dark_col}, {dark_row})}}    # WEB -> DALL-E regen'
                if old_line in content:
                    content = content.replace(old_line, new_line)
                    updates.append(f"  Updated terrain_coords[19] (WEB)")

            elif key == "B4":
                # Update terrain_coords[5] for STAIRS_DOWN
                light_col, light_row = target["tileset_light"]
                dark_col, dark_row = target["tileset_dark"]
                old_line = '\tterrain_coords[5] = {"light": Vector2i(2, 5), "dark": Vector2i(3, 5)}    # STAIRS_DOWN ->  (terrain 81)'
                new_line = f'\tterrain_coords[5] = {{"light": Vector2i({light_col}, {light_row}), "dark": Vector2i({dark_col}, {dark_row})}}    # STAIRS_DOWN -> DALL-E regen'
                if old_line in content:
                    content = content.replace(old_line, new_line)
                    updates.append(f"  Updated terrain_coords[5] (STAIRS_DOWN)")

            elif key == "B5":
                # Update terrain_coords[18] for POISON_STREAM
                light_col, light_row = target["tileset_light"]
                dark_col, dark_row = target["tileset_dark"]
                old_line = '\tterrain_coords[18] = {"light": Vector2i(6, 3), "dark": Vector2i(7, 3)}    # POISON_STREAM -> reuse water coords (terrain 51)'
                new_line = f'\tterrain_coords[18] = {{"light": Vector2i({light_col}, {light_row}), "dark": Vector2i({dark_col}, {dark_row})}}    # POISON_STREAM -> DALL-E regen'
                if old_line in content:
                    content = content.replace(old_line, new_line)
                    updates.append(f"  Updated terrain_coords[18] (POISON_STREAM)")

            # B6 doesn't need tile_mapper update (same coords Vector2i(10, 11))
            # B7 doesn't need tile_mapper update (UI element, not tileset)

        if updates:
            TILE_MAPPER_PATH.write_text(content)
            print(f"\n  tile_mapper.gd updated:")
            for u in updates:
                print(u)
        else:
            print(f"\n  No tile_mapper.gd updates needed")

        return True

    def run_target(self, target_key: str, skip_api: bool = False) -> bool:
        """Run a single target through the full pipeline."""
        target = TARGETS[target_key]
        sprite_type = target["type"]

        print(f"\n{'=' * 60}")
        print(f"TARGET {target_key}: {target['name']} (type={sprite_type})")
        print(f"{'=' * 60}")

        # Check for existing raw image if skipping API
        raw_path = self.output_dir / "raw" / f"{target_key}_1024.png"
        img_1024 = None

        if skip_api and raw_path.exists():
            print(f"  Loading existing raw: {raw_path}")
            img_1024 = Image.open(raw_path).convert("RGBA")
        elif not skip_api:
            img_1024 = self.generate_image(target_key, target)
            time.sleep(RATE_LIMIT_DELAY)
        else:
            print(f"  SKIP: No raw image found and --skip-api set")
            return False

        if img_1024 is None:
            print(f"  FAILED: No image available for {target_key}")
            return False

        # Process based on type
        result_data = {}

        if target["post_process"] == "item_magenta":
            light = self.process_item(target_key, target, img_1024)
            if light:
                result_data["light"] = light

        elif target["post_process"] == "terrain":
            light, dark = self.process_terrain(target_key, target, img_1024)
            if light:
                result_data["light"] = light
            if dark:
                result_data["dark"] = dark

        elif target["post_process"] == "orb_frame":
            orb = self.process_orb(target_key, target, img_1024)
            if orb:
                result_data["orb"] = orb

        self.results[target_key] = result_data
        return bool(result_data)

    def run_all(self, target_keys: list = None, skip_api: bool = False, dry_run: bool = False):
        """Run all (or specified) targets."""
        keys = target_keys or list(TARGETS.keys())

        if dry_run:
            print(f"\n{'=' * 60}")
            print(f"DRY RUN - {len(keys)} targets")
            print(f"{'=' * 60}")
            for key in keys:
                t = TARGETS[key]
                print(f"\n  {key}: {t['name']} (type={t['type']})")
                print(f"    Style: {t.get('style', 'natural')}")
                if t["type"] == "item":
                    print(f"    Tileset: Vector2i{t['tileset_pos']}")
                elif t["type"] == "terrain":
                    print(f"    Tileset light: Vector2i{t['tileset_light']}")
                    print(f"    Tileset dark: Vector2i{t['tileset_dark']}")
                elif t["type"] == "ui":
                    print(f"    Output: {t['output_path']}")
                print(f"    Prompt: {t['prompt'][:80]}...")
            total = len([k for k in keys if TARGETS[k]["type"] != "ui"])
            # UI targets get 1 call, terrain get 1 call (dark is programmatic)
            api_calls = len(keys)
            print(f"\n  Estimated API calls: {api_calls}")
            print(f"  Estimated cost: ${api_calls * COST_PER_IMAGE:.2f}")
            return

        # Run each target
        success = 0
        for key in keys:
            if self.run_target(key, skip_api):
                success += 1

        print(f"\n{'=' * 60}")
        print(f"GENERATION COMPLETE: {success}/{len(keys)} targets")
        print(f"API calls: {self.api_calls} | Cost: ${self.total_cost:.2f}")
        print(f"{'=' * 60}")

        # Integrate into tileset
        if self.results:
            print(f"\n{'=' * 60}")
            print(f"TILESET INTEGRATION")
            print(f"{'=' * 60}")
            self.integrate_tileset(self.results)
            self.update_tile_mapper(self.results)

        # Summary
        print(f"\n{'=' * 60}")
        print(f"FINAL SUMMARY")
        print(f"{'=' * 60}")
        for key in keys:
            status = "OK" if key in self.results and self.results[key] else "FAILED"
            t = TARGETS[key]
            print(f"  {key}: {t['name']:25s} {status}")
        print(f"\n  Total API calls: {self.api_calls}")
        print(f"  Total cost: ${self.total_cost:.2f}")
        print(f"  Output dir: {self.output_dir}")


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Necromancer Sprite Regenerator")
    parser.add_argument("--target", type=str, nargs="+",
                        choices=list(TARGETS.keys()),
                        help="Run specific targets (e.g. --target B1 B3)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show plan without making API calls")
    parser.add_argument("--skip-api", action="store_true",
                        help="Skip DALL-E calls, use existing raw images")

    args = parser.parse_args()

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key and not args.dry_run:
        print("ERROR: OPENAI_API_KEY not set in environment or .env file")
        sys.exit(1)

    gen = SpriteRegenerator(api_key or "dummy")
    gen.run_all(
        target_keys=args.target,
        skip_api=args.skip_api,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
