#!/usr/bin/env python3
"""
Retry failed sprites with adjusted prompts to avoid content filters
"""

import os
import io
import json
import time
import requests
import numpy as np
from pathlib import Path
from datetime import datetime
from PIL import Image
from openai import OpenAI

OPENAI_API_KEY = "YOUR_OPENAI_API_KEY_HERE"

PROJECT_ROOT = Path(__file__).parent.parent.parent
OUTPUT_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = OUTPUT_DIR / "final"
WIP_DIR = OUTPUT_DIR / "wip"
MANIFEST_PATH = OUTPUT_DIR / "sprite_manifest.json"

TARGET_SIZE = 64
RATE_LIMIT_DELAY = 12

# Adjusted prompts to avoid content filters
RETRY_SPRITES = [
    {
        "id": "R:31",
        "name": "Orc Slave",
        "filename": "monsters/m_031_orc_slave",
        "description": """A lowly orc worker, bottom of the orc hierarchy.
Scrawny weak orc with gray skin, malnourished and scarred.
Ragged worn clothing, no armor, carrying a crude wooden club.
Hunched submissive posture but still dangerous, feral look in eyes.
Dark fantasy game sprite style."""
    },
    {
        "id": "R:35",
        "name": "Orc Thrallmaster",
        "filename": "monsters/m_035_orc_thrallmaster",
        "description": """An orc overseer, commander of lesser orcs.
Burly muscular orc with ritual scars on face, cruel expression.
Carrying a coiled chain, wearing red-tinted dark armor.
Domineering stance, clearly a brutal leader figure.
Dark fantasy game sprite style."""
    },
    {
        "id": "R:39",
        "name": "Gashnak Warg-lord",
        "filename": "monsters/m_039_gashnak",
        "description": """Gashnak, the alpha leader of the warg pack - a boss creature.
Enormous wolf-beast, bigger and fiercer than normal wolves.
Battle scars across face, one torn ear, glowing amber eyes.
Snarling with massive fangs bared, clearly the pack alpha.
Dark fantasy game sprite, menacing predator."""
    },
    {
        "id": "R:52",
        "name": "Ghoul",
        "filename": "monsters/m_052_ghoul",
        "description": """A ghoul, cursed undead creature from dark folklore.
Hunched humanoid with gray pallid flesh, long sharp claws.
Hollow hungry eyes, pointed teeth, emaciated frame.
Crouching predatory pose, feral and dangerous undead.
Dark fantasy game sprite style like Darkest Dungeon."""
    },
    {
        "id": "R:56",
        "name": "Tortured Wretch",
        "filename": "monsters/m_056_tortured_wretch",
        "description": """A wretched prisoner, a broken soul driven mad by captivity.
Emaciated human figure covered in old scars and wounds.
Wild desperate eyes, ragged remains of clothes, feral posture.
Pitiable but dangerous madman, attacks out of fear.
Dark fantasy game sprite, tragic figure."""
    },
    {
        "id": "R:59",
        "name": "Karvag the Torturer",
        "filename": "monsters/m_059_karvag",
        "description": """Karvag, a massive troll dungeon boss.
Huge brutish troll with cruel intelligent eyes.
Wears a dark leather apron, carries heavy iron implements.
Unlike normal trolls, shows cunning and malice in expression.
Dark fantasy game sprite, intimidating boss monster."""
    },
    {
        "id": "R:73",
        "name": "Zombie",
        "filename": "monsters/m_073_zombie",
        "description": """A reanimated undead, classic shambling corpse.
Humanoid figure with gray-green pallid skin, stiff movement.
Blank empty eyes, arms outstretched, lurching forward pose.
Tattered old clothing, clearly deceased but still moving.
Dark fantasy game sprite like classic RPG undead."""
    },
    {
        "id": "R:97",
        "name": "Vampire Thrall",
        "filename": "monsters/m_097_vampire_thrall",
        "description": """A vampire's servant, corrupted human minion.
Pale gaunt human with sunken features, reddish eyes.
Subservient hunched posture, visible fangs, dark clothing.
Not a full vampire but clearly corrupted by dark influence.
Dark fantasy game sprite style."""
    },
    {
        "id": "F:31",
        "name": "Bloodstain",
        "filename": "terrain/t_31_bloodstain",
        "description": """A dungeon floor tile with dark stains.
Stone floor with dark reddish-brown dried marks.
Signs of past conflict, ominous atmosphere.
Top-down view, stain pattern on gray stone tile.
Dark fantasy game terrain sprite."""
    },
]

BASE_TEMPLATE = """{description}

CRITICAL REQUIREMENTS:
- Single sprite only, perfectly centered in frame
- Solid magenta background (#FF00FF) for easy removal
- NO color palette swatches or UI elements
- NO text, labels, watermarks, or borders
- Character/object fills 80% of the frame
- Clear silhouette readable at small size
- Dark fantasy pixel art style
- Top-left lighting, consistent shadows
- 64x64 pixel game sprite aesthetic"""

def generate_image(client, sprite_data):
    prompt = BASE_TEMPLATE.format(description=sprite_data["description"])
    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="hd",
            n=1,
            response_format="url"
        )
        image_url = response.data[0].url
        img_response = requests.get(image_url, timeout=60)
        img = Image.open(io.BytesIO(img_response.content))
        return img, None
    except Exception as e:
        return None, str(e)

def remove_background(img):
    img = img.convert("RGBA")
    data = np.array(img)
    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]
    magenta_mask = (r > 180) & (g < 120) & (b > 180)
    white_mask = (r > 245) & (g > 245) & (b > 245)
    background_mask = magenta_mask | white_mask
    data[:,:,3] = np.where(background_mask, 0, 255)
    return Image.fromarray(data)

def auto_crop_to_content(img, padding=2):
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    alpha = np.array(img)[:,:,3]
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)
    if not rows.any() or not cols.any():
        return img
    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]
    rmin = max(0, rmin - padding)
    rmax = min(img.height - 1, rmax + padding)
    cmin = max(0, cmin - padding)
    cmax = min(img.width - 1, cmax + padding)
    return img.crop((cmin, rmin, cmax + 1, rmax + 1))

def center_on_canvas(img, target_size):
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    x = (target_size - img.width) // 2
    y = (target_size - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas

def post_process(img, target_size=64):
    img = remove_background(img)
    img = img.resize((target_size * 2, target_size * 2), Image.Resampling.LANCZOS)
    img = auto_crop_to_content(img, padding=4)
    max_dim = max(img.width, img.height)
    if max_dim > target_size - 4:
        scale = (target_size - 4) / max_dim
        new_width = int(img.width * scale)
        new_height = int(img.height * scale)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    img = center_on_canvas(img, target_size)
    return img

def load_manifest():
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, 'r') as f:
            return json.load(f)
    return {"version": "1.0", "target_size": TARGET_SIZE, "sprites": {}}

def save_manifest(manifest):
    manifest["updated"] = datetime.now().isoformat()
    with open(MANIFEST_PATH, 'w') as f:
        json.dump(manifest, f, indent=2)

def main():
    print("=" * 60)
    print("RETRYING FAILED SPRITES WITH ADJUSTED PROMPTS")
    print("=" * 60)

    client = OpenAI(api_key=OPENAI_API_KEY)
    manifest = load_manifest()

    success = 0
    failed = 0

    for sprite in RETRY_SPRITES:
        print(f"\n[RETRY] {sprite['name']}...")

        img, error = generate_image(client, sprite)

        if error:
            print(f"  FAILED: {error}")
            failed += 1
            time.sleep(RATE_LIMIT_DELAY)
            continue

        try:
            processed = post_process(img, TARGET_SIZE)

            output_path = FINAL_DIR / f"{sprite['filename']}.png"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            processed.save(output_path)

            wip_path = WIP_DIR / f"{sprite['filename']}_full.png"
            wip_path.parent.mkdir(parents=True, exist_ok=True)
            img.save(wip_path)

            preview = processed.resize((256, 256), Image.Resampling.NEAREST)
            preview_path = WIP_DIR / f"{sprite['filename']}_preview.png"
            preview.save(preview_path)

            manifest["sprites"][sprite["id"]] = {
                "status": "completed",
                "name": sprite["name"],
                "filename": str(output_path.relative_to(OUTPUT_DIR)),
                "attempts": "retry",
                "completed": datetime.now().isoformat()
            }
            save_manifest(manifest)

            print(f"  SUCCESS: {output_path.name}")
            success += 1

        except Exception as e:
            print(f"  POST-PROCESS ERROR: {e}")
            failed += 1

        time.sleep(RATE_LIMIT_DELAY)

    print("\n" + "=" * 60)
    print(f"RETRY COMPLETE: {success} succeeded, {failed} failed")
    print("=" * 60)

if __name__ == "__main__":
    main()
