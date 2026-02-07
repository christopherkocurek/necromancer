#!/usr/bin/env python3
"""
Necromancer Terrain Tile Generator v2
Generates environment tiles using DALL-E 3 with edge-to-edge coverage.

Key improvements over generator.py:
- Prompts designed for seamless, full-bleed tiles (no borders)
- Auto-crop + stretch post-processing to remove white edges
- Programmatic dark variant generation (free, consistent)
- Test mode generates 1 sample per category for human review

Usage:
    python terrain_gen.py --test              # 8 sample sprites for review
    python terrain_gen.py --all               # Generate all terrain
    python terrain_gen.py --category floor    # Specific category
    python terrain_gen.py --status            # Show progress
    python terrain_gen.py --darken            # Generate dark variants from existing light sprites
"""

import os
import sys
import json
import time
import base64
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import io

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter, ImageEnhance, ImageStat
    import numpy as np
except ImportError:
    print("Required packages not installed. Run:")
    print("  pip install openai pillow python-dotenv numpy")
    sys.exit(1)

# Constants
TILE_SIZE = 64
MAX_RETRIES = 3
RATE_LIMIT_DELAY = 2.5  # seconds between API calls
COST_PER_IMAGE = 0.04   # DALL-E 3 standard 1024x1024

# White/border detection thresholds
WHITE_THRESHOLD = 240    # Pixel brightness above this = "white"
BORDER_SCAN_DEPTH = 50   # How many pixels inward to scan for borders (in 1024x1024)
CONTENT_MIN_PCT = 0.60   # At least 60% of cropped area should be non-white

# Paths
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "terrain_v2"
PROGRESS_PATH = BASE_DIR / "terrain_v2_progress.json"

# ============================================================================
# TERRAIN DEFINITIONS - What we need to generate
# ============================================================================

# Each entry: (terrain_id, name, visual_category, prompt_description)
# visual_category determines the prompt template used

TERRAIN_SAMPLES = {
    "floor": {
        "id": 1,
        "name": "open floor",
        "desc": "uniform dark gray stone dungeon floor, cracked flagstones with dark mortar lines between them, all the same gray tone throughout with no color variation at edges"
    },
    "wall": {
        "id": 56,
        "name": "dark stone wall",
        "desc": "dark cobblestone dungeon wall, gray and dark gray stones with black mortar, rough hewn blocks"
    },
    "door_closed": {
        "id": 32,
        "name": "iron door (closed)",
        "desc": "a shut wooden door reinforced with iron bands, iron ring handle, set into a stone archway in a dungeon wall"
    },
    "door_open": {
        "id": 4,
        "name": "open door",
        "desc": "a wooden door that is swung wide open to the left, revealing a black empty doorway passage, the door hinged on the left side and pushed inward, stone archway frame visible"
    },
    "trap": {
        "id": 17,
        "name": "jagged pit",
        "desc": "jagged hole in dungeon floor revealing sharp rocks below, cracked stone edges"
    },
    "stairs_down": {
        "id": 81,
        "name": "dark stairs down",
        "desc": "stone stairs descending into darkness, worn steps carved into dungeon floor"
    },
    "stairs_up": {
        "id": 80,
        "name": "crumbling stairs up",
        "desc": "stone stairs ascending upward toward light, worn crumbling steps carved into dungeon floor, light visible at the top"
    },
    "forge": {
        "id": 65,
        "name": "orc forge (active)",
        "desc": "a large circular stone forge pit filled with roaring bright orange-red coals and flames, the round opening glows intensely, dark stone rim around the fire circle"
    },
    "special": {
        "id": 29,
        "name": "prison bars",
        "desc": "vertical iron prison bars set into stone floor and ceiling, rusted, dark dungeon"
    }
}

# Full terrain manifest - all terrains grouped by visual category
TERRAIN_FULL = {
    "floor": [
        (0, "darkness", "pure black void, absolute darkness, no visible features, solid black"),
        (1, "open floor", "uniform dark gray stone dungeon floor, cracked flagstones with dark mortar lines, all the same gray tone throughout with no color variation at edges"),
        (9, "fading daylight", "dark stone floor with faint warm yellowish light filtering from above, same flagstone pattern but warmer tint"),
        (10, "open floor variant", "dark gray stone dungeon floor with subtly different stone pattern, dark mortar between uniform gray blocks"),
        (31, "bloodstain", "dark stone dungeon floor with dark red-brown dried stains splattered across gray flagstones"),
        (49, "fallen masonry", "dark stone floor scattered with broken stone rubble and debris chunks"),
        (86, "vine floor", "dark stone floor with creeping green vines and moss growing through cracks between stones"),
        (87, "forest floor", "natural dark dirt floor with dead brown leaves, twigs, and green moss patches"),
    ],
    "wall": [
        (11, "wall", "standard dungeon wall, rough gray stone blocks with dark mortar"),
        (48, "hidden passage", "wall that looks identical to normal stone wall, secret door disguised"),
        (51, "quartz vein", "dungeon wall with white crystalline quartz veins running through dark stone"),
        (56, "dark stone wall 1", "dark cobblestone wall, gray and dark gray stones, rough hewn blocks"),
        (57, "dark stone wall 2", "dark stone wall, slightly different block arrangement, varied mortar"),
        (58, "dark stone wall 3", "dark stone wall, larger blocks, deeper mortar lines"),
        (59, "dark stone wall 4", "dark stone wall, mixed block sizes, some crumbling edges"),
        (63, "dark stone wall permanent", "reinforced dark stone wall, iron bands embedded, unbreakable"),
        (85, "tangled roots", "wall of thick twisted tree roots and packed earth, forest dungeon"),
    ],
    "door_closed": [
        (32, "iron door", "a shut wooden door reinforced with iron bands, iron ring handle, set into a stone archway in a dungeon wall"),
        (5, "shattered door", "a destroyed wooden door, splintered broken planks hanging from bent iron hinges in a stone archway"),
        (6, "warded door power 1", "a shut wooden door with a faint blue magical rune glowing on its surface, set in a stone archway"),
        (7, "warded door power 2", "a shut wooden door with bright blue-green magical runes pulsing across it, set in a stone archway"),
        (8, "warded door power 3", "a shut wooden door with intense violet magical ward energy barrier glowing across it, set in a stone archway"),
    ],
    "door_open": [
        (4, "open door", "a wooden door that is swung wide open to the left, revealing a black empty doorway passage, the door hinged on the left side and pushed inward, stone archway frame visible"),
    ],
    "trap": [
        (2, "bottomless pit", "dark void hole in dungeon floor, no visible bottom, crumbling stone edges"),
        (16, "weakened floor", "suspicious cracked stone floor, slightly sagging, trap disguised as floor"),
        (17, "jagged pit", "jagged hole revealing sharp rocks below, cracked stone edges"),
        (18, "poisoned spike pit", "pit with green-tipped metal spikes visible at bottom, toxic drips"),
        (19, "poison needle trap", "stone floor tile with tiny holes, hidden needle mechanism, green residue"),
        (20, "noxious fumes", "stone floor with green-yellow toxic gas wisps rising from cracks"),
        (21, "mind fog", "stone floor with swirling purple-blue haze, disorienting magical mist"),
        (22, "orc alarm", "crude rope-and-bell alarm mechanism mounted on stone floor, tribal"),
        (23, "blinding glyph", "bright white magical symbol inscribed on dungeon floor, radiating light"),
        (24, "rusted caltrops", "scattered rusty iron caltrops on stone dungeon floor"),
        (25, "bat roost", "stone alcove with bat droppings, dark stains, scratched stone ceiling"),
        (26, "thick web", "dense white spider web filling the passage, sticky strands"),
        (27, "falling stones", "stone floor under cracked ceiling with loose rocks, dust falling"),
        (28, "pool of filth", "shallow dark murky water puddle on dungeon floor, greenish scum"),
    ],
    "stairs": [
        (81, "dark stairs down", "stone stairs descending into darkness, worn steps"),
        (83, "narrow shaft down", "small vertical shaft opening in floor, iron ladder rungs going down into darkness"),
    ],
    "stairs_up": [
        (80, "crumbling stairs up", "stone stairs ascending upward toward light, worn crumbling steps, light visible at the top"),
        (82, "narrow shaft up", "small vertical shaft opening in ceiling with iron ladder rungs going up toward faint light"),
    ],
    "forge": [
        (64, "orc forge exhausted", "a large circular stone forge pit filled with cold gray ash, no fire, dark and dormant round opening"),
        (65, "orc forge active", "a large circular stone forge pit filled with roaring bright orange-red coals and flames, the round opening glows intensely, dark stone rim around the fire circle"),
        (70, "shadow forge exhausted", "dark crystalline forge, no glow, purple-black stone, dormant"),
        (71, "shadow forge active", "dark crystalline forge with violet flames, magical purple glow"),
        (76, "forge Angdur exhausted", "ancient ornate dwarven forge, cold, intricate gold inlay, dormant"),
        (77, "forge Angdur active", "ancient ornate dwarven forge, bright orange-gold flames, rune-carved"),
    ],
    "special": [
        (3, "protective rune", "green glowing magical rune circle inscribed on dungeon floor"),
        (12, "dark pool", "shallow pool of dark still water on dungeon floor, reflective surface"),
        (13, "morgul runes", "sinister dark magical runes on floor, faint sickly green-black glow"),
        (14, "shadow brazier", "iron brazier stand with flickering dark flame, casting shadows"),
        (15, "torture rack", "iron frame with chains and restraints, dark metal, dungeon furniture"),
        (29, "prison bars", "vertical iron prison bars set into stone floor and ceiling, rusted"),
        (30, "chains", "heavy iron chains and shackles hanging from stone wall, rusted"),
        (84, "poison stream", "narrow stream of green-tinted water flowing across dungeon floor"),
    ],
}


def get_terrain_prompt(name: str, desc: str, category: str) -> str:
    """
    Build a DALL-E 3 prompt for a terrain tile.

    Key lessons from rounds 1-2:
    - NEVER use "pixel art", "game tile", "sprite", or "texture" - these trigger
      DALL-E to generate editor UIs, sprite sheets, color palettes, and grids
    - Frame as a "painting" or "illustration" of a scene/surface
    - Use "retro low-resolution" and "blocky" instead of "pixel art"
    - Describe the physical surface/scene, not a digital asset
    - Always specify dark backgrounds so any border bleed is dark, not white
    """

    if category in ("floor", "trap"):
        prompt = (
            f"A flat overhead painting of {desc}. "
            f"Bird's eye view looking straight down. "
            f"Dark fantasy style, gritty and worn. "
            f"The stone surface fills the entire image completely, "
            f"extending beyond all four edges. "
            f"Painted in a retro low-resolution blocky style with chunky details. "
            f"Very dark color palette: charcoal gray, near-black, dark brown."
        )
    elif category == "wall":
        prompt = (
            f"A close-up painting of {desc}. "
            f"Viewed straight-on from the front. "
            f"Dark fantasy style, ancient and weathered. "
            f"The wall surface fills the entire image completely, "
            f"extending beyond all four edges like a zoomed-in photograph. "
            f"Painted in a retro low-resolution blocky style with chunky stone blocks. "
            f"Very dark color palette: charcoal gray, near-black, dark brown."
        )
    elif category in ("door_closed", "door_open"):
        prompt = (
            f"A single illustration showing {desc}. "
            f"Viewed straight-on from the front. "
            f"Dark stone dungeon wall completely fills the entire image from edge to edge, "
            f"with the doorway in the center of the wall. "
            f"Dark fantasy style, ancient and menacing. "
            f"Retro low-resolution blocky style. "
            f"Very dark color palette: charcoal stone, iron gray, dark wood brown, black shadows. "
            f"This is one single scene only, not a reference sheet or color study."
        )
    elif category in ("stairs", "stairs_up"):
        prompt = (
            f"A painting of a dark dungeon stone floor with {desc} in the center. "
            f"Bird's eye view looking straight down from above. "
            f"The dark stone floor fills the entire image edge to edge, "
            f"with the stairway opening in the center of the floor. "
            f"Dark fantasy style. "
            f"Painted in a retro low-resolution blocky style. "
            f"Very dark color palette: charcoal gray, near-black, dark brown."
        )
    elif category == "forge":
        prompt = (
            f"A painting of a dark dungeon stone floor with {desc} in the center. "
            f"Bird's eye view looking straight down from above. "
            f"The dark stone floor fills the entire image edge to edge, "
            f"with the forge in the center. "
            f"Dark fantasy style with warm orange glow from the coals. "
            f"Painted in a retro low-resolution blocky style. "
            f"Dark color palette: charcoal gray, near-black, with orange-red firelight."
        )
    elif category == "special":
        prompt = (
            f"A painting of a dark dungeon stone floor with {desc} in the center. "
            f"Bird's eye view looking straight down from above. "
            f"The dark stone floor fills the entire image edge to edge, "
            f"with the feature in the center. "
            f"Dark fantasy style, gritty and ancient. "
            f"Painted in a retro low-resolution blocky style. "
            f"Very dark color palette: charcoal gray, near-black, dark brown, rusted iron."
        )
    else:
        prompt = (
            f"A painting of {desc}. "
            f"Dark fantasy dungeon style. "
            f"The scene fills the entire image edge to edge. "
            f"Painted in a retro low-resolution blocky style. "
            f"Very dark color palette."
        )

    return prompt


def auto_crop_and_stretch(img: Image.Image, target_size: int = TILE_SIZE) -> Image.Image:
    """
    Detect content area, crop out white borders, then stretch to target_size.

    Strategy:
    1. Convert to grayscale to detect white borders
    2. Find bounding box of non-white content
    3. Crop to content area
    4. Resize to target_size x target_size using nearest-neighbor

    If no significant white border is detected (good generation), just resize.
    """
    # Work on a copy
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]

    # Create mask of "non-white" pixels (content)
    # A pixel is "content" if it's not close to white
    r, g, b = img_array[:,:,0], img_array[:,:,1], img_array[:,:,2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD

    # Find bounding box of content
    rows_with_content = np.any(content_mask, axis=1)
    cols_with_content = np.any(content_mask, axis=0)

    if not np.any(rows_with_content) or not np.any(cols_with_content):
        # No content found (entirely white) - return as-is resized
        print("  WARNING: Image appears entirely white/blank")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)

    # Get content bounds
    row_start = np.argmax(rows_with_content)
    row_end = h - np.argmax(rows_with_content[::-1])
    col_start = np.argmax(cols_with_content)
    col_end = w - np.argmax(cols_with_content[::-1])

    # Calculate border sizes
    border_top = row_start
    border_bottom = h - row_end
    border_left = col_start
    border_right = w - col_end

    total_border = border_top + border_bottom + border_left + border_right
    border_pct = total_border / (2 * (h + w)) * 100

    print(f"  Border detection: top={border_top} bot={border_bottom} "
          f"left={border_left} right={border_right} ({border_pct:.1f}%)")

    # Only crop if there's a meaningful border (> 2% of image size on any side)
    min_border = int(h * 0.02)
    if (border_top > min_border or border_bottom > min_border or
        border_left > min_border or border_right > min_border):

        # Add a small inset to ensure we get all content (2px at 1024 scale)
        padding = 2
        row_start = max(0, row_start - padding)
        row_end = min(h, row_end + padding)
        col_start = max(0, col_start - padding)
        col_end = min(w, col_end + padding)

        # Crop
        cropped = img.crop((col_start, row_start, col_end, row_end))
        crop_w, crop_h = cropped.size
        print(f"  Cropped: {w}x{h} -> {crop_w}x{crop_h}")

        # Make it square by taking the larger dimension and center-cropping
        if crop_w != crop_h:
            max_dim = max(crop_w, crop_h)
            # Create a square canvas with the dominant color from edges
            square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 255))
            paste_x = (max_dim - crop_w) // 2
            paste_y = (max_dim - crop_h) // 2
            square.paste(cropped, (paste_x, paste_y))
            cropped = square
            print(f"  Squared: {max_dim}x{max_dim}")

        # Stretch to target size
        result = cropped.resize((target_size, target_size), Image.Resampling.NEAREST)
        print(f"  Stretched to {target_size}x{target_size}")
        return result
    else:
        # No significant border - just resize directly
        print(f"  No significant border detected - direct resize")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)


def generate_dark_variant(img: Image.Image) -> Image.Image:
    """
    Generate a dark/FOV variant from a light sprite.

    Technique:
    - Desaturate by 60%
    - Darken by 40%
    - Apply cool blue-grey tint
    """
    # Convert to RGB for processing (drop alpha temporarily)
    if img.mode == "RGBA":
        alpha = img.split()[3]
        rgb = img.convert("RGB")
    else:
        alpha = None
        rgb = img.convert("RGB")

    # Desaturate (blend toward grayscale)
    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)  # 60% toward gray

    # Darken
    darkener = ImageEnhance.Brightness(desaturated)
    darkened = darkener.enhance(0.6)  # 60% brightness = 40% darker

    # Apply cool blue tint
    arr = np.array(darkened).astype(np.float32)
    # Shift toward blue-grey: reduce red slightly, boost blue slightly
    arr[:,:,0] *= 0.85  # reduce red
    arr[:,:,1] *= 0.90  # slightly reduce green
    arr[:,:,2] = np.minimum(arr[:,:,2] * 1.15, 255)  # boost blue
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, "RGB")

    # Restore alpha channel
    if alpha is not None:
        result = result.convert("RGBA")
        result.putalpha(alpha)

    return result


def validate_tile(img: Image.Image) -> Tuple[bool, str]:
    """
    Validate a generated terrain tile.
    Returns (is_valid, reason).
    """
    w, h = img.size
    if w != TILE_SIZE or h != TILE_SIZE:
        return False, f"Wrong size: {w}x{h}, expected {TILE_SIZE}x{TILE_SIZE}"

    # Check it's not mostly white (failed generation)
    arr = np.array(img.convert("RGB"))
    brightness = arr.mean()
    if brightness > 220:
        return False, f"Too bright (avg brightness {brightness:.0f}), likely a failed generation"

    # Check it's not mostly a single color (degenerate)
    std = arr.std()
    if std < 10:
        return False, f"Too uniform (std dev {std:.1f}), likely a solid color block"

    # Check edges aren't mostly white (border leak)
    top_row = arr[0, :, :].mean()
    bot_row = arr[-1, :, :].mean()
    left_col = arr[:, 0, :].mean()
    right_col = arr[:, -1, :].mean()
    edge_avg = (top_row + bot_row + left_col + right_col) / 4
    if edge_avg > 230:
        return False, f"White edges detected (avg edge brightness {edge_avg:.0f})"

    return True, "OK"


class TerrainGenerator:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.progress = self._load_progress()
        self.total_cost = 0.0

    def _load_progress(self) -> Dict:
        if PROGRESS_PATH.exists():
            with open(PROGRESS_PATH, "r") as f:
                return json.load(f)
        return {
            "started_at": datetime.now().isoformat(),
            "last_updated": datetime.now().isoformat(),
            "sprites": {},
            "cost_total": 0.0,
            "api_calls": 0
        }

    def _save_progress(self):
        self.progress["last_updated"] = datetime.now().isoformat()
        with open(PROGRESS_PATH, "w") as f:
            json.dump(self.progress, f, indent=2)

    def generate_single(self, terrain_id: int, name: str, desc: str,
                        category: str, retry: int = 0) -> Optional[Path]:
        """
        Generate a single terrain tile sprite.
        Returns path to saved 64x64 PNG, or None on failure.
        """
        key = f"terrain_{terrain_id}_light"

        # Skip if already completed
        if key in self.progress["sprites"] and self.progress["sprites"][key].get("status") == "completed":
            existing_path = Path(self.progress["sprites"][key]["path"])
            if existing_path.exists():
                print(f"  SKIP: {key} already completed")
                return existing_path

        prompt = get_terrain_prompt(name, desc, category)
        print(f"\n{'='*60}")
        print(f"Generating: {name} (ID {terrain_id}, category: {category})")
        print(f"Prompt: {prompt[:120]}...")

        try:
            # Call DALL-E 3
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style="natural",  # "natural" tends to be less artistic/bordered
                n=1,
                response_format="b64_json"
            )

            self.total_cost += COST_PER_IMAGE
            self.progress["api_calls"] = self.progress.get("api_calls", 0) + 1
            self.progress["cost_total"] = self.progress.get("cost_total", 0) + COST_PER_IMAGE

            # Decode image
            img_data = base64.b64decode(response.data[0].b64_json)
            img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")

            # Log the revised prompt (DALL-E 3 modifies prompts)
            revised = getattr(response.data[0], 'revised_prompt', None)
            if revised:
                print(f"  DALL-E revised prompt: {revised[:100]}...")

            # Save the raw 1024x1024 for debugging
            raw_dir = self.output_dir / "raw"
            raw_dir.mkdir(exist_ok=True)
            raw_path = raw_dir / f"{key}_1024.png"
            img_1024.save(raw_path)
            print(f"  Saved raw: {raw_path}")

            # Auto-crop and stretch to 64x64
            img_64 = auto_crop_and_stretch(img_1024, TILE_SIZE)

            # Validate
            is_valid, reason = validate_tile(img_64)
            if not is_valid:
                print(f"  VALIDATION FAILED: {reason}")
                if retry < MAX_RETRIES:
                    print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                    time.sleep(RATE_LIMIT_DELAY)
                    return self.generate_single(terrain_id, name, desc, category, retry + 1)
                else:
                    print(f"  MAX RETRIES REACHED - saving anyway for manual review")

            # Save light variant
            cat_dir = self.output_dir / category
            cat_dir.mkdir(exist_ok=True)
            light_path = cat_dir / f"terrain_{terrain_id}_light.png"
            img_64.save(light_path)
            print(f"  Saved light: {light_path}")

            # Generate and save dark variant
            img_dark = generate_dark_variant(img_64)
            dark_path = cat_dir / f"terrain_{terrain_id}_dark.png"
            img_dark.save(dark_path)
            print(f"  Saved dark: {dark_path}")

            # Update progress
            self.progress["sprites"][key] = {
                "status": "completed",
                "path": str(light_path),
                "dark_path": str(dark_path),
                "terrain_id": terrain_id,
                "name": name,
                "category": category,
                "valid": is_valid,
                "validation_msg": reason,
                "completed_at": datetime.now().isoformat()
            }
            self._save_progress()

            return light_path

        except Exception as e:
            print(f"  ERROR: {e}")
            if retry < MAX_RETRIES:
                print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                time.sleep(RATE_LIMIT_DELAY * 2)
                return self.generate_single(terrain_id, name, desc, category, retry + 1)

            self.progress["sprites"][key] = {
                "status": "failed",
                "error": str(e),
                "terrain_id": terrain_id,
                "name": name,
                "failed_at": datetime.now().isoformat()
            }
            self._save_progress()
            return None

    def generate_test_samples(self) -> Dict[str, bool]:
        """Generate 1 sample per category for human review."""
        results = {}
        print("\n" + "=" * 60)
        print("TERRAIN TEST GENERATION - 8 samples for review")
        print("=" * 60)

        for category, info in TERRAIN_SAMPLES.items():
            path = self.generate_single(
                terrain_id=info["id"],
                name=info["name"],
                desc=info["desc"],
                category=category
            )
            results[category] = path is not None
            time.sleep(RATE_LIMIT_DELAY)

        # Print summary
        print("\n" + "=" * 60)
        print("TEST RESULTS")
        print("=" * 60)
        for cat, success in results.items():
            status = "OK" if success else "FAILED"
            print(f"  {cat:15s}: {status}")

        cost = self.progress.get("cost_total", 0)
        calls = self.progress.get("api_calls", 0)
        print(f"\nAPI calls: {calls}")
        print(f"Estimated cost: ${cost:.2f}")
        print(f"\nReview sprites at: {self.output_dir}/")
        print(f"Raw 1024x1024 images at: {self.output_dir}/raw/")

        return results

    def generate_category(self, category: str) -> Dict[str, int]:
        """Generate all terrains in a category."""
        if category not in TERRAIN_FULL:
            print(f"Unknown category: {category}")
            print(f"Available: {list(TERRAIN_FULL.keys())}")
            return {"completed": 0, "failed": 0, "skipped": 0}

        terrains = TERRAIN_FULL[category]
        stats = {"completed": 0, "failed": 0, "skipped": 0}

        print(f"\nGenerating category: {category} ({len(terrains)} terrains)")

        for terrain_id, name, desc in terrains:
            key = f"terrain_{terrain_id}_light"
            if key in self.progress["sprites"] and self.progress["sprites"][key].get("status") == "completed":
                existing_path = Path(self.progress["sprites"][key]["path"])
                if existing_path.exists():
                    stats["skipped"] += 1
                    continue

            path = self.generate_single(terrain_id, name, desc, category)
            if path:
                stats["completed"] += 1
            else:
                stats["failed"] += 1
            time.sleep(RATE_LIMIT_DELAY)

        print(f"\n{category} complete: {stats}")
        return stats

    def generate_all(self):
        """Generate all terrain categories."""
        total_stats = {"completed": 0, "failed": 0, "skipped": 0}

        for category in TERRAIN_FULL:
            stats = self.generate_category(category)
            for k in total_stats:
                total_stats[k] += stats[k]

        print(f"\n{'='*60}")
        print(f"ALL TERRAIN COMPLETE")
        print(f"{'='*60}")
        print(f"Completed: {total_stats['completed']}")
        print(f"Failed: {total_stats['failed']}")
        print(f"Skipped: {total_stats['skipped']}")
        print(f"API calls: {self.progress.get('api_calls', 0)}")
        print(f"Est. cost: ${self.progress.get('cost_total', 0):.2f}")

    def generate_dark_variants_only(self):
        """Generate dark variants for all existing light sprites."""
        count = 0
        for key, info in self.progress["sprites"].items():
            if info.get("status") != "completed":
                continue
            light_path = Path(info["path"])
            if not light_path.exists():
                continue

            dark_path = light_path.parent / light_path.name.replace("_light.", "_dark.")
            if dark_path.exists():
                continue

            img = Image.open(light_path).convert("RGBA")
            dark = generate_dark_variant(img)
            dark.save(dark_path)
            info["dark_path"] = str(dark_path)
            count += 1
            print(f"  Generated dark: {dark_path.name}")

        self._save_progress()
        print(f"\nGenerated {count} dark variants")

    def show_status(self):
        """Display generation progress."""
        print(f"\n{'='*60}")
        print("TERRAIN GENERATION STATUS")
        print(f"{'='*60}")

        # Count by category
        cat_stats = {}
        for category, terrains in TERRAIN_FULL.items():
            total = len(terrains)
            done = 0
            for tid, name, desc in terrains:
                key = f"terrain_{tid}_light"
                if key in self.progress["sprites"] and self.progress["sprites"][key].get("status") == "completed":
                    done += 1
            cat_stats[category] = (done, total)

        for cat, (done, total) in cat_stats.items():
            bar_len = 30
            filled = int(bar_len * done / total) if total > 0 else 0
            bar = "#" * filled + "-" * (bar_len - filled)
            print(f"  {cat:15s} [{bar}] {done}/{total}")

        total_done = sum(d for d, t in cat_stats.values())
        total_all = sum(t for d, t in cat_stats.values())
        print(f"\n  Total: {total_done}/{total_all}")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Est. cost: ${self.progress.get('cost_total', 0):.2f}")
        print(f"  Output: {self.output_dir}/")


def main():
    parser = argparse.ArgumentParser(description="Necromancer Terrain Tile Generator v2")
    parser.add_argument("--test", action="store_true", help="Generate 8 test samples for review")
    parser.add_argument("--all", action="store_true", help="Generate all terrain tiles")
    parser.add_argument("--category", type=str, help="Generate specific category")
    parser.add_argument("--status", action="store_true", help="Show progress status")
    parser.add_argument("--darken", action="store_true", help="Generate dark variants from existing")
    args = parser.parse_args()

    if args.status:
        api_key = os.environ.get("OPENAI_API_KEY", "dummy")
        gen = TerrainGenerator(api_key)
        gen.show_status()
        return

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found in environment or .env file")
        sys.exit(1)

    gen = TerrainGenerator(api_key)

    if args.darken:
        gen.generate_dark_variants_only()
    elif args.test:
        gen.generate_test_samples()
    elif args.all:
        gen.generate_all()
    elif args.category:
        gen.generate_category(args.category)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
