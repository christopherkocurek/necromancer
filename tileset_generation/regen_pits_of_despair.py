#!/usr/bin/env python3
"""
Pits of Despair (Layer 5) Tile Generation — Volcanic Forge-Prison

Generates tiles for F13-F15 with creative direction:
  Volcanic forge-prison where scorched basalt cracks reveal ember-orange
  heat from below. Sauron's active torture chambers in geothermal rock.

Palette: scorched basalt (#2A1F1A), volcanic ash grey (#4A4240),
         ember orange (#C85A3A), dried blood red (#5c1a1a),
         soot black (#120D0B).
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
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "pits_of_despair"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "pits_of_despair"
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
OUTER_PITS_RAW = SCRIPT_DIR / "layer_tiles" / "raw" / "outer_pits_v2"

RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================================
# DALL-E CLIENT
# ============================================================================

load_dotenv(SCRIPT_DIR / ".env")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ============================================================================
# SHARED PREAMBLE
# ============================================================================

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Scorched volcanic dungeon illustration. "
    "Palette: scorched black-brown basalt, volcanic ash grey, ember orange cracks. "
    "Fills the entire frame edge to edge. No text. "
)

# ============================================================================
# TILE DEFINITIONS
# ============================================================================

TILES = {
    "floor": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Cracked scorched basalt flagstones in an irregular pattern. "
            "Dark black-brown volcanic stone with rough pitted surface. "
            "Thick ember-orange veins glow in the deep cracks between flagstones, "
            "suggesting intense heat from far below the surface. "
            "Volcanic ash dust gathers in shallow depressions. "
            "Seamless tileable scorched volcanic floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Massive scorched basalt blocks in rough masonry rows. "
            "Dark black-brown volcanic stone with pitted glassy surface. "
            "Deep vertical fissures crack through the wall, "
            "glowing ember-orange from magma pressure behind the stone. "
            "Heavy black iron chain links bolted across one fissure. "
            "Seamless tileable scorched volcanic wall texture."
        ),
    },

    "iron_maiden": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Scorched basalt floor with a standing iron torture device in the center. "
            "A tall black iron shell with visible spikes inside, hinged open slightly. "
            "Dried dark red-brown stains on the iron and surrounding stone. "
            "Heavy iron chains anchor the device to the volcanic stone floor. "
            "Seamless tileable iron torture device on scorched floor texture."
        ),
    },
    "shadow_tapestry": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Scorched basalt wall with a tattered black fabric hanging. "
            "The dark cloth is shredded and burned at the edges. "
            "Faded dark red symbols barely visible on the black fabric. "
            "Heavy iron nails pin the tapestry to the volcanic stone wall. "
            "Seamless tileable tattered tapestry on scorched wall texture."
        ),
    },
}

# ============================================================================
# TILESET PASTE COORDINATES — Row 22, Cols 0-11
# ============================================================================

PASTE_MAP = {
    'wall':        [(0, 22), (1, 22)],
    'floor':       [(2, 22), (3, 22)],
    'door_closed': [(4, 22), (5, 22)],
    'door_open':   [(6, 22), (7, 22)],
    'stairs_down': [(8, 22), (9, 22)],
    'stairs_up':   [(10, 22), (11, 22)],
}

# ============================================================================
# DARK VARIANT
# ============================================================================

def make_dark_variant(light_img: Image.Image) -> Image.Image:
    arr = np.array(light_img).astype(np.float64)
    gray = np.mean(arr[:, :, :3], axis=2, keepdims=True)
    arr[:, :, :3] = arr[:, :, :3] * 0.4 + gray * 0.6
    arr[:, :, :3] *= 0.6
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


# ============================================================================
# STAIRS RECOLOR
# ============================================================================

def recolor_stairs(src_path: Path, direction: str) -> Image.Image:
    """Recolor outer_pits stairs to volcanic ember palette."""
    src = np.array(Image.open(src_path).convert("RGBA")).astype(np.float64)
    result = src.copy()

    r, g, b = result[:,:,0], result[:,:,1], result[:,:,2]

    # 1. Remove green — shift to warm grey-brown
    green_dominant = (g > r * 1.05) & (g > 40)
    grey_target = (r + b) / 2
    result[:,:,1] = np.where(green_dominant, g * 0.3 + grey_target * 0.7, g)

    # 2. Darken significantly
    result[:,:,:3] *= 0.70

    # 3. Warm shift — boost red, reduce blue (opposite of necropolis)
    result[:,:,0] = np.minimum(result[:,:,0] * 1.30, 255)  # red up
    result[:,:,1] *= 0.85  # green down
    result[:,:,2] *= 0.70  # blue down strongly

    # 4. Add ember-orange tint to bright areas
    lum = np.mean(result[:,:,:3], axis=2)
    bright = lum > 60
    result[:,:,0] = np.where(bright, np.minimum(result[:,:,0] * 1.15, 255), result[:,:,0])
    result[:,:,1] = np.where(bright, result[:,:,1] * 0.90, result[:,:,1])

    # 5. For stairs_up: warm ember light from above
    if direction == "up":
        very_bright = lum > 80
        result[:,:,0] = np.where(very_bright, np.minimum(result[:,:,0] * 1.2, 255), result[:,:,0])
        result[:,:,1] = np.where(very_bright, np.minimum(result[:,:,1] * 1.05, 255), result[:,:,1])

    # 6. Edge darkening
    h, w = result.shape[:2]
    y_dist = np.minimum(np.arange(h)[:, None], np.arange(h-1, -1, -1)[:, None])
    x_dist = np.minimum(np.arange(w)[None, :], np.arange(w-1, -1, -1)[None, :])
    edge_dist = np.minimum(y_dist, x_dist).astype(np.float64)
    edge_darken = np.clip(1.0 - (edge_dist / 200) * 0.15, 0.85, 1.0)
    result[:,:,0] *= edge_darken
    result[:,:,1] *= edge_darken
    result[:,:,2] *= edge_darken

    return Image.fromarray(result.clip(0, 255).astype(np.uint8))


# ============================================================================
# PROGRAMMATIC DOORS
# ============================================================================

def generate_door_closed(wall_1024: Image.Image) -> Image.Image:
    """Scorched iron door with ember glow underneath."""
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size

    door_l, door_r = int(w * 0.20), int(w * 0.80)
    door_t, door_b = int(h * 0.10), h
    draw.rectangle([door_l, door_t, door_r, door_b], fill=(18, 13, 10, 255))

    # Door surface — scorched black iron
    inner_margin = 20
    dl, dr = door_l + inner_margin, door_r - inner_margin
    dt, db = door_t + inner_margin, door_b
    draw.rectangle([dl, dt, dr, db], fill=(35, 25, 20, 255))

    # Vertical iron plate lines
    for x_off in range(dl + 40, dr, 70):
        draw.line([(x_off, dt), (x_off, db)], fill=(28, 20, 16, 255), width=4)

    # Heavy iron frame — dark with rust highlights
    frame_w = 38
    iron_color = (45, 35, 28, 255)
    rust_color = (92, 26, 26, 255)
    draw.rectangle([door_l, door_t, door_r, door_t + frame_w], fill=iron_color)
    draw.rectangle([door_l, door_t, door_l + frame_w, door_b], fill=iron_color)
    draw.rectangle([door_r - frame_w, door_t, door_r, door_b], fill=iron_color)

    # Rust streaks on frame
    for y in range(door_t + 10, door_b, 120):
        draw.rectangle([door_l + 8, y, door_l + frame_w - 8, y + 30], fill=rust_color)
        draw.rectangle([door_r - frame_w + 8, y, door_r - 8, y + 30], fill=rust_color)

    # Heavy iron crossbands with large rivets
    band_h = 22
    for y_frac in [0.30, 0.55, 0.80]:
        by = int(door_t + (door_b - door_t) * y_frac - band_h // 2)
        draw.rectangle([dl, by, dr, by + band_h], fill=iron_color)
        for rx in range(dl + 35, dr, 70):
            draw.ellipse([rx-9, by+2, rx+9, by+band_h-2], fill=(60, 45, 35, 255))

    # Ember glow from cracks around door
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    # Glow along left and right frame edges
    glow_draw.rectangle([door_l-15, door_t, door_l+5, door_b], fill=(200, 90, 58, 25))
    glow_draw.rectangle([door_r-5, door_t, door_r+15, door_b], fill=(200, 90, 58, 25))
    # Glow from under door
    gcx = w // 2
    glow_draw.ellipse([gcx-160, h-80, gcx+160, h+50], fill=(200, 90, 58, 30))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=20))
    img = Image.alpha_composite(img, glow_layer)

    return img


def generate_door_open(wall_1024: Image.Image) -> Image.Image:
    """Scorched iron door open — ember glow from beyond."""
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size

    door_l, door_r = int(w * 0.20), int(w * 0.80)
    door_t, door_b = int(h * 0.10), h
    draw.rectangle([door_l, door_t, door_r, door_b], fill=(12, 8, 6, 255))

    # Heavy iron frame
    frame_w = 38
    iron_color = (45, 35, 28, 255)
    rust_color = (92, 26, 26, 255)
    draw.rectangle([door_l, door_t, door_r, door_t + frame_w], fill=iron_color)
    draw.rectangle([door_l, door_t, door_l + frame_w, door_b], fill=iron_color)
    draw.rectangle([door_r - frame_w, door_t, door_r, door_b], fill=iron_color)

    # Rust streaks
    for y in range(door_t + 10, door_b, 120):
        draw.rectangle([door_l + 8, y, door_l + frame_w - 8, y + 30], fill=rust_color)
        draw.rectangle([door_r - frame_w + 8, y, door_r - 8, y + 30], fill=rust_color)

    # Door panel swung open
    panel_w = 55
    draw.rectangle([door_r - frame_w - panel_w, door_t + frame_w,
                     door_r - frame_w, door_b], fill=(35, 25, 20, 255))

    # Strong ember glow from open doorway
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    gcx, gcy = w // 2, int(h * 0.55)
    glow_draw.ellipse([gcx-200, gcy-150, gcx+200, gcy+150], fill=(200, 90, 58, 40))
    glow_draw.ellipse([gcx-100, gcy-80, gcx+100, gcy+80], fill=(230, 130, 70, 25))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=30))
    img = Image.alpha_composite(img, glow_layer)

    return img


# ============================================================================
# PROCEDURAL ENVIRONMENTAL TILES
# ============================================================================

def generate_bloodstained_floor(floor_64: Image.Image) -> Image.Image:
    """Procedural bloodstained floor — dried dark red stains."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    rng = np.random.RandomState(501)

    mask = np.zeros((h, w), dtype=np.float64)
    for _ in range(6):
        ox = rng.randint(12, w-12)
        oy = rng.randint(12, h-12)
        rx, ry = rng.randint(8, 18), rng.randint(8, 18)
        yy, xx = np.ogrid[:h, :w]
        ellipse = ((xx - ox) / rx) ** 2 + ((yy - oy) / ry) ** 2
        mask = np.maximum(mask, np.clip(1.0 - ellipse, 0, 1))

    mask = gaussian_filter(mask, sigma=3)
    mask = np.clip(mask, 0, 1)

    blood_color = np.array([92, 26, 26])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask * 0.65) + blood_color[c] * mask * 0.65

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_smoldering_grate(floor_64: Image.Image) -> Image.Image:
    """Procedural smoldering grate — ember glow grid on floor."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]

    # Iron grate grid
    grate = np.zeros((h, w), dtype=np.float64)
    iron_color = np.array([45, 35, 28])
    for x in range(8, w, 12):
        grate[:, max(0,x-1):min(w,x+2)] = 1.0
    for y in range(8, h, 12):
        grate[max(0,y-1):min(h,y+2), :] = 1.0

    # Apply iron bars
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - grate * 0.7) + iron_color[c] * grate * 0.7

    # Ember glow in the gaps
    ember_mask = 1.0 - grate
    ember_mask = gaussian_filter(ember_mask, sigma=2)
    ember_color = np.array([200, 90, 58])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - ember_mask * 0.4) + ember_color[c] * ember_mask * 0.4

    # Bright center glow
    cy, cx = h//2, w//2
    yy, xx = np.ogrid[:h, :w]
    center = np.exp(-((xx-cx)**2 + (yy-cy)**2) / (2 * 15**2))
    bright_color = np.array([230, 130, 70])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] + bright_color[c] * center * 0.2

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_blood_pool_trap(floor_64: Image.Image) -> Image.Image:
    """Procedural blood pool trap — dark crimson pool on floor."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    rng = np.random.RandomState(502)

    mask = np.zeros((h, w), dtype=np.float64)
    cx, cy = w // 2, h // 2
    for _ in range(5):
        ox = cx + rng.randint(-6, 7)
        oy = cy + rng.randint(-6, 7)
        rx, ry = rng.randint(12, 20), rng.randint(12, 20)
        yy, xx = np.ogrid[:h, :w]
        ellipse = ((xx - ox) / rx) ** 2 + ((yy - oy) / ry) ** 2
        mask = np.maximum(mask, np.clip(1.0 - ellipse, 0, 1))

    mask = gaussian_filter(mask, sigma=3)
    mask = np.clip(mask, 0, 1)

    # Deep dark blood
    blood_dark = np.array([60, 12, 12])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask * 0.75) + blood_dark[c] * mask * 0.75

    # Wet highlight in center
    highlight_mask = gaussian_filter(mask, sigma=2) * mask
    highlight_mask = np.clip(highlight_mask * 1.8 - 0.4, 0, 1)
    highlight = np.array([100, 25, 25])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] + highlight[c] * highlight_mask * 0.2

    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


def generate_scattered_bones(floor_64: Image.Image) -> Image.Image:
    """Procedural fresh scattered bones on floor."""
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)
    rng = np.random.RandomState(503)

    bone_color = (200, 185, 160)
    for _ in range(14):
        x, y = rng.randint(6, 58), rng.randint(6, 58)
        length = rng.randint(3, 9)
        angle = rng.uniform(0, 3.14159)
        dx = int(length * np.cos(angle))
        dy = int(length * np.sin(angle))
        r_off = rng.randint(-20, 10)
        color = tuple(max(0, min(255, c + r_off)) for c in bone_color) + (230,)
        draw.line([(x, y), (x + dx, y + dy)], fill=color, width=2)

    # Blood stains near some bones
    for _ in range(3):
        x, y = rng.randint(10, 54), rng.randint(10, 54)
        r = rng.randint(2, 5)
        draw.ellipse([x-r, y-r, x+r, y+r], fill=(80, 20, 15, 120))

    return img


# ============================================================================
# GENERATION HELPERS
# ============================================================================

def generate_tile(name, tile_def, attempt=1):
    print(f"  [{name}] Generating (attempt {attempt})...")
    try:
        response = client.images.generate(
            model="dall-e-3", prompt=tile_def["prompt"],
            size="1024x1024", quality="standard", style="natural",
            n=1, response_format="b64_json",
        )
        img_data = base64.b64decode(response.data[0].b64_json)
        return Image.open(io.BytesIO(img_data)).convert("RGBA")
    except Exception as e:
        print(f"  [{name}] FAILED: {e}")
        return None

def check_edge_brightness(img, threshold=180):
    arr = np.array(img)[:,:,:3]
    edges = np.concatenate([arr[:10,:,:].reshape(-1,3), arr[-10:,:,:].reshape(-1,3),
                            arr[:,:10,:].reshape(-1,3), arr[:,-10:,:].reshape(-1,3)])
    mean = edges.mean()
    print(f"  Edge brightness: {mean:.1f} (threshold: {threshold})")
    return mean > threshold

def process_tile(name, img_1024):
    light_64 = img_1024.resize((64, 64), Image.LANCZOS)
    return light_64, make_dark_variant(light_64)

def run_phase(phase_num, tiles_in_phase, max_attempts=3):
    results = {}
    for name, tile_def in tiles_in_phase.items():
        for attempt in range(1, max_attempts + 1):
            img = generate_tile(name, tile_def, attempt)
            if img and not check_edge_brightness(img):
                raw_path = RAW_DIR / f"{name}_1024.png"
                img.save(raw_path)
                light, dark = process_tile(name, img)
                light.save(PROCESSED_DIR / f"{name}_light.png")
                dark.save(PROCESSED_DIR / f"{name}_dark.png")
                results[name] = {"img_1024": img, "light_64": light, "dark_64": dark}
                print(f"  [{name}] Saved light + dark")
                break
            elif img:
                print(f"  [{name}] White edge, re-rolling...")
                time.sleep(2)
            else:
                time.sleep(3)
        else:
            print(f"  [{name}] FAILED after {max_attempts} attempts!")
    return results


def main():
    parser = argparse.ArgumentParser(description="Generate Pits of Despair tiles")
    parser.add_argument("--phase", type=int, choices=[1, 4])
    parser.add_argument("--tile", type=str)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--attempts", type=int, default=3)
    parser.add_argument("--stairs", action="store_true")
    parser.add_argument("--doors", action="store_true")
    parser.add_argument("--env", action="store_true")
    args = parser.parse_args()

    print("=" * 60)
    print("PITS OF DESPAIR TILE GENERATION")
    print("=" * 60)

    if args.stairs:
        print("\n--- Recoloring stairs (ember palette) ---")
        for d in ["down", "up"]:
            src = OUTER_PITS_RAW / f"stairs_{d}_1024.png"
            if not src.exists():
                print(f"  MISSING: {src}"); continue
            img = recolor_stairs(src, d)
            img.save(RAW_DIR / f"stairs_{d}_1024.png")
            l, dk = process_tile(f"stairs_{d}", img)
            l.save(PROCESSED_DIR / f"stairs_{d}_light.png")
            dk.save(PROCESSED_DIR / f"stairs_{d}_dark.png")
            print(f"  stairs_{d}: saved")
        return

    if args.doors:
        print("\n--- Generating programmatic doors ---")
        wall_raw = RAW_DIR / "wall_1024.png"
        if not wall_raw.exists():
            print("  MISSING wall — generate phase 1 first"); return
        wall = Image.open(wall_raw).convert("RGBA")
        for name, func in [("door_closed", generate_door_closed), ("door_open", generate_door_open)]:
            img = func(wall)
            img.save(RAW_DIR / f"{name}_1024.png")
            l, dk = process_tile(name, img)
            l.save(PROCESSED_DIR / f"{name}_light.png")
            dk.save(PROCESSED_DIR / f"{name}_dark.png")
            print(f"  {name}: saved")
        return

    if args.env:
        print("\n--- Generating procedural env tiles ---")
        fl = PROCESSED_DIR / "floor_light.png"
        if not fl.exists():
            print("  MISSING floor — generate phase 1 first"); return
        floor = Image.open(fl).convert("RGBA")
        for name, func in [("bloodstained_floor", generate_bloodstained_floor),
                            ("smoldering_grate", generate_smoldering_grate),
                            ("blood_pool_trap", generate_blood_pool_trap),
                            ("scattered_bones", generate_scattered_bones)]:
            l = func(floor)
            dk = make_dark_variant(l)
            l.save(PROCESSED_DIR / f"{name}_light.png")
            dk.save(PROCESSED_DIR / f"{name}_dark.png")
            print(f"  {name}: saved")
        return

    # Standard phase mode
    if args.tile:
        selected = {args.tile: TILES[args.tile]}
        phases = [TILES[args.tile]["phase"]]
    elif args.phase:
        selected = {k: v for k, v in TILES.items() if v["phase"] == args.phase}
        phases = [args.phase]
    else:
        selected = TILES
        phases = sorted(set(v["phase"] for v in TILES.values()))

    if args.dry_run:
        for n, td in selected.items():
            print(f"\n--- {n} (Phase {td['phase']}) ---")
            print(f"Prompt ({len(td['prompt'])} chars): {td['prompt'][:200]}...")
        print(f"\nTotal: {len(selected)} tiles, ~${len(selected) * 0.04:.2f}")
        return

    for p in sorted(phases):
        pt = {k: v for k, v in selected.items() if v["phase"] == p}
        if not pt: continue
        print(f"\n{'='*60}\nPHASE {p}: {', '.join(pt.keys())}\n{'='*60}")
        run_phase(p, pt, args.attempts)

    print(f"\n{'='*60}\nGENERATION COMPLETE\n{'='*60}")


if __name__ == "__main__":
    main()
