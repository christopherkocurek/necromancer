extends Control
class_name SmithingPanel
## UI for the smithing system - displays when player is on a forge tile.
## Supports CREATE (Mithril → item), REFORGE (2 Broken Glowing → enchanted),
## and RECLAIM (2 Broken Strange → artifact).

const SmithingSystemScript := preload("res://scripts/systems/smithing_system.gd")

signal closed
signal item_forged(item: Variant)

var player: Player = null
var level: Level = null
var smithing_system: RefCounted = null  # SmithingSystem

# Selected state
var selected_recipe: RefCounted = null  # SmithingSystem.Recipe
var selected_template: Variant = null   # For CREATE: the item template to forge
var selected_materials: Array = []      # Materials chosen (1 for create, 2 for reforge/reclaim)

# Cached lists for index mapping
var _current_templates: Array = []
var _current_materials: Array = []

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
	smithing_system.item_forged.connect(_on_item_forged)
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
	selected_recipe = null
	selected_template = null
	selected_materials.clear()
	_current_templates.clear()
	_current_materials.clear()
	PanelTransition.close_panel(self, func(): closed.emit())

func _refresh_ui() -> void:
	if not player:
		return

	title_label.text = "Forge"

	# Update success chance display
	var chance: int = smithing_system.get_success_chance(player)
	success_label.text = "Success Chance: %d%%" % chance

	# Populate recipe list (available + locked)
	_populate_recipes()

	# Clear item/material lists
	item_list.clear()
	material_list.clear()
	_current_templates.clear()
	_current_materials.clear()

	_update_forge_button()
	_update_info()

func _populate_recipes() -> void:
	recipe_list.clear()

	var statuses: Array[Dictionary] = smithing_system.get_all_recipes_with_status(player)
	for status in statuses:
		var recipe = status.recipe
		if status.available:
			recipe_list.add_item(recipe.name)
		else:
			var idx: int = recipe_list.add_item("%s (%s)" % [recipe.name, status.reason])
			recipe_list.set_item_disabled(idx, true)

func _on_recipe_selected(index: int) -> void:
	# Map the index back to available recipes only
	var statuses: Array[Dictionary] = smithing_system.get_all_recipes_with_status(player)
	var available_idx: int = 0
	selected_recipe = null

	for status in statuses:
		if status.available:
			if available_idx == index:
				selected_recipe = status.recipe
				break
			available_idx += 1

	selected_template = null
	selected_materials.clear()
	_populate_items_for_recipe()
	_update_info()
	_update_forge_button()

func _populate_items_for_recipe() -> void:
	item_list.clear()
	material_list.clear()
	_current_templates.clear()
	_current_materials.clear()
	selected_template = null
	selected_materials.clear()

	if not selected_recipe:
		return

	match selected_recipe.type:
		SmithingSystemScript.RecipeType.CREATE_WEAPON, \
		SmithingSystemScript.RecipeType.CREATE_ARMOR, \
		SmithingSystemScript.RecipeType.CREATE_JEWELRY:
			# Show creatable item templates in the item list
			var depth: int = level.depth if level else 5
			_current_templates = smithing_system.get_creatable_items(selected_recipe.type, depth)
			for template in _current_templates:
				var display: String = _get_item_display_name(template)
				if "damage_dice" in template and template.damage_dice != "":
					display += " (%s)" % template.damage_dice
				elif "protection_dice" in template and template.protection_dice != "":
					display += " [%s]" % template.protection_dice
				item_list.add_item(display)

		SmithingSystemScript.RecipeType.REFORGE, \
		SmithingSystemScript.RecipeType.RECLAIM:
			# No template selection — materials only
			pass

	# Populate material list
	_populate_materials()

func _populate_materials() -> void:
	material_list.clear()
	_current_materials.clear()

	if not selected_recipe:
		return

	_current_materials = smithing_system.get_materials_for_recipe(player, selected_recipe.type)
	for mat in _current_materials:
		material_list.add_item(_get_item_display_name(mat))

func _on_item_selected(index: int) -> void:
	if not selected_recipe:
		return

	if index < _current_templates.size():
		selected_template = _current_templates[index]
	else:
		selected_template = null

	_update_info()
	_update_forge_button()

func _on_material_selected(index: int) -> void:
	if not selected_recipe:
		return

	# For recipes needing 2 materials, toggle selection
	if index < _current_materials.size():
		var mat = _current_materials[index]
		if mat in selected_materials:
			selected_materials.erase(mat)
			material_list.set_item_custom_fg_color(index, Color.WHITE)
		else:
			if selected_materials.size() >= selected_recipe.material_count:
				# Deselect oldest
				var oldest = selected_materials.pop_front()
				var oldest_idx: int = _current_materials.find(oldest)
				if oldest_idx >= 0:
					material_list.set_item_custom_fg_color(oldest_idx, Color.WHITE)
			selected_materials.append(mat)
			material_list.set_item_custom_fg_color(index, ThemeColors.ABILITY_LEARNED)

	_update_info()
	_update_forge_button()

func _update_info() -> void:
	var lines: Array[String] = []

	if selected_recipe:
		lines.append("[b]%s[/b]" % selected_recipe.name)
		lines.append(selected_recipe.description)
		lines.append("")
		lines.append("Required Skill: Smithing %d" % selected_recipe.required_skill)
		lines.append("Materials needed: %d" % selected_recipe.material_count)
		lines.append("")

	if selected_template:
		lines.append("[b]Forge:[/b] %s" % _get_item_display_name(selected_template))
		if "damage_dice" in selected_template and selected_template.damage_dice != "":
			lines.append("Damage: %s" % selected_template.damage_dice)
		if "protection_dice" in selected_template and selected_template.protection_dice != "":
			lines.append("Protection: %s" % selected_template.protection_dice)
		if "evasion_bonus" in selected_template and selected_template.evasion_bonus != 0:
			lines.append("Evasion: %+d" % selected_template.evasion_bonus)
		lines.append("")

	if not selected_materials.is_empty():
		lines.append("[b]Materials (%d/%d):[/b]" % [selected_materials.size(), selected_recipe.material_count if selected_recipe else 1])
		for mat in selected_materials:
			lines.append("  - %s" % _get_item_display_name(mat))

	if lines.is_empty():
		lines.append("Select a recipe to begin smithing.")
		lines.append("")
		lines.append("Your Smithing skill: %d" % player.skills.get("smithing", 0))

	info_label.bbcode_enabled = true
	info_label.text = "\n".join(lines)

func _update_forge_button() -> void:
	var can_forge: bool = false

	if selected_recipe:
		var has_enough_materials: bool = selected_materials.size() >= selected_recipe.material_count
		match selected_recipe.type:
			SmithingSystemScript.RecipeType.CREATE_WEAPON, \
			SmithingSystemScript.RecipeType.CREATE_ARMOR, \
			SmithingSystemScript.RecipeType.CREATE_JEWELRY:
				can_forge = selected_template != null and has_enough_materials
			SmithingSystemScript.RecipeType.REFORGE:
				can_forge = has_enough_materials
			SmithingSystemScript.RecipeType.RECLAIM:
				can_forge = has_enough_materials

	forge_button.disabled = not can_forge

func _on_forge_pressed() -> void:
	if not selected_recipe:
		return

	var depth: int = level.depth if level else 5

	match selected_recipe.type:
		SmithingSystemScript.RecipeType.CREATE_WEAPON, \
		SmithingSystemScript.RecipeType.CREATE_ARMOR, \
		SmithingSystemScript.RecipeType.CREATE_JEWELRY:
			if selected_template and not selected_materials.is_empty():
				smithing_system.create_item(player, selected_template, selected_materials[0])

		SmithingSystemScript.RecipeType.REFORGE:
			if selected_materials.size() >= 2:
				smithing_system.reforge(player, selected_materials[0], selected_materials[1], depth)

		SmithingSystemScript.RecipeType.RECLAIM:
			if selected_materials.size() >= 2:
				smithing_system.reclaim(player, selected_materials[0], selected_materials[1], depth)

	# Reset state and refresh
	selected_template = null
	selected_materials.clear()
	_refresh_ui()

func _on_item_forged(item: Variant, _result: String) -> void:
	if item != null and GameManager.needs_identification(item):
		GameManager.identify_item(item)
	item_forged.emit(item)

func _on_smithing_failed(_item: Variant, _reason: String) -> void:
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
