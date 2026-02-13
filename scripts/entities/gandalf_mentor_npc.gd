extends NPC
class_name GandalfMentorNPC
## Intro mentor NPC for guided new-player runs.
## Uses Gandalf's tile and departs in a flash after scripted dialogue.

const GANDALF_TILE_ID: int = 301

func _ready() -> void:
	super._ready()
	_setup_gandalf()
	_setup_dialogue()
	set_sprite_from_monster_id(GANDALF_TILE_ID)
	z_as_relative = false
	z_index = 260

func _setup_gandalf() -> void:
	npc_id = "gandalf_mentor_intro"
	entity_name = "Gandalf the Grey"
	is_unique = true
	can_be_attacked = false
	blocks_movement = true
	max_health = 1
	current_health = 1

func _setup_dialogue() -> void:
	dialogue_tree.clear()
	add_dialogue_node(
		"You are come in good hour. Hear me now: you must find Thrain, son of Thror."
	)
	add_dialogue_node(
		"He bears what must not be lost: the map and the key to Erebor. Bring them out of this darkness."
	)
	add_dialogue_node(
		"This is the Tower of the Necromancer, and I fear the hand behind it is Sauron himself."
	)
	add_dialogue_node(
		"Once you pass within these wards, there is no easy turning back. No market, no hearth, no safe bed awaits you here."
	)
	add_dialogue_node(
		"There is only down, through curse and shadow, until you reclaim Thrain's charge."
	)
	add_dialogue_node(
		"This charge was mine to carry. Yet I am called away by urgent business, and so I lay it upon you."
	)
	add_dialogue_node(
		"Take now this ancient scroll. Study it with [T], and let your skill and your craft grow together."
	)
	add_dialogue_node(
		"It is no light thing that I ask, and I do not ask it lightly. I am sorry to lay this burden upon you."
	)
	add_dialogue_node(
		"I will guide you while I may; but in the deeper dark my power will be cut off. Go now, and keep your wits."
	)

func on_dialogue_complete() -> void:
	if TutorialManager and TutorialManager.has_method("on_gandalf_scroll_granted"):
		TutorialManager.on_gandalf_scroll_granted()
	if TutorialManager and TutorialManager.has_method("on_gandalf_intro_complete"):
		TutorialManager.on_gandalf_intro_complete()
	_depart_in_light()

func _depart_in_light() -> void:
	GameManager.log_message("Gandalf is gone in a sudden flash of white fire.", ThemeColors.GOLD_BRIGHT)
	vfx_sprite_spell("flash03", 0.92)
	vfx_sprite_spell("fire_yellow", 0.78)
	vfx_flash(ThemeColors.FLASH_WHITE_HOT, 0.08, 0.25)
	vfx_particles(ThemeColors.GOLD_BRIGHT, 14, 42.0, 0.45)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.32)
	tween.tween_callback(func():
		if GameManager and GameManager.current_level and GameManager.current_level.has_method("remove_entity"):
			GameManager.current_level.remove_entity(self)
		queue_free()
	)

static func create_at_position(pos: Vector2i) -> Node:
	var gandalf = (load("res://scripts/entities/gandalf_mentor_npc.gd") as GDScript).new()
	gandalf.grid_position = pos
	return gandalf
