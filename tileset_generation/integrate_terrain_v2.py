#!/usr/bin/env python3
"""
Integrate terrain_v2 DALL-E generated sprites into the tileset pipeline.

Steps:
1. Copy terrain_v2 sprites into staging/terrain/ (replacing old DCSS tiles)
2. Fill forge charge variants (all orc forge → ID 65, shadow forge → 70/71, angdur → 76/77)
3. Fill missing terrain IDs with nearest available fallback
4. Run the assembler to build the 2048x2048 tileset
5. Generate updated tile_mapper.gd from layout_map.json
"""

import json
import shutil
from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).parent
PROJECT_ROOT = BASE_DIR.parent
STAGING_TERRAIN = BASE_DIR / "staging" / "terrain"
TERRAIN_V2 = BASE_DIR / "terrain_v2"
LAYOUT_PATH = BASE_DIR / "layout_map.json"
TILESET_OUTPUT = PROJECT_ROOT / "assets" / "sprites" / "necromancer_dcss_tileset.png"
TILE_MAPPER_PATH = PROJECT_ROOT / "scripts" / "core" / "tile_mapper.gd"

TILE_SIZE = 64
GRID_SIZE = 32
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048

# Forge variant mappings: map charge variants to base sprite
# User said: "64s suck, use 65 for all orc forge"
FORGE_MAPPINGS = {
    # Orc forge: all states → use active (65)
    64: 65, 66: 65, 67: 65, 68: 65, 69: 65,
    # Shadow forge: exhausted=70, active variants → 71
    72: 71, 73: 71, 74: 71, 75: 71,
    # Forge Angdur: exhausted=76, active variants → 77
    78: 77, 79: 77,
}

# Terrain IDs that don't exist in the game (unused placeholders in terrain.txt)
# These have no generated sprites - use wall (11) or floor (1) as fallback
UNUSED_TERRAIN_FALLBACKS = {
    33: 11, 34: 11, 35: 11, 36: 11, 37: 11,
    38: 11, 39: 11, 40: 11, 41: 11, 42: 11,
    43: 11, 44: 11, 45: 11, 46: 11, 47: 11,
    50: 11, 52: 11, 53: 11, 54: 11, 55: 11,
    60: 11, 61: 11, 62: 11,
}


def copy_terrain_v2_to_staging():
    """Copy all terrain_v2 sprites into staging/terrain/."""
    print("=== Step 1: Copy terrain_v2 → staging/terrain/ ===")
    copied = 0

    # Walk all subdirectories in terrain_v2
    for category_dir in TERRAIN_V2.iterdir():
        if not category_dir.is_dir() or category_dir.name == "raw":
            continue
        for png_file in category_dir.glob("terrain_*_*.png"):
            if ".import" in png_file.name:
                continue
            dest = STAGING_TERRAIN / png_file.name
            shutil.copy2(png_file, dest)
            copied += 1

    print(f"  Copied {copied} sprites from terrain_v2 → staging/terrain/")
    return copied


def fill_forge_variants():
    """Copy forge base sprites to fill all charge variant slots."""
    print("\n=== Step 2: Fill forge charge variants ===")
    filled = 0

    for variant_id, base_id in FORGE_MAPPINGS.items():
        for suffix in ["light", "dark"]:
            src = STAGING_TERRAIN / f"terrain_{base_id}_{suffix}.png"
            dst = STAGING_TERRAIN / f"terrain_{variant_id}_{suffix}.png"
            if src.exists():
                shutil.copy2(src, dst)
                filled += 1
            else:
                print(f"  WARNING: Base sprite missing: {src.name}")

    print(f"  Filled {filled} forge variant slots")
    return filled


def fill_unused_terrain():
    """Fill unused terrain IDs with fallback sprites."""
    print("\n=== Step 3: Fill unused terrain IDs ===")
    filled = 0

    for unused_id, fallback_id in UNUSED_TERRAIN_FALLBACKS.items():
        for suffix in ["light", "dark"]:
            src = STAGING_TERRAIN / f"terrain_{fallback_id}_{suffix}.png"
            dst = STAGING_TERRAIN / f"terrain_{unused_id}_{suffix}.png"
            if src.exists() and not dst.exists():
                shutil.copy2(src, dst)
                filled += 1

    print(f"  Filled {filled} unused terrain slots with fallbacks")
    return filled


def assemble_tileset():
    """Build the final 2048x2048 tileset from staging + layout_map.json."""
    print("\n=== Step 4: Assemble tileset ===")

    with open(LAYOUT_PATH, 'r') as f:
        layout = json.load(f)

    coordinates = layout.get('coordinates', {})

    # Create blank tileset (black background for transparency)
    tileset = Image.new('RGBA', (TILESET_SIZE, TILESET_SIZE), (0, 0, 0, 255))

    stats = {'found': 0, 'missing': 0, 'errors': []}
    missing_keys = []

    # Category → staging subdirectory mapping
    category_dirs = {
        'terrain': 'terrain',
        'monster': 'monsters',
        'item': 'items',
        'artifact': 'artifacts',
        'player': 'players',
        'effect': 'effects',
    }

    for entity_key, coord in coordinates.items():
        x = coord['x'] * TILE_SIZE
        y = coord['y'] * TILE_SIZE

        # Parse category from key
        parts = entity_key.split('_')
        category = parts[0]
        staging_dir = category_dirs.get(category, category)

        # Find sprite file
        sprite_path = BASE_DIR / "staging" / staging_dir / f"{entity_key}.png"

        if not sprite_path.exists():
            stats['missing'] += 1
            missing_keys.append(entity_key)
            # Draw placeholder (dark gray with X)
            placeholder = Image.new('RGBA', (TILE_SIZE, TILE_SIZE), (32, 32, 32, 255))
            tileset.paste(placeholder, (x, y))
            continue

        try:
            sprite = Image.open(sprite_path).convert('RGBA')
            if sprite.size != (TILE_SIZE, TILE_SIZE):
                sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)
            tileset.paste(sprite, (x, y))
            stats['found'] += 1
        except Exception as e:
            stats['errors'].append(f"{entity_key}: {e}")
            stats['missing'] += 1

    # Save tileset
    TILESET_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    tileset.save(TILESET_OUTPUT, 'PNG')

    print(f"  Tileset saved: {TILESET_OUTPUT}")
    print(f"  Found: {stats['found']}/{len(coordinates)}")
    print(f"  Missing: {stats['missing']}")

    if missing_keys:
        # Group by category
        by_cat = {}
        for k in missing_keys:
            cat = k.split('_')[0]
            by_cat.setdefault(cat, []).append(k)
        print(f"\n  Missing by category:")
        for cat, keys in sorted(by_cat.items()):
            print(f"    {cat}: {len(keys)} ({keys[0]}...{keys[-1]})")

    if stats['errors']:
        print(f"\n  Errors:")
        for e in stats['errors'][:10]:
            print(f"    {e}")

    return stats


def generate_tile_mapper():
    """Generate updated tile_mapper.gd from layout_map.json."""
    print("\n=== Step 5: Generate tile_mapper.gd ===")

    with open(LAYOUT_PATH, 'r') as f:
        layout = json.load(f)

    coordinates = layout.get('coordinates', {})

    # Organize coordinates by category
    terrain_light = {}  # terrain_id → Vector2i(x, y)
    terrain_dark = {}
    monsters = {}
    items = {}
    artifacts = {}
    players = {}
    effects = {}

    for key, coord in coordinates.items():
        parts = key.split('_')
        category = parts[0]

        if category == 'terrain':
            terrain_id = int(parts[1])
            variant = parts[2]  # 'light' or 'dark'
            if variant == 'light':
                terrain_light[terrain_id] = (coord['x'], coord['y'])
            else:
                terrain_dark[terrain_id] = (coord['x'], coord['y'])
        elif category == 'monster':
            monster_id = int(parts[1])
            monsters[monster_id] = (coord['x'], coord['y'])
        elif category == 'item':
            item_id = int(parts[1])
            items[item_id] = (coord['x'], coord['y'])
        elif category == 'artifact':
            art_id = int(parts[1])
            artifacts[art_id] = (coord['x'], coord['y'])
        elif category == 'player':
            player_id = int(parts[1])
            players[player_id] = (coord['x'], coord['y'])
        elif category == 'effect':
            effect_id = int(parts[1])
            effects[effect_id] = (coord['x'], coord['y'])

    # Load terrain names from manifest for comments
    terrain_names = {}
    try:
        with open(BASE_DIR / "manifest.json", 'r') as f:
            manifest = json.load(f)
        for entry in manifest.get('entities', []):
            if entry.get('category') == 'terrain':
                terrain_names[entry['id']] = entry.get('name', '')
    except:
        pass

    # Load monster/item/artifact names from manifest
    monster_names = {}
    item_names = {}
    artifact_names = {}
    try:
        with open(BASE_DIR / "manifest.json", 'r') as f:
            manifest = json.load(f)
        for entry in manifest.get('entities', []):
            cat = entry.get('category', '')
            if cat == 'monster':
                monster_names[entry['id']] = entry.get('name', '')
            elif cat == 'item':
                item_names[entry['id']] = entry.get('name', '')
            elif cat == 'artifact':
                artifact_names[entry['id']] = entry.get('name', '')
    except:
        pass

    # Build GDScript
    lines = []
    lines.append('extends Node')
    lines.append('## DALL-E + DCSS tile mapper for Necromancer')
    lines.append('## Auto-generated by integrate_terrain_v2.py')
    lines.append('## Tileset: 32x32 grid of 64x64 tiles (2048x2048 pixels)')
    lines.append('')
    lines.append('# Coordinate lookup tables')
    lines.append('var terrain_coords: Dictionary = {}')
    lines.append('var monster_coords: Dictionary = {}')
    lines.append('var item_coords: Dictionary = {}')
    lines.append('var artifact_coords: Dictionary = {}')
    lines.append('var player_coords: Dictionary = {}')
    lines.append('var effect_coords: Dictionary = {}')
    lines.append('')
    lines.append('# Monster display char to ID mapping (for existing code compatibility)')
    lines.append('var char_to_monster_id: Dictionary = {}')
    lines.append('')
    lines.append('func _ready() -> void:')
    lines.append('\t_load_terrain_coords()')
    lines.append('\t_load_monster_coords()')
    lines.append('\t_load_item_coords()')
    lines.append('\t_load_artifact_coords()')
    lines.append('\t_load_player_coords()')
    lines.append('\t_load_effect_coords()')
    lines.append('\t_load_char_mappings()')
    lines.append('\tprint("=== TileMapper Initialized (DALL-E Terrain + DCSS Entities) ===")')
    lines.append('\tprint("Grid: 32x32, Tile size: 64x64")')
    lines.append('\tprint("Total tiles loaded: ", terrain_coords.size() + monster_coords.size() + item_coords.size())')
    lines.append('')

    # Terrain coords
    lines.append('func _load_terrain_coords() -> void:')
    lines.append('\t# Format: terrain_coords[id] = {"light": Vector2i, "dark": Vector2i}')
    for tid in sorted(terrain_light.keys()):
        if tid in terrain_dark:
            lx, ly = terrain_light[tid]
            dx, dy = terrain_dark[tid]
            name = terrain_names.get(tid, '')
            comment = f"  # {name}" if name else ""
            lines.append(f'\tterrain_coords[{tid}] = {{"light": Vector2i({lx}, {ly}), "dark": Vector2i({dx}, {dy})}}{comment}')

    # Level.gd Tile enum compatibility aliases
    # The game passes Level.Tile enum values (0-16) to get_terrain_coords(),
    # NOT terrain.txt IDs. These MUST override the terrain.txt entries above.
    # enum Tile { VOID=0, FLOOR=1, WALL=2, DOOR_CLOSED=3, DOOR_OPEN=4,
    #   STAIRS_DOWN=5, STAIRS_UP=6, CHASM=7, RUBBLE=8, FORGE=9, TRAP=10,
    #   TRAP_TRIGGERED=11, DOOR_LOCKED=12, DOOR_JAMMED=13, DOOR_SECRET=14,
    #   WATER=15, LAVA=16 }
    lines.append('')
    lines.append('\t# Level.gd Tile enum compatibility mappings')
    lines.append('\t# The game passes Level.Tile enum values (0-16), NOT terrain.txt IDs.')
    lines.append('\t# These MUST come AFTER the main load to override the wrong terrain.txt entries.')
    lines.append('\t# enum Tile { VOID=0, FLOOR=1, WALL=2, DOOR_CLOSED=3, DOOR_OPEN=4,')
    lines.append('\t#   STAIRS_DOWN=5, STAIRS_UP=6, CHASM=7, RUBBLE=8, FORGE=9, TRAP=10,')
    lines.append('\t#   TRAP_TRIGGERED=11, DOOR_LOCKED=12, DOOR_JAMMED=13, DOOR_SECRET=14,')
    lines.append('\t#   WATER=15, LAVA=16 }')

    # Map enum values to terrain.txt IDs, then look up their grid positions
    ENUM_TO_TERRAIN_ID = {
        # VOID(0) -> darkness(0), FLOOR(1) -> open floor(1) - already correct
        2: 11,   # WALL -> wall
        3: 32,   # DOOR_CLOSED -> iron door
        4: 4,    # DOOR_OPEN -> open door (same ID, already correct)
        5: 81,   # STAIRS_DOWN -> dark stairs down
        6: 80,   # STAIRS_UP -> crumbling stairs up
        7: 17,   # CHASM -> jagged pit
        8: 1,    # RUBBLE -> open floor (rubble variant)
        9: 65,   # FORGE -> orc forge active
        10: 19,  # TRAP -> poison needle trap
        11: 24,  # TRAP_TRIGGERED -> rusted caltrops
        12: 6,   # DOOR_LOCKED -> warded door power 1
        13: 7,   # DOOR_JAMMED -> warded door power 2
        14: 11,  # DOOR_SECRET -> wall (looks like wall)
        15: 51,  # WATER -> quartz vein (as water)
        16: 13,  # LAVA -> morgul runes
    }
    ENUM_NAMES = {
        2: "WALL", 3: "DOOR_CLOSED", 4: "DOOR_OPEN", 5: "STAIRS_DOWN",
        6: "STAIRS_UP", 7: "CHASM", 8: "RUBBLE", 9: "FORGE",
        10: "TRAP", 11: "TRAP_TRIGGERED", 12: "DOOR_LOCKED", 13: "DOOR_JAMMED",
        14: "DOOR_SECRET", 15: "WATER", 16: "LAVA",
    }

    lines.append('\t# VOID(0) -> darkness(0) already correct at (0,0)/(1,0)')
    lines.append('\t# FLOOR(1) -> open floor(1) already correct at (2,0)/(3,0)')
    for enum_val, target_tid in sorted(ENUM_TO_TERRAIN_ID.items()):
        if target_tid in terrain_light and target_tid in terrain_dark:
            lx, ly = terrain_light[target_tid]
            dx, dy = terrain_dark[target_tid]
            ename = ENUM_NAMES.get(enum_val, "")
            tname = terrain_names.get(target_tid, "")
            lines.append(f'\tterrain_coords[{enum_val}] = {{"light": Vector2i({lx}, {ly}), "dark": Vector2i({dx}, {dy})}}    # {ename} -> {tname} (terrain {target_tid})')
        else:
            lines.append(f'\t# WARNING: terrain {target_tid} for enum {enum_val} not found in layout_map')

    lines.append('')

    # Monsters
    lines.append('func _load_monster_coords() -> void:')
    for mid in sorted(monsters.keys()):
        mx, my = monsters[mid]
        name = monster_names.get(mid, '')
        comment = f"  # {name}" if name else ""
        lines.append(f'\tmonster_coords[{mid}] = Vector2i({mx}, {my}){comment}')
    lines.append('')

    # Items
    lines.append('func _load_item_coords() -> void:')
    for iid in sorted(items.keys()):
        ix, iy = items[iid]
        name = item_names.get(iid, '')
        comment = f"  # {name}" if name else ""
        lines.append(f'\titem_coords[{iid}] = Vector2i({ix}, {iy}){comment}')
    lines.append('')

    # Artifacts
    lines.append('func _load_artifact_coords() -> void:')
    for aid in sorted(artifacts.keys()):
        ax, ay = artifacts[aid]
        name = artifact_names.get(aid, '')
        comment = f"  # {name}" if name else ""
        lines.append(f'\tartifact_coords[{aid}] = Vector2i({ax}, {ay}){comment}')
    lines.append('')

    # Players
    lines.append('func _load_player_coords() -> void:')
    race_names = {0: 'Elf', 1: 'Man', 2: 'Dwarf', 3: 'Istari', 4: 'Hobbit'}
    for pid in sorted(players.keys()):
        px, py = players[pid]
        rname = race_names.get(pid, '')
        comment = f"  # {rname}" if rname else ""
        lines.append(f'\tplayer_coords[{pid}] = Vector2i({px}, {py}){comment}')
    lines.append('')

    # Effects
    lines.append('func _load_effect_coords() -> void:')
    if effects:
        for eid in sorted(effects.keys()):
            ex, ey = effects[eid]
            lines.append(f'\teffect_coords[{eid}] = Vector2i({ex}, {ey})')
    else:
        lines.append('\tpass  # No effects defined yet')
    lines.append('')

    # Char mappings (keep from existing tile_mapper.gd)
    lines.append('func _load_char_mappings() -> void:')
    lines.append('\t# Map display characters to monster IDs for compatibility')
    lines.append('\tchar_to_monster_id["M"] = 11   # Mirkwood Spider')
    lines.append('\tchar_to_monster_id["r"] = 12   # Giant Rat')
    lines.append('\tchar_to_monster_id["b"] = 14   # Crebain')
    lines.append('\tchar_to_monster_id["&"] = 15   # Tanglethorn')
    lines.append('\tchar_to_monster_id["o"] = 18   # Orc Scout')
    lines.append('\tchar_to_monster_id["O"] = 36   # Orc Captain')
    lines.append('\tchar_to_monster_id["s"] = 19   # Swamp Adder')
    lines.append('\tchar_to_monster_id["w"] = 21   # Warg Pup')
    lines.append('\tchar_to_monster_id["W"] = 34   # Warg')
    lines.append('\tchar_to_monster_id["T"] = 38   # Hill Troll')
    lines.append('\tchar_to_monster_id["h"] = 51   # Dark Acolyte')
    lines.append('\tchar_to_monster_id["G"] = 52   # Ghoul')
    lines.append('\tchar_to_monster_id["g"] = 52   # Ghoul')
    lines.append('\tchar_to_monster_id["H"] = 55   # Dark Sorcerer')
    lines.append('\tchar_to_monster_id["Z"] = 73   # Zombie')
    lines.append('\tchar_to_monster_id["z"] = 71   # Skeleton')
    lines.append('\tchar_to_monster_id["S"] = 71   # Skeleton Warrior')
    lines.append('\tchar_to_monster_id["p"] = 91   # Phantom')
    lines.append('\tchar_to_monster_id["P"] = 91   # Phantom')
    lines.append('\tchar_to_monster_id["V"] = 113  # Vampire')
    lines.append('\tchar_to_monster_id["U"] = 115  # Vampire Lord')
    lines.append('\tchar_to_monster_id["@"] = 0    # Player')
    lines.append('\tchar_to_monster_id["N"] = 135  # Sauron')
    lines.append('')
    lines.append('')

    # Public API (same as before)
    lines.append('# ============================================================================')
    lines.append('# PUBLIC API')
    lines.append('# ============================================================================')
    lines.append('')
    lines.append('func get_terrain_coords(terrain_id: int, lit: bool = true) -> Vector2i:')
    lines.append('\t## Get terrain tile coordinates. lit=true for visible, false for remembered.')
    lines.append('\tif terrain_coords.has(terrain_id):')
    lines.append('\t\tvar data: Dictionary = terrain_coords[terrain_id]')
    lines.append('\t\treturn data["light"] if lit else data["dark"]')
    lines.append('\treturn Vector2i(0, 0)  # Default to first tile')
    lines.append('')
    lines.append('func get_monster_coords(monster_id: int) -> Vector2i:')
    lines.append('\t## Get monster tile coordinates by ID.')
    lines.append('\tif monster_coords.has(monster_id):')
    lines.append('\t\treturn monster_coords[monster_id]')
    lines.append('\treturn Vector2i(0, 0)')
    lines.append('')
    lines.append('func get_monster_coords_for_char(display_char: String) -> Vector2i:')
    lines.append('\t## Get monster tile coordinates by display character.')
    lines.append('\tif char_to_monster_id.has(display_char):')
    lines.append('\t\tvar monster_id: int = char_to_monster_id[display_char]')
    lines.append('\t\treturn get_monster_coords(monster_id)')
    lines.append('\treturn Vector2i(0, 0)')
    lines.append('')
    lines.append('func get_item_coords(item_id: int) -> Vector2i:')
    lines.append('\t## Get item tile coordinates.')
    lines.append('\tif item_coords.has(item_id):')
    lines.append('\t\treturn item_coords[item_id]')
    lines.append('\treturn Vector2i(0, 0)')
    lines.append('')
    lines.append('func get_artifact_coords(artifact_id: int) -> Vector2i:')
    lines.append('\t## Get artifact tile coordinates.')
    lines.append('\tif artifact_coords.has(artifact_id):')
    lines.append('\t\treturn artifact_coords[artifact_id]')
    lines.append('\t# Fall back to items')
    lines.append('\treturn get_item_coords(artifact_id)')
    lines.append('')
    lines.append('func get_player_coords(race_id: int) -> Vector2i:')
    lines.append('\t## Get player tile coordinates by race.')
    lines.append('\tif player_coords.has(race_id):')
    lines.append('\t\treturn player_coords[race_id]')
    lines.append('\treturn Vector2i(0, 0)')
    lines.append('')
    lines.append('func get_effect_coords(effect_id: int) -> Vector2i:')
    lines.append('\t## Get effect/status tile coordinates.')
    lines.append('\tif effect_coords.has(effect_id):')
    lines.append('\t\treturn effect_coords[effect_id]')
    lines.append('\treturn Vector2i(0, 0)')
    lines.append('')
    lines.append('func get_object_coords(object_id: int) -> Vector2i:')
    lines.append('\t## Compatibility function - tries items then artifacts.')
    lines.append('\tif item_coords.has(object_id):')
    lines.append('\t\treturn item_coords[object_id]')
    lines.append('\tif artifact_coords.has(object_id):')
    lines.append('\t\treturn artifact_coords[object_id]')
    lines.append('\treturn Vector2i(0, 0)')
    lines.append('')
    lines.append('# Legacy compatibility')
    lines.append('func tile_enum_to_feature_id(tile_enum: int) -> int:')
    lines.append('\treturn tile_enum')
    lines.append('')

    # Write the file
    content = '\n'.join(lines)
    with open(TILE_MAPPER_PATH, 'w') as f:
        f.write(content)

    print(f"  tile_mapper.gd written: {TILE_MAPPER_PATH}")
    print(f"  Terrain: {len(terrain_light)} IDs")
    print(f"  Monsters: {len(monsters)} IDs")
    print(f"  Items: {len(items)} IDs")
    print(f"  Artifacts: {len(artifacts)} IDs")
    print(f"  Players: {len(players)} IDs")
    print(f"  Effects: {len(effects)} IDs")


def main():
    print("=" * 60)
    print("TERRAIN V2 INTEGRATION")
    print("=" * 60)

    # Step 1: Copy terrain_v2 sprites
    copy_terrain_v2_to_staging()

    # Step 2: Fill forge variants
    fill_forge_variants()

    # Step 3: Fill unused terrain
    fill_unused_terrain()

    # Step 4: Assemble tileset
    stats = assemble_tileset()

    # Step 5: Generate tile_mapper.gd
    generate_tile_mapper()

    print("\n" + "=" * 60)
    print("INTEGRATION COMPLETE")
    print("=" * 60)
    print(f"Tileset: {TILESET_OUTPUT}")
    print(f"Tile Mapper: {TILE_MAPPER_PATH}")
    print(f"Sprites placed: {stats['found']}")
    print(f"Missing: {stats['missing']}")


if __name__ == "__main__":
    main()
