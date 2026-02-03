#!/usr/bin/env python3
"""
Validate that tileset positions match PRF mappings.

This script:
1. Parses the PRF file to extract tile mappings
2. Loads the tileset PNG
3. Verifies that tiles at mapped positions have visible content
4. Reports any mismatches or empty tiles
"""

import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: PIL/Pillow is required. Install with: pip3 install Pillow")
    sys.exit(1)

PROJECT_ROOT = Path(__file__).parent.parent.parent
GRAF_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
PREF_DIR = PROJECT_ROOT / "lib" / "pref"
TILESET_PATH = GRAF_DIR / "64x64_necromancer.png"
PRF_PATH = PREF_DIR / "graf-necromancer.prf"

TILE_SIZE = 64
MIN_VISIBLE_PIXELS = 100  # Minimum non-transparent pixels to consider a tile "has content"
ALPHA_THRESHOLD = 10  # Alpha value above which a pixel is considered visible


def parse_prf(prf_path: Path) -> list[tuple[str, int, int, int]]:
    """
    Parse PRF file and return list of (type, id, row, col) tuples.

    PRF format: TYPE:ID:0xROW/0xCOL
    where ROW and COL have 0x80 offset that must be removed.
    """
    mappings = []

    if not prf_path.exists():
        print(f"Error: PRF file not found: {prf_path}")
        return mappings

    with open(prf_path) as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()

            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue

            # Skip conditional directives (these shouldn't exist in our fixed PRF)
            if line.startswith('?:'):
                print(f"Warning: Found conditional directive at line {line_num}: {line}")
                continue

            # Parse mapping lines: F:0:0x80/0x80 or R:0:0x86/0x80
            match = re.match(r'^([FRKLESO]):(\d+):0x([0-9A-Fa-f]+)/0x([0-9A-Fa-f]+)', line)
            if match:
                typ, idx, row_hex, col_hex = match.groups()
                # Remove 0x80 offset to get actual row/col
                row = int(row_hex, 16) - 0x80
                col = int(col_hex, 16) - 0x80
                mappings.append((typ, int(idx), row, col))

    return mappings


def check_tile_content(img: Image.Image, row: int, col: int) -> tuple[bool, int]:
    """
    Check if a tile at (row, col) has visible content.

    Returns (has_content, visible_pixel_count)
    """
    x = col * TILE_SIZE
    y = row * TILE_SIZE

    # Check bounds
    if x + TILE_SIZE > img.width or y + TILE_SIZE > img.height:
        return False, 0

    tile = img.crop((x, y, x + TILE_SIZE, y + TILE_SIZE))

    # Count pixels with alpha > threshold
    visible = 0
    for pixel in tile.getdata():
        if len(pixel) >= 4:  # RGBA
            if pixel[3] > ALPHA_THRESHOLD:
                visible += 1
        else:  # RGB (no alpha)
            # Consider all pixels visible if no alpha channel
            visible += 1

    return visible >= MIN_VISIBLE_PIXELS, visible


def validate_tileset(tileset_path: Path, mappings: list) -> list[str]:
    """
    Check that tiles at PRF positions have content.

    Returns list of error messages.
    """
    if not tileset_path.exists():
        return [f"Error: Tileset not found: {tileset_path}"]

    try:
        img = Image.open(tileset_path).convert('RGBA')
    except Exception as e:
        return [f"Error loading tileset: {e}"]

    errors = []
    warnings = []

    # Type descriptions for clearer error messages
    type_names = {
        'F': 'Feature',
        'R': 'Race/Monster',
        'K': 'Object Kind',
        'L': 'Flavor',
        'E': 'Effect',
        'S': 'Special',
        'O': 'Object',
    }

    for typ, idx, row, col in mappings:
        has_content, pixel_count = check_tile_content(img, row, col)

        type_name = type_names.get(typ, typ)

        if not has_content:
            errors.append(
                f"{type_name} {typ}:{idx} at row {row}, col {col} - "
                f"tile appears empty! ({pixel_count} visible pixels)"
            )
        elif pixel_count < 500:
            warnings.append(
                f"{type_name} {typ}:{idx} at row {row}, col {col} - "
                f"tile has low content ({pixel_count} visible pixels)"
            )

    return errors, warnings


def check_for_conditionals(prf_path: Path) -> list[str]:
    """Check if the PRF file contains any conditional directives."""
    issues = []

    if not prf_path.exists():
        return issues

    with open(prf_path) as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if line.startswith('?:'):
                issues.append(f"Line {line_num}: {line}")

    return issues


def main():
    print("=" * 60)
    print("TILESET MAPPING VALIDATION")
    print("=" * 60)
    print()

    # Check for conditional directives
    print("Checking PRF for conditional directives...")
    conditionals = check_for_conditionals(PRF_PATH)
    if conditionals:
        print("  ERROR: Found conditional directives (these should not exist):")
        for c in conditionals:
            print(f"    {c}")
        print()
    else:
        print("  OK: No conditional directives found")
        print()

    # Parse mappings
    print(f"Parsing PRF: {PRF_PATH}")
    mappings = parse_prf(PRF_PATH)
    print(f"  Found {len(mappings)} mappings")

    # Count by type
    type_counts = {}
    for typ, _, _, _ in mappings:
        type_counts[typ] = type_counts.get(typ, 0) + 1
    print("  Breakdown by type:")
    for typ, count in sorted(type_counts.items()):
        print(f"    {typ}: {count}")
    print()

    # Validate tileset
    print(f"Validating tileset: {TILESET_PATH}")
    errors, warnings = validate_tileset(TILESET_PATH, mappings)
    print()

    # Report warnings
    if warnings:
        print("WARNINGS (low content tiles):")
        for w in warnings[:10]:  # Show first 10
            print(f"  {w}")
        if len(warnings) > 10:
            print(f"  ... and {len(warnings) - 10} more")
        print()

    # Report errors
    if errors:
        print("ERRORS (empty tiles):")
        for e in errors:
            print(f"  {e}")
        print()
        print(f"VALIDATION FAILED: {len(errors)} errors, {len(warnings)} warnings")
        return 1

    # Check specific important mappings
    print("Checking critical mappings...")
    critical = [
        ('R', 0, 'Player Elf'),
        ('R', 1, 'Player Man'),
        ('R', 2, 'Player Dwarf'),
        ('F', 0, 'Darkness'),
        ('F', 1, 'Stone Floor'),
        ('F', 56, 'Wall'),
    ]

    for typ, idx, name in critical:
        found = False
        for m_typ, m_idx, m_row, m_col in mappings:
            if m_typ == typ and m_idx == idx:
                print(f"  {name} ({typ}:{idx}): row {m_row}, col {m_col}")
                found = True
                break
        if not found:
            print(f"  {name} ({typ}:{idx}): NOT FOUND IN PRF!")
    print()

    print("=" * 60)
    if conditionals:
        print("RESULT: PRF HAS CONDITIONAL ISSUES - needs regeneration")
        return 1
    else:
        print("VALIDATION PASSED")
        print(f"  {len(mappings)} mappings validated")
        print(f"  {len(warnings)} low-content warnings")
        print(f"  {len(errors)} errors")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
