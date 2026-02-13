#!/usr/bin/env python3
"""
DALL-E Regeneration for Tier 3 Problem Sprites — Round 2

Generates new 1024x1024 raws on GREEN background (#00FF00) for:
- #60 Master Sorcerer (complete regen — pinkish magic blob, desaturated robes)
- #85 Tunnel Crawler (complete regen — magenta BG deeply embedded in body)
     NOTE: Green accents replaced with YELLOW/AMBER to avoid green BG confusion
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
    60: {
        "name": "Master Sorcerer",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a powerful sorcerer in ornate dark violet robes "
            "with golden arcane patterns embroidered on the fabric. "
            "Both hands raised overhead channeling swirling dark purple magical energy. "
            "Eyes blazing with bright purple fire. A gaunt pale face with sharp features. "
            "Full body head to toe, centered, facing the viewer. "
            "The magical energy above is dark violet and black swirling shadows, not pink or red. "
            "White and gold highlights on the robes only, no green tinting. "
            "A single figure only, no other elements. Painted in a clean illustrative style."
        ),
    },
    85: {
        "name": "Tunnel Crawler",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a massive centipede-like creature. "
            "Dark brown heavily armored segmented carapace with ridged plates. "
            "Dozens of sharp dark legs along its body. "
            "Large yellow mandibles dripping amber venom, yellow-tipped antennae. "
            "The body coils in a sinuous curve filling most of the frame. "
            "All accents are yellow, amber, and ivory — absolutely no green on the creature. "
            "Dark brown and black body with yellow-amber highlights only. "
            "A single creature only, no other elements. Painted in a clean illustrative style."
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

        existing = OUTPUT_DIR / f"monster_{monster_id}_1024.png"
        if existing.exists():
            backup = OUTPUT_DIR / f"monster_{monster_id}_1024_v1_backup.png"
            if not backup.exists():
                existing.rename(backup)
                print(f"  Backed up existing raw -> {backup.name}")
            else:
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
    print(f"  python3 process_monsters_v3.py --ids 60 85 --from-raw")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
