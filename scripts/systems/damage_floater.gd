extends Node2D
class_name DamageFloater
## A floating text indicator that rises and fades.
## Used for damage numbers, healing, status effects, and other combat feedback.

var label: Label

var velocity: Vector2 = Vector2(0, -60)  # Pixels per second upward
var lifetime: float = 1.0
var elapsed: float = 0.0
var start_scale: Vector2 = Vector2(1.0, 1.0)

# Pending setup values (set before _ready)
var _pending_text: String = ""
var _pending_color: Color = Color.WHITE
var _pending_size: int = 16

func _ready() -> void:
	label = $Label

	# Apply pending setup
	if label and _pending_text != "":
		label.text = _pending_text
		label.add_theme_color_override("font_color", _pending_color)
		label.add_theme_font_size_override("font_size", _pending_size)

	# Start with a slight pop animation
	scale = start_scale * 1.2
	var tween := create_tween()
	tween.tween_property(self, "scale", start_scale, 0.1).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	elapsed += delta

	# Move upward with slight deceleration
	position += velocity * delta
	velocity *= 0.98

	# Fade out in the last 30% of lifetime
	var fade_start := lifetime * 0.7
	if elapsed > fade_start:
		var fade_progress := (elapsed - fade_start) / (lifetime * 0.3)
		modulate.a = 1.0 - fade_progress

	# Remove when done
	if elapsed >= lifetime:
		queue_free()

func setup(text: String, color: Color, size: int = 16, duration: float = 1.0) -> void:
	lifetime = duration
	_pending_text = text
	_pending_color = color
	_pending_size = size

	# Apply immediately if label exists (called after _ready)
	if label:
		label.text = text
		label.add_theme_color_override("font_color", color)
		label.add_theme_font_size_override("font_size", size)

static func create_at(parent: Node, world_position: Vector2, text: String, color: Color, size: int = 16) -> DamageFloater:
	var floater_scene := preload("res://scenes/effects/damage_floater.tscn")
	var floater: DamageFloater = floater_scene.instantiate()
	floater.position = world_position + Vector2(randf_range(-10, 10), 0)  # Slight random offset
	floater.setup(text, color, size)
	parent.add_child(floater)
	return floater

# Preset colors for different damage types (delegates to ThemeColors)
const COLOR_PHYSICAL := ThemeColors.DMG_PHYSICAL
const COLOR_FIRE := ThemeColors.DMG_FIRE
const COLOR_COLD := ThemeColors.DMG_COLD
const COLOR_POISON := ThemeColors.DMG_POISON
const COLOR_DARK := ThemeColors.DMG_DARK
const COLOR_HEAL := ThemeColors.DMG_HEAL
const COLOR_MANA := ThemeColors.DMG_MANA
const COLOR_MISS := ThemeColors.DMG_MISS
const COLOR_CRIT := ThemeColors.DMG_CRIT

static func get_color_for_type(damage_type: String) -> Color:
	return ThemeColors.get_damage_color(damage_type)
