extends Entity
class_name Player
## The player character - the reawakened Necromancer.

signal experience_gained(amount: int)
signal xp_spent(amount: int, skill_name: String)
signal player_died(cause: String, killer_name: String)

# Character creation
@export var race_name: String = "Man"
@export var house_name: String = ""

# XP System (Sil-Q style - XP is currency for skills, no levels)
const STARTING_XP: int = 5000
const XP_MULTIPLIER: float = 1.3  # 130% boost from base Sil-Q
@export var total_xp_earned: int = 0  # Lifetime XP for records
@export var xp_available: int = STARTING_XP  # XP available to spend

# XP tracking by source
var kill_xp: int = 0
var encounter_xp: int = 0
var descent_xp: int = 0
var identify_xp: int = 0

# Skills (0-20 scale)
var skills: Dictionary = {
	"melee": 0,
	"archery": 0,
	"evasion": 0,
	"stealth": 0,
	"perception": 0,
	"will": 0,
	"smithing": 0,
	"lore": 0,  # Was "song" in Sil-Q
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

# Run statistics (Phase 7)
var run_stats: RunStats = RunStats.new()

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
	# Base stats (no levels in Sil-Q)
	max_health = 10 + constitution * 2

	# Combat bonuses from skills and stats
	melee_bonus = skills["melee"] + (strength / 2)
	evasion_bonus = skills["evasion"] + (dexterity / 2)

	# Equipment bonuses
	var equip_attack: int = 0
	var equip_evasion: int = 0
	var equip_protection: String = ""

	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		# Item is a DataManager.ItemData - use "in" instead of .has()
		if "attack_bonus" in item:
			equip_attack += item.attack_bonus
		if "evasion_bonus" in item:
			equip_evasion += item.evasion_bonus
		# Protection dice are accumulated as strings for now
		# TODO: Parse and combine protection dice properly

	melee_bonus += equip_attack
	evasion_bonus += equip_evasion

	# Update protection dice from armor
	_recalculate_protection()

func _recalculate_protection() -> void:
	# Sum up protection dice from all armor pieces
	var total_dice: int = 0
	var total_sides: int = 0

	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		# Parse protection_dice string like "1d4" or "2d6"
		if "protection_dice" in item and item.protection_dice != "":
			var parsed := _parse_dice_string(item.protection_dice)
			if parsed.dice > 0:
				# Simple combination: add dice, take max sides
				total_dice += parsed.dice
				if parsed.sides > total_sides:
					total_sides = parsed.sides

	protection_dice = total_dice
	protection_sides = total_sides

func _parse_dice_string(dice_str: String) -> Dictionary:
	# Parse "NdM" format
	var result := {"dice": 0, "sides": 0}
	if dice_str.is_empty():
		return result
	var parts := dice_str.to_lower().split("d")
	if parts.size() == 2:
		result.dice = int(parts[0]) if parts[0].is_valid_int() else 0
		result.sides = int(parts[1]) if parts[1].is_valid_int() else 0
	return result

# ============================================================================
# XP SYSTEM (Sil-Q style - XP as currency)
# ============================================================================

func gain_experience(amount: int, source: String = "misc") -> void:
	# Apply XP multiplier
	var boosted: int = int(amount * XP_MULTIPLIER)

	# Track by source
	match source:
		"kill": kill_xp += boosted
		"encounter": encounter_xp += boosted
		"descent": descent_xp += boosted
		"identify": identify_xp += boosted

	total_xp_earned += boosted
	xp_available += boosted
	experience_gained.emit(boosted)

	GameManager.log_message("Gained %d XP (%s)" % [boosted, source], Color.YELLOW)

func get_skill_cost(current_level: int, points_to_buy: int = 1) -> int:
	# Cost for nth skill point = 100 × n
	# Total cost to go from current to (current + points) = sum of 100×(current+1) to 100×(current+points)
	var cost: int = 0
	for i in range(points_to_buy):
		cost += 100 * (current_level + i + 1)
	return cost

func can_afford_skill(skill_name: String) -> bool:
	if not skills.has(skill_name):
		return false
	var current: int = skills[skill_name]
	if current >= 20:  # Max skill level
		return false
	return xp_available >= get_skill_cost(current)

func get_total_skill_points() -> int:
	var total: int = 0
	for skill_value in skills.values():
		total += skill_value
	return total

# ============================================================================
# SKILLS
# ============================================================================

func invest_skill(skill_name: String) -> bool:
	if not skills.has(skill_name):
		GameManager.log_message("Unknown skill: %s" % skill_name, Color.RED)
		return false

	var current: int = skills[skill_name]
	if current >= 20:
		GameManager.log_message("%s is already at maximum!" % skill_name.capitalize(), Color.RED)
		return false

	var cost: int = get_skill_cost(current)
	if xp_available < cost:
		GameManager.log_message("Need %d XP to raise %s (have %d)" % [cost, skill_name, xp_available], Color.RED)
		return false

	# Spend XP and increase skill
	xp_available -= cost
	skills[skill_name] += 1
	xp_spent.emit(cost, skill_name)

	GameManager.log_message("Raised %s to %d (-%d XP)" % [skill_name.capitalize(), skills[skill_name], cost], Color.GREEN)
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

func _get_weapon_weight() -> int:
	# Get weight of equipped weapon for crit calculation
	# Heavier weapons = harder crits but more STR damage bonus
	var weapon = equipment.get("weapon")
	if weapon != null and "weight" in weapon:
		return weapon.weight
	return 30  # Unarmed default weight

func get_weapon_damage_dice() -> String:
	var weapon = equipment.get("weapon")
	if weapon != null and "damage_dice" in weapon and weapon.damage_dice != "":
		return weapon.damage_dice
	return "1d4"  # Unarmed

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

# ============================================================================
# DEATH OVERRIDE (Phase 7)
# ============================================================================

func die(killer: Entity = null) -> void:
	if not is_alive:
		return

	is_alive = false

	# Record death in run stats
	var cause: String = "unknown causes"
	var killer_name: String = ""
	var killer_id: int = -1

	if killer:
		killer_name = killer.entity_name
		cause = killer_name
		if killer is Monster and killer.monster_data:
			killer_id = killer.monster_data.id if "id" in killer.monster_data else -1

	run_stats.record_death(cause, killer_name, killer_id)

	# Log death
	GameManager.log_message("You have been slain by %s!" % cause, Color.RED)

	# Emit signals
	player_died.emit(cause, killer_name)
	EventBus.entity_died.emit(self, killer)
	EventBus.game_over.emit(false, cause)

	# Play death animation (don't queue_free - we need the player for death screen)
	_play_death_animation_no_free()

func _play_death_animation_no_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 0.5)

# ============================================================================
# STAT TRACKING HELPERS (Phase 7)
# ============================================================================

func record_damage_dealt(amount: int) -> void:
	run_stats.record_damage_dealt(amount)

func record_kill(monster: Monster) -> void:
	var was_silent: bool = false  # TODO: Detect silent kills
	run_stats.record_kill(monster.entity_name, monster.experience_value, was_silent)
