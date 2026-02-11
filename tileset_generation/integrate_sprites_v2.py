#!/usr/bin/env python3
"""
Integrate DALL-E monster + item sprites into the game tileset.

Opens the existing 2048x2048 tileset and replaces:
  - Rows 24-26: ALL monsters (87 total, sequential by ID)
  - Rows 11-17: ALL items (193 unique, sequential by ID)
  - Clears old DCSS monster/item rows (8-10 monsters, 11-18 items)

Then updates tile_mapper.gd with new coordinate mappings (preserves all
other functions like terrain, players, effects, artifacts).

Usage:
    python3 integrate_sprites_v2.py --all          # Paste all + update tile_mapper.gd
    python3 integrate_sprites_v2.py --monsters      # Monsters only
    python3 integrate_sprites_v2.py --items          # Items only
    python3 integrate_sprites_v2.py --dry-run        # Show layout plan without changes
"""

import argparse
import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError as e:
    print(f"Missing dependency: {e}")
    sys.exit(1)

# ============================================================================
# PATHS
# ============================================================================

BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
TILE_MAPPER_PATH = PROJECT_DIR / "scripts" / "core" / "tile_mapper.gd"
MONSTER_DIR = BASE_DIR / "monster_v3"
ITEM_DIR = BASE_DIR / "item_v3"
ITEM_PROGRESS_PATH = BASE_DIR / "item_v3_progress.json"
MONSTER_PROGRESS_PATH = BASE_DIR / "monster_v2_progress.json"

TILE_SIZE = 64
GRID_SIZE = 32  # 32x32 grid
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048

# Layout regions
MONSTER_START_ROW = 24  # Rows 24-26 for all monsters
ITEM_START_ROW = 11     # Rows 11-17 for all items
OLD_MONSTER_ROWS = [8, 9, 10]  # Old DCSS monster rows to clear


# ============================================================================
# MONSTER DATA
# ============================================================================

# All 88 monster IDs in display order (sorted by ID)
ALL_MONSTER_IDS = sorted([
    # Tier 1
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 31,
    # Tier 2
    32, 33, 34, 35, 36, 37, 38, 39, 40, 51,
    # Tier 3
    52, 53, 54, 55, 56, 57, 58, 59, 60, 71, 73, 80, 85,
    # Tier 4
    72, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 86, 87, 91, 100,
    # Tier 5
    92, 93, 94, 95, 96, 97, 98, 99, 101, 102, 103, 104, 111,
    # Tier 6
    112, 113, 114, 115, 116, 117, 118, 131, 136,
    # Tier 7
    132, 133, 134, 135, 137,
    # Tier 8
    301, 302, 303, 304, 305, 306, 307, 308, 309, 310,
])

MONSTER_NAMES = {
    11: "Mirkwood Spider", 12: "Giant Rat", 13: "Black Squirrel",
    14: "Crebain", 15: "Tanglethorn", 16: "Giant Bat", 17: "Web Spinner",
    18: "Orc Scout", 19: "Swamp Adder", 20: "Great Spider", 21: "Warg Pup",
    22: "Broodmother", 31: "Orc Slave", 32: "Orc Soldier", 33: "Orc Crossbowman",
    34: "Warg", 35: "Orc Thrallmaster", 36: "Orc Captain", 37: "Warg Rider",
    38: "Hill Troll", 39: "Gashnak Warg-lord", 40: "Orc Warchief",
    51: "Dark Acolyte", 52: "Ghoul", 53: "Mirk-troll", 54: "Easterling Warrior",
    55: "Dark Sorcerer", 56: "Tortured Wretch", 57: "Easterling Champion",
    58: "Ghast", 59: "Karvag Torturer", 60: "Master Sorcerer", 71: "Skeleton",
    72: "Skeleton Warrior", 73: "Zombie", 74: "Wight", 75: "Corpse-candle",
    76: "Necromancer Adept", 77: "Barrow-wight", 78: "Bone Golem",
    79: "Grishnakh", 80: "Easterling Infiltrator", 81: "Cave Troll",
    82: "Dark Ritualist", 83: "Corsair of Umbar", 84: "Dunlending",
    85: "Tunnel Crawler", 86: "Pale Crawler", 87: "Werewolf", 91: "Phantom", 92: "Shadow",
    93: "Whispering Shade", 94: "Wraith", 95: "Fell Spirit", 96: "Spectre",
    97: "Vampire Thrall", 98: "Wailing Horror", 99: "Uvatha",
    100: "BN Acolyte", 101: "Haradrim Assassin", 102: "Cave Worm",
    103: "Oathbreaker", 104: "Morgul Sorcerer", 111: "Black Numenorean",
    112: "Olog-hai", 113: "Vampire", 114: "Greater Wraith", 115: "Vampire Lord",
    116: "Shadow Lord", 117: "Maia Thrall", 118: "Khamul",
    131: "Elite Olog-hai", 132: "Greater Shadow", 133: "Void Wraith",
    134: "Thrain's Shade", 135: "Sauron", 136: "BN Lord",
    137: "Mouth of Sauron",
    301: "Gandalf", 302: "Thranduil", 303: "Galadriel", 304: "Elrond",
    305: "Thorin", 306: "Beorn", 307: "Radagast", 308: "Eagle",
    309: "Great Elk", 310: "Ent",
}

TIER_IDS = {
    1: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 31],
    2: [32, 33, 34, 35, 36, 37, 38, 39, 40, 51],
    3: [52, 53, 54, 55, 56, 57, 58, 59, 60, 71, 73, 80, 85],
    4: [72, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 86, 87, 91, 100],
    5: [92, 93, 94, 95, 96, 97, 98, 99, 101, 102, 103, 104, 111],
    6: [112, 113, 114, 115, 116, 117, 118, 131, 136],
    7: [132, 133, 134, 135, 137],
    8: [301, 302, 303, 304, 305, 306, 307, 308, 309, 310],
}


def get_tier_for_monster(mid):
    for tier, ids in TIER_IDS.items():
        if mid in ids:
            return tier
    return 1


# ============================================================================
# ITEM DATA
# ============================================================================

def load_item_ids():
    """Get all unique item IDs from the item generation progress file."""
    if not ITEM_PROGRESS_PATH.exists():
        print(f"  WARNING: {ITEM_PROGRESS_PATH} not found")
        return [], {}

    with open(ITEM_PROGRESS_PATH, 'r') as f:
        progress = json.load(f)

    canonical_ids = []
    dup_map = {}  # item_id → canonical_id

    for key, info in progress.get("sprites", {}).items():
        if info.get("status") != "completed":
            continue
        item_id = info.get("item_id")
        if item_id is None:
            continue

        canonical = info.get("canonical_id")
        if canonical is not None and canonical != item_id:
            dup_map[item_id] = canonical
        else:
            if item_id not in canonical_ids:
                canonical_ids.append(item_id)

    return sorted(canonical_ids), dup_map


def get_item_category(item_id):
    """Get the category name for an item from progress."""
    if not ITEM_PROGRESS_PATH.exists():
        return "unknown"
    with open(ITEM_PROGRESS_PATH, 'r') as f:
        progress = json.load(f)
    key = f"item_{item_id}"
    info = progress.get("sprites", {}).get(key, {})
    return info.get("category", "unknown")


def get_item_name(item_id):
    """Get item name from progress."""
    if not ITEM_PROGRESS_PATH.exists():
        return f"item_{item_id}"
    with open(ITEM_PROGRESS_PATH, 'r') as f:
        progress = json.load(f)
    key = f"item_{item_id}"
    info = progress.get("sprites", {}).get(key, {})
    return info.get("name", f"item_{item_id}")


# ============================================================================
# LAYOUT COMPUTATION
# ============================================================================

def compute_monster_layout():
    """Assign grid coordinates to all monsters. Returns {monster_id: (col, row)}."""
    layout = {}
    for i, mid in enumerate(ALL_MONSTER_IDS):
        col = i % GRID_SIZE
        row = MONSTER_START_ROW + i // GRID_SIZE
        layout[mid] = (col, row)
    return layout


def compute_item_layout(item_ids):
    """Assign grid coordinates to all unique items. Returns {item_id: (col, row)}."""
    layout = {}
    for i, iid in enumerate(item_ids):
        col = i % GRID_SIZE
        row = ITEM_START_ROW + i // GRID_SIZE
        layout[iid] = (col, row)
    return layout


# ============================================================================
# SPRITE FINDING
# ============================================================================

def find_monster_sprite(mid):
    """Find the processed light sprite for a monster."""
    tier = get_tier_for_monster(mid)
    # Check corrected/processed tier directory first
    path = MONSTER_DIR / f"tier_{tier}" / f"monster_{mid}_light.png"
    if path.exists():
        return path
    # Fallback: raw 1024px (shouldn't reach here after correction pipeline)
    return None


def find_item_sprite(iid):
    """Find the processed light sprite for an item."""
    cat = get_item_category(iid)
    # Check category dir for corrected sprite
    path = ITEM_DIR / cat / f"item_{iid}_light.png"
    if path.exists():
        return path
    return None


# ============================================================================
# TILESET OPERATIONS
# ============================================================================

def clear_rows(tileset, rows):
    """Clear specific rows in the tileset (set to transparent black)."""
    for row in rows:
        y = row * TILE_SIZE
        box = (0, y, TILESET_SIZE, y + TILE_SIZE)
        clear = Image.new("RGBA", (TILESET_SIZE, TILE_SIZE), (0, 0, 0, 0))
        tileset.paste(clear, (0, y))
    return tileset


def paste_sprite(tileset, sprite_path, col, row):
    """Paste a 64x64 sprite into the tileset at (col, row)."""
    try:
        sprite = Image.open(sprite_path).convert("RGBA")
        if sprite.size != (TILE_SIZE, TILE_SIZE):
            sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)
        x = col * TILE_SIZE
        y = row * TILE_SIZE
        tileset.paste(sprite, (x, y), sprite)  # Use alpha mask
        return True
    except Exception as e:
        print(f"    ERROR pasting {sprite_path}: {e}")
        return False


# ============================================================================
# TILE_MAPPER.GD UPDATE
# ============================================================================

def update_tile_mapper(monster_layout, item_layout, dup_map):
    """Update _load_monster_coords and _load_item_coords in tile_mapper.gd."""
    if not TILE_MAPPER_PATH.exists():
        print(f"  ERROR: {TILE_MAPPER_PATH} not found")
        return False

    content = TILE_MAPPER_PATH.read_text()

    # === Replace _load_monster_coords ===
    monster_lines = []
    monster_lines.append("func _load_monster_coords() -> void:")

    # Group by tier for comments
    current_tier = 0
    for mid in ALL_MONSTER_IDS:
        tier = get_tier_for_monster(mid)
        if tier != current_tier:
            current_tier = tier
            tier_names = {1: "Outer Pits", 2: "Lower Halls", 3: "Dark Halls",
                         4: "Necropolis", 5: "Pits of Despair", 6: "Inner Sanctum",
                         7: "Throne Room", 8: "Hallucinations"}
            monster_lines.append(f"\t# === Tier {tier}: {tier_names.get(tier, '')} ===")

        if mid in monster_layout:
            col, row = monster_layout[mid]
            name = MONSTER_NAMES.get(mid, "")
            comment = f"  # {name}" if name else ""
            monster_lines.append(f"\tmonster_coords[{mid}] = Vector2i({col}, {row}){comment}")

    monster_block = "\n".join(monster_lines)

    # === Replace _load_item_coords ===
    item_lines = []
    item_lines.append("func _load_item_coords() -> void:")

    # Canonical items first (they have actual tileset positions)
    for iid in sorted(item_layout.keys()):
        col, row = item_layout[iid]
        name = get_item_name(iid)
        item_lines.append(f"\titem_coords[{iid}] = Vector2i({col}, {row})  # {name}")

    # Duplicate items (point to same coords as their canonical)
    if dup_map:
        item_lines.append("\t# Duplicate items sharing canonical sprites")
        for dup_id in sorted(dup_map.keys()):
            canonical = dup_map[dup_id]
            if canonical in item_layout:
                col, row = item_layout[canonical]
                item_lines.append(f"\titem_coords[{dup_id}] = Vector2i({col}, {row})  # -> item_{canonical}")

    item_block = "\n".join(item_lines)

    # === Apply replacements ===
    # Replace _load_monster_coords function body
    pattern_monster = r"func _load_monster_coords\(\) -> void:.*?(?=\nfunc |\Z)"
    content = re.sub(pattern_monster, monster_block + "\n", content, flags=re.DOTALL)

    # Replace _load_item_coords function body
    pattern_item = r"func _load_item_coords\(\) -> void:.*?(?=\nfunc |\Z)"
    content = re.sub(pattern_item, item_block + "\n", content, flags=re.DOTALL)

    TILE_MAPPER_PATH.write_text(content)
    print(f"  tile_mapper.gd updated: {TILE_MAPPER_PATH}")
    print(f"    Monsters: {len(monster_layout)} entries")
    print(f"    Items: {len(item_layout)} canonical + {len(dup_map)} duplicates")
    return True


# ============================================================================
# MAIN PIPELINE
# ============================================================================

def integrate_monsters(tileset, dry_run=False):
    """Paste all monster sprites into rows 24-26."""
    layout = compute_monster_layout()

    print(f"\n{'=' * 60}")
    print(f"MONSTER INTEGRATION - {len(ALL_MONSTER_IDS)} monsters")
    print(f"Layout: rows {MONSTER_START_ROW}-{MONSTER_START_ROW + (len(ALL_MONSTER_IDS) - 1) // GRID_SIZE}")
    print(f"{'=' * 60}")

    found = 0
    missing = []

    for mid in ALL_MONSTER_IDS:
        col, row = layout[mid]
        sprite_path = find_monster_sprite(mid)
        name = MONSTER_NAMES.get(mid, f"#{mid}")

        if sprite_path:
            if not dry_run:
                if paste_sprite(tileset, sprite_path, col, row):
                    found += 1
                else:
                    missing.append(mid)
            else:
                found += 1
                print(f"  [{mid:3d}] {name:25s} -> ({col:2d}, {row}) from {sprite_path.name}")
        else:
            missing.append(mid)
            if dry_run:
                print(f"  [{mid:3d}] {name:25s} -> ({col:2d}, {row}) MISSING")

    print(f"\n  Found: {found}/{len(ALL_MONSTER_IDS)}")
    if missing:
        print(f"  Missing ({len(missing)}): {missing}")

    return layout


def integrate_items(tileset, dry_run=False):
    """Paste all item sprites into rows 11-17."""
    item_ids, dup_map = load_item_ids()
    layout = compute_item_layout(item_ids)

    print(f"\n{'=' * 60}")
    print(f"ITEM INTEGRATION - {len(item_ids)} unique ({len(item_ids) + len(dup_map)} total)")
    print(f"Layout: rows {ITEM_START_ROW}-{ITEM_START_ROW + (len(item_ids) - 1) // GRID_SIZE}")
    print(f"{'=' * 60}")

    found = 0
    missing = []

    for iid in item_ids:
        col, row = layout[iid]
        sprite_path = find_item_sprite(iid)
        name = get_item_name(iid)

        if sprite_path:
            if not dry_run:
                if paste_sprite(tileset, sprite_path, col, row):
                    found += 1
                else:
                    missing.append(iid)
            else:
                found += 1
        else:
            missing.append(iid)

    print(f"\n  Found: {found}/{len(item_ids)}")
    if missing:
        print(f"  Missing ({len(missing)}): {missing[:20]}{'...' if len(missing) > 20 else ''}")

    return layout, dup_map


def main():
    parser = argparse.ArgumentParser(description="Integrate DALL-E sprites into tileset")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--all", action="store_true", help="Integrate all monsters + items")
    group.add_argument("--monsters", action="store_true", help="Monsters only")
    group.add_argument("--items", action="store_true", help="Items only")
    group.add_argument("--dry-run", action="store_true", help="Show layout plan only")

    args = parser.parse_args()

    if not any([args.all, args.monsters, args.items, args.dry_run]):
        parser.print_help()
        return

    if args.dry_run:
        print(f"{'=' * 60}")
        print(f"DRY RUN - Layout Plan")
        print(f"{'=' * 60}")
        # Don't need to open the tileset for dry run
        tileset = None
        monster_layout = integrate_monsters(tileset, dry_run=True)

        item_ids, dup_map = load_item_ids()
        item_layout = compute_item_layout(item_ids)
        print(f"\n  Item layout: {len(item_ids)} unique across rows {ITEM_START_ROW}-{ITEM_START_ROW + (len(item_ids) - 1) // GRID_SIZE}")
        print(f"  Duplicates: {len(dup_map)} items sharing canonical sprites")
        return

    # Open existing tileset
    if not TILESET_PATH.exists():
        print(f"ERROR: Tileset not found: {TILESET_PATH}")
        return

    tileset = Image.open(TILESET_PATH).convert("RGBA")
    print(f"Loaded tileset: {tileset.size[0]}x{tileset.size[1]}")

    monster_layout = {}
    item_layout = {}
    dup_map = {}

    do_monsters = args.all or args.monsters
    do_items = args.all or args.items

    if do_monsters:
        # Clear old DCSS monster rows (cols 12+ on rows 8-9, all of row 10)
        # Note: rows 8-9 cols 0-11 are player v2 sprites - DON'T clear those
        print("\n  Clearing old monster rows (8-9 cols 12-31, 10 all)...")
        # Row 10: clear everything
        clear_full = Image.new("RGBA", (TILESET_SIZE, TILE_SIZE), (0, 0, 0, 0))
        tileset.paste(clear_full, (0, 10 * TILE_SIZE))
        # Rows 8-9: only clear cols 12-31 (preserve player sprites in 0-11)
        for row in [8, 9]:
            clear_partial = Image.new("RGBA", (20 * TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear_partial, (12 * TILE_SIZE, row * TILE_SIZE))

        monster_layout = integrate_monsters(tileset)

    if do_items:
        # Clear item rows 11-18
        print("\n  Clearing item rows 11-18...")
        for row in range(11, 19):
            y = row * TILE_SIZE
            clear = Image.new("RGBA", (TILESET_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear, (0, y))

        item_layout, dup_map = integrate_items(tileset)

    # Save tileset
    tileset.save(TILESET_PATH, "PNG")
    print(f"\n  Tileset saved: {TILESET_PATH}")

    # Update tile_mapper.gd
    if monster_layout or item_layout:
        print(f"\n  Updating tile_mapper.gd...")
        update_tile_mapper(monster_layout, item_layout, dup_map)

    print(f"\n{'=' * 60}")
    print(f"INTEGRATION COMPLETE")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
