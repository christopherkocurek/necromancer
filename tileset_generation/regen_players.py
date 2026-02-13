"""Regenerate player sprites using monster pipeline v3 techniques.
Magenta BG for humanoids, rembg processing, dark variants.
Does NOT modify the tileset — outputs to player_v2/ for review."""

import os, sys, json, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from io import BytesIO
from rembg import remove

# Load API key
env_path = Path(__file__).parent / ".env"
with open(env_path) as f:
    for line in f:
        if line.startswith("OPENAI_API_KEY="):
            API_KEY = line.strip().split("=", 1)[1]
            break

BG_COLOR = "#FF00FF"  # Magenta for ALL humanoids (Tier 8 lesson)

PREAMBLE = (
    "On a plain flat solid bright magenta background hex #FF00FF. "
    "A dark fantasy illustration. "
)

ANTI_HALO = (
    "Plain flat magenta background only, absolutely no other elements "
    "or shapes in the image. "
)

# 9 sprites to regenerate: (id, label, prompt)
SPRITES = [
    # --- ELVES ---
    ("lothlorien_m", "Elf/Lothlorien M",
     PREAMBLE +
     "Full body head to toe, centered, filling most of the frame. "
     "An ethereal male elf lord with long flowing silver-white hair. "
     "Wearing luminous silver-white robes with golden thread embroidery. "
     "One hand raised in blessing, the other holding a slender elven staff. "
     "Radiant pale skin, ageless noble face, tall and regal bearing. "
     "Solid opaque robes with well-defined edges. "
     "Golden and silver highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
    ("lothlorien_f", "Elf/Lothlorien F",
     PREAMBLE +
     "Full body head to toe, centered, filling most of the frame. "
     "An ethereal female elf lady with long flowing silver-white hair. "
     "Wearing a luminous silver-blue gown that flows to the ground. "
     "A circlet of silver stars on her brow. Graceful pose, hands clasped. "
     "Radiant pale skin, ageless beautiful face, tall and serene. "
     "Solid opaque gown with well-defined edges. "
     "Silver and ice-blue highlights only, no magenta tinting. "
     + ANTI_HALO
    ),

    # --- MEN ---
    ("gondor_f", "Man/Gondor F",
     PREAMBLE +
     "Full body head to toe, centered, filling most of the frame. "
     "A female knight of Gondor in bright polished silver plate armor. "
     "A white tabard bearing the White Tree of Gondor emblem over the armor. "
     "Dark hair pulled back, stern noble face. Holding a longsword at her side. "
     "Solid opaque armor with well-defined edges. "
     "Bright silver and white highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
    ("dunedain_f", "Man/Dunedain F",
     PREAMBLE +
     "Full body head to toe, centered, filling most of the frame. "
     "A female Dunedain ranger in dark leather armor with a hooded dark green cloak. "
     "A bright silver star brooch clasps the cloak at her throat. "
     "Holding a gleaming elven-steel longsword. Dark hair, weathered noble face. "
     "Solid opaque armor and cloak with well-defined edges. "
     "Silver brooch and blade highlights only, no magenta tinting. "
     + ANTI_HALO
    ),

    # --- ELVES (cont) ---
    ("greenwood_f", "Elf/Greenwood F",
     PREAMBLE +
     "Full body head to toe, centered, filling most of the frame. "
     "A female wood elf ranger of Mirkwood in forest-green leather armor. "
     "A dark green hooded cloak, wielding a longbow with arrow nocked. "
     "Auburn hair braided, sharp elven features, alert stance. "
     "Bow overlapping the torso for clear silhouette. "
     "Solid opaque armor and cloak with well-defined edges. "
     "Forest green and brown highlights only, no magenta tinting. "
     + ANTI_HALO
    ),

    # --- HOBBITS (all need "enlarged, filling 80% of the frame") ---
    ("shire_m", "Hobbit/Shire M",
     PREAMBLE +
     "Portrait from the waist up, enlarged, filling 80 percent of the frame. "
     "A male hobbit with curly brown hair and rosy cheeks. "
     "Wearing an earth-tone linen tunic with a leather vest and brass buttons. "
     "Carrying a walking stick over one shoulder. Warm friendly face, round build. "
     "Solid opaque clothing with well-defined edges. "
     "Warm brown and brass highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
    ("shire_f", "Hobbit/Shire F",
     PREAMBLE +
     "Portrait from the waist up, enlarged, filling 80 percent of the frame. "
     "A female hobbit with curly auburn hair and a warm smile. "
     "Wearing a cozy earth-tone dress with a patterned apron. "
     "A small wildflower tucked behind one ear. Round cheerful face. "
     "Solid opaque dress with well-defined edges. "
     "Warm brown and cream highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
    ("tooks_f", "Hobbit/Tooks F",
     PREAMBLE +
     "Portrait from the waist up, enlarged, filling 80 percent of the frame. "
     "An adventurous female hobbit with wild curly hair and bright eyes. "
     "Wearing a deep red leather vest over a cream tunic, a short sword at her belt. "
     "Confident smirk, slightly windswept. Braver than she looks. "
     "Solid opaque clothing with well-defined edges. "
     "Deep red and warm brown highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
    ("gamgees_f", "Hobbit/Gamgees F",
     PREAMBLE +
     "Portrait from the waist up, enlarged, filling 80 percent of the frame. "
     "A practical sturdy female hobbit with curly brown hair tied back. "
     "Wearing a simple brown work dress with a tan canvas gardening apron. "
     "Holding a small trowel. Warm weathered face, strong capable hands. "
     "Solid opaque clothing with well-defined edges. "
     "Warm brown and tan highlights only, no magenta tinting. "
     + ANTI_HALO
    ),
]

OUTPUT_DIR = Path(__file__).parent / "player_v2"
RAW_DIR = OUTPUT_DIR / "raw"
OUTPUT_DIR.mkdir(exist_ok=True)
RAW_DIR.mkdir(exist_ok=True)


def generate_sprite(sprite_id, prompt):
    """Generate a single DALL-E sprite."""
    print(f"  Generating {sprite_id}...")
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "style": "vivid",
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
    raw_path = RAW_DIR / f"{sprite_id}_raw.png"
    img.save(raw_path)
    print(f"  Raw saved: {sprite_id}")
    return sprite_id, img


def process_sprite(sprite_id, raw_img):
    """Process with rembg + magenta cleanup + resize to 64x64."""
    print(f"  Processing {sprite_id}...")

    # Step 1: rembg ML background removal
    raw_bytes = BytesIO()
    raw_img.save(raw_bytes, format="PNG")
    raw_bytes.seek(0)
    result_bytes = remove(raw_bytes.read())
    rembg_img = Image.open(BytesIO(result_bytes)).convert("RGBA")
    rembg_arr = np.array(rembg_img).astype(float)

    # Step 2: Color-merge recovery (recover non-magenta pixels rembg dropped)
    raw_arr = np.array(raw_img).astype(float)
    r, g, b = raw_arr[:,:,0]/255, raw_arr[:,:,1]/255, raw_arr[:,:,2]/255

    # Magenta detection: high R, low G, high B
    is_not_magenta = (g > 0.15) | ((r > 0.3) & (b < r * 0.7))
    color_mask = is_not_magenta.astype(float) * 255

    # Merge: OR of rembg alpha and color mask
    rembg_alpha = rembg_arr[:,:,3]
    combined_alpha = np.maximum(rembg_alpha, color_mask)

    # Apply combined alpha back to raw image colors
    result = raw_arr.copy()
    result[:,:,3] = combined_alpha

    # Step 3: Hard magenta remnant removal
    # Pixels that are strongly magenta (high R, low G, high B) -> transparent
    r_raw = raw_arr[:,:,0] / 255
    g_raw = raw_arr[:,:,1] / 255
    b_raw = raw_arr[:,:,2] / 255
    is_magenta = (r_raw > 0.6) & (g_raw < 0.3) & (b_raw > 0.5)
    result[:,:,3][is_magenta] = 0

    # Step 4: Soft edge cleanup - desaturate magenta-tinted edge pixels
    from scipy.ndimage import binary_erosion
    alpha_mask = result[:,:,3] > 10
    eroded = binary_erosion(alpha_mask, iterations=3)
    edge_zone = alpha_mask & ~eroded

    # In edge zone, if pixel has magenta hue (R high, G low, B high), desaturate
    for y in range(result.shape[0]):
        for x in range(result.shape[1]):
            if edge_zone[y, x]:
                r_px, g_px, b_px = result[y,x,0], result[y,x,1], result[y,x,2]
                # Magenta hue check
                if r_px > 100 and b_px > 100 and g_px < min(r_px, b_px) * 0.6:
                    gray = 0.299 * r_px + 0.587 * g_px + 0.114 * b_px
                    result[y,x,0] = result[y,x,0] * 0.3 + gray * 0.7
                    result[y,x,1] = result[y,x,1] * 0.3 + gray * 0.7
                    result[y,x,2] = result[y,x,2] * 0.3 + gray * 0.7

    result = np.clip(result, 0, 255).astype(np.uint8)
    processed = Image.fromarray(result)

    # Step 5: Auto-crop to content bounding box
    alpha_channel = np.array(processed)[:,:,3]
    rows = np.any(alpha_channel > 10, axis=1)
    cols = np.any(alpha_channel > 10, axis=0)
    if rows.any() and cols.any():
        rmin, rmax = np.where(rows)[0][[0, -1]]
        cmin, cmax = np.where(cols)[0][[0, -1]]
        # Add small padding
        pad = 5
        rmin = max(0, rmin - pad)
        rmax = min(processed.height - 1, rmax + pad)
        cmin = max(0, cmin - pad)
        cmax = min(processed.width - 1, cmax + pad)
        cropped = processed.crop((cmin, rmin, cmax + 1, rmax + 1))
    else:
        cropped = processed

    # Step 6: Resize to 64x64 with aspect ratio preservation
    w, h = cropped.size
    scale = min(64 / w, 64 / h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = cropped.resize((new_w, new_h), Image.NEAREST)

    # Center on 64x64 canvas
    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    offset_x = (64 - new_w) // 2
    offset_y = (64 - new_h) // 2
    canvas.paste(resized, (offset_x, offset_y), resized)

    # Save light variant
    light_path = OUTPUT_DIR / f"{sprite_id}_light.png"
    canvas.save(light_path)

    # Step 7: Dark variant (60% desat, 40% darken, 1.15x blue)
    arr = np.array(canvas).astype(float)
    r_ch, g_ch, b_ch, a_ch = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    gray = 0.299 * r_ch + 0.587 * g_ch + 0.114 * b_ch
    r_ch = r_ch * 0.4 + gray * 0.6
    g_ch = g_ch * 0.4 + gray * 0.6
    b_ch = b_ch * 0.4 + gray * 0.6
    r_ch *= 0.6
    g_ch *= 0.6
    b_ch = np.clip(b_ch * 0.6 * 1.15, 0, 255)
    dark_arr = np.stack([r_ch, g_ch, b_ch, a_ch], axis=2).astype(np.uint8)
    dark_img = Image.fromarray(dark_arr)
    dark_path = OUTPUT_DIR / f"{sprite_id}_dark.png"
    dark_img.save(dark_path)

    # Compute fill percentage
    fill = (np.array(canvas)[:,:,3] > 10).sum() / (64*64) * 100
    print(f"  Done: {sprite_id} (fill: {fill:.1f}%)")
    return sprite_id, canvas, dark_img


def build_comparison_html(results):
    """Build side-by-side old vs new comparison HTML."""
    ts = Image.open(Path(__file__).parent.parent / "assets" / "sprites" / "necromancer_dcss_tileset.png").convert("RGBA")

    # Map sprite IDs to tileset positions (col, row) for old sprites
    old_positions = {
        "lothlorien_m": (0, 6), "lothlorien_f": (1, 6),
        "gondor_f": (5, 7), "dunedain_f": (1, 7),
        "greenwood_f": (5, 6),
        "shire_m": (0, 9), "shire_f": (1, 9),
        "tooks_f": (3, 9), "gamgees_f": (5, 9),
    }

    SCALE = 6
    compare_dir = OUTPUT_DIR / "compare"
    compare_dir.mkdir(exist_ok=True)

    # Extract old sprites
    for sid, (col, row) in old_positions.items():
        x, y = col * 64, row * 64
        old = ts.crop((x, y, x + 64, y + 64))
        old_big = old.resize((64 * SCALE, 64 * SCALE), Image.NEAREST)
        old_big.save(compare_dir / f"{sid}_old.png")

    # Copy new sprites at scale
    for sid in results:
        new_img = Image.open(OUTPUT_DIR / f"{sid}_light.png")
        new_big = new_img.resize((64 * SCALE, 64 * SCALE), Image.NEAREST)
        new_big.save(compare_dir / f"{sid}_new.png")
        dark_img = Image.open(OUTPUT_DIR / f"{sid}_dark.png")
        dark_big = dark_img.resize((64 * SCALE, 64 * SCALE), Image.NEAREST)
        dark_big.save(compare_dir / f"{sid}_dark_new.png")

    # Also save old dark variants
    for sid, (col, row) in old_positions.items():
        x, y = (6 + col) * 64, row * 64
        old_dark = ts.crop((x, y, x + 64, y + 64))
        old_dark_big = old_dark.resize((64 * SCALE, 64 * SCALE), Image.NEAREST)
        old_dark_big.save(compare_dir / f"{sid}_old_dark.png")

    # Build HTML
    html = """<!DOCTYPE html>
<html><head><style>
body { background: #1a1a1a; color: #eee; font-family: monospace; padding: 20px; }
h1 { color: #ffcc00; }
h2 { color: #88ccff; border-bottom: 1px solid #444; padding-bottom: 8px; }
.row { display: flex; gap: 24px; margin-bottom: 32px; align-items: flex-start; }
.sprite-box { text-align: center; }
.sprite-box img { border: 2px solid #444; image-rendering: pixelated; }
.label { font-size: 14px; margin-top: 4px; }
.old { border-color: #cc4444 !important; }
.new { border-color: #44cc44 !important; }
.verdict { color: #ffcc00; font-size: 13px; margin-top: 4px; }
</style></head><body>
<h1>Player Sprite Regeneration — Old vs New</h1>
<p>Red border = OLD | Green border = NEW | Right side = dark variants</p>
"""
    for sid, label, _ in SPRITES:
        if sid not in results:
            continue
        html += f"<h2>{label}</h2>\n<div class='row'>\n"
        html += f"""
  <div class='sprite-box'>
    <img src='compare/{sid}_old.png' class='old' width='192' height='192'>
    <div class='label'>OLD (light)</div>
  </div>
  <div class='sprite-box'>
    <img src='compare/{sid}_new.png' class='new' width='192' height='192'>
    <div class='label'>NEW (light)</div>
  </div>
  <div class='sprite-box'>
    <img src='compare/{sid}_old_dark.png' class='old' width='192' height='192'>
    <div class='label'>OLD (dark)</div>
  </div>
  <div class='sprite-box'>
    <img src='compare/{sid}_dark_new.png' class='new' width='192' height='192'>
    <div class='label'>NEW (dark)</div>
  </div>
"""
        html += "</div>\n"

    html += "</body></html>"
    html_path = Path(__file__).parent / "player_regen_review.html"
    with open(html_path, "w") as f:
        f.write(html)
    print(f"\nReview HTML: {html_path}")


def main():
    # Allow filtering by ID
    target_ids = set()
    if len(sys.argv) > 1:
        target_ids = set(sys.argv[1:])

    sprites_to_gen = [(sid, label, prompt) for sid, label, prompt in SPRITES
                      if not target_ids or sid in target_ids]

    print(f"=== Player Sprite Regeneration ({len(sprites_to_gen)} sprites) ===\n")

    # Phase 1: Generate raw images
    raw_results = {}
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {}
        for sid, label, prompt in sprites_to_gen:
            f = executor.submit(generate_sprite, sid, prompt)
            futures[f] = sid

        for f in as_completed(futures):
            sid = futures[f]
            try:
                _, img = f.result()
                raw_results[sid] = img
            except Exception as e:
                print(f"  FAILED {sid}: {e}")

    print(f"\n=== Generated {len(raw_results)}/{len(sprites_to_gen)} raw images ===\n")

    # Phase 2: Process with rembg
    processed = {}
    for sid, raw_img in raw_results.items():
        try:
            _, light, dark = process_sprite(sid, raw_img)
            processed[sid] = (light, dark)
        except Exception as e:
            print(f"  PROCESS FAILED {sid}: {e}")
            import traceback
            traceback.print_exc()

    print(f"\n=== Processed {len(processed)}/{len(raw_results)} sprites ===\n")

    # Phase 3: Build comparison HTML
    print("=== Building comparison review ===")
    build_comparison_html(processed)

    print("\n=== Done! ===")
    print(f"Light + dark sprites saved to: {OUTPUT_DIR}")
    print("Open player_regen_review.html to compare old vs new")


if __name__ == "__main__":
    main()
