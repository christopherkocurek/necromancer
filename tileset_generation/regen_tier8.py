#!/usr/bin/env python3
"""
DALL-E Generation for Tier 8 — Hallucination/NPC Creatures

10 NPCs. Most on MAGENTA BG (#FF00FF) to avoid green skin/color contamination.
Radagast stays on green BG (brown robes work fine on green).

Green BG: 307
Magenta BG: 301, 302, 303, 304, 305, 306, 308, 309, 310
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
    301: {
        "name": "Gandalf the Grey",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a wandering gray wizard. "
            "Full body head to toe, centered, facing the viewer directly, filling most of the frame. "
            "A tall imposing old wizard with a pale face, piercing bright blue eyes, "
            "a long flowing gray beard and thick bushy gray eyebrows. "
            "A tall pointed gray hat with bright white highlights on the brim. "
            "Heavy gray robes with bright white folds and white fabric highlights, no pink or magenta tones in the clothing. "
            "A long rough brown wooden staff held upright overlapping the body. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Gray with white highlights and warm brown staff only, absolutely no magenta or pink in the robes. A single figure only."
        ),
    },
    302: {
        "name": "Thranduil Elvenking",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a single proud woodland elf king. "
            "Full body head to toe, centered, facing the viewer directly, one face only. "
            "A tall regal elf with luminous pale ivory skin, long silver-blond hair and bright cold blue eyes. "
            "Wearing a rich dark emerald green cloak over dark green robes with gold leaf embroidery. "
            "A tall crown of silver branches and autumn leaves on his head. "
            "One hand resting on the pommel of a sheathed elegant elven sword. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Emerald green and gold highlights only. A single figure only, one person only."
        ),
    },
    303: {
        "name": "Galadriel Lady of Light",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a radiant elven queen of great power. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A tall ethereal woman with warm luminous pale skin and long flowing silver-gold hair. "
            "Wearing flowing white robes with silver embroidery. "
            "A delicate silver circlet with a white gemstone on her brow. "
            "Wise ancient blue eyes. "
            "Hands folded gracefully in front. Faint white light radiating from her form. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Silver-white and pale gold highlights only. A single figure only."
        ),
    },
    304: {
        "name": "Elrond Half-elven",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a noble ancient elf lord. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A tall noble elf with luminous pale skin, long straight black hair and piercing gray eyes. "
            "Wearing bright rich blue robes with wide sleeves and ornate gilded gold trim. "
            "Gold embroidered star patterns on the chest. A gold circlet on his brow. "
            "Arms down at his sides, hands visible, standing with noble authority. "
            "Solid opaque body with well-defined edges, solid opaque arms and shoulders. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Bright blue and gilded gold highlights only. A single figure only."
        ),
    },
    305: {
        "name": "Thorin Oakenshield",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a proud dwarf king in exile. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A short stocky powerful dwarf with warm ruddy skin, a long dark braided beard with silver streaks. "
            "Wearing heavy dark blue fur-trimmed armor with silver chainmail underneath. "
            "An oak branch shield strapped to his back. "
            "Fierce proud blue eyes. A heavy dark iron war axe held close to the body. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Dark blue and silver highlights only. A single figure only."
        ),
    },
    306: {
        "name": "Beorn the Skinchanger",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a terrifying half-man half-bear berserker. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A towering hulking brute with thick dark brown bear fur growing from his shoulders and arms. "
            "Scarred weathered tanned skin, a wild tangled dark beard, feral amber eyes. "
            "Wearing crude dark leather and iron armor strapped across a massive barrel chest. "
            "Enormous clawed hands. Heavy brow, broad flat nose, bestial snarl. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Dark brown and iron-black highlights only. A single figure only."
        ),
    },
    307: {
        "name": "Radagast the Brown",
        "prompt": (
            "On a plain flat solid bright green background hex #00FF00. "
            "A dark fantasy illustration of an eccentric woodland wizard. "
            "Full body head to toe, centered, facing the viewer directly. "
            "An old man with wild unkempt brown hair and a tangled brown beard. "
            "Wearing ragged layered brown robes covered in leaves and twigs. "
            "A crooked brown hat with a bird nest on top. "
            "Kind wild eyes. Holding a gnarled wooden staff close to the body. "
            "Solid opaque body with well-defined edges. "
            "Plain flat green background only, absolutely no other elements or shapes in the image. "
            "Brown and autumn-tan highlights only. A single figure only."
        ),
    },
    308: {
        "name": "Eagle of the Misty Mountains",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a great eagle, an enormous bird of prey. "
            "Full body, centered, facing the viewer directly. "
            "A massive golden-brown eagle with wings folded close to its body. "
            "Sharp golden eyes, a large curved dark beak. "
            "Powerful talons gripping an invisible perch. "
            "Rich golden-brown and dark brown feathers with white chest plumage. "
            "Solid opaque feathered body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Golden-brown and dark brown highlights only. A single creature only."
        ),
    },
    309: {
        "name": "Great Elk of Mirkwood",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of a single majestic great elk, a sacred forest beast. "
            "Full body, centered, facing the viewer directly, one head one body. "
            "An enormous powerful elk with a single massive rack of wide branching ivory antlers. "
            "Rich dark brown fur with a tawny golden chest. "
            "One noble head with large dark amber eyes, a strong broad muzzle. "
            "Thick muscular neck and powerful legs. Standing proud and regal. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Dark brown and ivory-gold highlights only. A single creature only, one elk only."
        ),
    },
    310: {
        "name": "Ent of Fangorn",
        "prompt": (
            "On a plain flat solid bright magenta background hex #FF00FF. "
            "A dark fantasy illustration of an ancient living tree creature, a forest shepherd. "
            "Full body head to toe, centered, facing the viewer directly. "
            "A towering humanoid figure made of thick dark bark with deep green moss covering the body. "
            "Deep-set glowing amber eyes in a craggy bark face with a long beard of hanging moss. "
            "Thick branch-like arms held close to the body. "
            "A crown of bright green leaves and living branches sprouting from the top of the head. "
            "Green vines and ivy wrapped around the torso and arms. Roots for feet. "
            "Solid opaque body with well-defined edges. "
            "Plain flat magenta background only, absolutely no other elements or shapes in the image. "
            "Deep green and dark brown highlights only, no magenta tinting. A single creature only."
        ),
    },
}


def main():
    parser = argparse.ArgumentParser(description="Tier 8 NPC Monster Generation")
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
        print(f"Generating #{monster_id} {info['name']}")
        print(f"{'='*60}")

        existing = OUTPUT_DIR / f"monster_{monster_id}_1024.png"
        if existing.exists():
            for suffix in ["_t8v3_backup", "_t8v2_backup", "_t8_backup", "_t7_backup", "_v2_backup", "_magenta_backup"]:
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
        print(f"\nRetry failed with: python3 regen_tier8.py --ids {' '.join(str(f[0]) for f in failed)}")
    print(f"\nNext: python3 process_monsters_v3.py --tier 8")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
