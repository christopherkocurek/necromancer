extends Node2D
class_name EntityHealthBar
## Small health bar displayed above monsters, gated by MonsterMemory knowledge tier.
## Tier 0-1: Hidden | Tier 2: Bar only | Tier 3+: Bar + numbers

const BAR_WIDTH: int = 48
const BAR_HEIGHT: int = 4
const BAR_OFFSET_Y: int = -8  # Above entity sprite
const BG_COLOR := Color(0.08, 0.08, 0.12, 0.8)
const BORDER_COLOR := Color(0.3, 0.3, 0.35, 0.6)

var entity: Entity = null
var _show_numbers: bool = false
var _label: Label = null

func _ready() -> void:
	z_index = 50
	position.y = BAR_OFFSET_Y

func setup(target_entity: Entity) -> void:
	entity = target_entity

func update_display(knowledge_tier: int) -> void:
	if not entity or not entity.is_alive:
		visible = false
		return

	# Tier gating
	if knowledge_tier < 2:
		visible = false
		return

	visible = true
	_show_numbers = knowledge_tier >= 3

	# Create/update number label
	if _show_numbers and not _label:
		_label = Label.new()
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 9)
		_label.add_theme_color_override("font_color", ThemeColors.TEXT_SECONDARY)
		_label.position = Vector2(-BAR_WIDTH / 2.0, -14)
		_label.size = Vector2(BAR_WIDTH, 12)
		add_child(_label)

	if _label:
		_label.visible = _show_numbers
		if _show_numbers:
			_label.text = "%d/%d" % [entity.current_health, entity.max_health]

	queue_redraw()

func _draw() -> void:
	if not entity or not entity.is_alive or not visible:
		return

	var health_pct: float = clampf(float(entity.current_health) / float(maxi(entity.max_health, 1)), 0.0, 1.0)
	var bar_x: float = -BAR_WIDTH / 2.0
	var bar_y: float = 0.0

	# Background
	draw_rect(Rect2(bar_x - 1, bar_y - 1, BAR_WIDTH + 2, BAR_HEIGHT + 2), BORDER_COLOR)
	draw_rect(Rect2(bar_x, bar_y, BAR_WIDTH, BAR_HEIGHT), BG_COLOR)

	# Health fill
	var fill_width: float = BAR_WIDTH * health_pct
	var fill_color: Color = ThemeColors.get_health_color(health_pct)
	draw_rect(Rect2(bar_x, bar_y, fill_width, BAR_HEIGHT), fill_color)
