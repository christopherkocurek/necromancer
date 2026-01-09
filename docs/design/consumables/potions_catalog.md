# Potions Catalog
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: lib/edit/object.txt, src/use-obj.c

---

## Overview

| Metric | Value |
|--------|-------|
| Total Potions | 18 |
| Beneficial | 14 |
| Harmful | 6 |
| tval | TV_POTION (75) |
| Implementation | src/use-obj.c lines 197-457 |

---

## Beneficial Potions (14)

### Healing & Recovery

| ID | Name | sval | Depth | Effect | Code Reference |
|----|------|------|-------|--------|----------------|
| 313 | Miruvor | 0 | 11 | Cures stunning, confusion, hallucination, poison, blindness, cuts, fear. Restores 50% health and all voice. | SV_POTION_MIRUVOR |
| 315 | Orcish Liquor | 2 | 3 | Banishes fear, cures 25% health, stuns for 2d4 turns | SV_POTION_ORCISH_LIQUOR |
| 318 | Healing | 5 | 9 | Heals all cuts, restores 50% health | SV_POTION_HEALING |
| 321 | Antidote | 8 | 2 | Cures any current poisoning | SV_POTION_ANTIDOTE |

### Mental & Perception

| ID | Name | sval | Depth | Effect | Code Reference |
|----|------|------|-------|--------|----------------|
| 316 | Esgalduin | 3 | 4 | +10 perception for 20d4 turns, restores 25% voice | SV_POTION_ESGALDUIN |
| 317 | Clarity | 4 | 6 | Cures stunning, confusion, hallucination; ends rage | SV_POTION_CLARITY |
| 319 | Voice | 6 | 13 | Renews voice (full restore) | SV_POTION_VOICE |
| 320 | True Sight | 7 | 5 | Restores sight, resist blindness/hallucination, see invisible for 10d4 turns | SV_POTION_TRUE_SIGHT |

### Stat Boosting (Temporary)

| ID | Name | sval | Depth | Effect | Duration | Code Reference |
|----|------|------|-------|--------|----------|----------------|
| 327 | Strength | 14 | 6 | +3 STR, restores STR | 20d4 turns | SV_POTION_STR |
| 328 | Dexterity | 15 | 7 | +3 DEX, restores DEX | 20d4 turns | SV_POTION_DEX |
| 329 | Constitution | 16 | 8 | +3 CON, restores CON | 20d4 turns | SV_POTION_CON |
| 330 | Grace | 17 | 9 | +3 GRA, restores GRA | 20d4 turns | SV_POTION_GRA |

### Combat Buffs

| ID | Name | sval | Depth | Effect | Code Reference |
|----|------|------|-------|--------|----------------|
| 322 | Quickness | 9 | 5 | +1 speed for 10d4 turns | SV_POTION_QUICKNESS |
| 323 | Elemental Resistance | 10 | 12 | Resist fire and cold for 20d4 turns | SV_POTION_ELEM_RESISTANCE |

---

## Harmful Potions (6)

| ID | Name | sval | Depth | Effect | Code Reference |
|----|------|------|-------|--------|----------------|
| 343 | Slowness | 22 | 2 | -1 speed for 10d4 turns | SV_POTION_SLOWNESS |
| 344 | Poison | 23 | 3 | 5d4 points of poison | SV_POTION_POISON |
| 345 | Blindness | 24 | 4 | Blindness for 10d4 turns | SV_POTION_BLINDNESS |
| 346 | Confusion | 25 | 6 | Confusion for 5d4 turns | SV_POTION_CONFUSION |
| 348 | Awkwardness | 27 | 9 | Permanently reduces DEX by 1 | SV_POTION_DEC_DEX |
| 350 | Disconnection | 29 | 11 | Permanently reduces GRA by 1 | SV_POTION_DEC_GRA |

---

## Potion Depth Distribution

```
Depth  Potions
 2     Antidote, Slowness
 3     Orcish Liquor, Poison
 4     Esgalduin, Blindness
 5     True Sight, Quickness
 6     Clarity, Strength, Confusion
 7     Dexterity
 8     Constitution
 9     Healing, Grace, Awkwardness
11     Miruvor, Disconnection
12     Elemental Resistance
13     Voice
```

---

## Implementation Notes

### Allocation Format (A: line)
Format: `A:depth1/rarity1:depth2/rarity2`
- Lower rarity = more common
- Example: `A:9/1:15/1` means appears at depth 9+ with rarity 1

### Flags
- All potions have `EASY_KNOW` flag (identified on first use)

### Code Structure
Potions are handled in `src/use-obj.c` function `quaff_potion()`:
- Switch on sval (subtype value)
- Each case implements the specific effect
- Returns TRUE if something happens (for identification)

---

## Tolkien Theming Analysis

| Potion | Tolkien Reference | Theme Fit |
|--------|-------------------|-----------|
| Miruvor | Cordial of Imladris | Strong - canonical |
| Orcish Liquor | Orc grog from books | Strong - fits lore |
| Esgalduin | River in Doriath | Medium - name reference |
| Lembas | Elvish waybread | Strong - canonical (but it's food) |
| Athelas | Kingsfoil herb | Strong - canonical (but it's food) |
| Others | Generic fantasy | Weak - no specific Tolkien reference |

---

## Gaps Identified

1. **No Ent-draught** - Would fit for stat restoration
2. **No Old Toby** - Pipeweed could have calming effects
3. **Generic stat potions** - Could be renamed with lore references
4. **Harmful potions** - Could be "Morgul draughts" or orc poisons

---

*Catalog generated for AUDIT-001*
