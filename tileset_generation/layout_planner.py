#!/usr/bin/env python3
"""
Necromancer Tileset - Layout Planner
Assigns coordinates to each entity in the 32x32 tileset grid.

Usage: python layout_planner.py
"""

import json
from pathlib import Path
from typing import Dict, List, Tuple, Set
from datetime import datetime

OUTPUT_DIR = Path(__file__).parent


def load_manifest() -> Dict:
    """Load the manifest.json file."""
    manifest_path = OUTPUT_DIR / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError("manifest.json not found. Run extract_manifest.py first.")

    with open(manifest_path, 'r') as f:
        return json.load(f)


class LayoutPlanner:
    """Plans tileset layout with collision detection."""

    def __init__(self, grid_size: int = 32):
        self.grid_size = grid_size
        self.layout_map: Dict[str, Dict] = {}
        self.used_coords: Set[Tuple[int, int]] = set()
        self.current_x = 0
        self.current_y = 0

    def assign(self, entity_key: str, x: int, y: int) -> bool:
        """Assign a coordinate, checking bounds and collisions."""
        if x < 0 or x >= self.grid_size or y < 0 or y >= self.grid_size:
            print(f"  WARNING: Out of bounds ({x}, {y}) for {entity_key}")
            return False

        coord = (x, y)
        if coord in self.used_coords:
            print(f"  WARNING: Collision at ({x}, {y}) for {entity_key}")
            return False

        self.used_coords.add(coord)
        self.layout_map[entity_key] = {"x": x, "y": y}
        return True

    def next_pos(self) -> Tuple[int, int]:
        """Get next available position, auto-advancing."""
        while (self.current_x, self.current_y) in self.used_coords:
            self.current_x += 1
            if self.current_x >= self.grid_size:
                self.current_x = 0
                self.current_y += 1

        x, y = self.current_x, self.current_y
        self.current_x += 1
        if self.current_x >= self.grid_size:
            self.current_x = 0
            self.current_y += 1
        return x, y

    def set_row(self, row: int):
        """Move to start of a specific row."""
        self.current_x = 0
        self.current_y = row

    def fill_sequential(self, keys: List[str], start_row: int) -> int:
        """Fill sprites sequentially from a starting row. Returns next available row."""
        self.set_row(start_row)
        for key in keys:
            x, y = self.next_pos()
            self.assign(key, x, y)
        # Return the row after the last used row
        return self.current_y if self.current_x == 0 else self.current_y + 1


def plan_layout(manifest: Dict) -> Dict[str, Dict]:
    """
    Plan the tileset layout.

    Compact Layout (32x32 = 1024 tiles, 682 needed):

    Rows 0-5:   Terrain (176 sprites = 5.5 rows)
    Rows 6-7:   Players (12) + Effects (20) = 32 sprites
    Rows 8-10:  Monsters (73 sprites = 2.3 rows)
    Rows 11-23: Items (254 sprites = 8 rows)
    Rows 24-31: Artifacts (147 sprites = 4.6 rows)

    This gives us ~682 sprites with some room to spare.
    """

    planner = LayoutPlanner(32)

    # =========================================================================
    # TERRAIN (Rows 0-5, ~176 sprites)
    # =========================================================================
    print("Planning terrain layout...")

    terrain = manifest['categories']['terrain']

    # All terrain in sequential order (light/dark variants already paired in manifest)
    terrain_keys = []
    for t in terrain:
        variant = t.get('variant', 'light')
        terrain_keys.append(f"terrain_{t['id']}_{variant}")

    next_row = planner.fill_sequential(terrain_keys, start_row=0)
    print(f"  Terrain complete: {len(terrain_keys)} sprites, rows 0-{next_row - 1}")

    # =========================================================================
    # PLAYERS & EFFECTS (Rows 6-7)
    # =========================================================================
    print("Planning player and effect layout...")

    # Ensure we start at row 6
    planner.set_row(6)

    # Players
    player_keys = [f"player_{p['id']}" for p in manifest['categories']['players']]
    for key in player_keys:
        x, y = planner.next_pos()
        planner.assign(key, x, y)

    # Effects
    effect_keys = [f"effect_{e['id']}" for e in manifest['categories']['effects']]
    for key in effect_keys:
        x, y = planner.next_pos()
        planner.assign(key, x, y)

    next_row = planner.current_y if planner.current_x == 0 else planner.current_y + 1
    print(f"  Players/Effects complete: {len(player_keys) + len(effect_keys)} sprites, ending row {next_row - 1}")

    # =========================================================================
    # MONSTERS (Rows 8-10, ~73 sprites)
    # =========================================================================
    print("Planning monster layout...")

    planner.set_row(8)

    # Sort monsters by layer for visual organization
    monsters = sorted(manifest['categories']['monsters'], key=lambda m: (m.get('layer', 0), m['id']))
    monster_keys = [f"monster_{m['id']}" for m in monsters]

    for key in monster_keys:
        x, y = planner.next_pos()
        planner.assign(key, x, y)

    next_row = planner.current_y if planner.current_x == 0 else planner.current_y + 1
    print(f"  Monsters complete: {len(monster_keys)} sprites, ending row {next_row - 1}")

    # =========================================================================
    # ITEMS (continuing from where monsters end, ~254 sprites = ~8 rows)
    # =========================================================================
    print("Planning item layout...")

    # Start from next row after monsters
    if planner.current_x != 0:
        planner.set_row(planner.current_y + 1)

    items = manifest['categories']['items']
    item_keys = [f"item_{i['id']}" for i in items]

    for key in item_keys:
        x, y = planner.next_pos()
        planner.assign(key, x, y)

    next_row = planner.current_y if planner.current_x == 0 else planner.current_y + 1
    print(f"  Items complete: {len(item_keys)} sprites, ending row {next_row - 1}")

    # =========================================================================
    # ARTIFACTS (continuing from where items end, ~147 sprites = ~5 rows)
    # =========================================================================
    print("Planning artifact layout...")

    if planner.current_x != 0:
        planner.set_row(planner.current_y + 1)

    artifacts = manifest['categories']['artifacts']
    artifact_keys = [f"artifact_{a['id']}" for a in artifacts]

    for key in artifact_keys:
        x, y = planner.next_pos()
        planner.assign(key, x, y)

    final_row = planner.current_y if planner.current_x == 0 else planner.current_y + 1
    print(f"  Artifacts complete: {len(artifact_keys)} sprites, ending row {final_row - 1}")

    return planner.layout_map


def main():
    print("=" * 60)
    print("Necromancer Tileset - Layout Planning")
    print("=" * 60)

    manifest = load_manifest()
    print(f"Loaded manifest with {manifest['total_sprites']} sprites")
    print(f"Grid capacity: {32 * 32} = 1024 tiles")
    print()

    layout_map = plan_layout(manifest)

    # Validate
    print("\nValidating layout...")

    assigned_count = len(layout_map)
    expected_count = manifest['total_sprites']

    print(f"Assigned coordinates: {assigned_count}")
    print(f"Expected: {expected_count}")

    if assigned_count < expected_count:
        print(f"WARNING: {expected_count - assigned_count} entities without coordinates!")

    # Check coordinate bounds
    out_of_bounds = []
    max_row = 0
    for key, coord in layout_map.items():
        if coord['x'] < 0 or coord['x'] >= 32 or coord['y'] < 0 or coord['y'] >= 32:
            out_of_bounds.append((key, coord))
        max_row = max(max_row, coord['y'])

    if out_of_bounds:
        print(f"ERROR: {len(out_of_bounds)} coordinates out of bounds!")
        for key, coord in out_of_bounds[:5]:
            print(f"  {key}: ({coord['x']}, {coord['y']})")
    else:
        print("All coordinates within bounds!")

    print(f"Highest row used: {max_row} (max 31)")

    # Save layout map
    layout_path = OUTPUT_DIR / "layout_map.json"
    with open(layout_path, 'w') as f:
        json.dump({
            'version': '1.0',
            'created_at': datetime.now().isoformat(),
            'grid_size': 32,
            'tile_size': 64,
            'total_entries': len(layout_map),
            'max_row_used': max_row,
            'coordinates': layout_map
        }, f, indent=2)

    print(f"\nLayout map saved to: {layout_path}")

    # Generate row summary
    row_usage = {}
    for key, coord in layout_map.items():
        row = coord['y']
        row_usage[row] = row_usage.get(row, 0) + 1

    print("\nRow usage summary:")
    print("-" * 50)
    for row in sorted(row_usage.keys()):
        bar = '#' * min(row_usage[row], 32)
        category = ""
        if row < 6:
            category = "(terrain)"
        elif row < 8:
            category = "(players/effects)"
        elif row < 11:
            category = "(monsters)"
        elif row < 20:
            category = "(items)"
        else:
            category = "(artifacts)"
        print(f"Row {row:2d}: {row_usage[row]:3d} tiles | {bar} {category}")

    print("\nDone!")


if __name__ == "__main__":
    main()
