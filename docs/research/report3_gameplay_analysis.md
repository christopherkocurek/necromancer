# Report 3: Necromancer Gameplay Problem-Solving Analysis

**Generated:** 2026-02-08
**Purpose:** Identify what gameplay problems exist at each depth tier, what the player needs to solve them, and where enchanted items are needed to fill the gaps.

---

## 1. Dungeon Progression Overview

The dungeon has **20 floors** across **7 layers** (with a layer config mapping that differs slightly from monster.txt's layer comments):

| Layer | Config Name | Depths | Theme | FOV | Darkness Mod |
|-------|------------|--------|-------|-----|-------------|
| 1 | Outer Pits | 1-3 | Forest corruption, spiders, vermin | 8 | 0 |
| 2 | Lower Halls | 4-6 | Orcs, wargs, military | 8 | 0 |
| 3 | Dark Halls | 7-9 | Sorcerers, trolls, ghouls | 7 | -1 |
| 4 | Necropolis | 10-12 | Undead hordes, living servants, caves | 7 | -1 |
| 5 | Pits of Despair | 13-15 | Wraiths, shadows, elite mortals | 6 | -2 |
| 6 | Inner Sanctum | 16-18 | Black Numenoreans, Olog-hai, vampires | 6 | -2 |
| 7 | Throne Room | 19-20 | Sauron's domain, elite guards, the end | 5 | -3 |

**Boss levels:** 3, 6, 9, 12, 15, 18, 20

**Key observation:** The layer config `layer_config.gd` and monster.txt define slightly different depth ranges. Monster.txt uses:
- Layer 1 Forest Breach: depths 1-3
- Layer 2 Orc Warrens: depths 3-6
- Layer 3 Torture Halls: depths 6-9
- Layer 4 Necropolis: depths 9-12
- Layer 5 Wraith Domain: depths 12-15
- Layer 6 Inner Sanctum: depths 15-18
- Layer 7 Pits of Despair: depths 18-20

The overlapping depth ranges create transition zones where monsters from two layers coexist.

---

## 2. Monster Threat Analysis by Depth

### Layer 1: Forest Breach (Depths 1-3) — POISON DANGER

| Monster | Depth | HP (dice) | Attack | Evasion | Damage | Special |
|---------|-------|-----------|--------|---------|--------|---------|
| Mirkwood Spider | 1 | 4d4 (10) | +4 | +3 | 1d6 | POISON, RES_POIS |
| Giant Rat | 1 | 2d4 (5) | +3 | +2 | 1d4 | FRIENDS |
| Black Squirrel | 1 | 1d4 (2.5) | +5 | +6 | 1d3 | SHRIEK (50%) |
| Crebain | 1 | 1d4 (2.5) | +6 | +8 | 1d4 | SHRIEK, FLYING |
| Tanglethorn | 1 | 4d4 (10) | +5 | -5 | 2d3 | POISON, NEVER_MOVE |
| Giant Bat | 2 | 2d4 (5) | +6 | +7 | 1d5 | FLYING, SHRIEK |
| Web Spinner | 2 | 5d4 (12.5) | +5 | +4 | 1d7 | POISON, THROW_WEB |
| Orc Scout | 2 | 5d4 (12.5) | +3 | +3 | 1d8 | SHRIEK (40%) |
| Swamp Adder | 2 | 2d4 (5) | +7 | +5 | 1d8 | POISON, high stealth (10) |
| Great Spider | 3 | 8d4 (20) | +8 | +6 | 2d6 | POISON, THROW_WEB |
| Warg Pup | 3 | 5d4 (12.5) | +5 | +4 | 1d6 | WOUND |
| **Broodmother** (boss) | 3 | 16d4 (40) | +10 | +5 | 2d8 | POISON, HATCH_SPIDER, SLOW |

**Key threats:**
- **Poison** is the dominant mechanic — 5 of 12 monsters deal poison damage
- **Shrieking** alerts other monsters, creating avalanche encounters
- **Web** slows the player for multi-monster ganks
- **Broodmother** spawns additional spiders and slows

**What the player needs:**
- **RES_POIS** (critical) — Poison is the #1 killer mechanic
- **Antidotes** — Available as potion at depth 2
- **Light sources** — FOV is 8, but darkness is coming

### Layer 2: Orc Warrens (Depths 3-6) — ORGANIZED ENEMIES

| Monster | Depth | HP | Attack | Evasion | Damage | Special |
|---------|-------|-----|--------|---------|--------|---------|
| Orc Slave | 3 | 4d4 | +1 | +1 | 1d6 | Weak |
| Orc Soldier | 4 | 7d4 | +4 | +4 | 2d6 | FRIENDS, 2d4 prot |
| Orc Crossbowman | 4 | 6d4 | +4 | +3 | 1d6 + CROSSBOW | Ranged at 40% |
| Warg | 5 | 8d4 | +10 | +8 | 2d5 | WOUND, fast (spd 3) |
| Orc Thrallmaster | 5 | 8d4 | +6 | +5 | 2d5 | DISARM |
| Orc Captain | 5 | 9d4 | +8 | +6 | 2d7 | ESCORT, RALLY |
| Warg Rider | 5 | 10d4 | +7 | +7 | 2d6 | CHARGE |
| Hill Troll | 6 | 14d4 | +7 | +4 | 3d6 | BATTER, KNOCK_BACK, REGEN |
| **Gashnak** (unique) | 6 | 14d4 | +14 | +12 | 2d7 | WOUND, ESCORT |
| **Orc Warchief** (boss) | 6 | 14d4 | +10 | +8 | 3d7 | RALLY, ESCORTS, 3d4 prot |

**Key threats:**
- **Organized groups** — FRIENDS/ESCORT flags mean you fight multiples
- **Crossbowmen** deal ranged damage before you close
- **Wargs** are fast (speed 3) with +10 attack — deadly
- **Hill Troll** batters and knocks back, regenerates
- **Disarm** from Thrallmasters can leave you weaponless

**What the player needs:**
- **High evasion** (dodging groups is critical)
- **Stealth** (avoiding organized patrols)
- **Good melee weapon** (2d5+ damage to handle armored orcs)
- **Ranged capability** (dealing with crossbowmen)

### Layer 3: Torture Halls (Depths 6-9) — MAGIC + STATUS EFFECTS

| Monster | Depth | HP | Attack | Evasion | Damage | Special |
|---------|-------|-----|--------|---------|--------|---------|
| Dark Acolyte | 6 | 6d4 | +5 | +5 | 1d7 | DARKNESS, SLOW (40%) |
| Ghoul | 7 | 6d4 | +8/+6 | +6 | 2d5 | ENTRANCE, RES_COLD/POIS |
| Mirk-troll | 7 | 16d4 | +9 | +6 | 3d6 | POISON, REGEN, KNOCK_BACK |
| Easterling Warrior | 7 | 9d4 | +8 | +6 | 2d7 | FLANKING |
| Werewolf | 8 | 8d8(!) | +8/+7/+7 | +8 | 2d6+1d8+1d8 | POISON, SMART, 3 attacks |
| Dark Sorcerer | 8 | 8d4 | +7 | +7 | 1d8 | DARKNESS/SLOW/SCARE/CONF (50%) |
| Easterling Champion | 8 | 11d4 | +12 | +9 | 2d8 | CHARGE |
| Ghast | 8 | 8d4 | +10/+8 | +8 | 2d6 | ENTRANCE, FRIENDS |
| **Karvag** (unique) | 9 | 20d4 | +12/+10 | +8 | 3d8 | LOSE_DEX, REGEN |
| **Master Sorcerer** (boss) | 9 | 12d4 | +10 | +10 | 2d8 | HOLD/SLOW/SCARE/CONF (60%) |

**Key threats:**
- **ENTRANCE** from ghouls/ghasts — the Sil equivalent of paralysis
- **DARKNESS** reduces visibility, making stealth harder and navigation worse
- **SLOW** halves your actions
- **CONF** causes random movement
- **HOLD** is full paralysis
- **Werewolves** have 3 attacks per round with 8d8 HP (massive for this depth)

**What the player needs:**
- **FREE_ACT** (critical) — protects against ENTRANCE, SLOW, HOLD
- **RES_FEAR** — SCARE wastes turns fleeing
- **WILL** (high) — resists magical effects
- **Fire damage** — effective vs trolls (HURT_LITE on undead)
- **LIGHT source** — counters DARKNESS spells

### Layer 4: Necropolis (Depths 9-12) — UNDEAD + STAT DRAIN

| Monster | Depth | HP | Attack | Evasion | Damage | Special |
|---------|-------|-----|--------|---------|--------|---------|
| Skeleton | 9 | 4d4 | +6 | +4 | 1d8 | MINDLESS, HURT_LITE |
| Zombie | 9 | 10d4 | +5 | +2 | 2d6 | REGEN, MINDLESS |
| Skeleton Warrior | 10 | 6d4 | +9 | +7 | 2d6 | 2d4 prot |
| Wight | 10 | 6d4 | +10 | +8 | 2d8 | **LOSE_CON**, DARKNESS, SLOW |
| Corpse-candle | 10 | 3d4 | +12 | +10 | — | **CONFUSE**, INVISIBLE, FLYING |
| Cave Troll | 10 | 18d4 | +10 | +5 | 3d7 | BATTER, KNOCK_BACK, REGEN |
| Barrow-wight | 11 | 8d4 | +12 | +10 | 2d9 | **LOSE_GRA**, DARKNESS, HOLD |
| Bone Golem | 11 | 18d4 | +10 | +4 | 3d8 | RES_CRIT, 4d4 prot |
| Necromancer Adept | 11 | 10d4 | +9 | +9 | 1d9 | DARKNESS, SLOW, SCARE |
| Corsair of Umbar | 11 | 10d4 | +10/+8 | +8 | 2d7 | WOUND, FLANKING |
| **Grishnakh** (unique) | 12 | 14d4 | +14 | +12 | 2d10 | **LOSE_STR**, DARK_AURA |

**Key threats:**
- **STAT DRAIN** appears: LOSE_CON (wights), LOSE_GRA (barrow-wights), LOSE_STR (Grishnakh)
- **INVISIBLE** enemies (corpse-candle) — can't target what you can't see
- **DARK_AURA** reduces light radius near the enemy
- **HOLD** from barrow-wights is lethal with stat drain
- **Bone Golem** has massive HP (45 avg) with 4d4 protection — hard to damage

**What the player needs:**
- **SUST_CON/GRA/STR** — stat drain is permanent without sustain
- **SEE_INVIS** — mandatory for corpse-candles and later layers
- **LIGHT** — counteracts DARKNESS and DARK_AURA
- **SLAY_UNDEAD** — critical damage multiplier vs majority of enemies
- **FREE_ACT** — even more important with HOLD in play

### Layer 5: Wraith Domain (Depths 12-15) — INVISIBLE TERRORS + ELITE MORTALS

| Monster | Depth | HP | Attack | Evasion | Damage | Special |
|---------|-------|-----|--------|---------|--------|---------|
| Phantom | 12 | 4d4 | +14 | +12 | — | TERRIFY, INVISIBLE, DIM |
| Shadow | 13 | 6d4 | +16 | +14 | 2d6 | **LOSE_STR**, INVISIBLE, PASS_DOOR |
| Whispering Shade | 13 | 5d4 | +12 | +10 | 2d5 | DARK, MULTIPLY |
| Wraith | 14 | 12d4 | +18 | +14 | 2d8 | DARK, HOLD, SLOW |
| Fell Spirit | 14 | 8d4 | +20 | +16 | — | **LOSE_GRA**, PASS_WALL, INVISIBLE |
| Spectre | 14 | 10d4 | +22/+22 | +15 | 2d10 | COLD + **LOSE_CON**, PASS_WALL |
| Vampire Thrall | 13 | 8d4 | +18/+14 | +18 | 2d5 | WOUND + **LOSE_CON** |
| B.N. Acolyte | 12 | 10d4 | +12 | +10 | 2d8 | DARKNESS, SLOW, SCARE |
| Haradrim Assassin | 13 | 9d4 | +16/+14 | +14 | 2d7 | WOUND + POISON |
| Cave Worm | 13 | 20d4 | +14/+12 | +6 | 3d8 | BATTER, REGEN |
| Oathbreaker Captain | 14 | 12d4 | +16 | +12 | 2d9 | CHARGE, ESCORT |
| Morgul Sorcerer | 14 | 10d4 | +14 | +10 | 2d8 | HOLD/SLOW/SCARE/CONF (50%) |
| **Wailing Horror** (unique) | 15 | 16d4 | +20/+18 | +16 | 3d8 | TERRIFY + HALLU, INVISIBLE |
| **Uvatha** (boss/Nazgul) | 15 | 20d4 | +22/+20 | +20 | 3d8 | WOUND + **LOSE_ALL**, 4d4 prot |

**Key threats:**
- **INVISIBLE** is now ubiquitous — Phantoms, Shadows, Fell Spirits, Wailing Horror
- **PASS_WALL/PASS_DOOR** — enemies ignore terrain, can't use corridors defensively
- **LOSE_ALL** on Uvatha drains every stat simultaneously
- **Attack bonuses exceed +20** — even high-evasion characters get hit regularly
- **Double attacks** with stat drain (Spectre: +22 COLD + +22 LOSE_CON)
- **MULTIPLY** on Whispering Shades creates exponential threat

**What the player needs:**
- **SEE_INVIS** (mandatory) — you literally cannot fight what you can't see
- **SUST_ALL** (ideal) or at minimum SUST_CON + SUST_GRA
- **RES_COLD** — spectres deal cold damage
- **RES_FEAR** — terrify effects are crippling
- **FREE_ACT** — HOLD from wraiths means death
- **LIGHT** — counters dark auras and darkness spells
- **High WILL** — to resist magical effects (sorcerers at 50-60% spell frequency)

### Layer 6: Inner Sanctum (Depths 15-18) — EVERYTHING IS DEADLY

| Monster | Depth | HP | Attack | Evasion | Damage | Special |
|---------|-------|-----|--------|---------|--------|---------|
| Black Numenorean | 15 | 12d4 | +16 | +14 | 2d9 | HOLD/SLOW/SCARE (40%), 3d4 prot |
| Olog-hai | 16 | 22d4 | +16 | +12 | **4d8** | BATTER, KNOCK_BACK, REGEN |
| Vampire | 16 | 12d4 | +24/+20 | +22 | 3d6 | WOUND + **LOSE_STR_CON** |
| Greater Wraith | 17 | 16d4 | +24/+24 | +18 | 3d8 | DARK + **LOSE_GRA**, 4d4 prot |
| Vampire Lord | 17 | 14d4 | +28/+24 | +26 | 3d7 | WOUND + **LOSE_ALL** |
| Shadow Lord | 17 | 14d4 | +26/+26 | +20 | 3d6 | **LOSE_STR** + DARK, INVISIBLE, PASS_WALL |
| Maia Thrall | 18 | 18d4 | +22 | +18 | **3d10 FIRE** | RES_FIRE |
| **Khamul** (boss/Nazgul) | 18 | 30d4 | +28/+26 | +26 | 3d10 | WOUND + **LOSE_ALL**, 5d4 prot |

**Key threats:**
- **Damage dice spike massively** — Olog-hai 4d8 (avg 18), Maia Thrall 3d10 fire (avg 16.5)
- **Attack bonuses exceed +24** — nearly unhittable evasion won't save you
- **LOSE_ALL** on Vampire Lord and Khamul means every hit drains every stat
- **Khamul** has 75 avg HP, +28 attack, 5d4 protection (12.5 avg) — a walking death sentence
- **Maia Thrall** deals **fire** damage — first fire attacker in the game

**What the player needs:**
- **RES_FIRE** (new critical need) — Maia Thralls and fire damage
- **REGEN** — stat drain is constant, need to recover
- **Massive HP pool** — CON boosting becomes survival
- **SUST_ALL** — no individual sustain is enough; everything gets drained
- **SLAY_UNDEAD** — still majority undead enemies
- **High protection dice** — incoming damage is 3d8 to 4d8 minimum

### Layer 7: Throne Room (Depths 18-20) — ESCAPE OR DIE

| Monster | Depth | HP | Attack | Evasion | Damage | Special |
|---------|-------|-----|--------|---------|--------|---------|
| Elite Olog-hai | 18 | 26d4 | +20 | +14 | **5d8** | BATTER, KNOCK_BACK, 4d4 prot |
| B.N. Lord | 18 | 16d4 | +22 | +18 | 3d9 | HOLD/SCARE/SLOW (40%), 4d4 prot |
| Greater Shadow | 19 | 12d4 | +28 | +22 | 3d6 | **LOSE_ALL**, INVISIBLE, PASS_WALL |
| Void Wraith | 19 | 18d4 | +30 | +24 | **4d8** | DARK + HUNGER, HOLD, 4d4 prot |
| Mouth of Sauron | 19 | 24d4 | +26/+24 | +22 | 3d10 | DARK + **LOSE_GRA**, HOLD/SCARE/SLOW/CONF |
| **Sauron** | 20 | **200d4** | +35/+35 | +30 | **5d12 FIRE** + **LOSE_ALL** | HOLD/SCARE/BINDING/PIERCING, 6d4 prot |

**Key threats:**
- **Sauron** is unkillable by design (500 avg HP, +35 attack, 6d4 prot)
- **HUNGER** from Void Wraith accelerates starvation
- **Greater Shadows** are invisible, pass through walls, drain all stats, and have +28 attack
- **Every monster has 4d4+ protection** — low damage weapons bounce off

**What the player needs:**
- **SPEED** — you must outrun Sauron, not fight him
- **Everything listed above, maximized** — this is the gauntlet
- **CHEAT_DEATH** — a second chance if caught
- The **Ring of Thrain** + **Key to Erebor** + **Thror's Map** (quest items)

---

## 3. Player Progression System

### Stats
- **STR** — Melee bonus = STR/2 (capped by weapon weight). Damage scaling.
- **DEX** — Evasion bonus = DEX/2. Ranged accuracy.
- **CON** — HP = 24 * 1.2^CON. Most important survival stat.
- **GRA** — Voice = 20 * 1.2^GRA. Ability resource pool.

### Skills (0-20, XP currency)
| Skill | Effect | Key Abilities |
|-------|--------|---------------|
| Melee | Attack bonus | Power, Charge, Knockback, Rapid Attack, Riposte |
| Archery | Ranged attack | Fletchery, Ambush, Crippling Shot |
| Evasion | Evasion bonus | Dodging, Sprinting, Riposte, Flanking |
| Stealth | Stealth score | Disguise, Assassination, Vanish |
| Hunting | Perception | Keen Senses, Listen, Master Hunter |
| Will | Resist magic | Strength in Adversity, Vengeance, Majesty |
| Smithing | Forge items | Weaponsmith, Armoursmith, Jeweller, Reforge, Reclaim, Masterwork |
| Lore | Voice abilities | Word of Command, Song of Elbereth, Song of Banishment |

### XP Economy
- **Starting XP:** 5,000
- **Kill XP:** max(10, depth*5 + rarity*10), 3x UNIQUE, 1.3x global multiplier
- **Descent XP:** depth * 50
- **Stealth explore XP:** 1 per newly explored tile in stealth mode
- **Stealth kill XP:** 2x base XP when monster is unwary/sleeping
- **Skill cost:** 100 * (level+1) per point, affinity discount -100/level

Example costs: Melee 1→2 = 200 XP. Melee 5→6 = 600 XP. Melee 10→11 = 1,100 XP.

### Combat Formulas
- **Hit:** d20 + attack_bonus vs d20 + evasion_bonus (attacker wins ties)
- **Damage:** weapon_dice + min(STR/2, weapon_weight/10) - protection_roll
- **Critical:** (hit_margin * 10 + 4) / (crit_threshold + weapon_weight) bonus damage dice
- **Ranged:** Same as melee but evasion halved, -1 per tile distance

---

## 4. Current Item Economy

### Base Weapons (from object.txt)

| Weapon | Depth | Dice | Attack Mod | Special |
|--------|-------|------|-----------|---------|
| Ranger's Knife | 1 | 1d5 | +0 | THROWING |
| Curved Sword | 1 | 2d4 | +1 | — |
| Sylvan Blade | 1 | 1d7 | +1 | — |
| Orc-blade | 2 | 2d5 | -1 | +1 evasion |
| Longsword | 4 | 2d5 | +0 | +1 evasion |
| Hunting Spear | 1 | 1d9 | +0 | THROWING, HAND_AND_A_HALF |
| Tower Guard Spear | 4 | 1d13 | +1 | TWO_HANDED |
| Woodsman's Axe | 2 | 4d2 | -1 | — |
| Dwarven War-axe | 4 | 3d4 | -3 | HAND_AND_A_HALF |
| Oak Staff | 1 | 2d5 | +0 | TWO_HANDED, +2 evasion |
| Rohirrim Blade | 6 | 3d3 | -2 | HAND_AND_A_HALF |
| Numenorean Blade | 4 | 3d5 | -2 | TWO_HANDED |
| Mithril Sword | 5 | 2d5 | +1 | — |
| Morgul Glaive | 8 | 2d9 | -1 | TWO_HANDED |
| Mithril Great-blade | 6 | 3d6 | -2 | TWO_HANDED |

### Base Armor

| Armor | Depth | Protection | Evasion Mod |
|-------|-------|-----------|-------------|
| Wanderer's Robe | 1 | 1d0 | +1 |
| Ranger Leathers | 1 | 1d4 | -1 |
| Scout's Armor | 2 | 1d6 | -2 |
| Shadow-steel Armor | 17 | 1d8 | -1 |
| Gondor Corslet (mail) | 5 | 2d4 | -3 |
| Dwarven Hauberk (mail) | 7 | 2d5 | -4 |
| Mithril Corslet (mail) | 7 | 2d4 | -2 |

### Rings (ego items — not artifacts)

| Ring | Depth | Effect |
|------|-------|--------|
| Endurance | 2 | +CON |
| Iron Will | 3 | RES_FEAR |
| the Watchful | 3 | +PERCEPTION |
| the Forester | 4 | +STEALTH |
| Venom's End | 6 | RES_POIS |
| Ered Luin | 8 | +WILL, RES_FEAR, RES_CONFU |
| Evasion | 8 | +2 evasion |
| Durin's Folk | 7 | +STR, RES_FIRE |
| the Greenwood | 8 | +GRA, RES_POIS |
| Protection | 7 | +1d2 protection |
| Strength | 9 | +STR, SUST_STR |
| Dexterity | 10 | +DEX, SUST_DEX |
| Free Action | 12 | FREE_ACT |
| the Shadow-ward | 12 | SEE_INVIS, RES_FEAR |
| Noldor Memory | 13 | +GRA, +WILL |

### Amulets (ego items)

| Amulet | Depth | Effect |
|--------|-------|--------|
| the Hearth | 3 | SLOW_DIGEST |
| Clear Sight | 4 | +PERCEPTION |
| Fortitude | 5 | +WILL |
| Constitution | 8 | +CON, SUST_CON |
| the Stoneheart | 8 | SUST_STR, SUST_CON |
| Starlight | 9 | LIGHT, RES_DARK |
| Grace | 10 | +GRA, SUST_GRA |
| Regeneration | 12 | REGEN |
| Haunted Dreams | 9 | HAUNTED, SEE_INVIS |
| Preservation | 14 | SUST_CON, SUST_GRA, SLOW_DIGEST |
| Lorien-light | 15 | +GRA, REGEN, LIGHT |
| the Blessed Realm | 16 | +GRA, SUST_GRA, LIGHT |

### Smithing Materials

| Material | Min Depth | Rarity | Use |
|----------|-----------|--------|-----|
| Broken Glowing Weapon | 3 | Common-ish | Reforge → enchanted weapon |
| Broken Glowing Armor | 4 | Common-ish | Reforge → enchanted armor |
| Broken Glowing Ring | 5 | Common-ish | Reforge → enchanted jewelry |
| Broken Strange Weapon | 8 | Rare | Reclaim/Masterwork → artifact weapon |
| Broken Strange Armor | 10 | Rare | Reclaim/Masterwork → artifact armor |
| Broken Strange Jewelry | 12 | Very Rare | Reclaim/Masterwork → artifact jewelry |
| Piece of Mithril | 15 | Very Rare | Create base mithril items |

---

## 5. Gap Analysis: Where Enchanted Items Are Needed

### The Scarcity → Abundance Curve

The lore demands:
- **Floors 1-6:** Mostly mundane. The outer reaches of Dol Guldur have been picked over. You find rough orc-gear and scattered elvish remnants.
- **Floors 7-12:** Transition zone. Enchanted items start appearing. Sauron's hoarded treasures begin to surface.
- **Floors 13-18:** Rich magical items. This is Sauron's armory. Artifacts are available.
- **Floors 19-20:** Legendary items. The deepest vaults contain the greatest treasures of ages.

### Critical Gap: No Enchantment System for Base Items

**Currently, the game has NO ego items / enchanted base items.** All items in object.txt are either plain base items or unique artifacts. The smithing system can "Reforge" broken materials into "enchanted items" but the actual enchantments that get applied are not defined anywhere in the codebase.

This is the **single most broken feature** in the game right now.

### Depth-by-Depth Needs vs Available Solutions

#### Floors 1-3: Early Survival
| Need | Available Solution | Gap? |
|------|-------------------|------|
| RES_POIS | Antidote potion (depth 2), Ring of Venom's End (depth 6) | **YES** — no RES_POIS items before depth 6; antidotes are consumable only |
| Better weapon (2d5+) | Orc-blade (depth 2), Longsword (depth 4) | Adequate |
| Basic protection | Ranger Leathers (depth 1), Scout's Armor (depth 2) | Adequate |

**Enchantment need:** Weapons/armor "of Poison Resistance" available depth 3-5

#### Floors 4-6: Organized Combat
| Need | Available Solution | Gap? |
|------|-------------------|------|
| Higher evasion | Evasion skill, DEX stat | Adequate via skill investment |
| Ranged option | Silvan Bow (depth 1), Longbow (depth 6) | Adequate |
| Group fighting | Crowd Fighting ability (melee 4) | Only via ability, no item support |
| Better damage | Rohirrim Blade (depth 6), war-axes | Adequate |

**Enchantment need:** Weapons "of Orc-Slaying" to handle the organized orc threat. Armor with combat bonuses.

#### Floors 7-9: Magic + Status Effects **[CRITICAL GAP]**
| Need | Available Solution | Gap? |
|------|-------------------|------|
| FREE_ACT | Ring of Free Action (depth 12!) | **CRITICAL** — 5 floors too late |
| RES_FEAR | Ring of Iron Will (depth 3), artifacts | Adequate if found early |
| High WILL | Amulet of Fortitude (depth 5), Will skill | Thin but possible |
| Counter DARKNESS | Light sources, Staff of Light | Adequate |
| Counter ENTRANCE | FREE_ACT (see above) | **CRITICAL** |

**Enchantment need:** FREE_ACT items MUST appear by depth 6-7. This is the #1 balance gap. Ghouls at depth 7 use ENTRANCE and the first FREE_ACT ring doesn't appear until depth 12.

#### Floors 10-12: Undead + Stat Drain **[CRITICAL GAP]**
| Need | Available Solution | Gap? |
|------|-------------------|------|
| SUST_CON | Amulet of Constitution (depth 8) | Barely adequate |
| SUST_GRA | Amulet of Grace (depth 10) | Just in time |
| SUST_STR | Ring of Strength (depth 9) | Just in time |
| SEE_INVIS | Amulet of Haunted Dreams (depth 9), Ring of Shadow-ward (depth 12) | **GAP** — only 2 sources, both rare |
| SLAY_UNDEAD | Only on artifacts (Sting, Narsil Shard, Westernesse, etc.) | **CRITICAL** — no craftable/common SLAY_UNDEAD |
| LIGHT | Jewel-lamp (depth 12), various light sources | Adequate |

**Enchantment need:** SLAY_UNDEAD weapons need to exist as ego items ("of Westernesse", "of the Blessed"). SEE_INVIS needs more sources. SUST_X items need to be available in more slots.

#### Floors 13-15: Wraith Domain **[CRITICAL GAP]**
| Need | Available Solution | Gap? |
|------|-------------------|------|
| SEE_INVIS | Ring of Shadow-ward (depth 12), artifacts | **THIN** — most builds won't have it |
| SUST_ALL | Multiple separate pieces needed | **IMPRACTICAL** — need 3-4 sustain items |
| RES_COLD | Ring of Warmth (depth 10), artifacts | Adequate if found |
| High WILL (14+) | Skill investment only | **GAP** — no WILL-boosting enchanted items |
| Counter PASS_WALL | Nothing | **UNSOLVABLE** — corridor-fighting strategy breaks |

**Enchantment need:** "of Wraith-Slaying" weapons, SEE_INVIS on more item types, WILL-boosting enchantments, armor "of the Blessed" with multiple sustains.

#### Floors 16-18: Inner Sanctum
| Need | Available Solution | Gap? |
|------|-------------------|------|
| RES_FIRE | Ring of Durin's Folk (depth 7), artifacts | Adequate if hoarded |
| Massive damage output | Best weapons + high melee skill | Adequate |
| Massive protection | Dwarven Hauberk 2d5, mail options | Barely adequate |
| REGEN | Amulet of Regeneration (depth 12) | Single source, rare |
| SPEED | Only on artifact boots/cloak of Rivendell (depth 18) | **CRITICAL** — SPEED arrives too late |

**Enchantment need:** REGEN needs to appear on more items. SPEED items need to exist before depth 18. Fire resistance armor.

#### Floors 19-20: Endgame
| Need | Available Solution | Gap? |
|------|-------------------|------|
| SPEED (to flee Sauron) | Artifact-only | **CRITICAL** |
| CHEAT_DEATH | Amulet of Last Chances (depth 12) | Single rare source |
| Everything above | Artifacts | Only if you found the right ones |

**Enchantment need:** By this point, the player must have assembled a complete loadout from earlier floors. The enchantment system needs to provide reliable paths to critical resistances by floor 15.

---

## 6. Bot Data Analysis (720 runs, V3)

### Death Distribution
| Floor | Deaths | % |
|-------|--------|---|
| 1 | 302 | 41.9% |
| 2 | 115 | 16.0% |
| 3 | 164 | 22.8% |
| 4 | 76 | 10.6% |
| 5 | 33 | 4.6% |
| 6 | 27 | 3.8% |
| 7 | 3 | 0.4% |

**41.9% of all runs die on Floor 1.** No bot has ever reached Floor 8.

### Per-Floor Damage Analysis
| Floor | Avg Damage Taken | Avg Kills | Visits |
|-------|-----------------|-----------|--------|
| 1 | 23.1 | 2.5 | 845 |
| 2 | 14.4 | 1.5 | 481 |
| 3 | 22.1 | 1.6 | 336 |
| 4 | 14.1 | 0.8 | 196 |
| 5 | 23.5 | 0.9 | 66 |
| 6 | 31.6 | 0.8 | 33 |
| 7 | 20.7 | 9.7 | 7 |

Damage spikes on floors 1, 3, 5, 6 — these correspond to layer transitions where tougher monsters appear.

### Archetype Performance
| Archetype | Avg Floor | Avg Kills | Notes |
|-----------|----------|-----------|-------|
| SHIELD_WALL | 3.4 | 9.9 | Best survival — evasion + protection |
| WARRIOR | 3.4 | 11.3 | Highest kill count |
| TANK | 3.2 | 14.4 | Highest kills per run, bulk survival |
| POLEARM_MASTER | 3.1 | 10.4 | Good reach weapons |
| GREENWOOD_RANGER | 2.9 | 4.7 | Stealth helps survival |
| HOBBIT_SNIPER | 1.5 | 0.7 | Worst performer — can't kill anything |
| RANGER_STEALTH_ARCHER | 1.5 | 2.1 | Ranged-only builds fail |
| HOBBIT_BURGLAR | 1.6 | 1.9 | Too squishy |

### Bot Limitations
- **Bots never use:** Songs (0%), Voice abilities (0%), Smithing (0%), most consumables
- **Bots never equip items** — 0 items equipped across all runs
- **Stuck errors:** ~80% of runs hit pathfinding traps (40+ turns wasted)
- The bot data shows **floor 1 as a massive difficulty spike** because bots fight with bare fists and no equipment

### Key Insight from Bot Data
The bot data is **not reliable for balance below floor 7** because bots don't equip items or use abilities. However, it confirms:
1. Floor 1 is brutal for underprepared characters (relevant to new players)
2. Combat-focused builds (WARRIOR, TANK, SHIELD_WALL) vastly outperform other archetypes
3. Ranged-only and pure stealth builds die very fast without equipment support
4. The damage spike at Floor 3 and 6 (layer transitions) is real

---

## 7. Summary: Enchantment Priority Matrix

### CRITICAL (game-breaking gaps)

| Enchantment | Items Needed On | Depth Available | Why Critical |
|-------------|----------------|-----------------|--------------|
| FREE_ACT | Rings, amulets, gloves | By depth 6-7 | Ghouls ENTRANCE at depth 7, current first source at depth 12 |
| SLAY_UNDEAD | Weapons (ego item) | By depth 9-10 | Necropolis is 70% undead, currently artifact-only |
| SEE_INVIS | Rings, helms, lights | By depth 10-12 | Invisible enemies from depth 10 onward, only 2 current sources |
| SPEED | Boots (ego item) | By depth 15 | Escape mechanic, currently depth 18 artifact-only |

### HIGH (severe gameplay impact)

| Enchantment | Items Needed On | Depth Available | Why |
|-------------|----------------|-----------------|-----|
| RES_POIS | Armor, rings | By depth 3 | Layer 1 is all poison, first ring source at depth 6 |
| SUST_CON | Rings, armor | By depth 9 | Stat drain starts at depth 10 |
| SUST_GRA | Amulets, cloaks | By depth 10 | Barrow-wight GRA drain at depth 11 |
| SUST_STR | Gauntlets, rings | By depth 10 | Shadow STR drain at depth 13 |
| RES_FIRE | Armor, shields | By depth 16 | Maia Thrall fire at depth 18 |
| REGEN | Armor, amulets | By depth 13 | Constant stat drain requires regeneration |
| WILL (+bonus) | Helms, amulets | Throughout | Magical effects escalate every layer |
| RES_FEAR | Helms, cloaks | By depth 6 | SCARE effects start at Dark Sorcerer (depth 8) |

### MEDIUM (significant quality of life)

| Enchantment | Items Needed On | Depth Available | Why |
|-------------|----------------|-----------------|-----|
| SLAY_ORC | Weapons | By depth 4 | Orc Warrens (depths 3-6) are all orcs |
| SLAY_SPIDER | Weapons | By depth 1-3 | Layer 1 is mostly spiders |
| BRAND_FIRE | Weapons | By depth 9 | Effective vs trolls (HURT_LITE) and undead |
| BRAND_COLD | Weapons | By depth 14 | Effective vs certain enemies |
| RES_COLD | Armor, rings | By depth 13 | Spectre cold damage |
| LIGHT | Shields, helms | Throughout | Counters darkness spells |
| PERCEPTION | Helms, cloaks | Throughout | Detection range for traps and secrets |
| STEALTH | Cloaks, boots | Throughout | Stealth builds need scaling gear |

### LOW (nice to have)

| Enchantment | Items Needed On | Why |
|-------------|----------------|-----|
| SLAY_WOLF | Weapons | Wargs are a subset of Layer 2 |
| SLAY_TROLL | Weapons | Trolls appear layers 2-4 only |
| SLAY_DRAGON | Weapons | No dragons in current monster list |
| BRAND_POIS | Weapons | Situational |
| SLOW_DIGEST | Amulets | Hunger is a soft mechanic |
| CHEAT_DEATH | Amulets | Emergency backup |
| RES_CONFU | Rings | Confusion is annoying but rarely lethal |
| RES_STUN | Rings | Stun is brief |

---

## 8. Recommended Enchantment Distribution by Depth

### Depth 1-5 (Mundane + First Enchantments)
- Weapons: "of Orc-Slaying", "of Spider-Slaying", "of Venom" (brand_pois)
- Armor: "of Resistance" (RES_POIS), "of the Forest" (+stealth)
- Shields: "of the Mark" (+RES_FEAR)

### Depth 6-9 (Magical Awakening)
- Weapons: "of Westernesse" (SLAY_UNDEAD, LIGHT), "of Flame" (BRAND_FIRE)
- Armor: "of Freedom" (FREE_ACT), "of Fortitude" (+WILL)
- Jewelry: "of Free Action", "of Warding" (RES_FEAR + RES_CONFU)
- Helms: "of Clarity" (RES_CONFU), "of Sight" (SEE_INVIS at depth 9+)

### Depth 10-14 (Sauron's Armory Opens)
- Weapons: "of the Blessed" (SLAY_UNDEAD, SLAY_ORC, LIGHT), "of Frost" (BRAND_COLD)
- Armor: "of Preservation" (SUST_CON + SUST_STR), "of Endurance" (REGEN)
- Jewelry: "of the Noldor" (SEE_INVIS, +GRA), "of Sustenance" (SUST_ALL)
- Boots: "of Swiftness" (+SPEED)
- Cloaks: "of the Shadow" (+STEALTH, SEE_INVIS)

### Depth 15-20 (Legendary Tier)
- Weapons: "of Banishment" (SLAY_UNDEAD x2), "of the West" (SLAY_ORC + SLAY_TROLL + LIGHT)
- Armor: "of the Eldar" (RES_FIRE + RES_COLD + FREE_ACT)
- Jewelry: "of Power" (all sustains), "of Mastery" (+all stats)

---

## 9. Conclusions

### The Three Most Broken Things

1. **No enchanted (ego) item system exists.** Base items have no modifiers. The smithing system can theoretically create enchanted items but the enchantments themselves are undefined. This means a player using a Longsword on floor 1 has the same Longsword on floor 15 — there's no scaling.

2. **FREE_ACT availability gap.** The first source of Free Action (the ring) appears at depth 12. Ghoul ENTRANCE attacks start at depth 7. This is a 5-floor gap where the player has NO defense against the game's paralysis mechanic.

3. **SEE_INVIS scarcity.** Only 2 non-artifact sources exist (Amulet of Haunted Dreams at depth 9, Ring of Shadow-ward at depth 12). From depth 12 onward, invisible enemies are everywhere. A player without SEE_INVIS literally cannot engage half the enemies.

### The Design Pillar: Scarcity → Abundance

The enchantment system should follow this curve:
- **Floors 1-5:** 90% mundane, 10% minor enchantments (single flag: SLAY_X, RES_X)
- **Floors 6-10:** 60% mundane, 30% minor enchanted, 10% major enchanted (2+ flags)
- **Floors 11-15:** 30% mundane, 40% enchanted, 20% major, 10% artifact
- **Floors 16-20:** 10% mundane, 30% enchanted, 30% major, 30% artifact

This matches the lore: Sauron hoards magical items. The deeper you go, the more you find from his collection.
