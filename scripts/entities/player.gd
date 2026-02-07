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
var gender: String = "male"      # "male" or "female"
var age: int = 0                 # Character age in years
var history: String = ""         # Parentage/background flavor text

# Trait state tracking
var _trait_fortune_used: bool = false   # Fortune's Favor: once per floor
var _trait_undying_used: bool = false    # Undying Resolve: once per run
var _trait_shadow_step_used: bool = false # Shadow Step: once per floor

# Steady Aim: bonus when stationary
var _steady_aim_ready: bool = false

# Oath of Enmity: locked target type
var _oath_target_type: String = ""

# Nimble Striker: hit-and-run bonuses
var _nimble_evn_bonus: int = 0
var _nimble_free_move: bool = false

# Whisper of the Valar: reveal monsters
var _whisper_used: bool = false
var _whisper_turns: int = 0
var _whisper_revealed: Array = []

# Patient Stalker: ambush buildup
var _stalker_turns: int = 0
var _stalker_double_ready: bool = false

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
var voice_charges: int = 20  # For song/voice abilities (starts full)
var max_voice: int = 20

# Ability hotkeys (4 slots for quick-cast via 1-4 keys, -1 = empty)
var ability_hotkeys: Array[int] = [-1, -1, -1, -1]
var _voice_regen_accumulator: float = 0.0  # Fractional regen tracking

# Hunger system - soft pressure mechanic
var hunger: int = 2000  # Current hunger (counts down per turn)
const HUNGER_MAX: int = 2000       # Well-fed (starting value)
const HUNGER_NORMAL: int = 1500    # Normal - no effects
const HUNGER_HUNGRY: int = 800     # Getting hungry - stat penalty starts
const HUNGER_FAMISHED: int = 400   # Serious - bigger penalties, no regen
const HUNGER_STARVING: int = 100   # Critical - HP loss
var _starving_turns: int = 0       # Turns spent at 0 hunger (for death timer)
var _last_hunger_state: String = "well_fed"  # Track state transitions for messages

# Equipment slots
var equipment: Dictionary = {
	"weapon": null,
	"off_hand": null,
	"bow": null,
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

# Equipment flags applied from equipped items (recalculated each stat update)
var equip_flags: Dictionary = {}

# Skill bonuses from equipment flags
var equip_skill_bonuses: Dictionary = {
	"perception": 0,
	"will": 0,
	"stealth": 0,
	"melee": 0,
	"archery": 0,
	"evasion": 0,
	"smithing": 0,
	"lore": 0,
}

# Equipment stat bonuses (recalculated fresh each _recalculate_stats call)
var _equip_str_bonus: int = 0
var _equip_dex_bonus: int = 0
var _equip_con_bonus: int = 0
var _equip_gra_bonus: int = 0

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
			# VFX: restore sprite opacity
			if sprite:
				var reappear_tween := create_tween()
				reappear_tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
			GameManager.log_message("You become visible again.", ThemeColors.MSG_SYSTEM)

	# Steady Aim: ready when standing still with no attacks
	if trait_effect_id == "steady_aim":
		if not moved_this_turn and attacks_this_turn == 0:
			_steady_aim_ready = true
		if moved_this_turn:
			_steady_aim_ready = false

	# Nimble Striker: reset per-turn bonuses
	_nimble_evn_bonus = 0
	_nimble_free_move = false

	# Whisper of the Valar: tick down reveal duration
	if _whisper_turns > 0:
		_whisper_turns -= 1
		if _whisper_turns <= 0:
			_whisper_revealed.clear()

	# Patient Stalker: build up ambush turns while stealthing undetected
	if trait_effect_id == "patient_stalker":
		if stealth_mode and not _any_adjacent_alert_enemy():
			_stalker_turns += 1
			if _stalker_turns >= 3:
				_stalker_double_ready = true
		else:
			_stalker_turns = 0
			_stalker_double_ready = false

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
	# VFX: bright steel flash on self + floater
	vfx_flash(ThemeColors.FLASH_RIPOSTE, 0.04, 0.12)
	vfx_floater("Riposte!", ThemeColors.SECONDARY, 16)
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
	# VFX: green speed flash + particles + floater
	vfx_flash(ThemeColors.FLASH_SPRINT, 0.05, 0.15)
	vfx_particles(ThemeColors.ABILITY_LEARNED, 4, 20.0, 0.3)
	vfx_floater("Sprint!", ThemeColors.ABILITY_LEARNED, 16)
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
	# VFX: fade sprite to semi-transparent + dark smoke particles + floater
	vfx_flash(ThemeColors.FLASH_VANISH, 0.06, 0.2)
	vfx_particles(ThemeColors.BG_RAISED, 6, 20.0, 0.5)
	vfx_floater("Vanish!", ThemeColors.SKILL_STEALTH, 16)
	if sprite:
		var vanish_tween := create_tween()
		vanish_tween.tween_property(sprite, "modulate:a", 0.35, 0.25).set_ease(Tween.EASE_IN)
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
	# V2: Look up sprite by race + house + gender
	var house_data: DataManager.HouseData = DataManager.get_house(house_name)
	if house_data:
		set_sprite_from_player_v2(race_name, house_data.index, "male")
		return
	# Legacy fallback: race only
	var race_to_sprite: Dictionary[String, int] = {
		"Noldor": 0, "Sindar": 0, "Elf": 0,
		"Man": 1, "Dwarf": 2, "Istari": 3, "Hobbit": 4,
	}
	var race_sprite_id: int = race_to_sprite.get(race_name, 1)
	set_sprite_from_player_id(race_sprite_id)

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
		"echoes_firstborn":
			# Reduce speed by 1 tier (slower but more graceful)
			speed = maxi(1, speed - 1)

	GameManager.log_message("Trait: %s" % trait_name, ThemeColors.PRIMARY)

func reset_per_floor_traits() -> void:
	## Called when entering a new floor to reset per-floor trait/racial abilities.
	_trait_fortune_used = false
	_trait_shadow_step_used = false
	_hobbit_luck_used = false

	# Oath of Enmity: clear oath target on new floor
	_oath_target_type = ""

	# Whisper of the Valar: reset per-floor
	_whisper_used = false
	_whisper_turns = 0
	_whisper_revealed.clear()

	# Echoes of the Firstborn: gain 2 voice charges on floor entry
	if trait_effect_id == "echoes_firstborn":
		voice_charges = mini(voice_charges + 2, max_voice)

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

## Steady Aim: UI helper to show when aim bonus is ready
func has_steady_aim_bonus() -> bool:
	return trait_effect_id == "steady_aim" and _steady_aim_ready

## Oath of Enmity: attack bonus/penalty based on oath target
func get_oath_bonus(target: Entity) -> int:
	if trait_effect_id != "oath_of_enmity":
		return 0
	if _oath_target_type.is_empty():
		return 0  # Oath not yet set
	if not is_instance_valid(target) or not target is Monster:
		return 0
	var mon: Monster = target as Monster
	if mon.entity_name == _oath_target_type:
		return 2
	return -1  # Penalty vs non-oath targets

## Whisper of the Valar: activate to reveal nearby monsters for 5 turns
func activate_whisper_of_valar() -> bool:
	if trait_effect_id != "whisper_of_valar":
		return false
	if _whisper_used:
		GameManager.log_message("The Valar have already spoken this floor.", ThemeColors.MSG_SYSTEM)
		return false
	if voice_charges < 3:
		GameManager.log_message("Not enough voice charges (need 3, have %d)." % voice_charges, ThemeColors.MSG_ERROR)
		return false
	voice_charges -= 3
	_whisper_used = true
	_whisper_turns = 5
	_whisper_revealed.clear()
	if GameManager.current_level:
		var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(grid_position, 6)
		for entity in entities:
			if is_instance_valid(entity) and entity is Monster and entity.is_alive:
				_whisper_revealed.append(entity.get_instance_id())
	GameManager.log_message("The Valar whisper of hidden foes nearby...", ThemeColors.PRIMARY)
	return true

## Whisper of the Valar: check if a specific entity is revealed
func is_whisper_revealed(entity: Entity) -> bool:
	if _whisper_turns <= 0:
		return false
	if not is_instance_valid(entity):
		return false
	return entity.get_instance_id() in _whisper_revealed

## Nimble Striker: check if free move is available after kill
func has_nimble_free_move() -> bool:
	return trait_effect_id == "nimble_striker" and _nimble_free_move

## Patient Stalker: check for adjacent alert enemies
func _any_adjacent_alert_enemy() -> bool:
	if not GameManager.current_level:
		return false
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(grid_position, 1)
	for entity in entities:
		if entity == self:
			continue
		if not is_instance_valid(entity) or not entity is Monster:
			continue
		var mon: Monster = entity as Monster
		if mon.is_alive and mon.alertness >= Constants.ALERTNESS_ALERT:
			return true
	return false

## Blood of Numenor: healing reduction handled in consumable_system.gd (separate agent)
# Note: the +1 holy damage vs UNDEAD/EVIL is in _on_successful_hit()
# Note: entrancement immunity is in apply_status()

## Shield Brother: enemy evasion penalty handled in monster.gd (separate agent)
# Note: +1 attack with shield is in get_total_attack()
# Note: ranged damage halving is in take_damage()

## Echoes of the Firstborn: voice cost reduction handled in ability_system.gd (separate agent)
# Note: speed reduction is in _apply_trait()
# Note: voice charge gain on floor entry is in reset_per_floor_traits()

func _recalculate_stats() -> void:
	# Apply equipment flags (stat/skill bonuses, resistances, ability grants)
	# This sets _equip_*_bonus and equip_skill_bonuses without modifying base stats
	_apply_equipment_flags()

	# Effective stats = base + equipment bonuses
	var eff_con: int = constitution + _equip_con_bonus
	var eff_gra: int = grace + _equip_gra_bonus
	var eff_str: int = strength + _equip_str_bonus
	var eff_dex: int = dexterity + _equip_dex_bonus

	# Sil-Q formula: 20 * 1.2^Con (compounding 20% per Con point)
	var hp_base: int = 2000  # 20 * 100 for integer math
	if eff_con >= 0:
		for i in range(eff_con):
			hp_base = hp_base * 12 / 10
	else:
		for i in range(-eff_con):
			hp_base = hp_base * 10 / 12
	max_health = hp_base / 100

	# Sil-Q formula: max_voice = 20 * 1.2^Grace (compounding 20% per Grace point)
	var voice_base: int = 2000  # 20 * 100 for integer math
	if eff_gra >= 0:
		for i in range(eff_gra):
			voice_base = voice_base * 12 / 10
	else:
		for i in range(-eff_gra):
			voice_base = voice_base * 10 / 12
	var old_max: int = max_voice
	max_voice = voice_base / 100
	voice_charges = mini(voice_charges, max_voice)
	# If max increased, don't auto-fill — regen handles it
	# If first calc (old was default 20), start full
	if old_max == 20 and max_voice != 20:
		voice_charges = max_voice

	# Combat bonuses from skills and stats
	melee_bonus = skills["melee"] + (eff_str / 2) + equip_skill_bonuses.get("melee", 0)
	evasion_bonus = skills["evasion"] + (eff_dex / 2) + equip_skill_bonuses.get("evasion", 0)

	# Equipment bonuses
	var equip_attack: int = 0
	var equip_evasion: int = 0

	for slot in equipment:
		var item = equipment[slot]
		if item == null:
			continue
		# Item is a DataManager.ItemData - use "in" instead of .has()
		if "attack_bonus" in item:
			equip_attack += item.attack_bonus
		if "evasion_bonus" in item:
			equip_evasion += item.evasion_bonus

	melee_bonus += equip_attack
	evasion_bonus += equip_evasion

	# Hunger penalties to combat stats
	var hunger_pen: Dictionary = get_hunger_penalties()
	if hunger_pen.get("str", 0) != 0:
		melee_bonus += hunger_pen.str  # Negative value = penalty
	if hunger_pen.get("dex", 0) != 0:
		evasion_bonus += hunger_pen.dex  # Negative value = penalty

	# Update protection dice from armor
	_recalculate_protection()

func _apply_equipment_flags() -> void:
	equip_flags.clear()
	_equip_str_bonus = 0
	_equip_dex_bonus = 0
	_equip_con_bonus = 0
	_equip_gra_bonus = 0
	for key in equip_skill_bonuses:
		equip_skill_bonuses[key] = 0

	for slot in equipment:
		var item: Variant = equipment[slot]
		if item == null:
			continue
		if "flags" not in item:
			continue

		var pval: int = 1
		if "pval" in item:
			pval = maxi(item.pval, 1)

		for flag in item.flags:
			match flag:
				# Stat bonuses (scaled by pval) - stored as bonuses, not added to base
				"STR":
					_equip_str_bonus += pval
				"DEX":
					_equip_dex_bonus += pval
				"CON":
					_equip_con_bonus += pval
				"GRA":
					_equip_gra_bonus += pval
				# Skill bonuses (scaled by pval)
				"PERCEPTION":
					equip_skill_bonuses["perception"] += pval
				"WILL":
					equip_skill_bonuses["will"] += pval
				"STEALTH":
					equip_skill_bonuses["stealth"] += pval
				"MELEE":
					equip_skill_bonuses["melee"] += pval
				"ARCHERY":
					equip_skill_bonuses["archery"] += pval
				# Boolean resistance flags
				"RES_FIRE", "RES_COLD", "RES_POIS", "RES_DARK", "RES_FEAR", \
				"RES_STUN", "RES_CONFU", "RES_HALLU":
					equip_flags[flag] = true
				# Boolean utility flags
				"FREE_ACT", "SEE_INVIS", "REGEN", "LIGHT", "SLOW_DIGEST", \
				"SUST_STR", "SUST_DEX", "SUST_CON", "SUST_GRA", "MEDIC", \
				"CHEAT_DEATH":
					equip_flags[flag] = true
				# Negative flags
				"HUNGER", "AGGRAVATE", "FEAR", "DANGER", "HAUNTED", \
				"LIGHT_CURSE":
					equip_flags[flag] = true
				# Brand flags
				"BRAND_FIRE", "BRAND_COLD", "BRAND_POIS":
					equip_flags[flag] = true

	# Apply granted abilities from B: lines
	for slot in equipment:
		var item: Variant = equipment[slot]
		if item == null:
			continue
		if "granted_abilities" not in item:
			continue
		for ability_ref in item.granted_abilities:
			if ability_ref.size() >= 2:
				var skill_id: int = ability_ref[0]
				var ability_id: int = ability_ref[1]
				if skill_id >= 0 and skill_id < Constants.S_MAX and ability_id >= 0 and ability_id < Constants.ABILITIES_MAX:
					have_ability[skill_id][ability_id] = true
					active_ability[skill_id][ability_id] = true

func has_equip_flag(flag_name: String) -> bool:
	return equip_flags.has(flag_name)

func get_effective_strength() -> int:
	return strength + _equip_str_bonus

func get_effective_dexterity() -> int:
	return dexterity + _equip_dex_bonus

func get_effective_constitution() -> int:
	return constitution + _equip_con_bonus

func get_effective_grace() -> int:
	return grace + _equip_gra_bonus

func get_effective_skill(skill_name: String) -> int:
	return skills.get(skill_name, 0) + equip_skill_bonuses.get(skill_name, 0)

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

	# Mithril Skin: innate +1d2 protection
	if trait_effect_id == "mithril_skin":
		total += randi_range(1, 2)

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
# HUNGER SYSTEM
# ============================================================================

## Get current hunger state as a string
func get_hunger_state() -> String:
	if hunger > HUNGER_NORMAL:
		return "well_fed"
	elif hunger > HUNGER_HUNGRY:
		return "normal"
	elif hunger > HUNGER_FAMISHED:
		return "hungry"
	elif hunger > HUNGER_STARVING:
		return "famished"
	else:
		return "starving"

## Decay hunger by 1 per turn and apply state-change messages
func tick_hunger() -> void:
	var old_state: String = _last_hunger_state
	hunger = maxi(0, hunger - 1)
	var new_state: String = get_hunger_state()

	# Log message on state transitions
	if new_state != old_state:
		match new_state:
			"hungry":
				GameManager.log_message("You are hungry.", ThemeColors.MSG_WARNING)
			"famished":
				GameManager.log_message("You are famished!", ThemeColors.MSG_ERROR)
			"starving":
				GameManager.log_message("You are starving!", ThemeColors.MSG_ERROR)
			"normal":
				if old_state == "hungry":
					GameManager.log_message("You no longer feel hungry.", ThemeColors.MSG_INFO)
			"well_fed":
				GameManager.log_message("You feel well fed.", ThemeColors.MSG_INFO)
		_last_hunger_state = new_state

	# Track turns at 0 hunger for escalating damage
	if hunger == 0:
		_starving_turns += 1
	else:
		_starving_turns = 0

## Apply hunger penalties to combat stats. Called during stat recalculation.
## Returns a Dictionary with penalty values.
func get_hunger_penalties() -> Dictionary:
	var state: String = get_hunger_state()
	match state:
		"hungry":
			return {"str": -1, "dex": -1, "will": -1, "no_regen": false}
		"famished":
			return {"str": -2, "dex": -2, "will": -2, "no_regen": true}
		"starving":
			return {"str": -3, "dex": -3, "will": -3, "no_regen": true}
		_:
			return {"str": 0, "dex": 0, "will": 0, "no_regen": false}

## Apply starvation damage (called from turn processing).
## At starving: -1 HP every 5 turns. At 0 hunger for 100+ turns: 1d4 per turn.
func apply_starvation_damage(current_round: int) -> void:
	if hunger <= HUNGER_STARVING and hunger > 0:
		# -1 HP every 5 turns when starving
		if current_round % 5 == 0:
			take_damage(1, "starvation", null)
			GameManager.log_message("You are wasting away from hunger!", ThemeColors.MSG_ERROR)
	elif hunger == 0 and _starving_turns >= 100:
		# After 100 turns at 0, take 1d4 damage per turn
		var damage: int = randi_range(1, 4)
		take_damage(damage, "starvation", null)
		GameManager.log_message("You are dying of starvation! (%d damage)" % damage, ThemeColors.MSG_ERROR)

## Restore hunger from eating food
func restore_hunger(amount: int) -> void:
	var old_state: String = get_hunger_state()
	hunger = mini(hunger + amount, HUNGER_MAX)
	var new_state: String = get_hunger_state()
	if new_state != old_state:
		_last_hunger_state = new_state

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

## Find the first equippable item from a list of Item nodes on the floor.
## Returns the Item node (not data) if found, or null if nothing can be equipped.
func try_equip_from_floor(items_on_floor: Array) -> Item:
	for item_node in items_on_floor:
		if not is_instance_valid(item_node):
			continue
		var item_data = item_node.get_data()
		if item_data == null or "tval" not in item_data:
			continue
		var tval: int = item_data.tval
		if tval not in Constants.TVAL_TO_SLOT:
			continue
		var slot_id: int = Constants.TVAL_TO_SLOT[tval]
		var slot_key: String = _equip_slot_id_to_key(slot_id)
		if slot_key.is_empty():
			continue
		# If slot is occupied, check if we can unequip to inventory
		if equipment[slot_key] != null:
			if inventory.size() >= max_inventory:
				continue  # Can't unequip, skip
		return item_node
	return null

## Convert EquipSlot enum to equipment dictionary key.
func _equip_slot_id_to_key(slot_id: int) -> String:
	match slot_id:
		Constants.EquipSlot.WEAPON: return "weapon"
		Constants.EquipSlot.OFF_HAND: return "off_hand"
		Constants.EquipSlot.BOW: return "bow"
		Constants.EquipSlot.QUIVER: return "quiver"
		Constants.EquipSlot.HEAD: return "head"
		Constants.EquipSlot.BODY: return "armor"
		Constants.EquipSlot.CLOAK: return "cloak"
		Constants.EquipSlot.HANDS: return "hands"
		Constants.EquipSlot.FEET: return "feet"
		Constants.EquipSlot.NECK: return "amulet"
		Constants.EquipSlot.RING_L: return "ring_left"
		Constants.EquipSlot.RING_R: return "ring_right"
		Constants.EquipSlot.LIGHT: return "light"
	return ""

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
	# Try stacking first for stackable items
	if "tval" in item_data and item_data.tval in Constants.STACKABLE_TVALS:
		for existing_item in inventory:
			if "tval" in existing_item and "sval" in existing_item and "name" in existing_item:
				if existing_item.tval == item_data.tval and existing_item.sval == item_data.sval and existing_item.name == item_data.name:
					var existing_count: int = existing_item.stack_count if "stack_count" in existing_item else 1
					var add_count: int = item_data.stack_count if "stack_count" in item_data else 1
					if existing_count + add_count <= Constants.MAX_STACK_SIZE:
						existing_item.stack_count = existing_count + add_count
						EventBus.item_picked_up.emit(self, item_data)
						return true

	if inventory.size() >= max_inventory:
		GameManager.log_message("Your pack is full!", ThemeColors.MSG_ERROR)
		return false

	# Ensure stack_count is set
	if "stack_count" not in item_data:
		item_data.stack_count = 1
	inventory.append(item_data)
	EventBus.item_picked_up.emit(self, item_data)
	return true

func drop_item(item_data: Variant) -> bool:
	var idx := inventory.find(item_data)
	if idx < 0:
		return false

	var count: int = item_data.stack_count if "stack_count" in item_data else 1
	if count > 1:
		# Drop one from the stack
		item_data.stack_count = count - 1
		# Create a copy for the ground with stack_count = 1
		var drop_copy = item_data.duplicate() if item_data is Dictionary else item_data
		if item_data is DataManager.ItemData:
			drop_copy = DataManager.ItemData.new()
			drop_copy.index = item_data.index
			drop_copy.name = item_data.name
			drop_copy.display_char = item_data.display_char
			drop_copy.color = item_data.color
			drop_copy.tval = item_data.tval
			drop_copy.sval = item_data.sval
			drop_copy.pval = item_data.pval
			drop_copy.depth = item_data.depth
			drop_copy.rarity = item_data.rarity
			drop_copy.weight = item_data.weight
			drop_copy.cost = item_data.cost
			drop_copy.attack_bonus = item_data.attack_bonus
			drop_copy.damage_dice = item_data.damage_dice
			drop_copy.evasion_bonus = item_data.evasion_bonus
			drop_copy.protection_dice = item_data.protection_dice
			drop_copy.description = item_data.description
			drop_copy.stack_count = 1
		EventBus.item_dropped.emit(self, drop_copy, grid_position)
		return true

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

	# Oath of Enmity: +2 vs oath target, -1 vs non-oath targets
	att += get_oath_bonus(target)

	# Shield Brother: +1 attack when wielding a shield
	if trait_effect_id == "shield_brother":
		var off_hand = equipment.get("off_hand")
		if off_hand != null and "tval" in off_hand and off_hand.tval == 34:
			att += 1

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

	# Nimble Striker: evasion bonus from hit-and-run
	evn += _nimble_evn_bonus

	# Blind: halve evasion
	if status_fx and status_fx.is_blind():
		evn = evn / 2

	# Darkness penalty: halve evasion if no light (can't see attacker)
	if not has_light() and is_instance_valid(attacker):
		if GameManager.current_level and not GameManager.current_level.is_tile_visible(attacker.grid_position):
			evn = evn / 2

	# Mithril Skin: cap evasion at 10 (heavy but tough)
	if trait_effect_id == "mithril_skin":
		evn = mini(evn, 10)

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
	# Patient Stalker: double damage on ambush attack after 3+ stealth turns
	if _stalker_double_ready:
		damage *= 2
		_stalker_double_ready = false
		_stalker_turns = 0
		GameManager.log_message("Your patience pays off! Double damage!", ThemeColors.COMBAT_CRIT)

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
					# VFX: blood-red flash on target + red particles + floater
					target.vfx_flash(ThemeColors.FLASH_THROAT_SLIT, 0.08, 0.2)
					target.vfx_particles(ThemeColors.DMG_PHYSICAL, 8, 35.0, 0.5)
					vfx_floater("Throat Slit!", ThemeColors.COMBAT_CRIT, 18)
					target.current_health = 0
					GameManager.log_message("You slit %s's throat!" % target.entity_name, ThemeColors.COMBAT_CRIT)
					target.die(self)
					return

	# Charge VFX: impact particles when charging into melee
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_CHARGE):
		if _is_charging_toward(target):
			if is_instance_valid(target):
				target.vfx_flash(ThemeColors.FLASH_CHARGE, 0.06, 0.15)
				target.vfx_particles(ThemeColors.PRIMARY, 6, 25.0, 0.3)
				vfx_floater("Charge!", ThemeColors.PRIMARY_BRIGHT, 16)

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

	# Nimble Striker: +2 evasion when hitting after moving; free move on kill
	if trait_effect_id == "nimble_striker" and moved_this_turn:
		_nimble_evn_bonus = 2
		if is_instance_valid(target) and target.current_health <= 0:
			_nimble_free_move = true

	# Oath of Enmity: +1 extra damage die vs oath target (matching weapon dice)
	if trait_effect_id == "oath_of_enmity" and not _oath_target_type.is_empty():
		if is_instance_valid(target) and target is Monster:
			var mon: Monster = target as Monster
			if mon.entity_name == _oath_target_type:
				var oath_dmg_dice: String = get_weapon_damage_dice()
				var oath_dmg: int = DataManager.roll_dice(oath_dmg_dice)
				if target.current_health > 0:
					target.take_damage(oath_dmg, "physical", self)
					GameManager.log_message("Your oath empowers the strike! (+%d)" % oath_dmg, ThemeColors.PRIMARY)

	# Blood of Numenor: +1 holy damage vs UNDEAD or EVIL targets
	if trait_effect_id == "blood_of_numenor":
		if is_instance_valid(target) and target is Monster and target.current_health > 0:
			var mon: Monster = target as Monster
			if mon.monster_data and (mon.monster_data.has_flag("UNDEAD") or mon.monster_data.has_flag("EVIL")):
				target.take_damage(1, "holy", self)
				GameManager.log_message("Your Numenorean blood sears %s! (+1)" % target.entity_name, ThemeColors.PRIMARY)

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
	var ranged_weapon = equipment.get("bow")
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

	# Steady Aim: +3 attack (already applied above would be ideal, but spec says
	# add after crit calc) and +1 crit die when stationary
	if trait_effect_id == "steady_aim" and _steady_aim_ready:
		att += 3
		crit_dice += 1
		_steady_aim_ready = false
		GameManager.log_message("Steady aim!", ThemeColors.ABILITY_LEARNED)

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
			# VFX: icy blue-white flash on target + impact particles + floater
			target.vfx_flash(ThemeColors.FLASH_CRIPPLE, 0.06, 0.2)
			target.vfx_particles(ThemeColors.STATUS_SLOW, 6, 25.0, 0.4)
			target.vfx_floater("Crippled!", ThemeColors.STATUS_SLOW, 16)
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

	# Wayfarer's Instinct: reduce noise by 2 (min 0)
	var effective_noise: int = noise_this_turn
	if trait_effect_id == "wayfarers_instinct":
		effective_noise = maxi(0, effective_noise - 2)

	# Patient Stalker: +3 stealth when stealthing with no adjacent alert enemies
	if trait_effect_id == "patient_stalker" and stealth_mode and not _any_adjacent_alert_enemy():
		score += 3

	# Noise penalty
	score -= effective_noise
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

	# PHOSPHOR: +1 light radius from Phosphorescent Moss
	if status_fx and status_fx.has_effect(Constants.EFFECT_PHOSPHOR):
		base_radius += 1

	# Depth darkness modifier (deeper layers suppress light)
	if GameManager.current_level:
		var depth_mod: int = LayerConfig.get_darkness_modifier(GameManager.current_level.depth)
		base_radius = maxi(1, base_radius + depth_mod)

	# Dark Aura: adjacent monsters with DARK_AURA suppress light by 1 each
	if GameManager.current_level:
		var dark_aura_count: int = _count_adjacent_dark_aura()
		if dark_aura_count > 0:
			base_radius = maxi(1, base_radius - dark_aura_count)

	return base_radius

## Count adjacent monsters that have the DARK_AURA flag
func _count_adjacent_dark_aura() -> int:
	if not GameManager.current_level:
		return 0
	var count: int = 0
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		var dist: int = maxi(absi(entity.grid_position.x - grid_position.x),
						absi(entity.grid_position.y - grid_position.y))
		if dist <= 1 and entity.is_dark_aura:
			count += 1
	return count

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

	# Blow horn/flute (P key)
	if Input.is_action_just_pressed("blow_horn"):
		return _use_first_consumable(Constants.TVAL_HORN)

	return false

## Use the first consumable of a given tval from inventory
func _use_first_consumable(target_tval: int) -> bool:
	for i in range(inventory.size()):
		var item = inventory[i]
		if item != null and "tval" in item and item.tval == target_tval:
			if ConsumableSystem.use_item(self, item):
				var count: int = item.stack_count if "stack_count" in item else 1
				if count > 1:
					item.stack_count = count - 1
				else:
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
	# Blood of Numenor: immune to entrancement
	if trait_effect_id == "blood_of_numenor" and status_name == "entranced":
		GameManager.log_message("Your Numenorean blood resists!", ThemeColors.PRIMARY)
		return

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

	# Shield Brother: halve ranged damage when blocking with a shield
	if trait_effect_id == "shield_brother" and damage_type == "ranged":
		if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_BLOCKING):
			var off_hand = equipment.get("off_hand")
			if off_hand != null and "tval" in off_hand and off_hand.tval == 34:
				amount = maxi(1, amount / 2)
				GameManager.log_message("Your shield deflects the blow!", ThemeColors.PRIMARY)

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

	# Oath of Enmity: lock onto first kill's type as oath target
	if trait_effect_id == "oath_of_enmity" and _oath_target_type.is_empty():
		_oath_target_type = monster.entity_name
		GameManager.log_message("You swear an oath against all %s!" % _oath_target_type, ThemeColors.PRIMARY)
