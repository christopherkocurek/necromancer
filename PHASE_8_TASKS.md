# Phase 8 Atomic Task Breakdown

**Status**: IN PROGRESS
**Created**: 2026-02-05
**Updated**: 2026-02-05 (Agent 4 integration complete)
**Goal**: Complete playable prototype with all core systems

---

## 8B.1: Lore Ability System

### Framework
- [x] 8B.1.0: Create `scripts/systems/ability_system.gd` with activation framework
  - Ability activation via hotkey or ability panel
  - Cooldown tracking
  - Voice charge consumption
  - Signal emissions for UI updates
  - Integration with player.gd ability arrays

### Individual Abilities (14 total, 2 deferred)

| Task ID | Ability | ID | Effect | Status |
|---------|---------|-----|--------|--------|
| 8B.1.1 | Word of Command | 140 | AOE fear/stun servants of enemy in radius | TODO |
| 8B.1.2 | Lore of Battle | 141 | Provoke target: -evasion, +damage for X turns | TODO |
| 8B.1.3 | Deep Memory | 142 | Reveal dungeon layout | **DEFERRED** |
| 8B.1.4 | Word of Opening | 143 | Unlock doors, reveal traps in radius | TODO |
| 8B.1.5 | Lore of Silence | 144 | Reduce monster perception in radius | TODO |
| 8B.1.6 | Herbcraft | 145 | Double healing from herbs/potions | TODO |
| 8B.1.7 | Word of Shutting | 146 | Lock/seal doors permanently | TODO |
| 8B.1.8 | Inner Light | 147 | +1 light radius per 5 Lore | **DEFERRED** |
| 8B.1.9 | Deadly Lore | 148 | Instant kill if target HP ≤ 2×Lore skill | TODO |
| 8B.1.10 | Lore of Endurance | 149 | +Will/2, +2d2 protection for duration | TODO |
| 8B.1.11 | Lore of Sleep | 150 | Put target to sleep (Will check) | TODO |
| 8B.1.12 | Word of Mastery | 151 | Paralyze target (prevent movement/action) | TODO |
| 8B.1.13 | Device Mastery | 152 | +50% wand/staff charges when using | TODO |
| 8B.1.14 | Grace | 153 | Passive +1 Grace stat | TODO |

---

## 8B.2: Dungeon Layers (7 Tiers)

### Framework
- [x] 8B.2.0: Create `scripts/systems/layer_config.gd` with LAYER_CONFIGS dictionary
- [x] 8B.2.1: Create `shaders/layer_tint.gdshader` for color tinting
- [x] 8B.2.2: Implement `get_layer_for_depth(depth: int) -> Dictionary`
- [x] 8B.2.3: Wire tint shader to TileMap on layer transitions

### Per-Layer Implementation

| Task ID | Layer | Depth | Tint | Room Style | Monsters | Status |
|---------|-------|-------|------|------------|----------|--------|
| 8B.2.4 | Outer Pits | 1-3 | None (base) | Standard stone | Spiders, rats, tanglethorns | DONE |
| 8B.2.5 | Lower Halls | 4-6 | Green (+0.15) | Larger rooms | Orcs, wargs, soldiers | DONE |
| 8B.2.6 | Dark Halls | 7-9 | Blue (+0.2) | Narrow corridors | Trolls, orc captains | DONE |
| 8B.2.7 | Necropolis | 10-12 | Purple (+0.25) | Wide corridors | Undead, wraiths | DONE |
| 8B.2.8 | Pits of Despair | 13-15 | Red/Orange (+0.3) | Wide corridors | Fire creatures | DONE |
| 8B.2.9 | Inner Sanctum | 16-18 | Black + Gold (+0.35) | Wide corridors, large rooms | Elite guards | DONE |
| 8B.2.10 | Throne Room | 19-20 | Dark + Bright Gold (+0.4) | Boss arena style | Sauron, lieutenants | DONE |

### Layer Systems
- [ ] 8B.2.11: Implement monster spawn tables per layer (filter by W: depth) - DataManager already filters by depth
- [x] 8B.2.12: Implement FOV radius changes per layer (base 8, Inner 6, Throne 5)
- [x] 8B.2.13: Add ambient messages on layer entry (message_log flavor)
- [x] 8B.2.14: Implement layer-specific generation params (room size, corridor style)
- [ ] 8B.2.15: Add layer transition sound/visual cue (DEFERRED - no audio system yet)

---

## 8B.3: Quest Items

- [x] 8B.3.1: Add Ring of Thráin to `data/artefact.txt` or `data/object.txt`
  - Quest flag, cannot be dropped
  - Triggers victory check when ascending from depth 1
  - **Implemented**: Created in quest_system.gd as static factory method
- [x] 8B.3.2: Add Key to Erebor to data files
  - Quest flag, cannot be dropped
  - Required with Ring for Escape Victory
  - **Implemented**: Created in quest_system.gd as static factory method
- [x] 8B.3.3: Add Rod of Istari (3 pieces) to data files
  - Assembly mechanic (combine when all 3 in inventory)
  - Required for Banishment Victory
  - **Implemented**: Created in quest_system.gd with auto-assembly logic
- [x] 8B.3.4: Implement quest item pickup logic (special handling, messages)
  - **Implemented**: QuestSystem connects to EventBus.item_picked_up
- [x] 8B.3.5: Create `scripts/systems/quest_system.gd` for quest state tracking
  - **Implemented**: Full quest state machine with serialization

---

## 8B.4: Victory Conditions

### Framework
- [x] 8B.4.0: Create `scripts/systems/victory_system.gd` with victory state machine
  - **Implemented**: Victory logic integrated into quest_system.gd
- [x] 8B.4.1: Create `scenes/ui/victory_screen.tscn` with run statistics display
  - **Implemented**: Full victory screen with score calculation

### Escape Victory
- [x] 8B.4.2: Detect player has Ring of Thráin + Key to Erebor
  - **Implemented**: can_escape() in quest_system.gd
- [x] 8B.4.3: Check ascending stairs at depth 1
  - **Implemented**: attempt_escape() checks depth
- [x] 8B.4.4: Trigger Escape Victory screen with stats
  - **Implemented**: victory_screen.gd show_victory()
- [x] 8B.4.5: Write to run history / high scores
  - **Implemented**: RunStats tracking integrated

### Banishment Victory
- [x] 8B.4.6: Detect Rod of Istari assembled
  - **Implemented**: _assemble_rod() in quest_system.gd
- [x] 8B.4.7: Check Lore skill ≥ 12 AND Will skill ≥ 10
  - **Implemented**: can_banish() skill checks
- [x] 8B.4.8: Implement Sauron encounter (depths 19-20)
  - **Implemented**: Throne room tracking in quest_system.gd
- [x] 8B.4.9: Implement Will check for banishment (opposed roll vs Sauron)
  - **Implemented**: attempt_banishment() with d20+Will+Lore/2 vs 25
- [x] 8B.4.10: Trigger Banishment Victory screen with alternate stats
  - **Implemented**: victory_screen.gd with victory_type
- [x] 8B.4.11: Write to run history / high scores
  - **Implemented**: RunStats with victory type tracking

---

## 8B.5: Thráin II NPC Encounter

- [x] 8B.5.1: Create `scripts/entities/npc.gd` base class (non-hostile entity)
  - **Implemented**: Full NPC base class with dialogue tree support
- [x] 8B.5.2: Create Thráin II NPC definition
  - Spawns at depth 15+ (specific location or vault)
  - UNIQUE flag, cannot be killed
  - **Implemented**: scripts/entities/thrain_npc.gd
- [x] 8B.5.3: Implement dialogue system (simple text display)
  - **Implemented**: scripts/ui/dialogue_panel.gd + scenes/ui/dialogue_panel.tscn
- [x] 8B.5.4: Create Thráin II dialogue tree
  - Introduction
  - Quest explanation
  - Ring + Key handoff
  - Farewell / escape instructions
  - **Implemented**: 6-node dialogue tree in thrain_npc.gd
- [x] 8B.5.5: Wire Thráin II to quest_system.gd (advance quest state)
  - **Implemented**: quest_system callbacks for thrain_found, ring_acquired, key_acquired
- [x] 8B.5.6: Add Thráin sprite to tile_mapper.gd (use DCSS dwarf/NPC tile)
  - **Implemented**: Uses Thorin Oakenshield sprite (index 305) or dwarf fallback

---

## 8C.1: Smithing System

- [x] 8C.1.1: Verify forge terrain type exists and spawns (every 4th level per generator)
  - **Implemented**: Forge terrain IDs 64-79 in smithing_system.gd
- [x] 8C.1.2: Create `scripts/systems/smithing_system.gd`
  - **Implemented**: Full smithing system with recipes and skill integration
- [x] 8C.1.3: Create `scenes/ui/smithing_panel.tscn`
  - **Implemented**: Full UI with recipe/item/material selection
- [x] 8C.1.4: Implement smithing recipes
  - Weapon enhancement (+damage dice)
  - Armor enhancement (+protection dice)
  - Item repair (if durability exists)
  - **Implemented**: 3 recipe types
- [x] 8C.1.5: Implement material requirements (ore items from data)
  - **Implemented**: TVAL_METAL and TVAL_SALVAGE constants
- [x] 8C.1.6: Wire forge interaction ('>' or 'e' when on forge tile)
  - **Implemented**: smithing_panel.gd integrated in main.gd
- [x] 8C.1.7: Integrate with player Smithing skill (success chance = skill×5%)
  - **Implemented**: get_success_chance() in smithing_system.gd

---

## 8C.2: Auto-Explore

- [x] 8C.2.1: Create `scripts/systems/auto_explore.gd`
  - **Implemented**: Full auto-exploration system
- [x] 8C.2.2: Implement BFS/flood-fill to nearest unexplored tile
  - **Implemented**: _bfs_find_unexplored() and A* pathfinding
- [x] 8C.2.3: Implement movement queue (one step per turn)
  - **Implemented**: path array with get_next_step()
- [x] 8C.2.4: Implement stop conditions:
  - Enemy enters FOV
  - Item visible
  - Player takes damage
  - Player reaches stairs
  - Trap triggered
  - Manual input received
  - **Implemented**: _check_stop_conditions() with all cases
- [x] 8C.2.5: Add keybind for auto-explore ('o' is traditional)
  - **Implemented**: Integrated in main.gd
- [x] 8C.2.6: Add status message during auto-explore ("Exploring...")
  - **Implemented**: GameManager.log_message on start/stop

---

## 8C.3: Monster Memory / Lore Discovery

- [x] 8C.3.1: Create `scripts/systems/monster_memory.gd`
  - **Implemented**: Full monster memory system
- [x] 8C.3.2: Implement seen_monsters dictionary (monster_id -> observation count)
  - **Implemented**: seen_monsters dict with monster_names cache
- [x] 8C.3.3: Implement info reveal tiers:
  - 0 observations: "Unknown creature"
  - 1 observation: Name only
  - 3 observations: HP, basic attacks
  - 5 observations: All attacks, resistances
  - 10 observations: Full stats, flags
  - **Implemented**: KnowledgeTier enum with TIER_THRESHOLDS
- [x] 8C.3.4: Integrate with Look mode ('x' key) - show known info only
  - **Implemented**: look_panel.gd uses monster_memory.format_monster_info_for_look()
- [x] 8C.3.5: Persist monster memory in save file
  - **Implemented**: to_dict() and from_dict() serialization
- [x] 8C.3.6: Add Lore skill bonus (+skill/2 observation levels)
  - **Implemented**: player_lore parameter in format_monster_info_for_look()

---

## Documentation Tasks

- [ ] DOC.1: Create `docs/PROTOTYPE_DEFERRED.md` with deferred items
- [x] DOC.2: Create `docs/BUG_TRIAGE.md` for bug tracking
  - **Implemented**: Basic structure with known issues
- [ ] DOC.3: Update TODO.md with Phase 8 status
- [ ] DOC.4: Update MEMORY.md on Phase 8 completion

---

## Integration Checkpoints

| Checkpoint | Trigger | Validation |
|------------|---------|------------|
| CP1 | 8B.1 complete | All Lore abilities work, don't break combat |
| CP2 | 8B.2 complete | Navigate depths 1-20-1, tints/spawns/FOV work |
| CP3 | 8B.3-8B.5 complete | Full Escape Victory playthrough |
| CP4 | 8B.4 Banishment | Full Banishment Victory playthrough |
| CP5 | 8C complete | Smithing, auto-explore, monster memory all functional |
| FINAL | All complete | Both victory paths, no crashes, deferred documented |

---

## Task Counts

| Section | Total | DONE | TODO | Deferred |
|---------|-------|------|------|----------|
| 8B.1 Lore | 15 | 1 | 12 | 2 |
| 8B.2 Layers | 16 | 11 | 3 | 2 |
| 8B.3 Quest Items | 5 | 5 | 0 | 0 |
| 8B.4 Victory | 12 | 12 | 0 | 0 |
| 8B.5 Thráin II | 6 | 6 | 0 | 0 |
| 8C.1 Smithing | 7 | 7 | 0 | 0 |
| 8C.2 Auto-Explore | 6 | 6 | 0 | 0 |
| 8C.3 Monster Memory | 6 | 6 | 0 | 0 |
| Documentation | 4 | 1 | 3 | 0 |
| **TOTAL** | **77** | **55** | **18** | **4** |

**Note**: Core systems (8B.3-8C.3) are complete. Remaining TODO items are primarily individual Lore abilities (8B.1) and documentation tasks.
