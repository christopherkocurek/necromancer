# Item Reference Map - The Necromancer
## AUDIT-004: Cross-File Item Name References

---

## Overview

This document maps where each base item name appears in the SIL-Q codebase. Key findings:

1. **No item names in monster.txt or vault.txt** - Use symbolic references
2. **No ego_item.txt** - Ego items defined in special.txt using numeric tval/sval
3. **Most code references are comments** - Actual item creation uses numeric IDs
4. **artefact.txt is primary data file** - Contains most item name references
5. **ability.txt has many category references** - For ability eligibility

---

## Weapons Reference Counts

| Item Name | Code (.c/.h) | Data (.txt) | Total | Risk Level |
|-----------|-------------|-------------|-------|------------|
| Dagger | 7 (comments) | 11 | 18 | LOW |
| Curved Sword | 0 | 4 | 4 | LOW |
| Shortsword | 0 | 9 | 9 | LOW |
| Longsword | 0 | 11 | 11 | LOW |
| Bastard Sword | 7 (comments) | 5 | 12 | LOW |
| Greatsword | 1 | 8 | 9 | MEDIUM* |
| Spear | 1 | 10 | 11 | MEDIUM* |
| Great Spear | 0 | 3 | 3 | LOW |
| Glaive | 0 | 6 | 6 | LOW |
| Hand Axe | 0 | 2 | 2 | LOW |
| Battle Axe | 0 | 5 | 5 | LOW |
| Great Axe | 0 | 4 | 4 | LOW |
| Quarterstaff | 0 | 3 | 3 | LOW |
| War Hammer | 0 | 11 | 11 | LOW |
| Shortbow | 5 (comments) | 7 | 12 | LOW |
| Longbow | 5 (comments) | 13 | 18 | LOW |
| Dragon-horn Bow | 0 | 3 | 3 | LOW |
| Shovel | 0 | 1 | 1 | LOW |
| Mattock | 0 | 5 | 5 | LOW |

*MEDIUM = Has hardcoded reference in xtra2.c for specific artifact creation

---

## Armor Reference Counts

| Item Name | Code (.c/.h) | Data (.txt) | Total | Risk Level |
|-----------|-------------|-------------|-------|------------|
| Robe | 0 | 6 | 6 | LOW |
| Leather Armour | 0 | 4 | 4 | LOW |
| Studded Leather | 0 | 3 | 3 | LOW |
| Galvorn Armour | 1 | 3 | 4 | MEDIUM* |
| Mail Corslet | 0 | 5 | 5 | LOW |
| Hauberk | 0 | 5 | 5 | LOW |
| Mithril Corslet | 0 | 3 | 3 | LOW |

*MEDIUM = Has hardcoded reference in xtra2.c (Armour of Maeglin)

---

## Equipment Reference Counts

| Item Name | Code (.c/.h) | Data (.txt) | Total | Risk Level |
|-----------|-------------|-------------|-------|------------|
| Boots | 11 | 21 | 32 | MEDIUM |
| Greaves | 0 | 8 | 8 | LOW |
| Gloves | 9 | 45 | 54 | MEDIUM |
| Gauntlets | 0 | 10 | 10 | LOW |
| Helm | 3 | 25 | 28 | MEDIUM |
| Great Helm | 0 | 3 | 3 | LOW |
| Dwarf Mask | 0 | 2 | 2 | LOW |
| Round Shield | 0 | 3 | 3 | LOW |
| Kite Shield | 0 | 4 | 4 | LOW |
| Cloak | 2 | 28 | 30 | MEDIUM |
| Shadow Cloak | 0 | 3 | 3 | LOW |
| Torch | 2 (comments) | 4 | 6 | LOW |
| Lantern | 0 | 1 | 1 | LOW |
| Arrow | 2 | 5 | 7 | LOW |

---

## Hardcoded Item Creation (xtra2.c)

Three items have hardcoded artifact creation in `/Users/christopherkocurek/sil-q/src/xtra2.c`:

1. **Line 2110**: Galvorn Armour of Maeglin
2. **Line 2116**: Iron Spear of Boldog
3. **Line 2125**: Greatsword 'Glend'

These require careful handling if base item names change.

---

## Files by Reference Type

### Primary Data Files (Item names appear directly)
- `lib/edit/artefact.txt` - Artifact base items
- `lib/edit/object.txt` - Base item definitions
- `lib/edit/ability.txt` - Ability item type eligibility

### Secondary Data Files (Some item names)
- `lib/edit/special.txt` - Ego item comments
- `lib/edit/race.txt` - Race starting items
- `lib/edit/changes.txt` - Changelog
- `lib/edit/early-changes.txt` - Early changelog

### Code Files (Mostly comments)
- `src/cmd1.c` - Combat calculation comments
- `src/wizard1.c` - Debug/wizard mode strings
- `src/wizard2.c` - Debug/wizard mode strings
- `src/squelch.c` - Squelch category names
- `src/cmd4.c` - UI category names
- `src/object1.c` - Object description comments
- `src/cave.c` - Light source comments
- `src/xtra2.c` - **HARDCODED ARTIFACT CREATION**

### Files with NO item name references
- `lib/edit/monster.txt` - Uses symbol codes
- `lib/edit/vault.txt` - Uses symbol codes
- `lib/edit/flavor.txt` - Potion/scroll flavors only
- `lib/edit/terrain.txt` - Terrain definitions

---

## Risk Assessment Summary

| Risk Level | Count | Notes |
|------------|-------|-------|
| HIGH | 0 | No items require extensive code changes |
| MEDIUM | 7 | Boots, Gloves, Helm, Cloak (UI strings), Greatsword/Spear/Galvorn (hardcoded artifacts) |
| LOW | 50+ | Most items only referenced in data files |

---

## Implementation Notes

### For Data File Changes
Most items only need changes in:
1. `object.txt` - Base item definition (required)
2. `artefact.txt` - Artifact base item name (if applicable)
3. `ability.txt` - Ability type comments (optional, cosmetic)

### For Code Changes (MEDIUM risk items)
1. **Boots, Gloves, Helm, Cloak**: Category strings in wizard1.c, wizard2.c, squelch.c, cmd4.c - UI display names
2. **Greatsword, Spear, Galvorn Armour**: Hardcoded artifact creation in xtra2.c - must update string literals

### Recommended Approach
1. Change item names in object.txt first
2. Update artefact.txt to match
3. Search and replace in code files as needed
4. Test artifact creation (Glend, Boldog, Maeglin)
