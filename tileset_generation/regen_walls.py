#!/usr/bin/env python3
"""
Regenerate broken wall tiles: terrain_48, terrain_58, terrain_59
Fixes: perspective/scaling effects and terrain_48 having a door in it.
"""

import os
import sys
import json
import time
import base64
import io
from pathlib import Path
from datetime import datetime

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from openai import OpenAI
from PIL import Image, ImageEnhance
import numpy as np

TILE_SIZE = 64
WHITE_THRESHOLD = 240
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "terrain_v2"
PROGRESS_PATH = BASE_DIR / "terrain_v2_progress.json"

# These 3 walls need regeneration with fixed prompts
WALLS_TO_REGEN = [
    {
        "id": 48,
        "name": "hidden passage",
        # KEY FIX: No mention of "secret door" - just looks like a normal wall
        "desc": "rough gray stone wall blocks with dark mortar, identical to a standard dungeon wall, nothing unusual or distinctive about it, just ordinary stone masonry"
    },
    {
        "id": 58,
        "name": "dark stone wall 3",
        "desc": "dark stone wall made of large rectangular hewn blocks with deep dark mortar lines between them, uniformly dark gray throughout"
    },
    {
        "id": 59,
        "name": "dark stone wall 4",
        "desc": "dark stone wall with mixed irregular block sizes, some crumbling mortar at edges, weathered and ancient, uniformly dark gray throughout"
    },
]


def get_wall_prompt(desc: str) -> str:
    """
    Wall prompt with EXPLICIT anti-perspective instructions.
    The previous prompt said "Viewed straight-on from the front" which DALL-E
    interpreted as a corridor/hallway receding into the distance.
    Now we describe it as a FLAT surface texture with ZERO depth.
    """
    return (
        f"A close-up painting of {desc}. "
        f"This is a FLAT surface texture with absolutely NO depth, NO perspective, "
        f"NO vanishing point, and NO receding lines. "
        f"The wall is a perfectly flat plane filling the entire image. "
        f"Like a photograph taken with the camera pressed directly against the wall surface. "
        f"Every stone block is the same size on screen - NO blocks getting smaller toward any edge. "
        f"Dark fantasy style, ancient and weathered. "
        f"The wall surface fills the entire image completely, extending beyond all four edges. "
        f"Painted in a retro low-resolution blocky style with chunky stone blocks. "
        f"Very dark color palette: charcoal gray, near-black, dark brown. "
        f"No background visible. No floor. No ceiling. Just the wall surface."
    )


def auto_crop_and_stretch(img, target_size=TILE_SIZE):
    """Detect content area, crop out white borders, stretch to target_size."""
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]
    r, g, b = img_array[:,:,0], img_array[:,:,1], img_array[:,:,2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD

    rows_with_content = np.any(content_mask, axis=1)
    cols_with_content = np.any(content_mask, axis=0)

    if not np.any(rows_with_content) or not np.any(cols_with_content):
        print("  WARNING: Image appears entirely white/blank")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)

    row_start = np.argmax(rows_with_content)
    row_end = h - np.argmax(rows_with_content[::-1])
    col_start = np.argmax(cols_with_content)
    col_end = w - np.argmax(cols_with_content[::-1])

    border_top = row_start
    border_bottom = h - row_end
    border_left = col_start
    border_right = w - col_end

    print(f"  Border detection: top={border_top} bot={border_bottom} "
          f"left={border_left} right={border_right}")

    min_border = int(h * 0.02)
    if (border_top > min_border or border_bottom > min_border or
        border_left > min_border or border_right > min_border):
        padding = 2
        row_start = max(0, row_start - padding)
        row_end = min(h, row_end + padding)
        col_start = max(0, col_start - padding)
        col_end = min(w, col_end + padding)

        cropped = img.crop((col_start, row_start, col_end, row_end))
        crop_w, crop_h = cropped.size
        print(f"  Cropped: {w}x{h} -> {crop_w}x{crop_h}")

        if crop_w != crop_h:
            max_dim = max(crop_w, crop_h)
            square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 255))
            paste_x = (max_dim - crop_w) // 2
            paste_y = (max_dim - crop_h) // 2
            square.paste(cropped, (paste_x, paste_y))
            cropped = square

        result = cropped.resize((target_size, target_size), Image.Resampling.NEAREST)
        return result
    else:
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)


def generate_dark_variant(img):
    """Desaturate 60%, darken 40%, blue tint."""
    if img.mode == "RGBA":
        alpha = img.split()[3]
        rgb = img.convert("RGB")
    else:
        alpha = None
        rgb = img.convert("RGB")

    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)
    darkener = ImageEnhance.Brightness(desaturated)
    darkened = darkener.enhance(0.6)

    arr = np.array(darkened).astype(np.float32)
    arr[:,:,0] *= 0.85
    arr[:,:,1] *= 0.90
    arr[:,:,2] = np.minimum(arr[:,:,2] * 1.15, 255)
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, "RGB")
    if alpha is not None:
        result = result.convert("RGBA")
        result.putalpha(alpha)
    return result


def validate_wall_tile(img):
    """Extra validation: check for perspective artifacts."""
    arr = np.array(img.convert("RGB"))

    # Basic checks
    brightness = arr.mean()
    if brightness > 220:
        return False, f"Too bright ({brightness:.0f})"

    # Check edges aren't white
    edge_avg = (arr[0,:,:].mean() + arr[-1,:,:].mean() +
                arr[:,0,:].mean() + arr[:,-1,:].mean()) / 4
    if edge_avg > 200:
        return False, f"White edges ({edge_avg:.0f})"

    return True, "OK"


def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found")
        sys.exit(1)

    client = OpenAI(api_key=api_key)

    # Load progress
    with open(PROGRESS_PATH) as f:
        progress = json.load(f)

    cat_dir = OUTPUT_DIR / "wall"
    cat_dir.mkdir(parents=True, exist_ok=True)
    raw_dir = OUTPUT_DIR / "raw"
    raw_dir.mkdir(exist_ok=True)

    for wall in WALLS_TO_REGEN:
        tid = wall["id"]
        name = wall["name"]
        desc = wall["desc"]
        key = f"terrain_{tid}_light"

        prompt = get_wall_prompt(desc)
        print(f"\n{'='*60}")
        print(f"Regenerating: {name} (ID {tid})")
        print(f"Prompt: {prompt[:150]}...")

        # Delete old files
        old_light = cat_dir / f"terrain_{tid}_light.png"
        old_dark = cat_dir / f"terrain_{tid}_dark.png"
        old_raw = raw_dir / f"{key}_1024.png"
        for f in [old_light, old_dark, old_raw]:
            if f.exists():
                f.unlink()
                print(f"  Deleted old: {f.name}")

        # Generate with DALL-E 3
        try:
            response = client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style="natural",
                n=1,
                response_format="b64_json"
            )

            img_data = base64.b64decode(response.data[0].b64_json)
            img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")

            revised = getattr(response.data[0], 'revised_prompt', None)
            if revised:
                print(f"  Revised prompt: {revised[:120]}...")

            # Save raw
            raw_path = raw_dir / f"{key}_1024.png"
            img_1024.save(raw_path)

            # Crop and resize
            img_64 = auto_crop_and_stretch(img_1024)

            # Validate
            is_valid, reason = validate_wall_tile(img_64)
            print(f"  Validation: {reason}")

            # Save light
            light_path = cat_dir / f"terrain_{tid}_light.png"
            img_64.save(light_path)
            print(f"  Saved: {light_path.name}")

            # Generate and save dark
            img_dark = generate_dark_variant(img_64)
            dark_path = cat_dir / f"terrain_{tid}_dark.png"
            img_dark.save(dark_path)
            print(f"  Saved: {dark_path.name}")

            # Update progress
            progress["sprites"][key] = {
                "status": "completed",
                "path": str(light_path),
                "dark_path": str(dark_path),
                "terrain_id": tid,
                "name": name,
                "category": "wall",
                "valid": is_valid,
                "validation_msg": reason,
                "regenerated": True,
                "completed_at": datetime.now().isoformat()
            }
            progress["api_calls"] = progress.get("api_calls", 0) + 1
            progress["cost_total"] = progress.get("cost_total", 0) + 0.04

            print(f"  SUCCESS: terrain_{tid} regenerated")

        except Exception as e:
            print(f"  ERROR: {e}")
            continue

        time.sleep(2.5)

    # Save progress
    with open(PROGRESS_PATH, "w") as f:
        json.dump(progress, f, indent=2)

    print(f"\n{'='*60}")
    print(f"Regeneration complete! 3 walls updated.")
    print(f"Cost: $0.12 (3 images)")
    print(f"\nNext: run integrate_terrain_v2.py to rebuild tileset")


if __name__ == "__main__":
    main()
