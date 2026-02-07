# Necromancer Session K: Bug Fix & Improvement Mega-Pass

## Context

After extensive playtesting of the Session J procedural map overhaul, 24 bugs and improvements were identified across tile art, game systems, UI/UX, and game design. This plan organizes them into 6 parallel agent streams for maximum throughput.

---

## Team Architecture

| Stream | Agent Type | Focus | Est. Items |
|--------|-----------|-------|------------|
| **A** | Tile Artist | Sprite recoloring (no DALL-E) | 7 recolors |
| **B** | Tile Generator | DALL-E sprite generation + integration | 7 new sprites |
| **C** | Combat Engineer | Turn system, ranged AI, diagonal movement | 4 bugs |
| **D** | Inventory/Items | Stacking, dropping, consumables, herb balance | 4 bugs |
| **E** | Game Designer | Word of Command, Deep Memory, procedural descriptions | 3 systems |
| **F** | UI/UX Developer | Peril tiers, voice hotbar, orb artwork | 3 improvements |

---

## Stream A: Sprite Recoloring (No DALL-E, No API Cost)

**Script**: New `tileset_generation/batch_recolor.py` — imports HSV correction + BG removal functions from existing `fix_item_magenta.py`

### A1. Scrolls (15 sprites: IDs 191-211)
- **Problem**: Magenta bleed on parchment surfaces
- **Fix**: Re-run HSV correction with `hue_deg=38, bleed=2` (was `hue_deg=40, bleed=1`)
- **Coords**: `(25,13)` through `(8,14)` — patch in-place

### A2. Documents (14 sprites: IDs 451, 500-556)
- **Problem**: Same parchment bleed as scrolls
- **Fix**: `hue_deg=38, bleed=2`
- **Coords**: `(14,16)` through `(0,17)` — patch in-place

### A3. Torches (5 sprites: IDs 128-131, 411)
- **Problem**: Magenta bleed on warm glow areas
- **Fix**: `hue_deg=35, bleed=2` (amber/flame target)
- **Coords**: `(31,12)`, `(0-2,13)`, `(3,16)` — patch in-place

### A4. Sylvan Blade (ID 59)
- **Problem**: Color retouch needed + NOT in tile_mapper
- **Fix**: Re-run raw with `hue_deg=120` (green-tinged blade), place at `Vector2i(2,17)`
- **tile_mapper.gd**: Add `item_coords[59] = Vector2i(2, 17)`

### A5. Web Spinner (Monster ID 17)
- **Problem**: Corpus needs darker gray
- **Fix**: `achromatic=true, bleed=2` + post-BG brightness multiplier 0.7x
- **Coord**: `(6,24)` — patch in-place

### A6. Orc Slave (Monster ID 31)
- **Problem**: Magenta contamination on skin
- **Fix**: `hue_deg=80, bleed=2` — escalate to DALL-E regen if insufficient
- **Coord**: `(12,24)` — patch in-place

### A7. Buckler (Item ID 43)
- **Problem**: Interior hollowed by aggressive BG removal
- **Fix**: Conservative BG removal (pass 1 only, skip passes 2-3)
- **Coord**: `(20,11)` — patch in-place

**Files**:
- NEW: `tileset_generation/batch_recolor.py`
- MODIFY: `assets/sprites/necromancer_dcss_tileset.png` (patched)
- MODIFY: `scripts/core/tile_mapper.gd` (add ID 59)

---

## Stream B: DALL-E Sprite Generation (~$0.32, 8 API calls)

### B1. Curved Sword (Item ID 58) — NEW SPRITE
- No raw exists. Generate with magenta BG prompt.
- Place at `Vector2i(1, 17)`, add `item_coords[58]` to tile_mapper.gd

### B2. Vine Floor Terrain — REGENERATE
- Current tile at `(12,5)/(13,5)` is too subtle. Generate new "stone floor with thick green vines" overhead view.
- Place at `Vector2i(16,18)` light / `Vector2i(17,18)` dark
- Update terrain_coords override for Level.Tile 17

### B3. Web Terrain (Level.Tile 19) — NEW SPRITE
- Currently empty placeholder at `(0,18)/(1,18)`. Generate "dense white spider webs over dark stone."
- Patch in-place at `(0,18)/(1,18)`

### B4. Stairs Down — REGENERATE
- Current tile at `(2,5)/(3,5)` is unclear. Generate "stone stairway opening descending into darkness" overhead view.
- Place at `Vector2i(18,18)` / `Vector2i(19,18)`, update terrain_coords for Level.Tile 5

### B5. Poison Stream Terrain — NEW SPRITE
- Currently reuses water tile. Generate "sickly green stream flowing across dark stone floor" overhead view.
- Place at `Vector2i(20,18)` / `Vector2i(21,18)`, update terrain_coords for Level.Tile 18

### B6. Wanderer's Robe (Item ID 22) — REGENERATE
- Too much BG residue. Full DALL-E regen with magenta BG + `hue_deg=25, bleed=1`.
- Patch in-place at `(10,11)`

### B7. HP/Voice Orb Frames — NEW UI ARTWORK
- Generate wrought iron watcher frame (Dol Guldur/Cirith Ungol style) on dark BG
- Post-process: make center circle + corners transparent, resize to 100x100
- Save as `assets/ui/orbs/orb_frame_watcher.png`, update hud.gd to use it

**Files**:
- NEW: `tileset_generation/regen_sprites.py`
- MODIFY: `assets/sprites/necromancer_dcss_tileset.png`
- MODIFY: `scripts/core/tile_mapper.gd` (IDs 58, terrain overrides)
- NEW: `assets/ui/orbs/orb_frame_watcher.png`
- MODIFY: `scripts/ui/hud.gd` (orb frame texture swap)

---

## Stream C: Combat & Movement Bugs

### C1. Turn System — CRITICAL (Monster 5:1 ratio)
**Root cause**: `_process_game_tick()` (turn_system.gd:166-169) has a synchronous loop that processes ALL monster turns immediately, with no animation delay and no visibility check. The state machine's `_process_monster_turn()` (line 206) likely never fires because monsters already consumed their energy. Additionally, `_end_round()` (line 230) has **duplicate** round increment (line 231 vs 175) and **duplicate** energy grants (lines 235-246 vs 157-163).

**Fix**: Remove the synchronous monster processing loop (lines 166-169) from `_process_game_tick()`. Let the state machine handle monsters through `_process_monster_turn()` which has proper animation delays and visibility checks. Also remove the duplicate round/tick processing — consolidate all ticks into `_end_round()` only.

**Specifically in `_process_game_tick()` (starting line 150)**:
- KEEP lines 157-163 (grant energy to player + monsters)
- REMOVE lines 166-169 (sync monster turn loop)
- REMOVE line 172 (entity visibility refresh after sync loop)
- REMOVE line 175 (round counter — let `_end_round()` handle)
- REMOVE lines 178-204 (status ticks, hunger, regen — move to `_end_round()`)

**In `_end_round()` (line 230)**:
- REMOVE lines 234-248 (duplicate energy grants — already in `_process_game_tick()`)
- KEEP round increment at line 231
- ADD status ticks, hunger, regen here (moved from `_process_game_tick()`)

**File**: `scripts/systems/turn_system.gd`

### C2. Orc Crossbow Not Shooting
**Root cause**: S: line parser (data_manager.gd:145-158) fails on `"SPELL_PCT_40"` — `int("SPELL_PCT_40")` = 0 in GDScript. Crossbowmen get `spell_frequency=0`. Also, `_get_available_spells()` in monster.gd only checks `flags`, not `spell_types`.

**Fix data_manager.gd S: parser (line 145)**:
- Parse `SPELL_PCT_N` → extract N as spell_frequency
- Parse `POW_N` → extract N as spell_power
- Remaining tokens = spell type names (CROSSBOW, SHRIEK, etc.)

**Fix monster.gd `_get_available_spells()` (line 918)**:
- Check `spell_types` array (primary) in addition to flags (legacy)
- Map `"CROSSBOW"` → `"ARROW1"` for compatibility

**Fix monster.gd `_try_cast_spell()` (line 878)**:
- Use `monster_data.spell_frequency / 100.0` instead of hardcoded `0.33`

**Files**: `scripts/core/data_manager.gd`, `scripts/entities/monster.gd`

### C3. Diagonal Movement/Attacks
**Status**: Input bindings exist in project.godot (YUBN + Numpad). `_get_movement_input()` in player.gd checks all 8 directions. Need to verify these actually work on macOS — likely a physical_keycode issue.

**Fix**: Add keycode fallback in main.gd's `_unhandled_input()` for YUBN keys (same pattern as `;` key fix). If `Input.is_action_just_pressed("move_up_left")` doesn't fire, raw `event.keycode == KEY_Y` catches it.

**Files**: `scripts/main.gd`, `scripts/entities/player.gd`

---

## Stream D: Inventory & Item Bugs

### D1. Consumable Stack Bug — CRITICAL
**Root cause**: `_use_first_consumable()` (player.gd:2036-2037) does `inventory.remove_at(i)` on use — removes the **entire stack** instead of decrementing `stack_count`.

**Fix**:
```
if ConsumableSystem.use_item(self, item):
    var count: int = item.stack_count if "stack_count" in item else 1
    if count > 1:
        item.stack_count = count - 1
    else:
        inventory.remove_at(i)
    return true
```

**File**: `scripts/entities/player.gd` line 2036

### D2. Item Dropping Not Working
**Status**: Drop plumbing exists (inventory_panel.gd:586-603 → player.drop_item() → EventBus.item_dropped → main.gd handler). Confirm dialog flow looks correct.

**Investigation**: Add fallback Shift+D keycode check in inventory_panel's `_input()` (macOS compatibility). Verify `selected_item` is not null when drop is triggered. Add debug logging.

**File**: `scripts/ui/inventory_panel.gd`

### D3. Herb Spawn Rate Too High
**Root cause**: Dedicated food spawner at dungeon_generator.gd lines 1210-1231 spawns 2-3 extra food/herbs at shallow depths. Pool is dominated by herbs (~88%) since there are 26 herb svals vs 4 food svals.

**Fix**: Split food/herb spawning into separate pools. Cap herbs at 1-2 per floor (shallow) down to 0-1 (deep). Add `get_random_actual_food()` and `get_random_herb_for_depth()` to data_manager.gd.

**Files**: `scripts/systems/dungeon_generator.gd`, `scripts/core/data_manager.gd`

### D4. Curved Sword Tile Mapping
**Root cause**: IDs 58 and 59 missing from tile_mapper.gd item_coords.

**Quick fix**: Add placeholder mappings to existing sword sprites. Proper fix after Stream B generates DALL-E sprites.

**File**: `scripts/core/tile_mapper.gd`

---

## Stream E: Game Design & Systems

### E1. Word of Command Rework
**Problem**: Per-turn will saves in status_effects.gd strip fear too fast. User gets ~2 turns instead of 5.
**Design goal**: Primary escape tool for lore builds early, scales but doesn't break late.

**Fix (ability_system.gd `_word_of_command()`)**:
- Add guaranteed no-resist period: `no_resist_turns = 3 + lore_skill / 4`
  - Lore 0 → 3 turns | Lore 8 → 5 | Lore 16 → 7
- Store `monster.set_meta("word_of_command_no_resist", no_resist_turns)`
- Increase save DC: `10 + lore_skill` (was `10 + lore_skill / 2`)
- Stun duration: `lore_skill / 3` (was `lore_skill / 4`)

**Fix (status_effects.gd will save block)**:
- Before will save roll, check `word_of_command_no_resist` meta
- If > 0, decrement and skip save
- When reaches 0, normal saves resume

**Files**: `scripts/systems/ability_system.gd`, `scripts/systems/status_effects.gd`

### E2. Deep Memory Fix
**Current**: Active effect = map reveal (works). Passive effect = bonus observations on first sighting (partially implemented in main.gd but no feedback).

**Fix**:
- In main.gd `_observe_visible_monsters()`: ensure bonus observation code fires and add log message "Deep Memory: You recall lore about the [name]."
- Bonus: `maxi(1, lore_skill / 3)` observations on first sighting
- At Lore 6: 2 bonus obs = IDENTIFIED immediately
- At Lore 12: 4 bonus obs = BASIC tier on sight

**File**: `scripts/main.gd`

### E3. Procedural Descriptions (DF-style)
**Problem**: X inspect shows "Unknown creature" at tier 0 — useless.

**Fix**: New `scripts/systems/description_generator.gd` with static methods:
- `generate_monster_description(monster_data, tier)` — templates per display_char type (o=orc, S=spider, T=troll, etc.) using HP for size, color code for coloring, flags for behavior hints
- `generate_item_description(item_data)` — from tval/weight/bonus
- `generate_terrain_description(tile)` — atmospheric per tile type

**Integration**:
- monster_memory.gd `format_monster_info_for_look()`: at UNKNOWN tier, show procedural physical description. At IDENTIFIED tier, add behavioral hints. At COMPLETE, use actual D: description.
- look_panel.gd: add terrain descriptions

**Files**: NEW `scripts/systems/description_generator.gd`, `scripts/systems/monster_memory.gd`, `scripts/ui/look_panel.gd`

---

## Stream F: UI/UX Improvements

### F1. Sauron Peril Warning — Tiered by Depth
**Current**: Single "SAURON SENSES YOUR PERIL" at <10% HP.

**Fix (hud.gd `_show_peril_warning()`)**:
- Read `GameManager.current_depth`
- Depth 1-6: "A malevolent presence watches from below..." (gray, 28pt)
- Depth 7-12: "A dark power stirs in the deep..." (purple, 30pt)
- Depth 13-15: "The Necromancer senses your weakness..." (orange, 32pt)
- Depth 16-18: "SAURON SENSES YOUR PERIL!" (red, 36pt)
- Depth 19-20: "THE DARK LORD'S GAZE FALLS UPON YOU!" (pulsing gold, 40pt)
- Flash intensity scales with depth

**File**: `scripts/ui/hud.gd`

### F2. Voice Ability Hotkey Bar
**Problem**: V → popup → select → target is too many steps for combat magic.

**Fix**:
- Add 4 ability quick-slots between HP orb and center stats in HUD
- Each slot: ability abbreviation + voice cost + cooldown overlay
- Number keys 1-4 activate directly (or open targeting if needed)
- V key still opens full menu
- Add `ability_hotkeys: Array[int]` to player.gd (persist in save)
- Assignment: hold Shift+1-4 in voice menu to bind

**Files**: `scripts/ui/hud.gd`, `scripts/main.gd`, `scripts/entities/player.gd`, `scripts/systems/save_manager.gd`

### F3. Orb Watcher Artwork
(Handled by Stream B7 — DALL-E generation + integration into hud.gd)

---

## Execution Order & Dependencies

```
Phase 1 (parallel, no deps):
  Stream A (recolor)   — immediate, no API cost
  Stream C1 (turn sys) — highest impact bug
  Stream D1 (stacking) — highest impact inventory bug
  Stream E1 (WoC)      — game design, independent

Phase 2 (parallel, after Phase 1):
  Stream B (DALL-E)    — needs API key, ~$0.32
  Stream C2 (crossbow) — benefits from C1 turn fix
  Stream D2-D4         — remaining inventory issues
  Stream E2-E3         — Deep Memory + descriptions

Phase 3 (parallel, after Phase 2):
  Stream F1-F2         — UI/UX polish
  Integration testing  — all streams verified together
```

---

## Verification Plan

1. **Turn system**: Stand next to Speed 2 monster → should trade blows ~1:1. Speed 3 monster should sometimes get 2 turns.
2. **Crossbow**: Orc Crossbowman at distance 3-5 with LOS → should fire ~40% of turns.
3. **Stacking**: Eat 1 of 3 lembas → should show "Lembas (x2)" not empty.
4. **Dropping**: Select item in inventory → Shift+D → confirm → item appears on floor.
5. **Word of Command**: Cast at Lore 0 → monster fears for 3+ turns before first resist check.
6. **Diagonal**: Press Y/U/B/N → player moves diagonally, attacks diagonal enemies.
7. **Sprites**: Visual inspection of recolored/regenerated tiles in game.
8. **Run full test suite**: `godot --path . --headless --script res://test_runner.gd`

---

## Critical Files Summary

| File | Streams | Changes |
|------|---------|---------|
| `scripts/systems/turn_system.gd` | C1 | Remove sync loop, consolidate ticks |
| `scripts/entities/player.gd` | D1, F2 | Fix _use_first_consumable, add ability_hotkeys |
| `scripts/entities/monster.gd` | C2 | Fix _get_available_spells, use spell_frequency |
| `scripts/core/data_manager.gd` | C2, D3 | Fix S: parser, add food/herb helpers |
| `scripts/core/tile_mapper.gd` | A4, B1-B5, D4 | Add coords for IDs 58/59, update terrain |
| `scripts/systems/ability_system.gd` | E1 | WoC no-resist period |
| `scripts/systems/status_effects.gd` | E1 | WoC no-resist countdown check |
| `scripts/ui/hud.gd` | F1, F2, B7 | Peril tiers, hotbar, orb frame |
| `scripts/main.gd` | C3, E2, F2 | Diagonal fallback, Deep Memory log, hotkey input |
| `scripts/systems/monster_memory.gd` | E3 | Procedural description integration |
| `scripts/ui/look_panel.gd` | E3 | Terrain descriptions |
| `scripts/ui/inventory_panel.gd` | D2 | Drop input fallback |
| NEW `scripts/systems/description_generator.gd` | E3 | DF-style procedural descriptions |
| NEW `tileset_generation/batch_recolor.py` | A | Batch HSV recolor script |
| NEW `tileset_generation/regen_sprites.py` | B | DALL-E generation + integration |
| `assets/sprites/necromancer_dcss_tileset.png` | A, B | Patched tileset |
