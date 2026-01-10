# Sil-Q Smithing Changes Reference

## Document: AUDIT-007
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document tracks all smithing-related changes made in Sil-Q versions, showing the evolution from Sil 1.3 to the current system in The Necromancer.

---

## Sil-Q 1.5.0 (Most Recent)

### Major Smithing Changes

```
Smithing changes
    - +Smithing items removed
    - Curses removed from artifact creation
    - Smithing costs reduced to compensate
    - Guaranteed forges now at the first entrance to or below:
        100', 300', 500'
```

**Analysis:**
1. **+Smithing items removed** - No more gear that boosts smithing skill
   - Impact: Can't stack smithing bonuses from equipment
   - Balance: Smithing skill must come from XP investment only

2. **Curses removed from artifact creation** - Can't add curses for difficulty discount
   - Impact: No more exploiting dangerous curses for cheap powerful items
   - Balance: Artifacts are more expensive but cleaner

3. **Costs reduced** - Compensates for above removals
   - Impact: Base smithing more affordable
   - Balance: Similar power level, less exploitable

4. **Guaranteed forges** - 100', 300', 500' depths
   - Impact: Players can plan smithing strategies
   - Balance: Reliable forge access early game

### Ability Changes

```
Smithing
    - Artistry gone, effects available by default
    - Expertise added
    - Jeweller lets you identify jewellery, Enchantment enchanted items
    - Grace point has prereqs removed
```

**Key additions:**
- **Expertise**: Halves forge time, negates XP/stat costs
- **Auto-identification**: Jeweller/Enchantment abilities grant passive ID

---

## Sil-Q 1.4.2

### Smithing Changes

```
- Expertise and Artifice swap places
```

**Analysis:**
- Tree restructuring for better progression
- Expertise moved earlier in tree

### Ability Cost Changes

```
- Abilities cheaper to smith, need only half as much experience
```

**Impact:**
- Smithing abilities onto items costs 50% less XP
- Makes ability-granting equipment more attractive

---

## Sil-Q 1.4.1

### Smithing Changes

```
- bow and arrow smithing tweaked, arrow drop rates altered (there should
  now be more arrows earlier on), longbows drop further down
```

**Analysis:**
- Archery balance adjustments
- More arrows available = less need to smith them
- Longbows harder to find = more valuable to smith

---

## Sil-Q 1.4.0

### Major Smithing Overhaul

```
- smithing
    - Most costs massively overhauled
        - Aim is to make smithing more competitive mid-game, less broken
          late-game. Sharpness and speed more expensive, brands and slays
          and resists less so. Many other changes.
    - Forges guaranteed to have at least 3 uses
    - Guaranteed forges spawned at 100', 500', 900'.
    - Negative effects on enchanted items (not artificed ones) again
      provide a cost discount
    - Mithril can be melted at used forges (mpa-sil)
    - Many abilities can be added to items which couldn't be added before
      (most artefacts are craftable again)
```

**Key changes:**

1. **Cost rebalancing** - Mid-game competitive, late-game nerfed
   - Sharpness: More expensive (was overpowered)
   - Speed: More expensive (was overpowered)
   - Brands/Slays: Less expensive (underused)
   - Resists: Less expensive (underused)

2. **Forge guarantees** - Minimum 3 uses, spawn at 100', 500', 900'
   - Changed in 1.5.0 to 100', 300', 500'

3. **Negative effects discount** - Restored for enchanted items
   - Does NOT apply to artificed items
   - Balance: Risk-reward tradeoff

4. **Mithril melting** - Can recycle at used forges
   - New mechanic from mpa-sil fork
   - Allows converting mithril items to raw material

5. **Ability crafting expanded** - Most artifacts craftable again
   - Previously restricted abilities now available

---

## Evolution of Guaranteed Forges

| Version | Guaranteed Forge Depths |
|---------|------------------------|
| Sil 1.1 | 100' (first forge only) |
| Sil-Q 1.4.0 | 100', 500', 900' |
| Sil-Q 1.5.0 | 100', 300', 500' |

**Trend:** More frequent early forges, less late-game reliance

---

## Ability Tree Evolution

### Sil 1.3 → Sil-Q 1.4.0

| Old | New |
|-----|-----|
| Enchantment | (merged with base abilities) |
| Artifice | Artifice (position changed) |
| Masterpiece | (reworked) |
| - | Expertise (new) |

### Sil-Q 1.4.0 → 1.5.0

| Change | Details |
|--------|---------|
| Artistry | Removed (effects default) |
| Expertise | Added (time + cost reduction) |
| Jeweller | Now grants jewelry ID |
| Enchantment | Now grants enchanted item ID |

---

## Cost Evolution Summary

### Items That Got More Expensive

| Item/Property | Reason |
|---------------|--------|
| Sharpness | Was overpowered for damage |
| Speed | Was overpowered for action economy |
| +Smithing bonuses | Removed entirely |

### Items That Got Cheaper

| Item/Property | Reason |
|---------------|--------|
| Brands | Underused, thematic |
| Slays | Underused, flavorful |
| Resists | Survival necessity |
| Ability smithing | Was too expensive |
| Base costs | Compensate for removed exploits |

---

## New Mechanics Introduced

### Broken Item System

**New item types for recycling:**

| Item | K_IDX | Use |
|------|-------|-----|
| Broken Glowing Weapon | 491 | Reforge → enchanted weapon |
| Shattered Elven Mail | 492 | Reforge → enchanted armor |
| Broken Strange Weapon | 493 | Reclaim/Masterwork → artifact |
| Twisted Shadow-plate | 494 | Reclaim/Masterwork → artifact |
| Broken Strange Jewelry | 495 | Reclaim/Masterwork → artifact |

### Reforge/Reclaim/Masterwork System

| Action | Input | Output | XP Cost |
|--------|-------|--------|---------|
| Reforge | 2 Broken Glowing | Random enchanted | 500 flat |
| Reclaim | 2 Broken Strange | Random artifact | level × 50 |
| Masterwork | 4 Broken Strange | Best artifact | level × 100 |

**Note:** These XP costs were added in Sil-Q, not present in original Sil.

### Mithril Melting

- Can be done at used forges (0 uses remaining)
- Converts mithril items to mithril pieces
- Amount based on item weight
- Added in Sil-Q 1.4.0 from mpa-sil

---

## The Necromancer Modifications

### UI Text Changes

The Necromancer has renamed "Artifice" references in the codebase:
- Variable: `smithing_cost.artifice`
- UI labels: "c) Artifice"
- Help text: "(not compatible with Artifice)"

**Recommended changes** (from AUDIT-003):
- Rename to "Custom Artifact" or similar
- Update all UI text to match

### Lore Modifications

Special item names updated for Third Age setting:
- First Age references → Third Age equivalents
- See AUDIT-005 for full list

---

## Key Insights for Balance

### What Worked in Sil-Q

1. **Guaranteed forges** - Reliable progression
2. **Mithril melting** - Material recycling
3. **Broken item system** - Endgame goal for items
4. **Auto-identification** - QoL for Jeweller/Enchantment

### What May Need Adjustment

1. **Expertise too powerful** - Negates all XP/stat costs
   - Solution: Reduce instead of eliminate?

2. **Smithing cliff at level 10** - No abilities after Grace
   - Solution: Add high-level abilities

3. **XP costs hidden** - Players may not realize Reforge etc. cost XP
   - Solution: Display costs clearly in UI

4. **"Artifice" terminology** - Confusing legacy name
   - Solution: Rename to "Custom Artifact"

---

## Recommendations for The Necromancer

### Preserve

1. Guaranteed forge locations (100', 300', 500')
2. Broken item system (Reforge/Reclaim/Masterwork)
3. Mithril melting at used forges
4. Auto-identification from Jeweller/Enchantment
5. Balanced cost structure from Sil-Q 1.5.0

### Modify

1. **Expertise**: Consider nerfing to 50% reduction instead of elimination
2. **Artifice naming**: Rename to "Custom Artifact" throughout
3. **High-level abilities**: Add rewards for Smithing 12, 15, 18, 20
4. **XP cost display**: Show costs clearly in forge UI

### Remove/Replace

1. **Grace at level 10**: Replace with smithing-specific bonus
2. **"Artifice" text**: Update all occurrences
