#!/usr/bin/env python3
"""
Regenerate environmental tiles with Microchasm-style visual clarity.

Design principles:
- Floors: Light, flat, simple - BACKGROUND that recedes
- Walls: Dark, solid, clearly blocking - BARRIERS
- Darkness: Pure black - ABSENCE of light
- Hazards: Distinct colors with clear edges
- NO dramatic baked-in lighting/shadows
- Top-down view, tileable where appropriate
"""

import os
import json
import time
import requests
from pathlib import Path
from PIL import Image
import numpy as np
from io import BytesIO

PROJECT_ROOT = Path(__file__).parent.parent.parent
GRAF_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = GRAF_DIR / "final"
WIP_DIR = GRAF_DIR / "wip"
MANIFEST_PATH = GRAF_DIR / "sprite_manifest.json"

# Get API key
OPENAI_API_KEY = ""
try:
    with open(Path(__file__).parent / "generate_all.py", 'r') as f:
        import re
        match = re.search(r'OPENAI_API_KEY\s*=\s*["\']([^"\']+)["\']', f.read())
        if match:
            OPENAI_API_KEY = match.group(1)
except:
    pass

# Cleaner base template for environment tiles
ENV_TEMPLATE = """{description}

CRITICAL STYLE REQUIREMENTS:
- 64x64 pixel art tile, TOP-DOWN view
- FLAT lighting - no dramatic shadows or 3D perspective
- Solid magenta background (#FF00FF) for removal
- Simple, clean, tileable design
- Muted colors - gray/brown/earth tones for stone
- This is a BACKGROUND tile - it should NOT draw attention
- Think classic roguelike tileset: Dungeon Crawl Stone Soup, Microchasm
- NO color swatches, NO borders, NO text"""

# Environmental tiles to regenerate with BETTER prompts
ENVIRONMENT_TILES = [
    # DARKNESS - should be pure black
    {
        "id": "F:0",
        "name": "Darkness",
        "filename": "terrain/t_00_darkness",
        "description": """Unexplored dungeon darkness tile.
PURE BLACK or very dark gray solid fill.
No features, no patterns, no glow - just absence of light.
This represents areas the player hasn't seen yet.
Completely flat and uniform."""
    },

    # STONE FLOOR - simple background
    {
        "id": "F:1",
        "name": "Stone Floor",
        "filename": "terrain/t_01_stone_floor",
        "description": """Basic dungeon stone floor tile.
Light gray cobblestones or flagstones.
Simple grid pattern, very subtle texture.
FLAT - no 3D perspective, no dramatic shadows.
Neutral, boring, background - characters should stand out against this.
Tileable pattern. Think classic roguelike floor."""
    },

    # DARK STONE WALL - clearly blocking
    {
        "id": "F:56",
        "name": "Dark Stone Wall",
        "filename": "terrain/t_56_dark_stone_wall",
        "description": """Dungeon wall tile - IMPASSABLE barrier.
Dark gray or charcoal stone blocks.
Clearly DARKER than floor tiles.
Solid, blocky appearance - obviously can't walk through.
Simple brick/block pattern, minimal detail.
Must contrast strongly with lighter floor tiles."""
    },

    # FADING DAYLIGHT - warmer floor variant
    {
        "id": "F:9",
        "name": "Fading Daylight",
        "filename": "terrain/t_09_fading_daylight",
        "description": """Stone floor with hint of daylight.
Same as basic floor but slightly warmer tone.
Light gray with subtle yellow/tan tint.
Represents area near dungeon entrance.
Still flat and simple, just warmer color."""
    },

    # VINE FLOOR - floor with organic overlay
    {
        "id": "F:86",
        "name": "Vine Floor",
        "filename": "terrain/t_86_vine_floor",
        "description": """Stone floor with creeping vines.
Light gray floor base with dark green vine tendrils.
Vines as overlay, floor still clearly visible.
Obviously still WALKABLE floor, just decorated.
Forest area aesthetic."""
    },

    # FOREST FLOOR - natural ground
    {
        "id": "F:87",
        "name": "Forest Floor",
        "filename": "terrain/t_87_forest_floor",
        "description": """Natural outdoor ground tile.
Brown earth with scattered leaves.
Flat, simple, natural texture.
Clearly WALKABLE ground, outdoor area.
Earthy brown/tan colors, no dramatic lighting."""
    },

    # BLOODSTAIN - floor with blood
    {
        "id": "F:31",
        "name": "Bloodstain",
        "filename": "terrain/t_31_bloodstain",
        "description": """Stone floor with dried blood.
Light gray floor with dark red stain.
Blood as splatter/pool overlay on floor.
Still clearly recognizable as floor tile.
Ominous but simple."""
    },

    # DARK POOL - water hazard
    {
        "id": "F:12",
        "name": "Dark Pool",
        "filename": "terrain/t_12_dark_pool",
        "description": """Pool of dark water in dungeon.
Dark blue/black water surface.
Still, reflective appearance.
Clear edges showing pool boundary.
Obviously different from floor - a HAZARD."""
    },

    # POISON STREAM - clearly toxic
    {
        "id": "F:84",
        "name": "Poison Stream",
        "filename": "terrain/t_84_poison_stream",
        "description": """Flowing toxic liquid.
Bright green poisonous water.
Clear, distinct color - obviously DANGEROUS.
Simple flowing pattern.
Strong contrast with gray stone surroundings."""
    },

    # HIDDEN PASSAGE - wall that's secretly passable
    {
        "id": "F:48",
        "name": "Hidden Passage",
        "filename": "terrain/t_48_hidden_passage",
        "description": """Secret door disguised as wall.
Looks like wall but with subtle crack/seam.
Dark gray like wall, but with hairline gap visible.
Player might notice it's slightly different.
Mostly looks like F:56 wall but with hint."""
    },

    # TANGLED ROOTS - organic wall
    {
        "id": "F:85",
        "name": "Tangled Roots",
        "filename": "terrain/t_85_tangled_roots",
        "description": """Wall of tangled tree roots.
Brown twisted roots forming barrier.
Clearly IMPASSABLE like a wall.
Dark brown, organic texture.
Forest area wall equivalent."""
    },

    # OPEN DOOR - passable doorway
    {
        "id": "F:4",
        "name": "Open Door",
        "filename": "terrain/t_04_open_door",
        "description": """Open wooden door in stone frame.
Door swung to side, passage clear.
Stone doorframe visible, wooden door open.
Obviously PASSABLE - shows walkable path.
Simple, clear design."""
    },

    # IRON DOOR - closed metal door
    {
        "id": "F:32",
        "name": "Iron Door",
        "filename": "terrain/t_32_iron_door",
        "description": """Closed iron dungeon door.
Dark metal door in stone frame.
Clearly CLOSED and blocking.
Simple iron bands/rivets pattern.
Must be opened to pass."""
    },

    # STAIRS UP
    {
        "id": "F:80",
        "name": "Stairs Up",
        "filename": "terrain/t_80_stairs_up",
        "description": """Stone stairs going upward.
Gray stone steps, ascending.
Clear < or upward arrow indication.
Simple, obvious stairs going UP.
Flat top-down representation."""
    },

    # STAIRS DOWN
    {
        "id": "F:81",
        "name": "Stairs Down",
        "filename": "terrain/t_81_stairs_down",
        "description": """Stone stairs going downward.
Gray stone steps, descending into dark.
Clear > or downward arrow indication.
Simple, obvious stairs going DOWN.
Flat top-down representation."""
    },
]


def remove_background(img):
    """Remove magenta and create clean transparency."""
    data = np.array(img.convert("RGBA"))

    # Simple magenta removal
    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]

    # Magenta and pink variants
    is_magenta = (r > 200) & (g < 100) & (b > 200)
    is_pink = (r > 150) & (g < 80) & (b > 150)

    mask = is_magenta | is_pink
    data[mask] = [0, 0, 0, 0]

    return Image.fromarray(data, "RGBA")


def generate_tile(tile_def, api_key):
    """Generate a single tile using DALL-E 3."""
    prompt = ENV_TEMPLATE.format(description=tile_def["description"])

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "quality": "standard",  # Standard quality for cleaner results
        "response_format": "url"
    }

    response = requests.post(
        "https://api.openai.com/v1/images/generations",
        headers=headers,
        json=payload,
        timeout=120
    )

    if response.status_code != 200:
        raise Exception(f"API error: {response.status_code} - {response.text}")

    result = response.json()
    image_url = result["data"][0]["url"]

    img_response = requests.get(image_url, timeout=60)
    img = Image.open(BytesIO(img_response.content))

    return img


def process_tile(img, target_size=64):
    """Process to final size with clean transparency."""
    img = remove_background(img)

    # Resize directly - environment tiles should fill the frame
    img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)

    return img


def main():
    if not OPENAI_API_KEY:
        print("ERROR: No OpenAI API key found!")
        return

    print("=" * 60)
    print("REGENERATING ENVIRONMENTAL TILES")
    print("=" * 60)
    print(f"Tiles to regenerate: {len(ENVIRONMENT_TILES)}")
    print()

    generated = 0
    failed = []

    for tile in ENVIRONMENT_TILES:
        tile_id = tile["id"]
        name = tile["name"]
        filename = tile["filename"]

        print(f"  Generating {tile_id} - {name}...")

        try:
            raw_img = generate_tile(tile, OPENAI_API_KEY)

            # Save preview
            preview_name = filename.split('/')[-1] + "_v2_preview.png"
            preview_path = WIP_DIR / preview_name
            preview_path.parent.mkdir(parents=True, exist_ok=True)
            preview = raw_img.resize((256, 256), Image.Resampling.LANCZOS)
            preview.save(preview_path)

            # Process to 64x64
            final_img = process_tile(raw_img)

            # Save final
            final_name = filename.split('/')[-1] + ".png"
            final_path = FINAL_DIR / "terrain" / final_name
            final_path.parent.mkdir(parents=True, exist_ok=True)
            final_img.save(final_path)

            generated += 1
            print(f"    ✓ Saved to {final_name}")

            # Rate limit
            time.sleep(12)

        except Exception as e:
            print(f"    ✗ Failed: {e}")
            failed.append((tile_id, name, str(e)))

            # If billing limit, stop
            if "billing" in str(e).lower():
                print("\n  API billing limit reached - stopping")
                break

    print()
    print("=" * 60)
    print(f"Generated: {generated}")
    print(f"Failed: {len(failed)}")

    if failed:
        print("\nFailed tiles:")
        for tid, name, err in failed:
            print(f"  {tid} - {name}")


if __name__ == "__main__":
    main()
