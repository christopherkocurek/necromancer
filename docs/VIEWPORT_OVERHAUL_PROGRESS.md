# Viewport Overhaul Progress

## Phase 1: Core Tile Rendering - COMPLETE

### Created Files
- `src/cocoa/NecroTileRenderer.h` - Tile renderer header
- `src/cocoa/NecroTileRenderer.m` - Tile renderer implementation
- `src/cocoa/NecroTestView.h` - Test view header
- `src/cocoa/NecroTestView.m` - Test view implementation

### Modified Files
- `src/Makefile.cocoa` - Added new source files to build
- `src/main-cocoa.m` - Added imports and test window function

### Features Implemented
1. **NecroTileRenderer**:
   - Loads 64x64 tileset from PNG file
   - Extracts individual tiles via `CGImageCreateWithImageInRect`
   - Caches extracted tiles for performance
   - Draws tiles at any zoom level (32/64/128px)
   - Handles coordinate conversion from PRF format (0x80 offset)

2. **NecroTestView**:
   - Displays test grid of tiles from multiple rows
   - Zoom controls (+/- keys)
   - Cache statistics display
   - Verifies tiles render at native 64px size

3. **Integration**:
   - Test window accessible via Graphics > "Test Tile Renderer..." (Cmd+Shift+T)
   - Tileset path correctly resolved from ANGBAND_DIR_XTRA

### How to Test
1. Launch Necromancer.app
2. Go to Graphics menu
3. Click "Test Tile Renderer..." or press Cmd+Shift+T
4. Verify tiles display at 64px
5. Press + to zoom in (128px)
6. Press - to zoom out (32px)
7. Press R to clear cache and refresh

### Next Steps (Phase 2)
- Create NecroGameBridge to access game state
- Query map_info() for terrain at each (y,x)
- Translate attr/char to tile row/col
- Verify terrain matches actual game state

---

## Phase 2: Game State Bridge - COMPLETE

### Created Files
- `src/cocoa/NecroGameBridge.h` - Bridge header
- `src/cocoa/NecroGameBridge.m` - Bridge implementation

### Modified Files
- `src/Makefile.cocoa` - Added NecroGameBridge.o
- `src/cocoa/NecroTestView.m` - Added game map rendering mode

### Features Implemented
1. **NecroGameBridge**:
   - Wraps `map_info()` to get tile data
   - Converts attr/char (0x80 offset) to tile row/col
   - Provides player position, HP, SP
   - Returns map dimensions and bounds checking
   - Queries visibility (CAVE_SEEN, CAVE_MARK)

2. **Test View Updates**:
   - Press 'M' to toggle between Test Grid and Game Map modes
   - Game Map mode shows actual dungeon centered on player
   - Visibility dimming for memorized but not visible tiles
   - Green border around player position
   - Debug info shows player position and HP

### How to Test
1. Launch game, create/load a character
2. Enable Graphics > Necromancer 64x64
3. Open Graphics > Test Tile Renderer (Cmd+Shift+T)
4. Press 'M' to switch to Game Map mode
5. Tiles should now show actual dungeon content

### Notes
- Requires graphics mode enabled to show game map
- Player must be in dungeon (not at start menu)
- Tiles show correctly if PRF mappings match tileset

## Phase 3: Viewport Management - COMPLETE

### Created Files
- `src/cocoa/NecroMapViewport.h` - Viewport header
- `src/cocoa/NecroMapViewport.m` - Viewport implementation

### Modified Files
- `src/Makefile.cocoa` - Added NecroMapViewport.o
- `src/main-cocoa.m` - Added viewport window function and menu item

### Features Implemented
1. **NecroMapViewport**:
   - Player-centered rendering (viewport always centered on player)
   - Zoom controls: +/- for 32/64/128px tile sizes
   - Look mode: ';' to enter, arrows/hjkl to move cursor, Esc to exit
   - Grid overlay: 'G' to toggle
   - Health bars for monsters (placeholder implementation)
   - Visibility effects (dim memorized, dark unknown)
   - Smooth coordinate conversion (screen <-> map)

2. **Integration**:
   - Graphics > Map Viewport... (Cmd+Shift+M) opens viewport window
   - Shares tile renderer with test window for efficiency

### How to Test
1. Launch game, create/load character
2. Enable Graphics > Necromancer 64x64
3. Open Graphics > Map Viewport (Cmd+Shift+M)
4. Press ';' to enter look mode, arrows to move cursor
5. Press +/- to zoom
6. Press 'G' to toggle grid overlay

### Keyboard Controls
| Key | Action |
|-----|--------|
| +/= | Zoom in |
| -/_ | Zoom out |
| ; | Enter/exit look mode |
| hjkl / arrows | Move look cursor |
| Esc/q | Exit look mode |
| G | Toggle grid overlay |

## Phase 4: UI Integration - PENDING

## Phase 5: Information Layer - PENDING
