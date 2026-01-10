# Forge Actions Audit

## Document: AUDIT-001
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document catalogs all available forge actions in The Necromancer, including their requirements, costs, and mechanics.

---

## Forge Action Summary

| Action | Menu Key | Ability Required | XP Cost | Broken Items | Forge Use |
|--------|----------|-----------------|---------|--------------|-----------|
| Base Item | a | Weaponsmith/Armoursmith/Jeweller | Variable | - | 1 |
| Enchant | b | Reforge (for enchanting) | Variable | - | - |
| Artifice | c | Reclaim | Variable | - | - |
| Numbers | d | None | - | - | - |
| Melt | e | None | - | - | - |
| Reforge | f | Reforge | 500 XP | 2 Glowing | 1 |
| Reclaim | g | Reclaim | artifact_level * 50 | 2 Strange | 1 |
| Masterwork | h | Masterwork | artifact_level * 100 | 4 Strange | 1 |
| Accept | i | All required | Pay all costs | - | 1+ |

---

## Detailed Action Descriptions

### 1. Base Item (a)

**Location:** `src/cmd4.c` - `create_menu()` function

**Description:** Select a base item type to forge.

**Requirements:**
- Must have Weaponsmith, Armoursmith, or Jeweller ability
- Must be at a forge

**Available Items by Ability:**
- **Weaponsmith:** Swords, polearms, hafted weapons, bows, arrows
- **Armoursmith:** Mail, leather armor, shields, helms, cloaks, gloves, boots
- **Jeweller:** Rings, amulets, light sources

**Costs:** Determined by item complexity (see Object Difficulty)

---

### 2. Enchant (b)

**Location:** `src/cmd4.c:4514-4656` - `enchant_menu_aux()`

**Description:** Add a special enchantment (ego) to the base item.

**Requirements:**
- Base item must be selected
- Cannot combine with Artifice
- Cannot be changed after using Numbers menu
- Excluded item types: rings, amulets, horns, shovels, enhanced arrows

**Available Enchantments:** Depends on item type (egos from ego_item.txt)

**Costs:** Added to base item cost

---

### 3. Artifice (c)

**Location:** `src/cmd4.c:6714-6721`

**Description:** Design a custom artifact (self-made artifact).

**Requirements:**
- Base item selected
- Cannot combine with Enchant
- Player has not exceeded self-made artifact limit
- Requires Reclaim ability (shown in red if missing)

**Costs:**
- Higher than normal forging
- Sets `smithing_cost.artifice = 1` if ability missing

**Notes:**
- Allows custom property selection
- Limited number of self-made artifacts per game

---

### 4. Numbers (d)

**Location:** `src/cmd4.c:6723-6727`

**Description:** Adjust item stats (attack bonus, damage dice, evasion, protection).

**Requirements:**
- Base item selected

**Costs:** Adds to total forging cost

**Notes:**
- Locks in enchantment choice (cannot change after)

---

### 5. Melt (e)

**Location:** `src/cmd4.c:2630-2742` - `melt_mithril_item()`

**Description:** Melt mithril items into raw mithril pieces.

**Requirements:**
- Must have mithril items in inventory
- Must be at forge

**Costs:** None (just loses the item)

**Output:** Mithril pieces (weight-based conversion)

---

### 6. Reforge (f)

**Location:** `src/cmd4.c:6037-6185` - `reforge_menu()`

**Description:** Combine 2 Broken Glowing items to create a random enchanted item.

**Requirements:**
- Reforge ability (Smithing level 5+)
- 2 Broken Glowing items (weapons OR armor)
- At forge with uses remaining

**Input Items:**
- Broken Glowing Weapon (K_IDX 491) - for weapons
- Shattered Elven Mail (K_IDX 492) - for armor

**Output Selection:**
- Weapons: Sword, Polearm, Hafted, Bow
- Armor: Mail, Light armor, Shield, Helm, Cloak, Gloves, Boots

**Process:**
1. Player selects item category
2. Random sval selected via `pick_random_sval()`
3. Random ego applied via `pick_random_ego()`
4. Item given to player

**Costs:**
- **XP: 500 (flat)**
- Forge uses: 1
- Broken items: 2

**Code Reference (lines 6173-6177):**
```c
/* Deduct XP cost (500 for enchanted item) */
if (p_ptr->new_exp >= 500)
{
    p_ptr->new_exp -= 500;
}
```

---

### 7. Reclaim (g)

**Location:** `src/cmd4.c:6190-6385` - `reclaim_menu()`

**Description:** Combine 2 Broken Strange items to create a random artifact.

**Requirements:**
- Reclaim ability (Smithing level 7+, requires Reforge)
- 2 Broken Strange items
- At forge with uses remaining

**Input Items:**
- Broken Strange Weapon (K_IDX 493)
- Twisted Shadow-plate (K_IDX 494)
- Broken Strange Jewelry (K_IDX 495)

**Output Selection:**
- Weapons: Sword, Polearm, Hafted, Bow, or Any
- Armor: Mail, Light, Shield, Helm, Cloak, Gloves, Boots, or Any
- Jewelry: Ring, Amulet, or Any

**Process:**
1. Player selects category (weapon/armor/jewelry)
2. Player selects type or "any"
3. `pick_random_artifact(tval_list, FALSE)` selects artifact
4. Artifact created and given to player

**Costs:**
- **XP: artifact_level * 50**
- Forge uses: 1
- Broken items: 2

**Code Reference (lines 6367-6373):**
```c
/* Deduct XP cost based on artifact level */
{
    int xp_cost = a_ptr->level * 50;
    if (p_ptr->new_exp >= xp_cost)
    {
        p_ptr->new_exp -= xp_cost;
    }
}
```

**Example Costs:**
- Level 5 artifact: 250 XP
- Level 10 artifact: 500 XP
- Level 15 artifact: 750 XP
- Level 20 artifact: 1000 XP

---

### 8. Masterwork (h)

**Location:** `src/cmd4.c:6390-6585` - `masterwork_menu()`

**Description:** Combine 4 Broken Strange items to create a legendary (best) artifact.

**Requirements:**
- Masterwork ability (Smithing level 8+, requires Reclaim)
- 4 Broken Strange items
- At forge with uses remaining

**Process:**
1. Same selection as Reclaim
2. `pick_random_artifact(tval_list, TRUE)` selects BEST artifact
3. Artifact created and given to player

**Costs:**
- **XP: artifact_level * 100** (2x Reclaim cost)
- Forge uses: 1
- Broken items: 4

**Code Reference (lines 6567-6573):**
```c
/* Deduct XP cost based on artifact level (premium for masterwork) */
{
    int xp_cost = a_ptr->level * 100;
    if (p_ptr->new_exp >= xp_cost)
    {
        p_ptr->new_exp -= xp_cost;
    }
}
```

**Example Costs:**
- Level 10 artifact: 1000 XP
- Level 15 artifact: 1500 XP
- Level 20 artifact: 2000 XP

---

### 9. Accept/Resume (i)

**Location:** `src/cmd4.c:7134-7193` - `create_smithing_item()`

**Description:** Finalize and create the designed item.

**Requirements:**
- Item must be affordable (`affordable()` returns TRUE)
- At forge with uses remaining
- All ability requirements met

**Costs Deducted:** (via `pay_costs()` at lines 3872-3897)
- Stat drains (str, dex, con, gra)
- Experience points
- Mithril
- Forge uses
- Smithing skill drain (for difficult items)

---

## Broken Item Types

| K_IDX | Name | Use | Source |
|-------|------|-----|--------|
| 491 | Broken Glowing Weapon | Reforge (weapons) | Monster drops |
| 492 | Shattered Elven Mail | Reforge (armor) | Monster drops |
| 493 | Broken Strange Weapon | Reclaim/Masterwork (weapons) | Rare drops |
| 494 | Twisted Shadow-plate | Reclaim/Masterwork (armor) | Rare drops |
| 495 | Broken Strange Jewelry | Reclaim/Masterwork (jewelry) | Rare drops |

---

## Forge Types and Bonuses

| Forge Type | Feature Range | Uses | Skill Bonus |
|------------|--------------|------|-------------|
| Orc Forge (Normal) | 0x40-0x45 | 0-5 | +0 |
| Shadow Forge (Good) | 0x46-0x4B | 3-8 | +3 |
| Angdur (Unique) | 0x4C-0x4F | varies | +7 |

**Location:** `src/cmd4.c:2860-2891` - `forge_uses()` and `forge_bonus()`

---

## Key Findings

1. **Reforge, Reclaim, Masterwork already have XP costs** - contrary to PRD assumption
2. **Costs scale with artifact level** - 50 XP/level for Reclaim, 100 XP/level for Masterwork
3. **Flat 500 XP for Reforge** - regardless of item power
4. **No skill-based discount** - XP costs don't decrease with higher Smithing
5. **"Artifice" UI text is a Sil-Q remnant** - should be renamed
