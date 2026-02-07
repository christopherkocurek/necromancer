#!/usr/bin/env python3
"""Build a complete mapping of tileset grid positions to human-readable names.
Tileset: 32x32 grid of 64x64 tiles (2048x2048 pixels).
Output: Python dict mapping "row_col" -> short name (1-2 words max).
"""

# We'll build the mapping by going through each section of tile_mapper.gd.
# In tile_mapper.gd, coordinates are Vector2i(col, row).

tileset_map = {}

def add(row, col, name):
    key = f"{row}_{col}"
    tileset_map[key] = name

# =============================================================================
# TERRAIN (Rows 0-5)
# =============================================================================
# The terrain_coords are loaded in two phases:
# Phase 1: terrain.txt IDs 0-87 mapped sequentially (IDs 0-15 -> row 0, 16-31 -> row 1, etc.)
# Phase 2: Level.Tile enum overrides (0-26) that reassign some IDs.
#
# Since many terrain.txt IDs are "unused", and the game uses Level.Tile enum values,
# we focus on what ACTUALLY ends up at each grid position.
#
# Let's first map the terrain.txt names to their original sequential positions,
# then note which positions are meaningful.

# terrain.txt names by ID:
terrain_names = {
    0: "Darkness",
    1: "Floor",
    2: "Bottomless Pit",
    3: "Rune",
    4: "Open Door",
    5: "Broken Door",
    6: "Warded Door",
    7: "Warded Door",
    8: "Warded Door",
    9: "Daylight",
    10: "Floor",
    11: "Wall",
    12: "Dark Pool",
    13: "Morgul Runes",
    14: "Shadow Brazier",
    15: "Torture Rack",
    16: "Weak Floor",
    17: "Jagged Pit",
    18: "Spike Pit",
    19: "Poison Trap",
    20: "Noxious Fumes",
    21: "Mind Fog",
    22: "Orc Alarm",
    23: "Blind Glyph",
    24: "Caltrops",
    25: "Bat Roost",
    26: "Thick Web",
    27: "Falling Stone",
    28: "Filth Pool",
    29: "Prison Bars",
    30: "Chains",
    31: "Bloodstain",
    32: "Iron Door",
    33: "Locked Door",
    34: "Locked Door",
    35: "Locked Door",
    36: "Locked Door",
    37: "Locked Door",
    38: "Locked Door",
    39: "Locked Door",
    40: "Jammed Door",
    41: "Jammed Door",
    42: "Jammed Door",
    43: "Jammed Door",
    44: "Jammed Door",
    45: "Jammed Door",
    46: "Jammed Door",
    47: "Jammed Door",
    48: "Hidden Pass",
    49: "Fallen Masonry",
    50: "Unused",
    51: "Quartz Vein",
    52: "Unused",
    53: "Unused",
    54: "Unused",
    55: "Unused",
    56: "Stone Wall",
    57: "Stone Wall",
    58: "Stone Wall",
    59: "Stone Wall",
    60: "Unused",
    61: "Unused",
    62: "Unused",
    63: "Stone Wall",
    64: "Orc Forge",
    65: "Orc Forge",
    66: "Orc Forge",
    67: "Orc Forge",
    68: "Orc Forge",
    69: "Orc Forge",
    70: "Shadow Forge",
    71: "Shadow Forge",
    72: "Shadow Forge",
    73: "Shadow Forge",
    74: "Shadow Forge",
    75: "Shadow Forge",
    76: "Angdur Forge",
    77: "Angdur Forge",
    78: "Angdur Forge",
    79: "Angdur Forge",
    80: "Stairs Up",
    81: "Stairs Down",
    82: "Shaft Up",
    83: "Shaft Down",
    84: "Poison Stream",
    85: "Tangled Roots",
    86: "Vine Floor",
    87: "Forest Floor",
}

# Phase 1: Sequential mapping. IDs 0-87 -> (col, row) pairs.
# Each ID gets light at (col, row) and dark at (col+1, row).
# ID 0 -> col=0,row=0; ID 1 -> col=2,row=0; ... ID 15 -> col=30,row=0
# ID 16 -> col=0,row=1; etc.
for tid in range(88):
    row = tid // 16
    col_base = (tid % 16) * 2
    light_col = col_base
    dark_col = col_base + 1
    light_row = row
    dark_row = row

    name = terrain_names.get(tid, "Unused")
    if name != "Unused":
        add(light_row, light_col, f"{name} Lit")
        add(dark_row, dark_col, f"{name} Dark")

# Phase 2: Level.Tile enum overrides. These REPLACE some entries.
# The game actually uses these tile IDs, so these positions are the "real" ones.
# But they point to the SAME grid positions already named above, just with different
# semantic meaning. The override reassigns which terrain_id maps to which position,
# but the positions themselves already have sprites from Phase 1.
# So the grid position names from Phase 1 are still correct for the sprites.

# However, some overrides point to ROW 18 (new terrain) which wasn't in Phase 1:
# Let's handle row 18 entries explicitly.

# =============================================================================
# ROW 18: New Terrain Types
# =============================================================================
row18_terrain = {
    (18, 0): "Web Lit",
    (18, 1): "Web Dark",
    (18, 2): "Dark Pool Lit",
    (18, 3): "Dark Pool Dark",
    (18, 4): "Morgul Rune Lit",
    (18, 5): "Morgul Rune Dark",
    (18, 6): "Shadow Brazr Lit",
    (18, 7): "Shadow Brazr Dark",
    (18, 8): "Warding Lit",
    (18, 9): "Warding Dark",
    (18, 10): "Bone Pile Lit",
    (18, 11): "Bone Pile Dark",
    (18, 12): "Shadow Flr Lit",
    (18, 13): "Shadow Flr Dark",
    (18, 14): "Throne Lit",
    (18, 15): "Throne Dark",
    (18, 16): "Vine Floor Lit",
    (18, 17): "Vine Floor Dark",
    (18, 18): "Stairs Dn Lit",
    (18, 19): "Stairs Dn Dark",
    (18, 20): "Poison Str Lit",
    (18, 21): "Poison Str Dark",
}
for (r, c), name in row18_terrain.items():
    add(r, c, name)

# =============================================================================
# PLAYER SPRITES (Rows 6-9, cols 0-11)
# =============================================================================
# Row 6=Elf, 7=Man, 8=Dwarf, 9=Hobbit
# Cols 0-5: light (House1M, House1F, House2M, House2F, House3M, House3F)
# Cols 6-11: dark versions of same
races = {6: "Elf", 7: "Man", 8: "Dwarf", 9: "Hobbit"}
house_labels = ["H1M", "H1F", "H2M", "H2F", "H3M", "H3F"]

for row, race in races.items():
    for col in range(6):
        add(row, col, f"{race} {house_labels[col]}")
    for col in range(6, 12):
        add(row, col, f"{race} {house_labels[col-6]}Dk")

# =============================================================================
# EFFECTS (Row 6, cols 12-31) -- from _load_effect_coords
# =============================================================================
# effect_coords[0..19] -> Vector2i(12..31, 6)
# We don't have specific names for these, label generically
for i in range(20):
    add(6, 12 + i, f"Effect {i}")

# =============================================================================
# ROW 7-9 cols 12-31: Empty (player rows only use 0-11)
# =============================================================================
# Nothing mapped here

# =============================================================================
# ROW 10: Not mapped in tile_mapper.gd (available)
# =============================================================================

# =============================================================================
# ITEMS (Rows 11-17)
# =============================================================================
# item_coords maps item_id -> Vector2i(col, row)
# We need to build a reverse mapping (row, col) -> name
# Only use canonical items (not duplicates)

# Canonical item entries from tile_mapper.gd with their comments
item_positions = {
    (11, 0): "Item Pile",
    (11, 1): "Serp Ring",
    (11, 2): "Ring",
    (11, 3): "Amulet",
    (11, 4): "Pearl",
    (11, 5): "Jewel",
    (11, 6): "Necklace",
    (11, 7): "War Hammer",
    (11, 8): "Iron Crown",
    (11, 9): "Elven Light",
    (11, 10): "Wanderer Robe",
    (11, 11): "Ranger Armor",
    (11, 12): "Scout Armor",
    (11, 13): "Shadow Armor",
    (11, 14): "Gondor Mail",
    (11, 15): "Dwarf Hauberk",
    (11, 16): "Mithril Mail",
    (11, 17): "Orc Skeleton",
    (11, 18): "Human Skel",
    (11, 19): "Elf Skeleton",
    (11, 20): "Buckler",
    (11, 21): "Tower Shield",
    (11, 22): "Mithril Shield",
    (11, 23): "Ranger Knife",
    (11, 24): "Orc Blade",
    (11, 25): "Wood Blade",
    (11, 26): "Longsword",
    (11, 27): "Rohirrim Blade",
    (11, 28): "Numenor Blade",
    (11, 29): "Mithril Sword",
    (11, 30): "Mithril Great",
    (11, 31): "Hunt Spear",
    (12, 0): "Tower Spear",
    (12, 1): "Morgul Glaive",
    (12, 2): "Wood Axe",
    (12, 3): "Dwarf Axe",
    (12, 4): "Erebor Axe",
    (12, 5): "Oak Staff",
    (12, 6): "Dwarf Hammer",
    (12, 7): "Miner Spade",
    (12, 8): "Dwarf Mattock",
    (12, 9): "Iron Helm",
    (12, 10): "Tower Helm",
    (12, 11): "Dwarf Mask",
    (12, 12): "Mithril Helm",
    (12, 13): "Crown",
    (12, 14): "Travel Cloak",
    (12, 15): "Shadow Cloak",
    (12, 16): "Wolf Hame",
    (12, 17): "Bat Fell",
    (12, 18): "Silvan Bow",
    (12, 19): "Longbow",
    (12, 20): "Dragon Bow",
    (12, 21): "Arrow",
    (12, 22): "Sling",
    (12, 23): "Fine Sling",
    (12, 24): "Sling Stone",
    (12, 25): "Travel Boots",
    (12, 26): "Iron Greaves",
    (12, 27): "Mithril Greave",
    (12, 28): "Leather Glove",
    (12, 29): "Iron Gauntlet",
    (12, 30): "Mithril Gaunt",
    (12, 31): "Wood Torch",
    (13, 0): "Brass Lantern",
    (13, 1): "Jewel Lamp",
    (13, 2): "Star Glass",
    (13, 3): "Last Chances",
    (13, 4): "Constitution",
    (13, 5): "Grace",
    (13, 6): "Regeneration",
    (13, 7): "Preservation",
    (13, 8): "Blessed Realm",
    (13, 9): "Haunt Dreams",
    (13, 10): "Vigilant Eye",
    (13, 11): "Secrets",
    (13, 12): "Ered Luin",
    (13, 13): "Evasion",
    (13, 14): "Protection",
    (13, 15): "Strength",
    (13, 16): "Dexterity",
    (13, 17): "Frost",
    (13, 18): "Warmth",
    (13, 19): "Accuracy",
    (13, 20): "Free Action",
    (13, 21): "Cowardice",
    (13, 22): "Shadow Vang",
    (13, 23): "Venom End",
    (13, 24): "Laiquendi",
    (13, 25): "Imprisonment",
    (13, 26): "Freedom",
    (13, 27): "Light",
    (13, 28): "Sanctity",
    (13, 29): "Understanding",
    (13, 30): "Revelations",
    (13, 31): "Treasures",
    (14, 0): "Foes",
    (14, 1): "Slumber",
    (14, 2): "Majesty",
    (14, 3): "Self Knowledge",
    (14, 4): "Warding",
    (14, 5): "Dismay",
    (14, 6): "Recharging",
    (14, 7): "Summoning",
    (14, 8): "Shadows",
    (14, 9): "Frost Wand",
    (14, 10): "Fire Wand",
    (14, 11): "Slow Wand",
    (14, 12): "Light Wand",
    (14, 13): "Fear Wand",
    (14, 14): "Sleep Wand",
    (14, 15): "Terror Horn",
    (14, 16): "Thunder Horn",
    (14, 17): "Force Horn",
    (14, 18): "Blast Horn",
    (14, 19): "Challenge Horn",
    (14, 20): "Fairy Flute",
    (14, 21): "Miruvor",
    (14, 22): "Orc Liquor",
    (14, 23): "Esgalduin",
    (14, 24): "Clarity",
    (14, 25): "Cordial",
    (14, 26): "Voice",
    (14, 27): "True Sight",
    (14, 28): "Antidote",
    (14, 29): "Quickness",
    (14, 30): "Elem Resist",
    (14, 31): "Shadows Pot",
    (15, 0): "Might Draft",
    (15, 1): "Nimble Wine",
    (15, 2): "Hardy Brew",
    (15, 3): "Star Elixir",
    (15, 4): "Slowness",
    (15, 5): "Poison",
    (15, 6): "Blindness",
    (15, 7): "Confusion",
    (15, 8): "Awkwardness",
    (15, 9): "Disconnect",
    (15, 10): "Wood Chest",
    (15, 11): "Steel Chest",
    (15, 12): "Jewel Chest",
    (15, 13): "Lg Wood Chest",
    (15, 14): "Lg Steel Chest",
    (15, 15): "Lg Jewel Chest",
    (15, 16): "Gift Box",
    (15, 17): "Orc Mushroom",
    (15, 18): "Waymeal",
    (15, 19): "Terror Herb",
    (15, 20): "Healer Herb",
    (15, 21): "Restoration",
    (15, 22): "Emptiness",
    (15, 23): "Visions",
    (15, 24): "Entrancement",
    (15, 25): "Weakness",
    (15, 26): "Sickness",
    (15, 27): "Athelas",
    (15, 28): "Travel Bread",
    (15, 29): "Dried Meat",
    (15, 30): "Lembas",
    (15, 31): "Flask Oil",
    (16, 0): "Cram Cake",
    (16, 1): "Pipe Weed",
    (16, 2): "Mithril Piece",
    (16, 3): "Mallorn Torch",
    (16, 4): "Conc Healer",
    (16, 5): "Potent Athelas",
    (16, 6): "Conc Waymeal",
    (16, 7): "Potent Orc-Rg",
    (16, 8): "Phos Moss",
    (16, 9): "Torch Oil",
    (16, 10): "Night Cloak",
    (16, 11): "Rusted Helm",
    (16, 12): "Worn Boots",
    (16, 13): "Broken Shield",
    (16, 14): "Note",
    (16, 15): "Glow Weapon",
    (16, 16): "Broken Mail",
    (16, 17): "Strange Wpn",
    (16, 18): "Shadow Plate",
    (16, 19): "Strange Jewel",
    (16, 20): "Thrain Memory",
    (16, 21): "Shadow Frag",
    (16, 22): "Ancient Glyph",
    (16, 23): "Palantir Shard",
    (16, 24): "Mithril Brooch",
    (16, 25): "Thror Coin",
    (16, 26): "Dragon Gem",
    (16, 27): "Dwarf Page",
    (16, 28): "Durin Fragment",
    (16, 29): "Prisoner Acct",
    (16, 30): "Orc Report",
    (16, 31): "History Frag",
    (17, 0): "Necro Sighting",
    (17, 1): "Curved Sword",
    (17, 2): "Sylvan Blade",
}

for (r, c), name in item_positions.items():
    add(r, c, name)

# =============================================================================
# ARTEFACT CATEGORIES (Row 19, cols 0-18)
# =============================================================================
artefact_categories = {
    (19, 0): "Art Sword",
    (19, 1): "Art Axe",
    (19, 2): "Art Spear",
    (19, 3): "Art Staff",
    (19, 4): "Art Hammer",
    (19, 5): "Art Pickaxe",
    (19, 6): "Art Bow",
    (19, 7): "Art Arrow",
    (19, 8): "Art Ring",
    (19, 9): "Art Amulet",
    (19, 10): "Art Robe",
    (19, 11): "Art Mail",
    (19, 12): "Art Shield",
    (19, 13): "Art Helm",
    (19, 14): "Art Crown",
    (19, 15): "Art Cloak",
    (19, 16): "Art Boots",
    (19, 17): "Art Gloves",
    (19, 18): "Art Light",
}

for (r, c), name in artefact_categories.items():
    add(r, c, name)

# =============================================================================
# MONSTERS (Rows 24-26)
# =============================================================================
monster_positions = {
    (24, 0): "Mirk Spider",
    (24, 1): "Giant Rat",
    (24, 2): "Blk Squirrel",
    (24, 3): "Crebain",
    (24, 4): "Tanglethorn",
    (24, 5): "Giant Bat",
    (24, 6): "Web Spinner",
    (24, 7): "Orc Scout",
    (24, 8): "Swamp Adder",
    (24, 9): "Great Spider",
    (24, 10): "Warg Pup",
    (24, 11): "Broodmother",
    (24, 12): "Orc Slave",
    (24, 13): "Orc Soldier",
    (24, 14): "Orc Crossbow",
    (24, 15): "Warg",
    (24, 16): "Thrallmaster",
    (24, 17): "Orc Captain",
    (24, 18): "Warg Rider",
    (24, 19): "Hill Troll",
    (24, 20): "Gashnak",
    (24, 21): "Orc Warchief",
    (24, 22): "Dark Acolyte",
    (24, 23): "Ghoul",
    (24, 24): "Mirk Troll",
    (24, 25): "East Warrior",
    (24, 26): "Dark Sorcerer",
    (24, 27): "Tortured One",
    (24, 28): "East Champion",
    (24, 29): "Ghast",
    (24, 30): "Karvag",
    (24, 31): "Master Sorc",
    (25, 0): "Skeleton",
    (25, 1): "Skel Warrior",
    (25, 2): "Zombie",
    (25, 3): "Wight",
    (25, 4): "Corpse Candle",
    (25, 5): "Necro Adept",
    (25, 6): "Barrow Wight",
    (25, 7): "Bone Golem",
    (25, 8): "Grishnakh",
    (25, 9): "East Infiltr",
    (25, 10): "Cave Troll",
    (25, 11): "Dark Ritual",
    (25, 12): "Corsair",
    (25, 13): "Dunlending",
    (25, 14): "Tunnel Crawl",
    (25, 15): "Pale Crawler",
    (25, 16): "Phantom",
    (25, 17): "Shadow",
    (25, 18): "Whisper Shade",
    (25, 19): "Wraith",
    (25, 20): "Fell Spirit",
    (25, 21): "Spectre",
    (25, 22): "Vamp Thrall",
    (25, 23): "Wail Horror",
    (25, 24): "Uvatha",
    (25, 25): "BN Acolyte",
    (25, 26): "Haradrim",
    (25, 27): "Cave Worm",
    (25, 28): "Oathbreaker",
    (25, 29): "Morgul Sorc",
    (25, 30): "Blk Numenor",
    (25, 31): "Olog-hai",
    (26, 0): "Vampire",
    (26, 1): "Greater Wraith",
    (26, 2): "Vampire Lord",
    (26, 3): "Shadow Lord",
    (26, 4): "Maia Thrall",
    (26, 5): "Khamul",
    (26, 6): "Elite Olog",
    (26, 7): "Greater Shadow",
    (26, 8): "Void Wraith",
    (26, 9): "Thrain Shade",
    (26, 10): "Sauron",
    (26, 11): "BN Lord",
    (26, 12): "Mouth Sauron",
    (26, 13): "Gandalf",
    (26, 14): "Thranduil",
    (26, 15): "Galadriel",
    (26, 16): "Elrond",
    (26, 17): "Thorin",
    (26, 18): "Beorn",
    (26, 19): "Radagast",
    (26, 20): "Eagle",
    (26, 21): "Great Elk",
    (26, 22): "Ent",
}

for (r, c), name in monster_positions.items():
    add(r, c, name)

# =============================================================================
# Now shorten terrain names to fit 1-2 word limit better
# =============================================================================
# Many terrain names already have " Lit" / " Dark" suffix.
# Let's clean up: remove " Lit" and " Dark" suffixes since they take space,
# and instead use "L" and "D" suffixes.

final_map = {}
for key, name in sorted(tileset_map.items(), key=lambda x: (int(x[0].split('_')[0]), int(x[0].split('_')[1]))):
    # Shorten Lit/Dark suffixes for terrain
    name = name.replace(" Lit", " L").replace(" Dark", " D")
    # Truncate to keep reasonable length
    if len(name) > 16:
        name = name[:15]
    final_map[key] = name

# Print as valid Python dict literal
print("TILESET_NAMES = {")
for key in sorted(final_map.keys(), key=lambda x: (int(x.split('_')[0]), int(x.split('_')[1]))):
    print(f'    "{key}": "{final_map[key]}",')
print("}")
