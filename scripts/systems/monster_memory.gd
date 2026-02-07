extends RefCounted
class_name MonsterMemory
## Monster memory / lore discovery system.
## Tracks how much the player has learned about each monster type.
## Knowledge reveals more information over time.

signal monster_observed(monster_id: int, observation_count: int)
signal knowledge_tier_reached(monster_id: int, tier: int)

# Knowledge tiers - observations needed for each tier
enum KnowledgeTier {
	UNKNOWN = 0,    # 0 observations - "Unknown creature"
	IDENTIFIED = 1, # 1 observation - Name only
	BASIC = 2,      # 3 observations - HP, basic attack
	DETAILED = 3,   # 5 observations - All attacks, resistances
	COMPLETE = 4,   # 10 observations - Full stats, flags
}

# Observations needed for each tier
const TIER_THRESHOLDS: Array[int] = [0, 1, 3, 5, 10]

# Monster observation tracking: monster_id -> observation_count
var seen_monsters: Dictionary = {}

# Monster name cache for saving (since we only store IDs)
var monster_names: Dictionary = {}  # monster_id -> name

func _init() -> void:
	pass

# ============================================================================
# OBSERVATION RECORDING
# ============================================================================

func record_observation(monster: Monster) -> void:
	# Record an observation of a monster (when seen in FOV or fought)
	if not is_instance_valid(monster) or not monster.monster_data:
		return

	var monster_id: int = monster.monster_data.index
	var monster_name: String = monster.entity_name

	# Store name for reference
	monster_names[monster_id] = monster_name

	# Increment observation count
	var old_count: int = seen_monsters.get(monster_id, 0)
	var new_count: int = old_count + 1
	seen_monsters[monster_id] = new_count

	# Check for tier advancement
	var old_tier: int = _get_tier_for_count(old_count)
	var new_tier: int = _get_tier_for_count(new_count)

	monster_observed.emit(monster_id, new_count)

	if new_tier > old_tier:
		knowledge_tier_reached.emit(monster_id, new_tier)
		_log_tier_advancement(monster_name, new_tier)

func record_observation_by_id(monster_id: int, monster_name: String = "") -> void:
	# Record observation by ID (for loading from save)
	if monster_name != "":
		monster_names[monster_id] = monster_name

	var old_count: int = seen_monsters.get(monster_id, 0)
	var new_count: int = old_count + 1
	seen_monsters[monster_id] = new_count

	monster_observed.emit(monster_id, new_count)

func _get_tier_for_count(count: int) -> int:
	for i in range(TIER_THRESHOLDS.size() - 1, -1, -1):
		if count >= TIER_THRESHOLDS[i]:
			return i
	return 0

func _log_tier_advancement(monster_name: String, tier: int) -> void:
	match tier:
		KnowledgeTier.IDENTIFIED:
			GameManager.log_message("You can now identify %s." % monster_name, ThemeColors.MSG_INFO)
		KnowledgeTier.BASIC:
			GameManager.log_message("You've learned basic information about %s." % monster_name, ThemeColors.MSG_INFO)
		KnowledgeTier.DETAILED:
			GameManager.log_message("You've learned detailed information about %s." % monster_name, ThemeColors.MSG_INFO)
		KnowledgeTier.COMPLETE:
			GameManager.log_message("You have complete knowledge of %s!" % monster_name, ThemeColors.ABILITY_LEARNED)

# ============================================================================
# KNOWLEDGE QUERIES
# ============================================================================

func get_observation_count(monster_id: int) -> int:
	return seen_monsters.get(monster_id, 0)

func get_knowledge_tier(monster_id: int) -> int:
	var count: int = get_observation_count(monster_id)
	return _get_tier_for_count(count)

func get_effective_observations(monster_id: int, player_lore: int) -> int:
	# Apply lore skill bonus to observation count
	# Bonus = player_lore / 2 (rounded down)
	var base_obs: int = get_observation_count(monster_id)
	var lore_bonus: int = player_lore / 2
	return base_obs + lore_bonus

func get_effective_tier(monster_id: int, player_lore: int) -> int:
	var effective_obs: int = get_effective_observations(monster_id, player_lore)
	return _get_tier_for_count(effective_obs)

# ============================================================================
# INFORMATION DISPLAY
# ============================================================================

func get_visible_info(monster: Monster, player_lore: int) -> Dictionary:
	# Get a dictionary of information visible to the player about this monster
	# Based on knowledge tier with lore skill bonus
	var info: Dictionary = {
		"name": "???",
		"description": "",
		"health_known": false,
		"current_health": 0,
		"max_health": 0,
		"health_percent": 0.0,
		"attacks_known": false,
		"attacks": [],
		"resistances_known": false,
		"resistances": [],
		"full_stats_known": false,
		"stats": {},
		"flags_known": false,
		"flags": [],
	}

	if not is_instance_valid(monster) or not monster.monster_data:
		return info

	var monster_id: int = monster.monster_data.index
	var tier: int = get_effective_tier(monster_id, player_lore)

	# UNKNOWN tier - reveal nothing
	if tier < KnowledgeTier.IDENTIFIED:
		return info

	# IDENTIFIED tier - name only
	info.name = monster.entity_name
	info.description = ""

	if tier < KnowledgeTier.BASIC:
		return info

	# BASIC tier - HP, basic attack info
	info.health_known = true
	info.current_health = monster.current_health
	info.max_health = monster.max_health
	info.health_percent = float(monster.current_health) / float(monster.max_health) if monster.max_health > 0 else 0.0

	# Show primary attack only
	if monster.monster_data.attacks.size() > 0:
		var primary_attack = monster.monster_data.attacks[0]
		info.attacks_known = true
		info.attacks = [{
			"method": primary_attack.method,
			"damage": primary_attack.damage_dice,
		}]

	if tier < KnowledgeTier.DETAILED:
		return info

	# DETAILED tier - all attacks, resistances
	info.attacks.clear()
	for attack in monster.monster_data.attacks:
		info.attacks.append({
			"method": attack.method,
			"effect": attack.effect,
			"bonus": attack.attack_bonus,
			"damage": attack.damage_dice,
		})

	info.resistances_known = true
	info.resistances = _get_monster_resistances(monster)

	if tier < KnowledgeTier.COMPLETE:
		return info

	# COMPLETE tier - full stats and flags
	info.full_stats_known = true
	info.stats = {
		"speed": monster.speed,
		"evasion": monster.evasion_bonus,
		"melee": monster.melee_bonus,
		"perception": monster.monster_data.perception,
		"stealth": monster.monster_data.stealth,
		"will": monster.monster_data.will,
		"protection": monster.monster_data.protection_dice,
	}

	info.flags_known = true
	info.flags = monster.monster_data.flags.duplicate()
	info.description = monster.monster_data.description

	return info

func _get_monster_resistances(monster: Monster) -> Array:
	var resists: Array = []
	var data = monster.monster_data

	if data.has_flag("RES_FIRE"):
		resists.append("Fire")
	if data.has_flag("RES_COLD"):
		resists.append("Cold")
	if data.has_flag("RES_POIS"):
		resists.append("Poison")
	if data.has_flag("NO_FEAR"):
		resists.append("Fear")
	if data.has_flag("NO_SLEEP"):
		resists.append("Sleep")
	if data.has_flag("NO_STUN"):
		resists.append("Stun")
	if data.has_flag("NO_CONF"):
		resists.append("Confusion")

	return resists

# ============================================================================
# TEXT FORMATTING FOR UI
# ============================================================================

func format_monster_info_for_look(monster: Monster, player_lore: int) -> Array[String]:
	# Format monster info for the look panel
	var lines: Array[String] = []
	var info: Dictionary = get_visible_info(monster, player_lore)

	if info.name == "???":
		# Procedural DF-style description for unknown creatures
		if is_instance_valid(monster) and monster.monster_data:
			var desc_data: Dictionary = {
				"char": monster.monster_data.display_char,
				"color": monster.monster_data.color,
				"health_dice": monster.monster_data.health_dice,
				"flags": monster.monster_data.flags,
			}
			var desc: String = DescriptionGenerator.generate_monster_description(desc_data, 0)
			lines.append("[color=#9CA3AF][i]%s[/i][/color]" % desc)
		else:
			lines.append("[color=gray]Unknown creature[/color]")
		return lines

	# Name with color based on stance
	var color: String = "white"
	if is_instance_valid(monster):
		match monster.stance:
			Constants.Stance.AGGRESSIVE:
				color = "red"
			Constants.Stance.CONFIDENT:
				color = "orange"
			Constants.Stance.FLEEING:
				color = "gray"

	lines.append("[color=%s]%s[/color]" % [color, info.name])

	# Procedural description at IDENTIFIED/BASIC/DETAILED tiers (before COMPLETE)
	var monster_id: int = monster.monster_data.index if is_instance_valid(monster) and monster.monster_data else -1
	var effective_tier: int = get_effective_tier(monster_id, player_lore) if monster_id >= 0 else 0
	if effective_tier < KnowledgeTier.COMPLETE and is_instance_valid(monster) and monster.monster_data:
		var desc_data: Dictionary = {
			"char": monster.monster_data.display_char,
			"color": monster.monster_data.color,
			"health_dice": monster.monster_data.health_dice,
			"flags": monster.monster_data.flags,
		}
		var desc: String = DescriptionGenerator.generate_monster_description(desc_data, effective_tier)
		lines.append("[color=#9CA3AF][i]%s[/i][/color]" % desc)

	# Health (if known)
	if info.health_known:
		var health_color: String = "green"
		if info.health_percent < 0.3:
			health_color = "red"
		elif info.health_percent < 0.6:
			health_color = "yellow"
		lines.append("[color=%s]HP: %d/%d (%.0f%%)[/color]" % [
			health_color, info.current_health, info.max_health, info.health_percent * 100
		])
	else:
		lines.append("HP: ???")

	# Attacks (if known)
	if info.attacks_known and info.attacks.size() > 0:
		var attack_str: String = "Attacks: "
		var attack_parts: Array[String] = []
		for attack in info.attacks:
			if "bonus" in attack and "effect" in attack:
				attack_parts.append("%s (%s, +%d)" % [attack.method, attack.damage, attack.bonus])
			else:
				attack_parts.append("%s (%s)" % [attack.method, attack.damage])
		lines.append(attack_str + ", ".join(attack_parts))

	# Resistances (if known)
	if info.resistances_known and info.resistances.size() > 0:
		lines.append("Resists: %s" % ", ".join(info.resistances))

	# Full stats (if known)
	if info.full_stats_known:
		var stats = info.stats
		lines.append("Speed: %d | Evasion: %+d | Melee: %+d" % [
			stats.speed, stats.evasion, stats.melee
		])
		if stats.protection != "":
			lines.append("Protection: %s" % stats.protection)

	# Flags (if known)
	if info.flags_known and info.flags.size() > 0:
		# Filter to interesting flags
		var display_flags: Array[String] = []
		for flag in info.flags:
			if flag in ["UNIQUE", "UNDEAD", "DRAGON", "DEMON", "ORC", "TROLL", "EVIL"]:
				display_flags.append(flag)
		if display_flags.size() > 0:
			lines.append("Traits: %s" % ", ".join(display_flags))

	# Description (if known)
	if info.description != "":
		lines.append("")
		lines.append("[i]%s[/i]" % info.description)

	return lines

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	return {
		"seen_monsters": seen_monsters.duplicate(),
		"monster_names": monster_names.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	if "seen_monsters" in data:
		seen_monsters = data.seen_monsters.duplicate()
	if "monster_names" in data:
		monster_names = data.monster_names.duplicate()

static func create_from_dict(data: Dictionary) -> RefCounted:
	"""Factory function to create MonsterMemory from saved data."""
	var memory = (load("res://scripts/systems/monster_memory.gd") as GDScript).new()
	memory.from_dict(data)
	return memory
