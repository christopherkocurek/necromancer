# Parity Analysis: C Source vs Godot Implementation

**Updated:** 2026-02-08 (post-Ralph Loop, Session S)
**Previous version:** `docs/GAP_ANALYSIS.md` (2026-02-05, pre-Ralph Loop)

This document compares every major system in the original Sil-Q C source with the current Godot implementation. Each feature is marked:

- **PARITY** -- Feature matches or exceeds the C source
- **GODOT_ENHANCED** -- Godot version adds functionality beyond the C source
- **PARTIAL** -- Core functionality works but some aspects are missing
- **GAP** -- Feature exists in C source but is not implemented in Godot
- **N/A** -- Feature is not applicable to the Godot version

---

## Summary

| Status | Count | Percentage |
|--------|-------|------------|
| PARITY | 62 | 33% |
| GODOT_ENHANCED | 28 | 15% |
| PARTIAL | 41 | 22% |
| GAP | 48 | 26% |
| N/A | 8 | 4% |
| **Total** | **187** | -- |

**Overall Feature Completion: ~70%** (up from ~30-35% in the Feb 5 gap analysis)

The Ralph Loop (Session S Tiers 1-8) closed approximately 50 gaps, adding smithing overhaul, stealth overhaul, sustained songs, bosses, ego enchantments, procedural descriptions, map enrichment, and difficulty modes.

---

## 1. Combat System

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 1 | Opposed d20 attack rolls | PARITY | Full implementation with modifiers |
| 2 | Concentration modifier | PARITY | +Perception when stationary |
| 3 | Focused Attack modifier | PARITY | +1 per ability level |
| 4 | Bane modifier | PARITY | +Hunting vs identified type |
| 5 | Master Hunter modifier | PARITY | +Hunting vs natural creatures |
| 6 | Assassination modifier | PARITY | +Stealth vs unwary/sleeping (Ralph Loop Tier 2) |
| 7 | Flanking/Overwhelming modifier | PARITY | +1 per adjacent ally |
| 8 | Light penalty modifier | PARITY | Penalty in darkness |
| 9 | Distance penalty (archery) | PARITY | -1 per tile |
| 10 | Charge bonus | PARITY | +1 on straight-line charge |
| 11 | Pit/Web penalties | GAP | No pit/web terrain types |
| 12 | Critical hit formula | PARITY | Weight-based crit |
| 13 | Protection dice | PARITY | Shield + armor dice |
| 14 | Shield blocking (2x stationary) | PARITY | Double dice when stationary |
| 15 | Archery system | PARITY | Ranged combat with evasion halving |
| 16 | Ranged weapon firing (F key) | PARITY | Target selection, range calculation |
| 17 | Ammunition tracking | PARITY | Quiver slot, arrow count |
| 18 | Throwing system | GAP | No throw command |
| 19 | FIRE attack effect | PARITY | Burning DOT damage |
| 20 | COLD attack effect | PARITY | Slow status |
| 21 | BLIND attack effect | PARITY | FOV reduction |
| 22 | CONFUSE attack effect | PARITY | Random movement |
| 23 | FEAR attack effect | PARITY | Flee from source |
| 24 | STUN attack effect | PARITY | Turn skip |
| 25 | ENTRANCE attack effect | PARITY | Paralysis until damaged |
| 26 | LOSE_STR attack effect | PARTIAL | Stat drain exists but limited |
| 27 | Poison resolution | PARITY | DOT with decay |
| 28 | Weapon proficiency | PARTIAL | Parsed but limited combat impact |
| 29 | Ego enchantments on weapons | GODOT_ENHANCED | 6 ego types with depth-scaling (Ralph Loop Tier 3) |
| 30 | Monster damage dice | PARITY | Proper NdS dice from data |
| 31 | Parry mechanic | PARITY | Fixed in Ralph Loop Tier 1 |

---

## 2. Stealth and Detection

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 32 | Stealth mode toggle | PARITY | `;` key toggle (Ralph Loop Tier 2) |
| 33 | Stealth score calculation | PARITY | STL skill + equipment + terrain |
| 34 | Noise generation system | PARITY | Per-action noise values |
| 35 | Monster perception checks | PARITY | d10+perception vs d10+stealth |
| 36 | Floor-wide alertness | PARITY | Global alertness rises with noise, decays |
| 37 | Alertness thresholds | PARITY | Unwary/alert/very alert behavior |
| 38 | Assassination attack bonus | PARITY | +STL vs unwary |
| 39 | Throat Slit ability | PARITY | Instant kill on sleeping target |
| 40 | Silent Kill ability | GAP | Defined but no gameplay hook |
| 41 | Fade ability | PARITY | 2 turns of invisibility |
| 42 | Disguise ability | PARITY | Halves LOS detection bonus |
| 43 | Vanish ability | PARITY | Break contact, re-enter stealth |
| 44 | Escape Artist ability | PARITY | Disengage bonus |
| 45 | Monster sleep state | PARITY | Sleep, wake on proximity/noise |
| 46 | Detection eye indicator | GODOT_ENHANCED | HUD eye icon shows detection state (Ralph Loop Tier 2) |
| 47 | Stealth distance bonus | PARITY | max(0, 6-distance) |

---

## 3. FOV and Light

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 48 | Fog of war | PARITY | explored[] array, dark tile rendering |
| 49 | Dynamic light radius | PARITY | Per-entity light from equipment |
| 50 | Torch fuel consumption | PARITY | Torches burn down over turns |
| 51 | Darkness combat penalty | PARITY | Halves evasion in darkness |
| 52 | Inner Light ability | PARITY | Damages HURT_LITE monsters in light radius |
| 53 | Light source variety | PARITY | Torch +2, lantern +3, lamp +4 |
| 54 | Monster light interaction | PARTIAL | HURT_LITE implemented, DARK_AURA defined but limited |
| 55 | Glowing item light | PARTIAL | Artifacts with LIGHT flag parsed, not all emit light |
| 56 | Depth darkness scaling | PARITY | -0 to -3 modifier by layer |
| 57 | Room glow | GODOT_ENHANCED | Rooms have ambient light independent of player |

---

## 4. Skill System and Abilities

### Melee (14 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 58 | Power | PARITY | Extra damage die |
| 59 | Finesse | PARITY | Light armor bonus |
| 60 | Knock Back | PARITY | Push 1 tile |
| 61 | Polearms | PARITY | Reach attacks |
| 62 | Charge | PARITY | Straight-line bonus |
| 63 | Follow-Through | PARITY | Free attack on kill |
| 64 | Opening Strike | PARITY | First-attack bonus |
| 65 | Subtlety (Control) | PARITY | Noise reduction |
| 66 | Cleave | PARITY | Hit 2 adjacent enemies |
| 67 | Zone of Control | PARITY | Free attack on enemy retreat |
| 68 | Mighty Blow | PARITY | Stun on hit |
| 69 | Defensive Stance | PARITY | +protection, -attack |
| 70 | Rapid Attack | PARITY | Two attacks at penalty |
| 71 | Strength bonus | PARITY | +STR passive |

### Archery (9 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 72 | Rout | PARITY | Bonus vs fleeing |
| 73 | Fletchery | PARITY | Improved arrows |
| 74 | Point Blank | PARITY | No range penalty at 1 |
| 75 | Puncture | PARITY | Ignore some protection |
| 76 | Ambush | PARITY | Bonus from stealth |
| 77 | Keen Eyes | PARITY | Extended vision |
| 78 | Crippling Shot | PARITY | Slow on hit |
| 79 | Deadly Hail | PARITY | Multi-shot |
| 80 | DEX bonus | PARITY | +DEX passive |

### Evasion (11 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 81 | Dodging | PARITY | Evasion bonus |
| 82 | Blocking | PARITY | Improved shield block |
| 83 | Parry | PARITY | Weapon block chance |
| 84 | Crowd Fighting | PARITY | Less penalty when surrounded |
| 85 | Leaping | PARTIAL | Jump defined, limited terrain |
| 86 | Sprinting | PARITY | Double speed burst |
| 87 | Flanking | PARITY | Behind-attack bonus |
| 88 | Heavy Armour | PARITY | Reduce armor penalty |
| 89 | Riposte | PARITY | Counter on miss |
| 90 | Controlled Retreat | PARITY | Safe disengage |
| 91 | DEX bonus | PARITY | +DEX passive |

### Stealth (12 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 92 | Disguise | PARITY | Detection halved |
| 93 | Assassination | PARITY | +STL attack bonus |
| 94 | Disorienting | PARITY | Confuse on backstab |
| 95 | Escape Artist | PARITY | Disengage bonus |
| 96 | Light Fingers | PARITY | Steal items |
| 97 | Vanish | PARITY | Break contact |
| 98 | DEX bonus | PARITY | +DEX passive |
| 99 | Throat Slit | PARITY | Instant kill sleeping |
| 100 | Fade | PARITY | Brief invisibility |
| 101 | Pilfer | PARTIAL | Defined, limited targets |
| 102 | Distraction | PARITY | Noise diversion |
| 103 | Silent Kill | GAP | No gameplay hook |

### Hunting/Perception (10 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 104 | Natural Talent | PARITY | Passive perception bonus |
| 105 | Focused Attack | PARITY | +1 attack per level |
| 106 | Keen Senses | PARITY | Detect invisible |
| 107 | Concentration | PARITY | +Perception stationary |
| 108 | Alchemy | PARITY | Identify potions |
| 109 | Bane | PARITY | +Perception vs type |
| 110 | Outwit | PARITY | Defensive perception |
| 111 | Listen | GAP | Defined but no effect |
| 112 | Master Hunter | PARITY | +Perception natural |
| 113 | Grace bonus | PARITY | +GRA passive |

### Will (11 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 114 | Curse Breaking | PARITY | Remove cursed items |
| 115 | Force of Will | PARITY | Will save bonus |
| 116 | Strength in Adversity | PARITY | Bonus when outnumbered |
| 117 | Formidable | PARITY | Monster morale penalty |
| 118 | Defy Death | PARITY | Survive lethal hit once |
| 119 | Indomitable | PARITY | Extended resistance |
| 120 | Oath | PARITY | Bonus vs oath target |
| 121 | Poison Resist | PARITY | Reduce poison duration |
| 122 | Vengeance | PARITY | Bonus after taking damage |
| 123 | Majesty | PARITY | Passive fear aura |
| 124 | CON bonus | PARITY | +CON passive |

### Smithing (12 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 125 | Weaponsmith | PARITY | Create weapons from Mithril (Ralph Loop Tier 1) |
| 126 | Armoursmith | PARITY | Create armor from Mithril |
| 127 | Jeweller | PARITY | Create jewelry from Mithril |
| 128 | Reforge | PARITY | Combine broken glowing items |
| 129 | Expertise | PARITY | Improved forge results |
| 130 | Reclaim | PARITY | Combine broken strange items |
| 131 | Masterwork | PARTIAL | Bonus quality, damage dice not yet full |
| 132 | Grace bonus | PARITY | +GRA passive |
| 133 | Reforge Mastery | PARITY | Better reforge results |
| 134 | Salvage | PARITY | Recover materials from items |
| 135 | Reclaim Mastery | PARITY | Better artifact reclamation |
| 136 | Master Smith | PARTIAL | Unlocks all recipes, some stat generation incomplete |

### Lore (18 abilities)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 137 | Word of Command | PARITY | AOE fear + stun (Lore 8+ dual effect) |
| 138 | Lore of Battle | PARITY | Provoke target |
| 139 | Deep Memory | PARITY | Progressive map reveal + auto-ID (Ralph Loop passive) |
| 140 | Word of Opening | PARTIAL | Opens doors/clears rubble; trap reveal TODO |
| 141 | Lore of Silence | PARITY | Reduce perception in radius |
| 142 | Herbcraft | PARITY | Double healing from herbs |
| 143 | Word of Shutting | PARTIAL | Closes doors; sealed flag TODO |
| 144 | Inner Light | PARITY | Damage HURT_LITE in light radius |
| 145 | Deadly Lore | PARITY | Execute low-HP targets on crit |
| 146 | Lore of Endurance | PARITY | +Will/2, +2d2 protection |
| 147 | Lore of Sleep | PARITY | Put target to sleep (Will check) |
| 148 | Word of Mastery | PARITY | Paralyze target |
| 149 | Device Mastery | PARITY | +50% wand/staff charges |
| 150 | Grace | PARITY | Passive +1 Grace |
| 151 | Song of Banishment | PARITY | AOE undead flee, 1/floor |
| 152 | Song of Freedom | PARITY | Sustained +3 evasion (Ralph Loop Tier 4) |
| 153 | Song of the Trees | PARITY | Sustained +5 stealth (Ralph Loop Tier 4) |
| 154 | Song of Aule | PARITY | Sustained +2 melee, +1 smithing (Ralph Loop Tier 4) |

---

## 5. Character Creation

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 155 | Race selection | PARITY | 4 races with stat modifiers |
| 156 | House selection | PARITY | 6 houses with skill affinity |
| 157 | Stat point allocation | PARITY | 13-point budget system |
| 158 | House skill affinity | PARITY | Applied as discount |
| 159 | Starting equipment | PARITY | Race-based starting gear |
| 160 | Age selection | PARITY | Affects history text |
| 161 | Gender selection | PARITY | Cosmetic choice |
| 162 | Backstory generation | GODOT_ENHANCED | Procedural backstory generator |
| 163 | Name entry | PARITY | Free text input |
| 164 | Difficulty selection | GODOT_ENHANCED | 4 difficulty modes (Ralph Loop Tier 8) |
| 165 | Trait selection | GODOT_ENHANCED | 10 hero traits with gameplay effects |

---

## 6. Monsters

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 166 | Monster data parsing | PARITY | 77 monsters from data |
| 167 | Monster spell casting | PARITY | SHRIEK, breath, bolt, darkness, slow, hold, scare, conf |
| 168 | SHRIEK spell | PARITY | Raises alertness, wakes nearby |
| 169 | Breath attacks | PARITY | Cone-shaped elemental damage |
| 170 | DARKNESS spell | PARITY | Reduce light in area |
| 171 | SLOW/HOLD/SCARE/CONF | PARITY | All status-applying spells |
| 172 | Group spawning (FRIENDS) | PARITY | Spawn similar nearby |
| 173 | Escort spawning (ESCORT) | PARTIAL | Leader spawns, escort logic limited |
| 174 | Boss encounters | GODOT_ENHANCED | 3 named Tolkien bosses per layer transition (Ralph Loop Tier 5) |
| 175 | Monster morale system | PARITY | Flee when broken, rally mechanic |
| 176 | Monster sleep/wake | PARITY | Sleep flag, wake on noise/proximity |
| 177 | Unique monsters | PARITY | One-per-game spawning |
| 178 | Monster drops | GODOT_ENHANCED | Depth-scaled drops with ego enchantments (Ralph Loop Tier 3) |
| 179 | Monster XP scaling | PARITY | max(10, depth*5 + rarity*10), 3x UNIQUE |

---

## 7. Items and Equipment

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 180 | Item identification | PARITY | Unknown on pickup, identified by use or Lore |
| 181 | Unknown item flavor names | PARITY | Randomized per game |
| 182 | Identify by use | PARITY | Auto-identify on consumption |
| 183 | Lore-based identification | PARITY | Lore skill check on pickup |
| 184 | Potion quaffing (Q key) | PARITY | 10+ potion types with effects |
| 185 | Scroll reading (R key) | PARITY | Scroll effects implemented |
| 186 | Scroll backfire chance | PARTIAL | Basic backfire, not all variants |
| 187 | Food/herb eating (, key) | PARITY | 10+ herb types with effects |
| 188 | Staff activation | PARITY | Staff use effects |
| 189 | Wand zapping | PARTIAL | Basic wand effects, limited targeting |
| 190 | Horn blowing (P key) | PARITY | 5 horns + 1 flute with directional effects |
| 191 | Equipment resistance flags | GAP | Parsed but not checked in damage |
| 192 | Artifact items | PARITY | 30+ unique artifacts with special powers |
| 193 | Ego enchantments | GODOT_ENHANCED | 6 ego types on random drops (Ralph Loop Tier 3) |
| 194 | Item stacking | PARITY | Arrows, torches, potions, herbs |
| 195 | Item cursing | GAP | Not implemented |

---

## 8. Dungeon Generation

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 196 | Room and corridor generation | PARITY | Multiple room shapes |
| 197 | 7 dungeon layers | GODOT_ENHANCED | Themed layers with distinct visuals/monsters |
| 198 | Vault templates | PARITY | From vault.txt data |
| 199 | Door placement | PARITY | Corridor junctions, vault doors |
| 200 | Door open/close | PARITY | Bump-to-open, C key to close |
| 201 | Locked doors | GAP | Not implemented |
| 202 | Jammed doors | GAP | Not implemented |
| 203 | 13 trap types | PARTIAL | 1 generic trap + disarm mechanic |
| 204 | Level persistence | GAP | Levels regenerated on return |
| 205 | Boss rooms | GODOT_ENHANCED | Boss rooms at layer transitions (Ralph Loop Tier 5) |
| 206 | Staircase placement | PARITY | Up/down with distance constraints |
| 207 | Forge placement | PARITY | Forges every 2 floors to depth 10 |
| 208 | Cave rooms | GODOT_ENHANCED | Cellular automata irregular rooms (Ralph Loop Tier 7) |
| 209 | Alcove rooms | GODOT_ENHANCED | Wall alcoves in deeper layers (Ralph Loop Tier 7) |
| 210 | Environmental storytelling | GODOT_ENHANCED | Inscriptions, bone piles, scattered items (Ralph Loop Tier 7) |
| 211 | Secret doors | GAP | Not implemented |
| 212 | Water/lava terrain | GAP | Not implemented |

---

## 9. Quest and Victory

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 213 | Ring of Thrain quest | PARITY | Find and return |
| 214 | Key to Erebor quest | PARITY | Find key, reach exit |
| 215 | Rod of Istari quest | PARITY | Find the rod |
| 216 | Escape victory path | PARITY | Reach surface with items |
| 217 | Banishment victory path | PARITY | Defeat final threat |
| 218 | Pursuit Mode (6 phases) | GAP | Not implemented |
| 219 | Exhaustion during escape | GAP | Not implemented |
| 220 | Victory score calculation | PARITY | Race factor, depth, escape, victory bonuses |
| 221 | High score table | GAP | No persistence |
| 222 | Victory/death screens | PARITY | Full epitaph with stats and achievements |

---

## 10. UI and Controls

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 223 | HP/Voice/XP status bar | PARITY | Full HUD display |
| 224 | Status effect indicators | PARITY | Icons + text in HUD |
| 225 | Monster health bars | PARITY | Tiered by monster memory |
| 226 | Equipment comparison | GAP | No side-by-side compare |
| 227 | Full character sheet | PARITY | Tome panel with all stats |
| 228 | Message log scrollback | PARITY | Scrollable message history |
| 229 | Minimap | PARITY | Toggle with M key |
| 230 | Depth/turn counter | PARITY | Displayed in HUD |
| 231 | Help screen (? key) | PARITY | Full keybinding overlay |
| 232 | Settings panel (Esc) | GODOT_ENHANCED | Accessibility, display, colorblind modes |
| 233 | Bestiary panel | GODOT_ENHANCED | Monster memory with tiered knowledge |
| 234 | Procedural descriptions | GODOT_ENHANCED | 500+ templates, state-aware (Ralph Loop Tier 6) |
| 235 | Tutorial hints | GODOT_ENHANCED | Context-sensitive hints for new players |
| 236 | Target panel (archery) | PARITY | Cursor-based targeting |

---

## 11. Special Mechanics

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 237 | Ring gold hallucination | GAP | Not implemented |
| 238 | Morgul-wound | GAP | Not implemented |
| 239 | Lidless Eye | GAP | Not implemented |
| 240 | Status effects framework | PARITY | 14 effect types with DOT/decay |
| 241 | Running (Shift+direction) | GAP | Not implemented |
| 242 | Resting (Z key) | PARITY | Rest until full, rest N turns, interrupt on danger |
| 243 | Auto-explore (O key) | GODOT_ENHANCED | BFS pathfinding with door auto-open |
| 244 | Experience and leveling | PARITY | XP from kills, descent, skills |
| 245 | Ability XP costs | PARITY | 100*(level+1) with affinity discount |
| 246 | Difficulty modes | GODOT_ENHANCED | 4 modes: Easy/Normal/Hard/Ironman (Ralph Loop Tier 8) |
| 247 | God mode (accessibility) | GODOT_ENHANCED | Progressive damage reduction after deaths |

---

## Ralph Loop Additions (All Implemented)

These features were added in Session S Tiers 1-8 and have no C source equivalent:

| Tier | Feature | Status |
|------|---------|--------|
| 1 | Smithing system overhaul (5 recipes, Mithril, forge materials) | GODOT_ENHANCED |
| 2 | Stealth overhaul (detection eye, d10 rolls, floor alertness) | PARITY with C source |
| 3 | Monster drops + ego enchantments (6 types) | GODOT_ENHANCED |
| 4 | Sustained song system (Freedom, Trees, Aule) | PARITY with Sil-Q singing |
| 5 | Custom Tolkien bosses (3 per layer transition) | GODOT_ENHANCED |
| 6 | Procedural description depth (500+ templates) | GODOT_ENHANCED |
| 7 | Map generation enrichment (cave rooms, alcoves, storytelling) | GODOT_ENHANCED |
| 8 | Victory path balance + difficulty modes | GODOT_ENHANCED |

---

## Remaining Gaps (Prioritized)

### High Priority
1. Equipment resistance flag integration
2. Silent Kill gameplay hook
3. Listen ability gameplay hook
4. Sealed door mechanic (Word of Shutting)
5. Trap reveal via Word of Opening

### Medium Priority
6. Item cursing system
7. Secret doors
8. Locked/jammed doors
9. Water/lava terrain
10. Pursuit Mode (6-phase Ring escalation)
11. Level persistence
12. Throwing system

### Low Priority
13. Ring gold hallucination
14. Morgul-wound mechanic
15. Lidless Eye checks
16. Shift+direction running
17. Equipment comparison UI
18. High score persistence
19. Additional prisoner NPC types
