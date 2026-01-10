# Smithing Abilities Audit

## Document: AUDIT-004
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document lists all Smithing-related abilities from `lib/edit/ability.txt` and evaluates their current relevance.

---

## Ability File Format Reference

```
N:ID:Name
I:skill:index:level
P:skill/index (prerequisite)
D:Description text
T:tval:sval_min:sval_max (usable items)
```

---

## Current Smithing Abilities

### 1. Weaponsmith (N:120)

**File Location:** `lib/edit/ability.txt:590-594`

```
N:120:Weaponsmith
I:6:0:2
D:Allows you to create weapons.
T:21:8:8   # Hafted (War Hammer only)
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_WEAPONSMITH (0)
- **Level Required:** 2
- **Prerequisites:** None
- **Effect:** Enables weapon forging (swords, polearms, hafted, bows)
- **Usable With:** War Hammer, Gloves

**Status:** ✅ KEEP - Core ability, necessary for weapon creation

---

### 2. Armoursmith (N:121)

**File Location:** `lib/edit/ability.txt:596-600`

```
N:121:Armoursmith
I:6:1:3
D:Allows you to create armour.
T:21:8:8   # Hafted (War Hammer only)
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_ARMOURSMITH (1)
- **Level Required:** 3
- **Prerequisites:** None
- **Effect:** Enables armor forging (mail, leather, shields, helms, etc.)
- **Usable With:** War Hammer, Gloves

**Status:** ✅ KEEP - Core ability, necessary for armor creation

---

### 3. Jeweller (N:122)

**File Location:** `lib/edit/ability.txt:602-607`

```
N:122:Jeweller
I:6:2:4
D:Allows you to create rings, amulets, and light sources,
D: and identify such items you encounter. The craft of
D: adornment and illumination.
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_JEWELLER (2)
- **Level Required:** 4
- **Prerequisites:** None
- **Effect:** Enables jewelry forging + auto-identification of jewelry
- **Usable With:** Gloves (no War Hammer - thematic for fine work)

**Status:** ✅ KEEP - Core ability, necessary for jewelry creation
**Note:** Auto-identify is a nice bonus feature

---

### 4. Reforge (N:123)

**File Location:** `lib/edit/ability.txt:609-615`

```
N:123:Reforge
I:6:3:5
D:Allows you to combine two Broken Glowing items at a forge
D: to create an enchanted item of that type. You choose the
D: enchantment from all available types.
T:21:8:8   # Hafted (War Hammer only)
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_REFORGE (3)
- **Level Required:** 5
- **Prerequisites:** None
- **Effect:** Convert broken glowing items → random enchanted item
- **XP Cost:** 500 flat (implemented in code)

**Status:** ✅ KEEP - Important recycling mechanic
**Issue:** Description says "You choose the enchantment" but code picks randomly

---

### 5. Expertise (N:124)

**File Location:** `lib/edit/ability.txt:617-623`

```
N:124:Expertise
I:6:4:6
P:6/3
D:Reduces the time taken to forge an item by half and
D: negates all experience and stat costs.
T:21:8:8   # Hafted (War Hammer only)
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_EXPERTISE (4)
- **Level Required:** 6
- **Prerequisites:** Reforge (6/3)
- **Effect:** Halves forging time, removes XP/stat costs

**Status:** ⚠️ EVALUATE - Very powerful, may obsolete XP cost system
**Concern:** If this negates XP costs, why bother with XP balance?

---

### 6. Reclaim (N:125)

**File Location:** `lib/edit/ability.txt:625-632`

```
N:125:Reclaim
I:6:5:7
P:6/3
D:Allows you to combine two Broken Strange items at a forge
D: to create a random artifact of that type. The artifact
D: is drawn from the legends of Middle-earth.
T:21:8:8   # Hafted (War Hammer only)
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_RECLAIM (5)
- **Level Required:** 7
- **Prerequisites:** Reforge (6/3)
- **Effect:** Convert broken strange items → random artifact
- **XP Cost:** artifact_level * 50 (implemented in code)

**Status:** ✅ KEEP - Core artifact creation mechanic

---

### 7. Masterwork (N:126)

**File Location:** `lib/edit/ability.txt:634-641`

```
N:126:Masterwork
I:6:6:8
P:6/5
D:Allows you to combine four Broken Strange items at a forge
D: to create a legendary artifact. These are the greatest
D: works of the Third Age, surpassing even ancient relics.
T:21:8:8   # Hafted (War Hammer only)
T:31:0:99  # Gloves
```

**Analysis:**
- **Index:** SMT_MASTERWORK (6)
- **Level Required:** 8
- **Prerequisites:** Reclaim (6/5)
- **Effect:** Convert 4 broken strange items → best artifact of type
- **XP Cost:** artifact_level * 100 (implemented in code)

**Status:** ✅ KEEP - Premium artifact creation mechanic

---

### 8. Grace (N:127)

**File Location:** `lib/edit/ability.txt:643-645`

```
N:127:Grace
I:6:7:10
D:You gain a point of grace.
```

**Analysis:**
- **Index:** 7
- **Level Required:** 10
- **Prerequisites:** None
- **Effect:** +1 Grace stat

**Status:** ⚠️ EVALUATE - Stat boost is nice but doesn't reward smithing mastery
**Concern:** This is a generic stat boost, not a smithing-specific reward

---

## Ability Progression Summary

```
Level 2:  Weaponsmith (weapon creation)
Level 3:  Armoursmith (armor creation)
Level 4:  Jeweller (jewelry + auto-id)
Level 5:  Reforge (broken glowing → enchanted)
Level 6:  Expertise (no costs, faster forge) [requires Reforge]
Level 7:  Reclaim (broken strange → artifact) [requires Reforge]
Level 8:  Masterwork (4 broken → best artifact) [requires Reclaim]
Level 10: Grace (+1 Grace stat)
```

---

## Issues Identified

### 1. Expertise May Break XP Economy

**Problem:** Expertise "negates all experience and stat costs"
**Impact:** This makes the XP cost system irrelevant for any smith with this ability
**Consideration:** Should Expertise only reduce costs, not eliminate them?

### 2. No Abilities After Level 10

**Problem:** Grace at level 10 is the last ability
**Impact:** No reason to invest Smithing beyond 10 except for difficulty checks
**Solution:** Add high-level abilities (see DESIGN-003)

### 3. Description Mismatch for Reforge

**Problem:** Description says "You choose the enchantment" but it's random
**Impact:** Player confusion
**Solution:** Update description to match behavior, or implement choice

### 4. Grace is Underwhelming for Level 10

**Problem:** +1 Grace is a generic reward, not smithing-specific
**Impact:** Feels disconnected from smithing mastery
**Solution:** Replace with smithing-specific bonus or add additional effect

---

## Proposed Changes

### Option A: Keep Expertise, Add High-Level Abilities

Add new abilities at levels 12, 15, 18, 20 that provide:
- Double enchantments
- Resistance crafting
- Artifact modification
- Master Smith bonuses

### Option B: Nerf Expertise, Strengthen Cost Scaling

Change Expertise to:
- "Reduces XP and stat costs by 50%" (not eliminate)
- Add skill-based discount (2% per level above 6)

### Option C: Rework Grace

Replace Grace with:
- "Forge Mastery" - All crafted items get +1 to primary stat
- Or "Efficient Smith" - Broken items have 20% chance to not be consumed

---

## Recommendations

1. **Keep all core abilities** (Weapon/Armor/Jeweller/Reforge/Reclaim/Masterwork)
2. **Evaluate Expertise** - may need nerf to preserve XP economy
3. **Replace or augment Grace** - should feel like smithing mastery
4. **Add 3-4 new high-level abilities** for levels 12-20
5. **Fix Reforge description** to match random behavior
