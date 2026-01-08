# The Necromancer - Alpha 0.4.4 Release Notes

**Release Date**: 2026-01-09

---

## Overview

This release focuses on item naming consistency, replacing generic item names with evocative names that reflect the Third Age setting of Middle-earth. All 36 renamed items now have flavor text describing their origins and purpose.

---

## Item Renames (36 total)

### Weapons (18 items)

| Old Name | New Name |
|----------|----------|
| Dagger | Ranger's Knife |
| Curved Sword | Orc-blade |
| Shortsword | Woodland Blade |
| Bastard Sword | Rohirrim Blade |
| Greatsword | Númenórean Blade |
| Mithril Longsword | Mithril Sword |
| Mithril Greatsword | Mithril Great-blade |
| Spear | Hunting Spear |
| Great Spear | Tower Guard Spear |
| Glaive | Morgul Glaive |
| Hand Axe | Woodsman's Axe |
| Battle Axe | Dwarven War-axe |
| Great Axe | Erebor Great-axe |
| Quarterstaff | Oak Staff |
| War Hammer | Dwarven Hammer |
| Shortbow | Silvan Bow |
| Shovel | Miner's Spade |
| Mattock | Dwarf Mattock |

### Armor (8 items)

| Old Name | New Name |
|----------|----------|
| Robe | Wanderer's Robe |
| Leather Armour | Ranger Leathers |
| Studded Leather | Scout's Armor |
| Galvorn Armour | Shadow-steel Armor |
| Mail Corslet | Gondor Corslet |
| Hauberk | Dwarven Hauberk |
| Broken Glowing Armor | Shattered Elven Mail |
| Broken Strange Armor | Twisted Shadow-plate |

### Equipment (10 items)

| Old Name | New Name |
|----------|----------|
| Pair of Boots | Traveler's Boots |
| Pair of Greaves | Iron Greaves |
| Pair of Shabby Boots | Worn Boots |
| Set of Gloves | Leather Gloves |
| Set of Gauntlets | Iron Gauntlets |
| Helm | Iron Helm |
| Great Helm | Tower Helm |
| Rusty Helm | Rusted Helm |
| Round Shield | Buckler |
| Kite Shield | Tower Shield |
| Broken Shield | Shattered Shield |
| Cloak | Traveler's Cloak |
| Lesser Jewel | Elven Light |
| Feanorian Lamp | Jewel-lamp |

---

## Design Rationale

### Third Age Theming
Item names now reference cultures and locations from the Third Age of Middle-earth:
- **Gondor**: Tower Guard Spear, Tower Helm, Tower Shield, Gondor Corslet
- **Rohan**: Rohirrim Blade
- **Dwarves**: Dwarven War-axe, Dwarven Hammer, Dwarven Hauberk, Erebor Great-axe, Dwarf Mattock
- **Elves**: Woodland Blade, Silvan Bow, Elven Light, Shattered Elven Mail
- **Rangers**: Ranger's Knife, Ranger Leathers
- **Númenor**: Númenórean Blade

### First Age References Removed
Two items had First Age references that were removed for setting consistency:
- **Galvorn Armour** → **Shadow-steel Armor** (Galvorn was invented by Eöl in the First Age)
- **Feanorian Lamp** → **Jewel-lamp** (Fëanor is a First Age character)

### Flavor Text
All renamed items now have descriptive flavor text providing context about their origins, typical users, and combat characteristics.

---

## Technical Notes

- All item stats remain unchanged
- Existing save files are compatible
- Artifact generation unaffected (uses tval:sval references)

---

## Files Modified

- `lib/edit/object.txt` - Item names and descriptions
- `lib/edit/artefact.txt` - Documentation comments updated
- `src/xtra2.c` - Documentation comments updated

---

*The Necromancer is a Tolkien-themed roguelike based on Sil-Q.*
