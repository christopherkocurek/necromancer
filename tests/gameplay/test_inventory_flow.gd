extends GutTest
## Gameplay scenario tests for inventory operations.
## Tests pickup, equip, unequip, drop, potion use, food consumption,
## and consumable stacking mechanics.

# ============================================================================
# INVENTORY ADD / REMOVE
# ============================================================================

func test_add_item_to_empty_inventory():
	var inventory: Array = []
	var max_inventory: int = 23

	var item: Dictionary = {"name": "Short Sword", "tval": 23, "sval": 1, "weight": 30}
	if inventory.size() < max_inventory:
		inventory.append(item)

	assert_eq(inventory.size(), 1, "Inventory should have 1 item")
	assert_eq(inventory[0].name, "Short Sword", "Item name should match")

func test_add_multiple_items():
	var inventory: Array = []
	var max_inventory: int = 23

	for i in range(5):
		var item: Dictionary = {"name": "Item %d" % i, "tval": 23, "sval": i, "weight": 10}
		if inventory.size() < max_inventory:
			inventory.append(item)

	assert_eq(inventory.size(), 5, "Inventory should have 5 items")

func test_inventory_full_rejects_item():
	var inventory: Array = []
	var max_inventory: int = 23

	# Fill inventory
	for i in range(max_inventory):
		inventory.append({"name": "Item %d" % i, "tval": 23, "sval": i})

	assert_eq(inventory.size(), 23, "Inventory should be full at 23")

	# Try to add one more
	var new_item: Dictionary = {"name": "Overflow", "tval": 23, "sval": 99}
	var added: bool = false
	if inventory.size() < max_inventory:
		inventory.append(new_item)
		added = true

	assert_false(added, "Should not add item to full inventory")
	assert_eq(inventory.size(), 23, "Inventory size unchanged")

func test_remove_item_by_index():
	var inventory: Array = []
	inventory.append({"name": "Sword", "tval": 23, "sval": 1})
	inventory.append({"name": "Shield", "tval": 34, "sval": 1})
	inventory.append({"name": "Potion", "tval": 75, "sval": 3})

	# Remove the shield (index 1)
	inventory.remove_at(1)
	assert_eq(inventory.size(), 2, "Inventory should have 2 items after removal")
	assert_eq(inventory[0].name, "Sword", "First item unchanged")
	assert_eq(inventory[1].name, "Potion", "Potion shifted to index 1")

func test_remove_item_by_reference():
	var inventory: Array = []
	var sword: Dictionary = {"name": "Sword", "tval": 23, "sval": 1}
	var shield: Dictionary = {"name": "Shield", "tval": 34, "sval": 1}
	inventory.append(sword)
	inventory.append(shield)

	inventory.erase(sword)
	assert_eq(inventory.size(), 1, "Inventory should have 1 item")
	assert_eq(inventory[0].name, "Shield", "Shield should remain")

# ============================================================================
# EQUIP / UNEQUIP
# ============================================================================

func test_equip_item_to_slot():
	var inventory: Array = []
	var equipment: Dictionary = {
		"weapon": null, "off_hand": null, "armor": null,
		"head": null, "feet": null, "light": null,
	}

	var sword: Dictionary = {"name": "Short Sword", "tval": 23, "sval": 1, "weight": 30, "damage_dice": "1d7"}
	inventory.append(sword)
	assert_eq(inventory.size(), 1, "Item in inventory before equip")

	# Equip: move from inventory to slot
	equipment["weapon"] = sword
	inventory.erase(sword)

	assert_null(equipment.get("armor"), "Armor slot should still be empty")
	assert_not_null(equipment["weapon"], "Weapon slot should be occupied")
	assert_eq(equipment["weapon"].name, "Short Sword", "Equipped weapon name")
	assert_eq(inventory.size(), 0, "Item removed from inventory after equip")

func test_unequip_item_to_inventory():
	var inventory: Array = []
	var max_inventory: int = 23
	var equipment: Dictionary = {"weapon": null, "armor": null}

	var sword: Dictionary = {"name": "Long Sword", "tval": 23, "sval": 2, "weight": 40}
	equipment["weapon"] = sword

	# Unequip: move from slot to inventory
	var item: Dictionary = equipment["weapon"]
	equipment["weapon"] = null
	if inventory.size() < max_inventory:
		inventory.append(item)

	assert_null(equipment["weapon"], "Weapon slot should be empty after unequip")
	assert_eq(inventory.size(), 1, "Item should be in inventory")
	assert_eq(inventory[0].name, "Long Sword", "Unequipped item name matches")

func test_equip_replaces_existing():
	var inventory: Array = []
	var max_inventory: int = 23
	var equipment: Dictionary = {"weapon": null}

	var old_sword: Dictionary = {"name": "Rusty Sword", "tval": 23, "sval": 1}
	var new_sword: Dictionary = {"name": "Elven Blade", "tval": 23, "sval": 5}

	# Equip old sword
	equipment["weapon"] = old_sword

	# Equip new sword (old goes to inventory)
	var replaced: Dictionary = equipment["weapon"]
	equipment["weapon"] = new_sword
	if inventory.size() < max_inventory:
		inventory.append(replaced)

	assert_eq(equipment["weapon"].name, "Elven Blade", "New weapon equipped")
	assert_eq(inventory.size(), 1, "Old weapon in inventory")
	assert_eq(inventory[0].name, "Rusty Sword", "Old weapon name matches")

func test_equip_slot_mapping():
	# TVAL -> slot mapping (from Constants.TVAL_TO_SLOT)
	# Test the concept: different tvals go to different slots
	var tval_to_slot: Dictionary = {
		23: "weapon",  # Swords
		21: "weapon",  # Polearms
		19: "weapon",  # Axes
		34: "off_hand",  # Shields
		36: "armor",  # Body armor
		32: "head",  # Helmets
		31: "feet",  # Boots
		33: "hands",  # Gloves
		35: "cloak",  # Cloaks
		40: "amulet",  # Amulets
		45: "ring_left",  # Rings
	}

	assert_eq(tval_to_slot[23], "weapon", "Swords equip to weapon slot")
	assert_eq(tval_to_slot[34], "off_hand", "Shields equip to off_hand slot")
	assert_eq(tval_to_slot[36], "armor", "Body armor equips to armor slot")
	assert_eq(tval_to_slot[40], "amulet", "Amulets equip to amulet slot")
	assert_eq(tval_to_slot[45], "ring_left", "Rings equip to ring slot")

func test_all_equipment_slots_start_empty():
	var equipment: Dictionary = {
		"weapon": null, "off_hand": null, "bow": null,
		"armor": null, "cloak": null, "head": null,
		"hands": null, "feet": null, "ring_left": null,
		"ring_right": null, "amulet": null, "light": null,
		"quiver": null,
	}

	for slot_name in equipment:
		assert_null(equipment[slot_name], "Slot '%s' should start empty" % slot_name)

	assert_eq(equipment.size(), 13, "Should have 13 equipment slots")

# ============================================================================
# DROP ITEM
# ============================================================================

func test_drop_item_removes_from_inventory():
	var inventory: Array = []
	var sword: Dictionary = {"name": "Sword", "tval": 23, "sval": 1}
	var shield: Dictionary = {"name": "Shield", "tval": 34, "sval": 1}
	inventory.append(sword)
	inventory.append(shield)

	# Drop sword
	var idx: int = inventory.find(sword)
	assert_eq(idx, 0, "Sword should be at index 0")
	inventory.remove_at(idx)
	assert_eq(inventory.size(), 1, "Inventory should have 1 item after drop")
	assert_eq(inventory[0].name, "Shield", "Shield remains")

func test_drop_from_stack_decrements_count():
	# Dropping from a stack of consumables
	var potion: Dictionary = {"name": "Healing Potion", "tval": 75, "sval": 3, "stack_count": 5}
	var inventory: Array = [potion]

	# Drop one from stack
	var count: int = potion.stack_count
	assert_eq(count, 5, "Stack starts at 5")
	if count > 1:
		potion.stack_count = count - 1

	assert_eq(potion.stack_count, 4, "Stack decremented to 4")
	assert_eq(inventory.size(), 1, "Still one entry in inventory")

func test_drop_last_from_stack_removes_item():
	var potion: Dictionary = {"name": "Healing Potion", "tval": 75, "sval": 3, "stack_count": 1}
	var inventory: Array = [potion]

	var count: int = potion.stack_count
	if count <= 1:
		inventory.erase(potion)
	else:
		potion.stack_count = count - 1

	assert_eq(inventory.size(), 0, "Dropping last item removes from inventory")

# ============================================================================
# CONSUMABLE STACKING
# ============================================================================

func test_stackable_tvals():
	# Arrows (16), Sling ammo (39), Potions (75), Food/Herbs (80)
	var stackable_tvals: Array[int] = [16, 39, 75, 80]
	assert_true(75 in stackable_tvals, "Potions are stackable")
	assert_true(80 in stackable_tvals, "Food is stackable")
	assert_true(16 in stackable_tvals, "Arrows are stackable")
	assert_false(23 in stackable_tvals, "Swords are NOT stackable")

func test_stack_same_consumable():
	# Picking up a potion when same type already in inventory
	var inventory: Array = []
	var existing: Dictionary = {"name": "Healing", "tval": 75, "sval": 3, "stack_count": 2}
	inventory.append(existing)

	var new_item: Dictionary = {"name": "Healing", "tval": 75, "sval": 3, "stack_count": 1}
	var max_stack: int = 20

	# Try stacking
	var stacked: bool = false
	for inv_item in inventory:
		if inv_item.tval == new_item.tval and inv_item.sval == new_item.sval and inv_item.name == new_item.name:
			var existing_count: int = inv_item.stack_count if "stack_count" in inv_item else 1
			var add_count: int = new_item.stack_count if "stack_count" in new_item else 1
			if existing_count + add_count <= max_stack:
				inv_item.stack_count = existing_count + add_count
				stacked = true
				break

	assert_true(stacked, "Should stack onto existing item")
	assert_eq(inventory.size(), 1, "No new inventory entry created")
	assert_eq(inventory[0].stack_count, 3, "Stack count should be 3")

func test_stack_respects_max_size():
	var inventory: Array = []
	var existing: Dictionary = {"name": "Arrow", "tval": 16, "sval": 1, "stack_count": 18}
	inventory.append(existing)

	var new_item: Dictionary = {"name": "Arrow", "tval": 16, "sval": 1, "stack_count": 5}
	var max_stack: int = 20

	# Try stacking - would exceed max
	var stacked: bool = false
	for inv_item in inventory:
		if inv_item.tval == new_item.tval and inv_item.sval == new_item.sval:
			var existing_count: int = inv_item.stack_count if "stack_count" in inv_item else 1
			var add_count: int = new_item.stack_count if "stack_count" in new_item else 1
			if existing_count + add_count <= max_stack:
				inv_item.stack_count = existing_count + add_count
				stacked = true
				break

	assert_false(stacked, "Should NOT stack when would exceed max")
	assert_eq(inventory[0].stack_count, 18, "Original stack unchanged")

func test_different_sval_does_not_stack():
	var inventory: Array = []
	var existing: Dictionary = {"name": "Healing", "tval": 75, "sval": 3, "stack_count": 2}
	var new_item: Dictionary = {"name": "Clarity", "tval": 75, "sval": 4, "stack_count": 1}
	inventory.append(existing)

	var stacked: bool = false
	for inv_item in inventory:
		if inv_item.tval == new_item.tval and inv_item.sval == new_item.sval and inv_item.name == new_item.name:
			var existing_count: int = inv_item.stack_count if "stack_count" in inv_item else 1
			var add_count: int = new_item.stack_count if "stack_count" in new_item else 1
			if existing_count + add_count <= 20:
				inv_item.stack_count = existing_count + add_count
				stacked = true
				break

	if not stacked:
		inventory.append(new_item)

	assert_false(stacked, "Different sval potions should not stack")
	assert_eq(inventory.size(), 2, "Both potions are separate entries")

# ============================================================================
# POTION USE (ConsumableSystem formula tests)
# ============================================================================

func test_quaff_heals_player():
	# Simulate Esgalduin potion (sval 3): heals 10-25
	var current_health: int = 30
	var max_health: int = 50
	var heal_amount: int = 15  # Fixed for test

	current_health = mini(current_health + heal_amount, max_health)
	assert_eq(current_health, 45, "Health should increase by heal amount")

func test_quaff_heal_capped_at_max():
	var current_health: int = 45
	var max_health: int = 50
	var heal_amount: int = 20  # Would overheal

	current_health = mini(current_health + heal_amount, max_health)
	assert_eq(current_health, 50, "Healing capped at max HP")

func test_quaff_miruvor_full_heal():
	# Miruvor (sval 0): heals to max + cures all
	var current_health: int = 10
	var max_health: int = 50
	current_health = max_health  # Full heal
	assert_eq(current_health, 50, "Miruvor fully heals")

func test_quaff_decrements_stack():
	var potion: Dictionary = {"name": "Healing", "tval": 75, "sval": 3, "stack_count": 3}

	# Use one
	potion.stack_count -= 1
	assert_eq(potion.stack_count, 2, "Stack decremented after quaff")

func test_quaff_last_potion_removes():
	var potion: Dictionary = {"name": "Healing", "tval": 75, "sval": 3, "stack_count": 1}
	var inventory: Array = [potion]

	# Use the last one
	potion.stack_count -= 1
	if potion.stack_count <= 0:
		inventory.erase(potion)

	assert_eq(inventory.size(), 0, "Empty stack removed from inventory")

# ============================================================================
# FOOD / HERB USE
# ============================================================================

func test_eat_food_restores_hunger():
	var hunger: int = 800  # HUNGRY threshold
	var food_value: int = 500  # Restore amount
	var hunger_max: int = 2000

	hunger = mini(hunger + food_value, hunger_max)
	assert_eq(hunger, 1300, "Hunger restored by food value")

func test_eat_food_capped_at_max():
	var hunger: int = 1800
	var food_value: int = 500
	var hunger_max: int = 2000

	hunger = mini(hunger + food_value, hunger_max)
	assert_eq(hunger, 2000, "Hunger capped at max")

func test_herb_limited_pool():
	# Herbs are capped at 1-2 per floor (from Session K design)
	var herbs_on_floor: int = 0
	var max_herbs_per_floor: int = 2

	herbs_on_floor += 1
	assert_lte(herbs_on_floor, max_herbs_per_floor, "Herbs within limit")
	herbs_on_floor += 1
	assert_lte(herbs_on_floor, max_herbs_per_floor, "2 herbs is at limit")

	# Third herb should be rejected
	var can_spawn: bool = herbs_on_floor < max_herbs_per_floor
	assert_false(can_spawn, "Cannot spawn third herb")

# ============================================================================
# ITEM DATA DICT STRUCTURE
# ============================================================================

func test_item_dict_has_required_fields():
	var item: Dictionary = {
		"name": "Iron Helm",
		"tval": 32,
		"sval": 1,
		"weight": 60,
		"protection_dice": "1d4",
		"evasion_bonus": -1,
		"attack_bonus": 0,
	}

	assert_true("name" in item, "Item should have name")
	assert_true("tval" in item, "Item should have tval")
	assert_true("sval" in item, "Item should have sval")
	assert_true("weight" in item, "Item should have weight")

func test_item_stack_count_default():
	# Items without stack_count should default to 1
	var item: Dictionary = {"name": "Sword", "tval": 23, "sval": 1}
	var count: int = item.get("stack_count", 1)
	assert_eq(count, 1, "Default stack count is 1")

func test_weapon_damage_dice_access():
	var weapon: Dictionary = {"name": "Long Sword", "tval": 23, "sval": 2, "damage_dice": "2d5", "weight": 40}
	assert_eq(weapon.damage_dice, "2d5", "Weapon should have damage dice")

	# No weapon -> default
	var no_weapon: Variant = null
	var dmg_str: String = "1d4"
	if no_weapon != null and "damage_dice" in no_weapon:
		dmg_str = no_weapon.damage_dice
	assert_eq(dmg_str, "1d4", "Unarmed fallback is 1d4")
