# Implementation Checklist - Item Renames
## The Necromancer Alpha 0.4.4

**Generated**: 2026-01-09
**Source**: MASTER_RENAME_TABLE.md (with approved edits)
**Total Renames**: 36

---

## WEAPONS (16 renames)

| ID | Old Name | New Name | Flavor Text |
|----|----------|----------|-------------|
| 56 | Dagger | Ranger's Knife | A keen blade favored by the Dúnedain. Light enough to throw, sharp enough to kill. |
| 57 | Curved Sword | Orc-blade | A crude scimitar forged in the shadow of Dol Guldur. The edge is notched but hungry. |
| 60 | Shortsword | Woodland Blade | A short blade of elven make, favored by the wood-elves for its balance. |
| 67 | Bastard Sword | Rohirrim Blade | A long sword in the style of the Riddermark. It can be wielded with one or two hands. |
| 68 | Greatsword | Númenórean Blade | A greatsword of ancient design, forged in the style of Westernesse. It requires two hands to wield. |
| 69 | Mithril Longsword | Mithril Sword | A longsword forged of true-silver. Light as a feather, hard as dragon-scale. |
| 70 | Mithril Greatsword | Mithril Great-blade | A massive two-handed sword of mithril. Despite its size, it is remarkably light. |
| 71 | Spear | Hunting Spear | A simple spear used for hunting game. It serves well enough against darker prey. |
| 72 | Great Spear | Tower Guard Spear | A tall spear of Gondorian make, used by the Tower Guard in formal ceremonies and battle. |
| 74 | Glaive | Morgul Glaive | A wicked polearm touched by shadow. The blade seems to drink the light. |
| 76 | Hand Axe | Woodsman's Axe | A small axe meant for chopping wood, but deadly when thrown. |
| 77 | Battle Axe | Dwarven War-axe | A heavy axe of dwarven craft. The runes on its head are worn but still sharp. |
| 81 | Great Axe | Erebor Great-axe | A massive axe forged in the halls of Erebor. It requires both hands to wield. |
| 86 | Quarterstaff | Oak Staff | A sturdy staff of aged oak. Simple but effective. |
| 89 | War Hammer | Dwarven Hammer | A heavy hammer of dwarven make. Good for cracking skulls and ore alike. |
| 110 | Shortbow | Silvan Bow | A light bow of wood-elf make. Quick to draw and accurate. |
| 96 | Shovel | Miner's Spade | A sturdy digging tool. It can also bash skulls in a pinch. |
| 98 | Mattock | Dwarf Mattock | A heavy pick used by dwarven miners. Excellent for breaking through rock and armor. |

---

## ARMOR (8 renames)

| ID | Old Name | New Name | Flavor Text |
|----|----------|----------|-------------|
| 22 | Robe | Wanderer's Robe | A simple robe worn by travelers. It offers little protection but doesn't hinder movement. |
| 23 | Leather Armour | Ranger Leathers | Supple leather armor favored by the Rangers of the North. Quiet and flexible. |
| 26 | Studded Leather | Scout's Armor | Leather armor reinforced with metal studs. Favored by scouts and skirmishers. |
| 27 | Galvorn Armour | Shadow-steel Armor | Armor forged of a strange black metal, supple as leather but strong as mail. Its origins are dark. |
| 30 | Mail Corslet | Gondor Corslet | A mail shirt of Gondorian make, covering from shoulder to waist. |
| 31 | Hauberk | Dwarven Hauberk | A long mail shirt of dwarven craft, protecting from neck to knee. |
| 492 | Broken Glowing Armor | Shattered Elven Mail | Fragments of elven armor that still glow with faint enchantment. Perhaps it can be reforged. |
| 494 | Broken Strange Armor | Twisted Shadow-plate | Shards of dark armor from some fell creature. The metal seems to shift in the light. |

---

## EQUIPMENT (12 renames)

| ID | Old Name | New Name | Flavor Text |
|----|----------|----------|-------------|
| 122 | Pair of Boots | Traveler's Boots | Sturdy boots for long roads. They've seen many leagues. |
| 123 | Pair of Greaves | Iron Greaves | Metal plates that protect the lower legs. Heavy but effective. |
| 421 | Pair of Shabby Boots | Worn Boots | Old boots that have seen better days. They still keep out the worst of the mud. |
| 125 | Set of Gloves | Leather Gloves | Simple gloves of tanned leather. They protect the hands without hindering dexterity. |
| 126 | Set of Gauntlets | Iron Gauntlets | Heavy metal gloves that protect the hands in combat. |
| 100 | Helm | Iron Helm | A simple iron helm. It protects the head at the cost of peripheral vision. |
| 101 | Great Helm | Tower Helm | A tall helm in the style of the Tower Guard. It bears a small silver star. |
| 420 | Rusty Helm | Rusted Helm | An old helm covered in rust. It offers some protection, but not much. |
| 43 | Round Shield | Buckler | A small round shield, easy to maneuver but offering limited coverage. |
| 44 | Kite Shield | Tower Shield | A tall shield that covers from shoulder to knee. Favored by the Tower Guard. |
| 422 | Broken Shield | Shattered Shield | The remains of a once-sturdy shield. It might deflect a blow or two. |
| 106 | Cloak | Traveler's Cloak | A weathered cloak that keeps off rain and wind. It helps you blend into shadows. |
| 21 | Lesser Jewel | Elven Light | A small crystal that glows with inner light. The elves craft these as gifts. |
| 130 | Feanorian Lamp | Jewel-lamp | A crystal lamp that shines with captured starlight. It never dims or goes out. |

---

## FILES TO UPDATE

### Primary
- [ ] lib/edit/object.txt - All 36 N: and D: lines

### Secondary (references)
- [ ] lib/edit/artefact.txt - Base item references
- [ ] src/xtra2.c - 3 hardcoded strings (Galvorn Armour, Spear, Greatsword)
- [ ] src/*.c - Any other hardcoded strings
- [ ] lib/edit/monster.txt - Drop references
- [ ] lib/edit/vault.txt - Item spawns
- [ ] lib/edit/ego_item.txt - Base item references

---

## HARDCODED REFERENCES (xtra2.c)

| Line Area | Old String | New String | Context |
|-----------|------------|------------|---------|
| ~2110 | "Galvorn Armour" | "Shadow-steel Armor" | Maeglin artifact |
| ~2116 | "Spear" | "Hunting Spear" | Boldog artifact |
| ~2125 | "Greatsword" | "Númenórean Blade" | Glend artifact |

---

*Checklist generated for PREP-002*
