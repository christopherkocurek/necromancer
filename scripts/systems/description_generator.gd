extends RefCounted
class_name DescriptionGenerator
## Generates procedural physical descriptions for monsters, terrain, and items.
## 500+ templates with state-aware variations (health, morale, layer, ego).
## Used by MonsterMemory, LookPanel, and DeathScreen.

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
	var hp: int = _estimate_hp(monster_data)
	var size: String = _get_size_descriptor(hp)
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

## Generate a contextual description with health, morale, and layer awareness.
## Returns an array of description lines (base + state modifiers).
static func generate_contextual_description(monster_data: Dictionary, tier: int, context: Dictionary) -> Array[String]:
	var lines: Array[String] = []

	# Base description
	lines.append(generate_monster_description(monster_data, tier))

	# Health-aware line
	var health_pct: float = context.get("health_pct", 1.0)
	if health_pct < 1.0:
		var health_line: String = generate_health_description(health_pct)
		if not health_line.is_empty():
			lines.append(health_line)

	# Morale-aware line
	var stance: int = context.get("stance", -1)
	var morale: int = context.get("morale", 0)
	if stance >= 0:
		var morale_line: String = generate_morale_description(stance, morale)
		if not morale_line.is_empty():
			lines.append(morale_line)

	# Layer-themed overlay
	var layer_name: String = context.get("layer_name", "")
	if not layer_name.is_empty():
		var display_char: String = monster_data.get("char", "?")
		var overlay: String = generate_layer_creature_overlay(display_char, layer_name)
		if not overlay.is_empty():
			lines.append(overlay)

	return lines

## Estimate HP from health_dice string (e.g. "4d4" -> average 10).
static func _estimate_hp(monster_data: Dictionary) -> int:
	var health_dice: String = monster_data.get("health_dice", "")
	if health_dice.is_empty():
		return 10
	var parts: PackedStringArray = health_dice.split("d")
	if parts.size() != 2:
		return 10
	var num_dice: int = int(parts[0])
	var die_size: int = int(parts[1])
	if num_dice <= 0 or die_size <= 0:
		return 10
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
# CREATURE TYPE TEMPLATES (3-5 base variants per type)
# ============================================================================

## Orcs (o) - humanoid warriors, soldiers of Sauron
static func _describe_orc(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s, %s-skinned humanoid with crude armor and a brutal countenance." % [size, color],
		"A %s, %s-hided warrior bearing the scars of many battles and a look of animal cunning." % [size, color],
		"A %s creature with %s skin stretched over heavy bones, its mouth full of broken fangs." % [size, color],
		"A %s orc-kind with %s flesh, its eyes burning with hatred in a face like hammered iron." % [size, color],
		"A %s, %s-complexioned brute whose armor is stitched together from plundered pieces." % [size, color],
	]
	var base: String = bases.pick_random()
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
	var bases: Array[String] = [
		"A %s %s arachnid with glistening fangs and clusters of dark eyes." % [size, color],
		"A %s spider of %s coloring, its legs clicking softly on the stone as it watches you." % [size, color],
		"A %s, %s-bodied arachnid whose abdomen pulses with something unwholesome." % [size, color],
		"A %s spider with %s chitin, its mandibles working ceaselessly as it considers you." % [size, color],
	]
	var base: String = bases.pick_random()
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
	var bases: Array[String] = [
		"A %s, %s-hided brute with long arms and a slack jaw. Its skin looks thick and leathery." % [size, color],
		"A %s troll-creature with %s hide, knuckles dragging on the ground as it lumbers forward." % [size, color],
		"A %s monstrosity of %s flesh, all muscle and stupidity and terrible, mindless hunger." % [size, color],
		"A %s beast with %s skin like old bark, its beady eyes glinting with dull malice." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "TROLL" in flags:
			base += " It smells of rotting meat."
		if "BASH_DOOR" in flags:
			base += " Its fists look capable of smashing through doors."
	return base

## Wargs/wolves (w) - intelligent wolf-beasts
static func _describe_warg(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s wolf-like beast with intelligent, malevolent eyes and powerful jaws." % [size, color],
		"A %s warg with %s fur, its lips curled back to reveal yellowed fangs." % [size, color],
		"A %s %s-pelted beast that moves with the cunning of something more than mere animal." % [size, color],
		"A %s lupine creature with %s fur matted with old blood and a gaze of terrible awareness." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags:
			base += " It seems to be part of a hunting pack."
		if "ORC" in flags or "ESCORT" in flags:
			base += " Crude harness marks suggest it serves as a mount."
	return base

## Wraiths (W) - spectral undead, ring-servants
static func _describe_wraith(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s figure shrouded in tattered darkness. The air grows bitterly cold in its presence." % [size, color],
		"A %s shade draped in %s robes that seem woven from shadow itself." % [size, color],
		"A %s spectral presence of %s aspect, its form flickering like a candle in a draft." % [size, color],
		"A %s %s apparition that moves without sound, leaving frost on the stones where it passes." % [size, color],
	]
	var base: String = bases.pick_random()
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
	var bases: Array[String] = [
		"A %s %s serpentine creature with scales that catch the torchlight. It moves with unsettling speed." % [size, color],
		"A %s serpent of %s hue, coiled and watchful, its tongue tasting the air." % [size, color],
		"A %s %s-scaled thing that flows across the stone like dark water." % [size, color],
		"A %s wyrm with %s scales, its sinuous body undulating with hypnotic menace." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "RES_POIS" in flags:
			base += " Venom glistens on its fangs."
		if "RES_FIRE" in flags:
			base += " Heat shimmers around its body."
	return base

## Canines (C) - dogs, hounds, wild beasts
static func _describe_canine(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s hound with bared teeth and hackles raised. Drool hangs from its jaws." % [size, color],
		"A %s %s-furred hound that fixes you with a predator's unwavering stare." % [size, color],
		"A %s canine beast of %s coat, ribs visible beneath matted fur, driven by hunger." % [size, color],
		"A %s %s hound whose breath steams in the dungeon air, muscles coiled to spring." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags:
			base += " Others of its kind lurk nearby."
		if "RES_FIRE" in flags:
			base += " Flames lick around its muzzle."
	return base

## Bats/birds (b) - flying creatures
static func _describe_bat(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s winged creature that darts erratically through the air." % [size, color],
		"A %s flying thing with %s membraned wings, swooping through the darkness." % [size, color],
		"A %s %s-winged creature that hangs in the air with unsettling stillness before darting away." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FLYING" in flags:
			base += " It swoops and dives with surprising agility."
		if "FRIENDS" in flags:
			base += " The flutter of many more wings echoes from the darkness."
	return base

## Rodents (r) - rats, squirrels, vermin
static func _describe_rodent(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s creature scurries along the ground, its beady eyes glinting." % [size, color],
		"A %s rodent with %s fur, its whiskers twitching as it watches you from the shadows." % [size, color],
		"A %s %s vermin that moves in quick, nervous bursts across the dungeon floor." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "FRIENDS" in flags:
			base += " You can hear more of them chittering in the shadows."
		if "RAND_50" in flags or "RAND_25" in flags:
			base += " It moves unpredictably, darting in random directions."
	return base

## Undead (z) - zombies, skeletons, wights
static func _describe_undead(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s figure that moves with a horrible, lurching gait. The stench of the grave clings to it." % [size, color],
		"A %s animated corpse of %s hue, its jaw hanging slack as it shambles toward you." % [size, color],
		"A %s %s remnant of what was once a living thing, now driven by dark will alone." % [size, color],
		"A %s undead creature with %s, mottled flesh, its empty eyes fixed on you with terrible hunger." % [size, color],
	]
	var base: String = bases.pick_random()
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
	var bases: Array[String] = [
		"A %s, %s figure of aristocratic bearing. Its eyes gleam with a terrible hunger." % [size, color],
		"A %s creature of %s complexion, its beauty marred by the predatory gleam in its eyes." % [size, color],
		"A %s %s-skinned being that moves with liquid grace, its lips parted to show elongated canines." % [size, color],
		"A %s figure draped in %s finery, radiating a cold charisma that draws you closer against your will." % [size, color],
	]
	var base: String = bases.pick_random()
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
	var bases: Array[String] = [
		"A %s %s creature wreathed in shadow and flame. The very air burns around it." % [size, color],
		"A %s being of %s fire and darkness, its form shifting between solid and inferno." % [size, color],
		"A %s %s horror born of the ancient pits, trailing smoke and cinders." % [size, color],
		"A %s %s-flamed entity whose mere presence scorches the stone beneath its feet." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "RES_FIRE" in flags:
			base += " Fire seems to be its element, not its weakness."
		if "UNIQUE" in flags:
			base += " It is a being of terrible and ancient power."
	return base

## Horrors (H) - nameless things, eldritch beings
static func _describe_horror(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s thing of unspeakable form. Your mind recoils from trying to comprehend its shape." % [size, color],
		"A %s abomination of %s aspect that defies the eye — its geometry is wrong, impossible." % [size, color],
		"A %s %s nightmare given flesh, its outline shifting and reshaping with each heartbeat." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "PASS_WALL" in flags:
			base += " It seems to exist only partially in this world."
		if "INVISIBLE" in flags:
			base += " Your eyes slide off it, as if refusing to acknowledge its existence."
	return base

## Plants/trees (&) - corrupted vegetation, tanglethorns
static func _describe_plant(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s mass of twisted vegetation, its thorned tendrils twitching with unnatural life." % [size, color],
		"A %s growth of %s vines and brambles that shifts and reaches toward you hungrily." % [size, color],
		"A %s %s tangle of corrupted plant matter, pulsing with a sickly inner light." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "TERRITORIAL" in flags:
			base += " It seems rooted here, guarding this stretch of corridor."
		if "RES_POIS" in flags:
			base += " A sickly sap oozes from its barbs."
	return base

## Centipedes/insects (c) - many-legged crawlers
static func _describe_centipede(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s many-legged creature that scuttles across the stone with a dry clicking sound." % [size, color],
		"A %s insectoid thing of %s carapace, its many legs moving in unsettling synchrony." % [size, color],
		"A %s %s-shelled crawler whose segmented body undulates as it advances." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "RES_POIS" in flags:
			base += " Its mandibles are slick with toxin."
	return base

## Quadrupeds (q) - miscellaneous four-legged beasts
static func _describe_quadruped(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s %s four-legged beast with a muscular frame and wary stance." % [size, color],
		"A %s quadruped of %s hide, its nostrils flaring as it catches your scent." % [size, color],
		"A %s %s-furred beast that watches you with preternatural intelligence." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNIQUE" in flags:
			base += " It carries itself with unnatural intelligence."
	return base

## Humanoids (@) - humans, sorcerers, named characters
static func _describe_humanoid(data: Dictionary, size: String, color: String, tier: int) -> String:
	var bases: Array[String] = [
		"A %s, %s-robed figure stands before you. Their posture suggests both cunning and menace." % [size, color],
		"A %s humanoid figure in %s garb, regarding you with cold calculation." % [size, color],
		"A %s person clad in %s vestments, their eyes sharp and their stance ready for violence." % [size, color],
		"A %s %s-cloaked individual whose stillness is more unnerving than any threat." % [size, color],
	]
	var base: String = bases.pick_random()
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
	var bases: Array[String] = [
		"A %s %s creature moves in the darkness ahead." % [size, color],
		"A %s thing of %s coloring lurks at the edge of your torchlight." % [size, color],
		"A %s %s shape shifts in the gloom, its nature unclear." % [size, color],
	]
	var base: String = bases.pick_random()
	if tier >= 1:
		var flags: Array = data.get("flags", [])
		if "UNIQUE" in flags:
			base += " Something about it sets it apart from common beasts."
	return base

# ============================================================================
# HEALTH-AWARE DESCRIPTIONS
# ============================================================================

## Generate a health-state description based on current HP percentage.
static func generate_health_description(health_pct: float) -> String:
	if health_pct >= 0.95:
		return ""  # Healthy — no special description
	elif health_pct >= 0.7:
		var pool: Array[String] = [
			"It bears a few scratches and minor wounds.",
			"Light injuries mark its body but it seems unbothered.",
			"A thin trail of blood seeps from a shallow cut.",
			"It favors one side slightly, nursing a fresh wound.",
		]
		return pool.pick_random()
	elif health_pct >= 0.4:
		var pool: Array[String] = [
			"It bleeds from several wounds, its movements growing labored.",
			"Dark blood stains its hide. It fights on through obvious pain.",
			"Its breathing is ragged and a deep gash mars its flank.",
			"Wounds cover its body. It sways but does not fall.",
			"Blood drips steadily from multiple injuries.",
		]
		return pool.pick_random()
	elif health_pct >= 0.15:
		var pool: Array[String] = [
			"It is grievously wounded, barely standing.",
			"Blood pools beneath it. Each breath seems an act of will.",
			"Its movements are desperate and erratic, driven by survival instinct alone.",
			"Terrible wounds expose flesh and bone. It will not last much longer.",
			"It staggers, leaving a trail of dark blood on the stone.",
		]
		return pool.pick_random()
	else:
		var pool: Array[String] = [
			"It clings to life by a thread, its eyes glazing over.",
			"One more blow will end it. It knows this, and so do you.",
			"It collapses, rises, collapses again — death's door stands open.",
			"A pitiful wreck of what it was, barely conscious.",
		]
		return pool.pick_random()

# ============================================================================
# MORALE-AWARE DESCRIPTIONS
# ============================================================================

## Generate a morale/stance description. Stance values from Constants.Stance enum.
static func generate_morale_description(stance: int, morale: int) -> String:
	# Constants.Stance: AGGRESSIVE=0, CONFIDENT=1, CAUTIOUS=2, FLEEING=3
	match stance:
		0:  # AGGRESSIVE
			var pool: Array[String] = [
				"Its eyes blaze with fury — it means to kill you or die trying.",
				"It snarls with unrestrained aggression, closing the distance.",
				"Rage drives it forward with reckless abandon.",
				"Every fiber of its being is bent on your destruction.",
			]
			return pool.pick_random()
		1:  # CONFIDENT
			var pool: Array[String] = [
				"It regards you with cold confidence, certain of victory.",
				"It advances steadily, unafraid and unhurried.",
				"There is no doubt in its posture — it believes it will win.",
			]
			return pool.pick_random()
		2:  # CAUTIOUS
			var pool: Array[String] = [
				"Its eyes dart nervously, measuring escape routes.",
				"It shifts its weight uncertainly, torn between fight and flight.",
				"A wariness has entered its movements — it doubts itself.",
			]
			return pool.pick_random()
		3:  # FLEEING
			var pool: Array[String] = [
				"Terror has broken its will — it scrambles desperately to escape.",
				"It flees in blind panic, all thought of combat forgotten.",
				"Its nerve has shattered. It runs, heedless of obstacles.",
				"It whimpers as it retreats, casting fearful glances over its shoulder.",
			]
			return pool.pick_random()
	return ""

# ============================================================================
# LAYER-THEMED CREATURE OVERLAYS
# ============================================================================

## Add a layer-appropriate atmospheric detail to a creature description.
## Same creature type reads differently in different layers.
static func generate_layer_creature_overlay(display_char: String, layer_name: String) -> String:
	# General atmosphere modifiers per layer
	var layer_overlays: Dictionary = {
		"outer_pits": [
			"Mirkwood's corruption clings to it like a second skin.",
			"The damp air of the upper pits has left mold on its hide.",
			"It seems newly arrived from the forest above.",
			"The faint scent of decaying leaves accompanies it.",
		],
		"lower_halls": [
			"Moss and lichen spot its body, marking it as a denizen of these damp halls.",
			"The greenish luminescence of the lower halls reflects off its form.",
			"It has adapted to the eternal twilight of these corridors.",
		],
		"dark_halls": [
			"Faint arcane runes flicker across its body, a sign of the magic saturating these halls.",
			"The blue shimmer of the Dark Halls gives it an otherworldly appearance.",
			"Ancient sorcery has twisted it beyond its natural form.",
			"It moves through the magical darkness as if born to it.",
		],
		"necropolis": [
			"The aura of undeath that permeates the Necropolis clings to it visibly.",
			"Fragments of bone and grave-dust coat its body.",
			"The restless dead seem drawn to it, whispering in its wake.",
			"A purple miasma of necromantic energy wreathes its form.",
		],
		"pits_of_despair": [
			"The oppressive heat of the Pits has scorched its extremities.",
			"Sweat — or something worse — glistens on its body in the infernal heat.",
			"The red glow of distant lava paints it in hellish light.",
			"It seems to thrive in the crushing despair that fills these depths.",
		],
		"inner_sanctum": [
			"The weight of Sauron's presence has warped it into something more terrible.",
			"Dark gold light plays across its form as the Sanctum's power feeds it.",
			"It moves with the confidence of a creature serving a master of absolute power.",
			"The Eye's influence has sharpened its malice to a razor's edge.",
		],
		"throne_room": [
			"The Necromancer's direct will animates it — this is no mere beast.",
			"Dark fire crackles around its form, a gift from the Lord of Dol Guldur.",
			"In the shadow of Sauron's throne, it is at its most dangerous.",
			"The full power of the Necromancer saturates its being.",
		],
	}

	if layer_name in layer_overlays:
		var pool: Array = layer_overlays[layer_name]
		return pool.pick_random()
	return ""

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
			"is barely larger than a cat",
			"has a skeletal, malnourished look",
		]
	elif hp <= 10:
		return [
			"has a lean, hungry look",
			"is compact but alert",
			"appears gaunt and desperate",
			"has a wiry, economical build",
			"is small but densely muscled",
		]
	elif hp <= 25:
		return [
			"has a sturdy build",
			"looks well-fed and strong",
			"carries itself with confidence",
			"has a solid, dependable frame",
			"is built for endurance rather than speed",
		]
	elif hp <= 50:
		return [
			"is heavily muscled",
			"has a massive, powerful frame",
			"towers over lesser creatures",
			"has a body like a battering ram",
			"is broad-shouldered and imposing",
		]
	else:
		return [
			"is colossal, filling the corridor",
			"has a body like a living siege engine",
			"is terrifyingly enormous",
			"makes the ground tremble with each step",
			"dwarfs everything around it",
		]

static func _get_unit_movement_descriptor(spd: int) -> String:
	var pool: Array[String] = []
	if spd <= 1:
		pool = [
			"It moves with a sluggish, ponderous gait.",
			"Each step seems to take great effort.",
			"It lumbers forward, slow but inexorable.",
			"Its movements are glacier-slow but unstoppable.",
		]
	elif spd == 2:
		pool = [
			"It moves at a measured, cautious pace.",
			"Its movements are deliberate and watchful.",
			"It keeps a steady, unhurried rhythm.",
			"",  # Sometimes no movement descriptor for normal speed
		]
	elif spd == 3:
		pool = [
			"It moves with surprising quickness.",
			"Its feet are quick and sure.",
			"It darts forward with alarming speed.",
			"It moves faster than its size would suggest.",
		]
	else:
		pool = [
			"It moves with blindingly fast reflexes.",
			"Its speed is almost impossible to track.",
			"It seems to flicker between positions.",
			"It is a blur of motion, terrifyingly quick.",
		]
	return pool.pick_random()

static func _get_unit_combat_hint(attacks: Array) -> String:
	if attacks.is_empty():
		return ""

	var hints: Array[String] = []
	for attack in attacks:
		if not attack is Object:
			continue
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
					"Its maw opens wider than seems possible.",
				])
			"claw":
				hints.append_array([
					"Its claws are long and cruel.",
					"Razor-sharp talons extend from its limbs.",
					"Its claws leave gouges in the stone.",
					"Dried blood cakes its curved talons.",
				])
			"hit", "punch":
				hints.append_array([
					"Its fists are scarred from many fights.",
					"It wields crude but effective weapons.",
					"Calloused knuckles speak of endless violence.",
					"It cracks its knuckles with menacing intent.",
				])
			"crush":
				hints.append_array([
					"It could crush a helm with those arms.",
					"Its grip looks bone-breaking.",
					"Massive hands open and close with crushing force.",
				])
			"sting":
				hints.append_array([
					"A barbed stinger drips with venom.",
					"Its tail curves with lethal intent.",
					"The stinger glistens with paralytic poison.",
				])
			"touch":
				hints.append_array([
					"A cold aura surrounds its hands.",
					"Its touch looks withering.",
					"Frost crackles where its fingers pass.",
				])
			_:
				hints.append_array([
					"It looks ready to attack.",
					"Its posture radiates menace.",
					"Every movement speaks of lethal capability.",
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
			"A faint keening emanates from it, the cry of a trapped soul.",
		])
	if "SPIDER" in flags:
		candidates.append_array([
			"Multiple eyes gleam in the darkness.",
			"Silk threads trail from its abdomen.",
			"Its legs move with mechanical precision.",
		])
	if "ORC" in flags:
		candidates.append_array([
			"War-paint covers its face.",
			"Crude tribal scars mark its flesh.",
			"The red eye of Sauron is branded on its armor.",
			"Blackened teeth are filed to points.",
		])
	if "TROLL" in flags:
		candidates.append_array([
			"It reeks of carrion and filth.",
			"Its hide is like old leather, tough and scarred.",
			"Drool hangs in thick ropes from its jaw.",
		])
	if "WOLF" in flags:
		candidates.append_array([
			"Its hackles are raised, lips pulled back.",
			"Yellow eyes track your every movement.",
			"A low growl rumbles continuously in its chest.",
		])
	if "EVIL" in flags and "UNIQUE" in flags:
		candidates.append_array([
			"A palpable malice radiates from it.",
			"The shadows seem to deepen around it.",
			"Your skin crawls in its presence.",
		])
	if "DRAGON" in flags:
		candidates.append_array([
			"Heat shimmers in the air around it.",
			"Ancient scales gleam like dark metal.",
			"The stench of sulfur precedes it.",
		])
	if "INVISIBLE" in flags:
		candidates.append_array([
			"The air shimmers where it stands.",
			"You can barely make out its outline.",
		])
	if "PASS_WALL" in flags:
		candidates.append_array([
			"Its form seems partially translucent.",
			"Stone appears to bend around its body.",
		])
	if "NO_FEAR" in flags:
		candidates.append_array([
			"It shows no sign of fear or hesitation.",
			"An eerie calm pervades its demeanor.",
		])
	if "SMART" in flags:
		candidates.append_array([
			"A disturbing intelligence gleams in its eyes.",
			"It studies you with calculating awareness.",
		])
	if "BASH_DOOR" in flags:
		candidates.append_array([
			"Its shoulders are broad enough to break through barriers.",
		])

	if candidates.is_empty():
		return ""
	return candidates.pick_random()

# ============================================================================
# TERRAIN DESCRIPTIONS (3-5 variants per tile, depth-scaled)
# ============================================================================

## Generate an atmospheric terrain description from tile type enum value.
## Randomly selects from multiple variants per tile type.
static func generate_terrain_description(tile_type: int) -> String:
	var pool: Array[String] = _get_terrain_pool(tile_type)
	if pool.is_empty():
		return "Unremarkable dungeon floor."
	return pool.pick_random()

## Generate a depth-scaled terrain description. Deeper floors get darker text.
static func generate_terrain_description_for_depth(tile_type: int, depth: int) -> String:
	var base: String = generate_terrain_description(tile_type)
	var depth_suffix: String = _get_depth_terrain_suffix(tile_type, depth)
	if depth_suffix.is_empty():
		return base
	return base + " " + depth_suffix

static func _get_terrain_pool(tile_type: int) -> Array[String]:
	match tile_type:
		0:  # VOID
			return [
				"Impenetrable darkness stretches before you.",
				"Nothing but the void — an absence of all light and form.",
				"The darkness here is absolute, swallowing even memory.",
				"You stare into nothingness. The nothingness stares back.",
			]
		1:  # FLOOR
			return [
				"Rough-hewn stone floor, worn smooth by countless feet.",
				"Cold flagstones stretch before you, cracked and ancient.",
				"Bare stone floor, polished by ages of passage.",
				"The floor is solid granite, cold beneath your feet.",
				"Worn stone tiles, their original pattern long since ground away.",
			]
		2:  # WALL
			return [
				"A solid wall of dark stone blocks, cold to the touch.",
				"Massive stone blocks fitted without mortar, testament to ancient craft.",
				"The wall is slick with condensation, black stone sweating in the cold.",
				"A featureless wall of dark rock, utterly impassable.",
			]
		3:  # DOOR_CLOSED
			return [
				"A heavy iron-banded door, firmly shut.",
				"A thick wooden door reinforced with dark iron. It does not invite entry.",
				"An oak door bound in blackened metal, its hinges crusted with rust.",
				"A closed door of ancient timber, scarred by claw marks on its surface.",
			]
		4:  # DOOR_OPEN
			return [
				"An open doorway, the door hanging on rusted hinges.",
				"The door stands ajar, its iron hinges groaning softly.",
				"An open portal, the door swung wide to reveal darkness beyond.",
				"A doorway stands open, cool air drifting through from the other side.",
			]
		5:  # STAIRS_DOWN
			return [
				"Stone steps descend into deeper darkness.",
				"A stairway spirals downward, each step narrower than the last.",
				"Worn steps lead down. A cold draft rises from below.",
				"The stairs descend into a darkness that seems to breathe.",
			]
		6:  # STAIRS_UP
			return [
				"A crumbling stairway leads upward toward faint light.",
				"Stone steps climb into the gloom above, offering a path back.",
				"The stairway ascends, and with it a faint promise of cleaner air.",
				"Stairs rise toward the levels above. Safety, perhaps.",
			]
		7:  # CHASM
			return [
				"A yawning chasm drops into nothingness. You dare not step closer.",
				"The floor ends abruptly at a gulf of impenetrable darkness.",
				"A bottomless rift cleaves the stone. The far side is unreachable.",
				"Darkness yawns below — a fall from here would have no end.",
			]
		8:  # RUBBLE
			return [
				"Loose rubble and broken stone litter the ground.",
				"A heap of collapsed masonry blocks the way.",
				"Shattered stone and dust fill this area, remnants of ancient collapse.",
				"Rubble crunches underfoot — the ceiling here gave way long ago.",
			]
		9:  # FORGE
			return [
				"An ancient forge, its coals still faintly glowing with dull heat.",
				"A dwarven forge of blackened iron, somehow still warm after ages of neglect.",
				"The forge's embers pulse with an inner light. The craft of smithing lives here still.",
				"An ancient anvil sits beside a banked forge, tools scattered nearby.",
			]
		10:  # TRAP
			return [
				"The floor looks subtly wrong here... a trap, perhaps.",
				"Something about the stonework here sets your nerves on edge.",
				"A barely perceptible seam in the floor suggests a pressure plate.",
				"Your instincts scream danger — this ground is not to be trusted.",
			]
		11:  # TRAP_TRIGGERED
			return [
				"A trap! The mechanism has already been sprung.",
				"The remains of a triggered trap litter the floor.",
				"A sprung trap — its mechanism spent, its danger past.",
			]
		12:  # DOOR_LOCKED
			return [
				"A heavy door sealed with glowing runes of binding.",
				"The door is locked, its surface inscribed with wards of power.",
				"A sealed door — no keyhole, only faintly pulsing sigils.",
				"Dark enchantments hold this door shut. It will not yield to force alone.",
			]
		13:  # DOOR_JAMMED
			return [
				"A jammed door, swollen in its frame. It might yield to force.",
				"The door is stuck fast, warped by age and damp.",
				"A stubborn door — brute strength might open it.",
			]
		14:  # DOOR_SECRET
			return [
				"This wall section looks slightly different from the rest.",
				"A hairline crack in the stone suggests a concealed passage.",
				"The stonework here is subtly newer — or is it a door?",
			]
		15:  # WATER
			return [
				"Dark water pools on the floor, reflecting nothing.",
				"Black water fills the passage, still and cold as death.",
				"A shallow pool of frigid water stretches across the floor.",
				"The water here is perfectly still, like dark glass.",
			]
		16:  # LAVA
			return [
				"Molten rock glows with an angry red light. The heat is intense.",
				"Lava bubbles and hisses, casting hellish light on the walls.",
				"Rivers of liquid fire creep across the stone.",
				"The air shimmers above a flow of molten rock, unbearably hot.",
			]
		17:  # VINE_FLOOR
			return [
				"Thick green vines creep across the stone floor, slowing your steps.",
				"Tangled vegetation carpets the floor, each step requiring effort.",
				"Knotted vines and creepers make the footing treacherous.",
				"Living vegetation has claimed this corridor, defying the darkness.",
			]
		18:  # POISON_STREAM
			return [
				"A thin stream of poisonous-looking liquid trickles across the path.",
				"Sickly green fluid seeps from the walls, pooling in the path ahead.",
				"A rivulet of something toxic cuts across the floor, staining the stone.",
			]
		19:  # WEB
			return [
				"Dense white spider webs stretch between the walls, sticky and thick.",
				"Curtains of web fill the passage, trembling at your approach.",
				"Gossamer strands of spider silk crisscross the space, strong as wire.",
				"Webs clog the corridor, each strand as thick as your finger.",
			]
		20:  # DARK_POOL
			return [
				"A dark pool of some foul liquid bubbles slowly.",
				"A pool of viscous black fluid, its surface roiling with unseen motion.",
				"Oily liquid fills a depression in the floor, giving off noxious fumes.",
			]
		21:  # MORGUL_RUNE
			return [
				"Morgul runes glow with a sickly light on the floor.",
				"Fell runes of sorcery are carved into the stone, pulsing with malice.",
				"The writing of Mordor burns on the floor — do not read it aloud.",
				"Dark script writhes on the stone, the language of the Enemy.",
			]
		22:  # SHADOW_BRAZIER
			return [
				"A shadow brazier burns with a cold, dark flame that drinks the light.",
				"An iron brazier holds a flame of pure darkness, radiating cold.",
				"Dark fire burns in a stone basin, casting shadows that move against the light.",
			]
		23:  # GLYPH_OF_WARDING
			return [
				"Glyphs of warding are etched into the stone, still faintly pulsing.",
				"Ancient protective sigils mark the floor, their power slowly fading.",
				"Ward-marks glow dimly on the ground, remnants of a defense long breached.",
			]
		24:  # BONE_PILE
			return [
				"Piles of old bones are heaped against the wall.",
				"A cairn of yellowed bones, some still bearing scraps of armor.",
				"Bones of the fallen lie scattered here, their owners long forgotten.",
				"A grim monument of skulls and bones marks this place.",
			]
		25:  # SHADOW_FLOOR
			return [
				"The floor here is made of smooth dark stone, cold to the touch.",
				"Shadow-touched stone absorbs your torchlight hungrily.",
				"The floor seems to swallow light, leaving your feet in perpetual darkness.",
			]
		26:  # THRONE_DAIS
			return [
				"An elevated stone dais, carved with symbols of dark authority.",
				"A raised platform of obsidian stone, its surface etched with sigils of command.",
				"The dais radiates power — this is a seat of dominion over the darkness.",
			]
		27:  # INSCRIPTION
			return [
				"Words have been carved into the stone floor here.",
				"Faded inscriptions mark this stretch of floor — someone left a message.",
				"Scratched letters and crude symbols cover the flagstones.",
				"An old inscription is chiseled into the ground, still barely legible.",
			]
		_:
			return ["Unremarkable dungeon floor."]

static func _get_depth_terrain_suffix(tile_type: int, depth: int) -> String:
	# Only add depth flavor for certain terrain types
	if tile_type == 1:  # FLOOR
		if depth <= 3:
			var pool: Array[String] = [
				"Roots from above have cracked the stone.",
				"Faint daylight has never reached here.",
			]
			return pool.pick_random()
		elif depth <= 9:
			var pool: Array[String] = [
				"The stone is ancient beyond reckoning.",
				"No natural light has touched this place in ages.",
			]
			return pool.pick_random()
		elif depth >= 16:
			var pool: Array[String] = [
				"The stone thrums with dark power.",
				"The floor feels warm, as if a furnace burns below.",
				"Each step echoes with unnatural resonance.",
			]
			return pool.pick_random()
	elif tile_type == 2:  # WALL
		if depth >= 13:
			var pool: Array[String] = [
				"Strange veins of dark metal run through the rock.",
				"The walls seem to pulse with a faint, malign heartbeat.",
			]
			return pool.pick_random()
	elif tile_type == 15:  # WATER
		if depth >= 10:
			var pool: Array[String] = [
				"Something moves beneath the surface.",
				"The water is unnaturally warm this deep.",
			]
			return pool.pick_random()
	return ""

# ============================================================================
# DEATH MESSAGES (Layer-themed)
# ============================================================================

## Generate a layer-themed death message based on where the player died.
static func generate_death_message(layer_name: String) -> String:
	var messages: Dictionary = {
		"outer_pits": [
			"You fall among the roots of Mirkwood, never to rise again.",
			"The darkness of the Outer Pits claims another soul.",
			"Your body will feed the twisted growth of Dol Guldur's threshold.",
			"So close to the surface — yet the light will never reach you now.",
		],
		"lower_halls": [
			"You collapse in the mossy Lower Halls, your blood feeding the lichen.",
			"The green-lit corridors become your tomb, unmarked and unmourned.",
			"The damp stones of the Lower Halls will be your final resting place.",
			"Mold will cover you here, and none will know your name.",
		],
		"dark_halls": [
			"The sorcery of the Dark Halls consumes your life force.",
			"Arcane energies dissolve your last breath into shimmering mist.",
			"The magic-saturated air drinks your final moments.",
			"You fall among ancient spells, your essence joining the enchantments.",
		],
		"necropolis": [
			"Your bones join the countless dead of Dol Guldur.",
			"The Necropolis gains another resident — permanent, this time.",
			"The whispers of the dead welcome you as one of their own.",
			"In the city of the dead, you have found your final address.",
		],
		"pits_of_despair": [
			"The oppressive heat of the Pits bakes the life from your body.",
			"You fall into the darkness of despair, and the fire consumes what remains.",
			"The screams of the damned swallow your last cry.",
			"Flame and shadow consume you in the deepest pits.",
		],
		"inner_sanctum": [
			"The Sanctum's dark power crushes the last spark of your resistance.",
			"Sauron's will presses you into the stone like a boot on an insect.",
			"The golden darkness of the Inner Sanctum is the last thing you see.",
			"So close to the heart of evil, and it is your heart that stops.",
		],
		"throne_room": [
			"Sauron's laughter echoes as darkness claims you.",
			"You die at the foot of the Necromancer's throne. He does not even look down.",
			"The dark fire of the Throne Room scorches your final breath from your lungs.",
			"In the shadow of the Dark Lord's seat, your quest ends in silence.",
		],
	}

	if layer_name in messages:
		return messages[layer_name].pick_random()
	return "The darkness of Dol Guldur claims another soul."

# ============================================================================
# ITEM DESCRIPTIONS (expanded with ego/quality awareness)
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

## Generate an extended item description with ego/quality awareness.
static func generate_item_description_ext(item_data: Dictionary) -> String:
	var item_name: String = item_data.get("name", "something")
	var weight: int = item_data.get("weight", 0)
	var tval: int = item_data.get("tval", 0)
	var ego_name: String = item_data.get("ego_name", "")
	var ego_quality: int = item_data.get("ego_quality", 0)

	var parts: Array[String] = []

	# Base weight description
	if weight > 100:
		parts.append("A heavy %s." % item_name.to_lower())
	elif weight > 30:
		parts.append("A %s of moderate heft." % item_name.to_lower())
	else:
		parts.append("A light %s." % item_name.to_lower())

	# Ego/enchantment flavor
	if ego_quality >= 2:
		var pool: Array[String] = [
			"It radiates an aura of power — this is no ordinary piece of equipment.",
			"Faint runes shimmer along its surface, speaking of masterful enchantment.",
			"It hums with barely contained magical energy.",
			"The craftsmanship is extraordinary, surpassing mortal skill.",
			"A warm glow emanates from within, pulsing with ancient power.",
		]
		parts.append(pool.pick_random())
	elif ego_quality == 1:
		var pool: Array[String] = [
			"It is well-crafted, a cut above common equipment.",
			"Subtle enchantment has been worked into its making.",
			"The quality of its construction is evident at a glance.",
			"It bears the marks of skilled craftsmanship.",
		]
		parts.append(pool.pick_random())

	# Type-specific flavor
	if tval >= 20 and tval <= 24:  # Weapons
		var pool: Array[String] = [
			"The blade catches the light with a keen edge.",
			"The balance is excellent — it was made for one purpose.",
			"Battle scars mark the metal, but the edge remains true.",
			"It feels natural in the hand, eager to be wielded.",
		]
		parts.append(pool.pick_random())
	elif tval >= 30 and tval <= 37:  # Armor/wearables
		var pool: Array[String] = [
			"The metal rings softly as you examine it.",
			"It is surprisingly light for its apparent protection.",
			"Generations of wear have shaped it to its purpose.",
			"It would turn aside all but the strongest blows.",
		]
		parts.append(pool.pick_random())
	elif tval == 45 or tval == 46:  # Jewelry
		var pool: Array[String] = [
			"It gleams with an inner light that has nothing to do with torchlight.",
			"Strange symbols are engraved along its surface in minute script.",
			"It feels warm to the touch, despite the dungeon's chill.",
			"There is a depth to it that the eye cannot quite fathom.",
		]
		parts.append(pool.pick_random())
	elif tval == 75:  # Potions
		var pool: Array[String] = [
			"The liquid shifts and swirls within the vial.",
			"It sloshes faintly when moved, promising relief or ruin.",
			"The glass is warm to the touch.",
		]
		parts.append(pool.pick_random())
	elif tval == 80:  # Food/herbs
		var pool: Array[String] = [
			"It smells faintly of the earth from which it grew.",
			"The leaves are still fresh, somehow preserved in the dungeon air.",
			"A faint herbal fragrance rises from it.",
		]
		parts.append(pool.pick_random())

	return " ".join(parts)

# ============================================================================
# KILL HISTORY DESCRIPTIONS
# ============================================================================

## Generate a description based on how many of this creature the player has killed.
static func generate_kill_history_description(kill_count: int, monster_name: String) -> String:
	if kill_count <= 0:
		return ""
	elif kill_count <= 2:
		var pool: Array[String] = [
			"You have faced %s before." % monster_name,
			"You recall a previous encounter with %s." % monster_name,
		]
		return pool.pick_random()
	elif kill_count <= 5:
		var pool: Array[String] = [
			"You've slain %d of these. Their habits are becoming familiar." % kill_count,
			"Experience with %s gives you a measure of confidence." % monster_name,
			"You know this foe — %d have fallen to your hand." % kill_count,
		]
		return pool.pick_random()
	elif kill_count <= 15:
		var pool: Array[String] = [
			"You are an experienced slayer of %s. %d kills and counting." % [monster_name, kill_count],
			"These creatures hold few surprises for you anymore.",
			"You know their weaknesses well — %d lie dead by your hand." % kill_count,
		]
		return pool.pick_random()
	else:
		var pool: Array[String] = [
			"You are a veteran hunter of %s. They should fear you." % monster_name,
			"Countless %s have fallen to you. This one is merely next." % monster_name,
			"Your expertise against %s is absolute." % monster_name,
		]
		return pool.pick_random()
