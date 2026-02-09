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
		# Cost: 0+6+1+6 = 13. Final with Hobbit(-2/+2/+2/+2) + Tooks(0/+1/0/0): STR-2 DEX6 CON3 GRA5
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
		# Pre-game: Lore 6, Will 2, Evasion 1 (1900 XP) + Hidden Ways/Deep Memory/Domination (1500 XP) = 3400 XP
		"skill_investments": {"lore": 6, "will": 2, "evasion": 1},
		"ability_purchases": [
			{"skill_type": 7, "ability_num": 0},   # Hidden Ways (lore 1)
			{"skill_type": 7, "ability_num": 2},   # Deep Memory (lore 2)
			{"skill_type": 7, "ability_num": 11},  # Word of Domination (lore 6)
		],
		"xp_spent_precreation": 3400,
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
		# Cost: -1+10+1+3 = 13. Final with Hobbit(-2/+2/+2/+2) + Tooks(0/+1/0/0): STR-1 DEX8 CON4 GRA5
		"base_stats": {"str": 1, "dex": 5, "con": 2, "gra": 3},
	},
	"STEALTH_ASSASSIN": {
		"archetype_id": "STEALTH_ASSASSIN",
		"name": "SurvivalBot-StealthAssassin",
		"race": "Hobbit",
		"house": "Of the Tooks",
		"trait": "Nimble Striker",
		"gender": "male",
		# Cost: 3+6+1+3 = 13. Final with Hobbit(-2/+2/+2/+2) + Tooks(0/+1/0/0): STR1 DEX7 CON4 GRA4
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
		# Cost: 0+6+1+6 = 13. Final with Man(+1/0/+1/0) + Dunedain(0/+1/0/+1): STR1 DEX5 CON3 GRA4
		"base_stats": {"str": 0, "dex": 4, "con": 2, "gra": 3},
	},
	# ========== v3 NEW ARCHETYPES ==========
	"POLEARM_MASTER": {
		"archetype_id": "POLEARM_MASTER",
		"name": "SurvivalBot-PolearmMaster",
		"race": "Man",
		"house": "Of Rohan",
		"trait": "Defiance",
		"gender": "male",
		# Cost: 6+3+3+1 = 13. Final with Man(+1/0/+1/0) + Rohan(+1/0/0/0): STR5 DEX2 CON3 GRA1
		"base_stats": {"str": 3, "dex": 2, "con": 2, "gra": 1},
	},
	"ELF_SMITH": {
		"archetype_id": "ELF_SMITH",
		"name": "SurvivalBot-ElfSmith",
		"race": "Elf",
		"house": "Of Rivendell",
		"trait": "Forge Intuition",
		"gender": "female",
		# Cost: 3+1+6+6 = 16 -> adjusted: 2+1+3+3 = 9 -> 2+1+6+3 = 12 -> adj: STR2 DEX1 CON3 GRA3 = 3+1+6+6=16 NO
		# Elf(-1/+2/+1/+2) + Rivendell(0/0/+1/0): need base to sum 13
		# base_stats: str=2 dex=1 con=2 gra=3 => cost: 3+1+3+6=13. Final: STR1 DEX3 CON4 GRA5
		"base_stats": {"str": 2, "dex": 1, "con": 2, "gra": 3},
	},
	"WILL_TANK": {
		"archetype_id": "WILL_TANK",
		"name": "SurvivalBot-WillTank",
		"race": "Dwarf",
		"house": "Of Khazad-dum",
		"trait": "Undying Resolve",
		"gender": "male",
		# Cost: 3+0+10+0 = 13. Final with Dwarf(+1/-1/+3/0) + Khazad-dum(0/0/0/+1): STR3 DEX-1 CON7 GRA1
		"base_stats": {"str": 2, "dex": 0, "con": 4, "gra": 0},
	},
	"HOBBIT_SNIPER": {
		"archetype_id": "HOBBIT_SNIPER",
		"name": "SurvivalBot-HobbitSniper",
		"race": "Hobbit",
		"house": "Of the Shire",
		"trait": "Steady Aim",
		"gender": "male",
		# Cost: 0+6+1+6 = 13. Final with Hobbit(-2/+2/+2/+2) + Shire(0/0/+1/0): STR-2 DEX6 CON4 GRA5
		"base_stats": {"str": 0, "dex": 4, "con": 1, "gra": 3},
	},
	"GREENWOOD_RANGER": {
		"archetype_id": "GREENWOOD_RANGER",
		"name": "SurvivalBot-GreenwoodRanger",
		"race": "Elf",
		"house": "Of Greenwood",
		"trait": "Patient Stalker",
		"gender": "female",
		# Cost: 1+3+3+6 = 13. Final with Elf(-1/+2/+1/+2) + Greenwood(0/+1/0/0): STR0 DEX5 CON3 GRA6
		"base_stats": {"str": 1, "dex": 2, "con": 2, "gra": 4},
	},
	"HOBBIT_BURGLAR": {
		"archetype_id": "HOBBIT_BURGLAR",
		"name": "SurvivalBot-HobbitBurglar",
		"race": "Hobbit",
		"house": "Of the Gamgees",
		"trait": "Shadow Step",
		"gender": "male",
		# Cost: 1+6+3+3 = 13. Final with Hobbit(-2/+2/+2/+2) + Gamgees(+1/0/0/0): STR0 DEX6 CON4 GRA4
		"base_stats": {"str": 1, "dex": 4, "con": 2, "gra": 2},
	},
	"BANISHMENT_MAGE": {
		"archetype_id": "BANISHMENT_MAGE",
		"name": "SurvivalBot-BanishmentMage",
		"race": "Elf",
		"house": "Of Lothlorien",
		"trait": "Song of Banishment",
		"gender": "male",
		# Cost: 0+0+3+10 = 13. Final with Elf(-1/+2/+1/+2) + Lorien(0/0/0/+1): STR-1 DEX2 CON3 GRA7
		"base_stats": {"str": 0, "dex": 0, "con": 2, "gra": 4},
		# Pre-game: Lore 6, Will 2, Evasion 1 (1900 XP) + Deep Memory/Light of Eldar/Domination (1500 XP) = 3400 XP
		"skill_investments": {"lore": 6, "will": 2, "evasion": 1},
		"ability_purchases": [
			{"skill_type": 7, "ability_num": 2},   # Deep Memory (lore 2)
			{"skill_type": 7, "ability_num": 5},   # Light of the Eldar (lore 3)
			{"skill_type": 7, "ability_num": 11},  # Word of Domination (lore 6)
		],
		"xp_spent_precreation": 3400,
	},
	"SHIELD_WALL": {
		"archetype_id": "SHIELD_WALL",
		"name": "SurvivalBot-ShieldWall",
		"race": "Man",
		"house": "Of Gondor",
		"trait": "Shield Brother",
		"gender": "male",
		# Cost: 6+0+6+1 = 13. Final with Man(+1/0/+1/0) + Gondor(0/0/+1/0): STR4 DEX0 CON5 GRA1
		"base_stats": {"str": 3, "dex": 0, "con": 3, "gra": 1},
	},
	# ========== v4 LORE REDESIGN ARCHETYPES ==========
	"LORE_HEALER": {
		"archetype_id": "LORE_HEALER",
		"name": "SurvivalBot-LoreHealer",
		"race": "Elf",
		"house": "Of Rivendell",
		"trait": "Echoes of the Firstborn",
		"gender": "female",
		# Cost: 0+0+6+6 = 12 -> adjusted: 0+1+6+6 = 13. Final with Elf(-1/+2/+1/+2) + Rivendell(0/0/+1/0): STR-1 DEX3 CON5 GRA6
		"base_stats": {"str": 0, "dex": 1, "con": 3, "gra": 3},
		# Pre-game: Lore 6, Will 1, Evasion 1 (1700 XP) + Deep Memory/Herbcraft/Domination (1500 XP) = 3200 XP
		"skill_investments": {"lore": 6, "will": 1, "evasion": 1},
		"ability_purchases": [
			{"skill_type": 7, "ability_num": 2},   # Deep Memory (lore 2)
			{"skill_type": 7, "ability_num": 3},   # Herbcraft (lore 2)
			{"skill_type": 7, "ability_num": 11},  # Word of Domination (lore 6)
		],
		"xp_spent_precreation": 3200,
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
