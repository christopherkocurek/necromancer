# Tile Rendering Fix - Ralph Loop Prompt

## Branch
`fix/tile-rendering-clean` (clean state from origin/linux)

## Goal
Make 64x64 Necromancer tiles work with the existing rendering system by using simple font-based cell sizing and letting Core Graphics scale tiles to fit.

## Background

This game (The Necromancer) is forked from Sil-Q, an Angband variant. The Cocoa frontend uses a terminal-style grid where:
- The entire screen is a grid of uniform cells (cols × rows)
- Cell size is determined by font metrics (`tileSize` property)
- When graphics are enabled, tiles are drawn into these cells
- Core Graphics automatically scales source images to fit destination rects

The game has three graphics modes:
1. **None (ASCII)** - Text only
2. **Original 16x16** - 16x16 pixel tiles
3. **Necromancer 64x64** - 64x64 pixel tiles (new, not working)

The 16x16 mode works because tiles are scaled from 16x16 to ~13px cells.
The 64x64 mode should work the same way - tiles scaled from 64x64 to ~13px cells.

## The Problem

Previous attempts tried to make 64x64 cells for the map while keeping 13px cells for text. This is fundamentally incompatible with Angband's uniform grid architecture. The solution is simpler: keep uniform font-based cells and let tiles scale.

## Files to Modify

1. `src/main-cocoa.m` - Main rendering code
2. `src/Makefile.cocoa` - Add 64x64 tileset to install
3. `src/defines.h` - Already has `GRAPHICS_NECROMANCER_64` defined

## Implementation Steps

### Step 1: Verify defines.h has the graphics constant
Check that `GRAPHICS_NECROMANCER_64` is defined (value 4).

### Step 2: Update Makefile.cocoa
Add this line after the 16x16_microchasm.png copy (around line 135):
```make
@cp ../lib/xtra/graf/64x64_necromancer.png $(APPRES)/lib/xtra/graf
```

### Step 3: In main-cocoa.m, ensure these things are correct:

#### 3a. The graphics loading code (around line 2900-2930)
There should be a case for `GRAPHICS_NECROMANCER_64` that:
- Loads `64x64_necromancer.png` from the graf directory
- Sets `pict_cell_width = 64` and `pict_cell_height = 64`

#### 3b. Cell sizing uses ONLY font-based tileSize
Search for any methods like `cellSize`, `effectiveCellSize`, `textCellSize`, `tileCellSize` and REMOVE them.

The following methods should use `self.tileSize` directly (NOT any zoom or tile-based sizing):
- `baseSize` - should be: `self.cols * self.tileSize.width`, `self.rows * self.tileSize.height`
- `rectInImageForTileAtX:Y:` - should use `self.tileSize` for positioning and dimensions
- `resizeTerminalWithContentRect:saveToDefaults:` - should use `self.tileSize`
- `constrainWindowSize:` - should use `self.tileSize`

#### 3c. Remove any SIDEBAR_COLS or hybrid cell logic
Delete any code that tries to use different cell sizes for different screen regions.

#### 3d. Remove any zoom-related code
Delete:
- `tile_zoom_level` variable
- `get_tile_zoom_scale()` function
- `AngbandTileZoomDefaultsKey` constant
- `setTileZoom:` method
- `prepareTileZoomMenu` method
- `handle_tile_zoom_change()` function
- Any menu validation for zoom

### Step 4: Verify tile rendering uses Core Graphics scaling

In `Term_pict_cocoa` or `draw_image_tile`, verify that:
- Source rect uses `graf_width` × `graf_height` (64×64 for the source tile)
- Destination rect uses cell size from `rectInImageForTileAtX:Y:` (font-based, ~13×13)
- Core Graphics handles the scaling automatically

The `draw_image_tile` function should look something like:
```objc
static void draw_image_tile(
    NSGraphicsContext *nsContext,
    CGContextRef ctx,
    CGImageRef image,
    NSRect srcRect,    // 64x64 from tileset
    NSRect dstRect,    // 13x13 cell on screen
    NSCompositingOperation
) {
    // CGContextDrawImage scales automatically
}
```

### Step 5: Graphics menu should have Necromancer 64x64 option

In `menuNeedsUpdate:` or wherever the Graphics menu is built, ensure there's an item:
- Title: "Necromancer 64x64"
- Tag: `GRAPHICS_NECROMANCER_64`

## Testing

After building (`make -f Makefile.cocoa clean && make -f Makefile.cocoa install`):

1. Launch game
2. Settings → Graphics → None (ASCII) - Text should render normally
3. Settings → Graphics → Original 16x16 - Tiles should display, scaled to font size
4. Settings → Graphics → Necromancer 64x64 - Tiles should display, scaled to font size
5. Sidebar text should be readable in all modes
6. Window resize should work in all modes

## Reference

The working sil-q implementation is at:
`/Users/christopherkocurek/dev/active/games/sil-q/src/main-cocoa.m`

Key methods to reference:
- `baseSize` (around line 1734)
- `rectInImageForTileAtX:Y:` (around line 2174)
- `Term_pict_cocoa` for tile rendering

## Success Criteria

- All three graphics modes work
- Text is always at normal font spacing
- Tiles are scaled to fit font-sized cells (they will appear small, ~13px)
- No crashes or rendering artifacts
- Window resize works properly

## Notes

The 64x64 tiles will appear small (scaled to ~13px) but this is CORRECT behavior.
If larger tiles are desired in the future, that requires either:
1. A larger base font
2. A complete rewrite of the rendering architecture to separate text and tile regions

Do NOT attempt hybrid cell sizing - it doesn't work with Angband's architecture.
