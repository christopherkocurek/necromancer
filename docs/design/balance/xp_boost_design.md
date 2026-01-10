# +30% XP Implementation Design

## Document: DESIGN-001
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document designs the implementation of a +30% XP boost across all XP sources, with a configurable multiplier for future tuning.

---

## Implementation Options

### Option A: Modify Monster XP Values in Data

**Approach:** Change `W:` values in `lib/edit/monster.txt` or add an XP field.

**Pros:**
- No code changes required
- Individual monster tuning possible

**Cons:**
- Tedious (60+ monsters to modify)
- Doesn't affect non-monster XP
- Hard to tune (requires editing many lines)
- Doesn't provide config option

**Verdict:** NOT RECOMMENDED

---

### Option B: Modify Base XP Calculation

**Approach:** Change `level * 10` to `level * 13` in `adjusted_mon_exp()`.

**Location:** `src/xtra2.c:2525`

**Current:**
```c
int mexp = r_ptr->level * 10;
```

**Proposed:**
```c
int mexp = r_ptr->level * 13;  // +30% XP boost
```

**Pros:**
- Single line change
- Affects all monster XP

**Cons:**
- Hardcoded, not configurable
- Only affects monster XP (not descent, ident, etc.)
- Doesn't support future difficulty modes

**Verdict:** SIMPLE BUT LIMITED

---

### Option C: Global XP Multiplier in gain_exp() (RECOMMENDED)

**Approach:** Add a multiplier in the `gain_exp()` function that applies to ALL XP sources.

**Location:** `src/xtra2.c:1752-1765`

**Current:**
```c
void gain_exp(s32b amount)
{
    if (birth_fixed_exp)
    {
        return;
    }

    p_ptr->exp += amount;
    p_ptr->new_exp += amount;

    check_experience();
}
```

**Proposed:**
```c
/*
 * XP multiplier for balance tuning.
 * 100 = normal (1.0x), 130 = +30% boost (1.3x)
 * Can be adjusted via config for difficulty modes.
 */
#define XP_MULTIPLIER 130

void gain_exp(s32b amount)
{
    if (birth_fixed_exp)
    {
        return;
    }

    /* Apply XP multiplier (integer math: amount * 130 / 100) */
    amount = (amount * XP_MULTIPLIER) / 100;

    p_ptr->exp += amount;
    p_ptr->new_exp += amount;

    check_experience();
}
```

**Pros:**
- Single location controls all XP
- Easy to tune (change one number)
- Affects ALL XP sources uniformly
- Foundation for difficulty modes

**Cons:**
- Requires code change
- Slight overhead (one multiply+divide per XP gain)

**Verdict:** RECOMMENDED

---

### Option D: Configurable XP Multiplier (ENHANCED RECOMMENDATION)

**Approach:** Same as Option C but with runtime configuration.

**Step 1: Add Config Variable**

Location: `src/tables.c` (near other birth options)

```c
bool xp_multiplier = 130;  /* Percentage: 100 = normal, 130 = +30% */
```

Location: `src/externs.h`

```c
extern int xp_multiplier;
```

**Step 2: Add Birth Option (Optional)**

Could add to birth options screen for difficulty selection:
- Normal: 100%
- Accessible: 130% (default)
- Easy: 150%
- Challenge: 80%

**Step 3: Modify gain_exp()**

```c
void gain_exp(s32b amount)
{
    if (birth_fixed_exp)
    {
        return;
    }

    /* Apply XP multiplier for balance/difficulty */
    if (xp_multiplier != 100)
    {
        amount = (amount * xp_multiplier) / 100;
    }

    p_ptr->exp += amount;
    p_ptr->new_exp += amount;

    check_experience();
}
```

**Pros:**
- All benefits of Option C
- Runtime configurable
- Enables future difficulty modes
- Easy A/B testing

**Cons:**
- More code changes
- Need to save/load the setting

**Verdict:** IDEAL FOR LONG-TERM

---

## Recommended Implementation

### Phase 1: Simple Implementation (IMPL-001)

Use **Option C** - hardcoded multiplier with `#define`:

1. Add `#define XP_MULTIPLIER 130` to `src/defines.h`
2. Modify `gain_exp()` to apply multiplier
3. Test and validate

### Phase 2: Configurable (IMPL-004)

Upgrade to **Option D** - configurable multiplier:

1. Add `xp_multiplier` global variable
2. Add birth option or config file setting
3. Modify `gain_exp()` to use variable
4. Add save/load support

---

## Detailed Implementation

### File: src/defines.h

Add near other game balance constants:

```c
/*
 * XP Multiplier for balance tuning
 * 100 = standard Sil-Q experience
 * 130 = +30% boost (The Necromancer default)
 * Adjust this value to tune overall game difficulty
 */
#define XP_MULTIPLIER 130
```

### File: src/xtra2.c

Modify `gain_exp()` function (around line 1752):

```c
/*
 * Gain experience
 */
void gain_exp(s32b amount)
{
    /* Fixed XP mode disables all experience gain */
    if (birth_fixed_exp)
    {
        return;
    }

    /* Apply XP multiplier for game balance */
    /* Uses integer math: amount * 130 / 100 for +30% */
    #if XP_MULTIPLIER != 100
    amount = (amount * XP_MULTIPLIER) / 100;
    #endif

    /* Gain the experience */
    p_ptr->exp += amount;
    p_ptr->new_exp += amount;

    /* Check for level changes */
    check_experience();
}
```

---

## Testing Plan

### Unit Test: XP Values

Before implementation:
- Kill a level 5 monster (first kill) → expect 50 XP
- Descend to depth 5 → expect 250 XP (5 * 50)
- Identify item → expect 100 XP

After implementation:
- Kill a level 5 monster (first kill) → expect 65 XP (50 * 1.3)
- Descend to depth 5 → expect 325 XP (250 * 1.3)
- Identify item → expect 130 XP (100 * 1.3)

### Integration Test: Progression

Play through depth 300ft, record:
- Total XP accumulated
- Skill levels affordable
- Build viability

Compare to AUDIT-005 projections.

---

## Rollback Plan

If +30% is too much:

1. Change `#define XP_MULTIPLIER 130` to `120` or `110`
2. Rebuild
3. Test again

If +30% is not enough:

1. Change to `140` or `150`
2. Rebuild
3. Test again

---

## Summary

**Recommended approach:** Modify `gain_exp()` with a `#define XP_MULTIPLIER 130`

**Benefits:**
- Single point of control
- Affects ALL XP sources
- Easy to tune
- Foundation for difficulty modes

**Implementation effort:** ~10 lines of code changes across 2 files
