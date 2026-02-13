#!/usr/bin/env python3
"""
DALL-E Generation for Tier 4 — Necropolis (depths 10-12)

14 monsters, all on GREEN BG (#00FF00), using v6 best practices:
- 50/50 portrait vs full body framing
- "Plain flat green background only, absolutely no other elements"
- style="vivid", quality="standard"
- Solid opaque bodies, weapons overlapping torso
- Content-policy safe language

Full body (all 14): 72, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 86, 91, 100
Round 2: converted 7 portrait → full body
"""

import os
import sys
import base64
import io
import time
import argparse
from pathlib import Path

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from openai import OpenAI
from PIL import Image

BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "monster_v2" / "raw"

REGENS = {
    72: {
        "name": "Skeleton Warrior",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of an ancient armored bone warrior. "
            "Full body head to toe, centered. Ivory-white bones beneath rusted iron chainmail and a battered iron helm. "
            "Gripping a weathered iron sword in one hand. "
            "Dark hollow eye sockets with faint amber pinpoints of magical energy. "
            "Solid opaque thick bones with well-defined joints. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Iron-gray and bone-white highlights only. A single figure only."
        ),
    },
    74: {
        "name": "Wight",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a wight, a powerful undead lord. "
            "Full body head to toe, centered. Pale gray desiccated skin stretched over sharp angular features. "
            "Cold blue-white glowing eyes sunken deep in dark hollows. "
            "Wearing tarnished silver crown and decayed dark noble robes with silver thread. "
            "One clawed hand raised, pale fingers wreathed in cold blue mist. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Silver and ice-blue highlights only. A single figure only."
        ),
    },
    75: {
        "name": "Corpse-candle",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a corpse-candle, a ghostly floating orb of pale yellow light. "
            "Full body, centered. A solid glowing sphere of warm amber-yellow light "
            "with a faint corona of pale white wisps trailing behind it. "
            "Inside the orb a faint ghostly skull face is barely visible. "
            "Solid opaque glowing orb with well-defined edges, not transparent. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Amber-yellow and pale white highlights only. A single light only."
        ),
    },
    76: {
        "name": "Necromancer Adept",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a necromancer sorcerer. "
            "Full body head to toe, centered. Gaunt pale man in layered dark charcoal robes with bone-white trim. "
            "A deep cowl partially shadowing the face, revealing hollow cheeks and dark-ringed eyes. "
            "Both hands raised, dark violet energy crackling between thin fingers. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Violet and bone-white highlights only. A single figure only."
        ),
    },
    77: {
        "name": "Barrow-wight",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a barrow-wight, a tall powerful undead king. "
            "Full body head to toe, centered. Decayed dark royal armor over desiccated gray flesh. "
            "A heavy ancient iron crown on its skull-like head. "
            "Wielding a long pale sword that glows with cold blue light. "
            "Tattered dark cloak flowing behind it. Tall imposing stance. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Ice-blue and dark iron highlights only. A single figure only."
        ),
    },
    78: {
        "name": "Bone Golem",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a bone golem, a towering construct made of fused bones. "
            "Full body head to toe, centered. Massive hulking frame built from hundreds of yellowed bones "
            "fused together into a vaguely humanoid shape. "
            "Thick bone-plate armor across the chest, massive bone fists. "
            "A skull for a head with dark empty sockets glowing faint purple. "
            "Solid opaque body, heavy and dense. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Bone-white and dark purple highlights only. A single creature only."
        ),
    },
    79: {
        "name": "Grishnakh Crypt Lord",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a crypt lord, a powerful undead overlord. "
            "Full body head to toe, centered, facing the viewer directly. "
            "Tall imposing figure in heavy dark plate armor with violet runic engravings. "
            "Desiccated dark gray skin, gaunt angular skull-like face. "
            "Burning violet eyes. Ornate blackened iron crown with dark gems. "
            "One clawed hand crackling with dark violet energy. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark violet and iron-black highlights only. A single figure only."
        ),
    },
    81: {
        "name": "Cave Troll",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a massive cave troll. "
            "Full body head to toe, centered. Enormous gray-brown thick hide "
            "with rocky lumps and stone-like skin. Hunched powerful frame with long muscular arms "
            "dragging on the ground. Small beady dark eyes, wide flat nose, jutting lower tusks. "
            "Wearing only a crude leather loincloth and heavy iron shackles on the wrists. "
            "Solid opaque body, heavy and dense. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Stone-gray and dark brown highlights only. A single creature only."
        ),
    },
    82: {
        "name": "Dark Ritualist",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a dark ritualist sorcerer. "
            "Full body head to toe, centered. Thin pale man in heavy black velvet robes covered in silver occult symbols. "
            "A tall dark headdress with silver ornament at the center. "
            "Holding a curved ritual dagger in one hand, a dark crystal orb in the other. "
            "Sunken dark eyes with an unsettling calm expression. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Silver and dark violet highlights only. A single figure only."
        ),
    },
    83: {
        "name": "Corsair of Umbar",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a southern pirate warrior. "
            "Full body head to toe, centered. Dark olive skin, sharp features, trimmed black beard. "
            "Wearing a dark crimson sash over black leather armor. "
            "Gripping twin curved daggers, one in each hand. "
            "A dark headscarf tied back, gold earring. Fierce confident expression. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Crimson and gold highlights only. A single figure only."
        ),
    },
    84: {
        "name": "Dunlending Berserker",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a wild barbarian berserker. "
            "Full body head to toe, centered. Tall muscular man with no armor, "
            "only dark war paint in jagged patterns across bare chest and face. "
            "Wild tangled dark hair and a thick braided beard. "
            "Wielding a massive two-handed iron battle axe raised overhead in a war cry. "
            "Dark fur loincloth and leather boots. Fierce raging expression. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark iron and war-paint blue highlights only. A single figure only."
        ),
    },
    86: {
        "name": "Pale Crawler",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a pale crawler, a blind cave-dwelling creature. "
            "Full body, centered. A pale white eyeless humanoid on all fours in a crawling pose. "
            "Smooth hairless white skin stretched over an emaciated frame. "
            "Long spindly limbs with oversized clawed hands. "
            "Eyeless face with a wide mouth full of needle teeth, no nose. "
            "Long pale tongue lolling out. Solid opaque body, sickly and disturbing. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Pale white and ivory highlights only. A single creature only."
        ),
    },
    91: {
        "name": "Phantom",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a phantom, an undead spirit. "
            "Full body, centered. A translucent pale blue-gray humanoid figure "
            "hovering above the ground. Tattered spectral robes flowing downward. "
            "A hollow screaming face with dark empty eyes and gaping mouth. "
            "Arms outstretched with clawed spectral fingers. "
            "Solid opaque ghostly form with well-defined edges, not transparent. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Pale blue and silver-gray highlights only. A single figure only."
        ),
    },
    100: {
        "name": "Black Numenorean Acolyte",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a dark sorcerer in long robes. "
            "Full body head to toe, centered. Tall pale man with sharp noble features and cold dark eyes. "
            "Wearing heavy black robes with dark red arcane sigils stitched in the fabric. "
            "A dark iron circlet on his brow. One hand raised with dark red energy swirling in the palm. "
            "Aristocratic bearing, cruel thin mouth. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark red and iron-black highlights only. A single figure only."
        ),
    },
}


def main():
    parser = argparse.ArgumentParser(description="Tier 4 Monster Generation")
    parser.add_argument("--ids", type=int, nargs="+", help="Generate specific IDs only")
    args = parser.parse_args()

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found in environment")
        print("Run: export $(cat tileset_generation/.env | xargs)")
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    gen_ids = args.ids if args.ids else sorted(REGENS.keys())
    success = 0
    failed = []

    for monster_id in gen_ids:
        if monster_id not in REGENS:
            print(f"  #{monster_id}: not in REGENS, skipping")
            continue

        info = REGENS[monster_id]
        print(f"\n{'='*60}")
        print(f"Generating #{monster_id} {info['name']} (green BG)")
        print(f"{'='*60}")

        existing = OUTPUT_DIR / f"monster_{monster_id}_1024.png"
        if existing.exists():
            for suffix in ["_t4_backup", "_v2_backup", "_magenta_backup"]:
                backup = OUTPUT_DIR / f"monster_{monster_id}_1024{suffix}.png"
                if not backup.exists():
                    existing.rename(backup)
                    print(f"  Backed up existing raw -> {backup.name}")
                    break

        word_count = len(info["prompt"].split())
        print(f"  Prompt ({word_count} words): {info['prompt'][:120]}...")

        try:
            response = client.images.generate(
                model="dall-e-3",
                prompt=info["prompt"],
                size="1024x1024",
                quality="standard",
                style="vivid",
                n=1,
                response_format="b64_json",
            )

            img_data = base64.b64decode(response.data[0].b64_json)
            img = Image.open(io.BytesIO(img_data)).convert("RGBA")

            output_path = OUTPUT_DIR / f"monster_{monster_id}_1024.png"
            img.save(output_path)
            print(f"  Saved: {output_path}")

            revised = getattr(response.data[0], "revised_prompt", None)
            if revised:
                print(f"  DALL-E revised: {revised[:150]}...")

            success += 1
            print(f"  Done!")

        except Exception as e:
            print(f"  ERROR: {e}")
            failed.append((monster_id, info["name"], str(e)))
            continue

        time.sleep(2)

    print(f"\n{'='*60}")
    print(f"Generation complete: {success}/{len(gen_ids)} succeeded")
    if failed:
        print(f"FAILED ({len(failed)}):")
        for mid, name, err in failed:
            print(f"  #{mid} {name}: {err[:80]}")
        print(f"\nRetry failed with: python3 regen_tier4.py --ids {' '.join(str(f[0]) for f in failed)}")
    print(f"\nNext: python3 process_monsters_v3.py --tier 4")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
