extends Entity
class_name NPC
## Base class for non-hostile NPCs.
## NPCs have dialogue trees and can give items/quests.

# Note: Using Node type in signals to avoid self-reference issues
signal dialogue_started(npc: Node)
signal dialogue_advanced(npc: Node, node_index: int)
signal dialogue_ended(npc: Node)
signal item_given(npc: Node, item_name: String)

# NPC identification
@export var npc_id: String = ""
@export var is_unique: bool = true

# Dialogue system
var dialogue_tree: Array[DialogueNode] = []
var current_dialogue_index: int = 0
var has_interacted: bool = false
var dialogue_complete: bool = false

# Items to give
var items_to_give: Array[String] = []
var items_given: Array[String] = []

# NPC flags
var can_be_attacked: bool = false
var blocks_movement: bool = true

func _ready() -> void:
	super._ready()
	# NPCs don't participate in combat by default
	is_alive = true

func interact() -> DialogueNode:
	"""Return current dialogue node when player interacts."""
	if dialogue_complete:
		return null

	if current_dialogue_index >= dialogue_tree.size():
		dialogue_complete = true
		dialogue_ended.emit(self)
		return null

	if not has_interacted:
		has_interacted = true
		dialogue_started.emit(self)

	return dialogue_tree[current_dialogue_index]

func advance_dialogue() -> DialogueNode:
	"""Move to next dialogue node and return it."""
	var current_node := get_current_dialogue()
	if current_node == null:
		return null

	# Give items if this node gives items
	for item_name in current_node.gives_items:
		if item_name not in items_given:
			_give_item(item_name)
			items_given.append(item_name)

	# Move to next node
	current_dialogue_index += 1
	dialogue_advanced.emit(self, current_dialogue_index)

	# Check if dialogue is complete
	if current_dialogue_index >= dialogue_tree.size():
		dialogue_complete = true
		dialogue_ended.emit(self)
		return null

	return dialogue_tree[current_dialogue_index]

func get_current_dialogue() -> DialogueNode:
	"""Get the current dialogue node without advancing."""
	if current_dialogue_index >= dialogue_tree.size():
		return null
	return dialogue_tree[current_dialogue_index]

func _give_item(item_name: String) -> void:
	"""Give an item to the player."""
	var player: Player = GameManager.player
	if not player:
		return

	# Create item data for quest items
	var quest_item := _create_quest_item(item_name)
	if quest_item:
		if player.pick_up_item(quest_item):
			GameManager.log_message("You receive: %s" % item_name, ThemeColors.PRIMARY)
			item_given.emit(self, item_name)
		else:
			GameManager.log_message("Your pack is full! %s falls to the ground." % item_name, ThemeColors.MSG_ERROR)

func _create_quest_item(item_name: String) -> DataManager.ItemData:
	"""Create a quest item. Override in subclasses for special items."""
	# Check if item exists in data
	var existing_item := DataManager.get_item(item_name)
	if existing_item:
		return existing_item

	var existing_artifact := DataManager.get_artifact(item_name)
	if existing_artifact:
		# Convert artifact to item data
		var quest_item := DataManager.ItemData.new()
		quest_item.name = existing_artifact.name
		quest_item.description = existing_artifact.description
		quest_item.flags = existing_artifact.flags.duplicate()
		quest_item.flags.append("QUEST_ITEM")
		return quest_item

	# Create a generic quest item
	var quest_item := DataManager.ItemData.new()
	quest_item.name = item_name
	quest_item.description = "A quest item."
	quest_item.flags = ["QUEST_ITEM", "INDESTRUCTIBLE"]
	return quest_item

func add_dialogue_node(text: String, gives_items: Array[String] = []) -> void:
	"""Helper to add a dialogue node."""
	var node := DialogueNode.new()
	node.text = text
	node.gives_items = gives_items
	dialogue_tree.append(node)

# Override movement check - NPCs don't move
func can_move_to(_target: Vector2i) -> bool:
	return false

# Override death - most NPCs can't die
func die(_killer: Entity = null) -> void:
	if can_be_attacked:
		super.die(_killer)
	# Otherwise do nothing

# Override attack - NPCs don't attack back by default
func attack_entity(_target: Entity) -> void:
	pass

# ============================================================================
# DIALOGUE NODE CLASS
# ============================================================================

class DialogueNode:
	var text: String = ""
	var gives_items: Array[String] = []
	var next_index: int = -1  # -1 = auto-advance, otherwise jump to index
	var options: Array[String] = []  # Future: player response options
