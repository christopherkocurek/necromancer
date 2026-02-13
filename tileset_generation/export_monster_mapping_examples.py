#!/usr/bin/env python3
"""
Export monster mapping examples from current tile_mapper + atlas.

Default IDs: 32, 33, 40, 54
Creates a review folder with:
- atlas crops from live mapping
- mapping_manifest.json
- README.txt

Usage:
  python3 tileset_generation/export_monster_mapping_examples.py
  python3 tileset_generation/export_monster_mapping_examples.py --ids 32 33 40 54 --out example
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from PIL import Image

PROJECT_DIR = Path(__file__).resolve().parent.parent
TILE_MAPPER = PROJECT_DIR / "scripts" / "core" / "tile_mapper.gd"
ATLAS = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
MONSTER_TXT = PROJECT_DIR / "data" / "monster.txt"
TILE_SIZE = 64

PAT_COORD = re.compile(r"monster_coords\[(\d+)\]\s*=\s*Vector2i\((\d+),\s*(\d+)\)")
PAT_NAME = re.compile(r"^N:(\d+):(.+)$")


def load_coords() -> dict[int, tuple[int, int]]:
    content = TILE_MAPPER.read_text()
    coords: dict[int, tuple[int, int]] = {}
    for mid_s, x_s, y_s in PAT_COORD.findall(content):
        coords[int(mid_s)] = (int(x_s), int(y_s))
    return coords


def load_names() -> dict[int, str]:
    names: dict[int, str] = {}
    for line in MONSTER_TXT.read_text().splitlines():
        m = PAT_NAME.match(line.strip())
        if m:
            names[int(m.group(1))] = m.group(2)
    return names


def main() -> int:
    parser = argparse.ArgumentParser(description="Export mapped monster atlas examples")
    parser.add_argument("--ids", nargs="+", type=int, default=[32, 33, 40, 54])
    parser.add_argument("--out", type=str, default="example")
    args = parser.parse_args()

    out_dir = (PROJECT_DIR / args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    coords = load_coords()
    names = load_names()
    atlas = Image.open(ATLAS).convert("RGBA")

    manifest: list[dict] = []
    for mid in args.ids:
        if mid not in coords:
            continue
        x, y = coords[mid]
        crop = atlas.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
        filename = f"monster_{mid}_mapped.png"
        crop.save(out_dir / filename)
        manifest.append(
            {
                "id": mid,
                "name": names.get(mid, f"Monster {mid}"),
                "atlas_coord": [x, y],
                "image": filename,
            }
        )

    (out_dir / "mapping_manifest.json").write_text(json.dumps(manifest, indent=2))

    lines = [
        "Monster Mapping Example Export",
        "",
        "These are crops from the CURRENT atlas using CURRENT tile_mapper.gd monster_coords.",
        "",
    ]
    for row in manifest:
        lines.append(
            f"- ID {row['id']} ({row['name']}) -> atlas {tuple(row['atlas_coord'])} -> {row['image']}"
        )
    lines.append("")
    lines.append("If two IDs collide in mapping, they both show the same atlas cell contents.")
    (out_dir / "README.txt").write_text("\n".join(lines))

    print(out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
