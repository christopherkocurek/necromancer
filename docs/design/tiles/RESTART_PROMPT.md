# Restart Prompt for Claude

Copy/paste this to resume the environmental tileset work:

---

## Prompt

I'm working on The Necromancer (a Sil-Q fork roguelike) and need to fix the environmental tiles in the 64x64 tileset.

**Context**: Read `docs/design/tiles/PROJECT_UPDATE.md` for full context on where we left off.

**The Problem**: The current environmental tiles (floor, wall, daylight, forest) are boring flat grids with no texture or character. They technically follow the luminosity hierarchy (wall is darker than floor) but they look like shit.

**Tiles that need rework**:
- `lib/xtra/graf/final/terrain/t_01_stone_floor.png` - needs texture, depth
- `lib/xtra/graf/final/terrain/t_09_fading_daylight.png` - needs to look like actual light
- `lib/xtra/graf/final/terrain/t_87_forest_floor.png` - needs to look like forest, not brown noise
- `lib/xtra/graf/final/terrain/t_56_dark_stone_wall.png` - needs depth and character

**The spec**: See `docs/design/tiles/environmental_spec.md` for the luminosity requirements and visual guidelines.

**The mockup**: Open `docs/design/tiles/environmental_mockup.html` in a browser to see the current tiles in context.

**Options we discussed**:
1. Regenerate with better AI prompts
2. Use an existing roguelike tileset (DCSS, Oryx) as reference/base
3. Hand-edit in Aseprite
4. Hybrid approach

Help me decide on an approach and then execute it. The goal is environmental tiles that:
- Have clear luminosity hierarchy (floors lighter than walls)
- Have actual texture and visual interest
- Look like pixel art, not flat colored grids
- Match the darker Dol Guldur aesthetic

---

## Quick Commands

```bash
# Go to project
cd ~/dev/active/games/necromancer-master

# Open the mockup
open docs/design/tiles/environmental_mockup.html

# View current terrain tiles
ls lib/xtra/graf/final/terrain/

# View the tileset
open lib/xtra/graf/64x64_necromancer.png
```
