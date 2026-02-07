#!/usr/bin/env python3
"""
Integrate artefact category sprites into the tileset + update tile_mapper.gd.

1. Clears old artifact rows (19-23) in the tileset
2. Pastes 19 category sprites at row 19, cols 0-18
3. Rewrites _load_artifact_coords() so every artefact ID maps to its category tile

Usage:
    python3 integrate_artefacts.py --dry-run    # Show plan without changes
    python3 integrate_artefacts.py --go         # Execute integration
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, Optional

try:
    from PIL import Image
    import numpy as np
except ImportError as e:
    print(f"Missing dependency: {e}")
    sys.exit(1)

BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"
TILE_MAPPER_PATH = PROJECT_DIR / "scripts" / "core" / "tile_mapper.gd"
ARTEFACT_DIR = BASE_DIR / "artefact_v2"

TILE_SIZE = 64
GRID_SIZE = 32
TILESET_SIZE = TILE_SIZE * GRID_SIZE  # 2048

# Artifact region: rows 19-23 (5 rows × 32 cols = 160 slots)
ARTIFACT_ROW_START = 19
ARTIFACT_ROW_END = 23  # inclusive

# Category sprites go at row 19, cols 0-18
CATEGORY_ROW = 19

# ============================================================================
# CATEGORY NAMES (must match artefact_gen.py)
# ============================================================================

CATEGORY_NAMES = {
    0: "sword", 1: "axe", 2: "spear", 3: "staff", 4: "hammer",
    5: "pickaxe", 6: "bow", 7: "arrow", 8: "ring", 9: "amulet",
    10: "robe", 11: "mail", 12: "shield", 13: "helm", 14: "crown",
    15: "cloak", 16: "boots", 17: "gloves", 18: "light_source",
}

# ============================================================================
# ARTEFACT → CATEGORY MAPPING (from artefact_gen.py)
# ============================================================================

TVAL_TO_CATEGORY = {
    23: 0,   # Sword
    19: 6,   # Bow
    17: 7,   # Arrow
    45: 8,   # Ring
    40: 9,   # Amulet
    36: 10,  # Robe / Soft Armor
    37: 11,  # Mail / Hard Armor
    34: 12,  # Shield
    33: 14,  # Crown
    35: 15,  # Cloak
    30: 16,  # Boots
    31: 17,  # Gloves
    39: 18,  # Light Source
}

POLEARM_AXE_SVALS = {11, 12, 13}
POLEARM_SPEAR_SVALS = {1, 2, 4}
HAFTED_STAFF_SVALS = {3}
HAFTED_HAMMER_SVALS = {8}
SKIP_IDS = set(range(182, 199)) | {180}


def get_category_for_artefact(tval: int, sval: int) -> Optional[int]:
    if tval in TVAL_TO_CATEGORY:
        return TVAL_TO_CATEGORY[tval]
    if tval == 22:
        if sval in POLEARM_AXE_SVALS:
            return 1
        return 2
    if tval == 21:
        if sval in HAFTED_HAMMER_SVALS:
            return 4
        return 3
    if tval == 20:
        return 5
    if tval == 32:
        return 13
    return None


def parse_artefacts() -> Dict[int, Dict]:
    artefact_path = PROJECT_DIR / "data" / "artefact.txt"
    artefacts = {}
    current_id = None
    current_name = None

    with open(artefact_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("N:"):
                parts = line.split(":")
                current_id = int(parts[1])
                current_name = parts[2] if len(parts) > 2 else ""
            elif line.startswith("I:") and current_id is not None:
                parts = line.split(":")
                tval = int(parts[1])
                sval = int(parts[2])
                if current_id not in SKIP_IDS:
                    cat = get_category_for_artefact(tval, sval)
                    artefacts[current_id] = {
                        "name": current_name,
                        "tval": tval,
                        "sval": sval,
                        "category": cat,
                    }
    return artefacts


# ============================================================================
# TILESET INTEGRATION
# ============================================================================

def integrate_tileset(dry_run=False):
    """Place 19 category sprites on tileset row 19."""
    if not TILESET_PATH.exists():
        print(f"ERROR: Tileset not found: {TILESET_PATH}")
        return False

    tileset = Image.open(TILESET_PATH).convert("RGBA")
    print(f"Tileset loaded: {tileset.size[0]}x{tileset.size[1]}")

    # Clear artifact rows 19-23
    print(f"\nClearing artifact rows {ARTIFACT_ROW_START}-{ARTIFACT_ROW_END}...")
    if not dry_run:
        clear = Image.new("RGBA", (TILESET_SIZE, TILE_SIZE * 5), (0, 0, 0, 0))
        tileset.paste(clear, (0, ARTIFACT_ROW_START * TILE_SIZE))

    # Paste 19 category sprites at row 19, cols 0-18
    placed = 0
    for cat_id in range(19):
        name = CATEGORY_NAMES[cat_id]
        light_path = ARTEFACT_DIR / f"artefact_{cat_id}_{name}_light.png"
        col = cat_id
        row = CATEGORY_ROW
        x = col * TILE_SIZE
        y = row * TILE_SIZE

        if not light_path.exists():
            print(f"  MISSING: {light_path.name}")
            continue

        print(f"  [{cat_id:2d}] {name:15s} -> ({col}, {row})")

        if not dry_run:
            sprite = Image.open(light_path).convert("RGBA")
            if sprite.size != (TILE_SIZE, TILE_SIZE):
                sprite = sprite.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)
            tileset.paste(sprite, (x, y), sprite)
        placed += 1

    print(f"\nPlaced: {placed}/19 category sprites")

    if not dry_run:
        tileset.save(TILESET_PATH)
        print(f"Tileset saved: {TILESET_PATH}")

    return True


# ============================================================================
# TILE_MAPPER.GD UPDATE
# ============================================================================

def update_tile_mapper(dry_run=False):
    """Rewrite _load_artifact_coords() so each artefact ID -> category tile."""
    artefacts = parse_artefacts()

    # Build ID -> tile position mapping
    id_to_pos = {}
    for art_id, info in sorted(artefacts.items()):
        cat = info["category"]
        if cat is None:
            print(f"  WARNING: artefact {art_id} ({info['name']}) has no category, skipping")
            continue
        col = cat  # category ID = column on row 19
        row = CATEGORY_ROW
        id_to_pos[art_id] = (col, row, cat, info["name"])

    print(f"\nArtifact ID -> category tile mappings: {len(id_to_pos)}")

    # Group by category for summary
    by_cat = {}
    for art_id, (col, row, cat, name) in sorted(id_to_pos.items()):
        by_cat.setdefault(cat, []).append(art_id)
    for cat_id in sorted(by_cat.keys()):
        cat_name = CATEGORY_NAMES[cat_id]
        ids = by_cat[cat_id]
        print(f"  [{cat_id:2d}] {cat_name:15s} ({len(ids):2d} artefacts) -> ({cat_id}, {CATEGORY_ROW})")

    if dry_run:
        return True

    # Read tile_mapper.gd
    content = TILE_MAPPER_PATH.read_text()

    # Build new _load_artifact_coords() body
    lines = []
    lines.append("func _load_artifact_coords() -> void:")

    # Group entries by category for readability
    for cat_id in range(19):
        cat_name = CATEGORY_NAMES[cat_id]
        ids_in_cat = sorted([aid for aid, (c, r, cat, n) in id_to_pos.items() if cat == cat_id])
        if not ids_in_cat:
            continue
        lines.append(f"\t# {cat_name} ({len(ids_in_cat)} artefacts)")
        for art_id in ids_in_cat:
            col, row, cat, name = id_to_pos[art_id]
            lines.append(f"\tartifact_coords[{art_id}] = Vector2i({col}, {row})  # {name}")
        lines.append("")

    new_func = "\n".join(lines)

    # Replace the function in the file
    pattern = r'func _load_artifact_coords\(\) -> void:.*?(?=\nfunc |\n[a-z]|\Z)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        print("ERROR: Could not find _load_artifact_coords() in tile_mapper.gd")
        return False

    old_func = match.group(0)
    old_lines = old_func.strip().split("\n")
    print(f"\nOld _load_artifact_coords(): {len(old_lines)} lines")
    print(f"New _load_artifact_coords(): {len(lines)} lines")

    content = content[:match.start()] + new_func + "\n" + content[match.end():]
    TILE_MAPPER_PATH.write_text(content)
    print(f"Updated: {TILE_MAPPER_PATH}")

    return True


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Integrate artefact category sprites")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true", help="Show plan without changes")
    group.add_argument("--go", action="store_true", help="Execute integration")
    args = parser.parse_args()

    dry_run = args.dry_run
    label = "DRY RUN" if dry_run else "LIVE"

    print(f"{'=' * 60}")
    print(f"ARTEFACT TILESET INTEGRATION ({label})")
    print(f"{'=' * 60}")

    ok1 = integrate_tileset(dry_run=dry_run)
    ok2 = update_tile_mapper(dry_run=dry_run)

    if ok1 and ok2:
        print(f"\n{'=' * 60}")
        print(f"{'DRY RUN COMPLETE' if dry_run else 'INTEGRATION COMPLETE'}")
        print(f"{'=' * 60}")
    else:
        print("\nERROR: Integration failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
