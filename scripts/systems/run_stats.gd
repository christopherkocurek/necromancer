class_name RunStats
extends RefCounted
## Tracks statistics for a single run/playthrough.
## Used for death recap, high scores, and epitaph generation.

# Death information
var died_from: String = ""
var killer_name: String = ""
var killer_idx: int = -1

# Combat statistics
var total_damage_dealt: int = 0
var biggest_hit: int = 0
var biggest_enemy_killed: int = 0
var biggest_enemy_killed_name: String = ""
var enemies_killed: int = 0
var silent_kills: int = 0

# Stealth statistics
var enemies_avoided: int = 0
var times_detected: int = 0
var stealth_streak_current: int = 0
var stealth_streak_max: int = 0

# Exploration statistics
var doors_closed: int = 0
var stairs_descended: int = 0
var stairs_ascended: int = 0
var max_depth_reached: int = 0

# Item usage
var potions_quaffed: int = 0
var herbs_consumed: int = 0
var items_identified: int = 0

# Achievements / special flags
var saw_sauron: bool = false
var found_thrain: bool = false
var killed_nazgul: bool = false
var stole_ring: bool = false
var escaped: bool = false
var necromancer_defeated: bool = false

# Timing
var total_turns: int = 0
var start_time: int = 0  # Unix timestamp
var end_time: int = 0

func _init() -> void:
	start_time = Time.get_unix_time_from_system()

# ============================================================================
# STAT TRACKING METHODS
# ============================================================================

func record_damage_dealt(amount: int) -> void:
	total_damage_dealt += amount
	if amount > biggest_hit:
		biggest_hit = amount

func record_kill(monster_name: String, monster_xp: int, was_silent: bool = false) -> void:
	enemies_killed += 1
	if monster_xp > biggest_enemy_killed:
		biggest_enemy_killed = monster_xp
		biggest_enemy_killed_name = monster_name
	if was_silent:
		silent_kills += 1

func record_detection() -> void:
	times_detected += 1
	stealth_streak_current = 0

func record_stealth_turn() -> void:
	stealth_streak_current += 1
	if stealth_streak_current > stealth_streak_max:
		stealth_streak_max = stealth_streak_current

func record_avoidance() -> void:
	enemies_avoided += 1

func record_descent(new_depth: int) -> void:
	stairs_descended += 1
	if new_depth > max_depth_reached:
		max_depth_reached = new_depth

func record_ascent() -> void:
	stairs_ascended += 1

func record_death(cause: String, killer: String, killer_id: int) -> void:
	died_from = cause
	killer_name = killer
	killer_idx = killer_id
	end_time = Time.get_unix_time_from_system()

func record_escape() -> void:
	escaped = true
	end_time = Time.get_unix_time_from_system()

func record_victory() -> void:
	necromancer_defeated = true
	end_time = Time.get_unix_time_from_system()

# ============================================================================
# QUERY METHODS (for epitaph generation)
# ============================================================================

func was_long_run() -> bool:
	return total_turns > 10000

func was_short_run() -> bool:
	return total_turns < 500

func died_deep() -> bool:
	return max_depth_reached >= 12

func died_shallow() -> bool:
	return max_depth_reached <= 3

func was_pacifist() -> bool:
	return enemies_killed == 0

func was_slayer() -> bool:
	return enemies_killed > 50

func had_high_stealth() -> bool:
	if times_detected == 0:
		return enemies_avoided > 10
	return float(enemies_avoided) / float(times_detected + enemies_avoided) > 0.7

func get_play_duration_seconds() -> int:
	var end: int = end_time if end_time > 0 else Time.get_unix_time_from_system()
	return end - start_time

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	return {
		"died_from": died_from,
		"killer_name": killer_name,
		"killer_idx": killer_idx,
		"total_damage_dealt": total_damage_dealt,
		"biggest_hit": biggest_hit,
		"biggest_enemy_killed": biggest_enemy_killed,
		"biggest_enemy_killed_name": biggest_enemy_killed_name,
		"enemies_killed": enemies_killed,
		"silent_kills": silent_kills,
		"enemies_avoided": enemies_avoided,
		"times_detected": times_detected,
		"stealth_streak_max": stealth_streak_max,
		"doors_closed": doors_closed,
		"stairs_descended": stairs_descended,
		"stairs_ascended": stairs_ascended,
		"max_depth_reached": max_depth_reached,
		"potions_quaffed": potions_quaffed,
		"herbs_consumed": herbs_consumed,
		"items_identified": items_identified,
		"saw_sauron": saw_sauron,
		"found_thrain": found_thrain,
		"killed_nazgul": killed_nazgul,
		"stole_ring": stole_ring,
		"escaped": escaped,
		"necromancer_defeated": necromancer_defeated,
		"total_turns": total_turns,
		"start_time": start_time,
		"end_time": end_time,
	}

static func from_dict(data: Dictionary) -> RunStats:
	var stats := RunStats.new()
	stats.died_from = data.get("died_from", "")
	stats.killer_name = data.get("killer_name", "")
	stats.killer_idx = data.get("killer_idx", -1)
	stats.total_damage_dealt = data.get("total_damage_dealt", 0)
	stats.biggest_hit = data.get("biggest_hit", 0)
	stats.biggest_enemy_killed = data.get("biggest_enemy_killed", 0)
	stats.biggest_enemy_killed_name = data.get("biggest_enemy_killed_name", "")
	stats.enemies_killed = data.get("enemies_killed", 0)
	stats.silent_kills = data.get("silent_kills", 0)
	stats.enemies_avoided = data.get("enemies_avoided", 0)
	stats.times_detected = data.get("times_detected", 0)
	stats.stealth_streak_max = data.get("stealth_streak_max", 0)
	stats.doors_closed = data.get("doors_closed", 0)
	stats.stairs_descended = data.get("stairs_descended", 0)
	stats.stairs_ascended = data.get("stairs_ascended", 0)
	stats.max_depth_reached = data.get("max_depth_reached", 0)
	stats.potions_quaffed = data.get("potions_quaffed", 0)
	stats.herbs_consumed = data.get("herbs_consumed", 0)
	stats.items_identified = data.get("items_identified", 0)
	stats.saw_sauron = data.get("saw_sauron", false)
	stats.found_thrain = data.get("found_thrain", false)
	stats.killed_nazgul = data.get("killed_nazgul", false)
	stats.stole_ring = data.get("stole_ring", false)
	stats.escaped = data.get("escaped", false)
	stats.necromancer_defeated = data.get("necromancer_defeated", false)
	stats.total_turns = data.get("total_turns", 0)
	stats.start_time = data.get("start_time", 0)
	stats.end_time = data.get("end_time", 0)
	return stats
