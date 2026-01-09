# Staves Catalog
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: lib/edit/object.txt, src/use-obj.c, src/cmd6.c

---

## Overview

| Metric | Value |
|--------|-------|
| Total Staves | 16 |
| Beneficial | 14 |
| Harmful/Mixed | 2 |
| tval | TV_STAFF (55) |
| Symbol | _ (underscore) |
| Weight | 50 (all staves) |
| Charge System | Yes (pval stores charges) |

**Key Finding**: Staves in Sil-Q are NOT weapons. They are charge-based magic devices used for utility effects. This differs from Gandalf-style combat staves.

---

## All Staves

### Utility/Detection Staves

| ID | Name | sval | Depth | Value | Effect |
|----|------|------|-------|-------|--------|
| 193 | Light | 3 | 2 | 250 | Lights area (radius 7), stuns light-sensitive creatures |
| 192 | Freedom | 2 | 9 | 400 | Reveals doors/traps in LoS, may open/destroy them |
| 197 | Revelations | 7 | 13 | 400 | Reveals surroundings (map) |
| 198 | Treasures | 8 | 13 | 400 | Shows all items on level |
| 199 | Foes | 9 | 13 | 400 | Shows all monsters on level |
| 202 | Self Knowledge | 12 | 7 | 400 | Shows all your abilities |
| 196 | Understanding | 6 | 10 | 400 | Identifies an item (abortable) |

### Combat/Control Staves

| ID | Name | sval | Depth | Value | Effect |
|----|------|------|-------|-------|--------|
| 191 | Imprisonment | 1 | 6 | 400 | Shuts and locks all doors in LoS |
| 200 | Slumber | 10 | 11 | 400 | Causes weariness in all monsters in LoS |
| 201 | Majesty | 11 | 9 | 400 | Causes fear in all monsters in LoS |
| 204 | Dismay | 14 | 13 | 400 | Confuses all monsters in LoS |
| 203 | Warding | 13 | 11 | 400 | Creates glyphs of warding |
| 195 | Sanctity | 5 | 6 | 400 | Removes curses from items |
| 206 | Recharging | 16 | 11 | 400 | Partially recharges another staff |

### Harmful/Special Staves

| ID | Name | sval | Depth | Value | Effect |
|----|------|------|-------|-------|--------|
| 210 | Summoning | 17 | 7 | 0 | Summons monsters to stairs (harmful) |
| 211 | Shadows | 18 | 9 | 0 | Darkens area (radius 7) - tactical |

---

## Charge System

### How Charges Work
- Staves have `pval` which stores charge count
- Each use decrements pval by 1 (or more with Channeling)
- Staff of Recharging can restore charges
- "The staff has no charges left" when pval <= 0

### Channeling Ability
```c
if ((o_ptr->pval <= 1 && (!p_ptr->active_ability[S_WIL][WIL_CHANNELING]))
    || o_ptr->pval <= 0)
```
- Channeling ability allows using staffs with 1 charge
- Uses `CHANNELING_CHARGE_MULTIPLIER` for charge consumption
- Skilled users get more use from staves

---

## Implementation (src/use-obj.c)

```c
case SV_STAFF_IMPRISONMENT:  // Close/lock doors
case SV_STAFF_FREEDOM:       // Reveal/open doors/traps
case SV_STAFF_LIGHT:         // Light area, stun light-sensitive
case SV_STAFF_SANCTITY:      // Remove curses
case SV_STAFF_UNDERSTANDING: // Identify item
case SV_STAFF_REVELATIONS:   // Map area
case SV_STAFF_TREASURES:     // Detect items
case SV_STAFF_FOES:          // Detect monsters
case SV_STAFF_SLUMBER:       // Fatigue monsters
case SV_STAFF_MAJESTY:       // Fear monsters
case SV_STAFF_SELF_KNOWLEDGE:// Show abilities
case SV_STAFF_WARDING:       // Create glyphs
case SV_STAFF_DISMAY:        // Confuse monsters
case SV_STAFF_RECHARGING:    // Recharge staff
case SV_STAFF_SUMMONING:     // Summon monsters (harmful)
case SV_STAFF_SHADOWS:       // Darken area
```

---

## Staff Categories

### By Function

| Category | Staves | Count |
|----------|--------|-------|
| Detection | Light, Revelations, Treasures, Foes, Understanding | 5 |
| Crowd Control | Slumber, Majesty, Dismay, Imprisonment | 4 |
| Utility | Freedom, Sanctity, Self Knowledge, Warding, Recharging | 5 |
| Special | Summoning (harmful), Shadows (tactical) | 2 |

### By Depth

```
Depth 2:  Light
Depth 6:  Imprisonment, Sanctity
Depth 7:  Self Knowledge, Summoning
Depth 9:  Freedom, Majesty, Shadows
Depth 10: Understanding
Depth 11: Slumber, Warding, Recharging
Depth 13: Revelations, Treasures, Foes, Dismay
```

---

## Stealth Synergy Analysis

| Staff | Stealth Synergy | Notes |
|-------|-----------------|-------|
| Shadows | **Excellent** | Creates darkness for hiding |
| Slumber | **Good** | Neutralizes threats quietly |
| Imprisonment | **Good** | Locks doors for escape |
| Majesty | Good | Fear can scatter enemies |
| Dismay | Medium | Confused enemies less predictable |
| Light | **Poor** | Reveals you to enemies |
| Warding | Medium | Passive defense |

---

## Tolkien Theming Analysis

| Staff | Theme Reference | Fit |
|-------|-----------------|-----|
| Light | Gandalf's light in Moria | Strong |
| Shadows | Morgoth's darkness | Strong |
| Majesty | Presence of wizards | Medium |
| Revelations | Palantir-like seeing | Medium |
| Understanding | Wizard lore | Medium |
| Others | Generic fantasy | Weak |

### Missing Tolkien Concepts
- **Fire effects** - Gandalf used fire (no fire staff)
- **Blinding flash** - Used against goblins
- **Ward against evil** - Protection from shadow
- **Flame of Anor** - Combat staff ability

---

## Design Observations

### Current State
Staves are **utility devices**, not weapons:
- Cannot be wielded in combat
- No damage stats (P:0:0d0:0:0d0)
- Weight 50 across all (heavy for magic item)
- Charge-based usage

### Strengths
1. Good variety of utility effects
2. Charge system creates resource management
3. Channeling skill integration
4. Recharging staff allows sustainability

### Weaknesses
1. **Not weapons** - Cannot be used as Gandalf-style combat items
2. **Heavy** - 50 weight each limits carrying
3. **Generic names** - "Dismay", "Majesty" lack Tolkien flavor
4. **No combat staves** - No damage-dealing options
5. **Line of Sight only** - No targeted effects

### Gandalf-Style Staff Design (Hypothetical)
If staves were reworked as polearms:
- Main hand weapon (requires 2 hands?)
- Combat damage + spell casting
- Limited charges for special effects
- Skill: Will or Grace for casting
- Example: "Staff of the White" - 2d6 damage, can cast Light/Flash

---

## Wand Comparison

**Wands do not exist in Sil-Q**. Possible distinction:

| Attribute | Staff (current) | Wand (hypothetical) |
|-----------|-----------------|---------------------|
| Weight | 50 (heavy) | 5-10 (light) |
| Charges | Medium (3-10) | Many (10-30) |
| Effects | Powerful, utility | Weaker, targeted |
| Range | Line of Sight | Directional beam |
| Skill | Will | Grace or Perception |

---

*Catalog generated for AUDIT-004*
