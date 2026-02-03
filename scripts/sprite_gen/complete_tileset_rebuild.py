#!/usr/bin/env python3
"""
Complete Tileset Rebuild for The Necromancer

This script:
1. Defines the authoritative tileset layout with dark version pairs
2. Generates all missing sprites using DALL-E 3
3. Creates dark versions of terrain tiles
4. Assembles the final tileset
5. Generates the matching PRF file

The darkness system requires: each terrain tile at column N has its dark version at column N+1
"""

import os
import io
import json
import time
import requests
import sys
from pathlib import Path
from datetime import datetime
from PIL import Image, ImageEnhance, ImageFilter
from openai import OpenAI

# =============================================================================
# CONFIGURATION
# =============================================================================
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "YOUR_OPENAI_API_KEY_HERE")

PROJECT_ROOT = Path(__file__).parent.parent.parent
OUTPUT_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = OUTPUT_DIR / "final"
PREF_DIR = PROJECT_ROOT / "lib" / "pref"
APP_BUNDLE_GRAF = PROJECT_ROOT / "Necromancer.app" / "Contents" / "Resources" / "lib" / "xtra" / "graf"
APP_BUNDLE_PREF = PROJECT_ROOT / "Necromancer.app" / "Contents" / "Resources" / "lib" / "pref"
MANIFEST_PATH = OUTPUT_DIR / "complete_manifest.json"

TILE_SIZE = 64
SHEET_SIZE = 1024  # 16x16 grid
RATE_LIMIT_DELAY = 13

# =============================================================================
# PROMPT TEMPLATES
# =============================================================================
TERRAIN_FLOOR_TEMPLATE = """A seamless tileable dungeon floor texture for a roguelike game.
{description}
CRITICAL: Fills ENTIRE frame edge-to-edge, NO borders. Seamless tiling. Top-down view. Dark fantasy dungeon aesthetic. Must look good at 32-64px. No characters or UI."""

TERRAIN_WALL_TEMPLATE = """A dungeon wall tile for a roguelike game.
{description}
CRITICAL: Fills ENTIRE frame edge-to-edge, NO borders. Top-down/hybrid view. DARKER than floors. Must look good at 32-64px. No characters or UI."""

TERRAIN_DOOR_TEMPLATE = """A dungeon door tile for a roguelike game, top-down view.
{description}
CRITICAL: Fills ENTIRE frame edge-to-edge. Simple flat top-down perspective matching dungeon tiles. Door centered in stone frame. Medieval iron/wood aesthetic. Must look good at 32-64px."""

TERRAIN_STAIRS_TEMPLATE = """Dungeon stairs tile for a roguelike game, top-down view.
{description}
CRITICAL: Fills ENTIRE frame edge-to-edge. Clear directional indication. Stone construction. Must look good at 32-64px."""

TERRAIN_SPECIAL_TEMPLATE = """A dungeon feature tile for a roguelike game.
{description}
CRITICAL: Fills ENTIRE frame edge-to-edge. Top-down view. Dark fantasy aesthetic. Must look good at 32-64px."""

TERRAIN_TRAP_TEMPLATE = """A dungeon trap tile for a roguelike game.
{description}
CRITICAL: Fills ENTIRE frame edge-to-edge. Visible danger indicator. Top-down view. Must look good at 32-64px."""

MONSTER_TEMPLATE = """A fantasy creature sprite for a roguelike game.
{description}
CRITICAL: Single creature centered. Solid magenta background (#FF00FF) for removal. Creature fills 80% of frame. Clear silhouette at small size. Dark fantasy style."""

ITEM_TEMPLATE = """A fantasy item sprite for a roguelike game.
{description}
CRITICAL: Single item centered. Solid magenta background (#FF00FF) for removal. Item fills 70% of frame. Clear silhouette at small size. Dark fantasy style."""

# =============================================================================
# AUTHORITATIVE TILESET LAYOUT
# =============================================================================
# Format: "sprite_id": (row, col, "category", "filename", "description", needs_dark)
# For terrain: col is the LIT version, col+1 will be DARK version

TERRAIN_LAYOUT = {
    # Row 0: Core floors (pairs: col 0-1, 2-3, 4-5, 6-7, 8-9, 10-11, 12-13, 14-15)
    "F:0": (0, 0, "floor", "t_00_darkness", "Pure black void, unexplored darkness", False),  # No dark version needed
    "F:1": (0, 2, "floor", "t_01_stone_floor", "Gray weathered flagstone dungeon floor, subtle cracks, worn smooth", True),
    "F:9": (0, 4, "floor", "t_09_fading_daylight", "Stone floor with warm golden-orange sunlight tint, near entrance", True),
    "F:31": (0, 6, "floor", "t_31_bloodstain", "Stone floor with dark dried blood stains, signs of violence", True),
    "F:86": (0, 8, "floor", "t_86_vine_floor", "Stone floor with creeping dark green vines growing over it", True),
    "F:87": (0, 10, "floor", "t_87_forest_floor", "Natural forest floor with brown earth, fallen leaves, twigs", True),
    "F:84": (0, 12, "floor", "t_84_poison_stream", "Bright green toxic poison stream flowing across stone", True),
    "F:49": (0, 14, "floor", "t_49_rubble", "Collapsed stone rubble and fallen masonry debris on floor", True),

    # Row 1: Walls and barriers
    "F:56": (1, 0, "wall", "t_56_dark_stone_wall", "Solid dark stone dungeon wall blocks, ancient hewn masonry", True),
    "F:48": (1, 2, "wall", "t_48_hidden_passage", "Wall with subtle crack hinting at secret passage", True),
    "F:85": (1, 4, "wall", "t_85_tangled_roots", "Thick tangled tree roots forming impassable barrier", True),
    "F:29": (1, 6, "wall", "t_29_prison_bars", "Vertical iron prison bars with gaps, rusty dungeon cell", True),
    "F:30": (1, 8, "wall", "t_30_chains", "Heavy iron chains hanging from ceiling over floor", True),
    "F:51": (1, 10, "wall", "t_51_quartz_vein", "Stone wall with sparkly quartz mineral deposits", True),
    # Reserved: 1,12-15

    # Row 2: Doors
    "F:32": (2, 0, "door", "t_32_iron_door", "Heavy closed iron door with rivets in stone frame, top-down", True),
    "F:4": (2, 2, "door", "t_04_open_door", "Open doorway with door swung aside, passage visible, top-down", True),
    "F:5": (2, 4, "door", "t_05_shattered_door", "Broken smashed door with wood debris scattered", True),
    "F:6": (2, 6, "door", "t_06_warded_door", "Door with faint green magical runes glowing", True),
    "F:7": (2, 8, "door", "t_07_warded_door_2", "Door with brighter blue magical ward runes", True),
    "F:8": (2, 10, "door", "t_08_warded_door_3", "Door with intense purple magical ward energy", True),
    "F:33": (2, 12, "door", "t_33_locked_door", "Iron door with visible heavy lock mechanism", True),
    "F:40": (2, 14, "door", "t_40_jammed_door", "Door stuck in frame, warped wood, won't budge", True),

    # Row 3: Stairs and vertical passages
    "F:80": (3, 0, "stairs", "t_80_stairs_up", "Stone stairs ascending upward, lighter at top", True),
    "F:81": (3, 2, "stairs", "t_81_stairs_down", "Stone stairs descending into darkness, darker at bottom", True),
    "F:82": (3, 4, "stairs", "t_82_shaft_up", "Narrow vertical shaft going up, rope ladder visible", True),
    "F:83": (3, 6, "stairs", "t_83_shaft_down", "Narrow dark hole descending into depths", True),
    # Reserved: 3,8-15

    # Row 4: Hazards and special features
    "F:2": (4, 0, "special", "t_02_bottomless_pit", "Gaping black pit with jagged rocky edges, deadly fall", True),
    "F:3": (4, 2, "special", "t_03_protective_rune", "Stone floor with glowing green protective ward circle", True),
    "F:12": (4, 4, "special", "t_12_dark_pool", "Still black water pool in stone basin, reflective", True),
    "F:13": (4, 6, "special", "t_13_morgul_runes", "Evil purple glowing Morgul runes carved in floor", True),
    "F:14": (4, 8, "special", "t_14_shadow_brazier", "Iron brazier with dark purple shadow flames", True),
    "F:15": (4, 10, "special", "t_15_torture_rack", "Wooden torture device with chains on stone floor", True),
    "F:64": (4, 12, "special", "t_64_orc_forge", "Crude orc forge with glowing orange embers, anvil", True),
    # Reserved: 4,14-15

    # Row 5: Traps
    "F:16": (5, 0, "trap", "t_16_weakened_floor", "Cracked unstable floor with visible stress lines", True),
    "F:17": (5, 2, "trap", "t_17_jagged_pit", "Open pit trap with sharp spikes visible below", True),
    "F:18": (5, 4, "trap", "t_18_poisoned_spikes", "Pit with green poison-dripping spikes", True),
    "F:20": (5, 6, "trap", "t_20_noxious_fumes", "Floor vent with green toxic gas rising", True),
    "F:21": (5, 8, "trap", "t_21_mind_fog", "Floor with purple-blue confusion mist", True),
    "F:26": (5, 10, "trap", "t_26_thick_web", "Dense sticky spider web covering floor", True),
    "F:27": (5, 12, "trap", "t_27_falling_stones", "Floor with debris, cracked ceiling above", True),
    "F:22": (5, 14, "trap", "t_22_orc_alarm", "Crude tripwire connected to alarm horn", True),
}

# Players - Row 6 (no dark versions needed)
PLAYER_LAYOUT = {
    "R:0": (6, 0, "player", "p_0_elf", "Elven ranger hero with longbow, green cloak, pointed ears"),
    "R:1": (6, 1, "player", "p_1_man", "Human warrior hero with sword, leather armor, determined"),
    "R:2": (6, 2, "player", "p_2_dwarf", "Dwarven warrior with axe, braided beard, chainmail"),
    "R:3": (6, 3, "player", "p_3_alt", "Hooded mysterious adventurer with staff, cloaked"),
}

# Monsters - Rows 7-13 (no dark versions needed)
MONSTER_LAYOUT = {
    # Row 7: Layer 1 - Forest (12 monsters)
    "R:11": (7, 0, "monster", "m_011_mirkwood_spider", "Giant spider with bristled legs, dripping fangs, dog-sized"),
    "R:12": (7, 1, "monster", "m_012_giant_rat", "Diseased giant rat, matted fur, red eyes, aggressive"),
    "R:13": (7, 2, "monster", "m_013_black_squirrel", "Corrupted black squirrel, sinister intelligent eyes"),
    "R:14": (7, 3, "monster", "m_014_crebain", "Evil black crow spy bird, glossy feathers, watching"),
    "R:15": (7, 4, "monster", "m_015_tanglethorn", "Living thornbush creature, grasping vines, poison thorns"),
    "R:16": (7, 5, "monster", "m_016_giant_bat", "Giant bat with wide leathery wings spread, fangs"),
    "R:17": (7, 6, "monster", "m_017_web_spinner", "Pale white spider trailing silk threads"),
    "R:18": (7, 7, "monster", "m_018_orc_scout", "Lean orc with crude spear, alert crouching pose"),
    "R:19": (7, 8, "monster", "m_019_swamp_adder", "Venomous snake coiled to strike, forked tongue"),
    "R:20": (7, 9, "monster", "m_020_great_spider", "Massive spider larger than man, terrifying"),
    "R:21": (7, 10, "monster", "m_021_warg_pup", "Young warg wolf pup, vicious but small"),
    "R:22": (7, 11, "monster", "m_022_broodmother", "Bloated spider queen with egg sac, horrifying"),

    # Row 8: Layer 2 - Orc Warrens (10 monsters)
    "R:31": (8, 0, "monster", "m_031_orc_slave", "Scrawny beaten orc in rags, hunched"),
    "R:32": (8, 1, "monster", "m_032_orc_soldier", "Orc warrior in dark armor with scimitar"),
    "R:33": (8, 2, "monster", "m_033_orc_crossbowman", "Orc with heavy crossbow aiming"),
    "R:34": (8, 3, "monster", "m_034_warg", "Massive evil wolf with huge fangs snarling"),
    "R:35": (8, 4, "monster", "m_035_orc_thrallmaster", "Burly orc with whip, cruel expression"),
    "R:36": (8, 5, "monster", "m_036_orc_captain", "Armored orc officer with red cloak"),
    "R:37": (8, 6, "monster", "m_037_warg_rider", "Orc mounted on snarling warg"),
    "R:38": (8, 7, "monster", "m_038_hill_troll", "Huge gray troll with tree trunk club"),
    "R:39": (8, 8, "monster", "m_039_gashnak", "Enormous alpha warg, battle-scarred, pack leader"),
    "R:40": (8, 9, "monster", "m_040_orc_warchief", "Massive orc leader in ornate dark armor"),

    # Row 9: Layer 3 - Torture Halls (10 monsters)
    "R:51": (9, 0, "monster", "m_051_dark_acolyte", "Robed human cultist with ritual dagger"),
    "R:52": (9, 1, "monster", "m_052_ghoul", "Gray undead corpse eater with long claws"),
    "R:53": (9, 2, "monster", "m_053_mirk_troll", "Dark greenish troll adapted to darkness"),
    "R:54": (9, 3, "monster", "m_054_easterling_warrior", "Eastern warrior in bronze armor, curved sword"),
    "R:55": (9, 4, "monster", "m_055_dark_sorcerer", "Black robed mage with crackling dark energy"),
    "R:56": (9, 5, "monster", "m_056_tortured_wretch", "Mad scarred prisoner, feral and dangerous"),
    "R:57": (9, 6, "monster", "m_057_easterling_champion", "Elite eastern warrior with two curved swords"),
    "R:58": (9, 7, "monster", "m_058_ghast", "Larger ghoul with sickly green stench aura"),
    "R:59": (9, 8, "monster", "m_059_karvag", "Massive torturer troll with bloody implements"),
    "R:60": (9, 9, "monster", "m_060_master_sorcerer", "Powerful mage in violet robes, glowing eyes"),

    # Row 10: Layer 4 - Necropolis (9 monsters)
    "R:71": (10, 0, "monster", "m_071_skeleton", "Animated skeleton with rusty sword, glowing eyes"),
    "R:72": (10, 1, "monster", "m_072_skeleton_warrior", "Armored skeleton with shield and blade"),
    "R:73": (10, 2, "monster", "m_073_zombie", "Shambling rotting corpse, arms outstretched"),
    "R:74": (10, 3, "monster", "m_074_wight", "Undead spirit in corpse, glowing eyes, ancient armor"),
    "R:75": (10, 4, "monster", "m_075_corpse_candle", "Floating ghostly pale flame wisp"),
    "R:76": (10, 5, "monster", "m_076_necromancer_adept", "Robed figure with skull wand, death magic"),
    "R:77": (10, 6, "monster", "m_077_barrow_wight", "Spectral king in burial robes, ancient blade"),
    "R:78": (10, 7, "monster", "m_078_bone_golem", "Towering construct of fused bones"),
    "R:79": (10, 8, "monster", "m_079_grishnakh", "Powerful wight lord with crown of bones"),

    # Row 11: Layer 5 - Wraith Domain (9 monsters)
    "R:91": (11, 0, "monster", "m_091_phantom", "Translucent gray ghost, anguished expression"),
    "R:92": (11, 1, "monster", "m_092_shadow", "Living darkness creature, only dim eyes visible"),
    "R:93": (11, 2, "monster", "m_093_whispering_shade", "Flickering dark form with faint whispers"),
    "R:94": (11, 3, "monster", "m_094_wraith", "Hooded spectral figure in tattered robes"),
    "R:95": (11, 4, "monster", "m_095_fell_spirit", "Pure malevolent energy, barely visible form"),
    "R:96": (11, 5, "monster", "m_096_spectre", "Insubstantial ghostly figure, transparent"),
    "R:97": (11, 6, "monster", "m_097_vampire_thrall", "Pale human with fangs, bloodstained"),
    "R:98": (11, 7, "monster", "m_098_wailing_horror", "Massive ghost with gaping screaming mouth"),
    "R:99": (11, 8, "monster", "m_099_uvatha", "Ringwraith in black robes, crown of shadow"),

    # Row 12: Layer 6 - Inner Sanctum (8 monsters)
    "R:111": (12, 0, "monster", "m_111_black_numenorean", "Tall dark human in fell armor with runes"),
    "R:112": (12, 1, "monster", "m_112_olog_hai", "Massive armored battle troll, disciplined"),
    "R:113": (12, 2, "monster", "m_113_vampire", "Elegant pale vampire with red eyes, fangs"),
    "R:114": (12, 3, "monster", "m_114_greater_wraith", "Powerful wraith of ancient king"),
    "R:115": (12, 4, "monster", "m_115_vampire_lord", "Regal ancient vampire in violet finery"),
    "R:116": (12, 5, "monster", "m_116_shadow_lord", "Lord of shadows, extinguishes all light"),
    "R:117": (12, 6, "monster", "m_117_maia_thrall", "Enslaved spirit, burning with stolen fire"),
    "R:118": (12, 7, "monster", "m_118_khamul", "Second Nazgul, terrifying ringwraith"),

    # Row 13: Layer 7 + Final Boss (5 monsters)
    "R:131": (13, 0, "monster", "m_131_elite_olog_hai", "Elite battle troll in black plate, red eye symbol"),
    "R:132": (13, 1, "monster", "m_132_greater_shadow", "Immense shadow that devours all light"),
    "R:133": (13, 2, "monster", "m_133_void_wraith", "Wraith from beyond, guards inner chambers"),
    "R:134": (13, 3, "monster", "m_134_thrains_shade", "Ghost of dwarf king Thrain, sorrowful"),
    "R:135": (13, 4, "monster", "m_135_sauron", "THE NECROMANCER - Dark Lord in shadow armor, burning eyes, immense power"),
}

# Items - Rows 14-15 (no dark versions needed)
# Using consolidated item categories for now
ITEM_LAYOUT = {
    # Row 14: Weapons and armor
    "I:sword": (14, 0, "item", "i_sword", "Steel longsword with crossguard"),
    "I:dagger": (14, 1, "item", "i_dagger", "Short knife or dagger"),
    "I:axe": (14, 2, "item", "i_axe", "War axe with wooden handle"),
    "I:polearm": (14, 3, "item", "i_polearm", "Spear or glaive with long shaft"),
    "I:blunt": (14, 4, "item", "i_blunt", "Mace or hammer"),
    "I:staff": (14, 5, "item", "i_staff", "Wooden staff, possibly magical"),
    "I:bow": (14, 6, "item", "i_bow", "Wooden longbow with string"),
    "I:arrow": (14, 7, "item", "i_arrow", "Bundle of arrows"),
    "I:armor": (14, 8, "item", "i_armor", "Chainmail or leather armor"),
    "I:shield": (14, 9, "item", "i_shield", "Round metal shield"),
    "I:helm": (14, 10, "item", "i_helm", "Iron helmet"),
    "I:cloak": (14, 11, "item", "i_cloak", "Traveling cloak"),
    "I:boots": (14, 12, "item", "i_boots", "Leather boots"),
    "I:gloves": (14, 13, "item", "i_gloves", "Leather gloves"),
    "I:ring": (14, 14, "item", "i_ring", "Golden ring with gem"),
    "I:amulet": (14, 15, "item", "i_amulet", "Amulet necklace with pendant"),

    # Row 15: Consumables, tools, misc
    "I:potion": (15, 0, "item", "i_potion", "Glass potion bottle with colored liquid"),
    "I:herb": (15, 1, "item", "i_herb", "Bundle of dried herbs"),
    "I:food": (15, 2, "item", "i_food", "Bread or dried meat"),
    "I:torch": (15, 3, "item", "i_torch", "Burning wooden torch"),
    "I:lantern": (15, 4, "item", "i_lantern", "Brass lantern with glow"),
    "I:chest": (15, 5, "item", "i_chest", "Wooden treasure chest"),
    "I:wand": (15, 6, "item", "i_wand", "Magical wand with crystal"),
    "I:horn": (15, 7, "item", "i_horn", "Curved horn instrument"),
    "I:pick": (15, 8, "item", "i_pick", "Mining pick or mattock"),
    "I:scroll": (15, 9, "item", "i_scroll", "Rolled parchment scroll"),
    "I:gem": (15, 10, "item", "i_gem", "Glowing gemstone"),
    "I:gold": (15, 11, "item", "i_gold", "Pile of gold coins"),
    # Effects
    "E:arrow": (15, 12, "effect", "e_arrow", "Flying arrow projectile"),
    "E:fire": (15, 13, "effect", "e_fire", "Burst of flames"),
    "E:impact": (15, 14, "effect", "e_impact", "Hit impact flash"),
    "U:cursor": (15, 15, "ui", "u_cursor", "Targeting cursor square"),
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
def load_manifest():
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, 'r') as f:
            return json.load(f)
    return {"version": "2.0", "created": datetime.now().isoformat(), "sprites": {}}

def save_manifest(manifest):
    manifest["updated"] = datetime.now().isoformat()
    with open(MANIFEST_PATH, 'w') as f:
        json.dump(manifest, f, indent=2)

def create_dark_version(img):
    """Create a darkened version of a tile for unlit areas"""
    # Convert to RGBA if needed
    img = img.convert('RGBA')

    # Reduce brightness significantly
    enhancer = ImageEnhance.Brightness(img)
    darkened = enhancer.enhance(0.3)  # 30% brightness

    # Add slight blue tint for "cold darkness" feel
    pixels = darkened.load()
    width, height = darkened.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Shift toward blue/purple slightly
            r = int(r * 0.8)
            g = int(g * 0.7)
            b = int(min(255, b * 1.1))
            pixels[x, y] = (r, g, b, a)

    return darkened

def remove_magenta_background(img):
    """Remove magenta background from sprite"""
    img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Detect magenta-ish pixels
            if r > 180 and g < 120 and b > 180:
                pixels[x, y] = (0, 0, 0, 0)  # Make transparent

    return img

def generate_image(client, prompt, is_terrain=False):
    """Generate image using DALL-E 3"""
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
        img_response = requests.get(image_url, timeout=60)
        img = Image.open(io.BytesIO(img_response.content))

        # Process based on type
        if is_terrain:
            # Just downscale, no background removal
            img = img.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
        else:
            # Remove magenta background and process
            img = remove_magenta_background(img)
            img = img.resize((TILE_SIZE * 2, TILE_SIZE * 2), Image.Resampling.LANCZOS)
            # Auto-crop and center
            img = auto_crop_center(img, TILE_SIZE)

        return img, None
    except Exception as e:
        return None, str(e)

def auto_crop_center(img, target_size):
    """Auto-crop to content and center on canvas"""
    import numpy as np

    # Find content bounds
    alpha = np.array(img)[:,:,3]
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)

    if not rows.any() or not cols.any():
        return img.resize((target_size, target_size), Image.Resampling.LANCZOS)

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]

    # Crop with padding
    padding = 2
    rmin = max(0, rmin - padding)
    rmax = min(img.height - 1, rmax + padding)
    cmin = max(0, cmin - padding)
    cmax = min(img.width - 1, cmax + padding)

    cropped = img.crop((cmin, rmin, cmax + 1, rmax + 1))

    # Scale to fit
    max_dim = max(cropped.width, cropped.height)
    if max_dim > target_size - 4:
        scale = (target_size - 4) / max_dim
        new_w = int(cropped.width * scale)
        new_h = int(cropped.height * scale)
        cropped = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Center on canvas
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    x = (target_size - cropped.width) // 2
    y = (target_size - cropped.height) // 2
    canvas.paste(cropped, (x, y), cropped)

    return canvas

# =============================================================================
# MAIN GENERATION
# =============================================================================
def generate_all_sprites(client, manifest):
    """Generate all missing sprites"""

    all_layouts = [
        ("TERRAIN", TERRAIN_LAYOUT, True),
        ("PLAYERS", PLAYER_LAYOUT, False),
        ("MONSTERS", MONSTER_LAYOUT, False),
        ("ITEMS", ITEM_LAYOUT, False),
    ]

    total_generated = 0
    total_skipped = 0
    total_failed = 0

    for category_name, layout, needs_dark in all_layouts:
        print(f"\n{'='*60}")
        print(f"GENERATING {category_name}")
        print(f"{'='*60}")

        for sprite_id, data in layout.items():
            if len(data) == 6:
                row, col, stype, filename, description, has_dark = data
            else:
                row, col, stype, filename, description = data
                has_dark = False

            # Check if already generated
            if sprite_id in manifest["sprites"] and manifest["sprites"][sprite_id].get("status") == "completed":
                print(f"  [SKIP] {sprite_id} - already done")
                total_skipped += 1
                continue

            print(f"\n  Generating {sprite_id}: {filename}")

            # Select template
            if stype == "floor":
                template = TERRAIN_FLOOR_TEMPLATE
            elif stype == "wall":
                template = TERRAIN_WALL_TEMPLATE
            elif stype == "door":
                template = TERRAIN_DOOR_TEMPLATE
            elif stype == "stairs":
                template = TERRAIN_STAIRS_TEMPLATE
            elif stype == "trap":
                template = TERRAIN_TRAP_TEMPLATE
            elif stype in ["special", "hazard"]:
                template = TERRAIN_SPECIAL_TEMPLATE
            elif stype == "monster":
                template = MONSTER_TEMPLATE
            elif stype == "player":
                template = MONSTER_TEMPLATE  # Same style
            else:
                template = ITEM_TEMPLATE

            is_terrain = stype in ["floor", "wall", "door", "stairs", "trap", "special", "hazard"]
            prompt = template.format(description=description)

            # Generate
            print(f"    Waiting {RATE_LIMIT_DELAY}s...")
            time.sleep(RATE_LIMIT_DELAY)

            img, error = generate_image(client, prompt, is_terrain)

            if error:
                print(f"    ERROR: {error}")
                total_failed += 1
                continue

            # Save sprite
            category_dir = FINAL_DIR / stype
            category_dir.mkdir(parents=True, exist_ok=True)
            output_path = category_dir / f"{filename}.png"
            img.save(output_path)
            print(f"    Saved: {output_path.name}")

            # Generate dark version if needed
            if has_dark:
                dark_img = create_dark_version(img)
                dark_path = category_dir / f"{filename}_dark.png"
                dark_img.save(dark_path)
                print(f"    Saved dark: {dark_path.name}")

            # Update manifest
            manifest["sprites"][sprite_id] = {
                "status": "completed",
                "filename": filename,
                "row": row,
                "col": col,
                "type": stype,
                "has_dark": has_dark,
                "completed": datetime.now().isoformat()
            }
            save_manifest(manifest)
            total_generated += 1

    return total_generated, total_skipped, total_failed

def assemble_tileset(manifest):
    """Assemble all sprites into final tileset"""
    print(f"\n{'='*60}")
    print("ASSEMBLING TILESET")
    print(f"{'='*60}")

    tileset = Image.new('RGBA', (SHEET_SIZE, SHEET_SIZE), (0, 0, 0, 0))
    placed = 0

    all_layouts = [TERRAIN_LAYOUT, PLAYER_LAYOUT, MONSTER_LAYOUT, ITEM_LAYOUT]

    for layout in all_layouts:
        for sprite_id, data in layout.items():
            if len(data) == 6:
                row, col, stype, filename, description, has_dark = data
            else:
                row, col, stype, filename, description = data
                has_dark = False

            # Find sprite file
            sprite_path = FINAL_DIR / stype / f"{filename}.png"
            if not sprite_path.exists():
                # Try other locations
                for subdir in ["terrain", "monsters", "items", "player", "effects", "ui"]:
                    alt_path = FINAL_DIR / subdir / f"{filename}.png"
                    if alt_path.exists():
                        sprite_path = alt_path
                        break

            if sprite_path.exists():
                sprite = Image.open(sprite_path).convert('RGBA')
                if sprite.size != (TILE_SIZE, TILE_SIZE):
                    sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)

                x, y = col * TILE_SIZE, row * TILE_SIZE
                tileset.paste(sprite, (x, y), sprite)
                placed += 1

                # Place dark version if exists
                if has_dark:
                    dark_path = FINAL_DIR / stype / f"{filename}_dark.png"
                    if dark_path.exists():
                        dark_sprite = Image.open(dark_path).convert('RGBA')
                        if dark_sprite.size != (TILE_SIZE, TILE_SIZE):
                            dark_sprite = dark_sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
                        tileset.paste(dark_sprite, ((col + 1) * TILE_SIZE, y), dark_sprite)
                        placed += 1

    # Save tileset
    output_path = OUTPUT_DIR / "64x64_necromancer.png"
    tileset.save(output_path)
    print(f"Saved: {output_path}")
    print(f"Placed {placed} tiles")

    return output_path

def generate_prf():
    """Generate PRF mapping file"""
    print(f"\n{'='*60}")
    print("GENERATING PRF")
    print(f"{'='*60}")

    lines = [
        "# File: graf-necromancer-corrected.prf",
        "# Purpose: Tile mappings for Necromancer 64x64 tileset",
        "#",
        "# Format: TYPE:ID:0xROW/0xCOL",
        "# Row/Col are offset by 0x80 (128)",
        "#",
        f"# Generated: {datetime.now().isoformat()}",
        "#",
        "# IMPORTANT: Dark versions are at column+1 for terrain",
        "",
    ]

    # Terrain features
    lines.append("# Terrain Features")
    for sprite_id, data in sorted(TERRAIN_LAYOUT.items(), key=lambda x: int(x[0].split(':')[1])):
        row, col = data[0], data[1]
        feat_id = sprite_id.split(':')[1]
        row_hex = f"0x{0x80 + row:02X}"
        col_hex = f"0x{0x80 + col:02X}"
        lines.append(f"F:{feat_id}:{row_hex}/{col_hex}")

    lines.append("")
    lines.append("# Monsters and Players")

    # Players
    for sprite_id, data in sorted(PLAYER_LAYOUT.items(), key=lambda x: int(x[0].split(':')[1])):
        row, col = data[0], data[1]
        race_id = sprite_id.split(':')[1]
        row_hex = f"0x{0x80 + row:02X}"
        col_hex = f"0x{0x80 + col:02X}"
        lines.append(f"R:{race_id}:{row_hex}/{col_hex}")

    # Monsters
    for sprite_id, data in sorted(MONSTER_LAYOUT.items(), key=lambda x: int(x[0].split(':')[1])):
        row, col = data[0], data[1]
        race_id = sprite_id.split(':')[1]
        row_hex = f"0x{0x80 + row:02X}"
        col_hex = f"0x{0x80 + col:02X}"
        lines.append(f"R:{race_id}:{row_hex}/{col_hex}")

    # Save
    PREF_DIR.mkdir(parents=True, exist_ok=True)
    prf_path = PREF_DIR / "graf-necromancer-corrected.prf"
    with open(prf_path, 'w') as f:
        f.write('\n'.join(lines))

    print(f"Saved: {prf_path}")
    return prf_path

def copy_to_app_bundle(tileset_path, prf_path):
    """Copy to app bundle"""
    import shutil

    print(f"\n{'='*60}")
    print("COPYING TO APP BUNDLE")
    print(f"{'='*60}")

    APP_BUNDLE_GRAF.mkdir(parents=True, exist_ok=True)
    APP_BUNDLE_PREF.mkdir(parents=True, exist_ok=True)

    shutil.copy2(tileset_path, APP_BUNDLE_GRAF / "64x64_necromancer.png")
    shutil.copy2(prf_path, APP_BUNDLE_PREF / "graf-necromancer-corrected.prf")

    print("Done!")

def main():
    print("=" * 70)
    print("THE NECROMANCER - COMPLETE TILESET REBUILD")
    print("=" * 70)

    # Setup
    FINAL_DIR.mkdir(parents=True, exist_ok=True)

    client = OpenAI(api_key=OPENAI_API_KEY)
    manifest = load_manifest()

    # Count what we need
    total_terrain = len(TERRAIN_LAYOUT)
    total_players = len(PLAYER_LAYOUT)
    total_monsters = len(MONSTER_LAYOUT)
    total_items = len(ITEM_LAYOUT)
    total = total_terrain + total_players + total_monsters + total_items

    print(f"\nSprites to generate:")
    print(f"  Terrain: {total_terrain} (with dark versions)")
    print(f"  Players: {total_players}")
    print(f"  Monsters: {total_monsters}")
    print(f"  Items: {total_items}")
    print(f"  TOTAL: {total}")

    # Generate
    generated, skipped, failed = generate_all_sprites(client, manifest)

    # Assemble
    tileset_path = assemble_tileset(manifest)

    # Generate PRF
    prf_path = generate_prf()

    # Copy to app
    copy_to_app_bundle(tileset_path, prf_path)

    # Summary
    print(f"\n{'='*70}")
    print("COMPLETE")
    print(f"{'='*70}")
    print(f"Generated: {generated}")
    print(f"Skipped: {skipped}")
    print(f"Failed: {failed}")
    print(f"\nTileset: {tileset_path}")
    print(f"PRF: {prf_path}")

if __name__ == "__main__":
    main()
