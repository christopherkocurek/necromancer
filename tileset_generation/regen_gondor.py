#!/usr/bin/env python3
"""
Regenerate Gondor male + female with weapons.
Male: sword + heavy kite shield | Female: great spear
Uses same pipeline as other Man sprites: DALL-E 3 -> bg removal -> 64x64 -> dark variant
"""
import os, sys, io, json, base64, time
from pathlib import Path
from datetime import datetime
import numpy as np
from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from openai import OpenAI
from PIL import Image, ImageEnhance

# Import prompt builder from player_gen
sys.path.insert(0, str(Path(__file__).parent))
from player_gen import get_player_prompt, generate_dark_variant, HOUSES, RACES

BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "player_v2"
RAW_DIR = OUTPUT_DIR / "raw"
MAN_DIR = OUTPUT_DIR / "man"
PROGRESS_PATH = BASE_DIR / "player_v2_progress.json"

def remove_background(img: Image.Image) -> Image.Image:
    """Remove magenta background using edge flood fill + interior cleanup."""
    arr = np.array(img.convert("RGBA")).copy()
    h, w = arr.shape[:2]
    r, g, b, a = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int), arr[:,:,3]

    def is_pink_seed(ri, gi, bi):
        return ri > 100 and gi < ri * 0.55 and bi > gi and (ri - gi) > 50

    def is_pink_spread(ri, gi, bi):
        return ri > 80 and gi < ri * 0.6 and bi > gi and (ri - gi) > 40

    def is_pink_interior(ri, gi, bi):
        return ri > 60 and gi < ri * 0.6 and bi > gi and (ri - gi) > 30

    # Pass 1: Edge flood fill
    removed = np.zeros((h, w), dtype=bool)
    queue = []

    # Seed from all edges
    for y in range(h):
        for x in [0, w-1]:
            if a[y, x] > 0 and is_pink_seed(r[y,x], g[y,x], b[y,x]):
                queue.append((y, x))
                removed[y, x] = True
    for x in range(w):
        for y in [0, h-1]:
            if not removed[y, x] and a[y, x] > 0 and is_pink_seed(r[y,x], g[y,x], b[y,x]):
                queue.append((y, x))
                removed[y, x] = True

    # BFS spread
    while queue:
        cy, cx = queue.pop(0)
        for dy in [-1, 0, 1]:
            for dx in [-1, 0, 1]:
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and not removed[ny, nx]:
                    if a[ny, nx] > 0 and is_pink_spread(r[ny,nx], g[ny,nx], b[ny,nx]):
                        removed[ny, nx] = True
                        queue.append((ny, nx))

    count_flood = np.sum(removed)
    print(f"  Pass 1 (flood fill): removed {count_flood} pixels")

    # Pass 2: Interior pink cleanup
    count_interior = 0
    for y in range(h):
        for x in range(w):
            if not removed[y, x] and a[y, x] > 0:
                if is_pink_interior(r[y,x], g[y,x], b[y,x]):
                    removed[y, x] = True
                    count_interior += 1
    print(f"  Pass 2 (interior): removed {count_interior} pixels")

    # Pass 3: Fringe cleanup (2 iterations)
    for iteration in range(2):
        fringe = np.zeros((h, w), dtype=bool)
        for y in range(h):
            for x in range(w):
                if not removed[y, x] and a[y, x] > 0:
                    # Check if adjacent to removed pixel
                    adjacent = False
                    for dy in [-1, 0, 1]:
                        for dx in [-1, 0, 1]:
                            ny, nx = y + dy, x + dx
                            if 0 <= ny < h and 0 <= nx < w and removed[ny, nx]:
                                adjacent = True
                                break
                        if adjacent:
                            break
                    if adjacent:
                        ri, gi, bi = r[y,x], g[y,x], b[y,x]
                        if ri > 40 and gi < ri * 0.55 and bi > gi * 1.1 and (ri - gi) > 15:
                            fringe[y, x] = True
        removed |= fringe
        print(f"  Pass 3 iter {iteration+1} (fringe): removed {np.sum(fringe)} pixels")

    # Apply removal
    arr[removed, 3] = 0
    total_removed = np.sum(removed)
    total_pixels = h * w
    print(f"  Total removed: {total_removed}/{total_pixels} ({total_removed/total_pixels*100:.1f}%)")

    return Image.fromarray(arr, "RGBA")


def auto_crop_square(img: Image.Image, target_size: int = 64) -> Image.Image:
    """Crop to content bounding box, square, resize."""
    arr = np.array(img)
    alpha = arr[:,:,3]
    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)
    if not np.any(rows) or not np.any(cols):
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)

    y0, y1 = np.argmax(rows), len(rows) - np.argmax(rows[::-1])
    x0, x1 = np.argmax(cols), len(cols) - np.argmax(cols[::-1])

    # Add small padding
    pad = 4
    y0 = max(0, y0 - pad)
    y1 = min(arr.shape[0], y1 + pad)
    x0 = max(0, x0 - pad)
    x1 = min(arr.shape[1], x1 + pad)

    cropped = img.crop((x0, y0, x1, y1))
    cw, ch = cropped.size

    # Square it
    if cw != ch:
        max_dim = max(cw, ch)
        square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
        square.paste(cropped, ((max_dim - cw) // 2, (max_dim - ch) // 2))
        cropped = square

    return cropped.resize((target_size, target_size), Image.Resampling.NEAREST)


def generate_sprite(client, race_key, house_id, gender):
    """Generate one sprite end-to-end: DALL-E -> bg removal -> 64x64 -> dark."""
    key = f"player_{race_key}_h{house_id}_{gender}"
    raw_path = RAW_DIR / f"{key}_1024.png"
    nobg_path = RAW_DIR / f"{key}_1024_nobg.png"
    light_path = MAN_DIR / f"{key}_light.png"
    dark_path = MAN_DIR / f"{key}_dark.png"

    house = HOUSES[house_id]
    label = f"{house['short']} ({gender})"

    # Step 1: Generate via DALL-E 3
    prompt = get_player_prompt(race_key, house_id, gender)
    print(f"\n{'='*60}")
    print(f"Generating: {label}")
    print(f"Prompt: {prompt[:200]}...")

    response = client.images.generate(
        model="dall-e-3",
        prompt=prompt,
        size="1024x1024",
        quality="standard",
        style="vivid",
        n=1,
        response_format="b64_json",
    )

    img_data = base64.b64decode(response.data[0].b64_json)
    img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")
    img_1024.save(raw_path)
    print(f"  Saved raw 1024: {raw_path.name}")

    revised = getattr(response.data[0], "revised_prompt", None)
    if revised:
        print(f"  Revised: {revised[:150]}...")

    # Step 2: Remove background
    print(f"  Removing background...")
    img_nobg = remove_background(img_1024)
    img_nobg.save(nobg_path)
    print(f"  Saved nobg: {nobg_path.name}")

    # Step 3: Auto-crop + resize to 64x64
    img_64 = auto_crop_square(img_nobg, 64)
    img_64.save(light_path)
    print(f"  Saved 64x64 light: {light_path.name}")

    # Step 4: Dark variant
    img_dark = generate_dark_variant(img_64)
    img_dark.save(dark_path)
    print(f"  Saved 64x64 dark: {dark_path.name}")

    return light_path, dark_path


def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not set")
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    MAN_DIR.mkdir(parents=True, exist_ok=True)

    sprites = [
        ("man", 5, "male"),    # Gondor male: sword + heavy shield
        ("man", 5, "female"),  # Gondor female: great spear
    ]

    cost = 0
    for race_key, house_id, gender in sprites:
        light, dark = generate_sprite(client, race_key, house_id, gender)
        cost += 0.04
        print(f"  Done! Cost so far: ${cost:.2f}")
        time.sleep(2.5)  # Rate limit

    # Update progress
    if PROGRESS_PATH.exists():
        with open(PROGRESS_PATH) as f:
            progress = json.load(f)
    else:
        progress = {"sprites": {}, "api_calls": 0, "cost_total": 0}

    progress["api_calls"] = progress.get("api_calls", 0) + len(sprites)
    progress["cost_total"] = progress.get("cost_total", 0) + cost

    for race_key, house_id, gender in sprites:
        key = f"player_{race_key}_h{house_id}_{gender}"
        progress["sprites"][key] = {
            "status": "completed",
            "path": str(MAN_DIR / f"{key}_light.png"),
            "dark_path": str(MAN_DIR / f"{key}_dark.png"),
            "race": race_key,
            "house_id": house_id,
            "house_name": HOUSES[house_id]["short"],
            "gender": gender,
            "valid": True,
            "validation_msg": "OK",
            "completed_at": datetime.now().isoformat(),
        }

    progress["last_updated"] = datetime.now().isoformat()
    with open(PROGRESS_PATH, "w") as f:
        json.dump(progress, f, indent=2)

    print(f"\n{'='*60}")
    print(f"DONE! Generated {len(sprites)} Gondor sprites with weapons.")
    print(f"Total cost: ${cost:.2f}")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
