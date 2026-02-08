# Item Tile Cleanup Catalogue

**Generated**: 2026-02-07
**Scope**: 195 unique item tiles (rows 11-17)
**Method**: 1 analyst + 6 parallel review agents using 7-category visual framework

---

## Executive Summary

| Row | Category | Total | PASS | FAIL | Rate |
|-----|----------|-------|------|------|------|
| 11+17 | Weapons, armor, jewelry | 34 | 14 | 20 | 59% fail |
| 12 | Spears, axes, helms, cloaks, bows | 32 | 5 | 27 | 84% fail |
| 13 | Amulets, rings, light sources | 32 | 1 | 31 | 97% fail |
| 14 | Scrolls, wands, horns, potions | 32 | 1 | 31 | 97% fail |
| 15 | Potions, chests, food, herbs | 32 | 0 | 32 | 100% fail |
| 16 | Misc, lore, quest items | 32 | 20 | 12 | 38% fail |
| **TOTAL** | | **195** | **41** | **153** | **78.5% fail** |

### Root Cause Analysis

The `fix_item_magenta.py` pipeline was tuned for **magenta/pink** background removal. DALL-E produced **4 distinct background color families** that this pipeline cannot handle:

1. **Gold/amber** (rows 11-13): Jewelry, weapons, armor — the dominant failure mode
2. **Blue/navy** (rows 14-15): Potions — completely untouched by magenta pipeline
3. **Green** (rows 15-16): Herbs, food — green subjects on green backgrounds
4. **White/cream** (scattered): Some scrolls and amulets

---

## Fix Categories

### REGENERATE (24 tiles)
These need new DALL-E generations — either the subject merged with background, processing destroyed the subject, or the image is unsalvageable.

| Item ID | Name | Row:Col | Issue |
|---------|------|---------|-------|
| item_2 | Ring | 11:2 | Full gold bg >80% + sparkles |
| item_3 | Amulet | 11:3 | Full gold bg >80% + sparkles |
| item_4 | Pearl | 11:4 | Full gold bg + halo + sparkles |
| item_5 | Jewel | 11:5 | Full gold bg >80% |
| item_6 | Necklace | 11:6 | Gold bg + bottom barrier |
| item_21 | Elven Light | 11:9 | Amber bg + intense glow merged |
| item_40 | Orc Skeleton | 11:17 | Full amber bg >75% |
| item_42 | Elf Skeleton | 11:19 | Full gold bg >85% + subject faded |
| item_59 | Sylvan Blade | 17:2 | PROCESSING_FAILURE: subject stripped |
| item_71 | Hunting Spear | 11:31 | Horizontal amber bands ~75% |
| item_133 | Constitution | 13:4 | Gold bg + sapphire gem destroyed |
| item_135 | Regeneration | 13:6 | PROCESSING_FAILURE: vertical half-split |
| item_137 | Blessed Realm | 13:8 | Full gold bg + messy edges |
| item_139 | Vigilant Eye | 13:10 | Full brown bg + frames |
| item_152 | Evasion ring | 13:13 | Gold ring on gold bg — inseparable |
| item_153 | Protection ring | 13:14 | Gold ring on gold bg — inseparable |
| item_154 | Strength ring | 13:15 | Gold ring on gold bg — inseparable |
| item_157 | Warmth ring | 13:18 | Full white/cream bg + intense glow |
| item_193 | Light scroll | 13:27 | Full gold bg + starburst merged |
| item_196 | Understanding | 13:29 | Full orange bg >85% |
| item_385 | Emptiness herb | 15:22 | Circular dark vignette frame baked in |
| item_415 | Potent Orc-rage Mushroom | 16:7 | Green subject on green bg — inseparable |
| item_416 | Phosphorescent Moss | 16:8 | Green subject on green bg — inseparable |
| item_556 | Necromancer Sighting | 17:0 | Full orange bg >80% |

**Regeneration prompts should specify**: "isolated object floating in a solid black void, no background, no frame, no surface"

### BG_REMOVAL (113 tiles)
These have recoverable subjects but retained colored backgrounds. Need a new multi-color-aware bg removal pipeline.

#### Gold/Amber Backgrounds (~65 tiles)

| Item ID | Name | Row:Col | Coverage |
|---------|------|---------|----------|
| item_1 | Serpentine Ring | 11:1 | ~45% |
| item_19 | Mighty Hammer | 11:7 | ~18% |
| item_20 | Massive Iron Crown | 11:8 | ~55% |
| item_22 | Wanderer's Robe | 11:10 | ~45% |
| item_23 | Ranger Leathers | 11:11 | ~40% |
| item_26 | Scout's Armor | 11:12 | ~35% |
| item_27 | Shadow-steel Armor | 11:13 | ~45% |
| item_41 | Human Skeleton | 11:18 | ~55% |
| item_72 | Tower Guard Spear | 12:0 | ~40% |
| item_74 | Morgul Glaive | 12:1 | ~85% |
| item_76 | Woodsman's Axe | 12:2 | ~80% |
| item_77 | Dwarven War-axe | 12:3 | ~50% |
| item_81 | Erebor Great-axe | 12:4 | ~38% |
| item_86 | Oak Staff | 12:5 | ~80% |
| item_89 | Dwarven Hammer | 12:6 | ~40% |
| item_101 | Tower Helm | 12:10 | ~20% |
| item_102 | Dwarf Mask | 12:11 | ~18% |
| item_104 | Crown | 12:13 | ~23% |
| item_110 | Silvan Bow | 12:18 | ~80% |
| item_111 | Longbow | 12:19 | ~85% |
| item_112 | Dragon-horn Bow | 12:20 | ~45% |
| item_116 | Arrow | 12:21 | ~50% |
| item_118 | Sling | 12:22 | ~45% |
| item_119 | Fine Leather Sling | 12:23 | ~50% |
| item_122 | Traveler's Boots | 12:25 | ~38% |
| item_123 | Iron Greaves | 12:26 | ~75% |
| item_124 | Mithril Greaves | 12:27 | ~18% |
| item_125 | Leather Gloves | 12:28 | ~78% |
| item_127 | Mithril Gauntlets | 12:30 | ~35% |
| item_128 | Wooden Torch | 12:31 | ~33% |
| item_129 | Brass Lantern | 13:0 | ~60% |
| item_130 | Jewel-lamp | 13:1 | ~50% |
| item_131 | Star-glass | 13:2 | ~20% |
| item_132 | Last Chances | 13:3 | ~40% + outlines |
| item_134 | Grace | 13:5 | ~80% |
| item_136 | Preservation | 13:7 | ~80% |
| item_150 | Secrets | 13:11 | ~40% + particles |
| item_151 | Ered Luin | 13:12 | ~50% |
| item_155 | Dexterity | 13:16 | ~45% |
| item_156 | Frost | 13:17 | ~35% |
| item_158 | Accuracy | 13:19 | ~50% |
| item_159 | Free Action | 13:20 | ~45% |
| item_160 | Cowardice | 13:21 | ~50% |
| item_162 | Venom's End | 13:23 | ~50% |
| item_171 | the Laiquendi | 13:24 | ~40% |
| item_191 | Imprisonment | 13:25 | ~55% |
| item_192 | Freedom | 13:26 | ~50% |
| item_195 | Sanctity | 13:28 | ~50% |
| item_197 | Revelations | 13:30 | ~50% + particles |
| item_198 | Treasures | 13:31 | ~45% |
| item_199 | Foes scroll | 14:0 | ~80% |
| item_200 | Slumber scroll | 14:1 | ~40% |
| item_201 | Majesty scroll | 14:2 | ~50% |
| item_202 | Self Knowledge | 14:3 | ~35% |
| item_203 | Warding scroll | 14:4 | ~40% |
| item_206 | Recharging | 14:6 | ~40% |
| item_210 | Summoning | 14:7 | ~45% |
| item_211 | Shadows scroll | 14:8 | ~40% |
| item_220 | Wand of Frost | 14:9 | ~38% |
| item_221 | Wand of Fire | 14:10 | ~50% |
| item_223 | Wand of Light | 14:12 | ~18% |
| item_224 | Wand of Fear | 14:13 | ~40% |
| item_225 | Wand of Sleep | 14:14 | ~35% |
| item_240 | Horn of Terror | 14:15 | ~78% |
| item_241 | Horn of Thunder | 14:16 | ~33% |
| item_242 | Horn of Force | 14:17 | ~45% |
| item_243 | Horn of Blasting | 14:18 | ~75% |
| item_251 | Flute of Fairy | 14:20 | ~40% |
| item_530 | Palantir Shard | 16:23 | ~35% |
| item_554 | Historical Fragment | 16:31 | ~30% + border |
| item_402 | Flask of oil | 15:31 | ~40% |

#### Blue/Navy Backgrounds (~23 tiles)

| Item ID | Name | Row:Col | Coverage |
|---------|------|---------|----------|
| item_313 | Miruvor | 14:21 | ~23% |
| item_315 | Orcish Liquor | 14:22 | ~80% |
| item_316 | Esgalduin | 14:23 | ~43% |
| item_317 | Clarity | 14:24 | ~38% |
| item_318 | Cordial of Wise | 14:25 | ~40% |
| item_320 | True Sight | 14:27 | ~40% |
| item_321 | Antidote | 14:28 | ~40% |
| item_322 | Quickness | 14:29 | ~50% |
| item_323 | Elemental Resist | 14:30 | ~78% |
| item_324 | Shadows potion | 14:31 | ~50% |
| item_327 | Draught of Might | 15:0 | ~50% |
| item_328 | Nimble-wine | 15:1 | ~60% |
| item_329 | Hardy-brew | 15:2 | ~55% |
| item_330 | Starlight Elixir | 15:3 | ~80% |
| item_343 | Slowness | 15:4 | ~50% |
| item_344 | Poison | 15:5 | ~45% |
| item_345 | Blindness | 15:6 | ~85% |
| item_346 | Confusion | 15:7 | ~50% |
| item_348 | Awkwardness | 15:8 | ~75% |
| item_350 | Disconnection | 15:9 | ~55% |

#### Green Backgrounds (~18 tiles)

| Item ID | Name | Row:Col | Coverage |
|---------|------|---------|----------|
| item_107 | Shadow Cloak | 12:15 | ~38% |
| item_108 | Wolf-Hame | 12:16 | ~45% |
| item_380 | Orc-rage Mushroom | 15:17 | ~80% |
| item_381 | Waymeal | 15:18 | ~50% |
| item_382 | Terror herb | 15:19 | ~80% |
| item_383 | Healer's Herb | 15:20 | ~50% |
| item_384 | Restoration | 15:21 | ~38% |
| item_386 | Visions herb | 15:23 | ~45% |
| item_387 | Entrancement | 15:24 | ~45% |
| item_388 | Weakness herb | 15:25 | ~50% |
| item_389 | Sickness herb | 15:26 | ~55% |
| item_390 | Athelas | 15:27 | ~50% |
| item_399 | Travel Bread | 15:28 | ~45% |
| item_400 | Dried Meat | 15:29 | ~50% |
| item_401 | Lembas | 15:30 | ~40% |
| item_403 | Cake of Cram | 16:0 | ~90% |
| item_404 | Pipe-weed | 16:1 | ~85% |
| item_412 | Conc. Healer's | 16:4 | ~80% |
| item_413 | Potent Athelas | 16:5 | ~75% |
| item_414 | Conc. Waymeal | 16:6 | ~85% |
| item_418 | Nightshade Cloak | 16:10 | ~40% |

### EDGE_CLEANUP (6 tiles)
Minor halo/glow or border issues, item subject is fine.

| Item ID | Name | Row:Col | Issue |
|---------|------|---------|-------|
| item_38 | Mithril Corslet | 11:16 | Grey halo ~3-4px |
| item_46 | Mithril Shield | 11:22 | White/blue halo ~3px |
| item_68 | Numenorean Blade | 11:28 | White glow along blade |
| item_109 | Bat-Fell | 12:17 | Green fringe ~2-3px |
| item_126 | Iron Gauntlets | 12:29 | Warm fringe ~1-2px |
| item_543 | Dwarven Chronicle Page | 16:27 | Dark border on all 4 sides |

### MULTI_PASS (5 tiles)
Need combined bg_removal + particle_cleanup or other multiple treatments.

| Item ID | Name | Row:Col | Issue |
|---------|------|---------|-------|
| item_106 | Traveler's Cloak | 12:14 | Green particles + subject holes + white bg patches |
| item_138 | Haunted Dreams | 13:9 | White bg (inverted) + dark particle specks |
| item_204 | Dismay scroll | 14:5 | White bg + heavy white particles + strong halo |
| item_250 | Horn of Challenge | 14:19 | Orange bg ~75% + heavy particles (~12) |
| item_319 | Voice potion | 14:26 | Blue bg ~48% + heavy white sparkle particles (~15) |

### PASS (41 tiles)
Clean tiles requiring no action.

Row 11: item_0, item_30, item_31, item_43, item_44, item_56, item_57, item_58, item_60, item_64, item_67, item_69, item_70
Row 12: item_96, item_98, item_100, item_103, item_120
Row 13: item_161
Row 14: item_222
Row 16: item_410, item_411, item_417, item_420, item_421, item_422, item_451, item_491, item_492, item_494, item_495, item_500, item_510, item_520, item_540, item_541, item_542, item_544, item_550, item_552

---

## Pipeline Recommendations

### 1. New Multi-Color BG Removal Script
Replace single-hue `fix_item_magenta.py` with a multi-pass approach:
- **Pass 1**: Gold/amber removal (HSV hue 20-50, sat >30%)
- **Pass 2**: Blue/navy removal (HSV hue 180-250, sat >20%)
- **Pass 3**: Green removal (HSV hue 80-160, sat >30%) — CAREFUL: skip for green subjects
- **Pass 4**: White/cream removal (sat <15%, val >80%)
- **Pass 5**: Small-island particle cleanup (connected components <50px)
- **Pass 6**: Alpha erosion for halo cleanup (erode 1-2px on semi-transparent edges)

### 2. Regeneration Batch
24 tiles need DALL-E regeneration ($0.96 at $0.04/tile). Use prompt template:
> "A [ITEM_NAME], dark fantasy illustration style painting, isolated object floating in solid black void, no background, no frame, no surface, centered composition"

### 3. Priority Order
1. **P0**: 24 regenerations (broken/inseparable)
2. **P1**: 113 bg_removal re-runs (pipeline fix)
3. **P2**: 6 edge_cleanup (minor polish)
4. **P3**: 5 multi_pass (complex cleanup)

### 4. Green Subject Risk
Items like herbs, mushrooms, and moss are inherently green. For these, regeneration with a **blue or black** background is safer than attempting green bg removal on green subjects.

---

## Issue Category Frequency

| Category | Total Occurrences |
|----------|------------------|
| BACKGROUND_RETAINED | 148 (96.7% of failures) |
| HALO_GLOW | ~95 |
| FLOATING_PARTICLES | ~40 |
| BORDER_FRAME | ~10 |
| SUBJECT_DAMAGE | ~8 |
| ITEM_OUTLINE | ~2 |
| PROCESSING_FAILURE | ~3 |
