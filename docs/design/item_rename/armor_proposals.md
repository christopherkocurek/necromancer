# Armor Rename Proposals - The Necromancer
## PROPOSE-002: Tolkien-Grounded Armor Names

---

## Naming Philosophy

- **Leather/Light**: Ranger/Woodsman style (Silvan, Ithilien)
- **Mail**: Regional military style (Gondor, Erebor, Rohan)
- **Mithril**: Keep canonical; emphasize Dwarven craft
- **Deep layer**: More ornate/ancient names

---

## TV_SOFT_ARMOR (36) - Leather, Robes

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 22 | Robe | **Wanderer's Robe** | Evokes traveling wizards/scholars. Gandalf wore robes. Functional for mage builds. | 6 |
| 23 | Leather Armour | **Ranger Leathers** | Dúnedain Rangers wore leather for stealth. Ithilien Rangers association. | 4 |
| 26 | Studded Leather | **Scout's Armor** | Scouts (like those of Gondor/Rohan) needed protection with mobility. | 3 |
| 27 | Galvorn Armour | **Shadow-steel Armor** | Galvorn is First Age (Eol). "Shadow-steel" evokes Dol Guldur corruption while keeping the supple black metal concept. | 4 |

### Alternative Considerations
- Robe could be "Scholar's Robe" or "Grey Robe" (Gandalf)
- Leather Armour could be "Woodsman's Leather" or "Hunter's Gear"
- Studded Leather could be "Reinforced Leather" or "Soldier's Leather"
- Galvorn Armour could be "Black Elven Mail" or keep "Galvorn" (players may know it)

### Note on Galvorn
Galvorn is technically First Age material invented by Eol the Dark Elf. Options:
1. **Keep "Galvorn"**: Recognizable to Tolkien fans, though violates "no First Age" principle
2. **"Shadow-steel"**: New name that captures the essence (black, supple, strong) without First Age reference
3. **"Black Elven Mail"**: Descriptive, avoids specific lore

**Recommendation**: "Shadow-steel Armor" - fits Dol Guldur theme, suggests the metal was corrupted/transformed in the Third Age.

---

## TV_MAIL (37) - Chain Mail, Plate

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 30 | Mail Corslet | **Gondor Corslet** | Gondorian soldiers wore mail corslets. Tower Guard standard issue. Direct regional association. | 5 |
| 31 | Hauberk | **Dwarven Hauberk** | Dwarves crafted the finest mail. Hauberks (long mail shirts) common in Erebor trade. | 5 |
| 38 | Mithril Corslet | **Mithril Corslet** | KEEP - Already perfect. Frodo's famous armor was a mithril corslet. Canonical. | 3 |

### Alternative Considerations
- Mail Corslet could be "Tower Guard Mail" or "Citadel Corslet"
- Hauberk could be "Erebor Hauberk" or "Iron Hauberk"
- Mithril Corslet could add "of Erebor" suffix if more specificity desired

---

## Crafting/Damaged Items (TV_MAIL)

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 492 | Broken Glowing Armor | **Shattered Elven Mail** | "Glowing" suggests Elven enchantment. Reforging theme fits smithing gameplay. | LOW |
| 494 | Broken Strange Armor | **Twisted Shadow-plate** | "Strange" + "absorbs light" = shadow corruption. Dol Guldur origin implied. | LOW |

### Alternative Considerations
- Broken Glowing Armor could be "Ruined Enchanted Mail" or "Faded Elven Armor"
- Broken Strange Armor could be "Corrupted Armor Shards" or "Dark Iron Fragments"

---

## Summary Table

| Type | Changed | Kept | Total |
|------|---------|------|-------|
| Soft Armor | 4 | 0 | 4 |
| Mail | 2 | 1 | 3 |
| Crafting | 2 | 0 | 2 |
| **Total** | **8** | **1** | **9** |

---

## Regional Style Reference

### Gondor (Men of Westernesse)
- Style: Formal, noble, ancient Númenórean heritage
- Materials: Steel, silver trim, black/silver colors
- Armor: Mail corslets, vambraces, greaves, tall helms
- Naming: "Gondor [Type]", "Tower [Type]", "Citadel [Type]"

### Rohan (Rohirrim)
- Style: Anglo-Saxon inspired, practical cavalry gear
- Materials: Iron, leather, horsehair decoration
- Armor: Lighter mail, leather, ornate helms
- Naming: "Rider's [Type]", "Rohirric [Type]"

### Erebor (Dwarves)
- Style: Heavy, masterwork, functional
- Materials: Iron, steel, mithril
- Armor: Heavy mail, full helms, masks
- Naming: "Dwarven [Type]", "Erebor [Type]", "Iron [Type]"

### Mirkwood (Silvan Elves)
- Style: Light, nature-inspired
- Materials: Leather, light metals, enchanted
- Armor: Leather, cloaks, light mail
- Naming: "Silvan [Type]", "Forest [Type]", "Woodland [Type]"

### Dol Guldur (Shadow)
- Style: Corrupted, dark, menacing
- Materials: Black iron, shadow-touched
- Armor: Orcish gear, corrupted equipment
- Naming: "Shadow [Type]", "Dark [Type]", "Morgul [Type]"

---

## Armor Progression (Layer-Appropriate)

| Depth | Layer | Armor Types | Style |
|-------|-------|-------------|-------|
| 1-2 | Forest Breach | Wanderer's Robe, Ranger Leathers | Silvan/Ranger |
| 3-4 | Orc Warrens | Scout's Armor | Military scout |
| 5-6 | Torture Halls | Gondor Corslet | Gondorian |
| 7-8 | Necropolis | Dwarven Hauberk, Mithril Corslet | Dwarven/Precious |
| 17 | Inner Sanctum | Shadow-steel Armor | Ancient/Corrupted |

---

## High-Risk Changes (Code References)

| Item | Old Name | New Name | Risk | Notes |
|------|----------|----------|------|-------|
| 27 | Galvorn Armour | Shadow-steel Armor | MEDIUM | xtra2.c hardcoded for Maeglin artifact |

The Galvorn Armour of Maeglin has a hardcoded reference in xtra2.c that will need updating.
