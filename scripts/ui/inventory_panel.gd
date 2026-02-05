extends Control
class_name InventoryPanel
## Inventory management UI with 4x6 item grid and equipment paper doll.

signal item_selected(item_data: Variant)
signal item_equipped(item_data: Variant, slot: int)
signal item_dropped(item_data: Variant)
signal closed

const GRID_COLS: int = 4
const GRID_ROWS: int = 6
const SLOT_SIZE: Vector2 = Vector2(64, 64)
const TILE_SIZE: int = 64

var player: Player
var selected_item: Variant = null
var selected_slot_index: int = -1

# Shared tileset texture for item sprites
static var _tileset_texture: Texture2D = null
static var _magenta_shader: ShaderMaterial = null

# UI References
@onready var inventory_grid: GridContainer = $HSplitContainer/InventorySection/InventoryGrid
@onready var equipment_container: GridContainer = $HSplitContainer/EquipmentSection/EquipmentSlots
@onready var item_info: RichTextLabel = $HSplitContainer/InventorySection/ItemInfo
@onready var weight_label: Label = $HSplitContainer/InventorySection/WeightLabel

# Equipment slot buttons (mapped by Constants.EquipSlot)
var equipment_slots: Dictionary = {}
var inventory_slots: Array[Button] = []

func _ready() -> void:
	# Load shared resources
	if not _tileset_texture:
		_tileset_texture = load("res://assets/sprites/necromancer_dcss_tileset.png")
	if not _magenta_shader:
		_magenta_shader = load("res://assets/shaders/magenta_transparent.tres")

	_setup_inventory_grid()
	_setup_equipment_slots()
	visible = false

func open(player_ref: Player) -> void:
	player = player_ref
	visible = true
	_refresh_inventory()
	_refresh_equipment()
	grab_focus()

func close() -> void:
	visible = false
	selected_item = null
	selected_slot_index = -1
	closed.emit()

func _setup_inventory_grid() -> void:
	inventory_grid.columns = GRID_COLS

	for i in range(GRID_COLS * GRID_ROWS):
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.toggle_mode = true
		slot.button_group = _get_inventory_button_group()
		slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		slot.gui_input.connect(_on_slot_gui_input.bind(i))

		# Style empty slot
		slot.add_theme_stylebox_override("normal", _create_slot_style(Color(0.2, 0.2, 0.2)))
		slot.add_theme_stylebox_override("hover", _create_slot_style(Color(0.3, 0.3, 0.3)))
		slot.add_theme_stylebox_override("pressed", _create_slot_style(Color(0.3, 0.4, 0.5)))

		inventory_grid.add_child(slot)
		inventory_slots.append(slot)

func _setup_equipment_slots() -> void:
	# Create equipment slot buttons arranged as paper doll in a 3-column grid
	# Layout (read left-to-right, top-to-bottom):
	# Row 0: [empty] [HEAD]    [empty]
	# Row 1: [NECK]  [BODY]    [CLOAK]
	# Row 2: [WEAPON][empty]   [OFF_HAND]
	# Row 3: [HANDS] [empty]   [BOW]
	# Row 4: [RING_L][FEET]    [RING_R]
	# Row 5: [LIGHT] [empty]   [QUIVER]

	var slot_names: Dictionary = {
		Constants.EquipSlot.HEAD: "Head",
		Constants.EquipSlot.NECK: "Neck",
		Constants.EquipSlot.CLOAK: "Cloak",
		Constants.EquipSlot.BODY: "Body",
		Constants.EquipSlot.WEAPON: "Weapon",
		Constants.EquipSlot.OFF_HAND: "Off-Hand",
		Constants.EquipSlot.BOW: "Bow",
		Constants.EquipSlot.HANDS: "Hands",
		Constants.EquipSlot.RING_L: "Ring L",
		Constants.EquipSlot.RING_R: "Ring R",
		Constants.EquipSlot.FEET: "Feet",
		Constants.EquipSlot.LIGHT: "Light",
		Constants.EquipSlot.QUIVER: "Quiver",
	}

	# Grid layout: each row is [left, center, right]
	# Use -1 for empty spacer cells
	var grid_layout: Array = [
		[-1, Constants.EquipSlot.HEAD, -1],                           # Row 0
		[Constants.EquipSlot.NECK, Constants.EquipSlot.BODY, Constants.EquipSlot.CLOAK],  # Row 1
		[Constants.EquipSlot.WEAPON, -1, Constants.EquipSlot.OFF_HAND],  # Row 2
		[Constants.EquipSlot.HANDS, -1, Constants.EquipSlot.BOW],        # Row 3
		[Constants.EquipSlot.RING_L, Constants.EquipSlot.FEET, Constants.EquipSlot.RING_R],  # Row 4
		[Constants.EquipSlot.LIGHT, -1, Constants.EquipSlot.QUIVER],     # Row 5
	]

	equipment_container.columns = 3

	for row in grid_layout:
		for slot_id in row:
			if slot_id == -1:
				# Add empty spacer control
				var spacer := Control.new()
				spacer.custom_minimum_size = SLOT_SIZE
				equipment_container.add_child(spacer)
			else:
				var slot := Button.new()
				slot.custom_minimum_size = SLOT_SIZE
				slot.tooltip_text = slot_names[slot_id]
				slot.pressed.connect(_on_equipment_slot_pressed.bind(slot_id))

				slot.add_theme_stylebox_override("normal", _create_slot_style(Color(0.15, 0.2, 0.15)))
				slot.add_theme_stylebox_override("hover", _create_slot_style(Color(0.25, 0.3, 0.25)))

				equipment_container.add_child(slot)
				equipment_slots[slot_id] = slot

func _refresh_inventory() -> void:
	if not player:
		return

	for i in range(inventory_slots.size()):
		var slot: Button = inventory_slots[i]
		if i < player.inventory.size():
			var item = player.inventory[i]
			slot.icon = _get_item_icon(item)
			slot.text = ""  # Clear text, use icon instead
			slot.tooltip_text = _get_item_name(item)
		else:
			slot.icon = null
			slot.text = ""
			slot.tooltip_text = "Empty"

	_update_weight_display()

func _refresh_equipment() -> void:
	if not player:
		return

	# Map player equipment dict keys to slot IDs
	var slot_key_map: Dictionary = {
		"weapon": Constants.EquipSlot.WEAPON,
		"off_hand": Constants.EquipSlot.OFF_HAND,
		"armor": Constants.EquipSlot.BODY,
		"cloak": Constants.EquipSlot.CLOAK,
		"head": Constants.EquipSlot.HEAD,
		"hands": Constants.EquipSlot.HANDS,
		"feet": Constants.EquipSlot.FEET,
		"ring_left": Constants.EquipSlot.RING_L,
		"ring_right": Constants.EquipSlot.RING_R,
		"amulet": Constants.EquipSlot.NECK,
		"light": Constants.EquipSlot.LIGHT,
	}

	for equip_key in player.equipment:
		var slot_id: int = slot_key_map.get(equip_key, -1)
		if slot_id < 0 or not equipment_slots.has(slot_id):
			continue

		var slot: Button = equipment_slots[slot_id]
		var item = player.equipment[equip_key]

		if item != null:
			slot.icon = _get_item_icon(item)
			slot.text = ""  # Clear text, use icon instead
			slot.tooltip_text = _get_item_name(item)
		else:
			slot.icon = null
			slot.text = ""

func _on_inventory_slot_pressed(index: int) -> void:
	if not player or index >= player.inventory.size():
		selected_item = null
		selected_slot_index = -1
		_update_item_info(null)
		return

	selected_item = player.inventory[index]
	selected_slot_index = index
	_update_item_info(selected_item)
	item_selected.emit(selected_item)

func _on_equipment_slot_pressed(slot_id: int) -> void:
	if not player:
		return

	# If we have a selected inventory item, try to equip it
	if selected_item != null:
		var item_slot: int = _get_item_slot(selected_item)
		if item_slot == slot_id or (slot_id == Constants.EquipSlot.RING_R and item_slot == Constants.EquipSlot.RING_L):
			_try_equip_item(selected_item, slot_id)
		return

	# Otherwise, show equipped item info or unequip
	var slot_key: String = _get_slot_key(slot_id)
	if slot_key.is_empty():
		return

	var equipped_item = player.equipment.get(slot_key)
	if equipped_item != null:
		_update_item_info(equipped_item)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right-click context menu or quick action
			if index < player.inventory.size():
				var item = player.inventory[index]
				_show_item_context_menu(item, index)

func _try_equip_item(item: Variant, slot_id: int) -> void:
	var slot_key: String = _get_slot_key(slot_id)
	if slot_key.is_empty():
		return

	if player.equip_item(item, slot_key):
		selected_item = null
		selected_slot_index = -1
		_refresh_inventory()
		_refresh_equipment()
		item_equipped.emit(item, slot_id)

func _show_item_context_menu(item: Variant, index: int) -> void:
	# Simple action for now - try to equip or drop
	var item_slot: int = _get_item_slot(item)
	if item_slot >= 0:
		# Equippable item - try to equip
		var slot_key: String = _get_slot_key(item_slot)
		if not slot_key.is_empty() and player.equip_item(item, slot_key):
			_refresh_inventory()
			_refresh_equipment()
	else:
		# Non-equippable - could drop, use, etc.
		pass

func _update_item_info(item: Variant) -> void:
	if item == null:
		item_info.text = "Select an item to see details."
		return

	var name_str: String = _get_item_name(item)
	var stats_str: String = ""

	if "attack_bonus" in item and item.attack_bonus != 0:
		stats_str += "Attack: %+d\n" % item.attack_bonus
	if "damage_dice" in item and item.damage_dice != "":
		stats_str += "Damage: %s\n" % item.damage_dice
	if "evasion_bonus" in item and item.evasion_bonus != 0:
		stats_str += "Evasion: %+d\n" % item.evasion_bonus
	if "protection_dice" in item and item.protection_dice != "":
		stats_str += "Protection: %s\n" % item.protection_dice
	if "weight" in item:
		stats_str += "Weight: %.1f lb\n" % (item.weight / 10.0)

	var desc_str: String = item.description if "description" in item else ""

	item_info.bbcode_enabled = true
	item_info.text = "[b]%s[/b]\n%s\n%s" % [name_str, stats_str, desc_str]

func _update_weight_display() -> void:
	if not player:
		return

	var total_weight: float = 0.0
	for item in player.inventory:
		if "weight" in item:
			total_weight += item.weight / 10.0

	for slot_key in player.equipment:
		var item = player.equipment[slot_key]
		if item != null and "weight" in item:
			total_weight += item.weight / 10.0

	weight_label.text = "Weight: %.1f lb" % total_weight

# ============================================================================
# UTILITY
# ============================================================================

func _get_item_char(item: Variant) -> String:
	if item == null:
		return "?"
	# ItemData/ArtifactData classes have display_char property
	if "display_char" in item and item.display_char != "":
		return item.display_char
	return "?"

func _get_item_icon(item: Variant) -> AtlasTexture:
	if item == null or not _tileset_texture:
		return null

	# Get item index - works for both ItemData and ArtifactData
	var item_index: int = -1
	if "index" in item:
		item_index = item.index
	else:
		return null

	# Determine if it's an artifact or regular item
	var is_artifact: bool = item is DataManager.ArtifactData if item else false

	# Get atlas coordinates from TileMapper
	var atlas_coords: Vector2i
	if is_artifact:
		atlas_coords = TileMapper.get_artifact_coords(item_index)
	else:
		atlas_coords = TileMapper.get_item_coords(item_index)

	# Create atlas texture with the correct region
	var atlas := AtlasTexture.new()
	atlas.atlas = _tileset_texture
	atlas.region = Rect2(
		atlas_coords.x * TILE_SIZE,
		atlas_coords.y * TILE_SIZE,
		TILE_SIZE,
		TILE_SIZE
	)
	return atlas

func _get_item_name(item: Variant) -> String:
	if item == null:
		return "Unknown"
	if "name" in item:
		return item.name
	return "Unknown"

func _get_item_slot(item: Variant) -> int:
	if item == null:
		return -1
	if "tval" in item:
		return Constants.get_slot_for_tval(item.tval)
	return -1

func _get_slot_key(slot_id: int) -> String:
	match slot_id:
		Constants.EquipSlot.WEAPON: return "weapon"
		Constants.EquipSlot.OFF_HAND: return "off_hand"
		Constants.EquipSlot.BOW: return "bow"
		Constants.EquipSlot.QUIVER: return "quiver"
		Constants.EquipSlot.HEAD: return "head"
		Constants.EquipSlot.BODY: return "armor"
		Constants.EquipSlot.CLOAK: return "cloak"
		Constants.EquipSlot.HANDS: return "hands"
		Constants.EquipSlot.FEET: return "feet"
		Constants.EquipSlot.NECK: return "amulet"
		Constants.EquipSlot.RING_L: return "ring_left"
		Constants.EquipSlot.RING_R: return "ring_right"
		Constants.EquipSlot.LIGHT: return "light"
	return ""

var _inv_button_group: ButtonGroup = null

func _get_inventory_button_group() -> ButtonGroup:
	if not _inv_button_group:
		_inv_button_group = ButtonGroup.new()
	return _inv_button_group

func _create_slot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()

	# Quick equip with 'e'
	if event.is_action_pressed("equip") and selected_item != null:
		var item_slot: int = _get_item_slot(selected_item)
		if item_slot >= 0:
			_try_equip_item(selected_item, item_slot)
		get_viewport().set_input_as_handled()

	# Drop with 'd'
	if event.is_action_pressed("drop") and selected_item != null:
		if player.drop_item(selected_item):
			item_dropped.emit(selected_item)
			selected_item = null
			selected_slot_index = -1
			_refresh_inventory()
		get_viewport().set_input_as_handled()
