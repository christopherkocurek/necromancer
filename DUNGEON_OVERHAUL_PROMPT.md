# Dungeon Generation Overhaul — Implementation Prompt

**Paste this into a fresh Claude Code session from `~/dev/active/games/necromancer-godot/`**

---

## Prompt

```
Read the plan at ~/.claude/plans/wondrous-snacking-kettle.md — it contains the complete architecture for a 6-stream procedural map generation overhaul.

Execute ALL 6 streams using parallel sub-agents with self-healing test loops (run godot --path . --headless --quit-after 3 after each .gd edit to catch crashes).

Here's the summary of what each stream does:

### Stream A: Data Layer Fixes (data_manager.gd)
- Fix VaultData class: add flags, rarity, compute_dimensions() from map_lines
- Fix load_vaults(): parse F: lines, fix X: field mapping (field[2] = rarity, not height)
- Add get_vaults_by_type_for_depth(), get_weighted_vault() with rarity-based selection
- Add get_themed_monster_for_depth() using LayerConfig monster tables
- Add get_themed_item_for_depth() using LayerConfig item tval tables
- Expand get_monster_by_char() with full 26+ vault symbol alphabet
- Add 12 _pick_*_for_depth() helpers for depth-scaled monster selection

### Stream B: Room Type System (dungeon_generator.gd)
- Add RoomType enum: STANDARD, CROSS, L_SHAPE, CIRCULAR, VAULT_INTERESTING/LESSER/GREATER
- Extend Room class with room_type, vault_data, tiles array
- Add _generate_cross_room(), _generate_l_room(), _generate_circular_room()
- Add _select_room_type(depth) — depth-weighted selection (more vaults at deeper levels)
- Replace _generate_rooms() with type-aware generation loop
- Add per-run greater vault tracking in GameManager

### Stream C: Vault Enhancement (dungeon_generator.gd)
- Vault rotation: _rotate_vault_90(), _flip_vault_h/v(), _transform_vault() with NO_ROTATION flag
- Complete vault symbol parser: all terrain (#.+s><^07:;,=-|_~%$), items (*&?), monsters (1-4, uppercase/lowercase boss letters)
- Vault flag processing: WEBS (5% web), TRAPS (2x density), LIGHT (permanent lit), SURFACE (depth penalty)
- Corridor connection points ($) linked to nearest rooms
- BFS connectivity validation — retry generation up to 10 times if disconnected
- Forge guarantees — _ensure_forges() places forge in middle room if missing

### Stream D: Layer Terrain & Decorators (level.gd, dungeon_generator.gd, tile_mapper.gd, layer_config.gd)
- Add 8 new Level.Tile enum values (19-26): WEB, DARK_POOL, MORGUL_RUNE, SHADOW_BRAZIER, GLYPH_OF_WARDING, BONE_PILE, SHADOW_FLOOR, THRONE_DAIS
- Update is_passable(), get_movement_cost(), on_entity_step() for each
- Shadow brazier anti-light pass in apply_lighting()
- Replace _apply_forest_terrain() + _apply_themed_rooms() + _generate_poison_streams() with unified _apply_layer_decoration(depth) dispatcher
- 7 layer decorators: outer_pits (webs), orc_warrens (barracks/armory/kennel), torture_halls (ritual/torture/runes), necropolis (crypt/bone/ritual), wraith_domain (void/shadow/chasm), inner_sanctum (grand halls/guard posts), throne_room (dais/lava moat/pillars)
- Chasm system for depths 3+ (random walk, connectivity-safe)
- DALL-E sprite generation: 8 new terrain sprites on tileset row 18 (~$0.32)
- Add decoration_params to LayerConfig per layer

### Stream E: Monster & Item Spawning (dungeon_generator.gd, layer_config.gd)
- LAYER_MONSTER_TABLES constant: weighted monster pools per layer (spiders L1, orcs L2, undead L4, wraiths L5, etc.)
- LAYER_ITEM_TVALS constant: item type weights per layer (herbs L1, weapons L2, light sources L4, rings L5+)
- Replace _spawn_monsters() with room-aware density: (rooms + dieroll(rooms))/2 + depth/3
- Replace _spawn_items() with 75% of monster target, themed selection
- Door guard placement: 15%+2%/depth chance per door
- Boss encounter guarantees with escorts and treasure
- Treasure room logic in vault carving (+2/+4 quality bonus)

### Stream F: Special Levels + Transitions (dungeon_generator.gd)
- Sauron's Throne Room (depth 20): vault type 9 centered in grid
- Gates of Dol Guldur (escape): vault type 10 on ascent from depth 1
- Transition vaults at layer boundaries (depths 3,6,9,12,15,18): 50% force-place N:200-205
- Corridor variety: L-shaped, winding (20% at depth 5+), wide (deeper levels)

### Critical Rules
- Use `"property" in item` not `item.has("property")` for DataManager dicts
- Always `is_instance_valid()` before `is` operator on freed objects
- ALWAYS `.duplicate(true)` for nested arrays
- Explicitly type variables (GDScript type inference causes crashes)
- For macOS symbol keys, use event.keycode/event.unicode fallback
- Run tests after each stream: godot --path . --headless --script res://test_runner.gd

### Dependencies
Streams A + D start immediately (no dependencies). B and E can start LayerConfig work immediately. C depends on A+B. F depends on C. Use 6 parallel sub-agents, each with self-recursive test loops.

Throw maximum compute at this. Use subagents aggressively. Each stream should test independently and fix its own crashes before completing.
```

---

## Quick Start

```bash
cd ~/dev/active/games/necromancer-godot
# Paste the prompt above into Claude Code
```
