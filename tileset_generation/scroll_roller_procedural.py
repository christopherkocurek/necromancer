#!/usr/bin/env python3
"""
Procedural scroll roller generator.
Creates a dark wood cylinder with ornate bronze end caps.
Zero API cost, fully deterministic.
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
    import numpy as np
except ImportError:
    print("Required: pip install pillow numpy")
    sys.exit(1)

OUTPUT_DIR = Path(__file__).parent.parent / "assets" / "ui" / "tome"

# Roller dimensions
WIDTH = 100
HEIGHT = 756
CAP_HEIGHT = 60       # Height of each end cap
BAND_HEIGHT = 8       # Metal reinforcement bands
SHAFT_WIDTH = 60      # Width of the wooden shaft
CAP_WIDTH = 80        # Width of the end caps (wider than shaft)


def make_cylinder_gradient(w: int, center_x: int, radius: int) -> np.ndarray:
    """Create a 1D horizontal gradient simulating a cylinder's shading."""
    x = np.arange(w, dtype=np.float32)
    # Normalized distance from center (-1 to +1)
    d = (x - center_x) / radius
    d = np.clip(d, -1.0, 1.0)
    # Cylinder shading: bright at 30% from left (light source), dark at edges
    light_pos = -0.3  # Light from left
    shade = 1.0 - 0.7 * (d - light_pos) ** 2
    shade = np.clip(shade, 0.2, 1.0)
    # Add specular highlight
    spec_pos = -0.25
    spec = np.exp(-((d - spec_pos) ** 2) / 0.02) * 0.3
    shade += spec
    return np.clip(shade, 0.0, 1.0)


def draw_wood_shaft(arr: np.ndarray, y_start: int, y_end: int, cx: int, radius: int):
    """Draw the wooden shaft portion of the roller."""
    gradient = make_cylinder_gradient(WIDTH, cx, radius)

    # Base wood color: dark walnut
    base_r, base_g, base_b = 95, 55, 30

    for y in range(y_start, y_end):
        # Add vertical grain variation
        grain = np.sin(y * 0.15) * 8 + np.sin(y * 0.37) * 4 + np.sin(y * 0.03) * 12
        for x in range(WIDTH):
            if abs(x - cx) > radius:
                continue
            shade = gradient[x]
            # Wood grain: subtle horizontal variation
            grain_x = np.sin(x * 0.2 + y * 0.01) * 5
            r = int(np.clip((base_r + grain + grain_x) * shade, 0, 255))
            g = int(np.clip((base_g + grain * 0.6 + grain_x * 0.5) * shade, 0, 255))
            b = int(np.clip((base_b + grain * 0.3) * shade, 0, 255))
            arr[y, x] = [r, g, b, 255]


def draw_metal_band(arr: np.ndarray, y_center: int, height: int, cx: int, radius: int):
    """Draw a bronze metal reinforcement band."""
    gradient = make_cylinder_gradient(WIDTH, cx, radius + 2)

    # Bronze color
    base_r, base_g, base_b = 165, 120, 55

    y_start = max(0, y_center - height // 2)
    y_end = min(HEIGHT, y_center + height // 2)

    for y in range(y_start, y_end):
        for x in range(WIDTH):
            if abs(x - cx) > radius + 2:
                continue
            shade = gradient[x]
            # Add slight engraving pattern
            engrave = 1.0 + np.sin(x * 0.8) * 0.05 + np.sin(y * 1.5) * 0.03
            r = int(np.clip(base_r * shade * engrave, 0, 255))
            g = int(np.clip(base_g * shade * engrave, 0, 255))
            b = int(np.clip(base_b * shade * engrave, 0, 255))
            arr[y, x] = [r, g, b, 255]


def draw_end_cap(arr: np.ndarray, y_start: int, y_end: int, cx: int, cap_radius: int, is_top: bool):
    """Draw an ornate bronze end cap with Celtic knotwork suggestion."""
    gradient = make_cylinder_gradient(WIDTH, cx, cap_radius)

    for y in range(y_start, y_end):
        # Taper: caps are wider in the middle, narrower at extremes
        progress = (y - y_start) / max(1, y_end - y_start)
        if is_top:
            progress = 1.0 - progress  # Reverse for top cap
        # Bell curve taper
        taper = 0.7 + 0.3 * np.sin(progress * np.pi)
        effective_radius = int(cap_radius * taper)

        for x in range(WIDTH):
            if abs(x - cx) > effective_radius:
                continue

            shade = gradient[x]

            # Ornate pattern: concentric rings + knot suggestion
            dist_from_edge = effective_radius - abs(x - cx)
            ring_pattern = np.sin(progress * 12) * 0.08
            edge_detail = np.sin(dist_from_edge * 0.5) * 0.06

            # Base bronze with patina
            base_r = 155 + int(ring_pattern * 40 + edge_detail * 30)
            base_g = 110 + int(ring_pattern * 30 + edge_detail * 20)
            base_b = 45 + int(ring_pattern * 15 + edge_detail * 10)

            # Darkened patina in recesses
            patina = 1.0 + np.sin(y * 0.3 + x * 0.2) * 0.1

            r = int(np.clip(base_r * shade * patina, 0, 255))
            g = int(np.clip(base_g * shade * patina, 0, 255))
            b = int(np.clip(base_b * shade * patina, 0, 255))
            arr[y, x] = [r, g, b, 255]


def add_edge_shadow(img: Image.Image) -> Image.Image:
    """Add a soft drop shadow around the roller for depth."""
    # Create a slightly larger shadow
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow_arr = np.array(shadow)
    img_arr = np.array(img)

    # Where the roller is opaque, create shadow offset
    alpha = img_arr[:, :, 3]
    # Dilate the alpha for shadow
    alpha_img = Image.fromarray(alpha)
    dilated = alpha_img.filter(ImageFilter.MaxFilter(7))
    blurred = dilated.filter(ImageFilter.GaussianBlur(radius=4))
    shadow_alpha = np.array(blurred)

    # Shadow is dark, semi-transparent
    shadow_arr[:, :, 0] = 0
    shadow_arr[:, :, 1] = 0
    shadow_arr[:, :, 2] = 0
    shadow_arr[:, :, 3] = (shadow_alpha * 0.5).astype(np.uint8)

    # Offset shadow slightly right and down
    shadow_shifted = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow_base = Image.fromarray(shadow_arr)
    shadow_shifted.paste(shadow_base, (3, 2))

    # Composite: shadow behind roller
    result = Image.alpha_composite(shadow_shifted, img)
    return result


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("=== Generating procedural scroll roller ===")

    arr = np.zeros((HEIGHT, WIDTH, 4), dtype=np.uint8)
    cx = WIDTH // 2

    # Main wooden shaft
    shaft_start = CAP_HEIGHT
    shaft_end = HEIGHT - CAP_HEIGHT
    draw_wood_shaft(arr, shaft_start, shaft_end, cx, SHAFT_WIDTH // 2)

    # End caps
    draw_end_cap(arr, 0, CAP_HEIGHT, cx, CAP_WIDTH // 2, is_top=True)
    draw_end_cap(arr, HEIGHT - CAP_HEIGHT, HEIGHT, cx, CAP_WIDTH // 2, is_top=False)

    # Metal reinforcement bands along the shaft
    band_positions = [
        CAP_HEIGHT + 10,
        CAP_HEIGHT + 30,
        HEIGHT // 2,
        shaft_end - 30,
        shaft_end - 10,
    ]
    for bp in band_positions:
        draw_metal_band(arr, bp, BAND_HEIGHT, cx, SHAFT_WIDTH // 2)

    img = Image.fromarray(arr, "RGBA")

    # Add drop shadow for depth
    img = add_edge_shadow(img)

    # Save left roller
    left_path = OUTPUT_DIR / "scroll_roller.png"
    img.save(left_path, "PNG")
    print(f"  Saved: {left_path} ({WIDTH}x{HEIGHT})")

    # Mirror for right roller
    mirrored = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    right_path = OUTPUT_DIR / "scroll_roller_right.png"
    mirrored.save(right_path, "PNG")
    print(f"  Mirrored: {right_path}")

    print("\n=== Done! (zero cost) ===")


if __name__ == "__main__":
    main()
