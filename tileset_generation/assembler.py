#!/usr/bin/env python3
"""
Necromancer Tileset Assembler
Combines individual sprites from staging/ into final tileset PNG.

Usage:
    python assembler.py                    # Assemble tileset
    python assembler.py --preview          # Generate preview image
    python assembler.py --validate         # Validate all sprites
    python assembler.py --output custom.png  # Custom output path
"""

import json
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("PIL not installed. Run: pip install pillow")
    exit(1)

# Constants
TILE_SIZE = 64
GRID_SIZE = 32
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048x2048
MAGENTA = (255, 0, 255, 255)

# Paths
BASE_DIR = Path(__file__).parent
PROJECT_ROOT = BASE_DIR.parent
STAGING_DIR = BASE_DIR / "staging"
LAYOUT_PATH = BASE_DIR / "layout_map.json"
MANIFEST_PATH = BASE_DIR / "manifest.json"
OUTPUT_PATH = PROJECT_ROOT / "assets" / "sprites" / "64x64_necromancer_new.png"


def load_layout() -> Dict:
    """Load the layout map."""
    with open(LAYOUT_PATH, 'r') as f:
        return json.load(f)


def load_manifest() -> Dict:
    """Load the manifest."""
    with open(MANIFEST_PATH, 'r') as f:
        return json.load(f)


def find_sprite(entity_key: str) -> Optional[Path]:
    """Find a sprite file in staging directory."""
    # Parse the key to determine category
    parts = entity_key.split('_')
    if len(parts) < 2:
        return None

    category = parts[0]
    # Map singular to plural for directory
    category_dirs = {
        'terrain': 'terrain',
        'monster': 'monsters',
        'item': 'items',
        'artifact': 'artifacts',
        'player': 'players',
        'effect': 'effects'
    }

    dir_name = category_dirs.get(category, category)
    sprite_path = STAGING_DIR / dir_name / f"{entity_key}.png"

    if sprite_path.exists():
        return sprite_path

    # Try alternate naming
    alt_path = STAGING_DIR / dir_name / f"{entity_key.replace('_', '-')}.png"
    if alt_path.exists():
        return alt_path

    return None


def validate_sprite(path: Path) -> Tuple[bool, str]:
    """Validate a sprite file."""
    try:
        img = Image.open(path)

        # Check dimensions
        if img.size != (TILE_SIZE, TILE_SIZE):
            return False, f"Wrong size: {img.size}, expected {TILE_SIZE}x{TILE_SIZE}"

        # Check mode
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Check has content
        pixels = list(img.getdata())
        non_magenta = sum(1 for p in pixels if p[:3] != MAGENTA[:3])
        if non_magenta < 100:
            return False, "Sprite appears empty (mostly magenta)"

        return True, "OK"
    except Exception as e:
        return False, str(e)


def assemble_tileset(output_path: Path, missing_placeholder: bool = True) -> Dict:
    """Assemble all sprites into final tileset."""
    print(f"Assembling tileset: {TILESET_SIZE}x{TILESET_SIZE} pixels")

    # Create blank tileset with magenta background
    tileset = Image.new('RGBA', (TILESET_SIZE, TILESET_SIZE), MAGENTA)

    layout = load_layout()
    coordinates = layout.get('coordinates', {})

    stats = {
        'total': len(coordinates),
        'found': 0,
        'missing': 0,
        'invalid': 0,
        'errors': []
    }

    print(f"Processing {stats['total']} sprites...")

    for entity_key, coord in coordinates.items():
        x = coord['x'] * TILE_SIZE
        y = coord['y'] * TILE_SIZE

        sprite_path = find_sprite(entity_key)

        if sprite_path is None:
            stats['missing'] += 1
            if missing_placeholder:
                # Draw placeholder (grey square with X)
                placeholder = create_placeholder(entity_key)
                tileset.paste(placeholder, (x, y))
            continue

        # Validate and load sprite
        valid, msg = validate_sprite(sprite_path)
        if not valid:
            stats['invalid'] += 1
            stats['errors'].append(f"{entity_key}: {msg}")
            if missing_placeholder:
                placeholder = create_placeholder(entity_key, error=True)
                tileset.paste(placeholder, (x, y))
            continue

        # Load and paste sprite
        try:
            sprite = Image.open(sprite_path).convert('RGBA')
            if sprite.size != (TILE_SIZE, TILE_SIZE):
                sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
            tileset.paste(sprite, (x, y))
            stats['found'] += 1
        except Exception as e:
            stats['errors'].append(f"{entity_key}: {e}")
            stats['invalid'] += 1

    # Save tileset
    output_path.parent.mkdir(parents=True, exist_ok=True)
    tileset.save(output_path, 'PNG')

    print(f"\nTileset saved to: {output_path}")
    print(f"Stats: {stats['found']} found, {stats['missing']} missing, {stats['invalid']} invalid")

    return stats


def create_placeholder(entity_key: str, error: bool = False) -> Image.Image:
    """Create a placeholder image for missing sprites."""
    img = Image.new('RGBA', (TILE_SIZE, TILE_SIZE), MAGENTA)
    draw = ImageDraw.Draw(img)

    # Background color
    bg_color = (128, 0, 0, 255) if error else (64, 64, 64, 255)
    draw.rectangle([4, 4, TILE_SIZE - 4, TILE_SIZE - 4], fill=bg_color)

    # Draw X
    line_color = (255, 255, 255, 255)
    draw.line([8, 8, TILE_SIZE - 8, TILE_SIZE - 8], fill=line_color, width=2)
    draw.line([8, TILE_SIZE - 8, TILE_SIZE - 8, 8], fill=line_color, width=2)

    return img


def generate_preview(output_path: Path, scale: int = 1):
    """Generate a labeled preview image."""
    layout = load_layout()
    manifest = load_manifest()
    coordinates = layout.get('coordinates', {})

    # Create preview at specified scale
    preview_size = TILESET_SIZE // (4 // scale)
    tile_preview_size = TILE_SIZE // (4 // scale)

    preview = Image.new('RGB', (preview_size, preview_size), (32, 32, 32))
    draw = ImageDraw.Draw(preview)

    # Draw grid
    for i in range(GRID_SIZE + 1):
        pos = i * tile_preview_size
        # Vertical lines
        draw.line([(pos, 0), (pos, preview_size)], fill=(64, 64, 64))
        # Horizontal lines
        draw.line([(0, pos), (preview_size, pos)], fill=(64, 64, 64))

    # Mark used cells
    for entity_key, coord in coordinates.items():
        x = coord['x'] * tile_preview_size
        y = coord['y'] * tile_preview_size

        # Check if sprite exists
        sprite_path = find_sprite(entity_key)
        if sprite_path and sprite_path.exists():
            color = (0, 128, 0)  # Green for found
        else:
            color = (128, 0, 0)  # Red for missing

        draw.rectangle(
            [x + 1, y + 1, x + tile_preview_size - 1, y + tile_preview_size - 1],
            fill=color
        )

    # Add row labels
    row_labels = [
        "0-1: Floors (Light)",
        "2-3: Floors (Dark)",
        "4-5: Doors",
        "6-7: Stairs/Forges",
        "8-9: Traps",
        "10-11: Special",
        "12-13: Players",
        "14-15: Effects",
        "16-17: Monsters L1",
        "18: Monsters L2",
        "19: Monsters L3",
        "20: Monsters L4",
        "21: Monsters L5",
        "22: Monsters L6-7",
        "23: Special Monsters",
        "24-27: Equipment",
        "28-29: Consumables",
        "30: Misc Items",
        "31: Artifacts"
    ]

    preview.save(output_path.with_suffix('.preview.png'))
    print(f"Preview saved to: {output_path.with_suffix('.preview.png')}")


def validate_all():
    """Validate all sprites in staging directory."""
    print("Validating all sprites in staging/...")

    issues = []
    total = 0

    for category_dir in STAGING_DIR.iterdir():
        if not category_dir.is_dir():
            continue

        for sprite_file in category_dir.glob('*.png'):
            total += 1
            valid, msg = validate_sprite(sprite_file)
            if not valid:
                issues.append(f"{sprite_file.relative_to(STAGING_DIR)}: {msg}")

    print(f"\nValidated {total} sprites")
    print(f"Issues found: {len(issues)}")

    if issues:
        print("\nIssues:")
        for issue in issues[:20]:  # Show first 20
            print(f"  - {issue}")
        if len(issues) > 20:
            print(f"  ... and {len(issues) - 20} more")

    return len(issues) == 0


def main():
    parser = argparse.ArgumentParser(description='Necromancer Tileset Assembler')
    parser.add_argument('--output', type=str, help='Custom output path')
    parser.add_argument('--preview', action='store_true', help='Generate preview image')
    parser.add_argument('--validate', action='store_true', help='Validate all sprites')
    parser.add_argument('--no-placeholders', action='store_true',
                       help='Do not include placeholders for missing sprites')

    args = parser.parse_args()

    output_path = Path(args.output) if args.output else OUTPUT_PATH

    if args.validate:
        validate_all()
        return

    if args.preview:
        generate_preview(output_path)
        return

    # Assemble tileset
    stats = assemble_tileset(output_path, missing_placeholder=not args.no_placeholders)

    # Generate preview too
    generate_preview(output_path)

    # Summary
    print("\n" + "=" * 60)
    print("ASSEMBLY COMPLETE")
    print("=" * 60)
    print(f"Output: {output_path}")
    print(f"Size: {TILESET_SIZE}x{TILESET_SIZE} pixels")
    print(f"Grid: {GRID_SIZE}x{GRID_SIZE} tiles")
    print(f"Sprites: {stats['found']}/{stats['total']} ({100*stats['found']/stats['total']:.1f}%)")

    if stats['errors']:
        print(f"\nErrors ({len(stats['errors'])}):")
        for err in stats['errors'][:10]:
            print(f"  - {err}")


if __name__ == "__main__":
    main()
