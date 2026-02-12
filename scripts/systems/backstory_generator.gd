extends RefCounted
class_name BackstoryGenerator
## Procedural backstory generator with 5 narrative layers.
## Generates Tolkien-flavored character histories for the creation screen.

# ============================================================================
# LAYER 1: PARENTAGE
# ============================================================================

static func _generate_parentage(race: String, house: String, gender: String, parent_name: String) -> String:
	var parent_title: String = "father" if gender == "male" else "mother"
	var child_word: String = "son" if gender == "male" else "daughter"

	var templates: Array[String] = []
	match race:
		"Elf":
			templates = [
				"Born in the twilight of the Third Age to %s, a keeper of the %s," % [parent_name, house],
				"Child of %s, who served among the %s as a warden of the ancient paths," % [parent_name, house],
				"The %s %s raised you in the hidden vales of the %s, far from the Shadow's reach," % [parent_title, parent_name, house],
				"You are the %s of %s, a singer of laments among the %s," % [child_word, parent_name, house],
				"In the ageless halls of the %s, your %s %s taught you the old ways," % [house, parent_title, parent_name],
				"Your %s %s walked beneath the mallorn trees of the %s for uncounted years before your birth," % [parent_title, parent_name, house],
				"Among the starlit glades of the %s, %s — your %s — first spoke your name," % [house, parent_name, parent_title],
				"The %s %s was counted wise even among the %s, and you inherited that quiet wisdom," % [parent_title, parent_name, house],
				"Born under the light of Earendil to %s of the %s," % [parent_name, house],
				"You first drew breath in the halls of the %s, %s of %s," % [house, child_word, parent_name],
				"Your %s %s remembered the Elder Days, and passed their grief to you," % [parent_title, parent_name],
				"In a time of deepening shadow, %s of the %s brought you into the world," % [parent_name, house],
			]
		"Man":
			templates = [
				"In the settlements of Men near the forest edge, %s — your %s — raised you," % [parent_name, parent_title],
				"You are the %s of %s, a soldier of the %s," % [child_word, parent_name, house],
				"Born to %s in the halls of the %s, you knew duty before you knew play," % [parent_name, house],
				"Your %s %s served the %s with honor, and expected no less of you," % [parent_title, parent_name, house],
				"Among the folk of the %s, %s raised you to stand against the darkness," % [house, parent_name],
				"The %s %s was a veteran of many campaigns, scarred but unbowed," % [parent_title, parent_name],
				"In a modest homestead of the %s, your %s %s taught you the value of courage," % [house, parent_title, parent_name],
				"You grew up in the shadow of the %s's banner, %s of the warrior %s," % [house, child_word, parent_name],
				"Born in troubled times to %s, a healer among the %s," % [parent_name, house],
				"Your %s %s was among those who kept watch upon the borders of the %s," % [parent_title, parent_name, house],
				"The blood of the %s runs in your veins, passed down from %s," % [house, parent_name],
				"In a border village of the %s, %s raised you with tales of ancient valor," % [house, parent_name],
			]
		"Dwarf":
			templates = [
				"Deep in the mountain halls, %s of the %s forged your character as surely as mithril," % [parent_name, house],
				"You are the %s of %s, a craftsman of the %s," % [child_word, parent_name, house],
				"Born beneath stone and starlight to %s of the %s," % [parent_name, house],
				"Your %s %s worked the forges of the %s, and the ring of hammers was your lullaby," % [parent_title, parent_name, house],
				"In the deep halls of the %s, %s taught you the secrets of stone and steel," % [house, parent_name],
				"The %s %s was a miner of great renown among the %s," % [parent_title, parent_name, house],
				"Among the pillared caverns of the %s, your %s %s first placed a hammer in your hand," % [house, parent_title, parent_name],
				"Born to the anvil's song, %s of %s — warrior and smith in equal measure," % [child_word, parent_name],
				"Your %s %s remembered the glory of the %s before the dragon came," % [parent_title, parent_name, house],
				"In the echoing deeps of the %s, %s raised you with tales of Durin's line," % [house, parent_name],
				"The forge-fires of the %s lit your first breath, %s of %s," % [house, child_word, parent_name],
				"Your %s %s counted among the finest axe-wielders of the %s," % [parent_title, parent_name, house],
			]
		"Hobbit":
			templates = [
				"In the comfortable burrow of the %s family, your %s %s taught you the simple pleasures of life," % [house, parent_title, parent_name],
				"You are the %s of %s, a respectable hobbit of the %s," % [child_word, parent_name, house],
				"Born in the green hills of the %s, %s — your %s — raised you with pipeweed and poetry," % [house, parent_name, parent_title],
				"Your %s %s kept a fine garden and a finer pantry in the %s," % [parent_title, parent_name, house],
				"Among the gentle folk of the %s, %s was known for both courage and cooking," % [house, parent_name],
				"The hobbit %s raised you in the %s with an eye toward respectability," % [parent_name, house],
				"In a well-appointed hole in the %s, your %s %s taught you that adventures are nasty things," % [house, parent_title, parent_name],
				"Born to %s of the %s, who always said that hobbits were meant for quiet things," % [parent_name, house],
				"Your %s %s was the finest baker in all the %s — and you learned well," % [parent_title, parent_name, house],
				"In the rolling meadows of the %s, %s raised you to value good food above all else," % [house, parent_name],
				"The %s family of the %s was unremarkable — until you came along," % [parent_name.split(" ")[0] if " " in parent_name else parent_name, house],
				"Your %s %s always suspected there was something Tookish about you," % [parent_title, parent_name],
			]
		_:
			templates = [
				"Born to %s of the %s, you grew up in uncertain times," % [parent_name, house],
			]

	return templates.pick_random()


# ============================================================================
# LAYER 2: YOUTH / CHILDHOOD
# ============================================================================

static func _generate_youth(race: String, age: int) -> String:
	var age_bracket: String = _get_age_bracket(race, age)

	var templates: Dictionary = {
		"young": [
			"Your youth was brief but intense — a time of fierce training and fiercer loyalty.",
			"You came of age quickly, the shadow in the East lending urgency to every lesson.",
			"The elders marked you early as one with an uncommon restlessness.",
			"In your youth, you often wandered beyond the borders, drawn by something you could not name.",
			"You mastered the basics swiftly, driven by a hunger to prove yourself.",
			"Your early years were spent in the company of those older and wiser, absorbing their lore.",
			"A precocious child, you were already asking questions that troubled your teachers.",
			"The world seemed too small for you even then — every horizon a challenge.",
			"You were quiet and watchful as a child, observing more than others realized.",
			"Even in youth, you felt the pull of distant places and dangerous paths.",
			"Your childhood ended the day you first saw an orc raid from the watchtower.",
			"You spent your formative years training in secret, away from disapproving elders.",
		],
		"mature": [
			"Through the long years you honed your craft, patient as stone worn by water.",
			"The middle years brought wisdom born of loss — friends fallen, hopes deferred.",
			"You have seen enough seasons to know that the world darkens, and still you choose to fight.",
			"Experience has tempered you like good steel — harder, but not brittle.",
			"The years have given you a steady hand and a clear eye for deception.",
			"You spent decades perfecting skills that most never begin to learn.",
			"Time has taught you the value of patience, and the cost of hesitation.",
			"Your prime was spent in service, earning respect through deed rather than word.",
			"The world changed around you, but your purpose remained fixed as the North Star.",
			"You have buried enough comrades to know what you fight for — and what you fight against.",
			"Maturity brought the understanding that true strength is found in endurance.",
			"Years of discipline have forged your body and mind into instruments of singular purpose.",
		],
		"elder": [
			"The weight of long years lies upon you, but it is the weight of wisdom, not weakness.",
			"You have outlived friends, rivals, and more than one king — yet your resolve endures.",
			"Age has stripped away illusion, leaving only what matters: duty, honor, and one final quest.",
			"The young ones look at you with a mixture of awe and pity — they do not understand.",
			"Your joints ache with the memory of old wounds, but your spirit burns undimmed.",
			"You have seen the rise and fall of kingdoms, and know that darkness can always be fought.",
			"The eldest among your people whisper that you carry an old doom — perhaps they are right.",
			"Time has stolen your speed but sharpened your cunning beyond measure.",
			"You have nothing left to prove — only a debt to settle with the darkness.",
			"The songs of your youth have become dirges, but you still remember every word.",
			"Age has granted you a terrible clarity: you know exactly what awaits in Dol Guldur.",
			"Your long life has been a preparation, though you only see that now.",
		],
	}

	var bracket_templates: Array = templates.get(age_bracket, templates["mature"])
	return bracket_templates.pick_random()


# ============================================================================
# LAYER 3: DEFINING MOMENT
# ============================================================================

static func _generate_defining_moment(trait_name: String) -> String:
	var archetype: String = _get_trait_archetype(trait_name)

	var warrior_moments: Array[String] = [
		"You earned your first scar defending a trade caravan from orc raiders along the forest road.",
		"Your blade-master declared you ready after you bested three sparring partners in succession.",
		"You stood alone at a narrow bridge when your patrol was ambushed, buying time for the wounded to escape.",
		"A cave troll nearly killed you in the Misty Mountains — the scar across your ribs is a reminder.",
		"You were the last one standing when wolves descended on your camp at midwinter.",
		"During a border skirmish, you pulled a wounded comrade from beneath an orc's blade.",
		"You shattered an orc chieftain's war-helm with a single blow, earning the respect of hardened veterans.",
		"A duel with a Dunlending raider left you with a broken arm and an unbreakable resolve.",
		"You forged your first blade in a mountain forge, and it has never left your side since.",
		"When the watchtower fell, you held the stairs alone until relief arrived at dawn.",
		"You learned to fight not from training yards, but from desperate need on a burning night.",
		"The battle-rage first took you during a warg attack — terrifying and exhilarating in equal measure.",
	]

	var rogue_moments: Array[String] = [
		"You once tracked an orc patrol for three days through thick forest without being detected.",
		"A chance encounter with a Ranger taught you that silence is the deadliest weapon.",
		"You stole a key from a sleeping guard to free prisoners held in an Easterling camp.",
		"An ambush went wrong, and only your quick thinking saved your companions from slaughter.",
		"You learned to read the forest's signs — bent twigs, disturbed earth, the silence of birds.",
		"A night spent hiding in a hollow log while orcs searched for you taught patience beyond words.",
		"You discovered a hidden path through the mountains that even the Rangers did not know.",
		"Your first solo mission was a success — the enemy never knew you were there.",
		"A master thief from Bree taught you that the best locks are the ones you never touch.",
		"You once evaded a Nazgul's gaze by lying motionless for six hours beneath dead leaves.",
		"The art of the ambush came naturally to you, as if the shadows themselves were your allies.",
		"You survived your first failed mission by fading into the wilderness like morning mist.",
	]

	var lore_moments: Array[String] = [
		"In a forgotten library, you found a text that spoke of the Necromancer's true nature.",
		"A vision came to you unbidden — a dark tower wreathed in shadow, and a voice calling your name.",
		"You translated an ancient scroll that revealed the weaknesses of the undead.",
		"A dying sage entrusted you with knowledge too dangerous for any book.",
		"The stars spoke to you one winter's night, and you understood their warning.",
		"You discovered your voice could calm frightened animals and even sway uncertain minds.",
		"A fragment of an elder tongue came to you in a dream, and you spoke it upon waking.",
		"You once healed a companion with herbs and willpower alone, surprising even yourself.",
		"The lore-masters tested you and found your understanding of the Enemy beyond your years.",
		"You spent a season studying the ruins near Dol Guldur, piecing together its terrible history.",
		"An ancient melody lodged in your memory, humming with power you do not yet understand.",
		"You read the signs others miss — the flicker of malice in a stranger's eye, the taste of sorcery in the wind.",
	]

	match archetype:
		"warrior":
			return warrior_moments.pick_random()
		"rogue":
			return rogue_moments.pick_random()
		"lore":
			return lore_moments.pick_random()
		_:
			return warrior_moments.pick_random()


# ============================================================================
# LAYER 4: MOTIVATION FOR DOL GULDUR
# ============================================================================

static func _generate_motivation() -> String:
	var categories: Array[Dictionary] = [
		{"key": "revenge", "weight": 25},
		{"key": "duty", "weight": 25},
		{"key": "redemption", "weight": 15},
		{"key": "curiosity", "weight": 15},
		{"key": "treasure", "weight": 10},
		{"key": "exile", "weight": 10},
	]

	var motivations: Dictionary = {
		"revenge": [
			"The shadow of Dol Guldur took someone dear to you — and debts of blood must be repaid.",
			"Orcs bearing the mark of the Necromancer burned your homestead. You will find their master.",
			"Your mentor vanished into Mirkwood's depths and never returned. You intend to learn why.",
			"A creature of darkness slew your closest companion. The trail leads to the hill of sorcery.",
			"You swore an oath over a fresh grave: the Necromancer will answer for what he has taken.",
		],
		"duty": [
			"The Wise have spoken: the darkness in Dol Guldur must be confronted. You answered the call.",
			"Your people's leaders asked for volunteers. You stepped forward without hesitation.",
			"An ancient oath binds your line to oppose the Shadow wherever it rises. Dol Guldur calls.",
			"The Rangers sent word: something stirs in southern Mirkwood. You were chosen to investigate.",
			"Duty is not a burden you carry — it is the ground beneath your feet. You go because you must.",
		],
		"redemption": [
			"A past failure haunts you — companions lost to your hesitation. Dol Guldur is your chance to atone.",
			"You broke an oath once, in a moment of weakness. This quest is your path back to honor.",
			"The shame of cowardice burns hotter than any dragon's flame. You will prove yourself or die trying.",
			"You wronged someone who trusted you. Only a deed of great courage can balance that debt.",
			"The darkness you fight in Dol Guldur is nothing compared to the darkness you carry within.",
		],
		"curiosity": [
			"The mystery of the Necromancer gnaws at you. Who — or what — has taken residence in that ancient fortress?",
			"Strange phenomena emanate from Dol Guldur: unnatural mists, twisted animals, whispers on the wind. You must understand.",
			"A cryptic prophecy mentions one who will enter the hill of sorcery. You believe it speaks of you.",
			"The old maps show passages beneath Dol Guldur that predate the fortress itself. What lies below?",
			"Knowledge is your weapon, and the greatest knowledge lies in the most dangerous places.",
		],
		"treasure": [
			"They say the Necromancer hoards artifacts of the Elder Days. Fortune favors the bold.",
			"Thrain's ring — one of the seven Dwarf-rings — is said to lie within. The reward would be legendary.",
			"Wealth beyond imagining waits in the vaults of Dol Guldur, guarded by things best left unnamed.",
			"You are not proud: you need gold, and the dead do not spend theirs. Dol Guldur has plenty of dead.",
			"Ancient weapons of power lie forgotten in the fortress. You intend to claim one for yourself.",
		],
		"exile": [
			"Cast out from your homeland, you seek purpose in the one place no exile would willingly go.",
			"With nothing left to lose, Dol Guldur holds no terror for you — only the promise of meaning.",
			"You wander because you cannot return. Perhaps in the Necromancer's fortress, you will find an ending — or a beginning.",
			"Exile has stripped everything from you: name, home, honor. Only a deed of terrible valor can restore what was lost.",
			"The road led you here, as roads do for those without a destination. Dol Guldur is as good a place to die as any.",
		],
	}

	# Weighted random selection
	var total_weight: int = 0
	for cat in categories:
		total_weight += cat["weight"]

	var roll: int = randi_range(1, total_weight)
	var cumulative: int = 0
	var chosen_key: String = "duty"
	for cat in categories:
		cumulative += cat["weight"]
		if roll <= cumulative:
			chosen_key = cat["key"]
			break

	var options: Array = motivations[chosen_key]
	return options.pick_random()


# ============================================================================
# LAYER 5: STAT FLAVOR
# ============================================================================

static func _generate_stat_flavor(stats: Dictionary) -> String:
	if stats.is_empty():
		return ""

	# Find highest and lowest stats
	var highest_stat: String = "str"
	var highest_val: int = -99
	var lowest_stat: String = "str"
	var lowest_val: int = 99

	for stat_name: String in stats:
		var val: int = stats[stat_name]
		if val > highest_val:
			highest_val = val
			highest_stat = stat_name
		if val < lowest_val:
			lowest_val = val
			lowest_stat = stat_name

	var high_text: String = _get_high_stat_text(highest_stat)
	var low_text: String = _get_low_stat_text(lowest_stat)

	if highest_stat == lowest_stat or (highest_val == 0 and lowest_val == 0):
		return "You are balanced in all things — a generalist, ready for whatever the darkness brings."

	return high_text + " " + low_text


static func _get_high_stat_text(stat: String) -> String:
	var options: Dictionary = {
		"str": [
			"Years of labor have hardened your frame.",
			"Your grip can bend iron and your shoulders bear any burden.",
			"Strength flows through you like a river of stone.",
		],
		"dex": [
			"Your hands move with uncanny precision.",
			"Quick as a striking serpent, you react before thought catches up.",
			"Your agility has drawn envious glances from even the most seasoned warriors.",
		],
		"con": [
			"You have endured wounds that would fell an ox and risen again.",
			"Your constitution is legendary — fever, poison, and exhaustion trouble you less than most.",
			"Hardy beyond measure, you have outlasted storms both natural and unnatural.",
		],
		"gra": [
			"There is a light about you that others cannot name but instinctively trust.",
			"Your presence commands attention — when you speak, even the proud listen.",
			"Grace moves through you like starlight through crystal.",
		],
	}
	var texts: Array = options.get(stat, options["str"])
	return texts.pick_random()


static func _get_low_stat_text(stat: String) -> String:
	var options: Dictionary = {
		"str": [
			"Your frame is slight, but determination compensates for what muscle cannot.",
			"You have never relied on brute force — cleverness serves you better.",
		],
		"dex": [
			"You lack the natural quickness of some, but deliberation has its own advantages.",
			"The finer arts of agility elude you, though your other gifts more than compensate.",
		],
		"con": [
			"You tire more easily than most, and must choose your battles carefully.",
			"Your body is fragile, but your will drives it beyond its limits.",
		],
		"gra": [
			"Courts and councils never came naturally to you; you prefer plain speech and hard truths.",
			"You are blunt where others are graceful, but at least you are honest.",
			"You do not charm a room by entering it; you win trust only after deeds are done.",
			"Etiquette was never your weapon, and you have little patience for pretty lies.",
			"Your manner is direct and unvarnished, better suited to danger than diplomacy.",
			"You are no silver-tongued courtier; your convictions speak louder than your voice.",
		],
	}
	var texts: Array = options.get(stat, options["str"])
	return texts.pick_random()


# ============================================================================
# MAIN GENERATOR
# ============================================================================

static func generate(character_data: Dictionary) -> String:
	var race: String = character_data.get("race", "")
	var house: String = character_data.get("house", "")
	var gender: String = character_data.get("gender", "male")
	var trait_name: String = character_data.get("trait", "")
	var stats: Dictionary = character_data.get("base_stats", {})
	var age: int = character_data.get("age", 30)
	var skill_investments: Dictionary = character_data.get("skill_investments", {})
	var ability_purchases: Array = character_data.get("ability_purchases", [])

	# Get alternate house name for narrative use
	var house_display: String = house
	var house_data: DataManager.HouseData = DataManager.get_house(house)
	if house_data and not house_data.alternate_name.is_empty():
		house_display = house_data.alternate_name

	# Generate parent name using NameGenerator
	var parent_gender: String = "female" if gender == "male" else "male"
	var parent_name: String = NameGenerator.get_random_name(race, house_display, parent_gender)

	var parts: Array[String] = []
	parts.append(_generate_parentage(race, house_display, gender, parent_name))
	parts.append(_generate_youth(race, age))
	parts.append(_generate_defining_moment(trait_name))
	parts.append(_generate_motivation())

	var stat_flavor: String = _generate_stat_flavor(stats)
	if not stat_flavor.is_empty():
		parts.append(stat_flavor)
	var build_flavor: String = _generate_build_flavor(skill_investments, ability_purchases)
	if not build_flavor.is_empty():
		parts.append(build_flavor)

	return "\n\n".join(parts)

static func _generate_build_flavor(skill_investments: Dictionary, ability_purchases: Array) -> String:
	var ranked: Array[Dictionary] = []
	for key in skill_investments.keys():
		var val: int = int(skill_investments.get(key, 0))
		if val > 0:
			ranked.append({"skill": str(key), "points": val})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["points"]) == int(b["points"]):
			return str(a["skill"]) < str(b["skill"])
		return int(a["points"]) > int(b["points"])
	)

	var focus_phrase: String = ""
	if ranked.size() > 0:
		var primary: String = str(ranked[0]["skill"])
		match primary:
			"melee":
				focus_phrase = "You drilled endlessly in close-quarters forms, until each strike became instinct."
			"archery":
				focus_phrase = "You trained with bow and sightline in all weather, measuring distance by breath and heartbeat."
			"evasion":
				focus_phrase = "You learned to survive by movement, never where the enemy expects you to be."
			"stealth":
				focus_phrase = "You favored shadow and patience, striking only when the moment could not fail."
			"hunting":
				focus_phrase = "You studied tracks, wind, and silence, making the wild itself your tutor."
			"will":
				focus_phrase = "You hardened mind and spirit, mastering fear before facing it in battle."
			"smithing":
				focus_phrase = "You spent long hours at hammer and anvil, learning the language of steel and flaw."
			"lore":
				focus_phrase = "You gathered old songs and dangerous words, believing knowledge could wound the Shadow."
			_:
				focus_phrase = ""

	var notable_abilities: Array[String] = []
	for purchase in ability_purchases:
		if purchase is Dictionary:
			var nm: String = str(purchase.get("name", "")).strip_edges()
			if not nm.is_empty() and not notable_abilities.has(nm):
				notable_abilities.append(nm)
	if notable_abilities.size() > 3:
		notable_abilities = notable_abilities.slice(0, 3)

	if focus_phrase.is_empty() and notable_abilities.is_empty():
		return ""
	if notable_abilities.is_empty():
		return focus_phrase
	return "%s You are already known for %s." % [focus_phrase, ", ".join(notable_abilities)]


# ============================================================================
# HELPERS
# ============================================================================

static func _get_age_bracket(race: String, age: int) -> String:
	match race:
		"Elf":
			if age < 200:
				return "young"
			elif age < 1000:
				return "mature"
			else:
				return "elder"
		"Dwarf":
			if age < 80:
				return "young"
			elif age < 200:
				return "mature"
			else:
				return "elder"
		"Hobbit":
			if age < 40:
				return "young"
			elif age < 80:
				return "mature"
			else:
				return "elder"
		_:  # Man
			if age < 25:
				return "young"
			elif age < 50:
				return "mature"
			else:
				return "elder"


static func _get_trait_archetype(trait_name: String) -> String:
	var warrior_traits: Array[String] = [
		"Defiance", "Last Stand", "Undying Resolve", "Mithril Skin",
		"Shield Brother", "Blood of Numenor",
	]
	var rogue_traits: Array[String] = [
		"Ambush Mastery", "Shadow Step", "Steady Aim", "Nimble Striker",
		"Patient Stalker", "Oath of Enmity", "Wayfarer's Instinct",
	]
	# Everything else is "lore"
	if trait_name in warrior_traits:
		return "warrior"
	elif trait_name in rogue_traits:
		return "rogue"
	else:
		return "lore"
