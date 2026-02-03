#!/usr/bin/env python3
"""
Create clean environmental tiles programmatically.
No AI needed - these should be simple, clear, tileable patterns.
"""

from PIL import Image, ImageDraw
import random
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
FINAL_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf" / "final" / "terrain"
FINAL_DIR.mkdir(parents=True, exist_ok=True)

SIZE = 64


def create_darkness():
    """F:0 - Pure black darkness tile."""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 255))
    return img


def create_stone_floor():
    """F:1 - Simple gray cobblestone floor."""
    img = Image.new('RGBA', (SIZE, SIZE), (80, 80, 85, 255))
    draw = ImageDraw.Draw(img)

    # Draw simple grid of stones
    stone_size = 16
    for y in range(0, SIZE, stone_size):
        for x in range(0, SIZE, stone_size):
            # Slight color variation per stone
            variation = random.randint(-10, 10)
            color = (80 + variation, 80 + variation, 85 + variation, 255)

            # Draw stone with slight gap
            draw.rectangle([x+1, y+1, x+stone_size-1, y+stone_size-1], fill=color)

    # Draw mortar lines (darker)
    mortar = (50, 50, 55, 255)
    for y in range(0, SIZE, stone_size):
        draw.line([(0, y), (SIZE, y)], fill=mortar, width=1)
    for x in range(0, SIZE, stone_size):
        draw.line([(x, 0), (x, SIZE)], fill=mortar, width=1)

    return img


def create_dark_wall():
    """F:56 - Dark stone wall - clearly impassable."""
    img = Image.new('RGBA', (SIZE, SIZE), (35, 35, 40, 255))
    draw = ImageDraw.Draw(img)

    # Draw darker brick pattern
    brick_h = 12
    brick_w = 24

    for row, y in enumerate(range(0, SIZE, brick_h)):
        offset = (brick_w // 2) if row % 2 else 0
        for x in range(-brick_w, SIZE + brick_w, brick_w):
            ax = x + offset
            variation = random.randint(-5, 5)
            color = (35 + variation, 35 + variation, 40 + variation, 255)
            draw.rectangle([ax+1, y+1, ax+brick_w-1, y+brick_h-1], fill=color)

    # Mortar lines
    mortar = (25, 25, 30, 255)
    for y in range(0, SIZE, brick_h):
        draw.line([(0, y), (SIZE, y)], fill=mortar, width=1)

    return img


def create_fading_daylight():
    """F:9 - Floor with warmer daylight tint."""
    img = Image.new('RGBA', (SIZE, SIZE), (90, 85, 75, 255))
    draw = ImageDraw.Draw(img)

    stone_size = 16
    for y in range(0, SIZE, stone_size):
        for x in range(0, SIZE, stone_size):
            variation = random.randint(-8, 8)
            # Warmer tan/yellow tint
            color = (90 + variation, 85 + variation, 75 + variation, 255)
            draw.rectangle([x+1, y+1, x+stone_size-1, y+stone_size-1], fill=color)

    mortar = (60, 55, 50, 255)
    for y in range(0, SIZE, stone_size):
        draw.line([(0, y), (SIZE, y)], fill=mortar, width=1)
    for x in range(0, SIZE, stone_size):
        draw.line([(x, 0), (x, SIZE)], fill=mortar, width=1)

    return img


def create_bloodstain():
    """F:31 - Stone floor with blood splatter."""
    # Start with stone floor
    img = create_stone_floor()
    draw = ImageDraw.Draw(img)

    # Add blood splatters
    blood_color = (100, 20, 20, 200)

    # Main pool
    draw.ellipse([20, 20, 50, 45], fill=blood_color)

    # Smaller splatters
    for _ in range(5):
        x = random.randint(10, 54)
        y = random.randint(10, 54)
        r = random.randint(3, 8)
        draw.ellipse([x, y, x+r, y+r], fill=blood_color)

    return img


def create_vine_floor():
    """F:86 - Stone floor with green vines."""
    img = create_stone_floor()
    draw = ImageDraw.Draw(img)

    vine_color = (30, 70, 30, 180)

    # Draw curving vines
    for _ in range(3):
        x = random.randint(0, SIZE)
        y = random.randint(0, SIZE)
        for _ in range(20):
            dx = random.randint(-5, 5)
            dy = random.randint(-5, 5)
            draw.ellipse([x, y, x+4, y+4], fill=vine_color)
            x = (x + dx) % SIZE
            y = (y + dy) % SIZE

    return img


def create_forest_floor():
    """F:87 - Natural brown earth with leaves."""
    img = Image.new('RGBA', (SIZE, SIZE), (70, 55, 40, 255))
    draw = ImageDraw.Draw(img)

    # Add texture variation
    for _ in range(100):
        x = random.randint(0, SIZE-3)
        y = random.randint(0, SIZE-3)
        variation = random.randint(-15, 15)
        color = (70 + variation, 55 + variation, 40 + variation, 255)
        draw.rectangle([x, y, x+2, y+2], fill=color)

    # Add some leaves
    leaf_colors = [(80, 60, 30, 255), (60, 70, 30, 255), (90, 50, 20, 255)]
    for _ in range(8):
        x = random.randint(5, SIZE-10)
        y = random.randint(5, SIZE-10)
        color = random.choice(leaf_colors)
        draw.ellipse([x, y, x+5, y+3], fill=color)

    return img


def create_dark_pool():
    """F:12 - Dark water pool."""
    img = Image.new('RGBA', (SIZE, SIZE), (20, 30, 50, 255))
    draw = ImageDraw.Draw(img)

    # Stone border
    border = (60, 60, 65, 255)
    draw.rectangle([0, 0, SIZE-1, 3], fill=border)
    draw.rectangle([0, SIZE-4, SIZE-1, SIZE-1], fill=border)
    draw.rectangle([0, 0, 3, SIZE-1], fill=border)
    draw.rectangle([SIZE-4, 0, SIZE-1, SIZE-1], fill=border)

    # Water ripples
    ripple = (25, 35, 60, 255)
    for _ in range(3):
        cx = random.randint(20, 44)
        cy = random.randint(20, 44)
        for r in range(5, 20, 5):
            draw.ellipse([cx-r, cy-r, cx+r, cy+r], outline=ripple)

    return img


def create_poison_stream():
    """F:84 - Bright green toxic liquid."""
    img = Image.new('RGBA', (SIZE, SIZE), (30, 150, 30, 255))
    draw = ImageDraw.Draw(img)

    # Stone edges
    edge = (60, 60, 65, 255)
    draw.rectangle([0, 0, SIZE-1, 5], fill=edge)
    draw.rectangle([0, SIZE-6, SIZE-1, SIZE-1], fill=edge)

    # Bubbles
    bubble = (50, 200, 50, 255)
    for _ in range(6):
        x = random.randint(10, 54)
        y = random.randint(10, 54)
        r = random.randint(2, 5)
        draw.ellipse([x, y, x+r, y+r], fill=bubble)

    return img


def create_hidden_passage():
    """F:48 - Wall with subtle crack."""
    img = create_dark_wall()
    draw = ImageDraw.Draw(img)

    # Vertical crack down middle
    crack = (15, 15, 20, 255)
    for y in range(0, SIZE):
        x = 32 + random.randint(-2, 2)
        draw.line([(x, y), (x, y+1)], fill=crack, width=1)

    return img


def create_tangled_roots():
    """F:85 - Brown root wall."""
    img = Image.new('RGBA', (SIZE, SIZE), (50, 35, 25, 255))
    draw = ImageDraw.Draw(img)

    # Draw intertwining roots
    root_color = (70, 50, 35, 255)
    root_dark = (40, 25, 15, 255)

    for _ in range(15):
        x1 = random.randint(0, SIZE)
        y1 = random.randint(0, SIZE)
        x2 = random.randint(0, SIZE)
        y2 = random.randint(0, SIZE)
        draw.line([(x1, y1), (x2, y2)], fill=root_color, width=4)
        draw.line([(x1+1, y1+1), (x2+1, y2+1)], fill=root_dark, width=2)

    return img


def create_open_door():
    """F:4 - Open doorway."""
    img = Image.new('RGBA', (SIZE, SIZE), (80, 80, 85, 255))  # Floor visible
    draw = ImageDraw.Draw(img)

    # Stone doorframe
    frame = (60, 60, 65, 255)
    draw.rectangle([0, 0, 12, SIZE-1], fill=frame)
    draw.rectangle([SIZE-13, 0, SIZE-1, SIZE-1], fill=frame)

    # Wooden door (swung open against left wall)
    door = (80, 55, 35, 255)
    draw.rectangle([3, 5, 10, SIZE-6], fill=door)

    return img


def create_iron_door():
    """F:32 - Closed iron door."""
    img = Image.new('RGBA', (SIZE, SIZE), (45, 45, 50, 255))
    draw = ImageDraw.Draw(img)

    # Stone frame
    frame = (60, 60, 65, 255)
    draw.rectangle([0, 0, 8, SIZE-1], fill=frame)
    draw.rectangle([SIZE-9, 0, SIZE-1, SIZE-1], fill=frame)

    # Iron door
    iron = (55, 55, 60, 255)
    iron_dark = (40, 40, 45, 255)
    draw.rectangle([10, 2, SIZE-11, SIZE-3], fill=iron)

    # Horizontal bands
    for y in range(10, SIZE-10, 15):
        draw.rectangle([10, y, SIZE-11, y+4], fill=iron_dark)

    # Rivets
    rivet = (70, 70, 75, 255)
    for y in range(15, SIZE-15, 20):
        draw.ellipse([15, y, 19, y+4], fill=rivet)
        draw.ellipse([SIZE-20, y, SIZE-16, y+4], fill=rivet)

    return img


def create_stairs_up():
    """F:80 - Stairs going up."""
    img = Image.new('RGBA', (SIZE, SIZE), (70, 70, 75, 255))
    draw = ImageDraw.Draw(img)

    # Draw steps getting lighter (going up = toward light)
    step_h = 8
    for i, y in enumerate(range(SIZE-step_h, -1, -step_h)):
        brightness = 60 + i * 8
        color = (brightness, brightness, brightness + 5, 255)
        draw.rectangle([8, y, SIZE-9, y+step_h-1], fill=color)

    # Side walls
    wall = (50, 50, 55, 255)
    draw.rectangle([0, 0, 7, SIZE-1], fill=wall)
    draw.rectangle([SIZE-8, 0, SIZE-1, SIZE-1], fill=wall)

    # Up arrow indicator
    arrow = (200, 200, 200, 255)
    draw.polygon([(32, 15), (24, 30), (40, 30)], fill=arrow)

    return img


def create_stairs_down():
    """F:81 - Stairs going down."""
    img = Image.new('RGBA', (SIZE, SIZE), (50, 50, 55, 255))
    draw = ImageDraw.Draw(img)

    # Draw steps getting darker (going down = into darkness)
    step_h = 8
    for i, y in enumerate(range(0, SIZE, step_h)):
        brightness = 80 - i * 8
        brightness = max(20, brightness)
        color = (brightness, brightness, brightness + 5, 255)
        draw.rectangle([8, y, SIZE-9, y+step_h-1], fill=color)

    # Side walls
    wall = (40, 40, 45, 255)
    draw.rectangle([0, 0, 7, SIZE-1], fill=wall)
    draw.rectangle([SIZE-8, 0, SIZE-1, SIZE-1], fill=wall)

    # Down arrow indicator
    arrow = (150, 150, 150, 255)
    draw.polygon([(32, 48), (24, 33), (40, 33)], fill=arrow)

    return img


def main():
    print("Creating clean environmental tiles...")

    tiles = [
        ("t_00_darkness.png", create_darkness, "F:0 Darkness"),
        ("t_01_stone_floor.png", create_stone_floor, "F:1 Stone Floor"),
        ("t_56_dark_stone_wall.png", create_dark_wall, "F:56 Dark Wall"),
        ("t_09_fading_daylight.png", create_fading_daylight, "F:9 Daylight"),
        ("t_31_bloodstain.png", create_bloodstain, "F:31 Bloodstain"),
        ("t_86_vine_floor.png", create_vine_floor, "F:86 Vine Floor"),
        ("t_87_forest_floor.png", create_forest_floor, "F:87 Forest Floor"),
        ("t_12_dark_pool.png", create_dark_pool, "F:12 Dark Pool"),
        ("t_84_poison_stream.png", create_poison_stream, "F:84 Poison Stream"),
        ("t_48_hidden_passage.png", create_hidden_passage, "F:48 Hidden Passage"),
        ("t_85_tangled_roots.png", create_tangled_roots, "F:85 Tangled Roots"),
        ("t_04_open_door.png", create_open_door, "F:4 Open Door"),
        ("t_32_iron_door.png", create_iron_door, "F:32 Iron Door"),
        ("t_80_stairs_up.png", create_stairs_up, "F:80 Stairs Up"),
        ("t_81_stairs_down.png", create_stairs_down, "F:81 Stairs Down"),
    ]

    for filename, create_func, description in tiles:
        img = create_func()
        path = FINAL_DIR / filename
        img.save(path)
        print(f"  ✓ {description} -> {filename}")

    print(f"\nCreated {len(tiles)} environmental tiles in {FINAL_DIR}")
    print("\nNext: Run assemble_sheet.py and copy to app bundle")


if __name__ == "__main__":
    main()
