extends Node
## Manages damage floaters and other visual feedback.
## Listens to EventBus signals and spawns appropriate floaters.

var floater_container: Node2D

func _ready() -> void:
	# Connect to combat events
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_healed.connect(_on_entity_healed)
	EventBus.attack_missed.connect(_on_attack_missed)
	EventBus.attack_blocked.connect(_on_attack_blocked)
	EventBus.status_applied.connect(_on_status_applied)

func set_container(container: Node2D) -> void:
	floater_container = container

func _on_entity_damaged(entity: Node, damage: int, damage_type: String, _source: Node) -> void:
	if not floater_container or not entity:
		return

	var pos := _get_entity_position(entity)
	var color := DamageFloater.get_color_for_type(damage_type)

	# Larger text for bigger hits
	var size := 16
	if damage >= 20:
		size = 24
	elif damage >= 10:
		size = 20

	DamageFloater.create_at(floater_container, pos, str(damage), color, size)

func _on_entity_healed(entity: Node, amount: int, _source: Node) -> void:
	if not floater_container or not entity:
		return

	var pos := _get_entity_position(entity)
	DamageFloater.create_at(floater_container, pos, "+" + str(amount), DamageFloater.COLOR_HEAL, 18)

func _on_attack_missed(_attacker: Node, defender: Node) -> void:
	if not floater_container or not defender:
		return

	var pos := _get_entity_position(defender)
	DamageFloater.create_at(floater_container, pos, "MISS", DamageFloater.COLOR_MISS, 14)

func _on_attack_blocked(_attacker: Node, defender: Node, damage_blocked: int) -> void:
	if not floater_container or not defender:
		return

	var pos := _get_entity_position(defender)
	DamageFloater.create_at(floater_container, pos, "BLOCK " + str(damage_blocked), Color(0.8, 0.8, 0.2), 14)

func _on_status_applied(entity: Node, status_name: String, _duration: int) -> void:
	if not floater_container or not entity:
		return

	var pos := _get_entity_position(entity)
	var color := Color(0.9, 0.7, 0.2)  # Gold for status effects
	DamageFloater.create_at(floater_container, pos + Vector2(0, -20), status_name, color, 12)

func _get_entity_position(entity: Node) -> Vector2:
	if entity.has_method("get_world_position"):
		return entity.get_world_position()
	elif entity is Node2D:
		return entity.global_position
	return Vector2.ZERO
