# Phase 7 Plan - Expert Review Corrections

Based on reviews from three experts: Godot 4.x implementation, Necromancer/Sil-Q fidelity, and roguelike design.

---

## Critical Issues (Must Fix)

### 1. Morale Calculation Incomplete (Fidelity Review)

**Missing modifiers to add:**
```gdscript
# In monster.gd calculate_morale():

# Hallucination bonus
if player.has_effect("image"): morale += 20

# Endgame escape phase
if player.on_the_run: morale += 20

# Light-averse monsters
if has_flag(RF3_HURT_LITE) and cave_light >= 4:
    morale -= (cave_light - 3) * 10

# Thieves lose morale for carried objects (non-unique only)
if not has_flag(RF1_UNIQUE):
    morale -= 20 * carried_items.size()

# Throne room minimum (floor boss area)
if GameManager.current_depth == FINAL_DEPTH:
    morale = max(morale, 20)
```

### 2. Pack Morale Missing 4x Escort Multiplier (Fidelity Review)

**Fix:**
```gdscript
func _calculate_pack_morale() -> int:
    var bonus: int = 0
    for ally in _get_nearby_allies():
        var multiplier: int = 1
        if ally.has_flag(RF1_ESCORT) or ally.has_flag(RF1_ESCORTS):
            multiplier = 4  # CRITICAL: Escorts provide 4x morale

        if ally.stance == Stance.FLEEING:
            bonus -= 10 * multiplier
        else:
            bonus += 10 * multiplier
    return bonus
```

### 3. Perception Roll Formula Wrong (Fidelity Review)

**Original formula:**
- Monsters LOSE alertness when result is NEGATIVE (plan had it inverted)
- Only triggers when monster is OUT of LOS and NOT fleeing
- Uses flow_dist for noise propagation, not simple distance
- Vanish ability changes threshold (15 vs 25)

**Fix:**
```gdscript
func check_lose_player(monster: Monster) -> void:
    # Only check when out of LOS and not fleeing
    if _has_los_to_player(monster): return
    if monster.stance == Stance.FLEEING: return
    if monster.race.sleep <= 0: return  # Never sleeps

    var perception_bonus: int = 25
    if player.has_ability(STL_VANISH):
        perception_bonus = 15

    var monster_skill: int = monster.get_skill(S_PER) + perception_bonus
    var player_skill: int = player.skills[S_STL] + _get_noise_flow_dist(monster.position)

    var result: int = skill_check(monster_skill, player_skill)
    if result < 0:  # NEGATIVE means monster loses track
        monster.alertness = max(monster.alertness + result, ALERTNESS_UNWARY)
```

### 4. FLEE_RANGE Value Wrong (Fidelity Review)

**Fix:**
```gdscript
const MAX_SIGHT: int = 20
const FLEE_RANGE: int = MAX_SIGHT + 20  # = 40, NOT 60
```

### 5. Missing Rally Bonus (Fidelity Review)

When monster stops fleeing, give +60 tmp_morale to prevent oscillation:

```gdscript
func set_stance(new_stance: Stance) -> void:
    if stance == Stance.FLEEING and new_stance != Stance.FLEEING:
        tmp_morale += 60  # Rally bonus
    stance = new_stance
```

### 6. Missing Stance Modifiers (Fidelity Review)

```gdscript
func determine_stance() -> Stance:
    var morale: int = calculate_morale()

    # Mindless always aggressive
    if has_flag(RF2_MINDLESS):
        return Stance.AGGRESSIVE

    # NO_FEAR with positive tmp_morale stays confident
    if has_flag(RF3_NO_FEAR) and tmp_morale >= 0:
        return Stance.CONFIDENT

    var base_stance: Stance
    if morale > 200:
        base_stance = Stance.AGGRESSIVE
    elif morale > 0:
        base_stance = Stance.CONFIDENT
    else:
        base_stance = Stance.FLEEING

    # Trolls are aggressive instead of confident
    if has_flag(RF3_TROLL) and base_stance == Stance.CONFIDENT:
        base_stance = Stance.AGGRESSIVE

    # MFLAG_AGGRESSIVE converts confident to aggressive
    if mflag_aggressive and base_stance == Stance.CONFIDENT:
        base_stance = Stance.AGGRESSIVE

    # Unwary/sleeping monsters default to confident
    if alertness < ALERTNESS_ALERT:
        base_stance = Stance.CONFIDENT

    return base_stance
```

### 7. Skip Next Turn Flag (Fidelity Review)

Monsters that just noticed player or were knocked back skip their turn:

```gdscript
var skip_next_turn: bool = false

func process_turn() -> void:
    if skip_next_turn:
        skip_next_turn = false
        return  # Do nothing this turn
    # ... normal AI processing
```

### 8. Run Mode Recursion Bug (Godot Review)

**Replace recursive implementation with iterative:**
```gdscript
func _run_step() -> void:
    while is_running and run_steps_remaining > 0:
        if not _can_continue_run():
            stop_run()
            return

        move(run_direction)
        run_steps_remaining -= 1
        await get_tree().process_frame  # No recursion!
```

### 9. StatusEffect Callable Serialization (Godot Review)

**Replace inner class with lookup pattern:**
```gdscript
# effect_definitions.gd
const EFFECT_CALLBACKS: Dictionary = {
    "poison": {
        "on_tick": "_poison_tick",
        "damage_formula": "_poison_damage"
    },
    # ... other effects
}

func _poison_damage(duration: int) -> int:
    return (duration + 4) / 5  # Original formula
```

### 10. Save Scumming Vulnerability (Design Review)

**Implement save-on-action:**
```gdscript
func _on_player_action_completed() -> void:
    # Save immediately after any meaningful action
    SaveSystem.quick_save()

func _on_game_load() -> void:
    # Delete save immediately on load (recreate on quit)
    SaveSystem.delete_current_save()
```

**Separate leaderboards:**
```gdscript
enum GameMode { PERMADEATH, CASUAL }
var current_mode: GameMode

func submit_score() -> void:
    var board: String = "permadeath" if current_mode == GameMode.PERMADEATH else "casual"
    HighScoreManager.submit(board, score)
```

---

## High Priority Issues

### 11. Unify GameState Enums (Godot Review)

Remove duplicate from `main.gd`, use only `GameManager.GameState`.

### 12. Cache Morale Calculations (Godot Review)

```gdscript
var _cached_morale: int = 60
var _morale_dirty: bool = true

func calculate_morale() -> int:
    if not _morale_dirty:
        return _cached_morale
    _cached_morale = _compute_morale()
    _morale_dirty = false
    return _cached_morale

func invalidate_morale() -> void:
    _morale_dirty = true
```

### 13. Extract RunStats Class (Godot Review)

Move death tracking stats out of player.gd:
```gdscript
# scripts/systems/run_stats.gd
class_name RunStats
extends RefCounted

var died_from: String = ""
var killer_name: String = ""
# ... all tracking stats

func to_dict() -> Dictionary:
    return { ... }
```

### 14. Add Error Handling to Save/Load (Godot Review)

```gdscript
func save_game(slot: int = 0) -> bool:
    var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
    if file == null:
        var err: int = FileAccess.get_open_error()
        push_error("Failed to open save file: %d" % err)
        return false
    # ... proper error handling throughout
```

### 15. Score Formula Oversimplified (Fidelity Review)

**Replace with proper formula:**
```gdscript
func calculate_score() -> int:
    var points: int = 0

    # Base: 100000 - turns (0-99999)
    points += max(0, 100000 - total_turns)

    # Depth bonus: 10 * challenge_factor per level
    points += current_depth * 10 * _get_challenge_factor()

    # Silmaril bonus (if applicable)
    points += silmarils_collected * 10000 * _get_challenge_factor()

    # Escape bonus
    if escaped:
        points += 50000 * _get_challenge_factor()

    # Victory bonus
    if necromancer_defeated:
        points += 500000 * _get_challenge_factor()

    return points

func _get_challenge_factor() -> int:
    # Race-based difficulty multiplier
    match player.race:
        "Dwarf": return 5
        "Noldor": return 3
        # ... etc
    return 4
```

### 16. Accessibility: Screen Reader Support (Design Review)

```gdscript
# Add to all UI elements
func _ready() -> void:
    set_accessibility_name("Health: %d of %d" % [current_hp, max_hp])

# Add sound cues
func apply_effect(effect_id: String) -> void:
    AudioManager.play_effect_sound(effect_id)
    # ... rest of logic
```

### 17. Accessibility: Colorblind Mode (Design Review)

```gdscript
# Path markers use shapes + colors
func draw_path_marker(pos: Vector2i, type: String) -> void:
    var marker: Node2D = _get_marker()
    marker.position = Vector2(pos) * TILE_SIZE

    match type:
        "monster":
            marker.modulate = Color.RED
            marker.shape = "X"  # Shape indicator too
        "item":
            marker.modulate = Color.YELLOW
            marker.shape = "+"
        "wall":
            marker.modulate = Color.BLUE
            marker.shape = "[]"
```

### 18. Status Effect Duration Display (Design Review)

```gdscript
func _format_effect_message(effect_id: String, duration: int) -> String:
    var base: String = EFFECT_MESSAGES[effect_id]
    return "%s (%d turns)" % [base, duration]
```

---

## Medium Priority Issues

### 19. Mouse Support for Targeting (Design Review)

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if targeting_mode != TargetMode.NONE:
            var tile_pos: Vector2i = _screen_to_tile(event.position)
            set_target(tile_pos)
```

### 20. Click-to-Walk Pathfinding (Design Review)

```gdscript
func _on_map_clicked(tile_pos: Vector2i) -> void:
    if not targeting_mode:
        var path: Array[Vector2i] = Pathfinding.find_path(player.position, tile_pos)
        _start_auto_walk(path)
```

### 21. Item Comparison Tooltips (Design Review)

```gdscript
func show_item_tooltip(item: Item) -> void:
    var equipped: Item = player.get_equipped_in_slot(item.slot)
    if equipped:
        tooltip.show_comparison(item, equipped)
    else:
        tooltip.show_item(item)
```

### 22. Ability Search (Design Review)

```gdscript
# In abilities_panel.gd
func _on_search_text_changed(text: String) -> void:
    var filtered: Array = abilities.filter(func(a):
        return text.to_lower() in a.name.to_lower() or text.to_lower() in a.description.to_lower()
    )
    _display_abilities(filtered)
```

### 23. Contextual First-Time Hints (Design Review)

```gdscript
var shown_hints: Dictionary = {}

func maybe_show_hint(hint_id: String, message: String) -> void:
    if hint_id in shown_hints:
        return
    shown_hints[hint_id] = true
    MessageLog.add("[Tip] " + message, "tutorial")
```

---

## Implementation Order (Revised)

### Phase 0: Refactoring Prep (NEW)
1. Unify GameState enums
2. Create RunStats class
3. Add missing EventBus signals
4. Add effect ID constants

### Phase 1: Foundation (7A + 7C partial)
1. Add corrected morale calculation
2. Add skip_next_turn flag
3. Implement death detection with proper stats
4. Implement core status effects with lookup pattern

### Phase 2: Combat Enhancement (7B + 7C complete)
1. Implement targeting with mouse support
2. Complete status effects with resistance checks
3. Add path visualization with accessibility shapes

### Phase 3: Persistence (7D)
1. Implement save-on-action pattern
2. Add separate permadeath/casual leaderboards
3. Full state serialization with error handling

### Phase 4: AI Polish (7E)
1. Implement corrected morale with all modifiers
2. Add rally bonus and stance modifiers
3. Implement perception roll correctly
4. Add morale caching

### Phase 5: QoL (7G)
1. Implement iterative run mode
2. Add message history with duration display
3. Add click-to-walk pathfinding
4. Create help screen

### Phase 6: Polish (7A complete + onboarding)
1. Implement full score formula
2. Add epitaph generator
3. Add contextual hints
4. Add accessibility features

---

## Summary of Critical Corrections

| Issue | Original Plan | Correction |
|-------|---------------|------------|
| Morale modifiers | 6 modifiers | 11 modifiers (add hallucination, light, items, throne, escape) |
| Pack morale | +10 per ally | +10/40 per ally (4x for escorts) |
| Perception roll | Result > 0 increases | Result < 0 decreases (inverted) |
| FLEE_RANGE | ~60 | 40 |
| Rally bonus | Not mentioned | +60 tmp_morale on stop fleeing |
| Stance modifiers | Basic 3-tier | Trolls, NO_FEAR, MFLAG_AGGRESSIVE, unwary override |
| Run mode | Recursive await | Iterative while loop |
| Status effects | Inner class with Callable | Dictionary + lookup table |
| Save system | Optional permadeath | Save-on-action + separate leaderboards |
| Score formula | 100000 - turns | Full formula with race/depth/escape multipliers |

---

## Files Updated by This Review

The following files in the plan need corrections based on this review:
- `docs/PHASE_7_COMPREHENSIVE_PLAN.md` - All sections need updates per above
- `scripts/entities/monster.gd` - Morale, alertness, stance corrections
- `scripts/systems/status_effects.gd` - Lookup table pattern
- `scripts/systems/save_system.gd` - Save-on-action pattern
- `scripts/systems/high_score_manager.gd` - Full score formula
- `scripts/ui/targeting_system.gd` - Mouse support, accessibility
