# Armor Catalog - The Necromancer
## AUDIT-002: Complete Armor Extraction from object.txt

---

## TV_SOFT_ARMOR (36) - Leather, Robes

| ID | Name | Depth | Weight | To-Hit | Evasion | Protection | Description |
|----|------|-------|--------|--------|---------|------------|-------------|
| 22 | Robe | 1 | 30 | 0 | +1 | 1d0 | (none) |
| 23 | Leather Armour | 1 | 70 | 0 | -1 | 1d4 | (none) |
| 26 | Studded Leather | 2 | 130 | 0 | -2 | 1d6 | (none) |
| 27 | Galvorn Armour | 17 | 70 | 0 | -1 | 1d8 | A suit of armour made of galvorn: a strange shining black metal so malleable that it is thin and supple, yet strong enough to stop blade and dart. |

**Count: 4 soft armor**

---

## TV_MAIL (37) - Chain Mail, Plate

| ID | Name | Depth | Weight | To-Hit | Evasion | Protection | Description |
|----|------|-------|--------|--------|---------|------------|-------------|
| 30 | Mail Corslet | 5 | 270 | -1 | -3 | 2d4 | A shirt of armour formed from linked rings. It comes down to the waist. |
| 31 | Hauberk | 7 | 350 | -2 | -4 | 2d5 | A long-sleeved shirt of armour formed from linked rings. It comes down to the thigh. |
| 38 | Mithril Corslet | 7 | 150 | 0 | -2 | 2d4 | A shirt of armour formed from linked rings. |

**Count: 3 standard mail**

---

## Special/Crafting Items (TV_MAIL)

| ID | Name | Depth | Weight | To-Hit | Evasion | Protection | Description |
|----|------|-------|--------|--------|---------|------------|-------------|
| 492 | Broken Glowing Armor | 4 | 50 | 0 | 0 | 0d0 | Shattered pieces of armor that still shimmer faintly. A skilled smith with the Reforge ability could work the remaining magic into new protective gear. |
| 494 | Broken Strange Armor | 10 | 80 | 0 | 0 | 0d0 | Twisted pieces of armor that seem to absorb light. The metal feels ancient and powerful. Only a master smith could unlock its potential. |

**Count: 2 crafting materials**

---

## Summary Statistics

| Armor Type | Count | Depth Range | Protection Range | Weight Range |
|------------|-------|-------------|-----------------|--------------|
| Soft Armor (TV_SOFT_ARMOR) | 4 | 1-17 | 1d0 to 1d8 | 30-130 |
| Mail (TV_MAIL) | 3 | 5-7 | 2d4 to 2d5 | 150-350 |
| Crafting Materials | 2 | 4-10 | 0d0 | 50-80 |

**Total Armor Pieces: 7** (+ 2 crafting materials)

---

## Armor Progression

### Early Game (Depth 1-4)
- Robe: +1 Evasion, 1d0 Protection (mage/stealth)
- Leather Armour: -1 Evasion, 1d4 Protection (light fighter)
- Studded Leather: -2 Evasion, 1d6 Protection (balanced)

### Mid Game (Depth 5-7)
- Mail Corslet: -3 Evasion, 2d4 Protection (heavy)
- Hauberk: -4 Evasion, 2d5 Protection (very heavy)
- Mithril Corslet: -2 Evasion, 2d4 Protection (premium)

### Late Game (Depth 17)
- Galvorn Armour: -1 Evasion, 1d8 Protection (rare, special)

---

## Renaming Priorities

### High Priority (Generic names)
- Robe
- Leather Armour
- Studded Leather
- Mail Corslet
- Hauberk

### Already Tolkien-Appropriate (Keep or minor adjustment)
- Galvorn Armour (canonical Tolkien material - First Age though!)
- Mithril Corslet (canonical - could add regional flavor)

### Crafting Items (Keep generic or add Dol Guldur flavor)
- Broken Glowing Armor
- Broken Strange Armor

---

## Layer Mapping (Dol Guldur context)

| Depth | Layer | Expected Armor |
|-------|-------|---------------|
| 1-2 | Forest Breach | Robes, Leather |
| 3-4 | Orc Warrens | Studded Leather |
| 5-6 | Torture Halls | Mail Corslet |
| 7-8 | Necropolis | Hauberk, Mithril Corslet |
| 17+ | Inner Sanctum | Galvorn Armour |

---

## Notes on Galvorn

Galvorn is technically First Age material (invented by Eol the Dark Elf). However, Eol's work could have survived and been recovered - or the name could be changed to avoid First Age references per design principles.

**Options:**
1. Keep "Galvorn Armour" - players familiar with Tolkien will appreciate it
2. Rename to "Black Elven Mail" - vaguer but still evocative
3. Rename to "Shadow-steel Armour" - more Dol Guldur appropriate
