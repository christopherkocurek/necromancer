extends CanvasLayer
## Contextual tutorial hint system. Shows hints once per save.

var _shown_hints: Dictionary = {}  # hint_id -> true
var _hint_panel: PanelContainer
var _hint_label: Label
var _dismiss_timer: Timer
var _is_showing: bool = false
const HINTS_PATH := "user://tutorial_hints.cfg"
const TUTORIAL_PATH := "user://tutorial_state.cfg"

const TUTORIAL_STEPS: Array[Dictionary] = [
	{
		"id": "move",
		"text": "[Tutorial] Move a few tiles with WASD or Arrow keys to orient yourself.",
	},
	{
		"id": "pickup",
		"text": "[Tutorial] Pick up an item with [G].",
	},
	{
		"id": "survive_hit",
		"text": "[Tutorial] You have tasted danger. Use [Shift+Q] or [,] to stabilize.",
	},
	{
		"id": "stairs",
		"text": "[Tutorial] Find stairs and press [Enter] to transition floors.",
	},
]

var _tutorial_state: Dictionary = {
	"enabled": true,
	"current_step": 0,
	"completed": {},
	"spawn_depth1_x": -1,
	"spawn_depth1_y": -1,
}
var _gandalf_guidance_enabled: bool = false
var _gandalf_intro_complete: bool = false
var _gandalf_cutoff_announced: bool = false
var _gandalf_session_nonce: int = 0
var _gandalf_seen_tokens: Dictionary = {}
var _gandalf_last_hint_turn: int = -9999
var _gandalf_threat_signals: Dictionary = {}
var _player_took_damage_once: bool = false
var _gandalf_scroll_tutorial: Dictionary = {
	"scroll_granted": false,
	"tome_opened": false,
	"stealth_skill_invested": false,
	"stealth_chapter_opened": false,
	"ability_purchased": false,
	"assassination_taken": false,
	"disguise_taken": false,
	"pending_bind_after_tome": false,
	"bind_prompted": false,
	"bind_menu_seen": false,
	"ability_bound": false,
	"ability_used": false,
}
var _tutorial_milestones: Dictionary = {
	"moved": false,
	"opened_scroll": false,
	"opened_inventory": false,
	"bound_first_gem": false,
	"used_first_gem": false,
	"entered_stealth": false,
	"rested_below_half": false,
	"saw_broodmother": false,
}
var _tutorial_expectations: Dictionary = {}  # id -> {set_turn, deadline_turn, retry_text, completed}
var _mentor_confidence_score: int = 0
var _tutorial_analytics: Dictionary = {
	"hints_shown": 0,
	"expectations_set": 0,
	"expectations_met": 0,
	"expectations_missed": 0,
	"last_hint_token": "",
	"last_hint_turn": -1,
}
const TUTORIAL_ANALYTICS_PATH := "user://tutorial_analytics.log"
const GANDALF_HINT_COOLDOWN_TURNS: int = 14
const GANDALF_GUIDANCE_DEPTH_CUTOFF: int = 4
const GANDALF_PRIORITY_CRITICAL: int = 100
const GANDALF_PRIORITY_HIGH: int = 80
const GANDALF_PRIORITY_MEDIUM: int = 50
const GANDALF_PRIORITY_LOW: int = 20
const GANDALF_STEP_TEXT: Dictionary = {
	"move": "Take a few careful steps with WASD or the Arrow-keys, and learn the ground beneath you before you wager your life upon it.",
	"pickup": "Gather what the dark has left behind. A small tool in hand is better than a great hope in mind.",
	"survive_hit": "You have felt their malice now. Heal, breathe, and choose where the next fight is fought.",
	"stairs": "When you are steady, descend. Do not race the dark; master one danger at a time.",
}
const GANDALF_LAYER1_BRIEFING: String = "Remember this: there is no friendly shop and no safe bed in this tower. Spend what you must to live, then go down only when your footing is sure."
const GANDALF_SCROLL_FOUNDATION_LINE: String = "Skill is the foundation upon which you survive. Abilities are the answers you wield when trouble turns ill. Keep both in balance, if you would endure the Necromancer's Tower."

func _ready() -> void:
	layer = 15
	_setup_ui()
	_load_hints()
	_load_tutorial_state()
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_tick.connect(_on_status_tick)
	EventBus.entity_moved.connect(_on_entity_moved)
	EventBus.ability_used.connect(_on_ability_used)
	EventBus.level_entered.connect(_on_level_entered)

func _setup_ui() -> void:
	_hint_panel = PanelContainer.new()
	_hint_panel.visible = false
	var style := ThemeColors.create_panel_stylebox(Color(ThemeColors.BG_SURFACE, 0.9), ThemeColors.PRIMARY_DIM, 1, 8)
	_hint_panel.add_theme_stylebox_override("panel", style)
	# Position is computed dynamically so the panel sits centered in the top third.
	_hint_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hint_panel.custom_minimum_size = Vector2(760, 0)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_label.custom_minimum_size = Vector2(720, 0)
	ThemeColors.apply_heading_font(_hint_label, ThemeColors.FONT_SIZE_BODY)
	_hint_label.add_theme_color_override("font_color", ThemeColors.GOLD_WARM)
	_hint_panel.add_child(_hint_label)
	add_child(_hint_panel)

	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.timeout.connect(_hide_hint)
	add_child(_dismiss_timer)

	var vp: Viewport = get_viewport()
	if vp and not vp.size_changed.is_connected(_reposition_hint_panel):
		vp.size_changed.connect(_reposition_hint_panel)
	_reposition_hint_panel()

func show_hint(hint_id: String, text: String, duration_sec: float = 5.0) -> void:
	if AccessibilityManager and AccessibilityManager.has_method("is_assist_enabled"):
		if not AccessibilityManager.is_assist_enabled():
			return
	_show_hint_internal(hint_id, text, duration_sec, true)

func show_forced_hint(hint_id: String, text: String, duration_sec: float = 5.0, remember_once: bool = true) -> void:
	_show_hint_internal(hint_id, text, duration_sec, remember_once)

func _show_hint_internal(hint_id: String, text: String, duration_sec: float, remember_once: bool) -> void:
	if remember_once:
		if _shown_hints.has(hint_id):
			return
		_shown_hints[hint_id] = true
		_save_hints()
	_hint_label.text = text
	call_deferred("_reposition_hint_panel")
	_hint_panel.visible = true
	_hint_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_hint_panel, "modulate:a", 1.0, 0.3)
	_dismiss_timer.start(maxf(0.25, duration_sec))
	_is_showing = true

func _assist_level() -> String:
	if not AccessibilityManager:
		return "full"
	return AccessibilityManager.assist_level

func _hide_hint() -> void:
	var tween := create_tween()
	tween.tween_property(_hint_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): _hint_panel.visible = false; _is_showing = false)

func _reposition_hint_panel() -> void:
	if _hint_panel == null:
		return
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var panel_width: float = clampf(viewport_size.x * 0.62, 560.0, 920.0)
	_hint_panel.custom_minimum_size.x = panel_width
	_hint_label.custom_minimum_size.x = panel_width - 40.0
	_hint_panel.reset_size()
	var panel_size: Vector2 = _hint_panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = _hint_panel.get_combined_minimum_size()
	var top_third_center_y: float = viewport_size.y / 6.0
	_hint_panel.position = Vector2(
		(viewport_size.x - panel_size.x) * 0.5,
		top_third_center_y - panel_size.y * 0.5
	)

func start_gandalf_guidance_session(enabled: bool) -> void:
	_gandalf_guidance_enabled = enabled
	_gandalf_intro_complete = false
	_gandalf_cutoff_announced = false
	_gandalf_session_nonce = randi()
	_gandalf_seen_tokens.clear()
	_gandalf_last_hint_turn = -9999
	_gandalf_threat_signals.clear()
	_player_took_damage_once = false
	_gandalf_scroll_tutorial = {
		"scroll_granted": false,
		"tome_opened": false,
		"stealth_skill_invested": false,
		"stealth_chapter_opened": false,
		"ability_purchased": false,
		"assassination_taken": false,
		"disguise_taken": false,
		"pending_bind_after_tome": false,
		"bind_prompted": false,
		"bind_menu_seen": false,
		"ability_bound": false,
		"ability_used": false,
	}
	if not enabled:
		return
	_tutorial_state["enabled"] = true
	_tutorial_state["current_step"] = 0
	_tutorial_state["completed"] = {}
	_tutorial_state["spawn_depth1_x"] = -1
	_tutorial_state["spawn_depth1_y"] = -1
	_save_tutorial_state()

func on_gandalf_intro_complete() -> void:
	if not _gandalf_guidance_enabled:
		return
	_gandalf_intro_complete = true
	_show_gandalf_once(
		"intro_complete",
		_gandalf_line("I will guide you while I may. Below the fourth depth, the Shadow will sever my counsel. %s Walk now with WASD or the Arrow-keys, and keep your feet under you. When you are ready, open the ancient scroll with [T] and shape your craft." % GANDALF_LAYER1_BRIEFING),
		true
	)
	_set_expectation("open_scroll_t", "Press [T] and open the ancient scroll now.", 20)
	_show_current_tutorial_step()

func on_gandalf_scroll_granted() -> void:
	if not _gandalf_guidance_enabled:
		return
	_gandalf_scroll_tutorial["scroll_granted"] = true
	GameManager.log_message("Gandalf places an ancient scroll in your hands.", ThemeColors.GOLD_BRIGHT)

func on_tome_opened(tome_panel: Control) -> void:
	if not _is_gandalf_guidance_active():
		return
	_mark_milestone("opened_scroll")
	_complete_expectation("open_scroll_t")
	if bool(_gandalf_scroll_tutorial.get("tome_opened", false)):
		return
	_gandalf_scroll_tutorial["tome_opened"] = true
	_show_gandalf_once("tome_first_open", _gandalf_line(GANDALF_SCROLL_FOUNDATION_LINE), true, 8.0)
	if tome_panel:
		if tome_panel.has_method("pulse_skill_plus"):
			tome_panel.call_deferred("pulse_skill_plus", "stealth", 3)
		var tween := create_tween()
		tween.tween_interval(0.65)
		tween.tween_callback(func():
			if tome_panel and is_instance_valid(tome_panel) and tome_panel.has_method("pulse_skill_row"):
				tome_panel.call("pulse_skill_row", "stealth", 3)
		)
	var hint_tween := create_tween()
	hint_tween.tween_interval(8.6)
	hint_tween.tween_callback(func():
		_show_gandalf_once(
			"tome_press_stealth_row",
			_gandalf_line("Put a point into Stealth by pressing the + button, then click the word Stealth to gain your first ability."),
			true,
			4.0
		)
	)

func on_tome_skill_increased(skill_name: String, tome_panel: Control) -> void:
	if not _is_gandalf_guidance_active():
		return
	if skill_name.to_lower() != "stealth":
		return
	_gandalf_scroll_tutorial["stealth_skill_invested"] = true
	_show_gandalf_once(
		"tome_stealth_invested",
		_gandalf_line("Good. A sound foundation. Now open the Stealth chapter and choose an ability worthy of that craft.")
	)
	if tome_panel and tome_panel.has_method("pulse_skill_row"):
		tome_panel.call_deferred("pulse_skill_row", "stealth", 2)

func on_tome_chapter_opened(skill_name: String, tome_panel: Control) -> void:
	if not _is_gandalf_guidance_active():
		return
	if skill_name.to_lower() != "stealth":
		return
	if bool(_gandalf_scroll_tutorial.get("stealth_chapter_opened", false)):
		return
	_gandalf_scroll_tutorial["stealth_chapter_opened"] = true
	_show_gandalf_once(
		"tome_stealth_chapter_opened",
		_gandalf_line("Begin with Disguise. It is your first active Stealth art, and you can bind it to a gem for quick use.")
	)
	if tome_panel and tome_panel.has_method("pulse_ability_by_name"):
		tome_panel.call_deferred("pulse_ability_by_name", "Disguise", 3)

func on_tome_ability_purchased(ability_name: String, tome_panel: Control = null) -> void:
	if not _is_gandalf_guidance_active():
		return
	var picked: String = ability_name.to_lower().strip_edges()
	if picked == "disguise":
		_gandalf_scroll_tutorial["disguise_taken"] = true
		_show_gandalf_once(
			"disguise_taken_next_assassination",
			_gandalf_line("Well chosen. Now take Assassination: it is a passive edge that deepens every strike against the unwary."),
			true
		)
		if tome_panel and tome_panel.has_method("pulse_ability_by_name"):
			tome_panel.call_deferred("pulse_ability_by_name", "Assassination", 3)
		return
	if picked == "assassination":
		_gandalf_scroll_tutorial["assassination_taken"] = true
		if bool(_gandalf_scroll_tutorial.get("disguise_taken", false)):
			_gandalf_scroll_tutorial["ability_purchased"] = true
			_gandalf_scroll_tutorial["pending_bind_after_tome"] = true
			_show_gandalf_once(
				"assassination_after_disguise_close_scroll",
				_gandalf_line("Good. You have both arts. Close the scroll now, and in the field view I will show you how to bind Disguise to a gem."),
				true
			)
		else:
			_show_gandalf_once(
				"assassination_taken_need_disguise",
				_gandalf_line("Assassination will serve you well. Now inscribe Disguise, that you may bind a Stealth art to a gem."),
				true
			)
			if tome_panel and tome_panel.has_method("pulse_ability_by_name"):
				tome_panel.call_deferred("pulse_ability_by_name", "Disguise", 3)
		return
	if bool(_gandalf_scroll_tutorial.get("stealth_chapter_opened", false)):
		_show_gandalf_once(
			"stealth_pick_disguise_reminder",
			_gandalf_line("Take Disguise first, then Assassination."),
			true
		)

func on_ability_bind_menu_opened(bind_slot: int) -> void:
	if not _is_gandalf_guidance_active():
		return
	if not bool(_gandalf_scroll_tutorial.get("bind_prompted", false)):
		return
	if bool(_gandalf_scroll_tutorial.get("bind_menu_seen", false)):
		return
	_gandalf_scroll_tutorial["bind_menu_seen"] = true
	_show_gandalf_once(
		"gem_bind_menu_seen",
		_gandalf_line("Choose wisely. This gem will carry that answer at your fingertips. Select Disguise for quick survival control."),
		true,
		4.0,
		GANDALF_PRIORITY_HIGH
	)
	if GameManager and GameManager.has_method("log_message"):
		GameManager.log_message("Binding for gem %d: choose an ability from the menu." % (bind_slot + 1), ThemeColors.MSG_SYSTEM)
	_show_gandalf_once(
		"hotbar_bind_detail",
		_gandalf_line("Hotbar method: empty gem, choose the art, then use that gem number to invoke it."),
		true,
		4.0,
		GANDALF_PRIORITY_HIGH
	)
	_set_expectation(
		"bind_gem",
		"Bind Disguise to this gem, then return to the field.",
		14
	)

func on_ability_bound_to_gem(slot_index: int, _ability_id: int, ability_name: String, hud: CanvasLayer) -> void:
	if not _is_gandalf_guidance_active():
		return
	_mark_milestone("bound_first_gem")
	_complete_expectation("bind_gem")
	_gandalf_scroll_tutorial["ability_bound"] = true
	_show_gandalf_once(
		"gem_bound_use_now",
		_gandalf_line("It is done. %s now rests in gem %d. Use key [%d], or click the gem, when the moment is right.") % [ability_name, slot_index + 1, slot_index + 1],
		true
	)
	if hud and hud.has_method("pulse_hotbar_slot"):
		hud.call("pulse_hotbar_slot", slot_index, 3)
	_set_expectation(
		"use_gem",
		"Use your bound gem now with its number key, or click the gem.",
		16
	)

func on_ability_cast_from_gem(ability_id: int) -> void:
	if not _is_gandalf_guidance_active():
		return
	_mark_milestone("used_first_gem")
	_complete_expectation("use_gem")
	if not bool(_gandalf_scroll_tutorial.get("ability_bound", false)):
		return
	if bool(_gandalf_scroll_tutorial.get("ability_used", false)):
		return
	_gandalf_scroll_tutorial["ability_used"] = true
	_show_gandalf_once(
		"gem_cast_confirmed",
		_gandalf_line("Well used. Keep one hand for movement, and one for answers. That is how you live in this place."),
		true
	)
	if ability_id == Player.GEM_DISGUISE:
		var player_node: Node = GameManager.player if GameManager else null
		if player_node and "stealth_mode" in player_node and not bool(player_node.stealth_mode):
			_show_gandalf_once(
				"disguise_then_sneak",
				_gandalf_line("Now sneak. Press [;] to enter stealth mode. In stealth you move more slowly, but you are harder to notice, and your attacks against the unwary are far deadlier."),
				true,
				4.0,
				GANDALF_PRIORITY_HIGH
			)
			_set_expectation(
				"enter_stealth",
				"Press [;] now and move as a shadow.",
				12
			)

func on_tome_closed() -> void:
	if not _is_gandalf_guidance_active():
		return
	if bool(_gandalf_scroll_tutorial.get("tome_opened", false)) and not bool(_gandalf_scroll_tutorial.get("stealth_chapter_opened", false)):
		_show_gandalf_once(
			"tome_closed_before_chapter",
			_gandalf_line("Open the scroll again with [T], and press the Stealth chapter-name to view its abilities.")
		)
		return
	if bool(_gandalf_scroll_tutorial.get("pending_bind_after_tome", false)) and not bool(_gandalf_scroll_tutorial.get("bind_prompted", false)):
		_gandalf_scroll_tutorial["bind_prompted"] = true
		_show_gandalf_once(
			"gem_bind_after_tome_close_specific",
			_gandalf_line("Now to binding. Left-click an empty gem in the bar, or press its number while empty. Choose Disguise from the list. Then use that same number key, or click the gem, to invoke it."),
			true
		)
		return
	if bool(_gandalf_scroll_tutorial.get("stealth_chapter_opened", false)) and not bool(_gandalf_scroll_tutorial.get("bind_prompted", false)):
		var player_node: Node = GameManager.player if GameManager else null
		if _has_any_bindable_gem_ability(player_node):
			_gandalf_scroll_tutorial["bind_prompted"] = true
			_show_gandalf_once(
				"gem_bind_after_tome_close",
			_gandalf_line("You are ready. Bind one learned ability to an empty gem now: click the gem, choose the art, then use that number key to invoke it."),
				true
			)

func on_inventory_opened() -> void:
	_mark_milestone("opened_inventory")
	_complete_expectation("open_inventory")
	if _is_gandalf_guidance_active():
		_show_gandalf_once(
			"inventory_opened_confirm",
			_gandalf_line("Good. This is your pack. Use [I] to manage curatives, tools, and loads for your utility and gem decisions."),
			true,
			4.0,
			GANDALF_PRIORITY_HIGH
		)

func on_inventory_closed() -> void:
	pass

func _has_any_bindable_gem_ability(player_node: Node) -> bool:
	if not player_node or not player_node.has_method("has_ability"):
		return false
	var checks: Array = [
		[Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_DEFENSIVE_STANCE],
		[Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_PARRY],
		[Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK],
		[Constants.Skill.S_PER, Constants.PerceptionAbility.PER_BANE],
		[Constants.Skill.S_PER, Constants.PerceptionAbility.PER_MASTER_HUNTER],
		[Constants.Skill.S_STL, Constants.StealthAbility.STL_DISGUISE],
		[Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_CROWD_FIGHTING],
		[Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_RAPID_ATTACK],
		[Constants.Skill.S_ARC, Constants.ArcheryAbility.ARC_CRIPPLING_SHOT],
		[Constants.Skill.S_PER, Constants.PerceptionAbility.PER_KEEN_SENSES],
		[Constants.Skill.S_WIL, Constants.WillAbility.WIL_CURSE_BREAKING],
		[Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_POWER],
		[Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FINESSE],
		[Constants.Skill.S_STL, Constants.StealthAbility.STL_VANISH],
		[Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_SPRINTING],
	]
	for pair in checks:
		if bool(player_node.has_ability(int(pair[0]), int(pair[1]))):
			return true
	return false

func _gandalf_line(text: String) -> String:
	return "Gandalf: %s" % text

func _is_gandalf_guidance_active() -> bool:
	if not _gandalf_guidance_enabled or not _gandalf_intro_complete:
		return false
	return int(GameManager.current_depth) <= GANDALF_GUIDANCE_DEPTH_CUTOFF

func _show_gandalf_once(token: String, text: String, bypass_cooldown: bool = false, duration_sec: float = 5.0, priority: int = GANDALF_PRIORITY_MEDIUM) -> void:
	if token.is_empty() or text.is_empty():
		return
	if _gandalf_seen_tokens.has(token):
		return
	if _should_suppress_noncritical(priority, token):
		return
	var turn_now: int = int(GameManager.turn_count) if GameManager else 0
	var force_now: bool = priority >= GANDALF_PRIORITY_HIGH
	if not bypass_cooldown and not force_now and turn_now - _gandalf_last_hint_turn < GANDALF_HINT_COOLDOWN_TURNS:
		return
	_gandalf_seen_tokens[token] = true
	_gandalf_last_hint_turn = turn_now
	show_hint("gandalf_%s_%d" % [token, _gandalf_session_nonce], text, duration_sec)
	_tutorial_analytics["hints_shown"] = int(_tutorial_analytics.get("hints_shown", 0)) + 1
	_tutorial_analytics["last_hint_token"] = token
	_tutorial_analytics["last_hint_turn"] = turn_now
	_append_tutorial_analytics("HINT %s t=%d p=%d" % [token, turn_now, priority])

func _enforce_gandalf_depth_policy() -> void:
	if not _gandalf_guidance_enabled or not _gandalf_intro_complete:
		return
	var depth: int = int(GameManager.current_depth)
	if depth <= GANDALF_GUIDANCE_DEPTH_CUTOFF:
		return
	if not _gandalf_cutoff_announced:
		_show_gandalf_once(
			"cutoff",
			_gandalf_line("The dark runs too deep here. My voice cannot reach you now. Trust your craft, and endure."),
			true
		)
		_gandalf_cutoff_announced = true
	_gandalf_guidance_enabled = false

func check_hints(player_node: Node) -> void:
	if AccessibilityManager and AccessibilityManager.has_method("is_assist_enabled"):
		if not AccessibilityManager.is_assist_enabled():
			return
	_enforce_gandalf_depth_policy()
	if not player_node or _is_showing:
		return
	_check_tutorial_scaffold(player_node)
	_check_gandalf_interface_coaching(player_node)
	_check_gandalf_layer1_coaching(player_node)
	_check_gandalf_outer_pits_explainers(player_node)
	_check_tutorial_expectations(player_node)
	if "stealth_mode" in player_node and bool(player_node.stealth_mode):
		_mark_milestone("entered_stealth")
		_complete_expectation("enter_stealth")
	if "current_health" in player_node and "max_health" in player_node and _is_gandalf_guidance_active():
		var hp_now_50: int = int(player_node.current_health)
		var hp_max_50: int = int(maxi(player_node.max_health, 1))
		if hp_now_50 * 2 < hp_max_50:
			_show_gandalf_once(
				"first_below_half_rest",
				_gandalf_line("You are bloodied. Press [Z] and rest when no eyes are upon you; do not carry half a life into the next chamber.%s" % _why_now_clause(player_node)),
				false,
				4.0
			)
			_set_expectation(
				"rest_after_half",
				"Rest with [Z] after this danger passes.",
				18
			)
		if bool(_tutorial_expectations.get("rest_after_half", {}).get("completed", false)) == false:
			if hp_now_50 * 2 >= hp_max_50 and _gandalf_seen_tokens.has("first_below_half_rest"):
				_mark_milestone("rested_below_half")
				_complete_expectation("rest_after_half")
	# HP < 30%
	if "current_health" in player_node and "max_health" in player_node:
		if float(player_node.current_health) / float(maxi(player_node.max_health, 1)) < 0.3:
			if _is_gandalf_guidance_active():
				_show_gandalf_once("low_hp", _gandalf_line("Cast not your life away. Heal now, then choose the ground of the next clash.%s" % _why_now_clause(player_node)), false, 4.0, GANDALF_PRIORITY_CRITICAL)
			else:
				show_hint("low_hp", "Use potions [Shift+Q] or herbs [,] to heal")
	# XP >= first skill cost (Full assist only)
	if _assist_level() == "full":
		if "xp_available" in player_node and player_node.xp_available >= 500:
			if _is_gandalf_guidance_active():
				_check_gandalf_xp_advisor(player_node)
			else:
				show_hint("can_buy_skill", "Press [@] to open Skills and spend XP")
	# Stealth mode available
	if _assist_level() == "full" and "stealth_mode" in player_node and not player_node.stealth_mode:
		# Check for nearby unwary monster
		if GameManager.current_level:
			for entity in GameManager.current_level.entities:
				if is_instance_valid(entity) and entity is Monster and entity.is_alive:
					if "alertness" in entity and entity.alertness < 5:
						var dist: int = max(abs(entity.grid_position.x - player_node.grid_position.x), abs(entity.grid_position.y - player_node.grid_position.y))
						if dist <= 5:
							if _is_gandalf_guidance_active():
								_show_gandalf_once("stealth_mode", _gandalf_line("Now be a shadow. Enter stealth with [;] before you close with them."))
							else:
								show_hint("stealth_hint", "Press [;] for stealth mode")
							break

func _check_gandalf_interface_coaching(player_node: Node) -> void:
	if not _is_gandalf_guidance_active():
		return
	if "inventory" in player_node:
		var inv_variant: Variant = player_node.inventory
		if inv_variant is Array and (inv_variant as Array).size() > 0:
			_show_gandalf_once(
				"inventory_basics",
				_gandalf_line("Open your pack with [I]. Keep curatives and tools close; what you carry, and how swiftly you reach it, decides many battles."),
				false,
				4.0
			)
			_set_expectation(
				"open_inventory",
				"Open your inventory with [I].",
				24
			)
	if _has_any_bindable_gem_ability(player_node):
		_show_gandalf_once(
			"hotbar_basics",
			_gandalf_line("Mark this gem-row well: [1]-[8] invoke bound arts. An empty gem can be bound by pressing its number or by clicking it."),
			false,
			4.0
		)

func _check_gandalf_layer1_coaching(player_node: Node) -> void:
	if not _is_gandalf_guidance_active():
		return
	if int(GameManager.current_depth) != 1:
		return
	if not GameManager.current_level:
		return

	var visible_hostiles: int = _count_visible_hostiles(player_node)
	if visible_hostiles >= 2:
		_record_gandalf_threat_signal("pack")
		_show_gandalf_once("pack_chokepoint", _gandalf_line("Do not meet a pack in the open. Fall back to a doorway or a narrow hall, and make them come one by one."))
		return

	if "current_health" in player_node and "max_health" in player_node:
		var hp_now: int = int(player_node.current_health)
		var hp_max: int = int(maxi(player_node.max_health, 1))
		if hp_now < hp_max and visible_hostiles == 0:
			_show_gandalf_once("safe_rest", _gandalf_line("No eyes are upon you. Rest now and mend, before the next chamber tries you."))
			return

	if "xp_available" in player_node and int(player_node.xp_available) >= 1200 and visible_hostiles > 0:
		_show_gandalf_once("reactive_xp", _gandalf_line("Now is the hour to spend. Buy the answer to what is killing you, and go forward."))
		return

	if "inventory" in player_node:
		var inv_variant: Variant = player_node.inventory
		if inv_variant is Array and (inv_variant as Array).size() <= 1:
			_show_gandalf_once("loot_discipline", _gandalf_line("Search every place you clear. In this tower, survival is often a thing picked from the floor."))

func _check_gandalf_outer_pits_explainers(player_node: Node) -> void:
	if not _is_gandalf_guidance_active():
		return
	var depth: int = int(GameManager.current_depth)
	if depth < 1 or depth > 3:
		return
	if not GameManager.current_level:
		return

	if _player_has_status(player_node, "poisoned"):
		_show_gandalf_once("status_poisoned", _gandalf_line("Poison kills by patience, not by spectacle. Cleanse it soon, or break off until it passes."))
		_record_gandalf_threat_signal("poison")
		return
	if _player_has_status(player_node, "entranced"):
		_show_gandalf_once("status_entranced", _gandalf_line("Your will is fettered. Strengthen Will, and keep your distance from hexing foes."))
		_record_gandalf_threat_signal("entrance")
		return
	if _player_has_status(player_node, "slow"):
		_show_gandalf_once("status_slow", _gandalf_line("Slow feet are deadly in close halls. Break line of sight, and set the fight anew."))
		_record_gandalf_threat_signal("slow")
		return

	var tile: int = int(GameManager.current_level.get_tile(player_node.grid_position))
	if tile == Level.Tile.WEB:
		_show_gandalf_once("tile_web", _gandalf_line("Web underfoot. Trade no blows while snared; step clear first, then fight."))
		_record_gandalf_threat_signal("web")
		return
	if tile == Level.Tile.POISON_STREAM:
		_show_gandalf_once("tile_poison_stream", _gandalf_line("Poisoned water: cross swiftly, and never brawl within it."))
		_record_gandalf_threat_signal("poison")
		return
	if tile == Level.Tile.INSCRIPTION:
		_show_gandalf_once("tile_inscription", _gandalf_line("Read what is written here. In this tower, lore is often warning bought by another's death."))
		return

	var room_tags: Array[String] = GameManager.current_level.get_room_tags_at(player_node.grid_position)
	if "vault" in room_tags:
		_show_gandalf_once("room_vault", _gandalf_line("A vault. Rush not this threshold; scout, lure, and clear it in pieces."))
		_record_gandalf_threat_signal("vault")
		return

	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not (entity is Monster):
			continue
		if not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			continue
		var mon: Monster = entity as Monster
		var md: Variant = mon.monster_data
		if _is_broodmother(mon, md):
			_mark_milestone("saw_broodmother")
			_show_gandalf_once(
				"broodmother_seen",
				_gandalf_line("A Broodmother. Do not brawl in her webs. Pull her to firm ground, break line of sight when snared, and kill her before the nest can close upon you."),
				true,
				4.0
			)
			_record_gandalf_threat_signal("web")
			_record_gandalf_threat_signal("pack")
			return
		if mon.has_friends_flag:
			_show_gandalf_once("monster_pack", _gandalf_line("That one hunts with friends. Expect reinforcements, and shape the fight at a choke."))
			_record_gandalf_threat_signal("pack")
			return
		if mon.can_open_doors:
			_show_gandalf_once("monster_open_door", _gandalf_line("Mark this: some foes open doors. A door buys time; it does not grant safety."))
			_record_gandalf_threat_signal("door_openers")
			return
		var spells: Array[String] = []
		if md and "spell_types" in md:
			for s in md.spell_types:
				spells.append(str(s))
		if not spells.is_empty():
			if "WEB" in spells or "THROW_WEB" in spells:
				_show_gandalf_once("monster_webcaster", _gandalf_line("A web-caster. Keep space, use corners, and let it not anchor you in the open."))
				_record_gandalf_threat_signal("web")
				return
			if "HOLD" in spells or "SLOW" in spells or "CONF" in spells or "SCARE" in spells:
				_show_gandalf_once("monster_hexer", _gandalf_line("A hexing foe. Value Will, and stand not in clear sight-lines."))
				_record_gandalf_threat_signal("hexer")
				return
			if "ARROW1" in spells or "ARROW2" in spells or "BOULDER" in spells:
				_show_gandalf_once("monster_ranged", _gandalf_line("Ranged pressure. Break line of sight with corners, before you trade turns."))
				_record_gandalf_threat_signal("ranged")
				return
		elif md and md.has_method("has_flag"):
			if bool(md.has_flag("THROW_WEB")):
				_show_gandalf_once("monster_webcaster", _gandalf_line("A web-caster. Keep space, use corners, and let it not anchor you in the open."))
				_record_gandalf_threat_signal("web")
				return
			if bool(md.has_flag("ARROW1")) or bool(md.has_flag("ARROW2")) or bool(md.has_flag("BOULDER")):
				_show_gandalf_once("monster_ranged", _gandalf_line("Ranged pressure. Break line of sight with corners, before you trade turns."))
				_record_gandalf_threat_signal("ranged")
				return

func _record_gandalf_threat_signal(signal_name: String) -> void:
	if signal_name.is_empty():
		return
	_gandalf_threat_signals[signal_name] = true

func _set_expectation(expectation_id: String, retry_text: String, turns_until_retry: int = 16) -> void:
	if expectation_id.is_empty():
		return
	if _tutorial_expectations.has(expectation_id):
		return
	var now_turn: int = int(GameManager.turn_count) if GameManager else 0
	_tutorial_expectations[expectation_id] = {
		"set_turn": now_turn,
		"deadline_turn": now_turn + maxi(4, turns_until_retry),
		"retry_text": retry_text,
		"completed": false,
		"reminded": false,
	}
	_tutorial_analytics["expectations_set"] = int(_tutorial_analytics.get("expectations_set", 0)) + 1
	_append_tutorial_analytics("EXPECT_SET %s t=%d" % [expectation_id, now_turn])

func _complete_expectation(expectation_id: String) -> void:
	if expectation_id.is_empty() or not _tutorial_expectations.has(expectation_id):
		return
	var item: Dictionary = _tutorial_expectations[expectation_id]
	if bool(item.get("completed", false)):
		return
	item["completed"] = true
	_tutorial_expectations[expectation_id] = item
	_tutorial_analytics["expectations_met"] = int(_tutorial_analytics.get("expectations_met", 0)) + 1
	_mentor_confidence_score += 1
	_append_tutorial_analytics("EXPECT_MET %s t=%d" % [expectation_id, int(GameManager.turn_count) if GameManager else 0])

func _check_tutorial_expectations(player_node: Node) -> void:
	if _tutorial_expectations.is_empty():
		return
	var turn_now: int = int(GameManager.turn_count) if GameManager else 0
	var keys: Array = _tutorial_expectations.keys()
	for key_v in keys:
		var key: String = str(key_v)
		var item: Dictionary = _tutorial_expectations.get(key, {})
		if bool(item.get("completed", false)):
			continue
		if bool(item.get("reminded", false)):
			continue
		var deadline: int = int(item.get("deadline_turn", turn_now + 1))
		if turn_now < deadline:
			continue
		item["reminded"] = true
		_tutorial_expectations[key] = item
		_tutorial_analytics["expectations_missed"] = int(_tutorial_analytics.get("expectations_missed", 0)) + 1
		_mentor_confidence_score = maxi(0, _mentor_confidence_score - 1)
		var retry_text: String = str(item.get("retry_text", "Do this now."))
		if _is_gandalf_guidance_active():
			_show_gandalf_once("retry_%s" % key, _gandalf_line(retry_text), true, 4.0)
		if key == "enter_stealth" and player_node and "stealth_mode" in player_node and bool(player_node.stealth_mode):
			_complete_expectation("enter_stealth")

func _mark_milestone(milestone: String) -> void:
	if milestone.is_empty():
		return
	if not _tutorial_milestones.has(milestone):
		_tutorial_milestones[milestone] = true
		return
	if bool(_tutorial_milestones.get(milestone, false)):
		return
	_tutorial_milestones[milestone] = true
	_mentor_confidence_score += 1
	_append_tutorial_analytics("MILESTONE %s t=%d" % [milestone, int(GameManager.turn_count) if GameManager else 0])

func _append_tutorial_analytics(line: String) -> void:
	if line.is_empty():
		return
	var f: FileAccess = null
	if FileAccess.file_exists(TUTORIAL_ANALYTICS_PATH):
		f = FileAccess.open(TUTORIAL_ANALYTICS_PATH, FileAccess.READ_WRITE)
	else:
		f = FileAccess.open(TUTORIAL_ANALYTICS_PATH, FileAccess.WRITE_READ)
	if f == null:
		return
	f.seek_end()
	f.store_line("[%d] %s" % [int(Time.get_unix_time_from_system()), line])
	f.close()

func _should_suppress_noncritical(priority: int, token: String) -> bool:
	if priority >= GANDALF_PRIORITY_HIGH:
		return false
	if _mentor_confidence_score < 10:
		return false
	if token.begins_with("xp_") or token.find("status_") >= 0 or token.find("inventory") >= 0 or token.find("hotbar") >= 0 or token.find("disguise") >= 0:
		return false
	if priority >= GANDALF_PRIORITY_MEDIUM:
		return false
	return true

func _skill_level(player_node: Node, skill_name: String) -> int:
	if player_node and player_node.has_method("get_effective_skill"):
		return int(player_node.get_effective_skill(skill_name))
	return 0

func _has_player_ability(player_node: Node, skill: int, ability: int) -> bool:
	if not player_node or not player_node.has_method("has_ability"):
		return false
	return bool(player_node.has_ability(skill, ability))

func _check_gandalf_xp_advisor(player_node: Node) -> void:
	if not _is_gandalf_guidance_active():
		return
	var xp_now: int = int(player_node.get("xp_available"))
	if xp_now < 500:
		return
	var lane: String = "safety"
	if _gandalf_threat_signals.has("poison") or _gandalf_threat_signals.has("hexer") or _gandalf_threat_signals.has("entrance"):
		lane = "anti_control"
	elif _gandalf_threat_signals.has("pack") or _gandalf_threat_signals.has("door_openers"):
		lane = "safety"
	elif _tutorial_milestones.get("entered_stealth", false):
		lane = "stealth_kill"
	match lane:
		"safety":
			_show_gandalf_once("xp_lane_safety", _gandalf_line("Spend-lane: safety first. Buy survival before elegance."), false, 4.0, GANDALF_PRIORITY_MEDIUM)
		"anti_control":
			_show_gandalf_once("xp_lane_anti_control", _gandalf_line("Spend-lane: anti-control. Will and positioning answers come first."), false, 4.0, GANDALF_PRIORITY_HIGH)
		"stealth_kill":
			_show_gandalf_once("xp_lane_stealth_kill", _gandalf_line("Spend-lane: stealth-kill. Build tools that open and finish unwary fights quickly."), false, 4.0, GANDALF_PRIORITY_MEDIUM)

	var melee: int = _skill_level(player_node, "melee")
	var evasion: int = _skill_level(player_node, "evasion")
	var stealth: int = _skill_level(player_node, "stealth")
	var hunting: int = _skill_level(player_node, "hunting")
	var will: int = _skill_level(player_node, "will")
	var visible_hostiles: int = _count_visible_hostiles(player_node)

	if melee < 2:
		_show_gandalf_once("xp_skill_melee_2", _gandalf_line("Set Melee to 2. Do this now: your first duty is to survive the close turns, when retreat fails."))
		return
	if hunting < 2:
		_show_gandalf_once("xp_skill_hunting_2", _gandalf_line("Set Hunting to 2. Do this now: clearer reads prevent bad fights before they are joined."))
		return
	if stealth < 4:
		_show_gandalf_once("xp_skill_stealth_4", _gandalf_line("Build Stealth toward 4. Do this now: it opens your first true kill-window tools."))
		return
	if evasion < 2:
		_show_gandalf_once("xp_skill_evasion_2", _gandalf_line("Set Evasion to 2. Do this now: one missed enemy blow may yet save the run."))
		return

	var has_finesse: bool = _has_player_ability(player_node, Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FINESSE)
	if not has_finesse and melee >= 2:
		_show_gandalf_once("xp_ability_finesse", _gandalf_line("Take Finesse in Melee. Do this now: the elven hand wins by precision, not by brute force."))
		return
	var has_mark_quarry: bool = _has_player_ability(player_node, Constants.Skill.S_PER, Constants.PerceptionAbility.PER_FOCUSED_ATTACK)
	if not has_mark_quarry and hunting >= 2:
		_show_gandalf_once("xp_ability_mark_quarry", _gandalf_line("Take Mark Quarry in Hunting. Do this now: pressure upon one target can break a dangerous group apart."))
		return
	var has_assassination: bool = _has_player_ability(player_node, Constants.Skill.S_STL, Constants.StealthAbility.STL_ASSASSINATION)
	if not has_assassination and stealth >= 4:
		_show_gandalf_once("xp_ability_assassination", _gandalf_line("Take Assassination in Stealth. Do this now: unwary foes must fall swiftly, before they gather force."))
		return

	if (_gandalf_threat_signals.has("pack") or visible_hostiles >= 2) and evasion < 4:
		_show_gandalf_once("xp_vs_pack_evasion4", _gandalf_line("Hear me: packs are upon you. Spend toward Evasion 4 now, for it opens Parry and steadies crowded fights."))
		return

	var has_parry: bool = _has_player_ability(player_node, Constants.Skill.S_EVN, Constants.EvasionAbility.EVN_PARRY)
	if (_gandalf_threat_signals.has("pack") or _gandalf_threat_signals.has("door_openers")) and evasion >= 4 and not has_parry:
		_show_gandalf_once("xp_ability_parry", _gandalf_line("Take Parry in Evasion. Do this now: when lines collapse, weapon-evasion keeps you alive."))
		return

	if (_gandalf_threat_signals.has("ranged") or _gandalf_threat_signals.has("hexer")) and hunting < 3:
		_show_gandalf_once("xp_vs_ranged_hunting3", _gandalf_line("Hear me: ranged and hexing pressure is rising. Raise Hunting to 3 now, that you may break sight-lines before harm takes hold."))
		return

	if (_gandalf_threat_signals.has("poison") or _gandalf_threat_signals.has("hexer") or _gandalf_threat_signals.has("entrance")) and will < 2:
		_show_gandalf_once("xp_vs_status_will2", _gandalf_line("Hear me: status attrition is at work. Raise Will to 2 now, and better withstand controlling effects."))
		return

	if xp_now >= 1800:
		_show_gandalf_once("xp_reserve_default", _gandalf_line("Keep a reserve. Spend only what answers the next danger you can name."))

func _player_has_status(player_node: Node, status_name: String) -> bool:
	if not ("status_effects" in player_node):
		return false
	var statuses: Variant = player_node.status_effects
	return statuses is Dictionary and (statuses as Dictionary).has(status_name)

func _count_visible_hostiles(player_node: Node) -> int:
	if not GameManager.current_level:
		return 0
	var count: int = 0
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity):
			continue
		if not (entity is Monster):
			continue
		if not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			continue
		var dist: int = maxi(
			absi(entity.grid_position.x - player_node.grid_position.x),
			absi(entity.grid_position.y - player_node.grid_position.y)
		)
		if dist <= 8:
			count += 1
	return count

func _why_now_clause(player_node: Node) -> String:
	if not player_node:
		return ""
	var visible_hostiles: int = _count_visible_hostiles(player_node)
	var hp_now: int = int(player_node.get("current_health"))
	var hp_max: int = int(maxi(int(player_node.get("max_health")), 1))
	if visible_hostiles >= 2:
		return " Why now: more than one foe is in sight."
	if hp_now * 2 < hp_max:
		return " Why now: your health is below half."
	if hp_now * 3 < hp_max:
		return " Why now: you are one bad turn from collapse."
	return ""

func _is_broodmother(mon: Monster, md: Variant) -> bool:
	if mon:
		var n0: String = str(mon.entity_name).to_lower()
		var n1: String = str(mon.get("monster_name")).to_lower()
		if n0.find("broodmother") >= 0 or n1.find("broodmother") >= 0:
			return true
		if n0.find("brood mother") >= 0 or n1.find("brood mother") >= 0:
			return true
	if md:
		if "name" in md:
			var n2: String = str(md.name).to_lower()
			if n2.find("broodmother") >= 0 or n2.find("brood mother") >= 0:
				return true
		if "id" in md:
			var n3: String = str(md.id).to_lower()
			if n3.find("broodmother") >= 0 or n3.find("brood_mother") >= 0:
				return true
	return false

func _check_tutorial_scaffold(player_node: Node) -> void:
	if not _tutorial_state.get("enabled", true):
		return
	if GameManager.current_depth != 1:
		return
	if _tutorial_state.get("current_step", 0) >= TUTORIAL_STEPS.size():
		return
	if not ("grid_position" in player_node):
		return

	if int(_tutorial_state.get("spawn_depth1_x", -1)) < 0 or int(_tutorial_state.get("spawn_depth1_y", -1)) < 0:
		var p: Vector2i = player_node.grid_position
		_tutorial_state["spawn_depth1_x"] = p.x
		_tutorial_state["spawn_depth1_y"] = p.y
		_save_tutorial_state()
		_show_current_tutorial_step()

	var step_index: int = int(_tutorial_state.get("current_step", 0))
	if _is_gandalf_guidance_active() and step_index >= 1 and not bool(_gandalf_scroll_tutorial.get("tome_opened", false)):
		_show_gandalf_once(
			"post_move_open_scroll_t",
			_gandalf_line("Your feet are set. Now open the ancient scroll with [T], and shape your skill before the dark closes in."),
			false,
			4.0
		)
	if step_index < 0 or step_index >= TUTORIAL_STEPS.size():
		return
	var step: Dictionary = TUTORIAL_STEPS[step_index]
	var step_id: String = str(step.get("id", ""))
	if step_id.is_empty():
		return
	if not _is_tutorial_step_complete(step_id, player_node):
		return

	var completed: Dictionary = _tutorial_state.get("completed", {})
	completed[step_id] = true
	if step_id == "move":
		_mark_milestone("moved")
	_tutorial_state["completed"] = completed
	_tutorial_state["current_step"] = step_index + 1
	_save_tutorial_state()
	_show_current_tutorial_step()

func _show_current_tutorial_step() -> void:
	var step_index: int = int(_tutorial_state.get("current_step", 0))
	if step_index < 0 or step_index >= TUTORIAL_STEPS.size():
		return
	var step: Dictionary = TUTORIAL_STEPS[step_index]
	var step_id: String = str(step.get("id", ""))
	var step_text: String = str(step.get("text", ""))
	if step_id.is_empty() or step_text.is_empty():
		return
	if _is_gandalf_guidance_active():
		step_text = _gandalf_line(str(GANDALF_STEP_TEXT.get(step_id, step_text)))
		show_hint("tutorial_step_%s_%d" % [step_id, _gandalf_session_nonce], step_text)
		return
	show_hint("tutorial_step_%s" % step_id, step_text)

func _is_tutorial_step_complete(step_id: String, player_node: Node) -> bool:
	match step_id:
		"move":
			var start := Vector2i(
				int(_tutorial_state.get("spawn_depth1_x", -1)),
				int(_tutorial_state.get("spawn_depth1_y", -1))
			)
			if start.x < 0 or start.y < 0:
				return false
			var pos: Vector2i = player_node.grid_position
			var dist: int = maxi(absi(pos.x - start.x), absi(pos.y - start.y))
			return dist >= 2
		"pickup":
			if not ("inventory" in player_node):
				return false
			var inv_variant: Variant = player_node.inventory
			return inv_variant is Array and (inv_variant as Array).size() > 0
		"survive_hit":
			return _player_took_damage_once
		"stairs":
			if not GameManager.current_level:
				return false
			var tile: int = GameManager.current_level.get_tile(player_node.grid_position)
			return tile == Level.Tile.STAIRS_UP or tile == Level.Tile.STAIRS_DOWN
		_:
			return false

func check_tile_hints(player_node: Node, tile: int) -> void:
	if AccessibilityManager and AccessibilityManager.has_method("is_assist_enabled"):
		if not AccessibilityManager.is_assist_enabled():
			return
	if not player_node or _is_showing:
		return
	# Standing on stairs
	if tile == 6 or tile == 7:  # STAIRS_UP or STAIRS_DOWN
		if _is_gandalf_guidance_active():
			_show_gandalf_once("tile_stairs", _gandalf_line("Stairs set your tempo. Descend with [Enter] only when your health and position are steady."))
		else:
			show_hint("stairs", "Press [Enter] to use stairs")
	# Standing on forge
	if tile == 9:  # FORGE
		if _is_gandalf_guidance_active():
			_show_gandalf_once("tile_forge", _gandalf_line("A forge may decide a run. Improve your kit before greed draws you deeper."))
		else:
			show_hint("forge", "Press [F] to use the forge")

func _on_entity_died(entity: Node, _killer: Node) -> void:
	if entity is Player:
		_append_tutorial_analytics("PLAYER_DEATH t=%d last_hint=%s" % [
			int(GameManager.turn_count) if GameManager else -1,
			str(_tutorial_analytics.get("last_hint_token", "")),
		])
		return
	if _is_gandalf_guidance_active():
		_show_gandalf_once("first_kill", _gandalf_line("Well struck. Search the fallen, and take what improves your odds before you press on."))
	else:
		show_hint("first_kill", "Monsters drop items and give XP")

func _on_entity_damaged(entity: Node, _damage: int, damage_type: String, _source: Node) -> void:
	if not _is_gandalf_guidance_active():
		return
	if entity != GameManager.player:
		return
	_player_took_damage_once = true
	var dtype: String = damage_type.to_lower()
	if _source and "grid_position" in _source and GameManager.player and "grid_position" in GameManager.player:
		var dist: int = maxi(
			absi(int(_source.grid_position.x) - int(GameManager.player.grid_position.x)),
			absi(int(_source.grid_position.y) - int(GameManager.player.grid_position.y))
		)
		if dist >= 3:
			_show_gandalf_once("evt_ranged_hit", _gandalf_line("You are taking ranged pressure. Break line of sight before you trade another turn."), false, 4.0, GANDALF_PRIORITY_HIGH)
	if dtype == "poison":
		_show_gandalf_once("evt_poison_damage", _gandalf_line("Poison is a debt that grows with time. Break contact and clear it early."), false, 4.0, GANDALF_PRIORITY_HIGH)
	elif dtype == "fire":
		_show_gandalf_once("evt_fire_damage", _gandalf_line("Fire punishes delay. Step off the hazard at once, then reassess."), false, 4.0, GANDALF_PRIORITY_HIGH)
	elif dtype == "dark":
		_show_gandalf_once("evt_dark_damage", _gandalf_line("Shadow pressure rises. Favor line-of-sight breaks and disciplined retreat."), false, 4.0, GANDALF_PRIORITY_HIGH)

func _on_status_applied(entity: Node, status_name: String, _duration: int) -> void:
	if not _is_gandalf_guidance_active():
		return
	if entity != GameManager.player:
		return
	var status: String = status_name.to_lower()
	match status:
		"poisoned":
			_show_gandalf_once("evt_status_poisoned", _gandalf_line("You are poisoned. Cleanse, or disengage until it wanes."), false, 4.0, GANDALF_PRIORITY_CRITICAL)
		"entranced":
			_show_gandalf_once("evt_status_entranced", _gandalf_line("Entrancement is upon you. Keep distance and answer with Will at the next spend."), false, 4.0, GANDALF_PRIORITY_CRITICAL)
		"slow":
			_show_gandalf_once("evt_status_slow", _gandalf_line("Slow feet kill in narrow halls. Break sight-lines and reset the fight."), false, 4.0, GANDALF_PRIORITY_HIGH)
		"stunned":
			_show_gandalf_once("evt_status_stunned", _gandalf_line("You are reeling. Do not trade blows until your footing returns."), false, 4.0, GANDALF_PRIORITY_HIGH)
		_:
			pass

func _on_status_tick(entity: Node, status_name: String, _remaining: int) -> void:
	if not _is_gandalf_guidance_active():
		return
	if entity != GameManager.player:
		return
	if status_name.to_lower() == "poisoned":
		_show_gandalf_once("evt_poison_tick", _gandalf_line("Each turn of poison is theft. Spend or reposition to end it."), false, 4.0, GANDALF_PRIORITY_HIGH)

func _on_entity_moved(entity: Node, _from_pos: Vector2i, _to_pos: Vector2i) -> void:
	if entity != GameManager.player:
		return
	if not _tutorial_milestones.get("moved", false):
		_mark_milestone("moved")

func _on_ability_used(entity: Node, _ability: Resource, _targets: Array) -> void:
	if not _is_gandalf_guidance_active():
		return
	if entity != GameManager.player:
		return
	_complete_expectation("use_gem")

func _on_item_picked_up(_entity: Node, _item: Variant) -> void:
	pass  # Could show inventory hint

func _on_level_entered(_depth: int) -> void:
	if not AccessibilityManager.is_assist_enabled():
		return
	_enforce_gandalf_depth_policy()
	if not ChronicleManager:
		return
	if _depth == 1:
		# Re-anchor movement step to this run's spawn position.
		_tutorial_state["spawn_depth1_x"] = -1
		_tutorial_state["spawn_depth1_y"] = -1
		_save_tutorial_state()
		_show_postmortem_guidance()
	if _is_gandalf_guidance_active():
		_emit_floor_doctrine(_depth)
	var first_run: bool = ChronicleManager.entries.is_empty()
	if not first_run:
		return
	if _is_gandalf_guidance_active():
		return
	match _depth:
		1:
			show_hint("first_run_depth1", "A scout's note: read intent before you commit. Death comes fast down here.")
		2:
			show_hint("first_run_depth2", "The walls close in. If fights feel unreadable, invest in Hunting/Lore next run.")
		3:
			show_hint("first_run_depth3", "Field lesson: retreat is victory when the dark presses too hard.")

func _show_postmortem_guidance() -> void:
	if not ChronicleManager or ChronicleManager.entries.is_empty():
		return
	var last: Dictionary = ChronicleManager.entries[ChronicleManager.entries.size() - 1]
	if str(last.get("outcome", "")) != "death":
		return
	var stamp: String = str(last.get("timestamp", ""))
	var killer: String = str(last.get("killer", "")).to_lower()
	var cause: String = str(last.get("died_from", "")).to_lower()
	var hint_id: String = "postmortem_%s" % stamp
	var text: String = ""
	if killer.find("sorcerer") >= 0 or killer.find("wraith") >= 0:
		text = "Scout's addendum: control casters kill fast. Invest Hunting/Lore to read intent earlier."
	elif killer.find("spider") >= 0 or cause.find("poison") >= 0:
		text = "Scout's addendum: poison attrition won the last run. Bring cleanse tools and disengage sooner."
	elif killer.find("ghoul") >= 0 or cause.find("entrance") >= 0 or cause.find("hold") >= 0:
		text = "Scout's addendum: loss of control was fatal. Seek Will and Free Action protection."
	else:
		text = "Scout's addendum: if threats felt unreadable, invest Hunting/Lore next run for sharper field reads."
	show_hint(hint_id, text)

func _emit_floor_doctrine(depth: int) -> void:
	match depth:
		1:
			_show_gandalf_once("depth1_brief", _gandalf_line("Outer Pits doctrine: scout, isolate, strike, rest, descend."), true, 4.0, GANDALF_PRIORITY_HIGH)
			_show_gandalf_once("depth1_doctrine_ui", _gandalf_line("Doctrine this floor: press [I] often, keep [Z] for safe recovery, and spend XP only when the next danger is named."), true, 4.0, GANDALF_PRIORITY_MEDIUM)
		2:
			_show_gandalf_once("depth2_brief", _gandalf_line("Second depth doctrine: webs and poison are common; fight only on clean ground."), true, 4.0, GANDALF_PRIORITY_HIGH)
			_show_gandalf_once("depth2_doctrine_build", _gandalf_line("If control effects rise, answer with Will and positioning before prideful damage buys your death."), true, 4.0, GANDALF_PRIORITY_MEDIUM)
		3:
			_show_gandalf_once("depth3_brief", _gandalf_line("Third depth doctrine: packs are keener and vaults deadlier; pull fights apart or do not take them."), true, 4.0, GANDALF_PRIORITY_HIGH)
			_show_gandalf_once("depth3_doctrine_xp", _gandalf_line("Keep reserve XP for adaptation. The right answer bought one turn earlier is often the whole run."), true, 4.0, GANDALF_PRIORITY_MEDIUM)

func _load_hints() -> void:
	var config := ConfigFile.new()
	if config.load(HINTS_PATH) == OK:
		for key in config.get_section_keys("hints"):
			_shown_hints[key] = true

func _load_tutorial_state() -> void:
	var config := ConfigFile.new()
	if config.load(TUTORIAL_PATH) != OK:
		return
	_tutorial_state["enabled"] = bool(config.get_value("tutorial", "enabled", true))
	_tutorial_state["current_step"] = int(config.get_value("tutorial", "current_step", 0))
	_tutorial_state["spawn_depth1_x"] = int(config.get_value("tutorial", "spawn_depth1_x", -1))
	_tutorial_state["spawn_depth1_y"] = int(config.get_value("tutorial", "spawn_depth1_y", -1))
	var completed_raw: String = str(config.get_value("tutorial", "completed", ""))
	var completed: Dictionary = {}
	for key in completed_raw.split(",", false):
		completed[key] = true
	_tutorial_state["completed"] = completed

func _save_hints() -> void:
	var config := ConfigFile.new()
	for key in _shown_hints:
		config.set_value("hints", key, true)
	config.save(HINTS_PATH)

func _save_tutorial_state() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "enabled", bool(_tutorial_state.get("enabled", true)))
	config.set_value("tutorial", "current_step", int(_tutorial_state.get("current_step", 0)))
	config.set_value("tutorial", "spawn_depth1_x", int(_tutorial_state.get("spawn_depth1_x", -1)))
	config.set_value("tutorial", "spawn_depth1_y", int(_tutorial_state.get("spawn_depth1_y", -1)))
	var completed: Dictionary = _tutorial_state.get("completed", {})
	var keys: PackedStringArray = []
	for key in completed.keys():
		keys.append(str(key))
	config.set_value("tutorial", "completed", ",".join(keys))
	config.save(TUTORIAL_PATH)

func reset_hints() -> void:
	_shown_hints.clear()
	_save_hints()

func reset_tutorial_progress() -> void:
	_tutorial_state = {
		"enabled": true,
		"current_step": 0,
		"completed": {},
		"spawn_depth1_x": -1,
		"spawn_depth1_y": -1,
	}
	_save_tutorial_state()
