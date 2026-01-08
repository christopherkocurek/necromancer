# Threat Level Indicator - Final Implementation Specification

## Overview

This document consolidates all design decisions for the Tower Threat Level UI indicator feature. It serves as the definitive implementation guide.

## Feature Summary

A color-coded threat indicator displayed in the left sidebar that shows the current danger level based on dungeon depth, with a special "HUNTED!" override during Pursuit Mode.

---

## 1. Display Location

**Position**: Left sidebar, Row 12, Columns 0-12

**Rationale**:
- Between Spirit (Row 11) and Melee stats (Row 13)
- 12 characters width accommodates "Threat:DOOM" format
- Does not affect crowded bottom status bar
- Logical grouping with player resources

**Layout Context**:
```
Row 10: HP:  45:45
Row 11: Spirit:20:20
Row 12: Threat:HIGH   <-- NEW
Row 13: Mel:(+3,2d5)
```

---

## 2. Threat Levels

| Level | Constant | Depth Range | Label | Color |
|-------|----------|-------------|-------|-------|
| 1 | THREAT_LOW | 50-150ft (1-3) | "Low" | TERM_GREEN (5) |
| 2 | THREAT_GUARDED | 150-300ft (4-6) | "Guarded" | TERM_YELLOW (11) |
| 3 | THREAT_ELEVATED | 300-450ft (7-9) | "Elevated" | TERM_ORANGE (3) |
| 4 | THREAT_HIGH | 450-600ft (10-12) | "High" | TERM_L_RED (12) |
| 5 | THREAT_SEVERE | 600-750ft (13-15) | "Severe" | TERM_RED (4) |
| 6 | THREAT_CRITICAL | 750-900ft (16-18) | "Critical" | TERM_UMBER (7) |
| 7 | THREAT_DOOM | 900-1000ft (19-20) | "Doom" | TERM_VIOLET (10) |
| 8 | THREAT_HUNTED | Any (Pursuit) | "HUNTED!" | TERM_L_RED (flash) |

---

## 3. Implementation Details

### 3.1 Constants (defines.h)

```c
/* Threat Level Constants */
#define THREAT_LOW       1
#define THREAT_GUARDED   2
#define THREAT_ELEVATED  3
#define THREAT_HIGH      4
#define THREAT_SEVERE    5
#define THREAT_CRITICAL  6
#define THREAT_DOOM      7
#define THREAT_HUNTED    8

/* Threat Display Row */
#define ROW_THREAT       12
#define COL_THREAT       0

/* Flash Animation */
#define THREAT_FLASH_DURATION 6  /* 3 flashes on layer change */
```

### 3.2 Core Function (xtra1.c)

```c
/*
 * Get current threat level based on depth
 */
static int get_threat_level(void)
{
    /* Pursuit mode override */
    if (p_ptr->on_the_run) return THREAT_HUNTED;

    /* Depth-based threat */
    if (p_ptr->depth <= 3)  return THREAT_LOW;
    if (p_ptr->depth <= 6)  return THREAT_GUARDED;
    if (p_ptr->depth <= 9)  return THREAT_ELEVATED;
    if (p_ptr->depth <= 12) return THREAT_HIGH;
    if (p_ptr->depth <= 15) return THREAT_SEVERE;
    if (p_ptr->depth <= 18) return THREAT_CRITICAL;
    return THREAT_DOOM;
}

/*
 * Get color for threat level
 */
static byte get_threat_color(int threat)
{
    switch (threat)
    {
        case THREAT_LOW:      return TERM_GREEN;
        case THREAT_GUARDED:  return TERM_YELLOW;
        case THREAT_ELEVATED: return TERM_ORANGE;
        case THREAT_HIGH:     return TERM_L_RED;
        case THREAT_SEVERE:   return TERM_RED;
        case THREAT_CRITICAL: return TERM_UMBER;
        case THREAT_DOOM:     return TERM_VIOLET;
        case THREAT_HUNTED:   return TERM_L_RED;
        default:              return TERM_WHITE;
    }
}

/*
 * Get label for threat level
 */
static cptr get_threat_label(int threat)
{
    switch (threat)
    {
        case THREAT_LOW:      return "Low";
        case THREAT_GUARDED:  return "Guarded";
        case THREAT_ELEVATED: return "Elevated";
        case THREAT_HIGH:     return "High";
        case THREAT_SEVERE:   return "Severe";
        case THREAT_CRITICAL: return "Critical";
        case THREAT_DOOM:     return "Doom";
        case THREAT_HUNTED:   return "HUNTED!";
        default:              return "???";
    }
}

/*
 * Display the threat indicator
 */
static void prt_threat(void)
{
    int threat = get_threat_level();
    byte color = get_threat_color(threat);
    cptr label = get_threat_label(threat);
    char buf[13];

    /* Handle HUNTED flash effect */
    if (threat == THREAT_HUNTED)
    {
        /* Alternate color every other turn */
        if (turn % 2 == 0)
            color = TERM_WHITE;
    }

    /* Format: "Threat:Label" (max 12 chars) */
    strnfmt(buf, sizeof(buf), "Threat:%-5s", label);

    /* Clear the row first */
    put_str("            ", ROW_THREAT, COL_THREAT);

    /* Display with color */
    c_put_str(color, buf, ROW_THREAT, COL_THREAT);
}
```

### 3.3 Integration Points

**In prt_frame_basic() or equivalent redraw function**:
```c
prt_threat();
```

**Redraw flag** (if using PR_* system):
```c
#define PR_THREAT  0x00400000L  /* Or next available bit */
```

---

## 4. Behavior Summary

### Normal Operation
- Threat level determined by p_ptr->depth
- Static color display
- Updates on depth change

### Layer Transition (Future Enhancement)
- Brief flash animation when crossing layer boundaries
- Not required for Alpha 0.4.2

### Pursuit Mode
- Triggered when p_ptr->on_the_run == TRUE
- Forces THREAT_HUNTED level
- Flashing red/white animation
- Persists until escape or death

---

## 5. Testing Checklist

- [ ] Verify display at Row 12, fits within 12 columns
- [ ] Test all 7 threat levels at appropriate depths
- [ ] Confirm colors match specification
- [ ] Test Pursuit Mode override and flashing
- [ ] Verify no overlap with adjacent UI elements
- [ ] Test on minimum terminal size (80x24)

---

## 6. File Changes Required

| File | Changes |
|------|---------|
| src/defines.h | Add THREAT_* constants, ROW_THREAT, COL_THREAT |
| src/xtra1.c | Add prt_threat() and helper functions |
| src/xtra1.c | Call prt_threat() in redraw function |

---

## 7. Dependencies

- p_ptr->depth (current dungeon depth)
- p_ptr->on_the_run (Pursuit Mode flag)
- turn (game turn counter for flash animation)
- TERM_* color constants (already exist)

---

## Approved Design

- **Location**: Left sidebar Row 12
- **Format**: "Threat:Label" with color
- **Levels**: 7 depth-based + 1 Pursuit override
- **Animation**: Flash for HUNTED only (V1)

Ready for implementation.
