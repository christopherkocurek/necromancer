extends Control
class_name DialoguePanel
## UI panel for NPC dialogue interactions.
## Displays dialogue text and handles player input to advance.
## Note: Uses Node type for NPC to avoid cyclic dependency issues.

signal dialogue_closed()

# UI References
@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DialogueText
@onready var prompt_label: Label = $Panel/MarginContainer/VBoxContainer/PromptLabel

# Current NPC being talked to (typed as Node to avoid cyclic dependency)
var current_npc: Node = null
var is_active: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Style the dialogue panel with parchment theme
	if panel:
		var style: StyleBox
		if ThemeColors.has_textures():
			style = ThemeColors.create_textured_panel("panel_parchment", 12.0)
		else:
			style = ThemeColors.create_panel_stylebox(ThemeColors.PARCHMENT_BG, ThemeColors.PARCHMENT_EDGE, 2, 6)
		panel.add_theme_stylebox_override("panel", style)
	if speaker_label:
		ThemeColors.apply_heading_font(speaker_label, ThemeColors.FONT_SIZE_H3)
	if dialogue_text:
		ThemeColors.apply_rich_body_font(dialogue_text, ThemeColors.FONT_SIZE_LARGE)
		dialogue_text.add_theme_color_override("default_color", ThemeColors.PARCHMENT_TEXT)
	if prompt_label:
		ThemeColors.apply_body_font(prompt_label, ThemeColors.FONT_SIZE_HINT)
		prompt_label.add_theme_color_override("font_color", ThemeColors.GOLD_DIM)

func _input(event: InputEvent) -> void:
	if not is_active or not visible:
		return

	# Advance dialogue on Enter/Space
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()
	# Close on Escape
	elif event.is_action_pressed("ui_cancel"):
		close_dialogue()
		get_viewport().set_input_as_handled()

func open_dialogue(npc: Node) -> void:
	"""Open dialogue with an NPC. (Uses Node type to avoid cyclic dependency)"""
	if npc == null:
		return

	current_npc = npc
	is_active = true
	PanelTransition.open_panel(self)

	# Get the first dialogue node (duck typing)
	var dialogue_node = npc.interact() if npc.has_method("interact") else null
	if dialogue_node:
		_display_dialogue(dialogue_node)
	else:
		# NPC has nothing to say
		close_dialogue()

	# Pause game state (optional - depends on game design)
	GameManager.change_state(GameManager.GameState.DIALOGUE)

	# Emit event
	EventBus.dialogue_started.emit(npc)

func _advance_dialogue() -> void:
	"""Move to the next dialogue node."""
	if current_npc == null:
		close_dialogue()
		return

	var next_node = current_npc.advance_dialogue() if current_npc.has_method("advance_dialogue") else null
	if next_node:
		_display_dialogue(next_node)
	else:
		# Dialogue complete
		close_dialogue()

func _display_dialogue(node) -> void:
	"""Display a dialogue node. (node is a DialogueNode RefCounted object)"""
	if speaker_label:
		speaker_label.text = current_npc.entity_name if current_npc else "???"

	if dialogue_text:
		dialogue_text.text = node.text if node else ""

	if prompt_label:
		prompt_label.text = "[Press ENTER to continue]"

func close_dialogue() -> void:
	"""Close the dialogue panel."""
	is_active = false

	# Capture NPC reference before close animation clears it
	var npc_ref: Node = current_npc
	current_npc = null

	PanelTransition.close_panel(self, func():
		# Emit event after close animation
		if npc_ref and is_instance_valid(npc_ref):
			EventBus.dialogue_ended.emit(npc_ref)

			# Check if dialogue is complete and trigger any end effects
			if npc_ref.dialogue_complete and npc_ref.has_method("on_dialogue_complete"):
				npc_ref.on_dialogue_complete()

		# Return to playing state
		GameManager.change_state(GameManager.GameState.PLAYING)

		dialogue_closed.emit()
	)

func is_dialogue_active() -> bool:
	return is_active and visible
