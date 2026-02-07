#!/usr/bin/env python3
"""
Scroll UI Asset Generator v2
Improved prompts for flat parchment bg and thick scroll rollers.

Cost: ~$0.08 (2 DALL-E 3 images at $0.04 each)
"""

import os
import sys
import time
from pathlib import Path

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter
    import numpy as np
    import requests
    from io import BytesIO
except ImportError:
    print("Required: pip install openai pillow python-dotenv numpy requests")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "ui" / "tome"
COST_PER_IMAGE = 0.04

client = OpenAI()


def generate_image(prompt: str, filename: str, size: tuple[int, int]) -> Path:
    """Generate a DALL-E 3 image and save resized."""
    print(f"  Generating {filename}...")
    print(f"  Prompt: {prompt[:100]}...")

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
    img = img.resize(size, Image.Resampling.LANCZOS)

    out_path = OUTPUT_DIR / filename
    img.save(out_path, "PNG")
    print(f"  Saved: {out_path} ({size[0]}x{size[1]})")
    return out_path


def generate_scroll_bg():
    """Generate flat parchment texture — no perspective, no rollers, pure surface."""
    prompt = (
        "A perfectly flat aged parchment surface texture photographed from directly above, "
        "filling the entire image edge to edge with no borders or margins, "
        "warm cream and amber tones with subtle natural aging marks and slight foxing, "
        "slightly darker at the edges, lighter in the center, "
        "no text no symbols no writing no objects no scroll rollers visible, "
        "just the flat paper surface, macro photography style, even lighting"
    )
    return generate_image(prompt, "scroll_bg.png", (512, 640))


def generate_scroll_roller():
    """Generate a thick ornate scroll roller — fills most of the frame."""
    prompt = (
        "A thick ornate wooden scroll roller dowel seen from the front against a pure bright green background, "
        "the roller is a vertical dark brown wooden cylinder with ornate bronze dwarven end caps at top and bottom, "
        "intricate Celtic knotwork engravings on the bronze caps, "
        "the wooden shaft has a rich dark walnut grain texture with metal reinforcement bands, "
        "the roller takes up at least 60 percent of the image width, "
        "dramatic side lighting highlighting the cylindrical form, "
        "dark fantasy illustration style like Lord of the Rings Moria props, "
        "pure bright green chromakey background, nothing else in the image"
    )
    path = generate_image(prompt, "scroll_roller_raw.png", (160, 756))

    # Post-process: remove green chromakey background
    img = Image.open(path).convert("RGBA")
    arr = np.array(img, dtype=np.float32)

    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    # Green screen removal: pixels where green is dominant
    green_dominant = (g > r * 1.2) & (g > b * 1.2) & (g > 80)
    # Also catch bright/light green
    bright_green = (g > 150) & (g > r * 1.1) & (g > b * 1.1)
    # And near-white that might be background
    near_white = (r > 200) & (g > 200) & (b > 200)

    remove_mask = green_dominant | bright_green | near_white

    arr_out = arr.copy()
    arr_out[remove_mask, 3] = 0

    # Soften alpha edges
    result = Image.fromarray(arr_out.astype(np.uint8))
    alpha_channel = result.split()[3]
    alpha_channel = alpha_channel.filter(ImageFilter.GaussianBlur(radius=1.5))
    # Re-threshold to avoid too much blur
    alpha_arr = np.array(alpha_channel)
    alpha_arr[alpha_arr < 30] = 0
    result.putalpha(Image.fromarray(alpha_arr))

    out_path = OUTPUT_DIR / "scroll_roller.png"
    result.save(out_path, "PNG")
    print(f"  Post-processed: {out_path}")

    # Create mirrored version for right side
    mirrored = result.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    mirror_path = OUTPUT_DIR / "scroll_roller_right.png"
    mirrored.save(mirror_path, "PNG")
    print(f"  Mirrored: {mirror_path}")

    # Clean up raw
    os.remove(path)

    return out_path


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--bg-only", action="store_true")
    parser.add_argument("--roller-only", action="store_true")
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    total_cost = 0.0

    if not args.roller_only:
        print("\n=== Generating Scroll Background (flat parchment) ===")
        generate_scroll_bg()
        total_cost += COST_PER_IMAGE
        time.sleep(2.5)

    if not args.bg_only:
        print("\n=== Generating Scroll Roller (green screen + chroma key) ===")
        generate_scroll_roller()
        total_cost += COST_PER_IMAGE

    print(f"\n=== Done! Total DALL-E cost: ${total_cost:.2f} ===")


if __name__ == "__main__":
    main()
