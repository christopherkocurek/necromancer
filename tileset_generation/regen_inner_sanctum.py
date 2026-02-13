#!/usr/bin/env python3
"""
Inner Sanctum (Layer 6) Tile Generation — Sauron's Throne Antechamber

Palette: obsidian black (#1a1108), dark gold (#b8860b),
         scorched bronze (#4a3728), deep crimson (#8b0000),
         burnt umber (#1f1410).
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
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "inner_sanctum"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "inner_sanctum"
OUTER_PITS_RAW = SCRIPT_DIR / "layer_tiles" / "raw" / "outer_pits_v2"
RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

load_dotenv(SCRIPT_DIR / ".env")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Ancient dark fortress illustration. "
    "Palette: polished obsidian black stone with tarnished dark gold inlay veins. "
    "Fills the entire frame edge to edge. No text. "
)

TILES = {
    "floor": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Polished obsidian-black flagstones fitted with precision. "
            "Thin tarnished dark gold veins trace the joints between stones. "
            "The surface is smooth and reflective like dark glass. "
            "Faint gold dust settles in the deeper cracks. "
            "Burnt umber undertones in the darkest areas. "
            "Seamless tileable polished obsidian floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Massive polished obsidian-black stone blocks in precise masonry. "
            "Tarnished dark gold geometric inlay patterns trace chevron shapes "
            "along a horizontal band across the center of the wall. "
            "Aged bronze brackets at regular intervals along the gold band. "
            "The stone surface is smooth and reflective. "
            "Seamless tileable polished obsidian wall texture."
        ),
    },
    "fallen_statue": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Polished obsidian floor with a toppled stone statue lying across it. "
            "The fallen figure is carved from black stone with dark gold trim on its armor. "
            "The statue is broken at the waist, upper body separated from legs. "
            "Aged bronze sword lies beside the fallen figure. "
            "Seamless tileable fallen statue on dark floor texture."
        ),
    },
    "trophy_plaque": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Polished obsidian wall with a tarnished gold rectangular plaque mounted on it. "
            "The plaque displays dark iron hooks holding trophies: a broken crown, a shattered blade. "
            "Aged bronze frame surrounds the plaque with geometric border patterns. "
            "The wall surface is smooth polished black stone. "
            "Seamless tileable trophy display on dark wall texture."
        ),
    },
}

PASTE_MAP = {
    'wall': [(12,22),(13,22)], 'floor': [(14,22),(15,22)],
    'door_closed': [(16,22),(17,22)], 'door_open': [(18,22),(19,22)],
    'stairs_down': [(20,22),(21,22)], 'stairs_up': [(22,22),(23,22)],
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
    # Darken heavily
    result[:,:,:3] *= 0.65
    # Dark gold shift — boost red moderately, slight green for gold tone
    result[:,:,0] = np.minimum(result[:,:,0] * 1.20, 255)
    result[:,:,1] = np.minimum(result[:,:,1] * 1.00, 255)
    result[:,:,2] *= 0.75
    # Gold highlights on bright areas
    lum = np.mean(result[:,:,:3], axis=2)
    bright = lum > 50
    result[:,:,0] = np.where(bright, np.minimum(result[:,:,0] * 1.15, 255), result[:,:,0])
    result[:,:,1] = np.where(bright, np.minimum(result[:,:,1] * 1.05, 255), result[:,:,1])
    if direction == "up":
        very_bright = lum > 70
        result[:,:,0] = np.where(very_bright, np.minimum(result[:,:,0] * 1.15, 255), result[:,:,0])
    # Edge darken
    h, w = result.shape[:2]
    yd = np.minimum(np.arange(h)[:,None], np.arange(h-1,-1,-1)[:,None])
    xd = np.minimum(np.arange(w)[None,:], np.arange(w-1,-1,-1)[None,:])
    ed = np.minimum(yd, xd).astype(np.float64)
    darken = np.clip(1.0 - (ed/200)*0.15, 0.85, 1.0)
    for c in range(3): result[:,:,c] *= darken
    return Image.fromarray(result.clip(0,255).astype(np.uint8))

def generate_door_closed(wall_1024):
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size
    dl, dr = int(w*0.20), int(w*0.80)
    dt, db = int(h*0.10), h
    draw.rectangle([dl,dt,dr,db], fill=(14,10,6,255))
    # Door surface
    m = 20
    draw.rectangle([dl+m,dt+m,dr-m,db], fill=(26,17,8,255))
    for x in range(dl+m+35, dr-m, 65):
        draw.line([(x,dt+m),(x,db)], fill=(20,14,6,255), width=3)
    # Dark gold frame
    fw = 36
    gold = (184,134,11,255)
    gold_dim = (140,100,8,255)
    draw.rectangle([dl,dt,dr,dt+fw], fill=gold_dim)
    draw.rectangle([dl,dt,dl+fw,db], fill=gold_dim)
    draw.rectangle([dr-fw,dt,dr,db], fill=gold_dim)
    # Gold chevron pattern on door
    cx = w//2
    for y_off in [int(h*0.30), int(h*0.50), int(h*0.70)]:
        pts = [(cx-80,y_off), (cx,y_off-30), (cx+80,y_off)]
        draw.line(pts, fill=gold, width=4)
        pts2 = [(cx-80,y_off+15), (cx,y_off-15), (cx+80,y_off+15)]
        draw.line(pts2, fill=gold_dim, width=3)
    # Bronze ring handle
    hx, hy = cx, int(h*0.55)
    draw.ellipse([hx-20,hy-20,hx+20,hy+20], outline=(74,55,40,255), fill=None, width=5)
    draw.ellipse([hx-12,hy-12,hx+12,hy+12], outline=(90,68,48,255), fill=None, width=3)
    # Deep crimson glow from behind
    glow = Image.new("RGBA", img.size, (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    gd.rectangle([dl-10,dt,dl+8,db], fill=(139,0,0,20))
    gd.rectangle([dr-8,dt,dr+10,db], fill=(139,0,0,20))
    gd.ellipse([cx-140,h-70,cx+140,h+40], fill=(139,0,0,25))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=18))
    img = Image.alpha_composite(img, glow)
    return img

def generate_door_open(wall_1024):
    img = wall_1024.copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size
    dl, dr = int(w*0.20), int(w*0.80)
    dt, db = int(h*0.10), h
    draw.rectangle([dl,dt,dr,db], fill=(8,6,4,255))
    fw = 36
    gold_dim = (140,100,8,255)
    draw.rectangle([dl,dt,dr,dt+fw], fill=gold_dim)
    draw.rectangle([dl,dt,dl+fw,db], fill=gold_dim)
    draw.rectangle([dr-fw,dt,dr,db], fill=gold_dim)
    # Panel swung
    draw.rectangle([dr-fw-50,dt+fw,dr-fw,db], fill=(26,17,8,255))
    # Deep crimson + gold glow from beyond
    glow = Image.new("RGBA", img.size, (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    cx, cy = w//2, int(h*0.5)
    gd.ellipse([cx-180,cy-130,cx+180,cy+130], fill=(139,40,0,30))
    gd.ellipse([cx-90,cy-60,cx+90,cy+60], fill=(184,134,11,20))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=25))
    img = Image.alpha_composite(img, glow)
    return img

# ---- Procedural env tiles ----

def generate_gilded_floor(floor_64):
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    rng = np.random.RandomState(601)
    mask = np.zeros((h,w), dtype=np.float64)
    for _ in range(10):
        ox, oy = rng.randint(5,w-5), rng.randint(5,h-5)
        rx, ry = rng.randint(8,18), rng.randint(8,18)
        yy, xx = np.ogrid[:h,:w]
        e = ((xx-ox)/rx)**2 + ((yy-oy)/ry)**2
        mask = np.maximum(mask, np.clip(1.0-e, 0, 1))
    mask = gaussian_filter(mask, sigma=3)
    mask = np.clip(mask, 0, 1)
    gold = np.array([184,134,11])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - mask*0.45) + gold[c] * mask*0.45
    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def generate_eye_sigil(floor_64):
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    cx, cy = w//2, h//2
    yy, xx = np.ogrid[:h,:w]
    dist = np.sqrt((xx-cx)**2 + (yy-cy)**2)
    # Eye shape — almond
    angle = np.arctan2(yy-cy, xx-cx)
    eye_r = 20 * (1 - 0.5 * np.abs(np.sin(angle)))
    eye_mask = np.clip(1.0 - (dist / eye_r), 0, 1)
    eye_mask = gaussian_filter(eye_mask, sigma=1.5)
    # Vertical pupil
    pupil = np.exp(-((xx-cx)**2/(2*3**2) + (yy-cy)**2/(2*12**2)))
    combined = np.clip(eye_mask * 0.7 + pupil * 0.8, 0, 1)
    # Outer ring
    ring = np.exp(-((dist-22)**2/(2*2.5**2)))
    combined = np.clip(combined + ring * 0.6, 0, 1)
    glow = gaussian_filter(combined, sigma=3) * 0.3
    combined = np.clip(combined + glow, 0, 1)
    # Gold-crimson gradient
    gold = np.array([184,134,11])
    crimson = np.array([180,40,0])
    color = gold * 0.6 + crimson * 0.4
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1 - combined*0.8) + color[c] * combined*0.8
    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def generate_crucible(floor_64):
    arr = np.array(floor_64).astype(np.float64)
    h, w = arr.shape[:2]
    cx, cy = w//2, h//2
    yy, xx = np.ogrid[:h,:w]
    dist = np.sqrt((xx-cx)**2 + (yy-cy)**2)
    # Bronze rim
    rim = np.exp(-((dist-18)**2/(2*2.5**2)))
    bronze = np.array([74,55,40])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1-rim*0.8) + bronze[c] * rim*0.8
    # Dark interior
    inner = np.clip(1.0 - dist/15, 0, 1)
    inner = gaussian_filter(inner, sigma=2)
    dark = np.array([15,8,20])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] * (1-inner*0.85) + dark[c] * inner*0.85
    # Faint crimson shimmer
    shimmer = gaussian_filter(inner, sigma=3) * inner
    crim = np.array([139,0,0])
    for c in range(3):
        arr[:,:,c] = arr[:,:,c] + crim[c] * shimmer * 0.15
    arr[:,:,3] = 255
    return Image.fromarray(arr.clip(0,255).astype(np.uint8))

def generate_gold_dust(floor_64):
    img = floor_64.copy()
    draw = ImageDraw.Draw(img)
    rng = np.random.RandomState(602)
    for _ in range(20):
        x, y = rng.randint(4,60), rng.randint(4,60)
        r = rng.randint(1,2)
        bright = rng.randint(150,200)
        draw.ellipse([x-r,y-r,x+r,y+r], fill=(bright,int(bright*0.72),int(bright*0.15),180))
    for _ in range(5):
        x, y = rng.randint(8,56), rng.randint(8,56)
        l = rng.randint(3,7)
        a = rng.uniform(0,3.14)
        dx, dy = int(l*np.cos(a)), int(l*np.sin(a))
        draw.line([(x,y),(x+dx,y+dy)], fill=(160,120,10,150), width=1)
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
    print("="*60 + "\nINNER SANCTUM TILE GENERATION\n" + "="*60)

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
        for n, f in [("gilded_floor",generate_gilded_floor),("eye_sigil",generate_eye_sigil),
                      ("crucible",generate_crucible),("gold_dust",generate_gold_dust)]:
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
