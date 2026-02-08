extends RefCounted
class_name DescriptionGenerator
## Generates procedural physical descriptions for monsters, terrain, and items.
## Dwarf Fortress-style descriptions based on monster data fields.
## Used by MonsterMemory and LookPanel for unknown/partially-known creatures.

# ============================================================================
# MONSTER DESCRIPTIONS
# ============================================================================

## Generate a physical description based on monster data and knowledge tier.
## At tier 0 (IDENTIFIED): pure physical description from display_char and color.
## At higher tiers: adds behavioral hints from flags.
## At COMPLETE tier: caller should use the D: line description instead.
static func generate_monster_description(monster_data: Dictionary, tier: int) -> String:
	var display_char: String = monster_data.get("char", "?")
	var color: String = monster_data.get("color", "w")

	# Parse HP from health_dice if available (e.g. "4d4" -> avg ~10)
	var hp: int = _estimate_hp(monster_data)

	# Size descriptor from estimated HP
	var size: String = _get_size_descriptor(hp)
	# Color descriptor from monster color code
	var color_desc: String = _get_color_descriptor(color)

	match display_char:
		"o": return _describe_orc(monster_data, size, color_desc, tier)
		"M": return _describe_spider(monster_data, size, color_desc, tier)
		"T": return _describe_troll(monster_data, size, color_desc, tier)
		"w": return _describe_warg(monster_data, size, color_desc, tier)
		"W": return _describe_wraith(monster_data, size, color_desc, tier)
		"s": return _describe_serpent(monster_data, size, color_desc, tier)
		"C": return _describe_canine(monster_data, size, color_desc, tier)
		"b": return _describe_bat(monster_data, size, color_desc, tier)
		"r": return _describe_rodent(monster_data, size, color_desc, tier)
		"z": return _describe_undead(monster_data, size, color_desc, tier)
		"v": return _describe_vampire(monster_data, size, color_desc, tier)
		"R": return _describe_demon(monster_data, size, color_desc, tier)
		"H": return _describe_horror(monster_data, size, color_desc, tier)
		"&": return _describe_plant(monster_data, size, color_desc, tier)
		"c": return _describe_centipede(monster_data, size, color_desc, tier)
		"q": return _describe_quadruped(monster_data, size, color_desc, tier)
		"@": return _describe_humanoid(monster_data, size, color_desc, tier)
		_: return _describe_generic(monster_data, size, color_desc, tier)

## Estimate HP from health_dice string (e.g. "4d4" -> average 10).
static func _estimate_hp(monster_data: Dictionary) -> int:
	var health_dice: String = monster_data.get("health_dice", "")
	if health_dice.is_empty():
		return 10  # default
	var parts: PackedStringArray = health_dice.split("d")
	if parts.size() != 2:
		return 10
	var num_dice: int = int(parts[0])
	var die_size: int = int(parts[1])
	if num_dice <= 0 or die_size <= 0:
		return 10
	# Average = num * (die+1) / 2
	return int(num_dice * (die_size + 1) / 2)

static func _get_size_descriptor(hp: int) -> String:
	if hp <= 5:
		return "tiny"
	elif hp <= 10:
		return "small"
	elif hp <= 25:
		return "medium-sized"
	elif hp <= 50:
		return "large"
	elif hp <= 80:
		return "massive"
	else:
		return "enormous"

static func _get_color_descriptor(color: String) -> String:
	# Strip trailing digit (e.g. "v1" -> "v") for extended color codes
	var base_color: String = color.left(1) if color.length() > 0 else "w"
	match base_color:
		"r": return "ruddy"
		"R": return "crimson"
		"g": return "green"
		"G": return "bright green"
		"b": return "dusky"
		"B": return "bright blue"
		"w": return "pale"
		"W": return "white"
		"d": return "pitch-black"
		"D": return "dark"
		"u": return "brown"
		"U": return "golden"
		"s": return "silver"
		"v": return "violet"
		"o": return "orange-tinged"
		"y": return "sallow"
		_: return "shadowy"

# ============================================================================
# CREATURE TYPE TEMPLATES
# ============================================================================

## Orcs (o) - humanoid warriors, soldiers of Sauron
static func _describe_orc(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s, %s-skinned humanoid with crude armor and a brutal countenance." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags or "ESCORT" in flags:
			base += " It appears to travel with others of its kind."
		if "DROP_60" in flags or "DROP_90" in flags:
			base += " It carries equipment."
		if "UNIQUE" in flags:
			base += " There is a terrible authority in its bearing."
	return base

## Spiders (M) - Mirkwood arachnids
static func _describe_spider(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s arachnid with glistening fangs and clusters of dark eyes." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "SPIDER" in flags:
			base += " Sticky webs trail from its spinnerets."
		if "RES_POIS" in flags:
			base += " Its fangs drip with venom."
		if "TERRITORIAL" in flags:
			base += " It guards this area aggressively."
	return base

## Trolls (T) - large brutes, thick-skinned
static func _describe_troll(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s, %s-hided brute with long arms and a slack jaw. Its skin looks thick and leathery." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "TROLL" in flags:
			base += " It smells of rotting meat."
		if "BASH_DOOR" in flags:
			base += " Its fists look capable of smashing through doors."
	return base

## Wargs/wolves (w) - intelligent wolf-beasts
static func _describe_warg(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s wolf-like beast with intelligent, malevolent eyes and powerful jaws." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags:
			base += " It seems to be part of a hunting pack."
		if "ORC" in flags or "ESCORT" in flags:
			base += " Crude harness marks suggest it serves as a mount."
	return base

## Wraiths (W) - spectral undead, ring-servants
static func _describe_wraith(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s figure shrouded in tattered darkness. The air grows bitterly cold in its presence." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNDEAD" in flags:
			base += " It is clearly not among the living."
		if "UNIQUE" in flags:
			base += " An aura of terrible power surrounds it."
		if "NO_FEAR" in flags:
			base += " It shows no emotion, no hesitation."
		if "PASS_WALL" in flags:
			base += " Its form seems partially insubstantial."
	return base

## Serpents (s) - snakes, worms, wyrms
static func _describe_serpent(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s serpentine creature with scales that catch the torchlight. It moves with unsettling speed." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "RES_POIS" in flags:
			base += " Venom glistens on its fangs."
		if "RES_FIRE" in flags:
			base += " Heat shimmers around its body."
	return base

## Canines (C) - dogs, hounds, wild beasts
static func _describe_canine(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s hound with bared teeth and hackles raised. Drool hangs from its jaws." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags:
			base += " Others of its kind lurk nearby."
		if "RES_FIRE" in flags:
			base += " Flames lick around its muzzle."
	return base

## Bats/birds (b) - flying creatures
static func _describe_bat(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s winged creature that darts erratically through the air." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FLYING" in flags:
			base += " It swoops and dives with surprising agility."
		if "FRIENDS" in flags:
			base += " The flutter of many more wings echoes from the darkness."
	return base

## Rodents (r) - rats, squirrels, vermin
static func _describe_rodent(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s creature scurries along the ground, its beady eyes glinting." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags:
			base += " You can hear more of them chittering in the shadows."
		if "RAND_50" in flags or "RAND_25" in flags:
			base += " It moves unpredictably, darting in random directions."
	return base

## Undead (z) - zombies, skeletons, wights
static func _describe_undead(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s figure that moves with a horrible, lurching gait. The stench of the grave clings to it." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNDEAD" in flags:
			base += " Its flesh is rotted and its eyes are hollow pits of malice."
		if "NO_FEAR" in flags:
			base += " It shows no fear, driven by a will not its own."
		if "NO_SLEEP" in flags:
			base += " It never rests, never tires."
	return base

## Vampires (v) - blood-drinkers, dark lords
static func _describe_vampire(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s, %s figure of aristocratic bearing. Its eyes gleam with a terrible hunger." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNDEAD" in flags:
			base += " An unnatural pallor marks it as one of the deathless."
		if "UNIQUE" in flags:
			base += " Dark power radiates from its form."
		if "DRAIN_EXP" in flags:
			base += " You feel your vitality waning in its presence."
	return base

## Demons/Balrogs (R) - fire creatures, Morgoth's servants
static func _describe_demon(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s creature wreathed in shadow and flame. The very air burns around it." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "RES_FIRE" in flags:
			base += " Fire seems to be its element, not its weakness."
		if "UNIQUE" in flags:
			base += " It is a being of terrible and ancient power."
	return base

## Horrors (H) - nameless things, eldritch beings
static func _describe_horror(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s thing of unspeakable form. Your mind recoils from trying to comprehend its shape." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "PASS_WALL" in flags:
			base += " It seems to exist only partially in this world."
		if "INVISIBLE" in flags:
			base += " Your eyes slide off it, as if refusing to acknowledge its existence."
	return base

## Plants/trees (&) - corrupted vegetation, tanglethorns
static func _describe_plant(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s mass of twisted vegetation, its thorned tendrils twitching with unnatural life." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "TERRITORIAL" in flags:
			base += " It seems rooted here, guarding this stretch of corridor."
		if "RES_POIS" in flags:
			base += " A sickly sap oozes from its barbs."
	return base

## Centipedes/insects (c) - many-legged crawlers
static func _describe_centipede(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s many-legged creature that scuttles across the stone with a dry clicking sound." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "RES_POIS" in flags:
			base += " Its mandibles are slick with toxin."
	return base

## Quadrupeds (q) - miscellaneous four-legged beasts
static func _describe_quadruped(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s four-legged beast with a muscular frame and wary stance." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNIQUE" in flags:
			base += " It carries itself with unnatural intelligence."
	return base

## Humanoids (@) - humans, sorcerers, named characters
static func _describe_humanoid(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s, %s-robed figure stands before you. Their posture suggests both cunning and menace." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNIQUE" in flags:
			base += " A palpable aura of power surrounds this individual."
		if "EVIL" in flags:
			base += " A dark intent burns in their eyes."
		if "UNDEAD" in flags:
			base += " Their flesh is withered, sustained by sorcery alone."
		if "ORC" in flags:
			base += " Despite humanoid shape, orcish features twist its face."
	return base

## Fallback for unrecognized display characters
static func _describe_generic(data: Dictionary, size: String, color: String, tier: int) -> String:
	var base: String = "A %s %s creature moves in the darkness ahead." % [size, color]
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNIQUE" in flags:
			base += " Something about it sets it apart from common beasts."
	return base

# ============================================================================
# PER-UNIT DF-STYLE FLAVOR TEXT
# ============================================================================

## Generate per-unit procedural flavor text from monster attributes.
## Uses HP for size, speed for movement, attacks for combat hints, flags for
## special flavor. Randomized adjectives ensure two individuals of the same
## species don't read identically.
static func generate_unit_flavor(monster_data: Dictionary) -> String:
	var parts: Array[String] = []

	# Size descriptors from HP
	var hp: int = _estimate_hp(monster_data)
	var size_adjectives: Array[String] = _get_unit_size_adjectives(hp)
	if not size_adjectives.is_empty():
		parts.append("This creature %s." % size_adjectives.pick_random())

	# Movement descriptors from speed
	var spd: int = monster_data.get("speed", 2)
	var movement: String = _get_unit_movement_descriptor(spd)
	if not movement.is_empty():
		parts.append(movement)

	# Combat hints from attacks
	var attacks: Array = monster_data.get("attacks", [])
	var combat_hint: String = _get_unit_combat_hint(attacks)
	if not combat_hint.is_empty():
		parts.append(combat_hint)

	# Flag-based flavor
	var flags: Array = monster_data.get("flags", [])
	var flag_flavor: String = _get_unit_flag_flavor(flags)
	if not flag_flavor.is_empty():
		parts.append(flag_flavor)

	return " ".join(parts)

static func _get_unit_size_adjectives(hp: int) -> Array[String]:
	if hp <= 5:
		return [
			"has a scrawny, underfed frame",
			"looks frail and wiry",
			"is pitifully small",
		]
	elif hp <= 10:
		return [
			"has a lean, hungry look",
			"is compact but alert",
			"appears gaunt and desperate",
		]
	elif hp <= 25:
		return [
			"has a sturdy build",
			"looks well-fed and strong",
			"carries itself with confidence",
		]
	elif hp <= 50:
		return [
			"is heavily muscled",
			"has a massive, powerful frame",
			"towers over lesser creatures",
		]
	else:
		return [
			"is colossal, filling the corridor",
			"has a body like a living siege engine",
			"is terrifyingly enormous",
		]

static func _get_unit_movement_descriptor(spd: int) -> String:
	var pool: Array[String] = []
	if spd <= 1:
		pool = [
			"It moves with a sluggish, ponderous gait.",
			"Each step seems to take great effort.",
			"It lumbers forward, slow but inexorable.",
		]
	elif spd == 2:
		pool = [
			"It moves at a measured, cautious pace.",
			"Its movements are deliberate and watchful.",
			"",  # Sometimes no movement descriptor for normal speed
		]
	elif spd == 3:
		pool = [
			"It moves with surprising quickness.",
			"Its feet are quick and sure.",
			"It darts forward with alarming speed.",
		]
	else:
		pool = [
			"It moves with blindingly fast reflexes.",
			"Its speed is almost impossible to track.",
			"It seems to flicker between positions.",
		]
	return pool.pick_random()

static func _get_unit_combat_hint(attacks: Array) -> String:
	if attacks.is_empty():
		return ""

	var hints: Array[String] = []
	for attack in attacks:
		if not attack is Object:
			continue
		# Check attack method if available
		var method: String = ""
		if "method" in attack:
			method = attack.method
		elif attack.has_method("get") and attack.get("method"):
			method = attack.get("method")

		match method.to_lower():
			"bite":
				hints.append_array([
					"It bears wicked fangs.",
					"Its jaws look capable of crushing bone.",
					"Saliva drips from sharp teeth.",
				])
			"claw":
				hints.append_array([
					"Its claws are long and cruel.",
					"Razor-sharp talons extend from its limbs.",
					"Its claws leave gouges in the stone.",
				])
			"hit", "punch":
				hints.append_array([
					"Its fists are scarred from many fights.",
					"It wields crude but effective weapons.",
					"Calloused knuckles speak of endless violence.",
				])
			"crush":
				hints.append_array([
					"It could crush a helm with those arms.",
					"Its grip looks bone-breaking.",
				])
			"sting":
				hints.append_array([
					"A barbed stinger drips with venom.",
					"Its tail curves with lethal intent.",
				])
			"touch":
				hints.append_array([
					"A cold aura surrounds its hands.",
					"Its touch looks withering.",
				])
			_:
				hints.append_array([
					"It looks ready to attack.",
					"Its posture radiates menace.",
				])

	if hints.is_empty():
		return ""
	return hints.pick_random()

static func _get_unit_flag_flavor(flags: Array) -> String:
	var candidates: Array[String] = []

	if "UNDEAD" in flags:
		candidates.append_array([
			"Its eyes glow with unholy light.",
			"The stench of death clings to it like a shroud.",
			"It should not exist, yet it moves.",
		])
	if "SPIDER" in flags:
		candidates.append_array([
			"Multiple eyes gleam in the darkness.",
			"Silk threads trail from its abdomen.",
		])
	if "ORC" in flags:
		candidates.append_array([
			"War-paint covers its face.",
			"Crude tribal scars mark its flesh.",
			"The red eye of Sauron is branded on its armor.",
		])
	if "TROLL" in flags:
		candidates.append_array([
			"It reeks of carrion and filth.",
			"Its hide is like old leather, tough and scarred.",
		])
	if "WOLF" in flags:
		candidates.append_array([
			"Its hackles are raised, lips pulled back.",
			"Yellow eyes track your every movement.",
		])
	if "EVIL" in flags and "UNIQUE" in flags:
		candidates.append_array([
			"A palpable malice radiates from it.",
			"The shadows seem to deepen around it.",
		])
	if "DRAGON" in flags:
		candidates.append_array([
			"Heat shimmers in the air around it.",
			"Ancient scales gleam like dark metal.",
		])
	if "INVISIBLE" in flags:
		candidates.append_array([
			"The air shimmers where it stands.",
			"You can barely make out its outline.",
		])
	if "PASS_WALL" in flags:
		candidates.append_array([
			"Its form seems partially translucent.",
		])
	if "NO_FEAR" in flags:
		candidates.append_array([
			"It shows no sign of fear or hesitation.",
		])

	if candidates.is_empty():
		return ""
	return candidates.pick_random()

# ============================================================================
# TERRAIN DESCRIPTIONS
# ============================================================================

## Generate an atmospheric terrain description from tile type enum value.
static func generate_terrain_description(tile_type: int) -> String:
	match tile_type:
		0:  return "Impenetrable darkness stretches before you."
		1:  return "Rough-hewn stone floor, worn smooth by countless feet."
		2:  return "A solid wall of dark stone blocks, cold to the touch."
		3:  return "A heavy iron-banded door, firmly shut."
		4:  return "An open doorway, the door hanging on rusted hinges."
		5:  return "Stone steps descend into deeper darkness."
		6:  return "A crumbling stairway leads upward toward faint light."
		7:  return "A yawning chasm drops into nothingness. You dare not step closer."
		8:  return "Loose rubble and broken stone litter the ground."
		9:  return "An ancient forge, its coals still faintly glowing with dull heat."
		10: return "The floor looks subtly wrong here... a trap, perhaps."
		11: return "A trap! The mechanism has already been sprung."
		12: return "A heavy door sealed with glowing runes of binding."
		13: return "A jammed door, swollen in its frame. It might yield to force."
		14: return "This wall section looks slightly different from the rest."
		15: return "Dark water pools on the floor, reflecting nothing."
		16: return "Molten rock glows with an angry red light. The heat is intense."
		17: return "Thick green vines creep across the stone floor, slowing your steps."
		18: return "A thin stream of poisonous-looking liquid trickles across the path."
		19: return "Dense white spider webs stretch between the walls, sticky and thick."
		20: return "A dark pool of some foul liquid bubbles slowly."
		21: return "Morgul runes glow with a sickly light on the floor."
		22: return "A shadow brazier burns with a cold, dark flame that drinks the light."
		23: return "Glyphs of warding are etched into the stone, still faintly pulsing."
		24: return "Piles of old bones are heaped against the wall."
		25: return "The floor here is made of smooth dark stone, cold to the touch."
		26: return "An elevated stone dais, carved with symbols of dark authority."
		_:  return "Unremarkable dungeon floor."

# ============================================================================
# ITEM DESCRIPTIONS
# ============================================================================

## Generate a brief item description based on weight and name.
static func generate_item_description(item_data: Dictionary) -> String:
	var item_name: String = item_data.get("name", "something")
	var weight: int = item_data.get("weight", 0)
	if weight > 100:
		return "A heavy %s." % item_name.to_lower()
	elif weight > 30:
		return "A %s of moderate heft." % item_name.to_lower()
	else:
		return "A light %s." % item_name.to_lower()
