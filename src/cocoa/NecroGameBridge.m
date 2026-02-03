/**
 * NecroGameBridge.m
 *
 * Implementation of bridge between Angband game engine and tile renderer.
 * Wraps global game state in a clean Objective-C interface.
 */

#import "NecroGameBridge.h"

// Include Angband headers
// We need to use extern "C" style declarations since we're in Objective-C
#include "angband.h"

/** Enable debug logging during development */
#define NECRO_BRIDGE_DEBUG 0

#if NECRO_BRIDGE_DEBUG
#define BridgeLog(fmt, ...) NSLog(@"[NecroGameBridge] " fmt, ##__VA_ARGS__)
#else
#define BridgeLog(fmt, ...)
#endif

@implementation NecroGameBridge

#pragma mark - Map Information

+ (NecroTileInfo)getTileInfoAtY:(int)y X:(int)x
{
    NecroTileInfo info = {0};

    // Check bounds
    if (![self isValidLocationY:y X:x]) {
        // Return empty/void tile
        info.foregroundRow = 0;
        info.foregroundCol = 0;
        info.backgroundRow = 0;
        info.backgroundCol = 0;
        return info;
    }

    // Get foreground (monster/player/item) and background (terrain) info
    byte foreAttr = 0;
    char foreChar = 0;
    byte backAttr = 0;
    char backChar = 0;

    // map_info returns the combined attr/char for what should be displayed
    // The fourth and fifth params (tap, tcp) give the terrain underneath
    map_info(y, x, &foreAttr, &foreChar, &backAttr, &backChar);

    // Convert to tile coordinates
    // Check if foreground is a graphics tile (both have 0x80 bit set)
    if ([self isGraphicsTile:foreAttr char:(unsigned char)foreChar]) {
        info.foregroundRow = (foreAttr & 0x7F);
        info.foregroundCol = ((unsigned char)foreChar & 0x7F);
    } else {
        // ASCII mode - use default mapping
        info.foregroundRow = 0;
        info.foregroundCol = 0;
    }

    // Check if background is a graphics tile
    if ([self isGraphicsTile:backAttr char:(unsigned char)backChar]) {
        info.backgroundRow = (backAttr & 0x7F);
        info.backgroundCol = ((unsigned char)backChar & 0x7F);
    } else {
        // ASCII mode - use default floor tile
        info.backgroundRow = 0;
        info.backgroundCol = 1;  // Standard floor tile
    }

    // Get visibility info from cave_info
    u16b caveInfo = cave_info[y][x];
    info.isVisible = (caveInfo & CAVE_SEEN) != 0;
    info.isMemorized = (caveInfo & CAVE_MARK) != 0;

    // Check for monster
    s16b m_idx = cave_m_idx[y][x];
    info.hasMonster = (m_idx > 0);
    info.hasPlayer = (m_idx < 0);  // Negative index = player

    // Check for objects (simplified - just check if any object at location)
    info.hasObject = (cave_o_idx[y][x] > 0);

    BridgeLog(@"Tile (%d,%d): fg=%ld,%ld bg=%ld,%ld vis=%d mem=%d",
              y, x,
              (long)info.foregroundRow, (long)info.foregroundCol,
              (long)info.backgroundRow, (long)info.backgroundCol,
              info.isVisible, info.isMemorized);

    return info;
}

+ (void)getMapHeight:(int *)outHeight width:(int *)outWidth
{
    if (p_ptr) {
        *outHeight = p_ptr->cur_map_hgt;
        *outWidth = p_ptr->cur_map_wid;
    } else {
        // Fallback to defaults
        *outHeight = MAX_DUNGEON_HGT;
        *outWidth = MAX_DUNGEON_WID;
    }
}

+ (BOOL)isValidLocationY:(int)y X:(int)x
{
    if (!p_ptr) return NO;

    return (y >= 0 && y < p_ptr->cur_map_hgt &&
            x >= 0 && x < p_ptr->cur_map_wid);
}

#pragma mark - Player Information

+ (void)getPlayerPositionY:(int *)outY X:(int *)outX
{
    if (p_ptr) {
        *outY = p_ptr->py;
        *outX = p_ptr->px;
    } else {
        *outY = 0;
        *outX = 0;
    }
}

+ (void)getPlayerHP:(int *)outCurrent max:(int *)outMax
{
    if (p_ptr) {
        *outCurrent = p_ptr->chp;
        *outMax = p_ptr->mhp;
    } else {
        *outCurrent = 0;
        *outMax = 0;
    }
}

+ (void)getPlayerSP:(int *)outCurrent max:(int *)outMax
{
    if (p_ptr) {
        *outCurrent = p_ptr->csp;
        *outMax = p_ptr->msp;
    } else {
        *outCurrent = 0;
        *outMax = 0;
    }
}

+ (int)getCurrentDepth
{
    if (p_ptr) {
        return p_ptr->depth * 50;  // Convert to feet (50 feet per level)
    }
    return 0;
}

#pragma mark - Graphics State

+ (BOOL)isGraphicsEnabled
{
    return (use_graphics != GRAPHICS_NONE);
}

+ (int)currentGraphicsMode
{
    return use_graphics;
}

#pragma mark - Utility

+ (BOOL)convertAttr:(unsigned char)attr
               char:(unsigned char)chr
              toRow:(NSInteger *)outRow
                col:(NSInteger *)outCol
{
    // Check if this is a graphics tile (both bytes have 0x80 bit set)
    if ((attr & 0x80) && (chr & 0x80)) {
        // Remove the 0x80 bit to get the actual tile index
        *outRow = (attr & 0x7F);
        *outCol = (chr & 0x7F);
        return YES;
    }

    // Not a graphics tile
    *outRow = 0;
    *outCol = 0;
    return NO;
}

+ (BOOL)isGraphicsTile:(unsigned char)attr char:(unsigned char)chr
{
    return ((attr & 0x80) && (chr & 0x80));
}

@end
