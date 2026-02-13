extends Node
class_name QuestSystem
## Manages the main quest progression for The Necromancer.
## Tracks Thrain encounter, ring/key acquisition, Rod of Istari, and victory conditions.

signal quest_updated(quest_state: QuestState)
signal thrain_found()
signal ring_acquired()
signal key_acquired()
signal rod_piece_acquired(piece_num: int)
signal rod_assembled()
signal escape_available()
signal banishment_available()
signal victory_achieved(victory_type: String)

# Quest state enum
enum QuestState {
	NOT_STARTED,       # Player hasn't found Thrain
	THRAIN_FOUND,      # Player has encountered Thrain
	HAS_RING,          # Player has Ring of Thrain
	HAS_KEY,           # Player has Key to Erebor
	HAS_BOTH,          # Player has both items (escape ready)
	HAS_ROD_PIECE,     # Player has at least one Rod piece
	ROD_ASSEMBLED,     # Player has assembled Rod of Istari
	ESCAPED,           # Player escaped Dol Guldur
	BANISHED,          # Player banished Sauron
	VICTORY            # Full victory achieved
}

# Current quest state
var current_state: QuestState = QuestState.NOT_STARTED

# Tracking flags
var thrain_spawned: bool = false
var thrain_dialogue_complete: bool = false
var has_ring_of_thrain: bool = false
var has_key_to_erebor: bool = false
var reached_surface: bool = false
var necromancer_defeated: bool = false

# Rod of Istari tracking
var rod_piece_1: bool = false
var rod_piece_2: bool = false
var rod_piece_3: bool = false
var rod_assembled_flag: bool = false

# Location tracking
var in_throne_room: bool = false

# Thrain spawn depth
const THRAIN_MIN_DEPTH: int = 15

# Rod piece spawn depths (scattered across dungeon)
const ROD_PIECE_1_DEPTH: int = 10
const ROD_PIECE_2_DEPTH: int = 15
const ROD_PIECE_3_DEPTH: int = 18

# Player reference
var player: Player = null

# Quest item names (for matching in inventory)
const ITEM_RING_OF_THRAIN: String = "Ring of Thrain"
const ITEM_KEY_TO_EREBOR: String = "Key to Erebor"
const ITEM_ROD_PIECE_1: String = "Rod of Istari (Head)"
const ITEM_ROD_PIECE_2: String = "Rod of Istari (Shaft)"
const ITEM_ROD_PIECE_3: String = "Rod of Istari (Base)"
const ITEM_ROD_OF_ISTARI: String = "Rod of Istari"

func _ready() -> void:
	# Connect to relevant events
	if EventBus:
		EventBus.level_entered.connect(_on_level_entered)
		EventBus.item_picked_up.connect(_on_item_picked_up)
		EventBus.item_dropped.connect(_on_item_dropped)

func set_player(p: Player) -> void:
	player = p

func _on_level_entered(depth: int) -> void:
	# Track deepest depth for descent XP
	# Reset throne room flag when changing levels
	in_throne_room = false

func _on_item_picked_up(entity: Node, item: Variant) -> void:
	if entity != player:
		return
	var item_name: String = _get_item_name(item)
	_check_quest_item_pickup(item_name)

func _on_item_dropped(entity: Node, item: Variant, _position: Vector2i) -> void:
	if entity != player:
		return
	var item_name: String = _get_item_name(item)
	_check_quest_item_drop(item_name)

func _get_item_name(item: Variant) -> String:
	if item is DataManager.ItemData:
		return item.name
	elif item != null and "name" in item:
		return item.name
	return ""

func _check_quest_item_pickup(item_name: String) -> void:
	match item_name:
		ITEM_RING_OF_THRAIN:
			on_ring_acquired()
		ITEM_KEY_TO_EREBOR:
			on_key_acquired()
		ITEM_ROD_PIECE_1:
			on_rod_piece_acquired(1)
		ITEM_ROD_PIECE_2:
			on_rod_piece_acquired(2)
		ITEM_ROD_PIECE_3:
			on_rod_piece_acquired(3)

func _check_quest_item_drop(item_name: String) -> void:
	match item_name:
		ITEM_RING_OF_THRAIN:
			has_ring_of_thrain = false
			_update_quest_state()
		ITEM_KEY_TO_EREBOR:
			has_key_to_erebor = false
			_update_quest_state()
		# Rod pieces can't be dropped once picked up (INDESTRUCTIBLE flag)

func can_spawn_thrain(depth: int) -> bool:
	"""Check if Thrain can spawn at this depth."""
	return depth >= THRAIN_MIN_DEPTH and not thrain_spawned

func mark_thrain_spawned() -> void:
	"""Mark that Thrain has been spawned."""
	thrain_spawned = true

func on_thrain_found() -> void:
	"""Called when player first interacts with Thrain."""
	if current_state == QuestState.NOT_STARTED:
		current_state = QuestState.THRAIN_FOUND
		thrain_found.emit()
		quest_updated.emit(current_state)
		GameManager.log_message("Quest Updated: You have found Thrain, son of Thror!", ThemeColors.PRIMARY)

func on_ring_acquired() -> void:
	"""Called when player receives the Ring of Thrain."""
	has_ring_of_thrain = true
	ring_acquired.emit()
	_update_quest_state()
	GameManager.log_message("Quest Updated: You have received the Ring of Thrain!", ThemeColors.PRIMARY)

func on_key_acquired() -> void:
	"""Called when player receives the Key to Erebor."""
	has_key_to_erebor = true
	key_acquired.emit()
	_update_quest_state()
	GameManager.log_message("Quest Updated: You have received the Key to Erebor!", ThemeColors.PRIMARY)

func on_rod_piece_acquired(piece_num: int) -> void:
	"""Called when player receives a piece of the Rod of Istari."""
	match piece_num:
		1: rod_piece_1 = true
		2: rod_piece_2 = true
		3: rod_piece_3 = true

	rod_piece_acquired.emit(piece_num)
	GameManager.log_message("Quest Updated: You have found a piece of the Rod of Istari!", ThemeColors.PRIMARY)

	# Check if all pieces collected
	if rod_piece_1 and rod_piece_2 and rod_piece_3:
		_assemble_rod()
	else:
		_update_quest_state()

func _assemble_rod() -> void:
	"""Assemble the Rod of Istari from its three pieces."""
	if rod_assembled_flag:
		return

	rod_assembled_flag = true
	rod_assembled.emit()

	# Remove pieces from player inventory and add assembled rod
	if player:
		var pieces_to_remove: Array = []
		for item in player.inventory:
			var item_name: String = _get_item_name(item)
			if item_name in [ITEM_ROD_PIECE_1, ITEM_ROD_PIECE_2, ITEM_ROD_PIECE_3]:
				pieces_to_remove.append(item)

		for piece in pieces_to_remove:
			player.inventory.erase(piece)

		# Add the assembled rod
		var assembled_rod: DataManager.ItemData = create_rod_of_istari()
		player.inventory.append(assembled_rod)

	GameManager.log_message("The three pieces of the Rod fuse together with blinding light!", ThemeColors.PRIMARY)
	GameManager.log_message("The Rod of Istari is whole once more!", ThemeColors.MSG_INFO)
	_update_quest_state()

func on_thrain_dialogue_complete() -> void:
	"""Called when Thrain's dialogue is finished."""
	thrain_dialogue_complete = true
	_update_quest_state()

func _update_quest_state() -> void:
	"""Update quest state based on current flags."""
	var old_state := current_state

	# Check for rod assembled state first (higher priority)
	if rod_assembled_flag:
		if current_state != QuestState.ROD_ASSEMBLED and current_state != QuestState.BANISHED:
			current_state = QuestState.ROD_ASSEMBLED
			banishment_available.emit()
			GameManager.log_message("With the Rod of Istari, you may attempt to banish the Necromancer!", ThemeColors.MSG_INFO)
	elif rod_piece_1 or rod_piece_2 or rod_piece_3:
		# GDScript enums don't have ordinal() - compare directly
		if current_state < QuestState.HAS_ROD_PIECE:
			current_state = QuestState.HAS_ROD_PIECE

	# Check for escape items
	if has_ring_of_thrain and has_key_to_erebor:
		if current_state != QuestState.HAS_BOTH and current_state != QuestState.ESCAPED and current_state != QuestState.ROD_ASSEMBLED:
			current_state = QuestState.HAS_BOTH
			escape_available.emit()
			GameManager.log_message("You have both the Ring and the Key! Escape to the surface!", ThemeColors.MSG_INFO)
	elif has_key_to_erebor:
		if current_state == QuestState.THRAIN_FOUND or current_state == QuestState.NOT_STARTED:
			current_state = QuestState.HAS_KEY
	elif has_ring_of_thrain:
		if current_state == QuestState.THRAIN_FOUND or current_state == QuestState.NOT_STARTED:
			current_state = QuestState.HAS_RING

	if old_state != current_state:
		quest_updated.emit(current_state)

func set_throne_room(value: bool) -> void:
	"""Set whether player is in Sauron's throne room."""
	in_throne_room = value
	if value:
		GameManager.log_message("You have entered the Throne Room of the Necromancer!", ThemeColors.STATUS_AFRAID)

# ============================================================================
# VICTORY CONDITIONS
# ============================================================================

func can_escape() -> Dictionary:
	"""Check if player can achieve Escape Victory."""
	var result: Dictionary = {
		"can_escape": false,
		"missing": []
	}

	if not has_ring_of_thrain:
		result.missing.append("Ring of Thrain")
	if not has_key_to_erebor:
		result.missing.append("Key to Erebor")
	if GameManager.current_depth != 1:
		result.missing.append("Must be at depth 1 (currently at depth %d)" % GameManager.current_depth)

	result.can_escape = result.missing.is_empty()
	return result

func can_banish() -> Dictionary:
	"""Check if player can achieve Banishment Victory."""
	var result: Dictionary = {
		"can_banish": false,
		"missing": []
	}

	if not rod_assembled_flag:
		result.missing.append("Assembled Rod of Istari")
	if not in_throne_room:
		result.missing.append("Must be in Sauron's Throne Room")

	if player:
		var lore_skill: int = player.get_skill("lore")
		var will_skill: int = player.get_skill("will")
		if lore_skill < 12:
			result.missing.append("Lore skill must be 12+ (current: %d)" % lore_skill)
		if will_skill < 10:
			result.missing.append("Will skill must be 10+ (current: %d)" % will_skill)

	result.can_banish = result.missing.is_empty()
	return result

func attempt_escape() -> bool:
	"""Attempt escape victory (called when ascending from depth 1)."""
	var check: Dictionary = can_escape()
	if not check.can_escape:
		GameManager.log_message("You cannot escape yet:", ThemeColors.MSG_ERROR)
		for missing in check.missing:
			GameManager.log_message("  - " + missing, ThemeColors.MSG_WARNING)
		return false

	# Success!
	current_state = QuestState.ESCAPED
	quest_updated.emit(current_state)
	victory_achieved.emit("escape")

	GameManager.log_message("You emerge from the darkness into the light of day!", ThemeColors.PRIMARY)
	GameManager.log_message("The Ring of Thrain guides you through the hidden gates.", ThemeColors.MSG_INFO)
	GameManager.log_message("YOU HAVE ESCAPED DOL GULDUR!", ThemeColors.ABILITY_LEARNED)

	# Record in run stats
	if player and player.run_stats:
		player.run_stats.victory = true
		player.run_stats.victory_type = "Escape"
		player.run_stats.record_victory("Escape")
		if ChronicleManager:
			ChronicleManager.record_run(player, player.run_stats, "escape")

	EventBus.game_over.emit(true, "Escape Victory")
	return true

func attempt_banishment() -> bool:
	"""Attempt banishment victory (called when using Rod in Throne Room)."""
	var check: Dictionary = can_banish()
	if not check.can_banish:
		GameManager.log_message("You cannot perform the banishment:", ThemeColors.MSG_ERROR)
		for missing in check.missing:
			GameManager.log_message("  - " + missing, ThemeColors.MSG_WARNING)
		return false

	# Will check vs Sauron (difficulty 25)
	var will_skill: int = player.get_effective_skill("will") if player else 0
	var lore_skill: int = player.get_effective_skill("lore") if player else 0
	var player_roll: int = randi_range(1, 20) + will_skill + (lore_skill / 2)
	var sauron_difficulty: int = 25

	GameManager.log_message("You raise the Rod of Istari and speak the words of banishment!", ThemeColors.PRIMARY)
	GameManager.log_message("Your will: %d vs Sauron's power: %d" % [player_roll, sauron_difficulty], ThemeColors.MSG_INFO)

	if player_roll >= sauron_difficulty:
		# Success!
		current_state = QuestState.BANISHED
		quest_updated.emit(current_state)
		necromancer_defeated = true
		victory_achieved.emit("banishment")

		GameManager.log_message("Light erupts from the Rod, shattering the dark throne!", ThemeColors.PRIMARY)
		GameManager.log_message("Sauron's spirit is cast out, his power broken!", ThemeColors.ABILITY_LEARNED)
		GameManager.log_message("YOU HAVE BANISHED THE NECROMANCER!", ThemeColors.ABILITY_LEARNED)

		# Record in run stats
		if player and player.run_stats:
			player.run_stats.victory = true
			player.run_stats.victory_type = "Banishment"
			player.run_stats.necromancer_defeated = true
			player.run_stats.record_victory("Banishment")
			if ChronicleManager:
				ChronicleManager.record_run(player, player.run_stats, "banishment")

		EventBus.game_over.emit(true, "Banishment Victory")
		return true
	else:
		# Failure - consequences
		GameManager.log_message("The Rod flickers and dims! Sauron's will overpowers you!", ThemeColors.MSG_ERROR)
		if player:
			var damage: int = player.max_health / 2
			player.take_damage(damage, "dark", null)
			GameManager.log_message("You take %d damage from the backlash!" % damage, ThemeColors.MSG_ERROR)
		GameManager.log_message("You must grow stronger before attempting again.", ThemeColors.MSG_WARNING)
		return false

func on_surface_reached() -> void:
	"""Called when player reaches depth 0 (escapes)."""
	reached_surface = true
	if current_state == QuestState.HAS_BOTH:
		attempt_escape()

func on_necromancer_defeated() -> void:
	"""Called when the Necromancer is defeated (optional objective)."""
	necromancer_defeated = true
	if current_state == QuestState.ESCAPED:
		current_state = QuestState.VICTORY
		quest_updated.emit(current_state)

func get_quest_description() -> String:
	"""Get human-readable quest status."""
	match current_state:
		QuestState.NOT_STARTED:
			return "Descend into Dol Guldur and find Thrain."
		QuestState.THRAIN_FOUND:
			return "Speak with Thrain to learn of his fate."
		QuestState.HAS_RING:
			return "You carry the Ring of Thrain. Find the Key to Erebor."
		QuestState.HAS_KEY:
			return "You carry the Key to Erebor. Find the Ring of Thrain."
		QuestState.HAS_BOTH:
			return "Escape Dol Guldur and return to the surface!"
		QuestState.HAS_ROD_PIECE:
			var pieces: int = int(rod_piece_1) + int(rod_piece_2) + int(rod_piece_3)
			return "You have %d/3 pieces of the Rod of Istari." % pieces
		QuestState.ROD_ASSEMBLED:
			return "The Rod of Istari is whole. Confront the Necromancer in his throne room!"
		QuestState.ESCAPED:
			return "You have escaped! Deliver Thrain's message to Thorin."
		QuestState.BANISHED:
			return "Victory! The Necromancer has been banished from Middle-earth!"
		QuestState.VICTORY:
			return "Complete Victory! The legacy of Durin lives on."
	return "Unknown quest state."

func has_quest_items() -> bool:
	"""Check if player has any quest items."""
	return has_ring_of_thrain or has_key_to_erebor or rod_piece_1 or rod_piece_2 or rod_piece_3 or rod_assembled_flag

func get_score_multiplier() -> float:
	"""Get score multiplier based on quest completion."""
	match current_state:
		QuestState.BANISHED:
			return 3.5  # Highest reward for banishment
		QuestState.VICTORY:
			return 3.0
		QuestState.ESCAPED:
			return 2.0
		QuestState.ROD_ASSEMBLED:
			return 1.75
		QuestState.HAS_BOTH:
			return 1.5
		_:
			return 1.0

func get_rod_piece_count() -> int:
	"""Get number of rod pieces collected."""
	return int(rod_piece_1) + int(rod_piece_2) + int(rod_piece_3)

# ============================================================================
# QUEST ITEM CREATION
# ============================================================================

static func create_ring_of_thrain() -> DataManager.ItemData:
	"""Create the Ring of Thrain quest item."""
	var ring: DataManager.ItemData = DataManager.ItemData.new()
	ring.name = ITEM_RING_OF_THRAIN
	ring.display_char = "="
	ring.color = "y"  # Gold/yellow
	ring.tval = 45  # Ring
	ring.sval = 99  # Unique quest item
	ring.weight = 2
	ring.description = "The Ring of Thrain, last of the Seven Rings of the Dwarf-lords. It burns with inner fire and grants courage to its bearer."
	ring.flags.append("QUEST_ITEM")
	ring.flags.append("INDESTRUCTIBLE")
	ring.flags.append("RES_FIRE")
	# Combat bonuses
	ring.attack_bonus = 2
	ring.evasion_bonus = 2
	return ring

static func create_key_to_erebor() -> DataManager.ItemData:
	"""Create the Key to Erebor quest item."""
	var key: DataManager.ItemData = DataManager.ItemData.new()
	key.name = ITEM_KEY_TO_EREBOR
	key.display_char = "~"
	key.color = "s"  # Silver
	key.tval = 80  # Miscellaneous
	key.sval = 99  # Unique quest item
	key.weight = 5
	key.description = "An ornate dwarven key, inscribed with runes of opening. It unlocks the secret way out of Dol Guldur."
	key.flags.append("QUEST_ITEM")
	key.flags.append("INDESTRUCTIBLE")
	return key

static func create_rod_piece(piece_num: int) -> DataManager.ItemData:
	"""Create a piece of the Rod of Istari."""
	var piece: DataManager.ItemData = DataManager.ItemData.new()
	match piece_num:
		1:
			piece.name = ITEM_ROD_PIECE_1
			piece.description = "The head of the Rod of Istari, crowned with a clear gem that glows faintly with inner light."
		2:
			piece.name = ITEM_ROD_PIECE_2
			piece.description = "The shaft of the Rod of Istari, carved with ancient runes of power in the tongue of Valinor."
		3:
			piece.name = ITEM_ROD_PIECE_3
			piece.description = "The base of the Rod of Istari, wrapped in mithril wire that never tarnishes."
		_:
			piece.name = "Rod Fragment"
			piece.description = "A fragment of a broken staff of great power."

	piece.display_char = "/"
	piece.color = "w"  # White
	piece.tval = 55  # Staff
	piece.sval = 98 + piece_num  # Unique identifier per piece
	piece.weight = 15
	piece.flags.append("QUEST_ITEM")
	piece.flags.append("INDESTRUCTIBLE")
	return piece

static func create_rod_of_istari() -> DataManager.ItemData:
	"""Create the assembled Rod of Istari."""
	var rod: DataManager.ItemData = DataManager.ItemData.new()
	rod.name = ITEM_ROD_OF_ISTARI
	rod.display_char = "/"
	rod.color = "W"  # Bright white
	rod.tval = 55  # Staff
	rod.sval = 100  # Unique assembled item
	rod.weight = 40
	rod.description = "The assembled Rod of Istari, a weapon of the Maiar capable of banishing great evils. In your hands, it thrums with barely contained power."
	rod.flags.append("QUEST_ITEM")
	rod.flags.append("INDESTRUCTIBLE")
	rod.flags.append("BLESSED")
	# The Rod grants significant bonuses
	rod.attack_bonus = 5
	rod.damage_dice = "2d6"
	rod.evasion_bonus = 3
	return rod

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	"""Serialize quest state to dictionary."""
	return {
		"current_state": current_state,
		"thrain_spawned": thrain_spawned,
		"thrain_dialogue_complete": thrain_dialogue_complete,
		"has_ring_of_thrain": has_ring_of_thrain,
		"has_key_to_erebor": has_key_to_erebor,
		"reached_surface": reached_surface,
		"necromancer_defeated": necromancer_defeated,
		"rod_piece_1": rod_piece_1,
		"rod_piece_2": rod_piece_2,
		"rod_piece_3": rod_piece_3,
		"rod_assembled_flag": rod_assembled_flag,
		"in_throne_room": in_throne_room,
	}

func from_dict(data: Dictionary) -> void:
	"""Deserialize quest state from dictionary."""
	current_state = data.get("current_state", QuestState.NOT_STARTED)
	thrain_spawned = data.get("thrain_spawned", false)
	thrain_dialogue_complete = data.get("thrain_dialogue_complete", false)
	has_ring_of_thrain = data.get("has_ring_of_thrain", false)
	has_key_to_erebor = data.get("has_key_to_erebor", false)
	reached_surface = data.get("reached_surface", false)
	necromancer_defeated = data.get("necromancer_defeated", false)
	rod_piece_1 = data.get("rod_piece_1", false)
	rod_piece_2 = data.get("rod_piece_2", false)
	rod_piece_3 = data.get("rod_piece_3", false)
	rod_assembled_flag = data.get("rod_assembled_flag", false)
	in_throne_room = data.get("in_throne_room", false)
