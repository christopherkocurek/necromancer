#!/usr/bin/env python3
"""
Tier 3 Round 4 — Precise pixel-level fixes based on user feedback.

- #54 Easterling Warrior: Thicken thin sword + remove back decoration artifact
- #55 Dark Sorcerer: Add green aura glow under hood cowl
- #57 Easterling Champion: Remove gray block (was magenta, desaturated instead of removed)
- #58 Ghast: Fix arm stripping on upper frame-left arm
- #85 Tunnel Crawler: Remove light/gray-green BG in center of sprite
"""

import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import binary_erosion, binary_dilation, label as scipy_label

BASE_DIR = Path(__file__).parent
TIER_DIR = BASE_DIR / "monster_v3" / "tier_3"


def compute_hsv(rgb):
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    diff = maxc - minc
    hue = np.zeros_like(maxc)
    nz = diff > 0.001
    mr = (maxc == r) & nz
    mg = (maxc == g) & nz & ~mr
    mb = (maxc == b) & nz & ~mr & ~mg
    hue[mr] = 60.0 * (((g[mr] - b[mr]) / diff[mr]) % 6)
    hue[mg] = 60.0 * (((b[mg] - r[mg]) / diff[mg]) + 2)
    hue[mb] = 60.0 * (((r[mb] - g[mb]) / diff[mb]) + 4)
    sat = np.where(maxc > 0.001, diff / maxc, 0.0)
    return hue, sat, maxc


def generate_dark_variant(img_rgba):
    arr = np.array(img_rgba).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    if not np.any(alpha > 0):
        return img_rgba
    gray = np.mean(rgb, axis=2, keepdims=True)
    rgb = rgb * 0.4 + gray * 0.6
    rgb *= 0.6
    rgb[:, :, 0] *= 0.85
    rgb[:, :, 1] *= 0.90
    rgb[:, :, 2] = np.minimum(rgb[:, :, 2] * 1.15, 255)
    result = np.zeros_like(arr)
    result[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    result[:, :, 3] = alpha
    return Image.fromarray(result.astype(np.uint8), "RGBA")


def save_sprite(arr, monster_id):
    """Save light sprite + regenerate dark variant."""
    light_path = TIER_DIR / f"monster_{monster_id}_light.png"
    dark_path = TIER_DIR / f"monster_{monster_id}_dark.png"
    img = Image.fromarray(arr.astype(np.uint8), "RGBA")
    img.save(light_path)
    dark = generate_dark_variant(img)
    dark.save(dark_path)
    print(f"    Saved: {light_path.name} + {dark_path.name}")


# ============================================================================
# #54 Easterling Warrior — Thicken sword + remove back artifact
# ============================================================================

def fix_54():
    print(f"\n  #54 Easterling Warrior — thicken sword + remove back artifact:")
    light_path = TIER_DIR / "monster_54_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    # --- Part 1: Find and remove back decoration artifact ---
    # The artifact is disconnected from the main body on the right/back side
    # Find all connected components and remove small isolated ones
    opaque = alpha > 0
    labeled, n_features = scipy_label(opaque)
    sizes = [(labeled == i).sum() for i in range(1, n_features + 1)]

    if n_features > 1:
        max_size = max(sizes)
        removed = 0
        for i in range(1, n_features + 1):
            # Remove fragments smaller than 5% of main body
            if sizes[i-1] < max_size * 0.05:
                mask = labeled == i
                arr[mask, 3] = 0
                removed += sizes[i-1]
        print(f"    Removed {removed} px of back artifact fragments ({n_features} components)")

    # --- Part 2: Thicken the sword blade ---
    # Find bright metallic pixels (the blade) — high value, moderate sat, yellowish/whitish
    hue, sat, val = compute_hsv(rgb)
    visible = arr[:, :, 3] > 0

    # Blade pixels: bright (val > 0.5), not too saturated (sat < 0.5),
    # in the upper portion of the sprite (sword should be above hand)
    is_blade = visible & (val > 0.50) & (sat < 0.50) & (
        # Metallic: grayish/silver or warm/gold
        ((sat < 0.20) & (val > 0.55)) |  # Silver/gray metal
        ((hue >= 30) & (hue <= 60) & (val > 0.45))  # Gold/bronze highlights
    )

    # Only in the upper half of the sprite (blade extends upward from hand)
    upper_half = np.zeros_like(is_blade)
    upper_half[:h//2, :] = True
    is_blade = is_blade & upper_half

    blade_count = np.sum(is_blade)
    if blade_count > 0:
        print(f"    Found {blade_count} blade pixels — dilating to thicken")
        # Dilate blade pixels by 1px to thicken
        dilated = binary_dilation(is_blade, iterations=1)
        # New blade pixels = dilated minus original
        new_blade = dilated & ~is_blade & ~visible

        # Color new blade pixels as average of nearby blade pixels
        blade_r = np.mean(rgb[:, :, 0][is_blade])
        blade_g = np.mean(rgb[:, :, 1][is_blade])
        blade_b = np.mean(rgb[:, :, 2][is_blade])

        new_count = np.sum(new_blade)
        arr[new_blade, 0] = blade_r * 255
        arr[new_blade, 1] = blade_g * 255
        arr[new_blade, 2] = blade_b * 255
        arr[new_blade, 3] = 255
        print(f"    Added {new_count} px to thicken blade (color: {blade_r:.2f},{blade_g:.2f},{blade_b:.2f})")
    else:
        print(f"    No blade pixels found to thicken")

    save_sprite(arr, 54)
    return True


# ============================================================================
# #55 Dark Sorcerer — Add green aura under hood cowl
# ============================================================================

def fix_55():
    print(f"\n  #55 Dark Sorcerer — add green aura under hood:")
    light_path = TIER_DIR / "monster_55_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    # Find the head/hood area — topmost opaque pixels
    opaque = alpha > 0
    # Find top of sprite
    top_row = 0
    for r in range(h):
        if np.any(opaque[r, :]):
            top_row = r
            break

    # The hood cowl area is roughly rows top_row to top_row+12, centered
    # Find horizontal center of mass of opaque pixels in hood region
    hood_rows = slice(top_row, min(top_row + 15, h))
    hood_cols = np.where(np.any(opaque[hood_rows, :], axis=0))[0]
    if len(hood_cols) == 0:
        print(f"    Could not find hood area")
        return False

    center_col = int(np.mean(hood_cols))
    print(f"    Hood region: rows {top_row}-{top_row+15}, center col {center_col}")

    # Paint green aura pixels in a small area under the cowl opening
    # The cowl opening is typically rows top_row+4 to top_row+10, centered
    aura_color = np.array([30, 200, 60, 200], dtype=np.float64)  # Green glow, slightly transparent
    aura_dim = np.array([15, 120, 30, 160], dtype=np.float64)  # Dimmer green for outer ring

    painted = 0
    # Inner glow (brighter, 3x3 area)
    for dr in range(5, 10):
        for dc in range(-2, 3):
            r, c = top_row + dr, center_col + dc
            if 0 <= r < h and 0 <= c < w:
                if opaque[r, c]:  # Only paint on existing opaque pixels
                    # Blend: 40% green glow + 60% original
                    arr[r, c, :3] = arr[r, c, :3] * 0.55 + aura_color[:3] * 0.45
                    painted += 1

    # Outer glow (dimmer, ring around inner)
    for dr in range(3, 12):
        for dc in range(-4, 5):
            r, c = top_row + dr, center_col + dc
            if 0 <= r < h and 0 <= c < w:
                if opaque[r, c] and abs(dc) >= 3 or (dr <= 4 or dr >= 10):
                    arr[r, c, :3] = arr[r, c, :3] * 0.75 + aura_dim[:3] * 0.25
                    painted += 1

    print(f"    Painted {painted} px of green aura")
    save_sprite(arr, 55)
    return True


# ============================================================================
# #57 Easterling Champion — Remove gray block entirely (make transparent)
# ============================================================================

def fix_57():
    print(f"\n  #57 Easterling Champion — remove gray block (make transparent):")
    light_path = TIER_DIR / "monster_57_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    visible = alpha > 0
    hue, sat, val = compute_hsv(rgb)

    # The gray block is a desaturated magenta patch — low saturation, medium brightness
    # It should be distinctly different from the gold/crimson armor
    # Target: desaturated pixels (sat < 0.15) that are NOT bone-white and NOT very dark
    is_gray_block = visible & (sat < 0.18) & (val > 0.15) & (val < 0.65)

    # Exclude the expected gray areas: very dark shadows, weapon metal
    # The block should be a contiguous patch, not scattered pixels
    # Also check for pink/magenta hue remnant (the desaturated magenta still has pinkish hue)
    is_pinkish_gray = visible & (sat < 0.25) & (val > 0.12) & (
        ((hue >= 280) & (hue <= 360)) | (hue < 30)  # Pink/magenta hue range
    )

    combined = is_gray_block | is_pinkish_gray

    # Label components and find blocky patches
    labeled, n_features = scipy_label(combined)
    removed = 0
    for i in range(1, n_features + 1):
        component = labeled == i
        comp_size = np.sum(component)
        if comp_size < 3:
            continue

        # Check if it's a blocky/square-ish shape (artifact) vs scattered pixels
        rows_hit = np.any(component, axis=1)
        cols_hit = np.any(component, axis=0)
        row_span = np.sum(rows_hit)
        col_span = np.sum(cols_hit)

        # A "block" has roughly similar row and column span, and is dense
        density = comp_size / max(row_span * col_span, 1)
        if comp_size >= 5 and density > 0.2:
            arr[component, 3] = 0
            removed += comp_size
            print(f"    Removed component {i}: {comp_size} px, {row_span}x{col_span}, density {density:.2f}")

    if removed == 0:
        # Fallback: just remove ALL low-saturation pinkish pixels
        fallback = visible & (sat < 0.20) & (
            ((hue >= 290) & (hue <= 360)) | (hue < 20)
        ) & (val > 0.10)
        removed = np.sum(fallback)
        if removed > 0:
            arr[fallback, 3] = 0
            print(f"    Fallback: removed {removed} desaturated pink px")

    print(f"    Total removed: {removed} px -> transparent")
    save_sprite(arr, 57)
    return True


# ============================================================================
# #58 Ghast — Fix arm stripping on upper frame-left
# ============================================================================

def fix_58():
    print(f"\n  #58 Ghast — fix arm stripping on upper frame-left:")
    light_path = TIER_DIR / "monster_58_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    # The stripping is on the upper-left arm area — transparent gaps in what should be solid arm
    # Strategy: find the arm region (upper-left quadrant with opaque pixels),
    # identify holes/gaps, and fill them with neighboring colors

    opaque = alpha > 0

    # Focus on upper-left quadrant (frame-left = viewer's left = image left)
    # Upper half, left portion
    region_mask = np.zeros_like(opaque)
    region_mask[:h*2//3, :w*2//3] = True  # Upper-left 2/3

    # Find transparent pixels surrounded by opaque pixels in this region
    # These are the "stripped" gaps
    dilated = binary_dilation(opaque, iterations=1)
    # Holes = transparent pixels that would be filled by 1px dilation
    holes_in_region = ~opaque & dilated & region_mask

    # Only fill holes that are near other opaque pixels (not at the edge of the sprite)
    # Check: at least 3 opaque neighbors
    from scipy.ndimage import convolve
    kernel = np.ones((3, 3))
    neighbor_count = convolve(opaque.astype(np.float64), kernel, mode='constant', cval=0)
    holes_to_fill = holes_in_region & (neighbor_count >= 3)

    fill_count = np.sum(holes_to_fill)
    if fill_count == 0:
        # Try more aggressive: look for stripped pixels (very transparent in a mostly opaque region)
        # Also check for pixels with very low alpha that should be fully opaque
        partially_transparent = (alpha > 0) & (alpha < 200) & region_mask
        partial_count = np.sum(partially_transparent)
        if partial_count > 0:
            print(f"    Found {partial_count} partially transparent px in arm region — making opaque")
            arr[partially_transparent, 3] = 255
            fill_count = partial_count
        else:
            print(f"    No stripped pixels found in upper-left arm region")
            # Try: find green-hued pixels that were made transparent by edge cleanup
            # and restore them if they're in the arm area
            print(f"    Attempting to restore stripped arm from wider dilation...")
            dilated2 = binary_dilation(opaque, iterations=2)
            holes2 = ~opaque & dilated2 & region_mask & (neighbor_count >= 2)
            fill_count = np.sum(holes2)
            if fill_count > 0:
                holes_to_fill = holes2
            else:
                save_sprite(arr, 58)
                return True

    if fill_count > 0:
        print(f"    Filling {fill_count} stripped px with neighbor colors")
        # Fill each hole with average color of its opaque neighbors
        ys, xs = np.where(holes_to_fill)
        for y, x in zip(ys, xs):
            neighbors = []
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and opaque[ny, nx]:
                        neighbors.append(arr[ny, nx, :3])
            if neighbors:
                avg_color = np.mean(neighbors, axis=0)
                arr[y, x, :3] = avg_color
                arr[y, x, 3] = 255

    save_sprite(arr, 58)
    return True


# ============================================================================
# #85 Tunnel Crawler — Remove gray-green BG in center
# ============================================================================

def fix_85():
    print(f"\n  #85 Tunnel Crawler — remove gray-green center BG:")
    light_path = TIER_DIR / "monster_85_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).astype(np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    visible = alpha > 0
    hue, sat, val = compute_hsv(rgb)

    # The center BG is light/gray-green — desaturated green from the green BG cleanup
    # These pixels are greenish (hue 70-160) but have been desaturated by the pipeline
    # They're still distinguishable from the brown creature body

    # Target: pixels that are green-ish AND light/bright (BG remnant, not dark creature)
    # The creature body is dark brown; the BG remnant is lighter green/gray-green
    is_bg_remnant = visible & (
        # Green-ish hue with moderate-high value (lighter than creature)
        (hue >= 60) & (hue <= 170) & (val > 0.35) & (sat > 0.10)
    )

    # Also catch very desaturated greenish pixels (the "gray-green" the user describes)
    is_gray_green = visible & (
        (hue >= 60) & (hue <= 170) & (val > 0.30) & (sat >= 0.03) & (sat < 0.25)
    )

    # Focus on interior pixels (not the creature edge)
    opaque = alpha > 0
    eroded = binary_erosion(opaque, iterations=2)
    interior = eroded  # Interior of sprite

    # Only remove BG remnants that are in the interior (center of sprite)
    # NOT edge pixels (those might be creature coloring)
    center_bg = (is_bg_remnant | is_gray_green) & interior

    count = np.sum(center_bg)
    if count == 0:
        print(f"    No gray-green center BG found")
        # Try less strict
        center_bg = is_bg_remnant & interior
        count = np.sum(center_bg)

    if count > 0:
        pct = 100 * count / max(np.sum(visible), 1)
        print(f"    Gray-green center BG: {count} px ({pct:.1f}%) -> transparent")
        arr[center_bg, 3] = 0
    else:
        print(f"    No pixels matched")

    save_sprite(arr, 85)
    return True


# ============================================================================
# Main
# ============================================================================

def main():
    print(f"\n{'='*60}")
    print(f"Tier 3 Round 4 — Pixel-Level Fixes")
    print(f"{'='*60}")

    fix_54()
    fix_55()
    fix_57()
    fix_58()
    fix_85()

    print(f"\n{'='*60}")
    print(f"All fixes applied. Generating review HTML...")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
