#!/usr/bin/env python3
"""
Environment Tile Generator for The Necromancer

Generates environment tiles (floors, walls, doors, stairs) that fill 100% of
the tile frame with NO borders. This fixes the black gap problem caused by
the original 80% fill sprites.

Key differences from generate_all.py:
- Uses edge-to-edge prompts (no magenta background)
- Generates at 1024x1024 and downscales to 64x64 for quality
- No auto-crop or centering (tiles must fill entire frame)
- Interactive review loop for each tile
"""

import os
import io
import json
import time
import requests
import sys
from pathlib import Path
from datetime import datetime
from PIL import Image
from openai import OpenAI

# =============================================================================
# CONFIGURATION
# =============================================================================
# API key loaded from environment or hardcoded fallback
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")

PROJECT_ROOT = Path(__file__).parent.parent.parent
OUTPUT_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
TERRAIN_DIR = OUTPUT_DIR / "final" / "terrain"
WIP_DIR = OUTPUT_DIR / "wip" / "environment"
TILESET_PATH = OUTPUT_DIR / "64x64_necromancer.png"
MANIFEST_PATH = OUTPUT_DIR / "environment_manifest.json"

TARGET_SIZE = 64
GENERATE_SIZE = 1024  # DALL-E minimum, downscale for quality
RATE_LIMIT_DELAY = 13  # seconds between API calls (5/min limit)

# =============================================================================
# ENVIRONMENT TILE TEMPLATES
# =============================================================================
FLOOR_TEMPLATE = """A seamless tileable dungeon floor texture for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders, padding, or empty space around edges
- Seamless tiling pattern (edges must match for infinite tiling)
- Top-down orthographic view
- Dark fantasy dungeon aesthetic (Dol Guldur style)
- Subtle texture variation, not flat color
- Must look good at 32x32 and 64x64 display sizes
- No characters, objects, or UI elements
- Consistent medieval/fantasy dungeon style
- Muted earth tones with occasional accent"""

WALL_TEMPLATE = """A dungeon wall tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders, padding, or empty space
- Dark stone/brick aesthetic
- Top-down or hybrid view showing wall face
- Should visually block and look solid
- Must look good at 32x32 and 64x64 display sizes
- DARKER than floor tiles for clear contrast
- No characters or UI elements
- Dark fantasy style (Dol Guldur)"""

DOOR_TEMPLATE = """A dungeon door tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders or empty space
- Shows door from top-down dungeon view
- Must be clearly recognizable as a door
- Medieval iron and wood aesthetic
- Stone frame visible around door
- Must look good at 32x32 and 64x64 display sizes
- No characters or UI elements"""

STAIRS_TEMPLATE = """Dungeon stairs tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders or empty space
- Top-down view showing stairs
- Clear directional indication (up or down)
- Stone construction
- Must look good at 32x32 and 64x64 display sizes
- No characters or UI elements
- Dark fantasy style"""

SPECIAL_TEMPLATE = """A dungeon special feature tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders or empty space
- Top-down or hybrid dungeon view
- Must be clearly identifiable
- Dark fantasy dungeon aesthetic
- Must look good at 32x32 and 64x64 display sizes
- No characters or UI elements"""

# =============================================================================
# ENVIRONMENT TILES TO GENERATE
# =============================================================================
# Core 8 tiles for first batch
CORE_TILES = [
    {
        "id": "F:1",
        "name": "Stone Floor",
        "filename": "t_01_stone_floor",
        "grid_pos": (0, 1),
        "type": "floor",
        "description": """Gray weathered flagstone dungeon floor. Ancient stone worn smooth by ages of use. Subtle cracks between stones. Occasional moss or lichen in joints. Neutral gray tone that serves as background for characters. Individual stone blocks visible but not distracting."""
    },
    {
        "id": "F:0",
        "name": "Darkness",
        "filename": "t_00_darkness",
        "grid_pos": (0, 0),
        "type": "special",
        "description": """Pure impenetrable darkness representing unexplored dungeon areas. Very dark void - solid black or extremely dark purple-black. No features visible. Complete absence of light. Represents fog of war / unexplored territory."""
    },
    {
        "id": "F:56",
        "name": "Dark Stone Wall",
        "filename": "t_56_dark_stone_wall",
        "grid_pos": (1, 0),
        "type": "wall",
        "description": """Solid dark stone dungeon wall blocks. Ancient hewn stone masonry. Darker than floor tiles - clearly impassable barrier. Slight moss or age weathering. Gray-black tone. Individual stone blocks with mortar lines visible."""
    },
    {
        "id": "F:32",
        "name": "Iron Door (Closed)",
        "filename": "t_32_iron_door",
        "grid_pos": (1, 4),
        "type": "door",
        "description": """Heavy iron-bound wooden dungeon door, closed. Dark oak planks reinforced with iron bands and rivets. Large iron studs. Imposing and locked appearance. Stone doorframe visible. Clearly blocks passage."""
    },
    {
        "id": "F:4",
        "name": "Open Door",
        "filename": "t_04_open_door",
        "grid_pos": (1, 5),
        "type": "door",
        "description": """Stone doorframe with open passage. The door is swung aside or removed. Shows passable opening - darker in center where passage is. Wooden door visible to one side. Stone frame prominent."""
    },
    {
        "id": "F:80",
        "name": "Stairs Up",
        "filename": "t_80_stairs_up",
        "grid_pos": (2, 0),
        "type": "stairs",
        "description": """Stone stairs ascending upward out of dungeon. Carved stone steps leading up - lighter at the top suggesting destination. Multiple visible steps. Arrow or visual indication of 'up' direction helpful. Light source from above."""
    },
    {
        "id": "F:81",
        "name": "Stairs Down",
        "filename": "t_81_stairs_down",
        "grid_pos": (2, 1),
        "type": "stairs",
        "description": """Stone stairs descending into deeper darkness. Carved stone steps leading down into shadow - darker at bottom. Multiple visible steps. Ominous descent. Opposite visual treatment from stairs up."""
    },
    {
        "id": "F:9",
        "name": "Fading Daylight",
        "filename": "t_09_fading_daylight",
        "grid_pos": (0, 2),
        "type": "floor",
        "description": """Stone floor with warm golden-orange tint from fading sunlight. Near dungeon entrance with some natural light filtering in. Same flagstone texture as regular floor but with warm orange-yellow highlights. Slightly lighter and warmer than regular stone floor. Must tile seamlessly."""
    },
]

# Extended tiles for full regeneration
EXTENDED_TILES = [
    # Additional floors
    {
        "id": "F:31",
        "name": "Bloodstain",
        "filename": "t_31_bloodstain",
        "grid_pos": (0, 3),
        "type": "floor",
        "description": """Stone floor with dried blood stains. Dark red-brown dried blood splattered on gray flagstone. Signs of violence. Ominous atmosphere. Stone texture still visible beneath blood."""
    },
    {
        "id": "F:86",
        "name": "Vine Floor",
        "filename": "t_86_vine_floor",
        "grid_pos": (0, 4),
        "type": "floor",
        "description": """Stone floor partially covered by creeping dark green vines. Forest breach area aesthetic. Organic growth over ancient stone. Nature reclaiming the dungeon."""
    },
    {
        "id": "F:2",
        "name": "Bottomless Pit",
        "filename": "t_02_bottomless_pit",
        "grid_pos": (0, 5),
        "type": "special",
        "description": """A gaping bottomless pit in the dungeon floor. Dark void in center. Jagged rocky edges around the hole. Pure black center representing infinite depth. Clearly deadly fall hazard."""
    },
    {
        "id": "F:3",
        "name": "Protective Rune",
        "filename": "t_03_protective_rune",
        "grid_pos": (0, 6),
        "type": "special",
        "description": """Stone floor with glowing green protective magical rune. Circular ward pattern carved into stone. Green magical glow emanating from the symbol. Safe haven indicator. Stone floor visible around rune."""
    },
    {
        "id": "F:87",
        "name": "Forest Floor",
        "filename": "t_87_forest_floor",
        "grid_pos": (0, 7),
        "type": "floor",
        "description": """Natural outdoor forest floor. Brown earth with fallen leaves and twigs. Organic natural ground texture. Outdoor area near dungeon entrance. Earth tones, leaf litter, small stones."""
    },
    {
        "id": "F:84",
        "name": "Poison Stream",
        "filename": "t_84_poison_stream",
        "grid_pos": (0, 8),
        "type": "special",
        "description": """Flowing stream of bright green toxic poison. Bubbling, steaming poisonous liquid. Clearly dangerous to touch. Bright sickly green color. Stream flows across stone floor."""
    },
    # Additional walls/doors
    {
        "id": "F:48",
        "name": "Hidden Passage",
        "filename": "t_48_hidden_passage",
        "grid_pos": (1, 1),
        "type": "wall",
        "description": """Secret door disguised as stone wall. Looks mostly like regular wall but with subtle crack or seam hinting at hidden passage. Player might notice the difference if looking closely. Same dark stone as wall but with slight irregularity."""
    },
    {
        "id": "F:85",
        "name": "Tangled Roots",
        "filename": "t_85_tangled_roots",
        "grid_pos": (1, 2),
        "type": "wall",
        "description": """Thick tangled roots forming an impassable wall. Organic barrier of twisted tree roots. Dark brown and green. Forest breach area obstacle. Clearly blocks movement."""
    },
    {
        "id": "F:29",
        "name": "Prison Bars",
        "filename": "t_29_prison_bars",
        "grid_pos": (1, 3),
        "type": "wall",
        "description": """Iron prison bars with gaps between. Vertical iron bars blocking passage. Can see through but cannot pass. Dark iron with rust spots. Dungeon prison aesthetic."""
    },
    {
        "id": "F:5",
        "name": "Shattered Door",
        "filename": "t_05_shattered_door",
        "grid_pos": (1, 6),
        "type": "door",
        "description": """Broken destroyed door with debris. Door smashed to pieces. Splintered wood scattered on floor. Signs of violence. Passage is open through destruction. Stone doorframe damaged."""
    },
    {
        "id": "F:6",
        "name": "Warded Door",
        "filename": "t_06_warded_door",
        "grid_pos": (1, 7),
        "type": "door",
        "description": """Magically warded door with glowing runes. Closed door with green-blue magical symbols. Enchanted protection visible. Special door requiring magic or key. Runes glow faintly."""
    },
    {
        "id": "F:7",
        "name": "Warded Door Power 2",
        "filename": "t_07_warded_door_2",
        "grid_pos": (1, 8),
        "type": "door",
        "description": """Magically warded door with stronger enchantment. Blue magical runes glowing more intensely than basic warded door. More powerful ward. Same door structure with brighter magic."""
    },
    {
        "id": "F:8",
        "name": "Warded Door Power 3",
        "filename": "t_08_warded_door_3",
        "grid_pos": (1, 9),
        "type": "door",
        "description": """Heavily warded door with most powerful enchantment. Intense purple magical runes swirling around door. Nearly impenetrable magical barrier. Maximum power ward."""
    },
    {
        "id": "F:30",
        "name": "Chains",
        "filename": "t_30_chains",
        "grid_pos": (1, 10),
        "type": "wall",
        "description": """Heavy iron chains hanging from ceiling. Dungeon decoration and hazard. Rusty iron links. Clanking obstacle. Top-down view showing chains over floor space."""
    },
    # Stairs and special
    {
        "id": "F:82",
        "name": "Shaft Up",
        "filename": "t_82_shaft_up",
        "grid_pos": (2, 2),
        "type": "stairs",
        "description": """Narrow vertical shaft going upward. Rough narrow passage climbing up. More cramped than stairs. Rope or ladder might be needed. Dark hole with light above."""
    },
    {
        "id": "F:83",
        "name": "Shaft Down",
        "filename": "t_83_shaft_down",
        "grid_pos": (2, 3),
        "type": "stairs",
        "description": """Narrow vertical shaft going downward. Dark narrow hole descending into depths. More cramped than stairs. Dangerous vertical descent. Pure darkness below."""
    },
    {
        "id": "F:64",
        "name": "Orc Forge",
        "filename": "t_64_orc_forge",
        "grid_pos": (2, 4),
        "type": "special",
        "description": """Crude orc forge for crafting. Anvil and glowing embers. Iron tools scattered around. Functional but rough construction. Orange glow from hot coals. Interactive crafting location."""
    },
    {
        "id": "F:12",
        "name": "Dark Pool",
        "filename": "t_12_dark_pool",
        "grid_pos": (2, 5),
        "type": "special",
        "description": """Pool of dark still water in stone basin. Black reflective water surface. Ominous depth. Stone edge around pool. Mysterious and possibly dangerous. Could contain something."""
    },
    {
        "id": "F:13",
        "name": "Morgul Runes",
        "filename": "t_13_morgul_runes",
        "grid_pos": (2, 6),
        "type": "special",
        "description": """Floor with glowing Morgul runes carved into stone. Evil magical writing. Purple-violet glow. Dangerous dark magic. Clearly magical hazard area. Fell script of Mordor."""
    },
    {
        "id": "F:14",
        "name": "Shadow Brazier",
        "filename": "t_14_shadow_brazier",
        "grid_pos": (2, 7),
        "type": "special",
        "description": """Iron brazier with dark purple shadow flames. Evil light source. Dark wisps emanating from flames. Provides dim eerie light. Unnatural fire."""
    },
    {
        "id": "F:15",
        "name": "Torture Rack",
        "filename": "t_15_torture_rack",
        "grid_pos": (2, 8),
        "type": "special",
        "description": """Wooden torture device with chains and straps. Dungeon horror element. Dark stained wood and rusty metal. Sinister device. Top-down view of torture rack on stone floor."""
    },
]

# Combine for full set
ALL_ENVIRONMENT_TILES = CORE_TILES + EXTENDED_TILES

# =============================================================================
# MANIFEST MANAGEMENT
# =============================================================================
def load_manifest():
    """Load or create the environment manifest"""
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, 'r') as f:
            return json.load(f)
    return {
        "version": "1.0",
        "target_size": TARGET_SIZE,
        "created": datetime.now().isoformat(),
        "tiles": {}
    }

def save_manifest(manifest):
    """Save the manifest"""
    manifest["updated"] = datetime.now().isoformat()
    with open(MANIFEST_PATH, 'w') as f:
        json.dump(manifest, f, indent=2)

# =============================================================================
# IMAGE GENERATION
# =============================================================================
def get_template_for_type(tile_type):
    """Return the appropriate template for tile type"""
    templates = {
        "floor": FLOOR_TEMPLATE,
        "wall": WALL_TEMPLATE,
        "door": DOOR_TEMPLATE,
        "stairs": STAIRS_TEMPLATE,
        "special": SPECIAL_TEMPLATE
    }
    return templates.get(tile_type, SPECIAL_TEMPLATE)

def generate_tile(client, tile_data):
    """Generate a tile using DALL-E 3"""
    template = get_template_for_type(tile_data["type"])
    prompt = template.format(description=tile_data["description"])

    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="hd",
            n=1,
            response_format="url"
        )

        image_url = response.data[0].url
        revised_prompt = response.data[0].revised_prompt

        # Download the image
        img_response = requests.get(image_url, timeout=60)
        img = Image.open(io.BytesIO(img_response.content))

        return img, revised_prompt, None

    except Exception as e:
        return None, None, str(e)

def process_environment_tile(img, target_size=64):
    """Process environment tile - downscale only, NO cropping or centering"""
    # Convert to RGBA
    img = img.convert("RGBA")

    # High-quality downscale from 1024 to 64
    # Use LANCZOS for best quality downscaling
    processed = img.resize((target_size, target_size), Image.Resampling.LANCZOS)

    return processed

# =============================================================================
# TILESET INTEGRATION
# =============================================================================
def update_tileset(tile_data, tile_img):
    """Update a single tile in the main tileset"""
    if not TILESET_PATH.exists():
        print(f"  WARNING: Tileset not found at {TILESET_PATH}")
        return False

    row, col = tile_data["grid_pos"]

    # Load existing tileset
    tileset = Image.open(TILESET_PATH).convert('RGBA')

    # Calculate position
    x = col * TARGET_SIZE
    y = row * TARGET_SIZE

    # Paste the new tile
    tileset.paste(tile_img, (x, y))

    # Save updated tileset
    tileset.save(TILESET_PATH)

    return True

# =============================================================================
# INTERACTIVE GENERATION
# =============================================================================
def generate_single_tile(client, tile_data, manifest, auto_approve=False):
    """Generate a single tile with interactive review"""
    tile_id = tile_data["id"]
    tile_name = tile_data["name"]
    tile_type = tile_data["type"]
    filename = tile_data["filename"]

    # Check if already completed
    if tile_id in manifest.get("tiles", {}):
        status = manifest["tiles"][tile_id].get("status")
        if status == "completed":
            print(f"  [SKIP] {tile_name} - already completed")
            return True

    print(f"\n{'='*60}")
    print(f"Generating: {tile_name} ({tile_id})")
    print(f"Type: {tile_type}")
    print(f"Grid position: {tile_data['grid_pos']}")
    print(f"{'='*60}")

    attempt = 0
    max_attempts = 5

    while attempt < max_attempts:
        attempt += 1
        print(f"\n  Attempt {attempt}/{max_attempts}...")
        print(f"  Waiting {RATE_LIMIT_DELAY}s for rate limit...")
        time.sleep(RATE_LIMIT_DELAY)

        # Generate
        img, revised_prompt, error = generate_tile(client, tile_data)

        if error:
            print(f"  ERROR: {error}")
            continue

        # Process (downscale only)
        processed = process_environment_tile(img, TARGET_SIZE)

        # Ensure output directories exist
        TERRAIN_DIR.mkdir(parents=True, exist_ok=True)
        WIP_DIR.mkdir(parents=True, exist_ok=True)

        # Save files
        output_path = TERRAIN_DIR / f"{filename}.png"
        processed.save(output_path)

        # Save full-size for reference
        wip_full = WIP_DIR / f"{filename}_1024.png"
        img.save(wip_full)

        # Save 4x preview
        preview = processed.resize((256, 256), Image.Resampling.NEAREST)
        preview_path = WIP_DIR / f"{filename}_preview.png"
        preview.save(preview_path)

        print(f"\n  Generated files:")
        print(f"    Final: {output_path}")
        print(f"    Full:  {wip_full}")
        print(f"    Preview: {preview_path}")

        if auto_approve:
            approved = True
        else:
            # Interactive review
            print(f"\n  REVIEW: Check the preview at {preview_path}")
            print(f"  Does this tile:")
            print(f"    1. Fill the entire frame with NO borders?")
            print(f"    2. Match the dungeon aesthetic?")
            print(f"    3. Look good at small sizes?")

            response = input("\n  Approve? [y/n/q]: ").strip().lower()

            if response == 'q':
                print("  Quitting...")
                sys.exit(0)

            approved = response == 'y'

        if approved:
            # Update manifest
            manifest["tiles"][tile_id] = {
                "status": "completed",
                "name": tile_name,
                "type": tile_type,
                "filename": str(output_path.relative_to(OUTPUT_DIR)),
                "grid_pos": tile_data["grid_pos"],
                "attempts": attempt,
                "completed": datetime.now().isoformat()
            }
            save_manifest(manifest)

            # Update tileset
            if update_tileset(tile_data, processed):
                print(f"  Updated tileset at position {tile_data['grid_pos']}")

            print(f"  SUCCESS: {tile_name} completed!")
            return True
        else:
            print(f"  Regenerating...")

    print(f"  FAILED after {max_attempts} attempts")
    manifest["tiles"][tile_id] = {
        "status": "failed",
        "name": tile_name,
        "type": tile_type,
        "attempts": max_attempts,
        "failed": datetime.now().isoformat()
    }
    save_manifest(manifest)
    return False

def main():
    """Main generation loop"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate environment tiles for The Necromancer')
    parser.add_argument('--core-only', action='store_true', help='Generate only the 8 core tiles')
    parser.add_argument('--auto', action='store_true', help='Auto-approve all tiles (no interactive review)')
    parser.add_argument('--tile', type=str, help='Generate specific tile by ID (e.g., F:1)')
    parser.add_argument('--api-key', type=str, help='OpenAI API key')
    args = parser.parse_args()

    print("=" * 70)
    print("NECROMANCER ENVIRONMENT TILE GENERATOR")
    print("=" * 70)

    # Get API key
    api_key = args.api_key or OPENAI_API_KEY
    if not api_key:
        print("\nERROR: No OpenAI API key provided.")
        print("Set OPENAI_API_KEY environment variable or use --api-key")
        sys.exit(1)

    # Setup
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    TERRAIN_DIR.mkdir(parents=True, exist_ok=True)
    WIP_DIR.mkdir(parents=True, exist_ok=True)

    client = OpenAI(api_key=api_key)
    manifest = load_manifest()

    # Select tiles to generate
    if args.tile:
        tiles = [t for t in ALL_ENVIRONMENT_TILES if t["id"] == args.tile]
        if not tiles:
            print(f"ERROR: Tile {args.tile} not found")
            print(f"Available tiles: {[t['id'] for t in ALL_ENVIRONMENT_TILES]}")
            sys.exit(1)
    elif args.core_only:
        tiles = CORE_TILES
    else:
        tiles = ALL_ENVIRONMENT_TILES

    print(f"\nTarget: {len(tiles)} environment tiles at {TARGET_SIZE}x{TARGET_SIZE}")
    print(f"Output: {TERRAIN_DIR}")
    print(f"Tileset: {TILESET_PATH}")

    # Count status
    completed = sum(1 for t in tiles if manifest.get("tiles", {}).get(t["id"], {}).get("status") == "completed")
    print(f"Already completed: {completed}")
    print(f"Remaining: {len(tiles) - completed}")

    if not args.auto:
        print("\n" + "-" * 70)
        print("INTERACTIVE MODE")
        print("For each tile, you'll be asked to approve or regenerate.")
        print("Use --auto flag to skip interactive review.")
        input("\nPress Enter to start...")

    # Generate tiles
    success_count = 0
    fail_count = 0

    for i, tile_data in enumerate(tiles):
        print(f"\n[{i+1}/{len(tiles)}]")

        if generate_single_tile(client, tile_data, manifest, auto_approve=args.auto):
            success_count += 1
        else:
            fail_count += 1

    # Final summary
    print("\n" + "=" * 70)
    print("GENERATION COMPLETE")
    print("=" * 70)
    print(f"Total: {len(tiles)}")
    print(f"Successful: {success_count}")
    print(f"Failed: {fail_count}")
    print(f"\nOutput: {TERRAIN_DIR}")
    print(f"Tileset: {TILESET_PATH}")

    if success_count > 0:
        print("\n" + "-" * 70)
        print("NEXT STEPS:")
        print("-" * 70)
        print("1. Copy tileset to app bundle:")
        print(f'   cp "{TILESET_PATH}" "Necromancer.app/Contents/Resources/lib/xtra/graf/"')
        print("2. Clear cache:")
        print('   rm -rf ~/Documents/Sil/Sil-Q/data/*.raw')
        print("3. Build and test:")
        print('   cd hardfork && make -f Makefile.hardfork ARCHS=arm64 install')
        print("4. Launch game and verify tiles")

if __name__ == "__main__":
    main()
