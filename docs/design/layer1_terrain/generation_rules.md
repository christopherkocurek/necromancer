# Layer 1 Generation Rules

## Overview

Layer 1 (Forest Breach, depths 1-3, 50-150ft) should feel like the boundary between Mirkwood forest and the ruined tower. The forest is invading through cracks and gaps.

## Terrain Distribution

### Per-Level Quotas

| Terrain | Depth 1 | Depth 2 | Depth 3 | Notes |
|---------|---------|---------|---------|-------|
| Vine Floor | 20% floor | 15% floor | 10% floor | Decreases deeper |
| Tangled Roots | 12% walls | 10% walls | 8% walls | Decreases deeper |
| Poison Stream | 1-2 streams | 1 stream | 0-1 stream | Rare deeper |
| Sunlight | Existing | Few patches | Very rare | Fades with depth |
| Forest Floor | 10% floor | 5% floor | 3% floor | Decorative |

### Floor Type: Forest Floor (Decorative)

```
# terrain.txt entry
N:87:forest floor
G:.:u
```

Brown-colored floor for visual variety, no special effect.

## Generation Algorithm

### Main Function: make_forest_terrain()

```c
/*
 * Apply forest terrain to Layer 1 floors (depths 1-3)
 */
void make_forest_terrain(void)
{
    int y, x;
    int vine_chance, root_chance;

    /* Only on depths 1-3 */
    if (p_ptr->depth > 3) return;

    /* Set chances based on depth */
    vine_chance = 25 - (p_ptr->depth * 5);   /* 20%, 15%, 10% */
    root_chance = 14 - (p_ptr->depth * 2);   /* 12%, 10%, 8% */

    /* Scan dungeon */
    for (y = 1; y < p_ptr->cur_map_hgt - 1; y++)
    {
        for (x = 1; x < p_ptr->cur_map_wid - 1; x++)
        {
            /* Convert some floors to vine floor */
            if (cave_feat[y][x] == FEAT_FLOOR)
            {
                if (one_in_(100 / vine_chance))
                {
                    cave_set_feat(y, x, FEAT_VINE_FLOOR);
                }
            }

            /* Convert some walls to tangled roots */
            if (cave_feat[y][x] == FEAT_WALL_EXTRA)
            {
                if (one_in_(100 / root_chance))
                {
                    /* Only if adjacent to floor (edge walls) */
                    if (count_adjacent_floors(y, x) > 0)
                    {
                        cave_set_feat(y, x, FEAT_TANGLED_ROOTS);
                    }
                }
            }
        }
    }

    /* Place poison streams */
    make_poison_streams();

    /* Extend sunlight patches (depth 2-3) */
    if (p_ptr->depth > 1)
    {
        make_sparse_sunlight();
    }
}
```

### Poison Stream Generation

```c
/*
 * Create 1-2 poison streams flowing through the level
 */
void make_poison_streams(void)
{
    int streams = 1;
    int i, y, x, dir, length;

    /* Fewer streams at deeper levels */
    if (p_ptr->depth == 1 && one_in_(2)) streams = 2;
    if (p_ptr->depth == 3 && one_in_(2)) streams = 0;

    for (i = 0; i < streams; i++)
    {
        /* Start at random edge */
        if (one_in_(2))
        {
            /* Horizontal stream */
            y = rand_range(5, p_ptr->cur_map_hgt - 5);
            x = 1;
            dir = 4; /* East */
        }
        else
        {
            /* Vertical stream */
            y = 1;
            x = rand_range(5, p_ptr->cur_map_wid - 5);
            dir = 2; /* South */
        }

        /* Flow across level */
        length = rand_range(20, 50);
        while (length > 0)
        {
            /* Place stream if floor */
            if (cave_feat[y][x] == FEAT_FLOOR ||
                cave_feat[y][x] == FEAT_VINE_FLOOR)
            {
                cave_set_feat(y, x, FEAT_POISON_STREAM);
            }

            /* Move in direction with some wandering */
            if (one_in_(3))
            {
                /* Perpendicular drift */
                if (dir == 4) y += (one_in_(2) ? 1 : -1);
                else x += (one_in_(2) ? 1 : -1);
            }
            else
            {
                /* Main direction */
                if (dir == 4) x++;
                else y++;
            }

            /* Bounds check */
            if (y < 1 || y >= p_ptr->cur_map_hgt - 1) break;
            if (x < 1 || x >= p_ptr->cur_map_wid - 1) break;

            length--;
        }
    }
}
```

### Sparse Sunlight (Depths 2-3)

```c
/*
 * Place a few sunlight patches on depths 2-3
 */
void make_sparse_sunlight(void)
{
    int count = (4 - p_ptr->depth) * 3;  /* 6 on depth 2, 3 on depth 3 */
    int y, x, tries;

    for (int i = 0; i < count; i++)
    {
        tries = 100;
        while (tries > 0)
        {
            y = rand_range(1, p_ptr->cur_map_hgt - 2);
            x = rand_range(1, p_ptr->cur_map_wid - 2);

            if (cave_feat[y][x] == FEAT_FLOOR &&
                count_adjacent_floors(y, x) >= 6)
            {
                cave_set_feat(y, x, FEAT_SUNLIGHT);
                break;
            }
            tries--;
        }
    }
}
```

## Integration Point

In generate.c `cave_gen()`, after existing terrain placement:

```c
/* Place rubble, player, stairs */
if (!place_rubble_player())
{
    // ... existing error handling
}

/* Apply Layer 1 forest terrain */
if (p_ptr->depth <= 3)
{
    make_forest_terrain();
}

/* Existing sunlight patches for depth 1 */
if (p_ptr->depth == 1 && p_ptr->stairs_taken == 0)
{
    make_patches_of_sunlight();
}
```

## Exclusion Zones

Terrain should NOT replace:
- Stairs (FEAT_LESS, FEAT_MORE, shafts)
- Forges (FEAT_FORGE_*)
- Doors
- Vault interiors (CAVE_ICKY flag)
- Player starting position

## Visual Result

```
###r###r###    r = tangled roots
r.vv...vv.r    v = vine floor
#.vv.*.vv.#    * = sunlight
#.vv...vv.#    ~ = poison stream (flowing)
#....~~~..#
#.vv~~~vv.#
#.vv...vv.#
###r###r###
```

## Post-Generation Validation

After terrain placement:
1. Verify connectivity (existing check)
2. Ensure stairs reachable
3. Ensure forges accessible
4. Ensure no isolated areas blocked by roots
