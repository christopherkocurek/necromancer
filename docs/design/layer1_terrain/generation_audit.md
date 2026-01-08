# Dungeon Generation Audit

## Primary File: src/generate.c

### Main Generation Flow

```
generate_cave()           <- Entry point
  └─► cave_gen()          <- Main generation logic
        ├─► basic_granite()         <- Fill with walls
        ├─► room_build() loop       <- Place rooms/vaults
        ├─► connect_rooms_stairs()  <- Create corridors
        ├─► place_rubble_player()   <- Place terrain, player
        ├─► make_patches_of_sunlight() <- Special terrain (depth 1)
        └─► alloc_object() loop     <- Place items/monsters
```

### Key Functions

#### cave_gen() (line 3515)
Main dungeon generation. Key sections:
- **Dungeon size**: Lines 3540-3546 - Size based on depth (3x3 to 5x5 panels)
- **Room placement**: Lines 3601-3638 - Loop building rooms
- **Special depth handling**: Line 3690-3696 - Depth 1 sunlight patches

#### Room Types
```c
room_build(1)  -> build_type1()  // Standard room
room_build(2)  -> build_type2()  // Cross room
room_build(6)  -> build_type6()  // Interesting room (with forge chance)
room_build(7)  -> build_type7()  // Lesser vault
room_build(8)  -> build_type8()  // Greater vault
```

#### Vault Selection (build_type7, build_type8)
```c
// Lesser vault selection (line 3118):
if ((v_ptr->typ == 7) && (v_ptr->depth <= p_ptr->depth)
    && (one_in_(v_ptr->rarity)))
```
- `v_ptr->typ`: 7=lesser, 8=greater
- `v_ptr->depth`: Minimum depth for vault
- `v_ptr->rarity`: 1-in-N chance of selection

---

## Depth-Based Behavior

### Current Depth Checks in cave_gen()
```c
// Line 3690-3696
if (p_ptr->depth == 1)
{
    mon_gen = dun->cent_n / 2;  // Fewer monsters at 50ft
    if (p_ptr->stairs_taken == 0)
        make_patches_of_sunlight();  // Sunlight at game start
}
```

### Depth Variable
- `p_ptr->depth` - Current dungeon level (1-20)
- Depth 1-3 = 50-150ft = Layer 1 (Forest Breach)
- Depth 4-6 = 150-300ft = Layer 2 (Orc Warrens)
- etc.

---

## Special Terrain Placement

### make_patches_of_sunlight() (line 3487)
Pattern for terrain placement:
```c
void make_patches_of_sunlight()
{
    int i, x, y;

    // Cluster near player
    for (i = 0; i < 40; ++i)
    {
        y = rand_range(MAX(p_ptr->py - 5, 1),
            MIN(p_ptr->py + 5, p_ptr->cur_map_hgt - 2));
        x = rand_range(MAX(p_ptr->px - 5, 1),
            MIN(p_ptr->px + 5, p_ptr->cur_map_wid - 2));
        make_patch_of_sunlight(y, x);
    }

    // Scattered across level
    for (i = 0; i < 20; ++i)
    {
        y = rand_range(1, p_ptr->cur_map_hgt - 2);
        x = rand_range(1, p_ptr->cur_map_wid - 2);
        make_patch_of_sunlight(y, x);
    }
}
```

### make_patch_of_sunlight() (line 3452)
Checks for valid placement:
```c
if (cave_info[y][x] & CAVE_GLOW)  // Must be lit
{
    // Count adjacent floors
    if (floor > 6)  // Need open space
    {
        cave_set_feat(y, x, FEAT_RUBBLE);  // Central rubble
        // Surround with FEAT_SUNLIGHT
        if (one_in_(4))
            cave_set_feat(n, m, FEAT_SUNLIGHT);
    }
}
```

---

## How to Add Layer 1 Terrain

### Recommended Approach

1. **Create terrain placement function**:
```c
void make_forest_terrain()
{
    if (p_ptr->depth > 3) return;  // Only Layer 1

    // Place poison streams
    make_poison_streams();

    // Scatter vine floors
    make_vine_patches();

    // Replace some walls with tangled roots
    make_tangled_roots();
}
```

2. **Call from cave_gen() after room generation**:
```c
// In cave_gen(), after make_patches_of_sunlight()
if (p_ptr->depth <= 3)
{
    make_forest_terrain();
}
```

3. **Terrain replacement pass**:
- Scan generated dungeon
- Replace some FEAT_FLOOR with vine floor
- Replace some FEAT_WALL_* with tangled roots
- Place poison stream "rivers" using flow algorithm

---

## Vault Terrain Integration

Vaults can include custom terrain via vault.txt symbols.

### Current Vault Symbols (from init1.c parsing):
```
#  - Wall
.  - Floor
+  - Door
<  - Up stairs
>  - Down stairs
~  - Decorative (dark pool, etc.)
0  - Forge
```

### Adding New Symbols for Forest Terrain:
Add parsing in init1.c for:
```
p  - Poison stream
v  - Vine floor
r  - Tangled roots
s  - Sunlight patch
```

---

## Key Files for Implementation

| File | Purpose |
|------|---------|
| src/generate.c | Main generation, terrain placement |
| src/init1.c | Vault text parsing |
| lib/edit/vault.txt | Vault definitions |
| lib/edit/terrain.txt | Terrain type definitions |
| src/defines.h | FEAT_* constants |

---

## Implementation Order

1. Add terrain to terrain.txt (PREP)
2. Add FEAT_* constants to defines.h (PREP)
3. Add vault symbols to init1.c parsing (if needed)
4. Create make_forest_terrain() and sub-functions
5. Call from cave_gen() for depths 1-3
6. Add forest vaults to vault.txt
