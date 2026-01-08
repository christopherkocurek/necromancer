# Monster Stealth Audit - The Necromancer
## MON-003: Stealth Gameplay Evaluation

---

## Evaluation Criteria

Each monster evaluated for stealth gameplay on:
1. **SLEEPING flag potential** - Can be throat-slit
2. **Patrol behavior** - Moves predictably
3. **Alert radius** - How far does it detect
4. **Pack size** - FRIENDS/ESCORT flags
5. **Vision range** - Perception stat

---

## SLEEPINESS ANALYSIS

Sleepiness determines how likely a monster is to be asleep when encountered.
Higher = more likely asleep = better stealth target.

### High Sleepiness (20+) - Excellent Stealth Targets
| Monster | Sleep | Notes |
|---------|-------|-------|
| N:21 Warg Pup | 20 | Pack animal, but sleepy |
| N:31 Orc Slave | 20 | Exhausted, easy target |
| N:34 Warg | 20 | Sleeps but keen perception |
| N:97 Vampire Thrall | 20 | Nocturnal predator |
| N:113 Vampire | 20 | Vampires sleep in torpor |
| N:115 Vampire Lord | 20 | Vampires sleep in torpor |

### Medium Sleepiness (15) - Sometimes Asleep
| Monster | Sleep | Notes |
|---------|-------|-------|
| N:11 Mirkwood Spider | 15 | Sometimes sleeping |
| N:16 Giant Bat | 15 | Roosting |
| N:20 Great Spider | 15 | Sometimes sleeping |
| N:32 Orc Soldier | 15 | Off-duty |
| N:33 Orc Archer | 15 | Off-duty |
| N:36 Orc Captain | 15 | Officers sleep |
| N:37 Warg Rider | 15 | Mounted off-duty |
| N:38 Hill Troll | 15 | Heavy sleeper |
| N:39 Gashnak | 15 | Even bosses rest |
| N:40 Orc Warchief | 15 | Even bosses rest |
| N:53 Mirk-troll | 15 | Heavy sleeper |
| N:54 Easterling Warrior | 15 | Off-duty |
| N:57 Easterling Champion | 15 | Off-duty |
| N:112 Olog-hai | 15 | Heavy sleeper |
| N:131 Elite Olog-hai | 15 | Heavy sleeper |

### Low Sleepiness (10) - Usually Awake
Most other monsters have sleepiness 10 - standard alertness.

### Very Low Sleepiness (5 or less) - Always Alert
| Monster | Sleep | Notes |
|---------|-------|-------|
| N:13 Black Squirrel | 5 | Always watching |
| N:19 Swamp Adder | 5 | Ambush predator |
| N:56 Tortured Wretch | 5 | Can't sleep |
| N:73 Zombie | 5 | Undead don't sleep |
| N:75 Corpse-candle | 5 | Always burning |
| N:78 Bone Golem | 5 | Construct |
| N:91 Phantom | 5 | Spirit |
| N:92 Shadow | 5 | Spirit |
| N:132 Greater Shadow | 5 | Spirit |
| N:135 Sauron | 5 | Never sleeps |

---

## NO_SLEEP FLAG ANALYSIS

Monsters with NO_SLEEP cannot be stealth-killed via Throat Slit.

### Cannot Be Throat-Slit
- **All Undead (z symbol):** Skeleton, Skeleton Warrior, Zombie, Ghoul, Ghast
- **All Wights (W symbol):** Wight, Barrow-wight, Greater Wraith, Void Wraith
- **All Spirits (w symbol):** Phantom, Shadow, Whispering Shade, Spectre, Fell Spirit
- **Constructs:** Bone Golem

### CAN Be Throat-Slit (Living/Vampires)
- All Spiders (M)
- All Orcs (o)
- All Trolls (T)
- All Humans (@)
- All Wolves/Wargs (C/c)
- Vampires (v) - they sleep in torpor

---

## ALARM CREATURE ANALYSIS

### Monsters with SHRIEK
| Monster | SHRIEK % | Priority |
|---------|----------|----------|
| N:13 Black Squirrel | 30% | HIGH - eliminate first |
| N:18 Orc Scout | 25% | HIGH - border patrol |
| N:14 Crebain | 20% | MEDIUM - flying, hard to reach |
| N:16 Giant Bat | 10% | LOW - only sometimes |

### Alarm Mitigation
1. Kill alarm creatures first
2. Stay out of perception range
3. Use Silent Kill ability (removes alarm)
4. Distraction to draw them away

---

## PERCEPTION ANALYSIS

Perception determines detection range. Higher = harder to sneak past.

### Very High Perception (8+) - Hard to Sneak
| Monster | Perception | Notes |
|---------|------------|-------|
| N:60 Master Sorcerer | 8 | Boss - expected |
| N:99 Uvatha | 15 | Nazgul - expected |
| N:118 Khamul | 18 | Nazgul - expected |
| N:135 Sauron | 20 | Final boss |
| N:132 Greater Shadow | 14 | Very perceptive |
| N:133 Void Wraith | 16 | Very perceptive |

### High Perception (6-7) - Challenging
| Monster | Perception | Notes |
|---------|------------|-------|
| N:14 Crebain | 6 | Spy birds |
| N:22 Broodmother | 6 | Boss |
| N:55 Dark Sorcerer | 6 | Caster |
| N:39 Gashnak | 7 | Unique |

### Standard Perception (3-5) - Normal Stealth
Most monsters have perception 3-5.

### Low Perception (1-2) - Easy Stealth
| Monster | Perception | Notes |
|---------|------------|-------|
| N:31 Orc Slave | 1 | Too tired to notice |
| N:38 Hill Troll | 2 | Stupid |
| N:73 Zombie | 1 | Mindless |
| N:12 Giant Rat | 2 | Simple vermin |
| N:19 Swamp Adder | 2 | Relies on ambush |
| N:56 Tortured Wretch | 2 | Mad |

---

## PACK BEHAVIOR ANALYSIS

### FRIENDS Flag (Spawns with Others)
Most orcs, wargs, skeletons, zombies, ghouls, phantoms, spectres.
- Creates group encounters
- Eliminating one may alert others
- Need Silent Kill for pack stealth

### ESCORT/ESCORTS Flags (Has Bodyguards)
| Monster | Flag | Notes |
|---------|------|-------|
| N:36 Orc Captain | ESCORT | Has soldiers |
| N:39 Gashnak | ESCORT | Has wargs |
| N:40 Orc Warchief | ESCORTS | Many soldiers |
| N:60 Master Sorcerer | ESCORT | Has acolytes |
| N:79 Grishnakh | ESCORT | Has wights |
| N:99 Uvatha | ESCORT | Has wraiths |
| N:118 Khamul | ESCORTS | Full guard |

### Solo Monsters (No Pack Flags)
Best assassination targets:
- N:20 Great Spider (TERRITORIAL only)
- N:35 Orc Thrallmaster (TERRITORIAL)
- N:55 Dark Sorcerer (solo caster)
- N:57 Easterling Champion (solo elite)
- N:74 Wight (TERRITORIAL)
- N:77 Barrow-wight (TERRITORIAL)
- N:111 Black Numenorean (solo)

---

## STEALTH SCENARIO RATINGS

### Excellent Stealth Scenarios (5/5)
| Scenario | Monsters | Why |
|----------|----------|-----|
| Sleeping Barracks | Orc Slaves | High sleep, low perception |
| Vampire Crypt | Vampires | High sleep, can throat-slit |
| Warg Den | Warg Pups | High sleep, but pack alerts |
| Orc Captain's Quarters | Captain sleeping | High value target |

### Good Stealth Scenarios (4/5)
| Scenario | Monsters | Why |
|----------|----------|-----|
| Spider Nest | Spiders | Medium sleep, territorial |
| Troll Pen | Trolls | High sleep, low perception |
| Necromancer's Lab | Necromancer alone | Solo caster, high value |
| Easterling Barracks | Warriors | Medium sleep |

### Challenging Stealth (3/5)
| Scenario | Monsters | Why |
|----------|----------|-----|
| Warg Kennels | Wargs | High sleep BUT high perception |
| Crypt Hall | Wights | Intelligent, NO_SLEEP |
| Dark Chapel | Sorcerer | High perception caster |

### Poor Stealth (2/5)
| Scenario | Monsters | Why |
|----------|----------|-----|
| Ghoul Pit | Ghouls | NO_SLEEP, pack |
| Shadow Hall | Shadows | Invisible, NO_SLEEP |
| Skeleton Barracks | Skeletons | NO_SLEEP, mindless |

### Impossible Stealth (1/5)
| Scenario | Monsters | Why |
|----------|----------|-----|
| Uvatha's Hall | Uvatha + escorts | Nazgul perception |
| Khamul's Throne | Khamul + escorts | Nazgul perception |
| Sauron's Throne | Sauron | Cannot be avoided |

---

## RECOMMENDATIONS

### Add SLEEPING Flag Explicitly
Consider adding explicit SLEEPING flag to:
- Some orc soldiers in barracks
- Some wargs in kennels
- Vampires in crypts
- Trolls in pens

### Create "Sleeper" Variants
- "Sleeping Orc" - guaranteed asleep
- "Torpid Vampire" - always in torpor
- "Resting Warg" - pack but sleeping

### Reduce Perception on Some
- Orc Soldiers (4->3) for easier stealth
- Hill Trolls (2->1) - very stupid

### Add Patrol Monsters
- "Orc Patrol" - moves on set path
- "Warg Sentry" - guards specific area

---

## SUMMARY

### Stealth-Friendly Monsters
1. Orc Slaves (sleep 20, perception 1)
2. Vampires (sleep 20, can throat-slit)
3. Trolls (sleep 15, perception 2)
4. Warg Pups (sleep 20, but pack warns)

### Stealth-Hostile Monsters
1. All undead (NO_SLEEP)
2. Nazgul (extreme perception)
3. Shadows (invisible + NO_SLEEP)
4. Alarm creatures (SHRIEK)

### Layer Stealth Difficulty
| Layer | Difficulty | Reason |
|-------|------------|--------|
| 1 | Easy | Mostly animals, some sleepers |
| 2 | Medium | Organized orcs, wargs |
| 3 | Medium | Sorcerers, ghouls |
| 4 | Hard | Undead don't sleep |
| 5 | Very Hard | Spirits don't sleep |
| 6 | Very Hard | Elite enemies |
| 7 | Extreme | Sauron, elite guards |
