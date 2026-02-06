extends Control
class_name InventoryPanel
## Inventory management UI with 4x6 item grid and equipment paper doll.
## Keyboard navigation, sort/filter, rarity borders, confirm dialog for drops.

signal item_selected(item_data: Variant)
signal item_equipped(item_data: Variant, slot: int)
signal item_unequipped(item_data: Variant, slot_key: String)
signal item_dropped(item_data: Variant)
signal closed

const GRID_COLS: int = 4
const GRID_ROWS: int = 6
const SLOT_SIZE: Vector2 = Vector2(64, 64)
const TILE_SIZE: int = 64

# Sort modes
enum SortMode { DEFAULT, TYPE, WEIGHT, NAME }
const SORT_LABELS: Array[String] = ["Default", "Type", "Weight", "Name"]

# Filter modes
enum FilterMode { ALL, WEAPONS, ARMOR, CONSUMABLES }
const FILTER_LABELS: Array[String] = ["All", "Weapons", "Armor", "Consumables"]

var player: Player
var selected_item: Variant = null
var selected_slot_index: int = -1
var selected_equipment_slot: int = -1

# Keyboard navigation
var _focus_mode: int = 0  # 0 = inventory grid, 1 = equipment
var _focus_index: int = 0  # Current focused slot in inventory grid
var _equip_focus_index: int = 0  # Current focused slot in equipment

# Sort/filter state
var _sort_mode: SortMode = SortMode.DEFAULT
var _filter_mode: FilterMode = FilterMode.ALL
var _sorted_items: Array = []  # Filtered + sorted view of player inventory

# Confirm dialog
var _confirm_dialog: ConfirmDialog = null
var _pending_drop_item: Variant = null

# Shared tileset texture for item sprites
static var _tileset_texture: Texture2D = null
static var _magenta_shader: ShaderMaterial = null

# UI References
@onready var inventory_grid: GridContainer = $HSplitContainer/InventorySection/InventoryGrid
@onready var equipment_container: GridContainer = $HSplitContainer/EquipmentSection/EquipmentSlots
@onready var item_info: RichTextLabel = $HSplitContainer/InventorySection/ItemInfo
@onready var weight_label: Label = $HSplitContainer/InventorySection/WeightLabel

# Sort/filter labels
var _sort_label: Label = null
var _filter_label: Label = null

# Equipment slot buttons (mapped by Constants.EquipSlot)
var equipment_slots: Dictionary = {}
var inventory_slots: Array[Button] = []

# Ordered list of equipment slot IDs for keyboard nav
var _equip_slot_order: Array[int] = []

func _ready() -> void:
	if not _tileset_texture:
		_tileset_texture = load("res://assets/sprites/necromancer_dcss_tileset.png")
	if not _magenta_shader:
		_magenta_shader = load("res://assets/shaders/magenta_transparent.tres")

	_setup_sort_filter_bar()
	_setup_inventory_grid()
	_setup_equipment_slots()
	_setup_confirm_dialog()
	visible = false

func open(player_ref: Player) -> void:
	player = player_ref
	_focus_mode = 0
	_focus_index = 0
	_sort_mode = SortMode.DEFAULT
	_filter_mode = FilterMode.ALL
	PanelTransition.open_panel(self)
	_refresh_inventory()
	_refresh_equipment()
	_update_focus_ring()
	grab_focus()

func close() -> void:
	selected_item = null
	selected_slot_index = -1
	selected_equipment_slot = -1
	PanelTransition.close_panel(self, func(): closed.emit())

func _setup_sort_filter_bar() -> void:
	# Find or create a bar above the inventory grid
	var inv_section: Control = null
	if has_node("HSplitContainer/InventorySection"):
		inv_section = $HSplitContainer/InventorySection

	if not inv_section:
		return

	var bar := HBoxContainer.new()
	bar.name = "SortFilterBar"

	_sort_label = Label.new()
	_sort_label.text = "Sort: Default"
	ThemeColors.apply_body_font(_sort_label, ThemeColors.FONT_SIZE_BODY)
	bar.add_child(_sort_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.add_child(spacer)

	_filter_label = Label.new()
	_filter_label.text = "Filter: All"
	ThemeColors.apply_body_font(_filter_label, ThemeColors.FONT_SIZE_BODY)
	bar.add_child(_filter_label)

	# Insert bar before the grid
	var grid_idx: int = 0
	for i in range(inv_section.get_child_count()):
		if inv_section.get_child(i) == inventory_grid:
			grid_idx = i
			break
	inv_section.add_child(bar)
	inv_section.move_child(bar, grid_idx)

func _setup_inventory_grid() -> void:
	inventory_grid.columns = GRID_COLS

	for i in range(GRID_COLS * GRID_ROWS):
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.toggle_mode = true
		slot.button_group = _get_inventory_button_group()
		slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		slot.gui_input.connect(_on_slot_gui_input.bind(i))

		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
			slot.add_theme_stylebox_override("hover", ThemeColors.create_textured_slot("hover"))
			slot.add_theme_stylebox_override("pressed", ThemeColors.create_textured_slot("selected"))
		else:
			slot.add_theme_stylebox_override("normal", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_EMPTY))
			slot.add_theme_stylebox_override("hover", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_HOVER))
			slot.add_theme_stylebox_override("pressed", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_SELECTED, ThemeColors.BORDER_FOCUS))

		inventory_grid.add_child(slot)
		inventory_slots.append(slot)

func _setup_equipment_slots() -> void:
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

	var grid_layout: Array = [
		[-1, Constants.EquipSlot.HEAD, -1],
		[Constants.EquipSlot.NECK, Constants.EquipSlot.BODY, Constants.EquipSlot.CLOAK],
		[Constants.EquipSlot.WEAPON, -1, Constants.EquipSlot.OFF_HAND],
		[Constants.EquipSlot.HANDS, -1, Constants.EquipSlot.BOW],
		[Constants.EquipSlot.RING_L, Constants.EquipSlot.FEET, Constants.EquipSlot.RING_R],
		[Constants.EquipSlot.LIGHT, -1, Constants.EquipSlot.QUIVER],
	]

	equipment_container.columns = 3
	_equip_slot_order.clear()

	for row in grid_layout:
		for slot_id in row:
			if slot_id == -1:
				var spacer := Control.new()
				spacer.custom_minimum_size = SLOT_SIZE
				equipment_container.add_child(spacer)
			else:
				var slot := Button.new()
				slot.custom_minimum_size = SLOT_SIZE
				slot.tooltip_text = slot_names[slot_id]
				slot.pressed.connect(_on_equipment_slot_pressed.bind(slot_id))

				if ThemeColors.has_textures():
					slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
					slot.add_theme_stylebox_override("hover", ThemeColors.create_textured_slot("hover"))
				else:
					slot.add_theme_stylebox_override("normal", _create_slot_style(ThemeColors.SLOT_EQUIP_EMPTY))
					slot.add_theme_stylebox_override("hover", _create_slot_style(ThemeColors.SLOT_EQUIP_HOVER))

				equipment_container.add_child(slot)
				equipment_slots[slot_id] = slot
				_equip_slot_order.append(slot_id)

func _setup_confirm_dialog() -> void:
	_confirm_dialog = ConfirmDialog.new()
	_confirm_dialog.confirmed.connect(_on_drop_confirmed)
	_confirm_dialog.cancelled.connect(_on_drop_cancelled)
	add_child(_confirm_dialog)

# ============================================================================
# SORT / FILTER
# ============================================================================

func _cycle_sort() -> void:
	_sort_mode = (_sort_mode + 1) % SortMode.size() as SortMode
	_sort_label.text = "Sort: %s" % SORT_LABELS[_sort_mode]
	_refresh_inventory()

func _cycle_filter() -> void:
	_filter_mode = (_filter_mode + 1) % FilterMode.size() as FilterMode
	_filter_label.text = "Filter: %s" % FILTER_LABELS[_filter_mode]
	_refresh_inventory()

func _build_sorted_items() -> void:
	if not player:
		_sorted_items.clear()
		return

	# Start with all items
	var items: Array = []
	for item in player.inventory:
		items.append(item)

	# Apply filter
	if _filter_mode != FilterMode.ALL:
		var filtered: Array = []
		for item in items:
			if _passes_filter(item):
				filtered.append(item)
		items = filtered

	# Apply sort
	match _sort_mode:
		SortMode.TYPE:
			items.sort_custom(func(a, b):
				var ta: int = a.tval if "tval" in a else 0
				var tb: int = b.tval if "tval" in b else 0
				return ta < tb
			)
		SortMode.WEIGHT:
			items.sort_custom(func(a, b):
				var wa: float = a.weight if "weight" in a else 0.0
				var wb: float = b.weight if "weight" in b else 0.0
				return wa < wb
			)
		SortMode.NAME:
			items.sort_custom(func(a, b):
				return _get_item_name(a).naturalnocasecmp_to(_get_item_name(b)) < 0
			)

	_sorted_items = items

func _passes_filter(item: Variant) -> bool:
	if item == null:
		return false
	var tval: int = item.tval if "tval" in item else 0
	match _filter_mode:
		FilterMode.WEAPONS:
			# Swords, axes, polearms, bows, arrows
			return tval >= 20 and tval <= 24
		FilterMode.ARMOR:
			# Armor, shields, helms, gloves, boots, cloaks
			return tval >= 30 and tval <= 37
		FilterMode.CONSUMABLES:
			# Potions, herbs, scrolls, staves, horns
			return tval >= 70
	return true

# ============================================================================
# REFRESH
# ============================================================================

func _refresh_inventory() -> void:
	if not player:
		return

	_build_sorted_items()

	for i in range(inventory_slots.size()):
		var slot: Button = inventory_slots[i]
		if i < _sorted_items.size():
			var item = _sorted_items[i]
			slot.icon = _get_item_icon(item)
			slot.text = ""
			slot.tooltip_text = _get_item_name(item)
			# Apply rarity border color
			_apply_rarity_border(slot, item)
		else:
			slot.icon = null
			slot.text = ""
			slot.tooltip_text = "Empty"
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("normal", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_EMPTY))

	_update_weight_display()
	_update_focus_ring()

func _apply_rarity_border(slot: Button, item: Variant) -> void:
	var rarity_color: Color = ThemeColors.get_rarity_color(item)
	if rarity_color == ThemeColors.RARITY_NORMAL:
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("normal", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_EMPTY))
	else:
		slot.add_theme_stylebox_override("normal", ThemeColors.create_slot_stylebox(ThemeColors.IRON_SHADOW, rarity_color))

func _refresh_equipment() -> void:
	if not player:
		return

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
			slot.text = ""
			slot.tooltip_text = _get_item_name(item)
		else:
			slot.icon = null
			slot.text = ""

# ============================================================================
# KEYBOARD NAVIGATION
# ============================================================================

func _update_focus_ring() -> void:
	# Clear all focus indicators
	for i in range(inventory_slots.size()):
		var slot: Button = inventory_slots[i]
		if i < _sorted_items.size():
			_apply_rarity_border(slot, _sorted_items[i])
		else:
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
			else:
				slot.add_theme_stylebox_override("normal", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_EMPTY))

	for id in equipment_slots:
		var slot: Button = equipment_slots[id]
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("normal", _create_slot_style(ThemeColors.SLOT_EQUIP_EMPTY))

	# Apply gold focus ring to current focused slot
	if _focus_mode == 0:
		if _focus_index >= 0 and _focus_index < inventory_slots.size():
			var slot: Button = inventory_slots[_focus_index]
			if ThemeColors.has_textures():
				slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("selected"))
			else:
				slot.add_theme_stylebox_override("normal", ThemeColors.create_slot_stylebox(ThemeColors.SLOT_SELECTED, ThemeColors.BORDER_FOCUS))
	else:
		if _equip_focus_index >= 0 and _equip_focus_index < _equip_slot_order.size():
			var slot_id: int = _equip_slot_order[_equip_focus_index]
			if equipment_slots.has(slot_id):
				var slot: Button = equipment_slots[slot_id]
				if ThemeColors.has_textures():
					slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("selected"))
				else:
					slot.add_theme_stylebox_override("normal", _create_slot_style(ThemeColors.BORDER_FOCUS))

func _move_focus(dx: int, dy: int) -> void:
	if _focus_mode == 0:
		# Inventory grid navigation
		var col: int = _focus_index % GRID_COLS
		var row: int = _focus_index / GRID_COLS
		col = clampi(col + dx, 0, GRID_COLS - 1)
		row = clampi(row + dy, 0, GRID_ROWS - 1)
		_focus_index = row * GRID_COLS + col
	else:
		# Equipment grid navigation (navigate through ordered slots)
		var new_idx: int = clampi(_equip_focus_index + dx + dy, 0, _equip_slot_order.size() - 1)
		_equip_focus_index = new_idx

	_update_focus_ring()
	# Auto-select focused item for info display
	_select_focused_item()

func _select_focused_item() -> void:
	if _focus_mode == 0:
		if _focus_index < _sorted_items.size():
			selected_item = _sorted_items[_focus_index]
			selected_slot_index = _focus_index
			_update_item_info(selected_item)
		else:
			selected_item = null
			selected_slot_index = -1
			_update_item_info(null)
		selected_equipment_slot = -1
	else:
		selected_item = null
		selected_slot_index = -1
		if _equip_focus_index < _equip_slot_order.size():
			var slot_id: int = _equip_slot_order[_equip_focus_index]
			var slot_key: String = _get_slot_key(slot_id)
			if not slot_key.is_empty():
				var equipped_item = player.equipment.get(slot_key) if player else null
				if equipped_item != null:
					selected_equipment_slot = slot_id
					_update_item_info(equipped_item)
					return
		selected_equipment_slot = -1
		_update_item_info(null)

func _toggle_focus_mode() -> void:
	_focus_mode = 1 - _focus_mode
	_update_focus_ring()
	_select_focused_item()

func _activate_focused() -> void:
	if _focus_mode == 0:
		# In inventory: quick-equip
		if selected_item != null:
			var item_slot: int = _get_item_slot(selected_item)
			if item_slot >= 0:
				_try_equip_item(selected_item, item_slot)
	else:
		# In equipment: unequip
		if selected_equipment_slot >= 0:
			_try_unequip_slot(selected_equipment_slot)

# ============================================================================
# SLOT CALLBACKS
# ============================================================================

func _on_inventory_slot_pressed(index: int) -> void:
	selected_equipment_slot = -1
	_focus_mode = 0
	_focus_index = index

	if not player or index >= _sorted_items.size():
		selected_item = null
		selected_slot_index = -1
		_update_item_info(null)
		_update_focus_ring()
		return

	selected_item = _sorted_items[index]
	selected_slot_index = index
	_update_item_info(selected_item)
	_update_focus_ring()
	item_selected.emit(selected_item)

func _on_equipment_slot_pressed(slot_id: int) -> void:
	if not player:
		return

	if selected_item != null:
		var item_slot: int = _get_item_slot(selected_item)
		if item_slot == slot_id or (slot_id == Constants.EquipSlot.RING_R and item_slot == Constants.EquipSlot.RING_L):
			_try_equip_item(selected_item, slot_id)
		return

	selected_item = null
	selected_slot_index = -1
	_focus_mode = 1

	var slot_key: String = _get_slot_key(slot_id)
	if slot_key.is_empty():
		return

	var equipped_item = player.equipment.get(slot_key)
	if equipped_item != null:
		selected_equipment_slot = slot_id
		_update_item_info(equipped_item)
		# Update equip focus index
		for i in range(_equip_slot_order.size()):
			if _equip_slot_order[i] == slot_id:
				_equip_focus_index = i
				break
	else:
		selected_equipment_slot = -1
		_update_item_info(null)

	_update_focus_ring()

func _highlight_equipment_slot(slot_id: int) -> void:
	for id in equipment_slots:
		var slot: Button = equipment_slots[id]
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("empty"))
		else:
			slot.add_theme_stylebox_override("normal", _create_slot_style(ThemeColors.SLOT_EQUIP_EMPTY))

	if slot_id >= 0 and equipment_slots.has(slot_id):
		var slot: Button = equipment_slots[slot_id]
		if ThemeColors.has_textures():
			slot.add_theme_stylebox_override("normal", ThemeColors.create_textured_slot("selected"))
		else:
			slot.add_theme_stylebox_override("normal", _create_slot_style(ThemeColors.SLOT_SELECTED))

func _try_unequip_slot(slot_id: int) -> void:
	var slot_key: String = _get_slot_key(slot_id)
	if slot_key.is_empty():
		return

	var equipped_item = player.equipment.get(slot_key)
	if equipped_item == null:
		GameManager.log_message("Nothing equipped in that slot.", ThemeColors.MSG_SYSTEM)
		return

	if player.unequip_slot(slot_key):
		GameManager.log_message("Unequipped %s." % _get_item_name(equipped_item), ThemeColors.TEXT_PRIMARY)
		item_unequipped.emit(equipped_item, slot_key)
		selected_equipment_slot = -1
		_refresh_inventory()
		_refresh_equipment()
		_update_item_info(null)
	else:
		GameManager.log_message("Cannot unequip - inventory full.", ThemeColors.MSG_WARNING)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if index < _sorted_items.size():
				var item = _sorted_items[index]
				_show_item_context_menu(item, index)
		# Double-click quick-equip
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if index < _sorted_items.size():
				var item = _sorted_items[index]
				var item_slot: int = _get_item_slot(item)
				if item_slot >= 0:
					_try_equip_item(item, item_slot)

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
	var item_slot: int = _get_item_slot(item)
	if item_slot >= 0:
		var slot_key: String = _get_slot_key(item_slot)
		if not slot_key.is_empty() and player.equip_item(item, slot_key):
			_refresh_inventory()
			_refresh_equipment()

# ============================================================================
# DROP CONFIRMATION
# ============================================================================

func _request_drop() -> void:
	if selected_item == null:
		return
	_pending_drop_item = selected_item
	var item_name: String = _get_item_name(selected_item)
	_confirm_dialog.show_confirm("Drop %s?" % item_name)

func _on_drop_confirmed() -> void:
	if _pending_drop_item != null and player:
		if player.drop_item(_pending_drop_item):
			item_dropped.emit(_pending_drop_item)
			selected_item = null
			selected_slot_index = -1
			_refresh_inventory()
	_pending_drop_item = null

func _on_drop_cancelled() -> void:
	_pending_drop_item = null

# ============================================================================
# ITEM INFO
# ============================================================================

func _update_item_info(item: Variant) -> void:
	ThemeColors.apply_rich_body_font(item_info)
	if item == null:
		item_info.text = "Select an item to see details."
		return

	var name_str: String = _get_item_name(item)
	var rarity_color: Color = ThemeColors.get_rarity_color(item)
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
	item_info.text = "[color=#%s][b]%s[/b][/color]\n%s\n%s" % [
		rarity_color.to_html(false), name_str, stats_str, desc_str
	]

func _update_weight_display() -> void:
	if not player:
		return

	ThemeColors.apply_body_font(weight_label)

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
	if "display_char" in item and item.display_char != "":
		return item.display_char
	return "?"

func _get_item_icon(item: Variant) -> AtlasTexture:
	if item == null or not _tileset_texture:
		return null

	var item_index: int = -1
	if "index" in item:
		item_index = item.index
	else:
		return null

	var is_artifact: bool = item is DataManager.ArtifactData if item else false

	var atlas_coords: Vector2i
	if is_artifact:
		atlas_coords = TileMapper.get_artifact_coords(item_index)
	else:
		atlas_coords = TileMapper.get_item_coords(item_index)

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
	return GameManager.get_item_display_name(item)

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
	style.bg_color = ThemeColors.IRON_SHADOW
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = ThemeColors.IRON_HIGHLIGHT
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

# ============================================================================
# INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Block input if confirm dialog is showing
	if _confirm_dialog.visible:
		return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		# Arrow keys for navigation
		match event.keycode:
			KEY_UP:
				_move_focus(0, -1)
				get_viewport().set_input_as_handled()
				return
			KEY_DOWN:
				_move_focus(0, 1)
				get_viewport().set_input_as_handled()
				return
			KEY_LEFT:
				_move_focus(-1, 0)
				get_viewport().set_input_as_handled()
				return
			KEY_RIGHT:
				_move_focus(1, 0)
				get_viewport().set_input_as_handled()
				return
			KEY_TAB:
				_toggle_focus_mode()
				get_viewport().set_input_as_handled()
				return
			KEY_ENTER:
				_activate_focused()
				get_viewport().set_input_as_handled()
				return
			KEY_S:
				_cycle_sort()
				get_viewport().set_input_as_handled()
				return
			KEY_F:
				_cycle_filter()
				get_viewport().set_input_as_handled()
				return

	# Quick equip with 'e'
	if event.is_action_pressed("equip") and selected_item != null:
		var item_slot: int = _get_item_slot(selected_item)
		if item_slot >= 0:
			_try_equip_item(selected_item, item_slot)
		get_viewport().set_input_as_handled()

	# Drop with 'd' - now shows confirm dialog
	if event.is_action_pressed("drop") and selected_item != null:
		_request_drop()
		get_viewport().set_input_as_handled()

	# Unequip with 'r'
	if event.is_action_pressed("unequip") and selected_equipment_slot >= 0:
		_try_unequip_slot(selected_equipment_slot)
		get_viewport().set_input_as_handled()
