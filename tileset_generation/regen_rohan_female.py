#!/usr/bin/env python3
"""
Regenerate the Rohan female player sprite with a clean magenta background.

The current raw image has a 3-color patchwork background (magenta, green, olive)
that's nearly impossible to remove programmatically. The CHARACTER is great though.

Approach:
1. Try DALL-E 2 image edit: mask the background, ask for solid magenta fill
2. If that fails, regenerate entirely with DALL-E 3
3. Apply background removal (flood fill + pink cleanup) for transparency
4. Resize to 64x64 nearest neighbor
5. Generate dark variant
"""

import os
import sys
import io
import base64
import time
from pathlib import Path

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

from openai import OpenAI
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import numpy as np

# Paths
BASE_DIR = Path(__file__).parent
PLAYER_DIR = BASE_DIR / "player_v2"
RAW_DIR = PLAYER_DIR / "raw"
MAN_DIR = PLAYER_DIR / "man"

SOURCE_IMG = RAW_DIR / "player_man_h4_female_1024.png"
REGEN_IMG = RAW_DIR / "player_man_h4_female_1024_regen.png"
LIGHT_OUT = MAN_DIR / "player_man_h4_female_light.png"
DARK_OUT = MAN_DIR / "player_man_h4_female_dark.png"

TILE_SIZE = 64


def flood_fill_from_edges(mask_bool: np.ndarray) -> np.ndarray:
    """
    Pure numpy flood fill: find all True pixels in mask_bool that are
    connected to any edge pixel via 8-connectivity. Returns a boolean
    array of edge-connected pixels.
    """
    h, w = mask_bool.shape
    filled = np.zeros_like(mask_bool)

    # Seed from all 4 edges
    filled[0, :] |= mask_bool[0, :]
    filled[-1, :] |= mask_bool[-1, :]
    filled[:, 0] |= mask_bool[:, 0]
    filled[:, -1] |= mask_bool[:, -1]

    # Iterative expansion (8-connectivity)
    changed = True
    iteration = 0
    while changed:
        iteration += 1
        expanded = np.zeros_like(filled)
        # 8-directional neighbors
        expanded[1:, :] |= filled[:-1, :]    # from above
        expanded[:-1, :] |= filled[1:, :]    # from below
        expanded[:, 1:] |= filled[:, :-1]    # from left
        expanded[:, :-1] |= filled[:, 1:]    # from right
        expanded[1:, 1:] |= filled[:-1, :-1]     # top-left
        expanded[1:, :-1] |= filled[:-1, 1:]     # top-right
        expanded[:-1, 1:] |= filled[1:, :-1]     # bottom-left
        expanded[:-1, :-1] |= filled[1:, 1:]     # bottom-right

        # Only expand into mask_bool pixels
        new_filled = filled | (expanded & mask_bool)
        changed = np.any(new_filled != filled)
        filled = new_filled

        if iteration % 50 == 0:
            print(f"    Flood fill iteration {iteration}...")

    print(f"    Flood fill completed in {iteration} iterations")
    return filled


def dilate_mask(mask_bool: np.ndarray, iterations: int = 1) -> np.ndarray:
    """Dilate a boolean mask using 8-connectivity, pure numpy."""
    result = mask_bool.copy()
    for _ in range(iterations):
        expanded = np.zeros_like(result)
        expanded[1:, :] |= result[:-1, :]
        expanded[:-1, :] |= result[1:, :]
        expanded[:, 1:] |= result[:, :-1]
        expanded[:, :-1] |= result[:, 1:]
        expanded[1:, 1:] |= result[:-1, :-1]
        expanded[1:, :-1] |= result[:-1, 1:]
        expanded[:-1, 1:] |= result[1:, :-1]
        expanded[:-1, :-1] |= result[1:, 1:]
        result = result | expanded
    return result


def erode_mask(mask_bool: np.ndarray, iterations: int = 1) -> np.ndarray:
    """Erode a boolean mask using 8-connectivity, pure numpy."""
    # Erosion = NOT(dilation(NOT(mask)))
    return ~dilate_mask(~mask_bool, iterations)


def prepare_image_for_edit(img: Image.Image, mask: Image.Image) -> Image.Image:
    """
    Prepare image for DALL-E 2 edit endpoint.

    The image must be RGBA PNG where transparent areas match the mask's
    transparent areas (areas to edit).
    """
    img_rgba = img.convert("RGBA")
    img_arr = np.array(img_rgba)
    mask_arr = np.array(mask)

    # Make image transparent where mask is transparent
    img_arr[mask_arr[:, :, 3] == 0, 3] = 0

    return Image.fromarray(img_arr, "RGBA")


def attempt_dalle2_edit(client: OpenAI, img: Image.Image) -> Image.Image:
    """
    Attempt to use DALL-E 2 edit endpoint to replace background with solid magenta.
    """
    print("\n=== DALL-E 2 Edit Approach ===")

    # Create mask
    print("Creating background mask...")
    mask = create_mask_from_image(img)
    mask_path = RAW_DIR / "player_man_h4_female_mask.png"
    mask.save(mask_path)
    print(f"  Saved mask to: {mask_path}")

    # Count masked pixels
    mask_arr = np.array(mask)
    transparent_pct = (mask_arr[:, :, 3] == 0).sum() / (mask_arr.shape[0] * mask_arr.shape[1]) * 100
    print(f"  Background (to edit): {transparent_pct:.1f}% of image")

    # Prepare image (transparent where mask is transparent)
    print("Preparing image with transparent background areas...")
    edit_img = prepare_image_for_edit(img, mask)
    edit_path = RAW_DIR / "player_man_h4_female_edit_input.png"
    edit_img.save(edit_path)
    print(f"  Saved edit input to: {edit_path}")

    # Convert to bytes for API
    img_bytes = io.BytesIO()
    edit_img.save(img_bytes, format="PNG")
    img_bytes.seek(0)

    mask_bytes = io.BytesIO()
    mask.save(mask_bytes, format="PNG")
    mask_bytes.seek(0)

    # Check file sizes
    img_size = img_bytes.getbuffer().nbytes
    mask_size = mask_bytes.getbuffer().nbytes
    print(f"  Image size: {img_size / 1024:.0f}KB, Mask size: {mask_size / 1024:.0f}KB")

    if img_size > 4 * 1024 * 1024 or mask_size > 4 * 1024 * 1024:
        print("  WARNING: Files exceed 4MB limit!")

    # Call DALL-E 2 edit
    print("Calling DALL-E 2 images.edit...")
    response = client.images.edit(
        image=img_bytes,
        mask=mask_bytes,
        prompt="solid flat uniform bright magenta pink background color, nothing else, pure flat magenta fill",
        size="1024x1024",
        n=1,
        response_format="b64_json",
    )

    print("  Got response from DALL-E 2!")
    result_data = base64.b64decode(response.data[0].b64_json)
    result_img = Image.open(io.BytesIO(result_data)).convert("RGBA")

    return result_img


def attempt_dalle3_regen(client: OpenAI) -> Image.Image:
    """
    Fallback: regenerate entirely with DALL-E 3.
    """
    print("\n=== DALL-E 3 Regeneration Fallback ===")

    prompt = (
        "A fantasy book cover painting of a human woman, strong and resolute, "
        "practical build, wearing chainmail armor with a green surcoat bearing "
        "a white horse emblem on the chest, a round wooden shield, blond hair, "
        "stern warrior. The lone figure stands centered facing the viewer. "
        "Vivid striking colors: green, gold, brown leather, iron chainmail. "
        "Strong readable silhouette, bold saturated armor and clothing. "
        "The entire background is solid flat bright magenta pink, like a green "
        "screen but magenta. Nothing else in the image except the character "
        "against flat magenta. No floor, no ground, no shadows on the background. "
        "Painted in a clean illustrative style like a Tolkien book cover."
    )

    print(f"Prompt: {prompt[:120]}...")
    print("Calling DALL-E 3 images.generate...")

    response = client.images.generate(
        model="dall-e-3",
        prompt=prompt,
        size="1024x1024",
        quality="standard",
        style="vivid",
        n=1,
        response_format="b64_json",
    )

    print("  Got response from DALL-E 3!")
    revised = getattr(response.data[0], "revised_prompt", None)
    if revised:
        print(f"  Revised prompt: {revised[:150]}...")

    result_data = base64.b64decode(response.data[0].b64_json)
    result_img = Image.open(io.BytesIO(result_data)).convert("RGBA")

    return result_img


def remove_magenta_background(img: Image.Image) -> Image.Image:
    """
    Remove magenta/pink background using edge flood fill + interior cleanup.
    Returns image with transparent background. Pure numpy, no scipy.
    """
    print("\nRemoving magenta background...")
    arr = np.array(img.convert("RGBA"))
    h, w = arr.shape[:2]
    r, g, b = arr[:, :, 0].astype(float), arr[:, :, 1].astype(float), arr[:, :, 2].astype(float)

    # Detect magenta/pink pixels - the DALL-E 3 bg should be uniform magenta
    # Magenta: high red, low-medium green, high blue
    is_pink = (
        (r > 140) & (b > 100) &
        (g < r - 40) & (g < b + 30) &
        ((r + b) > (2 * g + 80))
    )

    # Also detect near-white/light pink that DALL-E might add
    is_light_pink = (r > 200) & (b > 180) & (g < 180) & (r > g)

    is_magenta_ish = is_pink | is_light_pink

    magenta_count = is_magenta_ish.sum()
    print(f"  Detected {magenta_count} magenta-ish pixels ({magenta_count / (h * w) * 100:.1f}%)")

    # Flood fill from edges to find background
    print("  Flood filling from edges...")
    bg_mask = flood_fill_from_edges(is_magenta_ish)

    # Also do a second pass: any remaining magenta pixel clusters
    # that are NOT connected to edges but are large (interior bg pockets)
    remaining_magenta = is_magenta_ish & ~bg_mask
    remaining_count = remaining_magenta.sum()
    if remaining_count > 0:
        print(f"  {remaining_count} interior magenta pixels remain, checking...")
        # Simple approach: any remaining magenta pixel is likely bg
        # (character shouldn't have many pure magenta pixels)
        bg_mask |= remaining_magenta

    # Dilate slightly to clean edges
    bg_mask = dilate_mask(bg_mask, iterations=1)

    # Apply transparency
    arr[bg_mask, 3] = 0

    # Anti-alias: partially transparent for edge pixels
    eroded_fg = erode_mask(~bg_mask, iterations=1)
    border = (~bg_mask) & (~eroded_fg)
    arr[border, 3] = 180  # Semi-transparent edges

    removed_pct = bg_mask.sum() / (h * w) * 100
    print(f"  Removed {removed_pct:.1f}% of pixels as background")

    return Image.fromarray(arr, "RGBA")


def auto_crop_to_content(img: Image.Image) -> Image.Image:
    """Crop to content bounding box (non-transparent pixels)."""
    arr = np.array(img)
    alpha = arr[:, :, 3]

    rows = np.any(alpha > 0, axis=1)
    cols = np.any(alpha > 0, axis=0)

    if not np.any(rows) or not np.any(cols):
        return img

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]

    # Add small padding
    pad = 4
    rmin = max(0, rmin - pad)
    rmax = min(arr.shape[0] - 1, rmax + pad)
    cmin = max(0, cmin - pad)
    cmax = min(arr.shape[1] - 1, cmax + pad)

    cropped = img.crop((cmin, rmin, cmax + 1, rmax + 1))
    w, h = cropped.size
    print(f"  Cropped to content: {w}x{h}")

    # Make square
    if w != h:
        max_dim = max(w, h)
        square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
        paste_x = (max_dim - w) // 2
        paste_y = (max_dim - h) // 2
        square.paste(cropped, (paste_x, paste_y))
        cropped = square
        print(f"  Squared to: {max_dim}x{max_dim}")

    return cropped


def generate_dark_variant(img: Image.Image) -> Image.Image:
    """Generate dark/FOV variant: desaturate 60%, darken 40%, cool blue tint."""
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
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, "RGB")

    if alpha is not None:
        result = result.convert("RGBA")
        result.putalpha(alpha)

    return result


def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found. Check tileset_generation/.env")
        sys.exit(1)

    client = OpenAI(api_key=api_key)

    # Check if we already have a regen image (from previous run)
    if REGEN_IMG.exists():
        print(f"Found existing regen image: {REGEN_IMG}")
        print("  Skipping generation, using existing file.")
        result_img = Image.open(REGEN_IMG).convert("RGBA")
        print(f"  Size: {result_img.size}")
    else:
        # Load source image
        print(f"Loading source image: {SOURCE_IMG}")
        if not SOURCE_IMG.exists():
            print(f"ERROR: Source image not found: {SOURCE_IMG}")
            sys.exit(1)

        source_img = Image.open(SOURCE_IMG).convert("RGBA")
        print(f"  Size: {source_img.size}, Mode: {source_img.mode}")

        # Try DALL-E 3 regeneration (DALL-E 2 edit needs scipy for mask)
        result_img = None
        try:
            result_img = attempt_dalle3_regen(client)
            result_img.save(REGEN_IMG)
            print(f"\nSaved DALL-E 3 result: {REGEN_IMG}")
        except Exception as e:
            print(f"\nDALL-E 3 failed: {e}")
            sys.exit(1)

    # Remove background
    nobg_img = remove_magenta_background(result_img)
    nobg_path = RAW_DIR / "player_man_h4_female_1024_regen_nobg.png"
    nobg_img.save(nobg_path)
    print(f"Saved no-bg: {nobg_path}")

    # Crop to content
    cropped = auto_crop_to_content(nobg_img)

    # Resize to 64x64
    img_64 = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)
    print(f"\nResized to {TILE_SIZE}x{TILE_SIZE}")

    # Save light variant
    img_64.save(LIGHT_OUT)
    print(f"Saved light: {LIGHT_OUT}")

    # Generate and save dark variant
    img_dark = generate_dark_variant(img_64)
    img_dark.save(DARK_OUT)
    print(f"Saved dark: {DARK_OUT}")

    print(f"\n{'=' * 60}")
    print("DONE! Files saved:")
    print(f"  1024 regen:  {REGEN_IMG}")
    print(f"  1024 no-bg:  {nobg_path}")
    print(f"  64x64 light: {LIGHT_OUT}")
    print(f"  64x64 dark:  {DARK_OUT}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
