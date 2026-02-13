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
var _listen_turns: int = 0
var _listen_revealed: Array = []

# Defensive stance toggle state
var _defensive_stance_active: bool = false
var _defensive_stance_duration: int = 0
var _defensive_stance_cooldown: int = 0
const DEFENSIVE_STANCE_DURATION_TURNS: int = 3

# Parry toggle state
var _parry_ready: bool = false
var _parry_ready_window: int = 0
var _parry_active_turns: int = 0
var _parry_cooldown: int = 0
const PARRY_READY_WINDOW_TURNS: int = 1
const PARRY_ACTIVE_TURNS: int = 1
const PARRY_COOLDOWN_TURNS: int = 5

# Ability stance/action state (active remaster)
var _disguise_active: bool = false
var _disguise_cooldown: int = 0
const DISGUISE_RECAST_COOLDOWN_TURNS: int = 2

var _power_stance_active: bool = false
var _finesse_stance_active: bool = false

var _circular_guard_turns: int = 0
var _circular_guard_cooldown: int = 0
const CIRCULAR_GUARD_DURATION_TURNS: int = 3
const CIRCULAR_GUARD_COOLDOWN_TURNS: int = 6

var _swift_strikes_armed: bool = false
var _swift_strikes_cooldown: int = 0
const SWIFT_STRIKES_COOLDOWN_TURNS: int = 6

var _crippling_shot_armed: bool = false
var _crippling_shot_cooldown: int = 0
const CRIPPLING_SHOT_COOLDOWN_TURNS: int = 5

var _keen_senses_turns: int = 0
var _keen_senses_cooldown: int = 0
const KEEN_SENSES_DURATION_TURNS: int = 2
const KEEN_SENSES_COOLDOWN_TURNS: int = 4

# Hunting duel system (Mark -> Rhythm -> Exploit)
var _hunting_mark_target_id: int = -1
var _hunting_mark_duration: int = 0
var _hunting_mark_cooldown: int = 0
var _hunting_focus_stacks: int = 0
var _hunting_had_pressure_last_turn: bool = false
var _hunting_focus_gained_this_turn: bool = false
var _hunting_exploit_armed: bool = false
var _hunting_exploit_bonus_dice: int = 0
var _hunting_exploit_crit_bonus: int = 0

const HUNTING_MARK_DURATION_TURNS: int = 8
const HUNTING_MARK_COOLDOWN_TURNS: int = 11
const HUNTING_MARK_ATTACK_BONUS: int = 2
const HUNTING_MARK_EVASION_BONUS: int = 2
const HUNTING_FOCUS_MAX: int = 3
const HUNTING_EXPOSE_DURATION_TURNS: int = 4
const HUNTING_EXPOSE_COOLDOWN_TURNS: int = 8
var _hunting_expose_cooldown: int = 0

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
var stealth_explore_xp: int = 0

# Skills (0-20 scale)
var skills: Dictionary = {
	"melee": 0,
	"archery": 0,
	"evasion": 0,
	"stealth": 0,
	"hunting": 0,
	"will": 0,
	"smithing": 0,
	"lore": 0,  # Was "song" in Sil-Q
}

# Necromancer-specific
var lore_known: Dictionary = {}  # monster_type -> Array of lore abilities
var voice_charges: int = 20  # For song/voice abilities (starts full)
var max_voice: int = 20

# Ability gem slots (8 slots, -1 = empty)
var ability_hotkeys: Array[int] = [-1, -1, -1, -1, -1, -1, -1, -1]
var utility_hotkeys: Array[Dictionary] = [{}, {}, {}, {}, {}, {}]  # 6 item utility slots
var _voice_regen_accumulator: float = 0.0  # Fractional regen tracking

# Sustained song system (v4: dual song support via Mastery of Themes)
var active_song_id: int = -1        # Currently sustained song ability ID (-1 = none)
var song_voice_drain: int = 1       # Voice cost per turn while singing
var active_song_id_2: int = -1      # Second sustained song (Mastery of Themes)
var song_voice_drain_2: int = 0     # Voice cost per turn for second song
var dominated_monsters: Array = []  # Monsters under Word of Domination

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
	"hunting": 0,
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

# Rapid attack state
var _rapid_attack_penalty: int = 0  # Temporary attack penalty while executing a flurry

# Vengeance (Will): +2 attack on turn after being hit
var _vengeance_active: bool = false

# Fade (Stealth): temporary stealth bonus after kill
var _fade_bonus: int = 0
var _fade_turns: int = 0

# Follow-Through recursion guard
var _in_follow_through: bool = false

# Sprinting state
var _sprinting_turns: int = 0  # Turns remaining at double speed
var _sprint_charge_steps: int = 0
var _sprint_charge_dir: Vector2i = Vector2i.ZERO

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
	# Ensure player starts at full HP after stat calculation
	current_health = max_health
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.attack_missed.connect(_on_attack_evaded)
	EventBus.player_turn_started.connect(_on_player_turn_started)
	EventBus.entity_died.connect(_on_any_entity_died)

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
	else:
		# Sprint momentum requires consecutive movement with no idle/action breaks.
		_sprint_charge_steps = 0
		_sprint_charge_dir = Vector2i.ZERO
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

	# Listen (Perception): reveal nearby monsters through walls while stationary
	if _listen_turns > 0:
		_listen_turns -= 1
		if _listen_turns <= 0:
			_listen_revealed.clear()
	if has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_LISTEN):
		if not moved_this_turn and attacks_this_turn == 0:
			_apply_listen_reveal()
		else:
			_listen_turns = 0
			_listen_revealed.clear()

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
	attacked_this_turn = false
	moved_this_turn = false
	knocked_back = false
	noise_this_turn = 0
	was_attacked_this_turn = false

func _on_level_entered(_depth: int) -> void:
	reset_per_floor_traits()
	attacked_this_turn = false
	_vengeance_active = false
	_clear_hunting_mark()
	_break_disguise("You reset your disguise.")
	_power_stance_active = false
	_finesse_stance_active = false
	_circular_guard_turns = 0
	_swift_strikes_armed = false
	_crippling_shot_armed = false
	_keen_senses_turns = 0
	_sprint_charge_steps = 0
	_sprint_charge_dir = Vector2i.ZERO
	# Tick Fade bonus
	if _fade_turns > 0:
		_fade_turns -= 1
		if _fade_turns <= 0:
			_fade_bonus = 0

func _on_player_turn_started() -> void:
	# Tick short-duration combat stance/parry windows on player turns for predictable UX.
	if _defensive_stance_active:
		_defensive_stance_duration -= 1
		if _defensive_stance_duration <= 0:
			_break_defensive_stance()
	if _defensive_stance_cooldown > 0:
		_defensive_stance_cooldown -= 1

	if _parry_ready_window > 0:
		_parry_ready_window -= 1
		if _parry_ready_window <= 0:
			_parry_ready = false
	if _parry_active_turns > 0:
		_parry_active_turns -= 1
	if _parry_cooldown > 0:
		_parry_cooldown -= 1
	if _disguise_cooldown > 0:
		_disguise_cooldown -= 1
	if _circular_guard_cooldown > 0:
		_circular_guard_cooldown -= 1
	if _swift_strikes_cooldown > 0:
		_swift_strikes_cooldown -= 1
	if _crippling_shot_cooldown > 0:
		_crippling_shot_cooldown -= 1
	if _keen_senses_cooldown > 0:
		_keen_senses_cooldown -= 1
	if _circular_guard_turns > 0:
		_circular_guard_turns -= 1
	if _keen_senses_turns > 0:
		_keen_senses_turns -= 1

	# Hunting duel loop timing
	if _hunting_mark_cooldown > 0:
		_hunting_mark_cooldown -= 1
	if _hunting_expose_cooldown > 0:
		_hunting_expose_cooldown -= 1

	# Focus decays if we failed to pressure our marked quarry last turn.
	if _hunting_mark_target_id != -1:
		if _hunting_mark_duration > 0:
			_hunting_mark_duration -= 1
		if _hunting_mark_duration <= 0:
			_clear_hunting_mark()
		elif not _hunting_had_pressure_last_turn and _hunting_focus_stacks > 0:
			_hunting_focus_stacks -= 1

	_hunting_had_pressure_last_turn = false
	_hunting_focus_gained_this_turn = false

func _on_any_entity_died(entity: Entity, _killer: Entity) -> void:
	if entity == null:
		return
	if entity.get_instance_id() == _hunting_mark_target_id:
		_clear_hunting_mark()

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
	if _sprint_charge_steps < 3 or _sprint_charge_dir == Vector2i.ZERO:
		GameManager.log_message("Build momentum first: move 3 tiles in one direction.", ThemeColors.MSG_SYSTEM)
		return false
	_sprinting_turns = 3 + get_effective_skill("evasion") / 5
	_sprint_charge_steps = 0
	_sprint_charge_dir = Vector2i.ZERO
	apply_status("fast", _sprinting_turns)
	# VFX: green speed flash + particles + floater
	vfx_flash(ThemeColors.FLASH_SPRINT, 0.05, 0.15)
	vfx_particles(ThemeColors.ABILITY_LEARNED, 4, 20.0, 0.3)
	vfx_sprite_spell("wings")
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
	if GameManager.current_level:
		for entity in GameManager.current_level.entities:
			if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
				continue
			var mon: Monster = entity as Monster
			if mon.alertness >= Constants.ALERTNESS_ALERT and GameManager.current_level.is_tile_visible(mon.grid_position):
				GameManager.log_message("You need to break line of sight before vanishing.", ThemeColors.MSG_SYSTEM)
				return false
	_vanish_turns = 3
	# Massive stealth bonus while vanished
	_fade_bonus += 20
	# VFX: fade sprite to semi-transparent + dark smoke particles + floater
	vfx_flash(ThemeColors.FLASH_VANISH, 0.06, 0.2)
	vfx_particles(ThemeColors.BG_RAISED, 6, 20.0, 0.5)
	vfx_sprite_spell("smoke_glow")
	vfx_floater("Vanish!", ThemeColors.SKILL_STEALTH, 16)
	if sprite:
		var vanish_tween := create_tween()
		vanish_tween.tween_property(sprite, "modulate:a", 0.35, 0.25).set_ease(Tween.EASE_IN)
	GameManager.log_message("You vanish from sight!", ThemeColors.ABILITY_LEARNED)
	return true

func activate_disguise_stance() -> bool:
	if not has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_DISGUISE):
		GameManager.log_message("You haven't learned Disguise.", ThemeColors.MSG_ERROR)
		return false
	if _disguise_active:
		_break_disguise("You drop your disguise.")
		return true
	if _disguise_cooldown > 0:
		GameManager.log_message("Disguise is not ready (%d turns)." % _disguise_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	_disguise_active = true
	vfx_flash(ThemeColors.SKILL_STEALTH, 0.05, 0.15)
	vfx_sprite_spell("smoke", 0.34)
	vfx_floater("Disguised", ThemeColors.SKILL_STEALTH, 14)
	GameManager.log_message("You settle into a false gait and hidden profile.", ThemeColors.MSG_INFO)
	return true

func _break_disguise(reason: String = "") -> void:
	if not _disguise_active:
		return
	_disguise_active = false
	_disguise_cooldown = DISGUISE_RECAST_COOLDOWN_TURNS
	if not reason.is_empty():
		GameManager.log_message(reason, ThemeColors.MSG_SYSTEM)
	vfx_floater("Revealed", ThemeColors.MSG_WARNING, 14)

func is_disguise_active() -> bool:
	return _disguise_active

func activate_power_stance() -> bool:
	if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_POWER):
		GameManager.log_message("You haven't learned Power.", ThemeColors.MSG_ERROR)
		return false
	_power_stance_active = not _power_stance_active
	if _power_stance_active:
		_finesse_stance_active = false
		vfx_flash(ThemeColors.DMG_PHYSICAL, 0.05, 0.12)
		vfx_sprite_spell("fire_yellow", 0.52)
		vfx_floater("Power", ThemeColors.DMG_PHYSICAL, 14)
		GameManager.log_message("You adopt a crushing stance.", ThemeColors.MSG_INFO)
	else:
		GameManager.log_message("You relax your power stance.", ThemeColors.MSG_SYSTEM)
	return true

func activate_finesse_stance() -> bool:
	if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FINESSE):
		GameManager.log_message("You haven't learned Finesse.", ThemeColors.MSG_ERROR)
		return false
	_finesse_stance_active = not _finesse_stance_active
	if _finesse_stance_active:
		_power_stance_active = false
		vfx_flash(ThemeColors.SECONDARY, 0.05, 0.12)
		vfx_sprite_spell("feather", 1.0)
		vfx_floater("Finesse", ThemeColors.SECONDARY, 14)
		GameManager.log_message("You shift into a precise duelist stance.", ThemeColors.MSG_INFO)
	else:
		GameManager.log_message("You relax your finesse stance.", ThemeColors.MSG_SYSTEM)
	return true

func _break_weapon_stances(reason: String = "") -> void:
	var changed: bool = _power_stance_active or _finesse_stance_active
	_power_stance_active = false
	_finesse_stance_active = false
	_swift_strikes_armed = false
	if changed and not reason.is_empty():
		GameManager.log_message(reason, ThemeColors.MSG_SYSTEM)

func activate_circular_guard() -> bool:
	if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_CROWD_FIGHTING):
		GameManager.log_message("You haven't learned Circular Guard.", ThemeColors.MSG_ERROR)
		return false
	if _circular_guard_turns > 0:
		GameManager.log_message("Circular Guard is already active.", ThemeColors.MSG_SYSTEM)
		return false
	if _circular_guard_cooldown > 0:
		GameManager.log_message("Circular Guard cooldown (%d turns)." % _circular_guard_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	_circular_guard_turns = CIRCULAR_GUARD_DURATION_TURNS
	_circular_guard_cooldown = CIRCULAR_GUARD_COOLDOWN_TURNS
	vfx_ring_particles(ThemeColors.SECONDARY, 6, 10.0, 0.5)
	vfx_sprite_spell("sphere", 0.52)
	vfx_floater("Guard Ring", ThemeColors.SECONDARY, 14)
	GameManager.log_message("You set a circular guard and control the crush.", ThemeColors.MSG_INFO)
	return true

func activate_swift_strikes() -> bool:
	if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_RAPID_ATTACK):
		GameManager.log_message("You haven't learned Swift Strikes.", ThemeColors.MSG_ERROR)
		return false
	if _swift_strikes_armed:
		GameManager.log_message("Swift Strikes is already readied.", ThemeColors.MSG_SYSTEM)
		return false
	if _swift_strikes_cooldown > 0:
		GameManager.log_message("Swift Strikes cooldown (%d turns)." % _swift_strikes_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	_swift_strikes_armed = true
	vfx_sprite_spell("arrows_yellow", 0.58)
	vfx_floater("Flurry Ready", ThemeColors.ABILITY_LEARNED, 14)
	GameManager.log_message("You ready a flurry of swift strikes.", ThemeColors.MSG_INFO)
	return true

func activate_crippling_shot() -> bool:
	if not has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_CRIPPLING_SHOT):
		GameManager.log_message("You haven't learned Crippling Shot.", ThemeColors.MSG_ERROR)
		return false
	if _crippling_shot_armed:
		GameManager.log_message("Crippling Shot is already readied.", ThemeColors.MSG_SYSTEM)
		return false
	if _crippling_shot_cooldown > 0:
		GameManager.log_message("Crippling Shot cooldown (%d turns)." % _crippling_shot_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	_crippling_shot_armed = true
	vfx_sprite_spell("arrows_green", 0.58)
	vfx_floater("Hamstring", ThemeColors.STATUS_SLOW, 14)
	GameManager.log_message("You line up a hamstringing shot.", ThemeColors.MSG_INFO)
	return true

func activate_keen_senses() -> bool:
	if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_KEEN_SENSES):
		GameManager.log_message("You haven't learned Keen Senses.", ThemeColors.MSG_ERROR)
		return false
	if _keen_senses_cooldown > 0:
		GameManager.log_message("Keen Senses cooldown (%d turns)." % _keen_senses_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	_keen_senses_turns = KEEN_SENSES_DURATION_TURNS
	_keen_senses_cooldown = KEEN_SENSES_COOLDOWN_TURNS
	_apply_listen_reveal()
	vfx_ring_particles(ThemeColors.PRIMARY_BRIGHT, 7, 12.0, 0.55)
	vfx_sprite_spell("flash02")
	vfx_floater("Sense Pulse", ThemeColors.PRIMARY_BRIGHT, 14)
	GameManager.log_message("Your senses flare, tracing movement in the dark.", ThemeColors.MSG_INFO)
	return true

func activate_curse_breaking() -> bool:
	if not has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_CURSE_BREAKING):
		GameManager.log_message("You haven't learned Curse Breaking.", ThemeColors.MSG_ERROR)
		return false
	var voice_cost: int = 5
	if voice_charges < voice_cost:
		GameManager.log_message("Curse Breaking needs %d voice (%d available)." % [voice_cost, voice_charges], ThemeColors.MSG_ERROR)
		return false
	var removed: int = 0
	var clearable: Array[StringName] = [
		Constants.EFFECT_AFRAID,
		Constants.EFFECT_CONFUSED,
		Constants.EFFECT_ENTRANCED,
		Constants.EFFECT_STUNNED,
		Constants.EFFECT_SLOW,
		Constants.EFFECT_DARKENED,
	]
	for effect_id in clearable:
		if status_fx and status_fx.has_effect(effect_id):
			status_fx.remove_effect(effect_id, true)
			removed += 1
	if removed <= 0:
		GameManager.log_message("No afflictions answer your curse-breaking rite.", ThemeColors.MSG_SYSTEM)
		return false
	voice_charges = maxi(0, voice_charges - voice_cost)
	vfx_flash(ThemeColors.GOLD_BRIGHT, 0.06, 0.18)
	vfx_particles(ThemeColors.GOLD_BRIGHT, 8, 28.0, 0.45)
	vfx_sprite_spell("heal", 0.42)
	vfx_floater("Cleansed", ThemeColors.GOLD_BRIGHT, 16)
	GameManager.log_message("Your will sunders lingering curses (%d removed).", ThemeColors.ABILITY_LEARNED)
	return true

# ============================================================================
# GEM ABILITY IDS / HELPERS
# ============================================================================

const GEM_DEFENSIVE_STANCE: int = 1000
const GEM_READY_PARRY: int = 1001
const GEM_MARK_QUARRY: int = 1002
const GEM_EXPOSE_WEAKNESS: int = 1003
const GEM_EXPLOIT_OPENING: int = 1004
const GEM_DISGUISE: int = 1005
const GEM_CIRCULAR_GUARD: int = 1006
const GEM_SWIFT_STRIKES: int = 1007
const GEM_CRIPPLING_SHOT: int = 1008
const GEM_KEEN_SENSES: int = 1009
const GEM_CURSE_BREAKING: int = 1010
const GEM_POWER_STANCE: int = 1011
const GEM_FINESSE_STANCE: int = 1012
const GEM_VANISH: int = 1013
const GEM_SPRINTING: int = 1014

func get_hotbar_ability_display_name(ability_id: int) -> String:
	match ability_id:
		GEM_DEFENSIVE_STANCE: return "Defensive Stance"
		GEM_READY_PARRY: return "Parry"
		GEM_MARK_QUARRY: return "Mark Quarry"
		GEM_EXPOSE_WEAKNESS: return "Expose Weakness"
		GEM_EXPLOIT_OPENING: return "Exploit Opening"
		GEM_DISGUISE: return "Disguise"
		GEM_CIRCULAR_GUARD: return "Circular Guard"
		GEM_SWIFT_STRIKES: return "Swift Strikes"
		GEM_CRIPPLING_SHOT: return "Crippling Shot"
		GEM_KEEN_SENSES: return "Keen Senses"
		GEM_CURSE_BREAKING: return "Curse Breaking"
		GEM_POWER_STANCE: return "Power Stance"
		GEM_FINESSE_STANCE: return "Finesse Stance"
		GEM_VANISH: return "Vanish"
		GEM_SPRINTING: return "Sprinting"
		_: return "Unknown"

func get_hotbar_ability_cost(ability_id: int, ability_system: Node = null) -> int:
	if ability_id >= 140 and ability_id <= 159 and ability_system and ability_system.has_method("get_effective_voice_cost"):
		return int(ability_system.get_effective_voice_cost(ability_id))
	match ability_id:
		GEM_CURSE_BREAKING:
			return 5
		_:
			return 0

func is_hotbar_ability_targeted(ability_id: int, ability_system: Node = null) -> bool:
	if ability_id == GEM_MARK_QUARRY:
		return true
	if ability_id >= 140 and ability_id <= 159 and ability_system and ability_system.has_method("_ability_needs_target"):
		return bool(ability_system._ability_needs_target(ability_id))
	return false

func can_use_hotbar_ability(ability_id: int, ability_system: Node = null) -> Dictionary:
	if ability_id >= 140 and ability_id <= 159:
		if ability_system and ability_system.has_method("can_use_ability"):
			return ability_system.can_use_ability(ability_id)
		return {"can_use": false, "reason": "Ability system unavailable."}
	match ability_id:
		GEM_DEFENSIVE_STANCE:
			if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_DEFENSIVE_STANCE):
				return {"can_use": false, "reason": "Not learned."}
			if _defensive_stance_active:
				return {"can_use": false, "reason": "Already active."}
			if _defensive_stance_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _defensive_stance_cooldown}
			if moved_last_turn or moved_this_turn or attacked_this_turn:
				return {"can_use": false, "reason": "Hold position first."}
			return {"can_use": true, "reason": ""}
		GEM_READY_PARRY:
			if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_PARRY):
				return {"can_use": false, "reason": "Not learned."}
			if _parry_ready:
				return {"can_use": false, "reason": "Already readied."}
			if _parry_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _parry_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_MARK_QUARRY:
			if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK):
				return {"can_use": false, "reason": "Not learned."}
			if _hunting_mark_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _hunting_mark_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_EXPOSE_WEAKNESS:
			if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_BANE):
				return {"can_use": false, "reason": "Not learned."}
			if _hunting_expose_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _hunting_expose_cooldown}
			if _get_marked_quarry() == null:
				return {"can_use": false, "reason": "No marked quarry."}
			return {"can_use": true, "reason": ""}
		GEM_EXPLOIT_OPENING:
			if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_MASTER_HUNTER):
				return {"can_use": false, "reason": "Not learned."}
			if _hunting_focus_stacks <= 0:
				return {"can_use": false, "reason": "Need focus."}
			if _get_marked_quarry() == null:
				return {"can_use": false, "reason": "No marked quarry."}
			return {"can_use": true, "reason": ""}
		GEM_DISGUISE:
			if not has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_DISGUISE):
				return {"can_use": false, "reason": "Not learned."}
			if _disguise_active:
				return {"can_use": true, "reason": "Drop disguise"}
			if _disguise_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _disguise_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_CIRCULAR_GUARD:
			if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_CROWD_FIGHTING):
				return {"can_use": false, "reason": "Not learned."}
			if _circular_guard_turns > 0:
				return {"can_use": false, "reason": "Already active."}
			if _circular_guard_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _circular_guard_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_SWIFT_STRIKES:
			if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_RAPID_ATTACK):
				return {"can_use": false, "reason": "Not learned."}
			if _swift_strikes_armed:
				return {"can_use": false, "reason": "Already armed."}
			if _swift_strikes_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _swift_strikes_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_CRIPPLING_SHOT:
			if not has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_CRIPPLING_SHOT):
				return {"can_use": false, "reason": "Not learned."}
			if _crippling_shot_armed:
				return {"can_use": false, "reason": "Already armed."}
			if _crippling_shot_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _crippling_shot_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_KEEN_SENSES:
			if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_KEEN_SENSES):
				return {"can_use": false, "reason": "Not learned."}
			if _keen_senses_cooldown > 0:
				return {"can_use": false, "reason": "Cooldown (%d)." % _keen_senses_cooldown}
			return {"can_use": true, "reason": ""}
		GEM_CURSE_BREAKING:
			if not has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_CURSE_BREAKING):
				return {"can_use": false, "reason": "Not learned."}
			if voice_charges < 5:
				return {"can_use": false, "reason": "Need 5 voice."}
			return {"can_use": true, "reason": ""}
		GEM_POWER_STANCE:
			if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_POWER):
				return {"can_use": false, "reason": "Not learned."}
			return {"can_use": true, "reason": "Toggle"}
		GEM_FINESSE_STANCE:
			if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FINESSE):
				return {"can_use": false, "reason": "Not learned."}
			return {"can_use": true, "reason": "Toggle"}
		GEM_VANISH:
			if not has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_VANISH):
				return {"can_use": false, "reason": "Not learned."}
			if _vanish_turns > 0:
				return {"can_use": false, "reason": "Already hidden."}
			return {"can_use": true, "reason": ""}
		GEM_SPRINTING:
			if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_SPRINTING):
				return {"can_use": false, "reason": "Not learned."}
			if _sprinting_turns > 0:
				return {"can_use": false, "reason": "Already sprinting."}
			if _sprint_charge_steps < 3 or _sprint_charge_dir == Vector2i.ZERO:
				return {"can_use": false, "reason": "Need 3 same-direction moves."}
			return {"can_use": true, "reason": ""}
	return {"can_use": false, "reason": "Unknown ability."}

func is_hotbar_ability_active(ability_id: int) -> bool:
	match ability_id:
		GEM_DISGUISE:
			return _disguise_active
		GEM_POWER_STANCE:
			return _power_stance_active
		GEM_FINESSE_STANCE:
			return _finesse_stance_active
		GEM_DEFENSIVE_STANCE:
			return _defensive_stance_active and _defensive_stance_duration > 0
		GEM_VANISH:
			return _vanish_turns > 0
		GEM_SPRINTING:
			return _sprinting_turns > 0
		GEM_CIRCULAR_GUARD:
			return _circular_guard_turns > 0
	return false

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

	# Smithing: Grace — permanent +1 GRA when learned (Task 15)
	if skill == Constants.Skill.S_SMT and ability == Constants.SmithingAbility.SMT_GRACE:
		grace += 1
		GameManager.log_message("Your grace increases by 1!", ThemeColors.ABILITY_LEARNED)

func abilities_in_skill(skill_type: int) -> int:
	if skill_type < 0 or skill_type >= Constants.S_MAX:
		return 0
	var count: int = 0
	for i in range(Constants.ABILITIES_MAX):
		if innate_ability[skill_type][i]:
			count += 1
	return count

func _setup_player_sprite() -> void:
	# V2: Look up sprite by race + house + gender
	var house_data: DataManager.HouseData = DataManager.get_house(house_name)
	if house_data:
		var sprite_gender: String = gender if not gender.is_empty() else "male"
		set_sprite_from_player_v2(race_name, house_data.index, sprite_gender)
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
		var player_roll: int = randi_range(1, 20) + get_effective_skill("will")
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

## Listen (Perception): reveal nearby monsters through walls while stationary
func _apply_listen_reveal() -> void:
	if not GameManager.current_level:
		return
	var radius: int = 3 + get_effective_skill("hunting") / 4
	_listen_turns = 1
	_listen_revealed.clear()
	var entities: Array[Entity] = GameManager.current_level.get_entities_in_radius(grid_position, radius)
	for entity in entities:
		if is_instance_valid(entity) and entity is Monster and entity.is_alive:
			_listen_revealed.append(entity.get_instance_id())

func activate_defensive_stance() -> bool:
	if not has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_DEFENSIVE_STANCE):
		GameManager.log_message("You haven't learned Defensive Stance.", ThemeColors.MSG_ERROR)
		return false
	if _defensive_stance_active:
		GameManager.log_message("You're already braced.", ThemeColors.MSG_SYSTEM)
		return false
	if _defensive_stance_cooldown > 0:
		GameManager.log_message("Defensive Stance is on cooldown (%d turns)." % _defensive_stance_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	if moved_last_turn:
		GameManager.log_message("You must hold position for a turn before bracing.", ThemeColors.MSG_SYSTEM)
		return false
	if moved_this_turn or attacked_this_turn:
		GameManager.log_message("You must stand still this turn to brace for impact.", ThemeColors.MSG_SYSTEM)
		return false
	_defensive_stance_active = true
	_defensive_stance_duration = DEFENSIVE_STANCE_DURATION_TURNS
	_defensive_stance_cooldown = 5
	vfx_sprite_spell("sphere_yellow", 0.52)
	vfx_floater("Defend", ThemeColors.SECONDARY, 14)
	GameManager.log_message("You brace for impact.", ThemeColors.MSG_SYSTEM)
	return true

func _break_defensive_stance() -> void:
	if _defensive_stance_active:
		_defensive_stance_active = false
		_defensive_stance_duration = 0

func ready_parry() -> bool:
	if not has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_PARRY):
		GameManager.log_message("You haven't learned Parry.", ThemeColors.MSG_ERROR)
		return false
	if _parry_ready:
		GameManager.log_message("You're already readying a parry.", ThemeColors.MSG_SYSTEM)
		return false
	if _parry_cooldown > 0:
		GameManager.log_message("Parry is on cooldown (%d turns)." % _parry_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	_parry_ready = true
	_parry_ready_window = PARRY_READY_WINDOW_TURNS
	_parry_cooldown = PARRY_COOLDOWN_TURNS
	vfx_flash(ThemeColors.FLASH_RIPOSTE, 0.05, 0.14)
	vfx_sprite_spell("flash", 0.72)
	vfx_ring_particles(ThemeColors.SECONDARY, 5, 9.0, 0.35)
	vfx_floater("Parry Ready", ThemeColors.ABILITY_LEARNED, 14)
	GameManager.log_message("You ready a parry stance.", ThemeColors.MSG_SYSTEM)
	return true

func _resolve_parry_hit(damage: int) -> int:
	_parry_ready = false
	_parry_ready_window = 0
	_parry_active_turns = PARRY_ACTIVE_TURNS
	_parry_cooldown = maxi(_parry_cooldown, PARRY_COOLDOWN_TURNS)
	vfx_flash(ThemeColors.GOLD_BRIGHT, 0.06, 0.16)
	vfx_particles(ThemeColors.GOLD_BRIGHT, 7, 22.0, 0.35)
	vfx_sprite_spell("cauterize", 0.36)
	vfx_floater("Parry!", ThemeColors.GOLD_BRIGHT, 16)
	GameManager.log_message("You parry the blow!", ThemeColors.MSG_PRIMARY)
	return maxi(1, int(damage / 2))

func get_parry_active_bonus() -> int:
	var weapon = equipment.get("weapon")
	var parry_weapon_evn: int = 0
	if weapon != null and "evasion_bonus" in weapon:
		parry_weapon_evn = weapon.evasion_bonus
	return maxi(4, parry_weapon_evn * 2)

func get_combat_stance_indicators() -> Array[Dictionary]:
	var indicators: Array[Dictionary] = []

	# PARRY card: show if any parry lifecycle state is currently relevant.
	var parry_active_turns: int = _parry_active_turns
	if parry_active_turns <= 0 and _parry_ready and _parry_ready_window > 0:
		parry_active_turns = _parry_ready_window
	if parry_active_turns > 0 or _parry_cooldown > 0:
		indicators.append({
			"id": "parry",
			"title": "PARRY",
			"icon": "parry",
			"bonus_text": "+%d Evasion" % get_parry_active_bonus(),
			"active_turns": parry_active_turns,
			"cooldown_turns": _parry_cooldown,
		})

	# DEFEND card: show if active or cooling down.
	if (_defensive_stance_active and _defensive_stance_duration > 0) or _defensive_stance_cooldown > 0:
		indicators.append({
			"id": "defend",
			"title": "DEFEND",
			"icon": "defend",
			"bonus_text": "+5 Evasion",
			"active_turns": _defensive_stance_duration if _defensive_stance_active else 0,
			"cooldown_turns": _defensive_stance_cooldown,
		})

	# HUNT card: show while quarry is marked, focused, or cooling down.
	var marked_target: Monster = _get_marked_quarry()
	if marked_target != null or _hunting_focus_stacks > 0 or _hunting_mark_cooldown > 0:
		var hunt_title: String = "HUNT"
		if marked_target != null:
			hunt_title = "HUNT: %s" % marked_target.entity_name
		indicators.append({
			"id": "hunt",
			"title": hunt_title,
			"icon": "hunt",
			"bonus_text": "Focus %d/%d" % [_hunting_focus_stacks, HUNTING_FOCUS_MAX],
			"active_turns": _hunting_mark_duration,
			"cooldown_turns": _hunting_mark_cooldown,
		})

	if _circular_guard_turns > 0 or _circular_guard_cooldown > 0:
		indicators.append({
			"id": "circle",
			"title": "CIRCULAR GUARD",
			"icon": "circle",
			"bonus_text": "+2 Evasion, no surround penalty",
			"active_turns": _circular_guard_turns,
			"cooldown_turns": _circular_guard_cooldown,
		})

	if _swift_strikes_armed or _swift_strikes_cooldown > 0:
		indicators.append({
			"id": "swift",
			"title": "SWIFT STRIKES",
			"icon": "swift",
			"bonus_text": "2 attacks @ -2",
			"active_turns": 1 if _swift_strikes_armed else 0,
			"cooldown_turns": _swift_strikes_cooldown,
		})

	if _disguise_active or _disguise_cooldown > 0:
		indicators.append({
			"id": "disguise",
			"title": "DISGUISE",
			"icon": "disguise",
			"bonus_text": "+stealth, lower sight profile",
			"active_turns": 1 if _disguise_active else 0,
			"cooldown_turns": _disguise_cooldown,
		})

	return indicators

func activate_mark_quarry() -> bool:
	if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK):
		GameManager.log_message("You haven't learned Mark Quarry.", ThemeColors.MSG_ERROR)
		return false
	if _hunting_mark_cooldown > 0:
		GameManager.log_message("Mark Quarry is on cooldown (%d turns)." % _hunting_mark_cooldown, ThemeColors.MSG_SYSTEM)
		return false

	var target: Monster = _find_best_hunt_target()
	if target == null:
		GameManager.log_message("No visible quarry to mark.", ThemeColors.MSG_SYSTEM)
		return false
	return activate_mark_quarry_on_target(target)

func can_mark_quarry_now() -> bool:
	return has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK) and _hunting_mark_cooldown <= 0

func get_mark_quarry_cooldown_turns() -> int:
	return _hunting_mark_cooldown

func activate_mark_quarry_on_target(target: Monster) -> bool:
	if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK):
		GameManager.log_message("You haven't learned Mark Quarry.", ThemeColors.MSG_ERROR)
		return false
	if _hunting_mark_cooldown > 0:
		GameManager.log_message("Mark Quarry is on cooldown (%d turns)." % _hunting_mark_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	if target == null or not is_instance_valid(target) or not target.is_alive:
		GameManager.log_message("No valid quarry selected.", ThemeColors.MSG_SYSTEM)
		return false
	if not GameManager.current_level or not GameManager.current_level.is_tile_visible(target.grid_position):
		GameManager.log_message("You can only mark a visible quarry.", ThemeColors.MSG_SYSTEM)
		return false

	_hunting_mark_target_id = target.get_instance_id()
	_hunting_mark_duration = HUNTING_MARK_DURATION_TURNS
	_hunting_mark_cooldown = HUNTING_MARK_COOLDOWN_TURNS
	_hunting_focus_stacks = 0
	_hunting_had_pressure_last_turn = false
	_hunting_focus_gained_this_turn = false
	_hunting_exploit_armed = false
	_hunting_exploit_bonus_dice = 0
	_hunting_exploit_crit_bonus = 0

	vfx_sprite_spell("fire_green", 0.54)
	vfx_floater("Marked", ThemeColors.PRIMARY_BRIGHT, 15)
	target.vfx_sprite_spell("flash03", 0.72)
	target.vfx_floater("Quarry", ThemeColors.PRIMARY_BRIGHT, 14)
	GameManager.log_message("You mark %s as your quarry. Cooldown: %d turns." % [target.entity_name, _hunting_mark_cooldown], ThemeColors.MSG_INFO)
	return true

func activate_expose_weakness() -> bool:
	if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_BANE):
		GameManager.log_message("You haven't learned Expose Weakness.", ThemeColors.MSG_ERROR)
		return false
	if _hunting_expose_cooldown > 0:
		GameManager.log_message("Expose Weakness is on cooldown (%d turns)." % _hunting_expose_cooldown, ThemeColors.MSG_SYSTEM)
		return false
	var target: Monster = _get_marked_quarry()
	if target == null:
		GameManager.log_message("You need a marked quarry first.", ThemeColors.MSG_SYSTEM)
		return false

	var player_roll: int = randi_range(1, 20) + get_effective_skill("hunting")
	var target_will: int = target.monster_data.will if target.monster_data else 5
	var monster_roll: int = randi_range(1, 20) + target_will

	_hunting_expose_cooldown = HUNTING_EXPOSE_COOLDOWN_TURNS
	if player_roll >= monster_roll:
		target.apply_hunter_exposure(HUNTING_EXPOSE_DURATION_TURNS, 3, 1)
		_register_hunting_pressure(target)
		target.vfx_sprite_spell("skull_smoke_green", 0.42)
		vfx_floater("Exposed!", ThemeColors.COMBAT_CRIT, 15)
		GameManager.log_message("You expose %s's weakness!" % target.entity_name, ThemeColors.COMBAT_CRIT)
	else:
		# Partial fail-soft to keep this tactical rather than punishing dead turns.
		target.apply_hunter_exposure(2, 1, 0)
		GameManager.log_message("%s partially resists your reading of its stance." % target.entity_name, ThemeColors.MSG_WARNING)

	return true

func activate_exploit_opening() -> bool:
	if not has_ability(Constants.Skill.S_PER, Constants.PerceptionAbility.PER_MASTER_HUNTER):
		GameManager.log_message("You haven't learned Exploit Opening.", ThemeColors.MSG_ERROR)
		return false
	if _hunting_focus_stacks <= 0:
		GameManager.log_message("You need Focus to exploit an opening.", ThemeColors.MSG_SYSTEM)
		return false
	var target: Monster = _get_marked_quarry()
	if target == null:
		GameManager.log_message("You need a marked quarry first.", ThemeColors.MSG_SYSTEM)
		return false

	_hunting_exploit_armed = true
	_hunting_exploit_bonus_dice = _hunting_focus_stacks
	_hunting_exploit_crit_bonus = 1 if _hunting_focus_stacks >= 3 else 0
	_hunting_focus_stacks = 0
	vfx_sprite_spell("fireball_blue", 0.34)
	vfx_floater("Exploit!", ThemeColors.GOLD_BRIGHT, 16)
	GameManager.log_message("You prepare to exploit %s's opening." % target.entity_name, ThemeColors.MSG_INFO)
	return true

func _find_best_hunt_target() -> Monster:
	if not GameManager.current_level:
		return null
	var best: Monster = null
	var best_score: int = -99999
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		var mon: Monster = entity as Monster
		if not GameManager.current_level.is_tile_visible(mon.grid_position):
			continue
		var dist: int = maxi(absi(mon.grid_position.x - grid_position.x), absi(mon.grid_position.y - grid_position.y))
		var score: int = 0
		if mon.is_unique:
			score += 100
		score += mon.max_health / 3
		score += mon.melee_bonus
		score += mon.evasion_bonus
		score -= dist
		if score > best_score:
			best_score = score
			best = mon
	return best

func _get_marked_quarry() -> Monster:
	if _hunting_mark_target_id == -1 or _hunting_mark_duration <= 0:
		return null
	var obj: Object = instance_from_id(_hunting_mark_target_id)
	if obj == null or not is_instance_valid(obj) or not obj is Monster:
		_clear_hunting_mark()
		return null
	var mon: Monster = obj as Monster
	if not mon.is_alive:
		_clear_hunting_mark()
		return null
	return mon

func _clear_hunting_mark() -> void:
	_hunting_mark_target_id = -1
	_hunting_mark_duration = 0
	_hunting_focus_stacks = 0
	_hunting_had_pressure_last_turn = false
	_hunting_focus_gained_this_turn = false
	_hunting_exploit_armed = false
	_hunting_exploit_bonus_dice = 0
	_hunting_exploit_crit_bonus = 0

func _register_hunting_pressure(target: Entity) -> void:
	var marked: Monster = _get_marked_quarry()
	if marked == null:
		return
	if target == null or not is_instance_valid(target) or target != marked:
		return
	_hunting_had_pressure_last_turn = true
	if _hunting_focus_stacks < HUNTING_FOCUS_MAX:
		_hunting_focus_stacks += 1
		_hunting_focus_gained_this_turn = true

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

	# Modified Sil-Q formula: 24 * 1.2^Con (base bumped from 20 for survivability)
	var hp_base: int = 2400  # 24 * 100 for integer math
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
					equip_skill_bonuses["hunting"] += pval
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
				# Slay flags (boolean)
				"SLAY_ORC", "SLAY_TROLL", "SLAY_SPIDER", "SLAY_WOLF", \
				"SLAY_UNDEAD", "SLAY_RAUKO", "SLAY_DRAGON", "SLAY_MAN_OR_ELF":
					equip_flags[flag] = true
				# Defensive utility flags
				"STAND_FAST", "AVOID_TRAPS", "ACCURATE", "SHARPNESS", \
				"VAMPIRIC", "TUNNEL", "RADIANCE", "RES_BLIND", "RES_BLEED":
					equip_flags[flag] = true
				# Negative stat flags (scaled by pval)
				"NEG_STR":
					_equip_str_bonus -= pval
				"NEG_DEX":
					_equip_dex_bonus -= pval
				"NEG_CON":
					_equip_con_bonus -= pval
				"NEG_GRA":
					_equip_gra_bonus -= pval
				# Skill flags (SONG flag maps to lore skill bonus)
				"SONG":
					equip_skill_bonuses["lore"] += pval

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



## Try to drain a stat, blocked by SUST_* flags. Returns actual drain amount.
func try_drain_stat(stat_name: String, drain_amount: int) -> int:
	var sust_flag: String = "SUST_" + stat_name.to_upper()
	if has_equip_flag(sust_flag):
		GameManager.log_message("Your equipment sustains your %s!" % stat_name, ThemeColors.PRIMARY)
		return 0
	match stat_name:
		"str", "strength":
			strength = maxi(-5, strength - drain_amount)
		"dex", "dexterity":
			dexterity = maxi(-5, dexterity - drain_amount)
		"con", "constitution":
			constitution = maxi(-5, constitution - drain_amount)
		"gra", "grace":
			grace = maxi(-5, grace - drain_amount)
	_recalculate_stats()
	return drain_amount

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
	# Apply base XP multiplier + difficulty modifier
	var difficulty_xp: float = GameManager.get_xp_multiplier() if GameManager else 1.0
	var boosted: int = int(amount * XP_MULTIPLIER * difficulty_xp)

	# Track by source
	match source:
		"kill": kill_xp += boosted
		"encounter": encounter_xp += boosted
		"descent": descent_xp += boosted
		"identify": identify_xp += boosted
		"stealth_explore": stealth_explore_xp += boosted

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
	"PER_AFFINITY": "hunting",
	"WIL_AFFINITY": "will",
	"SMT_AFFINITY": "smithing",
	"LOR_AFFINITY": "lore",
}

const PENALTY_MAP: Dictionary = {
	"MEL_PENALTY": "melee", "ARC_PENALTY": "archery",
	"EVN_PENALTY": "evasion", "STL_PENALTY": "stealth",
	"PER_PENALTY": "hunting", "WIL_PENALTY": "will",
	"SMT_PENALTY": "smithing", "LOR_PENALTY": "lore",
}

func get_ability_affinity_level(skill_name: String) -> int:
	var level: int = 0
	var house_data := DataManager.get_house(house_name)
	if house_data:
		for flag in house_data.affinities:
			if AFFINITY_MAP.get(flag, "") == skill_name:
				level += 1
	var race_data := DataManager.get_race(race_name)
	if race_data:
		for flag in race_data.flags:
			if PENALTY_MAP.get(flag, "") == skill_name:
				level -= 1
			if AFFINITY_MAP.get(flag, "") == skill_name:
				level += 1
	return level

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

## Raw skill points only (for ability prerequisites, skill costs).
func get_skill(skill_name: String) -> int:
	return skills.get(skill_name, 0)

## Sil-Q effective skill: raw skill + governing stat + equipment bonuses.
## DEX governs: melee, archery, evasion, stealth.
## GRA governs: hunting, will, smithing, lore.
func get_effective_skill(skill_name: String) -> int:
	var base: int = skills.get(skill_name, 0)
	var equip: int = equip_skill_bonuses.get(skill_name, 0)
	var stat_bonus: int = 0
	match skill_name:
		"melee", "archery", "evasion", "stealth":
			stat_bonus = dexterity
		"hunting", "will", "smithing", "lore":
			stat_bonus = grace
	return base + stat_bonus + equip

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
	# Forge Intuition: auto-identify unidentified items on pickup
	if has_forge_intuition() and "identified" in item_data and not item_data.identified:
		GameManager.identify_item(item_data)
		GameManager.log_message("Forge Intuition: You recognize the %s." % item_data.name, ThemeColors.MSG_INFO)
	EventBus.item_picked_up.emit(self, item_data)
	return true

func drop_item(item_data: Variant) -> bool:
	# Find item by reference first, then fall back to property match
	var idx := inventory.find(item_data)
	if idx < 0:
		# Fallback: find by tval/sval/name match (handles reference mismatches)
		for i in range(inventory.size()):
			var inv_item: Variant = inventory[i]
			if "tval" in inv_item and "sval" in inv_item and "name" in inv_item:
				if "tval" in item_data and "sval" in item_data and "name" in item_data:
					if inv_item.tval == item_data.tval and inv_item.sval == item_data.sval and inv_item.name == item_data.name:
						idx = i
						item_data = inv_item  # Use the actual inventory reference
						break
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
		_cleanup_missing_utility_bindings()
		return true

	inventory.remove_at(idx)
	EventBus.item_dropped.emit(self, item_data, grid_position)
	_cleanup_missing_utility_bindings()
	return true

func equip_item(item_data: Variant, slot: String) -> bool:
	if not equipment.has(slot):
		return false

	# Unequip current item in slot
	if equipment[slot] != null:
		unequip_slot(slot)

	equipment[slot] = item_data
	inventory.erase(item_data)
	# Forge Intuition: auto-identify unidentified items on equip
	if has_forge_intuition() and "identified" in item_data and not item_data.identified:
		GameManager.identify_item(item_data)
		GameManager.log_message("Forge Intuition: You recognize the %s." % item_data.name, ThemeColors.MSG_INFO)
	EventBus.item_equipped.emit(self, item_data, slot)
	if slot == "weapon" or slot == "off_hand":
		_break_weapon_stances("Your stance resets with the weapon change.")
		_break_disguise("Your disguise slips as you adjust your gear.")
	_recalculate_stats()
	_cleanup_missing_utility_bindings()
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
	if slot == "weapon" or slot == "off_hand":
		_break_weapon_stances("Your stance resets with the weapon change.")
		_break_disguise("Your disguise slips as you adjust your gear.")
	_recalculate_stats()
	_cleanup_missing_utility_bindings()
	return true

func bind_utility_item(slot_index: int, item_data: Variant) -> bool:
	if slot_index < 0 or slot_index >= utility_hotkeys.size():
		return false
	if item_data == null or not ("index" in item_data) or not ("tval" in item_data):
		return false
	var descriptor: Dictionary = {
		"index": int(item_data.index),
		"tval": int(item_data.tval),
		"sval": int(item_data.sval) if "sval" in item_data else -1,
		"name": str(item_data.name) if "name" in item_data else "",
	}
	utility_hotkeys[slot_index] = descriptor
	return true

func clear_utility_item(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= utility_hotkeys.size():
		return
	utility_hotkeys[slot_index] = {}

func get_utility_descriptor(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= utility_hotkeys.size():
		return {}
	var desc: Variant = utility_hotkeys[slot_index]
	return desc if desc is Dictionary else {}

func resolve_utility_item(slot_index: int) -> Variant:
	var descriptor: Dictionary = get_utility_descriptor(slot_index)
	if descriptor.is_empty():
		return null

	# Prefer inventory first for consumables/hotswap handling.
	for item in inventory:
		if _matches_utility_descriptor(item, descriptor):
			return item
	for slot_key in equipment.keys():
		var eq_item = equipment.get(slot_key)
		if eq_item != null and _matches_utility_descriptor(eq_item, descriptor):
			return eq_item
	return null

func _matches_utility_descriptor(item_data: Variant, descriptor: Dictionary) -> bool:
	if item_data == null or descriptor.is_empty():
		return false
	if not ("index" in item_data) or not ("tval" in item_data):
		return false
	if int(item_data.index) != int(descriptor.get("index", -1)):
		return false
	if int(item_data.tval) != int(descriptor.get("tval", -1)):
		return false
	var descriptor_sval: int = int(descriptor.get("sval", -1))
	if descriptor_sval >= 0:
		var item_sval: int = int(item_data.sval) if "sval" in item_data else -2
		if item_sval != descriptor_sval:
			return false
	return true

func _cleanup_missing_utility_bindings() -> void:
	for i in range(utility_hotkeys.size()):
		var descriptor: Dictionary = get_utility_descriptor(i)
		if descriptor.is_empty():
			continue
		if resolve_utility_item(i) == null:
			utility_hotkeys[i] = {}

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

	if _finesse_stance_active:
		att += 1

	# Rapid Attack penalty: -3 when doing rapid double-attacks
	att += _rapid_attack_penalty

	# Assassination: +Stealth skill vs unwary/sleeping targets
	if has_ability(Constants.Skill.S_STL, Constants.StealthAbility.STL_ASSASSINATION):
		if is_instance_valid(target) and target is Monster:
			var mon: Monster = target as Monster
			if mon.alertness < Constants.ALERTNESS_ALERT:
				att += get_effective_skill("stealth")

	# Hunting duel loop: Mark Quarry + Focus stacks (target-locked).
	var marked: Monster = _get_marked_quarry()
	if marked != null and target == marked:
		att += HUNTING_MARK_ATTACK_BONUS
		att += _hunting_focus_stacks

	# Flanking: +1 per adjacent ally attacking same target
	att += _count_adjacent_allies_to(target)

	# Charge: +3 when moved straight toward target last action (requires ability)
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_CHARGE):
		if _is_charging_toward(target):
			att += 3

	# Opening Strike: +melee skill on first attack against each monster
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_OPENING_STRIKE):
		if is_instance_valid(target) and not _opening_strike_used.has(target.get_instance_id()):
			att += get_effective_skill("melee")

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

	# Song of Aule: +1 melee while singing (v4: was +2, now +1 damage die)
	if active_song_id == 152 or active_song_id_2 == 152:  # SONG_OF_AULE
		att += 1

	# ACCURATE equipment flag: +3 attack
	if has_equip_flag("ACCURATE"):
		att += 3

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
	var weapon = equipment.get("weapon")

	# Dodging: +3 if moved last turn and has EVN_DODGING
	if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_DODGING):
		if moved_last_turn:
			evn += 3

	# Defensive Stance: +3 evasion when not moved last turn
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_DEFENSIVE_STANCE):
		if not moved_last_turn:
			evn += 3

	# Surround pressure: -1 evasion per adjacent hostile beyond the first.
	# Circular Guard suppresses this penalty while active.
	if _circular_guard_turns <= 0:
		var adjacent_hostiles: int = _count_adjacent_monsters()
		if adjacent_hostiles > 1:
			var surround_penalty: int = adjacent_hostiles - 1
			if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_CROWD_FIGHTING):
				surround_penalty = maxi(0, surround_penalty / 2)
			evn -= surround_penalty
	else:
		evn += 2

	# Parry: double weapon's evasion contribution (Sil-Q: skill_equip_mod[S_EVN] += o_ptr->evn)
	if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_PARRY):
		if weapon != null and "evasion_bonus" in weapon:
			evn += weapon.evasion_bonus  # Add weapon evn again (first add is in recalculate_stats)

	# Song of Freedom: +3 evasion while singing
	if active_song_id == 147 or active_song_id_2 == 147:  # SONG_OF_FREEDOM
		evn += 3

	# Heavy Armour Use: remove heavy armor evasion penalty
	# (The base evasion_bonus already includes armor penalty; this adds back the penalty amount)
	if has_ability(Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_HEAVY_ARMOUR):
		evn += _get_heavy_armor_penalty()

	# Defensive stance toggle
	if _defensive_stance_active:
		evn += 5

	# Parry active window: grant weapon-scaled bonus
	if _parry_active_turns > 0:
		evn += get_parry_active_bonus()

	# Hardiness (Will): +1 protection-equivalent as evasion per 3 Will
	if has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_FORMIDABLE):
		evn += get_effective_skill("will") / 3

	# Hunting duel loop: marked quarry pressure grants mirrored defensive edge.
	var marked: Monster = _get_marked_quarry()
	if marked != null and attacker == marked:
		evn += HUNTING_MARK_EVASION_BONUS
		evn += _hunting_focus_stacks

	# Nimble Striker: evasion bonus from hit-and-run
	evn += _nimble_evn_bonus

	# Small Stature: +2 evasion vs large monsters (hard to hit small folk)
	if has_racial_flag("SMALL_STATURE") and is_instance_valid(attacker) and attacker is Monster:
		var mon: Monster = attacker as Monster
		if mon.is_large():
			evn += 2

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
	if _finesse_stance_active:
		threshold -= 30
	if has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_CONTROL):
		threshold -= 20
	if _power_stance_active:
		threshold += 10
	return threshold

## Power ability: extra damage die per hit
func _get_bonus_damage_dice() -> int:
	if _power_stance_active:
		return 2
	return 0

## Get slay bonus damage dice vs target based on equipped SLAY_* flags
func _get_slay_bonus_dice(target: Entity) -> int:
	if not is_instance_valid(target) or not target is Monster:
		return 0
	var mon: Monster = target as Monster
	if not mon.monster_data:
		return 0
	var bonus: int = 0
	# Each matching slay = +1 bonus weapon die
	if has_equip_flag("SLAY_ORC") and mon.monster_data.has_flag("ORC"):
		bonus += 1
	if has_equip_flag("SLAY_TROLL") and mon.monster_data.has_flag("TROLL"):
		bonus += 1
	if has_equip_flag("SLAY_SPIDER") and mon.monster_data.has_flag("SPIDER"):
		bonus += 1
	if has_equip_flag("SLAY_WOLF") and mon.monster_data.has_flag("WOLF"):
		bonus += 1
	if has_equip_flag("SLAY_UNDEAD") and mon.monster_data.has_flag("UNDEAD"):
		bonus += 1
	if has_equip_flag("SLAY_RAUKO") and mon.monster_data.has_flag("RAUKO"):
		bonus += 1
	if has_equip_flag("SLAY_DRAGON") and mon.monster_data.has_flag("DRAGON"):
		bonus += 1
	if has_equip_flag("SLAY_MAN_OR_ELF") and (mon.monster_data.has_flag("MAN") or mon.monster_data.has_flag("ELF")):
		bonus += 1
	return bonus

## Get brand bonus damage vs target based on equipped BRAND_* flags
func _get_brand_bonus_damage(target: Entity) -> int:
	if not is_instance_valid(target) or not target is Monster:
		return 0
	var mon: Monster = target as Monster
	var bonus: int = 0
	var dmg_dice: String = get_weapon_damage_dice()
	# Each brand = +1 weapon die, halved if target has matching resistance
	if has_equip_flag("BRAND_FIRE"):
		var brand_dmg: int = DataManager.roll_dice(dmg_dice)
		if mon.monster_data and mon.monster_data.has_flag("RES_FIRE"):
			brand_dmg = maxi(1, brand_dmg / 2)
		bonus += brand_dmg
	if has_equip_flag("BRAND_COLD"):
		var brand_dmg: int = DataManager.roll_dice(dmg_dice)
		if mon.monster_data and mon.monster_data.has_flag("RES_COLD"):
			brand_dmg = maxi(1, brand_dmg / 2)
		bonus += brand_dmg
	if has_equip_flag("BRAND_POIS"):
		var brand_dmg: int = DataManager.roll_dice(dmg_dice)
		if mon.monster_data and mon.monster_data.has_flag("RES_POIS"):
			brand_dmg = maxi(1, brand_dmg / 2)
		bonus += brand_dmg
	return bonus

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
		_register_hunting_pressure(target)

	# Exploit Opening: spend prepared burst on first successful hit against marked quarry.
	_apply_hunting_exploit_on_hit(target)

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
			# Always show "Charge!" on the player, even if target died
			vfx_floater("Charge!", ThemeColors.PRIMARY_BRIGHT, 16)
			if is_instance_valid(target):
				target.vfx_flash(ThemeColors.FLASH_CHARGE, 0.06, 0.15)
				target.vfx_particles(ThemeColors.PRIMARY, 6, 25.0, 0.3)

	# Light of the Eldar: bonus damage while the aura is active.
	if _is_light_of_eldar_active():
		if is_instance_valid(target) and target is Monster and target.current_health > 0:
			var mon: Monster = target as Monster
			if mon.monster_data and mon.monster_data.has_flag("HURT_LITE"):
				var light_dmg: int = maxi(1, get_effective_skill("lore") / 3)
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

	# Vampiric: heal for damage/2 (min 1) when dealing damage
	if has_equip_flag("VAMPIRIC") and damage > 0:
		var heal_amount: int = maxi(1, damage / 2)
		current_health = mini(current_health + heal_amount, max_health)
		GameManager.log_message("Your weapon drains life! (+%d HP)" % heal_amount, ThemeColors.MSG_HEAL)
		vfx_floater("+%d" % heal_amount, ThemeColors.DMG_HEAL, 14)

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

## Receive knockback from an external source. STAND_FAST blocks displacement.
## Returns true if knockback was resisted.
func receive_knockback(push_dir: Vector2i, _distance: int = 1) -> bool:
	# STAND_FAST blocks knockback displacement
	if has_equip_flag("STAND_FAST"):
		GameManager.log_message("You stand fast!", ThemeColors.PRIMARY)
		return true
	if not GameManager.current_level:
		return false
	var dest: Vector2i = grid_position + push_dir
	if GameManager.current_level.is_in_bounds(dest) and GameManager.current_level.is_passable(dest) and GameManager.current_level.get_entity_at(dest) == null:
		move_to(dest, false)
		GameManager.log_message("You are knocked back!", ThemeColors.MSG_WARNING)
	return false

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
	var ranged_weapon = equipment.get("bow")
	if ranged_weapon != null and "weight" in ranged_weapon:
		return ranged_weapon.weight
	return 30

## Override ranged attack to use archery skill instead of melee
func ranged_attack(target: Entity, distance: int) -> void:
	attacked_this_turn = true
	_break_disguise("Your disguise breaks as you fire.")
	# Archery-based attack: archery skill + DEX/2 + proficiency
	var att: int = skills["archery"] + (dexterity / 2)
	# Weapon proficiency bonus (BOW_PROFICIENCY or SLING_PROFICIENCY)
	att += _get_ranged_proficiency_bonus()
	# Hunting duel loop: mark pressure applies to ranged shots against your quarry.
	var marked: Monster = _get_marked_quarry()
	if marked != null and target == marked:
		att += HUNTING_MARK_ATTACK_BONUS
		att += _hunting_focus_stacks
	# Keen Eyes: +Hunting/2 to ranged attack
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_KEEN_EYES):
		att += get_effective_skill("hunting") / 2
	# Ambush: +Stealth to ranged attack vs unwary targets
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_AMBUSH):
		if is_instance_valid(target) and target is Monster:
			var mon: Monster = target as Monster
			if mon.alertness < Constants.ALERTNESS_ALERT:
				att += get_effective_skill("stealth")
	# Point Blank: +archery/2 at range 1 (melee range)
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_POINT_BLANK):
		if distance <= 1:
			att += get_effective_skill("archery") / 2
	# Distance penalty: -1 per tile beyond 1
	att -= maxi(0, distance - 1)
	# Steady Aim: +3 attack and +1 crit die when stationary and readied.
	var steady_aim_active: bool = trait_effect_id == "steady_aim" and _steady_aim_ready
	if steady_aim_active:
		att += 3

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

	# Steady Aim: +1 crit die when stationary/readied.
	if steady_aim_active:
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
		damage += get_effective_skill("archery") / 3

	target.take_damage(damage, "physical", self)
	_register_hunting_pressure(target)
	_apply_hunting_exploit_on_hit(target)

	# Crippling Shot (active): armed shot applies slow on hit then goes on cooldown.
	if _crippling_shot_armed and has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_CRIPPLING_SHOT):
		if is_instance_valid(target) and target.is_alive:
			# VFX: icy blue-white flash on target + impact particles + floater
			target.vfx_flash(ThemeColors.FLASH_CRIPPLE, 0.06, 0.2)
			target.vfx_particles(ThemeColors.STATUS_SLOW, 6, 25.0, 0.4)
			target.vfx_floater("Crippled!", ThemeColors.STATUS_SLOW, 16)
			target.apply_status("slow", 3 + randi_range(1, 3))
			GameManager.log_message("Your shot cripples %s!" % target.entity_name, ThemeColors.COMBAT_CRIT)
		_crippling_shot_armed = false
		_crippling_shot_cooldown = CRIPPLING_SHOT_COOLDOWN_TURNS

	# Rout: fleeing enemies take extra damage from ranged attacks
	if has_ability(Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_ROUT):
		if is_instance_valid(target) and target.is_alive and target is Monster:
			var mon: Monster = target as Monster
			if mon.current_morale < 0:
				var rout_dmg: int = maxi(1, get_effective_skill("archery") / 3)
				target.take_damage(rout_dmg, "physical", self)
				GameManager.log_message("Routing shot! (+%d)" % rout_dmg, ThemeColors.COMBAT_HIT)

## Get proficiency bonus for equipped ranged weapon
func _get_ranged_proficiency_bonus() -> int:
	var ranged_weapon = equipment.get("bow")
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

func _apply_hunting_exploit_on_hit(target: Entity) -> void:
	if not _hunting_exploit_armed or not is_instance_valid(target):
		return
	var marked: Monster = _get_marked_quarry()
	if marked == null or target != marked or target.current_health <= 0:
		return
	var exploit_bonus: int = 0
	var dice_str: String = get_weapon_damage_dice()
	for i in range(_hunting_exploit_bonus_dice):
		exploit_bonus += DataManager.roll_dice(dice_str)
	if _hunting_exploit_crit_bonus > 0:
		exploit_bonus += DataManager.roll_dice(dice_str)
	target.take_damage(exploit_bonus, "physical", self)
	GameManager.log_message("You exploit the opening! (+%d)" % exploit_bonus, ThemeColors.COMBAT_CRIT)
	target.vfx_floater("Exploit!", ThemeColors.GOLD_BRIGHT, 16)
	_hunting_exploit_armed = false
	_hunting_exploit_bonus_dice = 0
	_hunting_exploit_crit_bonus = 0

## Check if player can fire (has bow+arrows or sling+stones)
func can_fire_ranged() -> bool:
	var ranged_weapon = equipment.get("bow")
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
	var ranged_weapon = equipment.get("bow")
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

func direction_to_action(dir: Vector2i) -> int:
	match dir:
		Vector2i(0, -1): return Constants.ACTION_MOVE_N
		Vector2i(1, -1): return Constants.ACTION_MOVE_NE
		Vector2i(1, 0): return Constants.ACTION_MOVE_E
		Vector2i(1, 1): return Constants.ACTION_MOVE_SE
		Vector2i(0, 1): return Constants.ACTION_MOVE_S
		Vector2i(-1, 1): return Constants.ACTION_MOVE_SW
		Vector2i(-1, 0): return Constants.ACTION_MOVE_W
		Vector2i(-1, -1): return Constants.ACTION_MOVE_NW
	return Constants.ACTION_NOTHING

# ============================================================================
# STEALTH SYSTEM (Phase B)
# ============================================================================

## Get current stealth score for this turn (canon section 2.2)
func get_stealth_score() -> int:
	var score: int = get_effective_skill("stealth")
	# Stealth mode bonus
	if stealth_mode:
		score += Constants.STEALTH_MODE_BONUS
	# SMALL_STATURE: +2 stealth (enemies overlook small folk)
	if has_racial_flag("SMALL_STATURE"):
		score += 2
	# Disguise (active stance): +Stealth/3 bonus while maintained.
	if _disguise_active:
		score += get_effective_skill("stealth") / 3
	# Fade bonus (temporary boost after kill)
	score += _fade_bonus

	# Wayfarer's Instinct: reduce noise by 2 (min 0)
	var effective_noise: int = noise_this_turn
	if trait_effect_id == "wayfarers_instinct":
		effective_noise = maxi(0, effective_noise - 2)

	# Patient Stalker: +3 stealth when stealthing with no adjacent alert enemies
	if trait_effect_id == "patient_stalker" and stealth_mode and not _any_adjacent_alert_enemy():
		score += 3

	# Song of the Trees: +5 stealth while singing
	if active_song_id == 159 or active_song_id_2 == 159:  # SONG_OF_THE_TREES
		score += 5

	# Noise penalty
	score -= effective_noise
	return score

## Get effective perception/hunting skill (enhanced by stealth mode awareness)
func get_effective_perception() -> int:
	var base: int = get_effective_skill("hunting")
	if stealth_mode:
		base += Constants.STEALTH_MODE_PERCEPTION_BONUS
	return base

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
	if _disguise_active and amount >= 2:
		_break_disguise("The noise gives away your disguise.")
	# Also raise floor alertness
	if GameManager.current_level and GameManager.current_level.has_method("add_floor_noise"):
		GameManager.current_level.add_floor_noise(amount)

## Toggle stealth mode
func toggle_stealth_mode() -> void:
	stealth_mode = not stealth_mode
	if stealth_mode:
		GameManager.log_message("You enter stealth mode. (Moving at half speed)", ThemeColors.MSG_STEALTH)
	else:
		GameManager.log_message("You leave stealth mode.", ThemeColors.MSG_SYSTEM)

## Award 1 XP per newly explored tile while stealthed.
func award_stealth_exploration_xp(new_tiles: int) -> void:
	if stealth_mode and new_tiles > 0:
		gain_experience(new_tiles, "stealth_explore")

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

	# Keen Senses (active pulse): +1 light radius while active.
	if _keen_senses_turns > 0:
		base_radius += 1

	# Light of the Eldar (active aura): +2 baseline, plus small scaling from Lore.
	if _is_light_of_eldar_active():
		base_radius += 2 + (get_effective_skill("lore") / 6)

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

func _is_light_of_eldar_active() -> bool:
	return has_meta("light_of_eldar_active") and bool(get_meta("light_of_eldar_active"))

func on_enemy_detected() -> void:
	_break_disguise("Your disguise fails as enemies lock onto you.")

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
						if try_move(rdir):
							record_action(direction_to_action(rdir))
						return true
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
				if try_move(flee_dir):
					record_action(direction_to_action(flee_dir))
				return true
			# No flee direction available, allow normal movement

	var direction := _get_movement_input()
	if direction != Vector2i.ZERO:
		moved_this_turn = true
		var did_move: bool = try_move(direction)
		if did_move:
			record_action(direction_to_action(direction))
		return did_move or attacked_this_turn

	if Input.is_action_just_pressed("wait"):
		return true  # Skip turn

	if Input.is_action_just_pressed("pickup"):
		return try_pickup()

	# Stealth mode toggle (';' key)
	if Input.is_action_just_pressed("toggle_stealth"):
		toggle_stealth_mode()
		return false  # Toggling stealth doesn't cost a turn

	# Quaff/Eat/Horn are now handled by main.gd item selection menus (Q/comma/P keys)

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

	var per: int = get_effective_skill("hunting")
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
			# Bump attack if it's a monster.
			if blocker is Monster:
				attacked_this_turn = true
				_break_disguise("Your disguise breaks as you strike.")
				# Swift Strikes: armed flurry, two attacks at -2 each with cooldown.
				if _swift_strikes_armed and has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_RAPID_ATTACK):
					_rapid_attack_penalty = -2
					attack_entity(blocker)
					if is_instance_valid(blocker) and blocker.is_alive:
						attack_entity(blocker)
					_rapid_attack_penalty = 0
					_swift_strikes_armed = false
					_swift_strikes_cooldown = SWIFT_STRIKES_COOLDOWN_TURNS
				else:
					attack_entity(blocker)
				return false
			# Talk to NPC if bumped (duck-typing: NPCs expose interact()).
			if blocker.has_method("interact"):
				_interact_with_npc(blocker)
				return false
			return false

	return true

func move_to(target: Vector2i, animate: bool = true) -> void:
	var move_dir: Vector2i = target - grid_position
	if _defensive_stance_active:
		_break_defensive_stance()
	super.move_to(target, animate)
	_register_sprint_momentum(move_dir)

func _register_sprint_momentum(move_dir: Vector2i) -> void:
	if move_dir == Vector2i.ZERO:
		return
	var step_dir: Vector2i = Vector2i(int(sign(move_dir.x)), int(sign(move_dir.y)))
	if _sprint_charge_dir == step_dir:
		_sprint_charge_steps = mini(_sprint_charge_steps + 1, 3)
	else:
		_sprint_charge_dir = step_dir
		_sprint_charge_steps = 1
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
	# FREE_ACT blocks paralysis and entrance
	if status_name in ["paralyze", "paralysis", "entrance", "entranced"] and has_equip_flag("FREE_ACT"):
		GameManager.log_message("You resist the effect!", ThemeColors.PRIMARY)
		return

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
	if run_stats:
		run_stats.record_forensic_event(
			GameManager.turn_count,
			"status",
			"Afflicted: %s (%d turns)" % [status_name, reduced_dur],
			"warning"
		)

func take_damage(amount: int, damage_type: String = "physical", source: Entity = null) -> void:
	was_attacked_this_turn = true
	_break_disguise("A sudden threat exposes your disguise.")
	var incoming_amount: int = amount
	var hp_before: int = current_health

	# Record last damage source for telemetry
	if run_stats:
		run_stats.last_damage_type = damage_type
		if is_instance_valid(source):
			run_stats.last_damage_source_name = source.entity_name
			if source is Monster and source.monster_data and "id" in source.monster_data:
				run_stats.last_damage_source_id = source.monster_data.id
			else:
				run_stats.last_damage_source_id = -1
		else:
			run_stats.last_damage_source_name = ""
			run_stats.last_damage_source_id = -1

	# Parry reaction
	if _parry_ready:
		amount = _resolve_parry_hit(amount)

	# Elemental resistance: halve matching damage types
	var mitigation_reason: String = ""
	if damage_type == "fire" and has_equip_flag("RES_FIRE"):
		amount = maxi(1, amount / 2)
		mitigation_reason = "RES_FIRE"
		GameManager.log_message("Your fire resistance absorbs the heat!", ThemeColors.PRIMARY)
	elif damage_type == "cold" and has_equip_flag("RES_COLD"):
		amount = maxi(1, amount / 2)
		mitigation_reason = "RES_COLD"
		GameManager.log_message("Your cold resistance wards off the chill!", ThemeColors.PRIMARY)
	elif damage_type == "poison" and has_equip_flag("RES_POIS"):
		amount = maxi(1, amount / 2)
		mitigation_reason = "RES_POIS"
		GameManager.log_message("Your poison resistance filters the venom!", ThemeColors.PRIMARY)

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
			var save_chance: int = get_effective_skill("will") * 3
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
	if run_stats:
		var src_name: String = source.entity_name if is_instance_valid(source) else "unknown source"
		var details: String = ""
		if not mitigation_reason.is_empty():
			details = " mitigated by %s" % mitigation_reason
		var hp_after: int = current_health
		run_stats.record_forensic_event(
			GameManager.turn_count,
			"damage",
			"Took %d %s damage from %s (incoming %d, HP %d->%d)%s" % [amount, damage_type, src_name, incoming_amount, hp_before, hp_after, details],
			"critical" if current_health <= 0 else "warning"
		)

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
			if run_stats and "last_attack_effect" in killer:
				run_stats.killer_attack_effect = str(killer.last_attack_effect)
	elif run_stats and not run_stats.last_damage_type.is_empty():
		run_stats.killer_attack_effect = "DAMAGE_%s" % run_stats.last_damage_type.to_upper()

	if run_stats:
		var floor_alert: int = 0
		var visible_hostiles: int = 0
		if GameManager.current_level:
			if GameManager.current_level.has_method("get_floor_alertness"):
				floor_alert = int(GameManager.current_level.get_floor_alertness())
			for entity in GameManager.current_level.entities:
				if is_instance_valid(entity) and entity is Monster and entity.is_alive and GameManager.current_level.is_tile_visible(entity.grid_position):
					visible_hostiles += 1
		var stealth_state: String = "Hidden" if stealth_mode else "Revealed"
		run_stats.record_forensic_event(
			GameManager.turn_count,
			"context",
			"Final state: HP %d/%d, %s, visible hostiles %d, floor alert %d" % [current_health, max_health, stealth_state, visible_hostiles, floor_alert],
			"critical"
		)

	run_stats.record_death(cause, killer_name, killer_id)
	run_stats.record_forensic_event(
		GameManager.turn_count,
		"death",
		"Fatal blow by %s" % cause,
		"critical"
	)

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
	var was_silent: bool = monster != null and monster.alertness < Constants.ALERTNESS_ALERT
	run_stats.record_kill(monster.entity_name, monster.experience_value, was_silent)

	# Oath of Enmity: lock onto first kill's type as oath target
	if trait_effect_id == "oath_of_enmity" and _oath_target_type.is_empty():
		_oath_target_type = monster.entity_name
		GameManager.log_message("You swear an oath against all %s!" % _oath_target_type, ThemeColors.PRIMARY)
