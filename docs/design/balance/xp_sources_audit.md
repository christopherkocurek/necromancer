# XP Sources Audit

## Document: AUDIT-001
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document catalogs every source of experience points (XP) in The Necromancer codebase. The game tracks XP in four distinct categories: encounter, kill, descent, and identification.

---

## XP Sources

### 1. Monster Kill XP

**Location:** `src/xtra2.c:2436-2438` (in `monster_death()` function)

```c
new_exp = adjusted_mon_exp(r_ptr, TRUE);
gain_exp(new_exp);
p_ptr->kill_exp += new_exp;
```

**Description:** XP awarded when a monster is killed.

**Formula:** `monster_level * 10` with diminishing returns:
- 1st kill: 100% XP
- 2nd kill: ~35% XP
- 3rd kill: ~19% XP
- 4th-6th kill: `mexp / (kills + 1) * 2`
- 7th+ kill: `mexp / (kills + 1) * 3`
- Minimum: 1 XP (non-peaceful monsters)
- Unique monsters: Always 100% XP

**Notes:**
- Steeper diminishing returns encourage exploring vs grinding
- Peaceful monsters give 0 XP

---

### 2. Monster Encounter XP

**Location:** `src/monster2.c:1679-1683` and `src/xtra2.c:2459-2463`

```c
new_exp = adjusted_mon_exp(r_ptr, FALSE);
gain_exp(new_exp);
p_ptr->encounter_exp += new_exp;
```

**Description:** XP awarded when a monster is first seen (enters line of sight).

**Formula:**
- Unique: Full base XP (`monster_level * 10`)
- Non-unique: `mexp / (sightings + 1)`

**Notes:**
- Rewards exploration and stealth builds
- No steeper diminishing returns (unlike kills)
- Stealth players can gain XP just by seeing monsters

---

### 3. Descent XP (Depth Exploration)

**Location:** `src/dungeon.c:2586-2602` (in `generate_cave()`)

```c
for (i = p_ptr->max_depth + 1; i <= p_ptr->depth; i++)
{
    if (i > 1)
    {
        int new_exp = i * 50;
        gain_exp(new_exp);
        p_ptr->descent_exp += new_exp;
    }
}
```

**Description:** XP awarded for reaching new dungeon depths.

**Formula:** `depth_level * 50` XP per new level (first time only)

**Example progression:**
- Depth 2: 100 XP
- Depth 3: 150 XP
- Depth 4: 200 XP
- ...
- Depth 10: 500 XP
- Depth 20: 1000 XP

**Total descent XP to depth 20:** 50 * (2+3+4+...+20) = 50 * 209 = **10,450 XP**

---

### 4. Identification XP

**Location:** `src/object2.c:868-871` (in `object_aware()`)

```c
if (!flag && !p_ptr->leaving)
{
    int new_exp = 100;
    gain_exp(new_exp);
    p_ptr->ident_exp += new_exp;
}
```

**Description:** XP awarded for identifying new item types.

**Amount:** 100 XP per newly identified item type

**Notes:**
- Rewards exploration and experimentation
- Each item "kind" can only be identified once

---

### 5. Lore Reading XP

**Location:** `src/cmd1.c:5422-5424` and `src/cmd3.c:182-184`

```c
o_ptr->ident |= IDENT_NOTE_READ;
msg_print("You gain insight from reading this lore.");
gain_exp(500);
```

**Description:** XP awarded for reading lore notes found in the dungeon.

**Amount:** 500 XP per lore note read

**Notes:**
- One-time reward per note
- Tracked via `IDENT_NOTE_READ` flag

---

## XP Tracking Structure

**Location:** `src/types.h:782-792`

```c
s32b new_exp;        /* New experience (session) - available to spend */
s32b exp;            /* Total experience earned */

s32b encounter_exp;  /* Total from encountering monsters */
s32b kill_exp;       /* Total from killing monsters */
s32b descent_exp;    /* Total from descending levels */
s32b ident_exp;      /* Total from identifying objects */
```

---

## XP Gain Function

**Location:** `src/xtra2.c:1752-1765`

```c
void gain_exp(s32b amount)
{
    if (birth_fixed_exp)
    {
        return;
    }

    p_ptr->exp += amount;
    p_ptr->new_exp += amount;

    check_experience();
}
```

**Notes:**
- `birth_fixed_exp` option disables all XP gain (testing mode)
- Both `exp` (total) and `new_exp` (spendable) are incremented

---

## XP NOT Implemented (Potential Additions)

The following sources of XP are **not currently implemented**:

1. **Stealth successes** - No XP for successfully sneaking past enemies
2. **Disarming traps** - No XP reward
3. **Opening locked doors** - No XP reward
4. **Quest completions** - No formal quest system
5. **Discovery objects** - Objects in `object.txt` mention XP values but implementation not found

---

## Summary Table

| Source | Amount | Location | Notes |
|--------|--------|----------|-------|
| Monster Kill | level*10 (diminishing) | xtra2.c:2436 | Steeper diminishing returns |
| Monster Encounter | level*10 (diminishing) | monster2.c:1679 | First sight only |
| Descent | depth*50 | dungeon.c:2590 | Per new depth level |
| Identification | 100 flat | object2.c:868 | Per new item type |
| Lore Reading | 500 flat | cmd1.c:5422 | Per lore note |

---

## Key Findings for Rebalancing

1. **Monster XP is the primary source** - Both kills and encounters use `monster_level * 10` base
2. **Diminishing returns are steep** - Kill XP drops rapidly after first kill of each type
3. **Encounter XP benefits all builds** - Stealth and combat both get encounter XP
4. **Descent XP is modest** - ~10k total XP from full dungeon descent
5. **Central point of modification** - `adjusted_mon_exp()` in `xtra2.c:2521-2611` controls most XP

---

## Recommendation for +30% XP Boost

The most effective place to add a global XP multiplier is in the `gain_exp()` function at `src/xtra2.c:1752-1765`. This would affect ALL XP sources uniformly.

Alternatively, modify the base calculation in `adjusted_mon_exp()` to boost monster-derived XP specifically.
