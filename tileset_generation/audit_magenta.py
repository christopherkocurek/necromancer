#!/usr/bin/env python3
"""
Tileset Magenta/Pink Contamination Audit
Scans every non-empty tile in the tileset PNG and reports magenta pixel contamination.

Tileset: 2048x2048 pixels, 32x32 grid of 64x64 tiles
Magenta HSV definition: hue 280-340 degrees, saturation > 0.3, value > 0.3
"""

import colorsys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run: pip3 install Pillow")
    raise SystemExit(1)

TILESET_PATH = Path(__file__).parent.parent / "assets" / "sprites" / "necromancer_dcss_tileset.png"
TILE_SIZE = 64
GRID_SIZE = 32  # 32x32 grid

# Magenta HSV thresholds
# Python colorsys uses hue 0.0-1.0, so 280-340 degrees = 0.778-0.944
HUE_MIN = 280.0 / 360.0  # ~0.778
HUE_MAX = 340.0 / 360.0  # ~0.944
SAT_MIN = 0.3
VAL_MIN = 0.3

# Reporting thresholds
MAJOR_THRESHOLD = 2.0   # percentage
MINOR_THRESHOLD = 1.0   # percentage


def get_tile_description(col: int, row: int) -> str:
    """Return a brief description based on known tile layout."""
    if 0 <= row <= 5:
        pair = "light" if row % 2 == 0 else "dark"
        return f"Terrain ({pair}, row {row})"
    elif 6 <= row <= 9 and 0 <= col <= 11:
        race_names = {6: "Elf", 7: "Man", 8: "Dwarf", 9: "Hobbit"}
        race = race_names.get(row, f"Race row {row}")
        return f"Player sprite ({race})"
    elif 6 <= row <= 9 and col > 11:
        return f"Player area (unused, row {row})"
    elif row == 10:
        return "Effects/status"
    elif 11 <= row <= 17:
        return f"Item sprite (row {row})"
    elif row == 18:
        return f"New terrain (row 18)"
    elif row == 19:
        return f"Artefact category sprite"
    elif 20 <= row <= 23:
        return f"Available/former artifacts (row {row})"
    elif 24 <= row <= 26:
        return f"Monster sprite (row {row})"
    elif 27 <= row <= 31:
        return f"Available (row {row})"
    else:
        return f"Unknown (row {row})"


def is_tile_empty(tile_img: Image.Image) -> bool:
    """Check if a tile is empty (all transparent, all black, or near-black)."""
    pixels = list(tile_img.getdata())
    for pixel in pixels:
        if len(pixel) == 4:
            r, g, b, a = pixel
        else:
            r, g, b = pixel
            a = 255

        # If any pixel is non-transparent and not near-black, tile is not empty
        if a > 10 and (r > 10 or g > 10 or b > 10):
            return False
    return True


def count_magenta_pixels(tile_img: Image.Image) -> tuple[int, int, int]:
    """
    Count magenta/pink pixels in a tile.
    Returns (magenta_count, non_transparent_count, total_pixels).
    """
    pixels = list(tile_img.getdata())
    magenta_count = 0
    non_transparent_count = 0

    for pixel in pixels:
        if len(pixel) == 4:
            r, g, b, a = pixel
        else:
            r, g, b = pixel
            a = 255

        # Skip fully transparent pixels
        if a < 10:
            continue

        non_transparent_count += 1

        # Skip very dark pixels (not visually magenta even if hue matches)
        if r < 20 and g < 20 and b < 20:
            continue

        # Convert to HSV
        r_norm, g_norm, b_norm = r / 255.0, g / 255.0, b / 255.0
        h, s, v = colorsys.rgb_to_hsv(r_norm, g_norm, b_norm)

        # Check magenta/pink range
        if HUE_MIN <= h <= HUE_MAX and s > SAT_MIN and v > VAL_MIN:
            magenta_count += 1

    return magenta_count, non_transparent_count, len(pixels)


def main():
    print(f"Tileset Magenta/Pink Contamination Audit")
    print(f"{'=' * 60}")
    print(f"Tileset: {TILESET_PATH}")

    if not TILESET_PATH.exists():
        print(f"ERROR: Tileset not found at {TILESET_PATH}")
        raise SystemExit(1)

    img = Image.open(TILESET_PATH).convert("RGBA")
    w, h = img.size
    print(f"Image size: {w}x{h}")
    print(f"Grid: {GRID_SIZE}x{GRID_SIZE} tiles of {TILE_SIZE}x{TILE_SIZE} pixels")
    print(f"Magenta HSV: hue {280}-{340} deg, sat > {SAT_MIN}, val > {VAL_MIN}")
    print(f"Major threshold: > {MAJOR_THRESHOLD}%  |  Minor threshold: > {MINOR_THRESHOLD}%")
    print()

    results = []
    empty_count = 0
    clean_count = 0
    total_tiles = 0

    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            total_tiles += 1
            x0 = col * TILE_SIZE
            y0 = row * TILE_SIZE
            x1 = x0 + TILE_SIZE
            y1 = y0 + TILE_SIZE

            # Bounds check
            if x1 > w or y1 > h:
                continue

            tile = img.crop((x0, y0, x1, y1))

            if is_tile_empty(tile):
                empty_count += 1
                continue

            magenta, non_trans, total_px = count_magenta_pixels(tile)

            if non_trans == 0:
                empty_count += 1
                continue

            pct = (magenta / non_trans) * 100.0

            if pct > MINOR_THRESHOLD:
                desc = get_tile_description(col, row)
                results.append({
                    "col": col,
                    "row": row,
                    "magenta": magenta,
                    "non_transparent": non_trans,
                    "percentage": pct,
                    "description": desc,
                })
            else:
                clean_count += 1

    # Sort by percentage descending
    results.sort(key=lambda x: x["percentage"], reverse=True)

    # Separate major and minor
    major = [r for r in results if r["percentage"] > MAJOR_THRESHOLD]
    minor = [r for r in results if MINOR_THRESHOLD < r["percentage"] <= MAJOR_THRESHOLD]

    # Print major issues
    print(f"MAJOR ISSUES (>{MAJOR_THRESHOLD}% magenta): {len(major)} tiles")
    print(f"{'-' * 80}")
    if major:
        print(f"{'Grid (col,row)':<16} {'Magenta px':<12} {'Total px':<10} {'Pct':>7}  Description")
        print(f"{'-' * 80}")
        for r in major:
            print(
                f"({r['col']:2d}, {r['row']:2d})       "
                f"{r['magenta']:<12d} {r['non_transparent']:<10d} "
                f"{r['percentage']:6.2f}%  {r['description']}"
            )
    else:
        print("  None found!")
    print()

    # Print minor issues
    print(f"MINOR ISSUES ({MINOR_THRESHOLD}%-{MAJOR_THRESHOLD}% magenta): {len(minor)} tiles")
    print(f"{'-' * 80}")
    if minor:
        print(f"{'Grid (col,row)':<16} {'Magenta px':<12} {'Total px':<10} {'Pct':>7}  Description")
        print(f"{'-' * 80}")
        for r in minor:
            print(
                f"({r['col']:2d}, {r['row']:2d})       "
                f"{r['magenta']:<12d} {r['non_transparent']:<10d} "
                f"{r['percentage']:6.2f}%  {r['description']}"
            )
    else:
        print("  None found!")
    print()

    # Summary
    print(f"{'=' * 60}")
    print(f"SUMMARY")
    print(f"  Total tiles scanned:    {total_tiles}")
    print(f"  Empty tiles (skipped):  {empty_count}")
    print(f"  Clean tiles (<{MINOR_THRESHOLD}%):    {clean_count}")
    print(f"  Minor issues ({MINOR_THRESHOLD}-{MAJOR_THRESHOLD}%): {len(minor)}")
    print(f"  Major issues (>{MAJOR_THRESHOLD}%):   {len(major)}")
    print(f"  Non-empty tiles total:  {clean_count + len(minor) + len(major)}")

    # Top offenders summary
    if major:
        print()
        print(f"TOP 10 WORST OFFENDERS:")
        for i, r in enumerate(major[:10], 1):
            print(
                f"  {i:2d}. ({r['col']:2d}, {r['row']:2d}) - "
                f"{r['percentage']:.1f}% magenta ({r['magenta']} px) - "
                f"{r['description']}"
            )


if __name__ == "__main__":
    main()
