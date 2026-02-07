#!/usr/bin/env python3
"""
Final cleanup for Man race sprites:
1. Gondor Male (h5): green floor remnant at bottom of frame
2. Gondor Female (h5): re-process from raw with conservative removal to preserve banner
3. Rohan Male (h4): background remnant in bottom-left corner of 64x64
"""
import numpy as np
from PIL import Image, ImageEnhance
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent))
from player_gen import generate_dark_variant

BASE = Path(__file__).parent / "player_v2"
RAW = BASE / "raw"
MAN = BASE / "man"


def analyze_pixels(img, label=""):
    """Print pixel stats for debugging."""
    arr = np.array(img)
    if arr.shape[2] == 4:
        a = arr[:,:,3]
        transparent = np.sum(a == 0)
        total = a.shape[0] * a.shape[1]
        print(f"  {label}: {img.size[0]}x{img.size[1]}, transparent={transparent}/{total} ({transparent/total*100:.1f}%)")


def remove_bg_conservative(img: Image.Image) -> Image.Image:
    """
    More conservative background removal that preserves light-colored character elements.
    Only removes pixels that are strongly pink/magenta AND connected to edges.
    Does NOT do interior pink cleanup (to preserve banners/flags).
    """
    arr = np.array(img.convert("RGBA")).copy()
    h, w = arr.shape[:2]
    r, g, b = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int)
    a = arr[:,:,3]

    def is_pink_strict(ri, gi, bi):
        """Strict pink: high red, low green, blue > green. Won't match white/gray banners."""
        return (ri > 120 and gi < ri * 0.5 and bi > gi * 0.8 and (ri - gi) > 60)

    def is_pink_neighbor(ri, gi, bi):
        """Neighbor spread: still strict enough to avoid banner colors."""
        return (ri > 100 and gi < ri * 0.55 and bi > gi * 0.7 and (ri - gi) > 45)

    removed = np.zeros((h, w), dtype=bool)
    queue = []

    # Seed from edges - strict pink only
    for y in range(h):
        for x in [0, 1, w-2, w-1]:
            if a[y, x] > 0 and is_pink_strict(r[y,x], g[y,x], b[y,x]):
                queue.append((y, x))
                removed[y, x] = True
    for x in range(w):
        for y in [0, 1, h-2, h-1]:
            if not removed[y, x] and a[y, x] > 0 and is_pink_strict(r[y,x], g[y,x], b[y,x]):
                queue.append((y, x))
                removed[y, x] = True

    # BFS - moderate spread
    while queue:
        cy, cx = queue.pop(0)
        for dy in [-1, 0, 1]:
            for dx in [-1, 0, 1]:
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and not removed[ny, nx]:
                    if a[ny, nx] > 0 and is_pink_neighbor(r[ny,nx], g[ny,nx], b[ny,nx]):
                        removed[ny, nx] = True
                        queue.append((ny, nx))

    print(f"  Conservative removal: {np.sum(removed)} pixels")

    # Light fringe cleanup - 1 pass only, strict
    fringe = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            if not removed[y, x] and a[y, x] > 0:
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
                    # Only remove fringe that's clearly pinkish
                    if ri > 80 and gi < ri * 0.5 and bi > gi and (ri - gi) > 35:
                        fringe[y, x] = True
    removed |= fringe
    print(f"  Fringe: {np.sum(fringe)} pixels")

    arr[removed, 3] = 0
    total_removed = np.sum(removed)
    print(f"  Total: {total_removed}/{h*w} ({total_removed/(h*w)*100:.1f}%)")

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

    pad = 4
    y0 = max(0, y0 - pad)
    y1 = min(arr.shape[0], y1 + pad)
    x0 = max(0, x0 - pad)
    x1 = min(arr.shape[1], x1 + pad)

    cropped = img.crop((x0, y0, x1, y1))
    cw, ch = cropped.size

    if cw != ch:
        max_dim = max(cw, ch)
        square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
        square.paste(cropped, ((max_dim - cw) // 2, (max_dim - ch) // 2))
        cropped = square

    return cropped.resize((target_size, target_size), Image.Resampling.NEAREST)


def fix_gondor_male():
    """Fix green floor remnant at bottom of Gondor male."""
    print("\n" + "="*60)
    print("FIX 1: Gondor Male - green floor at bottom")
    print("="*60)

    nobg_path = RAW / "player_man_h5_male_1024_nobg.png"
    raw_path = RAW / "player_man_h5_male_1024.png"

    # Work from the nobg file
    img = Image.open(nobg_path).convert("RGBA")
    arr = np.array(img).copy()
    h, w = arr.shape[:2]
    r, g, b, a = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int), arr[:,:,3]

    # The green floor is at the bottom. Scan bottom 25% for non-character pixels.
    # Green floor: green channel dominant or dark greenish tones
    bottom_start = int(h * 0.75)
    removed = 0

    # Flood fill from bottom edge for green/dark floor pixels
    floor_mask = np.zeros((h, w), dtype=bool)
    queue = []

    # Seed: bottom row pixels that are opaque and greenish/dark
    for x in range(w):
        y = h - 1
        if a[y, x] > 0:
            ri, gi, bi = r[y,x], g[y,x], b[y,x]
            # Green floor: green is dominant, or very dark, or teal-ish
            is_floor = (gi > ri and gi > 40) or (ri < 60 and gi < 60 and bi < 60) or (gi > 50 and bi > gi * 0.7 and ri < gi)
            if is_floor:
                floor_mask[y, x] = True
                queue.append((y, x))

    # BFS upward but only in bottom region
    while queue:
        cy, cx = queue.pop(0)
        for dy in [-1, 0, 1]:
            for dx in [-1, 0, 1]:
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and ny >= bottom_start and not floor_mask[ny, nx]:
                    if a[ny, nx] > 0:
                        ri, gi, bi = r[ny,nx], g[ny,nx], b[ny,nx]
                        is_floor = (gi > ri and gi > 40) or (ri < 60 and gi < 60 and bi < 60) or (gi > 50 and bi > gi * 0.7 and ri < gi)
                        if is_floor:
                            floor_mask[ny, nx] = True
                            queue.append((ny, nx))

    removed = np.sum(floor_mask)
    print(f"  Green floor pixels found: {removed}")

    # Also catch any remaining magenta in bottom area
    pink_bottom = 0
    for y in range(bottom_start, h):
        for x in range(w):
            if a[y, x] > 0 and not floor_mask[y, x]:
                ri, gi, bi = r[y,x], g[y,x], b[y,x]
                if ri > 80 and gi < ri * 0.6 and bi > gi and (ri - gi) > 30:
                    floor_mask[y, x] = True
                    pink_bottom += 1
    print(f"  Pink remnants in bottom: {pink_bottom}")

    arr[floor_mask, 3] = 0
    result = Image.fromarray(arr, "RGBA")
    result.save(nobg_path)
    analyze_pixels(result, "1024 nobg")

    # Re-crop and resize
    img_64 = auto_crop_square(result, 64)
    light_path = MAN / "player_man_h5_male_light.png"
    img_64.save(light_path)
    analyze_pixels(img_64, "64x64 light")

    dark = generate_dark_variant(img_64)
    dark_path = MAN / "player_man_h5_male_dark.png"
    dark.save(dark_path)
    print(f"  Saved: {light_path.name}, {dark_path.name}")


def fix_gondor_female():
    """Re-process Gondor female with conservative bg removal to preserve banner."""
    print("\n" + "="*60)
    print("FIX 2: Gondor Female - preserve banner, conservative removal")
    print("="*60)

    raw_path = RAW / "player_man_h5_female_1024.png"
    nobg_path = RAW / "player_man_h5_female_1024_nobg.png"

    img = Image.open(raw_path).convert("RGBA")
    print(f"  Raw: {img.size}")

    # Conservative removal - only strongly pink pixels connected to edges
    result = remove_bg_conservative(img)
    result.save(nobg_path)
    analyze_pixels(result, "1024 nobg (conservative)")

    # Crop and resize
    img_64 = auto_crop_square(result, 64)
    light_path = MAN / "player_man_h5_female_light.png"
    img_64.save(light_path)
    analyze_pixels(img_64, "64x64 light")

    dark = generate_dark_variant(img_64)
    dark_path = MAN / "player_man_h5_female_dark.png"
    dark.save(dark_path)
    print(f"  Saved: {light_path.name}, {dark_path.name}")


def fix_rohan_male():
    """Clean up bottom-left corner of Rohan male 64x64."""
    print("\n" + "="*60)
    print("FIX 3: Rohan Male - bottom-left corner artifact")
    print("="*60)

    light_path = MAN / "player_man_h4_male_light.png"
    img = Image.open(light_path).convert("RGBA")
    arr = np.array(img).copy()
    h, w = arr.shape[:2]
    r, g, b, a = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int), arr[:,:,3]

    # Scan bottom-left quadrant for non-character pixels
    # Also try from the 1024 nobg and re-process
    nobg_path = RAW / "player_man_h4_male_1024_nobg.png"
    if nobg_path.exists():
        print("  Working from 1024 nobg...")
        img_1024 = Image.open(nobg_path).convert("RGBA")
        arr_1024 = np.array(img_1024).copy()
        h1, w1 = arr_1024.shape[:2]
        r1, g1, b1, a1 = arr_1024[:,:,0].astype(int), arr_1024[:,:,1].astype(int), arr_1024[:,:,2].astype(int), arr_1024[:,:,3]

        # Flood fill from bottom-left corner for any non-transparent artifact
        cleaned = np.zeros((h1, w1), dtype=bool)
        queue = []

        # Seed from bottom-left area (bottom 15%, left 15%)
        bl_h = int(h1 * 0.85)
        bl_w = int(w1 * 0.15)
        for y in range(bl_h, h1):
            for x in range(0, bl_w):
                if a1[y, x] > 0:
                    ri, gi, bi = r1[y,x], g1[y,x], b1[y,x]
                    # Any dark or pinkish pixel in this corner is artifact
                    is_artifact = (ri < 80 and gi < 80 and bi < 80) or \
                                  (ri > 60 and gi < ri * 0.6 and bi > gi) or \
                                  (gi > ri and ri < 100)  # greenish
                    if is_artifact:
                        cleaned[y, x] = True
                        queue.append((y, x))

        # BFS spread within bottom-left region
        while queue:
            cy, cx = queue.pop(0)
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h1 and 0 <= nx < w1 and not cleaned[ny, nx]:
                        if ny >= int(h1 * 0.7) and nx <= int(w1 * 0.3):  # Stay in corner region
                            if a1[ny, nx] > 0:
                                ri, gi, bi = r1[ny,nx], g1[ny,nx], b1[ny,nx]
                                is_artifact = (ri < 80 and gi < 80 and bi < 80) or \
                                              (ri > 60 and gi < ri * 0.6 and bi > gi) or \
                                              (gi > ri and ri < 100)
                                if is_artifact:
                                    cleaned[ny, nx] = True
                                    queue.append((ny, nx))

        count = np.sum(cleaned)
        print(f"  Bottom-left artifacts: {count} pixels")
        arr_1024[cleaned, 3] = 0
        result_1024 = Image.fromarray(arr_1024, "RGBA")
        result_1024.save(nobg_path)

        # Re-crop and resize
        img_64 = auto_crop_square(result_1024, 64)
    else:
        # Fix at 64x64 level directly
        print("  No 1024 nobg found, fixing 64x64 directly...")
        # Bottom-left corner: bottom 30%, left 30%
        for y in range(int(h * 0.7), h):
            for x in range(0, int(w * 0.3)):
                if a[y, x] > 0:
                    ri, gi, bi = r[y,x], g[y,x], b[y,x]
                    # Dark or pinkish artifacts
                    if (ri < 60 and gi < 60 and bi < 60) or \
                       (ri > 60 and gi < ri * 0.6 and bi > gi):
                        arr[y, x, 3] = 0
        img_64 = Image.fromarray(arr, "RGBA")

    light_path.unlink(missing_ok=True)
    img_64.save(light_path)
    analyze_pixels(img_64, "64x64 light")

    dark = generate_dark_variant(img_64)
    dark_path = MAN / "player_man_h4_male_dark.png"
    dark.save(dark_path)
    print(f"  Saved: {light_path.name}, {dark_path.name}")


if __name__ == "__main__":
    fix_gondor_male()
    fix_gondor_female()
    fix_rohan_male()
    print("\n" + "="*60)
    print("ALL FIXES COMPLETE")
    print("="*60)
