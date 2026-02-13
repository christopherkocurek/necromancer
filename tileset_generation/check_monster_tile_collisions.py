#!/usr/bin/env python3
"""
Validate monster atlas coordinate mappings in tile_mapper.gd.
Fails if any two monster IDs map to the same (x,y) atlas cell.

Usage:
  python3 tileset_generation/check_monster_tile_collisions.py
  python3 tileset_generation/check_monster_tile_collisions.py --json

Exit codes:
  0: no collisions
  1: collisions detected or parse failure
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
TILE_MAPPER = PROJECT_DIR / "scripts" / "core" / "tile_mapper.gd"

PATTERN = re.compile(
    r"monster_coords\[(\d+)\]\s*=\s*Vector2i\((\d+),\s*(\d+)\)"
)


def parse_monster_coords(path: Path) -> dict[int, tuple[int, int]]:
    content = path.read_text()
    matches = PATTERN.findall(content)
    coords: dict[int, tuple[int, int]] = {}
    for mid_s, x_s, y_s in matches:
        coords[int(mid_s)] = (int(x_s), int(y_s))
    return coords


def find_collisions(coords: dict[int, tuple[int, int]]) -> dict[tuple[int, int], list[int]]:
    by_cell: dict[tuple[int, int], list[int]] = defaultdict(list)
    for mid, cell in coords.items():
        by_cell[cell].append(mid)
    return {cell: sorted(ids) for cell, ids in by_cell.items() if len(ids) > 1}


def main() -> int:
    parser = argparse.ArgumentParser(description="Check monster atlas coordinate collisions")
    parser.add_argument("--json", action="store_true", help="Output machine-readable JSON")
    args = parser.parse_args()

    if not TILE_MAPPER.exists():
        print(f"ERROR: Missing tile mapper: {TILE_MAPPER}")
        return 1

    coords = parse_monster_coords(TILE_MAPPER)
    if not coords:
        print("ERROR: No monster_coords found in tile_mapper.gd")
        return 1

    collisions = find_collisions(coords)

    if args.json:
        payload = {
            "monster_count": len(coords),
            "collision_count": len(collisions),
            "collisions": [
                {"cell": [x, y], "monster_ids": ids}
                for (x, y), ids in sorted(collisions.items(), key=lambda kv: (kv[0][1], kv[0][0]))
            ],
        }
        print(json.dumps(payload, indent=2))
        return 1 if collisions else 0

    print(f"Monster mapping entries: {len(coords)}")
    if not collisions:
        print("OK: No atlas coordinate collisions in monster_coords.")
        return 0

    print(f"FAIL: {len(collisions)} collision cell(s) found:")
    for (x, y), ids in sorted(collisions.items(), key=lambda kv: (kv[0][1], kv[0][0])):
        print(f"  cell ({x}, {y}) <- IDs {ids}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
