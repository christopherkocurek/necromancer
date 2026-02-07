#!/usr/bin/env python3
"""
Necromancer Artefact Category Sprite Generator
Generates ONE DALL-E sprite per visual category (19 categories).
All artefacts of a given type share the same sprite.

Usage:
    python artefact_gen.py --all        # Generate all 19 category sprites
    python artefact_gen.py --status     # Show progress
    python artefact_gen.py --single ID  # Generate one category by ID (0-18)
    python artefact_gen.py --list       # List categories and artefact mappings
"""

import os
import sys
import json
import time
import base64
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import io

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageEnhance
    import numpy as np
except ImportError:
    print("Required: pip install openai pillow python-dotenv numpy")
    sys.exit(1)

TILE_SIZE = 64
MAX_RETRIES = 3
RATE_LIMIT_DELAY = 2.5
COST_PER_IMAGE = 0.04

BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
OUTPUT_DIR = BASE_DIR / "artefact_v2"
RAW_DIR = OUTPUT_DIR / "raw"
PROGRESS_PATH = BASE_DIR / "artefact_v2_progress.json"

# ============================================================================
# 19 VISUAL CATEGORIES
# ============================================================================

CATEGORIES = {
    0: {
        "name": "sword",
        "visual_desc": "a single ornate fantasy longsword, gleaming steel blade with elven runes etched along the fuller, golden crossguard with a blue gemstone pommel, lying diagonally across the frame",
        "colors": "bright steel blade, golden crossguard, blue gemstone, leather grip",
    },
    1: {
        "name": "axe",
        "visual_desc": "a single heavy dwarven battle axe, broad curved steel blade head with runic engravings, thick oak handle wrapped in leather bindings, imposing and sturdy",
        "colors": "dark steel blade, runic silver engravings, brown oak handle, leather wrapping",
    },
    2: {
        "name": "spear",
        "visual_desc": "a single tall elegant spear standing upright, long ash wood shaft with a leaf-shaped silvered steel spearhead, a subtle silk ribbon tied below the blade",
        "colors": "silver steel spearhead, pale ash wood shaft, flowing silk ribbon, iron bindings",
    },
    3: {
        "name": "staff",
        "visual_desc": "a single gnarled wizard's staff, ancient dark oak wood with a softly glowing blue crystal mounted at the top, carved arcane runes along the shaft",
        "colors": "dark brown ancient wood, glowing blue crystal, carved silver runes, knobby bark texture",
    },
    4: {
        "name": "hammer",
        "visual_desc": "a single heavy dwarven war hammer, massive dark iron head with flat striking face and a spiked back, sturdy oak handle wrapped in leather, heavy and imposing",
        "colors": "dark iron hammer head, oak brown handle, leather wrapping, steel rivets",
    },
    5: {
        "name": "pickaxe",
        "visual_desc": "a single dwarven mining mattock, dark iron dual-pointed head mounted on a thick wooden handle, well-worn and practical, a miner's tool and weapon",
        "colors": "dark iron points, brown wooden handle, worn metal, practical design",
    },
    6: {
        "name": "bow",
        "visual_desc": "a single elegant elven longbow, gracefully curved golden mallorn wood with delicate silver leaf inlays along the limbs, taut bowstring catching the light",
        "colors": "golden-brown mallorn wood, silver leaf inlays, taut pale bowstring",
    },
    7: {
        "name": "arrow",
        "visual_desc": "a single ornate arrow lying horizontally, long straight dark shaft with pristine white goose feather fletching and a sharp broadhead steel tip, elegant craftsmanship",
        "colors": "dark wood shaft, white feather fletching, bright steel arrowhead",
    },
    8: {
        "name": "ring",
        "visual_desc": "a single ornate golden ring with a glowing blue gemstone centerpiece, delicate elven filigree metalwork around the band, faint magical inner glow",
        "colors": "bright gold band, glowing blue gemstone, silver filigree details, magical aura",
    },
    9: {
        "name": "amulet",
        "visual_desc": "a single ornate pendant amulet hanging from a fine silver chain, central glowing white gem set in intricate elven silverwork, radiating soft warm light",
        "colors": "silver chain, glowing white-blue gem, intricate silver setting, warm radiance",
    },
    10: {
        "name": "robe",
        "visual_desc": "a single flowing elven robe displayed as if worn by an invisible figure, rich dark blue fabric with golden embroidered patterns and subtle arcane symbols along the hem and sleeves",
        "colors": "deep blue fabric, golden embroidery, subtle arcane symbols, rich texture",
    },
    11: {
        "name": "mail",
        "visual_desc": "a single gleaming mithril chainmail corslet displayed upright, shining silver-blue interlocking rings, broad shoulder guards, masterwork craftsmanship visible in every link",
        "colors": "shining silver-blue mithril rings, steel shoulder guards, bright metallic sheen",
    },
    12: {
        "name": "shield",
        "visual_desc": "a single round medieval fantasy shield viewed from the front, dark iron rim with a painted heraldic white tree device on a blue field center, slightly battle-worn but noble",
        "colors": "dark iron rim, blue field, white tree heraldry, worn battle marks",
    },
    13: {
        "name": "helm",
        "visual_desc": "a single dark iron war helm with a tall nose guard and broad cheek plates, stern and functional design with subtle dwarven knotwork engravings, slightly battle-worn",
        "colors": "dark iron metal, subtle silver engravings, battle wear marks, stern design",
    },
    14: {
        "name": "crown",
        "visual_desc": "a single ornate golden crown with tall pointed peaks and sweeping arches, set with sparkling gemstones of many colors, intricate filigree metalwork, ancient and regal",
        "colors": "bright gold, sparkling gemstones red blue green, intricate filigree, regal majesty",
    },
    15: {
        "name": "cloak",
        "visual_desc": "a single flowing hooded elven cloak draped elegantly as if over invisible shoulders, dark forest green fabric with a prominent silver leaf-shaped clasp brooch at the neck",
        "colors": "dark forest green fabric, silver leaf clasp, subtle color-shifting weave",
    },
    16: {
        "name": "boots",
        "visual_desc": "a pair of sturdy leather adventurer's boots seen from the side, well-crafted with iron buckles and reinforced toes, slightly travel-worn but serviceable",
        "colors": "brown leather, iron buckles, reinforced dark toe caps, worn soles",
    },
    17: {
        "name": "gloves",
        "visual_desc": "a pair of leather gauntlets with iron knuckle plates and reinforced fingers, well-crafted hand protection, displayed palms-down side by side",
        "colors": "brown leather, iron knuckle plates, reinforced fingertips, dark stitching",
    },
    18: {
        "name": "light_source",
        "visual_desc": "a single glowing crystal phial radiating brilliant white-blue inner light outward in all directions, held in an ornate silver filigree cradle, magical artifact of great power",
        "colors": "brilliant white-blue inner glow, ornate silver filigree holder, radiant light beams",
    },
}

# ============================================================================
# ARTEFACT → CATEGORY MAPPING (tval + sval based)
# ============================================================================

# tval to category mapping (simple cases)
TVAL_TO_CATEGORY = {
    23: 0,   # Sword
    19: 6,   # Bow
    17: 7,   # Arrow
    45: 8,   # Ring
    40: 9,   # Amulet
    36: 10,  # Robe / Soft Armor
    37: 11,  # Mail / Hard Armor
    34: 12,  # Shield
    33: 14,  # Crown
    35: 15,  # Cloak
    30: 16,  # Boots
    31: 17,  # Gloves
    39: 18,  # Light Source
}

# tval 22 (Polearm) split by sval → Axe or Spear
POLEARM_AXE_SVALS = {11, 12, 13}  # Woodsman's Axe, Dwarven War-axe, Erebor Great-axe
POLEARM_SPEAR_SVALS = {1, 2, 4}   # Hunting Spear, Tower Guard Spear, Morgul Glaive

# tval 21 (Hafted) split by sval → Staff or Hammer
HAFTED_STAFF_SVALS = {3}    # Oak Staff
HAFTED_HAMMER_SVALS = {8}   # Dwarven Hammer

# tval 20 (Digging) → Pickaxe
DIGGING_TVAL = 20

# tval 32 (Helm) - all go to helm category
HELM_TVAL = 32

# Smithing template IDs to skip (182-198)
SKIP_IDS = set(range(182, 199))
# Quest map item
SKIP_IDS.add(180)  # Thrór's Map (tval 2, unique)


def get_category_for_artefact(tval: int, sval: int) -> Optional[int]:
    """Map artefact tval+sval to category ID."""
    if tval in TVAL_TO_CATEGORY:
        return TVAL_TO_CATEGORY[tval]
    if tval == 22:  # Polearm
        if sval in POLEARM_AXE_SVALS:
            return 1  # Axe
        return 2  # Spear (default for polearm)
    if tval == 21:  # Hafted
        if sval in HAFTED_HAMMER_SVALS:
            return 4  # Hammer
        return 3  # Staff (default for hafted)
    if tval == 20:  # Digging
        return 5  # Pickaxe
    if tval == 32:  # Helm
        return 13  # Helm
    return None


def parse_artefacts() -> Dict[int, Dict]:
    """Parse artefact.txt and return {id: {name, tval, sval, category}}."""
    artefact_path = PROJECT_DIR / "data" / "artefact.txt"
    artefacts = {}
    current_id = None
    current_name = None
    current_tval = None
    current_sval = None

    with open(artefact_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("N:"):
                parts = line.split(":")
                current_id = int(parts[1])
                current_name = parts[2] if len(parts) > 2 else ""
            elif line.startswith("I:") and current_id is not None:
                parts = line.split(":")
                current_tval = int(parts[1])
                current_sval = int(parts[2])
                if current_id not in SKIP_IDS:
                    cat = get_category_for_artefact(current_tval, current_sval)
                    artefacts[current_id] = {
                        "name": current_name,
                        "tval": current_tval,
                        "sval": current_sval,
                        "category": cat,
                    }
    return artefacts


# ============================================================================
# DALL-E GENERATION
# ============================================================================

def get_prompt(cat_id: int) -> str:
    """Build DALL-E prompt for a category sprite."""
    cat = CATEGORIES[cat_id]
    return (
        f"On a completely solid flat hot magenta background (hex FF00FF), "
        f"a vivid fantasy illustration of {cat['visual_desc']}. "
        f"Vivid striking colors: {cat['colors']}. "
        f"Strong readable silhouette against the magenta background. "
        f"The entire background must be completely uniform solid magenta with no variation. "
        f"A single object only, no duplicates, no text, no frames. "
        f"Painted in a clean illustrative style."
    )


def generate_sprite(client: OpenAI, cat_id: int) -> Optional[Image.Image]:
    """Generate a single category sprite via DALL-E 3."""
    cat = CATEGORIES[cat_id]
    prompt = get_prompt(cat_id)

    for attempt in range(MAX_RETRIES):
        try:
            print(f"  Generating {cat['name']}... (attempt {attempt + 1})")
            response = client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style="vivid",
                n=1,
                response_format="b64_json",
            )
            revised = response.data[0].revised_prompt
            if revised:
                print(f"  DALL-E revised: {revised[:80]}...")

            img_data = base64.b64decode(response.data[0].b64_json)
            img = Image.open(io.BytesIO(img_data)).convert("RGBA")

            # Validate: not blank
            arr = np.array(img)
            mean_brightness = arr[:, :, :3].mean()
            if mean_brightness > WHITE_THRESHOLD:
                print(f"  WARNING: Image too bright ({mean_brightness:.0f}), retrying...")
                time.sleep(RATE_LIMIT_DELAY)
                continue

            return img

        except Exception as e:
            err_str = str(e)
            if "content_policy" in err_str.lower():
                print(f"  Content policy rejection, softening prompt...")
                time.sleep(RATE_LIMIT_DELAY)
                continue
            print(f"  Error: {e}")
            time.sleep(RATE_LIMIT_DELAY)

    return None


WHITE_THRESHOLD = 240


def auto_crop_and_resize(img: Image.Image) -> Image.Image:
    """Crop to content, pad to square, resize to 64x64."""
    arr = np.array(img)
    alpha = arr[:, :, 3]
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)

    if not rows.any():
        return img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

    top, bot = np.where(rows)[0][[0, -1]]
    left, right = np.where(cols)[0][[0, -1]]

    cropped = img.crop((left, top, right + 1, bot + 1))
    w, h = cropped.size
    size = max(w, h)
    padded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    padded.paste(cropped, ((size - w) // 2, (size - h) // 2))
    return padded.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)


def generate_dark_variant(img: Image.Image) -> Image.Image:
    """Desaturate 60%, darken 40%, cool blue tint."""
    arr = np.array(img).astype(float)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3:]

    gray = rgb.mean(axis=2, keepdims=True)
    desat = rgb * 0.4 + gray * 0.6  # 60% desaturate
    darkened = desat * 0.6  # 40% darken
    # Blue tint
    darkened[:, :, 0] *= 0.85  # R
    darkened[:, :, 1] *= 0.90  # G
    darkened[:, :, 2] = np.minimum(darkened[:, :, 2] * 1.15, 255)  # B

    result = np.concatenate([darkened, alpha], axis=2).clip(0, 255).astype(np.uint8)
    return Image.fromarray(result)


# ============================================================================
# PROGRESS TRACKING
# ============================================================================

def load_progress() -> dict:
    if PROGRESS_PATH.exists():
        return json.loads(PROGRESS_PATH.read_text())
    return {"sprites": {}, "started": datetime.now().isoformat()}


def save_progress(progress: dict):
    PROGRESS_PATH.write_text(json.dumps(progress, indent=2))


# ============================================================================
# MAIN PIPELINE
# ============================================================================

def generate_category(client: OpenAI, cat_id: int, progress: dict) -> bool:
    """Generate, save, and track one category sprite."""
    cat = CATEGORIES[cat_id]
    key = f"cat_{cat_id}_{cat['name']}"

    if key in progress["sprites"] and progress["sprites"][key].get("status") == "completed":
        print(f"  [{cat_id}] {cat['name']} - already completed, skipping")
        return True

    print(f"\n{'=' * 60}")
    print(f"Generating: [{cat_id}] {cat['name']}")
    print(f"{'=' * 60}")

    img = generate_sprite(client, cat_id)
    if img is None:
        print(f"  FAILED after {MAX_RETRIES} attempts")
        progress["sprites"][key] = {"status": "failed", "name": cat["name"]}
        save_progress(progress)
        return False

    # Save raw
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    raw_path = RAW_DIR / f"artefact_{cat_id}_{cat['name']}_1024.png"
    img.save(raw_path)
    print(f"  Saved raw: {raw_path.name}")

    # Crop + resize to 64x64 (we'll do BG removal in a separate step)
    # For now save light preview
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Quick border check for direct resize
    arr = np.array(img)
    h, w = arr.shape[:2]
    border_size = 20
    top_border = arr[:border_size, :, :3]
    bot_border = arr[-border_size:, :, :3]
    left_border = arr[:, :border_size, :3]
    right_border = arr[:, -border_size:, :3]

    all_borders = np.concatenate([
        top_border.reshape(-1, 3),
        bot_border.reshape(-1, 3),
        left_border.reshape(-1, 3),
        right_border.reshape(-1, 3),
    ])
    magenta_mask = (all_borders[:, 0] > 150) & (all_borders[:, 1] < 100) & (all_borders[:, 2] > 150)
    magenta_pct = magenta_mask.mean()
    print(f"  Border magenta: {magenta_pct:.1%}")

    # Save light 64px (pre-correction - will be overwritten by fix pipeline)
    small = img.resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)
    light_path = OUTPUT_DIR / f"artefact_{cat_id}_{cat['name']}_light.png"
    small.save(light_path)
    print(f"  Saved light: {light_path.name}")

    # Dark variant
    dark = generate_dark_variant(small)
    dark_path = OUTPUT_DIR / f"artefact_{cat_id}_{cat['name']}_dark.png"
    dark.save(dark_path)
    print(f"  Saved dark: {dark_path.name}")

    progress["sprites"][key] = {
        "status": "completed",
        "name": cat["name"],
        "cat_id": cat_id,
        "completed_at": datetime.now().isoformat(),
    }
    save_progress(progress)
    time.sleep(RATE_LIMIT_DELAY)
    return True


def cmd_all(client: OpenAI):
    """Generate all 19 category sprites."""
    progress = load_progress()
    total = len(CATEGORIES)
    done = sum(1 for v in progress["sprites"].values() if v.get("status") == "completed")
    print(f"\nGenerating ALL {total} categories ({done} already done)")

    for cat_id in sorted(CATEGORIES.keys()):
        generate_category(client, cat_id, progress)

    done = sum(1 for v in progress["sprites"].values() if v.get("status") == "completed")
    calls = len(progress["sprites"])
    print(f"\n{'=' * 60}")
    print(f"COMPLETE: {done}/{total}")
    print(f"API calls: {calls}")
    print(f"Est. cost: ${calls * COST_PER_IMAGE:.2f}")


def cmd_single(client: OpenAI, cat_id: int):
    """Generate a single category sprite."""
    if cat_id not in CATEGORIES:
        print(f"Unknown category ID: {cat_id}. Valid: 0-{len(CATEGORIES) - 1}")
        sys.exit(1)
    progress = load_progress()
    # Clear existing entry to force regeneration
    cat = CATEGORIES[cat_id]
    key = f"cat_{cat_id}_{cat['name']}"
    if key in progress["sprites"]:
        del progress["sprites"][key]
    generate_category(client, cat_id, progress)


def cmd_status():
    """Show generation progress."""
    progress = load_progress()
    total = len(CATEGORIES)
    done = sum(1 for v in progress["sprites"].values() if v.get("status") == "completed")
    failed = sum(1 for v in progress["sprites"].values() if v.get("status") == "failed")
    print(f"\n{'=' * 60}")
    print(f"ARTEFACT CATEGORY SPRITE GENERATION STATUS")
    print(f"{'=' * 60}")
    for cat_id in sorted(CATEGORIES.keys()):
        cat = CATEGORIES[cat_id]
        key = f"cat_{cat_id}_{cat['name']}"
        status = progress.get("sprites", {}).get(key, {}).get("status", "pending")
        icon = "✓" if status == "completed" else ("✗" if status == "failed" else "·")
        print(f"  [{cat_id:2d}] {icon} {cat['name']:<15}")
    print(f"\n  Total: {done}/{total} (failed: {failed})")
    calls = len(progress["sprites"])
    print(f"  Est. cost: ${calls * COST_PER_IMAGE:.2f}")


def cmd_list():
    """List categories and which artefacts map to each."""
    artefacts = parse_artefacts()
    by_cat = {}
    for art_id, art in sorted(artefacts.items()):
        cat = art["category"]
        if cat is not None:
            by_cat.setdefault(cat, []).append((art_id, art["name"]))

    for cat_id in sorted(CATEGORIES.keys()):
        cat = CATEGORIES[cat_id]
        arts = by_cat.get(cat_id, [])
        print(f"\n[{cat_id}] {cat['name'].upper()} ({len(arts)} artefacts)")
        for art_id, name in arts:
            print(f"    {art_id:4d}: {name}")

    # Check for unmapped
    unmapped = [(aid, a) for aid, a in artefacts.items() if a["category"] is None]
    if unmapped:
        print(f"\nUNMAPPED ({len(unmapped)}):")
        for aid, a in unmapped:
            print(f"    {aid}: {a['name']} (tval={a['tval']}, sval={a['sval']})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate artefact category sprites")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all", action="store_true", help="Generate all 19 categories")
    group.add_argument("--single", type=int, metavar="ID", help="Generate one category (0-18)")
    group.add_argument("--status", action="store_true", help="Show progress")
    group.add_argument("--list", action="store_true", help="List category→artefact mappings")
    args = parser.parse_args()

    if args.status:
        cmd_status()
    elif args.list:
        cmd_list()
    else:
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            print("Set OPENAI_API_KEY in .env or environment")
            sys.exit(1)
        client = OpenAI(api_key=api_key)

        if args.all:
            cmd_all(client)
        elif args.single is not None:
            cmd_single(client, args.single)
