#!/usr/bin/env python3
"""
Integrate player_v2 sprites (24 light + 24 dark = 48 total) into the tileset.

Layout (32x32 grid of 64x64 tiles, 2048x2048 tileset):

  LIGHT variants (cols 0-5):
    Row 6: Elf    → h0_male, h0_female, h1_male, h1_female, h2_male, h2_female
    Row 7: Man    → h3_male, h3_female, h4_male, h4_female, h5_male, h5_female
    Row 8: Dwarf  → h6_male, h6_female, h7_male, h7_female, h8_male, h8_female
    Row 9: Hobbit → h9_male, h9_female, h10_male, h10_female, h11_male, h11_female

  DARK variants (cols 6-11, same rows):
    Row 6: Elf    → h0_male_dark, h0_female_dark, ...
    Row 7: Man    → h3_male_dark, h3_female_dark, ...
    Row 8: Dwarf  → h6_male_dark, h6_female_dark, ...
    Row 9: Hobbit → h9_male_dark, h9_female_dark, ...

This script opens the existing tileset PNG, pastes in all 48 player sprites,
and saves the result. The original tileset is backed up first.
"""

import json
import shutil
from datetime import datetime
from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).parent
PROJECT_ROOT = BASE_DIR.parent
TILESET_PATH = PROJECT_ROOT / "assets" / "sprites" / "necromancer_dcss_tileset.png"
PLAYER_V2_DIR = BASE_DIR / "player_v2"
LAYOUT_PATH = BASE_DIR / "layout_map.json"

TILE_SIZE = 64
GRID_SIZE = 32
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048

# Race definitions: (race_name, subfolder, house_ids, target_row)
RACES = [
    ("Elf",    "elf",    [0, 1, 2],     6),
    ("Man",    "man",    [3, 4, 5],     7),
    ("Dwarf",  "dwarf",  [6, 7, 8],     8),
    ("Hobbit", "hobbit", [9, 10, 11],   9),
]

GENDERS = ["male", "female"]


def load_layout_map():
    """Load layout_map.json and build a reverse lookup: (col, row) -> entity_key."""
    with open(LAYOUT_PATH, 'r') as f:
        layout = json.load(f)
    occupied = {}
    for key, coord in layout.get('coordinates', {}).items():
        occupied[(coord['x'], coord['y'])] = key
    return occupied


def check_target_positions(occupied):
    """Check what currently occupies the target grid positions and warn about conflicts."""
    print("\n=== Step 1: Check target positions ===")

    conflicts = []
    free = 0
    old_players = 0

    for race_name, subfolder, house_ids, row in RACES:
        for col_offset, (house_id, gender) in enumerate(
            [(h, g) for h in house_ids for g in GENDERS]
        ):
            # Light variant: cols 0-5
            light_col = col_offset
            light_pos = (light_col, row)
            # Dark variant: cols 6-11
            dark_col = col_offset + 6
            dark_pos = (dark_col, row)

            for pos, variant in [(light_pos, "light"), (dark_pos, "dark")]:
                existing = occupied.get(pos)
                if existing:
                    if existing.startswith("player_"):
                        old_players += 1
                    else:
                        conflicts.append((pos, existing, f"{race_name} h{house_id}_{gender}_{variant}"))
                else:
                    free += 1

    print(f"  Free positions: {free}")
    print(f"  Old player slots (will be replaced): {old_players}")
    print(f"  Conflicts with non-player entities: {len(conflicts)}")

    if conflicts:
        print("\n  WARNING: The following positions contain non-player entities that will be OVERWRITTEN:")
        for pos, existing_key, new_sprite in conflicts:
            print(f"    ({pos[0]}, {pos[1]}): '{existing_key}' -> '{new_sprite}'")

    return conflicts


def build_sprite_placements():
    """Build the list of (sprite_path, grid_col, grid_row, description) tuples."""
    placements = []

    for race_name, subfolder, house_ids, row in RACES:
        race_dir = PLAYER_V2_DIR / subfolder

        for col_offset, (house_id, gender) in enumerate(
            [(h, g) for h in house_ids for g in GENDERS]
        ):
            # Light variant
            light_filename = f"player_{subfolder}_h{house_id}_{gender}_light.png"
            light_path = race_dir / light_filename
            light_col = col_offset
            desc_light = f"{race_name} h{house_id} {gender} light"
            placements.append((light_path, light_col, row, desc_light))

            # Dark variant
            dark_filename = f"player_{subfolder}_h{house_id}_{gender}_dark.png"
            dark_path = race_dir / dark_filename
            dark_col = col_offset + 6
            desc_dark = f"{race_name} h{house_id} {gender} dark"
            placements.append((dark_path, dark_col, row, desc_dark))

    return placements


def backup_tileset():
    """Create a timestamped backup of the existing tileset."""
    print("\n=== Step 2: Backup existing tileset ===")
    if not TILESET_PATH.exists():
        print(f"  WARNING: Tileset not found at {TILESET_PATH}")
        return False

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = TILESET_PATH.with_name(f"necromancer_dcss_tileset_backup_{timestamp}.png")
    shutil.copy2(TILESET_PATH, backup_path)
    print(f"  Backed up to: {backup_path}")
    return True


def paste_sprites(placements):
    """Open the tileset and paste each player sprite at its grid position."""
    print("\n=== Step 3: Paste player sprites into tileset ===")

    tileset = Image.open(TILESET_PATH).convert('RGBA')
    assert tileset.size == (TILESET_SIZE, TILESET_SIZE), \
        f"Tileset size mismatch: expected {TILESET_SIZE}x{TILESET_SIZE}, got {tileset.size}"

    placed = 0
    missing = 0
    errors = []

    for sprite_path, col, row, desc in placements:
        px = col * TILE_SIZE
        py = row * TILE_SIZE

        if not sprite_path.exists():
            print(f"  MISSING: {sprite_path.name} ({desc})")
            missing += 1
            continue

        try:
            sprite = Image.open(sprite_path).convert('RGBA')
            if sprite.size != (TILE_SIZE, TILE_SIZE):
                sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)
            # Paste using alpha composite to preserve transparency
            # First clear the target area, then paste with alpha
            clear_region = Image.new('RGBA', (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
            tileset.paste(clear_region, (px, py))
            tileset.paste(sprite, (px, py), sprite)
            placed += 1
        except Exception as e:
            errors.append(f"{sprite_path.name}: {e}")
            print(f"  ERROR: {sprite_path.name}: {e}")

    # Save
    tileset.save(TILESET_PATH, 'PNG')

    print(f"\n  Tileset saved: {TILESET_PATH}")
    print(f"  Placed: {placed}/{len(placements)}")
    if missing:
        print(f"  Missing: {missing}")
    if errors:
        print(f"  Errors: {len(errors)}")
        for e in errors:
            print(f"    {e}")

    return placed, missing, errors


def print_summary(placements, placed_count):
    """Print a readable summary of the final layout."""
    print("\n=== Placement Summary ===")
    print(f"{'Grid Pos':<12} {'Variant':<8} {'Description'}")
    print("-" * 50)

    for sprite_path, col, row, desc in placements:
        status = "OK" if sprite_path.exists() else "MISSING"
        variant = "dark" if "dark" in desc else "light"
        print(f"  ({col:2d}, {row}) {variant:<8} {desc:<35} [{status}]")

    print(f"\nTotal sprites placed: {placed_count}/48")
    print(f"Tileset: {TILESET_PATH}")


def main():
    print("=" * 60)
    print("PLAYER V2 INTEGRATION")
    print("=" * 60)
    print(f"Source: {PLAYER_V2_DIR}")
    print(f"Target: {TILESET_PATH}")

    # Step 1: Check what occupies target positions
    occupied = load_layout_map()
    conflicts = check_target_positions(occupied)

    if conflicts:
        print(f"\n  Proceeding despite {len(conflicts)} conflicts (overwriting)...")

    # Step 2: Backup
    backup_tileset()

    # Step 3: Build placement list and paste
    placements = build_sprite_placements()
    placed, missing, errors = paste_sprites(placements)

    # Summary
    print_summary(placements, placed)

    print("\n" + "=" * 60)
    print("INTEGRATION COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
