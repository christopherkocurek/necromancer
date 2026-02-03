#!/usr/bin/env python3
"""
Aggressive Magenta/Pink Background Removal for Sprite Tiles.

This script removes magenta (#FF00FF) and pink variant backgrounds from
all sprites in lib/xtra/graf/final/. It uses multiple approaches:
1. Sample corner pixels to detect actual background color
2. Color distance from detected background and pure magenta
3. Flood-fill from edges to remove connected background
4. Heuristic for pink/mauve variants
"""

import os
import sys
from pathlib import Path
from PIL import Image
import numpy as np
from collections import defaultdict, Counter

# Configuration
SPRITE_DIR = Path(__file__).parent.parent.parent / "lib" / "xtra" / "graf" / "final"
BACKUP_DIR = Path(__file__).parent.parent.parent / "lib" / "xtra" / "graf" / "backup_originals"

# Pure magenta RGB
MAGENTA = np.array([255, 0, 255])

# Known problematic background colors (dusty mauve from DALL-E compression)
KNOWN_BG_COLORS = [
    np.array([135, 67, 97]),   # Dusty mauve (common in player/monster sprites)
    np.array([136, 67, 97]),   # Variant
    np.array([134, 67, 97]),   # Variant
    np.array([135, 66, 97]),   # Variant
    np.array([255, 0, 255]),   # Pure magenta
]

# Thresholds for detection
COLOR_TOLERANCE = 15  # Euclidean distance tolerance for background matching
MAGENTA_DISTANCE_THRESHOLD = 80  # Color distance from pure magenta
PINK_R_MIN = 120  # Lowered - Minimum red for pink detection
PINK_G_MAX = 100  # Maximum green for pink detection
PINK_B_MIN = 80   # Lowered - Minimum blue for pink detection
EDGE_ALPHA_THRESHOLD = 200  # Alpha below this at edges is suspicious


def color_distance(color, target):
    """Calculate Euclidean distance between two RGB colors."""
    return np.sqrt(np.sum((color.astype(float) - target.astype(float)) ** 2))


def is_magenta_variant(r, g, b, detected_bg=None):
    """Check if a color is magenta or a pink variant."""
    color = np.array([r, g, b])

    # Method 0: Check against detected background color for this image
    if detected_bg is not None:
        if color_distance(color, detected_bg) < COLOR_TOLERANCE:
            return True

    # Method 1: Check against known problematic background colors
    for known_bg in KNOWN_BG_COLORS:
        if color_distance(color, known_bg) < COLOR_TOLERANCE:
            return True

    # Method 2: Distance from pure magenta
    if color_distance(color, MAGENTA) < MAGENTA_DISTANCE_THRESHOLD:
        return True

    # Method 3: Pink/mauve heuristic (moderate R, low G, moderate B)
    # Catches dusty pink/mauve colors like RGB(135, 67, 97)
    if r >= PINK_R_MIN and g <= PINK_G_MAX and b >= PINK_B_MIN:
        # Additional check: R and B should be notably higher than G
        if r > g * 1.3 and b > g * 0.9:
            return True

    # Method 4: Very saturated magenta/pink (R and B similar, G much lower)
    if int(r) > 120 and int(b) > 80 and int(g) < 100:
        rb_avg = (int(r) + int(b)) / 2
        if int(g) < rb_avg * 0.6:  # Green is less than 60% of the R/B average
            return True

    return False


def detect_background_color(data):
    """
    Detect the most likely background color by sampling edges.
    Returns the most common non-transparent color found on the edges.
    """
    height, width = data.shape[:2]
    edge_colors = []

    # Sample from all edges (top, bottom, left, right rows/cols)
    for x in range(width):
        # Top edge
        r, g, b, a = data[0, x]
        if a > 0:
            edge_colors.append((r, g, b))
        # Bottom edge
        r, g, b, a = data[height-1, x]
        if a > 0:
            edge_colors.append((r, g, b))

    for y in range(height):
        # Left edge
        r, g, b, a = data[y, 0]
        if a > 0:
            edge_colors.append((r, g, b))
        # Right edge
        r, g, b, a = data[y, width-1]
        if a > 0:
            edge_colors.append((r, g, b))

    if not edge_colors:
        return None

    # Find the most common edge color
    color_counts = Counter(edge_colors)
    most_common = color_counts.most_common(1)[0][0]

    # Only return if it appears frequently (at least 10% of edge pixels)
    if color_counts[most_common] >= len(edge_colors) * 0.1:
        return np.array(most_common)

    return None


def remove_magenta_background(img_path, aggressive=True):
    """
    Remove magenta/pink background from a sprite image.

    Args:
        img_path: Path to the PNG image
        aggressive: If True, use more aggressive detection

    Returns:
        Tuple of (modified_image, pixels_changed)
    """
    img = Image.open(img_path).convert("RGBA")
    data = np.array(img)

    original_data = data.copy()
    pixels_changed = 0

    height, width = data.shape[:2]

    # Detect the background color for this specific image
    detected_bg = detect_background_color(data)

    # Create a mask for pixels to make transparent
    mask = np.zeros((height, width), dtype=bool)

    for y in range(height):
        for x in range(width):
            r, g, b, a = data[y, x]

            # Skip already transparent pixels
            if a == 0:
                continue

            # Check if this pixel is a magenta/pink variant
            if is_magenta_variant(r, g, b, detected_bg):
                mask[y, x] = True
                pixels_changed += 1

    if aggressive:
        # Pass 2: Check edges for semi-transparent pink halos
        # Often DALL-E creates anti-aliased edges with pink tints
        for y in range(height):
            for x in range(width):
                r, g, b, a = data[y, x]

                # Skip fully transparent or already marked
                if a == 0 or mask[y, x]:
                    continue

                # Check if near an already-masked pixel (within 2px)
                is_near_mask = False
                for dy in range(-2, 3):
                    for dx in range(-2, 3):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < height and 0 <= nx < width:
                            if mask[ny, nx]:
                                is_near_mask = True
                                break
                    if is_near_mask:
                        break

                if is_near_mask:
                    # More lenient check for edge pixels with detected bg
                    if detected_bg is not None:
                        color = np.array([r, g, b])
                        if color_distance(color, detected_bg) < COLOR_TOLERANCE * 1.5:
                            mask[y, x] = True
                            pixels_changed += 1
                            continue

                    # Pink-ish and semi-transparent = probably halo
                    if r > 120 and b > 80 and g < r and g < b:
                        if a < 250:  # Semi-transparent
                            mask[y, x] = True
                            pixels_changed += 1
                        elif r > 150 and b > 100 and g < 100:
                            # Strong pink even if opaque
                            mask[y, x] = True
                            pixels_changed += 1

    # Apply the mask - set marked pixels to fully transparent
    data[mask] = [0, 0, 0, 0]

    result = Image.fromarray(data, "RGBA")
    return result, pixels_changed


def flood_fill_from_corners(img_path):
    """
    Alternative approach: flood fill from corners assuming background.
    Removes connected regions of magenta-ish colors starting from corners.
    Detects the background color from edge pixels first.
    """
    img = Image.open(img_path).convert("RGBA")
    data = np.array(img)
    height, width = data.shape[:2]

    # Detect background color for this image
    detected_bg = detect_background_color(data)

    visited = np.zeros((height, width), dtype=bool)
    to_remove = np.zeros((height, width), dtype=bool)

    # Start from all four corners
    corners = [(0, 0), (0, width-1), (height-1, 0), (height-1, width-1)]

    # Also start from edges
    edges = []
    for x in range(width):
        edges.append((0, x))
        edges.append((height-1, x))
    for y in range(height):
        edges.append((y, 0))
        edges.append((y, width-1))

    stack = list(set(corners + edges))

    while stack:
        y, x = stack.pop()

        if y < 0 or y >= height or x < 0 or x >= width:
            continue
        if visited[y, x]:
            continue

        visited[y, x] = True
        r, g, b, a = data[y, x]

        # Skip transparent pixels but allow flood through them
        if a == 0:
            # Still add neighbors to allow traversal
            for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ny, nx = y + dy, x + dx
                if 0 <= ny < height and 0 <= nx < width and not visited[ny, nx]:
                    stack.append((ny, nx))
            continue

        # Check if this is a magenta variant (using detected bg)
        if is_magenta_variant(r, g, b, detected_bg):
            to_remove[y, x] = True
            # Add neighbors
            for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ny, nx = y + dy, x + dx
                if 0 <= ny < height and 0 <= nx < width and not visited[ny, nx]:
                    stack.append((ny, nx))

    pixels_changed = int(np.sum(to_remove))
    data[to_remove] = [0, 0, 0, 0]

    result = Image.fromarray(data, "RGBA")
    return result, pixels_changed


def process_all_sprites(dry_run=False, backup=True):
    """Process all sprites in the final directory."""

    if not SPRITE_DIR.exists():
        print(f"Error: Sprite directory not found: {SPRITE_DIR}")
        return

    # Find all PNG files
    png_files = list(SPRITE_DIR.rglob("*.png"))
    print(f"Found {len(png_files)} sprites to process")

    if backup and not dry_run:
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        print(f"Backing up originals to: {BACKUP_DIR}")

    results = defaultdict(list)
    total_pixels_changed = 0

    for png_path in sorted(png_files):
        rel_path = png_path.relative_to(SPRITE_DIR)

        # Backup original
        if backup and not dry_run:
            backup_path = BACKUP_DIR / rel_path
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            if not backup_path.exists():
                import shutil
                shutil.copy2(png_path, backup_path)

        # Process with both methods and use the one that removes more
        img1, changed1 = remove_magenta_background(png_path, aggressive=True)
        img2, changed2 = flood_fill_from_corners(png_path)

        # Use the result that changed more pixels (more aggressive)
        if changed1 >= changed2:
            result_img, pixels_changed = img1, changed1
            method = "color-distance"
        else:
            result_img, pixels_changed = img2, changed2
            method = "flood-fill"

        if pixels_changed > 0:
            category = png_path.parent.name
            results[category].append((rel_path.name, pixels_changed, method))
            total_pixels_changed += pixels_changed

            if not dry_run:
                result_img.save(png_path)
                print(f"  ✓ {rel_path}: {pixels_changed} pixels ({method})")
            else:
                print(f"  [DRY] {rel_path}: would change {pixels_changed} pixels ({method})")
        else:
            print(f"  - {rel_path}: no changes needed")

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    for category, files in sorted(results.items()):
        cat_total = sum(p for _, p, _ in files)
        print(f"\n{category.upper()}: {len(files)} files, {cat_total} pixels")
        for name, pixels, method in files:
            print(f"  - {name}: {pixels} px ({method})")

    print(f"\n{'[DRY RUN] ' if dry_run else ''}Total: {total_pixels_changed} pixels changed across {sum(len(f) for f in results.values())} files")

    return results


def preview_single_sprite(sprite_path):
    """Preview changes for a single sprite without modifying it."""
    if not os.path.exists(sprite_path):
        print(f"File not found: {sprite_path}")
        return

    print(f"Analyzing: {sprite_path}")

    img1, changed1 = remove_magenta_background(sprite_path, aggressive=True)
    img2, changed2 = flood_fill_from_corners(sprite_path)

    print(f"  Color-distance method: {changed1} pixels")
    print(f"  Flood-fill method: {changed2} pixels")

    # Save previews
    base = Path(sprite_path).stem
    preview_dir = Path(sprite_path).parent / "preview"
    preview_dir.mkdir(exist_ok=True)

    img1.save(preview_dir / f"{base}_color_dist.png")
    img2.save(preview_dir / f"{base}_flood_fill.png")
    print(f"  Previews saved to: {preview_dir}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Remove magenta backgrounds from sprites")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without modifying files")
    parser.add_argument("--no-backup", action="store_true", help="Skip backing up original files")
    parser.add_argument("--preview", type=str, help="Preview a single sprite file")

    args = parser.parse_args()

    if args.preview:
        preview_single_sprite(args.preview)
    else:
        process_all_sprites(dry_run=args.dry_run, backup=not args.no_backup)
