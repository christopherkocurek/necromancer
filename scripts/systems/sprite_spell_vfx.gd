extends RefCounted
class_name SpriteSpellVFX
## CC-BY sprite-sheet spell animation playback helper.

const EFFECT_DEFS: Dictionary = {
	"flash": {
		"path": "res://assets/vfx/ccby_spell_animations/flash01.png",
		"frame_size": Vector2i(64, 64),
		"columns": 5,
		"rows": 2,
		"frames": 10,
		"fps": 22.0,
		"scale": 0.75,
		"additive": true,
	},
	"heal": {
		"path": "res://assets/vfx/ccby_spell_animations/flash_heal.png",
		"frame_size": Vector2i(160, 160),
		"columns": 9,
		"rows": 24,
		"frames": 72,
		"fps": 28.0,
		"scale": 0.42,
		"additive": true,
	},
	"sphere": {
		"path": "res://assets/vfx/ccby_spell_animations/sphere_blue.png",
		"frame_size": Vector2i(128, 128),
		"columns": 6,
		"rows": 5,
		"frames": 30,
		"fps": 24.0,
		"scale": 0.50,
		"additive": true,
	},
	"fireball": {
		"path": "res://assets/vfx/ccby_spell_animations/fireball_blue.png",
		"frame_size": Vector2i(256, 256),
		"columns": 8,
		"rows": 15,
		"frames": 60,
		"fps": 28.0,
		"scale": 0.30,
		"additive": true,
	},
	"wings": {
		"path": "res://assets/vfx/ccby_spell_animations/wings.png",
		"frame_size": Vector2i(256, 256),
		"columns": 9,
		"rows": 12,
		"frames": 54,
		"fps": 24.0,
		"scale": 0.30,
		"additive": true,
	},
	"arrows_green": {
		"path": "res://assets/vfx/ccby_spell_animations/arrows_green.png",
		"frame_size": Vector2i(128, 128),
		"columns": 8,
		"rows": 12,
		"frames": 96,
		"fps": 20.0,
		"scale": 0.50,
		"additive": true,
	},
	"arrows_yellow": {
		"path": "res://assets/vfx/ccby_spell_animations/arrows_yellow.png",
		"frame_size": Vector2i(128, 128),
		"columns": 8,
		"rows": 12,
		"frames": 96,
		"fps": 20.0,
		"scale": 0.50,
		"additive": true,
	},
	"flash02": {
		"path": "res://assets/vfx/ccby_spell_animations/flash02.png",
		"frame_size": Vector2i(64, 64),
		"columns": 5,
		"rows": 2,
		"frames": 10,
		"fps": 22.0,
		"scale": 0.75,
		"additive": true,
	},
	"flash03": {
		"path": "res://assets/vfx/ccby_spell_animations/flash03.png",
		"frame_size": Vector2i(64, 64),
		"columns": 5,
		"rows": 2,
		"frames": 10,
		"fps": 22.0,
		"scale": 0.75,
		"additive": true,
	},
	"flash04": {
		"path": "res://assets/vfx/ccby_spell_animations/flash04.png",
		"frame_size": Vector2i(64, 64),
		"columns": 5,
		"rows": 2,
		"frames": 10,
		"fps": 22.0,
		"scale": 0.75,
		"additive": true,
	},
	"flash_freeze": {
		"path": "res://assets/vfx/ccby_spell_animations/flash_freeze.png",
		"frame_size": Vector2i(256, 256),
		"columns": 16,
		"rows": 24,
		"frames": 120,
		"fps": 24.0,
		"scale": 0.30,
		"additive": true,
	},
	"sphere_purple": {
		"path": "res://assets/vfx/ccby_spell_animations/sphere_purple.png",
		"frame_size": Vector2i(128, 128),
		"columns": 6,
		"rows": 5,
		"frames": 30,
		"fps": 24.0,
		"scale": 0.50,
		"additive": true,
	},
	"sphere_yellow": {
		"path": "res://assets/vfx/ccby_spell_animations/sphere_yellow.png",
		"frame_size": Vector2i(128, 128),
		"columns": 6,
		"rows": 5,
		"frames": 30,
		"fps": 24.0,
		"scale": 0.50,
		"additive": true,
	},
	"fireball_blue": {
		"path": "res://assets/vfx/ccby_spell_animations/fireball_blue.png",
		"frame_size": Vector2i(256, 256),
		"columns": 8,
		"rows": 15,
		"frames": 60,
		"fps": 28.0,
		"scale": 0.30,
		"additive": true,
	},
	"fire_green": {
		"path": "res://assets/vfx/ccby_spell_animations/fire_green.png",
		"frame_size": Vector2i(96, 96),
		"columns": 7,
		"rows": 10,
		"frames": 70,
		"fps": 24.0,
		"scale": 0.50,
		"additive": true,
	},
	"fire_purple": {
		"path": "res://assets/vfx/ccby_spell_animations/fire_purple.png",
		"frame_size": Vector2i(96, 96),
		"columns": 7,
		"rows": 10,
		"frames": 70,
		"fps": 24.0,
		"scale": 0.50,
		"additive": true,
	},
	"fire_yellow": {
		"path": "res://assets/vfx/ccby_spell_animations/fire_yellow.png",
		"frame_size": Vector2i(96, 96),
		"columns": 7,
		"rows": 10,
		"frames": 70,
		"fps": 24.0,
		"scale": 0.50,
		"additive": true,
	},
	"smoke": {
		"path": "res://assets/vfx/ccby_spell_animations/smoke.png",
		"frame_size": Vector2i(256, 256),
		"columns": 16,
		"rows": 22,
		"frames": 120,
		"fps": 24.0,
		"scale": 0.30,
		"additive": true,
	},
	"smoke_glow": {
		"path": "res://assets/vfx/ccby_spell_animations/smoke_glow.png",
		"frame_size": Vector2i(256, 256),
		"columns": 16,
		"rows": 22,
		"frames": 96,
		"fps": 26.0,
		"scale": 0.30,
		"additive": true,
	},
	"skull_smoke_green": {
		"path": "res://assets/vfx/ccby_spell_animations/skull_smoke_green.png",
		"frame_size": Vector2i(192, 256),
		"columns": 19,
		"rows": 2,
		"frames": 38,
		"fps": 22.0,
		"scale": 0.36,
		"additive": true,
	},
	"skull_smoke_purple": {
		"path": "res://assets/vfx/ccby_spell_animations/skull_smoke_purple.png",
		"frame_size": Vector2i(192, 256),
		"columns": 19,
		"rows": 2,
		"frames": 38,
		"fps": 22.0,
		"scale": 0.36,
		"additive": true,
	},
	"cauterize": {
		"path": "res://assets/vfx/ccby_spell_animations/cauterize.png",
		"frame_size": Vector2i(256, 256),
		"columns": 12,
		"rows": 12,
		"frames": 80,
		"fps": 24.0,
		"scale": 0.32,
		"additive": true,
	},
	"feather": {
		"path": "res://assets/vfx/ccby_spell_animations/feather.png",
		"frame_size": Vector2i(128, 128),
		"columns": 1,
		"rows": 1,
		"frames": 1,
		"fps": 1.0,
		"scale": 0.9,
		"additive": true,
	},
}

static var _frames_cache: Dictionary = {}  # effect_key -> SpriteFrames

static func play(parent_node: Node, world_position: Vector2, effect_key: String, scale_override: float = -1.0) -> void:
	if parent_node == null or not is_instance_valid(parent_node):
		return
	if not EFFECT_DEFS.has(effect_key):
		return
	var def: Dictionary = EFFECT_DEFS[effect_key]
	var sprite_frames: SpriteFrames = _get_or_build_frames(effect_key, def)
	if sprite_frames == null:
		return

	var sprite := AnimatedSprite2D.new()
	sprite.name = "SpriteSpellVFX_%s" % effect_key
	sprite.sprite_frames = sprite_frames
	sprite.animation = "play"
	sprite.centered = true
	sprite.position = world_position
	sprite.z_index = 200
	sprite.speed_scale = 1.0

	var base_scale: float = float(def.get("scale", 1.0))
	if scale_override > 0.0:
		base_scale = scale_override
	sprite.scale = Vector2(base_scale, base_scale)

	if bool(def.get("additive", false)):
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = mat

	parent_node.add_child(sprite)
	sprite.play("play")
	sprite.animation_finished.connect(sprite.queue_free)

static func _get_or_build_frames(effect_key: String, def: Dictionary) -> SpriteFrames:
	if _frames_cache.has(effect_key):
		return _frames_cache[effect_key]

	var tex: Texture2D = load(str(def.get("path", "")))
	if tex == null:
		return null

	var frame_size: Vector2i = def.get("frame_size", Vector2i(64, 64))
	var columns: int = int(def.get("columns", 1))
	var rows: int = int(def.get("rows", 1))
	var max_frames: int = int(def.get("frames", columns * rows))
	var fps: float = float(def.get("fps", 20.0))

	var frames := SpriteFrames.new()
	frames.add_animation("play")
	frames.set_animation_speed("play", fps)
	frames.set_animation_loop("play", false)

	var emitted: int = 0
	for y in range(rows):
		for x in range(columns):
			if emitted >= max_frames:
				break
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2i(x * frame_size.x, y * frame_size.y, frame_size.x, frame_size.y)
			frames.add_frame("play", atlas)
			emitted += 1
		if emitted >= max_frames:
			break

	_frames_cache[effect_key] = frames
	return frames
