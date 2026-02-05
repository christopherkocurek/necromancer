# The Necromancer -- Design Canon

**Authoritative ledger of every mechanic in the canonical C implementation.**

This document is the single source of truth for The Necromancer's game systems as
they exist in the original C codebase. Every formula, constant, and table recorded
here was extracted directly from the source files (`cmd1.c`, `melee1.c`, `melee2.c`,
`dungeon.c`, `defines.h`, and the associated data files). Any Godot reimplementation
must reproduce the behaviour described below unless a deviation is explicitly noted
and justified elsewhere.

---

## Table of Contents

1. [Combat System](#1-combat-system)
2. [Stealth & Detection System](#2-stealth--detection-system)
3. [FOV & Light System](#3-fov--light-system)
4. [Skill System](#4-skill-system)
5. [Character Creation](#5-character-creation)
6. [Monsters](#6-monsters)
7. [Items & Equipment](#7-items--equipment)
8. [Dungeon Generation](#8-dungeon-generation)
9. [Special Systems](#9-special-systems)
10. [Controls & UI](#10-controls--ui)

---

## 1. Combat System

Source: `cmd1.c`, `melee1.c`

### 1.1 Hit Resolution

All attacks resolve through opposed d20 rolls:

```
attack_score  = d20 + att
evasion_score = d20 + evn
result        = attack_score - evasion_score
```

| Result | Outcome |
|--------|---------|
| > 0    | HIT     |
| <= 0   | MISS    |

**Curse penalty:** the cursed side rolls the d20 twice and takes the **minimum**.

### 1.2 Player Attack Modifiers

Function: `total_player_attack` (`cmd1.c:857`)

Base value: `weapon_plus + melee_skill`

| Modifier | Source | Effect |
|----------|--------|--------|
| Concentration | `PER_CONCENTRATION` ability | +MIN(consecutive_attacks, Perception / 2) |
| Focused Attack | `PER_FOCUSED_ATTACK` ability | +Perception / 2 (one-shot, consumed on use) |
| Bane | Kill-count tracking | +1 per doubling of kills of that race (2 = +1, 4 = +2, 8 = +3, ...) -- logarithmic via `bane_bonus(m_ptr)` |
| Master Hunter | `PER_MASTER_HUNTER` ability | +MIN(pkills_of_this_race, Perception / 2) |
| Assassination | `STL_ASSASSINATION` ability | +Stealth_skill (only when target alertness < ALERTNESS_ALERT) |
| Distance | Ranged attacks | -(distance / 5) (integer division) |
| Blind | Cannot see target | att / 2 |
| Pit / Web | Player is in a pit or web | att / 2 |
| Charge | First blow of a charge | +3 |

Halvings (blind, pit/web) stack multiplicatively.

### 1.3 Monster Attack Modifiers

Function: `total_monster_attack` (`cmd1.c:937`)

Base value: per-attack `att` from `r_info`

| Modifier | Condition | Effect |
|----------|-----------|--------|
| Stunned | Monster is stunned | -2 |
| Light Sensitivity | `RF3_HURT_LITE` flag | -(cave_light - 2) |
| Overwhelming (Flanking) | Multiple attackers in LOS | +1 per side monster, +2 per rear monster (max +10). Halved if player has Crowd Fighting. |
| Distance | Ranged attacks | -(distance / 5) |
| Elf-Bane | `RF2_ELFBANE` vs Elf player | +5 |
| Blind | Cannot see player | att / 2 |
| Charge | First blow of a charge | +3 to attack **and** +3 to damage sides |

### 1.4 Player Evasion Modifiers

Function: `total_player_evasion` (`cmd1.c:900`)

Base value: `skill_use[S_EVN]`

| Modifier | Condition | Effect |
|----------|-----------|--------|
| Dodging | `EVN_DODGING` + moved last turn | +3 |
| Bane | Kill-count tracking | +bane_bonus(m_ptr) |
| Blind | Cannot see attacker | evn / 2 |
| Target of Archery | Being shot at | evn / 2 |
| Pit / Web | Player is in a pit or web | evn / 2 |

Halvings stack multiplicatively.

### 1.5 Monster Evasion Modifiers

Function: `total_monster_evasion` (`cmd1.c:981`)

Base value: `r_ptr->evn`

| Modifier | Condition | Effect |
|----------|-----------|--------|
| Stunned | Monster is stunned | -2 |
| Light Sensitivity | `RF3_HURT_LITE` | -(cave_light - 2) |
| Blind | Cannot see player | evn / 2 |
| Unwary | alertness < 0 | evn / 2 |
| Target of Archery | Being shot at | evn / 2 |
| Sleeping | alertness < -10 | evn = **-5** (overrides all other modifiers) |

### 1.6 Critical Hit Formula

Function: `crit_bonus` (`cmd1.c:1184`)

```
base_threshold  = 70
if Finesse:   threshold -= 20
if Control:   threshold -= 20
if Power:     threshold += 10

crit_bonus_dice = (hit_result * 10 + 4) / (threshold + weight)
```

- `weight` = weapon weight in 0.1 lb units (e.g., a 3.0 lb weapon = 30).
- For monster attacks: `weight = 20 * dd`.
- `RES_CRIT` flag: halves crit bonus dice.
- `NO_CRIT` flag: zeroes crit bonus dice entirely.

### 1.7 Damage Calculation

**Player damage:**

```
total_dice = weapon_dd + slay_bonus + crit_bonus_dice
dam        = damroll(total_dice, weapon_ds)
net        = MAX(dam - protection_roll, 0)
```

**`damroll(n, s)`** = sum of `n` dice each rolling 1..s.

### 1.8 Protection Rolls

Function: `protection_roll` (`melee1.c:88`)

```
prt = SUM over each armour piece of damroll(pd, ps)
```

**Shield special rules:**

```
shield_prt = damroll(pd * mult, ps)
  where mult = 2 if Blocking is active, else 1
```

Blocking is active when:
- Player has `EVN_BLOCKING` ability, **and**
- Player did **not** move on their last turn.

**Heavy Armour Use:**

```
heavy_prt = damroll(1, armour_weight / 150)
```

This is added on top of the shield/armour rolls.

**Net damage:**

```
net = MAX(dam - prt, 0)
```

### 1.9 Skill Check Formula

Function: `skill_check` (`cmd1.c:721`)

```
d10 + skill  vs  d10 + difficulty
result > 0 = success
```

Modifiers that apply to skill checks:
- Bane bonus (player side)
- Elf-bane bonus (monster side, vs Elf player)
- Curse: worst of two d10 rolls on the cursed side

---

## 2. Stealth & Detection System

Source: `melee2.c`, `dungeon.c`, `defines.h`

### 2.1 Alertness Scale

Constants from `defines.h:2104`:

| Constant | Value | Meaning |
|----------|-------|---------|
| `ALERTNESS_MIN` | -20 | Deepest sleep |
| `ALERTNESS_UNWARY` | -10 | Below this = sleeping |
| `ALERTNESS_ALERT` | 0 | Fully aware, will engage |
| `ALERTNESS_QUITE_ALERT` | 5 | Heightened awareness |
| `ALERTNESS_VERY_ALERT` | 10 | Actively hunting |
| `ALERTNESS_MAX` | 20 | Maximum alertness |

Monsters with alertness < -10 are **sleeping** and receive severe evasion penalties
(evn overridden to -5). Monsters with alertness < 0 are **unwary** (evn halved).

### 2.2 Stealth Score Per Turn

```
stealth_score = skill_use[S_STL]
```

Situational reductions:

| Action | Penalty |
|--------|---------|
| Opening/closing doors | -5 |
| Tunnelling / digging | -10 |
| Throwing items | -noise (item-dependent) |
| Smithing at a forge | -10 |
| Stealth mode active | +5 (bonus, not penalty) |

The constant `STEALTH_MODE_BONUS = +5`.

### 2.3 Monster Perception Check

Function: `monster_perception` (`melee2.c:6008`)

Evaluated once per monster per player turn:

```
difficulty_roll = stealth_score + d10

m_perception = monster_skill(S_PER)
             - noise_distance
             + combat_noise_bonus
             - bane_bonus
             + elf_bane_bonus
             + 5 * (is_escaping)
             + alertness * (if already alert)
             + aggravate * 10
             + open_squares_in_LOS (halved by Disguise ability)

perception_roll = m_perception + d10

result = perception_roll - difficulty_roll
if result > 0:
    monster.alertness += result
```

### 2.4 Combat Noise

Combat generates additive noise bonuses to monster perception:

| Event | Bonus |
|-------|-------|
| Player attacked a monster this turn | +2 |
| Player was attacked this turn | +2 |
| Both | +4 (stacks) |

### 2.5 Stealth Abilities

| Ability | Effect |
|---------|--------|
| Assassination (`STL_ASSASSINATION`) | +Stealth_skill to melee attack when target alertness < ALERTNESS_ALERT |
| Throat Slit | Suppresses combat noise on kill (humanoids only) |
| Silent Kill | Suppresses combat noise on kill (any enemy type) |
| Fade | Killing an unwary enemy grants 2 turns of invisibility |
| Disguise | Halves the open_squares_in_LOS contribution to monster perception |

---

## 3. FOV & Light System

### 3.1 Field of View

The C implementation uses a standard recursive shadowcasting algorithm for
field-of-view calculation. Key properties:

- FOV recalculates each turn and whenever the player moves.
- Walls block LOS. Doors block LOS when closed.
- The player's light radius determines how far they can see in unlit areas.
- Lit dungeon squares (torches, glowing features) are visible if in LOS regardless
  of player light radius.

### 3.2 Light and Darkness

- `cave_light` tracks the ambient light level of each tile.
- Player light sources (torches, lanterns, the Light staff) illuminate a radius.
- Monsters with `RF3_HURT_LITE` take penalties in bright light:
  `-(cave_light - 2)` to both attack and evasion.
- Dark areas outside the player's light radius are not visible even if geometrically
  in LOS.
- Some dungeon features (shadow braziers, morgul runes) emit negative light or
  interact with the light system.

### 3.3 Visibility and Combat

- **Cannot see target:** attack and evasion are both halved.
- **Sleeping monsters** (alertness < -10): evasion overridden to -5.
- **Unwary monsters** (alertness < 0): evasion halved.
- These stack with blindness halvings multiplicatively.

---

## 4. Skill System

### 4.1 Skill List

There are 8 primary skills, each with an associated ability tree:

| Skill | Code | Primary Stat | Role |
|-------|------|-------------|------|
| Melee | `S_MEL` | STR | Weapon attack bonus |
| Archery | `S_ARC` | DEX | Ranged attack bonus |
| Evasion | `S_EVN` | DEX | Defence / dodge |
| Stealth | `S_STL` | DEX | Sneaking, assassination |
| Perception | `S_PER` | GRA | Detection, concentration |
| Will | `S_WIL` | GRA | Mental resistance, song |
| Smithing | `S_SMT` | GRA | Crafting at forges |
| Lore | `S_LOR` | GRA | Monster knowledge, banishment |

### 4.2 Ability Counts Per Skill Tree

| Tree | Count |
|------|-------|
| Melee | 14 |
| Archery | 9 |
| Evasion | 11 |
| Stealth | 12 |
| Perception | 10 |
| Will | 11 |
| Smithing | 12 |
| Lore | 14 |
| **Total** | **93** |

### 4.3 XP and Advancement

- **XP Multiplier:** 130 (i.e., 1.3x the standard Sil-Q rate).
- Difficulty mode multipliers:

| Mode | Multiplier |
|------|-----------|
| Easy | 150 |
| Standard | 130 |
| Challenge | 100 |
| Hardcore | 80 |

### 4.4 Skill Check Formula

See [Section 1.9](#19-skill-check-formula) for the opposed d10 formula.

---

## 5. Character Creation

### 5.1 Playable Races

| Race | STR | DEX | CON | GRA | Stat Total | Proficiency | Notes |
|------|-----|-----|-----|-----|-----------|-------------|-------|
| Elf | -1 | +2 | +1 | +2 | +4 | Bow | -- |
| Man | +1 | 0 | +1 | 0 | +2 | Sword | -- |
| Dwarf | +1 | -1 | +3 | 0 | +3 | Axe | `ARC_PENALTY` (archery penalty) |
| Istari | +10 | +10 | +10 | +10 | +40 | All | **Debug race only** |

### 5.2 Houses

Each house belongs to exactly one race and provides a skill affinity and a stat bonus.

| House | Race | Skill Affinity | Stat Bonus |
|-------|------|----------------|------------|
| Lothlorien | Elf | Lore | GRA +1 |
| Rivendell | Elf | Smithing | CON +1 |
| Greenwood | Elf | Stealth | DEX +1 |
| Dunedain | Man | Perception | DEX +1, GRA +1 |
| Rohan | Man | Evasion | STR +1 |
| Gondor | Man | Melee | CON +1 |
| Khazad-dum | Dwarf | Lore | GRA +1 |
| Erebor | Dwarf | Smithing | CON +1 |
| Iron Hills | Dwarf | Melee | STR +1 |

### 5.3 Starting Equipment

Starting equipment is determined by race proficiency and house. This is defined in
the data files and varies per combination. All characters begin at dungeon depth 1.

---

## 6. Monsters

### 6.1 Population Summary

| Category | Count |
|----------|-------|
| Combat monsters | 55 |
| Hallucinatory images | 10 |
| **Total entries** | **65** |

### 6.2 Monsters by Dungeon Layer

| Layer | Depths | Regular | Bosses | Uniques | Total |
|-------|--------|---------|--------|---------|-------|
| 1 -- Forest Breach | 1-3 | 12 | 1 (Broodmother) | -- | 13 |
| 2 -- Orc Warrens | 3-6 | 10 | 1 (Orc Warchief) | 1 (Gashnak) | 12 |
| 3 -- Torture Halls | 6-9 | 10 | 1 (Master Sorcerer) | 1 (Karvag) | 12 |
| 4 -- Necropolis | 9-12 | 9 | -- | 1 (Grishnakh, unique/boss) | 10 |
| 5 -- Wraith Domain | 12-15 | 9 | 1 (Uvatha) | 1 (Wailing Horror) | 11 |
| 6 -- Inner Sanctum | 15-18 | 8 | 1 (Khamul) | -- | 9 |
| 7 -- Pits of Despair | 18-20 | 5 | 1 (Sauron, final boss) | 1 (Thrain's Shade, NPC) | 7 |

### 6.3 Hallucinatory Images

These appear during hallucination effects (Ring of Thrain curse, potions, etc.)
and are not real combatants:

Gandalf, Thranduil, Galadriel, Elrond, Thorin, Beorn, Radagast, Eagle, Elk, Ent

### 6.4 Monster Flags of Note

| Flag | Effect |
|------|--------|
| `RF3_HURT_LITE` | Takes light-based attack/evasion penalties |
| `RF2_ELFBANE` | +5 attack vs Elf players |
| `RES_CRIT` | Halves critical hit bonus dice against this monster |
| `NO_CRIT` | Immune to critical hits entirely |

### 6.5 Monster Speed & Energy

Inherited from Sil-Q. Each monster has a speed value that indexes into
`ENERGY_TABLE[speed]` to determine energy gained per game tick. A monster
acts when accumulated energy >= `ACTION_COST` (100).

---

## 7. Items & Equipment

### 7.1 Item Counts by Category

| Category | Subcategory | Count |
|----------|-------------|-------|
| **Weapons** | Swords | 8 |
| | Polearms | 7 |
| | Hafted | 2 |
| | Digging | 2 |
| | Bows | 3 |
| | Arrows | 1 |
| **Armour** | Soft Armour | 4 |
| | Mail | 3 |
| | Shields | 3 |
| | Helms | 5 |
| | Boots | 3 |
| | Cloaks | 4 |
| | Gloves | 3 |
| **Staves** | -- | 17 |
| **Wands** | -- | 6 |
| **Horns** | -- | 6 |
| **Potions** | -- | 22 |
| **Herbs / Food** | -- | 18 |
| **Rings** | -- | 14 |
| **Amulets** | -- | 8 |
| **Artifacts** | (excl. smithing templates) | ~127 |
| **Quest Items** | -- | 7 |
| **Discovery XP Items** | -- | 38 |
| **Tutorial Notes** | -- | 38 |

### 7.2 Staves

Staves are activatable items with powerful effects:

Imprisonment, Freedom, Light, Sanctity, Understanding, and 12 others (17 total).

### 7.3 Wands

| Wand | Effect |
|------|--------|
| Frost | Cold damage bolt |
| Fire | Fire damage bolt |
| Slowing | Slows target |
| Light | Illuminates area |
| Fear | Causes fear |
| Sleep | Puts target to sleep |

### 7.4 Horns

| Horn | Effect |
|------|--------|
| Terror | Area-of-effect fear |
| Thunder | Sonic damage |
| Force | Knockback |
| Blasting | Destructive blast |
| Challenge | Aggro / taunt |
| Fairy Flute | Special (charm-like) |

### 7.5 Quest Items

| Item | Role |
|------|------|
| Ring of Thrain (4 variants) | Cursed ring, required for Escape victory |
| Key to Erebor | Obtained from Thrain, required for Escape victory |
| Map of Erebor | Navigation aid |
| Rod of Istari (3 pieces) | Assembled for Banishment victory |

### 7.6 Discovery XP Items

38 items across 6 tiers: Memories, Fragments, Glyphs, Shards, Relics, Records.
Finding and identifying these grants experience points as a non-combat advancement
path.

### 7.7 Protection Mechanics

See [Section 1.8](#18-protection-rolls) for the full protection roll formula
including shield blocking and heavy armour use.

---

## 8. Dungeon Generation

### 8.1 Layer Structure

The dungeon spans 20 depths across 7 thematic layers:

| Layer | Depths | Name | Theme / Flavour |
|-------|--------|------|-----------------|
| 1 | 1-3 | Forest Breach | Spiders, bats, orc scouts |
| 2 | 3-6 | Orc Warrens | Orcs, wargs, forges |
| 3 | 6-9 | Torture Halls | Sorcerers, ghouls, cells, torture racks |
| 4 | 9-12 | Necropolis | Undead, crypts |
| 5 | 12-15 | Wraith Domain | Phantoms, shadows |
| 6 | 15-18 | Inner Sanctum | Black Numenoreans, Khamul |
| 7 | 18-20 | Pits of Despair | Sauron, Thrain |

Note that layers overlap at boundary depths (e.g., depth 3 may draw from both
Layer 1 and Layer 2 content).

### 8.2 Terrain Types

**Total: 87 terrain types**

| Category | Count | Examples |
|----------|-------|---------|
| Traps | 13 | Pit trap, alarm trap, web trap, etc. |
| Doors | 24 | Open, closed, locked, jammed, secret, etc. |
| Forges | 16 | 3 types (Orc, Shadow, Angdur) x multiple use-count entries |
| Stairs | 4 | Up, down, sealed up, sealed down |
| Special features | Various | Dark pool, morgul runes, shadow brazier, torture rack, prison bars, chains |

### 8.3 Vault Templates

**Total: 96 vault templates**

| Template Range | Purpose |
|----------------|---------|
| N:1 | Gates of Dol Guldur (entrance) |
| N:10-29 | Layer 1 vaults |
| N:30-49 | Layer 2 vaults |
| N:50-69 | Layer 3 vaults |
| N:70-89 | Layer 4 vaults |
| N:90-109 | Layer 5 vaults |
| N:110-129 | Layer 6 vaults |
| N:130-149 | Layer 7 vaults |
| N:200-209 | Transition vaults (between layers) |
| N:300-309 | Lesser vaults (generic) |
| N:400-409 | Greater vaults (generic) |
| N:450 | Sauron's Throne Room |

### 8.4 Forge Types

| Forge | Uses | Availability |
|-------|------|-------------|
| Orc Forge | 5 | Layers 2+ |
| Shadow Forge | 5 | Layers 3+ |
| Angdur Forge | 3 | Unique placement |

### 8.5 Door Mechanics

- **Open:** Walk into a closed door to open it.
- **Close:** Close a door behind you (manual action).
- **Lock:** Doors auto-lock at floor alertness 11+.
- **Unlock:** Word of Opening ability or breaking down the door.

---

## 9. Special Systems

### 9.1 Victory Conditions

There are two distinct paths to victory:

#### Escape Victory

1. Descend to depth 20.
2. Find Thrain's Shade.
3. Receive the Ring of Thrain and the Key to Erebor.
4. This triggers **Pursuit Mode** (see below).
5. Ascend back to the surface (depth 0) alive.

#### Banishment Victory

1. Find and assemble the three pieces of the Rod of Istari.
2. Reach Sauron's Throne (vault N:450).
3. Requirements: Lore >= 12 **and** Will >= 10.
4. Perform a contested Will check against Sauron.
5. Success banishes Sauron. **No pursuit phase** -- the game ends in victory.

### 9.2 Pursuit Mode

Triggered by the Escape Victory path. Six sequential phases:

| Phase | Name | Effect |
|-------|------|--------|
| 1 | Sauron Awakens | Sauron becomes active; all monsters alerted |
| 2 | Dungeon Shifts | Level layouts may change or become more hostile |
| 3 | Locked Exits | Some stairs are sealed; alternate routes required |
| 4 | The Chase | Increased monster spawns, Sauron tracks the player |
| 5 | Collapse | Dungeon begins collapsing; timed escape pressure |
| 6 | Shortcuts Open | Previously sealed paths open to allow escape |

### 9.3 Floor-wide Alertness

A global per-floor value (0-100+) that affects dungeon behaviour:

| Range | State | Effects |
|-------|-------|---------|
| 0-10 | Normal | Standard patrols |
| 11-25 | Increased | Extra patrols, doors lock automatically |
| 26-50 | Ambushes | Monsters set ambushes, reinforcements arrive |
| 50+ | Full Alert | Maximum hostility, all monsters aware |

**Alertness triggers:**

| Event | Increase |
|-------|----------|
| Combat (general) | +1 to +3 |
| Crebain escape (scout bird) | +5 |
| Alarm trap triggered | +10 |
| Prisoner rescue | Varies by prisoner type |

### 9.4 The Lidless Eye

- **Availability:** Layer 4+ only (depth 9+).
- Triggers a Will check approximately every ~20 turns.
- **Failure:** Sauron's attention focuses on the player; enemies are dispatched
  to the player's location.

### 9.5 Morgul-Wound

- Inflicted by Nazgul attacks (chance-based).
- **Effect:** Permanent -2 to **all four** base stats (STR, DEX, CON, GRA).
- **Cure:** Special items (Athelas herb, etc.) or Lore skill at 14+.

### 9.6 Ring of Thrain Curse

The Ring of Thrain provides powerful bonuses but at a steep cost:

| Benefit | Value |
|---------|-------|
| Will bonus | +3 |
| Smithing bonus | +2 |

| Drawback | Description |
|----------|-------------|
| Gold hallucinations | Player sees illusory gold piles |
| Will checks | Periodic Will saves required |
| Compulsion | Failure compels player to move toward fake gold |
| Hallucinatory monsters | See [Section 6.3](#63-hallucinatory-images) |

### 9.7 NPCs and Prisoners

Six prisoner types can be found and rescued in the dungeon, plus the critical
endgame NPC:

| NPC | Reward | Alertness Cost |
|-----|--------|---------------|
| Captured Ranger | Map information (reveals dungeon area) | +5 |
| Elven Scout | Lore hint (monster/item knowledge) | +3 |
| Dwarf Smith | Free repair at next forge | +5 |
| Gondorian Soldier | Allied combatant for 3 floors | +8 |
| Tortured Wretch | Carries a valuable item | +2 |
| Mad Prophet | Hints about Sauron / endgame | +0 |
| **Thrain II** | Ring of Thrain + Key to Erebor (depth 20 only) | N/A (dies inevitably) |

### 9.8 Smithing System

#### Forge Types

See [Section 8.4](#84-forge-types).

#### Smithing Abilities

| Ability | Description |
|---------|-------------|
| Weaponsmith | Craft weapons |
| Armoursmith | Craft armour |
| Jeweller | Craft rings and amulets |
| Reforge | Improve existing items |
| Reclaim | Salvage materials from items |
| Masterwork | Create superior-quality items |
| Expertise | Improved crafting success rate |
| Salvage | Extract components from dungeon features |

Success chance for smithing: `skill * 5%` (e.g., Smithing 10 = 50% success).

### 9.9 Energy and Speed System

Inherited directly from Sil-Q:

- Each entity has a `speed` value.
- `ENERGY_TABLE[speed]` determines energy gained per game tick.
- An entity may act when accumulated energy >= `ACTION_COST` (100).
- After acting, `ACTION_COST` is subtracted from the entity's energy pool.
- Faster entities accumulate energy more quickly and therefore act more often.

### 9.10 Running

- Activated with Shift + direction key.
- The character moves continuously in the given direction.
- **Stops at:** enemies in LOS, intersections, obstacles, interesting features.
- **Generates more noise** than single-step movement.

---

## 10. Controls & UI

### 10.1 Movement

| Input | Action |
|-------|--------|
| Numpad / vi-keys (hjklyubn) | Move in 8 directions |
| Arrow keys | Move in 4 cardinal directions |
| Shift + direction | Run (continuous movement) |
| `.` or Numpad 5 | Wait one turn |

### 10.2 Combat

| Key | Action |
|-----|--------|
| Direction toward enemy | Melee attack |
| `f` | Fire ranged weapon |
| `t` | Throw item |

### 10.3 Inventory & Equipment

| Key | Action |
|-----|--------|
| `i` | View inventory |
| `e` | View equipment |
| `d` | Drop item |
| `w` | Wield weapon |
| `W` | Wear armour |
| `T` | Take off / unequip |
| `g` or `,` | Pick up item |

### 10.4 Item Use

| Key | Action |
|-----|--------|
| `a` | Activate (staff, horn, etc.) |
| `q` | Quaff potion |
| `r` | Read scroll |
| `E` | Eat food / herb |

### 10.5 Abilities

| Key | Action |
|-----|--------|
| `m` | View / use abilities |
| `A` | Toggle auto-use for an ability |

### 10.6 Information

| Key | Action |
|-----|--------|
| `C` | Character sheet |
| `@` | Detailed character info |
| `%` | Knowledge screen |
| `~` | Monster memory |
| `M` | Full dungeon map |
| `L` | Look mode (inspect tile) |

### 10.7 System

| Key | Action |
|-----|--------|
| Ctrl+S | Save game |
| Ctrl+Q | Quit |
| Ctrl+X | Suicide (permadeath) |

---

## Appendix A: Formula Quick Reference

| Formula | Expression | Source |
|---------|-----------|--------|
| Hit resolution | `(d20 + att) - (d20 + evn) > 0` | `cmd1.c` |
| Skill check | `(d10 + skill) - (d10 + difficulty) > 0` | `cmd1.c:721` |
| Crit bonus dice | `(hit_result * 10 + 4) / (crit_threshold + weight)` | `cmd1.c:1184` |
| Damage | `damroll(dd + slay + crit, ds)` | `cmd1.c` |
| Protection | `SUM(damroll(pd, ps)) + shield + heavy_armour` | `melee1.c:88` |
| Net damage | `MAX(damage - protection, 0)` | `melee1.c` |
| Bane bonus | `floor(log2(kills))` for kills >= 2 | `cmd1.c` |
| Smithing success | `skill * 5` percent | GDD |
| Stealth check | `(stealth_score + d10) vs (monster_perception + d10)` | `melee2.c:6008` |

## Appendix B: Key Constants

| Constant | Value | Location |
|----------|-------|----------|
| `ALERTNESS_MIN` | -20 | `defines.h:2104` |
| `ALERTNESS_UNWARY` | -10 | `defines.h` |
| `ALERTNESS_ALERT` | 0 | `defines.h` |
| `ALERTNESS_QUITE_ALERT` | 5 | `defines.h` |
| `ALERTNESS_VERY_ALERT` | 10 | `defines.h` |
| `ALERTNESS_MAX` | 20 | `defines.h` |
| `ACTION_COST` | 100 | Sil-Q engine |
| `STEALTH_MODE_BONUS` | +5 | `melee2.c` |
| `XP_MULTIPLIER` (Standard) | 130 | GDD |
| `CRIT_BASE_THRESHOLD` | 70 | `cmd1.c:1184` |

---

*Document generated from canonical C source analysis. Last updated: 2026-02-05.*
