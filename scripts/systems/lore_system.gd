extends Node
class_name LoreSystem
## Handles lore object discovery: reading lore items grants XP on first read.
## Lore objects are items with tval=2, IDs 500-557 (defined in data/object.txt).

# Track which lore objects have been read (persists in save data)
var read_lore: Dictionary = {}  # object_id (int) -> true

## Get the XP reward for reading a lore object, based on its ID range.
static func get_lore_xp(object_id: int) -> int:
	if object_id >= 500 and object_id <= 507: return 150   # Thrain's Memories
	if object_id >= 510 and object_id <= 515: return 200   # Shadow Fragments
	if object_id >= 520 and object_id <= 526: return 75    # Ancient Glyphs
	if object_id >= 530 and object_id <= 533: return 500   # Palantir Shards
	if object_id >= 540 and object_id <= 544: return 100   # Erebor Relics
	if object_id >= 550 and object_id <= 557: return 500   # Dol Guldur Records
	return 0

## Check if an item is a lore object (tval=2, index in lore range).
static func is_lore_object(item_data: DataManager.ItemData) -> bool:
	if not item_data:
		return false
	return item_data.tval == 2 and item_data.index >= 500 and item_data.index <= 557

## Read a lore object: display its text and grant XP on first read.
## Returns true if XP was granted (first read), false otherwise.
func read_lore_object(player: Node, item_data: DataManager.ItemData) -> bool:
	if not item_data:
		return false

	var obj_id: int = item_data.index
	var desc: String = item_data.description if item_data.description != "" else "You find nothing of interest."
	var name: String = item_data.name if item_data.name != "" else "mysterious object"

	# Display the lore text
	EventBus.message_logged.emit("--- " + name + " ---", ThemeColors.GOLD_BRIGHT)
	EventBus.message_logged.emit(desc, ThemeColors.PARCHMENT_BG)

	# Grant XP on first read only
	if not read_lore.has(obj_id):
		var xp: int = get_lore_xp(obj_id)
		if xp > 0:
			read_lore[obj_id] = true
			if player.has_method("gain_experience"):
				player.gain_experience(xp, "lore")
			EventBus.message_logged.emit("You gain " + str(xp) + " experience from this lore.", ThemeColors.GOLD_BRIGHT)
			return true

	return false

## Get save data for persistence.
func get_save_data() -> Dictionary:
	return {"read_lore": read_lore.duplicate()}

## Load save data for persistence.
func load_save_data(data: Dictionary) -> void:
	read_lore = data.get("read_lore", {}).duplicate()

## Reset lore tracking (for new game).
func reset() -> void:
	read_lore.clear()
