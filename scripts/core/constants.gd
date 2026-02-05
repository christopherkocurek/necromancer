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
	ARC_PRECISION = 0,
	ARC_POINT_BLANK = 1,
	ARC_RAPID_FIRE = 2,
	ARC_CRIPPLING_SHOT = 3,
	ARC_FLAMING_ARROWS = 4
}

# ============================================================================
# STEALTH ABILITIES
# ============================================================================

enum StealthAbility {
	STL_DISGUISE = 0,
	STL_ASSASSINATION = 1,
	STL_CRUEL_BLOW = 2,
	STL_OPPORTUNIST = 3,
	STL_EXCHANGE_PLACES = 4
}

# ============================================================================
# PERCEPTION ABILITIES
# ============================================================================

enum PerceptionAbility {
	PER_FOCUSED_ATTACK = 0,
	PER_KEEN_SENSES = 1,
	PER_LORE_KEEPER = 2,
	PER_CONCENTRATION = 3,
	PER_BANE = 4
}

# ============================================================================
# WILL ABILITIES
# ============================================================================

enum WillAbility {
	WIL_CHANNELING = 0,
	WIL_MIND_OVER_BODY = 1,
	WIL_CURSE_BREAKING = 2,
	WIL_INNER_LIGHT = 3,
	WIL_HARDINESS = 4
}

# ============================================================================
# SMITHING ABILITIES
# ============================================================================

enum SmithingAbility {
	SMT_WEAPONSMITH = 0,
	SMT_ARMOURSMITH = 1,
	SMT_JEWELLER = 2,
	SMT_ENCHANTMENT = 3,
	SMT_ARTIFICE = 4,
	SMT_MASTERPIECE = 5
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

# Energy gained per tick based on speed (0-7)
const ENERGY_TABLE: Array[int] = [5, 5, 10, 15, 20, 25, 30, 35]

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
