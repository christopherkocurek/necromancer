extends Control
class_name SmithingPanel
## UI for the smithing system - displays when player is on a forge tile.
## Note: Using preload for SmithingSystem to avoid class_name resolution issues.

const SmithingSystemScript := preload("res://scripts/systems/smithing_system.gd")

signal closed
signal item_forged(item: Variant)

var player: Player = null
var level: Level = null
var smithing_system: RefCounted = null  # SmithingSystem - using RefCounted to avoid type resolution

# Selected items
var selected_item: Variant = null
var selected_material: Variant = null
var selected_recipe: RefCounted = null  # SmithingSystem.Recipe

# UI References
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var success_label: Label = $Panel/VBox/SuccessLabel
@onready var recipe_list: ItemList = $Panel/VBox/HSplit/RecipeSection/RecipeList
@onready var item_list: ItemList = $Panel/VBox/HSplit/ItemSection/VBox/ItemList
@onready var material_list: ItemList = $Panel/VBox/HSplit/ItemSection/VBox/MaterialList
@onready var info_label: RichTextLabel = $Panel/VBox/HSplit/InfoSection/InfoLabel
@onready var forge_button: Button = $Panel/VBox/ButtonRow/ForgeButton
@onready var close_button: Button = $Panel/VBox/ButtonRow/CloseButton

func _ready() -> void:
	visible = false
	smithing_system = SmithingSystemScript.new()

	# Connect button signals
	forge_button.pressed.connect(_on_forge_pressed)
	close_button.pressed.connect(close)
	recipe_list.item_selected.connect(_on_recipe_selected)
	item_list.item_selected.connect(_on_item_selected)
	material_list.item_selected.connect(_on_material_selected)

	# Connect smithing system signals
	smithing_system.item_enhanced.connect(_on_item_enhanced)
	smithing_system.smithing_failed.connect(_on_smithing_failed)

	# Style smithing panel with iron theme
	ThemeColors.apply_heading_font(title_label, ThemeColors.FONT_SIZE_H2)
	ThemeColors.apply_body_font(success_label)
	ThemeColors.apply_rich_body_font(info_label)
	ThemeColors.apply_button_theme(forge_button)
	ThemeColors.apply_button_theme(close_button)

func open(player_ref: Player, level_ref: Level) -> void:
	player = player_ref
	level = level_ref
	PanelTransition.open_panel(self)

	_refresh_ui()
	grab_focus()

func close() -> void:
	selected_item = null
	selected_material = null
	selected_recipe = null
	PanelTransition.close_panel(self, func(): closed.emit())

func _refresh_ui() -> void:
	if not player:
		return

	# Update title with forge info
	title_label.text = "Forge"

	# Update success chance display
	var chance: int = smithing_system.get_success_chance(player)
	success_label.text = "Success Chance: %d%%" % chance

	# Populate recipe list
	_populate_recipes()

	# Clear item lists initially
	item_list.clear()
	material_list.clear()

	# Update forge button state
	_update_forge_button()

	# Clear info
	_update_info()

func _populate_recipes() -> void:
	recipe_list.clear()

	var recipes: Array = smithing_system.get_available_recipes(player)
	for recipe in recipes:
		recipe_list.add_item(recipe.name)

	# Add unavailable recipes (grayed out) for reference
	var smithing_skill: int = player.skills.get("smithing", 0)
	for recipe in smithing_system.recipes:
		if smithing_skill < recipe.required_skill:
			var idx: int = recipe_list.add_item("%s (Requires Smithing %d)" % [recipe.name, recipe.required_skill])
			recipe_list.set_item_disabled(idx, true)

func _on_recipe_selected(index: int) -> void:
	var recipes: Array = smithing_system.get_available_recipes(player)
	if index < recipes.size():
		selected_recipe = recipes[index]
		_populate_items_for_recipe()
		_update_info()
	else:
		selected_recipe = null

	_update_forge_button()

func _populate_items_for_recipe() -> void:
	item_list.clear()
	material_list.clear()
	selected_item = null
	selected_material = null

	if not selected_recipe:
		return

	# Populate item list based on recipe type
	match selected_recipe.type:
		SmithingSystemScript.RecipeType.WEAPON_ENHANCEMENT:
			var weapons: Array = smithing_system.get_enhanceable_weapons(player)
			for weapon in weapons:
				item_list.add_item(_get_item_display_name(weapon))
		SmithingSystemScript.RecipeType.ARMOR_ENHANCEMENT:
			var armor: Array = smithing_system.get_enhanceable_armor(player)
			for armor_piece in armor:
				item_list.add_item(_get_item_display_name(armor_piece))
		SmithingSystemScript.RecipeType.REFORGE:
			# For reforge, just need salvage materials
			pass

	# Populate material list
	_populate_materials()

func _populate_materials() -> void:
	material_list.clear()

	if not selected_recipe:
		return

	# Search for materials by name since we might not have exact TVAL match
	var material_names: Array[String] = []
	match selected_recipe.type:
		SmithingSystemScript.RecipeType.WEAPON_ENHANCEMENT, SmithingSystemScript.RecipeType.ARMOR_ENHANCEMENT:
			material_names = ["mithril", "fragment", "ore", "metal"]
		SmithingSystemScript.RecipeType.REFORGE:
			material_names = ["salvage", "shard", "remnant"]

	for item in player.inventory:
		if not "name" in item:
			continue
		var item_name: String = item.name.to_lower()
		for mat_name in material_names:
			if item_name.contains(mat_name):
				material_list.add_item(_get_item_display_name(item))
				break

func _on_item_selected(index: int) -> void:
	if not selected_recipe:
		return

	var items: Array = []
	match selected_recipe.type:
		SmithingSystemScript.RecipeType.WEAPON_ENHANCEMENT:
			items = smithing_system.get_enhanceable_weapons(player)
		SmithingSystemScript.RecipeType.ARMOR_ENHANCEMENT:
			items = smithing_system.get_enhanceable_armor(player)

	if index < items.size():
		selected_item = items[index]
	else:
		selected_item = null

	_update_info()
	_update_forge_button()

func _on_material_selected(index: int) -> void:
	# Find the actual material item
	var material_names: Array[String] = []
	match selected_recipe.type:
		SmithingSystemScript.RecipeType.WEAPON_ENHANCEMENT, SmithingSystemScript.RecipeType.ARMOR_ENHANCEMENT:
			material_names = ["mithril", "fragment", "ore", "metal"]
		SmithingSystemScript.RecipeType.REFORGE:
			material_names = ["salvage", "shard", "remnant"]

	var found_materials: Array = []
	for item in player.inventory:
		if not "name" in item:
			continue
		var item_name: String = item.name.to_lower()
		for mat_name in material_names:
			if item_name.contains(mat_name):
				found_materials.append(item)
				break

	if index < found_materials.size():
		selected_material = found_materials[index]
	else:
		selected_material = null

	_update_info()
	_update_forge_button()

func _update_info() -> void:
	var lines: Array[String] = []

	if selected_recipe:
		lines.append("[b]%s[/b]" % selected_recipe.name)
		lines.append(selected_recipe.description)
		lines.append("")
		lines.append("Required Skill: Smithing %d" % selected_recipe.required_skill)
		lines.append("")

	if selected_item:
		lines.append("[b]Selected Item:[/b]")
		lines.append(_get_item_display_name(selected_item))
		if "damage_dice" in selected_item and selected_item.damage_dice != "":
			lines.append("Current Damage: %s" % selected_item.damage_dice)
		if "protection_dice" in selected_item and selected_item.protection_dice != "":
			lines.append("Current Protection: %s" % selected_item.protection_dice)
		lines.append("")

	if selected_material:
		lines.append("[b]Selected Material:[/b]")
		lines.append(_get_item_display_name(selected_material))

	if lines.is_empty():
		lines.append("Select a recipe to begin smithing.")
		lines.append("")
		lines.append("Your Smithing skill: %d" % player.skills.get("smithing", 0))

	info_label.bbcode_enabled = true
	info_label.text = "\n".join(lines)

func _update_forge_button() -> void:
	# Enable forge button only when we have valid selections
	var can_forge: bool = false

	if selected_recipe:
		match selected_recipe.type:
			SmithingSystemScript.RecipeType.WEAPON_ENHANCEMENT:
				can_forge = selected_item != null and selected_material != null
			SmithingSystemScript.RecipeType.ARMOR_ENHANCEMENT:
				can_forge = selected_item != null and selected_material != null
			SmithingSystemScript.RecipeType.REFORGE:
				can_forge = selected_material != null

	forge_button.disabled = not can_forge

func _on_forge_pressed() -> void:
	if not selected_recipe:
		return

	var success: bool = false

	match selected_recipe.type:
		SmithingSystemScript.RecipeType.WEAPON_ENHANCEMENT:
			if selected_item and selected_material:
				success = smithing_system.enhance_weapon(player, selected_item, selected_material)
		SmithingSystemScript.RecipeType.ARMOR_ENHANCEMENT:
			if selected_item and selected_material:
				success = smithing_system.enhance_armor(player, selected_item, selected_material)
		SmithingSystemScript.RecipeType.REFORGE:
			if selected_material and level:
				var new_item = smithing_system.reforge_salvage(player, selected_material, level.depth)
				success = new_item != null

	# Refresh UI after forging
	selected_item = null
	selected_material = null
	_refresh_ui()

func _on_item_enhanced(item: Variant, result: String) -> void:
	# Auto-identify items that are smithed
	if item != null and GameManager.needs_identification(item):
		GameManager.identify_item(item)
	item_forged.emit(item)
	# UI refresh happens in _on_forge_pressed

func _on_smithing_failed(item: Variant, reason: String) -> void:
	# UI refresh happens in _on_forge_pressed
	pass

func _get_item_display_name(item: Variant) -> String:
	if item == null:
		return "Unknown"
	if "name" in item:
		return item.name
	return "Unknown Item"

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

	# Quick forge with 'f' when ready
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F and not forge_button.disabled:
			_on_forge_pressed()
			get_viewport().set_input_as_handled()
