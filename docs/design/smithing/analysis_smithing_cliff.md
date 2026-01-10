# Analysis: The Smithing Cliff

## Document: ANALYSIS-001
## Version: 1.0
## Date: 2026-01-10

---

## Problem Statement

After Smithing level 10 (Grace ability), players have no new abilities or meaningful rewards for continued skill investment. This creates a "cliff" where the return on investment drops dramatically.

---

## Current Ability Unlock Schedule

| Level | Ability | Value Added |
|-------|---------|-------------|
| 2 | Weaponsmith | HIGH - Core functionality |
| 3 | Armoursmith | HIGH - Core functionality |
| 4 | Jeweller | HIGH - Core functionality + auto-ID |
| 5 | Reforge | HIGH - Broken item recycling |
| 6 | Expertise | VERY HIGH - Cost elimination |
| 7 | Reclaim | VERY HIGH - Artifact creation |
| 8 | Masterwork | VERY HIGH - Best artifacts |
| 9 | (none) | LOW - Difficulty threshold only |
| 10 | Grace | MEDIUM - +1 stat |
| 11-20 | (none) | LOW - Difficulty threshold only |

---

## The Cliff Visualization

```
VALUE
  ^
  |    ****
  |   *    *
  |  *      **
  | *          *
  |*             ****************************
  +-----------------------------------------> LEVEL
    2  3  4  5  6  7  8  9  10 11 12 ... 20
         |<-- Sweet Spot -->|<-- Cliff -->|
```

---

## What High Smithing (11-20) Currently Provides

### 1. Higher Difficulty Threshold

**Effect:** Can attempt more difficult items without skill drain
**Value:** Situational

| Smithing | Max Difficulty (base) | With Angdur (+7) |
|----------|----------------------|------------------|
| 10 | 10 | 17 |
| 15 | 15 | 22 |
| 20 | 20 | 27 |

Most items don't require difficulty above 17, making 20+ unnecessary.

### 2. Reduced Skill Drain

**Effect:** When crafting items above your skill level, less permanent skill loss
**Value:** Low - Players avoid skill drain situations anyway

### 3. Better Masterwork Success

**Effect:** Larger gap between skill and difficulty = less drain
**Value:** Low - Masterwork already works well at level 8

---

## Why This Is a Problem

### 1. Dead XP Investment

XP spent on Smithing 11-20 provides almost no benefit:
- No new abilities unlock
- No new item types available
- No meaningful power increase

**XP "wasted" on Smithing 11-20:** 15,500 XP (from 5,500 to 21,000)

### 2. Skill Identity Crisis

At high levels, Smithing becomes:
- Just a number for difficulty checks
- No unique identity or playstyle
- Feels incomplete compared to combat skills

### 3. Player Psychology

Players who enjoy smithing want:
- Continued progression
- New capabilities at high levels
- Recognition of mastery

Currently: Reaching Smithing 20 feels no different from Smithing 10.

---

## Comparison to Other Skills

### Combat Skills (Melee/Evasion)

| Level | Melee Value | Evasion Value |
|-------|-------------|---------------|
| 1-8 | New abilities every 1-2 levels | New abilities every 1-2 levels |
| 9-15 | Continued ability unlocks | Continued ability unlocks |
| 16-20 | Advanced abilities, capstone | Advanced abilities, capstone |

Combat skills have meaningful rewards throughout the entire range.

### Smithing

| Level | Smithing Value |
|-------|----------------|
| 1-8 | New abilities every 1-2 levels |
| 9-10 | One ability (Grace) |
| 11-20 | Nothing |

Smithing has a 10-level gap with no rewards.

---

## Root Cause Analysis

### Historical Context

1. **Original Sil Design:** Smithing was capped lower, less emphasis
2. **Sil-Q Expansion:** Added Reforge/Reclaim/Masterwork but stopped at 8
3. **Grace at 10:** Only non-smithing reward in the tree
4. **No Vision for 11-20:** Never designed for high-level smithing

### Design Oversight

The Sil-Q changes focused on:
- Early/mid-game smithing improvements
- Broken item system
- Cost rebalancing

But neglected:
- High-level smithing identity
- Master smith fantasy fulfillment
- Endgame crafting goals

---

## Impact Assessment

### On Player Builds

**Smith-focused builds:**
- Stop at Smithing 8-10
- No reason to continue investment
- Feel incomplete

**Hybrid builds:**
- Never consider Smithing above 5-7
- Miss out on smithing identity

### On Game Balance

**Currently:**
- High Smithing is a "trap" investment
- XP is better spent on combat skills after level 10
- Dedicated smiths are penalized

**Should be:**
- High Smithing provides unique advantages
- Investment scales meaningfully
- Master smith is a viable endgame identity

---

## Proposed Solutions

### Option A: New Abilities at 12, 15, 18, 20

| Level | Ability | Effect |
|-------|---------|--------|
| 12 | Double Enchant | Apply two ego types to one item |
| 15 | Resistance Master | Can add resistance properties |
| 18 | Artifact Enhancement | Modify existing artifacts |
| 20 | Legendary Smith | Exceed normal stat caps |

**Pros:** Fills the void, provides clear goals
**Cons:** Significant implementation effort

### Option B: Scaling Discounts

| Level | XP Cost Reduction |
|-------|------------------|
| 10 | 10% |
| 12 | 20% |
| 15 | 35% |
| 18 | 50% |
| 20 | 65% |

**Pros:** Simple implementation
**Cons:** Doesn't provide new capabilities, feels passive

### Option C: Quality Bonuses

| Level | Effect |
|-------|--------|
| 12 | +1 to random stat on crafted items |
| 15 | +2 to random stat on crafted items |
| 18 | Choose which stat gets bonus |
| 20 | +3 to chosen stat on crafted items |

**Pros:** Meaningful but not ability-based
**Cons:** May be too random/weak

### Option D: Combination Approach

- **Level 12:** Double Enchant (ability)
- **Level 14:** 25% XP cost reduction (passive)
- **Level 16:** Resistance Crafting (ability)
- **Level 18:** 50% XP cost reduction (passive)
- **Level 20:** Master Smith title + unique recipes (ability)

**Pros:** Mixes abilities and passive bonuses
**Cons:** Most complex to implement

---

## Recommendation

**Implement Option D (Combination Approach)**

This provides:
1. Clear milestones every 2 levels
2. Mix of active abilities and passive bonuses
3. Compelling reason to invest to 20
4. Master Smith fantasy fulfillment

### Implementation Priority

1. **HIGH:** Add Double Enchant at level 12
   - Most requested feature
   - Enables unique builds
   - Moderate implementation complexity

2. **MEDIUM:** Add Resistance Crafting at level 16
   - Fills gap in crafting options
   - Valuable for survival builds

3. **MEDIUM:** Add XP cost reductions at 14, 18
   - Simple to implement
   - Immediate value

4. **LOW:** Add Master Smith at level 20
   - Capstone ability
   - Can be designed later

---

## Success Metrics

After implementation, measure:

1. **Player investment:** Do players invest beyond level 10?
2. **Build diversity:** Are smith-focused builds viable?
3. **Satisfaction:** Do players feel rewarded for high Smithing?

**Target:**
- 30%+ of smithing characters should reach level 12
- 10%+ should reach level 20
- Player feedback should be positive about high-level rewards
