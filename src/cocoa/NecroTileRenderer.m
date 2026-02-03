/**
 * NecroTileRenderer.m
 *
 * Implementation of tile renderer for The Necromancer.
 * Uses proven working pattern from main-cocoa.m:draw_image_tile().
 */

#import "NecroTileRenderer.h"

/** Enable debug logging during development */
#define NECRO_TILE_DEBUG 1

#if NECRO_TILE_DEBUG
#define NecroLog(fmt, ...) NSLog(@"[NecroTileRenderer] " fmt, ##__VA_ARGS__)
#else
#define NecroLog(fmt, ...)
#endif

@interface NecroTileRenderer ()

/** The loaded tileset image */
@property (nonatomic) CGImageRef tilesetImage;

/** Cache of extracted tile images, keyed by "row,col" */
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *tileCache;

/** Cache hit count for statistics */
@property (nonatomic) NSUInteger cacheHits;

/** Cache miss count for statistics */
@property (nonatomic) NSUInteger cacheMisses;

@end

@implementation NecroTileRenderer

#pragma mark - Lifecycle

- (nullable instancetype)initWithTilesetPath:(NSString *)path
                                    tileSize:(NSInteger)tileSize
{
    self = [super init];
    if (self) {
        _nativeTileSize = tileSize;
        _tileCache = [NSMutableDictionary dictionary];
        _cacheHits = 0;
        _cacheMisses = 0;
        _isLoaded = NO;

        // Load the tileset image
        if (![self loadTilesetFromPath:path]) {
            NecroLog(@"Failed to load tileset from: %@", path);
            return nil;
        }

        // Calculate grid dimensions
        CGFloat width = CGImageGetWidth(_tilesetImage);
        CGFloat height = CGImageGetHeight(_tilesetImage);
        _tileColumns = (NSInteger)(width / tileSize);
        _tileRows = (NSInteger)(height / tileSize);

        NecroLog(@"Loaded tileset: %.0fx%.0f pixels, %ldx%ld tiles of %ldpx",
                 width, height,
                 (long)_tileColumns, (long)_tileRows, (long)tileSize);

        _isLoaded = YES;
    }
    return self;
}

- (void)dealloc
{
    if (_tilesetImage) {
        CGImageRelease(_tilesetImage);
        _tilesetImage = NULL;
    }

    // Release cached images
    [self clearCache];
}

#pragma mark - Tileset Loading

- (BOOL)loadTilesetFromPath:(NSString *)path
{
    // Create data provider from file
    CGDataProviderRef provider = CGDataProviderCreateWithFilename([path UTF8String]);
    if (!provider) {
        NecroLog(@"Failed to create data provider for: %@", path);
        return NO;
    }

    // Create image from PNG data
    _tilesetImage = CGImageCreateWithPNGDataProvider(provider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);

    if (!_tilesetImage) {
        NecroLog(@"Failed to create CGImage from PNG: %@", path);
        return NO;
    }

    // Verify image dimensions
    size_t width = CGImageGetWidth(_tilesetImage);
    size_t height = CGImageGetHeight(_tilesetImage);
    size_t bpp = CGImageGetBitsPerPixel(_tilesetImage);

    NecroLog(@"Tileset loaded: %zux%zu, %zu bpp, alpha: %d",
             width, height, bpp,
             (int)CGImageGetAlphaInfo(_tilesetImage));

    return YES;
}

#pragma mark - Tile Drawing

- (void)drawTileAtRow:(NSInteger)row
                  col:(NSInteger)col
            inContext:(CGContextRef)context
              atPoint:(CGPoint)point
             withSize:(CGSize)size
{
    if (!_tilesetImage || !context) {
        return;
    }

    // Validate row/col bounds
    if (row < 0 || row >= _tileRows || col < 0 || col >= _tileColumns) {
        NecroLog(@"Tile out of bounds: row=%ld col=%ld (max: %ld x %ld)",
                 (long)row, (long)col, (long)_tileRows, (long)_tileColumns);
        return;
    }

    // Get or create the cached tile subimage
    CGImageRef tileImage = [self cachedTileAtRow:row col:col];
    if (!tileImage) {
        return;
    }

    // Draw the tile to the context
    // CGContextDrawImage uses lower-left origin, so we need to flip
    CGContextSaveGState(context);

    // Set up coordinate system: flip vertically around the tile center
    CGContextTranslateCTM(context, point.x, point.y + size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGRect destRect = CGRectMake(0, 0, size.width, size.height);
    CGContextDrawImage(context, destRect, tileImage);

    CGContextRestoreGState(context);
}

- (void)drawTileWithBackgroundRow:(NSInteger)bgRow
                    backgroundCol:(NSInteger)bgCol
                    foregroundRow:(NSInteger)fgRow
                    foregroundCol:(NSInteger)fgCol
                        inContext:(CGContextRef)context
                          atPoint:(CGPoint)point
                         withSize:(CGSize)size
{
    // Draw background first (terrain)
    [self drawTileAtRow:bgRow col:bgCol inContext:context atPoint:point withSize:size];

    // Draw foreground with alpha blending (monster/item)
    // Only draw if foreground is different from background
    if (fgRow != bgRow || fgCol != bgCol) {
        [self drawTileAtRow:fgRow col:fgCol inContext:context atPoint:point withSize:size];
    }
}

#pragma mark - Tile Caching

- (nullable CGImageRef)cachedTileAtRow:(NSInteger)row col:(NSInteger)col
{
    NSString *key = [NSString stringWithFormat:@"%ld,%ld", (long)row, (long)col];

    // Check cache first
    id cachedValue = _tileCache[key];
    if (cachedValue) {
        _cacheHits++;
        return (__bridge CGImageRef)cachedValue;
    }

    // Extract tile from tileset
    _cacheMisses++;
    CGImageRef tileImage = [self extractTileAtRow:row col:col];

    if (tileImage) {
        // Store in cache (transfer ownership to the dictionary)
        _tileCache[key] = (__bridge_transfer id)tileImage;
        // Get it back for return (dictionary owns it now)
        return (__bridge CGImageRef)_tileCache[key];
    }

    return NULL;
}

- (nullable CGImageRef)extractTileAtRow:(NSInteger)row col:(NSInteger)col
{
    if (!_tilesetImage) {
        return NULL;
    }

    // Calculate source rectangle in tileset
    // Note: CGImage uses top-left origin, so row 0 is at the top
    CGFloat x = col * _nativeTileSize;
    CGFloat y = row * _nativeTileSize;
    CGRect sourceRect = CGRectMake(x, y, _nativeTileSize, _nativeTileSize);

    // Extract the tile subimage
    CGImageRef tileImage = CGImageCreateWithImageInRect(_tilesetImage, sourceRect);

    if (!tileImage) {
        NecroLog(@"Failed to extract tile at row=%ld col=%ld", (long)row, (long)col);
    }

    return tileImage;
}

- (void)clearCache
{
    // The cached images are bridged to the dictionary, so they'll be released
    // when we clear the dictionary
    [_tileCache removeAllObjects];
    _cacheHits = 0;
    _cacheMisses = 0;
    NecroLog(@"Cache cleared");
}

- (NSDictionary<NSString *, NSNumber *> *)cacheStatistics
{
    return @{
        @"cacheSize": @(_tileCache.count),
        @"cacheHits": @(_cacheHits),
        @"cacheMisses": @(_cacheMisses),
        @"hitRate": @(_cacheHits + _cacheMisses > 0 ?
                      (double)_cacheHits / (_cacheHits + _cacheMisses) : 0)
    };
}

#pragma mark - Coordinate Conversion

+ (void)convertAttr:(uint8_t)attr
               char:(uint8_t)chr
              toRow:(NSInteger *)outRow
                col:(NSInteger *)outCol
{
    // PRF format: 0x87/0x82 means row 7, col 2
    // Remove the 0x80 high bit to get the actual index
    *outRow = (attr & 0x7F);
    *outCol = (chr & 0x7F);
}

@end
