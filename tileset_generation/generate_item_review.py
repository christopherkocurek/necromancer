#!/usr/bin/env python3
"""
Generate item_v3_review.html — a self-contained HTML review page for item sprites.
Base64-embeds all sprite images so no external dependencies.
"""

import os
import sys
import json
import base64
import re
from pathlib import Path
from collections import defaultdict

BASE_DIR = Path(__file__).parent
ITEM_V3_DIR = BASE_DIR / "item_v3"
PROGRESS_PATH = BASE_DIR / "item_v3_progress.json"
OBJECT_TXT = BASE_DIR.parent / "data" / "object.txt"
OUTPUT_PATH = BASE_DIR / "item_v3_review.html"

# Category display order
CATEGORY_ORDER = [
    "sword", "polearm", "hafted", "digging", "bow", "sling", "arrow", "sling_stone",
    "body_armor", "soft_armor", "helm", "crown", "shield", "cloak", "boots", "gloves",
    "ring", "amulet",
    "potion", "herb", "scroll", "wand", "horn", "oil",
    "light", "chest", "document",
    "skeleton", "special_material", "food", "misc", "unknown",
]


def load_progress():
    """Load item_v3_progress.json and build id->name mapping."""
    if not PROGRESS_PATH.exists():
        return {}
    with open(PROGRESS_PATH) as f:
        data = json.load(f)
    names = {}
    for key, info in data.get("sprites", {}).items():
        item_id = info.get("item_id")
        name = info.get("name", "")
        if item_id is not None and name:
            names[item_id] = name
    return names


def load_object_txt_names():
    """Parse object.txt for N: lines to get item_id -> name mapping."""
    names = {}
    if not OBJECT_TXT.exists():
        return names
    with open(OBJECT_TXT) as f:
        for line in f:
            line = line.strip()
            if line.startswith("N:"):
                parts = line[2:].split(":", 1)
                try:
                    item_id = int(parts[0])
                except ValueError:
                    continue
                name = parts[1].strip() if len(parts) > 1 else ""
                # Clean up & and ~ markers used for grammar
                name = name.replace("&", "").replace("~", "").strip()
                # Collapse multiple spaces
                name = re.sub(r'\s+', ' ', name)
                names[item_id] = name
    return names


def scan_sprites():
    """Scan item_v3/ subdirectories for all *_light.png files.
    Returns: list of dicts with keys: id, category, light_path, dark_path
    """
    sprites = []
    if not ITEM_V3_DIR.exists():
        return sprites

    for subdir in sorted(ITEM_V3_DIR.iterdir()):
        if not subdir.is_dir():
            continue
        category = subdir.name
        if category in ("raw", "montages"):
            continue
        for png in sorted(subdir.glob("item_*_light.png")):
            # Parse ID from filename: item_64_light.png -> 64
            match = re.match(r'item_(\d+)_light\.png', png.name)
            if not match:
                continue
            item_id = int(match.group(1))
            dark_path = png.parent / png.name.replace("_light.png", "_dark.png")
            sprites.append({
                "id": item_id,
                "category": category,
                "light_path": png,
                "dark_path": dark_path if dark_path.exists() else None,
            })
    return sprites


def encode_image(path):
    """Base64-encode a PNG file."""
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("ascii")


def generate_html(sprites, names):
    """Generate the full HTML page."""

    # Group by category
    by_category = defaultdict(list)
    for s in sprites:
        by_category[s["category"]].append(s)

    # Sort each category by ID
    for cat in by_category:
        by_category[cat].sort(key=lambda x: x["id"])

    # Determine actual category order (only categories with sprites)
    categories = []
    for cat in CATEGORY_ORDER:
        if cat in by_category:
            categories.append(cat)
    # Add any categories not in the predefined order
    for cat in sorted(by_category.keys()):
        if cat not in categories:
            categories.append(cat)

    total_sprites = sum(len(by_category[c]) for c in categories)

    # Build sprite cards HTML
    cards_html = []
    for cat in categories:
        cat_display = cat.replace("_", " ").title()
        count = len(by_category[cat])
        cards_html.append(f'<div class="category-section" id="cat-{cat}">')
        cards_html.append(f'  <h2 class="category-header">{cat_display} <span class="count">({count})</span></h2>')
        cards_html.append('  <div class="sprite-grid">')
        for s in by_category[cat]:
            item_id = s["id"]
            name = names.get(item_id, f"Unknown #{item_id}")
            b64 = encode_image(s["light_path"])
            cards_html.append(f'    <div class="sprite-card" data-id="{item_id}" onclick="toggleSelect(this)">')
            cards_html.append(f'      <img src="data:image/png;base64,{b64}" alt="{name}" width="256" height="256" class="sprite-img">')
            cards_html.append(f'      <div class="sprite-name">{name}</div>')
            cards_html.append(f'      <div class="sprite-id">#{item_id}</div>')
            cards_html.append(f'    </div>')
        cards_html.append('  </div>')
        cards_html.append('</div>')

    cards_block = "\n".join(cards_html)

    # Build nav links
    nav_links = []
    for cat in categories:
        cat_display = cat.replace("_", " ").title()
        count = len(by_category[cat])
        nav_links.append(f'<a href="#cat-{cat}" class="nav-link">{cat_display} ({count})</a>')
    nav_block = "\n      ".join(nav_links)

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Item Sprites v3 Review</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    background: #1a1a2e;
    color: #e0e0e0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding-top: 110px;
  }}
  .nav-bar {{
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 100;
    background: #16213e;
    border-bottom: 1px solid #0f3460;
    padding: 8px 16px;
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    align-items: center;
  }}
  .nav-label {{
    color: #8899aa;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-right: 8px;
    white-space: nowrap;
  }}
  .nav-link {{
    color: #53a8e2;
    text-decoration: none;
    font-size: 13px;
    padding: 3px 8px;
    border-radius: 4px;
    background: #1a1a2e;
    border: 1px solid #0f3460;
    white-space: nowrap;
    transition: background 0.15s, color 0.15s;
  }}
  .nav-link:hover {{
    background: #0f3460;
    color: #fff;
  }}
  .selection-bar {{
    position: fixed;
    top: 44px;
    left: 0;
    right: 0;
    z-index: 99;
    background: #1a1a2e;
    border-bottom: 1px solid #0f3460;
    padding: 6px 16px;
    display: flex;
    align-items: center;
    gap: 12px;
    min-height: 38px;
  }}
  .selection-bar .label {{
    color: #8899aa;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    white-space: nowrap;
  }}
  .selection-ids {{
    flex: 1;
    background: #16213e;
    border: 1px solid #0f3460;
    border-radius: 4px;
    padding: 4px 8px;
    color: #e0e0e0;
    font-family: 'Consolas', 'Courier New', monospace;
    font-size: 13px;
    min-height: 24px;
    overflow-x: auto;
    white-space: nowrap;
    cursor: text;
    user-select: all;
  }}
  .selection-count {{
    color: #53a8e2;
    font-size: 13px;
    font-weight: 600;
    white-space: nowrap;
  }}
  .btn {{
    background: #0f3460;
    color: #53a8e2;
    border: 1px solid #53a8e2;
    padding: 4px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    white-space: nowrap;
    transition: background 0.15s, color 0.15s;
  }}
  .btn:hover {{
    background: #53a8e2;
    color: #1a1a2e;
  }}
  .stats-bar {{
    padding: 10px 16px;
    color: #8899aa;
    font-size: 13px;
    border-bottom: 1px solid #0f3460;
  }}
  .stats-bar strong {{
    color: #53a8e2;
  }}
  .category-section {{
    padding: 0 16px;
    margin-bottom: 32px;
  }}
  .category-header {{
    color: #e94560;
    font-size: 20px;
    font-weight: 700;
    padding: 16px 0 12px;
    border-bottom: 2px solid #e94560;
    margin-bottom: 16px;
  }}
  .category-header .count {{
    color: #8899aa;
    font-weight: 400;
    font-size: 15px;
  }}
  .sprite-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 12px;
  }}
  .sprite-card {{
    background: #16213e;
    border: 3px solid transparent;
    border-radius: 8px;
    padding: 12px;
    text-align: center;
    cursor: pointer;
    transition: border-color 0.15s, transform 0.1s, box-shadow 0.15s;
  }}
  .sprite-card:hover {{
    border-color: #335577;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  }}
  .sprite-card.selected {{
    border-color: #53a8e2;
    box-shadow: 0 0 12px rgba(83, 168, 226, 0.4);
  }}
  .sprite-img {{
    image-rendering: pixelated;
    image-rendering: crisp-edges;
    display: block;
    margin: 0 auto 8px;
    background: #111;
    border-radius: 4px;
  }}
  .sprite-name {{
    color: #e0e0e0;
    font-size: 14px;
    font-weight: 600;
    margin-bottom: 2px;
    word-break: break-word;
  }}
  .sprite-id {{
    color: #8899aa;
    font-size: 12px;
    font-family: 'Consolas', 'Courier New', monospace;
  }}

  /* Scrollbar styling */
  ::-webkit-scrollbar {{ width: 8px; }}
  ::-webkit-scrollbar-track {{ background: #1a1a2e; }}
  ::-webkit-scrollbar-thumb {{ background: #0f3460; border-radius: 4px; }}
  ::-webkit-scrollbar-thumb:hover {{ background: #53a8e2; }}
</style>
</head>
<body>

<div class="nav-bar">
  <span class="nav-label">Categories:</span>
  {nav_block}
</div>

<div class="selection-bar">
  <span class="label">Selected:</span>
  <div class="selection-ids" id="selectionIds">None</div>
  <span class="selection-count" id="selectionCount">0 selected</span>
  <button class="btn" onclick="copyIds()">Copy IDs</button>
  <button class="btn" onclick="clearSelection()">Clear</button>
</div>

<div class="stats-bar">
  <strong>{total_sprites}</strong> sprites across <strong>{len(categories)}</strong> categories
</div>

{cards_block}

<script>
const selectedIds = new Set();

function toggleSelect(card) {{
  const id = card.dataset.id;
  if (selectedIds.has(id)) {{
    selectedIds.delete(id);
    card.classList.remove('selected');
  }} else {{
    selectedIds.add(id);
    card.classList.add('selected');
  }}
  updateSelectionBar();
}}

function updateSelectionBar() {{
  const idsDiv = document.getElementById('selectionIds');
  const countSpan = document.getElementById('selectionCount');
  const sorted = Array.from(selectedIds).map(Number).sort((a, b) => a - b);
  if (sorted.length === 0) {{
    idsDiv.textContent = 'None';
    countSpan.textContent = '0 selected';
  }} else {{
    idsDiv.textContent = sorted.join(', ');
    countSpan.textContent = sorted.length + ' selected';
  }}
}}

function copyIds() {{
  const sorted = Array.from(selectedIds).map(Number).sort((a, b) => a - b);
  if (sorted.length === 0) {{
    return;
  }}
  const text = sorted.join(', ');
  navigator.clipboard.writeText(text).then(() => {{
    const btn = event.target;
    const orig = btn.textContent;
    btn.textContent = 'Copied!';
    btn.style.background = '#53a8e2';
    btn.style.color = '#1a1a2e';
    setTimeout(() => {{
      btn.textContent = orig;
      btn.style.background = '';
      btn.style.color = '';
    }}, 1200);
  }});
}}

function clearSelection() {{
  selectedIds.clear();
  document.querySelectorAll('.sprite-card.selected').forEach(c => c.classList.remove('selected'));
  updateSelectionBar();
}}

document.addEventListener('keydown', (e) => {{
  if (e.key === 'Escape') {{
    clearSelection();
  }}
}});
</script>

</body>
</html>"""
    return html


def main():
    print("Loading item names from progress JSON...")
    progress_names = load_progress()
    print(f"  Found {len(progress_names)} names in progress JSON")

    print("Loading item names from object.txt...")
    object_names = load_object_txt_names()
    print(f"  Found {len(object_names)} names in object.txt")

    # Merge: progress takes priority, then object.txt
    all_names = {}
    all_names.update(object_names)
    all_names.update(progress_names)
    print(f"  Combined: {len(all_names)} unique item names")

    print("Scanning item_v3/ for sprites...")
    sprites = scan_sprites()
    print(f"  Found {len(sprites)} light sprites")

    if not sprites:
        print("ERROR: No sprites found in item_v3/")
        sys.exit(1)

    print("Generating HTML with base64-embedded images...")
    html = generate_html(sprites, all_names)

    print(f"Writing {OUTPUT_PATH}...")
    with open(OUTPUT_PATH, "w") as f:
        f.write(html)

    size_mb = os.path.getsize(OUTPUT_PATH) / (1024 * 1024)
    print(f"Done! {OUTPUT_PATH.name} ({size_mb:.1f} MB)")
    print(f"  {len(sprites)} sprites, {len(set(s['category'] for s in sprites))} categories")


if __name__ == "__main__":
    main()
