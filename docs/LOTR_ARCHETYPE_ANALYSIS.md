# LOTR Archetype Analysis - The Necromancer

**Document Version:** 2.0
**Produced by:** Necromancer Design Committee (Coordinator + 3 Expert Agents)
**Revised by:** Deep research pass with ability mapping, XP modeling, win rate calibration
**Date:** 2026-02-06
**Game:** The Necromancer (Sil-Q fork, Godot 4.6)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Hero Build Specifications](#2-hero-build-specifications)
3. [Ability Progression Paths](#3-ability-progression-paths)
4. [Hobbit Race Design](#4-hobbit-race-design)
5. [Viability Analysis](#5-viability-analysis)
6. [Fantasy Scorecards](#6-fantasy-scorecards)
7. [Gap Analysis & Priority Roadmap](#7-gap-analysis--priority-roadmap)
8. [Bold Design Proposals](#8-bold-design-proposals)
9. [Tier List](#9-tier-list)
10. [Implementation Priority](#10-implementation-priority)
11. [Data Reference Appendix](#11-data-reference-appendix)

---

## 1. Executive Summary

### The Vision
Map 13 iconic LOTR heroes to playable builds in The Necromancer, ensuring each feels mechanically distinct, thematically resonant, and fun to play across all 7 dungeon layers.

### Key Findings
- **Protection math favors tanks**: Heavy armor + Blocking + shields can reduce most early/mid damage to 0. Boromir's tank fantasy is the best-realized archetype in the current build.
- **Undead immunity negates Lore casters**: NO_FEAR + NO_SLEEP + NO_CONF on all undead means Lore-based heroes (Galadriel, Glorfindel) are helpless in Layers 4-5 (~40% of the dungeon). This is a critical design gap.
- **Unimplemented status effects = hidden difficulty reduction**: If HOLD/SLOW/SCARE/DARKNESS/stat drain all worked, every non-Will build would die in Layer 3+. The game is currently easier than designed.
- **Consumable system not yet wired**: Herbs, potions, and food items exist in data files but aren't functional. This is an implementation gap, not a design gap -- the Sil-Q design assumes between-fight healing via consumables (Herbcraft doubles their effect). Implementing consumables is P0 for balance.
- **5 of 13 heroes are COMPLETELY BROKEN**: Legolas + Faramir (no archery system), Frodo + Sam + Bilbo (no Hobbit race). Nearly 40% of the roster cannot function.
- **Faramir is an Aragorn clone**: Identical race (Man), house (Dunedain), and stat line (+1/+1/+1/+1). Needs identity intervention.
- **The Hobbit race is essential**: Adding a 4th playable race with 3 houses unlocks 3 heroes and creates the most Tolkien-resonant gameplay in the entire game.
- **Layer 5-6 evasion spike is impassable**: The jump from wraith EVN+14 to Khamul EVN+26 to Sauron EVN+30 outpaces any achievable player attack bonus. ALL melee builds wall here.
- **All heroes have identical speed**: Every player character has speed 2 (100 energy/tick). DEX does NOT affect speed -- it only contributes to evasion. This means no hero is inherently faster or slower than another, and speed-3 monsters (Wargs, Nazgul, Sauron) always have a 25% action advantage.
- **XP budget is tight but workable**: Starting XP of 5,000 plus ~10,450 descent XP across 20 floors gives ~15,450 total. A focused combat build needs ~9,000 XP; the Banishment path (Lore 12 + Will 10) costs ~12,100 with affinity. Both are achievable but demand discipline.

### The 13 Heroes

| # | Hero | Race | House | Primary Fantasy |
|---|------|------|-------|-----------------|
| 1 | Aragorn | Man | Dunedain | Ranger-King, balanced warrior |
| 2 | Boromir | Man | Gondor | Shield-warrior, noble sacrifice |
| 3 | Legolas | Elf | Greenwood | Elven archer, mobile striker |
| 4 | Gimli | Dwarf | Iron Hills | Axe-berserker, dwarven resilience |
| 5 | Frodo | Hobbit | Shire | Ring-bearer, will-tank |
| 6 | Sam | Hobbit | Gamgee | Loyal companion, crafter-survivor |
| 7 | Bilbo | Hobbit | Took | Burglar, stealth-assassin |
| 8 | Theoden | Man | Rohan | Horse-lord, charge-and-hold |
| 9 | Eowyn | Man | Rohan | Shieldmaiden, defiant giant-slayer |
| 10 | Faramir | Man | Gondor | Scholar-warrior, ambush commander |
| 11 | Galadriel | Elf | Lothlorien | Lore-master, banishment specialist |
| 12 | Celebrimbor | Elf | Rivendell | Master smith, artifact forger |
| 13 | Glorfindel | Elf | Lothlorien | Ancient warrior-sage, wraith-bane |

---

## 2. Hero Build Specifications

### 2.1 Aragorn - Ranger of the North
- **Race:** Man (+1/0/+1/0) | **House:** Dunedain (PER_AFFINITY, +0/+1/+0/+1)
- **Final Stats:** STR+1 / DEX+1 / CON+1 / GRA+1 (Total: +4)
- **Proficiency:** Sword
- **Primary Skills:** Perception, Melee, Evasion
- **Secondary Skills:** Will, Stealth
- **Signature Abilities:** Focused Attack, Concentration, Bane, Master Hunter
- **Victory Path:** Escape (the King returns)
- **Fantasy Summary:** The balanced hero. Good at everything, master of nothing. His Perception affinity means he detects traps, notices ambushes, and tracks enemies. A true ranger who can fight, sneak, and endure.

### 2.2 Boromir - Captain of Gondor
- **Race:** Man (+1/0/+1/0) | **House:** Gondor (MEL_AFFINITY, +0/+0/+1/+0)
- **Final Stats:** STR+1 / DEX+0 / CON+2 / GRA+0 (Total: +3)
- **Proficiency:** Sword
- **Primary Skills:** Melee, Evasion
- **Secondary Skills:** Will (critical for survival)
- **Signature Abilities:** Power, Knock Back, Zone of Control, Defensive Stance
- **Victory Path:** Escape (fighting retreat, the warrior's ending)
- **Fantasy Summary:** The pure melee tank. Highest CON of any Man build. Dominates early layers through sheer combat power. Walls at Layer 4-5 when Will saves become critical - thematically correct (Boromir fell to the Ring's corruption).

### 2.3 Legolas - Prince of Greenwood
- **Race:** Elf (-1/+2/+1/+2) | **House:** Greenwood (STL_AFFINITY, +0/+1/+0/+0)
- **Final Stats:** STR-1 / DEX+3 / CON+1 / GRA+2 (Total: +5)
- **Proficiency:** Bow
- **Primary Skills:** Archery, Stealth, Evasion
- **Secondary Skills:** Perception
- **Signature Abilities:** [REQUIRES ARCHERY SYSTEM] Keen Eyes, Ambush, Deadly Hail
- **Victory Path:** Escape (swift and deadly retreat)
- **Fantasy Summary:** The mobile stealth-archer. Highest DEX in the game. Should be the ranged damage dealer who picks off enemies before they close. CURRENTLY BROKEN - no archery system exists.
- **BLOCKER:** Archery skill tree completely unimplemented.

### 2.4 Gimli - Lord of Glittering Caves
- **Race:** Dwarf (+1/-1/+3/0) | **House:** Iron Hills (MEL_AFFINITY, +1/+0/+0/+0)
- **Final Stats:** STR+2 / DEX-1 / CON+3 / GRA+0 (Total: +4)
- **Proficiency:** Axe (BUGGED - tval mismatch)
- **Primary Skills:** Melee, Smithing
- **Secondary Skills:** Will (needs Dwarven Resilience)
- **Signature Abilities:** Power, Mighty Blow, Cleave, Weaponsmith, Armoursmith
- **Victory Path:** Escape (the miner's path out)
- **Fantasy Summary:** The unkillable melee machine. Highest CON in the entire game (+3). Hits hard, takes hits, forges better gear. Walls at Layer 5 due to low GRA/Will unless DWARVEN_RESILIENCE racial is added.
- **BLOCKER:** Axe proficiency tval bug (player.gd:807 maps tval 20 instead of 22).
- **PROPOSED FIX:** DWARVEN_RESILIENCE racial flag: +3 to Will saves vs fear/corruption.

### 2.5 Frodo - Ring-bearer
- **Race:** Hobbit (-2/+2/+0/+2) | **House:** Shire (WIL_AFFINITY, +0/+0/+1/+0)
- **Final Stats:** STR-2 / DEX+2 / CON+1 / GRA+2 (Total: +3)
- **Proficiency:** Sling
- **Primary Skills:** Will, Perception, Lore
- **Secondary Skills:** Stealth, Evasion
- **Power Curve:** FLAT/DECLINE (inverse) -- challenges grow faster than power. Stealth+Will start strong but enemy Perception escalates.
- **Signature Abilities:** Defy Death, Indomitable, Strength in Adversity, Majesty
- **Victory Path:** Banishment (the Ring-bearer's true quest is to defeat evil through wisdom, not combat)
- **Fantasy Summary:** The ultimate Will-tank. Weakest in melee, strongest in mental resistance. Survives through sheer determination. HOBBIT_LUCK saves him from certain death once per floor. His journey through the Wraith Domain should feel like Mordor. The most narratively compelling build in the game, but brutally hard -- requires near-perfect stealth play.
- **Death Pattern:** EXPOSURE (stealth cascade) -- one failed check spirals into total detection. The most TENSE death in the game.
- **Retention Hook:** "I almost had it" -- "I made it to depth 16 without killing anyone."
- **BLOCKER:** Hobbit race does not exist.

### 2.6 Sam - The Brave
- **Race:** Hobbit (-2/+2/+0/+2) | **House:** Gamgee (SMT_AFFINITY, +1/+0/+0/+0)
- **Final Stats:** STR-1 / DEX+2 / CON+0 / GRA+2 (Total: +3)
- **Proficiency:** Sling
- **Primary Skills:** Smithing, Will, Perception
- **Secondary Skills:** Melee (benefits from STR-1 instead of -2)
- **Power Curve:** S-CURVE -- weak early, spikes when Herbcraft + Inner Light come online with herb drops.
- **Signature Abilities:** Weaponsmith, Armoursmith, Herbcraft, Strength in Adversity
- **Victory Path:** Escape (Sam carries Frodo out - the loyal companion's path)
- **Fantasy Summary:** The crafter-survivor. Sam's house gives STR+1, partially offsetting the Hobbit STR-2. With Smithing affinity, he forges gear that makes up for his small stature. Herbcraft represents his gardening knowledge. Inner Light combat against HURT_LITE enemies (Layers 4-5) is his peak. Most dependent on item drops (herbs, light sources).
- **Death Pattern:** RESOURCE EXHAUSTION -- "I ran out of herbs three floors from the surface." Needs guaranteed herb drop pity timer.
- **Retention Hook:** "I found something cool" -- "I found 3 Athelas herbs and with Herbcraft they were incredible."
- **BLOCKER:** Hobbit race does not exist.

### 2.7 Bilbo - The Burglar
- **Race:** Hobbit (-2/+2/+0/+2) | **House:** Took (STL_AFFINITY, +0/+1/+0/+0)
- **Final Stats:** STR-2 / DEX+3 / CON+0 / GRA+2 (Total: +3)
- **Proficiency:** Sling
- **Primary Skills:** Stealth, Evasion, Perception
- **Secondary Skills:** Lore
- **Signature Abilities:** Assassination, Disguise, Vanish, Fade, Escape Artist
- **Victory Path:** Escape (the burglar slips away unseen)
- **Fantasy Summary:** The pure stealth build. Highest DEX among Hobbits. Sneaks past enemies, assassinates from shadows, escapes when caught. HOBBIT_LUCK + SMALL_STATURE make him extremely slippery. The "Bilbo vs Smaug" fantasy of the small creature outwitting the great.
- **BLOCKER:** Hobbit race does not exist. Stealth abilities mostly unimplemented.

### 2.8 Theoden - King of the Mark
- **Race:** Man (+1/0/+1/0) | **House:** Rohan (EVN_AFFINITY, +1/+0/+0/+0)
- **Final Stats:** STR+2 / DEX+0 / CON+1 / GRA+0 (Total: +3)
- **Proficiency:** Sword
- **Primary Skills:** Melee, Evasion
- **Secondary Skills:** Will
- **Signature Abilities:** Charge, Follow-Through, Crowd Fighting, Zone of Control, [PROPOSED: Rally]
- **Victory Path:** Escape (the king leads the charge out)
- **Key Differentiation from Eowyn:** Theoden is the **movement warrior**. His build prioritizes Evasion depth (Crowd Fighting at EVN 5, Sprinting at EVN 7) over Will investment. He fights by charging in, cleaving with Follow-Through, and Sprinting away when outnumbered. His EVN affinity lets him reach Crowd Fighting (1,000 XP with affinity) cheaply, enabling him to fight while surrounded -- a king who holds the line. Rally (1/floor break fear/confusion) represents shaking off Saruman's influence. His weakness is small rooms where movement is impossible.
- **Fantasy Summary:** The mounted warrior-king (no mount system, but Charge captures the feel). High STR for devastating melee, EVN affinity for battlefield mobility. Where Eowyn stands her ground against one terrifying foe, Theoden charges into many. His Pelennor moment: Charging down a corridor of orcs with Follow-Through, killing 3 in a single turn.

### 2.9 Eowyn - Shieldmaiden of Rohan
- **Race:** Man (+1/0/+1/0) | **House:** Rohan (EVN_AFFINITY, +1/+0/+0/+0)
- **Final Stats:** STR+2 / DEX+0 / CON+1 / GRA+0 (Total: +3)
- **Proficiency:** Sword
- **Primary Skills:** Evasion, Will, Melee
- **Secondary Skills:** Stealth (Disguise -- she disguised herself as Dernhelm)
- **Signature Abilities:** Dodging, Strength in Adversity, Defy Death, Formidable, [UNIQUE: No Living Man]
- **Victory Path:** Escape (fight your way out)
- **Key Differentiation from Theoden:** Eowyn is the **defiant duelist**. Where Theoden invests deep in Evasion for mobility, Eowyn splits EVN/Will early -- by purchase 10 she has Will 4 (Formidable) while Theoden has Melee 5 (Charge). This makes her weaker against groups but dramatically stronger against bosses and undead. Strength in Adversity (+1/+3 stats when HP < 50%) means she fights hardest when wounded. Defy Death means she survives one lethal hit per floor. Combined with No Living Man (+3 att/dmg vs NO_FEAR enemies), her Wraith Domain performance is superior to Theoden's. Her Pelennor moment: at 3 HP, Strength in Adversity active, killing a Wraith Lord that terrified Theoden into fleeing.
- **UNIQUE MECHANIC - No Living Man:** +3 attack and +3 damage against enemies with the NO_FEAR flag. Enemies with NO_FEAR that Eowyn kills grant double XP. This specifically targets bosses and elite undead. "No living man am I" -- she is the bane of things that cannot be afraid.

### 2.10 Faramir - Captain of Ithilien
- **Race:** Man (+1/0/+1/0) | **House:** Gondor (MEL_AFFINITY, +0/+0/+1/+0)
- **Final Stats:** STR+1 / DEX+0 / CON+2 / GRA+0 (Total: +3)
- **Proficiency:** Sword
- **Primary Skills:** Melee, Archery (when implemented), Lore
- **Secondary Skills:** Perception, Stealth
- **Power Curve:** S-CURVE -- weak before ambush abilities come online, spikes once Ithilien Trap + Crippling Shot active, plateaus late.
- **Signature Abilities:** Lore of Battle, Deep Memory, Lore of Silence, [NEW: Ithilien Trap]
- **UNIQUE MECHANIC - Ithilien Trap:** Spend 3 turns stationary to "prepare" position. While prepared: first attack gets +Perception/2 to attack AND damage; enemies entering LOS are auto-Crippled (slowed) for 1 turn. Effect breaks on movement. Creates unique decision loop: "Is this position worth 3 turns of setup?" No other build asks this question. The Into the Breach philosophy -- fights are won before the first arrow flies.
- **Victory Path:** Banishment (Faramir would not take the Ring - he seeks to understand and defeat evil through knowledge)
- **Fantasy Summary:** MOVED from Dunedain to Gondor to differentiate from Aragorn. The ambush commander: sets up perfect kill zones with patience and preparation. Combined with Lore of Silence (quiets the area for ambush setup) and archery, Faramir becomes the "information warfare" specialist while Legolas is the "damage chain" archer.
- **Death Pattern:** RESOURCE EXHAUSTION -- "My ambush position was flanked and I ran out of arrows for the second wave."
- **Retention Hook:** "I want to try a different approach" -- "I set up my ambush in the wrong corridor. Better scouting next time."
- **DESIGN NOTE:** Previously identical to Aragorn (both Man/Dunedain). Moving to Gondor + Ithilien Trap creates completely distinct identity.

### 2.11 Galadriel - Lady of Light
- **Race:** Elf (-1/+2/+1/+2) | **House:** Lothlorien (LOR_AFFINITY, +0/+0/+0/+1)
- **Final Stats:** STR-1 / DEX+2 / CON+1 / GRA+3 (Total: +5)
- **Proficiency:** Bow
- **Primary Skills:** Lore, Will, Perception
- **Secondary Skills:** Smithing
- **Signature Abilities:** Word of Command, Inner Light, Lore of Sleep, Word of Mastery, Majesty
- **Victory Path:** Banishment (Galadriel's power opposes the Shadow directly)
- **Fantasy Summary:** The ultimate Lore/Will build. Highest GRA in the game (+3). Dominates Layers 4-7 where Will saves matter. Weak early (STR-1) but becomes godlike. Inner Light counters DARKNESS spam. Majesty makes enemies flee. The Banishment victory path is practically designed for her.

### 2.12 Celebrimbor - Lord of Eregion
- **Race:** Elf (-1/+2/+1/+2) | **House:** Rivendell (SMT_AFFINITY, +0/+0/+1/+0)
- **Final Stats:** STR-1 / DEX+2 / CON+2 / GRA+2 (Total: +5)
- **Proficiency:** Bow
- **Primary Skills:** Smithing, Lore
- **Secondary Skills:** Will, Perception
- **Signature Abilities:** Weaponsmith, Armoursmith, Jeweller, Reforge, Expertise, Reclaim, Masterwork
- **Victory Path:** Both viable (crafter can gear up for either)
- **Fantasy Summary:** The master smith. His SMT affinity makes the entire Smithing tree dramatically cheaper -- he reaches Weaponsmith (free), Armoursmith (100 XP), Jeweller (200 XP), and Reforge (600 XP) for a total of just 1,000 XP. By the time other heroes are choosing their first ability, Celebrimbor is already forging gear at any available forge. Higher CON than other Elves (+2) for durability while working.
- **The Forge-Dependency Problem:** Celebrimbor's power is a step function tied to forge availability. With forges: he crafts weapons, armor, and rings that elevate him to A-tier. Without forges: he's an Elf with no combat investment and wasted skill points. This creates the most variable run experience of any hero. **Mitigation**: guarantee at least one forge per 3-floor span in dungeon generation.
- **Endgame Fantasy:** Reclaim (Smithing 7) creates artifacts from broken items. Masterwork (Smithing 8) creates legendary artifacts. Master Smith (Smithing 20) is the ultimate stretch goal at 19,000 XP with affinity -- achievable only in extremely long, XP-rich runs. This is Celebrimbor's "forge the Rings of Power" moment.
- **Device Mastery** (Lore 11) synergizes with Jeweller: Celebrimbor understands magical items at a fundamental level. Combined with Lore, he can identify, enhance, and wield items that other heroes can only use at face value.

### 2.13 Glorfindel - Lord of the House of the Golden Flower
- **Race:** Elf (-1/+2/+1/+2) | **House:** Lothlorien (LOR_AFFINITY, +0/+0/+0/+1)
- **Final Stats:** STR-1 / DEX+2 / CON+1 / GRA+3 (Total: +5)
- **Proficiency:** Bow
- **Primary Skills:** Melee, Will, Lore
- **Secondary Skills:** Evasion
- **Signature Abilities:** Power, Finesse, Opening Strike, Inner Light, Indomitable, Deadly Lore, Strength in Adversity
- **Victory Path:** Escape (the ancient warrior fights his way out)
- **Fantasy Summary:** Same stats as Galadriel but fundamentally different playstyle. Glorfindel is the warrior-sage who fights AND casts -- the only hero who genuinely needs both Melee and Lore. Where Galadriel avoids combat entirely, Glorfindel wades in with blade and light.
- **The Hybrid Problem:** Splitting XP across Melee, Will, AND Lore creates mediocrity risk. At purchase 10, he has Melee 4 / Lore 3 / Will 3 -- master of nothing. This is why Light Warrior is essential to make him work.
- **[PROPOSED: Light Warrior]** (unique passive): Melee attacks against HURT_LITE enemies deal bonus damage equal to Lore/3. Inner Light radius increases by Melee/4. This rewards investing in BOTH skills simultaneously instead of penalizing split investment. Thematically: Glorfindel fights with the light of the Two Trees -- his blade IS his light.
- **Three-Way Fork at Purchase 10+:** Deeper Melee for Opening Strike (7) gives raw combat power. Deeper Will for Defy Death (5) gives desperate survival. Deeper Lore for Deadly Lore (6) gives execute-on-crit kills. Glorfindel can viably go all three paths -- the right choice depends on what the dungeon throws at him. This decision flexibility IS his identity.
- **Wraith Domain Specialist:** His combination of Inner Light (burns HURT_LITE undead), Will investment (resists their fear), and melee (fights them directly) makes him the best non-Eowyn hero for Layer 5. He killed a Balrog -- he fears nothing in Dol Guldur.

---

## 3. Ability Progression Paths

This section maps the optimal first 10 skill/ability purchases for each hero, showing exact XP costs with affinity discounts. Based on the actual skill cost formula: the Nth point costs `100 * N` XP (first point = 100 XP; affinity reduces each point by 100, making the first point free).

### 3.1 Aragorn -- Man / Dunedain (PER affinity)

| # | Purchase | Cost | Cumulative | XP Remaining | Key Unlock |
|---|----------|------|------------|--------------|------------|
| 1 | Perception 0->1 | 0 (A) | 0 | 5,000 | Natural Talent |
| 2 | Perception 1->2 | 100 (A) | 100 | 4,900 | Focused Attack |
| 3 | Melee 0->1 | 100 | 200 | 4,800 | Power |
| 4 | Melee 1->2 | 200 | 400 | 4,600 | Finesse |
| 5 | Perception 2->3 | 200 (A) | 600 | 4,400 | Keen Senses |
| 6 | Evasion 0->1 | 100 | 700 | 4,300 | -- |
| 7 | Evasion 1->2 | 200 | 900 | 4,100 | Dodging |
| 8 | Melee 2->3 | 300 | 1,200 | 3,800 | Knock Back |
| 9 | Perception 3->4 | 300 (A) | 1,500 | 3,500 | Concentration |
| 10 | Melee 3->4 | 400 | 1,900 | 3,100 | Polearm Mastery |

**Rationale:** Leads with cheap Perception (free level 1 from affinity), picking up Natural Talent and Focused Attack early. Melee brings core fighting, Evasion 2 gives Dodging for Ranger mobility. The balanced three-skill spread IS Aragorn's identity.

### 3.2 Boromir -- Man / Gondor (MEL affinity)

| # | Purchase | Cost | Cumulative | XP Remaining | Key Unlock |
|---|----------|------|------------|--------------|------------|
| 1 | Melee 0->1 | 0 (A) | 0 | 5,000 | Power |
| 2 | Melee 1->2 | 100 (A) | 100 | 4,900 | Finesse |
| 3 | Melee 2->3 | 200 (A) | 300 | 4,700 | Knock Back |
| 4 | Evasion 0->1 | 100 | 400 | 4,600 | -- |
| 5 | Evasion 1->2 | 200 | 600 | 4,400 | Dodging |
| 6 | Melee 3->4 | 300 (A) | 900 | 4,100 | Polearm Mastery |
| 7 | Evasion 2->3 | 300 | 1,200 | 3,800 | Blocking |
| 8 | Melee 4->5 | 400 (A) | 1,600 | 3,400 | Charge |
| 9 | Melee 5->6 | 500 (A) | 2,100 | 2,900 | Follow-Through |
| 10 | Evasion 3->4 | 400 | 2,500 | 2,500 | Parry |

**Rationale:** Pure combat machine. Free Power, 100 XP Finesse -- MEL affinity makes his primary tree absurdly cheap. Rushes to Follow-Through and Charge while picking up Blocking (shield Gondorian) and Parry. By purchase 10, Boromir has spent only 2,500 XP and has the game's best melee kit.

### 3.3 Galadriel -- Elf / Lothlorien (LOR affinity)

| # | Purchase | Cost | Cumulative | XP Remaining | Key Unlock |
|---|----------|------|------------|--------------|------------|
| 1 | Lore 0->1 | 0 (A) | 0 | 5,000 | Word of Command, Lore of Battle |
| 2 | Lore 1->2 | 100 (A) | 100 | 4,900 | Deep Memory, Word of Opening |
| 3 | Will 0->1 | 100 | 200 | 4,800 | Curse Breaking |
| 4 | Will 1->2 | 200 | 400 | 4,600 | Force of Will |
| 5 | Lore 2->3 | 200 (A) | 600 | 4,400 | Lore of Silence, Herbcraft |
| 6 | Perception 0->1 | 100 | 700 | 4,300 | Natural Talent |
| 7 | Lore 3->4 | 300 (A) | 1,000 | 4,000 | Word of Shutting |
| 8 | Will 2->3 | 300 | 1,300 | 3,700 | Strength in Adversity |
| 9 | Lore 4->5 | 400 (A) | 1,700 | 3,300 | Inner Light |
| 10 | Perception 1->2 | 200 | 1,900 | 3,100 | Focused Attack |

**Rationale:** THE Lore character. Free Lore 1 unlocks two active abilities immediately. By purchase 9 she has Inner Light (spiritual radiance), Lore of Silence (stealth enabler), Herbcraft (healing mastery), and Word of Shutting (sealing doors). Galadriel aims for the Banishment path: Lore 12 + Will 10 = 12,100 XP with affinity. Achievable with ~15,450 total XP available.

### 3.4 Bilbo -- Hobbit / Took (STL affinity)

| # | Purchase | Cost | Cumulative | XP Remaining | Key Unlock |
|---|----------|------|------------|--------------|------------|
| 1 | Stealth 0->1 | 0 (A) | 0 | 5,000 | -- |
| 2 | Stealth 1->2 | 100 (A) | 100 | 4,900 | -- |
| 3 | Stealth 2->3 | 200 (A) | 300 | 4,700 | Disguise |
| 4 | Evasion 0->1 | 100 | 400 | 4,600 | -- |
| 5 | Evasion 1->2 | 200 | 600 | 4,400 | Dodging |
| 6 | Stealth 3->4 | 300 (A) | 900 | 4,100 | Assassination, Throat Slit |
| 7 | Perception 0->1 | 100 | 1,000 | 4,000 | Natural Talent |
| 8 | Evasion 2->3 | 300 | 1,300 | 3,700 | Blocking |
| 9 | Perception 1->2 | 200 | 1,500 | 3,500 | Focused Attack |
| 10 | Evasion 3->4 | 400 | 1,900 | 3,100 | Parry |

**Rationale:** Bilbo maxes Stealth cheaply. Disguise at 3 makes him hard to detect. Assassination + Throat Slit at 4 let him dispatch unaware enemies in a single devastating blow. Evasion gives Dodging (mobile hobbit) and Parry (Sting!). His endgame fork: Stealth 8 for Vanish or Stealth 9 for Fade (kill + vanish chain).

### 3.5 Remaining Heroes -- Summary Progression

Full first-10 tables for the remaining 9 heroes follow the same pattern. Key highlights:

| Hero | First 10 Cost | Primary Skill at 10 | Key Ability Unlocked | Decision Fork |
|------|---------------|---------------------|---------------------|---------------|
| **Legolas** (STL affinity) | 1,900 | Archery 4 / Stealth 4 | Assassination, Point Blank | Archery 5 (Puncture) vs Stealth 5 (Disorienting Strike) |
| **Gimli** (MEL affinity) | 2,500 | Melee 6 / Smithing 4 | Follow-Through, Jeweller | Melee 9 (Cleave) vs Smithing 5 (Reforge) |
| **Frodo** (WIL affinity) | 1,900 | Will 4 / Lore 3 / Per 3 | Formidable, Herbcraft, Keen Senses | Will 5 (Defy Death) vs Lore 5 (Inner Light) |
| **Sam** (SMT affinity) | 1,900 | Smithing 5 / Will 3 / Per 2 | Reforge, Str in Adversity | Smithing 7+ (Reclaim) vs Lore 3 (Herbcraft) |
| **Theoden** (EVN affinity) | 2,500 | Melee 5 / Evasion 5 | Charge, Crowd Fighting | Evasion 7 (Sprinting) vs Melee 6 (Follow-Through) |
| **Eowyn** (EVN affinity) | 1,900 | Evasion 3 / Will 4 / Melee 3 | Blocking, Formidable, Knock Back | Will 5 (Defy Death + Indomitable) vs Melee 5 (Charge) |
| **Faramir** (MEL affinity) | 1,600 | Melee 4 / Archery 3 / Per 2 | Polearm Mastery, Fletchery | Archery 5 (Puncture) vs Lore 3 (Herbcraft) |
| **Celebrimbor** (SMT affinity) | 2,700 | Smithing 7 / Lore 3 | Reclaim, Herbcraft | Smithing 8 (Masterwork) vs Lore 5+ (Inner Light) |
| **Glorfindel** (LOR affinity) | 1,900 | Melee 4 / Lore 3 / Will 3 | Polearm Mastery, Herbcraft, Str in Adversity | Melee 7 (Opening Strike) vs Will 5 (Defy Death) vs Lore 6 (Deadly Lore) |

### 3.6 XP Budget Summary

| Skill Level | Cumulative (Base) | Cumulative (Affinity) | Key Unlocks |
|-------------|-------------------|----------------------|-------------|
| 1 | 100 | 0 | First-tier passives |
| 2 | 300 | 100 | Dodging, Rout, Focused Attack |
| 3 | 600 | 300 | Blocking, Disguise, Keen Senses, Herbcraft |
| 4 | 1,000 | 600 | Assassination, Parry, Concentration, Jeweller |
| 5 | 1,500 | 1,000 | Charge, Crowd Fighting, Defy Death, Reforge |
| 6 | 2,100 | 1,500 | Follow-Through, Bane, Expertise, Deadly Lore |
| 7 | 2,800 | 2,100 | Opening Strike, Sprinting, Reclaim, Lore of Endurance |
| 8 | 3,600 | 2,800 | Subtlety, Crippling Shot, Masterwork, Lore of Sleep |
| 9 | 4,500 | 3,600 | Cleave, Heavy Armour Use, Deadly Hail, Majesty |
| 10 | 5,500 | 4,500 | Zone of Control, Riposte, Grace (stat), Word of Mastery |
| 12 | 7,800 | 6,600 | Device Mastery, Constitution, Grace (Lore) |
| 15 | 12,000 | 10,500 | Deep skill investment territory |
| 20 | 21,000 | 19,000 | Master Smith (Smithing 20) -- extreme endgame |

**Starting XP:** 5,000 | **Total Descent XP (20 floors):** 10,450 | **Kill/Encounter XP:** Variable (~3,000-5,000 typical)

**Maximum realistic total XP:** ~15,000-18,000 per run

With 5,000 starting XP, a hero can immediately reach skill level 9 in ONE affinity skill (4,500 XP) -- but nothing else. Most viable builds spread across 2-3 skills, reaching levels 5-8 in their primary and 3-5 in secondaries.

---

## 4. Hobbit Race Design

### 4.1 Race Statistics
```
N:4:Hobbit
S:-2:2:0:2
I:5:30:120
H:42:2
W:70:6
C:9|10|11
F:SMALL_STATURE | HOBBIT_LUCK | SLING_PROFICIENCY
E:39:0:3:3     # ~ Wooden Torches (3)
E:80:38:5:5    # , Seed Cakes (5)
E:23:4:1:1     # | Short Sword (1)
E:19:0:1:1     # ( Sling (1)
E:18:0:10:10   # } Stones (10)
D:Hobbits are a small, quiet folk who love peace, good food,
D: and comfortable homes. Yet when pressed, they show a
D: remarkable resilience. Their small stature makes them
D: difficult targets, and fortune seems to favor them in
D: the darkest moments.
```

**COMMITTEE CONSENSUS**: Stats revised from coordinator's initial STR-2/DEX+1/CON+1/GRA+2 to **STR-2/DEX+2/CON+0/GRA+2 (Total: +2)**. Roguelike-expert conceded DEX+2 citing the DCSS Felid problem (Total +1 would make Hobbits too punishing for non-expert players). DEX+2 powers Stealth, Evasion, and Sling archery -- all core Hobbit skills. CON+0 (not +1) because HOBBIT_LUCK provides the survival safety net instead of raw HP.

### 4.2 Racial Mechanics

**SMALL_STATURE** (merged from HALFLING_SIZE + stealth bonus proposals)
- +2 bonus to Stealth score (enemies overlook small folk)
- Large/Huge creatures (trolls, wargs, spiders, Sauron) get -2 to attack rolls against Hobbits
- -2 to melee attack with non-proficiency weapons (can't wield big weapons effectively)
- Thematic: small, easily overlooked, but can't fight toe-to-toe with big weapons
- Implementation: modify `stealth_score` calculation, add size check in `total_monster_attack()`, add proficiency check in `total_player_attack()`
- Net effect: Hobbits are HARDER TO DETECT and HARDER TO HIT but WORSE AT HITTING. Coherent identity.

**HOBBIT_LUCK**
- Once per dungeon floor, reroll a d20 that would result in lethal damage
- Triggers automatically on the first hit that would reduce HP to 0
- Resets when descending to a new floor
- The "Bilbo falls and finds the Ring" mechanic -- fortune favors Hobbits in their darkest moments
- Implementation: new `hobbit_luck_available` flag in player state, checked in `take_damage()` before HP reaches 0. Reroll the monster's attack d20.

**SLING_PROFICIENCY**
- +1 to archery when using sling-type weapons
- Requires: sling weapon type added to item system (tval for slings, ammo type for stones)
- Does NOT overlap with Elf BOW_PROFICIENCY or Dwarf AXE_PROFICIENCY
- Tolkien-canonical: Hobbits are famous stone-throwers

### 4.3 Hobbit Houses

```
N:9:Of the Shire
A:the Shire
B:Hobbit
F:WIL_AFFINITY
S:0:0:1:0
D:The Shire-hobbits are the most numerous of their kind,
D: dwelling in the peaceful lands between the Brandywine
D: and the Far Downs. They are stubborn, resistant to
D: corruption, and possess an inner strength that belies
D: their gentle nature.

N:10:Of the Gamgees
A:the Gamgees
B:Gamgee
F:SMT_AFFINITY
S:1:0:0:0
D:The Gamgees are a practical folk, known for their skill
D: with rope, gardening, and all manner of useful crafts.
D: What they lack in learning they make up in determination
D: and a surprising physical hardiness.

N:11:Of the Tooks
A:the Tooks
B:Took
F:STL_AFFINITY
S:0:1:0:0
D:The Tooks are the most adventurous of hobbit families,
D: rumored to have fairy blood. They are quick, cunning,
D: and possessed of an unhobbity desire to see what lies
D: beyond the next hill. Many have gone on adventures
D: and returned with remarkable tales.
```

---

## 5. Viability Analysis

### 5.1 Survival Gate Analysis

| Layer | Depth | Key Threats | Survival Requirement |
|-------|-------|-------------|---------------------|
| 1-2: Forest/Orcs | 1-6 | Spiders (poison), Orcs (melee), Wargs | Basic melee/evasion |
| 3: Torture Halls | 6-9 | Dark Sorcerer (POW 10), Mirk-trolls (KNOCK_BACK) | WILL checks begin |
| 4: Necropolis | 9-12 | Undead (RES_CRIT, HURT_LITE), Wights (drain CON/GRA) | LIGHT, high WILL |
| 5: Wraith Domain | 12-15 | Invisible spirits, Shadows (LOSE_STR), Fell Spirit (PASS_WALL) | SEE_INVISIBLE, Indomitable |
| 6: Inner Sanctum | 15-18 | Black Numenoreans (POW 16), Olog-hai (4d8 BATTER) | Everything |
| 7: Pits of Despair | 18-20 | Sauron (unkillable, 200d4 HP, +35/5d12 fire) | MUST FLEE |

### 5.2 Hero Viability Matrix (Combat Math Verified)

Ratings incorporate actual combat math (P(hit) calculations, protection rolls, HP thresholds) from code analysis.

| Hero | L1-2 | L3 | L4 | L5 | L6-7 | Pursuit | Wall | Power Curve | Fantasy Alive |
|------|------|-----|-----|-----|------|---------|------|-------------|---------------|
| Aragorn | 5 | 4 | 3 | 2 | 1 | 3 | L5 | Flat | 3/5 |
| Boromir | 5 | 5 | 4 | 3 | 1 | 3 | L6 | Early-peaker | 4/5 |
| Legolas | 1* | 1* | 1* | 1* | 1* | 1* | L1* | *BROKEN | 1/5 |
| Gimli | 5 | 5 | 3 | 2 | 1 | 2 | L5 | Early-peaker | 3/5 |
| Frodo | ?* | ?* | ?* | ?* | ?* | ?* | ?* | *BROKEN | 1/5 |
| Sam | ?* | ?* | ?* | ?* | ?* | ?* | ?* | *BROKEN | 1/5 |
| Bilbo | ?* | ?* | ?* | ?* | ?* | ?* | ?* | *BROKEN | 1/5 |
| Theoden | 5 | 4 | 3 | 2 | 1 | 2 | L4-5 | Early-peaker | 3/5 |
| Eowyn | 4 | 3 | 3 | 2 | 1 | 2 | L4 | Early-peaker | 2/5 |
| Faramir | 1* | 1* | 1* | 1* | 1* | 1* | L1* | *BROKEN | 1/5 |
| Galadriel | 3 | 4 | 1** | 1** | 2 | 1 | L4** | Bimodal | 3/5 |
| Celebrimbor | 2 | 2 | 1 | 1 | 1 | 1 | L1-2 | Forge-dependent | 2/5 |
| Glorfindel | 3 | 4 | 3 | 2 | 1 | 2 | L4-5 | Mid-peaker | 3/5 |

*BROKEN = system dependency missing (archery or Hobbit race)
**Galadriel's L4-5 rating reflects undead immunity to ALL Lore crowd control (NO_FEAR/NO_SLEEP/NO_CONF)

### 5.3 Critical Combat Math Insights

**Protection vs Damage**: Heavy armor + Blocking + shields can reduce most L1-3 damage to 0 net. Boromir with Tower Shield + Dwarven Hauberk rolls ~14 protection vs Orc Soldier's 2d6 (avg 7). Most early hits deal 0 damage. This makes tank builds feel invincible early.

**The Evasion Wall**: Player attack bonus maxes at ~+11. Wraith EVN is +14 (37% hit rate). Khamul EVN is +26 (12% hit rate). Sauron EVN is +30 (5% hit rate). No melee build can overcome this math without unimplemented abilities like Concentration stacking.

**Undead Immune to Everything**: All undead have NO_FEAR + NO_SLEEP + NO_CONF + RES_CRIT. Lore casters lose their entire toolkit. All crits are halved. This makes Layer 4-5 a design dead zone for non-melee builds.

**Consumable Gap**: Herbs, potions, and food items exist in the data files (ability.txt defines Herbcraft which doubles their effect) but the consumable USE system is not wired in Godot. This is an implementation gap, not a design problem: the Sil-Q design assumes between-fight healing via consumables. Implementing this system is P0 -- without it, HP is a one-way ratchet and every build is a death trap eventually. With it, sustain-focused heroes (Sam with Herbcraft, any Will build with potions) gain their intended survival pillar.

### 5.4 Victory Path Feasibility Analysis

The Necromancer has two victory paths. This section models whether each hero can reach the skill requirements given the XP budget.

**Escape Path Requirements:**
- Find the Ring of Thrain and the Master Key
- Survive the ascent back to the surface while Sauron pursues
- Not skill-gated, but requires sufficient combat/stealth/evasion to survive pursuit
- Primary challenge: the pursuit phase, where Sauron (speed 3, 200d4 HP) chases upward

**Banishment Path Requirements:**
- Obtain the Rod of Istari
- Reach Lore 12 + Will 10
- Successfully cast the banishment ritual
- Skill-gated: Lore 12 costs 7,800 XP (6,600 with affinity); Will 10 costs 5,500 XP (4,500 with affinity)

**XP Budget Model:**

| Source | XP Amount | Notes |
|--------|-----------|-------|
| Starting XP | 5,000 | Fixed for all heroes |
| Descent XP (20 floors) | 10,450 | depth * 50 per floor, cumulative |
| Kill XP | ~2,000-4,000 | level * 10 per kill, diminishing returns |
| Encounter XP | ~1,000-2,000 | level * 10 per first sighting |
| Identification XP | ~200-500 | 100 per item identified |
| Lore Reading XP | ~500-1,500 | 500 per scroll/tome read |
| **Realistic Total** | **~15,000-18,000** | Conservative estimate |

**Banishment Path XP Costs by Hero:**

| Hero | Lore 12 Cost | Will 10 Cost | Total | XP Needed Beyond Start | Feasible? |
|------|-------------|-------------|-------|----------------------|-----------|
| **Galadriel** (LOR affinity) | 6,600 (A) | 5,500 | 12,100 | 7,100 | YES - descent XP alone (10,450) covers it |
| **Frodo** (WIL affinity) | 7,800 | 4,500 (A) | 12,300 | 7,300 | YES - barely, needs most descent XP |
| **Faramir** (MEL affinity) | 7,800 | 5,500 | 13,300 | 8,300 | TIGHT - needs significant kill XP too |
| **Glorfindel** (LOR affinity) | 6,600 (A) | 5,500 | 12,100 | 7,100 | POSSIBLE but leaves nothing for Melee |
| Any hero (no affinity) | 7,800 | 5,500 | 13,300 | 8,300 | VERY TIGHT - achievable only with heavy XP farming |

**Escape Path Viability by Archetype:**

| Archetype | Pursuit Survival | Why |
|-----------|-----------------|-----|
| **Melee tanks** (Boromir, Gimli) | MODERATE | Can fight rearguard but Sauron is speed 3, they can't outrun |
| **Evasion/mobility** (Theoden, Eowyn) | GOOD | Sprinting + Charge enable floor-to-floor movement |
| **Stealth** (Bilbo, Frodo, Aragorn) | BEST | Can potentially avoid Sauron entirely on each floor |
| **Lore casters** (Galadriel, Glorfindel) | POOR | Sauron likely immune to crowd control; must flee without tools |
| **Crafters** (Celebrimbor, Sam) | MODERATE | Gear quality helps but no special pursuit advantage |

**Key Insight:** Galadriel is the strongest Banishment candidate (cheapest path at 12,100 XP), but her Escape fallback is the worst. If she fails to find the Rod of Istari, she has no good plan B. Aragorn, by contrast, is a weak Banishment candidate but the most flexible Escape hero.

### 5.5 Energy & Speed System Analysis

All player characters have speed 2 (100 energy/tick, 1 action per game tick). DEX does NOT affect speed -- it contributes only to evasion bonus (`evasion_bonus = skills["evasion"] + (dexterity / 2)`). Speed can only be modified by the SLOW and FAST status effects.

**ENERGY_TABLE:** `[50, 75, 100, 125, 150, 175, 200, 250]` (indices 0-7)

| Speed | Energy/Tick | Actions per 4 Ticks | Examples |
|-------|-------------|---------------------|----------|
| 0 | 50 | 2 | -- |
| 1 | 75 | 3 | Zombies, Brood Mother (slow monsters) |
| **2** | **100** | **4** | **All players**, most monsters (58%) |
| 3 | 125 | 5 | Wargs, Vampires, Uvatha, Khamul, **Sauron** |
| 4 | 150 | 6 | Bats, Crebain (fast flyers) |

**Design Implications:**
- **No hero is faster or slower than another.** Speed differentiation comes entirely from the Sprinting ability (Evasion 7) and SLOW/FAST status effects.
- **Speed 3 monsters get a 25% action advantage.** Against Sauron, a player gets 4 actions for every 5 of his. This is a significant sustained disadvantage in the pursuit phase.
- **DEX is NOT wasted on non-speed builds.** High DEX heroes (Legolas DEX+3, Bilbo DEX+3) benefit from evasion, not speed. This means "fast" heroes are actually "hard to hit" heroes.
- **SLOW status is devastating.** Dropping from speed 2 to speed 1 halves your action rate. Any hero hit with SLOW in a fight is in critical danger. This makes Will saves against SLOW-inflicting monsters a survival requirement.

**Why This Matters for Archetypes:** Some hero fantasies (Legolas the swift, Theoden the charging horseman) feel like they should be faster. The current system can't deliver this through base speed -- instead, these fantasies must be realized through Sprinting, Charge (move + attack in one action), and evasion-based "I dodge everything" play. This is a reasonable tradeoff that avoids the balance nightmare of different player speeds.

### 5.6 Projected Hobbit Viability (if implemented)

| Hero | L1-2 | L3 | L4 | L5 | L6-7 | Pursuit | Wall | Power Curve |
|------|------|-----|-----|-----|------|---------|------|-------------|
| Frodo | 2 | 3 | 4 | 5 | 4 | 3 | L1-2 | Late-bloomer |
| Sam | 3 | 3 | 4 | 4 | 3 | 3 | L6 | Mid-peaker |
| Bilbo | 2 | 4 | 4 | 5 | 3 | 5 | L1 | Late-bloomer |

---

## 6. Fantasy Scorecards

### Power Curves, Death Patterns, and Retention Analysis

| Hero | Power Curve | Primary Death | Retention Hook | "One More Run" |
|------|------------|---------------|----------------|----------------|
| Aragorn | LINEAR (steady) | Attrition | "I learned something" | "Next time I'll invest Stealth early for Assassination openers" |
| Boromir | EARLY PEAK (plateau) | Stat check (Morgul) | "I almost had it" | "I was 2 floors from surface when the Nazgul got me" |
| Legolas | S-CURVE (weak->spike) | Resource exhaustion | "I found something cool" | "That Deadly Hail 5-kill chain -- I need that again" |
| Gimli | LATE BLOOMER | Spike (Mighty Blow recovery) | "I learned something" | "Shouldn't have committed that Mighty Blow with an orc around the corner" |
| Frodo | INVERSE (challenges > power) | Exposure (stealth cascade) | "I almost had it" | "I made it to depth 16 without killing anyone" |
| Sam | S-CURVE (herb spike) | Resource exhaustion | "I found something cool" | "3 Athelas herbs + Herbcraft was incredible" |
| Bilbo | FEAST/FAMINE (binary) | Exposure (catastrophic) | "I found something cool" | "6 Throat Slits with Fade before the alarm. Six!" |
| Theoden | EARLY PEAK + RESURGENCE | Spike (surrounded) | "I learned something" | "Charged without checking corners. Terrain awareness next run" |
| Eowyn | LATE BLOOM (inverted) | Spike (at 1 HP) | "I almost had it" | "Killed the Wraith Lord at 1 HP then a random orc got me" |
| Faramir | S-CURVE (setup->spike) | Resource exhaustion | "Different approach" | "Set up ambush in wrong corridor. Better scouting next time" |
| Galadriel | EXPONENTIAL (wizard) | Spike (early game) | "I learned something" | "Slept the wrong target, the caster got a spell off" |
| Celebrimbor | STEP FUNCTION (forge-dependent) | Resource exhaustion | "I found something cool" | "I Reclaimed the Sword of Gondolin! But should've made armor" |
| Glorfindel | LINEAR + BUMPS | Attrition (spread thin) | "Different approach" | "Spread skills too thin. Focus Melee first, Lore second next time" |

**Power Curve Diversity**: All 13 heroes have unique emotional arcs. This is EXCELLENT design -- no two heroes feel the same.

**Death Pattern Distribution**: Spike (5), Attrition (4), Resource Exhaustion (4), Exposure (3), Stat Check (4). Well-distributed with no single type dominating.

**Retention Hook Distribution**: "I learned something" (6), "I almost had it" (5), "I found something cool" (4), "Different approach" (5). "Discovery" hooks are slightly underrepresented -- consider adding more rare item synergies and unique events per archetype.

### Scoring Criteria
- **Tolkien Resonance (1-5):** Does this build FEEL like the character?
- **Fantasy Alive (1-5):** How well does the CURRENT codebase deliver the fantasy?
- **Fun Factor (1-5):** Is this hero fun to play as a roguelike build?
- **Uniqueness (1-5):** How distinct is this build from all others?
- **Projected Tier:** Assuming all systems implemented

---

## 7. Gap Analysis & Priority Roadmap

### 7.0 Systemic Issues (affect ALL heroes)

These are game-wide problems that must be solved before individual hero balance matters:

| Issue | Impact | Current State | Fix Priority |
|-------|--------|---------------|-------------|
| **Consumables not wired** | Herbs/potions exist in data but can't be used; HP never recovers | Data exists, USE system missing | P0 - CRITICAL |
| **Status effects unimplemented** | HOLD/SLOW/SCARE/DARKNESS don't affect gameplay | DATA ONLY - hidden difficulty reduction | P0 - CRITICAL |
| **Stat drain unimplemented** | LOSE_CON/GRA/STR/ALL don't drain stats | DATA ONLY - wraiths are toothless | P0 - CRITICAL |
| **Evasion wall at L5+** | Player att max ~+11 vs Wraith EVN +14, Khamul +26 | No attack scaling abilities work | P1 - HIGH |
| **Undead immune to all CC** | NO_FEAR+NO_SLEEP+NO_CONF negates Lore builds | By design but no counter exists | P1 - HIGH |
| **Speed 3 monster advantage** | Nazgul/Sauron act 25% more often | By design, no player speed boosts | P2 - MEDIUM |

**The "Two Games" Problem**: Currently the game plays as two entirely different experiences:
1. **Layers 1-3**: Melee dominates. Tank builds trivialize content. Status effects don't work so GRA doesn't matter.
2. **Layers 4-7**: Everything changes. Undead immune to CC, wraith evasion impassable, stat drain (if implemented) cascades. No build has a clear path through.

This creates a design where ALL heroes wall at roughly the same point (Layer 4-5), just for different reasons. The dungeon needs to be solvable, not just survivable.

### 7.1 Critical Blockers (must fix)

| Priority | Issue | Heroes Affected | Complexity |
|----------|-------|-----------------|------------|
| P0 | No archery system | Legolas, Faramir | HIGH - new combat system |
| P0 | No Hobbit race | Frodo, Sam, Bilbo | MEDIUM - data + flags |
| P1 | Axe tval bug (player.gd:807) | Gimli | LOW - one-line fix |
| P1 | Stealth abilities unimplemented | Bilbo, Legolas | MEDIUM - 12 abilities |
| P1 | Faramir = Aragorn clone | Faramir | LOW - move to Gondor house |

### 7.2 High-Impact Abilities to Implement

Based on analysis of which unimplemented abilities would most improve hero diversity:

| Priority | Ability | Tree | Effect | Heroes Benefiting |
|----------|---------|------|--------|-------------------|
| 1 | **Indomitable** | Will 5 | Resist fear/confusion/stun/hallucination | ALL heroes (esp. Boromir, Theoden, Gimli) |
| 2 | **Defy Death** | Will 4 | Survive lethal hit 1/floor at 1 HP | ALL heroes (esp. Eowyn, Frodo) |
| 3 | **Inner Light** | Lore 7 | Counter DARKNESS, light-based combat | Galadriel, Glorfindel, Sam |
| 4 | **Assassination** | Stealth 1 | +Stealth to attack vs unwary | Bilbo, Legolas, Aragorn |
| 5 | **Vanish** | Stealth 5 | Become invisible for 3 turns | Bilbo, Frodo |
| 6 | **Mighty Blow** | Melee 10 | Massive single-target damage | Gimli, Boromir, Theoden |
| 7 | **Deadly Lore** | Lore 8 | Kill enemies below HP threshold on crit | Galadriel, Glorfindel |
| 8 | **Sprinting** | Evasion 5 | Move 2x speed for limited turns | Theoden, Legolas, all pursuit |
| 9 | **Fade** | Stealth 8 | Invisibility after killing unwary target | Bilbo |
| 10 | **Majesty** | Will 9 | Lower morale by Will difference | Galadriel, Glorfindel, Frodo |

### 7.3 New Mechanics Needed

| Mechanic | Description | Heroes Benefiting | Complexity |
|----------|-------------|-------------------|------------|
| SMALL_STATURE | +2 Stealth, -2 att from large monsters, -2 non-proficiency melee | All Hobbits | MEDIUM |
| HOBBIT_LUCK | Reroll lethal d20 1/floor | All Hobbits | LOW |
| SLING_PROFICIENCY | +1 ARC with slings | All Hobbits | LOW |
| DWARVEN_RESILIENCE | +3 Will vs fear/corruption | Gimli (all Dwarves) | LOW |
| Rally | 1/floor break fear/confusion | Theoden | LOW |
| No Living Man | +3 att/dmg vs NO_FEAR enemies | Eowyn | LOW |
| Ithilien Trap | 3-turn setup, +PER/2 att+dmg, auto-Cripple LOS | Faramir | MEDIUM |
| Light Warrior | Melee bonus vs HURT_LITE = Lore/3 | Glorfindel | LOW |
| Horn of Gondor | 1/game: break status, Last Stand, alert floor | Boromir | MEDIUM |
| Sling weapons | New weapon type + stone ammo | All Hobbits | MEDIUM |
| Anti-undead Lore | Turn Undead, Holy Light, Banish Spirit, Sanctify | Galadriel, Glorfindel | HIGH |
| Consumable USE system | Wire herb/potion/food usage to restore HP | ALL heroes | HIGH |

---

## 8. Bold Design Proposals

### 8.1 Anti-Undead Lore Abilities (CRITICAL)

The undead immunity problem (NO_FEAR + NO_SLEEP + NO_CONF) creates a dead zone for Lore casters. Proposed new Lore abilities that specifically target undead:

| Ability | Lore Req | Effect | Tolkien Source |
|---------|----------|--------|----------------|
| **Turn Undead** | Lore 6 | Force undead to flee for 3-5 turns (ignores NO_FEAR) | Gandalf on the Bridge of Khazad-dum |
| **Holy Light** | Lore 8 | Burst of light dealing 2d8 damage to all HURT_LITE enemies in radius 3 | Galadriel's phial, Gandalf's staff |
| **Banish Spirit** | Lore 10 | Instant-kill incorporeal undead (ghosts, wraiths) below HP threshold | Gandalf banishing spirits |
| **Sanctify Ground** | Lore 12 | Create a 3x3 zone where undead cannot enter for 10 turns | Elven enchantments on Rivendell/Lothlorien |

These abilities would use a new "divine/light" damage type that bypasses undead immunities. They should require high Lore investment (8+) so only dedicated Lore builds access them.

### 8.2 The Boromir Tragedy Mechanic

Boromir's S-to-C tier shift when status effects are implemented is thematically perfect but potentially frustrating. Proposed mechanic:

**"The Horn of Gondor"**: Once per game, when Boromir fails a Will save that would kill him, he can blow the Horn of Gondor. This:
- Automatically breaks the status effect
- Alerts every monster on the floor (+10 floor alertness)
- Gives Boromir +5 attack and +5 evasion for 20 turns ("Last Stand")
- After the effect ends, Boromir takes 50% max HP damage

This captures the Amon Hen moment: Boromir falls to corruption, blows his horn, fights gloriously, and then faces the consequences.

### 8.3 Dwarven Resilience

Dwarves in Tolkien are famously resistant to corruption. The Dwarf Rings didn't corrupt their bearers - they only inflamed their natural greed. Proposed racial mechanic:

**DWARVEN_RESILIENCE**: +3 bonus to Will saves vs fear, confusion, and corruption effects specifically. Does NOT help against physical status effects (slow, hold, poison). This is intentionally narrower than Indomitable (which resists everything) but available from level 1 as a racial trait.

### 8.4 Ithilien Trap (Faramir Identity Fix)

**Problem**: Faramir and Aragorn were identical (Man/Dunedain, +1/+1/+1/+1, PER affinity).
**Solution**: Move Faramir to Gondor + add unique "Ithilien Trap" ability.

**Ithilien Trap** (New Ability, Perception tree or unique):
- Spend 3 turns stationary to "prepare" your position
- While prepared:
  - First attack from this position: +Perception/2 to attack AND damage
  - Enemies entering your line of sight: auto-Crippled (slowed) for 1 turn
  - Effect breaks when you move
- Combined with Lore of Silence (quiets the area), creates the "ambush commander" archetype
- Creates unique decision loop: "Is this position worth 3 turns of setup?"
- Design philosophy: Into the Breach -- fights are won before the first arrow flies

**Why This Works**: No other hero asks "should I invest turns NOW for a bigger payoff LATER?" This is the patience-vs-action tradeoff that differentiates Faramir from both Aragorn (always adapting) and Legolas (always shooting). Faramir plans, then executes.

### 8.5 Glorfindel Light Warrior

**Problem**: Glorfindel's hybrid melee+lore spread creates mediocrity risk (C+ tier).
**Solution**: Unique racial/house bonus that bridges both skill trees.

**Light Warrior** (unique passive):
- Melee attacks against HURT_LITE enemies deal bonus damage equal to Lore/3
- Inner Light radius increases by Melee/4
- This rewards investing in BOTH skills simultaneously instead of penalizing split investment
- Thematically: Glorfindel fights with the light of the Two Trees -- his blade IS his light

### 8.6 Eowyn's "No Living Man" Mechanic

**Problem**: Eowyn is mechanically identical to Theoden (same race, house, stats).
**Solution**: Unique anti-boss mechanic.

**No Living Man** (unique passive):
- +3 attack and +3 damage against enemies with the NO_FEAR flag
- Enemies with NO_FEAR that Eowyn kills grant double XP
- This specifically targets bosses and elite undead -- the enemies that are supposed to be fearless
- Thematically: "No living man am I" -- she is the bane of things that cannot be afraid

### 8.7 The Hobbit Courage Mechanic (Vision-Keeper Synthesis)

The three Hobbit heroes represent Tolkien's deepest theme: ordinary courage matters more than extraordinary power. Design the Hobbit experience to reflect this:

**HOBBIT_COURAGE** (emergent from existing proposals):
- When a Hobbit is at less than 25% HP, all Stealth and Will checks gain +2
- This stacks with Strength in Adversity (+1/+3 stats when injured)
- The "desperate hobbit" is MORE dangerous than the comfortable one
- Tolkien source: "I found it is the small everyday deed of ordinary folks that keep the darkness at bay. Small acts of kindness and love." -- Gandalf
- Implementation: Check HP threshold in `stealth_score` and `will_save` calculations

This creates the signature Hobbit emotional arc: comfortable start, terrifying middle, heroic finish. Every Hobbit run should end with the player sweating at 3 HP, slipping past a Wraith, and feeling like they earned it.

---

## 9. Tier List

### 9.1 Current State Tier List (code-verified, combat math)

Based on actual combat math against monster stat blocks:

| Tier | Heroes | Reasoning |
|------|--------|-----------|
| S | Boromir | Protection math makes him nearly invulnerable through L3. Best-realized fantasy. |
| A | Gimli, Aragorn | Strong melee with HP to survive. Wall at L5 but reach further than others. |
| B | Theoden, Glorfindel, Galadriel* | Adequate through L3. Theoden has Charge+Follow-Through. Glorfindel has dual melee+lore. |
| C | Eowyn, Celebrimbor | Eowyn's Will investment is dead weight (unimplemented). Celebrimbor needs forge to function. |
| F | Legolas, Faramir, Frodo, Sam, Bilbo | Non-functional. Missing core systems (archery, Hobbit race). |

*Galadriel is B vs non-undead, F in Layers 4-5. Bimodal viability.

### 9.2 Projected Tier List (ALL systems implemented) -- Calibrated with Real Data

Win rates below are calibrated against published data from comparable roguelikes:
- **DCSS overall win rate: 0.74%** across ~1 million games ([source](http://colinmorris.github.io/blog/dcss_winrates))
- **Sil-Q ladder win rate: ~8%** (23/288 dumps -- heavily selection-biased toward experienced players) ([source](https://angband.live/ladder/ladder-browse.php?v=Sil-Q))
- **Cogmind win rate: 5.3%** in Rogue mode ([source](https://www.gridsagegames.com/blog/2023/03/cogmind-beta-11-player-stats/))
- **ToME4 overall: 1.04%** across 13M characters ([source](https://te4.org/game-statistics))
- **DCSS species spread: ~10x** between easiest (Deep Dwarf ~1.8%) and hardest (Octopode ~0.25%)

**Calibration Framework:**

| Tier | Experienced Player WR | All-Player WR | Benchmark |
|------|----------------------|---------------|-----------|
| A-tier (Recommended) | 12-20% | 2-4% | Like DCSS Minotaur Berserker or Sil Noldor Feanor |
| B-tier (Standard) | 6-12% | 1-2% | Like DCSS average species or Cogmind Rogue mode |
| C-tier (Hard) | 3-6% | 0.5-1% | Like DCSS weaker species or Sil Sindar |
| D-tier (Expert) | 1-3% | 0.1-0.5% | Like DCSS Felid/Octopode or Sil Edain |

Assuming archery, Hobbit race, stealth abilities, status effects, stat drain, consumables, and all 93 abilities work. **No hero is S-tier by design** -- this prevents Cookie Cutter dominance. The target spread is ~6x between easiest and hardest hero (tighter than DCSS's 10x, since our hero roster is smaller and we want all heroes to be reasonable picks).

| Tier | Hero | Exp. WR | All-Player WR | Reasoning |
|------|------|---------|---------------|-----------|
| **A** | Aragorn | 15-20% | 3-4% | The generalist. Never worst, never best. Balanced mastery teaches the game. The "recommended first hero." |
| **A** | Boromir | 15-20% | 3-4% | Dominant early via protection math. Wraith Domain is his trial. Horn of Gondor prevents feels-bad deaths. |
| **A** | Galadriel | 12-18% | 2-3% | Highest ceiling. Exponential power curve = godlike late. Dangerous early (may die depth 3). Needs anti-undead Lore abilities to reach full potential. |
| **B+** | Eowyn | 10-15% | 2-3% | Anti-Wraith specialist. No Living Man gives her a niche no other hero fills. Reverse-scaling (stronger near death). |
| **B+** | Gimli | 10-15% | 2-3% | Mighty Blow is highest single-target burst. CON+3 HP cushion. DEX-1 gets kited. DWARVEN_RESILIENCE helps late. |
| **B** | Legolas | 8-12% | 1.5-2% | Archery kill-chains are spectacular. Dependent on arrow supply. Feast or famine. |
| **B** | Theoden | 8-12% | 1.5-2% | Movement-based combat is unique. Best pursuit-phase hero (Charge + Sprinting). Dies in small rooms. |
| **B** | Bilbo | 6-10% | 1-2% | Highest skill-ceiling build. Throat Slit+Fade chains = roguelike perfection. One detection = death. |
| **B-** | Celebrimbor | 6-10% | 1-2% | Forge-dependent step function. Great forges = A-tier run. No forges = D-tier. Needs pity timer. |
| **C+** | Faramir | 4-8% | 0.7-1.5% | Ithilien Trap creates unique identity. Setup-dependent. Wide variance between good/bad positioning runs. |
| **C+** | Glorfindel | 4-8% | 0.7-1.5% | Hybrid mediocrity risk without Light Warrior. WITH Light Warrior: B-tier. The proposal matters most for him. |
| **C** | Frodo | 3-5% | 0.5-1% | Most narratively compelling. Pacifist-runner. Brutally hard -- expert-only. The "challenge run" hero. |
| **C** | Sam | 3-5% | 0.5-1% | Resource-dependent sustain. Needs herb drop pity timer. Peak in L4-5 vs HURT_LITE. |

### 9.3 Tier List Commentary

**The Boromir Shift**: S-tier currently, A projected. Protection math makes him invulnerable early, but when status effects work, his GRA 0 creates a genuine Wraith Domain trial. This is thematically perfect -- Boromir's struggle against corruption IS his story. The "Horn of Gondor" proposed mechanic provides a dramatic escape valve.

**The Galadriel Paradox**: B-tier currently (helpless vs undead), A-tier projected (needs anti-undead Lore abilities). Without Turn Undead / Holy Light, she has a complete dead zone in Layers 4-5. With them, she's the strongest late-game build.

**Eowyn vs Theoden -- Finally Different**: In the current build, they're clones. With proposals implemented: Theoden is the movement warrior (Crowd Fighting, Sprinting, Rally) who excels in open areas against groups. Eowyn is the defiant duelist (Strength in Adversity, Defy Death, No Living Man) who excels in boss fights and the Wraith Domain. Same stats, completely different play patterns.

**The Hobbit Spread**: Frodo and Sam are intentionally at the bottom -- the hardest heroes to win with. This is thematically correct (Hobbits in Dol Guldur should feel desperate) and follows the Sil tradition of using race as difficulty dial. Bilbo is slightly higher because Stealth is a more proven victory strategy than Will-tanking.

**Calibration Note**: These win rates assume the game reaches a similar difficulty to Sil-Q. If the implementation is closer to "Sil-Q with quality-of-life improvements" (better UI, tutorials, accessibility), expect all rates to shift upward by 2-5 percentage points. The RELATIVE ordering should remain stable.

**Key Design Levers**:
1. Resource pity timers (arrows for Legolas, herbs for Sam, forges for Celebrimbor)
2. Morgul-wound as the great equalizer (keeps tanks honest, gives Will builds their niche)
3. Boss immunities (Sauron/Khamul MUST resist Galadriel's control or she trivializes them)
4. Pursuit phase rewards mobility (Theoden, Frodo, Bilbo are pursuit stars)
5. Spread target: easiest hero (Aragorn ~15-20%) should be ~4x the win rate of hardest (Sam ~3-5%)

---

## 10. Implementation Priority

### Phase 0: Systemic Fixes (affects ALL heroes)
1. **Wire consumable USE system** -- herbs/potions exist in data, need USE handler in Godot. P0.
2. **Implement status effects** -- HOLD, SLOW, SCARE, DARKNESS, CONFUSION must affect gameplay. Currently a hidden difficulty reduction. P0.
3. **Implement stat drain** -- LOSE_CON/GRA/STR/ALL. Wraiths are toothless without this. P0.

### Phase 1: Unlock Broken Heroes (5 heroes fixed)
4. Add Hobbit race to race.txt with SMALL_STATURE + HOBBIT_LUCK + SLING_PROFICIENCY (unlocks Frodo, Sam, Bilbo)
5. Add 3 Hobbit houses to house.txt: Shire (WIL), Gamgee (SMT), Took (STL)
6. Fix axe tval bug in player.gd:807 -- change tval 20 to tval 22 (fixes Gimli)
7. Move Faramir preset from Dunedain to Gondor house (fixes identity)
8. Add sling weapon type + stone ammo to item system

### Phase 2: Core Missing Systems (5 heroes playable)
9. Implement minimum viable archery: basic ranged attack + Keen Eyes + Ambush + Crippling Shot (unlocks Legolas, Faramir)
10. Implement core stealth abilities: Assassination, Disguise, Vanish, Fade, Escape Artist (unlocks Bilbo)
11. Implement SMALL_STATURE and HOBBIT_LUCK racial flag code
12. Implement Indomitable + Defy Death + Strength in Adversity (critical Will abilities)
13. Implement Inner Light + Deadly Lore (critical Lore abilities)

### Phase 3: Hero Identity Mechanics
14. Implement DWARVEN_RESILIENCE racial flag for Dwarves
15. Implement Theoden Rally mechanic (1/floor break fear/confusion)
16. Implement Eowyn "No Living Man" mechanic (+3 att/dmg vs NO_FEAR)
17. Implement Faramir "Ithilien Trap" mechanic
18. Implement Glorfindel "Light Warrior" passive
19. Implement Boromir "Horn of Gondor" mechanic

### Phase 4: Anti-Undead & Balance
20. Implement anti-undead Lore abilities: Turn Undead, Holy Light, Banish Spirit, Sanctify Ground
21. Implement Mighty Blow, Cleave, Sprinting, Majesty
22. Add resource pity timers: guaranteed arrow/herb/forge drops per 3-floor span
23. Balance Morgul-wound effect (the great equalizer for tank builds)
24. Tune pursuit phase per hero archetype

### Phase 5: Polish & Testing
25. Balance testing across all 13 hero builds through all 7 layers
26. Tune XP curve for late-bloomer builds (Elves, Hobbits need enough early XP to survive)
27. Ensure dungeon generation supports all playstyles (corridors for Theoden, forges for Celebrimbor, hiding spots for Bilbo)
28. Verify each hero has at least one viable victory path (Escape or Banishment)

### Estimated Impact Per Phase

| Phase | Heroes Unlocked | Heroes Improved | Priority |
|-------|----------------|-----------------|----------|
| Phase 0 | 0 | ALL 13 | CRITICAL |
| Phase 1 | 5 (Frodo, Sam, Bilbo, Gimli fix, Faramir fix) | 5 | CRITICAL |
| Phase 2 | 2 (Legolas, Faramir ranged) | 5+ | HIGH |
| Phase 3 | 0 | 5 (Theoden, Eowyn, Faramir, Glorfindel, Boromir) | HIGH |
| Phase 4 | 0 | 3+ (Galadriel, Glorfindel, all Lore builds) | MEDIUM |
| Phase 5 | 0 | ALL 13 | MEDIUM |

---

## 11. Data Reference Appendix

### A. Complete Skill Tree Summary (154 abilities across 8 trees)

| Skill | # Abilities | Key Abilities | Affinity Houses |
|-------|-------------|---------------|-----------------|
| Melee (0) | 14 | Power (1), Finesse (2), Charge (5), Follow-Through (6), Cleave (9), Mighty Blow (11) | Gondor, Iron Hills |
| Archery (1) | 12 | Rout (2), Fletchery (3), Point Blank (4), Puncture (5), Keen Eyes (7), Deadly Hail (9) | -- |
| Evasion (2) | 14 | Dodging (2), Blocking (3), Parry (4), Crowd Fighting (5), Sprinting (7), Riposte (10) | Rohan |
| Stealth (3) | 13 | Disguise (3), Assassination (4), Throat Slit (4), Vanish (8), Fade (9) | Greenwood, Took |
| Perception (4) | 12 | Focused Attack (2), Keen Senses (3), Concentration (4), Bane (6), Listen (8) | Dunedain |
| Will (5) | 11 | Curse Breaking (1), Force of Will (2), Strength in Adversity (3), Defy Death (5), Indomitable (5), Majesty (9) | Shire |
| Smithing (6) | 12 | Weaponsmith (2), Armoursmith (3), Jeweller (4), Reforge (5), Expertise (6), Reclaim (7), Masterwork (8) | Rivendell, Gamgee, Erebor |
| Lore (7) | 14 | Word of Command (1), Herbcraft (3), Inner Light (5), Deadly Lore (6), Lore of Sleep (8), Word of Mastery (10) | Lothlorien, Khazad-dum |

### B. Monster Speed Distribution (from monster.txt)

| Speed | Energy/Tick | Count | Notable Monsters |
|-------|-------------|-------|-----------------|
| 1 (Slow) | 75 | ~9% | Zombies, Brood Mother |
| 2 (Normal) | 100 | ~58% | Orcs, Spiders, Trolls, most enemies |
| 3 (Fast) | 125 | ~24% | Wargs, Vampires, Uvatha, Khamul, **Sauron** |
| 4 (Very Fast) | 150 | ~9% | Bats, Crebain |

### C. Race & House Quick Reference

| Race | STR | DEX | CON | GRA | Total | Proficiency | Penalty |
|------|-----|-----|-----|-----|-------|-------------|---------|
| Elf | -1 | +2 | +1 | +2 | +4 | Bow | -- |
| Man | +1 | 0 | +1 | 0 | +2 | Sword | -- |
| Dwarf | +1 | -1 | +3 | 0 | +3 | Axe | ARC_PENALTY |
| Hobbit (proposed) | -2 | +2 | 0 | +2 | +2 | Sling | -2 non-proficiency melee |

| House | Race | Affinity | STR | DEX | CON | GRA |
|-------|------|----------|-----|-----|-----|-----|
| Lothlorien | Elf | Lore | 0 | 0 | 0 | +1 |
| Rivendell | Elf | Smithing | 0 | 0 | +1 | 0 |
| Greenwood | Elf | Stealth | 0 | +1 | 0 | 0 |
| Dunedain | Man | Perception | 0 | +1 | 0 | +1 |
| Rohan | Man | Evasion | +1 | 0 | 0 | 0 |
| Gondor | Man | Melee | 0 | 0 | +1 | 0 |
| Khazad-dum | Dwarf | Lore | 0 | 0 | 0 | +1 |
| Erebor | Dwarf | Smithing | 0 | 0 | +1 | 0 |
| Iron Hills | Dwarf | Melee | +1 | 0 | 0 | 0 |
| Shire (proposed) | Hobbit | Will | 0 | 0 | +1 | 0 |
| Gamgee (proposed) | Hobbit | Smithing | +1 | 0 | 0 | 0 |
| Took (proposed) | Hobbit | Stealth | 0 | +1 | 0 | 0 |

### D. XP Economy Reference

| Formula | Expression | Example |
|---------|-----------|---------|
| Skill point N (base) | 100 * N | 5th point = 500 XP |
| Skill point N (affinity) | 100 * (N-1) | 5th point = 400 XP, 1st point = FREE |
| Skill 0->L (base) | L*(L+1)/2 * 100 | 0->10 = 5,500 XP |
| Skill 0->L (affinity) | (L-1)*L/2 * 100 | 0->10 = 4,500 XP |
| Descent XP per floor | depth * 50 | Floor 20 = 1,000 XP |
| Total descent XP (20 floors) | Sum of (d*50) for d=1..20 | 10,500 XP |
| Kill XP | monster_level * 10 | Level 5 monster = 50 XP |
| Encounter XP (first sight) | monster_level * 10 | Level 5 monster = 50 XP |
| Identification XP | 100 per item | -- |
| Lore reading XP | 500 per scroll/tome | -- |
| Starting XP | 5,000 | Fixed for all heroes |

### E. Win Rate Calibration Sources

| Game | Overall Win Rate | Sample Size | Source |
|------|-----------------|-------------|--------|
| DCSS | 0.74% | ~1M games | [Colin Morris](http://colinmorris.github.io/blog/dcss_winrates) |
| Sil-Q (ladder) | ~8% | 288 dumps | [Angband Ladder](https://angband.live/ladder/ladder-browse.php?v=Sil-Q) |
| NetHack (expert dataset) | 15.9% | 35K games | [codehappy.net](https://codehappy.net/nethack/data.htm) |
| ToME4 | 1.04% | 13M characters | [te4.org](https://te4.org/game-statistics) |
| Cogmind (Rogue) | 5.3% | Beta 11 | [Grid Sage Games](https://www.gridsagegames.com/blog/2023/03/cogmind-beta-11-player-stats/) |
| DCSS (8.1% of players have ever won) | -- | 26K players | [Colin Morris](http://colinmorris.github.io/blog/dcss_players) |
| DCSS (species spread) | 0.25% to 1.8% | -- | Octopode to Deep Dwarf (~10x spread) |

---

*Document v2.0 produced by the Necromancer Design Committee + deep research revision, 2026-02-06*
*Committee: Coordinator + Current-State Analyst + Vision Keeper + Roguelike Expert*
*Research: Ability tree mapping, XP budget modeling, win rate calibration from 6 published roguelike datasets*
