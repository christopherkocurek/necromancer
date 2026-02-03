#!/usr/bin/env python3
"""
Production Sprite Generation - Generate all sprites for The Necromancer
Uses DALL-E 3 with refined prompts and proper post-processing
Supports resuming from interruption via manifest.json
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

from sprite_data import get_all_sprites, BASE_TEMPLATE

# =============================================================================
# CONFIGURATION
# =============================================================================
OPENAI_API_KEY = "YOUR_OPENAI_API_KEY_HERE"

PROJECT_ROOT = Path(__file__).parent.parent.parent
OUTPUT_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = OUTPUT_DIR / "final"
WIP_DIR = OUTPUT_DIR / "wip"
MANIFEST_PATH = OUTPUT_DIR / "sprite_manifest.json"
LOG_PATH = OUTPUT_DIR / "generation_log.jsonl"

TARGET_SIZE = 64
MAX_ATTEMPTS = 3
RATE_LIMIT_DELAY = 12  # seconds between API calls (5/min limit)

# =============================================================================
# MANIFEST MANAGEMENT
# =============================================================================
def load_manifest():
    """Load or create the sprite manifest"""
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, 'r') as f:
            return json.load(f)
    return {
        "version": "1.0",
        "target_size": TARGET_SIZE,
        "created": datetime.now().isoformat(),
        "sprites": {}
    }

def save_manifest(manifest):
    """Save the manifest"""
    manifest["updated"] = datetime.now().isoformat()
    with open(MANIFEST_PATH, 'w') as f:
        json.dump(manifest, f, indent=2)

def log_generation(sprite_id, status, details):
    """Append to generation log"""
    entry = {
        "timestamp": datetime.now().isoformat(),
        "sprite_id": sprite_id,
        "status": status,
        **details
    }
    with open(LOG_PATH, 'a') as f:
        f.write(json.dumps(entry) + "\n")

# =============================================================================
# IMAGE GENERATION
# =============================================================================
def generate_image(client, sprite_data, attempt=1):
    """Generate a sprite using DALL-E 3"""
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
        revised_prompt = response.data[0].revised_prompt

        # Download the image
        img_response = requests.get(image_url, timeout=60)
        img = Image.open(io.BytesIO(img_response.content))

        return img, revised_prompt, None

    except Exception as e:
        return None, None, str(e)

# =============================================================================
# POST-PROCESSING
# =============================================================================
def remove_background(img):
    """Remove magenta and near-magenta background"""
    img = img.convert("RGBA")
    data = np.array(img)

    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]

    # Detect magenta-ish pixels (various shades DALL-E might use)
    # Magenta: high R, low G, high B
    magenta_mask = (r > 180) & (g < 120) & (b > 180)

    # Also catch very light/white pixels at edges
    white_mask = (r > 245) & (g > 245) & (b > 245)

    # Combine masks
    background_mask = magenta_mask | white_mask

    # Set background to transparent
    data[:,:,3] = np.where(background_mask, 0, 255)

    return Image.fromarray(data)

def auto_crop_to_content(img, padding=2):
    """Crop to content bounding box"""
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
    """Center content on transparent canvas"""
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    x = (target_size - img.width) // 2
    y = (target_size - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas

def post_process(img, target_size=64):
    """Full post-processing pipeline"""
    # 1. Remove background
    img = remove_background(img)

    # 2. Resize to 2x target for quality
    img = img.resize((target_size * 2, target_size * 2), Image.Resampling.LANCZOS)

    # 3. Auto-crop
    img = auto_crop_to_content(img, padding=4)

    # 4. Scale to fit within target
    max_dim = max(img.width, img.height)
    if max_dim > target_size - 4:
        scale = (target_size - 4) / max_dim
        new_width = int(img.width * scale)
        new_height = int(img.height * scale)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # 5. Center on canvas
    img = center_on_canvas(img, target_size)

    return img

# =============================================================================
# MAIN GENERATION LOOP
# =============================================================================
def generate_sprite(client, sprite_data, manifest):
    """Generate a single sprite with retries"""
    sprite_id = sprite_data["id"]
    sprite_name = sprite_data["name"]
    filename = sprite_data["filename"]

    # Check if already completed
    if sprite_id in manifest["sprites"]:
        status = manifest["sprites"][sprite_id].get("status")
        if status == "completed":
            print(f"  [SKIP] {sprite_name} - already completed")
            return True

    print(f"  [GEN] {sprite_name}...")

    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"    Attempt {attempt}/{MAX_ATTEMPTS}...")

        # Generate image
        img, revised_prompt, error = generate_image(client, sprite_data, attempt)

        if error:
            print(f"    ERROR: {error}")
            log_generation(sprite_id, "error", {"attempt": attempt, "error": error})
            time.sleep(RATE_LIMIT_DELAY)
            continue

        # Post-process
        try:
            processed = post_process(img, TARGET_SIZE)
        except Exception as e:
            print(f"    POST-PROCESS ERROR: {e}")
            log_generation(sprite_id, "post_process_error", {"attempt": attempt, "error": str(e)})
            time.sleep(RATE_LIMIT_DELAY)
            continue

        # Ensure output directories exist
        output_path = FINAL_DIR / f"{filename}.png"
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Save files
        processed.save(output_path)

        # Save full-size backup
        wip_path = WIP_DIR / f"{filename}_full.png"
        wip_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(wip_path)

        # Save preview (4x)
        preview = processed.resize((256, 256), Image.Resampling.NEAREST)
        preview_path = WIP_DIR / f"{filename}_preview.png"
        preview.save(preview_path)

        # Update manifest
        manifest["sprites"][sprite_id] = {
            "status": "completed",
            "name": sprite_name,
            "filename": str(output_path.relative_to(OUTPUT_DIR)),
            "attempts": attempt,
            "completed": datetime.now().isoformat()
        }
        save_manifest(manifest)

        log_generation(sprite_id, "completed", {"attempt": attempt, "filename": filename})
        print(f"    SUCCESS: {output_path.name}")

        # Rate limiting
        time.sleep(RATE_LIMIT_DELAY)
        return True

    # All attempts failed
    manifest["sprites"][sprite_id] = {
        "status": "failed",
        "name": sprite_name,
        "attempts": MAX_ATTEMPTS,
        "failed": datetime.now().isoformat()
    }
    save_manifest(manifest)

    print(f"    FAILED after {MAX_ATTEMPTS} attempts")
    return False

def main():
    """Main generation loop"""
    print("=" * 70)
    print("NECROMANCER SPRITE GENERATION - PRODUCTION RUN")
    print("=" * 70)

    # Setup
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    FINAL_DIR.mkdir(parents=True, exist_ok=True)
    WIP_DIR.mkdir(parents=True, exist_ok=True)

    client = OpenAI(api_key=OPENAI_API_KEY)
    manifest = load_manifest()
    all_sprites = get_all_sprites()

    print(f"\nTarget: {len(all_sprites)} sprites at {TARGET_SIZE}x{TARGET_SIZE}")

    # Count status
    completed = sum(1 for s in manifest.get("sprites", {}).values() if s.get("status") == "completed")
    print(f"Already completed: {completed}")
    print(f"Remaining: {len(all_sprites) - completed}")

    print("\n" + "-" * 70)

    success_count = 0
    fail_count = 0

    for i, sprite_data in enumerate(all_sprites):
        print(f"\n[{i+1}/{len(all_sprites)}] {sprite_data['name']}")

        if generate_sprite(client, sprite_data, manifest):
            success_count += 1
        else:
            fail_count += 1

    # Final summary
    print("\n" + "=" * 70)
    print("GENERATION COMPLETE")
    print("=" * 70)
    print(f"Total: {len(all_sprites)}")
    print(f"Successful: {success_count}")
    print(f"Failed: {fail_count}")
    print(f"\nOutput: {FINAL_DIR}")
    print(f"Manifest: {MANIFEST_PATH}")

if __name__ == "__main__":
    main()
