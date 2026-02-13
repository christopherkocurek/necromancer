#!/usr/bin/env python3
"""
DALL-E Generation for Tier 7 — Deep Combat + Boss Monsters (depths 8-20)

7 monsters, all on GREEN BG (#00FF00), all full body, v6 best practices.
Includes 2 gap monsters from earlier tiers (#80, #87), deep shadow undead,
story NPCs, and the final boss.

Full body (all 7): 80, 87, 132, 133, 134, 135, 137
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
    80: {
        "name": "Easterling Infiltrator",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a stealthy eastern spy warrior. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A lean athletic man in dark leather armor with a dark hooded cloak. "
            "Dark olive skin, sharp features, dark kohl around narrowed eyes. "
            "A dark cloth mask covering the lower face. "
            "Gripping a short curved blade in one hand held close to the body. "
            "Crouched ready stance. Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark brown and steel highlights only. A single figure only."
        ),
    },
    87: {
        "name": "Werewolf",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a massive cursed wolf-beast. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A huge muscular wolf standing upright on its hind legs. "
            "Dark gray-brown fur, powerful broad chest, long clawed hands. "
            "Savage lupine face with glowing amber eyes and bared fangs. "
            "Pointed ears laid back. Thick muscular legs and large clawed feet. "
            "Solid opaque furred body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark gray and amber highlights only. A single creature only."
        ),
    },
    132: {
        "name": "Greater Shadow",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of an immense shadow entity from the void. "
            "Full body, centered, facing the viewer. "
            "A towering humanoid figure made of solid concentrated darkness. "
            "Dense black core body with dark purple edges. "
            "Two burning pale white eyes in a featureless void face. "
            "Massive dark arms with long clawed fingers reaching forward. "
            "Dark tendrils trailing from the body. "
            "Solid opaque dark body with well-defined edges, not transparent. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark purple and pale white highlights only. A single creature only."
        ),
    },
    133: {
        "name": "Void Wraith",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a wraith summoned from beyond the world. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall spectral figure in heavy dark tattered robes with void-black lining. "
            "A dark iron crown floating above a hooded void where a face should be. "
            "Pale skeletal hands wreathed in dark purple energy. "
            "Dark mist swirling at the feet. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark purple and iron-black highlights only. A single figure only."
        ),
    },
    134: {
        "name": "Thrain's Shade",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of the shade of a broken dwarf king. "
            "Full body head to toe, centered, facing the viewer. "
            "A translucent pale blue-gray ghostly dwarf figure. "
            "Long tangled ghostly beard, a tattered spectral crown. "
            "Hunched posture, clutching a small glowing golden key in both hands. "
            "Hollow dark eyes with a look of madness and grief. "
            "Spectral tattered royal robes. Solid opaque ghostly form with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Pale blue and gold highlights only. A single figure only."
        ),
    },
    135: {
        "name": "Sauron the Necromancer",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a terrifying dark lord of immense power. "
            "Full body head to toe, centered, facing the viewer directly, filling most of the frame. "
            "A massive towering figure in ornate burnished bronze and black plate armor "
            "with bright glowing orange-gold rune engravings covering every surface. "
            "A tall spiked iron crown with a single great burning orange eye at its center. "
            "No visible face, only an intense burning orange inferno within the helm. "
            "Arms held close to the body, dark gauntleted fists clenched. "
            "Solid opaque metallic body with well-defined sharp edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Bright orange-gold and bronze highlights only. A single figure only."
        ),
    },
    137: {
        "name": "Mouth of Sauron",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a dark lord's herald and lieutenant. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A tall pale man of ancient age in ornate dark plate armor with dark red rune engravings. "
            "A great dark helm that covers the upper face, leaving only a cruel grinning mouth visible. "
            "Dark flowing robes over the armor. A dark iron staff held vertically "
            "in front of the body, overlapping the torso. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark red and iron-black highlights only. A single figure only."
        ),
    },
}


def main():
    parser = argparse.ArgumentParser(description="Tier 7 Monster Generation")
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
            for suffix in ["_t7_backup", "_t6_backup", "_t5_backup", "_v2_backup", "_magenta_backup"]:
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
        print(f"\nRetry failed with: python3 regen_tier7.py --ids {' '.join(str(f[0]) for f in failed)}")
    print(f"\nNext: python3 process_monsters_v3.py --tier 7")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
