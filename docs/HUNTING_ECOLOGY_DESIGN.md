# Hunting Ecology Design Document

## The Problem

Hunting (Perception in Sil-Q) is the weakest skill tree in The Necromancer. While Melee gives
you power to kill, Evasion keeps you alive, Stealth lets you bypass threats, and Lore offers
versatile utility — Hunting is a "tax" skill. You invest XP to avoid bad things (traps, ambushes)
rather than to gain good things (kills, loot, tactical advantage). A player who ignores Hunting
entirely suffers occasional trap damage; a player who invests heavily in it gets... slightly less
trap damage. The reward curve is flat and the skill feels passive.

This document proposes a Hunting Ecology — a set of interlocking systems that make Hunting feel
as rewarding and strategically interesting as any other skill tree. The guiding principle is
**wilderness mastery**: a Hunting-focused character should feel like Aragorn the Ranger — reading
the land, sensing danger before it arrives, striking with precision born from patience, and finding
paths that others miss.

---

## 1. Current State Audit

### 1.1 What Hunting Currently Does

The Perception skill (internal name `S_PER`, key `"perception"`) has the following mechanical
touchpoints in the current codebase:

| Mechanic | Location | Formula | Impact |
|---|---|---|---|
| Trap avoidance | `level.gd:_trigger_trap()` | `50 + perception * 5`% chance to step over | Defensive only |
| Secret door search | `level.gd:search_for_secrets()` | `20 + perception * 10`% per adjacent tile | Requires Shift+S action |
| Focused Attack | `player.gd:get_total_attack()` | `+perception / 2` to melee attack | Always-on if learned |
| Concentration | `player.gd:get_total_attack()` | `+min(consecutive_attacks, perception / 2)` | Requires standing still |
| Keen Senses | `player.gd:get_light_radius()` | `+1` light radius | Flat bonus |
| Keen Eyes (Archery) | `player.gd:ranged_attack()` | `+perception / 2` to ranged attack | Always-on if learned |
| Bane | `player.gd:_get_bane_bonus()` | `+floor(log2(kills))` vs killed species | Attack + evasion |
| Master Hunter | `player.gd:_get_master_hunter_bonus()` | `+min(kills, perception / 2)` attack | Scales with kills |
| Monster memory | `monster_memory.gd` | Lore-based (not Perception-based) | Observation count system |
| Equipment bonuses | `player.gd:_apply_equipment_flags()` | Items can grant `PERCEPTION` flag | Passive skill bump |

### 1.2 Current Ability Tree (10 Abilities)

| # | Name | Level | Prereqs | Effect | Implemented? |
|---|---|---|---|---|---|
| 0 | Natural Talent | 1 | None | Bypass prerequisites for other abilities | Yes |
| 1 | Focused Attack | 2 | None | +Perception/2 to melee after passing a turn | Partially (always on, not gated to passing) |
| 2 | Keen Senses | 3 | None | +5 to spot invisible, +1 light radius | Light radius only |
| 3 | Concentration | 4 | None | +consecutive attacks (capped at Per/2) when stationary | Yes |
| 4 | Alchemy | 5 | None | Identify all herbs/potions, combine herbs | Not implemented |
| 5 | Bane | 6 | None | +log2(kills) vs selected enemy category | Yes (all types, not selected) |
| 6 | Outwit | 7 | None | Perception vs Perception roll to negate crits | Not implemented |
| 7 | Listen | 8 | Keen Senses | Detect non-visible monsters by sound | Not implemented |
| 8 | Master Hunter | 9 | Concentration + Bane | +min(kills, Per/2) attack vs known species | Yes |
| 9 | Grace | 10 | None | +1 Grace stat point | Yes |

**Ability count comparison:**
- Melee: 14 abilities (Power through Strength)
- Archery: 9 abilities
- Evasion: 11 abilities (Dodging through Dexterity)
- Stealth: 12 abilities (Disguise through Silent Kill)
- **Perception: 10 abilities** (smallest alongside Archery)
- Will: 11 abilities
- Smithing: 12 abilities
- Lore: 15 abilities

### 1.3 Usage Frequency Assessment

- **Trap avoidance**: Passive, fires automatically. Player never "feels" it working.
- **Secret door search (Shift+S)**: Rarely used. Only 1-2 secret doors per floor (depths 3+).
  Most players walk past them without knowing. The reward for finding one is a shortcut, not
  treasure or power.
- **Focused Attack / Concentration**: These are good combat abilities but feel like they belong
  in Melee. They reward standing still and fighting, not hunting or tracking.
- **Bane / Master Hunter**: Strong scaling abilities, but they reward killing — again, a Melee
  fantasy, not a Hunting one.
- **Listen**: Not implemented. This is the single most "Hunting-flavored" ability and it does
  nothing.
- **Alchemy**: Not implemented. Would be strong utility but thematically disconnected from
  Hunting.
- **Outwit**: Not implemented. A strong defensive ability (crit negation) with no Hunting flavor.

### 1.4 The Core Problem

Hunting has an **identity crisis**. Its combat abilities (Focused Attack, Concentration, Bane,
Master Hunter) are "Melee but you stand still." Its utility abilities (Keen Senses, Alchemy,
Listen) are either unimplemented or underwhelming. The skill does not create **unique gameplay
moments** — there is no Hunting equivalent of Riposte's dramatic counterattack, Vanish's
disappearing act, or Smithing's artifact creation.

A well-designed Hunting ecology should create moments like:
- "I sense something behind that wall" (Listen reveals a patrol)
- "There's a hidden door here — and it leads to an unguarded treasury" (Secret door + loot)
- "I aim carefully... critical hit!" (Aimed Shot converts patience into damage)
- "I know this creature's weakness" (Bane + observation reveals vulnerability)
- "I smell the poison on the wind" (Ambush detection saves your life)

---

## 2. Sil-Q Perception Reference

### 2.1 What Perception Does in Sil-Q

From the Sil-Q C source (`cmd1.c`, `cmd2.c`, `melee2.c`, `monster2.c`):

**Core Mechanic: Opposed Skill Check**
The heart of Sil-Q perception is `monster_perception()` — called every turn for every monster.
The formula is:

```
m_perception = monster_skill(S_PER) - noise_dist + combat_noise_bonus - bane_bonus
difficulty_roll = stealth_score + d10
result = m_perception + d10 - difficulty_roll
```

This means Perception is fundamentally **the anti-Stealth stat**. When a monster rolls to detect
you, your Stealth opposes their Perception. When you roll to detect hidden things, your Perception
opposes the dungeon's difficulty.

**Search (`search_square()` in cmd1.c):**
```
score = skill_use[S_PER] + cave_light[y][x]
difficulty = depth / 2
    + 5 (if blind/dark/confused)
    + 2/4/6 (distance 2/3/4)
    + 5 (dungeon trap)
    + 10 (secret door)
    + 15 (chest trap)
```
Active search adds +5 to score. This creates meaningful scaling: at Perception 5 on depth 10
(difficulty 5), you have a ~50% chance to find adjacent traps and ~25% for secret doors.

**Listen (`listen()` in monster2.c):**
```
difficulty = flow_dist(FLOW_PLAYER_NOISE, y, x) - monster_noise
    + monster_skill(S_STL)
    - 3 (if monster is unwary)
result = skill_check(PLAYER, skill_use[S_PER], difficulty, monster)
    if result > 0: show blip on map
    if result > 10: fully reveal monster
```
Listen shows a generic marker (`*`) at the monster's position for non-visible monsters. It does
NOT reveal monster identity — just "something is there." This creates wonderful tension.

### 2.2 What Transfers Well to The Necromancer

| Sil-Q Mechanic | Transfer Quality | Notes |
|---|---|---|
| Opposed perception checks | Already adapted | Monster alertness system uses this |
| Search formula (Per + light vs depth/2) | Good, needs tuning | Current formula is simpler but functional |
| Listen (blip detection) | Excellent | High-impact, low-implementation-cost |
| Passive trap detection each turn | Good | Already implemented but formula differs |
| Secret doors as Perception gates | Excellent | Infrastructure exists (DOOR_SECRET, search_for_secrets) |
| Keen Senses (+5 vs invisible) | Good | SEE_INVIS exists, invisible monsters exist |
| Focused Attack (pass turn bonus) | Already in | Works well |
| Concentration (consecutive attack bonus) | Already in | Works well |
| Alchemy (herb identification) | Good | Herb system exists, identification could add value |
| Bane (kill-tracking bonus) | Already in | Strong ability |
| Master Hunter | Already in | Strong ability |
| Outwit (negate crits) | Good | Needs implementation |

### 2.3 What Doesn't Fit

| Sil-Q Mechanic | Issue |
|---|---|
| Noise flow maps (`FLOW_PLAYER_NOISE`) | Requires a full Dijkstra noise propagation system. High effort, low visible impact. The current simpler distance-based system is adequate. |
| Chest traps | The Necromancer doesn't have chest objects. Skip. |
| Perceive command (full-screen detection) | Overlaps with Deep Memory (Lore). Would step on Lore's territory. |

---

## 3. Proposed Hunting Ecology

### A. Secret Doors — Gateway Mechanic (Priority: HIGH)

**Current state:** 1-2 secret doors per floor at depth 3+. Found only by active Shift+S search.
Formula: `20 + perception * 10`% per adjacent tile.

**Problem:** Too few doors, too little reason to search, no reward behind them.

**Proposal:**

1. **Increase secret door density**: Scale with depth.
   - Depths 1-3: 0-1 secret doors (tutorial levels, rare)
   - Depths 4-8: 2-3 secret doors per floor
   - Depths 9-14: 3-5 secret doors per floor
   - Depths 15-20: 4-6 secret doors per floor

2. **Passive detection (new)**: Each turn you are adjacent to a secret door, make a passive
   Perception check:
   ```
   passive_chance = perception * 3  (percentage)
   ```
   At Perception 5, you have a 15% passive chance per turn adjacent. At Perception 10, 30%.
   This means a Hunting character walking along corridors will occasionally notice hidden passages
   without explicitly searching. Explicitly searching (Shift+S) retains its higher chance
   (`20 + perception * 10`%).

3. **Reward rooms behind secret doors**: New dungeon generation step: `_generate_secret_rooms()`.
   When placing a secret door, 50% chance to generate a small (3x3 to 5x5) hidden room behind
   it containing one of:
   - **Treasure cache**: 2-3 items, depth-appropriate, 20% chance of artifact-quality
   - **Herb garden**: 3-5 herbs (themed to layer — healing herbs shallow, rare herbs deep)
   - **Forge alcove**: A forge in a hidden room (valuable at any depth)
   - **Lore object**: A lore inscription granting 100-300 XP
   - **Shortcut**: Corridor to a distant room (existing behavior, but now less common)

4. **Visual hint system**: At Perception 6+, explored walls adjacent to secret doors show a
   subtle visual indicator (slightly different wall sprite or a faint crack overlay) when the
   tile is in FOV. This is NOT automatic discovery — it tells the player "search here."

**Implementation scope**: Medium. Requires changes to `dungeon_generator.gd` (room generation),
`level.gd` (passive detection per turn), and minor tilemap work for visual hints.

**Files to modify**: `dungeon_generator.gd`, `level.gd`, `player.gd` (passive check in movement),
`main.gd` (integrate passive check into turn loop).

---

### B. Invisible and Camouflaged Monsters (Priority: MEDIUM)

**Current state:** Several monsters in `monster.txt` already have the `INVISIBLE` flag:
- Corpse Light (depth 8) — INVISIBLE, UNDEAD
- Shadow Wraith (depth 12) — INVISIBLE, LIGHT_SENSITIVE
- Barrow Wight (depth 14) — INVISIBLE, DARK_AURA
- Fell Spirit (depth 16) — INVISIBLE, PASS_WALL
- The Necromancer (depth 20) — INVISIBLE
- Ringwraith variants (depths 16-20) — INVISIBLE

The `SEE_INVIS` equipment flag exists. The `is_invisible` monster flag is parsed.

**Problem:** Invisible monsters are rendered as visible in the current code. The `is_invisible`
flag is stored but never checked during visibility calculations.

**Proposal:**

1. **Implement true invisibility**: In `level.gd:update_entity_visibility()`, check
   `monster.is_invisible`:
   ```gdscript
   if monster.is_invisible:
       var can_see: bool = false
       # SEE_INVIS equipment flag
       if player.equip_flags.has("SEE_INVIS"):
           can_see = true
       # Keen Senses ability: +5 effective Perception for invisible detection
       elif player.has_ability(S_PER, PER_KEEN_SENSES):
           var detect_chance: int = (player.get_skill("perception") + 5) * 3
           can_see = randi_range(1, 100) <= detect_chance
       # Base Perception check (harder)
       else:
           var detect_chance: int = player.get_skill("perception") * 2
           can_see = randi_range(1, 100) <= detect_chance
       monster.visible = can_see and is_tile_visible(monster.grid_position)
   ```

2. **Shimmer effect for partially-detected invisible monsters**: When the Perception check
   barely fails (within 10% of threshold), show a brief shimmer particle at the monster's
   position — a hint that something is there without revealing identity.

3. **Detection persistence**: Once you detect an invisible monster, it stays visible for
   `2 + perception / 3` turns (not just the current turn). This prevents annoying flicker.

4. **Keen Senses upgrade**: Change the ability description to: "Allows you to see enemies who are
   just beyond the edge of a pool of light, and gives a strong bonus to detect invisible
   creatures." The +5 bonus is already in `ability.txt` but needs code implementation.

**Implementation scope**: Small-medium. Mostly `level.gd` visibility logic plus a shimmer VFX.

**Files to modify**: `level.gd` (visibility), `player.gd` (detection check), potentially
`monster.gd` (detection state tracking).

---

### C. Ambush Detection (Priority: MEDIUM)

**Current state:** Monsters behind closed doors are invisible to the player. Opening a door into
a room full of alert monsters gives them the first action since the player spent their turn
opening the door. There is no warning system.

**Proposal:**

1. **Ambush warning**: When the player is adjacent to a closed door, make a Perception check
   against the strongest monster behind it:
   ```
   detection_score = perception + d10
   difficulty = monster_stealth + distance_behind_door
   if detection_score > difficulty:
       "You sense danger beyond the door."
   if detection_score > difficulty + 5:
       "You sense [number] creatures beyond the door."
   if detection_score > difficulty + 10:
       "You sense [creature_type] beyond the door."
   ```

2. **Ambush free attack prevention**: Without Hunting, entering a room with 3+ alert monsters
   gives each adjacent monster a free attack (ambush round). With Hunting 5+, the ambush
   round is negated — you enter cautiously. With Hunting 8+ or the "Sixth Sense" ability (new),
   you get a free turn to act before they react.

3. **Door guard awareness**: The dungeon generator already places door guards
   (`_place_door_guards()`). Hunting should interact with this — guarded doors show a
   different visual hint (scuff marks, shadow under the door) at Perception 4+.

**Implementation scope**: Medium. Requires new check in `main.gd` when opening doors, plus
the ambush round mechanic in the turn system.

**Files to modify**: `main.gd` (door opening), `player.gd` (ambush check), `turn_system.gd`
(ambush round logic).

---

### D. Tracking (Priority: LOW)

**Current state:** No tracking system exists. Explored tiles show terrain only.

**Proposal:**

1. **Monster footprints**: When a monster moves, it leaves a "track" on the tile it departed.
   Tracks are invisible by default. With the "Pathfinder" ability (new, see Section 5), tracks
   become visible in explored tiles.

2. **Track information scales with Perception**:
   - Per 3+: "Something passed here recently" (generic marker)
   - Per 6+: Size category (small/medium/large) and direction of travel
   - Per 9+: Creature type and approximate recency (1-5 turns ago vs 5+ turns)

3. **Track decay**: Tracks fade after `20 - depth` turns (faster decay in deeper, more
   dangerous areas). Tracks on water tiles are immediately erased.

4. **Visual representation**: A small directional arrow or footprint icon overlaid on the tile,
   color-coded by recency (bright = recent, dim = old).

**Implementation scope**: Medium-high. Requires track data storage per-tile, monster movement
hooks, and overlay rendering. Lower priority because the payoff is tactical convenience,
not survival.

**Files to modify**: `level.gd` (track storage), `monster.gd` (track creation on move),
`player.gd` (track perception check), tilemap overlay system.

---

### E. Enhanced Look Mode (Priority: MEDIUM)

**Current state:** Look mode (X key) shows monster info based on `MonsterMemory` observation
count. The knowledge tiers are: UNKNOWN (0 obs), IDENTIFIED (1), BASIC (3), DETAILED (5),
COMPLETE (10). Lore skill adds `lore / 2` effective observations. Perception has no effect.

**Problem:** This system rewards passive observation count, not active skill investment. A
Perception 0 character who has seen 10 goblins knows everything about goblins. A Perception 15
character who has never seen a goblin knows nothing.

**Proposal:**

1. **Hybrid system**: Replace the pure observation-count system with a hybrid that factors in
   both observations AND Perception skill:
   ```
   effective_observations = actual_observations + (perception / 2) + (lore / 2)
   ```
   This means a character with Perception 10 and Lore 0 starts with 5 effective observations
   on every monster — enough for BASIC tier (HP, primary attack) on first sight.

2. **Perception-gated information tiers**:
   - **Any Perception**: Name, stance, basic description (already works)
   - **Perception 3+**: Health percentage bar (approximate: "wounded", "badly hurt", "near death")
   - **Perception 5+**: Primary attack type and estimated damage range
   - **Perception 8+**: All attacks, resistances, movement speed
   - **Perception 10+**: Exact current HP, full stat block, inventory (if any)

3. **"Study" action**: A new action (Shift+X or long-press X) that spends a turn to deeply
   study the targeted monster. This adds 3 effective observations instantly, equivalent to
   seeing the creature 3 more times. Synergy: a Hunting character studies a new monster for one
   turn, then has BASIC knowledge for the rest of the fight.

4. **Visual tier indicators**: In look mode, show a colored border or icon indicating knowledge
   tier: grey (unknown), white (identified), blue (basic), purple (detailed), gold (complete).

**Implementation scope**: Small-medium. The `MonsterMemory` system already supports tiered
info. Main change is incorporating Perception into `get_effective_observations()` and adding
the Study action.

**Files to modify**: `monster_memory.gd` (formula change), `look_panel.gd` (visual tiers),
`main.gd` (Study action keybind), `player.gd` (study action).

---

### F. Listen (Priority: MEDIUM-HIGH)

**Current state:** The Listen ability exists in `ability.txt` (N:87, Perception tree, level 8,
requires Keen Senses) but is completely unimplemented. The MEMORY.md file lists "Listen ability:
Needs monster audibility system" as a known TODO.

**Proposal (faithful to Sil-Q):**

1. **Core mechanic**: Each turn, for every non-visible monster within `perception * 2` tiles,
   make a Listen check:
   ```
   player_score = perception_skill + d10
   difficulty = flow_distance + monster_stealth
       - 3 (if monster is unwary — careless noise)
   result = player_score - difficulty
   if result > 0: show blip marker at monster position
   if result > 10: fully reveal monster (make visible for 1 turn)
   ```

2. **Blip markers**: A generic `*` symbol (or small sound-wave icon) displayed at the monster's
   tile position. The blip does NOT reveal monster identity, HP, or type — only that something
   alive is at that position. Color: slate grey (matching Sil-Q's `TERM_SLATE`).

3. **Monster audibility tiers**: Not all monsters make equal noise.
   - **Loud** (-3 difficulty): Trolls, dragons, orcs in groups, werewolves
   - **Normal** (0): Most humanoids, wolves, wargs
   - **Quiet** (+3 difficulty): Spiders, snakes, bats
   - **Silent** (+10 difficulty, effectively undetectable): Wraiths, shadows, spirits
   - Store as `audibility` modifier in `MonsterData` or derive from flags.

4. **Directional hint**: At Perception 10+, instead of a blip, show a directional indicator in
   the message log: "You hear heavy footsteps to the northwest." This gives tactical
   information without exact positioning.

5. **Integration with existing systems**: Listen checks happen during `update_entity_visibility()`
   or in a new `_apply_listen_detection()` pass after FOV. Detected positions are stored in a
   transient `listened_positions: Array[Vector2i]` on the level, rendered as overlays, and
   cleared each turn.

**Implementation scope**: Medium. Requires the listen check loop, blip rendering, and monster
audibility data. The Sil-Q source provides a clear reference implementation.

**Files to modify**: `level.gd` (listen overlay), `player.gd` (listen check), `monster.gd`
(audibility getter), `data_manager.gd` (parse audibility from monster data or derive from flags).

---

### G. Aimed Shot / Critical Shot (Priority: HIGH)

**Current state:** Archery has "Keen Eyes" which gives +Perception/2 to ranged attacks. But
there is no active Perception ability that directly contributes to ranged damage. The Archery
tree has its own abilities (Rout, Puncture, Crippling Shot, Deadly Hail) but Perception's
contribution is limited to the passive Keen Eyes bonus.

**Problem:** A Perception-heavy ranged character has high accuracy but no way to convert patience
into burst damage. Melee has Opening Strike and Charge for burst; Archery has nothing equivalent
that scales with Perception.

**Proposal:**

1. **Aimed Shot (new ability)**: Active ability, costs a turn to activate. On the next ranged
   attack:
   - `+Perception` to attack roll (not Perception/2 — full skill)
   - Crit threshold reduced by `Perception * 2` (stacks with Finesse)
   - If the shot hits, deal `+Perception / 3` bonus damage dice (rounded down)
   - Effect consumed after one shot (hit or miss)

2. **Activation flow**:
   - Player presses hotkey or selects from ability menu
   - Message: "You take careful aim..." (costs one turn, no movement)
   - Player sprite shows subtle targeting overlay (crosshair or eye icon)
   - Next ranged attack (any direction) applies Aimed Shot bonuses
   - If player moves before firing, aim is lost: "You lose your aim."

3. **Synergy chain**:
   - Aimed Shot + Keen Eyes: +Perception + Perception/2 = 1.5x Perception to ranged attack
   - Aimed Shot + Ambush (Archery): +Stealth to attack vs unwary + Aimed Shot bonuses
   - Aimed Shot + Crippling Shot: guaranteed crit = guaranteed slow
   - Aimed Shot + Bane/Master Hunter: stacking kill-count bonuses

4. **Balance**: The "costs a turn" requirement is critical. In a 1v1, using Aimed Shot is
   trading one turn of safety for one turn of massive damage. Against multiple enemies, you
   cannot afford it. This makes it strategic, not a spam ability.

**Implementation scope**: Small. New ability flag, activation state in `player.gd`, bonus
application in `ranged_attack()`, state reset on movement.

**Files to modify**: `player.gd` (activation, state, ranged bonus), `ability.txt` (new ability
entry), `constants.gd` (new ability enum value), `main.gd` (hotkey integration).

---

### H. Herb Identification (Priority: LOW-MEDIUM)

**Current state:** The Alchemy ability (N:84, Perception tree, level 5) is defined in
`ability.txt` but not implemented. Description: "Lets you identify all herbs and potions.
Combine two identical herbs to produce a more potent version."

**Proposal:**

1. **Auto-identification on pickup**: When `PER_ALCHEMY` is active, all herbs and potions are
   automatically identified when picked up (no identification scroll needed). Without Alchemy,
   herbs show as "unknown herb" until consumed or identified.

2. **Herb combination**: At a forge (or anywhere with Alchemy), combine 2 identical herbs to
   produce an upgraded version:
   - 2x Healing Herb -> Potent Healing Herb (2x healing)
   - 2x Antidote Herb -> Elixir of Purity (cure all poison + 10-turn immunity)
   - 2x Rage Herb -> Berserker Draft (+3 STR, +3 melee, -3 evasion, 5 turns)

3. **Passive Perception skill benefit**: Even without Alchemy, at Perception 3+ herbs found on
   the ground show a color hint (the herb's actual color rather than generic "herb" sprite).
   This is a soft identification — the player can guess based on color but doesn't get the name.

**Implementation scope**: Small for auto-ID, medium for herb combination.

**Files to modify**: `player.gd` (auto-ID on pickup), `consumable_system.gd` (combination
recipes), `item.gd` (display name logic).

---

## 4. Implementation Priority

### Phase 1: Core Identity (Sessions 1-2)

These changes establish Hunting as a skill with a clear identity and visible impact:

| Proposal | Priority | Effort | Impact | Why First |
|---|---|---|---|---|
| **G. Aimed Shot** | HIGH | Small | High | Gives Hunting its first active offensive ability. Immediately changes how ranged characters feel. |
| **F. Listen** | MEDIUM-HIGH | Medium | High | Most iconic Hunting ability. Creates unique gameplay moments every turn. |
| **B. Invisible Monsters** | MEDIUM | Small | Medium | Infrastructure exists. Flipping the switch on `is_invisible` makes Keen Senses meaningful. |

**Estimated effort**: 2 focused implementation sessions.

### Phase 2: Exploration Reward (Sessions 3-4)

These changes make exploration-focused play rewarding:

| Proposal | Priority | Effort | Impact | Why Second |
|---|---|---|---|---|
| **A. Secret Doors (expanded)** | HIGH | Medium | High | Creates the "hidden loot" loop that makes Hunting feel rewarding. |
| **E. Enhanced Look Mode** | MEDIUM | Small | Medium | Low-effort, high-visibility improvement to the information game. |
| **C. Ambush Detection** | MEDIUM | Medium | Medium | Rewards investment in Hunting with tactical safety. |

**Estimated effort**: 2 focused implementation sessions.

### Phase 3: Polish and Depth (Sessions 5+)

These add depth but are not essential for the core identity:

| Proposal | Priority | Effort | Impact | Why Later |
|---|---|---|---|---|
| **H. Herb Identification** | LOW-MEDIUM | Small | Low | Nice utility but doesn't change moment-to-moment play. |
| **D. Tracking** | LOW | Medium-High | Low | Cool flavor but tactical value is situational. |

**Estimated effort**: 1-2 sessions if time permits.

---

## 5. Ability Tree Expansion

### Current Tree (10 abilities, IDs 80-89)

```
Natural Talent (1) ─── Focused Attack (2) ─── Keen Senses (3) ─── Concentration (4)
                                                    │
                                                    └── Listen (8)
                                        Alchemy (5) ─── Bane (6) ─── Outwit (7)
                                                              │
                                                              └── Master Hunter (9, req: Concentration + Bane)
Grace (10)
```

### Proposed Additions (5 new abilities, IDs 90-94)

---

#### Ability: Aimed Shot
- **ID**: 90
- **Skill**: Perception (4), Ability Value: 10, Level Requirement: 5
- **Prerequisites**: Focused Attack (4/1) OR Keen Senses (4/2)
- **Description**: Spend a turn taking careful aim. Your next ranged attack gains +Perception to
  hit, a reduced critical threshold, and bonus damage. The aim is lost if you move.
- **Equipment affinity**: Bows, Helms
- **Cost rationale**: Level 5, one prereq — comparable to Charge (Melee 4/4, level 5). The "costs
  a turn" limitation provides balance.
- **Data entry**:
  ```
  N:90:Aimed Shot
  I:4:10:5
  P:4/1:4/2
  D:Spend a turn taking careful aim. Your next ranged attack gains
  D: +Perception to hit, a reduced critical threshold, and bonus damage.
  D: The aim is lost if you move. The patience of the hunter rewarded.
  T:19:0:99  # Bows
  T:32:0:99  # Helm
  ```

---

#### Ability: Sixth Sense
- **ID**: 91
- **Skill**: Perception (4), Ability Value: 11, Level Requirement: 7
- **Prerequisites**: Keen Senses (4/2)
- **Description**: You can never be ambushed. When entering a room containing alert enemies, you
  act first instead of them. Your instincts are honed beyond normal awareness.
- **Equipment affinity**: Helms, Amulets
- **Effect**: Sets a flag `_sixth_sense_active` that is checked in the ambush resolution system
  (Proposal C). When you open a door, the ambush round is completely negated, and you get
  priority action.
- **Data entry**:
  ```
  N:91:Sixth Sense
  I:4:11:7
  P:4/2
  D:You can never be ambushed. When entering a room containing alert
  D: enemies, you act first instead of them. Your instincts are honed
  D: beyond the limits of normal awareness.
  T:32:0:99  # Helm
  T:40:0:99  # Amulet
  ```

---

#### Ability: Pathfinder
- **ID**: 92
- **Skill**: Perception (4), Ability Value: 12, Level Requirement: 6
- **Prerequisites**: Keen Senses (4/2)
- **Description**: You can read the signs of passage. Monster tracks become visible in explored
  tiles, revealing creature type, direction of travel, and recency. You also passively detect
  secret doors when adjacent.
- **Equipment affinity**: Boots, Helms
- **Effect**: Enables track visibility (Proposal D) and upgrades passive secret door detection
  chance from `perception * 3`% to `perception * 5`%.
- **Data entry**:
  ```
  N:92:Pathfinder
  I:4:12:6
  P:4/2
  D:You can read the signs of passage. Monster tracks become visible
  D: in explored tiles, revealing creature type, direction, and recency.
  D: You also passively detect secret doors when adjacent.
  T:30:0:99  # Boots
  T:32:0:99  # Helm
  ```

---

#### Ability: Predator's Insight
- **ID**: 93
- **Skill**: Perception (4), Ability Value: 13, Level Requirement: 8
- **Prerequisites**: Bane (4/5) AND Listen (4/7)
- **Description**: Your deep knowledge of prey reveals their weaknesses. Monsters you have killed
  3+ times take bonus damage equal to your Perception/3 from all sources. Studying a monster
  (Shift+X) counts as 3 additional observations.
- **Equipment affinity**: Helms, Bows
- **Effect**: A direct damage multiplier gated behind kill tracking + Listen prereqs. Makes
  the Bane/Master Hunter investment path culminate in real power.
- **Data entry**:
  ```
  N:93:Predator's Insight
  I:4:13:8
  P:4/5:4/7
  D:Your deep knowledge of prey reveals their weaknesses. Monsters you
  D: have killed 3+ times take bonus damage equal to your Perception/3
  D: from all sources. Study (Shift+X) counts as 3 extra observations.
  T:32:0:99  # Helm
  T:19:0:99  # Bows
  ```

---

#### Ability: Eagle Eye
- **ID**: 94
- **Skill**: Perception (4), Ability Value: 14, Level Requirement: 10
- **Prerequisites**: Aimed Shot (4/10) AND Pathfinder (4/12)
- **Description**: Your vision rivals the great Eagles of Manwe. Your FOV radius increases by 2.
  Ranged attacks suffer no distance penalty within your light radius. You automatically detect
  all traps and secret doors within line of sight.
- **Equipment affinity**: Helms, Bows, Light Sources
- **Effect**: Capstone ability. +2 FOV radius, zero ranged distance penalty within light range,
  auto-detect traps/secrets in FOV. This is the payoff for deep Perception investment — you
  see everything.
- **Data entry**:
  ```
  N:94:Eagle Eye
  I:4:14:10
  P:4/10:4/12
  D:Your vision rivals the great Eagles of Manwe. Your FOV radius
  D: increases by 2. Ranged attacks suffer no distance penalty within
  D: your light radius. You automatically detect all traps and secret
  D: doors within line of sight.
  T:32:0:99  # Helm
  T:19:0:99  # Bows
  T:39:0:99  # Light Source
  ```

---

### Expanded Tree (15 abilities)

```
Natural Talent (1) ─── Focused Attack (2) ──┬── Concentration (4) ──┐
                                             │                       │
                                             └── Aimed Shot (5) ─────┤
                                                                     │
Keen Senses (3) ──┬── Listen (8) ──┐                                 │
                  │                ├── Predator's Insight (8)        │
                  ├── Sixth Sense (7)                                 │
                  └── Pathfinder (6) ─── Eagle Eye (10) ◄────────────┘
                                                   (req: Aimed Shot + Pathfinder)

Alchemy (5) ─── Bane (6) ──┬── Master Hunter (9, req: Concentration + Bane)
                            └── Predator's Insight (8, req: Bane + Listen)

Outwit (7)
Grace (10)
```

**Ability count after expansion: 15** (matching Lore as the deepest tree, up from 10).

---

## 6. Balance Considerations

### Skill Tree Comparison

| Skill | Core Fantasy | Offensive Power | Defensive Power | Utility |
|---|---|---|---|---|
| Melee | Close-quarters warrior | Very High (damage, crits) | Medium (Defensive Stance) | Low |
| Archery | Ranged striker | High (at distance) | Low | Low |
| Evasion | Untouchable duelist | Medium (Riposte, Flanking) | Very High | Medium (Sprinting) |
| Stealth | Unseen assassin | High (burst from stealth) | High (avoidance) | Medium |
| **Hunting** (proposed) | **Wilderness master** | **Medium (Aimed Shot, Bane)** | **Medium (Ambush, Outwit)** | **Very High (Listen, Secrets, Look)** |
| Will | Iron resolve | Low | Very High (resist effects) | Medium |
| Smithing | Crafter | Medium (better gear) | Medium (better gear) | Very High (forge) |
| Lore | Scholar-sage | Medium (Deadly Lore) | Medium (Endurance, Sleep) | Very High (Words) |

Hunting's proposed identity is **"the information skill"** — you know more, see more, and exploit
knowledge for tactical advantage. This is distinct from every other tree:
- Melee/Archery: raw combat power
- Evasion: reactive defense
- Stealth: avoidance and ambush
- Will: resilience and mental fortitude
- Smithing: gear creation
- Lore: magical utility

### XP Investment Curve

With escalating XP costs (`(owned + 1) * 500 - 500 * affinity`), a character investing deeply
in Hunting needs to justify the cost. The proposed abilities reward this:

- **Levels 1-3 (cheap)**: Focused Attack + Keen Senses = solid early combat + light bonus
- **Levels 4-6 (moderate)**: Alchemy + Aimed Shot + Pathfinder = active offense + exploration
- **Levels 7-9 (expensive)**: Listen + Sixth Sense + Predator's Insight = full awareness + damage
- **Level 10 (very expensive)**: Eagle Eye = capstone, "I see everything"

A character who invests only to level 3 gets good combat bonuses. A character who goes to level 7+
gets transformative awareness abilities. This matches other trees where early investment gives
reliable basics and deep investment unlocks signature abilities.

### Interaction with Tolkien Setting

All proposed abilities reflect learned wilderness skills, not magic:

- **Aimed Shot**: A ranger's patient marksmanship
- **Sixth Sense**: Instincts honed by years in the wild (Aragorn entering Moria cautiously)
- **Pathfinder**: Reading tracks and signs (Aragorn tracking the hobbits across Rohan)
- **Predator's Insight**: Deep knowledge of prey (a hunter who has studied their quarry)
- **Eagle Eye**: The far-sight of the Dunedain (Aragorn's exceptional eyesight in the books)
- **Listen**: Alertness to sound (rangers listening at doors, scouts detecting patrols)

None of these are magical. They are the skills of a trained wilderness survivor operating in
a world where such skills mean the difference between life and death in the dark places of
Middle-earth.

---

## 7. Implementation Notes

### Constants to Add (`constants.gd`)

```gdscript
enum PerceptionAbility {
    # ... existing entries 0-9 ...
    PER_AIMED_SHOT = 10,
    PER_SIXTH_SENSE = 11,
    PER_PATHFINDER = 12,
    PER_PREDATORS_INSIGHT = 13,
    PER_EAGLE_EYE = 14,
}
```

### Player State to Add (`player.gd`)

```gdscript
# Aimed Shot state
var _aimed_shot_active: bool = false  # True after spending a turn aiming

# Track data (for Pathfinder)
var _track_perception_active: bool = false  # Calculated from abilities

# Passive secret door detection accumulator
var _passive_secret_checked: Dictionary = {}  # pos -> true (checked this turn)
```

### Monster Data to Add

```gdscript
# Audibility modifier for Listen checks (derived from flags or explicit)
# Loud: -3, Normal: 0, Quiet: +3, Silent: +10
func get_audibility() -> int:
    if has_flag("UNDEAD") and (has_flag("INVISIBLE") or has_flag("PASS_WALL")):
        return 10  # Wraiths/spirits are silent
    if has_flag("SPIDER"):
        return 3   # Spiders are quiet
    if has_flag("TROLL") or has_flag("DRAGON"):
        return -3  # Large creatures are loud
    if has_flag("ORC") and has_flag("FRIENDS"):
        return -3  # Orc groups are noisy
    return 0  # Default: normal
```

### Key Integration Points

1. **Turn loop** (`main.gd`): After FOV update, call `_apply_listen_detection()` and
   `_check_passive_secrets()`.
2. **Door opening** (`main.gd`): Before opening a door, call `_check_ambush_warning()`.
3. **Ranged attack** (`player.gd`): Check `_aimed_shot_active` for bonus application.
4. **Movement** (`player.gd`): Reset `_aimed_shot_active = false` on any movement.
5. **Visibility** (`level.gd`): Add invisible monster detection pass.
6. **Dungeon generation** (`dungeon_generator.gd`): Expand secret door placement and
   generate reward rooms.

---

## Summary

The Hunting Ecology transforms Perception from a passive tax into an active information-warfare
skill. By implementing Listen, Aimed Shot, expanded secret doors, invisible monster detection,
and ambush awareness, we create a skill tree where every point invested produces visible,
satisfying results. The five new abilities (Aimed Shot, Sixth Sense, Pathfinder, Predator's
Insight, Eagle Eye) give Hunting a clear progression from "competent woodsman" to "all-seeing
master ranger" — the Aragorn fantasy that Tolkien's setting demands.
