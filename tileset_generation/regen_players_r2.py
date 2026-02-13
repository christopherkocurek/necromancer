"""Round 2 regen — fix Lothlorien M/F, Shire F, Gamgees F with adjusted prompts.
Key fixes: explicit skin color, solid opaque everything, dark fantasy style reinforced."""

import os, sys, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from PIL import Image
import numpy as np
from io import BytesIO

env_path = Path(__file__).parent / ".env"
with open(env_path) as f:
    for line in f:
        if line.startswith("OPENAI_API_KEY="):
            API_KEY = line.strip().split("=", 1)[1]
            break

ANTI_HALO = (
    "Plain flat magenta background only, absolutely no other elements "
    "or shapes in the image. "
)

# Round 2 sprites with fixed prompts
SPRITES_R2 = [
    ("lothlorien_m",
     "On a plain flat solid bright magenta background hex #FF00FF. "
     "A dark fantasy illustration. "
     "Full body head to toe, centered, filling most of the frame. "
     "An ethereal male elf lord with long flowing silver-white hair. "
     "Pale ivory skin, no purple or magenta tinting in the skin or robes. "
     "Wearing luminous white robes with golden thread embroidery over silver armor. "
     "Holding a slender golden elven staff in one hand. "
     "Noble ageless face, tall and regal bearing. Facing the viewer directly. "
     "Solid opaque robes and body with well-defined edges. "
     "Golden and bright white highlights only, no magenta or purple tinting anywhere. "
     + ANTI_HALO
    ),
    ("lothlorien_f",
     "On a plain flat solid bright magenta background hex #FF00FF. "
     "A dark fantasy illustration. "
     "Full body head to toe, centered, filling most of the frame. "
     "An ethereal female elf lady with long flowing silver-white hair. "
     "Pale ivory skin, no purple or magenta tinting anywhere on the body. "
     "Wearing a solid opaque silver-blue silk gown that flows to the ground. "
     "A delicate silver circlet on her brow. Hands clasped at waist. "
     "The gown and hair are completely opaque, not translucent or see-through. "
     "Solid opaque figure with well-defined edges, nothing transparent. "
     "Silver and ice-blue highlights only, no magenta or purple tinting. "
     + ANTI_HALO
    ),
    ("shire_f",
     "On a plain flat solid bright magenta background hex #FF00FF. "
     "A dark fantasy painting in a realistic painterly style. Not anime. Not cartoon. "
     "Portrait from the waist up, enlarged, filling 80 percent of the frame. "
     "A female hobbit with curly auburn hair and warm hazel eyes. "
     "Wearing an earth-tone linen dress with a patterned apron and a small shawl. "
     "A tiny wildflower tucked behind one pointed ear. Round cheerful face, rosy cheeks. "
     "Realistic proportions, not stylized or cartoon. Mature adult woman. "
     "Solid opaque clothing with well-defined edges. "
     "Warm brown and cream highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
    ("gamgees_f",
     "On a plain flat solid bright magenta background hex #FF00FF. "
     "A dark fantasy painting in a realistic painterly style. "
     "Portrait from the waist up, enlarged, filling 80 percent of the frame. "
     "A practical sturdy female hobbit with curly brown hair pulled back in a bun. "
     "Wearing a simple brown homespun work dress with a tan canvas gardening apron. "
     "Holding a small garden trowel. Strong capable hands, warm weathered face. "
     "Solid opaque clothing with well-defined edges. "
     "Warm brown and earthy tan highlights only, no magenta tinting. "
     "Facing the viewer directly. "
     + ANTI_HALO
    ),
]

OUTPUT_DIR = Path(__file__).parent / "player_v2"
RAW_DIR = OUTPUT_DIR / "raw"


def generate(sprite_id, prompt):
    print(f"  Generating {sprite_id}...")
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "style": "vivid",
        "quality": "standard"
    }
    resp = requests.post("https://api.openai.com/v1/images/generations",
                         headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    url = resp.json()["data"][0]["url"]
    img_resp = requests.get(url, timeout=60)
    img = Image.open(BytesIO(img_resp.content)).convert("RGBA")
    img.save(RAW_DIR / f"{sprite_id}_raw.png")
    print(f"  Raw saved: {sprite_id}")
    return sprite_id, img


if __name__ == "__main__":
    print(f"=== Round 2 Regen ({len(SPRITES_R2)} sprites) ===\n")

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(generate, sid, p): sid for sid, p in SPRITES_R2}
        for f in as_completed(futures):
            sid = futures[f]
            try:
                f.result()
            except Exception as e:
                print(f"  FAILED {sid}: {e}")

    print("\n=== Now reprocess all with reprocess_players.py ===")
    print("Run: python3 reprocess_players.py")
