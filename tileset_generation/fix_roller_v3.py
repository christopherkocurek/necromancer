#!/usr/bin/env python3
"""Aggressive green screen removal for scroll roller, then auto-crop to content."""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageFilter
    import numpy as np
except ImportError:
    print("Required: pip install pillow numpy")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "ui" / "tome"


def fix_roller():
    # Re-generate from v2's raw output if it exists, else use current
    roller_path = OUTPUT_DIR / "scroll_roller.png"
    img = Image.open(roller_path).convert("RGBA")
    arr = np.array(img, dtype=np.float32)

    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    # Very aggressive: anything with greenness > 0 AND not dark enough to be the roller
    greenness = g - np.maximum(r, b)

    # The roller itself is dark wood (browns, near-black metal)
    # Brightness of roller pixels is generally < 140
    brightness = (r + g + b) / 3.0

    # Remove: any pixel that is greenish OR very bright
    remove = (
        (greenness > 8) |  # Any noticeable green tint
        (brightness > 180) |  # Very bright = background
        ((greenness > 0) & (brightness > 120)) |  # Mild green + bright
        ((g > 100) & (greenness > -5) & (brightness > 100))  # Green-ish and bright-ish
    )

    # Protect clearly dark roller pixels
    protect = (brightness < 80) & (greenness < 10)
    remove = remove & ~protect

    new_alpha = np.where(remove, 0, 255).astype(np.uint8)

    # Green spill suppression on remaining pixels
    spill = (greenness > -3) & ~remove
    g_fixed = g.copy()
    g_fixed[spill] = np.minimum(g[spill], (r[spill] + b[spill]) / 2.0)

    # Erode to clean fringe, then smooth
    alpha_img = Image.fromarray(new_alpha)
    alpha_img = alpha_img.filter(ImageFilter.MinFilter(3))
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(radius=1.0))
    new_alpha = np.array(alpha_img)
    new_alpha[new_alpha < 50] = 0

    result_arr = np.stack([
        np.clip(r, 0, 255).astype(np.uint8),
        np.clip(g_fixed, 0, 255).astype(np.uint8),
        np.clip(b, 0, 255).astype(np.uint8),
        new_alpha
    ], axis=2)

    result = Image.fromarray(result_arr, "RGBA")

    # Auto-crop to content (non-transparent bounding box)
    bbox = result.getbbox()
    if bbox:
        # Add small padding
        pad = 4
        x1 = max(0, bbox[0] - pad)
        y1 = max(0, bbox[1] - pad)
        x2 = min(result.width, bbox[2] + pad)
        y2 = min(result.height, bbox[3] + pad)
        result = result.crop((x1, y1, x2, y2))
        print(f"  Cropped to content: {result.size}")

    # Scale to final size (100px wide, full height of scroll)
    final_w = 100
    final_h = 756
    result = result.resize((final_w, final_h), Image.Resampling.LANCZOS)

    result.save(roller_path, "PNG")
    print(f"  Saved: {roller_path} ({final_w}x{final_h})")

    # Mirror for right side
    mirrored = result.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    mirror_path = OUTPUT_DIR / "scroll_roller_right.png"
    mirrored.save(mirror_path, "PNG")
    print(f"  Mirrored: {mirror_path}")


if __name__ == "__main__":
    # Need to re-run from the DALL-E output before previous fix damaged it
    # Let's check if we can re-generate from v2
    print("=== Fixing scroll roller (aggressive chroma key + auto-crop) ===")

    # First re-generate the roller from DALL-E since our previous fix might have lost data
    # Check if we have a backup
    raw_path = OUTPUT_DIR / "scroll_roller_raw.png"
    if not raw_path.exists():
        # Need to re-download — just regenerate
        print("  No raw backup found. Re-generating via DALL-E...")
        from dotenv import load_dotenv
        load_dotenv(Path(__file__).parent / ".env")
        from openai import OpenAI
        import requests
        from io import BytesIO

        client = OpenAI()
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
        response = client.images.generate(
            model="dall-e-3", prompt=prompt, size="1024x1024", quality="standard", n=1
        )
        img_response = requests.get(response.data[0].url)
        img = Image.open(BytesIO(img_response.content)).convert("RGBA")
        img = img.resize((160, 756), Image.Resampling.LANCZOS)
        img.save(OUTPUT_DIR / "scroll_roller.png", "PNG")
        print(f"  Re-generated roller from DALL-E")

    fix_roller()
    print("\n=== Done! ===")
