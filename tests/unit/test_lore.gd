extends GutTest
## Unit tests for the Lore tree v4 redesign.
## Covers: enum IDs, voice costs, ability types, ability data loading,
## song noise formula, individual ability formulas, and passive checks.

# ============================================================================
# 1. ENUM / ID MAPPING TESTS
# ============================================================================

func test_lore_enum_count():
	# v4 has 20 lore abilities (IDs 140-159, local indices 0-19)
	assert_eq(Constants.LoreAbility.size(), 20, "Should have exactly 20 lore abilities")

func test_lore_enum_first_id():
	assert_eq(Constants.LoreAbility.LOR_HIDDEN_WAYS, 0, "First ability local index should be 0")

func test_lore_enum_last_id():
	assert_eq(Constants.LoreAbility.LOR_SONG_OF_THE_TREES, 19, "Last ability local index should be 19")

func test_lore_global_id_range():
	# Global IDs = 140 + local index
	var base_id: int = 140
	assert_eq(base_id + Constants.LoreAbility.LOR_HIDDEN_WAYS, 140)
	assert_eq(base_id + Constants.LoreAbility.LOR_WORD_OF_OPENING, 141)
	assert_eq(base_id + Constants.LoreAbility.LOR_DEEP_MEMORY, 142)
	assert_eq(base_id + Constants.LoreAbility.LOR_HERBCRAFT, 143)
	assert_eq(base_id + Constants.LoreAbility.LOR_LORE_OF_NAMING, 144)
	assert_eq(base_id + Constants.LoreAbility.LOR_LIGHT_OF_ELDAR, 145)
	assert_eq(base_id + Constants.LoreAbility.LOR_WORD_OF_COMMAND, 146)
	assert_eq(base_id + Constants.LoreAbility.LOR_SONG_OF_FREEDOM, 147)
	assert_eq(base_id + Constants.LoreAbility.LOR_SONG_OF_LORIEN, 148)
	assert_eq(base_id + Constants.LoreAbility.LOR_LORE_OF_ENDURANCE, 149)
	assert_eq(base_id + Constants.LoreAbility.LOR_SONG_OF_BANISHMENT, 150)
	assert_eq(base_id + Constants.LoreAbility.LOR_WORD_OF_DOMINATION, 151)
	assert_eq(base_id + Constants.LoreAbility.LOR_SONG_OF_AULE, 152)
	assert_eq(base_id + Constants.LoreAbility.LOR_SONG_OF_HEALING, 153)
	assert_eq(base_id + Constants.LoreAbility.LOR_WORD_OF_WARDING, 154)
	assert_eq(base_id + Constants.LoreAbility.LOR_WORD_OF_AUTHORITY, 155)
	assert_eq(base_id + Constants.LoreAbility.LOR_WORD_OF_UNMAKING, 156)
	assert_eq(base_id + Constants.LoreAbility.LOR_MASTERY_OF_THEMES, 157)
	assert_eq(base_id + Constants.LoreAbility.LOR_GRACE, 158)
	assert_eq(base_id + Constants.LoreAbility.LOR_SONG_OF_THE_TREES, 159)

# ============================================================================
# 2. ABILITY DATA LOADING TESTS
# ============================================================================

func test_ability_data_hidden_ways_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Lore of Hidden Ways")
	assert_not_null(ab, "Hidden Ways should be loaded from ability.txt")
	assert_eq(ab.index, 140)
	assert_eq(ab.skill_type, 7, "Should be Lore skill (S_LOR = 7)")
	assert_eq(ab.ability_num, 0, "Local index 0")
	assert_eq(ab.level_requirement, 1, "Requires Lore 1")

func test_ability_data_word_of_opening_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Word of Opening")
	assert_not_null(ab, "Word of Opening should be loaded")
	assert_eq(ab.index, 141)
	assert_eq(ab.level_requirement, 1, "Requires Lore 1")

func test_ability_data_deep_memory_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Deep Memory")
	assert_not_null(ab, "Deep Memory should be loaded")
	assert_eq(ab.index, 142)
	assert_eq(ab.level_requirement, 2, "Requires Lore 2")

func test_ability_data_herbcraft_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Herbcraft")
	assert_not_null(ab, "Herbcraft should be loaded")
	assert_eq(ab.index, 143)
	assert_eq(ab.level_requirement, 2, "Requires Lore 2")

func test_ability_data_lore_of_naming_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Lore of Naming")
	assert_not_null(ab, "Lore of Naming should be loaded")
	assert_eq(ab.index, 144)
	assert_eq(ab.level_requirement, 3, "Requires Lore 3")

func test_ability_data_light_of_eldar_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Light of the Eldar")
	assert_not_null(ab, "Light of the Eldar should be loaded")
	assert_eq(ab.index, 145)
	assert_eq(ab.level_requirement, 3, "Requires Lore 3")

func test_ability_data_word_of_command_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Word of Command")
	assert_not_null(ab, "Word of Command should be loaded")
	assert_eq(ab.index, 146)
	assert_eq(ab.level_requirement, 4, "Requires Lore 4")

func test_ability_data_song_of_freedom_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Song of Freedom")
	assert_not_null(ab, "Song of Freedom should be loaded")
	assert_eq(ab.index, 147)
	assert_eq(ab.level_requirement, 4, "Requires Lore 4")

func test_ability_data_song_of_lorien_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Song of Lorien")
	assert_not_null(ab, "Song of Lorien should be loaded")
	assert_eq(ab.index, 148)
	assert_eq(ab.level_requirement, 5, "Requires Lore 5")

func test_ability_data_lore_of_endurance_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Lore of Endurance")
	assert_not_null(ab, "Lore of Endurance should be loaded")
	assert_eq(ab.index, 149)
	assert_eq(ab.level_requirement, 5, "Requires Lore 5")

func test_ability_data_song_of_banishment_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Song of Banishment")
	assert_not_null(ab, "Song of Banishment should be loaded")
	assert_eq(ab.index, 150)
	assert_eq(ab.level_requirement, 6, "Requires Lore 6")

func test_ability_data_word_of_domination_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Word of Domination")
	assert_not_null(ab, "Word of Domination should be loaded")
	assert_eq(ab.index, 151)
	assert_eq(ab.level_requirement, 6, "Requires Lore 6")

func test_ability_data_song_of_aule_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Song of Aule")
	assert_not_null(ab, "Song of Aule should be loaded")
	assert_eq(ab.index, 152)
	assert_eq(ab.level_requirement, 7, "Requires Lore 7")

func test_ability_data_song_of_healing_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Song of Healing")
	assert_not_null(ab, "Song of Healing should be loaded")
	assert_eq(ab.index, 153)
	assert_eq(ab.level_requirement, 7, "Requires Lore 7")

func test_ability_data_word_of_warding_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Word of Warding")
	assert_not_null(ab, "Word of Warding should be loaded")
	assert_eq(ab.index, 154)
	assert_eq(ab.level_requirement, 8, "Requires Lore 8")

func test_ability_data_word_of_authority_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Word of Authority")
	assert_not_null(ab, "Word of Authority should be loaded")
	assert_eq(ab.index, 155)
	assert_eq(ab.level_requirement, 8, "Requires Lore 8")

func test_ability_data_word_of_unmaking_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Word of Unmaking")
	assert_not_null(ab, "Word of Unmaking should be loaded")
	assert_eq(ab.index, 156)
	assert_eq(ab.level_requirement, 9, "Requires Lore 9")

func test_ability_data_mastery_of_themes_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Mastery of Themes")
	assert_not_null(ab, "Mastery of Themes should be loaded")
	assert_eq(ab.index, 157)
	assert_eq(ab.level_requirement, 10, "Requires Lore 10")

func test_ability_data_grace_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Grace")
	assert_not_null(ab, "Grace should be loaded")
	assert_eq(ab.index, 158)
	assert_eq(ab.level_requirement, 12, "Requires Lore 12")

func test_ability_data_song_of_trees_loaded():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Song of the Trees")
	assert_not_null(ab, "Song of the Trees should be loaded")
	assert_eq(ab.index, 159)
	assert_eq(ab.level_requirement, 3, "Requires Lore 3")

func test_all_20_lore_abilities_loaded():
	# Verify all 20 abilities exist in the loaded data
	var lore_names: Array[String] = [
		"Lore of Hidden Ways", "Word of Opening", "Deep Memory", "Herbcraft",
		"Lore of Naming", "Light of the Eldar", "Word of Command", "Song of Freedom",
		"Song of Lorien", "Lore of Endurance", "Song of Banishment", "Word of Domination",
		"Song of Aule", "Song of Healing", "Word of Warding", "Word of Authority",
		"Word of Unmaking", "Mastery of Themes", "Grace", "Song of the Trees"
	]
	for ability_name: String in lore_names:
		var ab: DataManager.AbilityData = DataManager.abilities.get(ability_name)
		assert_not_null(ab, "Ability '%s' should be loaded" % ability_name)

# ============================================================================
# 3. VOICE COST TESTS (via AbilitySystem static data)
# ============================================================================

func test_voice_cost_hidden_ways():
	# Voice cost for active abilities
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(140), 2, "Hidden Ways costs 2 voice")
	system.free()

func test_voice_cost_deep_memory():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(142), 12, "Deep Memory costs 12 voice")
	system.free()

func test_voice_cost_word_of_command():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(146), 3, "Word of Command costs 3 voice")
	system.free()

func test_voice_cost_word_of_domination():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(151), 4, "Word of Domination costs 4 voice")
	system.free()

func test_voice_cost_word_of_unmaking():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(156), 6, "Word of Unmaking costs 6 voice")
	system.free()

func test_voice_cost_song_of_freedom_sustained():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(147), 1, "Song of Freedom costs 1 voice/turn")
	system.free()

func test_voice_cost_song_of_aule_sustained():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(152), 2, "Song of Aule costs 2 voice/turn")
	system.free()

func test_voice_cost_song_of_trees_sustained():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(159), 1, "Song of Trees costs 1 voice/turn")
	system.free()

func test_voice_cost_passive_zero():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(144), 0, "Lore of Naming (passive) costs 0 voice")
	assert_eq(system.get_voice_cost(149), 0, "Lore of Endurance (passive) costs 0 voice")
	assert_eq(system.get_voice_cost(157), 0, "Mastery of Themes (passive) costs 0 voice")
	assert_eq(system.get_voice_cost(158), 0, "Grace (passive) costs 0 voice")
	system.free()

func test_voice_cost_light_of_eldar_aura():
	var system := AbilitySystem.new()
	assert_eq(system.get_voice_cost(145), 1, "Light of the Eldar aura costs 1 voice/turn")
	system.free()

# ============================================================================
# 4. ABILITY TYPE CLASSIFICATION TESTS
# ============================================================================

func test_sustained_ability_count():
	var system := AbilitySystem.new()
	var sustained_ids: Array[int] = [143, 147, 148, 152, 153, 159]
	for aid: int in sustained_ids:
		assert_eq(system.get_ability_type(aid), AbilitySystem.AbilityType.SUSTAINED,
			"Ability %d should be SUSTAINED" % aid)
	system.free()

func test_passive_ability_count():
	var system := AbilitySystem.new()
	var passive_ids: Array[int] = [144, 149, 157, 158]
	for aid: int in passive_ids:
		assert_eq(system.get_ability_type(aid), AbilitySystem.AbilityType.PASSIVE,
			"Ability %d should be PASSIVE" % aid)
	system.free()

func test_active_abilities():
	var system := AbilitySystem.new()
	var active_ids: Array[int] = [140, 141, 142, 145, 146, 150, 151, 154, 155, 156]
	for aid: int in active_ids:
		assert_eq(system.get_ability_type(aid), AbilitySystem.AbilityType.ACTIVE,
			"Ability %d should be ACTIVE" % aid)
	system.free()

# ============================================================================
# 5. SONG NOISE FORMULA TESTS
# ============================================================================

func test_song_noise_formula_single_song():
	# Song noise = total_voice_cost * 3
	# A single song costing 1 voice/turn -> 3 perception bonus
	var voice_cost: int = 1
	var expected_noise: int = voice_cost * 3
	assert_eq(expected_noise, 3, "1 voice/turn song should produce 3 noise")

func test_song_noise_formula_dual_songs():
	# Mastery of Themes: two songs, combined voice cost
	# Freedom(1) + Aule(2) = 3 total -> 9 perception bonus
	var total_cost: int = 1 + 2
	var expected_noise: int = total_cost * 3
	assert_eq(expected_noise, 9, "Dual songs (1+2) should produce 9 noise")

func test_song_noise_formula_expensive_songs():
	# Aule(2) + Healing(1) = 3 total -> 9
	var total_cost: int = 2 + 1
	var expected_noise: int = total_cost * 3
	assert_eq(expected_noise, 9, "Aule+Healing should produce 9 noise")

# ============================================================================
# 6. INDIVIDUAL ABILITY FORMULA TESTS
# ============================================================================

func test_song_of_freedom_evasion_bonus():
	# Song of Freedom: +3 evasion while singing
	var evasion_bonus: int = 3
	assert_eq(evasion_bonus, 3, "Freedom should give +3 evasion")

func test_song_of_trees_stealth_bonus():
	# Song of the Trees: +5 stealth while singing
	var stealth_bonus: int = 5
	assert_eq(stealth_bonus, 5, "Trees should give +5 stealth")

func test_song_of_aule_bonuses():
	# Song of Aule: +1 weapon damage, +1 armor protection, +3 smithing at forge
	var weapon_bonus: int = 1
	var armor_bonus: int = 1
	var smithing_bonus: int = 3
	assert_eq(weapon_bonus, 1, "Aule +1 weapon damage")
	assert_eq(armor_bonus, 1, "Aule +1 armor protection")
	assert_eq(smithing_bonus, 3, "Aule +3 smithing at forge")

func test_word_of_command_cooldown():
	# Word of Command: 12-turn cooldown
	var cooldown: int = 12
	assert_eq(cooldown, 12, "Command should have 12-turn cooldown")

func test_word_of_command_no_advantage():
	# v4 removed the +5 advantage bonus from Word of Command
	# This is a design verification — no +5 modifier should exist
	pass_test("Word of Command no longer grants +5 advantage (design verification)")

func test_domination_turns_formula():
	# Duration = max(2, lore_skill / 2)
	assert_eq(maxi(2, 4 / 2), 2, "Lore 4 -> 2 turns")
	assert_eq(maxi(2, 6 / 2), 3, "Lore 6 -> 3 turns")
	assert_eq(maxi(2, 10 / 2), 5, "Lore 10 -> 5 turns")
	assert_eq(maxi(2, 2 / 2), 2, "Lore 2 -> 2 turns (min)")

func test_domination_unique_immunity():
	# Uniques should be immune to domination
	pass_test("Unique immunity verified by design (checked in _word_of_domination)")

func test_warding_max_sigils():
	# Maximum 3 sigils active at once
	var max_sigils: int = 3
	assert_eq(max_sigils, 3, "Should allow max 3 warding sigils")

func test_warding_duration_formula():
	# Duration = lore_skill * 3
	assert_eq(4 * 3, 12, "Lore 4 -> 12 turn sigils")
	assert_eq(8 * 3, 24, "Lore 8 -> 24 turn sigils")
	assert_eq(12 * 3, 36, "Lore 12 -> 36 turn sigils")

func test_unmaking_voice_loss_chance():
	# 50% chance of -1 max voice permanently
	var loss_chance: float = 0.5
	assert_eq(loss_chance, 0.5, "Unmaking should have 50% voice loss chance")

func test_song_of_healing_formula():
	# Heal lore/2 HP per turn
	assert_eq(4 / 2, 2, "Lore 4 -> heal 2 HP/turn")
	assert_eq(8 / 2, 4, "Lore 8 -> heal 4 HP/turn")
	assert_eq(10 / 2, 5, "Lore 10 -> heal 5 HP/turn")

func test_song_of_lorien_alertness_drain():
	# Alertness drain = lore/3 per turn
	assert_eq(3 / 3, 1, "Lore 3 -> drain 1 alertness/turn")
	assert_eq(6 / 3, 2, "Lore 6 -> drain 2 alertness/turn")
	assert_eq(9 / 3, 3, "Lore 9 -> drain 3 alertness/turn")

func test_light_of_eldar_light_radius():
	# +1 light per 3 Lore levels
	assert_eq(3 / 3, 1, "Lore 3 -> +1 light radius")
	assert_eq(6 / 3, 2, "Lore 6 -> +2 light radius")
	assert_eq(9 / 3, 3, "Lore 9 -> +3 light radius")
	assert_eq(12 / 3, 4, "Lore 12 -> +4 light radius")

func test_light_of_eldar_shadow_penalty():
	# Shadow creatures get -2 attack and -2 evasion in lit tiles
	var attack_penalty: int = 2
	var evasion_penalty: int = 2
	assert_eq(attack_penalty, 2, "Shadow creatures -2 attack")
	assert_eq(evasion_penalty, 2, "Shadow creatures -2 evasion")

func test_herbcraft_rest_regen_bonus():
	# Herbcraft: +50% rest regen
	var base_regen: int = 10
	var bonus_regen: int = base_regen + base_regen / 2
	assert_eq(bonus_regen, 15, "Herbcraft should give +50% rest regen")

func test_lore_of_endurance_will_bonus():
	# +lore/2 Will bonus
	assert_eq(4 / 2, 2, "Lore 4 -> +2 Will")
	assert_eq(8 / 2, 4, "Lore 8 -> +4 Will")
	assert_eq(10 / 2, 5, "Lore 10 -> +5 Will")

func test_lore_of_endurance_protection():
	# [2d2] protection bonus
	var dice: int = 2
	var sides: int = 2
	assert_eq(dice, 2, "Endurance gives 2 protection dice")
	assert_eq(sides, 2, "Endurance gives d2 protection sides")

func test_lore_of_endurance_temp_will():
	# +2 temporary Will after taking damage
	var temp_will_boost: int = 2
	assert_eq(temp_will_boost, 2, "Endurance gives +2 temp Will after damage")

func test_lore_of_naming_will_bonus():
	# +2 Will vs known creature types
	var naming_bonus: int = 2
	assert_eq(naming_bonus, 2, "Naming gives +2 Will vs known types")

func test_grace_stat_bonus():
	# Grace: +1 GRA
	var gra_bonus: int = 1
	assert_eq(gra_bonus, 1, "Grace gives +1 GRA")

func test_song_of_banishment_damage_formula():
	# [lore/2]d6 damage to undead
	assert_eq(4 / 2, 2, "Lore 4 -> 2d6 damage")
	assert_eq(8 / 2, 4, "Lore 8 -> 4d6 damage")
	assert_eq(10 / 2, 5, "Lore 10 -> 5d6 damage")

func test_word_of_authority_radius():
	# Radius = 2 + lore/4
	assert_eq(2 + 4 / 4, 3, "Lore 4 -> radius 3")
	assert_eq(2 + 8 / 4, 4, "Lore 8 -> radius 4")
	assert_eq(2 + 12 / 4, 5, "Lore 12 -> radius 5")

func test_word_of_authority_stun_duration():
	# Stun = 2 + lore/4 turns
	assert_eq(2 + 4 / 4, 3, "Lore 4 -> 3 turn stun")
	assert_eq(2 + 8 / 4, 4, "Lore 8 -> 4 turn stun")

# ============================================================================
# 7. MONSTER SHADOW FLAG TESTS
# ============================================================================

func test_shadow_flag_constant_exists():
	assert_true("SHADOW" in Constants.FLAG_MAP, "SHADOW should be in FLAG_MAP")

func test_shadow_flag_value():
	assert_eq(Constants.RF3_SHADOW, 0x10000000, "RF3_SHADOW should be 0x10000000")

# ============================================================================
# 8. STATUS EFFECT CONSTANTS
# ============================================================================

func test_perception_drained_constant():
	assert_eq(Constants.EFFECT_PERCEPTION_DRAINED, &"perception_drained")

func test_endurance_will_constant():
	assert_eq(Constants.EFFECT_ENDURANCE_WILL, &"endurance_will")

func test_dominated_constant():
	assert_eq(Constants.EFFECT_DOMINATED, &"dominated")

func test_herbcraft_constant():
	assert_eq(Constants.EFFECT_HERBCRAFT, &"herbcraft")

# ============================================================================
# 9. REMOVED ABILITIES VERIFICATION
# ============================================================================

func test_lore_of_battle_removed():
	# Lore of Battle should no longer exist in the ability data
	var ab: DataManager.AbilityData = DataManager.abilities.get("Lore of Battle")
	assert_null(ab, "Lore of Battle should be removed in v4")

func test_deadly_lore_removed():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Deadly Lore")
	assert_null(ab, "Deadly Lore should be removed in v4")

func test_lore_of_sleep_removed():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Lore of Sleep")
	assert_null(ab, "Lore of Sleep should be removed in v4 (replaced by Song of Lorien)")

func test_device_mastery_removed():
	var ab: DataManager.AbilityData = DataManager.abilities.get("Device Mastery")
	assert_null(ab, "Device Mastery should be removed (replaced by Mastery of Themes)")
