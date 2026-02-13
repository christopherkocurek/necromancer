# AGENTS.md

## Audit Bootstrap (Required)
For any new implementation review or audit session in this repository:
1. Read `SESSION_AUDIT_CONTEXT.md` first.
2. Treat it as the latest baseline of shipped-in-session changes.
3. Validate behavior against its "Audit Checklist" before proposing new gap findings.

## Scope Note
If current code conflicts with `SESSION_AUDIT_CONTEXT.md`, report the mismatch explicitly as either:
- regression,
- incomplete implementation, or
- stale context note.

## Tileset Gen Memory (Required)
For any tileset/monster sprite remap or patch workflow:
1. Never allow duplicate `monster_coords[...]` atlas cells in `scripts/core/tile_mapper.gd`.
2. Before patching atlas tiles, run:
   - `python3 tileset_generation/check_monster_tile_collisions.py`
3. After mapping edits and patches, run again and require zero collisions.
4. Export a verification pack for the touched monster IDs:
   - `python3 tileset_generation/export_monster_mapping_examples.py --ids <ids...> --out example`
5. If two IDs share a cell, both resolve to the exact same rendered tile (no priority rule). Treat this as a blocker.
