extends Node2D
class_name DamageFloater
## A floating text indicator that rises and fades.
## Used for damage numbers, healing, status effects, and other combat feedback.

@onready var label: Label = $Label

var velocity: Vector2 = Vector2(0, -60)  # Pixels per second upward
var lifetime: float = 1.0
var elapsed: float = 0.0
var start_scale: Vector2 = Vector2(1.0, 1.0)

func _ready() -> void:
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

# Preset colors for different damage types
const COLOR_PHYSICAL := Color(1.0, 0.3, 0.3)  # Red
const COLOR_FIRE := Color(1.0, 0.5, 0.0)      # Orange
const COLOR_COLD := Color(0.3, 0.7, 1.0)      # Light blue
const COLOR_POISON := Color(0.3, 1.0, 0.3)    # Green
const COLOR_DARK := Color(0.6, 0.3, 0.8)      # Purple
const COLOR_HEAL := Color(0.3, 1.0, 0.5)      # Bright green
const COLOR_MANA := Color(0.3, 0.5, 1.0)      # Blue
const COLOR_MISS := Color(0.7, 0.7, 0.7)      # Gray
const COLOR_CRIT := Color(1.0, 1.0, 0.0)      # Yellow

static func get_color_for_type(damage_type: String) -> Color:
	match damage_type:
		"physical", "HURT": return COLOR_PHYSICAL
		"fire", "FIRE": return COLOR_FIRE
		"cold", "COLD": return COLOR_COLD
		"poison", "POISON": return COLOR_POISON
		"dark", "DARK": return COLOR_DARK
		"heal": return COLOR_HEAL
		"mana": return COLOR_MANA
		"miss": return COLOR_MISS
		"critical": return COLOR_CRIT
		_: return Color.WHITE
