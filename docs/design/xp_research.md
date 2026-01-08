# XP System Research: Non-Combat Progression in Roguelikes

## Context: Sil-Q's Current System

Sil-Q already has a sophisticated multi-source XP system:
- **encounter_exp**: XP for encountering (seeing) monsters for the first time
- **kill_exp**: XP for killing monsters
- **descent_exp**: XP for descending to new dungeon levels (50 * depth)
- **ident_exp**: XP for identifying items (100 per identification)

This research examines how other roguelikes handle non-combat progression to inform potential improvements for stealth-first gameplay.

---

## Caves of Qud

### Overview
Caves of Qud is a science-fantasy roguelike set in a far-future Earth with extensive exploration and quest systems.

### Primary XP/Progression Sources
1. **Quest completion** - Primary XP source, often large rewards
2. **Combat kills** - Standard monster kill XP
3. **Exploration discoveries** - Finding new locations grants XP
4. **Secrets and lore** - Reading Sultan history, finding artifacts
5. **Water rituals** - Social interactions with factions

### Non-Combat XP Opportunities
- **Water rituals**: Gaining faction reputation grants XP and abilities
- **Quest XP**: Many quests can be completed without combat through dialogue, stealth, or item use
- **Discovery XP**: Finding named locations, historic sites
- **Learning secrets**: Examining artifacts, reading lore
- **Skill training**: Can gain abilities through faction standing

### Stealth/Pacifist Viability
- **High viability**: Many quests have non-violent solutions
- Stealth mutations (Photosynthetic Skin, Burrowing Claws for escape)
- Domination allows controlling enemies without killing
- Sprint and movement abilities enable avoidance
- **True pacifist runs are possible** but challenging

### Discovery/Exploration XP
- Named locations grant one-time XP bonus
- Sultan shrines provide lore XP
- Finding historic sites grants exploration XP
- Deferred XP: Some discoveries unlock quests worth more XP

### Lessons for Stealth-First Design
1. **Quest systems provide combat-equivalent XP** - Completing objectives matters more than body count
2. **Faction systems** - Social progression path parallel to combat
3. **Discovery as reward** - Finding things is intrinsically rewarded
4. **Multiple solutions** - Same goal achievable through different paths

---

## Cogmind

### Overview
Cogmind is a sci-fi roguelike where you play as a robot building yourself from salvaged parts. Notable for its emphasis on non-combat options.

### Primary XP/Progression Sources
Cogmind has **no traditional XP system**. Progression is entirely equipment-based:
1. **Part acquisition** - Finding better parts (weapons, utilities, propulsion)
2. **Slot expansion** - Gaining more equipment slots
3. **Prototype discovery** - Finding unique high-end parts
4. **Ally acquisition** - Recruiting robot allies

### Non-Combat Rewards
- **Hacking rewards**: Terminal access provides maps, intel, allies
- **Stealth completion bonuses**: Lower alert = better ending tiers
- **Part preservation**: Not fighting means keeping your current loadout
- **Machine control**: Reprogram enemies rather than destroy them
- **Exploration rewards**: Finding hidden areas with prototype parts

### Stealth/Pacifist Viability
- **Extremely high viability** - Designed as equal option to combat
- Alert level system: Combat raises global alert, making game harder
- "Pacifist" endings exist and are considered higher achievements
- Stealth-focused builds (flight, cloaking, sensor jamming) are meta
- Combat is often **punished** through alert escalation

### Discovery/Exploration XP
- No XP, but exploration yields:
  - Better parts in hidden areas
  - Intel for planning routes
  - Access to optional areas with prototypes
  - Lore terminals that unlock story

### Lessons for Stealth-First Design
1. **Alert/consequence systems** - Combat has costs beyond the immediate fight
2. **Equipment as progression** - Items can replace XP entirely
3. **Stealth as optimal** - Non-combat can be the "better" path, not just viable
4. **Hacking/interaction systems** - Alternative engagement with environment
5. **No kill XP eliminates grind incentive** - You don't need to clear rooms

---

## DCSS (Dungeon Crawl Stone Soup)

### Overview
DCSS is a highly-refined traditional roguelike known for iterative design and removing "unfun" elements.

### Primary XP/Progression Sources
1. **Monster kills** - Primary XP source
2. **Exploration** - DCSS removed exploration XP in older versions
3. **No quest XP** - Purely monster-driven
4. **XP penalty for popcorn** - Weak enemies give reduced XP

### Non-Combat XP Opportunities
- **Very limited** - DCSS is combat-focused
- XP is almost entirely from killing
- Some branches give completion bonuses (runes)
- Piety (god favor) from non-combat acts, but not XP

### Stealth/Pacifist Viability
- **Moderate** - Stealth builds viable, pacifist not really
- Strong stealth mechanics (stabbing from stealth)
- **Stabbers** are a common build archetype
- But you still need to kill for XP
- No true pacifist option due to mandatory fights

### Discovery/Exploration XP
- **Removed in modern versions**
- Previously had auto-explore XP
- Removed because it encouraged tedious full exploration
- Current philosophy: XP from engagement, not geography

### Lessons for Stealth-First Design
1. **Exploration XP can be problematic** - Can encourage tedious behavior
2. **Stabber archetype** - Stealth enabling combat, not avoiding it
3. **Popcorn penalty** - Diminishing returns on weak enemies
4. **DCSS chose not to support pacifist** - Not every game needs it
5. **XP scarcity creates tension** - Limited XP makes choices matter

---

## Brogue

### Overview
Brogue is a minimalist roguelike focused on elegant, interconnected systems with no traditional XP.

### Primary Progression Sources
Brogue has **no experience points or levels**:
1. **Equipment discovery** - Finding weapons, armor, staffs, wands
2. **Enchantment scrolls** - Upgrade items (main progression)
3. **Ally recruitment** - Empowerment scrolls to buff allies
4. **Depth reached** - Deeper = harder but better loot

### Non-Combat Rewards
- **Item discovery** - Every item potentially valuable
- **Ally preservation** - Keeping allies alive (they share XP equivalent)
- **Resource management** - Conserving consumables is rewarding
- **Environmental manipulation** - Using terrain, gas, etc.

### Stealth/Pacifist Viability
- **Moderate** - Stealth rings, invisibility potions exist
- No XP incentive to kill
- But mandatory fights exist (some bosses, tight corridors)
- Allies can do fighting for you
- **Pacifist-ish possible** with ally builds

### Discovery/Exploration XP
- No XP system at all
- Exploration rewarded through:
  - Item discovery (enchantment scrolls, equipment)
  - Finding the way down
  - Discovering secrets (hidden rooms)

### Lessons for Stealth-First Design
1. **No XP is viable** - Progression through items alone works
2. **Enchantment consolidation** - Fewer, more impactful upgrades
3. **No grind incentive** - Without kill XP, no reason to clear rooms
4. **Elegant minimalism** - Fewer systems, deeper interactions
5. **Stealth as resource** - Invisibility consumables, not skills

---

## NetHack

### Overview
NetHack is a classic roguelike known for extreme complexity and interaction depth.

### Primary XP/Progression Sources
1. **Monster kills** - Primary XP source
2. **Quest completion** - Major XP rewards
3. **Level-based milestones** - Intrinsic abilities at certain levels
4. **No exploration XP** - Geography doesn't grant XP

### Non-Combat XP Opportunities
- **Very limited direct XP** - Almost all from kills
- But many alternative progression paths:
  - **Polypiling** - Transform items without combat
  - **Wishing** - Bypass normal progression
  - **Prayer** - Divine intervention
  - **Sacrifice** - God favor from corpses (requires killing though)

### Stealth/Pacifist Viability
- **Technically possible** - Famous "pacifist" conducts
- Pet kills don't count as your kills for conduct
- Can use pets, conflict, boulder-throwing
- **Level drain is major concern** - Vampires, wraiths can reduce level
- Must balance XP gain vs level drain risk

### Discovery/Exploration XP
- None directly
- But exploration yields:
  - Items (scrolls, potions, wands)
  - Shop access
  - Altar access (critical for some strategies)
  - Special room benefits

### Lessons for Stealth-First Design
1. **Level drain creates XP anxiety** - Must maintain buffer
2. **Conducts/achievements** - Community-driven challenge modes
3. **Pet/ally combat** - Indirect kills as compromise
4. **Extreme emergent complexity** - Many unintended pacifist solutions
5. **Intrinsic abilities** - Level-gated powers incentivize XP

---

## Invisible Inc.

### Overview
Invisible Inc. is a turn-based tactical stealth game with roguelike elements, entirely built around stealth.

### Primary Progression Sources
1. **Credits (money)** - From mission objectives, safes, guards
2. **Agent recruitment** - Acquiring new playable characters
3. **Equipment purchase** - Between-mission shopping
4. **Program unlocks** - Hacking abilities

### Non-Combat Rewards
- **Objective completion** - Primary reward, often stealth-required
- **Safe cracking** - Credits without combat
- **Hacking** - PWR (power) from consoles
- **Stealth bonuses** - Not raising alarm gives better options
- **Guard avoidance** - Unconscious guards wake, dead guards raise alarm

### Stealth/Pacifist Viability
- **100% designed for stealth** - Combat is a failure state
- Killing guards has permanent consequences
- Weapons mostly non-lethal (tasers, darts)
- **Lethal force raises alarm permanently**
- Pacifist is the intended playstyle

### Discovery/Exploration XP
- Exploration reveals:
  - Safes (credits)
  - Consoles (PWR)
  - Exit locations
  - Guard patrol routes
- No XP, but information is crucial

### Lessons for Stealth-First Design
1. **Alarm escalation** - Global threat increases over time
2. **Combat as failure** - Design where killing is suboptimal
3. **Information economy** - Knowing enemy positions is reward
4. **Non-lethal options** - Give players ways to neutralize without killing
5. **Turn economy** - Time pressure encourages efficiency over thoroughness
6. **Reversible vs irreversible** - Unconscious enemies vs dead ones

---

## Heat Signature

### Overview
Heat Signature is a top-down infiltration game with roguelike structure, offering stealth as one of several viable approaches.

### Primary Progression Sources
1. **Mission completion** - Primary currency
2. **Character liberation** - Unlocks new starting characters
3. **Equipment acquisition** - Found and purchased gadgets
4. **Clause completion** - Bonus objectives for extra rewards

### Non-Combat Rewards
- **Ghost clause** - Bonus for not being seen
- **Pacifist clause** - Bonus for not killing
- **No alarms clause** - Bonus for clean infiltration
- **Objective-only** - Only objective completion required

### Stealth/Pacifist Viability
- **Excellent** - Multiple viable approaches
- Stealth gadgets: teleporters, cloaks, subverters
- Non-lethal: concussive weapons, subverter (mind control)
- **Pacifist is rewarded** - Extra clauses = extra rewards
- Ghost runs have highest skill ceiling

### Discovery/Exploration XP
- Ship exploration yields:
  - Equipment caches
  - Intel terminals
  - Alternative routes
- No exploration XP, but environmental rewards

### Lessons for Stealth-First Design
1. **Clauses as optional challenges** - Bonus rewards for clean play
2. **Multiple gadget approaches** - Lethal, non-lethal, stealth all viable
3. **Stealth as highest skill** - Ghost runs for experts
4. **Objective focus** - Kill everyone or kill no one, just complete goal
5. **Procedural challenge** - Random ship layouts test adaptability

---

## Summary: Key Design Patterns

### XP Source Comparison

| Game | Kill XP | Quest XP | Discovery XP | Social XP | No XP |
|------|---------|----------|--------------|-----------|-------|
| Caves of Qud | Yes | Yes (primary) | Yes | Yes | - |
| Cogmind | No | - | Equipment | - | Yes |
| DCSS | Yes (primary) | No | Removed | No | - |
| Brogue | - | - | - | - | Yes |
| NetHack | Yes (primary) | Yes | No | No | - |
| Invisible Inc | - | Credits | - | - | Yes |
| Heat Signature | - | Completion | - | - | Yes |

### Stealth Viability Ranking

1. **Invisible Inc** - Designed for stealth, combat punished
2. **Cogmind** - Stealth optimal, combat raises alert
3. **Heat Signature** - Stealth rewarded via clauses
4. **Caves of Qud** - Multiple paths, stealth viable
5. **Brogue** - No kill incentive, but mandatory fights
6. **DCSS** - Stabber builds, but kill-focused
7. **NetHack** - Possible via conducts, not designed for it

### Recurring Design Patterns

#### 1. Alert/Escalation Systems
Games that support stealth often have **global consequences for combat**:
- Cogmind: Alert level increases enemy response
- Invisible Inc: Alarm clock raises threat each turn
- Heat Signature: Alarms call reinforcements

**Lesson**: Combat should have costs beyond the immediate fight.

#### 2. Objective-Based Rewards
Several games reward **completing goals, not kills**:
- Caves of Qud: Quest completion is primary XP
- Heat Signature: Mission completion, clauses for bonuses
- Invisible Inc: Objective completion only

**Lesson**: XP/rewards tied to objectives, not body count.

#### 3. Equipment as Progression
Some games bypass XP entirely:
- Brogue: Enchantment scrolls only
- Cogmind: Parts define capability
- Heat Signature: Gadgets determine options

**Lesson**: Items can provide all progression, eliminating grind incentive.

#### 4. Non-Lethal Options
Stealth-viable games provide **alternatives to killing**:
- Invisible Inc: Tasers, darts
- Heat Signature: Concussive weapons, subverters
- Cogmind: Hacking, machine reprogramming

**Lesson**: Give players tools to neutralize without killing.

#### 5. Discovery/Exploration Rewards
When implemented well, exploration rewards:
- Are one-time (no repeated grinding)
- Yield items or information, not necessarily XP
- Encourage thorough exploration without tedium

**Lesson**: Exploration XP works if bounded and meaningful.

---

## Recommendations for Sil-Q

### Current Strengths
Sil-Q already has:
1. **encounter_exp** - XP for seeing monsters (discovery)
2. **descent_exp** - XP for reaching new depths (exploration)
3. **ident_exp** - XP for identifying items (interaction)
4. **Separate tracking** - Can analyze play patterns

### Potential Enhancements

#### 1. Expand Encounter XP
- Award full encounter XP for **evading** an alert monster
- Rationale: Successfully sneaking past = demonstrating competence

#### 2. Add Stealth-Specific XP
- **evasion_exp**: XP for escaping combat (vanishing, fleeing successfully)
- **objective_exp**: XP for reaching specific dungeon features

#### 3. Alert/Consequence System
- Global alert level that rises with combat
- Higher alert = more monsters, more aggressive behavior
- Incentivizes stealth over clearing rooms

#### 4. Non-Lethal Options
- Distraction items (thrown stones, noise makers)
- Sleep/stun effects that don't kill
- XP for neutralizing without killing?

#### 5. Discovery XP Refinements
- XP for finding special rooms (vaults, treasure rooms)
- XP for reaching new areas via alternate routes
- Cap or diminishing returns to prevent grind

#### 6. Clause/Achievement System
- Track stealth achievements (floors without combat, monsters evaded)
- Bonus XP or rewards for clean completion
- End-game scoring that values stealth

### Design Principles from Research

1. **Combat should have costs** - Beyond just HP/resources
2. **Objectives matter more than kills** - Tie rewards to goals
3. **Stealth should be optimal, not just viable** - Reward it explicitly
4. **Information is valuable** - Knowing enemy positions is its own reward
5. **One-time discovery rewards** - Exploration XP bounded, not grindable
6. **Non-lethal tools** - Let players choose to spare enemies
7. **Track player patterns** - Sil-Q's separate XP tracking is excellent

---

## References

- Caves of Qud Wiki: Experience system, water rituals
- Cogmind Developer Blog: Design philosophy on stealth
- DCSS Changelog: Exploration XP removal rationale
- Brogue Design Notes: No-XP philosophy
- NetHack Conducts: Pacifist community challenges
- Invisible Inc GDC Talk: Alarm clock design
- Heat Signature Developer Commentary: Clause system
