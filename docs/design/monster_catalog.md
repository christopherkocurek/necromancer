# Monster Catalog - The Necromancer
## MON-001: Complete Monster Extraction

---

## File Format Reference (lib/edit/monster.txt)

```
N:<id>:<name>                              - Monster ID and display name
W:<depth>:<rarity>                         - Native depth, rarity (1=common)
G:<symbol>:<color>                         - Display symbol and color
I:<speed>:<health_dice>:<light_radius>     - Speed, HP dice, light
A:<sleepiness>:<perception>:<stealth>:<will> - AI/defense stats
P:[<evasion>,<protection_dice>]            - Defense values
B:<method>:<effect>:(<bonus>,<damage_dice>) - Attack
S:<frequency> | <power>                    - Spell info
S:<spell_list>                             - Spell types
F:<flags>                                  - Monster flags
D:<text>                                   - Description
```

---

## LAYER 1: FOREST BREACH (Depths 1-3, 50-150ft)

### N:11 - Mirkwood Spider
| Stat | Value |
|------|-------|
| Depth/Rarity | 1/1 (common) |
| Symbol | M (umber) |
| Speed | 2 | HP | 4d4 (~10) |
| Sleepiness | 15 | Perception | 3 | Stealth | 6 | Will | 2 |
| Evasion | +3 | Protection | 1d4 |
| Attack | BITE:POISON:(+4,1d6) |
| Flags | SPIDER, TERRITORIAL, FRIENDS, RES_POIS |
| **Stealth Notes** | Medium sleep, pack behavior, can ambush |

### N:12 - Giant Rat
| Stat | Value |
|------|-------|
| Depth/Rarity | 1/1 (common) |
| Symbol | r (umber) |
| Speed | 3 | HP | 2d4 (~5) |
| Sleepiness | 10 | Perception | 2 | Stealth | 5 | Will | 1 |
| Evasion | +2 | Protection | - |
| Attack | BITE:HURT:(+3,1d4) |
| Flags | FRIENDS, RAND_25, TERRITORIAL |
| **Stealth Notes** | Low sleep, random movement, nuisance |

### N:13 - Black Squirrel
| Stat | Value |
|------|-------|
| Depth/Rarity | 1/2 |
| Symbol | r (dark) |
| Speed | 4 | HP | 1d4 (~2) |
| Sleepiness | 5 | Perception | 4 | Stealth | 8 | Will | 1 |
| Evasion | +6 | Protection | - |
| Attack | BITE:HURT:(+5,1d3) |
| Spells | 30% SHRIEK |
| Flags | RAND_50, TERRITORIAL |
| **Stealth Notes** | ALARM CREATURE - priority target, low sleep |

### N:14 - Crebain
| Stat | Value |
|------|-------|
| Depth/Rarity | 1/2 |
| Symbol | b (dark) |
| Speed | 4 | HP | 1d4 (~2) |
| Sleepiness | 10 | Perception | 6 | Stealth | 4 | Will | 2 |
| Evasion | +8 | Protection | - |
| Attack | PECK:HURT:(+6,1d4) |
| Spells | 20% SHRIEK |
| Flags | FLYING, RAND_25, FRIENDS |
| **Stealth Notes** | ALARM CREATURE - flying makes hard to reach |

### N:15 - Tanglethorn
| Stat | Value |
|------|-------|
| Depth/Rarity | 1/1 (common) |
| Symbol | & (green) |
| Speed | 2 | HP | 4d4 (~10) |
| Sleepiness | 0 | Perception | 0 | Stealth | 0 | Will | 0 |
| Evasion | -5 | Protection | 1d4 |
| Attack | THORN:POISON:(+5,2d3) |
| Flags | NEVER_MOVE, MINDLESS, FRIEND, HURT_FIRE, NO_FEAR, RES_POIS, NO_CONF, NO_SLEEP, NO_CRIT |
| **Stealth Notes** | Static hazard - can be avoided, doesn't detect |

### N:16 - Giant Bat
| Stat | Value |
|------|-------|
| Depth/Rarity | 2/1 (common) |
| Symbol | b (slate) |
| Speed | 4 | HP | 2d4 (~5) |
| Sleepiness | 15 | Perception | 4 | Stealth | 4 | Will | 1 |
| Evasion | +7 | Protection | 1d4 |
| Attack | BITE:HURT:(+6,1d5) |
| Spells | 10% SHRIEK |
| Flags | FLYING, RAND_50, TERRITORIAL |
| **Stealth Notes** | ALARM CREATURE - medium sleep potential |

### N:17 - Web Spinner
| Stat | Value |
|------|-------|
| Depth/Rarity | 2/2 |
| Symbol | M (white) |
| Speed | 2 | HP | 5d4 (~12) |
| Sleepiness | 10 | Perception | 4 | Stealth | 7 | Will | 2 |
| Evasion | +4 | Protection | 1d4 |
| Attack | BITE:POISON:(+5,1d7) |
| Spells | 10% POW_4 THROW_WEB |
| Flags | SPIDER, TERRITORIAL, RES_POIS |
| **Stealth Notes** | Creates webs, territorial - guards area |

### N:18 - Orc Scout
| Stat | Value |
|------|-------|
| Depth/Rarity | 2/1 (common) |
| Symbol | o (dark) |
| Speed | 2 | HP | 5d4 (~12) |
| Sleepiness | 10 | Perception | 5 | Stealth | 6 | Will | 2 |
| Evasion | +3 | Protection | 1d4 |
| Attack | HIT:HURT:(+3,1d8) |
| Spells | 25% SHRIEK |
| Flags | MALE, DROP_33, OPEN_DOOR, ORC, HURT_LITE, SMART |
| **Stealth Notes** | ALARM CREATURE - intelligent, opens doors |

### N:19 - Swamp Adder
| Stat | Value |
|------|-------|
| Depth/Rarity | 2/3 |
| Symbol | s (green) |
| Speed | 2 | HP | 2d4 (~5) |
| Sleepiness | 5 | Perception | 2 | Stealth | 10 | Will | 2 |
| Evasion | +5 | Protection | 2d4 |
| Attack | BITE:POISON:(+7,1d8) |
| Flags | SERPENT, RAND_25, RES_POIS |
| **Stealth Notes** | High stealth itself, low sleep - ambush predator |

### N:20 - Great Spider
| Stat | Value |
|------|-------|
| Depth/Rarity | 3/2 |
| Symbol | M (dark) |
| Speed | 2 | HP | 8d4 (~20) |
| Sleepiness | 15 | Perception | 5 | Stealth | 5 | Will | 3 |
| Evasion | +6 | Protection | 1d4 |
| Attack | BITE:POISON:(+8,2d6) |
| Spells | 15% POW_6 THROW_WEB |
| Flags | SPIDER, TERRITORIAL, RES_POIS |
| **Stealth Notes** | Larger spider, webs, good assassination target |

### N:21 - Warg Pup
| Stat | Value |
|------|-------|
| Depth/Rarity | 3/1 (common) |
| Symbol | C (umber) |
| Speed | 3 | HP | 5d4 (~12) |
| Sleepiness | 20 | Perception | 3 | Stealth | 4 | Will | 2 |
| Evasion | +4 | Protection | 1d4 |
| Attack | BITE:WOUND:(+5,1d6) |
| Flags | FRIENDS, RAND_25, WOLF |
| **Stealth Notes** | HIGH SLEEP - excellent stealth target, pack warns |

### N:22 - Broodmother (BOSS)
| Stat | Value |
|------|-------|
| Depth/Rarity | 3/6 |
| Symbol | M (green) |
| Speed | 1 | HP | 16d4 (~40) |
| Sleepiness | 10 | Perception | 6 | Stealth | 2 | Will | 4 |
| Evasion | +5 | Protection | 2d4 |
| Attack | BITE:POISON:(+10,2d8) |
| Spells | 20% POW_8 HATCH_SPIDER, SLOW |
| Flags | SPIDER, TERRITORIAL, RES_POIS, FEMALE |
| **Stealth Notes** | LAYER 1 BOSS - spawns spiders, slow |

---

## LAYER 2: ORC WARRENS (Depths 3-6, 150-300ft)

### N:31 - Orc Slave
| Stat | Value |
|------|-------|
| Depth/Rarity | 3/1 (common) |
| Symbol | o (slate) |
| Speed | 2 | HP | 4d4 (~10) |
| Sleepiness | 20 | Perception | 1 | Stealth | 1 | Will | 1 |
| Evasion | +1 | Protection | 1d4 |
| Attack | HIT:HURT:(+1,1d6) |
| Flags | MALE, ORC, HURT_LITE |
| **Stealth Notes** | HIGH SLEEP - exhausted, easy stealth |

### N:32 - Orc Soldier
| Stat | Value |
|------|-------|
| Depth/Rarity | 4/1 (common) |
| Symbol | o (white) |
| Speed | 2 | HP | 7d4 (~17) |
| Sleepiness | 15 | Perception | 2 | Stealth | 2 | Will | 3 |
| Evasion | +4 | Protection | 2d4 |
| Attack | HIT:HURT:(+4,2d6) |
| Flags | MALE, FRIENDS, DROP_33, OPEN_DOOR, BASH_DOOR, ORC, HURT_LITE, SMART |
| **Stealth Notes** | Medium sleep, pack fighter, doors |

### N:33 - Orc Archer
| Stat | Value |
|------|-------|
| Depth/Rarity | 4/2 |
| Symbol | o (umber) |
| Speed | 2 | HP | 6d4 (~15) |
| Sleepiness | 15 | Perception | 3 | Stealth | 3 | Will | 3 |
| Evasion | +3 | Protection | 1d4 |
| Attack | HIT:HURT:(+4,1d6) |
| Spells | 75% POW_6 ARROW1 |
| Flags | MALE, FRIENDS, DROP_33, OPEN_DOOR, ORC, HURT_LITE, SMART |
| **Stealth Notes** | Ranged threat, priority target |

### N:34 - Warg
| Stat | Value |
|------|-------|
| Depth/Rarity | 5/1 (common) |
| Symbol | C (slate) |
| Speed | 3 | HP | 8d4 (~20) |
| Sleepiness | 20 | Perception | 5 | Stealth | 4 | Will | 4 |
| Evasion | +8 | Protection | 1d4 |
| Attack | BITE:WOUND:(+10,2d5) |
| Flags | FRIENDS, RAND_25, BASH_DOOR, WOLF, SMART |
| **Stealth Notes** | HIGH SLEEP but high perception - tricky |

### N:35 - Orc Thrallmaster
| Stat | Value |
|------|-------|
| Depth/Rarity | 5/3 |
| Symbol | o (red) |
| Speed | 2 | HP | 8d4 (~20) |
| Sleepiness | 10 | Perception | 4 | Stealth | 3 | Will | 4 |
| Evasion | +5 | Protection | 2d4 |
| Attack | HIT:HURT:(+6,2d5), WHIP:DISARM:(+4,1d4) |
| Flags | MALE, DROP_100, OPEN_DOOR, BASH_DOOR, ORC, HURT_LITE, SMART, UNLOCK_DOOR, TERRITORIAL |
| **Stealth Notes** | Assassination target - controls slaves |

### N:36 - Orc Captain
| Stat | Value |
|------|-------|
| Depth/Rarity | 5/2 |
| Symbol | o (red) |
| Speed | 2 | HP | 9d4 (~22) |
| Sleepiness | 15 | Perception | 4 | Stealth | 2 | Will | 5 |
| Evasion | +6 | Protection | 2d4 |
| Attack | HIT:HURT:(+8,2d7) |
| Spells | 10% POW_8 RALLY |
| Flags | MALE, ESCORT, DROP_100, OPEN_DOOR, BASH_DOOR, ORC, HURT_LITE, SMART, UNLOCK_DOOR |
| **Stealth Notes** | High-value target, has escorts |

### N:37 - Warg Rider
| Stat | Value |
|------|-------|
| Depth/Rarity | 5/3 |
| Symbol | o (dark) |
| Speed | 3 | HP | 10d4 (~25) |
| Sleepiness | 15 | Perception | 5 | Stealth | 3 | Will | 4 |
| Evasion | +7 | Protection | 2d4 |
| Attack | HIT:HURT:(+7,2d6) |
| Flags | MALE, DROP_33, OPEN_DOOR, BASH_DOOR, ORC, HURT_LITE, SMART, CHARGE |
| **Stealth Notes** | Fast, charges, hard to sneak past |

### N:38 - Hill Troll
| Stat | Value |
|------|-------|
| Depth/Rarity | 6/2 |
| Symbol | T (white) |
| Speed | 2 | HP | 14d4 (~35) |
| Sleepiness | 15 | Perception | 2 | Stealth | 0 | Will | 3 |
| Evasion | +4 | Protection | 2d4 |
| Attack | HIT:BATTER:(+7,3d6) |
| Flags | MALE, FRIEND, DROP_33, REGENERATE, OPEN_DOOR, BASH_DOOR, TROLL, HURT_LITE, SMART, NO_FEAR, KNOCK_BACK |
| **Stealth Notes** | Heavy hitter, regenerates, hurt by light |

### N:39 - Gashnak, Warg-lord (UNIQUE)
| Stat | Value |
|------|-------|
| Depth/Rarity | 6/10 |
| Symbol | C (white) |
| Speed | 3 | HP | 14d4 (~35) |
| Sleepiness | 15 | Perception | 7 | Stealth | 4 | Will | 6 |
| Evasion | +12 | Protection | 2d4 |
| Attack | BITE:WOUND:(+14,2d7) |
| Flags | UNIQUE, MALE, ESCORT, WOLF, SMART, DROP_100, DROP_GOOD, BASH_DOOR |
| **Stealth Notes** | LAYER 2 UNIQUE - high perception, escorts |

### N:40 - Orc Warchief (BOSS)
| Stat | Value |
|------|-------|
| Depth/Rarity | 6/6 |
| Symbol | o (red bright) |
| Speed | 2 | HP | 14d4 (~35) |
| Sleepiness | 15 | Perception | 5 | Stealth | 2 | Will | 7 |
| Evasion | +8 | Protection | 3d4 |
| Attack | HIT:HURT:(+10,3d7) |
| Spells | 10% POW_12 RALLY |
| Flags | UNIQUE, MALE, ESCORTS, SMART, DROP_100, DROP_GOOD, OPEN_DOOR, BASH_DOOR, ORC, HURT_LITE, UNLOCK_DOOR |
| **Stealth Notes** | LAYER 2 BOSS - many escorts |

---

## LAYER 3: TORTURE HALLS (Depths 6-9, 300-450ft)

### N:51 - Dark Acolyte
| Stat | Value |
|------|-------|
| Depth/Rarity | 6/2 |
| Symbol | @ (violet) |
| Speed | 2 | HP | 6d4 (~15) |
| Sleepiness | 10 | Perception | 4 | Stealth | 4 | Will | 6 |
| Evasion | +5 | Protection | 1d4 |
| Attack | HIT:HURT:(+5,1d7) |
| Spells | 40% POW_6 DARKNESS, SLOW |
| Flags | MAN, MALE, DROP_33, OPEN_DOOR, SMART |
| **Stealth Notes** | Caster, casts darkness/slow |

### N:52 - Ghoul
| Stat | Value |
|------|-------|
| Depth/Rarity | 7/1 (common) |
| Symbol | z (slate) |
| Speed | 2 | HP | 6d4 (~15) |
| Sleepiness | 10 | Perception | 4 | Stealth | 5 | Will | 5 |
| Evasion | +6 | Protection | 2d4 |
| Attack | CLAW:HURT:(+8,2d5), BITE:ENTRANCE:(+6,1d8) |
| Flags | UNDEAD, RES_COLD, RES_POIS, NO_FEAR, NO_CONF, NO_SLEEP, HURT_LITE |
| **Stealth Notes** | NO_SLEEP - can't be throat-slit, mindless |

### N:53 - Mirk-troll
| Stat | Value |
|------|-------|
| Depth/Rarity | 7/1 (common) |
| Symbol | T (dark) |
| Speed | 2 | HP | 16d4 (~40) |
| Sleepiness | 15 | Perception | 3 | Stealth | 1 | Will | 4 |
| Evasion | +6 | Protection | 2d4 |
| Attack | HIT:POISON:(+9,3d6) |
| Flags | MALE, FRIEND, DROP_33, REGENERATE, OPEN_DOOR, BASH_DOOR, TROLL, SMART, NO_FEAR, KNOCK_BACK |
| **Stealth Notes** | Poison troll, doesn't fear light |

### N:54 - Easterling Warrior
| Stat | Value |
|------|-------|
| Depth/Rarity | 7/2 |
| Symbol | @ (umber) |
| Speed | 2 | HP | 9d4 (~22) |
| Sleepiness | 15 | Perception | 4 | Stealth | 2 | Will | 6 |
| Evasion | +6 | Protection | 3d4 |
| Attack | HIT:HURT:(+8,2d7) |
| Flags | MAN, MALE, DROP_33, OPEN_DOOR, BASH_DOOR, FRIENDS, SMART, FLANKING |
| **Stealth Notes** | Disciplined fighter, flanks |

### N:55 - Dark Sorcerer
| Stat | Value |
|------|-------|
| Depth/Rarity | 8/3 |
| Symbol | @ (dark) |
| Speed | 2 | HP | 8d4 (~20) |
| Sleepiness | 10 | Perception | 6 | Stealth | 5 | Will | 9 |
| Evasion | +7 | Protection | 1d4 |
| Attack | HIT:DARK:(+7,1d8) |
| Spells | 50% POW_10 DARKNESS, SLOW, SCARE, CONF |
| Flags | MAN, MALE, DROP_100, OPEN_DOOR, UNLOCK_DOOR, SMART |
| **Stealth Notes** | HIGH PRIORITY TARGET - control caster |

### N:56 - Tortured Wretch
| Stat | Value |
|------|-------|
| Depth/Rarity | 7/4 |
| Symbol | @ (slate) |
| Speed | 1 | HP | 4d4 (~10) |
| Sleepiness | 5 | Perception | 2 | Stealth | 2 | Will | 2 |
| Evasion | +2 | Protection | - |
| Attack | CLAW:HURT:(+4,1d6) |
| Flags | MAN, RAND_50, NO_FEAR |
| **Stealth Notes** | Mad prisoner, erratic, low threat |

### N:57 - Easterling Champion
| Stat | Value |
|------|-------|
| Depth/Rarity | 8/3 |
| Symbol | @ (orange) |
| Speed | 2 | HP | 11d4 (~27) |
| Sleepiness | 15 | Perception | 5 | Stealth | 2 | Will | 8 |
| Evasion | +9 | Protection | 3d4 |
| Attack | HIT:HURT:(+12,2d8) |
| Flags | MAN, MALE, DROP_100, OPEN_DOOR, BASH_DOOR, SMART, CHARGE |
| **Stealth Notes** | Elite warrior, assassination target |

### N:58 - Ghast
| Stat | Value |
|------|-------|
| Depth/Rarity | 8/2 |
| Symbol | z (green) |
| Speed | 2 | HP | 8d4 (~20) |
| Sleepiness | 10 | Perception | 5 | Stealth | 4 | Will | 6 |
| Evasion | +8 | Protection | 2d4 |
| Attack | CLAW:HURT:(+10,2d6), BITE:ENTRANCE:(+8,2d6) |
| Flags | UNDEAD, RES_COLD, RES_POIS, NO_FEAR, FRIENDS, NO_CONF, NO_SLEEP, HURT_LITE |
| **Stealth Notes** | NO_SLEEP - stronger ghoul |

### N:59 - Karvag the Torturer (UNIQUE)
| Stat | Value |
|------|-------|
| Depth/Rarity | 9/10 |
| Symbol | T (red) |
| Speed | 2 | HP | 20d4 (~50) |
| Sleepiness | 10 | Perception | 5 | Stealth | 1 | Will | 7 |
| Evasion | +8 | Protection | 3d4 |
| Attack | HIT:HURT:(+12,3d8), CLAW:LOSE_DEX:(+10,2d6) |
| Flags | UNIQUE, MALE, TROLL, REGENERATE, NO_FEAR, DROP_100, DROP_GOOD, OPEN_DOOR, BASH_DOOR, SMART |
| **Stealth Notes** | LAYER 3 UNIQUE - stat drain |

### N:60 - Master Sorcerer (BOSS)
| Stat | Value |
|------|-------|
| Depth/Rarity | 9/6 |
| Symbol | @ (violet bright) |
| Speed | 2 | HP | 12d4 (~30) |
| Sleepiness | 10 | Perception | 8 | Stealth | 5 | Will | 12 |
| Evasion | +10 | Protection | 2d4 |
| Attack | HIT:DARK:(+10,2d8) |
| Spells | 60% POW_14 DARKNESS, SLOW, HOLD, SCARE, CONF |
| Flags | UNIQUE, MALE, SMART, ESCORT, DROP_100, DROP_GREAT, OPEN_DOOR, UNLOCK_DOOR |
| **Stealth Notes** | LAYER 3 BOSS - HOLD spell is dangerous |

---

## LAYERS 4-7: Summary Tables

(Full details available in monster.txt)

### Layer 4: Necropolis (Depths 9-12)
| ID | Name | HP | Sleep | Flags |
|----|------|----|----|-------|
| 71 | Skeleton | 4d4 | 10 | MINDLESS, NO_SLEEP |
| 72 | Skeleton Warrior | 6d4 | 10 | NO_SLEEP |
| 73 | Zombie | 10d4 | 5 | MINDLESS, NO_SLEEP, REGENERATE |
| 74 | Wight | 6d4 | 10 | SMART, NO_SLEEP |
| 75 | Corpse-candle | 3d4 | 5 | INVISIBLE, NO_SLEEP |
| 76 | Necromancer Adept | 10d4 | 10 | SMART, caster |
| 77 | Barrow-wight | 8d4 | 10 | SMART, NO_SLEEP |
| 78 | Bone Golem | 18d4 | 5 | MINDLESS, NO_SLEEP |
| 79 | Grishnakh (BOSS) | 14d4 | 10 | UNIQUE, ESCORT |

### Layer 5: Wraith Domain (Depths 12-15)
| ID | Name | HP | Sleep | Flags |
|----|------|----|----|-------|
| 91 | Phantom | 4d4 | 5 | INVISIBLE, NO_SLEEP |
| 92 | Shadow | 6d4 | 5 | INVISIBLE, NO_SLEEP |
| 93 | Whispering Shade | 5d4 | 10 | MULTIPLY, NO_SLEEP |
| 94 | Wraith | 12d4 | 10 | SMART, NO_SLEEP |
| 95 | Fell Spirit | 8d4 | 10 | INVISIBLE, PASS_WALL |
| 96 | Spectre | 10d4 | 10 | PASS_WALL, NO_SLEEP |
| 97 | Vampire Thrall | 8d4 | 20 | FLYING, SMART |
| 98 | Wailing Horror (UNIQUE) | 16d4 | 5 | INVISIBLE |
| 99 | Uvatha (BOSS) | 20d4 | 10 | NAZGUL |

### Layer 6: Inner Sanctum (Depths 15-18)
| ID | Name | HP | Sleep | Flags |
|----|------|----|----|-------|
| 111 | Black Numenorean | 12d4 | 10 | SMART, caster |
| 112 | Olog-hai | 22d4 | 15 | NO_FEAR |
| 113 | Vampire | 12d4 | 20 | FLYING, SMART |
| 114 | Greater Wraith | 16d4 | 10 | NO_SLEEP |
| 115 | Vampire Lord | 14d4 | 20 | FLYING, SMART |
| 116 | Shadow Lord | 14d4 | 10 | INVISIBLE, NO_SLEEP |
| 117 | Maia Thrall | 18d4 | 10 | RES_FIRE |
| 118 | Khamul (BOSS) | 30d4 | 10 | NAZGUL |

### Layer 7: Pits of Despair (Depths 18-20)
| ID | Name | HP | Sleep | Flags |
|----|------|----|----|-------|
| 131 | Elite Olog-hai | 26d4 | 15 | NO_FEAR |
| 132 | Greater Shadow | 12d4 | 5 | INVISIBLE, NO_SLEEP |
| 133 | Void Wraith | 18d4 | 10 | NO_SLEEP |
| 134 | Thrain's Shade | 1d4 | 0 | PEACEFUL |
| 135 | Sauron (BOSS) | 200d4 | 5 | QUESTOR |

---

## STEALTH-RELEVANT SUMMARY

### High Sleepiness (20+) - Good Stealth Targets
- N:21 Warg Pup (20)
- N:31 Orc Slave (20)
- N:34 Warg (20)
- N:97 Vampire Thrall (20)
- N:113 Vampire (20)
- N:115 Vampire Lord (20)

### Alarm Creatures (SHRIEK)
- N:13 Black Squirrel (30%)
- N:14 Crebain (20%)
- N:16 Giant Bat (10%)
- N:18 Orc Scout (25%)

### Cannot be Stealth-Killed (NO_SLEEP)
- All undead except vampires
- All spectral creatures

### Good Assassination Targets (High Value)
- N:35 Orc Thrallmaster (controls slaves)
- N:36 Orc Captain (has RALLY)
- N:55 Dark Sorcerer (control caster)
- N:57 Easterling Champion (elite)
- N:76 Necromancer Adept (raises dead)
- N:111 Black Numenorean (warrior-sorcerer)
