# Necromancer Enchantment & Artifact Roster — Final Design (v2)

**Generated:** 2026-02-08
**Source Reports:** Report 1 (SilQ Analysis), Report 2 (Necromancer-Dev Audit), Report 3 (Gameplay Analysis)
**Reviewed by:** Roguelike Expert, Tolkien Lore Expert, Necromancer-Dev Expert, Professional Analyst
**Status:** APPROVED — Ready for implementation planning
**Committee Score:** 8.2/10 (Approve with Modifications)

---

## Executive Summary

### The Core Finding

The Necromancer already has **60+ enchantment types fully defined** in `data/special.txt` with proper Third Age naming, depth ranges, rarity weights, item slot restrictions, and flag effects. These enchantments are adapted from SilQ with 9 entirely new Necromancer-specific types added.

**The problem is not missing data — it's missing code.** The enchantment system exists in data files but the Godot codebase never parses `special.txt` and the ego application functions are placeholders that only add cosmetic name prefixes.

### What This Document Proposes

1. **Use the existing 60+ enchantments from special.txt** with targeted modifications
2. **Add 16 new enchantments** across shields (5), boots (3), gloves (3), weapons (1), armor (2), cloaks (1), plus 1 weapon rework
3. **Replace "of Dragon-bane"** (SLAY_RAUKO/DRAGON — zero valid targets in game) with **"of Wraith-bane"** (SLAY_UNDEAD + SEE_INVIS)
4. **Add LIGHT to "of Gondolin" and "of Doriath"** — lore-accurate glowing elven blades
5. **Implement boss loot tables** — guaranteed drops one tier above floor median
6. **Create a "drought zone" in Wraith Domain** (floors 13-15) for pacing tension
7. **Adjust 2 ring/amulet depths** in object.txt for better timing
8. **Specify semantic UI descriptions** for every enchantment flag (no raw numbers)

### The Scarcity → Abundance Curve (Expert-Reviewed)

| Tier | Floors | Mundane | Minor | Major | Artifact | Boss Drop |
|------|--------|---------|-------|-------|----------|-----------|
| Outer Pits | 1-3 | 90% | 8% | 2% | 0% | Guaranteed minor enchant |
| Orc Warrens | 4-6 | 85% | 10% | 5% | 0% | Guaranteed major enchant |
| Dark Halls | 7-9 | 78% | 12% | 8% | 2% | Guaranteed major or artifact |
| Necropolis | 10-12 | 70% | 12% | 12% | 6% | Guaranteed artifact |
| Wraith Domain | 13-15 | 62% | 8% | 20% | 10% | Guaranteed artifact |
| Inner Sanctum | 16-18 | 50% | 10% | 25% | 15% | Guaranteed artifact + bonus |
| Throne Room | 19-20 | 35% | 5% | 40% | 20% | Morgul-lord hoard table |

**Key design decisions:**
- **90% mundane on floors 1-3** — enchanted items are RARE early on. Each find is a story. At ~10 items found per tier, ~1 enchant per tier keeps each one special.
- **30% ego rate at depth 10** — conservative curve that makes enchanted items feel meaningful throughout the midgame. Every enchanted find changes your build calculus.
- **Artifacts capped at 20%** even in the endgame — preserves artifact impact. Each artifact should be a story, not inventory noise.
- **Boss drops on separate table** — bosses every 3 floors guarantee progression. Floor 3 boss = minor enchant, Floor 6 = major, Floor 9+ = major/artifact. **Boss drops NEVER roll cursed enchantments.**
- **Wraith Domain drought** (minor drops to 8%) — the wraith floors feel empty and terrifying, making the Inner Sanctum payoff feel earned.
- **Major enchants are the endgame workhorse** (40% in Throne Room) — not artifacts. Good synergistic enchanted gear should be how you win.
- **Ability grants do NOT stack** — if equipment grants an ability the player already has, the grant is wasted. This is intentional RNG friction that rewards diverse builds.

---

## Phase 2, Loop 1: Complete Draft Roster

All enchantments below exist in `data/special.txt` unless marked **[NEW]** or **[MODIFIED]**. Organized by equipment slot. Full stat blocks are in Report 1.

**Note:** The skill formerly known as "Perception" is called **Hunting** in the Necromancer.

### 1.1 Armor Enchantments (Body Armor)

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 1 | of Protection | Shields, Greaves, Soft/Hard Armor | 0 | +1 protection side, IGNORE_ALL | Universal defense upgrade |
| 2 | of Venom's End | Soft/Hard Armor | 0 | RES_POIS | **Tier 1 survival** — counters spider poison |
| 3 | of Resilience | Galvorn/Mithril only | 10 | +1 CON, IGNORE_ALL | Endgame tanking |
| 4 | of the Woodmen | Leather/Gloves/Boots | 6 | FREE_ACT, IGNORE_ALL | **Critical** — first FREE_ACT ego |
| 5 | of Stealth | Soft Armor | 0 | +3 Stealth | Stealth build enabler |
| 6 | of Nogrod | Shields/Greaves/Mail | 0 | SUST_ALL, IGNORE_ALL | **Critical** — sustain insurance |
| 7 | of the Iron Hills | Iron Greaves/Iron Mail | 0 | STAND_FAST, RES_FEAR | Anti-knockback, fear immune |
| 8 | of Dale | Iron Gauntlets/Iron Greaves | 8 | RES_COLD, IGNORE_ALL | Cold resistance |
| 9 | of Blight | Soft/Hard Armor | 0 | VUL_POIS | **Cursed** — poison vulnerability |
| 10 | of the Ranger | Leather/Cloaks/Boots | 4 | +2 Stealth, +2 Hunting | Dunedain scout gear |
| 11 | of Gondor | Mail/Shields | 6 | WILL, RES_FEAR, IGNORE_ALL | Gondorian military |
| **NEW** | of the Flame-guard | Mail/Galvorn | 10 | RES_FIRE, IGNORE_ALL | **[NEW]** Fire-resistant armor |
| **NEW** | of Endurance | Mail | 12 | REGEN, SUST_CON | **[NEW]** Deep sustain armor |

### 1.2 Shield Enchantments

| ID | Name | Item Types | Depth | Flags/Effect | Gameplay Role |
|----|------|-----------|-------|-------------|---------------|
| 12 | of Deflection | All Shields | 0 | +2 evasion, IGNORE_ALL | Universal evasion boost |
| 13 | of Frost | All Shields | 10 | RES_FIRE, IGNORE_ALL | Fire protection |
| 14 | with Many Runes | Mithril Shield only | 20 | CHEAT_DEATH | **Legendary** — second life |
| 15 | of Wrath | Non-mithril Shields | 0 (max 10) | AGGRAVATE | **Cursed** — alerts enemies |
| **NEW** | of the Vanguard | All Shields | 4 | Grants **Charge** | **[NEW]** Offensive shield — rush into combat |
| **NEW** | of the Citadel | Tower Shields/Mithril | 8 | STAND_FAST, RES_FEAR, +1 WILL | **[NEW]** Minas Tirith — hold the line |
| **NEW** | of the Sentinel | Tower Shields | 10 | Grants **Zone of Control**, +1 prot die | **[NEW]** Nothing gets past you |
| **NEW** | of the Dunedain | Bucklers/Mithril | 6 | SEE_INVIS, +2 HUNTING | **[NEW]** Ranger watchfulness |
| **NEW** | of Warding | All Shields | 8 | RES_CONFU, RES_STUN, FREE_ACT | **[NEW]** Anti-sorcery ward |

Shields now offer: offensive ability (Charge), control ability (Zone of Control), defensive utility (Warding, Citadel), perception (Dunedain), plus the existing evasion/resistance options. Every shield enchantment tells a story.

### 1.3 Weapon Enchantments — Swords

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 20 | of Rivendell | Daggers only | 0 | +3 pval: LIGHT, SUST_GRA, SUST_DEX, LORE | Elven dagger — defensive/utility |
| 21 | of Gondolin | Swords/Spears/Glaives/Arrows/Mithril | 0 (max 10) | SLAY_ORC, SLAY_TROLL, **LIGHT** | **[MODIFIED]** Glows blue near orcs — lore-accurate |
| 22 | of Doriath | Axes/Swords/Spears/Glaives/Arrows/Mithril | 2 | SLAY_SPIDER, SLAY_WOLF, **LIGHT** | **[MODIFIED]** Elven blades glow faintly |
| 23 | **of Wraith-bane** | Swords/Spears/Glaives/Mithril | 9 | **SLAY_UNDEAD, SEE_INVIS** | **[REPLACED]** Was "of Dragon-bane" (SLAY_RAUKO/DRAGON — zero valid targets). Now the deep-game anti-wraith jackpot |
| 24 | of Final Rest | Warhammers/Axes/Swords (not daggers/curved) | 7 | SLAY_UNDEAD, FREE_ACT | **Critical** — anti-undead + paralysis |
| 25 | of Westernesse | Swords only | 6 | SLAY_UNDEAD, LIGHT | Dunedain anti-undead |
| 31 | of the Noldor | Swords only | 12 | +1 GRA, +1 DEX, DANGER | High-elven — power with risk |
| 34 | of Murder | Daggers/Curved Swords | 0 (max 4) | +3 Stealth, grants Assassination | Stealth kill build-enabler |
| 35 | of Accompaniment | Daggers only | 0 (max 4) | Grants Two Weapon Fighting | Dual-wield enabler |
| 42 | of Morgul | Daggers/Swords/Spears | 10 | BRAND_COLD, DARKNESS, LIGHT_CURSE | Cursed enemy weapons |
| 43 | of Shadow | Curved/Great Swords, Great Axes | 12 | VAMPIRIC, DARKNESS, HUNGER | Dark power with cost |
| 45 | of Mordor | Curved/Great Swords, Axes | 0 | +1ds, SLAY_MAN_OR_ELF, AGGRAVATE | Enemy orc weapons |
| 46 | (Poisoned) | Daggers/Hand Axes | 0 | BRAND_POIS | Poison damage |
| 47 | (Balanced) | Most weapons | 14 | ACCURATE | Precision strikes |
| 48 | (Defender) | Non-curved Swords/Glaives | 0 | +1 evasion, IGNORE_ALL | Defensive weapon |
| 49 | (Vampiric) | Glaives/Great Axes/Curved/Bastard Swords | 4 | VAMPIRIC, HUNGER, LIGHT_CURSE | Life steal with risk |

**Key changes:**
- **of Gondolin + of Doriath now include LIGHT.** Glamdring and Orcrist glow blue — this is Tolkien canon.
- **of Dragon-bane replaced with of Wraith-bane.** There are zero RAUKO or DRAGON monsters in the game. "of Wraith-bane" (SLAY_UNDEAD + SEE_INVIS) targets the actual endgame threat and combines two critical needs into one weapon enchantment.

### 1.4 Weapon Enchantments — Polearms, Axes, Blunt

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 26 | of the Firebeards | Warhammers/Axes/Mattocks | 4 | REGEN, RES_FIRE, IGNORE_ALL | Dwarven resilience |
| 27 | of the Edain | Heavy weapons (hammers/axes/long swords/glaives) | 8 | +1 damage side, grants Follow-Through | Combat ability unlock |
| 28 | of Fury | Heavy weapons | 10 | +1 damage side, grants Whirlwind, AGGRAVATE, CURSED | AOE damage with risk |
| 29 | of Mirkwood | Bows/Spears | 4 | +2 Stealth, SLAY_SPIDER | Wood-elf hunter |
| 30 | of Lothlórien | Bows/Swords | 8 | +2 GRA, +2 Hunting, LIGHT | Elven grace |
| 32 | of the Mark | Spears/Swords | 6 | +1 attack, RES_FEAR, FREE_ACT | Rohirrim cavalry |
| 33 | of Erebor | Axes/Hammers | 8 | +1 damage side, +1 STR, RES_FIRE, IGNORE_ALL | Dwarven forge-craft |
| 36 | of the Eorlingas | Spears only | 10 | +1 attack, +1 damage side, +1 STR, RES_FEAR | Rohirrim master spear |
| 37 | of Lothlórien | Quarterstaves only | 0 | +1 attack, REGEN | Staff of healing |
| 38 | of the North | Quarterstaves only | 2 | +1 CON, RES_COLD | Dunedain ranger staff |
| 39 | of Battering | Warhammers only | 0 | Grants Knock Back | Control ability |
| 40 | of Crushing | Warhammers only | 10 | +1 damage side, +1 STR | Raw power |
| 41 | of Piercing | Polearms only | 4 | +1 damage side, grants Impale | Polearm specialization |
| 44 | of the Deeps | Warhammers/Curved/Great Swords/Axes | 2 | +1 damage side, +1 CON, CUMBERSOME | Heavy but powerful |
| **NEW** | of the Flame | Swords/Axes | 10 | BRAND_FIRE | **[NEW]** Fire damage — lost when "of Udun" became "of Shadow" |

### 1.5 Helm Enchantments

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 71 | of Brilliance | All Helms | 0 | LIGHT | Counters darkness |
| 72 | of Defiance | All Helms | 0 | +3 Will, RES_FEAR | Anti-magic defense |
| 73 | of True Sight | All Helms + Light Sources | 0 | RES_BLIND, SEE_INVIS, RES_HALLU | **Critical** — see invisible |
| 74 | of Clarity | All Helms | 0 | RES_CONFU, RES_STUN, RES_HALLU | Status immunity bundle |
| 75 | of Grace | Mithril Helm/Lesser Jewel | 0 | +1 GRA | Grace stat boost |
| 76 | of the Dwarrowdelf | Iron-Mithril Helms | 8 | +1 CON, WILL, IGNORE_ALL | Dwarven stubbornness |
| 80 | of Terror | Non-mithril Helms | 0 | FEAR | **Cursed** — permanent fear |

### 1.6 Cloak Enchantments

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 82 | of Stealth | All Cloaks | 0 | +3 Stealth | Core stealth item |
| 83 | of Warmth | All Cloaks | 4 | RES_COLD | Cold protection |
| 84 | of the Traveller | All Cloaks | 0 | SLOW_DIGEST | Anti-hunger |
| 86 | of Winter's Chill | All Cloaks | 0 | VUL_COLD | **Cursed** — cold vulnerability |
| 87 | of the Tower | Cloaks only | 0 | RES_BLEED, SUST_CON, IGNORE_ALL | Gondorian military cloak |
| 88 | of the Golden Wood | Cloaks only | 0 | RES_FEAR, SUST_GRA, IGNORE_ALL | Lothlórien protection |
| **NEW** | of the Unseen | Cloaks | 10 | SEE_INVIS, +2 Stealth | **[NEW]** Wraith-hunter cloak |

### 1.7 Boot Enchantments

| ID | Name | Item Types | Depth | Flags/Effect | Gameplay Role |
|----|------|-----------|-------|-------------|---------------|
| 110 | of Ithil's Light | Mithril Greaves only | 0 | RADIANCE | Area light |
| 111 | of Softest Tread | Boots only | 0 | +3 Stealth | Stealth boots |
| 112 | of Snares Eluded | Mithril Greaves only | 10 | AVOID_TRAPS, FREE_ACT | Anti-paralysis + trap immunity |
| 113 | of Speed | Boots only | 10 | Grants **Sprinting** | Movement ability |
| 114 | of Leaping | Boots only | 7 | Grants **Leaping** | Tactical movement |
| 116 | of Treacherous Paths | Boots/Greaves | 5 (max 18) | DANGER | **Cursed** — alerts enemies |
| **NEW** | of the Shadow-stalker | Boots only | 8 | Grants **Fade** (kill unwary -> invisible 2 turns) | **[NEW]** Dunedain vanish-after-kill |
| **NEW** | of the Scout | Boots only | 4 | Grants **Listen**, +1 Stealth | **[NEW]** Woodland scout — detect through walls |
| **NEW** | of Pursuit | Boots/Mithril Greaves | 10 | Grants **Flanking** (+attack from side/behind) | **[NEW]** Hunter's boots — always finding the angle |

Boots now serve melee/stealth builds: Fade boots are build-defining for stealth assassins, Scout boots enable early detection, and Pursuit boots reward tactical positioning.

### 1.8 Glove Enchantments

| ID | Name | Item Types | Depth | Flags/Effect | Gameplay Role |
|----|------|-----------|-------|-------------|---------------|
| 120 | of Archery | Gloves only | 2 | +3 Archery | Ranged build enabler |
| 121 | of Healing | All Gloves | 0 | MEDIC | Better herb/potion healing |
| 122 | of Swordplay | All Gloves | 4 | Grants **Parry** | Defensive combat ability |
| 123 | of the Iron Hills | Gauntlets only | 4 | +1 CON, NEG_DEX | Tank tradeoff |
| 124 | of Might | Mithril Gauntlets only | 10 | +1 STR, IGNORE_ALL | Raw strength |
| 126 | of Treachery | All Gloves | 4 (max 13) | +1 STR, grants **Opportunist**, CURSED | **Cursed** — power with betrayal |
| **NEW** | of the Silent Hand | Gloves only | 6 | Grants **Assassination**, +1 Stealth | **[NEW]** Silent kill gloves — +stealth to attack vs unwary |
| **NEW** | of Cunning | Gloves only | 4 | Grants **Opening Strike** | **[NEW]** First-blow advantage (bonus die vs each new foe) |
| **NEW** | of the Burglar | Gloves only | 8 | Grants **Pilfer**, +2 Stealth | **[NEW]** Nimble fingers — 25% extra drops |

Gloves now serve stealth/melee builds: Silent Hand gloves grant the Assassination ability without XP investment (freeing XP for other skills), Cunning gloves reward aggressive openers, and Burglar gloves create a loot-farming stealth playstyle.

### 1.9 Bow & Arrow Enchantments

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 91 | of Black Yew | Longbows only | 6 | +1 damage side, +1 protection side, VUL_FIRE | Power with fire vulnerability |
| 92 | of the Wild | Shortbows only | 4 | RES_POIS, DANGER, AGGRAVATE | Dangerous wilderness bow |
| 93 | of Radiance | All Bows | 6 | RADIANCE | Area light on ranged |
| 94 | of the Marchwardens | All Bows | 6 | SEE_INVIS, RES_FEAR | Lothlórien archer bow |
| 95 | of the Grey Havens | All Bows | 12 | +3 Hunting, RES_COLD | Elven precision |
| 96 | of the Galadhrim | All Bows | 12 | ACCURATE | Perfect accuracy |
| 101 | (Poisoned) | Arrows | 6 | BRAND_POIS | Poison arrows |
| 102 | of Piercing | Arrows | 10 | SHARPNESS | Armor-piercing arrows |

### 1.10 Digging Tool & Light Source Enchantments

| ID | Name | Item Types | Depth | Flags | Gameplay Role |
|----|------|-----------|-------|-------|---------------|
| 51 | of Belegost | Mattocks only | 0 | +1 Tunnel | Better digging |
| 52 | of the Longbeards | Mattocks only | 0 (max 4) | +STR | Dwarven strength |
| 130 | of Brightness | Lanterns/Jewels/Lamps | 0 | LIGHT | Brighter light |
| 73 | of True Sight | (shared with helms) | 0 | SEE_INVIS, RES_BLIND, RES_HALLU | See invisible |
| 75 | of Grace | Lesser Jewel only | 0 | +1 GRA | Grace on light source |
| 135 | of Flickering Shadow | Lanterns only | 0 (max 11) | DARKNESS, CURSED | **Cursed** — dims your light |

### 1.11 Rings (from object.txt)

| Ring | Current Depth | Proposed Depth | Effect | Change Reason |
|------|--------------|---------------|--------|---------------|
| of Endurance | 2 | 2 | +CON | No change |
| of Iron Will | 3 | 3 | RES_FEAR | No change |
| of the Watchful | 3 | 3 | +Hunting | No change |
| of the Forester | 4 | 4 | +Stealth | No change |
| of Venom's End | 6 | 6 | RES_POIS | No change |
| of Durin's Folk | 7 | 7 | +STR, RES_FIRE | No change |
| of Protection | 7 | 7 | +1d2 protection | No change |
| of Ered Luin | 8 | 8 | +Will, RES_FEAR, RES_CONFU | No change |
| of Evasion | 8 | 8 | +2 evasion | No change |
| of the Greenwood | 8 | 8 | +GRA, RES_POIS | No change |
| of Strength | 9 | 9 | +STR, SUST_STR | No change |
| of Dexterity | 10 | 10 | +DEX, SUST_DEX | No change |
| **of Free Action** | **12** | **8** | **FREE_ACT** | **MOVED** — ghouls at depth 7 |
| of the Shadow-ward | 12 | 12 | SEE_INVIS, RES_FEAR | No change |
| of Noldor Memory | 13 | 13 | +GRA, +Will | No change |

### 1.12 Amulets (from object.txt)

| Amulet | Current Depth | Proposed Depth | Effect | Change Reason |
|--------|--------------|---------------|--------|---------------|
| of the Hearth | 3 | 3 | SLOW_DIGEST | No change |
| of Clear Sight | 4 | 4 | +Hunting | No change |
| of Fortitude | 5 | 5 | +Will | No change |
| of Constitution | 8 | 8 | +CON, SUST_CON | No change |
| of the Stoneheart | 8 | 8 | SUST_STR, SUST_CON | No change |
| **of Starlight** | **9** | **7** | **LIGHT, RES_DARK** | **MOVED** — darkness spells at depth 6 |
| of Haunted Dreams | 9 | 9 | HAUNTED, SEE_INVIS | No change (cursed) |
| of Grace | 10 | 10 | +GRA, SUST_GRA | No change |
| of Regeneration | 12 | 12 | REGEN | No change |
| of Preservation | 14 | 14 | SUST_CON, SUST_GRA, SLOW_DIGEST | No change |
| of Lorien-light | 15 | 15 | +GRA, REGEN, LIGHT | No change |
| of the Blessed Realm | 16 | 16 | +GRA, SUST_GRA, LIGHT | No change |

---

## Phase 2, Loop 2: Balance & Gap Validation

Cross-referencing the complete roster against Report 3's threat analysis by dungeon tier.

### Monster Race Audit

Before validating, confirm which SLAY_ flags have valid targets:

| Slay Flag | Monster Race | Count | Depth Range | Verdict |
|-----------|-------------|-------|-------------|---------|
| SLAY_ORC | ORC | 8+ | 2-12 | **Valid** — dominant layers 2-3 |
| SLAY_TROLL | TROLL | 5+ | 6-18 | **Valid** — recurring throughout |
| SLAY_SPIDER | SPIDER | 5 | 1-3 | **Valid** — layer 1 dominant |
| SLAY_WOLF | WOLF | 4 | 3-6 | **Valid** — warg threats |
| SLAY_UNDEAD | UNDEAD | 15+ | 7-20 | **Valid** — dominant from layer 3 onward |
| SLAY_MAN_OR_ELF | MAN | 12+ | 6-20 | **Valid** — human enemies throughout |
| SLAY_RAUKO | (none) | 0 | — | **REMOVED** — zero valid targets |
| SLAY_DRAGON | (none) | 0 | — | **REMOVED** — zero valid targets |

### Invisible Monster Audit (SEE_INVIS Importance)

**7 invisible monsters** spanning floors 10-19:

| Monster | Depth | Type | Special Abilities |
|---------|-------|------|-------------------|
| Corpse-candle | 10 | UNDEAD | CONFUSE, FLYING |
| Phantom | 12 | UNDEAD | TERRIFY |
| Shadow | 13 | UNDEAD | LOSE_STR, PASS_DOOR |
| Fell Spirit | 14 | UNDEAD | LOSE_GRA, PASS_WALL |
| Wailing Horror (unique) | 15 | UNDEAD | TERRIFY, HALLU |
| Shadow Lord | 17 | UNDEAD | LOSE_STR, DARK_AURA, PASS_WALL |
| Greater Shadow | 19 | UNDEAD | LOSE_ALL, PASS_WALL |

**SEE_INVIS is mandatory from floor 10 onward.** Without it, players literally cannot fight half the enemies. Current SEE_INVIS sources after this update: helm ego (depth 0), bow ego (depth 6), shield ego (depth 6), cloak ego (depth 10), weapon ego "of Wraith-bane" (depth 9), ring (depth 12), cursed amulet (depth 9) — **7 sources** across 6 slots. Well-covered.

### Tier-by-Tier Validation

**Tier 1 (Floors 1-3) — Poison + Spiders:** FULLY COVERED. RES_POIS armor at depth 0, SLAY_SPIDER/WOLF weapons at depth 2, stealth options at depth 0.

**Tier 2 (Floors 4-6) — Organized Groups:** FULLY COVERED. SLAY_ORC/TROLL at depth 0, RES_FEAR at depth 0, stealth bypass at depth 4, ranged at depth 4. New shield "of the Vanguard" (Charge) at depth 4 helps melee close gaps.

**Tier 3 (Floors 7-9) — Magic + Status:** CRITICAL GAP FIXED. FREE_ACT now available from depth 6 across 5+ sources. New shield "of Warding" (RES_CONFU + RES_STUN + FREE_ACT) at depth 8 is a one-stop anti-sorcery solution.

**Tier 4 (Floors 10-12) — Undead + Stat Drain:** FULLY COVERED. SUST_ALL via "of Nogrod" (depth 0), SEE_INVIS via 5+ sources, SLAY_UNDEAD via 3 weapon egos. New "of Wraith-bane" (SLAY_UNDEAD + SEE_INVIS at depth 9) is the premium anti-undead option.

**Tier 5 (Floors 13-15) — Wraith Domain:** COVERED + DROUGHT. Loot drops to 62%/8%/20%/10% — minor enchants at just 8% create scarcity tension. Players rely on loadout assembled in tiers 3-4. New "of the Unseen" cloak provides SEE_INVIS.

**Tier 6 (Floors 16-18) — Inner Sanctum:** COVERED. RES_FIRE from 5+ sources, BRAND_FIRE via new "of the Flame" (depth 10), REGEN via "of Endurance" (depth 12). New shield "of the Sentinel" (Zone of Control) at depth 10 helps control corridors.

**Tier 7 (Floors 19-20) — Throne Room:** BY DESIGN. SPEED remains artifact-only. Major enchants at 40% are the workhorse. Artifacts at 20% still feel special.

### Gap Summary After Revision

| Gap | Status | Solution |
|-----|--------|----------|
| FREE_ACT at depth 7 | **FIXED** | 5+ ego sources at depth 6-8 + ring at depth 8 + shield of Warding at depth 8 |
| SLAY_UNDEAD artifact-only | **FIXED** | "of Final Rest" (depth 7), "of Westernesse" (depth 6), "of Wraith-bane" (depth 9) |
| SEE_INVIS scarcity | **FIXED** | 7 sources across 6 slots (helm, bow, shield, cloak, weapon, ring) |
| SLAY_RAUKO/DRAGON useless | **REMOVED** | Replaced with "of Wraith-bane" (SLAY_UNDEAD + SEE_INVIS) |
| No BRAND_FIRE ego | **FIXED** | New "of the Flame" ego (depth 10) |
| No RES_FIRE on body armor | **FIXED** | New "of the Flame-guard" ego (depth 10) |
| No REGEN on body armor | **FIXED** | New "of Endurance" ego (depth 12) |
| Shields boring | **FIXED** | 5 new shield egos with abilities, SEE_INVIS, anti-magic |
| Boots/gloves lack stealth | **FIXED** | 6 new egos granting Fade, Listen, Flanking, Assassination, Opening Strike, Pilfer |
| Darkness counter thin | **IMPROVED** | Amulet of Starlight moved to depth 7 + LIGHT on Gondolin/Doriath weapons |
| No boss loot tables | **FIXED** | Guaranteed boss drops on separate progression table |

---

## Phase 2, Loop 3: Final Polish

### 3.1 Lore Consistency Review

Every enchantment name maps to Third Age Middle-earth lore:

| Name | Lore Source | Justification |
|------|-----------|---------------|
| of Gondolin | Ancient Elven city — blades like Glamdring/Orcrist survived | Glows blue near orcs (Tolkien canon) |
| of Doriath | Thingol's kingdom, marchwardens fought spiders | Historical elven heirlooms that glow |
| of the Woodmen | Mirkwood settlers who resisted spiders/corruption | Practical survival gear, FREE_ACT |
| of the Ranger | Dunedain Rangers of the North | Scout and tracking equipment |
| of Gondor | Soldiers of the White Tower | Military-grade armor |
| of Westernesse | Numenorean blades, effective against undead | Ancient anti-undead weapons |
| of the Mark | Rohirrim cavalry weapons | Courage and free action (riding) |
| of Erebor | Dwarven forge-craft from the Lonely Mountain | Fire-resistant metalwork |
| of Mirkwood | Wood-elf hunting weapons | Anti-spider stealth gear |
| of Lothlórien | Galadhrim elven craft | Grace, hunting, light |
| of Morgul | Nazgul/witch-king weapons | Cursed cold-brand blades |
| of the Noldor | High Elven craft (Rivendell remnants) | Power with inherent danger |
| of the Dwarrowdelf | Moria/Khazad-dum dwarven helms | Stubborn endurance |
| of Wraith-bane | Weapons specifically forged against wraiths | The deep-game anti-invisible weapon |
| of the Vanguard | Gondorian vanguard leading the charge | Shield that enables Charge ability |
| of the Citadel | Minas Tirith, the White City | Hold-the-line shield (STAND_FAST) |
| of the Sentinel | Border guards and watchtowers | Zone of Control shield |
| of the Dunedain | Rangers who watch the borders | Shield with SEE_INVIS |
| of Warding | Protective wards against dark sorcery | Anti-sorcery (RES_CONFU/STUN + FREE_ACT) |
| of the Shadow-stalker | Dunedain who vanish into shadow after a strike | Boots granting Fade |
| of the Scout | Woodland scouts who feel the forest | Boots granting Listen |
| of Pursuit | Hunters who always find the flank | Boots granting Flanking |
| of the Silent Hand | Those who strike unseen and unheard | Gloves granting Assassination |
| of Cunning | Those who strike first and strike true | Gloves granting Opening Strike |
| of the Burglar | Hobbit-style nimble fingers | Gloves granting Pilfer |
| of the Flame | Dwarven forge-fire | Fire damage on weapons |
| of the Flame-guard | Fire-resistant dwarven armor | Body armor with RES_FIRE |
| of Endurance | Rangers and soldiers of Gondor | Regeneration + sustain |
| of the Unseen | Wraith-hunter cloaks | SEE_INVIS for cloak slot |

### 3.2 UX: Semantic Item Descriptions

All flag effects display as natural language. No raw numbers.

#### Stat Bonuses

| Flag | pval 1 | pval 2 | pval 3+ |
|------|--------|--------|---------|
| STR | "Slightly increases strength" | "Increases strength" | "Greatly increases strength" |
| DEX | "Slightly increases dexterity" | "Increases dexterity" | "Greatly increases dexterity" |
| CON | "Slightly increases constitution" | "Increases constitution" | "Greatly increases constitution" |
| GRA | "Slightly increases grace" | "Increases grace" | "Greatly increases grace" |

#### Skill Bonuses

| Flag | pval 1-2 | pval 3+ |
|------|----------|---------|
| STEALTH | "Muffles your footsteps" | "Greatly muffles your footsteps" |
| HUNTING | "Sharpens your awareness" | "Greatly sharpens your awareness" |
| WILL | "Strengthens your resolve" | "Greatly strengthens your resolve" |
| ARCHERY | "Steadies your aim" | "Greatly steadies your aim" |
| LORE | "Deepens your knowledge" | "Greatly deepens your knowledge" |
| TUNNEL | "Improves your digging" | "Greatly improves your digging" |

#### Combat Flags

| Flag | Description |
|------|-------------|
| SLAY_ORC | "Deadly against orcs" |
| SLAY_TROLL | "Deadly against trolls" |
| SLAY_SPIDER | "Deadly against spiders" |
| SLAY_WOLF | "Deadly against wolves" |
| SLAY_UNDEAD | "Deadly against the undead" |
| SLAY_MAN_OR_ELF | "Deadly against the Free Peoples" |
| BRAND_FIRE | "Burns with inner fire" |
| BRAND_COLD | "Gleams with bitter cold" |
| BRAND_POIS | "Drips with venom" |
| SHARPNESS | "Cuts through armor" |
| VAMPIRIC | "Drains life from your foes" |
| ACCURATE | "Strikes with unerring precision" |
| STAND_FAST | "Holds your ground against blows" |

#### Defensive Flags

| Flag | Description |
|------|-------------|
| RES_FIRE | "Protects against fire" |
| RES_COLD | "Protects against cold" |
| RES_POIS | "Protects against poison" |
| RES_FEAR | "Steels your courage" |
| RES_BLIND | "Protects your sight" |
| RES_CONFU | "Protects your mind" |
| RES_STUN | "Protects against stunning" |
| RES_HALLU | "Protects against illusions" |
| RES_BLEED | "Stanches wounds" |
| FREE_ACT | "Protects against paralysis" |
| SEE_INVIS | "Reveals hidden foes" |
| SUST_STR | "Sustains your strength" |
| SUST_DEX | "Sustains your dexterity" |
| SUST_CON | "Sustains your constitution" |
| SUST_GRA | "Sustains your grace" |

#### Utility Flags

| Flag | Description |
|------|-------------|
| LIGHT | "Glows with soft light" |
| RADIANCE | "Illuminates the area around you" |
| REGEN | "Hastens your recovery" |
| SLOW_DIGEST | "Staves off hunger" |
| MEDIC | "Improves healing" |
| SPEED | "Quickens your stride" |
| CHEAT_DEATH | "May save you from a fatal blow" |
| AVOID_TRAPS | "Warns you of hidden traps" |

#### Negative Flags

| Flag | Description |
|------|-------------|
| DANGER | "Puts you in greater peril" |
| AGGRAVATE | "Disturbs nearby creatures" |
| HUNGER | "Gnaws at your vitality" |
| DARKNESS | "Dims the light around you" |
| HAUNTED | "Haunted by dark visions" |
| FEAR | "Fills you with dread" |
| VUL_FIRE | "Leaves you vulnerable to fire" |
| VUL_COLD | "Leaves you vulnerable to cold" |
| VUL_POIS | "Leaves you vulnerable to poison" |
| LIGHT_CURSE | "Cursed — cannot be removed easily" |
| CUMBERSOME | "Slows your movements in combat" |
| NEG_STR | "Saps your strength" |
| NEG_DEX | "Dulls your reflexes" |
| NEG_CON | "Weakens your constitution" |
| NEG_GRA | "Diminishes your grace" |

#### Ability Grants

| Ability | Description |
|---------|-------------|
| Follow-Through | "Grants Follow-Through: continued strikes after a kill" |
| Whirlwind Attack | "Grants Whirlwind: strikes all adjacent foes" |
| Assassination | "Grants Assassination: deadly strikes against unwary foes" |
| Two Weapon Fighting | "Grants Dual Wielding: fight with two weapons" |
| Knock Back | "Grants Knock Back: drive enemies away" |
| Impale | "Grants Impale: pierce through foes" |
| Parry | "Grants Parry: deflect incoming blows" |
| Sprinting | "Grants Sprinting: burst of speed" |
| Leaping | "Grants Leaping: jump over obstacles" |
| Opportunist | "Grants Opportunist: strike fleeing foes" |
| Charge | "Grants Charge: rush into combat from distance" |
| Zone of Control | "Grants Zone of Control: block enemy movement" |
| Fade | "Grants Fade: vanish after killing an unwary foe" |
| Listen | "Grants Listen: detect creatures through walls" |
| Flanking | "Grants Flanking: bonus when attacking from the side" |
| Opening Strike | "Grants Opening Strike: bonus on first attack against each foe" |
| Pilfer | "Grants Pilfer: chance of extra drops from kills" |

#### Example Tooltips

```
  Longsword of Gondolin
  ─────────────────────
  An ancient blade forged in the hidden
  city, before it fell to treachery.

  Deadly against orcs.
  Deadly against trolls.
  Glows with soft light.

  Attack: well-balanced
  Damage: moderate (2d5)
```

```
  Tower Shield of the Sentinel
  ────────────────────────────
  A shield borne by the watchers of
  Osgiliath, who held the river crossing.

  Grants Zone of Control: block enemy movement.
  Better protection.

  Evasion: neutral
  Protection: solid (1d7)
```

```
  Leather Gloves of the Silent Hand
  ──────────────────────────────────
  Gloves worn by those who strike unseen
  and unheard, leaving no trace behind.

  Grants Assassination: deadly strikes
  against unwary foes.
  Slightly muffles your footsteps.
```

### 3.3 Addiction Loop Design

The enchantment system creates engagement through these psychological hooks:

#### 1. Progressive Revelation (Floors 1-6)
- First enchanted item found: moment of surprise ("what does this do?")
- Learning enchantment names: "of Gondolin" means anti-orc — player starts pattern-matching
- Ego chance starts low so each find feels special
- Identification mechanic: unidentified enchantments create anticipation
- **Boss drops guarantee progression**: Floor 3 boss always drops a minor enchant

#### 2. Problem-Solution Matching (Floors 7-12)
- Player encounters ghouls -> gets paralyzed -> dies
- Next run: finds "Leathers of the Woodmen" (FREE_ACT) -> survives ghoul floor
- This creates a "I need X to survive Y" loop that makes specific enchantments feel essential
- The TIMING is critical: threats appear 1-2 floors before solutions become common
- **Build-defining finds**: "Gloves of the Silent Hand" unlocks stealth kills without XP investment

#### 3. Build Optimization (Floors 10-15)
- Player has enough enchanted items to start making choices: which to equip?
- Slot competition: "Do I wear Shadow-stalker boots (Fade) or Speed boots (Sprinting)?"
- Cursed items create risk-reward tension: "This Vampiric sword heals me but causes HUNGER..."
- Smithing materials (Broken Glowing/Strange) create anticipation: "What will this forge into?"
- **Wraith Domain drought** (minor enchants drop to 8%): scarcity makes every find precious

#### 4. Loadout Completion (Floors 15-20)
- Player is hunting specific enchantments to complete their build
- Every slot matters: "I have RES_FIRE on my shield but need it on armor for Maia Thralls"
- Artifact finds create peak excitement moments
- The "raid Sauron's armory" fantasy is fully realized
- **Major enchants are the workhorse** (40% in Throne Room) — artifacts are the cherry on top

#### 5. The Cursed Item Gamble
Risk-reward items create memorable moments:
- **of Morgul** (BRAND_COLD + DARKNESS + CURSED) — powerful but corrupting
- **of Shadow** (VAMPIRIC + DARKNESS + HUNGER) — sustain vs. cost
- **of Fury** (Whirlwind + AGGRAVATE + CURSED) — AOE power vs. stealth death
- **of the Noldor** (GRA + DEX + DANGER) — stats vs. increased monster alertness
- Players who use cursed items feel clever; players who avoid them feel prudent. Both are valid.

#### 6. The Smithing Investment Loop
- Find Broken Glowing materials -> anticipation: "what can I make?"
- Find forge -> plan: "what do I need most?" (limited uses force prioritization)
- Reforge -> random enchanted item -> surprise: "YES, Westernesse blade!"
- Reforge Mastery -> reject/reroll -> strategic: "I need FREE_ACT, not this"
- Reclaim -> artifact -> peak moment: "I made Glamdring!"
- This creates a separate loot system that rewards exploration and planning

### 3.4 Cursed Item Risk-Reward Matrix

| Enchantment | Benefit | Cost | Risk Level | Best For |
|-------------|---------|------|-----------|----------|
| of Fury | Whirlwind Attack, +1ds | AGGRAVATE, CURSED | **HIGH** | Pure melee tanks |
| (Vampiric) | Life steal | HUNGER, CURSED | **MEDIUM** | Sustain fighters |
| of Shadow | Vampiric, high damage | DARKNESS, HUNGER | **HIGH** | Desperate deep runs |
| of Morgul | BRAND_COLD | DARKNESS, CURSED | **MEDIUM** | Anti-undead builds |
| of the Noldor | +GRA, +DEX | DANGER | **LOW** | Skill-focused builds |
| of Mordor | +1ds, SLAY_MAN | AGGRAVATE | **HIGH** | Evil-themed builds |
| of Treachery (gloves) | +1 STR, Opportunist | CURSED | **MEDIUM** | Stealth builds (ironic) |
| Helm of Terror | (cheap) | FEAR | **EXTREME** | Never equip intentionally |
| of Winter's Chill | (cheap) | VUL_COLD | **MEDIUM** | Viable early |
| of Wrath (shield) | (cheap) | AGGRAVATE | **HIGH** | Never equip intentionally |
| of the Wild (bow) | RES_POIS | DANGER, AGGRAVATE | **HIGH** | Poison floors only |

---

## Implementation Architecture (Overview Only — Not Implementing)

### What Must Be Built

1. **Parse special.txt in data_manager.gd**
   - New `EgoData` class: name, flags, creation_bonuses, depth, rarity, max_depth, cost, tval_filters, granted_abilities
   - Load on game start alongside items, monsters, artifacts

2. **Replace placeholder ego application**
   - `monster.gd:_apply_ego_enchantment()` -> select random ego from loaded data, filtered by item tval/sval and depth
   - `dungeon_generator.gd:_apply_floor_ego()` -> same system
   - Apply ALL ego flags to ItemData (not just cosmetic name)

3. **Wire combat system to equipment flags**
   - `entity.gd:attack_entity()` -> check for SLAY_* flags, add bonus damage die per matching slay
   - `entity.gd:attack_entity()` -> check for BRAND_* flags, add bonus damage die of element
   - `player.gd:take_damage()` -> check RES_* flags, halve matching elemental damage
   - `player.gd:take_damage()` -> check SUST_* flags, block stat drain

4. **Fine vs. Special system**
   - Independent rolls: Fine (stat bump) and Special (ego enchantment)
   - Fine chance: `depth * 2` percent
   - Special chance: `depth` percent
   - Monster DROP_GOOD: guaranteed fine OR special
   - Monster DROP_GREAT: guaranteed fine AND special

5. **Boss loot table system**
   - Separate loot table per boss tier, not rolled on floor table
   - Floor 3 boss: guaranteed 1 minor enchant
   - Floor 6 boss: guaranteed 1 major enchant
   - Floor 9+ boss: guaranteed 1 major enchant or artifact
   - Floor 12+ boss: guaranteed 1 artifact
   - **Boss drops NEVER roll cursed enchantments** (no AGGRAVATE, FEAR, DARKNESS, CURSED, VUL_*)
   - Boss loot table overrides existing boss drop logic

6. **Smithing integration**
   - Reforge -> select random ego appropriate for output type and forge tier
   - Reclaim -> select random artifact appropriate for output type
   - All existing smithing tests must continue passing

7. **Tooltip system update**
   - `tooltip_manager.gd:format_item_tooltip()` -> use semantic descriptions table
   - Show enchantment name prominently
   - Hide raw numbers behind semantic descriptions
   - Show cursed items with warning text

### Changes to Data Files

#### special.txt Additions

| ID | Name | Definition | Rationale |
|----|------|-----------|-----------|
| 16 | of the Flame-guard | T:37:0:99 / T:36:11:11, F:RES_FIRE / IGNORE_ALL, W:10:6 | RES_FIRE on body armor |
| 17 | of Endurance | T:37:0:99, F:REGEN / SUST_CON, W:12:8 | REGEN + sustain on armor |
| 50 | of the Flame | T:23:10:30 / T:22:11:13, F:BRAND_FIRE, W:10:6 | Restore BRAND_FIRE ego |
| 55 | of Warding | T:34:0:99, F:RES_CONFU / RES_STUN / FREE_ACT, W:8:4 | Anti-sorcery shield |
| 56 | of the Vanguard | T:34:0:99, B:0/3 (Charge), W:4:4 | Offensive shield ability |
| 57 | of the Citadel | T:34:3:10, F:STAND_FAST / RES_FEAR / WILL (pval 1), W:8:6 | Defensive shield |
| 58 | of the Sentinel | T:34:3:6, B:Zone_of_Control, +1pd, W:10:6 | Control shield |
| 59 | of the Dunedain | T:34:0:10, F:SEE_INVIS / HUNTING (pval 2), W:6:4 | Ranger shield |
| 85 | of the Unseen | T:35:0:99, F:SEE_INVIS / STEALTH (pval 2), W:10:6 | SEE_INVIS cloak |
| 115 | of the Shadow-stalker | T:30:1:1, B:Fade, W:8:6 | Stealth kill boots |
| 117 | of the Scout | T:30:1:1, B:Listen / STEALTH (pval 1), W:4:4 | Detection boots |
| 118 | of Pursuit | T:30:1:3, B:Flanking, W:10:4 | Tactical boots |
| 125 | of the Silent Hand | T:31:1:1, B:Assassination / STEALTH (pval 1), W:6:4 | Stealth kill gloves |
| 127 | of Cunning | T:31:1:1, B:Opening_Strike, W:4:4 | First-strike gloves |
| 128 | of the Burglar | T:31:1:1, B:Pilfer / STEALTH (pval 2), W:8:6 | Loot gloves |

#### special.txt Modifications

| ID | Change | Old | New |
|----|--------|-----|-----|
| 21 | of Gondolin | SLAY_ORC, SLAY_TROLL | SLAY_ORC, SLAY_TROLL, **LIGHT** |
| 22 | of Doriath | SLAY_SPIDER, SLAY_WOLF | SLAY_SPIDER, SLAY_WOLF, **LIGHT** |
| 23 | of Dragon-bane -> **of Wraith-bane** | SLAY_RAUKO, SLAY_DRAGON | **SLAY_UNDEAD, SEE_INVIS** |

#### object.txt Depth Changes

| Item | Old Depth | New Depth | Rationale |
|------|-----------|-----------|-----------|
| Ring of Free Action | 12 | 8 | Ghouls use ENTRANCE at depth 7 |
| Amulet of Starlight | 9 | 7 | Darkness spells start at depth 6 |

---

## Approval Checklist

**All items approved by Christopher (2026-02-08):**

- [x] **Revised loot curve** (90/85/78/70/62/50/35 mundane + boss loot tables + conservative 30% ego at depth 10)
- [x] **Wraith Domain drought** (minor enchants drop to 8% on floors 13-15)
- [x] **Artifacts capped at 20%** even in Throne Room (major enchants at 40% instead)
- [x] **5 new shield enchantments** (Vanguard/Citadel/Sentinel/Dunedain/Warding)
- [x] **3 new boot enchantments** (Shadow-stalker/Scout/Pursuit — stealth abilities)
- [x] **3 new glove enchantments** (Silent Hand/Cunning/Burglar — stealth abilities)
- [x] **of Gondolin + of Doriath add LIGHT** (lore-accurate glowing elven blades)
- [x] **of Dragon-bane -> of Wraith-bane** (SLAY_UNDEAD + SEE_INVIS replaces useless slays)
- [x] **of the Flame** (new BRAND_FIRE ego on swords/axes)
- [x] **of the Flame-guard + of Endurance** (RES_FIRE armor, REGEN armor)
- [x] **of the Unseen** (SEE_INVIS cloak)
- [x] **Ring of Free Action depth 12 -> 8**
- [x] **Amulet of Starlight depth 9 -> 7**
- [x] **Semantic descriptions** (natural language for all flags)
- [x] **SPEED remains artifact-only**
- [x] **Implementation architecture** (7-component approach including boss loot)
- [x] **Boss drops exclude cursed enchantments** (committee blocker #2)
- [x] **Ability grants do NOT stack** — wasted if player already has the ability (committee blocker #3)
- [x] **Naming: "of the Cutpurse" → "of the Burglar"** (Tolkien tonal consistency)
- [x] **Naming: "of the Assassin" → "of the Silent Hand"** (Tolkien tonal consistency)
- [ ] **Smithing depth-gating** — DEFERRED to separate work (committee blocker #1)

**APPROVED — Ready for implementation planning.**

---

*Document v3 generated 2026-02-09 from synthesis of Reports 1, 2, 3 + expert committee review*
*Refinement Loops: 3 (Draft -> Balance Validation -> Final Polish) + Committee Review*
*Reviewed by: Roguelike Expert (7.5/10), Necromancer-Dev Expert (8/10), Tolkien Scholar (8.5/10)*
*Committee Verdict: APPROVE WITH MODIFICATIONS (8.2/10)*
