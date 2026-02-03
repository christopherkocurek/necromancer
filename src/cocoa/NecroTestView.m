/**
 * NecroTestView.m
 *
 * Test view for Phase 1/2 verification.
 * Renders either a static grid of tiles or actual game map.
 */

#import "NecroTestView.h"
#import "NecroTileRenderer.h"
#import "NecroGameBridge.h"

@interface NecroTestView ()
@property (nonatomic) BOOL showGameMap;   // If YES, show actual game tiles
@property (nonatomic) int viewportCenterY;  // Center of viewport (map coords)
@property (nonatomic) int viewportCenterX;
@end

@implementation NecroTestView

- (instancetype)initWithFrame:(NSRect)frame
                 tileRenderer:(NecroTileRenderer *)renderer
{
    self = [super initWithFrame:frame];
    if (self) {
        _tileRenderer = renderer;
        _zoomLevel = 64;  // Native size
        _showGameMap = NO;
        _viewportCenterY = 0;
        _viewportCenterX = 0;
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tileRenderer = nil;
        _zoomLevel = 64;
        _showGameMap = NO;
    }
    return self;
}

- (void)refresh
{
    [self setNeedsDisplay:YES];
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)isFlipped
{
    // Use top-left origin for easier tile grid math
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Fill background with dark color
    [[NSColor colorWithRed:0.1 green:0.08 blue:0.12 alpha:1.0] setFill];
    NSRectFill(dirtyRect);

    if (!_tileRenderer || !_tileRenderer.isLoaded) {
        // Draw error message if no renderer
        [self drawErrorMessage:@"Tile renderer not loaded"];
        return;
    }

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    if (!context) {
        return;
    }

    if (_showGameMap && [NecroGameBridge isGraphicsEnabled]) {
        // Draw actual game map
        [self drawGameMapInContext:context];
    } else {
        // Draw static test grid
        [self drawTestGridInContext:context];
    }

    // Draw debug info
    [self drawDebugInfo];
}

#pragma mark - Game Map Rendering (Phase 2)

- (void)drawGameMapInContext:(CGContextRef)context
{
    CGSize tileSize = CGSizeMake(_zoomLevel, _zoomLevel);

    // Get player position and center viewport there
    int playerY, playerX;
    [NecroGameBridge getPlayerPositionY:&playerY X:&playerX];

    // Calculate how many tiles fit in the view
    NSRect bounds = self.bounds;
    int tilesWide = (int)(bounds.size.width / _zoomLevel) + 2;
    int tilesHigh = (int)((bounds.size.height - 40) / _zoomLevel) + 2;  // Reserve top for debug

    // Calculate starting map position (center on player)
    int startY = playerY - tilesHigh / 2;
    int startX = playerX - tilesWide / 2;

    // Get map dimensions
    int mapHeight, mapWidth;
    [NecroGameBridge getMapHeight:&mapHeight width:&mapWidth];

    // Draw visible tiles
    for (int vy = 0; vy < tilesHigh; vy++) {
        for (int vx = 0; vx < tilesWide; vx++) {
            int mapY = startY + vy;
            int mapX = startX + vx;

            // Screen position
            CGFloat screenX = vx * _zoomLevel;
            CGFloat screenY = 40 + vy * _zoomLevel;  // 40 for debug area
            CGPoint point = CGPointMake(screenX, screenY);

            // Check if valid map location
            if (mapY >= 0 && mapY < mapHeight && mapX >= 0 && mapX < mapWidth) {
                NecroTileInfo info = [NecroGameBridge getTileInfoAtY:mapY X:mapX];

                // Draw background (terrain) first
                [_tileRenderer drawTileAtRow:info.backgroundRow
                                         col:info.backgroundCol
                                   inContext:context
                                     atPoint:point
                                    withSize:tileSize];

                // Draw foreground (monster/player/item) if different from background
                if (info.foregroundRow != info.backgroundRow ||
                    info.foregroundCol != info.backgroundCol) {
                    [_tileRenderer drawTileAtRow:info.foregroundRow
                                             col:info.foregroundCol
                                       inContext:context
                                         atPoint:point
                                        withSize:tileSize];
                }

                // Dim non-visible tiles
                if (!info.isVisible && info.isMemorized) {
                    CGContextSetRGBFillColor(context, 0, 0, 0, 0.5);
                    CGContextFillRect(context, CGRectMake(screenX, screenY, _zoomLevel, _zoomLevel));
                }
            } else {
                // Out of bounds - draw void
                [_tileRenderer drawTileAtRow:0 col:0 inContext:context atPoint:point withSize:tileSize];
            }
        }
    }

    // Draw player position indicator
    int playerScreenX = (playerX - startX) * _zoomLevel;
    int playerScreenY = 40 + (playerY - startY) * _zoomLevel;
    CGContextSetRGBStrokeColor(context, 0, 1, 0, 1.0);
    CGContextSetLineWidth(context, 2.0);
    CGContextStrokeRect(context, CGRectMake(playerScreenX, playerScreenY, _zoomLevel, _zoomLevel));
}

#pragma mark - Static Test Grid (Phase 1)

- (void)drawTestGridInContext:(CGContextRef)context
{
    CGSize tileSize = CGSizeMake(_zoomLevel, _zoomLevel);
    CGFloat padding = 2.0;  // Small gap between tiles for visibility

    // Test tiles to display:
    // Row 0: Terrain (floors, walls)
    // Row 1: More terrain (doors, stairs)
    // Row 7: Player characters
    // Row 8: Small creatures
    // Row 9: Orcs

    struct TestTile {
        NSInteger row;
        NSInteger col;
        const char *label;
    };

    struct TestTile testTiles[] = {
        // Row 0: Terrain
        {0, 0, "void"},
        {0, 1, "floor"},
        {0, 2, "floor2"},
        {0, 3, "stairs?"},
        {0, 4, "terrain"},

        // Row 1: More terrain
        {1, 0, "wall"},
        {1, 3, "stairs"},
        {1, 5, "door_c"},
        {1, 6, "door_o"},
        {1, 7, "door_b"},

        // Row 7: Players
        {7, 0, "player1"},
        {7, 1, "player2"},
        {7, 2, "player3"},
        {7, 3, "player4"},
        {7, 4, "player5"},

        // Row 8: Creatures
        {8, 0, "rat"},
        {8, 1, "crow"},
        {8, 2, "bat"},
        {8, 3, "snake"},
        {8, 4, "spider"},

        // Row 9: Orcs
        {9, 0, "orc1"},
        {9, 1, "orc2"},
        {9, 2, "orc3"},
        {9, 3, "orc4"},
        {9, 4, "orc5"},
    };

    NSInteger numTiles = sizeof(testTiles) / sizeof(testTiles[0]);
    NSInteger tilesPerRow = 5;

    for (NSInteger i = 0; i < numTiles; i++) {
        NSInteger gridX = i % tilesPerRow;
        NSInteger gridY = i / tilesPerRow;

        CGFloat x = 10 + gridX * (_zoomLevel + padding);
        CGFloat y = 40 + gridY * (_zoomLevel + padding + 20);  // Extra space for labels

        CGPoint point = CGPointMake(x, y);

        [_tileRenderer drawTileAtRow:testTiles[i].row
                                 col:testTiles[i].col
                           inContext:context
                             atPoint:point
                            withSize:tileSize];

        // Draw label below tile
        NSString *label = [NSString stringWithUTF8String:testTiles[i].label];
        NSDictionary *attrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:9],
            NSForegroundColorAttributeName: [NSColor whiteColor]
        };
        [label drawAtPoint:NSMakePoint(x, y + _zoomLevel + 2) withAttributes:attrs];
    }
}

- (void)drawDebugInfo
{
    NSDictionary *stats = [_tileRenderer cacheStatistics];
    NSString *mode = _showGameMap ? @"GAME MAP" : @"TEST GRID";
    NSString *gfx = [NecroGameBridge isGraphicsEnabled] ? @"ON" : @"OFF";

    NSString *info;
    if (_showGameMap) {
        int py, px;
        [NecroGameBridge getPlayerPositionY:&py X:&px];
        int hp, maxHp;
        [NecroGameBridge getPlayerHP:&hp max:&maxHp];

        info = [NSString stringWithFormat:
            @"%@ | Zoom: %ldpx | Graphics: %@ | Player: (%d,%d) | HP: %d/%d | [M]ode [+/-]zoom [R]efresh",
            mode, (long)_zoomLevel, gfx, py, px, hp, maxHp];
    } else {
        info = [NSString stringWithFormat:
            @"%@ | Zoom: %ldpx | Cache: %@ tiles | [M]ode [+/-]zoom [R]efresh",
            mode, (long)_zoomLevel, stats[@"cacheSize"]];
    }

    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:11],
        NSForegroundColorAttributeName: [NSColor greenColor]
    };

    [info drawAtPoint:NSMakePoint(10, 10) withAttributes:attrs];
}

- (void)drawErrorMessage:(NSString *)message
{
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:18],
        NSForegroundColorAttributeName: [NSColor redColor]
    };

    NSSize size = [message sizeWithAttributes:attrs];
    NSPoint point = NSMakePoint(
        (self.bounds.size.width - size.width) / 2,
        (self.bounds.size.height - size.height) / 2
    );

    [message drawAtPoint:point withAttributes:attrs];
}

#pragma mark - Keyboard Handling

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
    NSString *chars = [event characters];
    if ([chars length] == 0) {
        [super keyDown:event];
        return;
    }

    unichar key = [chars characterAtIndex:0];

    switch (key) {
        case '+':
        case '=':
            // Zoom in
            if (_zoomLevel < 128) {
                _zoomLevel *= 2;
                [self refresh];
                NSLog(@"[NecroTestView] Zoom in: %ldpx", (long)_zoomLevel);
            }
            break;

        case '-':
        case '_':
            // Zoom out
            if (_zoomLevel > 32) {
                _zoomLevel /= 2;
                [self refresh];
                NSLog(@"[NecroTestView] Zoom out: %ldpx", (long)_zoomLevel);
            }
            break;

        case 'r':
        case 'R':
            // Refresh
            [_tileRenderer clearCache];
            [self refresh];
            NSLog(@"[NecroTestView] Cache cleared, refreshing");
            break;

        case 'm':
        case 'M':
            // Toggle mode
            _showGameMap = !_showGameMap;
            [self refresh];
            NSLog(@"[NecroTestView] Mode: %@", _showGameMap ? @"Game Map" : @"Test Grid");
            break;

        default:
            [super keyDown:event];
            break;
    }
}

@end
