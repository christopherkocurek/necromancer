class_name EpitaphGenerator
extends RefCounted
## Generates procedural epitaphs based on run characteristics.
## Ported from the original Necromancer/Sil-Q death.c system.

# ============================================================================
# CONDITIONAL EPITAPHS (Highest Priority)
# ============================================================================

const EPITAPHS_KILLED_BY_SAURON: Array[String] = [
	"The darkness claimed another soul.",
	"In the end, the shadow was absolute.",
	"No light escapes from Dol Guldur.",
	"The Necromancer's power proved absolute.",
	"Even the brave fall before the Dark Lord.",
]

const EPITAPHS_KILLED_BY_NAZGUL: Array[String] = [
	"The wraith's blade found its mark.",
	"Claimed by the Ringwraiths.",
	"Neither living nor dead shall escape them.",
	"The Nine always find their prey.",
	"The Black Breath took another.",
]

const EPITAPHS_STOLE_RING: Array[String] = [
	"So close to victory, yet so far.",
	"The Ring slipped away... as did life.",
	"To have held such power, only to lose everything.",
	"The prize was won, but not the war.",
	"Glory found, but escape eluded.",
]

const EPITAPHS_FOUND_THRAIN: Array[String] = [
	"The dwarf-king's fate was witnessed.",
	"Thrain's secret died with another.",
	"Knowledge gained, but never shared.",
	"The last of Durin's line was found.",
]

const EPITAPHS_SAW_SAURON: Array[String] = [
	"To gaze upon the Necromancer is to know despair.",
	"The Eye sees all, even the brave.",
	"Some sights cannot be unseen.",
	"Witness to darkness, consumed by it.",
]

const EPITAPHS_LONG_RUN: Array[String] = [
	"A journey measured in countless steps.",
	"Time enough for hope and despair both.",
	"The long road ends at last.",
	"Persistence met its match.",
	"Every step was a victory, until the last.",
]

const EPITAPHS_SHORT_RUN: Array[String] = [
	"A candle flame, brief and bright.",
	"Barely begun.",
	"The dungeon claims the unwary.",
	"Ambition outpaced preparation.",
	"Swift was the descent, swifter the end.",
]

const EPITAPHS_DIED_DEEP: Array[String] = [
	"So deep, the surface seems a dream.",
	"In the darkest depths, hope fades.",
	"Far from sun and sky, rest at last.",
	"The abyss gazes back.",
	"Lost in endless darkness.",
]

const EPITAPHS_DIED_SHALLOW: Array[String] = [
	"The first steps are often the last.",
	"Not far enough to matter.",
	"Barely scratched the surface.",
	"The upper halls proved deadly enough.",
]

const EPITAPHS_HIGH_STEALTH: Array[String] = [
	"A shadow among shadows.",
	"Unseen until the end.",
	"Silent as the grave they now fill.",
	"The quiet path led to silence eternal.",
]

const EPITAPHS_HIGH_KILLS: Array[String] = [
	"A reaper of many souls.",
	"The slayer became the slain.",
	"Blood calls to blood.",
	"Many fell before this one.",
	"A warrior's end for a warrior's life.",
]

const EPITAPHS_PACIFIST: Array[String] = [
	"Harmless to the last.",
	"The gentlest soul in all the darkness.",
	"Not a single life taken, yet one was lost.",
	"Peace brought no safety here.",
]

# ============================================================================
# TONE-BASED EPITAPHS (Fallback)
# ============================================================================

enum Tone {
	LACONIC,
	DESCRIPTIVE,
	IRONIC,
	BLEAK,
	ASPIRATIONAL,
	GRIM,
	HEROIC
}

const EPITAPHS_LACONIC: Array[String] = [
	"It ended.",
	"No more.",
	"Done.",
	"Finished.",
	"Gone.",
]

const EPITAPHS_DESCRIPTIVE: Array[String] = [
	"Here lies one who sought the depths.",
	"This adventurer dared the darkness.",
	"Another seeker lost to Dol Guldur.",
	"The dungeon claims what the dungeon wills.",
]

const EPITAPHS_IRONIC: Array[String] = [
	"Came for treasure, found something else.",
	"The best laid plans...",
	"Confidence, meet consequence.",
	"It seemed like a good idea at the time.",
	"If only they had turned back.",
]

const EPITAPHS_BLEAK: Array[String] = [
	"None shall remember.",
	"Forgotten before the body grew cold.",
	"Another nameless corpse in the deep.",
	"The darkness swallows all.",
	"No songs will be sung.",
]

const EPITAPHS_ASPIRATIONAL: Array[String] = [
	"They reached for glory.",
	"Almost. So very almost.",
	"The dream died with the dreamer.",
	"What might have been...",
	"Potential unrealized.",
]

const EPITAPHS_GRIM: Array[String] = [
	"Death came on swift wings.",
	"The end was neither quick nor clean.",
	"Screams echoed briefly, then silence.",
	"Meat for the shadows.",
	"Another feast for the dark.",
]

const EPITAPHS_HEROIC: Array[String] = [
	"They fought until they could fight no more.",
	"A worthy end for a worthy soul.",
	"Defiant to the last breath.",
	"Though fallen, not dishonored.",
	"The brave need not live forever.",
]

const TONE_EPITAPHS: Dictionary = {
	Tone.LACONIC: EPITAPHS_LACONIC,
	Tone.DESCRIPTIVE: EPITAPHS_DESCRIPTIVE,
	Tone.IRONIC: EPITAPHS_IRONIC,
	Tone.BLEAK: EPITAPHS_BLEAK,
	Tone.ASPIRATIONAL: EPITAPHS_ASPIRATIONAL,
	Tone.GRIM: EPITAPHS_GRIM,
	Tone.HEROIC: EPITAPHS_HEROIC,
}

# ============================================================================
# GENERATION
# ============================================================================

## Generate an epitaph based on run statistics.
static func generate(stats: RunStats) -> String:
	# Check conditional triggers first (highest priority)

	# Killed by Sauron
	if stats.killer_idx == Constants.SAURON_ID:
		return _random_from(EPITAPHS_KILLED_BY_SAURON)

	# Killed by Nazgul
	if stats.killer_idx in Constants.NAZGUL_IDS:
		return _random_from(EPITAPHS_KILLED_BY_NAZGUL)

	# Stole the ring (rare achievement)
	if stats.stole_ring:
		return _random_from(EPITAPHS_STOLE_RING)

	# Found Thrain
	if stats.found_thrain:
		return _random_from(EPITAPHS_FOUND_THRAIN)

	# Saw Sauron but wasn't killed by him
	if stats.saw_sauron and stats.killer_idx != Constants.SAURON_ID:
		return _random_from(EPITAPHS_SAW_SAURON)

	# Long run (>10000 turns)
	if stats.was_long_run():
		return _random_from(EPITAPHS_LONG_RUN)

	# Short run (<500 turns)
	if stats.was_short_run():
		return _random_from(EPITAPHS_SHORT_RUN)

	# Died deep (>=12)
	if stats.died_deep():
		return _random_from(EPITAPHS_DIED_DEEP)

	# Died shallow (<=3)
	if stats.died_shallow():
		return _random_from(EPITAPHS_DIED_SHALLOW)

	# High stealth ratio
	if stats.had_high_stealth():
		return _random_from(EPITAPHS_HIGH_STEALTH)

	# High kills (>50)
	if stats.was_slayer():
		return _random_from(EPITAPHS_HIGH_KILLS)

	# Pacifist (0 kills)
	if stats.was_pacifist():
		return _random_from(EPITAPHS_PACIFIST)

	# Fallback to tone-based selection
	var tone: Tone = _analyze_run_profile(stats)
	return _random_from(TONE_EPITAPHS[tone])

## Analyze run to determine epitaph tone.
static func _analyze_run_profile(stats: RunStats) -> Tone:
	var depth: int = stats.max_depth_reached
	var kills: int = stats.enemies_killed
	var turns: int = stats.total_turns

	# Deep exploration suggests aspirational tone
	if depth >= 10:
		return Tone.ASPIRATIONAL

	# Lots of combat suggests heroic or grim
	if kills > 30:
		if randf() < 0.5:
			return Tone.HEROIC
		return Tone.GRIM

	# Very low turns suggests ironic (didn't even get started)
	if turns < 200:
		return Tone.IRONIC

	# Mid-range exploration
	if depth >= 5:
		if randf() < 0.3:
			return Tone.DESCRIPTIVE
		return Tone.BLEAK

	# Default: random tone weighted toward bleak/descriptive
	var roll: float = randf()
	if roll < 0.25:
		return Tone.LACONIC
	elif roll < 0.50:
		return Tone.BLEAK
	elif roll < 0.75:
		return Tone.DESCRIPTIVE
	else:
		return Tone.IRONIC

static func _random_from(array: Array) -> String:
	if array.is_empty():
		return "Rest in peace."
	return array[randi() % array.size()]
