extends Camera2D
## Screen shake system. Replaces the basic Camera2D on the player node.

var _shake_strength: float = 0.0
var _shake_decay: float = 8.0
var _shake_enabled: bool = true

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

func _on_entity_damaged(entity: Node, damage: int, _damage_type: String, _source: Node) -> void:
	if entity is Player:
		shake(clampf(damage / 20.0, 0.5, 6.0), 8.0)

func _on_entity_died(entity: Node, _killer: Node) -> void:
	if not entity is Player:
		shake(2.0, 6.0)

func _on_critical_hit(_attacker: Node, _target: Node, _damage: int) -> void:
	shake(3.0, 7.0)

func _on_level_entered(_depth: int) -> void:
	shake(3.0, 4.0)
