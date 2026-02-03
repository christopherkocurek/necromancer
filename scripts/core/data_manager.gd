extends Node
## Parses and manages game data from the original Necromancer data files.
## Converts Angband-format text files into usable game resources.

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
	call_deferred("load_all_data")

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
	print("DataManager: Loaded %d monsters, %d items, %d artifacts, %d abilities" % [
		monsters.size(), items.size(), artifacts.size(), abilities.size()
	])

# ============================================================================
# MONSTER PARSING
# ============================================================================

func load_monsters() -> void:
	var file := FileAccess.open(DATA_PATH + "monster.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load monster.txt")
		return

	var current_monster: MonsterData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				# N:index:name
				if current_monster:
					monsters[current_monster.name] = current_monster
				current_monster = MonsterData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_monster.index = int(n_parts[0])
					current_monster.name = n_parts[1]
			"G":
				# G:char:color
				if current_monster:
					var g_parts := value.split(":")
					if g_parts.size() >= 2:
						current_monster.display_char = g_parts[0]
						current_monster.color = g_parts[1]
			"I":
				# I:speed:health_dice:aaf:ac:alertness
				if current_monster:
					var i_parts := value.split(":")
					if i_parts.size() >= 5:
						current_monster.speed = int(i_parts[0])
						current_monster.health_dice = i_parts[1]
						current_monster.aaf = int(i_parts[2])
						current_monster.armor_class = int(i_parts[3])
						current_monster.alertness = int(i_parts[4])
			"W":
				# W:depth:rarity:exp
				if current_monster:
					var w_parts := value.split(":")
					if w_parts.size() >= 3:
						current_monster.depth = int(w_parts[0])
						current_monster.rarity = int(w_parts[1])
						current_monster.experience = int(w_parts[2])
			"B":
				# B:method:effect:damage_dice
				if current_monster:
					var b_parts := value.split(":")
					if b_parts.size() >= 3:
						var attack := AttackData.new()
						attack.method = b_parts[0]
						attack.effect = b_parts[1]
						attack.damage_dice = b_parts[2] if b_parts.size() > 2 else ""
						current_monster.attacks.append(attack)
			"F":
				# F:FLAG1 | FLAG2 | FLAG3
				if current_monster:
					var flags := value.split("|")
					for flag in flags:
						current_monster.flags.append(flag.strip_edges())
			"D":
				# D:description text
				if current_monster:
					if current_monster.description.is_empty():
						current_monster.description = value
					else:
						current_monster.description += " " + value

	if current_monster:
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
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_item:
					items[current_item.name] = current_item
				current_item = ItemData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_item.index = int(n_parts[0])
					current_item.name = n_parts[1]
			"G":
				if current_item:
					var g_parts := value.split(":")
					if g_parts.size() >= 2:
						current_item.display_char = g_parts[0]
						current_item.color = g_parts[1]
			"I":
				if current_item:
					var i_parts := value.split(":")
					if i_parts.size() >= 3:
						current_item.tval = int(i_parts[0])
						current_item.sval = int(i_parts[1])
						current_item.pval = int(i_parts[2]) if i_parts.size() > 2 else 0
			"W":
				if current_item:
					var w_parts := value.split(":")
					if w_parts.size() >= 4:
						current_item.depth = int(w_parts[0])
						current_item.rarity = int(w_parts[1])
						current_item.weight = int(w_parts[2])
						current_item.cost = int(w_parts[3])
			"A":
				if current_item:
					current_item.allocation = value
			"P":
				if current_item:
					var p_parts := value.split(":")
					if p_parts.size() >= 5:
						current_item.ac = int(p_parts[0])
						current_item.damage_dice = p_parts[1]
						current_item.to_hit = int(p_parts[2])
						current_item.to_dam = int(p_parts[3])
						current_item.to_ac = int(p_parts[4])
			"F":
				if current_item:
					var flags := value.split("|")
					for flag in flags:
						current_item.flags.append(flag.strip_edges())
			"D":
				if current_item:
					if current_item.description.is_empty():
						current_item.description = value
					else:
						current_item.description += " " + value

	if current_item:
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
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_artifact:
					artifacts[current_artifact.name] = current_artifact
				current_artifact = ArtifactData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_artifact.index = int(n_parts[0])
					current_artifact.name = n_parts[1]
			"I":
				if current_artifact:
					var i_parts := value.split(":")
					if i_parts.size() >= 3:
						current_artifact.tval = int(i_parts[0])
						current_artifact.sval = int(i_parts[1])
						current_artifact.pval = int(i_parts[2])
			"W":
				if current_artifact:
					var w_parts := value.split(":")
					if w_parts.size() >= 3:
						current_artifact.depth = int(w_parts[0])
						current_artifact.rarity = int(w_parts[1])
						current_artifact.weight = int(w_parts[2])
			"P":
				if current_artifact:
					var p_parts := value.split(":")
					if p_parts.size() >= 5:
						current_artifact.ac = int(p_parts[0])
						current_artifact.damage_dice = p_parts[1]
						current_artifact.to_hit = int(p_parts[2])
						current_artifact.to_dam = int(p_parts[3])
						current_artifact.to_ac = int(p_parts[4])
			"F":
				if current_artifact:
					var flags := value.split("|")
					for flag in flags:
						current_artifact.flags.append(flag.strip_edges())
			"D":
				if current_artifact:
					if current_artifact.description.is_empty():
						current_artifact.description = value
					else:
						current_artifact.description += " " + value

	if current_artifact:
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
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_ability:
					abilities[current_ability.name] = current_ability
				current_ability = AbilityData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_ability.index = int(n_parts[0])
					current_ability.name = n_parts[1]
			"I":
				if current_ability:
					var i_parts := value.split(":")
					if i_parts.size() >= 2:
						current_ability.skill_type = int(i_parts[0])
						current_ability.skill_requirement = int(i_parts[1])
			"P":
				if current_ability:
					current_ability.prerequisites = value
			"D":
				if current_ability:
					if current_ability.description.is_empty():
						current_ability.description = value
					else:
						current_ability.description += " " + value

	if current_ability:
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
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_race:
					races[current_race.name] = current_race
				current_race = RaceData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_race.index = int(n_parts[0])
					current_race.name = n_parts[1]
			"S":
				if current_race:
					var s_parts := value.split(":")
					if s_parts.size() >= 4:
						current_race.str_mod = int(s_parts[0])
						current_race.dex_mod = int(s_parts[1])
						current_race.con_mod = int(s_parts[2])
						current_race.gra_mod = int(s_parts[3])
			"D":
				if current_race:
					if current_race.description.is_empty():
						current_race.description = value
					else:
						current_race.description += " " + value

	if current_race:
		races[current_race.name] = current_race

func load_houses() -> void:
	var file := FileAccess.open(DATA_PATH + "house.txt", FileAccess.READ)
	if not file:
		push_error("Failed to load house.txt")
		return

	var current_house: HouseData = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_house:
					houses[current_house.name] = current_house
				current_house = HouseData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_house.index = int(n_parts[0])
					current_house.name = n_parts[1]
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

	if current_house:
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
		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split(":")
		if parts.size() < 2:
			continue

		var key := parts[0]
		var value := ":".join(parts.slice(1))

		match key:
			"N":
				if current_terrain:
					terrain[current_terrain.display_char] = current_terrain
				current_terrain = TerrainData.new()
				var n_parts := value.split(":")
				if n_parts.size() >= 2:
					current_terrain.index = int(n_parts[0])
					current_terrain.name = n_parts[1]
			"G":
				if current_terrain:
					var g_parts := value.split(":")
					if g_parts.size() >= 2:
						current_terrain.display_char = g_parts[0]
						current_terrain.color = g_parts[1]
			"M":
				if current_terrain:
					current_terrain.mimic_char = value
			"F":
				if current_terrain:
					var flags := value.split("|")
					for flag in flags:
						current_terrain.flags.append(flag.strip_edges())

	if current_terrain:
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

		if stripped.is_empty() or stripped.begins_with("#"):
			continue

		var parts := stripped.split(":")
		if parts.size() >= 2:
			var key := parts[0]
			var value := ":".join(parts.slice(1))

			match key:
				"N":
					if current_vault:
						vaults.append(current_vault)
					current_vault = VaultData.new()
					reading_map = false
					var n_parts := value.split(":")
					if n_parts.size() >= 2:
						current_vault.index = int(n_parts[0])
						current_vault.name = n_parts[1]
				"X":
					if current_vault:
						var x_parts := value.split(":")
						if x_parts.size() >= 4:
							current_vault.vault_type = int(x_parts[0])
							current_vault.rating = int(x_parts[1])
							current_vault.height = int(x_parts[2])
							current_vault.width = int(x_parts[3])
				"D":
					reading_map = true
					if current_vault:
						current_vault.map_lines.append(value)
		elif reading_map and current_vault:
			# Continue reading map lines
			current_vault.map_lines.append(stripped)

	if current_vault:
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

func get_race(name: String) -> RaceData:
	return races.get(name)

func get_house(name: String) -> HouseData:
	return houses.get(name)

func get_terrain_by_char(ch: String) -> TerrainData:
	return terrain.get(ch)

func get_random_monster_for_depth(depth: int) -> MonsterData:
	var valid_monsters: Array[MonsterData] = []
	for m in monsters.values():
		if m.depth <= depth:
			valid_monsters.append(m)
	if valid_monsters.is_empty():
		return null
	return valid_monsters.pick_random()

func get_random_item_for_depth(depth: int) -> ItemData:
	var valid_items: Array[ItemData] = []
	for i in items.values():
		if i.depth <= depth:
			valid_items.append(i)
	if valid_items.is_empty():
		return null
	return valid_items.pick_random()

func roll_dice(dice_string: String) -> int:
	# Parse dice strings like "3d6" or "1d8+2"
	var regex := RegEx.new()
	regex.compile("(\\d+)d(\\d+)([+-]\\d+)?")
	var result := regex.search(dice_string)
	if not result:
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
	var speed: int = 0
	var health_dice: String = ""
	var aaf: int = 0  # area affect flag
	var armor_class: int = 0
	var alertness: int = 0
	var depth: int = 0
	var rarity: int = 1
	var experience: int = 0
	var attacks: Array[AttackData] = []
	var flags: Array[String] = []
	var description: String = ""

	func roll_health() -> int:
		return DataManager.roll_dice(health_dice) if health_dice else 10

class AttackData:
	var method: String = ""
	var effect: String = ""
	var damage_dice: String = ""

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
	var weight: int = 0
	var cost: int = 0
	var allocation: String = ""
	var ac: int = 0
	var damage_dice: String = ""
	var to_hit: int = 0
	var to_dam: int = 0
	var to_ac: int = 0
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
	var ac: int = 0
	var damage_dice: String = ""
	var to_hit: int = 0
	var to_dam: int = 0
	var to_ac: int = 0
	var flags: Array[String] = []
	var description: String = ""

class AbilityData:
	var index: int = 0
	var name: String = ""
	var skill_type: int = 0
	var skill_requirement: int = 0
	var prerequisites: String = ""
	var description: String = ""

class RaceData:
	var index: int = 0
	var name: String = ""
	var str_mod: int = 0
	var dex_mod: int = 0
	var con_mod: int = 0
	var gra_mod: int = 0
	var description: String = ""

class HouseData:
	var index: int = 0
	var name: String = ""
	var str_mod: int = 0
	var dex_mod: int = 0
	var con_mod: int = 0
	var gra_mod: int = 0
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
