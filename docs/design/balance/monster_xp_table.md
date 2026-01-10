# Monster XP Table

## Document: AUDIT-002
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document extracts XP values for all monsters from `lib/edit/monster.txt`. The base XP formula is:

```
Base XP = monster_level * 10
```

Where `monster_level` is the `W:depth:rarity` field in monster.txt (the depth value).

---

## XP Calculation Notes

- **Kill XP**: Base * diminishing returns (see AUDIT-001)
- **Encounter XP**: Base / (sightings + 1)
- **Unique monsters**: Always full base XP

---

## Layer 1: The Forest Breach (50-150ft, Depths 1-3)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 11 | Mirkwood Spider | 1 | 1 | 10 | Common starter |
| 12 | Giant Rat | 1 | 1 | 10 | Common starter |
| 13 | Black Squirrel | 1 | 2 | 10 | Shrieks for help |
| 14 | Crebain | 1 | 2 | 10 | Flying scouts |
| 15 | Tanglethorn | 1 | 1 | 10 | Stationary, poison |
| 16 | Giant Bat | 2 | 1 | 20 | Flying |
| 17 | Web Spinner | 2 | 2 | 20 | Throws webs |
| 18 | Orc Scout | 2 | 1 | 20 | Can shriek |
| 19 | Swamp Adder | 2 | 3 | 20 | Poison, stealthy |
| 20 | Great Spider | 3 | 2 | 30 | Larger spider |
| 21 | Warg Pup | 3 | 1 | 30 | Pack animal |
| 22 | **Broodmother** | 3 | 6 | 30 | Layer 1 Boss |

**Layer 1 Summary:**
- Common monsters: 10-30 XP base
- Boss (Broodmother): 30 XP base

---

## Layer 2: The Orc Warrens (150-300ft, Depths 3-6)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 31 | Orc Slave | 3 | 1 | 30 | Weak |
| 32 | Orc Soldier | 4 | 1 | 40 | Basic orc |
| 33 | Orc Crossbowman | 4 | 3 | 40 | Ranged |
| 34 | Warg | 5 | 1 | 50 | Pack hunter |
| 35 | Orc Thrallmaster | 5 | 3 | 50 | Has whip |
| 36 | Orc Captain | 5 | 2 | 50 | Has escort |
| 37 | Warg Rider | 5 | 3 | 50 | Mounted orc |
| 38 | Hill Troll | 6 | 2 | 60 | First troll |
| 39 | **Gashnak, Warg-lord** | 6 | 10 | 60 | Unique |
| 40 | **Orc Warchief** | 6 | 6 | 60 | Layer 2 Boss |

**Layer 2 Summary:**
- Common monsters: 30-60 XP base
- Boss (Orc Warchief): 60 XP base

---

## Layer 3: The Torture Halls (300-450ft, Depths 6-9)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 51 | Dark Acolyte | 6 | 2 | 60 | Caster |
| 52 | Ghoul | 7 | 1 | 70 | Undead, entrance |
| 53 | Mirk-troll | 7 | 1 | 70 | Poison troll |
| 54 | Easterling Warrior | 7 | 2 | 70 | Human enemy |
| 55 | Dark Sorcerer | 8 | 3 | 80 | Caster |
| 56 | Tortured Wretch | 7 | 4 | 70 | Mad prisoner |
| 57 | Easterling Champion | 8 | 3 | 80 | Elite human |
| 58 | Ghast | 8 | 2 | 80 | Stronger ghoul |
| 59 | **Karvag the Torturer** | 9 | 10 | 90 | Unique |
| 60 | **Master Sorcerer** | 9 | 6 | 90 | Layer 3 Boss |

**Layer 3 Summary:**
- Common monsters: 60-90 XP base
- Boss (Master Sorcerer): 90 XP base

---

## Layer 4: The Necropolis (450-600ft, Depths 9-12)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 71 | Skeleton | 9 | 1 | 90 | Basic undead |
| 72 | Skeleton Warrior | 10 | 1 | 100 | Armed skeleton |
| 73 | Zombie | 9 | 1 | 90 | Slow, regenerates |
| 74 | Wight | 10 | 2 | 100 | Drains CON |
| 75 | Corpse-candle | 10 | 3 | 100 | Confuses |
| 76 | Necromancer Adept | 11 | 2 | 110 | Raises dead |
| 77 | Barrow-wight | 11 | 3 | 110 | Stronger wight |
| 78 | Bone Golem | 11 | 4 | 110 | Construct |
| 79 | **Grishnákh, Crypt Lord** | 12 | 10 | 120 | Unique |

**Layer 4 Summary:**
- Common monsters: 90-120 XP base

---

## Layer 5: The Wraith Domain (600-750ft, Depths 12-15)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 91 | Phantom | 12 | 1 | 120 | Terrifies |
| 92 | Shadow | 13 | 1 | 130 | Drains STR |
| 93 | Whispering Shade | 13 | 2 | 130 | Multiplies |
| 94 | Wraith | 14 | 1 | 140 | Standard wraith |
| 95 | Fell Spirit | 14 | 3 | 140 | Pass wall |
| 96 | Spectre | 14 | 2 | 140 | Cold attack |
| 97 | Vampire Thrall | 13 | 2 | 130 | Lesser vampire |
| 98 | **The Wailing Horror** | 15 | 10 | 150 | Unique |
| 99 | **Úvatha the Horseman** | 15 | 6 | 150 | Layer 5 Boss (Nazgûl) |

**Layer 5 Summary:**
- Common monsters: 120-150 XP base
- Boss (Úvatha): 150 XP base

---

## Layer 6: The Inner Sanctum (750-900ft, Depths 15-18)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 111 | Black Númenórean | 15 | 1 | 150 | Elite caster |
| 112 | Olog-hai | 16 | 1 | 160 | Battle troll |
| 113 | Vampire | 16 | 2 | 160 | Full vampire |
| 114 | Greater Wraith | 17 | 2 | 170 | Powerful wraith |
| 115 | Vampire Lord | 17 | 3 | 170 | Elite vampire |
| 116 | Shadow Lord | 17 | 4 | 170 | Invisible |
| 117 | Maia Thrall | 18 | 5 | 180 | Corrupted Maia |
| 118 | **Khamûl, Shadow of the East** | 18 | 3 | 180 | Layer 6 Boss (Nazgûl #2) |

**Layer 6 Summary:**
- Common monsters: 150-180 XP base
- Boss (Khamûl): 180 XP base

---

## Layer 7: The Pits of Despair (900-1000ft, Depths 18-20)

| ID | Monster | Depth | Rarity | Base XP | Notes |
|----|---------|-------|--------|---------|-------|
| 131 | Elite Olog-hai | 18 | 1 | 180 | Elite troll |
| 132 | Greater Shadow | 19 | 2 | 190 | Drains all |
| 133 | Void Wraith | 19 | 3 | 190 | Pass wall |
| 134 | Thráin's Shade | 20 | 100 | 200 | Quest NPC (peaceful) |
| 135 | **Sauron, the Necromancer** | 20 | 1 | 200 | Final Boss |

**Layer 7 Summary:**
- Common monsters: 180-200 XP base
- Final Boss (Sauron): 200 XP base

---

## XP Distribution Analysis

### By Depth Level

| Depth | Base XP | Monsters at Depth |
|-------|---------|-------------------|
| 1 | 10 | 5 |
| 2 | 20 | 4 |
| 3 | 30 | 4 |
| 4 | 40 | 2 |
| 5 | 50 | 4 |
| 6 | 60 | 4 |
| 7 | 70 | 5 |
| 8 | 80 | 3 |
| 9 | 90 | 4 |
| 10 | 100 | 3 |
| 11 | 110 | 3 |
| 12 | 120 | 2 |
| 13 | 130 | 3 |
| 14 | 140 | 3 |
| 15 | 150 | 4 |
| 16 | 160 | 2 |
| 17 | 170 | 3 |
| 18 | 180 | 4 |
| 19 | 190 | 2 |
| 20 | 200 | 2 |

### XP Curve Summary

- **Early game (depths 1-6):** 10-60 XP base per monster
- **Mid game (depths 7-12):** 70-120 XP base per monster
- **Late game (depths 13-18):** 130-180 XP base per monster
- **End game (depths 19-20):** 190-200 XP base per monster

### Practical XP (First Kill)

With first-kill bonuses (100% XP):
- Layer 1 monster: 10-30 XP
- Layer 7 monster: 180-200 XP

With +30% boost applied:
- Layer 1 monster: 13-39 XP
- Layer 7 monster: 234-260 XP

---

## Key Observations

1. **Linear XP scaling**: Monster XP scales linearly with depth (10 XP per depth level)
2. **Bosses not significantly more valuable**: Boss XP same as regular monsters at their depth
3. **Diminishing returns hit hard**: By 3rd kill of same type, XP drops to 19%
4. **Variety is rewarded**: Killing different monster types maximizes XP

---

## Recommendations

1. **+30% boost is straightforward**: Multiply `level * 10` by 1.3 to get `level * 13`
2. **Consider boss bonuses**: Unique monsters could have higher base XP
3. **Layer bosses could scale**: Consider giving layer bosses 1.5x-2x normal XP
