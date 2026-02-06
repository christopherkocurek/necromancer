extends NPC
class_name ThrainNPC
## Thrain II, son of Thror - the Dwarf King imprisoned in Dol Guldur.
## A unique NPC who gives the player the Ring of Thrain and Key to Erebor.

const RING_OF_THRAIN := "Ring of Thrain"
const KEY_TO_EREBOR := "Key to Erebor"

# Reference to quest system (using Node to avoid cyclic dependency)
var quest_system: Node = null

func _ready() -> void:
	super._ready()
	_setup_thrain()
	_setup_dialogue()
	_setup_sprite()

func _setup_thrain() -> void:
	"""Configure Thrain's properties."""
	npc_id = "thrain_ii"
	entity_name = "Thrain II, Son of Thror"
	is_unique = true
	can_be_attacked = false
	blocks_movement = true

	# Thrain is weak but immortal for story purposes
	max_health = 1
	current_health = 1

func _setup_dialogue() -> void:
	"""Set up Thrain's dialogue tree."""
	dialogue_tree.clear()

	# Node 0 - Introduction
	add_dialogue_node(
		"At last... a living soul in these cursed halls. I am Thrain, son of Thror, King Under the Mountain."
	)

	# Node 1 - Waiting
	add_dialogue_node(
		"I have waited long years for one who might carry word to my kin. The Shadow's dungeons have held me captive since Azanulbizar."
	)

	# Node 2 - Give Ring
	add_dialogue_node(
		"Take this ring - the Ring of Thrain - last of the Seven given to the Dwarf-lords. It is proof of my fate.",
		[RING_OF_THRAIN]
	)

	# Node 3 - Give Key
	add_dialogue_node(
		"And this key - the Key to Erebor, our ancestral home. With it, the secret door may be opened when Durin's Day comes again.",
		[KEY_TO_EREBOR]
	)

	# Node 4 - Mission
	add_dialogue_node(
		"Escape this place. Return to the surface. Tell my son Thorin what became of me, and that the Mountain may yet be reclaimed."
	)

	# Node 5 - Farewell
	add_dialogue_node(
		"Go now. May the Valar protect you on your journey. My time here is done, but through you, Durin's line may yet endure."
	)

func _setup_sprite() -> void:
	"""Set up Thrain's sprite using the DCSS dwarf tile."""
	# Thrain's Shade is monster index 134 in tile_mapper.gd
	# But we want a living dwarf appearance - use player dwarf (index 2)
	# Or the Thorin sprite (305) if available
	var atlas_coords := TileMapper.get_monster_coords(305)  # Thorin Oakenshield
	if atlas_coords == Vector2i(0, 0):
		# Fallback to dwarf player sprite
		atlas_coords = TileMapper.get_player_coords(2)  # Dwarf
	set_sprite_from_atlas_coords(atlas_coords)

func interact():
	"""Override to trigger quest events. Returns DialogueNode (untyped to avoid cyclic dependency)."""
	# Notify quest system on first interaction
	if not has_interacted and quest_system:
		quest_system.on_thrain_found()

	return super.interact()

func _give_item(item_name: String) -> void:
	"""Override to notify quest system of item acquisition."""
	super._give_item(item_name)

	# Notify quest system
	if quest_system:
		match item_name:
			RING_OF_THRAIN:
				quest_system.on_ring_acquired()
			KEY_TO_EREBOR:
				quest_system.on_key_acquired()

func _create_quest_item(item_name: String) -> DataManager.ItemData:
	"""Create special quest items for Thrain."""
	var quest_item := DataManager.ItemData.new()
	quest_item.flags = ["QUEST_ITEM", "INDESTRUCTIBLE"]

	match item_name:
		RING_OF_THRAIN:
			quest_item.name = RING_OF_THRAIN
			quest_item.display_char = "="
			quest_item.color = "y"
			quest_item.tval = 45  # TV_RING
			quest_item.sval = 99  # Unique
			quest_item.index = 541  # Use Thror's Coin tile for display
			quest_item.description = "The Ring of Thrain, last of the Seven Rings of the Dwarf-lords. It burns with inner fire and grants courage to its bearer."
			quest_item.attack_bonus = 2
			quest_item.evasion_bonus = 2
			quest_item.flags.append("RES_FIRE")
			return quest_item
		KEY_TO_EREBOR:
			quest_item.name = KEY_TO_EREBOR
			quest_item.display_char = "~"
			quest_item.color = "s"
			quest_item.tval = 80  # Miscellaneous
			quest_item.sval = 99  # Unique
			quest_item.index = 175  # Map of Thrain artifact tile for display
			quest_item.description = "An ornate dwarven key, inscribed with runes of opening. It unlocks the secret way out of Dol Guldur."
			return quest_item
		_:
			return super._create_quest_item(item_name)

func on_dialogue_complete() -> void:
	"""Called when all dialogue is exhausted."""
	if quest_system:
		quest_system.on_thrain_dialogue_complete()

	GameManager.log_message("Thrain fades into shadow, his spirit finally at peace.", ThemeColors.SECONDARY)

	# Optional: Thrain could fade away or become a corpse
	# For now, he remains but won't speak again

# Static factory method
static func create_at_position(pos: Vector2i, quest_sys: Node = null) -> Node:
	"""Factory method to create Thrain at a specific position. Returns Node (untyped to avoid self-reference)."""
	var thrain = (load("res://scripts/entities/thrain_npc.gd") as GDScript).new()
	thrain.grid_position = pos
	thrain.quest_system = quest_sys
	return thrain
