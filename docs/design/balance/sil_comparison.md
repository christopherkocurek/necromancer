# Sil 1.3 Baseline Comparison

## Document: AUDIT-006
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document attempts to compare current XP values to the original Sil 1.3 baseline. Due to limited historical documentation, this comparison is partially reconstructed from available evidence.

---

## Codebase Search Results

### References Found

1. **lib/docs/changes.txt** - Changelog mentioning Sil 1.3 release
2. **src/Sil.r** - Mac resource file with version 1.3.0

### Sil 1.3 Changelog (from changes.txt:330-386)

Key changes in Sil 1.3:
- Large changes to early game monsters
- Many new monster types added
- Old "generic" monsters replaced
- Mac Cocoa version introduced
- **No explicit XP formula changes documented**

### Sil-Q Changes (from changes.txt)

Notable XP-related change in Sil-Q 1.4.2:
```
- XP for scaring monsters removed
    - this breaks savefiles
    - it wasn't a lot of XP, but it wasn't very elegant either
```

This indicates minor XP adjustments between Sil-Q versions.

---

## Reconstructed XP Formula History

### Current Formula (The Necromancer / Sil-Q)

**Monster Kill XP:**
```c
int mexp = r_ptr->level * 10;  // Base XP = monster_level * 10
```

With diminishing returns (from `src/xtra2.c:2538-2586`):
- 1st kill: 100% XP
- 2nd kill: 35% XP (steeper than original)
- 3rd kill: 19% XP
- 7th+ kill: mexp / (kills + 1) * 3

**Note:** Comment in code says "Old formula: exp = mexp / (mkills + 1)"

### Original Formula (Based on Code Comments)

From `src/xtra2.c:2542`:
```c
* Old formula: exp = mexp / (mkills + 1)
```

This suggests the original Sil had gentler diminishing returns:
- 1st kill: 100% XP
- 2nd kill: 50% XP (vs current 35%)
- 3rd kill: 33% XP (vs current 19%)
- 4th kill: 25% XP (vs current 13%)

---

## XP Comparison: Original vs Current

### Kill XP Comparison (Same Monster Killed 5 Times)

Assuming monster level 5 (base 50 XP):

| Kill # | Original | Current | Difference |
|--------|----------|---------|------------|
| 1st | 50 | 50 | 0 |
| 2nd | 25 | 17 | -8 (-32%) |
| 3rd | 16 | 9 | -7 (-44%) |
| 4th | 12 | 6 | -6 (-50%) |
| 5th | 10 | 4 | -6 (-60%) |
| **Total** | **113** | **86** | **-27 (-24%)** |

### Implication

The current game has **~24% less XP from repeated kills** compared to what appears to be the original formula. This was an intentional change to encourage variety and stealth, but it compounds the XP shortage problem.

---

## Other Potential XP Differences

### XP Removed in Sil-Q

From changelog:
- **Scaring monsters XP** - Removed (amount unknown)

### XP Sources Unchanged

Based on code structure, these appear consistent:
- Descent XP: `depth * 50`
- Encounter XP: `monster_level * 10 / (sightings + 1)`
- Identification XP: 100 per type

---

## Starting XP Comparison

### Current
```c
#define PY_START_EXP 5000
```

### Historical

Unable to find historical starting XP values. The 5,000 XP start appears consistent in the codebase.

---

## Skill Cost Comparison

The skill cost formula appears unchanged:
```c
// The nth skill point costs (100*n) experience points
int total_cost = (points + base) * (points + base + 1) / 2;
return ((total_cost - prev_cost) * 100);
```

This triangular number formula is consistent across versions.

---

## Net XP Impact Analysis

### Changes Reducing XP

1. **Steeper diminishing returns on kills**: -24% on repeated kills
2. **Scaring XP removed**: Unknown amount

### Changes Increasing XP

None identified.

### Net Effect

The current game appears to have **reduced XP income** compared to original Sil, primarily through steeper diminishing returns. This was a design choice to encourage variety but has had the side effect of making the game feel XP-starved.

---

## Recommendations

### Option A: Restore Original Diminishing Returns

Revert to `exp = mexp / (mkills + 1)`:
- Would increase total XP by ~24% on repeated kills
- Maintains some diminishing returns
- Simpler formula

### Option B: Apply +30% Multiplier (PRD Recommendation)

Keep current formula but multiply all XP by 1.3:
- Provides consistent boost
- Maintains design intent of current formula
- Easier to tune

### Option C: Hybrid Approach

1. Apply +20% base XP multiplier
2. Soften diminishing returns to midpoint between old and new:
   - 2nd kill: 40% (vs current 35%, original 50%)
   - 3rd kill: 25% (vs current 19%, original 33%)

This would effectively provide +30-35% total XP while preserving the "variety is rewarded" design goal.

---

## Conclusion

While complete historical documentation is unavailable, the codebase contains evidence that **XP income was reduced** from original Sil through steeper diminishing returns. Combined with unchanged skill costs, this creates the XP shortage problem described in the PRD.

The +30% XP boost recommended by the PRD would approximately restore players to the original Sil XP curve while maintaining the current design philosophy of rewarding variety.

---

## Sources

- `src/xtra2.c` - Contains comments about old XP formula
- `lib/docs/changes.txt` - Version history
- Code analysis of current XP calculations
