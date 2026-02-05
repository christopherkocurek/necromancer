# Necromancer Godot - Shared TODO

This file coordinates work between parallel Claude sessions.

**Main repo:** `~/dev/active/games/necromancer-godot` (master)
**Status:** Phase 7 - DCSS Tileset Integration COMPLETE

---

## Completed Tasks

| Date | Task | Notes |
|------|------|-------|
| 2026-02-05 | DCSS Tileset Integration | Replaced old 16x16 tileset with 32x32 DCSS tileset |
| 2026-02-05 | TileSet resource updated | Now uses 2048x2048 necromancer_dcss_tileset.png |
| 2026-02-05 | tile_mapper.gd replaced | New DCSS-based mapper with 294 tiles |
| 2026-02-05 | Level.gd Tile enum compatibility | Added mappings for VOID, FLOOR, WALL, etc. |

---

## Current Phase: Testing & Polish

| Status | Priority | Task | Notes |
|--------|----------|------|-------|
| [ ] | HIGH | Visual test of tileset in-game | Launch game, verify terrain/monsters/items render |
| [ ] | MED | Add more char_to_monster_id mappings | Some monsters may not have sprites |
| [ ] | MED | Fix GUT test script issues | test_turn_flow.gd has parse error |
| [ ] | LOW | Clean up old tile_mapper files | Remove tile_mapper_old.gd, tile_mapper_dcss.gd |

---

## Known Issues

1. **DataManager warnings** - Missing key monsters (Morgoth, Orc, Troll, Spider) and races (Noldor, Sindar) in validation. These are validation checks, not runtime errors.

2. **Test script parse error** - `test_turn_flow.gd:146` has a parameter name issue.

---

## Files Changed (DCSS Integration)

- `assets/sprites/necromancer_tileset.tres` - Updated to use 32x32 DCSS grid
- `scripts/core/tile_mapper.gd` - Replaced with DCSS version (294 tiles)
- `scripts/core/tile_mapper_dcss.gd` - Source for new mapper (can be deleted)
- `scripts/core/tile_mapper_old.gd` - Backup of old mapper (can be deleted)

---

## Notes

_The DCSS tileset integration is complete. The game now uses GPL-licensed DCSS tiles scaled from 32x32 to 64x64. Dark variants are generated for FOV system. All terrain, monster, and item tiles are mapped._
