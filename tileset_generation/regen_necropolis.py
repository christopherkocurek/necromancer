#!/usr/bin/env python3
"""
Necropolis (Layer 4) Tile Generation — Ancient Ossuary

Generates tiles for F10-F12 with creative direction:
  Ancient ossuary carved from rough limestone. Walls faced with bones,
  burial niches broken open from within, cold spectral light seeping
  from empty eye sockets.

Palette: dusty limestone grey (#3d3a2e), aged bone ivory (#c8b89d),
         cold cyan (#4a7f8f), decay brown (#6b5a42),
         spectral mist blue (#9db4c8).

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
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "necropolis"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "necropolis"
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
# SHARED PREAMBLE — Ancient Ossuary
# ============================================================================

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Ancient undead crypt illustration. "
    "Palette: dusty limestone-grey stone, aged ivory bone, cold blue-grey mist. "
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
            "Rough-cut dusty limestone flagstones in an irregular pattern. "
            "Weathered grey-brown stone with hairline cracks and worn edges. "
            "Aged ivory bone fragments embedded in the mortar joints between stones, "
            "small knuckle bones and teeth visible in the grout. "
            "Fine brown dust coats the surface, settled over centuries. "
            "Seamless tileable crypt floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Rough dusty limestone blocks in masonry rows, weathered grey-brown stone. "
            "Human skulls and long bones mortared into the wall face, creating an ossuary wall. "
            "The aged ivory bones are embedded flush with the stone surface. "
            "Cold blue-grey mist leaks from empty eye sockets and between stone joints. "
            "Seamless tileable crypt ossuary wall texture."
        ),
    },

    # ---- Phase 4: Environmental (DALL-E based) ----
    "sealed_sarcophagus": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Dusty limestone floor with a large stone sarcophagus in the center. "
            "The rectangular tomb is carved from aged grey-brown limestone. "
            "A heavy stone lid rests slightly ajar, revealing dark void within. "
            "Bone ivory decorative border carved around the lid edges. "
            "Fine brown dust and bone chips scattered around the base. "
            "Seamless tileable stone tomb on crypt floor texture."
        ),
    },
    "carved_epitaph": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Rough dusty limestone wall with deeply incised angular rune inscriptions. "
            "The carved letters are sharp and angular, filled with dark shadow. "
            "Aged ivory bone fragments mortared around the inscription border. "
            "The stone surface is weathered and dusty with brown patina. "
            "Seamless tileable inscribed crypt wall texture."
        ),
    },
}

# ============================================================================
# TILESET PASTE COORDINATES — Row 21, Cols 12-23
# ============================================================================

PASTE_MAP = {
    'wall':        [(12, 21), (13, 21)],
    'floor':       [(14, 21), (15, 21)],
    'door_closed': [(16, 21), (17, 21)],
    'door_open':   [(18, 21), (19, 21)],
    'stairs_down': [(20, 21), (21, 21)],
    'stairs_up':   [(22, 21), (23, 21)],
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
    """Recolor outer_pits stairs to necropolis cold cyan palette."""
    src = np.array(Image.open(src_path).convert("RGBA")).astype(np.float64)
    result = src.copy()

    r, g, b = result[:,:,0], result[:,:,1], result[:,:,2]

    # 1. Remove green tones — shift toward grey-brown
    green_dominant = (g > r * 1.05) & (g > 40)
    grey_target = (r + b) / 2
    result[:,:,1] = np.where(green_dominant, g * 0.35 + grey_target * 0.65, g)

    # 2. Darken moderately (limestone is lighter than obsidian)
    result[:,:,:3] *= 0.75

    # 3. Cold cyan-blue shift — boost blue strongly, reduce red
    result[:,:,2] = np.minimum(result[:,:,2] * 1.35, 255)  # blue up strongly
    result[:,:,0] *= 0.80  # red down
    result[:,:,1] *= 0.88  # green down

    # 4. Dusty desaturation on mid-tones — shift toward brown
    lum = np.mean(result[:,:,:3], axis=2)
    mid_tone = (lum > 25) & (lum < 100)
    gray_mid = lum[:,:,None] if lum.ndim == 2 else lum
    # Desaturate mid-tones 30%
    for c in range(3):
        channel = result[:,:,c]
        desaturated = channel * 0.7 + lum * 0.3
        result[:,:,c] = np.where(mid_tone, desaturated, channel)

    # 5. For stairs_up: cold cyan light on bright areas
    if direction == "up":
        bright = lum > 70
        result[:,:,2] = np.where(bright, np.minimum(result[:,:,2] * 1.2, 255), result[:,:,2])
        result[:,:,0] = np.where(bright, result[:,:,0] * 0.9, result[:,:,0])

    # 6. Edge darkening
    h, w = result.shape[:2]
    y_dist = np.minimum(np.arange(h)[:, None], np.arange(h-1, -1, -1)[:, None])
    x_dist = np.minimum(np.arange(w)[None, :], np.arange(w-1, -1, -1)[None, :])
    edge_dist = np.minimum(y_dist, x_dist).astype(np.float64)
    edge_darken = np.clip(1.0 - (edge_dist / 200) * 0.10, 0.90, 1.0)
    result[:,:,0] *= edge_darken
    result[:,:,1] *= edge_darken
    result[:,:,2] *= edge_darken

    return Image.fromarray(result.clip(0, 255).astype(np.uint8))


# ============================================================================
# PROGRAMMATIC DOOR GENERATION
# ============================================================================

def generate_door_closed(wall_1024: Image.Image) -> Image.Image:
    """Programmatic door_closed: limestone wall + bone-inlaid frame + cyan glow."""
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size

    # Door opening — flush with bottom
    door_l, door_r = int(w * 0.20), int(w * 0.80)
    door_t, door_b = int(h * 0.10), h
    draw.rectangle([door_l, door_t, door_r, door_b], fill=(20, 18, 15, 255))

    # Door surface — dark aged wood
    inner_margin = 20
    dl = door_l + inner_margin
    dr = door_r - inner_margin
    dt = door_t + inner_margin
    db = door_b
    draw.rectangle([dl, dt, dr, db], fill=(45, 38, 30, 255))

    # Vertical wood grain lines
    for x_off in range(dl + 30, dr, 60):
        draw.line([(x_off, dt), (x_off, db)], fill=(38, 32, 25, 255), width=3)

    # Bone-inlaid frame — aged ivory border
    frame_w = 35
    bone_color = (200, 184, 157, 255)
    bone_shadow = (160, 145, 125, 255)
    # Top frame
    draw.rectangle([door_l, door_t, door_r, door_t + frame_w], fill=bone_color)
    draw.rectangle([door_l + 5, door_t + 5, door_r - 5, door_t + frame_w - 5], fill=bone_shadow)
    # Left frame
    draw.rectangle([door_l, door_t, door_l + frame_w, door_b], fill=bone_color)
    draw.rectangle([door_l + 5, door_t + 5, door_l + frame_w - 5, door_b], fill=bone_shadow)
    # Right frame
    draw.rectangle([door_r - frame_w, door_t, door_r, door_b], fill=bone_color)
    draw.rectangle([door_r - frame_w + 5, door_t + 5, door_r - 5, door_b], fill=bone_shadow)

    # Skull at top center of frame
    scx, scy = w // 2, door_t + frame_w // 2
    skull_r = 16
    draw.ellipse([scx-skull_r, scy-skull_r, scx+skull_r, scy+skull_r], fill=(190, 175, 150, 255))
    # Eye sockets with cyan glow
    for ex in [-7, 7]:
        draw.ellipse([scx+ex-4, scy-4, scx+ex+4, scy+4], fill=(74, 127, 143, 200))

    # Iron crossbands — 2 horizontal bands
    band_h = 16
    iron_color = (50, 48, 42, 255)
    for y_frac in [0.35, 0.65]:
        by = int(door_t + (door_b - door_t) * y_frac - band_h // 2)
        draw.rectangle([dl, by, dr, by + band_h], fill=iron_color)
        for rx in range(dl + 50, dr, 90):
            draw.ellipse([rx-6, by+2, rx+6, by+band_h-2], fill=(65, 60, 52, 255))

    # Faint cyan glow from under the door
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    gcx = w // 2
    glow_draw.ellipse([gcx-150, h-100, gcx+150, h+40], fill=(40, 100, 120, 30))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=25))
    img = Image.alpha_composite(img, glow_layer)

    return img


def generate_door_open(wall_1024: Image.Image) -> Image.Image:
    """Programmatic door_open: limestone wall + open doorway + cyan glow."""
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size

    # Door opening — flush with bottom
    door_l, door_r = int(w * 0.20), int(w * 0.80)
    door_t, door_b = int(h * 0.10), h
    draw.rectangle([door_l, door_t, door_r, door_b], fill=(10, 10, 12, 255))

    # Bone-inlaid frame (no bottom bar)
    frame_w = 35
    bone_color = (200, 184, 157, 255)
    bone_shadow = (160, 145, 125, 255)
    draw.rectangle([door_l, door_t, door_r, door_t + frame_w], fill=bone_color)
    draw.rectangle([door_l + 5, door_t + 5, door_r - 5, door_t + frame_w - 5], fill=bone_shadow)
    draw.rectangle([door_l, door_t, door_l + frame_w, door_b], fill=bone_color)
    draw.rectangle([door_l + 5, door_t + 5, door_l + frame_w - 5, door_b], fill=bone_shadow)
    draw.rectangle([door_r - frame_w, door_t, door_r, door_b], fill=bone_color)
    draw.rectangle([door_r - frame_w + 5, door_t + 5, door_r - 5, door_b], fill=bone_shadow)

    # Skull at top center
    scx, scy = w // 2, door_t + frame_w // 2
    skull_r = 16
    draw.ellipse([scx-skull_r, scy-skull_r, scx+skull_r, scy+skull_r], fill=(190, 175, 150, 255))
    for ex in [-7, 7]:
        draw.ellipse([scx+ex-4, scy-4, scx+ex+4, scy+4], fill=(74, 127, 143, 200))

    # Door panel swung open (right side)
    panel_w = 55
    draw.rectangle([door_r - frame_w - panel_w, door_t + frame_w,
                     door_r - frame_w, door_b],
                    fill=(45, 38, 30, 255))

    # Cyan glow from open doorway
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    gcx, gcy = w // 2, h // 2
    glow_draw.ellipse([gcx-180, gcy-120, gcx+180, gcy+120], fill=(35, 90, 110, 30))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=30))
    img = Image.alpha_composite(img, glow_layer)

    return img


# ============================================================================
# PROCEDURAL ENVIRONMENTAL TILES
# ============================================================================

def generate_bone_dust(floor_64: Image.Image) -> Image.Image:
    """Procedural bone dust on floor — brown-ivory dust overlay."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]

    rng = np.random.RandomState(101)
    # Irregular dust patches
    mask = np.zeros((h, w), dtype=np.float64)
    for _ in range(8):
        ox = rng.randint(10, w-10)
        oy = rng.randint(10, h-10)
        rx = rng.randint(10, 22)
        ry = rng.randint(10, 22)
        yy, xx = np.ogrid[:h, :w]
        ellipse = ((xx - ox) / rx) ** 2 + ((yy - oy) / ry) ** 2
        mask = np.maximum(mask, np.clip(1.0 - ellipse, 0, 1))

    mask = gaussian_filter(mask, sigma=3)
    mask = np.clip(mask, 0, 1)

    # Dust color: warm ivory-brown
    dust_color = np.array([180, 165, 135])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask * 0.5) + dust_color[c] * mask * 0.5

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_grave_miasma(floor_64: Image.Image) -> Image.Image:
    """Procedural grave miasma — cold cyan mist pooling on floor with glow."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]

    rng = np.random.RandomState(202)
    mask = np.zeros((h, w), dtype=np.float64)
    cx, cy = w // 2, h // 2

    for _ in range(7):
        ox = cx + rng.randint(-10, 11)
        oy = cy + rng.randint(-10, 11)
        rx = rng.randint(12, 22)
        ry = rng.randint(12, 22)
        yy, xx = np.ogrid[:h, :w]
        ellipse = ((xx - ox) / rx) ** 2 + ((yy - oy) / ry) ** 2
        mask = np.maximum(mask, np.clip(1.0 - ellipse, 0, 1))

    mask = gaussian_filter(mask, sigma=4)
    mask = np.clip(mask, 0, 1)

    # Cyan mist color
    mist_color = np.array([74, 127, 143])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask * 0.6) + mist_color[c] * mask * 0.6

    # Bright cyan glow in center
    glow_mask = gaussian_filter(mask, sigma=2) * mask
    glow_mask = np.clip(glow_mask * 1.5 - 0.2, 0, 1)
    glow_color = np.array([100, 180, 200])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] + glow_color[c] * glow_mask * 0.2

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_burial_urn(floor_64: Image.Image) -> Image.Image:
    """Procedural burial urn trap — clay urn shape on floor."""
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)

    cx, cy = 32, 30
    # Urn body — clay brown ellipse
    urn_color = (140, 100, 65, 220)
    draw.ellipse([cx-10, cy-6, cx+10, cy+10], fill=urn_color)
    # Urn neck
    draw.rectangle([cx-5, cy-10, cx+5, cy-5], fill=(130, 92, 58, 220))
    # Urn rim
    draw.ellipse([cx-7, cy-12, cx+7, cy-8], fill=(150, 110, 72, 220))
    # Shadow underneath
    draw.ellipse([cx-11, cy+8, cx+11, cy+14], fill=(30, 28, 22, 100))
    # Highlight
    draw.arc([cx-6, cy-4, cx+2, cy+6], 200, 340, fill=(170, 130, 90, 180), width=1)

    return img


def generate_grave_offerings(floor_64: Image.Image) -> Image.Image:
    """Procedural grave offerings — scattered coins, pottery shards on floor."""
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)

    rng = np.random.RandomState(303)

    # Scattered coins (small yellow-brown circles)
    for _ in range(8):
        x = rng.randint(8, 56)
        y = rng.randint(8, 56)
        r = rng.randint(1, 3)
        brightness = rng.randint(140, 190)
        color = (brightness, int(brightness * 0.8), int(brightness * 0.5), 200)
        draw.ellipse([x-r, y-r, x+r, y+r], fill=color)

    # Pottery shards (small irregular brown shapes)
    for _ in range(5):
        x = rng.randint(10, 54)
        y = rng.randint(10, 54)
        points = []
        for _ in range(4):
            px = x + rng.randint(-3, 4)
            py = y + rng.randint(-3, 4)
            points.append((px, py))
        r_off = rng.randint(-20, 10)
        color = (110 + r_off, 75 + r_off, 50 + r_off, 180)
        if len(points) >= 3:
            draw.polygon(points, fill=color)

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
    edge_pixels = np.concatenate([
        arr[:10, :, :].reshape(-1, 3),
        arr[-10:, :, :].reshape(-1, 3),
        arr[:, :10, :].reshape(-1, 3),
        arr[:, -10:, :].reshape(-1, 3),
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
    parser = argparse.ArgumentParser(description="Generate Necropolis layer tiles")
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
    print("NECROPOLIS TILE GENERATION")
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
            "bone_dust": generate_bone_dust,
            "grave_miasma": generate_grave_miasma,
            "burial_urn": generate_burial_urn,
            "grave_offerings": generate_grave_offerings,
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
            4: "Environmental (DALL-E + procedural)",
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
