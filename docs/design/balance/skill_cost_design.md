# Skill Cost Adjustment Design

## Document: DESIGN-002
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document evaluates whether skill costs need adjustment in addition to the +30% XP boost.

---

## Current Skill Costs

Formula: nth point costs `100 * n` XP

| Level | Cost | Cumulative |
|-------|------|------------|
| 1 | 100 | 100 |
| 2 | 200 | 300 |
| 3 | 300 | 600 |
| 4 | 400 | 1,000 |
| 5 | 500 | 1,500 |
| 6 | 600 | 2,100 |
| 7 | 700 | 2,800 |
| 8 | 800 | 3,600 |
| 9 | 900 | 4,500 |
| 10 | 1,000 | 5,500 |

---

## Analysis: Is XP Boost Sufficient?

### With +30% XP Boost

Based on AUDIT-005 projections:

| Depth | Current XP | +30% XP | Affordable Skills |
|-------|------------|---------|-------------------|
| 300ft | 9,280 | 12,064 | Melee 8 + Eva 8 + Will 5 + Per 3 |
| 450ft | 13,170 | 17,121 | Melee 10 + Eva 9 + Will 6 + Per 5 |
| 600ft | 18,090 | 23,517 | Melee 12 + Eva 10 + Will 7 + Per 6 |

This looks viable. The +30% boost alone should provide enough XP for competitive builds.

### Comparison to Target

| Depth | +30% XP Available | Target Build Cost | Margin |
|-------|-------------------|-------------------|--------|
| 300ft | 12,064 | 9,200 | +2,864 (for abilities) |
| 450ft | 17,121 | 13,500 | +3,621 (for abilities) |
| 600ft | 23,517 | 18,000 | +5,517 (for abilities) |

**Conclusion:** +30% XP appears sufficient without modifying skill costs.

---

## Optional Enhancements

If playtesting reveals skill costs are still problematic, consider:

### Option A: Cheaper First Points

**Current:** 1st point = 100, 2nd = 200, 3rd = 300...

**Proposed:** 1st point = 50, 2nd = 100, 3rd = 200, 4th = 300...

**Effect:** Saves 150 XP per skill = 1,200 XP total for 8 skills

**Pros:**
- Enables more skill spread
- Helps early game exploration

**Cons:**
- Changes fundamental progression feel
- May make early game too easy

**Verdict:** NOT NEEDED with +30% XP

---

### Option B: Reduced Multiplier

**Current:** Cost = `n * 100`

**Proposed:** Cost = `n * 80`

**Effect:**
- Level 8 skill: 2,880 XP (vs 3,600)
- Saves 720 XP per primary skill

**Pros:**
- Proportional reduction
- All skills cheaper

**Cons:**
- Changes feel of progression
- Compounds with XP boost

**Verdict:** OVER-CORRECTION with +30% XP

---

### Option C: Free First Point in Each Skill

**Proposed:** First point of any skill is free (costs 0)

**Effect:** Saves 800 XP total (8 skills × 100)

**Pros:**
- Encourages skill experimentation
- Helps with "survival tax" skills (Will, Perception)

**Cons:**
- Small impact overall
- May feel inconsistent

**Verdict:** INTERESTING but minor impact

---

### Option D: Increased Affinity Discount (Ability Costs)

**Current:** Affinity saves 500 XP per ability

**Proposed:** Affinity saves 750 XP per ability

**Effect:**
- With 2 affinities: first 2 abilities free, 3rd costs 750
- Makes racial/house choice more impactful

**Pros:**
- Rewards character building
- Doesn't change core skill costs

**Cons:**
- Only helps abilities, not skills
- Minimal overall impact

**Verdict:** POSSIBLE enhancement for later

---

## Recommendation

### Primary: +30% XP Only (No Skill Cost Changes)

Based on analysis, the +30% XP boost alone should be sufficient to solve the progression problem. Skill costs should remain unchanged for now.

**Rationale:**
1. The triangular skill cost curve is a core game mechanic
2. +30% XP provides adequate margin for builds
3. Changing skill costs risks over-correction
4. Easier to tune one variable (XP) than two

### Secondary: Monitor These Metrics

During playtesting, watch for:

1. **First 3 points feel expensive** → Consider Option A
2. **Can't afford backup skills** → Consider Option C
3. **Abilities feel unaffordable** → Consider Option D
4. **Still XP-starved at 300ft** → Increase XP multiplier to 140%

---

## Implementation

### For This Release

**No skill cost changes.** Apply +30% XP multiplier only.

### For Future Consideration

If +30% proves insufficient:

1. First try increasing XP to +40%
2. Then consider Option C (free first point)
3. Avoid Options A and B (change core progression)

---

## Code Location Reference

If skill cost changes are ever needed:

**File:** `src/birth.c:1740-1745`

```c
static int skill_cost(int base, int points)
{
    int total_cost = (points + base) * (points + base + 1) / 2;
    int prev_cost = (base) * (base + 1) / 2;
    return ((total_cost - prev_cost) * 100);  // Change 100 to adjust
}
```

Ability costs are in `src/cmd4.c:1411-1416`.
