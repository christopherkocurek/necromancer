#!/usr/bin/env python3
"""
DALL-E Generation for Tier 5 — Wraith Domain (depths 13-15)

13 monsters, all on GREEN BG (#00FF00), using v6 best practices:
- ALL full body (lesson from Tier 4: full body preferred)
- "Plain flat green background only, absolutely no other elements"
- style="vivid", quality="standard"
- Solid opaque bodies, weapons overlapping torso
- Content-policy safe language
- "Facing the viewer directly" for humanoids

Full body (all 13): 92, 93, 94, 95, 96, 97, 98, 99, 101, 102, 103, 104, 111

Shadow creatures (92-96): Need "solid opaque" to prevent rembg stripping
Magic users (97, 98, 99, 104, 111): May need COLOR_MERGE for magic effects
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
    92: {
        "name": "Shadow",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a shadow creature, a patch of living darkness. "
            "Full body, centered, facing the viewer. A tall humanoid silhouette made of solid dark smoke. "
            "Dense black core with wispy dark purple edges. "
            "Two faint pale white pinpoints where eyes would be. "
            "Vaguely humanoid shape with long reaching arms and clawed fingers. "
            "Solid opaque dark body with well-defined edges, not transparent. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark purple and black highlights only. A single creature only."
        ),
    },
    93: {
        "name": "Whispering Shade",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a whispering shade, a flickering shadow spirit. "
            "Full body, centered, facing the viewer. A dark wispy humanoid figure "
            "with a tattered dark cloak dissolving into dark smoke at the edges. "
            "No visible face, just a dark void under the hood with faint gray wisps. "
            "Arms spread wide, dark tendrils trailing from the fingertips. "
            "Solid opaque dark body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark gray and charcoal highlights only. A single creature only."
        ),
    },
    94: {
        "name": "Wraith",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a wraith, a mantled undead spirit. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall spectral figure in dark tattered robes, hovering above the ground. "
            "Pale silver-white skeletal hands reaching forward from dark sleeves. "
            "A dark hood with faint cold blue eyes glowing within the void. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Silver and cold blue highlights only. A single figure only."
        ),
    },
    95: {
        "name": "Fell Spirit",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a fell spirit, a malevolent ghost. "
            "Full body, centered, facing the viewer. A translucent pale violet humanoid figure "
            "floating in the air with no legs, trailing into dark mist below. "
            "Hollow dark eyes and a gaping mouth frozen in a silent scream. "
            "Long spectral arms with clawed fingers. "
            "Solid opaque ghostly form with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Pale violet and dark gray highlights only. A single creature only."
        ),
    },
    96: {
        "name": "Spectre",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a spectre, a barely visible undead spirit. "
            "Full body, centered, facing the viewer. A faint pale blue-white humanoid figure "
            "that is almost see-through. Tattered spectral shroud clinging to a skeletal frame. "
            "Dark hollow eyes and a mouth open in anguish. "
            "Icy frost forming on its outstretched hands. "
            "Solid opaque ghostly form with well-defined edges, not transparent. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Pale ice-blue and white highlights only. A single creature only."
        ),
    },
    97: {
        "name": "Vampire Thrall",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a pale nocturnal predator creature. "
            "Full body head to toe, centered, facing the viewer. "
            "Pale gaunt humanoid with sharp angular features and pointed ears. "
            "Sunken dark-ringed eyes with crimson irises. Wearing dark tattered noble clothing "
            "and a torn dark cloak. Long clawed pale hands reaching forward. "
            "Barefoot, crouching predatory stance. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Crimson and pale gray highlights only. A single figure only."
        ),
    },
    98: {
        "name": "The Wailing Horror",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a cosmic horror from beyond the world. "
            "Full body, centered, facing the viewer. A massive dark swirling entity "
            "with a vaguely humanoid upper body emerging from a mass of dark tendrils. "
            "Multiple pale white eyes scattered across its form. "
            "A gaping maw where a face should be, dark void within. "
            "Dark purple and black writhing mass. Solid opaque body. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark purple and pale white highlights only. A single creature only."
        ),
    },
    99: {
        "name": "Uvatha the Horseman",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a Ringwraith, one of the Nine. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall imposing figure in heavy dark iron armor under flowing black robes. "
            "A great dark helm with no visible face, only darkness within. "
            "Wielding a long pale sword in one hand, dark energy crackling along the blade. "
            "A dark iron crown visible beneath the helm. Commanding regal stance. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark iron and cold blue highlights only. A single figure only."
        ),
    },
    101: {
        "name": "Haradrim Assassin",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of an elite southern rogue warrior. "
            "Full body head to toe, centered, facing the viewer. "
            "Lean athletic man in dark leather armor wrapped in dark cloth bindings. "
            "Dark olive skin, sharp features, dark kohl around the eyes. "
            "A dark face wrap covering the lower face. "
            "Gripping a curved dagger in each hand, blades gleaming. "
            "Crouched ready stance. Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark crimson and steel highlights only. A single figure only."
        ),
    },
    102: {
        "name": "Cave Worm",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a massive cave worm, a tunneling beast. "
            "Full body, centered, facing the viewer. A huge segmented worm "
            "with thick dark brown armored hide and pale underbelly. "
            "Massive circular mouth filled with rows of jagged teeth. "
            "Dark beady eyes on either side of the head. "
            "Thick muscular body coiled in an S-shape. "
            "Solid opaque body, heavy and dense. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark brown and pale ivory highlights only. A single creature only."
        ),
    },
    103: {
        "name": "Oathbreaker Captain",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a traitorous human captain. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall armored man in battered dark steel plate armor with a torn dark cloak. "
            "A scarred weathered face with cold gray eyes and short dark hair. "
            "The armor bears scratched-out heraldry of a once-noble house. "
            "Wielding a heavy dark steel longsword in one hand. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark steel and iron-gray highlights only. A single figure only."
        ),
    },
    104: {
        "name": "Morgul Sorcerer",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a sorcerer trained in dark Morgul arts. "
            "Full body head to toe, centered, facing the viewer. "
            "A pale gaunt man in heavy dark violet robes with silver rune embroidery. "
            "A dark iron staff held across the body, overlapping the torso. "
            "One hand gripping the staff, the other hand pressed to his chest "
            "with a pale violet orb of energy glowing in the palm against his robes. "
            "Dark hollow eyes glowing faint violet. A silver circlet on his brow. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark violet and silver highlights only. A single figure only."
        ),
    },
    111: {
        "name": "Black Numenorean",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a dark warrior-sorcerer. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall imposing pale man in dark plate armor with dark red rune engravings. "
            "A heavy dark cloak over the armor. Sharp noble features, cold dark eyes. "
            "A dark iron crown on his brow. Wielding a dark steel sword in one hand, "
            "dark red magical energy swirling around the other. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark red and iron-black highlights only. A single figure only."
        ),
    },
}


def main():
    parser = argparse.ArgumentParser(description="Tier 5 Monster Generation")
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
            for suffix in ["_t5_backup", "_t4_backup", "_v2_backup", "_magenta_backup"]:
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
        print(f"\nRetry failed with: python3 regen_tier5.py --ids {' '.join(str(f[0]) for f in failed)}")
    print(f"\nNext: python3 process_monsters_v3.py --tier 5")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
