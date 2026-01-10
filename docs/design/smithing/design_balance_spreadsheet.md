# Design: Smithing Balance Spreadsheet

## Document: DESIGN-005
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document provides comprehensive balance tables for the smithing system redesign.

---

## Ability Costs and Requirements

### Smithing Ability Investment Table

| Ability | Skill Req | Prereq | Est. Ability XP | Cumulative XP |
|---------|-----------|--------|-----------------|---------------|
| Weaponsmith | 2 | - | 500 | 800 |
| Armoursmith | 3 | - | 750 | 1,350 |
| Jeweller | 4 | - | 1,000 | 2,000 |
| Reforge | 5 | - | 1,250 | 2,750 |
| Expertise | 6 | Reforge | 1,500 | 3,600 |
| Reclaim | 7 | Reforge | 1,750 | 4,550 |
| Masterwork | 8 | Reclaim | 2,000 | 5,600 |
| Grace | 10 | - | 2,500 | 8,000 |
| Double Enchant | 12 | Reforge | 3,000 | 10,800 |
| Efficient Smith | 14 | Double | 3,500 | 14,100 |
| Resistance Craft | 16 | Double | 4,000 | 17,900 |
| Greater Efficiency | 18 | Efficient | 4,500 | 22,200 |
| Master Smith | 20 | Grace | 5,000 | 26,000 |

---

## Forge Action Economics

### Reforge (Base Cost: 600 XP)

| Scenario | Discount | Final Cost | ROI |
|----------|----------|------------|-----|
| Base (Smithing 5) | 0% | 600 | 67% |
| + Expertise | 50% | 300 | 233% |
| + Efficient | 62.5% | 225 | 344% |
| + Greater Eff | 72% | 168 | 495% |

### Reclaim (Base Cost: level × 50)

| Art Level | Base Cost | +Expertise | +Efficient | +Greater |
|-----------|-----------|------------|------------|----------|
| 5 | 250 | 125 | 94 | 70 |
| 10 | 500 | 250 | 188 | 140 |
| 15 | 750 | 375 | 281 | 210 |
| 20 | 1000 | 500 | 375 | 280 |

### Masterwork (Base Cost: level × 125)

| Art Level | Base Cost | +Expertise | +Efficient | +Greater |
|-----------|-----------|------------|------------|----------|
| 10 | 1250 | 625 | 469 | 350 |
| 15 | 1875 | 938 | 703 | 525 |
| 20 | 2500 | 1250 | 938 | 700 |
| 25 | 3125 | 1563 | 1172 | 875 |

---

## Comparative Skill Investment

### 5,000 XP Budget Options

| Build | Skills | Combat Power | Crafting Power |
|-------|--------|--------------|----------------|
| Combat Focus | M8, E4, W2 | HIGH | NONE |
| Hybrid Light | M6, E5, S5 | MEDIUM | Reforge |
| Hybrid Heavy | M5, E4, S7 | LOW-MED | Reclaim |
| Smith Focus | M4, E4, S8 | LOW | Masterwork |

### 10,000 XP Budget Options

| Build | Skills | Combat Power | Crafting Power |
|-------|--------|--------------|----------------|
| Combat Max | M10, E8, W4 | VERY HIGH | NONE |
| Balanced | M7, E6, S7, W3 | HIGH | Reclaim |
| Smith Expert | M5, E5, S10, W2 | MEDIUM | Grace + All |
| Master Smith | M4, E4, S12 | LOW-MED | Double Enchant |

### 20,000 XP Budget Options

| Build | Skills | Combat Power | Crafting Power |
|-------|--------|--------------|----------------|
| Combat Legend | M15, E12, W8, P5 | MAXIMUM | NONE |
| Hybrid Master | M10, E8, S10, W4 | VERY HIGH | Grace + All |
| Smith Legend | M6, E6, S18, W4 | MEDIUM | Greater Eff |
| True Master | M5, E5, S20, W3 | MEDIUM | Master Smith |

---

## Break-Even Analysis

### When Does Smithing Pay Off?

| Investment | Break-Even Uses | Typical Game Uses | Verdict |
|------------|-----------------|-------------------|---------|
| Smithing 5 (Reforge) | 2 Reforges | 3-5 | GOOD |
| Smithing 7 (Reclaim) | 1 Reclaim | 1-2 | EXCELLENT |
| Smithing 8 (Masterwork) | 1 Masterwork | 0-1 | GOOD |
| Smithing 10 (Grace) | N/A (stat) | Always | FAIR |
| Smithing 12 (Double) | 2 uses | 2-4 | GOOD |
| Smithing 14 (Efficient) | 20 actions | Depends | FAIR |
| Smithing 16 (Resist) | 2 uses | 1-3 | GOOD |
| Smithing 18 (Greater) | 40 actions | Depends | FAIR |
| Smithing 20 (Master) | All crafts | All future | EXCELLENT |

---

## Enchantment Difficulty Costs

### Double Enchant Examples

| First Ego | Difficulty | Second Ego | +50% Diff | Total |
|-----------|------------|------------|-----------|-------|
| of Gondolin | 4 | of Doriath | 6 | 10 |
| of Erebor | 6 | (Balanced) | 9 | 15 |
| of the Edain | 8 | of Protection | 6 | 14 |
| of Fury | 10 | of Stealth | 6 | 16 |

### Resistance Difficulty Costs

| Resistance | Difficulty Cost |
|------------|-----------------|
| RES_FIRE | +8 |
| RES_COLD | +8 |
| RES_POIS | +8 |
| RES_FEAR | +6 |
| RES_BLIND | +6 |
| RES_CONFU | +6 |
| RES_STUN | +6 |

---

## Broken Item Drop Rates

### Expected Drops per Game Section

| Depth Range | Broken Glowing | Broken Strange |
|-------------|----------------|----------------|
| 0-300ft | 2-4 | 0-1 |
| 300-600ft | 3-5 | 1-2 |
| 600-900ft | 3-5 | 2-3 |
| 900-1000ft | 1-2 | 1-2 |
| **Total** | **9-16** | **4-8** |

### Conversion Capacity

| Ability | Items Needed | Max Uses (typical) |
|---------|--------------|-------------------|
| Reforge | 2 Glowing | 4-8 |
| Reclaim | 2 Strange | 2-4 |
| Masterwork | 4 Strange | 1-2 |

---

## Power Comparison: Crafted vs Found

### Weapon Quality Tiers

| Tier | Found Example | Crafted Equivalent | Smithing Req |
|------|---------------|-------------------|--------------|
| Basic | +0 weapon | Custom base | Weaponsmith |
| Good | Random ego | Chosen ego | Reforge |
| Excellent | Random artifact | Chosen type | Reclaim |
| Legendary | Best artifact | Guaranteed best | Masterwork |
| Ultimate | N/A | Double ego + resist | S16 + Double |

### Power Level Estimates (1-10 scale)

| Item Source | Power | Consistency | Investment |
|-------------|-------|-------------|------------|
| Random drop | 3-7 | LOW | 0 |
| Crafted base | 4-5 | HIGH | LOW |
| Reforged | 5-7 | MEDIUM | MEDIUM |
| Reclaimed | 7-9 | LOW | HIGH |
| Masterwork | 9-10 | HIGH | VERY HIGH |
| Master Smith craft | 10+ | HIGH | MAXIMUM |

---

## XP Efficiency Summary

### XP per Combat Point

| Skill | Level 1→5 | Level 5→10 | Level 10→15 |
|-------|-----------|------------|-------------|
| Melee | 300/pt | 700/pt | 1100/pt |
| Evasion | 300/pt | 700/pt | 1100/pt |
| Smithing | N/A | N/A | N/A |

### XP per Crafted Item Value

| Action | XP Cost | Item Value | Efficiency |
|--------|---------|------------|------------|
| Reforge | 600 | ~1000 | 1.67× |
| Reclaim | ~500 | ~3000 | 6.0× |
| Masterwork | ~1500 | ~7000 | 4.67× |

---

## Recommended Investment Paths

### Early Game (0-5000 XP)

**Combat Priority:**
1. Melee 6 (2,100 XP)
2. Evasion 4 (1,000 XP)
3. Will 3 (600 XP)
4. Combat abilities (1,300 XP)

**Hybrid Priority:**
1. Melee 4 (1,000 XP)
2. Evasion 4 (1,000 XP)
3. Smithing 5 + Reforge (2,750 XP)
4. Basic abilities (250 XP)

### Mid Game (5000-15000 XP)

**Combat Evolution:**
1. Melee 10 (5,500 XP cumulative)
2. Evasion 8 (3,600 XP cumulative)
3. Will 6 (2,100 XP cumulative)
4. Advanced abilities (3,000+ XP)

**Smith Evolution:**
1. Smithing 8 + Masterwork (5,600 XP)
2. Smithing 10 + Grace (8,000 XP)
3. Smithing 12 + Double Enchant (10,800 XP)
4. Combat catch-up (4,200 XP)

### Late Game (15000+ XP)

**Combat Mastery:**
- Push key skills to 15+
- Acquire capstone abilities
- Gear-dependent progression

**Smith Mastery:**
- Smithing 16-20 for high-level abilities
- Create ultimate gear
- Combat adequate for survival

---

## Balance Verification Checklist

### Is Smithing Competitive?

- [x] Smithing 5-8 provides clear value
- [x] Reforge/Reclaim/Masterwork ROI is positive
- [ ] High-level rewards justify investment
- [ ] XP costs scale appropriately
- [ ] Expertise doesn't break economy

### Is Combat Still Valuable?

- [x] Combat builds remain strong
- [x] Found items still useful
- [ ] Smithing doesn't obsolete combat
- [ ] Both paths lead to victory

### Is Hybrid Viable?

- [x] Hybrid builds can succeed
- [x] Flexible investment path
- [ ] Neither extreme is required
- [ ] Player choice matters
