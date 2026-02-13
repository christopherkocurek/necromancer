"""Generate DALL-E terrain tiles for the 8 missing row 18 env slots."""
import os, sys, json, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from PIL import Image, ImageEnhance, ImageFilter
import numpy as np
from io import BytesIO

# Load API key
env_path = Path(__file__).parent / ".env"
with open(env_path) as f:
    for line in f:
        if line.startswith("OPENAI_API_KEY="):
            API_KEY = line.strip().split("=", 1)[1]
            break

PREAMBLE = (
    "Seamless tileable texture. Top-down dungeon tile viewed from above. "
    "Retro low-resolution blocky painting style with thick visible brushstrokes. "
    "Lines at least 12 pixels wide. Dark fantasy underground dungeon. "
)

# 8 terrain types: (name, row18_light_col, prompt_suffix)
TERRAIN_TILES = [
    ("web", 0, 
     PREAMBLE +
     "Grey stone flagstone floor covered with thick white-grey spider webs. "
     "Dense cobwebs stretch across the tile in irregular patterns. "
     "Silky strands form a messy web canopy over dark stone. "
     "Muted grey-white palette with dusty stone underneath."
    ),
    ("dark_pool", 2,
     PREAMBLE +
     "Grey stone flagstone floor with a pool of dark still water in the center. "
     "The water is inky black-blue, reflecting faint cold light. "
     "Stone edges crumble into the dark water. Subtle ripples on the surface. "
     "Cold blue-black palette, ominous and deep."
    ),
    ("morgul_rune", 4,
     PREAMBLE +
     "Grey stone flagstone floor with glowing violet-purple arcane runes carved into the stone. "
     "The runes form angular Elvish-style script in a circular pattern. "
     "Faint purple magical glow emanates from the carved lines. "
     "Dark stone with bright violet luminous lines. Sinister magical energy."
    ),
    ("shadow_brazier", 6,
     PREAMBLE +
     "Top-down view of a dark iron brazier standing on grey stone floor. "
     "The brazier is a round iron bowl on a tripod base, seen from directly above. "
     "Dark shadowy purple-black flames flicker inside the bowl. "
     "Anti-light effect — shadows radiate outward from the brazier. Dark iron and purple fire."
    ),
    ("glyph_of_warding", 8,
     PREAMBLE +
     "Grey stone flagstone floor with a protective golden-white magical ward circle. "
     "Concentric rings of light form a glowing sigil on the floor. "
     "Bright warm golden light emanates from clean geometric lines. "
     "Elvish protective rune, radiant and pure against dark stone."
    ),
    ("inscription", 10,
     PREAMBLE +
     "Grey stone flagstone floor with ancient text carved deeply into the stone surface. "
     "Rows of angular runic script chiseled into worn stone. "
     "The carved letters are weathered but legible, filled with shadow. "
     "Muted stone-grey palette, aged and scholarly. No magical glow."
    ),
    ("shadow_floor", 12,
     PREAMBLE +
     "Grey stone flagstone floor corrupted by creeping shadow tendrils. "
     "Dark black-purple wisps of shadow crawl across cracked stone. "
     "The floor looks partially dissolved by darkness, edges eaten away. "
     "Very dark palette — black shadow veins on dark grey stone. Ominous corruption."
    ),
    ("throne_dais", 14,
     PREAMBLE +
     "Ornate raised stone platform floor viewed from above. "
     "Polished dark granite with gold inlay patterns forming a decorative border. "
     "Rich dark stone with metallic gold geometric trim. "
     "Regal and imposing. Dark obsidian-grey stone with bright gold accents."
    ),
]

OUTPUT_DIR = Path(__file__).parent / "row18_env"
OUTPUT_DIR.mkdir(exist_ok=True)

def generate_tile(name, prompt):
    """Generate a single DALL-E tile."""
    print(f"  Generating {name}...")
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "style": "natural",
        "quality": "standard"
    }
    
    resp = requests.post("https://api.openai.com/v1/images/generations",
                        headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    data = resp.json()
    url = data["data"][0]["url"]
    
    img_resp = requests.get(url, timeout=60)
    img = Image.open(BytesIO(img_resp.content)).convert("RGBA")
    
    # Save raw 1024x1024
    raw_path = OUTPUT_DIR / f"{name}_raw.png"
    img.save(raw_path)
    
    # Downscale to 64x64 with NEAREST
    light = img.resize((64, 64), Image.NEAREST)
    light_path = OUTPUT_DIR / f"{name}_light.png"
    light.save(light_path)
    
    # Create dark variant: 60% desaturate, 40% darken, 1.15x blue tint
    arr = np.array(light).astype(float)
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    
    # Desaturate 60%
    gray = 0.299 * r + 0.587 * g + 0.114 * b
    r = r * 0.4 + gray * 0.6
    g = g * 0.4 + gray * 0.6
    b = b * 0.4 + gray * 0.6
    
    # Darken 40%
    r *= 0.6
    g *= 0.6
    b *= 0.6
    
    # Blue tint 1.15x
    b = np.clip(b * 1.15, 0, 255)
    
    dark = np.stack([r, g, b, a], axis=2).astype(np.uint8)
    dark_img = Image.fromarray(dark)
    dark_path = OUTPUT_DIR / f"{name}_dark.png"
    dark_img.save(dark_path)
    
    print(f"  Done: {name}")
    return name, light, dark_img

def integrate_into_tileset(tiles):
    """Paste all generated tiles into the tileset at row 18 positions."""
    tileset_path = Path(__file__).parent.parent / "assets" / "sprites" / "necromancer_dcss_tileset.png"
    ts = Image.open(tileset_path).convert("RGBA")
    ts_arr = np.array(ts)
    
    for name, col, _ in TERRAIN_TILES:
        if name not in tiles:
            print(f"  SKIPPED {name} (generation failed)")
            continue
        light_img, dark_img = tiles[name]
        
        y = 18 * 64
        lx = col * 64
        dx = (col + 1) * 64
        
        ts_arr[y:y+64, lx:lx+64] = np.array(light_img)
        ts_arr[y:y+64, dx:dx+64] = np.array(dark_img)
        print(f"  Integrated {name} at ({col},18)/({col+1},18)")
    
    result = Image.fromarray(ts_arr)
    result.save(tileset_path)
    print(f"  Tileset saved: {tileset_path}")

def main():
    print(f"=== Row 18 Env Tile Generation ({len(TERRAIN_TILES)} tiles) ===\n")
    
    results = {}
    # Generate with 4 parallel workers
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {}
        for name, col, prompt in TERRAIN_TILES:
            f = executor.submit(generate_tile, name, prompt)
            futures[f] = name
        
        for f in as_completed(futures):
            name = futures[f]
            try:
                _, light, dark = f.result()
                results[name] = (light, dark)
            except Exception as e:
                print(f"  FAILED {name}: {e}")
    
    print(f"\n=== Generated {len(results)}/{len(TERRAIN_TILES)} tiles ===\n")
    
    print("=== Integrating into tileset ===")
    integrate_into_tileset(results)
    
    print("\n=== Done! ===")
    print(f"Raw + processed tiles saved to: {OUTPUT_DIR}")
    print("Remember to clear .godot/imported/ and reimport in editor!")

if __name__ == "__main__":
    main()
