#!/usr/bin/env python3
"""
Generate ALL UI texture assets for a Diablo-inspired dark fantasy roguelike.
Style: dark iron metal frames, carved stone, aged parchment.
Output: assets/ui/ subdirectories (frames, orbs, backgrounds, decorative).
"""

import os
import random
import math
from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_BASE = os.path.join(SCRIPT_DIR, "assets", "ui")

SUBDIRS = ["frames", "orbs", "backgrounds", "decorative"]

# Seed for reproducibility
random.seed(42)

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------

def hex_to_rgba(h, a=255):
    """Convert '#RRGGBB' to (R, G, B, A)."""
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def clamp(v, lo=0, hi=255):
    return max(lo, min(hi, int(v)))


def noise_color(base_rgba, spread=10):
    """Return base color with per-channel noise of +-spread."""
    r, g, b, a = base_rgba
    return (
        clamp(r + random.randint(-spread, spread)),
        clamp(g + random.randint(-spread, spread)),
        clamp(b + random.randint(-spread, spread)),
        a,
    )


def lerp_color(c1, c2, t):
    """Linearly interpolate between two RGBA colors."""
    return tuple(clamp(int(a + (b - a) * t)) for a, b in zip(c1, c2))


def blend_over(base, overlay):
    """Alpha-composite overlay onto base (both RGBA tuples)."""
    rb, gb, bb, ab = base
    ro, go, bo, ao = overlay
    alpha_o = ao / 255.0
    alpha_b = ab / 255.0
    alpha_out = alpha_o + alpha_b * (1 - alpha_o)
    if alpha_out == 0:
        return (0, 0, 0, 0)
    r = int((ro * alpha_o + rb * alpha_b * (1 - alpha_o)) / alpha_out)
    g = int((go * alpha_o + gb * alpha_b * (1 - alpha_o)) / alpha_out)
    b = int((bo * alpha_o + bb * alpha_b * (1 - alpha_o)) / alpha_out)
    return (clamp(r), clamp(g), clamp(b), clamp(int(alpha_out * 255)))


# ---------------------------------------------------------------------------
# Noise / texture helpers
# ---------------------------------------------------------------------------

def fill_noise(img, base_rgba, spread=10):
    """Fill entire image with noisy solid color."""
    w, h = img.size
    for y in range(h):
        for x in range(w):
            img.putpixel((x, y), noise_color(base_rgba, spread))


def fill_noise_rect(img, x0, y0, x1, y1, base_rgba, spread=10):
    """Fill a rectangular region with noisy color."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x < img.width and 0 <= y < img.height:
                img.putpixel((x, y), noise_color(base_rgba, spread))


def add_noise_to_region(img, x0, y0, x1, y1, spread=8):
    """Add noise to existing pixel values in a region."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x < img.width and 0 <= y < img.height:
                r, g, b, a = img.getpixel((x, y))
                if a > 0:
                    img.putpixel((x, y), (
                        clamp(r + random.randint(-spread, spread)),
                        clamp(g + random.randint(-spread, spread)),
                        clamp(b + random.randint(-spread, spread)),
                        a,
                    ))


def draw_bevel_rect(img, x0, y0, x1, y1, highlight, shadow, width=1):
    """Draw beveled rectangle edges. highlight=top-left, shadow=bottom-right."""
    for i in range(width):
        # Top edge (highlight)
        for x in range(x0 + i, x1 - i):
            px = img.getpixel((x, y0 + i))
            img.putpixel((x, y0 + i), blend_over(px, highlight))
        # Left edge (highlight)
        for y in range(y0 + i, y1 - i):
            px = img.getpixel((x0 + i, y))
            img.putpixel((x0 + i, y), blend_over(px, highlight))
        # Bottom edge (shadow)
        for x in range(x0 + i, x1 - i):
            px = img.getpixel((x, y1 - 1 - i))
            img.putpixel((x, y1 - 1 - i), blend_over(px, shadow))
        # Right edge (shadow)
        for y in range(y0 + i, y1 - i):
            px = img.getpixel((x1 - 1 - i, y))
            img.putpixel((x1 - 1 - i, y), blend_over(px, shadow))


def draw_inset_rect(img, x0, y0, x1, y1, highlight, shadow, width=1):
    """Inset bevel — shadow on top-left, highlight on bottom-right (opposite of raised)."""
    draw_bevel_rect(img, x0, y0, x1, y1, shadow, highlight, width)


def draw_rivet(img, cx, cy, bright=(140, 140, 150, 255), dark=(40, 40, 48, 255)):
    """Draw a small 3x3 rivet at (cx, cy)."""
    # center bright
    if 0 <= cx < img.width and 0 <= cy < img.height:
        img.putpixel((cx, cy), bright)
    # top-left highlight
    for dx, dy in [(-1, 0), (0, -1)]:
        nx, ny = cx + dx, cy + dy
        if 0 <= nx < img.width and 0 <= ny < img.height:
            img.putpixel((nx, ny), lerp_color(dark, bright, 0.6))
    # bottom-right shadow
    for dx, dy in [(1, 0), (0, 1)]:
        nx, ny = cx + dx, cy + dy
        if 0 <= nx < img.width and 0 <= ny < img.height:
            img.putpixel((nx, ny), dark)
    # diagonals darker
    for dx, dy in [(-1, -1), (1, 1), (-1, 1), (1, -1)]:
        nx, ny = cx + dx, cy + dy
        if 0 <= nx < img.width and 0 <= ny < img.height:
            img.putpixel((nx, ny), lerp_color(dark, bright, 0.3))


def make_tileable(img, margin=8):
    """Blend edges to make texture tileable by averaging opposing edge strips."""
    w, h = img.size
    result = img.copy()
    for m in range(margin):
        t = m / margin  # 0 at edge, approaching 1 at margin
        weight_edge = 1.0 - t * 0.5  # edge pixel weight decreases
        weight_opp = t * 0.5         # opposite pixel weight increases

        for x in range(w):
            # Top-bottom blending
            top_px = img.getpixel((x, m))
            bot_px = img.getpixel((x, h - 1 - m))
            blended_top = lerp_color(bot_px, top_px, weight_edge)
            blended_bot = lerp_color(top_px, bot_px, weight_edge)
            result.putpixel((x, m), blended_top)
            result.putpixel((x, h - 1 - m), blended_bot)

        for y in range(h):
            # Left-right blending
            left_px = result.getpixel((m, y))
            right_px = result.getpixel((w - 1 - m, y))
            blended_left = lerp_color(right_px, left_px, weight_edge)
            blended_right = lerp_color(left_px, right_px, weight_edge)
            result.putpixel((m, y), blended_left)
            result.putpixel((w - 1 - m, y), blended_right)

    return result


# ===========================================================================
# FRAME TEXTURES
# ===========================================================================

def gen_panel_iron(path):
    """48x48 9-slice dark iron frame with beveled edges, noise, corner rivets."""
    size = 48
    border = 6
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    outer_dark = hex_to_rgba("#1A1A1F")
    metal_base = hex_to_rgba("#2D2D35")
    highlight = hex_to_rgba("#55555F")
    shadow = hex_to_rgba("#0D0D12")
    interior = hex_to_rgba("#111116")

    # Fill border region with metal base + noise
    fill_noise(img, metal_base, spread=8)

    # Fill interior (will be the stretchable center of 9-slice)
    fill_noise_rect(img, border, border, size - border, size - border, interior, spread=5)

    # Outer edge (1px dark outline)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, size - 1, size - 1], outline=outer_dark)

    # Outer bevel (highlight top-left, shadow bottom-right) — 2px wide
    draw_bevel_rect(img, 1, 1, size - 1, size - 1,
                    (*highlight[:3], 160), (*shadow[:3], 200), width=2)

    # Inner bevel at border boundary (inset to give depth)
    draw_inset_rect(img, border - 1, border - 1, size - border + 1, size - border + 1,
                    (*highlight[:3], 100), (*shadow[:3], 140), width=1)

    # Additional mid-border detail line
    mid = border // 2
    draw_bevel_rect(img, mid, mid, size - mid, size - mid,
                    (*highlight[:3], 60), (*shadow[:3], 80), width=1)

    # Corner rivets
    rivet_offset = 3
    for rx, ry in [
        (rivet_offset, rivet_offset),
        (size - 1 - rivet_offset, rivet_offset),
        (rivet_offset, size - 1 - rivet_offset),
        (size - 1 - rivet_offset, size - 1 - rivet_offset),
    ]:
        draw_rivet(img, rx, ry)

    # Add subtle overall noise to border region only
    add_noise_to_region(img, 0, 0, size, border, spread=5)
    add_noise_to_region(img, 0, size - border, size, size, spread=5)
    add_noise_to_region(img, 0, border, border, size - border, spread=5)
    add_noise_to_region(img, size - border, border, size, size - border, spread=5)

    img.save(path)
    return path


def gen_panel_stone(path):
    """48x48 9-slice carved stone frame. Warmer tones, more noise."""
    size = 48
    border = 6
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    base = hex_to_rgba("#252219")
    surface = hex_to_rgba("#3A3529")
    highlight = hex_to_rgba("#524C3C")
    shadow = hex_to_rgba("#151210")
    interior = hex_to_rgba("#1A1815")

    # Fill border with stone surface + heavier noise
    fill_noise(img, surface, spread=14)

    # Fill interior
    fill_noise_rect(img, border, border, size - border, size - border, interior, spread=6)

    # Outer edge
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, size - 1, size - 1], outline=base)

    # Bevels
    draw_bevel_rect(img, 1, 1, size - 1, size - 1,
                    (*highlight[:3], 140), (*shadow[:3], 180), width=2)

    # Inner bevel (slightly rounded effect by skipping exact corners)
    draw_inset_rect(img, border - 1, border - 1, size - border + 1, size - border + 1,
                    (*highlight[:3], 90), (*shadow[:3], 120), width=1)

    # Round inner corners slightly: darken the exact corner pixels of the interior
    for cx, cy in [
        (border, border), (size - border - 1, border),
        (border, size - border - 1), (size - border - 1, size - border - 1),
    ]:
        img.putpixel((cx, cy), noise_color(surface, 8))

    # Extra stone noise
    add_noise_to_region(img, 0, 0, size, size, spread=6)

    img.save(path)
    return path


def gen_panel_parchment(path):
    """48x48 9-slice aged parchment with darker edges."""
    size = 48
    border = 3  # thinner border for parchment
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    interior = hex_to_rgba("#D4C5A0")
    edge_dark = hex_to_rgba("#8B7D5E")
    border_line = hex_to_rgba("#3A3529")
    edge_mid = hex_to_rgba("#B0A47E")

    # Fill everything with parchment interior
    fill_noise(img, interior, spread=8)

    # Darken edges gradually (vignette effect within the border area + a few px inside)
    fade_width = 8
    for y in range(size):
        for x in range(size):
            # Distance from nearest edge
            dx = min(x, size - 1 - x)
            dy = min(y, size - 1 - y)
            d = min(dx, dy)
            if d < fade_width:
                t = d / fade_width  # 0 at edge, 1 at fade_width
                # Blend toward edge_dark
                px = img.getpixel((x, y))
                darkened = lerp_color(edge_dark, px, t)
                img.putpixel((x, y), darkened)

    # Outer border line
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, size - 1, size - 1], outline=border_line)
    draw.rectangle([1, 1, size - 2, size - 2], outline=(*edge_dark[:3], 180))

    # Subtle paper grain noise
    add_noise_to_region(img, 0, 0, size, size, spread=4)

    img.save(path)
    return path


def gen_slot(path, size=40, border_width=2, edge_glow=None, glow_alpha=0, inner_glow=False):
    """Inset stone inventory slot."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    interior = hex_to_rgba("#15151A")
    stone = hex_to_rgba("#2D2D35")
    highlight = hex_to_rgba("#55555F")
    shadow = hex_to_rgba("#0D0D12")

    # Fill with stone base
    fill_noise(img, stone, spread=8)

    # Fill interior
    fill_noise_rect(img, border_width + 1, border_width + 1,
                    size - border_width - 1, size - border_width - 1,
                    interior, spread=4)

    # Outer edge
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, size - 1, size - 1], outline=hex_to_rgba("#0D0D12"))

    # Inset bevel (shadow top-left, highlight bottom-right — looks pushed in)
    draw_inset_rect(img, 1, 1, size - 1, size - 1,
                    (*highlight[:3], 130), (*shadow[:3], 180), width=border_width)

    # Edge glow (for hover/selected variants)
    if edge_glow:
        glow_rgba = (*hex_to_rgba(edge_glow)[:3], glow_alpha)
        # Draw glow on outer 2px border
        for i in range(2):
            for x in range(i, size - i):
                px = img.getpixel((x, i))
                img.putpixel((x, i), blend_over(px, glow_rgba))
                px = img.getpixel((x, size - 1 - i))
                img.putpixel((x, size - 1 - i), blend_over(px, glow_rgba))
            for y in range(i, size - i):
                px = img.getpixel((i, y))
                img.putpixel((i, y), blend_over(px, glow_rgba))
                px = img.getpixel((size - 1 - i, y))
                img.putpixel((size - 1 - i, y), blend_over(px, glow_rgba))

    # Inner glow (for selected variant)
    if inner_glow and edge_glow:
        glow_base = hex_to_rgba(edge_glow)
        glow_range = 4
        bw = border_width + 1
        for y in range(bw, size - bw):
            for x in range(bw, size - bw):
                dx = min(x - bw, size - bw - 1 - x)
                dy = min(y - bw, size - bw - 1 - y)
                d = min(dx, dy)
                if d < glow_range:
                    t = 1.0 - (d / glow_range)
                    glow_a = int(35 * t)
                    px = img.getpixel((x, y))
                    img.putpixel((x, y), blend_over(px, (*glow_base[:3], glow_a)))

    add_noise_to_region(img, 0, 0, size, size, spread=3)
    img.save(path)
    return path


def gen_button(path, w=80, h=32, raised=True, gold_tint=False):
    """Raised or pressed stone/metal button. 9-slice compatible."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    base = hex_to_rgba("#3D3D48")
    highlight = hex_to_rgba("#55555F")
    shadow = hex_to_rgba("#1A1A1F")
    outline = hex_to_rgba("#111116")
    border_w = 2

    if not raised:
        # Pressed: darker base
        base = hex_to_rgba("#2E2E38")

    if gold_tint:
        # Hover: warm tint
        base = hex_to_rgba("#43403A")
        highlight = hex_to_rgba("#605848")

    # Fill base with noise
    fill_noise(img, base, spread=8)

    # Outline
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w - 1, h - 1], outline=outline)

    if raised:
        draw_bevel_rect(img, 1, 1, w - 1, h - 1, (*highlight[:3], 150), (*shadow[:3], 180), width=border_w)
    else:
        draw_inset_rect(img, 1, 1, w - 1, h - 1, (*highlight[:3], 120), (*shadow[:3], 160), width=border_w)

    add_noise_to_region(img, 0, 0, w, h, spread=4)
    img.save(path)
    return path


def gen_bar_frame(path):
    """100x20 9-slice frame for progress bars. Thin metal, 3px border, dark interior."""
    w, h = 100, 20
    border = 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    metal = hex_to_rgba("#2D2D35")
    highlight = hex_to_rgba("#55555F")
    shadow = hex_to_rgba("#0D0D12")
    interior = hex_to_rgba("#0A0A0F")
    outline = hex_to_rgba("#111116")

    fill_noise(img, metal, spread=6)
    fill_noise_rect(img, border, border, w - border, h - border, interior, spread=3)

    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w - 1, h - 1], outline=outline)

    draw_bevel_rect(img, 1, 1, w - 1, h - 1, (*highlight[:3], 120), (*shadow[:3], 160), width=1)
    draw_inset_rect(img, border - 1, border - 1, w - border + 1, h - border + 1,
                    (*highlight[:3], 80), (*shadow[:3], 120), width=1)

    add_noise_to_region(img, 0, 0, w, h, spread=3)
    img.save(path)
    return path


def gen_tab(path, w=80, h=28, active=True):
    """Tab texture. Active: no bottom border, lighter. Inactive: full border, darker."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    if active:
        base = hex_to_rgba("#35353E")
        highlight = hex_to_rgba("#55555F")
        shadow = hex_to_rgba("#1A1A1F")
    else:
        base = hex_to_rgba("#252529")
        highlight = hex_to_rgba("#3A3A44")
        shadow = hex_to_rgba("#111116")

    outline = hex_to_rgba("#111116")

    fill_noise(img, base, spread=7)

    draw = ImageDraw.Draw(img)
    # Draw outline
    if active:
        # No bottom border — top, left, right only
        draw.line([(0, 0), (w - 1, 0)], fill=outline)  # top
        draw.line([(0, 0), (0, h - 1)], fill=outline)   # left
        draw.line([(w - 1, 0), (w - 1, h - 1)], fill=outline)  # right
    else:
        draw.rectangle([0, 0, w - 1, h - 1], outline=outline)

    # Bevel
    if active:
        draw_bevel_rect(img, 1, 1, w - 1, h, (*highlight[:3], 130), (*shadow[:3], 150), width=1)
    else:
        draw_inset_rect(img, 1, 1, w - 1, h - 1, (*highlight[:3], 80), (*shadow[:3], 120), width=1)

    add_noise_to_region(img, 0, 0, w, h, spread=4)
    img.save(path)
    return path


# ===========================================================================
# ORB TEXTURES
# ===========================================================================

def gen_orb_frame(path):
    """72x72 circular metal rim for health/voice orbs. Transparent center."""
    size = 72
    cx, cy = size // 2, size // 2
    outer_r = 35
    inner_r = 28
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    metal_base = hex_to_rgba("#3A3A44")
    highlight = hex_to_rgba("#6A6A78")
    shadow = hex_to_rgba("#18181E")
    dark_outline = hex_to_rgba("#0D0D12")
    rivet_bright = (160, 160, 175, 255)
    rivet_dark = (50, 50, 60, 255)

    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)

            if inner_r <= dist <= outer_r:
                # Normalize position within ring for bevel
                ring_t = (dist - inner_r) / (outer_r - inner_r)  # 0=inner, 1=outer

                # Angle for directional bevel (light from top-left)
                angle = math.atan2(dy, dx)  # -pi to pi
                # Light direction: top-left = -3pi/4
                light_angle = -3 * math.pi / 4
                dot = math.cos(angle - light_angle)  # -1 to 1

                # Base metal color
                base = noise_color(metal_base, 6)

                # Apply bevel based on dot product
                if dot > 0:
                    # Highlight side
                    color = lerp_color(base, highlight, dot * 0.7)
                else:
                    # Shadow side
                    color = lerp_color(base, shadow, abs(dot) * 0.7)

                # Darken outer and inner edges of ring
                if ring_t < 0.15 or ring_t > 0.85:
                    color = lerp_color(color, dark_outline, 0.5)

                img.putpixel((x, y), color)

            elif dist > outer_r and dist <= outer_r + 1:
                # Anti-alias outer edge (dark outline)
                frac = dist - outer_r
                img.putpixel((x, y), (*dark_outline[:3], int(255 * (1 - frac))))

    # Rivets at cardinal points
    for angle_deg in [0, 90, 180, 270]:
        rad = math.radians(angle_deg)
        mid_r = (inner_r + outer_r) / 2
        rx = int(cx + mid_r * math.cos(rad))
        ry = int(cy + mid_r * math.sin(rad))
        draw_rivet(img, rx, ry, rivet_bright, rivet_dark)

    # Add subtle noise to ring pixels
    for y in range(size):
        for x in range(size):
            r, g, b, a = img.getpixel((x, y))
            if a > 100:
                dx = x - cx
                dy = y - cy
                dist = math.sqrt(dx * dx + dy * dy)
                if inner_r <= dist <= outer_r:
                    img.putpixel((x, y), (
                        clamp(r + random.randint(-4, 4)),
                        clamp(g + random.randint(-4, 4)),
                        clamp(b + random.randint(-4, 4)),
                        a,
                    ))

    img.save(path)
    return path


def gen_orb_mask(path):
    """64x64 white circle on transparent background. Radius 28, centered."""
    size = 64
    cx, cy = size // 2, size // 2
    radius = 28
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= radius:
                img.putpixel((x, y), (255, 255, 255, 255))
            elif dist <= radius + 1:
                # Slight anti-alias
                frac = dist - radius
                img.putpixel((x, y), (255, 255, 255, int(255 * (1 - frac))))

    img.save(path)
    return path


# ===========================================================================
# BACKGROUND TEXTURES
# ===========================================================================

def gen_bg_stone_tile(path):
    """64x64 tileable dark stone texture."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))

    base = hex_to_rgba("#1A1A1F")
    fill_noise(img, base, spread=15)

    # Add some darker splotches for stone texture variation
    for _ in range(20):
        sx = random.randint(0, size - 1)
        sy = random.randint(0, size - 1)
        r = random.randint(2, 6)
        dark_offset = random.randint(-20, -5)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    px = (sx + dx) % size
                    py = (sy + dy) % size
                    c = img.getpixel((px, py))
                    dist_t = math.sqrt(dx * dx + dy * dy) / r
                    offset = int(dark_offset * (1 - dist_t))
                    img.putpixel((px, py), (
                        clamp(c[0] + offset),
                        clamp(c[1] + offset),
                        clamp(c[2] + offset),
                        255,
                    ))

    img = make_tileable(img, margin=10)
    img.save(path)
    return path


def gen_bg_leather(path):
    """64x64 tileable dark leather texture with crosshatch grain."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))

    base = hex_to_rgba("#252219")
    fill_noise(img, base, spread=10)

    # Crosshatch grain: subtle diagonal lines
    for y in range(size):
        for x in range(size):
            # Diagonal pattern
            v1 = ((x + y) % 6 == 0)
            v2 = ((x - y) % 8 == 0)
            if v1 or v2:
                c = img.getpixel((x, y))
                offset = -8 if v1 else -5
                img.putpixel((x, y), (
                    clamp(c[0] + offset),
                    clamp(c[1] + offset),
                    clamp(c[2] + offset),
                    255,
                ))

    img = make_tileable(img, margin=10)
    img.save(path)
    return path


def gen_bg_metal_brushed(path):
    """128x64 tileable brushed metal with horizontal grain."""
    w, h = 128, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))

    base = hex_to_rgba("#2A2A32")
    fill_noise(img, base, spread=8)

    # Horizontal streaks
    for y in range(h):
        streak_offset = random.randint(-6, 6)
        for x in range(w):
            c = img.getpixel((x, y))
            # Consistent horizontal noise per row
            local_noise = random.randint(-3, 3)
            img.putpixel((x, y), (
                clamp(c[0] + streak_offset + local_noise),
                clamp(c[1] + streak_offset + local_noise),
                clamp(c[2] + streak_offset + local_noise),
                255,
            ))

    img = make_tileable(img, margin=12)
    img.save(path)
    return path


def gen_action_bar_bg(path):
    """256x100 non-tiling action bar background. Dark metal with ornate top edge."""
    w, h = 256, 100
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))

    base = hex_to_rgba("#222228")
    metal_surface = hex_to_rgba("#2A2A32")
    highlight = hex_to_rgba("#55555F")
    shadow = hex_to_rgba("#0D0D12")
    outline = hex_to_rgba("#111116")
    rivet_bright = (140, 140, 150, 255)
    rivet_dark = (40, 40, 48, 255)

    # Fill with metal base
    fill_noise(img, metal_surface, spread=8)

    # Subtle horizontal brushed texture
    for y in range(h):
        streak = random.randint(-4, 4)
        for x in range(w):
            c = img.getpixel((x, y))
            img.putpixel((x, y), (
                clamp(c[0] + streak + random.randint(-2, 2)),
                clamp(c[1] + streak + random.randint(-2, 2)),
                clamp(c[2] + streak + random.randint(-2, 2)),
                255,
            ))

    # Top ornate edge: 3px raised bevel
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w - 1, h - 1], outline=outline)

    # Top bevel (3px raised bar along top)
    top_bevel_h = 3
    for y in range(1, top_bevel_h + 1):
        for x in range(1, w - 1):
            t = y / top_bevel_h
            color = lerp_color(highlight, metal_surface, t)
            img.putpixel((x, y), noise_color(color, 4))

    # Shadow line below top bevel
    for x in range(1, w - 1):
        img.putpixel((x, top_bevel_h + 1), noise_color(shadow, 3))

    # Rivet dots every 32px along top edge
    for rx in range(16, w, 32):
        draw_rivet(img, rx, top_bevel_h + 4, rivet_bright, rivet_dark)

    # Bottom subtle shadow
    for x in range(1, w - 1):
        img.putpixel((x, h - 2), noise_color(shadow, 3))

    img.save(path)
    return path


# ===========================================================================
# DECORATIVE TEXTURES
# ===========================================================================

def gen_divider_ornate(path):
    """200x8 horizontal ornate divider with center diamond/dot."""
    w, h = 200, 8
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    line_color = hex_to_rgba("#6B5A2E")
    center_bright = hex_to_rgba("#C8A84E")
    center_dim = hex_to_rgba("#8B7530")

    cy = h // 2
    cx = w // 2

    # Main horizontal line (1px, centered vertically)
    for x in range(w):
        # Fade line at edges
        fade = 1.0
        edge_fade = 30
        if x < edge_fade:
            fade = x / edge_fade
        elif x > w - edge_fade:
            fade = (w - x) / edge_fade

        alpha = int(255 * fade)
        img.putpixel((x, cy), (*line_color[:3], alpha))
        # Second thinner line below for depth
        img.putpixel((x, cy + 1), (*line_color[:3], int(alpha * 0.4)))

    # Center diamond (5x5 diamond shape)
    diamond_points = [
        (0, -2), (0, 2), (-2, 0), (2, 0),
        (-1, -1), (1, -1), (-1, 1), (1, 1),
        (0, -1), (0, 1), (-1, 0), (1, 0),
        (0, 0),
    ]
    for dx, dy in diamond_points:
        px, py = cx + dx, cy + dy
        if 0 <= px < w and 0 <= py < h:
            # Brighter in center, dimmer at edges
            dist = abs(dx) + abs(dy)
            if dist <= 1:
                img.putpixel((px, py), center_bright)
            else:
                img.putpixel((px, py), center_dim)

    # Small dots flanking the diamond
    for offset in [-12, -8, 8, 12]:
        px = cx + offset
        if 0 <= px < w:
            img.putpixel((px, cy), center_dim)

    img.save(path)
    return path


def gen_corner_ornate(base_path):
    """16x16 corner decorative pieces. Generate TL, then mirror for TR, BL, BR."""
    size = 16
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    gold = hex_to_rgba("#C8A84E")
    gold_dim = hex_to_rgba("#6B5A2E")
    gold_dark = hex_to_rgba("#4A3D1E")

    # Draw an L-shaped flourish in top-left corner
    # Vertical stroke (left edge)
    for y in range(0, 12):
        t = y / 12.0
        color = lerp_color(gold, gold_dark, t)
        img.putpixel((1, y), color)
        if y < 8:
            img.putpixel((2, y), lerp_color(gold_dim, (0, 0, 0, 0), t * 1.2))

    # Horizontal stroke (top edge)
    for x in range(0, 12):
        t = x / 12.0
        color = lerp_color(gold, gold_dark, t)
        img.putpixel((x, 1), color)
        if x < 8:
            img.putpixel((x, 2), lerp_color(gold_dim, (0, 0, 0, 0), t * 1.2))

    # Corner accent (bright dot at corner)
    img.putpixel((1, 1), gold)
    img.putpixel((0, 0), gold_dim)
    img.putpixel((0, 1), gold_dim)
    img.putpixel((1, 0), gold_dim)

    # Small curl at end of L (decorative)
    img.putpixel((1, 12), gold_dark)
    img.putpixel((2, 11), (*gold_dark[:3], 180))
    img.putpixel((12, 1), gold_dark)
    img.putpixel((11, 2), (*gold_dark[:3], 180))

    # Inner decorative dot
    img.putpixel((4, 4), (*gold_dim[:3], 160))
    img.putpixel((3, 3), (*gold_dark[:3], 120))

    # Save TL
    dir_path = os.path.dirname(base_path)
    paths = []

    tl_path = os.path.join(dir_path, "corner_ornate_tl.png")
    img.save(tl_path)
    paths.append(tl_path)

    # TR: mirror horizontally
    tr = img.transpose(Image.FLIP_LEFT_RIGHT)
    tr_path = os.path.join(dir_path, "corner_ornate_tr.png")
    tr.save(tr_path)
    paths.append(tr_path)

    # BL: mirror vertically
    bl = img.transpose(Image.FLIP_TOP_BOTTOM)
    bl_path = os.path.join(dir_path, "corner_ornate_bl.png")
    bl.save(bl_path)
    paths.append(bl_path)

    # BR: mirror both
    br = img.transpose(Image.FLIP_LEFT_RIGHT).transpose(Image.FLIP_TOP_BOTTOM)
    br_path = os.path.join(dir_path, "corner_ornate_br.png")
    br.save(br_path)
    paths.append(br_path)

    return paths


def gen_book_cover(path):
    """64x64 9-slice dark leather book cover with gold corner accents and beveled edge."""
    size = 64
    border = 10
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    leather = hex_to_rgba("#1E1A14")
    leather_mid = hex_to_rgba("#2A2318")
    highlight = hex_to_rgba("#3D3428")
    shadow = hex_to_rgba("#0D0B08")
    gold = hex_to_rgba("#C8A84E")
    gold_dim = hex_to_rgba("#6B5A2E")
    interior = hex_to_rgba("#161210")

    # Fill border with leather texture + noise
    fill_noise(img, leather_mid, spread=10)

    # Fill interior (stretchable center)
    fill_noise_rect(img, border, border, size - border, size - border, interior, spread=5)

    # Outer edge (dark outline)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, size - 1, size - 1], outline=shadow)

    # Outer bevel
    draw_bevel_rect(img, 1, 1, size - 1, size - 1,
                    (*highlight[:3], 140), (*shadow[:3], 200), width=2)

    # Inner bevel at border boundary
    draw_inset_rect(img, border - 1, border - 1, size - border + 1, size - border + 1,
                    (*highlight[:3], 100), (*shadow[:3], 160), width=1)

    # Gold corner accents (L-shaped)
    for cx, cy, dx, dy in [(2, 2, 1, 1), (size - 3, 2, -1, 1),
                           (2, size - 3, 1, -1), (size - 3, size - 3, -1, -1)]:
        for i in range(6):
            px_h, py_h = cx + dx * i, cy
            px_v, py_v = cx, cy + dy * i
            if 0 <= px_h < size and 0 <= py_h < size:
                t = i / 6.0
                img.putpixel((px_h, py_h), lerp_color(gold, gold_dim, t))
            if 0 <= px_v < size and 0 <= py_v < size:
                t = i / 6.0
                img.putpixel((px_v, py_v), lerp_color(gold, gold_dim, t))
        # Corner dot
        img.putpixel((cx, cy), gold)

    # Leather grain noise
    add_noise_to_region(img, 0, 0, size, size, spread=6)

    img.save(path)
    return path


def gen_book_page(path):
    """128x128 tileable aged parchment with foxing spots and grain noise."""
    size = 128
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))

    base = hex_to_rgba("#D4C5A0")
    fill_noise(img, base, spread=6)

    # Foxing spots (age stains)
    for _ in range(30):
        sx = random.randint(0, size - 1)
        sy = random.randint(0, size - 1)
        r = random.randint(2, 5)
        stain = hex_to_rgba("#B8A47A")
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r:
                    px = (sx + dx) % size
                    py = (sy + dy) % size
                    c = img.getpixel((px, py))
                    dist_t = math.sqrt(dx * dx + dy * dy) / r
                    blended = lerp_color(stain, c, dist_t)
                    img.putpixel((px, py), blended)

    # Subtle age cracks (thin dark lines)
    for _ in range(8):
        cx = random.randint(10, size - 10)
        cy = random.randint(10, size - 10)
        length = random.randint(6, 20)
        angle = random.uniform(0, math.pi)
        crack_color = hex_to_rgba("#9E8E6E")
        for i in range(length):
            px = int(cx + i * math.cos(angle))
            py = int(cy + i * math.sin(angle))
            if 0 <= px < size and 0 <= py < size:
                c = img.getpixel((px, py))
                img.putpixel((px, py), lerp_color(crack_color, c, 0.5))

    # Paper grain noise
    add_noise_to_region(img, 0, 0, size, size, spread=4)

    img = make_tileable(img, margin=12)
    img.save(path)
    return path


def gen_book_spine(path):
    """24x128 9-slice dark leather spine strip with stitch marks."""
    w, h = 24, 128
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    leather = hex_to_rgba("#1A1610")
    leather_mid = hex_to_rgba("#252018")
    highlight = hex_to_rgba("#3A3228")
    shadow = hex_to_rgba("#0A0908")
    stitch = hex_to_rgba("#5A4E3A")

    # Fill with leather
    fill_noise(img, leather_mid, spread=8)

    # Vertical highlight down center (spine ridge)
    cx = w // 2
    for y in range(h):
        for dx in range(-2, 3):
            px = cx + dx
            if 0 <= px < w:
                c = img.getpixel((px, y))
                intensity = 1.0 - abs(dx) / 3.0
                img.putpixel((px, y), lerp_color(c, highlight, intensity * 0.4))

    # Edge shadows
    for y in range(h):
        for x in range(3):
            c = img.getpixel((x, y))
            img.putpixel((x, y), lerp_color(shadow, c, x / 3.0))
            c = img.getpixel((w - 1 - x, y))
            img.putpixel((w - 1 - x, y), lerp_color(shadow, c, x / 3.0))

    # Stitch marks every 12px
    for y in range(6, h - 4, 12):
        for dy in range(3):
            sy = y + dy
            if 0 <= sy < h:
                # Left stitch line
                img.putpixel((4, sy), stitch)
                # Right stitch line
                img.putpixel((w - 5, sy), stitch)

    # Outer border
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w - 1, h - 1], outline=shadow)

    add_noise_to_region(img, 0, 0, w, h, spread=5)
    img.save(path)
    return path


def gen_bookmark_tab(path):
    """32x48 leather bookmark tab, tinted at runtime."""
    w, h = 32, 48
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    leather = hex_to_rgba("#3A3228")
    highlight = hex_to_rgba("#524838")
    shadow = hex_to_rgba("#1A1610")
    edge = hex_to_rgba("#0D0B08")

    # Bookmark shape: rectangle with pointed bottom
    for y in range(h):
        for x in range(w):
            # Check if pixel is inside bookmark shape
            if y < h - 10:
                # Rectangle part
                in_shape = True
            else:
                # Pointed bottom (V shape)
                bottom_y = y - (h - 10)
                half_w = w / 2
                taper = half_w * (1.0 - bottom_y / 10.0)
                in_shape = abs(x - half_w) < taper

            if in_shape:
                img.putpixel((x, y), noise_color(leather, 8))

    # Bevel on edges
    for y in range(h - 10):
        if 0 < y < h:
            # Left highlight
            c = img.getpixel((0, y))
            if c[3] > 0:
                img.putpixel((1, y), lerp_color(c, highlight, 0.5))
            # Right shadow
            c = img.getpixel((w - 1, y))
            if c[3] > 0:
                img.putpixel((w - 2, y), lerp_color(c, shadow, 0.5))

    # Top highlight
    for x in range(w):
        c = img.getpixel((x, 0))
        if c[3] > 0:
            img.putpixel((x, 0), lerp_color(c, highlight, 0.4))

    # Add noise to visible pixels only
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a > 0:
                img.putpixel((x, y), (
                    clamp(r + random.randint(-4, 4)),
                    clamp(g + random.randint(-4, 4)),
                    clamp(b + random.randint(-4, 4)),
                    a,
                ))

    img.save(path)
    return path


def gen_gutter_shadow(path):
    """32x128 linear gradient from dark to transparent for book spine gutter."""
    w, h = 32, 128
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    dark = hex_to_rgba("#1A1815")

    for y in range(h):
        for x in range(w):
            # Linear gradient: opaque at x=0, transparent at x=w
            t = x / max(1, w - 1)
            alpha = int(180 * (1.0 - t * t))  # Quadratic falloff
            img.putpixel((x, y), (*dark[:3], max(0, alpha)))

    img.save(path)
    return path


def gen_bar_fill(path, top_color, bottom_color, w=8, h=16):
    """Vertical gradient bar fill texture, tileable horizontally."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    top = hex_to_rgba(top_color)
    bottom = hex_to_rgba(bottom_color)

    for y in range(h):
        t = y / max(1, h - 1)
        color = lerp_color(top, bottom, t)
        for x in range(w):
            img.putpixel((x, y), noise_color(color, 4))

    img.save(path)
    return path


# ===========================================================================
# MAIN
# ===========================================================================

def main():
    # Ensure output directories exist
    for subdir in SUBDIRS:
        os.makedirs(os.path.join(OUTPUT_BASE, subdir), exist_ok=True)

    generated = []

    print("Generating UI textures...")
    print(f"Output directory: {OUTPUT_BASE}")
    print()

    # --- frames/ ---
    print("[frames/] Generating panel and button textures...")

    p = gen_panel_iron(os.path.join(OUTPUT_BASE, "frames", "panel_iron.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_panel_stone(os.path.join(OUTPUT_BASE, "frames", "panel_stone.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_panel_parchment(os.path.join(OUTPUT_BASE, "frames", "panel_parchment.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_slot(os.path.join(OUTPUT_BASE, "frames", "slot_empty.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_slot(os.path.join(OUTPUT_BASE, "frames", "slot_hover.png"),
                 edge_glow="#C8A84E", glow_alpha=102)  # 40% of 255
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_slot(os.path.join(OUTPUT_BASE, "frames", "slot_selected.png"),
                 edge_glow="#C8A84E", glow_alpha=255, inner_glow=True)
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_button(os.path.join(OUTPUT_BASE, "frames", "button_normal.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_button(os.path.join(OUTPUT_BASE, "frames", "button_hover.png"), gold_tint=True)
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_button(os.path.join(OUTPUT_BASE, "frames", "button_pressed.png"), raised=False)
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bar_frame(os.path.join(OUTPUT_BASE, "frames", "bar_frame.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_tab(os.path.join(OUTPUT_BASE, "frames", "tab_active.png"), active=True)
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_tab(os.path.join(OUTPUT_BASE, "frames", "tab_inactive.png"), active=False)
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    # --- orbs/ ---
    print("[orbs/] Generating orb textures...")

    p = gen_orb_frame(os.path.join(OUTPUT_BASE, "orbs", "orb_frame.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_orb_mask(os.path.join(OUTPUT_BASE, "orbs", "orb_mask.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    # --- backgrounds/ ---
    print("[backgrounds/] Generating background textures...")

    p = gen_bg_stone_tile(os.path.join(OUTPUT_BASE, "backgrounds", "bg_stone_tile.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bg_leather(os.path.join(OUTPUT_BASE, "backgrounds", "bg_leather.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bg_metal_brushed(os.path.join(OUTPUT_BASE, "backgrounds", "bg_metal_brushed.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_action_bar_bg(os.path.join(OUTPUT_BASE, "backgrounds", "action_bar_bg.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    # --- decorative/ ---
    print("[decorative/] Generating decorative textures...")

    p = gen_divider_ornate(os.path.join(OUTPUT_BASE, "decorative", "divider_ornate.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    corner_paths = gen_corner_ornate(os.path.join(OUTPUT_BASE, "decorative", "corner_ornate_tl.png"))
    generated.extend(corner_paths)
    for cp in corner_paths:
        print(f"  -> {os.path.basename(cp)}")

    # --- book textures (Tome of Fallen Heroes) ---
    print("[frames/] Generating book textures...")

    p = gen_book_cover(os.path.join(OUTPUT_BASE, "frames", "book_cover.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_book_page(os.path.join(OUTPUT_BASE, "backgrounds", "book_page.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_book_spine(os.path.join(OUTPUT_BASE, "frames", "book_spine.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bookmark_tab(os.path.join(OUTPUT_BASE, "frames", "bookmark_tab.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_gutter_shadow(os.path.join(OUTPUT_BASE, "frames", "gutter_shadow.png"))
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bar_fill(os.path.join(OUTPUT_BASE, "decorative", "xp_bar_fill.png"),
                     "#E8D084", "#6B5A2E")
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bar_fill(os.path.join(OUTPUT_BASE, "decorative", "health_bar_fill.png"),
                     "#CC2222", "#4A0E0E")
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    p = gen_bar_fill(os.path.join(OUTPUT_BASE, "decorative", "voice_bar_fill.png"),
                     "#2266CC", "#0E2A4A")
    generated.append(p)
    print(f"  -> {os.path.basename(p)}")

    print()
    print("=" * 60)
    print(f"TOTAL FILES GENERATED: {len(generated)}")
    print("=" * 60)
    print()

    # List all output files
    for subdir in SUBDIRS:
        subdir_path = os.path.join(OUTPUT_BASE, subdir)
        files = sorted(os.listdir(subdir_path))
        png_files = [f for f in files if f.endswith(".png")]
        print(f"{subdir}/ ({len(png_files)} files):")
        for f in png_files:
            full = os.path.join(subdir_path, f)
            size = os.path.getsize(full)
            img = Image.open(full)
            print(f"  {f:30s} {img.size[0]:4d}x{img.size[1]:<4d}  ({size:,} bytes)")
            img.close()
        print()


if __name__ == "__main__":
    main()
