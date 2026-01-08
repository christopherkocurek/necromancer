# Layer 4 Vault Design Proposals - The Necromancer
## VAULT-008: Necropolis (Depths 9-12)

---

## Layer Theme Recap
**Setting:** Crypts, green witchlight, bone piles, sarcophagi
**Threats:** Skeletons, zombies, wights, necromancers
**Feel:** Death, endless undead, cold stone tombs
**Key Resistance:** Light, Fire

---

## Vault Design Principles for Layer 4
1. Necromancers are priority targets - kill controller, undead fall
2. Wights are intelligent - can't be bypassed easily
3. Skeletons/zombies are mindless - can be avoided
4. Light sources disrupt undead (HURT_LITE flag)
5. Corpse management - don't leave bodies near necromancers
6. Ancient tombs with treasure worth the risk

---

## NEW VAULT PROPOSALS

### Vault 1: The Animated Patrol
**Concept:** Skeleton patrol route with gaps. Classic timing stealth.

**Size:** 13x11
**Type:** 6
**Depth:** 10 | **Rarity:** 6
**Flags:** None

```
#############
#z.........z#
#.#########.#
#.#.......#.#
#.#..&*&..#.#
$.+.......+.$
#.#..&*&..#.#
#.#.......#.#
#.#########.#
#z.........z#
#############
```

**Features:**
- 4 skeletons (z) patrol outer ring
- Rich treasure center (&*)
- Timing-based entry
- Mindless patrol = predictable

**Stealth Rating:** 5/5 - Classic patrol puzzle

---

### Vault 2: The Necromancer's Workshop
**Concept:** A necromancer creating undead. Kill him before reinforcements rise.

**Size:** 11x11
**Type:** 6
**Depth:** 11 | **Rarity:** 12
**Flags:** None

```
###########
#z.z...z.z#
#.........#
#z.#####.z#
$..#.@.#..$
#z.#.&.#.z#
$..#####..$
#z.......z#
#z.z...z.z#
###########
```

**Features:**
- Necromancer (@) in central workshop
- 12 skeletons (z) around room
- Kill necromancer = skeletons stop
- Treasure (&) reward
- Multiple entry points

**Stealth Rating:** 4/5 - Priority assassination

---

### Vault 3: The Wight Lord's Court
**Concept:** A wight holding court over lesser undead. Elite target.

**Size:** 11x9
**Type:** 6
**Depth:** 11 | **Rarity:** 15
**Flags:** None

```
###########
#z.z.W.z.z#
#.........#
#z.#####.z#
+..#.&.#..+
#z.#.*.#.z#
#..s###s..#
#z.z...z.z#
###########
```

**Features:**
- Wight lord (W) on throne
- 8 skeleton servants (z)
- Secret doors (s) to treasure
- Kill wight lord = servants collapse
- High-value assassination

**Stealth Rating:** 4/5 - Challenging but rewarding

---

### Vault 4: The Bone Maze
**Concept:** A labyrinth of bone walls. Skeletons patrol, but passages allow bypass.

**Size:** 13x13
**Type:** 6
**Depth:** 10 | **Rarity:** 8
**Flags:** None

```
#############
#.z.#.#.#.z.#
#.#.#.#.#.#.#
#.#.#.#.#.#.#
#.#...#...#.#
$.#.#.?.#.#.$
#.#...#...#.#
#.#.#.#.#.#.#
#.#.#.#.#.#.#
#.z.#.#.#.z.#
#############
```

**Features:**
- Maze of bone pillars
- 4 skeletons (z) in corners
- Central treasure (?)
- Multiple paths = avoidance possible
- Line-of-sight constantly breaking

**Stealth Rating:** 5/5 - Designed for stealth navigation

---

### Vault 5: The Tomb of the Forgotten
**Concept:** Ancient tomb with sleeping barrow-wight. Don't wake it.

**Size:** 9x11
**Type:** 6
**Depth:** 12 | **Rarity:** 20
**Flags:** None

```
.#######.
##.....##
#.#####.#
#.#&*&#.#
#.s.W.s.#
#.#&*&#.#
#.#####.#
##.....##
.#######.
```

**Features:**
- Barrow-wight (W) sleeping in tomb
- Massive treasure (&*)
- Secret doors (s) allow careful approach
- Can loot without waking if quiet
- Wake it = powerful fight

**Stealth Rating:** 5/5 - Ultimate risk/reward

---

### Vault 6: The Corpse Assembly
**Concept:** Zombies being assembled. No necromancer yet - peaceful window.

**Size:** 11x9
**Type:** 6
**Depth:** 10 | **Rarity:** 10
**Flags:** None

```
###########
#:z:z:z:z:#
#:........#
#z........z#
$.....?....$
#z........z#
#:........#
#:z:z:z:z:#
###########
```

**Features:**
- Dormant zombies (z) on rubble slabs
- No controller present
- Zombies don't activate without stimulus
- Cross carefully or trigger them all
- Loot (?) in center

**Stealth Rating:** 4/5 - Careful navigation

---

### Vault 7: The Crypt of Whispers
**Concept:** A crypt with corpse candles that reveal intruders. Light-based detection.

**Size:** 11x11
**Type:** 6
**Depth:** 11 | **Rarity:** 12
**Flags:** None

```
###########
#w.......w#
#.#######.#
#.#.....#.#
#w+..W..+w#
#.#.....#.#
#.#.&*&.#.#
#.s.....s.#
###########
```

**Features:**
- 4 corpse candles (w) - detect invisible
- Wight (W) guardian
- Secret doors (s) to treasure bypass
- Corpse candles reveal stealth users
- Must handle lights or avoid them

**Stealth Rating:** 3/5 - Counter-stealth challenge

---

### Vault 8: The Mass Ossuary
**Concept:** Bone storage with a bone golem. Environmental horror.

**Size:** 11x9
**Type:** 6
**Depth:** 11 | **Rarity:** 15
**Flags:** None

```
###########
#:::::::::##
#:z.....z::#
#:..###..::#
+:..#*#..:.+
#:..###..::#
#:z.....z::#
#:::::::::##
###########
```

**Features:**
- Rubble (:) = bone piles everywhere
- Bone golem implied by z placement
- Central treasure (*) guarded
- Can sneak along edges
- Atmosphere of death

**Stealth Rating:** 3/5 - Some bypass possible

---

## REDESIGN PROPOSALS FOR EXISTING VAULTS

### N:71 Bone Chamber - Redesign
**Current Problem:** Simple horde circle

**Proposed Fix:**
```
#########
#:z.:.z:#
#:.###.:#
#z#...#z#
+.+.*.+.+
#z#...#z#
#:.###.:#
#:z.:.z:#
#########
```
- Add structure with doors
- Rubble for atmosphere

---

### N:74 Ossuary - Redesign
**Current Problem:** One-way entrance

**Proposed Fix:**
```
###########
#:::::::::##
#:z.z.z.z:s#
#:........:#
$:....*...:$
#:........:#
#:z.z.z.z:s#
#:::::::::##
###########
```
- Add corridor exits ($)
- Secret doors (s) for escape

---

### N:76 Zombie Pit - REMOVE
**Current Problem:** Redundant pit design
**Recommendation:** Use Corpse Assembly concept

---

### N:78 Corpse Candle Hall - Redesign
**Current Problem:** Open gauntlet

**Proposed Fix:**
```
#############
#w.#...#...w#
#..+...+...#
###.#.#.#.###
$...........$
###.#.#.#.###
#w.+...+...w#
#..#...#....#
#############
```
- Add pillars for cover
- Doors break up space

---

## REMOVAL RECOMMENDATIONS

| Vault | Reason | Replacement |
|-------|--------|-------------|
| N:76 | Zombie Pit - Redundant | Corpse Assembly |

---

## LAYER 4 VAULT COUNT

**Current:** 13 vaults
**Remove:** 1
**Add:** 8 new proposals
**Replace:** 3 redesigns
**New Total:** 20 vaults (trim to ~12-14 in implementation)

---

## SUMMARY

Layer 4 introduces undead control mechanics:
1. **Necromancer priority** - Kill controller to disable army
2. **Sleeping undead** - Barrow-wights as risk/reward
3. **Patrol timing** - Mindless undead on routes
4. **Light mechanics** - Corpse candles as counter-stealth
5. **Bone atmosphere** - Environmental horror
6. **Wight intelligence** - Smarter undead can't be bypassed
