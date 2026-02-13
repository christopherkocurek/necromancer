#!/usr/bin/env python3
"""
DALL-E Regeneration for Tier 2 Problem Sprites

Generates new 1024x1024 raws on GREEN background (#00FF00) for:
- #32 Orc Soldier (sword blade lost in pipeline — regen with prominent blade)
- #33 Orc Crossbowman (missing leg — regen with wide stance, both legs visible)
- #34 Warg (pink/white underside from magenta BG — regen on green with dark gray fur)
"""

import os
import sys
import base64
import io
import time
from pathlib import Path

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from openai import OpenAI
from PIL import Image

BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "monster_v2" / "raw"

REGENS = {
    32: {
        "name": "Orc Soldier",
        "prompt": (
            "On a completely solid flat bright magenta background (hex #FF00FF), "
            "a vivid dark fantasy illustration of a lightly armored orc soldier. "
            "Dark sallow olive-brown skin. Light leather armor with iron studs. "
            "Wielding a cruel curved scimitar in one hand and a small round wooden buckler in the other. "
            "The scimitar blade is bright and clearly visible, reflecting whitish-yellow light. "
            "Standing centered facing the viewer, full body head to toe, snarling battle-ready face. "
            "All reflective highlights and lighting on the figure are whitish-yellow, warm tone. "
            "A single creature only, no other elements. Painted in a clean illustrative style."
        ),
    },
    33: {
        "name": "Orc Crossbowman",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of an orc in dark leather armor aiming a heavy iron crossbow. "
            "Dark sallow olive-brown skin, not bright green. "
            "Standing in a wide stable stance with BOTH LEGS clearly visible and spread apart, "
            "feet planted firmly on the ground. Full body from head to toe with both legs fully shown. "
            "A quiver of cruel barbed bolts on his hip. One eye squinted shut taking aim. "
            "White and silver metallic highlights on the crossbow, no green tinting on skin or armor. "
            "A single creature only, no other elements. Painted in a clean illustrative style."
        ),
    },
    34: {
        "name": "Warg",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a great wolf the size of a horse. "
            "Dark charcoal-gray fur with white and silver highlights on the fur edges. "
            "Massive jaws full of white fangs, baleful yellow eyes full of cunning intelligence. "
            "Powerful muscled shoulders, all four legs visible in an aggressive crouching pose. "
            "The entire underside and belly of the wolf is dark gray fur, same as the body. "
            "White and silver highlights only, absolutely no pink or warm tones on the fur. "
            "A single beast creature only, no other elements. Painted in a clean illustrative style."
        ),
    },
}


def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found in environment")
        print("Run: export $(cat .env | xargs)")
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for monster_id, info in sorted(REGENS.items()):
        print(f"\n{'='*60}")
        print(f"Regenerating #{monster_id} {info['name']} (green BG)")
        print(f"{'='*60}")

        # Backup existing raw
        existing = OUTPUT_DIR / f"monster_{monster_id}_1024.png"
        if existing.exists():
            backup = OUTPUT_DIR / f"monster_{monster_id}_1024_magenta_backup.png"
            if not backup.exists():
                existing.rename(backup)
                print(f"  Backed up existing raw -> {backup.name}")
            else:
                # Keep magenta backup, just overwrite current
                print(f"  Backup already exists, will overwrite current raw")

        print(f"  Prompt: {info['prompt'][:140]}...")

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

            print(f"  Done!")

        except Exception as e:
            print(f"  ERROR: {e}")
            continue

        time.sleep(2)

    print(f"\n{'='*60}")
    print(f"All regens complete. Now run:")
    print(f"  python3 process_monsters_v3.py --ids 32 33 34 --from-raw")
    print(f"  python3 postprocess_tier2.py")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
