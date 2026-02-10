extends Node
## Configuration for dungeon layers (tiers) in The Necromancer.
## Each layer has distinct visual theming, difficulty, and atmosphere.
## Autoload singleton - access via LayerConfig.method_name()

# Layer definitions: 7 tiers of Dol Guldur
const LAYERS = {
	"outer_pits": {
		"depths": [1, 2, 3],
		"tint": Color(1.0, 1.0, 1.0, 1.0),  # No tint - base stone dungeon
		"tint_strength": 0.0,
		"fov_radius": 8,
		"darkness_modifier": 0,
		"room_count_min": 6,
		"room_count_max": 12,
		"room_size_min": 4,
		"room_size_max": 10,
		"corridor_width": 1,
		"vault_chance": 0.1,
		"entry_message": "You descend into the Outer Pits of Dol Guldur...",
		"ambient_messages": [
			"The air is cold and damp.",
			"You hear distant dripping water.",
			"Stone dust falls from above."
		],
		"ambient_message_chance": 0.02
	},
	"lower_halls": {
		"depths": [4, 5, 6],
		"tint": Color(0.85, 1.0, 0.85, 1.0),  # Slight green tint
		"tint_strength": 0.15,
		"fov_radius": 8,
		"darkness_modifier": 0,
		"room_count_min": 7,
		"room_count_max": 14,
		"room_size_min": 4,
		"room_size_max": 12,
		"corridor_width": 1,
		"vault_chance": 0.15,
		"entry_message": "You enter the Lower Halls. Moss grows on ancient stones.",
		"ambient_messages": [
			"A damp, mossy smell fills your nostrils.",
			"You feel a chill run down your spine.",
			"Something slithers in the darkness.",
			"Green luminescence glows faintly on the walls."
		],
		"ambient_message_chance": 0.025
	},
	"dark_halls": {
		"depths": [7, 8, 9],
		"tint": Color(0.85, 0.85, 1.0, 1.0),  # Blue tint
		"tint_strength": 0.2,
		"fov_radius": 7,
		"darkness_modifier": -1,
		"room_count_min": 6,
		"room_count_max": 12,
		"room_size_min": 5,
		"room_size_max": 14,
		"corridor_width": 1,
		"vault_chance": 0.2,
		"entry_message": "The Dark Halls stretch before you. Ancient magic permeates the air.",
		"ambient_messages": [
			"You feel a magical presence watching you.",
			"The walls shimmer with faint blue light.",
			"A cold wind whispers of forgotten things.",
			"Arcane symbols glow dimly on the floor."
		],
		"ambient_message_chance": 0.03
	},
	"necropolis": {
		"depths": [10, 11, 12],
		"tint": Color(0.9, 0.75, 1.0, 1.0),  # Purple/Violet tint
		"tint_strength": 0.25,
		"fov_radius": 7,
		"darkness_modifier": -1,
		"room_count_min": 8,
		"room_count_max": 16,
		"room_size_min": 5,
		"room_size_max": 16,
		"corridor_width": 2,
		"vault_chance": 0.25,
		"entry_message": "You enter the Necropolis. The dead do not rest here.",
		"ambient_messages": [
			"You feel a chill of undeath...",
			"Whispers of the dead echo in your mind.",
			"A ghostly wail sounds in the distance.",
			"The air reeks of decay and dark magic.",
			"You sense restless spirits all around."
		],
		"ambient_message_chance": 0.04
	},
	"pits_of_despair": {
		"depths": [13, 14, 15],
		"tint": Color(1.0, 0.8, 0.7, 1.0),  # Red/Orange tint
		"tint_strength": 0.3,
		"fov_radius": 6,
		"darkness_modifier": -2,
		"room_count_min": 5,
		"room_count_max": 10,
		"room_size_min": 6,
		"room_size_max": 18,
		"corridor_width": 2,
		"vault_chance": 0.3,
		"entry_message": "You descend into the Pits of Despair. The heat is oppressive.",
		"ambient_messages": [
			"The heat is oppressive...",
			"Sweat drips down your brow.",
			"You hear the crackling of distant flames.",
			"Screams of the damned echo from below.",
			"The stones radiate an unnatural warmth."
		],
		"ambient_message_chance": 0.05
	},
	"inner_sanctum": {
		"depths": [16, 17, 18],
		"tint": Color(0.7, 0.65, 0.5, 1.0),  # Dark with gold hints
		"tint_strength": 0.35,
		"fov_radius": 6,
		"darkness_modifier": -2,
		"room_count_min": 4,
		"room_count_max": 8,
		"room_size_min": 8,
		"room_size_max": 20,
		"corridor_width": 2,
		"vault_chance": 0.4,
		"entry_message": "You enter the Inner Sanctum. Sauron's presence is strong here.",
		"ambient_messages": [
			"You sense an ancient evil...",
			"Golden light flickers on dark stone.",
			"Power beyond measure emanates from below.",
			"The Eye seems to watch your every move.",
			"Dark whispers promise power... for a price."
		],
		"ambient_message_chance": 0.06
	},
	"throne_room": {
		"depths": [19, 20],
		"tint": Color(0.5, 0.45, 0.3, 1.0),  # Dark + Bright Gold
		"tint_strength": 0.4,
		"fov_radius": 8,
		"darkness_modifier": 0,
		"room_count_min": 2,
		"room_count_max": 5,
		"room_size_min": 10,
		"room_size_max": 25,
		"corridor_width": 3,
		"vault_chance": 0.5,
		"entry_message": "The Throne Room of the Necromancer awaits. Your final confrontation begins.",
		"ambient_messages": [
			"The air crackles with malevolent power.",
			"Ancient evil permeates every stone.",
			"You feel the weight of Sauron's gaze.",
			"Dark fire burns without consuming.",
			"The end is near... one way or another."
		],
		"ambient_message_chance": 0.08
	}
}

# Monster spawn tables per layer - category weights (sum to ~100)
# Categories: spider, orc, troll, undead, shadow, vampire, warg, human_enemy, wight, flier, vermin, elite
const LAYER_MONSTER_TABLES: Dictionary = {
	"outer_pits": {
		"spider": 30, "vermin": 30, "flier": 15, "warg": 15, "orc": 10
	},
	"lower_halls": {
		"orc": 50, "warg": 25, "troll": 10, "spider": 10, "vermin": 5
	},
	"dark_halls": {
		"human_enemy": 40, "undead": 20, "troll": 15, "orc": 15, "shadow": 10
	},
	"necropolis": {
		"undead": 35, "wight": 20, "human_enemy": 20, "shadow": 15, "vampire": 10
	},
	"pits_of_despair": {
		"shadow": 30, "vampire": 15, "human_enemy": 25, "undead": 15, "elite": 15
	},
	"inner_sanctum": {
		"human_enemy": 40, "undead": 25, "elite": 15, "shadow": 10, "vampire": 10
	},
	"throne_room": {
		"elite": 40, "shadow": 25, "human_enemy": 20, "undead": 15
	}
}

# Item type (tval) weights per layer - controls what items drop/spawn
# Common tvals: 80=food/herb, 75=potion, 55=scroll, 23=sword, 31=bow, 36=armor,
# 34=shield, 37=cloak, 33=helm, 30=gloves, 35=boots, 40=light, 45=ring, 46=amulet
const LAYER_ITEM_TVALS: Dictionary = {
	"outer_pits": {
		"80": 35,   # herbs/food heavy
		"75": 20,   # potions
		"23": 15,   # swords
		"31": 10,   # bows
		"55": 10,   # scrolls
		"40": 10    # light sources
	},
	"lower_halls": {
		"23": 25,   # swords
		"36": 20,   # armor
		"75": 15,   # potions
		"34": 10,   # shields
		"80": 10,   # food
		"31": 10,   # bows
		"55": 10    # scrolls
	},
	"dark_halls": {
		"75": 25,   # potions
		"55": 20,   # scrolls
		"36": 15,   # armor
		"23": 15,   # swords
		"40": 15,   # light sources (important in dark)
		"80": 10    # food
	},
	"necropolis": {
		"75": 25,   # potions
		"55": 20,   # scrolls
		"45": 15,   # rings start appearing
		"36": 15,   # armor
		"40": 15,   # light sources
		"23": 10    # swords
	},
	"pits_of_despair": {
		"45": 25,   # rings
		"46": 15,   # amulets
		"75": 20,   # potions
		"55": 15,   # scrolls
		"36": 15,   # armor
		"23": 10    # swords
	},
	"inner_sanctum": {
		"45": 30,   # rings heavy
		"46": 20,   # amulets
		"75": 15,   # potions
		"55": 15,   # scrolls
		"36": 10,   # armor
		"23": 10    # swords
	},
	"throne_room": {
		"45": 30,   # rings
		"46": 25,   # amulets
		"75": 20,   # potions
		"55": 15,   # scrolls
		"36": 10    # armor
	}
}

# Layer decoration parameters - controls themed room and scatter generation
const DECORATION_PARAMS: Dictionary = {
	"outer_pits": {
		"themed_room_chance": 0.60,   # 60% of rooms get decoration
		"scatter_density": 0.05,      # 5% scatter density
		"chasm_count_min": 0,
		"chasm_count_max": 0,
		"web_chance": 0.15,           # 15% web on empty floor
		"decorators": ["forest", "tower", "web_cluster"]
	},
	"lower_halls": {
		"themed_room_chance": 0.50,
		"scatter_density": 0.08,
		"chasm_count_min": 0,
		"chasm_count_max": 0,
		"decorators": ["barracks", "armory", "kennel"]
	},
	"dark_halls": {
		"themed_room_chance": 0.55,
		"scatter_density": 0.10,
		"chasm_count_min": 0,
		"chasm_count_max": 1,
		"decorators": ["ritual_chamber", "torture_room", "rune_corridor"]
	},
	"necropolis": {
		"themed_room_chance": 0.65,
		"scatter_density": 0.12,
		"chasm_count_min": 1,
		"chasm_count_max": 3,
		"decorators": ["crypt", "bone_chamber", "ritual_circle"]
	},
	"pits_of_despair": {
		"themed_room_chance": 0.70,
		"scatter_density": 0.15,
		"chasm_count_min": 3,
		"chasm_count_max": 8,
		"decorators": ["void_chamber", "shadow_gallery", "chasm_bridge"]
	},
	"inner_sanctum": {
		"themed_room_chance": 0.80,
		"scatter_density": 0.12,
		"chasm_count_min": 3,
		"chasm_count_max": 8,
		"decorators": ["grand_hall", "guard_post", "lava_chamber"]
	},
	"throne_room": {
		"themed_room_chance": 1.0,    # All rooms decorated
		"scatter_density": 0.10,
		"chasm_count_min": 5,
		"chasm_count_max": 12,
		"decorators": ["throne_chamber", "antechamber", "lava_moat"]
	}
}

# Cached layer lookup by depth
static var _depth_to_layer_cache: Dictionary = {}

static func _build_cache() -> void:
	if not _depth_to_layer_cache.is_empty():
		return
	for layer_name in LAYERS:
		var layer_data: Dictionary = LAYERS[layer_name]
		for depth in layer_data["depths"]:
			_depth_to_layer_cache[depth] = layer_name

## Get the layer configuration for a specific depth
static func get_layer_for_depth(depth: int) -> Dictionary:
	_build_cache()

	# Handle depths beyond 20 (use throne room settings)
	if depth > 20:
		return LAYERS["throne_room"]

	var layer_name: String = _depth_to_layer_cache.get(depth, "outer_pits")
	return LAYERS[layer_name]

## Get the layer name for a specific depth
static func get_layer_name(depth: int) -> String:
	_build_cache()

	if depth > 20:
		return "throne_room"

	return _depth_to_layer_cache.get(depth, "outer_pits")

## Get the FOV radius for a specific depth
static func get_fov_radius(depth: int) -> int:
	var layer := get_layer_for_depth(depth)
	return layer.get("fov_radius", 8)

## Get the tint color for a specific depth
static func get_tint_color(depth: int) -> Color:
	var layer := get_layer_for_depth(depth)
	return layer.get("tint", Color.WHITE)

## Get the tint strength for a specific depth
static func get_tint_strength(depth: int) -> float:
	var layer := get_layer_for_depth(depth)
	return layer.get("tint_strength", 0.0)

## Check if this depth is a layer boundary (different layer than depth-1).
static func is_layer_boundary(depth: int) -> bool:
	if depth <= 1:
		return false
	return get_layer_name(depth) != get_layer_name(depth - 1)

## Get the entry message for a specific depth (only at layer boundaries)
static func get_entry_message(depth: int, previous_depth: int) -> String:
	var current_layer := get_layer_name(depth)
	var previous_layer := get_layer_name(previous_depth) if previous_depth > 0 else ""

	# Only show message when entering a new layer
	if current_layer != previous_layer:
		var layer := get_layer_for_depth(depth)
		return layer.get("entry_message", "")

	return ""

## Get a random ambient message for the current layer (or empty string)
static func get_ambient_message(depth: int) -> String:
	var layer := get_layer_for_depth(depth)
	var chance: float = layer.get("ambient_message_chance", 0.0)

	if randf() < chance:
		var messages: Array = layer.get("ambient_messages", [])
		if not messages.is_empty():
			return messages[randi() % messages.size()]

	return ""

## Get dungeon generation parameters for a specific depth
static func get_generation_params(depth: int) -> Dictionary:
	var layer := get_layer_for_depth(depth)
	return {
		"room_count_min": layer.get("room_count_min", 6),
		"room_count_max": layer.get("room_count_max", 12),
		"room_size_min": layer.get("room_size_min", 4),
		"room_size_max": layer.get("room_size_max", 10),
		"corridor_width": layer.get("corridor_width", 1),
		"vault_chance": layer.get("vault_chance", 0.1)
	}

## Get the darkness modifier for a specific depth (reduces player light radius)
static func get_darkness_modifier(depth: int) -> int:
	var layer := get_layer_for_depth(depth)
	return layer.get("darkness_modifier", 0)

## Check if this is a boss level (specific depths with guaranteed boss)
static func is_boss_level(depth: int) -> bool:
	# Boss encounters at layer transitions and final level
	return depth in [3, 6, 9, 12, 15, 18, 20]

## Get the boss type for a boss level
static func get_boss_type(depth: int) -> String:
	match depth:
		3: return "pit_guardian"
		6: return "moss_horror"
		9: return "dark_sorcerer"
		12: return "lich_lord"
		15: return "fire_demon"
		18: return "nazgul"
		20: return "necromancer"
		_: return ""

## Get monster table for a specific depth
static func get_monster_table(depth: int) -> Dictionary:
	var layer_name: String = get_layer_name(depth)
	if layer_name in LAYER_MONSTER_TABLES:
		return LAYER_MONSTER_TABLES[layer_name]
	return {}

## Get item tval table for a specific depth
static func get_item_tval_table(depth: int) -> Dictionary:
	var layer_name: String = get_layer_name(depth)
	if layer_name in LAYER_ITEM_TVALS:
		return LAYER_ITEM_TVALS[layer_name]
	return {}

## Get decoration parameters for a specific depth
static func get_decoration_params(depth: int) -> Dictionary:
	var layer_name: String = get_layer_name(depth)
	if layer_name in DECORATION_PARAMS:
		return DECORATION_PARAMS[layer_name]
	return {"themed_room_chance": 0.0, "scatter_density": 0.0, "chasm_count_min": 0, "chasm_count_max": 0, "decorators": []}
