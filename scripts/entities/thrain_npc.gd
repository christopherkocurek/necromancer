extends NPC
class_name ThrainNPC
## Thrain II, son of Thror - the Dwarf King imprisoned in Dol Guldur.
## A unique NPC who gives the player the Ring of Thrain and Key to Erebor.

const RING_OF_THRAIN := "Ring of Thrain"
const KEY_TO_EREBOR := "Key to Erebor"
const MAP_OF_EREBOR := "Map of Erebor"
const THRAIN_PRIMARY_TILE_ID: int = 134
const THRAIN_FALLBACK_TILE_ID: int = 305

# Reference to quest system (using Node to avoid cyclic dependency)
var quest_system: Node = null
var _beacon: Sprite2D = null
var _sprite_override: Sprite2D = null

func _ready() -> void:
	super._ready()
	# Keep Thrain visually obvious in the endgame chamber.
	z_as_relative = false
	z_index = 250
	visible = true
	_setup_thrain()
	_setup_dialogue()
	_setup_sprite()
	call_deferred("_force_visible_sprite_state")

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

	# Node 4 - Give Map
	add_dialogue_node(
		"And this map, hidden from the Enemy's eye. With the key, it reveals the true way.",
		[MAP_OF_EREBOR]
	)

	# Node 5 - Mission
	add_dialogue_node(
		"Escape this place. Return to the surface. Tell my son Thorin what became of me, and that the Mountain may yet be reclaimed."
	)

	# Node 6 - Farewell
	add_dialogue_node(
		"Go now. May the Valar protect you on your journey. My time here is done, but through you, Durin's line may yet endure."
	)

func _setup_sprite() -> void:
	"""Set up Thrain's sprite."""
	# Prefer the clearly visible dwarf king portrait in current atlas, and keep
	# Thrain's Shade as fallback in case mapping/content changes.
	var atlas_coords := TileMapper.get_monster_coords(THRAIN_PRIMARY_TILE_ID)
	if atlas_coords == Vector2i(0, 0):
		atlas_coords = TileMapper.get_monster_coords(THRAIN_FALLBACK_TILE_ID)
		if atlas_coords == Vector2i(0, 0):
			atlas_coords = TileMapper.get_player_coords(2)
	set_sprite_from_atlas_coords(atlas_coords)

func _force_visible_sprite_state() -> void:
	visible = true
	var atlas_coords := TileMapper.get_monster_coords(THRAIN_PRIMARY_TILE_ID)
	if atlas_coords == Vector2i(0, 0):
		atlas_coords = TileMapper.get_monster_coords(THRAIN_FALLBACK_TILE_ID)
	_ensure_override_sprite(atlas_coords)

	if sprite == null and has_node("Sprite2D"):
		sprite = $Sprite2D
	if sprite:
		# Re-assert texture/region directly to avoid any stale render state.
		if sprite.texture == null:
			sprite.texture = load("res://assets/sprites/necromancer_dcss_tileset.png")
		sprite.region_enabled = true
		if atlas_coords != Vector2i(0, 0):
			var tile_size := GameManager.TILE_SIZE
			sprite.region_rect = Rect2(
				atlas_coords.x * tile_size,
				atlas_coords.y * tile_size,
				tile_size,
				tile_size
			)
		# Bypass keyed shader for Thrain specifically; this removes any chance of
		# accidental transparency from render material state.
		sprite.material = null
		sprite.visible = true
		sprite.z_as_relative = false
		sprite.z_index = 260
		sprite.modulate = Color(1.35, 1.35, 1.45, 1.0)
	_setup_beacon()

func _ensure_override_sprite(atlas_coords: Vector2i) -> void:
	if atlas_coords == Vector2i(0, 0):
		return
	if _sprite_override == null or not is_instance_valid(_sprite_override):
		_sprite_override = Sprite2D.new()
		_sprite_override.name = "ThrainSpriteOverride"
		_sprite_override.centered = false
		_sprite_override.position = Vector2.ZERO
		_sprite_override.z_as_relative = false
		_sprite_override.z_index = 280
		add_child(_sprite_override)
	if _sprite_override.texture == null:
		_sprite_override.texture = load("res://assets/sprites/necromancer_dcss_tileset.png")
	_sprite_override.region_enabled = true
	var tile_size := GameManager.TILE_SIZE
	_sprite_override.region_rect = Rect2(
		atlas_coords.x * tile_size,
		atlas_coords.y * tile_size,
		tile_size,
		tile_size
	)
	_sprite_override.material = null
	_sprite_override.visible = true
	_sprite_override.modulate = Color(1.25, 1.25, 1.35, 1.0)

func _setup_beacon() -> void:
	if _beacon and is_instance_valid(_beacon):
		_beacon.visible = true
		return
	var beacon_texture := ImageTexture.create_from_image(Image.create(6, 6, false, Image.FORMAT_RGBA8))
	var img := beacon_texture.get_image()
	img.fill(Color(0.55, 0.95, 1.0, 0.95))
	beacon_texture.update(img)
	_beacon = Sprite2D.new()
	_beacon.name = "ThrainBeacon"
	_beacon.texture = beacon_texture
	_beacon.centered = true
	_beacon.position = Vector2(GameManager.TILE_SIZE / 2, 6)
	_beacon.z_as_relative = false
	_beacon.z_index = 300
	add_child(_beacon)

func _process(_delta: float) -> void:
	# Keep render state stable for playtest visibility checks.
	_force_visible_sprite_state()

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
	quest_item.identified = true

	match item_name:
		RING_OF_THRAIN:
			quest_item.name = RING_OF_THRAIN
			quest_item.display_char = "="
			quest_item.color = "y"
			quest_item.tval = 45  # TV_RING
			quest_item.sval = 99  # Unique
			quest_item.index = 175  # Quest artifact ring
			quest_item.description = "The Ring of Thrain, last of the Seven Rings of the Dwarf-lords. It burns with inner fire and grants courage to its bearer."
			quest_item.attack_bonus = 2
			quest_item.evasion_bonus = 2
			quest_item.flags.append("RES_FIRE")
			return quest_item
		KEY_TO_EREBOR:
			quest_item.name = KEY_TO_EREBOR
			quest_item.display_char = ")"
			quest_item.color = "s"
			quest_item.tval = 80  # Miscellaneous
			quest_item.sval = 99  # Unique
			quest_item.index = 179  # Quest artifact key
			quest_item.description = "An ornate dwarven key, inscribed with runes of opening. It unlocks the secret way out of Dol Guldur."
			return quest_item
		MAP_OF_EREBOR:
			quest_item.name = MAP_OF_EREBOR
			quest_item.display_char = "~"
			quest_item.color = "y"
			quest_item.tval = 80
			quest_item.sval = 98
			quest_item.index = 180  # Quest artifact map
			quest_item.description = "A map of Erebor showing the hidden door and runes for Durin's Day."
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
