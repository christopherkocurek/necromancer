#!/usr/bin/env python3
"""
Phase 1: Style Test - Generate 6 test sprites (3 subjects × 2 styles)
"""

import os
import io
import base64
import requests
from pathlib import Path
from PIL import Image
from openai import OpenAI

# API Keys (passed directly for this session)
OPENAI_API_KEY = "YOUR_OPENAI_API_KEY_HERE"

# Output directory
PROJECT_ROOT = Path(__file__).parent.parent.parent
WIP_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf" / "wip"
STYLE_TEST_DIR = WIP_DIR / "style_test"
STYLE_TEST_DIR.mkdir(parents=True, exist_ok=True)

# Test subjects from the plan
TEST_SUBJECTS = [
    {
        "id": "orc_soldier",
        "name": "Orc Soldier",
        "description": "A brutish orc warrior in dark iron armor, holding a crude sword, hunched aggressive posture, tusked face with red eyes, battle-scarred"
    },
    {
        "id": "stone_floor",
        "name": "Stone Floor",
        "description": "A single stone floor tile, cracked ancient dungeon flagstone, dark gray with subtle moss, top-down view, worn and weathered"
    },
    {
        "id": "elf_player",
        "name": "Elf Ranger",
        "description": "An elven ranger hero, slender athletic build, pointed ears, hooded cloak, carrying a bow, determined noble expression, protagonist character"
    }
]

# Style templates
STYLES = {
    "pixel_art": {
        "name": "True Pixel Art",
        "suffix": "pixel",
        "prompt_template": """pixel art, 32x32 sprite, {subject}, dark fantasy roguelike style,
1-2 pixel black outline, solid color fills, NO anti-aliasing, NO gradients,
top-left lighting, limited 16-color palette using: dark purple, stone gray, blood red, mirkwood green, bone white, shadow black,
clear readable silhouette, crisp pixel edges, retro game aesthetic like Caves of Qud or DCSS tiles,
single sprite centered on transparent background, no text, no watermarks""",
        "resample": Image.Resampling.NEAREST
    },
    "painted": {
        "name": "Painted Style",
        "suffix": "painted",
        "prompt_template": """painted game sprite, 32x32 pixels, {subject}, dark fantasy style,
soft brushwork edges, atmospheric shading, subtle color gradients,
gritty medieval horror aesthetic like Stoneshard or Darkest Dungeon,
top-left dramatic lighting, muted earthy palette with purple and green accents,
clear silhouette against transparent background, single character/tile centered,
no text, no watermarks, game-ready sprite""",
        "resample": Image.Resampling.LANCZOS
    }
}

def generate_sprite(client, subject, style):
    """Generate a single sprite using DALL-E 3"""
    prompt = style["prompt_template"].format(subject=subject["description"])

    print(f"  Generating {subject['name']} ({style['name']})...")

    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="standard",
            n=1,
            response_format="url"
        )

        image_url = response.data[0].url

        # Download the image
        img_response = requests.get(image_url)
        img = Image.open(io.BytesIO(img_response.content))

        return img, response.data[0].revised_prompt

    except Exception as e:
        print(f"    ERROR: {e}")
        return None, str(e)

def post_process(img, style, is_floor=False):
    """Resize to 32x32 and process"""
    # Convert to RGBA
    img = img.convert("RGBA")

    # Resize using appropriate resampling
    img_32 = img.resize((32, 32), style["resample"])

    return img_32

def create_comparison_sheet(sprites):
    """Create a side-by-side comparison image"""
    # Layout: 2 columns (pixel, painted) × 3 rows (subjects)
    # Each cell: 64x64 (2x scale for visibility) + 4px padding
    cell_size = 64
    padding = 8
    label_height = 20

    width = (cell_size + padding) * 2 + padding
    height = (cell_size + padding + label_height) * 3 + padding + 40  # Extra for title

    sheet = Image.new("RGBA", (width, height), (40, 40, 50, 255))

    # Subject labels
    subjects = ["Orc Soldier", "Stone Floor", "Elf Player"]
    styles = ["pixel_art", "painted"]

    y = 40
    for i, subject in enumerate(subjects):
        x = padding
        for j, style in enumerate(styles):
            key = f"{TEST_SUBJECTS[i]['id']}_{style}"
            if key in sprites and sprites[key] is not None:
                # Scale up 2x for visibility
                sprite = sprites[key].resize((cell_size, cell_size), Image.Resampling.NEAREST)
                sheet.paste(sprite, (x, y + label_height), sprite)
            x += cell_size + padding
        y += cell_size + padding + label_height

    return sheet

def main():
    print("=" * 60)
    print("PHASE 1: Style Test - Generating 6 Test Sprites")
    print("=" * 60)

    client = OpenAI(api_key=OPENAI_API_KEY)
    sprites = {}
    prompts_used = {}

    for subject in TEST_SUBJECTS:
        print(f"\n[{subject['name']}]")

        for style_key, style in STYLES.items():
            # Generate
            img, revised_prompt = generate_sprite(client, subject, style)

            if img:
                # Post-process
                is_floor = subject["id"] == "stone_floor"
                processed = post_process(img, style, is_floor)

                # Save individual sprite
                filename = f"{subject['id']}_{style['suffix']}.png"
                filepath = STYLE_TEST_DIR / filename
                processed.save(filepath)
                print(f"    Saved: {filepath}")

                # Also save full-size for reference
                fullsize_path = STYLE_TEST_DIR / f"{subject['id']}_{style['suffix']}_full.png"
                img.save(fullsize_path)

                sprites[f"{subject['id']}_{style_key}"] = processed
                prompts_used[f"{subject['id']}_{style_key}"] = revised_prompt

    # Create comparison sheet
    print("\n[Creating Comparison Sheet]")
    comparison = create_comparison_sheet(sprites)
    comparison_path = STYLE_TEST_DIR / "style_comparison.png"
    comparison.save(comparison_path)
    print(f"  Saved: {comparison_path}")

    # Save prompts for reference
    prompts_path = STYLE_TEST_DIR / "prompts_used.txt"
    with open(prompts_path, "w") as f:
        for key, prompt in prompts_used.items():
            f.write(f"=== {key} ===\n{prompt}\n\n")
    print(f"  Saved prompts: {prompts_path}")

    print("\n" + "=" * 60)
    print("PHASE 1 COMPLETE!")
    print(f"Output directory: {STYLE_TEST_DIR}")
    print("=" * 60)
    print("\nNext: Review the sprites and select your preferred style.")

if __name__ == "__main__":
    main()
