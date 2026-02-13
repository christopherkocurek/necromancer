#!/usr/bin/env python3
"""
DALL-E Regeneration for Tier 3 — Round 4

Clean regenerations on GREEN background (#00FF00) for:
- #52 Ghoul — too dark, needs more visible detail
- #54 Easterling Warrior — had decorative circle/halo artifact
- #59 Karvag the Torturer — quality upgrade
- #71 Skeleton — had moon behind it, nonsensical

Best practices:
- Green BG (#00FF00) for clean extraction
- "vivid dark fantasy illustration" (NEVER "pixel art")
- EXPLICIT: "No decorative elements, circles, moons, halos, or symbols"
- Under 110 words per prompt
- No green accents on creature
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
    52: {
        "name": "Ghoul",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of an undead ghoul. "
            "Pale gray-blue emaciated humanoid with sunken cheeks and hollow dark eyes. "
            "Long bony fingers with blackened claws reaching forward. Hunched predatory crouch. "
            "Tattered remnants of prisoner rags clinging to the gaunt frame. "
            "Mouth open showing sharp yellowed teeth. Ribs visible through stretched skin. "
            "Full body head to toe, centered. Solid opaque body. "
            "No background decorations, no circles, no halos, no symbols. "
            "Pale blue and ivory highlights, no green tinting. "
            "A single creature only. Painted in a clean illustrative style."
        ),
    },
    54: {
        "name": "Easterling Warrior",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of an eastern warrior. "
            "Dark bronze lamellar armor over leather. A large curved scimitar held prominently "
            "in his right hand with the blade raised and clearly visible. "
            "Round bronze shield strapped to his left arm. "
            "Dark cloth headwrap with a bronze nasal guard. Olive skin, dark beard. "
            "Full body head to toe, centered, facing the viewer. "
            "No background decorations, no circles, no halos, no symbols behind the figure. "
            "White and silver highlights on the blade. No green tinting. "
            "A single figure only. Painted in a clean illustrative style."
        ),
    },
    59: {
        "name": "Karvag the Torturer",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of a massive troll torturer. "
            "Dark reddish-brown thick hide with scarred muscular body. "
            "Towering hulking frame with long powerful arms. "
            "Cruel face with small red eyes, jutting tusks, and a wicked grin. "
            "One hand gripping a heavy barbed iron chain, the other a bloodstained cleaver. "
            "Wearing a crude leather apron stained dark. "
            "Full body head to toe, centered, facing the viewer. "
            "No background decorations, no circles, no halos, no symbols. "
            "Red and iron-gray highlights, no green tinting. "
            "A single creature only. Painted in a clean illustrative style."
        ),
    },
    71: {
        "name": "Skeleton",
        "prompt": (
            "On a completely solid flat bright green background (hex #00FF00), "
            "a vivid dark fantasy illustration of an animated skeleton. "
            "Complete human skeleton standing upright with clean ivory-white bones. "
            "Empty black eye sockets with faint red pinpoints of necromantic energy. "
            "Jaw open in a silent snarl. Bony hands with sharp finger bones reaching forward. "
            "Wisps of dark purple shadow energy drifting between the ribs. "
            "Solid opaque thick bones, clearly visible joints. "
            "Full body head to toe, centered, facing the viewer. "
            "No background decorations, no moons, no circles, no halos, no symbols. "
            "Ivory and pale purple highlights, no green tinting. "
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
            # Keep backup chain — don't overwrite previous backups
            for suffix in ["_v4_backup", "_v3_backup", "_v2_backup", "_magenta_backup"]:
                backup = OUTPUT_DIR / f"monster_{monster_id}_1024{suffix}.png"
                if not backup.exists():
                    existing.rename(backup)
                    print(f"  Backed up existing raw -> {backup.name}")
                    break
            else:
                print(f"  All backup slots used, will overwrite current raw")

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
    print(f"  python3 process_monsters_v3.py --ids 52 54 59 71")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
