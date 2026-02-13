#!/usr/bin/env python3
"""
DALL-E Regeneration for Tier 3 Problem Sprites — Round 3

Generates new 1024x1024 raws on GREEN background (#00FF00) for:
- #54 Easterling Warrior — needs visible weapon (scimitar)
- #57 Easterling Champion — persistent magenta BG artifacts
- #58 Ghast — stripping/missing body parts
- #71 Skeleton — low quality, needs complete redo
- #73 Zombie — low quality, needs complete redo

Best practices:
- Green BG (#00FF00) for clean extraction
- "vivid dark fantasy illustration" (NEVER "pixel art" or "sprite")
- Explicit highlight colors that DON'T match BG
- "solid opaque body" for translucent creatures
- Under 110 words per prompt
- style="vivid", quality="standard"
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
    54: {
        "name": "Easterling Warrior",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a fierce eastern warrior. "
            "Bronze lamellar armor over dark leather. A curved scimitar held prominently "
            "in his right hand, blade catching the light. Round bronze shield on his left arm. "
            "Dark cloth wrapped around his head with a bronze nasal guard. "
            "Olive-tan skin, dark beard. Full body head to toe, centered, facing the viewer. "
            "White and silver highlights on the blade, no green tinting on the figure. "
            "A single figure only. Painted in a clean illustrative style."
        ),
    },
    57: {
        "name": "Easterling Champion",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of an elite eastern warrior champion. "
            "Heavy ornate bronze-gold plate armor with intricate eastern engravings. "
            "A massive two-handed curved greatsword held across his body. "
            "Tall imposing figure with a dark flowing cloak. "
            "Full-face bronze war helm with dark plume. "
            "Full body head to toe, centered, facing the viewer. "
            "Gold and ivory highlights on armor, no green tinting. "
            "A single figure only. Painted in a clean illustrative style."
        ),
    },
    58: {
        "name": "Ghast",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a ghast, a powerful undead ghoul. "
            "Gaunt emaciated gray-white body with visible ribs and sinew. "
            "Long clawed hands with blackened nails. Hunched predatory stance. "
            "Sunken hollow eyes glowing faint yellow. Wide mouth with jagged teeth. "
            "Patches of rotting dark flesh clinging to pale bones. Solid opaque body. "
            "Full body head to toe, centered, facing the viewer. "
            "Ivory and pale yellow highlights, no green tinting. "
            "A single creature only. Painted in a clean illustrative style."
        ),
    },
    71: {
        "name": "Skeleton",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of an animated skeleton. "
            "Complete human skeleton with ivory-white bones, standing upright. "
            "Empty black eye sockets with faint red pinpoints of dark magic. "
            "Jaw slightly open in a silent snarl. Arms reaching forward with bony clawed hands. "
            "Wisps of dark purple shadow energy clinging between the bones. "
            "Solid opaque bones, thick visible joints. "
            "Full body head to toe, centered, facing the viewer. "
            "Ivory and pale purple highlights, no green tinting. "
            "A single figure only. Painted in a clean illustrative style."
        ),
    },
    73: {
        "name": "Zombie",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a shambling zombie. "
            "Bloated gray-blue decaying corpse with torn rotting clothes. "
            "One arm raised reaching forward, the other hanging limply. "
            "Exposed dark red muscle and bone on the torso and arms. "
            "Clouded white dead eyes, slack jaw, matted dark hair. "
            "Solid opaque body, thick limbs. Shuffling forward pose. "
            "Full body head to toe, centered, facing the viewer. "
            "Dark red and ivory highlights, no green tinting. "
            "A single figure only. Painted in a clean illustrative style."
        ),
    },
}


def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found in environment")
        print("Run: export $(cat tileset_generation/.env | xargs)")
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for monster_id, info in sorted(REGENS.items()):
        print(f"\n{'='*60}")
        print(f"Regenerating #{monster_id} {info['name']} (green BG)")
        print(f"{'='*60}")

        existing = OUTPUT_DIR / f"monster_{monster_id}_1024.png"
        if existing.exists():
            backup = OUTPUT_DIR / f"monster_{monster_id}_1024_magenta_backup.png"
            if not backup.exists():
                existing.rename(backup)
                print(f"  Backed up existing raw -> {backup.name}")
            else:
                print(f"  Backup already exists, will overwrite current raw")

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

            print(f"  Done!")

        except Exception as e:
            print(f"  ERROR: {e}")
            continue

        time.sleep(2)

    print(f"\n{'='*60}")
    print(f"All regens complete. Now run:")
    print(f"  python3 process_monsters_v3.py --ids 54 57 58 71 73")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
