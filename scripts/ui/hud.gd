extends CanvasLayer
class_name HUD
## Heads-up display showing player stats, messages, and status.

@onready var health_bar: ProgressBar = $TopPanel/HealthBar
@onready var health_label: Label = $TopPanel/HealthLabel
@onready var depth_label: Label = $TopPanel/DepthLabel
@onready var turn_label: Label = $TopPanel/TurnLabel
@onready var message_log: RichTextLabel = $BottomPanel/MessageLog
@onready var status_container: HBoxContainer = $TopPanel/StatusContainer

const MAX_MESSAGES := 200
var messages: Array[String] = []
var _turn_count: int = 0

# Dangerous statuses that pulse in the HUD
const DANGER_STATUSES := ["poisoned", "burning", "stunned", "confused"]

func _ready() -> void:
	EventBus.message_logged.connect(_on_message_logged)
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_healed.connect(_on_entity_healed)
	EventBus.level_entered.connect(_on_level_entered)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_removed.connect(_on_status_removed)

func update_player_stats(player: Player) -> void:
	if not player:
		return

	# Update health bar
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health
	health_label.text = "%d / %d" % [player.current_health, player.max_health]

	# Color health bar based on percentage
	var health_percent := float(player.current_health) / float(player.max_health)
	health_bar.modulate = ThemeColors.get_health_color(health_percent)

func _on_message_logged(text: String, color: Color) -> void:
	var colored_text := "[color=#%s]%s[/color]" % [color.to_html(false), text]
	messages.append(colored_text)

	# Trim old messages
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()

	# Update display
	message_log.clear()
	for msg in messages:
		message_log.append_text(msg + "\n")

	# Scroll to bottom
	message_log.scroll_to_line(message_log.get_line_count())

func _on_entity_damaged(entity: Entity, damage: int, damage_type: String, source: Entity) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		var source_name := source.entity_name if is_instance_valid(source) else "something"
		var msg := "The %s hits you for %d %s damage." % [source_name, damage, damage_type]
		_on_message_logged(msg, ThemeColors.DMG_PHYSICAL)
		update_player_stats(entity as Player)
	elif is_instance_valid(source) and source is Player:
		var msg := "You hit the %s for %d damage." % [entity.entity_name, damage]
		_on_message_logged(msg, ThemeColors.COMBAT_HIT)

func _on_entity_healed(entity: Entity, amount: int, _source: Entity) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		var msg := "You recover %d health." % amount
		_on_message_logged(msg, ThemeColors.MSG_HEAL)
		update_player_stats(entity as Player)

func _on_level_entered(depth: int) -> void:
	depth_label.text = "Depth: %d" % depth
	_on_message_logged("You descend to depth %d." % depth, ThemeColors.MSG_INFO)

func _on_round_completed(round_number: int) -> void:
	turn_label.text = "Turn: %d" % round_number
	_turn_count = round_number

func _on_status_applied(entity: Entity, status_name: String, duration: int) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		_on_message_logged("You are afflicted with %s (%d turns)." % [status_name, duration], ThemeColors.MSG_WARNING)
		_update_status_icons(entity as Player)

func _on_status_removed(entity: Entity, status_name: String) -> void:
	if not is_instance_valid(entity):
		return
	if entity is Player:
		_on_message_logged("The %s effect wears off." % status_name, ThemeColors.MSG_INFO)
		_update_status_icons(entity as Player)

func _update_status_icons(player: Player) -> void:
	# Clear existing icons
	for child in status_container.get_children():
		child.queue_free()

	# Use new StatusEffects system for active effects
	if player.status_fx:
		for effect_id: StringName in player.status_fx.get_active_effects():
			var duration: int = player.status_fx.get_duration(effect_id)
			var status_name := String(effect_id)
			var status_color := ThemeColors.get_status_color(status_name)

			# Create pill-style status badge
			var badge := PanelContainer.new()
			badge.add_theme_stylebox_override("panel", ThemeColors.create_status_pill(status_color))

			var icon := Label.new()
			icon.text = _get_status_abbreviation(status_name)
			icon.add_theme_color_override("font_color", status_color)
			icon.add_theme_font_size_override("font_size", ThemeColors.FONT_SIZE_HINT)
			icon.tooltip_text = "%s (%d turns)" % [status_name.capitalize(), duration]
			badge.add_child(icon)
			status_container.add_child(badge)

			# Pulse dangerous statuses
			if status_name.to_lower() in DANGER_STATUSES:
				_pulse_node(badge)

func _pulse_node(node: Control) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(node, "modulate:a", 0.5, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)

func _get_status_abbreviation(status_name: String) -> String:
	match status_name.to_lower():
		"poisoned": return "PSN"
		"confused": return "CNF"
		"blind": return "BLD"
		"afraid": return "AFR"
		"slow": return "SLW"
		"fast": return "HST"
		"entranced": return "ENT"
		"stunned": return "STN"
		"cut": return "CUT"
		"burning": return "BRN"
		"rage": return "RGE"
		"darkened": return "DRK"
		"image": return "HAL"
		_: return status_name.substr(0, 3).to_upper()
