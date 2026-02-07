#!/usr/bin/env python3
"""
Fix magenta bleed in monster sprites.

Problem: DALL-E's magenta background bleeds pink tint into creature bodies.
Dark creatures (rats, bats, wolves, squirrels) are especially affected.

Pipeline per monster:
1. Load raw 1024x1024
2. Identify creature vs background regions
3. For creature pixels with magenta tint, neutralize toward natural colors
4. 3-pass BG removal (edge flood fill, interior cleanup, fringe)
5. Auto-crop + resize to 64x64
6. Generate dark variant

Usage:
    python fix_monster_magenta.py --all           # Process all tier 1
    python fix_monster_magenta.py --ids 12 13 16 21  # Specific monsters
    python fix_monster_magenta.py --preview 12    # Show before/after comparison
"""

import argparse
import os
import sys
from pathlib import Path
from collections import deque
from typing import List, Tuple

try:
    from PIL import Image, ImageEnhance
    import numpy as np
except ImportError:
    print("pip install pillow numpy")
    sys.exit(1)

BASE_DIR = Path(__file__).parent
RAW_DIR = BASE_DIR / "monster_v2" / "raw"
TIER_DIR = BASE_DIR / "monster_v2" / "tier_1"
CORRECTED_DIR = BASE_DIR / "monster_v2" / "corrected"
TILE_SIZE = 64

# All tier 1 monster IDs
TIER_1_IDS = [11, 12, 13, 14, 16, 17, 18, 19, 20, 21, 22, 31]

# Monsters with known heavy magenta bleed (from user review)
HEAVY_BLEED = {12, 13, 16, 21}


def is_background_pixel(r, g, b):
    """Check if a pixel is part of the magenta background (strict)."""
    return (r > 150 and g < r * 0.55 and (r - g) > 70 and b > g * 0.8)


def get_magenta_influence(r, g, b):
    """
    Compute how much magenta contaminates this pixel (0.0 to 1.0).

    Magenta = both R and B elevated relative to G.
    Pure magenta: R=255, G=0, B=255 -> influence=1.0
    Natural brown: R=100, G=60, B=30 -> influence=0.0
    Pink-tinted brown: R=120, G=50, B=80 -> influence ~0.4
    """
    if g >= r or g >= b:
        return 0.0  # G dominates - no magenta

    # How much do R and B each exceed G?
    r_excess = (r - g) / max(r, 1)
    b_excess = (b - g) / max(b, 1)

    # Magenta influence = geometric mean of both excesses
    # Both need to be high for strong magenta
    influence = (r_excess * b_excess) ** 0.5

    # Additional check: if blue is close to or exceeds red,
    # that's more magenta-like (vs warm red which is natural)
    if b > r * 0.6:
        influence *= 1.3  # Boost detection for blue-heavy pink

    return min(influence, 1.0)


def correct_magenta_bleed(img: Image.Image, strength: float = 1.0) -> Image.Image:
    """
    Neutralize magenta tint in creature pixels.

    Strategy: For pixels with magenta influence, shift color toward
    natural tones by reducing the blue channel (the "blue" half of magenta)
    and slightly warming the red channel.

    Does NOT touch background pixels (those get removed separately).
    """
    arr = np.array(img).astype(np.float64)
    h, w = arr.shape[:2]
    has_alpha = arr.shape[2] == 4

    r = arr[:, :, 0]
    g = arr[:, :, 1]
    b = arr[:, :, 2]

    # Create masks
    # Background: strong magenta (leave alone - bg removal handles this)
    bg_mask = (r > 150) & (g < r * 0.55) & ((r - g) > 70) & (b > g * 0.8)

    # Creature pixels with magenta influence
    # Both R and B elevated relative to G
    r_excess = np.where(r > 0, (r - g) / np.maximum(r, 1), 0)
    b_excess = np.where(b > 0, (b - g) / np.maximum(b, 1), 0)

    # Magenta influence map
    mag_influence = np.sqrt(np.maximum(r_excess, 0) * np.maximum(b_excess, 0))

    # Boost where blue is close to red (more pink/magenta vs warm red)
    blue_ratio = np.where(r > 0, b / np.maximum(r, 1), 0)
    mag_influence = np.where(blue_ratio > 0.6, mag_influence * 1.3, mag_influence)
    mag_influence = np.clip(mag_influence, 0, 1)

    # Only correct creature pixels (not background)
    correction_mask = (~bg_mask) & (mag_influence > 0.15)

    # Compute correction amount per pixel
    correction = np.clip(mag_influence * strength * 1.2, 0, 0.85)

    # Apply correction only where mask is True
    # Strategy: push blue DOWN toward green (neutralizes the magenta)
    # Push red DOWN slightly (removes pinkish warmth toward natural)
    new_b = np.where(correction_mask,
                     g + (b - g) * (1 - correction * 0.8),  # Blue moves toward green
                     b)
    new_r = np.where(correction_mask,
                     g + (r - g) * (1 - correction * 0.3),  # Red gets slight reduction
                     r)
    # Green stays or gets tiny boost for more natural look
    new_g = np.where(correction_mask,
                     g * (1 + correction * 0.05),  # Tiny green boost
                     g)

    arr[:, :, 0] = np.clip(new_r, 0, 255)
    arr[:, :, 1] = np.clip(new_g, 0, 255)
    arr[:, :, 2] = np.clip(new_b, 0, 255)

    result = Image.fromarray(arr.astype(np.uint8), img.mode)

    # Count corrected pixels
    corrected_count = np.sum(correction_mask)
    total_creature = np.sum(~bg_mask)
    pct = (corrected_count / max(total_creature, 1)) * 100
    print(f"    Corrected {corrected_count:,} pixels ({pct:.1f}% of creature area)")

    return result


def bg_remove_3pass(img: Image.Image) -> Image.Image:
    """
    3-pass magenta background removal (proven from player sprites).

    Pass 1: Edge flood fill from all 4 borders
    Pass 2: Interior pink cleanup (catches enclosed pockets)
    Pass 3: Fringe cleanup (anti-aliasing bleed at edges)
    """
    arr = np.array(img.convert("RGBA"))
    h, w = arr.shape[:2]
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    removed = np.zeros((h, w), dtype=bool)

    # ---- PASS 1: Edge flood fill ----
    def is_seed(r, g, b):
        """Strict pink for initial seeds."""
        return r > 100 and g < r * 0.55 and (r - g) > 50

    def is_spread(r, g, b):
        """Broader pink for flood fill spread."""
        return r > 80 and g < r * 0.6 and b > g and (r - g) > 40

    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Seed from all 4 edges
    for x in range(w):
        for y in [0, h - 1]:
            if is_seed(r[y, x], g[y, x], b[y, x]):
                queue.append((y, x))
                visited[y, x] = True
    for y in range(h):
        for x in [0, w - 1]:
            if not visited[y, x] and is_seed(r[y, x], g[y, x], b[y, x]):
                queue.append((y, x))
                visited[y, x] = True

    # BFS flood fill
    while queue:
        cy, cx = queue.popleft()
        removed[cy, cx] = True
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1),
                       (-1, -1), (-1, 1), (1, -1), (1, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if is_spread(r[ny, nx], g[ny, nx], b[ny, nx]):
                    queue.append((ny, nx))

    pass1_count = np.sum(removed)

    # ---- PASS 2: Interior pink cleanup ----
    for y in range(h):
        for x in range(w):
            if not removed[y, x] and a[y, x] > 0:
                rv, gv, bv = int(r[y, x]), int(g[y, x]), int(b[y, x])
                if rv > 60 and gv < rv * 0.6 and bv > gv and (rv - gv) > 30:
                    removed[y, x] = True

    pass2_count = np.sum(removed) - pass1_count

    # ---- PASS 3: Fringe cleanup (2 iterations) ----
    pass3_count = 0
    for _ in range(2):
        fringe = np.zeros((h, w), dtype=bool)
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if removed[y, x] or a[y, x] == 0:
                    continue
                # Check if adjacent to a removed pixel
                has_removed_neighbor = False
                for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    if removed[y + dy, x + dx]:
                        has_removed_neighbor = True
                        break
                if has_removed_neighbor:
                    rv, gv, bv = int(r[y, x]), int(g[y, x]), int(b[y, x])
                    if rv > 40 and gv < rv * 0.55 and bv > gv * 1.1 and (rv - gv) > 15:
                        fringe[y, x] = True
        removed |= fringe
        pass3_count += np.sum(fringe)

    # Apply removal
    arr[removed, 3] = 0  # Set alpha to 0

    total_removed = np.sum(removed)
    total_pixels = h * w
    pct = (total_removed / total_pixels) * 100
    print(f"    BG removed: {total_removed:,}/{total_pixels:,} ({pct:.1f}%)")
    print(f"    Pass 1 (flood): {pass1_count:,} | Pass 2 (interior): {pass2_count:,} | Pass 3 (fringe): {pass3_count:,}")

    return Image.fromarray(arr)


def auto_crop_square(img: Image.Image) -> Image.Image:
    """Crop to content bounding box, then square it."""
    arr = np.array(img)
    if arr.shape[2] == 4:
        alpha = arr[:, :, 3]
        rows = np.any(alpha > 0, axis=1)
        cols = np.any(alpha > 0, axis=0)
    else:
        brightness = arr[:, :, :3].mean(axis=2)
        rows = brightness < 240
        cols = np.any(brightness < 240, axis=0)
        rows = np.any(brightness < 240, axis=1)

    if not np.any(rows) or not np.any(cols):
        return img

    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]

    # Add small padding
    pad = 4
    rmin = max(0, rmin - pad)
    rmax = min(arr.shape[0], rmax + pad + 1)
    cmin = max(0, cmin - pad)
    cmax = min(arr.shape[1], cmax + pad + 1)

    cropped = img.crop((cmin, rmin, cmax, rmax))
    w, h = cropped.size

    if w != h:
        max_dim = max(w, h)
        square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
        paste_x = (max_dim - w) // 2
        paste_y = (max_dim - h) // 2
        square.paste(cropped, (paste_x, paste_y))
        cropped = square

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


def process_monster(monster_id: int, strength: float = 1.0) -> bool:
    """Full pipeline for one monster: correct → bg remove → crop → resize → dark."""
    raw_path = RAW_DIR / f"monster_{monster_id}_1024.png"
    if not raw_path.exists():
        print(f"  SKIP: {raw_path.name} not found")
        return False

    print(f"\n  Processing monster_{monster_id}...")
    img = Image.open(raw_path).convert("RGBA")
    print(f"    Raw: {img.size}")

    # Step 1: Correct magenta bleed in creature body
    print(f"    Step 1: Magenta bleed correction (strength={strength:.1f})...")
    corrected = correct_magenta_bleed(img, strength=strength)

    # Save corrected raw for inspection
    CORRECTED_DIR.mkdir(parents=True, exist_ok=True)
    corrected_path = CORRECTED_DIR / f"monster_{monster_id}_corrected.png"
    corrected.save(corrected_path)

    # Step 2: Background removal
    print(f"    Step 2: 3-pass BG removal...")
    transparent = bg_remove_3pass(corrected)

    # Step 3: Auto-crop and square
    print(f"    Step 3: Auto-crop...")
    cropped = auto_crop_square(transparent)
    cw, ch = cropped.size
    print(f"    Cropped: {cw}x{ch}")

    # Step 4: Resize to 64x64
    img_64 = cropped.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.NEAREST)

    # Step 5: Save light variant
    TIER_DIR.mkdir(parents=True, exist_ok=True)
    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    img_64.save(light_path)
    print(f"    Saved: {light_path.name}")

    # Step 6: Dark variant
    dark = generate_dark_variant(img_64)
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    dark.save(dark_path)
    print(f"    Saved: {dark_path.name}")

    return True


def save_comparison(monster_ids: List[int]):
    """Save a before/after comparison image."""
    from PIL import ImageDraw

    n = len(monster_ids)
    tile = TILE_SIZE
    scale = 3
    margin = 4
    label_h = 16

    cols = min(n, 6)
    rows_count = (n + cols - 1) // cols

    out_w = (tile * scale * 2 + margin * 2) * cols + margin
    out_h = (tile * scale + label_h + margin) * rows_count + label_h * 2

    out = Image.new("RGBA", (out_w, out_h), (40, 40, 40, 255))
    draw = ImageDraw.Draw(out)
    draw.text((margin, 2), "Before (left) vs After (right) - Magenta Bleed Fix", fill=(255, 255, 255))

    # Load originals from raw (re-resize without correction for comparison)
    for i, mid in enumerate(monster_ids):
        r = i // cols
        c = i % cols
        x_base = margin + c * (tile * scale * 2 + margin * 2)
        y_base = label_h * 2 + r * (tile * scale + label_h + margin)

        # Before: original light (from initial generation)
        orig_path = TIER_DIR / f"monster_{mid}_light.png"
        if orig_path.exists():
            before = Image.open(orig_path).convert("RGBA")
            before_scaled = before.resize((tile * scale, tile * scale), Image.Resampling.NEAREST)
            out.paste(before_scaled, (x_base, y_base), before_scaled)

        draw.text((x_base, y_base + tile * scale), f"m_{mid}", fill=(180, 180, 180))

    comp_path = CORRECTED_DIR / "comparison.png"
    CORRECTED_DIR.mkdir(parents=True, exist_ok=True)
    out.save(comp_path)
    print(f"\nComparison saved: {comp_path}")


def main():
    parser = argparse.ArgumentParser(description="Fix magenta bleed in monster sprites")
    parser.add_argument("--all", action="store_true", help="Process all tier 1 monsters")
    parser.add_argument("--ids", nargs="+", type=int, help="Process specific monster IDs")
    parser.add_argument("--heavy-only", action="store_true", help="Only process heavily affected (12,13,16,21)")
    parser.add_argument("--strength", type=float, default=1.0, help="Correction strength (0.5=mild, 1.0=normal, 1.5=aggressive)")
    parser.add_argument("--preview", type=int, help="Show before/after for a single monster")
    args = parser.parse_args()

    if args.ids:
        monster_ids = args.ids
    elif args.heavy_only:
        monster_ids = sorted(HEAVY_BLEED)
    elif args.all:
        monster_ids = TIER_1_IDS
    elif args.preview:
        monster_ids = [args.preview]
    else:
        parser.print_help()
        return

    print(f"{'=' * 60}")
    print(f"MAGENTA BLEED FIX - {len(monster_ids)} monsters")
    print(f"Strength: {args.strength} | Output: {TIER_DIR}")
    print(f"{'=' * 60}")

    succeeded = 0
    failed = 0
    for mid in monster_ids:
        # Use higher strength for known heavy-bleed monsters
        s = args.strength
        if mid in HEAVY_BLEED:
            s = max(s, 1.2)
            print(f"\n  [HEAVY BLEED] monster_{mid} - using strength {s:.1f}")

        if process_monster(mid, strength=s):
            succeeded += 1
        else:
            failed += 1

    print(f"\n{'=' * 60}")
    print(f"COMPLETE: {succeeded} succeeded, {failed} failed")
    print(f"Light sprites: {TIER_DIR}/")
    print(f"Corrected raws: {CORRECTED_DIR}/")


if __name__ == "__main__":
    main()
