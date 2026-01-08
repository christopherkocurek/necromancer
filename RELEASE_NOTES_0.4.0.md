# The Necromancer - Alpha 0.4.0
## Release Notes & Design Documentation

**Date:** January 8, 2026
**Build:** Alpha 0.4.0 - Stealth-First Economy
**Base:** SIL-Q fork, Third Age Dol Guldur setting

---

## What's New in Alpha 0.4.0

### VAULT SYSTEM REDESIGN

15 vaults redesigned for stealth-first gameplay with multiple entry points, cover, and tactical options.

#### Key Vault Changes
| Vault | Change |
|-------|--------|
| Web Choke (N:11) | Secret bypass around spider nest |
| Corrupted Grove (N:12) | Central puzzle structure |
| Scout Camp (N:17) | Sleeping quarters, multiple doors |
| Warg Den (N:23) | Isolated kennels for controlled engagement |
| Guard Room (N:34) | Multiple rooms with tactical doors |
| Mess Hall (N:36) | Secret assassination passages |
| Troll Pen (N:37) | Center passage for avoidance |
| Ghoul Pit (N:53) | Distraction areas, expanded layout |

#### Design Documents Created
- vault_catalog.md - Complete vault extraction with stealth ratings
- vault_layer_tags.md - Layer appropriateness analysis
- vault_stealth_audit.md - 0-5 stealth viability scores
- vault_boring_flags.md - Vaults needing redesign
- vault_layer1-7_proposals.md - New vault designs per layer

---

### MONSTER BALANCE PASS

Monsters adjusted for stealth gameplay with differentiated sleepiness, perception, and behavior.

#### Sleepiness Increases (Easier Stealth Targets)
| Monster | Old | New |
|---------|-----|-----|
| Warg Pup | 20 | 25 |
| Orc Slave | 20 | 25 |
| Orc Soldier | 15 | 20 |
| Hill Troll | 15 | 25 |
| Mirk-troll | 15 | 20 |
| Easterling Warrior | 15 | 20 |

#### Perception Changes (Detection Differentiation)
| Monster | Old | New | Effect |
|---------|-----|-----|--------|
| Hill Troll | 2 | 1 | Dumber, easier to sneak past |
| Mirk-troll | 3 | 2 | Slightly dumber |
| Orc Archer | 3 | 4 | More watchful |
| Orc Thrallmaster | 4 | 5 | Very alert |

#### SHRIEK Rate Changes (Alarm Priority)
| Monster | Old | New | Effect |
|---------|-----|-----|--------|
| Black Squirrel | 30% | 50% | Higher alarm priority |
| Orc Scout | 25% | 40% | More dangerous alarm |
| Giant Bat | 10% | 5% | Less annoying |

#### Flag Additions
| Monster | Flag Added | Effect |
|---------|------------|--------|
| Hill Troll | TERRITORIAL | Guards area, won't chase far |
| Mirk-troll | TERRITORIAL | Guards area, won't chase far |

#### Design Documents Created
- monster_catalog.md - Complete monster extraction
- monster_layer_tags.md - Layer assignment verification
- monster_stealth_audit.md - Sleepiness and perception analysis
- monster_gaps.md - Missing archetypes (handlers, patrols)
- monster_new_proposals.md - 15 new monster designs (for future)
- monster_prune_list.md - Pruning analysis (none needed)
- monster_modifications.md - Stat change proposals

---

### XP ECONOMY REBALANCE

Major changes to make stealth builds competitive with combat builds.

#### Kill XP Diminishing Returns (xtra2.c)
| Kill # | Old XP | New XP | Reduction |
|--------|--------|--------|-----------|
| 1st | 100% | 100% | 0% |
| 2nd | 50% | 35% | 30% |
| 3rd | 33% | 19% | 42% |
| 4th | 25% | 13% | 48% |
| 5th+ | 20%- | 9%- | 55%+ |

**Effect:** Grinding the same monster type is now unprofitable. First kills of each type remain valuable.

#### Tower Objects (New Discovery XP)
30 new collectible lore items that grant XP when discovered:

| Category | Items | XP Each | Total |
|----------|-------|---------|-------|
| Thráin's Memories | 8 | 150 | 1,200 |
| Shadow Fragments | 6 | 200 | 1,200 |
| Ancient Glyphs | 7 | 75 | 525 |
| Palantír Shards | 4 | 500 | 2,000 |
| Erebor Relics | 5 | 100 | 500 |
| **Total** | **30** | - | **~5,400** |

**Thráin's Memories** - Blue wisps in layers 3-7, tell the story of Thráin II's imprisonment

**Shadow Fragments** - Dark crystals near dangerous monsters, crystallized Sauron's power

**Ancient Glyphs** - Wall inscriptions throughout all layers, messages from past prisoners

**Palantír Shards** - Rare vault treasures, fragments of the seeing-stones

**Erebor Relics** - Dwarven heritage items stolen from the Lonely Mountain

#### XP Economy Comparison
| Playthrough | Old Total | New Total | Change |
|-------------|-----------|-----------|--------|
| Combat (clear all) | 30,000 | 26,000 | -13% |
| Stealth (avoid) | 19,000 | 23,000 | +21% |
| **Gap** | 37% | 12% | **Narrowed** |

#### Design Documents Created
- xp_research.md - Analysis of 7 roguelikes' non-combat XP
- xp_current_audit.md - Current SIL-Q XP system analysis
- tower_objects_design.md - Discovery item design
- xp_rebalance_proposal.md - Detailed rebalance plan

---

### SYNTHESIS VALIDATION

Cross-system validation ensuring all changes work together.

#### Archetype Viability
| Build | XP | Skills | Verdict |
|-------|-------|--------|---------|
| Bilbo (Pure Stealth) | 23,000 | 21 | Viable |
| Faramir (Stealth Archer) | 26,500 | 22 | Strong |
| Aragorn (Stealth Melee) | 29,500 | 23 | Strong |
| Gandalf (Stealth Lore) | 21,500 | 20 | Viable |

**All four archetypes can complete the game.**

#### Layer-by-Layer Stealth
| Layer | Pure Stealth | Combat |
|-------|--------------|--------|
| 1-2 | A | A |
| 3-4 | B+ | A |
| 5-6 | C+ | A- |
| 7 | B | B |

**Layers 4-5 remain challenging for pure stealth due to NO_SLEEP undead.**

#### Design Documents Created
- synthesis_audit.md - Cross-system analysis
- archetype_validation.md - Build playtest validation

---

## Design Philosophy

### Stealth-First
Every viable build should invest in Stealth. Infiltration is core gameplay, not optional.

### Layer Identity
Each of the 7 layers feels distinct:
1. **Forest Breach** - Spiders, poison, webs, alarm creatures
2. **Orc Warrens** - Military orcs, wargs, organized resistance
3. **Torture Halls** - Sorcerers, ghouls, control effects
4. **Necropolis** - Undead, necromancers, NO_SLEEP challenge
5. **Wraith Domain** - Spirits, fear, Will-based survival
6. **Inner Sanctum** - Elite enemies, final challenges
7. **Pits of Despair** - Extraction gameplay, Sauron

### Exploration Over Combat
XP rewards discovery and objectives, not grinding kills.

### Fewer Bigger Monsters
Vaults have fewer but more meaningful enemies.

### Tolkien Grounded
Third Age power scale. Aragorn-tier ceiling.

---

## Known Issues

### Not Yet Implemented
- Handler/Beast mechanics (design only in monster_new_proposals.md)
- Patrol behavior (design only)
- SLEEPING flag guarantee (design only)
- Custom vault monster placement

### Balance Concerns
- Layers 4-5 may be too hard for pure stealth (undead NO_SLEEP)
- Tower Objects spawn via allocation tables, not custom placement
- Some vaults may need further iteration

---

## THE LIST - Future Work

### Alpha 0.5.0 (Planned)
- [ ] Handler flag implementation (kill handler → beasts flee)
- [ ] SLEEPING flag implementation (guarantee sleep state)
- [ ] Layer 4-5 non-undead stealth targets
- [ ] Song vs Undead options for Lore builds
- [ ] Custom Tower Object placement in vaults

### Medium Priority
- [ ] Patrol behavior implementation
- [ ] Stealth kill bonus XP
- [ ] Track and reward successful evasions
- [ ] More sleeping variants for deep layers

### Low Priority
- [ ] Alert/escalation system (Cogmind-style)
- [ ] Non-lethal takedown options
- [ ] Clause/achievement system

---

## File Changes Summary

### Modified
- lib/edit/vault.txt - 15 vaults redesigned
- lib/edit/monster.txt - Sleepiness, perception, SHRIEK, flags
- lib/edit/object.txt - 30 Tower Objects added
- src/xtra2.c - Kill XP diminishing returns formula

### New Documents (docs/design/)
- vault_catalog.md, vault_layer_tags.md, vault_stealth_audit.md
- vault_boring_flags.md, vault_layer1-7_proposals.md
- monster_catalog.md, monster_layer_tags.md, monster_stealth_audit.md
- monster_gaps.md, monster_new_proposals.md, monster_prune_list.md
- monster_modifications.md
- xp_research.md, xp_current_audit.md, tower_objects_design.md
- xp_rebalance_proposal.md
- synthesis_audit.md, archetype_validation.md

---

## Technical Details

### Kill XP Formula Change (xtra2.c)
```c
// Old
exp = (mexp) / (mkills + 1);

// New - Steeper diminishing returns
if (mkills == 0) exp = mexp;
else if (mkills == 1) exp = mexp * 35 / 100;
else if (mkills == 2) exp = mexp * 19 / 100;
else if (mkills <= 5) exp = mexp / (divisor * 2);
else exp = mexp / (divisor * 3);
```

### Tower Objects (object.txt)
Using TV_NOTE (tval 2) with unique svals:
- sval 50-57: Thráin's Memories
- sval 60-65: Shadow Fragments
- sval 70-76: Ancient Glyphs
- sval 80-83: Palantír Shards
- sval 90-94: Erebor Relics

---

## Credits

Design & Development: Christopher Kocurek
AI Assistance: Claude (Anthropic)
Base Game: SIL-Q by sil-quirk
Original Sil: half.net

---

*"There is no light, but there is hope. The shadow of the past can be reforged into the light of the future."*
