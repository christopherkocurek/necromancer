# The Necromancer - Sprite Requirements Mapping

Generated for tileset PRD AUDIT-004.

## Overview

This document provides the complete mapping from game symbols/IDs to required sprites for the 32x32 pixel tileset.

**Total Sprites Required: 82** (per PRD target)

---

## 1. Player Sprites (4 sprites)

| ID | Race | Symbol | Color | Priority |
|----|------|--------|-------|----------|
| R:0 | Player (Elf) | @ | white | HIGH |
| R:1 | Player (Man) | @ | white | HIGH |
| R:2 | Player (Dwarf) | @ | white | HIGH |
| R:3 | Player (alternate) | @ | white | MEDIUM |

**Notes**: Each race should have distinct silhouette. Consider directional sprites (4 directions) for future animation.

---

## 2. Monster Sprites (45 sprites)

### Layer 1: Forest Breach (8 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:11 | Mirkwood Spider | M | brown | HIGH |
| R:12 | Giant Rat | r | brown | HIGH |
| R:13 | Black Squirrel | r | dark | MEDIUM |
| R:14 | Crebain | b | dark | HIGH |
| R:15 | Tanglethorn | & | green | HIGH |
| R:16 | Giant Bat | b | gray | HIGH |
| R:17 | Web Spinner | M | white | MEDIUM |
| R:18 | Orc Scout | o | dark | HIGH |

### Layer 2: Orc Warrens (10 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:31 | Orc Slave | o | gray | MEDIUM |
| R:32 | Orc Soldier | o | white | HIGH |
| R:33 | Orc Crossbowman | o | brown | HIGH |
| R:34 | Warg | C | gray | HIGH |
| R:35 | Orc Thrallmaster | o | red | HIGH |
| R:36 | Orc Captain | o | red | HIGH |
| R:37 | Warg Rider | o | dark | MEDIUM |
| R:38 | Hill Troll | T | white | HIGH |
| R:39 | Gashnak, Warg-lord | C | white | HIGH (Boss) |
| R:40 | Orc Warchief | o | red bright | HIGH (Boss) |

### Layer 3: Torture Halls (10 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:51 | Dark Acolyte | @ | violet | HIGH |
| R:52 | Ghoul | z | gray | HIGH |
| R:53 | Mirk-troll | T | dark | HIGH |
| R:54 | Easterling Warrior | @ | brown | MEDIUM |
| R:55 | Dark Sorcerer | @ | dark | HIGH |
| R:56 | Tortured Wretch | @ | gray | MEDIUM |
| R:57 | Easterling Champion | @ | orange | MEDIUM |
| R:58 | Ghast | z | green | HIGH |
| R:59 | Karvag the Torturer | T | red | HIGH (Boss) |
| R:60 | Master Sorcerer | @ | violet bright | HIGH (Boss) |

### Layer 4: Necropolis (8 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:71 | Skeleton | z | white | HIGH |
| R:72 | Skeleton Warrior | z | light gray | HIGH |
| R:73 | Zombie | z | brown | HIGH |
| R:74 | Wight | W | brown | HIGH |
| R:75 | Corpse-candle | w | yellow | MEDIUM |
| R:76 | Necromancer Adept | @ | dark bright | HIGH |
| R:77 | Barrow-wight | W | white | HIGH |
| R:79 | Grishnákh, Crypt Lord | W | violet | HIGH (Boss) |

### Layer 5: Wraith Domain (6 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:91 | Phantom | w | gray | HIGH |
| R:92 | Shadow | W | black | HIGH |
| R:94 | Wraith | W | gray | HIGH |
| R:97 | Vampire Thrall | v | gray | MEDIUM |
| R:98 | Wailing Horror | H | white | HIGH (Boss) |
| R:99 | Úvatha the Horseman | W | dark bright | HIGH (Boss/Nazgûl) |

### Layer 6: Inner Sanctum (5 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:111 | Black Númenórean | @ | dark bright | HIGH |
| R:112 | Olog-hai | T | gray | HIGH |
| R:113 | Vampire | v | white | HIGH |
| R:115 | Vampire Lord | v | violet bright | HIGH |
| R:118 | Khamûl | W | red | HIGH (Boss/Nazgûl) |

### Layer 7 & Final (3 sprites)
| ID | Monster | Symbol | Color | Priority |
|----|---------|--------|-------|----------|
| R:131 | Elite Olog-hai | T | dark | HIGH |
| R:134 | Thráin's Shade | @ | dark | HIGH (Story) |
| R:135 | Sauron | @ | red bright | CRITICAL |

---

## 3. Terrain Sprites (20 sprites)

### Floors (5 sprites)
| Feature ID | Name | Symbol | Priority |
|------------|------|--------|----------|
| F:0 | Darkness | (space) | HIGH |
| F:1 | Open floor | . | HIGH |
| F:9 | Fading daylight | . | MEDIUM |
| F:31 | Bloodstain | . | LOW |
| F:86 | Vine floor | . | MEDIUM |

### Walls (4 sprites)
| Feature ID | Name | Symbol | Priority |
|------------|------|--------|----------|
| F:56-59 | Dark stone wall | # | HIGH |
| F:48 | Hidden passage | # | MEDIUM |
| F:85 | Tangled roots | # | MEDIUM |
| F:29 | Prison bars | # | MEDIUM |

### Doors (4 sprites)
| Feature ID | Name | Symbol | Priority |
|------------|------|--------|----------|
| F:32 | Iron door | + | HIGH |
| F:4 | Open door | ' | HIGH |
| F:5 | Shattered door | ' | MEDIUM |
| F:6-8 | Warded door | + | MEDIUM |

### Stairs (4 sprites)
| Feature ID | Name | Symbol | Priority |
|------------|------|--------|----------|
| F:80 | Crumbling stairs up | < | HIGH |
| F:81 | Dark stairs down | > | HIGH |
| F:82 | Narrow shaft up | < | MEDIUM |
| F:83 | Narrow shaft down | > | MEDIUM |

### Special Terrain (3 sprites)
| Feature ID | Name | Symbol | Priority |
|------------|------|--------|----------|
| F:64-69 | Orc forge | 0 | HIGH |
| F:12 | Dark pool | ~ | MEDIUM |
| F:13 | Morgul runes | * | MEDIUM |

---

## 4. Trap Sprites (6 sprites - consolidated)

| Feature ID | Name | Symbol | Priority |
|------------|------|--------|----------|
| F:16 | Weakened floor | ^ | HIGH |
| F:17 | Jagged pit | ^ | HIGH |
| F:20 | Noxious fumes | ^ | MEDIUM |
| F:22 | Orc alarm | ^ | HIGH |
| F:26 | Thick web | ^ | HIGH |
| F:27 | Falling stones | ^ | MEDIUM |

---

## 5. Item Sprites (12 sprites - using categories)

### Weapons (4 sprites)
| Category | Examples | Symbol | Priority |
|----------|----------|--------|----------|
| Swords | Knife, Blade, Longsword | \| | HIGH |
| Polearms | Spear, Glaive | / | HIGH |
| Blunt | Staff, Hammer | \\ | MEDIUM |
| Bow | Silvan Bow, Longbow | } | HIGH |

### Armor (4 sprites)
| Category | Examples | Symbol | Priority |
|----------|----------|--------|----------|
| Body | Robe, Leather, Mail | ( or [ | HIGH |
| Shield | Buckler, Tower Shield | ) | HIGH |
| Helm | Iron Helm, Dwarf Mask | ] | HIGH |
| Misc | Boots, Gloves, Cloak | ] or ( | MEDIUM |

### Consumables (2 sprites)
| Category | Examples | Symbol | Priority |
|----------|----------|--------|----------|
| Potion | Various (use color tint) | ! | HIGH |
| Herb/Food | Various (use color tint) | , | HIGH |

### Magic Items (2 sprites)
| Category | Examples | Symbol | Priority |
|----------|----------|--------|----------|
| Ring | Various (use color tint) | = | HIGH |
| Staff | Various (use color tint) | _ | MEDIUM |

---

## 6. Effect Sprites (4 sprites)

| Effect | Description | Priority |
|--------|-------------|----------|
| Arrow projectile | Flying arrow | HIGH |
| Fire breath | Dragon/fire effect | MEDIUM |
| Darkness | Shadow spell effect | MEDIUM |
| Impact | Hit/damage indicator | HIGH |

---

## 7. UI Sprites (5 sprites)

| Element | Description | Priority |
|---------|-------------|----------|
| Item pile | Multiple items on ground | HIGH |
| Light source | Torch/lantern glow | HIGH |
| Cursor/selection | Player targeting | MEDIUM |
| Status icon (poisoned) | Negative status | MEDIUM |
| Status icon (wounded) | Health warning | MEDIUM |

---

## 8. Sprite Sheet Layout (Recommended)

### 32x32 Tileset Grid (32 columns x 16 rows = 512 tiles)

```
Row 0 (0x80): Terrain - floors, walls, doors
Row 1 (0x81): Terrain - stairs, traps, forges
Row 2 (0x82): Items - rings (21 variants)
Row 3 (0x83): Items - potions (29 variants)
Row 4 (0x84): Items - amulets, staves
Row 5 (0x85): Items - armor, boots, gloves, bows
Row 6 (0x86): Items - weapons
Row 7 (0x87): Monsters - spiders, undead
Row 8 (0x88): Monsters - orcs, wolves, humanoids
Row 9 (0x89): Monsters - trolls, bosses
Row 10 (0x8A): Monsters - wraiths, vampires, Nazgûl
Row 11 (0x8B): Effects, projectiles
Row 12 (0x8C): UI elements, numbers
Row 13 (0x8D): Player - Elf variants
Row 14 (0x8E): Player - Man variants
Row 15 (0x8F): Player - Dwarf variants
```

**Image Size**: 1024 x 512 pixels (32 cols x 16 rows @ 32px)

---

## 9. Priority Summary

| Priority | Count | Description |
|----------|-------|-------------|
| CRITICAL | 1 | Sauron - must be iconic |
| HIGH | 52 | Core gameplay sprites |
| MEDIUM | 24 | Important but can use placeholders |
| LOW | 5 | Nice to have |
| **Total** | **82** | Matches PRD target |

---

## 10. Color Palette Recommendations

### Primary Colors (8)
| Name | Hex | Use |
|------|-----|-----|
| Shadow Black | #1a1a2e | Darkness, deep shadows |
| Stone Gray | #4a4a5c | Walls, armor |
| Blood Red | #8b0000 | Danger, fire, Sauron |
| Corruption Violet | #6b3a6b | Magic, wraiths |
| Mirkwood Green | #2d4a2d | Forest, poison |
| Bone White | #d4c8b8 | Skeletons, light |
| Iron Brown | #5c4033 | Doors, weapons |
| Gold Accent | #c9a227 | Items, highlights |

### Secondary Colors (8)
| Name | Hex | Use |
|------|-----|-----|
| Deep Purple | #2d1b3d | Nazgûl, shadow magic |
| Rust Orange | #8b4513 | Orcs, brown creatures |
| Sickly Green | #4a6b3a | Ghouls, poison |
| Ice Blue | #6b8ea6 | Cold effects |
| Flesh Pink | #c9a090 | Human skin |
| Dark Blue | #2d3a5c | Night, water |
| Pale Yellow | #c9c990 | Light effects |
| Silver | #a0a0b0 | Mithril, elven items |
