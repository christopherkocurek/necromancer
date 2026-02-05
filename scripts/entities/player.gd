extends Entity
class_name Player
## The player character - the reawakened Necromancer.

signal experience_gained(amount: int)
signal level_up(new_level: int)
signal skill_points_gained(amount: int)

# Character creation
@export var race_name: String = "Man"
@export var house_name: String = ""

# Experience & Level
@export var experience: int = 0
@export var level: int = 1

# Skills (0-20 scale)
var skills: Dictionary = {
	"melee": 0,
	"archery": 0,
	"evasion": 0,
	"stealth": 0,
	"perception": 0,
	"will": 0,
	"smithing": 0,
	"song": 0,
}

# Necromancer-specific
var lore_known: Dictionary = {}  # monster_type -> Array of lore abilities
var voice_charges: int = 0  # For song/voice abilities
var max_voice: int = 10

# Equipment slots
var equipment: Dictionary = {
	"weapon": null,
	"off_hand": null,
	"armor": null,
	"cloak": null,
	"head": null,
	"hands": null,
	"feet": null,
	"ring_left": null,
	"ring_right": null,
	"amulet": null,
	"light": null,
}

# Inventory
var inventory: Array = []
var max_inventory: int = 23  # a-w

# Movement tracking for running
var last_direction: Vector2i = Vector2i.ZERO
var is_running: bool = false

# ============================================================================
# ABILITY TRACKING (Phase 4)
# ============================================================================

# Ability arrays (S_MAX x ABILITIES_MAX)
var innate_ability: Array = []   # Learned permanently
var active_ability: Array = []   # Currently enabled
var have_ability: Array = []     # Includes item grants

# Action tracking (for abilities like Charge, Dodging, Controlled Retreat)
var previous_action: Array = []  # Last 3 actions [0]=most recent

# Combat state (reset each turn)
var ripostes_this_turn: int = 0
var attacks_this_turn: int = 0
var consecutive_attacks: int = 0
var last_attack_monster_idx: int = -1
var knocked_back: bool = false
var moved_this_turn: bool = false

func _ready() -> void:
	super._ready()
	entity_name = "Necromancer"
	_init_ability_arrays()
	_apply_racial_modifiers()
	_setup_player_sprite()

func _init_ability_arrays() -> void:
	# Initialize ability tracking arrays (S_MAX x ABILITIES_MAX)
	innate_ability.clear()
	active_ability.clear()
	have_ability.clear()
	for i in range(Constants.S_MAX):
		var innate_row: Array = []
		var active_row: Array = []
		var have_row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			innate_row.append(false)
			active_row.append(false)
			have_row.append(false)
		innate_ability.append(innate_row)
		active_ability.append(active_row)
		have_ability.append(have_row)
	# Initialize action tracking
	previous_action.resize(Constants.ACTION_MAX)
	previous_action.fill(Constants.ACTION_NOTHING)

func record_action(action: int) -> void:
	previous_action.insert(0, action)
	if previous_action.size() > Constants.ACTION_MAX:
		previous_action.resize(Constants.ACTION_MAX)

func reset_turn_state() -> void:
	ripostes_this_turn = 0
	attacks_this_turn = 0
	moved_this_turn = false
	knocked_back = false

func has_ability(skill: int, ability: int) -> bool:
	if skill < 0 or skill >= Constants.S_MAX:
		return false
	if ability < 0 or ability >= Constants.ABILITIES_MAX:
		return false
	return active_ability[skill][ability]

func learn_ability(skill: int, ability: int) -> void:
	if skill < 0 or skill >= Constants.S_MAX:
		return
	if ability < 0 or ability >= Constants.ABILITIES_MAX:
		return
	innate_ability[skill][ability] = true
	active_ability[skill][ability] = true
	have_ability[skill][ability] = true

func _setup_player_sprite() -> void:
	# Map race to sprite index (R:0-3 in PRF)
	var race_to_sprite: Dictionary[String, int] = {
		"Noldor": 0,
		"Sindar": 1,
		"Man": 2,
		"Dwarf": 3,
	}
	var race_sprite_id: int = race_to_sprite.get(race_name, 2)  # Default to Man
	set_sprite_from_monster_id(race_sprite_id)

func _apply_racial_modifiers() -> void:
	var race_data: DataManager.RaceData = DataManager.get_race(race_name)
	if race_data:
		strength += race_data.str_mod
		dexterity += race_data.dex_mod
		constitution += race_data.con_mod
		grace += race_data.gra_mod

	var house_data: DataManager.HouseData = DataManager.get_house(house_name)
	if house_data:
		strength += house_data.str_mod
		dexterity += house_data.dex_mod
		constitution += house_data.con_mod
		grace += house_data.gra_mod

	# Recalculate derived stats
	_recalculate_stats()

func _recalculate_stats() -> void:
	max_health = 10 + constitution * 2 + level
	melee_bonus = skills["melee"] + (strength / 2)
	evasion_bonus = skills["evasion"] + (dexterity / 2)

# ============================================================================
# EXPERIENCE & LEVELING
# ============================================================================

func gain_experience(amount: int) -> void:
	experience += amount
	experience_gained.emit(amount)

	var xp_for_next := _xp_for_level(level + 1)
	while experience >= xp_for_next:
		_level_up()
		xp_for_next = _xp_for_level(level + 1)

func _xp_for_level(target_level: int) -> int:
	# Sil-style XP curve
	return target_level * target_level * 100

func _level_up() -> void:
	level += 1
	max_health += constitution / 2 + 2
	current_health = max_health  # Full heal on level up

	level_up.emit(level)
	GameManager.log_message("You have reached level %d!" % level, Color.YELLOW)

# ============================================================================
# SKILLS
# ============================================================================

func invest_skill(skill_name: String) -> bool:
	if not skills.has(skill_name):
		return false
	if skills[skill_name] >= 20:
		return false
	# Check for available skill points, etc.
	skills[skill_name] += 1
	_recalculate_stats()
	return true

func get_skill(skill_name: String) -> int:
	return skills.get(skill_name, 0)

# ============================================================================
# LORE SYSTEM
# ============================================================================

func learn_lore(monster_type: String, lore_ability: Resource) -> void:
	if not lore_known.has(monster_type):
		lore_known[monster_type] = []
	if not lore_known[monster_type].has(lore_ability):
		lore_known[monster_type].append(lore_ability)
		EventBus.lore_learned.emit(self, monster_type, lore_ability)
		GameManager.log_message("You have learned lore about %s!" % monster_type, Color.CYAN)

func get_lore_for(monster_type: String) -> Array:
	return lore_known.get(monster_type, [])

func has_lore_for(monster_type: String) -> bool:
	return lore_known.has(monster_type) and not lore_known[monster_type].is_empty()

# ============================================================================
# INVENTORY
# ============================================================================

func pick_up_item(item_data: Variant) -> bool:
	if inventory.size() >= max_inventory:
		GameManager.log_message("Your pack is full!", Color.RED)
		return false

	inventory.append(item_data)
	EventBus.item_picked_up.emit(self, item_data)
	return true

func drop_item(item_data: Variant) -> bool:
	var idx := inventory.find(item_data)
	if idx < 0:
		return false

	inventory.remove_at(idx)
	EventBus.item_dropped.emit(self, item_data, grid_position)
	return true

func equip_item(item_data: Variant, slot: String) -> bool:
	if not equipment.has(slot):
		return false

	# Unequip current item in slot
	if equipment[slot] != null:
		unequip_slot(slot)

	equipment[slot] = item_data
	inventory.erase(item_data)
	EventBus.item_equipped.emit(self, item_data, slot)
	_recalculate_stats()
	return true

func unequip_slot(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot] == null:
		return false

	var item = equipment[slot]
	equipment[slot] = null

	if not pick_up_item(item):
		# Can't fit in inventory, drop on ground
		EventBus.item_dropped.emit(self, item, grid_position)

	EventBus.item_unequipped.emit(self, item, slot)
	_recalculate_stats()
	return true

# ============================================================================
# INPUT HANDLING
# ============================================================================

func handle_input() -> bool:
	if not GameManager.is_player_turn:
		return false

	var direction := _get_movement_input()
	if direction != Vector2i.ZERO:
		return try_move(direction)

	if Input.is_action_just_pressed("wait"):
		return true  # Skip turn

	if Input.is_action_just_pressed("pickup"):
		return try_pickup()

	return false

func try_pickup() -> bool:
	if not GameManager.current_level:
		return false

	var items_here: Array[Item] = GameManager.current_level.get_items_at(grid_position)
	if items_here.is_empty():
		GameManager.log_message("There is nothing here to pick up.", Color.GRAY)
		return false

	# Pick up the first item
	var item: Item = items_here[0]
	var item_data = item.get_data()

	if pick_up_item(item_data):
		GameManager.current_level.remove_item(item)
		item.queue_free()
		GameManager.log_message("You pick up the %s." % item.get_display_name(), Color.WHITE)
		return true

	return false

func _get_movement_input() -> Vector2i:
	if Input.is_action_just_pressed("move_up"):
		return Vector2i(0, -1)
	if Input.is_action_just_pressed("move_down"):
		return Vector2i(0, 1)
	if Input.is_action_just_pressed("move_left"):
		return Vector2i(-1, 0)
	if Input.is_action_just_pressed("move_right"):
		return Vector2i(1, 0)
	if Input.is_action_just_pressed("move_up_left"):
		return Vector2i(-1, -1)
	if Input.is_action_just_pressed("move_up_right"):
		return Vector2i(1, -1)
	if Input.is_action_just_pressed("move_down_left"):
		return Vector2i(-1, 1)
	if Input.is_action_just_pressed("move_down_right"):
		return Vector2i(1, 1)
	return Vector2i.ZERO

# ============================================================================
# MOVEMENT OVERRIDE
# ============================================================================

func can_move_to(target: Vector2i) -> bool:
	if not GameManager.current_level:
		return true

	# Check terrain passability
	if GameManager.current_level.has_method("is_passable"):
		var passable: bool = GameManager.current_level.is_passable(target)
		if not passable:
			var tile: int = GameManager.current_level.get_tile(target)
			# Try to open closed doors
			if tile == Level.Tile.DOOR_CLOSED:
				GameManager.current_level.set_tile(target, Level.Tile.DOOR_OPEN)
				GameManager.log_message("You open the door.", Color.WHITE)
				return false  # Opening door takes a turn but doesn't move
			return false

	# Check for blocking entities
	if GameManager.current_level.has_method("get_entity_at"):
		var blocker = GameManager.current_level.get_entity_at(target)
		if blocker and blocker != self:
			# Bump attack if it's a monster
			if blocker is Monster:
				attack_entity(blocker)
			return false

	return true
