# Design: XP Cost Structure

## Document: DESIGN-001
## Version: 1.0
## Date: 2026-01-10

---

## Design Goals

1. **Preserve XP economy** - Smithing costs should matter throughout the game
2. **Reward investment** - Higher Smithing skill should provide discounts
3. **Maintain balance** - Reforge/Reclaim/Masterwork should be valuable but not broken
4. **Fix Expertise** - Ability should enhance, not eliminate costs

---

## Current State Summary

### Forge Action Costs

| Action | Current Cost | Notes |
|--------|--------------|-------|
| Reforge | 500 XP flat | Slightly undercosted |
| Reclaim | level × 50 XP | Well balanced |
| Masterwork | level × 100 XP | Slightly undercosted |

### Expertise Effect

**Current:** "negates all experience and stat costs"
**Problem:** Completely eliminates XP economy after acquisition

---

## Proposed Changes

### 1. Adjust Base Costs

#### Reforge: 500 → 600 XP

**Rationale:**
- Average enchanted item worth ~1000 XP equivalent
- Current 500 XP is slightly too cheap
- 600 XP maintains value while being fairer

**Implementation:** Change hardcoded value in `reforge_menu()` (cmd4.c:6173)

```c
/* Before */
if (p_ptr->new_exp >= 500)
{
    p_ptr->new_exp -= 500;
}

/* After */
if (p_ptr->new_exp >= 600)
{
    p_ptr->new_exp -= 600;
}
```

#### Reclaim: Keep level × 50 XP

**Rationale:**
- Current scaling is appropriate
- Artifact value scales with level
- No change needed

#### Masterwork: level × 100 → level × 125 XP

**Rationale:**
- Best artifact is worth significantly more than random
- Premium pricing reflects guaranteed quality
- Still affordable with 4 broken strange investment

**Implementation:** Change multiplier in `masterwork_menu()` (cmd4.c:6567)

```c
/* Before */
int xp_cost = a_ptr->level * 100;

/* After */
int xp_cost = a_ptr->level * 125;
```

---

### 2. Rework Expertise

#### Current Description

```
D:Reduces the time taken to forge an item by half and
D: negates all experience and stat costs.
```

#### Proposed Description

```
D:Reduces the time taken to forge an item by half and
D: reduces all experience and stat costs by 50%.
```

#### Implementation

**File:** src/cmd4.c

Need to add expertise check to cost deduction:

```c
/* Apply Expertise discount if player has the ability */
#define SMT_EXPERTISE 4  /* From defines.h */

int apply_expertise_discount(int base_cost)
{
    if (p_ptr->active_ability[S_SMT][SMT_EXPERTISE])
    {
        return base_cost / 2;  /* 50% reduction */
    }
    return base_cost;
}

/* In reforge_menu() */
int xp_cost = apply_expertise_discount(600);
if (p_ptr->new_exp >= xp_cost)
{
    p_ptr->new_exp -= xp_cost;
}

/* In reclaim_menu() */
int xp_cost = apply_expertise_discount(a_ptr->level * 50);

/* In masterwork_menu() */
int xp_cost = apply_expertise_discount(a_ptr->level * 125);
```

---

### 3. Add Skill-Based Discount

#### Concept

Higher Smithing skill provides additional XP cost reduction:
- 2% discount per Smithing level above 8
- Stacks with Expertise

#### Formula

```
final_cost = base_cost × (1 - skill_discount) × (1 - expertise_discount)

Where:
- skill_discount = max(0, (smithing_level - 8) × 0.02)
- expertise_discount = 0.50 if has Expertise, 0 otherwise
```

#### Discount Table

| Smithing Level | Skill Discount | With Expertise | Effective Total |
|----------------|----------------|----------------|-----------------|
| 8 | 0% | 50% | 50% |
| 10 | 4% | 50% | 52% |
| 12 | 8% | 50% | 54% |
| 15 | 14% | 50% | 57% |
| 18 | 20% | 50% | 60% |
| 20 | 24% | 50% | 62% |

#### Implementation

```c
int calculate_smithing_discount(int base_cost)
{
    int cost = base_cost;
    int skill = p_ptr->skill_base[S_SMT];

    /* Skill-based discount: 2% per level above 8 */
    if (skill > 8)
    {
        int skill_discount = (skill - 8) * 2;
        cost = cost * (100 - skill_discount) / 100;
    }

    /* Expertise discount: 50% */
    if (p_ptr->active_ability[S_SMT][SMT_EXPERTISE])
    {
        cost = cost / 2;
    }

    return cost;
}
```

---

## Cost Examples (After Changes)

### Reforge (base 600 XP)

| Scenario | Calculation | Final Cost |
|----------|-------------|------------|
| Smithing 5, no Expertise | 600 | 600 |
| Smithing 8, no Expertise | 600 | 600 |
| Smithing 8, with Expertise | 600 × 0.50 | 300 |
| Smithing 12, with Expertise | 600 × 0.92 × 0.50 | 276 |
| Smithing 20, with Expertise | 600 × 0.76 × 0.50 | 228 |

### Reclaim (level 15 artifact = 750 XP base)

| Scenario | Calculation | Final Cost |
|----------|-------------|------------|
| Smithing 7, no Expertise | 750 | 750 |
| Smithing 8, with Expertise | 750 × 0.50 | 375 |
| Smithing 12, with Expertise | 750 × 0.92 × 0.50 | 345 |
| Smithing 20, with Expertise | 750 × 0.76 × 0.50 | 285 |

### Masterwork (level 15 artifact = 1875 XP base)

| Scenario | Calculation | Final Cost |
|----------|-------------|------------|
| Smithing 8, no Expertise | 1875 | 1875 |
| Smithing 8, with Expertise | 1875 × 0.50 | 937 |
| Smithing 15, with Expertise | 1875 × 0.86 × 0.50 | 806 |
| Smithing 20, with Expertise | 1875 × 0.76 × 0.50 | 712 |

---

## Balance Verification

### Break-Even Analysis (After Changes)

**Reforge:**
- Cost: 600 XP (without Expertise), 300 XP (with Expertise)
- Value: ~1000 XP equivalent
- ROI: 67% (without), 233% (with)
- Verdict: Still profitable, less exploitable

**Reclaim:**
- Cost: 375-750 XP (with Expertise, level 10-20 artifacts)
- Value: ~2000-5000 XP equivalent
- ROI: 167-566%
- Verdict: Strong but not broken

**Masterwork:**
- Cost: 625-1562 XP (with Expertise, level 10-25 artifacts)
- Value: ~5000-10000 XP equivalent
- ROI: 220-540%
- Verdict: Premium but worthwhile

### High-Level Smithing Value

With new skill-based discount, Smithing 11-20 provides:
- 2-24% additional discount on all forge actions
- Incentive to continue investing past level 10
- Compounds with Expertise

---

## UI Changes

### Display Costs Before Action

Add cost preview to Reforge/Reclaim/Masterwork menus:

```
Reforge this item?
XP Cost: 300 (600 base - 50% Expertise)
Press 'y' to confirm, 'n' to cancel
```

### Display Discount Information

In forge menu, show current discount rate:

```
Smithing Skill: 12
Expertise: Active
Total Discount: 54%
```

---

## Summary of Changes

### Code Changes Required

| Location | Change |
|----------|--------|
| cmd4.c:6173 | Reforge cost: 500 → 600 |
| cmd4.c:6567 | Masterwork multiplier: 100 → 125 |
| cmd4.c (new) | Add `calculate_smithing_discount()` function |
| cmd4.c:6173 | Apply discount to Reforge |
| cmd4.c:6367 | Apply discount to Reclaim |
| cmd4.c:6567 | Apply discount to Masterwork |
| ability.txt | Update Expertise description |

### Data File Changes

**lib/edit/ability.txt line 617-623:**

```
# Before
N:124:Expertise
I:6:4:6
P:6/3
D:Reduces the time taken to forge an item by half and
D: negates all experience and stat costs.

# After
N:124:Expertise
I:6:4:6
P:6/3
D:Reduces the time taken to forge an item by half and
D: reduces all experience and stat costs by 50%.
```

---

## Risk Assessment

### Potential Issues

1. **Existing saves:** Players with Expertise may feel nerfed
   - Mitigation: Clear changelog, fair warning

2. **Balance overshoot:** Changes may make smithing too expensive
   - Mitigation: Monitor feedback, adjust values if needed

3. **Complexity:** Multiple discount sources may confuse players
   - Mitigation: Clear UI display of final costs

### Testing Requirements

1. Verify Reforge works with new cost
2. Verify Reclaim works with new cost
3. Verify Masterwork works with new cost
4. Verify Expertise applies 50% (not 100%)
5. Verify skill-based discount applies correctly
6. Verify discounts stack properly
7. Verify UI displays costs correctly
