# Stat Tracking Audit - The Necromancer

**Date:** 2026-01-10
**Version:** Beta 1.0.1

## Already Tracked Stats

### In player_type (types.h)

| Stat | Field | Type | Notes |
|------|-------|------|-------|
| Depth | `depth` | s16b | Current dungeon depth |
| Max depth | tracked in high_score | - | Maximum reached |
| Stairs taken | `stairs_taken` | u16b | Number of stair uses |
| Cause of death | `died_from[80]` | char[] | Text description |
| Escaped | `escaped` | u16b | Boolean flag |
| Self-made artifacts | `self_made_arts` | byte | Count |
| Artifacts generated | `artefacts` | byte | Total artifacts on level |

### In monster_lore (types.h:405-430)

| Stat | Field | Type | Notes |
|------|-------|------|-------|
| Deaths from monster | `deaths` | s16b | Per monster type |
| Sightings (this life) | `psights` | s16b | Per monster type |
| Kills (this life) | `pkills` | s16b | Per monster type |
| Kills (all lives) | `tkills` | s16b | Per monster type |

### In high_score (types.h:1072-1099)

| Stat | Field | Type | Notes |
|------|-------|------|-------|
| Turns taken | `turns[10]` | char[] | String format |
| Current level | `cur_lev[4]` | char[] | Player level |
| Current depth | `cur_dun[4]` | char[] | Depth |
| Max depth | `max_dun[4]` | char[] | Deepest |
| Death cause | `how[50]` | char[] | Method of death |
| Escaped | `escaped[2]` | char[] | t/f |

### Global Variables

| Stat | Variable | Location |
|------|----------|----------|
| Game turn | `turn` | variable.c |
| Total gold | Calculated from inventory | - |

## Stats Needing Addition

### Combat Stats (add to player_type)

```c
/* Death sequence tracking - combat */
s32b damage_dealt_total;      /* Total damage dealt to enemies */
s16b biggest_hit;             /* Largest single hit */
s16b biggest_enemy_killed;    /* Monster index of toughest kill */
s16b biggest_enemy_seen;      /* Monster index of toughest seen */
char killer_name[80];         /* Name of monster that killed player */
s16b killer_idx;              /* Monster race index of killer */
```

### Stealth Stats (add to player_type)

```c
/* Death sequence tracking - stealth */
u16b enemies_avoided;         /* Monsters that lost track of player */
u16b times_detected;          /* Times spotted by monsters */
u16b stealth_streak_current;  /* Current undetected turns */
u16b stealth_streak_max;      /* Longest stealth streak */
u16b silent_kills;            /* Kills without alerting others */
u16b doors_closed;            /* Doors closed behind player */
```

### Treasure/Journey Stats (add to player_type)

```c
/* Death sequence tracking - treasure */
s16b rarest_item_idx;         /* Object kind index of rarest find */
s16b rarest_item_depth;       /* Depth where rarest was found */
u16b lore_notes_found;        /* Number of lore notes read */
u16b potions_quaffed;         /* Potions consumed */
u16b herbs_consumed;          /* Herbs eaten */
u16b wands_zapped;            /* Wand uses */
u16b items_forged;            /* Items created at forge */
```

### Achievement Flags (add to player_type)

```c
/* Death sequence tracking - achievements */
byte saw_sauron;              /* Seen the Necromancer */
byte found_thrain;            /* Found Thrain */
byte stole_ring;              /* Took Ring of Thrain */
byte killed_nazgul;           /* Killed a Nazgul */
```

## Implementation Locations

### Where to Increment Stats

| Stat | Location | Event |
|------|----------|-------|
| damage_dealt_total | melee1.c, spells1.c | On successful hit |
| biggest_hit | melee1.c, spells1.c | Compare on each hit |
| biggest_enemy_killed | melee2.c | On monster death |
| enemies_avoided | melee2.c | When monster loses player |
| times_detected | melee2.c | When monster spots player |
| stealth_streak | melee2.c | Track in monster perception |
| silent_kills | melee2.c | Kill without nearby alert |
| doors_closed | cmd2.c | On close door command |
| potions_quaffed | cmd6.c | On quaff |
| killer_name/idx | files.c | In damage function when fatal |

## Save/Load Considerations

New stats must be added to:
- `save.c` - Write stats to savefile
- `load.c` - Read stats from savefile
- Increment savefile version for compatibility
