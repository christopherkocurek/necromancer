# Deep Memory Ability Audit

## Overview

Deep Memory (N:142) is a Lore ability that reveals dungeon layout.

### Ability Definition (ability.txt:665-670)
```
N:142:Deep Memory
I:7:2:2    # Skill 7 (Lore), ability index 2, level requirement 2
D:Drawing on ancestral knowledge, you gradually perceive the layout
D: of your surroundings, sensing passages and chambers nearby.
```

## Song System Overview

### How Songs Work
- Songs are Lore abilities that can be activated as continuous effects
- `p_ptr->song1` = primary song (SNG_* constant)
- `p_ptr->song2` = minor theme (secondary song, requires Woven Themes ability)
- `SNG_NOTHING` (100) = no song active

### Song Constants (defines.h:544-563)
```c
#define SNG_DELVINGS 2      // Deep Memory's song index
#define SNG_NOTHING 100     // No song active
```

### Spirit (Voice) Cost
- Songs drain spirit (csp) each turn
- Deep Memory costs 1 spirit every 3 turns (see spells1.c:5788)
- Song stops automatically when spirit reaches 0 (spells1.c:5698-5710)

## Key Code Locations

### Song Activation/Deactivation
- `change_song()` in spells1.c:5108+ - changes active song
- Called via ability use or toggling

### Song Upkeep (sing() function)
**Location**: spells1.c:5686-5835

```c
void sing(void)
{
    // Abort if out of voice (csp < 1)
    if ((p_ptr->csp < 1) || ...)
    {
        change_song(SNG_NOTHING);  // Stop singing
        return;
    }

    // Process each song's effect
    case SNG_DELVINGS:
        if ((p_ptr->song_duration % 3) == type - 1)
            cost += 1;  // 1 spirit every 3 turns
        sing_song_of_delvings(score);
        break;

    // Pay the cost
    p_ptr->csp -= cost;
}
```

### Delvings Effect (sing_song_of_delvings)
**Location**: spells1.c:5494-5599

- Reveals dungeon layout based on Lore skill score
- Higher score = larger reveal radius
- Reveals walls, floors, doors, secret doors

## Implementation Plan for Ring Curse

### What Needs to Happen
1. When Ring of Thráin is equipped → Start SNG_DELVINGS automatically
2. While Ring is worn → Prevent deactivating SNG_DELVINGS
3. Ring removal (via Remove Curse) → Stop SNG_DELVINGS

### Key Modification Points

1. **Equipment wield** (cmd3.c or object2.c):
   - Check if item is Ring of Thráin
   - Call `change_song(SNG_DELVINGS)` to start the song

2. **Song toggle prevention** (spells1.c change_song):
   - Before allowing song change, check if Ring of Thráin is equipped
   - If so, and trying to stop SNG_DELVINGS, prevent it

3. **Equipment removal** (cmd3.c or spells2.c for Remove Curse):
   - When Ring of Thráin is removed, call `change_song(SNG_NOTHING)`

### Thematic Result
- Player gets permanent dungeon vision (powerful!)
- But spirit drains constantly (1 per 3 turns)
- When spirit hits 0, player is weakened (no casting, etc.)
- Only Remove Curse can end the drain

---

*Audit completed for PREP-001*
