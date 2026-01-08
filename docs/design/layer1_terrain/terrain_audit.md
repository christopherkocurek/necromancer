# Terrain System Audit

## File: lib/edit/terrain.txt

### Format
```
N:serial_number:terrain_name
G:symbol:color
M:mimic_feature  (optional - makes terrain look like another)
```

### Color Codes
```
D - Dark Gray    w - White          s - Gray          o - Orange
r - Red          g - Green          b - Blue          u - Brown
d - Black        W - Light Gray     v - Violet        y - Yellow
R - Light Red    G - Light Green    B - Light Blue    U - Light Brown
```

### Current Terrain Types (0x00-0x53)

| ID | Hex | Name | Symbol | Color | Type |
|----|-----|------|--------|-------|------|
| 0 | 0x00 | darkness | (space) | w | special |
| 1 | 0x01 | open floor | . | s | floor |
| 2 | 0x02 | bottomless pit | % | D | hazard |
| 3 | 0x03 | protective rune | ; | G | floor |
| 4 | 0x04 | open door | ' | U | door |
| 5 | 0x05 | shattered door | ' | s | door |
| 6-8 | 0x06-08 | warded door | + | G/B/v | door |
| 9 | 0x09 | fading daylight | . | y | floor (FEAT_SUNLIGHT) |
| 10-11 | 0x0A-0B | rage floor/wall | 1 | s | tileset |
| 12 | 0x0C | dark pool | ~ | D | Dol Guldur decorative |
| 13 | 0x0D | morgul runes | * | v | Dol Guldur decorative |
| 14 | 0x0E | shadow brazier | 0 | D | Dol Guldur decorative |
| 15 | 0x0F | torture rack | & | r | Dol Guldur decorative |
| 16-28 | 0x10-1C | traps | ^ | various | traps |
| 29 | 0x1D | prison bars | # | s | Dol Guldur wall-like |
| 30 | 0x1E | chains | \ | s | Dol Guldur decorative |
| 31 | 0x1F | bloodstain | . | r | Dol Guldur decorative |
| 32-47 | 0x20-2F | doors (iron/locked/jammed) | + | U | doors |
| 48 | 0x30 | hidden passage | # | W | secret door |
| 49 | 0x31 | fallen masonry | : | s | FEAT_RUBBLE |
| 50 | 0x32 | **UNUSED** | - | - | available |
| 51 | 0x33 | quartz vein | % | w | wall |
| 52-55 | 0x34-37 | **UNUSED** | - | - | available |
| 56-59 | 0x38-3B | dark stone wall | # | D | walls |
| 60-62 | 0x3C-3E | **UNUSED** | - | - | available |
| 63 | 0x3F | dark stone wall (perm) | # | D | permanent wall |
| 64-75 | 0x40-4B | forges (orc/shadow) | 0 | s/v | forges |
| 76-79 | 0x4C-4F | forge 'Angdur' | 0 | D/v | unique forge |
| 80-83 | 0x50-53 | stairs | < / > | W/D | stairs |

### Available Slots for New Terrain
- **50 (0x32)**: In wall range but marked unused - could be repurposed
- **52-55 (0x34-0x37)**: In wall range, marked unused
- **60-62 (0x3C-0x3E)**: In wall range, marked unused

**Note**: All unused slots are in the WALL range (0x30-0x3F). For floor-type terrain, we should use the unused slots but ensure they're NOT in the wall range or properly flagged.

---

## FEAT_* Constants (src/defines.h)

### Key Feature Constants
```c
#define FEAT_NONE        0x00
#define FEAT_FLOOR       0x01
#define FEAT_CHASM       0x02  // Causes falling, blocks normal movement
#define FEAT_GLYPH       0x03
#define FEAT_SUNLIGHT    0x09  // Lights area, damages HURT_LITE monsters

#define FEAT_RUBBLE      0x31  // Blocks movement, can be tunneled
#define FEAT_QUARTZ      0x33
#define FEAT_SECRET      0x30  // Hidden passage

#define FEAT_WALL_HEAD   0x30
#define FEAT_WALL_TAIL   0x3F
#define FEAT_WALL_EXTRA  0x38
#define FEAT_WALL_PERM   0x3F
```

### Cave Info Flags
```c
#define CAVE_WALL   0x0080  // Grid is a wall (blocks movement)
#define CAVE_MARK   0x0001  // Grid is memorized
```

### Terrain Check Macros
```c
cave_floor_bold(Y, X)  // Returns true if NOT a wall
cave_wall_bold(Y, X)   // Returns true if IS a wall
cave_passable(Y, X)    // Complex passability check
```

---

## How Terrain Effects Work

### FEAT_SUNLIGHT (fading daylight)
- Location: src/cmd1.c, src/cave.c, src/xtra1.c
- **Light**: Provides illumination to adjacent squares
- **Monster Damage**: Monsters with HURT_LITE flag take damage
- **UI**: prt_terrain() displays "Sunlight" when standing in it

### FEAT_CHASM (bottomless pit)
- Location: src/cmd1.c, src/melee2.c, src/dungeon.c
- **Falling**: Player/monster falls if entering without flying
- **Blocking**: Cannot normally cross
- **Projectiles**: Projectiles can cross

### FEAT_RUBBLE (fallen masonry)
- Location: src/cmd2.c, src/cave.c, many files
- **Blocking**: Blocks movement
- **Tunneling**: Can be cleared with effort
- **Projectiles**: Partially blocks

---

## Rendering (src/cave.c)

Terrain is rendered via `map_info()` which looks up:
1. `f_info[feat]` for base appearance
2. Color from G: line in terrain.txt
3. Symbol from G: line in terrain.txt

The `f_info` array is loaded from terrain.txt via init2.c.

---

## Adding New Terrain

### Steps Required:
1. Add entry to lib/edit/terrain.txt with N:, G:, and optional M:
2. Add FEAT_* constant to src/defines.h
3. Add effect handling code to relevant src files
4. Ensure cave_info flags are set correctly (CAVE_WALL if wall)

### Recommended New Terrain Slots

Since all unused slots (50, 52-55, 60-62) are in the wall range, for floor-type terrain we have two options:

**Option A**: Use slots but ensure they're treated as floor by code
- Risk: May have unforeseen wall-check issues

**Option B**: Extend terrain.txt beyond current range
- Add new entries after 83 (0x53)
- Slots 84+ are available
- Safer approach

**Recommendation**: Use slots 84-88 for new Layer 1 terrain:
- 84 (0x54): poison stream
- 85 (0x55): tangled roots
- 86 (0x56): vine floor
- 87 (0x57): sunlight patch (alternate to FEAT_SUNLIGHT?)
- 88 (0x58): forest floor

---

## Dol Guldur Terrain Pattern

Existing Dol Guldur terrain (12-15, 29-31) are decorative only:
- No special effect code
- Visual variety for dungeon atmosphere
- Some mimic other terrain (prison bars mimics wall)

This pattern can be followed for visual terrain. Effect-bearing terrain (poison, slow) needs code in:
- src/cmd1.c (movement handling)
- src/melee2.c (monster movement)
- src/dungeon.c (turn processing)
