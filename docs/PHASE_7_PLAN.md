# Phase 7: Gameplay Polish & Core Systems

**Status**: Planning
**Prerequisites**: Phase 5-6 complete (UI, combat, XP systems working)

---

## Overview

Phase 7 focuses on making the game feel complete and polished. The core loop (explore → fight → loot → level up) exists but needs supporting systems for a proper roguelike experience.

---

## 7A: Death & Game Over System

**Priority**: HIGH (currently no death handling)

### Tasks
1. **Death detection** - Trigger game over when player HP <= 0
2. **Death screen UI** - Show character epitaph/summary
3. **"Your Tale" generation** - Procedural death summary (Sil-Q style)
4. **Restart option** - Return to character creation
5. **High scores** - Track best runs (depth reached, XP earned, cause of death)

### Files to modify
- `scripts/entities/player.gd` - Death signal
- `scripts/main.gd` - GameState.GAME_OVER handling
- NEW: `scripts/ui/death_screen.gd`
- NEW: `scenes/ui/death_screen.tscn`

---

## 7B: Targeting System

**Priority**: HIGH (needed for ranged combat & abilities)

### Tasks
1. **Look mode** (`x` key) - Examine tiles/entities
2. **Target cursor** - Visual indicator for selection
3. **Target cycling** - Tab through visible enemies
4. **Line of sight** - Validate target is visible
5. **Ranged attack integration** - Archery skill usage
6. **Ability targeting** - For offensive lore abilities

### Files to modify
- `scripts/entities/player.gd` - Targeting state machine
- `scripts/levels/level.gd` - LOS queries
- NEW: `scripts/ui/target_cursor.gd`

---

## 7C: Status Effects System

**Priority**: MEDIUM (adds combat depth)

### Tasks
1. **Effect data structure** - Duration, stacking, tick behavior
2. **Common effects**: Poison, Bleed, Stun, Slow, Blind, Confused, Fear
3. **Effect application** - From monster attacks, abilities, items
4. **Effect display** - Icons in HUD, messages on apply/expire
5. **Effect processing** - Per-turn tick damage/recovery

### Files to modify
- `scripts/entities/entity.gd` - Effect tracking
- `scripts/ui/hud.gd` - Effect icons
- NEW: `scripts/systems/status_effects.gd`

---

## 7D: Save/Load System

**Priority**: MEDIUM (essential for longer play sessions)

### Tasks
1. **Save game state** - Player, level, turn count, RNG seed
2. **Save file format** - JSON or binary
3. **Load game** - Restore full state
4. **Permadeath handling** - Delete save on death (optional toggle)
5. **Save slot UI** - Main menu integration

### Files to modify
- NEW: `scripts/systems/save_system.gd`
- `scripts/main.gd` - Save/load triggers
- `scripts/core/game_manager.gd` - State serialization

---

## 7E: Monster AI Improvements

**Priority**: MEDIUM (makes combat more interesting)

### Tasks
1. **Fleeing behavior** - Low HP monsters retreat
2. **Pack tactics** - Grouped enemies coordinate
3. **Ranged AI** - Archers maintain distance
4. **Spell-casting AI** - Magic users use abilities
5. **Alert states** - Sleeping → Alert → Hunting
6. **Pathfinding improvements** - A* with terrain costs

### Files to modify
- `scripts/entities/monster.gd` - AI state machine
- `scripts/systems/pathfinding.gd` - Enhanced A*

---

## 7F: Smithing System

**Priority**: LOW (nice-to-have, requires forge terrain)

### Tasks
1. **Forge terrain** - Special interaction tile
2. **Smithing UI** - Item improvement interface
3. **Upgrade mechanics** - Improve weapons/armor
4. **Material requirements** - Crafting resources
5. **Skill gating** - Smithing skill determines options

---

## 7G: Quality of Life

**Priority**: MIXED

### Tasks
1. **Auto-explore** (`o` key) - Move until something interesting
2. **Run mode** (Shift+direction) - Move until blocked/enemy
3. **Message log scroll** - Review past messages
4. **Minimap** - Corner overview of explored area
5. **Help screen** (`?` key) - In-game controls reference
6. **Mouse support** - Click to move/interact (optional)

---

## Recommended Implementation Order

1. **7A: Death & Game Over** - Critical for playable game loop
2. **7B: Targeting System** - Enables ranged combat & abilities
3. **7G: QoL (partial)** - Auto-explore, message log, help screen
4. **7C: Status Effects** - Combat depth
5. **7D: Save/Load** - Session persistence
6. **7E: Monster AI** - Combat variety
7. **7F: Smithing** - Optional depth

---

## Stretch Goals (Phase 8+)

- Sound effects & ambient audio
- Particle effects for magic/combat
- Achievement system
- Tutorial/hint system
- Steam integration
- Modding support

---

## Notes from User Feedback

1. **Abilities UI** - Consider Skyrim constellation-style or Tolkien scroll-based presentation instead of plain list
2. **Ability XP costs** - Current formula `(level+1)*300` needs balancing against Sil-Q data
3. **Equipment layout** - Fixed in Phase 6, now uses 3-column grid

---

## Success Criteria

Phase 7 is complete when:
- [ ] Player can die and see a death summary screen
- [ ] Player can target enemies for ranged attacks
- [ ] At least 3 status effects are functional
- [ ] Game can be saved and loaded
- [ ] Monsters have varied AI behaviors
- [ ] Auto-explore and run mode work
