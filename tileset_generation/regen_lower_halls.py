#!/usr/bin/env python3
"""
Lower Halls (Layer 2) Tile Generation — Orc Military Garrison

Generates tiles for F4-F6 with creative direction:
  Crude lashed wood, hanging racks of raw/rotting meat, military stone + chopped wood,
  rough wrought iron, soot, war banners and crude iron fixtures.

Palette: dark grey stone, rough-hewn brown wood, sooty black iron, amber torchlight.

Follows project terrain gen best practices from /tileset-gen skill.
"""

import os
import sys
import io
import base64
import argparse
import time
from pathlib import Path

import numpy as np
from PIL import Image
from dotenv import load_dotenv
from openai import OpenAI

# ============================================================================
# PATHS
# ============================================================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "lower_halls"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "lower_halls"
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"

# Outer Pits floor for compositing overlay tiles
OUTER_PITS_RAW = SCRIPT_DIR / "layer_tiles" / "raw" / "outer_pits_v2"

RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================================
# DALL-E CLIENT
# ============================================================================

load_dotenv(SCRIPT_DIR / ".env")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ============================================================================
# SHARED PREAMBLE — Orc Military Garrison
# ============================================================================

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Crude orc military garrison illustration. "
    "Palette: dark grey stone, rough-hewn brown wood, sooty black iron. "
    "Fills the entire frame edge to edge. No text. "
)

# ============================================================================
# TILE DEFINITIONS
# ============================================================================

TILES = {
    # ---- Phase 1: Anchor tiles ----
    "floor": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Rectangular dark grey stone flagstones in an irregular paving pattern. "
            "Weathered charcoal-grey stone with hairline cracks and worn edges. "
            "Faint black soot stains darken patches of the stone surface. "
            "No wood, no debris, just heavy dark stone paving. "
            "Seamless tileable dark stone floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Massive dark grey stone blocks in rough-hewn masonry rows. "
            "A single horizontal band of rough chopped brown lumber spans the center, "
            "lashed to the stone with crude rope and secured by two wrought iron brackets. "
            "Black soot stains streak the stone above the crossbeam. "
            "The stone dominates, the lumber is one structural support beam. "
            "Seamless tileable stone garrison wall texture."
        ),
    },

    # ---- Phase 3: Navigation pair ----
    "stairs_down": {
        "phase": 3,
        "prompt": (
            PREAMBLE +
            "Dark grey stone flagstones with a square stairwell opening in the center. "
            "Rough stone steps descend into deep shadow below, each step darker. "
            "Crude brown wood reinforcement beams frame the stairwell opening. "
            "Sooty black iron brackets bolted to the wood frame. "
            "Soot stains and scorch marks around the edges. "
            "Seamless tileable stone floor with stairwell texture."
        ),
    },
    "stairs_up": {
        "phase": 3,
        "prompt": (
            PREAMBLE +
            "Dark grey stone flagstones with a square stairwell opening in the center. "
            "Rough stone steps ascend toward warm amber torchlight from above. "
            "The topmost step catches warm orange light, each lower step progressively darker. "
            "Crude brown wood beams frame the stairwell. Wrought iron brackets visible. "
            "Soot stains around the edges from torches. "
            "Seamless tileable stone floor with stairwell texture."
        ),
    },

    # ---- Phase 4: Environmental ----
    "forest_floor": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Stone flagstones covered with military debris and garrison waste. "
            "Scattered brown wood splinters, crude rope scraps, iron filings. "
            "Dark amber stains from spilled grog and torch drippings. "
            "Sooty black marks from campfires on the stone surface. "
            "The stone is filthy with the detritus of orc occupation. "
            "Seamless tileable garrison debris floor texture."
        ),
    },
    "fallen_masonry": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Dark grey stone flagstones with a large chunk of broken stone rubble in the center. "
            "Shattered wall blocks and crushed brown wood beam fragments piled together. "
            "Bent wrought iron brackets and twisted iron nails in the debris. "
            "Soot and dust coat everything. "
            "Seamless tileable rubble floor texture."
        ),
    },
    "poison_stream": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Dark grey stone flagstones split by a narrow channel of foul murky liquid. "
            "The toxic stream flows north-south through the center, sickly yellow-green color. "
            "Crude iron grating partially covers sections of the channel. "
            "Soot and grime coat the corroded stone edges along the channel. "
            "Seamless tileable stone floor with poison stream texture."
        ),
    },

    # ---- Phase 5: Hazard / Special ----
    "spider_web": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Dense spider web stretched across dark grey stone floor. "
            "Thick silvery-white silk threads form an irregular radial web pattern. "
            "The web anchors to crude iron fixtures and wood beam fragments on the stone. "
            "Soot dust and small debris caught in the sticky silk strands. "
            "Seamless tileable spider web on stone floor texture."
        ),
    },
    "thick_web_trap": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Extremely dense mat of thick sticky spider web covering stone floor. "
            "Multiple layers of silvery-white silk woven tightly together, nearly opaque. "
            "Dark grey stone and iron fixtures barely visible beneath the web mass. "
            "Thick gooey strands with yellowish tint from age and soot. "
            "Seamless tileable thick web trap texture."
        ),
    },
    "bottomless_pit": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Dark grey stone flagstones with a ragged circular hole revealing black void below. "
            "Crumbling irregular stone edges surround the pit opening. "
            "Broken brown wood beam ends and bent iron brackets hang over the edge. "
            "Soot stains around the crumbling rim. "
            "Seamless tileable stone floor with pit texture."
        ),
    },
    "vine_floor": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Dark grey stone flagstones with crude brown rope and leather straps draped across. "
            "Worn rope lashings and frayed cord scattered across the garrison floor. "
            "Iron ring bolts embedded in the stone with rope threaded through. "
            "Soot stains and scorch marks on the stone surface. "
            "Seamless tileable rope-covered garrison floor texture."
        ),
    },
    "tangled_roots": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Massive dark grey stone blocks reinforced with heavy lashed brown wood beams. "
            "Dense crude wood crossbeams and thick rope lashings dominate the surface. "
            "Wrought iron brackets and heavy iron bolts everywhere. "
            "The wood is rough-hewn and crude, seventy percent wood and iron, thirty percent stone. "
            "Seamless tileable heavily reinforced garrison wall texture."
        ),
    },
}

# ============================================================================
# TILESET PASTE COORDINATES — Row 20, cols 12-23
# ============================================================================

# Lower halls is at row 20 starting at col 12
PASTE_MAP = {
    'wall':        [(12, 20), (13, 20)],   # light, dark
    'floor':       [(14, 20), (15, 20)],
    'door_closed': [(16, 20), (17, 20)],
    'door_open':   [(18, 20), (19, 20)],
    'stairs_down': [(20, 20), (21, 20)],
    'stairs_up':   [(22, 20), (23, 20)],
}

# ============================================================================
# DARK VARIANT GENERATION
# ============================================================================

def make_dark_variant(light_img: Image.Image) -> Image.Image:
    """Generate dark/remembered variant: desaturate 60%, darken 40%, cool blue tint."""
    arr = np.array(light_img).astype(np.float64)
    gray = np.mean(arr[:, :, :3], axis=2, keepdims=True)
    arr[:, :, :3] = arr[:, :, :3] * 0.4 + gray * 0.6
    arr[:, :, :3] *= 0.6
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))


# ============================================================================
# GENERATION
# ============================================================================

def generate_tile(name: str, tile_def: dict, attempt: int = 1) -> Image.Image:
    """Generate a single tile via DALL-E 3. Returns 1024x1024 RGBA image."""
    print(f"  [{name}] Generating (attempt {attempt})...")
    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=tile_def["prompt"],
            size="1024x1024",
            quality="standard",
            style="natural",
            n=1,
            response_format="b64_json",
        )
        img_data = base64.b64decode(response.data[0].b64_json)
        img = Image.open(io.BytesIO(img_data)).convert("RGBA")
        return img
    except Exception as e:
        print(f"  [{name}] FAILED: {e}")
        return None


def process_tile(name: str, img_1024: Image.Image) -> tuple:
    """Process 1024->64 light + dark. Returns (light_64, dark_64)."""
    light_64 = img_1024.resize((64, 64), Image.LANCZOS)
    dark_64 = make_dark_variant(light_64)
    return light_64, dark_64


def run_phase(phase_num: int, tiles_in_phase: dict, max_attempts: int = 2):
    """Generate all tiles in a phase sequentially."""
    results = {}
    for name, tile_def in tiles_in_phase.items():
        success = False
        for attempt in range(1, max_attempts + 1):
            img_1024 = generate_tile(name, tile_def, attempt)
            if img_1024 is not None:
                raw_path = RAW_DIR / f"{name}_1024.png"
                img_1024.save(raw_path)
                print(f"  [{name}] Saved raw: {raw_path.name}")

                light_64, dark_64 = process_tile(name, img_1024)
                light_path = PROCESSED_DIR / f"{name}_light.png"
                dark_path = PROCESSED_DIR / f"{name}_dark.png"
                light_64.save(light_path)
                dark_64.save(dark_path)
                print(f"  [{name}] Saved: {light_path.name} + {dark_path.name}")

                results[name] = {
                    "raw": raw_path,
                    "light": light_path,
                    "dark": dark_path,
                    "img_1024": img_1024,
                    "light_64": light_64,
                    "dark_64": dark_64,
                }
                success = True
                break
            else:
                if attempt < max_attempts:
                    print(f"  [{name}] Retrying in 3s...")
                    time.sleep(3)
        if not success:
            print(f"  [{name}] FAILED after {max_attempts} attempts!")
    return results


def main():
    parser = argparse.ArgumentParser(description="Generate Lower Halls layer tiles")
    parser.add_argument("--phase", type=int, choices=[1, 2, 3, 4, 5],
                        help="Run only a specific phase (1-5)")
    parser.add_argument("--tile", type=str, choices=list(TILES.keys()),
                        help="Generate only a single specific tile")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print prompts without calling DALL-E")
    parser.add_argument("--attempts", type=int, default=2,
                        help="Max generation attempts per tile (default: 2)")
    args = parser.parse_args()

    print("=" * 60)
    print("LOWER HALLS TILE GENERATION")
    print(f"Output: {RAW_DIR}")
    print(f"Processed: {PROCESSED_DIR}")
    print("=" * 60)

    if args.tile:
        selected = {args.tile: TILES[args.tile]}
        phases_to_run = [TILES[args.tile]["phase"]]
    elif args.phase:
        selected = {k: v for k, v in TILES.items() if v["phase"] == args.phase}
        phases_to_run = [args.phase]
    else:
        selected = TILES
        phases_to_run = [1, 2, 3, 4, 5]

    if args.dry_run:
        for name, tile_def in selected.items():
            print(f"\n--- {name} (Phase {tile_def['phase']}) ---")
            print(f"Prompt ({len(tile_def['prompt'])} chars):")
            print(tile_def["prompt"][:200] + "...")
        print(f"\nTotal: {len(selected)} tiles, ~${len(selected) * 0.04:.2f} estimated")
        return

    all_results = {}
    for phase_num in sorted(phases_to_run):
        phase_tiles = {k: v for k, v in selected.items() if v["phase"] == phase_num}
        if not phase_tiles:
            continue

        phase_names = {
            1: "Anchor (floor, wall)",
            2: "Interactive (doors)",
            3: "Navigation (stairs)",
            4: "Environmental",
            5: "Hazard / Special",
        }
        print(f"\n{'=' * 60}")
        print(f"PHASE {phase_num}: {phase_names.get(phase_num, 'Unknown')}")
        print(f"Tiles: {', '.join(phase_tiles.keys())}")
        print(f"{'=' * 60}")

        results = run_phase(phase_num, phase_tiles, max_attempts=args.attempts)
        all_results.update(results)

        if phase_num < max(phases_to_run):
            print(f"\n  Phase {phase_num} complete. Pausing 2s...")
            time.sleep(2)

    print(f"\n{'=' * 60}")
    print("GENERATION COMPLETE")
    print(f"{'=' * 60}")
    print(f"Generated: {len(all_results)}/{len(selected)} tiles")
    print(f"Estimated cost: ~${len(all_results) * 0.04:.2f}")
    failed = [k for k in selected if k not in all_results]
    if failed:
        print(f"FAILED: {', '.join(failed)}")


if __name__ == "__main__":
    main()
