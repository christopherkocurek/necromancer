#!/usr/bin/env python3
"""
Necromancer Tileset Generator
Generates sprites using DALL-E 3 API based on manifest.json

Usage:
    python generator.py --all                    # Generate all categories
    python generator.py --category monsters      # Generate specific category
    python generator.py --category terrain       # Generate terrain
    python generator.py --resume                 # Resume from last checkpoint
    python generator.py --status                 # Show generation status
    python generator.py --parallel 4             # Run with 4 concurrent streams

Environment:
    OPENAI_API_KEY must be set in .env file
"""

import os
import sys
import json
import time
import base64
import asyncio
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import io

# Load environment
from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image
except ImportError:
    print("Required packages not installed. Run:")
    print("  pip install openai pillow python-dotenv")
    sys.exit(1)

# Constants
TILE_SIZE = 64
MAGENTA = (255, 0, 255, 255)
MAX_RETRIES = 3
RATE_LIMIT_DELAY = 2.0  # seconds between API calls

# Paths
BASE_DIR = Path(__file__).parent
STAGING_DIR = BASE_DIR / "staging"
MANIFEST_PATH = BASE_DIR / "manifest.json"
LAYOUT_PATH = BASE_DIR / "layout_map.json"
PROGRESS_PATH = BASE_DIR / "progress.json"


# ============================================================================
# STYLE GUIDE - DALL-E 3 Prompts
# ============================================================================

STYLE_BASE = """dark fantasy roguelike style, 64x64 pixel art game sprite,
centered on solid magenta (#FF00FF) background, clean pixel edges, isolated game asset"""

DUNGEON_TIERS = {
    1: "corrupted forest dungeon, twisted roots, purple-tinted moss, spider webs",
    2: "orc warren dungeon, rough-hewn stone, crude torchlight, bloodstains",
    3: "torture hall dungeon, iron grating, dark metal, rusted chains",
    4: "necropolis crypt, bone-white stone, skull motifs, ghostly blue-green glow",
    5: "wraith domain, incorporeal mist, shadow-touched stone, purple wraith-fire",
    6: "dark lord sanctum, obsidian black, molten fire cracks, eye motifs",
    7: "abyssal pit, void stone, reality-warping cracks, ultimate darkness"
}


def get_monster_prompt(monster: Dict) -> str:
    """Generate DALL-E prompt for a monster."""
    name = sanitize_name(monster['name'])
    desc = sanitize_name(monster.get('description', ''))
    layer = monster.get('layer', 1)
    tier_theme = DUNGEON_TIERS.get(layer, DUNGEON_TIERS[1])

    return f"""{name}, dark fantasy creature, roguelike game sprite, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, side view facing right,
menacing pose, {tier_theme} theme,
{desc[:200] if desc else 'dark and dangerous'},
clean pixel edges, isolated game asset, dark purple shadows"""


def sanitize_name(name: str) -> str:
    """Replace potentially problematic terms with safer alternatives."""
    replacements = {
        'torture': 'dungeon',
        'torture rack': 'iron frame',
        'torture hall': 'dark hall',
        'blood': 'dark',
        'bloodstain': 'dark stain',
        'poison': 'toxic',
        'poisoned': 'venomous',
        'corpse': 'remains',
        'skull': 'bone',
        'death': 'shadow',
        'kill': 'strike',
        'murder': 'dark',
        'slave': 'captive',
        'chains': 'iron bindings',
        'prison': 'cell',
        'filth': 'muck',
    }
    result = name.lower()
    for old, new in replacements.items():
        result = result.replace(old, new)
    return result


def get_terrain_prompt(terrain: Dict) -> str:
    """Generate DALL-E prompt for terrain."""
    name = sanitize_name(terrain['name'])
    variant = terrain.get('variant', 'light')
    char = terrain.get('display_char', '')

    # Determine terrain type
    is_floor = 'floor' in name.lower() or char == '.'
    is_wall = 'wall' in name.lower() or char == '#'
    is_door = 'door' in name.lower() or char in '+\''
    is_stairs = 'stair' in name.lower() or 'shaft' in name.lower() or char in '<>'
    is_forge = 'forge' in name.lower() or char == '0'
    is_trap = 'trap' in name.lower() or char == '^'

    # Base type description
    if is_floor:
        type_desc = "stone dungeon floor tile, top-down view"
    elif is_wall:
        type_desc = "stone dungeon wall tile, 3/4 view"
    elif is_door:
        state = "closed" if 'closed' in name.lower() or 'locked' in name.lower() or 'jammed' in name.lower() else "open"
        type_desc = f"wooden dungeon door ({state}), front view"
    elif is_stairs:
        direction = "descending" if 'down' in name.lower() else "ascending"
        type_desc = f"{direction} stone stairs, top-down view"
    elif is_forge:
        type_desc = "dwarven forge with anvil, top-down view"
    elif is_trap:
        type_desc = f"dungeon trap ({name}), top-down view"
    else:
        type_desc = f"dungeon feature ({name}), top-down view"

    # Light/dark variant
    if variant == 'dark':
        lighting = "shadowed and desaturated, outside torch light, dim and murky"
    else:
        lighting = "torch-lit, visible in light, full color and detail"

    return f"""{name}, {type_desc}, roguelike style, 64x64 pixel art,
centered on solid magenta (#FF00FF) background,
{lighting}, dark stone dungeon aesthetic,
clean pixel edges, isolated game asset"""


def get_item_prompt(item: Dict) -> str:
    """Generate DALL-E prompt for an item."""
    name = item['name']
    item_type = item.get('item_type', 'misc')
    desc = item.get('description', '')

    # Type-specific descriptions
    type_views = {
        'sword': 'side view, blade pointing up',
        'blunt_weapon': 'side view, head at top',
        'polearm': 'side view, blade pointing up',
        'hafted': 'side view',
        'soft_armor': 'front view, displayed flat',
        'hard_armor': 'front view, displayed flat',
        'shield': 'front view, face forward',
        'crown': '3/4 view, regal positioning',
        'cloak': 'draped view',
        'gloves': 'paired, palm up',
        'potion': 'front view, glowing liquid',
        'food': 'top-down view',
        'scroll': 'rolled with visible seal',
        'wand': 'diagonal, tip glowing',
        'staff': 'vertical, crystal top',
        'ring': 'front view, band visible',
        'amulet': 'front view, pendant displayed',
        'light_source': 'glowing, light rays'
    }

    view = type_views.get(item_type, 'front view')

    return f"""{name}, dark fantasy {item_type}, roguelike item sprite, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, {view},
detailed craftsmanship, {desc[:150] if desc else 'magical item'},
clean pixel edges, isolated game asset"""


def get_artifact_prompt(artifact: Dict) -> str:
    """Generate DALL-E prompt for an artifact."""
    name = artifact['name']
    desc = artifact.get('description', '')

    return f"""{name}, legendary artifact, dark fantasy roguelike style, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, front view,
glowing with magical power, unique and ornate design,
{desc[:200] if desc else 'ancient and powerful'},
clean pixel edges, isolated game asset, subtle magical aura"""


def get_player_prompt(player: Dict) -> str:
    """Generate DALL-E prompt for a player sprite."""
    race = player['race_name']
    house = player['house_name']

    race_descs = {
        'Elf': 'elegant elven warrior with pointed ears, lithe build',
        'Man': 'rugged human ranger, weathered features',
        'Dwarf': 'stout dwarven warrior with thick beard, sturdy build',
        'Istari': 'mysterious robed wizard with staff, ancient and powerful'
    }

    house_descs = {
        'Of Lothlorien': 'golden wood aesthetic, silver and green colors',
        'Of Rivendell': 'high elven craft, blue and silver colors',
        'Of Greenwood': 'woodland hunter style, brown and green colors',
        'Dunedain': 'ranger cloak with star emblem, grey and silver',
        'Of Rohan': 'horse-lord armor, green and gold colors',
        'Of Gondor': 'tower guard style, black and silver colors',
        'Of Khazad-dum': 'ancient dwarven craft, silver and blue',
        'Of Erebor': 'dragon-resistant armor, gold and red accents',
        'Of the Iron Hills': 'battle-hardened armor, iron grey'
    }

    race_desc = race_descs.get(race, 'fantasy warrior')
    house_desc = house_descs.get(house, 'adventurer gear')

    return f"""{race} {house} adventurer, {race_desc}, {house_desc},
dark fantasy roguelike style, 64x64 pixel art character portrait,
centered on solid magenta (#FF00FF) background, front-facing view,
heroic pose ready for adventure,
clean pixel edges, isolated game asset"""


def get_effect_prompt(effect: Dict) -> str:
    """Generate DALL-E prompt for a status effect overlay."""
    name = effect['name']
    desc = effect.get('description', '')

    effect_visuals = {
        'poisoned': 'green toxic drips and swirls',
        'blind': 'dark blindfold or closed eyes effect',
        'confused': 'spinning stars and spirals',
        'afraid': 'pale face with fear marks',
        'slowed': 'blue ice crystals and frost',
        'hasted': 'yellow speed lines and blur',
        'entranced': 'purple hypnotic spirals',
        'bleeding': 'red blood drops',
        'hallucinating': 'rainbow distortion waves',
        'rage': 'red flames and angry aura',
        'hunger': 'empty stomach icon',
        'blessed': 'golden holy light',
        'protected': 'blue shield aura',
        'invisible': 'transparent ghostly outline',
        'see_invisible': 'glowing eye symbol',
        'free_action': 'broken chains symbol',
        'light': 'radiating yellow glow',
        'darkness': 'black shadow aura',
        'regenerating': 'green healing sparkles',
        'singing': 'musical notes and sound waves'
    }

    visual = effect_visuals.get(name, 'magical effect')

    return f"""status effect icon: {name}, {visual}, roguelike UI element, 64x64 pixel art,
centered on solid magenta (#FF00FF) background,
{desc} overlay effect that can be composited on characters,
semi-transparent magical effect,
clean pixel edges, isolated game asset"""


# ============================================================================
# IMAGE PROCESSING
# ============================================================================

def normalize_magenta(img: Image.Image, tolerance: int = 50) -> Image.Image:
    """Convert near-magenta pixels to exact magenta for transparency."""
    img = img.convert('RGBA')
    pixels = img.load()

    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]
            # Check if pixel is close to magenta
            if r > 200 and g < tolerance and b > 200:
                pixels[x, y] = MAGENTA

    return img


def validate_sprite(img: Image.Image) -> bool:
    """Validate that sprite meets requirements."""
    if img.size != (TILE_SIZE, TILE_SIZE):
        return False

    # Check has some content (not all magenta)
    pixels = list(img.getdata())
    non_magenta = sum(1 for p in pixels if p[:3] != MAGENTA[:3])

    # Need at least 10% non-magenta content
    min_content = (TILE_SIZE * TILE_SIZE) * 0.10
    return non_magenta >= min_content


# ============================================================================
# GENERATOR CLASS
# ============================================================================

class TilesetGenerator:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.manifest: Dict = {}
        self.layout: Dict = {}
        self.progress: Dict = {}

        self._load_data()

    def _load_data(self):
        """Load manifest, layout, and progress files."""
        # Load manifest
        if MANIFEST_PATH.exists():
            with open(MANIFEST_PATH, 'r') as f:
                self.manifest = json.load(f)
        else:
            raise FileNotFoundError("manifest.json not found. Run extract_manifest.py first.")

        # Load layout
        if LAYOUT_PATH.exists():
            with open(LAYOUT_PATH, 'r') as f:
                self.layout = json.load(f)
        else:
            raise FileNotFoundError("layout_map.json not found. Run layout_planner.py first.")

        # Load or initialize progress
        if PROGRESS_PATH.exists():
            with open(PROGRESS_PATH, 'r') as f:
                self.progress = json.load(f)
        else:
            self.progress = {
                'started_at': datetime.now().isoformat(),
                'last_updated': datetime.now().isoformat(),
                'categories': {},
                'sprites': {},
                'cost_tracking': {
                    'total_api_calls': 0,
                    'estimated_cost_usd': 0.0
                }
            }

    def _save_progress(self):
        """Save current progress to disk."""
        self.progress['last_updated'] = datetime.now().isoformat()
        with open(PROGRESS_PATH, 'w') as f:
            json.dump(self.progress, f, indent=2)

    def _get_prompt(self, category: str, entity: Dict) -> str:
        """Get the appropriate prompt for an entity."""
        if category == 'monsters':
            return get_monster_prompt(entity)
        elif category == 'terrain':
            return get_terrain_prompt(entity)
        elif category == 'items':
            return get_item_prompt(entity)
        elif category == 'artifacts':
            return get_artifact_prompt(entity)
        elif category == 'players':
            return get_player_prompt(entity)
        elif category == 'effects':
            return get_effect_prompt(entity)
        else:
            return f"{entity.get('name', 'unknown')}, dark fantasy roguelike sprite, {STYLE_BASE}"

    def _get_entity_key(self, category: str, entity: Dict) -> str:
        """Generate unique key for an entity."""
        if category == 'terrain':
            variant = entity.get('variant', 'light')
            return f"terrain_{entity['id']}_{variant}"
        elif category == 'players':
            return f"player_{entity['id']}"
        elif category == 'effects':
            return f"effect_{entity['id']}"
        elif category == 'monsters':
            return f"monster_{entity['id']}"
        elif category == 'items':
            return f"item_{entity['id']}"
        elif category == 'artifacts':
            return f"artifact_{entity['id']}"
        return f"{category}_{entity['id']}"

    def generate_sprite(self, category: str, entity: Dict) -> bool:
        """Generate a single sprite using DALL-E 3."""
        entity_key = self._get_entity_key(category, entity)
        prompt = self._get_prompt(category, entity)

        print(f"  Generating: {entity_key} - {entity.get('name', 'unknown')}")

        last_error = None
        for attempt in range(MAX_RETRIES):
            try:
                # Call DALL-E 3
                response = self.client.images.generate(
                    model="dall-e-3",
                    prompt=prompt,
                    size="1024x1024",
                    quality="standard",
                    style="vivid",
                    n=1,
                    response_format="b64_json"
                )

                # Track cost (~$0.04 per image)
                self.progress['cost_tracking']['total_api_calls'] += 1
                self.progress['cost_tracking']['estimated_cost_usd'] += 0.04

                # Decode image
                img_data = base64.b64decode(response.data[0].b64_json)
                img = Image.open(io.BytesIO(img_data))

                # Resize to 64x64
                img = img.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)

                # Normalize magenta background
                img = normalize_magenta(img)

                # Validate
                if not validate_sprite(img):
                    print(f"    Attempt {attempt + 1}: Invalid sprite, retrying...")
                    time.sleep(RATE_LIMIT_DELAY)
                    continue

                # Save to staging
                output_dir = STAGING_DIR / category
                output_dir.mkdir(parents=True, exist_ok=True)
                output_path = output_dir / f"{entity_key}.png"
                img.save(output_path)

                # Update progress
                self.progress['sprites'][entity_key] = {
                    'status': 'completed',
                    'path': str(output_path.relative_to(BASE_DIR)),
                    'completed_at': datetime.now().isoformat()
                }

                print(f"    Success: {output_path}")
                return True

            except Exception as e:
                last_error = e
                print(f"    Attempt {attempt + 1} failed: {e}")
                if attempt < MAX_RETRIES - 1:
                    time.sleep(RATE_LIMIT_DELAY * 2)  # Longer delay on error

        # All retries failed
        self.progress['sprites'][entity_key] = {
            'status': 'failed',
            'error': str(last_error) if last_error else 'Unknown error',
            'attempts': MAX_RETRIES
        }
        return False

    def generate_category(self, category: str, limit: Optional[int] = None) -> Dict[str, int]:
        """Generate all sprites in a category."""
        if category not in self.manifest['categories']:
            print(f"Unknown category: {category}")
            return {'completed': 0, 'failed': 0, 'skipped': 0}

        entities = self.manifest['categories'][category]
        if limit:
            entities = entities[:limit]

        stats = {'completed': 0, 'failed': 0, 'skipped': 0}

        print(f"\n{'=' * 60}")
        print(f"Generating {category}: {len(entities)} sprites")
        print(f"{'=' * 60}")

        for i, entity in enumerate(entities):
            entity_key = self._get_entity_key(category, entity)

            # Skip if already completed
            if entity_key in self.progress['sprites']:
                if self.progress['sprites'][entity_key].get('status') == 'completed':
                    stats['skipped'] += 1
                    continue

            print(f"\n[{i + 1}/{len(entities)}]", end="")

            success = self.generate_sprite(category, entity)
            if success:
                stats['completed'] += 1
            else:
                stats['failed'] += 1

            # Save progress periodically
            if (stats['completed'] + stats['failed']) % 5 == 0:
                self._save_progress()
                print(f"  [Checkpoint saved]")

            # Rate limiting
            time.sleep(RATE_LIMIT_DELAY)

        # Update category progress
        self.progress['categories'][category] = {
            'total': len(self.manifest['categories'][category]),
            'completed': stats['completed'] + stats['skipped'],
            'failed': stats['failed']
        }
        self._save_progress()

        print(f"\n{category} complete: {stats['completed']} generated, {stats['skipped']} skipped, {stats['failed']} failed")
        return stats

    def generate_all(self, parallel: int = 1):
        """Generate all categories."""
        categories = ['terrain', 'players', 'effects', 'monsters', 'items', 'artifacts']

        for category in categories:
            self.generate_category(category)

    def show_status(self):
        """Display current generation status."""
        print("\n" + "=" * 60)
        print("TILESET GENERATION STATUS")
        print("=" * 60)

        if not self.progress.get('started_at'):
            print("No generation in progress.")
            return

        print(f"Started: {self.progress['started_at']}")
        print(f"Last update: {self.progress['last_updated']}")

        total_sprites = self.manifest.get('total_sprites', 0)
        completed = sum(1 for s in self.progress.get('sprites', {}).values()
                       if s.get('status') == 'completed')
        failed = sum(1 for s in self.progress.get('sprites', {}).values()
                    if s.get('status') == 'failed')

        print(f"\nOverall Progress: {completed}/{total_sprites} ({100*completed/total_sprites:.1f}%)")
        print(f"Failed: {failed}")

        print("\nBy Category:")
        for category, data in self.progress.get('categories', {}).items():
            total = data.get('total', 0)
            done = data.get('completed', 0)
            pct = 100 * done / total if total > 0 else 0
            bar = '#' * int(pct / 5) + '-' * (20 - int(pct / 5))
            print(f"  {category:12s} [{bar}] {done:3d}/{total:3d}")

        cost = self.progress.get('cost_tracking', {})
        print(f"\nCost Tracking:")
        print(f"  API calls: {cost.get('total_api_calls', 0)}")
        print(f"  Estimated cost: ${cost.get('estimated_cost_usd', 0):.2f}")


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description='Necromancer Tileset Generator')
    parser.add_argument('--all', action='store_true', help='Generate all categories')
    parser.add_argument('--category', type=str, help='Generate specific category')
    parser.add_argument('--resume', action='store_true', help='Resume from last checkpoint')
    parser.add_argument('--status', action='store_true', help='Show generation status')
    parser.add_argument('--parallel', type=int, default=1, help='Number of parallel streams')
    parser.add_argument('--limit', type=int, help='Limit sprites per category (for testing)')
    parser.add_argument('--test', action='store_true', help='Test mode: generate 1 sprite per category')

    args = parser.parse_args()

    # Check API key
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        print("ERROR: OPENAI_API_KEY not set in .env file")
        sys.exit(1)

    generator = TilesetGenerator(api_key)

    if args.status:
        generator.show_status()
        return

    if args.test:
        # Test mode: generate 1 sprite from each category
        print("TEST MODE: Generating 1 sprite per category")
        for category in ['terrain', 'players', 'monsters', 'items']:
            generator.generate_category(category, limit=1)
        return

    if args.category:
        categories = args.category.split(',')
        for cat in categories:
            generator.generate_category(cat.strip(), limit=args.limit)
    elif args.all or args.resume:
        generator.generate_all(parallel=args.parallel)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
