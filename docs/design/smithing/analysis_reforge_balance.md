# Analysis: Reforge/Reclaim/Masterwork Balance

## Document: ANALYSIS-003
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document evaluates the balance of the three broken item conversion abilities: Reforge, Reclaim, and Masterwork.

---

## Current Implementation Summary

| Ability | Input | Output | XP Cost | Ability Req |
|---------|-------|--------|---------|-------------|
| Reforge | 2 Broken Glowing | Random enchanted | 500 | Smithing 5 |
| Reclaim | 2 Broken Strange | Random artifact | level × 50 | Smithing 7 |
| Masterwork | 4 Broken Strange | Best artifact | level × 100 | Smithing 8 |

---

## Reforge Analysis

### Input: Broken Glowing Items

| Item | K_IDX | Use |
|------|-------|-----|
| Broken Glowing Weapon | 491 | Weapons only |
| Shattered Elven Mail | 492 | Armor only |

**Drop rate:** Uncommon (3-5 per 1000ft)
**Availability:** Sufficient for 1-2 Reforges per game section

### Output: Random Enchanted Items

**Process:**
1. Player selects category (weapon type or armor type)
2. Random sval selected via `pick_random_sval()`
3. Random ego applied via `pick_random_ego()`

**Quality variance:** HIGH
- Could get excellent ego (of Gondolin, of Erebor)
- Could get mediocre ego (of Stealth on wrong item)
- Could get cursed ego (of Fury, Vampiric)

### Cost Assessment: 500 XP Flat

**Pros:**
- Simple, predictable
- Encourages use of broken items
- Not prohibitive

**Cons:**
- Doesn't scale with output quality
- May be too cheap for excellent results
- May feel expensive for poor results

### Balance Verdict: SLIGHTLY UNDERCOSTED

**Reasoning:**
- Average enchanted item value: ~750-1000 XP equivalent
- Cost: 500 XP + 2 broken items
- Net gain: ~250-500 XP per use

**Recommendation:** Consider 600-750 XP cost, or make cost vary by selected category.

---

## Reclaim Analysis

### Input: Broken Strange Items

| Item | K_IDX | Use |
|------|-------|-----|
| Broken Strange Weapon | 493 | Weapon artifacts |
| Twisted Shadow-plate | 494 | Armor artifacts |
| Broken Strange Jewelry | 495 | Jewelry artifacts |

**Drop rate:** Rare (1-2 per 1000ft for weapons/armor, 0-1 for jewelry)
**Availability:** Limited - expect 2-4 per full game

### Output: Random Artifact

**Process:**
1. Player selects category (weapon/armor/jewelry)
2. Player selects type or "any"
3. `pick_random_artifact(tval_list, FALSE)` selects artifact
4. FALSE = not best, just random eligible

**Quality variance:** VERY HIGH
- Could get powerful artifact (Ringil, Orcrist)
- Could get weak artifact (minor jewelry)
- Completely random within type

### Cost Assessment: level × 50

**Examples:**
| Artifact Level | XP Cost |
|----------------|---------|
| 5 | 250 |
| 10 | 500 |
| 15 | 750 |
| 20 | 1000 |

**Pros:**
- Scales with artifact power
- Higher level = more expensive = balanced
- Not cost-prohibitive

**Cons:**
- Player doesn't know cost until after selection
- Random selection may produce unwanted artifact
- Could get low-level artifact despite high investment

### Balance Verdict: WELL BALANCED

**Reasoning:**
- Artifact value: ~2000-5000 XP equivalent
- Cost: 250-1000 XP + 2 broken strange
- Net gain: ~1000-4000 XP per use (varies widely)

**Recommendation:** Keep current formula. Consider showing expected cost range before selection.

---

## Masterwork Analysis

### Input: 4 Broken Strange Items

**Requirement:** 4 of the same type (weapon OR armor OR jewelry)
**Availability:** Very limited - may only happen 0-1 times per game

### Output: Best Artifact of Type

**Process:**
1. Player selects category
2. Player selects type or "any"
3. `pick_random_artifact(tval_list, TRUE)` selects artifact
4. TRUE = best artifact in category

**Quality variance:** LOW (controlled)
- Guaranteed best artifact of selected type
- Much more predictable than Reclaim
- Player has some control via type selection

### Cost Assessment: level × 100

**Examples:**
| Artifact Level | XP Cost |
|----------------|---------|
| 10 | 1000 |
| 15 | 1500 |
| 20 | 2000 |

**Pros:**
- Scales with artifact power
- Significantly more expensive than Reclaim
- Reflects guaranteed quality

**Cons:**
- May still feel cheap for "best artifact"
- 4 broken strange is already expensive
- High-level artifacts could cost more

### Balance Verdict: SLIGHTLY UNDERCOSTED

**Reasoning:**
- Best artifact value: ~5000-10000 XP equivalent
- Cost: 1000-2000 XP + 4 broken strange
- Net gain: ~3000-8000 XP per use

**Recommendation:** Consider level × 150 or adding flat component (level × 100 + 500).

---

## The Expertise Problem

### Current Expertise Effect

**Location:** ability.txt line 617-623
**Effect:** "negates all experience and stat costs"

### Impact on Reforge/Reclaim/Masterwork

If Expertise eliminates XP costs:

| Ability | Cost Before Expertise | Cost After Expertise |
|---------|----------------------|---------------------|
| Reforge | 500 XP | 0 XP |
| Reclaim | level × 50 | 0 XP |
| Masterwork | level × 100 | 0 XP |

### Balance Impact: SEVERELY BROKEN

**Problem:**
- Single investment (Smithing 6 + Expertise) unlocks unlimited free uses
- Breaks the XP economy completely
- Removes all cost-based balance decisions

**Evidence:**
- Investment to get Expertise: ~3,600 XP
- Break-even: ~7 Reforges OR ~4 Reclaims OR ~2 Masterworks
- After break-even: Infinite value

### Recommendation: NERF EXPERTISE

**Options:**

**Option A: Partial reduction (Recommended)**
- Change to: "Reduces XP costs by 50%"
- Reforge: 250 XP
- Reclaim: level × 25
- Masterwork: level × 50

**Option B: Cap-based reduction**
- Change to: "Reduces XP costs by up to 500 XP"
- Reforge: 0 XP (capped)
- Reclaim: max(0, level × 50 - 500)
- Masterwork: max(0, level × 100 - 500)

**Option C: Time-based only**
- Change to: "Halves forge time only"
- Remove XP cost reduction entirely
- Preserves economy, expertise still useful

---

## Comparative Balance Table

| Metric | Reforge | Reclaim | Masterwork |
|--------|---------|---------|------------|
| Input rarity | Uncommon | Rare | Very rare |
| Output quality | Variable | Random artifact | Best artifact |
| XP cost | 500 | level × 50 | level × 100 |
| Uses per game | 3-5 | 1-2 | 0-1 |
| Net value | +250-500 | +1000-4000 | +3000-8000 |
| Risk | Medium | High | Low |
| Balance | Slightly under | Good | Slightly under |

---

## Drop Rate Impact

### If Broken Items Are Common

- Reforge becomes very strong (too many enchanted items)
- Reclaim becomes reliable (artifacts abundant)
- Masterwork becomes regular (best artifacts trivial)
- **Result:** Smithing overpowered

### If Broken Items Are Rare (Current)

- Reforge is situational (good when available)
- Reclaim is a highlight (exciting when possible)
- Masterwork is rare achievement (memorable)
- **Result:** Smithing balanced but RNG-dependent

### Recommendation: Maintain Current Drop Rates

The rarity of broken items is a key balance lever. Keep them scarce to preserve the excitement and value of conversion abilities.

---

## Recommendations Summary

### Immediate Fixes

1. **Nerf Expertise** - Reduce to 50% cost reduction, not elimination
2. **Show costs before action** - Display expected XP cost range in menu

### Balance Adjustments

3. **Reforge cost** - Consider increasing to 600-750 XP
4. **Masterwork cost** - Consider level × 150 or level × 100 + 500

### Quality of Life

5. **Display artifact options** - Show which artifacts are possible before selecting
6. **Confirm XP cost** - Prompt before spending XP on Reclaim/Masterwork

### Long-term Considerations

7. **Broken item drop tuning** - Monitor and adjust if needed
8. **High-level scaling** - Consider Smithing skill affecting costs at high levels

---

## Final Balance Assessment

| Component | Current State | Recommendation |
|-----------|---------------|----------------|
| Reforge | Good | Minor cost increase |
| Reclaim | Balanced | Keep as-is |
| Masterwork | Good | Minor cost increase |
| Expertise | Broken | Major nerf required |
| Drop rates | Appropriate | Monitor only |
| XP economy | At risk | Fix Expertise first |
