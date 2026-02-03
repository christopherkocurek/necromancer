/**
 * NecroTestView.h
 *
 * Test view for Phase 1 verification.
 * Renders a static grid of tiles to verify the NecroTileRenderer works.
 *
 * This is a temporary test harness - will be replaced by NecroMapViewport in Phase 3.
 */

#import <Cocoa/Cocoa.h>

@class NecroTileRenderer;

NS_ASSUME_NONNULL_BEGIN

@interface NecroTestView : NSView

/** The tile renderer to use */
@property (nonatomic, strong, nullable) NecroTileRenderer *tileRenderer;

/** Current zoom level (tile display size in pixels) */
@property (nonatomic) NSInteger zoomLevel;

/**
 * Initialize with a tile renderer.
 */
- (instancetype)initWithFrame:(NSRect)frame
                 tileRenderer:(NecroTileRenderer *)renderer;

/**
 * Force a redraw of the tile grid.
 */
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
