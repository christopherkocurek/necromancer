# New Monster Proposals - The Necromancer
## MON-005: Stealth-Relevant Monster Designs

---

## Design Goals

New monsters should create interesting stealth scenarios:
1. Sleeping targets for Throat Slit
2. Handler-beast dynamics
3. Alarm priority targets
4. Solo elite assassination targets
5. Patrol/timing challenges

---

## LAYER 1 ADDITIONS

### N:23 - Watch-crow
**Concept:** Pure alarm creature. No combat, just alerts.

```
N:23:Watch-crow
W:1:2
G:b:D
I:4:1d4:0
A:0:8:2:1
P:[+10]
F:FLYING | ALERT | NO_FEAR
S:SPELL_PCT_100
S:SHRIEK
D:A single crow perched high, watching for intruders.
D: It will flee and shriek if it spots you.
```

**Stealth Notes:**
- 100% SHRIEK rate - priority target
- High evasion, flying - hard to kill
- Zero sleep - always watching
- **Kill first or avoid entirely**

---

### N:24 - Resting Spider
**Concept:** Guaranteed sleeping spider.

```
N:24:Resting Spider
W:2:3
G:M:s
I:2:5d4:0
A:30:2:6:2
P:[+4,1d4]
B:BITE:POISON:(+5,1d7)
F:SPIDER | TERRITORIAL | RES_POIS | SLEEPING
D:A spider curled in its web, dormant until disturbed.
D: Its legs twitch occasionally in its slumber.
```

**Stealth Notes:**
- Sleepiness 30 + SLEEPING flag = guaranteed asleep
- Perfect Throat Slit target
- Territorial = won't chase far

---

## LAYER 2 ADDITIONS

### N:41 - Orc Sentry
**Concept:** Dedicated guard with patrol behavior.

```
N:41:Orc Sentry
W:4:2
G:o:U
I:2:6d4:0
A:5:6:4:3
P:[+5,2d4]
B:HIT:HURT:(+5,1d8)
F:MALE | OPEN_DOOR | ORC | HURT_LITE | SMART | PATROL
S:SPELL_PCT_50
S:SHRIEK
D:An orc guard walking a set patrol route.
D: He checks the same spots with military regularity.
```

**Stealth Notes:**
- Low sleep (5) - usually awake
- High perception (6) - alert
- PATROL flag - predictable movement
- 50% SHRIEK - will raise alarm

---

### N:42 - Sleeping Soldier
**Concept:** Off-duty orc, guaranteed asleep.

```
N:42:Sleeping Soldier
W:4:3
G:o:s
I:2:6d4:0
A:30:1:2:2
P:[+3,2d4]
B:HIT:HURT:(+4,2d5)
F:MALE | ORC | HURT_LITE | SLEEPING
D:An orc soldier in deep slumber, exhausted from duty.
D: His weapon lies at his side.
```

**Stealth Notes:**
- Sleepiness 30 + SLEEPING = always asleep
- Low perception when waking
- Perfect assassination target

---

### N:43 - Warg Handler
**Concept:** Controls wargs. Kill handler = wargs scatter.

```
N:43:Warg Handler
W:5:3
G:o:U
I:2:7d4:0
A:15:5:3:4
P:[+5,2d4]
B:HIT:HURT:(+6,2d5)
B:WHIP:HURT:(+4,1d4)
F:MALE | DROP_33 | OPEN_DOOR | ORC | HURT_LITE | SMART | HANDLER
D:An orc who commands a pack of wargs through fear.
D: Without him, the beasts will scatter in confusion.
```

**Stealth Notes:**
- HANDLER flag - death affects controlled beasts
- Kill handler = wargs flee
- High-value priority target

---

### N:44 - Handled Warg
**Concept:** Warg under handler control.

```
N:44:Handled Warg
W:5:3
G:C:U
I:3:7d4:0
A:10:4:4:3
P:[+7,1d4]
B:BITE:WOUND:(+9,2d5)
F:WOLF | HANDLED | FRIENDS
D:A warg kept in check by its handler's whip.
D: It strains at its leash, eager to hunt.
```

**Stealth Notes:**
- HANDLED flag - linked to handler
- When handler dies, becomes passive/flees
- Spawns with Handler

---

## LAYER 3 ADDITIONS

### N:61 - Apprentice Torturer
**Concept:** Lesser enemy learning the trade.

```
N:61:Apprentice Torturer
W:7:2
G:@:s
I:2:5d4:0
A:15:3:3:4
P:[+4,1d4]
B:HIT:HURT:(+5,1d7)
F:MAN | MALE | DROP_33 | OPEN_DOOR | SMART
D:A young human learning the dark craft of torture.
D: He is less alert than his masters.
```

**Stealth Notes:**
- Medium sleep, low perception
- Good stealth target
- Less dangerous than Dark Sorcerer

---

### N:62 - Ghoul Pack Leader
**Concept:** Intelligent ghoul that controls others.

```
N:62:Ghoul Pack Leader
W:8:4
G:z:W
I:2:10d4:0
A:10:6:4:7
P:[+8,2d4]
B:CLAW:HURT:(+12,2d6)
B:BITE:ENTRANCE:(+10,2d6)
F:UNDEAD | RES_COLD | RES_POIS | NO_FEAR | SMART
F:NO_CONF | NO_SLEEP | HURT_LITE | HANDLER
D:A ghoul of unusual cunning that commands lesser ghouls.
D: Destroy it, and the pack loses cohesion.
```

**Stealth Notes:**
- HANDLER flag - controls ghoul pack
- Kill to disable nearby ghouls
- Priority assassination target

---

## LAYER 4 ADDITIONS

### N:80 - Dormant Skeleton
**Concept:** Skeleton that hasn't been animated yet.

```
N:80:Dormant Skeleton
W:9:2
G:z:s
I:0:3d4:0
A:0:0:0:0
P:[+2]
F:UNDEAD | RES_COLD | RES_POIS | NO_FEAR | MINDLESS
F:NO_CONF | DORMANT
D:Bones arranged neatly, awaiting animation.
D: They might rise if a necromancer draws near.
```

**Stealth Notes:**
- DORMANT flag - doesn't act until triggered
- Can walk past safely
- Necromancer presence animates them

---

### N:81 - Necromancer's Familiar
**Concept:** Corpse-candle linked to necromancer.

```
N:81:Necromancer's Familiar
W:11:4
G:w:G
I:2:2d4:2
A:5:8:6:8
P:[+12]
B:TOUCH:CONFUSE:(+14)
F:UNDEAD | RES_COLD | RES_POIS | NO_FEAR
F:NO_CONF | NO_SLEEP | FLYING | INVISIBLE | FAMILIAR
D:A wisp of necromantic energy bound to its master.
D: While it lives, the necromancer can sense intruders.
```

**Stealth Notes:**
- FAMILIAR flag - linked to necromancer
- Provides detection to master
- Kill familiar first = blind necromancer

---

## LAYER 5 ADDITIONS

### N:101 - Torpid Vampire
**Concept:** Vampire in deep sleep. Guaranteed asleep.

```
N:101:Torpid Vampire
W:13:3
G:v:D
I:3:10d4:0
A:50:2:8:8
P:[+20,1d4]
B:CLAW:WOUND:(+16,2d6)
B:BITE:LOSE_CON:(+14,2d6)
F:FLYING | SMART | HURT_LITE | SLEEPING
D:A vampire in deathlike torpor, utterly still.
D: It will not wake unless blood is spilled nearby.
```

**Stealth Notes:**
- Sleepiness 50 + SLEEPING = deep torpor
- Perfect high-level assassination target
- Wakes if combat nearby

---

### N:102 - Bound Spirit
**Concept:** Spirit held in a binding circle.

```
N:102:Bound Spirit
W:14:4
G:w:v
I:2:8d4:0
A:0:10:10:12
P:[+16]
B:TOUCH:DARK:(+18,2d8)
F:UNDEAD | RES_COLD | NO_FEAR | RES_POIS
F:NO_CONF | NO_SLEEP | RES_CRIT | BOUND
D:A malevolent spirit held in place by ancient wards.
D: Breaking the circle would be most unwise.
```

**Stealth Notes:**
- BOUND flag - cannot move
- Don't break the wards
- Navigation puzzle, not combat

---

## LAYER 6 ADDITIONS

### N:119 - Black Numenorean Mage
**Concept:** Caster variant of Black Numenorean.

```
N:119:Black Numenorean Mage
W:16:3
G:@:v
I:2:10d4:0
A:10:8:5:16
P:[+12,2d4]
B:HIT:DARK:(+14,2d8)
F:MAN | MALE | DROP_100 | OPEN_DOOR | UNLOCK_DOOR | SMART
S:SPELL_PCT_60 | POW_18
S:DARKNESS | SLOW | HOLD | SCARE | CONF
D:A Black Numenorean dedicated to sorcery over steel.
D: His spells can hold you helpless while others kill.
```

**Stealth Notes:**
- High-priority assassination target
- HOLD spell = instant death if caught
- Kill before engaging warriors

---

### N:120 - Resting Olog
**Concept:** Sleeping Olog-hai.

```
N:120:Resting Olog
W:16:3
G:T:s
I:2:20d4:0
A:30:2:0:6
P:[+10,3d4]
B:HIT:BATTER:(+14,4d8)
F:MALE | REGENERATE | NO_FEAR | TROLL | SMART | SLEEPING
F:KNOCK_BACK
D:An Olog-hai in deep slumber, chest rising slowly.
D: Its massive weapon lies within easy reach.
```

**Stealth Notes:**
- SLEEPING + high sleepiness = always asleep
- Massive HP but vulnerable to throat-slit
- High-value target

---

## LAYER 7 ADDITIONS

### N:136 - Void Sentinel
**Concept:** Elite guard that detects invisible.

```
N:136:Void Sentinel
W:19:2
G:W:D
I:2:16d4:-2
A:5:20:14:22
P:[+22,4d4]
B:TOUCH:LOSE_ALL:(+26,3d8)
F:UNDEAD | RES_COLD | SMART | HURT_LITE
F:NO_FEAR | RES_POIS | NO_CONF | NO_SLEEP | RES_CRIT
F:SEE_INVISIBLE
D:A wraith that guards the final passages.
D: It can see through all concealment.
```

**Stealth Notes:**
- SEE_INVISIBLE - counters stealth
- Must be fought or completely avoided
- Gates the final approach

---

## SUMMARY: NEW MONSTERS

| ID | Name | Layer | Purpose |
|----|------|-------|---------|
| 23 | Watch-crow | 1 | Pure alarm |
| 24 | Resting Spider | 1 | Sleeping target |
| 41 | Orc Sentry | 2 | Patrol guard |
| 42 | Sleeping Soldier | 2 | Sleeping target |
| 43 | Warg Handler | 2 | Handler mechanic |
| 44 | Handled Warg | 2 | Handled beast |
| 61 | Apprentice Torturer | 3 | Easy target |
| 62 | Ghoul Pack Leader | 3 | Handler for undead |
| 80 | Dormant Skeleton | 4 | Avoidance |
| 81 | Necromancer's Familiar | 4 | Detection helper |
| 101 | Torpid Vampire | 5 | High-level sleeper |
| 102 | Bound Spirit | 5 | Navigation puzzle |
| 119 | Black Numenorean Mage | 6 | Priority caster |
| 120 | Resting Olog | 6 | Elite sleeper |
| 136 | Void Sentinel | 7 | Counter-stealth |

**Total New Monsters: 15**
