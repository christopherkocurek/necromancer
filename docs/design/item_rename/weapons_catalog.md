# Weapons Catalog - The Necromancer
## AUDIT-001: Complete Weapons Extraction from object.txt

---

## TV_SWORD (23) - Edged Weapons

| ID | Name | Depth | Weight | To-Hit | Damage | Evasion | Description |
|----|------|-------|--------|--------|--------|---------|-------------|
| 56 | Dagger | 1 | 5 | 0 | 1d5 | 0 | (none) |
| 57 | Curved Sword | 2 | 40 | -1 | 2d5 | 1 | A crude blade, but better than none. It is curved in the orcish style. |
| 60 | Shortsword | 1 | 20 | 0 | 1d7 | 1 | (none) |
| 64 | Longsword | 4 | 30 | 0 | 2d5 | 1 | (none) |
| 67 | Bastard Sword | 6 | 40 | -2 | 3d3 | 1 | (none) - HAND_AND_A_HALF |
| 68 | Greatsword | 4 | 60 | -2 | 3d5 | 1 | (none) - TWO_HANDED |
| 69 | Mithril Longsword | 5 | 20 | 1 | 2d5 | 1 | (none) - MITHRIL |
| 70 | Mithril Greatsword | 6 | 40 | -2 | 3d6 | 1 | (none) - TWO_HANDED, MITHRIL |

**Count: 8 swords**

---

## TV_POLEARM (22) - Axes and Polearms

| ID | Name | Depth | Weight | To-Hit | Damage | Evasion | Description |
|----|------|-------|--------|--------|--------|---------|-------------|
| 71 | Spear | 1 | 30 | 0 | 1d9 | 0 | (none) - THROWING, HAND_AND_A_HALF, POLEARM |
| 72 | Great Spear | 4 | 60 | 1 | 1d13 | 1 | (none) - TWO_HANDED, POLEARM |
| 74 | Glaive | 8 | 70 | -1 | 2d9 | 1 | (none) - TWO_HANDED, POLEARM |
| 76 | Hand Axe | 2 | 10 | -1 | 4d2 | 0 | (none) - AXE |
| 77 | Battle Axe | 4 | 45 | -3 | 3d4 | 0 | (none) - HAND_AND_A_HALF, AXE |
| 81 | Great Axe | 8 | 80 | -4 | 4d4 | 0 | (none) - TWO_HANDED, AXE |

**Count: 6 polearms/axes**

---

## TV_HAFTED (21) - Blunt Weapons

| ID | Name | Depth | Weight | To-Hit | Damage | Evasion | Description |
|----|------|-------|--------|--------|--------|---------|-------------|
| 19 | Mighty Hammer (Grond base) | 20 | 1000 | -7 | 6d5 | 0 | Special artifact base - INSTA_ART |
| 86 | Quarterstaff | 1 | 50 | 0 | 2d5 | 2 | (none) - TWO_HANDED, ENCHANTABLE |
| 89 | War Hammer | 6 | 50 | -2 | 4d1 | 0 | (none) - HAND_AND_A_HALF |

**Count: 3 hafted (2 usable, 1 artifact-only)**

---

## TV_BOW (19) - Bows

| ID | Name | Depth | Weight | To-Hit | Damage | Evasion | Description |
|----|------|-------|--------|--------|--------|---------|-------------|
| 110 | Shortbow | 1 | 15 | 0 | 1d7 | 0 | (none) |
| 111 | Longbow | 6 | 30 | 0 | 2d4 | 0 | (none) |
| 112 | Dragon-horn Bow | 15 | 45 | 0 | 4d2 | 0 | (none) - NO_SMITHING |

**Count: 3 bows**

---

## TV_DIGGING (20) - Digging Tools

| ID | Name | Depth | Weight | To-Hit | Damage | Evasion | pval | Description |
|----|------|-------|--------|--------|--------|---------|------|-------------|
| 96 | Shovel | 5 | 50 | -3 | 2d2 | 0 | 1 | It can be equipped as a weapon and allows you to dig through rubble. |
| 98 | Mattock | 10 | 100 | -5 | 5d2 | 0 | 2 | It can be equipped as a weapon and (usually) allows you to dig through rubble or quartz. |

**Count: 2 digging tools**

---

## Summary Statistics

| Weapon Type | Count | Depth Range | Damage Range |
|-------------|-------|-------------|--------------|
| Swords (TV_SWORD) | 8 | 1-6 | 1d5 to 3d6 |
| Polearms (TV_POLEARM) | 6 | 1-8 | 1d9 to 4d4 |
| Hafted (TV_HAFTED) | 2+1 | 1-6 (20 artifact) | 2d5 to 4d1 |
| Bows (TV_BOW) | 3 | 1-15 | 1d7 to 4d2 |
| Digging (TV_DIGGING) | 2 | 5-10 | 2d2 to 5d2 |

**Total Base Weapons: 21** (excluding Grond base)

---

## Renaming Priorities

### High Priority (Generic names needing Tolkien flavor)
- Dagger
- Shortsword
- Longsword
- Bastard Sword
- Greatsword
- Spear
- Great Spear
- Glaive
- Hand Axe
- Battle Axe
- Great Axe
- Quarterstaff
- War Hammer
- Shortbow
- Longbow
- Shovel
- Mattock

### Medium Priority (Already have some flavor)
- Curved Sword (orcish style - good for Dol Guldur)
- Dragon-horn Bow (evocative already)

### Special (Keep as-is due to Tolkien canon)
- Mithril Longsword
- Mithril Greatsword
- Mighty Hammer (Grond base)

---

## Layer Mapping (Dol Guldur context)

| Depth | Layer | Expected Weapons |
|-------|-------|-----------------|
| 1-2 | Forest Breach | Daggers, Shortswords, Spears, Shortbows |
| 3-4 | Orc Warrens | Curved Swords, Longswords, Battle Axes |
| 5-6 | Torture Halls | Mithril weapons, War Hammers |
| 7-8 | Necropolis | Glaives, Great Axes |
| 10+ | Deeper layers | Mattock, Dragon-horn Bow |
