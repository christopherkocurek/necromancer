# THE NECROMANCER
## Game Design Document v1.0

A fork of SIL-Q set in Third Age Middle-earth

---

# TABLE OF CONTENTS

1. [Overview](#1-overview)
2. [Setting & Story](#2-setting--story)
3. [Victory Conditions](#3-victory-conditions)
4. [Races & Houses](#4-races--houses)
5. [Skills & Abilities](#5-skills--abilities)
6. [Monsters](#6-monsters)
7. [Items & Artifacts](#7-items--artifacts)
8. [Dungeon Structure](#8-dungeon-structure)
9. [Special Mechanics](#9-special-mechanics)
10. [NPCs & Prisoners](#10-npcs--prisoners)
11. [Implementation Priority](#11-implementation-priority)

---

# 1. OVERVIEW

## Concept
The Necromancer is a roguelike game forked from SIL-Q. The player infiltrates Dol Guldur, Sauron's fortress in southern Mirkwood, to recover the Ring of Thráin and Key to Erebor from the dying dwarf-king imprisoned in the dungeons.

## Core Design Pillars
- **Tolkien Authenticity**: Third Age lore-accurate setting, races, and magic
- **SIL-Q Mechanics**: Keep core combat, stealth, stats, and skill systems
- **Tension**: Escape-focused endgame with pursuit mechanics
- **Meaningful Choice**: Race/house selection, item curses, prisoner dilemmas

## Key Differences from SIL-Q
| SIL-Q | The Necromancer |
|-------|-----------------|
| First Age | Third Age |
| Angband (Morgoth's fortress) | Dol Guldur (Sauron's fortress) |
| Retrieve Silmaril from Morgoth | Retrieve Ring + Key from Thráin |
| Song magic system | Lore magic system |
| Noldor/Sindar/Naugrim/Edain | Elf/Man/Dwarf with Third Age houses |
| Descend and escape | Descend, find Thráin, escape (or banish Sauron) |

---

# 2. SETTING & STORY

## Timeline
Third Age 2850. Sauron (disguised as "The Necromancer") occupies Dol Guldur. Thráin II, King of Durin's Folk, was captured five years prior and is imprisoned in the deepest dungeons, dying and broken.

## Location
Dol Guldur ("Hill of Dark Sorcery") in southern Mirkwood. A fortress built on Amon Lanc, former capital of the Silvan Elves before Sauron's shadow fell.

## The Quest
The player is sent to infiltrate Dol Guldur and recover:
- **The Ring of Thráin**: Last of the Seven Dwarf-rings
- **The Key to Erebor**: Opens the secret door to the Lonely Mountain

This mirrors Gandalf's historical quest in Tolkien's legendarium.

## Opening Text (Draft)
> *The shadow over Mirkwood deepens. For five years, Thráin son of Thrór has languished in the dungeons of Dol Guldur, his mind broken by the Necromancer's torments.*
>
> *You have been chosen for a desperate mission: descend into the Hill of Dark Sorcery, find the dying dwarf-king, and recover what he carries—the last of the Seven Rings and the key to Erebor.*
>
> *Few who enter Dol Guldur return. None who have seen its deepest pits have escaped to tell the tale.*
>
> *Until now.*

---

# 3. VICTORY CONDITIONS

## Escape Victory (Standard)
1. Descend to depth 1000ft
2. Find Thráin's Prison Pit
3. Take the Ring of Thráin and Key to Erebor from his corpse/body
4. Escape to the surface (depth 0) while Sauron pursues

## Banishment Victory (Hard)
1. Find both pieces of the Broken Staff (depths ~400ft and ~700ft)
2. Assemble the Rod of the Istari at a forge
3. Achieve Lore 12+ and Will 10+
4. Confront Sauron and use Banishment action
5. Win contested Will check to banish Sauron
6. (Failure = Rod destroyed, massive damage, must escape normally)

## Defeat Conditions
- HP reduced to 0
- Certain instant-death effects (rare)
- Trapped by Sauron with no escape

---

# 4. RACES & HOUSES

## Design Philosophy
- Stat totals range from +3 (hard mode) to +5 (easier)
- Each race has distinct flavor and mechanical identity
- Houses provide specialization within race
- Asymmetric balance creates meaningful choice

## Races

### ELF
**Base Stats**: -1 Str / +2 Dex / +1 Con / +2 Gra (Total: +4)
**Flags**: BOW_PROFICIENCY
**Available Houses**: Lothlórien, Rivendell, Greenwood

### MAN
**Base Stats**: +1 Str / 0 Dex / +1 Con / 0 Gra (Total: +2)
**Flags**: SWORD_PROFICIENCY
**Available Houses**: Dúnedain, Rohan, Gondor

### DWARF
**Base Stats**: +1 Str / -1 Dex / +3 Con / 0 Gra (Total: +3)
**Flags**: AXE_PROFICIENCY, ARC_PENALTY
**Available Houses**: Khazad-dûm, Erebor, Iron Hills

## Houses

### Elf Houses

| House | Stats | Affinity | Total | Concept |
|-------|-------|----------|-------|---------|
| **Lothlórien** | 0/0/0/+1 | LOR_AFFINITY | +1 | Galadriel's folk, most magical |
| **Rivendell** | 0/0/0/+1 | LOR_AFFINITY | +1 | Elrond's wisdom, loremasters |
| **Greenwood** | 0/+1/0/0 | STL_AFFINITY | +1 | Thranduil's folk, woodcraft |

### Man Houses

| House | Stats | Affinity | Total | Concept |
|-------|-------|----------|-------|---------|
| **Dúnedain** | 0/+1/0/+1 | PER_AFFINITY | +2 | Rangers of the North, Númenorean blood |
| **Rohan** | +1/0/0/0 | EVN_AFFINITY | +1 | Horsemasters, mobile fighters |
| **Gondor** | 0/0/+1/0 | MEL_AFFINITY | +1 | Tower Guard, disciplined soldiers |

### Dwarf Houses

| House | Stats | Affinity | Total | Concept |
|-------|-------|----------|-------|---------|
| **Khazad-dûm** | 0/0/0/+1 | LOR_AFFINITY | +1 | Ancient knowledge, exiled loremasters |
| **Erebor** | 0/0/+1/0 | SMT_AFFINITY | +1 | Smiths of the Lonely Mountain |
| **Iron Hills** | +1/0/0/0 | MEL_AFFINITY | +1 | Dáin's warriors, fighters |

## Combined Totals (Race + House)

| Build | Total | Difficulty |
|-------|-------|------------|
| Elf of Lothlórien | +5 | Easiest |
| Elf of Rivendell | +5 | Easy |
| Elf of Greenwood | +5 | Easy |
| Dwarf of Khazad-dûm | +4 | Medium |
| Dúnedain | +4 | Medium |
| Dwarf of Erebor | +4 | Medium |
| Dwarf of Iron Hills | +4 | Medium |
| Man of Rohan | +3 | Hard |
| Man of Gondor | +3 | Hard |

---

# 5. SKILLS & ABILITIES

## Skill Trees
The Necromancer uses the same 8 skill trees as SIL-Q, with **Song renamed to Lore**.

| Skill | Code | Focus |
|-------|------|-------|
| Melee | S_MEL | Close combat |
| Archery | S_ARC | Ranged combat |
| Evasion | S_EVN | Defense, mobility |
| Stealth | S_STL | Avoiding detection |
| Perception | S_PER | Awareness, identification |
| Will | S_WIL | Mental resistance |
| Smithing | S_SMT | Crafting, item improvement |
| **Lore** | S_LOR (was S_SNG) | Knowledge-based magic, devices |

## Lore Skill (Replaces Song)

### Design Philosophy
Third Age magic is fading, learned, subtle. Characters use accumulated knowledge rather than singing power into the world. Abilities represent knowing the right word, herb, symbol, or technique.

### Lore Abilities

| ID | Name | Effect | Prereq |
|----|------|--------|--------|
| 140 | **Word of Command** | Stuns/terrifies enemies in line of sight | Lore 8 |
| 141 | **Word of Opening** | Unlocks doors, breaks magical holds | Lore 4 |
| 142 | **Word of Shutting** | Locks doors, creates temporary barrier | Lore 6 |
| 143 | **Glyph of Warding** | Place a rune that blocks/damages enemies | Lore 7 |
| 144 | **Herbcraft** | Double effectiveness from all herbs | Lore 3 |
| 145 | **Deep Memory** | Reveal nearby dungeon layout | Lore 5 |
| 146 | **Device Mastery** | Wands/staves gain +50% charges | Lore 6 |
| 147 | **Ancient Tongues** | Auto-identify items, scrolls never backfire | Lore 8 |
| 153 | **+Grace** | +1 Grace | Lore 10 |

### LOR_AFFINITY
Grants +1 to Lore skill and one free Lore ability at character creation.

---

# 6. MONSTERS

## Tier Structure
Each dungeon tier has its own monster ecosystem with commons, uncommons, rares, and bosses.

---

## TIER 1: The Outer Pits (Depths 50-250ft)
*Spider nests, orc warrens, forest roots breaking through*

### Common
| Monster | Mechanic |
|---------|----------|
| Mirkwood Spider | **Venomous Bite** - poison DoT |
| Orc Slave | **Cowardly** - flees when wounded, alerts others |
| Orc Scout | **Alert** - wakes nearby sleeping enemies |
| Giant Rat | **Disease** - small chance of sickness debuff |
| Bat | **Erratic** - hard to hit, low damage |
| Black Squirrel | **Thief** - steals food, flees |
| Crebain | **Spy** - if escapes, increases floor alertness |

### Uncommon
| Monster | Mechanic |
|---------|----------|
| Orc Warrior | Standard enemy |
| Orc Archer | **Ranged** - attacks from distance, weak in melee |
| Warg Pup | **Pack Tactics** - +1 attack per adjacent Warg |
| Large Spider | **Web Shot** - can slow player from range |
| Giant Bat | **Screech** - wakes nearby enemies |
| Swamp Adder | **Ambush** - hidden until adjacent, venomous |

### Rare
| Monster | Mechanic |
|---------|----------|
| Orc Captain | **Commander** - nearby orcs get +2 to attacks |
| Great Spider | **Web Trap** - creates webs, venomous, tough |
| Warg | **Pack Tactics** - +1 attack per adjacent Warg |
| Half-orc | **Cunning** - opens doors, uses items |

### Bosses
| Monster | Mechanic |
|---------|----------|
| **Orc Warchief** | **Rally** - summons orc reinforcements; **Armored** |
| **Broodmother Spider** | **Spawn** - creates Mirkwood Spiders; **Heavy Poison**; stationary, destroy egg sacs to weaken |

---

## TIER 2: The Dark Halls (Depths 250-500ft)
*Torture chambers, troll dens, sorcerer workshops, crypts*

### Common
| Monster | Mechanic |
|---------|----------|
| Orc Warrior | Standard enemy |
| Orc Archer | **Ranged** |
| Warg | **Pack Tactics** |
| Skeleton | **Brittle** - extra damage from blunt weapons |
| Zombie | **Slow, Relentless** - always moves toward player, high HP |
| Hill Troll | **Sunlight Weakness** - weaker near light sources |
| Cave Spider | **Ceiling Ambush** - drops from above, first strike |

### Uncommon
| Monster | Mechanic |
|---------|----------|
| Orc Captain | **Commander** |
| Mirk-Troll | **Sun Resistant** - no sunlight weakness, poisoned weapon |
| Skeleton Warrior | **Shield Block** - higher evasion from front |
| Ghoul | **Paralyzing Touch** - failed Will save = lose next turn |
| Easterling Soldier | **Disciplined** - doesn't flee, fights in formation |
| Dark Acolyte | **Dark Prayer** - heals nearby undead |

### Rare
| Monster | Mechanic |
|---------|----------|
| Wight | **Life Drain** - damage reduces max HP until rest |
| Half-troll | **Regeneration** - heals slowly over time |
| Easterling Champion | **Duelist** - bonus damage in 1v1 combat |
| Dark Sorcerer | **Spellcaster** - casts darkness, fear, minor curses |
| Corpse-candle | **Lure** - player must save Will or move toward it |

### Bosses
| Monster | Mechanic |
|---------|----------|
| **Troll Chieftain** | **Frenzy** - attacks faster when wounded; **Boulder Throw** - must use pillars for cover |
| **Master Torturer** | **Crippling Strikes** - attacks reduce Dex temporarily; fight becomes harder as it continues |

---

## TIER 3: The Necropolis (Depths 500-750ft)
*Ritual chambers, wraith domains, necromancer sanctums*

### Common
| Monster | Mechanic |
|---------|----------|
| Mirk-Troll | **Sun Resistant** |
| Skeleton Warrior | **Shield Block** |
| Wight | **Life Drain** |
| Easterling Warrior | **Disciplined** |
| Ghast | **Stench** - adjacent player gets -2 to attacks |

### Uncommon
| Monster | Mechanic |
|---------|----------|
| Olog-hai | **Crushing Blow** - can destroy shields/armor |
| Barrow-wight | **Curse** - casts curses, drains stats |
| Necromancer Adept | **Raise Dead** - reanimates nearby corpses as skeletons |
| Vampire Thrall | **Blood Frenzy** - faster when player is wounded |
| Black Númenórean | **Dark Lore** - resists Lore abilities, casts spells |

### Rare
| Monster | Mechanic |
|---------|----------|
| Werewolf | **Shapeshifter** - appears human until close; fast, brutal |
| Vampire | **Life Steal** - heals when hitting player |
| Phantom | **Incorporeal** - 50% chance physical attacks pass through |
| Shadow | **Strength Drain** - damage reduces Str temporarily |
| Crypt Lord | **Raise Dead** - summons skeletons, commands undead; kill corpses/burn them |

### Boss
| Monster | Mechanic |
|---------|----------|
| **Lesser Nazgûl** | **Black Breath** - aura of fear, failed Will = flee; **Morgul-blade** - can cause permanent Morgul-wound; **Immune** to normal weapons |

---

## TIER 4: The Inner Sanctum & Pits of Despair (Depths 750-1000ft)
*Black Númenórean quarters, Nazgûl halls, Thráin's prison, Sauron's throne*

### Common
| Monster | Mechanic |
|---------|----------|
| Olog-hai | **Crushing Blow** |
| Phantom | **Incorporeal** |
| Barrow-wight | **Curse** |
| Black Númenórean | **Dark Lore** |

### Uncommon
| Monster | Mechanic |
|---------|----------|
| Vampire Lord | **Mist Form** - can become invulnerable briefly, repositions |
| Greater Werewolf | **Alpha** - commands lesser werewolves, regenerates |
| Wraith | **Fear Aura** - must pass Will check to approach |
| Fell Spirit | **Possession** - can take over corpses mid-fight |

### Rare
| Monster | Mechanic |
|---------|----------|
| Shadow Lord | **Darkness** - extinguishes light sources nearby |
| Úlairi | **Lesser Black Breath** - fear aura, phasing, weapon immunity |
| Maia Thrall | **Corrupted Power** - random powerful spell effects |

### Bosses
| Monster | Location | Mechanic |
|---------|----------|----------|
| **Khamûl the Easterling** | Depth ~900ft | **Shadow of the East** - fear aura, sorcery, Morgul-blade, summons wraiths; **Phase Shift** - visible/invisible, must track; immune to normal weapons |
| **Sauron the Necromancer** | Depth 1000ft | See Special Mechanics section |

---

## SAURON - THE FINAL BOSS

### Core Mechanics
| Mechanic | Effect |
|----------|--------|
| **Unkillable** | Cannot be reduced below 1 HP through normal means |
| **Lidless Eye** | Always knows player location on floor |
| **Dominating Will** | Constant Will checks or be slowed/frightened |
| **Dark Sorcery** | Casts powerful spells: darkness, fire, paralysis |
| **The Shadow** | Room is supernaturally dark, reduced vision |
| **Pursuit** | If player grabs Ring+Key, Sauron pursues through entire dungeon |

### Banishment (Only way to "defeat")
- Requires: Rod of the Istari (assembled) + Lore 12+ + Will 10+
- Use Banishment action (costs full turn)
- Contested Will check vs Sauron
- Success: Sauron banished, player wins, can loot freely
- Failure: Rod destroyed, massive damage, must escape normally

---

# 7. ITEMS & ARTIFACTS

## Staves
Two-handed weapons that cast effects. Limited charges, rechargeable by combining two of same type (higher Lore = more charges recovered).

| Staff | Damage | Charges | Effect | Lore Req |
|-------|--------|---------|--------|----------|
| Staff of Light | 1d5 | 8 | Illuminates area, damages undead | 2 |
| Staff of Striking | 2d6 | 6 | Melee attack with bonus knockback | 3 |
| Staff of Opening | 1d4 | 10 | Unlocks doors, breaks holds | 4 |
| Staff of Warding | 1d4 | 5 | Creates temporary glyph (blocks enemies 3 turns) | 6 |
| Staff of Slumber | 1d4 | 6 | Puts single enemy to sleep | 5 |
| Staff of Revelation | 1d4 | 4 | Reveals traps/secret doors in radius | 7 |
| Staff of Sanctity | 1d5 | 4 | Damages and repels undead in radius | 8 |
| Staff of Command | 1d4 | 3 | Stuns/terrifies enemies in cone | 10 |

## Wands
One-handed, ranged effects. Rechargeable by combining.

| Wand | Charges | Effect | Lore Req |
|------|---------|--------|----------|
| Wand of Light | 12 | Light bolt, minor damage to undead | 1 |
| Wand of Frost | 8 | Cold bolt, slows target | 3 |
| Wand of Fire | 6 | Fire bolt, higher damage | 4 |
| Wand of Fear | 5 | Target must pass Will or flee | 5 |
| Wand of Sleep | 6 | Target falls asleep | 4 |
| Wand of Slow | 8 | Target slowed for 10 turns | 3 |
| Wand of Binding | 4 | Target paralyzed for 3 turns | 8 |
| Wand of Dispel | 3 | Removes magical effects, damages summoned | 10 |
| Wand of Death | 2 | Massive damage, Will save or instant kill (not bosses) | 12 |

## Herbs
Consumables. Herbcraft ability doubles effectiveness.

| Herb | Base Effect | With Herbcraft |
|------|-------------|----------------|
| Athelas (Kingsfoil) | Heal 20 HP, cure poison | Heal 40 HP, cure poison + disease |
| Lissuin | +2 Dex for 20 turns | +4 Dex for 30 turns |
| Miruvor Draught | Heal 10 HP, cure fear | Heal 20 HP, cure fear + restore Will |
| Hithlain Leaf | +2 Stealth for 30 turns | +4 Stealth for 50 turns |
| Elanor | Light (radius 2) for 100 turns | Radius 3, damages undead |
| Niphredil | Cures blindness, +2 Perception | +4 Perception 40 turns |
| Alfirin | Slows poison/disease | Halts and partially reverses |
| Black Moss | Poison weapon (5 hits) | Stronger poison, 10 hits |
| Mordor Lichen | Heals 30 HP but -1 Grace permanent | No Grace penalty with Herbcraft |

**Note**: Athelas is VERY RARE. Most herbs should be common/uncommon tier.

## Scrolls
One-use. Higher Lore = better success, lower backfire chance.

| Scroll | Effect | Lore Req | Backfire |
|--------|--------|----------|----------|
| Scroll of Mapping | Reveals floor layout | 2 | Reveals you to enemies |
| Scroll of Identify | Identifies one item | 1 | Item cursed instead |
| Scroll of Teleport | Random teleport on floor | 4 | Teleport into danger |
| Scroll of Sanctuary | Enemies can't enter tile 10 turns | 6 | You can't leave tile |
| Scroll of Banishment | Destroys undead in radius | 8 | Summons undead |
| Scroll of Recall | Return to surface (escape victory) | 10 | Teleports deeper |
| Scroll of Warding | Permanent glyph on tile | 7 | Glyph hurts you |
| Scroll of Light | Lights entire floor | 3 | Blinds you |
| Scroll of Darkness | Darkens entire floor | 5 | Only you are blinded |

## Potions
Always work, no skill requirement.

| Potion | Effect |
|--------|--------|
| Healing | Restore 25 HP |
| Greater Healing | Restore 50 HP |
| Clarity | Cure confusion/fear, +2 Will 20 turns |
| Strength | +3 Str for 30 turns |
| Dexterity | +3 Dex for 30 turns |
| Grace | +3 Grace for 30 turns |
| Poison | Looks like healing; damages you |
| Weakness | Looks like Strength; -3 Str |
| True Sight | See invisible, see in darkness 50 turns |
| Resist Fire | Fire resistance 100 turns |
| Resist Cold | Cold resistance 100 turns |
| Antidote | Cures poison |
| Restoration | Restores drained stats |
| Waters of Rivendell | Cures Morgul-wound (very rare) |

---

## ARTIFACTS

### Quest Items (Required for Victory)

| Artifact | Location | Effect |
|----------|----------|--------|
| **Ring of Thráin** | Thráin's corpse (1000ft) | +3 Will, +2 Smithing; **CURSED**: Gold Hallucination (see below) |
| **Key to Erebor** | Thráin's corpse (1000ft) | No combat stats; required for victory |
| **Broken Staff (Upper)** | Tier 2 vault (~400ft) | +2 Lore, +1 Will; usable as weapon |
| **Broken Staff (Lower)** | Tier 3 (~700ft) | +2 Lore, +1 Grace; usable as weapon |
| **Rod of the Istari** | Assembled from both pieces | +5 Lore, +3 Will; Banishment ability |

### Major Artifacts

| Artifact | Type | Stats | Special |
|----------|------|-------|---------|
| **Aiglos** | Spear | +3 attack, 2d9 | Frost brand - extra cold damage, freezes |
| **Narsil Shard** | Dagger | +2 attack, 1d7 | Bane of Sauron - massive bonus vs Sauron/Nazgûl |
| **Mithril Corslet** | Armor | [+0, 4d4], no weight | Featherlight - no evasion penalty |
| **Bow of Lórien** | Bow | +3 attack, 2d6 | Unerring - reduced penalty at range |
| **Galadriel's Phial** | Light | Radius 5 | Star-light - damages undead/shadows, blinds evil |
| **Vilya's Shard** | Ring | +2 all stats | Single-use Cure - cures Morgul-wound, then crumbles |

### Minor Artifacts

| Artifact | Type | Effect |
|----------|------|--------|
| **Ranger's Cloak** | Cloak | +3 Stealth; Blend - harder to detect when still |
| **Dwarf-lantern** | Light | Radius 3; Eternal Flame - never runs out |
| **Athelas Pouch** | Misc | 3 uses, strong heal + cure poison |
| **Waters of Rivendell** | Potion | Cures Morgul-wound (single use) |
| **Elrond's Tome** | Book | +2 Lore; Ancient Knowledge - identify any item |
| **Black Arrow** | Ammo | Slayer - massive damage to single target, one use |

### Cursed Artifacts

| Artifact | Type | Stats | Curse |
|----------|------|-------|-------|
| **Morgul-blade** | Dagger | +4 attack, 1d8 | Wielder takes slow damage, can't unequip without Curse Breaking |
| **Ring of Thráin** | Ring | +3 Will, +2 Smithing | Gold Hallucination - see fake gold everywhere, compelled toward it |
| **Necromancer's Circlet** | Helm | +5 Lore, +3 Will | Corrupting - drains Grace over time, Sauron can sense you |

---

# 8. DUNGEON STRUCTURE

## Overview

| Depth | Tier | Name | Theme |
|-------|------|------|-------|
| 50-250ft | 1 | The Outer Pits | Spider nests, orc warrens, forest roots |
| 250-500ft | 2 | The Dark Halls | Torture chambers, troll dens, sorcerer workshops |
| 500-750ft | 3 | The Necropolis | Crypts, ritual chambers, wraith domains |
| 750-950ft | 4a | The Inner Sanctum | Black Númenórean quarters, Nazgûl halls |
| 950-1000ft | 4b | The Pits of Despair | Thráin's prison, Sauron's throne room |

## Transition Zones
At tier boundaries (200-250ft, 450-500ft, 700-750ft), use mixed enemy types from both tiers. Include environmental warnings (graffiti, corpses, darker lighting).

## Terrain Features by Tier

### Tier 1 - The Outer Pits
| Feature | Effect |
|---------|--------|
| Spider Webs | Slows movement, chance to trap |
| Fallen Trees | Blocks LoS, can be climbed |
| Poisoned Streams | Damage over time if crossed |
| Orc Barricades | Destructible walls |
| Nest Chambers | Spawns spiders if disturbed |
| Root Tunnels | Narrow passages, stealth bonus |

### Tier 2 - The Dark Halls
| Feature | Effect |
|---------|--------|
| Torture Racks | Flavor, sometimes loot |
| Forges | Can repair/combine items, assemble Rod |
| Troll Caves | Open areas, boulders for cover |
| Alchemist Tables | Random potion, chance of trap |
| Locked Cells | May contain prisoners, loot, or enemies |
| Pit Traps | Fall to lower level |

### Tier 3 - The Necropolis
| Feature | Effect |
|---------|--------|
| Sarcophagi | May contain loot or spawn wight |
| Ritual Circles | Disturbing spawns undead |
| Cursed Glyphs | Step on = random curse |
| Bone Piles | Necromancers can raise these |
| Black Altars | Sacrifice items for boons (risky) |
| Crypts | Vault rooms with undead guardians |

### Tier 4 - The Inner Sanctum
| Feature | Effect |
|---------|--------|
| Enchanted Darkness | Permanent low light |
| The Shadow | Passive Will drain |
| Morgul Braziers | Green flame, fear aura nearby |
| Throne Room | Sauron's chamber, final encounter |
| Prison Pit | Thráin's location |
| Escape Routes | Hidden stairs back up (reward exploration) |

## Vault Designs (Pre-built Rooms)

| Vault | Tier | Description |
|-------|------|-------------|
| Broodmother's Lair | 1 | Central spider boss, webs, egg sacs |
| Orc Barracks | 1 | Many orcs, armory loot |
| Warg Kennels | 1-2 | Wargs + handlers, open space |
| Torturer's Workshop | 2 | Master Torturer boss, cells, loot |
| Troll King's Cave | 2 | Boulder cover, hoard |
| Sorcerer's Study | 2 | Dark Sorcerer, scrolls, wands |
| Hall of the Dead | 3 | Rows of sarcophagi, Crypt Lord |
| Ritual Chamber | 3 | Necromancer Adept, sacrifice altar |
| Nazgûl's Quarters | 3 | Lesser Nazgûl boss, Morgul weapons |
| Black Númenórean Temple | 4 | Evil priests, dark artifacts |
| Khamûl's Throne | 4 | Second-in-command boss fight |
| The Prison Pit | 4 | Thráin's cell, Ring + Key |
| Sauron's Throne Room | 4 | Final area |

---

# 9. SPECIAL MECHANICS

## Alertness System
| Trigger | Effect |
|---------|--------|
| Combat | +1-3 Alertness depending on noise |
| Crebain escapes | +5 Alertness |
| Alarm triggered | +10 Alertness |
| Time passing | Slow decay |

| Alertness Level | Consequence |
|-----------------|-------------|
| 0-10 | Normal patrols |
| 11-25 | Increased patrols, some locked doors |
| 26-50 | Ambushes possible, reinforcements arrive |
| 50+ | Full alert, boss enemies may roam |

## The Lidless Eye (Tier 4 only)
- Sauron is aware of intruders
- Random Will checks every ~20 turns
- Failure: Sauron locates you, sends enemies to your position
- High Will and Stealth reduce frequency

## Morgul-Wound
| Aspect | Detail |
|--------|--------|
| **Caused by** | Nazgûl Morgul-blade hit (chance, not guaranteed) |
| **Effect** | Permanent -2 to all stats; vision slowly reduces over time |
| **Cures** | Waters of Rivendell (consumable), Vilya's Shard (artifact), Lore 14+ with Herbcraft + any healing herb |

## Ring of Thráin - Gold Hallucination
When carrying the Ring:
- +3 Will, +2 Smithing (benefits)
- Player sees fake gold piles scattered everywhere
- Must pass Will check or be compelled to move toward fake gold
- Fake gold disappears when reached, wastes turns
- Higher Will = less frequent hallucinations

## Pursuit Mode (After taking Ring + Key)
| Phase | Event |
|-------|-------|
| Sauron Awakens | Appears in throne room, begins pursuit |
| Dungeon Shifts | New enemies spawn on all floors |
| Locked Exits | Some stairs locked, need Word of Opening or alternate routes |
| The Chase | Sauron moves toward player each turn (slower but relentless) |
| Collapse | Some areas collapse, force alternate routes |
| Shortcuts Open | Previously locked passages become available |
| Surface = Victory | Reach depth 0 with Ring + Key |

## Exhaustion (Pursuit Mode)
- The Ring weighs on bearer
- Every 5 floors ascended: -1 to random stat temporarily
- Restored upon victory

## Environmental Hazards

| Hazard | Effect |
|--------|--------|
| Poisoned Water | 2 damage/turn while in it, -2 Dex |
| Spider Webs | Movement costs double, chance stuck |
| Pit Traps | Fall 50ft, take damage |
| Enchanted Darkness | Vision reduced to 1 tile |
| Cursed Glyphs | Random curse (stat drain, slow, fear) |
| Ritual Circles | Disturbing spawns 1d4 skeletons |
| The Shadow (Tier 4) | Constant Will drain, fear checks every 10 turns |

---

# 10. NPCs & PRISONERS

## Design Philosophy
Prisoners create moral dilemmas and provide gameplay variety. Rescuing costs time and raises alertness but provides rewards.

## Prisoner Types

| Prisoner | Location | Rescue Reward | Cost |
|----------|----------|---------------|------|
| **Captured Ranger** | Tier 2 cells | Gives map info, joins briefly as ally | +5 Alertness |
| **Elven Scout** | Tier 2-3 | Gives Lore hint (Rod location), healing herbs | +3 Alertness |
| **Dwarf Smith** | Tier 2 forge | Can repair/upgrade one item for free | +5 Alertness, must escort to forge |
| **Gondorian Soldier** | Tier 3 | Fights alongside you for 3 floors | +8 Alertness |
| **Tortured Wretch** | Tier 3-4 | Incoherent, but carries valuable item | +2 Alertness |
| **Mad Prophet** | Tier 4 | Cryptic hints about Sauron's weakness | +0 Alertness (nobody believes him) |

## Thráin II
**Location**: Prison Pit, Depth 1000ft
**State**: Mentally broken, dying, does not recognize his own name
**Interaction**: 
- Cannot be "rescued" - he dies shortly after you find him
- Babbles incoherently, begs for release
- Gives you Ring and Key (take from his body or he presses them into your hands)
- His death is scripted/inevitable - this is not a choice

## Prisoner Mechanics
- Prisoners are found in locked cells
- Opening cell costs 1 turn and may require key or Word of Opening
- Once freed, prisoner follows you until reward delivered or they reach stairs
- Prisoners can die if caught in combat
- Dead prisoners = no reward, guilt flavor text

---

# 11. IMPLEMENTATION PRIORITY

## Phase 1: Core Systems (Must Have)
1. Rename Song → Lore throughout codebase
2. Replace SNG_AFFINITY → LOR_AFFINITY
3. Implement new races (Elf, Man, Dwarf)
4. Implement new houses (9 total)
5. Update ability.txt with Lore abilities
6. Update monster.txt with Tier 1-2 monsters
7. Update terrain.txt with Dol Guldur features
8. Change win condition: Ring + Key + Escape
9. Basic pursuit mode after taking Ring

## Phase 2: Content (Should Have)
1. Full monster roster (Tiers 3-4)
2. All artifacts
3. Vault designs
4. Boss unique mechanics
5. Morgul-wound system
6. Ring of Thráin hallucination
7. All staves/wands/herbs
8. Alertness system

## Phase 3: Polish (Nice to Have)
1. NPCs and prisoners
2. Lore fragments (flavor text found in dungeon)
3. Opening/ending text
4. Exhaustion mechanic
5. Collapse mechanic during escape
6. Black Altar sacrifice system
7. Banishment victory path
8. Rod of Istari assembly

## File Modification Reference

| File | Changes |
|------|---------|
| `lib/edit/race.txt` | Replace all races with Elf/Man/Dwarf |
| `lib/edit/house.txt` | Replace all houses with Third Age houses |
| `lib/edit/ability.txt` | Replace Song abilities (140-153) with Lore |
| `lib/edit/monster.txt` | Replace all monsters with Dol Guldur roster |
| `lib/edit/object.txt` | Add wands, staves, herbs; update base items |
| `lib/edit/artefact.txt` | Replace with Third Age artifacts |
| `lib/edit/terrain.txt` | Add Dol Guldur terrain features |
| `lib/edit/vault.txt` | Replace with Dol Guldur vault designs |
| `lib/edit/history.txt` | Update character background text |
| `lib/edit/flavor.txt` | Update item descriptions |
| `src/defines.h` | Rename S_SNG → S_LOR, update constants |
| `src/types.h` | Any struct changes for new mechanics |
| `src/birth.c` | Update character creation for new races |
| `src/spells1.c` | Rename/modify Song functions → Lore |
| `src/spells2.c` | Additional Lore ability implementations |

---

# APPENDIX A: QUICK REFERENCE

## Stat Abbreviations
- Str = Strength
- Dex = Dexterity  
- Con = Constitution
- Gra = Grace

## Skill Abbreviations
- MEL = Melee
- ARC = Archery
- EVN = Evasion
- STL = Stealth
- PER = Perception
- WIL = Will
- SMT = Smithing
- LOR = Lore (was SNG/Song)

## Damage Notation
- XdY = roll X dice with Y sides
- [+X, YdZ] = +X to hit, YdZ protection

---

# APPENDIX B: LORE ACCURACY NOTES

## Timeline Placement
- T.A. 2850: Gandalf finds dying Thráin in Dol Guldur
- T.A. 2941: White Council drives Sauron from Dol Guldur (same year as Bilbo's quest)
- Our game is set at T.A. 2850, concurrent with Gandalf's visit

## What's at Dol Guldur (per Tolkien)
- Orcs, Trolls, Giant Spiders, Wargs
- Evil spirits, possibly vampires and werewolves
- Easterling servants
- The Necromancer (Sauron in disguise)
- Three Nazgûl stationed there (including Khamûl)
- Thráin II, imprisoned and tortured

## Appropriate Third Age Races
- Elves: Galadhrim (Lothlórien), Rivendell Elves, Silvan/Greenwood Elves
- Men: Dúnedain (Rangers), Rohirrim, Gondorians
- Dwarves: Erebor exiles, Iron Hills, Khazad-dûm refugees
- NOT appropriate: Hobbits (not adventuring at this time), First Age houses

## Magic in the Third Age
- Greatly diminished from First Age
- No direct "singing power into the world" like the Ainur
- More subtle: words of power, knowledge, devices
- Wizards use staves and words, not flashy spells
- Rings of Power are the main source of magical might

---

*Document Version 1.0*
*Created for The Necromancer - A SIL-Q Fork*
