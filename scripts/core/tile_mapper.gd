extends Node
## Provides atlas coordinate lookups for the 64x64 Necromancer tileset.
## The tileset is 1024x1024 pixels = 16x16 grid of 64x64 tiles.
## Valid coordinates: (0-15, 0-15)

# Lookup tables
var terrain_tiles: Dictionary = {}
var monster_tiles: Dictionary = {}
var object_tiles: Dictionary = {}

# Tileset layout reference (from visual inspection):
# Rows 0-5:  Items (weapons, armor, potions, artifacts)
# Rows 6-9:  Character sprites (player portraits in circular frames)
# Rows 10-15: Terrain (walls, floors, doors, stairs)

func _ready() -> void:
	_load_terrain_mappings()
	_load_character_mappings()
	_load_item_mappings()
	print("=== TileMapper Initialized ===")
	print("Tileset: 16x16 grid (coords 0-15)")
	print("Terrain tiles: ", terrain_tiles.size())
	print("Character tiles: ", monster_tiles.size())
	print("FLOOR coords: ", terrain_tiles.get(1, Vector2i(-1,-1)))
	print("WALL coords: ", terrain_tiles.get(2, Vector2i(-1,-1)))
	print("==============================")

func _load_terrain_mappings() -> void:
	# Terrain tiles - user-verified coordinates
	# Format: Vector2i(column, row) where row 0 is top
	# Tile enum: VOID=0, FLOOR=1, WALL=2, DOOR_CLOSED=3, DOOR_OPEN=4,
	#            STAIRS_DOWN=5, STAIRS_UP=6, CHASM=7, RUBBLE=8, FORGE=9

	terrain_tiles[0] = Vector2i(0, 15)   # VOID - dark void
	terrain_tiles[1] = Vector2i(2, 15)   # FLOOR - stone dungeon floor
	terrain_tiles[2] = Vector2i(0, 14)   # WALL - stone wall
	terrain_tiles[3] = Vector2i(0, 13)   # DOOR_CLOSED - wooden door
	terrain_tiles[4] = Vector2i(1, 13)   # DOOR_OPEN - dark version of door (one right of closed)
	terrain_tiles[5] = Vector2i(4, 13)   # STAIRS_DOWN
	terrain_tiles[6] = Vector2i(6, 13)   # STAIRS_UP
	terrain_tiles[7] = Vector2i(0, 15)   # CHASM - same as void
	terrain_tiles[8] = Vector2i(2, 15)   # RUBBLE - use floor for now
	terrain_tiles[9] = Vector2i(2, 15)   # FORGE - use floor for now

func _load_character_mappings() -> void:
	# Player race variants - Row 9 has elf/player characters
	# Format: Vector2i(column, row)
	monster_tiles[0] = Vector2i(0, 9)    # Noldor - elf
	monster_tiles[1] = Vector2i(1, 9)    # Sindar - elf variant
	monster_tiles[2] = Vector2i(2, 9)    # Man - human variant
	monster_tiles[3] = Vector2i(3, 9)    # Dwarf - dwarf variant

	# Monster sprites are mapped by display character via get_monster_coords_for_char()
	# rather than numeric index

func _load_item_mappings() -> void:
	# Items are in rows 0-5
	var item_idx := 0
	for row in range(6):
		for col in range(16):
			object_tiles[item_idx] = Vector2i(col, row)
			item_idx += 1

# ============================================================================
# PUBLIC API
# ============================================================================

func get_terrain_coords(tile_enum: int) -> Vector2i:
	if terrain_tiles.has(tile_enum):
		return terrain_tiles[tile_enum]
	# Default to floor
	return terrain_tiles.get(1, Vector2i(2, 14))

func get_monster_coords(monster_id: int) -> Vector2i:
	if monster_tiles.has(monster_id):
		var coords: Vector2i = monster_tiles[monster_id]
		print("TileMapper: monster_id=%d -> coords=%s" % [monster_id, coords])
		return coords
	# Default to first monster in row 3
	print("TileMapper: monster_id=%d NOT FOUND, using default (0,3)" % monster_id)
	return Vector2i(0, 3)

func get_object_coords(object_id: int) -> Vector2i:
	if object_tiles.has(object_id):
		return object_tiles[object_id]
	# Default to first item
	return Vector2i(0, 0)

func get_player_coords(race_id: int = 0) -> Vector2i:
	# Player sprites - row 10 Elf/Ranger
	return Vector2i(race_id % 16, 10)

func get_monster_coords_for_char(display_char: String) -> Vector2i:
	# Map Sil display characters to actual monster sprites in tileset
	# Corrected from reference (was 1-based, now 0-based: subtract 1 from both x and y)
	# Row 1: Demons & Major Undead (was row 2)
	# Row 2: Undead & Spirits (was row 3)
	# Row 3: Ghosts & Apparitions (was row 4)
	# Row 4: Boss Monsters (was row 5)

	var char_to_coords: Dictionary = {
		# Major demons (Row 1, was row 2)
		"U": Vector2i(0, 1),  # Unique demon -> red hulking demon
		"B": Vector2i(0, 1),  # Balrog -> red hulking demon
		"V": Vector2i(3, 1),  # Vampire -> necromancer
		"W": Vector2i(0, 1),  # Wraith -> dark wraith
		"Q": Vector2i(4, 1),  # Quylthulg -> tentacled horror

		# Undead (Row 2, was row 3)
		"G": Vector2i(0, 2),  # Ghost
		"g": Vector2i(0, 2),  # Lesser ghost
		"s": Vector2i(1, 4),  # Skeleton -> skeletal warrior
		"S": Vector2i(0, 2),  # Shadow -> dark armored undead
		"w": Vector2i(7, 2),  # Wight -> shadow wraith
		"Z": Vector2i(1, 4),  # Zombie -> skeleton
		"z": Vector2i(1, 4),  # Lesser zombie -> skeleton
		"L": Vector2i(5, 2),  # Lich -> reaper figure
		"N": Vector2i(3, 1),  # Nazgul -> necromancer

		# Spirits and ghosts (Row 3, was row 4)
		"p": Vector2i(0, 3),  # Phantom -> ghost face
		"P": Vector2i(4, 3),  # Poltergeist -> skull wraith
		"E": Vector2i(2, 3),  # Elemental -> ghostly robed
		"e": Vector2i(1, 3),  # Lesser elemental -> cloaked wanderer

		# Beasts - use various monster sprites
		"r": Vector2i(2, 4),  # Rodent (squirrel, rat)
		"R": Vector2i(2, 4),  # Giant rodent
		"b": Vector2i(4, 4),  # Bird (Crebain)
		"f": Vector2i(2, 1),  # Feline -> winged creature
		"F": Vector2i(2, 1),  # Large feline -> winged creature
		"h": Vector2i(6, 2),  # Hound -> haunted portrait
		"C": Vector2i(3, 2),  # Canine -> cthulhu-like
		"c": Vector2i(4, 2),  # Centipede -> spider
		"I": Vector2i(4, 2),  # Insect -> spider
		"i": Vector2i(4, 2),  # Lesser insect -> spider
		"a": Vector2i(4, 2),  # Ant -> spider (small creature)
		"A": Vector2i(4, 2),  # Giant ant -> spider
		"K": Vector2i(4, 2),  # Killer beetle -> spider
		"J": Vector2i(4, 2),  # Jelly -> spider
		"j": Vector2i(6, 3),  # Lesser jelly -> void mass

		# Dragons
		"d": Vector2i(0, 1),  # Dragon -> red demon (large)
		"D": Vector2i(4, 4),  # Ancient dragon -> demon king

		# Humanoids - use warrior/mage sprites (Row 4, was row 5)
		"o": Vector2i(0, 4),  # Orc -> warrior
		"O": Vector2i(0, 4),  # Orc captain -> warrior
		"T": Vector2i(0, 1),  # Troll -> hulking demon
		"t": Vector2i(1, 1),  # Lesser troll -> pale demon
		"k": Vector2i(1, 2),  # Kobold -> masked figure
		"H": Vector2i(0, 4),  # Human -> warrior
		"M": Vector2i(3, 2),  # Mirkwood Spider
		"m": Vector2i(0, 4),  # Lesser mage -> purple mage

		# Special/unique
		"@": Vector2i(0, 9),  # Player -> elf ranger (was 0,10)
		"&": Vector2i(7, 3),  # Tanglethorn / plant creature
	}

	if char_to_coords.has(display_char):
		var coords: Vector2i = char_to_coords[display_char]
		print("TileMapper: char '%s' -> coords %s" % [display_char, coords])
		return coords

	# Default: pick a semi-random sprite from row 2 based on character code
	var hash_val: int = display_char.unicode_at(0) % 8  # Only 0-7 are valid in row 2
	var default_coords := Vector2i(hash_val, 2)
	print("TileMapper: char '%s' NOT FOUND, using default %s" % [display_char, default_coords])
	return default_coords

# Direct tile enum to coords - used by level.gd
# This bypasses the feature_id indirection since we're mapping directly
func tile_enum_to_feature_id(tile_enum: int) -> int:
	# Return the tile_enum as-is since we now map directly
	return tile_enum
