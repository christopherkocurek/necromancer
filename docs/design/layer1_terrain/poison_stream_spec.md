# Poison Stream Terrain Specification

## Overview

Poison streams represent corrupted water flowing through the forest ruins. Stepping into the stream risks poisoning.

## Terrain Definition

```
# terrain.txt entry
N:84:poison stream
G:~:G
```

| Property | Value |
|----------|-------|
| ID | 84 (0x54) |
| Name | poison stream |
| Symbol | ~ (tilde, like water) |
| Color | G (Light Green - sickly) |
| Type | Floor (passable) |

## Constant Definition

```c
// defines.h
#define FEAT_POISON_STREAM 0x54  // 84 decimal
```

## Effect Specification

### On Player Entry
1. Display message: "You wade through the poisoned stream."
2. Make a Constitution check vs difficulty 10
3. On failure: Apply "Poisoned" status (if not already poisoned)
4. Poison resistance grants automatic success
5. No damage if already poisoned (just extends duration)

### On Monster Entry
1. Non-poison-resistant monsters may become poisoned
2. Poison-resistant monsters unaffected

### On Standing
- No additional effect (poison only on entry)
- Visual only while standing in stream

## Implementation Notes

### Status Bar Display
Add to prt_terrain() in xtra1.c:
```c
else if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_POISON_STREAM)
{
    c_put_str(TERM_L_GREEN, "Poison", ROW_TERRAIN, COL_TERRAIN);
}
```

### Entry Effect (cmd1.c)
Add to move_player() after movement success:
```c
if (cave_feat[y][x] == FEAT_POISON_STREAM)
{
    msg_print("You wade through the poisoned stream.");

    /* Check for poison resistance */
    if (!p_ptr->resist_pois && !p_ptr->immune_pois)
    {
        /* Constitution check */
        if (skill_check(PLAYER, p_ptr->stat_use[A_CON], 10, NULL) <= 0)
        {
            /* Apply poison */
            if (!p_ptr->poisoned)
            {
                msg_print("You feel ill from the tainted water!");
                set_poisoned(p_ptr->poisoned + 10 + damroll(2, 10));
            }
        }
    }
}
```

### Monster Effect (melee2.c)
Add to monster movement handling:
```c
if (cave_feat[ny][nx] == FEAT_POISON_STREAM)
{
    if (!(r_ptr->flags3 & RF3_IM_POIS))
    {
        /* Poison the monster */
        if (!m_ptr->poisoned)
        {
            m_ptr->poisoned = 10 + randint(10);
        }
    }
}
```

## Generation Rules

- Appears as "rivers" flowing through Layer 1 floors
- Generated as connected paths, not scattered
- 1-2 streams per level on depths 1-3
- Avoid blocking critical paths

## Visual Example

```
#########
#.......#
#..~~~~~#
#..~...~#
#..~...~#
#..~~~~~#
#.......#
#########
```

## Balance Considerations

- Early game terrain (depths 1-3 only)
- Moderate threat (poison is annoying but not lethal)
- Encourages carrying antidotes or finding resistance
- Can be jumped over with Leaping ability
