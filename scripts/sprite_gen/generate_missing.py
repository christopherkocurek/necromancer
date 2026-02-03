#!/usr/bin/env python3
"""
Generate missing terrain and additional item sprites for The Necromancer.
"""

import os
import json
import time
import requests
from pathlib import Path
from PIL import Image
import numpy as np
from io import BytesIO

# Configuration
PROJECT_ROOT = Path(__file__).parent.parent.parent
GRAF_DIR = PROJECT_ROOT / "lib" / "xtra" / "graf"
FINAL_DIR = GRAF_DIR / "final"
WIP_DIR = GRAF_DIR / "wip"
MANIFEST_PATH = GRAF_DIR / "sprite_manifest.json"

# API Key (from generate_all.py)
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")

# If not in env, try to read from generate_all.py
if not OPENAI_API_KEY:
    try:
        with open(Path(__file__).parent / "generate_all.py", 'r') as f:
            content = f.read()
            import re
            match = re.search(r'OPENAI_API_KEY\s*=\s*["\']([^"\']+)["\']', content)
            if match:
                OPENAI_API_KEY = match.group(1)
    except:
        pass

# Base template for all sprites
BASE_TEMPLATE = """{description}

CRITICAL REQUIREMENTS:
- Single sprite only, perfectly centered in frame
- Solid magenta background (#FF00FF) for easy removal
- NO color palette swatches or UI elements
- NO text, labels, watermarks, or borders
- Character/object fills 80% of the frame
- Clear silhouette readable at small size
- Dark fantasy pixel art style
- Top-left lighting, consistent shadows
- 64x64 pixel game sprite aesthetic"""

# =============================================================================
# MISSING TERRAIN SPRITES
# =============================================================================
MISSING_TERRAIN = [
    {
        "id": "F:2",
        "name": "Bottomless Pit",
        "filename": "terrain/t_02_bottomless_pit",
        "description": """A bottomless pit tile, deadly fall trap.
Dark gaping hole in the floor leading to infinite darkness.
Jagged rocky edges, pure black void in center.
Top-down view, clearly dangerous drop."""
    },
    {
        "id": "F:3",
        "name": "Protective Rune",
        "filename": "terrain/t_03_protective_rune",
        "description": """Floor tile with protective magical rune.
Stone floor with glowing green protective symbol.
Circular ward pattern, safe haven indicator.
Top-down view, magical protection effect."""
    },
    {
        "id": "F:7",
        "name": "Warded Door Power 2",
        "filename": "terrain/t_07_warded_door_2",
        "description": """Magically warded door, medium power.
Wooden door with glowing blue magical runes.
More intense glow than basic warded door.
Stronger magical protection visible."""
    },
    {
        "id": "F:8",
        "name": "Warded Door Power 3",
        "filename": "terrain/t_08_warded_door_3",
        "description": """Magically warded door, high power.
Door with intense violet/purple magical runes.
Most powerful ward, swirling magical energy.
Nearly impenetrable magical barrier."""
    },
    {
        "id": "F:14",
        "name": "Shadow Brazier",
        "filename": "terrain/t_14_shadow_brazier",
        "description": """A shadow brazier, source of dark magic.
Iron brazier with dark purple flames.
Emits shadowy wisps, evil light source.
Top-down or hybrid view, ominous glow."""
    },
    {
        "id": "F:15",
        "name": "Torture Rack",
        "filename": "terrain/t_15_torture_rack",
        "description": """A torture rack, dungeon horror.
Wooden torture device with chains and straps.
Dark stained wood, rusty metal parts.
Top-down view, clearly sinister device."""
    },
    {
        "id": "F:18",
        "name": "Poisoned Spike Pit",
        "filename": "terrain/t_18_poisoned_spikes",
        "description": """Trap: pit with poisoned spikes.
Hole in floor with green-tipped metal spikes.
Poison dripping from spike tips.
Top-down view, deadly trap with venom."""
    },
    {
        "id": "F:19",
        "name": "Poison Needle Trap",
        "filename": "terrain/t_19_poison_needle",
        "description": """Trap: hidden poison needle.
Floor tile with tiny hole, needle visible.
Subtle trap, green poison residue.
Top-down view, nearly hidden danger."""
    },
    {
        "id": "F:21",
        "name": "Mind Fog",
        "filename": "terrain/t_21_mind_fog",
        "description": """Trap: mind-affecting fog vent.
Floor vent releasing blue-purple misty fog.
Swirling psychedelic vapors, confusion effect.
Top-down view with visible fog effect."""
    },
    {
        "id": "F:23",
        "name": "Blinding Glyph",
        "filename": "terrain/t_23_blinding_glyph",
        "description": """Trap: blinding light glyph.
Floor with bright yellow magical symbol.
Sun-like rune, radiates intense light.
Top-down view, dangerous if triggered."""
    },
    {
        "id": "F:24",
        "name": "Rusted Caltrops",
        "filename": "terrain/t_24_caltrops",
        "description": """Trap: scattered rusted caltrops.
Floor covered with small spiked metal objects.
Rusty brown, tetanus danger, slows movement.
Top-down view of scattered spikes."""
    },
    {
        "id": "F:25",
        "name": "Bat Roost",
        "filename": "terrain/t_25_bat_roost",
        "description": """Trap: bat roost on ceiling.
Dark ceiling area with sleeping bats visible.
Will disturb and swarm if approached.
Top-down view showing roosting bats."""
    },
    {
        "id": "F:28",
        "name": "Pool of Filth",
        "filename": "terrain/t_28_pool_filth",
        "description": """Trap: disgusting pool of filth.
Stagnant brown-green sewage pool.
Disease hazard, bubbling nastiness.
Top-down view of gross liquid."""
    },
    {
        "id": "F:30",
        "name": "Chains",
        "filename": "terrain/t_30_chains",
        "description": """Hanging chains, dungeon decoration.
Heavy iron chains hanging from ceiling.
Rusty links, clanking hazard.
Top-down or hybrid view of chain pattern."""
    },
    {
        "id": "F:84",
        "name": "Poison Stream",
        "filename": "terrain/t_84_poison_stream",
        "description": """A flowing stream of poison.
Bright green toxic liquid flowing.
Bubbling, steaming poisonous water.
Top-down view of poison river/stream."""
    },
    {
        "id": "F:87",
        "name": "Forest Floor",
        "filename": "terrain/t_87_forest_floor",
        "description": """Natural forest floor tile.
Brown earth with fallen leaves and twigs.
Organic natural ground, outdoor area.
Top-down view, tileable forest ground."""
    },
]

# =============================================================================
# ADDITIONAL ITEM SPRITES (to complement existing ones)
# =============================================================================
ADDITIONAL_ITEMS = [
    {
        "id": "I:arrow",
        "name": "Arrow Bundle",
        "filename": "items/i_arrow",
        "description": """A bundle of arrows, ammunition.
Several arrows bundled together.
Wooden shafts, feathered fletching, metal tips.
Lying on ground or floating item view."""
    },
    {
        "id": "I:torch",
        "name": "Torch",
        "filename": "items/i_torch",
        "description": """A burning wooden torch.
Wooden handle wrapped in cloth, burning flame.
Primary light source, warm orange glow.
Item view with visible flame."""
    },
    {
        "id": "I:lantern",
        "name": "Lantern",
        "filename": "items/i_lantern",
        "description": """A brass lantern, light source.
Metal lantern with glass panels, warm glow.
Portable light, handle visible.
Item view with warm light effect."""
    },
    {
        "id": "I:amulet",
        "name": "Amulet",
        "filename": "items/i_amulet",
        "description": """A magical amulet necklace.
Gold chain with gemstone pendant.
Magical glow around gem.
Item view of neck jewelry."""
    },
    {
        "id": "I:cloak",
        "name": "Cloak",
        "filename": "items/i_cloak",
        "description": """A traveler's cloak.
Folded dark cloth cloak with clasp.
Protective outer garment.
Item view of folded cloak."""
    },
    {
        "id": "I:boots",
        "name": "Boots",
        "filename": "items/i_boots",
        "description": """A pair of leather boots.
Sturdy brown leather boots.
Travel footwear, worn but serviceable.
Item view of boot pair."""
    },
    {
        "id": "I:gloves",
        "name": "Gloves",
        "filename": "items/i_gloves",
        "description": """A pair of leather gloves.
Brown leather hand protection.
Gauntlets or simple gloves.
Item view of glove pair."""
    },
    {
        "id": "I:chest",
        "name": "Chest",
        "filename": "items/i_chest",
        "description": """A treasure chest container.
Wooden chest with metal bands and lock.
May contain treasure or danger.
Item view of closed chest."""
    },
    {
        "id": "I:horn",
        "name": "Horn",
        "filename": "items/i_horn",
        "description": """A horn instrument.
Curved animal horn with mouthpiece.
Can be blown for signal or magic.
Item view of horn instrument."""
    },
    {
        "id": "I:wand",
        "name": "Wand",
        "filename": "items/i_wand",
        "description": """A magical wand.
Short wooden wand with crystal tip.
Magical implement, glowing faintly.
Item view of wand."""
    },
]

# Combine all sprites to generate
ALL_NEW_SPRITES = MISSING_TERRAIN + ADDITIONAL_ITEMS


def remove_magenta_background(img):
    """Remove magenta background and create transparency."""
    data = np.array(img.convert("RGBA"))

    # Detect background from corners
    corners = [data[0,0], data[0,-1], data[-1,0], data[-1,-1]]
    bg_colors = [c[:3] for c in corners if c[3] > 0]

    if bg_colors:
        bg_color = np.mean(bg_colors, axis=0)
    else:
        bg_color = np.array([255, 0, 255])  # Default magenta

    # Create mask for background
    tolerance = 30
    r_diff = np.abs(data[:,:,0].astype(float) - bg_color[0])
    g_diff = np.abs(data[:,:,1].astype(float) - bg_color[1])
    b_diff = np.abs(data[:,:,2].astype(float) - bg_color[2])

    mask = (r_diff < tolerance) & (g_diff < tolerance) & (b_diff < tolerance)

    # Also catch magenta variants
    is_magenta = (data[:,:,0] > 200) & (data[:,:,1] < 100) & (data[:,:,2] > 200)
    is_pink = (data[:,:,0] > 120) & (data[:,:,1] < 100) & (data[:,:,2] > 80)

    mask = mask | is_magenta | is_pink

    # Apply transparency
    data[mask] = [0, 0, 0, 0]

    return Image.fromarray(data, "RGBA")


def generate_sprite(sprite_def, api_key):
    """Generate a single sprite using DALL-E 3."""
    prompt = BASE_TEMPLATE.format(description=sprite_def["description"])

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
        "quality": "hd",
        "response_format": "url"
    }

    response = requests.post(
        "https://api.openai.com/v1/images/generations",
        headers=headers,
        json=payload,
        timeout=120
    )

    if response.status_code != 200:
        raise Exception(f"API error: {response.status_code} - {response.text}")

    result = response.json()
    image_url = result["data"][0]["url"]

    # Download image
    img_response = requests.get(image_url, timeout=60)
    img = Image.open(BytesIO(img_response.content))

    return img


def process_sprite(img, target_size=64):
    """Process generated image: remove background, resize, center."""
    # Remove background
    img = remove_magenta_background(img)

    # Resize to 2x target for quality
    img = img.resize((target_size * 2, target_size * 2), Image.Resampling.LANCZOS)

    # Get bounding box of content
    bbox = img.getbbox()
    if bbox:
        # Crop to content with padding
        padding = 4
        left = max(0, bbox[0] - padding)
        top = max(0, bbox[1] - padding)
        right = min(img.width, bbox[2] + padding)
        bottom = min(img.height, bbox[3] + padding)
        img = img.crop((left, top, right, bottom))

    # Calculate scale to fit within target
    max_dim = max(img.width, img.height)
    fit_size = target_size - 4  # Leave 2px margin

    if max_dim > fit_size:
        scale = fit_size / max_dim
        new_width = int(img.width * scale)
        new_height = int(img.height * scale)
        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # Center on transparent canvas
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    x = (target_size - img.width) // 2
    y = (target_size - img.height) // 2
    canvas.paste(img, (x, y), img)

    return canvas


def load_manifest():
    """Load the sprite manifest."""
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, 'r') as f:
            return json.load(f)
    return {"version": "1.0", "target_size": 64, "sprites": {}}


def save_manifest(manifest):
    """Save the sprite manifest."""
    with open(MANIFEST_PATH, 'w') as f:
        json.dump(manifest, f, indent=2)


def main():
    if not OPENAI_API_KEY:
        print("ERROR: No OpenAI API key found!")
        print("Set OPENAI_API_KEY environment variable or add it to generate_all.py")
        return

    print("=" * 60)
    print("GENERATING MISSING SPRITES")
    print("=" * 60)
    print(f"Sprites to generate: {len(ALL_NEW_SPRITES)}")
    print(f"API Key: {OPENAI_API_KEY[:8]}...{OPENAI_API_KEY[-4:]}")
    print()

    manifest = load_manifest()

    generated = 0
    failed = []

    for sprite in ALL_NEW_SPRITES:
        sprite_id = sprite["id"]
        name = sprite["name"]
        filename = sprite["filename"]

        # Check if already completed
        if sprite_id in manifest.get("sprites", {}) and \
           manifest["sprites"][sprite_id].get("status") == "completed":
            existing_file = GRAF_DIR / manifest["sprites"][sprite_id]["filename"]
            if existing_file.exists():
                print(f"  [SKIP] {sprite_id} - {name} (already exists)")
                continue

        print(f"  Generating {sprite_id} - {name}...")

        try:
            # Generate with DALL-E
            raw_img = generate_sprite(sprite, OPENAI_API_KEY)

            # Save full-size preview
            wip_path = WIP_DIR / (filename.split('/')[-1] + "_preview.png")
            wip_path.parent.mkdir(parents=True, exist_ok=True)
            preview = raw_img.resize((256, 256), Image.Resampling.LANCZOS)
            preview.save(wip_path)

            # Process to 64x64
            final_img = process_sprite(raw_img)

            # Save final sprite
            final_path = FINAL_DIR / (filename.split('/')[-1] + ".png")
            final_path.parent.mkdir(parents=True, exist_ok=True)
            final_img.save(final_path)

            # Update manifest
            manifest.setdefault("sprites", {})[sprite_id] = {
                "status": "completed",
                "name": name,
                "filename": f"final/{filename.split('/')[-1]}.png",
                "attempts": 1,
                "completed": time.strftime("%Y-%m-%dT%H:%M:%SZ")
            }
            save_manifest(manifest)

            generated += 1
            print(f"    ✓ Saved to {final_path.name}")

            # Rate limit: 5 requests per minute
            time.sleep(12)

        except Exception as e:
            print(f"    ✗ Failed: {e}")
            failed.append((sprite_id, name, str(e)))

    print()
    print("=" * 60)
    print("GENERATION COMPLETE")
    print("=" * 60)
    print(f"Generated: {generated}")
    print(f"Failed: {len(failed)}")

    if failed:
        print("\nFailed sprites:")
        for sid, name, err in failed:
            print(f"  {sid} - {name}: {err}")

    print("\nNext steps:")
    print("1. Run assemble_sheet.py to rebuild tileset")
    print("2. Copy to app bundle")
    print("3. Test in game")


if __name__ == "__main__":
    main()
