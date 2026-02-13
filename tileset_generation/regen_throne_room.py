#!/usr/bin/env python3
"""
Throne Room (Layer 7) Tile Generation — Sauron's Seat of Power

Final layer (F19-20). The culmination of the entire dungeon.
Not tarnished gold (that was Inner Sanctum) — BURNISHED, gleaming gold.
Void purple shadows. The lidless Eye's sickly green accent.

Palette: void black (#0a0812), burnished gold (#d4a017),
         void purple (#2d1045), Eye green (#4a6e28),
         iron black (#1a1a1e).
"""

import os, sys, io, base64, argparse, time
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter
from dotenv import load_dotenv
from openai import OpenAI

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "throne_room"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "throne_room"
OUTER_PITS_RAW = SCRIPT_DIR / "layer_tiles" / "raw" / "outer_pits_v2"
RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

load_dotenv(SCRIPT_DIR / ".env")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Ancient dark throne hall illustration. "
    "Palette: void-black stone with burnished bright gold inlay, deep purple shadows. "
    "Fills the entire frame edge to edge. No text. "
)

TILES = {
    "floor": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Polished void-black stone floor with mirror-smooth surface. "
            "Burnished bright gold geometric inlay lines trace precise patterns "
            "between the large square flagstones. "
            "Deep purple shadows pool in the joints between stones. "
            "The gold lines gleam as if freshly polished. "
            "Seamless tileable polished black throne room floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Massive void-black stone blocks in perfect masonry, mirror-polished surface. "
            "Wide burnished bright gold band runs horizontally across the center "
            "with interlocking geometric patterns and angular runes. "
            "Deep purple veins trace through the black stone above and below the gold band. "
            "Iron brackets at the corners of each stone block. "
            "Seamless tileable polished black throne room wall texture."
        ),
    },
    "obsidian_pillar": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Polished void-black floor with a massive circular obsidian column in the center. "
            "The pillar is perfectly smooth polished black stone with a burnished gold band "
            "encircling it at the midpoint. Geometric runes carved into the gold band. "
            "Deep purple light reflects off the pillar's surface. "
            "Seamless tileable obsidian pillar on dark floor texture."
        ),
    },
    "obsidian_relief": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Polished void-black wall with a carved bas-relief panel. "
            "The carving depicts a tall crowned figure with outstretched hands, "
            "burnished gold highlights on the figure's crown and armor. "
            "Deep purple shadow fills the carved recesses. "
            "Geometric border of gold interlocking triangles frames the carving. "
            "Seamless tileable carved relief on dark wall texture."
        ),
    },
}

# Row 23, Cols 0-11
PASTE_MAP = {
    'wall': [(0,23),(1,23)], 'floor': [(2,23),(3,23)],
    'door_closed': [(4,23),(5,23)], 'door_open': [(6,23),(7,23)],
    'stairs_down': [(8,23),(9,23)], 'stairs_up': [(10,23),(11,23)],
}

def make_dark_variant(light_img):
    arr = np.array(light_img).astype(np.float64)
    gray = np.mean(arr[:,:,:3], axis=2, keepdims=True)
    arr[:,:,:3] = arr[:,:,:3] * 0.4 + gray * 0.6
    arr[:,:,:3] *= 0.6
    arr[:,:,0] *= 0.85; arr[:,:,1] *= 0.90
    arr[:,:,2] = np.minimum(arr[:,:,2] * 1.15, 255)
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def recolor_stairs(src_path, direction):
    src = np.array(Image.open(src_path).convert("RGBA")).astype(np.float64)
    result = src.copy()
    r, g, b = result[:,:,0], result[:,:,1], result[:,:,2]
    # Remove green
    green_dom = (g > r * 1.05) & (g > 40)
    grey = (r + b) / 2
    result[:,:,1] = np.where(green_dom, g * 0.3 + grey * 0.7, g)
    # Darken heavily — deepest layer
    result[:,:,:3] *= 0.55
    # Void-purple shift
    result[:,:,0] = np.minimum(result[:,:,0] * 1.05, 255)
    result[:,:,1] *= 0.85
    result[:,:,2] = np.minimum(result[:,:,2] * 1.30, 255)
    # Gold highlights on bright areas
    lum = np.mean(result[:,:,:3], axis=2)
    bright = lum > 40
    result[:,:,0] = np.where(bright, np.minimum(result[:,:,0] * 1.25, 255), result[:,:,0])
    result[:,:,1] = np.where(bright, np.minimum(result[:,:,1] * 1.10, 255), result[:,:,1])
    if direction == "up":
        very_bright = lum > 60
        result[:,:,0] = np.where(very_bright, np.minimum(result[:,:,0] * 1.15, 255), result[:,:,0])
        result[:,:,1] = np.where(very_bright, np.minimum(result[:,:,1] * 1.05, 255), result[:,:,1])
    # Edge darken
    h, w = result.shape[:2]
    yd = np.minimum(np.arange(h)[:,None], np.arange(h-1,-1,-1)[:,None])
    xd = np.minimum(np.arange(w)[None,:], np.arange(w-1,-1,-1)[None,:])
    ed = np.minimum(yd, xd).astype(np.float64)
    darken = np.clip(1.0 - (ed/200)*0.20, 0.80, 1.0)
    for c in range(3): result[:,:,c] *= darken
    return Image.fromarray(result.clip(0,255).astype(np.uint8))

def generate_door_closed(wall_1024):
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size
    dl, dr = int(w*0.20), int(w*0.80)
    dt, db = int(h*0.10), h
    # Door recess
    draw.rectangle([dl,dt,dr,db], fill=(6,4,10,255))
    # Door surface — void black with purple undertone
    m = 20
    draw.rectangle([dl+m,dt+m,dr-m,db], fill=(14,10,20,255))
    # Vertical planks
    for x in range(dl+m+45, dr-m, 75):
        draw.line([(x,dt+m),(x,db)], fill=(10,8,16,255), width=3)
    # Burnished gold frame — thicker than inner sanctum
    fw = 40
    gold = (212,160,23,255)
    gold_dim = (170,128,18,255)
    draw.rectangle([dl,dt,dr,dt+fw], fill=gold)
    draw.rectangle([dl,dt,dl+fw,db], fill=gold_dim)
    draw.rectangle([dr-fw,dt,dr,db], fill=gold_dim)
    # Top lintel — brighter gold, double bar
    draw.rectangle([dl,dt,dr,dt+fw//2], fill=gold)
    # Lidless Eye motif at center of door
    cx, cy_eye = w//2, int(h*0.45)
    # Outer eye shape — almond
    eye_pts = []
    for i in range(60):
        angle = i * 6.28 / 60
        rx = 65 * abs(np.cos(angle))
        ry = 35 * (1 - 0.5 * abs(np.sin(angle)))
        ex = cx + int(rx * np.cos(angle))
        ey = cy_eye + int(ry * np.sin(angle))
        eye_pts.append((ex, ey))
    draw.polygon(eye_pts, outline=gold, fill=None)
    # Inner iris — sickly green
    eye_green = (74,110,40,200)
    draw.ellipse([cx-18,cy_eye-18,cx+18,cy_eye+18], fill=eye_green, outline=gold_dim, width=2)
    # Vertical pupil slit
    draw.line([(cx,cy_eye-14),(cx,cy_eye+14)], fill=(10,8,4,255), width=5)
    # Deep crimson glow from gaps
    glow = Image.new("RGBA", img.size, (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    gd.rectangle([dl-10,dt,dl+8,db], fill=(80,20,60,20))
    gd.rectangle([dr-8,dt,dr+10,db], fill=(80,20,60,20))
    gd.ellipse([cx-160,h-80,cx+160,h+50], fill=(60,15,80,25))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=20))
    img = Image.alpha_composite(img, glow)
    return img

def generate_door_open(wall_1024):
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size
    dl, dr = int(w*0.20), int(w*0.80)
    dt, db = int(h*0.10), h
    # Dark void beyond
    draw.rectangle([dl,dt,dr,db], fill=(4,2,8,255))
    fw = 40
    gold = (212,160,23,255)
    gold_dim = (170,128,18,255)
    draw.rectangle([dl,dt,dr,dt+fw], fill=gold)
    draw.rectangle([dl,dt,dl+fw,db], fill=gold_dim)
    draw.rectangle([dr-fw,dt,dr,db], fill=gold_dim)
    # Panel swung open — visible edge
    draw.rectangle([dr-fw-55,dt+fw,dr-fw,db], fill=(14,10,20,255))
    # Purple + gold glow from beyond
    glow = Image.new("RGBA", img.size, (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    cx, cy = w//2, int(h*0.5)
    gd.ellipse([cx-200,cy-140,cx+200,cy+140], fill=(60,20,80,30))
    gd.ellipse([cx-100,cy-70,cx+100,cy+70], fill=(212,160,23,18))
    gd.ellipse([cx-40,cy-40,cx+40,cy+40], fill=(74,110,40,15))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=28))
    img = Image.alpha_composite(img, glow)
    return img

# ---- Procedural env tiles ----

def generate_dominion_floor(floor_64):
    """Psychic oppression — concentric eye-ripple patterns in void purple."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    cx, cy = w//2, h//2
    yy, xx = np.ogrid[:h,:w]
    dist = np.sqrt((xx-cx)**2 + (yy-cy)**2)
    # Concentric rings
    rings = np.sin(dist * 0.5) * 0.5 + 0.5
    rings = gaussian_filter(rings, sigma=1.5)
    # Center fade
    center = np.clip(1.0 - dist/35, 0, 1)
    mask = rings * center * 0.6
    purple = np.array([45,16,69])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask) + purple[c] * mask
    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def generate_dark_fire(floor_64):
    """Cold-burning black flames — void purple + deep crimson."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    rng = np.random.RandomState(701)
    # Flame shapes — several overlapping ellipses
    mask = np.zeros((h,w), dtype=np.float64)
    for _ in range(6):
        fx, fy = rng.randint(10,w-10), rng.randint(10,h-10)
        rx, ry = rng.randint(6,14), rng.randint(10,22)
        yy, xx = np.ogrid[:h,:w]
        e = ((xx-fx)/rx)**2 + ((yy-fy)/ry)**2
        flame = np.clip(1.0 - e, 0, 1)
        mask = np.maximum(mask, flame)
    mask = gaussian_filter(mask, sigma=2)
    mask = np.clip(mask, 0, 1)
    # Two-tone: outer purple, inner crimson-black
    outer_color = np.array([50,10,70])
    inner_color = np.array([100,15,30])
    inner_mask = np.clip(mask * 2 - 0.5, 0, 1)
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask*0.7) + outer_color[c] * mask * 0.5 + inner_color[c] * inner_mask * 0.3
    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def generate_eye_glyph(floor_64):
    """Sauron's surveillance rune — lidless eye in gold-green."""
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    cx, cy = w//2, h//2
    yy, xx = np.ogrid[:h,:w]
    dist = np.sqrt((xx-cx)**2 + (yy-cy)**2)
    # Almond eye shape
    angle = np.arctan2(yy-cy, xx-cx)
    eye_r = 22 * (1 - 0.5 * np.abs(np.sin(angle)))
    eye_mask = np.clip(1.0 - (dist / eye_r), 0, 1)
    eye_mask = gaussian_filter(eye_mask, sigma=1.5)
    # Vertical pupil
    pupil = np.exp(-((xx-cx)**2/(2*3**2) + (yy-cy)**2/(2*13**2)))
    combined = np.clip(eye_mask * 0.7 + pupil * 0.9, 0, 1)
    # Outer circle
    ring = np.exp(-((dist-24)**2/(2*2.5**2)))
    combined = np.clip(combined + ring * 0.5, 0, 1)
    glow = gaussian_filter(combined, sigma=3) * 0.3
    combined = np.clip(combined + glow, 0, 1)
    # Green-gold color
    eye_color = np.array([120,150,40])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - combined*0.8) + eye_color[c] * combined*0.8
    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def generate_gold_inlay(floor_64):
    """Geometric gold filigree pattern on floor."""
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)
    gold = (212,160,23,140)
    gold_dim = (170,128,18,100)
    # Diamond pattern centered
    cx, cy = 32, 32
    for r in [12, 20, 28]:
        pts = [(cx,cy-r),(cx+r,cy),(cx,cy+r),(cx-r,cy),(cx,cy-r)]
        draw.line(pts, fill=gold if r == 20 else gold_dim, width=1)
    # Corner dots
    for dx, dy in [(-8,-8),(8,-8),(-8,8),(8,8)]:
        draw.ellipse([cx+dx-1,cy+dy-1,cx+dx+1,cy+dy+1], fill=gold)
    # Cross lines
    draw.line([(cx-6,cy),(cx+6,cy)], fill=gold_dim, width=1)
    draw.line([(cx,cy-6),(cx,cy+6)], fill=gold_dim, width=1)
    return img

# ---- Generation helpers ----

def generate_tile(name, tile_def, attempt=1):
    print(f"  [{name}] Generating (attempt {attempt})...")
    try:
        resp = client.images.generate(model="dall-e-3", prompt=tile_def["prompt"],
            size="1024x1024", quality="standard", style="natural", n=1, response_format="b64_json")
        return Image.open(io.BytesIO(base64.b64decode(resp.data[0].b64_json))).convert("RGBA")
    except Exception as e:
        print(f"  [{name}] FAILED: {e}"); return None

def check_edge_brightness(img, threshold=180):
    arr = np.array(img)[:,:,:3]
    edges = np.concatenate([arr[:10,:,:].reshape(-1,3), arr[-10:,:,:].reshape(-1,3),
                            arr[:,:10,:].reshape(-1,3), arr[:,-10:,:].reshape(-1,3)])
    m = edges.mean(); print(f"  Edge brightness: {m:.1f}"); return m > threshold

def process_tile(name, img_1024):
    l = img_1024.resize((64,64), Image.LANCZOS); return l, make_dark_variant(l)

def run_phase(phase_num, tiles, max_attempts=3):
    results = {}
    for name, td in tiles.items():
        for att in range(1, max_attempts+1):
            img = generate_tile(name, td, att)
            if img and not check_edge_brightness(img):
                img.save(RAW_DIR / f"{name}_1024.png")
                l, d = process_tile(name, img)
                l.save(PROCESSED_DIR / f"{name}_light.png")
                d.save(PROCESSED_DIR / f"{name}_dark.png")
                results[name] = {"img_1024": img}
                print(f"  [{name}] Saved"); break
            elif img: print(f"  [{name}] White edge, re-rolling..."); time.sleep(2)
            else: time.sleep(3)
        else: print(f"  [{name}] FAILED!")
    return results

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", type=int)
    parser.add_argument("--tile", type=str)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--attempts", type=int, default=3)
    parser.add_argument("--stairs", action="store_true")
    parser.add_argument("--doors", action="store_true")
    parser.add_argument("--env", action="store_true")
    args = parser.parse_args()
    print("="*60 + "\nTHRONE ROOM TILE GENERATION\n" + "="*60)

    if args.stairs:
        for d in ["down","up"]:
            src = OUTER_PITS_RAW / f"stairs_{d}_1024.png"
            if not src.exists(): print(f"  MISSING: {src}"); continue
            img = recolor_stairs(src, d)
            img.save(RAW_DIR / f"stairs_{d}_1024.png")
            l, dk = process_tile(f"stairs_{d}", img)
            l.save(PROCESSED_DIR / f"stairs_{d}_light.png")
            dk.save(PROCESSED_DIR / f"stairs_{d}_dark.png")
            print(f"  stairs_{d}: saved")
        return

    if args.doors:
        wall = Image.open(RAW_DIR / "wall_1024.png").convert("RGBA")
        for n, f in [("door_closed",generate_door_closed),("door_open",generate_door_open)]:
            img = f(wall); img.save(RAW_DIR / f"{n}_1024.png")
            l, dk = process_tile(n, img)
            l.save(PROCESSED_DIR / f"{n}_light.png"); dk.save(PROCESSED_DIR / f"{n}_dark.png")
            print(f"  {n}: saved")
        return

    if args.env:
        floor = Image.open(PROCESSED_DIR / "floor_light.png").convert("RGBA")
        for n, f in [("dominion_floor",generate_dominion_floor),("dark_fire",generate_dark_fire),
                      ("eye_glyph",generate_eye_glyph),("gold_inlay",generate_gold_inlay)]:
            l = f(floor); dk = make_dark_variant(l)
            l.save(PROCESSED_DIR / f"{n}_light.png"); dk.save(PROCESSED_DIR / f"{n}_dark.png")
            print(f"  {n}: saved")
        return

    if args.tile:
        selected = {args.tile: TILES[args.tile]}; phases = [TILES[args.tile]["phase"]]
    elif args.phase:
        selected = {k:v for k,v in TILES.items() if v["phase"]==args.phase}; phases = [args.phase]
    else:
        selected = TILES; phases = sorted(set(v["phase"] for v in TILES.values()))

    if args.dry_run:
        for n, td in selected.items():
            print(f"\n--- {n} ---\n{td['prompt'][:200]}...")
        return

    for p in sorted(phases):
        pt = {k:v for k,v in selected.items() if v["phase"]==p}
        if pt: print(f"\nPHASE {p}: {', '.join(pt.keys())}"); run_phase(p, pt, args.attempts)

if __name__ == "__main__":
    main()
