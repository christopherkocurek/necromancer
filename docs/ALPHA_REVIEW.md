# The Necromancer -- Alpha Review Report

**Reviewer:** Independent Roguelike Analysis (Claude Opus 4.6)
**Date:** 2026-02-08
**Build:** Post-Alpha Canonical (commit `7ca63b9`, 45 commits, 162 files, 58k+ lines)
**Data Sources:** 320 automated bot playthroughs (120 v1 + 200 v2), GDD v2.0, Parity Analysis, Known Issues log

---

## 1. Executive Summary

The Necromancer is an ambitious Sil-Q successor rebuilt from scratch in Godot 4.6, targeting a Third Age Tolkien setting with 20 dungeon floors, 93 abilities across 8 skill trees, 4 playable races, and dual victory conditions. The mechanical foundation is solid: opposed d20 combat, d10 stealth checks, an XP-as-currency economy, and a well-structured 7-layer dungeon all work correctly. However, 320 automated bot playthroughs across two generations of increasingly sophisticated AI have produced a 0% win rate with no bot surviving past floor 6, revealing a severe early-game lethality problem that sits at the center of every balance concern. The project is at approximately 70% feature parity with the Sil-Q C source and approximately 92% of the game loop is functional. This is a credible alpha that needs targeted balance work and a handful of critical system completions before it becomes a playable beta.

---

## 2. Bot Testing Methodology Assessment

### 2.1 What Was Built

The Necromancer's automated testing infrastructure is unusually mature for an alpha roguelike. The system consists of:

- **A GDScript survival bot** (`tests/bot/survival_bot.gd`) that runs headlessly via Godot's `--headless` mode, bypasses character creation, and executes a priority-based decision loop each turn
- **10 archetype configurations** (`tests/bot/archetype_configs.gd`) covering all 4 races with distinct stat allocations, trait selections, and skill investment strategies
- **A bash harness** (`scripts/analysis/run_harness.sh`) using `xargs -P4` for parallel execution with deterministic seeding, per-run timeouts, and JSON telemetry extraction
- **A Python analysis pipeline** (`scripts/analysis/analyze_results.py`) that aggregates JSON results into per-archetype statistics and generates the balance report

### 2.2 How It Compares to Industry Practice

This approach has direct precedent in the roguelike community:

- **DCSS** uses "arena mode" and automated mutation testing to validate monster balance, but relies primarily on online server telemetry from thousands of human players for balance data. The Necromancer's approach is closer to DCSS's pre-release balance methodology.
- **Brogue** used a similar automated bot during development (Pender's "autoplay" mode) to validate difficulty curves, though Brogue's bots were simpler (pure greedy pathfinding).
- **Cogmind** uses internal playtest automation for regression detection but not balance tuning.
- **Sil/Sil-Q** relied almost entirely on human playtesting via the Angband ladder community.

The Necromancer's two-generation approach -- v1 bots with basic combat only, then v2 bots with stealth/songs/abilities/kiting -- is methodologically sound. It provides a lower-bound estimate of game difficulty (bots are strictly worse than competent humans) and has already caught a critical bug (ranged attacks checking the wrong equipment slot).

### 2.3 Strengths of the Approach

1. **Deterministic seeding** allows exact reproduction of any run for debugging
2. **Rich telemetry** (30+ tracked metrics per run including per-floor breakdowns) provides granular data beyond simple win/loss
3. **Archetype coverage** tests the full build diversity space, not just one "meta" build
4. **Parallel execution** (4x) makes 200-run experiments feasible in under 30 minutes
5. **Two generations of bot intelligence** create a methodological bracket: v1 (combat-only floor) to v2 (full toolkit ceiling)

### 2.4 Limitations and Blind Spots

1. **No tactical positioning intelligence.** The bot does not use chokepoints, doorway fighting, or corridor kiting -- the bread and butter of experienced roguelike play. In Sil-Q, fighting in corridors (where only one monster can attack you) is arguably the single most important survival technique. The bot's lack of this creates a floor-of-difficulty estimate that is artificially high.

2. **No multi-turn planning.** The bot uses a per-turn priority system rather than planning sequences like "lure monster into corridor, close door behind me, heal, re-engage." Human players routinely chain 5-10 actions into tactical sequences.

3. **Stealth implementation appears broken at the telemetry level.** The v2 balance report shows STEALTH_ASSASSIN with 0 combats avoided, 0 stealth kills, and 0 detections -- despite being a stealth-focused archetype. STEALTH_PURE shows 97.3 combats avoided but also 0 stealth kills. This suggests the stealth bot successfully avoids monsters but never exploits stealth for offensive advantage (assassination, throat slit). The assassin archetype appears to not be using stealth at all, despite having it in its skill priorities.

4. **Smithing is untestable.** The SMITH archetype visits 2.8 forges per run but achieves 0 successful forges and 0 items forged. This could reflect a bot pathing issue (visiting forge tiles without having materials) or a system-level problem (forge success formula not triggering). Either way, the smithing system has zero empirical validation.

5. **No item identification intelligence.** Bots equip upgrades but do not appear to use potions/herbs strategically beyond basic healing. The item economy data (0.6-1.6 items per run) suggests bots are barely interacting with the loot system.

6. **Sample sizes are uneven.** LORE_MAGE and SMITH got 50 runs each; the other 4 archetypes got 25 each. For statistical significance at a 0% win rate this does not matter much, but once win rates rise above 0%, the 25-run archetypes will have wide confidence intervals.

### 2.5 Recommendations for Bot Testing

- **Add corridor-fighting logic** as a v3 upgrade. This single change would likely be the largest driver of improved bot survival, and would provide a much more realistic difficulty floor.
- **Add item-use intelligence** -- quaffing unidentified potions when desperate, eating herbs before they rot.
- **Diagnose the assassin stealth gap** -- the STEALTH_ASSASSIN should be using Assassination and Throat Slit against unwary targets.
- **Run Easy difficulty** alongside Normal to validate difficulty mode scaling.
- **Target 500+ runs per archetype** once the game is closer to beta, for statistical confidence at low win rates.

---

## 3. Balance Analysis

### 3.1 The Numbers in Context

The headline finding -- 0% win rate across 320 runs -- needs careful interpretation.

**Reference roguelike win rates:**

| Game | Experienced Player Win Rate | Bot/Autoplay Win Rate | Notes |
|------|----------------------------|----------------------|-------|
| Sil-Q | ~2-5% (experienced) | Not publicly tested | Ladder data from sil.amirrorclear.net |
| DCSS | ~1-3% (all players), ~30-50% (top streakers) | Arena mode not applicable | Crawl server telemetry |
| Brogue | ~5-10% (experienced) | ~0.5% (autoplay) | Pender's published autoplay data |
| NetHack | ~1% (all players), ~90%+ (top players) | N/A | Extreme skill ceiling |
| Angband | ~1-2% (experienced) | N/A | Ladder data |

The Necromancer's 0% bot win rate is consistent with traditional roguelike difficulty -- Brogue's much simpler autoplay bot also achieves sub-1% win rates. The concern is not the win rate itself but the **depth distribution**: no bot survives past floor 6 of 20. This means 70% of the game's content (floors 7-20) is untested by any automated system.

### 3.2 The Floor 1-3 Kill Zone

The attrition data tells a clear story:

| Floor | Best Archetype Survival | Worst Archetype Survival |
|-------|------------------------|--------------------------|
| 1 | 100% (all) | 100% (all) |
| 2 | 62% (LORE_MAGE) | 24% (RANGER_STEALTH_ARCHER) |
| 3 | 46% (LORE_MAGE) | 16% (SMITH) |
| 4 | 12% (RANGER_STEALTH_ARCHER) | 4% (SMITH) |
| 5 | 6% (LORE_MAGE) | 0% (3 archetypes) |
| 6 | 4% (RANGER_MARKSMAN) | 0% (4 archetypes) |

The floor 1-to-2 transition is the hardest check in the game: **38-76% of all runs end on floor 1.** For comparison, in Sil-Q, the first 50 feet (approximately floors 1-2 equivalent) have roughly 30-40% attrition for new players but under 10% for experienced players. In DCSS, the D:1-D:3 attrition rate for non-trivial species is around 15-25%.

This suggests that either (a) floor 1 monsters are overtuned relative to starting player power, (b) the bot is catastrophically bad at floor 1 (possible, given no corridor-fighting), or (c) the floor 1 monster population (spiders, bats, orc scouts per the spawn table) deals too much burst damage before the player can respond.

### 3.3 The XP Starvation Problem

The data reveals a vicious cycle:

1. Bots kill 1.8-3.5 monsters per run (average across archetypes)
2. Floor 1 monsters yield ~15 XP each (at `depth*5 + rarity*10`)
3. Total combat XP earned: approximately 30-50 XP per run
4. Cost of a single skill point (level 0 to 1): 100 XP
5. Starting XP: 5,000

This means bots start with enough XP to invest in skills but earn almost nothing from combat. The 5,000 starting XP is the entire early-game economy. If a bot invests poorly (or if the starting XP is consumed by expensive early skill points), there is no way to recover through play.

In Sil-Q, the first few floors provide enough XP from exploration, identification, and weak monsters to meaningfully advance 2-3 skills. The Necromancer's descent XP (depth * 50 = 50 XP for reaching floor 2) is modest, and identification XP (10-25 per item) requires actually finding and using items -- which the bots barely do (0.6-1.6 items per run).

### 3.4 The Healing Gap

The item economy data reveals a critical survival bottleneck:

| Archetype | Avg Damage Taken | Avg Healing Done | Healing/Damage Ratio |
|-----------|-----------------|------------------|---------------------|
| LORE_MAGE | 48 | 115 | 2.4x |
| SMITH | 91 | 23 | 0.25x |
| RANGER_MARKSMAN | 45 | 5 | 0.11x |
| STEALTH_PURE | 37 | 3 | 0.08x |

The LORE_MAGE is the only archetype with a positive healing ratio, and it achieves this through **467 average rest turns** -- resting for voice regeneration, which implies resting for HP regeneration too. Every other archetype takes far more damage than it heals, meaning combat is a one-way attrition ratchet.

In Sil-Q, the early game provides herbs (healing, restoration) and the rest mechanic. Rest healing appears to be working (the LORE_MAGE uses it extensively), but non-caster archetypes are not resting enough. This is likely a bot behavior issue rather than a systems issue, but it highlights that **rest is the primary healing mechanic** and any archetype that cannot rest safely is doomed.

### 3.5 The v1 to v2 Delta

Comparing v1 (120 runs, basic combat only) to v2 (200 runs, full ability usage):

| Metric | v1 Avg | v2 Avg | Change |
|--------|--------|--------|--------|
| Win Rate | 0% | 0% | No change |
| Best Avg Depth | 2.2 (TANK) | 2.3 (LORE_MAGE) | +0.1 |
| Best Max Depth | 6 (RANGER) | 6 (LORE_MAGE, RANGER_MARKSMAN) | No change |
| Avg Turns | 44-316 | 91-596 | +100-280 |

The v2 bots survive **longer in turns** (especially LORE_MAGE at 596 vs v1's 106) but barely advance **deeper**. This suggests that the v2 improvements (rest-to-80%, flee-at-30%, consumable use) extend survival duration on the floors the bot reaches but do not enable progression to new floors. The bottleneck is not turn-by-turn survival but floor-transition survivability -- the monsters on each new floor are a step function in difficulty that the bot cannot overcome through incremental improvements.

---

## 4. Archetype Viability

### 4.1 Tier List (Based on Bot Data)

**Tier 1 -- Functional:**
- **LORE_MAGE** (Elf/Lothlorien, GRA 7): Best avg depth (2.3), best turns survived (596), only archetype with positive healing ratio. Deep Memory provides 20.8 map reveals per run. Word of Command used 3.2 times per run. The voice system and rest-for-voice loop actually works as a survival engine.

**Tier 2 -- Struggling:**
- **STEALTH_PURE** (Hobbit/Tooks, DEX 8): Second-best avg depth (2.1), high turn count (288), and 97.3 combats avoided per run proves the stealth system works for evasion. But 0 stealth kills means the archetype cannot convert stealth advantage into offensive output.
- **STEALTH_ASSASSIN** (Hobbit/Tooks, DEX 7): Decent avg depth (1.8) and max depth (5), but 0 combats avoided and 0 stealth kills suggests the assassin behavior is not engaging stealth properly.

**Tier 3 -- Non-Functional:**
- **RANGER_MARKSMAN** (Man/Dunedain, DEX 5): 0.4 avg ranged shots per run. The ranged system was broken in v1 (wrong equipment slot check) and appears barely functional in v2. The archetype should be firing 10-20+ arrows per run to be viable.
- **RANGER_STEALTH_ARCHER** (Man/Dunedain, DEX 5): Same ranged issues, 0.5 avg shots per run.
- **SMITH** (Dwarf/Erebor, CON 7): 2.8 forges visited, 0 successful forges. The smithing system is completely non-functional in practice. Despite high CON (which should provide survivability), the archetype underperforms because its intended power budget (forged equipment) never materializes.

### 4.2 What the Tiers Tell Us

The archetype data reveals that **only the voice/lore system** and **passive stealth avoidance** are functioning as designed. Every other specialized system -- ranged combat, active stealth (assassination), and smithing -- is either broken or has such severe usability issues that a sophisticated bot cannot make them work.

This is a critical finding. It means the game effectively has one viable playstyle (caster/lore) and one partially viable playstyle (pure stealth avoidance) rather than the 6+ intended archetypes.

### 4.3 Comparison to Sil-Q Archetype Balance

In Sil-Q, the viable archetype spectrum is significantly broader:

- **Melee fighters** are the most reliable path for new players
- **Stealth assassins** are the most efficient for experienced players (highest win rates on the ladder)
- **Archers** are viable but require careful resource management
- **Smiths** are the slowest but most consistent build for experienced players
- **Song builds** are high-risk/high-reward with the steepest learning curve

The Necromancer's data inverts this: melee fighters (the intended "beginner build") die fast, while the lore caster (high-skill-cap build) performs best. This inversion suggests that raw combat stats are undervalued relative to utility abilities, which is the opposite of Sil-Q's balance philosophy where "hit things and don't die" is always a viable fallback.

---

## 5. Systems Analysis

### 5.1 Combat System -- Functional, Possibly Overtuned for Monsters

The opposed d20 roll system is correctly implemented and matches Sil-Q's formula. The concern is not the formula but the numbers going into it.

**Starting player melee bonus:** A Man of Gondor with STR 4, Melee 0 has a melee bonus of approximately +2 (STR/2 + skill + equipment). Starting weapon (Curved Sword) provides reasonable damage dice.

**Floor 1 monster attack/evasion:** Without access to the exact monster data, the attrition curves suggest that floor 1 monsters have attack/evasion values high enough that 30-40% of encounters are lethal or near-lethal for a fresh character. In Sil-Q, 50 feet monsters (the equivalent) are deliberately weak enough that a starting character can kill them in 2-3 hits while taking 1-2 hits -- providing a learning zone.

**Recommendation:** Audit floor 1-2 monster stats against starting player stats. The attack/evasion gap should allow a fresh character with zero skill investment to win 70-80% of 1v1 fights on floor 1. Currently, the data suggests this rate is closer to 40-50%.

### 5.2 Stealth System -- Mechanically Sound, Offensively Broken

The d10 stealth check system is well-designed and correctly implemented. STEALTH_PURE's 97.3 combats avoided per run proves that stealth avoidance works. The distance bonus (`max(0, 6-distance)`) creates appropriate risk/reward for how close you approach monsters.

The problem is entirely on the offensive side:

- **0 stealth kills across all stealth archetypes** means Assassination (the +Stealth attack bonus vs unwary targets) is either not being triggered or not being effective enough to convert hits into kills
- **0 Throat Slit uses** means the instant-kill-on-sleeping mechanic is not being activated
- **Silent Kill has no gameplay hook** (confirmed in Known Issues)

The stealth system currently functions as a pure avoidance tool. In Sil-Q, stealth is a powerful offensive tool: sneak up to a sleeping monster, Throat Slit it for an instant kill, use Vanish to re-enter stealth, repeat. This loop is the core of Sil-Q's stealth assassin playstyle and is not functioning in The Necromancer.

### 5.3 Sustained Songs -- Implemented, Underutilized

The three sustained songs (Freedom +3 evasion, Trees +5 stealth, Aule +2 melee/+1 smithing) are implemented and toggle correctly. The bot telemetry shows 0.7 songs started per LORE_MAGE run, which is extremely low for a build that should be singing constantly.

**Song of the Trees (+5 stealth)** is particularly powerful -- it is equivalent to 5 levels of Stealth skill while active, at a cost of 1 voice/turn. With a GRA 7 character's voice pool of ~72 charges and regeneration of ~0.48/turn, Song of the Trees can be sustained for approximately 140 turns before voice is depleted. This should be the default state for any lore-invested stealth character. The bot's 0.7 uses suggests it activates songs only rarely.

**Song of Freedom (+3 evasion)** is the combat equivalent -- +3 evasion is worth approximately 3 levels of Evasion skill, a substantial defensive buff. The GDD notes that this value "needs mechanical grounding" and is arbitrary. In Sil-Q, Song of Elbereth provides variable evasion based on Song skill level, making it scale naturally. A fixed +3 is fine for alpha but should eventually scale with Lore level (suggested: `+1 + Lore/4`).

**Song of Aule (+2 melee, +1 smithing)** at 2 voice/turn is reasonably costed and is the best-grounded of the three songs, directly supporting the smithing playstyle.

### 5.4 Smithing System -- Structurally Present, Functionally Broken

The smithing system has been overhauled in Session S Tier 1 with 5 recipe types, Mithril materials, and a success formula of `min(smithing * 8, 95)`. However, the bot data shows 0 successful forges across all runs despite 2.8 forge visits per SMITH run.

Possible causes (not mutually exclusive):

1. **No materials available.** The GDD states forge materials spawn within 3 tiles of each forge (1-3 items). If the bot reaches forges but the material spawns are not working, forging cannot happen.
2. **Material identification failure.** Materials are identified by name substring ("mithril", "fragment", "ore", etc.). If the data files do not consistently use these substrings, the system will not recognize valid materials.
3. **Bot cannot interact with forge.** The forge interaction may require specific input that the bot does not simulate.
4. **Smithing skill too low.** At Smithing 0, success rate is 0%. At Smithing 1, it is 8%. The bot needs to invest in Smithing first -- but if it dies before earning enough XP, the system is never tested.

Beyond the immediate bot issue, the Known Issues document confirms that **smithing only grants attack/evasion bonuses** -- missing damage dice, parry values, weight, and protection dice. This means even if forging worked, the crafted items would be underwhelming compared to random drops with ego enchantments. This is identified as the "most broken feature" in the project memory and should be the highest-priority systems work.

### 5.5 Voice/Lore System -- The Working Engine

The voice system is the best-functioning advanced system in the game. Key evidence:

- LORE_MAGE uses 27.8 abilities per run (3.2 Word of Command + 20.8 Deep Memory + other)
- 467 average rest turns for voice regeneration shows the rest-regen loop works
- LORE_MAGE has the best survival metrics of any archetype

**Word of Command** is flagged as potentially overpowered: AOE fear + stun at Lore 8+, 3 voice cost, radius 2 + Lore/4. With a GRA 7 character at Lore 8 (reachable with starting XP), the radius is 4 tiles and the Will check is opposed. At 3.2 uses per run with 596 turns, the bot uses Word of Command approximately every 186 turns -- far less frequently than it could (23 uses per full voice pool).

The concern is valid for human play: a player who spams Word of Command every encounter will trivialize combat on floors 1-10. However, at alpha stage, having one system that works well is more valuable than having no systems work. Word of Command tuning should wait until other systems (stealth offense, smithing, ranged) are functional, so the relative power level can be assessed holistically.

### 5.6 Equipment Resistances -- A Quiet Disaster

The Known Issues document notes that **equipment resistance flags (RES_FIRE, RES_COLD, RES_POIS) are parsed from item data but never checked during damage resolution.** This means:

- Fire-resistant armor provides zero fire damage reduction
- Poison-resistant rings do not help against poison
- Cold-resistant gear is cosmetic

This is a serious systems gap that compounds with depth. In Sil-Q, resistance equipment is the primary defense against elemental attacks in the mid-to-late game. Breath attacks (fire, cold) from dragons and shadows are major threats in floors 10-15. Without functional resistances, the mid-game difficulty spike will be even harsher than it would otherwise be, and the equipment progression from "stat stick armor" to "resistance-layered defense" does not exist.

### 5.7 Level Persistence -- A Design Debt

Levels regenerate on every stair transition. This is noted as a known simplification but has cascading balance effects:

- **Forges are disposable.** A player who finds a forge cannot return to it after descending. In Sil-Q, forge planning ("I'll smith at this forge when I find Mithril on the next floor") is a core part of the smithing loop.
- **Retreat is meaningless.** Ascending stairs generates a new floor, so there is no "going back to a cleared area to rest safely."
- **Quest item placement is fragile.** Rod of Istari pieces at specific depths must be found on the first visit, or they are lost.

This is acceptable for alpha but must be resolved before beta.

---

## 6. Critical Path to Beta

### 6.1 Must-Fix (Blocks Beta Release)

These issues must be resolved before the game can be considered a playable beta:

| Priority | Issue | Effort Estimate | Impact |
|----------|-------|----------------|--------|
| **P0** | Floor 1-2 monster stats audit and rebalance | 2-4 hours | Unblocks all playtesting; currently 38-76% of runs die on floor 1 |
| **P0** | Equipment resistance flag integration | 2-3 hours | Entire resistance equipment category is non-functional |
| **P0** | Smithing damage dice, parry, weight, protection | 4-8 hours | Most broken feature per project memory; smithing archetype is unplayable |
| **P0** | Victory screen instantiation in main.gd | 0.5 hours | Game cannot be "won" in the UI |
| **P1** | Diagnose and fix 0 forge successes in bot | 2-3 hours | Smithing system has zero empirical validation |
| **P1** | Stealth assassination offensive loop | 2-4 hours | Assassination/Throat Slit not triggering; stealth assassin archetype is broken |
| **P1** | Ranged combat usability audit | 2-3 hours | 0.4-0.5 shots per run despite fixed equipment slot; still non-functional in practice |
| **P1** | Level persistence (at least for current and adjacent floors) | 8-16 hours | Forge planning, retreat, and quest item reliability all depend on this |
| **P2** | Pursuit Mode (6-phase Ring escalation) | 8-16 hours | The endgame does not function without this; escape victory has no tension |
| **P2** | Silent Kill gameplay hook | 1-2 hours | Defined ability with no effect |
| **P2** | Listen ability gameplay hook | 1-2 hours | Defined ability with no effect |

### 6.2 Should-Fix (Significantly Improves Beta Quality)

| Priority | Issue | Effort Estimate | Impact |
|----------|-------|----------------|--------|
| **P2** | Sealed door mechanic (Word of Shutting) | 1-2 hours | Tactical depth for lore builds |
| **P2** | Trap system expansion (13 types, currently 1) | 4-8 hours | Perception skill tree is undervalued without trap diversity |
| **P2** | Monster door-opening AI | 2-3 hours | Doors are currently impenetrable walls to all monsters |
| **P3** | Ring gold hallucination effect | 2-4 hours | Thematic endgame tension |
| **P3** | Morgul-wound mechanic | 4-8 hours | Nazgul encounters lack their signature threat |
| **P3** | High score persistence | 2-4 hours | Replayability hook |
| **P3** | HTML5 web export | 1-2 hours | Distribution |

### 6.3 Estimated Total Effort to Beta

- **P0 items:** 10-20 hours
- **P1 items:** 14-26 hours
- **P2 items:** 14-30 hours

Total: approximately 40-75 hours of focused development work to reach a playable beta with all major systems functional, balanced early floors, and a complete victory path.

---

## 7. Recommendations

### 7.1 Immediate Balance Changes (Before Next Playtest)

1. **Reduce floor 1 monster HP by 20-30% and attack by 1-2 points.** The goal is to make floor 1 a learning zone where a fresh character can survive 3-4 fights before needing to rest. Currently, floor 1 is a coin flip.

2. **Increase starting food by 1 unit for all races.** The tight food supply combined with the need to rest (467 turns for LORE_MAGE) creates a hunger death spiral. One extra food item gives the player enough runway to learn the rest mechanic.

3. **Add 1-2 guaranteed healing herbs on floor 1.** Sil-Q places fragments of lembas and herbs of restoration near the starting position. This provides an early heal that teaches the consumable system and gives a survival buffer.

4. **Implement equipment resistance checks.** This is a straightforward code change (the data is already parsed) with outsized impact on mid-game survivability.

### 7.2 System Priorities (Next Development Sprint)

1. **Complete smithing stat generation** -- damage dice, parry, weight, protection dice on forged items. This unlocks the entire smithing archetype.

2. **Wire up stealth offensive abilities** -- Assassination attack bonus, Throat Slit instant kills, and Silent Kill. These three changes unlock the stealth assassin archetype.

3. **Audit ranged combat end-to-end** -- from bow equipping to target selection to damage application. The v1 bug (wrong equipment slot) was fixed, but 0.4 shots per run suggests additional issues remain.

4. **Implement basic level persistence** -- cache the current floor and one floor above/below. This is the minimum viable persistence that enables forge planning and safe retreat.

### 7.3 Bot Testing Roadmap

1. **v3 bot: Add corridor-fighting.** When a monster is detected, move to the nearest 1-tile-wide corridor before engaging. This single change will likely improve survival by 50-100%.

2. **v3 bot: Add potion/herb quaffing.** Use unidentified potions when below 30% HP (they are more likely to help than hurt).

3. **Run Easy difficulty experiments.** The difficulty modes are implemented but untested by bots. Easy mode data would validate the difficulty scaling and provide a higher-win-rate dataset for analysis.

4. **Run 500+ runs at beta.** Once win rates climb above 0%, larger sample sizes become important for detecting archetype imbalances (e.g., a 2% vs 5% win rate difference requires ~500+ runs per archetype to detect with confidence).

5. **Introduce a "human heuristic" bot tier** that uses doorway fighting, pre-combat buffing (song activation), and multi-turn retreat sequences. This would provide the closest approximation to skilled human play.

### 7.4 Design-Level Observations

1. **The 20-floor depth is ambitious for a Sil-Q derivative.** Sil-Q uses 20 levels (1000 feet) but most runs see significant playstyle evolution by floor 10. The Necromancer's 7-layer structure (with distinct themes every 3 floors) is good design for maintaining variety, but the current lethality means only 2-4% of bot runs even see Layer 2 (floors 4-6). Consider whether 12-15 floors with denser content would serve the game better than 20 sparse ones.

3. **The XP-as-currency system is working correctly but the starting XP (5,000) may be doing too much work.** Because combat XP yields are so low on floor 1 (~15 per kill), the starting XP is essentially the entire skill budget for floors 1-3. If a player mis-invests their starting XP, they have no way to recover. Consider increasing floor 1-3 monster XP to 25-40 (from ~15) to provide a recovery path, or provide a "free" skill point in the player's house affinity skill.

4. **The dual victory path (Escape vs Banishment) is a strong design differentiator** from Sil-Q. The Banishment path requiring Lore 12 + Will 10 + Rod assembly creates a clear endgame build target. However, without Pursuit Mode implemented, the Escape path has no escalating tension -- the player simply walks back up 15 floors. Pursuit Mode should be prioritized as the key feature that makes the Escape path exciting.

5. **The trait system (20 traits) is genuinely novel** relative to Sil-Q and adds meaningful character diversity. Traits like Shadow Step (teleport to unaware enemy), Undying Resolve (survive lethal damage once), and Patient Stalker (stealth damage bonus) create distinct playstyle identities beyond race/house selection. This is one of the game's strongest design additions.

---

## 8. Conclusion

The Necromancer is a legitimate Sil-Q successor with a strong mechanical foundation, comprehensive data parsing from the Sil-Q source, and an unusually rigorous automated testing infrastructure. The core loop works: characters are created, dungeons are generated, combat resolves, skills are purchased, and the game can (in theory) be won. The 70% feature parity with Sil-Q after approximately 3 weeks of development is impressive velocity.

The critical issues are concentrated, not diffuse: floor 1-2 lethality, three broken subsystems (smithing stats, stealth offense, ranged combat), and one missing infrastructure piece (equipment resistances). These are all tractable 2-8 hour fixes that would collectively transform the game from "alpha with potential" to "playable beta."

The bot testing methodology is the project's greatest asset. The ability to run 200 playthroughs in under an hour and generate per-archetype balance data is a competitive advantage over traditional roguelike development, where balance tuning relies on human playtester reports over weeks or months. The recommendation is to double down on this infrastructure: fix the bot's stealth and ranged deficiencies, add corridor-fighting intelligence, and use the resulting data to guide every balance decision through beta.

**Overall Assessment: Strong alpha. Clear path to beta. Fix the floor 1 kill zone, complete the three broken subsystems, and this becomes a playable game.**

---

*Report generated 2026-02-08 by independent roguelike analysis.*
*Data sources: GAME_DESIGN_DOCUMENT.md, BALANCE_REPORT.md, BALANCE_REPORT_SESSION_S.md, KNOWN_ISSUES.md, PARITY_ANALYSIS.md, CHANGELOG.md, bot source code (survival_bot.gd, archetype_configs.gd, run_harness.sh, analyze_results.py).*
