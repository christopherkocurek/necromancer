# TILESET_GEN_SKILL_MEMORY.md

Purpose: operational do/don't memory for tileset generation and sprite remap sessions.

Last updated: 2026-02-13

## Required Flow
1. Verify mapping collisions before any edits:
   - `python3 tileset_generation/check_monster_tile_collisions.py`
2. Make the smallest mapping/atlas fix.
3. Verify collisions again; result must be zero.
4. Export proof images for touched monster IDs:
   - `python3 tileset_generation/export_monster_mapping_examples.py --ids <ids...> --out example`
5. Validate in-game spawn visuals, not just atlas crops.

## Session Lessons (Do)
- Treat spawn, interaction, and rendering as separate systems when debugging visual reports.
- If entity is interactable but invisible, inspect render/material/z-order and visibility logic; do not assume mapping is wrong.
- Use deterministic anchors for endgame placement tests (e.g., relative to Sauron), not brittle fixed absolute coordinates.
- Use temporary visibility diagnostics when blocked:
  - high-z override sprite,
  - no-shader fallback,
  - beacon marker above tile.
- Keep proof artifacts for touched IDs in a review folder (`example/`) for quick human verification.
- For pale-color background cleanup requests, prefer atlas-local post-processing (chroma cleanup) over regeneration.
- Create before/after crops per touched ID and keep a one-file atlas backup before destructive edits.

## Session Lessons (Don't)
- Do not remap IDs blindly from memory; always confirm live atlas crop from current `tile_mapper.gd`.
- Do not assume a tile issue is solved from atlas preview alone; verify actual in-game spawned entity.
- Do not ship massive test/output directories in gameplay fix commits.
- Do not assume corner flood-fill catches all chroma spill; verify per-ID histograms and rerun targeted keying if needed.

## Commit Hygiene for Tileset Work
- Archive large local test/output data outside repo before push (logs, bot results, tmp exports).
- Keep commits focused on:
  - mapping/data files,
  - atlas files,
  - required scripts/docs only.
- If push fails due size, split commits and retry lean payloads.
