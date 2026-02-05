extends Node
## Parses and manages game data from The Necromancer data files.
## Format is based on Sil-Q, not standard Angband.

# Parsed data storage
var monsters: Dictionary = {}  # name -> MonsterData
var items: Dictionary = {}     # name -> ItemData
var artifacts: Dictionary = {} # name -> ArtifactData
var abilities: Dictionary = {} # name -> AbilityData
var races: Dictionary = {}     # name -> RaceData
var houses: Dictionary = {}    # name -> HouseData
var terrain: Dictionary = {}   # char -> TerrainData
var vaults: Array[VaultData] = []

# Data file paths
const DATA_PATH := "res://data/"

func _ready() -> void:
	load_all_data()

func load_all_data() -> void:
	print("DataManager: Loading game data...")
	load_terrain()
	load_monsters()
	load_items()
	load_artifacts()
	load_abilities()
	load_races()
	load_houses()
	load_vaults()
	_validate_data()

# ============================================================================
# MONSTER PARSING (Sil-Q format)
# ============================================================================

func load_monsters() -> void:
	var file := FileAccess.open(DATA_PATH + "monster.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load monster.txt")
		return

	var current_monster: MonsterData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				# N:ID:Name
				if current_monster and current_monster.name != "" and not current_monster.name.begins_with("<"):
					monsters[current_monster.name] = current_monster
				current_monster = MonsterData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_monster.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_monster.name = n_parts[1]
			"G":
				# G:symbol:color
				if current_monster:
					var g_parts := value.split(":")
					if g_parts.size() >= 1:
						current_monster.display_char = g_parts[0]
					if g_parts.size() >= 2:
						current_monster.color = g_parts[1]
			"W":
				# W:depth:rarity
				if current_monster:
					var w_parts := value.split(":")
					if w_parts.size() >= 1:
						current_monster.depth = int(w_parts[0])
					if w_parts.size() >= 2:
						current_monster.rarity = int(w_parts[1])
			"I":
				# I:speed:health_dice:light_radius
				if current_monster:
					var i_parts := value.split(":")
					if i_parts.size() >= 1:
						current_monster.speed = int(i_parts[0])
					if i_parts.size() >= 2:
						current_monster.health_dice = i_parts[1]
					if i_parts.size() >= 3:
						current_monster.light_radius = int(i_parts[2])
			"A":
				# A:sleepiness:perception:stealth:will
				if current_monster:
					var a_parts := value.split(":")
					if a_parts.size() >= 1:
						current_monster.alertness = int(a_parts[0])
					if a_parts.size() >= 2:
						current_monster.perception = int(a_parts[1])
					if a_parts.size() >= 3:
						current_monster.stealth = int(a_parts[2])
					if a_parts.size() >= 4:
						current_monster.will = int(a_parts[3])
			"P":
				# P:[evasion,protection_dice] or P:[+evasion,protection_dice]
				if current_monster:
					var p_value := value.strip_edges()
					# Parse [+3,1d4] format
					if p_value.begins_with("[") and p_value.ends_with("]"):
						p_value = p_value.substr(1, p_value.length() - 2)
						var p_parts := p_value.split(",")
						if p_parts.size() >= 1:
							var evasion_str := p_parts[0].strip_edges()
							if evasion_str.begins_with("+"):
								evasion_str = evasion_str.substr(1)
							current_monster.evasion = int(evasion_str)
						if p_parts.size() >= 2:
							current_monster.protection_dice = p_parts[1].strip_edges()
			"B":
				# B:method:effect:(bonus,damage_dice)
				if current_monster:
					var b_parts := value.split(":")
					if b_parts.size() >= 2:
						var attack := AttackData.new()
						attack.method = b_parts[0]
						attack.effect = b_parts[1]
						if b_parts.size() >= 3:
							# Parse (bonus,damage_dice) format
							var dmg_str := b_parts[2].strip_edges()
							if dmg_str.begins_with("(") and dmg_str.ends_with(")"):
								dmg_str = dmg_str.substr(1, dmg_str.length() - 2)
								var dmg_parts := dmg_str.split(",")
								if dmg_parts.size() >= 1:
									var bonus_str := dmg_parts[0].strip_edges()
									if bonus_str.begins_with("+"):
										bonus_str = bonus_str.substr(1)
									attack.attack_bonus = int(bonus_str)
								if dmg_parts.size() >= 2:
									attack.damage_dice = dmg_parts[1].strip_edges()
						current_monster.attacks.append(attack)
			"S":
				# S:spell_frequency | spell_power or spell types
				if current_monster:
					if value.contains("|"):
						var s_parts := value.split("|")
						if s_parts.size() >= 1:
							current_monster.spell_frequency = int(s_parts[0].strip_edges())
						if s_parts.size() >= 2:
							current_monster.spell_power = int(s_parts[1].strip_edges())
					else:
						# Spell types
						var spells := value.split("|")
						for spell in spells:
							current_monster.spell_types.append(spell.strip_edges())
			"F":
				# F:FLAG1 | FLAG2 | FLAG3
				if current_monster:
					var flag_list := value.split("|")
					for flag in flag_list:
						var f := flag.strip_edges()
						if f != "":
							current_monster.set_flag(f)
			"D":
				# D:description text
				if current_monster:
					if current_monster.description.is_empty():
						current_monster.description = value
					else:
						current_monster.description += " " + value

	if current_monster and current_monster.name != "" and not current_monster.name.begins_with("<"):
		monsters[current_monster.name] = current_monster

# ============================================================================
# ITEM PARSING
# ============================================================================

func load_items() -> void:
	var file := FileAccess.open(DATA_PATH + "object.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load object.txt")
		return

	var current_item: ItemData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_item and current_item.name != "":
					items[current_item.name] = current_item
				current_item = ItemData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_item.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_item.name = n_parts[1]
			"G":
				if current_item:
					var g_parts := value.split(":")
					if g_parts.size() >= 1:
						current_item.display_char = g_parts[0]
					if g_parts.size() >= 2:
						current_item.color = g_parts[1]
			"I":
				if current_item:
					var i_parts := value.split(":")
					if i_parts.size() >= 1:
						current_item.tval = int(i_parts[0])
					if i_parts.size() >= 2:
						current_item.sval = int(i_parts[1])
					if i_parts.size() >= 3:
						current_item.pval = int(i_parts[2])
			"W":
				if current_item:
					var w_parts := value.split(":")
					if w_parts.size() >= 1:
						current_item.depth = int(w_parts[0])
					if w_parts.size() >= 2:
						current_item.rarity = int(w_parts[1])
					if w_parts.size() >= 3:
						current_item.weight = int(w_parts[2])
					if w_parts.size() >= 4:
						current_item.cost = int(w_parts[3])
			"A":
				if current_item:
					current_item.allocation = value
			"P":
				if current_item:
					# P:attack_bonus:damage_dice:evasion_bonus:protection_dice
					var p_parts := value.split(":")
					if p_parts.size() >= 1:
						current_item.attack_bonus = int(p_parts[0])
					if p_parts.size() >= 2:
						current_item.damage_dice = p_parts[1]
					if p_parts.size() >= 3:
						current_item.evasion_bonus = int(p_parts[2])
					if p_parts.size() >= 4:
						current_item.protection_dice = p_parts[3]
			"F":
				if current_item:
					var flags := value.split("|")
					for flag in flags:
						var f := flag.strip_edges()
						if f != "":
							current_item.flags.append(f)
			"D":
				if current_item:
					if current_item.description.is_empty():
						current_item.description = value
					else:
						current_item.description += " " + value

	if current_item and current_item.name != "":
		items[current_item.name] = current_item

# ============================================================================
# ARTIFACT PARSING
# ============================================================================

func load_artifacts() -> void:
	var file := FileAccess.open(DATA_PATH + "artefact.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load artefact.txt")
		return

	var current_artifact: ArtifactData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_artifact and current_artifact.name != "":
					artifacts[current_artifact.name] = current_artifact
				current_artifact = ArtifactData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_artifact.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_artifact.name = n_parts[1]
			"I":
				if current_artifact:
					var i_parts := value.split(":")
					if i_parts.size() >= 1:
						current_artifact.tval = int(i_parts[0])
					if i_parts.size() >= 2:
						current_artifact.sval = int(i_parts[1])
					if i_parts.size() >= 3:
						current_artifact.pval = int(i_parts[2])
			"W":
				if current_artifact:
					var w_parts := value.split(":")
					if w_parts.size() >= 1:
						current_artifact.depth = int(w_parts[0])
					if w_parts.size() >= 2:
						current_artifact.rarity = int(w_parts[1])
					if w_parts.size() >= 3:
						current_artifact.weight = int(w_parts[2])
			"P":
				if current_artifact:
					# P:attack_bonus:damage_dice:evasion_bonus:protection_dice
					var p_parts := value.split(":")
					if p_parts.size() >= 1:
						current_artifact.attack_bonus = int(p_parts[0])
					if p_parts.size() >= 2:
						current_artifact.damage_dice = p_parts[1]
					if p_parts.size() >= 3:
						current_artifact.evasion_bonus = int(p_parts[2])
					if p_parts.size() >= 4:
						current_artifact.protection_dice = p_parts[3]
			"F":
				if current_artifact:
					var flags := value.split("|")
					for flag in flags:
						var f := flag.strip_edges()
						if f != "":
							current_artifact.flags.append(f)
			"D":
				if current_artifact:
					if current_artifact.description.is_empty():
						current_artifact.description = value
					else:
						current_artifact.description += " " + value

	if current_artifact and current_artifact.name != "":
		artifacts[current_artifact.name] = current_artifact

# ============================================================================
# ABILITY PARSING
# ============================================================================

func load_abilities() -> void:
	var file := FileAccess.open(DATA_PATH + "ability.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load ability.txt")
		return

	var current_ability: AbilityData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_ability and current_ability.name != "":
					abilities[current_ability.name] = current_ability
				current_ability = AbilityData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_ability.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_ability.name = n_parts[1]
			"I":
				if current_ability:
					var i_parts := value.split(":")
					if i_parts.size() >= 1:
						current_ability.skill_type = int(i_parts[0])
					if i_parts.size() >= 2:
						current_ability.ability_num = int(i_parts[1])
					if i_parts.size() >= 3:
						current_ability.level_requirement = int(i_parts[2])
			"P":
				if current_ability:
					current_ability.prerequisites = value
					# Parse into structured format: skill/ability:skill/ability:...
					var prereq_list := value.split(":")
					for prereq in prereq_list:
						var p_parts := prereq.split("/")
						if p_parts.size() >= 2:
							current_ability.prereqs.append({
								"skill": int(p_parts[0]),
								"ability": int(p_parts[1])
							})
			"T":
				# T: lines grant abilities from items
				# Format: tval:min_sval:max_sval
				if current_ability:
					var t_parts := value.split(":")
					if t_parts.size() >= 3:
						current_ability.item_grants.append({
							"tval": int(t_parts[0]),
							"min_sval": int(t_parts[1]),
							"max_sval": int(t_parts[2])
						})
			"D":
				if current_ability:
					if current_ability.description.is_empty():
						current_ability.description = value
					else:
						current_ability.description += " " + value

	if current_ability and current_ability.name != "":
		abilities[current_ability.name] = current_ability

# ============================================================================
# RACE & HOUSE PARSING
# ============================================================================

func load_races() -> void:
	var file := FileAccess.open(DATA_PATH + "race.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load race.txt")
		return

	var current_race: RaceData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_race and current_race.name != "":
					races[current_race.name] = current_race
				current_race = RaceData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_race.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_race.name = n_parts[1]
			"S":
				if current_race:
					var s_parts := value.split(":")
					if s_parts.size() >= 4:
						current_race.str_mod = int(s_parts[0])
						current_race.dex_mod = int(s_parts[1])
						current_race.con_mod = int(s_parts[2])
						current_race.gra_mod = int(s_parts[3])
			"I":
				# I:history:agebase:agemax
				if current_race:
					var i_parts := value.split(":")
					if i_parts.size() >= 1:
						current_race.history_index = int(i_parts[0])
					if i_parts.size() >= 2:
						current_race.age_base = int(i_parts[1])
					if i_parts.size() >= 3:
						current_race.age_max = int(i_parts[2])
			"H":
				# H:base_height:mod_height
				if current_race:
					var h_parts := value.split(":")
					if h_parts.size() >= 2:
						current_race.height_base = int(h_parts[0])
						current_race.height_mod = int(h_parts[1])
			"W":
				# W:base_weight:mod_weight
				if current_race:
					var w_parts := value.split(":")
					if w_parts.size() >= 2:
						current_race.weight_base = int(w_parts[0])
						current_race.weight_mod = int(w_parts[1])
			"C":
				# C:house_index|house_index|... (compatible houses)
				if current_race:
					var house_indices := value.split("|")
					for idx_str in house_indices:
						var idx: int = int(idx_str.strip_edges())
						current_race.compatible_houses.append(idx)
			"F":
				# F:FLAG1 | FLAG2 | ... (racial flags)
				if current_race:
					var flag_list := value.split("|")
					for flag in flag_list:
						var f := flag.strip_edges()
						if f != "":
							current_race.flags.append(f)
			"E":
				# E:tval:sval:min:max (starting equipment)
				if current_race:
					var e_parts := value.split(":")
					if e_parts.size() >= 4:
						current_race.starting_equipment.append({
							"tval": int(e_parts[0]),
							"sval": int(e_parts[1]),
							"min_qty": int(e_parts[2]),
							"max_qty": int(e_parts[3])
						})
			"D":
				if current_race:
					if current_race.description.is_empty():
						current_race.description = value
					else:
						current_race.description += " " + value

	if current_race and current_race.name != "":
		races[current_race.name] = current_race

func load_houses() -> void:
	var file := FileAccess.open(DATA_PATH + "house.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load house.txt")
		return

	var current_house: HouseData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_house and current_house.name != "":
					houses[current_house.name] = current_house
				current_house = HouseData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_house.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_house.name = n_parts[1]
			"A":
				# A:alternate_name (e.g. "Lothlorien" for "Of Lothlorien")
				if current_house:
					current_house.alternate_name = value
			"B":
				# B:short_name (e.g. "Lorien")
				if current_house:
					current_house.short_name = value
			"F":
				# F:affinity_flag (e.g. LOR_AFFINITY, MEL_AFFINITY)
				if current_house:
					var affinity := value.strip_edges()
					if affinity != "":
						current_house.affinities.append(affinity)
			"S":
				if current_house:
					var s_parts := value.split(":")
					if s_parts.size() >= 4:
						current_house.str_mod = int(s_parts[0])
						current_house.dex_mod = int(s_parts[1])
						current_house.con_mod = int(s_parts[2])
						current_house.gra_mod = int(s_parts[3])
			"D":
				if current_house:
					if current_house.description.is_empty():
						current_house.description = value
					else:
						current_house.description += " " + value

	if current_house and current_house.name != "":
		houses[current_house.name] = current_house

# ============================================================================
# TERRAIN PARSING
# ============================================================================

func load_terrain() -> void:
	var file := FileAccess.open(DATA_PATH + "terrain.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load terrain.txt")
		return

	var current_terrain: TerrainData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#") or line.begins_with("V:"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_terrain and current_terrain.name != "":
					terrain[current_terrain.display_char] = current_terrain
				current_terrain = TerrainData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_terrain.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_terrain.name = n_parts[1]
			"G":
				if current_terrain:
					var g_parts := value.split(":")
					if g_parts.size() >= 1:
						current_terrain.display_char = g_parts[0]
					if g_parts.size() >= 2:
						current_terrain.color = g_parts[1]
			"M":
				if current_terrain:
					current_terrain.mimic_char = value
			"F":
				if current_terrain:
					var flags := value.split("|")
					for flag in flags:
						var f := flag.strip_edges()
						if f != "":
							current_terrain.flags.append(f)

	if current_terrain and current_terrain.name != "":
		terrain[current_terrain.display_char] = current_terrain

# ============================================================================
# VAULT PARSING
# ============================================================================

func load_vaults() -> void:
	var file := FileAccess.open(DATA_PATH + "vault.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load vault.txt")
		return

	var current_vault: VaultData = null
	var reading_map := false

	while not file.eof_reached():
		var line := file.get_line()
		var stripped := line.strip_edges()

		if stripped.is_empty() or stripped.begins_with("#") or stripped.begins_with("V:"):
			continue

		var parts := stripped.split(":")
		if parts.size() >= 2:
			var key := parts[0]
			var value := ":".join(parts.slice(1))

			match key:
				"N":
					if current_vault and current_vault.name != "":
						vaults.append(current_vault)
					current_vault = VaultData.new()
					reading_map = false
					var n_parts := value.split(":")
					if n_parts.size() >= 1:
						current_vault.index = int(n_parts[0])
					if n_parts.size() >= 2:
						current_vault.name = n_parts[1]
				"X":
					if current_vault:
						var x_parts := value.split(":")
						if x_parts.size() >= 1:
							current_vault.vault_type = int(x_parts[0])
						if x_parts.size() >= 2:
							current_vault.rating = int(x_parts[1])
						if x_parts.size() >= 3:
							current_vault.height = int(x_parts[2])
						if x_parts.size() >= 4:
							current_vault.width = int(x_parts[3])
				"D":
					reading_map = true
					if current_vault:
						current_vault.map_lines.append(value)
		elif reading_map and current_vault:
			current_vault.map_lines.append(stripped)

	if current_vault and current_vault.name != "":
		vaults.append(current_vault)

# ============================================================================
# DATA ACCESS HELPERS
# ============================================================================

func get_monster(name: String) -> MonsterData:
	return monsters.get(name)

func get_item(name: String) -> ItemData:
	return items.get(name)

func get_artifact(name: String) -> ArtifactData:
	return artifacts.get(name)

func get_ability(name: String) -> AbilityData:
	return abilities.get(name)

func get_abilities_for_skill(skill_type: int) -> Array[AbilityData]:
	var result: Array[AbilityData] = []
	for ability in abilities.values():
		if ability.skill_type == skill_type:
			result.append(ability)
	# Sort by level requirement then by ability_num
	result.sort_custom(func(a, b):
		if a.level_requirement != b.level_requirement:
			return a.level_requirement < b.level_requirement
		return a.ability_num < b.ability_num
	)
	return result

func get_race(name: String) -> RaceData:
	return races.get(name)

func get_house(name: String) -> HouseData:
	return houses.get(name)

func get_terrain_by_char(ch: String) -> TerrainData:
	return terrain.get(ch)

func get_random_monster_for_depth(depth: int) -> MonsterData:
	var valid_monsters: Array[MonsterData] = []
	for m in monsters.values():
		if m.depth <= depth and m.depth >= depth - 3:
			valid_monsters.append(m)
	if valid_monsters.is_empty():
		# Fallback: any monster at or below depth
		for m in monsters.values():
			if m.depth <= depth:
				valid_monsters.append(m)
	if valid_monsters.is_empty():
		return null
	return valid_monsters.pick_random()

func get_random_item_for_depth(depth: int) -> ItemData:
	var valid_items: Array[ItemData] = []
	for i in items.values():
		if i.depth <= depth and i.depth >= depth - 3:
			valid_items.append(i)
	if valid_items.is_empty():
		for i in items.values():
			if i.depth <= depth:
				valid_items.append(i)
	if valid_items.is_empty():
		return null
	return valid_items.pick_random()

func _validate_data() -> void:
	print("=== DataManager Validation ===")
	print("Loaded %d monsters, %d items, %d artifacts, %d abilities" % [
		monsters.size(), items.size(), artifacts.size(), abilities.size()
	])
	print("Loaded %d races, %d houses, %d vaults" % [
		races.size(), houses.size(), vaults.size()
	])

	# Spot-check critical content
	var warnings: Array[String] = []

	# Check for key monsters
	var key_monsters := ["Morgoth, Lord of Darkness", "Orc", "Troll", "Warg", "Spider"]
	for monster_name in key_monsters:
		if not monsters.has(monster_name):
			warnings.append("Missing key monster: " + monster_name)

	# Check for races
	var expected_races := ["Noldor", "Sindar", "Man", "Dwarf"]
	for race_name in expected_races:
		if not races.has(race_name):
			warnings.append("Missing race: " + race_name)

	# Check vaults have map data
	var empty_vaults := 0
	for vault in vaults:
		if vault.map_lines.is_empty():
			empty_vaults += 1
	if empty_vaults > 0:
		warnings.append("Found %d vaults with no map data" % empty_vaults)

	# Print warnings
	if warnings.is_empty():
		print("All validation checks passed!")
	else:
		for warning in warnings:
			push_warning("DataManager: " + warning)
		print("Validation completed with %d warnings" % warnings.size())

	print("==============================")

func get_vaults_for_depth(depth: int) -> Array[VaultData]:
	var valid_vaults: Array[VaultData] = []
	for vault in vaults:
		# vault_type determines the layer/type:
		# 0 = any, 1+ = specific dungeon layers
		# For now, allow all vaults with type <= depth
		if vault.vault_type <= depth:
			valid_vaults.append(vault)
	return valid_vaults

func get_random_vault_for_depth(depth: int) -> VaultData:
	var valid := get_vaults_for_depth(depth)
	if valid.is_empty():
		return null
	return valid.pick_random()

func get_monster_by_char(ch: String, depth: int) -> MonsterData:
	# Map single characters to monster types for vault spawning
	var char_to_monster: Dictionary = {
		"o": "Orc",
		"O": "Orc captain",
		"T": "Troll",
		"V": "Morgoth, Lord of Darkness",  # Sauron equivalent
		"g": "Goblin",
		"w": "Warg",
		"s": "Spider",
		"S": "Mirkwood Spider",
		"d": "Young dragon",
		"D": "Dragon",
		"W": "Werewolf",
		"k": "Kobold",
	}
	var monster_name: String = char_to_monster.get(ch, "")
	if monster_name and monsters.has(monster_name):
		return monsters[monster_name]
	# Fallback to random monster for depth
	return get_random_monster_for_depth(depth)

func roll_dice(dice_string: String) -> int:
	# Parse dice strings like "3d6" or "1d8+2" or "1d4"
	if dice_string.is_empty():
		return 0

	var regex := RegEx.new()
	regex.compile("(\\d+)d(\\d+)([+-]\\d+)?")
	var result := regex.search(dice_string)
	if not result:
		# Try to parse as a plain number
		if dice_string.is_valid_int():
			return int(dice_string)
		return 0

	var num_dice := int(result.get_string(1))
	var die_size := int(result.get_string(2))
	var modifier := 0
	if result.get_string(3):
		modifier = int(result.get_string(3))

	var total := 0
	for i in range(num_dice):
		total += randi_range(1, die_size)
	return total + modifier


# ============================================================================
# DATA CLASSES
# ============================================================================

class MonsterData:
	var index: int = 0
	var name: String = ""
	var display_char: String = ""
	var color: String = ""
	var speed: int = 2
	var health_dice: String = "1d4"
	var light_radius: int = 0
	var alertness: int = 10
	var perception: int = 5
	var stealth: int = 5
	var will: int = 5
	var evasion: int = 0
	var protection_dice: String = ""
	var depth: int = 1
	var rarity: int = 1
	var experience: int = 10
	var spell_frequency: int = 0
	var spell_power: int = 0
	var spell_types: Array[String] = []
	var attacks: Array[AttackData] = []
	var flags: Array[String] = []  # Keep for backwards compatibility
	var description: String = ""

	# Bitflag storage (Phase 4)
	var flags1: int = 0  # RF1 - general flags
	var flags2: int = 0  # RF2 - ability flags
	var flags3: int = 0  # RF3 - race/resist flags
	var flags4: int = 0  # RF4 - spell/ranged flags

	func roll_health() -> int:
		return DataManager.roll_dice(health_dice) if health_dice else 10

	func has_flag(flag_name: String) -> bool:
		# First check legacy array
		if flags.has(flag_name):
			return true
		# Then check bitflags
		if not Constants.FLAG_MAP.has(flag_name):
			return false
		var info: Array = Constants.FLAG_MAP[flag_name]
		var flag_set: int = info[0]
		var flag_bit: int = info[1]
		match flag_set:
			1: return (flags1 & flag_bit) != 0
			2: return (flags2 & flag_bit) != 0
			3: return (flags3 & flag_bit) != 0
			4: return (flags4 & flag_bit) != 0
		return false

	func set_flag(flag_name: String) -> void:
		# Also add to legacy array for compatibility
		if not flags.has(flag_name):
			flags.append(flag_name)
		# Set bitflag
		if not Constants.FLAG_MAP.has(flag_name):
			return
		var info: Array = Constants.FLAG_MAP[flag_name]
		var flag_set: int = info[0]
		var flag_bit: int = info[1]
		match flag_set:
			1: flags1 |= flag_bit
			2: flags2 |= flag_bit
			3: flags3 |= flag_bit
			4: flags4 |= flag_bit

class AttackData:
	var method: String = ""
	var effect: String = ""
	var attack_bonus: int = 0
	var damage_dice: String = "1d4"

class ItemData:
	var index: int = 0
	var name: String = ""
	var display_char: String = ""
	var color: String = ""
	var tval: int = 0
	var sval: int = 0
	var pval: int = 0
	var depth: int = 0
	var rarity: int = 1
	var weight: int = 0  # Tenth-pounds, also affects crit chance and damage
	var cost: int = 0
	var allocation: String = ""
	# Combat stats (Sil-Q style from P: line)
	var attack_bonus: int = 0       # Bonus to attack rolls
	var damage_dice: String = ""    # e.g. "2d5"
	var evasion_bonus: int = 0      # Bonus/penalty to evasion
	var protection_dice: String = "" # e.g. "1d4" for armor
	var flags: Array[String] = []
	var description: String = ""

class ArtifactData:
	var index: int = 0
	var name: String = ""
	var tval: int = 0
	var sval: int = 0
	var pval: int = 0
	var depth: int = 0
	var rarity: int = 1
	var weight: int = 0
	# Combat stats (Sil-Q style from P: line)
	var attack_bonus: int = 0
	var damage_dice: String = ""
	var evasion_bonus: int = 0
	var protection_dice: String = ""
	var flags: Array[String] = []
	var description: String = ""

class AbilityData:
	var index: int = 0
	var name: String = ""
	var skill_type: int = 0       # I: first value - which skill tree
	var ability_num: int = 0      # I: second value - position in skill tree
	var level_requirement: int = 0 # I: third value - skill level needed
	var prerequisites: String = ""  # Legacy string format
	var prereqs: Array = []       # P: parsed as [{skill: int, ability: int}, ...]
	var item_grants: Array = []   # T: parsed as [{tval: int, min_sval: int, max_sval: int}, ...]
	var description: String = ""

	# Keep old field name for compatibility
	var skill_requirement: int:
		get: return level_requirement
		set(v): level_requirement = v

class RaceData:
	var index: int = 0
	var name: String = ""
	var str_mod: int = 0
	var dex_mod: int = 0
	var con_mod: int = 0
	var gra_mod: int = 0
	# I: line - history and age
	var history_index: int = 0
	var age_base: int = 20
	var age_max: int = 100
	# H: line - height
	var height_base: int = 70
	var height_mod: int = 4
	# W: line - weight
	var weight_base: int = 150
	var weight_mod: int = 10
	# C: line - compatible house indices
	var compatible_houses: Array[int] = []
	# F: line - racial flags (BOW_PROFICIENCY, SWORD_PROFICIENCY, etc.)
	var flags: Array[String] = []
	# E: lines - starting equipment [{tval, sval, min_qty, max_qty}]
	var starting_equipment: Array = []
	var description: String = ""

class HouseData:
	var index: int = 0
	var name: String = ""
	var str_mod: int = 0
	var dex_mod: int = 0
	var con_mod: int = 0
	var gra_mod: int = 0
	# A: line - alternate name
	var alternate_name: String = ""
	# B: line - short/abbreviated name
	var short_name: String = ""
	# F: line - skill affinities (MEL_AFFINITY, ARC_AFFINITY, etc.)
	var affinities: Array[String] = []
	var description: String = ""

class TerrainData:
	var index: int = 0
	var name: String = ""
	var display_char: String = ""
	var color: String = ""
	var mimic_char: String = ""
	var flags: Array[String] = []

class VaultData:
	var index: int = 0
	var name: String = ""
	var vault_type: int = 0
	var rating: int = 0
	var height: int = 0
	var width: int = 0
	var map_lines: Array[String] = []
