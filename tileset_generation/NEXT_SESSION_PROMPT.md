# DCSS Tileset Integration - Session Prompt

Copy and paste this into a new Claude session to continue the tileset work.

---

## Prompt

```
I need you to complete the DCSS tileset integration for the Necromancer roguelike game.

## Context

The game is at `~/dev/active/games/necromancer-godot/`. We attempted to generate tiles with DALL-E 3 but it failed (wrong perspective, inconsistent styles). We're now using DCSS (Dungeon Crawl Stone Soup) tiles instead.

A demo was created at `tileset_generation/dcss_demo/` showing this approach works.

## Your Task

Complete the full DCSS tileset integration by following the plan at:
`tileset_generation/DCSS_INTEGRATION_PLAN.md`

## Summary of What Needs to Be Done

1. **Download all DCSS tiles** from https://github.com/crawl/crawl
   - Clone sparse checkout of `crawl-ref/source/rltiles/`
   - We need: terrain, monsters, items, player sprites

2. **Create mapping script** (`dcss_mapper.py`)
   - Read `manifest.json` (682 entities)
   - Map each Necromancer entity to best DCSS tile
   - Copy tiles to `tileset_generation/dcss_tiles/`
   - Generate dark variants (desaturate 60%, darken 40%) for FOV
   - Output `dcss_mapping.json`

3. **Scale tiles**
   - DCSS: 32x32 pixels
   - Necromancer: 64x64 pixels
   - Use 2x nearest-neighbor scaling

4. **Assemble tileset**
   - 32x32 grid = 1024 slots
   - Output: 2048x2048 PNG
   - Save to `assets/sprites/64x64_necromancer.png`

5. **Update tile_mapper.gd**
   - Change grid size from 16 to 32
   - Update all coordinate lookups from `dcss_mapping.json`

6. **Test the game runs** with new tileset

## Key Files

- `tileset_generation/DCSS_INTEGRATION_PLAN.md` - Full plan with entity mappings
- `tileset_generation/manifest.json` - All 682 entities from data files
- `tileset_generation/layout_map.json` - Grid coordinate assignments
- `tileset_generation/dcss_demo/` - Working demo showing approach
- `scripts/core/tile_mapper.gd` - Needs updating for new coordinates

## Technical Notes

- DCSS is GPL licensed - document this
- Use nearest-neighbor scaling (preserves pixel art)
- Player sprites: 1 masculine sprite per race (Elf, Man, Dwarf, Istari)
- Flag Tolkien-specific entities (Nazgûl, Sauron) for later custom art
- Dark variants are for FOV system (tiles outside line of sight)

## Success Criteria

- [ ] All terrain renders correctly
- [ ] All monsters have sprites
- [ ] All items have sprites
- [ ] FOV shows light/dark variants
- [ ] Game launches without missing texture errors
- [ ] Playable from character creation through dungeon

Please read the DCSS_INTEGRATION_PLAN.md first, then proceed with implementation.
```

---

## Alternative: Shorter Version

```
Complete the DCSS tileset integration for Necromancer at ~/dev/active/games/necromancer-godot/

Read the plan: tileset_generation/DCSS_INTEGRATION_PLAN.md

Tasks:
1. Download DCSS tiles from GitHub
2. Map 682 Necromancer entities to DCSS tiles (see manifest.json)
3. Scale 32x32 → 64x64, generate dark variants for FOV
4. Assemble into 2048x2048 tileset PNG
5. Update tile_mapper.gd with new coordinates
6. Test game runs

The demo at tileset_generation/dcss_demo/ shows this approach works.
```
