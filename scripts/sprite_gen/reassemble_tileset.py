#!/usr/bin/env python3
"""
Tileset Reassembly Script for The Necromancer

This script:
1. Reads all sprites from final/ directory
2. Assembles them into a 1024x1024 tileset with documented positions
3. Generates a matching PRF file
4. Reports missing sprites and empty positions

The layout is AUTHORITATIVE - if a sprite doesn't exist, the position stays empty.
"""

import json
from pathlib import Path
from PIL import Image
from datetime import datetime

# =============================================================================
# CONFIGURATION
# =============================================================================
PROJECT_ROOT = Path(__file__).parent.parent.parent
GRAF_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = GRAF_DIR / "final"
PREF_DIR = PROJECT_ROOT / "lib" / "pref"
APP_BUNDLE_GRAF = PROJECT_ROOT / "Necromancer.app" / "Contents" / "Resources" / "lib" / "xtra" / "graf"
APP_BUNDLE_PREF = PROJECT_ROOT / "Necromancer.app" / "Contents" / "Resources" / "lib" / "pref"

TILE_SIZE = 64
SHEET_SIZE = 1024  # 16x16 tiles

# =============================================================================
# AUTHORITATIVE TILESET LAYOUT
# =============================================================================
# Format: "sprite_id": (row, col, "filename_in_final")
# This is the SINGLE SOURCE OF TRUTH for tile positions

LAYOUT = {
    # =========================================================================
    # ROW 0: Floor tiles (F:0-9, F:31, F:84, F:86, F:87)
    # =========================================================================
    "F:0":  (0, 0, "terrain/t_00_darkness.png"),         # Darkness/unexplored
    "F:1":  (0, 1, "terrain/t_01_stone_floor.png"),      # Stone floor (most common)
    "F:9":  (0, 2, "terrain/t_09_fading_daylight.png"),  # Fading daylight
    "F:31": (0, 3, "terrain/t_31_bloodstain.png"),       # Bloodstain
    "F:86": (0, 4, "terrain/t_86_vine_floor.png"),       # Vine floor
    "F:2":  (0, 5, "terrain/t_02_bottomless_pit.png"),   # Bottomless pit
    "F:3":  (0, 6, "terrain/t_03_protective_rune.png"),  # Protective rune
    "F:87": (0, 7, "terrain/t_87_forest_floor.png"),     # Forest floor
    "F:84": (0, 8, "terrain/t_84_poison_stream.png"),    # Poison stream
    # Cols 9-15 reserved for future floors

    # =========================================================================
    # ROW 1: Walls and Doors (F:56, F:48, F:85, F:29, F:32, F:4-8, F:30)
    # =========================================================================
    "F:56": (1, 0, "terrain/t_56_dark_stone_wall.png"),  # Dark stone wall
    "F:48": (1, 1, "terrain/t_48_hidden_passage.png"),   # Hidden passage
    "F:85": (1, 2, "terrain/t_85_tangled_roots.png"),    # Tangled roots
    "F:29": (1, 3, "terrain/t_29_prison_bars.png"),      # Prison bars
    "F:32": (1, 4, "terrain/t_32_iron_door.png"),        # Iron door (closed)
    "F:4":  (1, 5, "terrain/t_04_open_door.png"),        # Open door
    "F:5":  (1, 6, "terrain/t_05_shattered_door.png"),   # Shattered door
    "F:6":  (1, 7, "terrain/t_06_warded_door.png"),      # Warded door 1
    "F:7":  (1, 8, "terrain/t_07_warded_door_2.png"),    # Warded door 2
    "F:8":  (1, 9, "terrain/t_08_warded_door_3.png"),    # Warded door 3
    "F:30": (1, 10, "terrain/t_30_chains.png"),          # Chains
    # Cols 11-15 reserved

    # =========================================================================
    # ROW 2: Stairs and Special Features (F:80-83, F:64, F:12-15)
    # =========================================================================
    "F:80": (2, 0, "terrain/t_80_stairs_up.png"),        # Stairs up
    "F:81": (2, 1, "terrain/t_81_stairs_down.png"),      # Stairs down
    "F:82": (2, 2, "terrain/t_82_shaft_up.png"),         # Shaft up
    "F:83": (2, 3, "terrain/t_83_shaft_down.png"),       # Shaft down
    "F:64": (2, 4, "terrain/t_64_orc_forge.png"),        # Orc forge
    "F:12": (2, 5, "terrain/t_12_dark_pool.png"),        # Dark pool
    "F:13": (2, 6, "terrain/t_13_morgul_runes.png"),     # Morgul runes
    "F:14": (2, 7, "terrain/t_14_shadow_brazier.png"),   # Shadow brazier
    "F:15": (2, 8, "terrain/t_15_torture_rack.png"),     # Torture rack
    # Cols 9-15 reserved

    # =========================================================================
    # ROW 3: Traps (F:16-28)
    # =========================================================================
    "F:16": (3, 0, "terrain/t_16_weakened_floor.png"),   # Weakened floor
    "F:17": (3, 1, "terrain/t_17_jagged_pit.png"),       # Jagged pit
    "F:20": (3, 2, "terrain/t_20_noxious_fumes.png"),    # Noxious fumes
    "F:22": (3, 3, "terrain/t_22_orc_alarm.png"),        # Orc alarm
    "F:26": (3, 4, "terrain/t_26_thick_web.png"),        # Thick web
    "F:27": (3, 5, "terrain/t_27_falling_stones.png"),   # Falling stones
    "F:18": (3, 6, "terrain/t_18_poisoned_spikes.png"),  # Poisoned spikes
    "F:19": (3, 7, "terrain/t_19_poison_needle.png"),    # Poison needle
    "F:21": (3, 8, "terrain/t_21_mind_fog.png"),         # Mind fog
    "F:23": (3, 9, "terrain/t_23_blinding_glyph.png"),   # Blinding glyph
    "F:24": (3, 10, "terrain/t_24_caltrops.png"),        # Caltrops
    "F:25": (3, 11, "terrain/t_25_bat_roost.png"),       # Bat roost
    "F:28": (3, 12, "terrain/t_28_pool_filth.png"),      # Pool of filth
    # Cols 13-15 reserved

    # =========================================================================
    # ROW 4: Items - Weapons and Armor
    # =========================================================================
    "I:sword":      (4, 0, "items/i_sword.png"),
    "I:polearm":    (4, 1, "items/i_polearm.png"),
    "I:blunt":      (4, 2, "items/i_blunt.png"),
    "I:bow":        (4, 3, "items/i_bow.png"),
    "I:armor":      (4, 4, "items/i_armor.png"),
    "I:shield":     (4, 5, "items/i_shield.png"),
    "I:helm":       (4, 6, "items/i_helm.png"),
    "I:misc_armor": (4, 7, "items/i_misc_armor.png"),
    "I:potion":     (4, 8, "items/i_potion.png"),
    "I:herb":       (4, 9, "items/i_herb.png"),
    "I:ring":       (4, 10, "items/i_ring.png"),
    "I:staff":      (4, 11, "items/i_staff.png"),
    "I:arrow":      (4, 12, "items/i_arrow.png"),
    "I:torch":      (4, 13, "items/i_torch.png"),
    "I:lantern":    (4, 14, "items/i_lantern.png"),
    "I:amulet":     (4, 15, "items/i_amulet.png"),

    # =========================================================================
    # ROW 5: Effects and UI
    # =========================================================================
    "E:arrow":    (5, 0, "effects/e_arrow.png"),
    "E:fire":     (5, 1, "effects/e_fire.png"),
    "E:darkness": (5, 2, "effects/e_darkness.png"),
    "E:impact":   (5, 3, "effects/e_impact.png"),
    "U:pile":     (5, 4, "ui/u_item_pile.png"),
    "U:light":    (5, 5, "ui/u_light_source.png"),
    "U:cursor":   (5, 6, "ui/u_cursor.png"),
    "U:poison":   (5, 7, "ui/u_status_poison.png"),
    "U:wounded":  (5, 8, "ui/u_status_wounded.png"),
    # Cols 9-15 reserved

    # =========================================================================
    # ROW 6: Players
    # =========================================================================
    "R:0": (6, 0, "player/p_0_elf.png"),      # Elf
    "R:1": (6, 1, "player/p_1_man.png"),      # Man
    "R:2": (6, 2, "player/p_2_dwarf.png"),    # Dwarf
    "R:3": (6, 3, "player/p_3_alt.png"),      # Alternate
    # Cols 4-15 reserved for player variants

    # =========================================================================
    # ROW 7: Layer 1 Monsters - Forest Breach
    # =========================================================================
    "R:11": (7, 0, "monsters/m_011_mirkwood_spider.png"),
    "R:12": (7, 1, "monsters/m_012_giant_rat.png"),
    "R:13": (7, 2, "monsters/m_013_black_squirrel.png"),
    "R:14": (7, 3, "monsters/m_014_crebain.png"),
    "R:15": (7, 4, "monsters/m_015_tanglethorn.png"),
    "R:16": (7, 5, "monsters/m_016_giant_bat.png"),
    "R:17": (7, 6, "monsters/m_017_web_spinner.png"),
    "R:18": (7, 7, "monsters/m_018_orc_scout.png"),
    # Cols 8-15 reserved

    # =========================================================================
    # ROW 8: Layer 2 Monsters - Orc Warrens
    # =========================================================================
    "R:31": (8, 0, "monsters/m_031_orc_slave.png"),
    "R:32": (8, 1, "monsters/m_032_orc_soldier.png"),
    "R:33": (8, 2, "monsters/m_033_orc_crossbowman.png"),
    "R:34": (8, 3, "monsters/m_034_warg.png"),
    "R:35": (8, 4, "monsters/m_035_orc_thrallmaster.png"),
    "R:36": (8, 5, "monsters/m_036_orc_captain.png"),
    "R:37": (8, 6, "monsters/m_037_warg_rider.png"),
    "R:38": (8, 7, "monsters/m_038_hill_troll.png"),
    "R:39": (8, 8, "monsters/m_039_gashnak.png"),
    "R:40": (8, 9, "monsters/m_040_orc_warchief.png"),
    # Cols 10-15 reserved

    # =========================================================================
    # ROW 9: Layer 3 Monsters - Torture Halls
    # =========================================================================
    "R:51": (9, 0, "monsters/m_051_dark_acolyte.png"),
    "R:52": (9, 1, "monsters/m_052_ghoul.png"),
    "R:53": (9, 2, "monsters/m_053_mirk_troll.png"),
    "R:54": (9, 3, "monsters/m_054_easterling_warrior.png"),
    "R:55": (9, 4, "monsters/m_055_dark_sorcerer.png"),
    "R:56": (9, 5, "monsters/m_056_tortured_wretch.png"),
    "R:57": (9, 6, "monsters/m_057_easterling_champion.png"),
    "R:58": (9, 7, "monsters/m_058_ghast.png"),
    "R:59": (9, 8, "monsters/m_059_karvag.png"),
    "R:60": (9, 9, "monsters/m_060_master_sorcerer.png"),
    # Cols 10-15 reserved

    # =========================================================================
    # ROW 10: Layer 4 Monsters - Necropolis
    # =========================================================================
    "R:71": (10, 0, "monsters/m_071_skeleton.png"),
    "R:72": (10, 1, "monsters/m_072_skeleton_warrior.png"),
    "R:73": (10, 2, "monsters/m_073_zombie.png"),
    "R:74": (10, 3, "monsters/m_074_wight.png"),
    "R:75": (10, 4, "monsters/m_075_corpse_candle.png"),
    "R:76": (10, 5, "monsters/m_076_necromancer_adept.png"),
    "R:77": (10, 6, "monsters/m_077_barrow_wight.png"),
    "R:79": (10, 7, "monsters/m_079_grishnakh.png"),
    # Cols 8-15 reserved

    # =========================================================================
    # ROW 11: Layer 5 Monsters - Wraith Domain
    # =========================================================================
    "R:91": (11, 0, "monsters/m_091_phantom.png"),
    "R:92": (11, 1, "monsters/m_092_shadow.png"),
    "R:94": (11, 2, "monsters/m_094_wraith.png"),
    "R:97": (11, 3, "monsters/m_097_vampire_thrall.png"),
    "R:98": (11, 4, "monsters/m_098_wailing_horror.png"),
    "R:99": (11, 5, "monsters/m_099_uvatha.png"),
    # Cols 6-15 reserved

    # =========================================================================
    # ROW 12: Layer 6 Monsters - Inner Sanctum
    # =========================================================================
    "R:111": (12, 0, "monsters/m_111_black_numenorean.png"),
    "R:112": (12, 1, "monsters/m_112_olog_hai.png"),
    "R:113": (12, 2, "monsters/m_113_vampire.png"),
    "R:115": (12, 3, "monsters/m_115_vampire_lord.png"),
    "R:118": (12, 4, "monsters/m_118_khamul.png"),
    # Cols 5-15 reserved

    # =========================================================================
    # ROW 13: Layer 7 Monsters - Final
    # =========================================================================
    "R:131": (13, 0, "monsters/m_131_elite_olog_hai.png"),
    "R:134": (13, 1, "monsters/m_134_thrains_shade.png"),
    "R:135": (13, 2, "monsters/m_135_sauron.png"),
    # Cols 3-15 reserved

    # =========================================================================
    # ROW 14: Additional Items (overflow)
    # =========================================================================
    "I:cloak":  (14, 0, "items/i_cloak.png"),
    "I:boots":  (14, 1, "items/i_boots.png"),
    "I:gloves": (14, 2, "items/i_gloves.png"),
    "I:chest":  (14, 3, "items/i_chest.png"),
    "I:horn":   (14, 4, "items/i_horn.png"),
    "I:wand":   (14, 5, "items/i_wand.png"),
    # Cols 6-15 reserved

    # =========================================================================
    # ROW 15: Reserved for future use
    # =========================================================================
}


def assemble_tileset():
    """Assemble tileset from final/ sprites using LAYOUT"""
    print("=" * 70)
    print("TILESET REASSEMBLY")
    print("=" * 70)

    # Create blank tileset with transparency
    tileset = Image.new('RGBA', (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))

    placed = 0
    missing = []
    found_files = []

    for sprite_id, (row, col, filename) in LAYOUT.items():
        sprite_path = FINAL_DIR / filename

        if sprite_path.exists():
            try:
                sprite = Image.open(sprite_path).convert('RGBA')

                # Ensure correct size
                if sprite.size != (TILE_SIZE, TILE_SIZE):
                    sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)

                # Calculate position
                x = col * TILE_SIZE
                y = row * TILE_SIZE

                # Paste sprite
                tileset.paste(sprite, (x, y), sprite)
                placed += 1
                found_files.append((sprite_id, row, col, filename))

            except Exception as e:
                print(f"  ERROR loading {sprite_id}: {e}")
                missing.append((sprite_id, row, col, filename, str(e)))
        else:
            missing.append((sprite_id, row, col, filename, "File not found"))

    # Save tileset
    output_path = GRAF_DIR / "64x64_necromancer.png"
    tileset.save(output_path)

    print(f"\nPlaced: {placed} sprites")
    print(f"Missing: {len(missing)} sprites")
    print(f"Saved: {output_path}")

    return output_path, placed, missing, found_files


def generate_prf(found_files):
    """Generate PRF file from successfully placed sprites"""
    print("\n" + "=" * 70)
    print("PRF GENERATION")
    print("=" * 70)

    lines = [
        "# File: graf-necromancer.prf",
        "# Purpose: Tile mappings for Necromancer 64x64 tileset",
        "#",
        "# Format: TYPE:ID:0xROW/0xCOL",
        "# Row/Col are offset by 0x80 (128)",
        "#",
        f"# Generated: {datetime.now().isoformat()}",
        f"# Total mappings: {len(found_files)}",
        "#",
        "",
    ]

    # Group by type
    features = []
    monsters = []
    items = []
    effects = []
    ui = []

    for sprite_id, row, col, filename in found_files:
        row_hex = f"0x{0x80 + row:02X}"
        col_hex = f"0x{0x80 + col:02X}"

        if sprite_id.startswith("F:"):
            feat_id = sprite_id[2:]
            features.append((int(feat_id), f"F:{feat_id}:{row_hex}/{col_hex}"))
        elif sprite_id.startswith("R:"):
            race_id = sprite_id[2:]
            monsters.append((int(race_id), f"R:{race_id}:{row_hex}/{col_hex}"))
        elif sprite_id.startswith("I:"):
            # Items don't have numeric IDs in PRF, skip for now
            pass
        elif sprite_id.startswith("E:"):
            # Effects don't have numeric IDs in PRF, skip for now
            pass
        elif sprite_id.startswith("U:"):
            # UI elements don't have numeric IDs in PRF, skip for now
            pass

    # Add features
    lines.append("# Terrain Features")
    for _, line in sorted(features, key=lambda x: x[0]):
        lines.append(line)

    lines.append("")

    # Add monsters/players
    lines.append("# Monsters and Players")
    for _, line in sorted(monsters, key=lambda x: x[0]):
        lines.append(line)

    # Write PRF
    prf_content = '\n'.join(lines)

    # Save to lib/pref/
    PREF_DIR.mkdir(parents=True, exist_ok=True)
    prf_path = PREF_DIR / "graf-necromancer-corrected.prf"
    with open(prf_path, 'w') as f:
        f.write(prf_content)

    print(f"Saved: {prf_path}")
    print(f"  Features: {len(features)}")
    print(f"  Monsters/Players: {len(monsters)}")

    return prf_path


def copy_to_app_bundle(tileset_path, prf_path):
    """Copy files to app bundle"""
    print("\n" + "=" * 70)
    print("COPYING TO APP BUNDLE")
    print("=" * 70)

    import shutil

    # Copy tileset
    APP_BUNDLE_GRAF.mkdir(parents=True, exist_ok=True)
    dest_tileset = APP_BUNDLE_GRAF / "64x64_necromancer.png"
    shutil.copy2(tileset_path, dest_tileset)
    print(f"Copied tileset: {dest_tileset}")

    # Copy PRF
    APP_BUNDLE_PREF.mkdir(parents=True, exist_ok=True)
    dest_prf = APP_BUNDLE_PREF / "graf-necromancer-corrected.prf"
    shutil.copy2(prf_path, dest_prf)
    print(f"Copied PRF: {dest_prf}")


def report_missing(missing):
    """Report missing sprites"""
    if not missing:
        return

    print("\n" + "=" * 70)
    print("MISSING SPRITES")
    print("=" * 70)

    # Group by category
    terrain = [m for m in missing if m[0].startswith("F:")]
    monsters = [m for m in missing if m[0].startswith("R:")]
    items = [m for m in missing if m[0].startswith("I:")]
    other = [m for m in missing if not any(m[0].startswith(p) for p in ["F:", "R:", "I:"])]

    if terrain:
        print("\nTerrain:")
        for sprite_id, row, col, filename, reason in terrain:
            print(f"  {sprite_id}: {filename} - {reason}")

    if monsters:
        print("\nMonsters/Players:")
        for sprite_id, row, col, filename, reason in monsters:
            print(f"  {sprite_id}: {filename} - {reason}")

    if items:
        print("\nItems:")
        for sprite_id, row, col, filename, reason in items:
            print(f"  {sprite_id}: {filename} - {reason}")

    if other:
        print("\nOther:")
        for sprite_id, row, col, filename, reason in other:
            print(f"  {sprite_id}: {filename} - {reason}")


def main():
    print("=" * 70)
    print("NECROMANCER TILESET REASSEMBLY")
    print("=" * 70)
    print(f"Source: {FINAL_DIR}")
    print(f"Layout entries: {len(LAYOUT)}")

    # Assemble
    tileset_path, placed, missing, found_files = assemble_tileset()

    # Generate PRF
    prf_path = generate_prf(found_files)

    # Report missing
    report_missing(missing)

    # Copy to app bundle
    copy_to_app_bundle(tileset_path, prf_path)

    # Summary
    print("\n" + "=" * 70)
    print("COMPLETE")
    print("=" * 70)
    print(f"Tileset: {tileset_path}")
    print(f"PRF: {prf_path}")
    print(f"Placed: {placed}/{len(LAYOUT)} sprites")

    if missing:
        print(f"\nMissing {len(missing)} sprites - see report above")
        print("Run generate_environment.py or generate_all.py to create missing sprites")


if __name__ == "__main__":
    main()
