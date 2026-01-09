# Alchemy Ability Audit
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: lib/edit/ability.txt, src/xtra1.c, src/defines.h

---

## Current Implementation

### Ability Definition (ability.txt:463)

```
N:84:Alchemy
I:4:4:5
D:Lets you determine the purpose of all herbs and potions you encounter.
D: A scholar's knowledge of the natural world.
T:32:0:99  # Helm
T:45:0:99  # Ring
```

### Parsed Fields
- **ID**: 84
- **Name**: Alchemy
- **I:4:4:5**: Skill tree 4 (Perception), position 4, prerequisite position 5
- **Description**: Auto-identify herbs and potions
- **T lines**: Can appear on Helms (32) and Rings (45)

---

## Code Implementation (src/xtra1.c:3194-3220)

```c
void update_lore_aux(object_type* o_ptr)
{
    if (!object_known_p(o_ptr))
    {
        bool alchemy = p_ptr->active_ability[S_PER][PER_ALCHEMY];
        bool foodOrPotion = o_ptr->tval == TV_FOOD || o_ptr->tval == TV_POTION;

        if (alchemy && foodOrPotion)
        {
            ident(o_ptr);
        }
    }
}
```

### What It Does
1. Checks if player has Alchemy ability active
2. Checks if item is food (TV_FOOD) or potion (TV_POTION)
3. If both true, automatically identifies the item

### What It Does NOT Do
- No crafting
- No combining items
- No recipe system
- No transmutation
- No potion brewing
- No herb processing

---

## Related Identification Abilities

| Ability | Skill | Effect |
|---------|-------|--------|
| **Alchemy** | Perception | Auto-ID herbs & potions |
| Channeling | Will | Auto-ID staves & horns |
| Jeweller | Smithing | Auto-ID rings, amulets, lights |
| Enchantment (Reforge) | Smithing | Auto-ID enchanted items |

---

## Skill Tree Location

Alchemy is in the **Perception** skill tree:
- `S_PER` (Perception skill)
- `PER_ALCHEMY` = 4 (position in tree)
- Prerequisite: position 5 in the tree

---

## Thematic Analysis

### Current Theme
"A scholar's knowledge of the natural world"
- Passive identification ability
- No active crafting component
- Scholarly/academic flavor

### Tolkien Fit
**Medium**. Tolkien characters like Aragorn knew herblore (Athelas usage), but this was practical knowledge, not academic identification.

---

## Comparison with Smithing

Sil-Q has a robust **Smithing** system for crafting:
- Forging weapons and armor
- Reforging and enchanting
- Uses forges found in the dungeon
- Multiple skills in the Smithing tree

**Alchemy has no equivalent crafting system.**

---

## Crafting Potential Analysis

### What Alchemy COULD Be (not currently implemented)

#### Option A: Potion Brewing
- Combine herbs + base liquid = potion
- Use cauldrons/alembics (like forges)
- Recipes discovered or learned

Example:
```
Athelas + Water = Potion of Lesser Healing
Athelas + Miruvor = Potion of Greater Healing
Herb of Rage + Orcish Liquor = Berserker Draught
```

#### Option B: Herb Processing
- Refine herbs for stronger effects
- Purify harmful herbs into beneficial ones
- Create antidotes

Example:
```
2x Herb of Healing = Concentrated Healing Herb
Herb of Sickness + Processing = Vaccine (poison resist)
```

#### Option C: Item Enhancement
- Apply potions to weapons (temporary effects)
- Create poison coatings
- Enhance food

Example:
```
Potion of Quickness + Arrow = Swift Arrow (temporary)
Potion of Poison + Blade = Poisoned Blade (limited uses)
```

---

## Implementation Complexity

| Feature | Complexity | Notes |
|---------|------------|-------|
| Current (ID only) | Trivial | Already done |
| Potion brewing | Medium | Need recipes, UI, containers |
| Herb processing | Low-Medium | Simpler than full brewing |
| Item enhancement | Medium-High | Affects combat balance |

### Key Implementation Questions
1. Where does crafting happen? (Anywhere? Special locations?)
2. What UI for recipe selection?
3. How to balance crafted items vs found items?
4. Should recipes be learned or known?

---

## Recommendation

### Short Term
Keep Alchemy as-is (identification). It serves its purpose.

### Medium Term
Consider **Herb Processing** as simplest crafting addition:
- 2 herbs of same type → 1 improved herb
- Remove harmful herbs → gain partial beneficial effect
- Would use existing items, minimal new content

### Long Term
Full **Potion Brewing** if crafting is a design priority:
- Requires cauldrons/alembics in dungeon
- Recipe discovery system
- New consumable types
- Significant implementation effort

---

## Questions for Design Review

1. **Is Alchemy meant to be passive only?** Current design is pure identification.

2. **Should it mirror Smithing?** Smithing has active crafting; should Alchemy?

3. **What Tolkien activities support crafting?**
   - Aragorn preparing athelas (simple)
   - Elves making lembas (complex, off-screen)
   - Dwarves brewing (mentioned but not detailed)

4. **Does crafting fit stealth gameplay?** Preparing consumables before dungeon delve supports planning.

---

*Audit generated for AUDIT-006*
