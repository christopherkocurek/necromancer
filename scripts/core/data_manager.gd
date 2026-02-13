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
var traits: Dictionary = {}    # name -> TraitData
var terrain: Dictionary = {}   # char -> TerrainData
var vaults: Array[VaultData] = []
var egos: Dictionary = {}  # index -> EgoData

# Data file paths
const DATA_PATH := "res://data/"

func _ready() -> void:
	load_all_data()

func load_all_data() -> void:
	print("DataManager: Loading game data...")
	load_terrain()
	load_monsters()
	load_items()
	load_special()
	load_artifacts()
	load_abilities()
	load_races()
	load_houses()
	load_traits()
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
					current_monster.name = n_parts[1].replace("& ", "").replace("~", "").strip_edges()
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
				# S: lines can contain a mix of:
				#   SPELL_PCT_N  -> spell_frequency = N
				#   POW_N        -> spell_power = N
				#   Other tokens -> spell type names (CROSSBOW, SHRIEK, DARKNESS, etc.)
				# Multiple S: lines accumulate (first has freq/power, second has types)
				if current_monster:
					var s_tokens := value.split("|")
					for token_raw in s_tokens:
						var token: String = token_raw.strip_edges()
						if token.is_empty():
							continue
						if token.begins_with("SPELL_PCT_"):
							# Extract frequency: SPELL_PCT_40 -> 40
							var pct_str: String = token.substr(10)
							current_monster.spell_frequency = int(pct_str)
						elif token.begins_with("POW_"):
							# Extract power: POW_6 -> 6
							var pow_str: String = token.substr(4)
							current_monster.spell_power = int(pow_str)
						else:
							# Spell type name (CROSSBOW, SHRIEK, DARKNESS, etc.)
							current_monster.spell_types.append(token)
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
					current_item.name = n_parts[1].replace("& ", "").replace("~", "").strip_edges()
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
			"B":
				# B:skill_id/ability_id - grants an ability when equipped
				if current_item:
					var b_parts := value.split(":")
					for b_entry in b_parts:
						var ab_parts := b_entry.strip_edges().split("/")
						if ab_parts.size() >= 2:
							current_item.granted_abilities.append(
								[int(ab_parts[0]), int(ab_parts[1])]
							)
			"D":
				if current_item:
					if current_item.description.is_empty():
						current_item.description = value
					else:
						current_item.description += " " + value

	if current_item and current_item.name != "":
		items[current_item.name] = current_item

# ============================================================================
# SPECIAL (EGO) PARSING
# ============================================================================

const CURSED_FLAGS: Array[String] = [
	"VUL_POIS", "VUL_FIRE", "VUL_COLD", "FEAR", "AGGRAVATE", "DARKNESS",
	"HUNGER", "LIGHT_CURSE", "DANGER", "HAUNTED", "NEG_STR", "NEG_DEX",
	"NEG_CON", "NEG_GRA", "CUMBERSOME"
]

func load_special() -> void:
	var file := FileAccess.open(DATA_PATH + "special.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load special.txt")
		return

	var current_ego: EgoData = null

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
				if current_ego and current_ego.name != "":
					# Derive is_cursed before storing
					current_ego.is_cursed = _has_cursed_flag(current_ego.flags)
					egos[current_ego.index] = current_ego
				current_ego = EgoData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_ego.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_ego.name = n_parts[1]
			"W":
				if current_ego:
					var w_parts := value.split(":")
					if w_parts.size() >= 1:
						current_ego.depth = int(w_parts[0])
					if w_parts.size() >= 2:
						current_ego.rarity = int(w_parts[1])
					if w_parts.size() >= 3:
						current_ego.max_depth = int(w_parts[2])
					if w_parts.size() >= 4:
						current_ego.cost = int(w_parts[3])
			"C":
				if current_ego:
					var c_parts := value.split(":")
					if c_parts.size() >= 1:
						current_ego.max_attack = int(c_parts[0])
					if c_parts.size() >= 2:
						current_ego.plus_damage_dice = int(c_parts[1])
					if c_parts.size() >= 3:
						current_ego.plus_damage_sides = int(c_parts[2])
					if c_parts.size() >= 4:
						current_ego.max_evasion = int(c_parts[3])
					if c_parts.size() >= 5:
						current_ego.plus_prot_dice = int(c_parts[4])
					if c_parts.size() >= 6:
						current_ego.plus_prot_sides = int(c_parts[5])
					if c_parts.size() >= 7:
						current_ego.pval = int(c_parts[6])
			"T":
				if current_ego:
					var t_parts := value.split(":")
					if t_parts.size() >= 3:
						current_ego.tval_filters.append({
							"tval": int(t_parts[0]),
							"min_sval": int(t_parts[1]),
							"max_sval": int(t_parts[2])
						})
			"F":
				if current_ego:
					var flags := value.split("|")
					for flag in flags:
						var f := flag.strip_edges()
						if f != "":
							current_ego.flags.append(f)
			"B":
				if current_ego:
					var b_parts := value.split(":")
					for b_entry in b_parts:
						var ab_parts := b_entry.strip_edges().split("/")
						if ab_parts.size() >= 2:
							current_ego.granted_abilities.append(
								[int(ab_parts[0]), int(ab_parts[1])]
							)

	# Don't forget the last entry
	if current_ego and current_ego.name != "":
		current_ego.is_cursed = _has_cursed_flag(current_ego.flags)
		egos[current_ego.index] = current_ego

	print("DataManager: Loaded %d ego types" % egos.size())

func _has_cursed_flag(flags: Array[String]) -> bool:
	for flag in flags:
		if flag in CURSED_FLAGS:
			return true
	return false

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
					current_artifact.name = n_parts[1].replace("& ", "").replace("~", "").strip_edges()
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
# TRAIT PARSING
# ============================================================================

func load_traits() -> void:
	var file := FileAccess.open(DATA_PATH + "trait.txt", FileAccess.READ)
	if not file:
		push_warning("No trait.txt found - traits disabled")
		return

	var current_trait: TraitData = null

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
				if current_trait and current_trait.name != "":
					traits[current_trait.name] = current_trait
				current_trait = TraitData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 1:
					current_trait.index = int(n_parts[0])
				if n_parts.size() >= 2:
					current_trait.name = n_parts[1]
			"E":
				if current_trait:
					current_trait.effect_id = value.strip_edges()
			"D":
				if current_trait:
					if current_trait.description.is_empty():
						current_trait.description = value
					else:
						current_trait.description += " " + value

	if current_trait and current_trait.name != "":
		traits[current_trait.name] = current_trait

func get_all_traits() -> Array:
	return traits.values()

func get_trait_by_name(trait_name: String) -> TraitData:
	return traits.get(trait_name, null)

func get_trait_by_index(index: int) -> TraitData:
	for t in traits.values():
		if t.index == index:
			return t
	return null

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
						current_vault.compute_dimensions()
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
							current_vault.rarity = int(x_parts[2])
				"F":
					if current_vault:
						var flag_list := value.split("|")
						for flag in flag_list:
							var f := flag.strip_edges()
							if f != "":
								current_vault.flags.append(f)
				"D":
					reading_map = true
					if current_vault:
						current_vault.map_lines.append(value)
		elif reading_map and current_vault:
			current_vault.map_lines.append(stripped)

	if current_vault and current_vault.name != "":
		current_vault.compute_dimensions()
		vaults.append(current_vault)

# ============================================================================
# DATA ACCESS HELPERS
# ============================================================================

## Deep-copy an ItemData so mutations (identification, etc.) don't affect templates
func duplicate_item_data(source: ItemData) -> ItemData:
	var copy := ItemData.new()
	copy.index = source.index
	copy.name = source.name
	copy.display_char = source.display_char
	copy.color = source.color
	copy.tval = source.tval
	copy.sval = source.sval
	copy.pval = source.pval
	copy.depth = source.depth
	copy.rarity = source.rarity
	copy.weight = source.weight
	copy.cost = source.cost
	copy.allocation = source.allocation
	copy.attack_bonus = source.attack_bonus
	copy.damage_dice = source.damage_dice
	copy.evasion_bonus = source.evasion_bonus
	copy.protection_dice = source.protection_dice
	copy.flags = source.flags.duplicate()
	copy.granted_abilities = source.granted_abilities.duplicate(true)
	copy.description = source.description
	copy.identified = source.identified
	copy.fuel = source.fuel
	copy.stack_count = source.stack_count
	copy.ego_name = source.ego_name
	copy.ego_index = source.ego_index
	return copy

## Get all valid egos for an item type at a given depth
func get_egos_for_item(tval: int, sval: int, depth: int, exclude_cursed: bool = false) -> Array:
	var result: Array = []
	for ego in egos.values():
		if not ego.matches_item(tval, sval):
			continue
		if not ego.valid_for_depth(depth):
			continue
		if exclude_cursed and ego.is_cursed:
			continue
		result.append(ego)
	return result

## Select a weighted random ego for an item (weight = 1/rarity)
func select_ego_for_item(tval: int, sval: int, depth: int, exclude_cursed: bool = false) -> EgoData:
	var candidates: Array = get_egos_for_item(tval, sval, depth, exclude_cursed)
	if candidates.is_empty():
		return null

	var total_weight: float = 0.0
	var weights: Array[float] = []
	for ego in candidates:
		var w: float = 1.0 / maxf(float(ego.rarity), 1.0)
		weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		return candidates.pick_random()

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]

	return candidates[-1]

## Apply an ego enchantment to an item — modifies name, stats, flags, abilities
func apply_ego_to_item(item: ItemData, ego: EgoData) -> void:
	# Set ego tracking fields
	item.ego_name = ego.name
	item.ego_index = ego.index

	# Apply name: parenthetical egos like "(Poisoned)" or "(Balanced)" are prefixed
	# Named egos like "of Gondolin" are suffixed
	if ego.name.begins_with("("):
		item.name = "%s %s" % [ego.name, item.name]
	else:
		item.name = "%s %s" % [item.name, ego.name]

	# Apply C: line bonuses
	item.attack_bonus += ego.max_attack
	if ego.plus_damage_dice > 0 or ego.plus_damage_sides > 0:
		if item.damage_dice != "":
			var parts: PackedStringArray = item.damage_dice.split("d")
			if parts.size() >= 2:
				var dice: int = int(parts[0]) + ego.plus_damage_dice
				var sides: int = int(parts[1]) + ego.plus_damage_sides
				item.damage_dice = "%dd%d" % [dice, sides]
	item.evasion_bonus += ego.max_evasion
	if ego.plus_prot_dice > 0 or ego.plus_prot_sides > 0:
		if item.protection_dice != "":
			var parts: PackedStringArray = item.protection_dice.split("d")
			if parts.size() >= 2:
				var dice: int = int(parts[0]) + ego.plus_prot_dice
				var sides: int = int(parts[1]) + ego.plus_prot_sides
				item.protection_dice = "%dd%d" % [dice, sides]
		elif ego.plus_prot_dice > 0:
			item.protection_dice = "%dd%d" % [ego.plus_prot_dice, maxi(ego.plus_prot_sides, 1)]
	if ego.pval != 0:
		item.pval += ego.pval

	# Merge flags
	for flag in ego.flags:
		if flag not in item.flags:
			item.flags.append(flag)

	# Merge granted abilities
	for ability_ref in ego.granted_abilities:
		item.granted_abilities.append(ability_ref)

func get_monster(name: String) -> MonsterData:
	return monsters.get(name)

func get_item(name: String) -> ItemData:
	return items.get(name)

func get_item_by_index(idx: int) -> ItemData:
	for item in items.values():
		if item.index == idx:
			return item
	return null

func get_artifact(name: String) -> ArtifactData:
	return artifacts.get(name)

func get_artifact_by_index(idx: int) -> ArtifactData:
	for a in artifacts.values():
		if a.index == idx:
			return a
	return null

## Get a random artifact (for smithing reclaim)
func get_random_artifact() -> ArtifactData:
	var all_artifacts: Array = artifacts.values()
	if all_artifacts.is_empty():
		return null
	return all_artifacts.pick_random()

## Deep-copy an ArtifactData into an ItemData (for smithing — artifacts become inventory items)
func duplicate_artifact_as_item(source: ArtifactData) -> ItemData:
	var copy := ItemData.new()
	copy.index = source.index
	copy.name = source.name
	copy.tval = source.tval
	copy.sval = source.sval
	copy.pval = source.pval
	copy.depth = source.depth
	copy.rarity = source.rarity
	copy.weight = source.weight
	copy.attack_bonus = source.attack_bonus
	copy.damage_dice = source.damage_dice
	copy.evasion_bonus = source.evasion_bonus
	copy.protection_dice = source.protection_dice
	copy.flags = source.flags.duplicate()
	copy.description = source.description
	copy.identified = true  # Reclaimed artifacts are always identified
	return copy

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

func get_random_monster_for_depth(depth: int, exclude_uniques: bool = false) -> MonsterData:
	var valid_monsters: Array[MonsterData] = []
	for m in monsters.values():
		if m.depth <= depth and m.depth >= depth - 3:
			if exclude_uniques and m.has_flag("UNIQUE"):
				continue
			valid_monsters.append(m)
	if valid_monsters.is_empty():
		# Fallback: any monster at or below depth
		for m in monsters.values():
			if m.depth <= depth:
				if exclude_uniques and m.has_flag("UNIQUE"):
					continue
				valid_monsters.append(m)
	if valid_monsters.is_empty():
		return null
	return _weighted_pick_monster(valid_monsters)

func get_random_item_for_depth(depth: int) -> ItemData:
	var valid_items: Array[ItemData] = []
	for i in items.values():
		if i.depth <= depth and i.depth >= depth - 3:
			if "INSTA_ART" not in i.flags:
				valid_items.append(i)
	if valid_items.is_empty():
		for i in items.values():
			if i.depth <= depth:
				if "INSTA_ART" not in i.flags:
					valid_items.append(i)
	if valid_items.is_empty():
		return null
	return valid_items.pick_random()

## Get a random item filtered by tval category for smithing Reforge output
func get_random_item_by_tvals(tvals: Array[int], depth: int) -> ItemData:
	var valid_items: Array[ItemData] = []
	for i in items.values():
		if i.tval not in tvals:
			continue
		if "INSTA_ART" in i.flags or "NO_SMITHING" in i.flags or "DAMAGED" in i.flags:
			continue
		if i.depth <= depth + 2 and i.depth >= maxi(1, depth - 3):
			valid_items.append(i)
	if valid_items.is_empty():
		# Fallback: any item of that type at or below depth
		for i in items.values():
			if i.tval not in tvals:
				continue
			if "INSTA_ART" in i.flags or "NO_SMITHING" in i.flags or "DAMAGED" in i.flags:
				continue
			if i.depth <= depth + 2:
				valid_items.append(i)
	if valid_items.is_empty():
		return null
	return duplicate_item_data(valid_items.pick_random())

## Get a random artifact filtered by tval category for smithing Reclaim output
func get_random_artifact_by_tvals(tvals: Array[int]) -> ArtifactData:
	var valid: Array[ArtifactData] = []
	for a in artifacts.values():
		if a.tval in tvals:
			valid.append(a)
	if valid.is_empty():
		return null
	return valid.pick_random()

## Get multiple random artifacts by tval category (for Reclaim Mastery — pick from 3)
func get_random_artifacts_by_tvals(tvals: Array[int], count: int) -> Array[ArtifactData]:
	var valid: Array[ArtifactData] = []
	for a in artifacts.values():
		if a.tval in tvals:
			valid.append(a)
	valid.shuffle()
	var result: Array[ArtifactData] = []
	for i in range(mini(count, valid.size())):
		result.append(valid[i])
	return result

## Get the highest-depth artifact of a given type (for Masterwork — best tier)
func get_best_artifact_by_tvals(tvals: Array[int]) -> ArtifactData:
	var best: ArtifactData = null
	for a in artifacts.values():
		if a.tval in tvals:
			if best == null or a.depth > best.depth:
				best = a
	return best

## Get a random food item (tval 80) appropriate for depth (any food or herb)
func get_random_food_for_depth(depth: int) -> ItemData:
	var food_items: Array[ItemData] = []
	for i in items.values():
		if i.tval == 80 and i.depth <= depth:
			food_items.append(i)
	if food_items.is_empty():
		return null
	return food_items.pick_random()

## Get a random actual food item (not herbs/mushrooms) for depth
## Actual food: sval >= 35 (Travel Bread, Dried Meat, Lembas, Cram) + Waymeal (sval 1)
func get_random_actual_food(depth: int) -> ItemData:
	var food_items: Array[ItemData] = []
	for i in items.values():
		if i.tval == 80 and i.depth <= depth:
			if i.sval >= 35 or i.sval == 1:  # Actual food or Waymeal
				food_items.append(i)
	if food_items.is_empty():
		return null
	return food_items.pick_random()

## Get a random herb/mushroom appropriate for depth
## Herbs: tval 80, sval 0 or sval 2-23 (excludes actual food sval>=35 and Waymeal sval 1)
func get_random_herb_for_depth(depth: int) -> ItemData:
	var herb_items: Array[ItemData] = []
	for i in items.values():
		if i.tval == 80 and i.depth <= depth:
			if i.sval != 1 and i.sval < 35:  # Herbs/mushrooms only
				herb_items.append(i)
	if herb_items.is_empty():
		return null
	return herb_items.pick_random()

## Look up an item by tval and sval (used for starting equipment grants)
func get_item_by_tval_sval(tval: int, sval: int) -> ItemData:
	for i in items.values():
		if i.tval == tval and i.sval == sval:
			return i
	return null

func _validate_data() -> void:
	print("=== DataManager Validation ===")
	print("Loaded %d monsters, %d items, %d artifacts, %d abilities" % [
		monsters.size(), items.size(), artifacts.size(), abilities.size()
	])
	print("Loaded %d races, %d houses, %d traits, %d vaults" % [
		races.size(), houses.size(), traits.size(), vaults.size()
	])

	# Spot-check critical content
	var warnings: Array[String] = []

	# Check for a valid boss plus key monster families.
	var has_end_boss: bool = false
	for monster_name in monsters.keys():
		var n: String = String(monster_name).to_lower()
		if "necromancer" in n or n.begins_with("sauron"):
			has_end_boss = true
			break
	if not has_end_boss:
		warnings.append("Missing end boss entry (expected 'The Necromancer' or 'Sauron').")

	var family_flags: Dictionary = {
		"ORC": false,
		"TROLL": false,
		"SPIDER": false,
	}
	for mon in monsters.values():
		if mon == null:
			continue
		if mon.has_flag("ORC"):
			family_flags["ORC"] = true
		if mon.has_flag("TROLL"):
			family_flags["TROLL"] = true
		if mon.has_flag("SPIDER"):
			family_flags["SPIDER"] = true
	for family in family_flags:
		if not family_flags[family]:
			warnings.append("Missing key monster family: " + family)

	# Check for races
	var expected_races := ["Elf", "Man", "Dwarf", "Hobbit"]
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
		# vault_type is a category (normal/lesser/greater/transition/throne), rating is depth gate.
		# Only include regular vault types here; greater/throne are handled elsewhere.
		if vault.rating <= depth and vault.vault_type < 8:
			valid_vaults.append(vault)
	return valid_vaults

func get_random_vault_for_depth(depth: int) -> VaultData:
	var valid := get_vaults_for_depth(depth)
	if valid.is_empty():
		return null
	return valid.pick_random()

## Get vaults matching a specific type that are valid for the given depth
func get_vaults_by_type_for_depth(type: int, depth: int) -> Array[VaultData]:
	var result: Array[VaultData] = []
	for vault in vaults:
		if vault.vault_type == type and vault.rating <= depth:
			result.append(vault)
	return result

## Get a weighted random vault of a specific type for depth (weight = 1/rarity)
func get_weighted_vault(type: int, depth: int) -> VaultData:
	var candidates: Array[VaultData] = get_vaults_by_type_for_depth(type, depth)
	if candidates.is_empty():
		return null

	var total_weight: float = 0.0
	var weights: Array[float] = []
	for v in candidates:
		var w: float = 1.0 / maxf(float(v.rarity), 1.0)
		weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		return candidates.pick_random()

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]
	return candidates[candidates.size() - 1]

## Get a themed monster for the current depth using layer-specific tables
## Falls back to get_random_monster_for_depth() if LayerConfig tables unavailable
func get_themed_monster_for_depth(depth: int) -> MonsterData:
	var layer_name: String = LayerConfig.get_layer_name(depth)
	# Check if LayerConfig has LAYER_MONSTER_TABLES (added by Stream E)
	if "LAYER_MONSTER_TABLES" in LayerConfig and layer_name in LayerConfig.LAYER_MONSTER_TABLES:
		var table: Dictionary = LayerConfig.LAYER_MONSTER_TABLES[layer_name]
		# Weighted selection from table entries: {category: weight}
		var total_weight: float = 0.0
		var entries: Array = []
		for category: String in table:
			var weight: float = float(table[category])
			entries.append({"category": category, "weight": weight})
			total_weight += weight

		if total_weight > 0.0:
			var roll: float = randf() * total_weight
			var cumul: float = 0.0
			for entry: Dictionary in entries:
				cumul += entry.weight
				if roll <= cumul:
					var picked: MonsterData = _pick_monster_by_category(entry.category, depth)
					if picked:
						return picked
					break

	# Fallback
	return get_random_monster_for_depth(depth)

## Get a themed item for the current depth using layer-specific tval tables
func get_themed_item_for_depth(depth: int) -> ItemData:
	var layer_name: String = LayerConfig.get_layer_name(depth)
	if "LAYER_ITEM_TVALS" in LayerConfig and layer_name in LayerConfig.LAYER_ITEM_TVALS:
		var table: Dictionary = LayerConfig.LAYER_ITEM_TVALS[layer_name]
		var total_weight: float = 0.0
		var entries: Array = []
		for tval_str: String in table:
			var weight: float = float(table[tval_str])
			entries.append({"tval": int(tval_str), "weight": weight})
			total_weight += weight

		if total_weight > 0.0:
			var roll: float = randf() * total_weight
			var cumul: float = 0.0
			for entry: Dictionary in entries:
				cumul += entry.weight
				if roll <= cumul:
					var picked: ItemData = _pick_item_by_tval(entry.tval, depth)
					if picked:
						return picked
					break

	return get_random_item_for_depth(depth)

func _pick_item_by_tval(tval: int, depth: int) -> ItemData:
	var candidates: Array[ItemData] = []
	for i in items.values():
		if i.tval == tval and i.depth <= depth and "INSTA_ART" not in i.flags:
			candidates.append(i)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func _pick_monster_by_category(category: String, depth: int) -> MonsterData:
	match category:
		"spider": return _pick_spider_for_depth(depth)
		"orc": return _pick_orc_for_depth(depth)
		"troll": return _pick_troll_for_depth(depth)
		"undead": return _pick_undead_for_depth(depth)
		"shadow": return _pick_shadow_for_depth(depth)
		"vampire": return _pick_vampire_for_depth(depth)
		"warg": return _pick_warg_for_depth(depth)
		"human_enemy": return _pick_human_enemy_for_depth(depth)
		"wight": return _pick_wight_for_depth(depth)
		"orc_leader": return _pick_orc_leader_for_depth(depth)
		"flier": return _pick_flier_for_depth(depth)
		"vermin": return _pick_vermin_for_depth(depth)
		"elite": return _pick_elite_for_depth(depth)
	return get_random_monster_for_depth(depth)

func _pick_spider_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "S" or m.has_flag("SPIDER") or "spider" in m.name.to_lower() or "Spider" in m.name)

func _pick_orc_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "o" or "Orc" in m.name or "orc" in m.name.to_lower())

func _pick_troll_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "T" or "Troll" in m.name or "troll" in m.name.to_lower())

func _pick_undead_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.has_flag("UNDEAD") or "Skeleton" in m.name or "Zombie" in m.name or "Wight" in m.name or "Ghost" in m.name or "Wraith" in m.name)

func _pick_shadow_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "G" or "Shadow" in m.name or "Wraith" in m.name or "Phantom" in m.name)

func _pick_vampire_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "V" or "Vampire" in m.name or "vampire" in m.name.to_lower())

func _pick_warg_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "w" or "Warg" in m.name or "Wolf" in m.name)

func _pick_human_enemy_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return "Easterling" in m.name or "Numenorean" in m.name or "Sorcerer" in m.name or "Necromancer" in m.name or m.display_char == "p")

func _pick_wight_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return "Wight" in m.name or "wight" in m.name.to_lower())

func _pick_orc_leader_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return "captain" in m.name.to_lower() or "chief" in m.name.to_lower() or m.display_char == "O")

func _pick_flier_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "B" or "Bat" in m.name or "Crebain" in m.name or m.has_flag("FLY"))

func _pick_vermin_for_depth(depth: int) -> MonsterData:
	return _pick_monster_matching(depth, func(m: MonsterData) -> bool:
		return m.display_char == "r" or m.display_char == "I" or "Rat" in m.name or "Centipede" in m.name)

func _pick_elite_for_depth(depth: int) -> MonsterData:
	# Elite: any monster at depth+2 for extra challenge
	return get_random_monster_for_depth(mini(depth + 2, 20))

## Generic helper: pick a random monster matching a predicate at depth (rarity-weighted)
func _pick_monster_matching(depth: int, predicate: Callable, exclude_uniques: bool = false) -> MonsterData:
	var candidates: Array[MonsterData] = []
	for m in monsters.values():
		if m.depth <= depth and m.depth >= maxi(1, depth - 4):
			if exclude_uniques and m.has_flag("UNIQUE"):
				continue
			if predicate.call(m):
				candidates.append(m)
	if candidates.is_empty():
		# Broaden search
		for m in monsters.values():
			if m.depth <= depth:
				if exclude_uniques and m.has_flag("UNIQUE"):
					continue
				if predicate.call(m):
					candidates.append(m)
	if candidates.is_empty():
		return get_random_monster_for_depth(depth, exclude_uniques)
	return _weighted_pick_monster(candidates)

## Rarity-weighted random pick from a monster candidate list.
## Lower rarity = more common. Weight = 1.0 / max(rarity, 1).
func _weighted_pick_monster(candidates: Array[MonsterData]) -> MonsterData:
	if candidates.is_empty():
		return null
	if candidates.size() == 1:
		return candidates[0]
	var weights: Array[float] = []
	var total_weight: float = 0.0
	for m in candidates:
		var w: float = 1.0 / maxf(float(maxi(m.rarity, 1)), 1.0)
		weights.append(w)
		total_weight += w
	if total_weight <= 0.0:
		return candidates.pick_random()
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]
	return candidates[candidates.size() - 1]

# ============================================================================
# OUT-OF-DEPTH SYSTEM
# ============================================================================

## Roll an effective depth for monster selection with OOD variance.
## 12% chance of +1d3 depth, capped at +5 and max 20.
## Called by spawn loop — vaults/escorts use base depth directly.
func get_effective_monster_depth(base_depth: int) -> int:
	if randf() < 0.12:
		var bonus: int = randi_range(1, 3)
		return mini(base_depth + mini(bonus, 5), 20)
	return base_depth

# ============================================================================
# UNIQUE POPULATION CAPS
# ============================================================================

var _spawned_uniques: Dictionary = {}

func reset_spawned_uniques() -> void:
	_spawned_uniques.clear()

func mark_unique_spawned(monster_name: String) -> void:
	_spawned_uniques[monster_name] = true

func is_unique_already_spawned(monster_name: String) -> bool:
	return _spawned_uniques.has(monster_name)

func get_monster_by_char(ch: String, depth: int) -> MonsterData:
	# Full vault symbol alphabet for monster spawning
	match ch:
		# Lowercase = common creature types
		"a": return _pick_vermin_for_depth(depth)       # ant/vermin
		"b": return _pick_flier_for_depth(depth)        # bat
		"c": return _pick_vermin_for_depth(depth)       # centipede
		"d": return _pick_warg_for_depth(depth)         # dog/warg pup
		"f": return _pick_spider_for_depth(depth)       # feline/spider variant
		"g": return _pick_orc_for_depth(depth)          # goblin
		"h": return _pick_human_enemy_for_depth(depth)  # human
		"i": return _pick_vermin_for_depth(depth)       # insect
		"k": return _pick_orc_for_depth(depth)          # kobold
		"m": return _pick_undead_for_depth(depth)       # mummy
		"o": return _pick_orc_for_depth(depth)          # orc
		"p": return _pick_human_enemy_for_depth(depth)  # person
		"r": return _pick_vermin_for_depth(depth)       # rodent
		"s": return _pick_spider_for_depth(depth)       # spider
		"t": return _pick_troll_for_depth(depth)        # troll (small)
		"v": return _pick_vampire_for_depth(depth)      # vampire bat
		"w": return _pick_warg_for_depth(depth)         # warg/wolf
		"z": return _pick_undead_for_depth(depth)       # zombie

		# Uppercase = elite/boss/named types
		"B": return _pick_flier_for_depth(depth)        # Bat Lord
		"C": return _pick_spider_for_depth(depth)       # Crebain
		"D": return _pick_shadow_for_depth(depth)       # Dragon/Demon
		"G": return _pick_shadow_for_depth(depth)       # Ghost
		"H": return _pick_human_enemy_for_depth(depth)  # Human leader
		"L": return _pick_undead_for_depth(depth)       # Lich
		"M": return _pick_undead_for_depth(depth)       # Mummy lord
		"N": return _pick_human_enemy_for_depth(depth)  # Necromancer
		"O": return _pick_orc_leader_for_depth(depth)   # Orc captain
		"P": return _pick_human_enemy_for_depth(depth)  # Person (strong)
		"S": return _pick_spider_for_depth(depth)       # Spider (big)
		"T": return _pick_troll_for_depth(depth)        # Troll (big)
		"V": return _pick_vampire_for_depth(depth)      # Vampire
		"W": return _pick_warg_for_depth(depth)         # Werewolf/Warg alpha
		"Z": return _pick_undead_for_depth(depth)       # Zombie lord

	# Fallback for unrecognized characters
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

	func _init() -> void:
		spell_types = []
		attacks = []
		flags = []

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
	var granted_abilities: Array = []  # B: lines parsed as [[skill_id, ability_id], ...]
	var description: String = ""
	# Identification (Phase D)
	var identified: bool = false     # Whether this specific item is identified
	var fuel: int = -1               # Fuel for light sources (-1 = no fuel system)
	var stack_count: int = 1         # Stacking: how many in this stack (1 = single item)
	var ego_name: String = ""
	var ego_index: int = -1

	func _init() -> void:
		flags = []
		granted_abilities = []

class EgoData:
	var index: int = 0
	var name: String = ""
	var depth: int = 0
	var rarity: int = 1
	var max_depth: int = 0
	var cost: int = 0
	var max_attack: int = 0
	var plus_damage_dice: int = 0
	var plus_damage_sides: int = 0
	var max_evasion: int = 0
	var plus_prot_dice: int = 0
	var plus_prot_sides: int = 0
	var pval: int = 0
	var tval_filters: Array = []   # Array of {tval: int, min_sval: int, max_sval: int}
	var flags: Array[String] = []
	var granted_abilities: Array = []  # Array of [skill_id, ability_id]
	var is_cursed: bool = false  # Derived: true if any VUL_/FEAR/AGGRAVATE/DARKNESS/HUNGER/LIGHT_CURSE/DANGER/HAUNTED/NEG_STR/NEG_DEX/NEG_CON/NEG_GRA/CUMBERSOME

	func _init() -> void:
		tval_filters = []
		flags = []
		granted_abilities = []

	func matches_item(tval: int, sval: int) -> bool:
		if tval_filters.is_empty():
			return true
		for filter in tval_filters:
			if filter.tval == tval:
				if sval >= filter.min_sval and sval <= filter.max_sval:
					return true
		return false

	func valid_for_depth(floor_depth: int) -> bool:
		if floor_depth < depth:
			return false
		if max_depth > 0 and floor_depth > max_depth:
			return false
		return true

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

	func _init() -> void:
		flags = []

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

	func _init() -> void:
		prereqs = []
		item_grants = []

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

	func _init() -> void:
		compatible_houses = []
		flags = []
		starting_equipment = []

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

	func _init() -> void:
		affinities = []

class TraitData:
	var index: int = 0
	var name: String = ""
	var effect_id: String = ""  # Code-facing identifier (e.g. "defiance")
	var description: String = ""

class TerrainData:
	var index: int = 0
	var name: String = ""
	var display_char: String = ""
	var color: String = ""
	var mimic_char: String = ""
	var flags: Array[String] = []

	func _init() -> void:
		flags = []

class VaultData:
	var index: int = 0
	var name: String = ""
	var vault_type: int = 0
	var rating: int = 0
	var height: int = 0
	var width: int = 0
	var rarity: int = 1          # From X: field[2]
	var flags: Array[String] = [] # From F: lines
	var map_lines: Array[String] = []

	func _init() -> void:
		flags = []
		map_lines = []

	func has_flag(flag_name: String) -> bool:
		return flag_name in flags

	func compute_dimensions() -> void:
		if map_lines.is_empty():
			return
		height = map_lines.size()
		width = 0
		for line in map_lines:
			width = maxi(width, line.length())
