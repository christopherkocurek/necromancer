# Vine Floor Terrain Specification

## Overview

Vine floor represents dense ground cover from forest vegetation. Movement is slowed as you push through the tangled growth, but it's passable.

## Terrain Definition

```
# terrain.txt entry
N:86:vine floor
G:.:g
```

| Property | Value |
|----------|-------|
| ID | 86 (0x56) |
| Name | vine floor |
| Symbol | . (floor) |
| Color | g (Green - natural) |
| Type | Floor (passable with penalty) |

## Constant Definition

```c
// defines.h
#define FEAT_VINE_FLOOR 0x56  // 86 decimal
```

## Effect Specification

### Movement Cost
- +50% energy cost to move through
- Normal movement = 100 energy
- Vine floor movement = 150 energy

### Combat
- No penalty to attack or evasion
- Unlike webs, vines are low to ground

### Monsters
- Monsters also slowed by vines
- Flying monsters unaffected

## Implementation Notes

### Status Bar Display
Add to prt_terrain() in xtra1.c:
```c
else if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_VINE_FLOOR)
{
    c_put_str(TERM_GREEN, "Vines", ROW_TERRAIN, COL_TERRAIN);
}
```

### Movement Energy (cmd1.c)
Add to move_player() energy calculation:
```c
/* Calculate energy use */
if (cave_feat[y][x] == FEAT_VINE_FLOOR)
{
    /* +50% movement cost in vines */
    p_ptr->energy_use = (p_ptr->energy_use * 3) / 2;
}
```

### Monster Movement (melee2.c)
Add to monster movement energy:
```c
if (cave_feat[ny][nx] == FEAT_VINE_FLOOR)
{
    /* Flying monsters unaffected */
    if (!(r_ptr->flags2 & RF2_FLYING))
    {
        /* +50% movement cost */
        m_ptr->energy -= 50;
    }
}
```

### Entry Message (optional)
```c
if (cave_feat[y][x] == FEAT_VINE_FLOOR && cave_feat[py][px] != FEAT_VINE_FLOOR)
{
    msg_print("You push through tangled vines.");
}
```

## Generation Rules

- Replace ~15-20% of floor tiles on Layer 1
- Prefer room interiors, not corridors
- Create patches (5-15 tiles)
- Avoid stairs and forge squares

## Visual Example

```
#########
#.......#
#..vvv..#      v = vine floor
#..vvv..#      Slows movement by 50%
#..vvv..#
#.......#
#########
```

## Comparison to Web

| Property | Vine Floor | Web Trap |
|----------|------------|----------|
| Movement | 50% slower | Blocked until break free |
| Combat penalty | None | Attack/Evade halved |
| Removal | Cannot remove | Can cut free |
| Monster effect | Slows | Traps |
| Flying bypass | Yes | Yes |

## Balance Considerations

- Mild annoyance, not major obstacle
- Encourages careful pathing
- Affects chase/escape dynamics
- Rewards flying abilities
- Natural-feeling forest environment
