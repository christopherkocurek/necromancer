#!/usr/bin/env python3
"""
Tome of Fallen Heroes - DALL-E 3 Book Texture Generator

Generates organic, aged book textures for the Tome UI panel.
Each texture is a 1024x1024 DALL-E 3 image, post-processed to target size.

Output: assets/ui/tome/*.png

Usage:
    python generate_book_textures.py           # Generate all textures
    python generate_book_textures.py --status  # Show progress
    python generate_book_textures.py --single cover  # Generate one texture
"""

import os
import sys
import json
import time
import base64
import argparse
import io
from pathlib import Path
from datetime import datetime
from typing import Optional

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter, ImageEnhance
    import numpy as np
except ImportError:
    print("Required: pip install openai pillow python-dotenv numpy")
    sys.exit(1)

COST_PER_IMAGE = 0.04
RATE_LIMIT_DELAY = 2.5
WHITE_THRESHOLD = 240

BASE_DIR = Path(__file__).parent
PROJECT_DIR = BASE_DIR.parent
OUTPUT_DIR = PROJECT_DIR / "assets" / "ui" / "tome"
RAW_DIR = OUTPUT_DIR / "raw"
PROGRESS_PATH = BASE_DIR / "book_texture_progress.json"

# ============================================================================
# TEXTURE DEFINITIONS
# ============================================================================

# Each texture: (key, target_width, target_height, prompt)
# Prompts avoid "pixel art", "game tile", "sprite", "texture map"

BOOK_STYLE = (
    "Painted in a detailed oil painting style with visible brushstrokes. "
    "Rich dark color palette. Photorealistic surface detail. "
    "The subject fills the entire image edge to edge with NO border, "
    "NO frame, NO white space. Dark background where edges meet."
)

TEXTURES = {
    "cover": {
        "w": 512, "h": 512,
        "prompt": (
            "A flat overhead photograph of an ancient leather book cover. "
            "Dark brown aged leather, deeply worn and scratched. "
            "Tarnished brass corner brackets with celtic knotwork, one bracket is missing. "
            "Embossed circular medallion in center with interlocking runic symbols. "
            "Broken leather strap clasp on the right edge. "
            "Cracked and patchy leather showing lighter underhide in places. "
            "Bird's eye view, flat lay on a dark stone surface. "
            + BOOK_STYLE
        ),
    },
    "page_index": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page from an ancient book. "
            "Yellowed vellum with subtle foxing spots scattered across the surface. "
            "A faint circular water ring stain in the bottom left corner. "
            "Faint ruled lines barely visible, as if someone once wrote on this page. "
            "Slightly darker along the right edge where it meets the book spine. "
            "The parchment surface shows fine grain and fiber detail. "
            "Flat top-down view, the parchment fills the entire image. "
            + BOOK_STYLE
        ),
    },
    "page_melee": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page, stained and battle-worn. "
            "Yellowed vellum with a dark reddish-brown dried blood splatter in the upper right corner. "
            "Three diagonal scratch marks across the surface as if clawed by a blade. "
            "Subtle foxing and age spots throughout. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_archery": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page from a hunter's journal. "
            "Yellowed vellum with a small circular hole torn through near the center, "
            "as if an arrow passed through it. Faint feather imprint near the bottom. "
            "Smudged charcoal fingerprints along the right edge. "
            "Foxing spots and age stains. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_evasion": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page damaged by water. "
            "Yellowed vellum with large watermark stains creating wavy tide lines. "
            "The edges are slightly warped and rippled from moisture damage. "
            "Some ink has run and blurred in the water-damaged areas. "
            "Foxing spots concentrated in the damp areas. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_stealth": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page stained with soot and shadow. "
            "Yellowed vellum with dark charcoal smudges and sooty fingerprints. "
            "The corners are darkened as if held near a flame but not burned. "
            "A dark thumbprint clearly visible in the lower right. "
            "Overall darker and dingier than normal parchment. "
            "Foxing spots. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_perception": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page with candle damage. "
            "Yellowed vellum with dripped candle wax pooled and hardened in one corner. "
            "A small circular burn mark where a candle was set down. "
            "Faint heat discoloration radiating from the burn in amber tones. "
            "Foxing spots and age stains throughout. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_will": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page, deeply creased and worn. "
            "Yellowed vellum that has been folded and unfolded many times, "
            "with deep crease lines forming a cross pattern. "
            "The surface is worn smooth in places from repeated handling. "
            "Some areas are slightly translucent from being rubbed thin. "
            "Foxing spots. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_smithing": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page damaged by fire and forge. "
            "Yellowed vellum with blackened scorch marks along the bottom edge. "
            "Small burn holes where sparks landed, revealing darkness through the page. "
            "Soot smudges and orange-brown iron rust stains. "
            "The bottom right corner is charred and crumbling. "
            "Foxing spots. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "page_lore": {
        "w": 512, "h": 640,
        "prompt": (
            "A flat overhead photograph of an aged parchment page stained with magical ink. "
            "Yellowed vellum with deep indigo-purple ink spills and splatters. "
            "Faint arcane symbols bleeding through from the page behind, barely visible. "
            "A shimmering residue where enchanted ink was spilled. "
            "The ink stains have an iridescent quality. "
            "Foxing spots. Darker along the left spine edge. "
            "The parchment fills the entire image edge to edge. "
            + BOOK_STYLE
        ),
    },
    "spine": {
        "w": 64, "h": 512,
        "prompt": (
            "A close-up photograph of an ancient book spine, vertical view. "
            "Dark brown cracked leather with visible thread stitching running vertically. "
            "Deep creases and wear marks from being opened countless times. "
            "Faded illegible gold lettering stamped into the leather. "
            "The spine is concave, curving inward, creating shadow in the center. "
            "Leather is worn smooth at top and bottom from being pulled off shelves. "
            "The spine fills the entire image. Dark background. "
            + BOOK_STYLE
        ),
    },
    "page_edges": {
        "w": 48, "h": 512,
        "prompt": (
            "A close-up photograph of the fore-edge of a very old thick book. "
            "Side view showing hundreds of stacked parchment pages, uneven and yellowed. "
            "Some pages protrude slightly further than others, creating an irregular edge. "
            "The pages are yellowed and aged, with slight foxing visible on the edges. "
            "A few pages have small tears or dog-ears visible from the side. "
            "The stack is thick, suggesting a heavy tome. "
            "Dark background surrounding the page stack. "
            + BOOK_STYLE
        ),
    },
    "corner_dogear": {
        "w": 128, "h": 128,
        "prompt": (
            "A close-up photograph of the corner of an aged parchment page that is folded over. "
            "Dog-eared fold showing the back side of the page which is slightly darker. "
            "The fold creates a triangular flap in the upper right corner. "
            "Yellowed vellum with subtle grain and foxing. "
            "Isolated on a completely dark black background. "
            "Only the folded corner is visible, everything else is dark. "
            + BOOK_STYLE
        ),
    },
    "loose_note": {
        "w": 192, "h": 192,
        "prompt": (
            "A flat overhead photograph of a small torn scrap of aged parchment. "
            "Irregular torn edges, slightly crumpled and wrinkled. "
            "Hasty illegible handwriting in dark brown ink, cramped and desperate. "
            "A few words scratched out. An ink blot in one corner. "
            "The scrap is small and asymmetric, roughly triangular. "
            "Isolated on a completely dark black background. "
            + BOOK_STYLE
        ),
    },
}


def auto_crop_and_resize(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Crop white borders, then resize to target dimensions using LANCZOS."""
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]

    r, g, b = img_array[:,:,0], img_array[:,:,1], img_array[:,:,2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD

    rows = np.any(content_mask, axis=1)
    cols = np.any(content_mask, axis=0)

    if not np.any(rows) or not np.any(cols):
        print("  WARNING: Image appears blank")
        return img.resize((target_w, target_h), Image.Resampling.LANCZOS)

    row_start = np.argmax(rows)
    row_end = h - np.argmax(rows[::-1])
    col_start = np.argmax(cols)
    col_end = w - np.argmax(cols[::-1])

    border_pct = ((row_start + (h - row_end) + col_start + (w - col_end)) / (2 * (h + w))) * 100
    min_border = int(h * 0.02)

    if (row_start > min_border or (h - row_end) > min_border or
            col_start > min_border or (w - col_end) > min_border):
        # Add small padding
        pad = max(5, int(h * 0.01))
        row_start = max(0, row_start - pad)
        row_end = min(h, row_end + pad)
        col_start = max(0, col_start - pad)
        col_end = min(w, col_end + pad)
        img = img.crop((col_start, row_start, col_end, row_end))
        print(f"  Cropped borders ({border_pct:.1f}%): {w}x{h} -> {img.width}x{img.height}")

    return img.resize((target_w, target_h), Image.Resampling.LANCZOS)


class BookTextureGenerator:
    def __init__(self):
        self.client = OpenAI()
        self.total_cost = 0.0
        self.progress = self._load_progress()
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        RAW_DIR.mkdir(parents=True, exist_ok=True)

    def _load_progress(self) -> dict:
        if PROGRESS_PATH.exists():
            with open(PROGRESS_PATH) as f:
                return json.load(f)
        return {"textures": {}, "api_calls": 0, "cost_total": 0.0}

    def _save_progress(self):
        self.progress["last_updated"] = datetime.now().isoformat()
        with open(PROGRESS_PATH, "w") as f:
            json.dump(self.progress, f, indent=2)

    def generate_single(self, key: str, retry: int = 0) -> Optional[Path]:
        """Generate a single book texture. Returns path or None."""
        tex = TEXTURES[key]

        # Skip if already done
        if key in self.progress["textures"]:
            status = self.progress["textures"][key].get("status")
            if status == "completed":
                path = Path(self.progress["textures"][key]["path"])
                if path.exists():
                    print(f"  SKIP: {key} already completed")
                    return path

        prompt = tex["prompt"]
        target_w, target_h = tex["w"], tex["h"]

        print(f"\n{'='*60}")
        print(f"Generating: {key} ({target_w}x{target_h})")
        print(f"Prompt: {prompt[:120]}...")

        try:
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style="natural",
                n=1,
                response_format="b64_json"
            )

            self.total_cost += COST_PER_IMAGE
            self.progress["api_calls"] = self.progress.get("api_calls", 0) + 1
            self.progress["cost_total"] = self.progress.get("cost_total", 0) + COST_PER_IMAGE

            img_data = base64.b64decode(response.data[0].b64_json)
            img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")

            revised = getattr(response.data[0], 'revised_prompt', None)
            if revised:
                print(f"  DALL-E revised: {revised[:100]}...")

            # Save raw
            raw_path = RAW_DIR / f"{key}_1024.png"
            img_1024.save(raw_path)
            print(f"  Saved raw: {raw_path.name}")

            # Crop and resize
            img_final = auto_crop_and_resize(img_1024, target_w, target_h)

            # Save final
            out_path = OUTPUT_DIR / f"{key}.png"
            img_final.save(out_path)
            print(f"  Saved: {out_path} ({target_w}x{target_h})")

            self.progress["textures"][key] = {
                "status": "completed",
                "path": str(out_path),
                "size": f"{target_w}x{target_h}",
                "timestamp": datetime.now().isoformat(),
            }
            self._save_progress()

            time.sleep(RATE_LIMIT_DELAY)
            return out_path

        except Exception as e:
            print(f"  ERROR: {e}")
            if retry < 2:
                print(f"  Retrying ({retry + 1}/2)...")
                time.sleep(5)
                return self.generate_single(key, retry + 1)
            self.progress["textures"][key] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
            }
            self._save_progress()
            return None

    def generate_all(self):
        """Generate all book textures."""
        keys = list(TEXTURES.keys())
        total = len(keys)
        completed = 0
        failed = 0

        print(f"\n{'#'*60}")
        print(f"  TOME TEXTURE GENERATION")
        print(f"  {total} textures to generate")
        print(f"  Estimated cost: ${total * COST_PER_IMAGE:.2f}")
        print(f"{'#'*60}")

        for i, key in enumerate(keys):
            print(f"\n[{i+1}/{total}] {key}")
            result = self.generate_single(key)
            if result:
                completed += 1
            else:
                failed += 1

        print(f"\n{'#'*60}")
        print(f"  COMPLETE: {completed} generated, {failed} failed")
        print(f"  Total cost: ${self.total_cost:.2f}")
        print(f"  Output: {OUTPUT_DIR}")
        print(f"{'#'*60}")

    def show_status(self):
        """Show generation progress."""
        total = len(TEXTURES)
        done = sum(1 for t in self.progress.get("textures", {}).values()
                   if t.get("status") == "completed")
        failed = sum(1 for t in self.progress.get("textures", {}).values()
                     if t.get("status") == "failed")
        pending = total - done - failed

        print(f"Book Texture Progress:")
        print(f"  Completed: {done}/{total}")
        print(f"  Failed: {failed}")
        print(f"  Pending: {pending}")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Total cost: ${self.progress.get('cost_total', 0):.2f}")

        for key in TEXTURES:
            status = self.progress.get("textures", {}).get(key, {}).get("status", "pending")
            marker = {"completed": "OK", "failed": "FAIL", "pending": "..."}
            print(f"  [{marker.get(status, '?'):4}] {key}")


def main():
    parser = argparse.ArgumentParser(description="Generate Tome book textures via DALL-E 3")
    parser.add_argument("--status", action="store_true", help="Show progress")
    parser.add_argument("--single", type=str, help="Generate a single texture by key")
    parser.add_argument("--regenerate", type=str, help="Force regenerate a texture by key")
    args = parser.parse_args()

    gen = BookTextureGenerator()

    if args.status:
        gen.show_status()
        return

    if args.regenerate:
        key = args.regenerate
        if key not in TEXTURES:
            print(f"Unknown texture: {key}. Options: {', '.join(TEXTURES.keys())}")
            sys.exit(1)
        # Clear progress for this key
        gen.progress.get("textures", {}).pop(key, None)
        gen._save_progress()
        gen.generate_single(key)
        return

    if args.single:
        key = args.single
        if key not in TEXTURES:
            print(f"Unknown texture: {key}. Options: {', '.join(TEXTURES.keys())}")
            sys.exit(1)
        gen.generate_single(key)
        return

    gen.generate_all()


if __name__ == "__main__":
    main()
