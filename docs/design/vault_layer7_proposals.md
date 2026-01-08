# Layer 7 Vault Design Proposals - The Necromancer
## VAULT-011: Pits of Despair (Depths 18-20)

---

## Layer Theme Recap
**Setting:** Absolute darkness, malice incarnate, Sauron's domain
**Threats:** Elite Olog-hai, greater shadows, void wraiths, Sauron himself
**Feel:** Hopelessness, overwhelming power, escape is victory
**Key Resistance:** Escape plan - combat is not the goal

---

## Vault Design Principles for Layer 7
1. Combat is not the path to victory - extraction is
2. Sauron cannot be killed - must be evaded
3. Thrain must be found and extracted
4. Every enemy is lethal - one mistake = death
5. Multiple escape routes should exist
6. Minimal vaults - this layer is about the mission

---

## NEW VAULT PROPOSALS

### Vault 1: The Final Guard Post
**Concept:** Last checkpoint before Sauron's throne. Must pass or eliminate.

**Size:** 13x11
**Type:** 6
**Depth:** 19 | **Rarity:** 6
**Flags:** None

```
#############
#T.T#...#T.T#
#...+...+...#
###+####+###
$....W.....$
###+####+###
#T..+...+..T#
#...#...#...#
#############
```

**Features:**
- 6 Elite Olog-hai (T)
- Greater wraith (W) commander
- Doors for engagement control
- Last obstacle before Sauron
- Stealth or total elimination

**Stealth Rating:** 3/5 - Difficult but possible

---

### Vault 2: The Pit of Shadows
**Concept:** A bottomless pit ringed with shadows. Traverse the edge.

**Size:** 11x11
**Type:** 6
**Depth:** 19 | **Rarity:** 10
**Flags:** None

```
###########
#w.w...w.w#
#.7777777.#
#w7777777w#
+.7777777.+
#w7777777w#
#.7777777.#
#w.w...w.w#
###########
```

**Features:**
- Massive chasm (7) in center
- 8 greater shadows (w) patrol edge
- Narrow walkway around edge
- One wrong step = death
- Timing and patience required

**Stealth Rating:** 4/5 - Navigation challenge

---

### Vault 3: Thrain's Cell Approach
**Concept:** The corridor to Thrain's prison. Void wraiths guard.

**Size:** 13x7
**Type:** 6
**Depth:** 20 | **Rarity:** 15
**Flags:** None

```
#############
#W.........W#
#..........#
$...........$
#..........#
#W.........W#
#############
```

**Features:**
- 4 void wraiths (W) at corners
- Wide corridor
- Must pass to reach Thrain
- Wraiths sense invisible
- Ultimate stealth challenge

**Stealth Rating:** 2/5 - Very difficult

---

### Vault 4: The Escape Shaft
**Concept:** A vertical shaft with up stairs. Escape route from Sauron.

**Size:** 9x9
**Type:** 6
**Depth:** 19 | **Rarity:** 20
**Flags:** NO_ROTATION

```
#########
#....<...#
#.#####.#
#.#...#.#
+.+...+.+
#.#...#.#
#.#####.#
#........#
#########
```

**Features:**
- Up stairs (<) = escape
- Open chamber
- No guards - secret escape
- Finding this = salvation
- Leads to Gates

**Stealth Rating:** 5/5 - Pure escape vault

---

### Vault 5: The Dark Archive
**Concept:** Sauron's records. Treasure but heavily watched.

**Size:** 11x11
**Type:** 6
**Depth:** 19 | **Rarity:** 15
**Flags:** None

```
###########
#&.&...&.&#
#.#######.#
#.#.....#.#
+.+..W..+.+
#.#.....#.#
#.#######.#
#&.&...&.&#
###########
```

**Features:**
- Void wraith (W) archivist
- Treasure (&) = ancient scrolls
- Single powerful guardian
- High risk, high reward
- Optional objective

**Stealth Rating:** 4/5 - Single target

---

### Vault 6: The Despair Chamber
**Concept:** A room that drains will. Must pass quickly.

**Size:** 9x9
**Type:** 6
**Depth:** 20 | **Rarity:** 10
**Flags:** None

```
#########
#;;;;;;;#
#;.....;#
#;.....;#
+;..?..;+
#;.....;#
#;.....;#
#;;;;;;;#
#########
```

**Features:**
- Rune chamber (;) = despair effect
- Item (?) bait in center
- No enemies - pure environmental
- Will drain per turn inside
- Rush through or avoid

**Stealth Rating:** N/A - Environmental hazard

---

## REDESIGN PROPOSALS FOR EXISTING VAULTS

### N:131 Greater Shadow Hall - Redesign
**Current Problem:** Open swarm room

**Proposed Fix:**
```
###########
#W.#.#.#.W#
#..+.+.+..#
###.#.#.###
$...........$
###.#.#.###
#W.+...+.W#
#..#.#.#..#
###########
```
- Add structure
- Reduce shadow count
- Create paths

---

### N:132 Void Wraith Sanctum - Redesign
**Current Problem:** Static chasm room

**Proposed Fix:**
```
###########
#77777777#
#7W...W7.#
#7.....7.#
+7.....7.+
#7.....7.#
#7W...W7.#
#77777777#
###########
```
- Wraiths inside chasm area
- Clearer navigation

---

## CRITICAL: Thrain's Prison Pit (N:133)

Current design is good - keep as is:
```
#########
#.......#
#.#####.#
#.#...#.#
+.+.>.+.+
#.#...#.#
#.#####.#
#.......#
#########
```

This is the objective vault. Down stairs lead to Thrain's shade.
No enemies - the challenge is getting here.

---

## CRITICAL: Sauron's Throne Room (N:450)

Current design is excellent. Key features:
- Multiple paths through massive complex
- Up stairs in two locations (escape routes)
- Sauron (V) in center
- Elite guards throughout
- Treasure scattered for risk-takers

**Recommendation:** Keep as is. This is well-designed for extraction gameplay.

---

## LAYER 7 DESIGN PHILOSOPHY

Layer 7 is different from all other layers:

1. **NOT about combat** - Player should avoid fights
2. **Mission-focused** - Find Thrain, escape
3. **Sauron is unbeatable** - Don't fight, run
4. **Multiple escape routes** - Gates, shafts, secrets
5. **Time pressure** - Sauron hunts the player
6. **Minimal vaults** - Focus on the mission

---

## LAYER 7 VAULT COUNT

**Current:** 4 vaults + Sauron's Throne
**Remove:** 0
**Add:** 6 new proposals
**Replace:** 2 redesigns
**New Total:** 10 vaults (keep at ~6-8 in implementation)

---

## EXTRACTION GAMEPLAY FLOW

1. Descend through Layer 7 vaults
2. Find Thrain's Prison Pit (N:133)
3. Interact with Thrain's Shade (N:134 monster)
4. Obtain key/ring/objective
5. Navigate back through Sauron's Throne (N:450)
6. Avoid or distract Sauron
7. Reach up stairs or Escape Shaft
8. Ascend to Gates of Dol Guldur (N:1)
9. Fight through escape gauntlet
10. Victory!

---

## SUMMARY

Layer 7 is the extraction endgame:
1. **Mission objective** - Rescue Thrain, escape
2. **Sauron avoidance** - Cannot be killed
3. **Escape routes** - Multiple paths out
4. **Maximum danger** - One mistake = death
5. **Minimal combat** - Stealth is survival
6. **Atmospheric horror** - Despair, darkness, malice
