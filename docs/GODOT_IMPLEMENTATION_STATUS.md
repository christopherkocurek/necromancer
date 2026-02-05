# The Necromancer - Godot Implementation Status

**Audit Date:** 2026-02-05
**Engine:** Godot 4.6 (Forward Plus renderer)
**Files Audited:** 41 GDScript files, 14 data files, project.godot

---

## Table of Contents

1. [Combat System](#1-combat-system)
2. [Stealth & Detection](#2-stealth--detection)
3. [FOV & Light](#3-fov--light)
4. [Skill System](#4-skill-system)
5. [Character Creation](#5-character-creation)
6. [Monster Status](#6-monster-status)
7. [Item Status](#7-item-status)
8. [Dungeon Generation](#8-dungeon-generation)
9. [Special Systems](#9-special-systems)
10. [UI Status](#10-ui-status)
11. [Input Bindings](#11-input-bindings)
12. [Known Issues & TODOs](#12-known-issues--todos)

---

## 1. Combat System

### 1.1 Hit Resolution (Sil-Q Opposed Roll)

**File:** `scripts/entities/entity.gd` lines 292-336

The combat system uses Sil-Q's opposed d20 roll mechanic:

```gdscript
# entity.gd lines 293-296
var attack_score: int = randi_range(1, 20) + melee_bonus
var evasion_score: int = randi_range(1, 20) + target.evasion_bonus
var hit_result: int = attack_score - evasion_score
```

- **Hit:** `hit_result >= 0` (attack wins ties)
- **Miss:** `hit_result < 0` (logged with scores)

### 1.2 Damage Calculation

**File:** `scripts/entities/entity.gd` lines 306-324

```gdscript
# Base damage from weapon dice
var weapon_weight: int = _get_weapon_weight()
var damage: int = DataManager.roll_dice(damage_dice)

# STR damage bonus capped by weapon weight
var str_bonus: int = strength / 2
var weight_cap: int = weapon_weight / 10
var actual_str_bonus: int = mini(str_bonus, weight_cap)
damage += actual_str_bonus

# Critical hit: (hit_result * 10 + 4) / (70 + weapon_weight)
var crit_dice: int = (hit_result * 10 + 4) / (70 + weapon_weight)

# Apply crit bonus dice (re-rolls weapon damage dice per crit die)
var crit_damage: int = 0
for i in range(crit_dice):
    crit_damage += DataManager.roll_dice(damage_dice)
damage += crit_damage
```

**Crit formula:** Heavier weapons make crits harder but allow more STR bonus. Light weapons crit easily but cap STR.

### 1.3 Protection (Damage Reduction)

**File:** `scripts/entities/entity.gd` lines 189-212

Protection uses a dice roll system instead of flat AC:

```gdscript
# entity.gd lines 205-212
func roll_protection(_damage_type: int = 1) -> int:
    if protection_dice <= 0 or protection_sides <= 0:
        return 0
    var total: int = 0
    for i in range(protection_dice):
        total += randi_range(1, protection_sides)
    return total
```

**Damage reduction:** `final_damage = max(0, base_damage - protection_roll)`

Player protection is recalculated from all equipped armor pieces in `player.gd` `_recalculate_protection()`.

### 1.4 Stat Derivation

**File:** `scripts/entities/player.gd` lines 140-168

```gdscript
# player.gd lines 148-153
melee_bonus = skills["melee"] + strength / 2
evasion_bonus = skills["evasion"] + dexterity / 2
max_health = 20 + constitution * 4
```

- **Melee bonus:** skill level + STR/2
- **Evasion bonus:** skill level + DEX/2
- **Max health:** 20 + CON * 4

### 1.5 Energy System

**File:** `scripts/entities/entity.gd` lines 347-359, `scripts/core/constants.gd` lines 51-55

```gdscript
# constants.gd lines 53-54
const ENERGY_TABLE: Array[int] = [50, 75, 100, 125, 150, 175, 200, 250]
const ACTION_COST: int = 100
```

All entities gain energy per game tick based on speed index (0-7). Acting costs 100 energy. Speed 2 (100 energy/tick) = 1 action/tick. Speed 4 (150 energy/tick) = 1.5 actions/tick average.

### 1.6 Status Effects in Combat

**File:** `scripts/entities/entity.gd` lines 274-286

Status effect tick processing:

| Effect      | Damage/Turn         |
|-------------|---------------------|
| Poison      | `power` damage      |
| Regeneration| `power` healing     |
| Burning     | `power * 2` fire    |
| Bleeding    | `power` physical    |

### 1.7 Damage Floaters

**Files:** `scripts/systems/floater_manager.gd`, `scripts/systems/damage_floater.gd`

Visual feedback system with color-coded floating text:
- Physical: Red
- Fire: Orange
- Cold: Light blue
- Poison: Green
- Dark: Purple
- Healing: Bright green
- Miss: Gray
- Critical: Yellow

Floaters scale by damage (16px base, 20px for 10+, 24px for 20+).

### 1.8 What Is Missing from Combat

- **Archery/ranged attacks:** No ranged combat implementation. Bow slot exists but no firing mechanic.
- **Flanking bonuses:** Referenced in data but not implemented in code.
- **Weapon proficiency bonuses:** Race flags (`BOW_PROFICIENCY`, `SWORD_PROFICIENCY`, `AXE_PROFICIENCY`) defined but not applied in combat calculations.
- **Monster special attacks:** Only basic `HURT` and `POISON` attack effects processed. `FIRE`, `COLD`, `DARK`, `BLIND`, `CONFUSE`, `FEAR`, `STUN`, etc. from monster.txt `B:` lines are parsed but not all fully resolved in damage application.
- **Monster spells:** `SHRIEK`, `S:SPELL_PCT_*` lines parsed but spell casting not implemented in monster AI.
- **Item identification:** No identification system. All items are known on pickup.

---

## 2. Stealth & Detection

### 2.1 Monster Alertness System

**File:** `scripts/entities/monster.gd`

Alertness range: -20 (deep sleep) to +20 (maximum alert)

**Constants** (`scripts/core/constants.gd` lines 63-67):
```gdscript
const ALERTNESS_SLEEPING: int = -20
const ALERTNESS_UNWARY: int = -10
const ALERTNESS_ALERT: int = 0
const ALERTNESS_MAX: int = 20
```

### 2.2 Detection Roll

**File:** `scripts/entities/monster.gd`

Detection uses opposed d20 rolls:
```gdscript
# Opposed roll: monster perception vs player stealth
var perception_roll: int = randi_range(1, 20) + perception_score
var stealth_roll: int = randi_range(1, 20) + player_stealth
```

Detection modifiers:
- Line of sight bonus to monster
- Distance penalty to monster
- Alertness state affects detection threshold

### 2.3 AI State Machine

**File:** `scripts/entities/monster.gd`

Four AI states:
| State       | Behavior                                    |
|-------------|---------------------------------------------|
| `IDLE`      | Stationary, low alertness                   |
| `WANDERING` | Random movement, checking for player        |
| `HUNTING`   | A* pathfinding to player, aggressive        |
| `FLEEING`   | Move away from player, low morale           |

State transitions based on alertness thresholds and morale.

### 2.4 Morale System

**File:** `scripts/entities/monster.gd`

```
current_morale = base_morale
    - health_penalty (lower HP = lower morale)
    + escort_bonus (allies nearby)
    + rally_bonus (leader nearby)
    + territorial_bonus (near spawn point)
```

Stance derived from morale:
- `morale > 200` = AGGRESSIVE
- `morale > 0` = CONFIDENT
- `morale <= 0` = FLEEING

### 2.5 What Is Missing from Stealth

- **Stealth toggle/mode:** No explicit "stealth mode" the player can activate.
- **Noise system:** No sound propagation or noise-based detection.
- **Floor-wide alertness:** No global alert level that escalates when monsters detect the player.
- **Light-based detection:** FOV radius changes by layer but light level does not affect stealth rolls.
- **Monster communication:** `SHRIEK` spell parsed but not implemented as an alertness propagation mechanic.

---

## 3. FOV & Light

### 3.1 FOV Algorithm

**File:** `scripts/systems/level.gd` lines 291-316

Simple raycasting FOV with 360 one-degree rays:

```gdscript
# level.gd lines 296-316
for angle in range(360):
    var rad := deg_to_rad(angle)
    var dx := cos(rad)
    var dy := sin(rad)
    var x := float(center.x) + 0.5
    var y := float(center.y) + 0.5
    for _step in range(radius):
        var check_pos := Vector2i(int(x), int(y))
        if not is_in_bounds(check_pos):
            break
        set_tile_visible(check_pos, true)
        if not is_transparent(check_pos):
            break
        x += dx
        y += dy
```

### 3.2 FOV Radius by Layer

**File:** `scripts/systems/layer_config.gd`

| Layer | Depths | FOV Radius |
|-------|--------|------------|
| Outer Pits | 1-3 | 8 |
| Lower Halls | 4-6 | 7 |
| Dark Halls | 7-9 | 7 |
| Necropolis | 10-12 | 6 |
| Pits of Despair | 13-15 | 6 |
| Inner Sanctum | 16-18 | 5 |
| Throne Room | 19-20 | 5 |

### 3.3 Visibility States

**File:** `scripts/systems/level.gd` lines 164-182

Three visibility states per tile:
- **Visible:** Currently in FOV (full brightness)
- **Explored:** Previously seen (darkened via shader)
- **Unexplored:** Never seen (black)

### 3.4 Layer Visual Theming

**File:** `scripts/systems/layer_config.gd`

Each layer has shader tint parameters:
- `tint_color`: Color overlay (ranges from forest green to blood red)
- `tint_strength`: Intensity (0.05 to 0.25)

Applied via `assets/shaders/layer_tint.tres` shader material.

### 3.5 Line of Sight

**File:** `scripts/systems/level.gd` lines 323-352

Bresenham line algorithm for LOS checks between two positions. Used by monster AI for targeting.

### 3.6 What Is Missing from FOV/Light

- **Torch fuel system:** No fuel consumption, no torch duration.
- **Light radius per entity:** No per-entity light source calculation.
- **Darkness combat penalties:** No penalty for fighting in dark vs lit areas.
- **Inner Light ability:** Deferred (ability 147). Would add +1 light per 5 Lore points.
- **Deep Memory ability:** Deferred (ability 142). Would reveal map gradually.
- **Dynamic lighting:** No multi-source lighting. Single FOV from player position only.

---

## 4. Skill System

### 4.1 Skills

**File:** `scripts/entities/player.gd`, `scripts/core/constants.gd` lines 22-33

8 skills defined:

| ID | Name       | Effect                                          |
|----|------------|-------------------------------------------------|
| 0  | Melee      | +1 melee_bonus per level                        |
| 1  | Archery    | +1 ranged_bonus per level (NOT IMPLEMENTED)     |
| 2  | Evasion    | +1 evasion_bonus per level                      |
| 3  | Stealth    | Used in opposed stealth detection rolls         |
| 4  | Perception | Trap avoidance (50% + Per*5%), monster memory    |
| 5  | Will       | Banishment check, status resistance              |
| 6  | Smithing   | Forge success chance (skill * 5%)               |
| 7  | Lore       | Ability power scaling, monster memory bonus      |

### 4.2 XP-as-Currency System

**File:** `scripts/entities/player.gd` lines 104-133

```gdscript
# player.gd lines 105-107
const STARTING_XP: int = 5000
const XP_MULTIPLIER: float = 1.3
static func get_skill_cost(current_level: int) -> int:
    return int(100.0 * (current_level + 1))
```

- Starting XP: 5000
- Cost to raise a skill: `100 * (current_level + 1)` XP
- Skill level 0->1 costs 100, 1->2 costs 200, etc.
- Max skill level: 20 (enforced in UI)
- XP earned from monster kills (depth-scaled)

### 4.3 Abilities

**File:** `scripts/systems/ability_system.gd`, `data/ability.txt`

93 abilities defined in `ability.txt` across 8 skill trees:
- **Melee:** 14 abilities (Power, Finesse, Knock Back, Polearm Mastery, Charge, Follow-Through, Opening Strike, Subtlety, Cleave, Zone of Control, Mighty Blow, Defensive Stance, Swift Strikes, +STR)
- **Archery:** 9 abilities (Rout, Fletchery, Point Blank, Puncture, Ambush, Keen Eyes, Crippling Shot, Deadly Hail, +DEX)
- **Evasion:** 11 abilities (Dodging, Blocking, Parry, Crowd Fighting, Leaping, Sprinting, Flanking, Heavy Armour Use, Riposte, Controlled Retreat, +DEX)
- **Stealth:** 12 abilities (Disguise, Assassination, Disorienting Strike, Escape Artist, Light Fingers, Vanish, +DEX, Throat Slit, Fade, Pilfer, Distraction, Silent Kill)
- **Perception:** 10 abilities (Natural Talent, Focused Attack, Keen Senses, Concentration, Alchemy, Bane, Outwit, Listen, Master Hunter, +GRA)
- **Will:** 11 abilities (Curse Breaking, Force of Will, Strength in Adversity, Formidable, Defy Death, Indomitable, Oath, Poison Resistance, Vengeance, Majesty, +CON)
- **Smithing:** 12 abilities (Weaponsmith, Armoursmith, Jeweller, Reforge, Expertise, Reclaim, Masterwork, +GRA, Reforge Mastery, Salvage, Reclaim Mastery, Master Smith)
- **Lore:** 14 abilities (Word of Command, Lore of Battle, Deep Memory, Word of Opening, Lore of Silence, Herbcraft, Word of Shutting, Inner Light, Deadly Lore, Lore of Endurance, Lore of Sleep, Word of Mastery, Device Mastery, +GRA)

### 4.4 Lore Abilities (Implemented in ability_system.gd)

**File:** `scripts/systems/ability_system.gd`

12 of 14 Lore abilities implemented:

| ID  | Name              | Type    | Cost   | Status       |
|-----|-------------------|---------|--------|--------------|
| 140 | Word of Command   | Active  | 3 voice| IMPLEMENTED  |
| 141 | Lore of Battle    | Active  | 1 voice| IMPLEMENTED  |
| 142 | Deep Memory       | Active  | 2 voice| DEFERRED     |
| 143 | Word of Opening   | Active  | 2 voice| IMPLEMENTED  |
| 144 | Lore of Silence   | Active  | 2 voice| IMPLEMENTED  |
| 145 | Herbcraft         | Passive | --     | IMPLEMENTED  |
| 146 | Word of Shutting  | Active  | 2 voice| IMPLEMENTED  |
| 147 | Inner Light       | Passive | --     | DEFERRED     |
| 148 | Deadly Lore       | Trigger | --     | IMPLEMENTED  |
| 149 | Lore of Endurance | Passive | --     | IMPLEMENTED  |
| 150 | Lore of Sleep     | Active  | 3 voice| IMPLEMENTED  |
| 151 | Word of Mastery   | Active  | 4 voice| IMPLEMENTED  |
| 152 | Device Mastery    | Passive | --     | IMPLEMENTED  |
| 153 | Grace             | Passive | --     | IMPLEMENTED  |

Voice charges regenerate 1 per turn. Max voice = lore_skill.

### 4.5 What Is Missing from Skills

- **Archery skill has no ranged combat to use it.**
- **Most non-Lore abilities are defined in data but NOT implemented as active mechanics.** The AbilitiesPanel allows purchasing them, but melee abilities like Power, Finesse, Charge, Follow-Through, Cleave, etc. have no code executing their effects.
- **Smithing abilities** (Weaponsmith, Armoursmith, Jeweller, etc.) are defined in data but the smithing system only uses base smithing skill level, not specific smithing abilities.
- **Will abilities** (Defy Death, Indomitable, etc.) are defined but not checked during gameplay.
- **Perception abilities** (Listen, Master Hunter, etc.) are defined but not triggered.

---

## 5. Character Creation

### 5.1 Flow

**File:** `scripts/ui/character_creation.gd`

5-stage flow: Race -> House -> Stats -> Name -> Confirm

### 5.2 Races

**File:** `data/race.txt`

| Race   | STR | DEX | CON | GRA | Trait              |
|--------|-----|-----|-----|-----|--------------------|
| Elf    | -1  | +2  | +1  | +2  | BOW_PROFICIENCY    |
| Man    | +1  | 0   | +1  | 0   | SWORD_PROFICIENCY  |
| Dwarf  | +1  | -1  | +3  | 0   | AXE_PROFICIENCY    |
| Istari | +10 | +10 | +10 | +10 | All (debug race)   |

Each race has compatible houses (C: line) and starting equipment (E: lines).

### 5.3 Houses

**File:** `data/house.txt`

9 houses total:

| House            | Race  | STR | DEX | CON | GRA | Affinity |
|------------------|-------|-----|-----|-----|-----|----------|
| Of Lothlorien    | Elf   | 0   | 0   | 0   | +1  | Lore     |
| Of Rivendell     | Elf   | 0   | 0   | +1  | 0   | Smithing |
| Of Greenwood     | Elf   | 0   | +1  | 0   | 0   | Stealth  |
| Dunedain         | Man   | 0   | +1  | 0   | +1  | Perception|
| Of Rohan         | Man   | +1  | 0   | 0   | 0   | Evasion  |
| Of Gondor        | Man   | 0   | 0   | +1  | 0   | Melee    |
| Of Khazad-dum    | Dwarf | 0   | 0   | 0   | +1  | Lore     |
| Of Erebor        | Dwarf | 0   | 0   | +1  | 0   | Smithing |
| Of the Iron Hills| Dwarf | +1  | 0   | 0   | 0   | Melee    |

### 5.4 Stat Allocation

**File:** `scripts/ui/character_creation.gd` lines 181-293

- Total stat points: `Constants.STAT_POINTS_TOTAL`
- Stat range: -4 to +6
- Cost scaling defined in `Constants.get_stat_cost()`
- Final stats = base allocation + race modifiers + house modifiers

### 5.5 Starting Equipment

**File:** `data/race.txt` (E: lines)

Each race defines starting equipment by tval:sval:min:max. Examples:
- All races: Wooden Torches (3)
- Elf: Fragment of Lembas (3), Curved Sword (1)
- Man/Dwarf: Pieces of Dark Bread (5)
- Dwarf: War Hammer instead of Curved Sword

### 5.6 What Is Missing from Character Creation

- **Starting equipment not applied:** Equipment E: lines are parsed by DataManager but `player.gd` does not appear to equip starting items from race data during character initialization.
- **House affinity bonuses:** Affinity flags (e.g., `LOR_AFFINITY`, `MEL_AFFINITY`) are parsed but no code grants starting skill bonuses based on house affinity.
- **Weapon proficiency bonuses:** Race flags defined but not applied in combat formulas.
- **History generation:** `history.txt` is loaded but no character history is displayed.

---

## 6. Monster Status

### 6.1 Data Source

**File:** `data/monster.txt`

77 monster entries defined across 7 layers. Format:
```
N:ID:Name
W:depth:rarity
G:symbol:color
I:speed:health_dice:light_radius
A:sleepiness:perception:stealth:will
P:[evasion,protection_dice]
B:attack_method:effect:(bonus,damage_dice)
S:spell_frequency | spell_power
F:flags
D:description
```

### 6.2 Layer Distribution

| Layer | Depths | Theme | Example Monsters |
|-------|--------|-------|-----------------|
| 1 | 1-3 | Forest Breach | Mirkwood Spider, Giant Rat, Crebain, Tanglethorn |
| 2 | 3-6 | Orc Warrens | Orc Scout, Warg, Orc Archer, Orc Captain |
| 3 | 6-9 | Torture Halls | Sorcerer, Ghoul, Orc Torturer |
| 4 | 9-12 | Necropolis | Wight, Barrow-wight, Necromancer |
| 5 | 12-15 | Wraith Domain | Shadow, Phantom, Nazgul |
| 6 | 15-18 | Inner Sanctum | Black Numenorean, Khamul |
| 7 | 18-20 | Pits of Despair | Sauron |

### 6.3 Monster Initialization

**File:** `scripts/entities/monster.gd`

`initialize_from_data(data: DataManager.MonsterData)` sets:
- Name, health (from dice), speed
- Evasion bonus, protection dice/sides
- Melee bonus (from first attack's bonus)
- Damage dice (from first attack)
- Monster flags (parsed bitflags -> boolean properties)
- AI initial state based on sleepiness

### 6.4 Monster AI

**File:** `scripts/entities/monster.gd`

- **Pathfinding:** A* via `Level.find_path()` with fallback to direct movement
- **Target tracking:** Last known player position
- **State transitions:** Based on alertness thresholds and LOS
- **Alertness decay:** Gradual return toward base alertness when player not visible

### 6.5 Monster Memory System

**File:** `scripts/systems/monster_memory.gd`

5 knowledge tiers based on observation count:

| Tier     | Observations | Info Revealed           |
|----------|-------------|------------------------|
| UNKNOWN  | 0           | "Unknown creature"     |
| IDENTIFIED| 1          | Name only              |
| BASIC    | 3           | HP, primary attack     |
| DETAILED | 5           | All attacks, resistances|
| COMPLETE | 10          | Full stats, all flags  |

Lore skill bonus: `effective_observations = base + lore_skill / 2`

### 6.6 What Is Missing from Monsters

- **Monster spells:** Parsed but not cast. No `SHRIEK`, `BOLT`, `BREATH` etc.
- **Special attack effects:** Most B: line effects beyond `HURT` and `POISON` are not applied (e.g., `FIRE`, `COLD`, `BLIND`, `CONFUSE`, `FEAR`, `STUN`).
- **Escort/group behavior:** `FRIENDS`, `ESCORT` flags parsed but no group spawning or escort logic.
- **Boss encounters:** Boss levels defined in LayerConfig but no special boss spawn logic (except Thrain at depth 15+).

---

## 7. Item Status

### 7.1 Data Source

**File:** `data/object.txt`

254 item entries. Sil-Q format with tval/sval system:
```
N:serial:&item name~
G:symbol:color
I:tval:sval:pval
W:depth:rarity:weight:cost
P:attack_bonus:damage_dice:evasion_bonus:protection_dice
A:depth/rarity pairs
F:flags
D:description
```

### 7.2 Item Categories (by tval)

| tval | Category        | Examples                           |
|------|-----------------|------------------------------------|
| 17   | Arrows          | Arrows (+0 to +3)                  |
| 19   | Bows            | Shortbow, Longbow, Great Bow       |
| 20   | Digging         | Shovel, Mattock                    |
| 21   | Hafted          | War Hammer, Quarterstaff           |
| 22   | Polearms        | Spear, Glaive, Great Axe           |
| 23   | Swords          | Dagger, Shortsword, Longsword      |
| 30   | Boots           | Boots, Greaves, Mithril Greaves    |
| 31   | Gloves          | Gloves, Gauntlets, Mithril Gauntlets|
| 32   | Helms           | Helm, Great Helm, Crown            |
| 34   | Shields         | Round Shield, Kite Shield          |
| 35   | Cloaks          | Cloak, Shadow Cloak                |
| 36   | Soft Armor      | Leather, Studded, Robe             |
| 37   | Mail            | Chain Mail, Mithril Corslet        |
| 39   | Light Sources   | Torch, Lantern, Lesser Jewel       |
| 40   | Amulets         | Various named amulets              |
| 45   | Rings           | Various named rings                |
| 55   | Staves          | Staff of Light, etc.               |
| 56   | Wands           | Wand of Frost, Fire, etc.          |
| 65   | Horns           | Horn of Blasting, etc.             |
| 66   | Scrolls         | Various scrolls                    |
| 75   | Potions         | Various potions                    |
| 80   | Food            | Dark Bread, Lembas                 |

### 7.3 Artifacts

**File:** `data/artefact.txt`

147 artifact entries:
- **Special (1-19):** Rings, Amulets, Light Sources, Crowns (Ring of Barahir, Vilya's Shard, etc.)
- **Normal (20-139):** Weapons and Armor (named unique items)
- **Quest (175-179):** Ring of Thrain, Key to Erebor
- **Smithing Templates (182-198):** For crafting system

### 7.4 Special Items

**File:** `data/special.txt`

~60 special item modifiers organized by category:
- Armor: of Protection, of Venom's End, of Resilience, of Stealth, of the Iron Hills, of the Ranger, of Gondor
- Shields: of Deflection, of Frost, with Many Runes
- Weapons: of Rivendell, of Gondolin, of Doriath, of Dragon-bane, of Final Rest, of Westernesse, of Mordor, of Murder, (Vampiric), (Poisoned), (Balanced), (Defender)
- Helms: of Brilliance, of Defiance, of True Sight, of Clarity, of Grace
- Cloaks: of Stealth, of Warmth, of the Traveller
- Bows: of Black Yew, of the Wild, of Radiance, of the Marchwardens, of the Galadhrim
- Boots: of Softest Tread, of Speed, of Leaping
- Gloves: of Archery, of Healing, of Swordplay

### 7.5 Equipment Slots

**File:** `scripts/core/constants.gd`

13 equipment slots:
```
WEAPON, OFF_HAND, BOW, QUIVER, HEAD, BODY, CLOAK,
HANDS, FEET, RING_L, RING_R, NECK, LIGHT
```

### 7.6 Item Sprites

**File:** `scripts/entities/item.gd`

Items on the ground render as sprites from the DCSS tileset. Atlas coordinates looked up via `TileMapper.get_item_coords()`.

### 7.7 What Is Missing from Items

- **Item identification system:** NOT IMPLEMENTED. All items are immediately known. No scrolls of identification, no "unknown" state.
- **Consumable usage:** Potions, food, herbs, scrolls, wands, staves, horns are in the data but no `use_item()` implementation for consumables.
- **Item durability/breakage:** No acid damage to equipment, no item destruction.
- **Special item generation:** `special.txt` modifiers are parsed by DataManager but unclear if the dungeon generator applies them to dropped items.
- **Flavor text system:** `flavor.txt` parsed but not used for unidentified item descriptions.
- **Archery ammunition:** Arrows defined but no ranged attack to use them.

---

## 8. Dungeon Generation

### 8.1 Algorithm

**File:** `scripts/systems/dungeon_generator.gd`

Room-and-corridor generation:
1. **Rooms:** Random placement with overlap checking, 100 attempts per room
2. **Corridors:** L-shaped connections between sequential rooms + random extra connections
3. **Vaults:** Template placement from `vault.txt` based on depth and layer
4. **Features:** Doors (30% at corridor junctions), rubble (depth>3), forges (every 4 levels)
5. **Stairs:** Up stairs placed first, down stairs placed far from up stairs
6. **Monsters:** 3+depth to 5+depth*2 (max 20), not within 5 tiles of stairs
7. **Items:** 2+depth/2 to 4+depth (max 15)

### 8.2 Level Dimensions

**File:** `scripts/systems/level.gd` lines 8-9

Default: 80 tiles wide x 40 tiles tall (5120x2560 pixels at 64px/tile)

### 8.3 Tile Types

**File:** `scripts/systems/level.gd` lines 22-35

```gdscript
enum Tile {
    VOID = 0, FLOOR = 1, WALL = 2,
    DOOR_CLOSED = 3, DOOR_OPEN = 4,
    STAIRS_DOWN = 5, STAIRS_UP = 6,
    CHASM = 7, RUBBLE = 8, FORGE = 9,
    TRAP = 10, TRAP_TRIGGERED = 11,
}
```

### 8.4 Layer-Specific Parameters

**File:** `scripts/systems/layer_config.gd`

Each of the 7 tiers defines:
- Room count range (min/max)
- Room size range (min/max width and height)
- Corridor width
- Vault placement chance
- Boss levels (depths 3, 6, 9, 12, 15, 18, 20)
- Entry messages and ambient messages

### 8.5 Vault Templates

**File:** `data/vault.txt`

96 vault entries across all layers:
- **N:1:** Gates of Dol Guldur (escape gauntlet, type 10)
- **N:10-29:** Layer 1 vaults
- **N:30-49:** Layer 2 vaults
- **N:50-69:** Layer 3 vaults
- **N:70-89:** Layer 4 vaults
- **N:90-109:** Layer 5 vaults
- **N:110-129:** Layer 6 vaults
- **N:130-149:** Layer 7 vaults
- **N:200-209:** Transition vaults
- **N:300-309:** Lesser vaults (type 7)
- **N:400-409:** Greater vaults (type 8)
- **N:450:** Sauron's Throne Room (type 9)

### 8.6 Trap System

**File:** `scripts/systems/level.gd` lines 116-154

```gdscript
# Trap damage: 1d4 + depth/3
var base_damage: int = randi_range(1, 4)
var depth_bonus: int = depth / 3
var total_damage: int = base_damage + depth_bonus

# Avoidance: 50% + Perception * 5%
var avoid_chance: int = 50
if entity.has_method("get_skill"):
    var perception: int = entity.get_skill(Constants.Skill.S_PER)
    avoid_chance += perception * 5
```

### 8.7 Terrain Data

**File:** `data/terrain.txt`

87 terrain types defined including:
- Basic: floor, walls, doors (open/closed/locked/jammed/warded)
- Special: forges (orc/shadow/Angdur with use counts), stairs (up/down/shafts)
- Traps: 13 visible trap types (weakened floor, jagged pit, poison spike, noxious fumes, etc.)
- Dol Guldur features: dark pool, morgul runes, shadow brazier, torture rack, prison bars, chains, bloodstain
- Layer 1: poison stream, tangled roots, vine floor, forest floor

### 8.8 What Is Missing from Dungeon Generation

- **Most terrain.txt terrain types not in Level.Tile enum:** Level only has 12 tile types. terrain.txt defines 87. Most special terrain (locked doors, trap variants, layer-specific features) are not generatable.
- **Vault monster/item spawning from templates:** Vault symbols like `o`, `O`, `T`, `M`, `*`, `&` are defined but unclear if the vault placement code actually spawns the appropriate monsters/items at those positions.
- **Boss rooms:** Boss levels noted in LayerConfig but no boss spawn or boss room generation logic beyond Thrain.
- **Level persistence:** Levels are regenerated on revisit; no level caching.

---

## 9. Special Systems

### 9.1 Quest System

**File:** `scripts/systems/quest_system.gd`

Two victory paths:

**Escape Path:**
1. Find Thrain II (depth >= 15)
2. Receive Ring of Thrain (dialogue node 2)
3. Receive Key to Erebor (dialogue node 3)
4. Ascend to depth 1 with both items

**Banishment Path:**
1. Collect 3 Rod of Istari pieces (depths 10, 15, 18)
2. Rod auto-assembles when all 3 collected
3. Reach Throne Room (depth 19-20)
4. Requirements: Lore >= 12, Will >= 10
5. Banishment check: `1d20 + will + lore/2` vs difficulty 25
6. Failure: half max HP damage

Score multipliers: Banishment = 3.5x, Escape = 2.0x

### 9.2 Smithing System

**File:** `scripts/systems/smithing_system.gd`

3 recipe types:
- **Weapon Enhancement:** Adds +1 damage die (e.g., "2d5" -> "3d5"). Requires smithing material.
- **Armor Enhancement:** Adds +1 protection die. Requires smithing material.
- **Reforge:** Creates random item at depth+2. Requires smithing >= 10.

Success chance: `smithing_skill * 5` (max 100%)

Materials identified by name substring matching ("mithril", "fragment", "ore", "metal", "salvage", "shard", "remnant").

### 9.3 Auto-Explore

**File:** `scripts/systems/auto_explore.gd`

BFS pathfinding to nearest unexplored tile adjacent to explored tile.

Stop conditions:
- Monster spotted in FOV
- Item found on floor
- Damage taken
- Reached stairs or forge
- Any key pressed
- No unexplored tiles reachable

### 9.4 Thrain II NPC

**File:** `scripts/entities/thrain_npc.gd`

6-node dialogue tree:
- Node 0: Introduction
- Node 1: Story
- Node 2: Gives Ring of Thrain (+2 attack, +2 evasion, RES_FIRE)
- Node 3: Gives Key to Erebor (+1 attack, +1 evasion)
- Node 4: Final words
- Node 5: Farewell

Spawns at depth >= 15 via `dungeon_generator.spawn_thrain_if_appropriate()`.

### 9.5 Save System

**File:** `scripts/systems/save_manager.gd`

- JSON serialization to `user://saves/slot_N.sav`
- **Permadeath mode enforced:** Save deleted on death
- Quick save/load removed (F5/F9 bindings removed)
- Full state serialization: player, level terrain, entities, game state

### 9.6 Run Statistics

**File:** `scripts/systems/run_stats.gd`

Tracks:
- Combat: enemies_killed, total_damage_dealt, biggest_hit, silent_kills, biggest_enemy_killed_name
- Stealth: enemies_avoided, times_detected, stealth_streak_max
- Exploration: max_depth_reached, stairs_descended, stairs_ascended, doors_closed
- Items: potions_quaffed, herbs_consumed
- Achievements: saw_sauron, found_thrain, killed_nazgul, stole_ring, escaped, necromancer_defeated
- Victory: victory_type, final_score

### 9.7 Epitaph Generator

**File:** `scripts/systems/epitaph_generator.gd`, `data/epitaphs.txt`

Priority-based epitaph selection:
1. Killed by Sauron (5 epitaphs)
2. Killed by Nazgul (5 epitaphs)
3. Stole the Ring (5 epitaphs)
4. Found Thrain (5 epitaphs)
5. Saw Sauron (5 epitaphs)
6. Long/short run (5 each)
7. Deep/shallow death (5 each)
8. High stealth/kills/pacifist (5 each)
9. Generic by tone: laconic, descriptive, ironic, bleak, aspirational, grim, heroic (8-10 each)

### 9.8 Score Calculation

**File:** `scripts/ui/death_screen.gd` lines 39-61, `scripts/ui/victory_screen.gd` lines 44-67

```
score = max(0, 100000 - turns)
    + max_depth * DEPTH_MULTIPLIER * race_challenge_factor
    + escape_bonus * challenge
    + victory_bonus * challenge
```

Race challenge factors defined in Constants for scoring balance.

---

## 10. UI Status

### 10.1 HUD

**File:** `scripts/ui/hud.gd`

- Health bar (color-coded: green > yellow > red by percentage)
- Depth label
- Turn counter
- Message log (RichTextLabel, max 50 messages, color-coded BBCode)
- Status effect icons (abbreviations: PSN, CNF, BLD, AFR, SLW, HST, INV, ENT)

### 10.2 Inventory Panel

**File:** `scripts/ui/inventory_panel.gd`

- 4x6 item grid (24 slots, max inventory 23)
- Paper doll equipment layout (3-column grid, 6 rows)
- 13 equipment slots with correct layout:
  ```
  [empty]  [HEAD]    [empty]
  [NECK]   [BODY]    [CLOAK]
  [WEAPON] [empty]   [OFF_HAND]
  [HANDS]  [empty]   [BOW]
  [RING_L] [FEET]    [RING_R]
  [LIGHT]  [empty]   [QUIVER]
  ```
- Item info panel showing attack, damage, evasion, protection, weight
- DCSS tileset icons for items
- Weight display
- Controls: E to equip, R to unequip, Shift+D to drop, right-click context menu

### 10.3 Skills Panel

**File:** `scripts/ui/skills_panel.gd`

- 8 skill rows with name, level, cost, buy button, progress bar
- XP display (available and total earned)
- Color coding: gold (level 10+), green (level 5+), normal
- Number keys 1-8 for quick purchase
- Skill descriptions on hover

### 10.4 Abilities Panel

**File:** `scripts/ui/abilities_panel.gd`

- Tab container with 8 skill tabs
- Ability list per skill with status icons (green check, yellow dot, gray circle, red X)
- Level requirement display
- Prerequisite checking
- XP cost: `(level_requirement + 1) * 300`
- Buy button with Learn/Learned states
- Learned abilities stored via `player.set_meta("learned_abilities", [])` (Godot metadata, not serialized in save)

### 10.5 Look Panel

**File:** `scripts/ui/look_panel.gd`

- Yellow border cursor sprite (generated procedurally)
- Full 8-directional cursor movement
- Entity info display:
  - Player: name, HP
  - Monster: Name (color by stance), HP bar, alertness state, stance/morale, speed/evasion/melee, protection, damage, trait flags
- Monster memory integration (progressive knowledge reveal)
- Item list at cursor position
- Terrain name display

### 10.6 Dialogue Panel

**File:** `scripts/ui/dialogue_panel.gd`

- Speaker name label
- RichTextLabel for dialogue text
- Enter/Space to advance, Escape to close
- Sets game state to DIALOGUE during conversation
- Triggers NPC `on_dialogue_complete()` callback
- Uses Node type to avoid cyclic dependency with NPC class

### 10.7 Smithing Panel

**File:** `scripts/ui/smithing_panel.gd`

- Recipe list (available + grayed unavailable)
- Item selection list (filtered by recipe type)
- Material selection list (searched by name substring)
- Info panel showing recipe details and selected items
- Success chance display
- Forge button with ready-state checking
- Quick forge with F key

### 10.8 Character Creation

**File:** `scripts/ui/character_creation.gd`

- 5-stage wizard: Race -> House -> Stats -> Name -> Confirm
- Race buttons with stat modifier display and trait flags
- House buttons filtered by race compatibility
- Stat allocation with +/- buttons, point budget, cost scaling
- Random name generator (18 Tolkien names hardcoded)
- Character summary with final stats preview
- Back/Next navigation

### 10.9 Death Screen

**File:** `scripts/ui/death_screen.gd`

- Epitaph display (from EpitaphGenerator)
- Character info (name, race, house, slain by, depth, turns)
- Combat stats (enemies slain, biggest kill, damage dealt, biggest hit, silent kills)
- Journey stats (max depth, stairs, enemies avoided, stealth streak, items used)
- Achievement list
- Final score
- Options: N (new game), Q (quit), S (save dump)
- Character dump export to `user://dumps/`
- **Note:** I (inventory), C (character sheet), M (message log) buttons show "not yet implemented"

### 10.10 Victory Screen

**File:** `scripts/ui/victory_screen.gd`

- Title varies: "THE NECROMANCER IS BANISHED!" (gold) or "YOU HAVE ESCAPED!" (green)
- Victory story text (prose paragraph per victory type)
- Same stat layout as death screen
- Victory dump export
- Skills included in player_data for dump

### 10.11 What Is Missing from UI

- **Minimap/automap:** No minimap display.
- **Character sheet panel:** Referenced on death screen but not implemented.
- **Message log review:** Death screen references it but "not yet implemented."
- **Post-death inventory view:** Referenced but "not yet implemented."

---

## 11. Input Bindings

### 11.1 Movement

**Source:** `project.godot` [input] section

| Action         | Keys                          |
|----------------|-------------------------------|
| move_up        | W, K, Up Arrow                |
| move_down      | S, J, Down Arrow              |
| move_left      | A, H, Left Arrow              |
| move_right     | D, L, Right Arrow             |
| move_up_left   | Y, Numpad 7                   |
| move_up_right  | U, Numpad 9                   |
| move_down_left | B, Numpad 1                   |
| move_down_right| N, Numpad 3                   |
| wait           | Period (.), Numpad 5           |

### 11.2 Actions

| Action       | Key(s)           | Handler              |
|--------------|------------------|----------------------|
| pickup       | G                | player.gd            |
| inventory    | I                | main.gd              |
| equip        | E                | inventory_panel.gd   |
| unequip      | R                | inventory_panel.gd   |
| drop         | Shift+D          | inventory_panel.gd   |
| skills       | Shift+2 (@)      | main.gd              |
| abilities    | A                | main.gd              |
| look         | X                | main.gd              |
| auto_explore | O                | main.gd              |
| forge        | F                | main.gd              |

### 11.3 Zoom

| Action    | Input              |
|-----------|--------------------|
| zoom_in   | Mouse Wheel Up     |
| zoom_out  | Mouse Wheel Down   |

Zoom levels: [0.5, 1.0, 1.5, 2.0, 3.0], default 2.0x (index 3)

### 11.4 UI Navigation

| Action    | Key(s)           |
|-----------|------------------|
| Close     | Escape           |
| Accept    | Enter, Space     |
| Navigate  | Arrow keys       |

### 11.5 Potential Conflicts

- **A key:** Bound to both `move_left` and `abilities`. The abilities binding uses physical_keycode 65 (A) without shift, same as move_left. This is handled by UI panel visibility checks -- abilities panel input only processes when panel is visible.
- **F key:** Forge action. Only triggers when on a forge tile with no panel open.

---

## 12. Known Issues & TODOs

### 12.1 Explicit TODOs in Code

| File | Line | TODO |
|------|------|------|
| `player.gd` | 194 | `TODO: Parse and combine protection dice properly` |
| `player.gd` | 542 | `TODO: Detect silent kills` |
| `constants.gd` | 164 | `DEFERRED: Deep Memory (ability 142)` |
| `constants.gd` | 169 | `DEFERRED: Inner Light (ability 147)` |
| `status_effects.gd` | 176 | `TODO: Check equipment for resistance flags` |
| `ability_system.gd` | 219 | `"Ability not implemented."` fallback message |
| `ability_system.gd` | 328 | `TODO: Reveal traps when trap system is implemented` |
| `ability_system.gd` | 398 | `TODO: Add sealed door flag to prevent monsters from opening` |
| `smithing_system.gd` | 106 | `TODO: Add forge_uses tracking to Level or use terrain data` |
| `death_screen.gd` | 175 | `TODO: Show final inventory` |
| `death_screen.gd` | 179 | `TODO: Show character sheet` |
| `death_screen.gd` | 183 | `TODO: Show message log` |

### 12.2 Deferred Abilities

- **142 Deep Memory:** Would gradually reveal map layout. Requires FOV system extension.
- **147 Inner Light:** Would increase light radius by lore_skill/5. Requires per-entity light system.

### 12.3 Unimplemented Subsystems

| System | Status | Notes |
|--------|--------|-------|
| Ranged Combat (Archery) | NOT IMPLEMENTED | Bow slot exists, arrows in data, no firing mechanic |
| Item Identification | NOT IMPLEMENTED | All items known immediately |
| Consumable Usage | NOT IMPLEMENTED | Potions, food, scrolls, wands defined but no use_item() |
| Monster Spells | NOT IMPLEMENTED | Spell data parsed, no casting AI |
| Most Attack Effects | PARTIAL | Only HURT and POISON resolved; FIRE, COLD, BLIND, CONFUSE, STUN, etc. not applied |
| Non-Lore Abilities | NOT IMPLEMENTED | Melee, Archery, Evasion, Stealth, Perception, Will, Smithing abilities defined in data but no gameplay code |
| Starting Equipment | NOT IMPLEMENTED | Race E: lines parsed but items not given to player |
| House Affinity | NOT IMPLEMENTED | Flags parsed but no skill bonuses applied |
| Weapon Proficiency | NOT IMPLEMENTED | Race flags parsed but not used in combat |
| Level Persistence | NOT IMPLEMENTED | Levels regenerate on revisit |
| Item Breakage/Durability | NOT IMPLEMENTED | No equipment degradation |
| Minimap | NOT IMPLEMENTED | No automap display |
| Equipment Resistance | NOT IMPLEMENTED | TODO in status_effects.gd |
| Floor-wide Alertness | NOT IMPLEMENTED | No global alarm system |
| Dynamic Lighting | NOT IMPLEMENTED | Single FOV source only |

### 12.4 Known Bugs / Warnings

- **RID leak on exit:** Cleanup issue, non-blocking
- **DataManager validation warnings:** Reports missing monsters/races due to naming mismatches between data files and expected IDs
- **Abilities panel uses Godot metadata:** `player.set_meta("learned_abilities", [])` is NOT serialized by the save system. Learned abilities would be lost on save/load.
- **tile_mapper_dcss.gd duplicate:** Near-identical copy of `tile_mapper.gd` with 4-space indentation instead of tabs. Redundant file.
- **Debug print statements:** `level.gd` lines 99-102 and 281-284 contain debug `print()` calls with a count limiter

### 12.5 Data File Summary

| File | Entries | Status |
|------|---------|--------|
| monster.txt | 77 | Fully parsed by DataManager |
| object.txt | 254 | Fully parsed by DataManager |
| artefact.txt | 147 | Fully parsed by DataManager |
| ability.txt | 93 | Fully parsed by DataManager |
| vault.txt | 96 | Parsed, placement logic exists |
| race.txt | 4 (3 playable + Istari debug) | Parsed, used in character creation |
| house.txt | 9 | Parsed, used in character creation |
| special.txt | ~60 | Parsed by DataManager |
| terrain.txt | 87 | Parsed but most types unused by Level.Tile |
| limits.txt | N/A | Array size limits (legacy Sil format) |
| epitaphs.txt | ~90 | Parsed by EpitaphGenerator |
| flavor.txt | ~50 | Parsed but unused (no identification system) |
| history.txt | ~60 | Parsed but unused (no history display) |
| names.txt | ~300 | Parsed but unused (random name uses hardcoded list) |

### 12.6 Architecture Notes

**Autoload Singletons** (loaded in order):
1. `LayerConfig` - Layer tier configuration
2. `GameManager` - Central game state
3. `EventBus` - Signal-based event system (30+ signals)
4. `DataManager` - All data file parsing
5. `TileMapper` - DCSS tileset coordinate lookup (294 tiles mapped)

**Rendering:**
- DCSS tileset: 2048x2048 PNG, 32x32 tiles scaled to 64x64
- Nearest-neighbor filtering (pixel art)
- Magenta transparency shader for tile sprites
- Layer tint shader for depth theming
- 5 render layers: terrain, items, entities, effects, ui

**Scene Structure:**
- `main.tscn` -> Main script instantiates Level, HUD, all UI panels
- Level contains: TerrainLayer (TileMapLayer), Entities (Node2D), Items (Node2D), Effects (Node2D)
- 7 test files exist under `tests/` using GUT framework

---

## Implementation Completeness Summary

### Fully Working
- Turn system with energy-based actions
- 8-directional movement with WASD/HJKL/arrows/diagonals
- Sil-Q opposed d20 combat (melee only)
- Protection dice damage reduction
- Critical hit system with weapon weight
- FOV with layer-specific radius
- Dungeon generation with rooms, corridors, doors, stairs
- Monster AI (idle/wandering/hunting/fleeing)
- Alertness/morale/stance system
- Character creation (race/house/stats/name)
- XP-as-currency skill system
- 12/14 Lore abilities with voice charge system
- Quest system (2 victory paths)
- Smithing at forges
- Auto-explore
- Monster memory (5 tiers)
- Trap system
- Inventory with paper doll equipment
- Save/load with permadeath
- Death/victory screens with epitaphs
- Damage floaters
- DCSS tileset integration (294 tiles)
- Look mode (X key)

### Partially Working
- Status effects (application works, equipment resistance checking missing)
- Monster attacks (basic HURT/POISON work, special effects not applied)
- Item system (equipping/dropping works, no consumables)

### Not Implemented
- Ranged combat (archery)
- Item identification
- Consumable items (potions, food, scrolls, wands, horns)
- Monster spells
- Non-Lore abilities (68 of 93 abilities)
- Starting equipment from race data
- House affinity bonuses
- Weapon proficiency bonuses
- Dynamic lighting / per-entity light
- Level persistence
- Floor-wide alertness
- Minimap
