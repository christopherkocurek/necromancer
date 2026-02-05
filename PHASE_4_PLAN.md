# Necromancer Godot: Phase 4 Implementation Plan (REVISED)

## Summary

Port foundational game systems from the C codebase to Godot. Phase 4 focuses on **data layer and core mechanics** - getting the formulas and structures right before adding ability effects.

**Exit Criteria**: Energy/speed system working, protection uses dice rolls, ability data parsed correctly, monster flags parsed.

**Design Note**: Levels are ONE-TIME ONLY (no grinding) - intentional design change.

---

## Review Findings (5 Rounds)

Critical issues discovered:
1. **Protection system wrong** - must use dice rolls, not flat AC/5
2. **Attack types missing** - need ATT_* enum for ability triggers
3. **Monster flags** - only 6 parsed, need 15-20 for combat
4. **ability.txt T: lines** - not parsed (item-granted abilities)
5. **Riposte/crit formulas** - incorrect in original plan
6. **Scope too large** - split into Phase 4 (data) and Phase 5 (effects)

---

## Phase 4 Scope (Reduced)

### INCLUDE:
- Constants/enums (AttackType, Skill, DamageType, RF flags)
- Fix protection system (dice rolls per armor piece)
- Player state tracking (previous actions, attack counters)
- Monster flag parsing (15-20 combat flags)
- Energy/speed turn system
- Ability data layer (parsing only - no combat effects)

### DEFER TO PHASE 5:
- Ability combat effects (knockback, cleave, riposte, flanking)
- Advanced combat integration
- Ranged combat framework
- Ability UI
- Songs/Lore system

---

## 4.1 Constants & Enums

**New File**: `scripts/core/constants.gd`

```gdscript
class_name Constants

# Skills (S_*)
enum Skill {
    S_MEL = 0,  # Melee
    S_ARC = 1,  # Archery
    S_EVN = 2,  # Evasion
    S_STL = 3,  # Stealth
    S_PER = 4,  # Perception
    S_WIL = 5,  # Will
    S_SMT = 6,  # Smithing
    S_LOR = 7   # Lore
}
const S_MAX: int = 8
const ABILITIES_MAX: int = 20

# Attack Types (for ability triggers)
enum AttackType {
    ATT_MAIN = 0,
    ATT_FLANKING = 1,
    ATT_CONTROLLED_RETREAT = 2,
    ATT_ZONE_OF_CONTROL = 3,
    ATT_OPPORTUNIST = 4,
    ATT_POLEARM = 5,
    ATT_FOLLOW_THROUGH = 6,
    ATT_RIPOSTE = 7,
    ATT_CLEAVE = 8,
    ATT_RAGE = 9,
    ATT_OPPORTUNITY = 10,
    ATT_IMPALE = 11
}

# Damage Types
enum DamageType {
    GF_HURT = 1,
    GF_ARROW = 2,
    GF_BOULDER = 3,
    GF_FIRE = 6,
    GF_COLD = 7,
    GF_POIS = 8,
    GF_DARK = 10
}

# Melee Abilities
enum MeleeAbility {
    MEL_POWER = 0,
    MEL_FINESSE = 1,
    MEL_KNOCK_BACK = 2,
    MEL_POLEARMS = 3,
    MEL_CHARGE = 4,
    MEL_FOLLOW_THROUGH = 5,
    MEL_OPENING_STRIKE = 6,
    MEL_CONTROL = 7,  # Subtlety - one-handed finesse
    MEL_CLEAVE = 8,
    MEL_ZONE_OF_CONTROL = 9,
    MEL_MIGHTY_BLOW = 10,
    MEL_DEFENSIVE_STANCE = 11,
    MEL_RAPID_ATTACK = 12,
    MEL_STR = 13
}

# Evasion Abilities
enum EvasionAbility {
    EVN_DODGING = 0,
    EVN_BLOCKING = 1,
    EVN_PARRY = 2,
    EVN_CROWD_FIGHTING = 3,
    EVN_LEAPING = 4,
    EVN_SPRINTING = 5,
    EVN_FLANKING = 6,
    EVN_HEAVY_ARMOUR = 7,
    EVN_RIPOSTE = 8,
    EVN_CONTROLLED_RETREAT = 9,
    EVN_DEX = 10
}

# Monster Flags (RF1 - general)
const RF1_UNIQUE: int = 0x00000001
const RF1_NO_CRIT: int = 0x00040000
const RF1_RES_CRIT: int = 0x00080000

# Monster Flags (RF2 - abilities)
const RF2_RIPOSTE: int = 0x00000400
const RF2_FLANKING: int = 0x00000800
const RF2_CHARGE: int = 0x04000000
const RF2_KNOCK_BACK: int = 0x10000000
const RF2_ZONE_OF_CONTROL: int = 0x80000000

# Monster Flags (RF4 - spells/ranged)
const RF4_ARROW1: int = 0x00000001
const RF4_ARROW2: int = 0x00000002
const RF4_BOULDER: int = 0x00000004

# Flag name to bit mapping
const FLAG_MAP: Dictionary = {
    "UNIQUE": [1, RF1_UNIQUE],
    "NO_CRIT": [1, RF1_NO_CRIT],
    "RES_CRIT": [1, RF1_RES_CRIT],
    "RIPOSTE": [2, RF2_RIPOSTE],
    "FLANKING": [2, RF2_FLANKING],
    "CHARGE": [2, RF2_CHARGE],
    "KNOCK_BACK": [2, RF2_KNOCK_BACK],
    "ZONE_OF_CONTROL": [2, RF2_ZONE_OF_CONTROL],
    "ARROW1": [4, RF4_ARROW1],
    "ARROW2": [4, RF4_ARROW2],
    "BOULDER": [4, RF4_BOULDER]
}
```

---

## 4.2 Protection System Fix

**File**: `scripts/entities/entity.gd`

**REMOVE** (lines ~177-180):
```gdscript
func _calculate_damage_reduction(base_damage: int, _damage_type: String) -> int:
    var reduction := armor_class / 5
    return max(1, base_damage - reduction)
```

**REPLACE WITH**:
```gdscript
# Protection dice (replaces armor_class)
var protection_dice: int = 0   # Number of dice (pd)
var protection_sides: int = 0  # Sides per die (ps)

func roll_protection(damage_type: int = Constants.DamageType.GF_HURT) -> int:
    if protection_dice <= 0 or protection_sides <= 0:
        return 0
    var total: int = 0
    for i in range(protection_dice):
        total += randi_range(1, protection_sides)
    return total

func _calculate_damage_reduction(base_damage: int, damage_type: String) -> int:
    var prot := roll_protection()
    return max(0, base_damage - prot)
```

**Note**: Full protection per-slot dice comes in Phase 5 with equipment system.

---

## 4.3 Player State Tracking

**File**: `scripts/entities/player.gd`

**ADD** after existing stats:
```gdscript
# Ability tracking (S_MAX x ABILITIES_MAX arrays)
var innate_ability: Array = []   # Learned permanently
var active_ability: Array = []   # Currently enabled
var have_ability: Array = []     # Includes item grants

# Action tracking (for abilities like Charge, Dodging, Controlled Retreat)
var previous_action: Array = []  # Last 3 actions [0]=most recent
const ACTION_MAX: int = 3
const ACTION_NOTHING: int = 0
const ACTION_MOVE: int = 1       # 1-9 = direction
const ACTION_WAIT: int = 5
const ACTION_MISC: int = 10
const ACTION_ARCHERY: int = 11

# Combat state (reset each turn)
var ripostes_this_turn: int = 0
var attacks_this_turn: int = 0
var consecutive_attacks: int = 0
var last_attack_monster_idx: int = -1
var knocked_back: bool = false
var moved_this_turn: bool = false

func _init_ability_arrays() -> void:
    for i in range(Constants.S_MAX):
        innate_ability.append([])
        active_ability.append([])
        have_ability.append([])
        for j in range(Constants.ABILITIES_MAX):
            innate_ability[i].append(false)
            active_ability[i].append(false)
            have_ability[i].append(false)
    previous_action.resize(ACTION_MAX)
    previous_action.fill(ACTION_NOTHING)

func record_action(action: int) -> void:
    previous_action.insert(0, action)
    if previous_action.size() > ACTION_MAX:
        previous_action.resize(ACTION_MAX)

func reset_turn_state() -> void:
    ripostes_this_turn = 0
    attacks_this_turn = 0
    moved_this_turn = false
    knocked_back = false

func has_ability(skill: int, ability: int) -> bool:
    if skill < 0 or skill >= Constants.S_MAX:
        return false
    if ability < 0 or ability >= Constants.ABILITIES_MAX:
        return false
    return active_ability[skill][ability]
```

---

## 4.4 Monster Flag Parsing

**File**: `scripts/core/data_manager.gd`

**Modify MonsterData class**:
```gdscript
class MonsterData:
    var name: String = ""
    var display_char: String = ""
    var depth: int = 0
    var rarity: int = 0
    var speed: int = 2
    var health_dice: String = "1d8"
    var evasion: int = 0
    var experience: int = 0
    var attacks: Array[Dictionary] = []

    # Bitflag storage (replacing Array[String])
    var flags1: int = 0  # RF1 - general flags
    var flags2: int = 0  # RF2 - ability flags
    var flags3: int = 0  # RF3 - race/resist flags
    var flags4: int = 0  # RF4 - spell/ranged flags

    func has_flag(flag_name: String) -> bool:
        if not Constants.FLAG_MAP.has(flag_name):
            return false
        var info: Array = Constants.FLAG_MAP[flag_name]
        var flag_set: int = info[0]
        var flag_bit: int = info[1]
        match flag_set:
            1: return (flags1 & flag_bit) != 0
            2: return (flags2 & flag_bit) != 0
            3: return (flags3 & flag_bit) != 0
            4: return (flags4 & flag_bit) != 0
        return false

    func set_flag(flag_name: String) -> void:
        if not Constants.FLAG_MAP.has(flag_name):
            return
        var info: Array = Constants.FLAG_MAP[flag_name]
        var flag_set: int = info[0]
        var flag_bit: int = info[1]
        match flag_set:
            1: flags1 |= flag_bit
            2: flags2 |= flag_bit
            3: flags3 |= flag_bit
            4: flags4 |= flag_bit
```

**Modify monster parsing** to use `set_flag()`:
```gdscript
"F":
    var flag_list := value.split("|")
    for flag in flag_list:
        flag = flag.strip_edges()
        current_monster.set_flag(flag)
```

---

## 4.5 Ability Data Parsing

**File**: `scripts/core/data_manager.gd`

**Enhanced AbilityData class**:
```gdscript
class AbilityData:
    var index: int = 0
    var name: String = ""
    var skill_type: int = 0       # I: first value
    var ability_num: int = 0      # I: second value
    var level_requirement: int = 0 # I: third value
    var prereqs: Array[Dictionary] = []  # P: parsed as [{skill, ability}, ...]
    var item_grants: Array[Dictionary] = []  # T: parsed as [{tval, min_sval, max_sval}, ...]
    var description: String = ""
```

**Enhanced ability parsing**:
```gdscript
func _parse_ability_line(key: String, value: String, current_ability: AbilityData) -> void:
    match key:
        "N":
            var parts := value.split(":")
            if parts.size() >= 2:
                current_ability.index = int(parts[0])
                current_ability.name = parts[1]
        "I":
            var parts := value.split(":")
            if parts.size() >= 1:
                current_ability.skill_type = int(parts[0])
            if parts.size() >= 2:
                current_ability.ability_num = int(parts[1])
            if parts.size() >= 3:
                current_ability.level_requirement = int(parts[2])
        "P":
            # Format: skill/ability:skill/ability:...
            var prereq_list := value.split(":")
            for prereq in prereq_list:
                var p_parts := prereq.split("/")
                if p_parts.size() >= 2:
                    current_ability.prereqs.append({
                        "skill": int(p_parts[0]),
                        "ability": int(p_parts[1])
                    })
        "T":
            # Format: tval:min_sval:max_sval
            var t_parts := value.split(":")
            if t_parts.size() >= 3:
                current_ability.item_grants.append({
                    "tval": int(t_parts[0]),
                    "min_sval": int(t_parts[1]),
                    "max_sval": int(t_parts[2])
                })
        "D":
            if current_ability.description.is_empty():
                current_ability.description = value
            else:
                current_ability.description += " " + value
```

---

## 4.6 Energy/Speed System

**File**: `scripts/entities/entity.gd`

**ADD**:
```gdscript
# Energy system
var energy: int = 0
const ACTION_COST: int = 100
const ENERGY_TABLE: Array[int] = [5, 5, 10, 15, 20, 25, 30, 35]

func get_energy_gain() -> int:
    var speed_index := clampi(speed, 0, ENERGY_TABLE.size() - 1)
    return ENERGY_TABLE[speed_index]

func can_act() -> bool:
    return energy >= ACTION_COST and is_alive

func consume_energy(amount: int = ACTION_COST) -> void:
    energy -= amount

func grant_energy() -> void:
    energy += get_energy_gain()
```

**File**: `scripts/systems/turn_system.gd`

**REWRITE** for energy-based turns:
```gdscript
enum TurnState {
    PROCESSING,
    PLAYER_INPUT,
    PLAYER_ACTING,
    MONSTER_ACTING,
    ANIMATING,
    ROUND_END
}

func _determine_next_actor() -> void:
    if not player or not player.is_alive:
        return

    if player.can_act():
        # Find monsters with MORE energy than player
        var priority_monsters := _get_monsters_above_energy(player.energy + 1)

        if priority_monsters.is_empty():
            current_state = TurnState.PLAYER_INPUT
        else:
            pending_monsters = priority_monsters
            current_state = TurnState.MONSTER_ACTING
    else:
        # Player can't act - process remaining monsters
        var acting_monsters := _get_monsters_above_energy(Entity.ACTION_COST)

        if acting_monsters.is_empty():
            current_state = TurnState.ROUND_END
        else:
            pending_monsters = acting_monsters
            current_state = TurnState.MONSTER_ACTING

func _end_round() -> void:
    current_round += 1

    # Grant energy
    if player and player.is_alive:
        player.grant_energy()
        player.tick_status_effects()
        player.reset_turn_state()

    for monster in current_level.get_monsters():
        if monster.is_alive:
            monster.grant_energy()
            monster.tick_status_effects()

    current_state = TurnState.PROCESSING
```

---

## Combat Formulas (Reference for Phase 5)

### Critical Hit (CORRECTED)
```gdscript
func calculate_crit_dice(hit_result: int, attacker: Entity, weapon_weight: int) -> int:
    var crit_separation: int = 70

    # Finesse: easier crits (-20)
    if attacker.has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_FINESSE):
        crit_separation -= 20

    # Control/Subtlety: one-handed finesse (-20)
    if attacker.has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_CONTROL):
        if not attacker.is_two_handed() and not attacker.has_offhand():
            crit_separation -= 20

    # Power: harder crits (+10) but more damage
    if attacker.has_ability(Constants.Skill.S_MEL, Constants.MeleeAbility.MEL_POWER):
        crit_separation += 10

    # Formula with +4 rounding adjustment
    var crit_dice: int = (hit_result * 10 + 4) / (crit_separation + weapon_weight)
    return max(0, crit_dice)
```

### Riposte Threshold (CORRECTED)
```gdscript
# For player (weapon weight in decipounds)
func get_riposte_threshold_player(weapon_weight: int) -> int:
    return -10 - ((weapon_weight + 9) / 10)

# For monster (uses damage dice count)
func get_riposte_threshold_monster(damage_dice: int) -> int:
    return -10 - (2 * damage_dice)
```

---

## Files Summary

### New Files
| File | Purpose |
|------|---------|
| `scripts/core/constants.gd` | All enums and flag constants |

### Modified Files
| File | Changes |
|------|---------|
| `scripts/entities/entity.gd` | Energy system, protection dice |
| `scripts/entities/player.gd` | Ability arrays, action tracking |
| `scripts/entities/monster.gd` | Flag bitfield integration |
| `scripts/systems/turn_system.gd` | Energy-based turn processing |
| `scripts/core/data_manager.gd` | Enhanced ability/monster parsing |

---

## Implementation Order

| Step | Focus | Files | Risk |
|------|-------|-------|------|
| 1 | Create constants.gd | constants.gd | LOW |
| 2 | Fix protection system | entity.gd | MEDIUM |
| 3 | Add player state tracking | player.gd | LOW |
| 4 | Monster flag parsing | data_manager.gd, monster.gd | LOW |
| 5 | Energy system | entity.gd, turn_system.gd | HIGH |
| 6 | Ability data parsing | data_manager.gd | LOW |

---

## Verification Checklist

### Phase 4 (Data Layer)
- [ ] constants.gd compiles without errors
- [ ] Protection uses dice rolls (visible in damage floaters)
- [ ] Player action tracking works (test with print statements)
- [ ] Monster flags parsed correctly (debug print on spawn)
- [ ] Energy system: fast monsters act more often
- [ ] Ability data loads all 160 abilities with correct prereqs/T-lines

### Deferred to Phase 5
- [ ] Knockback pushes enemy
- [ ] Follow-through/Cleave on kill
- [ ] Riposte on big miss
- [ ] Flanking on move-by
- [ ] Ability UI
- [ ] Ranged combat

---

## Reference Files

| System | C File | Key Lines |
|--------|--------|-----------|
| Energy table | `src/tables.c` | 46-55 |
| Critical formula | `src/cmd1.c` | 1184-1236 |
| Riposte | `src/melee1.c` | 1889-1901 |
| Ability defines | `src/defines.h` | 461-610 |
| Monster flags | `src/defines.h` | 2150-2350 |
| Protection dice | `src/melee1.c` | 88-151 |
