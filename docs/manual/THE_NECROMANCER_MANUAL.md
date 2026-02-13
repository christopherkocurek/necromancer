# The Necromancer -- Player's Manual

**Version:** Beta 1.0.1 (Godot 4.6 Build)
**Last Updated:** February 2026

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [Races & Houses](#3-races--houses)
4. [Skills & Abilities](#4-skills--abilities)
5. [The Dungeon](#5-the-dungeon)
6. [Monsters](#6-monsters)
7. [Items & Equipment](#7-items--equipment)
8. [Stealth & Detection](#8-stealth--detection)
9. [Victory Conditions](#9-victory-conditions)
10. [Controls & Keybindings](#10-controls--keybindings)

---

## 1. Introduction

### What Is The Necromancer?

The Necromancer is a traditional roguelike set in J.R.R. Tolkien's Middle-earth during
the Third Age. You play as a hero who has entered Dol Guldur, the fortress of the
Necromancer (Sauron in disguise), to confront the growing darkness.

The game draws its mechanical foundation from SIL-Q, the acclaimed Tolkien roguelike,
adapting its skill-based progression and opposed-roll combat to a graphical tile-based
experience in the Godot engine.

### Core Philosophy

- **No character levels.** You improve by spending experience points on skills.
- **Every decision matters.** Resources are scarce. XP is currency. Resting is risky.
- **Death is permanent.** There is no save-scumming. When you die, you start over.
- **The dungeon fights back.** Monsters have morale, alertness, and tactical AI.
  They flee when wounded, hunt in packs, and call for reinforcements.
- **Multiple victory paths.** You can escape Dol Guldur with Thrain's treasures, or
  descend to the Throne Room and banish the Necromancer himself.

### Notes for SIL-Q Players

If you have played SIL-Q, much will feel familiar. Key differences:

- **Song is now Lore.** The Song skill tree has been renamed and expanded. Sustained
  songs still exist (Song of Freedom, Song of the Trees, Song of Aule) as Lore
  abilities, but the tree also includes Words of Power, direct-damage lore, and
  passive knowledge abilities.
- **Hunting replaces Perception.** Same mechanics, new name to reflect the tracker/ranger
  fantasy.
- **Hero Traits.** A new system: each character chooses one of 20 traits at creation
  that defines a passive or triggered playstyle archetype (e.g., Defiance, Last Stand,
  Shadow Step, Undying Resolve).
- **Voice charges** replace Song duration points. They regenerate slowly
  (full pool over ~150 turns) and are spent on Lore abilities.
- **Four difficulty modes** (Easy, Normal, Hard, Ironman) modify XP rates, monster
  damage, item density, and healing rules.
- **Graphical tiles.** The ASCII display is replaced by a DCSS-style tileset. All
  keybindings remain keyboard-driven in the roguelike tradition.

---

## 2. Getting Started

### Character Creation

When you start a new game, you will create your character through a multi-step process:

#### Step 1: Choose Your Name

Enter a name for your hero. This is purely cosmetic but appears in the message log,
the HUD, and on your death screen (or victory screen, if you survive).

#### Step 2: Choose Your Race

There are four playable races (plus one debug race). Each race has stat modifiers,
racial flags, unique starting equipment, and a set of compatible houses. See Section 3
for full details.

| Race   | STR | DEX | CON | GRA | Special                                  |
|--------|-----|-----|-----|-----|------------------------------------------|
| Elf    | -1  | +2  | +1  | +2  | Bow Proficiency                          |
| Man    | +1  | +0  | +1  | +0  | Sword Proficiency                        |
| Dwarf  | +1  | -1  | +3  | +0  | Axe Proficiency, Dwarven Resilience      |
| Hobbit | -2  | +2  | +0  | +2  | Small Stature, Hobbit Luck, Sling Prof.  |

**Istari** is a debug/godmode race with +10 to all stats. It exists for playtesting.

#### Step 3: Choose Your House

Each race has three compatible houses. Houses provide a small stat bonus and a skill
affinity, which reduces the XP cost for that skill's advancement.

| House           | Race   | Stat Bonus     | Skill Affinity |
|-----------------|--------|----------------|----------------|
| Of Lothlorien   | Elf    | +1 GRA         | Lore           |
| Of Rivendell    | Elf    | +1 CON         | Smithing       |
| Of Greenwood    | Elf    | +1 DEX         | Stealth        |
| Dunedain        | Man    | +1 DEX, +1 GRA | Hunting        |
| Of Rohan        | Man    | +1 STR         | Evasion        |
| Of Gondor       | Man    | +1 CON         | Melee          |
| Of Khazad-dum   | Dwarf  | +1 GRA         | Lore           |
| Of Erebor       | Dwarf  | +1 CON         | Smithing       |
| Of the Iron Hills | Dwarf | +1 STR       | Melee          |
| Of the Shire    | Hobbit | +1 CON         | Will           |
| Of the Gamgees  | Hobbit | +1 STR         | Smithing       |
| Of the Tooks    | Hobbit | +1 DEX         | Stealth        |

#### Step 4: Allocate Stats

You receive **13 stat points** to distribute among four base stats:

- **Strength (STR):** Melee damage, carrying capacity, knock-back chance.
- **Dexterity (DEX):** Evasion bonus, ranged accuracy, sprinting.
- **Constitution (CON):** Hit points (HP = 24 * 1.2^CON). Survival.
- **Grace (GRA):** Voice pool (Voice = 20 * 1.2^GRA), Lore effectiveness.

Stats use an increasing cost curve. The first few points are cheap; pushing a stat
to +5 or +6 is extremely expensive. A balanced spread is generally safer than
hyper-specialization, though specialists can be very powerful when supported by the
right trait and house.

**Cost Table:**

| Stat Value | -4 | -3 | -2 | -1 | +0 | +1 | +2 | +3 | +4 | +5 | +6 |
|------------|----|----|----|----|----|----|----|----|----|----|-----|
| Cumulative | -4 | -3 | -2 | -1 |  0 |  1 |  3 |  6 | 10 | 15 | 21 |

Each point listed is the cumulative cost to reach that value. So raising a stat from
+0 to +3 costs 6 of your 13 available points.

#### Step 5: Choose Your Trait

Select one of 20 hero traits. Your trait is permanent and cannot be changed. It defines
a key passive or triggered ability that shapes your run.

**Combat Traits:**
- **Defiance:** +1 attack and damage vs enemies from deeper floors.
- **Last Stand:** +3 attack, damage, and evasion when below 25% HP.
- **Nimble Striker:** +2 evasion after move-then-attack; free move on kill.
- **Shield Brother:** +1 melee attack while wielding a shield; adjacent enemies
  suffer -1 evasion. Blocking also halves incoming ranged damage.

**Stealth Traits:**
- **Ambush Mastery:** Extra damage die vs unaware enemies.
- **Shadow Step:** Once per floor, teleport adjacent to any visible unaware enemy.
- **Patient Stalker:** +3 stealth when stealthing with no adjacent alert enemies.
  After 3 consecutive stealth turns, your first attack deals double damage.

**Survival Traits:**
- **Undying Resolve:** Once per game, survive lethal damage at 50% HP.
- **Fortune's Favor:** Once per floor, reroll a failed saving throw.
- **Mithril Skin:** +1d2 innate protection, but evasion capped at 10. Requires CON 3+.
- **Blood of Numenor:** +1 damage vs Undead/Evil, immune to Entranced, but heal 1 less
  from food/rest. Man only.

**Utility Traits:**
- **Forge Intuition:** Items you pick up are automatically identified.
- **Wayfarer's Instinct:** Detect traps within 3, reveal doors/stairs within 8 on
  floor entry. Movement noise reduced by 2.
- **Light of the Eldar:** +1 light radius. Undead in your light suffer -2 attack/evasion.
- **Whisper of the Valar:** Once per floor, spend 3 voice charges to reveal all enemies
  within radius 6 for 5 turns. Requires GRA 2+.

**Lore Traits:**
- **Song of Banishment (trait):** Begin the game knowing Song of Banishment regardless
  of Lore skill.
- **Echoes of the Firstborn:** +2 voice charges on each floor entry. All Lore abilities
  cost 1 fewer voice charge (min 1). Base speed reduced by 1 tier.

**Aggressive Traits:**
- **Rallying Cry:** When you kill an enemy, visible enemies must save or lose 20 morale.
- **Oath of Enmity:** First enemy type killed per floor becomes your sworn foe: +2 attack,
  +1 damage die vs that type. -1 attack vs all others.
- **Steady Aim:** Standing still without attacking charges your next ranged attack:
  +3 hit, +1 critical die.

#### Step 6: Choose Difficulty

- **Easy:** +50% XP, -25% monster damage, +25% item spawns, traps revealed.
- **Normal:** The standard Dol Guldur challenge.
- **Hard:** -20% item spawns, +3 monster perception. True SIL-Q difficulty.
- **Ironman:** Hard mode rules plus no rest healing and faster hunger.

### Starting Equipment

Your starting equipment depends on your race:

- **Elf:** Wooden Torch, 2x Fragment of Lembas, Curved Sword (equipped).
- **Man:** Wooden Torch, 3x Pieces of Dark Bread, Curved Sword (equipped).
- **Dwarf:** Wooden Torch, 2x Pieces of Dark Bread, Dwarven Hammer (equipped).
- **Hobbit:** Wooden Torch, 3x Seed Cakes, Sylvan Blade (equipped), Sling + 5 Stones.

All starting equipment is pre-identified. Your weapon and light source are
auto-equipped. Remaining items go to inventory.

### Your First Turns

After creation you appear at the entrance to the Outer Pits of Dol Guldur (Depth 1).
Key things to know:

1. **Move** with WASD, HJKL (vi-keys), or arrow keys. Diagonal movement uses Y/U/B/N.
2. **Bump into enemies** to melee attack them.
3. **Pick up items** by stepping on them and pressing G.
4. **Open your inventory** with I to manage gear.
5. **Open the Tome** with T to view your skills, spend XP on skill points, and learn
   new abilities.
6. **Toggle stealth** with the semicolon key (;) to enter sneaking mode.
7. **Descend** by standing on stairs (>) and pressing Enter.

Your starting XP pool is **5,000 XP**. Open the Tome (T) early to invest in your
first few skill points. Every kill, discovery, and floor descent earns more XP.

---

## 3. Races & Houses

### Elves

*"The Elves of Middle-earth have dwindled in the Third Age, but those who remain
are wise and fair."*

**Stats:** STR -1, DEX +2, CON +1, GRA +2 (Total: +4)
**Racial Flag:** Bow Proficiency (+1 archery when wielding bows)
**Starting Equipment:** Wooden Torch, 2x Lembas, Curved Sword
**Compatible Houses:** Lothlorien, Rivendell, Greenwood

Elves are the most stat-rich race, with a total of +4 across their modifiers. Their
Grace bonus makes them natural Lore specialists with large voice pools, while their
Dexterity supports evasion and archery builds. Their weakness is low Strength, which
hurts melee damage. Bow Proficiency and Grace synergize well with an Archery/Lore
hybrid build.

**Of Lothlorien** (+1 GRA, Lore affinity): The classic Elf loremaster. Deep voice pool,
cheap Lore skill advancement. Word of Command and sustained songs are potent early.

**Of Rivendell** (+1 CON, Smithing affinity): The Noldorin craftsman. Extra HP
from Constitution and discounted Smithing make this the choice for forge-focused builds.

**Of Greenwood** (+1 DEX, Stealth affinity): The Silvan shadow. Maximum Dexterity
and cheap Stealth enable pure stealth/assassination playstyles.

### Men

*"Men are the secondborn children of Iluvatar, mortal and fleeting. Yet in the
Third Age, many great kingdoms of Men still stand."*

**Stats:** STR +1, DEX +0, CON +1, GRA +0 (Total: +2)
**Racial Flag:** Sword Proficiency (+1 melee when wielding swords)
**Starting Equipment:** Wooden Torch, 3x Dark Bread, Curved Sword
**Compatible Houses:** Dunedain, Rohan, Gondor

Men are the balanced generalist race. No extreme highs or lows. Sword Proficiency
works with the most common weapon type in the game. Extra food (3 bread vs 2) gives
slightly more early hunger buffer. Men can viably pursue any build.

**Dunedain** (+1 DEX, +1 GRA, Hunting affinity): The ranger. Perception and tracking
bonuses support a careful, scouting playstyle. The stat spread is excellent for
hybrid builds.

**Of Rohan** (+1 STR, Evasion affinity): The warrior. Raw Strength combined with
cheap Evasion creates a durable melee fighter who can take and dodge hits.

**Of Gondor** (+1 CON, Melee affinity): The soldier. Maximum survivability through
HP and cheap Melee advancement. Straightforward and effective.

### Dwarves

*"The Dwarves are a tough and secretive people, created by Aule the Smith in ages
past."*

**Stats:** STR +1, DEX -1, CON +3, GRA +0 (Total: +3)
**Racial Flags:** Axe Proficiency (+1 melee with axes), Archery Penalty (-1 archery),
Dwarven Resilience
**Starting Equipment:** Wooden Torch, 2x Dark Bread, Dwarven Hammer (equipped)
**Compatible Houses:** Khazad-dum, Erebor, Iron Hills

Dwarves are the tankiest race. +3 Constitution translates to substantially more HP
than any other race. Axe Proficiency works with hammers and axes. The -1 Dexterity
and Archery Penalty make ranged builds painful but not impossible. Dwarves excel
at smithing and melee combat.

**Of Khazad-dum** (+1 GRA, Lore affinity): The lorekeeper. An unusual choice for a
Dwarf, trading the smith archetype for voice abilities. Works well with a
melee/Lore hybrid.

**Of Erebor** (+1 CON, Smithing affinity): The master smith. Maximum HP and cheap
Smithing. This is the canonical Dwarf build: forge your own legendary equipment.

**Of the Iron Hills** (+1 STR, Melee affinity): The warrior. Raw melee power with
cheap advancement. Simple, brutal, effective.

### Hobbits

*"Hobbits are a small, quiet folk who love peace, good food, and comfortable homes.
Yet when pressed, they show a remarkable resilience."*

**Stats:** STR -2, DEX +2, CON +0, GRA +2 (Total: +2)
**Racial Flags:**
- Small Stature: +2 stealth, -2 attack from large monsters, -2 non-proficiency melee
- Hobbit Luck: Once per floor, reroll a lethal d20
- Sling Proficiency: +1 archery when wielding slings
**Starting Equipment:** Wooden Torch, 3x Seed Cakes, Sylvan Blade, Sling, 5 Sling Stones
**Compatible Houses:** Shire, Gamgees, Tooks

Hobbits are the stealth/ranged specialist race. Their Small Stature makes them
naturally sneaky (+2 stealth) and harder for large creatures to hit. Hobbit Luck
is a free death-save once per floor. The severe Strength penalty (-2) makes melee
builds very difficult, but sling builds with high Dexterity can be devastating.

**Of the Shire** (+1 CON, Will affinity): The stout-hearted. Extra HP and cheap
Will provide resilience against fear, confusion, and dark magic.

**Of the Gamgees** (+1 STR, Smithing affinity): The practical craftsman. Partially
offsets the Hobbit's Strength penalty while enabling forge builds.

**Of the Tooks** (+1 DEX, Stealth affinity): The burglar. Maximum Dexterity
and cheap Stealth for a pure thief build. Bilbo would be proud.

---

## 4. Skills & Abilities

### The XP-as-Currency System

The Necromancer has no character levels. Instead, you earn experience points from
combat, exploration, and descent, then spend those points to raise skill levels and
learn abilities.

- **Starting XP:** 5,000
- **XP Multiplier:** All earned XP is multiplied by 1.3x before being added to your pool.
- **Skill Cost:** Raising a skill from level N to N+1 costs `100 * (N + 1)` XP.
  So: 0->1 costs 100 XP, 1->2 costs 200 XP, 5->6 costs 600 XP, etc.
- **Affinity Discount:** Your house affinity reduces the cost of one skill by 100 XP
  per purchase. A Lothlorien Elf (Lore affinity) pays 0 XP for Lore 0->1, 100 for
  1->2, etc.

XP is earned from:
- **Kills:** `max(10, depth * 5 + rarity * 10)`. Unique monsters give 3x. All kill XP
  is further multiplied by the 1.3x player multiplier.
- **Descent:** `depth * 50` XP each time you go deeper.
- **Identification:** Small XP rewards for identifying new items.
- **Difficulty modifier:** Easy mode grants +50% XP. Other modes use 1.0x.

### The Eight Skills

Each skill ranges from 0 to 20. Higher levels unlock more powerful abilities within
that tree and provide direct passive bonuses.

#### Melee (14 abilities)

Melee skill directly adds to your attack roll in close combat. Abilities in this tree
enhance your damage output, add special attack types, and reward aggressive play.

**Key Abilities:**
- **Power (Lv 1):** +1 damage sides, but +1 to critical threshold.
- **Finesse (Lv 2):** Lowers crit threshold from 7 to 5.
- **Knock Back (Lv 3):** Chance to push enemies back based on STR vs CON.
- **Charge (Lv 5):** +3 STR/DEX bonus when attacking immediately after moving toward foe.
- **Follow-Through (Lv 6):** Continue attacking after a kill, moving to the next adjacent enemy.
- **Opening Strike (Lv 7):** Extra damage die on first attack against unwary/sleeping enemies.
- **Cleave (Lv 9):** Free attacks on all adjacent enemies when you kill one.
- **Zone of Control (Lv 10):** Free attack when enemies move between your adjacent squares.
- **Defensive Stance (Lv 12):** +3 evasion and no flanking penalty when standing still.
- **Swift Strikes (Lv 13):** Extra attack with one-handed weapon, but -3 STR/DEX.
- **Strength (Lv 20):** +1 permanent Strength.

#### Archery (9 abilities)

Archery skill adds to ranged attack rolls. Requires a bow or sling equipped in the
bow slot, plus appropriate ammunition in the quiver slot.

**Key Abilities:**
- **Rout (Lv 2):** +5 DEX bonus when firing at fleeing enemies.
- **Fletchery (Lv 3):** Create +3 arrows from ordinary ones.
- **Point Blank Archery (Lv 4):** No attack of opportunity from the target.
- **Puncture (Lv 5):** When armor fully blocks damage, deal flat 5 damage instead.
- **Ambush (Lv 6):** Extra critical die vs unwary/sleeping monsters.
- **Keen Eyes (Lv 7):** +2 archery at range 5+, spot enemies in dim light.
- **Crippling Shot (Lv 8):** Crits can slow enemies.
- **Deadly Hail (Lv 9):** Double damage on arrows fired the turn after an arrow kill.
- **Dexterity (Lv 10):** +1 permanent Dexterity.

**Using Archery:** Press F to enter targeting mode. Select a visible enemy and confirm.
You must have a ranged weapon equipped and ammunition in your quiver. Distance affects
accuracy.

#### Evasion (11 abilities)

Evasion skill directly adds to your defense roll. This tree focuses on avoiding damage,
mobility, and counterattack.

**Key Abilities:**
- **Dodging (Lv 2):** +3 evasion if you moved last turn.
- **Blocking (Lv 3):** Double shield protection when stationary.
- **Parry (Lv 4):** Double the evasion bonus from your melee weapon.
- **Crowd Fighting (Lv 5):** Halves surround bonus from multiple enemies.
- **Leaping (Lv 6):** Jump over chasms and traps when moving toward them.
- **Sprinting (Lv 7):** Increased speed after running 4+ squares in one direction.
- **Flanking (Lv 8):** Free attack when stepping around an enemy (side to side).
- **Heavy Armour Use (Lv 9):** Protection bonus based on total armor weight.
- **Riposte (Lv 10):** Free counterattack when an enemy misses by 10+.
- **Controlled Retreat (Lv 11):** Free attack when stepping away (if you didn't move last turn).
- **Dexterity (Lv 20):** +1 permanent Dexterity.

#### Stealth (12 abilities)

Stealth skill determines how hard you are to detect. See Section 8 for full stealth
mechanics. This tree enables assassination, theft, and evasion of combat entirely.

**Key Abilities:**
- **Disguise (Lv 3):** Halves awareness bonus for unwary enemies seeing you.
- **Assassination (Lv 4):** Melee bonus equal to stealth score vs non-alert creatures.
- **Throat Slit (Lv 4):** Instantly kill sleeping/unaware humanoids silently.
- **Disorienting Strike (Lv 5):** Critical hits confuse enemies.
- **Escape Artist (Lv 6):** Break free from webs; traps deal half damage, don't alert.
- **Distraction (Lv 6):** Enemies that miss by 5+ become confused for 1 turn.
- **Light Fingers (Lv 7):** Steal items from unwary adjacent enemies.
- **Vanish (Lv 8):** +10 stealth bonus for making enemies lose track of you.
- **Fade (Lv 9):** Become invisible for 2 turns after killing an unaware enemy.
- **Pilfer (Lv 10):** 25% chance for extra item drop on kills.
- **Dexterity (Lv 11):** +1 permanent Dexterity.
- **Silent Kill (Lv 12):** Throat Slit works on any enemy type (not just humanoids).

#### Hunting (10 abilities)

Hunting (formerly Perception) governs awareness, tracking, and focus. It directly
affects your ability to detect traps and hidden enemies.

**Key Abilities:**
- **Natural Talent (Lv 1):** Take advanced abilities without prerequisites.
- **Focused Attack (Lv 2):** +Hunting/2 attack bonus after passing a turn.
- **Keen Senses (Lv 3):** See beyond light edges, +5 to spot invisible creatures.
- **Concentration (Lv 4):** +1 attack per consecutive round vs same enemy (max Hunting/2).
- **Alchemy (Lv 5):** Auto-identify herbs/potions. Combine identical herbs for upgrades.
- **Bane (Lv 6):** Bonus to all rolls vs a chosen enemy category; scales with kills.
- **Outwit (Lv 7):** Negate critical damage by winning Hunting vs Perception contest.
- **Listen (Lv 8):** Detect unseen enemies through doors and around corners.
- **Master Hunter (Lv 9):** +1 attack per kill of same type (max Hunting/2).
- **Grace (Lv 10):** +1 permanent Grace.

#### Will (11 abilities)

Will governs mental fortitude, resistance to status effects, and inner strength.

**Key Abilities:**
- **Curse Breaking (Lv 1):** Remove curses from equipped items.
- **Force of Will (Lv 2):** Identify staves/horns, use them twice as efficiently.
- **Strength in Adversity (Lv 3):** +1 STR/DEX/GRA at 50% HP, +3 at 25% HP.
- **Formidable (Lv 4):** Melee kills scare observers; enemies ignore your injuries.
- **Defy Death (Lv 5):** Once per floor, Will save to survive lethal damage at 1 HP.
- **Indomitable (Lv 5):** Resist fear/confusion/stun/hallucination. 1/3 hunger rate.
- **Oath (Lv 6):** Swear a great oath for a reward.
- **Poison Resistance (Lv 7):** Resist poison.
- **Vengeance (Lv 8):** Extra damage die on your next hit after being damaged in melee.
- **Majesty (Lv 9):** Lower monster morale by half the Will difference.
- **Constitution (Lv 12):** +1 permanent Constitution.

#### Smithing (12 abilities)

Smithing allows you to create and enhance equipment at forges found throughout the
dungeon (approximately every 2 floors to depth 10).

**Key Abilities:**
- **Weaponsmith (Lv 2):** Create weapons at forges.
- **Armoursmith (Lv 3):** Create armor at forges.
- **Jeweller (Lv 4):** Create rings, amulets, and light sources. Auto-identify them.
- **Reforge (Lv 5):** Combine 2 Broken Glowing items into a random enchanted item.
  Costs 600 XP.
- **Expertise (Lv 6):** Halve forge time and costs. At Smithing 10+, 75% reduction.
- **Reclaim (Lv 7):** Combine 2 Broken Strange items into a random artifact.
- **Masterwork (Lv 8):** Combine 4 Broken Strange items into a legendary artifact.
- **Grace (Lv 10):** +1 permanent Grace.
- **Reforge Mastery (Lv 12):** Reject one Reforge result and reroll.
- **Salvage (Lv 14):** 50% chance to recover items as Broken Glowing instead of destroyed.
- **Reclaim Mastery (Lv 16):** Choose from 3 artifacts when using Reclaim.
- **Master Smith (Lv 20):** Masterwork items need only 2 Broken Strange instead of 4.

**Using a Forge:** Stand on a forge tile and press F (when no bow is equipped). The
smithing panel shows available recipes based on your abilities and materials.

**Smithing Success:** Success rate is `min(smithing_skill * 8, 95)%`. Higher skill
means fewer wasted materials.

#### Lore (18 abilities)

Lore (formerly Song) is the most versatile skill tree. It governs voice abilities,
sustained songs, and ancient knowledge. Voice charges are consumed when activating
abilities and regenerate at a rate of `max_voice / 150` per turn.

**Active Abilities (require V menu or hotkey to activate):**
- **Word of Command (Lv 1):** AOE fear + stun on nearby enemies. Very powerful.
- **Lore of Battle (Lv 1):** Provoke a target into reckless melee.
- **Word of Opening (Lv 2):** Reveal and open nearby doors, reveal traps.
- **Lore of Silence (Lv 3):** Reduce monster perception in the area.
- **Word of Shutting (Lv 4):** Seal doors permanently behind you.
- **Song of Banishment (Lv 6):** Undead within radius 3 flee for 3 turns. Ignores
  normal fear immunity. Once per floor.
- **Lore of Sleep (Lv 8):** Put a target to sleep.
- **Word of Mastery (Lv 10):** Paralyze a target.
- **Deadly Lore (Lv 6):** Kill outright if enemy HP <= 2x your Lore score.

**Passive Abilities (always active when learned):**
- **Deep Memory (Lv 2):** Auto-identify nearby dungeon layout.
- **Herbcraft (Lv 3):** Double healing from herbs and potions.
- **Inner Light (Lv 5):** +1 light radius per 5 Lore skill.
- **Lore of Endurance (Lv 7):** +Will/2 bonus, +2d2 protection.
- **Device Mastery (Lv 11):** Combine two Lore effects simultaneously.
- **Grace (Lv 12):** +1 permanent Grace.

**Sustained Songs (toggle on/off, drain voice each turn):**
- **Song of Freedom (Lv 4):** +3 evasion. Costs 1 voice/turn.
- **Song of the Trees (Lv 5):** +5 stealth. Costs 1 voice/turn.
  Requires Lore of Silence.
- **Song of Aule (Lv 7):** +2 melee. Costs 2 voice/turn.
  Requires Word of Command.

**Using Lore Abilities:** Press V to open the Voice Menu, which lists all your known
active Lore abilities with their voice charge costs. Select one to activate. Some
abilities require a target -- you will enter targeting mode. You can also bind up to
4 abilities to hotkeys 1-4 for quick-casting (Shift+1-4 in the Voice Menu to bind).

Only one sustained song can be active at a time. Activating a new song replaces the
current one. Songs drain voice charges every turn; when your charges run out, the
song stops automatically.

---

## 5. The Dungeon

### Structure

Dol Guldur is a 20-level dungeon divided into 7 named layers:

| Layer              | Depths | FOV | Darkness | Character                        |
|--------------------|--------|-----|----------|----------------------------------|
| Outer Pits         | 1-3    | 8   | 0        | Spiders, vermin, wargs. Tutorial. |
| Lower Halls        | 4-6    | 8   | 0        | Orcs, wargs, trolls. First forges.|
| Dark Halls         | 7-9    | 7   | -1       | Sorcerers, undead, orcs.          |
| Necropolis         | 10-12  | 7   | -1       | Undead, wights, vampires, shadows.|
| Pits of Despair    | 13-15  | 6   | -2       | Shadows, vampires, elites.        |
| Inner Sanctum      | 16-18  | 6   | -2       | Sauron's servants, undead, elites.|
| Throne Room        | 19-20  | 5   | -3       | Elites, shadows, the Necromancer. |

Each layer has a distinct color tint, ambient messages, monster spawn tables, item
distribution, and decoration themes.

### Darkness

The **Darkness Modifier** reduces your effective light radius as you descend. In the
Outer Pits you see normally. In the Throne Room, darkness eats 3 points of your
light radius. Bring good light sources or learn Inner Light.

### Room Types

The dungeon generator creates several room types:

- **Standard:** Rectangular rooms of varying size.
- **Cross:** Plus-shaped rooms with four arms.
- **L-Shape:** Rooms with an L-shaped footprint, creating corners.
- **Circular:** Round rooms, good for ambushes.
- **Cave:** Irregular organic shapes generated by cellular automata. Common in deeper
  layers.
- **Alcove:** Rooms with carved-out recesses in the walls. Often contain items or traps.

### Vaults

Special pre-designed rooms with guaranteed loot and dangerous occupants. Vault chance
increases with depth (10% at depth 1, up to 50% at depth 19-20). Greater vaults can
only appear once per run.

### Decorations and Themed Rooms

Rooms are decorated based on their layer:

- **Outer Pits:** Forest clearings, tower ruins, spider web clusters.
- **Lower Halls:** Orc barracks, armories, warg kennels.
- **Dark Halls:** Ritual chambers, torture rooms, rune-inscribed corridors.
- **Necropolis:** Crypts, bone chambers, ritual circles.
- **Pits of Despair:** Void chambers, shadow galleries, chasm bridges.
- **Inner Sanctum:** Grand halls, guard posts, lava chambers.
- **Throne Room:** The throne chamber, antechambers, lava moats.

### Special Features

- **Stairs Down (>):** Descend to the next depth. Stand on them and press Enter.
- **Stairs Up (<):** Ascend to the previous depth. Stand on them and press Enter.
- **Doors:** Block line of sight. Bump into them to open. Word of Opening reveals
  and opens all nearby doors.
- **Forges:** Found approximately every 2 floors down to depth 10. Press F to use.
- **Traps:** Hidden hazards. Hunting skill and Wayfarer's Instinct help detect them.
  Press D to attempt disarming. On Easy difficulty, all traps are revealed.
- **Chasms:** Impassable gaps. Leaping (Evasion ability) lets you jump over them.
- **Rubble:** Blocked passages. Word of Opening clears rubble.
- **Webs:** Slow movement and can trap you. Escape Artist breaks free.
- **Inscriptions:** Lore markers found on certain tiles. Examine with X (look mode).

### Terrain Movement Costs

Most floor tiles cost 100 energy to traverse (one standard action). Some terrain
types cost more, representing difficult ground. Heavy armor and encumbrance can
also affect movement speed.

### Bosses

Boss encounters occur at layer transition depths: 3, 6, 9, 12, 15, 18, and 20.

| Depth | Boss             | Layer Transition         |
|-------|------------------|--------------------------|
| 3     | Pit Guardian     | Outer Pits -> Lower Halls|
| 6     | Moss Horror      | Lower Halls -> Dark Halls|
| 9     | Dark Sorcerer    | Dark Halls -> Necropolis |
| 12    | Lich Lord        | Necropolis -> Pits       |
| 15    | Fire Demon       | Pits -> Inner Sanctum    |
| 18    | Nazgul           | Inner Sanctum -> Throne  |
| 20    | The Necromancer  | Final Boss               |

---

## 6. Monsters

### Overview

The dungeon contains 77 monster entries across multiple categories: spiders, orcs,
trolls, undead, shadows, vampires, wargs, human enemies, wights, vermin, fliers,
and elite guards. Each monster has stats (attack, evasion, health, protection),
flags, and behavioral AI.

### Monster Categories by Layer

**Outer Pits (1-3):** Spiders (30%), vermin (30%), fliers (15%), wargs (15%), orcs (10%).
Low-threat creatures that teach basic combat.

**Lower Halls (4-6):** Orcs (50%), wargs (25%), trolls (10%), spiders (10%), vermin (5%).
First real combat challenges. Orc packs can overwhelm.

**Dark Halls (7-9):** Human enemies (40%), undead (20%), trolls (15%), orcs (15%),
shadows (10%). Sorcerers and their servants. More dangerous abilities.

**Necropolis (10-12):** Undead (35%), wights (20%), human enemies (20%), shadows (15%),
vampires (10%). Heavy undead presence. Many resist fear.

**Pits of Despair (13-15):** Shadows (30%), human enemies (25%), undead (15%),
vampires (15%), elites (15%). Dangerous territory. Elite guards appear.

**Inner Sanctum (16-18):** Human enemies (40%), undead (25%), elites (15%),
shadows (10%), vampires (10%). Sauron's inner circle.

**Throne Room (19-20):** Elites (40%), shadows (25%), human enemies (20%),
undead (15%). The strongest monsters in the game.

### Monster AI

Monsters operate on a state machine with four states:

- **IDLE:** Standing in place. Won't react until alerted.
- **WANDERING:** Moving randomly. More likely to spot you than idle monsters.
- **HUNTING:** Actively pursuing you. Uses A* pathfinding with fallback behavior.
- **FLEEING:** Running away. Triggered by low morale or fear effects.

### Monster Alertness

Monsters have an alertness spectrum from -20 (completely unaware) to +20 (fully
alert). Alertness changes based on:

- **Distance:** Closer = easier to detect you. Formula: `max(0, 6 - distance)`.
- **Line of sight:** Being visible dramatically increases detection chance.
- **Your noise:** Combat, doors, smithing all generate noise.
- **Your stealth:** Opposed d10 roll: `d10 + perception + bonuses vs d10 + stealth_score`.

When alertness crosses key thresholds, monsters change behavior:
- Below 0: Unaware. Vulnerable to assassination, ambush, throat slit.
- 0 to 10: Cautious. Investigating.
- Above 10: Fully alert and hunting.

### Monster Morale

Each monster has morale that determines its combat stance:

- **Aggressive:** High morale. Pursues relentlessly.
- **Confident:** Normal morale. Fights but may reconsider.
- **Cautious:** Wavering. May disengage.
- **Fleeing:** Broken morale. Runs away from you.

Morale is affected by:
- Monster health relative to max
- Number of allies nearby
- Whether the player seems strong or weak
- The Formidable ability, Rallying Cry trait, and Majesty ability

Morale makes combat dynamic. A lone orc may flee after taking damage, while the
same orc in a pack fights to the death.

### Special Monster Properties

- **UNIQUE:** One-of-a-kind named monsters. 3x XP. Cannot be duplicated.
- **LIGHT_SENSITIVE:** Take penalties in bright light. Prefer dark areas when fleeing.
- **DARK_AURA:** Reduce nearby light radius.
- **INVISIBLE:** Cannot be seen without Keen Senses or high Hunting.
- **PASS_WALL:** Move through walls.
- **OPEN_DOOR / BASH_DOOR:** Can open or break through doors.
- **NO_SLEEP / NO_FEAR / NO_STUN / NO_CONF:** Immune to specific effects.
- **Breath weapons:** Some monsters breathe fire, cold, poison, or darkness.
- **Shriek:** Alert other monsters on the floor.
- **Werewolves:** Can shapeshift between human and wolf forms.

### Monster XP

XP from kills uses the formula: `max(10, depth * 5 + rarity * 10)`.
Unique monsters give 3x base XP. All kill XP is multiplied by your 1.3x
player multiplier (and further by difficulty XP modifier on Easy).

---

## 7. Items & Equipment

### Equipment Slots

Your character has 13 equipment slots:

| Slot       | Key Items                              |
|------------|----------------------------------------|
| Weapon     | Swords, axes, hammers, polearms        |
| Off Hand   | Shields, second weapon                 |
| Bow        | Bows, slings                           |
| Armor      | Soft armor, mail, robes                |
| Cloak      | Cloaks                                 |
| Head       | Helms, crowns                          |
| Hands      | Gloves, gauntlets                      |
| Feet       | Boots                                  |
| Ring Left  | Rings                                  |
| Ring Right  | Rings                                 |
| Amulet     | Amulets                                |
| Light      | Torches, lanterns, Feanorian Lamps     |
| Quiver     | Arrows, sling stones                   |

### Identification

Most items you find are **unidentified**. Unidentified consumables (potions, scrolls,
herbs) display randomized flavor names that change each run. You won't know if that
"Bubbling Potion" is a Potion of Healing or a Potion of Poison until you use it or
identify it.

Ways to identify items:
- **Use them.** Drinking a potion identifies it (and all future potions of that type).
- **Alchemy ability.** Auto-identifies herbs and potions.
- **Jeweller ability.** Auto-identifies rings, amulets, and light sources.
- **Forge Intuition trait.** Everything you pick up is identified.
- **Force of Will.** Identifies staves and horns.

Once an item type is identified, all future copies of that type appear with their
real name.

### Weapons

Weapons are defined by:
- **Attack Bonus:** Added to your melee roll.
- **Damage Dice:** How many dice and of what size you roll for damage.
- **Weight:** Affects critical hit formula and some abilities.

**Critical Hits:** When your attack roll exceeds the enemy's evasion by a large
margin, you score a critical hit. The formula is:
`Critical = (hit_margin * 10 + 4) / (70 + weapon_weight)`

Lighter weapons crit more often. The Finesse and Subtlety abilities lower the
threshold further.

**Weapon Categories:**
- **Swords (tval 23):** Balanced weapons. Sword Proficiency (Man racial).
- **Hafted (tval 21):** Hammers and maces. Good with Power ability.
- **Polearms (tval 22):** Spears and glaives. Polearm Mastery grants set-to-receive.
- **Bows (tval 19):** Ranged weapons. Require arrows. Bow Proficiency (Elf racial).
- **Slings (tval 18):** Ranged weapons. Require stones. Sling Proficiency (Hobbit racial).

### Armor and Protection

Armor provides **protection dice**, not flat damage reduction. When you take damage,
you roll your protection dice and subtract the result. This means armor is somewhat
random -- heavy armor provides more dice/sides but doesn't guarantee full protection.

- **Soft Armor (tval 36):** Light. Minimal evasion penalty.
- **Mail (tval 37):** Heavy. Better protection, bigger evasion penalty.
- **Shields (tval 34):** Add protection. Blocking ability doubles shield protection.
- **Helms (tval 32):** Head protection.
- **Boots (tval 30):** Foot protection. Required for some Evasion/Stealth abilities.
- **Gloves (tval 31):** Hand protection.
- **Cloaks (tval 35):** Light protection. Required for many Stealth/Lore abilities.

### Consumables

- **Food/Herbs (tval 80):** Restore hunger. Some herbs have special effects.
  Eat with comma (,) key.
- **Potions (tval 75):** Various effects: healing, speed, stat boosts.
  Quaff with Q key. Herbcraft doubles effectiveness.
- **Scrolls (tval 55):** One-use magical effects: mapping, enchantment, etc.
  Read with R key.
- **Horns (tval 66):** Directional blast effects. Blow with P key, then choose direction.
- **Wands (tval 56):** Targeted ranged attacks: frost, fire, slowing, light, fear, sleep.

### Light Sources

Light is critical for survival. Your base vision radius is only 1 tile without a
light source. Three main light sources exist:

| Source          | Bonus Radius | Fuel | Notes                    |
|-----------------|-------------|------|--------------------------|
| Wooden Torch    | +2          | 5000 | Cheap, common, burns out |
| Brass Lantern   | +3          | -    | Better radius            |
| Feanorian Lamp  | +4          | -    | Best. Rare.              |

Darkness modifier from deeper layers reduces your effective radius. At depth 19-20
(Throne Room, -3 darkness), even a Feanorian Lamp gives only `1 + 4 - 3 = 2` tiles
of vision without abilities.

**Enhancing Light:**
- Keen Senses ability: +1 radius.
- Inner Light ability: +1 per 5 Lore skill.
- Light of the Eldar trait: +1 radius.

### Ego Items and Artifacts

**Ego items** are equipment with magical enchantments beyond base stats. They may
grant skill bonuses, resistances, stat increases, or special abilities.

**Artifacts** are unique named items from Tolkien lore. Each artifact can only appear
once per run. They are the most powerful items in the game.

Artifacts can be found in vaults, dropped by bosses, or crafted through the Reclaim
and Masterwork Smithing abilities.

### Item Spawns by Layer

Different layers favor different item types:

- **Outer Pits:** Herbs/food heavy (35%), potions (20%), basic weapons (15%).
- **Lower Halls:** Weapons (25%), armor (20%), potions (15%).
- **Dark Halls:** Potions (25%), scrolls (20%), light sources (15%).
- **Necropolis:** Potions (25%), scrolls (20%), rings begin appearing (15%).
- **Pits of Despair:** Rings (25%), potions (20%), amulets (15%).
- **Inner Sanctum:** Rings (30%), amulets (20%).
- **Throne Room:** Rings (30%), amulets (25%), potions (20%).

### Inventory Management

Your inventory holds up to 23 items (slots a through w). Stackable items (food,
potions, arrows) share a slot.

- **G:** Pick up item from the ground.
- **I:** Open inventory. From here you can equip, drop, examine, or use items.
- **E:** Quick-equip the top item on the ground.
- **Shift+D:** Drop an item from inventory (in inventory panel).

---

## 8. Stealth & Detection

### How Stealth Works

Stealth in The Necromancer uses an **opposed d10 roll** system between you and each
nearby monster, checked every turn.

**Detection Roll:**
```
Monster:  d10 + monster_perception + distance_bonus + difficulty_bonus
Player:   d10 + player_stealth_score
```

If the monster's roll exceeds yours, they gain alertness. If your roll exceeds theirs,
they lose alertness.

**Distance Bonus (for monster):** `max(0, 6 - distance)`. Closer = easier to detect.
At distance 6+, there is no distance bonus for the monster.

**Difficulty Bonus:** On Hard/Ironman, monsters get +3 perception.

### Your Stealth Score

Your stealth score is calculated each turn:

```
Base: stealth skill level
+ Stealth Mode: +5 (toggle with ;)
+ Small Stature: +2 (Hobbit racial)
+ Disguise ability: +stealth_skill/3
+ Fade bonus: temporary boost after stealth kill
+ Patient Stalker: +3 when stealthing, no adjacent alert enemies
+ Song of the Trees: +5 while singing
+ Wayfarer's Instinct: -2 to noise (not stealth, but reduces detection)
- Noise this turn: combat noise, door noise, smithing noise, etc.
```

### Stealth Mode

Press semicolon (;) to toggle stealth mode. While in stealth mode:
- You gain +5 to your stealth score.
- You may move more slowly (higher energy cost in some situations).
- Assassination and related abilities check whether you are in stealth mode.

Stealth mode does not cost energy to toggle. It is a state that persists until
you toggle it off.

### Noise

Actions generate noise that reduces your stealth effectiveness:

| Action       | Noise |
|--------------|-------|
| Opening doors | 5    |
| Smithing      | 10   |
| Digging       | 10   |
| Bashing doors | 15   |
| Melee attack  | +2   |
| Being attacked| +2   |

Wayfarer's Instinct reduces noise by 2 (minimum 0).

### Alertness Thresholds

Monsters track alertness on a -20 to +20 scale:

- **Unaware (< 0):** Monster has no idea you are there. Assassination, Throat Slit,
  Opening Strike, Ambush, and Ambush Mastery all work against unaware targets.
- **Aware (0 to 10):** Monster suspects something. May investigate.
- **Fully Alert (> 10):** Monster is hunting you. Combat AI engaged.

When you leave a monster's line of sight, their alertness slowly decays. The Vanish
ability accelerates this decay with a +10 stealth bonus.

### Practical Stealth Strategy

1. **Toggle stealth mode early.** The +5 bonus is significant at low skill levels.
2. **Avoid combat near sleeping enemies.** Combat noise (+2 per attack/defense)
   radiates and can wake nearby monsters.
3. **Use doors.** Closing doors blocks line of sight. Word of Shutting seals them.
4. **Kill quietly.** Throat Slit and Assassination leave no survivors to raise alarms.
   Fade gives you invisibility after a stealth kill.
5. **Manage your light.** Bright lights help you see but also help monsters see you.
   In stealth-heavy builds, consider dimmer light sources.
6. **Song of the Trees.** +5 stealth while singing is enormous, but costs 1 voice/turn.
   Use it for high-risk stealth segments, not permanently.

---

## 9. Victory Conditions

### Two Paths to Victory

The Necromancer offers two victory paths, each with different requirements:

### Path 1: Escape from Dol Guldur

The simpler victory. Find Thrain (an imprisoned dwarf NPC who appears at depth 15+),
receive the **Ring of Thrain** and the **Key to Erebor** from him, then ascend all
the way back to the surface (depth 0).

**Requirements:**
1. Descend to depth 15 or deeper.
2. Find and speak to Thrain (NPC spawns on appropriate floors).
3. Receive the Ring of Thrain and Key to Erebor.
4. Ascend back to the surface with both items.

This path requires strong survivability for the journey back up. You must fight or
sneak through every floor twice.

### Path 2: Banish the Necromancer

The greater victory. Collect the three pieces of the **Rod of Istari** scattered
throughout the dungeon, assemble them, descend to the Throne Room (depth 20), and
use the assembled Rod to banish Sauron from Dol Guldur.

**Requirements:**
1. Find Rod of Istari (Head) -- spawns around depth 10.
2. Find Rod of Istari (Shaft) -- spawns around depth 15.
3. Find Rod of Istari (Base) -- spawns around depth 18.
4. Assemble the Rod of Istari from all three pieces.
5. Reach the Throne Room (depth 20).
6. Defeat or confront the Necromancer.
7. Use the Rod to complete the banishment.

This path requires going all the way to the bottom. It is the canonical "full
completion" ending.

### Quest Tracking

The game tracks your quest progress through several states:
- Not Started
- Thrain Found
- Has Ring / Has Key / Has Both
- Has Rod Piece(s)
- Rod Assembled
- Escaped / Banished
- Victory

Quest updates appear in the message log. Key quest items cannot be accidentally
destroyed or sold.

---

## 10. Controls & Keybindings

### Movement

| Key                 | Action                        |
|---------------------|-------------------------------|
| W / K / Up Arrow    | Move North                    |
| S / J / Down Arrow  | Move South                    |
| A / H / Left Arrow  | Move West                     |
| D / L / Right Arrow | Move East                     |
| Y                   | Move Northwest (diagonal)     |
| U                   | Move Northeast (diagonal)     |
| B                   | Move Southwest (diagonal)     |
| N                   | Move Southeast (diagonal)     |
| Enter               | Use stairs (when standing on) |

### Combat & Actions

| Key         | Action                                          |
|-------------|-------------------------------------------------|
| (bump)      | Melee attack (move into an enemy)               |
| F           | Fire ranged weapon / Use forge (context)         |
| V           | Open Voice ability menu (Lore abilities)         |
| 1-4         | Quick-cast ability hotkeys                       |
| Shift+1-4   | Bind ability to hotkey (in Voice menu)           |
| Shift+F     | Defensive stance                                 |
| Shift+P     | Ready parry                                      |
| D           | Disarm trap                                      |
| P           | Blow horn/flute                                  |

### Items & Inventory

| Key           | Action                                        |
|---------------|-----------------------------------------------|
| G             | Pick up item from ground                       |
| I             | Open/close inventory                           |
| E             | Quick-equip item from ground                   |
| , (comma)     | Eat food/herb                                  |
| Q             | Quaff potion                                   |
| R             | Read scroll                                    |
| Shift+D       | Drop item (in inventory)                       |

### Interface & Information

| Key           | Action                                        |
|---------------|-----------------------------------------------|
| T             | Open Tome (skills, abilities, XP spending)     |
| X             | Look mode (examine tiles, monsters, items)     |
| M             | Toggle minimap                                 |
| Tab           | Expand/collapse bottom bar                     |
| ? (Shift+/)   | Help overlay                                  |
| Escape        | Settings panel                                 |
| +/-           | Zoom in/out                                    |

### Automation

| Key           | Action                                        |
|---------------|-----------------------------------------------|
| O             | Auto-explore (move toward unexplored areas)    |
| Z             | Rest until full (HP/voice recovery)            |
| Shift+Z       | Rest for 20 turns                              |

Auto-explore and resting are interrupted by:
- Any keypress
- An enemy entering your field of view
- Taking damage
- Hunger reaching a critical threshold

### Stealth

| Key           | Action                                        |
|---------------|-----------------------------------------------|
| ; (semicolon) | Toggle stealth mode                           |

### General Notes

- **Most input requires it to be your turn.** If it is the enemy's turn, your
  keypresses are queued or ignored.
- **UI panels block game input.** While the inventory, Tome, look panel, or other
  UI is open, movement and action keys are disabled.
- **Diagonal keys (YUBN) use direct keycode detection** for macOS compatibility.
  They bypass the standard Godot input action system.
- **The comma key and semicolon key** also use direct keycode detection as a fallback
  for macOS keyboard layout compatibility.

---

## Appendix A: Stat Formulas Quick Reference

| Formula                     | Description                                     |
|-----------------------------|-------------------------------------------------|
| `HP = 24 * 1.2^CON`        | Maximum hit points                              |
| `Voice = 20 * 1.2^GRA`     | Maximum voice charges                           |
| `Voice Regen = max_voice/150` | Voice charges recovered per turn              |
| `Melee = skill + STR/2 + equip` | Total melee attack bonus                   |
| `Evasion = skill + DEX/2 + equip` | Total evasion defense bonus               |
| `Crit = (margin*10+4)/(70+weight)` | Critical hit calculation                 |
| `Skill cost = 100*(N+1)`   | XP to raise skill from N to N+1                |
| `Kill XP = max(10, depth*5 + rarity*10) * 1.3` | XP from kills            |
| `Descent XP = depth * 50`  | XP for descending to a new depth                |
| `Stealth check: d10+perception vs d10+stealth`  | Opposed detection roll   |
| `Distance bonus = max(0, 6-dist)` | Monster detection bonus from proximity   |
| `Smithing success = min(skill*8, 95)%` | Forge success rate                  |
| `Hunger drain = 1/turn`    | Hunger decreases each turn                      |

## Appendix B: Hunger Thresholds

| State      | Hunger Value | Effect                                          |
|------------|-------------|--------------------------------------------------|
| Well Fed   | 1501-2000   | No effects                                       |
| Normal     | 801-1500    | No effects                                       |
| Hungry     | 401-800     | Minor stat penalties begin                       |
| Famished   | 101-400     | Larger penalties, no natural HP regeneration      |
| Starving   | 1-100       | HP loss each turn                                |
| Dead       | 0           | Starvation death after several turns             |

Eat food (comma key) to restore hunger. Lembas and seed cakes restore more than
dark bread. The Indomitable ability reduces hunger drain to 1/3 the normal rate.

## Appendix C: Difficulty Mode Reference

| Modifier               | Easy    | Normal | Hard   | Ironman |
|------------------------|---------|--------|--------|---------|
| XP Multiplier          | 1.5x    | 1.0x   | 1.0x   | 1.0x    |
| Monster Damage         | 0.75x   | 1.0x   | 1.0x   | 1.0x    |
| Item Spawn Rate        | 1.25x   | 1.0x   | 0.80x  | 0.80x   |
| Monster Perception     | +0      | +0     | +3     | +3      |
| Traps Revealed         | Yes     | No     | No     | No      |
| Rest Healing           | Yes     | Yes    | Yes    | No      |

## Appendix D: Racial Flags Reference

| Flag               | Race    | Effect                                          |
|--------------------|---------|-------------------------------------------------|
| BOW_PROFICIENCY    | Elf     | +1 archery when wielding bows                   |
| SWORD_PROFICIENCY  | Man     | +1 melee when wielding swords                   |
| AXE_PROFICIENCY    | Dwarf   | +1 melee when wielding axes/hammers             |
| ARC_PENALTY        | Dwarf   | -1 archery                                      |
| DWARVEN_RESILIENCE | Dwarf   | Resistance to certain status effects             |
| SMALL_STATURE      | Hobbit  | +2 stealth, -2 attack from large monsters       |
| HOBBIT_LUCK        | Hobbit  | Reroll one lethal d20 per floor                 |
| SLING_PROFICIENCY  | Hobbit  | +1 archery when wielding slings                 |

---

*The Necromancer is a fan work inspired by J.R.R. Tolkien's Middle-earth and
mechanically derived from SIL-Q. It is not affiliated with or endorsed by the
Tolkien Estate or the SIL-Q development team.*

*May the light of the Eldar guide your path through the darkness of Dol Guldur.*
