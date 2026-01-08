# Threat Indicator Escalation Behavior

## Base Behavior: Static Per-Layer

The default threat level is determined purely by current depth:

```
Depth 1-3   (50-150ft)   -> LOW
Depth 4-6   (150-300ft)  -> GUARDED
Depth 7-9   (300-450ft)  -> ELEVATED
Depth 10-12 (450-600ft)  -> HIGH
Depth 13-15 (600-750ft)  -> SEVERE
Depth 16-18 (750-900ft)  -> CRITICAL
Depth 19-20 (900-1000ft) -> DOOM
```

This is simple, predictable, and matches the layer-based dungeon design.

## Layer Transition Effects

When the player descends to a new layer (crosses a threshold):

1. **Visual Flash**: Threat indicator flashes 3 times
2. **Color Pulse**: Brief pulse to white then back to threat color
3. **Optional Sound**: A tone or chime (if audio enabled)

Implementation: Set a `threat_flash_counter` that decrements each turn.

```c
if (threat_flash_counter > 0)
{
    /* Alternate between white and threat color */
    color = (threat_flash_counter % 2) ? TERM_WHITE : threat_color;
    threat_flash_counter--;
}
```

## Pursuit Mode Override

When `p_ptr->on_the_run == TRUE` (player has Ring + Key and escaped throne room):

**Behavior**:
- Threat level forced to maximum: "HUNTED!"
- Color: Alternating TERM_L_RED and TERM_WHITE (flashing)
- Overrides all other threat calculations
- Persists until player escapes or dies

**Visual**:
```
Normal:  Threat:HIGH   (static light red)
Pursuit: Threat:HUNTED! (flashing red/white)
```

## Dynamic Adjustment (NOT Recommended for V1)

Future enhancement possibilities:
- Increase threat when powerful uniques nearby
- Decrease when floor is cleared of enemies
- Spike during ambush events

For Alpha 0.4.2, keep it simple: static per-layer + pursuit override.

## State Machine

```
                    +-------------+
                    |   NORMAL    |
                    | (per-layer) |
                    +------+------+
                           |
            player descends/ascends
                           |
                    +------v------+
                    |   FLASH     |
                    | (3 turns)   |
                    +------+------+
                           |
                    counter hits 0
                           |
                    +------v------+
                    |   NORMAL    |
                    +------+------+
                           |
              p_ptr->on_the_run = TRUE
                           |
                    +------v------+
                    |   HUNTED    |
                    | (flashing)  |
                    +-------------+
```

## Implementation Constants

```c
#define THREAT_FLASH_DURATION 6  /* 3 flashes = 6 state changes */
#define THREAT_PURSUIT_FLASH  2  /* Flash every 2 turns in pursuit */
```
