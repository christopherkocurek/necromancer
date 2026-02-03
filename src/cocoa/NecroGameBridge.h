/**
 * NecroGameBridge.h
 *
 * Bridge between the Angband game engine and the Necromancer tile renderer.
 * Provides a clean Objective-C interface to query game state for rendering.
 *
 * DESIGN DECISIONS:
 * 1. Class methods only - no instance needed, game state is global
 * 2. Wraps map_info() which returns attr/char values
 * 3. Converts attr/char (0x80 offset) to tile row/col (0-15)
 * 4. Provides player position, map dimensions, and visibility info
 *
 * Created for Phase 2 of viewport overhaul.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Information about a single map tile.
 */
typedef struct {
    NSInteger foregroundRow;    // Tileset row for foreground (monster/player)
    NSInteger foregroundCol;    // Tileset col for foreground
    NSInteger backgroundRow;    // Tileset row for background (terrain)
    NSInteger backgroundCol;    // Tileset col for background
    BOOL isVisible;             // Currently visible (CAVE_SEEN)
    BOOL isMemorized;           // Previously seen (CAVE_MARK)
    BOOL hasMonster;            // Monster present at this location
    BOOL hasPlayer;             // Player present at this location
    BOOL hasObject;             // Object on the ground
} NecroTileInfo;

/**
 * NecroGameBridge
 *
 * Static interface to query Angband game state.
 * All methods are class methods operating on global game state.
 */
@interface NecroGameBridge : NSObject

#pragma mark - Map Information

/**
 * Get tile information for a map location.
 * Returns foreground/background tile indices and visibility info.
 *
 * @param y Map row (0 = top)
 * @param x Map column (0 = left)
 * @return NecroTileInfo structure with tile data
 */
+ (NecroTileInfo)getTileInfoAtY:(int)y X:(int)x;

/**
 * Get the current map dimensions.
 * Returns the actual map size for the current dungeon level.
 *
 * @param outHeight Pointer to store map height
 * @param outWidth Pointer to store map width
 */
+ (void)getMapHeight:(int *)outHeight width:(int *)outWidth;

/**
 * Check if a map location is within valid bounds.
 *
 * @param y Map row
 * @param x Map column
 * @return YES if (y,x) is valid, NO otherwise
 */
+ (BOOL)isValidLocationY:(int)y X:(int)x;

#pragma mark - Player Information

/**
 * Get the player's current position.
 *
 * @param outY Pointer to store player row
 * @param outX Pointer to store player column
 */
+ (void)getPlayerPositionY:(int *)outY X:(int *)outX;

/**
 * Get player's current HP.
 *
 * @param outCurrent Pointer to store current HP
 * @param outMax Pointer to store maximum HP
 */
+ (void)getPlayerHP:(int *)outCurrent max:(int *)outMax;

/**
 * Get player's current stamina (mana).
 *
 * @param outCurrent Pointer to store current SP
 * @param outMax Pointer to store maximum SP
 */
+ (void)getPlayerSP:(int *)outCurrent max:(int *)outMax;

/**
 * Get the current dungeon depth (in feet).
 */
+ (int)getCurrentDepth;

#pragma mark - Graphics State

/**
 * Check if graphics mode is enabled.
 *
 * @return YES if using graphics tiles, NO if ASCII
 */
+ (BOOL)isGraphicsEnabled;

/**
 * Get the current graphics mode.
 *
 * @return Graphics mode constant (GRAPHICS_NONE, GRAPHICS_MICROCHASM, etc.)
 */
+ (int)currentGraphicsMode;

#pragma mark - Utility

/**
 * Convert game attr/char bytes to tile row/col.
 * Handles the 0x80 offset used in PRF files.
 *
 * @param attr The attribute byte (with 0x80 set for graphics)
 * @param chr The character byte (with 0x80 set for graphics)
 * @param outRow Pointer to store tile row (0-15 for 16x16 grid)
 * @param outCol Pointer to store tile column (0-15 for 16x16 grid)
 * @return YES if this is a graphics tile, NO if ASCII
 */
+ (BOOL)convertAttr:(unsigned char)attr
               char:(unsigned char)chr
              toRow:(NSInteger *)outRow
                col:(NSInteger *)outCol;

/**
 * Check if a tile coordinate pair represents a graphics tile.
 * Graphics tiles have the 0x80 bit set in both attr and char.
 *
 * @param attr The attribute byte
 * @param chr The character byte
 * @return YES if this is a graphics tile
 */
+ (BOOL)isGraphicsTile:(unsigned char)attr char:(unsigned char)chr;

@end

NS_ASSUME_NONNULL_END
