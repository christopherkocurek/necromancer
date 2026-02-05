class_name Constants
## Game constants, enums, and flag definitions.
## Ported from Sil-Q src/defines.h
## This is a static class - access via Constants.CONSTANT_NAME

# ============================================================================
# SKILLS
# ============================================================================

enum Skill {
	S_MEL = 0,  # Melee
	S_ARC = 1,  # Archery
	S_EVN = 2,  # Evasion
	S_STL = 3,  # Stealth
	S_PER = 4,  # Perception
	S_WIL = 5,  # Will
	S_SMT = 6,  # Smithing
	S_LOR = 7   # Lore (was Song in Sil-Q)
}

const S_MAX: int = 8
const ABILITIES_MAX: int = 20

# ============================================================================
# ATTACK TYPES (for ability triggers)
# ============================================================================

enum AttackType {
	ATT_MAIN = 0,
	ATT_FLANKING = 1,
	ATT_CONTROLLED_RETREAT = 2,
	ATT_ZONE_OF_CONTROL = 3,
	ATT_OPPORTUNIST = 4,
	ATT_POLEARM = 5,
	ATT_FOLLOW_THROUGH = 6,
	ATT_RIPOSTE = 7,
	ATT_CLEAVE = 8,
	ATT_RAGE = 9,
	ATT_OPPORTUNITY = 10,
	ATT_IMPALE = 11
}

# ============================================================================
# DAMAGE TYPES
# ============================================================================

enum DamageType {
	GF_HURT = 1,
	GF_ARROW = 2,
	GF_BOULDER = 3,
	GF_FIRE = 6,
	GF_COLD = 7,
	GF_POIS = 8,
	GF_DARK = 10
}

# ============================================================================
# MELEE ABILITIES
# ============================================================================

enum MeleeAbility {
	MEL_POWER = 0,
	MEL_FINESSE = 1,
	MEL_KNOCK_BACK = 2,
	MEL_POLEARMS = 3,
	MEL_CHARGE = 4,
	MEL_FOLLOW_THROUGH = 5,
	MEL_OPENING_STRIKE = 6,
	MEL_CONTROL = 7,        # Subtlety - one-handed finesse
	MEL_CLEAVE = 8,
	MEL_ZONE_OF_CONTROL = 9,
	MEL_MIGHTY_BLOW = 10,
	MEL_DEFENSIVE_STANCE = 11,
	MEL_RAPID_ATTACK = 12,
	MEL_STR = 13
}

# ============================================================================
# EVASION ABILITIES
# ============================================================================

enum EvasionAbility {
	EVN_DODGING = 0,
	EVN_BLOCKING = 1,
	EVN_PARRY = 2,
	EVN_CROWD_FIGHTING = 3,
	EVN_LEAPING = 4,
	EVN_SPRINTING = 5,
	EVN_FLANKING = 6,
	EVN_HEAVY_ARMOUR = 7,
	EVN_RIPOSTE = 8,
	EVN_CONTROLLED_RETREAT = 9,
	EVN_DEX = 10
}

# ============================================================================
# ARCHERY ABILITIES
# ============================================================================

enum ArcheryAbility {
	ARC_ROUT = 0,
	ARC_FLETCHERY = 1,
	ARC_POINT_BLANK = 2,
	ARC_PUNCTURE = 3,
	ARC_AMBUSH = 4,
	ARC_KEEN_EYES = 5,
	ARC_CRIPPLING_SHOT = 6,
	ARC_DEADLY_HAIL = 7,
	ARC_DEX = 8,
}

# ============================================================================
# STEALTH ABILITIES
# ============================================================================

enum StealthAbility {
	STL_DISGUISE = 0,
	STL_ASSASSINATION = 1,
	STL_DISORIENTING = 2,
	STL_ESCAPE_ARTIST = 3,
	STL_LIGHT_FINGERS = 4,
	STL_VANISH = 5,
	STL_DEX = 6,
	STL_THROAT_SLIT = 7,
	STL_FADE = 8,
	STL_PILFER = 9,
	STL_DISTRACTION = 10,
	STL_SILENT_KILL = 11,
}

# ============================================================================
# PERCEPTION ABILITIES
# ============================================================================

enum PerceptionAbility {
	PER_NATURAL_TALENT = 0,
	PER_FOCUSED_ATTACK = 1,
	PER_KEEN_SENSES = 2,
	PER_CONCENTRATION = 3,
	PER_ALCHEMY = 4,
	PER_BANE = 5,
	PER_OUTWIT = 6,
	PER_LISTEN = 7,
	PER_MASTER_HUNTER = 8,
	PER_GRACE = 9,
}

# ============================================================================
# WILL ABILITIES
# ============================================================================

enum WillAbility {
	WIL_CURSE_BREAKING = 0,
	WIL_FORCE_OF_WILL = 1,
	WIL_STRENGTH_ADVERSITY = 2,
	WIL_FORMIDABLE = 3,
	WIL_DEFY_DEATH = 4,
	WIL_INDOMITABLE = 5,
	WIL_OATH = 6,
	WIL_POISON_RESIST = 7,
	WIL_VENGEANCE = 8,
	WIL_MAJESTY = 9,
	WIL_CON = 10,
}

# ============================================================================
# SMITHING ABILITIES
# ============================================================================

enum SmithingAbility {
	SMT_WEAPONSMITH = 0,
	SMT_ARMOURSMITH = 1,
	SMT_JEWELLER = 2,
	SMT_REFORGE = 3,
	SMT_EXPERTISE = 4,
	SMT_RECLAIM = 5,
	SMT_MASTERWORK = 6,
	SMT_GRACE = 7,
	SMT_REFORGE_MASTERY = 8,
	SMT_SALVAGE = 9,
	SMT_RECLAIM_MASTERY = 10,
	SMT_MASTER_SMITH = 11,
}

# ============================================================================
# LORE ABILITIES (Phase 8)
# ============================================================================

enum LoreAbility {
	LOR_WORD_OF_COMMAND = 0,    # 140: AOE fear/stun
	LOR_LORE_OF_BATTLE = 1,     # 141: Provoke target
	LOR_DEEP_MEMORY = 2,        # 142: Reveal map (DEFERRED)
	LOR_WORD_OF_OPENING = 3,    # 143: Unlock doors, reveal traps
	LOR_LORE_OF_SILENCE = 4,    # 144: Reduce monster perception
	LOR_HERBCRAFT = 5,          # 145: Double healing from potions
	LOR_WORD_OF_SHUTTING = 6,   # 146: Lock doors permanently
	LOR_INNER_LIGHT = 7,        # 147: +light radius (DEFERRED)
	LOR_DEADLY_LORE = 8,        # 148: Instant kill if HP <= 2xLore
	LOR_LORE_OF_ENDURANCE = 9,  # 149: +Will/2, +2d2 protection
	LOR_LORE_OF_SLEEP = 10,     # 150: Put target to sleep
	LOR_WORD_OF_MASTERY = 11,   # 151: Paralyze target
	LOR_DEVICE_MASTERY = 12,    # 152: +50% wand/staff charges
	LOR_GRACE = 13,             # 153: Passive +1 Grace stat
}

# ============================================================================
# MONSTER FLAGS (RF1 - general)
# ============================================================================

const RF1_UNIQUE: int = 0x00000001
const RF1_QUESTOR: int = 0x00000002
const RF1_MALE: int = 0x00000004
const RF1_FEMALE: int = 0x00000008
const RF1_FRIEND: int = 0x00000010
const RF1_FRIENDS: int = 0x00000020
const RF1_ESCORT: int = 0x00000040
const RF1_ESCORTS: int = 0x00000080
const RF1_TERRITORIAL: int = 0x00000100
const RF1_NO_CRIT: int = 0x00040000
const RF1_RES_CRIT: int = 0x00080000

# ============================================================================
# MONSTER FLAGS (RF2 - abilities/behavior)
# ============================================================================

const RF2_INVISIBLE: int = 0x00000001
const RF2_PASS_WALL: int = 0x00000008
const RF2_KILL_WALL: int = 0x00000010
const RF2_OPEN_DOOR: int = 0x00000040
const RF2_BASH_DOOR: int = 0x00000080
const RF2_RIPOSTE: int = 0x00000400
const RF2_FLANKING: int = 0x00000800
const RF2_CHARGE: int = 0x04000000
const RF2_KNOCK_BACK: int = 0x10000000
const RF2_ZONE_OF_CONTROL: int = 0x80000000

# ============================================================================
# MONSTER FLAGS (RF3 - race/resist)
# ============================================================================

const RF3_ORC: int = 0x00000001
const RF3_TROLL: int = 0x00000002
const RF3_UNDEAD: int = 0x00000004
const RF3_DRAGON: int = 0x00000008
const RF3_DEMON: int = 0x00000010
const RF3_RAUKO: int = 0x00000020
const RF3_SPIDER: int = 0x00000040
const RF3_WOLF: int = 0x00000080
const RF3_SERPENT: int = 0x00000100
const RF3_MAN: int = 0x00000200
const RF3_EVIL: int = 0x00010000
const RF3_RES_FIRE: int = 0x00100000
const RF3_RES_COLD: int = 0x00200000
const RF3_RES_POIS: int = 0x00400000
const RF3_NO_SLEEP: int = 0x01000000
const RF3_NO_FEAR: int = 0x02000000
const RF3_NO_STUN: int = 0x04000000
const RF3_NO_CONF: int = 0x08000000

# ============================================================================
# MONSTER FLAGS (RF4 - spells/ranged)
# ============================================================================

const RF4_ARROW1: int = 0x00000001
const RF4_ARROW2: int = 0x00000002
const RF4_BOULDER: int = 0x00000004
const RF4_BR_FIRE: int = 0x00000010
const RF4_BR_COLD: int = 0x00000020
const RF4_BR_POIS: int = 0x00000040
const RF4_BR_DARK: int = 0x00000080
const RF4_SHRIEK: int = 0x00010000
const RF4_DARKNESS: int = 0x00020000
const RF4_SLOW: int = 0x00080000

# ============================================================================
# FLAG NAME TO BIT MAPPING
# ============================================================================

const FLAG_MAP: Dictionary = {
	# RF1 - General
	"UNIQUE": [1, RF1_UNIQUE],
	"QUESTOR": [1, RF1_QUESTOR],
	"MALE": [1, RF1_MALE],
	"FEMALE": [1, RF1_FEMALE],
	"FRIEND": [1, RF1_FRIEND],
	"FRIENDS": [1, RF1_FRIENDS],
	"ESCORT": [1, RF1_ESCORT],
	"ESCORTS": [1, RF1_ESCORTS],
	"TERRITORIAL": [1, RF1_TERRITORIAL],
	"NO_CRIT": [1, RF1_NO_CRIT],
	"RES_CRIT": [1, RF1_RES_CRIT],

	# RF2 - Abilities/Behavior
	"INVISIBLE": [2, RF2_INVISIBLE],
	"PASS_WALL": [2, RF2_PASS_WALL],
	"KILL_WALL": [2, RF2_KILL_WALL],
	"OPEN_DOOR": [2, RF2_OPEN_DOOR],
	"BASH_DOOR": [2, RF2_BASH_DOOR],
	"RIPOSTE": [2, RF2_RIPOSTE],
	"FLANKING": [2, RF2_FLANKING],
	"CHARGE": [2, RF2_CHARGE],
	"KNOCK_BACK": [2, RF2_KNOCK_BACK],
	"ZONE_OF_CONTROL": [2, RF2_ZONE_OF_CONTROL],

	# RF3 - Race/Resist
	"ORC": [3, RF3_ORC],
	"TROLL": [3, RF3_TROLL],
	"UNDEAD": [3, RF3_UNDEAD],
	"DRAGON": [3, RF3_DRAGON],
	"DEMON": [3, RF3_DEMON],
	"RAUKO": [3, RF3_RAUKO],
	"SPIDER": [3, RF3_SPIDER],
	"WOLF": [3, RF3_WOLF],
	"SERPENT": [3, RF3_SERPENT],
	"MAN": [3, RF3_MAN],
	"EVIL": [3, RF3_EVIL],
	"RES_FIRE": [3, RF3_RES_FIRE],
	"RES_COLD": [3, RF3_RES_COLD],
	"RES_POIS": [3, RF3_RES_POIS],
	"NO_SLEEP": [3, RF3_NO_SLEEP],
	"NO_FEAR": [3, RF3_NO_FEAR],
	"NO_STUN": [3, RF3_NO_STUN],
	"NO_CONF": [3, RF3_NO_CONF],

	# RF4 - Spells/Ranged
	"ARROW1": [4, RF4_ARROW1],
	"ARROW2": [4, RF4_ARROW2],
	"BOULDER": [4, RF4_BOULDER],
	"BR_FIRE": [4, RF4_BR_FIRE],
	"BR_COLD": [4, RF4_BR_COLD],
	"BR_POIS": [4, RF4_BR_POIS],
	"BR_DARK": [4, RF4_BR_DARK],
	"SHRIEK": [4, RF4_SHRIEK],
	"DARKNESS": [4, RF4_DARKNESS],
	"SLOW": [4, RF4_SLOW],
}

# ============================================================================
# ENERGY SYSTEM
# ============================================================================

const ACTION_COST: int = 100

# Stealth
const STEALTH_MODE_BONUS: int = 5  # Bonus to stealth score when in stealth mode
const NOISE_DOOR: int = 5          # Noise from opening/closing doors
const NOISE_SMITHING: int = 10     # Noise from smithing
const NOISE_DIGGING: int = 10      # Noise from tunnelling/digging
const NOISE_BASH: int = 15         # Noise from bashing doors

# Energy gained per tick based on speed (0-7)
# Speed 2 is normal (100 energy = 1 action per tick)
# Faster creatures act more often, slower less often
const ENERGY_TABLE: Array[int] = [50, 75, 100, 125, 150, 175, 200, 250]

# ============================================================================
# ACTION TYPES (for tracking previous actions)
# ============================================================================

const ACTION_NOTHING: int = 0
const ACTION_MOVE_N: int = 1
const ACTION_MOVE_NE: int = 2
const ACTION_MOVE_E: int = 3
const ACTION_MOVE_SE: int = 4
const ACTION_MOVE_S: int = 5
const ACTION_MOVE_SW: int = 6
const ACTION_MOVE_W: int = 7
const ACTION_MOVE_NW: int = 8
const ACTION_WAIT: int = 9
const ACTION_MISC: int = 10
const ACTION_ARCHERY: int = 11
const ACTION_MELEE: int = 12
const ACTION_MAX: int = 3  # Track last 3 actions

# ============================================================================
# CHARACTER CREATION
# ============================================================================

# Stat allocation: 13 points total
# Cost curve indexed by stat value + 4 (so stat -4 = index 0, stat +6 = index 10)
const STAT_POINTS_TOTAL: int = 13
const STAT_COSTS: Array[int] = [-4, -3, -2, -1, 0, 1, 3, 6, 10, 15, 21]
# Index:                         0   1   2   3  4  5  6  7   8   9  10
# Stat:                         -4  -3  -2  -1  0 +1 +2 +3  +4  +5  +6

static func get_stat_cost(stat_value: int) -> int:
	var index: int = stat_value + 4
	if index < 0 or index >= STAT_COSTS.size():
		return 999  # Invalid
	return STAT_COSTS[index]

# ============================================================================
# EQUIPMENT SLOTS
# ============================================================================

enum EquipSlot {
	WEAPON,
	OFF_HAND,
	BOW,
	QUIVER,
	HEAD,
	BODY,
	CLOAK,
	HANDS,
	FEET,
	NECK,
	RING_L,
	RING_R,
	LIGHT
}

# TVAL to equipment slot mapping
const TVAL_TO_SLOT: Dictionary = {
	17: EquipSlot.QUIVER,    # TV_ARROW
	19: EquipSlot.BOW,       # TV_BOW
	20: EquipSlot.WEAPON,    # TV_DIGGING
	21: EquipSlot.WEAPON,    # TV_HAFTED
	22: EquipSlot.WEAPON,    # TV_POLEARM
	23: EquipSlot.WEAPON,    # TV_SWORD
	30: EquipSlot.FEET,      # TV_BOOTS
	31: EquipSlot.HANDS,     # TV_GLOVES
	32: EquipSlot.HEAD,      # TV_HELM
	33: EquipSlot.HEAD,      # TV_CROWN
	34: EquipSlot.OFF_HAND,  # TV_SHIELD
	35: EquipSlot.CLOAK,     # TV_CLOAK
	36: EquipSlot.BODY,      # TV_SOFT_ARMOR
	37: EquipSlot.BODY,      # TV_MAIL
	39: EquipSlot.LIGHT,     # TV_LIGHT
	40: EquipSlot.NECK,      # TV_AMULET
	45: EquipSlot.RING_L,    # TV_RING (can go left or right)
}

# Non-equippable TVALs
const TVAL_CONSUMABLES: Array[int] = [55, 56, 66, 75, 77, 80]  # staff, wand, horn, potion, flask, food

static func get_slot_for_tval(tval: int) -> int:
	if TVAL_TO_SLOT.has(tval):
		return TVAL_TO_SLOT[tval]
	return -1  # Not equippable

# ============================================================================
# ALERTNESS SYSTEM (Phase 7)
# ============================================================================

const ALERTNESS_MIN: int = -20        # Deep sleep
const ALERTNESS_UNWARY: int = -10     # Awake but unaware (wandering)
const ALERTNESS_ALERT: int = 0        # Aware of player (hunting/alert)
const ALERTNESS_QUITE_ALERT: int = 5  # More alert
const ALERTNESS_VERY_ALERT: int = 10  # Highly alert
const ALERTNESS_MAX: int = 20         # Maximum alertness

# ============================================================================
# MORALE SYSTEM (Phase 7)
# ============================================================================

const BASE_MORALE: int = 60
const RALLY_BONUS: int = 60           # +60 tmp_morale when stopping flight
const ESCORT_MULTIPLIER: int = 4      # Escorts provide 4x morale to pack

# Stance thresholds
const MORALE_AGGRESSIVE: int = 200    # Morale > 200 = aggressive
const MORALE_CONFIDENT: int = 0       # Morale > 0 = confident

# Range constants
const MAX_SIGHT: int = 20
const FLEE_RANGE: int = MAX_SIGHT + 20  # = 40
const TURN_RANGE: int = 3             # Fleeing monsters within 3 tiles must fight if slower

# ============================================================================
# STANCE ENUM (Phase 7)
# ============================================================================

enum Stance {
	AGGRESSIVE,
	CONFIDENT,
	FLEEING
}

# ============================================================================
# STATUS EFFECT IDS (Phase 7)
# ============================================================================

# Use StringName for efficiency
const EFFECT_BLIND: StringName = &"blind"
const EFFECT_CONFUSED: StringName = &"confused"
const EFFECT_POISONED: StringName = &"poisoned"
const EFFECT_AFRAID: StringName = &"afraid"
const EFFECT_STUNNED: StringName = &"stunned"
const EFFECT_CUT: StringName = &"cut"
const EFFECT_SLOW: StringName = &"slow"
const EFFECT_FAST: StringName = &"fast"
const EFFECT_ENTRANCED: StringName = &"entranced"
const EFFECT_IMAGE: StringName = &"image"  # Hallucination
const EFFECT_RAGE: StringName = &"rage"
const EFFECT_DARKENED: StringName = &"darkened"
const EFFECT_BURNING: StringName = &"burning"

# Stun thresholds
const STUN_THRESHOLD_HEAVY: int = 50
const STUN_THRESHOLD_KNOCKOUT: int = 100
const STUN_MAX: int = 105

# Effect caps
const EFFECT_MAX_GENERAL: int = 10000
const EFFECT_MAX_POISON: int = 100
const EFFECT_MAX_CUT: int = 100

# ============================================================================
# GAME MODES (Phase 7)
# ============================================================================

enum GameMode {
	PERMADEATH,
	CASUAL
}

# ============================================================================
# SPECIAL MONSTER INDICES (Phase 7)
# ============================================================================

const SAURON_ID: int = 99       # Placeholder - update with actual ID
const NAZGUL_IDS: Array[int] = [90, 91, 92, 93, 94, 95, 96, 97, 98]  # 9 Nazgul
const THRAIN_ID: int = 100      # Thrain's corpse/encounter

# ============================================================================
# SCORE CALCULATION (Phase 7)
# ============================================================================

const SCORE_MAX_TURNS: int = 100000
const SCORE_DEPTH_MULTIPLIER: int = 10
const SCORE_ESCAPE_BONUS: int = 50000
const SCORE_VICTORY_BONUS: int = 500000

# Race challenge factors for score calculation
const RACE_CHALLENGE_FACTORS: Dictionary = {
	"Noldor": 3,
	"Sindar": 4,
	"Man": 4,
	"Dwarf": 5,
}

static func get_race_challenge_factor(race_name: String) -> int:
	return RACE_CHALLENGE_FACTORS.get(race_name, 4)
