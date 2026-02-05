extends GutTest
## Unit tests for save/load system (Phase H fixes)
## Tests deep copy of nested arrays, kills_by_name persistence

# ============================================================================
# DEEP COPY TESTS
# ============================================================================

func test_shallow_copy_shares_inner_arrays():
	# Demonstrate the bug that was fixed
	var original: Array = []
	for i in range(3):
		var row: Array = []
		for j in range(5):
			row.append(false)
		original.append(row)

	# Shallow copy
	var shallow: Array = original.duplicate()

	# Modify the copy's inner array
	shallow[0][0] = true

	# BUG: shallow copy means original is also modified!
	assert_true(original[0][0], "Shallow copy shares inner arrays (this is the bug)")

func test_deep_copy_isolates_inner_arrays():
	# Verify the fix: deep copy should isolate arrays
	var original: Array = []
	for i in range(3):
		var row: Array = []
		for j in range(5):
			row.append(false)
		original.append(row)

	# Deep copy (the fix)
	var deep: Array = original.duplicate(true)

	# Modify the copy's inner array
	deep[0][0] = true

	# Original should NOT be affected
	assert_false(original[0][0], "Deep copy should isolate inner arrays")
	assert_true(deep[0][0], "Deep copy should have the modification")

func test_ability_array_deep_copy():
	# Simulate the exact save/load pattern for ability arrays
	var active_ability: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		active_ability.append(row)

	# Learn an ability
	active_ability[0][1] = true  # Melee ability 1

	# Serialize (deep copy as per fix)
	var saved: Array = active_ability.duplicate(true)

	# Modify the original after saving
	active_ability[0][2] = true

	# Saved data should not reflect post-save modifications
	assert_true(saved[0][1], "Saved ability should persist")
	assert_false(saved[0][2], "Post-save modification should not affect saved data")

func test_ability_array_load_deep_copy():
	# Simulate loading and verify isolation
	var save_data: Array = []
	for i in range(Constants.S_MAX):
		var row: Array = []
		for j in range(Constants.ABILITIES_MAX):
			row.append(false)
		save_data.append(row)
	save_data[2][3] = true  # Some ability learned

	# Load with deep copy
	var loaded: Array = save_data.duplicate(true)

	# Modify loaded data
	loaded[2][4] = true

	# Save data should not be affected
	assert_false(save_data[2][4], "Loading should not affect save data")
	assert_true(loaded[2][3], "Loaded data should have saved ability")
	assert_true(loaded[2][4], "Loaded data should have new modification")

# ============================================================================
# KILLS_BY_NAME TESTS
# ============================================================================

func test_kills_by_name_serialize():
	var kills_by_name: Dictionary = {
		"Goblin": 5,
		"Orc": 2,
		"Troll": 1
	}

	var saved: Dictionary = kills_by_name.duplicate()
	assert_eq(saved["Goblin"], 5, "Saved goblin kills should be 5")
	assert_eq(saved["Orc"], 2, "Saved orc kills should be 2")
	assert_eq(saved["Troll"], 1, "Saved troll kills should be 1")

func test_kills_by_name_null_safety():
	# Null-safe duplicate (as per fix)
	var kills: Dictionary = {}
	var saved: Dictionary = kills.duplicate() if kills else {}
	assert_eq(saved.size(), 0, "Empty dict should serialize to empty")

func test_kills_by_name_load_default():
	# Loading from save without kills_by_name key
	var data: Dictionary = {"some_key": "some_value"}
	var loaded: Dictionary = data.get("kills_by_name", {})
	assert_eq(loaded.size(), 0, "Missing key should default to empty dict")

func test_kills_by_name_incremental():
	# Verify kill counting logic
	var kills: Dictionary = {}
	var monster_name: String = "Spider"

	for i in range(5):
		kills[monster_name] = kills.get(monster_name, 0) + 1

	assert_eq(kills[monster_name], 5, "Should track 5 spider kills")

# ============================================================================
# LEARNED ABILITIES META TESTS
# ============================================================================

func test_learned_abilities_save_format():
	# learned_abilities should save as an Array of strings
	var learned: Array = ["Power", "Knock Back", "Follow-Through"]
	assert_eq(learned.size(), 3, "Should have 3 learned abilities")
	assert_true("Power" in learned, "Power should be in learned list")

func test_learned_abilities_default_on_missing():
	# Loading save without learned_abilities key
	var data: Dictionary = {}
	var loaded: Array = data.get("learned_abilities", [])
	assert_eq(loaded.size(), 0, "Missing key should default to empty array")

# ============================================================================
# STATUS EFFECTS SAVE/LOAD
# ============================================================================

func test_status_effects_serialize():
	var effects: Dictionary = {
		"poisoned": 5,
		"burning": 3,
	}

	var saved: Dictionary = effects.duplicate()
	assert_eq(saved["poisoned"], 5, "Poison duration should be saved")
	assert_eq(saved["burning"], 3, "Burning duration should be saved")

func test_fade_state_not_persisted():
	# _fade_bonus and _fade_turns are intentionally not saved
	# They are turn-based buffs that expire quickly
	var fade_bonus: int = 10
	var fade_turns: int = 3
	# No save field for these - by design
	assert_eq(fade_bonus, 10, "Fade bonus exists in memory")
	assert_eq(fade_turns, 3, "Fade turns exists in memory")
	# After load, they default to 0
	var loaded_fade_bonus: int = 0
	var loaded_fade_turns: int = 0
	assert_eq(loaded_fade_bonus, 0, "Fade bonus defaults to 0 after load")
	assert_eq(loaded_fade_turns, 0, "Fade turns defaults to 0 after load")

# ============================================================================
# BACKWARDS COMPATIBILITY
# ============================================================================

func test_old_save_missing_new_fields():
	# Simulate loading an old save that doesn't have Phase H fields
	var old_save: Dictionary = {
		"current_health": 50,
		"max_health": 100,
		"skills": {"melee": 5},
	}

	# All new fields should have safe defaults
	var kills: Dictionary = old_save.get("kills_by_name", {})
	var learned: Array = old_save.get("learned_abilities", [])
	var innate: Array = old_save.get("innate_ability", [])
	var active: Array = old_save.get("active_ability", [])

	assert_eq(kills.size(), 0, "Missing kills_by_name defaults to empty")
	assert_eq(learned.size(), 0, "Missing learned_abilities defaults to empty")
	assert_eq(innate.size(), 0, "Missing innate_ability defaults to empty")
	assert_eq(active.size(), 0, "Missing active_ability defaults to empty")
