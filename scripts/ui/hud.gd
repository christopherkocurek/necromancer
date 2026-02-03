extends CanvasLayer
class_name HUD
## Heads-up display showing player stats, messages, and status.

@onready var health_bar: ProgressBar = $TopPanel/HealthBar
@onready var health_label: Label = $TopPanel/HealthLabel
@onready var depth_label: Label = $TopPanel/DepthLabel
@onready var turn_label: Label = $TopPanel/TurnLabel
@onready var message_log: RichTextLabel = $BottomPanel/MessageLog
@onready var status_container: HBoxContainer = $TopPanel/StatusContainer

const MAX_MESSAGES := 50
var messages: Array[String] = []

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
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

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
	if entity is Player:
		var source_name := source.entity_name if source else "something"
		var msg := "The %s hits you for %d %s damage." % [source_name, damage, damage_type]
		_on_message_logged(msg, Color.RED)
		update_player_stats(entity as Player)
	elif source is Player:
		var msg := "You hit the %s for %d damage." % [entity.entity_name, damage]
		_on_message_logged(msg, Color.WHITE)

func _on_entity_healed(entity: Entity, amount: int, _source: Entity) -> void:
	if entity is Player:
		var msg := "You recover %d health." % amount
		_on_message_logged(msg, Color.GREEN)
		update_player_stats(entity as Player)

func _on_level_entered(depth: int) -> void:
	depth_label.text = "Depth: %d" % depth
	_on_message_logged("You descend to depth %d." % depth, Color.CYAN)

func _on_round_completed(round_number: int) -> void:
	turn_label.text = "Turn: %d" % round_number

func _on_status_applied(entity: Entity, status_name: String, duration: int) -> void:
	if entity is Player:
		_on_message_logged("You are afflicted with %s (%d turns)." % [status_name, duration], Color.ORANGE)
		_update_status_icons(entity as Player)

func _on_status_removed(entity: Entity, status_name: String) -> void:
	if entity is Player:
		_on_message_logged("The %s effect wears off." % status_name, Color.CYAN)
		_update_status_icons(entity as Player)

func _update_status_icons(player: Player) -> void:
	# Clear existing icons
	for child in status_container.get_children():
		child.queue_free()

	# Add icons for active status effects
	for status_name in player.status_effects:
		var icon := Label.new()
		icon.text = _get_status_abbreviation(status_name)
		icon.add_theme_color_override("font_color", _get_status_color(status_name))
		icon.tooltip_text = status_name
		status_container.add_child(icon)

func _get_status_abbreviation(status_name: String) -> String:
	match status_name.to_lower():
		"poisoned": return "[PSN]"
		"confused": return "[CNF]"
		"blind": return "[BLD]"
		"afraid": return "[AFR]"
		"slowed": return "[SLW]"
		"hasted": return "[HST]"
		"invisible": return "[INV]"
		"entranced": return "[ENT]"
		_: return "[%s]" % status_name.substr(0, 3).to_upper()

func _get_status_color(status_name: String) -> Color:
	match status_name.to_lower():
		"poisoned": return Color.GREEN
		"confused": return Color.PURPLE
		"blind": return Color.GRAY
		"afraid": return Color.YELLOW
		"slowed": return Color.CYAN
		"hasted": return Color.ORANGE
		"invisible": return Color.WHITE
		"entranced": return Color.MAGENTA
		_: return Color.WHITE
