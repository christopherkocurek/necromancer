# Necromancer: Godot Migration Gap Analysis

**Date:** 2026-02-05
**Scope:** Canonical C source + data files vs. current Godot 4 implementation
**Purpose:** Identify every feature delta between the original Necromancer design and the Godot build, assign priority and complexity, and propose an implementation roadmap.

---

## Executive Summary

**Overall Feature Completion: ~30-35%**

**Validation: 5 iterations completed, confidence 90/100.**

The Godot build has the skeleton -- opposed d20 combat rolls, room-and-corridor dungeon generation, energy-based turns, a working FOV raycaster, DCSS tileset rendering, basic UI panels, door mechanics, a status effect framework, full death/victory screens with scoring, and monster sleep/alertness AI. It does not yet have the flesh. The stealth system is absent. Light does not affect gameplay. Consumable items cannot be used. 81 of 93 abilities have no gameplay code. The identification system is missing entirely. Monster spells are parsed but never cast. Characters receive no starting equipment.

In short: a player can walk through dungeons, fight monsters in melee, open doors, manage an inventory of equipment, complete two quest paths, and win or die with a scored epitaph screen. Everything beyond that core loop -- ranged combat, stealth, consumables, the vast majority of abilities, special encounter mechanics, and dozens of keybindings -- remains unimplemented.

---

## 1. Combat System

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 1 | Opposed d20 attack rolls | Full implementation with all modifiers | Base roll only | Partial -- modifiers missing | CRITICAL | M |
| 2 | Concentration modifier | +Perception skill when not moving last turn | Not implemented | Full gap | CRITICAL | S |
| 3 | Focused Attack modifier | +1 per Focused Attack ability level | Not implemented | Full gap | CRITICAL | S |
| 4 | Bane modifier | +Perception skill vs. identified monster type | Not implemented | Full gap | MAJOR | S |
| 5 | Master Hunter modifier | +Perception skill vs. natural creatures | Not implemented | Full gap | MAJOR | S |
| 6 | Assassination modifier | +Stealth skill vs. unwary/sleeping targets | Not implemented | Full gap | CRITICAL | M |
| 7 | Flanking/Overwhelming modifier | +1 per adjacent ally (player or monster) | Not implemented | Full gap | MAJOR | M |
| 8 | Light penalty modifier | Penalty when darkness > 0 at target tile | Not implemented | Full gap | CRITICAL | S |
| 9 | Distance penalty (archery) | -1 per tile beyond point-blank | Not implemented (no archery) | Full gap | MAJOR | M |
| 10 | Charge bonus | +1 to attack when charging in a straight line | Not implemented | Full gap | MODERATE | M |
| 11 | Pit/Web penalties | Penalties when attacker/defender in pit or web | Not implemented | Full gap | MODERATE | S |
| 12 | Critical hit formula | Weight-based crit with weapon weight | Implemented | None | -- | -- |
| 13 | Protection dice | Shield + armor dice rolled for damage reduction | Implemented | None | -- | -- |
| 14 | Shield blocking (2x stationary) | Double shield dice when player did not move | Not implemented | Full gap | MAJOR | S |
| 15 | Archery system | Separate ranged combat with evasion halving | Not implemented | Full gap | CRITICAL | L |
| 16 | Ranged weapon firing (f key) | Select target, calculate range, fire arrow/bolt | Not implemented | Full gap | CRITICAL | L |
| 17 | Ammunition tracking | Quiver slot, arrow count, recovery after combat | Not implemented | Full gap | CRITICAL | M |
| 18 | Throwing system (t key) | Throw any item at a target | Not implemented | Full gap | MAJOR | M |
| 19 | FIRE attack effect | Burn equipment, ongoing fire damage | Not resolved beyond HURT | Full gap | MAJOR | M |
| 20 | COLD attack effect | Slow movement, reduce dexterity | Not resolved beyond HURT | Full gap | MAJOR | S |
| 21 | BLIND attack effect | Reduce FOV to 0, miss chance | Not resolved | Full gap | MAJOR | M |
| 22 | CONFUSE attack effect | Random movement for N turns | Not resolved | Full gap | MAJOR | M |
| 23 | FEAR attack effect | Flee from source for N turns | Not resolved | Full gap | MAJOR | M |
| 24 | STUN attack effect | Skip N turns | Not resolved | Full gap | MAJOR | S |
| 25 | ENTRANCE attack effect | Paralysis until damaged | Not resolved | Full gap | MAJOR | S |
| 26 | LOSE_STR attack effect | Permanent strength drain | Not resolved | Full gap | MAJOR | S |
| 27 | Poison resolution | Ongoing damage per turn, curable | Partially implemented | Minor gap | MODERATE | S |
| 28 | Weapon proficiency in combat | Race-based proficiency affects hit chance | Not used in combat calculations | Full gap | MAJOR | S |

---

## 2. Stealth & Detection

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 29 | Stealth mode toggle | Player can enter/exit stealth mode (+5 bonus) | Not implemented | Full gap | CRITICAL | S |
| 30 | Stealth score calculation | STL skill, reduced by loud actions | Not implemented | Full gap | CRITICAL | M |
| 31 | Noise generation system | Each action generates noise (attack, door, item use) | Not implemented | Full gap | CRITICAL | M |
| 32 | Monster perception checks | d10+perception vs d10+stealth per monster per turn | Partial -- d20+perception vs d20+stealth roll exists in `_update_alertness()`, but uses d20 not d10 and no dedicated stealth system feeds it | Partial gap (wrong dice, no stealth input) | CRITICAL | M |
| 33 | Floor-wide alertness (0-50+) | Global alertness rises with noise, decays over time | Not implemented (per-monster alertness only) | Full gap | CRITICAL | M |
| 34 | Alertness threshold behaviors | Unwary/wary/alert/pursuing with distinct AI | Monster has alertness thresholds | Partial -- thresholds exist, no stealth feeds them | MAJOR | M |
| 35 | Assassination attack bonus | +STL skill to attack roll vs. unwary/sleeping | Not implemented | Full gap | CRITICAL | S |
| 36 | Throat Slit ability | Instant kill on sleeping target, suppresses noise | Not implemented | Full gap | MAJOR | S |
| 37 | Silent Kill ability | Suppresses noise from killing blow | Not implemented | Full gap | MAJOR | S |
| 38 | Fade ability | 2 turns of invisibility | Not implemented | Full gap | MAJOR | S |
| 39 | Disguise ability | Halves line-of-sight detection bonus | Not implemented | Full gap | MAJOR | S |
| 40 | Vanish ability | Break contact and re-enter stealth | Not implemented | Full gap | MAJOR | S |
| 41 | Escape Artist ability | Bonus to flee/disengage from adjacent enemies | Not implemented | Full gap | MODERATE | S |
| 42 | Monster sleep state | Monsters can be asleep, woken by noise | Implemented -- `is_sleeping` flag, SLEEPING data flag, wake-on-proximity (2 tiles), Lore of Sleep ability | None | -- | -- |

---

## 3. FOV & Light

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 43 | Fog of war (unexplored = hidden) | Map starts completely hidden, revealed by exploration | Partial -- `explored[]` array, `is_explored()`, FOV raycasting all exist; but terrain tilemap always renders in "light" variant (dark atlas coords never used). Data model exists, visual rendering missing. | Partial gap (rendering only) | CRITICAL | M |
| 44 | Dynamic light radius per entity | Light radius from equipped torch/lantern/glowing items | Not implemented (layer-based FOV radius only) | Full gap | CRITICAL | M |
| 45 | Torch fuel consumption | Torches burn down over turns, eventually go out | Not implemented | Full gap | MAJOR | S |
| 46 | Darkness combat penalty | Darkness halves evasion, applies attack penalties | Not implemented | Full gap | CRITICAL | S |
| 47 | Inner Light ability | +1 FOV radius per 5 Lore skill | Code stub exists, marked DEFERRED | Full gap | MAJOR | S |
| 48 | Light source variety | Different items give different radii (torch=2, lantern=3, etc.) | Not implemented | Full gap | MAJOR | M |
| 49 | Monster light interaction | Some monsters create/destroy light, darkness aura | Not implemented | Full gap | MODERATE | M |
| 50 | Glowing item light | Certain artifacts emit light passively | Not implemented | Full gap | MODERATE | S |

---

## 4. Skill System & Abilities

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 51 | Melee: Power | Extra damage die on hit | No gameplay code | Full gap | CRITICAL | S |
| 52 | Melee: Finesse | Bonus to attack when lightly armored | No gameplay code | Full gap | CRITICAL | S |
| 53 | Melee: Knock Back | Push target 1 tile on hit | No gameplay code | Full gap | MAJOR | M |
| 54 | Melee: Charge | Bonus attack when moving straight toward enemy | No gameplay code | Full gap | MAJOR | M |
| 55 | Melee: Follow-Through | Free attack on kill if adjacent enemy exists | No gameplay code | Full gap | MAJOR | M |
| 56 | Melee: Opening Strike | Bonus on first attack of combat | No gameplay code | Full gap | MAJOR | S |
| 57 | Melee: Subtlety | Reduces noise from melee attacks | No gameplay code | Full gap | MODERATE | S |
| 58 | Melee: Cleave | Hit two adjacent enemies with one attack | No gameplay code | Full gap | MAJOR | M |
| 59 | Melee: Zone of Control | Free attack when enemy moves away | No gameplay code | Full gap | MAJOR | M |
| 60 | Melee: Mighty Blow | Chance to stun on hit | No gameplay code | Full gap | MAJOR | S |
| 61 | Melee: Defensive Stance | Bonus protection, reduced attack | No gameplay code | Full gap | MAJOR | S |
| 62 | Melee: Whirlwind Attack | Attack all adjacent enemies | No gameplay code | Full gap | MAJOR | M |
| 63 | Melee: Rapid Attack | Two attacks per turn at penalty | No gameplay code | Full gap | MAJOR | M |
| 64 | Melee: Strength in Adversity | Bonus when outnumbered | No gameplay code | Full gap | MODERATE | S |
| 65 | Archery: Precision | Bonus to ranged attack rolls | No gameplay code (no archery system) | Full gap | MAJOR | S |
| 66 | Archery: Point Blank Shot | No range penalty at distance 1 | No gameplay code | Full gap | MAJOR | S |
| 67 | Archery: Rapid Fire | Two ranged attacks per turn at penalty | No gameplay code | Full gap | MAJOR | M |
| 68 | Archery: Crippling Shot | Slow target on ranged hit | No gameplay code | Full gap | MAJOR | S |
| 69 | Archery: Flaming Arrows | Add fire damage to ranged attacks | No gameplay code | Full gap | MAJOR | S |
| 70 | Archery: remaining 4 abilities | Various ranged combat bonuses | No gameplay code | Full gap | MAJOR | M |
| 71 | Evasion: Dodging | Bonus to evasion score | No gameplay code | Full gap | CRITICAL | S |
| 72 | Evasion: Blocking | Shield block chance improved | No gameplay code | Full gap | CRITICAL | S |
| 73 | Evasion: Parry | Weapon-based block chance | No gameplay code | Full gap | MAJOR | S |
| 74 | Evasion: Crowd Fighting | Reduced penalty when surrounded | No gameplay code | Full gap | MAJOR | S |
| 75 | Evasion: Leaping | Jump over enemies/obstacles | No gameplay code | Full gap | MAJOR | M |
| 76 | Evasion: Sprinting | Double move speed for N turns | No gameplay code | Full gap | MAJOR | M |
| 77 | Evasion: Flanking | Bonus to attack from behind | No gameplay code | Full gap | MAJOR | S |
| 78 | Evasion: Heavy Armour | Reduce armor penalty | No gameplay code | Full gap | MAJOR | S |
| 79 | Evasion: Riposte | Counterattack on missed enemy attack | No gameplay code | Full gap | MAJOR | M |
| 80 | Evasion: remaining 2 abilities | Various evasion bonuses | No gameplay code | Full gap | MAJOR | S |
| 81 | Stealth: all 12 abilities | Disguise, Assassination, Vanish, Fade, etc. | No gameplay code | Full gap | CRITICAL | L |
| 82 | Perception: Focused Attack | +1 attack per level | No gameplay code | Full gap | CRITICAL | S |
| 83 | Perception: Concentration | +Perception when stationary | No gameplay code | Full gap | CRITICAL | S |
| 84 | Perception: Bane | +Perception vs. identified monster | No gameplay code | Full gap | MAJOR | S |
| 85 | Perception: Master Hunter | +Perception vs. natural creatures | No gameplay code | Full gap | MAJOR | S |
| 86 | Perception: remaining 6 abilities | Listen, Keen Senses, etc. | No gameplay code | Full gap | MAJOR | M |
| 87 | Will: all 11 abilities | Resist fear, resist confusion, etc. | No gameplay code | Full gap | MAJOR | L |
| 88 | Smithing: all 12 abilities | Beyond 3 basic recipes (arming, enchant, etc.) | Partial -- 3 recipes exist, 9 missing | Major gap | MAJOR | L |
| 89 | Lore: Deep Memory (#142) | Recall monster stats from memory | Deferred in code | Full gap | MINOR | S |
| 90 | Lore: Inner Light (#147) | +1 FOV per 5 Lore | Deferred in code | Full gap | MAJOR | S |

---

## 5. Character Creation

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 91 | Race selection | Choose from ~8 races with stat modifiers | Implemented | None | -- | -- |
| 92 | House selection | Choose from ~6 houses with skill affinity | Implemented (no affinity applied) | Partial gap | MAJOR | S |
| 93 | Stat point allocation | Distribute points across STR/DEX/CON/GRA/WIL | Implemented | None | -- | -- |
| 94 | House skill affinity bonus | House grants +1 to affiliated skill | Not applied to skill calculations | Full gap | MAJOR | S |
| 95 | Starting equipment | Race/house grants initial weapons, armor, items | Not given to player at game start | Full gap | CRITICAL | M |
| 96 | Weapon proficiency from race | Race determines which weapon types are proficient | Parsed but not used in combat | Full gap | MAJOR | S |
| 97 | Age selection | Choose character age (affects stats) | Not implemented | Full gap | MINOR | S |
| 98 | Sex selection | Choose character sex | Not implemented | Full gap | MINOR | S |
| 99 | Backstory selection | Choose backstory (flavor + minor bonus) | Not implemented | Full gap | MINOR | M |
| 100 | History generation | Procedural character history text | Not implemented | Full gap | MINOR | M |
| 101 | Name entry | Player enters character name | Implemented | None | -- | -- |

---

## 6. Monsters

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 102 | Monster data parsing | 55+ combat monsters with full stat blocks | 77 monsters parsed from data | None (exceeds) | -- | -- |
| 103 | Monster spell casting | SHRIEK, BOLT, BREATH, DARKNESS, SLOW, HOLD, SCARE, CONF | Spells parsed but never cast in combat | Full gap | CRITICAL | L |
| 104 | SHRIEK spell | Raises floor alertness, wakes nearby monsters | Not implemented | Full gap | CRITICAL | S |
| 105 | BOLT spell | Ranged magic damage in a line | Not implemented | Full gap | CRITICAL | M |
| 106 | BREATH spell | Cone-shaped elemental damage | Not implemented | Full gap | CRITICAL | M |
| 107 | DARKNESS spell | Reduce light radius in area | Not implemented | Full gap | MAJOR | M |
| 108 | SLOW spell | Halve player speed for N turns | Not implemented | Full gap | MAJOR | S |
| 109 | HOLD spell | Paralyze player for N turns | Not implemented | Full gap | MAJOR | S |
| 110 | SCARE spell | Cause fear status on player | Not implemented | Full gap | MAJOR | S |
| 111 | CONF spell | Cause confusion status on player | Not implemented | Full gap | MAJOR | S |
| 112 | FIRE attack effect resolution | Burn equipment, fire damage | Only HURT/POISON resolved | Full gap | MAJOR | M |
| 113 | Group spawning (FRIENDS flag) | Spawn N similar monsters nearby | Not implemented | Full gap | MAJOR | M |
| 114 | Escort spawning (ESCORT flag) | Spawn weaker escort monsters with leader | Not implemented | Full gap | MAJOR | M |
| 115 | Boss encounter logic | Unique boss behaviors and spawn conditions | Not implemented | Full gap | MAJOR | L |
| 116 | Monster morale system | Monsters flee when morale breaks | Morale exists but limited behavior | Partial gap | MODERATE | M |
| 117 | Monster sleep/wake cycle | Monsters start asleep, woken by noise/proximity | Implemented -- SLEEPING flag parsed, `is_sleeping=true`, wake at 2 tiles, `_wake_up()` function | None | -- | -- |

---

## 7. Items & Equipment

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 118 | Item identification system | Items start as unknown, identified by use or Lore | All items fully known on pickup | Full gap | CRITICAL | L |
| 119 | Unknown item flavor names | "A shimmering blue potion" instead of "Potion of Healing" | Not implemented | Full gap | CRITICAL | M |
| 120 | Identify by use | Using an item reveals its identity | Not implemented | Full gap | CRITICAL | S |
| 121 | Lore-based identification | Lore skill check to identify on pickup | Not implemented | Full gap | MAJOR | S |
| 122 | Potion quaffing (q key) | Drink a potion from inventory for effect | Not implemented | Full gap | CRITICAL | M |
| 123 | Scroll reading (r key) | Read a scroll for magical effect | Not implemented | Full gap | CRITICAL | M |
| 124 | Scroll backfire chance | Lore-based chance of negative effect | Not implemented | Full gap | MAJOR | S |
| 125 | Food/herb eating (E key) | Consume food to restore hunger/HP | Not implemented | Full gap | CRITICAL | M |
| 126 | Hunger system | Player gets hungry over time, must eat | Not implemented | Full gap | MAJOR | L |
| 127 | Staff activation (a key) | Use a staff for magical effect | Not implemented | Full gap | MAJOR | M |
| 128 | Wand zapping | Point wand at target for ranged effect | Not implemented | Full gap | MAJOR | M |
| 129 | Horn blowing | Blow horn for area effect | Not implemented | Full gap | MAJOR | M |
| 130 | 17 staff types with effects | Each staff has unique use effect | Not implemented | Full gap | MAJOR | L |
| 131 | 6 wand types with effects | Each wand has unique zap effect | Not implemented | Full gap | MAJOR | M |
| 132 | 6 horn types with effects | Each horn has unique blow effect | Not implemented | Full gap | MAJOR | M |
| 133 | 22 potion types with effects | Healing, speed, strength, etc. | Data exists, no use code | Full gap | MAJOR | L |
| 134 | 18 herb/food types with effects | Restoration, curing, nutrition | Data exists, no use code | Full gap | MAJOR | L |
| 135 | Equipment resistance flags | Fire resist, cold resist, etc. on gear | Not checked during combat | Full gap | MAJOR | M |
| 136 | Wield weapon (w key) | Equip weapon from inventory | Uses E key in Godot, different binding | Partial gap | MODERATE | S |
| 137 | Wear armor (W key) | Equip armor from inventory | Uses E key in Godot, different binding | Partial gap | MODERATE | S |
| 138 | Take off equipment (T key) | Remove worn/wielded item | Uses R key in Godot, different binding | Partial gap | MODERATE | S |
| 139 | Inspect item (I key) | View detailed item stats and description | Not implemented (I opens inventory) | Full gap | MODERATE | M |
| 140 | Item cursing | Some items are cursed and cannot be removed | Not implemented | Full gap | MODERATE | M |
| 141 | Artifact items | Unique named items with special powers | Not implemented | Full gap | MODERATE | L |

---

## 8. Dungeon Generation

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 142 | Room and corridor generation | Procedural rooms connected by corridors | Implemented | None | -- | -- |
| 143 | 87 terrain types | Full terrain variety from terrain.txt | Only 12 tile types mapped | Major gap (75 terrains missing) | MAJOR | L |
| 144 | 96 vault templates | Pre-designed room layouts from vault data | Data parsed, vaults in data files | Partial -- need to verify vault placement code | MODERATE | M |
| 145 | Door placement | Doors placed between rooms and corridors | Implemented -- dungeon_generator places DOOR_CLOSED at 30% of corridor junctions; vaults also place doors | None | -- | -- |
| 146 | Door open/close mechanics | Player can open and close doors | Partial -- bump-to-open works (DOOR_CLOSED→DOOR_OPEN), LOS blocked by closed doors; no close command, no monster door-opening AI connected | Partial gap (close command, monster AI) | MAJOR | S |
| 147 | Locked doors | Doors that require keys or lockpicking | Not implemented | Full gap | MAJOR | M |
| 148 | Jammed doors | Doors stuck shut, require STR check to force | Not implemented | Full gap | MAJOR | S |
| 149 | Door bashing | Break down locked/jammed doors (noise!) | Not implemented | Full gap | MAJOR | S |
| 150 | 24 door type variants | Different materials, lock levels | Not implemented | Full gap | MODERATE | M |
| 151 | 13 trap types | Various trap effects beyond basic damage | Only 1 generic trap type (1d4+depth/3) | Major gap | MAJOR | M |
| 152 | Level persistence | Returning to a level preserves its state | Not implemented (levels regenerated) | Full gap | MAJOR | L |
| 153 | Boss room generation | Special rooms for boss encounters | Not implemented | Full gap | MAJOR | M |
| 154 | Staircase placement rules | Up/down stairs with distance constraints | Basic stairs exist | Partial gap | MODERATE | S |
| 155 | Water/lava terrain | Terrain that blocks or damages | Not implemented | Full gap | MODERATE | M |
| 156 | Rubble/chasms | Movement-blocking terrain variety | Not implemented | Full gap | MODERATE | S |
| 157 | Secret doors/passages | Hidden passages revealed by Perception | Not implemented | Full gap | MODERATE | M |

---

## 9. Quest & Victory

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 158 | Ring of Thrain quest | Find and return the ring | Implemented | None | -- | -- |
| 159 | Key to Erebor quest | Find the key, reach exit | Implemented | None | -- | -- |
| 160 | Rod of Istari quest | Find the rod | Implemented | None | -- | -- |
| 161 | Escape victory path | Reach surface with quest items | Implemented | None | -- | -- |
| 162 | Banishment victory path | Defeat final threat | Implemented | None | -- | -- |
| 163 | Pursuit Mode (6 phases) | Escalating pursuit after taking Ring | Not implemented | Full gap | MAJOR | XL |
| 164 | Exhaustion during escape | Fatigue accumulates during pursuit | Not implemented | Full gap | MAJOR | M |
| 165 | Victory score calculation | Complex score based on kills, depth, items, turns | Implemented -- `_calculate_score()` in both death_screen.gd and victory_screen.gd with base 100000, race challenge factor, depth bonus, escape bonus, victory bonus | None | -- | -- |
| 166 | High score table | Persistent high scores across runs | Not implemented | Full gap | MINOR | M |

---

## 10. NPC / Prisoner System

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 167 | Thrain II NPC | Dialogue, quest-giver at depth 15+ | Implemented | None | -- | -- |
| 168 | 6 prisoner types | Different prisoners with different rewards/quests | Only Thrain implemented | Full gap (5 missing) | MAJOR | L |
| 169 | Prisoner rescue mechanics | Free prisoners from cells, escort to stairs | Not implemented | Full gap | MAJOR | M |
| 170 | Prisoner dialogue variety | Each prisoner type has unique dialogue | Only Thrain dialogue exists | Full gap | MODERATE | M |
| 171 | Prisoner reward system | Prisoners give items/info/skill bonuses when freed | Not implemented | Full gap | MODERATE | M |

---

## 11. Special Mechanics

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 172 | Ring gold hallucination | Carrying the Ring causes gold hallucinations | Not implemented | Full gap | MAJOR | M |
| 173 | Morgul-wound | Permanent wound from Ringwraith, escalating penalties | Not implemented | Full gap | MAJOR | M |
| 174 | Lidless Eye | Tier 4+ Will checks for Sauron's attention | Not implemented | Full gap | MAJOR | M |
| 175 | Status effects system | Poison, blind, confused, scared, stunned, slowed, held | Partial -- generic framework exists (apply/remove/tick), 12 effects defined in Constants + EffectDefinitions with metadata/messages/severity tiers. Word of Command applies AFRAID. But behavioral integration missing: CONFUSED doesn't cause random movement, BLIND doesn't reduce FOV, SLOW doesn't halve speed, STUNNED doesn't skip turns, ENTRANCED doesn't prevent action. | Partial gap (behavioral hooks) | CRITICAL | M |
| 176 | Status effect display | Show active status effects on HUD | Not implemented | Full gap | MAJOR | M |
| 177 | Status effect duration/decay | Effects wear off over turns | Not implemented | Full gap | MAJOR | S |
| 178 | Running (Shift+direction) | Move in direction until obstacle/enemy | Not implemented | Full gap | MODERATE | M |
| 179 | Resting (5 key / period) | Wait in place, recover HP slowly | Partial -- "wait" input action bound, player can skip turn in place; no HP regeneration on rest | Partial gap (no HP regen) | MODERATE | S |
| 180 | Experience and leveling | XP from kills, level up with stat/skill gains | Partially implemented (XP exists) | Partial gap -- verify level-up grants | MODERATE | M |

---

## 12. Controls & Keybindings

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 181 | f -- Fire ranged weapon | Select target, fire arrow/bolt | Not implemented | Full gap | CRITICAL | L |
| 182 | t -- Throw item | Throw any item at target | Not implemented | Full gap | MAJOR | M |
| 183 | q -- Quaff potion | Drink potion from inventory | Not implemented | Full gap | CRITICAL | S |
| 184 | r -- Read scroll | Read scroll from inventory | Not implemented | Full gap | CRITICAL | S |
| 185 | E -- Eat food/herb | Consume food item | Not implemented | Full gap | CRITICAL | S |
| 186 | a -- Activate item | Use staff, wand, or horn | Not implemented | Full gap | MAJOR | S |
| 187 | w -- Wield weapon | Equip weapon specifically | Merged into E (equip) in Godot | Partial gap | MINOR | S |
| 188 | W -- Wear armor | Equip armor specifically | Merged into E (equip) in Godot | Partial gap | MINOR | S |
| 189 | T -- Take off equipment | Remove equipped item | Uses R in Godot | Partial gap | MINOR | S |
| 190 | I -- Inspect item | View item details | I opens inventory in Godot (different) | Full gap | MODERATE | M |
| 191 | L -- Look (canonical) | Inspect tile/monster | Uses X in Godot | Partial gap | MINOR | S |
| 192 | M -- Full map view | Display explored map | Not implemented | Full gap | MODERATE | M |
| 193 | < -- Go up stairs | Ascend staircase | Uses Enter in Godot | Partial gap | MINOR | S |
| 194 | > -- Go down stairs | Descend staircase | Uses Enter in Godot | Partial gap | MINOR | S |
| 195 | Shift+direction -- Run | Move repeatedly in direction | Not implemented | Full gap | MODERATE | M |
| 196 | 5 / . -- Rest | Wait one turn in place | Partial -- "wait" action is bound and functional (skip turn) | Partial gap (no HP regen) | MINOR | S |
| 197 | Stealth mode toggle key | Enter/exit stealth mode | Not implemented | Full gap | CRITICAL | S |
| 198 | Target selection mode | Cursor-based targeting for ranged attacks | Not implemented | Full gap | CRITICAL | L |

---

## 13. UI Completeness

| # | Feature | Canon | Godot | Gap | Priority | Complexity |
|---|---------|-------|-------|-----|----------|------------|
| 199 | HP/MP/XP status bar | Core stats displayed | Partially implemented | Verify completeness | MODERATE | S |
| 200 | Status effect indicators | Show blind/confused/poisoned/etc. | Not implemented | Full gap | CRITICAL | M |
| 201 | Monster health bars | Show monster HP in some form | Not implemented in detail | Partial gap | MODERATE | S |
| 202 | Equipment comparison | Compare held item to equipped | Not implemented | Full gap | MODERATE | M |
| 203 | Full character sheet | All stats, skills, resists on one screen | Partial (@ shows skills) | Partial gap | MODERATE | M |
| 204 | Message log scrollback | Scroll through past messages | Not implemented | Full gap | MODERATE | M |
| 205 | Minimap | Small overview map | Not implemented | Full gap | MINOR | M |
| 206 | Depth/turn counter display | Show current depth and turn number | Partially implemented | Verify | MINOR | S |
| 207 | Death screen with stats | Show cause of death, stats, kill list | Implemented -- 276-line death_screen.gd with epitaph, character info, combat stats, journey stats, achievements, final score, save dump, new game/quit options | None | -- | -- |
| 208 | Victory screen with score | Show final score breakdown | Implemented -- 323-line victory_screen.gd with victory type, story text, character info, combat stats, journey stats, achievements, final score, save dump | None | -- | -- |
| 209 | Help screen (? key) | In-game keybinding reference | Not implemented | Full gap | MODERATE | M |

---

## Priority Summary

| Priority | Count | Percentage |
|----------|-------|------------|
| CRITICAL | 30 | 30% |
| MAJOR | 55 | 56% |
| MODERATE | 24 | 24% |
| MINOR | 9 | 9% |
| **Total Gaps** | **~97** | -- |
| No Gap (implemented) | ~30 | -- |
| Validation-discovered | 5 | -- |

Note: Some items overlap across categories (e.g., archery appears in Combat, Abilities, and Controls). Unique distinct gaps number approximately 75-85. Validated through 5 iterations of spot-checking against source code. 6 false positives corrected, 5 false negatives added.

---

## Complexity Summary

| Complexity | Count | Estimated Days |
|------------|-------|----------------|
| S (< 1 day) | 48 | ~30 days |
| M (1-3 days) | 44 | ~88 days |
| L (3-7 days) | 11 | ~55 days |
| XL (1-2 weeks) | 1 | ~10 days |
| **Total** | **104** | **~183 dev-days** |

---

## Implementation Roadmap

### Phase A: Combat Foundation (est. 2-3 weeks)

Close the most impactful combat gaps first, since combat is the core gameplay loop.

1. **Status effects system** (#175) -- Foundation for everything else. Implement blind, confused, scared, stunned, slowed, held, poisoned as a generic status manager.
2. **Combat modifier stack** (#1-#11) -- Add concentration, focused attack, bane, master hunter, assassination, flanking, light penalty, charge, pit/web modifiers to the existing opposed roll.
3. **Monster attack effect resolution** (#19-#26, #112) -- Wire up FIRE, COLD, BLIND, CONFUSE, FEAR, STUN, ENTRANCE, LOSE_STR.
4. **Status effect UI** (#200, #176, #177) -- Display active effects, duration, decay.
5. **Shield block when stationary** (#14) and **weapon proficiency** (#28, #96).

### Phase B: Stealth System (est. 2 weeks)

Stealth is the second pillar of Necromancer's design and is entirely absent.

1. **Noise generation system** (#31) -- Every action produces noise.
2. **Stealth score and mode toggle** (#29, #30, #197) -- Player stealth calculation.
3. **Monster perception checks** (#32) -- d10+perception vs d10+stealth.
4. **Floor-wide alertness** (#33) -- Global alertness rises/decays.
5. **Monster sleep/wake** (#42, #117) -- Monsters start asleep.
6. **Assassination bonus** (#35, #6) -- +STL vs unwary.

### Phase C: FOV & Light Overhaul (est. 1-2 weeks)

Light interacts with combat and stealth; must follow those systems.

1. **Fog of war** (#43) -- Map starts hidden, revealed by exploration.
2. **Dynamic light radius** (#44, #48) -- Light from items, not just layer config.
3. **Darkness combat penalty** (#46) -- Wire into combat modifier stack.
4. **Torch fuel** (#45) -- Torches burn down.
5. **Inner Light ability** (#47, #90) -- Complete the deferred implementation.

### Phase D: Items & Identification (est. 2-3 weeks)

Consumables and identification are critical to the roguelike loop.

1. **Identification system** (#118, #119, #120, #121) -- Items start unknown.
2. **Potion use** (#122, #133) -- Implement quaff command and all 22 potion effects.
3. **Scroll use** (#123, #124) -- Read command with backfire.
4. **Food/herb use** (#125, #134) -- Eat command and 18 food effects.
5. **Staff/wand/horn use** (#127, #128, #129, #130, #131, #132) -- Activate command.
6. **Equipment resistances** (#135) -- Check resist flags in combat damage.
7. **Starting equipment** (#95) -- Give race/house appropriate gear at game start.

### Phase E: Archery & Ranged Combat (est. 2 weeks)

Requires target selection UI and new combat path.

1. **Target selection mode** (#198) -- Cursor-based targeting.
2. **Archery combat system** (#15, #16) -- Ranged attack rolls, evasion halving.
3. **Ammunition tracking** (#17) -- Quiver, arrow count, recovery.
4. **Throwing** (#18, #182) -- Throw any item.
5. **Fire key binding** (#181) -- f to fire.

### Phase F: Dungeon Enhancement (est. 2 weeks)

1. **Door enhancements** (#146-#150) -- Close command, lock/jam/bash mechanics, monster door AI, door type variants (basic open/placement already works).
2. **Additional terrain types** (#143, #155, #156) -- Water, lava, rubble, chasms.
3. **Level persistence** (#152) -- Save/restore level state.
4. **Trap variety** (#151) -- Implement remaining 12 trap types.
5. **Secret doors** (#157) -- Hidden passages.
6. **Boss rooms** (#153) -- Special room generation.

### Phase G: Monster Spells & AI (est. 1-2 weeks)

1. **Monster spell casting AI** (#103) -- Decision logic for when to cast.
2. **SHRIEK** (#104) -- Alertness raise.
3. **BOLT** (#105) -- Line-of-sight projectile.
4. **BREATH** (#106) -- Cone attack.
5. **Remaining spells** (#107-#111) -- DARKNESS, SLOW, HOLD, SCARE, CONF.
6. **Group spawning** (#113, #114) -- FRIENDS and ESCORT flags.

### Phase H: Abilities (est. 3-4 weeks)

Implement ability gameplay code. Many are simple modifiers once the systems exist.

1. **Perception abilities** (#82-#86) -- Feed into combat modifiers.
2. **Melee abilities** (#51-#64) -- Feed into combat actions.
3. **Evasion abilities** (#71-#80) -- Feed into defense calculations.
4. **Stealth abilities** (#81, #36-#41) -- Feed into stealth system.
5. **Archery abilities** (#65-#70) -- Feed into ranged combat.
6. **Will abilities** (#87) -- Status effect resistance.
7. **Smithing expansion** (#88) -- Additional recipes.

### Phase I: Special Systems & Polish (est. 2-3 weeks)

1. **Pursuit Mode** (#163, #164) -- 6-phase escalation after Ring.
2. **Prisoner system** (#168-#171) -- 5 additional prisoner types.
3. **Ring hallucination** (#172) -- Gold hallucination effect.
4. **Morgul-wound** (#173) -- Permanent wound mechanic.
5. **Lidless Eye** (#174) -- Will checks at depth.
6. **Character creation extras** (#94, #97-#100) -- House affinity, age, backstory.
7. **Running** (#178, #195) -- Shift+direction movement.
8. **Resting** (#179, #196) -- Wait in place.
9. **High score table** (#166) -- Persistent high scores across runs (death/victory screens and scoring already implemented).
10. **Help screen** (#209) -- Keybinding reference.
11. **Remaining keybindings** (#183-#196) -- Canonical key mapping.
12. **Message log scrollback** (#204) -- UI improvement.

---

## Validation-Discovered Gaps (False Negatives)

These gaps were not in the original analysis but were discovered during the 5-iteration validation cycle.

| # | Feature | Finding | Priority | Complexity |
|---|---------|---------|----------|------------|
| V1 | Dark tile rendering never used | TileMapper has "light" and "dark" atlas coords for all terrain, but `_get_atlas_coords_for_tile()` always calls `get_terrain_coords(tile)` with default `lit=true`. Dark variants are never rendered. Prerequisite for fog of war (#43). | CRITICAL | S |
| V2 | Monster door-opening AI disconnected | Monster.gd parses `can_open_doors` from OPEN_DOOR flag but `can_move_to()` never checks or interacts with doors. Monsters with the flag still cannot open doors. | MAJOR | S |
| V3 | Status effect behavioral hooks missing | EffectDefinitions defines 12 effects but none have behavioral integration: CONFUSED doesn't cause random movement, BLIND doesn't reduce FOV to 0, SLOW doesn't halve speed/energy, AFRAID doesn't force fleeing, STUNNED doesn't skip turns, ENTRANCED doesn't prevent action. Each needs individual wiring. | CRITICAL | L |
| V4 | Run stats display misleading zeros | Death and victory screens display `potions_quaffed`, `herbs_consumed`, `doors_closed`, `enemies_avoided`, `stealth_streak_max` -- but nothing in the game increments these counters. UI shows 0 for all. | MODERATE | S |
| V5 | Possible type mismatch in trap avoidance | `_trigger_trap()` calls `entity.get_skill(Constants.Skill.S_PER)` but Player's `get_skill()` expects a string key like `"perception"`. Trap avoidance perception checks may fail silently. | MAJOR | S |

---

## Appendix: Known Issues from Codebase

These items were identified from code comments, MEMORY.md notes, and the current TODO state.

1. **O key binding** -- Auto-explore key may need verification in project.godot input map.
2. **GPL compliance** -- DCSS tileset requires the game to be released under GPL v2+ if distributed.
3. **DataManager validation warnings** -- Reports missing monsters/races due to naming mismatches between data files and code references.
4. **RID leak on exit** -- Resource ID cleanup issue on game shutdown; non-blocking but should be resolved before release.
5. **Lore ability #142 (Deep Memory)** -- Deferred; code stub exists but no implementation.
6. **Lore ability #147 (Inner Light)** -- Deferred; code stub exists but no implementation.
7. **Monster melee_bonus** -- Recently fixed to use attack data; verify no regressions.
8. **Freed instance crashes** -- Mitigated with `is_instance_valid()` checks; may recur with new entity types.
9. **Turn system energy edge cases** -- Recently fixed; monitor for monsters acting out of order.
10. **Map visibility model** -- Entire map is visible (dimmed) rather than hidden until explored; fundamental FOV model needs rework.
11. **Starting equipment** -- Data files define starting gear per race/house but it is never granted to the player entity.
12. **House affinity** -- House selection UI works but the skill affinity bonus is not applied to the character.
13. **Abilities purchasable but inert** -- Players can spend XP on 81+ abilities that have zero gameplay effect; this is a player-facing bug.
14. **Consumable items drop but are unusable** -- Potions, scrolls, food, staves, wands, and horns can appear in inventory but have no use action.

---

## Appendix: Data File Coverage

| Data File | Records | Parsed in Godot | Used in Gameplay |
|-----------|---------|-----------------|------------------|
| Monsters | 55+ | 77 parsed | Partial (no spells, limited effects) |
| Terrain | 87 types | 12 mapped | Partial |
| Vaults | 96 templates | Parsed | Unverified placement |
| Items (weapons) | ~40 | Parsed | Used in equip/combat |
| Items (armor) | ~30 | Parsed | Used in equip/combat |
| Items (potions) | 22 | Parsed | NOT usable |
| Items (scrolls) | ~15 | Parsed | NOT usable |
| Items (staves) | 17 | Parsed | NOT usable |
| Items (wands) | 6 | Parsed | NOT usable |
| Items (horns) | 6 | Parsed | NOT usable |
| Items (food/herbs) | 18 | Parsed | NOT usable |
| Abilities | 93 | Parsed | 12 implemented |
| Races | ~8 | Parsed | Used in creation |
| Houses | ~6 | Parsed | Used in creation (no affinity) |
| Traps | 13 | 1 generic | Partial |
| Doors | 24 | 2 (open/closed) | Partial (bump-to-open, no close/lock/jam) |

---

*End of gap analysis. This document should be updated as gaps are closed.*
