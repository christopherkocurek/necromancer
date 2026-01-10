# Design: UI Text Cleanup

## Document: DESIGN-004
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document specifies all UI text changes needed to remove Sil-Q remnants and improve smithing interface clarity.

---

## "Artifice" Removal

### Current Occurrences

From AUDIT-003, "Artifice" appears in 7 locations in cmd4.c:

| Line | Context | Current Text |
|------|---------|--------------|
| 1864 | struct field | `int artifice;` |
| 2940 | initialization | `smithing_cost.artifice = 0;` |
| 3474 | cost setting | `smithing_cost.artifice = 1;` |
| 3651-3653 | UI display | `Term_putstr(..., "Artifice")` |
| 3862 | affordability | `|| smithing_cost.artifice)` |
| 6659 | menu label | `"c) Artifice"` |
| 6704 | help text | `"(not compatible with Artifice)"` |

### Proposed Changes

#### 1. Struct Field (line 1864)

```c
/* Before */
typedef struct smithing_cost_type {
    ...
    int artifice;
} smithing_cost_type;

/* After */
typedef struct smithing_cost_type {
    ...
    int custom_artifact;  /* Requires Reclaim ability */
} smithing_cost_type;
```

#### 2. Initialization (line 2940)

```c
/* Before */
smithing_cost.artifice = 0;

/* After */
smithing_cost.custom_artifact = 0;
```

#### 3. Cost Setting (line 3474)

```c
/* Before */
smithing_cost.artifice = 1;

/* After */
smithing_cost.custom_artifact = 1;
```

#### 4. UI Display (lines 3651-3653)

```c
/* Before */
if (smithing_cost.artifice)
{
    Term_putstr(COL_SMT4 + 2, 10 + costs, -1, TERM_RED, "Artifice");
    ...
}

/* After */
if (smithing_cost.custom_artifact)
{
    Term_putstr(COL_SMT4 + 2, 10 + costs, -1, TERM_RED, "Requires Reclaim");
    ...
}
```

#### 5. Affordability Check (line 3862)

```c
/* Before */
|| smithing_cost.artifice)

/* After */
|| smithing_cost.custom_artifact)
```

#### 6. Menu Label (line 6659)

```c
/* Before */
Term_putstr(..., "c) Artifice");

/* After */
Term_putstr(..., "c) Custom Artifact");
```

#### 7. Help Text (line 6704)

```c
/* Before */
"(not compatible with Artifice)"

/* After */
"(not compatible with Custom Artifact)"
```

---

## Cost Display Improvements

### Show XP Costs in Forge Menu

#### Current State

Reforge/Reclaim/Masterwork menus don't show XP costs before action.

#### Proposed Addition

Add cost display to each confirmation:

```c
/* In reforge_menu() before confirmation */
int xp_cost = apply_smithing_discounts(600);
prt(format("XP Cost: %d", xp_cost), row++, col);
prt("Press 'y' to confirm, 'n' to cancel", row++, col);
```

```c
/* In reclaim_menu() before confirmation */
int xp_cost = apply_smithing_discounts(a_ptr->level * 50);
prt(format("XP Cost: %d (artifact level %d)", xp_cost, a_ptr->level), row++, col);
```

```c
/* In masterwork_menu() before confirmation */
int xp_cost = apply_smithing_discounts(a_ptr->level * 125);
prt(format("XP Cost: %d (artifact level %d)", xp_cost, a_ptr->level), row++, col);
```

### Show Discount Information

#### In Main Forge Menu

Add discount summary:

```c
/* Display current discount rate */
int discount = 0;
if (p_ptr->active_ability[S_SMT][SMT_EFFICIENT]) discount += 25;
if (p_ptr->active_ability[S_SMT][SMT_GREATER_EFF]) discount += 19; /* compound */
if (p_ptr->active_ability[S_SMT][SMT_EXPERTISE]) discount += (100 - discount) / 2;

prt(format("XP Discount: %d%%", discount), row++, col);
```

---

## Menu Text Improvements

### Forge Main Menu

#### Current

```
a) Base item
b) Enchant
c) Artifice
d) Numbers
e) Melt
f) Reforge
g) Reclaim
h) Masterwork
```

#### Proposed

```
a) Base Item
b) Enchantment
c) Custom Artifact
d) Adjust Numbers
e) Melt Mithril
f) Reforge (2 Glowing → Enchanted)
g) Reclaim (2 Strange → Artifact)
h) Masterwork (4 Strange → Best)
```

### Menu Descriptions

Add brief descriptions to clarify each option:

```c
/* Base Item */
"Select the type of item to forge"

/* Enchantment */
"Add a special property (ego) to the item"

/* Custom Artifact */
"Design your own artifact with custom properties"

/* Adjust Numbers */
"Modify attack, damage, evasion, or protection"

/* Melt Mithril */
"Convert mithril items into raw mithril pieces"

/* Reforge */
"Combine broken glowing items into enchanted gear"

/* Reclaim */
"Combine broken strange items into an artifact"

/* Masterwork */
"Combine four broken strange items into the best artifact"
```

---

## Ability Menu Text

### Update Ability Descriptions

Ensure all smithing abilities have clear, accurate descriptions:

| Ability | Current | Proposed |
|---------|---------|----------|
| Weaponsmith | "Allows you to create weapons." | Keep |
| Armoursmith | "Allows you to create armour." | Keep |
| Jeweller | "Allows you to create rings..." | Keep |
| Reforge | "You choose the enchantment..." | "Randomly enchanted item..." |
| Expertise | "negates all experience..." | "reduces...by 50%" |
| Reclaim | OK | Keep |
| Masterwork | OK | Keep |
| Grace | OK | Keep |

---

## Error Messages

### Improve Error Clarity

#### Missing Ability

```c
/* Before */
"You need the Artifice ability"

/* After */
"You need the Reclaim ability to create custom artifacts"
```

#### Insufficient XP

```c
/* Before */
"Not enough experience"

/* After */
"Not enough experience (need %d XP, have %d XP)"
```

#### No Broken Items

```c
/* Before */
"You don't have the required items"

/* After */
"You need %d Broken %s items (have %d)"
```

---

## Confirmation Prompts

### Standardize Confirmations

All costly actions should have clear confirmation:

```c
/* Reforge */
"Reforge 2 Broken Glowing items into enchanted %s? [y/n]"
"XP Cost: %d"

/* Reclaim */
"Reclaim 2 Broken Strange items into artifact? [y/n]"
"XP Cost: %d (based on artifact level)"

/* Masterwork */
"Create masterwork from 4 Broken Strange items? [y/n]"
"XP Cost: %d (based on artifact level)"
```

---

## Implementation Checklist

### Variable Renames

- [ ] Rename `smithing_cost.artifice` → `smithing_cost.custom_artifact`
- [ ] Update all references (5 locations)
- [ ] Verify no compile errors

### UI Text Updates

- [ ] Update "Artifice" → "Custom Artifact" in menu
- [ ] Update "Artifice" → "Requires Reclaim" in cost display
- [ ] Update help text references
- [ ] Add cost display to Reforge/Reclaim/Masterwork
- [ ] Add discount display to main menu

### Description Updates

- [ ] Update Reforge description in ability.txt
- [ ] Update Expertise description in ability.txt
- [ ] Verify all descriptions match behavior

### Error Message Updates

- [ ] Update missing ability messages
- [ ] Add XP values to insufficient XP messages
- [ ] Add item counts to missing items messages

### Confirmation Updates

- [ ] Standardize confirmation format
- [ ] Add XP cost to all confirmations
- [ ] Ensure consistent [y/n] prompts

---

## Testing Requirements

### Visual Verification

- [ ] All menu text displays correctly
- [ ] No truncation or overflow
- [ ] Colors appropriate (red for missing reqs)

### Functional Verification

- [ ] Renamed variable compiles
- [ ] Custom Artifact menu works
- [ ] Cost displays are accurate
- [ ] Discount displays are accurate

### Regression Testing

- [ ] All forge actions still work
- [ ] No new bugs introduced
- [ ] Savefiles compatible
