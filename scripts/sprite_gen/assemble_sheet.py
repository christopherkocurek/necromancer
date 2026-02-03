#!/usr/bin/env python3
"""
Assemble all 64x64 sprites into a tileset PNG and generate PRF mapping file
"""

import json
from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).parent.parent.parent
GRAF_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = GRAF_DIR / "final"
MANIFEST_PATH = GRAF_DIR / "sprite_manifest.json"
PREF_DIR = PROJECT_ROOT / "lib" / "pref"

TILE_SIZE = 64
SHEET_COLS = 16  # 16 columns
SHEET_ROWS = 16  # 16 rows = 256 tiles max (we have 101)

# Tileset layout mapping - assigns each sprite to a row/column
# Based on the tileset_layout.md spec, adapted for 64x64
LAYOUT = {
    # Row 0: Terrain - floors
    "F:0": (0, 0),   # Darkness
    "F:1": (0, 1),   # Stone floor
    "F:9": (0, 2),   # Fading daylight
    "F:31": (0, 3),  # Bloodstain
    "F:86": (0, 4),  # Vine floor
    "F:2": (0, 5),   # Bottomless pit (NEW)
    "F:3": (0, 6),   # Protective rune (NEW)
    "F:87": (0, 7),  # Forest floor (NEW)
    "F:84": (0, 8),  # Poison stream (NEW)

    # Row 1: Terrain - walls, doors
    "F:56": (1, 0),  # Dark stone wall
    "F:48": (1, 1),  # Hidden passage
    "F:85": (1, 2),  # Tangled roots
    "F:29": (1, 3),  # Prison bars
    "F:32": (1, 4),  # Iron door
    "F:4": (1, 5),   # Open door
    "F:5": (1, 6),   # Shattered door
    "F:6": (1, 7),   # Warded door
    "F:7": (1, 8),   # Warded door power 2 (NEW)
    "F:8": (1, 9),   # Warded door power 3 (NEW)
    "F:30": (1, 10), # Chains (NEW)

    # Row 2: Terrain - stairs, special
    "F:80": (2, 0),  # Stairs up
    "F:81": (2, 1),  # Stairs down
    "F:82": (2, 2),  # Shaft up
    "F:83": (2, 3),  # Shaft down
    "F:64": (2, 4),  # Orc forge
    "F:12": (2, 5),  # Dark pool
    "F:13": (2, 6),  # Morgul runes
    "F:14": (2, 7),  # Shadow brazier (NEW)
    "F:15": (2, 8),  # Torture rack (NEW)

    # Row 3: Traps (existing + new)
    "F:16": (3, 0),  # Weakened floor
    "F:17": (3, 1),  # Jagged pit
    "F:20": (3, 2),  # Noxious fumes
    "F:22": (3, 3),  # Orc alarm
    "F:26": (3, 4),  # Thick web
    "F:27": (3, 5),  # Falling stones
    "F:18": (3, 6),  # Poisoned spike pit (NEW)
    "F:19": (3, 7),  # Poison needle trap (NEW)
    "F:21": (3, 8),  # Mind fog (NEW)
    "F:23": (3, 9),  # Blinding glyph (NEW)
    "F:24": (3, 10), # Rusted caltrops (NEW)
    "F:25": (3, 11), # Bat roost (NEW)
    "F:28": (3, 12), # Pool of filth (NEW)

    # Row 4: Items (weapons, armor)
    "I:sword": (4, 0),
    "I:polearm": (4, 1),
    "I:blunt": (4, 2),
    "I:bow": (4, 3),
    "I:armor": (4, 4),
    "I:shield": (4, 5),
    "I:helm": (4, 6),
    "I:misc_armor": (4, 7),
    "I:potion": (4, 8),
    "I:herb": (4, 9),
    "I:ring": (4, 10),
    "I:staff": (4, 11),
    "I:arrow": (4, 12),   # NEW
    "I:torch": (4, 13),   # NEW
    "I:lantern": (4, 14), # NEW
    "I:amulet": (4, 15),  # NEW

    # Row 14: Additional Items (overflow from row 4)
    "I:cloak": (14, 0),   # NEW
    "I:boots": (14, 1),   # NEW
    "I:gloves": (14, 2),  # NEW
    "I:chest": (14, 3),   # NEW
    "I:horn": (14, 4),    # NEW
    "I:wand": (14, 5),    # NEW

    # Row 5: Effects and UI
    "E:arrow": (5, 0),
    "E:fire": (5, 1),
    "E:darkness": (5, 2),
    "E:impact": (5, 3),
    "U:pile": (5, 4),
    "U:light": (5, 5),
    "U:cursor": (5, 6),
    "U:poison": (5, 7),
    "U:wounded": (5, 8),

    # Row 6: Players
    "R:0": (6, 0),   # Elf
    "R:1": (6, 1),   # Man
    "R:2": (6, 2),   # Dwarf
    "R:3": (6, 3),   # Alternate

    # Row 7: Layer 1 monsters (Forest)
    "R:11": (7, 0),  # Mirkwood Spider
    "R:12": (7, 1),  # Giant Rat
    "R:13": (7, 2),  # Black Squirrel
    "R:14": (7, 3),  # Crebain
    "R:15": (7, 4),  # Tanglethorn
    "R:16": (7, 5),  # Giant Bat
    "R:17": (7, 6),  # Web Spinner
    "R:18": (7, 7),  # Orc Scout

    # Row 8: Layer 2 monsters (Orc Warrens)
    "R:31": (8, 0),  # Orc Slave
    "R:32": (8, 1),  # Orc Soldier
    "R:33": (8, 2),  # Orc Crossbowman
    "R:34": (8, 3),  # Warg
    "R:35": (8, 4),  # Orc Thrallmaster
    "R:36": (8, 5),  # Orc Captain
    "R:37": (8, 6),  # Warg Rider
    "R:38": (8, 7),  # Hill Troll
    "R:39": (8, 8),  # Gashnak
    "R:40": (8, 9),  # Orc Warchief

    # Row 9: Layer 3 monsters (Torture Halls)
    "R:51": (9, 0),  # Dark Acolyte
    "R:52": (9, 1),  # Ghoul
    "R:53": (9, 2),  # Mirk-troll
    "R:54": (9, 3),  # Easterling Warrior
    "R:55": (9, 4),  # Dark Sorcerer
    "R:56": (9, 5),  # Tortured Wretch
    "R:57": (9, 6),  # Easterling Champion
    "R:58": (9, 7),  # Ghast
    "R:59": (9, 8),  # Karvag
    "R:60": (9, 9),  # Master Sorcerer

    # Row 10: Layer 4 monsters (Necropolis)
    "R:71": (10, 0), # Skeleton
    "R:72": (10, 1), # Skeleton Warrior
    "R:73": (10, 2), # Zombie
    "R:74": (10, 3), # Wight
    "R:75": (10, 4), # Corpse-candle
    "R:76": (10, 5), # Necromancer Adept
    "R:77": (10, 6), # Barrow-wight
    "R:79": (10, 7), # Grishnakh

    # Row 11: Layer 5 monsters (Wraith Domain)
    "R:91": (11, 0), # Phantom
    "R:92": (11, 1), # Shadow
    "R:94": (11, 2), # Wraith
    "R:97": (11, 3), # Vampire Thrall
    "R:98": (11, 4), # Wailing Horror
    "R:99": (11, 5), # Uvatha

    # Row 12: Layer 6 monsters (Inner Sanctum)
    "R:111": (12, 0), # Black Numenorean
    "R:112": (12, 1), # Olog-hai
    "R:113": (12, 2), # Vampire
    "R:115": (12, 3), # Vampire Lord
    "R:118": (12, 4), # Khamul

    # Row 13: Layer 7 monsters (Final)
    "R:131": (13, 0), # Elite Olog-hai
    "R:134": (13, 1), # Thrain's Shade
    "R:135": (13, 2), # SAURON
}

def load_manifest():
    with open(MANIFEST_PATH, 'r') as f:
        return json.load(f)

def assemble_sheet():
    """Create the combined tileset PNG"""
    print("Assembling sprite sheet...")

    manifest = load_manifest()
    sprites = manifest.get("sprites", {})

    # Create blank sheet
    sheet_width = SHEET_COLS * TILE_SIZE
    sheet_height = SHEET_ROWS * TILE_SIZE
    sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))

    placed = 0
    missing = []

    for sprite_id, (row, col) in LAYOUT.items():
        if sprite_id in sprites and sprites[sprite_id].get("status") == "completed":
            filename = sprites[sprite_id].get("filename")
            sprite_path = GRAF_DIR / filename

            if sprite_path.exists():
                try:
                    sprite = Image.open(sprite_path).convert('RGBA')
                    # Ensure correct size
                    if sprite.size != (TILE_SIZE, TILE_SIZE):
                        sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

                    x = col * TILE_SIZE
                    y = row * TILE_SIZE
                    sheet.paste(sprite, (x, y), sprite)
                    placed += 1
                except Exception as e:
                    print(f"  Error loading {sprite_id}: {e}")
                    missing.append(sprite_id)
            else:
                print(f"  Missing file: {sprite_path}")
                missing.append(sprite_id)
        else:
            missing.append(sprite_id)

    # Save sheet
    output_path = GRAF_DIR / "64x64_necromancer.png"
    sheet.save(output_path)
    print(f"Saved: {output_path}")
    print(f"Placed {placed} sprites, {len(missing)} missing")

    if missing:
        print(f"Missing: {missing[:10]}...")

    return output_path

def generate_prf():
    """Generate the PRF mapping file"""
    print("\nGenerating PRF file...")

    prf_lines = [
        "# File: graf-necromancer.prf",
        "# Purpose: Tile mappings for Necromancer 64x64 tileset",
        "#",
        "# Format: TYPE:ID:0xROW/0xCOL",
        "# Row/Col are offset by 0x80 (128)",
        "#",
        "# Note: This file is included by graf-mac.prf when $GRAF == 'necromancer'",
        "# No additional conditional needed here.",
        "",
    ]

    # Group by type
    features = []
    monsters = []

    for sprite_id, (row, col) in LAYOUT.items():
        # Convert row/col to hex format (offset by 0x80)
        row_hex = f"0x{0x80 + row:02X}"
        col_hex = f"0x{0x80 + col:02X}"

        if sprite_id.startswith("F:"):
            feat_id = sprite_id[2:]
            features.append(f"F:{feat_id}:{row_hex}/{col_hex}")
        elif sprite_id.startswith("R:"):
            race_id = sprite_id[2:]
            monsters.append(f"R:{race_id}:{row_hex}/{col_hex}")

    prf_lines.append("# Terrain Features")
    prf_lines.extend(sorted(features, key=lambda x: int(x.split(':')[1])))
    prf_lines.append("")
    prf_lines.append("# Monsters and Players")
    prf_lines.extend(sorted(monsters, key=lambda x: int(x.split(':')[1])))

    # Save PRF
    PREF_DIR.mkdir(parents=True, exist_ok=True)
    prf_path = PREF_DIR / "graf-necromancer.prf"
    with open(prf_path, 'w') as f:
        f.write('\n'.join(prf_lines))

    print(f"Saved: {prf_path}")
    return prf_path

def main():
    print("=" * 60)
    print("SPRITE SHEET ASSEMBLY")
    print("=" * 60)

    sheet_path = assemble_sheet()
    prf_path = generate_prf()

    print("\n" + "=" * 60)
    print("ASSEMBLY COMPLETE!")
    print("=" * 60)
    print(f"\nSprite sheet: {sheet_path}")
    print(f"PRF file: {prf_path}")
    print("\nNext steps:")
    print("1. Copy files to app bundle")
    print("2. Launch game and select 'Necromancer 64x64' graphics")

if __name__ == "__main__":
    main()
