# Skill Costs Audit

## Document: AUDIT-003
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document details the skill cost progression system in The Necromancer. Skills use a triangular number formula where each additional point costs progressively more XP.

---

## Skill Cost Formula

**Location:** `src/birth.c:1740-1745`

```c
static int skill_cost(int base, int points)
{
    int total_cost = (points + base) * (points + base + 1) / 2;
    int prev_cost = (base) * (base + 1) / 2;
    return ((total_cost - prev_cost) * 100);
}
```

### Formula Explanation

The nth skill point costs `100 * n` experience points.

**Triangular number formula:**
- Total cost to reach level N = `N * (N + 1) / 2 * 100`

### Cost Per Point Table

| From | To | Cost (XP) | Cumulative | Notes |
|------|-----|-----------|------------|-------|
| 0 | 1 | 100 | 100 | Cheap entry |
| 1 | 2 | 200 | 300 | |
| 2 | 3 | 300 | 600 | |
| 3 | 4 | 400 | 1,000 | |
| 4 | 5 | 500 | 1,500 | |
| 5 | 6 | 600 | 2,100 | |
| 6 | 7 | 700 | 2,800 | |
| 7 | 8 | 800 | 3,600 | "Viable" combat level |
| 8 | 9 | 900 | 4,500 | |
| 9 | 10 | 1,000 | 5,500 | Expert level |
| 10 | 11 | 1,100 | 6,600 | |
| 11 | 12 | 1,200 | 7,800 | |
| 12 | 13 | 1,300 | 9,100 | |
| 13 | 14 | 1,400 | 10,500 | |
| 14 | 15 | 1,500 | 12,000 | Master level |
| 15 | 16 | 1,600 | 13,600 | |
| 16 | 17 | 1,700 | 15,300 | |
| 17 | 18 | 1,800 | 17,100 | |
| 18 | 19 | 1,900 | 19,000 | |
| 19 | 20 | 2,000 | 21,000 | Maximum |

---

## Starting Experience

**Location:** `src/birth.c:59-61`

```c
#define PY_START_EXP 5000      /* Starting exp */
#define PY_FIXED_EXP 50000     /* Starting exp (for testing) */
#define PY_MAX_EXP 99999999L   /* Maximum exp */
```

- Normal characters start with **5,000 XP**
- Istari (test race) starts with **50,000 XP**

### What 5,000 XP Buys

Example allocations with 5,000 starting XP:

**Option A: Single skill focus**
- Skill to 8: 3,600 XP
- Remaining: 1,400 XP (can get another skill to 4)

**Option B: Two skills balanced**
- Two skills to 6: 2,100 + 2,100 = 4,200 XP
- Remaining: 800 XP

**Option C: Spread across 3 skills**
- Three skills to 5: 1,500 * 3 = 4,500 XP
- Remaining: 500 XP

---

## Ability Costs

**Location:** `src/cmd4.c:1411-1416, 1581-1587`

```c
int exp_cost = (abilities_in_skill(skilltype) + 1) * 500;

// give free abilities based on affinities
exp_cost -= 500 * affinity_level(skilltype);
if (exp_cost < 0) exp_cost = 0;
```

### Ability Cost Table

| # in Skill | Base Cost | With 1 Affinity | With 2 Affinities |
|------------|-----------|-----------------|-------------------|
| 1st | 500 | 0 (free) | 0 (free) |
| 2nd | 1,000 | 500 | 0 (free) |
| 3rd | 1,500 | 1,000 | 500 |
| 4th | 2,000 | 1,500 | 1,000 |
| 5th | 2,500 | 2,000 | 1,500 |

**Notes:**
- Affinity comes from race and house
- Maximum 2 affinity levels (1 from race + 1 from house)
- Abilities also require minimum skill level

---

## Affinity System

**Location:** `src/xtra1.c:2013-2081`

Races and houses can provide:
- `RHF_[SKILL]_AFFINITY` - Discount of 500 XP per ability
- `RHF_[SKILL]_PENALTY` - Penalty (increases cost)

Maximum benefit: **1,000 XP off** first two abilities (with 2 affinities)

---

## Skill Drain (Smithing)

**Location:** `src/cmd4.c:1849-1865, 3615-3890`

Smithing operations can permanently reduce skill base:

```c
p_ptr->skill_base[S_SMT] -= smithing_cost.drain;
```

This is a unique mechanic where the Smithing skill itself is consumed to create items.

---

## The Eight Skills

**Location:** `src/defines.h`

```c
#define S_MEL   0   /* Melee */
#define S_ARC   1   /* Archery */
#define S_EVN   2   /* Evasion */
#define S_STL   3   /* Stealth */
#define S_PER   4   /* Perception */
#define S_WIL   5   /* Will */
#define S_SMT   6   /* Smithing */
#define S_LOR   7   /* Lore */
```

---

## Typical Build Requirements

Based on the PRD's analysis, a viable character needs:

### Combat Build
| Skill | Target Level | Cost (XP) |
|-------|-------------|-----------|
| Melee | 8+ | 3,600 |
| Evasion | 8+ | 3,600 |
| Will | 4-5 | 1,000-1,500 |
| Perception | 3-4 | 600-1,000 |
| **Total** | | **8,800-9,700** |

### Stealth Build
| Skill | Target Level | Cost (XP) |
|-------|-------------|-----------|
| Stealth | 8+ | 3,600 |
| Evasion | 6+ | 2,100 |
| Will | 4-5 | 1,000-1,500 |
| Perception | 5+ | 1,500 |
| Melee | 4 (backup) | 1,000 |
| **Total** | | **9,200-9,700** |

---

## The Problem

With 5,000 starting XP and the XP income issues documented:

- A "viable" build costs ~9,000-10,000 XP
- Starting XP: 5,000
- **Gap: 4,000-5,000 XP needed from gameplay**

At 300ft depth (the reported struggle point):
- Descent XP to depth 6: ~750 XP
- Monster XP (estimate): 1,500-2,500 XP
- Total earned: ~2,250-3,250 XP
- **Still short by 1,000-2,000 XP**

---

## Impact of +30% XP Boost

### On Monster XP
- If monsters give 30% more, the ~2,000 XP from monsters becomes ~2,600 XP
- This adds ~600 XP by depth 300ft

### What +30% Solves
The boost helps close the gap:
- Current: 5,000 + 2,500 = 7,500 XP by depth 6
- With boost: 5,000 + 3,250 = 8,250 XP by depth 6

Still not quite enough for two maxed combat skills, but getting closer.

---

## Alternative: Skill Cost Reduction

Instead of or in addition to XP boost, could reduce skill costs:

### Option A: Flatten early costs
Current: 100, 200, 300, 400, 500...
Proposed: 100, 100, 200, 300, 400...

**Effect:** First 5 points cost 1,100 instead of 1,500 (saves 400 XP)

### Option B: Reduce multiplier
Current: `cost * 100`
Proposed: `cost * 80`

**Effect:** All skills 20% cheaper (equivalent to +25% XP)

### Option C: Free first point
Current: 1st point costs 100 XP
Proposed: 1st point is free

**Effect:** Enables more skill spread without heavy investment

---

## Recommendations

1. **+30% XP is a good start** but may not fully solve the problem
2. **Consider combining** +30% XP with slight skill cost reduction
3. **Track skill levels by depth** during playtesting to validate
4. **Target benchmarks:**
   - By depth 6 (300ft): Combined Melee + Evasion >= 14
   - By depth 10 (500ft): Primary combat skill at 10, secondary at 8
   - Will and Perception should be affordable "taxes" (4-5 each)
