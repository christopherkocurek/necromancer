# Intro Animation Code Audit

## Current Startup Flow

### Entry Points
- **macOS**: `main-cocoa.m:5268` → `applicationDidFinishLaunching` → `beginGame` → `init_angband()` → `play_game()`
- **Linux/Windows**: `main.c:359` → `init_angband()` → `play_game()`

### Key Function: `display_introduction()`

**Location**: `src/init2.c:1539-1567`

```c
extern void display_introduction(void)
{
    Term_clear();
    Term_putstr(14, 3, -1, TERM_L_BLUE, "  In the shadows of Mirkwood's eaves...");
    // ... more text lines ...
    Term_fresh();
}
```

**Called from**: `init_angband()` at line 1626 - FIRST display operation

### Current Flow
1. `init_angband()` called
2. `display_introduction()` shows static text
3. Initialization continues (loading data files, etc.)
4. `initial_menu()` shows main menu

## Insertion Point for Intro Animation

**Best approach**: Replace or enhance `display_introduction()` in `src/init2.c`

Option A: Create new `play_intro_animation()` function, call it from `display_introduction()`
Option B: Replace `display_introduction()` entirely with animated version

**Recommendation**: Option A - keeps existing code intact, adds animation before static text

## Display API Reference

### Core Functions
| Function | Purpose |
|----------|---------|
| `Term_clear()` | Clear entire screen |
| `Term_putstr(x, y, len, attr, str)` | Put string at position with color |
| `c_put_str(attr, str, row, col)` | Put colored string (alternative) |
| `Term_fresh()` | Refresh/flush display |
| `Term_xtra(TERM_XTRA_DELAY, msec)` | Delay in milliseconds |
| `screen_save()` / `screen_load()` | Save/restore screen |
| `inkey()` | Get keypress (returns immediately if key pressed) |

### Color Constants (from defines.h)
- `TERM_DARK` (0) - Black
- `TERM_WHITE` (1) - White
- `TERM_SLATE` (2) - Gray
- `TERM_ORANGE` (3) - Orange
- `TERM_RED` (4) - Red
- `TERM_GREEN` (5) - Green
- `TERM_BLUE` (6) - Blue
- `TERM_UMBER` (7) - Brown
- `TERM_L_DARK` (8) - Dark gray
- `TERM_L_WHITE` (9) - Light gray
- `TERM_VIOLET` (10) - Purple
- `TERM_YELLOW` (11) - Yellow
- `TERM_L_RED` (12) - Light red
- `TERM_L_GREEN` (13) - Light green
- `TERM_L_BLUE` (14) - Light blue
- `TERM_L_UMBER` (15) - Light brown

### Screen Dimensions
- Standard: 80 columns x 24 rows
- Some terminals may be larger, but 80x24 is safe minimum

## Existing Animation Example

**Function**: `pause_with_text()` in `src/xtra2.c:5454`

Shows text line-by-line with 50ms delay between lines. Key pattern:
```c
while (strlen(desc[i]) != 0) {
    c_put_str(TERM_WHITE, desc[i], row + i, col);
    Term_xtra(TERM_XTRA_DELAY, 50);  // 50ms delay
    Term_fresh();
    i++;
}
```

## Skip Detection

To allow skipping with any keypress:
```c
// Non-blocking key check
if (Term_inkey(&ch, FALSE, FALSE) == 0) {
    // Key was pressed - skip animation
    return;
}
```

Or use `inkey()` with timeout handling.

## Files to Modify

1. `src/init2.c` - Add intro animation function, modify `display_introduction()`
2. `src/externs.h` - Declare new function if needed
3. Possibly new `src/intro.c` for cleaner organization
