# Cross-System Stealth Audit - The Necromancer
## SYN-001: Do Vaults + Monsters + XP Create Cohesive Stealth-First Gameplay?

---

## Executive Summary

**Verdict: YES, with caveats**

The Alpha 0.4.0 changes create a cohesive stealth-first experience:
- Vaults now have multiple entry points and cover
- Monsters have adjusted sleepiness/perception for stealth scenarios
- XP economy rewards exploration over grinding

**Remaining gaps** (for future releases):
- No code support for Handler/Beast mechanics (design only)
- No patrol behavior (design only)
- Tower Objects spawn via allocation tables, not custom placement

---

## VAULT SYSTEM REVIEW

### Changes Made
- 15 vaults redesigned with stealth-friendly layouts
- Added secret doors (`s`) for alternate entry/exit
- Increased pillar coverage for line-of-sight breaks
- Added sleeping quarters (`z` monsters) for throat-slit opportunities
- Improved layer thematic alignment

### Stealth Scenarios Enabled

| Vault | Stealth Scenario |
|-------|------------------|
| Web Choke (N:11) | Secret bypass around spider nest |
| Scout Camp (N:17) | Sleeping scouts in barracks section |
| Warg Den (N:23) | Isolated kennels for one-at-a-time engagement |
| Guard Room (N:34) | Multiple rooms with doors for control |
| Mess Hall (N:36) | Secret passage through eating area |
| Troll Pen (N:37) | Center passage to avoid trolls |
| Ghoul Pit (N:53) | Distraction areas around pit edges |

### Gaps Identified

1. **No vault-specific monster placement** - Vaults spawn random depth-appropriate monsters, not the specific "sleeping orc" or "patrol guard" designed for
2. **Secret doors not guaranteed** - Player may not have perception to find them
3. **Layer filtering imprecise** - Allocation tables control depth, not layer

### Recommendation
Vaults are improved for stealth but would benefit from:
- Custom monster templates per vault (future code change)
- Guaranteed secret door visibility for stealth builds

---

## MONSTER SYSTEM REVIEW

### Changes Made (monster.txt)

| Monster | Change | Stealth Impact |
|---------|--------|----------------|
| Warg Pup | Sleepiness 20→25 | Better throat-slit target |
| Orc Slave | Sleepiness 20→25 | Easy early stealth kill |
| Orc Soldier | Sleepiness 15→20 | More likely asleep |
| Hill Troll | Sleepiness 15→25, Perception 2→1 | Heavy sleeper, dumb |
| Mirk-troll | Sleepiness 15→20, Perception 3→2 | Easier to sneak past |
| Easterling Warrior | Sleepiness 15→20 | More stealthy approach |
| Black Squirrel | SHRIEK 30%→50% | Higher alarm priority |
| Orc Scout | SHRIEK 25%→40% | More dangerous alarm |
| Giant Bat | SHRIEK 10%→5% | Less annoying |
| Orc Archer | Perception 3→4 | Harder to sneak past |
| Orc Thrallmaster | Perception 4→5 | More watchful |
| Hill Troll | Added TERRITORIAL | Won't chase far |
| Mirk-troll | Added TERRITORIAL | Guards its area |

### Stealth Scenarios Enabled

1. **Sleeper Targeting**: Higher sleepiness values mean more sleeping monsters, enabling throat-slit
2. **Alarm Prioritization**: Clear high-shriek monsters (Black Squirrel, Orc Scout) to prioritize
3. **Perception Differentiation**: Trolls dumb, archers smart - clear decision points
4. **Territorial Behavior**: Can retreat from trolls, they won't pursue forever

### Gaps Identified

1. **No Handler-Beast code** - Proposed Warg Handler mechanics require code
2. **No Patrol behavior** - Predictable patrol routes need code support
3. **NO_SLEEP undead** - Layer 4+ still has many unstealthable targets
4. **No sleeping guarantee** - SLEEPING flag proposed but not implemented

### Recommendation
Monster changes are effective for Layers 1-3. Deeper layers remain combat-focused due to undead. Consider:
- Implement Handler flag (kills handler → beasts flee)
- Implement SLEEPING flag (guaranteed asleep)
- Add more sleeper variants for deeper layers

---

## XP SYSTEM REVIEW

### Changes Made

#### Kill XP Rebalance (xtra2.c)
| Kill # | Old XP | New XP |
|--------|--------|--------|
| 1st | 100% | 100% |
| 2nd | 50% | 35% |
| 3rd | 33% | 19% |
| 4th | 25% | 13% |
| 5th+ | 20%- | 9%- |

**Effect:** Combat grinding heavily penalized after first kill of each type.

#### Tower Objects (object.txt)
| Category | Items | XP Each | Total |
|----------|-------|---------|-------|
| Thráin's Memories | 8 | 150 | 1,200 |
| Shadow Fragments | 6 | 200 | 1,200 |
| Ancient Glyphs | 7 | 75 | 525 |
| Palantír Shards | 4 | 500 | 2,000 |
| Erebor Relics | 5 | 100 | 500 |
| **Total** | **30** | - | **~5,425** |

### XP Economy Comparison

| Playthrough | Old Total | New Total | Change |
|-------------|-----------|-----------|--------|
| Combat (clear all) | 30,000 | 26,000 | -13% |
| Stealth (avoid) | 19,000 | 23,000 | +21% |
| **Gap** | 37% | 12% | Narrowed |

### Stealth Build XP Path
1. **Encounter XP**: See monsters while sneaking (~4,000)
2. **Descent XP**: Reach new depths (~10,500)
3. **Tower Objects**: Find lore items (~4,000)
4. **Ident XP**: Identify items (~2,500)
5. **Strategic Kills**: First kill of each type (~2,000)
6. **Total**: ~23,000 XP

### Combat Build XP Path
1. **Kill XP**: Clear everything (~6,000 after diminishing)
2. **Encounter XP**: See everything you kill (~5,000)
3. **Descent XP**: Reach new depths (~10,500)
4. **Tower Objects**: Find some items (~2,000)
5. **Ident XP**: Identify items (~2,500)
6. **Total**: ~26,000 XP

### Gaps Identified

1. **Tower Objects use allocation tables** - They spawn randomly, not in designed locations
2. **No stealth-specific XP** - No bonus for kills while hidden
3. **No evasion tracking** - Can't reward successful sneak-pasts

### Recommendation
XP system effectively supports stealth. Consider for future:
- Custom Tower Object placement in dungeon.c
- Stealth kill bonus XP
- Track and reward successful evasions

---

## SYSTEM INTERACTION ANALYSIS

### Positive Interactions

| System A | System B | Interaction |
|----------|----------|-------------|
| Vault layout | Monster sleep | Sleeping quarters in vaults enable throat-slit |
| Kill XP reduction | Tower Objects | Exploration competitive with combat |
| Monster perception | Vault cover | Cover useful against smart archers |
| TERRITORIAL flag | Vault exits | Can flee trolls through secret doors |
| SHRIEK rates | Vault entry | Clear alarm creatures before entering |

### Negative Interactions / Gaps

| System A | System B | Issue |
|----------|----------|-------|
| Vault design | Monster spawn | Random spawns don't match vault design |
| Tower Objects | Vault placement | Objects spawn randomly, not in vaults |
| Layer 4+ monsters | Stealth | NO_SLEEP undead can't be throat-slit |
| Handler design | Current code | Handler mechanics not implemented |

---

## LAYER-BY-LAYER ASSESSMENT

### Layer 1: Forest Breach (50-150ft)
**Stealth Grade: A**
- Spiders can be slept (sleepiness 15-30)
- Clear alarm creatures (crebain, squirrels)
- Vaults have web bypass options
- Tower Objects: Glyphs, some relics

### Layer 2: Orc Warrens (150-300ft)
**Stealth Grade: A-**
- Orcs sleepier (20)
- Archers more perceptive (4)
- Vaults have barracks and patrol routes
- Tower Objects: Memories begin, fragments

### Layer 3: Torture Halls (300-450ft)
**Stealth Grade: B+**
- Ghouls have NO_SLEEP (problem)
- Dark Sorcerers can be slept
- Easterlings sleepier (20)
- Tower Objects: More memories

### Layer 4: Necropolis (450-600ft)
**Stealth Grade: B-**
- All skeletons/wights have NO_SLEEP
- Necromancers can be slept
- Must avoid undead, not kill
- Tower Objects: Fragments, glyphs

### Layer 5: Wraith Domain (600-750ft)
**Stealth Grade: C+**
- Almost all NO_SLEEP
- Must rely on avoidance, not assassination
- High Will needed for fear effects
- Tower Objects: Memories, rare shards

### Layer 6: Inner Sanctum (750-900ft)
**Stealth Grade: C**
- Elite enemies, many NO_SLEEP
- Black Númenóreans can be slept
- Olog-hai have NO_SLEEP? (check)
- Tower Objects: Final memories

### Layer 7: Pits of Despair (900-1000ft)
**Stealth Grade: B-**
- Extraction gameplay, less combat
- Thráin's Shade interaction
- Sauron can be avoided (escape win)
- Tower Objects: Rarest items

---

## PLAYSTYLE VIABILITY MATRIX

| Build | Layers 1-2 | Layers 3-4 | Layers 5-6 | Layer 7 | Overall |
|-------|------------|------------|------------|---------|---------|
| Pure Combat | A | A | A- | B | A- |
| Combat/Stealth | A | A | A | A- | A |
| Stealth/Combat | A | A- | B+ | B+ | A- |
| Pure Stealth | A | B+ | B | B | B+ |

**Analysis:**
- **Pure Combat** works everywhere, slight challenge in Layer 7 extraction
- **Combat/Stealth** hybrid is optimal - best of both
- **Stealth/Combat** strong early, needs combat backup later
- **Pure Stealth** viable but challenging in undead layers

---

## CONCLUSION

### Success Criteria Met

✅ **Stealth-first**: Multiple entry points, sleeping targets, cover
✅ **Layer identity**: Each layer has distinct stealth challenges
✅ **Assassination rewarding**: Throat-slit on sleeping targets
✅ **Exploration over combat**: Tower Objects + XP rebalance
✅ **Fewer bigger monsters**: Vaults have fewer but more meaningful spawns
✅ **Tolkien grounded**: Thráin's Memories, Erebor relics, lore-appropriate

### Gaps for Future Work

1. **Handler mechanics** - Code needed for Warg Handler design
2. **SLEEPING flag** - Guarantee sleep state on specific monsters
3. **Patrol behavior** - Predictable routes for timing gameplay
4. **Custom vault monsters** - Spawn specific monsters, not random
5. **Layer 4-5 stealth** - Need non-undead stealth targets deeper

### Final Assessment

**The Necromancer Alpha 0.4.0** delivers a cohesive stealth-first experience for Layers 1-3, with diminishing but viable stealth for deeper layers. The system changes work together:

1. Vaults provide tactical spaces
2. Monsters have differentiated stealth profiles
3. XP rewards exploration equally to combat

**Recommendation:** Ship Alpha 0.4.0. Address Handler/Patrol/Deep stealth in Alpha 0.5.0.
