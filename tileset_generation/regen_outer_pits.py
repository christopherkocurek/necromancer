#!/usr/bin/env python3
"""
Outer Pits (Layer 1) Tile Regeneration — Full Creative Director Overhaul

Generates 14 tiles in phased order following the unified creative direction:
  Phase 1: Anchor (floor, wall) — establish the universal stone material
  Phase 2: Interactive (door_closed, door_open) — generated as a pair
  Phase 3: Navigation (stairs_down, stairs_up) — generated as a pair
  Phase 4: Environmental (vine_floor, forest_floor, fallen_masonry, poison_stream)
  Phase 5: Hazard/Special (spider_web, thick_web_trap, bottomless_pit, tangled_roots)

Dark variants generated programmatically (not via DALL-E).

Follows project terrain gen best practices:
  - style="natural" for terrain (NOT "vivid")
  - "retro low-resolution blocky painting" framing
  - "Top-down dungeon tile viewed from above"
  - Edge-to-edge fill, no borders
  - LANCZOS resize 1024→64 (not NEAREST — terrain fills full tile)
  - NEVER use "pixel art", "game tile", "sprite", "texture"
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
RAW_DIR = SCRIPT_DIR / "layer_tiles" / "raw" / "outer_pits_v2"
PROCESSED_DIR = SCRIPT_DIR / "layer_tiles" / "outer_pits_v2"
TILESET_PATH = PROJECT_DIR / "assets" / "sprites" / "necromancer_dcss_tileset.png"

RAW_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================================
# DALL-E CLIENT
# ============================================================================

load_dotenv(SCRIPT_DIR / ".env")
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# ============================================================================
# SHARED PREAMBLE — Creative Director's unified vision
# ============================================================================

PREAMBLE = (
    "Seamless tileable texture, top-down view from directly above, "
    "flat perspective with no vanishing point. "
    "Gothic stone fortress illustration. "
    "Palette: charcoal-grey stone, emerald green moss, brown earth and roots. "
    "Fills the entire frame edge to edge. No text. "
)

# ============================================================================
# TILE DEFINITIONS — 14 tiles in 5 phases
# ============================================================================

TILES = {
    # ---- Phase 1: Anchor tiles ----
    "floor": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Rectangular stone flagstones in an irregular paving pattern, charcoal-grey with weathered surfaces. "
            "Emerald green moss grows thick in the mortar joints between flagstones, "
            "spreading in vivid green patches where moisture collects. "
            "Two thin brown root tendrils cross the stone surface, pushing through cracks. "
            "A few amber-brown dead leaves and a small twig rest on the stone. "
            "Brown earth is visible in wider cracks where roots have split the stone. "
            "The stone dominates but green life pushes through every joint. "
            "Seamless tileable stone floor texture."
        ),
    },
    "wall": {
        "phase": 1,
        "prompt": (
            PREAMBLE +
            "Massive hand-cut stone blocks viewed from above, rough-hewn charcoal-grey masonry. "
            "Thick emerald green moss coats the mortar joints and spreads in vivid patches across the stone faces. "
            "One thick brown tree root forces through a crack, splitting the stonework apart. "
            "Fine brown earth and debris fill the gaps where roots have pushed through. "
            "The stone blocks are dominant but the living forest is visibly breaching the wall. "
            "Seamless tileable stone wall texture filling the entire image."
        ),
    },

    # ---- Phase 2: Interactive pair ----
    "door_closed": {
        "phase": 2,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone wall blocks fill the top third and bottom third. "
            "A horizontal band of aged oak planks spans the center, deep brown wood grain running left-to-right. "
            "Three rusted iron crossbands secure the planks. "
            "Emerald green moss grows thick where stone meets wood frame. "
            "A thin brown root tendril curls along the top edge of the door. "
            "Seamless tileable door texture filling the entire image."
        ),
    },
    "door_open": {
        "phase": 2,
        "prompt": (
            PREAMBLE +
            "Three horizontal bands filling the entire image edge to edge. "
            "Top band: rough charcoal-grey stone blocks with emerald green moss in the mortar joints. "
            "Center band: stone flagstones visible through a gap in the wall, slightly lighter grey. "
            "Broken brown wooden plank fragments pushed to one side. "
            "Bottom band: more charcoal-grey stone blocks matching the top. "
            "Vivid green moss at every seam between stone and opening. "
            "Seamless tileable stone wall passage texture."
        ),
    },

    # ---- Phase 3: Navigation pair ----
    "stairs_down": {
        "phase": 3,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone flagstones with a square stairwell opening in the center. "
            "Rough stone steps descend into deep shadow below, each step progressively deeper. "
            "The lowest step fades into black void. "
            "Emerald green moss and brown root tendrils grow along the cracked stairwell edges. "
            "A few amber-brown leaves have blown onto the top step. "
            "Seamless tileable stone floor with stairwell texture."
        ),
    },
    "stairs_up": {
        "phase": 3,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone flagstones with a square stairwell opening in the center. "
            "Rough stone steps ascend toward warm amber-green light from the forest above. "
            "The topmost step catches warm light, each lower step progressively deeper in shadow. "
            "Emerald green moss coats the stairwell edges. Leaves and forest debris on the lower steps. "
            "A brown root grows across one step. "
            "Seamless tileable stone floor with stairwell texture."
        ),
    },

    # ---- Phase 4: Environmental ----
    "vine_floor": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone flagstones heavily covered by creeping vines. "
            "Vivid emerald green vine tendrils sprawl across the entire stone surface, "
            "growing aggressively through every crack and mortar joint. "
            "Thick green leaves sprout from the vine stems. "
            "The stone is visible but the living vines dominate, covering sixty percent of the surface. "
            "Brown earth in the wider cracks where vines have split stone. "
            "Seamless tileable vine-covered stone floor texture."
        ),
    },
    "forest_floor": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Stone flagstones almost completely covered by forest debris. "
            "Amber-brown dead leaves, small twigs, and brown earth cover most of the surface. "
            "Vivid green moss patches grow between the leaf litter. "
            "Brown root tendrils thread across the debris. "
            "The charcoal-grey stone paving is only partially visible beneath the organic layer. "
            "The forest has nearly reclaimed this floor. Warm earth tones dominate. "
            "Seamless tileable forest debris floor texture."
        ),
    },
    "fallen_masonry": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone flagstones scattered with broken stone rubble and debris. "
            "Cracked masonry chunks and shattered stone fragments litter the floor. "
            "Emerald green moss grows on the rubble surfaces and in the cracks. "
            "Brown root tendrils thread through the debris pile. "
            "Brown earth and amber leaf litter mixed with the stone fragments. "
            "The forest is reclaiming the fallen stones. "
            "Seamless tileable rubble floor texture."
        ),
    },
    "poison_stream": {
        "phase": 4,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone flagstones split by a narrow channel of sickly yellow-green liquid. "
            "The toxic stream flows north-south through the center of the tile. "
            "The liquid glows faintly, a corrupted murky chartreuse color. "
            "Vivid green moss and algae coat the corroded stone edges along the channel. "
            "Brown earth and debris where the stream has eroded the stone joints. "
            "Seamless tileable stone floor with poison stream texture."
        ),
    },

    # ---- Phase 5: Hazard / Special ----
    "spider_web": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Dense spider web stretched across charcoal-grey stone floor. "
            "Thick silvery-white silk threads form an irregular radial web pattern. "
            "The web is anchored to brown root protrusions and moss-covered stone. "
            "Emerald green moss visible on the stone beneath the web strands. "
            "Dust and small debris caught in the sticky silk. "
            "Seamless tileable spider web on stone floor texture."
        ),
    },
    "thick_web_trap": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Extremely dense mat of thick sticky spider web covering stone floor. "
            "Multiple layers of silvery-white silk woven tightly together, nearly opaque. "
            "The charcoal-grey stone and emerald green moss barely visible beneath. "
            "Thick gooey strands with a yellowish tint from age. "
            "Brown root stubs poke through the web mat at the edges. "
            "Seamless tileable thick web trap texture."
        ),
    },
    "bottomless_pit": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Charcoal-grey stone flagstones with a ragged circular hole revealing black void below. "
            "Crumbling irregular stone edges surround the pit opening. "
            "Brown roots dangle over the edge into the darkness. "
            "Emerald green moss grows thick on the crumbling stone rim. "
            "Small stone fragments crumble into the abyss. "
            "Seamless tileable stone floor with pit texture."
        ),
    },
    "tangled_roots": {
        "phase": 5,
        "prompt": (
            PREAMBLE +
            "Massive stone blocks almost completely engulfed by thick brown tree roots. "
            "The roots are warm brown, gnarled and twisted, splitting the charcoal-grey masonry apart. "
            "Vivid emerald green moss coats every root surface. "
            "Brown earth packed between root masses and stone. "
            "The forest dominates — seventy percent roots and moss, thirty percent visible stone. "
            "Seamless tileable root-covered wall texture."
        ),
    },
}

# ============================================================================
# DARK VARIANT GENERATION (programmatic, not DALL-E)
# ============================================================================

def make_dark_variant(light_img: Image.Image) -> Image.Image:
    """Generate dark/remembered variant: desaturate 60%, darken 40%, cool blue tint."""
    arr = np.array(light_img).astype(np.float64)
    # Desaturate 60%
    gray = np.mean(arr[:, :, :3], axis=2, keepdims=True)
    arr[:, :, :3] = arr[:, :, :3] * 0.4 + gray * 0.6
    # Darken 40%
    arr[:, :, :3] *= 0.6
    # Cool blue tint
    arr[:, :, 0] *= 0.85   # reduce red
    arr[:, :, 1] *= 0.90   # reduce green slightly
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)  # boost blue
    # Preserve alpha
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
            style="natural",  # ALWAYS natural for terrain
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
    """Process 1024→64 light + dark. Returns (light_64, dark_64)."""
    # LANCZOS resize for terrain (fills full tile, not sprite)
    light_64 = img_1024.resize((64, 64), Image.LANCZOS)
    dark_64 = make_dark_variant(light_64)
    return light_64, dark_64


def run_phase(phase_num: int, tiles_in_phase: dict, max_attempts: int = 2):
    """Generate all tiles in a phase sequentially (respect DALL-E rate limits)."""
    results = {}
    for name, tile_def in tiles_in_phase.items():
        success = False
        for attempt in range(1, max_attempts + 1):
            img_1024 = generate_tile(name, tile_def, attempt)
            if img_1024 is not None:
                # Save raw 1024
                raw_path = RAW_DIR / f"{name}_1024.png"
                img_1024.save(raw_path)
                print(f"  [{name}] Saved raw: {raw_path.name}")

                # Process to 64x64
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
    parser = argparse.ArgumentParser(description="Regenerate Outer Pits layer tiles")
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
    print("OUTER PITS TILE REGENERATION")
    print(f"Output: {RAW_DIR}")
    print(f"Processed: {PROCESSED_DIR}")
    print("=" * 60)

    # Filter tiles
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

        # Brief pause between phases for rate limit headroom
        if phase_num < max(phases_to_run):
            print(f"\n  Phase {phase_num} complete. Pausing 2s before next phase...")
            time.sleep(2)

    # Summary
    print(f"\n{'=' * 60}")
    print("GENERATION COMPLETE")
    print(f"{'=' * 60}")
    print(f"Generated: {len(all_results)}/{len(selected)} tiles")
    print(f"Estimated cost: ~${len(all_results) * 0.04:.2f}")
    failed = [k for k in selected if k not in all_results]
    if failed:
        print(f"FAILED: {', '.join(failed)}")
    print(f"\nRaw 1024x1024: {RAW_DIR}")
    print(f"Processed 64x64: {PROCESSED_DIR}")
    print(f"\nNext step: Review tiles, then run integration to paste into tileset.")


if __name__ == "__main__":
    main()
