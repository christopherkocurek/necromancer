# Exploration and Stealth XP Audit

## Document: AUDIT-004
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document audits XP sources related to non-combat activities: exploration, stealth, and discovery.

---

## Currently Implemented Non-Combat XP

### 1. Descent XP (Implemented)

**Location:** `src/dungeon.c:2586-2602`

```c
int new_exp = i * 50;
gain_exp(new_exp);
p_ptr->descent_exp += new_exp;
```

**Awards:** `depth_level * 50` XP for each new depth reached

**Total XP from full descent (to depth 20):**
- Sum of (2+3+4+...+20) * 50 = 209 * 50 = **10,450 XP**

### 2. Encounter XP (Implemented)

**Location:** `src/monster2.c:1679-1683`

```c
new_exp = adjusted_mon_exp(r_ptr, FALSE);
gain_exp(new_exp);
p_ptr->encounter_exp += new_exp;
```

**Awards:** `monster_level * 10 / (sightings + 1)` XP for first sight of monster

**Notes:**
- Benefits stealth builds who see enemies without fighting
- Diminishing returns on repeated sightings

### 3. Identification XP (Implemented)

**Location:** `src/object2.c:868-871`

**Awards:** 100 XP per newly identified item type

### 4. Lore Reading XP (Implemented)

**Location:** `src/cmd1.c:5422-5424`

**Awards:** 500 XP per lore note read

---

## NOT Currently Implemented

The following XP sources are **not present** in the codebase:

### 1. Stealth Success XP

**Status:** NOT IMPLEMENTED

**What it could be:**
- XP for passing within sight range of enemies without being detected
- XP for successfully breaking LOS after being spotted
- XP for assassinations (first-strike kills on unaware targets)

### 2. Trap Disarming XP

**Status:** NOT IMPLEMENTED

**What it could be:**
- XP for successfully disarming traps
- Scales with trap difficulty

### 3. Locked Door XP

**Status:** NOT IMPLEMENTED

**What it could be:**
- XP for picking locks or forcing doors
- Minor reward for exploration

### 4. Secret Door XP

**Status:** NOT IMPLEMENTED

**What it could be:**
- XP for finding hidden passages
- Rewards perception investment

### 5. Floor Exploration XP

**Status:** NOT IMPLEMENTED (only descent is rewarded)

**What it could be:**
- XP bonus for exploring a percentage of each floor
- Rewards thorough exploration vs rushing

### 6. Discovery Object XP

**Status:** PARTIALLY DOCUMENTED BUT NOT IMPLEMENTED

In `lib/edit/object.txt`, discovery objects mention XP values:
- Thráin's Memories: 150 XP each
- Shadow Fragments: 200 XP each
- Ancient Glyphs: 75 XP each
- Palantír Shards: 500 XP each

**Could not find implementation** in the source code for these XP awards.

---

## Code Search Results

Searched for stealth-related XP:
- No XP awarded in stealth checks
- No XP for successful hiding
- No XP for sneak attacks

Searched for trap-related XP:
- Traps damage player or trigger effects
- No XP awarded for disarming

Searched for door-related XP:
- Door opening is a basic action
- No XP awarded

---

## Opportunity Analysis

### Why Add Exploration XP?

1. **Stealth build parity** - Combat builds earn XP from kills; stealth builds need equivalent
2. **Reward smart play** - Avoiding fights is tactically valid and should be rewarded
3. **Encourage exploration** - Players shouldn't feel punished for not grinding monsters

### Potential New XP Sources

| Source | Suggested Amount | Rationale |
|--------|-----------------|-----------|
| Depth milestones | +100 XP per 100ft | Existing descent is thin |
| Stealth bypass | 50% of monster's kill XP | Reward for avoiding combat |
| Trap disarm | 50-100 XP | Minor exploration bonus |
| Secret door | 50 XP | Perception reward |
| Assassinate bonus | +25% kill XP | Reward stealth + combat hybrid |

---

## Comparison: Combat vs Stealth XP Income

### Current State

**Combat player on floor with 10 monsters:**
- Kill XP: ~500 XP (first kills, level 5 monsters)
- Encounter XP: ~500 XP
- **Total: ~1,000 XP**

**Stealth player on same floor:**
- Kill XP: 0 (avoiding combat)
- Encounter XP: ~500 XP
- **Total: ~500 XP**

**Gap:** Stealth player earns 50% less XP

### With Proposed Stealth XP

**Stealth player with bypass XP:**
- Kill XP: 0
- Encounter XP: ~500 XP
- Bypass XP: ~250 XP (50% of would-be kill XP)
- **Total: ~750 XP**

**Gap reduced to 25%** - More viable but combat still slightly favored (risk/reward)

---

## Recommendations

### Priority 1: Implement Stealth Bypass XP
Award XP when player:
- Sees a monster (encounter)
- Leaves the level without killing it
- Amount: 30-50% of the kill XP they would have received

**Implementation location:** `src/dungeon.c` when player uses stairs

### Priority 2: Depth Milestone Bonuses
Add bonus XP at significant depths:
- 100ft: 100 XP
- 200ft: 200 XP
- 300ft: 300 XP
- etc.

**Implementation location:** Extend existing descent XP code

### Priority 3: Discovery Objects (if designed)
If Tower lore items are in the game:
- Implement the XP values already documented in object.txt
- Tie to IDENT flags for one-time rewards

---

## Conclusion

The current game heavily favors combat for XP income. While encounter XP helps stealth builds somewhat, the **50% XP gap** between combat and stealth players creates the "forced to hyper-specialize" problem identified in the PRD.

Adding stealth bypass XP and depth milestones would:
1. Make stealth builds more viable
2. Reduce pressure to kill every monster
3. Reward exploration and smart play
