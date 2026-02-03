#!/usr/bin/env python3
"""
Phase 1 v2: Style Test at 64x64 with refined prompts
- No color swatches or UI elements
- Clean backgrounds
- Better centering
"""

import os
import io
import requests
import numpy as np
from pathlib import Path
from PIL import Image
from openai import OpenAI

# API Key
OPENAI_API_KEY = "YOUR_OPENAI_API_KEY_HERE"

# Output directory
PROJECT_ROOT = Path(__file__).parent.parent.parent
STYLE_TEST_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf" / "wip" / "style_test_64"
STYLE_TEST_DIR.mkdir(parents=True, exist_ok=True)

# Test subjects with detailed descriptions
TEST_SUBJECTS = [
    {
        "id": "orc_soldier",
        "name": "Orc Soldier",
        "prompt": """A single orc warrior sprite for a dark fantasy roguelike game.
The orc has gray-green skin, tusks, wearing crude dark iron armor, holding a jagged sword.
Hunched aggressive posture, battle-scarred face, glowing red eyes.
The character faces slightly left, in an idle combat stance.
Dark fantasy style like Darkest Dungeon or Battle Brothers."""
    },
    {
        "id": "stone_floor",
        "name": "Stone Floor Tile",
        "prompt": """A single square stone floor tile for a dark dungeon.
Ancient cracked flagstone, dark gray with subtle green moss in cracks.
Top-down view, seamless tile pattern potential.
Worn and weathered surface with slight texture variation.
Dark atmospheric lighting, no objects on the floor."""
    },
    {
        "id": "elf_player",
        "name": "Elf Ranger (Player Character)",
        "prompt": """A single elven ranger hero sprite for a dark fantasy roguelike game.
Slender athletic build, pointed ears visible, wearing a forest green hooded cloak.
Carrying a elegant longbow, quiver on back.
Noble determined expression, protagonist character, facing slightly right.
The hero should look distinct and recognizable as the player character.
Dark fantasy style like Darkest Dungeon or Battle Brothers."""
    },
    {
        "id": "skeleton_warrior",
        "name": "Skeleton Warrior",
        "prompt": """A single undead skeleton warrior sprite for a dark fantasy roguelike game.
Animated human skeleton with hollow eye sockets glowing faint blue.
Wearing rusted ancient armor pieces, carrying a notched sword and battered shield.
Menacing stance, bones yellowed with age.
Dark fantasy undead style, clearly reads as hostile enemy."""
    },
    {
        "id": "wraith",
        "name": "Wraith",
        "prompt": """A single ghostly wraith sprite for a dark fantasy roguelike game.
Ethereal hooded figure, translucent flowing dark robes.
No visible face under hood, just darkness with two faint glowing eyes.
Wispy trailing edges that fade to transparency.
Floating slightly above ground, spectral and menacing.
Must be visible against dark backgrounds - use subtle glow or lighter edges."""
    },
    {
        "id": "wooden_door",
        "name": "Wooden Door",
        "prompt": """A single closed wooden dungeon door for a dark fantasy game.
Heavy oak door with iron bands and rivets, set in stone frame.
Front view, clearly reads as interactive/openable.
Ancient and weathered wood grain, dark iron hardware.
Torch light reflecting off surface from the left side."""
    }
]

# Refined prompt template - NO color swatches, NO UI elements
PROMPT_TEMPLATE = """{subject_prompt}

CRITICAL REQUIREMENTS:
- Single sprite only, perfectly centered in frame
- Solid colored background (will be removed) - use bright magenta #FF00FF
- NO color palette swatches
- NO UI elements, text, labels, or borders
- NO multiple versions or variations
- Character/object fills most of the frame
- Clear silhouette and readable details
- Pixel art style with clean defined edges
- Top-left lighting for consistent shadows
- 64x64 pixel game sprite aesthetic"""

def generate_sprite(client, subject):
    """Generate a single sprite using DALL-E 3"""
    prompt = PROMPT_TEMPLATE.format(subject_prompt=subject["prompt"])

    print(f"  Generating {subject['name']}...")

    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="hd",  # Higher quality for better detail
            n=1,
            response_format="url"
        )

        image_url = response.data[0].url
        revised_prompt = response.data[0].revised_prompt

        # Download the image
        img_response = requests.get(image_url)
        img = Image.open(io.BytesIO(img_response.content))

        return img, revised_prompt

    except Exception as e:
        print(f"    ERROR: {e}")
        return None, str(e)

def remove_background(img):
    """Remove magenta background and edge artifacts"""
    img = img.convert("RGBA")
    data = np.array(img)

    # Find magenta-ish pixels (background)
    # Be generous with the threshold to catch variations
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

    # Magenta: high red, low green, high blue
    magenta_mask = (r > 200) & (g < 100) & (b > 200)

    # Also catch near-white and very light pixels at edges (common DALL-E artifact)
    edge_artifact_mask = (r > 240) & (g > 240) & (b > 240)

    # Combine masks
    background_mask = magenta_mask | edge_artifact_mask

    # Set background to transparent
    data[:,:,3] = np.where(background_mask, 0, 255)

    return Image.fromarray(data)

def auto_crop_to_content(img, padding=2):
    """Crop to content bounding box with padding"""
    # Get alpha channel
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    alpha = np.array(img)[:,:,3]

    # Find bounding box of non-transparent pixels
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)

    if not rows.any() or not cols.any():
        return img  # No content found

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]

    # Add padding
    rmin = max(0, rmin - padding)
    rmax = min(img.height - 1, rmax + padding)
    cmin = max(0, cmin - padding)
    cmax = min(img.width - 1, cmax + padding)

    return img.crop((cmin, rmin, cmax + 1, rmax + 1))

def center_on_canvas(img, target_size):
    """Center content on a transparent canvas of target size"""
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))

    # Calculate position to center
    x = (target_size - img.width) // 2
    y = (target_size - img.height) // 2

    canvas.paste(img, (x, y), img)
    return canvas

def post_process(img, target_size=64):
    """Full post-processing pipeline"""
    # 1. Remove background
    img = remove_background(img)

    # 2. Resize to slightly larger than target (for better quality)
    img = img.resize((target_size * 2, target_size * 2), Image.Resampling.LANCZOS)

    # 3. Auto-crop to content
    img = auto_crop_to_content(img, padding=4)

    # 4. Scale to fit within target while maintaining aspect ratio
    aspect = img.width / img.height
    if aspect > 1:
        new_width = target_size - 4  # Leave some margin
        new_height = int(new_width / aspect)
    else:
        new_height = target_size - 4
        new_width = int(new_height * aspect)

    img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # 5. Center on target canvas
    img = center_on_canvas(img, target_size)

    return img

def main():
    print("=" * 60)
    print("PHASE 1 v2: 64x64 Style Test with Refined Prompts")
    print("=" * 60)

    client = OpenAI(api_key=OPENAI_API_KEY)
    sprites = {}

    for subject in TEST_SUBJECTS:
        print(f"\n[{subject['name']}]")

        # Generate
        img, revised_prompt = generate_sprite(client, subject)

        if img:
            # Save full-size original
            fullsize_path = STYLE_TEST_DIR / f"{subject['id']}_full.png"
            img.save(fullsize_path)
            print(f"    Saved full: {fullsize_path.name}")

            # Post-process to 64x64
            processed = post_process(img, target_size=64)

            # Save 64x64
            sprite_path = STYLE_TEST_DIR / f"{subject['id']}_64.png"
            processed.save(sprite_path)
            print(f"    Saved 64x64: {sprite_path.name}")

            # Save 4x preview (256x256) for easy viewing
            preview = processed.resize((256, 256), Image.Resampling.NEAREST)
            preview_path = STYLE_TEST_DIR / f"{subject['id']}_preview.png"
            preview.save(preview_path)
            print(f"    Saved preview: {preview_path.name}")

            sprites[subject['id']] = processed

            # Save prompt used
            prompt_path = STYLE_TEST_DIR / f"{subject['id']}_prompt.txt"
            with open(prompt_path, 'w') as f:
                f.write(f"=== Original Prompt ===\n{PROMPT_TEMPLATE.format(subject_prompt=subject['prompt'])}\n\n")
                f.write(f"=== DALL-E Revised Prompt ===\n{revised_prompt}\n")

    print("\n" + "=" * 60)
    print("PHASE 1 v2 COMPLETE!")
    print(f"Output: {STYLE_TEST_DIR}")
    print("=" * 60)
    print("\nGenerated sprites:")
    for name in sprites.keys():
        print(f"  - {name}_64.png (64x64)")
        print(f"  - {name}_preview.png (256x256 for viewing)")

if __name__ == "__main__":
    main()
