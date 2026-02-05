extends Node2D
class_name Entity
## Base class for all game entities (player, monsters, NPCs).
## Handles position, stats, movement, and combat.

signal moved(from: Vector2i, to: Vector2i)
signal damaged(amount: int, source: Entity)
signal died(killer: Entity)

# Grid position (tile coordinates)
@export var grid_position: Vector2i = Vector2i.ZERO:
	set(value):
		var old_pos := grid_position
		grid_position = value
		if old_pos != value:
			moved.emit(old_pos, value)
			_update_visual_position()

# Core stats
@export var entity_name: String = "Entity"
@export var max_health: int = 10
@export var current_health: int = 10
@export var strength: int = 0
@export var dexterity: int = 0
@export var constitution: int = 0
@export var grace: int = 0
@export var armor_class: int = 0
@export var speed: int = 2  # Actions per round

# Combat stats
@export var melee_bonus: int = 0
@export var evasion_bonus: int = 0
@export var damage_dice: String = "1d4"

# Protection dice (replaces flat armor_class reduction)
var protection_dice: int = 0   # Number of dice (pd)
var protection_sides: int = 0  # Sides per die (ps)

# Energy system
var energy: int = 0

# Visual
@export var sprite_index: int = 0  # Monster/entity ID for tile lookup
var sprite: Sprite2D
var _pending_atlas_coords: Vector2i = Vector2i(-1, -1)  # Coords to apply after sprite creation

# Shared resources (loaded once)
static var _tileset_texture: Texture2D = null
static var _magenta_shader: ShaderMaterial = null

# State
var is_alive: bool = true
var status_effects: Dictionary = {}  # name -> {duration: int, data: Variant}

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
		_tileset_texture = load("res://assets/sprites/64x64_necromancer.png")
	if not _magenta_shader:
		_magenta_shader = load("res://assets/shaders/magenta_transparent.tres")

	# Configure sprite
	sprite.texture = _tileset_texture
	sprite.region_enabled = true
	sprite.material = _magenta_shader

	# Apply pending atlas coords if set, otherwise use default
	if _pending_atlas_coords != Vector2i(-1, -1):
		_apply_atlas_coords(_pending_atlas_coords)
	else:
		_update_sprite_region()

func _update_sprite_region() -> void:
	if not sprite or not TileMapper:
		return

	var atlas_coords := TileMapper.get_monster_coords(sprite_index)
	var tile_size := GameManager.TILE_SIZE
	sprite.region_rect = Rect2(
		atlas_coords.x * tile_size,
		atlas_coords.y * tile_size,
		tile_size,
		tile_size
	)

func set_sprite_from_monster_id(monster_id: int) -> void:
	sprite_index = monster_id
	if sprite:
		_update_sprite_region()
	# If sprite doesn't exist yet, _update_sprite_region will be called in _setup_sprite

func set_sprite_from_atlas_coords(atlas_coords: Vector2i) -> void:
	_pending_atlas_coords = atlas_coords
	if sprite:
		_apply_atlas_coords(atlas_coords)
	# If sprite doesn't exist yet, coords will be applied in _setup_sprite

func _apply_atlas_coords(atlas_coords: Vector2i) -> void:
	if not sprite:
		return
	var tile_size := GameManager.TILE_SIZE
	sprite.region_rect = Rect2(
		atlas_coords.x * tile_size,
		atlas_coords.y * tile_size,
		tile_size,
		tile_size
	)

func _update_visual_position() -> void:
	position = Vector2(grid_position) * GameManager.TILE_SIZE

func get_world_position() -> Vector2:
	return position + Vector2(GameManager.TILE_SIZE / 2, GameManager.TILE_SIZE / 2)

# ============================================================================
# MOVEMENT
# ============================================================================

func try_move(direction: Vector2i) -> bool:
	var target_pos := grid_position + direction
	if can_move_to(target_pos):
		move_to(target_pos)
		return true
	return false

func can_move_to(target: Vector2i) -> bool:
	# Override in subclass to check terrain, entities, etc.
	return true

func move_to(target: Vector2i, animate: bool = true) -> void:
	var old_pos := grid_position
	grid_position = target

	if animate:
		_animate_move(old_pos, target)

	EventBus.entity_moved.emit(self, old_pos, target)

func teleport_to(target: Vector2i) -> void:
	var old_pos := grid_position
	grid_position = target
	EventBus.entity_teleported.emit(self, old_pos, target)

func _animate_move(from: Vector2i, to: Vector2i) -> void:
	var start_pos := Vector2(from) * GameManager.TILE_SIZE
	var end_pos := Vector2(to) * GameManager.TILE_SIZE
	position = start_pos

	var tween := create_tween()
	# DO NOT EDIT: Movement tween for smooth tile transitions
	tween.tween_property(self, "position", end_pos, 0.01).set_ease(Tween.EASE_OUT)

# ============================================================================
# COMBAT
# ============================================================================

func take_damage(amount: int, damage_type: String = "physical", source: Entity = null) -> void:
	if not is_alive:
		return

	var actual_damage := _calculate_damage_reduction(amount, damage_type)
	current_health -= actual_damage

	EventBus.entity_damaged.emit(self, actual_damage, damage_type, source)
	damaged.emit(actual_damage, source)

	# Flash red on damage
	_flash_damage()

	if current_health <= 0:
		die(source)

func _calculate_damage_reduction(base_damage: int, _damage_type: String) -> int:
	# Roll protection dice for damage reduction (Sil-Q system)
	var prot: int = roll_protection()
	var final_damage: int = max(0, base_damage - prot)
	if protection_dice > 0 and prot > 0:
		# Show player-friendly message when armor absorbs damage
		if self is Player:
			GameManager.log_message("Your armor absorbs %d damage (rolled %dd%d)." % [
				prot, protection_dice, protection_sides
			], Color.LIGHT_BLUE)
		else:
			GameManager.log_message("%s's armor absorbs %d damage." % [
				entity_name, prot
			], Color.GRAY)
	return final_damage

func roll_protection(_damage_type: int = 1) -> int:
	# Roll protection dice for damage reduction
	if protection_dice <= 0 or protection_sides <= 0:
		return 0
	var total: int = 0
	for i in range(protection_dice):
		total += randi_range(1, protection_sides)
	return total

func _flash_damage() -> void:
	if sprite:
		var original_modulate := sprite.modulate
		sprite.modulate = Color(1.5, 0.5, 0.5)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func heal(amount: int, source: Entity = null) -> void:
	var old_health := current_health
	current_health = min(current_health + amount, max_health)
	var actual_heal := current_health - old_health

	if actual_heal > 0:
		EventBus.entity_healed.emit(self, actual_heal, source)

func die(killer: Entity = null) -> void:
	is_alive = false
	EventBus.entity_died.emit(self, killer)
	died.emit(killer)
	_play_death_animation()

func _play_death_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

# ============================================================================
# STATUS EFFECTS
# ============================================================================

func apply_status(status_name: String, duration: int, data: Variant = null) -> void:
	status_effects[status_name] = {"duration": duration, "data": data}
	EventBus.status_applied.emit(self, status_name, duration)

func remove_status(status_name: String) -> void:
	if status_effects.has(status_name):
		status_effects.erase(status_name)
		EventBus.status_removed.emit(self, status_name)

func has_status(status_name: String) -> bool:
	return status_effects.has(status_name)

func tick_status_effects() -> void:
	var to_remove: Array[String] = []

	for status_name in status_effects:
		var effect: Dictionary = status_effects[status_name]

		# Process effect each tick
		_process_status_effect(status_name, effect)

		effect.duration -= 1
		EventBus.status_tick.emit(self, status_name, effect.duration)

		if effect.duration <= 0:
			to_remove.append(status_name)

	for status_name in to_remove:
		remove_status(status_name)

func _process_status_effect(status_name: String, effect: Dictionary) -> void:
	var power: int = effect.get("data", 1) if effect.has("data") and effect.data != null else 1
	match status_name:
		"poison":
			take_damage(power, "poison", null)
		"regeneration":
			heal(power, null)
		"burning":
			take_damage(power * 2, "fire", null)
		"bleeding":
			take_damage(power, "physical", null)
		_:
			pass  # Other effects handled elsewhere

# ============================================================================
# ATTACK
# ============================================================================

func attack_entity(target: Entity) -> void:
	# Sil-Q Opposed Roll Combat: (1d20 + attack) vs (1d20 + evasion)
	var attack_score: int = randi_range(1, 20) + melee_bonus
	var evasion_score: int = randi_range(1, 20) + target.evasion_bonus
	var hit_result: int = attack_score - evasion_score

	if hit_result < 0:
		EventBus.attack_missed.emit(self, target)
		GameManager.log_message("%s misses %s (%d vs %d)" % [
			entity_name, target.entity_name, attack_score, evasion_score
		], Color.GRAY)
		return

	# Base damage from weapon dice
	var weapon_weight: int = _get_weapon_weight()
	var damage: int = DataManager.roll_dice(damage_dice)

	# STR damage bonus capped by weapon weight
	# Heavier weapons can utilize more STR, lighter weapons cap the bonus
	var str_bonus: int = strength / 2
	var weight_cap: int = weapon_weight / 10
	var actual_str_bonus: int = mini(str_bonus, weight_cap)
	damage += actual_str_bonus

	# Critical hit calculation: (hit_result × 10 + 4) / (70 + weapon_weight)
	# Heavier weapons = harder crits but more damage potential from STR
	var crit_dice: int = (hit_result * 10 + 4) / (70 + weapon_weight)

	# Apply crit bonus dice
	var crit_damage: int = 0
	for i in range(crit_dice):
		crit_damage += DataManager.roll_dice(damage_dice)
	damage += crit_damage

	# Log the hit
	if crit_dice > 0:
		GameManager.log_message("%s CRITS %s! (%d vs %d, +%d dice = %d dmg)" % [
			entity_name, target.entity_name, attack_score, evasion_score, crit_dice, damage
		], Color.ORANGE)
	else:
		GameManager.log_message("%s hits %s (%d vs %d = %d dmg)" % [
			entity_name, target.entity_name, attack_score, evasion_score, damage
		], Color.WHITE)

	target.take_damage(damage, "physical", self)

func _get_weapon_weight() -> int:
	# Override in Player to get actual weapon weight
	# Default weight for monsters/unarmed
	return 50

# ============================================================================
# ENERGY SYSTEM
# ============================================================================

func get_energy_gain() -> int:
	# Get energy gain based on speed (uses Constants.ENERGY_TABLE)
	var speed_index: int = clampi(speed, 0, Constants.ENERGY_TABLE.size() - 1)
	return Constants.ENERGY_TABLE[speed_index]

func can_act() -> bool:
	return energy >= Constants.ACTION_COST and is_alive

func consume_energy(amount: int = Constants.ACTION_COST) -> void:
	energy -= amount

func grant_energy() -> void:
	energy += get_energy_gain()

# ============================================================================
# INFO
# ============================================================================

func get_stat_block() -> String:
	return "%s\nHP: %d/%d\nSTR: %d DEX: %d CON: %d GRA: %d\nAC: %d" % [
		entity_name, current_health, max_health,
		strength, dexterity, constitution, grace, armor_class
	]
