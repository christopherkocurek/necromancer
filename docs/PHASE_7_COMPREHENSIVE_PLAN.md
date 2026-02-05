# Phase 7: Comprehensive Implementation Plan

**Status**: Draft - Pending Expert Review
**Goal**: Complete gameplay systems with full fidelity to original Necromancer/Sil-Q

---

## Overview

This plan covers all Phase 7 systems (7A-7G) based on exhaustive research of the original C codebase. Each section includes the original mechanics, Godot implementation approach, and critical details that must not be lost.

---

## 7A: Death & Game Over System

### Original Mechanics (from death.c, files.c, dungeon.c)

**Death Trigger Flow**:
1. `take_hit()` sets `p_ptr->chp <= 0`
2. Stores cause of death in `died_from[80]`, killer info in `killer_name`, `killer_idx`
3. Sets `is_dead = TRUE`, `leaving = TRUE`
4. Main loop detects death, calls `close_game_aux()`

**Epitaph System** (death.c - 720 lines):
- 15+ epitaph categories based on achievements/conditions
- **Conditional triggers** (checked first):
  - Killed by Sauron/Nazgul → special epitaphs
  - Stole Ring, Found Thrain → achievement epitaphs
  - Long run (>10,000 turns), Short run (<500 turns)
  - Died deep (>=12), Died shallow (<=3)
  - High stealth ratio, High kills (>50), Pacifist (0 kills)
- **Tone-based fallback**: laconic, descriptive, ironic, bleak, aspirational, grim, heroic

**"Your Tale" Death Recap** (death.c:500-630):
- Two-column display:
  - Left: Character name, race, house, slain by, depth, turns
  - Right: Enemies slain, biggest kill, damage dealt, biggest hit
- Middle section: Enemies avoided, times detected, stealth streak, silent kills, doors closed, stairs, potions, herbs
- Bottom: Achievements list ("Glimpsed the Necromancer", "Found Thrain", etc.)

**Death Menu Options**:
- [a] View scores
- [b] View inventory/equipment
- [c] Explore dungeon (all revealed)
- [d] View final messages
- [e] View character sheet
- [f] Add note
- [g] Save character dump
- [Enter] New game
- [Esc] Quit

**High Score System** (files.c):
- Score = 100,000 - turns (lower turns = higher)
- Multipliers: Race factor, Silmarils bonus, Depth bonus, Escape bonus
- Rejected if: Wizard mode, quit by own hand, cheated

**Character Dump**: Auto-generated on death with stats, messages, mini-screenshot, equipment, abilities, kill list

### Godot Implementation

**New Files**:
- `scripts/ui/death_screen.gd`
- `scenes/ui/death_screen.tscn`
- `scripts/systems/epitaph_generator.gd`
- `scripts/systems/high_score_manager.gd`

**Player Stats to Track** (add to player.gd):
```gdscript
var died_from: String = ""
var killer_name: String = ""
var killer_idx: int = -1
var biggest_enemy_killed: int = 0
var enemies_avoided: int = 0
var times_detected: int = 0
var silent_kills: int = 0
var doors_closed: int = 0
var potions_quaffed: int = 0
var herbs_consumed: int = 0
var stairs_descended: int = 0
var stairs_ascended: int = 0
var stealth_streak_max: int = 0
var saw_sauron: bool = false
var found_thrain: bool = false
var killed_nazgul: bool = false
var stole_ring: bool = false
```

**Death Flow**:
1. In `player.gd`: When HP <= 0, emit `player_died(cause, killer)` signal
2. `main.gd`: Transition to `GameState.GAME_OVER`
3. Display death screen with epitaph, stats, menu options

**Epitaph Generator**:
```gdscript
func generate_epitaph() -> String:
    # Check conditional triggers first
    if player.killer_idx == SAURON_ID:
        return _random_from(EPITAPH_KILLED_BY_SAURON)
    if player.stole_ring:
        return _random_from(EPITAPH_STOLE_RING)
    # ... other conditions

    # Fallback to tone-based
    var tone = _analyze_run_profile()
    return _random_from(EPITAPH_BY_TONE[tone])
```

**Critical: Do NOT Lose**:
- Procedural epitaph generation based on run characteristics
- All stat tracking for death recap
- Score calculation formula with race/depth multipliers
- Character dump format for posterity

---

## 7B: Targeting System

### Original Mechanics (from xtra2.c, cmd3.c)

**Target Modes** (defines.h:1574-1580):
- `TARGET_KILL` (0x01): Target monsters for ranged attacks
- `TARGET_LOOK` (0x02): Look/examine mode (space cycles descriptions)
- `TARGET_GRID` (0x08): Grid-based targeting

**Look Mode ('l' key)**:
- Calls `target_set_interactive(TARGET_LOOK, 0)`
- Space key cycles through descriptions of current grid contents
- Shows monster info, item info, terrain info

**Ranged Attack Targeting**:
1. `get_aim_dir()` prompts: "Direction ('f' for closest, '*' to choose, ESC to cancel)?"
2. '*' opens interactive selection via `target_set_interactive(TARGET_KILL, range)`
3. 'f' or 't' auto-targets closest valid enemy
4. Arrow keys for manual direction

**Target Cycling**:
- `get_sorted_target_list()` builds list of valid targets sorted by distance
- Space/+/- cycles through targets
- Arrow keys move to next interesting grid in that direction

**Target Validation** (`target_able()`):
- Monster must be alive (r_idx > 0)
- Monster must be visible (ml flag)
- Monster must not be peaceful
- Monster must be projectable (clear LOS)
- No targeting while hallucinating or raging out of sight

**Path Drawing** (`draw_path()`):
- Draws colored path from player to target
- Red for monsters, yellow for items, blue for walls, white for floor

### Godot Implementation

**New Files**:
- `scripts/systems/targeting_system.gd`
- `scripts/ui/target_cursor.gd`
- `scenes/ui/target_cursor.tscn`

**Targeting States**:
```gdscript
enum TargetMode { NONE, LOOK, KILL }

var current_mode: TargetMode = TargetMode.NONE
var target_list: Array[Vector2i] = []
var target_index: int = 0
var current_target: Vector2i = Vector2i(-1, -1)
```

**Key Bindings**:
- 'x' or 'l': Enter look mode
- '*': Enter kill targeting (for ranged)
- 'f' or 't': Auto-target closest
- Tab: Cycle to next target
- Shift+Tab or '-': Cycle to previous target
- Arrow keys: Move cursor directionally
- Enter or 't': Confirm target
- Escape: Cancel targeting

**Path Visualization**:
```gdscript
func draw_target_path(from: Vector2i, to: Vector2i) -> void:
    var path = Bresenham.get_line(from, to)
    for pos in path:
        var color = _get_path_color(pos)
        _draw_path_marker(pos, color)
```

**Critical: Do NOT Lose**:
- Distance-sorted target list (closest first)
- Projectability validation (not just visibility)
- Directional target picking algorithm
- Path visualization with color coding

---

## 7C: Status Effects System

### Original Mechanics (from xtra2.c, dungeon.c, types.h)

**Player Effects** (types.h:815-833):
| Effect | Max | Decay | Damage |
|--------|-----|-------|--------|
| blind | 10000 | -1/turn | - |
| confused | 10000 | -1/turn | - |
| poisoned | 100 | -(v+4)/5 | (v+4)/5 |
| afraid | 10000 | -1/turn | - |
| stunned | 105 | -1/turn | - |
| cut | 100 | -(v+4)/5 | (v+4)/5 |
| slow | 10000 | -1/turn | - |
| fast | 10000 | -1/turn | - |
| entranced | 10000 | -1/turn | - |
| image (hallucination) | 10000 | -1/turn | - |
| rage | 10000 | -1/turn | - |

**Stun Levels**:
- 0: None
- 1-50: Stunned
- 51-100: Heavily Stunned
- 101-105: Knocked Out (adds blindness)

**Monster Effects** (limited set):
- stunned (byte, max 255)
- confused (s16b, max 200)
- slowed (s16b)
- hasted (s16b)
- tmp_morale (for fear)

**Resistance Checks**:
```c
skill_check(attacker, difficulty - 10*resistance, defender_will, defender) > 0
```
Player wins ties. Equipment flags: TR2_RES_BLIND, TR2_RES_CONFU, TR2_RES_FEAR, etc.

**Effect Messages**:
- Onset: "You are blind!", "You are confused!", "You have been poisoned."
- Recovery: "You can see again.", "You feel less confused now."

### Godot Implementation

**New Files**:
- `scripts/systems/status_effects.gd`
- `scripts/core/effect_definitions.gd`

**Effect Structure**:
```gdscript
class StatusEffect:
    var id: String
    var duration: int
    var max_duration: int
    var decay_rate: int = 1
    var damage_formula: Callable = null  # For poison/cut
    var on_apply: Callable = null
    var on_remove: Callable = null
    var on_tick: Callable = null
```

**Effect Manager**:
```gdscript
var active_effects: Dictionary = {}  # id -> StatusEffect

func apply_effect(target: Entity, effect_id: String, duration: int) -> bool:
    # Check resistance
    if _check_resistance(target, effect_id):
        _show_message("%s resists!" % target.name)
        return false

    # Apply or extend
    if effect_id in active_effects:
        active_effects[effect_id].duration += duration
    else:
        var effect = _create_effect(effect_id, duration)
        active_effects[effect_id] = effect
        effect.on_apply.call(target)

    return true

func tick_effects(target: Entity) -> void:
    for effect in active_effects.values():
        # Apply damage if applicable
        if effect.damage_formula:
            var damage = effect.damage_formula.call(effect.duration)
            target.take_damage(damage, effect.id)

        # Decay
        effect.duration -= effect.decay_rate
        if effect.duration <= 0:
            _remove_effect(target, effect.id)
```

**Critical: Do NOT Lose**:
- Poison/cut damage formula: `(v+4)/5` damage AND decay
- Stun level thresholds (50, 100) with knockout blindness
- Stun anti-stacking at >100 (prevents instant death)
- Resistance check formula with skill checks
- All message variations for severity levels

---

## 7D: Save/Load System

### Original Mechanics (from save.c, load.c)

**Save Format**: Binary with XOR cipher, checksums

**What Gets Saved**:
1. **Player Data**: Name, race, house, stats, skills, abilities, HP/SP, XP, status effects, combat tracking, death info, achievements, quest progress, smithing state, run statistics
2. **Monster Data**: Position, HP, alertness, speed, energy, status, combat state, flags
3. **Monster Lore**: Kill counts, drop tracking, flag discoveries
4. **Dungeon**: Depth, player position, cave info (RLE compressed), terrain, objects, monsters
5. **Inventory**: All items with full properties
6. **RNG State**: Mersenne Twister state (624 u32b values)
7. **Options**: Delay factor, boolean options, window flags
8. **Messages**: History buffer

**File Operations**:
1. Write to `{name}.new` (temp file)
2. Rename old save to `{name}.old`
3. Move `.new` to permanent
4. Delete backup on success

**Versioning**: 4-byte header (major, minor, patch, extra)

**Checksums**: Two checksums (v_stamp, x_stamp) for integrity

### Godot Implementation

**New Files**:
- `scripts/systems/save_system.gd`
- `scripts/core/save_data.gd`

**Save Structure** (JSON for simplicity):
```gdscript
class SaveData:
    var version: String = "1.0.0"
    var timestamp: int
    var player: Dictionary
    var dungeon: Dictionary
    var monsters: Array
    var items: Array
    var rng_state: Dictionary
    var options: Dictionary
    var messages: Array
```

**Save Flow**:
```gdscript
func save_game(slot: int = 0) -> bool:
    var data = SaveData.new()
    data.timestamp = Time.get_unix_time_from_system()
    data.player = _serialize_player()
    data.dungeon = _serialize_dungeon()
    data.monsters = _serialize_monsters()
    data.items = _serialize_items()
    data.rng_state = _serialize_rng()

    var json = JSON.stringify(data.to_dict())
    var path = "user://saves/save_%d.json" % slot
    var temp_path = path + ".tmp"

    # Write to temp first
    var file = FileAccess.open(temp_path, FileAccess.WRITE)
    file.store_string(json)
    file.close()

    # Atomic rename
    DirAccess.rename_absolute(temp_path, path)
    return true
```

**Permadeath Toggle**:
```gdscript
var permadeath_enabled: bool = true

func on_player_death() -> void:
    if permadeath_enabled:
        _delete_save(current_slot)
```

**Critical: Do NOT Lose**:
- Full RNG state preservation (deterministic replay)
- Atomic file operations (temp → rename)
- All monster state (alertness, energy, combat state)
- All player tracking stats for death recap
- Version checking for forward compatibility

---

## 7E: Monster AI Improvements

### Original Mechanics (from melee2.c)

**Alertness System** (continuous spectrum):
| Level | Value | Behavior |
|-------|-------|----------|
| Deep Sleep | -20 | No action |
| Unwary | -10 | Wander only |
| Alert | 0+ | Combat ready |
| Quite Alert | 5 | More vigilant |
| Very Alert | 10 | Highly vigilant |
| Maximum | 20 | Peak awareness |

**Morale Calculation** (base 60):
- Depth difference: `(monster_level - player_depth) * 10`
- Player conditions: Confused +40, Blind +20, Slowed +40, Afraid +40, Entranced +80, Stunned +20/40/80, Wounded +20/40/80
- Monster conditions: Stunned -20, Hasted +40, Wounded -20/-40/-80
- Pack morale: +10 per ally, -10 per fleeing ally
- Abilities: Majesty, Bane, Elf-Bane modifiers

**Stance from Morale**:
- Morale > 200: AGGRESSIVE (charge)
- Morale > 0: CONFIDENT (normal)
- Morale <= 0: FLEEING (run away)

**Range from Stance**:
- Fleeing: min_range = FLEE_RANGE (~60)
- Aggressive: min_range = 1
- Ranged specialists: min_range = 2-8 based on attack type

**Fleeing Decision**:
- Morale drops below 0
- Forced to flee if: wounded + already fleeing gives additional -20
- Extreme fear (morale < -200): May jump into chasms

**Pack Communication** (`tell_allies()`):
- Range: 15 grids (doubled if not in LOS)
- Targets same-type monsters (matching symbol)
- Sets MFLAG_AGGRESSIVE on nearby allies

**Perception Roll**:
```
monster_perception = skill(S_PER) - noise_dist + combat_bonus - bane_bonus
result = (monster_perception + 1d10) - (difficulty + 1d10)
if result > 0: increase alertness by result
```

### Godot Implementation

**Enhanced monster.gd**:
```gdscript
# Alertness
const ALERTNESS_MIN = -20
const ALERTNESS_UNWARY = -10
const ALERTNESS_ALERT = 0
var alertness: int = ALERTNESS_UNWARY

# Morale
var base_morale: int = 60
var tmp_morale: int = 0

enum Stance { AGGRESSIVE, CONFIDENT, FLEEING }
var stance: Stance = Stance.CONFIDENT

func calculate_morale() -> int:
    var morale = base_morale + tmp_morale

    # Depth difference
    morale += (level - GameManager.current_depth) * 10

    # Player conditions
    var player = GameManager.player
    if player.has_effect("confused"): morale += 40
    if player.has_effect("blind"): morale += 20
    # ... etc

    # Monster conditions
    if has_effect("stunned"): morale -= 20
    var hp_pct = float(hp) / max_hp
    if hp_pct <= 0.25: morale -= 80
    elif hp_pct <= 0.5: morale -= 40
    elif hp_pct <= 0.75: morale -= 20

    # Pack morale
    morale += _calculate_pack_morale()

    return morale

func determine_stance() -> Stance:
    var morale = calculate_morale()
    if has_flag(RF2_MINDLESS):
        return Stance.AGGRESSIVE
    if morale > 200:
        return Stance.AGGRESSIVE
    elif morale > 0:
        return Stance.CONFIDENT
    else:
        return Stance.FLEEING
```

**Critical: Do NOT Lose**:
- Continuous alertness spectrum (not discrete states)
- Full morale calculation with all modifiers
- Pack morale system with ally communication
- Perception roll formula
- TURN_RANGE (3) forcing trapped monsters to fight
- Mindless monsters always aggressive

---

## 7F: Smithing System

### Original Mechanics (from cmd4.c, terrain.txt, ability.txt)

**Forge Types**:
| Type | Terrain IDs | Bonus | Uses |
|------|-------------|-------|------|
| Orc Forge | 64-69 | +0 | 0-5 |
| Shadow Forge | 70-75 | +3 | 0-5 |
| Forge 'Angdur' | 76-79 | +7 | 0-5 |

**Smithable Categories**:
- Weapons: Swords, Axes, Polearms, Blunt, Bows, Arrows
- Armour: Soft, Mail, Cloaks, Shields, Helms, Gloves, Boots
- Jewelry: Rings, Amulets, Light Sources, Horns

**Operations**:
1. CREATE: Select base item, customize stats
2. ENCHANT: Add flags (stat bonuses, slays, resistances)
3. ARTEFACT: Convert to self-made artifact
4. NUMBERS: Modify attack, damage, evasion, protection, pval, weight
5. MELT: Recover mithril from items
6. REFORGE: Combine 2 Broken Glowing → enchanted item (600 XP)
7. RECLAIM: Combine 2 Broken Strange → artifact
8. MASTERWORK: Combine 4 Broken Strange → legendary

**Costs**:
- Stat drains: STR, DEX, CON, GRA (varies by item)
- Mithril: Item weight in tenths of pounds
- Forge uses: 1 per action
- XP: 600 for Reforge

**Smithing Abilities** (12 total):
1. Weaponsmith (ID 120) - Create weapons
2. Armoursmith (ID 121) - Create armor
3. Jeweller (ID 122) - Create jewelry
4. Reforge (ID 123) - Combine broken items
5. Expertise (ID 124) - 50% time/cost reduction
6. Reclaim (ID 125) - Create artifacts
7. Masterwork (ID 126) - Create legendaries
8. Grace (ID 127) - +1 Grace
9. Reforge Mastery (ID 128) - Reroll once
10. Salvage (ID 129) - Save destroyed equipment
11. Reclaim Mastery (ID 130) - Choose from 3
12. Master Smith (ID 131) - Masterwork with 2 items

**Difficulty Formula**: Based on item type, weight, enchantments, flags

### Godot Implementation

**New Files**:
- `scripts/systems/smithing_system.gd`
- `scripts/ui/smithing_panel.gd`
- `scenes/ui/smithing_panel.tscn`

**Forge Terrain**:
```gdscript
func get_forge_at(pos: Vector2i) -> Dictionary:
    var terrain = level.get_terrain(pos)
    if not terrain.is_forge:
        return {}
    return {
        "type": terrain.forge_type,  # "orc", "shadow", "angdur"
        "bonus": terrain.forge_bonus,
        "uses": terrain.forge_uses
    }
```

**Smithing UI Flow**:
1. Player stands on forge, presses '0'
2. Show main menu: Create/Enchant/Artefact/Numbers/Melt/Reforge/Reclaim/Masterwork/Accept
3. Each submenu shows difficulty, costs, requirements
4. Accept triggers smithing timer

**Critical: Do NOT Lose**:
- Three forge types with different bonuses
- Limited forge uses (0-5)
- Full ability prerequisite chain
- Broken item system for special crafting
- Stat drain costs
- Smithing time formula

---

## 7G: Quality of Life Features

### Original Mechanics (from cmd1.c, cmd2.c, util.c, files.c)

**Run Mode** ('.' or Shift+direction):
- Calls `run_init(dir)` then `run_step(dir)`
- Default 1000 steps
- Stops on: monster, object, terrain change, intersection, confusion

**Hallway Following Algorithm**:
- Tracks `run_open_area`, `run_break_left`, `run_break_right`
- Automatically follows corners
- Won't enter enclosed spaces from open areas

**Message System**:
- Circular buffer for efficiency
- Deduplicates recent identical messages ("Message <3x>")
- Color-coded by type
- History accessible

**Help Screen ('?' key)**:
- 3 pages: Movement & interaction, Terrain legend, Item/creature info
- Navigation: any key = next, '8'/'-' = previous

**Map View ('M' key)**:
- Full dungeon level overview
- Compressed display showing explored areas

**NO Auto-Explore**: Original game lacks 'o' auto-explore

### Godot Implementation

**Run Mode**:
```gdscript
var is_running: bool = false
var run_direction: Vector2i
var run_steps_remaining: int = 0

func start_run(direction: Vector2i) -> void:
    is_running = true
    run_direction = direction
    run_steps_remaining = 1000
    _run_step()

func _run_step() -> void:
    if not _can_continue_run():
        stop_run()
        return

    move(run_direction)
    run_steps_remaining -= 1

    # Continue next frame
    await get_tree().process_frame
    if is_running:
        _run_step()

func _can_continue_run() -> bool:
    if run_steps_remaining <= 0: return false
    if _monster_visible(): return false
    if _item_at_feet(): return false
    if _terrain_changed(): return false
    if _at_intersection(): return false
    return true
```

**Message Log**:
```gdscript
var message_history: Array[Dictionary] = []
const MAX_MESSAGES = 200

func add_message(text: String, type: String = "generic") -> void:
    # Deduplicate
    if message_history.size() > 0:
        var last = message_history[-1]
        if last.text == text:
            last.count += 1
            _update_display()
            return

    message_history.append({
        "text": text,
        "type": type,
        "count": 1,
        "timestamp": Time.get_ticks_msec()
    })

    if message_history.size() > MAX_MESSAGES:
        message_history.pop_front()

    _update_display()
```

**Help Screen**:
- Create `help_screen.tscn` with 3 pages
- '?' toggles visibility
- Show keybindings, terrain legend, commands

**Critical: Do NOT Lose**:
- Sophisticated run stopping conditions
- Hallway corner following
- Message deduplication with count display
- All three help pages

---

## Implementation Order

### Phase 1: Foundation (7A + 7C partial)
1. Add player death stats tracking
2. Implement basic death detection and screen
3. Implement core status effects (poison, stun, blind, confused)

### Phase 2: Combat Enhancement (7B + 7C complete)
1. Implement targeting system with look mode
2. Complete all status effects with resistances
3. Add path visualization

### Phase 3: Persistence (7D)
1. Implement save/load with full state
2. Add permadeath toggle
3. Test save compatibility

### Phase 4: AI Polish (7E)
1. Enhance monster alertness system
2. Implement full morale calculation
3. Add pack communication

### Phase 5: QoL (7G)
1. Implement run mode with smart stopping
2. Add message history panel
3. Create help screen

### Phase 6: Advanced (7A complete + 7F)
1. Implement epitaph generator
2. Add high score system
3. Implement smithing system (if forges exist)

---

## Success Criteria

- [ ] Player can die and see procedurally-generated epitaph
- [ ] Death recap shows all tracked stats
- [ ] High scores persist between sessions
- [ ] Look mode examines any tile
- [ ] Ranged targeting with path preview works
- [ ] All status effects function with proper decay
- [ ] Resistance checks use skill formula
- [ ] Game saves and loads complete state
- [ ] Permadeath optionally deletes save
- [ ] Monsters flee based on morale
- [ ] Pack communication alerts nearby monsters
- [ ] Run mode follows hallways smartly
- [ ] Message log shows history with deduplication
- [ ] Help screen shows all controls

---

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/ui/death_screen.gd` | Death UI and menu |
| `scripts/systems/epitaph_generator.gd` | Procedural epitaphs |
| `scripts/systems/high_score_manager.gd` | Score tracking |
| `scripts/systems/targeting_system.gd` | Target selection |
| `scripts/ui/target_cursor.gd` | Cursor display |
| `scripts/systems/status_effects.gd` | Effect management |
| `scripts/core/effect_definitions.gd` | Effect data |
| `scripts/systems/save_system.gd` | Save/load |
| `scripts/core/save_data.gd` | Save structure |
| `scripts/ui/smithing_panel.gd` | Smithing UI |
| `scripts/systems/smithing_system.gd` | Smithing logic |
| `scripts/ui/help_screen.gd` | Help display |
| `scripts/ui/message_log_panel.gd` | Message history |

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/entities/player.gd` | Death stats, effect tracking |
| `scripts/entities/monster.gd` | Alertness, morale, pack AI |
| `scripts/main.gd` | Game states, death handling |
| `scripts/ui/hud.gd` | Effect icons, message display |
| `scripts/core/constants.gd` | New enums and constants |
