# Sunlight Patch Terrain Specification

## Overview

Sunlight patches represent shafts of daylight penetrating through gaps in the ruined tower's upper floors. These are safe havens from dark creatures and provide minor healing.

## Terrain Definition

**Note**: SIL-Q already has FEAT_SUNLIGHT (0x09) as "fading daylight". For Layer 1, we can:
- Option A: Reuse existing FEAT_SUNLIGHT (recommended)
- Option B: Create new FEAT_SUNLIGHT_PATCH with extended effects

**Recommendation**: Use existing FEAT_SUNLIGHT, enhance its effects for Layer 1.

```
# Existing terrain.txt entry (no change needed)
N:9:fading daylight
G:.:y
```

| Property | Value |
|----------|-------|
| ID | 9 (0x09) |
| Name | fading daylight |
| Symbol | . (floor) |
| Color | y (Yellow - bright) |
| Type | Floor (beneficial) |

## Effect Specification (Current)

### Existing Effects
- Illuminates area (light source)
- Damages HURT_LITE monsters
- UI displays "Sunlight" in status bar

### Proposed Enhancements for Layer 1

#### Minor Healing
When player enters/stands in sunlight:
```c
/* Heal 1 HP per turn in sunlight (only if injured) */
if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_SUNLIGHT)
{
    if (p_ptr->chp < p_ptr->mhp)
    {
        hp_player(1);
    }
}
```

#### Undead Damage Increase
On Layer 1, sunlight is stronger:
```c
/* In monster processing */
if (cave_feat[m_ptr->fy][m_ptr->fx] == FEAT_SUNLIGHT)
{
    if (r_ptr->flags3 & RF3_HURT_LITE)
    {
        int damage = 5 + damroll(1, 10);  // Increased from base
        // Apply damage to monster
    }
}
```

## Implementation Notes

### Status Bar (Already Exists)
```c
// In prt_terrain() - already implemented
else if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_SUNLIGHT)
{
    c_put_str(TERM_YELLOW, "Sunlight", ROW_TERRAIN, COL_TERRAIN);
}
```

### Entry Messages (Already Exist)
```c
// In move_player() - already implemented
if (cave_feat[y][x] == FEAT_SUNLIGHT && cave_feat[py][px] != FEAT_SUNLIGHT)
{
    msg_print("You step into a shaft of sunlight.");
}
```

### Healing Addition (dungeon.c)
Add to process_player() per-turn effects:
```c
/* Heal in sunlight */
if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_SUNLIGHT)
{
    if (p_ptr->chp < p_ptr->mhp && one_in_(3))  // Every 3 turns avg
    {
        hp_player(1);
        // Optional message: msg_print("The sunlight warms and heals you.");
    }
}
```

## Generation Rules

### Current Generation (make_patches_of_sunlight)
- Called at depth 1 only, at game start
- Creates patches near player spawn
- Scattered additional patches

### Layer 1 Extension
For depths 2-3, add smaller sunlight patches:
```c
if (p_ptr->depth <= 3)
{
    make_layer1_sunlight();  // Fewer patches on depths 2-3
}
```

## Visual Example

```
###r####
#......#
#..*...#      * = sunlight patch (displayed as 's' in yellow)
#..**..#      Light source, heals, damages undead
#.......#
#######
```

## Strategic Uses

- Safe rest points for regeneration
- Chokepoints against undead enemies
- Tactical positioning in combat
- Early game tutorial for terrain effects

## Balance Considerations

- Healing is slow (1 HP per ~3 turns)
- Not overpowered but useful
- Encourages exploration
- Thematic for "surface layer" feel
- Undead avoidance creates tactical depth
