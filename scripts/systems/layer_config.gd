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
		"fov_radius": 5,
		"darkness_modifier": -3,
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
