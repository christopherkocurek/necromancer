# Expected XP Per Depth Analysis

## Document: AUDIT-005
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document estimates typical XP earned per depth level for different playstyles and identifies where players fall behind the power curve.

---

## Assumptions

### Dungeon Structure
- Each 50ft is one dungeon level
- ~10-15 monsters per level (varies by depth)
- Monster variety decreases as player kills (diminishing returns)

### XP Sources Per Level
1. **Descent XP**: `depth_level * 50` (one-time per new depth)
2. **Kill XP**: `monster_level * 10` (diminishing returns)
3. **Encounter XP**: `monster_level * 10 / (sightings + 1)`
4. **Ident XP**: ~100-200 XP per level (new item types)

---

## XP Calculation Model

### Monster Distribution by Depth

| Depth (ft) | Depth Level | Monsters/Level | Avg Monster Level | Types |
|------------|-------------|----------------|-------------------|-------|
| 50-100 | 1-2 | 12 | 1.5 | 5 |
| 100-150 | 2-3 | 12 | 2.5 | 5 |
| 150-200 | 3-4 | 15 | 4 | 6 |
| 200-300 | 4-6 | 15 | 5 | 6 |
| 300-450 | 6-9 | 15 | 7.5 | 7 |
| 450-600 | 9-12 | 15 | 10.5 | 6 |
| 600-750 | 12-15 | 12 | 13.5 | 6 |
| 750-900 | 15-18 | 10 | 16.5 | 5 |
| 900-1000 | 18-20 | 8 | 19 | 4 |

---

## Playstyle Definitions

### Combat-Heavy (Kill Everything)
- Kills 90% of monsters encountered
- Takes fights head-on
- Uses first-kill bonuses heavily

### Stealth-Heavy (Avoid Combat)
- Kills 20% of monsters (only when necessary)
- Bypasses most threats
- Relies on encounter XP

### Hybrid (Selective Combat)
- Kills 50% of monsters
- Fights when advantageous
- Sneaks past dangerous foes

---

## XP Estimates: 0-300ft

### Combat-Heavy Player

| Depth | Descent | Kill XP | Encounter | Ident | Total | Cumulative |
|-------|---------|---------|-----------|-------|-------|------------|
| Start | - | - | - | - | 5,000 | 5,000 |
| 50ft | 50 | 100 | 50 | 100 | 300 | 5,300 |
| 100ft | 100 | 180 | 60 | 100 | 440 | 5,740 |
| 150ft | 150 | 300 | 80 | 100 | 630 | 6,370 |
| 200ft | 200 | 450 | 100 | 100 | 850 | 7,220 |
| 250ft | 250 | 500 | 120 | 100 | 970 | 8,190 |
| 300ft | 300 | 550 | 140 | 100 | 1,090 | 9,280 |

**Total at 300ft: ~9,280 XP**

### Stealth-Heavy Player

| Depth | Descent | Kill XP | Encounter | Ident | Total | Cumulative |
|-------|---------|---------|-----------|-------|-------|------------|
| Start | - | - | - | - | 5,000 | 5,000 |
| 50ft | 50 | 20 | 100 | 100 | 270 | 5,270 |
| 100ft | 100 | 36 | 120 | 100 | 356 | 5,626 |
| 150ft | 150 | 60 | 150 | 100 | 460 | 6,086 |
| 200ft | 200 | 90 | 200 | 100 | 590 | 6,676 |
| 250ft | 250 | 100 | 250 | 100 | 700 | 7,376 |
| 300ft | 300 | 110 | 300 | 100 | 810 | 8,186 |

**Total at 300ft: ~8,186 XP** (12% less than combat)

### Hybrid Player

| Depth | Descent | Kill XP | Encounter | Ident | Total | Cumulative |
|-------|---------|---------|-----------|-------|-------|------------|
| Start | - | - | - | - | 5,000 | 5,000 |
| 50ft | 50 | 50 | 75 | 100 | 275 | 5,275 |
| 100ft | 100 | 90 | 90 | 100 | 380 | 5,655 |
| 150ft | 150 | 150 | 120 | 100 | 520 | 6,175 |
| 200ft | 200 | 225 | 150 | 100 | 675 | 6,850 |
| 250ft | 250 | 250 | 180 | 100 | 780 | 7,630 |
| 300ft | 300 | 275 | 220 | 100 | 895 | 8,525 |

**Total at 300ft: ~8,525 XP**

---

## XP Estimates: 300-600ft

### Combat-Heavy Player (continuing)

| Depth | Descent | Kill XP | Encounter | Ident | Total | Cumulative |
|-------|---------|---------|-----------|-------|-------|------------|
| 350ft | 350 | 600 | 160 | 100 | 1,210 | 10,490 |
| 400ft | 400 | 650 | 180 | 50 | 1,280 | 11,770 |
| 450ft | 450 | 700 | 200 | 50 | 1,400 | 13,170 |
| 500ft | 500 | 750 | 220 | 50 | 1,520 | 14,690 |
| 550ft | 550 | 800 | 240 | 50 | 1,640 | 16,330 |
| 600ft | 600 | 850 | 260 | 50 | 1,760 | 18,090 |

**Total at 600ft: ~18,090 XP**

---

## Power Curve Analysis

### What XP Buys (Combat Build Targets)

| Depth Target | Min XP Needed | Build | Combat Req |
|--------------|--------------|-------|------------|
| 300ft | 8,000 | Melee 8, Eva 6, Will 4 | Melee + Eva >= 14 |
| 450ft | 12,000 | Melee 10, Eva 8, Will 5, Per 4 | Melee + Eva >= 18 |
| 600ft | 16,000 | Melee 12, Eva 10, Will 6, Per 5 | Melee + Eva >= 22 |
| 750ft | 20,000 | Melee 14, Eva 12, Will 7, Per 6 | Melee + Eva >= 26 |
| 900ft | 25,000 | Melee 15+, Eva 13+, Will 8+, Per 7+ | Maximum |

### Current Gap Analysis

| Depth | XP Earned (Combat) | XP Needed (Combat) | Gap |
|-------|-------------------|-------------------|-----|
| 300ft | 9,280 | 8,000 | +1,280 (OK) |
| 450ft | 13,170 | 12,000 | +1,170 (Tight) |
| 600ft | 18,090 | 16,000 | +2,090 (OK) |

### Gap Analysis for Stealth

| Depth | XP Earned (Stealth) | XP Needed (Stealth) | Gap |
|-------|---------------------|---------------------|-----|
| 300ft | 8,186 | 8,500 | **-314 (BEHIND)** |
| 450ft | ~11,500 | 12,500 | **-1,000 (BEHIND)** |

---

## The Core Problem

### At 300ft (Depth 6)

The PRD reports an expert player struggling at 300ft. Looking at the numbers:

**Combat Player:**
- Has: ~9,280 XP
- Needs: Melee 8 (3,600) + Evasion 8 (3,600) + Will 4 (1,000) + Per 3 (600) = 8,800 XP
- **Margin: +480 XP** - Very tight, no room for abilities

**The Issue:**
- Player can *barely* afford minimum viable combat stats
- No XP for abilities (500+ XP each)
- No XP for backup skills
- One bad fight = restart because no margin

### What +30% XP Fixes

**Combat Player at 300ft with +30%:**
- Has: ~10,764 XP (+1,484 XP)
- Needs: 8,800 XP
- **Margin: +1,964 XP** - Room for 3-4 abilities or backup skill

---

## Recommended XP by Depth

### Target Cumulative XP (Post-Rebalance)

| Depth | Current XP | +30% XP | Should Feel |
|-------|------------|---------|-------------|
| 100ft | 5,740 | 6,462 | Comfortable starting build |
| 200ft | 7,220 | 8,386 | Core skills coming online |
| 300ft | 9,280 | 11,064 | Build viable, room for abilities |
| 400ft | 11,770 | 14,701 | Strong build, picking specialties |
| 500ft | 14,690 | 18,597 | Full core build online |
| 600ft | 18,090 | 23,017 | Mastery of primary skills |

---

## Key Findings

1. **Combat players are barely viable** at 300ft - no margin for error
2. **Stealth players fall behind** starting around 200ft
3. **Diminishing returns hit hard** - forcing variety but limiting overall XP
4. **+30% XP provides needed margin** - transforms "barely viable" to "comfortable"
5. **Abilities become affordable** with the boost
6. **The XP curve works** for late game but front-loads difficulty

---

## Recommendations

1. **+30% XP boost is validated** by this analysis
2. **Consider +40% for stealth-heavy** via exploration XP bonuses
3. **Depth milestones would help** early game progression feel
4. **Monitor 300-450ft range** - this is where builds either click or die
