# Roguelike Expert Review: Necromancer Enchantment Roster v2

**Reviewer:** Roguelike Systems Analyst (50+ titles, 1980-2024)
**Document reviewed:** `docs/design/enchantment_roster.md` v2 (2026-02-08)
**Supporting materials:** Reports 1-3, `data/special.txt`, `data/monster.txt`
**Date:** 2026-02-09

---

## 1. LOOT CURVE ANALYSIS

### 1.1 The Scarcity-to-Abundance Arc

The proposed mundane drop-off curve (75% / 60% / 45% / 30% / 25% / 15% / 5%) across a 20-floor dungeon is well-shaped. It follows the same exponential decay that Angband uses for its depth-based generation, but compresses it into a much shorter game. In a traditional Angband run, a player might see 100 floors before the loot becomes consistently excellent. Here, you have 20 floors. That compression demands a steeper curve, and this delivers one.

The decision to start at 75% mundane rather than 85% or 90% is correct for a game of this length. Report 3's bot data shows that 41.9% of runs die on floor 1. If a player who barely survives three floors never encounters a single enchanted item, the enchantment system might as well not exist for them. At 75% mundane with approximately 10 items found in floors 1-3, the probability of finding at least one enchantment approaches 95%. That is the right threshold -- nearly every player who survives the spider gauntlet will have tasted the enchantment system before they die or descend.

The midgame transition (floors 7-12 dropping from 45% to 30% mundane) is where the curve shines brightest. This is the zone where the game shifts from "survive with what you find" to "build your loadout." The 25-35% major enchantment rate in this band means players are making real equipment decisions every few floors. This mirrors what DCSS does in its branch transitions -- the Lair is where you first start seeing ego weapons, and Shoals/Snake/Swamp is where you start assembling resistance kits. The Necromancer's Dark Halls through Necropolis serve the same structural purpose.

### 1.2 The Artifact Cap

Capping artifacts at 30% even in the Throne Room is a bold and correct decision. In Angband, the late game becomes a flood of artifacts that reduces individual items to statistical noise. You are scrolling through ten Rings of Power trying to find the one with the right resistance combination. By capping artifacts at 30% and making major enchantments the 55% workhorse of the endgame, this design ensures that each artifact retains narrative weight. A player finding Orcrist on floor 14 should feel like discovering a named sword in a Tolkien novel, not like picking up another piece of vendor trash.

The comparison to Brogue is instructive here. Brogue limits enchant scrolls to approximately 15-20 per full game, and each one is a significant decision. The Necromancer's artifact cap creates a similar dynamic -- you might find 3-5 artifacts in a full run, and each one reshapes your build. That is the right density for a 20-floor game.

### 1.3 The Wraith Domain Drought (Floors 13-15)

This is the most interesting design decision in the entire document, and potentially the most risky. Dropping minor enchantments to 15% on floors 13-15 creates a deliberate loot drought in the most terrifying section of the dungeon. The intent is clear: the Wraith Domain should feel like a gauntlet where your preparation is tested, not a shopping trip where you upgrade.

This works because of two factors: first, the boss on floor 15 (Uvatha the Horseman) guarantees an artifact drop, creating a powerful tension-release cycle. Second, the player should have assembled their core loadout in the Necropolis (floors 10-12), where major enchantments are at 35% and artifacts are at 15%. The drought tests whether that loadout is sufficient.

The risk is that a player who got unlucky in floors 10-12 enters the Wraith Domain underequipped AND finds nothing to compensate. In DCSS, the Vaults serve a similar function as a loot-sparse danger zone, but DCSS gives the player the option to go elsewhere first. The Necromancer is linear -- there is no alternate path. I recommend monitoring this in playtesting. If more than 40% of runs that reach floor 13 die in the drought zone due to equipment gaps rather than tactical mistakes, the minor enchant rate should be bumped from 15% to 20%.

### 1.4 Boss Loot Tables

The boss loot table progression (Floor 3 = minor enchant, Floor 6 = major, Floor 9+ = major/artifact, Floor 12+ = guaranteed artifact) is excellent. Boss fights in roguelikes need to feel rewarding beyond the XP they grant. In Cogmind, boss encounters drop unique components that cannot be found elsewhere. In DCSS, unique monsters drop their named weapons. The Necromancer's boss table ensures that every boss kill provides meaningful progression.

One concern: the document specifies "guaranteed" drops but does not specify whether these are on the floor loot table or a separate restricted table. If the floor 3 boss can drop a Cloak of Winter's Chill (cursed, VUL_COLD), that is a terrible reward for a boss fight. Boss drops should exclude cursed items. The document says "guaranteed drops one tier above floor median" but this needs to be explicit: **boss drops must be from a curated positive-enchantment pool**.

### 1.5 Comparative Assessment

| Game | Loot Curve Model | Necromancer Comparison |
|------|-----------------|----------------------|
| Angband | Pure depth-based random, artifact uniqueness | Necromancer is tighter, better paced |
| DCSS | Branch-locked loot, enchant scrolls as currency | Necromancer uses depth gating instead of branch locks, similar scarcity model |
| Brogue | Enchant scroll economy, limited upgrades | Necromancer's artifact cap mirrors Brogue's enchant scarcity |
| Sil/Sil-Q | Fine/Special split, smithing as control valve | Direct ancestor, Necromancer adds boss tables and drought zones |
| Caves of Qud | Procedural artifacts, no fixed loot curve | Opposite philosophy; Necromancer is more structured |

The loot curve is **good**. It is not groundbreaking, but it is well-calibrated for a 20-floor game.

**Rating: 8/10** -- Loses points for the untested drought zone risk and the ambiguity around boss drop pools.

---

## 2. ENCHANTMENT VARIETY AND COVERAGE

### 2.1 Slot Coverage

The enchantment roster, after the proposed additions, provides the following coverage per slot:

| Slot | Existing Egos | Proposed New | Total | Cursed | Verdict |
|------|--------------|-------------|-------|--------|---------|
| Body Armor (soft) | 7 | 0 | 7 | 1 (Blight) | Good |
| Body Armor (mail) | 5 | 2 (Flame-guard, Endurance) | 7 | 0 | Good |
| Shields | 4 | 5 (Vanguard, Citadel, Sentinel, Dunedain, Warding) | 9 | 1 (Wrath) | Excellent |
| Swords | 12 | 1 (Wraith-bane replacing Dragon-bane) | 12 | 3 | Excellent |
| Polearms/Axes | 10 | 1 (the Flame) | 11 | 2 | Excellent |
| Helms | 6 | 0 | 6 | 1 (Terror) | Good |
| Cloaks | 6 | 1 (the Unseen) | 7 | 1 (Winter's Chill) | Good |
| Boots | 6 | 3 (Shadow-stalker, Scout, Pursuit) | 9 | 1 (Treacherous Paths) | Excellent |
| Gloves | 6 | 3 (Assassin, Cunning, Cutpurse) | 9 | 1 (Treachery) | Excellent |
| Bows | 6 | 0 | 6 | 1 (the Wild) | Adequate |
| Arrows | 2 | 0 | 2 | 0 | Thin |
| Digging | 2 | 0 | 2 | 0 | Minimal but appropriate |
| Light Sources | 3 | 0 | 3 | 1 (Flickering Shadow) | Adequate |

The weakest slot is arrows (only Poisoned and Piercing). SilQ also had only 2 arrow egos, so this is inherited rather than an oversight. However, for an archery-focused build, finding interesting arrows is part of the fantasy. Consider adding a single "of Flame" arrow ego (BRAND_FIRE, depth 10) to parallel the weapon addition. This would give archers a fire option in the Necropolis where HURT_LITE undead are everywhere.

### 2.2 Dead Enchantments

I see no truly dead enchantments in the roster. The replacement of Dragon-bane (SLAY_RAUKO + SLAY_DRAGON, zero valid targets) with Wraith-bane (SLAY_UNDEAD + SEE_INVIS) is exactly the right call. Every slay flag now has valid targets confirmed in monster.txt.

The closest thing to a dead enchantment is **Helm of Terror** (FEAR, cursed). The document itself notes "Never equip intentionally." In SilQ, cursed items serve as smithing difficulty reducers, but the Necromancer's simplified smithing system (Reforge/Reclaim) does not use difficulty calculations. If the smithing system does not benefit from curse penalties, Helm of Terror is pure trap with no interesting decision. Consider removing it from the drop table or giving it a minor positive effect (e.g., +1 protection die) to create a genuine tradeoff.

**Shield of Wrath** (AGGRAVATE) has the same problem. At least give it +1 damage side to the shield's protection or +1 STR to make the AGGRAVATE curse an actual decision rather than an inventory slot wasted.

### 2.3 Flag Distribution

| Flag Category | Count of Sources | Coverage Assessment |
|---------------|-----------------|---------------------|
| SLAY_ORC | 3 egos + artifacts | Good -- covers Orc Warrens |
| SLAY_TROLL | 2 egos + artifacts | Adequate |
| SLAY_SPIDER | 2 egos + artifacts | Adequate for Layer 1 |
| SLAY_WOLF | 1 ego + artifacts | Thin but wolves are only Layer 2 |
| SLAY_UNDEAD | 4 egos + artifacts | Excellent -- covers 60% of monsters |
| BRAND_FIRE | 1 new ego + artifacts | Thin; only one ego source |
| BRAND_COLD | 1 ego (Morgul, cursed) + artifacts | Very thin for non-cursed options |
| BRAND_POIS | 2 egos (weapon + arrow) | Adequate |
| FREE_ACT | 5+ ego sources + ring + artifacts | Excellent after proposed changes |
| SEE_INVIS | 7 sources across 6 slots | Excellent |
| RES_FIRE | 5+ sources | Excellent |
| RES_COLD | 4+ sources | Good |
| RES_POIS | 3+ sources | Good |
| SUST_ALL | 1 ego (Nogrod) | Thin for the most critical sustain |

The one notable gap is non-cursed BRAND_COLD. The only ego source is of Morgul (BRAND_COLD + DARKNESS + LIGHT_CURSE). For a player who wants cold damage without selling their soul, the only option is artifacts. This is a defensible design choice (cold brands should be rare and thematically "dark"), but worth noting.

### 2.4 Missing Archetypes

The roster supports warriors, stealth builds, and archer hybrids well. Two archetypes are underserved:

1. **Pure Lore/Voice caster:** The Lore skill tree (replacing Song) is an entire progression path, but the enchantment roster has almost no Lore-boosting egos. Only "of Rivendell" (daggers, +3 SONG/LORE) and "of Lothlórien" (bows/swords, +2 GRA) support this build. A dedicated Lore user would want a Lore-boosting helm, cloak, or amulet ego. Consider adding a "of the Loremaster" helm (depth 8, +2 LORE, LIGHT) to serve this archetype.

2. **Tank/Shieldwall:** The new shield egos (Citadel, Sentinel, Warding) massively improve this archetype, which is a strong design choice since Report 3 shows SHIELD_WALL as the best-performing bot archetype. However, there is no shield ego that grants a direct protection bonus beyond "of Protection" (+1 protection side). A shield-focused character wants layered protection. The Sentinel's +1 prot die partially addresses this. Adequate, but monitor whether tanks feel their shields are interesting enough.

---

## 3. BUILD DIVERSITY

### 3.1 Viable Build Sketches

**Build 1: The Gondorian Knight (Melee Tank)**
- Weapon: Longsword of Westernesse (SLAY_UNDEAD, LIGHT) or of Final Rest (SLAY_UNDEAD, FREE_ACT)
- Shield: Tower Shield of the Citadel (STAND_FAST, RES_FEAR, +1 WILL)
- Armor: Gondor Corslet of Gondor (WILL, RES_FEAR) or Mail of Endurance (REGEN, SUST_CON)
- Helm: Iron Helm of Defiance (+3 Will, RES_FEAR)
- Boots: Greaves of Dale (RES_COLD)
- Cloak: Cloak of the Tower (RES_BLEED, SUST_CON)
- Gloves: Gauntlets of Swordplay (Parry)
- Ring: Ring of Free Action (depth 8)
- Strategy: Stack WILL and RES_FEAR, use shield abilities defensively, wade through undead

**Build 2: The Shadow Ranger (Stealth Assassin)**
- Weapon: Dagger of Murder (+3 Stealth, Assassination)
- Off-hand: None (daggers are one-handed, could dual-wield with of Accompaniment)
- Armor: Ranger Leathers of Stealth (+3 Stealth) or of the Ranger (+2 Stealth, +2 Hunting)
- Boots: Boots of the Shadow-stalker (Fade -- vanish after stealth kill)
- Cloak: Cloak of Stealth (+3 Stealth) or of the Unseen (SEE_INVIS, +2 Stealth)
- Gloves: Leather Gloves of the Assassin (Assassination, +1 Stealth)
- Helm: Helm of True Sight (SEE_INVIS, RES_BLIND)
- Ring: Ring of the Forester (+Stealth)
- Strategy: Stack Stealth to 20+, use Assassination for burst kills, Fade for escape. Rely on stealth XP and exploration XP for progression. The Cutpurse gloves offer an alternate path focused on loot generation.

**Build 3: The Elven Archer (Ranged Hybrid)**
- Weapon: Longbow of the Marchwardens (SEE_INVIS, RES_FEAR)
- Backup: Longsword of Gondolin (SLAY_ORC, SLAY_TROLL, LIGHT) for melee emergencies
- Armor: Scout's Armor of the Ranger (+2 Stealth, +2 Hunting)
- Boots: Boots of the Scout (Listen, +1 Stealth) or of Leaping (tactical repositioning)
- Cloak: Cloak of the Golden Wood (RES_FEAR, SUST_GRA)
- Gloves: Gloves of Archery (+3 Archery)
- Helm: Helm of Brilliance (LIGHT) or of True Sight (SEE_INVIS)
- Ring: Ring of Dexterity (depth 10)
- Arrows: Poisoned Arrows (BRAND_POIS) or Arrows of Piercing (SHARPNESS)
- Strategy: Maintain distance, use Listen for detection, switch to Gondolin sword when cornered. Elven bow enchantments provide fear immunity and invisible detection.

**Build 4: The Dwarven Smith (Crafting Power)**
- Weapon: Dwarven War-axe of Erebor (+1 STR, +1ds, RES_FIRE)
- Shield: Buckler of Deflection (+2 evasion) -- or no shield for two-handed weapons
- Armor: Dwarven Hauberk of the Iron Hills (STAND_FAST, RES_FEAR)
- Helm: Helm of the Dwarrowdelf (+1 CON, +WILL)
- Boots: Greaves of Snares Eluded (AVOID_TRAPS, FREE_ACT)
- Gloves: Gauntlets of Might (+1 STR)
- Ring: Ring of Durin's Folk (+STR, RES_FIRE)
- Strategy: Rush Smithing skill to unlock Reforge/Reclaim, use forges to fill equipment gaps. Stack STR for maximum damage output. The Erebor enchantment line provides fire resistance naturally. Use Reforge Mastery to reject bad rolls until you get the enchantment you need.

These four builds are meaningfully different in playstyle, equipment choices, and skill priorities. The enchantment roster supports at least 4 distinct viable paths, which meets the minimum bar for build diversity in a roguelike.

### 3.2 Must-Have Enchantments

The biggest threat to build diversity is "must-have" enchantments that every build needs regardless of archetype. In this roster, the following are close to universal requirements:

1. **FREE_ACT** -- Every build needs paralysis protection by floor 7. Ghouls do not care whether you are a tank or a rogue.
2. **SEE_INVIS** -- Every build needs this by floor 10. Invisible enemies are non-negotiable.
3. **SUST_CON** -- Stat drain is permanent. Every build needs some form of sustain.

The design handles this well by providing these flags across multiple slots: FREE_ACT appears on armor (Woodmen, depth 6), weapons (Final Rest, depth 7; the Mark, depth 6), shields (Warding, depth 8), boots (Snares Eluded, depth 10), and rings (depth 8 after the proposed change). A player does not need to find a specific item -- any one of six+ sources solves the problem. This is the right approach. Compare to DCSS, where rF+ (fire resistance) is near-universal for the late game but appears on many different item types.

### 3.3 Stealth Build Support

Report 3's bot data shows stealth archetypes (GREENWOOD_RANGER, HOBBIT_BURGLAR, STEALTH_PURE) underperform combat archetypes significantly. The MEMORY.md notes "STEALTH_PURE avoids 68 combats but only 0.1 stealth kills -- runs from everything, can't kill."

The enchantment roster directly addresses this with:
- **of Murder** (Assassination on daggers, depth 0-4) -- enables stealth kills from the start
- **of the Assassin** (Assassination on gloves, depth 6) -- frees XP from the Stealth tree
- **of the Shadow-stalker** (Fade on boots, depth 8) -- the build-defining "vanish after kill" loop
- **of the Cutpurse** (Pilfer on gloves, depth 8) -- alternative stealth economy (loot farming)
- **of Cunning** (Opening Strike on gloves, depth 4) -- first-hit advantage for ambush builds
- **of the Scout** (Listen on boots, depth 4) -- early detection for avoidance play

This is a substantial improvement. The stealth build now has a progression path: early game use Murder daggers for Assassination, midgame find Assassin gloves to free your skill points, late game assemble Shadow-stalker boots for the Fade loop. Each piece builds on the previous one. This is how enchantment progression should work -- each item opens a new dimension of play.

However, I note that the stealth build is still XP-starved relative to combat builds. Stealth explore XP (1 per tile) and stealth kill XP (2x) help, but the enchantment system could do more. The Cutpurse gloves (Pilfer, 25% extra drops) are the only loot-focused enchantment. Consider whether Pilfer should also grant bonus XP from stealth kills, or whether the 25% extra drop rate is sufficient compensation.

---

## 4. DEPTH GATING AND PROGRESSION

### 4.1 The FREE_ACT Timeline

This was the most critical gap identified in Report 3 and the enchantment roster addresses it comprehensively:

| Depth | Threat | FREE_ACT Sources Available |
|-------|--------|---------------------------|
| 6 | Dark Acolyte (SLOW, 40%) | of the Woodmen (armor, depth 6), of the Mark (weapon, depth 6) |
| 7 | Ghoul (ENTRANCE) | All depth-6 sources + of Final Rest (weapon, depth 7) |
| 8 | Dark Sorcerer (SLOW/HOLD, 50%), Ghast (ENTRANCE) | All above + Ring of Free Action (moved to depth 8), Shield of Warding (depth 8) |
| 9 | Master Sorcerer boss (HOLD, 60%) | All above |

The fix is thorough. Moving the Ring of Free Action from depth 12 to depth 8 is the single most important balance change in the document. The gap between "ghouls appear at depth 7" and "first FREE_ACT at depth 12" was a 5-floor dead zone where the game's paralysis mechanic had no counterplay. Now the gap is 1 floor (ghouls at 7, first ego sources at 6), which is actually ideal -- the player encounters the threat, dies to it, and on the next run knows to prioritize FREE_ACT items.

### 4.2 SEE_INVIS Timeline

| Depth | Invisible Monster | SEE_INVIS Sources Available |
|-------|-------------------|---------------------------|
| 10 | Corpse-candle (CONFUSE, INVISIBLE) | Helm of True Sight (depth 0), Bow of the Marchwardens (depth 6), Shield of the Dunedain (depth 6), Amulet of Haunted Dreams (depth 9, cursed) |
| 12 | Phantom (INVISIBLE) | All above + Ring of Shadow-ward (depth 12) |
| 13 | Shadow (INVISIBLE, PASS_DOOR) | All above |
| 14 | Fell Spirit (INVISIBLE, PASS_WALL) | All above + new Cloak of the Unseen (depth 10), Weapon of Wraith-bane (depth 9) |

Seven sources across six slots. This is well-covered. The critical detail is that the Helm of True Sight is available at depth 0 -- a lucky early find solves the problem for the entire game. This is correct. In SilQ, SEE_INVIS helms were also depth 0, and they served as one of the game's most exciting early finds. Preserving that dynamic is right.

### 4.3 The Darkness Counter

The Amulet of Starlight move from depth 9 to depth 7 is a good catch. Darkness spells begin at depth 6 (Dark Acolyte), and the FOV drops to 7 with a -1 darkness modifier in the Dark Halls (layer 3). By depth 7, the player is fighting in near-darkness against ghouls and sorcerers who cast DARKNESS. Having a LIGHT + RES_DARK amulet available at depth 7 provides a timely counter.

Adding LIGHT to Gondolin and Doriath weapon enchantments is also mechanically sound. These weapons were already some of the most desirable early-game finds (SLAY_ORC, SLAY_TROLL for the Orc Warrens). Adding LIGHT makes them even more useful in the Dark Halls, extending their relevance deeper into the game. A Longsword of Gondolin found on floor 4 is now relevant through floor 12 -- it slays orcs AND lights your path. That is excellent item longevity.

### 4.4 Remaining Timing Gaps

One gap the document does not address: **RES_FIRE timing**. The first fire-dealing monster is the Maia Thrall at depth 18 (3d10 FIRE damage). Sauron at depth 20 deals 5d12 FIRE. The earliest fire resistance sources are Ring of Durin's Folk (depth 7), Shield of Frost (depth 10), the new Flame-guard armor (depth 10), and various artifacts. This is actually fine -- fire resistance is available well before fire damage appears. The gap is cosmetic, not real.

A subtle concern: **RES_CONFU timing**. Confusion effects begin with Dark Sorcerer at depth 8 (CONF, 50% spell rate) and Pale Crawler at depth 10 (CONFUSE touch). The earliest non-ring RES_CONFU is Helm of Clarity (depth 0). Ring of Ered Luin (RES_FEAR + RES_CONFU, depth 8). The Shield of Warding adds RES_CONFU at depth 8. This is adequately covered.

### 4.5 Fine/Special Roll Interaction

The Fine/Special system (inherited from SilQ) creates interesting depth interactions. At depth 10, Fine chance is 20% and Special chance is 10%. By depth 20, these become 40% and 20%. This means endgame items have a meaningful chance of being both Fine AND Special (a "fine longsword of Wraith-bane" with +1 attack AND SLAY_UNDEAD + SEE_INVIS). This stacking creates those "jackpot" moments that make loot exciting.

The DROP_GOOD flag (guaranteed fine OR special) and DROP_GREAT flag (guaranteed fine AND special) on monster definitions create predictable loot from specific encounters. Bosses with DROP_GREAT guarantee the best possible items. This is a good system that rewards targeting dangerous monsters.

---

## 5. BALANCE RED FLAGS

### 5.1 Potentially Overpowered

**Shield of Warding (RES_CONFU + RES_STUN + FREE_ACT, depth 8):** This is three powerful resistances on a single item at a relatively early depth. In SilQ, getting all three of these required occupying three separate equipment slots. A single Shield of Warding solves the entire magic-defense problem for the Dark Halls and beyond. This is the "one ring to rule them all" of anti-magic defense.

Recommendation: Increase rarity to 8 (from 4) or increase depth to 10. The shield should be findable but not common. Alternatively, remove one of the three flags (RES_STUN is the least critical) to force the player to supplement with other gear.

**Gloves of the Assassin (Assassination + Stealth, depth 6):** Granting the Assassination ability (which normally requires significant Stealth skill investment) on a piece of equipment at depth 6 is very strong. It essentially gives stealth builds a free high-tier ability, freeing skill points for other investments. The concern is that this makes Assassination too easy to acquire, reducing the XP decision tension.

Mitigation: The rarity of 4 helps, and the item is gloves-only (competition with Parry gloves, Archery gloves, and Iron Hills gauntlets). The opportunity cost of the glove slot provides natural balance. I rate this as "monitor but likely fine."

**Weapon of Wraith-bane (SLAY_UNDEAD + SEE_INVIS, depth 9):** Two of the most critical late-game flags on a single weapon. Finding this weapon at depth 9 solves both the "kill undead" and "see invisible" problems simultaneously, freeing your helm and ring slots for other uses. This is intentionally designed as "the deep-game anti-wraith jackpot" and it delivers on that promise. The depth 9 entry point means it cannot trivialize the early undead encounters (which start at depth 7).

I rate this as appropriately powerful. It is the reward for reaching the Necropolis alive.

### 5.2 Potentially Underpowered

**Boots of Pursuit (Flanking, depth 10, rarity 4):** Flanking (+attack from side/behind) requires the player to manually position themselves to the side or rear of an enemy. In a tile-based roguelike, this requires spending movement actions to circle an enemy, which costs turns and potentially exposes you to other threats. On boots -- a slot that competes with Sprinting, Leaping, Shadow-stalker (Fade), and Scout (Listen) -- Flanking feels like the weakest option. The depth 10 entry point means it competes with Speed boots (also depth 10) which grant Sprinting.

Recommendation: Either reduce the depth to 6 (making it an early-midgame tactical option before better boots appear) or add a secondary bonus (+1 Stealth or +1 Evasion) to make the item competitive at depth 10.

**(Balanced) weapons (ACCURATE, depth 14, rarity 20):** Accurate is a precision modifier that helps with critical hits. At depth 14 with rarity 20, this is one of the rarest enchantments in the game. But ACCURATE alone does not compare to the power of depth-14 alternatives like Wraith-bane (SLAY_UNDEAD + SEE_INVIS) or of the Noldor (+GRA, +DEX, DANGER). The high rarity makes this feel like a rare find that disappoints.

Recommendation: Reduce rarity to 12 or add a secondary effect (+1 attack). Finding a perfectly balanced weapon at depth 14 should feel like finding a master-crafted blade, not a statistical curiosity.

### 5.3 Smithing System Interaction

The smithing system is the biggest balance wildcard. The design document specifies that Reforge selects "random ego appropriate for output type and forge tier" and Reclaim selects "random artifact appropriate for output type." With Reforge Mastery (reject/reroll) and Reclaim Mastery (choose from 3), a patient player with enough Broken Strange materials can effectively choose their artifact.

This has the potential to completely bypass the scarcity curve. If Broken Strange items spawn reliably near forges (the C code spawns 3 broken items per forge), a player who prioritizes Smithing skill can potentially have multiple artifacts by floor 12 -- well ahead of the curve.

The existing smithing overhaul (commit 00c1821) implements forge types with limited uses, type-filtered output, and XP costs with Expertise discounts. These are good constraints. However, the document does not specify whether the ego/artifact selection respects the floor's depth gating. Can a player Reforge on floor 6 and receive a depth-12 enchantment? If yes, the smithing system breaks the depth curve. If no, the smithing system is a controlled alternate path that supplements natural drops.

**This must be specified before implementation.** The Reforge/Reclaim selection MUST be filtered by current floor depth, not just by item type and forge tier.

### 5.4 Artifact Power Levels

Examining the artifact list from Report 2, the power level range is appropriate. Early artifacts (depth 3-8) provide single powerful effects (Sting: SLAY_ORC + SLAY_SPIDER + SEE_INVIS + LIGHT). Mid-game artifacts (depth 10-14) provide multi-flag combinations (Narsil: LIGHT + RES_FIRE + RES_COLD + SLAY_UNDEAD). Late-game artifacts (depth 16-20) provide build-defining power (Robe of Rivendell: SPEED + FREE_ACT).

The SPEED flag remaining artifact-only is the right call. SPEED is the single most powerful effect in the game -- it determines whether you can escape Sauron. Making it available only through artifacts (or extremely rare circumstances) ensures that finding a SPEED source is always a pivotal moment.

---

## 6. FUN FACTOR ASSESSMENT

### 6.1 Exciting Finds

The following enchantments create genuine excitement moments:

- **Shield with Many Runes (CHEAT_DEATH):** Finding this on a Mithril Shield at depth 20 is the ultimate insurance policy. The knowledge that you have one extra life changes how aggressively you play. This is the equivalent of the Amulet of Life Saving in NetHack.
- **Dagger of Murder (+3 Stealth, Assassination):** For a stealth player, this is build-enabling at depth 0-4. Finding this early defines your entire run.
- **Boots of the Shadow-stalker (Fade):** Kill an unwary enemy and become invisible for 2 turns. This creates a viscerally exciting gameplay loop: sneak, kill, vanish, reposition, repeat.
- **Sword of Wraith-bane (SLAY_UNDEAD + SEE_INVIS):** The named weapon fantasy. You find a blade that reveals and slays the invisible dead. This is Tolkien's Sting distilled into a single enchantment.
- **Any artifact find:** At 30% cap, artifacts remain rare enough to be exciting through the entire game.

### 6.2 Inventory Filler

The following enchantments risk feeling like filler:

- **Cloak of the Traveller (SLOW_DIGEST):** Hunger is described as a "soft mechanic" in Report 3. SLOW_DIGEST does not change gameplay in a meaningful way for most runs. It is insurance against a problem that rarely kills.
- **Helm of Brilliance (LIGHT):** LIGHT is useful but not exciting. It is the "socks for Christmas" of enchantments.
- **Boots of Ithil's Light (RADIANCE, Mithril Greaves only):** RADIANCE on boots competes with Sprinting, Leaping, Fade, and Listen. Area light is nice but not build-defining. The Mithril Greaves restriction makes this even less exciting -- by the time you find Mithril Greaves, you probably have better light solutions.

### 6.3 Discovery and Surprise

The system provides good discovery through several mechanisms:

1. **Unidentified enchantments:** The player must learn what "of Gondolin" means through use or identification. This creates anticipation when finding new ego types.
2. **Cursed items:** The risk of equipping an unidentified cursed item (of Morgul, of Shadow, of Fury) creates tension in equipment decisions.
3. **Smithing surprise:** Reforging broken materials produces random results, creating a "what will I get?" moment.
4. **Ability-granting items:** Finding Gloves of the Assassin or Boots of the Shadow-stalker changes HOW you play, not just your numbers. This is the highest form of loot excitement.

The semantic description system (natural language instead of raw numbers) enhances discovery. Reading "Deadly against the undead" is more evocative than "SLAY_UNDEAD." The example tooltips in the document are well-crafted and add narrative texture.

### 6.4 Overall Loot Excitement Rating

**7.5/10**

The system has a strong foundation with clear progression, meaningful choices, and genuine excitement moments. It loses points in three areas: (1) the early game has limited enchantment variety due to the 75% mundane rate, meaning many short runs will see only basic items; (2) several enchantments are passive-defensive (resistances, sustains) which solve problems but do not create excitement; (3) the drought zone is a deliberate fun-reduction that needs to pay off with the Uvatha boss loot.

For comparison, I would rate Brogue's enchantment system at 9/10 (every scroll decision is agonizing), SilQ's smithing at 8/10 (the forge planning is deeply engaging), DCSS's ego item system at 7/10 (well-distributed but rarely exciting), and Angband's random drops at 5/10 (too much noise, not enough signal).

---

## 7. RECOMMENDATIONS

### Top 5 Changes, Ranked by Impact

**1. [BLOCKER] Specify that Reforge/Reclaim must respect floor depth gating.**
The design document does not explicitly state whether smithing output respects depth restrictions on enchantments. If a player can Reforge on floor 6 and receive a depth-12 ego like "of the Noldor" (+GRA, +DEX, DANGER), the entire scarcity curve is broken. The implementation MUST filter ego selection by `min(current_floor_depth, forge_tier_bonus + current_floor_depth)`. This is the single most important specification missing from the document.

**2. [BLOCKER] Specify that boss drops exclude cursed enchantments.**
The boss loot table system says "guaranteed drops one tier above floor median" but does not exclude cursed items. A Floor 3 boss dropping a Helm of Terror (FEAR, cursed) or a Cloak of Winter's Chill (VUL_COLD) would be a terrible player experience. The implementation must explicitly exclude any enchantment with negative-only flags from boss drop tables. Use the `only_good` filter from SilQ's `make_special_item()` function (Report 1, Section 5.3).

**3. [HIGH] Increase Shield of Warding rarity from 4 to 8.**
Three powerful anti-magic resistances (RES_CONFU + RES_STUN + FREE_ACT) on a single item at depth 8 with rarity 4 is too generous. At rarity 4, this item appears roughly as often as Shield of Frost (RES_FIRE, rarity 1) but provides three times the defensive value. Increasing rarity to 8 makes it a memorable find rather than a common solution. The player should still need to assemble anti-magic defense from multiple sources in most runs.

**4. [MEDIUM] Add a Lore/Voice-boosting helm ego.**
The Lore skill tree (the renamed Song system) is an entire progression path with 12+ abilities, but has almost no ego support. A "of the Loremaster" or "of the Wise" helm (depth 8, +2 LORE, LIGHT) would serve the caster archetype the same way Murder daggers serve stealth builds. Without this, the Lore build relies entirely on artifacts for skill bonuses, making it feel unsupported by the enchantment system.

**5. [MEDIUM] Reduce Boots of Pursuit depth from 10 to 6, or add a secondary bonus.**
At depth 10, Pursuit boots (Flanking) compete directly with Speed boots (Sprinting) and Shadow-stalker boots (Fade). Flanking is the weakest of these three abilities in a roguelike context where positioning is expensive. Either make it available earlier (depth 6) so it fills a niche before better options appear, or add +1 Stealth or +1 Evasion to make it competitive at depth 10.

### Nice-to-Have (Not Critical)

- Add a "of Flame" arrow ego (BRAND_FIRE, depth 10) to give archers a fire option against HURT_LITE undead.
- Give Helm of Terror a minor positive effect (+1 protection side) to create a genuine cursed-item decision rather than a pure trap.
- Give Shield of Wrath a minor positive effect (+1 STR or +1 damage side) for the same reason.
- Consider whether Cloak of the Traveller (SLOW_DIGEST) should be replaced with something more interesting for the cloak slot, or accept it as the "safe boring option" that serves new players who have not yet learned to manage hunger.
- Monitor the Wraith Domain drought (floors 13-15) in playtesting. If death rates in this zone exceed 40% among players who reached floor 13, increase minor enchant rate from 15% to 20%.

### Implementation Priority

If resources are limited, implement in this order:
1. Parse `special.txt` and apply ego flags to items (the core system)
2. Fine/Special roll system tied to depth
3. The two depth changes (Ring of Free Action to 8, Amulet of Starlight to 7)
4. The Dragon-bane to Wraith-bane replacement
5. LIGHT added to Gondolin and Doriath
6. Boss loot tables with cursed-item exclusion
7. The 16 new enchantments (shields, boots, gloves, weapons, armor, cloaks)
8. Semantic UI descriptions
9. Smithing integration with depth-filtered ego selection

The first five items fix critical balance gaps and require only data file changes. Items 6-7 require new code. Items 8-9 are polish.

---

## Appendix: Enchantment Density by Depth Band

For reference, here is the total number of enchantment types available at each depth threshold (counting only non-cursed egos):

| Depth | New Egos Unlocked | Cumulative Total | Notable Additions |
|-------|------------------|------------------|-------------------|
| 0 | 22 | 22 | Protection, Stealth, Gondolin, Deflection, Murder, True Sight, all basics |
| 2 | 5 | 27 | Doriath, Archery, Deeps, North staff |
| 4 | 8 | 35 | Woodmen (FREE_ACT), Ranger, Mirkwood, Piercing, Swordplay, Scout boots, Cunning gloves, Vampiric |
| 6 | 8 | 43 | Gondor, Westernesse, Mark (FREE_ACT), Marchwardens (SEE_INVIS), Assassin gloves, Dunedain shield, Black Yew, Radiance |
| 7 | 2 | 45 | Final Rest (SLAY_UNDEAD + FREE_ACT), Leaping boots |
| 8 | 8 | 53 | Edain, Lothlórien, Erebor, Dale, Dwarrowdelf, Shadow-stalker boots, Warding shield, Citadel shield |
| 9 | 1 | 54 | Wraith-bane (SLAY_UNDEAD + SEE_INVIS) |
| 10 | 10 | 64 | Frost shield, Resilience, Fury, Eorlingas, Crushing, Sentinel shield, Flame weapon, Flame-guard armor, Speed boots, Pursuit boots, Might gloves, Snares Eluded, Unseen cloak |
| 12 | 5 | 69 | Noldor, Shadow, Grey Havens, Galadhrim, Endurance armor |
| 14 | 1 | 70 | Balanced |
| 20 | 1 | 71 | Many Runes (CHEAT_DEATH) |

This distribution shows healthy growth through the game. The big jumps at depth 0 (22 egos), depth 4 (8 new), depth 6 (8 new), depth 8 (8 new), and depth 10 (10 new) correspond to the layer transitions where new threats appear. The depth 10 spike is the largest, which makes sense -- the Necropolis is where the game's complexity fully opens up.

---

*Review completed 2026-02-09. This document should be read alongside the enchantment roster v2 and Reports 1-3. All specific item references, depth values, and flag combinations have been verified against `data/special.txt` and `data/monster.txt` as they exist in the current codebase.*
