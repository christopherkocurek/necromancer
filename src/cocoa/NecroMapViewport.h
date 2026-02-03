/**
 * NecroMapViewport.h
 *
 * The main map viewport for The Necromancer.
 * Renders 64x64 tiles at native resolution with player-centered scrolling.
 *
 * DESIGN DECISIONS:
 * 1. Always centered on player (smooth scrolling when player moves)
 * 2. Zoom levels: 32px (overview), 64px (normal), 128px (detail)
 * 3. Separate from text rendering (messages, stats are handled elsewhere)
 * 4. Provides look mode (cursor to inspect tiles)
 *
 * Created for Phase 3 of viewport overhaul.
 */

#import <Cocoa/Cocoa.h>

@class NecroTileRenderer;

NS_ASSUME_NONNULL_BEGIN

/**
 * Zoom levels for the map viewport.
 */
typedef NS_ENUM(NSInteger, NecroZoomLevel) {
    NecroZoomLevel32 = 32,   // Overview - see more, smaller tiles
    NecroZoomLevel64 = 64,   // Normal - native tile size
    NecroZoomLevel128 = 128  // Detail - larger tiles for inspection
};

/**
 * NecroMapViewport
 *
 * The main game map display. Renders tiles from the tileset
 * based on game state, centered on the player.
 */
@interface NecroMapViewport : NSView

#pragma mark - Properties

/** The tile renderer used to draw map tiles */
@property (nonatomic, strong, nullable) NecroTileRenderer *tileRenderer;

/** Current zoom level (tile display size in pixels) */
@property (nonatomic) NecroZoomLevel zoomLevel;

/** Whether look mode is active (cursor for tile inspection) */
@property (nonatomic, readonly) BOOL isLookModeActive;

/** Look mode cursor position (map coordinates) */
@property (nonatomic, readonly) int lookCursorY;
@property (nonatomic, readonly) int lookCursorX;

/** Whether to show monster health bars */
@property (nonatomic) BOOL showHealthBars;

/** Whether to show a grid overlay */
@property (nonatomic) BOOL showGrid;

#pragma mark - Initialization

/**
 * Initialize with a tile renderer.
 */
- (instancetype)initWithFrame:(NSRect)frame
                 tileRenderer:(NecroTileRenderer *)renderer;

#pragma mark - Viewport Control

/**
 * Center the viewport on the player.
 * Called automatically each frame, but can be called manually.
 */
- (void)centerOnPlayer;

/**
 * Zoom in one level (32 -> 64 -> 128).
 */
- (void)zoomIn;

/**
 * Zoom out one level (128 -> 64 -> 32).
 */
- (void)zoomOut;

/**
 * Set zoom to a specific level.
 */
- (void)setZoomLevel:(NecroZoomLevel)level;

#pragma mark - Look Mode

/**
 * Enter look mode with cursor at player position.
 */
- (void)enterLookMode;

/**
 * Exit look mode.
 */
- (void)exitLookMode;

/**
 * Move the look cursor by delta tiles.
 */
- (void)moveLookCursorByDeltaY:(int)dy deltaX:(int)dx;

/**
 * Get description of what's at the look cursor position.
 */
- (nullable NSString *)lookCursorDescription;

#pragma mark - Coordinate Conversion

/**
 * Convert screen coordinates to map tile coordinates.
 *
 * @param screenPoint Point in view coordinates
 * @param outY Pointer to store map row
 * @param outX Pointer to store map column
 * @return YES if point is over a valid map tile
 */
- (BOOL)screenPointToMapY:(int *)outY X:(int *)outX fromPoint:(NSPoint)screenPoint;

/**
 * Convert map coordinates to screen position.
 *
 * @param mapY Map row
 * @param mapX Map column
 * @return Top-left corner of tile in view coordinates, or NSZeroPoint if off-screen
 */
- (NSPoint)mapToScreenY:(int)mapY X:(int)mapX;

#pragma mark - Rendering

/**
 * Request a redraw of the entire viewport.
 */
- (void)refresh;

/**
 * Request a redraw of a specific map region.
 */
- (void)refreshMapRegionFromY:(int)y1 X:(int)x1 toY:(int)y2 X:(int)x2;

@end

NS_ASSUME_NONNULL_END
