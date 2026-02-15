extends Node
class_name ConsumableSystem
## Handles use of consumable items: potions, scrolls, food/herbs, staves, wands.

# ============================================================================
# POTION EFFECTS (tval 75)
# ============================================================================

## Use a potion on the player. Returns true if consumed.
static func quaff_potion(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item or item.tval != 75:
		return false

	var sval: int = item.sval if "sval" in item else 0
	var consumed: bool = true

	# Auto-identify on use
	GameManager.identify_item(item)

	match sval:
		0:  # Miruvor - full healing + cure all
			player.heal(player.max_health, player)
			player.remove_status("poisoned")
			player.remove_status("confused")
			player.remove_status("blind")
			player.remove_status("afraid")
			GameManager.log_message("You feel completely restored!", ThemeColors.HEALTH_HIGH)
		2:  # Orcish Liquor - small heal + confusion chance
			player.heal(randi_range(5, 15), player)
			if randi_range(1, 3) == 1:
				player.apply_status("confused", 3)
				GameManager.log_message("The foul brew makes your head spin!", ThemeColors.MSG_WARNING)
			else:
				GameManager.log_message("You gulp the harsh liquor.", ThemeColors.TEXT_PRIMARY)
		3:  # Esgalduin - moderate healing
			var heal_amount: int = randi_range(10, 25)
			player.heal(heal_amount, player)
			GameManager.log_message("You feel much better.", ThemeColors.HEALTH_HIGH)
		4:  # Clarity - cure confusion + blind
			player.remove_status("confused")
			player.remove_status("blind")
			player.remove_status("image")
			GameManager.log_message("Your mind clears.", ThemeColors.MSG_INFO)
		5:  # Cordial of the Wise - restore Grace
			player.grace = maxi(player.grace, player.grace + 1)
			GameManager.log_message("You feel wiser.", ThemeColors.SECONDARY)
		6:  # Voice - restore voice charges
			player.voice_charges = player.max_voice
			GameManager.log_message("Your voice is restored!", ThemeColors.SECONDARY)
		7:  # True Sight - cure blind + temporary enhanced vision
			player.remove_status("blind")
			player.remove_status("darkened")
			GameManager.log_message("Your vision sharpens!", ThemeColors.MSG_INFO)
		8:  # Antidote - cure poison
			player.remove_status("poisoned")
			GameManager.log_message("The poison is neutralized.", ThemeColors.HEALTH_HIGH)
		9:  # Quickness - haste
			player.apply_status("fast", 10 + randi_range(1, 10))
			GameManager.log_message("You feel yourself speed up!", ThemeColors.STATUS_FAST)
		10:  # Elemental Resistance - temporary resist
			player.apply_status("resist_elements", 15 + randi_range(1, 10))
			GameManager.log_message("You feel protected from the elements.", ThemeColors.SECONDARY)
		11:  # Shadows - temporary stealth bonus
			player.apply_status("darkened", 10 + randi_range(1, 5))
			GameManager.log_message("Shadows wrap around you.", ThemeColors.MSG_STEALTH)
		14:  # Draught of Might - temporary STR boost
			player.strength += 3
			player.apply_status("might", 20 + randi_range(1, 10))
			GameManager.log_message("You feel incredibly strong!", ThemeColors.STATUS_BUFF)
		15:  # Nimble-wine - temporary DEX boost
			player.dexterity += 3
			player.apply_status("nimble", 20 + randi_range(1, 10))
			GameManager.log_message("You feel incredibly agile!", ThemeColors.STATUS_BUFF)
		16:  # Hardy-brew - temporary CON boost
			player.constitution += 3
			player.apply_status("hardy", 20 + randi_range(1, 10))
			GameManager.log_message("You feel incredibly tough!", ThemeColors.STATUS_BUFF)
		17:  # Starlight Elixir - temporary GRA boost
			player.grace += 3
			player.apply_status("starlight", 20 + randi_range(1, 10))
			GameManager.log_message("You feel a divine presence!", ThemeColors.STATUS_BUFF)
		22:  # Slowness - bad potion
			player.apply_status("slow", 10 + randi_range(1, 10))
			GameManager.log_message("You feel sluggish!", ThemeColors.MSG_ERROR)
		23:  # Poison - bad potion
			player.apply_status("poisoned", 10 + randi_range(1, 10))
			GameManager.log_message("You feel very sick!", ThemeColors.MSG_ERROR)
		24:  # Blindness - bad potion
			player.apply_status("blind", 10 + randi_range(1, 10))
			GameManager.log_message("Everything goes dark!", ThemeColors.MSG_ERROR)
		25:  # Confusion - bad potion
			player.apply_status("confused", 10 + randi_range(1, 10))
			GameManager.log_message("Your head spins violently!", ThemeColors.MSG_ERROR)
		27:  # Awkwardness - temporary DEX loss
			player.dexterity = maxi(0, player.dexterity - 3)
			player.apply_status("clumsy", 20 + randi_range(1, 10))
			GameManager.log_message("You feel clumsy!", ThemeColors.MSG_ERROR)
		29:  # Disconnection - temporary GRA loss
			player.grace = maxi(0, player.grace - 3)
			player.apply_status("disconnected", 20 + randi_range(1, 10))
			GameManager.log_message("You feel cut off from the world!", ThemeColors.MSG_ERROR)
		_:
			GameManager.log_message("You drink the potion. Nothing happens.", ThemeColors.MSG_SYSTEM)

	# Update stats
	player._recalculate_stats()

	# Track in run stats
	if player.run_stats:
		player.run_stats.potions_quaffed += 1

	return consumed

# ============================================================================
# FOOD/HERB EFFECTS (tval 80)
# ============================================================================

## Use a food item or herb. Returns true if consumed.
static func eat_food(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item or item.tval != 80:
		return false

	var sval: int = item.sval if "sval" in item else 0
	var pval: int = item.pval if "pval" in item else 0
	GameManager.identify_item(item)

	match sval:
		# ================================================================
		# BASIC HERBS (sval 0-11)
		# ================================================================
		0:  # Orc-rage Mushroom - battle rage
			var duration: int = _roll_dice(10, 4)
			_apply_rage(player, duration, 1, 1, 1, 1)
			player.remove_status("afraid")
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("A dark fury rises within you!", ThemeColors.STATUS_RAGE)
		1:  # Waymeal - major hunger restoration
			player.restore_hunger(pval if pval > 0 else 2000)
			GameManager.log_message("The traveler's herb staves off your hunger.", ThemeColors.TEXT_PRIMARY)
		2:  # Terror - fear + haste
			var fear_dur: int = _roll_dice(10, 4)
			var haste_dur: int = _roll_dice(5, 4)
			# Check fear immunity
			if player.has_ability(Constants.Skill.S_WIL, Constants.WillAbility.WIL_MAJESTY):
				GameManager.log_message("Your majesty overcomes the herb's terror!", ThemeColors.PRIMARY)
			elif player.status_fx and player.status_fx.has_effect(Constants.EFFECT_RAGE):
				GameManager.log_message("Your rage overcomes the herb's terror!", ThemeColors.STATUS_RAGE)
			else:
				player.apply_status("afraid", fear_dur)
			player.apply_status("fast", haste_dur)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("A burst of terrified energy courses through you!", ThemeColors.MSG_WARNING)
		3:  # Healer's Herb - halve cuts, heal 50% HP
			# Halve current cuts
			if player.status_fx and player.status_fx.has_effect(Constants.EFFECT_CUT):
				var cut_dur: int = player.status_fx.get_duration(Constants.EFFECT_CUT)
				var new_cut: int = cut_dur / 2
				if new_cut <= 0:
					player.remove_status("cut")
				else:
					player.status_fx.effects[Constants.EFFECT_CUT] = new_cut
			# Heal 50% of max HP (with Herbcraft bonus — requires sustained song active)
			var heal_amount: int = player.max_health / 2
			if _is_herbcraft_active(player):
				heal_amount *= 2
				GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
			player.heal(heal_amount, player)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The medicinal herb soothes your wounds.", ThemeColors.HEALTH_HIGH)
		4:  # Restoration - restore all stats by 3
			_restore_stats(player, 3)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("You feel your strength returning!", ThemeColors.ABILITY_LEARNED)
		5:  # Emptiness herb - drains hunger!
			player.hunger = maxi(0, player.hunger - 1000)
			player.restore_hunger(0)  # Trigger state update
			GameManager.log_message("A gnawing emptiness fills your stomach!", ThemeColors.MSG_ERROR)
		6:  # Visions - cure blindness + hallucination
			player.remove_status("blind")
			var hallu_dur: int = _roll_dice(80, 4)
			# Check hallucination immunity
			if player.status_fx and player.status_fx._check_resistance(Constants.EFFECT_IMAGE):
				GameManager.log_message("Your mind resists the visions.", ThemeColors.MSG_INFO)
			else:
				player.apply_status("image", hallu_dur)
				GameManager.log_message("Brilliant visions flood your mind as your sight returns!", ThemeColors.MSG_WARNING)
			player.restore_hunger(pval if pval > 0 else 250)
		7:  # Entrancement - stun/trance
			var entrance_dur: int = _roll_dice(10, 4)
			# Check free action immunity
			if player.status_fx and player.status_fx._check_resistance(Constants.EFFECT_ENTRANCED):
				GameManager.log_message("Your will resists the entrancement.", ThemeColors.MSG_INFO)
			else:
				player.apply_status("entranced", entrance_dur)
			player.restore_hunger(pval if pval > 0 else 250)
		8:  # Weakness - CURSE: permanent STR loss
			player.strength = maxi(0, player.strength - 1)
			player._recalculate_stats()
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("You feel weaker!", ThemeColors.MSG_ERROR)
		9:  # Sickness - CURSE: permanent CON loss
			player.constitution = maxi(0, player.constitution - 1)
			player._recalculate_stats()
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("You feel sickly!", ThemeColors.MSG_ERROR)
		10:  # Athelas - cure-all + heal 25%
			player.remove_status("poisoned")
			player.remove_status("afraid")
			player.remove_status("confused")
			player.remove_status("image")
			var athelas_heal: int = player.max_health / 4
			if _is_herbcraft_active(player):
				athelas_heal *= 2
				GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
			player.heal(athelas_heal, player)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The kingsfoil drives back the shadow! You feel renewed.", ThemeColors.HEALTH_HIGH)
		11:  # Pipe-weed - cure fear + temp Grace
			player.remove_status("afraid")
			# Apply temporary +3 Grace boost
			_apply_grace_boost(player, 3, 30)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("You take a few puffs. A wisp of smoke rises as your nerves steady.", ThemeColors.MSG_STEALTH)
		12:  # Phosphorescent Moss - grants +1 light radius for 50 turns
			player.apply_status(Constants.EFFECT_PHOSPHOR, 50)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The glowing moss fills you with a warm luminescence. You glow faintly!", ThemeColors.MSG_INFO)
		13:  # Silverbark Moss - cure poison + minor heal
			player.remove_status("poisoned")
			var silver_heal: int = 10
			if _is_herbcraft_active(player):
				silver_heal *= 2
				GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
			player.heal(silver_heal, player)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The silverbark moss purges the toxins from your body.", ThemeColors.HEALTH_HIGH)
		14:  # Nightshade Berry - poison damage + true sight (risk/reward)
			var poison_dmg: int = _roll_dice(3, 6)
			player.take_damage(poison_dmg, "poison", null)
			GameManager.log_message("The nightshade burns your throat! (%d damage)" % poison_dmg, ThemeColors.MSG_ERROR)
			player.apply_status("true_sight", 20)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("Your vision pierces the veil -- you can see the invisible!", ThemeColors.MSG_INFO)
		15:  # Thornvine Root - temporary +2 protection dice
			_apply_thornvine(player, 2, 30)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("Thorny vines harden beneath your skin, granting protection.", ThemeColors.SECONDARY)
		16:  # Moonpetal - restore voice charges
			var voice_restore: int = 5
			if _is_herbcraft_active(player):
				voice_restore *= 2
				GameManager.log_message("Your knowledge of herbs enhances the effect!", ThemeColors.ABILITY_LEARNED)
			player.voice_charges = mini(player.voice_charges + voice_restore, player.max_voice)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The moonpetal's essence restores your voice.", ThemeColors.SECONDARY)
		17:  # Spider-bane - blood becomes toxic to spiders
			player.apply_status("spider_bane", 50)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("A bitter taste fills your mouth. Spiders will regret biting you!", ThemeColors.MSG_WARNING)
		18:  # Gloomcap - CURSE: confusion + some hunger
			var confuse_dur: int = _roll_dice(5, 4)
			player.apply_status("confused", confuse_dur)
			player.restore_hunger(500)
			GameManager.log_message("The mushroom's spores cloud your mind, but your belly is full.", ThemeColors.MSG_ERROR)

		# ================================================================
		# IMPROVED HERBS - Alchemy Outputs (sval 20-23)
		# ================================================================
		20:  # Concentrated Healer's Herb - cure ALL cuts + heal 75% HP
			player.remove_status("cut")
			var conc_heal: int = (player.max_health * 3) / 4
			if _is_herbcraft_active(player):
				conc_heal *= 2
				GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
			player.heal(conc_heal, player)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The concentrated herbs heal your wounds completely!", ThemeColors.HEALTH_HIGH)
		21:  # Potent Athelas - full cure-all + heal 50% HP
			player.remove_status("poisoned")
			player.remove_status("afraid")
			player.remove_status("confused")
			player.remove_status("image")
			player.remove_status("blind")
			player.remove_status("stunned")
			player.remove_status("entranced")
			player.remove_status("slow")
			var potent_heal: int = player.max_health / 2
			if _is_herbcraft_active(player):
				potent_heal *= 2
				GameManager.log_message("Your knowledge of herbs enhances the healing!", ThemeColors.ABILITY_LEARNED)
			player.heal(potent_heal, player)
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("The potent kingsfoil banishes all shadow! You are fully restored.", ThemeColors.HEALTH_HIGH)
		22:  # Concentrated Waymeal - 4000 hunger
			player.restore_hunger(4000)
			GameManager.log_message("The concentrated waymeal fills you completely.", ThemeColors.TEXT_PRIMARY)
		23:  # Potent Orc-rage Mushroom - enhanced rage
			var potent_dur: int = _roll_dice(15, 4)
			_apply_rage(player, potent_dur, 2, 2, 2, 2)
			player.remove_status("afraid")
			player.restore_hunger(pval if pval > 0 else 250)
			GameManager.log_message("An overwhelming fury consumes you! You feel unstoppable!", ThemeColors.STATUS_RAGE)

		# ================================================================
		# FOOD ITEMS (sval 35-38)
		# ================================================================
		35:  # Travel Bread - basic sustenance
			player.restore_hunger(pval if pval > 0 else 1500)
			GameManager.log_message("You eat the bread. It's stale but filling.", ThemeColors.TEXT_PRIMARY)
		36:  # Dried Meat - solid sustenance
			player.restore_hunger(pval if pval > 0 else 2000)
			GameManager.log_message("You chew the tough dried meat. It fills you up.", ThemeColors.TEXT_PRIMARY)
		37:  # Fragment of Lembas - good sustenance + grace restore
			player.restore_hunger(pval if pval > 0 else 3000)
			# Restore 1 Grace if drained below base
			# (Simple approach: always +1 Grace, capped at a reasonable max)
			if player.grace < 10:  # Only restore if below a reasonable threshold
				player.grace += 1
				player._recalculate_stats()
				GameManager.log_message("The Elvish waybread fills you with renewed vigor and grace.", ThemeColors.HEALTH_HIGH)
			else:
				GameManager.log_message("The Elvish waybread fills you with renewed vigor.", ThemeColors.HEALTH_HIGH)
		38:  # Cram - filling but bland
			player.restore_hunger(pval if pval > 0 else 2000)
			GameManager.log_message("You eat the dense waybread. Filling but bland.", ThemeColors.TEXT_PRIMARY)
		_:
			# Unknown herb - minimal fallback
			player.restore_hunger(200)
			GameManager.log_message("You eat the herb. It has little effect.", ThemeColors.TEXT_PRIMARY)

	if player.run_stats:
		player.run_stats.herbs_consumed += 1

	return true

# ============================================================================
# HERB HELPER FUNCTIONS
# ============================================================================

## Check if Herbcraft sustained song is currently active (herb-doubling requires active singing)
static func _is_herbcraft_active(player: Player) -> bool:
	return player.active_song_id == 143 or player.active_song_id_2 == 143  # HERBCRAFT

## Roll NdS dice (e.g., 10d4 = roll 10 four-sided dice and sum)
static func _roll_dice(num: int, sides: int) -> int:
	var total: int = 0
	for i in range(num):
		total += randi_range(1, sides)
	return total

## Apply rage status with stat modifications tracked via metadata
static func _apply_rage(player: Player, duration: int, str_bonus: int, con_bonus: int, dex_penalty: int, gra_penalty: int) -> void:
	# If already raging, remove old rage bonuses first
	if player.status_fx and player.status_fx.has_effect(Constants.EFFECT_RAGE):
		player.status_fx.remove_effect(Constants.EFFECT_RAGE, false)

	# Apply stat changes
	player.strength += str_bonus
	player.constitution += con_bonus
	player.dexterity -= dex_penalty
	player.grace -= gra_penalty

	# Store bonuses as metadata for restoration on expiry
	player.set_meta("rage_str_bonus", str_bonus)
	player.set_meta("rage_con_bonus", con_bonus)
	player.set_meta("rage_dex_penalty", dex_penalty)
	player.set_meta("rage_gra_penalty", gra_penalty)

	player.apply_status("rage", duration)
	player._recalculate_stats()
	EventBus.status_applied.emit(player, Constants.EFFECT_RAGE, duration)

## Apply temporary Grace boost tracked via metadata
static func _apply_grace_boost(player: Player, amount: int, duration: int) -> void:
	# If already boosted, remove old bonus first
	if player.status_fx and player.status_fx.has_effect(&"grace_boost"):
		player.status_fx.remove_effect(&"grace_boost", false)

	player.grace += amount
	player.set_meta("grace_boost_amount", amount)
	player.apply_status("grace_boost", duration)
	player._recalculate_stats()

## Apply temporary protection dice bonus from Thornvine Root
static func _apply_thornvine(player: Player, dice_bonus: int, duration: int) -> void:
	# If already active, remove old bonus first
	if player.status_fx and player.status_fx.has_effect(&"thornvine"):
		player.status_fx.remove_effect(&"thornvine", false)

	player.set_temporary_protection_pool(&"thornvine", dice_bonus, 2)
	player.apply_status("thornvine", duration)

## Restore all 4 base stats by up to the given amount (won't exceed original base)
static func _restore_stats(player: Player, amount: int) -> void:
	# Simple restoration: increase each stat by amount
	# In Sil-Q, restoration returns stats drained by monsters/curse herbs
	player.strength += amount
	player.dexterity += amount
	player.constitution += amount
	player.grace += amount
	player._recalculate_stats()

# ============================================================================
# HERBCRAFT ALCHEMY SYSTEM
# ============================================================================

## Herb alchemy recipe table: sval -> output item name in DataManager
const ALCHEMY_RECIPES: Dictionary = {
	3: "& Concentrated Healer's Herb~",   # 2x Healer's Herb -> Concentrated
	10: "& Potent Athelas~",              # 2x Athelas -> Potent
	1: "& Concentrated Waymeal~",         # 2x Waymeal -> Concentrated
	0: "& Potent Orc-rage Mushroom~",     # 2x Orc-rage -> Potent
}

## Try to combine two identical herbs via Herbcraft alchemy.
## herb1_idx and herb2_idx are indices into player.inventory.
## Returns true if combining was successful.
static func try_herb_alchemy(player: Player, herb1_idx: int, herb2_idx: int) -> bool:
	# Validate indices
	if herb1_idx < 0 or herb1_idx >= player.inventory.size():
		GameManager.log_message("Invalid item selection.", ThemeColors.MSG_ERROR)
		return false
	if herb2_idx < 0 or herb2_idx >= player.inventory.size():
		GameManager.log_message("Invalid item selection.", ThemeColors.MSG_ERROR)
		return false
	if herb1_idx == herb2_idx:
		GameManager.log_message("You need two separate herbs to combine.", ThemeColors.MSG_ERROR)
		return false

	# Check Herbcraft ability
	if not player.has_ability(Constants.Skill.S_LOR, Constants.LoreAbility.LOR_HERBCRAFT):
		GameManager.log_message("You lack the Herbcraft knowledge to combine herbs.", ThemeColors.MSG_ERROR)
		return false

	var herb1: Variant = player.inventory[herb1_idx]
	var herb2: Variant = player.inventory[herb2_idx]

	# Both must be herbs (tval 80)
	if not "tval" in herb1 or herb1.tval != 80:
		GameManager.log_message("That is not a herb.", ThemeColors.MSG_ERROR)
		return false
	if not "tval" in herb2 or herb2.tval != 80:
		GameManager.log_message("That is not a herb.", ThemeColors.MSG_ERROR)
		return false

	# Both must be the same sval (same herb type)
	var herb_sval: int = herb1.sval if "sval" in herb1 else -1
	var herb2_sval: int = herb2.sval if "sval" in herb2 else -2
	if herb_sval != herb2_sval:
		GameManager.log_message("You can only combine identical herbs.", ThemeColors.MSG_ERROR)
		return false

	# Check if this herb has a recipe
	if not ALCHEMY_RECIPES.has(herb_sval):
		GameManager.log_message("These herbs cannot be combined.", ThemeColors.MSG_SYSTEM)
		return false

	# Look up the output item from DataManager
	var output_name: String = ALCHEMY_RECIPES[herb_sval]
	var output_template: Variant = DataManager.get_item(output_name)
	if output_template == null:
		GameManager.log_message("Something went wrong with the alchemy.", ThemeColors.MSG_ERROR)
		return false

	# Create a new item instance (copy from template)
	var new_item: DataManager.ItemData = DataManager.ItemData.new()
	new_item.index = output_template.index
	new_item.name = output_template.name
	new_item.display_char = output_template.display_char
	new_item.color = output_template.color
	new_item.tval = output_template.tval
	new_item.sval = output_template.sval
	new_item.pval = output_template.pval
	new_item.depth = output_template.depth
	new_item.rarity = output_template.rarity
	new_item.weight = output_template.weight
	new_item.cost = output_template.cost
	new_item.flags = output_template.flags.duplicate()
	new_item.description = output_template.description
	new_item.identified = true  # Player created it, so it's identified

	# Remove the two input herbs (remove higher index first to avoid shifting)
	var idx_high: int = maxi(herb1_idx, herb2_idx)
	var idx_low: int = mini(herb1_idx, herb2_idx)
	player.inventory.remove_at(idx_high)
	player.inventory.remove_at(idx_low)

	# Add the output herb to inventory
	player.inventory.append(new_item)

	var herb_name: String = herb1.name if "name" in herb1 else "herb"
	GameManager.log_message("You carefully combine two %s into %s!" % [herb_name, new_item.name], ThemeColors.ABILITY_LEARNED)
	EventBus.item_used.emit(player, new_item)

	return true

# ============================================================================
# SCROLL EFFECTS (tval 55)
# ============================================================================

## Use a scroll. Returns true if consumed.
static func read_scroll(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item or item.tval != 55:
		return false

	# Can't read when blind
	if player.status_fx and player.status_fx.is_blind():
		GameManager.log_message("You can't read while blind!", ThemeColors.MSG_ERROR)
		return false

	var sval: int = item.sval if "sval" in item else 0
	GameManager.identify_item(item)

	# Confused reading has a backfire chance
	if player.status_fx and player.status_fx.is_confused():
		if randi_range(1, 3) == 1:
			GameManager.log_message("The words swim before your eyes! The scroll crumbles.", ThemeColors.MSG_ERROR)
			return true  # Consumed but no effect

	match sval:
		0:  # Light
			var revealed_tiles: int = _reveal_area(player, 8)
			GameManager.log_message("A bright light floods the area! (%d tiles revealed)" % revealed_tiles, ThemeColors.MSG_WARNING)
		1:  # Sanctity - purge lingering afflictions and light curses
			var cleansed_effects: int = _cleanse_negative_effects(player)
			var cleansed_items: int = _remove_light_curses(player)
			if cleansed_effects > 0 or cleansed_items > 0:
				GameManager.log_message(
					"Holy grace cleanses %d affliction%s and %d cursed item%s." % [
						cleansed_effects, "s" if cleansed_effects != 1 else "",
						cleansed_items, "s" if cleansed_items != 1 else ""
					],
					ThemeColors.ABILITY_LEARNED
				)
			else:
				GameManager.log_message("A holy calm settles over you, but there is little to cleanse.", ThemeColors.SECONDARY)
		2:  # Understanding - identify all inventory items
			for inv_item in player.inventory:
				GameManager.identify_item(inv_item)
			GameManager.log_message("You understand your possessions!", ThemeColors.MSG_INFO)
		3:  # Self Knowledge - reveal stats
			GameManager.log_message("You gain insight into yourself.", ThemeColors.MSG_INFO)
		4:  # Warding - temporary protection bonus
			_apply_thornvine(player, 1, 20 + randi_range(1, 10))
			GameManager.log_message("You feel protected.", ThemeColors.SECONDARY)
		5:  # Recharging - refill devices with charges
			var recharge: Dictionary = _recharge_devices(player)
			if recharge.items > 0:
				GameManager.log_message(
					"Energy crackles through %d device%s (+%d charges)." % [
						recharge.items, "s" if recharge.items != 1 else "", recharge.total_charges
					],
					ThemeColors.MSG_WARNING
				)
			else:
				GameManager.log_message("Energy crackles... but you carry no chargeable devices.", ThemeColors.MSG_SYSTEM)
		_:
			GameManager.log_message("You read the scroll. The text fades.", ThemeColors.TEXT_PRIMARY)

	return true

## Reveal explored/visible tiles around player and refresh floor visuals.
static func _reveal_area(player: Player, radius: int) -> int:
	if not GameManager.current_level:
		return 0
	var level: Level = GameManager.current_level
	var center: Vector2i = player.grid_position
	var revealed: int = 0
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos: Vector2i = center + Vector2i(dx, dy)
			if not level.is_in_bounds(pos):
				continue
			if maxi(absi(dx), absi(dy)) > radius:
				continue
			var idx: int = pos.y * level.width + pos.x
			if not level.explored[idx]:
				revealed += 1
			level.set_explored(pos, true)
			level.set_tile_visible(pos, true)
	level.apply_fov_to_tilemap()
	return revealed

## Remove common negative statuses from the player.
static func _cleanse_negative_effects(player: Player) -> int:
	if not player.status_fx:
		return 0
	var cleansed: int = 0
	var removable: Array[StringName] = [
		Constants.EFFECT_POISONED,
		Constants.EFFECT_CUT,
		Constants.EFFECT_BURNING,
		Constants.EFFECT_CONFUSED,
		Constants.EFFECT_AFRAID,
		Constants.EFFECT_STUNNED,
		Constants.EFFECT_ENTRANCED,
		Constants.EFFECT_IMAGE,
		Constants.EFFECT_BLIND,
	]
	for effect_id in removable:
		if player.status_fx.has_effect(effect_id):
			player.status_fx.remove_effect(effect_id, false)
			cleansed += 1
	player._sync_status_dict()
	return cleansed

## Remove removable light curses from equipment and inventory.
static func _remove_light_curses(player: Player) -> int:
	var cleansed: int = 0
	var slots: Array[String] = ["weapon", "offhand", "armor", "head", "light", "amulet"]
	for slot in slots:
		var item = player.equipment.get(slot)
		if item == null or "flags" not in item:
			continue
		var idx: int = item.flags.find("LIGHT_CURSE")
		if idx >= 0:
			item.flags.remove_at(idx)
			cleansed += 1
	for item in player.inventory:
		if item == null or "flags" not in item:
			continue
		var idx: int = item.flags.find("LIGHT_CURSE")
		if idx >= 0:
			item.flags.remove_at(idx)
			cleansed += 1
	player._recalculate_stats()
	return cleansed

## Recharge charged devices (wands/staves) carried by the player.
static func _recharge_devices(player: Player) -> Dictionary:
	var affected: int = 0
	var total_added: int = 0
	var device_tvals: Array[int] = [56, 57]
	var all_items: Array = []
	for item in player.inventory:
		all_items.append(item)
	var slots: Array[String] = ["weapon", "offhand", "armor", "head", "light", "amulet"]
	for slot in slots:
		var equipped = player.equipment.get(slot)
		if equipped != null:
			all_items.append(equipped)
	for item in all_items:
		if item == null or "tval" not in item:
			continue
		if not (item.tval in device_tvals):
			continue
		if "pval" not in item:
			continue
		var gain: int = randi_range(2, 6)
		item.pval += gain
		total_added += gain
		affected += 1
	return {"items": affected, "total_charges": total_added}

# ============================================================================
# WAND USE (tval 56)
# ============================================================================

## Zap a wand in a direction. Returns true if charges were consumed.
static func zap_wand(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item or item.tval != 56:
		return false

	# Check charges
	var charges: int = item.pval if "pval" in item else 0
	if charges <= 0:
		GameManager.log_message("The wand has no charges remaining.", ThemeColors.MSG_SYSTEM)
		return false

	var sval: int = item.sval if "sval" in item else 0
	GameManager.identify_item(item)

	# Consume a charge
	if "pval" in item:
		item.pval -= 1

	match sval:
		0:  # Wand of Frost
			GameManager.log_message("A bolt of frost shoots from the wand!", ThemeColors.MSG_INFO)
			_wand_bolt_effect(player, "cold", randi_range(3, 12))
		1:  # Wand of Fire
			GameManager.log_message("A bolt of fire shoots from the wand!", ThemeColors.DMG_FIRE)
			_wand_bolt_effect(player, "fire", randi_range(3, 12))
		2:  # Wand of Slowing
			GameManager.log_message("A ray of lethargy shoots from the wand!", ThemeColors.MSG_SYSTEM)
			_wand_status_effect(player, "slow", 5 + randi_range(1, 5))
		3:  # Wand of Light
			GameManager.log_message("A brilliant light shines from the wand!", ThemeColors.MSG_WARNING)
		4:  # Wand of Fear
			GameManager.log_message("A wave of terror emanates from the wand!", ThemeColors.STATUS_AFRAID)
			_wand_status_effect(player, "afraid", 5 + randi_range(1, 5))
		5:  # Wand of Sleep
			GameManager.log_message("A drowsy mist flows from the wand!", ThemeColors.MSG_STEALTH)
		_:
			GameManager.log_message("Nothing happens.", ThemeColors.MSG_SYSTEM)

	return true

## Apply bolt damage to nearest enemy in player's facing direction
static func _wand_bolt_effect(player: Player, damage_type: String, damage: int) -> void:
	if not GameManager.current_level:
		return
	# Hit nearest visible monster
	var nearest: Entity = null
	var nearest_dist: int = 999
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			continue
		var dist: int = max(abs(entity.grid_position.x - player.grid_position.x),
						   abs(entity.grid_position.y - player.grid_position.y))
		if dist < nearest_dist:
			nearest = entity
			nearest_dist = dist
	if nearest:
		nearest.take_damage(damage, damage_type, player)

## Apply status effect to nearest visible monster
static func _wand_status_effect(player: Player, effect: String, duration: int) -> void:
	if not GameManager.current_level:
		return
	var nearest: Entity = null
	var nearest_dist: int = 999
	for entity in GameManager.current_level.entities:
		if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
			continue
		if not GameManager.current_level.is_tile_visible(entity.grid_position):
			continue
		var dist: int = max(abs(entity.grid_position.x - player.grid_position.x),
						   abs(entity.grid_position.y - player.grid_position.y))
		if dist < nearest_dist:
			nearest = entity
			nearest_dist = dist
	if nearest:
		nearest.apply_status(effect, duration)
		GameManager.log_message("The %s is affected!" % nearest.entity_name, ThemeColors.MSG_INFO)

# ============================================================================
# FLASK EFFECTS (tval 77)
# ============================================================================

## Use a flask on the player's equipped light source. Returns true if consumed.
static func use_flask(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item or item.tval != 77:
		return false

	var sval: int = item.sval if "sval" in item else 0
	GameManager.identify_item(item)

	var light_item = player.equipment.get("light")
	if light_item == null:
		GameManager.log_message("You have no light source equipped to refuel.", ThemeColors.MSG_SYSTEM)
		return false

	var light_sval: int = light_item.sval if "sval" in light_item else -1

	match sval:
		0:  # Flask of Oil - refuels brass lantern
			if light_sval != 1:  # sval 1 = Brass Lantern
				GameManager.log_message("Oil can only refuel a brass lantern.", ThemeColors.MSG_SYSTEM)
				return false
			if not "fuel" in light_item:
				GameManager.log_message("This light source doesn't use fuel.", ThemeColors.MSG_SYSTEM)
				return false
			var fuel_add: int = item.pval if "pval" in item else 3000
			light_item.fuel = mini(light_item.fuel + fuel_add, 7000)
			GameManager.log_message("You refuel your lantern.", ThemeColors.MSG_INFO)
			return true
		1:  # Torch Oil - refuels wooden torch
			if light_sval != 0:  # sval 0 = Wooden Torch
				GameManager.log_message("Torch oil can only refuel a wooden torch.", ThemeColors.MSG_SYSTEM)
				return false
			if not "fuel" in light_item:
				GameManager.log_message("This light source doesn't use fuel.", ThemeColors.MSG_SYSTEM)
				return false
			var fuel_add: int = item.pval if "pval" in item else 1000
			light_item.fuel = mini(light_item.fuel + fuel_add, 3000)
			GameManager.log_message("You apply torch oil. Your torch burns brighter!", ThemeColors.MSG_INFO)
			return true
		_:
			GameManager.log_message("You can't use that.", ThemeColors.MSG_SYSTEM)
			return false

# ============================================================================
# HORN / FLUTE EFFECTS (tval 66)
# ============================================================================

## Pending horn item awaiting directional input from the player.
## Set by use_horn() when the horn requires a direction, read by main.gd.
static var _pending_horn_item: Variant = null
static var _pending_horn_player: Player = null

## Start using a horn/flute. For directional horns, sets pending state and
## returns false (item not yet consumed). For self-targeted horns, executes
## immediately and returns true.
static func use_horn(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item or item.tval != Constants.TVAL_HORN:
		return false

	var sval: int = item.sval if "sval" in item else -1

	# Self-targeted horns: execute immediately
	if sval not in Constants.HORN_DIRECTIONAL_SVALS:
		GameManager.identify_item(item)
		return HornSystem.use_horn(player, item, Vector2i.ZERO)

	# Directional horns: prompt for direction
	_pending_horn_item = item
	_pending_horn_player = player
	GameManager.log_message("Blow horn in which direction? (movement keys to aim, Escape to cancel)", ThemeColors.TEXT_PRIMARY)
	return false  # Not consumed yet - waiting for direction

## Complete a pending horn use with a direction. Called from main.gd input handler.
## Returns true if the horn was consumed (item should be removed from inventory).
## Also removes the consumed horn from player inventory automatically.
static func complete_horn_use(direction: Vector2i) -> bool:
	if _pending_horn_item == null or _pending_horn_player == null:
		return false

	var item: Variant = _pending_horn_item
	var player: Player = _pending_horn_player
	_pending_horn_item = null
	_pending_horn_player = null

	GameManager.identify_item(item)
	var success: bool = HornSystem.use_horn(player, item, direction)

	# Remove the horn from inventory if successfully used
	if success and player:
		var idx: int = player.inventory.find(item)
		if idx >= 0:
			player.inventory.remove_at(idx)

	return success

## Cancel a pending horn use.
static func cancel_horn_use() -> void:
	if _pending_horn_item != null:
		GameManager.log_message("Cancelled.", ThemeColors.MSG_SYSTEM)
	_pending_horn_item = null
	_pending_horn_player = null

## Check if there is a pending horn awaiting directional input.
static func has_pending_horn() -> bool:
	return _pending_horn_item != null

# ============================================================================
# CONSUMABLE DISPATCHER
# ============================================================================

## Use any consumable item from inventory. Returns true if item was consumed.
static func use_item(player: Player, item: Variant) -> bool:
	if item == null or not "tval" in item:
		return false

	match item.tval:
		75:  # Potion
			return quaff_potion(player, item)
		77:  # Flask (oil/torch oil)
			return use_flask(player, item)
		80:  # Food/Herb
			return eat_food(player, item)
		55:  # Scroll
			return read_scroll(player, item)
		56:  # Wand
			return zap_wand(player, item)
		66:  # Horn/Flute
			return use_horn(player, item)
		_:
			GameManager.log_message("You can't use that.", ThemeColors.MSG_SYSTEM)
			return false
