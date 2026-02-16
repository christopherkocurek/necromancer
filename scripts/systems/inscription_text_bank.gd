extends RefCounted
class_name InscriptionTextBank
## Provides a deterministic bank of 100 inscription lines per layer.
## Each layer composes 10 openers x 10 closers.

const _BANK: Dictionary = {
	"outer_pits": {
		"openers": [
			"Scrawl in ash: scout first, strike second.",
			"Scratched in haste: never trade in webs.",
			"Chiseled warning: keep one escape line open.",
			"Faded script: poison wins long fights.",
			"Knife-marked note: corners are shields.",
			"Etched plea: rest before the next door.",
			"Broken runes: noise calls more teeth.",
			"Smudged glyphs: kill the watcher first.",
			"Old chalk line: spend strength where it matters.",
			"Briar-stained mark: greed buries the quick.",
		],
		"closers": [
			"Move with purpose, not panic.",
			"Do not stand where they can surround you.",
			"Break line of sight before you bleed out.",
			"Treat every open room as a trap.",
			"Take one step back before two steps forward.",
			"Choose clean ground before committing.",
			"Preserve curatives for the next mistake.",
			"Count exits before counting kills.",
			"Let patience do the killing.",
			"Fear is useful if it makes you slower.",
		],
	},
	"lower_halls": {
		"openers": [
			"Orc-cut letters: shields break slower than pride.",
			"Camp-brand warning: captains call reinforcements.",
			"Carved in iron: crossbow lanes are death lanes.",
			"Barracks graffiti: chase stragglers and die.",
			"Forge soot note: steel is made between blows.",
			"Drilled command: isolate the loudest enemy.",
			"Helmet scratchings: never fight in the doorway center.",
			"Blood-inked order: break formation before they break you.",
			"Rusted inscription: pressure the weak flank.",
			"Warg-handler mark: sound carries farther than courage.",
		],
		"closers": [
			"Pull packs into narrow stone.",
			"Cut the scout before the horn sounds.",
			"Armor is time. Spend it well.",
			"Trade range for cover, not for ego.",
			"Hold reserves for the counterrush.",
			"A closed door is one stolen turn.",
			"Leave no archer with open sight-lines.",
			"Step out of kill funnels immediately.",
			"Noise discipline is survival discipline.",
			"Win the second exchange, not the first boast.",
		],
	},
	"dark_halls": {
		"openers": [
			"In charcoal: curses arrive before steel.",
			"Thin silver script: will is armor here.",
			"Shaken writing: slow feet become graves.",
			"Wax-sealed warning: control casters end runs.",
			"Burned etching: panic feeds their magic.",
			"Prisoner marks: retreat is a tactic, not shame.",
			"Ritual chalk: interrupt the first cast.",
			"Nicked stone: darkness hides second attackers.",
			"Black ink line: status debt compounds quickly.",
			"Crooked rune: keep antidotes where hands can reach.",
		],
		"closers": [
			"Break contact before your will breaks.",
			"Answer control with distance and cover.",
			"Keep one turn uncommitted.",
			"Fight fewer enemies per decision.",
			"Spend XP on answers, not fantasies.",
			"Never brawl while slowed.",
			"Recover composure before re-entry.",
			"See the caster, solve the caster.",
			"An escape route is part of your build.",
			"Delay is damage in another form.",
		],
	},
	"necropolis": {
		"openers": [
			"Mortar-pressed epitaph: light is a weapon.",
			"Bone-scratched line: the dead punish hesitation.",
			"Crypt note: attrition beats bravado.",
			"Chilled inscription: fear serves those who endure.",
			"Sepulcher carving: do not swing blindly.",
			"Gray chalk warning: undead count turns, not mercy.",
			"Lantern soot text: darkness is their home field.",
			"Grave-mason mark: chip away, do not overextend.",
			"Cold rune: keep stamina for the pullback.",
			"Marrow script: one bad corridor ends dynasties.",
		],
		"closers": [
			"Fight where your light reaches.",
			"Force them into your timing.",
			"Leave no flank unchecked.",
			"Burn pressure early, not late.",
			"Commit only with a retreat path.",
			"Sustain wins deeper than burst.",
			"Stabilize after every spike.",
			"Control the lane, control the fight.",
			"Respect the next room as a boss.",
			"Survival is cumulative craftsmanship.",
		],
	},
	"pits_of_despair": {
		"openers": [
			"Scored by gauntlet: despair is a resource drain.",
			"Heat-warped script: overpursuit feeds the pit.",
			"Soot-black command: kill windows are brief.",
			"Iron nail marks: mistakes echo for floors.",
			"Ashen warning: greed outruns healing.",
			"Cracked sigil: fear effects stack with terrain.",
			"Seared note: reserve tools for reversals.",
			"Broken carving: offense without timing is surrender.",
			"Smoldering line: your first retreat is the cheapest.",
			"Pit-rim etching: decisive does not mean reckless.",
		],
		"closers": [
			"Choose durable lines over flashy swings.",
			"Spend depth like a budget, not a race.",
			"Exit collapsing fights immediately.",
			"Treat cooldowns as lifelines.",
			"Control tempo or be consumed by it.",
			"Avoid multi-vector pressure at all costs.",
			"Stagger enemies, not your own plan.",
			"Preserve HP for unknown rooms.",
			"Beat the dungeon by refusing bad trades.",
			"Discipline is damage prevention.",
		],
	},
	"inner_sanctum": {
		"openers": [
			"Gold-fleck script: power without control is bait.",
			"Needle etching: elites punish wasted turns.",
			"Obsidian note: every angle is contested here.",
			"Court-carved warning: confidence draws aggro.",
			"Fine runes: execution must match planning.",
			"Black lacquer text: your build is now on trial.",
			"Polished scar line: pressure arrives in layers.",
			"Throne-ward mark: remove supports before centerpieces.",
			"Gilded glyphs: one lapse rewrites the floor.",
			"Catacomb hand: endurance is your final weapon.",
		],
		"closers": [
			"Respect every elite as a mini-boss.",
			"Stability before aggression.",
			"Sequence threats by lethality, not proximity.",
			"Use sight-lines as hard terrain.",
			"Plan two turns ahead at minimum.",
			"Take guaranteed value over variance.",
			"Preserve control tools for disaster turns.",
			"Never stand in layered threat cones.",
			"Win by reducing simultaneous risks.",
			"Precision keeps you alive this deep.",
		],
	},
	"throne_room": {
		"openers": [
			"Imperial script: the final chamber measures discipline.",
			"Etched oath: panic is the true end boss.",
			"Knife-carved vow: do not spend all answers at once.",
			"Burnished warning: pride is a terminal status.",
			"Royal rune: hold form under pressure spikes.",
			"Dark court decree: recover between exchanges.",
			"Shattered crown line: tempo decides thrones.",
			"Final inscription: survive the burst, then punish.",
			"Black-gold mark: every turn must justify itself.",
			"Last hand's message: finish clean or not at all.",
		],
		"closers": [
			"Keep composure when health crashes.",
			"Save one emergency tool at all times.",
			"Force predictable patterns before committing.",
			"Do not tunnel vision the title.",
			"Stability first, victory second.",
			"Make the fight smaller every turn.",
			"Punish recoverable windows only.",
			"Never donate turns to spectacle.",
			"The run ends when discipline ends.",
			"Win by denying catastrophe.",
		],
	},
}

static func get_line(layer_name: String, slot: int) -> String:
	var bank: Dictionary = _BANK.get(layer_name, _BANK["outer_pits"])
	var openers: Array = bank.get("openers", [])
	var closers: Array = bank.get("closers", [])
	if openers.is_empty() or closers.is_empty():
		return "An old inscription warns of haste and hubris."
	var idx: int = posmod(slot, 100)
	var opener_idx: int = idx / 10
	var closer_idx: int = idx % 10
	return "%s %s" % [String(openers[opener_idx]), String(closers[closer_idx])]

