# Layer 1 Forest Breach Terrain - Final Implementation Specification

## Overview

Layer 1 (depths 1-3, 50-150ft) represents the Forest Breach - where Mirkwood's corrupted vegetation invades the ruined upper levels of Dol Guldur.

---

## Part 1: Terrain Definitions

### New Terrain Types

Add to **lib/edit/terrain.txt**:

```
# 0x54 --> poison stream (Layer 1 hazard)
N:84:poison stream
G:~:G

# 0x55 --> tangled roots (Layer 1 wall variant)
N:85:tangled roots
G:#:u

# 0x56 --> vine floor (Layer 1 floor variant)
N:86:vine floor
G:.:g

# 0x57 --> forest floor (Layer 1 decorative)
N:87:forest floor
G:.:u
```

### FEAT Constants

Add to **src/defines.h** (after existing FEAT_* definitions):

```c
/* Layer 1 Forest Terrain */
#define FEAT_POISON_STREAM  0x54  /* 84 - Poisons on entry */
#define FEAT_TANGLED_ROOTS  0x55  /* 85 - Blocks move, allows sight/projectiles */
#define FEAT_VINE_FLOOR     0x56  /* 86 - Slows movement 50% */
#define FEAT_FOREST_FLOOR   0x57  /* 87 - Decorative brown floor */
```

---

## Part 2: Effect Implementation

### 2.1 Poison Stream (src/cmd1.c)

In `move_player()` after successful movement:

```c
/* Check for poison stream */
if (cave_feat[y][x] == FEAT_POISON_STREAM)
{
    msg_print("You wade through the poisoned stream.");

    /* Check for poison resistance */
    if (!p_ptr->resist_pois)
    {
        /* Constitution check vs difficulty 10 */
        if (skill_check(PLAYER, p_ptr->stat_use[A_CON], 10, NULL) <= 0)
        {
            if (!p_ptr->poisoned)
            {
                msg_print("The tainted water sickens you!");
                set_poisoned(p_ptr->poisoned + 10 + damroll(2, 10));
            }
        }
    }
}
```

### 2.2 Vine Floor Slow Effect (src/cmd1.c)

In `move_player()` energy calculation section:

```c
/* Vine floor increases movement cost */
if (cave_feat[y][x] == FEAT_VINE_FLOOR)
{
    /* +50% movement cost */
    p_ptr->energy_use = (p_ptr->energy_use * 3) / 2;
}
```

For monsters (src/melee2.c), in movement processing:

```c
/* Vine floor slows non-flying monsters */
if (cave_feat[ny][nx] == FEAT_VINE_FLOOR)
{
    if (!(r_ptr->flags2 & RF2_FLYING))
    {
        /* Reduce energy for this move */
        m_ptr->energy -= 50;
    }
}
```

### 2.3 Tangled Roots (defines.h, cave.c)

Tangled roots block movement but allow projectiles/sight.

Add helper macro to **defines.h**:
```c
/* Check if terrain allows projectiles even if wall */
#define cave_project_bold(Y, X) \
    (!cave_wall_bold(Y, X) || (cave_feat[Y][X] == FEAT_TANGLED_ROOTS))
```

In **src/cave.c** `los()` function, allow LOS through roots:
```c
/* Tangled roots don't block line of sight */
if (cave_feat[y][x] == FEAT_TANGLED_ROOTS)
{
    /* Continue - don't block */
}
```

In tunnel command (**src/cmd2.c**):
```c
else if (cave_feat[y][x] == FEAT_TANGLED_ROOTS)
{
    msg_print("The roots are too dense and tough to clear.");
    return;
}
```

### 2.4 Status Bar Display (src/xtra1.c)

Add to `prt_terrain()`:

```c
else if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_POISON_STREAM)
{
    c_put_str(TERM_L_GREEN, "Poison", ROW_TERRAIN, COL_TERRAIN);
}
else if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_VINE_FLOOR)
{
    c_put_str(TERM_GREEN, "Vines", ROW_TERRAIN, COL_TERRAIN);
}
```

---

## Part 3: Dungeon Generation

### 3.1 New Functions (src/generate.c)

```c
/*
 * Count adjacent floor tiles
 */
static int count_adjacent_floors(int y, int x)
{
    int count = 0;
    int d;

    for (d = 0; d < 8; d++)
    {
        int ny = y + ddy_ddd[d];
        int nx = x + ddx_ddd[d];

        if (cave_floor_bold(ny, nx))
            count++;
    }

    return count;
}

/*
 * Create poison streams flowing through level
 */
static void make_poison_streams(void)
{
    int streams = (p_ptr->depth == 1) ? (1 + one_in_(2)) : one_in_(2);
    int i, y, x, length;

    for (i = 0; i < streams; i++)
    {
        /* Start at random floor position */
        y = rand_range(5, p_ptr->cur_map_hgt - 5);
        x = rand_range(5, p_ptr->cur_map_wid - 5);

        length = rand_range(15, 40);

        while (length > 0)
        {
            if (cave_feat[y][x] == FEAT_FLOOR)
            {
                cave_set_feat(y, x, FEAT_POISON_STREAM);
            }

            /* Wander */
            y += rand_range(-1, 1);
            x += rand_range(-1, 1);

            /* Bounds */
            if (y < 1 || y >= p_ptr->cur_map_hgt - 1) break;
            if (x < 1 || x >= p_ptr->cur_map_wid - 1) break;

            length--;
        }
    }
}

/*
 * Apply forest terrain to Layer 1 (depths 1-3)
 */
void make_forest_terrain(void)
{
    int y, x;
    int vine_chance = 25 - (p_ptr->depth * 5);   /* 20, 15, 10% */
    int root_chance = 14 - (p_ptr->depth * 2);   /* 12, 10, 8% */

    if (p_ptr->depth > 3) return;

    /* Convert terrain */
    for (y = 1; y < p_ptr->cur_map_hgt - 1; y++)
    {
        for (x = 1; x < p_ptr->cur_map_wid - 1; x++)
        {
            /* Skip protected areas */
            if (cave_info[y][x] & (CAVE_ICKY)) continue;

            /* Vine floor */
            if (cave_feat[y][x] == FEAT_FLOOR)
            {
                if (randint(100) <= vine_chance)
                {
                    cave_set_feat(y, x, FEAT_VINE_FLOOR);
                }
            }

            /* Tangled roots (edge walls only) */
            if (cave_feat[y][x] == FEAT_WALL_EXTRA)
            {
                if (randint(100) <= root_chance)
                {
                    if (count_adjacent_floors(y, x) > 0)
                    {
                        cave_set_feat(y, x, FEAT_TANGLED_ROOTS);
                        /* Keep CAVE_WALL flag */
                        cave_info[y][x] |= (CAVE_WALL);
                    }
                }
            }
        }
    }

    /* Add poison streams */
    make_poison_streams();
}
```

### 3.2 Integration (src/generate.c cave_gen())

After `place_rubble_player()`:

```c
/* Apply Layer 1 forest terrain */
if (p_ptr->depth <= 3)
{
    make_forest_terrain();
}
```

---

## Part 4: Vault Support

### 4.1 Vault Symbol Parsing (src/init1.c)

Add to vault character parsing:

```c
case 'p': feat = FEAT_POISON_STREAM; break;
case 'v': feat = FEAT_VINE_FLOOR; break;
case 'r': feat = FEAT_TANGLED_ROOTS; break;
case 'f': feat = FEAT_FOREST_FLOOR; break;
```

### 4.2 New Vaults (lib/edit/vault.txt)

```
# Overgrown Ruins
N:90:Overgrown Ruins
X:7:1:2
D:###############
D:#vvvvvvvvvvvvv#
D:#v...........v#
D:#v.rrr...rrr.v#
D:#v.r.......r.v#
D:#v.....<....v#
D:#v.r.......r.v#
D:#v.rrr...rrr.v#
D:#v...........v#
D:#vvvvvvvvvvvvv#
D:###############

# Poison Pool Grove
N:91:Poison Pool Grove
X:7:2:3
D:#################
D:#vvvvvvvvvvvvvvv#
D:#v.............v#
D:#v..rrr~~~rrr..v#
D:#v..r..~~~..r..v#
D:#v.....~~~.....v#
D:#v..r..~~~..r..v#
D:#v..rrr~~~rrr..v#
D:#v.............v#
D:#vvvvvvvvvvvvvvv#
D:#################

# Sunlit Clearing
N:92:Sunlit Clearing
X:7:1:4
D:#############
D:#vvvvvvvvvvv#
D:#v.........v#
D:#v..rrrrr..v#
D:#v..r...r..v#
D:#v..r.*.r..v#
D:#v..r...r..v#
D:#v..rrrrr..v#
D:#v.........v#
D:#vvvvvvvvvvv#
D:#############
```

Note: `*` is existing sunlight symbol, `~` is used for poison.

---

## Part 5: Files Modified

| File | Changes |
|------|---------|
| lib/edit/terrain.txt | Add 4 new terrain entries (84-87) |
| src/defines.h | Add FEAT_POISON_STREAM, FEAT_TANGLED_ROOTS, FEAT_VINE_FLOOR, FEAT_FOREST_FLOOR |
| src/cmd1.c | Add poison stream and vine floor effects |
| src/melee2.c | Add monster vine floor slowing |
| src/xtra1.c | Add terrain status bar display |
| src/cave.c | Add LOS exception for tangled roots |
| src/cmd2.c | Add tunnel rejection for roots |
| src/generate.c | Add make_forest_terrain() and call from cave_gen() |
| src/init1.c | Add vault symbol parsing for p, v, r, f |
| lib/edit/vault.txt | Add 3+ new forest vaults |

---

## Part 6: Testing Checklist

- [ ] New terrain appears correctly in terrain.txt
- [ ] FEAT_* constants compile without conflict
- [ ] Poison stream: Player gets poisoned on entry (CON check)
- [ ] Poison stream: Poison-resistant player unaffected
- [ ] Vine floor: Movement takes 50% more energy
- [ ] Vine floor: Status bar shows "Vines"
- [ ] Tangled roots: Blocks movement
- [ ] Tangled roots: Allows projectiles through
- [ ] Tangled roots: Allows line of sight
- [ ] Tangled roots: Cannot be tunneled
- [ ] Layer 1 (depth 1-3) generates with forest terrain
- [ ] Terrain density decreases with depth
- [ ] Vaults with forest terrain spawn correctly
- [ ] No terrain in vault interiors (CAVE_ICKY)
- [ ] Stairs and forges not replaced

---

## Implementation Order

1. **terrain.txt** - Add terrain definitions
2. **defines.h** - Add FEAT_* constants
3. **xtra1.c** - Add status bar display
4. **cmd1.c** - Add poison and vine effects
5. **melee2.c** - Add monster vine slowing
6. **cave.c** - Add LOS handling for roots
7. **cmd2.c** - Add tunnel rejection for roots
8. **generate.c** - Add generation functions
9. **init1.c** - Add vault symbol parsing
10. **vault.txt** - Add forest vaults

Ready for implementation.
