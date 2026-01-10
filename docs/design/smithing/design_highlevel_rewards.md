# Design: High-Level Smithing Rewards (Revised)

## Document: DESIGN-002
## Version: 2.0
## Date: 2026-01-10

---

## Design Principles (from GDD Review)

1. **RNG First, Choice is Premium** - Randomness is default; player choice costs extra
2. **Active > Passive** - Abilities should DO something, not just be invisible modifiers
3. **Fun & Rewarding** - Each ability should feel impactful
4. **Thematic** - Dwarven craftsmanship: repair, refine, recycle

---

## Revised Ability Schedule

| Level | Ability | Effect |
|-------|---------|--------|
| 10 | Grace | +1 Grace stat (existing) |
| 12 | Reforge Mastery | One reroll on Reforge results |
| 14 | Salvage | 50% chance to save destroyed items |
| 16 | Reclaim Mastery | Pick 1 of 3 random artifacts |
| 18 | (Reserved) | Future expansion |
| 20 | Master Smith | Masterwork costs 2 Strange instead of 4 |

---

## Detailed Ability Designs

### Level 12: Reforge Mastery

#### Description

```
N:128:Reforge Mastery
I:6:8:12
P:6/3
D:When using Reforge, you may reject the random result
D: once and reroll. You must accept the second result.
T:21:8:8
T:31:0:99
```

#### Mechanics

- After Reforge generates a random enchanted item, display it to player
- Player chooses: "Accept" or "Reroll (1 remaining)"
- If reroll chosen, generate new random item
- Second result is final - no further rerolls
- XP cost paid only once (on initial Reforge)

#### Implementation

**File:** src/cmd4.c - `reforge_menu()`

```c
/* After generating item */
if (p_ptr->active_ability[S_SMT][SMT_REFORGE_MASTERY])
{
    /* Show item to player */
    /* Prompt: Accept or Reroll? */
    if (player_chooses_reroll && !already_rerolled)
    {
        /* Generate new item */
        already_rerolled = TRUE;
    }
}
```

#### Why This Works

- ✅ RNG still determines outcomes
- ✅ Choice is LIMITED (one reroll only)
- ✅ Active decision moment
- ✅ Feels rewarding - dodge bad RNG once

---

### Level 14: Salvage

#### Description

```
N:129:Salvage
I:6:9:14
P:6/8
D:When equipment would be destroyed by acid, fire, or
D: breakage, there is a 50% chance to recover it as a
D: Broken Glowing item instead of losing it entirely.
```

#### Mechanics

- Triggers when: acid destroys armor, fire destroys items, weapons break
- 50% chance (RNG roll)
- Success: Item becomes Broken Glowing (weapon or armor as appropriate)
- Failure: Item destroyed as normal
- Message: "Your [item] shatters... but you salvage the remains!"

#### Implementation

**File:** src/object2.c - wherever item destruction occurs

```c
/* Before destroying item */
if (p_ptr->active_ability[S_SMT][SMT_SALVAGE])
{
    if (randint0(100) < 50)
    {
        /* Create appropriate Broken Glowing item */
        /* Message */
        return; /* Don't destroy */
    }
}
/* Normal destruction */
```

#### Why This Works

- ✅ Active effect tied to gameplay events
- ✅ Creates resource stream for Reforge
- ✅ Thematic - dwarven resourcefulness
- ✅ RNG-based (50% chance)

#### Dependency Note

**IMPORTANT:** This ability requires gear-destroying events to be meaningful. Current sources:
- Acid attacks (some monsters)
- Fire damage to inventory
- Weapon breakage (rare)

**Recommendation:** Review and potentially increase frequency of:
- Acid-using monsters in mid-game (Tier 2-3)
- Fire hazards that can damage inventory
- Weapon stress/breakage mechanics

See DESIGN-006: Loot and Destruction Events for details.

---

### Level 16: Reclaim Mastery

#### Description

```
N:130:Reclaim Mastery
I:6:10:16
P:6/5
D:When using Reclaim, you are shown three random artifacts
D: of the chosen type and may select which one to create.
D: This represents your expertise in guiding the reclamation.
T:21:8:8
T:31:0:99
```

#### Mechanics

1. Player selects category (weapon/armor/jewelry) as normal
2. Player selects type (sword/spear/etc.) as normal
3. System generates THREE random eligible artifacts
4. Display all three to player with stats
5. Player picks one
6. XP cost based on CHOSEN artifact's level

#### Implementation

**File:** src/cmd4.c - `reclaim_menu()`

```c
if (p_ptr->active_ability[S_SMT][SMT_RECLAIM_MASTERY])
{
    /* Generate 3 candidates */
    artifact_type *candidates[3];
    for (int i = 0; i < 3; i++)
    {
        candidates[i] = pick_random_artifact(tval_list, FALSE);
    }

    /* Display all 3 */
    /* Player selects */
    /* Create chosen one */
}
else
{
    /* Normal: single random artifact */
}
```

#### Why This Works

- ✅ RNG still determines the pool (3 random)
- ✅ Choice is LIMITED (pick 1 of 3, not anything)
- ✅ Premium choice requires Smithing 16
- ✅ Very rewarding - seeing options feels good

---

### Level 18: Reserved

This level is reserved for future expansion. Potential ideas:
- Enhanced Salvage (75% instead of 50%)
- Forge efficiency bonus
- Special material handling

For now, Smithing 17-19 provide only:
- Higher difficulty thresholds
- Expertise discount scaling (if implemented)

---

### Level 20: Master Smith

#### Description

```
N:131:Master Smith
I:6:11:20
P:6/6
D:Your legendary skill allows you to create Masterwork
D: items with only 2 Broken Strange items instead of 4.
D: You have mastered the art of extracting power from
D: even the smallest fragments.
T:21:8:8
T:31:0:99
```

#### Mechanics

- When using Masterwork action:
  - Without Master Smith: Requires 4 Broken Strange items
  - With Master Smith: Requires only 2 Broken Strange items
- Output unchanged: Still creates best artifact of type
- XP cost unchanged: Still artifact_level × 100 (or × 125 per cost redesign)

#### Implementation

**File:** src/cmd4.c - `masterwork_menu()`

```c
int required_items = 4;

if (p_ptr->active_ability[S_SMT][SMT_MASTER])
{
    required_items = 2;
}

/* Check player has required_items Broken Strange */
```

#### Why This Works

- ✅ Directly reduces the scarcest resource (Broken Strange)
- ✅ Makes Masterwork accessible more than once per game
- ✅ Huge reward for reaching Smithing 20
- ✅ Simple, clear, powerful

---

## Ability Tree Integration

### Updated Smithing Tree

```
Level 2:  Weaponsmith
Level 3:  Armoursmith
Level 4:  Jeweller
Level 5:  Reforge
Level 6:  Expertise (req: Reforge)
Level 7:  Reclaim (req: Reforge)
Level 8:  Masterwork (req: Reclaim)
Level 10: Grace
Level 12: Reforge Mastery (req: Reforge)
Level 14: Salvage (req: Reforge Mastery)
Level 16: Reclaim Mastery (req: Reclaim)
Level 18: (Reserved)
Level 20: Master Smith (req: Masterwork)
```

### Prerequisite Summary

| Ability | Prerequisite |
|---------|--------------|
| Reforge Mastery | Reforge (6/3) |
| Salvage | Reforge Mastery (6/8) |
| Reclaim Mastery | Reclaim (6/5) |
| Master Smith | Masterwork (6/6) |

---

## Removed from Original Proposal

| Removed Ability | Reason |
|-----------------|--------|
| Double Enchant | Violates "choice is premium" - too much direct control |
| Resistance Crafting | Too powerful, removes gear-finding RNG |
| Efficient Smith | Boring passive, not rewarding |
| Greater Efficiency | Boring passive, not rewarding |
| Forge Bond | No trading/selling in game, meaningless |
| "Create seen artifact" | May never see high-quality artifacts |

---

## Data File Changes

### lib/edit/ability.txt

Add after Grace (N:127):

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

---

## Dependencies and Related Work

### DESIGN-006: Loot and Destruction Events (NEW)

The Salvage ability requires gear-destroying events to be meaningful. A new design document should address:

1. **Current destruction sources** - Audit what can destroy gear
2. **Sil-Q comparison** - Compare loot density and destruction frequency
3. **Vault loot density** - Ensure rare/ego spawns match Sil-Q
4. **Broken item drop rates** - Verify Broken Glowing/Strange are appropriately rare

### Testing Requirements

- [ ] Reforge Mastery: Reroll works, limited to one
- [ ] Salvage: Triggers on destruction, 50% rate
- [ ] Reclaim Mastery: Shows 3 options, player picks
- [ ] Master Smith: Masterwork accepts 2 items

---

## Success Metrics

After implementation:

1. **Reforge Mastery adoption:** 40%+ of smiths reaching level 12 take it
2. **Salvage triggers:** Players report meaningful item recovery
3. **Reclaim Mastery satisfaction:** Players enjoy seeing options
4. **Master Smith impact:** Dedicated smiths can create 2+ masterworks per game
