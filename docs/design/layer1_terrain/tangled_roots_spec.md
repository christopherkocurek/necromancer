# Tangled Roots Terrain Specification

## Overview

Tangled roots represent Mirkwood's invasive vegetation growing through cracks in the ruined tower. They block physical movement but are sparse enough to see and shoot through.

## Terrain Definition

```
# terrain.txt entry
N:85:tangled roots
G:#:u
```

| Property | Value |
|----------|-------|
| ID | 85 (0x55) |
| Name | tangled roots |
| Symbol | # (wall symbol) |
| Color | u (Brown) |
| Type | Wall-like (blocks movement, allows sight/projectiles) |

## Constant Definition

```c
// defines.h
#define FEAT_TANGLED_ROOTS 0x55  // 85 decimal
```

## Effect Specification

### Movement
- Blocks player and monster movement
- Cannot be tunneled (organic, regrows)
- No climbing over

### Line of Sight
- **Does NOT block** line of sight
- Player can see through roots
- Monsters can see through roots

### Projectiles
- **Does NOT block** arrows/thrown weapons
- Projectiles pass through freely
- Spells/breath weapons pass through

### Combat
- Cannot melee attack through (too dense to reach)
- Ranged attacks work normally

## Implementation Notes

### Wall Classification
Tangled roots need special handling:
- Set CAVE_WALL flag (blocks movement)
- But NOT block line of sight or projectiles

### Macro/Function Updates

Add to defines.h:
```c
/* Check if terrain blocks projectiles */
#define cave_project_bold(Y, X) \
    (!cave_wall_bold(Y, X) || (cave_feat[Y][X] == FEAT_TANGLED_ROOTS))

/* Check if terrain blocks line of sight */
#define cave_los_bold(Y, X) \
    (!cave_wall_bold(Y, X) || (cave_feat[Y][X] == FEAT_TANGLED_ROOTS))
```

Or modify existing wall checks:
```c
// In cave_wall_bold or passability checks
if (cave_feat[Y][X] == FEAT_TANGLED_ROOTS)
{
    // Blocks movement but allows sight/projectiles
}
```

### cave.c Modifications

In map_info() or feat_info lookups, ensure:
- FEAT_TANGLED_ROOTS is classified as wall for movement
- But LOS/projectile calculations treat it as passable

### Tunnel Handling (cmd2.c)

Add to tunnel command:
```c
else if (cave_feat[y][x] == FEAT_TANGLED_ROOTS)
{
    msg_print("The roots are too dense and tough to clear.");
    return;
}
```

## Generation Rules

- Replace ~10% of wall tiles on Layer 1 with tangled roots
- Prefer edges of rooms, corridor walls
- Create clusters (2-5 adjacent tiles)
- Avoid completely enclosing spaces

## Visual Example

```
###r####      r = tangled roots
#......#
r......r      Player can see through 'r'
#......#      Arrows can pass through 'r'
#......#      Cannot walk through 'r'
####r###
```

## Tactical Uses

- Provides cover while allowing ranged combat
- Creates interesting sight lines
- Archers can shoot through roots
- Monsters can be seen but not reached
- Strategic flanking opportunities

## Balance Considerations

- Visual variety for Layer 1
- Minor tactical advantage (see enemies before reaching)
- Does not significantly change difficulty
- Complements stealth gameplay (can observe without engagement)
