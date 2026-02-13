#!/usr/bin/env python3
"""
Patch specific monster tiles into the main tileset without bulk re-integration.

This script is intentionally narrow:
- It pastes only the requested monster IDs.
- It does NOT clear rows.
- It does NOT rewrite tile_mapper.gd.
- It expects already-processed 64x64 sprites in monster_v3/tier_X/.

Usage:
  python3 patch_monster_tiles.py --ids 32 33 35 135
  python3 patch_monster_tiles.py --ids 32 33 --dry-run
"""

from __future__ import annotations

import argparse
import re
import shutil
from datetime import datetime
from pathlib import Path

from PIL import Image

import integrate_sprites_v2 as integ


def _sprite_path_for_monster(monster_id: int) -> Path:
    tier = integ.get_tier_for_monster(monster_id)
    return integ.MONSTER_DIR / f"tier_{tier}" / f"monster_{monster_id}_light.png"


def _backup_tileset_path() -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    return integ.TILESET_PATH.with_name(
        f"{integ.TILESET_PATH.stem}.monster_patch_backup_{ts}{integ.TILESET_PATH.suffix}"
    )


def _load_monster_coords_from_tile_mapper() -> dict[int, tuple[int, int]]:
    """Parse live monster atlas coords from tile_mapper.gd."""
    coords: dict[int, tuple[int, int]] = {}
    content = integ.TILE_MAPPER_PATH.read_text()
    pattern = re.compile(
        r"monster_coords\[(\d+)\]\s*=\s*Vector2i\(\s*(\d+)\s*,\s*(\d+)\s*\)"
    )
    for m in pattern.finditer(content):
        mid = int(m.group(1))
        x = int(m.group(2))
        y = int(m.group(3))
        coords[mid] = (x, y)
    return coords


def main() -> None:
    parser = argparse.ArgumentParser(description="Patch selected monster tiles into tileset")
    parser.add_argument("--ids", nargs="+", type=int, required=True, help="Monster IDs to patch")
    parser.add_argument("--dry-run", action="store_true", help="Show planned writes only")
    parser.add_argument("--no-backup", action="store_true", help="Skip automatic tileset backup")
    args = parser.parse_args()

    ids = sorted(set(args.ids))
    unknown = [mid for mid in ids if mid not in integ.ALL_MONSTER_IDS]
    if unknown:
        raise SystemExit(f"Unknown monster IDs: {unknown}")

    if not integ.TILESET_PATH.exists():
        raise SystemExit(f"Tileset not found: {integ.TILESET_PATH}")

    live_coords = _load_monster_coords_from_tile_mapper()
    fallback_layout = integ.compute_monster_layout()
    plan = []
    missing = []

    for mid in ids:
        sprite_path = _sprite_path_for_monster(mid)
        if not sprite_path.exists():
            missing.append((mid, sprite_path))
            continue
        col, row = live_coords.get(mid, fallback_layout[mid])
        x = col * integ.TILE_SIZE
        y = row * integ.TILE_SIZE
        plan.append((mid, sprite_path, col, row, x, y))

    if missing:
        print("Missing processed sprite(s):")
        for mid, p in missing:
            print(f"  - #{mid}: {p}")
        raise SystemExit(1)

    print("Patch plan:")
    for mid, sprite_path, col, row, _, _ in plan:
        print(f"  - #{mid} -> ({col}, {row}) from {sprite_path.name}")

    if args.dry_run:
        return

    if not args.no_backup:
        backup_path = _backup_tileset_path()
        shutil.copy2(integ.TILESET_PATH, backup_path)
        print(f"Backup created: {backup_path}")

    tileset = Image.open(integ.TILESET_PATH).convert("RGBA")

    for mid, sprite_path, col, row, x, y in plan:
        sprite = Image.open(sprite_path).convert("RGBA")
        if sprite.size != (integ.TILE_SIZE, integ.TILE_SIZE):
            sprite = sprite.resize((integ.TILE_SIZE, integ.TILE_SIZE), Image.Resampling.NEAREST)
        # Clear destination cell so transparent regions in the new sprite
        # don't leave stale pixels from previous art.
        clear = Image.new("RGBA", (integ.TILE_SIZE, integ.TILE_SIZE), (0, 0, 0, 0))
        tileset.paste(clear, (x, y))
        tileset.paste(sprite, (x, y), sprite)
        print(f"Patched #{mid} at tile ({col}, {row})")

    tileset.save(integ.TILESET_PATH, "PNG")
    print(f"Saved tileset: {integ.TILESET_PATH}")


if __name__ == "__main__":
    main()
