#!/usr/bin/env python3
"""
Scroll UI Asset Generator
Generates scroll background and roller/cap sprites via DALL-E 3.

Assets:
1. scroll_bg.png     - Clean aged parchment background (512x640)
2. scroll_roller.png - Left scroll roller with ornate cap (128x740)
   (Right roller is mirrored at integration time)

Cost: ~$0.08 (2 DALL-E 3 images at $0.04 each)

Usage:
    python scroll_gen.py              # Generate all
    python scroll_gen.py --bg-only    # Just parchment background
    python scroll_gen.py --roller-only # Just scroll roller
"""

import os
import sys
import time
from pathlib import Path

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image
    import numpy as np
    import requests
    from io import BytesIO
except ImportError:
    print("Required: pip install openai pillow python-dotenv numpy requests")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "ui" / "tome"
COST_PER_IMAGE = 0.04

client = OpenAI()


def generate_image(prompt: str, filename: str, target_size: tuple[int, int]) -> Path:
    """Generate a DALL-E 3 image and save resized to target_size."""
    print(f"  Generating {filename}...")
    print(f"  Prompt: {prompt[:80]}...")

    response = client.images.generate(
        model="dall-e-3",
        prompt=prompt,
        size="1024x1024",
        quality="standard",
        n=1,
    )

    image_url = response.data[0].url
    img_response = requests.get(image_url)
    img = Image.open(BytesIO(img_response.content)).convert("RGBA")

    # Resize to target
    img = img.resize(target_size, Image.Resampling.LANCZOS)

    out_path = OUTPUT_DIR / filename
    img.save(out_path, "PNG")
    print(f"  Saved: {out_path} ({target_size[0]}x{target_size[1]})")
    return out_path


def remove_background(img: Image.Image, threshold: int = 220) -> Image.Image:
    """Remove near-white background pixels, replace with transparent."""
    arr = np.array(img)
    # Detect near-white pixels
    brightness = arr[:, :, :3].mean(axis=2)
    mask = brightness > threshold
    arr[mask, 3] = 0  # Set alpha to 0 for bright pixels
    return Image.fromarray(arr)


def generate_scroll_bg():
    """Generate clean aged parchment background."""
    prompt = (
        "An unrolled ancient parchment scroll surface viewed from directly above, "
        "aged yellowed vellum with subtle natural variations and foxing marks, "
        "warm amber and cream tones, slightly darkened edges, "
        "no text no symbols no writing no decorations, "
        "dark fantasy illustration style, dramatic but subtle lighting, "
        "the parchment fills the entire frame edge to edge"
    )
    return generate_image(prompt, "scroll_bg.png", (512, 640))


def generate_scroll_roller():
    """Generate ornate scroll roller/cap - tall vertical cylinder."""
    prompt = (
        "A single ornate vertical scroll roller viewed from the front, "
        "dark aged wood cylinder with brass or bronze decorative end caps, "
        "intricate dwarven metalwork engravings on the metal caps, "
        "the roller runs vertically filling the full height of the image, "
        "dark fantasy illustration in the style of Lord of the Rings props, "
        "like the scroll cases found in the Mines of Moria, "
        "dramatic side lighting, solid black background behind the roller, "
        "no parchment visible just the wooden roller and metal caps"
    )
    path = generate_image(prompt, "scroll_roller_raw.png", (128, 740))

    # Post-process: remove black background
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)

    # Remove very dark pixels (black background)
    brightness = arr[:, :, :3].max(axis=2)
    dark_mask = brightness < 35
    arr[dark_mask, 3] = 0

    # Soften edges of the alpha
    from PIL import ImageFilter
    alpha = Image.fromarray(arr[:, :, 3])
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=1))
    arr[:, :, 3] = np.array(alpha)

    # Re-darken any remaining bright spots that shouldn't be there
    # (keep the roller itself)
    result = Image.fromarray(arr)
    out_path = OUTPUT_DIR / "scroll_roller.png"
    result.save(out_path, "PNG")
    print(f"  Post-processed: {out_path}")

    # Also create mirrored version for right side
    mirrored = result.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    mirror_path = OUTPUT_DIR / "scroll_roller_right.png"
    mirrored.save(mirror_path, "PNG")
    print(f"  Mirrored: {mirror_path}")

    # Clean up raw
    os.remove(path)

    return out_path


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate scroll UI assets")
    parser.add_argument("--bg-only", action="store_true", help="Only generate parchment bg")
    parser.add_argument("--roller-only", action="store_true", help="Only generate scroll roller")
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    total_cost = 0.0

    if not args.roller_only:
        print("\n=== Generating Scroll Background ===")
        generate_scroll_bg()
        total_cost += COST_PER_IMAGE
        time.sleep(2.5)

    if not args.bg_only:
        print("\n=== Generating Scroll Roller ===")
        generate_scroll_roller()
        total_cost += COST_PER_IMAGE

    print(f"\n=== Done! Total DALL-E cost: ${total_cost:.2f} ===")


if __name__ == "__main__":
    main()
