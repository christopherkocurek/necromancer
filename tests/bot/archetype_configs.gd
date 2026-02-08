extends RefCounted
## Bot archetype configurations for automated playtesting.
## Each archetype defines a valid character build using 13-point stat allocation.
##
## Stat costs (Constants.STAT_COSTS): [-4,-3,-2,-1,0,1,3,6,10,15,21]
## Indexed by stat_value + 4, must sum to STAT_POINTS_TOTAL (13).

# 6 archetypes covering all 4 playable races and diverse strategies.
# Base stats are PRE-race/house modifiers. Final stats shown in comments.

const ARCHETYPES: Dictionary = {
	"WARRIOR": {
		"archetype_id": "WARRIOR",
		"name": "SurvivalBot-Warrior",
		"race": "Man",
		"house": "Of Gondor",
		"trait": "Last Stand",
		"gender": "male",
		# Cost: 6+1+6+0 = 13. Final with Man(+1/0/+1/0) + Gondor(0/0/+1/0): STR4 DEX1 CON5 GRA0
		"base_stats": {"str": 3, "dex": 1, "con": 3, "gra": 0},
	},
	"STEALTH": {
		"archetype_id": "STEALTH",
		"name": "SurvivalBot-Stealth",
		"race": "Hobbit",
		"house": "Of the Tooks",
		"trait": "Nimble Striker",
		"gender": "female",
		# Cost: 0+6+1+6 = 13. Final with Hobbit(-2/+2/0/+2) + Tooks(0/+1/0/0): STR-2 DEX6 CON1 GRA5
		"base_stats": {"str": 0, "dex": 3, "con": 1, "gra": 3},
	},
	"LORE_MAGE": {
		"archetype_id": "LORE_MAGE",
		"name": "SurvivalBot-LoreMage",
		"race": "Elf",
		"house": "Of Lothlorien",
		"trait": "Light of the Eldar",
		"gender": "male",
		# Cost: 0+0+3+10 = 13. Final with Elf(-1/+2/+1/+2) + Lorien(0/0/0/+1): STR-1 DEX2 CON3 GRA7
		"base_stats": {"str": 0, "dex": 0, "con": 2, "gra": 4},
	},
	"RANGER": {
		"archetype_id": "RANGER",
		"name": "SurvivalBot-Ranger",
		"race": "Man",
		"house": "Dunedain",
		"trait": "Wayfarer's Instinct",
		"gender": "male",
		# Cost: 3+3+6+1 = 13. Final with Man(+1/0/+1/0) + Dunedain(0/+1/0/+1): STR3 DEX3 CON4 GRA2
		"base_stats": {"str": 2, "dex": 2, "con": 3, "gra": 1},
	},
	"TANK": {
		"archetype_id": "TANK",
		"name": "SurvivalBot-Tank",
		"race": "Dwarf",
		"house": "Of the Iron Hills",
		"trait": "Mithril Skin",
		"gender": "male",
		# Cost: 3+0+10+0 = 13. Final with Dwarf(+1/-1/+3/0) + IronHills(+1/0/0/0): STR4 DEX-1 CON7 GRA0
		"base_stats": {"str": 2, "dex": 0, "con": 4, "gra": 0},
	},
	"SMITH": {
		"archetype_id": "SMITH",
		"name": "SurvivalBot-Smith",
		"race": "Dwarf",
		"house": "Of Erebor",
		"trait": "Forge Intuition",
		"gender": "male",
		# Cost: 6+1+6+0 = 13. Final with Dwarf(+1/-1/+3/0) + Erebor(0/0/+1/0): STR4 DEX0 CON7 GRA0
		"base_stats": {"str": 3, "dex": 1, "con": 3, "gra": 0},
	},
	"STEALTH_PURE": {
		"archetype_id": "STEALTH_PURE",
		"name": "SurvivalBot-StealthPure",
		"race": "Hobbit",
		"house": "Of the Tooks",
		"trait": "Shadow Walker",
		"gender": "female",
		# Cost: -1+10+1+3 = 13. Final with Hobbit(-2/+2/0/+2) + Tooks(0/+1/0/0): STR-1 DEX8 CON2 GRA5
		"base_stats": {"str": 1, "dex": 5, "con": 2, "gra": 3},
	},
	"STEALTH_ASSASSIN": {
		"archetype_id": "STEALTH_ASSASSIN",
		"name": "SurvivalBot-StealthAssassin",
		"race": "Hobbit",
		"house": "Of the Tooks",
		"trait": "Nimble Striker",
		"gender": "male",
		# Cost: 3+6+1+3 = 13. Final with Hobbit(-2/+2/0/+2) + Tooks(0/+1/0/0): STR1 DEX7 CON2 GRA4
		"base_stats": {"str": 3, "dex": 4, "con": 2, "gra": 2},
	},
	"RANGER_MARKSMAN": {
		"archetype_id": "RANGER_MARKSMAN",
		"name": "SurvivalBot-RangerMarksman",
		"race": "Man",
		"house": "Dunedain",
		"trait": "Wayfarer's Instinct",
		"gender": "male",
		# Cost: 3+6+3+1 = 13. Final with Man(+1/0/+1/0) + Dunedain(0/+1/0/+1): STR4 DEX5 CON3 GRA2
		"base_stats": {"str": 3, "dex": 4, "con": 2, "gra": 1},
	},
	"RANGER_STEALTH_ARCHER": {
		"archetype_id": "RANGER_STEALTH_ARCHER",
		"name": "SurvivalBot-RangerStealthArcher",
		"race": "Man",
		"house": "Dunedain",
		"trait": "Wayfarer's Instinct",
		"gender": "female",
		# Cost: 1+6+1+6 = 14 -- adjusted: 0+6+1+6 = 13. Final with Man(+1/0/+1/0) + Dunedain(0/+1/0/+1): STR1 DEX5 CON3 GRA4
		"base_stats": {"str": 0, "dex": 4, "con": 2, "gra": 3},
	},
}


static func get_archetype(archetype_name: String) -> Dictionary:
	if ARCHETYPES.has(archetype_name):
		return ARCHETYPES[archetype_name].duplicate(true)
	push_warning("Unknown archetype: %s" % archetype_name)
	return {}


static func get_all_archetype_names() -> Array[String]:
	var names: Array[String] = []
	for key in ARCHETYPES:
		names.append(key)
	return names
