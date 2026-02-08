extends RefCounted
class_name SmithingSystem
## Smithing system for creating, reforging, reclaiming, and masterworking items at forges.
## Ported from Sil-Q smithing mechanics (cmd4.c), expanded for The Necromancer.
##
## Recipes:
##   CREATE    - Use Mithril to forge a new base item (Weaponsmith/Armoursmith/Jeweller)
##   REFORGE   - Combine 2 Broken Glowing items → type-filtered enchanted item (600 XP)
##   RECLAIM   - Combine 2 Broken Strange items → type-filtered artifact (depth×50 XP)
##   MASTERWORK - Combine 4 Broken Strange items → legendary artifact (depth×75 XP)

signal forge_used(remaining_uses: int)
signal item_forged(item: Variant, result: String)
signal smithing_failed(item: Variant, reason: String)
signal reforge_mastery_offer(item: Variant)       # UI: show reject/accept for Reforge Mastery
signal reclaim_mastery_offer(artifacts: Array)     # UI: show pick-from-3 for Reclaim Mastery

# Recipe types
enum RecipeType {
	CREATE_WEAPON,   # Mithril → new weapon (requires SMT_WEAPONSMITH)
	CREATE_ARMOR,    # Mithril → new armor (requires SMT_ARMOURSMITH)
	CREATE_JEWELRY,  # Mithril → new ring/amulet/light (requires SMT_JEWELLER)
	REFORGE,         # 2 Broken Glowing items → enchanted item (requires SMT_REFORGE)
	RECLAIM,         # 2 Broken Strange items → artifact (requires SMT_RECLAIM)
	MASTERWORK,      # 4 Broken Strange items → legendary artifact (requires SMT_MASTERWORK)
}

# Material type categories for type-filtered output
enum MaterialCategory {
	WEAPON,
	ARMOR,
	JEWELRY,
}

# Broken item IDs from object.txt
const BROKEN_GLOWING_WEAPON_ID: int = 491
const BROKEN_GLOWING_ARMOR_ID: int = 492
const BROKEN_GLOWING_JEWELRY_ID: int = 496  # NEW — Broken Glowing Ring
const BROKEN_STRANGE_WEAPON_ID: int = 493
const BROKEN_STRANGE_ARMOR_ID: int = 494
const BROKEN_STRANGE_JEWELRY_ID: int = 495
const MITHRIL_ID: int = 410  # Piece of Mithril

# Item name substrings for material detection
const BROKEN_GLOWING_NAMES: Array[String] = ["broken glowing", "shattered elven"]
const BROKEN_STRANGE_NAMES: Array[String] = ["broken strange", "twisted shadow"]
const MITHRIL_NAMES: Array[String] = ["mithril"]

# TVAL ranges for type filtering
const WEAPON_TVALS: Array[int] = [20, 21, 22, 23]  # Digging, Hafted, Polearm, Sword
const ARMOR_TVALS: Array[int] = [30, 31, 32, 34, 35, 36, 37]  # Boots, Gloves, Helm, Shield, Cloak, Soft, Mail
const JEWELRY_TVALS: Array[int] = [39, 40, 45]  # Light, Amulet, Ring

# XP costs
const REFORGE_XP_COST: int = 600
const RECLAIM_XP_MULTIPLIER: int = 50   # artifact.depth × this
const MASTERWORK_XP_MULTIPLIER: int = 75  # artifact.depth × this

# ============================================================================
# RECIPE DEFINITIONS
# ============================================================================

class Recipe:
	var name: String
	var type: RecipeType
	var required_skill: int  # Minimum smithing skill
	var required_ability: int  # SmithingAbility enum (-1 = none)
	var material_count: int  # How many materials needed
	var description: String

	func _init(n: String, t: RecipeType, skill: int, ability: int, mat_count: int, desc: String) -> void:
		name = n
		type = t
		required_skill = skill
		required_ability = ability
		material_count = mat_count
		description = desc

var recipes: Array[Recipe] = []

func _init() -> void:
	_init_recipes()

func _init_recipes() -> void:
	recipes.append(Recipe.new(
		"Forge Weapon", RecipeType.CREATE_WEAPON, 2,
		Constants.SmithingAbility.SMT_WEAPONSMITH, 1,
		"Forge a new weapon from Mithril. Choose the weapon type."
	))
	recipes.append(Recipe.new(
		"Forge Armor", RecipeType.CREATE_ARMOR, 2,
		Constants.SmithingAbility.SMT_ARMOURSMITH, 1,
		"Forge new armor from Mithril. Choose the armor type."
	))
	recipes.append(Recipe.new(
		"Forge Jewelry", RecipeType.CREATE_JEWELRY, 3,
		Constants.SmithingAbility.SMT_JEWELLER, 1,
		"Forge a ring, amulet, or light source from Mithril."
	))
	recipes.append(Recipe.new(
		"Reforge", RecipeType.REFORGE, 5,
		Constants.SmithingAbility.SMT_REFORGE, 2,
		"Combine 2 Broken Glowing items into a random enchanted item of chosen type. Costs 600 XP."
	))
	recipes.append(Recipe.new(
		"Reclaim", RecipeType.RECLAIM, 8,
		Constants.SmithingAbility.SMT_RECLAIM, 2,
		"Combine 2 Broken Strange items into a random artifact of chosen type."
	))
	recipes.append(Recipe.new(
		"Masterwork", RecipeType.MASTERWORK, 8,
		Constants.SmithingAbility.SMT_MASTERWORK, 4,
		"Combine 4 Broken Strange items into a legendary artifact of chosen type."
	))

# ============================================================================
# SUCCESS CHANCE — varies by recipe type (Task 8)
# ============================================================================

func get_success_chance(player: Player, recipe_type: RecipeType = RecipeType.CREATE_WEAPON, forge_bonus: int = 0) -> int:
	var skill: int = player.skills.get("smithing", 0) + forge_bonus
	# Song of Aule bonus (Task 13)
	if _has_song_of_aule(player):
		skill += 2
	match recipe_type:
		RecipeType.CREATE_WEAPON, RecipeType.CREATE_ARMOR, RecipeType.CREATE_JEWELRY:
			return mini(skill * 8, 95)
		RecipeType.REFORGE:
			return mini(skill * 6, 90)
		RecipeType.RECLAIM:
			return mini(skill * 5, 85)
		RecipeType.MASTERWORK:
			return mini(skill * 4, 80)
	return mini(skill * 8, 95)

func roll_success(player: Player, recipe_type: RecipeType = RecipeType.CREATE_WEAPON, forge_bonus: int = 0) -> bool:
	var chance: int = get_success_chance(player, recipe_type, forge_bonus)
	return randi_range(1, 100) <= chance

# ============================================================================
# XP COST HELPERS (Tasks 6, 9)
# ============================================================================

func _get_expertise_discount(player: Player) -> float:
	if not player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_EXPERTISE):
		return 1.0
	var smithing_skill: int = player.skills.get("smithing", 0)
	if smithing_skill >= 10:
		return 0.25  # 75% reduction
	return 0.5  # 50% reduction

func get_reforge_xp_cost(player: Player) -> int:
	return int(REFORGE_XP_COST * _get_expertise_discount(player))

func get_reclaim_xp_cost(player: Player, artifact_depth: int) -> int:
	return int(artifact_depth * RECLAIM_XP_MULTIPLIER * _get_expertise_discount(player))

func get_masterwork_xp_cost(player: Player, artifact_depth: int) -> int:
	return int(artifact_depth * MASTERWORK_XP_MULTIPLIER * _get_expertise_discount(player))

func _can_afford_xp(player: Player, cost: int) -> bool:
	return player.xp_available >= cost

func _spend_xp(player: Player, cost: int) -> void:
	player.xp_available -= cost

# ============================================================================
# SONG OF AULE CHECK (Task 13)
# ============================================================================

func _has_song_of_aule(_player: Player) -> bool:
	# Check if player has an active song matching "Aule" / song of crafting
	# The Necromancer uses Lore instead of Song, but this checks for equivalent
	if _player == null:
		return false
	if "active_song" in _player and _player.active_song is String:
		return _player.active_song.to_lower().contains("aule")
	return false

# ============================================================================
# MATERIAL QUERIES
# ============================================================================

func get_mithril_materials(player: Player) -> Array:
	var materials: Array = []
	for item in player.inventory:
		if _is_mithril(item):
			materials.append(item)
	return materials

func get_broken_glowing_items(player: Player) -> Array:
	var items: Array = []
	for item in player.inventory:
		if _is_broken_glowing(item):
			items.append(item)
	return items

func get_broken_strange_items(player: Player) -> Array:
	var items: Array = []
	for item in player.inventory:
		if _is_broken_strange(item):
			items.append(item)
	return items

func get_materials_for_recipe(player: Player, recipe_type: RecipeType) -> Array:
	match recipe_type:
		RecipeType.CREATE_WEAPON, RecipeType.CREATE_ARMOR, RecipeType.CREATE_JEWELRY:
			return get_mithril_materials(player)
		RecipeType.REFORGE:
			return get_broken_glowing_items(player)
		RecipeType.RECLAIM, RecipeType.MASTERWORK:
			return get_broken_strange_items(player)
	return []

func _is_mithril(item: Variant) -> bool:
	if item == null or not "name" in item:
		return false
	if "index" in item and item.index == MITHRIL_ID:
		return true
	var item_name: String = item.name.to_lower()
	for mat_name: String in MITHRIL_NAMES:
		if item_name.contains(mat_name):
			return true
	return false

func _is_broken_glowing(item: Variant) -> bool:
	if item == null or not "name" in item:
		return false
	if "index" in item and item.index in [BROKEN_GLOWING_WEAPON_ID, BROKEN_GLOWING_ARMOR_ID, BROKEN_GLOWING_JEWELRY_ID]:
		return true
	if _has_flag(item, "DAMAGED") and not _is_broken_strange(item):
		return true
	var item_name: String = item.name.to_lower()
	for mat_name: String in BROKEN_GLOWING_NAMES:
		if item_name.contains(mat_name):
			return true
	return false

func _is_broken_strange(item: Variant) -> bool:
	if item == null or not "name" in item:
		return false
	if "index" in item and item.index in [BROKEN_STRANGE_WEAPON_ID, BROKEN_STRANGE_ARMOR_ID, BROKEN_STRANGE_JEWELRY_ID]:
		return true
	var item_name: String = item.name.to_lower()
	for mat_name: String in BROKEN_STRANGE_NAMES:
		if item_name.contains(mat_name):
			return true
	return false

## Detect material category from a broken item
func get_material_category(item: Variant) -> MaterialCategory:
	if item == null:
		return MaterialCategory.WEAPON
	if "index" in item:
		if item.index in [BROKEN_GLOWING_WEAPON_ID, BROKEN_STRANGE_WEAPON_ID]:
			return MaterialCategory.WEAPON
		if item.index in [BROKEN_GLOWING_ARMOR_ID, BROKEN_STRANGE_ARMOR_ID]:
			return MaterialCategory.ARMOR
		if item.index in [BROKEN_GLOWING_JEWELRY_ID, BROKEN_STRANGE_JEWELRY_ID]:
			return MaterialCategory.JEWELRY
	if "tval" in item:
		if item.tval in WEAPON_TVALS:
			return MaterialCategory.WEAPON
		if item.tval in ARMOR_TVALS:
			return MaterialCategory.ARMOR
		if item.tval in JEWELRY_TVALS:
			return MaterialCategory.JEWELRY
	# Fallback: check name
	var n: String = item.name.to_lower() if "name" in item else ""
	if n.contains("weapon") or n.contains("sword") or n.contains("axe"):
		return MaterialCategory.WEAPON
	if n.contains("mail") or n.contains("armor") or n.contains("plate") or n.contains("shield"):
		return MaterialCategory.ARMOR
	if n.contains("ring") or n.contains("amulet") or n.contains("jewel") or n.contains("light"):
		return MaterialCategory.JEWELRY
	return MaterialCategory.WEAPON

func _get_tvals_for_category(category: MaterialCategory) -> Array[int]:
	match category:
		MaterialCategory.WEAPON: return WEAPON_TVALS
		MaterialCategory.ARMOR: return ARMOR_TVALS
		MaterialCategory.JEWELRY: return JEWELRY_TVALS
	return WEAPON_TVALS

# ============================================================================
# ITEM TYPE CHECKS
# ============================================================================

func _is_weapon(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	return item.tval in WEAPON_TVALS

func _is_armor(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	return item.tval in ARMOR_TVALS

func _is_jewelry(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	return item.tval in JEWELRY_TVALS

func _has_flag(item: Variant, flag: String) -> bool:
	if item == null:
		return false
	if "flags" in item and item.flags is Array:
		return flag in item.flags
	return false

# ============================================================================
# CREATE — Forge new items from Mithril
# ============================================================================

func get_creatable_items(recipe_type: RecipeType, depth: int) -> Array:
	var tvals: Array[int] = []
	match recipe_type:
		RecipeType.CREATE_WEAPON: tvals = WEAPON_TVALS
		RecipeType.CREATE_ARMOR: tvals = ARMOR_TVALS
		RecipeType.CREATE_JEWELRY: tvals = JEWELRY_TVALS

	var items: Array = []
	for item_data in DataManager.items.values():
		if not "tval" in item_data:
			continue
		if item_data.tval not in tvals:
			continue
		if _has_flag(item_data, "INSTA_ART") or _has_flag(item_data, "NO_SMITHING"):
			continue
		if "depth" in item_data and item_data.depth > depth + 5:
			continue
		items.append(item_data)
	return items

func create_item(player: Player, template: Variant, mithril: Variant, forge_bonus: int = 0) -> Variant:
	if not roll_success(player, RecipeType.CREATE_WEAPON, forge_bonus):
		_consume_material(player, mithril)
		smithing_failed.emit(null, "Creation failed — Mithril consumed")
		GameManager.log_message("Your smithing attempt fails. The Mithril is ruined.", ThemeColors.MSG_ERROR)
		return null

	_consume_material(player, mithril)

	var new_item: DataManager.ItemData = DataManager.duplicate_item_data(template)
	if new_item == null:
		return null

	# Smithing bonus: +attack or +protection based on skill
	var smithing_skill: int = _get_effective_skill(player)
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
# REFORGE — 2 Broken Glowing items → type-filtered enchanted item (Task 3)
# ============================================================================

func reforge(player: Player, material1: Variant, material2: Variant, depth: int, forge_bonus: int = 0) -> Variant:
	# Check XP cost (Task 6)
	var xp_cost: int = get_reforge_xp_cost(player)
	if not _can_afford_xp(player, xp_cost):
		smithing_failed.emit(null, "Not enough XP (need %d, have %d)" % [xp_cost, player.xp_available])
		GameManager.log_message("You lack the experience to attempt reforging (need %d XP)." % xp_cost, ThemeColors.MSG_ERROR)
		return null

	if not roll_success(player, RecipeType.REFORGE, forge_bonus):
		_consume_material(player, material1)
		_consume_material(player, material2)
		_spend_xp(player, xp_cost)
		smithing_failed.emit(null, "Reforging failed — materials and XP consumed")
		GameManager.log_message("Your reforging attempt fails. The broken items crumble to dust.", ThemeColors.MSG_ERROR)
		return null

	_consume_material(player, material1)
	_consume_material(player, material2)
	_spend_xp(player, xp_cost)

	# Type-filter based on input material category (Task 3)
	var category: MaterialCategory = get_material_category(material1)
	var tvals: Array[int] = _get_tvals_for_category(category)
	var new_item: DataManager.ItemData = DataManager.get_random_item_by_tvals(tvals, depth)

	if new_item == null:
		# Fallback: any item at depth
		new_item = DataManager.duplicate_item_data(DataManager.get_random_item_for_depth(depth + 2))

	if new_item:
		# Enchantment bonus for reforged items
		var smithing_skill: int = _get_effective_skill(player)
		if _is_weapon(new_item) and "attack_bonus" in new_item:
			new_item.attack_bonus += 1 + smithing_skill / 8
		elif _is_armor(new_item) and "evasion_bonus" in new_item:
			new_item.evasion_bonus += 1
		elif _is_jewelry(new_item) and "pval" in new_item:
			new_item.pval = maxi(new_item.pval, 1)
		player.inventory.append(new_item)
		item_forged.emit(new_item, "Reforged!")
		GameManager.log_message("The broken fragments reform into a %s!" % _get_item_name(new_item), ThemeColors.ABILITY_LEARNED)
		player.add_noise(Constants.NOISE_SMITHING)

	return new_item

## Reforge Mastery: reject result and reroll once (Task 10)
func reforge_with_mastery(player: Player, material1: Variant, material2: Variant, depth: int, forge_bonus: int = 0) -> Array:
	# Returns [item1, item2] — UI shows item1, player can reject for item2
	var xp_cost: int = get_reforge_xp_cost(player)
	if not _can_afford_xp(player, xp_cost):
		return []

	if not roll_success(player, RecipeType.REFORGE, forge_bonus):
		_consume_material(player, material1)
		_consume_material(player, material2)
		_spend_xp(player, xp_cost)
		smithing_failed.emit(null, "Reforging failed")
		GameManager.log_message("Your reforging attempt fails. The broken items crumble to dust.", ThemeColors.MSG_ERROR)
		return []

	_consume_material(player, material1)
	_consume_material(player, material2)
	_spend_xp(player, xp_cost)

	var category: MaterialCategory = get_material_category(material1)
	var tvals: Array[int] = _get_tvals_for_category(category)

	var item1: DataManager.ItemData = DataManager.get_random_item_by_tvals(tvals, depth)
	var item2: DataManager.ItemData = DataManager.get_random_item_by_tvals(tvals, depth)

	var results: Array = []
	if item1:
		results.append(item1)
	if item2:
		results.append(item2)
	return results

func accept_reforge_mastery_item(player: Player, item: DataManager.ItemData) -> void:
	if item == null:
		return
	var smithing_skill: int = _get_effective_skill(player)
	if _is_weapon(item) and "attack_bonus" in item:
		item.attack_bonus += 1 + smithing_skill / 8
	elif _is_armor(item) and "evasion_bonus" in item:
		item.evasion_bonus += 1
	elif _is_jewelry(item) and "pval" in item:
		item.pval = maxi(item.pval, 1)
	player.inventory.append(item)
	item_forged.emit(item, "Reforged!")
	GameManager.log_message("The broken fragments reform into a %s!" % _get_item_name(item), ThemeColors.ABILITY_LEARNED)
	player.add_noise(Constants.NOISE_SMITHING)

# ============================================================================
# RECLAIM — 2 Broken Strange items → type-filtered artifact (Task 4)
# ============================================================================

func reclaim(player: Player, material1: Variant, material2: Variant, _depth: int, forge_bonus: int = 0) -> Variant:
	# Type-filter based on input material category (Task 4)
	var category: MaterialCategory = get_material_category(material1)
	var tvals: Array[int] = _get_tvals_for_category(category)

	# Pre-roll artifact to calculate XP cost
	var artifact: DataManager.ArtifactData = DataManager.get_random_artifact_by_tvals(tvals)
	if artifact == null:
		# Fallback to any artifact
		artifact = DataManager.get_random_artifact()
	if artifact == null:
		smithing_failed.emit(null, "No artifacts available")
		return null

	var xp_cost: int = get_reclaim_xp_cost(player, artifact.depth)
	if not _can_afford_xp(player, xp_cost):
		smithing_failed.emit(null, "Not enough XP (need %d, have %d)" % [xp_cost, player.xp_available])
		GameManager.log_message("You lack the experience to reclaim this artifact (need %d XP)." % xp_cost, ThemeColors.MSG_ERROR)
		return null

	if not roll_success(player, RecipeType.RECLAIM, forge_bonus):
		_consume_material(player, material1)
		_consume_material(player, material2)
		_spend_xp(player, xp_cost)
		smithing_failed.emit(null, "Reclaiming failed — materials and XP consumed")
		GameManager.log_message("The strange fragments resist your efforts and dissolve.", ThemeColors.MSG_ERROR)
		return null

	_consume_material(player, material1)
	_consume_material(player, material2)
	_spend_xp(player, xp_cost)

	var new_item: DataManager.ItemData = DataManager.duplicate_artifact_as_item(artifact)
	if new_item:
		player.inventory.append(new_item)
		item_forged.emit(new_item, "Reclaimed artifact!")
		GameManager.log_message("Ancient power surges through the forge — you have reclaimed %s!" % _get_item_name(new_item), ThemeColors.RARITY_ARTIFACT)
		player.add_noise(Constants.NOISE_SMITHING)
		return new_item

	return null

## Reclaim Mastery: show 3 artifacts, player picks one (Task 11)
func reclaim_with_mastery(player: Player, material1: Variant, material2: Variant, _depth: int, forge_bonus: int = 0) -> Array[DataManager.ArtifactData]:
	var category: MaterialCategory = get_material_category(material1)
	var tvals: Array[int] = _get_tvals_for_category(category)
	var candidates: Array[DataManager.ArtifactData] = DataManager.get_random_artifacts_by_tvals(tvals, 3)

	if candidates.is_empty():
		return []

	# Use highest-depth artifact for XP cost calculation
	var max_depth: int = 0
	for a in candidates:
		max_depth = maxi(max_depth, a.depth)
	var xp_cost: int = get_reclaim_xp_cost(player, max_depth)

	if not _can_afford_xp(player, xp_cost):
		GameManager.log_message("You lack the experience to reclaim an artifact (need %d XP)." % xp_cost, ThemeColors.MSG_ERROR)
		return []

	if not roll_success(player, RecipeType.RECLAIM, forge_bonus):
		_consume_material(player, material1)
		_consume_material(player, material2)
		_spend_xp(player, xp_cost)
		smithing_failed.emit(null, "Reclaiming failed")
		GameManager.log_message("The strange fragments resist your efforts and dissolve.", ThemeColors.MSG_ERROR)
		return []

	_consume_material(player, material1)
	_consume_material(player, material2)
	_spend_xp(player, xp_cost)

	return candidates

func accept_reclaim_mastery_artifact(player: Player, artifact: DataManager.ArtifactData) -> Variant:
	if artifact == null:
		return null
	var new_item: DataManager.ItemData = DataManager.duplicate_artifact_as_item(artifact)
	if new_item:
		player.inventory.append(new_item)
		item_forged.emit(new_item, "Reclaimed artifact!")
		GameManager.log_message("Ancient power surges through the forge — you have reclaimed %s!" % _get_item_name(new_item), ThemeColors.RARITY_ARTIFACT)
		player.add_noise(Constants.NOISE_SMITHING)
	return new_item

# ============================================================================
# MASTERWORK — 4 Broken Strange items → legendary artifact (Task 2)
# ============================================================================

func masterwork(player: Player, materials: Array, _depth: int, forge_bonus: int = 0) -> Variant:
	# Master Smith (Task 12): only need 2 materials instead of 4
	var required_count: int = 4
	if player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_MASTER_SMITH):
		required_count = 2

	if materials.size() < required_count:
		smithing_failed.emit(null, "Need %d Broken Strange items" % required_count)
		return null

	# Type-filter based on first material
	var category: MaterialCategory = get_material_category(materials[0])
	var tvals: Array[int] = _get_tvals_for_category(category)

	# Get best artifact for this type
	var artifact: DataManager.ArtifactData = DataManager.get_best_artifact_by_tvals(tvals)
	if artifact == null:
		artifact = DataManager.get_random_artifact()
	if artifact == null:
		smithing_failed.emit(null, "No artifacts available")
		return null

	var xp_cost: int = get_masterwork_xp_cost(player, artifact.depth)
	if not _can_afford_xp(player, xp_cost):
		smithing_failed.emit(null, "Not enough XP (need %d, have %d)" % [xp_cost, player.xp_available])
		GameManager.log_message("You lack the experience for a masterwork (need %d XP)." % xp_cost, ThemeColors.MSG_ERROR)
		return null

	if not roll_success(player, RecipeType.MASTERWORK, forge_bonus):
		for i in range(required_count):
			_consume_material(player, materials[i])
		_spend_xp(player, xp_cost)
		smithing_failed.emit(null, "Masterwork failed — materials and XP consumed")
		GameManager.log_message("The fragments shatter! Your masterwork attempt has failed.", ThemeColors.MSG_ERROR)
		return null

	for i in range(required_count):
		_consume_material(player, materials[i])
	_spend_xp(player, xp_cost)

	var new_item: DataManager.ItemData = DataManager.duplicate_artifact_as_item(artifact)
	if new_item:
		player.inventory.append(new_item)
		item_forged.emit(new_item, "Masterwork!")
		GameManager.log_message("A masterwork of the Third Age! You have forged %s!" % _get_item_name(new_item), ThemeColors.RARITY_ARTIFACT)
		player.add_noise(Constants.NOISE_SMITHING)
		return new_item

	return null

# ============================================================================
# HELPERS
# ============================================================================

func _get_effective_skill(player: Player) -> int:
	var skill: int = player.skills.get("smithing", 0)
	if _has_song_of_aule(player):
		skill += 2
	return skill

func _consume_material(player: Player, material: Variant) -> void:
	var idx: int = player.inventory.find(material)
	if idx >= 0:
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
	var smithing_skill: int = _get_effective_skill(player)

	for recipe in recipes:
		if smithing_skill < recipe.required_skill:
			continue
		if recipe.required_ability >= 0:
			if not player.has_ability(Constants.Skill.S_SMT, recipe.required_ability):
				continue
		var mats: Array = get_materials_for_recipe(player, recipe.type)
		# Master Smith reduces Masterwork material requirement
		var needed: int = recipe.material_count
		if recipe.type == RecipeType.MASTERWORK and player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_MASTER_SMITH):
			needed = 2
		if mats.size() < needed:
			continue
		available.append(recipe)

	return available

func get_all_recipes_with_status(player: Player) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var smithing_skill: int = _get_effective_skill(player)

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
				Constants.SmithingAbility.SMT_MASTERWORK: "Masterwork",
			}
			var ability_name: String = ability_names.get(recipe.required_ability, "Unknown")
			status.reason = "Requires %s ability" % ability_name

		var mats: Array = get_materials_for_recipe(player, recipe.type)
		var needed: int = recipe.material_count
		if recipe.type == RecipeType.MASTERWORK and player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_MASTER_SMITH):
			needed = 2
		if mats.size() < needed:
			status.available = false
			if status.reason.is_empty():
				status.reason = "Need %d materials (have %d)" % [needed, mats.size()]

		result.append(status)

	return result

## Check if player has Reforge Mastery ability
func has_reforge_mastery(player: Player) -> bool:
	return player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_REFORGE_MASTERY)

## Check if player has Reclaim Mastery ability
func has_reclaim_mastery(player: Player) -> bool:
	return player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_RECLAIM_MASTERY)

## Check if player has Master Smith ability
func has_master_smith(player: Player) -> bool:
	return player.has_ability(Constants.Skill.S_SMT, Constants.SmithingAbility.SMT_MASTER_SMITH)

## Smithing material detection for external use (bot, pickup priority)
func is_smithing_material(item: Variant) -> bool:
	return _is_mithril(item) or _is_broken_glowing(item) or _is_broken_strange(item)
