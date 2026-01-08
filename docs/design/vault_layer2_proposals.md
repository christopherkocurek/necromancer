# Layer 2 Vault Design Proposals - The Necromancer
## VAULT-006: Orc Warrens (Depths 3-6)

---

## Layer Theme Recap
**Setting:** Military barracks, forge-smoke, organized orc resistance
**Threats:** Orc groups, wargs, archers, warg riders
**Feel:** Enemy territory, military encampment, dangerous patrols
**Key Need:** Evasion, Stealth

---

## Vault Design Principles for Layer 2
1. Sleeping quarters = stealth opportunity (sleeping orcs)
2. Guard posts require careful timing or elimination
3. Alarm horns/archers as priority targets
4. Patrols create windows of opportunity
5. Wargs have keen senses - harder to sneak past
6. Officer assassination = high value targets

---

## NEW VAULT PROPOSALS

### Vault 1: Sleeping Barracks
**Concept:** An orc dormitory with sleeping soldiers. Perfect stealth-kill or sneak-past opportunity.

**Size:** 13x9
**Type:** 6
**Depth:** 4 | **Rarity:** 6
**Flags:** None

```
#############
#o.o#...#o.o#
#...+...+...#
###+#...#+###
$...........$
###+#...#+###
#...+...+...#
#o.o#...#o.o#
#############
```

**Features:**
- 8 orcs (o) in corner bunks - SLEEPING flag
- Central corridor is patrol route
- Doors isolate sections
- Can throat-slit individuals without waking others

**Stealth Rating:** 5/5 - Designed for stealth kills

---

### Vault 2: The Worg Handler's Post
**Concept:** Single orc handler with 2 wargs. Kill handler to prevent warg alarm.

**Size:** 9x7
**Type:** 6
**Depth:** 5 | **Rarity:** 10
**Flags:** None

```
#########
#C#.*.#C#
#.+...+.#
###.O.###
$..+.+..$
###...###
####$####
```

**Features:**
- Orc captain handler (O) in center
- 2 wargs (C) in side pens
- Kill handler = wargs don't raise alarm
- Treasure reward (*)

**Stealth Rating:** 4/5 - Priority target mechanic

---

### Vault 3: Patrol Circuit
**Concept:** A vault with a clear circular patrol path. Timing-based stealth.

**Size:** 13x11
**Type:** 6
**Depth:** 4 | **Rarity:** 8
**Flags:** None

```
#############
#.o.......o.#
#.#########.#
#.#.......#.#
#.#..&*&..#.#
$.+.......+.$
#.#..&*&..#.#
#.#.......#.#
#.#########.#
#.o.......o.#
#############
```

**Features:**
- 4 orcs (o) patrol the outer ring
- Central treasure room with doors
- Wait for patrol gap, dash to center
- Inner room has excellent loot

**Stealth Rating:** 5/5 - Classic patrol timing puzzle

---

### Vault 4: Horn Tower
**Concept:** An alarm tower. The archer must be silenced before engaging others.

**Size:** 9x11
**Type:** 6
**Depth:** 5 | **Rarity:** 12
**Flags:** None

```
...###...
..##a##..
.##...##.
##..;..##
#.o.#.o.#
+...#...+
#.o.#.o.#
##.....##
.##...##.
..##.##..
...#$#...
```

**Features:**
- Archer (a) at top with horn (SHRIEK)
- Rune (;) marks alarm position
- 4 orcs (o) guard below
- Kill archer first via stealth
- Tower design allows climbing approach

**Stealth Rating:** 5/5 - Clear priority target

---

### Vault 5: The Pit Fighting Ring
**Concept:** Orcs watching pit fights. Distracted enemies, easy stealth.

**Size:** 11x11
**Type:** 6
**Depth:** 5 | **Rarity:** 10
**Flags:** None

```
###########
#o.o...o.o#
#.........#
#o.#####.o#
#..#...#..#
$..+.1.+..$
#..#...#..#
#o.#####.o#
#.........#
#o.o...o.o#
###########
```

**Features:**
- 12 orcs (o) watching the pit
- Fighter (1) in center (level+1)
- All orcs face center = backs turned
- Excellent sneak-by opportunity
- Or assassinate distracted viewers

**Stealth Rating:** 5/5 - Distraction mechanic

---

### Vault 6: The Quartermaster's Store
**Concept:** Supply depot with single greedy quartermaster. Assassination + loot.

**Size:** 11x9
**Type:** 6
**Depth:** 4 | **Rarity:** 15
**Flags:** None

```
###########
#*&*#.#*&*#
#...+.+...#
###+#O#+###
$...........$
##########$
#s......s.#
#.&*&*&*&.#
###########
```

**Features:**
- Orc captain quartermaster (O) guards store
- Massive treasure room below
- Secret doors (s) for stealth entry
- Kill quartermaster, loot everything

**Stealth Rating:** 5/5 - High-value assassination target

---

### Vault 7: Warg Breeding Pens
**Concept:** Replacement for current Warg Kennels. Fewer wargs, more structure.

**Size:** 13x9
**Type:** 6
**Depth:** 5 | **Rarity:** 8
**Flags:** None

```
#############
#C.#+#..#+.C#
#..#...#..#.#
###+#.#.#+###
$....o.o....$
###+#.#.#+###
#..#...#..#.#
#C.#+#..#+.C#
#############
```

**Features:**
- 4 wargs (C) in corner pens
- 2 handlers (o) in center
- Many doors = engagement control
- Can isolate and eliminate piecemeal

**Stealth Rating:** 4/5 - Controlled engagement

---

### Vault 8: The War Council
**Concept:** Orc officers in planning session. Elite assassination opportunity.

**Size:** 11x9
**Type:** 6
**Depth:** 6 | **Rarity:** 20
**Flags:** None

```
###########
#.O.....O.#
#.########.#
#.#......#.#
+.+..2...+.+
#.#......#.#
#.#*&*&*.#.#
#.s......s.#
###########
```

**Features:**
- 2 orc captains (O) as bodyguards
- Level+2 warchief (2) in center
- Secret doors (s) to treasure
- High risk, high reward
- Triple assassination challenge

**Stealth Rating:** 4/5 - Challenging but rewarding

---

## REDESIGN PROPOSALS FOR EXISTING VAULTS

### N:31 Warg Kennels - Redesign
**Current Problem:** 16 wargs, claustrophobic

**Proposed Fix:** Use Vault 7 above (Warg Breeding Pens)

---

### N:34 Guard Room - Redesign
**Current Problem:** Open guard post, no tactics

**Proposed Fix:**
```
#########
#o.#.#.o#
#..+.+..#
###+.#+##
$...O...$
###+.#+##
#o.+.+.o#
#..#.#..#
#########
```
- Add doors for engagement control
- Maintain guard function

---

### N:36 Mess Hall - Redesign
**Current Problem:** 14 orcs, mass combat only

**Proposed Fix:**
```
#############
#...s.O.s...#
#.ooooooooo.#
#...........#
+...........+
#...........#
#.ooooooooo.#
#...........#
#####$$$#####
```
- Keep 12 orcs (still mess hall)
- Add secret doors (s) at captain end
- Assassination target at head of table
- Or sneak past via secrets

**Stealth Rating:** 3/5 - Some stealth option now

---

### N:37 Troll Pen - Redesign
**Current Problem:** Simple open pen

**Proposed Fix:**
```
########
#T#..#T#
#.+..+.#
##....##
+.s..s.+
##....##
#T+..+T#
#.#..#.#
########
```
- Trolls in corner pens
- Secret passages (s) through center
- Can sneak past sleeping trolls

---

### N:42 Slave Pit - Redesign
**Current Problem:** Unclear rescue mechanic

**Proposed Fix:**
```
###########
#1.1.1.1.1#
#.........#
#1.......1#
+.s.....s.+
#1..>..1#
#.........#
#1.1.1.1.1#
###########
```
- Prisoners (1) in positions
- Secret doors (s) for stealth entry
- Down stairs (>) = escape route for rescued
- Clear purpose: free prisoners, send down

---

## REMOVAL RECOMMENDATIONS

No vaults need removal from Layer 2. All serve a purpose.

---

## LAYER 2 VAULT COUNT

**Current:** 16 vaults
**Remove:** 0
**Add:** 8 new proposals
**Replace:** 5 redesigns
**New Total:** 24 vaults (trim to ~16-18 in implementation)

---

## SUMMARY

Layer 2 establishes military stealth gameplay:
1. **Sleeping quarters** - Core throat-slit opportunity
2. **Patrol timing** - Classic stealth gameplay
3. **Priority targets** - Alarmists, handlers, officers
4. **Distraction** - Pit fights, meals as stealth windows
5. **Handler mechanics** - Kill handler to control beasts
6. **Rescue opportunities** - Slave pit as moral choice
