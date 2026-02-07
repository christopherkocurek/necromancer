#!/usr/bin/env python3
"""
regen_items_v2.py — DALL-E regeneration for 24 unsalvageable item sprites.

These tiles have backgrounds inseparable from subjects, processing failures,
or green-on-green issues that cannot be fixed with BG removal.

Uses black void background prompts for clean separation.
Cost: ~$0.96 (24 images × $0.04/image)

Usage:
    python3 regen_items_v2.py                # Generate all 24
    python3 regen_items_v2.py --target R1    # Single target
    python3 regen_items_v2.py --skip-api     # Skip DALL-E, only process+integrate
    python3 regen_items_v2.py --dry-run      # Show plan, no API calls or file writes
"""

import os
import sys
import json
import time
import base64
import argparse
import io
from pathlib import Path
from datetime import datetime
from collections import deque

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter, ImageEnhance
    import numpy as np
    from scipy.ndimage import distance_transform_edt, label
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install: pip3 install openai pillow python-dotenv numpy scipy")
    sys.exit(1)

# === Paths ===
BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
RAW_DIR = BASE_DIR / "regen_v2" / "raw"
PROCESSED_DIR = BASE_DIR / "regen_v2" / "processed"
PROGRESS_FILE = BASE_DIR / "regen_v2_progress.json"

TILE_SIZE = 64
COST_PER_IMAGE = 0.04
RATE_LIMIT_DELAY = 2.5
MAX_RETRIES = 3

# === 24 Regeneration Targets ===
# Key format: R{n} for sequential numbering
# Each has: name, item_id, tileset_pos (col, row), prompt, category

TARGETS = {
    "R1": {
        "name": "Ring",
        "item_id": 2,
        "tileset_pos": (2, 11),
        "category": "ring",
        "prompt": (
            "A single ornate golden ring with a small inset gemstone, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration style. "
            "No surface, no shadow, no frame, no other objects. "
            "Strong readable silhouette. Clean illustrative painting style."
        ),
    },
    "R2": {
        "name": "Amulet",
        "item_id": 3,
        "tileset_pos": (3, 11),
        "category": "amulet",
        "prompt": (
            "A single ornate silver amulet pendant on a thin chain, "
            "with a dark blue gem in an intricate bezel setting, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R3": {
        "name": "Pearl",
        "item_id": 4,
        "tileset_pos": (4, 11),
        "category": "amulet",
        "prompt": (
            "A single lustrous white pearl pendant on a delicate silver chain, "
            "iridescent surface catching dim light, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R4": {
        "name": "Jewel",
        "item_id": 5,
        "tileset_pos": (5, 11),
        "category": "amulet",
        "prompt": (
            "A single brilliant cut gemstone jewel in a gold filigree pendant setting, "
            "deep red ruby catching light, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R5": {
        "name": "Necklace",
        "item_id": 6,
        "tileset_pos": (6, 11),
        "category": "amulet",
        "prompt": (
            "A single elegant golden necklace with a teardrop emerald pendant, "
            "ornate chain links, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R6": {
        "name": "Elven Light",
        "item_id": 21,
        "tileset_pos": (9, 11),
        "category": "light",
        "prompt": (
            "A single glowing elven crystal phial emitting soft white-blue light, "
            "delicate silver filigree casing, ethereal radiance, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. Tolkien-inspired elven craftsmanship. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R7": {
        "name": "Orc Skeleton",
        "item_id": 40,
        "tileset_pos": (17, 11),
        "category": "skeleton",
        "prompt": (
            "A single small pile of ancient dark stone-colored remains, "
            "weathered fragments and pieces in a small scattered heap, "
            "archaeological remnants of an ancient warrior, dusty and worn, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. Ancient and faded. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R8": {
        "name": "Elf Skeleton",
        "item_id": 42,
        "tileset_pos": (19, 11),
        "category": "skeleton",
        "prompt": (
            "A single pile of delicate elven bones with a slender skull, "
            "fragments of ancient armor clinging to pale bones, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. Tragic and ancient. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R9": {
        "name": "Sylvan Blade",
        "item_id": 59,
        "tileset_pos": (2, 17),
        "category": "sword",
        "prompt": (
            "A single elegant elven longsword with a leaf-shaped blade, "
            "green-tinted steel with vine engravings on the blade, "
            "golden crossguard shaped like spreading branches, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy weapon illustration. Tolkien elven craftsmanship. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R10": {
        "name": "Hunting Spear",
        "item_id": 71,
        "tileset_pos": (31, 11),
        "category": "polearm",
        "prompt": (
            "A single hunting spear with a broad leaf-shaped iron head "
            "on a long wooden ash shaft, leather grip wrapping, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy weapon illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R11": {
        "name": "Constitution Amulet",
        "item_id": 133,
        "tileset_pos": (4, 13),
        "category": "amulet",
        "prompt": (
            "A single heavy bronze amulet with a deep blue sapphire gem "
            "set in an interlocking knotwork bezel, thick chain, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Dwarven craftsmanship. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R12": {
        "name": "Regeneration Amulet",
        "item_id": 135,
        "tileset_pos": (6, 13),
        "category": "amulet",
        "prompt": (
            "A single silver amulet with a pulsing green gem at center, "
            "surrounded by vine-like silver tendrils, healing magic glow, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R13": {
        "name": "Blessed Realm Amulet",
        "item_id": 137,
        "tileset_pos": (8, 13),
        "category": "amulet",
        "prompt": (
            "A single radiant mithril amulet with a white diamond gem, "
            "elven script etched around the setting, holy light emanating, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Valinor-blessed elven craft. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R14": {
        "name": "Vigilant Eye Amulet",
        "item_id": 139,
        "tileset_pos": (10, 13),
        "category": "amulet",
        "prompt": (
            "A single bronze amulet shaped like an open eye, "
            "amber iris gem in the center, watchful and alert design, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Ancient protective ward. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R15": {
        "name": "Evasion Ring",
        "item_id": 152,
        "tileset_pos": (13, 13),
        "category": "ring",
        "prompt": (
            "A single slender silver ring with fluid quicksilver design, "
            "light and nimble-looking, faintly shimmering, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Elven agility enchantment. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R16": {
        "name": "Protection Ring",
        "item_id": 153,
        "tileset_pos": (14, 13),
        "category": "ring",
        "prompt": (
            "A single thick iron ring with protective runes deeply engraved, "
            "sturdy and solid, dull metallic sheen, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Dwarven ward-crafting. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R17": {
        "name": "Strength Ring",
        "item_id": 154,
        "tileset_pos": (15, 13),
        "category": "ring",
        "prompt": (
            "A single heavy bronze ring with a bear claw motif, "
            "thick band with embossed strength runes, powerful look, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R18": {
        "name": "Warmth Ring",
        "item_id": 157,
        "tileset_pos": (18, 13),
        "category": "ring",
        "prompt": (
            "A single copper ring with a small embedded amber gem "
            "glowing with warm orange inner fire, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Dwarven fire magic. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R19": {
        "name": "Light Scroll",
        "item_id": 193,
        "tileset_pos": (27, 13),
        "category": "scroll",
        "prompt": (
            "A single rolled parchment scroll tied with a golden ribbon, "
            "ancient yellowed paper with faint glowing runes visible, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R20": {
        "name": "Understanding Scroll",
        "item_id": 196,
        "tileset_pos": (29, 13),
        "category": "scroll",
        "prompt": (
            "A single unrolled parchment scroll with dense elven script, "
            "ancient knowledge text visible, ink still crisp on aged vellum, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. Scholarly wisdom. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R21": {
        "name": "Emptiness Herb",
        "item_id": 385,
        "tileset_pos": (22, 15),
        "category": "herb",
        "prompt": (
            "A single small bunch of pale white withered herbs with dried leaves, "
            "ghostly faded plant material, hollow desiccated stems, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy botanical illustration. Ominous and lifeless. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R22": {
        "name": "Potent Orc-rage Mushroom",
        "item_id": 415,
        "tileset_pos": (7, 16),
        "category": "herb",
        "prompt": (
            "A single large red-capped mushroom with white spots, "
            "thick stem, slightly glowing with inner rage energy, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy botanical illustration. Toxic and potent. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R23": {
        "name": "Phosphorescent Moss",
        "item_id": 416,
        "tileset_pos": (8, 16),
        "category": "herb",
        "prompt": (
            "A single clump of glowing blue-green bioluminescent moss, "
            "soft ethereal glow, delicate phosphorescent tendrils, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy botanical illustration. Cave-dwelling flora. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R24": {
        "name": "Necromancer Sighting",
        "item_id": 556,
        "tileset_pos": (0, 17),
        "category": "document",
        "prompt": (
            "A single tattered parchment note with hasty handwritten text, "
            "dark ink on aged paper, torn edges, urgent intelligence report, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. War-time reconnaissance document. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    # Bonus: tiles that survived BG removal but remained over-stripped
    "R25": {
        "name": "Wooden Torch",
        "item_id": 128,
        "tileset_pos": (31, 12),
        "category": "light",
        "prompt": (
            "A single lit wooden torch with burning orange flame at the top, "
            "rough wooden handle wrapped with oiled cloth, bright fire, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy illustration. Warm firelight glow. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
    "R26": {
        "name": "Haunted Dreams Amulet",
        "item_id": 138,
        "tileset_pos": (9, 13),
        "category": "amulet",
        "prompt": (
            "A single dark iron amulet with a swirling purple-black gem, "
            "wisps of shadow emanating from the stone, cursed jewelry, "
            "floating isolated in a completely solid black void background. "
            "Dark fantasy jewelry illustration. Nightmarish enchantment. "
            "No surface, no shadow, no frame. Clean illustrative painting."
        ),
    },
}


# === HSV Conversion ===

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


# === Image Processing ===

def detect_and_remove_bg(arr, tolerance=50):
    """
    Adaptive border-seeded flood fill BG removal.
    Works on any background color by detecting from border pixels.
    """
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(np.float64)
    alpha = arr[:, :, 3]

    # Get background color from border
    border_mask = np.zeros((h, w), dtype=bool)
    border_mask[:3, :] = True
    border_mask[-3:, :] = True
    border_mask[:, :3] = True
    border_mask[:, -3:] = True
    border_opaque = border_mask & (alpha > 128)

    if border_opaque.sum() < 20:
        return arr  # Can't detect background

    border_rgb = rgb[border_opaque]
    bg_color = np.median(border_rgb, axis=0)
    distances = np.sqrt(np.sum((border_rgb - bg_color) ** 2, axis=1))
    auto_tol = max(np.percentile(distances, 75) * 1.8, tolerance)

    # Precompute distance map
    dist_map = np.sqrt(np.sum((rgb - bg_color.reshape(1, 1, 3)) ** 2, axis=2))

    # Flood fill from border
    visited = np.zeros((h, w), dtype=bool)
    removed = np.zeros((h, w), dtype=bool)
    queue = deque()

    seed_tol = auto_tol * 1.3
    spread_tol = auto_tol * 0.85

    for y in range(h):
        for x in range(w):
            if y < 2 or y >= h - 2 or x < 2 or x >= w - 2:
                visited[y, x] = True
                if alpha[y, x] < 10 or dist_map[y, x] < seed_tol:
                    removed[y, x] = True
                    queue.append((y, x))

    dirs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in dirs:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if alpha[ny, nx] < 10 or dist_map[ny, nx] < spread_tol:
                    removed[ny, nx] = True
                    queue.append((ny, nx))

    result = arr.copy()
    result[removed, 3] = 0
    return result


def remove_small_islands(arr, min_area=80):
    """Remove small disconnected opaque regions."""
    result = arr.copy()
    alpha = result[:, :, 3]
    opaque = alpha > 0

    labeled, num_features = label(opaque)
    if num_features <= 1:
        return result

    for i in range(1, num_features + 1):
        if np.sum(labeled == i) < min_area:
            result[labeled == i, 3] = 0

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

    h, w = arr.shape[:2]
    y_min = max(0, y_min - pad)
    y_max = min(h - 1, y_max + pad)
    x_min = max(0, x_min - pad)
    x_max = min(w - 1, x_max + pad)

    cropped = img.crop((x_min, y_min, x_max + 1, y_max + 1))

    cw, ch = cropped.size
    size = max(cw, ch)
    square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    square.paste(cropped, ((size - cw) // 2, (size - ch) // 2))
    return square


def remove_black_bg(arr, threshold=25):
    """
    Simple black background removal by brightness threshold.
    Removes pixels where max(R,G,B) < threshold.
    Uses edge-only flood fill seeded from border dark pixels for safety.
    """
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(np.float64)
    alpha = arr[:, :, 3]
    brightness = np.max(rgb, axis=2)

    visited = np.zeros((h, w), dtype=bool)
    removed = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Seed: border pixels that are dark
    for y in range(h):
        for x in range(w):
            if y < 2 or y >= h - 2 or x < 2 or x >= w - 2:
                visited[y, x] = True
                if alpha[y, x] < 10 or brightness[y, x] < threshold * 1.5:
                    removed[y, x] = True
                    queue.append((y, x))

    dirs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
    while queue:
        cy, cx = queue.popleft()
        for dy, dx in dirs:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if alpha[ny, nx] < 10 or brightness[ny, nx] < threshold:
                    removed[ny, nx] = True
                    queue.append((ny, nx))

    result = arr.copy()
    result[removed, 3] = 0
    return result


def process_sprite(img_1024):
    """
    Process a raw 1024x1024 DALL-E sprite into a 64x64 game tile.
    Uses brightness-based black BG removal (safer than color-distance for
    dark subjects on black backgrounds).
    """
    arr = np.array(img_1024.convert("RGBA"))

    # Detect if background is black (most border pixels are dark)
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(np.float64)
    border_mask = np.zeros((h, w), dtype=bool)
    border_mask[:3, :] = True
    border_mask[-3:, :] = True
    border_mask[:, :3] = True
    border_mask[:, -3:] = True
    border_opaque = border_mask & (arr[:, :, 3] > 128)

    if border_opaque.sum() > 20:
        border_brightness = np.max(rgb[border_opaque], axis=1)
        median_brightness = np.median(border_brightness)
    else:
        median_brightness = 0

    if median_brightness < 50:
        # Black background: use brightness threshold
        arr = remove_black_bg(arr, threshold=22)
    else:
        # Other background: use color-distance flood fill
        arr = detect_and_remove_bg(arr, tolerance=40)

    # Remove particles
    arr = remove_small_islands(arr, min_area=80)

    # Crop and resize
    img = Image.fromarray(arr)
    img = auto_crop_square(img, pad=4)
    img = img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

    return img


# === DALL-E Generation ===

class SpriteRegenerator:
    def __init__(self):
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY not set. Check tileset_generation/.env")
        self.client = OpenAI(api_key=api_key)
        self.total_cost = 0.0

    def generate_image(self, target_key, target, retry=0):
        """Generate a single image via DALL-E 3."""
        if retry >= MAX_RETRIES:
            print(f"    [FAIL] {target_key}: Max retries exceeded")
            return None

        try:
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=target["prompt"],
                size="1024x1024",
                quality="standard",
                style="natural",
                n=1,
                response_format="b64_json",
            )
            img_data = base64.b64decode(response.data[0].b64_json)
            img = Image.open(io.BytesIO(img_data)).convert("RGBA")
            self.total_cost += COST_PER_IMAGE
            return img

        except Exception as e:
            print(f"    [RETRY {retry+1}] {target_key}: {e}")
            time.sleep(RATE_LIMIT_DELAY * (retry + 1))
            return self.generate_image(target_key, target, retry + 1)

    def run(self, target_keys=None, skip_api=False, dry_run=False):
        """Run the full regeneration pipeline."""
        RAW_DIR.mkdir(parents=True, exist_ok=True)
        PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

        # Load progress
        progress = {}
        if PROGRESS_FILE.exists():
            progress = json.loads(PROGRESS_FILE.read_text())

        if target_keys is None:
            target_keys = list(TARGETS.keys())

        # Filter to requested targets
        targets = {k: TARGETS[k] for k in target_keys if k in TARGETS}

        print(f"\n{'='*60}")
        print(f"DALL-E Regeneration: {len(targets)} tiles")
        print(f"Estimated cost: ${len(targets) * COST_PER_IMAGE:.2f}")
        print(f"{'='*60}\n")

        if dry_run:
            for key, target in targets.items():
                col, row = target["tileset_pos"]
                print(f"  {key}: {target['name']} (item_{target['item_id']}) -> ({row},{col})")
            print(f"\n[DRY RUN] No API calls made.")
            return []

        # Load tileset
        tileset = Image.open(TILESET_PATH).convert("RGBA")
        results = []

        for i, (key, target) in enumerate(targets.items(), 1):
            item_id = target["item_id"]
            col, row = target["tileset_pos"]
            raw_path = RAW_DIR / f"item_{item_id}_1024.png"
            processed_path = PROCESSED_DIR / f"item_{item_id}_light.png"

            print(f"  [{i}/{len(targets)}] {key}: {target['name']} (item_{item_id})")

            # Step 1: Generate or load raw
            if skip_api and raw_path.exists():
                print(f"    Loading cached raw: {raw_path.name}")
                img_1024 = Image.open(raw_path).convert("RGBA")
            elif skip_api:
                print(f"    [SKIP] No cached raw and --skip-api set")
                continue
            else:
                print(f"    Generating via DALL-E 3...")
                img_1024 = self.generate_image(key, target)
                if img_1024 is None:
                    continue
                img_1024.save(raw_path)
                print(f"    Saved raw: {raw_path.name}")
                time.sleep(RATE_LIMIT_DELAY)

            # Step 2: Process
            print(f"    Processing...")
            processed = process_sprite(img_1024)
            processed.save(processed_path)

            # Step 3: Integrate into tileset
            x, y = col * TILE_SIZE, row * TILE_SIZE
            clear = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear, (x, y))
            tileset.paste(processed, (x, y), processed)

            results.append({
                "key": key,
                "item_id": item_id,
                "name": target["name"],
                "tileset_pos": (col, row),
            })

            # Update progress
            progress[key] = {
                "item_id": item_id,
                "name": target["name"],
                "generated": datetime.now().isoformat(),
                "status": "complete",
            }
            PROGRESS_FILE.write_text(json.dumps(progress, indent=2))

        # Save tileset
        if results:
            tileset.save(TILESET_PATH, "PNG")
            print(f"\nTileset updated: {TILESET_PATH}")

        print(f"\n{'='*60}")
        print(f"RESULTS: {len(results)}/{len(targets)} regenerated")
        print(f"Total DALL-E cost: ${self.total_cost:.2f}")
        print(f"{'='*60}")

        return results


# === Main ===

def main():
    parser = argparse.ArgumentParser(description="DALL-E regeneration for 24 item sprites")
    parser.add_argument("--target", help="Single target key (e.g., R1)")
    parser.add_argument("--skip-api", action="store_true", help="Skip DALL-E, process cached raw only")
    parser.add_argument("--dry-run", action="store_true", help="Show plan, no API calls")
    args = parser.parse_args()

    target_keys = None
    if args.target:
        target_keys = [args.target]

    regen = SpriteRegenerator()
    results = regen.run(target_keys=target_keys, skip_api=args.skip_api, dry_run=args.dry_run)
    return len(results)


if __name__ == "__main__":
    sys.exit(0 if main() > 0 else 1)
