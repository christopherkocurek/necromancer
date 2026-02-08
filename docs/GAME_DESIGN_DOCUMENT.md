# THE NECROMANCER
## Game Design Document
### Godot 4.6 Implementation -- Post-Alpha Build

**Version:** 2.0 (Godot Build)
**Last Updated:** 2026-02-08
**Build Status:** 45 commits, 162 files, 58k+ lines, 125/130 tests passing

---

# TABLE OF CONTENTS

1. [Vision and Setting](#1-vision-and-setting)
2. [Core Loop](#2-core-loop)
3. [Races and Houses](#3-races-and-houses)
4. [Hero Traits](#4-hero-traits)
5. [Skills and Abilities](#5-skills-and-abilities)
6. [Combat System](#6-combat-system)
7. [The Dungeon](#7-the-dungeon)
8. [Monsters](#8-monsters)
9. [Items and Equipment](#9-items-and-equipment)
10. [Stealth and Detection](#10-stealth-and-detection)
11. [Special Systems](#11-special-systems)
12. [Difficulty Modes](#12-difficulty-modes)
13. [Victory Conditions](#13-victory-conditions)
14. [Balance and Tuning](#14-balance-and-tuning)

---

# 1. VISION AND SETTING

## Concept

The Necromancer is a tactical roguelike forked from SIL-Q, rebuilt in Godot 4.6. The player
infiltrates Dol Guldur, Sauron's fortress in southern Mirkwood, to recover the Ring of
Thrain and Key to Erebor from the dying dwarf-king imprisoned in the deepest dungeons.

## Design Pillars

- **Tolkien Authenticity**: Third Age lore-accurate setting, races, and magic
- **SIL-Q Mechanics**: Opposed-roll combat, stealth, skills, and ability trees
- **Tension**: Escape-focused endgame with pursuit mechanics
- **Meaningful Choice**: Race/house/trait selection, item identification, risk-reward
- **Tactical Depth**: Every encounter matters; outthink, not outlevel

## Setting: Third Age, Year 2850

Dol Guldur -- the "Hill of Dark Sorcery" -- rises in southern Mirkwood on Amon Lanc,
the former capital of the Silvan Elves before Sauron's shadow fell upon it. Sauron,
disguised as "The Necromancer," has occupied the fortress. Thrain II, King of Durin's
Folk, was captured five years prior and languishes in the deepest dungeons, broken.

The player is sent on a desperate mission: descend into Dol Guldur, find the dying
dwarf-king, and recover what he carries. This mirrors Gandalf's canonical quest in
Tolkien's legendarium.

## Key Differences from SIL-Q

| SIL-Q | The Necromancer |
|-------|-----------------|
| First Age | Third Age |
| Angband (Morgoth's fortress) | Dol Guldur (Sauron's fortress) |
| Retrieve Silmaril from Morgoth | Retrieve Ring + Key from Thrain |
| Song magic system | Lore magic system + Sustained Songs |
| Noldor/Sindar/Naugrim/Edain | Elf/Man/Dwarf/Hobbit with Third Age houses |
| Descend and escape | Descend, find Thrain, escape (or banish Sauron) |
| No difficulty modes | 4 selectable difficulty modes |
| No traits | 20 hero traits defining playstyle archetypes |

## Lore Accuracy Notes

### What Is at Dol Guldur (per Tolkien)

- Orcs, Trolls, Giant Spiders, Wargs
- Evil spirits, possibly vampires and werewolves
- Easterling servants
- The Necromancer (Sauron in disguise)
- Three Nazgul stationed there (including Khamul)
- Thrain II, imprisoned and tortured

### Magic in the Third Age

- Greatly diminished from the First Age
- No direct "singing power into the world" like the Ainur
- More subtle: words of power, knowledge, devices
- Wizards use staves and words, not flashy spells
- Rings of Power are the main source of magical might

---

# 2. CORE LOOP

## Primary Loop

```
Create Character --> Descend --> Explore --> Fight/Sneak --> Loot --> Level Skills
      ^                                                                    |
      |                   <--- Find Thrain (depth 15+) <---               |
      |                                                                    v
  Game Over  <---  Die  <---  Escape Upward  <---  Sauron Pursues  <--- Take Ring
      |
  Victory (surface reached with Ring + Key, or Sauron banished)
```

### Step by Step

1. **Character Creation**: Choose race, house, gender, trait, allocate stats, name
2. **Descend**: Enter Dol Guldur at depth 1, proceed downward through 20 floors
3. **Explore**: Reveal procedurally generated rooms, corridors, and vaults via FOV
4. **Fight or Sneak**: Engage enemies in tactical melee or slip past them in stealth
5. **Loot**: Gather weapons, armor, herbs, potions, scrolls, and artifacts
6. **Develop Skills**: Spend earned XP on 8 skill trees and 93 abilities
7. **Reach the Bottom**: Find Thrain at depth 15+ to receive Ring and Key
8. **Escape or Banish**: Ascend to surface while pursued, or assemble the Rod of the
   Istari and banish Sauron

## Permadeath

Death is permanent. The save system enforces this: saves are deleted on death. Each run
teaches the player more about game systems, making the next character more likely to
succeed.

## Turn Structure

The game uses an energy-based turn system inherited from SIL-Q:

- Each entity has a `speed` value (0-7)
- `ENERGY_TABLE[speed]` determines energy gained per game tick: `[50, 75, 100, 125, 150, 175, 200, 250]`
- An entity acts when accumulated energy >= `ACTION_COST` (100)
- Speed 2 (100 energy/tick) = 1 action per tick (standard)
- Faster entities accumulate energy more quickly and act more often

---

# 3. RACES AND HOUSES

## Design Philosophy

- Stat totals range from +2 (hard mode) to +4 (easier)
- Each race has distinct mechanical identity and weapon proficiency
- Houses provide specialization within race via skill affinities and stat bonuses
- Asymmetric balance creates meaningful choice
- The Istari race exists for playtesting only (+40 stats)
- The Hobbit race adds a stealth-focused option with unique mechanics

## Playable Races

### Elf

**Base Stats**: STR -1 / DEX +2 / CON +1 / GRA +2 (Total: +4)
**Proficiency**: BOW_PROFICIENCY (+1 archery with bows)
**Starting Gear**: Wooden Torch, Fragment of Lembas (x2), Curved Sword
**Houses**: Lothlorien, Rivendell, Greenwood

*The Eldar of the Third Age have dwindled but remain wise and fair. Whether from the
golden woods of Lothlorien, the hidden valley of Rivendell, or the dark forests of
Greenwood, they possess keen senses and ancient knowledge.*

### Man

**Base Stats**: STR +1 / DEX 0 / CON +1 / GRA 0 (Total: +2)
**Proficiency**: SWORD_PROFICIENCY (+1 melee with swords)
**Starting Gear**: Wooden Torch, Pieces of Dark Bread (x3), Curved Sword
**Houses**: Dunedain, Rohan, Gondor

*Men are mortal and fleeting, yet in the Third Age many great kingdoms still stand. The
Rangers carry the blood of Numenor, the Rohirrim are famed horsemasters, and Gondor's
soldiers defend the West against the Shadow.*

### Dwarf

**Base Stats**: STR +1 / DEX -1 / CON +3 / GRA 0 (Total: +3)
**Proficiency**: AXE_PROFICIENCY (+1 melee with axes)
**Penalties**: ARC_PENALTY (-1 archery), DWARVEN_RESILIENCE
**Starting Gear**: Wooden Torch, Pieces of Dark Bread (x2), Dwarven Hammer
**Houses**: Khazad-dum, Erebor, Iron Hills

*A tough and secretive people, master craftsmen and fierce warriors. Their hatred of
orcs and dragons is legendary. Dwarves have the highest Constitution of any race.*

### Hobbit

**Base Stats**: STR -2 / DEX +2 / CON 0 / GRA +2 (Total: +2)
**Proficiency**: SLING_PROFICIENCY (+1 archery with slings)
**Flags**: SMALL_STATURE (+2 stealth, -2 att from large monsters), HOBBIT_LUCK (reroll lethal d20 once per floor)
**Starting Gear**: Wooden Torch, Seed Cakes (x3), Sylvan Blade, Sling, Sling Stones (x5)
**Houses**: Of the Shire, Of the Gamgees, Of the Tooks

*Small, quiet folk who love peace and good food. Yet when pressed, they show remarkable
resilience. Their small stature makes them hard to hit and easy to overlook.*

### Istari (Debug)

**Base Stats**: STR +10 / DEX +10 / CON +10 / GRA +10 (Total: +40)
**Proficiency**: All
**Starting Gear**: Feanorian Lamp, Horn of Blasting, Lembas (x10), all wands, Curved Sword

*Debug race for playtesting. Not intended for normal play.*

## Houses

### Elf Houses

| House | STR | DEX | CON | GRA | Affinity | Combined Total |
|-------|-----|-----|-----|-----|----------|----------------|
| **Of Lothlorien** | 0 | 0 | 0 | +1 | Lore | +5 |
| **Of Rivendell** | 0 | 0 | +1 | 0 | Smithing | +5 |
| **Of Greenwood** | 0 | +1 | 0 | 0 | Stealth | +5 |

### Man Houses

| House | STR | DEX | CON | GRA | Affinity | Combined Total |
|-------|-----|-----|-----|-----|----------|----------------|
| **Dunedain** | 0 | +1 | 0 | +1 | Perception | +4 |
| **Of Rohan** | +1 | 0 | 0 | 0 | Evasion | +3 |
| **Of Gondor** | 0 | 0 | +1 | 0 | Melee | +3 |

### Dwarf Houses

| House | STR | DEX | CON | GRA | Affinity | Combined Total |
|-------|-----|-----|-----|-----|----------|----------------|
| **Of Khazad-dum** | 0 | 0 | 0 | +1 | Lore | +4 |
| **Of Erebor** | 0 | 0 | +1 | 0 | Smithing | +4 |
| **Of the Iron Hills** | +1 | 0 | 0 | 0 | Melee | +4 |

### Hobbit Houses

| House | STR | DEX | CON | GRA | Affinity | Combined Total |
|-------|-----|-----|-----|-----|----------|----------------|
| **Of the Shire** | 0 | 0 | +1 | 0 | Will | +3 |
| **Of the Gamgees** | +1 | 0 | 0 | 0 | Smithing | +3 |
| **Of the Tooks** | 0 | +1 | 0 | 0 | Stealth | +3 |

## Difficulty Ranking by Build

| Build | Total Stats | Difficulty |
|-------|-------------|------------|
| Elf of Lothlorien | +5 | Easiest |
| Elf of Rivendell | +5 | Easy |
| Elf of Greenwood | +5 | Easy |
| Dwarf of Khazad-dum | +4 | Medium |
| Dunedain | +4 | Medium |
| Dwarf of Erebor | +4 | Medium |
| Dwarf of Iron Hills | +4 | Medium |
| Man of Rohan | +3 | Hard |
| Man of Gondor | +3 | Hard |
| Hobbit of the Shire | +3 | Hard |
| Hobbit of the Gamgees | +3 | Hard |
| Hobbit of the Tooks | +3 | Hard |

## Stat Allocation at Creation

- **Total points**: 13
- **Stat range**: -4 to +6
- **Cost curve**: `[-4, -3, -2, -1, 0, 1, 3, 6, 10, 15, 21]`
  (indexed by stat+4, so stat 0 costs 0 points, stat +3 costs 6 points, etc.)
- Final stats = base allocation + race modifiers + house modifiers

---

# 4. HERO TRAITS

Each character selects one trait during creation. Traits define the hero's playstyle
archetype and provide a unique passive or triggered ability.

**Source**: `data/trait.txt` (20 traits defined)

| ID | Trait | Effect ID | Description |
|----|-------|-----------|-------------|
| 0 | **Defiance** | `defiance` | +1 attack and damage vs enemies whose native depth exceeds current floor by 3+ |
| 1 | **Ambush Mastery** | `ambush_mastery` | Extra damage die vs unaware enemies. Stacks with Assassination and Opening Strike |
| 2 | **Light of the Eldar** | `light_of_eldar` | +1 light radius. Undead within light radius suffer -2 attack and evasion |
| 3 | **Last Stand** | `last_stand` | Below 25% HP: +3 attack, damage, and evasion |
| 4 | **Fortune's Favor** | `fortunes_favor` | Once per floor, reroll a failed saving throw or resistance check |
| 5 | **Undying Resolve** | `undying_resolve` | Once per game, survive lethal damage at 50% HP instead of dying |
| 6 | **Rallying Cry** | `rallying_cry` | On kill, visible enemies must save Will or lose 20 morale |
| 7 | **Song of Banishment** | `song_of_banishment` | Start game with Song of Banishment ability regardless of Lore level |
| 8 | **Forge Intuition** | `forge_intuition` | Items you pick up are automatically identified |
| 9 | **Shadow Step** | `shadow_step` | Once per floor, teleport adjacent to any visible unaware enemy. Costs 50 energy |
| 10 | **Steady Aim** | `steady_aim` | Standing still without attacking: next ranged attack gains +3 hit, +1 crit die |
| 11 | **Oath of Enmity** | `oath_of_enmity` | First kill type per floor becomes sworn foe: +2 attack, +1 damage die. -1 vs others |
| 12 | **Mithril Skin** | `mithril_skin` | +1d2 innate protection. Evasion capped at 10. Requires CON 3+ |
| 13 | **Wayfarer's Instinct** | `wayfarers_instinct` | Detect traps within 3 tiles. On floor entry, reveal doors/stairs within 8 tiles. -2 movement noise |
| 14 | **Nimble Striker** | `nimble_striker` | Move + attack in same turn: +2 evasion. Kill this way: next move costs no energy |
| 15 | **Whisper of the Valar** | `whisper_of_valar` | Once per floor, spend 3 voice to reveal enemies in radius 6 for 5 turns. -2 to their Will. Requires GRA 2+ |
| 16 | **Blood of Numenor** | `blood_of_numenor` | +1 damage vs Undead/Evil. Immune to Entranced. Heal 1 less from food/rest. Man only |
| 17 | **Patient Stalker** | `patient_stalker` | While stealthing with no adjacent alert enemies: +3 stealth. After 3+ stealth turns: first attack deals double damage |
| 18 | **Shield Brother** | `shield_brother` | With shield: +1 melee, adjacent enemies -1 evasion. If Blocking known, halve incoming ranged damage |
| 19 | **Echoes of the Firstborn** | `echoes_firstborn` | +2 voice charges per floor. All Lore abilities cost 1 less voice (min 1). Base speed reduced by 1 tier |

---

# 5. SKILLS AND ABILITIES

## Skill System

The Necromancer uses an XP-as-currency system. There are no character levels; instead,
XP is earned and spent directly on 8 skill trees.

**Source**: `scripts/entities/player.gd`, `scripts/core/constants.gd`

### The 8 Skills

| ID | Skill | Primary Stat | Role |
|----|-------|-------------|------|
| 0 | Melee | STR | Weapon attack bonus (+1 per level) |
| 1 | Archery | DEX | Ranged attack bonus (+1 per level) |
| 2 | Evasion | DEX | Defense / dodge (+1 per level) |
| 3 | Stealth | DEX | Sneaking, assassination |
| 4 | Perception (Hunting) | GRA | Trap avoidance (50% + Per*5%), monster memory |
| 5 | Will | GRA | Mental resistance, banishment check |
| 6 | Smithing | GRA | Forge success chance (skill * 5%) |
| 7 | Lore | GRA | Ability power scaling, monster memory bonus |

### XP Economy

- **Starting XP**: 5,000
- **XP Multiplier**: 1.3x (130% of base SIL-Q rate)
- **Skill cost formula**: `100 * (current_level + 1)` XP per point
  - Level 0 to 1: 100 XP
  - Level 1 to 2: 200 XP
  - Level 5 to 6: 600 XP
  - Level 10 to 11: 1,100 XP
- **Max skill level**: 20
- **XP sources**: Monster kills (depth-scaled), descent XP (depth * 50), item identification, discovery objects

### Derived Stats from Skills

- **Melee bonus**: `melee_skill + (STR / 2) + equipment_bonuses`
- **Evasion bonus**: `evasion_skill + (DEX / 2) + equipment_bonuses`
- **Max HP**: `24 * 1.2^CON` (compounding 20% per CON point)
- **Max Voice**: `20 * 1.2^GRA` (compounding 20% per Grace point)
- **Voice Regen**: `max_voice / 150` per turn (full pool regenerates over 150 turns)

## Ability Trees

93 abilities across 8 skill trees. Abilities are purchased with XP at cost
`(level_requirement + 1) * 300` and require meeting the skill level prerequisite.

**Source**: `data/ability.txt`, `scripts/systems/ability_system.gd`

### Melee Abilities (14)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 0 | Power | 1 | +1 damage sides, harder crits (+1 base threshold) |
| 1 | Finesse | 2 | Lowers crit threshold from 7 to 5 |
| 2 | Knock Back | 3 | Chance to push enemies back based on STR vs CON |
| 3 | Polearm Mastery | 4 | +2 attack with polearms, free attacks on advancing enemies |
| 4 | Charge | 5 | +3 STR and DEX when attacking after moving toward enemy |
| 5 | Follow-Through | 6 | Continue attacking next adjacent enemy after a kill (requires Power or Finesse) |
| 6 | Opening Strike | 7 | +1 damage die on first attack vs unwary/sleeping enemies (requires Finesse) |
| 7 | Subtlety | 8 | -2 crit threshold with one-handed weapon and free off-hand (requires Finesse) |
| 8 | Cleave | 9 | Free attacks on all adjacent enemies after a kill (requires Polearm Mastery + Follow-Through) |
| 9 | Zone of Control | 10 | Free attack when enemy moves between two adjacent squares (requires Finesse + Polearm Mastery) |
| 10 | Mighty Blow | 11 | Two-handed weapon: bonus damage equal to STR, costs next turn (requires Knock Back + Charge) |
| 11 | Defensive Stance | 12 | +3 evasion when stationary, no flanking bonuses against you (requires Finesse + Blocking) |
| 12 | Swift Strikes | 13 | Extra attack with one-handed weapon at -3 STR and DEX (requires Subtlety + Assassination) |
| 13 | +Strength | 20 | +1 Strength |

### Archery Abilities (9)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 20 | Rout | 2 | +5 DEX when firing at fleeing monsters |
| 21 | Fletchery | 3 | Create +3 arrows from ordinary ones |
| 22 | Point Blank Archery | 4 | No attack of opportunity when firing adjacent |
| 23 | Puncture | 5 | 5 flat damage when armor fully blocks arrow damage |
| 24 | Ambush | 6 | +1 crit die vs unwary/sleeping targets |
| 25 | Keen Eyes | 7 | +2 archery at range 5+, see enemies at edge of dim light |
| 26 | Crippling Shot | 8 | Critical hits sometimes slow monsters (requires Puncture + Ambush) |
| 27 | Deadly Hail | 9 | Double damage on arrows fired turn after arrow kill (requires Rout + Puncture) |
| 28 | +Dexterity | 10 | +1 Dexterity |

### Evasion Abilities (11)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 40 | Dodging | 2 | +3 evasion if you moved last turn |
| 41 | Blocking | 3 | Doubles shield protection if you did not move last turn |
| 42 | Parry | 4 | Doubles evasion bonus from primary melee weapon |
| 43 | Crowd Fighting | 5 | Halves surround bonus enemies get |
| 44 | Leaping | 6 | Leap over chasms/traps if you moved toward them |
| 45 | Sprinting | 7 | +1 speed for 3+ turns when running in same direction (requires Dodging + Leaping) |
| 46 | Flanking | 8 | Free attack when stepping between two adjacent squares of an enemy |
| 47 | Heavy Armour Use | 9 | [1dX] bonus protection where X = total armor weight / 15 lbs (requires Blocking + Crowd Fighting) |
| 48 | Riposte | 10 | Free counterattack when enemy misses by 10+ weapon weight (1/round) (requires Parry) |
| 49 | Controlled Retreat | 11 | Free attack when stepping away from enemy, if you didn't move last turn (requires Dodging + Blocking) |
| 50 | +Dexterity | 20 | +1 Dexterity |

### Stealth Abilities (12)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 60 | Disguise | 3 | Halves LOS detection bonuses from unwary enemies |
| 61 | Assassination | 4 | +Stealth_skill to melee attack vs non-alert creatures |
| 62 | Disorienting Strike | 5 | Crits confuse monsters (crit level vs Will) (requires Assassination) |
| 63 | Escape Artist | 6 | Auto-break from webs. Traps deal half damage, no alert (requires Disguise + Crowd Fighting) |
| 64 | Light Fingers | 7 | Steal from adjacent unwary enemy without alerting (requires Assassination) |
| 65 | Vanish | 8 | +10 stealth bonus to making enemies unwary out of LOS (requires Disguise) |
| 66 | +Dexterity | 11 | +1 Dexterity (requires Disguise + Assassination) |
| 67 | Throat Slit | 4 | Instant kill sleeping/unaware humanoids silently (requires Assassination) |
| 68 | Fade | 9 | Killing unaware enemy grants 2 turns invisibility (requires Assassination + Vanish) |
| 69 | Pilfer | 10 | 25% chance kills drop extra item (requires Light Fingers) |
| 70 | Distraction | 6 | Alert enemy missing by 5+: confused 1 turn (requires Disguise) |
| 71 | Silent Kill | 12 | Removes humanoid restriction from Throat Slit (requires Throat Slit + Fade) |

### Perception (Hunting) Abilities (10)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 80 | Natural Talent | 1 | Take advanced abilities without usual prerequisites |
| 81 | Focused Attack | 2 | +Hunting/2 to attacks if you waited last turn |
| 82 | Keen Senses | 3 | See enemies at edge of light pools, +5 to spot invisible |
| 83 | Concentration | 4 | +1 attack per consecutive round attacking same enemy (max Hunting/2) |
| 84 | Alchemy | 5 | Identify all herbs/potions. Combine identical herbs for stronger versions |
| 85 | Bane | 6 | Bonus to all skill rolls vs a selected enemy category (scales with kills) |
| 86 | Outwit | 7 | Hunting vs Perception to negate crit damage when you receive a critical hit |
| 87 | Listen | 8 | Chance each turn to detect enemies you can't see (requires Keen Senses) |
| 88 | Master Hunter | 9 | +1 attack per kill of same type (max Hunting/2) (requires Concentration + Bane) |
| 89 | +Grace | 10 | +1 Grace |

### Will Abilities (11)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 100 | Curse Breaking | 1 | Break curses when removing items |
| 101 | Force of Will | 2 | Recognize all staves/horns, use them 2x efficiently |
| 102 | Strength in Adversity | 3 | +1 STR/DEX/GRA at 50% HP, +3 at 25% HP |
| 103 | Formidable | 4 | Melee kills scare visible enemies. Enemies don't gain morale from your injuries |
| 104 | Defy Death | 5 | Once per floor, Will save to survive at 1 HP (requires Strength in Adversity) |
| 105 | Indomitable | 5 | Resist fear/confusion/stun/hallucination. Hunger slowed to 1/3 rate |
| 106 | Oath | 6 | Swear a great oath and be rewarded for keeping it |
| 107 | Poison Resistance | 7 | Resistance to poison |
| 108 | Vengeance | 8 | When damaged in melee, +1 damage die on next hit (requires Strength in Adversity) |
| 109 | Majesty | 9 | Lower monster morale by half the Will difference (requires Curse Breaking + Defy Death) |
| 110 | +Constitution | 12 | +1 Constitution |

### Smithing Abilities (12)

| ID | Name | Level | Description |
|----|------|-------|-------------|
| 120 | Weaponsmith | 2 | Create weapons at forges |
| 121 | Armoursmith | 3 | Create armour at forges |
| 122 | Jeweller | 4 | Create rings, amulets, light sources. Identify such items |
| 123 | Reforge | 5 | Combine 2 Broken Glowing items for a random enchanted item (600 XP) |
| 124 | Expertise | 6 | Halve forging time and costs. At Smithing 10+: reduce to 25% (requires Reforge) |
| 125 | Reclaim | 7 | Combine 2 Broken Strange items for a random artifact (requires Reforge) |
| 126 | Masterwork | 8 | Combine 4 Broken Strange items for a legendary artifact (requires Reclaim) |
| 127 | +Grace | 10 | +1 Grace |
| 128 | Reforge Mastery | 12 | Reject and reroll one Reforge result (requires Reforge) |
| 129 | Salvage | 14 | 50% chance to recover equipment as Broken Glowing on destruction (requires Reforge Mastery) |
| 130 | Reclaim Mastery | 16 | Choose from 3 artifacts when using Reclaim (requires Reclaim) |
| 131 | Master Smith | 20 | Masterwork with only 2 Broken Strange items (requires Masterwork) |

### Lore Abilities (18)

The Lore tree replaces SIL-Q's Song tree and is the most fully implemented ability
tree, with 18 abilities including 3 sustained songs.

| ID | Name | Type | Level | Voice Cost | Description |
|----|------|------|-------|------------|-------------|
| 140 | Word of Command | Active | 1 | 3 | AOE fear + stun (at Lore 8+). Radius 2 + Lore/4. Opposed Will check |
| 141 | Lore of Battle | Active | 1 | 1 | Provoke target: -2 evasion, +2 damage for 3 + Lore/4 turns |
| 142 | Deep Memory | Active | 2 | 2 | Reveal dungeon layout in radius Lore*3 (capped 5-30) |
| 143 | Word of Opening | Active | 2 | 2 | Open closed doors and clear rubble in radius 3 + Lore/3 |
| 144 | Lore of Silence | Active | 3 | 2 | Reduce monster perception in radius 4 + Lore/3 for 5 + Lore/2 turns |
| 145 | Herbcraft | Passive | 3 | -- | Double healing from herbs and potions |
| 146 | Word of Shutting | Active | 4 | 2 | Seal open doors in radius 2 + Lore/4 (requires Word of Command + Deep Memory) |
| 147 | Inner Light | Active | 5 | 3 | Damage light-sensitive monsters in light radius (requires Word of Command + Herbcraft) |
| 148 | Deadly Lore | Triggered | 6 | -- | Crits kill if target HP <= 2 * Lore (requires Lore of Battle + Word of Opening) |
| 149 | Lore of Endurance | Passive | 7 | -- | +Lore/2 Will bonus, +2d2 protection (requires Lore of Battle + Herbcraft) |
| 150 | Lore of Sleep | Active | 8 | 3 | Put target to sleep (Will check) (requires Lore of Silence + Deep Memory) |
| 151 | Word of Mastery | Active | 10 | 4 | Paralyze target (heavy stun, opposed Will +5 difficulty) (requires Word of Opening + Lore of Silence) |
| 152 | Device Mastery | Passive | 11 | -- | +50% wand/staff charges |
| 153 | +Grace | Passive | 12 | -- | +1 Grace stat |
| 154 | Song of Banishment | Active | 6 | 3 | AOE undead flee, ignores NO_FEAR, 1/floor (requires Word of Command + Herbcraft) |
| 155 | Song of Freedom | Sustained | 4 | 1/turn | +3 evasion while singing |
| 156 | Song of the Trees | Sustained | 5 | 1/turn | +5 stealth while singing (requires Lore of Silence) |
| 157 | Song of Aule | Sustained | 7 | 2/turn | +2 melee while singing (requires Word of Command) |

### Sustained Song Mechanics

Sustained songs are a toggle system inherited from SIL-Q's singing:

- Toggle on/off from the Voice menu (V key)
- Drain voice charges per turn while active
- Only one song can be active at a time
- Starting a new song stops the current one
- Song automatically ends when voice charges are depleted
- Voice regeneration continues (reduced) while singing

---

# 6. COMBAT SYSTEM

## Hit Resolution (Opposed d20 Rolls)

**Source**: `scripts/entities/entity.gd`

All attacks resolve through opposed d20 rolls:

```
attack_score  = d20 + melee_bonus
evasion_score = d20 + evasion_bonus
hit_result    = attack_score - evasion_score
```

| Result | Outcome |
|--------|---------|
| >= 0   | HIT (attacker wins ties) |
| < 0    | MISS |

## Damage Calculation

```
weapon_weight = equipped weapon weight in 0.1 lb units
damage = roll_dice(weapon_damage_dice)

# STR bonus capped by weapon weight
str_bonus = STR / 2
weight_cap = weapon_weight / 10
actual_str_bonus = min(str_bonus, weight_cap)
damage += actual_str_bonus

# Critical hit bonus dice
crit_dice = (hit_result * 10 + 4) / (70 + weapon_weight)

# Roll weapon dice again for each crit die
for each crit_die:
    damage += roll_dice(weapon_damage_dice)
```

**Design**: Heavier weapons make crits harder but allow more STR bonus. Light weapons
crit easily but cap STR contribution.

## Protection (Damage Reduction)

```
protection = SUM of damroll(pd, ps) for each armor piece

# Shield special rules:
shield_prt = damroll(pd * mult, ps)
  where mult = 2 if Blocking ability + didn't move, else 1

# Net damage
net = max(0, damage - protection)
```

Protection uses dice rolls rather than flat AC, creating variance in damage taken.

## Skill Check Formula

Used for stealth, Will saves, and other non-combat checks:

```
d10 + skill  vs  d10 + difficulty
result > 0 = success
```

## Status Effects

| Effect | Per-Turn Damage | Notes |
|--------|----------------|-------|
| Poison | `power` damage | Up to 100 stacks |
| Burning | `power * 2` fire damage | |
| Bleeding | `power` physical | Up to 100 stacks |
| Regeneration | `power` healing | |
| Blind | -- | Attack/evasion halved |
| Confused | -- | Random movement |
| Afraid | -- | Forced fleeing behavior |
| Stunned | -- | Skip turn (heavy stun = 50+, knockout = 100+) |
| Slow | -- | Reduced speed |
| Fast | -- | Increased speed |
| Entranced | -- | Cannot act |
| Darkened | -- | Reduced vision |

## Damage Floaters

Visual feedback with color-coded floating text:
- Physical: Red
- Fire: Orange
- Cold: Light Blue
- Poison: Green
- Dark: Purple
- Healing: Bright Green
- Miss: Gray
- Critical: Yellow

Floaters scale by damage (16px base, 20px for 10+, 24px for 20+).

---

# 7. THE DUNGEON

## Layer Structure

The dungeon spans 20 depths across 7 thematic layers.

**Source**: `scripts/systems/layer_config.gd`, `scripts/systems/dungeon_generator.gd`

| Layer | Depths | Name | FOV | Tint | Theme |
|-------|--------|------|-----|------|-------|
| 1 | 1-3 | Outer Pits | 8 | None | Spiders, bats, orc scouts |
| 2 | 4-6 | Lower Halls | 8 | Green | Orcs, wargs, forges |
| 3 | 7-9 | Dark Halls | 7 | Blue | Sorcerers, ghouls, torture racks |
| 4 | 10-12 | Necropolis | 7 | Purple | Undead, crypts, wights |
| 5 | 13-15 | Pits of Despair | 6 | Red/Orange | Shadows, vampires, heat |
| 6 | 16-18 | Inner Sanctum | 6 | Gold | Black Numenoreans, Khamul |
| 7 | 19-20 | Throne Room | 5 | Dark Gold | Sauron, Thrain |

## Generation Algorithm

Room-and-corridor generation with retry logic for connectivity:

1. **Rooms**: Random placement with overlap checking, up to 100 attempts
2. **Room Types**: Standard, Cross, L-Shape, Circular, Cave (cellular automata), Alcove
3. **Corridors**: L-shaped connections between sequential rooms + random extra loops
4. **Vaults**: Template placement from `vault.txt` (96 templates) based on depth/layer
5. **Features**: Doors (at corridor junctions), rubble, forges
6. **Transition Vaults**: Force-placed at layer boundaries
7. **Stairs**: Up stairs placed first, down stairs placed far from up
8. **Monsters**: 3+depth to 5+depth*2 (max 20), minimum 5 tiles from stairs
9. **Items**: 2+depth/2 to 4+depth (max 15)
10. **Post-processing**: Layer decoration, storytelling scatter, artifact spawns

### Room Types

| Type | Shape | Where Used |
|------|-------|------------|
| Standard | Rectangle | All layers |
| Cross | Two overlapping rectangles | All layers |
| L-Shape | Rectangle with corner cutout | All layers |
| Circular | Distance-based circle fill | All layers |
| Cave | Cellular automata (45% fill, 4-5 rule, 4 iterations) | Outer Pits (30%), Pits of Despair (15%) |
| Alcove | Rectangle with 2-4 wall recesses | Necropolis (25%) |

### Layer-Specific Generation Parameters

| Layer | Rooms | Size | Corridors | Vault Chance |
|-------|-------|------|-----------|-------------|
| Outer Pits | 6-12 | 4-10 | Width 1 | 10% |
| Lower Halls | 7-14 | 4-12 | Width 1 | 15% |
| Dark Halls | 6-12 | 5-14 | Width 1 | 20% |
| Necropolis | 8-16 | 5-16 | Width 2 | 25% |
| Pits of Despair | 5-10 | 6-18 | Width 2 | 30% |
| Inner Sanctum | 4-8 | 8-20 | Width 2 | 40% |
| Throne Room | 2-5 | 10-25 | Width 3 | 50% |

## Vault System

96 vault templates organized by layer:

| Range | Purpose |
|-------|---------|
| N:1 | Gates of Dol Guldur (entrance) |
| N:10-29 | Layer 1 vaults |
| N:30-49 | Layer 2 vaults |
| N:50-69 | Layer 3 vaults |
| N:70-89 | Layer 4 vaults |
| N:90-109 | Layer 5 vaults |
| N:110-129 | Layer 6 vaults |
| N:130-149 | Layer 7 vaults |
| N:200-209 | Transition vaults (between layers) |
| N:300-309 | Lesser vaults |
| N:400-409 | Greater vaults (max 1 per floor, tracked for uniqueness) |
| N:450 | Sauron's Throne Room |

## Tile Types

```
VOID, FLOOR, WALL, DOOR_CLOSED, DOOR_OPEN, STAIRS_DOWN, STAIRS_UP,
CHASM, RUBBLE, FORGE, TRAP, TRAP_TRIGGERED
```

## Room Lighting

- Shallow floors are mostly lit (80% chance at depth 1, decreasing by 4% per depth)
- Deep floors are mostly dark (minimum 10% lit at depth 18+)
- Dark zones at depth 10+: frequency 20% at depth 10, increasing to 80% at depth 20

## Level Dimensions

Default: 80 tiles wide x 40 tiles tall (5120 x 2560 pixels at 64px/tile)

---

# 8. MONSTERS

## Population

**Source**: `data/monster.txt` (77 entries: 55 combat + 10 hallucination + unique NPCs)

## Monsters by Layer

| Layer | Depths | Regulars | Bosses | Uniques | Total |
|-------|--------|----------|--------|---------|-------|
| 1 -- Forest Breach | 1-3 | 12 | 1 (Broodmother) | -- | 13 |
| 2 -- Orc Warrens | 3-6 | 10 | 1 (Orc Warchief) | 1 (Gashnak) | 12 |
| 3 -- Torture Halls | 6-9 | 10 | 1 (Master Sorcerer) | 1 (Karvag) | 12 |
| 4 -- Necropolis | 9-12 | 9 | -- | 1 (Grishnakh) | 10 |
| 5 -- Wraith Domain | 12-15 | 9 | 1 (Uvatha) | 1 (Wailing Horror) | 11 |
| 6 -- Inner Sanctum | 15-18 | 8 | 1 (Khamul) | -- | 9 |
| 7 -- Pits of Despair | 18-20 | 5 | 1 (Sauron) | 1 (Thrain's Shade) | 7 |

## Monster Spawn Tables by Layer

| Layer | Primary Types (weights) |
|-------|------------------------|
| Outer Pits | spider 30, vermin 30, flier 15, warg 15, orc 10 |
| Lower Halls | orc 50, warg 25, troll 10, spider 10, vermin 5 |
| Dark Halls | human_enemy 40, undead 20, troll 15, orc 15, shadow 10 |
| Necropolis | undead 35, wight 20, human_enemy 20, shadow 15, vampire 10 |
| Pits of Despair | shadow 30, human_enemy 25, vampire 15, undead 15, elite 15 |
| Inner Sanctum | human_enemy 40, undead 25, elite 15, shadow 10, vampire 10 |
| Throne Room | elite 40, shadow 25, human_enemy 20, undead 15 |

## AI State Machine

**Source**: `scripts/entities/monster.gd`

Four AI states with transitions based on alertness thresholds, morale, and LOS:

| State | Behavior |
|-------|----------|
| IDLE | Stationary, low alertness |
| WANDERING | Random movement, checking for player |
| HUNTING | A* pathfinding to player, attacks when adjacent |
| FLEEING | Move away from player, low morale |

### AI Features

- **Pathfinding**: A* via `Level.find_path()` with fallback to direct movement
- **Target tracking**: Remembers last known player position
- **Pack surround**: Monsters with FRIENDS flag try to flank rather than beeline
- **Door interaction**: OPEN_DOOR flag allows opening doors
- **Status effects on AI**: Confused = random movement, Afraid = flee, Blind = wander, Stunned = skip

## Alertness System

**Source**: `scripts/core/constants.gd`

Continuous spectrum from -20 (deep sleep) to +20 (maximum alertness):

| Constant | Value | Meaning |
|----------|-------|---------|
| ALERTNESS_MIN | -20 | Deep sleep |
| ALERTNESS_UNWARY | -10 | Below this = sleeping |
| ALERTNESS_ALERT | 0 | Fully aware, will engage |
| ALERTNESS_QUITE_ALERT | 5 | Heightened awareness |
| ALERTNESS_VERY_ALERT | 10 | Actively hunting |
| ALERTNESS_MAX | 20 | Maximum alertness |

**Combat impact**: Sleeping monsters (alertness < -10) have evasion overridden to -5.
Unwary monsters (alertness < 0) have evasion halved.

## Morale System

```
current_morale = base_morale
    - health_penalty (up to -30 at 20% HP)
    + escort_count * ESCORT_MULTIPLIER (4x per nearby ally)
    + rally_bonus (temporary)
    + territorial_bonus (+30 near home, if TERRITORIAL flag)
    + light_sensitivity_mod (-20 morale in lit tiles)
```

**Stance derived from morale**:
- morale > 200 = AGGRESSIVE
- morale > 0 = CONFIDENT
- morale <= 0 = FLEEING

**Override**: Unique and brave monsters override fleeing unless below 10% HP. Mindless creatures never flee.

## XP from Monsters

```
experience_value = max(10, depth * 5 + rarity * 10)
# Unique/boss: 3x multiplier
```

XP is further modified by the difficulty XP multiplier (see Section 12).

## Hallucinatory Images

10 non-combat entities that appear during hallucination effects (Ring of Thrain curse, potions):
Gandalf, Thranduil, Galadriel, Elrond, Thorin, Beorn, Radagast, Eagle, Elk, Ent

## Monster Flags

| Flag Category | Examples |
|---------------|---------|
| Race | ORC, TROLL, UNDEAD, DRAGON, DEMON, SPIDER, WOLF, SERPENT, MAN |
| Behavior | UNIQUE, FRIENDS, ESCORT, TERRITORIAL, OPEN_DOOR, BASH_DOOR |
| Combat | RIPOSTE, FLANKING, CHARGE, KNOCK_BACK, ZONE_OF_CONTROL |
| Resistance | RES_FIRE, RES_COLD, RES_POIS, NO_SLEEP, NO_FEAR, NO_STUN, NO_CONF |
| Special | INVISIBLE, PASS_WALL, LIGHT_SENSITIVE, DARK_AURA |
| Crit | NO_CRIT (immune), RES_CRIT (halves crit bonus dice) |

## Monster Memory

**Source**: `scripts/systems/monster_memory.gd`

Progressive knowledge based on observation count:

| Tier | Observations | Info Revealed |
|------|-------------|---------------|
| UNKNOWN | 0 | "Unknown creature" |
| IDENTIFIED | 1 | Name only |
| BASIC | 3 | HP, primary attack |
| DETAILED | 5 | All attacks, resistances |
| COMPLETE | 10 | Full stats, all flags |

Lore skill bonus: `effective_observations = base + lore_skill / 2`

---

# 9. ITEMS AND EQUIPMENT

## Data Sources

- `data/object.txt`: 254 base item entries
- `data/artefact.txt`: 147 artifact entries
- `data/special.txt`: ~60 ego item modifiers

## Equipment Slots (13)

```
WEAPON, OFF_HAND, BOW, QUIVER, HEAD, BODY, CLOAK,
HANDS, FEET, RING_L, RING_R, NECK, LIGHT
```

## Item Categories

| tval | Category | Examples | Count |
|------|----------|---------|-------|
| 17 | Arrows | Arrows (+0 to +3) | 1 |
| 19 | Bows | Shortbow, Longbow, Great Bow | 3 |
| 20 | Digging | Shovel, Mattock | 2 |
| 21 | Hafted | War Hammer, Quarterstaff | 2 |
| 22 | Polearms | Spear, Glaive, Great Axe | 7 |
| 23 | Swords | Dagger, Shortsword, Longsword | 8 |
| 30 | Boots | Boots, Greaves, Mithril Greaves | 3 |
| 31 | Gloves | Gloves, Gauntlets, Mithril Gauntlets | 3 |
| 32 | Helms | Helm, Great Helm, Crown | 5 |
| 34 | Shields | Round Shield, Kite Shield | 3 |
| 35 | Cloaks | Cloak, Shadow Cloak | 4 |
| 36 | Soft Armor | Leather, Studded, Robe | 4 |
| 37 | Mail | Chain Mail, Mithril Corslet | 3 |
| 39 | Light Sources | Torch, Lantern, Lesser Jewel | Various |
| 40 | Amulets | Various | 8 |
| 45 | Rings | Various | 14 |
| 55 | Staves | Staff of Light, etc. | 17 |
| 56 | Wands | Frost, Fire, Slowing, Light, Fear, Sleep | 6 |
| 65 | Horns | Terror, Thunder, Force, Blasting, Challenge, Fairy Flute | 6 |
| 75 | Potions | 22 types | 22 |
| 80 | Food/Herbs | 18 types | 18 |

## Identification System

Items in certain categories start unidentified and use randomized "flavor" names per game:

- **Identifiable tvals**: Amulets (40), Rings (45), Scrolls (55), Potions (75), Herbs (80)
- **Always identified**: Artifacts, basic food (bread, lembas, etc.), starting equipment
- **Flavor names**: Randomized at game start (e.g., "Murky Potion," "Twisted Ring," "a Black Herb")
- **Identification methods**: Use the item, Forge Intuition trait (auto-identify on pickup), Alchemy ability, Jeweller ability
- **First-time identification XP**: 10 XP for consumables, 25 XP for rings/amulets

## Ego Items (Special Modifiers)

~60 special modifiers from `data/special.txt`:

| Category | Examples |
|----------|---------|
| Armor | of Protection, of Venom's End, of Stealth, of the Iron Hills, of Gondor |
| Shields | of Deflection, of Frost, with Many Runes |
| Weapons | of Rivendell, of Gondolin, of Dragon-bane, of Final Rest, Vampiric, Poisoned, Balanced, Defender |
| Helms | of Brilliance, of True Sight, of Clarity, of Grace |
| Cloaks | of Stealth, of Warmth, of the Traveller |
| Bows | of Black Yew, of Radiance, of the Galadhrim |
| Boots | of Softest Tread, of Speed, of Leaping |
| Gloves | of Archery, of Healing, of Swordplay |

## Item Stacking

Stackable tvals: arrows/ammo (16), light sources (39), potions (75), food/herbs (80).
Maximum stack size: 20.

## Artifacts

147 artifact entries:

| Range | Category |
|-------|----------|
| 1-19 | Special: Rings, Amulets, Light Sources, Crowns |
| 20-139 | Named unique weapons and armor |
| 175-179 | Quest items: Ring of Thrain, Key to Erebor |
| 182-198 | Smithing templates |

Each artifact can only spawn once per game (tracked by `GameManager.spawned_artifacts`).

## Quest Items

| Item | Location | Effect |
|------|----------|--------|
| Ring of Thrain (4 variants) | Thrain's corpse (depth 15+) | +2 attack, +2 evasion, RES_FIRE. Cursed: gold hallucinations |
| Key to Erebor | Thrain's corpse | +1 attack, +1 evasion. Required for Escape victory |
| Rod of Istari (3 pieces) | Depths 10, 15, 18 | Auto-assembles. Required for Banishment victory |

## Discovery XP Items

38 items across 6 tiers: Memories, Fragments, Glyphs, Shards, Relics, Records. Finding
and identifying these grants XP as a non-combat advancement path.

## Horn System

Horns use directional targeting with a cone effect:

| Horn | Sval | Noise | Effect |
|------|------|-------|--------|
| Terror | 0 | 10 | AOE fear for 10 turns |
| Thunder | 1 | 20 | 10d4 sonic damage + 2-turn stun |
| Force | 2 | 20 | Knockback 1-3 tiles |
| Blasting | 3 | 30 | Destructive blast in range 3 |
| Challenge | 4 | 20 | Aggro monsters in radius 5 for 20 turns |
| Fairy Flute | 5 | 5 | Charm-like effect, radius 3, 10 turns |

Cone parameters: radius 3, angle 90 degrees. Directional horns (svals 0-3) require
the player to choose a direction.

---

# 10. STEALTH AND DETECTION

## Stealth Mode

Toggle with the semicolon key (`;`). While active:
- +5 stealth score (STEALTH_MODE_BONUS)
- Player moves more carefully

## Stealth Score Calculation

**Source**: `scripts/entities/player.gd` `get_stealth_score()`

```
stealth_score = stealth_skill
    + 5              (if stealth_mode active)
    + 2              (if SMALL_STATURE racial flag)
    + stealth/3      (if Disguise ability)
    + fade_bonus     (temporary, from Fade ability kill)
    + 3              (if Patient Stalker trait + stealth mode + no adjacent alert enemy)
    + 5              (if Song of the Trees active)
    - effective_noise (this turn's noise, reduced by 2 for Wayfarer's Instinct)
```

## Monster Detection Roll

**Source**: `scripts/entities/monster.gd` `_update_alertness()`

Uses opposed **d10** rolls (not d20), following the canonical SIL-Q stealth formula:

### With Line of Sight

```
monster_perception = base_perception
    + combat_noise_bonus (player attacking: +2, being attacked: +2)
    + alertness (if already alert)
    + GameManager.get_monster_perception_bonus() (difficulty modifier)

perception_roll = d10 + monster_perception
difficulty_roll = d10 + player_stealth_score + max(0, 6 - distance)

result = perception_roll - difficulty_roll
if result > 0: alertness += result
else: alertness -= 1
```

### Without Line of Sight

```
monster_perception = base_perception
    + combat_noise_bonus
    + alertness/2 (reduced bonus without LOS)
    - distance/2 (hearing distance penalty)

perception_roll = d10 + monster_perception
difficulty_roll = d10 + player_stealth_score

result = perception_roll - difficulty_roll
if result > 0: alertness += result
else if result < 0: alertness -= 1
```

### Noise Sources

| Action | Noise Value |
|--------|-------------|
| Opening/closing doors | 5 |
| Smithing at forge | 10 |
| Digging/tunnelling | 10 |
| Bashing doors | 15 |
| Combat (attacking) | +2 perception bonus to monsters |
| Combat (being attacked) | +2 perception bonus to monsters |
| Both | +4 (stacks) |

### Distance Effect

Closer to a monster = easier to detect. The distance factor adds `max(0, 6 - distance)`
to the monster's perception roll, meaning adjacent monsters get +6 while monsters 6+
tiles away get +0.

## Stealth Abilities Summary

| Ability | Effect |
|---------|--------|
| Disguise | Halves LOS detection bonuses |
| Assassination | +Stealth to attack vs non-alert |
| Vanish | +10 stealth for making enemies unwary out of LOS |
| Fade | 2 turns invisibility after killing unaware enemy |
| Throat Slit | Instant silent kill on sleeping/unaware humanoids |
| Silent Kill | Extends Throat Slit to all enemy types |
| Lore of Silence | Reduce monster perception in radius |
| Song of the Trees | +5 stealth while singing (sustained) |

---

# 11. SPECIAL SYSTEMS

## Hunger System

**Source**: `scripts/entities/player.gd`

Soft pressure mechanic that counts down per turn:

| Threshold | Value | State | Effect |
|-----------|-------|-------|--------|
| HUNGER_MAX | 2000 | Well-fed | No effects |
| HUNGER_NORMAL | 1500 | Normal | No effects |
| HUNGER_HUNGRY | 800 | Hungry | Stat penalties begin |
| HUNGER_FAMISHED | 400 | Famished | Bigger penalties, no regen |
| HUNGER_STARVING | 100 | Starving | HP loss, death timer |

Food consumption restores hunger. Types include Dark Bread, Lembas (elven), Seed Cakes (hobbit), and various herbs.

## Light System

**Source**: `scripts/entities/player.gd` `get_light_radius()`

- Base light radius: 1 (see adjacent tiles without any source)
- Light sources by type: Wooden Torch (+2), Lantern (+3), Feanorian Lamp (+4)
- Light of the Eldar trait: +1 radius
- Light-sensitive monsters: suffer attack/evasion penalties in lit tiles, -20 morale
- Dark Aura monsters: suppress player light when adjacent
- Blind status: light radius forced to 1
- Fuel system: torches have limited fuel (5000 units), deplete per turn

### FOV by Layer

FOV radius decreases with depth, from 8 (Outer Pits) to 5 (Throne Room), creating
increasing claustrophobia.

## Rest System

- **Z key**: Rest until full HP/voice
- **Shift+Z**: Rest for 20 turns
- Rest is interrupted by: monster spotted, damage taken, any key press
- Ironman difficulty: no rest healing

## Smithing System

**Source**: `scripts/systems/smithing_system.gd`

3 recipe types at forges:

| Recipe | Effect | Requirement |
|--------|--------|-------------|
| Weapon Enhancement | +1 damage die | Smithing material |
| Armor Enhancement | +1 protection die | Smithing material |
| Reforge | Random item at depth+2 | Smithing >= 10 |

**Success chance**: `smithing_skill * 5` (max 100%). Materials identified by name
substring: "mithril", "fragment", "ore", "metal", "salvage", "shard", "remnant".

**Forge types**: Orc Forge (5 uses, layers 2+), Shadow Forge (5 uses, layers 3+),
Angdur Forge (3 uses, unique). Forges appear every 2 floors to depth 10; smithing
materials spawn within 3 tiles of each forge (1-3 items).

## Quest System

**Source**: `scripts/systems/quest_system.gd`

### Escape Path

1. Find Thrain II (depth >= 15)
2. Dialogue tree: receive Ring of Thrain (node 2) and Key to Erebor (node 3)
3. Ascend to depth 1 with both items
4. Pursuit mode triggers on taking ring

### Banishment Path

1. Collect 3 Rod of Istari pieces (depths 10, 15, 18)
2. Rod auto-assembles when all 3 collected
3. Reach Throne Room (depth 19-20)
4. Requirements: Lore >= 12, Will >= 10
5. Banishment check: `d20 + will + lore/2` vs difficulty 25
6. Failure: half max HP damage
7. No pursuit phase on success

**Score multipliers**: Banishment = 3.5x, Escape = 2.0x

## Thrain II NPC

**Source**: `scripts/entities/thrain_npc.gd`

6-node dialogue tree at depth 15+:

| Node | Content |
|------|---------|
| 0 | Introduction -- broken dwarf-king |
| 1 | Story -- his imprisonment |
| 2 | Gives Ring of Thrain (+2 attack, +2 evasion, RES_FIRE) |
| 3 | Gives Key to Erebor (+1 attack, +1 evasion) |
| 4 | Final words |
| 5 | Farewell |

## Auto-Explore

**Source**: `scripts/systems/auto_explore.gd`

BFS pathfinding to nearest unexplored tile. Stop conditions: monster spotted, item
found, damage taken, stairs/forge reached, any key press, no unexplored tiles.

## Save System

- JSON serialization to `user://saves/slot_N.sav`
- Permadeath enforced: save deleted on death
- Full state: player, level terrain, entities, game state

## Score Calculation

```
score = max(0, 100000 - turns)
    + max_depth * DEPTH_MULTIPLIER * race_challenge_factor
    + escape_bonus * challenge
    + victory_bonus * challenge
```

Race challenge factors: Noldor 3, Sindar 4, Man 4, Dwarf 5.

## Epitaph System

Priority-based selection from `data/epitaphs.txt` (~90 epitaphs):

1. Killed by Sauron (5)
2. Killed by Nazgul (5)
3. Stole the Ring (5)
4. Found Thrain (5)
5. Saw Sauron (5)
6. Long/short run (5 each)
7. Deep/shallow death (5 each)
8. High stealth/kills/pacifist (5 each)
9. Generic by tone (8-10 each)

## Procedural Descriptions

500+ procedural description templates with state-aware variations, providing rich
environmental storytelling throughout the dungeon.

## Environmental Storytelling

The dungeon generator scatters flavor messages on tiles, providing narrative context
about the dungeon's history, inhabitants, and horrors. These intensify with depth.

---

# 12. DIFFICULTY MODES

**Source**: `scripts/core/game_manager.gd`

4 selectable difficulty modes chosen during character creation:

## Modifier Table

| Modifier | Easy | Normal | Hard | Ironman |
|----------|------|--------|------|---------|
| XP Multiplier | 1.5x | 1.0x | 1.0x | 1.0x |
| Monster Damage | 0.75x | 1.0x | 1.0x | 1.0x |
| Item Spawns | 1.25x | 1.0x | 0.80x | 0.80x |
| Monster Perception | +0 | +0 | +3 | +3 |
| Reveal Traps | Yes | No | No | No |
| Rest Healing | Yes | Yes | Yes | **No** |

### Easy

*"A gentler descent. More experience, weaker foes, and revealed traps."*

- 50% more XP from all sources
- Monsters deal 25% less damage
- 25% more items spawn
- All traps are visible

### Normal

*"The standard challenge of Dol Guldur."*

Standard balance. No modifiers applied.

### Hard

*"Fewer supplies, sharper-eyed foes. True Sil-Q difficulty."*

- 20% fewer item spawns
- Monsters get +3 perception (harder to sneak past)
- No pity spawns

### Ironman

*"Hard mode. No rest healing. Every wound matters."*

- All Hard mode modifiers
- **No rest healing**: the Z key rest mechanic does not recover HP
- Every point of damage must be healed through consumables

---

# 13. VICTORY CONDITIONS

## Escape Victory (Standard)

1. Descend to depth 15+
2. Find Thrain's Prison Pit
3. Receive Ring of Thrain and Key to Erebor from his dialogue
4. Pursuit mode activates: Sauron awakens, all monsters alerted
5. Ascend back to depth 1 alive

**Score multiplier**: 2.0x

## Banishment Victory (Hard)

1. Find 3 pieces of the Rod of Istari (depths 10, 15, 18)
2. Rod auto-assembles when all 3 collected
3. Requirements: Lore >= 12 AND Will >= 10
4. Reach Sauron's Throne Room (depth 19-20)
5. Banishment check: `d20 + will + lore/2` vs difficulty 25
6. Success: Sauron banished, no pursuit phase, game ends in victory
7. Failure: half max HP damage, Rod destroyed, must escape normally

**Score multiplier**: 3.5x

## Defeat Conditions

- HP reduced to 0 (unless Undying Resolve or Defy Death triggers)
- Starvation (extended time at 0 hunger)

---

# 14. BALANCE AND TUNING

## Current State (Session S, 2026-02-08)

**Known balance issues** (from MEMORY.md):

1. **Smithing is oversimplified**: Only attack/evasion bonuses. Missing: damage dice,
   parry, weight, protection dice. Most broken feature requiring a full workstream.

2. **Game projected too easy**: 40-75% win rates on Normal (roguelike target: 1-5%).
   Need 100 survival bot runs for empirical data before adjusting.

3. **Word of Command overpowered**: AOE fear+stun at Lore 8+, with 23 uses per rest
   from a 71-voice pool. Trivializes floors.

4. **Song effects arbitrary**: Song of Freedom (+3 evasion) and Song of the Trees (+5
   stealth) need mechanical grounding. Song of Aule is balanced.

5. **Victory screen not instantiated**: Exists in code but not wired into main.gd.
   30-minute fix.

6. **No HTML5 export**: Needs export_presets.cfg configuration in Godot editor.

## Empirical Data: 120 Bot Playthroughs

Six archetype builds were tested with 20 runs each (120 total) using an automated survival bot
that employs basic combat + heal + explore only. The bot does NOT use stealth, songs, forging,
archery, or voice abilities.

### Per-Archetype Results (Normal Difficulty)

| Archetype | Race | Build Focus | Avg Depth | Max Depth | Avg Turns | Avg Kills |
|-----------|------|-------------|-----------|-----------|-----------|-----------|
| TANK | Dwarf | CON 7, MEL | 2.2 | 3 | 304 | 4.2 |
| SMITH | Dwarf | CON 7, SMT | 1.9 | 5 | 316 | 4.6 |
| RANGER | Man | Balanced, PER | 1.8 | 6 | 173 | 3.6 |
| WARRIOR | Man | STR/CON, MEL | 1.6 | 3 | 220 | 5.0 |
| LORE_MAGE | Elf | GRA 7, LOR | 1.3 | 2 | 106 | 1.6 |
| STEALTH | Hobbit | DEX 6, STL | 1.2 | 3 | 44 | 0.7 |

**Overall win rate: 0.0%** (120 deaths, 0 wins)

### Key Findings

1. **CON is king for bot survival** -- Dwarf builds (CON 7) survive 60-80% longer than others
2. **Stealth builds are unplayable without stealth AI** -- Hobbit dies in ~44 turns (2.2x faster than average)
3. **Grace-heavy builds suffer without voice use** -- Lore Mage's GRA 7 provides zero benefit to the bot
4. **Floor 1-3 is the kill zone** -- 95% of deaths occur before floor 4
5. **RANGER is the dark horse** -- one run reached floor 6, highest individual depth despite middling average
6. **Item pickup rate near zero** -- bot collects 0.1-0.6 items per run, suggesting item distribution or pickup AI needs work

### Implications

- The game's difficulty is NOT "too easy" at baseline -- pure combat survivability is near zero
- Stealth, songs, and voice abilities are load-bearing mechanics -- a human player using these systems should have dramatically higher survival
- The previous 40-75% projected win rate assumed optimal human play; actual baseline is ~0%
- Balance tuning should focus on making floor 1-3 survivable through skill use, not by reducing difficulty

See [docs/BALANCE_REPORT.md](BALANCE_REPORT.md) for full attrition curves and death floor distributions.

## Key Formulas Quick Reference

| Formula | Expression |
|---------|-----------|
| Hit resolution | `(d20 + att) - (d20 + evn) >= 0` |
| Skill check | `(d10 + skill) - (d10 + difficulty) > 0` |
| Crit bonus dice | `(hit_result * 10 + 4) / (70 + weapon_weight)` |
| Damage | `roll_dice(dd) + STR_bonus + crit_dice_rolls` |
| Protection | `SUM(roll_dice(pd, ps)) per armor piece` |
| Net damage | `max(damage - protection, 0)` |
| Max HP | `24 * 1.2^CON` |
| Max Voice | `20 * 1.2^GRA` |
| Voice Regen | `max_voice / 150 per turn` |
| Skill cost | `100 * (level + 1)` XP |
| Ability cost | `(level_req + 1) * 300` XP |
| Smithing success | `skill * 5` percent |
| Stealth check | `(stealth + d10) vs (perception + d10)` |
| Monster XP | `max(10, depth*5 + rarity*10)`, 3x for UNIQUE |
| Trap avoidance | `50% + Perception * 5%` |
| Trap damage | `d4 + depth/3` |
| Banishment check | `d20 + will + lore/2` vs 25 |

---

# APPENDIX A: FILE REFERENCE

## Core Scripts

| File | Purpose |
|------|---------|
| `scripts/core/constants.gd` | Enums, flags, formulas, constants |
| `scripts/core/game_manager.gd` | Game state, difficulty, identification |
| `scripts/main.gd` | Scene management, input handling, turn flow |
| `scripts/entities/entity.gd` | Base entity: combat, damage, protection |
| `scripts/entities/player.gd` | Player: stats, skills, traits, stealth, hunger |
| `scripts/entities/monster.gd` | Monster AI, alertness, morale, pathfinding |
| `scripts/systems/dungeon_generator.gd` | Procedural level generation |
| `scripts/systems/ability_system.gd` | Lore abilities, sustained songs, voice |
| `scripts/systems/layer_config.gd` | Layer definitions, FOV, spawn tables |
| `scripts/systems/quest_system.gd` | Victory conditions, Rod assembly |

## Data Files

| File | Entries | Purpose |
|------|---------|---------|
| `data/monster.txt` | 77 | Monster definitions |
| `data/object.txt` | 254 | Item definitions |
| `data/artefact.txt` | 147 | Artifact definitions |
| `data/ability.txt` | 93 | Ability definitions |
| `data/vault.txt` | 96 | Vault templates |
| `data/race.txt` | 5 | Race definitions (4 playable + Istari) |
| `data/house.txt` | 12 | House definitions (9 base + 3 hobbit) |
| `data/trait.txt` | 20 | Hero trait definitions |
| `data/special.txt` | ~60 | Ego item modifiers |
| `data/terrain.txt` | 87 | Terrain type definitions |
| `data/epitaphs.txt` | ~90 | Death epitaphs |

---

# APPENDIX B: RENDERING AND TECHNICAL

## Engine

- Godot 4.6 (Forward Plus renderer)
- Target resolution: 1920x1080
- Content scale mode: Canvas Items, Aspect Keep
- Pixel art: nearest-neighbor filtering

## Tileset

- DCSS (Dungeon Crawl Stone Soup) tileset
- 2048x2048 PNG atlas, 32x32 tiles scaled to 64x64
- 294 tiles mapped via TileMapper
- Magenta transparency shader
- Layer tint shader for depth theming

## Render Layers

1. Terrain (TileMapLayer)
2. Items (Node2D)
3. Entities (Node2D)
4. Effects (Node2D)
5. UI (CanvasLayer)

## Autoload Singletons

1. LayerConfig -- layer tier configuration
2. GameManager -- central game state
3. EventBus -- signal-based event system (30+ signals)
4. DataManager -- all data file parsing
5. TileMapper -- DCSS tileset coordinate lookup

---

*Document Version 2.0 -- Godot Build*
*Generated from codebase analysis, 2026-02-08*
