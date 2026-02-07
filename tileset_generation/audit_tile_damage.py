#!/usr/bin/env python3
"""
Tileset BG Removal Damage Auditor
Scans every non-empty tile in the necromancer tileset for signs of
over-aggressive background removal: interior holes, excessive transparency,
fragmentation, residual magenta, and edge thinning.
"""

import colorsys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

# --- Configuration ---
TILESET_PATH = Path(__file__).parent.parent / "assets" / "sprites" / "necromancer_dcss_tileset.png"
TILE_SIZE = 64
GRID_COLS = 32
GRID_ROWS = 32

# Thresholds
INTERIOR_HOLE_NEIGHBOR_THRESHOLD = 6   # transparent pixel with >= N opaque neighbors
INTERIOR_HOLE_HIGH = 50                # HIGH severity if > N interior holes
INTERIOR_HOLE_MEDIUM = 15             # MEDIUM severity if > N interior holes
INTERIOR_HOLE_LOW = 5                 # LOW severity if > N interior holes

TRANSPARENCY_ENTITY_HIGH = 0.85       # > 85% transparent for entity tiles = HIGH
TRANSPARENCY_ENTITY_MEDIUM = 0.70     # > 70% transparent = MEDIUM

FRAGMENT_HIGH = 10                    # > 10 disconnected regions = HIGH
FRAGMENT_MEDIUM = 5                   # > 5 = MEDIUM

MAGENTA_HIGH = 0.05                   # > 5% magenta pixels = HIGH
MAGENTA_MEDIUM = 0.02                 # > 2% magenta pixels = MEDIUM

THIN_THRESHOLD = 20                   # bounding box dimension < 20px = thinned
THIN_THRESHOLD_HIGH = 12              # < 12px = HIGH severity

# Empty tile threshold: if fewer than this many opaque pixels, consider tile empty
EMPTY_THRESHOLD = 10


def get_tile_category(col: int, row: int) -> str:
    """Categorize a tile by its grid position."""
    if row <= 5:
        return "Terrain"
    if row in (6, 7) and col <= 11:
        return "Player"
    if row in (8, 9) and col <= 11:
        return "Player"
    if row == 10:
        return "Effect"
    if 11 <= row <= 17:
        return "Item"
    if row == 18:
        return "Terrain"
    if row == 19 and col <= 18:
        return "Artefact"
    if 24 <= row <= 26:
        return "Monster"
    # Rows 20-23, 27-31, or row 19 col>18: likely empty/unused
    return "Unused"


def should_skip_tile(col: int, row: int) -> bool:
    """Check if tile should be skipped from analysis."""
    # Skip terrain dark variant tiles (odd columns in rows 0-5)
    if row <= 5 and col % 2 == 1:
        return True
    return False


def is_entity_tile(category: str) -> bool:
    """Entity tiles have stricter transparency thresholds."""
    return category in ("Player", "Item", "Artefact", "Monster", "Effect")


def count_interior_holes(alpha: np.ndarray) -> int:
    """
    Count transparent pixels surrounded by non-transparent pixels.
    A transparent pixel (alpha=0) with >= INTERIOR_HOLE_NEIGHBOR_THRESHOLD
    non-transparent (alpha>0) neighbors out of 8.
    """
    opaque = (alpha > 0).astype(np.int32)
    h, w = opaque.shape

    # Pad the array to handle borders
    padded = np.pad(opaque, 1, mode='constant', constant_values=0)

    # Count opaque neighbors for each pixel (8-connectivity)
    neighbor_count = np.zeros_like(opaque, dtype=np.int32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy == 0 and dx == 0:
                continue
            neighbor_count += padded[1+dy:h+1+dy, 1+dx:w+1+dx]

    # Interior holes: transparent pixels with many opaque neighbors
    transparent = (alpha == 0)
    interior_holes = transparent & (neighbor_count >= INTERIOR_HOLE_NEIGHBOR_THRESHOLD)
    return int(np.sum(interior_holes))


def count_fragments(alpha: np.ndarray) -> int:
    """
    Count disconnected non-transparent pixel clusters using flood fill (4-connectivity).
    Returns the number of connected components.
    """
    opaque = (alpha > 0)
    h, w = opaque.shape
    visited = np.zeros_like(opaque, dtype=bool)
    count = 0

    for y in range(h):
        for x in range(w):
            if opaque[y, x] and not visited[y, x]:
                # BFS flood fill
                count += 1
                queue = deque()
                queue.append((y, x))
                visited[y, x] = True
                while queue:
                    cy, cx = queue.popleft()
                    for dy, dx in ((-1,0),(1,0),(0,-1),(0,1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < h and 0 <= nx < w and opaque[ny, nx] and not visited[ny, nx]:
                            visited[ny, nx] = True
                            queue.append((ny, nx))

    return count


def count_magenta_pixels(rgba: np.ndarray) -> int:
    """
    Count pixels in the magenta/pink HSV range.
    Hue 280-340 deg (normalized 0.778-0.944), saturation > 0.3, value > 0.3.
    Only counts opaque pixels (alpha > 0).
    """
    count = 0
    h, w, _ = rgba.shape
    for y in range(h):
        for x in range(w):
            r, g, b, a = rgba[y, x]
            if a == 0:
                continue
            # Normalize to 0-1
            rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
            hue, sat, val = colorsys.rgb_to_hsv(rf, gf, bf)
            # Hue in [0,1], 280/360=0.778, 340/360=0.944
            if 0.778 <= hue <= 0.944 and sat > 0.3 and val > 0.3:
                count += 1
    return count


def get_bounding_box(alpha: np.ndarray):
    """Get bounding box of non-transparent pixels. Returns (width, height) or (0,0) if empty."""
    opaque_coords = np.argwhere(alpha > 0)
    if len(opaque_coords) == 0:
        return 0, 0
    min_y, min_x = opaque_coords.min(axis=0)
    max_y, max_x = opaque_coords.max(axis=0)
    return int(max_x - min_x + 1), int(max_y - min_y + 1)


def analyze_tile(tile_rgba: np.ndarray, col: int, row: int) -> dict | None:
    """
    Analyze a single tile for BG removal damage.
    Returns a dict with findings, or None if tile passes all checks.
    """
    category = get_tile_category(col, row)
    alpha = tile_rgba[:, :, 3]
    total_pixels = TILE_SIZE * TILE_SIZE
    opaque_count = int(np.sum(alpha > 0))

    # Skip empty tiles
    if opaque_count < EMPTY_THRESHOLD:
        return None

    # Skip unused tiles
    if category == "Unused":
        return None

    is_entity = is_entity_tile(category)
    is_terrain = (category == "Terrain")

    findings = {
        "col": col,
        "row": row,
        "category": category,
        "issues": [],
        "severity": "LOW",
        "interior_holes": 0,
        "transparency_pct": 0.0,
        "fragment_count": 0,
        "magenta_pct": 0.0,
        "bbox_w": 0,
        "bbox_h": 0,
        "opaque_pixels": opaque_count,
    }

    # 1. Interior transparency holes
    holes = count_interior_holes(alpha)
    findings["interior_holes"] = holes
    if holes > INTERIOR_HOLE_HIGH:
        findings["issues"].append(("Interior holes", "HIGH", f"{holes} holes"))
    elif holes > INTERIOR_HOLE_MEDIUM:
        findings["issues"].append(("Interior holes", "MEDIUM", f"{holes} holes"))
    elif holes > INTERIOR_HOLE_LOW:
        findings["issues"].append(("Interior holes", "LOW", f"{holes} holes"))

    # 2. Excessive transparency ratio (entity tiles only)
    transparency = 1.0 - (opaque_count / total_pixels)
    findings["transparency_pct"] = round(transparency * 100, 1)
    if is_entity:
        if transparency > TRANSPARENCY_ENTITY_HIGH:
            findings["issues"].append(("Excessive transparency", "HIGH", f"{findings['transparency_pct']}%"))
        elif transparency > TRANSPARENCY_ENTITY_MEDIUM:
            findings["issues"].append(("Excessive transparency", "MEDIUM", f"{findings['transparency_pct']}%"))

    # 3. Fragment count (skip for terrain — terrain may legitimately have disconnected features)
    if is_entity:
        fragments = count_fragments(alpha)
        findings["fragment_count"] = fragments
        if fragments > FRAGMENT_HIGH:
            findings["issues"].append(("Fragmented sprite", "HIGH", f"{fragments} regions"))
        elif fragments > FRAGMENT_MEDIUM:
            findings["issues"].append(("Fragmented sprite", "MEDIUM", f"{fragments} regions"))
    else:
        # Still count for reporting but don't flag
        fragments = count_fragments(alpha)
        findings["fragment_count"] = fragments

    # 4. Residual magenta contamination (entity tiles primarily)
    if is_entity and opaque_count > 0:
        magenta_count = count_magenta_pixels(tile_rgba)
        magenta_pct = magenta_count / opaque_count
        findings["magenta_pct"] = round(magenta_pct * 100, 2)
        if magenta_pct > MAGENTA_HIGH:
            findings["issues"].append(("Magenta contamination", "HIGH", f"{findings['magenta_pct']}%"))
        elif magenta_pct > MAGENTA_MEDIUM:
            findings["issues"].append(("Magenta contamination", "MEDIUM", f"{findings['magenta_pct']}%"))

    # 5. Edge thinning (entity tiles)
    bbox_w, bbox_h = get_bounding_box(alpha)
    findings["bbox_w"] = bbox_w
    findings["bbox_h"] = bbox_h
    if is_entity:
        min_dim = min(bbox_w, bbox_h)
        if min_dim < THIN_THRESHOLD_HIGH:
            findings["issues"].append(("Edge thinning", "HIGH", f"bbox {bbox_w}x{bbox_h}"))
        elif min_dim < THIN_THRESHOLD:
            findings["issues"].append(("Edge thinning", "MEDIUM", f"bbox {bbox_w}x{bbox_h}"))

    if not findings["issues"]:
        return None

    # Determine overall severity
    severities = [issue[1] for issue in findings["issues"]]
    if "HIGH" in severities:
        findings["severity"] = "HIGH"
    elif "MEDIUM" in severities:
        findings["severity"] = "MEDIUM"
    else:
        findings["severity"] = "LOW"

    return findings


def main():
    print(f"Loading tileset: {TILESET_PATH}")
    img = Image.open(TILESET_PATH).convert("RGBA")
    data = np.array(img)
    print(f"Tileset size: {img.size[0]}x{img.size[1]}, Grid: {GRID_COLS}x{GRID_ROWS} tiles of {TILE_SIZE}x{TILE_SIZE}px\n")

    flagged_tiles = []
    total_tiles = 0
    empty_tiles = 0
    skipped_tiles = 0
    clean_tiles = 0

    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            if should_skip_tile(col, row):
                skipped_tiles += 1
                continue

            total_tiles += 1
            y0 = row * TILE_SIZE
            x0 = col * TILE_SIZE
            tile = data[y0:y0+TILE_SIZE, x0:x0+TILE_SIZE]

            alpha = tile[:, :, 3]
            opaque = int(np.sum(alpha > 0))
            if opaque < EMPTY_THRESHOLD:
                empty_tiles += 1
                continue

            result = analyze_tile(tile, col, row)
            if result:
                flagged_tiles.append(result)
            else:
                clean_tiles += 1

        # Progress indicator per row
        if row % 4 == 3:
            print(f"  Scanned rows 0-{row}... ({len(flagged_tiles)} issues found so far)")

    # Sort by severity (HIGH > MEDIUM > LOW), then row, then col
    severity_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    flagged_tiles.sort(key=lambda f: (severity_order[f["severity"]], f["row"], f["col"]))

    # --- Report ---
    print("\n" + "=" * 100)
    print("TILESET BG REMOVAL DAMAGE AUDIT REPORT")
    print("=" * 100)
    print(f"\nTotal tiles scanned: {total_tiles}")
    print(f"Empty tiles (skipped): {empty_tiles}")
    print(f"Dark-variant terrain tiles (skipped): {skipped_tiles}")
    print(f"Clean tiles (no issues): {clean_tiles}")
    print(f"Flagged tiles: {len(flagged_tiles)}")

    high_count = sum(1 for f in flagged_tiles if f["severity"] == "HIGH")
    med_count = sum(1 for f in flagged_tiles if f["severity"] == "MEDIUM")
    low_count = sum(1 for f in flagged_tiles if f["severity"] == "LOW")
    print(f"  HIGH: {high_count}  |  MEDIUM: {med_count}  |  LOW: {low_count}")

    # Group by category
    categories = {}
    for f in flagged_tiles:
        cat = f["category"]
        if cat not in categories:
            categories[cat] = {"HIGH": 0, "MEDIUM": 0, "LOW": 0}
        categories[cat][f["severity"]] += 1

    if categories:
        print("\nBy Category:")
        for cat in sorted(categories.keys()):
            counts = categories[cat]
            print(f"  {cat:12s}  HIGH: {counts['HIGH']:3d}  MEDIUM: {counts['MEDIUM']:3d}  LOW: {counts['LOW']:3d}")

    if flagged_tiles:
        print("\n" + "-" * 100)
        print("FLAGGED TILES (sorted by severity, then position)")
        print("-" * 100)

        current_severity = None
        for f in flagged_tiles:
            if f["severity"] != current_severity:
                current_severity = f["severity"]
                print(f"\n{'='*20} {current_severity} SEVERITY {'='*20}")

            issues_str = " | ".join(
                f"{name} [{sev}]: {detail}" for name, sev, detail in f["issues"]
            )
            print(f"\n  ({f['col']:2d},{f['row']:2d}) {f['category']:10s}  "
                  f"[{f['severity']}]")
            print(f"    Issues: {issues_str}")
            print(f"    Holes: {f['interior_holes']:4d}  "
                  f"Transp: {f['transparency_pct']:5.1f}%  "
                  f"Fragments: {f['fragment_count']:3d}  "
                  f"Magenta: {f['magenta_pct']:5.2f}%  "
                  f"BBox: {f['bbox_w']}x{f['bbox_h']}  "
                  f"Opaque: {f['opaque_pixels']}")

    # Summary of worst offenders
    if high_count > 0:
        print("\n" + "=" * 100)
        print("TOP PRIORITY FIXES (HIGH severity)")
        print("=" * 100)
        for f in flagged_tiles:
            if f["severity"] != "HIGH":
                break
            issues_brief = ", ".join(f"{name}" for name, sev, detail in f["issues"] if sev == "HIGH")
            print(f"  ({f['col']:2d},{f['row']:2d}) {f['category']:10s}  -> {issues_brief}")

    print("\n" + "=" * 100)
    print("AUDIT COMPLETE")
    print("=" * 100)


if __name__ == "__main__":
    main()
