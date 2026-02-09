extends GutTest
## Unit tests for the enchantment system.
## Covers: special.txt parser, ego selection, ego application, loot tier curves, tooltip dictionaries.

# ============================================================================
# 1. PARSER TESTS — verify special.txt loads correctly into DataManager.egos
# ============================================================================

func test_egos_loaded():
	assert_gte(DataManager.egos.size(), 78, "Should load at least 78 ego types")

func test_ego_count_matches_file():
	# special.txt has 112 unique N: lines (97 original + 15 new ring/amulet egos)
	assert_eq(DataManager.egos.size(), 112, "Should load all 112 ego types from special.txt")

func test_ego_21_gondolin_fields():
	var ego: DataManager.EgoData = DataManager.egos.get(21)
	assert_not_null(ego, "Ego 21 should exist")
	assert_eq(ego.name, "of Gondolin")
	assert_true("SLAY_ORC" in ego.flags, "Should have SLAY_ORC flag")
	assert_true("SLAY_TROLL" in ego.flags, "Should have SLAY_TROLL flag")
	assert_true("LIGHT" in ego.flags, "Should have LIGHT flag")

func test_ego_22_doriath_has_light():
	var ego: DataManager.EgoData = DataManager.egos.get(22)
	assert_not_null(ego, "Ego 22 should exist")
	assert_eq(ego.name, "of Doriath")
	assert_true("LIGHT" in ego.flags, "Should have LIGHT flag")

func test_ego_23_renamed_wraith_bane():
	var ego: DataManager.EgoData = DataManager.egos.get(23)
	assert_not_null(ego, "Ego 23 should exist")
	assert_eq(ego.name, "of Wraith-bane", "Should be named Wraith-bane")
	assert_true("SLAY_UNDEAD" in ego.flags, "Should have SLAY_UNDEAD")
	assert_true("SEE_INVIS" in ego.flags, "Should have SEE_INVIS")

func test_ego_9_is_cursed():
	var ego: DataManager.EgoData = DataManager.egos.get(9)
	assert_not_null(ego, "Ego 9 (of Blight) should exist")
	assert_eq(ego.name, "of Blight")
	assert_true(ego.is_cursed, "Ego 9 should be cursed (has VUL_POIS)")

func test_ego_1_is_not_cursed():
	var ego: DataManager.EgoData = DataManager.egos.get(1)
	assert_not_null(ego, "Ego 1 (of Protection) should exist")
	assert_false(ego.is_cursed, "Ego 1 should NOT be cursed")

func test_ego_27_has_granted_ability():
	# Ego 27 (of the Edain) has B:0/5 (Follow-Through)
	var ego: DataManager.EgoData = DataManager.egos.get(27)
	assert_not_null(ego, "Ego 27 should exist")
	assert_eq(ego.name, "of the Edain")
	assert_gt(ego.granted_abilities.size(), 0, "Should have at least one granted ability")
	assert_eq(ego.granted_abilities[0], [0, 5], "Should grant ability 0/5 (Follow-Through)")

func test_ego_21_tval_filters():
	# Ego 21 (of Gondolin) filters to specific weapon/arrow types
	var ego: DataManager.EgoData = DataManager.egos.get(21)
	assert_not_null(ego, "Ego 21 should exist")
	assert_gt(ego.tval_filters.size(), 0, "Should have tval filters")
	# T:22:1:4 (axes sval 1-4), T:23:10:21 (swords), T:17:0:99 (arrows), T:23:28:30 (mithril swords)
	assert_eq(ego.tval_filters.size(), 4, "Gondolin should have 4 T: filter entries")

func test_ego_36_c_line_parsing():
	# Ego 36 (of the Eorlingas) has C:1:0:1:0:0:0:1
	var ego: DataManager.EgoData = DataManager.egos.get(36)
	assert_not_null(ego, "Ego 36 should exist")
	assert_eq(ego.name, "of the Eorlingas")
	assert_eq(ego.max_attack, 1, "Should have max_attack 1")
	assert_eq(ego.plus_damage_dice, 0, "Should have plus_damage_dice 0")
	assert_eq(ego.plus_damage_sides, 1, "Should have plus_damage_sides 1")
	assert_eq(ego.max_evasion, 0, "Should have max_evasion 0")
	assert_eq(ego.plus_prot_dice, 0, "Should have plus_prot_dice 0")
	assert_eq(ego.plus_prot_sides, 0, "Should have plus_prot_sides 0")
	assert_eq(ego.pval, 1, "Should have pval 1")

func test_ego_1_c_line_protection():
	# Ego 1 (of Protection) has C:0:0:0:0:0:1:0
	var ego: DataManager.EgoData = DataManager.egos.get(1)
	assert_not_null(ego, "Ego 1 should exist")
	assert_eq(ego.plus_prot_sides, 1, "Should have plus_prot_sides 1")
	assert_eq(ego.pval, 0, "Should have pval 0")

func test_ego_34_max_depth():
	# Ego 34 (of Murder) has W:0:1:4:2000 → max_depth = 4
	var ego: DataManager.EgoData = DataManager.egos.get(34)
	assert_not_null(ego, "Ego 34 should exist")
	assert_eq(ego.name, "of Murder")
	assert_eq(ego.max_depth, 4, "Should have max_depth 4")

func test_ego_w_line_depth_and_rarity():
	# Ego 21 (of Gondolin) has W:0:4:10:1000 → depth 0, rarity 4, max_depth 10
	var ego: DataManager.EgoData = DataManager.egos.get(21)
	assert_not_null(ego, "Ego 21 should exist")
	assert_eq(ego.depth, 0, "Should have depth 0")
	assert_eq(ego.rarity, 4, "Should have rarity 4")
	assert_eq(ego.max_depth, 10, "Should have max_depth 10")

# New ego entries (Enchantment System v1)

func test_new_ego_50_flame():
	var ego: DataManager.EgoData = DataManager.egos.get(50)
	assert_not_null(ego, "Ego 50 (of the Flame) should exist")
	assert_eq(ego.name, "of the Flame")
	assert_true("BRAND_FIRE" in ego.flags, "Should have BRAND_FIRE")

func test_new_ego_56_vanguard():
	var ego: DataManager.EgoData = DataManager.egos.get(56)
	assert_not_null(ego, "Ego 56 (of the Vanguard) should exist")
	assert_eq(ego.name, "of the Vanguard")
	assert_gt(ego.granted_abilities.size(), 0, "Should grant an ability")
	assert_eq(ego.granted_abilities[0], [0, 4], "Should grant Charge (0/4)")

func test_new_ego_115_shadow_stalker():
	var ego: DataManager.EgoData = DataManager.egos.get(115)
	assert_not_null(ego, "Ego 115 (of the Shadow-stalker) should exist")
	assert_eq(ego.name, "of the Shadow-stalker")
	assert_gt(ego.granted_abilities.size(), 0, "Should grant Fade ability")
	assert_eq(ego.granted_abilities[0], [3, 8], "Should grant Fade (3/8)")

func test_new_ego_128_burglar():
	var ego: DataManager.EgoData = DataManager.egos.get(128)
	assert_not_null(ego, "Ego 128 (of the Burglar) should exist")
	assert_eq(ego.name, "of the Burglar")
	assert_true("STEALTH" in ego.flags, "Should have STEALTH")
	assert_eq(ego.pval, 2, "Should have pval 2")
	assert_gt(ego.granted_abilities.size(), 0, "Should grant Pilfer")
	assert_eq(ego.granted_abilities[0], [3, 9], "Should grant Pilfer (3/9)")

func test_new_ego_16_flame_guard():
	var ego: DataManager.EgoData = DataManager.egos.get(16)
	assert_not_null(ego, "Ego 16 (of the Flame-guard) should exist")
	assert_eq(ego.name, "of the Flame-guard")
	assert_true("RES_FIRE" in ego.flags, "Should have RES_FIRE")
	assert_true("IGNORE_ALL" in ego.flags, "Should have IGNORE_ALL")

func test_new_ego_55_warding():
	var ego: DataManager.EgoData = DataManager.egos.get(55)
	assert_not_null(ego, "Ego 55 (of Warding) should exist")
	assert_eq(ego.name, "of Warding")
	assert_true("RES_CONFU" in ego.flags, "Should have RES_CONFU")
	assert_true("RES_STUN" in ego.flags, "Should have RES_STUN")
	assert_true("FREE_ACT" in ego.flags, "Should have FREE_ACT")

func test_ego_46_parenthetical_name():
	# Parenthetical egos like "(Poisoned)" are valid names
	var ego: DataManager.EgoData = DataManager.egos.get(46)
	assert_not_null(ego, "Ego 46 should exist")
	assert_eq(ego.name, "(Poisoned)")
	assert_true("BRAND_POIS" in ego.flags, "Should have BRAND_POIS")

func test_ego_multi_flag_line():
	# Ego 26 (of the Firebeards) has two F: lines: REGEN | RES_FIRE and IGNORE_ALL
	var ego: DataManager.EgoData = DataManager.egos.get(26)
	assert_not_null(ego, "Ego 26 should exist")
	assert_true("REGEN" in ego.flags, "Should have REGEN from first F: line")
	assert_true("RES_FIRE" in ego.flags, "Should have RES_FIRE from first F: line")
	assert_true("IGNORE_ALL" in ego.flags, "Should have IGNORE_ALL from second F: line")

# ============================================================================
# 2. EGO SELECTION TESTS — get_egos_for_item / select_ego_for_item
# ============================================================================

func test_get_egos_for_sword():
	# tval 23 (swords), sval 10 (shortsword), depth 5
	var egos: Array = DataManager.get_egos_for_item(23, 10, 5)
	assert_gt(egos.size(), 0, "Should find valid egos for a sword at depth 5")

func test_get_egos_rejects_wrong_tval():
	# Ego 111 (of Softest Tread) is boots-only (tval 30, sval 1)
	var ego: DataManager.EgoData = DataManager.egos.get(111)
	assert_not_null(ego, "Ego 111 should exist")
	# Try matching against a sword (tval 23)
	assert_false(ego.matches_item(23, 10), "Boot ego should not match a sword")

func test_get_egos_respects_depth():
	# Egos at deeper depth should include those valid for shallow + new deeper ones
	var shallow: Array = DataManager.get_egos_for_item(23, 10, 1)
	var deep: Array = DataManager.get_egos_for_item(23, 10, 15)
	assert_lte(shallow.size(), deep.size(), "More egos should be available at deeper depth")

func test_get_egos_respects_max_depth():
	# Ego 34 (of Murder) has max_depth 4
	var ego: DataManager.EgoData = DataManager.egos.get(34)
	assert_not_null(ego, "Ego 34 should exist")
	assert_true(ego.max_depth > 0, "Ego 34 should have a positive max_depth")
	assert_false(ego.valid_for_depth(ego.max_depth + 1), "Should not be valid beyond max_depth")
	assert_true(ego.valid_for_depth(ego.max_depth), "Should be valid at max_depth")

func test_exclude_cursed_removes_cursed():
	# Get egos for armor (tval 36), with and without cursed exclusion
	var all_egos: Array = DataManager.get_egos_for_item(36, 4, 10, false)
	var good_egos: Array = DataManager.get_egos_for_item(36, 4, 10, true)
	assert_gte(all_egos.size(), good_egos.size(), "Excluding cursed should return same or fewer results")
	for ego in good_egos:
		assert_false(ego.is_cursed, "Excluded list should contain no cursed egos")

func test_select_ego_returns_valid():
	# Select random ego for sword at depth 5
	var ego: DataManager.EgoData = DataManager.select_ego_for_item(23, 10, 5)
	# May return null if no egos match, but if not null, should be valid
	if ego:
		assert_true(ego.matches_item(23, 10), "Selected ego should match the item type")
		assert_true(ego.valid_for_depth(5), "Selected ego should be valid for depth 5")

func test_select_ego_null_for_invalid():
	# tval 99 doesn't exist — should return null
	var ego: DataManager.EgoData = DataManager.select_ego_for_item(99, 99, 5)
	assert_null(ego, "Should return null for non-existent item type")

func test_ego_matches_item_empty_filters():
	# An ego with no tval_filters should match everything
	var ego := DataManager.EgoData.new()
	assert_true(ego.matches_item(23, 10), "Empty filters should match any item")
	assert_true(ego.matches_item(36, 4), "Empty filters should match armor too")
	assert_true(ego.matches_item(99, 99), "Empty filters should match invalid types too")

func test_valid_for_depth_no_max():
	# An ego with depth 0 and no max_depth should always be valid
	var ego := DataManager.EgoData.new()
	ego.depth = 0
	ego.max_depth = 0
	assert_true(ego.valid_for_depth(1), "Should be valid at depth 1")
	assert_true(ego.valid_for_depth(20), "Should be valid at depth 20")

func test_valid_for_depth_below_minimum():
	# An ego with depth 8 should not be valid at depth 3
	var ego := DataManager.EgoData.new()
	ego.depth = 8
	ego.max_depth = 0
	assert_false(ego.valid_for_depth(3), "Should not be valid below minimum depth")
	assert_true(ego.valid_for_depth(8), "Should be valid at minimum depth")
	assert_true(ego.valid_for_depth(15), "Should be valid above minimum depth")

# ============================================================================
# 3. EGO APPLICATION TESTS — apply_ego_to_item
# ============================================================================

func test_apply_ego_sets_name_suffix():
	var item := DataManager.ItemData.new()
	item.name = "Longsword"
	item.damage_dice = "2d5"
	var ego := DataManager.EgoData.new()
	ego.name = "of Gondolin"
	ego.index = 21
	DataManager.apply_ego_to_item(item, ego)
	assert_true(item.name.ends_with("of Gondolin"), "Should append ego name as suffix")
	assert_eq(item.name, "Longsword of Gondolin")

func test_apply_ego_sets_name_prefix():
	var item := DataManager.ItemData.new()
	item.name = "Dagger"
	item.damage_dice = "1d5"
	var ego := DataManager.EgoData.new()
	ego.name = "(Poisoned)"
	ego.index = 46
	DataManager.apply_ego_to_item(item, ego)
	assert_true(item.name.begins_with("(Poisoned)"), "Parenthetical ego should be prefixed")
	assert_eq(item.name, "(Poisoned) Dagger")

func test_apply_ego_merges_flags():
	var item := DataManager.ItemData.new()
	item.flags = ["LIGHT"] as Array[String]
	var ego := DataManager.EgoData.new()
	ego.flags = ["SLAY_ORC", "LIGHT"] as Array[String]
	DataManager.apply_ego_to_item(item, ego)
	assert_true("SLAY_ORC" in item.flags, "Should merge new flags")
	# Count LIGHT occurrences — should be 1 (no duplicates)
	var light_count: int = 0
	for f in item.flags:
		if f == "LIGHT":
			light_count += 1
	assert_eq(light_count, 1, "Should not duplicate existing flags")

func test_apply_ego_merges_abilities():
	var item := DataManager.ItemData.new()
	var ego := DataManager.EgoData.new()
	ego.granted_abilities = [[0, 5]]  # Follow-Through
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.granted_abilities.size(), 1, "Should have one granted ability")
	assert_eq(item.granted_abilities[0], [0, 5], "Should grant ability 0/5")

func test_apply_ego_modifies_damage_dice():
	var item := DataManager.ItemData.new()
	item.damage_dice = "2d5"
	var ego := DataManager.EgoData.new()
	ego.plus_damage_dice = 1
	ego.plus_damage_sides = 0
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.damage_dice, "3d5", "Should add 1 damage die")

func test_apply_ego_modifies_damage_sides():
	var item := DataManager.ItemData.new()
	item.damage_dice = "2d5"
	var ego := DataManager.EgoData.new()
	ego.plus_damage_dice = 0
	ego.plus_damage_sides = 2
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.damage_dice, "2d7", "Should add 2 damage sides")

func test_apply_ego_modifies_prot_dice():
	var item := DataManager.ItemData.new()
	item.protection_dice = "1d4"
	var ego := DataManager.EgoData.new()
	ego.plus_prot_dice = 0
	ego.plus_prot_sides = 1
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.protection_dice, "1d5", "Should add 1 protection side")

func test_apply_ego_modifies_prot_dice_count():
	var item := DataManager.ItemData.new()
	item.protection_dice = "1d4"
	var ego := DataManager.EgoData.new()
	ego.plus_prot_dice = 1
	ego.plus_prot_sides = 0
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.protection_dice, "2d4", "Should add 1 protection die")

func test_apply_ego_sets_tracking_fields():
	var item := DataManager.ItemData.new()
	item.name = "Shield"
	var ego := DataManager.EgoData.new()
	ego.name = "of Protection"
	ego.index = 1
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.ego_name, "of Protection", "Should set ego_name")
	assert_eq(item.ego_index, 1, "Should set ego_index")

func test_apply_ego_adds_attack_bonus():
	var item := DataManager.ItemData.new()
	item.attack_bonus = 0
	var ego := DataManager.EgoData.new()
	ego.max_attack = 2
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.attack_bonus, 2, "Should add attack bonus")

func test_apply_ego_adds_evasion_bonus():
	var item := DataManager.ItemData.new()
	item.evasion_bonus = 0
	var ego := DataManager.EgoData.new()
	ego.max_evasion = 3
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.evasion_bonus, 3, "Should add evasion bonus")

func test_apply_ego_adds_pval():
	var item := DataManager.ItemData.new()
	item.pval = 0
	var ego := DataManager.EgoData.new()
	ego.pval = 2
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.pval, 2, "Should add pval")

func test_apply_ego_stacks_attack_bonus():
	var item := DataManager.ItemData.new()
	item.attack_bonus = 3
	var ego := DataManager.EgoData.new()
	ego.max_attack = 2
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.attack_bonus, 5, "Should stack attack bonus on existing")

func test_apply_ego_no_damage_modification_when_zero():
	var item := DataManager.ItemData.new()
	item.damage_dice = "2d5"
	var ego := DataManager.EgoData.new()
	ego.plus_damage_dice = 0
	ego.plus_damage_sides = 0
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.damage_dice, "2d5", "Should not modify damage when bonuses are 0")

func test_apply_real_ego_gondolin_to_sword():
	# Integration: apply actual loaded ego 21 to a sword
	var ego: DataManager.EgoData = DataManager.egos.get(21)
	assert_not_null(ego, "Ego 21 should exist")
	var item := DataManager.ItemData.new()
	item.name = "Longsword"
	item.damage_dice = "2d5"
	item.flags = [] as Array[String]
	item.granted_abilities = []
	DataManager.apply_ego_to_item(item, ego)
	assert_eq(item.name, "Longsword of Gondolin", "Should have correct suffixed name")
	assert_true("SLAY_ORC" in item.flags, "Should inherit SLAY_ORC flag")
	assert_true("SLAY_TROLL" in item.flags, "Should inherit SLAY_TROLL flag")
	assert_true("LIGHT" in item.flags, "Should inherit LIGHT flag")
	assert_eq(item.ego_index, 21, "Should track ego index")

# ============================================================================
# 4. LOOT CURVE TESTS — _roll_loot_tier probabilities
# ============================================================================

func test_loot_tier_floor_1_mostly_mundane():
	# Run 1000 rolls at depth 1 — expect ~90% mundane
	var mundane_count: int = 0
	var generator := DungeonGenerator.new()
	for i in range(1000):
		var tier: String = generator._roll_loot_tier(1)
		if tier == "mundane":
			mundane_count += 1
	# Allow variance: 80% to 96%
	assert_gt(mundane_count, 800, "Floor 1 should be ~90%% mundane (got %d/1000)" % mundane_count)
	assert_lt(mundane_count, 960, "Floor 1 should not be >96%% mundane (got %d/1000)" % mundane_count)

func test_loot_tier_floor_20_less_mundane():
	var mundane_count: int = 0
	var generator := DungeonGenerator.new()
	for i in range(1000):
		var tier: String = generator._roll_loot_tier(20)
		if tier == "mundane":
			mundane_count += 1
	# Floor 20: mundane = 35%
	assert_lt(mundane_count, 500, "Floor 20 should be <50%% mundane (got %d/1000)" % mundane_count)

func test_loot_tier_all_valid():
	var generator := DungeonGenerator.new()
	var valid_tiers: Array[String] = ["mundane", "minor", "major", "artifact"]
	for depth in range(1, 21):
		var tier: String = generator._roll_loot_tier(depth)
		assert_true(tier in valid_tiers, "Tier '%s' at depth %d should be valid" % [tier, depth])

func test_loot_tier_floor_3_no_artifact():
	# At depth 1-3, artifact chance should be 0% (mundane=90, minor=8, major=2 fills 100)
	var generator := DungeonGenerator.new()
	var artifact_count: int = 0
	for i in range(500):
		if generator._roll_loot_tier(3) == "artifact":
			artifact_count += 1
	assert_eq(artifact_count, 0, "Floor 3 should have 0%% artifact chance")

func test_loot_tier_deep_has_artifacts():
	var generator := DungeonGenerator.new()
	var artifact_count: int = 0
	for i in range(2000):
		if generator._roll_loot_tier(20) == "artifact":
			artifact_count += 1
	# Floor 20: artifact = 20%  →  expect ~400 in 2000 rolls, check >200
	assert_gt(artifact_count, 200, "Floor 20 should have ~20%% artifact chance (got %d/2000)" % artifact_count)

func test_loot_tier_floor_7_has_minor():
	var generator := DungeonGenerator.new()
	var minor_count: int = 0
	for i in range(1000):
		if generator._roll_loot_tier(7) == "minor":
			minor_count += 1
	# Floor 7-9: minor = 12%
	assert_gt(minor_count, 50, "Floor 7 should have minor loot (got %d/1000)" % minor_count)

func test_loot_tier_floor_7_has_artifacts():
	# Floor 7-9: artifact = 2%
	var generator := DungeonGenerator.new()
	var artifact_count: int = 0
	for i in range(2000):
		if generator._roll_loot_tier(7) == "artifact":
			artifact_count += 1
	assert_gt(artifact_count, 5, "Floor 7 should have some artifact chance (got %d/2000)" % artifact_count)

# ============================================================================
# 5. TOOLTIP DICTIONARY TESTS
# ============================================================================

func test_tooltip_slay_orc_description():
	assert_true("SLAY_ORC" in TooltipManager.FLAG_DESCRIPTIONS, "SLAY_ORC should have a description")
	assert_eq(TooltipManager.FLAG_DESCRIPTIONS["SLAY_ORC"], "Deadly against orcs")

func test_tooltip_brand_fire_description():
	assert_true("BRAND_FIRE" in TooltipManager.FLAG_DESCRIPTIONS, "BRAND_FIRE should have a description")
	assert_eq(TooltipManager.FLAG_DESCRIPTIONS["BRAND_FIRE"], "Burns with fire")

func test_tooltip_vampiric_description():
	assert_true("VAMPIRIC" in TooltipManager.FLAG_DESCRIPTIONS, "VAMPIRIC should have a description")
	assert_eq(TooltipManager.FLAG_DESCRIPTIONS["VAMPIRIC"], "Drains life from foes")

func test_tooltip_accurate_description():
	assert_true("ACCURATE" in TooltipManager.FLAG_DESCRIPTIONS, "ACCURATE should have a description")
	assert_eq(TooltipManager.FLAG_DESCRIPTIONS["ACCURATE"], "Strikes with precision (+3 attack)")

func test_tooltip_negative_flags_list():
	assert_true("HUNGER" in TooltipManager.NEGATIVE_FLAGS, "HUNGER should be in negative flags")
	assert_true("AGGRAVATE" in TooltipManager.NEGATIVE_FLAGS, "AGGRAVATE should be in negative flags")
	assert_true("VUL_FIRE" in TooltipManager.NEGATIVE_FLAGS, "VUL_FIRE should be in negative flags")
	assert_true("CUMBERSOME" in TooltipManager.NEGATIVE_FLAGS, "CUMBERSOME should be in negative flags")
	assert_false("SLAY_ORC" in TooltipManager.NEGATIVE_FLAGS, "SLAY_ORC should NOT be in negative flags")
	assert_false("LIGHT" in TooltipManager.NEGATIVE_FLAGS, "LIGHT should NOT be in negative flags")

func test_tooltip_stat_flag_has_3_tiers():
	assert_true("STR" in TooltipManager.STAT_FLAG_DESCRIPTIONS, "STR should have stat descriptions")
	assert_eq(TooltipManager.STAT_FLAG_DESCRIPTIONS["STR"].size(), 3, "STR should have 3 tiers")
	assert_eq(TooltipManager.STAT_FLAG_DESCRIPTIONS["STR"][0], "Slightly strengthens")
	assert_eq(TooltipManager.STAT_FLAG_DESCRIPTIONS["STR"][2], "Greatly strengthens")

func test_tooltip_all_stats_have_3_tiers():
	for stat in ["STR", "DEX", "CON", "GRA"]:
		assert_true(stat in TooltipManager.STAT_FLAG_DESCRIPTIONS, "%s should have stat descriptions" % stat)
		assert_eq(TooltipManager.STAT_FLAG_DESCRIPTIONS[stat].size(), 3, "%s should have 3 tiers" % stat)

func test_tooltip_negative_stat_flags():
	for neg_stat in ["NEG_STR", "NEG_DEX", "NEG_CON", "NEG_GRA"]:
		assert_true(neg_stat in TooltipManager.STAT_FLAG_DESCRIPTIONS, "%s should have descriptions" % neg_stat)
		assert_true(neg_stat in TooltipManager.NEGATIVE_FLAGS, "%s should be in NEGATIVE_FLAGS" % neg_stat)

func test_tooltip_skill_flags():
	assert_true("STEALTH" in TooltipManager.SKILL_FLAG_DESCRIPTIONS, "STEALTH should have skill descriptions")
	assert_eq(TooltipManager.SKILL_FLAG_DESCRIPTIONS["STEALTH"].size(), 2, "STEALTH should have 2 tiers")

func test_tooltip_ability_grant_description():
	assert_true("0/4" in TooltipManager.ABILITY_GRANT_DESCRIPTIONS, "Charge should have description")
	assert_eq(TooltipManager.ABILITY_GRANT_DESCRIPTIONS["0/4"], "Grants Charge")

func test_tooltip_all_ego_abilities_have_descriptions():
	# Every ability granted by an ego should have a tooltip entry
	var missing: Array[String] = []
	for ego in DataManager.egos.values():
		for ability_ref in ego.granted_abilities:
			if ability_ref.size() >= 2:
				var key: String = "%d/%d" % [ability_ref[0], ability_ref[1]]
				if key not in TooltipManager.ABILITY_GRANT_DESCRIPTIONS:
					missing.append("Ego '%s' grants %s but no tooltip exists" % [ego.name, key])
	assert_eq(missing.size(), 0, "All ego-granted abilities should have tooltips: %s" % str(missing))

func test_tooltip_flag_descriptions_cover_all_slay():
	# All SLAY_ flags used by egos should have descriptions
	var slay_flags: Array[String] = []
	for ego in DataManager.egos.values():
		for flag in ego.flags:
			if flag.begins_with("SLAY_") and flag not in slay_flags:
				slay_flags.append(flag)
	for flag in slay_flags:
		assert_true(flag in TooltipManager.FLAG_DESCRIPTIONS, "SLAY flag '%s' should have a tooltip description" % flag)

func test_tooltip_flag_descriptions_cover_all_brand():
	# All BRAND_ flags used by egos should have descriptions
	var brand_flags: Array[String] = []
	for ego in DataManager.egos.values():
		for flag in ego.flags:
			if flag.begins_with("BRAND_") and flag not in brand_flags:
				brand_flags.append(flag)
	for flag in brand_flags:
		assert_true(flag in TooltipManager.FLAG_DESCRIPTIONS, "BRAND flag '%s' should have a tooltip description" % flag)

func test_tooltip_flag_descriptions_cover_all_res():
	# All RES_ flags used by egos should have descriptions
	var res_flags: Array[String] = []
	for ego in DataManager.egos.values():
		for flag in ego.flags:
			if flag.begins_with("RES_") and flag not in res_flags:
				res_flags.append(flag)
	for flag in res_flags:
		assert_true(flag in TooltipManager.FLAG_DESCRIPTIONS, "RES flag '%s' should have a tooltip description" % flag)
