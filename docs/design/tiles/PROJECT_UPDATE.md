# Environmental Tileset Review - Project Update

**Date**: 2026-02-01
**Status**: Environmental tiles identified as needing rework

---

## Summary

We reviewed the environmental tileset for The Necromancer and identified significant issues with the floor, wall, and terrain tiles. The current tiles lack visual distinction and character.

---

## What Was Done

### 1. Created Environmental Tile Specification
**File**: `docs/design/tiles/environmental_spec.md`

Defines the **luminosity hierarchy** that environmental tiles must follow:
- **Floors**: ~68% luminosity (LIGHTER than walls)
- **Walls**: ~30-35% luminosity (DARKER than floors)
- **Darkness**: ~15% luminosity (Shadow Purple #2a1a2a, never pure black)
- **Minimum contrast ratio**: 1.5:1 between floor and wall

Key insight: Passable terrain must be visually LIGHTER than impassable terrain for instant readability.

### 2. Updated Style Guide
**File**: `docs/design/tiles/style_guide.md`

Added luminosity hierarchy reference to Section 4 (Terrain Rules).

### 3. Created Visual Mockup
**File**: `docs/design/tiles/environmental_mockup.html`

HTML comparison showing:
- Current 64x64 Necromancer environmental tiles
- Side-by-side floor/wall/darkness contrast
- Room layout test with actual tiles
- Reference showing correct luminosity with solid colors

Open in browser: `open docs/design/tiles/environmental_mockup.html`

---

## Current Problems Identified

### The Environmental Tiles Look Bad

Reviewed these specific tiles:
- `t_01_stone_floor.png` - Dark gray grid, no texture or depth
- `t_09_fading_daylight.png` - Same grid with tan tint, nearly identical to floor
- `t_87_forest_floor.png` - Brown noise with dots, looks muddy
- `t_56_dark_stone_wall.png` - Dark horizontal bricks, very basic

**Issues**:
1. All tiles are essentially flat colored grids
2. No depth, texture, or visual interest
3. Floor and daylight are nearly identical
4. Forest is just brown noise
5. Lack character compared to the monster/item sprites

**What's Actually Correct**:
- Wall IS darker than floor (luminosity hierarchy is right)
- The concept is sound, execution is poor

---

## Tile Locations

**Tileset**: `/lib/xtra/graf/64x64_necromancer.png`
**Individual tiles**: `/lib/xtra/graf/final/terrain/`
**PRF mappings**: `/lib/pref/graf-necromancer.prf`
**Sprite manifest**: `/lib/xtra/graf/sprite_manifest.json`

---

## Options for Fixing

1. **Regenerate with better AI prompts** - emphasize pixel art texture, depth, lighting
2. **Use existing roguelike tileset as base** - DCSS, Oryx, or similar
3. **Hand-edit in Aseprite** - add texture, shading, cracks, moss
4. **Hybrid approach** - reference tileset for environment, keep custom monsters/items

---

## Files Created This Session

```
docs/design/tiles/
├── environmental_spec.md      # Full specification for environmental tiles
├── environmental_mockup.html  # Visual comparison (open in browser)
├── PROJECT_UPDATE.md          # This file
└── style_guide.md             # Updated with luminosity hierarchy
```

---

## Next Steps

1. Decide on approach for fixing environmental tiles
2. Either regenerate, find reference art, or hand-edit
3. Update the tileset PNG with new environmental tiles
4. Test in-game to verify readability

---

## Key Reference: Luminosity Hierarchy

```
100%  Light sources, sunlight
 68%  FLOORS (passable) - must be LIGHTER than walls
 50%  Interactive (doors, stairs)
 35%  WALLS (impassable) - must be DARKER than floors
 15%  Darkness/void (never pure black)
```

**The Rule**: If you squint at a room, you should instantly see light pools (floors) surrounded by dark borders (walls).
