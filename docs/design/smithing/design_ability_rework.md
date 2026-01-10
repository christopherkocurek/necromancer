# Design: Smithing Ability Rework (Revised)

## Document: DESIGN-003
## Version: 2.0
## Date: 2026-01-10

---

## Design Principles

Based on GDD review:

1. **RNG First, Choice is Premium** - Player choice should be earned, not free
2. **Active > Passive** - Abilities should DO something
3. **Fun & Rewarding** - Each ability should feel impactful
4. **Thematic** - Dwarven craftsmanship: repair, refine, recycle

---

## Existing Ability Changes

### 1. Expertise (N:124) - TIERED REDUCTION

#### Current Description

```
D:Reduces the time taken to forge an item by half and
D: negates all experience and stat costs.
```

#### Problem

"Negates all costs" breaks XP economy for Reforge/Reclaim/Masterwork.

#### Proposed Change

```
N:124:Expertise
I:6:4:6
P:6/3
D:Reduces the time taken to forge an item by half and
D: reduces experience and stat costs by 50%. At Smithing
D: 10+, reduction increases to 75%.
T:21:8:8
T:31:0:99
```

#### Implementation

```c
int apply_expertise_discount(int base_cost)
{
    if (!p_ptr->active_ability[S_SMT][SMT_EXPERTISE])
        return base_cost;

    int skill = p_ptr->skill_base[S_SMT];

    if (skill >= 10)
        return base_cost * 25 / 100;  /* 75% reduction */
    else
        return base_cost * 50 / 100;  /* 50% reduction */
}
```

#### Rationale

- Still powerful and rewarding
- Never reaches 100% (preserves economy)
- Rewards continued investment (Smithing 10+)

---

### 2. Reforge (N:123) - DESCRIPTION FIX

#### Current Description

```
D:Allows you to combine two Broken Glowing items at a forge
D: to create an enchanted item of that type. You choose the
D: enchantment from all available types.
```

#### Problem

Says "You choose" but code picks randomly.

#### Proposed Change

```
N:123:Reforge
I:6:3:5
D:Allows you to combine two Broken Glowing items at a forge
D: to create a randomly enchanted item of that type. Costs
D: 600 experience points.
T:21:8:8
T:31:0:99
```

---

### 3. Grace (N:127) - KEEP AS-IS

Grace (+1 Grace) is fine as a mid-tier reward. The issue was lack of abilities AFTER Grace, not Grace itself.

---

## New Abilities

### Complete Ability List (Levels 2-20)

| Level | ID | Name | Effect |
|-------|-----|------|--------|
| 2 | 120 | Weaponsmith | Create weapons |
| 3 | 121 | Armoursmith | Create armor |
| 4 | 122 | Jeweller | Create jewelry, auto-ID |
| 5 | 123 | Reforge | 2 broken glowing → enchanted |
| 6 | 124 | Expertise | 50%/75% cost reduction, faster |
| 7 | 125 | Reclaim | 2 broken strange → artifact |
| 8 | 126 | Masterwork | 4 broken strange → best artifact |
| 10 | 127 | Grace | +1 Grace stat |
| 12 | 128 | Reforge Mastery | One reroll on Reforge |
| 14 | 129 | Salvage | 50% save destroyed items |
| 16 | 130 | Reclaim Mastery | Pick 1 of 3 artifacts |
| 18 | - | (Reserved) | Future expansion |
| 20 | 131 | Master Smith | Masterwork needs 2 items |

---

## Ability Details

### Reforge Mastery (Level 12)

```
N:128:Reforge Mastery
I:6:8:12
P:6/3
D:When using Reforge, you may reject the random result
D: once and reroll. You must accept the second result.
T:21:8:8
T:31:0:99
```

**Why it works:**
- RNG still determines outcomes
- Limited choice (one reroll)
- Active decision moment

---

### Salvage (Level 14)

```
N:129:Salvage
I:6:9:14
P:6/8
D:When equipment would be destroyed by acid, fire, or
D: breakage, there is a 50% chance to recover it as a
D: Broken Glowing item instead of losing it entirely.
```

**Why it works:**
- Tied to gameplay events
- Creates resource stream
- Thematic (dwarven resourcefulness)
- RNG-based (50%)

**Note:** Requires gear-destroying events to be meaningful. See DESIGN-006.

---

### Reclaim Mastery (Level 16)

```
N:130:Reclaim Mastery
I:6:10:16
P:6/5
D:When using Reclaim, you are shown three random artifacts
D: of the chosen type and may select which one to create.
T:21:8:8
T:31:0:99
```

**Why it works:**
- RNG determines pool (3 random)
- Limited choice (pick 1 of 3)
- Premium choice at premium level
- Very rewarding

---

### Master Smith (Level 20)

```
N:131:Master Smith
I:6:11:20
P:6/6
D:Your legendary skill allows you to create Masterwork
D: items with only 2 Broken Strange items instead of 4.
T:21:8:8
T:31:0:99
```

**Why it works:**
- Reduces scarcest resource
- Makes Masterwork accessible 2+ times per game
- Huge reward for Smithing 20
- Simple, clear, powerful

---

## Prerequisite Chain

```
Weaponsmith (2)
    |
Armoursmith (3)
    |
Jeweller (4)
    |
Reforge (5)
   /    \
Expertise(6)  Reforge Mastery(12)
   |              |
Reclaim(7)    Salvage(14)
   |
Masterwork(8)  Reclaim Mastery(16)
   |
Grace(10)
   |
Master Smith(20)
```

---

## Removed Abilities (from v1.0 Proposal)

| Removed | Reason |
|---------|--------|
| Double Enchant | Violates "choice is premium" |
| Resistance Crafting | Too powerful, removes RNG |
| Efficient Smith | Boring passive |
| Greater Efficiency | Boring passive |
| Forge Bond | No trading in game |
| "Create seen artifact" | May never see good artifacts |

---

## Code Changes Required

### src/defines.h

```c
/* Smithing ability indices */
#define SMT_WEAPONSMITH      0
#define SMT_ARMOURSMITH      1
#define SMT_JEWELLER         2
#define SMT_REFORGE          3
#define SMT_EXPERTISE        4
#define SMT_RECLAIM          5
#define SMT_MASTERWORK       6
/* Grace is index 7 */
#define SMT_REFORGE_MASTERY  8
#define SMT_SALVAGE          9
#define SMT_RECLAIM_MASTERY  10
#define SMT_MASTER           11
```

### src/cmd4.c

1. **Expertise discount:** Implement tiered 50%/75% reduction
2. **Reforge Mastery:** Add reroll logic in `reforge_menu()`
3. **Reclaim Mastery:** Add 3-choice logic in `reclaim_menu()`
4. **Master Smith:** Change required items in `masterwork_menu()`

### src/object2.c (or similar)

5. **Salvage:** Hook into item destruction to check for salvage

---

## lib/edit/ability.txt Changes

### Modify Existing

```
# Reforge - fix description
N:123:Reforge
I:6:3:5
D:Allows you to combine two Broken Glowing items at a forge
D: to create a randomly enchanted item of that type. Costs
D: 600 experience points.
T:21:8:8
T:31:0:99

# Expertise - tiered reduction
N:124:Expertise
I:6:4:6
P:6/3
D:Reduces the time taken to forge an item by half and
D: reduces experience and stat costs by 50%. At Smithing
D: 10+, reduction increases to 75%.
T:21:8:8
T:31:0:99
```

### Add New

```
N:128:Reforge Mastery
I:6:8:12
P:6/3
D:When using Reforge, you may reject the random result
D: once and reroll. You must accept the second result.
T:21:8:8
T:31:0:99

N:129:Salvage
I:6:9:14
P:6/8
D:When equipment would be destroyed, 50% chance to
D: recover it as a Broken Glowing item instead.

N:130:Reclaim Mastery
I:6:10:16
P:6/5
D:When using Reclaim, choose from three random artifacts
D: instead of receiving one randomly.
T:21:8:8
T:31:0:99

N:131:Master Smith
I:6:11:20
P:6/6
D:Masterwork requires only 2 Broken Strange items
D: instead of 4. True mastery of the forge.
T:21:8:8
T:31:0:99
```

---

## Testing Checklist

### Existing Abilities

- [ ] Expertise applies 50% at Smithing 6-9
- [ ] Expertise applies 75% at Smithing 10+
- [ ] Reforge description matches behavior
- [ ] All existing abilities still work

### New Abilities

- [ ] Reforge Mastery allows one reroll
- [ ] Reforge Mastery blocks second reroll
- [ ] Salvage triggers on item destruction
- [ ] Salvage 50% rate is correct
- [ ] Salvage creates appropriate Broken item
- [ ] Reclaim Mastery shows 3 options
- [ ] Reclaim Mastery lets player pick
- [ ] Master Smith reduces requirement to 2
- [ ] All prerequisites work correctly

### Integration

- [ ] Ability tree displays correctly
- [ ] All abilities purchasable
- [ ] XP costs correct
- [ ] No crashes
- [ ] Savefiles compatible

---

## Implementation Order

1. **Fix Expertise** - Change to 50%/75% tiered
2. **Fix Reforge description** - Match random behavior
3. **Add Reforge Mastery** - Reroll logic
4. **Add Master Smith** - Simple item count change
5. **Add Reclaim Mastery** - 3-choice selection
6. **Add Salvage** - Hook destruction events

Steps 1-4 are simpler. Steps 5-6 are more complex.
