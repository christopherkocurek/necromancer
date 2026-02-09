# Enchantment Roster -- Final Review Committee Report

**Document Reviewed:** `docs/design/enchantment_roster.md` v2 (2026-02-08)
**Review Panel:** Roguelike Systems Analyst, Necromancer-Dev Expert, Tolkien Scholar
**Synthesis Author:** Game Design Analyst
**Date:** 2026-02-09

---

## Executive Summary

The Enchantment Roster v2 is a strong, comprehensive design document that addresses the single most critical gap in The Necromancer: flat item progression. The game currently has 60+ enchantment definitions sitting in `special.txt` that the Godot code never parses -- weapons found on floor 1 are mechanically identical to weapons found on floor 18. This document provides the blueprint for fixing that, and all three reviewers agree it is largely excellent work. The proposed scarcity-to-abundance loot curve, the 16 new enchantments, the depth-timing fixes (Ring of Free Action to depth 8, Amulet of Starlight to depth 7), and the Dragon-bane-to-Wraith-bane replacement all received unanimous praise.

The committee identified two implementation blockers that must be resolved before any code is written: (1) Reforge/Reclaim smithing output must respect floor depth gating, and (2) boss drops must explicitly exclude cursed enchantments. Both are specification gaps rather than design flaws -- the intent is clear, but the document does not make the rules explicit enough for implementation. Additionally, the ability-grant-from-equipment contract (what happens when a player already has the ability? do grants stack? do they count toward prerequisites?) must be defined before any ability-granting enchantments are built.

The loot curve itself drew the most nuanced discussion. The Roguelike Expert rated it well-calibrated for a 20-floor game, while the Necromancer-Dev Expert flagged the mid-game density (70% ego items at depth 10) as potentially too generous for a "desperate survival" game. The committee recommends shipping with the proposed curve but monitoring playtest data closely, with a fallback conservative curve ready if the mid-game feels like a loot shower. The Wraith Domain drought (floors 13-15) is the most interesting and risky design decision -- all reviewers praised the concept but the Roguelike Expert recommends bumping minor enchant rate from 15% to 20% if more than 40% of runs that reach floor 13 die in the drought zone.

**Overall Committee Score: 8.2 / 10** (Roguelike Expert: 7.75, Necromancer-Dev: 8.0, Tolkien Scholar: 8.5)

**Verdict: APPROVE WITH MODIFICATIONS** -- The design is sound and implementation-ready after addressing the two blockers and the high-priority naming/specification changes listed below.

---

## Consensus Findings

### Unanimous Praise (What's Working)

**1. The Dragon-bane to Wraith-bane replacement (all 3 reviewers).** Replacing SLAY_RAUKO + SLAY_DRAGON (zero valid targets) with SLAY_UNDEAD + SEE_INVIS was called "the single best design decision in the document" by the Necromancer-Dev Expert, "exactly the right call" by the Roguelike Expert, and "an excellent decision" by the Tolkien Scholar. This combines two critical endgame needs into one weapon slot and targets the actual dominant threat (7 invisible undead from depth 10-19).

**2. Adding LIGHT to Gondolin and Doriath weapons (all 3 reviewers).** Elven blades glowing in the presence of orcs is Tolkien canon (Glamdring, Orcrist, Sting). The Tolkien Scholar called this "the single most important lore change" and cited the exact passage from *The Hobbit*. The Roguelike Expert noted it extends item longevity -- a Longsword of Gondolin found on floor 4 remains relevant through floor 12 because it slays orcs AND lights your path.

**3. The FREE_ACT timing fix (all 3 reviewers).** Moving the Ring of Free Action from depth 12 to depth 8 closes a 5-floor dead zone where ghouls (ENTRANCE at depth 7) had no counterplay. The Roguelike Expert called this "the single most important balance change in the document." Combined with 5+ ego sources at depth 6-8, the fix is thorough.

**4. The new shield, boot, and glove enchantments (all 3 reviewers).** Shields transforming from "passive stat-sticks into build-defining items" was praised across the board. The Shadow-stalker boots (Fade after stealth kill) and Assassin gloves (free Assassination ability) were highlighted as exciting, build-enabling finds that directly address stealth archetypes' underperformance.

**5. The cursed item risk-reward matrix (Roguelike Expert + Necromancer-Dev).** Morgul (BRAND_COLD + DARKNESS + CURSED), Fury (Whirlwind + AGGRAVATE), Shadow (VAMPIRIC + DARKNESS + HUNGER) -- these create genuine dilemmas that define roguelike runs. The Tolkien Scholar additionally praised the cursed items as reflecting Tolkien's theme that dark power corrupts its wielder.

**6. The semantic UI descriptions (all 3 reviewers).** "Deadly against orcs" instead of "SLAY_ORC," with graduated pval language and evocative tooltip examples. The Necromancer-Dev Expert called the example tooltips "particularly strong," and the Tolkien Scholar noted they "read like item descriptions from the Silmarillion Appendices."

### Unanimous Concerns (What Needs Work)

**1. Naming of several new enchantments (Necromancer-Dev + Tolkien Scholar).** Both reviewers flagged "of the Cutpurse," "of the Assassin," "of the Vanguard," "of the Sentinel," "of Pursuit," and "of Cunning" as too generic for a game that takes Tolkien naming seriously. The Tolkien Scholar notes that "assassin" has no Middle-earth equivalent and "cutpurse" implies common thievery foreign to Bilbo's "burglar" archetype.

**2. Ability-grant stacking behavior undefined (Roguelike Expert + Necromancer-Dev).** What happens when a Stealth 4 character with Assassination equips Gloves of the Assassin? Does it stack? Do nothing? Feel wasted? The SilQ precedent is no stacking, but this must be explicitly specified.

**3. Smithing depth-gating unspecified (Roguelike Expert + Necromancer-Dev).** Can a player Reforge on floor 6 and receive a depth-12 enchantment? If yes, the scarcity curve breaks. Both reviewers independently flagged this as a critical specification gap. The Necromancer-Dev Expert additionally noted that forge tier filtering (Normal <= depth 6, Enchanted <= depth 12, Unique = any) needs explicit rules.

**4. Some enchantments are pure traps with no interesting decision (Roguelike Expert + Necromancer-Dev).** Helm of Terror (FEAR, cursed) and Shield of Wrath (AGGRAVATE) are "never equip intentionally" items. In SilQ, cursed egos reduce smithing difficulty, but The Necromancer's Reforge system does not use difficulty calculations. Without that context, these are inventory waste, not risk-reward decisions.

**5. Loot curve possibly too generous at mid-depths (Necromancer-Dev).** At depth 10, the proposal produces 70% ego items versus the current system's 20% -- a 3.5x increase. The Necromancer-Dev Expert recommends starting with a more conservative curve and tuning upward. The Roguelike Expert rates the curve as "good" but "not groundbreaking." The committee recommends shipping with the proposed curve but having a conservative fallback ready.

---

## Implementation Blockers

Items that ANY reviewer flagged as "must fix before implementation," compiled into a single prioritized list.

### Blocker 1: Reforge/Reclaim Must Respect Floor Depth Gating

- **Issue:** The document does not specify whether smithing output respects depth restrictions. A player Reforging on floor 6 could receive a depth-12 ego like "of the Noldor," breaking the scarcity curve.
- **Flagged by:** Roguelike Expert (Recommendation #1), Necromancer-Dev Expert (Recommendation #5)
- **Recommended fix:** Filter ego selection by `min(current_floor_depth, forge_tier_bonus + current_floor_depth)`. Suggested forge tier mapping: Normal forges produce enchantments with depth <= 6, Enchanted forges depth <= 12, Unique forges any depth.
- **Impact if not fixed:** The entire scarcity-to-abundance curve becomes bypassable. A Smithing-focused player could have endgame enchantments by floor 6-8.

### Blocker 2: Boss Drops Must Exclude Cursed Enchantments

- **Issue:** The boss loot table says "guaranteed drops one tier above floor median" but does not exclude cursed items. A Floor 3 boss dropping Helm of Terror (FEAR) or Cloak of Winter's Chill (VUL_COLD) would be a terrible player experience for a hard-earned boss kill.
- **Flagged by:** Roguelike Expert (Recommendation #2)
- **Recommended fix:** Implement a `only_good` filter (modeled on SilQ's `make_special_item()`) that excludes any enchantment with negative-only flags from boss drop tables.
- **Impact if not fixed:** Boss fights feel unrewarding ~10% of the time, undermining the guaranteed-progression design.

### Blocker 3: Define Ability-Grant-from-Equipment Contract

- **Issue:** 14 enchantments grant abilities (Charge, Zone of Control, Assassination, Fade, etc.), but the document does not specify: (a) do granted abilities stack with purchased ones? (b) what happens on unequip? (c) do grants count toward prerequisites? (d) how are they displayed in the UI?
- **Flagged by:** Necromancer-Dev Expert (Recommendation #1)
- **Recommended fix:** Explicitly state: ability grants from equipment do not stack (SilQ precedent), are removed on unequip, do not count toward skill prerequisites, and are displayed with a special icon or "[equipment]" tag in the ability list.
- **Impact if not fixed:** Implementation hits design ambiguity at every ability-granting enchantment. Developers will make inconsistent decisions that require later rework.

---

## Recommended Changes -- Prioritized Master List

### P0 -- BLOCKER (Must fix before any implementation)

| # | Change | Reviewer(s) | Rationale |
|---|--------|-------------|-----------|
| 1 | Specify Reforge/Reclaim depth gating rules | Roguelike, Necromancer-Dev | Prevents smithing from bypassing scarcity curve |
| 2 | Specify boss drops exclude cursed enchantments | Roguelike | Prevents frustrating boss rewards |
| 3 | Define ability-grant-from-equipment contract (stacking, unequip, prerequisites, UI) | Necromancer-Dev | Prevents implementation ambiguity across 14 enchantments |

### P1 -- HIGH (Fix before first playtest)

| # | Change | Reviewer(s) | Rationale |
|---|--------|-------------|-----------|
| 4 | Increase Shield of Warding rarity from 4 to 8 | Roguelike | Three anti-magic resistances at depth 8 with rarity 4 is too common; makes anti-magic defense trivial |
| 5 | Rename "of the Cutpurse" to "of the Burglar" | Necromancer-Dev, Tolkien | "Cutpurse" implies common thievery; "Burglar" directly references Bilbo's canonical archetype |
| 6 | Rename "of the Assassin" to "of the Shadow-hand" | Tolkien | "Assassin" has no Middle-earth equivalent; Tolkien-flavored name maintains linguistic integrity |
| 7 | Add a Lore/Voice-boosting helm ego ("of the Wise" or "of the Loremaster," depth 8, +2 LORE, LIGHT) | Roguelike | The Lore skill tree has 12+ abilities but almost no ego support; caster builds feel unsupported |
| 8 | Add explicit exclusion note for wands, horns, scrolls, discovery items, consumables | Necromancer-Dev | Silence on these categories could be interpreted as oversight and cause scope creep |
| 9 | Address duplicate "of Lothlorien" name (IDs 30 and 37) | Necromancer-Dev, Tolkien | Two enchantments sharing a name but applying to different item types (bows vs. quarterstaves) creates player confusion; rename staff version to "of the Mallorn" or "of Caras Galadhon" |

### P2 -- MEDIUM (Fix before release)

| # | Change | Reviewer(s) | Rationale |
|---|--------|-------------|-----------|
| 10 | Reduce Boots of Pursuit depth from 10 to 6, or add secondary bonus | Roguelike | Flanking at depth 10 competes with Speed (Sprinting) and Shadow-stalker (Fade) and loses; too weak for its depth |
| 11 | Add Tolkien-specific language to enchantment descriptions | Tolkien | "Deadly against orcs" becomes "A bane to the servants of the Enemy"; low effort, high atmosphere impact |
| 12 | Give Helm of Terror and Shield of Wrath minor positive effects | Roguelike | Pure-trap cursed items with no decision point waste inventory and player time; add +1 prot or +1 STR to create actual risk-reward |
| 13 | Add more evocative negative-flag descriptions | Necromancer-Dev | "Puts you in greater peril" (DANGER) is flat; "The shadow takes note of you" or "Evil eyes turn toward you" adds weight |
| 14 | Rename generic new enchantment names (Vanguard, Sentinel, Cunning, Pursuit) | Tolkien | Replace with Tolkien-flavored alternatives: "of the White Company," "of the Watchers," etc. |
| 15 | Prepare conservative fallback loot curve for mid-depths | Necromancer-Dev | If the 70% ego rate at depth 10 proves too generous in playtesting, have a 55-60% alternative ready |
| 16 | Consider pity timer or guaranteed-first-ego mechanic for non-boss floors | Necromancer-Dev | A zero-ego run through floors 4-6 is 6-13% probable; could frustrate players with no recourse |

### P3 -- LOW (Nice to have)

| # | Change | Reviewer(s) | Rationale |
|---|--------|-------------|-----------|
| 17 | Add "of Flame" arrow ego (BRAND_FIRE, depth 10) | Roguelike | Gives archers fire option against HURT_LITE undead; arrows are the thinnest slot (only 2 egos) |
| 18 | Add "of Esgaroth" or "of the Lake" bow/arrow enchantment | Tolkien | Lake-town is geographically adjacent and culturally significant (Bard, Black Arrow); fills cultural gap |
| 19 | Add "of the Woodland Realm" armor/cloak enchantment | Tolkien | Thranduil's kingdom is the closest Elven realm to Dol Guldur; +Stealth + SLAY_SPIDER would add thematic depth |
| 20 | Add Beorning representation to enchantment roster | Tolkien | Beorn's folk dwell directly adjacent to Dol Guldur; "of the Beornings" on leather/cloaks (STR + RES_FEAR) |
| 21 | Consider "of Ithildin" enchantment for helms or light sources | Tolkien | Mithril inlay that reveals the hidden; SEE_INVIS or reveal-trap effects would fit the lore |
| 22 | Replace Cloak of the Traveller (SLOW_DIGEST) with something more interesting | Roguelike, Necromancer-Dev | Hunger is a "soft mechanic"; SLOW_DIGEST does not change gameplay meaningfully in most runs |
| 23 | Add lore fragments to each enchantment tooltip | Tolkien | One-line environmental storytelling per enchantment (e.g., "Wrought before the dragon came") |
| 24 | Add balance-pass-after-implementation note to document | Necromancer-Dev | No player has ever experienced real ego items; difficulty impact is unpredictable |
| 25 | Monitor non-cursed BRAND_COLD gap | Roguelike | Only Morgul (cursed) provides cold brand on egos; defensible but worth noting |

---

## Disagreements Between Reviewers

### Loot Curve Aggressiveness

**Roguelike Expert position:** The proposed curve (75%/60%/45%/30%/25%/15%/5% mundane) is "well-calibrated for a 20-floor game" and rates it 8/10. The compression from Angband's 100-floor curve into 20 floors demands a steeper descent, and this delivers.

**Necromancer-Dev Expert position:** The mid-game density is too aggressive. At depth 10, the proposal produces 70% ego items versus the current 20% -- a 3.5x increase. They recommend starting with a more conservative curve (roughly 30% less ego density at mid-depths) and tuning upward based on playtest data.

**Committee recommendation:** Ship with the proposed curve. The Roguelike Expert's comparative analysis (Angband, DCSS, Brogue, SilQ) is convincing that the compression is necessary for a 20-floor game, and the bot data showing 41.9% of deaths on floor 1 supports the argument that players need to encounter the enchantment system early and often. However, the Necromancer-Dev's concern is valid -- prepare the conservative fallback curve and be ready to swap if playtesting reveals a mid-game loot shower. The first playtest cycle should specifically measure "average enchanted items in inventory at floor 10."

### Enchantment Description Style

**Tolkien Scholar position:** Enchantment descriptions should use Tolkien-specific language. "Deadly against orcs" should become "A bane to the servants of the Enemy." "Glows with soft light" should become "Gleams with pale Elven-light."

**Implicit counterpoint (from roster design):** The current descriptions prioritize gameplay clarity -- a player immediately understands what "Deadly against orcs" means, while "A bane to the servants of the Enemy" requires interpretation.

**Committee recommendation:** Use both. The primary description should be clear and functional ("Deadly against orcs"), but add a one-line lore fragment above it in the tooltip. The existing example tooltips already demonstrate this pattern: "An ancient blade forged in the hidden city, before it fell to treachery" (lore) followed by "Deadly against orcs. Deadly against trolls." (mechanics). Extend this pattern to all enchantments.

### Helm of Terror / Shield of Wrath: Remove or Improve?

**Roguelike Expert position:** Give these pure-trap items a minor positive effect (+1 prot, +1 STR) to create genuine cursed-item decisions rather than inventory waste.

**Necromancer-Dev position:** Questions whether purely negative egos should exist at all without SilQ's smithing-difficulty-reduction context.

**Committee recommendation:** Add minor positive effects. A Helm of Terror with +1 protection side becomes "terrible but technically wearable if you are desperate," which is more interesting than "never equip." This aligns with the document's own stated goal that "cursed items create risk-reward tension." An item with zero reward and only risk creates no tension.

---

## The Fun Factor Report

### Most Exciting Enchantments (Consensus Picks)

1. **Weapon of Wraith-bane** (SLAY_UNDEAD + SEE_INVIS, depth 9) -- All three reviewers highlighted this as a jackpot find. The Roguelike Expert called it "Tolkien's Sting distilled into a single enchantment." Finding this weapon reveals and slays the invisible dead in one slot, freeing helm and ring for other uses.

2. **Boots of the Shadow-stalker** (Fade, depth 8) -- Praised by both the Roguelike Expert ("viscerally exciting gameplay loop: sneak, kill, vanish, reposition, repeat") and the Necromancer-Dev Expert ("turns stealth assassin from 'hope you don't get caught' to 'calculated predator'"). Build-defining for stealth plays.

3. **Mithril Shield with Many Runes** (CHEAT_DEATH, depth 20) -- The Roguelike Expert compared it to NetHack's Amulet of Life Saving. The Necromancer-Dev Expert noted this is the kind of item that "generates forum posts and run narratives." Its extreme rarity (depth 20, rarity 20, mithril only) ensures it stays legendary.

4. **Dagger of Murder** (+3 Stealth, Assassination, depth 0-4) -- Finding this early defines your entire run. The Roguelike Expert and Necromancer-Dev Expert both identified it as the stealth build enabler that the game needs.

5. **Shield of the Vanguard** (Charge, depth 4) -- The Necromancer-Dev Expert called it a "playstyle pivot": a shield that enables offensive rushing plays a completely different game than a defensive shield.

### Inventory Filler (Consensus Concerns)

1. **Cloak of the Traveller** (SLOW_DIGEST) -- Both the Roguelike Expert and Necromancer-Dev Expert flagged this as the weakest enchantment in the roster. Hunger is a soft mechanic that rarely kills. SLOW_DIGEST is "insurance against a problem that rarely materializes."

2. **Helm of Brilliance** (LIGHT) -- The Roguelike Expert called it "the socks for Christmas of enchantments." The Necromancer-Dev Expert noted that by the time you find helms, you already have a torch. Marginal benefit in a slot that wants True Sight or Clarity.

3. **Helm of Terror / Shield of Wrath** (pure cursed) -- Both the Roguelike Expert and Necromancer-Dev Expert identified these as items with zero upside and no interesting decision. They are literally never worth equipping in the current design.

4. **"of Dale" gauntlets/greaves** (RES_COLD, depth 8) -- The Necromancer-Dev Expert noted that cold damage does not appear until depth 14, making this a "save it for later" item that takes inventory space for 6 floors. Either increase depth or broaden utility.

### The "One More Run" Factor

**Yes, this system will drive replays.** The committee unanimously agrees that the enchantment system creates strong replay incentives through three mechanisms:

1. **Problem-solution memory loop:** "I died to ghouls because I had no FREE_ACT. Next run, I will prioritize of the Woodmen or of the Mark." This is the engine that drives roguelike retention, and the depth-timing fixes ensure solutions exist before problems become lethal.

2. **Build-defining equipment finds:** The 14 ability-granting enchantments mean that two runs of the same character can play completely differently based on what appears. A Man of Gondor who finds Shadow-stalker boots plays a mobile assassin; the same character with a Sentinel shield plays a corridor-blocking juggernaut.

3. **The cursed item gamble:** Every cursed item creates a unique, memorable decision. "Do I equip this Glaive of Fury and gain Whirlwind but lose stealth forever?" These moments become run-defining stories.

The Roguelike Expert rates the overall loot excitement at 7.5/10 -- below Brogue (9/10) and SilQ smithing (8/10), but above DCSS egos (7/10) and Angband random drops (5/10). The committee considers this a strong result for a system that has not yet been playtested.

---

## Implementation Roadmap Recommendation

Based on all three reviews, the committee recommends a three-phase implementation that separates flag-based mechanics (easy, high impact) from ability-grant systems (hard, requires new architecture).

### Phase 1 -- MVP (The Core System)

**Goal:** Every item found in the dungeon can have meaningful enchantments. Flag-based only.

- Parse `special.txt` in DataManager (new `EgoData` class)
- Replace cosmetic ego placeholders with real ego selection (filter by tval/sval, depth, rarity)
- Wire SLAY_ flags into `entity.gd:attack_entity()` (bonus damage die per match)
- Wire BRAND_ flags into combat (bonus elemental damage die)
- Wire RES_ flags into `player.gd:take_damage()` (halve matching damage)
- Wire FREE_ACT, SEE_INVIS, SUST_* into relevant systems
- Implement the depth-gated loot curve (mundane/minor/major/artifact tiers)
- Apply the two depth changes: Ring of Free Action to 8, Amulet of Starlight to 7
- Replace Dragon-bane with Wraith-bane in `special.txt`
- Add LIGHT to Gondolin and Doriath in `special.txt`
- Implement Fine/Special independent roll system
- Implement semantic tooltip descriptions for all flags
- Implement boss drop system with cursed-item exclusion
- **Enchantment count:** ~35-40 existing egos (all flag-based: SLAY_, RES_, stat bonuses, BRAND_, utility flags)

### Phase 2 -- Polish (Depth and Variety)

**Goal:** Cursed items, new enchantments, smithing integration, and build diversity.

- Implement CURSED/LIGHT_CURSE identification and removal mechanics
- Add BRAND_ enchantments and cursed items (Morgul, Fury, Shadow, Vampiric)
- Add new flag-based enchantments (Flame-guard, Endurance, Flame weapon, Unseen cloak)
- Add all new shield enchantments (Vanguard, Citadel, Sentinel, Dunedain, Warding)
- Implement Wraith Domain drought curve (floors 13-15)
- Integrate smithing system with depth-filtered ego selection
- Implement the P1 naming changes (Burglar, Shadow-hand, Mallorn, etc.)
- **Enchantment count:** ~55-60 total egos

### Phase 3 -- Expansion (Ability Grants and Full Roster)

**Goal:** Equipment-granted abilities and the complete enchantment roster.

- Build ability-grant-from-equipment system (temporary grants, unequip removal, no stacking, no prerequisite counting)
- Add all ability-granting enchantments: boots (Shadow-stalker/Fade, Scout/Listen, Pursuit/Flanking, Speed/Sprinting, Leaping), gloves (Assassin/Assassination, Cunning/Opening Strike, Cutpurse/Pilfer, Swordplay/Parry), weapons (Murder/Assassination, Accompaniment/Two Weapon Fighting, Battering/Knock Back, Piercing/Impale, Edain/Follow-Through, Fury/Whirlwind), shields (Vanguard/Charge, Sentinel/Zone of Control)
- Add CHEAT_DEATH system (on-lethal-damage hook) for Mithril Shield with Many Runes
- Add AVOID_TRAPS system for Boots of Snares Eluded
- Add Lore-boosting helm ego ("of the Wise")
- Consider P3 additions: arrow egos, Esgaroth, Woodland Realm, Beorning enchantments
- **Enchantment count:** ~70+ total egos with all abilities online

---

## Appendix: Individual Reviewer Scores

### Roguelike Expert Scores

| Category | Score |
|----------|-------|
| Loot Curve | 8/10 |
| Enchantment Variety & Coverage | Strong (no numerical score; arrows flagged as thin) |
| Build Diversity | 4+ viable builds identified |
| Depth Gating & Progression | Thorough |
| Balance Red Flags | Shield of Warding OP, Boots of Pursuit UP |
| Fun Factor / Loot Excitement | 7.5/10 |
| **Implied Overall** | **~7.75/10** |

### Necromancer-Dev Expert Scores

| Category | Score |
|----------|-------|
| Design Vision Alignment | Serves all 5 pillars |
| Lore and Naming | Strongest dimension |
| Mechanical Fit | Strong with ability-grant caveat |
| Player Experience Journey | Floors 1-20 well-mapped |
| Gaps and Missing Pieces | Wands, horns, pursuit phase unaddressed |
| Implementation Risk | Ability grants = highest risk |
| Fun Factor / Player Retention | Strong build variety |
| **Overall** | **8/10** |

### Tolkien Scholar Scores

| Category | Score |
|----------|-------|
| Location Names (averaged) | 8.9/10 across 15+ names |
| Artifact Names | Excellent (canonical items: 10/10, invented: 7-9/10) |
| Enchantment Effects | Nearly all lore-justified |
| Thematic Consistency | "Emphatically yes" |
| Dol Guldur Setting Fit | Strong |
| Racial/Cultural Associations | Excellent for Dwarves/Elves, adequate for Rohan |
| **Overall Lore Accuracy** | **8.5/10** |

### Committee Average

| Reviewer | Score |
|----------|-------|
| Roguelike Expert | 7.75 |
| Necromancer-Dev Expert | 8.0 |
| Tolkien Scholar | 8.5 |
| **Committee Average** | **8.1** |
| **Analyst Adjustment** | +0.1 (for structural completeness of the document) |
| **Final Score** | **8.2 / 10** |

---

*Report synthesized 2026-02-09 from three independent expert reviews totaling ~12,000 words of analysis. All enchantment IDs, depth values, flag combinations, and monster references have been cross-verified across the three reviews and the source design document. This report should be read alongside the enchantment roster v2 and the three individual reviews for full context.*
