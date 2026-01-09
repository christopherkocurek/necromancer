# Equipment Catalog - The Necromancer
## AUDIT-003: Complete Equipment Extraction from object.txt

---

## TV_BOOTS (30) - Boots

| ID | Name | Depth | Weight | Evasion | Protection | Notes |
|----|------|-------|--------|---------|------------|-------|
| 122 | Pair of Boots | 1 | 20 | 0 | 1d1 | Standard |
| 123 | Pair of Greaves | 4 | 80 | -1 | 1d2 | Heavy |
| 124 | Pair of Mithril Greaves | 6 | 40 | 0 | 1d2 | Premium |
| 421 | Pair of Shabby Boots | 1 | 20 | -1 | 1d1 | DAMAGED |

**Count: 4 boots**

---

## TV_GLOVES (31) - Gloves

| ID | Name | Depth | Weight | To-Hit | Protection | Notes |
|----|------|-------|--------|--------|------------|-------|
| 125 | Set of Gloves | 1 | 5 | 0 | 1d0 | Standard |
| 126 | Set of Gauntlets | 3 | 30 | -1 | 1d1 | Heavy |
| 127 | Set of Mithril Gauntlets | 5 | 15 | 0 | 1d1 | Premium |

**Count: 3 gloves**

---

## TV_HELM (32) - Helms

| ID | Name | Depth | Weight | Evasion | Protection | Description |
|----|------|-------|--------|---------|------------|-------------|
| 100 | Helm | 3 | 50 | -1 | 1d2 | (none) |
| 101 | Great Helm | 5 | 80 | -2 | 1d3 | (none) |
| 102 | Dwarf Mask | 10 | 80 | -2 | 1d2 | A full faced helm, wrought in a fearsome visage. |
| 103 | Mithril Helm | 7 | 35 | -1 | 1d3 | (none) |
| 420 | Rusty Helm | 1 | 50 | -1 | 1d1 | DAMAGED |

**Count: 5 helms**

---

## TV_CROWN (33) - Crowns

| ID | Name | Depth | Weight | Protection | Notes |
|----|------|-------|--------|------------|-------|
| 20 | Massive Iron Crown | 20 | 4000 | 0d0 | INSTA_ART (Morgoth's) |
| 104 | Crown | 7 | 30 | 1d0 | INSTA_ART |

**Count: 2 crowns (both artifact-only)**

---

## TV_SHIELD (34) - Shields

| ID | Name | Depth | Weight | To-Hit | Protection | Notes |
|----|------|-------|--------|--------|------------|-------|
| 43 | Round Shield | 3 | 50 | 0 | 1d3 | Standard |
| 44 | Kite Shield | 6 | 80 | -2 | 1d6 | Heavy |
| 46 | Mithril Shield | 8 | 40 | -1 | 1d6 | Premium |
| 422 | Broken Shield | 1 | 50 | -1 | 1d2 | DAMAGED |

**Count: 4 shields**

---

## TV_CLOAK (35) - Cloaks

| ID | Name | Depth | Weight | Evasion | Protection | Description |
|----|------|-------|--------|---------|------------|-------------|
| 106 | Cloak | 2 | 20 | +1 | 1d0 | (none) |
| 107 | Shadow Cloak | 12 | 10 | +3 | 1d0 | Has DARKNESS, STEALTH flags |
| 108 | Wolf-Hame | 20 | 130 | -3 | 1d6 | INSTA_ART |
| 109 | Bat-Fell | 23 | 50 | +2 | 0d0 | INSTA_ART |

**Count: 4 cloaks (2 artifact-only)**

---

## TV_LIGHT (39) - Light Sources

| ID | Name | Depth | Weight | Radius | Duration | Description |
|----|------|-------|--------|--------|----------|-------------|
| 128 | Wooden Torch | 1 | 20 | 1 | 3000 turns max | Refuelable |
| 129 | Brass Lantern | 5 | 30 | 2 | 7000 turns max | Refuelable |
| 411 | Mallorn Torch | 1 | 10 | 3 | 100 turns max | Burns bright but brief |
| 21 | Lesser Jewel | 3 | 1 | 1 | Forever | Elven enchanted |
| 130 | Feanorian Lamp | 12 | 10 | 4 | Forever | Enchanted lamp |
| 131 | Star-glass | 25 | 1 | 7 | Forever | Light of Earendil |

**Count: 6 light sources**

---

## TV_ARROW (17) - Ammunition

| ID | Name | Depth | Weight | Notes |
|----|------|-------|--------|-------|
| 116 | Arrow | 1 | 1 | Basic ammunition |

**Count: 1 arrow type**

---

## Summary Statistics

| Equipment Type | Count | Depth Range |
|----------------|-------|-------------|
| Boots | 4 | 1-6 |
| Gloves | 3 | 1-5 |
| Helms | 5 | 1-10 |
| Crowns | 2 | 7-20 (artifact-only) |
| Shields | 4 | 1-8 |
| Cloaks | 4 | 2-23 (2 artifact-only) |
| Lights | 6 | 1-25 |
| Arrows | 1 | 1 |

**Total Equipment: 29**

---

## Renaming Priorities

### High Priority (Generic names)
- Pair of Boots
- Pair of Greaves
- Set of Gloves
- Set of Gauntlets
- Helm
- Great Helm
- Round Shield
- Kite Shield
- Cloak
- Wooden Torch
- Brass Lantern
- Arrow

### Medium Priority (Some flavor but could be improved)
- Dwarf Mask (Tolkien-appropriate but generic)
- Shadow Cloak (good for Dol Guldur)
- Mallorn Torch (canonical Tolkien)

### Already Tolkien-Appropriate (Keep)
- Mithril Greaves
- Mithril Gauntlets
- Mithril Helm
- Mithril Shield
- Lesser Jewel
- Feanorian Lamp (First Age reference - consider renaming)
- Star-glass (Phial of Galadriel reference)

### Artifact Bases (Keep)
- Massive Iron Crown (Morgoth)
- Crown
- Wolf-Hame
- Bat-Fell

### Damaged Items (Keep generic or add flavor)
- Pair of Shabby Boots
- Rusty Helm
- Broken Shield

---

## First Age References to Address

Per design principle "no_first_age", these items reference Silmarillion-era:

1. **Feanorian Lamp** - References Feanor (First Age). Could rename to:
   - "Elven Lamp"
   - "Jewel-lamp"
   - "Lamp of the Eldar"

---

## Layer Mapping (Dol Guldur context)

| Depth | Layer | Expected Equipment |
|-------|-------|-------------------|
| 1-2 | Forest Breach | Basic boots/gloves/cloak, torches |
| 3-4 | Orc Warrens | Helms, Round Shields, Gauntlets |
| 5-6 | Torture Halls | Great Helms, Kite Shields, Lanterns |
| 7-8 | Necropolis | Mithril items |
| 10+ | Deeper | Dwarf Mask, Shadow Cloak |
| 12+ | Inner Sanctum | Feanorian Lamp |
| 25 | Pits | Star-glass |
