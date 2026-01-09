# Death Screen Audit - The Necromancer

**Date:** 2026-01-10
**Version:** Beta 1.0.1

## Current Death Flow

### Entry Point
- `files.c:close_game_aux()` (line 4872) - Main death handler

### Current Sequence
1. Play death/victory music (added by music PRD)
2. Save dead player
3. Get death time
4. Create and enter high score
5. Clear hallucination/rage
6. Auto-dump character file
7. **Display tombstone** via `print_tomb()` (line 4936)
8. Present menu with options loop (`final_menu()`)

### Current Tombstone (print_tomb)
Location: `files.c:3378-3396`

Very minimal:
- "You have escaped" or "You have been slain" (line 2)
- Calls `display_single_score()` for basic info
- Shows mini-screenshot of death location

### Final Menu Options
1. View scores (`top_twenty()`)
2. Examine items (`death_examine()`)
3. View dungeon (lights level, allows looking)
4. View final messages
5. View character sheet (`show_info()`)
6. Start new character
7. Exit game

### Key Functions
| Function | Location | Purpose |
|----------|----------|---------|
| `close_game_aux()` | files.c:4872 | Main death handler |
| `print_tomb()` | files.c:3378 | Display tombstone |
| `display_single_score()` | files.c:3xxx | Show score entry |
| `final_menu()` | files.c:~4800 | Death menu loop |
| `show_info()` | files.c:3401 | Character sheet |
| `death_examine()` | files.c:3449 | Item examination |

### Insertion Points for New Death Animation

**Best insertion point:** After `print_tomb(&the_score);` at line 4936

Proposed new flow:
1. Play death music (already done)
2. Save dead player
3. Get death time
4. Create and enter high score
5. Clear effects
6. Auto-dump character
7. **NEW: Play death animation sequence**
8. **NEW: Show procedural epitaph**
9. **NEW: Show stats recap screen**
10. Present menu loop (modified for new options)

### Screen Size
Standard Angband/Sil terminal: 80 columns x 24 rows

### Color Constants Available
- TERM_WHITE, TERM_RED, TERM_ORANGE, TERM_YELLOW
- TERM_L_BLUE, TERM_L_GREEN, TERM_L_RED
- TERM_DARK, TERM_SLATE, TERM_VIOLET

## Recommendations

1. Create new file `src/death.c` for death sequence code
2. Add header `src/death.h` for declarations
3. Keep existing `final_menu()` functionality but add new entry point
4. Use intro.c animation framework as template
5. Store epitaph strings either embedded or in `lib/edit/epitaphs.txt`
