# Device/Magic Item System Audit
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: src/cmd6.c, src/use-obj.c, src/defines.h, lib/edit/ability.txt

---

## Device Categories in Sil-Q

| Type | tval | Symbol | Charges | Skill |
|------|------|--------|---------|-------|
| Staves | TV_STAFF (55) | _ | Yes | Will |
| Horns | TV_HORN (66) | ? | No* | Will |
| Potions | TV_POTION (75) | ! | No | None |
| Food/Herbs | TV_FOOD (80) | , | No | None |

*Horns are single-use, not charge-based

---

## Charge System Deep Dive

### Staff Charges (src/cmd6.c)

```c
// Staff charge consumption
if (p_ptr->active_ability[S_WIL][WIL_CHANNELING])
{
    o_ptr->pval--;  // Use 1 charge
}
else
{
    o_ptr->pval -= CHANNELING_CHARGE_MULTIPLIER;  // Use 2 charges
}
```

### Key Constants (defines.h)
```c
#define CHANNELING_CHARGE_MULTIPLIER 2
#define WIL_CHANNELING 1  // Position in Will skill tree
```

### Charge Display Logic (object2.c)
Without Channeling ability, displayed charges are halved:
```c
if (!p_ptr->active_ability[S_WIL][WIL_CHANNELING])
    visible_charges /= CHANNELING_CHARGE_MULTIPLIER;
```

This means a staff with 6 internal charges shows as "3 charges" to non-Channeling users.

---

## Key Ability: Force of Will (Channeling)

### Definition (ability.txt:515)
```
N:101:Force of Will
I:5:1:2
D:Your mental strength lets you recognise all staves and horns
D: and use them twice as efficiently.
T:32:0:99  # Helm
T:45:0:99  # Ring
```

### Effects
1. **Auto-identify** staves and horns on sight
2. **Double efficiency** - use 1 charge instead of 2
3. **Last charge access** - can use staff with 1 charge (non-Channeling can't)

### Skill Tree
- Skill: Will (S_WIL = 5)
- Position: 1 in tree
- Prerequisite: position 2

---

## Device Usage Flow

### Staff Usage (cmd6.c:do_cmd_use_staff)
1. Select staff from inventory
2. Check if empty (`IDENT_EMPTY` flag)
3. Take a turn (100 energy)
4. Check charges (different thresholds with/without Channeling)
5. Play sound (`MSG_ZAP`)
6. Call `use_object()` to execute effect
7. Break truce (hostile action)
8. Update identification state
9. Consume charges
10. Display remaining charges

### Horn Usage
- Single-use items
- Directional aiming required
- Breaks truce
- Loud (affects monster perception)

### Potion/Food Usage
- Single-use, always consumed
- No skill check
- No charge system
- Identified by Alchemy ability

---

## Skill Interactions

| Ability | Skill | Affects | Effect |
|---------|-------|---------|--------|
| Force of Will | Will | Staves, Horns | 2x efficiency, auto-ID |
| Alchemy | Perception | Potions, Food | Auto-ID |
| Jeweller | Smithing | Rings, Amulets, Lights | Auto-ID |
| Enchantment | Smithing | All equipment | Auto-ID |

---

## Truce System Integration

All device usage calls `break_truce(FALSE)`:
- Using staves breaks truce with monsters
- Using horns breaks truce (very loudly)
- Eating/drinking does NOT break truce (based on code review)

This creates tactical considerations - using devices in combat reveals you.

---

## Recharging Mechanics

### Staff of Recharging (use-obj.c:601)
```c
if (!recharge(CHANNELING_CHARGE_MULTIPLIER))
    return FALSE;
```
- Adds charges to another staff
- Amount based on Channeling ability
- Can fail or backfire (staff destruction?)

### No Other Recharge Methods
- No recharge potions
- No recharge scrolls
- No recharge abilities besides Staff of Recharging
- Resting does NOT restore charges

---

## Design Observations

### Strengths
1. **Channeling creates meaningful choice** - Will skill investment pays off
2. **Charge display is smart** - Shows "effective" charges based on ability
3. **Truce integration** - Device use has tactical cost
4. **Simple categorization** - Clear device types

### Weaknesses
1. **No failure chance** - Staves always work (no skill check)
2. **Binary efficiency** - Either 1x or 2x, no gradient
3. **Limited recharge** - Only Staff of Recharging
4. **No device skill** - Will affects efficiency but not success

### Comparison with Traditional Roguelikes

| Feature | Sil-Q | Angband | DCSS |
|---------|-------|---------|------|
| Device skill | No | Yes (Device) | Yes (Evocations) |
| Failure chance | No | Yes | Yes |
| Backfire | No | Limited | Yes |
| Recharge method | Staff only | Scrolls + staffs | Scrolls |
| Charge visibility | Modified by skill | Always shown | Always shown |

---

## Wand Implementation Space

If wands were added, they could fill gaps:

| Attribute | Staff | Wand (hypothetical) |
|-----------|-------|---------------------|
| Charges | 6-12 internal | 15-30 |
| Per use | 1-2 | 1 |
| Power | Strong AoE | Weak targeted |
| Weight | 50 | 10 |
| Skill | Will (Channeling) | Grace or Perception |
| Failure | None | Skill check |

---

## Code Architecture

### Key Files
- `src/cmd6.c` - Command handling for device use
- `src/use-obj.c` - Effect implementation
- `src/object1.c` - Object display (charge text)
- `src/object2.c` - Object generation, charge handling
- `src/defines.h` - Constants

### Key Functions
- `do_cmd_use_staff()` - Staff usage entry point
- `use_object()` - Effect dispatcher
- `recharge()` - Recharge staff mechanic
- `inven_item_charges()` - Display charge count

---

*Audit generated for AUDIT-007*
