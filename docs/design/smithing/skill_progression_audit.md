# Smithing Skill Progression Audit

## Document: AUDIT-002
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document maps what capabilities unlock at each Smithing skill level from 1-20.

---

## Ability Unlock Requirements

From `lib/edit/ability.txt`:

| Ability | Index | Level Req | Prerequisites | Effect |
|---------|-------|-----------|---------------|--------|
| Weaponsmith | SMT_WEAPONSMITH (0) | 2 | None | Create weapons |
| Armoursmith | SMT_ARMOURSMITH (1) | 3 | None | Create armor |
| Jeweller | SMT_JEWELLER (2) | 4 | None | Create rings, amulets, light |
| Reforge | SMT_REFORGE (3) | 5 | None | Combine Broken Glowing → Enchanted |
| Expertise | SMT_EXPERTISE (4) | 6 | Reforge | Halves time, negates XP/stat costs |
| Reclaim | SMT_RECLAIM (5) | 7 | Reforge | Combine Broken Strange → Artifact |
| Masterwork | SMT_MASTERWORK (6) | 8 | Reclaim | 4 Broken Strange → Best Artifact |
| Grace | (7) | 10 | None | +1 Grace stat |

---

## Skill Level Progression Table

### Levels 1-5: Basic Smithing

| Level | New Abilities | Capabilities | XP Cost (cumulative) |
|-------|---------------|--------------|----------------------|
| 1 | - | Can access forge (exploration mode) | 100 |
| 2 | Weaponsmith | Forge weapons | 300 |
| 3 | Armoursmith | Forge armor | 600 |
| 4 | Jeweller | Forge rings, amulets, lights | 1,000 |
| 5 | Reforge | Combine Broken Glowing items | 1,500 |

### Levels 6-10: Advanced Smithing

| Level | New Abilities | Capabilities | XP Cost (cumulative) |
|-------|---------------|--------------|----------------------|
| 6 | Expertise | No XP/stat costs, faster forging | 2,100 |
| 7 | Reclaim | Combine Broken Strange → Random Artifact | 2,800 |
| 8 | Masterwork | 4 Broken Strange → Best Artifact | 3,600 |
| 9 | - | Higher difficulty items affordable | 4,500 |
| 10 | Grace | +1 Grace stat | 5,500 |

### Levels 11-15: Expert Smithing

| Level | New Abilities | Capabilities | XP Cost (cumulative) |
|-------|---------------|--------------|----------------------|
| 11 | - | Higher base difficulty threshold | 6,600 |
| 12 | - | - | 7,800 |
| 13 | - | - | 9,100 |
| 14 | - | - | 10,500 |
| 15 | - | - | 12,000 |

### Levels 16-20: Master Smithing

| Level | New Abilities | Capabilities | XP Cost (cumulative) |
|-------|---------------|--------------|----------------------|
| 16 | - | - | 13,600 |
| 17 | - | - | 15,300 |
| 18 | - | - | 17,100 |
| 19 | - | - | 19,000 |
| 20 | - | - | 21,000 |

---

## The Smithing Cliff

**Critical Finding:** No new abilities unlock after level 10 (Grace).

From levels 11-20, players only gain:
- Higher effective skill for difficulty calculations
- Ability to craft higher-difficulty items
- Reduced smithing skill drain on masterwork items

**This is the "Smithing cliff"** - there is no compelling reason to invest past level 10 unless attempting very difficult items.

---

## Effective Smithing Skill

The actual smithing capability is:
```
effective_skill = skill_base[S_SMT] + forge_bonus
```

Where forge_bonus is:
- Normal forge: +0
- Shadow forge: +3
- Unique forge (Angdur): +7

**With Angdur:**
- Smithing 10 + 7 = effective 17
- Smithing 15 + 7 = effective 22

This makes high smithing skill less necessary if you can find Angdur.

---

## Difficulty System

**Location:** `src/cmd4.c:2913-3490` - `object_difficulty()`

Item difficulty is calculated from:
- Base item level
- Weight modifiers
- Attack bonus
- Damage dice
- Evasion bonus
- Protection dice
- Special properties (slay, brand, resist, etc.)

If difficulty > (skill + forge_bonus):
- Item requires smithing skill drain
- Masterwork ability allows crafting with drain

---

## What High Smithing Unlocks

### Currently (levels 11-20)

1. **Higher base difficulty threshold** - can attempt more powerful items
2. **Less skill drain** - difficult items cost less smithing skill
3. **Better masterwork success** - larger gap between skill and difficulty = less drain

### What's Missing

No unique high-level rewards for:
- Double enchantments
- Special resistances
- Artifact modification
- Unique properties
- Cost reductions

---

## Ability Cost Analysis

To get all smithing abilities (at minimum level):

| Ability | Skill Level | Ability Cost | Total |
|---------|-------------|--------------|-------|
| Weaponsmith | 2 | 500 | 500 |
| Armoursmith | 3 | 1000 | 1500 |
| Jeweller | 4 | 1500 | 3000 |
| Reforge | 5 | 2000 | 5000 |
| Expertise | 6 | 2500 | 7500 |
| Reclaim | 7 | 3000 | 10500 |
| Masterwork | 8 | 3500 | 14000 |
| Grace | 10 | 4500 | 18500 |

Plus skill points: 5,500 XP for Smithing 10

**Total to max meaningful smithing:** ~24,000 XP

---

## Recommendations

### Add High-Level Rewards

**Level 12:** Double Enchantment
- Allow two ego properties on single item
- Requires both enchants to be compatible

**Level 15:** Resistance Crafting
- Can add resistance properties
- Limited to 1-2 per item

**Level 18:** Artifact Enhancement
- Can modify existing artifacts
- Add properties or improve stats

**Level 20:** Master Smith
- Unique title/achievement
- Access to legendary recipes
- Can exceed normal stat caps

### Add XP Cost Discount

Higher smithing should reduce XP costs:
- Level 10: 10% discount
- Level 15: 25% discount
- Level 20: 50% discount

This makes continued investment valuable.
