#!/usr/bin/env python3
"""
Dark Halls (Layer 3) Tile Generation — Corrupted Elven Sanctum

Generates tiles for F7-F9 with creative direction:
  Corrupted elven sanctum seized by Morgul sorcery. Graceful architecture
  defaced with iron chains and burning runes. Shadow itself is a weapon.

Palette: obsidian black (#1a1520), amethyst purple (#7851a9),
         bone white (#d4c9b0), phosphorescent green (#44ff88),
         sickly amber (#cc8833).

Follows project terrain gen best practices from /tileset-gen skill.
"""

import os
import sys
import io
import base64
import argparse
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter
from dotenv import load_dotenv
from openai import OpenAI

# ============================================================================
# PATHS
# ============================================================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "dark_halls"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "dark_halls"
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"

# Outer Pits stairs for recoloring reference
OUTER_PITS_RAW = SCRIPT_DIR / "layer_tiles" / "raw" / "outer_pits_v2"

RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================================
# DALL-E CLIENT
# ============================================================================

load_dotenv(SCRIPT_DIR / ".env")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ============================================================================
# SHARED PREAMBLE — Corrupted Elven Sanctum
# ============================================================================

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Dark corrupted stone sanctum illustration. "
    "Palette: obsidian black stone with amethyst purple mineral veining, bone white carved inlays. "
    "Fills the entire frame edge to edge. No text. "
)

# ============================================================================
# TILE DEFINITIONS
# ============================================================================

TILES = {
    # ---- Phase 1: Anchor tiles ----
    "floor": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Polished obsidian-black stone flagstones in a precise geometric pattern. "
            "Thick amethyst purple mineral veins run between the stone joints. "
            "Faint bone-white geometric inlay fragments visible in some flagstones, "
            "elvish decorative motifs partially chiseled away and damaged. "
            "The stone is smooth and dark, almost glass-like. "
            "Seamless tileable dark obsidian floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Smooth obsidian-black stone blocks in precise masonry rows. "
            "Thick amethyst purple mineral veins streak through the dark stone. "
            "A horizontal band of carved bone-white elvish leaf motifs spans the center, "
            "partially defaced with crude iron chain links bolted across the carvings. "
            "The chain is dark wrought iron with visible bolt heads. "
            "Seamless tileable dark obsidian wall texture."
        ),
    },

    # ---- Phase 3: Navigation pair (recolored from outer_pits) ----
    # These are handled programmatically, not via DALL-E

    # ---- Phase 4: Environmental (DALL-E based) ----
    "collapsed_pillar": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Obsidian-black stone floor with a large broken stone column lying across it. "
            "The column is bone-white stone with amethyst purple veining, cracked and shattered. "
            "Carved elvish leaf motifs visible on the column fragments. "
            "Dark rubble and stone chips scattered around the broken pillar. "
            "Seamless tileable broken pillar on dark stone floor texture."
        ),
    },
    "defaced_carvings": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Smooth obsidian-black wall with elaborate bone-white carved leaf and vine motifs. "
            "Deep gouges and scratches cut through the carvings with crude iron tool marks. "
            "Amethyst purple veins in the black stone visible through the damage. "
            "Iron chain links and crude bolts hammered into the carved surface. "
            "Seamless tileable defaced carved wall texture."
        ),
    },
}

# ============================================================================
# TILESET PASTE COORDINATES — Row 21, Cols 0-11
# ============================================================================

PASTE_MAP = {
    'wall':        [(0, 21), (1, 21)],   # light, dark
    'floor':       [(2, 21), (3, 21)],
    'door_closed': [(4, 21), (5, 21)],
    'door_open':   [(6, 21), (7, 21)],
    'stairs_down': [(8, 21), (9, 21)],
    'stairs_up':   [(10, 21), (11, 21)],
}

# ============================================================================
# DARK VARIANT GENERATION
# ============================================================================

def make_dark_variant(light_img: Image.Image) -> Image.Image:
    """Generate dark/remembered variant: desaturate 60%, darken 40%, cool blue tint."""
    arr = np.array(light_img).astype(np.float64)
    gray = np.mean(arr[:, :, :3], axis=2, keepdims=True)
    arr[:, :, :3] = arr[:, :, :3] * 0.4 + gray * 0.6
    arr[:, :, :3] *= 0.6
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


# ============================================================================
# STAIRS RECOLOR (from outer_pits reference)
# ============================================================================

def recolor_stairs(src_path: Path, direction: str) -> Image.Image:
    """Recolor outer_pits stairs to dark_halls obsidian-purple palette."""
    src = np.array(Image.open(src_path).convert("RGBA")).astype(np.float64)
    result = src.copy()

    r, g, b = result[:,:,0], result[:,:,1], result[:,:,2]

    # 1. Remove green tones — shift toward grey
    green_dominant = (g > r * 1.05) & (g > 40)
    grey_target = (r + b) / 2
    result[:,:,1] = np.where(green_dominant, g * 0.4 + grey_target * 0.6, g)

    # 2. Darken significantly (obsidian is very dark)
    result[:,:,:3] *= 0.70

    # 3. Shift toward purple — boost blue, reduce green slightly
    result[:,:,2] = np.minimum(result[:,:,2] * 1.25, 255)  # blue up
    result[:,:,1] *= 0.85  # green down
    result[:,:,0] *= 0.95  # red slight down

    # 4. Add amethyst purple tint to mid-tones
    lum = np.mean(result[:,:,:3], axis=2)
    mid_tone = (lum > 30) & (lum < 120)
    result[:,:,0] = np.where(mid_tone, np.minimum(result[:,:,0] * 1.08, 255), result[:,:,0])
    result[:,:,2] = np.where(mid_tone, np.minimum(result[:,:,2] * 1.15, 255), result[:,:,2])

    # 5. For stairs_up: warm amber light on bright areas
    if direction == "up":
        bright = lum > 80
        result[:,:,0] = np.where(bright, np.minimum(result[:,:,0] * 1.15, 255), result[:,:,0])
        result[:,:,1] = np.where(bright, result[:,:,1] * 0.95, result[:,:,1])

    # 6. Soot-stained edges
    h, w = result.shape[:2]
    y_dist = np.minimum(np.arange(h)[:, None], np.arange(h-1, -1, -1)[:, None])
    x_dist = np.minimum(np.arange(w)[None, :], np.arange(w-1, -1, -1)[None, :])
    edge_dist = np.minimum(y_dist, x_dist).astype(np.float64)
    edge_darken = np.clip(1.0 - (edge_dist / 200) * 0.12, 0.88, 1.0)
    result[:,:,0] *= edge_darken
    result[:,:,1] *= edge_darken
    result[:,:,2] *= edge_darken

    return Image.fromarray(result.clip(0, 255).astype(np.uint8))


# ============================================================================
# PROGRAMMATIC DOOR GENERATION
# ============================================================================

def generate_door_closed(wall_1024: Image.Image) -> Image.Image:
    """Programmatic door_closed: obsidian wall + iron-banded door + Morgul-green rune."""
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size

    # Door opening — 10% wider, flush with bottom edge
    door_l, door_r = int(w * 0.20), int(w * 0.80)
    door_t, door_b = int(h * 0.10), h  # flush to bottom
    draw.rectangle([door_l, door_t, door_r, door_b], fill=(15, 12, 20, 255))

    # Door surface — dark wood with purple tint
    inner_margin = 20
    dl = door_l + inner_margin
    dr = door_r - inner_margin
    dt = door_t + inner_margin
    db = door_b  # flush to bottom
    draw.rectangle([dl, dt, dr, db], fill=(30, 22, 35, 255))

    # Vertical wood grain lines
    for x_off in range(dl + 30, dr, 60):
        draw.line([(x_off, dt), (x_off, db)], fill=(25, 18, 30, 255), width=3)

    # Iron frame — thick dark iron border (no bottom bar — flush with floor)
    frame_w = 35
    iron_color = (40, 38, 45, 255)
    draw.rectangle([door_l, door_t, door_r, door_t + frame_w], fill=iron_color)  # top
    draw.rectangle([door_l, door_t, door_l + frame_w, door_b], fill=iron_color)  # left
    draw.rectangle([door_r - frame_w, door_t, door_r, door_b], fill=iron_color)  # right

    # Iron crossbands — 3 horizontal bands
    band_h = 18
    for y_frac in [0.30, 0.50, 0.70]:
        by = int(door_t + (door_b - door_t) * y_frac - band_h // 2)
        draw.rectangle([dl, by, dr, by + band_h], fill=iron_color)
        # Rivets on bands
        for rx in range(dl + 40, dr, 80):
            draw.ellipse([rx-8, by+2, rx+8, by+band_h-2], fill=(55, 52, 58, 255))

    # Corner rivets on frame (top corners only — bottom is flush)
    rivet_r = 12
    for cx, cy in [(door_l+18, door_t+18), (door_r-18, door_t+18)]:
        draw.ellipse([cx-rivet_r, cy-rivet_r, cx+rivet_r, cy+rivet_r], fill=(60, 55, 65, 255))

    # Morgul rune — glowing green symbol in center of door
    cx, cy = w // 2, int(door_t + (door_b - door_t) * 0.45)
    rune_color = (68, 255, 136, 200)
    rune_dim = (40, 180, 80, 150)

    # Central eye shape (Morgul style — angular, not round)
    points_outer = [
        (cx - 100, cy), (cx - 40, cy - 60), (cx, cy - 80),
        (cx + 40, cy - 60), (cx + 100, cy),
        (cx + 40, cy + 60), (cx, cy + 80), (cx - 40, cy + 60),
    ]
    draw.polygon(points_outer, outline=rune_color, fill=None)
    draw.polygon(points_outer, outline=rune_dim, fill=None)  # dimmer double line

    # Inner rune circle
    draw.ellipse([cx-35, cy-35, cx+35, cy+35], outline=rune_color, fill=None, width=3)
    # Center dot
    draw.ellipse([cx-12, cy-12, cx+12, cy+12], fill=rune_color)

    # Vertical line through eye
    draw.line([(cx, cy - 90), (cx, cy + 90)], fill=rune_color, width=3)

    # Add glow bloom around rune
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    glow_draw.ellipse([cx-120, cy-120, cx+120, cy+120], fill=(30, 140, 60, 40))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=30))
    img = Image.alpha_composite(img, glow_layer)

    return img


def generate_door_open(wall_1024: Image.Image) -> Image.Image:
    """Programmatic door_open: obsidian wall + open doorway + faint green glow."""
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size

    # Door opening — 10% wider, flush with bottom edge
    door_l, door_r = int(w * 0.20), int(w * 0.80)
    door_t, door_b = int(h * 0.10), h  # flush to bottom
    draw.rectangle([door_l, door_t, door_r, door_b], fill=(8, 6, 12, 255))

    # Iron frame (no bottom bar — flush with floor)
    frame_w = 35
    iron_color = (40, 38, 45, 255)
    draw.rectangle([door_l, door_t, door_r, door_t + frame_w], fill=iron_color)  # top
    draw.rectangle([door_l, door_t, door_l + frame_w, door_b], fill=iron_color)  # left
    draw.rectangle([door_r - frame_w, door_t, door_r, door_b], fill=iron_color)  # right

    # Door panel swung open (visible on right side)
    panel_w = 60
    draw.rectangle([door_r - frame_w - panel_w, door_t + frame_w,
                     door_r - frame_w, door_b],
                    fill=(30, 22, 35, 255))

    # Corner rivets (top only)
    rivet_r = 12
    for cx, cy in [(door_l+18, door_t+18), (door_r-18, door_t+18)]:
        draw.ellipse([cx-rivet_r, cy-rivet_r, cx+rivet_r, cy+rivet_r], fill=(60, 55, 65, 255))

    # Faint green glow at threshold (at bottom edge)
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    gcx, gcy = w // 2, door_b - 60
    glow_draw.ellipse([gcx-180, gcy-60, gcx+180, gcy+60], fill=(25, 100, 50, 35))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=25))
    img = Image.alpha_composite(img, glow_layer)

    return img


# ============================================================================
# PROCEDURAL ENVIRONMENTAL TILES
# ============================================================================

def generate_shadow_pool(floor_64: Image.Image) -> Image.Image:
    """Procedural shadow pool on floor — dark purple-black pooling with amethyst shimmer."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]

    # Create irregular pool shape with overlapping ellipses
    mask = np.zeros((h, w), dtype=np.float64)
    cx, cy = w // 2, h // 2
    rng = np.random.RandomState(42)

    for _ in range(6):
        ox = cx + rng.randint(-8, 9)
        oy = cy + rng.randint(-8, 9)
        rx = rng.randint(14, 24)
        ry = rng.randint(14, 24)
        yy, xx = np.ogrid[:h, :w]
        ellipse = ((xx - ox) / rx) ** 2 + ((yy - oy) / ry) ** 2
        mask = np.maximum(mask, np.clip(1.0 - ellipse, 0, 1))

    mask = gaussian_filter(mask, sigma=3)
    mask = np.clip(mask, 0, 1)

    # Darken pool area and shift to purple
    pool_color = np.array([20, 10, 30])  # dark purple-black
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask * 0.7) + pool_color[c] * mask * 0.7

    # Amethyst shimmer highlights in center
    shimmer_mask = gaussian_filter(mask, sigma=2) * mask
    shimmer_mask = np.clip(shimmer_mask * 1.5 - 0.3, 0, 1)
    shimmer_color = np.array([120, 81, 169])  # amethyst
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] + shimmer_color[c] * shimmer_mask * 0.15

    arr[:,:,3] = 255  # full alpha
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_morgul_sigil(floor_64: Image.Image) -> Image.Image:
    """Procedural Morgul sigil — phosphorescent green rune circle with glow."""
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)
    arr = np.array(img).astype(np.float64)
    h, w = arr.shape[:2]
    cx, cy = w // 2, h // 2

    # Outer ring
    r_outer = 22
    r_inner = 18
    yy, xx = np.ogrid[:h, :w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    ring = ((dist >= r_inner) & (dist <= r_outer)).astype(np.float64)

    # Inner circle
    r_small = 8
    inner = (dist <= r_small).astype(np.float64)

    # Cross lines
    cross = np.zeros((h, w), dtype=np.float64)
    cross[cy-1:cy+2, cx-r_outer:cx+r_outer+1] = 1.0  # horizontal
    cross[cy-r_outer:cy+r_outer+1, cx-1:cx+2] = 1.0  # vertical

    # Combine all glyph elements
    glyph = np.clip(ring + inner + cross * 0.8, 0, 1)

    # Apply green glow
    green_color = np.array([68, 255, 136])
    glow = gaussian_filter(glyph, sigma=4) * 0.4  # soft glow halo
    combined = np.clip(glyph + glow, 0, 1)

    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - combined * 0.8) + green_color[c] * combined * 0.8

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_binding_circle(floor_64: Image.Image) -> Image.Image:
    """Procedural binding circle — concentric green rings trap."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    cx, cy = w // 2, h // 2

    yy, xx = np.ogrid[:h, :w]
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)

    # Three concentric rings
    rings = np.zeros((h, w), dtype=np.float64)
    for r_center, thickness in [(24, 2.5), (17, 2.0), (10, 1.5)]:
        ring = np.exp(-((dist - r_center) ** 2) / (2 * thickness ** 2))
        rings = np.maximum(rings, ring)

    # Radial lines (8 spokes)
    spokes = np.zeros((h, w), dtype=np.float64)
    for angle_deg in range(0, 360, 45):
        angle = np.radians(angle_deg)
        dx = np.cos(angle)
        dy = np.sin(angle)
        # Distance from spoke line
        px = (xx - cx) * dy - (yy - cy) * dx
        spoke_mask = (np.abs(px) < 1.5) & (dist < 25) & (dist > 8)
        spokes = np.maximum(spokes, spoke_mask.astype(np.float64) * 0.7)

    combined = np.clip(rings + spokes, 0, 1)
    glow = gaussian_filter(combined, sigma=3) * 0.35
    combined = np.clip(combined + glow, 0, 1)

    green_color = np.array([50, 220, 110])  # slightly different green from sigil
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - combined * 0.75) + green_color[c] * combined * 0.75

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_bone_fragments(floor_64: Image.Image) -> Image.Image:
    """Procedural bone fragments scattered on floor."""
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)

    rng = np.random.RandomState(77)
    bone_color_base = (212, 201, 176)  # bone white

    # Scatter small bone fragments
    for _ in range(12):
        x = rng.randint(8, 56)
        y = rng.randint(8, 56)
        length = rng.randint(3, 8)
        angle = rng.uniform(0, 3.14159)
        dx = int(length * np.cos(angle))
        dy = int(length * np.sin(angle))
        # Slight color variation
        r_off = rng.randint(-15, 10)
        color = tuple(max(0, min(255, c + r_off)) for c in bone_color_base) + (220,)
        draw.line([(x, y), (x + dx, y + dy)], fill=color, width=2)

    # A few larger bone chunks
    for _ in range(4):
        x = rng.randint(12, 52)
        y = rng.randint(12, 52)
        rx = rng.randint(2, 4)
        ry = rng.randint(1, 3)
        r_off = rng.randint(-20, 5)
        color = tuple(max(0, min(255, c + r_off)) for c in bone_color_base) + (200,)
        draw.ellipse([x-rx, y-ry, x+rx, y+ry], fill=color)

    return img


# ============================================================================
# GENERATION
# ============================================================================

def generate_tile(name: str, tile_def: dict, attempt: int = 1) -> Image.Image:
    """Generate a single tile via DALL-E 3. Returns 1024x1024 RGBA image."""
    print(f"  [{name}] Generating (attempt {attempt})...")
    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=tile_def["prompt"],
            size="1024x1024",
            quality="standard",
            style="natural",
            n=1,
            response_format="b64_json",
        )
        img_data = base64.b64decode(response.data[0].b64_json)
        img = Image.open(io.BytesIO(img_data)).convert("RGBA")
        return img
    except Exception as e:
        print(f"  [{name}] FAILED: {e}")
        return None


def check_edge_brightness(img: Image.Image, threshold: int = 180) -> bool:
    """Check if edges are too bright (white border issue)."""
    arr = np.array(img)[:,:,:3]
    h, w = arr.shape[:2]
    edge_pixels = np.concatenate([
        arr[:10, :, :].reshape(-1, 3),     # top
        arr[-10:, :, :].reshape(-1, 3),    # bottom
        arr[:, :10, :].reshape(-1, 3),     # left
        arr[:, -10:, :].reshape(-1, 3),    # right
    ])
    mean_brightness = edge_pixels.mean()
    print(f"  Edge brightness: {mean_brightness:.1f} (threshold: {threshold})")
    return mean_brightness > threshold


def process_tile(name: str, img_1024: Image.Image) -> tuple:
    """Process 1024->64 light + dark. Returns (light_64, dark_64)."""
    light_64 = img_1024.resize((64, 64), Image.LANCZOS)
    dark_64 = make_dark_variant(light_64)
    return light_64, dark_64


def run_phase(phase_num: int, tiles_in_phase: dict, max_attempts: int = 3):
    """Generate all tiles in a phase sequentially."""
    results = {}
    for name, tile_def in tiles_in_phase.items():
        success = False
        for attempt in range(1, max_attempts + 1):
            img_1024 = generate_tile(name, tile_def, attempt)
            if img_1024 is not None:
                # Check for white edges
                if check_edge_brightness(img_1024):
                    print(f"  [{name}] White edge detected, re-rolling...")
                    if attempt < max_attempts:
                        time.sleep(2)
                        continue

                raw_path = RAW_DIR / f"{name}_1024.png"
                img_1024.save(raw_path)
                print(f"  [{name}] Saved raw: {raw_path.name}")

                light_64, dark_64 = process_tile(name, img_1024)
                light_path = PROCESSED_DIR / f"{name}_light.png"
                dark_path = PROCESSED_DIR / f"{name}_dark.png"
                light_64.save(light_path)
                dark_64.save(dark_path)
                print(f"  [{name}] Saved: {light_path.name} + {dark_path.name}")

                results[name] = {
                    "raw": raw_path,
                    "light": light_path,
                    "dark": dark_path,
                    "img_1024": img_1024,
                    "light_64": light_64,
                    "dark_64": dark_64,
                }
                success = True
                break
            else:
                if attempt < max_attempts:
                    print(f"  [{name}] Retrying in 3s...")
                    time.sleep(3)
        if not success:
            print(f"  [{name}] FAILED after {max_attempts} attempts!")
    return results


def main():
    parser = argparse.ArgumentParser(description="Generate Dark Halls layer tiles")
    parser.add_argument("--phase", type=int, choices=[1, 2, 3, 4, 5],
                        help="Run only a specific phase (1-5)")
    parser.add_argument("--tile", type=str,
                        help="Generate only a single specific tile")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print prompts without calling DALL-E")
    parser.add_argument("--attempts", type=int, default=3,
                        help="Max generation attempts per tile (default: 3)")
    parser.add_argument("--stairs", action="store_true",
                        help="Generate recolored stairs from outer_pits reference")
    parser.add_argument("--doors", action="store_true",
                        help="Generate programmatic doors")
    parser.add_argument("--env", action="store_true",
                        help="Generate procedural environmental tiles (needs floor)")
    args = parser.parse_args()

    print("=" * 60)
    print("DARK HALLS TILE GENERATION")
    print(f"Output: {RAW_DIR}")
    print(f"Processed: {PROCESSED_DIR}")
    print("=" * 60)

    # --- Stairs recolor mode ---
    if args.stairs:
        print("\n--- Recoloring stairs from outer_pits reference ---")
        for direction in ["down", "up"]:
            src = OUTER_PITS_RAW / f"stairs_{direction}_1024.png"
            if not src.exists():
                print(f"  MISSING: {src}")
                continue
            img_1024 = recolor_stairs(src, direction)
            raw_path = RAW_DIR / f"stairs_{direction}_1024.png"
            img_1024.save(raw_path)
            light_64, dark_64 = process_tile(f"stairs_{direction}", img_1024)
            light_64.save(PROCESSED_DIR / f"stairs_{direction}_light.png")
            dark_64.save(PROCESSED_DIR / f"stairs_{direction}_dark.png")
            print(f"  stairs_{direction}: saved light + dark")
        return

    # --- Door programmatic mode ---
    if args.doors:
        print("\n--- Generating programmatic doors ---")
        wall_raw = RAW_DIR / "wall_1024.png"
        if not wall_raw.exists():
            print(f"  MISSING wall raw: {wall_raw}")
            print("  Generate wall first (--phase 1)")
            return

        wall_1024 = Image.open(wall_raw).convert("RGBA")

        for door_type, gen_func in [("door_closed", generate_door_closed),
                                      ("door_open", generate_door_open)]:
            img_1024 = gen_func(wall_1024)
            raw_path = RAW_DIR / f"{door_type}_1024.png"
            img_1024.save(raw_path)
            light_64, dark_64 = process_tile(door_type, img_1024)
            light_64.save(PROCESSED_DIR / f"{door_type}_light.png")
            dark_64.save(PROCESSED_DIR / f"{door_type}_dark.png")
            print(f"  {door_type}: saved light + dark")
        return

    # --- Environmental procedural mode ---
    if args.env:
        print("\n--- Generating procedural environmental tiles ---")
        floor_light = PROCESSED_DIR / "floor_light.png"
        if not floor_light.exists():
            print(f"  MISSING floor: {floor_light}")
            print("  Generate floor first (--phase 1)")
            return

        floor_64 = Image.open(floor_light).convert("RGBA")

        env_generators = {
            "shadow_pool": generate_shadow_pool,
            "morgul_sigil": generate_morgul_sigil,
            "binding_circle": generate_binding_circle,
            "bone_fragments": generate_bone_fragments,
        }

        for name, gen_func in env_generators.items():
            light_64 = gen_func(floor_64)
            dark_64 = make_dark_variant(light_64)
            light_64.save(PROCESSED_DIR / f"{name}_light.png")
            dark_64.save(PROCESSED_DIR / f"{name}_dark.png")
            print(f"  {name}: saved light + dark")
        return

    # --- Standard DALL-E phase mode ---
    if args.tile:
        if args.tile not in TILES:
            print(f"Unknown tile: {args.tile}. Available: {list(TILES.keys())}")
            return
        selected = {args.tile: TILES[args.tile]}
        phases_to_run = [TILES[args.tile]["phase"]]
    elif args.phase:
        selected = {k: v for k, v in TILES.items() if v["phase"] == args.phase}
        phases_to_run = [args.phase]
    else:
        selected = TILES
        phases_to_run = sorted(set(v["phase"] for v in TILES.values()))

    if args.dry_run:
        for name, tile_def in selected.items():
            print(f"\n--- {name} (Phase {tile_def['phase']}) ---")
            print(f"Prompt ({len(tile_def['prompt'])} chars):")
            print(tile_def["prompt"][:200] + "...")
        print(f"\nTotal: {len(selected)} tiles, ~${len(selected) * 0.04:.2f} estimated")
        return

    all_results = {}
    for phase_num in sorted(phases_to_run):
        phase_tiles = {k: v for k, v in selected.items() if v["phase"] == phase_num}
        if not phase_tiles:
            continue

        phase_names = {
            1: "Anchor (floor, wall)",
            2: "Interactive (doors — programmatic)",
            3: "Navigation (stairs — recolor)",
            4: "Environmental (DALL-E + procedural)",
            5: "Hazard / Special (procedural)",
        }
        print(f"\n{'=' * 60}")
        print(f"PHASE {phase_num}: {phase_names.get(phase_num, 'Unknown')}")
        print(f"Tiles: {', '.join(phase_tiles.keys())}")
        print(f"{'=' * 60}")

        results = run_phase(phase_num, phase_tiles, max_attempts=args.attempts)
        all_results.update(results)

        if phase_num < max(phases_to_run):
            print(f"\n  Phase {phase_num} complete. Pausing 2s...")
            time.sleep(2)

    print(f"\n{'=' * 60}")
    print("GENERATION COMPLETE")
    print(f"{'=' * 60}")
    print(f"Generated: {len(all_results)}/{len(selected)} tiles")
    print(f"Estimated cost: ~${len(all_results) * 0.04:.2f}")
    failed = [k for k in selected if k not in all_results]
    if failed:
        print(f"FAILED: {', '.join(failed)}")


if __name__ == "__main__":
    main()
