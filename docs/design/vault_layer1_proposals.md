# Layer 1 Vault Design Proposals - The Necromancer
## VAULT-005: Forest Breach (Depths 1-3)

---

## Layer Theme Recap
**Setting:** Corrupted Mirkwood reclaiming the outer ruins of Dol Guldur
**Threats:** Spiders, poison, webs, crebain, orc scouts
**Feel:** Creeping dread, nature gone wrong, ambush predators
**Key Resistance:** Poison

---

## Vault Design Principles for Layer 1
1. Webs and poison are environmental hazards
2. Spiders ambush from concealment
3. Crebain/bats serve as alarms - stealth must avoid them
4. Orc scouts are rare but organized
5. Dense foliage/rubble provides cover for both player AND enemies
6. Entry point to the dungeon - teach stealth mechanics

---

## NEW VAULT PROPOSALS

### Vault 1: The Spider's Parlor
**Concept:** A web-choked chamber where a great spider waits in ambush. Multiple approaches allow stealth or combat.

**Size:** 11x11
**Type:** 6 (interesting room)
**Depth:** 1 | **Rarity:** 8
**Flags:** WEBS

```
###########
#M.....s.M#
#.###.###.#
#.#.....#.#
$.+..M..+.$
#.#.....#.#
#.###.###.#
#M.s.....M#
###########
```

**Features:**
- Central spider (M) guards the crossing
- 4 corner spiders in web nests
- Secret doors (s) allow bypass
- Multiple entry points (E/W)
- Pillars break line of sight

**Stealth Rating:** 4/5 - Multiple approaches, secret bypass

---

### Vault 2: Crebain Roost Bypass
**Concept:** A tower with alarm crebain, but a ground-level passage allows sneaking past.

**Size:** 11x9
**Type:** 6
**Depth:** 2 | **Rarity:** 10
**Flags:** None

```
..#####..
.##bbb##.
##b.*.b##
#b.###.b#
$.s...s.$
#.#####.#
#.......#
#:::::::##
$$$$$$$$$
```

**Features:**
- Upper level has crebain (b) and treasure (*)
- Lower passage (rubble :) is safe route
- Secret doors (s) connect levels
- Player choice: risk alarm for treasure or sneak past

**Stealth Rating:** 5/5 - Clear stealth vs reward choice

---

### Vault 3: The Sleeping Den
**Concept:** Warg pups sleeping in a den. Can sneak past or wake them all.

**Size:** 9x9
**Type:** 6
**Depth:** 2 | **Rarity:** 8
**Flags:** None

```
#########
#c.c.c.c#
#.......#
#c.....c#
+...?...+
#c.....c#
#.......#
#c.c.c.c#
#########
```

**Features:**
- 8 wolf pups (c) positioned around edges
- Central loot (?)
- Wide open center allows careful movement
- Sleeping flag on pups means stealth viable

**Stealth Rating:** 4/5 - Sleeping enemies, careful navigation

---

### Vault 4: Tangled Crossing
**Concept:** A natural chokepoint where roots and webs create a maze. Spiders lurk.

**Size:** 13x7
**Type:** 6
**Depth:** 1 | **Rarity:** 5
**Flags:** WEBS

```
#############
#::.:::..:::#
#.M.....M...$
$...:::.....#
#..M.....M..$
#::...:::.::#
#############
```

**Features:**
- Rubble (:) breaks up space
- 4 spiders (M) patrol
- Multiple corridor connections
- Irregular shape feels natural

**Stealth Rating:** 3/5 - Cover available, but open areas

---

### Vault 5: Scout Signal Post
**Concept:** Orc scout outpost with a signal fire. Stealth-killing the signaler prevents reinforcements.

**Size:** 11x11
**Type:** 6
**Depth:** 2 | **Rarity:** 12
**Flags:** None

```
###########
#o.#;#;#.o#
#..+.#.+..#
###+####+##
$....a.....$
###+####+##
#..+.#.+..#
#o.#.0.#.o#
###########
```

**Features:**
- Central archer (a) is the signaler (SHRIEK)
- 4 orc scouts (o) in corner posts
- Forge/fire (0) provides light
- Runes (;) mark signal area
- Kill archer first = no alarm
- Multiple doors allow approach

**Stealth Rating:** 5/5 - Clear assassination priority target

---

### Vault 6: The Poison Garden
**Concept:** A corrupted grove with poison pools and tanglethorn plants. Environmental hazard focus.

**Size:** 11x9
**Type:** 6
**Depth:** 2 | **Rarity:** 10
**Flags:** None

```
###########
#&.~...~.&#
#.~~.&.~~.#
#~.......~#
$....?....$
#~.......~#
#.~~.&.~~.#
#&.~...~.&#
###########
```

**Features:**
- Poison water (~) creates barriers
- Good treasure (&) rewards careful navigation
- Central loot (?)
- Tanglethorn (static plants) not shown but implied
- No patrol enemies - environmental challenge

**Stealth Rating:** 3/5 - Navigation puzzle, not stealth focus

---

### Vault 7: Web Trap Gallery
**Concept:** A corridor with webs that slow movement and hidden spiders that spring when prey is stuck.

**Size:** 13x5
**Type:** 6
**Depth:** 1 | **Rarity:** 6
**Flags:** WEBS

```
#############
#s.M.....M.s#
$...........#
#s.M.....M.s#
#############
```

**Features:**
- 4 spiders (M) hidden in alcoves
- Secret doors (s) in corners allow escape
- WEBS flag means movement penalty
- Sprinting through triggers all; careful movement safer

**Stealth Rating:** 3/5 - Bypass options via secrets

---

### Vault 8: The Brood Cache
**Concept:** A spider egg chamber. Disturbing it hatches reinforcements. Treasure hidden within.

**Size:** 9x9
**Type:** 6
**Depth:** 3 | **Rarity:** 15
**Flags:** WEBS | NO_ROTATION

```
#########
##M.*.M##
#.#####.#
#.#&.&#.#
+.s...s.+
#.#####.#
#M.....M#
##.....##
####$####
```

**Features:**
- Outer spiders (M) guard
- Secret passage (s) to inner treasure
- Central good treasure (&)
- Regular treasure (*)
- Disturbing triggers hatching? (gameplay implication)

**Stealth Rating:** 4/5 - Secret bypass to treasure

---

## REDESIGN PROPOSALS FOR EXISTING VAULTS

### N:11 Web Choke - Redesign
**Current Problem:** Forced corridor, no stealth option

**Proposed Fix:**
```
#########
#.s##s..#
$.M##M..$
#..##...#
$.M##M..$
#..s#s..#
#########
```
- Add secret doors (s) for bypass
- Widen sides for cover

---

### N:12 Corrupted Grove - Redesign
**Current Problem:** Empty room with treasure

**Proposed Fix:**
```
##########
#&:.:.:&:#
#:.###.:.#
$..#?#...$
#:.###.:.#
#&:.:.:&:#
##########
```
- Add central puzzle/loot (?)
- Rubble for atmosphere
- Corner treasures

---

### N:17 Scout Camp - Redesign
**Current Problem:** Bland rectangle, open

**Proposed Fix:**
```
############
#o..##..##o#
#...+....+.#
###+##..##+#
$....00.....$
###+##..##+#
#o..+....+o#
#...##..##.#
############
```
- Sleeping scouts (o) in tents (##)
- Doors allow isolation
- Central forge area

---

### N:23 Warg Den - Redesign
**Current Problem:** Pack swarm, no structure

**Proposed Fix:**
```
##########
#C#..#..##
#.+..+..C#
###..##+##
$.........$
###..##+##
#C+..+...#
##..#..#C#
##########
```
- 4 wargs (C) in kennel corners
- Doors control engagement
- Central safe passage

---

## REMOVAL RECOMMENDATIONS

| Vault | Reason | Replacement |
|-------|--------|-------------|
| N:20 Small Web Room | Too simple (5x5) | Spider's Parlor |
| N:26 Root Tunnel | Empty passage | Tangled Crossing |

---

## LAYER 1 VAULT COUNT

**Current:** 20 vaults
**Remove:** 2
**Add:** 8 new proposals
**New Total:** 26 vaults (trim to ~18-20 in implementation)

---

## SUMMARY

Layer 1 needs the most work because it teaches players the game's stealth mechanics. New designs focus on:
1. **Bypass options** - Secret doors, alternative routes
2. **Alarm avoidance** - Crebain/bat posts with sneak routes
3. **Sleeping enemies** - Wargs as stealth opportunities
4. **Environmental hazards** - Poison, webs as tactical elements
5. **Clear stealth vs combat choice** - Risk/reward for engagement
