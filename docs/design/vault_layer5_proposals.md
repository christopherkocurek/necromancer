# Layer 5 Vault Design Proposals - The Necromancer
## VAULT-009: Wraith Domain (Depths 12-15)

---

## Layer Theme Recap
**Setting:** Perpetual shadow, whispers, bone-chilling cold
**Threats:** Phantoms, shadows, wraiths, fell spirits
**Feel:** Terror, the unseen, madness
**Key Resistance:** See Invisible, Will

---

## Vault Design Principles for Layer 5
1. Invisible enemies require See Invisible or careful listening
2. Will saves against fear effects are crucial
3. Shadows drain stats - avoid prolonged fights
4. Safe zones of light or protection exist
5. Wraiths are intelligent and can track
6. Psychological horror through sound cues

---

## NEW VAULT PROPOSALS

### Vault 1: The Sanctuary of Light
**Concept:** A protected zone amidst shadows. Rest point with ward mechanics.

**Size:** 11x11
**Type:** 6
**Depth:** 13 | **Rarity:** 8
**Flags:** LIGHT

```
###########
#w.w...w.w#
#.........#
#w.;;;;;.w#
$..;...;..$
#w.;.?.;.w#
$..;...;..$
#w.;;;;;.w#
#.........#
#w.w...w.w#
###########
```

**Features:**
- Protective rune ring (;) = safe zone
- Shadows (w) patrol outside
- Treasure (?) in center is safe
- LIGHT flag means permanently lit
- Sanctuary concept

**Stealth Rating:** 4/5 - Safe zone provides rest

---

### Vault 2: The Whispering Maze
**Concept:** A maze where whispering shades teleport. Disorienting.

**Size:** 13x13
**Type:** 6
**Depth:** 14 | **Rarity:** 12
**Flags:** None

```
#############
#.w.#.#.#.w.#
#.#.#.#.#.#.#
#.#.#.#.#.#.#
#.#...#...#.#
$.#.#.&.#.#.$
#.#...#...#.#
#.#.#.#.#.#.#
#.#.#.#.#.#.#
#.w.#.#.#.w.#
#############
```

**Features:**
- Maze design with many passages
- 4 whispering shades (w) teleport randomly
- Treasure (&) reward
- Can't predict enemy positions
- Adds paranoia element

**Stealth Rating:** 3/5 - Unpredictable but paths exist

---

### Vault 3: The Wraith Binding
**Concept:** A wraith bound in a circle. Don't break the wards.

**Size:** 9x9
**Type:** 6
**Depth:** 14 | **Rarity:** 15
**Flags:** None

```
#########
#;;;;;;;#
#;.....;#
#;.###.;#
+;.#W#.;+
#;.###.;#
#;..&..;#
#;;;;;;;#
#########
```

**Features:**
- Wraith (W) bound in center
- Rune circle (;) = binding
- Treasure (&) outside binding
- Don't step on runes = wraith stays bound
- High tension navigation

**Stealth Rating:** 4/5 - Careful navigation required

---

### Vault 4: The Cold Chamber
**Concept:** A freezing room with vampires in torpor. Don't wake them.

**Size:** 11x9
**Type:** 6
**Depth:** 13 | **Rarity:** 12
**Flags:** None

```
###########
#v.#&*&#.v#
#..#####..#
#v.......v#
+....?....+
#v.......v#
#..#####..#
#v.#&*&#.v#
###########
```

**Features:**
- 6 vampires (v) in torpor (sleeping)
- Treasure (&*) in corner alcoves
- Center item (?)
- Vampires don't wake easily in cold
- Perfect stealth-loot scenario

**Stealth Rating:** 5/5 - Sleeping predators

---

### Vault 5: The Phantom Crossing
**Concept:** Must cross an open area where phantoms patrol. Timing crucial.

**Size:** 13x7
**Type:** 6
**Depth:** 13 | **Rarity:** 6
**Flags:** None

```
#############
#w..w..w..w#
#..........#
$...........$
#..........#
#w..w..w..w#
#############
```

**Features:**
- 8 phantoms (w) in two rows
- Wide open crossing
- Must time movement between patrols
- Invisible = need See Invisible
- Pure timing challenge

**Stealth Rating:** 4/5 - Timing based

---

### Vault 6: The Shadow Pool
**Concept:** A pool of liquid darkness. Shadows emerge if disturbed.

**Size:** 11x11
**Type:** 6
**Depth:** 14 | **Rarity:** 10
**Flags:** None

```
###########
#.........#
#.#######.#
#.#77777#.#
+.#7.W.7#.+
#.#7.&.7#.#
#.#77777#.#
#.#######.#
#.........#
###########
```

**Features:**
- Chasm (7) = shadow pool
- Wight (W) guards the pool
- Treasure (&) in center (how to reach?)
- Shadows emerge from pool
- Environmental hazard

**Stealth Rating:** 3/5 - Puzzle element

---

### Vault 7: The Fell Spirit's Sanctum
**Concept:** A fell spirit that phases through walls. Can't be cornered.

**Size:** 11x11
**Type:** 6
**Depth:** 15 | **Rarity:** 20
**Flags:** None

```
###########
#.w.....w.#
#.#######.#
#w#.....#w#
#.+..W..+.#
#w#.....#w#
#.#.&*&.#.#
#.s.....s.#
###########
```

**Features:**
- Fell spirit (W) in center can PASS_WALL
- 6 shadows (w) as escorts
- Secret doors (s) to treasure
- Spirit can't be trapped
- Must eliminate or evade

**Stealth Rating:** 3/5 - Challenging enemy type

---

### Vault 8: The Memory Chamber
**Concept:** Illusions of the past. Not all enemies are real.

**Size:** 9x9
**Type:** 6
**Depth:** 14 | **Rarity:** 15
**Flags:** None

```
#########
#?.?.?.?#
#.......#
#?.....?#
+...W...+
#?.....?#
#.......#
#?.?.?.?#
#########
```

**Features:**
- 12 (?) = may or may not be real
- Central wraith (W) is definitely real
- Some (?) are illusions, some are shadows
- Player must guess or See Invisible
- Psychological horror

**Stealth Rating:** 3/5 - Uncertainty mechanic

---

## REDESIGN PROPOSALS FOR EXISTING VAULTS

### N:90 Shadow Hall - Redesign
**Current Problem:** Open hall, no tactics

**Proposed Fix:**
```
###########
#w..#.#..w#
#...+.+...#
###.#.#.###
$...........$
###.#.#.###
#w..+.+..w#
#...#.#...#
###########
```
- Add pillars and doors
- Creates cover and routes

---

### N:91 Phantom Chamber - Redesign
**Current Problem:** Basic room

**Proposed Fix:**
```
###########
#w.#...#.w#
#..+...+..#
###.###.###
+...#W#...+
###.###.###
#w.+.?.+.w#
#..#...#..#
###########
```
- Add central wight (W)
- Structure with doors

---

### N:93 Spectral Crossing - Redesign
**Current Problem:** Empty crossing

**Proposed Fix:** Use Phantom Crossing design above

---

### N:98 Whispering Gallery - Redesign
**Current Problem:** Linear gauntlet

**Proposed Fix:**
```
###############
#w.#.#.#.#.#.w#
#..+.+.+.+.+..#
###+#.#.#.#+###
$.............$
###+#.#.#.#+###
#w.+.+.+.+.+.w#
#..#.#.#.#.#..#
###############
```
- Add rooms along gallery
- Doors create escape routes

---

## REMOVAL RECOMMENDATIONS

None - Layer 5 needs more vaults, not fewer.

---

## LAYER 5 VAULT COUNT

**Current:** 11 vaults
**Remove:** 0
**Add:** 8 new proposals
**Replace:** 4 redesigns
**New Total:** 19 vaults (trim to ~12-14 in implementation)

---

## SUMMARY

Layer 5 introduces incorporeal threats:
1. **See Invisible requirement** - Core mechanic becomes crucial
2. **Will saves** - Fear and hold effects dominate
3. **Safe zones** - Lit areas and wards as sanctuary
4. **Sleeping vampires** - Risk/reward stealth
5. **Wall-phasing enemies** - Can't corner them
6. **Psychological elements** - Whispers, illusions, uncertainty
