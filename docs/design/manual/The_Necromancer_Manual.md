# THE NECROMANCER
## Player Manual

*Beta 1.0*

---

# Table of Contents

1. [About The Necromancer](#the-necromancer)
2. [Races and Houses](#races-and-houses)
3. [Skills](#skills)
4. [The Dungeon: Dol Guldur](#the-dungeon-dol-guldur)
5. [Monsters](#monsters)
6. [Items](#items)
7. [Victory Conditions](#victory-conditions)
8. [Stealth Guide](#stealth-guide)
9. [Controls and Interface](#controls-and-interface)
10. [Credits](#credits-and-acknowledgments)

---

# The Necromancer

## About The Necromancer

The Necromancer is a tactical roguelike game set in Tolkien's Third Age of Middle-earth. Forked from the excellent Sil-Q project, it places you in Dol Guldur during the dark years when Sauron, disguised as "The Necromancer," claimed his tower in southern Mirkwood.

Like its predecessor, The Necromancer emphasizes tactical depth over grinding. Every encounter matters, every choice has consequences, and death is permanent. This is not a game where you can outlevel your problems—you must outthink them.

## Who Will Enjoy This Game

The Necromancer is designed for players who enjoy:

- **Tactical combat** where positioning and timing matter more than stats
- **Meaningful character builds** with real tradeoffs
- **High stakes gameplay** with permanent death
- **Stealth and cunning** as viable alternatives to combat
- **Rich lore** set in Tolkien's Middle-earth

If you've enjoyed Sil, Sil-Q, Angband, or other traditional roguelikes, you'll find familiar mechanics here with a fresh setting and some new twists.

## The Setting

### Third Age, Year 2850

The shadow over Mirkwood deepens. For five years, Thráin son of Thrór, King of Durin's Folk, has languished in the dungeons of Dol Guldur, his mind broken by the Necromancer's torments.

Dol Guldur—the "Hill of Dark Sorcery"—rises in southern Mirkwood on Amon Lanc, once the capital of the Silvan Elves before Sauron's shadow fell upon it. Now it serves as the Necromancer's fortress, filled with orcs, trolls, giant spiders, and darker things.

### Your Quest

You have been chosen for a desperate mission: descend into the Hill of Dark Sorcery, find the dying dwarf-king, and recover what he carries—the last of the Seven Dwarf-rings and the key to Erebor.

Few who enter Dol Guldur return. None who have seen its deepest pits have escaped to tell the tale.

Until now.

## The Basics

### Goal

Your primary objective is to:
1. Descend through Dol Guldur's depths (to 1000 feet)
2. Find Thráin in the Pits of Despair
3. Recover the Ring of Thráin and the Key to Erebor
4. Escape back to the surface while Sauron pursues you

### Core Gameplay Loop

1. **Descend** through procedurally generated dungeon levels
2. **Fight or Avoid** the creatures that inhabit each tier
3. **Gather Equipment** to improve your chances of survival
4. **Develop Skills** by earning experience through exploration and combat
5. **Reach the Bottom** and claim your objective
6. **Escape** back to the surface in a desperate chase

### Permadeath

When your character dies, they are gone forever. This is not a bug—it's the core of the roguelike experience. Each run teaches you more about the game's systems, making your next character more likely to succeed.

Save your game when you need to stop playing, but know that loading a save resumes the game exactly where you left off. There is no "save scumming" in The Necromancer.

## Notes for Sil-Q Players

If you're coming from Sil-Q, here are the key changes:

| Sil-Q | The Necromancer |
|-------|-----------------|
| First Age setting | Third Age setting |
| Angband (Morgoth's fortress) | Dol Guldur (Sauron's fortress) |
| Retrieve a Silmaril | Retrieve Ring + Key from Thráin |
| Song magic system | Lore magic system |
| Noldor/Sindar/Naugrim/Edain | Elf/Man/Dwarf with Third Age houses |
| Escape after stealing Silmaril | Escape while Sauron pursues |

The core mechanics—combat, stealth, stats, skills—remain largely the same. The setting, lore abilities, and endgame structure are the main differences.

---

# Races and Houses

## Overview

In The Necromancer, you choose both a **race** and a **house** for your character. Your race determines your base statistics and innate abilities, while your house provides additional stat bonuses and skill affinities that shape your playstyle.

The three playable races are:
- **Elf** - Graceful and perceptive, natural archers
- **Man** - Versatile and determined, skilled with swords
- **Dwarf** - Sturdy and resilient, masters of the axe

Each race has three houses to choose from, representing different peoples and traditions of the Third Age.

## Races

### Elf

**Base Stats**: -1 Str / +2 Dex / +1 Con / +2 Gra (Total: +4)

Elves are the firstborn of Ilúvatar, immortal and fair. Though diminished from their glory in the Elder Days, the Elves of the Third Age remain formidable: swift, perceptive, and deadly with the bow.

**Racial Ability**: Bow Proficiency - Elves gain a bonus when using bows.

**Strengths**: High Dexterity and Grace make Elves excellent archers and stealth characters. Good starting stat total (+4 from race, +1 from house = +5 total).

**Weaknesses**: Lower Strength limits melee damage and carrying capacity.

### Man

**Base Stats**: +1 Str / 0 Dex / +1 Con / 0 Gra (Total: +2)

The race of Men is called the "Aftercomers" by the Elves. Though mortal and shorter-lived, Men possess a drive and adaptability that serves them well in the depths of Dol Guldur.

**Racial Ability**: Sword Proficiency - Men gain a bonus when using swords.

**Strengths**: Balanced starting stats allow for flexible builds. Sword proficiency pairs well with melee-focused houses.

**Weaknesses**: Lower overall stat total (+2 from race, +1-2 from house = +3-4 total) makes Men the challenging choice for new players.

### Dwarf

**Base Stats**: +1 Str / -1 Dex / +3 Con / 0 Gra (Total: +3)

The Dwarves are the creation of Aulë, built to endure. Their high Constitution makes them remarkably resilient, able to survive punishment that would fell an Elf or Man.

**Racial Ability**: Axe Proficiency - Dwarves gain a bonus when using axes.

**Racial Penalty**: Archery Penalty - Dwarves are less skilled with bows.

**Strengths**: Exceptional Constitution allows Dwarves to take hits and keep fighting. Good for melee-focused builds.

**Weaknesses**: The Archery penalty limits ranged options. Lower Dexterity affects Evasion and Stealth.

## Houses

### Elf Houses

#### Lothlórien
*Galadriel's Folk*

**Stats**: 0/0/0/+1 Gra
**Affinity**: Lore

The Galadhrim of Lothlórien dwell in the Golden Wood, protected by the power of Galadriel's ring. They are the most magical of the surviving Elven peoples, steeped in the lore of the Elder Days.

**Total with Race**: +5
**Playstyle**: Lore-focused, using knowledge-based abilities and magical devices.

#### Rivendell
*Elrond's Household*

**Stats**: 0/0/0/+1 Gra
**Affinity**: Lore

The Elves of Imladris are masters of healing and wisdom. Elrond Half-elven has gathered much of the remaining lore of Middle-earth in his hidden valley.

**Total with Race**: +5
**Playstyle**: Similar to Lothlórien, favoring Lore abilities and a thoughtful approach.

#### Greenwood
*Thranduil's Folk*

**Stats**: 0/+1 Dex/0/0
**Affinity**: Stealth

The Silvan Elves of the Greenwood (later called Mirkwood) are woodcraft masters. Living under the shadow of Dol Guldur itself, they have learned to move unseen through the forest.

**Total with Race**: +5
**Playstyle**: Stealth-focused, avoiding combat when possible and striking from shadows.

### Man Houses

#### Dúnedain
*Rangers of the North*

**Stats**: 0/+1 Dex/0/+1 Gra
**Affinity**: Perception

The Dúnedain are the remnant of the Númenóreans in the North. As Rangers, they patrol the wild lands, guarding the innocent from threats they never see. Their bloodline grants them longer life and keener senses than lesser Men.

**Total with Race**: +4
**Playstyle**: Balanced scouts, strong in Perception for detecting threats and secrets.

#### Rohan
*Riders of the Mark*

**Stats**: +1 Str/0/0/0
**Affinity**: Evasion

The Rohirrim are horse-masters, descended from the Éothéod of the North. Though there are no horses in Dol Guldur, their training in mobile combat translates to excellent footwork and evasion.

**Total with Race**: +3
**Playstyle**: Mobile fighters, using Evasion to avoid damage while striking back.

#### Gondor
*Men of the White Tower*

**Stats**: 0/0/+1 Con/0
**Affinity**: Melee

The soldiers of Gondor are disciplined warriors, trained in the martial traditions passed down from Númenor. They form shield walls, hold defensive positions, and fight with unwavering courage.

**Total with Race**: +3
**Playstyle**: Frontline fighters, high Constitution and Melee focus for direct combat.

### Dwarf Houses

#### Khazad-dûm
*Exiles of Moria*

**Stats**: 0/0/0/+1 Gra
**Affinity**: Lore

The descendants of the Dwarves who fled Moria after the Balrog's awakening carry with them the ancient knowledge of their forebears. They are among the few Dwarves who value learning alongside smithcraft.

**Total with Race**: +4
**Playstyle**: Unusual Dwarf build focusing on Lore abilities.

#### Erebor
*Smiths of the Lonely Mountain*

**Stats**: 0/0/+1 Con/0
**Affinity**: Smithing

Before Smaug took the Lonely Mountain, Erebor was renowned for its smiths. These Dwarves, descended from that tradition, excel at crafting and improving equipment.

**Total with Race**: +4
**Playstyle**: Smithing-focused, creating and enhancing gear to overcome challenges.

#### Iron Hills
*Dáin's Warriors*

**Stats**: +1 Str/0/0/0
**Affinity**: Melee

The Dwarves of the Iron Hills under Dáin Ironfoot are warriors first and foremost. They have defended their halls against countless Orc incursions and fear no enemy.

**Total with Race**: +4
**Playstyle**: Pure melee combat, using high Strength and Constitution to overpower foes.

## Choosing Your Build

### Easiest Combinations (Total +5)
- Elf of Lothlórien
- Elf of Rivendell
- Elf of Greenwood

### Medium Difficulty (Total +4)
- Dwarf of Khazad-dûm
- Dwarf of Erebor
- Dwarf of Iron Hills
- Dúnedain (Man)

### Challenging (Total +3)
- Man of Rohan
- Man of Gondor

For new players, we recommend starting with an Elf of Greenwood (stealth-focused) or Elf of Lothlórien (Lore-focused). These builds have the highest stat totals and strong skill affinities that help you survive the early game.

---

# Skills

## Overview

The Necromancer uses eight skills that determine your character's capabilities:

| Skill | Focus |
|-------|-------|
| **Melee** | Close combat effectiveness |
| **Archery** | Ranged combat with bows |
| **Evasion** | Avoiding attacks, mobility |
| **Stealth** | Moving undetected |
| **Perception** | Awareness, finding secrets |
| **Will** | Mental resistance, courage |
| **Smithing** | Crafting and item improvement |
| **Lore** | Knowledge-based abilities, magical devices |

## How Skills Work

### Skill Checks
Most skill uses involve a check: roll 1d10 + your skill level against a difficulty number. Meeting or exceeding the difficulty means success.

**Example**: Opening a difficulty 15 lock with Perception 8 requires rolling 7+ on 1d10 (8 + 7 = 15).

### Skill Points
You spend experience points to raise skills. The cost increases as skills get higher. See the Experience section for details.

### Skill Affinities
Houses grant affinities to specific skills. An affinity:
- Gives +1 to that skill at character creation
- Reduces the experience cost for raising that skill
- May unlock a free starting ability

## Combat Skills

### Melee

Melee determines your ability to hit enemies in close combat and deal damage with melee weapons.

**Affects**:
- Melee attack rolls (1d20 + Melee + weapon bonus vs enemy Evasion)
- Damage bonus with melee weapons
- Access to melee combat abilities

**Key Abilities**:
- **Power** - Extra damage on attacks
- **Finesse** - Improved accuracy
- **Momentum** - Bonuses after killing enemies
- **Whirlwind** - Attack multiple adjacent enemies
- **Riposte** - Counter-attack when evading

### Archery

Archery governs your accuracy and damage with bows and other ranged weapons.

**Affects**:
- Ranged attack rolls
- Damage at range
- Access to archery abilities

**Key Abilities**:
- **Precision** - Improved accuracy at range
- **Point Blank** - Better damage at close range
- **Rapid Fire** - Multiple shots per turn
- **Crippling Shot** - Slow or hinder enemies

### Evasion

Evasion is your ability to avoid being hit by attacks, both melee and ranged.

**Affects**:
- Defense against all attacks (enemy rolls vs your Evasion)
- Mobility abilities
- Access to defensive maneuvers

**Key Abilities**:
- **Dodging** - Better evasion against single attackers
- **Flanking** - Bonus when enemies are surrounded
- **Sprinting** - Increased movement speed
- **Leaping** - Jump over obstacles and enemies
- **Controlled Retreat** - Move away without provoking attacks

## Utility Skills

### Stealth

Stealth determines how well you avoid detection by enemies.

**Affects**:
- Noise generation when moving
- Chance of being spotted
- Access to stealth abilities

**Key Abilities**:
- **Disguise** - Appear harmless to some enemies
- **Assassination** - Massive damage against unaware targets
- **Vanish** - Escape from combat into shadows
- **Silent Running** - Move quickly without noise

See the Stealth Guide section for detailed stealth mechanics.

### Perception

Perception is your awareness of your surroundings and ability to notice hidden things.

**Affects**:
- Detecting traps and secret doors
- Spotting hidden enemies
- Identifying items
- Access to perception abilities

**Key Abilities**:
- **Keen Senses** - Detect enemies at greater range
- **Loremaster** - Identify items more easily
- **Danger Sense** - Warning of nearby threats
- **Eye for Detail** - Find hidden objects

### Will

Will represents mental fortitude, courage, and resistance to fear and magical effects.

**Affects**:
- Resistance to fear, confusion, and mind effects
- Ability to resist Sauron's Lidless Eye
- Access to Will abilities

**Key Abilities**:
- **Hardiness** - Improved poison/disease resistance
- **Inner Light** - Resistance to darkness effects
- **Indomitable** - Cannot be frightened
- **Clarity** - Resistance to confusion

## Crafting Skills

### Smithing

Smithing allows you to create, repair, and improve equipment.

**Affects**:
- Creating items at forges
- Repairing damaged equipment
- Improving item quality
- Assembling special items (like the Rod of the Istari)

**Key Abilities**:
- **Weaponsmith** - Create and improve weapons
- **Armoursmith** - Create and improve armor
- **Enchantment** - Add magical properties to items
- **Artifice** - Work with special materials

### Lore

Lore represents accumulated knowledge of Middle-earth—its languages, history, and subtle magic. In the Third Age, magic is learned and subtle rather than sung into existence.

**Affects**:
- Using magical devices (wands, staves)
- Casting Lore abilities (words of power)
- Reading scrolls without backfire
- Understanding artifacts

**Key Abilities**:
- **Word of Command** - Stun or terrify enemies (Lore 8)
- **Word of Opening** - Unlock doors and break holds (Lore 4)
- **Word of Shutting** - Lock doors, create barriers (Lore 6)
- **Glyph of Warding** - Place protective runes (Lore 7)
- **Herbcraft** - Double effectiveness of all herbs (Lore 3)
- **Deep Memory** - Reveal nearby dungeon layout (Lore 5)
- **Device Mastery** - Wands and staves gain bonus charges (Lore 6)
- **Ancient Tongues** - Auto-identify items, scrolls never backfire (Lore 8)

**LOR_AFFINITY** houses (Lothlórien, Rivendell, Khazad-dûm) start with +1 Lore and one free Lore ability.

## Skill Priorities by Playstyle

### Stealth Build
1. Stealth (primary)
2. Evasion (survival)
3. Perception (awareness)
4. Melee or Archery (for when stealth fails)

### Combat Build
1. Melee or Archery (primary)
2. Evasion (survival)
3. Will (resist fear from bosses)
4. Stealth (avoid unnecessary fights)

### Lore Build
1. Lore (abilities and devices)
2. Will (mental resistance)
3. Evasion (survival)
4. Perception (find items)

### Balanced Build
- Spread points across Melee/Archery, Evasion, Stealth, and Perception
- Add Will before facing Nazgûl (Tier 3+)
- Consider Lore 3 for Herbcraft regardless of build

---

# The Dungeon: Dol Guldur

## Overview

Dol Guldur—the "Hill of Dark Sorcery"—is divided into four tiers, each deeper and more dangerous than the last. The dungeon descends from the surface (0 ft) to the Pits of Despair (1000 ft) where Thráin is imprisoned.

| Depth | Tier | Name | Theme |
|-------|------|------|-------|
| 50-250 ft | 1 | The Outer Pits | Spider nests, orc warrens, forest roots |
| 250-500 ft | 2 | The Dark Halls | Torture chambers, troll dens, workshops |
| 500-750 ft | 3 | The Necropolis | Crypts, ritual chambers, wraith domains |
| 750-1000 ft | 4 | The Inner Sanctum | Nazgûl halls, prison pits, Sauron's throne |

## Tier 1: The Outer Pits (50-250 ft)

The upper levels of Dol Guldur are still touched by the forest above. Roots break through the walls, and giant spiders have woven their nests throughout the corridors. Orc patrols are frequent but poorly organized.

### Threats
- **Giant Spiders** - Venomous, spin webs that slow movement
- **Orcs** - Scouts, slaves, warriors; will alert others
- **Wargs** - Pack hunters that coordinate attacks
- **Crebain** - Spy birds that increase alertness if they escape
- **Bats** - Erratic movement, can wake nearby enemies

### Terrain Features
- **Spider Webs** - Slow movement, chance to become stuck
- **Fallen Trees** - Block line of sight, can be climbed
- **Poisoned Streams** - Damage over time if crossed
- **Orc Barricades** - Destructible walls
- **Nest Chambers** - Disturbing spawns spiders
- **Root Tunnels** - Narrow passages with stealth bonus

### Boss: Broodmother Spider
Located in a special vault. Stationary but spawns endless Mirkwood Spiders. Destroy the egg sacs around her to weaken her spawning rate.

### Strategy
The Outer Pits are the "learning" zone. Practice stealth here—avoiding fights is often better than winning them. Kill Crebain quickly before they escape and raise alertness.

## Tier 2: The Dark Halls (250-500 ft)

The middle depths are where the Necromancer's servants do their grim work. Torture chambers, troll dens, and sorcerer workshops fill these halls. The enemies here are more organized and dangerous.

### Threats
- **Mirk-Trolls** - Sun-resistant, use poisoned weapons
- **Skeletons & Zombies** - Undead that don't sleep
- **Ghouls** - Paralyzing touch
- **Orc Captains** - Command nearby orcs (+2 attack bonus)
- **Dark Sorcerers** - Cast darkness, fear, curses
- **Easterling Soldiers** - Disciplined, don't flee

### Terrain Features
- **Torture Racks** - Flavor, sometimes loot
- **Forges** - Repair items, assemble Rod of the Istari
- **Troll Caves** - Open areas with boulders for cover
- **Alchemist Tables** - Random potion (may be trapped)
- **Locked Cells** - May contain prisoners, loot, or enemies
- **Pit Traps** - Fall 50 ft, take damage

### Boss: Master Torturer
Found in the Torturer's Workshop vault. His crippling strikes reduce your Dexterity temporarily—the longer the fight, the harder it gets. End it quickly.

### Strategy
Forges become important here—use them to repair equipment. Consider rescuing prisoners for rewards but weigh the alertness cost. Watch for pit traps; falling to a lower level while injured is often fatal.

## Tier 3: The Necropolis (500-750 ft)

The domain of the undead. Ritual chambers hum with dark power, crypts hold ancient evils, and wraiths drift through the corridors. This is where you begin facing truly supernatural threats.

### Threats
- **Wights** - Life drain reduces maximum HP until rest
- **Barrow-wights** - Cast curses, drain stats
- **Necromancer Adepts** - Raise corpses as skeletons
- **Vampires** - Life steal, regenerate
- **Phantoms** - Incorporeal (50% physical attack immunity)
- **Werewolves** - Appear human until close, fast and brutal
- **Black Númenóreans** - Evil sorcerers with dark lore

### Terrain Features
- **Sarcophagi** - May contain loot or spawn wight
- **Ritual Circles** - Disturbing spawns 1d4 skeletons
- **Cursed Glyphs** - Step on = random curse
- **Bone Piles** - Necromancers can raise these
- **Black Altars** - Sacrifice items for risky boons
- **Crypts** - Vault rooms with undead guardians

### Boss: Lesser Nazgûl
A Ringwraith stalks the Necropolis. Immune to normal weapons—you need magical or silver weapons to harm it. Its Black Breath aura forces Will saves or you flee in terror. Its Morgul-blade can inflict permanent wounds.

### Strategy
Stock up on healing before entering Tier 3. Life drain from Wights is devastating—target them first. Don't disturb ritual circles unless you're ready for a fight. The Lesser Nazgûl is a major threat; consider avoiding it if possible.

## Tier 4: The Inner Sanctum (750-1000 ft)

The heart of Dol Guldur. Black Númenórean quarters, Nazgûl halls, and finally the Pits of Despair where Thráin languishes. Sauron himself dwells in the deepest chamber.

### Threats
- **Olog-hai** - Crushing blows destroy shields/armor
- **Vampire Lords** - Mist form makes them temporarily invulnerable
- **Greater Werewolves** - Pack alphas that regenerate
- **Wraiths** - Fear aura requires Will check to approach
- **Fell Spirits** - Can possess corpses mid-fight
- **Shadow Lords** - Extinguish nearby light sources
- **Khamûl the Easterling** - Second Nazgûl, guarding approach to Sauron

### Terrain Features
- **Enchanted Darkness** - Permanent low light
- **The Shadow** - Passive Will drain, fear checks every 10 turns
- **Morgul Braziers** - Green flame with fear aura
- **Escape Routes** - Hidden stairs (reward exploration)
- **Prison Pit** - Thráin's location, your objective
- **Throne Room** - Sauron's chamber

### Boss: Khamûl the Easterling
The second-most powerful Nazgûl. Phase shifts between visible and invisible states. Fear aura, sorcery, Morgul-blade, summons lesser wraiths. Immune to normal weapons.

### Final: Sauron the Necromancer
Cannot be killed through normal means (see Victory Conditions). Always knows your location. Dominating Will forces constant mental resistance checks. Dark sorcery and supernatural darkness.

### Strategy
Will becomes critical here. The Shadow's constant Will drain makes this tier a race against time. Find hidden escape routes for the return journey. Don't fight Sauron—get the Ring and Key from Thráin and run.

## Transition Zones

At tier boundaries (200-250 ft, 450-500 ft, 700-750 ft), you'll find mixed enemy types from both tiers. These serve as warnings that harder challenges await. Look for:
- Graffiti and warnings
- Corpses of previous adventurers
- Darker lighting
- More dangerous patrols

## General Dungeon Tips

1. **Rest carefully** - Resting restores HP but gives enemies time to patrol
2. **Mind your light** - Light helps you see but also helps enemies see you
3. **Use doors** - Closing doors behind you blocks line of sight
4. **Explore thoroughly** - Hidden passages often contain valuable loot
5. **Know when to flee** - Living to fight another day is victory in itself
6. **Manage alertness** - High alertness brings reinforcements and locked doors

---

# Monsters

## Overview

The creatures of Dol Guldur are organized by the tier where they primarily appear. Each tier introduces new threats and mechanics.

## Monster Mechanics

### Alertness
Some monsters can alert others to your presence:
- **Crebain** - If they escape the level, alertness increases significantly
- **Orc Scouts** - Wake nearby sleeping enemies
- **Giant Bats** - Screech wakes nearby enemies

### Pack Tactics
Wargs and some other creatures gain bonuses when fighting alongside allies of the same type.

### Undead Properties
Undead creatures:
- Don't sleep (can't be ambushed)
- May be immune to certain effects (poison, fear)
- Often vulnerable to holy effects and light
- Skeletons take extra damage from blunt weapons

### Fear Auras
Powerful creatures like Nazgûl project fear. You must pass Will checks to:
- Approach them
- Remain in their presence
- Attack them

### Special Immunities
- **Nazgûl** - Immune to normal weapons; require magical, silver, or artifact weapons
- **Phantoms** - 50% chance physical attacks pass through (incorporeal)
- **Sauron** - Cannot be reduced below 1 HP through normal means

## Tier 1 Monsters (50-250 ft)

### Common
| Monster | Key Mechanic |
|---------|-------------|
| Mirkwood Spider | Venomous bite (poison damage over time) |
| Orc Slave | Cowardly - flees when wounded, alerts others |
| Orc Scout | Alert - wakes nearby sleeping enemies |
| Giant Rat | Disease - small chance of sickness debuff |
| Bat | Erratic - hard to hit but low damage |
| Black Squirrel | Thief - steals food and flees |
| Crebain | Spy - increases floor alertness if escapes |

### Uncommon
| Monster | Key Mechanic |
|---------|-------------|
| Orc Warrior | Standard melee enemy |
| Orc Archer | Ranged attacks, weak in melee |
| Warg Pup | Pack Tactics - +1 attack per adjacent Warg |
| Large Spider | Web Shot - can slow you from range |
| Giant Bat | Screech - wakes nearby enemies |
| Swamp Adder | Ambush - hidden until adjacent, venomous |

### Rare
| Monster | Key Mechanic |
|---------|-------------|
| Orc Captain | Commander - nearby orcs get +2 to attacks |
| Great Spider | Web Trap, venomous, tough |
| Warg | Pack Tactics |
| Half-orc | Cunning - opens doors, uses items |

### Bosses
- **Orc Warchief** - Summons orc reinforcements, heavily armored
- **Broodmother Spider** - Spawns spiders, heavy poison, stationary

## Tier 2 Monsters (250-500 ft)

### Common
| Monster | Key Mechanic |
|---------|-------------|
| Orc Warrior | Standard enemy |
| Orc Archer | Ranged |
| Warg | Pack Tactics |
| Skeleton | Brittle - extra damage from blunt weapons |
| Zombie | Slow, Relentless - always moves toward you, high HP |
| Hill Troll | Weaker near light sources |
| Cave Spider | Ceiling Ambush - drops from above, first strike |

### Uncommon
| Monster | Key Mechanic |
|---------|-------------|
| Orc Captain | Commander |
| Mirk-Troll | Sun resistant, poisoned weapon |
| Skeleton Warrior | Shield Block - higher evasion from front |
| Ghoul | Paralyzing Touch - failed Will = lose next turn |
| Easterling Soldier | Disciplined - doesn't flee, formation fighting |
| Dark Acolyte | Dark Prayer - heals nearby undead |

### Rare
| Monster | Key Mechanic |
|---------|-------------|
| Wight | Life Drain - damage reduces max HP until rest |
| Half-troll | Regeneration - heals over time |
| Easterling Champion | Duelist - bonus damage in 1v1 combat |
| Dark Sorcerer | Casts darkness, fear, curses |
| Corpse-candle | Lure - must save Will or move toward it |

### Bosses
- **Troll Chieftain** - Frenzy when wounded, throws boulders
- **Master Torturer** - Crippling strikes reduce your Dexterity

## Tier 3 Monsters (500-750 ft)

### Common
| Monster | Key Mechanic |
|---------|-------------|
| Mirk-Troll | Sun Resistant |
| Skeleton Warrior | Shield Block |
| Wight | Life Drain |
| Easterling Warrior | Disciplined |
| Ghast | Stench - adjacent player gets -2 to attacks |

### Uncommon
| Monster | Key Mechanic |
|---------|-------------|
| Olog-hai | Crushing Blow - can destroy shields/armor |
| Barrow-wight | Curse - casts curses, drains stats |
| Necromancer Adept | Raise Dead - reanimates corpses as skeletons |
| Vampire Thrall | Blood Frenzy - faster when you're wounded |
| Black Númenórean | Dark Lore - resists Lore abilities, casts spells |

### Rare
| Monster | Key Mechanic |
|---------|-------------|
| Werewolf | Shapeshifter - appears human until close |
| Vampire | Life Steal - heals when hitting you |
| Phantom | Incorporeal - 50% physical attack immunity |
| Shadow | Strength Drain - damage reduces Str temporarily |
| Crypt Lord | Raise Dead, commands undead |

### Boss
- **Lesser Nazgûl** - Black Breath fear aura, Morgul-blade, immune to normal weapons

## Tier 4 Monsters (750-1000 ft)

### Common
| Monster | Key Mechanic |
|---------|-------------|
| Olog-hai | Crushing Blow |
| Phantom | Incorporeal |
| Barrow-wight | Curse |
| Black Númenórean | Dark Lore |

### Uncommon
| Monster | Key Mechanic |
|---------|-------------|
| Vampire Lord | Mist Form - briefly invulnerable, repositions |
| Greater Werewolf | Alpha - commands lesser werewolves, regenerates |
| Wraith | Fear Aura - must pass Will to approach |
| Fell Spirit | Possession - can take over corpses mid-fight |

### Rare
| Monster | Key Mechanic |
|---------|-------------|
| Shadow Lord | Darkness - extinguishes light sources |
| Úlairi | Lesser Black Breath, phasing, weapon immunity |
| Maia Thrall | Corrupted Power - random powerful spell effects |

### Bosses
- **Khamûl the Easterling** - Second Nazgûl, phase shifts, sorcery, summons wraiths
- **Sauron the Necromancer** - Unkillable, Lidless Eye, Dominating Will, Dark Sorcery

## Combat Tips by Monster Type

### Against Spiders
- Don't get webbed; maintain distance when possible
- Poison antidotes are essential
- Destroy egg sacs before engaging Broodmother

### Against Orcs
- Kill scouts and Crebain first to prevent alerts
- Focus on Captains to remove the Commander bonus
- Use stealth to avoid unnecessary fights

### Against Trolls
- Use light to weaken Hill Trolls
- Use cover against boulder-throwing Troll Chieftain
- Kite rather than trade blows

### Against Undead
- Use blunt weapons against skeletons
- Kill Necromancers before they raise corpses
- Don't let Wights stack Life Drain

### Against Nazgûl
- Ensure you have magical or artifact weapons
- High Will is essential to resist Black Breath
- Consider fleeing rather than fighting
- Stock Waters of Rivendell for Morgul-wounds

---

# Items

## Overview

Items in The Necromancer fall into several categories:
- **Weapons** - Melee and ranged combat
- **Armor** - Protection from damage
- **Staves** - Two-handed casting implements
- **Wands** - One-handed ranged magic
- **Herbs** - Consumable healing and buffs
- **Potions** - Liquid consumables
- **Scrolls** - One-use magical writings
- **Artifacts** - Unique powerful items

## Weapons

### Melee Weapons

Melee weapons have attack bonuses and damage dice. Damage notation: XdY means roll X dice with Y sides.

**Swords** (Men gain proficiency bonus)
- Good all-around weapons
- Balanced attack and damage

**Axes** (Dwarves gain proficiency bonus)
- Higher damage, lower accuracy
- Can destroy some terrain

**Daggers**
- Fast attacks, lower damage
- Bonus for stealth attacks

**Spears**
- Can attack at 2-tile range
- Good for controlling space

**Hammers/Maces**
- Extra damage vs skeletons
- Can stun enemies

### Ranged Weapons

**Bows** (Elves gain proficiency bonus, Dwarves have penalty)
- Require arrows
- Damage reduced at longer range

### Special Properties

Weapons may have magical properties:
- **Flaming** - Fire damage, lights area
- **Frost** - Cold damage, can slow
- **Vampiric** - Heals on hit
- **Slaying** - Bonus vs specific enemy type
- **Holy** - Bonus vs undead and evil

## Armor

### Armor Types

| Type | Protection | Evasion Penalty | Notes |
|------|------------|-----------------|-------|
| Robes | [0, 1d1] | 0 | No protection |
| Leather | [0, 1d4] | 0 | Light, no penalty |
| Studded Leather | [0, 2d4] | -1 | Slight penalty |
| Mail | [0, 2d6] | -2 | Good protection |
| Plate | [0, 3d6] | -4 | Heavy, best protection |

Protection notation: [+X, YdZ] means +X to protection rolls, rolling YdZ for damage reduction.

### Helmets, Gloves, Boots

Additional armor pieces provide smaller protection bonuses and sometimes special abilities.

### Shields

Shields increase evasion and can block attacks. Some enemies (Olog-hai) can destroy shields with crushing blows.

## Staves

Staves are two-handed weapons that cast magical effects. They have limited charges that can be restored by combining two staves of the same type.

| Staff | Charges | Effect | Lore Req |
|-------|---------|--------|----------|
| Staff of Light | 8 | Illuminates area, damages undead | 2 |
| Staff of Striking | 6 | Melee attack with knockback | 3 |
| Staff of Opening | 10 | Unlocks doors, breaks holds | 4 |
| Staff of Slumber | 6 | Puts enemy to sleep | 5 |
| Staff of Warding | 5 | Creates blocking glyph (3 turns) | 6 |
| Staff of Revelation | 4 | Reveals traps/secrets in radius | 7 |
| Staff of Sanctity | 4 | Damages/repels undead in radius | 8 |
| Staff of Command | 3 | Stuns/terrifies enemies in cone | 10 |

Higher Lore skill recovers more charges when combining staves.

## Wands

Wands are one-handed items that fire ranged magical bolts. Like staves, charges can be restored by combining.

| Wand | Charges | Effect | Lore Req |
|------|---------|--------|----------|
| Wand of Light | 12 | Light bolt, minor undead damage | 1 |
| Wand of Slow | 8 | Target slowed 10 turns | 3 |
| Wand of Frost | 8 | Cold bolt, slows target | 3 |
| Wand of Fire | 6 | Fire bolt, higher damage | 4 |
| Wand of Sleep | 6 | Target falls asleep | 4 |
| Wand of Fear | 5 | Target flees (Will save) | 5 |
| Wand of Binding | 4 | Target paralyzed 3 turns | 8 |
| Wand of Dispel | 3 | Removes magic, damages summoned | 10 |
| Wand of Death | 2 | Massive damage, instant kill chance | 12 |

## Herbs

Herbs are found throughout the dungeon. The **Herbcraft** ability (Lore 3) doubles their effectiveness.

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

**Note**: Athelas is very rare. Don't rely on finding it.

## Potions

Potions always work regardless of skill. Some potions are harmful—learn to identify them!

### Beneficial Potions
| Potion | Effect |
|--------|--------|
| Healing | Restore 25 HP |
| Greater Healing | Restore 50 HP |
| Clarity | Cure confusion/fear, +2 Will 20 turns |
| Strength | +3 Str for 30 turns |
| Dexterity | +3 Dex for 30 turns |
| Grace | +3 Grace for 30 turns |
| True Sight | See invisible, see in darkness 50 turns |
| Resist Fire | Fire resistance 100 turns |
| Resist Cold | Cold resistance 100 turns |
| Antidote | Cures poison |
| Restoration | Restores drained stats |
| Waters of Rivendell | Cures Morgul-wound (very rare) |

### Harmful Potions
| Potion | Effect |
|--------|--------|
| Poison | Damages you (looks like healing) |
| Weakness | -3 Str (looks like Strength) |

Identifying potions before drinking is strongly recommended.

## Scrolls

Scrolls are one-use items. Higher Lore reduces backfire chance.

| Scroll | Effect | Backfire |
|--------|--------|----------|
| Scroll of Identify | Identifies one item | Item cursed instead |
| Scroll of Mapping | Reveals floor layout | Reveals you to enemies |
| Scroll of Light | Lights entire floor | Blinds you |
| Scroll of Teleport | Random teleport | Teleport into danger |
| Scroll of Darkness | Darkens floor | Only you are blinded |
| Scroll of Sanctuary | Enemies can't enter tile 10 turns | You can't leave tile |
| Scroll of Warding | Permanent glyph on tile | Glyph hurts you |
| Scroll of Banishment | Destroys undead in radius | Summons undead |
| Scroll of Recall | Return to surface (escape!) | Teleports deeper |

The **Ancient Tongues** ability (Lore 8) makes scrolls never backfire.

## Artifacts

### Quest Items

These items are required for victory:

| Artifact | Location | Effect |
|----------|----------|--------|
| Ring of Thráin | Thráin's body (1000 ft) | +3 Will, +2 Smithing; CURSED |
| Key to Erebor | Thráin's body (1000 ft) | Required for victory |

The Ring of Thráin causes **Gold Hallucination**—you see fake gold everywhere and must pass Will checks to avoid wasting turns chasing it.

### Major Artifacts

| Artifact | Type | Special |
|----------|------|---------|
| Aiglos | Spear | Frost brand, freezes enemies |
| Narsil Shard | Dagger | Massive bonus vs Sauron/Nazgûl |
| Mithril Corslet | Armor | Featherlight - no evasion penalty |
| Bow of Lórien | Bow | Reduced range penalty |
| Galadriel's Phial | Light | Radius 5, damages undead/shadows |
| Vilya's Shard | Ring | +2 all stats, single-use Morgul cure |

### Minor Artifacts

| Artifact | Effect |
|----------|--------|
| Ranger's Cloak | +3 Stealth, harder to detect when still |
| Dwarf-lantern | Radius 3, never runs out |
| Athelas Pouch | 3 uses, strong heal + cure poison |
| Elrond's Tome | +2 Lore, identify any item |
| Black Arrow | One-shot massive damage |

### Cursed Artifacts

| Artifact | Curse |
|----------|-------|
| Morgul-blade | Can't unequip, deals slow damage to wielder |
| Necromancer's Circlet | Drains Grace, Sauron can sense you |

## Combining Items

Some items can be combined:
- Two staves/wands of the same type → Restored charges
- Broken Staff (Upper) + Broken Staff (Lower) at forge → Rod of the Istari

The Rod of the Istari is required for the Banishment Victory path.

---

# Victory Conditions

## Overview

There are two ways to win The Necromancer:
1. **Escape Victory** - Retrieve the Ring and Key, escape to the surface
2. **Banishment Victory** - Banish Sauron with the Rod of the Istari

Both are legitimate victories. Escape Victory is the standard path; Banishment Victory is the challenging alternative.

## Escape Victory (Standard)

### Requirements
1. Descend to depth 1000 ft (the Pits of Despair)
2. Find Thráin's prison cell
3. Take the Ring of Thráin and Key to Erebor
4. Return to the surface (depth 0)

### The Journey Down

Your descent through Dol Guldur takes you through four tiers of increasing danger:

| Tier | Depth | Challenge |
|------|-------|-----------|
| The Outer Pits | 50-250 ft | Spiders, orcs, wargs |
| The Dark Halls | 250-500 ft | Trolls, undead, sorcerers |
| The Necropolis | 500-750 ft | Wraiths, vampires, Nazgûl |
| The Inner Sanctum | 750-1000 ft | Sauron's domain |

### Finding Thráin

Thráin II, King of Durin's Folk, is imprisoned in the Pits of Despair at 1000 ft. He has been tortured for five years and is dying.

When you find him:
- He is mentally broken and cannot be saved
- He will give you (or you will take from his body) the Ring and Key
- His death is inevitable—this is not a choice you can prevent

### Taking the Ring

The moment you take the Ring of Thráin and Key to Erebor, **Pursuit Mode** begins.

### Pursuit Mode

When you take the Ring:

**Sauron Awakens**
- Sauron appears in his throne room
- He begins pursuing you through the dungeon
- He always knows your general location (Lidless Eye)

**The Dungeon Changes**
- New enemies spawn on all floors
- Some staircases become locked
- Some areas collapse, blocking routes
- Hidden shortcuts open up

**The Chase**
- Sauron moves toward you each turn (slower but relentless)
- You cannot kill him through normal means
- You must outrun him to the surface

**The Ring's Burden**
- The Ring of Thráin is cursed with Gold Hallucination
- You see fake gold piles everywhere
- Must pass Will checks or waste turns chasing mirages
- Higher Will = fewer hallucinations

**Exhaustion**
- Every 5 floors ascended: -1 to a random stat temporarily
- The Ring weighs on its bearer
- Stats restore upon victory

### Reaching the Surface

If you reach depth 0 (the surface) while carrying the Ring and Key, you win.

You have escaped Dol Guldur with the treasures of Thráin. The Key will eventually reach the dwarves, leading to the Quest of Erebor. The Ring's fate... is another story.

## Banishment Victory (Hard)

### Requirements
1. Find both pieces of the Broken Staff
2. Assemble the Rod of the Istari at a forge
3. Achieve Lore 12+ and Will 10+
4. Confront Sauron in his throne room
5. Win the Banishment contest

### Finding the Broken Staff

The Rod of the Istari was broken long ago. Its pieces are hidden in Dol Guldur:

| Piece | Location | Stats |
|-------|----------|-------|
| Broken Staff (Upper) | Tier 2 vault (~400 ft) | +2 Lore, +1 Will |
| Broken Staff (Lower) | Tier 3 (~700 ft) | +2 Lore, +1 Grace |

Both pieces function as weapons and provide bonuses while carried.

### Assembling the Rod

At any **forge** (found in Tier 2 and deeper), with both pieces in your inventory, you can assemble the Rod of the Istari.

**Rod of the Istari**
- +5 Lore
- +3 Will
- Enables the Banishment ability

### The Banishment

With the Rod assembled and sufficient skills (Lore 12+, Will 10+), you can confront Sauron directly.

**Banishment Action**:
1. Must be in same room as Sauron
2. Use the Banishment ability (costs your full turn)
3. Contested Will check: your Will vs Sauron's Will

**Success**:
- Sauron is banished from his physical form
- He cannot pursue you
- You can loot his throne room freely
- Take the Ring and Key at your leisure
- Return to surface without Pursuit Mode

**Failure**:
- The Rod of the Istari is destroyed
- You take massive damage
- Sauron is enraged
- You must escape normally (now without the Rod's bonuses)

### Why Attempt Banishment?

**Advantages**:
- No Pursuit Mode means easier escape
- Can explore Tier 4 thoroughly
- Additional loot from throne room
- Greater glory in the scoring system

**Disadvantages**:
- Requires finding both staff pieces
- Requires Lore 12+ and Will 10+ (significant investment)
- Failure is catastrophic
- Sauron is immensely powerful

## Defeat Conditions

You lose if:
- Your HP reaches 0
- Certain instant-death effects (rare)
- Sauron catches you during Pursuit Mode with no escape

## Tips for Victory

### Escape Victory
1. **Speed matters** - Don't clear every room; move with purpose
2. **High Will helps** - Resists Ring hallucinations and Sauron's gaze
3. **Map escape routes** - Note hidden passages on the way down
4. **Stock supplies** - Healing and teleportation for the escape

### Banishment Victory
1. **Prioritize Lore** - Need 12 for the check
2. **Don't neglect Will** - Need 10 for the check
3. **Find the staff pieces early** - They give bonuses while carried
4. **Consider backup plan** - If Banishment fails, you need to escape

### General
1. **Stealth is survival** - Avoid unnecessary fights
2. **Know your limits** - Retreat before it's too late
3. **Use terrain** - Doors, corridors, and obstacles save lives
4. **Save resources** - That potion you use now might be needed later

---

# Stealth Guide

## Philosophy

The Necromancer emphasizes stealth-first gameplay. Unlike many roguelikes where combat is the primary solution, Dol Guldur rewards those who slip through unseen. Every fight you avoid is:
- HP you didn't lose
- Resources you didn't spend
- Alertness you didn't raise
- Time you didn't waste

The goal is to reach Thráin and escape, not to kill everything in your path.

## Stealth Mechanics

### Detection

Monsters detect you through:

1. **Sight** - Enemies in your light radius or with you in theirs can see you
2. **Sound** - Actions generate noise that can alert nearby enemies
3. **Alertness** - High dungeon alertness means more patrols and searches

### Light and Vision

| Your Light | Effect |
|------------|--------|
| None | Enemies within 1 tile may spot you |
| Dim | Enemies within 2-3 tiles may spot you |
| Bright | Enemies within 4+ tiles may spot you |

Darkness helps stealth but limits your own vision. Balance is key.

### Noise

Actions generate noise:

| Action | Noise Level |
|--------|-------------|
| Standing still | None |
| Walking | Low |
| Running | Medium |
| Combat | High |
| Breaking objects | Very High |
| Using loud abilities | Varies |

Higher Stealth skill reduces noise from your actions.

### Alertness System

The dungeon has an overall **Alertness Level** that affects enemy behavior:

| Alertness | Effect |
|-----------|--------|
| 0-10 | Normal patrols |
| 11-25 | Increased patrols, some locked doors |
| 26-50 | Ambushes possible, reinforcements arrive |
| 50+ | Full alert, boss enemies may roam |

**Alertness Triggers**:
- Combat: +1-3 depending on noise
- Crebain escapes: +5
- Alarm triggered: +10
- Time: Slow decay

## Stealth Skills and Abilities

### Stealth Skill

Each point of Stealth:
- Reduces noise you generate
- Increases chance of remaining undetected
- Unlocks stealth abilities

### Key Stealth Abilities

**Disguise**
- Appear harmless to some enemies
- Certain creatures may ignore you entirely

**Assassination**
- Massive damage bonus against unaware targets
- One-shot kills on weaker enemies

**Vanish**
- Break contact during combat
- Slip back into shadows

**Silent Running**
- Move at full speed without increased noise
- Essential for escape sequences

### Stealth Affinity

The **Greenwood** house (Elf) grants Stealth affinity:
- +1 Stealth at character creation
- Reduced cost to raise Stealth
- Free starting stealth ability

## Stealth Tactics

### Basic Stealth

1. **Move carefully** - Don't run unless necessary
2. **Manage light** - Dim light or darkness when hiding
3. **Use cover** - Stay behind walls and doors
4. **Wait** - Let patrols pass before moving
5. **Close doors** - Block line of sight behind you

### Avoiding Detection

1. **Spot enemies first** - High Perception lets you see them before they see you
2. **Track patrol patterns** - Enemies move predictably
3. **Use corridors** - Narrow passages let you control engagement
4. **Kill scouts quietly** - Crebain and Orc Scouts must die fast

### When Stealth Fails

Sometimes you're spotted. When this happens:

1. **Break line of sight** - Get behind a wall or door
2. **Don't fight in the open** - Lead enemies to favorable ground
3. **Consider fleeing** - Escape is often better than combat
4. **Use abilities** - Vanish, sleep effects, fear effects
5. **Accept the fight** - If you must fight, fight decisively

### Stealth and Alertness Management

High alertness makes stealth harder. To manage alertness:

1. **Kill Crebain immediately** - Their escape raises alertness by 5
2. **Avoid alarms** - Some traps raise alertness
3. **Don't massacre** - Killing many enemies raises alertness
4. **Let it decay** - Time reduces alertness slowly

## Stealth Builds

### Pure Stealth (Elf of Greenwood)

**Priority Skills**: Stealth > Evasion > Perception > Melee

**Strategy**:
- Avoid almost all combat
- Assassination for necessary kills
- Race to Thráin and escape

**Advantages**: Fast, resource-efficient
**Disadvantages**: Vulnerable when detected

### Stealth-Combat Hybrid

**Priority Skills**: Stealth > Melee > Evasion > Will

**Strategy**:
- Use stealth to choose engagements
- Fight when advantageous
- Avoid unnecessary battles

**Advantages**: Flexible, can handle mistakes
**Disadvantages**: Neither specialized

### Combat with Stealth Support

**Priority Skills**: Melee > Evasion > Stealth > Will

**Strategy**:
- Fight effectively
- Use stealth to avoid overwhelming odds
- Skip optional encounters

**Advantages**: Strong in combat
**Disadvantages**: More resource-intensive

## Stealth-Positive Items

### Armor
- Light armor has no stealth penalty
- Heavy armor reduces stealth significantly

### Artifacts
- **Ranger's Cloak**: +3 Stealth, harder to detect when still
- **Hithlain Leaf**: Temporary stealth boost

### Equipment Considerations
- Light sources reveal you - consider when to use them
- Noisy weapons (axes) may be suboptimal for stealth builds

## Floor-by-Floor Stealth Tips

### Tier 1 (Outer Pits)
- Kill Crebain on sight
- Avoid Orc Scouts or kill quickly
- Spider Webs slow you - don't get stuck while fleeing
- Root Tunnels provide stealth bonus

### Tier 2 (Dark Halls)
- Undead don't sleep - can't be ambushed
- Watch for pit traps while sneaking
- Cave Spiders drop from above - check ceilings

### Tier 3 (Necropolis)
- Ritual Circles spawn undead if disturbed - avoid
- Wraiths have fear auras - may force you to flee
- Lesser Nazgûl should be avoided if possible

### Tier 4 (Inner Sanctum)
- The Shadow causes constant Will drain - move fast
- Enchanted Darkness limits vision both ways
- Sauron's Lidless Eye means true stealth is impossible
- Plan your escape route before taking the Ring

## The Escape (Stealth in Pursuit Mode)

During Pursuit Mode, pure stealth is impossible—Sauron always knows your general location. However:

1. **Enemies still use normal detection** - Stealth helps against minions
2. **Speed matters** - Silent Running lets you move fast quietly
3. **Hidden passages** - Knowledge of escape routes trumps stealth
4. **Distraction** - Enemies chase you; use this to create gaps

The escape is about controlled movement, not invisibility.

---

# Controls and Interface

## Movement

### Basic Movement

Move using the numpad or vi-keys:

```
Numpad:          Vi-keys:
7  8  9          y  k  u
 \ | /            \ | /
4 -5- 6          h -.- l
 / | \            / | \
1  2  3          b  j  n
```

**5** or **.** - Wait one turn (pass)

### Running

**Shift + direction** - Run in that direction until interrupted

Running continues until you:
- See an enemy
- Reach an intersection
- Hit an obstacle

Running generates more noise than walking.

### Stairs

**<** - Go up stairs (when standing on up stairs)
**>** - Go down stairs (when standing on down stairs)

## Combat

**Direction toward enemy** - Attack in melee
**f** - Fire ranged weapon
**t** - Throw an item

### Targeting

When using ranged attacks:
- Use direction keys to select target
- **Enter** or **f** again to confirm
- **Escape** to cancel

## Inventory

**i** - View inventory
**e** - Equipment screen
**d** - Drop item
**w** - Wield weapon
**W** - Wear armor
**T** - Take off armor

### Using Items

**a** - Activate (use wands, staves, special items)
**q** - Quaff potion
**r** - Read scroll
**E** - Eat (herbs, food)

### Item Management

**I** - Inspect item (detailed information)
**{** - Inscribe item (add note)
**k** - Destroy item

## Abilities

**m** - View/use abilities
**A** - Auto-abilities toggle

Abilities cost turns and sometimes have additional costs or requirements.

## Magic Items

### Wands and Staves

**a** then select item - Activate wand or staff
- Wands fire at a target (must aim)
- Staves often affect area around you

### Combining Items

When you have two identical wands or staves:
**a** - Select one, then select the other to combine

Higher Lore skill = more charges recovered.

## Information Commands

**C** - Character screen (stats, skills)
**@** - Detailed character info
**%** - Knowledge (identified items)
**~** - Identified monster list
**M** - Full dungeon map
**L** - Look around (examine terrain/items)

### The Look Command

**L** - Enter look mode
- Move cursor with direction keys
- **Enter** - Get info about what's under cursor
- **Escape** - Exit look mode

## Display

### The Main Screen

```
+--------------------------------------------------+
|  Map Area                                        |
|                                                  |
|                @                                 |
|                                                  |
|                                                  |
+--------------------------------------------------+
| HP: 45/50  Voice: 3/5  Depth: 200'               |
| [Status Effects]                                 |
+--------------------------------------------------+
```

### Status Line

- **HP**: Current / Maximum health
- **Voice**: Current / Maximum (for Lore abilities)
- **Depth**: Current dungeon depth in feet

### Status Effects

Status effects appear as abbreviated tags:
- **Psn** - Poisoned
- **Blnd** - Blinded
- **Conf** - Confused
- **Fear** - Frightened
- **Slow** - Slowed
- **Haste** - Hasted

### The Sidebar

The sidebar shows:
- Nearby monsters and their status
- Equipment readout
- Other contextual information

### Messages

Recent game messages appear at the top of the screen. Press **Ctrl+P** to view message history.

## Options and Settings

**=** - Options menu
**?** - Help

### Useful Options

- **Auto-pickup** - Automatically pick up certain items
- **Run-cut-corners** - Running behavior at corners
- **Disturb options** - What interrupts resting/running

## Saving and Quitting

**Ctrl+S** - Save game
**Ctrl+Q** or **Q** - Save and quit
**Ctrl+X** - Quit without saving (suicide)

**Warning**: Quitting without saving destroys your character permanently. This is intentional—no save scumming.

## Quick Reference

| Key | Action |
|-----|--------|
| Direction | Move/Attack |
| 5 or . | Wait |
| < | Go up stairs |
| > | Go down stairs |
| f | Fire ranged |
| i | Inventory |
| e | Equipment |
| a | Activate item |
| q | Quaff potion |
| r | Read scroll |
| E | Eat |
| m | Abilities |
| C | Character |
| M | Map |
| L | Look |
| ? | Help |
| = | Options |

## Mouse Support

Some versions support mouse input:
- **Click** to move
- **Click enemy** to attack
- **Right-click** to examine

---

# Credits and Acknowledgments

## The Necromancer

**The Necromancer** is a fan-made roguelike game set in Tolkien's Middle-earth. It is free software, developed by fans for fans.

## Built Upon Giants

The Necromancer is a fork of **Sil-Q**, which is itself a variant of **Sil**, which descends from the venerable **Angband** roguelike tradition.

### Sil
Created by **Scatha** and **Fingolfin**

Sil brought a fresh approach to the roguelike genre with its emphasis on tactical combat, meaningful choices, and deep Tolkien lore. Its innovations in stealth, skill systems, and encounter design form the foundation of The Necromancer.

### Sil-Q
Maintained by the **Sil-Q community**

Sil-Q continued development of Sil with balance improvements, new content, and bug fixes. The Necromancer builds directly on Sil-Q's codebase.

### Angband
Originally by **Ben Harrison**, based on **Moria** by Robert Alan Koeneke

Angband is one of the longest-running open source projects in existence, with development spanning over 30 years. Countless contributors have shaped it into the deep, complex game that inspired Sil and its descendants.

## Tolkien's Legacy

The setting, characters, and lore of The Necromancer are inspired by the works of **J.R.R. Tolkien**, particularly *The Hobbit*, *The Lord of the Rings*, and *The Silmarillion*.

The Necromancer is a **non-commercial fan work** created out of love for Tolkien's legendarium. It is not affiliated with, endorsed by, or connected to the Tolkien Estate, Middle-earth Enterprises, or any official Tolkien-related entity.

## License

The Necromancer is released under the **GNU General Public License version 2 (GPLv2)**.

This means you are free to:
- Play the game
- Modify the source code
- Distribute copies
- Create your own variants

Provided that any distributed modifications are also released under the GPL.

## Get Involved

The Necromancer is open source. Contributions are welcome!

**Source Code**: https://github.com/sil-quirk/sil-q

You can contribute by:
- Reporting bugs
- Suggesting improvements
- Submitting code changes
- Creating content
- Writing documentation
- Spreading the word

## Special Thanks

To everyone who has contributed to the roguelike tradition, from the creators of Rogue in 1980 to the modern developers keeping the genre alive.

To the Tolkien fan community for preserving and celebrating the Professor's work.

And to you, for playing.

---

*In the shadows of Mirkwood's eaves, a darkness stirs beneath the leaves...*

**The Necromancer** - A Fan-Made Roguelike

*Beta 1.0 - January 2026*
