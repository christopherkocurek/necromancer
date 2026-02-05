# Necromancer Godot: Phase 5 Final Implementation Plan

## Vision
Transform the prototype into a playable roguelike with complete item management, character customization, and progression systems using authentic Sil-Q mechanics.

## Critical Decision: Combat System
**RULING: Implement Sil-Q opposed rolls, NOT d20.**
- Attacker: `1d(melee_score + attack_bonus)`
- Defender: `1d(evasion_score + evasion_bonus)`
- Margin determines hit quality and critical potential
- Protection: `damage - roll(protection_dice)`

---

## BLOCKERS (Must complete FIRST)

| ID | Issue | Resolution |
|----|-------|------------|
| B1 | XP/Leveling fundamentally wrong | REWRITE: Sil-Q has NO levels. XP is currency for skills/abilities |
| B2 | Item P: line parsing wrong | FIX: Correctly parse attack, damage, evasion, protection |
| B3 | Combat uses d20 | REWRITE: Implement opposed roll system |
| B4 | _recalculate_stats() ignores equipment | REWRITE: Stats = base + race + equipment + abilities |
| B5 | Race parsing missing C:/E:/F: lines | ADD: House compatibility, starting equipment, racial flags |
| B6 | House parsing missing fields | ADD: All house data fields |

---

## Phase 5A: Character Creation

### Data Layer
- [ ] Complete race.txt parsing (C:/E:/F: lines)
- [ ] Complete house.txt parsing (all fields)
- [ ] Create CharacterBuild Resource class
- [ ] Racial proficiency bonuses (BOW_PROFICIENCY, etc.)
- [ ] Verify stat allocation formula from Sil-Q

### UI Layer
- [ ] Separate CharacterCreation.tscn scene
- [ ] Race selection with real-time stat preview
- [ ] House selection (filtered by race compatibility)
- [ ] Stat allocation interface with point costs
- [ ] Name entry with LineEdit
- [ ] Full keyboard navigation (Tab, Enter, Escape)

### Signals
- [ ] GameState.CHARACTER_CREATION
- [ ] EventBus: race_selected, house_selected, creation_confirmed

---

## Phase 5B: Inventory & Equipment

### Data Layer
- [ ] tval-to-slot mapping dictionary
- [ ] ItemData.get_valid_slots() method
- [ ] TWO_HANDED flag detection
- [ ] Add QUIVER slot for arrows
- [ ] player.inventory: Array[ItemData]
- [ ] player.equipment: Dictionary with proper typing
- [ ] Equipment contributes to _recalculate_stats()

### UI Layer
- [ ] UIRoot CanvasLayer hierarchy in main.tscn
- [ ] Inventory panel with GridContainer (4x6)
- [ ] Equipment paper doll (11 slots)
- [ ] Item tooltips (name, stats, description)
- [ ] Item COMPARISON tooltips (vs equipped)
- [ ] Drag-and-drop equipping
- [ ] Right-click context menu
- [ ] Quick-equip hotkey (E)
- [ ] Weight/encumbrance display

### Signals
- [ ] EventBus: inventory_opened/closed, item_equipped/unequipped
- [ ] Input priority system (UI consumes input when open)

---

## Phase 5C: Skills & Abilities

### Data Layer
- [ ] Fix "song" -> "lore" in skills dictionary
- [ ] XP as currency: player.xp_available
- [ ] Skill purchase cost formula (verify from Sil-Q)
- [ ] Ability prerequisite validation
- [ ] Ability toggle system (active/inactive)
- [ ] Light source fuel tracking

### UI Layer
- [ ] Skills panel (8 skills with costs)
- [ ] Ability tree view with prerequisites
- [ ] Prerequisite lines (Line2D)
- [ ] XP display in HUD
- [ ] Contextual tooltips

### Signals
- [ ] GameState.SKILLS_PANEL
- [ ] EventBus: skill_increased, ability_purchased, ability_toggled

---

## Global Requirements

- [ ] Theme Resource for consistent styling
- [ ] Color coding: green=good, red=bad, yellow=neutral
- [ ] Confirmation dialogs for destructive actions
- [ ] Non-modal UI (panels don't fully obscure game)

---

## Research Results (VERIFIED - see PHASE_5_RESEARCH.md)

| ID | Finding | Source |
|----|---------|--------|
| R1 | 13 stat points, cost curve [-4..21] | birth.c:1555 |
| R2 | P: attack:damage:evasion:protection | object.txt |
| R3 | Skill cost = 100 × triangular_sum | birth.c:1740 |
| R4 | Race: N/S/I/H/W/C/F/E/D lines | race.txt |
| R5 | House: N/A/B/F/S/D lines | house.txt |
| R6 | Combat: (1d20+att) - (1d20+evn) | cmd1.c:800 |
| R7 | TVAL→slot mapping complete | defines.h |

---

## Implementation Order

### Week 1: Blockers
1. Research tasks R1-R7
2. B1: Remove level system, implement XP-as-currency
3. B2: Fix item P: line parsing
4. B5/B6: Fix race/house parsing
5. B3: Rewrite combat to opposed rolls
6. B4: Rewrite stat recalculation

### Week 2: Character Creation (5A)
1. Data layer (race/house/CharacterBuild)
2. Scene structure and state management
3. UI screens (race → house → stats → name)
4. Keyboard navigation and flow

### Week 3: Inventory & Equipment (5B)
1. Data layer (tval mapping, slot validation)
2. UI structure (panels, grid, paper doll)
3. Interaction (tooltips, drag-drop, context menu)
4. Polish and signals

### Week 4: Skills & Abilities (5C)
1. Data layer (XP system, prerequisites)
2. Light source fuel system
3. UI panels (skills, ability tree)
4. Integration testing

---

## Success Criteria

A player can:
1. ✅ Create character: race → house → stats → name
2. ✅ View inventory, equip/unequip items, see stat changes
3. ✅ Spend XP to increase skills
4. ✅ Purchase abilities respecting prerequisites
5. ✅ Experience Sil-Q style combat (opposed rolls)
6. ✅ Navigate all menus with keyboard
7. ✅ Understand items through consistent visual feedback

---

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/ui/character_creation.gd` | Creation flow controller |
| `scripts/ui/race_selection.gd` | Race selection screen |
| `scripts/ui/house_selection.gd` | House selection screen |
| `scripts/ui/stat_allocation.gd` | Stat point distribution |
| `scripts/ui/inventory_panel.gd` | Inventory grid |
| `scripts/ui/equipment_panel.gd` | Paper doll display |
| `scripts/ui/item_tooltip.gd` | Item inspection/comparison |
| `scripts/ui/skills_panel.gd` | Skills and abilities |
| `scripts/ui/ability_tree.gd` | Ability tree visualization |
| `scripts/resources/character_build.gd` | Character creation data |
| `scenes/ui/character_creation.tscn` | Creation scene |
| `scenes/ui/inventory.tscn` | Inventory scene |
| `scenes/ui/skills.tscn` | Skills scene |

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/entities/entity.gd` | Opposed roll combat |
| `scripts/entities/player.gd` | XP system, equipment stats, abilities |
| `scripts/core/data_manager.gd` | Race/house/item parsing fixes |
| `scripts/core/game_manager.gd` | Character creation state, game start |
| `scripts/core/event_bus.gd` | New signals |
| `scripts/core/constants.gd` | Equipment slots, tval mapping |
