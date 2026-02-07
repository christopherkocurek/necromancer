extends Camera2D
## Screen shake and camera effects system. Replaces the basic Camera2D on the player node.
## Supports shake, zoom pulse, and brief game pause for impactful moments.

var _shake_strength: float = 0.0
var _shake_decay: float = 8.0
var _shake_enabled: bool = true

# Zoom pulse state
var _base_zoom: Vector2 = Vector2(2.0, 2.0)
var _zoom_pulsing: bool = false

func _ready() -> void:
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.critical_hit.connect(_on_critical_hit)

func _process(delta: float) -> void:
	if _shake_strength > 0.01:
		offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
		_shake_strength = lerpf(_shake_strength, 0.0, _shake_decay * delta)
	else:
		_shake_strength = 0.0
		offset = Vector2.ZERO

func shake(strength: float, decay: float = 8.0) -> void:
	if not _shake_enabled:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_decay = decay

## Brief zoom pulse effect (zoom in slightly, then back to normal).
## Used for ability activations and impactful moments.
func zoom_pulse(target_zoom_factor: float = 2.05, duration: float = 0.3) -> void:
	if _zoom_pulsing:
		return
	_zoom_pulsing = true
	_base_zoom = zoom
	var target: Vector2 = Vector2(target_zoom_factor, target_zoom_factor)
	var t := create_tween()
	t.tween_property(self, "zoom", target, duration * 0.3).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "zoom", _base_zoom, duration * 0.7).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): _zoom_pulsing = false)

## Brief game pause for dramatic impact (freezes the scene tree briefly).
## Used for significant kills (boss deaths, critical moments).
func impact_pause(pause_duration: float = 0.1) -> void:
	get_tree().paused = true
	var timer := get_tree().create_timer(pause_duration, true, false, true)
	timer.timeout.connect(func(): get_tree().paused = false)

func _on_entity_damaged(entity: Node, damage: int, _damage_type: String, _source: Node) -> void:
	if entity is Player:
		shake(clampf(damage / 20.0, 0.5, 6.0), 8.0)

func _on_entity_died(entity: Node, _killer: Node) -> void:
	if not entity is Player:
		# Enhanced death effects for bosses/uniques
		if entity is Monster:
			var mon: Monster = entity as Monster
			if mon.is_unique or mon.is_dragon:
				shake(5.0, 5.0)
				impact_pause(0.1)
				return
		shake(2.0, 6.0)

func _on_critical_hit(_attacker: Node, _target: Node, _damage: int) -> void:
	shake(3.0, 7.0)

func _on_level_entered(_depth: int) -> void:
	shake(3.0, 4.0)
