#!/usr/bin/env python3
"""
Necromancer Player Character Sprite Generator
Generates race/house/gender player sprites using DALL-E 3.

Layout: 1 row per race, male/female pairs per house
  Row 0: Elf    → [Lothlorien_M, Lothlorien_F, Rivendell_M, Rivendell_F, Greenwood_M, Greenwood_F]
  Row 1: Man    → [Dunedain_M, Dunedain_F, Rohan_M, Rohan_F, Gondor_M, Gondor_F]
  Row 2: Dwarf  → [Khazad-dum_M, Khazad-dum_F, Erebor_M, Erebor_F, IronHills_M, IronHills_F]
  Row 3: Hobbit → [Shire_M, Shire_F, Gamgees_M, Gamgees_F, Tooks_M, Tooks_F]

Usage:
    python player_gen.py --test           # 8 sprites: 1 house per race, M+F
    python player_gen.py --all            # All 24 sprites
    python player_gen.py --race elf       # All houses for one race (6 sprites)
    python player_gen.py --status         # Show progress
    python player_gen.py --darken         # Generate dark variants from existing
"""

import os
import sys
import json
import time
import base64
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import io

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter, ImageEnhance
    import numpy as np
except ImportError:
    print("Required packages not installed. Run:")
    print("  pip install openai pillow python-dotenv numpy")
    sys.exit(1)

# Constants
TILE_SIZE = 64
MAX_RETRIES = 3
RATE_LIMIT_DELAY = 2.5
COST_PER_IMAGE = 0.04
WHITE_THRESHOLD = 240

# Paths
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "player_v2"
PROGRESS_PATH = BASE_DIR / "player_v2_progress.json"

# ============================================================================
# RACE & HOUSE DEFINITIONS
# ============================================================================

RACES = {
    "elf": {
        "race_id": 0,
        "display_name": "Elf",
        "base_desc": "tall and slender elf with pointed ears, fair skin, and an ethereal otherworldly beauty",
        "female_mod": "an elven woman with long flowing hair, elegant and graceful",
        "male_mod": "an elven man with angular features, noble bearing",
        "houses": [0, 1, 2],
    },
    "man": {
        "race_id": 1,
        "display_name": "Man",
        "base_desc": "human warrior of Middle-earth, weathered and determined",
        "female_mod": "a human woman, strong and resolute, practical build",
        "male_mod": "a human man, rugged and battle-worn",
        "houses": [3, 4, 5],
    },
    "dwarf": {
        "race_id": 2,
        "display_name": "Dwarf",
        "base_desc": "short and stocky dwarf with a thick beard, broad shoulders, and powerful build",
        "female_mod": "a dwarven woman, stout and strong, braided hair adorned with metal clasps",
        "male_mod": "a dwarven man with a magnificent braided beard, barrel-chested",
        "houses": [6, 7, 8],
    },
    "hobbit": {
        "race_id": 4,
        "display_name": "Hobbit",
        "base_desc": "very small halfling with curly hair, round face, and bare furry feet",
        "female_mod": "a hobbit woman, short and round-faced with curly hair, bare feet",
        "male_mod": "a hobbit man, short and stout with curly hair, bare hairy feet",
        "houses": [9, 10, 11],
    },
}

HOUSES = {
    # Elf houses
    0: {
        "name": "Of Lothlorien",
        "short": "Lothlorien",
        "male_desc": "wearing flowing silver and gold robes with leaf patterns, a circlet of mallorn leaves on their head, gripping a tall golden longbow in one hand, a serene noble expression on a handsome fair-skinned face, woodland guardian of the golden wood",
        "female_desc": "wearing a long flowing white gown adorned with silver starlight embroidery, a circlet of mithril and diamonds on their head, one hand gracefully extended, mystical and regal like a queen of the elves, fair luminous skin",
        "desc": "wearing flowing silver and gold robes with leaf patterns, a circlet of mallorn leaves on their head, carrying a longbow, woodland mystic of the golden wood",
        "colors": "silver, gold, forest green, white, soft inner glow",
    },
    1: {
        "name": "Of Rivendell",
        "short": "Rivendell",
        "male_desc": "with dark jet black long straight hair, wearing gilded elven plate armor with gold engravings over dark metal, holding a long curved elvish sword upright in front of him, a handsome noble elven face, an elven lord warrior",
        "female_desc": "with dark jet black long straight hair, wearing gilded elven plate armor with gold engravings over dark metal, holding a long curved elvish sword upright, a beautiful noble elven face, an elven warrior",
        "desc": "wearing gilded elven plate armor with gold engravings, dark jet black long hair, holding a curved elvish sword",
        "colors": "dark metal, burnished gold, black hair, silver engravings",
    },
    2: {
        "name": "Of Greenwood",
        "short": "Greenwood",
        "male_desc": "wearing dark green and brown woodland leathers with a hooded cloak, dual short swords drawn and ready, a deadly silent assassin of the forest",
        "female_desc": "wearing dark green and brown woodland leathers with a hooded cloak, drawing a longbow with an arrow nocked, stealthy forest archer emerging from shadows",
        "desc": "wearing dark green and brown woodland leathers with a hooded cloak, quiver of arrows on their back, stealthy forest hunter",
        "colors": "dark green, earth brown, moss green, shadow black",
    },
    # Man houses
    3: {
        "name": "Dunedain",
        "short": "Dunedain",
        "male_desc": "wearing a worn travel-stained dark green ranger cloak with a silver star brooch, leather armor underneath, holding a large two-handed greatsword upright in front of him, vigilant wanderer of the wild",
        "female_desc": "wearing a worn travel-stained dark green ranger cloak with a silver star brooch, leather armor underneath, holding a longbow in one hand, vigilant wanderer of the wild",
        "desc": "wearing a worn travel-stained dark green ranger cloak with a silver star brooch, leather armor underneath, vigilant wanderer of the wild",
        "colors": "dark green, weathered brown, silver star, warm tan skin",
    },
    4: {
        "name": "Of Rohan",
        "short": "Rohan",
        "desc": "wearing chainmail armor with a green surcoat bearing a white horse emblem on the chest, a round wooden shield, blond hair, stern warrior",
        "colors": "green, gold, brown leather, iron chainmail",
    },
    5: {
        "name": "Of Gondor",
        "short": "Gondor",
        "male_desc": "wearing a long dark black cloth tabard over a breastplate, the tabard has a white tree emblem on the chest, no helmet, warm tan skin, dark brown hair, noble handsome face, holding a sword in one hand and a large heavy kite shield in the other, a Tower Guard of Minas Tirith",
        "female_desc": "wearing a long dark black cloth tabard over a breastplate, the tabard has a white tree emblem on the chest, no helmet, warm tan skin, dark brown hair, noble face, gripping a long great spear upright in both hands, a Tower Guard of Minas Tirith",
        "desc": "wearing a long dark black cloth tabard over a breastplate, the tabard has a white tree emblem on the chest, no helmet, warm tan skin, dark brown hair, noble handsome face, a Tower Guard of Minas Tirith",
        "colors": "black tabard, white tree emblem, warm tan skin, dark brown hair",
    },
    # Dwarf houses
    6: {
        "name": "Of Khazad-dum",
        "short": "Khazad-dum",
        "male_desc": "wearing ancient ornate mithril-inlaid armor in deep blue with gold runes, a magnificent long braided blue-gray beard, gripping a war axe in one hand and a leather-bound tome of lore in the other, keeper of ancient dwarven secrets",
        "female_desc": "wearing ancient ornate mithril-inlaid armor in deep blue with gold runes, braided hair adorned with mithril clasps, holding a rune-carved staff in one hand and a glowing crystal in the other, lorekeeper of the great halls",
        "desc": "wearing ancient ornate mithril-inlaid armor in deep blue, carrying a tome of lore and a war axe, keeper of ancient dwarven secrets from the great halls",
        "colors": "deep blue, mithril silver, ancient gold runes",
    },
    7: {
        "name": "Of Erebor",
        "short": "Erebor",
        "male_desc": "wearing a thick leather forge apron over chainmail armor, a magnificent red-gold braided beard, soot on his face, holding a large forge hammer in one hand, tools and tongs hanging from his belt, master smith of the Lonely Mountain",
        "female_desc": "wearing a thick leather forge apron over chainmail armor, braided red hair tied back with iron rings, soot-marked face, holding heavy forge tongs in one hand, tools hanging from her belt, master craftswoman of the Lonely Mountain",
        "desc": "wearing a leather forge apron over sturdy armor, tools and tongs at their belt, soot-marked master craftsman from the Lonely Mountain",
        "colors": "red, gold, iron gray, warm forge-orange",
    },
    8: {
        "name": "Of the Iron Hills",
        "short": "Iron Hills",
        "male_desc": "wearing heavy iron battle plate armor with rivets and dents, a wild dark braided beard, scarred face, gripping a massive double-headed war axe in both hands, a battle-hardened veteran warrior",
        "female_desc": "wearing heavy iron battle plate armor with rivets and dents, dark braided hair in a war braid, scarred arms, gripping a heavy war hammer in one hand and a battered iron shield in the other, a battle-hardened veteran warrior",
        "desc": "wearing heavy iron battle plate armor, carrying a massive war axe, scarred and battle-hardened veteran warrior",
        "colors": "iron gray, dark steel, rust red, dried blood brown",
    },
    # Hobbit houses
    9: {
        "name": "Of the Shire",
        "short": "Shire",
        "male_desc": "wearing a cozy earth-toned vest with bright brass buttons over a linen shirt, rolled-up trousers, gripping a sturdy walking stick in one hand, a small glowing ring on a chain around his neck, humble but determined round face",
        "female_desc": "wearing a warm embroidered shawl over a practical dress with an apron, holding a heavy cast-iron frying pan in one hand like a weapon, a small pouch of herbs at her belt, kind but fierce round face",
        "desc": "wearing simple comfortable earth-toned clothes with a vest and brass buttons, carrying a walking stick, humble and determined with an inner strength",
        "colors": "earth brown, warm green, cream, brass",
    },
    10: {
        "name": "Of the Gamgees",
        "short": "Gamgees",
        "male_desc": "wearing sturdy brown work clothes with a thick leather gardening belt, pruning shears and a trowel hanging from the belt, gripping a short elvish sword awkwardly in one hand, loyal stalwart expression, dirt on his hands",
        "female_desc": "wearing practical brown work clothes with a thick leather gardening belt, a woven flower crown on her curly hair, gripping a heavy gardening spade like a staff in both hands, loyal stalwart expression, soil-stained apron",
        "desc": "wearing practical sturdy work clothes, a gardener's belt with pruning tools, carrying a short sword awkwardly, loyal and stalwart common folk",
        "colors": "brown, tan, garden green, soil brown",
    },
    11: {
        "name": "Of the Tooks",
        "short": "Tooks",
        "male_desc": "wearing fine rich green velvet coat with gold trim over a brocade waistcoat, a wide-brimmed hat with a bright yellow feather, holding a large elegant longbow in one hand, a quiver of arrows on his back, wealthy old-money adventurer with a knowing smile",
        "female_desc": "wearing light green adventurer's leathers with a colorful scarf around her neck, a small crossbow in one hand, a pouch of bolts at her hip, bright-eyed mischievous grin, daring and bold",
        "desc": "wearing light adventurer's leather with a feathered cap, a sling at their hip, bright-eyed and mischievous with a dash of daring",
        "colors": "forest green, warm brown, crimson accent, gold buckle",
    },
}

# Test mode: 1 representative house per race
TEST_HOUSES = {
    "elf": 0,       # Lothlorien
    "man": 3,        # Dunedain
    "dwarf": 7,      # Erebor
    "hobbit": 9,     # Shire
}


def get_player_prompt(race_key: str, house_id: int, gender: str) -> str:
    """
    Build a DALL-E 3 prompt for a player character sprite.

    DALL-E rules:
    - NEVER use "pixel art", "game tile", "sprite", "texture"
    - Frame as "painting" or "illustration"
    - style="natural"

    Character sprite rules (v2 - distinct style):
    - BRIGHT saturated colors so characters read at 64x64
    - Simple bold shapes, minimal fine detail
    - Pure black background for clean silhouette
    - Single centered figure, no pairs or groups
    - Front-facing, fills the frame
    """
    race = RACES[race_key]
    house = HOUSES[house_id]

    if gender == "male":
        char_desc = race["male_mod"]
        house_desc = house.get("male_desc", house["desc"])
    else:
        char_desc = race["female_mod"]
        house_desc = house.get("female_desc", house["desc"])

    prompt = (
        f"On a completely solid flat hot magenta background (hex FF00FF), "
        f"a vivid fantasy illustration of {char_desc}, "
        f"{house_desc}. "
        f"Full body from head to toe, standing centered facing the viewer. "
        f"Vivid striking colors: {house['colors']}. "
        f"Strong readable silhouette, bold saturated armor and clothing. "
        f"The background must be entirely uniform solid magenta with absolutely nothing else. "
        f"A single character only, no other elements. "
        f"Painted in a clean illustrative style."
    )

    return prompt


def auto_crop_and_stretch(img: Image.Image, target_size: int = TILE_SIZE) -> Image.Image:
    """
    Detect content area, crop out white/light borders, stretch to target_size.
    Same algorithm as terrain_gen.py.
    """
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]

    r, g, b = img_array[:, :, 0], img_array[:, :, 1], img_array[:, :, 2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD

    rows_with_content = np.any(content_mask, axis=1)
    cols_with_content = np.any(content_mask, axis=0)

    if not np.any(rows_with_content) or not np.any(cols_with_content):
        print("  WARNING: Image appears entirely white/blank")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)

    row_start = np.argmax(rows_with_content)
    row_end = h - np.argmax(rows_with_content[::-1])
    col_start = np.argmax(cols_with_content)
    col_end = w - np.argmax(cols_with_content[::-1])

    border_top = row_start
    border_bottom = h - row_end
    border_left = col_start
    border_right = w - col_end

    print(f"  Border: top={border_top} bot={border_bottom} "
          f"left={border_left} right={border_right}")

    min_border = int(h * 0.02)
    if (border_top > min_border or border_bottom > min_border or
            border_left > min_border or border_right > min_border):

        padding = 2
        row_start = max(0, row_start - padding)
        row_end = min(h, row_end + padding)
        col_start = max(0, col_start - padding)
        col_end = min(w, col_end + padding)

        cropped = img.crop((col_start, row_start, col_end, row_end))
        crop_w, crop_h = cropped.size
        print(f"  Cropped: {w}x{h} -> {crop_w}x{crop_h}")

        if crop_w != crop_h:
            max_dim = max(crop_w, crop_h)
            square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 255))
            paste_x = (max_dim - crop_w) // 2
            paste_y = (max_dim - crop_h) // 2
            square.paste(cropped, (paste_x, paste_y))
            cropped = square
            print(f"  Squared: {max_dim}x{max_dim}")

        result = cropped.resize((target_size, target_size), Image.Resampling.NEAREST)
        print(f"  Resized to {target_size}x{target_size}")
        return result
    else:
        print(f"  No significant border - direct resize")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)


def generate_dark_variant(img: Image.Image) -> Image.Image:
    """Generate dark/FOV variant: desaturate 60%, darken 40%, cool blue tint."""
    if img.mode == "RGBA":
        alpha = img.split()[3]
        rgb = img.convert("RGB")
    else:
        alpha = None
        rgb = img.convert("RGB")

    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)

    darkener = ImageEnhance.Brightness(desaturated)
    darkened = darkener.enhance(0.6)

    arr = np.array(darkened).astype(np.float32)
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, "RGB")

    if alpha is not None:
        result = result.convert("RGBA")
        result.putalpha(alpha)

    return result


def validate_tile(img: Image.Image) -> Tuple[bool, str]:
    """Validate a generated player tile."""
    w, h = img.size
    if w != TILE_SIZE or h != TILE_SIZE:
        return False, f"Wrong size: {w}x{h}"

    arr = np.array(img.convert("RGB"))
    brightness = arr.mean()
    if brightness > 200:
        return False, f"Too bright (avg {brightness:.0f})"

    std = arr.std()
    if std < 8:
        return False, f"Too uniform (std {std:.1f})"

    return True, "OK"


class PlayerGenerator:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.progress = self._load_progress()

    def _load_progress(self) -> Dict:
        if PROGRESS_PATH.exists():
            with open(PROGRESS_PATH, "r") as f:
                return json.load(f)
        return {
            "started_at": datetime.now().isoformat(),
            "last_updated": datetime.now().isoformat(),
            "sprites": {},
            "cost_total": 0.0,
            "api_calls": 0,
        }

    def _save_progress(self):
        self.progress["last_updated"] = datetime.now().isoformat()
        with open(PROGRESS_PATH, "w") as f:
            json.dump(self.progress, f, indent=2)

    def _sprite_key(self, race_key: str, house_id: int, gender: str) -> str:
        return f"player_{race_key}_h{house_id}_{gender}"

    def generate_single(self, race_key: str, house_id: int, gender: str,
                        retry: int = 0) -> Optional[Path]:
        """Generate a single player character sprite."""
        key = self._sprite_key(race_key, house_id, gender)
        house = HOUSES[house_id]
        race = RACES[race_key]

        # Skip if already completed
        if key in self.progress["sprites"]:
            info = self.progress["sprites"][key]
            if info.get("status") == "completed":
                existing = Path(info["path"])
                if existing.exists():
                    print(f"  SKIP: {key} already completed")
                    return existing

        prompt = get_player_prompt(race_key, house_id, gender)
        label = f"{race['display_name']} {house['short']} ({gender})"
        print(f"\n{'=' * 60}")
        print(f"Generating: {label}")
        print(f"Key: {key}")
        print(f"Prompt: {prompt[:150]}...")

        try:
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style="vivid",
                n=1,
                response_format="b64_json",
            )

            self.progress["api_calls"] = self.progress.get("api_calls", 0) + 1
            self.progress["cost_total"] = self.progress.get("cost_total", 0) + COST_PER_IMAGE

            img_data = base64.b64decode(response.data[0].b64_json)
            img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")

            revised = getattr(response.data[0], "revised_prompt", None)
            if revised:
                print(f"  DALL-E revised: {revised[:120]}...")

            # Save raw 1024x1024
            raw_dir = self.output_dir / "raw"
            raw_dir.mkdir(exist_ok=True)
            raw_path = raw_dir / f"{key}_1024.png"
            img_1024.save(raw_path)
            print(f"  Saved raw: {raw_path.name}")

            # Auto-crop and resize to 64x64
            img_64 = auto_crop_and_stretch(img_1024, TILE_SIZE)

            # Validate
            is_valid, reason = validate_tile(img_64)
            if not is_valid:
                print(f"  VALIDATION FAILED: {reason}")
                if retry < MAX_RETRIES:
                    print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                    time.sleep(RATE_LIMIT_DELAY)
                    return self.generate_single(race_key, house_id, gender, retry + 1)
                else:
                    print(f"  MAX RETRIES - saving for manual review")

            # Save light variant
            race_dir = self.output_dir / race_key
            race_dir.mkdir(exist_ok=True)
            light_path = race_dir / f"{key}_light.png"
            img_64.save(light_path)
            print(f"  Saved light: {light_path.name}")

            # Generate and save dark variant
            img_dark = generate_dark_variant(img_64)
            dark_path = race_dir / f"{key}_dark.png"
            img_dark.save(dark_path)
            print(f"  Saved dark: {dark_path.name}")

            # Update progress
            self.progress["sprites"][key] = {
                "status": "completed",
                "path": str(light_path),
                "dark_path": str(dark_path),
                "race": race_key,
                "house_id": house_id,
                "house_name": house["short"],
                "gender": gender,
                "valid": is_valid,
                "validation_msg": reason,
                "completed_at": datetime.now().isoformat(),
            }
            self._save_progress()

            return light_path

        except Exception as e:
            print(f"  ERROR: {e}")
            if retry < MAX_RETRIES:
                print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                time.sleep(RATE_LIMIT_DELAY * 2)
                return self.generate_single(race_key, house_id, gender, retry + 1)

            self.progress["sprites"][key] = {
                "status": "failed",
                "error": str(e),
                "race": race_key,
                "house_id": house_id,
                "gender": gender,
                "failed_at": datetime.now().isoformat(),
            }
            self._save_progress()
            return None

    def generate_test(self) -> Dict[str, bool]:
        """Generate 1 house per race, male + female = 8 sprites for review."""
        results = {}
        print("\n" + "=" * 60)
        print("PLAYER TEST GENERATION - 8 sprites (1 house per race, M+F)")
        print("=" * 60)

        for race_key, house_id in TEST_HOUSES.items():
            house = HOUSES[house_id]
            race = RACES[race_key]
            print(f"\n--- {race['display_name']} / {house['short']} ---")

            for gender in ["male", "female"]:
                key = self._sprite_key(race_key, house_id, gender)
                path = self.generate_single(race_key, house_id, gender)
                results[key] = path is not None
                time.sleep(RATE_LIMIT_DELAY)

        self._print_summary(results)
        return results

    def generate_race(self, race_key: str) -> Dict[str, bool]:
        """Generate all houses for a single race (6 sprites)."""
        if race_key not in RACES:
            print(f"Unknown race: {race_key}")
            print(f"Available: {list(RACES.keys())}")
            return {}

        race = RACES[race_key]
        results = {}
        print(f"\n{'=' * 60}")
        print(f"Generating all {race['display_name']} houses ({len(race['houses'])} houses × 2 genders)")
        print(f"{'=' * 60}")

        for house_id in race["houses"]:
            house = HOUSES[house_id]
            print(f"\n--- {house['short']} ---")
            for gender in ["male", "female"]:
                key = self._sprite_key(race_key, house_id, gender)
                path = self.generate_single(race_key, house_id, gender)
                results[key] = path is not None
                time.sleep(RATE_LIMIT_DELAY)

        self._print_summary(results)
        return results

    def generate_all(self) -> Dict[str, bool]:
        """Generate all 24 player sprites."""
        results = {}
        print(f"\n{'=' * 60}")
        print(f"FULL PLAYER GENERATION - 24 sprites (4 races × 3 houses × 2 genders)")
        print(f"{'=' * 60}")

        for race_key in RACES:
            race_results = self.generate_race(race_key)
            results.update(race_results)

        print(f"\n{'=' * 60}")
        print(f"ALL PLAYERS COMPLETE")
        self._print_summary(results)
        return results

    def generate_dark_variants_only(self):
        """Generate dark variants for all existing light sprites."""
        count = 0
        for key, info in self.progress["sprites"].items():
            if info.get("status") != "completed":
                continue
            light_path = Path(info["path"])
            if not light_path.exists():
                continue
            dark_path = light_path.parent / light_path.name.replace("_light.", "_dark.")
            if dark_path.exists():
                continue

            img = Image.open(light_path).convert("RGBA")
            dark = generate_dark_variant(img)
            dark.save(dark_path)
            info["dark_path"] = str(dark_path)
            count += 1
            print(f"  Generated dark: {dark_path.name}")

        self._save_progress()
        print(f"\nGenerated {count} dark variants")

    def show_status(self):
        """Display generation progress."""
        print(f"\n{'=' * 60}")
        print("PLAYER SPRITE GENERATION STATUS")
        print(f"{'=' * 60}")

        for race_key, race in RACES.items():
            total = len(race["houses"]) * 2  # M+F per house
            done = 0
            for house_id in race["houses"]:
                for gender in ["male", "female"]:
                    key = self._sprite_key(race_key, house_id, gender)
                    if key in self.progress["sprites"]:
                        if self.progress["sprites"][key].get("status") == "completed":
                            done += 1

            bar_len = 20
            filled = int(bar_len * done / total) if total > 0 else 0
            bar = "#" * filled + "-" * (bar_len - filled)
            houses_str = ", ".join(HOUSES[h]["short"] for h in race["houses"])
            print(f"  {race['display_name']:8s} [{bar}] {done}/{total}  ({houses_str})")

        total_done = sum(
            1 for info in self.progress["sprites"].values()
            if info.get("status") == "completed"
        )
        print(f"\n  Total: {total_done}/24")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Est. cost: ${self.progress.get('cost_total', 0):.2f}")
        print(f"  Output: {self.output_dir}/")

    def _print_summary(self, results: Dict[str, bool]):
        print(f"\n{'=' * 60}")
        print("GENERATION SUMMARY")
        print(f"{'=' * 60}")
        succeeded = sum(1 for v in results.values() if v)
        failed = sum(1 for v in results.values() if not v)
        for key, success in results.items():
            status = "OK" if success else "FAILED"
            print(f"  {key}: {status}")
        print(f"\n  Succeeded: {succeeded}, Failed: {failed}")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Est. cost: ${self.progress.get('cost_total', 0):.2f}")
        print(f"\n  Review sprites at: {self.output_dir}/")
        print(f"  Raw 1024x1024 at: {self.output_dir}/raw/")


def main():
    parser = argparse.ArgumentParser(description="Necromancer Player Sprite Generator")
    parser.add_argument("--test", action="store_true",
                        help="Generate 8 test sprites (1 house per race, M+F)")
    parser.add_argument("--all", action="store_true",
                        help="Generate all 24 player sprites")
    parser.add_argument("--race", type=str,
                        help="Generate all houses for a race (elf/man/dwarf/hobbit)")
    parser.add_argument("--status", action="store_true",
                        help="Show progress status")
    parser.add_argument("--darken", action="store_true",
                        help="Generate dark variants from existing light sprites")
    args = parser.parse_args()

    if args.status:
        gen = PlayerGenerator("dummy")
        gen.show_status()
        return

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found in environment or .env file")
        sys.exit(1)

    gen = PlayerGenerator(api_key)

    if args.darken:
        gen.generate_dark_variants_only()
    elif args.test:
        gen.generate_test()
    elif args.all:
        gen.generate_all()
    elif args.race:
        gen.generate_race(args.race.lower())
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
