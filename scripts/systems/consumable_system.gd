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
	GameManager.identify_item(item)

	match sval:
		5:  # Emptiness herb - drains hunger!
			player.hunger = maxi(0, player.hunger - 1000)
			player.restore_hunger(0)  # Trigger state update
			GameManager.log_message("A gnawing emptiness fills your stomach!", ThemeColors.MSG_ERROR)
		12:  # Phosphorescent Moss - grants +1 light radius for 50 turns
			player.apply_status(Constants.EFFECT_PHOSPHOR, 50)
			player.restore_hunger(250)
			GameManager.log_message("The glowing moss fills you with a warm luminescence. You glow faintly!", ThemeColors.MSG_INFO)
		35:  # Travel Bread - basic sustenance + hunger restore
			player.heal(randi_range(2, 8), player)
			player.restore_hunger(500)
			GameManager.log_message("You eat the bread. It's stale but filling.", ThemeColors.TEXT_PRIMARY)
		36:  # Dried Meat - solid sustenance + hunger restore
			player.heal(randi_range(3, 10), player)
			player.restore_hunger(700)
			GameManager.log_message("You chew the tough dried meat. It fills you up.", ThemeColors.TEXT_PRIMARY)
		37:  # Fragment of Lembas - good healing + major hunger restore
			player.heal(randi_range(10, 20), player)
			player.restore_hunger(1000)
			GameManager.log_message("The Elvish waybread fills you with renewed vigor.", ThemeColors.HEALTH_HIGH)
		_:
			# Generic herb - minor healing + small hunger restore
			player.heal(randi_range(1, 6), player)
			player.restore_hunger(200)
			GameManager.log_message("You eat the herb.", ThemeColors.TEXT_PRIMARY)

	if player.run_stats:
		player.run_stats.herbs_consumed += 1

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
			GameManager.log_message("A bright light floods the area!", ThemeColors.MSG_WARNING)
		1:  # Sanctity - remove curses (placeholder)
			GameManager.log_message("You feel a holy presence.", ThemeColors.SECONDARY)
		2:  # Understanding - identify all inventory items
			for inv_item in player.inventory:
				GameManager.identify_item(inv_item)
			GameManager.log_message("You understand your possessions!", ThemeColors.MSG_INFO)
		3:  # Self Knowledge - reveal stats
			GameManager.log_message("You gain insight into yourself.", ThemeColors.MSG_INFO)
		4:  # Warding - temporary protection bonus
			player.apply_status("warded", 20 + randi_range(1, 10))
			GameManager.log_message("You feel protected.", ThemeColors.SECONDARY)
		5:  # Recharging (placeholder)
			GameManager.log_message("Energy crackles around your equipment.", ThemeColors.MSG_WARNING)
		_:
			GameManager.log_message("You read the scroll. The text fades.", ThemeColors.TEXT_PRIMARY)

	return true

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
		_:
			GameManager.log_message("You can't use that.", ThemeColors.MSG_SYSTEM)
			return false
