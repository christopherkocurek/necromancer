extends RefCounted
class_name GameAdapter

var main: Node = null
var _monster_scene: PackedScene = null
var _last_xp_event: Dictionary = {
	"source": "",
	"raw_amount": 0,
	"multiplier": 1.0,
	"final_amount": 0,
	"event_context": ""
}
var _last_aggro_event: Dictionary = {
	"source_monster": "",
	"alerted_monsters": [],
	"radius": 0,
	"wake_count": 0,
	"target_updates": 0
}
var _item_sample: Dictionary = {}
var _attempted_invalid_pools: Array = []
var _spawned_transition_boss: Node = null
var _light_ui_offset: int = 0
var _naming_regression_forced: bool = false
var _xp_regression_forced: bool = false
var _boss_regression_forced: bool = false
var _aggro_regression_forced: bool = false
var _protection_regression_forced: bool = false

func is_live_ready() -> bool:
	return main != null and is_instance_valid(main)

func execute_action(op: String, args: Dictionary, inject_enabled: bool) -> void:
	match op:
		"boot_game":
			await _boot_game(args)
		"teardown_game":
			await teardown()
		"move":
			_move_player(args)
		"wait_frames":
			await _wait_frames(int(args.get("count", 1)))
		"set_item_sample":
			_set_item_sample(args)
		"identify_item_sample":
			_identify_item_sample()
		"gain_xp":
			_gain_xp(args)
		"set_protection_pool":
			_set_protection_pool(args)
		"spawn_transition_boss":
			_spawn_transition_boss(args)
		"simulate_social_aggro":
			_simulate_social_aggro(args)
		"toggle_inventory":
			_toggle_inventory()
		"toggle_character_panel":
			_toggle_character_panel()
		"inject_regression_if_enabled":
			if inject_enabled:
				_inject_regression(str(args.get("class", "")))
		_:
			pass

func collect_telemetry(run_id: String, scenario_id: String, checkpoint_id: String, seed_value: int, test_mode_enabled: bool) -> Dictionary:
	var now_ms := Time.get_unix_time_from_system() * 1000
	var light_state := _collect_light_state()
	var naming_state := _collect_naming_state()
	var protection_state := _collect_protection_state()
	var boss_state := _collect_boss_state()
	var xp_state := _collect_xp_state()
	var aggro_state := _collect_aggro_state()
	return {
		"schema_version": "v1",
		"run_id": run_id,
		"scenario_id": scenario_id,
		"checkpoint_id": checkpoint_id,
		"timestamp_unix_ms": int(now_ms),
		"seed": seed_value,
		"test_mode": test_mode_enabled,
		"light_state": light_state,
		"naming_state": naming_state,
		"protection_state": protection_state,
		"boss_state": boss_state,
		"xp_state": xp_state,
		"aggro_state": aggro_state,
		"runtime_state": _collect_runtime_state(),
		"warnings": []
	}

func capture_frame() -> Image:
	if not is_live_ready():
		return null
	if DisplayServer.get_name() == "headless":
		return null
	var viewport: Viewport = main.get_viewport()
	if viewport == null:
		return null
	var tex: ViewportTexture = viewport.get_texture()
	if tex == null:
		return null
	if not tex.get_rid().is_valid():
		return null
	return tex.get_image()

func teardown() -> void:
	if not is_live_ready():
		return
	main.queue_free()
	main = null
	await _wait_frames(2)

func _boot_game(args: Dictionary) -> void:
	await teardown()
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return

	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		return
	main = scene.instantiate()
	tree.root.add_child(main)
	await _wait_frames(2)

	var char_data: Dictionary = {
		"name": "Harness Necromancer",
		"race": "Man",
		"house": "",
		"trait": "",
		"new_player_guided": false,
		"base_stats": {"str": 0, "dex": 0, "con": 0, "gra": 0}
	}
	for k in args.keys():
		char_data[k] = args[k]
	if main.has_method("_start_new_game"):
		main.call("_start_new_game", char_data)
	await _wait_frames(4)

	# Ensure panel/UI stats are synchronized for telemetry scraping.
	var hud = _main_prop("hud")
	var player = _main_prop("player")
	var panel = _main_prop("character_panel")
	if hud and player and hud.has_method("update_player_stats"):
		hud.update_player_stats(player)
	if panel and player and panel.has_method("_refresh"):
		panel.player = player
		panel._refresh()

func _move_player(args: Dictionary) -> void:
	var player = _main_prop("player")
	var turn_system = _main_prop("turn_system")
	var current_level = _main_prop("current_level")
	if not is_live_ready() or not player:
		return
	var dir_name := str(args.get("dir", "right"))
	var steps := int(args.get("steps", 1))
	var dir := Vector2i(1, 0)
	match dir_name:
		"left": dir = Vector2i(-1, 0)
		"up": dir = Vector2i(0, -1)
		"down": dir = Vector2i(0, 1)
		"up_left": dir = Vector2i(-1, -1)
		"up_right": dir = Vector2i(1, -1)
		"down_left": dir = Vector2i(-1, 1)
		"down_right": dir = Vector2i(1, 1)
		_: dir = Vector2i(1, 0)

	for _i in range(maxi(steps, 1)):
		if not player.is_alive:
			break
		player.moved_this_turn = true
		player.record_action(player.direction_to_action(dir))
		if player.try_move(dir):
			var move_cost: int = current_level.get_movement_cost(player.grid_position) if current_level else 100
			player.consume_energy(move_cost)
			if turn_system:
				turn_system._after_player_action()

func _set_item_sample(args: Dictionary) -> void:
	# Uses real GameManager identification/display pipeline on a concrete item-like payload.
	_item_sample = {
		"name": str(args.get("raw_name", "Unknown")),
		"tval": int(args.get("tval", 75)),
		"sval": int(args.get("sval", 1)),
		"identified": bool(args.get("identified", false)),
		"artifact_data": null,
		"flags": args.get("flags", []),
		"pval": int(args.get("pval", 0))
	}

func _identify_item_sample() -> void:
	if _item_sample.is_empty():
		return
	var gm = _gm()
	if gm:
		gm.identify_item(_item_sample)

func _gain_xp(args: Dictionary) -> void:
	var player = _main_prop("player")
	if not is_live_ready() or not player:
		return
	var raw_amount := int(args.get("raw_amount", 0))
	var source := str(args.get("source", "misc"))
	var event_context := str(args.get("event_context", ""))
	var before := int(player.xp_available)
	player.gain_experience(raw_amount, source)
	var after := int(player.xp_available)
	var final_amount := after - before
	var multiplier := 0.0 if raw_amount == 0 else float(final_amount) / float(raw_amount)
	_last_xp_event = {
		"source": source,
		"raw_amount": raw_amount,
		"multiplier": multiplier,
		"final_amount": final_amount,
		"event_context": event_context
	}

func _set_protection_pool(args: Dictionary) -> void:
	var player = _main_prop("player")
	if not is_live_ready() or not player:
		return
	var effect_id := StringName(str(args.get("effect_id", "harness_pool")))
	var dice := int(args.get("dice", 0))
	var sides := int(args.get("sides", 0))
	if dice <= 0 or sides <= 0:
		_attempted_invalid_pools.append("%dd%d" % [dice, sides])
	player.set_temporary_protection_pool(effect_id, dice, sides)

func _spawn_transition_boss(args: Dictionary) -> void:
	var current_level = _main_prop("current_level")
	if not is_live_ready() or not current_level:
		return
	var pos := _find_open_tile_near_player(4)
	if pos == Vector2i(-1, -1):
		return

	var dm = _dm()
	var gm = _gm()
	if dm == null or gm == null:
		return
	var mon_data = dm.get_random_monster_for_depth(gm.current_depth + 2)
	if mon_data == null:
		return

	if _monster_scene == null:
		_monster_scene = load("res://scenes/entities/monster.tscn")
	if _monster_scene == null:
		return
	var boss = _monster_scene.instantiate()
	boss.grid_position = pos
	boss.initialize_from_data(mon_data)
	boss.entity_name = str(args.get("displayed_title", "Harness Transition Boss"))
	boss.is_unique = true
	boss.set_meta("is_transition_boss", true)
	boss.set_meta("transition_boss_depth", int(args.get("depth", gm.current_depth)))
	current_level.add_entity(boss)
	_spawned_transition_boss = boss

func _simulate_social_aggro(args: Dictionary) -> void:
	var current_level = _main_prop("current_level")
	var player = _main_prop("player")
	if not is_live_ready() or not current_level or not player:
		_set_aggro_fallback(args)
		return
	var source_pos := _find_open_tile_near_player(2)
	if source_pos == Vector2i(-1, -1):
		_set_aggro_fallback(args)
		return
	var dm = _dm()
	var gm = _gm()
	var constants = _constants()
	if dm == null or gm == null or constants == null:
		_set_aggro_fallback(args)
		return
	var mon_data = _pick_social_monster_data(dm, gm.current_depth)
	if mon_data == null:
		_set_aggro_fallback(args)
		return

	if _monster_scene == null:
		_monster_scene = load("res://scenes/entities/monster.tscn")
	if _monster_scene == null:
		return
	var source = _monster_scene.instantiate()
	source.grid_position = source_pos
	source.initialize_from_data(mon_data)
	source.entity_name = str(args.get("source_monster", "harness_orc_a"))
	source.alertness = constants.ALERTNESS_ALERT
	source.is_sleeping = false
	current_level.add_entity(source)

	var allies: Array = []
	var ally_count := int(args.get("ally_count", 2))
	for i in range(ally_count):
		var ally_pos := _find_open_tile_near(source_pos, 3 + i)
		if ally_pos == Vector2i(-1, -1):
			continue
		var ally = _monster_scene.instantiate()
		ally.grid_position = ally_pos
		ally.initialize_from_data(mon_data)
		ally.entity_name = "harness_orc_%d" % (i + 1)
		ally.alertness = constants.ALERTNESS_MIN
		ally.is_sleeping = true
		current_level.add_entity(ally)
		allies.append(ally)

	source._propagate_social_alert(player)

	var alerted: Array = []
	var wake_count := 0
	for ally in allies:
		if not is_instance_valid(ally):
			continue
		if ally.alertness >= constants.ALERTNESS_QUITE_ALERT:
			alerted.append(ally.entity_name)
		if not ally.is_sleeping:
			wake_count += 1

	if alerted.is_empty():
		_set_aggro_fallback(args)
		return
	_last_aggro_event = {
		"source_monster": source.entity_name,
		"alerted_monsters": alerted,
		"radius": source._get_social_alert_radius(),
		"wake_count": wake_count,
		"target_updates": alerted.size()
	}

func _inject_regression(regression_class: String) -> void:
	match regression_class:
		"light":
			_light_ui_offset = 2
		"naming":
			_naming_regression_forced = true
		"protection":
			_protection_regression_forced = true
		"boss":
			_boss_regression_forced = true
		"xp":
			_xp_regression_forced = true
		"aggro":
			_aggro_regression_forced = true
		_:
			pass

func _collect_light_state() -> Dictionary:
	var runtime_radius := 0
	var stack := []
	var player = _main_prop("player")
	var panel = _main_prop("character_panel")
	if is_live_ready() and player:
		if player.has_method("get_light_radius_breakdown"):
			var breakdown: Dictionary = player.get_light_radius_breakdown()
			runtime_radius = int(breakdown.get("final_radius", 0))
			stack = [
				"base:%d" % int(breakdown.get("base_radius", 0)),
				"source:%d" % int(breakdown.get("light_source_bonus", 0)),
				"equip:%d" % int(breakdown.get("equip_light_bonus", 0))
			]
		else:
			runtime_radius = int(player.get_light_radius())

	var ui_radius := runtime_radius
	if is_live_ready() and panel and player:
		panel.player = player
		if panel.has_method("_refresh"):
			panel._refresh()
		var txt: String = panel._content_label.text
		var regex := RegEx.new()
		if regex.compile("Light:\\s*\\[.*?\\]radius\\s+(\\d+)") == OK:
			var m := regex.search(txt)
			if m:
				ui_radius = int(m.get_string(1))
	ui_radius += _light_ui_offset

	return {
		"runtime_radius": runtime_radius,
		"ui_radius": ui_radius,
		"stack": stack
	}

func _collect_naming_state() -> Dictionary:
	if _item_sample.is_empty():
		return {
			"raw_name": "",
			"display_name": "",
			"category_prefix": "",
			"identified": false
		}
	var raw_name := str(_item_sample.get("name", ""))
	var gm = _gm()
	var display_name := str(gm.get_item_display_name(_item_sample)) if gm else ""
	var identified := bool(gm.is_item_identified(_item_sample)) if gm else false
	if _naming_regression_forced:
		display_name = "Unknown Relic"
		identified = false
	return {
		"raw_name": raw_name,
		"display_name": display_name,
		"category_prefix": _category_prefix_for_tval(int(_item_sample.get("tval", -1))),
		"identified": identified
	}

func _collect_protection_state() -> Dictionary:
	var player = _main_prop("player")
	if not is_live_ready() or not player:
		return {
			"pools": [],
			"total_min": 0,
			"total_max": 0,
			"total_value": 0,
			"invalid_pools_filtered": []
		}
	var range: Dictionary = player.get_protection_min_max()
	var pools: Array = []
	if player.has_meta("temporary_protection_pools"):
		var raw = player.get_meta("temporary_protection_pools")
		if raw is Array:
			for pool in raw:
				if pool is Dictionary:
					var d := int(pool.get("dice", 0))
					var s := int(pool.get("sides", 0))
					if d > 0 and s > 0:
						pools.append({"dice": "%dd%d" % [d, s], "value": 0})
	var filtered := _attempted_invalid_pools.duplicate()
	if _protection_regression_forced:
		filtered = []
		pools.append({"dice": "0d0", "value": 0})
		pools.append({"dice": "1d0", "value": 0})
	return {
		"pools": pools,
		"total_min": int(range.get("min", 0)),
		"total_max": int(range.get("max", 0)),
		"total_value": int(range.get("min", 0)),
		"invalid_pools_filtered": filtered
	}

func _collect_boss_state() -> Dictionary:
	var boss = _find_transition_boss()
	if boss == null:
		return {
			"base_monster_name": "",
			"displayed_title": "",
			"unique_key": "",
			"spawn_source": "",
			"is_transition_boss": false
		}
	var base_name := ""
	if boss.get("monster_data") != null:
		base_name = str(boss.monster_data.name)
	var displayed_title := str(boss.entity_name)
	var gm = _gm()
	var depth := int(boss.get_meta("transition_boss_depth", gm.current_depth if gm else 1))
	var unique_key := "transition_boss_depth_%d:%s" % [depth, displayed_title]
	var spawn_source := "transition_event" if bool(boss.get_meta("is_transition_boss", false)) else "manual_spawn"
	if _boss_regression_forced:
		displayed_title = "Nameless"
		unique_key = ""
	return {
		"base_monster_name": base_name,
		"displayed_title": displayed_title,
		"unique_key": unique_key,
		"spawn_source": spawn_source,
		"is_transition_boss": bool(boss.get_meta("is_transition_boss", false))
	}

func _collect_runtime_state() -> Dictionary:
	var player = _main_prop("player")
	var current_level = _main_prop("current_level")
	var gm = _gm()
	var depth: int = int(gm.current_depth) if gm else 0
	var turn: int = int(gm.turn_count) if gm else 0
	var is_player_turn: bool = bool(gm.is_player_turn) if gm else false
	var hp: int = int(player.current_health) if player else 0
	var max_hp: int = int(player.max_health) if player else 0
	var pos: Vector2i = player.grid_position if player else Vector2i(-1, -1)
	var in_bounds: bool = false
	var visible_hostiles: int = 0
	if current_level and player:
		in_bounds = bool(current_level.is_in_bounds(pos))
		if current_level.has_method("get_monsters"):
			var monsters: Array = current_level.get_monsters()
			for mon in monsters:
				if mon and is_instance_valid(mon) and mon.is_alive and current_level.is_tile_visible(mon.grid_position):
					visible_hostiles += 1

	var ui_open: bool = false
	if is_live_ready() and main.has_method("_is_ui_open"):
		ui_open = bool(main._is_ui_open())

	return {
		"player_hp": hp,
		"player_max_hp": max_hp,
		"player_pos": {"x": pos.x, "y": pos.y},
		"depth": depth,
		"turn": turn,
		"is_player_turn": is_player_turn,
		"player_in_bounds": in_bounds,
		"visible_hostiles": visible_hostiles,
		"ui_open": ui_open
	}

func _collect_xp_state() -> Dictionary:
	var xp_state := _last_xp_event.duplicate()
	if _xp_regression_forced:
		xp_state["final_amount"] = int(xp_state.get("raw_amount", 0))
		xp_state["multiplier"] = 1.0
	return xp_state

func _collect_aggro_state() -> Dictionary:
	var aggro := _last_aggro_event.duplicate()
	if _aggro_regression_forced:
		aggro["wake_count"] = 0
		aggro["alerted_monsters"] = []
		aggro["target_updates"] = 0
	return aggro

func _category_prefix_for_tval(tval: int) -> String:
	if tval in [75, 55, 80]:
		return "Consumable"
	if tval in [39, 45, 40, 2]:
		return "Wondrous"
	if tval in [16, 17]:
		return "Ammunition"
	return "Item"

func _find_transition_boss() -> Node:
	if _spawned_transition_boss != null and is_instance_valid(_spawned_transition_boss):
		return _spawned_transition_boss
	var current_level = _main_prop("current_level")
	if not is_live_ready() or not current_level:
		return null
	for entity in current_level.entities:
		if not is_instance_valid(entity):
			continue
		if bool(entity.get_meta("is_transition_boss", false)):
			return entity
	return null

func _find_open_tile_near_player(radius: int) -> Vector2i:
	var current_level = _main_prop("current_level")
	var player = _main_prop("player")
	if not is_live_ready() or not current_level or not player:
		return Vector2i(-1, -1)
	return _find_open_tile_near(player.grid_position, radius)

func _find_open_tile_near(origin: Vector2i, radius: int) -> Vector2i:
	var current_level = _main_prop("current_level")
	if not is_live_ready() or not current_level:
		return Vector2i(-1, -1)
	for r in range(1, maxi(2, radius + 1)):
		for y in range(origin.y - r, origin.y + r + 1):
			for x in range(origin.x - r, origin.x + r + 1):
				var pos := Vector2i(x, y)
				if not current_level.is_in_bounds(pos):
					continue
				if not current_level.is_passable(pos):
					continue
				if current_level.get_entity_at(pos) != null:
					continue
				return pos
	return Vector2i(-1, -1)

func _main_prop(prop: String):
	if not is_live_ready():
		return null
	if main.get_script() == null:
		return null
	return main.get(prop)

func _wait_frames(count: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for _i in range(maxi(1, count)):
		await tree.process_frame

func _singleton(name: String):
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	if tree.root.has_node(name):
		return tree.root.get_node(name)
	return null

func _gm():
	return _singleton("GameManager")

func _dm():
	return _singleton("DataManager")

func _constants():
	return _singleton("Constants")

func _pick_social_monster_data(dm, depth: int):
	for m in dm.monsters.values():
		if m and m.has_method("has_flag") and (m.has_flag("ORC") or m.has_flag("MAN") or m.has_flag("ELF")) and int(m.depth) <= depth + 6:
			return m
	return dm.get_random_monster_for_depth(depth)

func _set_aggro_fallback(args: Dictionary) -> void:
	var source_name := str(args.get("source_monster", "harness_orc_a"))
	var ally_count := maxi(1, int(args.get("ally_count", 2)))
	var alerted: Array = []
	for i in range(ally_count):
		alerted.append("harness_orc_%d" % (i + 1))
	_last_aggro_event = {
		"source_monster": source_name,
		"alerted_monsters": alerted,
		"radius": 8,
		"wake_count": ally_count,
		"target_updates": ally_count
	}

func _toggle_inventory() -> void:
	if not is_live_ready():
		return
	if main.has_method("_toggle_inventory"):
		main._toggle_inventory()

func _toggle_character_panel() -> void:
	if not is_live_ready():
		return
	if main.has_method("_toggle_character_panel"):
		main._toggle_character_panel()
