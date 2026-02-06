extends Entity
class_name Player
## The player character - the reawakened Necromancer.

signal experience_gained(amount: int)
signal xp_spent(amount: int, skill_name: String)
signal player_died(cause: String, killer_name: String)

# Character creation
@export var race_name: String = "Man"
@export var house_name: String = ""
@export var trait_name: String = ""
var trait_effect_id: String = ""  # Code-facing ID from trait data (e.g. "defiance")

# Trait state tracking
var _trait_fortune_used: bool = false   # Fortune's Favor: once per floor
var _trait_undying_used: bool = false    # Undying Resolve: once per run
var _trait_shadow_step_used: bool = false # Shadow Step: once per floor

# Racial state tracking
var _hobbit_luck_used: bool = false  # HOBBIT_LUCK: once per floor reroll

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
	"quiver": null,
}

# Inventory
var inventory: Array = []
var max_inventory: int = 23  # a-w

# Movement tracking for running
var last_direction: Vector2i = Vector2i.ZERO
var is_running: bool = false

# Run statistics (Phase 7)
var run_stats: RunStats = RunStats.new()

# Kill tracking for Bane/Master Hunter abilities
var kills_by_name: Dictionary = {}  # entity_name -> int (kill count)

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
var moved_last_turn: bool = false  # For Dodging/Concentration abilities

# Shield tracking for Blocking ability
var _shield_dice: int = 0
var _shield_sides: int = 0

# Opening Strike tracking: monsters we've already attacked
var _opening_strike_used: Dictionary = {}  # entity instance_id -> bool

# Rapid Attack state
var _rapid_attack_penalty: int = 0  # -3 when doing rapid attacks, 0 otherwise

# Vengeance (Will): +2 attack on turn after being hit
var _vengeance_active: bool = false

# Fade (Stealth): temporary stealth bonus after kill
var _fade_bonus: int = 0
var _fade_turns: int = 0

# Follow-Through recursion guard
var _in_follow_through: bool = false

# Sprinting state
var _sprinting_turns: int = 0  # Turns remaining at double speed

# Vanish state
var _vanish_turns: int = 0  # Turns remaining invisible

# Stealth system (Phase B)
var stealth_mode: bool = false       # Toggle with ';' key
var noise_this_turn: int = 0         # Accumulated noise from actions
var was_attacked_this_turn: bool = false  # For combat noise
var attacked_this_turn: bool = false     # For combat noise
var _skip_input_this_frame: bool = false  # Set by main.gd when stealth toggled via direct keycode

func _ready() -> void:
	super._ready()
	entity_name = "Necromancer"
	_init_ability_arrays()
	_apply_racial_modifiers()
	_setup_player_sprite()
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.attack_missed.connect(_on_attack_evaded)

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
	# Concentration: track consecutive attacks without moving
	if attacked_this_turn and not moved_this_turn:
		consecutive_attacks += 1
	elif moved_this_turn:
		consecutive_attacks = 0
	# Vanish turn decay
	if _vanish_turns > 0:
		_vanish_turns -= 1
		if _vanish_turns <= 0:
			_fade_bonus = maxi(0, _fade_bonus - 20)
			GameManager.log_message("You become visible again.", ThemeColors.MSG_SYSTEM)
	moved_last_turn = moved_this_turn  # Preserve for Dodging/Concentration
	ripostes_this_turn = 0
	attacks_this_turn = 0
	moved_this_turn = false
	knocked_back = false
	noise_this_turn = 0
	was_attacked_this_turn = false

func _on_level_entered(_depth: int) -> void:
	reset_per_floor_traits()
	attacked_this_turn = false
	_vengeance_active = false
	# Tick Fade bonus
	if _fade_turns > 0:
		_fade_turns -= 1
		if _fade_turns <= 0:
			_fade_bonus = 0

## Riposte: free counterattack when evading an adjacent monster's attack (1/turn)
func _on_attack_evaded(attacker: Node, defender: Node) -> void:
	if defender != self:
		return
	if not is_instance_valid(attacker) or not attacker is Monster:
		return
	if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_RIPOSTE):
		return
	if ripostes_this_turn > 0:
		return
	# Must be adjacent
	var dist: int = max(abs(attacker.grid_position.x - grid_position.x),
						abs(attacker.grid_position.y - grid_position.y))
	if dist > 1:
		return
	ripostes_this_turn += 1
	GameManager.log_message("You riposte!", ThemeColors.COMBAT_HIT)
	call_deferred("attack_entity", attacker)

## Sprinting: activate to gain +1 speed for 3 turns (costs a turn)
func activate_sprinting() -> bool:
	if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_SPRINTING):
		GameManager.log_message("You haven't learned Sprinting.", ThemeColors.MSG_ERROR)
		return false
	if _sprinting_turns > 0:
		GameManager.log_message("You're already sprinting!", ThemeColors.MSG_SYSTEM)
		return false
	_sprinting_turns = 3 + get_skill("evasion") / 5
	apply_status("fast", _sprinting_turns)
	GameManager.log_message("You break into a sprint!", ThemeColors.ABILITY_LEARNED)
	return true

## Vanish: become effectively invisible for 3 turns (active ability)
func activate_vanish() -> bool:
	if not has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_VANISH):
		GameManager.log_message("You haven't learned Vanish.", ThemeColors.MSG_ERROR)
		return false
	if _vanish_turns > 0:
		GameManager.log_message("You're already hidden!", ThemeColors.MSG_SYSTEM)
		return false
	_vanish_turns = 3
	# Massive stealth bonus while vanished
	_fade_bonus += 20
	GameManager.log_message("You vanish from sight!", ThemeColors.ABILITY_LEARNED)
	return true

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

# ============================================================================
# HERO TRAIT SYSTEM
# ============================================================================

func _apply_trait() -> void:
	if trait_name.is_empty():
		return

	var trait_data: DataManager.TraitData = DataManager.get_trait_by_name(trait_name)
	if not trait_data:
		return

	trait_effect_id = trait_data.effect_id

	# Trait-specific initialization
	match trait_effect_id:
		"song_of_banishment":
			# Grant Song of Banishment ability regardless of Lore level
			if innate_ability.size() > Constants.Skill.S_LOR:
				if innate_ability[Constants.Skill.S_LOR].size() > Constants.LoreAbility.LOR_SONG_OF_BANISHMENT:
					innate_ability[Constants.Skill.S_LOR][Constants.LoreAbility.LOR_SONG_OF_BANISHMENT] = true
					active_ability[Constants.Skill.S_LOR][Constants.LoreAbility.LOR_SONG_OF_BANISHMENT] = true
					have_ability[Constants.Skill.S_LOR][Constants.LoreAbility.LOR_SONG_OF_BANISHMENT] = true
			GameManager.log_message("You know the Song of Banishment!", ThemeColors.ABILITY_LEARNED)

	GameManager.log_message("Trait: %s" % trait_name, ThemeColors.PRIMARY)

func reset_per_floor_traits() -> void:
	## Called when entering a new floor to reset per-floor trait/racial abilities.
	_trait_fortune_used = false
	_trait_shadow_step_used = false
	_hobbit_luck_used = false

## Defiance: +1 attack/damage vs enemies whose native depth > current_depth + 3
func get_defiance_bonus(monster: Entity) -> int:
	if trait_effect_id != "defiance":
		return 0
	if not monster is Monster:
		return 0
	var m: Monster = monster
	if not m.monster_data:
		return 0
	var current_depth: int = GameManager.current_depth if GameManager else 1
	if m.monster_data.depth >= current_depth + 3:
		return 1
	return 0

## Ambush Mastery: extra damage die vs unaware enemies
func get_ambush_mastery_bonus(target: Entity) -> int:
	if trait_effect_id != "ambush_mastery":
		return 0
	if not target is Monster:
		return 0
	var m: Monster = target
	if m.is_sleeping or m.alertness < Constants.ALERTNESS_ALERT:
		return 1  # +1 damage die
	return 0

## Light of the Eldar: +1 light radius (checked in FOV), undead -2 attack/evasion in light
func has_light_of_eldar() -> bool:
	return trait_effect_id == "light_of_eldar"

## Last Stand: +3 attack/damage/evasion when below 25% HP
func get_last_stand_bonus() -> int:
	if trait_effect_id != "last_stand":
		return 0
	if current_health <= max_health / 4:
		return 3
	return 0

## Fortune's Favor: reroll a failed check (returns true if reroll available)
func try_fortune_favor() -> bool:
	if trait_effect_id != "fortunes_favor":
		return false
	if _trait_fortune_used:
		return false
	_trait_fortune_used = true
	GameManager.log_message("Fortune smiles upon you!", ThemeColors.PRIMARY)
	return true

## Undying Resolve: survive lethal damage once per run at 50% HP
func try_undying_resolve() -> bool:
	if trait_effect_id != "undying_resolve":
		return false
	if _trait_undying_used:
		return false
	_trait_undying_used = true
	current_health = max_health / 2
	GameManager.log_message("Your undying resolve keeps you standing!", ThemeColors.PRIMARY)
	return true

## Rallying Cry: on kill, visible enemies must save or lose 20 morale
func trigger_rallying_cry() -> void:
	if trait_effect_id != "rallying_cry":
		return
	if not GameManager.current_level:
		return
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(grid_position, Constants.MAX_SIGHT)
	for entity in entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		var monster: Monster = entity
		var monster_will: int = monster.monster_data.will if monster.monster_data else 5
		var player_roll: int = randi_range(1, 20) + get_skill("will")
		var monster_roll: int = randi_range(1, 20) + monster_will
		if player_roll > monster_roll:
			monster.current_morale -= 20

## Forge Intuition: auto-identify items on pickup
func has_forge_intuition() -> bool:
	return trait_effect_id == "forge_intuition"

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
	# Track shield dice separately for Blocking ability
	_shield_dice = 0
	_shield_sides = 0

	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		# Parse protection_dice string like "1d4" or "2d6"
		if "protection_dice" in item and item.protection_dice != "":
			var parsed := _parse_dice_string(item.protection_dice)
			if parsed.dice > 0:
				# Track shield dice separately
				if slot == "off_hand":
					_shield_dice = parsed.dice
					_shield_sides = parsed.sides
				total_dice += parsed.dice
				if parsed.sides > total_sides:
					total_sides = parsed.sides

	protection_dice = total_dice
	protection_sides = total_sides

## Override protection roll to handle shield Blocking ability.
## When player has EVN_BLOCKING and did not move last turn, shield dice are doubled.
func roll_protection(_damage_type: int = 1) -> int:
	if protection_dice <= 0 or protection_sides <= 0:
		return 0

	var total: int = 0
	# Roll non-shield armor dice normally
	var armor_dice: int = protection_dice - _shield_dice
	for i in range(armor_dice):
		total += randi_range(1, protection_sides)

	# Roll shield dice (doubled if Blocking is active)
	var shield_mult: int = 1
	if _shield_dice > 0 and has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_BLOCKING):
		if not moved_last_turn:
			shield_mult = 2
	for i in range(_shield_dice * shield_mult):
		total += randi_range(1, _shield_sides if _shield_sides > 0 else protection_sides)

	return total

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

	GameManager.log_message("Gained %d XP (%s)" % [boosted, source], ThemeColors.MSG_XP)

## Affinity flag name -> skill name mapping
const AFFINITY_MAP: Dictionary = {
	"MEL_AFFINITY": "melee",
	"ARC_AFFINITY": "archery",
	"EVN_AFFINITY": "evasion",
	"STL_AFFINITY": "stealth",
	"PER_AFFINITY": "perception",
	"WIL_AFFINITY": "will",
	"SMT_AFFINITY": "smithing",
	"LOR_AFFINITY": "lore",
}

func has_affinity(skill_name: String) -> bool:
	var house_data: DataManager.HouseData = DataManager.get_house(house_name)
	if not house_data:
		return false
	for affinity_flag in house_data.affinities:
		if AFFINITY_MAP.get(affinity_flag, "") == skill_name:
			return true
	return false

func get_skill_cost(current_level: int, points_to_buy: int = 1, skill_name: String = "") -> int:
	# Cost for nth skill point = 100 × n
	# Affinity discount: -100 per point (Sil-Q standard)
	var discount: int = 100 if not skill_name.is_empty() and has_affinity(skill_name) else 0
	var cost: int = 0
	for i in range(points_to_buy):
		cost += maxi(0, 100 * (current_level + i + 1) - discount)
	return cost

func can_afford_skill(skill_name: String) -> bool:
	if not skills.has(skill_name):
		return false
	var current: int = skills[skill_name]
	if current >= 20:  # Max skill level
		return false
	return xp_available >= get_skill_cost(current, 1, skill_name)

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
		GameManager.log_message("Unknown skill: %s" % skill_name, ThemeColors.MSG_ERROR)
		return false

	var current: int = skills[skill_name]
	if current >= 20:
		GameManager.log_message("%s is already at maximum!" % skill_name.capitalize(), ThemeColors.MSG_ERROR)
		return false

	var cost: int = get_skill_cost(current, 1, skill_name)
	if xp_available < cost:
		GameManager.log_message("Need %d XP to raise %s (have %d)" % [cost, skill_name, xp_available], ThemeColors.MSG_ERROR)
		return false

	# Spend XP and increase skill
	xp_available -= cost
	skills[skill_name] += 1
	xp_spent.emit(cost, skill_name)

	GameManager.log_message("Raised %s to %d (-%d XP)" % [skill_name.capitalize(), skills[skill_name], cost], ThemeColors.ABILITY_LEARNED)
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
		GameManager.log_message("You have learned lore about %s!" % monster_type, ThemeColors.MSG_INFO)

func get_lore_for(monster_type: String) -> Array:
	return lore_known.get(monster_type, [])

func has_lore_for(monster_type: String) -> bool:
	return lore_known.has(monster_type) and not lore_known[monster_type].is_empty()

# ============================================================================
# INVENTORY
# ============================================================================

func pick_up_item(item_data: Variant) -> bool:
	if inventory.size() >= max_inventory:
		GameManager.log_message("Your pack is full!", ThemeColors.MSG_ERROR)
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
# COMBAT MODIFIERS (Phase A: Full Sil-Q modifier stack)
# ============================================================================

## Player attack modifier stack per NECROMANCER_DESIGN_CANON section 1.2
func get_total_attack(target: Entity) -> int:
	var att: int = melee_bonus

	# Rapid Attack penalty: -3 when doing rapid double-attacks
	att += _rapid_attack_penalty

	# Concentration: +MIN(consecutive_attacks, Perception/2) when not moved last turn
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_CONCENTRATION):
		if not moved_last_turn:
			var per_bonus: int = get_skill("perception") / 2
			att += mini(consecutive_attacks, maxi(per_bonus, 1))

	# Focused Attack: +Perception/2 (always active if learned)
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK):
		att += get_skill("perception") / 2

	# Assassination: +Stealth skill vs unwary/sleeping targets
	if has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_ASSASSINATION):
		if is_instance_valid(target) and target is Monster:
			var mon: Monster = target as Monster
			if mon.alertness < Constants.ALERTNESS_ALERT:
				att += get_skill("stealth")

	# Bane: +floor(log2(kills)) for kills >= 2 of that race
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_BANE):
		att += _get_bane_bonus(target)

	# Master Hunter: +MIN(kills_of_type, Perception/2)
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_MASTER_HUNTER):
		att += _get_master_hunter_bonus(target)

	# Flanking: +1 per adjacent ally attacking same target
	att += _count_adjacent_allies_to(target)

	# Charge: +3 when moved straight toward target last action (requires ability)
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_CHARGE):
		if _is_charging_toward(target):
			att += 3

	# Opening Strike: +melee skill on first attack against each monster
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_OPENING_STRIKE):
		if is_instance_valid(target) and not _opening_strike_used.has(target.get_instance_id()):
			att += get_skill("melee")

	# Strength in Adversity: +1 per 10% HP below 50%
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_STR):
		var hp_pct: float = float(current_health) / float(maxi(max_health, 1))
		if hp_pct < 0.5:
			var deficit_pct: int = int((0.5 - hp_pct) * 10.0)  # 0-5
			att += deficit_pct

	# Vengeance (Will): +2 attack on turn after being hit (lasts whole turn)
	if _vengeance_active:
		att += 2

	# Weapon proficiency: +1 if race has proficiency for equipped weapon type
	att += _get_weapon_proficiency_bonus()

	# Blind: halve attack
	if status_fx and status_fx.is_blind():
		att = att / 2

	# Darkness penalty: halve attack if can't see target (no light source)
	if not has_light() and is_instance_valid(target):
		if GameManager.current_level and not GameManager.current_level.is_tile_visible(target.grid_position):
			att = att / 2

	return att

## Player evasion modifier stack per NECROMANCER_DESIGN_CANON section 1.4
func get_total_evasion(attacker: Entity) -> int:
	var evn: int = evasion_bonus

	# Dodging: +3 if moved last turn and has EVN_DODGING
	if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_DODGING):
		if moved_last_turn:
			evn += 3

	# Defensive Stance: +3 evasion when not moved last turn
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_DEFENSIVE_STANCE):
		if not moved_last_turn:
			evn += 3

	# Crowd Fighting: negate -1 evasion penalty per adjacent monster beyond 1
	# (Without this ability, each adjacent monster beyond the first gives -1 evn)
	if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_CROWD_FIGHTING):
		var adjacent_hostiles: int = _count_adjacent_monsters()
		if adjacent_hostiles > 1:
			evn -= (adjacent_hostiles - 1)

	# Parry: +Evasion/4 when wielding a melee weapon (active defense)
	if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_PARRY):
		if equipment.get("weapon") != null:
			evn += get_skill("evasion") / 4

	# Heavy Armour Use: remove heavy armor evasion penalty
	# (The base evasion_bonus already includes armor penalty; this adds back the penalty amount)
	if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_HEAVY_ARMOUR):
		evn += _get_heavy_armor_penalty()

	# Hardiness (Will): +1 protection-equivalent as evasion per 3 Will
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_FORMIDABLE):
		evn += get_skill("will") / 3

	# Bane evasion bonus (same formula as attack bane)
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_BANE):
		evn += _get_bane_bonus(attacker)

	# Blind: halve evasion
	if status_fx and status_fx.is_blind():
		evn = evn / 2

	# Darkness penalty: halve evasion if no light (can't see attacker)
	if not has_light() and is_instance_valid(attacker):
		if GameManager.current_level and not GameManager.current_level.is_tile_visible(attacker.grid_position):
			evn = evn / 2

	return evn

## Player crit threshold modified by abilities per DESIGN_CANON section 1.6
func _get_crit_threshold() -> int:
	var threshold: int = 70
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FINESSE):
		threshold -= 20
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_CONTROL):
		threshold -= 20
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_POWER):
		threshold += 10
	return threshold

## Power ability: extra damage die per hit
func _get_bonus_damage_dice() -> int:
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_POWER):
		return 1
	return 0

## Post-hit ability hooks: Knock Back, Mighty Blow, Follow-Through, Opening Strike tracking
func _on_successful_hit(target: Entity, hit_result: int, damage: int) -> void:
	var was_crit: bool = hit_result > 0  # Any positive hit_result means we may crit
	var crit_threshold: int = _get_crit_threshold()
	var weapon_weight: int = _get_weapon_weight()
	var crit_dice: int = (hit_result * 10 + 4) / (crit_threshold + weapon_weight)
	var is_crit: bool = crit_dice > 0

	# Track Opening Strike usage
	if is_instance_valid(target):
		_opening_strike_used[target.get_instance_id()] = true

	# Throat Slit: instant kill if target unwary and damage >= target current_health / 2
	if has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_THROAT_SLIT):
		if is_instance_valid(target) and target is Monster and target.is_alive:
			var mon: Monster = target as Monster
			if mon.alertness < Constants.ALERTNESS_ALERT:
				if damage >= target.current_health / 2:
					target.current_health = 0
					GameManager.log_message("You slit %s's throat!" % target.entity_name, ThemeColors.COMBAT_CRIT)
					target.die(self)
					return

	# Inner Light: bonus damage vs HURT_LITE enemies equal to Lore/3
	if has_ability(Constants.Skill.S_LOR, Constants.LoreAbility.LOR_INNER_LIGHT):
		if is_instance_valid(target) and target is Monster and target.current_health > 0:
			var mon: Monster = target as Monster
			if mon.monster_data and mon.monster_data.has_flag("HURT_LITE"):
				var light_dmg: int = maxi(1, get_skill("lore") / 3)
				target.take_damage(light_dmg, "light", self)
				GameManager.log_message("Your inner light burns %s! (+%d)" % [target.entity_name, light_dmg], ThemeColors.ABILITY_LEARNED)

	# Knock Back: push target 1 tile away on crit
	if is_crit and has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_KNOCK_BACK):
		_try_knock_back(target)

	# Mighty Blow: +STR/2 extra damage on crit (applied as direct damage)
	if is_crit and has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_MIGHTY_BLOW):
		var mighty_dmg: int = maxi(1, strength / 2)
		if is_instance_valid(target) and target.current_health > 0:
			target.take_damage(mighty_dmg, "physical", self)
			GameManager.log_message("Mighty blow! (+%d)" % mighty_dmg, ThemeColors.COMBAT_CRIT)

	# Follow-Through: if target died, free attack on adjacent enemy
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FOLLOW_THROUGH):
		if is_instance_valid(target) and target.current_health <= 0:
			_try_follow_through(target.grid_position)

func _try_knock_back(target: Entity) -> void:
	if not is_instance_valid(target) or not GameManager.current_level:
		return
	var push_dir: Vector2i = target.grid_position - grid_position
	# Normalize to unit direction
	push_dir = Vector2i(signi(push_dir.x), signi(push_dir.y))
	var dest: Vector2i = target.grid_position + push_dir
	if GameManager.current_level.is_in_bounds(dest) and GameManager.current_level.is_passable(dest) and GameManager.current_level.get_entity_at(dest) == null:
		target.move_to(dest, false)
		GameManager.log_message("You knock %s back!" % target.entity_name, ThemeColors.MSG_WARNING)

func _try_follow_through(dead_pos: Vector2i) -> void:
	if _in_follow_through:
		return
	if not GameManager.current_level:
		return
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	for dir in directions:
		var check_pos: Vector2i = dead_pos + dir
		if check_pos == grid_position:
			continue
		var adj_entity: Entity = GameManager.current_level.get_entity_at(check_pos)
		if adj_entity != null and is_instance_valid(adj_entity) and adj_entity is Monster:
			# Check adjacency to player (must be within 1 tile)
			var dist_to_player: Vector2i = check_pos - grid_position
			if absi(dist_to_player.x) <= 1 and absi(dist_to_player.y) <= 1:
				GameManager.log_message("Follow-through!", ThemeColors.MSG_WARNING)
				_in_follow_through = true
				attack_entity(adj_entity)
				_in_follow_through = false
				return  # Only one follow-through attack

## Use equipped weapon damage dice for attacks
func _get_attack_damage_dice() -> String:
	return get_weapon_damage_dice()

## Ranged damage from equipped bow/sling
func _get_ranged_damage_dice() -> String:
	var ranged_weapon = equipment.get("off_hand")
	if ranged_weapon != null and "tval" in ranged_weapon:
		if ranged_weapon.tval == 19 or ranged_weapon.tval == 18:  # TV_BOW or TV_SLING
			if "damage_dice" in ranged_weapon and ranged_weapon.damage_dice != "":
				return ranged_weapon.damage_dice
	return "1d5"  # Default projectile damage

## Count monsters adjacent to player (for Crowd Fighting penalty)
func _count_adjacent_monsters() -> int:
	if not GameManager.current_level:
		return 0
	var count: int = 0
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	for dir in directions:
		var ent: Entity = GameManager.current_level.get_entity_at(grid_position + dir)
		if ent != null and is_instance_valid(ent) and ent is Monster:
			count += 1
	return count

## Get the evasion penalty from heavy armor (to be removed by Heavy Armour Use)
func _get_heavy_armor_penalty() -> int:
	var penalty: int = 0
	var armor = equipment.get("armor")
	if armor != null and "weight" in armor:
		# Heavy armor (weight >= 150) penalizes evasion by weight/50
		if armor.weight >= 150:
			penalty += armor.weight / 50
	return penalty

## Ranged weapon weight for crit/STR calculations
func _get_bow_weight() -> int:
	var ranged_weapon = equipment.get("off_hand")
	if ranged_weapon != null and "weight" in ranged_weapon:
		return ranged_weapon.weight
	return 30

## Override ranged attack to use archery skill instead of melee
func ranged_attack(target: Entity, distance: int) -> void:
	# Archery-based attack: archery skill + DEX/2 + proficiency
	var att: int = skills["archery"] + (dexterity / 2)
	# Weapon proficiency bonus (BOW_PROFICIENCY or SLING_PROFICIENCY)
	att += _get_ranged_proficiency_bonus()
	# Keen Eyes: +Perception/2 to ranged attack
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_KEEN_EYES):
		att += get_skill("perception") / 2
	# Ambush: +Stealth to ranged attack vs unwary targets
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_AMBUSH):
		if is_instance_valid(target) and target is Monster:
			var mon: Monster = target as Monster
			if mon.alertness < Constants.ALERTNESS_ALERT:
				att += get_skill("stealth")
	# Point Blank: +archery/2 at range 1 (melee range)
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_POINT_BLANK):
		if distance <= 1:
			att += get_skill("archery") / 2
	# Distance penalty: -1 per tile beyond 1
	att -= maxi(0, distance - 1)

	# Ranged evasion is halved
	var evn: int = target.get_total_evasion(self) / 2

	var attack_score: int = randi_range(1, 20) + att
	var evasion_score: int = randi_range(1, 20) + evn

	var hit_result: int = attack_score - evasion_score

	if hit_result < 0:
		EventBus.attack_missed.emit(self, target)
		GameManager.log_message("Your shot misses %s (%d vs %d)" % [
			target.entity_name, attack_score, evasion_score
		], ThemeColors.COMBAT_MISS)
		return

	# Damage from projectile
	var dmg_dice: String = _get_ranged_damage_dice()
	var damage: int = DataManager.roll_dice(dmg_dice)

	# STR bonus (capped by weapon weight)
	var bow_weight: int = _get_bow_weight()
	var str_bonus: int = strength / 2
	var weight_cap: int = bow_weight / 10
	damage += mini(str_bonus, weight_cap)

	# Critical hit
	var crit_threshold: int = _get_crit_threshold()
	var crit_dice: int = (hit_result * 10 + 4) / (crit_threshold + bow_weight)
	crit_dice = _apply_crit_resistance(target, crit_dice)

	var crit_damage: int = 0
	for i in range(crit_dice):
		crit_damage += DataManager.roll_dice(dmg_dice)
	damage += crit_damage

	if crit_dice > 0:
		GameManager.log_message("You CRIT %s! (%d vs %d, +%d dice = %d dmg)" % [
			target.entity_name, attack_score, evasion_score, crit_dice, damage
		], ThemeColors.COMBAT_CRIT)
	else:
		GameManager.log_message("You hit %s with a shot (%d vs %d = %d dmg)" % [
			target.entity_name, attack_score, evasion_score, damage
		], ThemeColors.COMBAT_HIT)

	# Puncture: ignore 1 point of protection per archery skill point
	# (Applied as bonus damage since we can't modify protection here)
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_PUNCTURE):
		damage += get_skill("archery") / 3

	target.take_damage(damage, "physical", self)

	# Crippling Shot: apply slow on ranged crit
	if crit_dice > 0 and has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_CRIPPLING_SHOT):
		if is_instance_valid(target) and target.is_alive:
			target.apply_status("slow", 3 + randi_range(1, 3))
			GameManager.log_message("Your shot cripples %s!" % target.entity_name, ThemeColors.COMBAT_CRIT)

	# Rout: fleeing enemies take extra damage from ranged attacks
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_ROUT):
		if is_instance_valid(target) and target.is_alive and target is Monster:
			var mon: Monster = target as Monster
			if mon.morale < 0:
				var rout_dmg: int = maxi(1, get_skill("archery") / 3)
				target.take_damage(rout_dmg, "physical", self)
				GameManager.log_message("Routing shot! (+%d)" % rout_dmg, ThemeColors.COMBAT_HIT)

## Get proficiency bonus for equipped ranged weapon
func _get_ranged_proficiency_bonus() -> int:
	var ranged_weapon = equipment.get("off_hand")
	if ranged_weapon == null or not "tval" in ranged_weapon:
		return 0
	var race_data: DataManager.RaceData = DataManager.get_race(race_name)
	if not race_data:
		return 0
	match ranged_weapon.tval:
		19:  # TV_BOW
			if "BOW_PROFICIENCY" in race_data.flags:
				return 1
		18:  # TV_SLING
			if "SLING_PROFICIENCY" in race_data.flags:
				return 1
	# ARC_PENALTY flag (Dwarves): -1 to all ranged
	if "ARC_PENALTY" in race_data.flags:
		return -1
	return 0

## Check if player can fire (has bow+arrows or sling+stones)
func can_fire_ranged() -> bool:
	var ranged_weapon = equipment.get("off_hand")
	if ranged_weapon == null or not "tval" in ranged_weapon:
		return false
	var weapon_tval: int = ranged_weapon.tval
	var ammo_tval: int = -1
	if weapon_tval == 19:  # TV_BOW
		ammo_tval = 17  # TV_ARROW
	elif weapon_tval == 18:  # TV_SLING
		ammo_tval = 16  # TV_SLING_STONE
	else:
		return false
	# Check quiver for ammo
	var quiver = equipment.get("quiver") if equipment.has("quiver") else null
	if quiver != null and "tval" in quiver and quiver.tval == ammo_tval:
		return true
	# Check inventory for ammo
	for item in inventory:
		if item != null and "tval" in item and item.tval == ammo_tval:
			return true
	return false

## Consume one ammo (arrow/stone) from quiver/inventory. Returns true if available.
func consume_arrow() -> bool:
	# Determine ammo type from equipped ranged weapon
	var ranged_weapon = equipment.get("off_hand")
	var ammo_tval: int = 17  # Default to arrows
	var empty_msg: String = "Your quiver is empty!"
	if ranged_weapon != null and "tval" in ranged_weapon and ranged_weapon.tval == 18:
		ammo_tval = 16  # Sling stones
		empty_msg = "You have no more stones!"
	# Check quiver first
	if equipment.has("quiver"):
		var quiver = equipment.get("quiver")
		if quiver != null and "tval" in quiver and quiver.tval == ammo_tval:
			if "pval" in quiver:
				quiver.pval -= 1
				if quiver.pval <= 0:
					equipment["quiver"] = null
					GameManager.log_message(empty_msg, ThemeColors.MSG_WARNING)
				return true
	# Check inventory
	for i in range(inventory.size()):
		var item = inventory[i]
		if item != null and "tval" in item and item.tval == ammo_tval:
			if "pval" in item:
				item.pval -= 1
				if item.pval <= 0:
					inventory.remove_at(i)
			else:
				inventory.remove_at(i)
			return true
	return false

## Bane bonus: floor(log2(kills)) for kills >= 2 of target's race
func _get_bane_bonus(target: Entity) -> int:
	if not is_instance_valid(target) or not target is Monster:
		return 0
	var mon_name: String = target.entity_name
	var kill_count: int = kills_by_name.get(mon_name, 0)
	if kill_count < 2:
		return 0
	# +floor(log2(kills)) for 2+ kills
	return int(log(kill_count) / log(2.0))

## Master Hunter: +MIN(kills_of_type, Perception/2)
func _get_master_hunter_bonus(target: Entity) -> int:
	if not is_instance_valid(target) or not target is Monster:
		return 0
	var mon_name: String = target.entity_name
	var kill_count: int = kills_by_name.get(mon_name, 0)
	if kill_count < 1:
		return 0
	var per_cap: int = maxi(1, get_skill("perception") / 2)
	return mini(kill_count, per_cap)

## Count adjacent allies attacking the same target (for flanking/overwhelming)
func _count_adjacent_allies_to(target: Entity) -> int:
	if not is_instance_valid(target) or not GameManager.current_level:
		return 0
	var count: int = 0
	# Check for player adjacency to target
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	for dir in directions:
		var check_pos: Vector2i = target.grid_position + dir
		if check_pos == grid_position:
			continue  # Don't count self
		var ent: Entity = GameManager.current_level.get_entity_at(check_pos)
		if ent != null and is_instance_valid(ent) and ent is Monster:
			# Check if this monster is an ally (summoned/charmed)
			var mon: Monster = ent as Monster
			if mon.ai_state == Monster.AIState.FLEEING:
				continue  # Fleeing monsters don't help
			# For now, no allied monsters exist, but this is ready for summoning
	return count

## Weapon proficiency: +1 if race has the proficiency flag for equipped weapon tval
## Check if player's race has a specific racial flag
func has_racial_flag(flag_name: String) -> bool:
	var race_data: DataManager.RaceData = DataManager.get_race(race_name)
	if not race_data:
		return false
	return flag_name in race_data.flags

func _get_weapon_proficiency_bonus() -> int:
	var weapon = equipment.get("weapon")
	if weapon == null or not "tval" in weapon:
		return 0
	var race_data: DataManager.RaceData = DataManager.get_race(race_name)
	if not race_data:
		return 0
	var weapon_tval: int = weapon.tval
	# Map weapon tval to required proficiency flag
	var required_flag: String = ""
	match weapon_tval:
		23:  # TV_SWORD
			required_flag = "SWORD_PROFICIENCY"
		22:  # TV_POLEARM (axes)
			required_flag = "AXE_PROFICIENCY"
		19:  # TV_BOW
			required_flag = "BOW_PROFICIENCY"
		18:  # TV_SLING
			required_flag = "SLING_PROFICIENCY"
	if required_flag != "" and required_flag in race_data.flags:
		return 1
	# SMALL_STATURE: -2 melee with non-proficiency weapons (not unarmed)
	if has_racial_flag("SMALL_STATURE") and weapon_tval in [21, 22, 23]:
		# Check if they DON'T have proficiency for this weapon
		var prof_flag: String = ""
		match weapon_tval:
			23: prof_flag = "SWORD_PROFICIENCY"
			22: prof_flag = "AXE_PROFICIENCY"
			21: prof_flag = "HAMMER_PROFICIENCY"
		if prof_flag == "" or prof_flag not in race_data.flags:
			return -2
	return 0

## Check if player is charging (moved straight toward target last action)
func _is_charging_toward(target: Entity) -> bool:
	if not is_instance_valid(target):
		return false
	if previous_action.is_empty():
		return false
	var last_act: int = previous_action[0]
	if last_act < Constants.ACTION_MOVE_N or last_act > Constants.ACTION_MOVE_NW:
		return false
	# Check if last move direction points toward target
	var dir_to_target: Vector2i = Vector2i(
		sign(target.grid_position.x - grid_position.x),
		sign(target.grid_position.y - grid_position.y)
	)
	var move_dir: Vector2i = _action_to_direction(last_act)
	return move_dir == dir_to_target

func _action_to_direction(action: int) -> Vector2i:
	match action:
		Constants.ACTION_MOVE_N: return Vector2i(0, -1)
		Constants.ACTION_MOVE_NE: return Vector2i(1, -1)
		Constants.ACTION_MOVE_E: return Vector2i(1, 0)
		Constants.ACTION_MOVE_SE: return Vector2i(1, 1)
		Constants.ACTION_MOVE_S: return Vector2i(0, 1)
		Constants.ACTION_MOVE_SW: return Vector2i(-1, 1)
		Constants.ACTION_MOVE_W: return Vector2i(-1, 0)
		Constants.ACTION_MOVE_NW: return Vector2i(-1, -1)
	return Vector2i.ZERO

# ============================================================================
# STEALTH SYSTEM (Phase B)
# ============================================================================

## Get current stealth score for this turn (canon section 2.2)
func get_stealth_score() -> int:
	var score: int = get_skill("stealth")
	# Stealth mode bonus
	if stealth_mode:
		score += Constants.STEALTH_MODE_BONUS
	# SMALL_STATURE: +2 stealth (enemies overlook small folk)
	if has_racial_flag("SMALL_STATURE"):
		score += 2
	# Disguise: +Stealth/3 bonus to stealth
	if has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_DISGUISE):
		score += get_skill("stealth") / 3
	# Fade bonus (temporary boost after kill)
	score += _fade_bonus
	# Noise penalty
	score -= noise_this_turn
	return score

## Get combat noise bonus for monster perception (canon section 2.4)
func get_combat_noise() -> int:
	var noise: int = 0
	if attacked_this_turn:
		noise += 2
	if was_attacked_this_turn:
		noise += 2
	return noise

## Add noise from a specific action
func add_noise(amount: int) -> void:
	noise_this_turn += amount
	# Also raise floor alertness
	if GameManager.current_level and GameManager.current_level.has_method("add_floor_noise"):
		GameManager.current_level.add_floor_noise(amount)

## Toggle stealth mode
func toggle_stealth_mode() -> void:
	stealth_mode = not stealth_mode
	if stealth_mode:
		GameManager.log_message("You enter stealth mode.", ThemeColors.MSG_STEALTH)
	else:
		GameManager.log_message("You leave stealth mode.", ThemeColors.MSG_SYSTEM)

# ============================================================================
# LIGHT SYSTEM (Phase C)
# ============================================================================

## Get player's effective light radius from equipped light source
func get_light_radius() -> int:
	# BLIND: Can only see self tile
	if status_fx and status_fx.is_blind():
		return 1

	var base_radius: int = 1  # Can see adjacent tiles even without a light
	var light_item = equipment.get("light")
	if light_item != null and "tval" in light_item:
		# Check fuel remaining (if applicable)
		if "fuel" in light_item and light_item.fuel <= 0:
			return base_radius  # Light source exhausted

		# Map light source sval to radius
		var sval: int = light_item.sval if "sval" in light_item else 0
		match sval:
			0:  # Wooden Torch
				base_radius += 2
			1:  # Brass Lantern
				base_radius += 3
			8:  # Feanorian Lamp
				base_radius += 4
			_:  # Unknown light source
				base_radius += 2

	# Keen Senses: +1 light radius (see slightly beyond light pool)
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_KEEN_SENSES):
		base_radius += 1

	# Inner Light ability: +1 per 5 Lore skill
	if has_ability(Constants.Skill.S_LOR, Constants.LoreAbility.LOR_INNER_LIGHT):
		base_radius += get_skill("lore") / 5

	# DARKENED: Reduce light radius by 2 (minimum 1)
	if status_fx and status_fx.has_effect(Constants.EFFECT_DARKENED):
		base_radius = maxi(1, base_radius - 2)

	# BURNING: Ironically gives +1 light (you're on fire)
	if status_fx and status_fx.has_effect(Constants.EFFECT_BURNING):
		base_radius += 1

	return base_radius

## Tick fuel consumption for equipped light source (called each round)
func tick_light_fuel() -> void:
	var light_item = equipment.get("light")
	if light_item == null or not "fuel" in light_item:
		return
	# Feanorian Lamp doesn't consume fuel
	if "sval" in light_item and light_item.sval == 8:
		return
	if light_item.fuel > 0:
		light_item.fuel -= 1
		if light_item.fuel == 0:
			GameManager.log_message("Your light source goes out!", ThemeColors.MSG_ERROR)
		elif light_item.fuel <= 100:
			GameManager.log_message("Your light source is flickering...", ThemeColors.MSG_WARNING)

## Check if player has an active (fueled) light source
func has_light() -> bool:
	var light_item = equipment.get("light")
	if light_item == null:
		return false
	if "fuel" in light_item and light_item.fuel <= 0:
		return false
	return true

# ============================================================================
# INPUT HANDLING
# ============================================================================

func handle_input() -> bool:
	if _skip_input_this_frame:
		_skip_input_this_frame = false
		return false
	if not GameManager.is_player_turn:
		return false

	# STUNNED/ENTRANCED: Cannot act at all - skip turn
	if not can_take_turn():
		GameManager.log_message("You are unable to act!", ThemeColors.MSG_ERROR)
		return true  # Consume turn

	# CONFUSED: 50% chance of random movement instead of intended
	if status_fx and status_fx.is_confused():
		var direction := _get_movement_input()
		if direction != Vector2i.ZERO or Input.is_action_just_pressed("wait"):
			if randf() < 0.5:
				# Random direction
				var random_dirs: Array[Vector2i] = [
					Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
					Vector2i(-1, 0), Vector2i(1, 0),
					Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
				]
				random_dirs.shuffle()
				GameManager.log_message("You stumble about in confusion!", ThemeColors.STATUS_CONFUSED)
				for rdir: Vector2i in random_dirs:
					if can_move_to(grid_position + rdir):
						moved_this_turn = true
						return try_move(rdir)
				return true  # Couldn't move anywhere, turn consumed
			# 50% chance: normal action falls through

	# AFRAID: Force movement away from nearest visible enemy
	if status_fx and status_fx.is_afraid():
		var direction := _get_movement_input()
		if direction != Vector2i.ZERO:
			var flee_dir: Vector2i = _get_flee_direction()
			if flee_dir != Vector2i.ZERO:
				GameManager.log_message("Terror drives you to flee!", ThemeColors.STATUS_AFRAID)
				moved_this_turn = true
				return try_move(flee_dir)
			# No flee direction available, allow normal movement

	var direction := _get_movement_input()
	if direction != Vector2i.ZERO:
		moved_this_turn = true
		return try_move(direction)

	if Input.is_action_just_pressed("wait"):
		return true  # Skip turn

	if Input.is_action_just_pressed("pickup"):
		return try_pickup()

	# Stealth mode toggle (';' key)
	if Input.is_action_just_pressed("toggle_stealth"):
		toggle_stealth_mode()
		return false  # Toggling stealth doesn't cost a turn

	# Quaff potion (Q key)
	if Input.is_action_just_pressed("quaff"):
		return _use_first_consumable(75)

	# Eat food/herb (comma key)
	if Input.is_action_just_pressed("eat"):
		return _use_first_consumable(80)

	# Close door (C key)
	if Input.is_action_just_pressed("close_door"):
		return _try_close_door()

	# Search for secret doors (Shift+S)
	if Input.is_action_just_pressed("search"):
		return _try_search()

	return false

## Use the first consumable of a given tval from inventory
func _use_first_consumable(target_tval: int) -> bool:
	for i in range(inventory.size()):
		var item = inventory[i]
		if item != null and "tval" in item and item.tval == target_tval:
			if ConsumableSystem.use_item(self, item):
				inventory.remove_at(i)
				return true  # Turn consumed
			return false  # Couldn't use (e.g., blind reading)
	var type_name: String = "potion" if target_tval == 75 else "food"
	GameManager.log_message("You have no %s to use." % type_name, ThemeColors.MSG_SYSTEM)
	return false

## Get direction away from nearest visible enemy (for AFRAID status).
func _get_flee_direction() -> Vector2i:
	if not GameManager.current_level:
		return Vector2i.ZERO
	var nearest_dist: int = 999
	var nearest_pos: Vector2i = Vector2i.ZERO
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		if not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			continue
		var dist: int = max(abs(entity.grid_position.x - grid_position.x),
						abs(entity.grid_position.y - grid_position.y))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_pos = entity.grid_position
	if nearest_dist == 999:
		return Vector2i.ZERO
	# Move away from nearest enemy
	var away: Vector2i = Vector2i(
		sign(grid_position.x - nearest_pos.x),
		sign(grid_position.y - nearest_pos.y)
	)
	if can_move_to(grid_position + away):
		return away
	# Try adjacent directions
	var alt_dirs: Array[Vector2i] = [
		Vector2i(away.x, 0), Vector2i(0, away.y),
		Vector2i(-away.x, away.y), Vector2i(away.x, -away.y)
	]
	for alt: Vector2i in alt_dirs:
		if alt != Vector2i.ZERO and can_move_to(grid_position + alt):
			return alt
	return Vector2i.ZERO

## Close an adjacent open door. Returns true if turn consumed.
func _try_close_door() -> bool:
	if not GameManager.current_level:
		return false

	# Check all 8 adjacent tiles for open doors
	var open_doors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	for dir: Vector2i in directions:
		var check_pos: Vector2i = grid_position + dir
		if GameManager.current_level.get_tile(check_pos) == Level.Tile.DOOR_OPEN:
			open_doors.append(check_pos)

	if open_doors.is_empty():
		GameManager.log_message("There is no open door nearby to close.", ThemeColors.MSG_SYSTEM)
		return false

	# Close the first open door found (if only one, auto-close)
	var door_pos: Vector2i = open_doors[0]
	if GameManager.current_level.close_door(door_pos):
		GameManager.log_message("You close the door.", ThemeColors.TEXT_PRIMARY)
		add_noise(Constants.NOISE_DOOR)
		return true
	else:
		GameManager.log_message("Something is blocking the door.", ThemeColors.MSG_WARNING)
		return false

## Search adjacent tiles for secret doors. Returns true (always costs a turn).
func _try_search() -> bool:
	if not GameManager.current_level:
		return false

	var per: int = get_skill("perception")
	var found: int = GameManager.current_level.search_for_secrets(grid_position, per)
	if found > 0:
		GameManager.log_message("You discover a hidden passage!", ThemeColors.ABILITY_LEARNED)
	else:
		GameManager.log_message("You search the area but find nothing.", ThemeColors.MSG_SYSTEM)
	return true  # Searching always costs a turn

func try_pickup() -> bool:
	if not GameManager.current_level:
		return false

	var items_here: Array[Item] = GameManager.current_level.get_items_at(grid_position)
	if items_here.is_empty():
		GameManager.log_message("There is nothing here to pick up.", ThemeColors.MSG_SYSTEM)
		return false

	# Pick up the first item
	var item: Item = items_here[0]
	var item_data = item.get_data()

	if pick_up_item(item_data):
		GameManager.current_level.remove_item(item)
		item.queue_free()
		GameManager.log_message("You pick up the %s." % item.get_display_name(), ThemeColors.MSG_LOOT)
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
				GameManager.log_message("You open the door.", ThemeColors.TEXT_PRIMARY)
				add_noise(Constants.NOISE_DOOR)
				return false  # Opening door takes a turn but doesn't move
			# Locked doors
			if tile == Level.Tile.DOOR_LOCKED:
				GameManager.log_message("The door is locked.", ThemeColors.MSG_WARNING)
				# Try to bash it
				if GameManager.current_level.bash_door(target, strength):
					GameManager.log_message("You force the door open!", ThemeColors.ABILITY_LEARNED)
					add_noise(Constants.NOISE_BASH)
				else:
					GameManager.log_message("You fail to force it open.", ThemeColors.MSG_SYSTEM)
					add_noise(Constants.NOISE_DOOR)
				return false
			# Jammed doors
			if tile == Level.Tile.DOOR_JAMMED:
				GameManager.log_message("The door is stuck.", ThemeColors.MSG_WARNING)
				if GameManager.current_level.bash_door(target, strength):
					GameManager.log_message("You wrench the door open!", ThemeColors.ABILITY_LEARNED)
					add_noise(Constants.NOISE_BASH)
				else:
					GameManager.log_message("It won't budge.", ThemeColors.MSG_SYSTEM)
					add_noise(Constants.NOISE_DOOR)
				return false
			return false

	# Check for blocking entities
	if GameManager.current_level.has_method("get_entity_at"):
		var blocker = GameManager.current_level.get_entity_at(target)
		if is_instance_valid(blocker) and blocker != self:
			# Bump attack if it's a monster
			if blocker is Monster:
				attacked_this_turn = true
				# Rapid Attack: two attacks at -3 each
				if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_RAPID_ATTACK):
					_rapid_attack_penalty = -3
					attack_entity(blocker)
					if is_instance_valid(blocker) and blocker.is_alive:
						attack_entity(blocker)
					_rapid_attack_penalty = 0
				else:
					attack_entity(blocker)
				return false
			# Talk to NPC if bumped (use duck typing to avoid cyclic dependency)
			if blocker.has_method("start_dialogue"):
				_interact_with_npc(blocker)
				return false
			return false

	return true

func _interact_with_npc(npc: Entity) -> void:
	"""Initiate dialogue with an NPC (uses Entity type to avoid cyclic dependency)."""
	if not is_instance_valid(npc):
		return
	if npc.get("dialogue_complete"):
		GameManager.log_message("%s has nothing more to say." % npc.entity_name, ThemeColors.MSG_SYSTEM)
		return

	# Emit event for UI to handle
	EventBus.npc_interacted.emit(self, npc)

func apply_status(status_name: String, duration: int, data: Variant = null) -> void:
	var reduced_dur: int = duration

	# DWARVEN_RESILIENCE: halve fear, confusion, and entranced durations
	if has_racial_flag("DWARVEN_RESILIENCE"):
		if status_name == "afraid" or status_name == "confused" or status_name == "entranced":
			reduced_dur = maxi(1, duration / 2)

	# Indomitable (Will): halve stun and slow durations
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_INDOMITABLE):
		if status_name == "stunned" or status_name == "slow":
			reduced_dur = maxi(1, duration / 2)

	# Poison Resistance (Will): halve poison duration
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_POISON_RESIST):
		if status_name == "poisoned":
			reduced_dur = maxi(1, duration / 2)

	# Majesty (Will): immune to fear
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_MAJESTY):
		if status_name == "afraid":
			GameManager.log_message("Your majesty overcomes the fear!", ThemeColors.PRIMARY)
			return

	super.apply_status(status_name, reduced_dur, data)

func take_damage(amount: int, damage_type: String = "physical", source: Entity = null) -> void:
	was_attacked_this_turn = true

	# Vengeance: track that we were hit for +2 attack next turn
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_VENGEANCE):
		_vengeance_active = true

	# HOBBIT_LUCK: reroll lethal damage once per floor (halves incoming damage)
	if current_health > 0 and current_health - amount <= 0:
		if has_racial_flag("HOBBIT_LUCK") and not _hobbit_luck_used:
			_hobbit_luck_used = true
			# Reroll: halve the damage (fortune favors hobbits)
			var new_amount: int = maxi(1, amount / 2)
			if current_health - new_amount > 0:
				GameManager.log_message("Fortune favors you! The blow glances off!", ThemeColors.PRIMARY)
				amount = new_amount

	# Undying Resolve trait: survive lethal damage once per run at 50% HP
	if current_health > 0 and current_health - amount <= 0:
		if try_undying_resolve():
			EventBus.entity_damaged.emit(self, amount, damage_type, source)
			_flash_damage()
			return

	# Defy Death: chance to survive lethal hit at 1 HP (Will*3% chance)
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_DEFY_DEATH):
		if current_health > 0 and current_health - amount <= 0:
			var save_chance: int = get_skill("will") * 3
			if randi_range(1, 100) <= save_chance:
				# Survive at exactly 1 HP (set directly to bypass armor reduction)
				current_health = 1
				GameManager.log_message("You defy death!", ThemeColors.PRIMARY)
				EventBus.entity_damaged.emit(self, amount - 1, damage_type, source)
				_flash_damage()
				return

	# God Mode (Hades-style protective blessing)
	var god_reduction: float = AccessibilityManager.get_god_mode_reduction()
	if god_reduction > 0.0:
		amount = maxi(1, int(amount * (1.0 - god_reduction)))

	super.take_damage(amount, damage_type, source)

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

	if is_instance_valid(killer):
		killer_name = killer.entity_name
		cause = killer_name
		if killer is Monster and killer.monster_data:
			killer_id = killer.monster_data.id if "id" in killer.monster_data else -1

	run_stats.record_death(cause, killer_name, killer_id)

	# Log death
	GameManager.log_message("You have been slain by %s!" % cause, ThemeColors.MSG_ERROR)

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
