extends Control
class_name SmithingPanel
## UI for the smithing system - displays when player is on a forge tile.
## Supports CREATE, REFORGE, RECLAIM, and MASTERWORK recipes.
## Handles Reforge Mastery (reject/reroll) and Reclaim Mastery (pick from 3).

const SmithingSystemScript := preload("res://scripts/systems/smithing_system.gd")

signal closed
signal item_forged(item: Variant)

var player: Player = null
var level: Level = null
var smithing_system: RefCounted = null  # SmithingSystem

# Selected state
var selected_recipe: RefCounted = null  # SmithingSystem.Recipe
var selected_template: Variant = null   # For CREATE: the item template to forge
var selected_materials: Array = []      # Materials chosen

# Mastery state
var _mastery_reforge_items: Array = []   # [item1, item2] for Reforge Mastery
var _mastery_reclaim_artifacts: Array = [] # [art1, art2, art3] for Reclaim Mastery
var _in_mastery_mode: bool = false

# Type choice state for reforge — player picks Weapon/Armor/Jewelry then subtype
var _reforge_type_chosen: bool = false
var _reforge_chosen_category: int = SmithingSystemScript.MaterialCategory.WEAPON
var _in_type_selection: bool = false  # True when showing category picker in item_list
var _in_subtype_selection: bool = false  # True when showing subtype picker
var _reforge_subtypes: Array = []  # Available subtypes for chosen category
var _reforge_chosen_template: Variant = null  # Chosen item subtype for reforge

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
	_in_mastery_mode = false
	_mastery_reforge_items.clear()
	_mastery_reclaim_artifacts.clear()
	PanelTransition.open_panel(self)

	_refresh_ui()
	grab_focus()

func close() -> void:
	selected_recipe = null
	selected_template = null
	selected_materials.clear()
	_current_templates.clear()
	_current_materials.clear()
	_in_mastery_mode = false
	_in_type_selection = false
	_in_subtype_selection = false
	_reforge_type_chosen = false
	_reforge_chosen_template = null
	_reforge_subtypes.clear()
	_mastery_reforge_items.clear()
	_mastery_reclaim_artifacts.clear()
	PanelTransition.close_panel(self, func(): closed.emit())

func _refresh_ui() -> void:
	if not player:
		return

	# Show forge type in title
	var forge_name: String = "Forge"
	if level:
		forge_name = level.get_terrain_name(player.grid_position)
		if forge_name.is_empty():
			forge_name = "Forge"
	title_label.text = forge_name

	# Update success chance display (varies by recipe type now)
	_update_success_display()

	# Populate recipe list (available + locked)
	_populate_recipes()

	# Clear item/material lists
	item_list.clear()
	material_list.clear()
	_current_templates.clear()
	_current_materials.clear()

	_update_forge_button()
	_update_info()

func _update_success_display() -> void:
	if not selected_recipe:
		var base_chance: int = smithing_system.get_success_chance(player)
		success_label.text = "Base Success: %d%%" % base_chance
		return

	var forge_bonus: int = 0
	if level:
		forge_bonus = level.get_forge_bonus(player.grid_position)
	var chance: int = smithing_system.get_success_chance(player, selected_recipe.type, forge_bonus)
	var uses: int = level.get_forge_uses(player.grid_position) if level else 0
	success_label.text = "Success: %d%% | Forge Uses: %d" % [chance, uses]

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
	# Map the ItemList index directly to the recipe (includes disabled items)
	var statuses: Array[Dictionary] = smithing_system.get_all_recipes_with_status(player)
	selected_recipe = null

	if index >= 0 and index < statuses.size():
		var status: Dictionary = statuses[index]
		if status.available:
			selected_recipe = status.recipe

	selected_template = null
	selected_materials.clear()
	_in_mastery_mode = false
	_in_type_selection = false
	_in_subtype_selection = false
	_reforge_type_chosen = false
	_reforge_chosen_template = null
	_reforge_subtypes.clear()
	_populate_items_for_recipe()
	_update_success_display()
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
				elif "protection_dice" in template and template.protection_dice != "" and template.protection_dice != "0d0":
					display += " [%s]" % template.protection_dice
				item_list.add_item(display)

			# Show Mithril as optional material (if player has any)
			_populate_optional_mithril()

		SmithingSystemScript.RecipeType.REFORGE:
			# Show type selection in item_list for player to choose output category
			if not _reforge_type_chosen:
				_in_type_selection = true
				item_list.add_item("Weapon")
				item_list.add_item("Armor")
				item_list.add_item("Jewelry")

		SmithingSystemScript.RecipeType.RECLAIM, \
		SmithingSystemScript.RecipeType.MASTERWORK:
			# No template selection — materials only
			pass

	# Populate material list (for non-CREATE recipes)
	if selected_recipe.type not in [
		SmithingSystemScript.RecipeType.CREATE_WEAPON,
		SmithingSystemScript.RecipeType.CREATE_ARMOR,
		SmithingSystemScript.RecipeType.CREATE_JEWELRY,
	]:
		_populate_materials()

func _populate_optional_mithril() -> void:
	## Show Mithril as an optional material for CREATE recipes.
	material_list.clear()
	_current_materials.clear()
	selected_materials.clear()
	var mithril_items: Array = smithing_system.get_mithril_materials(player)
	if not mithril_items.is_empty():
		_current_materials = mithril_items
		for mat in _current_materials:
			material_list.add_item("(Optional) %s — enhanced quality" % _get_item_display_name(mat))

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

	# Handle mastery pick-from-list
	if _in_mastery_mode:
		_handle_mastery_selection(index)
		return

	# Handle reforge category selection
	if _in_type_selection:
		_handle_type_selection(index)
		return

	# Handle reforge subtype selection
	if _in_subtype_selection:
		_handle_subtype_selection(index)
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

	# Determine needed count (Master Smith reduces Masterwork to 2)
	var needed: int = selected_recipe.material_count
	if selected_recipe.type == SmithingSystemScript.RecipeType.MASTERWORK and smithing_system.has_master_smith(player):
		needed = 2

	# For recipes needing multiple materials, toggle selection
	if index < _current_materials.size():
		var mat = _current_materials[index]
		if mat in selected_materials:
			selected_materials.erase(mat)
			material_list.set_item_custom_fg_color(index, Color.WHITE)
		else:
			if selected_materials.size() >= needed:
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

	# Mastery mode info
	if _in_mastery_mode:
		_update_mastery_info(lines)
		info_label.bbcode_enabled = true
		info_label.text = "\n".join(lines)
		return

	if selected_recipe:
		lines.append("[b]%s[/b]" % selected_recipe.name)
		lines.append(selected_recipe.description)
		lines.append("")
		lines.append("Required Skill: Smithing %d" % selected_recipe.required_skill)

		# Show material count (adjusted for recipe type)
		var needed: int = selected_recipe.material_count
		if selected_recipe.type in [SmithingSystemScript.RecipeType.CREATE_WEAPON, SmithingSystemScript.RecipeType.CREATE_ARMOR, SmithingSystemScript.RecipeType.CREATE_JEWELRY]:
			lines.append("Materials: Forge supplies (Mithril optional)")
		elif selected_recipe.type == SmithingSystemScript.RecipeType.MASTERWORK and smithing_system.has_master_smith(player):
			needed = 2
			lines.append("Materials needed: %d (Master Smith)" % needed)
		else:
			lines.append("Materials needed: %d" % needed)

		# Show recipe-specific info
		var forge_bonus: int = level.get_forge_bonus(player.grid_position) if level else 0
		var skill: int = player.skills.get("smithing", 0)
		match selected_recipe.type:
			SmithingSystemScript.RecipeType.CREATE_WEAPON, \
			SmithingSystemScript.RecipeType.CREATE_ARMOR, \
			SmithingSystemScript.RecipeType.CREATE_JEWELRY:
				lines.append("[color=cyan]Quality scales with Smithing skill (%d).[/color]" % skill)
				if not selected_materials.is_empty():
					lines.append("[color=gold]Using Mithril: lighter weight + bonus stats.[/color]")
			SmithingSystemScript.RecipeType.REFORGE:
				var cost: int = smithing_system.get_reforge_xp_cost(player)
				if player.xp_available < cost:
					lines.append("[color=red]XP Cost: %d (have %d) — Cannot afford![/color]" % [cost, player.xp_available])
				else:
					lines.append("XP Cost: %d (have %d)" % [cost, player.xp_available])
				# Show smithing tier info
				var tier: int = smithing_system._get_smithing_tier(skill)
				var tier_name: String = smithing_system._get_smithing_tier_name(tier)
				if not tier_name.is_empty():
					lines.append("[color=cyan]Quality tier: %s (+%d)[/color]" % [tier_name, tier])
				if _reforge_type_chosen and _reforge_chosen_template != null:
					var type_names: Array[String] = ["Weapon", "Armor", "Jewelry"]
					lines.append("[color=cyan]Forging: %s (%s)[/color]" % [_get_item_display_name(_reforge_chosen_template), type_names[_reforge_chosen_category]])
				elif _in_subtype_selection:
					var type_names: Array[String] = ["Weapon", "Armor", "Jewelry"]
					lines.append("[color=cyan]Category: %s — select a specific type above.[/color]" % type_names[_reforge_chosen_category])
				else:
					lines.append("Select an output category above.")
			SmithingSystemScript.RecipeType.RECLAIM:
				lines.append("XP Cost: artifact depth x %d" % SmithingSystemScript.RECLAIM_XP_MULTIPLIER)
				if smithing_system._get_expertise_discount(player) < 1.0:
					lines.append("(Expertise discount applied)")
			SmithingSystemScript.RecipeType.MASTERWORK:
				lines.append("XP Cost: artifact depth x %d" % SmithingSystemScript.MASTERWORK_XP_MULTIPLIER)
				if smithing_system._get_expertise_discount(player) < 1.0:
					lines.append("(Expertise discount applied)")

		# Show forge bonus
		if forge_bonus > 0:
			lines.append("Forge Bonus: +%d" % forge_bonus)

		# Show mastery info
		if selected_recipe.type == SmithingSystemScript.RecipeType.REFORGE and smithing_system.has_reforge_mastery(player):
			lines.append("[color=cyan]Reforge Mastery: You may reject and reroll once.[/color]")
		if selected_recipe.type == SmithingSystemScript.RecipeType.RECLAIM and smithing_system.has_reclaim_mastery(player):
			lines.append("[color=cyan]Reclaim Mastery: Choose from 3 artifacts.[/color]")

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
		var needed: int = selected_recipe.material_count if selected_recipe else 1
		if selected_recipe and selected_recipe.type == SmithingSystemScript.RecipeType.MASTERWORK and smithing_system.has_master_smith(player):
			needed = 2
		lines.append("[b]Materials (%d/%d):[/b]" % [selected_materials.size(), needed])
		for mat in selected_materials:
			lines.append("  - %s" % _get_item_display_name(mat))

	if lines.is_empty():
		lines.append("Select a recipe to begin smithing.")
		lines.append("")
		lines.append("Your Smithing skill: %d" % player.skills.get("smithing", 0))
		if level:
			var uses: int = level.get_forge_uses(player.grid_position)
			lines.append("Forge uses remaining: %d" % uses)

	info_label.bbcode_enabled = true
	info_label.text = "\n".join(lines)

func _update_mastery_info(lines: Array[String]) -> void:
	if not _mastery_reforge_items.is_empty():
		lines.append("[b]Reforge Mastery — Choose an item:[/b]")
		lines.append("Select from the item list above.")
		lines.append("You may reject the first item for a second chance.")
	elif not _mastery_reclaim_artifacts.is_empty():
		lines.append("[b]Reclaim Mastery — Choose an artifact:[/b]")
		lines.append("Select from the item list above.")
		for i in range(_mastery_reclaim_artifacts.size()):
			var a = _mastery_reclaim_artifacts[i]
			lines.append("%d. %s (depth %d)" % [i + 1, a.name, a.depth])

func _update_forge_button() -> void:
	var can_forge: bool = false

	if _in_mastery_mode or _in_type_selection or _in_subtype_selection:
		forge_button.disabled = true
		return

	if selected_recipe:
		var needed: int = selected_recipe.material_count
		if selected_recipe.type == SmithingSystemScript.RecipeType.MASTERWORK and smithing_system.has_master_smith(player):
			needed = 2
		var has_enough_materials: bool = selected_materials.size() >= needed
		match selected_recipe.type:
			SmithingSystemScript.RecipeType.CREATE_WEAPON, \
			SmithingSystemScript.RecipeType.CREATE_ARMOR, \
			SmithingSystemScript.RecipeType.CREATE_JEWELRY:
				# CREATE only needs a template — materials (Mithril) are optional
				can_forge = selected_template != null
			SmithingSystemScript.RecipeType.REFORGE:
				# Need materials + type chosen + enough XP
				var xp_cost: int = smithing_system.get_reforge_xp_cost(player)
				can_forge = has_enough_materials and _reforge_type_chosen and player.xp_available >= xp_cost
			SmithingSystemScript.RecipeType.RECLAIM:
				can_forge = has_enough_materials
			SmithingSystemScript.RecipeType.MASTERWORK:
				can_forge = has_enough_materials

	forge_button.disabled = not can_forge

func _on_forge_pressed() -> void:
	if not selected_recipe:
		return

	var depth: int = level.depth if level else 5
	var forge_bonus: int = level.get_forge_bonus(player.grid_position) if level else 0

	# Consume forge use (Task 5)
	if level:
		var remaining: int = level.consume_forge_use(player.grid_position)
		smithing_system.forge_used.emit(remaining)

	match selected_recipe.type:
		SmithingSystemScript.RecipeType.CREATE_WEAPON, \
		SmithingSystemScript.RecipeType.CREATE_ARMOR, \
		SmithingSystemScript.RecipeType.CREATE_JEWELRY:
			if selected_template:
				# Mithril is optional — pass it if selected, null otherwise
				var mithril: Variant = selected_materials[0] if not selected_materials.is_empty() else null
				smithing_system.create_item(player, selected_template, forge_bonus, mithril)

		SmithingSystemScript.RecipeType.REFORGE:
			if selected_materials.size() >= 2:
				if smithing_system.has_reforge_mastery(player):
					_start_reforge_mastery(depth, forge_bonus)
				else:
					smithing_system.reforge(player, selected_materials[0], selected_materials[1], depth, forge_bonus, _reforge_chosen_category, _reforge_type_chosen, _reforge_chosen_template)

		SmithingSystemScript.RecipeType.RECLAIM:
			if selected_materials.size() >= 2:
				if smithing_system.has_reclaim_mastery(player):
					_start_reclaim_mastery(depth, forge_bonus)
				else:
					smithing_system.reclaim(player, selected_materials[0], selected_materials[1], depth, forge_bonus)

		SmithingSystemScript.RecipeType.MASTERWORK:
			if selected_materials.size() >= 2:  # 2 with Master Smith, 4 without
				smithing_system.masterwork(player, selected_materials, depth, forge_bonus)

	# Reset state and refresh
	if not _in_mastery_mode:
		selected_template = null
		selected_materials.clear()
		_refresh_ui()

# ============================================================================
# TYPE SELECTION (Reforge)
# ============================================================================

func _handle_type_selection(index: int) -> void:
	# Map index to MaterialCategory: 0=Weapon, 1=Armor, 2=Jewelry
	match index:
		0: _reforge_chosen_category = SmithingSystemScript.MaterialCategory.WEAPON
		1: _reforge_chosen_category = SmithingSystemScript.MaterialCategory.ARMOR
		2: _reforge_chosen_category = SmithingSystemScript.MaterialCategory.JEWELRY
		_: return

	_in_type_selection = false
	_in_subtype_selection = true

	# Show available subtypes for the chosen category
	var depth: int = level.depth if level else 5
	_reforge_subtypes = smithing_system.get_reforge_subtypes(_reforge_chosen_category, depth)
	item_list.clear()
	for subtype in _reforge_subtypes:
		var display: String = _get_item_display_name(subtype)
		if "damage_dice" in subtype and subtype.damage_dice != "":
			display += " (%s)" % subtype.damage_dice
		elif "protection_dice" in subtype and subtype.protection_dice != "" and subtype.protection_dice != "0d0":
			display += " [%s]" % subtype.protection_dice
		item_list.add_item(display)

	_update_info()
	_update_forge_button()

func _handle_subtype_selection(index: int) -> void:
	if index < 0 or index >= _reforge_subtypes.size():
		return
	_reforge_chosen_template = _reforge_subtypes[index]
	_reforge_type_chosen = true
	_in_subtype_selection = false

	# Show selected subtype as confirmed
	item_list.clear()
	var display: String = _get_item_display_name(_reforge_chosen_template)
	item_list.add_item("Forging: %s (selected)" % display)
	item_list.set_item_disabled(0, true)

	_update_info()
	_update_forge_button()

# ============================================================================
# MASTERY FLOWS
# ============================================================================

func _start_reforge_mastery(depth: int, forge_bonus: int) -> void:
	_mastery_reforge_items = smithing_system.reforge_with_mastery(
		player, selected_materials[0], selected_materials[1], depth, forge_bonus, _reforge_chosen_category, _reforge_type_chosen, _reforge_chosen_template
	)
	if _mastery_reforge_items.is_empty():
		# Forge failed — already handled by smithing_system
		selected_materials.clear()
		_refresh_ui()
		return

	_in_mastery_mode = true
	# Show items in item_list for player to pick
	item_list.clear()
	for item in _mastery_reforge_items:
		var display: String = _get_item_display_name(item)
		if "damage_dice" in item and item.damage_dice != "":
			display += " (%s)" % item.damage_dice
		elif "protection_dice" in item and item.protection_dice != "":
			display += " [%s]" % item.protection_dice
		item_list.add_item(display)

	forge_button.disabled = true
	_update_info()

func _start_reclaim_mastery(depth: int, forge_bonus: int) -> void:
	_mastery_reclaim_artifacts = smithing_system.reclaim_with_mastery(
		player, selected_materials[0], selected_materials[1], depth, forge_bonus
	)
	if _mastery_reclaim_artifacts.is_empty():
		selected_materials.clear()
		_refresh_ui()
		return

	_in_mastery_mode = true
	# Show artifacts in item_list for player to pick
	item_list.clear()
	for artifact in _mastery_reclaim_artifacts:
		item_list.add_item("%s (depth %d)" % [artifact.name, artifact.depth])

	forge_button.disabled = true
	_update_info()

func _handle_mastery_selection(index: int) -> void:
	if not _mastery_reforge_items.is_empty():
		# Reforge Mastery: accept selected item
		if index < _mastery_reforge_items.size():
			var chosen = _mastery_reforge_items[index]
			smithing_system.accept_reforge_mastery_item(player, chosen)
	elif not _mastery_reclaim_artifacts.is_empty():
		# Reclaim Mastery: accept selected artifact
		if index < _mastery_reclaim_artifacts.size():
			var chosen = _mastery_reclaim_artifacts[index]
			smithing_system.accept_reclaim_mastery_artifact(player, chosen)

	# Exit mastery mode
	_in_mastery_mode = false
	_mastery_reforge_items.clear()
	_mastery_reclaim_artifacts.clear()
	selected_template = null
	selected_materials.clear()
	_refresh_ui()

# ============================================================================
# CALLBACKS
# ============================================================================

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
