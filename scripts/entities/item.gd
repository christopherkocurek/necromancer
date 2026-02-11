extends Node2D
class_name Item
## Visual representation of an item on the dungeon floor.

signal picked_up(by: Entity)

# Data backing this item (ItemData or ArtifactData)
var item_data: DataManager.ItemData = null
var artifact_data: DataManager.ArtifactData = null

# Grid position (tile coordinates)
@export var grid_position: Vector2i = Vector2i.ZERO:
	set(value):
		grid_position = value
		_update_visual_position()

# Visual
var sprite: Sprite2D
var _pending_sprite_index: int = -1  # Store sprite index until ready

# Shared resources (loaded once)
static var _tileset_texture: Texture2D = null
static var _magenta_shader: ShaderMaterial = null

const DEFAULT_WORLD_ITEM_SCALE: float = 0.86
const WORLD_ITEM_SCALE_BY_TVAL: Dictionary = {
	# Ammo
	16: 0.72, 17: 0.72,
	# Jewelry/lights/lore objects
	2: 0.68, 39: 0.70, 40: 0.62, 45: 0.62, 46: 0.62,
	# Consumables and small interactables
	55: 0.58, 56: 0.58, 66: 0.60, 75: 0.50, 77: 0.50, 80: 0.58
}

func _ready() -> void:
	_setup_sprite()
	_update_visual_position()

func _setup_sprite() -> void:
	# Get or create sprite
	if has_node("Sprite2D"):
		sprite = $Sprite2D
	else:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	# Load shared resources if not loaded
	if not _tileset_texture:
		_tileset_texture = load("res://assets/sprites/necromancer_dcss_tileset.png")
	if not _magenta_shader:
		_magenta_shader = load("res://assets/shaders/magenta_transparent.tres")

	# Configure sprite
	sprite.texture = _tileset_texture
	sprite.region_enabled = true
	sprite.material = _magenta_shader
	_apply_world_item_scale()

	# Apply pending sprite if set before ready
	if _pending_sprite_index >= 0:
		_apply_sprite_region(_pending_sprite_index)

func _update_sprite_region(sprite_index: int) -> void:
	_pending_sprite_index = sprite_index
	if sprite:
		_apply_sprite_region(sprite_index)

func _apply_sprite_region(sprite_index: int) -> void:
	if not sprite or not TileMapper:
		return

	var atlas_coords: Vector2i
	if artifact_data:
		atlas_coords = TileMapper.get_artifact_coords(sprite_index)
	else:
		atlas_coords = TileMapper.get_object_coords(sprite_index)
	var tile_size := GameManager.TILE_SIZE
	sprite.region_rect = Rect2(
		atlas_coords.x * tile_size,
		atlas_coords.y * tile_size,
		tile_size,
		tile_size
	)

func _update_visual_position() -> void:
	position = Vector2(grid_position) * GameManager.TILE_SIZE

func _apply_world_item_scale() -> void:
	if not sprite:
		return
	var scale_factor: float = _resolve_world_item_scale()
	sprite.scale = Vector2.ONE * scale_factor

	# Keep smaller pickup icons sitting on the floor instead of floating in the tile center.
	var tile_size: float = float(GameManager.TILE_SIZE)
	var center: float = tile_size * 0.5
	var bottom_lock_offset: float = tile_size * (1.0 - scale_factor) * 0.5
	sprite.position = Vector2(center, center + bottom_lock_offset)

func _resolve_world_item_scale() -> float:
	var tval: int = _get_item_tval()
	if WORLD_ITEM_SCALE_BY_TVAL.has(tval):
		return WORLD_ITEM_SCALE_BY_TVAL[tval]
	return DEFAULT_WORLD_ITEM_SCALE

func _get_item_tval() -> int:
	if artifact_data != null and "tval" in artifact_data:
		return int(artifact_data.tval)
	if item_data != null and "tval" in item_data:
		return int(item_data.tval)
	return -1

func initialize_from_item_data(data: DataManager.ItemData) -> void:
	if not data:
		return
	item_data = data
	# Use the item's index to select sprite from object tiles
	_update_sprite_region(data.index)
	_apply_world_item_scale()

func initialize_from_artifact_data(data: DataManager.ArtifactData) -> void:
	if not data:
		return
	artifact_data = data
	# Use the artifact's index to select sprite from object tiles
	_update_sprite_region(data.index)
	_apply_world_item_scale()

func get_display_name() -> String:
	if artifact_data:
		return artifact_data.name  # Artifacts are always identified
	elif item_data:
		return GameManager.get_item_display_name(item_data)
	return "Unknown Item"

func get_data() -> Variant:
	if artifact_data:
		return artifact_data
	return item_data

func pickup(entity: Entity) -> bool:
	picked_up.emit(entity)
	return true
