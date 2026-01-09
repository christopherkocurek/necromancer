# Weapons Rename Proposals - The Necromancer
## PROPOSE-001: Tolkien-Grounded Weapon Names

---

## Naming Philosophy

- **Silvan/Ranger style**: Nature-inspired, practical (Forest Breach layer)
- **Orcish/Dol Guldur style**: Crude, dark, menacing (Orc Warrens layer)
- **Gondorian/Númenórean style**: Noble, ancient (Deep layers, precious items)
- **Dwarven style**: Craft-focused, material names (Erebor heritage)

---

## TV_SWORD (23) - Edged Weapons

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 56 | Dagger | **Ranger's Knife** | Silvan/Ranger style, early layer item. "Knife" is Tolkien-appropriate (Bilbo's "Sting" was called a knife). | 18 |
| 57 | Curved Sword | **Orc-blade** | Already has orcish flavor; simplified name evokes Dol Guldur origin. Tolkien used "orc-" prefix. | 4 |
| 60 | Shortsword | **Arnor Blade** | References lost northern kingdom; appropriate for Rangers. Short swords common among Dúnedain scouts. | 9 |
| 64 | Longsword | **Gondor Sword** | Classic Gondorian military weapon. Direct and functional. | 11 |
| 67 | Bastard Sword | **War-blade** | "Bastard" is modern terminology. "War-blade" conveys hand-and-a-half usage, Tolkien-neutral. | 12 |
| 68 | Greatsword | **Númenórean Blade** | Large swords associated with Númenórean heritage. Noble, deep-layer appropriate. | 9 |
| 69 | Mithril Longsword | **Mithril Sword** | Keep mithril reference; simplify. Already Tolkien-appropriate. | LOW |
| 70 | Mithril Greatsword | **Mithril Great-blade** | Keep mithril; "great-blade" more evocative than "greatsword". | LOW |

### Alternative Considerations
- Dagger could be "Forest Knife" or "Woodsman's Knife"
- Shortsword could be "Dale Blade" (Bard's people) or "Scout's Sword"
- Longsword could be "Tower Sword" (Tower Guard reference)

---

## TV_POLEARM (22) - Axes and Polearms

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 71 | Spear | **Hunting Spear** | Silvan hunters used spears; functional and thematic. | 11 |
| 72 | Great Spear | **Tower Guard Spear** | Large spears used by Gondorian Tower Guard. Noble, deep-layer appropriate. | 3 |
| 74 | Glaive | **Morgul Glaive** | Deep layer weapon; "Morgul" evokes shadow corruption without being First Age. | 6 |
| 76 | Hand Axe | **Woodsman's Axe** | Early layer tool-weapon. Practical, Silvan-adjacent. | 2 |
| 77 | Battle Axe | **Dwarven War-axe** | Dwarves renowned for axes; Erebor heritage. | 5 |
| 81 | Great Axe | **Erebor Great-axe** | Dwarven masterwork; references Lonely Mountain. Third Age appropriate. | 4 |

### Alternative Considerations
- Spear could be "Silvan Spear" or "Ranger's Spear"
- Great Spear could be "Gondor Pike" or "Citadel Spear"
- Glaive could be "Shadow Glaive" or "Dol Guldur Glaive"
- Battle Axe could be "Dale Axe" (trade with Erebor)

---

## TV_HAFTED (21) - Blunt Weapons

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 19 | Mighty Hammer (Grond base) | **Mighty Hammer** | KEEP - Artifact base for Grond. Canonical. | N/A |
| 86 | Quarterstaff | **Oak Staff** | Material-based name; wood staves common in Middle-earth. Natural, Silvan-adjacent. | 3 |
| 89 | War Hammer | **Dwarven Hammer** | Dwarves master smiths and hammer-wielders. "Dring" is Sindarin for hammer. | 11 |

### Alternative Considerations
- Quarterstaff could be "Traveler's Staff" or "Walking Staff"
- War Hammer could be "Erebor Hammer" or "Iron Hammer"

---

## TV_BOW (19) - Bows

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 110 | Shortbow | **Silvan Bow** | Wood-elves renowned archers; short bows for forest hunting. | 12 |
| 111 | Longbow | **Gondor Longbow** | Gondorian archers used longbows; Faramir's rangers. | 18 |
| 112 | Dragon-horn Bow | **Dragon-horn Bow** | KEEP - Already evocative and unique. References Third Age dragons. | 3 |

### Alternative Considerations
- Shortbow could be "Ranger's Bow" or "Forest Bow"
- Longbow could be "Ithilien Bow" (Faramir's rangers) or "Númenórean Bow"

---

## TV_DIGGING (20) - Digging Tools

| ID | OLD NAME | NEW NAME | Rationale | Refs |
|----|----------|----------|-----------|------|
| 96 | Shovel | **Miner's Spade** | Dwarven mining association; "spade" more Tolkien-era. | 1 |
| 98 | Mattock | **Dwarf Mattock** | Mattocks canonical Dwarven tools (Gimli). Direct association. | 5 |

### Alternative Considerations
- Shovel could be "Delver's Tool" or stay "Shovel" (functional)
- Mattock could be "Erebor Mattock" or "Moria Pick"

---

## Summary Table

| Type | Changed | Kept | Total |
|------|---------|------|-------|
| Swords | 6 | 2 | 8 |
| Polearms | 6 | 0 | 6 |
| Hafted | 2 | 1 | 3 |
| Bows | 2 | 1 | 3 |
| Digging | 2 | 0 | 2 |
| **Total** | **18** | **4** | **22** |

---

## High-Risk Changes (Code References)

| Item | Old Name | New Name | Risk | Notes |
|------|----------|----------|------|-------|
| 68 | Greatsword | Númenórean Blade | MEDIUM | xtra2.c hardcoded for Glend artifact |
| 71 | Spear | Hunting Spear | MEDIUM | xtra2.c hardcoded for Boldog artifact |

These require code changes in addition to data files.

---

## Naming Style Guide (For Consistency)

1. **Compound names**: Use hyphen for clarity ("War-axe" not "Waraxe")
2. **Possessive forms**: Avoid unless specific NPC ("Ranger's" is okay, "Thráin's" needs context)
3. **Material prefix**: "Mithril", "Iron", "Oak" before item type
4. **Regional prefix**: "Gondor", "Erebor", "Silvan" before item type
5. **Descriptor prefix**: "Hunting", "War", "Great" before item type
