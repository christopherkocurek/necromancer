extends RefCounted
class_name SmithingSystem
## Smithing system for forging and enhancing items at forges.
## Based on Sil-Q smithing mechanics.

signal forge_used(remaining_uses: int)
signal item_enhanced(item: Variant, result: String)
signal smithing_failed(item: Variant, reason: String)

# Recipe types
enum RecipeType {
	WEAPON_ENHANCEMENT,  # Weapon + ore -> +1 damage die
	ARMOR_ENHANCEMENT,   # Armor + ore -> +1 protection die
	REFORGE,             # Salvage + smithing ability -> random item
}

# Material item types (TVALs)
const TVAL_METAL: int = 91      # Mithril Fragments, etc.
const TVAL_SALVAGE: int = 92    # Salvage materials

# Forge terrain IDs from terrain.txt (64-79)
const FORGE_TERRAIN_START: int = 64
const FORGE_TERRAIN_END: int = 79
const ORC_FORGE_START: int = 64     # 0-5 uses remaining
const SHADOW_FORGE_START: int = 70  # 0-5 uses remaining
const ANGDUR_FORGE_START: int = 76  # Unique forge, 0-3 uses

# Recipe definitions
class Recipe:
	var name: String
	var type: RecipeType
	var required_material_tval: int
	var required_material_name: String  # For display
	var required_skill: int  # Minimum smithing skill
	var description: String

	func _init(n: String, t: RecipeType, mat_tval: int, mat_name: String, skill: int, desc: String) -> void:
		name = n
		type = t
		required_material_tval = mat_tval
		required_material_name = mat_name
		required_skill = skill
		description = desc

# Available recipes
var recipes: Array[Recipe] = []

func _init() -> void:
	_init_recipes()

func _init_recipes() -> void:
	# Basic enhancement recipes
	recipes.append(Recipe.new(
		"Enhance Weapon",
		RecipeType.WEAPON_ENHANCEMENT,
		TVAL_METAL,
		"Mithril Fragments",
		2,  # Minimum smithing skill
		"Add +1 to weapon damage dice"
	))

	recipes.append(Recipe.new(
		"Enhance Armor",
		RecipeType.ARMOR_ENHANCEMENT,
		TVAL_METAL,
		"Mithril Fragments",
		2,
		"Add +1 to armor protection dice"
	))

	# Advanced reforging (requires Reforge ability)
	recipes.append(Recipe.new(
		"Reforge Salvage",
		RecipeType.REFORGE,
		TVAL_SALVAGE,
		"Salvage",
		5,
		"Reforge salvage into a random enchanted item"
	))

# ============================================================================
# FORGE DETECTION
# ============================================================================

func is_forge_tile(tile_id: int) -> bool:
	# Check if this is any type of forge tile
	return tile_id >= Level.Tile.FORGE

func get_forge_uses(level: Level, pos: Vector2i) -> int:
	# Get remaining uses for forge at position
	# Based on terrain IDs from terrain.txt
	var tile: int = level.get_tile(pos)

	if tile == Level.Tile.FORGE:
		# Generic forge tile - assume full uses
		return 5

	# For terrain data-based forges, we'd need the raw terrain ID
	# For now, assume the generic FORGE tile has 5 uses
	return 5

func consume_forge_use(level: Level, pos: Vector2i) -> bool:
	# Consume one use of the forge
	# For now, since we use a simplified tile system,
	# we can't easily track forge uses without extending Level
	# TODO: Add forge_uses tracking to Level or use terrain data
	forge_used.emit(get_forge_uses(level, pos) - 1)
	return true

# ============================================================================
# SMITHING CALCULATIONS
# ============================================================================

func get_success_chance(player: Player) -> int:
	# Success chance = smithing skill * 5, capped at 100%
	var smithing_skill: int = player.skills.get("smithing", 0)
	return mini(smithing_skill * 5, 100)

func roll_success(player: Player) -> bool:
	var chance: int = get_success_chance(player)
	return randi_range(1, 100) <= chance

# ============================================================================
# ITEM QUERIES
# ============================================================================

func get_enhanceable_weapons(player: Player) -> Array:
	# Get weapons from inventory that can be enhanced
	var weapons: Array = []
	for item in player.inventory:
		if _is_weapon(item) and not _has_flag(item, "NO_SMITHING"):
			weapons.append(item)
	return weapons

func get_enhanceable_armor(player: Player) -> Array:
	# Get armor from inventory that can be enhanced
	var armor: Array = []
	for item in player.inventory:
		if _is_armor(item) and not _has_flag(item, "NO_SMITHING"):
			armor.append(item)
	return armor

func get_materials(player: Player, tval: int) -> Array:
	# Get materials of a specific type from inventory
	var materials: Array = []
	for item in player.inventory:
		if "tval" in item and item.tval == tval:
			materials.append(item)
	return materials

func has_material(player: Player, material_name: String) -> bool:
	# Check if player has a material by name
	for item in player.inventory:
		if "name" in item and item.name.to_lower().contains(material_name.to_lower()):
			return true
	return false

func find_material(player: Player, material_name: String) -> Variant:
	# Find and return a material item
	for item in player.inventory:
		if "name" in item and item.name.to_lower().contains(material_name.to_lower()):
			return item
	return null

func _is_weapon(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	# Weapon TVALs: 20 (digging), 21 (hafted), 22 (polearm), 23 (sword)
	var tval: int = item.tval
	return tval >= 20 and tval <= 23

func _is_armor(item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false
	# Armor TVALs: 30 (boots), 31 (gloves), 32 (helm), 33 (crown),
	#              34 (shield), 35 (cloak), 36 (soft armor), 37 (mail)
	var tval: int = item.tval
	return tval >= 30 and tval <= 37

func _has_flag(item: Variant, flag: String) -> bool:
	if item == null:
		return false
	if "flags" in item and item.flags is Array:
		return flag in item.flags
	return false

# ============================================================================
# ENHANCEMENT EXECUTION
# ============================================================================

func enhance_weapon(player: Player, weapon: Variant, material: Variant) -> bool:
	# Enhance a weapon with a material
	if not _is_weapon(weapon):
		smithing_failed.emit(weapon, "Item is not a weapon")
		return false

	if _has_flag(weapon, "NO_SMITHING"):
		smithing_failed.emit(weapon, "This item cannot be modified")
		return false

	if not roll_success(player):
		# Failure - consume material but don't enhance
		_consume_material(player, material)
		smithing_failed.emit(weapon, "Smithing failed - material consumed")
		GameManager.log_message("Your smithing attempt fails. The material is ruined.", ThemeColors.MSG_ERROR)
		return false

	# Success - enhance the weapon
	_consume_material(player, material)

	# Increase damage dice
	if "damage_dice" in weapon:
		weapon.damage_dice = _enhance_dice(weapon.damage_dice)
		item_enhanced.emit(weapon, "Weapon damage increased!")
		GameManager.log_message("You successfully enhance the %s!" % _get_item_name(weapon), ThemeColors.ABILITY_LEARNED)
		return true

	return false

func enhance_armor(player: Player, armor: Variant, material: Variant) -> bool:
	# Enhance armor with a material
	if not _is_armor(armor):
		smithing_failed.emit(armor, "Item is not armor")
		return false

	if _has_flag(armor, "NO_SMITHING"):
		smithing_failed.emit(armor, "This item cannot be modified")
		return false

	if not roll_success(player):
		# Failure - consume material but don't enhance
		_consume_material(player, material)
		smithing_failed.emit(armor, "Smithing failed - material consumed")
		GameManager.log_message("Your smithing attempt fails. The material is ruined.", ThemeColors.MSG_ERROR)
		return false

	# Success - enhance the armor
	_consume_material(player, material)

	# Increase protection dice
	if "protection_dice" in armor:
		armor.protection_dice = _enhance_dice(armor.protection_dice)
		item_enhanced.emit(armor, "Armor protection increased!")
		GameManager.log_message("You successfully enhance the %s!" % _get_item_name(armor), ThemeColors.ABILITY_LEARNED)
		return true

	return false

func _enhance_dice(dice_string: String) -> String:
	# Parse "NdM" and return "(N+1)dM"
	if dice_string.is_empty():
		return "1d4"  # Default enhancement

	var regex := RegEx.new()
	regex.compile("(\\d+)d(\\d+)")
	var result := regex.search(dice_string)

	if not result:
		return dice_string  # Can't parse, return unchanged

	var num_dice: int = int(result.get_string(1))
	var die_size: int = int(result.get_string(2))

	return "%dd%d" % [num_dice + 1, die_size]

func _consume_material(player: Player, material: Variant) -> void:
	# Remove material from inventory
	var idx: int = player.inventory.find(material)
	if idx >= 0:
		player.inventory.remove_at(idx)

func _get_item_name(item: Variant) -> String:
	if item == null:
		return "item"
	if "name" in item:
		return item.name
	return "item"

# ============================================================================
# REFORGE (Advanced - requires Reforge ability)
# ============================================================================

func can_reforge(player: Player) -> bool:
	# Check if player has the Reforge ability
	# Reforge is a Smithing ability (skill 6, ability index TBD)
	# For now, check smithing skill >= 10
	return player.skills.get("smithing", 0) >= 10

func reforge_salvage(player: Player, salvage: Variant, depth: int) -> Variant:
	# Reforge salvage into a random enchanted item
	if not can_reforge(player):
		smithing_failed.emit(salvage, "Requires Reforge ability")
		return null

	if not roll_success(player):
		_consume_material(player, salvage)
		smithing_failed.emit(salvage, "Reforging failed")
		GameManager.log_message("Your reforging attempt fails. The salvage is lost.", ThemeColors.MSG_ERROR)
		return null

	# Success - create random item
	_consume_material(player, salvage)

	var new_item = DataManager.get_random_item_for_depth(depth + 2)
	if new_item:
		player.inventory.append(new_item)
		item_enhanced.emit(new_item, "Reforged into new item!")
		GameManager.log_message("You reforge the salvage into a %s!" % new_item.name, ThemeColors.ABILITY_LEARNED)

	return new_item

# ============================================================================
# RECIPE ACCESS
# ============================================================================

func get_available_recipes(player: Player) -> Array[Recipe]:
	# Get recipes the player can perform
	var available: Array[Recipe] = []
	var smithing_skill: int = player.skills.get("smithing", 0)

	for recipe in recipes:
		if smithing_skill >= recipe.required_skill:
			# Check for reforge ability requirement
			if recipe.type == RecipeType.REFORGE and not can_reforge(player):
				continue
			available.append(recipe)

	return available
