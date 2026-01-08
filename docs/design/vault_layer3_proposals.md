# Layer 3 Vault Design Proposals - The Necromancer
## VAULT-007: Torture Halls (Depths 6-9)

---

## Layer Theme Recap
**Setting:** Cells, chains, dark sorcery, the screaming halls
**Threats:** Sorcerers, ghouls, mirk-trolls, Easterling guards
**Feel:** Horror, cruelty, magical oppression
**Key Resistance:** Will, Free Action

---

## Vault Design Principles for Layer 3
1. Sorcerers are high-priority assassination targets (control spells)
2. Ghouls are mindless - can be avoided or lured
3. Prisoners offer rescue opportunities (moral choices)
4. Easterlings are disciplined - harder than orcs
5. Magic creates zones of danger (darkness, hold)
6. Torture implements as environmental flavor

---

## NEW VAULT PROPOSALS

### Vault 1: The Sorcerer's Meditation
**Concept:** A sorcerer in deep trance. Perfect stealth-kill opportunity.

**Size:** 9x9
**Type:** 6
**Depth:** 8 | **Rarity:** 12
**Flags:** None

```
#########
#;;;;;;;#
#;#####;#
#;#.&.#;#
+.+.@.+.+
#;#...#;#
#;#####;#
#;;;;;;;#
#########
```

**Features:**
- Sorcerer (@) in meditation (SLEEPING equivalent)
- Protective runes (;) mark ritual space
- Treasure (&) reward
- Multiple approach doors
- Kill before he wakes = no spells

**Stealth Rating:** 5/5 - Ideal assassination setup

---

### Vault 2: The Breaking Room
**Concept:** A torture chamber with a victim and torturer. Rescue opportunity.

**Size:** 11x9
**Type:** 6
**Depth:** 7 | **Rarity:** 8
**Flags:** None

```
###########
#:..:..:.:#
#.########.#
#.#:....:#.#
+.+.1.@.+.+
#.#:..:..#.#
#.########.#
#:..:..:.:#
###########
```

**Features:**
- Torturer (@) focused on victim (1)
- Victim is rescuable prisoner
- Doors allow ambush approach
- Kill torturer = save prisoner
- Rubble (:) for atmosphere

**Stealth Rating:** 5/5 - Stealth rescue scenario

---

### Vault 3: Ghoul Feeding Pit
**Concept:** Ghouls gathered around carrion. They won't notice you if you don't get close.

**Size:** 11x11
**Type:** 6
**Depth:** 7 | **Rarity:** 6
**Flags:** None

```
###########
#z.z...z.z#
#.........#
#z..~~~..z#
$...~~~...$
#z..~~~..z#
#.........#
#z.z...z.z#
###########
```

**Features:**
- 12 ghouls (z) around poison pit
- Central carrion pile (~)
- Wide corridors ($) allow edge sneaking
- Ghouls face center (distracted)
- Mindless = don't pursue far

**Stealth Rating:** 4/5 - Distraction allows bypass

---

### Vault 4: The Chain Gang
**Concept:** Prisoners being moved. Guards distracted by herding.

**Size:** 13x7
**Type:** 6
**Depth:** 7 | **Rarity:** 8
**Flags:** None

```
#############
#@.1.1.1.1.@#
#...........#
$...........$
#...........#
#@.1.1.1.1.@#
#############
```

**Features:**
- 4 Easterling guards (@) on edges
- 8 prisoners (1) in chains
- Open space for chaos
- Free prisoners = distraction
- Guards face inward

**Stealth Rating:** 4/5 - Create chaos opportunity

---

### Vault 5: Easterling Officer's Quarters
**Concept:** Elite enemy in private quarters. High-value assassination.

**Size:** 11x9
**Type:** 6
**Depth:** 8 | **Rarity:** 15
**Flags:** None

```
###########
#&.*..*.&#
#.#######.#
#.#.....#.#
+.+..2..s.+
#.#.....#.#
#.#######.#
#@...@...@#
###########
```

**Features:**
- Champion (2) in inner chamber (sleeping)
- 3 guards (@) in outer room
- Secret door (s) to inner room
- Bypass guards, assassinate champion
- Treasure reward (&*)

**Stealth Rating:** 5/5 - Classic stealth infiltration

---

### Vault 6: The Summoning Circle
**Concept:** A sorcerer mid-ritual with bound ghouls. Kill sorcerer before summon completes.

**Size:** 11x11
**Type:** 6
**Depth:** 9 | **Rarity:** 20
**Flags:** None

```
###########
#.........#
#.;#####;.#
#.#z.z.z#.#
+.#z.@.z#.+
#.#z.z.z#.#
#.;#####;.#
#....&....#
#####$#####
```

**Features:**
- Sorcerer (@) in center controlling ghouls
- 8 ghouls (z) bound in circle
- Kill sorcerer = ghouls become passive?
- Or ghouls break free and attack everything
- Runes (;) mark binding

**Stealth Rating:** 4/5 - Time pressure assassination

---

### Vault 7: The Confession Booth
**Concept:** Small rooms where prisoners are interrogated. Multiple targets.

**Size:** 13x7
**Type:** 6
**Depth:** 7 | **Rarity:** 10
**Flags:** None

```
#############
#@#1#@#1#@#1#
#.+.+.+.+.+.#
$...........$
#.+.+.+.+.+.#
#1#@#1#@#1#@#
#############
```

**Features:**
- 6 interrogators (@)
- 6 prisoners (1)
- Many small rooms with doors
- Clear line-of-sight breaks
- Systematic assassination possible

**Stealth Rating:** 5/5 - Room-by-room clearing

---

### Vault 8: The Mass Grave
**Concept:** Bodies being dumped. Ghouls rise when disturbed.

**Size:** 9x9
**Type:** 6
**Depth:** 8 | **Rarity:** 12
**Flags:** None

```
#########
#:::::::##
#:z.z.z::#
#:......:#
+:.?....:.+
#:......:#
#:z.z.z::#
#::::::::##
#########
```

**Features:**
- Rubble (:) = bone piles
- Dormant ghouls (z) in grave
- Random item (?) bait
- Stepping near = awakens ghouls
- Edge path is safe

**Stealth Rating:** 3/5 - Avoidance possible

---

## REDESIGN PROPOSALS FOR EXISTING VAULTS

### N:53 Ghoul Pit - Redesign
**Current Problem:** Simple horde circle

**Proposed Fix:** Use Vault 3 (Ghoul Feeding Pit) design

---

### N:58 Chains Room - Redesign
**Current Problem:** Simple room, single enemy

**Proposed Fix:**
```
#########
#::.::.:##
#.:1.:1.:##
#:.....:.#
+...@....+
#:.....:.#
#.:1.:1.:##
#::.::.:##
#########
```
- Add prisoners (1) in chains
- Clear rescue opportunity

---

### N:59 Mirk-Troll Den - Redesign
**Current Problem:** Open pen, no tactics

**Proposed Fix:**
```
##########
#T.#..#.T#
#..+..+..#
###.~~.###
+...~~...+
###.~~.###
#T.+..+.T#
#..#..#..#
##########
```
- Trolls in corners (sleeping)
- Poison water center
- Doors control engagement

---

### N:62 Ghast Nest - REMOVE
**Current Problem:** Redundant with Ghoul Pit
**Recommendation:** Remove, use space for new vault

---

### N:63 Hanging Cages - Redesign
**Current Problem:** Basic rescue, unclear

**Proposed Fix:**
```
###########
#.1.#.#.1.#
#...+.+...#
###+####+##
$....@.....$
###+####+##
#.1.+.+.1.#
#...#.#...#
###########
```
- Clear guard (@) position
- Prisoners (1) in cages
- Doors allow stealth approach

---

## REMOVAL RECOMMENDATIONS

| Vault | Reason | Replacement |
|-------|--------|-------------|
| N:62 | Ghast Nest - Redundant | Ghoul Feeding Pit |

---

## LAYER 3 VAULT COUNT

**Current:** 15 vaults
**Remove:** 1
**Add:** 8 new proposals
**Replace:** 4 redesigns
**New Total:** 22 vaults (trim to ~14-16 in implementation)

---

## SUMMARY

Layer 3 introduces magical threats and moral choices:
1. **Sorcerer assassination** - Kill before spells are cast
2. **Ghoul distraction** - Mindless enemies can be bypassed
3. **Prisoner rescue** - Moral choices with mechanical rewards
4. **Easterling discipline** - Tougher human enemies
5. **Ritual interruption** - Time-pressure stealth
6. **Horror atmosphere** - Torture implements, screaming halls
