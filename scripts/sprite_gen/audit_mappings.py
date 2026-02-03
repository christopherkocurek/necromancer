#!/usr/bin/env python3
"""
Audit tile mappings against game data, sprite definitions, and PRF file.
Identifies mismatches, missing sprites, and wrong mappings.
"""

import re
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).parent.parent.parent

# Import sprite data
import sys
sys.path.insert(0, str(Path(__file__).parent))
from sprite_data import PLAYERS, MONSTERS, TERRAIN, TRAPS, ITEMS, EFFECTS, UI

# Paths
PRF_PATH = PROJECT_ROOT / "lib" / "pref" / "graf-necromancer.prf"
TERRAIN_TXT = PROJECT_ROOT / "lib" / "edit" / "terrain.txt"
MONSTER_TXT = PROJECT_ROOT / "lib" / "edit" / "monster.txt"
SPRITE_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf" / "final"

def parse_prf_file():
    """Parse the PRF file to get current mappings."""
    mappings = {"F": {}, "R": {}}

    with open(PRF_PATH, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('F:') or line.startswith('R:'):
                parts = line.split(':')
                if len(parts) >= 3:
                    type_char = parts[0]
                    obj_id = int(parts[1])
                    coords = parts[2].split('/')
                    row = int(coords[0], 16) - 0x80
                    col = int(coords[1], 16) - 0x80
                    mappings[type_char][obj_id] = (row, col)

    return mappings

def parse_terrain_txt():
    """Parse terrain.txt to get all terrain feature IDs and names."""
    terrain = {}
    current_id = None

    with open(TERRAIN_TXT, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('N:'):
                parts = line.split(':')
                if len(parts) >= 3:
                    current_id = int(parts[1])
                    name = parts[2]
                    terrain[current_id] = {"name": name}

    return terrain

def parse_monster_txt():
    """Parse monster.txt to get all monster IDs and names."""
    monsters = {}
    current_id = None

    with open(MONSTER_TXT, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('N:'):
                parts = line.split(':')
                if len(parts) >= 3:
                    current_id = int(parts[1])
                    name = parts[2]
                    monsters[current_id] = {"name": name}

    return monsters

def get_sprite_definitions():
    """Get all sprite definitions from sprite_data.py."""
    all_sprites = {}

    for sprite in PLAYERS + MONSTERS + TERRAIN + TRAPS:
        sprite_id = sprite["id"]
        all_sprites[sprite_id] = {
            "name": sprite["name"],
            "filename": sprite["filename"]
        }

    # Items, Effects, UI use different ID format
    for sprite in ITEMS:
        all_sprites[sprite["id"]] = {
            "name": sprite["name"],
            "filename": sprite["filename"]
        }

    for sprite in EFFECTS:
        all_sprites[sprite["id"]] = {
            "name": sprite["name"],
            "filename": sprite["filename"]
        }

    for sprite in UI:
        all_sprites[sprite["id"]] = {
            "name": sprite["name"],
            "filename": sprite["filename"]
        }

    return all_sprites

def check_sprite_files():
    """Check which sprite files actually exist."""
    existing = set()

    for png in SPRITE_DIR.rglob("*.png"):
        relative = png.relative_to(SPRITE_DIR.parent)
        existing.add(str(relative).replace('.png', ''))

    return existing

def audit():
    """Run the full audit."""
    print("=" * 70)
    print("TILE MAPPING AUDIT")
    print("=" * 70)

    # Load all data
    prf_mappings = parse_prf_file()
    game_terrain = parse_terrain_txt()
    game_monsters = parse_monster_txt()
    sprite_defs = get_sprite_definitions()
    existing_files = check_sprite_files()

    issues = []

    # -------------------------------------------------------------------------
    # 1. Check PRF terrain mappings against game terrain
    # -------------------------------------------------------------------------
    print("\n### TERRAIN AUDIT ###")
    print(f"PRF has {len(prf_mappings['F'])} F: entries")
    print(f"Game has {len(game_terrain)} terrain features defined")

    # Terrain in game but not in PRF
    print("\n[!] Terrain in game but NOT in PRF (may need sprites):")
    for tid, data in sorted(game_terrain.items()):
        if tid not in prf_mappings['F']:
            sprite_key = f"F:{tid}"
            has_sprite = sprite_key in sprite_defs
            status = "HAS SPRITE DEF" if has_sprite else "NO SPRITE DEF"
            print(f"    F:{tid} - {data['name']} [{status}]")

    # Terrain in PRF but not in game
    print("\n[!] Terrain in PRF but NOT in game (orphan entries):")
    for tid in sorted(prf_mappings['F'].keys()):
        if tid not in game_terrain:
            print(f"    F:{tid} at {prf_mappings['F'][tid]}")

    # -------------------------------------------------------------------------
    # 2. Check PRF monster mappings against game monsters
    # -------------------------------------------------------------------------
    print("\n### MONSTER/PLAYER AUDIT ###")
    print(f"PRF has {len(prf_mappings['R'])} R: entries")
    print(f"Game has {len(game_monsters)} monster/player entries defined")

    # Monsters in game but not in PRF (selective - only those with sprites)
    print("\n[!] Monsters WITH sprite definitions but NOT in PRF:")
    for sprite_id, sprite_data in sprite_defs.items():
        if sprite_id.startswith("R:"):
            mid = int(sprite_id[2:])
            if mid not in prf_mappings['R']:
                print(f"    R:{mid} - {sprite_data['name']}")

    # -------------------------------------------------------------------------
    # 3. Verify sprite files exist for all PRF entries
    # -------------------------------------------------------------------------
    print("\n### SPRITE FILE VERIFICATION ###")

    print("\n[!] PRF entries without sprite files:")
    for tid, coords in prf_mappings['F'].items():
        sprite_key = f"F:{tid}"
        if sprite_key in sprite_defs:
            filename = "final/" + sprite_defs[sprite_key]["filename"]
            if filename not in existing_files:
                print(f"    F:{tid} - expected: {filename}")

    for rid, coords in prf_mappings['R'].items():
        sprite_key = f"R:{rid}"
        if sprite_key in sprite_defs:
            filename = "final/" + sprite_defs[sprite_key]["filename"]
            if filename not in existing_files:
                print(f"    R:{rid} - expected: {filename}")

    # -------------------------------------------------------------------------
    # 4. Cross-check LAYOUT positions match PRF
    # -------------------------------------------------------------------------
    print("\n### LAYOUT vs PRF CONSISTENCY ###")

    # Import LAYOUT
    from assemble_sheet import LAYOUT

    print("\n[!] Mismatches between LAYOUT and PRF:")
    mismatch_count = 0
    for sprite_id, layout_pos in LAYOUT.items():
        if sprite_id.startswith("F:"):
            fid = int(sprite_id[2:])
            if fid in prf_mappings['F']:
                prf_pos = prf_mappings['F'][fid]
                if layout_pos != prf_pos:
                    print(f"    {sprite_id}: LAYOUT={layout_pos} vs PRF={prf_pos}")
                    mismatch_count += 1
        elif sprite_id.startswith("R:"):
            rid = int(sprite_id[2:])
            if rid in prf_mappings['R']:
                prf_pos = prf_mappings['R'][rid]
                if layout_pos != prf_pos:
                    print(f"    {sprite_id}: LAYOUT={layout_pos} vs PRF={prf_pos}")
                    mismatch_count += 1

    if mismatch_count == 0:
        print("    All LAYOUT positions match PRF positions. ✓")

    # -------------------------------------------------------------------------
    # 5. Check for important missing terrain sprites
    # -------------------------------------------------------------------------
    print("\n### IMPORTANT MISSING SPRITES ###")

    important_terrain = {
        2: "Bottomless Pit",
        3: "Protective Rune",
        7: "Warded Door Power 2",
        8: "Warded Door Power 3",
        10: "Open Floor Variant",
        14: "Shadow Brazier",
        15: "Torture Rack",
        18: "Poisoned Spike Pit",
        19: "Poison Needle",
        21: "Mind Fog",
        23: "Blinding Glyph",
        24: "Rusted Caltrops",
        25: "Bat Roost",
        28: "Pool of Filth",
        30: "Chains",
        84: "Poison Stream",
        87: "Forest Floor",
    }

    print("\nTerrain features in game that might need sprites:")
    for tid, name in important_terrain.items():
        if tid in game_terrain:
            has_prf = tid in prf_mappings['F']
            sprite_key = f"F:{tid}"
            has_sprite = sprite_key in sprite_defs
            status = "MAPPED" if has_prf else ("HAS DEF" if has_sprite else "MISSING")
            if not has_prf:
                print(f"    F:{tid} - {name} [{status}]")

    # -------------------------------------------------------------------------
    # 6. Summary
    # -------------------------------------------------------------------------
    print("\n" + "=" * 70)
    print("AUDIT SUMMARY")
    print("=" * 70)

    terrain_in_prf = len(prf_mappings['F'])
    monsters_in_prf = len(prf_mappings['R'])
    sprites_defined = len(sprite_defs)

    print(f"Total terrain mappings in PRF: {terrain_in_prf}")
    print(f"Total monster/player mappings in PRF: {monsters_in_prf}")
    print(f"Total sprite definitions: {sprites_defined}")
    print(f"Total sprite files found: {len(existing_files)}")

    # Items, Effects, UI are not in PRF
    print("\nNote: Items (I:), Effects (E:), and UI (U:) sprites are NOT")
    print("mapped in PRF - they use separate rendering systems.")

    return issues

if __name__ == "__main__":
    audit()
