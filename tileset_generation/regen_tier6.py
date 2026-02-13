#!/usr/bin/env python3
"""
DALL-E Generation for Tier 6 — Inner Sanctum (depths 15-18)

9 monsters, all on GREEN BG (#00FF00), all full body, v6 best practices.
Mix of battle trolls, vampires, shadow undead, a corrupted Maia, and a Nazgûl boss.

Full body (all 9): 112, 113, 114, 115, 116, 117, 118, 131, 136
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
    112: {
        "name": "Olog-hai",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a massive battle-troll bred for war. "
            "Full body head to toe, centered, facing the viewer. "
            "Enormous muscular gray-brown troll with thick armored hide. "
            "Wearing crude dark iron plate armor on the chest and shoulders. "
            "Small cunning eyes, heavy jaw with jutting tusks. "
            "Wielding a massive dark iron war hammer in both hands. "
            "Solid opaque body, heavy and dense. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark iron and stone-gray highlights only. A single creature only."
        ),
    },
    113: {
        "name": "Vampire",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a monstrous nocturnal predator in bat-like form. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A tall humanoid figure with dark leathery bat wings folded close behind the back, "
            "wing tips visible on both sides overlapping the body. "
            "Pale gray skin, gaunt angular face with sharp features and crimson eyes. "
            "Long clawed pale hands held close to the body. Wearing tattered dark noble robes. "
            "Compact solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Crimson and dark gray highlights only. A single creature only."
        ),
    },
    114: {
        "name": "Greater Wraith",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a greater wraith, a powerful undead spirit lord. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall imposing spectral figure in heavy dark tattered royal robes. "
            "A dark crown on its hooded head. Pale skeletal hands reaching forward. "
            "Faint cold blue eyes glowing within the dark hood. "
            "Dark energy radiating from the figure. "
            "Solid opaque robes with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Cold blue and dark gray highlights only. A single figure only."
        ),
    },
    115: {
        "name": "Vampire Lord",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of an ancient lord of the night creatures. "
            "Full body head to toe, centered, facing the viewer directly. "
            "Small figure with plenty of green space around it. "
            "A tall pale figure in ornate dark crimson and black noble armor. "
            "Dark leathery wings folded close behind the back. "
            "Sharp aristocratic features, crimson eyes. Dark flowing cape. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark crimson and silver highlights only. A single figure only."
        ),
    },
    116: {
        "name": "Shadow Lord",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a shadow lord, a lord among living shadows. "
            "Full body, centered, facing the viewer. "
            "A tall imposing humanoid figure made of solid concentrated darkness. "
            "Dense black core with a dark crown of shadow floating above its head. "
            "Faint pale white eyes burning in the void of its face. "
            "Long dark arms with clawed shadow fingers. Dark robes merging with its body. "
            "Solid opaque dark body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark purple and pale white highlights only. A single creature only."
        ),
    },
    117: {
        "name": "Maia Thrall",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a corrupted fire elemental spirit. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A compact humanoid figure made of solid dark flame and molten rock. "
            "Dense dark orange and crimson body with visible dark veins of corruption. "
            "Arms held close to the torso, fists clenched with fire contained within the body. "
            "Burning orange eyes. Dark iron bracers on the wrists. "
            "Thick solid opaque fiery body with sharp well-defined edges, not wispy. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark orange and crimson highlights only. A single creature only."
        ),
    },
    118: {
        "name": "Khamul Shadow of the East",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a dark armored warlord of shadow. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A towering imposing figure in ornate dark plate armor with dark red engravings. "
            "Flowing black robes over the armor. A great dark iron crown with red gems. "
            "No visible face, only burning dark red eyes within the void of the helm. "
            "Both arms visible, gripping a long dark sword vertically in front of the body, "
            "blade overlapping the chest and torso. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark red and iron-black highlights only. A single figure only."
        ),
    },
    131: {
        "name": "Elite Olog-hai",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of an elite battle-troll in heavy black iron armor. "
            "Full body head to toe, centered, facing the viewer. "
            "Massive muscular dark gray troll completely clad in black iron plate armor. "
            "A heavy dark iron great helm with red eye slits. "
            "Wielding an enormous dark iron greatsword held across the body. "
            "Thick dark iron shoulder plates and gauntlets. "
            "Solid opaque body, heavy and dense. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Black iron and dark red highlights only. A single creature only."
        ),
    },
    136: {
        "name": "Black Numenorean Lord",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of a lord of the dark sorcerer order. "
            "Full body head to toe, centered, facing the viewer. "
            "A tall imposing pale man in ornate dark plate armor with violet rune engravings. "
            "Heavy dark cloak with silver clasps. A dark iron crown with violet gems. "
            "Sharp noble features, cold calculating dark eyes. "
            "One hand raised with dark violet energy swirling, the other gripping a dark staff "
            "held across the body overlapping the torso. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Dark violet and silver highlights only. A single figure only."
        ),
    },
}


def main():
    parser = argparse.ArgumentParser(description="Tier 6 Monster Generation")
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
            for suffix in ["_t6_backup", "_t5_backup", "_v2_backup", "_magenta_backup"]:
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
        print(f"\nRetry failed with: python3 regen_tier6.py --ids {' '.join(str(f[0]) for f in failed)}")
    print(f"\nNext: python3 process_monsters_v3.py --tier 6")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
