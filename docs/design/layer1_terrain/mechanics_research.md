# SIL-Q Terrain Mechanics Research

## Existing Terrain Effect Implementations

### 1. FEAT_TRAP_WEB (Thick Web)

**Definition**: terrain.txt N:26, defines.h 0x1A

**Effects**:
- **Movement restriction**: Must break free before moving (cmd1.c:5235)
- **Combat penalty**: Attack and evasion halved (cmd1.c:871, 908)
- **UI display**: "Web" in status bar (xtra1.c:991)
- **Cannot leap**: Prevents jumping actions (cmd1.c:5048)
- **Disarm**: Can cut free with 'd' command (cmd2.c:2552)

**Implementation Pattern**:
```c
// In player_attack_stat_calc()
if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_TRAP_WEB)
{
    att /= 2;  // Halve attack
}

// In movement handling
if (cave_feat[py][px] == FEAT_TRAP_WEB)
{
    if (!break_free_of_web())
        return;  // Failed to break free, no movement
}
```

---

### 2. FEAT_SUNLIGHT (Fading Daylight)

**Definition**: terrain.txt N:9, defines.h 0x09

**Effects**:
- **Light source**: Illuminates adjacent squares (cave.c:3161)
- **Monster damage**: Hurts HURT_LITE monsters (melee2.c:723)
- **UI display**: "Sunlight" in status bar (xtra1.c:995)
- **Message on entry**: "You step into a shaft of sunlight." (cmd1.c:5250)

**Implementation Pattern**:
```c
// In prt_terrain()
else if (cave_feat[p_ptr->py][p_ptr->px] == FEAT_SUNLIGHT)
{
    c_put_str(TERM_YELLOW, "Sunlight", ROW_TERRAIN, COL_TERRAIN);
}

// In movement messages
if (cave_feat[y][x] == FEAT_SUNLIGHT && cave_feat[py][px] != FEAT_SUNLIGHT)
{
    msg_print("You step into a shaft of sunlight.");
}
```

---

### 3. FEAT_CHASM (Bottomless Pit)

**Definition**: terrain.txt N:2, defines.h 0x02

**Effects**:
- **Blocking**: Cannot walk into without flying (cmd1.c:3144)
- **Falling**: Monsters/player fall if pushed/knocked in (melee2.c:559)
- **Projectiles pass**: Arrows can fly over (cave.c check)
- **Death on fall**: Usually fatal (dungeon.c:1373)

**Implementation Pattern**:
```c
// In handle_trap() switch
case FEAT_CHASM:
{
    // Handle falling
    break;
}

// In movement validation
if (cave_feat[y][x] == FEAT_CHASM)
{
    // Block normal movement
    return FALSE;
}
```

---

### 4. FEAT_RUBBLE (Fallen Masonry)

**Definition**: terrain.txt N:49, defines.h 0x31

**Effects**:
- **Blocks movement**: Cannot walk through
- **Tunnelable**: Can be cleared with effort (cmd2.c:2034)
- **Partial projectile block**: Affects line of sight (cave.c:4070)
- **Trap cover**: Things can hide behind it

**Implementation Pattern**:
```c
// In tunnel command
else if (cave_feat[y][x] == FEAT_RUBBLE)
{
    // Process tunneling
    if (success)
    {
        cave_set_feat(y, x, FEAT_FLOOR);
        msg_print("You have cleared the rubble.");
    }
}
```

---

## Key Code Locations for Terrain Effects

| File | Function | Purpose |
|------|----------|---------|
| src/cmd1.c | move_player() | Movement handling, trap triggering |
| src/cmd1.c | handle_trap() | Trap effect processing (switch statement) |
| src/cmd1.c | py_attack_*() | Combat calculations |
| src/cmd2.c | do_cmd_disarm() | Disarming/interacting with terrain |
| src/cmd2.c | do_cmd_tunnel() | Tunneling through terrain |
| src/melee2.c | process_move() | Monster movement and terrain effects |
| src/xtra1.c | prt_terrain() | Status bar terrain display |
| src/cave.c | map_info() | Visual rendering |
| src/dungeon.c | process_player() | Per-turn terrain effects |

---

## Flags and Macros

### Cave Info Flags (cave_info[y][x])
```c
CAVE_MARK    0x0001  // Memorized
CAVE_GLOW    0x0002  // Self-illuminating
CAVE_ICKY    0x0004  // Vault (no teleport)
CAVE_ROOM    0x0008  // Part of a room
CAVE_SEEN    0x0010  // Currently visible
CAVE_VIEW    0x0020  // In line of sight
CAVE_WALL    0x0080  // Wall (blocks movement)
CAVE_HIDDEN  0x0100  // Hidden trap/feature
```

### Terrain Check Macros
```c
cave_floor_bold(Y, X)     // NOT a wall
cave_wall_bold(Y, X)      // IS a wall
cave_passable(Y, X)       // Can move through
cave_trap_bold(Y, X)      // Has a trap
cave_pit_bold(Y, X)       // Is a pit trap
```

---

## Implementation Recommendations for New Terrain

### Poison Stream (FEAT_POISON_STREAM)
- Model after FEAT_TRAP_ACID handling
- Apply poison on entry (not each turn)
- Check for poison resistance
- Add to prt_terrain() display

### Vine Floor (FEAT_VINE_FLOOR)
- Model after FEAT_TRAP_WEB (simpler version)
- Increase movement cost (not full block)
- No combat penalty (unlike web)
- Maybe slow monsters too

### Tangled Roots (FEAT_TANGLED_ROOTS)
- Set as wall-type (CAVE_WALL flag)
- But allow projectiles (like glass/transparent wall)
- Visual only for combat purposes

### Sunlight Patch (FEAT_SUNLIGHT_PATCH)
- Model after existing FEAT_SUNLIGHT
- Already implemented, can reuse or extend

---

## Movement Cost System

Current movement uses a simple turn system. For slowed movement:

**Option 1**: Extra energy cost
```c
// In move_player() or energy handling
if (cave_feat[y][x] == FEAT_VINE_FLOOR)
{
    p_ptr->energy_use += 50;  // +50% movement cost
}
```

**Option 2**: Require multiple turns
- More complex, less recommended

---

## Monster Handling

Monsters should also be affected by terrain. Key location: src/melee2.c

```c
// In monster movement
if (cave_feat[ny][nx] == FEAT_VINE_FLOOR)
{
    // Slow monster movement
}

if (cave_feat[ny][nx] == FEAT_POISON_STREAM)
{
    // Poison monster (if not resistant)
}
```

---

## Summary

Terrain effects in SIL-Q follow a consistent pattern:
1. Define in terrain.txt and defines.h
2. Add checks in movement code (cmd1.c, melee2.c)
3. Add UI display in prt_terrain() (xtra1.c)
4. Add special handling in handle_trap() or similar switches
5. Consider both player and monster effects
