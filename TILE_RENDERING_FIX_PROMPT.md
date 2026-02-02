# Map Engine Rewrite - Ralph Loop Prompt

## Branch
`fix/tile-rendering-clean` (clean state from origin/linux)

## Goal
Rewrite the map rendering system to support large 64x64 tiles at NATIVE SIZE while keeping the sidebar text readable. The game must be fun and accessible for players who don't want tiny tiles or ASCII.

## The Problem

Angband's terminal architecture uses a uniform grid where every cell is the same size. This forces a choice:
- Small cells (~13px): Text readable, but 64x64 tiles scaled down to 13px (too small)
- Large cells (64px): Tiles at native size, but text spread out with 64px spacing (unreadable)

## The Solution: Dual-Region Rendering

Separate the screen into two independently-rendered regions:

1. **Sidebar Region** (columns 0-12): Rendered with font-based cell size (~13px)
2. **Map Region** (columns 13+): Rendered with tile-based cell size (64x64)

This requires significant changes to the rendering pipeline.

## Architecture Overview

```
+------------------+----------------------------------------+
|                  |                                        |
|    SIDEBAR       |              MAP AREA                  |
|   (Text cells)   |           (Tile cells)                 |
|    ~13px wide    |            64px wide                   |
|                  |                                        |
|  - Player name   |     [64x64 tiles rendered at          |
|  - Stats         |      native size, showing              |
|  - Health/Spirit |      detailed dungeon graphics]        |
|  - Equipment     |                                        |
|                  |                                        |
+------------------+----------------------------------------+
     13 columns              Variable columns
     ~169px wide             Based on window size
```

## Implementation Plan

### Phase 1: Create Separate Layer for Map Tiles

Instead of rendering everything to a single `angbandLayer`, create:
- `textLayer` - For sidebar and message areas (font-based sizing)
- `mapLayer` - For the dungeon map (tile-based sizing)

### Phase 2: Modify Cell Positioning

Create a new method `absoluteRectForTileAtX:Y:` that:
- For columns 0-12: Returns rect at `x * textCellWidth`
- For columns 13+: Returns rect at `sidebarWidth + (x-13) * tileCellWidth`

### Phase 3: Split Rendering in Term_xtra_cocoa_fresh

The main rendering function needs to:
1. Render text changes (CELL_CHANGE_TEXT, CELL_CHANGE_WIPE) to textLayer using font metrics
2. Render tile changes (CELL_CHANGE_TILE) to mapLayer using tile dimensions
3. Composite both layers for final display

### Phase 4: Handle Window Sizing

Window size calculations must account for:
- Sidebar: `SIDEBAR_COLS * textCellSize.width`
- Map: `mapCols * tileCellSize.width`
- Total width: sidebar + map
- Height: `rows * MAX(textCellSize.height, tileCellSize.height)`

### Phase 5: Handle Row Heights

Two options for row heights:
- **Option A**: Uniform row height = MAX(text, tile) - Simpler but wastes vertical space
- **Option B**: Text rows at text height, map rows at tile height - Complex, may cause alignment issues

Recommend Option A for initial implementation.

## Key Files to Modify

### src/main-cocoa.m

#### Constants to Add (near top)
```objc
#define SIDEBAR_COLS 13
#define MAP_START_COL 13
```

#### New Properties in AngbandContext
```objc
@property CGLayerRef mapLayer;      // Layer for tile rendering
@property (readonly) NSSize mapTileSize;  // Size of tiles (64x64)
```

#### New Methods to Add
```objc
// Returns the pixel rect for a cell, accounting for dual-region layout
- (NSRect)absoluteRectForCellAtX:(int)x Y:(int)y;

// Returns cell size for a given column (text size for sidebar, tile size for map)
- (NSSize)cellSizeForColumn:(int)x;

// Sidebar width in pixels
- (CGFloat)sidebarPixelWidth;
```

#### Methods to Modify
- `baseSize` - Calculate width as sidebar + map widths
- `updateImage` - Create/manage both layers
- `rectInImageForTileAtX:Y:` - Use absolute positioning
- `drawRect:inView:` - Composite both layers
- `resizeTerminalWithContentRect:` - Handle hybrid widths
- `constrainWindowSize:` - Handle hybrid widths

#### Term_xtra_cocoa_fresh Modifications
The tile rendering section (CELL_CHANGE_TILE case) must:
- Calculate destination rect at tile size (64x64)
- Position correctly in the map region

The text rendering section must:
- Calculate destination rect at text size
- Position correctly (sidebar uses text size, map area uses tile size)

### src/Makefile.cocoa
Add the 64x64 tileset to install:
```make
@cp ../lib/xtra/graf/64x64_necromancer.png $(APPRES)/lib/xtra/graf
```

## Detailed Implementation Steps

### Step 1: Add mapTileSize property
```objc
// In AngbandContext interface
@property (readonly) NSSize mapTileSize;

// In implementation, add getter
- (NSSize)mapTileSize {
    if (graphics_are_enabled() && pict_cell_width > 0 && pict_cell_height > 0) {
        return NSMakeSize(pict_cell_width, pict_cell_height);
    }
    return self.tileSize; // Fallback to text size
}
```

### Step 2: Add absolute positioning method
```objc
- (NSRect)absoluteRectForCellAtX:(int)x Y:(int)y {
    NSSize textCell = self.tileSize;
    NSSize mapCell = [self mapTileSize];
    CGFloat rowHeight = MAX(textCell.height, mapCell.height);

    CGFloat xPos;
    CGFloat cellWidth;

    if (x < SIDEBAR_COLS) {
        // Sidebar: text-sized cells
        xPos = x * textCell.width;
        cellWidth = textCell.width;
    } else {
        // Map: tile-sized cells
        CGFloat sidebarWidth = SIDEBAR_COLS * textCell.width;
        xPos = sidebarWidth + (x - SIDEBAR_COLS) * mapCell.width;
        cellWidth = mapCell.width;
    }

    return NSMakeRect(
        xPos + self.borderSize.width,
        y * rowHeight + self.borderSize.height,
        cellWidth,
        rowHeight
    );
}
```

### Step 3: Update baseSize
```objc
- (NSSize)baseSize {
    NSSize textCell = self.tileSize;
    NSSize mapCell = [self mapTileSize];

    int sidebarCols = MIN(SIDEBAR_COLS, self.cols);
    int mapCols = MAX(0, self.cols - SIDEBAR_COLS);

    CGFloat width = sidebarCols * textCell.width + mapCols * mapCell.width;
    CGFloat rowHeight = MAX(textCell.height, mapCell.height);
    CGFloat height = self.rows * rowHeight;

    return NSMakeSize(
        floor(width + 2 * self.borderSize.width),
        floor(height + 2 * self.borderSize.height)
    );
}
```

### Step 4: Update rectInImageForTileAtX:Y:
Replace with call to absoluteRectForCellAtX:Y:
```objc
- (NSRect)rectInImageForTileAtX:(int)x Y:(int)y {
    return [self absoluteRectForCellAtX:x Y:y];
}
```

### Step 5: Update Term_xtra_cocoa_fresh tile rendering

In the CELL_CHANGE_TILE case, the destination rect comes from rectInImageForTileAtX:Y: which now returns the correct 64x64 rect for map cells.

The source rect uses graf_width/graf_height (64x64).
The destination rect uses the absolute positioning (64x64 for map area).
No scaling needed - 1:1 rendering.

### Step 6: Update text rendering

Text in the sidebar renders at text cell size.
Text in the map area (rare, but possible) renders at tile cell size - the font will appear small relative to the cell, which is fine.

### Step 7: Update window resize logic
```objc
- (void)resizeTerminalWithContentRect:(NSRect)contentRect saveToDefaults:(BOOL)saveToDefaults {
    NSSize textCell = self.tileSize;
    NSSize mapCell = [self mapTileSize];
    CGFloat rowHeight = MAX(textCell.height, mapCell.height);

    CGFloat availWidth = contentRect.size.width - 2 * self.borderSize.width;
    CGFloat sidebarWidth = SIDEBAR_COLS * textCell.width;

    int newCols;
    if (availWidth <= sidebarWidth) {
        newCols = (int)ceil(availWidth / textCell.width);
    } else {
        int mapCols = (int)floor((availWidth - sidebarWidth) / mapCell.width);
        newCols = SIDEBAR_COLS + mapCols;
    }

    int newRows = (int)floor((contentRect.size.height - 2 * self.borderSize.height) / rowHeight);

    // ... rest of resize logic
}
```

## Testing Checklist

1. [ ] ASCII mode: Text renders correctly, normal spacing
2. [ ] 16x16 mode: Tiles render, sidebar text readable
3. [ ] 64x64 mode: Tiles render at NATIVE 64x64 size, sidebar text readable
4. [ ] Window resize works in all modes
5. [ ] Mouse clicks map to correct cells (if mouse is enabled)
6. [ ] No visual artifacts at sidebar/map boundary
7. [ ] Messages at top of screen render correctly
8. [ ] Status bar at bottom renders correctly

## Success Criteria

- 64x64 tiles display at full native resolution (detailed, beautiful)
- Sidebar text is normal size and readable
- The game is visually appealing and accessible
- No crashes or rendering glitches
- Players can enjoy the detailed tile art

## Reference Files

- Clean sil-q implementation: `/Users/christopherkocurek/dev/active/games/sil-q/src/main-cocoa.m`
- Current (broken) necromancer: Check git stash or origin/linux
- 64x64 tileset: `/Users/christopherkocurek/dev/active/games/necromancer-linux-port/lib/xtra/graf/64x64_necromancer.png`

## Notes

- This is a significant architectural change - take it step by step
- Test frequently during implementation
- The key insight is ABSOLUTE POSITIONING - each cell's pixel position depends on which region it's in
- Don't try to maintain the old uniform-grid assumption - it doesn't work for this use case
