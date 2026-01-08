# Monster Archetype Gaps - The Necromancer
## MON-004: Missing Monster Types for Stealth Gameplay

---

## Stealth-First Design Requirements

From the GDD and PRD, the game needs monsters that support:
1. **Patrol behavior** - Predictable movement for timing
2. **Sleeping variants** - Throat-slit opportunities
3. **Handler mechanics** - Kill handler to control beasts
4. **Alarm specialists** - Clear priority targets
5. **Solo elites** - Worth assassinating
6. **Distraction-vulnerable** - Can be lured away

---

## MISSING ARCHETYPE: PATROL MONSTERS

### Current State
No monsters have explicit patrol behavior. TERRITORIAL flag makes them guard an area but not move predictably.

### Needed
- **Orc Patrol** - Walks a set route, turns back at endpoints
- **Warg Sentry** - Circles a perimeter
- **Undead Guard** - Slow, methodical patrol

### Design Notes
Patrol behavior would need code support for:
- Waypoint movement
- Turn-around at endpoints
- Detection while moving

---

## MISSING ARCHETYPE: SLEEPING VARIANTS

### Current State
Sleepiness stat determines sleep chance, but no guaranteed sleepers.

### Needed
| Monster | Concept | Layer |
|---------|---------|-------|
| Sleeping Orc | Always asleep, easy kill | 2 |
| Torpid Vampire | Guaranteed torpor | 5-6 |
| Exhausted Slave | Too tired to wake | 2-3 |
| Napping Troll | Heavy sleeper | 2-3 |
| Resting Warg | Asleep in den | 1-2 |

### Design Notes
Could add SLEEPING flag that makes monster start asleep.

---

## MISSING ARCHETYPE: HANDLER-BEAST PAIRS

### Current State
Warg Riders exist (orc+warg combo) but no handler mechanics.

### Needed
| Handler | Beast | Mechanic |
|---------|-------|----------|
| Warg Handler | 2-3 Wargs | Kill handler = wargs flee |
| Spider Keeper | Great Spider | Kill keeper = spider calms |
| Troll Driver | Hill Troll | Kill driver = troll rampages |
| Ghoul Master | 3-4 Ghouls | Kill master = ghouls become passive |

### Design Notes
Would need code for:
- Handler death triggers beast AI change
- Beast becomes passive, fleeing, or berserk

---

## MISSING ARCHETYPE: DEDICATED ALARM CREATURES

### Current State
Several monsters have SHRIEK spell (10-30% use rate).

### Needed
| Monster | Concept | Layer |
|---------|---------|-------|
| Watch-crow | 100% SHRIEK, no attack, flees | 1-2 |
| Alarm Spider | Web-alarm that alerts others | 1 |
| Signal Orc | Blows horn, then fights | 2 |
| Warning Bell | Static trap that alerts | All |

### Design Notes
Pure alarm creatures should:
- Have 100% SHRIEK rate
- Low/no combat ability
- High priority for stealth players

---

## MISSING ARCHETYPE: DISTRACTION-VULNERABLE

### Current State
No explicit distraction mechanics.

### Needed
| Monster | Distraction | Layer |
|---------|-------------|-------|
| Greedy Orc | Lured by thrown gold | 2 |
| Hungry Warg | Lured by meat | 2 |
| Curious Spider | Investigates sounds | 1 |
| Distracted Guard | Watching something else | 2-3 |

### Design Notes
Would need code for:
- Item throwing to create distraction
- Noise generation ability
- Monster investigation AI

---

## MISSING ARCHETYPE: LIGHT-SENSITIVE

### Current State
HURT_LITE flag exists but isn't heavily used for stealth.

### Needed
| Monster | Light Behavior | Layer |
|---------|----------------|-------|
| Deep Shadow | Flees from light sources | 5 |
| Light-blind Troll | Can't detect in light | 2 |
| Photophobic Ghoul | Avoids lit areas | 3-4 |

### Design Notes
Could create safe zones with torches.

---

## MISSING ARCHETYPE: SOUND-BASED DETECTION

### Current State
Detection is purely visual (perception stat).

### Needed
| Monster | Sound Behavior | Layer |
|---------|----------------|-------|
| Blind Worm | Hears but doesn't see | 4 |
| Echolocator Bat | Sonar detection | 1 |
| Listening Spider | Feels vibrations | 1 |

### Design Notes
Would need alternate detection system.

---

## ARCHETYPE PRIORITY LIST

### High Priority (Core Stealth Gameplay)
1. **Sleeping variants** - Easy to add via flag
2. **Handler-beast pairs** - Key assassination mechanic
3. **Pure alarm creatures** - Priority targeting

### Medium Priority (Enhanced Stealth)
4. **Patrol monsters** - Timing gameplay
5. **Distraction-vulnerable** - Tactical options

### Low Priority (Nice to Have)
6. **Light-sensitive variants** - Safe zone creation
7. **Sound-based detection** - Alternate stealth

---

## SPECIFIC MONSTER PROPOSALS

See MON-005 for detailed monster designs addressing these gaps.

---

## GDD MONSTER ROSTER COMPARISON

The GDD specifies these monsters (checking coverage):

### Layer 1 (Forest Breach)
- [X] Mirkwood spiders - multiple types exist
- [X] Crebain - exists
- [X] Giant bats - exists
- [X] Orc scouts - exists
- [ ] Tangleweed (stationary) - MISSING (have Tanglethorn, similar)
- [X] Warg pups - exists

### Layer 2 (Orc Warrens)
- [X] Orc soldiers/archers - exists
- [X] Wargs - exists
- [X] Hill trolls - exists
- [X] Warg riders - exists
- [ ] Orc slavers with prisoners - PARTIAL (have Thrallmaster)

### Layer 3 (Torture Halls)
- [X] Easterling warriors - exists
- [X] Dark sorcerers - exists
- [X] Ghouls - exists
- [X] Mirk-trolls - exists
- [X] Tortured prisoners - exists (Tortured Wretch)

### Layer 4 (Necropolis)
- [X] Skeletons - exists
- [X] Zombies - exists
- [X] Wights - exists
- [X] Necromancers - exists
- [X] Barrow-wights - exists

### Layer 5 (Wraith Domain)
- [X] Phantoms/shadows - exists
- [X] Wraiths - exists
- [X] Fell spirits - exists
- [X] Vampires - exists
- [X] Lesser Nazgul (Uvatha) - exists

### Layer 6 (Inner Sanctum)
- [X] Black Numenoreans - exists
- [X] Olog-hai - exists
- [X] Vampire lords - exists
- [X] Greater wraiths - exists
- [X] Khamul - exists

### Layer 7 (Pits of Despair)
- [X] Elite guards - exists
- [X] Sauron - exists
- [X] Thrain's shade - exists

### Coverage: ~95%
Only missing explicit tangleweed/tripwire vegetation, but Tanglethorn is similar enough.

---

## SUMMARY

### What's Missing
1. Sleeping variants (guaranteed asleep)
2. Handler-beast mechanics
3. Pure alarm creatures
4. Patrol behavior

### What's Good
- Full GDD monster roster coverage
- Proper layer distribution
- Thematic appropriateness
- Difficulty progression

### Action Items
1. Add new monsters (MON-005)
2. Modify existing monsters (MON-007)
3. Consider code changes for patrol/handler mechanics
