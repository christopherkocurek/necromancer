#!/usr/bin/env python3
"""
Necromancer Tileset - Manifest Extraction Script
Extracts all entities from Sil-Q data files and creates manifest.json

Usage: python extract_manifest.py
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Any
from dataclasses import dataclass, asdict
from datetime import datetime

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
OUTPUT_DIR = Path(__file__).parent


@dataclass
class Entity:
    id: int
    name: str
    display_char: str = ""
    color: str = ""
    depth: int = 0
    layer: int = 0  # Dungeon layer (1-7)
    description: str = ""


def parse_monsters(filepath: Path) -> List[Dict]:
    """Parse monster.txt and extract all monsters."""
    monsters = []
    current = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('V:'):
                continue

            parts = line.split(':')
            key = parts[0] if parts else ''

            if key == 'N' and len(parts) >= 3:
                # Save previous monster
                if current and current['id'] >= 11:  # Skip player graphics (0-3)
                    monsters.append(current)

                current = {
                    'id': int(parts[1]),
                    'name': parts[2],
                    'display_char': '',
                    'color': '',
                    'depth': 0,
                    'layer': 0,
                    'description': ''
                }
            elif key == 'G' and current and len(parts) >= 3:
                current['display_char'] = parts[1]
                current['color'] = parts[2]
            elif key == 'W' and current and len(parts) >= 2:
                current['depth'] = int(parts[1])
                # Calculate layer based on depth
                depth = current['depth']
                if depth <= 3:
                    current['layer'] = 1  # Forest Breach
                elif depth <= 6:
                    current['layer'] = 2  # Orc Warrens
                elif depth <= 9:
                    current['layer'] = 3  # Torture Halls
                elif depth <= 12:
                    current['layer'] = 4  # Necropolis
                elif depth <= 15:
                    current['layer'] = 5  # Wraith Domain
                elif depth <= 18:
                    current['layer'] = 6  # Inner Sanctum
                else:
                    current['layer'] = 7  # Pits of Despair
            elif key == 'D' and current:
                desc = ':'.join(parts[1:]).strip()
                if current['description']:
                    current['description'] += ' ' + desc
                else:
                    current['description'] = desc

    # Don't forget the last one
    if current and current['id'] >= 11:
        monsters.append(current)

    return monsters


def parse_terrain(filepath: Path) -> List[Dict]:
    """Parse terrain.txt and extract all terrain features."""
    terrain = []
    current = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('V:'):
                continue

            parts = line.split(':')
            key = parts[0] if parts else ''

            if key == 'N' and len(parts) >= 3:
                if current:
                    terrain.append(current)

                current = {
                    'id': int(parts[1]),
                    'name': parts[2],
                    'display_char': '',
                    'color': ''
                }
            elif key == 'G' and current and len(parts) >= 3:
                current['display_char'] = parts[1]
                current['color'] = parts[2]

    if current:
        terrain.append(current)

    return terrain


def parse_items(filepath: Path) -> List[Dict]:
    """Parse object.txt and extract all items."""
    items = []
    current = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('V:'):
                continue

            parts = line.split(':')
            key = parts[0] if parts else ''

            if key == 'N' and len(parts) >= 3:
                if current:
                    items.append(current)

                # Clean up name (remove & and ~)
                name = parts[2].replace('&', '').replace('~', '').strip()

                current = {
                    'id': int(parts[1]),
                    'name': name,
                    'display_char': '',
                    'color': '',
                    'item_type': '',
                    'depth': 0,
                    'description': ''
                }
            elif key == 'G' and current and len(parts) >= 3:
                current['display_char'] = parts[1]
                current['color'] = parts[2]
            elif key == 'I' and current and len(parts) >= 3:
                # tval determines item type
                tval = int(parts[1])
                current['item_type'] = get_item_type(tval)
            elif key == 'W' and current and len(parts) >= 2:
                current['depth'] = int(parts[1])
            elif key == 'D' and current:
                desc = ':'.join(parts[1:]).strip()
                if current['description']:
                    current['description'] += ' ' + desc
                else:
                    current['description'] = desc

    if current:
        items.append(current)

    return items


def parse_artifacts(filepath: Path) -> List[Dict]:
    """Parse artefact.txt and extract all artifacts."""
    artifacts = []
    current = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('V:'):
                continue

            parts = line.split(':')
            key = parts[0] if parts else ''

            if key == 'N' and len(parts) >= 3:
                if current:
                    artifacts.append(current)

                current = {
                    'id': int(parts[1]),
                    'name': parts[2],
                    'display_char': '',
                    'color': '',
                    'depth': 0,
                    'description': ''
                }
            elif key == 'G' and current and len(parts) >= 3:
                current['display_char'] = parts[1]
                current['color'] = parts[2]
            elif key == 'W' and current and len(parts) >= 2:
                current['depth'] = int(parts[1])
            elif key == 'D' and current:
                desc = ':'.join(parts[1:]).strip()
                if current['description']:
                    current['description'] += ' ' + desc
                else:
                    current['description'] = desc

    if current:
        artifacts.append(current)

    return artifacts


def parse_races(filepath: Path) -> List[Dict]:
    """Parse race.txt and extract all races."""
    races = []
    current = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('V:'):
                continue

            parts = line.split(':')
            key = parts[0] if parts else ''

            if key == 'N' and len(parts) >= 3:
                if current:
                    races.append(current)

                current = {
                    'id': int(parts[1]),
                    'name': parts[2],
                    'description': ''
                }
            elif key == 'D' and current:
                desc = ':'.join(parts[1:]).strip()
                if current['description']:
                    current['description'] += ' ' + desc
                else:
                    current['description'] = desc

    if current:
        races.append(current)

    return races


def parse_houses(filepath: Path) -> List[Dict]:
    """Parse house.txt and extract all houses."""
    houses = []
    current = None

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or line.startswith('V:'):
                continue

            parts = line.split(':')
            key = parts[0] if parts else ''

            if key == 'N' and len(parts) >= 3:
                if current:
                    houses.append(current)

                current = {
                    'id': int(parts[1]),
                    'name': parts[2],
                    'short_name': '',
                    'description': ''
                }
            elif key == 'B' and current and len(parts) >= 2:
                current['short_name'] = parts[1]
            elif key == 'D' and current:
                desc = ':'.join(parts[1:]).strip()
                if current['description']:
                    current['description'] += ' ' + desc
                else:
                    current['description'] = desc

    if current:
        houses.append(current)

    return houses


def get_item_type(tval: int) -> str:
    """Map tval to item type category."""
    types = {
        3: 'skeleton',
        21: 'blunt_weapon',
        22: 'polearm',
        23: 'sword',
        24: 'hafted',
        33: 'crown',
        34: 'shield',
        35: 'cloak',
        36: 'soft_armor',
        37: 'hard_armor',
        38: 'gloves',
        39: 'light_source',
        40: 'amulet',
        45: 'ring',
        55: 'staff',
        56: 'wand',
        65: 'horn',
        66: 'scroll',
        70: 'arrow',
        75: 'potion',
        80: 'food'
    }
    return types.get(tval, 'misc')


def generate_player_sprites(races: List[Dict], houses: List[Dict]) -> List[Dict]:
    """Generate player sprite entries for each race+house combination."""
    players = []
    sprite_id = 0

    # Race to valid house mapping
    race_houses = {
        0: [0, 1, 2],    # Elf: Lothlorien, Rivendell, Greenwood
        1: [3, 4, 5],    # Man: Dunedain, Rohan, Gondor
        2: [6, 7, 8],    # Dwarf: Khazad-dum, Erebor, Iron Hills
        3: [0, 1, 2],    # Istari: uses Elf houses (test race)
    }

    for race in races:
        race_id = race['id']
        if race_id not in race_houses:
            continue

        for house_id in race_houses[race_id]:
            house = next((h for h in houses if h['id'] == house_id), None)
            if not house:
                continue

            players.append({
                'id': sprite_id,
                'race_id': race_id,
                'house_id': house_id,
                'race_name': race['name'],
                'house_name': house['name'],
                'name': f"{race['name']} {house.get('short_name', house['name'])}"
            })
            sprite_id += 1

    return players


def generate_effects() -> List[Dict]:
    """Generate status effect sprite entries."""
    effects = [
        {'id': 0, 'name': 'poisoned', 'description': 'Poisoned status overlay'},
        {'id': 1, 'name': 'blind', 'description': 'Blinded status overlay'},
        {'id': 2, 'name': 'confused', 'description': 'Confused status overlay'},
        {'id': 3, 'name': 'afraid', 'description': 'Afraid status overlay'},
        {'id': 4, 'name': 'slowed', 'description': 'Slowed status overlay'},
        {'id': 5, 'name': 'hasted', 'description': 'Hasted status overlay'},
        {'id': 6, 'name': 'entranced', 'description': 'Entranced/held status overlay'},
        {'id': 7, 'name': 'bleeding', 'description': 'Bleeding/wounded status overlay'},
        {'id': 8, 'name': 'hallucinating', 'description': 'Hallucinating status overlay'},
        {'id': 9, 'name': 'rage', 'description': 'Rage/berserk status overlay'},
        {'id': 10, 'name': 'hunger', 'description': 'Hungry status overlay'},
        {'id': 11, 'name': 'blessed', 'description': 'Blessed status overlay'},
        {'id': 12, 'name': 'protected', 'description': 'Protection aura overlay'},
        {'id': 13, 'name': 'invisible', 'description': 'Invisible/translucent overlay'},
        {'id': 14, 'name': 'see_invisible', 'description': 'See invisible status'},
        {'id': 15, 'name': 'free_action', 'description': 'Free action status'},
        {'id': 16, 'name': 'light', 'description': 'Light radius glow'},
        {'id': 17, 'name': 'darkness', 'description': 'Darkness aura'},
        {'id': 18, 'name': 'regenerating', 'description': 'Regeneration effect'},
        {'id': 19, 'name': 'singing', 'description': 'Singing/song effect'},
    ]
    return effects


def main():
    print("=" * 60)
    print("Necromancer Tileset - Manifest Extraction")
    print("=" * 60)

    # Parse all data files
    print("\nParsing data files...")

    monsters = parse_monsters(DATA_DIR / "monster.txt")
    print(f"  Monsters: {len(monsters)}")

    terrain = parse_terrain(DATA_DIR / "terrain.txt")
    print(f"  Terrain: {len(terrain)}")

    items = parse_items(DATA_DIR / "object.txt")
    print(f"  Items: {len(items)}")

    artifacts = parse_artifacts(DATA_DIR / "artefact.txt")
    print(f"  Artifacts: {len(artifacts)}")

    races = parse_races(DATA_DIR / "race.txt")
    print(f"  Races: {len(races)}")

    houses = parse_houses(DATA_DIR / "house.txt")
    print(f"  Houses: {len(houses)}")

    # Generate derived entries
    print("\nGenerating derived entries...")

    players = generate_player_sprites(races, houses)
    print(f"  Player sprites: {len(players)}")

    effects = generate_effects()
    print(f"  Status effects: {len(effects)}")

    # Calculate terrain with light/dark variants
    # Each terrain type needs light and dark versions
    terrain_with_variants = []
    for t in terrain:
        # Light variant (original)
        terrain_with_variants.append({
            **t,
            'variant': 'light',
            'sprite_id': f"terrain_{t['id']}_light"
        })
        # Dark variant (for FOV)
        terrain_with_variants.append({
            **t,
            'variant': 'dark',
            'sprite_id': f"terrain_{t['id']}_dark"
        })

    print(f"  Terrain with variants: {len(terrain_with_variants)}")

    # Calculate totals
    total_sprites = (
        len(monsters) +
        len(terrain_with_variants) +
        len(items) +
        len(artifacts) +
        len(players) +
        len(effects)
    )

    print(f"\n{'=' * 40}")
    print(f"TOTAL SPRITES NEEDED: {total_sprites}")
    print(f"{'=' * 40}")
    print(f"32x32 grid capacity: 1024 sprites")
    print(f"Available slots: {1024 - total_sprites}")

    # Build manifest
    manifest = {
        'version': '1.0',
        'created_at': datetime.now().isoformat(),
        'grid_size': 32,
        'tile_size': 64,
        'total_sprites': total_sprites,
        'categories': {
            'monsters': monsters,
            'terrain': terrain_with_variants,
            'items': items,
            'artifacts': artifacts,
            'players': players,
            'effects': effects
        },
        'category_counts': {
            'monsters': len(monsters),
            'terrain': len(terrain_with_variants),
            'items': len(items),
            'artifacts': len(artifacts),
            'players': len(players),
            'effects': len(effects)
        },
        'generation_status': {}
    }

    # Write manifest
    manifest_path = OUTPUT_DIR / "manifest.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)

    print(f"\nManifest saved to: {manifest_path}")

    # Write extraction log
    log_path = OUTPUT_DIR / "extraction_log.txt"
    with open(log_path, 'w') as f:
        f.write(f"Necromancer Tileset - Extraction Log\n")
        f.write(f"{'=' * 50}\n")
        f.write(f"Generated: {datetime.now().isoformat()}\n\n")

        f.write(f"CATEGORY BREAKDOWN\n")
        f.write(f"{'-' * 30}\n")
        f.write(f"Monsters:          {len(monsters):>5}\n")
        f.write(f"Terrain (w/vars):  {len(terrain_with_variants):>5}\n")
        f.write(f"Items:             {len(items):>5}\n")
        f.write(f"Artifacts:         {len(artifacts):>5}\n")
        f.write(f"Player sprites:    {len(players):>5}\n")
        f.write(f"Status effects:    {len(effects):>5}\n")
        f.write(f"{'-' * 30}\n")
        f.write(f"TOTAL:             {total_sprites:>5}\n\n")

        f.write(f"MONSTER LAYERS\n")
        f.write(f"{'-' * 30}\n")
        layer_counts = {}
        for m in monsters:
            layer = m.get('layer', 0)
            layer_counts[layer] = layer_counts.get(layer, 0) + 1
        for layer in sorted(layer_counts.keys()):
            layer_names = {
                1: "Forest Breach (1-3)",
                2: "Orc Warrens (3-6)",
                3: "Torture Halls (6-9)",
                4: "Necropolis (9-12)",
                5: "Wraith Domain (12-15)",
                6: "Inner Sanctum (15-18)",
                7: "Pits of Despair (18-20)",
                0: "Special/Hallucination"
            }
            f.write(f"Layer {layer} - {layer_names.get(layer, 'Unknown')}: {layer_counts[layer]}\n")

        f.write(f"\nITEM TYPES\n")
        f.write(f"{'-' * 30}\n")
        type_counts = {}
        for item in items:
            itype = item.get('item_type', 'misc')
            type_counts[itype] = type_counts.get(itype, 0) + 1
        for itype in sorted(type_counts.keys()):
            f.write(f"{itype}: {type_counts[itype]}\n")

    print(f"Extraction log saved to: {log_path}")
    print("\nDone!")


if __name__ == "__main__":
    main()
