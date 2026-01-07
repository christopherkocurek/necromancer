# The Necromancer - Alpha 0.2.0
## Release Notes & Design Documentation

**Date:** January 8, 2026  
**Build:** Alpha 0.2.0 - Smithing System Update  
**Base:** SIL-Q fork, Third Age Dol Guldur setting

---

## What's New in Alpha 0.2.0

### SMITHING SYSTEM OVERHAUL

The smithing system has been completely redesigned around a "Reclaiming the Past" philosophy. Instead of manually selecting enchantments, players find broken magical items and reforge them.

#### New Abilities
- **Reforge** (6:3) - Combine 2 Broken Glowing items → Enchanted item with random "of X" property
- **Reclaim** (6:5) - Combine 2 Broken Strange items → Random artifact from the legends of Middle-earth
- **Masterwork** (6:6) - Combine 4 Broken Strange items → Best artifact of that category

#### Removed Abilities
- Enchantment (old manual "of X" system)
- Artifice (old custom artifact system)  
- Masterpiece (replaced by Masterwork)

#### New Items
- Broken Glowing Weapon (N:491)
- Broken Glowing Armor (N:492)
- Broken Strange Weapon (N:493)
- Broken Strange Armor (N:494)
- Broken Strange Jewelry (N:495) - *Known issue: not fully working*

#### How It Works
1. Find Broken Glowing/Strange items as dungeon loot
2. Bring them to a forge
3. Use Reforge (2x Glowing), Reclaim (2x Strange), or Masterwork (4x Strange)
4. Receive a random enchanted item or artifact of that type
5. Base skill (Weaponsmith/Armoursmith/Jeweller) gates what types you can reforge

### THIRD AGE LORE UPDATES

#### special.txt (Ego Items)
Replaced First Age references with Third Age equivalents:
- Cuivienen → Rivendell
- Nargothrond → Dragon-bane
- Vanyar → the Eorlingas (Rohan)
- Feanorians → the Noldor
- Thangorodrim → the Deeps
- Udun → Shadow
- Mithrim → Lothlórien
- Helcaraxe → the North

New ego types added:
- of the Ranger (leather/cloaks/boots)
- of Gondor (mail/shields)
- of Westernesse (swords)
- of Mirkwood (bows/spears)
- of Lothlórien (bows/swords)
- of the Mark (spears/swords)
- of Erebor (axes/hammers)
- of Morgul (cursed weapons)
- of the Dwarrowdelf (helms)

#### artefact.txt (Artifacts)
25+ new Third Age artifacts added including:
- Lamp of the Noldor
- Palantír (cursed)
- Torch of Mordor (cursed)
- Elendilmir
- Ring of the Noldor
- Ring of Mastery (craft-only)
- Amulet of the Istari
- Black Necklace of Morgul (cursed)
- Star of the North (craft-only)
- Hadhafang
- Noldorin Knife
- Battle Axe of Erebor
- Hammer of the Longbeards (craft-only)
- Helm of Durin
- Crown of the Smith (craft-only)
- Shadow Cloak of Mordor (cursed)
- Mantle of Stars (craft-only)
- Longbow of Mirkwood
- Black Bow of Mordor (cursed)
- Bow of the Last Alliance (craft-only)
- Boots of Lothlórien
- Gauntlets of Erebor
- Gloves of Shadow (cursed)

---

## Known Issues

### Critical
- Broken Strange Jewelry not spawning correctly (sval issue)

### Minor
- UI uses key-based selection; prefer menu-based UI
- Isildur's Longsword may be weighted in artifact RNG
- Some artifact types filtered out due to invalid base items

### Not Yet Implemented
- Broken item spawn rates in dungeon (currently only via test race)
- Balance pass on broken item rarity per layer
- Forge location guarantees per smithing design doc

---

## Testing

### Istari Test Race
A test race has been added with starting equipment:
- 10 Broken Glowing Weapons
- 10 Broken Glowing Armors
- 10 Broken Strange Weapons
- 10 Broken Strange Armors
- 10 Broken Strange Jewelry
- Long Sword (equipped)
- 5 Wooden Torches

Use this race to test the smithing system without needing to find broken items.

---

## Design Philosophy

### Smithing: "Reclaiming the Past"
The Third Age is an age of decline. The great smiths are gone. Players don't create new wonders - they salvage and restore the works of the past. This is reflected in:
- Finding *broken* items rather than raw materials
- *Reforging* rather than creating from scratch
- Random results representing the uncertainty of restoration
- Progressively powerful results (Glowing → Strange → Masterwork)

### Lore Consistency
All First Age references have been replaced or justified:
- Gondolin blades (Glamdring, Orcrist) survived as relics - kept
- Doriath referenced as ancient history - kept
- Dwarven crafts (Nogrod, Belegost, Iron Hills) still active - kept
- Pure First Age locations (Nargothrond, Thangorodrim, Udun) - replaced

### Cursed Items
Nine cursed artifacts represent Sauron's corrupted hoard:
- Black Blade of Morgul
- Morgul-knife
- Black Bow of Mordor
- Shadow Cloak of Mordor
- Orc-helm of Dol Guldur
- Lesser Ring of Power
- Black Necklace of Morgul
- Palantír
- Torch of Mordor

---

## THE LIST - Future Work

### High Priority
- [ ] Fix Broken Strange Jewelry bug
- [ ] Implement broken item spawns in dungeon
- [ ] Balance pass on smithing economy
- [ ] Tower Alert System implementation

### Medium Priority
- [ ] Change Voice to Spirit (or better name)
- [ ] Rework vaults/mobs for stealth assassination gameplay
- [ ] Vault terrain overhaul - poison streams, hazards, variety
- [ ] Stealth ability tree expansion

### Exploratory
- [ ] Merge Melee + Archery into one "Combat" tree with weapon proficiency abilities

---

## File Changes Summary

### Modified
- lib/edit/ability.txt - Smithing tree restructure
- lib/edit/artefact.txt - 25+ new Third Age artifacts
- lib/edit/object.txt - 5 broken item types
- lib/edit/race.txt - Istari test race
- lib/edit/special.txt - Third Age ego items
- src/cmd4.c - Reforge/Reclaim/Masterwork implementation
- src/defines.h - SMT_REFORGE, SMT_RECLAIM, SMT_MASTERWORK constants

### Technical Details (cmd4.c)
New functions:
- `count_broken_item(int k_idx)`
- `consume_broken_items(int k_idx, int count)`
- `pick_random_sval(int tval)`
- `pick_random_ego(int tval, int sval)`
- `pick_random_artifact(int* tval_list, bool best)`
- `reforge_menu()`
- `reclaim_menu()`
- `masterwork_menu()`

---

## Credits

Design & Development: Christopher Kocurek  
AI Assistance: Claude (Anthropic)  
Base Game: SIL-Q by sil-quirk  
Original Sil: half.net

---

*"In place of a Dark Lord you would have a Queen! Not dark but beautiful and terrible as the Dawn!"*
