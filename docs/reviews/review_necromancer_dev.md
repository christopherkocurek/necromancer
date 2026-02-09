# Enchantment Roster Design Review

**Reviewer:** Necromancer-Dev Expert
**Document Reviewed:** `docs/design/enchantment_roster.md` (v2, 2026-02-08)
**Date:** 2026-02-09
**Verdict:** APPROVE WITH MODIFICATIONS (8/10)

---

## Preface

This review examines the Enchantment Roster v2 design document against The Necromancer's core design philosophy, Tolkien lore requirements, existing mechanical systems, player experience goals, and implementation realities. The review draws on the Game Design Document, the Player's Manual, all three research reports, the actual data files (`special.txt`, `monster.txt`, `object.txt`, `artefact.txt`), and the Godot codebase (`player.gd`, `entity.gd`, `monster.gd`, `dungeon_generator.gd`).

The enchantment roster is, in my assessment, the single most important design document for the game's future. The Necromancer currently has 60+ enchantment definitions sitting in `special.txt` that the Godot code never parses. The ego application functions in both `monster.gd` (`_apply_ego_enchantment`) and `dungeon_generator.gd` (`_apply_floor_ego`) are cosmetic placeholders that add random flavor prefixes like "Keen" or "Enchanted" and nudge numerical bonuses. No flags -- no SLAY_, no RES_, no BRAND_, no ability grants -- are ever applied to items. This means the game's entire item progression is flat: a Longsword found on floor 1 is mechanically identical to a Longsword found on floor 18, aside from a trivial +1 or +2 attack bonus. The roster document is the blueprint for fixing this, and it is largely excellent work. What follows is a detailed critique.

---

## 1. DESIGN VISION ALIGNMENT

### Does the roster match the game's stated design philosophy?

The Game Design Document establishes five design pillars: Tolkien Authenticity, SIL-Q Mechanics, Tension, Meaningful Choice, and Tactical Depth. The enchantment roster serves all five.

**Tolkien Authenticity** is deeply embedded. Every enchantment name traces to a canonical Third Age location, culture, or concept. The document explicitly maps each name to lore ("of Gondolin -- Glamdring and Orcrist survived," "of Westernesse -- Numenorean blades, effective against undead"). The removal of "of Dragon-bane" (SLAY_RAUKO/SLAY_DRAGON) and its replacement with "of Wraith-bane" (SLAY_UNDEAD + SEE_INVIS) is perhaps the single best design decision in the document. There are zero dragons and zero Balrogs in the monster roster -- a blade "of Dragon-bane" would be lore-authentic but mechanically dead weight, creating a "trap" enchantment that punishes players who don't memorize the monster list. Wraith-bane targets the actual endgame threat (7 invisible undead monsters from depth 10-19) and combines two critical survival needs into one weapon slot. This is elegant.

**SIL-Q Mechanics** are preserved faithfully. The Fine/Special split, the depth-gated rarity system, the independent roll architecture -- all mirror the source material documented in Report 1. The document correctly identifies that SIL-Q's ego selection is filtered by tval/sval, depth, and rarity weight, and proposes the same approach.

**Tension** is served by two brilliant structural decisions: the Wraith Domain drought (floors 13-15 minor enchants drop to 15%) and the cursed item risk-reward matrix. The drought creates a narrative "desert crossing" that forces players to rely on gear assembled in earlier tiers, making the Inner Sanctum (floors 16-18) feel like earned abundance. The cursed items -- "of Fury" (Whirlwind + AGGRAVATE), "of Shadow" (Vampiric + DARKNESS + HUNGER), "of Morgul" (BRAND_COLD + DARKNESS + CURSED) -- create genuine dilemmas. A stealth build finding a Glaive of Fury must choose between devastating AOE damage and permanent stealth-death. These are the moments that define roguelike runs.

**Meaningful Choice** is expanded significantly. The new shield enchantments (5 additions) transform shields from passive stat-sticks into build-defining items. A Shield of the Vanguard (grants Charge) plays completely differently from a Shield of the Sentinel (grants Zone of Control). The new boot and glove enchantments follow the same pattern: Boots of the Shadow-stalker (grants Fade) enable a stealth assassin playstyle; Boots of Pursuit (grants Flanking) reward tactical positioning for melee fighters. These are not incremental numerical bumps -- they are playstyle pivots.

**Tactical Depth** benefits from the problem-solution matching the document describes. Ghouls use ENTRANCE at depth 7; FREE_ACT is now available from depth 6-8 across 5+ sources. The player who remembers getting paralyzed by ghouls in their last run now has a specific, findable counter-strategy. This "I died to X, next run I'll look for Y" loop is the engine that drives roguelike retention.

### Does it support the "desperate survival" tone of Dol Guldur?

Yes, with one caveat. The 75% mundane rate on floors 1-3 is well calibrated. The document's own math confirms that at ~10 items found in the Outer Pits, 95%+ of runs see at least one enchantment -- enough to teach the system without drowning players in magic. By the Throne Room, major enchants (55%) are the workhorse, but artifacts are capped at 30%. This prevents the endgame from feeling like a loot pinata while ensuring the player has meaningful tools.

The caveat: the document does not address how the enchantment system interacts with the game's 0% bot win rate reality. Bot data from 720 runs shows 41.9% of all deaths occur on floor 1. The enchantment system begins its payload at depth 0 (several egos have W:0 depth), meaning the system is available from the very start -- but the placeholder implementation means no player has ever experienced a real ego item. The first release of this system will simultaneously be the first time any player encounters meaningful item progression, and the impact on difficulty is unpredictable. The document should acknowledge this and recommend a balance pass after implementation.

### Are there enchantments that feel too "high fantasy" for the setting?

No. The document is impressively restrained. There are no "of the Phoenix" or "of Dragonfire" enchantments that would feel out of place in a Third Age fortress. Even the most powerful effects (CHEAT_DEATH on "with Many Runes," SPEED as artifact-only) are mechanically grounded. The Mithril Shield with Many Runes is described as a legendary item at depth 20 with rarity 20 -- it will appear in perhaps one out of fifty runs. This is appropriate.

The closest thing to "too high fantasy" is the Boots of the Shadow-stalker (grants Fade). Fade is a powerful ability -- 2 turns of invisibility after killing an unaware enemy -- and putting it on boots that can appear at depth 8 is aggressive. However, Fade requires stealth investment to trigger (the target must be unaware), and stealth builds are currently the weakest archetype (bot data: Hobbit Sniper average floor 1.5). Giving stealth builds an equipment-based path to Fade without spending XP on Vanish (Stealth 8) + Fade (Stealth 9) is a reasonable power injection for an underperforming archetype.

### Does the power curve match the game's intended difficulty?

The loot curve (75% mundane at floor 1 descending to 5% at floor 19-20) tracks the GDD's stated intention that "the deeper you go, the more you find from Sauron's collection." The boss loot table system (guaranteed progression every 3 floors) is an important addition that the original SIL-Q lacks. In a game where 42% of runs die on floor 1, guaranteeing a minor enchant from the floor 3 boss creates a "if I can just survive to the boss" motivation that is psychologically powerful.

One concern: the document proposes no mechanism for bad-luck protection on non-boss floors. A player who explores floors 4-6 thoroughly but finds zero ego items (which at 60% mundane is possible for a run with few item spawns) has no recourse. The GDD lists 2+depth/2 to 4+depth items per floor. At depth 5, that is 4-9 items. With 40% ego chance (25% minor + 15% major), the expected ego count is 1.6-3.6. The variance is high enough that a zero-ego run through the Lower Halls is plausible (roughly 6-13% chance depending on item count). Consider whether some form of pity timer or guaranteed-first-ego mechanic is warranted.

---

## 2. LORE AND NAMING REVIEW

### Do enchantment names fit the First Age / Third Age naming conventions?

This is the document's strongest dimension. Every name is either a canonical Tolkien location/culture or a reasonable extrapolation. The renaming table in Section 3.1 demonstrates thorough scholarship:

- **of Gondolin** -- Kept. Glamdring and Orcrist are canonically Gondolin blades that survived to the Third Age. Bilbo and Gandalf use them. Perfect.
- **of Doriath** -- Kept as historical reference. Enchantments named after fallen kingdoms carry weight in Tolkien's world, where artifacts outlive their makers by millennia.
- **of Westernesse** -- New, and excellent. The "Barrow-blades" that Merry uses to wound the Witch-king are described as Numenorean/Westernesse blades effective against the undead. SLAY_UNDEAD + LIGHT is exactly right.
- **of the Woodmen** -- Renamed from "of Brethil" (First Age). The Woodmen of Mirkwood are a canonical Third Age culture who resist Dol Guldur's corruption. FREE_ACT on practical leather gear fits their survivalist identity.
- **of the Mark** -- Renamed from "of the Vanyar" (First Age Elves). Rohirrim cavalry weapons with RES_FEAR + FREE_ACT. The courage-against-fear theme is deeply Rohan.

### Are location-based names used correctly?

Almost entirely, yes. One minor issue:

**"of Lothlórien" appears twice** -- once on bows/swords (ID 30, +2 GRA + PERCEPTION + LIGHT) and once on quarterstaves (ID 37, +1 attack + REGEN). The data file `special.txt` confirms both entries exist. While SIL-Q had a similar pattern (different enchantments sharing names but applying to different item types), this creates player confusion. A player who sees "Quarterstaff of Lothlórien" and "Longbow of Lothlórien" might expect related effects. The quarterstaff version could be renamed "of Caras Galadhon" (the city within Lothlórien) or "of the Mallorn" (the golden trees) to differentiate.

### Are there anachronisms or lore violations?

One borderline case: **"of the Cutpurse"** (new gloves granting Pilfer). While Hobbits are famously "light-fingered" (Bilbo is literally called a burglar), the name "Cutpurse" carries a medieval-English flavor that sits slightly outside Tolkien's linguistic register. Tolkien's naming for thievish items would more likely be "of Nimble Fingers," "of the Quick Hand," or "of the Burglar" (referencing Bilbo's contract). This is a minor issue -- "Cutpurse" is perfectly understandable and functional -- but for a game that takes Tolkien naming seriously, a small rename would increase cohesion.

### Do the semantic descriptions feel authentic?

The UX descriptions in Section 3.2 are excellent. "Deadly against orcs" (SLAY_ORC), "Steels your courage" (RES_FEAR), "Glows with soft light" (LIGHT), "Drains life from your foes" (VAMPIRIC) -- these all feel like they could come from a Tolkien novel. The graduated pval descriptions ("Slightly increases strength" / "Increases strength" / "Greatly increases strength") are a good UX pattern.

The example tooltips are particularly strong:

> Longsword of Gondolin
> An ancient blade forged in the hidden city, before it fell to treachery.
> Deadly against orcs. Deadly against trolls. Glows with soft light.

This reads like an item description from the Silmarillion Appendices. The phrase "before it fell to treachery" is perfect -- it echoes Tolkien's tone of melancholy for lost kingdoms.

One suggestion: the negative flag descriptions should feel more ominous. "Puts you in greater peril" (DANGER) is serviceable but flat. Consider: "The shadow takes note of you" or "Evil eyes turn toward you." Similarly, "Gnaws at your vitality" (HUNGER) could be "Slowly devours your strength from within." These items are corrupted by Sauron's influence -- their descriptions should carry that weight.

---

## 3. MECHANICAL FIT WITH EXISTING SYSTEMS

### How do proposed enchantments interact with existing abilities?

The document demonstrates strong awareness of the ability system. Several enchantments are explicitly designed to grant abilities, creating alternative paths to key skills:

- **Gloves of the Assassin** (grants Assassination) -- Assassination normally requires Stealth 4 and 1,500 XP. Getting it from gloves at depth 6 frees stealth builds to invest XP elsewhere, potentially enabling Vanish/Fade earlier. This is a well-designed shortcut that rewards exploration without bypassing the skill system entirely (you still need stealth score for Assassination to matter).

- **Boots of Speed** (grants Sprinting) -- Sprinting requires Evasion 7 (Dodging + Leaping prerequisites). The boots bypass this at depth 10, right when the game transitions to layers where mobility becomes critical. Good timing.

- **Shield of the Sentinel** (grants Zone of Control) -- Zone of Control requires Melee 10 (Finesse + Polearm Mastery prerequisites). This is a level 10 ability being granted by a depth 10 item. The parallel is clean: if you haven't earned ZoC through XP, the dungeon can provide it at the same point in the game.

However, there is a mechanical concern with ability-granting items that the document does not address: **what happens when a player already has the ability?** The GDD does not document any "ability stacking" mechanic. If a Stealth 4 character with Assassination equips Gloves of the Assassin, does Assassination stack? Does it do nothing? Does the item feel wasted? The implementation must define this behavior. The SIL-Q precedent (Report 1) is that ability grants from items do not stack -- if you already have the ability, the item's ability grant is redundant. This should be explicitly stated in the roster document to prevent implementation ambiguity.

### Are there conflicts with the smithing system?

The smithing system (overhauled in commit `00c1821`, 15 files, +1345 lines) uses Broken Glowing items for Reforge and Broken Strange items for Reclaim/Masterwork. The roster document proposes that Reforge selects "random ego appropriate for output type and forge tier." This is mechanically sound but creates a design question: **should Reforge be able to produce the new enchantments (Vanguard, Sentinel, Shadow-stalker, etc.) or only the existing 60?**

If Reforge can produce any ego, then a player with Reforge Mastery (reject + reroll) has a 1/N chance per roll of hitting a specific enchantment, where N is the number of valid egos for that item type. For swords, N is approximately 15-20. This means a player with 2 Broken Glowing items and Reforge Mastery has roughly a 10% chance of getting a specific desired enchantment. This feels about right for the investment (Smithing 12 for Reforge Mastery, 2 broken items, 600 XP).

However, the forge tier system (Normal +0 / Enchanted +3 / Unique +7) should gate the more powerful new enchantments. A Shield of the Sentinel (grants Zone of Control, depth 10) should not be producible at a Normal forge on floor 4. The document's implementation section mentions "forge tier" filtering but does not specify the mapping. This needs to be defined before implementation.

### Are stat bonuses reasonable given the game's stat system?

Yes. The existing enchantments in `special.txt` use conservative pval values (typically 1-3), and the new enchantments follow this pattern. The highest pval in the roster is 3 (several entries: "of Rivendell" daggers, "of Stealth" cloaks/armor, "of Archery" gloves). Given that stats use a compounding cost curve (stat +3 costs 6 of 13 allocation points), a +3 bonus from a single item is significant but not game-breaking.

The document correctly avoids stacking concerns by keeping stat bonuses on different item types. +1 GRA appears on: Helms of Grace (mithril only), weapons of Lothlórien (bows/swords), weapons of the Noldor (swords only, with DANGER penalty). A player would need to find specific items in specific slots to stack GRA bonuses, which naturally limits the ceiling.

### Does the loot curve work with the dungeon generator's spawning logic?

The dungeon generator (`dungeon_generator.gd`) spawns 2+depth/2 to 4+depth items per floor (max 15). The current ego application uses a flat `10% + 1% * depth` chance. The roster proposes a more nuanced curve:

| Depth | Mundane | Minor | Major | Artifact |
|-------|---------|-------|-------|----------|
| 1-3   | 75%     | 22%   | 3%    | 0%       |
| 4-6   | 60%     | 25%   | 15%   | 0%       |
| 7-9   | 45%     | 25%   | 25%   | 5%       |
| 10-12 | 30%     | 20%   | 35%   | 15%      |
| 13-15 | 25%     | 15%   | 40%   | 20%      |
| 16-18 | 15%     | 15%   | 40%   | 30%      |
| 19-20 | 5%      | 10%   | 55%   | 30%      |

This is substantially more aggressive than the current 10%+depth% system. At depth 10, the current system produces ~20% ego items; the proposal produces 70% (20% minor + 35% major + 15% artifact). This is a 3.5x increase in enchanted item density.

Whether this is too generous depends on the base item spawn rate. At depth 10, the generator spawns 7-14 items. With 70% ego chance, that is 5-10 enchanted items per floor. Combined with the boss guaranteed artifact drop at floor 12, the player entering the Wraith Domain (floor 13) could plausibly have 15-25 enchanted items in their inventory history. This seems high for a "desperate survival" game.

**Recommendation:** Consider a tiered implementation. Start with a more conservative curve (matching the GDD's original intent more closely) and tune upward based on playtest data. The document's proposed curve might be the right end state, but launching with it risks making the mid-game feel like a loot shower before any player has experienced the baseline.

---

## 4. PLAYER EXPERIENCE JOURNEY

### Floors 1-3: The Outer Pits

A new player enters Dol Guldur with a Curved Sword, a Wooden Torch, and some food. At 75% mundane, most items found are base gear. But the 22% minor enchant chance means that in a typical 3-floor run (finding maybe 8-15 items), the player likely encounters 2-3 enchanted items.

These early enchantments are appropriately modest: "of Protection" (+1 protection side), "of Venom's End" (RES_POIS -- critical against the spider-dominated layer), "of Stealth" (+3 stealth on soft armor). Finding "Ranger Leathers of Venom's End" on floor 2 is a genuine moment of excitement -- it directly counters the dominant threat (5 of 12 layer 1 monsters deal poison) and teaches the player that enchantments solve specific problems.

The floor 3 boss (Broodmother) drops a guaranteed minor enchant. For a player who barely survived the spider gauntlet, this is a reward that validates the struggle. A "Longsword of Doriath" (SLAY_SPIDER + SLAY_WOLF) at this point would retroactively make the spider floors easier to think about -- "if only I'd had this earlier!" -- which is exactly the motivational hook for a replay.

### Floors 4-6: The Orc Warrens

The enchantment density increases to 40% (25% minor + 15% major). The player is now finding one enchanted item per 2-3 pickups. Importantly, the problems change: orcs in packs, wargs with speed 3, crossbowmen. The enchantment roster provides counters: "of Gondolin" (SLAY_ORC + SLAY_TROLL) is available from depth 0 but becomes more common here, "of the Mark" (RES_FEAR + FREE_ACT) appears at depth 6.

The transition from Layer 1 to Layer 2 is where the game's identity as a survival roguelike crystallizes. The player has assembled a small collection of enchanted gear and must decide what to equip. Slot competition begins: "Do I wear the Ranger Leathers of Venom's End (RES_POIS) or the Ranger Leathers of the Woodmen (FREE_ACT)?" This is the first genuine equipment dilemma, and it arrives at the right time.

The floor 6 boss (Orc Warchief / Gashnak) drops a guaranteed major enchant. A "Tower Shield of the Vanguard" (grants Charge) at this point would fundamentally change a melee build's playstyle. This is the kind of moment that makes players say "one more run."

### Floors 7-12: The Crucible

This is where the enchantment system faces its most critical test. The threats escalate dramatically: ghoul ENTRANCE (paralysis) at depth 7, darkness spells at depth 6+, stat drain starting at depth 10, invisible enemies at depth 10+. The roster's key contribution is ensuring that counter-enchantments arrive 1-2 floors before their associated threats:

- FREE_ACT: Available from depth 6 across 5+ sources (of the Woodmen, of the Mark, of Final Rest, of Warding shield, Ring of Free Action moved to depth 8). This is the most critical fix in the entire document. The original gap (FREE_ACT ring at depth 12, ghouls at depth 7) was a 5-floor death zone.
- SEE_INVIS: Available from depth 0 (Helm of True Sight), depth 6 (Bow of the Marchwardens, Shield of the Dunedain), depth 9 (weapon of Wraith-bane), depth 10 (Cloak of the Unseen). Seven sources across six slots.
- SLAY_UNDEAD: Available from depth 6 (of Westernesse), depth 7 (of Final Rest), depth 9 (of Wraith-bane). No longer artifact-only.

The timing is excellent. A player entering the Necropolis (depth 10) who has been exploring thoroughly should have: at least one FREE_ACT source, a reasonable chance of SEE_INVIS, and access to SLAY_UNDEAD weapons. They may not have all three, but the probability of having none is very low. This is the "gear check" that feels fair because the tools were available.

### The Wraith Domain Drought (Floors 13-15)

This is the roster's most narratively interesting design choice. Minor enchantments drop to 15% while major enchants remain at 40% and artifacts at 20%. The effect is that the player finds fewer items overall (the dungeon is darker, emptier, more desolate) but the items they do find are powerful.

From a narrative perspective, this maps perfectly to the Wraith Domain's identity: Sauron's wraiths don't carry swords and shields. They are incorporeal terrors that pass through walls. The "drought" reflects this -- there simply isn't much physical loot in the domain of the dead. What little exists is powerful precisely because it was placed there by Sauron (high artifact rate) or carried by his mortal servants (major enchants from Black Numenoreans).

The danger is that a player who enters the Wraith Domain underequipped finds no salvation. If your loadout is missing SEE_INVIS by floor 13, the drought ensures you won't easily find it before the Wailing Horror (unique, invisible, depth 15) kills you. This is intentional design -- the Wraith Domain is a gate that tests whether you prepared. But it should be communicated to the player somehow, perhaps through environmental storytelling ("The air grows thin and cold. You sense fewer treasures here -- only shadows").

### Floors 16-20: The Payoff

The Inner Sanctum (15% mundane, 40% major, 30% artifact) and Throne Room (5% mundane, 55% major, 30% artifact) deliver the "raiding Sauron's armory" fantasy. Nearly every item the player finds is enchanted or legendary. This feels earned after the Wraith Domain drought.

The design decision to make major enchants (not artifacts) the endgame workhorse at 55% is sound. It means the player's victory is built on synergistic enchanted gear -- a Longsword of Wraith-bane + a Tower Shield of Warding + a Mail of the Flame-guard -- rather than on a single overpowered artifact. This creates more interesting builds and reduces the variance of "did you find the right artifact?"

---

## 5. GAPS AND MISSING PIECES

### Systems in the GDD that the roster doesn't support

1. **Wands.** The GDD lists 6 wand types (Frost, Fire, Slowing, Light, Fear, Sleep) as a core item category. The enchantment roster does not include any wand enchantments. In SIL-Q, staves (the equivalent) do not have ego variants -- they are always base items with charges. If The Necromancer follows this precedent, wands should be excluded from the ego system, but this should be explicitly stated.

2. **Horns.** Six horn types exist (Terror, Thunder, Force, Blasting, Challenge, Fairy Flute). No horn enchantments are proposed. Again, this may be by SIL-Q precedent, but should be documented.

3. **Discovery items.** The 38 discovery XP items (Thrain's Memory, Shadow Fragment, etc.) are a unique non-combat progression system. The roster does not address whether discovery items can be enchanted (they shouldn't be) or whether enchantments that boost Hunting/Perception help find them.

4. **The pursuit phase.** After taking the Ring of Thrain, all monsters are alerted and Sauron awakens. The roster does not specifically address "escape-phase" enchantments. SPEED is correctly kept artifact-only, but other escape-relevant effects (STAND_FAST against knock-back, SLOW_DIGEST against hunger pressure during the long ascent) could be called out as escape-phase tools.

### Player abilities with no equipment synergy

- **Throat Slit / Silent Kill:** These are the stealth tree's capstone kill abilities. No enchantment specifically enhances instant-kill mechanics. Consider a "of the Assassin's Mark" weapon enchantment that increases the humanoid HP threshold for Throat Slit, or a cloak enchantment that reduces noise generated by kills.

- **Song of Banishment (trait):** This trait gives Song of Banishment at game start regardless of Lore. No enchantment specifically boosts Song of Banishment's effectiveness or radius. An amulet or cloak "of the Sanctified" (+radius to banishment effects) would create synergy with this trait.

- **Smithing tree (post-Reforge):** The smithing tree's higher abilities (Reclaim Mastery, Master Smith) require high Smithing investment. No enchantment grants Smithing skill bonuses. SIL-Q's artifact template for gloves includes "grants Jeweller" and "grants Expertise" -- similar enchantments could support smith builds.

### Monster threats with no counter-enchantment

- **MULTIPLY (Whispering Shades, depth 13):** No enchantment counters multiplication. This is probably fine -- multiplication is countered by killing the source quickly, which SLAY_UNDEAD handles.

- **PASS_WALL (Shadows, Fell Spirits, Shadow Lords):** No enchantment defends against wall-passing. The document acknowledges this as "UNSOLVABLE" in Report 3. This is correct -- PASS_WALL is a design feature that forces players to abandon corridor-fighting strategies. It should not have a counter-enchantment.

- **SHRIEK (multiple early monsters):** Shrieking alerts other monsters. No enchantment specifically counters this. An enchantment granting "sound dampening" (reduced shriek radius) would be thematically interesting but mechanically complex to implement.

### Consumables, wands, and staves

The roster correctly focuses on equipment enchantments (weapons, armor, accessories) and does not attempt to create ego variants of consumable items. This matches SIL-Q's design: potions, herbs, scrolls, and wands are always base items. The Alchemy system (combining herbs for improved versions) provides consumable progression through a different channel.

---

## 6. IMPLEMENTATION CONCERNS

### The current codebase reality

The implementation gap is severe. Here is what currently exists versus what the roster requires:

**Exists:**
- `data/special.txt` with 60+ enchantment definitions (complete, parseable)
- `player.gd:_apply_equipment_flags()` that reads flag strings from equipped items and sets `equip_flags` dictionary entries for RES_FIRE, FREE_ACT, SEE_INVIS, BRAND_FIRE, etc.
- `entity.gd:attack_entity()` with a combat resolution system that calculates damage dice, crits, and protection rolls

**Does NOT exist:**
- Any parsing of `special.txt` in `DataManager` or anywhere in the codebase
- Any flag application in `monster.gd:_apply_ego_enchantment()` or `dungeon_generator.gd:_apply_floor_ego()` -- both functions are purely cosmetic
- Any combat code that checks for SLAY_ flags (confirmed: zero matches for "SLAY_" in the entire `scripts/` directory)
- Any combat code that checks for BRAND_ flags (confirmed: BRAND_ flags are stored in `equip_flags` by `player.gd` but never read by `entity.gd`)
- Any implementation of ability grants from equipment
- Any boss loot table system
- Any tooltip system that reads enchantment flags

The `_apply_equipment_flags()` function in `player.gd` (around line 692) is the most encouraging piece of existing infrastructure. It already iterates equipped items, reads flag strings, and sets boolean flags and stat bonuses. The categories it handles include: stat bonuses (STR/DEX/CON/GRA), skill bonuses (STEALTH/PERCEPTION/WILL/ARCHERY), resistance flags (RES_FIRE through RES_HALLU), utility flags (FREE_ACT, SEE_INVIS, REGEN, etc.), and brand flags (BRAND_FIRE/COLD/POIS). This means the flag storage and reading infrastructure is partially built -- what's missing is the flag application in combat and the flag attachment to items during generation.

### Easiest to implement (in order)

1. **special.txt parser** -- The format is well-documented, and DataManager already parses similarly structured files (monster.txt, object.txt, artefact.txt). Estimated: 100-200 lines of parsing code.

2. **Replace cosmetic ego application with real ego selection** -- Filter loaded ego data by tval/sval match, depth range, and rarity. Apply flags to ItemData. The existing functions in `monster.gd` and `dungeon_generator.gd` are already called at the right points; they just need real logic. Estimated: 50-100 lines per function.

3. **Wire SLAY_ flags into combat** -- In `entity.gd:attack_entity()`, after damage dice are rolled, check attacker's equipped weapon flags for SLAY_ matches against target's race flags. Add one bonus damage die per match. Estimated: 20-30 lines.

4. **Wire BRAND_ flags into combat** -- Similar to SLAY_, add bonus damage die of appropriate element. Estimated: 20-30 lines.

5. **Wire RES_ flags into damage reduction** -- In `player.gd:take_damage()`, check `equip_flags` for matching resistance, halve damage. Some of this may already work if the flags are checked downstream.

### Hardest to implement

1. **Ability grants from equipment** -- This requires the ability system to support "equipment-granted" abilities that activate when equipped and deactivate when unequipped. The current `ability_system.gd` tracks abilities as permanent purchases. A new system must handle temporary ability grants without corrupting the permanent ability list. This is the single highest implementation risk.

2. **Boss loot table system** -- The document proposes a separate loot table per boss tier. The current boss spawn logic in `dungeon_generator.gd` does not have a dedicated loot system. Building one requires: defining boss entities, creating per-boss loot tables, ensuring drops spawn near the boss death position, and filtering by enchantment tier. Estimated: 200-300 lines of new code.

3. **Depth-gated ego rarity with the proposed curve** -- The current flat probability needs to be replaced with the layered mundane/minor/major/artifact system. This requires defining what constitutes "minor" vs "major" enchantment and implementing a two-stage roll (first determine tier, then select within tier). Estimated: 100-150 lines.

### Enchantments that require new game systems

- **CHEAT_DEATH ("with Many Runes")** -- Requires an "on lethal damage" hook that intercepts death, heals to 1 HP, and removes the shield's enchantment. The Undying Resolve trait and Defy Death ability already implement similar hooks, so the pattern exists.

- **STAND_FAST** -- Requires knock-back resistance logic. If Knock Back is implemented as a forced movement, STAND_FAST must prevent it. The GDD lists this as a flag on "of the Iron Hills" armor, suggesting it was always intended.

- **AVOID_TRAPS ("of Snares Eluded")** -- Requires trap detection to check equipment flags. The current trap system uses Hunting skill percentage; AVOID_TRAPS would need to either grant 100% avoidance or add a flat bonus.

### Minimum viable enchantment set

For a first release, I recommend implementing in this order:

**Tier 1 (must-have, ~20 enchantments):**
- All SLAY_ enchantments (Gondolin, Doriath, Wraith-bane, Final Rest, Westernesse, Mordor) -- these are the core combat progression
- All RES_ enchantments (Venom's End, Frost shield, Warmth cloak, Dale) -- survival essentials
- FREE_ACT sources (Woodmen, Mark, Final Rest) -- the critical gap fix
- SEE_INVIS sources (True Sight, Marchwardens) -- mandatory for mid-game
- Stealth enchantments (of Stealth on armor/cloaks/boots, of Murder on daggers, of the Ranger) -- stealth build support
- SUST_ALL (of Nogrod) -- stat drain protection
- Basic stat bonuses (of Resilience, of Grace, of Might) -- numerical progression

**Tier 2 (high-value, ~15 enchantments):**
- BRAND_ enchantments (Poisoned, of Morgul, new "of the Flame")
- Ability-granting weapons/shields (of Battering, of Piercing, of the Edain)
- Cursed items (of Fury, Vampiric, of Shadow, of Wrath) -- risk-reward
- Light enchantments (of Brilliance, of Brightness, modified Gondolin/Doriath with LIGHT)

**Tier 3 (nice-to-have, deferred):**
- New shield enchantments (Vanguard, Sentinel, Citadel, Dunedain, Warding)
- New boot enchantments (Shadow-stalker, Scout, Pursuit)
- New glove enchantments (Assassin, Cunning, Cutpurse)
- Boss loot tables

The rationale: Tier 1 items use only flag-based mechanics (SLAY, RES, stat bonuses) that can be wired into existing combat code with minimal new systems. Tier 2 adds BRAND damage and cursed item identification. Tier 3 requires the ability-grant system, which is the most complex new feature.

---

## 7. FUN FACTOR AND PLAYER RETENTION

### Enchantments that will make players say "one more run"

1. **Weapon of Wraith-bane** (SLAY_UNDEAD + SEE_INVIS) -- This is the "jackpot" weapon for the endgame. Finding it at depth 9 means the Necropolis and Wraith Domain become manageable instead of impossible. It solves two problems in one slot. Players who died to invisible wraiths will specifically hunt for this.

2. **Shield of the Vanguard** (grants Charge) -- Charge (+3 STR and DEX on rush attacks) on a shield is build-defining. A shield-and-sword fighter who finds this at depth 4 plays a completely different game than one without it. The "rush into combat" playstyle is viscerally satisfying.

3. **Boots of the Shadow-stalker** (grants Fade) -- For stealth builds, this is the dream item. Kill an unaware enemy, vanish for 2 turns, reposition, kill again. It turns the stealth assassin from "hope you don't get caught" to "calculated predator." The depth 8 availability means it arrives right when stealth builds need it most.

4. **Mithril Shield with Many Runes** (CHEAT_DEATH) -- The rarest enchantment in the game (depth 20, rarity 20, mithril shields only). Finding this is a story moment. "I was carrying Many Runes and it saved me from Khamul's death blow on floor 18." This is the kind of item that generates forum posts and run narratives.

5. **Gloves of the Assassin** (grants Assassination) -- Assassination (+Stealth to attack vs non-alert) without spending XP on Stealth 4 means a hybrid build (melee/stealth) becomes viable. The player can invest XP in Melee for damage while getting the stealth kill bonus from equipment.

### Enchantments that feel like filler

1. **"of the Traveller" (cloak)** -- SLOW_DIGEST is a very soft benefit in a game where food is available from floor 1 and the Indomitable ability reduces hunger to 1/3 rate. Unless Ironman difficulty makes hunger truly dangerous, this enchantment won't excite anyone.

2. **"of Blight" (armor)** -- VUL_POIS with no upside. Pure punishment. In SIL-Q, cursed egos serve the smithing system (they reduce difficulty, making items cheaper to forge). In The Necromancer's Reforge system (combine 2 broken items), this benefit doesn't exist. A player who finds "Scout's Armor of Blight" has simply found a worse-than-base item. Consider whether purely negative egos should exist without the SIL-Q smithing context.

3. **"of Brilliance" (helm)** -- LIGHT on a helm is marginal. By the time a player finds helms (depth 3+), they have a Wooden Torch providing +2 radius. Adding LIGHT (+1 radius presumably) on top of that is a minor benefit. It becomes relevant in the deep game where darkness modifiers eat light, but by then the player wants True Sight or Clarity, not a marginal radius bump.

4. **"of Dale" (gauntlets/greaves)** -- RES_COLD at depth 8. Cold damage doesn't appear until Spectres at depth 14 (6 floors later). This is a "save it for later" item that takes up inventory space for 6 floors. The depth should either be raised to 12 (when cold becomes relevant) or the item should be more broadly useful.

### Variety across multiple playthroughs

The roster provides strong variety. The combination of 60+ base enchantments, 16 new additions, 147 artifacts, 8 skill trees, 20 traits, and 4 races creates an enormous combinatorial space. Key variety drivers:

- **Race-enchantment synergies:** A Dwarf of Erebor (Smithing affinity) who finds "of Erebor" weapons (STR + RES_FIRE) has a thematic and mechanical alignment. An Elf of Greenwood (Stealth affinity) who finds "of Murder" daggers (Assassination + Stealth) has a different but equally satisfying alignment.

- **Cursed item decision trees:** Every cursed item creates a unique decision. "of the Noldor" (GRA + DEX + DANGER) is perfect for a Lore build but terrible for a stealth build. "(Vampiric)" (life steal + HUNGER) is great for a melee tank but dangerous for Ironman difficulty. These decisions change with every run.

- **Build-defining equipment finds:** The ability-granting enchantments (14 distinct abilities across boots, gloves, shields, and weapons) mean that two runs of the same race/house/trait can play completely differently based on what equipment appears. A Man of Gondor who finds Boots of Speed plays a mobile skirmisher; the same character with a Shield of the Sentinel plays a corridor-blocking juggernaut.

### Overall rating: 8/10

The enchantment roster is a thorough, lore-conscious, mechanically sound design document that addresses the game's most critical gap (flat item progression). It correctly identifies the highest-priority fixes (FREE_ACT timing, SLAY_UNDEAD availability, SEE_INVIS coverage, Dragon-bane removal), proposes creative new enchantments that expand build diversity (especially for stealth and shield builds), and establishes a loot curve that matches the game's narrative arc.

The 2-point deduction reflects: (1) the loot curve may be too generous at mid-depths and needs playtesting before committing, and (2) the ability-grant system has significant implementation risk that is not fully addressed. The document would also benefit from explicit guidance on ability stacking, Reforge tier filtering, and a phased implementation plan that separates flag-based enchantments (easy) from ability-grant enchantments (hard).

---

## 8. RECOMMENDATIONS

### Top 5 changes ranked by impact

1. **Define the ability-grant-from-equipment contract before implementing any ability-granting enchantments.** Specify: (a) do granted abilities stack with purchased ones? (b) what happens when you unequip the item? (c) do granted abilities count toward prerequisites for other abilities? (d) are granted abilities displayed differently in the UI? Without this contract, implementation will hit design ambiguity at every turn. This is the single most important pre-implementation task.

2. **Start with a more conservative loot curve and tune upward.** The proposed 70% ego rate at depth 10 is aggressive. Recommend starting at: 85/12/3/0 (floor 1-3), 70/20/10/0 (4-6), 55/25/18/2 (7-9), 40/25/30/5 (10-12), 35/20/35/10 (13-15), 25/20/40/15 (16-18), 15/15/50/20 (19-20). This preserves the scarcity-to-abundance arc while reducing the mid-game enchantment density by roughly 30%. Tune upward based on playtest win rates.

3. **Rename "of the Cutpurse" to "of the Burglar."** Minor but important for Tolkien tonal consistency. "Burglar" is canonically used for Bilbo's role and fits the Hobbit racial identity. Similarly, consider renaming the duplicate "of Lothlórien" (quarterstaff version) to "of the Mallorn" to avoid player confusion.

4. **Add explicit "not applicable" notes for wands, horns, scrolls, and discovery items.** The document's silence on these categories could be interpreted as oversight. A brief section stating "The following item categories are excluded from the ego system by design: wands, horns, herbs, potions, scrolls, food, and discovery items" prevents scope creep during implementation.

5. **Define Reforge tier filtering rules.** Specify which enchantments are available at each forge tier (Normal, Enchanted, Unique). Suggested rule: Normal forges can produce enchantments with depth <= 6. Enchanted forges can produce depth <= 12. Unique forges can produce any enchantment. This prevents a floor 4 Normal forge from generating a "Shield of the Sentinel" (depth 10 enchantment) and preserves the forge tier progression as a meaningful discovery.

### Implementation blockers

Nothing in the roster should block implementation entirely. However, the ability-grant enchantments (Tier 3 in my minimum viable set above) should be deferred until the ability-grant contract is defined and the system is built. Implementing Tier 1 (flag-based enchantments) and Tier 2 (brands + cursed items) is achievable without any new game systems.

### "Nice to have" vs "must have" for first release

**Must have:**
- special.txt parsing in DataManager
- Real ego selection replacing cosmetic placeholders
- SLAY_ combat integration
- BRAND_ combat integration
- RES_ damage reduction
- FREE_ACT paralyze resistance
- SEE_INVIS visibility
- Stat/skill bonuses from equipment (partially exists)
- of Wraith-bane replacing of Dragon-bane
- Ring of Free Action moved to depth 8
- Amulet of Starlight moved to depth 7
- LIGHT added to of Gondolin and of Doriath
- Semantic tooltip descriptions for all flags
- Boss drops on separate guaranteed table

**Nice to have (can ship without):**
- All 16 new enchantments (5 shields, 3 boots, 3 gloves, 2 armor, 1 weapon, 1 cloak, 1 weapon rework)
- Ability-grant-from-equipment system
- Wraith Domain drought loot curve (can use uniform curve initially)
- Fine/Special independent roll system (can treat all egos as one category initially)
- Cursed item identification (can defer CURSED/LIGHT_CURSE/removal mechanics)

---

## Appendix: Cross-Reference Verification

### Enchantments verified against special.txt

All existing enchantment IDs in the roster match their definitions in `special.txt`. Verified: IDs 1-15, 20-49, 51-52, 71-76, 80, 82-88, 91-96, 101-102, 110-116, 120-126, 130, 135. The file contains 62 entries total (including the version stamp). New IDs proposed (16-17, 50, 55-59, 85, 115, 117-118, 125, 127-128) do not conflict with existing IDs.

### Monster threats verified against monster.txt

Confirmed: 5 POISON monsters in Layer 1, ENTRANCE on ghouls at depth 7, INVISIBLE on 7 monsters (depths 10-19), LOSE_CON/STR/GRA on wights/shadows/barrow-wights, FIRE damage on Maia Thrall at depth 18, PASS_WALL on shadows/fell spirits/shadow lords. All threat claims in the roster are accurate.

### Artifact counts verified against artefact.txt

The file header states indices 1-19 (specials), 20-139 (normal), 175-179 (quest), 182-198 (smithing templates). The GDD states 147 total artifacts. The roster's claim of "~60 ego modifiers" in special.txt is confirmed (62 entries including version stamp).

### Code placeholder status verified

Confirmed: `dungeon_generator.gd:_apply_floor_ego()` (line ~2944) applies only cosmetic name prefixes and numerical bonuses. `monster.gd:_apply_ego_enchantment()` (line ~974) is identically cosmetic. Zero instances of SLAY_ in combat code. BRAND_ flags are stored by `player.gd:_apply_equipment_flags()` but never read by `entity.gd`. The document's core claim -- "the problem is not missing data, it's missing code" -- is verified as accurate.

---

*Review completed 2026-02-09. The enchantment roster is approved for implementation with the modifications noted above.*
