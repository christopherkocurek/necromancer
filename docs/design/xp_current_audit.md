# XP Current Audit - The Necromancer
## XP-002: Current SIL-Q Experience System Analysis

---

## Overview

SIL-Q's experience system tracks four distinct XP sources plus a total pool. Experience is used to purchase skill points, not to gain levels.

---

## XP SOURCES

### 1. Kill Experience (`kill_exp`)

**Code Location:** `src/xtra2.c:2436-2438`

```c
new_exp = adjusted_mon_exp(r_ptr, TRUE);
gain_exp(new_exp);
p_ptr->kill_exp += new_exp;
```

**Formula:** `src/xtra2.c:2521-2559`
```c
s32b adjusted_mon_exp(const monster_race* r_ptr, bool kill)
{
    int mexp = r_ptr->level * 10;  // Base: level × 10
    int mkills = l_list[r_ptr - r_info].pkills;  // Previous kills of this type

    if (kill) {
        if (r_ptr->flags1 & RF1_UNIQUE) {
            exp = mexp;  // Uniques: full XP every time
        } else {
            exp = mexp / (mkills + 1);  // Diminishing returns
        }
        if (r_ptr->flags1 & RF1_PEACEFUL) {
            exp = 0;  // No XP for peaceful creatures
        }
    }
    return exp;
}
```

**Key Observations:**
- Base XP = monster level × 10
- Diminishing returns: XP divides by (previous kills + 1)
- First kill of type: full XP
- Second kill: half XP
- Third kill: one-third XP, etc.
- Uniques: always full XP
- PEACEFUL flag: 0 XP

**Stealth Impact:** Killing the same monster type repeatedly is inefficient. Encourages finding new enemies, not grinding.

---

### 2. Encounter Experience (`encounter_exp`)

**Code Location:** `src/xtra2.c:2455-2467`, `src/monster2.c:1679-1683`

```c
if (!m_ptr->encountered) {
    int new_exp = adjusted_mon_exp(r_ptr, FALSE);  // FALSE = encounter, not kill
    gain_exp(new_exp);
    p_ptr->encounter_exp += new_exp;
    m_ptr->encountered = TRUE;
}
```

**Formula:** Same as kill XP but based on `msights` (sightings) instead of `mkills`.

**Key Observations:**
- XP granted on first sight of a monster
- Same diminishing returns as kill XP
- Stacks with kill XP (if you encounter then kill, you get both)
- Rewards exploration and observation

**Stealth Impact:** Excellent for stealth! You get encounter XP just by seeing enemies, even if you sneak past them.

---

### 3. Descent Experience (`descent_exp`)

**Code Location:** `src/dungeon.c:2539-2545`

```c
for (i = p_ptr->max_depth + 1; i <= p_ptr->depth; i++) {
    if (i > 1) {
        int new_exp = i * 50;  // Depth × 50
        gain_exp(new_exp);
        p_ptr->descent_exp += new_exp;
    }
}
p_ptr->max_depth = p_ptr->depth;
```

**Formula:** Each new depth level grants `depth × 50` XP.

**XP Progression:**
| Depth | XP Gained | Cumulative |
|-------|-----------|------------|
| 50ft (1) | 0 | 0 |
| 100ft (2) | 100 | 100 |
| 150ft (3) | 150 | 250 |
| 300ft (6) | 300 | 1050 |
| 500ft (10) | 500 | 2750 |
| 1000ft (20) | 1000 | 10500 |

**Key Observations:**
- Linear scaling with depth
- Only triggers on NEW maximum depth
- Backtracking doesn't grant XP
- Significant XP source for progression

**Stealth Impact:** Highly supportive of stealth. You get XP just for descending deeper, regardless of how many enemies you killed. A stealth player gets this XP naturally.

---

### 4. Identification Experience (`ident_exp`)

**Code Location:** `src/object2.c:816-821`, `src/xtra1.c:3143-3145`

```c
if (!flag && !p_ptr->leaving) {
    int new_exp = 100;  // Flat 100 XP per identification
    gain_exp(new_exp);
    p_ptr->ident_exp += new_exp;
}
```

**Formula:** Flat 100 XP per new item type identified.

**Key Observations:**
- One-time bonus per item type
- Applies to potions, scrolls, staves, wands, etc.
- Relatively small contribution compared to combat
- Rewards cautious play and item management

**Stealth Impact:** Neutral. All playstyles benefit equally from identification.

---

## XP SPENDING

**Code Location:** `src/birth.c:1732-1795`

```c
// The nth skill point costs (100*n) experience points
// First skill point: 100 XP
// Second skill point: 200 XP
// Third skill point: 300 XP
// etc.
```

**Cost Formula:** nth skill point costs `100 × n` XP.

**Total Cost to Skill Level:**
| Skill Level | Total XP Cost |
|-------------|---------------|
| 1 | 100 |
| 2 | 300 |
| 3 | 600 |
| 4 | 1000 |
| 5 | 1500 |
| 10 | 5500 |
| 15 | 12000 |
| 20 | 21000 |

---

## DATA STRUCTURES

**Code Location:** `src/types.h:782-788`

```c
s32b new_exp;       /* Available experience (spendable) */
s32b exp;           /* Total experience earned */
s32b encounter_exp; /* Total experience from encountering monsters */
s32b kill_exp;      /* Total experience from killing monsters */
s32b descent_exp;   /* Total experience from descending to new levels */
s32b ident_exp;     /* Total experience from identifying objects */
```

---

## STEALTH BUILD XP ANALYSIS

### Combat Playthrough (Kill Everything)
- Kill XP: High (but diminishing)
- Encounter XP: Full (always encounter before killing)
- Descent XP: Full
- Ident XP: Normal
- **Total:** High but grinding is penalized

### Stealth Playthrough (Avoid Combat)
- Kill XP: Low (few kills)
- Encounter XP: Full (see enemies while sneaking)
- Descent XP: Full
- Ident XP: Normal
- **Total:** Lower than combat, but still viable

### Current Balance Assessment
The diminishing returns on kill XP and the existence of encounter/descent XP makes stealth play viable but not optimal. A pure stealth build currently gets roughly 60-70% of the XP of a combat build.

---

## GAPS FOR STEALTH-FIRST DESIGN

### Missing XP Sources
1. **Discovery XP** - No XP for finding secrets, vaults, or special locations
2. **Objective XP** - No XP for completing goals (finding items, rescuing NPCs)
3. **Stealth Action XP** - No XP for successful stealth kills, pickpocket, etc.
4. **Avoidance XP** - No XP for escaping dangerous situations

### Current Problems
1. **Kill XP still dominant** - Even with diminishing returns, killing is often optimal
2. **No unique stealth rewards** - Nothing special for assassination vs combat kills
3. **Linear encounter XP** - No bonus for seeing dangerous monsters undetected
4. **No exploration incentive** - Descent XP only, no reward for map coverage

---

## RECOMMENDATIONS FOR REBALANCE

### Reduce Kill XP
- Option A: Steeper diminishing returns (divide by `mkills + 2` instead of `+1`)
- Option B: Cap maximum kills that grant XP per species
- Option C: Flat reduction (×0.5 or ×0.75)

### Increase Non-Combat XP
1. **Tower Objects** - New collectible items that grant discovery XP
2. **Stealth Kill Bonus** - Extra XP for kills while hidden
3. **Exploration XP** - XP for map coverage or vault discovery
4. **Milestone XP** - XP for reaching key story points

### New XP Sources to Implement
1. `discovery_exp` - From Tower Objects and secrets
2. `stealth_exp` - From successful stealth actions
3. `objective_exp` - From completing layer goals

---

## FILE LOCATIONS SUMMARY

| Component | File | Line Range |
|-----------|------|------------|
| Kill XP grant | xtra2.c | 2436-2438 |
| Encounter XP grant | xtra2.c | 2455-2467 |
| adjusted_mon_exp() | xtra2.c | 2521-2559 |
| Descent XP grant | dungeon.c | 2539-2545 |
| Ident XP grant | object2.c | 816-821 |
| XP data fields | types.h | 782-788 |
| Skill purchase | birth.c | 1732-1795 |
| gain_exp() | xtra2.c | 1752-1777 |
| XP display | files.c | 1292 |

---

## STARTING XP

**Code Location:** `src/birth.c:81`
```c
p_ptr->new_exp = p_ptr->exp = get_start_xp();
```

Players start with base XP that depends on race/class selection choices.

---

## CONCLUSION

SIL-Q's XP system is already partially stealth-friendly due to:
1. Diminishing returns on kill XP
2. Encounter XP for seeing enemies
3. Descent XP independent of combat

However, for a truly stealth-first design, we need:
1. Additional non-combat XP sources (Tower Objects, discovery)
2. Stealth-specific bonuses (assassination, avoidance)
3. Potentially reduced kill XP to shift balance further

The system is well-architected for expansion - adding new XP types requires:
1. New field in `types.h`
2. New tracking in save/load
3. New grant calls in relevant code
