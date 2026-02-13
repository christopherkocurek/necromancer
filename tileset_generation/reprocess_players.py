"""Reprocess player sprites from raw DALL-E images using rembg ONLY (no color-merge).
Color-merge is too aggressive for humanoid sprites on magenta BG."""

from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
from rembg import remove
from io import BytesIO
from scipy.ndimage import binary_erosion

OUTPUT_DIR = Path(__file__).parent / "player_v2"
RAW_DIR = OUTPUT_DIR / "raw"

SPRITES = [
    "lothlorien_m", "lothlorien_f", "gondor_f", "dunedain_f",
    "greenwood_f", "shire_m", "shire_f", "tooks_f", "gamgees_f"
]


def process_rembg_only(sprite_id):
    """Process with rembg only — no color-merge recovery."""
    raw_path = RAW_DIR / f"{sprite_id}_raw.png"
    if not raw_path.exists():
        print(f"  SKIP {sprite_id} — no raw image")
        return None

    raw_img = Image.open(raw_path).convert("RGBA")
    print(f"  Processing {sprite_id}...")

    # Step 1: rembg ML background removal
    raw_bytes = BytesIO()
    raw_img.save(raw_bytes, format="PNG")
    raw_bytes.seek(0)
    result_bytes = remove(raw_bytes.read())
    result = Image.open(BytesIO(result_bytes)).convert("RGBA")
    arr = np.array(result).astype(float)

    # Step 2: Hard magenta remnant removal (NO color-merge)
    # Any pixel that's strongly magenta -> transparent
    r, g, b, a = arr[:,:,0]/255, arr[:,:,1]/255, arr[:,:,2]/255, arr[:,:,3]
    is_magenta = (r > 0.5) & (g < 0.35) & (b > 0.4) & (a > 10)
    arr[:,:,3][is_magenta] = 0

    # Also catch pinkish magenta remnants (softer threshold)
    is_pink = (r > 0.55) & (g < 0.4) & (b > 0.35) & ((r - g) > 0.2) & (a > 10)
    arr[:,:,3][is_pink] = 0

    # Step 3: Soft edge cleanup — desaturate magenta-tinted edge pixels
    alpha_mask = arr[:,:,3] > 10
    if alpha_mask.sum() > 0:
        eroded = binary_erosion(alpha_mask, iterations=4)
        edge_zone = alpha_mask & ~eroded

        for y in range(arr.shape[0]):
            for x in range(arr.shape[1]):
                if edge_zone[y, x]:
                    r_px, g_px, b_px = arr[y,x,0], arr[y,x,1], arr[y,x,2]
                    # Magenta hue: R high, B high, G low
                    if r_px > 80 and b_px > 80 and g_px < min(r_px, b_px) * 0.7:
                        gray = 0.299 * r_px + 0.587 * g_px + 0.114 * b_px
                        blend = 0.3  # Keep 30% original, 70% gray
                        arr[y,x,0] = r_px * blend + gray * (1-blend)
                        arr[y,x,1] = g_px * blend + gray * (1-blend)
                        arr[y,x,2] = b_px * blend + gray * (1-blend)

    arr = np.clip(arr, 0, 255).astype(np.uint8)
    processed = Image.fromarray(arr)

    # Step 4: Auto-crop to content bounding box
    alpha_ch = np.array(processed)[:,:,3]
    rows = np.any(alpha_ch > 10, axis=1)
    cols = np.any(alpha_ch > 10, axis=0)
    if rows.any() and cols.any():
        rmin, rmax = np.where(rows)[0][[0, -1]]
        cmin, cmax = np.where(cols)[0][[0, -1]]
        pad = 3
        rmin = max(0, rmin - pad)
        rmax = min(processed.height - 1, rmax + pad)
        cmin = max(0, cmin - pad)
        cmax = min(processed.width - 1, cmax + pad)
        cropped = processed.crop((cmin, rmin, cmax + 1, rmax + 1))
    else:
        cropped = processed

    # Step 5: Resize to 64x64, preserve aspect ratio, center
    w, h = cropped.size
    scale = min(64 / w, 64 / h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = cropped.resize((new_w, new_h), Image.NEAREST)

    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    offset_x = (64 - new_w) // 2
    offset_y = (64 - new_h) // 2
    canvas.paste(resized, (offset_x, offset_y), resized)

    # Save light
    canvas.save(OUTPUT_DIR / f"{sprite_id}_light.png")

    # Step 6: Dark variant
    dark_arr = np.array(canvas).astype(float)
    r_ch, g_ch, b_ch, a_ch = dark_arr[:,:,0], dark_arr[:,:,1], dark_arr[:,:,2], dark_arr[:,:,3]
    gray = 0.299 * r_ch + 0.587 * g_ch + 0.114 * b_ch
    r_ch = r_ch * 0.4 + gray * 0.6
    g_ch = g_ch * 0.4 + gray * 0.6
    b_ch = b_ch * 0.4 + gray * 0.6
    r_ch *= 0.6
    g_ch *= 0.6
    b_ch = np.clip(b_ch * 0.6 * 1.15, 0, 255)
    dark_img = Image.fromarray(np.stack([r_ch, g_ch, b_ch, a_ch], axis=2).astype(np.uint8))
    dark_img.save(OUTPUT_DIR / f"{sprite_id}_dark.png")

    fill = (np.array(canvas)[:,:,3] > 10).sum() / (64*64) * 100
    print(f"  Done: {sprite_id} (fill: {fill:.1f}%)")
    return sprite_id, canvas, dark_img


def build_comparison():
    """Rebuild comparison review HTML."""
    ts_path = Path(__file__).parent.parent / "assets" / "sprites" / "necromancer_dcss_tileset.png"
    ts = Image.open(ts_path).convert("RGBA")

    old_positions = {
        "lothlorien_m": (0, 6), "lothlorien_f": (1, 6),
        "gondor_f": (5, 7), "dunedain_f": (1, 7),
        "greenwood_f": (5, 6),
        "shire_m": (0, 9), "shire_f": (1, 9),
        "tooks_f": (3, 9), "gamgees_f": (5, 9),
    }

    labels = {
        "lothlorien_m": "Elf/Lothlorien M",
        "lothlorien_f": "Elf/Lothlorien F",
        "gondor_f": "Man/Gondor F",
        "dunedain_f": "Man/Dunedain F",
        "greenwood_f": "Elf/Greenwood F",
        "shire_m": "Hobbit/Shire M",
        "shire_f": "Hobbit/Shire F",
        "tooks_f": "Hobbit/Tooks F",
        "gamgees_f": "Hobbit/Gamgees F",
    }

    SCALE = 6
    compare_dir = OUTPUT_DIR / "compare"
    compare_dir.mkdir(exist_ok=True)

    for sid, (col, row) in old_positions.items():
        # Old light
        x, y = col * 64, row * 64
        old = ts.crop((x, y, x + 64, y + 64))
        old.resize((64 * SCALE, 64 * SCALE), Image.NEAREST).save(compare_dir / f"{sid}_old.png")
        # Old dark
        x2 = (6 + col) * 64
        old_dark = ts.crop((x2, y, x2 + 64, y + 64))
        old_dark.resize((64 * SCALE, 64 * SCALE), Image.NEAREST).save(compare_dir / f"{sid}_old_dark.png")

    for sid in SPRITES:
        light_path = OUTPUT_DIR / f"{sid}_light.png"
        dark_path = OUTPUT_DIR / f"{sid}_dark.png"
        if light_path.exists():
            Image.open(light_path).resize((64*SCALE, 64*SCALE), Image.NEAREST).save(compare_dir / f"{sid}_new.png")
        if dark_path.exists():
            Image.open(dark_path).resize((64*SCALE, 64*SCALE), Image.NEAREST).save(compare_dir / f"{sid}_dark_new.png")

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
</style></head><body>
<h1>Player Sprite Regen v2 — Old vs New (rembg only, no color-merge)</h1>
<p>Red border = OLD | Green border = NEW</p>
"""
    for sid in SPRITES:
        label = labels[sid]
        html += f"<h2>{label}</h2>\n<div class='row'>\n"
        html += f"""
  <div class='sprite-box'>
    <img src='player_v2/compare/{sid}_old.png' class='old' width='192' height='192'>
    <div class='label'>OLD (light)</div>
  </div>
  <div class='sprite-box'>
    <img src='player_v2/compare/{sid}_new.png' class='new' width='192' height='192'>
    <div class='label'>NEW (light)</div>
  </div>
  <div class='sprite-box'>
    <img src='player_v2/compare/{sid}_old_dark.png' class='old' width='192' height='192'>
    <div class='label'>OLD (dark)</div>
  </div>
  <div class='sprite-box'>
    <img src='player_v2/compare/{sid}_dark_new.png' class='new' width='192' height='192'>
    <div class='label'>NEW (dark)</div>
  </div>
"""
        html += "</div>\n"

    html += "</body></html>"
    html_path = Path(__file__).parent / "player_regen_review.html"
    with open(html_path, "w") as f:
        f.write(html)
    print(f"Review: {html_path}")


if __name__ == "__main__":
    print("=== Reprocessing player sprites (rembg only, no color-merge) ===\n")
    for sid in SPRITES:
        process_rembg_only(sid)
    print("\n=== Building comparison ===")
    build_comparison()
    print("\n=== Done! ===")
