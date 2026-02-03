/**
 * NecroTileRenderer.h
 *
 * Tile renderer for The Necromancer roguelike.
 * Loads 64x64 tileset and renders tiles at native resolution.
 *
 * DESIGN DECISIONS:
 * 1. Tiles render at native 64x64 (or scaled zoom level), NOT font-cell size
 * 2. Tile extraction uses CGImageCreateWithImageInRect (proven working)
 * 3. Tileset is 1024x1024 = 16x16 grid of 64x64 tiles
 * 4. Row/col in PRF files are encoded with 0x80 offset (subtract to get 0-15)
 *
 * Created as part of the viewport overhaul - fresh implementation.
 */

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * NecroTileRenderer
 *
 * Responsible for:
 * - Loading the tileset PNG
 * - Extracting individual tiles
 * - Caching extracted tiles for performance
 * - Drawing tiles to a graphics context
 */
@interface NecroTileRenderer : NSObject

/** Native tile size (64 for 64x64_necromancer.png) */
@property (nonatomic, readonly) NSInteger nativeTileSize;

/** Number of tile columns in tileset */
@property (nonatomic, readonly) NSInteger tileColumns;

/** Number of tile rows in tileset */
@property (nonatomic, readonly) NSInteger tileRows;

/** Whether the tileset loaded successfully */
@property (nonatomic, readonly) BOOL isLoaded;

/**
 * Initialize with path to tileset PNG.
 *
 * @param path Full path to tileset PNG file
 * @param tileSize Size of each tile in pixels (64 for 64x64 tiles)
 * @return Initialized renderer, or nil if tileset couldn't be loaded
 */
- (nullable instancetype)initWithTilesetPath:(NSString *)path
                                    tileSize:(NSInteger)tileSize;

/**
 * Draw a tile from the tileset to a graphics context.
 *
 * @param row Tile row in tileset (0-15 for 16x16 grid)
 * @param col Tile column in tileset (0-15 for 16x16 grid)
 * @param context Core Graphics context to draw into
 * @param point Top-left corner of destination in context coordinates
 * @param size Size to draw the tile (allows zoom)
 */
- (void)drawTileAtRow:(NSInteger)row
                  col:(NSInteger)col
            inContext:(CGContextRef)context
              atPoint:(CGPoint)point
             withSize:(CGSize)size;

/**
 * Draw a tile with background (terrain) and foreground (monster/item) layers.
 * Uses alpha blending for the foreground layer.
 *
 * @param bgRow Background tile row
 * @param bgCol Background tile column
 * @param fgRow Foreground tile row
 * @param fgCol Foreground tile column
 * @param context Core Graphics context
 * @param point Top-left corner of destination
 * @param size Size to draw the tile
 */
- (void)drawTileWithBackgroundRow:(NSInteger)bgRow
                    backgroundCol:(NSInteger)bgCol
                    foregroundRow:(NSInteger)fgRow
                    foregroundCol:(NSInteger)fgCol
                        inContext:(CGContextRef)context
                          atPoint:(CGPoint)point
                         withSize:(CGSize)size;

/**
 * Convert PRF-encoded attr/char to tileset row/col.
 * PRF format uses 0x80 offset, so 0x87 means row 7.
 *
 * @param attr The attribute byte from game (typically with 0x80 bit set)
 * @param chr The character byte from game (typically with 0x80 bit set)
 * @param outRow Pointer to store resulting row (0-15)
 * @param outCol Pointer to store resulting column (0-15)
 */
+ (void)convertAttr:(uint8_t)attr
               char:(uint8_t)chr
              toRow:(NSInteger *)outRow
                col:(NSInteger *)outCol;

/**
 * Clear the tile cache. Call if tileset is reloaded.
 */
- (void)clearCache;

/**
 * Get statistics about the tile cache for debugging.
 */
- (NSDictionary<NSString *, NSNumber *> *)cacheStatistics;

@end

NS_ASSUME_NONNULL_END
