# Exploration XP Design

## Document: DESIGN-003
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document designs optional exploration XP bonuses to further support stealth builds and exploration-focused play.

---

## Proposed Features

### Feature 1: Depth Milestone Bonuses (RECOMMENDED)

**Description:** Bonus XP for reaching significant depth milestones.

**Implementation:**

Current descent XP: `depth_level * 50`

Proposed addition: Extra bonus at every 100ft (every 2 depth levels)

| Depth | Current Descent XP | Proposed Bonus | Total |
|-------|-------------------|----------------|-------|
| 100ft | 150 | +100 | 250 |
| 200ft | 450 | +200 | 650 |
| 300ft | 900 | +300 | 1,200 |
| 400ft | 1,500 | +400 | 1,900 |
| 500ft | 2,250 | +500 | 2,750 |
| 600ft | 3,150 | +600 | 3,750 |

**Total bonus by 600ft:** +2,100 XP

**Implementation location:** `src/dungeon.c:2586-2602`

```c
/* Depth milestone bonus (every 100ft) */
if ((i % 2 == 0) && (i > 0))
{
    int milestone_bonus = (i / 2) * 100;
    gain_exp(milestone_bonus);
    /* Could track in p_ptr->milestone_exp if desired */
}
```

**Priority:** MEDIUM - Nice to have but +30% XP may be sufficient

---

### Feature 2: Stealth Bypass XP (OPTIONAL)

**Description:** XP for avoiding combat with detected enemies.

**Trigger:** When player descends stairs, check for monsters they saw but didn't kill.

**Amount:** 30% of would-have-been kill XP for each bypassed monster (first encounter only)

**Implementation concept:**

```c
/* In stair descent code */
for each monster seen this level:
    if monster is alive:
        bypass_xp += adjusted_mon_exp(monster, TRUE) * 30 / 100;
gain_exp(bypass_xp);
```

**Complexity:** MEDIUM - requires tracking seen-but-not-killed monsters

**Priority:** LOW - +30% XP should help stealth builds enough

---

### Feature 3: Exploration Percentage Bonus (NOT RECOMMENDED)

**Description:** XP for exploring a percentage of each floor.

**Issues:**
- Requires tile tracking
- Encourages tedious completionism
- Conflicts with stealth (must explore to get bonus)

**Priority:** DO NOT IMPLEMENT

---

### Feature 4: First Encounter Bonus (ALREADY EXISTS)

**Description:** XP for seeing monsters for the first time.

**Status:** Already implemented as "encounter XP"

**No changes needed.**

---

## Recommendation

### Primary: +30% XP Only

For the initial rebalance, rely solely on the +30% XP multiplier. This affects all XP sources including encounter XP, which already supports stealth builds.

### Secondary: Depth Milestones (If Needed)

If playtesting shows stealth builds still struggling:

1. Add depth milestone bonuses
2. Simple implementation, low risk
3. Provides ~15% additional XP by 600ft

### Deferred: Stealth Bypass XP

If stealth builds need more help after milestones:

1. Implement bypass XP tracking
2. More complex implementation
3. Consider for future patch

---

## Implementation Plan

### Phase 1: +30% XP (Current Release)

No exploration XP changes. Let the multiplier do the work.

### Phase 2: Depth Milestones (If Needed)

Add to `src/dungeon.c` after descent XP code:

```c
/* Track maximum dungeon level */
if (p_ptr->max_depth < p_ptr->depth)
{
    for (i = p_ptr->max_depth + 1; i <= p_ptr->depth; i++)
    {
        if (i > 1)
        {
            int new_exp = i * 50;
            gain_exp(new_exp);
            p_ptr->descent_exp += new_exp;

            /* Depth milestone bonus every 100ft (2 levels) */
            if ((i % 2 == 0))
            {
                int milestone = (i / 2) * 100;
                gain_exp(milestone);
                /* msg_format("Milestone bonus: %d XP", milestone); */
            }
        }
    }
    p_ptr->max_depth = p_ptr->depth;
}
```

### Phase 3: Stealth Bypass (Future)

Would require:
1. Tracking array for monsters seen per level
2. Hook in stair descent code
3. UI feedback for bypass XP earned

**Estimated effort:** 50-100 lines of code

---

## Testing Considerations

### Depth Milestones

Test that:
- Bonus only triggers on first visit to depth
- Bonus stacks properly with normal descent XP
- Going up and back down doesn't re-trigger bonus

### Stealth Bypass (If Implemented)

Test that:
- Only counts monsters seen by player
- Doesn't count monsters killed
- Doesn't count monsters never in LOS
- Works correctly when backtracking

---

## Summary

| Feature | Priority | Effort | Recommendation |
|---------|----------|--------|----------------|
| +30% XP Multiplier | HIGH | Low | IMPLEMENT NOW |
| Depth Milestones | MEDIUM | Low | MAYBE LATER |
| Stealth Bypass | LOW | Medium | FUTURE |
| Exploration % | NONE | High | DO NOT |

Start with the XP multiplier. Add milestones only if playtesting shows they're needed.
