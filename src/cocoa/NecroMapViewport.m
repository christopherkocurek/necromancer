/**
 * NecroMapViewport.m
 *
 * Implementation of the main map viewport for The Necromancer.
 * Renders the dungeon map with proper tile graphics.
 */

#import "NecroMapViewport.h"
#import "NecroTileRenderer.h"
#import "NecroGameBridge.h"

/** Enable debug logging */
#define NECRO_VIEWPORT_DEBUG 0

#if NECRO_VIEWPORT_DEBUG
#define ViewportLog(fmt, ...) NSLog(@"[NecroMapViewport] " fmt, ##__VA_ARGS__)
#else
#define ViewportLog(fmt, ...)
#endif

@interface NecroMapViewport ()

/** Last known player position for smooth scrolling */
@property (nonatomic) int lastPlayerY;
@property (nonatomic) int lastPlayerX;

/** Look mode state */
@property (nonatomic, readwrite) BOOL isLookModeActive;
@property (nonatomic, readwrite) int lookCursorY;
@property (nonatomic, readwrite) int lookCursorX;

/** Viewport offset (for smooth scrolling, in pixels) */
@property (nonatomic) CGFloat viewOffsetX;
@property (nonatomic) CGFloat viewOffsetY;

@end

@implementation NecroMapViewport

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frame
                 tileRenderer:(NecroTileRenderer *)renderer
{
    self = [super initWithFrame:frame];
    if (self) {
        _tileRenderer = renderer;
        _zoomLevel = NecroZoomLevel64;
        _isLookModeActive = NO;
        _showHealthBars = YES;
        _showGrid = NO;
        _lastPlayerY = 0;
        _lastPlayerX = 0;
        _viewOffsetX = 0;
        _viewOffsetY = 0;
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tileRenderer = nil;
        _zoomLevel = NecroZoomLevel64;
        _isLookModeActive = NO;
        _showHealthBars = YES;
        _showGrid = NO;
    }
    return self;
}

#pragma mark - NSView Overrides

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)isFlipped
{
    // Use top-left origin for easier tile grid math
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Fill background with void color
    [[NSColor colorWithRed:0.05 green:0.03 blue:0.08 alpha:1.0] setFill];
    NSRectFill(dirtyRect);

    if (!_tileRenderer || !_tileRenderer.isLoaded) {
        [self drawMessage:@"Waiting for tileset..."];
        return;
    }

    if (![NecroGameBridge isGraphicsEnabled]) {
        [self drawMessage:@"Graphics mode not enabled"];
        return;
    }

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    if (!context) {
        return;
    }

    // Center on player
    [self centerOnPlayer];

    // Draw the map
    [self drawMapInContext:context];

    // Draw look cursor if in look mode
    if (_isLookModeActive) {
        [self drawLookCursorInContext:context];
    }

    // Draw grid overlay if enabled
    if (_showGrid) {
        [self drawGridInContext:context];
    }
}

#pragma mark - Map Rendering

- (void)drawMapInContext:(CGContextRef)context
{
    CGSize tileSize = CGSizeMake(_zoomLevel, _zoomLevel);
    NSRect bounds = self.bounds;

    // Get player position
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    // Calculate visible area
    int tilesWide = (int)ceil(bounds.size.width / _zoomLevel) + 2;
    int tilesHigh = (int)ceil(bounds.size.height / _zoomLevel) + 2;

    // Calculate starting map position (center on player)
    int startY = playerY - tilesHigh / 2;
    int startX = playerX - tilesWide / 2;

    // Get map dimensions
    int mapHeight, mapWidth;
    [NecroGameBridge getMapHeight:&mapHeight width:&mapWidth];

    // Draw all visible tiles
    for (int vy = 0; vy < tilesHigh; vy++) {
        for (int vx = 0; vx < tilesWide; vx++) {
            int mapY = startY + vy;
            int mapX = startX + vx;

            // Screen position (accounting for centering offset)
            CGFloat screenX = vx * _zoomLevel - _viewOffsetX;
            CGFloat screenY = vy * _zoomLevel - _viewOffsetY;

            // Skip if completely off screen
            if (screenX + _zoomLevel < 0 || screenX > bounds.size.width ||
                screenY + _zoomLevel < 0 || screenY > bounds.size.height) {
                continue;
            }

            CGPoint point = CGPointMake(screenX, screenY);

            // Draw tile
            if (mapY >= 0 && mapY < mapHeight && mapX >= 0 && mapX < mapWidth) {
                [self drawTileAtMapY:mapY X:mapX toPoint:point withSize:tileSize inContext:context];
            } else {
                // Out of bounds - draw void
                [_tileRenderer drawTileAtRow:0 col:0
                                   inContext:context
                                     atPoint:point
                                    withSize:tileSize];
            }
        }
    }

    // Draw player highlight
    CGFloat playerScreenX = (playerX - startX) * _zoomLevel - _viewOffsetX;
    CGFloat playerScreenY = (playerY - startY) * _zoomLevel - _viewOffsetY;
    [self drawPlayerHighlightAtX:playerScreenX Y:playerScreenY inContext:context];
}

- (void)drawTileAtMapY:(int)mapY X:(int)mapX toPoint:(CGPoint)point
              withSize:(CGSize)size inContext:(CGContextRef)context
{
    NecroTileInfo info = [NecroGameBridge getTileInfoAtY:mapY X:mapX];

    // Draw background (terrain)
    [_tileRenderer drawTileAtRow:info.backgroundRow
                             col:info.backgroundCol
                       inContext:context
                         atPoint:point
                        withSize:size];

    // Draw foreground (monster/player) if different
    if (info.foregroundRow != info.backgroundRow ||
        info.foregroundCol != info.backgroundCol) {
        [_tileRenderer drawTileAtRow:info.foregroundRow
                                 col:info.foregroundCol
                           inContext:context
                             atPoint:point
                            withSize:size];
    }

    // Apply visibility effects
    if (!info.isVisible) {
        if (info.isMemorized) {
            // Dim memorized but not visible tiles
            CGContextSetRGBFillColor(context, 0, 0, 0, 0.5);
            CGContextFillRect(context, CGRectMake(point.x, point.y, size.width, size.height));
        } else {
            // Completely dark for unknown tiles
            CGContextSetRGBFillColor(context, 0.05, 0.03, 0.08, 0.95);
            CGContextFillRect(context, CGRectMake(point.x, point.y, size.width, size.height));
        }
    }

    // Draw health bar for monsters
    if (_showHealthBars && info.hasMonster && info.isVisible) {
        [self drawHealthBarAtPoint:point withSize:size forMapY:mapY X:mapX inContext:context];
    }
}

- (void)drawPlayerHighlightAtX:(CGFloat)x Y:(CGFloat)y inContext:(CGContextRef)context
{
    // Subtle green glow around player
    CGContextSetRGBStrokeColor(context, 0.2, 0.8, 0.3, 0.8);
    CGContextSetLineWidth(context, 2.0);
    CGContextStrokeRect(context, CGRectMake(x + 1, y + 1, _zoomLevel - 2, _zoomLevel - 2));
}

- (void)drawHealthBarAtPoint:(CGPoint)point withSize:(CGSize)size
                    forMapY:(int)mapY X:(int)mapX inContext:(CGContextRef)context
{
    // Health bar dimensions
    CGFloat barHeight = 4;
    CGFloat barWidth = size.width - 4;
    CGFloat barX = point.x + 2;
    CGFloat barY = point.y + size.height - barHeight - 2;

    // TODO: Get actual monster HP from game state
    // For now, just draw a placeholder bar
    CGFloat healthPercent = 0.7;  // Placeholder

    // Background (dark)
    CGContextSetRGBFillColor(context, 0.2, 0.0, 0.0, 0.8);
    CGContextFillRect(context, CGRectMake(barX, barY, barWidth, barHeight));

    // Health (color based on %)
    if (healthPercent > 0.5) {
        CGContextSetRGBFillColor(context, 0.0, 0.8, 0.0, 1.0);  // Green
    } else if (healthPercent > 0.25) {
        CGContextSetRGBFillColor(context, 0.9, 0.7, 0.0, 1.0);  // Yellow
    } else {
        CGContextSetRGBFillColor(context, 0.9, 0.1, 0.0, 1.0);  // Red
    }
    CGContextFillRect(context, CGRectMake(barX, barY, barWidth * healthPercent, barHeight));
}

#pragma mark - Look Mode

- (void)drawLookCursorInContext:(CGContextRef)context
{
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    NSRect bounds = self.bounds;
    int tilesHigh = (int)ceil(bounds.size.height / _zoomLevel) + 2;
    int tilesWide = (int)ceil(bounds.size.width / _zoomLevel) + 2;
    int startY = playerY - tilesHigh / 2;
    int startX = playerX - tilesWide / 2;

    CGFloat cursorX = (_lookCursorX - startX) * _zoomLevel - _viewOffsetX;
    CGFloat cursorY = (_lookCursorY - startY) * _zoomLevel - _viewOffsetY;

    // Draw pulsing cursor
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0.0, 0.9);
    CGContextSetLineWidth(context, 3.0);
    CGContextStrokeRect(context, CGRectMake(cursorX, cursorY, _zoomLevel, _zoomLevel));

    // Inner highlight
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 0.5);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokeRect(context, CGRectMake(cursorX + 2, cursorY + 2, _zoomLevel - 4, _zoomLevel - 4));
}

- (void)enterLookMode
{
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    _isLookModeActive = YES;
    _lookCursorY = playerY;
    _lookCursorX = playerX;

    [self refresh];
    ViewportLog(@"Entered look mode at (%d,%d)", _lookCursorY, _lookCursorX);
}

- (void)exitLookMode
{
    _isLookModeActive = NO;
    [self refresh];
    ViewportLog(@"Exited look mode");
}

- (void)moveLookCursorByDeltaY:(int)dy deltaX:(int)dx
{
    if (!_isLookModeActive) return;

    int newY = _lookCursorY + dy;
    int newX = _lookCursorX + dx;

    // Check bounds
    if ([NecroGameBridge isValidLocationY:newY X:newX]) {
        _lookCursorY = newY;
        _lookCursorX = newX;
        [self refresh];
    }
}

- (nullable NSString *)lookCursorDescription
{
    if (!_isLookModeActive) return nil;

    NecroTileInfo info = [NecroGameBridge getTileInfoAtY:_lookCursorY X:_lookCursorX];

    NSMutableString *desc = [NSMutableString string];

    if (!info.isVisible && !info.isMemorized) {
        return @"Unknown";
    }

    if (info.hasPlayer) {
        [desc appendString:@"You are standing here"];
    } else if (info.hasMonster) {
        [desc appendString:@"A monster"];  // TODO: Get actual monster name
    } else if (info.hasObject) {
        [desc appendString:@"An item"];  // TODO: Get actual item name
    } else {
        [desc appendString:@"Empty floor"];  // TODO: Get actual terrain name
    }

    if (!info.isVisible) {
        [desc appendString:@" (remembered)"];
    }

    return desc;
}

#pragma mark - Grid Overlay

- (void)drawGridInContext:(CGContextRef)context
{
    NSRect bounds = self.bounds;

    CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 0.3);
    CGContextSetLineWidth(context, 0.5);

    // Vertical lines
    for (CGFloat x = 0; x < bounds.size.width; x += _zoomLevel) {
        CGContextMoveToPoint(context, x, 0);
        CGContextAddLineToPoint(context, x, bounds.size.height);
    }

    // Horizontal lines
    for (CGFloat y = 0; y < bounds.size.height; y += _zoomLevel) {
        CGContextMoveToPoint(context, 0, y);
        CGContextAddLineToPoint(context, bounds.size.width, y);
    }

    CGContextStrokePath(context);
}

#pragma mark - Viewport Control

- (void)centerOnPlayer
{
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    // For now, just track player position (instant centering)
    // TODO: Add smooth scrolling
    _lastPlayerY = playerY;
    _lastPlayerX = playerX;

    // Calculate centering offset to put player exactly in center
    NSRect bounds = self.bounds;
    CGFloat centerX = bounds.size.width / 2;
    CGFloat centerY = bounds.size.height / 2;

    // The offset adjusts the viewport so player tile is centered
    _viewOffsetX = (_zoomLevel / 2) - (centerX - floor(centerX / _zoomLevel) * _zoomLevel);
    _viewOffsetY = (_zoomLevel / 2) - (centerY - floor(centerY / _zoomLevel) * _zoomLevel);
}

- (void)zoomIn
{
    switch (_zoomLevel) {
        case NecroZoomLevel32:
            _zoomLevel = NecroZoomLevel64;
            break;
        case NecroZoomLevel64:
            _zoomLevel = NecroZoomLevel128;
            break;
        default:
            break;
    }
    [self refresh];
    ViewportLog(@"Zoomed in to %ldpx", (long)_zoomLevel);
}

- (void)zoomOut
{
    switch (_zoomLevel) {
        case NecroZoomLevel128:
            _zoomLevel = NecroZoomLevel64;
            break;
        case NecroZoomLevel64:
            _zoomLevel = NecroZoomLevel32;
            break;
        default:
            break;
    }
    [self refresh];
    ViewportLog(@"Zoomed out to %ldpx", (long)_zoomLevel);
}

#pragma mark - Coordinate Conversion

- (BOOL)screenPointToMapY:(int *)outY X:(int *)outX fromPoint:(NSPoint)screenPoint
{
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    NSRect bounds = self.bounds;
    int tilesHigh = (int)ceil(bounds.size.height / _zoomLevel) + 2;
    int tilesWide = (int)ceil(bounds.size.width / _zoomLevel) + 2;
    int startY = playerY - tilesHigh / 2;
    int startX = playerX - tilesWide / 2;

    int tileX = (int)((screenPoint.x + _viewOffsetX) / _zoomLevel);
    int tileY = (int)((screenPoint.y + _viewOffsetY) / _zoomLevel);

    *outY = startY + tileY;
    *outX = startX + tileX;

    return [NecroGameBridge isValidLocationY:*outY X:*outX];
}

- (NSPoint)mapToScreenY:(int)mapY X:(int)mapX
{
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    NSRect bounds = self.bounds;
    int tilesHigh = (int)ceil(bounds.size.height / _zoomLevel) + 2;
    int tilesWide = (int)ceil(bounds.size.width / _zoomLevel) + 2;
    int startY = playerY - tilesHigh / 2;
    int startX = playerX - tilesWide / 2;

    CGFloat screenX = (mapX - startX) * _zoomLevel - _viewOffsetX;
    CGFloat screenY = (mapY - startY) * _zoomLevel - _viewOffsetY;

    return NSMakePoint(screenX, screenY);
}

#pragma mark - Refresh

- (void)refresh
{
    [self setNeedsDisplay:YES];
}

- (void)refreshMapRegionFromY:(int)y1 X:(int)x1 toY:(int)y2 X:(int)x2
{
    // Convert map region to screen rect and invalidate
    NSPoint topLeft = [self mapToScreenY:y1 X:x1];
    NSPoint bottomRight = [self mapToScreenY:y2 + 1 X:x2 + 1];

    NSRect dirtyRect = NSMakeRect(topLeft.x, topLeft.y,
                                   bottomRight.x - topLeft.x,
                                   bottomRight.y - topLeft.y);
    [self setNeedsDisplayInRect:dirtyRect];
}

#pragma mark - Keyboard Handling

- (void)keyDown:(NSEvent *)event
{
    NSString *chars = [event characters];
    if ([chars length] == 0) {
        [super keyDown:event];
        return;
    }

    unichar key = [chars characterAtIndex:0];

    // Handle look mode navigation
    if (_isLookModeActive) {
        switch (key) {
            case NSUpArrowFunctionKey:
            case 'k':
            case '8':
                [self moveLookCursorByDeltaY:-1 deltaX:0];
                return;
            case NSDownArrowFunctionKey:
            case 'j':
            case '2':
                [self moveLookCursorByDeltaY:1 deltaX:0];
                return;
            case NSLeftArrowFunctionKey:
            case 'h':
            case '4':
                [self moveLookCursorByDeltaY:0 deltaX:-1];
                return;
            case NSRightArrowFunctionKey:
            case 'l':
            case '6':
                [self moveLookCursorByDeltaY:0 deltaX:1];
                return;
            case 27:  // Escape
            case 'q':
            case ';':
                [self exitLookMode];
                return;
        }
    }

    // Handle zoom and mode controls
    switch (key) {
        case '+':
        case '=':
            [self zoomIn];
            return;
        case '-':
        case '_':
            [self zoomOut];
            return;
        case ';':
            [self enterLookMode];
            return;
        case 'g':
        case 'G':
            _showGrid = !_showGrid;
            [self refresh];
            return;
    }

    // Pass unhandled keys up
    [super keyDown:event];
}

#pragma mark - Utility

- (void)drawMessage:(NSString *)message
{
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:16],
        NSForegroundColorAttributeName: [NSColor grayColor]
    };

    NSSize size = [message sizeWithAttributes:attrs];
    NSPoint point = NSMakePoint(
        (self.bounds.size.width - size.width) / 2,
        (self.bounds.size.height - size.height) / 2
    );

    [message drawAtPoint:point withAttributes:attrs];
}

@end
