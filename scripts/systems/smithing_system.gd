extends RefCounted
class_name SmithingSystem
## Smithing system for creating, reforging, and reclaiming items at forges.
## Ported from Sil-Q smithing mechanics (cmd4.c).
## Three core operations:
##   CREATE    - Use Mithril to forge a new base item (Weaponsmith/Armoursmith/Jeweller)
##   REFORGE   - Combine 2 Broken Glowing items → random enchanted item (SMT_REFORGE)
##   RECLAIM   - Combine 2 Broken Strange items → random artifact (SMT_RECLAIM)

signal forge_used(remaining_uses: int)
signal item_forged(item: Variant, result: String)
signal smithing_failed(item: Variant, reason: String)

# Recipe types (ported from Sil-Q cmd4.c)
enum RecipeType {
	CREATE_WEAPON,   # Mithril → new weapon (requires SMT_WEAPONSMITH)
	CREATE_ARMOR,    # Mithril → new armor (requires SMT_ARMOURSMITH)
	CREATE_JEWELRY,  # Mithril → new ring/amulet/light (requires SMT_JEWELLER)
	REFORGE,         # 2 Broken Glowing items → enchanted item (requires SMT_REFORGE)
	RECLAIM,         # 2 Broken Strange items → artifact (requires SMT_RECLAIM)
}

# Broken item IDs from object.txt (the smithing salvage materials)
const BROKEN_GLOWING_WEAPON_ID: int = 491
const BROKEN_GLOWING_ARMOR_ID: int = 492
const BROKEN_STRANGE_WEAPON_ID: int = 493
const BROKEN_STRANGE_ARMOR_ID: int = 494
const BROKEN_STRANGE_JEWELRY_ID: int = 495
const MITHRIL_ID: int = 410  # Piece of Mithril

# Item IDs for broken items — matched by name substring
const BROKEN_GLOWING_NAMES: Array[String] = ["broken glowing", "shattered elven"]
const BROKEN_STRANGE_NAMES: Array[String] = ["broken strange", "twisted shadow", "broken strange jewelry"]
const MITHRIL_NAMES: Array[String] = ["mithril"]

# Forge terrain IDs from terrain.txt (64-79)
const FORGE_TERRAIN_START: int = 64
const FORGE_TERRAIN_END: int = 79

# Recipe definitions
class Recipe:
	var name: String
	var type: RecipeType
	var required_skill: int  # Minimum smithing skill
	var required_ability: int  # Smithing ability index (-1 = none)
	var material_count: int  # How many materials needed
	var description: String

	func _init(n: String, t: RecipeType, skill: int, ability: int, mat_count: int, desc: String) -> void:
		name = n
		type = t
		required_skill = skill
		required_ability = ability
		material_count = mat_count
		description = desc

# Available recipes
var recipes: Array[Recipe] = []

func _init() -> void:
	_init_recipes()

func _init_recipes() -> void:
	# CREATE recipes — forge new items from Mithril
	recipes.append(Recipe.new(
		"Forge Weapon",
		RecipeType.CREATE_WEAPON,
		2,  # Minimum smithing skill
		Constants.SmithingAbility.SMT_WEAPONSMITH,
		1,  # 1 Mithril
		"Forge a new weapon from Mithril. Choose the weapon type."
	))

	recipes.append(Recipe.new(
		"Forge Armor",
		RecipeType.CREATE_ARMOR,
		2,
		Constants.SmithingAbility.SMT_ARMOURSMITH,
		1,
		"Forge new armor from Mithril. Choose the armor type."
	))

	recipes.append(Recipe.new(
		"Forge Jewelry",
		RecipeType.CREATE_JEWELRY,
		3,
		Constants.SmithingAbility.SMT_JEWELLER,
		1,
		"Forge a ring, amulet, or light source from Mithril."
	))

	# REFORGE — combine 2 Broken Glowing items into enchanted item
	recipes.append(Recipe.new(
		"Reforge",
		RecipeType.REFORGE,
		5,
		Constants.SmithingAbility.SMT_REFORGE,
		2,  # 2 broken glowing items
		"Combine 2 Broken Glowing items into a random enchanted item."
	))

	# RECLAIM — combine 2 Broken Strange items into artifact
	recipes.append(Recipe.new(
		"Reclaim",
		RecipeType.RECLAIM,
		8,
		Constants.SmithingAbility.SMT_RECLAIM,
		2,  # 2 broken strange items
		"Combine 2 Broken Strange items into a random artifact."
	))

# ============================================================================
# FORGE DETECTION
# ============================================================================

func is_forge_tile(tile_id: int) -> bool:
	return tile_id >= Level.Tile.FORGE

func get_forge_uses(_level: Level, _pos: Vector2i) -> int:
	return 5  # Simplified — all forges have 5 uses

func consume_forge_use(level_ref: Level, pos: Vector2i) -> bool:
	forge_used.emit(get_forge_uses(level_ref, pos) - 1)
	return true

# ============================================================================
# SMITHING CALCULATIONS
# ============================================================================

func get_success_chance(player: Player) -> int:
	var smithing_skill: int = player.skills.get("smithing", 0)
	# Create: high success rate (skill * 8, cap 95%)
	# Reforge/Reclaim: moderate (skill * 5, cap 90%)
	return mini(smithing_skill * 8, 95)

func roll_success(player: Player) -> bool:
	var chance: int = get_success_chance(player)
	return randi_range(1, 100) <= chance

# ============================================================================
# MATERIAL QUERIES
# ============================================================================

## Find all Mithril pieces in player inventory
func get_mithril_materials(player: Player) -> Array:
	var materials: Array = []
	for item in player.inventory:
		if _is_mithril(item):
			materials.append(item)
	return materials

## Find all Broken Glowing items in player inventory
func get_broken_glowing_items(player: Player) -> Array:
	var items: Array = []
	for item in player.inventory:
		if _is_broken_glowing(item):
			items.append(item)
	return items

## Find all Broken Strange items in player inventory
func get_broken_strange_items(player: Player) -> Array:
	var items: Array = []
	for item in player.inventory:
		if _is_broken_strange(item):
			items.append(item)
	return items

## Get materials for a specific recipe type
func get_materials_for_recipe(player: Player, recipe_type: RecipeType) -> Array:
	match recipe_type:
		RecipeType.CREATE_WEAPON, RecipeType.CREATE_ARMOR, RecipeType.CREATE_JEWELRY:
			return get_mithril_materials(player)
		RecipeType.REFORGE:
			return get_broken_glowing_items(player)
		RecipeType.RECLAIM:
			return get_broken_strange_items(player)
	return []

func _is_mithril(item: Variant) -> bool:
	if item == null or not "name" in item:
		return false
	var item_name: String = item.name.to_lower()
	for mat_name: String in MITHRIL_NAMES:
		if item_name.contains(mat_name):
			return true
	# Also check by index
	if "index" in item and item.index == MITHRIL_ID:
		return true
	return false

func _is_broken_glowing(item: Variant) -> bool:
	if item == null or not "name" in item:
		return false
	if _has_flag(item, "DAMAGED") and not _is_broken_strange(item):
		return true
	var item_name: String = item.name.to_lower()
	for mat_name: String in BROKEN_GLOWING_NAMES:
		if item_name.contains(mat_name):
			return true
	if "index" in item and item.index in [BROKEN_GLOWING_WEAPON_ID, BROKEN_GLOWING_ARMOR_ID]:
		return true
	return false

func _is_broken_strange(item: Variant) -> bool:
	if item == null or not "name" in item:
		return false
	var item_name: String = item.name.to_lower()
	for mat_name: String in BROKEN_STRANGE_NAMES:
		if item_name.contains(mat_name):
			return true
	if "index" in item and item.index in [BROKEN_STRANGE_WEAPON_ID, BROKEN_STRANGE_ARMOR_ID, BROKEN_STRANGE_JEWELRY_ID]:
		return true
	return false

# ============================================================================
# ITEM TYPE CHECKS
# ============================================================================

func _is_weapon(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	var tval: int = item.tval
	return tval >= 20 and tval <= 23

func _is_armor(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	var tval: int = item.tval
	return tval >= 30 and tval <= 37

func _is_jewelry(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	var tval: int = item.tval
	return tval == 39 or tval == 40 or tval == 45  # Light, Amulet, Ring

func _has_flag(item: Variant, flag: String) -> bool:
	if item == null:
		return false
	if "flags" in item and item.flags is Array:
		return flag in item.flags
	return false

# ============================================================================
# CREATE — Forge new items from Mithril
# ============================================================================

## Get creatable item templates for a given type
func get_creatable_items(recipe_type: RecipeType, depth: int) -> Array:
	var tvals: Array[int] = []
	match recipe_type:
		RecipeType.CREATE_WEAPON:
			tvals = [20, 21, 22, 23]  # Digging, Hafted, Polearm, Sword
		RecipeType.CREATE_ARMOR:
			tvals = [30, 31, 32, 34, 35, 36, 37]  # Boots, Gloves, Helm, Shield, Cloak, Soft, Mail
		RecipeType.CREATE_JEWELRY:
			tvals = [39, 40, 45]  # Light, Amulet, Ring

	var items: Array = []
	for item_data in DataManager.items:
		if not "tval" in item_data:
			continue
		if item_data.tval not in tvals:
			continue
		if _has_flag(item_data, "INSTA_ART") or _has_flag(item_data, "NO_SMITHING"):
			continue
		# Only show items appropriate for current depth
		if "depth" in item_data and item_data.depth > depth + 5:
			continue
		items.append(item_data)

	return items

func create_item(player: Player, template: Variant, mithril: Variant) -> Variant:
	if not roll_success(player):
		_consume_material(player, mithril)
		smithing_failed.emit(null, "Creation failed — Mithril consumed")
		GameManager.log_message("Your smithing attempt fails. The Mithril is ruined.", ThemeColors.MSG_ERROR)
		return null

	_consume_material(player, mithril)

	# Create a copy of the template item
	var new_item: DataManager.ItemData = DataManager.duplicate_item_data(template)
	if new_item == null:
		return null

	# Smithing bonus: +1 attack or +1 protection based on skill
	var smithing_skill: int = player.skills.get("smithing", 0)
	if _is_weapon(new_item) and "attack_bonus" in new_item:
		new_item.attack_bonus += smithing_skill / 5
	elif _is_armor(new_item) and "evasion_bonus" in new_item:
		new_item.evasion_bonus += smithing_skill / 10

	player.inventory.append(new_item)
	item_forged.emit(new_item, "Forged from Mithril!")
	GameManager.log_message("You forge a %s from Mithril!" % _get_item_name(new_item), ThemeColors.ABILITY_LEARNED)
	player.add_noise(Constants.NOISE_SMITHING)
	return new_item

# ============================================================================
# REFORGE — 2 Broken Glowing items → random enchanted item
# ============================================================================

func reforge(player: Player, material1: Variant, material2: Variant, depth: int) -> Variant:
	if not roll_success(player):
		_consume_material(player, material1)
		_consume_material(player, material2)
		smithing_failed.emit(null, "Reforging failed — materials consumed")
		GameManager.log_message("Your reforging attempt fails. The broken items crumble to dust.", ThemeColors.MSG_ERROR)
		return null

	_consume_material(player, material1)
	_consume_material(player, material2)

	# Generate random enchanted item for depth + 2
	var new_item = DataManager.get_random_item_for_depth(depth + 2)
	if new_item:
		# Bonus: reforged items get a small attack or evasion bonus
		if _is_weapon(new_item) and "attack_bonus" in new_item:
			new_item.attack_bonus += 1
		elif _is_armor(new_item) and "evasion_bonus" in new_item:
			new_item.evasion_bonus += 1
		player.inventory.append(new_item)
		item_forged.emit(new_item, "Reforged!")
		GameManager.log_message("The broken fragments reform into a %s!" % _get_item_name(new_item), ThemeColors.ABILITY_LEARNED)
		player.add_noise(Constants.NOISE_SMITHING)

	return new_item

# ============================================================================
# RECLAIM — 2 Broken Strange items → random artifact
# ============================================================================

func reclaim(player: Player, material1: Variant, material2: Variant, _depth: int) -> Variant:
	if not roll_success(player):
		_consume_material(player, material1)
		_consume_material(player, material2)
		smithing_failed.emit(null, "Reclaiming failed — materials consumed")
		GameManager.log_message("The strange fragments resist your efforts and dissolve.", ThemeColors.MSG_ERROR)
		return null

	_consume_material(player, material1)
	_consume_material(player, material2)

	# Generate a random artifact
	var artifact: DataManager.ArtifactData = DataManager.get_random_artifact()
	if artifact:
		var new_item: DataManager.ItemData = DataManager.duplicate_artifact_as_item(artifact)
		if new_item:
			player.inventory.append(new_item)
			item_forged.emit(new_item, "Reclaimed artifact!")
			GameManager.log_message("Ancient power surges through the forge — you have reclaimed %s!" % _get_item_name(new_item), ThemeColors.RARITY_ARTIFACT)
			player.add_noise(Constants.NOISE_SMITHING)
			return new_item

	# Fallback: generate high-quality item if no artifacts available
	var fallback = DataManager.get_random_item_for_depth(20)
	if fallback:
		if "attack_bonus" in fallback:
			fallback.attack_bonus += 3
		player.inventory.append(fallback)
		item_forged.emit(fallback, "Reclaimed!")
		GameManager.log_message("You reclaim a powerful %s from the strange fragments!" % _get_item_name(fallback), ThemeColors.ABILITY_LEARNED)
		player.add_noise(Constants.NOISE_SMITHING)
		return fallback

	return null

# ============================================================================
# HELPERS
# ============================================================================

func _consume_material(player: Player, material: Variant) -> void:
	var idx: int = player.inventory.find(material)
	if idx >= 0:
		# Handle stacking
		if "stack_count" in material and material.stack_count > 1:
			material.stack_count -= 1
		else:
			player.inventory.remove_at(idx)

func _get_item_name(item: Variant) -> String:
	if item == null:
		return "item"
	if "name" in item:
		return item.name
	return "item"

# ============================================================================
# RECIPE ACCESS
# ============================================================================

func get_available_recipes(player: Player) -> Array[Recipe]:
	var available: Array[Recipe] = []
	var smithing_skill: int = player.skills.get("smithing", 0)

	for recipe in recipes:
		if smithing_skill < recipe.required_skill:
			continue
		# Check ability requirement
		if recipe.required_ability >= 0:
			if not player.has_ability(Constants.Skill.S_SMT, recipe.required_ability):
				continue
		# Check materials
		var mats: Array = get_materials_for_recipe(player, recipe.type)
		if mats.size() < recipe.material_count:
			continue
		available.append(recipe)

	return available

func get_all_recipes_with_status(player: Player) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var smithing_skill: int = player.skills.get("smithing", 0)

	for recipe in recipes:
		var status: Dictionary = {
			"recipe": recipe,
			"available": true,
			"reason": "",
		}

		if smithing_skill < recipe.required_skill:
			status.available = false
			status.reason = "Requires Smithing %d" % recipe.required_skill

		if recipe.required_ability >= 0 and not player.has_ability(Constants.Skill.S_SMT, recipe.required_ability):
			status.available = false
			var ability_names: Dictionary = {
				Constants.SmithingAbility.SMT_WEAPONSMITH: "Weaponsmith",
				Constants.SmithingAbility.SMT_ARMOURSMITH: "Armoursmith",
				Constants.SmithingAbility.SMT_JEWELLER: "Jeweller",
				Constants.SmithingAbility.SMT_REFORGE: "Reforge",
				Constants.SmithingAbility.SMT_RECLAIM: "Reclaim",
			}
			var ability_name: String = ability_names.get(recipe.required_ability, "Unknown")
			status.reason = "Requires %s ability" % ability_name

		var mats: Array = get_materials_for_recipe(player, recipe.type)
		if mats.size() < recipe.material_count:
			status.available = false
			if status.reason.is_empty():
				status.reason = "Need %d materials (have %d)" % [recipe.material_count, mats.size()]

		result.append(status)

	return result
