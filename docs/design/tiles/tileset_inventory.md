# The Necromancer - Existing Tileset Inventory

Generated for tileset PRD AUDIT-003.

## 1. Currently Included Tilesets

### MicroChasm Tileset (Included)
- **Size**: 16x16 pixels
- **File**: `lib/xtra/graf/16x16_microchasm.png`
- **Format**: PNG with transparency
- **License**: Unknown (inherited from Sil-Q)
- **Coverage**: ~640 tiles (monsters, terrain, items, effects)
- **Style**: Classic pixel art, dark fantasy theme

### Adam Bolt Tileset (Legacy)
- **Size**: 16x16 pixels
- **File**: `lib/xtra/graf/16x16.bmp`
- **Format**: BMP (legacy)
- **License**: "Redistribution and use, for any purpose, with or without modification, is permitted"
- **Notes**: Original Angband tileset, very dated appearance

---

## 2. Available Open Source Tilesets

### David E. Gervais / TomeTik (Recommended)
- **Size**: 32x32 pixels (also 54x54 isometric)
- **Source**: http://pousse.rapiere.free.fr/tome/
- **License**: CC-BY 3.0 (Attribution required)
- **Coverage**: Extensive - weapons, armor, items, monsters, terrain
- **Originally designed for**: Angband, expanded for ToME (Tales of Middle Earth)
- **Pros**:
  - Complete coverage for typical roguelike needs
  - Dark fantasy aesthetic matches The Necromancer
  - Permissive license
  - Includes Middle-earth themed content
- **Cons**:
  - May need customization for unique Necromancer monsters
  - Would need to create PRF mappings

### Shockbolt Tileset
- **Size**: 32x32 and 64x64 pixels available
- **Source**: Angband community
- **License**: Free for non-commercial projects
- **Coverage**: Full Angband monster/item/terrain set
- **Pros**:
  - Higher resolution options
  - Modern pixel art style
- **Cons**:
  - Commercial use restrictions
  - May not cover all Necromancer-specific content

### RLTiles (Public Domain)
- **Size**: 32x32 pixels
- **Source**: Various roguelike projects
- **License**: Public domain (attribution requested)
- **Coverage**: Generic fantasy creatures, items, terrain
- **Pros**:
  - No license restrictions
  - Large collection
- **Cons**:
  - Generic style, not specifically Tolkien-themed
  - May require significant customization

### Liberated Pixel Cup Assets
- **Size**: 32x32 pixels
- **Source**: https://opengameart.org
- **License**: CC-BY-SA 3.0 and GPLv3 dual-licensed
- **Coverage**: Characters, items, terrain
- **Pros**:
  - Very permissive licensing
  - High quality community art
- **Cons**:
  - Not roguelike-specific
  - Would need significant adaptation

---

## 3. AI Generation Tools (For Custom Content)

### Recommended Tools for New Sprites

| Tool | Type | Best For | Notes |
|------|------|----------|-------|
| DALL-E 3 | Text-to-image | Concept art, references | Not pixel-perfect |
| Midjourney | Text-to-image | Style inspiration | Requires manual pixelization |
| Stable Diffusion | Text-to-image | Bulk generation | Local, more control |
| PixAI | Pixel art specific | 32x32 sprites | Purpose-built for game sprites |
| Aseprite | Editor | Refinement | Industry standard pixel editor |
| Lospec Palette | Reference | Color consistency | Pixel art color palettes |

### Recommended Workflow
1. Use TomeTik as base for common creatures
2. Generate custom sprites for unique Necromancer content via AI
3. Refine and pixel-perfect in Aseprite
4. Maintain consistent 32x32 format and palette

---

## 4. License Summary

| Tileset | License | Commercial OK | Attribution |
|---------|---------|---------------|-------------|
| MicroChasm | Unknown | TBD | TBD |
| Adam Bolt | Permissive | Yes | No |
| TomeTik/Gervais | CC-BY 3.0 | Yes | Required |
| Shockbolt | Non-commercial | No | Yes |
| RLTiles | Public Domain | Yes | Requested |
| LPC Assets | CC-BY-SA 3.0 | Yes | Required |

---

## 5. Recommendations for The Necromancer

### Primary Approach: AI-Generated Custom Tileset
Given the unique theme (Dol Guldur, Mirkwood, Third Age), create a **custom 32x32 tileset** using:

1. **Base sprites** from TomeTik (CC-BY 3.0) for:
   - Generic terrain (floors, walls, doors)
   - Common items (swords, armor, potions)
   - Generic creatures where applicable

2. **AI-generated sprites** for unique content:
   - Mirkwood spiders (custom designs)
   - Dol Guldur orcs (dark, corrupted style)
   - Nazgûl and Sauron (iconic, needs to be perfect)
   - Layer-specific terrain (torture halls, necropolis, etc.)

3. **Hand-refinement** in Aseprite for:
   - Consistency pass
   - Animation frames (if any)
   - Icon/UI elements

### Color Palette Recommendation
Use a **dark, desaturated palette** to match Dol Guldur's atmosphere:
- Shadows: Deep purples, blacks
- Stone: Gray-blue, muted
- Corruption: Sickly greens, violet
- Fire/Magic: Orange, red accents
- Mirkwood: Dark greens, browns

### Tile Count Estimate
| Category | TomeTik Base | Custom Needed | Total |
|----------|-------------|---------------|-------|
| Terrain | 20 | 15 | 35 |
| Monsters | 30 | 35 | 65 |
| Items | 40 | 10 | 50 |
| Effects | 10 | 5 | 15 |
| UI | 5 | 5 | 10 |
| **Total** | **105** | **70** | **175** |

---

## 6. Sources

- [RogueBasin - Finding Graphical Tiles](https://www.roguebasin.com/index.php/Finding_graphical_tiles)
- [OpenGameArt - Roguelike Tiles Collection](https://opengameart.org/content/roguelike-tiles-large-collection)
- [TomeTik/Gervais Tiles](http://pousse.rapiere.free.fr/tome/)
- [Angband Forums - 64x64 Tileset Discussion](https://angband.live/forums/forum/angband/development/3656-angband-64-x-64-pixel-tileset)
