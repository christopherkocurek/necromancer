# UI Audit - Threat Level Indicator Placement

## Current UI Layout (defines.h)

### Left Sidebar (Columns 0-12)
| Row | Element | Columns | Notes |
|-----|---------|---------|-------|
| 1 | ROW_NAME | 0-12 | Race/class name |
| 2 | ROW_MORTAL_WOUND | 0 | Critical health warning |
| 3-7 | ROW_STAT | 0-12 | STR, DEX, CON, GRA stats |
| 8 | ROW_EXP | 0-12 | Experience display |
| 10 | ROW_HP | 0-12 | Health points |
| 11 | ROW_SP | 0-12 | Spirit points |
| 13 | ROW_EQUIPPY/MEL | 0-12 | Equipment or melee stats |
| 14 | ROW_ARC | 0-12 | Archery stats |
| 15 | ROW_EVN | 0-12 | Evasion stats |
| 17 | ROW_RESIST/INFO | 0-12 | Resistances or monster health |
| 20 | ROW_CUT/POISONED | 0 | Bleeding/poison status |
| 21 | ROW_SONG | 0 | Current song |
| 24 | ROW_STEALTH | 0 | Stealth mode indicator |

### Map Area
- Starts at ROW_MAP (1), COL_MAP (13)
- SCREEN_HGT = Term->hgt - ROW_MAP - 1
- SCREEN_WID = (Term->wid - COL_MAP - 1)

### Bottom Status Bar (Term->hgt - 1)
| Column | Element | Width | Content |
|--------|---------|-------|---------|
| 0 | HUNGRY | ~8 | "Starving"/"Weak"/"Hungry"/"Full" |
| 9 | BLIND | ~5 | "Blind" |
| 15 | CONFUSED | ~8 | "Confused" |
| 24 | STUN | ~10 | Stun level |
| 36 | AFRAID | ~6 | "Afraid" |
| 43 | STATE | ~12 | Rest/Search/Study state |
| 56 | SPEED | ~4 | "Slow"/"Fast" |
| 61 | TERRAIN | ~10 | "Web"/"Pit"/"Sunlight" |
| 72 | DEPTH | 7 | "NNNNft" or "Surface" |

## Available Placement Options

### Option A: Between TERRAIN and DEPTH (Bottom Bar)
- Position: Column 67-71 (5 chars available)
- Pros: Natural fit near depth display
- Cons: Limited width, may overlap with terrain on narrow terminals

### Option B: Replace/Expand Depth Display
- Position: Column 65-79 (extend depth area)
- Format: "THREAT: 500ft" or "HIGH 500ft"
- Pros: Consolidated location info
- Cons: Changes existing layout

### Option C: Left Sidebar Row 9 (Currently Empty)
- Position: Row 9, Columns 0-12
- Pros: Dedicated space, doesn't affect bottom bar
- Cons: Between EXP and HP - disrupts visual flow

### Option D: Left Sidebar Row 12 (Currently Empty)
- Position: Row 12, Columns 0-12
- Pros: Between SP and combat stats - logical grouping
- Cons: None significant

### Option E: Left Sidebar Row 16 (Currently Empty)
- Position: Row 16, Columns 0-12
- Pros: Below combat stats, before conditions
- Cons: May feel disconnected

## Recommendation

**Option D (Row 12)** is the best choice:
- Provides 12 characters width for "THREAT: HIGH" or similar
- Located between Spirit and Combat stats - logical position
- Doesn't affect the crowded bottom status bar
- Can use color coding without overlap concerns

## Color Constants Available (defines.h)
```c
TERM_DARK     (0)  - Black
TERM_WHITE    (1)  - White
TERM_SLATE    (2)  - Gray
TERM_ORANGE   (3)  - Orange
TERM_RED      (4)  - Red
TERM_GREEN    (5)  - Green
TERM_BLUE     (6)  - Blue
TERM_UMBER    (7)  - Brown
TERM_L_DARK   (8)  - Dark gray
TERM_L_WHITE  (9)  - Light gray
TERM_VIOLET   (10) - Purple
TERM_YELLOW   (11) - Yellow
TERM_L_RED    (12) - Light red
TERM_L_GREEN  (13) - Light green
TERM_L_BLUE   (14) - Light blue
TERM_L_UMBER  (15) - Light brown
```

## Relevant Source Files
- src/defines.h - ROW_*/COL_* constants
- src/xtra1.c - prt_* display functions
- src/dungeon.c - Main game loop, redraw triggers
