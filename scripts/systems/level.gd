extends Node2D
class_name Level
## Manages a dungeon level - terrain, entities, items, FOV.

signal generation_complete(width: int, height: int)

# Level dimensions
@export var width: int = 80
@export var height: int = 40
@export var depth: int = 1
var layer_name: String = ""  # Current dungeon layer (e.g. "outer_pits", "dark_halls")
var is_ascent: bool = false  # True when player is ascending with quest items (escalated spawning)

# Tile data
var terrain: Array[int] = []  # Flat array, index = y * width + x
var explored: Array[bool] = []
var tile_visibility: Array[bool] = []
var room_lit: Array[bool] = []       # True if tile is in a lit room (CAVE_GLOW equivalent)
var room_id: Array[int] = []         # Which room each tile belongs to (-1 = none/corridor)
var rooms: Array[Rect2i] = []        # Room rectangles from generation
var vault_room_ids: Dictionary = {}  # room_id -> true for vault rooms
var vault_rects: Array[Rect2i] = []  # Rects for all carved vaults (including non-room vaults)
var tile_in_fov: Array[bool] = []    # Geometric line of sight (FOV only, before lighting)
var tile_lit: Array[bool] = []       # Has light (player torch + room glow)
var _newly_explored_count: int = 0   # Tiles explored this FOV update (for stealth XP)

# Isolated RNG for floor-finding (immune to external seed() calls)
var _floor_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Entities
var entities: Array[Entity] = []
var items: Array = []  # Item nodes on the ground

# Tile types
enum Tile {
	VOID = 0,
	FLOOR = 1,
	WALL = 2,
	DOOR_CLOSED = 3,
	DOOR_OPEN = 4,
	STAIRS_DOWN = 5,
	STAIRS_UP = 6,
	CHASM = 7,
	RUBBLE = 8,
	FORGE = 9,
	TRAP = 10,           # Generic trap - deals damage when stepped on
	TRAP_TRIGGERED = 11,  # Trap that has already been triggered
	DOOR_LOCKED = 12,    # Locked door - requires key or lockpicking
	DOOR_JAMMED = 13,    # Jammed/stuck door - requires STR check to bash
	DOOR_SECRET = 14,    # Secret door - looks like wall until discovered
	WATER = 15,          # Shallow water - passable, slows movement
	LAVA = 16,           # Lava - passable but deals fire damage on step
	VINE_FLOOR = 17,     # Thick vines (depths 1-3) - passable, slows movement
	POISON_STREAM = 18,  # Poison stream (depths 1-3) - passable, 1d4 damage + 3-turn poison
	# New terrain types for layer decoration (Stream D)
	WEB = 19,            # Spider webs - 1.5x movement, slow 3 turns (spiders immune)
	DARK_POOL = 20,      # Dark water pools - 2x movement, 1d6 cold damage, 20% blind 2 turns
	MORGUL_RUNE = 21,    # Morgul runes - 1x movement, 1d4 dark damage to non-undead
	SHADOW_BRAZIER = 22, # Shadow brazier - blocks movement, emits anti-light radius 2
	GLYPH_OF_WARDING = 23, # Warding glyph - 1x movement, 2d6 damage to undead monsters
	BONE_PILE = 24,      # Bone piles - 1x movement, flavor text only
	SHADOW_FLOOR = 25,   # Shadow floor - 1x movement, 1d4 damage if tile is lit
	THRONE_DAIS = 26,    # Throne dais - 1x movement, flavor text only
	INSCRIPTION = 27,    # Inscribed floor - 1x movement, readable lore marker (no combat effect)
	FORGE_ENCHANTED = 28, # Enchanted forge - +3 smithing bonus, 3-4 uses
	FORGE_UNIQUE = 29,    # Unique forge - +7 smithing bonus, 3 uses (max 1 per game)
}

# Track which traps have been triggered (to avoid re-triggering)
var triggered_traps: Dictionary = {}  # Vector2i -> bool
var revealed_traps: Dictionary = {}  # Vector2i -> bool (detected but not yet triggered/disarmed)

# Forge use tracking — each forge has limited uses
var forge_uses: Dictionary = {}  # Vector2i -> int

# Trap types stored per position
enum TrapType {
	BASIC = 0,      # 1d4+depth/3 damage
	PIT = 1,        # 2d4 damage, stuck 1 turn
	DART = 2,       # 1d6 + poison
	GAS = 3,        # Confusion 3-5 turns
	ALARM = 4,      # Raises floor alertness +15
	TELEPORT = 5,   # Random teleport
	FLASH = 6,      # Blind 3-5 turns
	CALTROPS = 7,   # 1d4 + slow 3 turns
	WEB = 8,        # Slow 5 turns
}
var trap_types: Dictionary = {}  # Vector2i -> TrapType

# Secret door tracking
var secret_doors: Dictionary = {}  # Vector2i -> bool (true if still hidden)

# Dark zones: rooms with no ambient light (depth 10+)
var dark_zone_rooms: Dictionary = {}  # room_id -> true for rooms that are dark zones
var room_tags: Dictionary = {}  # room_id -> Array[String]
var room_event_seeds: Dictionary = {}  # room_id -> int

# Glowing items on the ground: positions of items that emit light
var glowing_items: Array[Vector2i] = []

# Floor-wide alertness (Phase B: Stealth)
var floor_alertness: int = 0  # 0-50+, rises with noise, decays over time

# Environmental storytelling: position -> flavor message (displayed once when player steps on tile)
var flavor_messages: Dictionary = {}  # Vector2i -> String
var _seen_flavor_positions: Dictionary = {}  # Vector2i -> bool (already displayed)
var _seen_inscription_rewards: Dictionary = {}  # Vector2i -> bool (XP already granted)
var _seen_room_events: Dictionary = {}  # room_id -> true (drama event triggered)

# Child nodes
@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var entity_container: Node2D = $Entities
@onready var item_container: Node2D = $Items
@onready var effect_container: Node2D = $Effects

func _ready() -> void:
	_initialize_arrays()
	_apply_layer_tint_shader()

func _initialize_arrays() -> void:
	# Reseed the isolated floor RNG from OS time (immune to external seed() calls)
	_floor_rng.seed = Time.get_ticks_usec()
	var size := width * height
	terrain.resize(size)
	terrain.fill(Tile.VOID)
	explored.resize(size)
	explored.fill(false)
	tile_visibility.resize(size)
	tile_visibility.fill(false)
	room_lit.resize(size)
	room_lit.fill(false)
	room_id.resize(size)
	room_id.fill(-1)
	tile_in_fov.resize(size)
	tile_in_fov.fill(false)
	tile_lit.resize(size)
	tile_lit.fill(false)

func _apply_layer_tint_shader() -> void:
	if terrain_layer:
		# Use layer tint shader which includes magenta transparency
		var shader_material: ShaderMaterial = load("res://assets/shaders/layer_tint.tres")
		# Clone the material so each level can have its own tint settings
		shader_material = shader_material.duplicate()
		terrain_layer.material = shader_material
		# Apply initial tint based on depth
		update_layer_tint()

## Update the layer tint based on current depth
func update_layer_tint() -> void:
	if not terrain_layer or not terrain_layer.material:
		return

	var shader_mat := terrain_layer.material as ShaderMaterial
	if shader_mat:
		var tint_color := LayerConfig.get_tint_color(depth)
		var tint_strength := LayerConfig.get_tint_strength(depth)
		shader_mat.set_shader_parameter("tint_color", tint_color)
		shader_mat.set_shader_parameter("tint_strength", tint_strength)

## Get the max FOV radius for this level's depth (layer-based cap)
func get_fov_radius() -> int:
	return LayerConfig.get_fov_radius(depth)

## Get effective FOV radius - always returns geometric max; lighting handled separately
func get_effective_fov_radius(_player_light: int) -> int:
	return get_fov_radius()

# ============================================================================
# TERRAIN ACCESS
# ============================================================================

func get_tile(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return Tile.VOID
	return terrain[pos.y * width + pos.x]

var _set_tile_debug_count := 0

func set_tile(pos: Vector2i, tile: int) -> void:
	if is_in_bounds(pos):
		terrain[pos.y * width + pos.x] = tile
		if _set_tile_debug_count < 10:
			var atlas_coords := TileMapper.get_terrain_coords(tile)
			print("set_tile: pos=", pos, " tile=", Tile.keys()[tile], " atlas=", atlas_coords)
			_set_tile_debug_count += 1
		_update_tilemap_cell(pos, tile)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func is_passable(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	match tile:
		Tile.FLOOR, Tile.DOOR_OPEN, Tile.STAIRS_DOWN, Tile.STAIRS_UP, Tile.TRAP, Tile.TRAP_TRIGGERED, Tile.WATER, Tile.LAVA, Tile.FORGE, Tile.FORGE_ENCHANTED, Tile.FORGE_UNIQUE, Tile.VINE_FLOOR, Tile.POISON_STREAM, Tile.WEB, Tile.DARK_POOL, Tile.MORGUL_RUNE, Tile.GLYPH_OF_WARDING, Tile.BONE_PILE, Tile.SHADOW_FLOOR, Tile.THRONE_DAIS, Tile.INSCRIPTION:
			return true
		_:
			return false

## Get movement energy cost for a tile (water costs double, vines cost 1.5x, poison stream 2x)
func get_movement_cost(pos: Vector2i) -> int:
	var tile := get_tile(pos)
	if tile == Tile.WATER:
		return Constants.ACTION_COST * 2  # Double energy cost to wade
	if tile == Tile.VINE_FLOOR:
		return int(Constants.ACTION_COST * 1.5)  # 150 energy instead of 100
	if tile == Tile.POISON_STREAM:
		return Constants.ACTION_COST * 2  # 200 energy to wade through poison
	if tile == Tile.WEB:
		return int(Constants.ACTION_COST * 1.5)  # 1.5x for webs
	if tile == Tile.DARK_POOL:
		return Constants.ACTION_COST * 2  # 2x for dark pools
	return Constants.ACTION_COST

## Attempt to disarm a trap at the given position.
## Returns {"success": bool, "message": String}
func disarm_trap(pos: Vector2i, hunting_skill: int) -> Dictionary:
	var tile: int = get_tile(pos)
	if tile != Tile.TRAP and tile != Tile.TRAP_TRIGGERED:
		return {"success": false, "message": "There is no visible trap here."}
	if tile == Tile.TRAP and not revealed_traps.has(pos):
		return {"success": false, "message": "There is no visible trap here."}

	var chance: float = 0.40 + 0.05 * hunting_skill
	if randf() < chance:
		set_tile(pos, Tile.FLOOR)
		# Clear trap data for this position
		if trap_types.has(pos):
			trap_types.erase(pos)
		if triggered_traps.has(pos):
			triggered_traps.erase(pos)
		if revealed_traps.has(pos):
			revealed_traps.erase(pos)
		return {"success": true, "message": "You carefully disarm the trap."}
	else:
		return {"success": false, "message": "You fumble the disarm attempt!"}

## Called when an entity steps on a tile. Returns true if something happened.
func on_entity_step(entity: Entity, pos: Vector2i) -> bool:
	var tile := get_tile(pos)

	if entity is Player:
		var perception: int = entity.get_effective_perception() if entity.has_method("get_effective_perception") else 0
		_try_reveal_nearby_traps(pos, perception)
		var rid: int = get_room_id(pos)
		if rid >= 0 and not _seen_room_events.has(rid):
			_seen_room_events[rid] = true
			_trigger_room_drama_event(rid, entity as Player)

	if tile == Tile.TRAP and not triggered_traps.has(pos):
		return _trigger_trap(entity, pos)

	if tile == Tile.LAVA:
		return _lava_damage(entity, pos)

	if tile == Tile.WATER and entity is Player:
		GameManager.log_message("You wade through shallow water.", ThemeColors.SECONDARY)
		if AudioManager and AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("terrain_water_step")

	if tile == Tile.VINE_FLOOR and entity is Player:
		EventBus.message_logged.emit("You push through tangled vines.", ThemeColors.TEXT_MUTED)
		if AudioManager and AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("terrain_vine_step")

	if tile == Tile.POISON_STREAM:
		return _poison_stream_damage(entity, pos)

	if tile == Tile.WEB:
		return _web_effect(entity, pos)

	if tile == Tile.DARK_POOL:
		return _dark_pool_effect(entity, pos)

	if tile == Tile.MORGUL_RUNE:
		return _morgul_rune_effect(entity, pos)

	if tile == Tile.GLYPH_OF_WARDING:
		return _glyph_of_warding_effect(entity, pos)

	if tile == Tile.BONE_PILE and entity is Player:
		EventBus.message_logged.emit("You crunch through a pile of old bones.", ThemeColors.TEXT_MUTED)

	if tile == Tile.SHADOW_FLOOR:
		return _shadow_floor_effect(entity, pos)

	if tile == Tile.THRONE_DAIS and entity is Player:
		EventBus.message_logged.emit("You stand upon the dais. Dark power radiates from the stone.", ThemeColors.MSG_WARNING)

	# Environmental storytelling — inscription tiles with one-time flavor messages
	if tile == Tile.INSCRIPTION and entity is Player:
		if pos in flavor_messages and pos not in _seen_flavor_positions:
			_seen_flavor_positions[pos] = true
			EventBus.message_logged.emit(flavor_messages[pos], ThemeColors.MSG_INFO)
		if pos not in _seen_inscription_rewards:
			_seen_inscription_rewards[pos] = true
			var xp_reward: int = 500
			entity.gain_experience(xp_reward, "encounter")
			EventBus.message_logged.emit("The inscription steels your resolve. (+%d XP)" % xp_reward, ThemeColors.MSG_XP)

	return false

## Get a display name for the terrain at a position (for HUD / look mode)
# ============================================================================
# FORGE HELPERS
# ============================================================================

func is_forge_tile(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	return tile == Tile.FORGE or tile == Tile.FORGE_ENCHANTED or tile == Tile.FORGE_UNIQUE

func get_forge_type(pos: Vector2i) -> Tile:
	return get_tile(pos)

func get_forge_bonus(pos: Vector2i) -> int:
	match get_tile(pos):
		Tile.FORGE: return 0
		Tile.FORGE_ENCHANTED: return 3
		Tile.FORGE_UNIQUE: return 7
	return 0

func init_forge_uses(pos: Vector2i, uses: int) -> void:
	forge_uses[pos] = uses

func get_forge_uses(pos: Vector2i) -> int:
	return forge_uses.get(pos, 0)

func consume_forge_use(pos: Vector2i) -> int:
	if pos not in forge_uses:
		return 0
	forge_uses[pos] -= 1
	var remaining: int = forge_uses[pos]
	if remaining <= 0:
		forge_uses.erase(pos)
		set_tile(pos, Tile.FLOOR)
	return remaining

func get_terrain_name(pos: Vector2i) -> String:
	match get_tile(pos):
		Tile.RUBBLE: return "Rubble"
		Tile.VINE_FLOOR: return "Vines"
		Tile.WATER: return "Water"
		Tile.LAVA: return "Lava"
		Tile.FORGE: return "Forge"
		Tile.FORGE_ENCHANTED: return "Enchanted Forge"
		Tile.FORGE_UNIQUE: return "Unique Forge"
		Tile.POISON_STREAM: return "Poison Stream"
		Tile.WEB: return "Spider Web"
		Tile.DARK_POOL: return "Dark Pool"
		Tile.MORGUL_RUNE: return "Morgul Rune"
		Tile.SHADOW_BRAZIER: return "Shadow Brazier"
		Tile.GLYPH_OF_WARDING: return "Glyph of Warding"
		Tile.BONE_PILE: return "Bone Pile"
		Tile.SHADOW_FLOOR: return "Shadow Floor"
		Tile.THRONE_DAIS: return "Throne Dais"
		Tile.INSCRIPTION: return "Inscription"
		_: return ""

func _trigger_trap(entity: Entity, pos: Vector2i) -> bool:
	# Check for Hunting skill to potentially spot and avoid (50% + Hunting*5%)
	var avoid_chance: int = 50
	if is_instance_valid(entity) and entity.has_method("get_skill"):
		var hunting: int = entity.get_effective_perception() if entity.has_method("get_effective_perception") else entity.get_effective_skill("hunting")
		avoid_chance += hunting * 5

	# Roll to avoid — trap stays active if avoided
	if randi_range(1, 100) <= avoid_chance:
		revealed_traps[pos] = true
		if entity == GameManager.player:
			GameManager.log_message("You notice a trap and step carefully over it.", ThemeColors.MSG_WARNING)
		return true

	# Mark trap as triggered only after failing to avoid
	revealed_traps[pos] = true
	triggered_traps[pos] = true
	set_tile(pos, Tile.TRAP_TRIGGERED)

	# Get trap type for this position
	var trap_type: int = trap_types.get(pos, TrapType.BASIC)
	_resolve_trap_effect(entity, trap_type, pos)
	return true

func _resolve_trap_effect(entity: Entity, trap_type: int, _pos: Vector2i) -> void:
	if not is_instance_valid(entity):
		return

	# Only show messages if player can see the entity
	var show_msg: bool = (entity == GameManager.player or is_tile_visible(entity.grid_position))
	var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
	var verb: String = "trigger" if entity == GameManager.player else "triggers"

	match trap_type:
		TrapType.BASIC:
			var dmg: int = randi_range(1, 4) + depth / 3
			entity.take_damage(dmg, "physical", null)
			if show_msg:
				GameManager.log_message("%s %s a trap! (%d damage)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_FALL)

		TrapType.PIT:
			var dmg: int = randi_range(2, 8)  # 2d4
			entity.take_damage(dmg, "physical", null)
			entity.apply_status("stunned", 1)
			if show_msg:
				GameManager.log_message("%s %s into a pit! (%d damage)" % [entity_name, "fall" if entity == GameManager.player else "falls", dmg], ThemeColors.MSG_ERROR)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_FALL)

		TrapType.DART:
			var dmg: int = randi_range(1, 6)
			entity.take_damage(dmg, "physical", null)
			entity.apply_status("poisoned", 5 + randi_range(1, 5))
			if show_msg:
				GameManager.log_message("%s %s a dart trap! (%d damage, poisoned)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_FALL)

		TrapType.GAS:
			entity.apply_status("confused", 3 + randi_range(0, 2))
			if show_msg:
				GameManager.log_message("A cloud of gas engulfs %s!" % entity_name.to_lower(), ThemeColors.STATUS_CONFUSED)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_STEP)

		TrapType.ALARM:
			add_floor_noise(15)
			if show_msg:
				GameManager.log_message("An alarm sounds! The dungeon stirs...", ThemeColors.COMBAT_CRIT)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_STEP)

		TrapType.TELEPORT:
			var new_pos: Vector2i = find_random_floor()
			if new_pos != Vector2i(-1, -1) and entity.has_method("teleport_to"):
				entity.teleport_to(new_pos)
				if show_msg:
					GameManager.log_message("%s %s teleported!" % [entity_name, "are" if entity == GameManager.player else "is"], ThemeColors.MSG_INFO)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_STEP)

		TrapType.FLASH:
			entity.apply_status("blind", 2 + randi_range(0, 1))
			if show_msg:
				GameManager.log_message("A blinding flash of light!", ThemeColors.MSG_WARNING)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_STEP)

		TrapType.CALTROPS:
			var dmg: int = randi_range(1, 4)
			entity.take_damage(dmg, "physical", null)
			entity.apply_status("slow", 3)
			if show_msg:
				GameManager.log_message("%s %s caltrops! (%d damage, slowed)" % [entity_name, "step on" if entity == GameManager.player else "steps on", dmg], ThemeColors.MSG_ERROR)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_FALL)

		TrapType.WEB:
			entity.apply_status("slow", 5)
			if show_msg:
				GameManager.log_message("%s %s caught in a web!" % [entity_name, "are" if entity == GameManager.player else "is"], ThemeColors.MSG_WARNING)
			if entity.has_method("add_noise"):
				entity.add_noise(Constants.NOISE_TRAP_STEP)

func _lava_damage(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	var dmg: int = randi_range(2, 8) + depth / 2  # 2d4 + depth/2
	entity.take_damage(dmg, "fire", null)
	if entity == GameManager.player or is_tile_visible(entity.grid_position):
		var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
		var verb: String = "burn" if entity == GameManager.player else "burns"
		GameManager.log_message("%s %s in the lava! (%d fire damage)" % [entity_name, verb, dmg], ThemeColors.COMBAT_CRIT)
	return true

func _poison_stream_damage(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false

	var dmg: int = randi_range(1, 4)  # 1d4 poison damage
	entity.take_damage(dmg, "poison", null)
	var apply_poison: bool = true
	if entity is Player:
		var p: Player = entity as Player
		var con_roll: int = randi_range(1, 20) + p.get_effective_constitution()
		var poison_dc: int = 12 + int(depth / 3)
		apply_poison = con_roll < poison_dc
		if not apply_poison:
			GameManager.log_message("You resist the stream's venom.", ThemeColors.ABILITY_LEARNED)
	if apply_poison:
		entity.apply_status("poisoned", 3)
	if entity == GameManager.player or is_tile_visible(entity.grid_position):
		var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
		var verb: String = "wade" if entity == GameManager.player else "wades"
		if apply_poison:
			GameManager.log_message("%s %s through a poisonous stream! (%d damage)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)
		else:
			GameManager.log_message("%s %s through a poisonous stream! (%d damage, no poison)" % [entity_name, verb, dmg], ThemeColors.MSG_WARNING)
	if entity == GameManager.player and AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("terrain_poison_stream_step")
	return true

func _web_effect(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	# Spiders are immune to web effects
	if entity is Monster:
		var mon: Monster = entity as Monster
		if mon.monster_data and mon.monster_data.has_flag("SPIDER"):
			return false
	entity.apply_status("slow", 3)
	if entity == GameManager.player or is_tile_visible(entity.grid_position):
		var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
		var verb: String = "get" if entity == GameManager.player else "gets"
		GameManager.log_message("%s %s tangled in thick webs!" % [entity_name, verb], ThemeColors.MSG_WARNING)
	if entity == GameManager.player and AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("terrain_web_step")
	return true

func _dark_pool_effect(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	var dmg: int = randi_range(1, 6)  # 1d6 cold damage
	entity.take_damage(dmg, "cold", null)
	# 8% chance of blindness (reduced to curb deep-floor chain-blindness)
	if randf() < 0.08:
		entity.apply_status("blind", 2)
	if entity == GameManager.player or is_tile_visible(entity.grid_position):
		var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
		var verb: String = "wade" if entity == GameManager.player else "wades"
		GameManager.log_message("%s %s through a dark, freezing pool! (%d cold damage)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)
	if entity == GameManager.player and AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("terrain_dark_pool_step")
	return true

func _morgul_rune_effect(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	# Undead are immune
	if entity is Monster and entity.has_method("has_flag") and entity.has_flag("UNDEAD"):
		return false
	var dmg: int = randi_range(1, 4)  # 1d4 dark damage
	entity.take_damage(dmg, "dark", null)
	if entity == GameManager.player or is_tile_visible(entity.grid_position):
		var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
		var verb: String = "step" if entity == GameManager.player else "steps"
		GameManager.log_message("%s %s on a Morgul rune! (%d dark damage)" % [entity_name, verb, dmg], ThemeColors.MSG_ERROR)
	if entity == GameManager.player and AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("terrain_morgul_rune_step")
	return true

func _glyph_of_warding_effect(entity: Entity, _pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	# Only damages undead monsters
	if entity is Monster and entity.has_method("has_flag") and entity.has_flag("UNDEAD"):
		var dmg: int = randi_range(2, 12)  # 2d6 damage to undead
		entity.take_damage(dmg, "holy", null)
		if is_tile_visible(entity.grid_position):
			GameManager.log_message("The glyph of warding flares! (%d holy damage to %s)" % [dmg, entity.entity_name], ThemeColors.ABILITY_LEARNED)
		return true
	if entity is Player:
		EventBus.message_logged.emit("You feel the protective ward beneath your feet.", ThemeColors.ABILITY_LEARNED)
	return false

func _shadow_floor_effect(entity: Entity, pos: Vector2i) -> bool:
	if not is_instance_valid(entity):
		return false
	# Only deals damage if the tile is lit
	if is_tile_lit(pos):
		var dmg: int = randi_range(1, 4)  # 1d4 shadow damage
		entity.take_damage(dmg, "dark", null)
		if entity == GameManager.player or is_tile_visible(entity.grid_position):
			var entity_name: String = "You" if entity == GameManager.player else entity.entity_name
			GameManager.log_message("Light disturbs the shadows, lashing out at %s! (%d damage)" % [entity_name.to_lower(), dmg], ThemeColors.MSG_ERROR)
		if entity == GameManager.player and AudioManager and AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("terrain_shadow_floor_bite")
		return true
	return false

func is_transparent(pos: Vector2i) -> bool:
	var tile := get_tile(pos)
	match tile:
		Tile.WALL, Tile.DOOR_CLOSED, Tile.DOOR_LOCKED, Tile.DOOR_JAMMED, Tile.DOOR_SECRET, Tile.SHADOW_BRAZIER:
			return false
		_:
			return true

func is_explored(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return explored[pos.y * width + pos.x]

func is_tile_visible(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	return tile_visibility[pos.y * width + pos.x]

func set_explored(pos: Vector2i, value: bool = true) -> void:
	if is_in_bounds(pos):
		var idx: int = pos.y * width + pos.x
		if value and not explored[idx]:
			_newly_explored_count += 1
		explored[idx] = value

## Return the number of newly explored tiles since last call and reset counter.
func pop_newly_explored_count() -> int:
	var count: int = _newly_explored_count
	_newly_explored_count = 0
	return count

func set_tile_visible(pos: Vector2i, value: bool) -> void:
	if is_in_bounds(pos):
		tile_visibility[pos.y * width + pos.x] = value
		if value:
			set_explored(pos, true)

func is_tile_lit(pos: Vector2i) -> bool:
	if not is_in_bounds(pos): return false
	return tile_lit[pos.y * width + pos.x]

func is_room_lit(pos: Vector2i) -> bool:
	if not is_in_bounds(pos): return false
	return room_lit[pos.y * width + pos.x]

func get_room_id(pos: Vector2i) -> int:
	if not is_in_bounds(pos): return -1
	return room_id[pos.y * width + pos.x]

func set_room_lit_by_rect(rect: Rect2i, lit: bool) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if is_in_bounds(Vector2i(x, y)):
				room_lit[y * width + x] = lit

func set_room_id_by_rect(rect: Rect2i, id: int) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if is_in_bounds(Vector2i(x, y)):
				room_id[y * width + x] = id

func set_room_metadata(id: int, tags: Array[String], event_seed: int) -> void:
	room_tags[id] = tags.duplicate()
	room_event_seeds[id] = event_seed

func get_room_tags_at(pos: Vector2i) -> Array[String]:
	var rid: int = get_room_id(pos)
	if rid < 0:
		return []
	var tags: Variant = room_tags.get(rid, [])
	return tags.duplicate() if tags is Array else []

func get_room_event_seed_at(pos: Vector2i) -> int:
	var rid: int = get_room_id(pos)
	if rid < 0:
		return 0
	return int(room_event_seeds.get(rid, 0))

func _trigger_room_drama_event(room_idx: int, player_ref: Player) -> void:
	var tags: Array[String] = room_tags.get(room_idx, [])
	var seed: int = int(room_event_seeds.get(room_idx, 0))
	if tags.is_empty() or seed == 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var msg_pool: Array[String] = []
	var noise_boost: int = 0

	if "vault" in tags:
		msg_pool.append("A cold hush settles. This chamber remembers slaughter.")
		msg_pool.append("Broken standards and old blood mark a forgotten last stand.")
		noise_boost += 8
	if "entry" in tags:
		msg_pool.append("The stones behind you feel farther away than they should.")
		noise_boost += 2
	if "exit" in tags:
		msg_pool.append("The air tightens. Something waits between you and the stairs.")
		noise_boost += 4
	if "grand" in tags:
		msg_pool.append("The hall opens like a tomb. Your footsteps sound too loud.")
		noise_boost += 3
	if "deep" in tags:
		msg_pool.append("A watcher stirs in the dark. You feel its attention.")
		noise_boost += 6
	if "terror" in tags:
		msg_pool.append("Every instinct says turn back. Nothing here will be merciful.")
		noise_boost += 10

	if msg_pool.is_empty():
		return

	var chosen: String = msg_pool[rng.randi_range(0, msg_pool.size() - 1)]
	EventBus.message_logged.emit(chosen, ThemeColors.MSG_WARNING)
	if noise_boost > 0:
		add_floor_noise(noise_boost)
		if player_ref and player_ref.run_stats:
			player_ref.run_stats.record_forensic_event(
				GameManager.turn_count,
				"room_event",
				"Room drama triggered: %s (+%d pursuit)" % [chosen, noise_boost],
				"info"
			)

func find_open_door_near(center: Vector2i, radius: int = 8, max_attempts: int = 64) -> Vector2i:
	for _i in range(max_attempts):
		var x: int = _floor_rng.randi_range(maxi(1, center.x - radius), mini(width - 2, center.x + radius))
		var y: int = _floor_rng.randi_range(maxi(1, center.y - radius), mini(height - 2, center.y + radius))
		var pos := Vector2i(x, y)
		if get_tile(pos) == Tile.DOOR_OPEN:
			return pos
	return Vector2i(-1, -1)

# ============================================================================
# ENTITY MANAGEMENT
# ============================================================================

func add_entity(entity: Entity) -> void:
	entities.append(entity)
	entity_container.add_child(entity)
	# Auto-remove from entities array when entity dies
	if not entity.died.is_connected(_on_entity_died):
		entity.died.connect(_on_entity_died.bind(entity))

func remove_entity(entity: Entity) -> void:
	entities.erase(entity)
	if entity.get_parent() == entity_container:
		entity_container.remove_child(entity)

func _on_entity_died(killer: Entity, entity: Entity) -> void:
	# Remove from entities array immediately when entity dies
	# This prevents "freed instance" errors when iterating entities
	if is_instance_valid(entity) and entity in entities:
		entities.erase(entity)

func get_entity_at(pos: Vector2i) -> Entity:
	for entity in entities:
		if is_instance_valid(entity) and entity.grid_position == pos and entity.is_alive:
			return entity
	return null

func get_entities_in_radius(center: Vector2i, radius: int) -> Array[Entity]:
	var result: Array[Entity] = []
	for entity in entities:
		if is_instance_valid(entity) and entity.is_alive:
			var dist: int = max(abs(entity.grid_position.x - center.x),
						   abs(entity.grid_position.y - center.y))
			if dist <= radius:
				result.append(entity)
	return result

func get_monsters() -> Array[Monster]:
	var monsters: Array[Monster] = []
	for entity in entities:
		if is_instance_valid(entity) and entity is Monster and entity.is_alive:
			monsters.append(entity)
	return monsters

# ============================================================================
# ITEM MANAGEMENT
# ============================================================================

func add_item(item: Item) -> void:
	items.append(item)
	item_container.add_child(item)

func remove_item(item: Item) -> void:
	items.erase(item)
	if item.get_parent() == item_container:
		item_container.remove_child(item)

func get_items_at(pos: Vector2i) -> Array[Item]:
	var result: Array[Item] = []
	for item in items:
		if item.grid_position == pos:
			result.append(item)
	return result

func remove_item_at(pos: Vector2i, item: Item) -> bool:
	if item in items and item.grid_position == pos:
		remove_item(item)
		return true
	return false

# ============================================================================
# TILEMAP RENDERING
# ============================================================================

func _update_tilemap_cell(pos: Vector2i, tile: int) -> void:
	if not terrain_layer:
		return

	# Map tile type to atlas coordinates (default to lit for set_tile calls)
	var atlas_coords := _get_atlas_coords_for_tile(tile, true, pos)
	terrain_layer.set_cell(pos, 0, atlas_coords)

func _get_atlas_coords_for_tile(tile: int, lit: bool = true, pos: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	# BONE_PILE uses exact elf/orc skeleton overlays on top of the current layer floor:
	# deterministic 50/50 split by tile position.
	if tile == Tile.BONE_PILE and pos.x >= 0 and pos.y >= 0:
		var h: int = (pos.x * 73856093) ^ (pos.y * 19349663) ^ (depth * 83492791)
		var use_orc: bool = (h & 1) == 0
		if layer_name == "lower_halls":
			if use_orc:
				return Vector2i(28, 20) if lit else Vector2i(29, 20)
			return Vector2i(30, 20) if lit else Vector2i(31, 20)
		if layer_name == "necropolis":
			if use_orc:
				return Vector2i(28, 21) if lit else Vector2i(29, 21)
			return Vector2i(30, 21) if lit else Vector2i(31, 21)

	# Use layer-specific tile kits for base terrain types (wall/floor/door/stairs)
	if not layer_name.is_empty():
		return TileMapper.get_layer_terrain_coords(tile, layer_name, lit)
	return TileMapper.get_terrain_coords(tile, lit)

func rebuild_tilemap() -> void:
	if not terrain_layer:
		return

	terrain_layer.clear()
	var debug_count := 0
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var tile := get_tile(pos)
			if debug_count < 5:
				var atlas_coords := TileMapper.get_terrain_coords(tile)
				print("Tile at ", pos, ": ", Tile.keys()[tile], " atlas=", atlas_coords)
				debug_count += 1
			_update_tilemap_cell(pos, tile)

# ============================================================================
# FOV
# ============================================================================

func update_fov(center: Vector2i, radius: int) -> void:
	# Clear visibility and FOV arrays
	tile_visibility.fill(false)
	tile_in_fov.fill(false)
	tile_lit.fill(false)

	# Geometric raycasting FOV - writes to tile_in_fov only
	for angle in range(360):
		var rad := deg_to_rad(angle)
		var dx := cos(rad)
		var dy := sin(rad)

		var x := float(center.x) + 0.5
		var y := float(center.y) + 0.5

		for _step in range(radius + 1):  # +1: range(8) only reaches 7 tiles
			var check_pos := Vector2i(int(x), int(y))

			if not is_in_bounds(check_pos):
				break

			var idx: int = check_pos.y * width + check_pos.x
			tile_in_fov[idx] = true

			if not is_transparent(check_pos):
				break

			x += dx
			y += dy

## Apply lighting pass: combines player torch radius with room glow + glowing items
func apply_lighting(center: Vector2i, player_light_radius: int) -> void:
	var arr_size: int = width * height

	# Step 1: Find which lit rooms are visible in FOV (skip dark zone rooms)
	var lit_rooms_seen: Dictionary = {}
	for i in range(arr_size):
		if tile_in_fov[i] and room_lit[i]:
			var rid: int = room_id[i]
			if rid >= 0 and not dark_zone_rooms.has(rid):
				lit_rooms_seen[rid] = true

	# Step 2: Single pass - determine lighting and final visibility
	for i in range(arr_size):
		if not tile_in_fov[i]:
			continue

		var tx: int = i % width
		var ty: int = i / width
		var dist: int = maxi(absi(tx - center.x), absi(ty - center.y))

		# Lit by player torch?
		var is_lit: bool = dist <= player_light_radius
		# Lit by room glow? (not in dark zones)
		if not is_lit:
			var rid: int = room_id[i]
			if rid >= 0 and lit_rooms_seen.has(rid):
				is_lit = true

		tile_lit[i] = is_lit
		if is_lit:
			tile_visibility[i] = true
			explored[i] = true

	# Step 3: Glowing items on the ground emit light (radius 2)
	_apply_glowing_item_light()

	# Step 4: Shadow Brazier anti-light — suppresses light within radius 2
	_apply_shadow_brazier_darkness()

## Refresh the glowing_items list from current ground items
func refresh_glowing_items() -> void:
	glowing_items.clear()
	for item in items:
		if not is_instance_valid(item):
			continue
		if _item_has_glow(item):
			glowing_items.append(item.grid_position)

## Check if an item should glow (has LIGHT flag or is an artifact with GLOW)
func _item_has_glow(item: Item) -> bool:
	if not is_instance_valid(item):
		return false
	if item.item_data and "flags" in item.item_data:
		var flags = item.item_data.flags
		if flags is Array:
			return "GLOW" in flags or "LIGHT" in flags
		elif flags is String:
			return "GLOW" in flags or "LIGHT" in flags
	return false

## Apply light from glowing items on the ground
func _apply_glowing_item_light() -> void:
	if glowing_items.is_empty():
		return
	var glow_radius: int = 2
	for glow_pos in glowing_items:
		for dy in range(-glow_radius, glow_radius + 1):
			for dx in range(-glow_radius, glow_radius + 1):
				var pos: Vector2i = glow_pos + Vector2i(dx, dy)
				if not is_in_bounds(pos):
					continue
				var dist: int = maxi(absi(dx), absi(dy))
				if dist > glow_radius:
					continue
				var idx: int = pos.y * width + pos.x
				if tile_in_fov[idx] and not tile_lit[idx]:
					tile_lit[idx] = true
					tile_visibility[idx] = true
					explored[idx] = true

## Shadow braziers suppress light within radius 2
func _apply_shadow_brazier_darkness() -> void:
	for y in range(height):
		for x in range(width):
			if terrain[y * width + x] == Tile.SHADOW_BRAZIER:
				var brazier_pos := Vector2i(x, y)
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var pos: Vector2i = brazier_pos + Vector2i(dx, dy)
						if not is_in_bounds(pos):
							continue
						var dist: int = maxi(absi(dx), absi(dy))
						if dist > 2:
							continue
						var idx: int = pos.y * width + pos.x
						# Don't suppress room glow, only player torch light
						if tile_lit[idx] and not room_lit[idx]:
							tile_lit[idx] = false
							tile_visibility[idx] = false

## Get the darkness modifier for this level's depth
func get_darkness_modifier() -> int:
	return LayerConfig.get_darkness_modifier(depth)

## Mark a room as a dark zone (no ambient room glow)
func set_dark_zone(room_idx: int) -> void:
	dark_zone_rooms[room_idx] = true
	# Also clear room_lit for tiles in that room
	if room_idx < rooms.size():
		set_room_lit_by_rect(rooms[room_idx], false)

func update_entity_visibility() -> void:
	for entity in entities:
		if is_instance_valid(entity) and entity is Monster:
			entity.visible = is_tile_visible(entity.grid_position)
	for item in items:
		if is_instance_valid(item):
			item.visible = is_tile_visible(item.grid_position)

## Refresh tilemap after FOV update: lit tiles use light atlas, explored use dark, unexplored = darkness tile
func apply_fov_to_tilemap() -> void:
	if not terrain_layer:
		return
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var idx: int = y * width + x
			var tile: int = terrain[idx]
			if tile == Tile.VOID:
				terrain_layer.erase_cell(pos)
				continue
			# Traps are invisible until triggered — render as floor
			var render_tile: int = tile
			if tile == Tile.TRAP and not revealed_traps.has(pos):
				render_tile = Tile.FLOOR
			if tile_visibility[idx]:
				# Currently visible — lit variant
				var atlas_coords := _get_atlas_coords_for_tile(render_tile, true, pos)
				terrain_layer.set_cell(pos, 0, atlas_coords)
			elif explored[idx]:
				# Explored but not visible — dark/remembered variant
				var atlas_coords := _get_atlas_coords_for_tile(render_tile, false, pos)
				terrain_layer.set_cell(pos, 0, atlas_coords)
			else:
				# Unexplored: erase cell so black background shows through
				terrain_layer.erase_cell(pos)

func has_los_to(from: Vector2i, to: Vector2i) -> bool:
	# Bresenham line check for transparency
	var x0: int = from.x
	var y0: int = from.y
	var x1: int = to.x
	var y1: int = to.y

	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		if Vector2i(x0, y0) != from:
			if not is_transparent(Vector2i(x0, y0)):
				return false

		if x0 == x1 and y0 == y1:
			break

		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return true

# ============================================================================
# PATHFINDING
# ============================================================================

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	# Simple A* implementation
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}

	while not open_set.is_empty():
		# Find node with lowest f_score
		var current := open_set[0]
		var lowest_f: float = f_score.get(current, INF)
		for node in open_set:
			var f: float = f_score.get(node, INF)
			if f < lowest_f:
				current = node
				lowest_f = f

		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in _get_neighbors(current):
			var tentative_g: float = g_score.get(current, INF) + 1

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []  # No path found

func find_path_through_doors(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	# A* that can path through closed doors (for auto-explore)
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}

	while not open_set.is_empty():
		var current := open_set[0]
		var lowest_f: float = f_score.get(current, INF)
		for node in open_set:
			var f: float = f_score.get(node, INF)
			if f < lowest_f:
				current = node
				lowest_f = f

		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in _get_neighbors(current, true):
			var tentative_g: float = g_score.get(current, INF) + 1

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)

				if neighbor not in open_set:
					open_set.append(neighbor)

	return []

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return float(max(abs(a.x - b.x), abs(a.y - b.y)))

func _get_neighbors(pos: Vector2i, include_doors: bool = false) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions := [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]

	for dir in directions:
		var neighbor: Vector2i = pos + dir
		if is_passable(neighbor):
			neighbors.append(neighbor)
		elif include_doors and get_tile(neighbor) == Tile.DOOR_CLOSED:
			neighbors.append(neighbor)

	return neighbors

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path

# ============================================================================
# FIND SPECIAL POSITIONS
# ============================================================================

func find_stairs_down() -> Vector2i:
	var all: Array[Vector2i] = find_all_stairs_down()
	if all.is_empty():
		return Vector2i(-1, -1)
	return all[0]

func find_all_stairs_down() -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if get_tile(Vector2i(x, y)) == Tile.STAIRS_DOWN:
				results.append(Vector2i(x, y))
	return results

func find_stairs_up() -> Vector2i:
	var all: Array[Vector2i] = find_all_stairs_up()
	if all.is_empty():
		return Vector2i(-1, -1)
	return all[0]

func find_all_stairs_up() -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if get_tile(Vector2i(x, y)) == Tile.STAIRS_UP:
				results.append(Vector2i(x, y))
	return results

func find_random_stairs_down() -> Vector2i:
	var all: Array[Vector2i] = find_all_stairs_down()
	if all.is_empty():
		return Vector2i(-1, -1)
	return all[randi() % all.size()]

func find_random_stairs_up() -> Vector2i:
	var all: Array[Vector2i] = find_all_stairs_up()
	if all.is_empty():
		return Vector2i(-1, -1)
	return all[randi() % all.size()]

func find_random_floor() -> Vector2i:
	# Uses isolated RNG to prevent external seed() calls from poisoning floor selection.
	# The _floor_rng is seeded from system time on creation, not from the global RNG.
	var attempts := 1000
	while attempts > 0:
		var pos := Vector2i(_floor_rng.randi_range(1, width - 2), _floor_rng.randi_range(1, height - 2))
		if get_tile(pos) == Tile.FLOOR and get_entity_at(pos) == null:
			return pos
		attempts -= 1
	return Vector2i(-1, -1)

# ============================================================================
# SPATIAL HELPERS (Spawn System)
# ============================================================================

## Find a random passable floor tile inside a room rectangle (excludes stairs).
func find_random_floor_in_room(room: Rect2i, max_attempts: int = 50) -> Vector2i:
	for _i in range(max_attempts):
		var x: int = _floor_rng.randi_range(room.position.x, room.position.x + room.size.x - 1)
		var y: int = _floor_rng.randi_range(room.position.y, room.position.y + room.size.y - 1)
		var pos := Vector2i(x, y)
		if not is_in_bounds(pos):
			continue
		var tile: int = get_tile(pos)
		if tile == Tile.STAIRS_UP or tile == Tile.STAIRS_DOWN:
			continue
		if is_passable(pos) and get_entity_at(pos) == null:
			return pos
	return Vector2i(-1, -1)

## Count all passable (walkable) tiles on the level.
func count_passable_tiles() -> int:
	var count: int = 0
	for i in range(width * height):
		var tile: int = terrain[i]
		match tile:
			Tile.FLOOR, Tile.DOOR_OPEN, Tile.STAIRS_DOWN, Tile.STAIRS_UP, Tile.TRAP, Tile.TRAP_TRIGGERED, Tile.WATER, Tile.LAVA, Tile.FORGE, Tile.FORGE_ENCHANTED, Tile.FORGE_UNIQUE, Tile.VINE_FLOOR, Tile.POISON_STREAM, Tile.WEB, Tile.DARK_POOL, Tile.MORGUL_RUNE, Tile.GLYPH_OF_WARDING, Tile.BONE_PILE, Tile.SHADOW_FLOOR, Tile.THRONE_DAIS, Tile.INSCRIPTION:
				count += 1
	return count

## Find a random passable floor tile in a corridor (room_id == -1, excludes stairs).
func find_random_corridor_floor(max_attempts: int = 100) -> Vector2i:
	for _i in range(max_attempts):
		var pos := Vector2i(_floor_rng.randi_range(1, width - 2), _floor_rng.randi_range(1, height - 2))
		if not is_in_bounds(pos):
			continue
		var tile: int = get_tile(pos)
		if tile == Tile.STAIRS_UP or tile == Tile.STAIRS_DOWN:
			continue
		if is_passable(pos) and get_entity_at(pos) == null:
			var idx: int = pos.y * width + pos.x
			if idx < room_id.size() and room_id[idx] == -1:
				return pos
	return Vector2i(-1, -1)

# ============================================================================
# FLOOR-WIDE ALERTNESS (Phase B: Stealth)
# ============================================================================

## Add noise to floor alertness (from combat, doors, smithing, etc.)
func add_floor_noise(amount: int) -> void:
	floor_alertness = mini(floor_alertness + amount, 50)

## Decay floor alertness by 1 per round (called from turn system)
func tick_floor_alertness() -> void:
	if floor_alertness > 0:
		floor_alertness -= 1

## Get floor alertness for spawning/door locking decisions
func get_floor_alertness() -> int:
	return floor_alertness

# ============================================================================
# DOOR MECHANICS (Phase F)
# ============================================================================

## Try to close an open door at pos. Returns true if closed.
func close_door(pos: Vector2i) -> bool:
	if get_tile(pos) != Tile.DOOR_OPEN:
		return false
	# Check if an entity is standing in the doorway
	if get_entity_at(pos) != null:
		return false
	# Check if items are blocking the doorway
	if not get_items_at(pos).is_empty():
		return false
	set_tile(pos, Tile.DOOR_CLOSED)
	return true

## Try to bash a jammed/locked door. Returns true if bashed open.
func bash_door(pos: Vector2i, str_bonus: int) -> bool:
	var tile := get_tile(pos)
	if tile != Tile.DOOR_JAMMED and tile != Tile.DOOR_LOCKED:
		return false
	# STR check: 30% base + STR*5%
	var chance: int = 30 + str_bonus * 5
	if randi_range(1, 100) <= chance:
		set_tile(pos, Tile.DOOR_OPEN)
		return true
	return false

## Reveal a secret door at pos
func reveal_secret_door(pos: Vector2i) -> void:
	if get_tile(pos) == Tile.DOOR_SECRET:
		secret_doors.erase(pos)
		set_tile(pos, Tile.DOOR_CLOSED)

## Search adjacent tiles for secret doors (Perception check per tile)
func search_for_secrets(center: Vector2i, perception: int) -> int:
	var found: int = 0
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for dir: Vector2i in directions:
		var check_pos: Vector2i = center + dir
		if get_tile(check_pos) == Tile.DOOR_SECRET:
			# Perception check: 20% + perception*10%
			var chance: int = 20 + perception * 10
			if randi_range(1, 100) <= chance:
				reveal_secret_door(check_pos)
				found += 1
	return found

## Place a trap with a specific type at a position
func place_trap(pos: Vector2i, trap_type: int) -> void:
	set_tile(pos, Tile.TRAP)
	trap_types[pos] = trap_type
	revealed_traps.erase(pos)

func reveal_trap(pos: Vector2i) -> void:
	if not is_in_bounds(pos):
		return
	if get_tile(pos) != Tile.TRAP and get_tile(pos) != Tile.TRAP_TRIGGERED:
		return
	revealed_traps[pos] = true
	set_explored(pos, true)
	set_tile_visible(pos, true)

func is_trap_revealed(pos: Vector2i) -> bool:
	return revealed_traps.has(pos) or get_tile(pos) == Tile.TRAP_TRIGGERED

func _try_reveal_nearby_traps(center: Vector2i, perception: int) -> int:
	var found: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var pos: Vector2i = center + Vector2i(dx, dy)
			if not is_in_bounds(pos):
				continue
			if get_tile(pos) != Tile.TRAP:
				continue
			if revealed_traps.has(pos):
				continue
			var chance: int = clampi(12 + perception * 9, 12, 88)
			if randi_range(1, 100) <= chance:
				reveal_trap(pos)
				found += 1
	if found > 0:
		GameManager.log_message("Your senses pick out %d hidden trap%s nearby." % [found, "s" if found != 1 else ""], ThemeColors.MSG_WARNING)
	return found

## Reveal all traps on the floor (used by Easy difficulty).
func reveal_all_traps() -> void:
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if get_tile(pos) == Tile.TRAP:
				reveal_trap(pos)

# ============================================================================
# WAYFARER'S INSTINCT (Trait: reveal nearby traps, doors, stairs on floor entry)
# ============================================================================

## Reveal traps within trap_radius and doors/stairs within feature_radius of center.
func reveal_for_wayfarer(center: Vector2i, trap_radius: int, feature_radius: int) -> void:
	var max_radius: int = maxi(trap_radius, feature_radius)
	var traps_found: int = 0
	var features_found: int = 0

	for dy in range(-max_radius, max_radius + 1):
		for dx in range(-max_radius, max_radius + 1):
			var pos: Vector2i = center + Vector2i(dx, dy)
			if not is_in_bounds(pos):
				continue

			var dist: int = maxi(absi(dx), absi(dy))  # Chebyshev distance
			var tile: int = get_tile(pos)

			# Reveal traps within trap_radius
			if dist <= trap_radius:
				if tile == Tile.TRAP:
					reveal_trap(pos)
					traps_found += 1

			# Reveal doors and stairs within feature_radius
			if dist <= feature_radius:
				if tile in [Tile.DOOR_CLOSED, Tile.DOOR_OPEN, Tile.DOOR_LOCKED, Tile.DOOR_JAMMED, Tile.DOOR_SECRET, Tile.STAIRS_DOWN, Tile.STAIRS_UP]:
					set_explored(pos, true)
					set_tile_visible(pos, true)
					# Reveal secret doors as closed doors
					if tile == Tile.DOOR_SECRET:
						reveal_secret_door(pos)
					features_found += 1

	if traps_found > 0 or features_found > 0:
		var parts: Array[String] = []
		if traps_found > 0:
			parts.append("%d trap%s" % [traps_found, "s" if traps_found != 1 else ""])
		if features_found > 0:
			parts.append("%d feature%s" % [features_found, "s" if features_found != 1 else ""])
		GameManager.log_message("Your wayfarer's instinct reveals %s nearby." % ", ".join(parts), ThemeColors.ABILITY_LEARNED)
