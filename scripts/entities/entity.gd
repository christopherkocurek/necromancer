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

# Visual
@export var sprite_index: int = 0
var sprite: Sprite2D

# State
var is_alive: bool = true
var status_effects: Dictionary = {}  # name -> {duration: int, data: Variant}

func _ready() -> void:
	_setup_sprite()
	_update_visual_position()

func _setup_sprite() -> void:
	sprite = $Sprite2D if has_node("Sprite2D") else null

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
	tween.tween_property(self, "position", end_pos, 0.15).set_ease(Tween.EASE_OUT)

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
	# Basic armor reduction
	var reduction := armor_class / 5
	return max(1, base_damage - reduction)

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
		effect.duration -= 1
		EventBus.status_tick.emit(self, status_name, effect.duration)

		if effect.duration <= 0:
			to_remove.append(status_name)

	for status_name in to_remove:
		remove_status(status_name)

# ============================================================================
# ATTACK
# ============================================================================

func attack_entity(target: Entity) -> void:
	# Roll to hit
	var hit_roll := randi_range(1, 20) + melee_bonus + (dexterity / 2)
	var target_evasion := target.evasion_bonus + (target.dexterity / 2)

	if hit_roll < target_evasion:
		EventBus.attack_missed.emit(self, target)
		return

	# Roll damage
	var damage := DataManager.roll_dice(damage_dice)
	damage += strength / 2

	# Check for critical hit (natural 20)
	if hit_roll >= 20:
		damage *= 2
		# Could emit a critical hit event here

	target.take_damage(damage, "physical", self)

# ============================================================================
# INFO
# ============================================================================

func get_stat_block() -> String:
	return "%s\nHP: %d/%d\nSTR: %d DEX: %d CON: %d GRA: %d\nAC: %d" % [
		entity_name, current_health, max_health,
		strength, dexterity, constitution, grace, armor_class
	]
