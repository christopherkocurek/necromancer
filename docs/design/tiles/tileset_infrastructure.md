# The Necromancer - Tileset Infrastructure Documentation

Generated for tileset PRD AUDIT-002.

## 1. Overview

The game uses the standard Angband/Sil tileset system, which supports multiple graphics modes:
- **ASCII Mode** (default): Text characters with colors
- **Graphics Mode**: Sprite-based tiles loaded from PNG/BMP images

The current implementation includes the **MicroChasm Tileset** (16x16 pixels), originally designed for Sil/Sil-Q.

---

## 2. File Structure

### Graphics Assets
```
lib/xtra/graf/
├── 16x16.bmp              # Legacy tileset (BMP format)
└── 16x16_microchasm.png   # MicroChasm tileset (PNG format)
```

### Preference Files (Symbol-to-Tile Mapping)
```
lib/pref/
├── graf.prf               # Main graphics loader (platform-specific dispatch)
├── graf-new.prf           # MicroChasm tileset mappings (primary)
├── graf-mac.prf           # macOS-specific graphics
├── graf-win.prf           # Windows-specific graphics
├── graf-x11.prf           # X11 (Linux) graphics
├── graf-gcu.prf           # Terminal (ncurses) graphics
├── xtra-new.prf           # Player sprite remapping (race/class combinations)
├── flvr-new.prf           # Flavored item mappings (rings, potions, etc.)
├── flvr-dvg.prf           # Alternate flavor mappings
└── flvr-xxx.prf           # Default flavor mappings
```

---

## 3. Preference File Format

### Feature Definitions (F:)
Maps terrain feature IDs to tile coordinates:
```
# open floor
F:1:0x80/0x81

# granite wall
F:56:0x80/0x84
```

Format: `F:<feature_id>:<row>/<column>`
- `0x80` = row 0 in tileset (offset by 0x80)
- `0x81` = column 1 in tileset

### Monster Definitions (R:)
Maps monster race IDs to tile coordinates:
```
# player (Noldor)
R:0:0x8D/0x80

# Orc
R:21:0x87/0x9B
```

Format: `R:<monster_id>:<row>/<column>`

### Object Definitions (K:)
Maps object kind IDs to tile coordinates:
```
# & Dagger~
K:56:0x86/0x80

# & Long Sword~
K:64:0x86/0x83
```

Format: `K:<object_id>:<row>/<column>`

### Flavor Definitions (L:)
Maps flavor IDs to tile coordinates (for randomized item appearances):
```
# Amethyst ring
L:2:0x82/0x80

# Clear potion
L:193:0x83/0x80
```

Format: `L:<flavor_id>:<row>/<column>`

### Special Effects (S:)
Maps effect IDs to tile coordinates:
```
# Arrow Impact
S:0x3F:0x8B/0x92

# Fire Breath
S:0x34:0x8B/0x8E
```

---

## 4. Tileset Image Layout

The MicroChasm tileset (16x16_microchasm.png) is organized as a grid:
- Each tile is **16x16 pixels**
- Rows and columns are indexed starting from 0x80 (128)
- The image contains ~20 rows x 32 columns = ~640 tiles

### Row Layout (approximate from graf-new.prf):
| Row (hex) | Row (dec) | Contents |
|-----------|-----------|----------|
| 0x80 | 0 | Terrain (floors, walls, doors, stairs) |
| 0x81 | 1 | Chests, mithril, misc objects |
| 0x82 | 2 | Rings, horns, misc |
| 0x83 | 3 | Potions |
| 0x84 | 4 | Amulets, staves |
| 0x85 | 5 | Armor, boots, gloves, bows |
| 0x86 | 6 | Weapons (swords, spears, axes) |
| 0x87 | 7 | Spiders, undead, monsters |
| 0x88 | 8 | More monsters (trolls, wolves, humanoids) |
| 0x89 | 9 | More monsters (dragons, serpents, giants) |
| 0x8A | 10 | Traps, special monsters (balrogs) |
| 0x8B | 11 | Effects, projectiles, special items |
| 0x8C | 12 | UI elements (numbers, icons) |
| 0x8D | 13 | Player sprites (Noldor race) |
| 0x8E | 14 | Player sprites (Naugrim race) |
| 0x8F | 15 | Forges |

---

## 5. Platform-Specific Implementation

### macOS (main-cocoa.m)
- Uses Cocoa/AppKit for tile rendering
- Loads PNG images via NSImage
- Tile size configurable via preferences

### Windows (main-win.c)
- Uses Windows GDI for tile rendering
- Supports both BMP and PNG formats
- Configurable tile scaling

### X11/Linux (main-x11.c)
- Uses X11 pixmaps for tile rendering
- Requires 8-bit color display minimum

### Terminal (main-gcu.c)
- ASCII-only, no graphics support
- Uses ncurses for color text

---

## 6. Current Monster Mappings (graf-new.prf)

The existing tileset maps 100+ monsters. Key mappings for The Necromancer:

| Monster ID | Name | Tile Location |
|------------|------|---------------|
| R:0-3 | Player (4 races) | 0x8D-0x8E rows |
| R:11 | Wolf | 0x88/0x91 |
| R:12 | Tanglethorn | 0x86/0x9D |
| R:21 | Orc | 0x87/0x9B |
| R:31-51 | Orc variants | 0x87/0x99-0x9F |
| R:74 | Mountain troll | 0x89/0x8D |
| R:75 | Tattered wight | 0x87/0x8B |
| R:92 | Warg | 0x88/0x93 |
| R:112 | Barrow wight | 0x87/0x8D |
| R:131 | Werewolf | 0x88/0x94 |
| R:133 | Shadow | 0x87/0x97 |
| R:183 | Wraith | 0x87/0x8A |
| R:193 | Vampire | 0x87/0x90 |
| R:244 | Gorthaur (Sauron) | 0x8A/0x91 |
| R:251 | Morgoth | 0x8A/0x92 |

**Note**: Many of these IDs are from the original Sil-Q monster list and may not match The Necromancer's monster.txt IDs!

---

## 7. Creating a New Tileset

### Step 1: Create Tileset Image
- Create PNG image at desired resolution (recommend 32x32 for new tileset)
- Organize tiles in a grid layout
- Minimum size: ~32 columns x 20 rows = 640 tiles

### Step 2: Create Preference File
Create `lib/pref/graf-necromancer.prf`:
```
# File: graf-necromancer.prf
# Custom tileset for The Necromancer

# Include standard font mappings
%:font-xxx.prf

# Feature mappings
F:0:0x80/0x80    # darkness
F:1:0x80/0x81    # floor
F:56:0x80/0x84   # wall
# ... etc

# Monster mappings (use IDs from monster.txt)
R:0:0x8D/0x80    # player
R:11:0x87/0x80   # Mirkwood Spider
R:12:0x87/0x81   # Giant Rat
# ... etc

# Object mappings (use IDs from object.txt)
K:56:0x86/0x80   # Ranger's Knife
K:57:0x86/0x81   # Orc-blade
# ... etc
```

### Step 3: Register Tileset
Add to `lib/pref/graf.prf`:
```
?:[EQU $GRAF necromancer]
%:graf-necromancer.prf
```

### Step 4: Place Tileset Image
Copy the PNG to:
- `lib/xtra/graf/32x32_necromancer.png`

### Step 5: Update Source (if needed)
May need to update `main-*.c` files to:
- Add tileset to graphics menu
- Set correct tile dimensions
- Handle PNG loading

---

## 8. Required Changes for 32x32 Tileset

### Code Changes Needed
1. **main-cocoa.m**: Update tile size constants
2. **main-win.c**: Update tile loading code
3. **defines.h**: May need new GRAF_MODE constant

### Preference File Updates
1. Create new `graf-necromancer.prf` with all mappings
2. Create new `flvr-necromancer.prf` for flavored items
3. Update player sprite mappings for 3 races (Elf, Man, Dwarf)

### Asset Requirements
- Main tileset: `32x32_necromancer.png`
- Recommended size: 1024x640 pixels (32 columns x 20 rows)
- Format: PNG with alpha transparency

---

## 9. Monster ID Mapping (Critical!)

The existing graf-new.prf uses **Sil-Q monster IDs**, not The Necromancer's IDs!

**The Necromancer's monster.txt IDs:**
| ID | Monster |
|----|---------|
| 0-3 | Player graphics |
| 11 | Mirkwood Spider |
| 12 | Giant Rat |
| 13 | Black Squirrel |
| 14 | Crebain |
| 15 | Tanglethorn |
| ... | ... |
| 135 | Sauron, the Necromancer |

A new preference file must use these IDs, **not** the Sil-Q IDs from graf-new.prf!

---

## 10. Summary

| Component | Location | Purpose |
|-----------|----------|---------|
| Tileset image | lib/xtra/graf/*.png | Sprite sheet |
| Main prf | lib/pref/graf-new.prf | Symbol-to-tile mapping |
| Flavor prf | lib/pref/flvr-new.prf | Randomized item appearances |
| Player prf | lib/pref/xtra-new.prf | Race/class player sprites |
| Platform code | src/main-*.c | Tile rendering |

The infrastructure is **ready** for a new tileset. The main work is:
1. Creating the sprite sheet PNG
2. Writing the preference file with correct ID mappings
3. Testing on all platforms (macOS, Windows, Linux)
