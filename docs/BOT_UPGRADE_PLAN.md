# Bot Intelligence Upgrade Plan -- v3 Brain

**Author:** Independent Roguelike Analysis (Claude Opus 4.6)
**Date:** 2026-02-08
**Scope:** Comprehensive audit of all 10 archetypes, missing playstyle coverage, v3 decision engine design, and experiment methodology
**Correction Note:** The previous Alpha Review incorrectly characterized stealth offense and ranged combat as "broken systems." In fact, the telemetry counters (`_total_stealth_kills`, `_total_detections`) were declared but never incremented in the bot code. The underlying game systems are functional. This plan corrects that error and designs a bot that properly exercises all game systems.

---

# SECTION 1: CURRENT ARCHETYPE AUDIT

## 1.1 WARRIOR (Man of Gondor, Last Stand)

**Build:** STR 4 / DEX 1 / CON 5 / GRA 0 (base 3/1/3/0 + Man +1/0/+1/0 + Gondor 0/0/+1/0)

**Build Assessment:** Solid. Gondor's Melee affinity reduces skill costs. STR 4 gives +2 melee from stat alone. CON 5 yields `24 * 1.2^5 = 60 HP`. DEX 1 is low (only +0.5 evasion from stat), making the warrior reliant on gear and skill for defense. GRA 0 means zero voice pool -- no songs or lore abilities, ever. This is intentional but limits the build's ceiling.

**Last Stand Trait:** +3 attack/damage/evasion below 25% HP. Powerful emergency mechanic, but the bot has no awareness of this threshold. It never intentionally operates at low HP to exploit the bonus.

**Skill Priorities:** `["melee", "evasion", "will", "stealth"]`
- Good: Melee first is correct for this build. Evasion second provides defense.
- Problem: Will third is wasteful with GRA 0. The warrior has no voice charges to use Will-gated abilities (Defy Death requires Will 5, Strength in Adversity requires Will 3). At GRA 0, max voice is `20 * 1.2^0 = 20` charges -- enough for a few emergency uses but the skill investment is expensive.
- Fix: Replace Will third with `"hunting"` for Focused Attack (+hunting/2 when stationary), Concentration (+1 attack per consecutive round vs same target), and Bane (scaling bonus vs selected enemy type). These directly multiply the warrior's combat output.

**Ability Wishlist:** Power (MEL 0), Dodging (EVN 0), Finesse (MEL 1), Blocking (EVN 1)
- Good: Power (+1 damage sides) is the best first melee ability. Dodging (+3 evasion after moving) is essential.
- Problem: Missing Follow-Through (MEL 5, requires Power or Finesse) which gives free attacks after kills -- critical for a warrior who should be chaining kills.
- Problem: Missing Charge (MEL 4, +3 STR/DEX when attacking after movement toward enemy). With STR 4, Charge effectively gives STR 7 on approach, dramatically increasing damage.
- Fix: Wishlist should be: Power, Dodging, Finesse, Charge, Follow-Through, Blocking.

**Bot Behavior Issues:**
1. No positional awareness. The warrior should seek corridor fights (1v1 instead of being flanked).
2. No Last Stand exploitation. When HP is at 26-30% (15-18 HP out of 60), the warrior should fight aggressively, not flee. Last Stand turns the warrior into a glass cannon.
3. No weapon-awareness in combat decisions. Heavy weapons (Great Axe, Longsword) benefit from standing still (no Dodging bonus but more STR damage), while light weapons benefit from hit-and-move.
4. Attack target selection is purely "lowest HP adjacent monster." Should factor in threat level -- kill the Orc Sorcerer first, not the half-dead bat.

**Telemetry Gaps:**
- `_total_stealth_kills`: Declared, never incremented (not relevant to warrior anyway).
- Missing: `_total_corridor_fights`, `_total_last_stand_activations`, `_total_follow_through_kills`, `_total_charge_attacks`.

---

## 1.2 STEALTH (Hobbit of the Tooks, Nimble Striker)

**Build:** STR -2 / DEX 6 / CON 1 / GRA 5 (base 0/3/1/3 + Hobbit -2/+2/0/+2 + Tooks 0/+1/0/0)

**Build Assessment:** The original stealth archetype. DEX 6 gives +3 evasion from stat and strong stealth scaling. GRA 5 gives `20 * 1.2^5 = 50` voice charges -- enough for Song of the Trees (1/turn for 50 turns). CON 1 yields `24 * 1.2^1 = 29 HP` -- very fragile. STR -2 means -1 melee from stat and negligible physical damage. SMALL_STATURE gives +2 stealth and -2 attack from large monsters. HOBBIT_LUCK gives one lethal d20 reroll per floor.

**Nimble Striker Trait:** Move + attack in same turn: +2 evasion. Kill this way: next move costs no energy. This is a hit-and-run trait that the bot never exploits because it has no concept of move-then-attack sequences.

**Skill Priorities:** `["stealth", "evasion", "will", "lore"]`
- Good: Stealth first is correct. Evasion second makes sense for a fragile build.
- Problem: Will third, same issue as warrior but slightly better since GRA 5 gives enough voice for some Will-based saves.
- Problem: Lore fourth is interesting (Song of the Trees is on the wishlist) but the skill investment to reach Lore 5 (Song of Trees prerequisite) is expensive. More importantly, the bot treats STEALTH and STEALTH_PURE identically in `_init_archetype_strategy()`.
- Fix: This archetype should have distinct behavior from STEALTH_PURE. The STEALTH base archetype with Nimble Striker should be a hybrid: stealth-approach, then hit-and-run with Nimble Striker bonus. Skill priorities should be `["stealth", "evasion", "melee", "lore"]`.

**Ability Wishlist:** Disguise (STL 0), Dodging (EVN 0), Assassination (STL 1), Song of the Trees (LOR 15)
- Problem: Song of the Trees is listed as `"ability": 15`, which is the LOR_SONG_OF_FREEDOM enum value, not Song of the Trees. Song of the Trees is enum value 16 (LOR_SONG_OF_THE_TREES). This is likely a bug causing the wrong song to be learned.
- Problem: Missing Throat Slit (STL 7, instant kill sleeping/unaware humanoids) -- the single most powerful stealth ability.
- Fix: Wishlist should be: Disguise, Assassination, Dodging, Throat Slit, Vanish, Song of the Trees (ability 16 not 15).

**Bot Behavior Issues:**
1. STEALTH and STEALTH_PURE share the same `_init_archetype_strategy()` case -- `"STEALTH", "STEALTH_PURE":`. This means STEALTH uses pure-avoidance behavior rather than its intended hybrid combat/stealth approach.
2. `_total_stealth_kills` is never incremented anywhere in survival_bot.gd. The counter exists but no code path writes to it.
3. `_total_detections` is never incremented anywhere. No code detects when stealth checks fail.
4. `_total_combats_avoided` is only incremented in `_stealth_pure_decide()`, not in the general STEALTH decision path (which falls through to the default `_decide_and_act()`).
5. No concept of approaching sleeping/unwary monsters for assassination. The bot either avoids all monsters (PURE) or fights them head-on (default).

**Telemetry Gaps:**
- `_total_stealth_kills`: Never incremented. Needs: check if monster was unwary/sleeping at moment of kill, then increment.
- `_total_detections`: Never incremented. Needs: hook into monster alertness transitions -- when a monster goes from unwary to alert while the player is stealthed, increment.
- Missing: `_total_assassination_bonus_attacks` (attacks where Assassination ability added stealth to attack roll), `_total_throat_slits`, `_total_nimble_striker_procs`.

---

## 1.3 LORE_MAGE (Elf of Lothlorien, Light of the Eldar)

**Build:** STR -1 / DEX 2 / CON 3 / GRA 7 (base 0/0/2/4 + Elf -1/+2/+1/+2 + Lothlorien 0/0/0/+1)

**Build Assessment:** The best-performing archetype in 200 bot runs. GRA 7 yields `20 * 1.2^7 = 72` voice charges with regen of `72/150 = 0.48/turn`. CON 3 gives `24 * 1.2^3 = 41 HP` -- not great but survivable. Lothlorien's Lore affinity makes Lore skills cheaper. BOW_PROFICIENCY (+1 archery with bows) is wasted on this build.

**Light of the Eldar Trait:** +1 light radius, undead within light radius suffer -2 attack and evasion. Powerful in the Necropolis layer (floors 10-12) where undead are common. The bot has zero awareness of this -- it does not factor light radius into tactical positioning against undead.

**Skill Priorities:** `["lore", "will", "evasion", "stealth"]`
- Good: Lore first is essential. Will second for mental resistance and Defy Death access.
- Good: Evasion third for defense, stealth fourth for Song of Trees synergy.
- No changes needed.

**Ability Wishlist:** Word of Command (140), Song of Freedom (155), Deep Memory (142), Lore of Sleep (150), Curse Breaking (100)
- Good: Word of Command as first ability is correct -- AOE fear+stun is the best emergency tool.
- Problem: Song of Freedom (155) is listed but Song of the Trees (156) might be better for a build that invests in stealth fourth. However, for a pure caster, +3 evasion is more universally useful than +5 stealth.
- Problem: Missing Herbcraft (145, double healing from herbs/potions). With limited HP pool, doubling healing efficiency is enormous. Missing Lore of Silence (144, reduce monster perception in radius). Missing Inner Light (147, damage light-sensitive monsters -- synergizes with Light of the Eldar trait).
- Fix: Wishlist should be: Word of Command, Deep Memory, Herbcraft, Song of Freedom, Lore of Sleep, Lore of Silence, Inner Light.

**Bot Behavior Issues:**
1. Deep Memory is overused: 20.8 uses per run, but the bot uses it as an offensive ability (it appears in `_try_offensive_ability()`) rather than purely for map reveal. It should only fire when stairs are unknown.
2. Word of Command used only 3.2 times per run despite having 23 possible uses per full voice pool. The bot is too conservative with voice spending.
3. Lore of Sleep shows 0.0 uses per run despite being on the wishlist. This suggests the bot either never learns it (Lore 8 requirement) or the activation path has a bug.
4. No Song cycling: the bot does not switch between exploration songs (Trees for stealth) and combat songs (Freedom for evasion, Aule for melee).
5. The `_try_proactive_lore_abilities()` function targets the strongest visible monster with Lore of Sleep, but in Sil-Q, you want to sleep the CLOSEST approaching monster to buy time, not the strongest.

**Telemetry Gaps:**
- Missing: `_total_lore_of_silence`, `_total_inner_light`, `_total_herbcraft_heals`, `_total_song_switches`, `_total_voice_at_death` (how much unspent voice when dying).

---

## 1.4 RANGER (Man/Dunedain, Wayfarer's Instinct)

**Build:** STR 3 / DEX 3 / CON 4 / GRA 2 (base 2/2/3/1 + Man +1/0/+1/0 + Dunedain 0/+1/0/+1)

**Build Assessment:** The jack-of-all-trades. Balanced stats mean nothing is great but nothing is terrible. CON 4 gives `24 * 1.2^4 = 50 HP` -- decent. DEX 3 gives +1.5 evasion from stat. Dunedain's Perception affinity supports hunting skills. SWORD_PROFICIENCY (+1 melee with swords). One run reached floor 6 in v1, the highest individual depth.

**Wayfarer's Instinct Trait:** Detect traps within 3 tiles. On floor entry, reveal doors/stairs within 8 tiles. -2 movement noise. The stairs reveal is ENORMOUSLY powerful for bot play -- it removes the need to explore for stairs. The -2 movement noise directly buffs stealth. The bot has no awareness of these benefits.

**Skill Priorities:** `["archery", "evasion", "hunting", "stealth"]`
- Good: Archery first for the hybrid build. Evasion second.
- Problem: Hunting third is correct for the Dunedain affinity, but the bot never uses Focused Attack (requires standing still one turn) or Concentration (requires attacking same target consecutively).
- Fix: Add melee as fifth priority. A ranger who runs out of arrows needs a backup plan.

**Ability Wishlist:** Fletchery (ARC 1), Point Blank (ARC 2), Dodging (EVN 0), Natural Talent (PER 0)
- Good: Fletchery (create +3 arrows from ordinary ones) is essential for ammo sustainability.
- Good: Point Blank (no attack-of-opportunity when firing adjacent) is critical for ranged builds.
- Problem: Missing Keen Eyes (ARC 5, +2 archery at range 5+). Missing Ambush (ARC 4, +1 crit die vs unwary/sleeping).
- Fix: Wishlist should be: Fletchery, Point Blank, Dodging, Natural Talent, Keen Eyes, Ambush.

**Bot Behavior Issues:**
1. Ranged attacks show 0.4-0.5 shots per run. This is far too low. The ranger should be firing at every visible non-adjacent monster.
2. The bot checks `_player.can_fire_ranged()` which requires a bow in the "bow" equipment slot AND ammo. Starting gear may not include a bow, and the bot may not find/equip one before dying.
3. Kiting logic checks `dist < 2 or dist > 8` to skip invalid targets, but corridor geometry means most fights happen at distance 2-4. The range filter is fine.
4. No Fletchery usage. The bot learns it but never calls the ability to create better arrows.
5. The Wayfarer's Instinct trait reveals stairs on floor entry, but the bot's `_do_auto_explore_step()` does not check for already-known stairs locations before exploring.

**Telemetry Gaps:**
- Missing: `_total_arrows_crafted` (Fletchery), `_total_stairs_revealed_by_trait`, `_total_ambush_crits`.

---

## 1.5 TANK (Dwarf of the Iron Hills, Mithril Skin)

**Build:** STR 4 / DEX -1 / CON 7 / GRA 0 (base 2/0/4/0 + Dwarf +1/-1/+3/0 + IronHills +1/0/0/0)

**Build Assessment:** Best average depth in v1 (2.2). CON 7 gives `24 * 1.2^7 = 86 HP` -- highest in the game. STR 4 gives +2 melee. DEX -1 gives -0.5 evasion from stat -- terrible, but mitigated by Mithril Skin. AXE_PROFICIENCY (+1 melee with axes). Iron Hills' Melee affinity reduces melee skill costs.

**Mithril Skin Trait:** +1d2 innate protection. Evasion capped at 10. Requires CON 3+. This means the tank takes 1-2 less damage per hit from innate armor, but can never exceed 10 evasion. At DEX -1 and starting evasion 0, reaching evasion 10 requires significant investment -- the cap is not a practical limitation for many floors. The 1d2 protection stacks with equipped armor, making heavy armor builds even tankier.

**Skill Priorities:** `["evasion", "melee", "will", "smithing"]`
- Problem: Evasion first is wrong for this build. With Mithril Skin capping evasion at 10, the tank should NOT invest heavily in evasion. The first few points are valuable (getting from -0.5 to a reasonable dodge chance), but the priority should be melee first for offensive output.
- Problem: Smithing fourth is interesting for crafting armor, but with GRA 0, no Song of Aule is possible, limiting smithing bonus.
- Fix: Priorities should be `["melee", "evasion", "will", "hunting"]`. Melee first for kills, evasion second (to around 5-6, not capped), then will for Strength in Adversity (+1 STR/DEX/GRA at 50% HP, +3 at 25%).

**Ability Wishlist:** Dodging (EVN 0), Blocking (EVN 1), Power (MEL 0), Curse Breaking (WIL 0)
- Problem: Dodging gives +3 evasion after moving, but the tank's ideal play is to STAND STILL in a corridor and block. Blocking (doubles shield protection when stationary) is the correct first evasion ability for a tank.
- Problem: Missing Heavy Armour Use (EVN 7, bonus protection scaled by armor weight) -- the tank should be wearing the heaviest armor and benefiting from it.
- Problem: Missing Crowd Fighting (EVN 3, halves surround bonus) -- essential for a tank who will regularly be surrounded.
- Fix: Wishlist should be: Power, Blocking, Crowd Fighting, Heavy Armour Use, Curse Breaking, Strength in Adversity (WIL 2).

**Bot Behavior Issues:**
1. No doorway-fighting logic. The tank should seek narrow corridors and doorways to prevent flanking.
2. No shield-awareness. The bot does not know whether it has a shield equipped, which changes whether Blocking is useful.
3. No "stand and fight" mode. The tank should prefer standing still (Blocking doubles shield protection when not moving) rather than chasing monsters.
4. Rest behavior is aggressive enough (93 avg rest turns for SMITH dwarf), but the tank should rest even more -- with 86 HP, recovering to 80% takes longer and is more valuable.

**Telemetry Gaps:**
- Missing: `_total_blocking_procs`, `_total_heavy_armour_protection`, `_total_mithril_skin_absorbed`, `_total_doorway_fights`.

---

## 1.6 SMITH (Dwarf of Erebor, Forge Intuition)

**Build:** STR 4 / DEX 0 / CON 7 / GRA 0 (base 3/1/3/0 + Dwarf +1/-1/+3/0 + Erebor 0/0/+1/0)

**Build Assessment:** Same HP as tank (86). Erebor's Smithing affinity makes smithing skills cheaper. Forge Intuition auto-identifies items on pickup -- hugely valuable since it reveals potion/herb types without risk.

**Forge Intuition Trait:** Items you pick up are automatically identified. This eliminates the identification gamble and is the single best quality-of-life trait in the game. The bot gains full benefit passively but does not factor identification into item-seeking priority (it should prioritize picking up unidentified items since they become identified instantly).

**Skill Priorities:** `["smithing", "melee", "evasion", "will"]`
- Good: Smithing first is correct for this archetype.
- Good: Melee second for combat capability while building smithing.
- Fix: No changes needed to priorities.

**Ability Wishlist:** Weaponsmith (SMT 0), Armoursmith (SMT 1), Song of Aule (LOR 17), Power (MEL 0), Dodging (EVN 0)
- Critical Problem: Song of Aule requires Lore skill at level 7 and costs voice charges. With GRA 0, the smith has 20 voice charges and zero Lore skill. The bot would need to invest heavily in Lore (which is not in the skill priorities at all) to reach Lore 7. Song of Aule is unreachable for this build.
- Problem: Missing Reforge (SMT 3, combine 2 Broken Glowing items for random enchanted item). This is the core smithing progression ability.
- Fix: Remove Song of Aule (unreachable). Wishlist: Weaponsmith, Armoursmith, Power, Dodging, Reforge, Expertise.

**Bot Behavior Issues:**
1. 0 successful forges across 50 runs despite 2.8 forge visits. The `_try_use_forge()` function creates a SmithingSystem dynamically, calls `get_available_recipes()`, then tries to use the first recipe. The failure chain is likely: (a) no mithril materials found near forge, or (b) smithing skill is 0 when the forge is first encountered (XP not yet invested).
2. The bot invests skills in round-robin from the priority list, meaning smithing gets the first point. But `smithing_skill * 5` at skill 1 = 5% success rate. This is too low to reliably forge.
3. No material hoarding behavior. The bot should actively seek and pick up smithing materials (items with "mithril", "fragment", "ore", etc. in their name).
4. Forge Intuition's auto-identification is passive and works, but the bot does not factor this into item priority -- it should value unidentified items higher since they are instantly revealed.

**Telemetry Gaps:**
- Missing: `_total_materials_collected`, `_total_forge_failures` (distinct from successes), `_total_items_identified_by_trait`.

---

## 1.7 STEALTH_PURE (Hobbit of the Tooks, Shadow Walker)

**Build:** STR -1 / DEX 8 / CON 2 / GRA 5 (base 1/5/2/3 + Hobbit -2/+2/0/+2 + Tooks 0/+1/0/0)

**Build Assessment:** Maximum stealth specialization. DEX 8 is the highest of any archetype, giving +4 evasion from stat and massive stealth scaling. CON 2 yields only `24 * 1.2^2 = 35 HP` -- very fragile. GRA 5 gives 50 voice for Song of the Trees. The Shadow Walker trait is not defined in the GDD's trait list (which goes to ID 19). If it grants stealth bonuses, this could be extremely powerful.

**Skill Priorities:** Same as STEALTH (`["stealth", "evasion", "will", "lore"]`)
**Ability Wishlist:** Same as STEALTH (Disguise, Dodging, Assassination, Song of Trees at ability 15)

- Problem: Same wishlist bug as STEALTH -- ability 15 maps to Song of Freedom, not Song of the Trees (ability 16).
- Problem: A STEALTH_PURE build should NOT have Assassination on the wishlist. Pure stealth means avoiding all combat. Replace with Vanish (STL 5, +10 stealth for making enemies unwary out of LOS) and Escape Artist (STL 3, auto-break webs, half trap damage).
- Fix: Wishlist: Disguise, Vanish, Dodging, Escape Artist, Song of the Trees (ability 16).

**Bot Behavior Issues:**
1. `_stealth_pure_decide()` is well-structured but `_move_avoiding_monsters()` uses a simple greedy score (sum of distances to visible monsters). This does not account for LOS blocking -- a tile behind a wall is safe even if it is closer to the monster in Chebyshev distance.
2. 97.3 combats avoided per run proves the avoidance logic works. But the bot explores the entire floor before descending, when a pure stealth character should beeline for stairs.
3. No door-closing behavior. Closing doors behind you breaks LOS and allows stealth resets. This is THE critical tactic for stealth characters.
4. `_total_combats_avoided` is incremented (97.3 average) but `_total_stealth_kills` and `_total_detections` are never written.
5. When cornered, the bot attacks with STR -1 (terrible damage). It should use the HOBBIT_LUCK reroll and then flee on the next turn rather than committing to melee.

**Telemetry Gaps:**
- `_total_detections`: Never incremented. Should fire when monster alertness crosses from unwary to alert while player is stealthed.
- Missing: `_total_doors_closed_for_stealth`, `_total_los_breaks`, `_total_hobbit_luck_saves`.

---

## 1.8 STEALTH_ASSASSIN (Hobbit of the Tooks, Nimble Striker)

**Build:** STR 1 / DEX 7 / CON 2 / GRA 4 (base 3/4/2/2 + Hobbit -2/+2/0/+2 + Tooks 0/+1/0/0)

**Build Assessment:** Hybrid stealth/melee. STR 1 is better than the pure stealth builds but still weak. DEX 7 gives excellent stealth and evasion. CON 2 = 35 HP, still fragile. The key difference from STEALTH_PURE is that this build invests in STR for actual damage output.

**Nimble Striker Trait:** Move + attack: +2 evasion. Kill by move+attack: free next move. This is the ideal assassin trait. Approach from stealth, kill in one move+attack, get a free move to reposition.

**Skill Priorities:** `["stealth", "melee", "evasion", "will"]`
- Good: Stealth first, melee second is the correct assassin split.
- Fix: No changes needed.

**Ability Wishlist:** Disguise (STL 0), Assassination (STL 1), Power (MEL 0), Dodging (EVN 0)
- Good: Disguise + Assassination is the core combo.
- Problem: Missing Throat Slit (STL 7). The assassination loop is: stealth -> approach sleeping target -> Throat Slit (instant kill humanoids) -> Fade (2 turns invisibility) -> repeat. Without Throat Slit, the assassin is just a stealthy melee fighter.
- Problem: Missing Opening Strike (MEL 6, +1 damage die vs unwary/sleeping). Stacks with Assassination bonus.
- Fix: Wishlist: Disguise, Assassination, Power, Throat Slit, Dodging, Opening Strike.

**Bot Behavior Issues:**
1. `_stealth_assassin_decide()` exists and has correct structure: approach stealthily, attack when close. But it has NO tracking of stealth kills or detections.
2. Line 1472-1478: When the assassin spots a visible monster while stealthed, it approaches. But it approaches the WEAKEST target (`_get_weakest_visible_monster()`) rather than the most VULNERABLE (closest sleeping/unwary monster). In assassination, you want to kill whatever is sleeping, not whatever has the lowest HP.
3. Line 1484: "Visible monster but not stealthed -- flee and re-stealth." This is correct behavior but `_manage_stealth()` for STEALTH_ASSASSIN sets `should_stealth = not _has_adjacent_monster()`, meaning stealth toggles on/off every time a monster becomes adjacent. The re-stealth timing is wrong -- stealth should only be re-entered when OUT of all monster LOS, not just when no monster is adjacent.
4. No Nimble Striker exploitation. The bot does not track whether its last action was a move, so it cannot know if Nimble Striker is active.
5. The bot never checks `monster.alertness` to find assassination-viable targets.

**Telemetry Gaps:**
- `_total_stealth_kills`: Never incremented. Must check monster alertness < ALERTNESS_ALERT at moment of kill.
- Missing: `_total_assassination_approaches`, `_total_throat_slits`, `_total_nimble_striker_free_moves`, `_total_re_stealth_after_kill`.

---

## 1.9 RANGER_MARKSMAN (Man/Dunedain, Wayfarer's Instinct)

**Build:** STR 4 / DEX 5 / CON 3 / GRA 2 (base 3/4/2/1 + Man +1/0/+1/0 + Dunedain 0/+1/0/+1)

**Build Assessment:** More DEX-focused than the base RANGER. DEX 5 gives +2.5 evasion from stat and better archery. STR 4 provides reasonable melee backup. CON 3 = 41 HP, lower than the base ranger's CON 4. This is a glass cannon ranged build.

**Skill Priorities:** Same as RANGER (`["archery", "evasion", "hunting", "stealth"]`)
**Ability Wishlist:** Same as RANGER (Fletchery, Point Blank, Dodging, Natural Talent)

- Problem: Shares strategy with base RANGER but should have distinct marksman behavior -- favoring maximum range, Steady Aim procs (the trait is Wayfarer's Instinct not Steady Aim, so this does not apply). The trait is the same as RANGER.
- Problem: No Keen Eyes (ARC 5, +2 archery at range 5+) on wishlist. This is THE marksman ability.
- Fix: Wishlist should be: Fletchery, Keen Eyes, Point Blank, Dodging, Natural Talent, Deadly Hail (ARC 7).

**Bot Behavior Issues:**
1. 0.4 avg ranged shots per run. The bot dies before accumulating enough ammo or finding a bow.
2. Starting gear for Man includes a Curved Sword but NOT a bow. The marksman must FIND a bow to become functional. This is a critical dependency on floor loot.
3. The kiting logic exists and is reasonable but activates too rarely because `can_fire_ranged()` returns false (no bow equipped).
4. No awareness of Keen Eyes range bonus. Should prefer targets at range 5+ when the ability is learned.

**Telemetry Gaps:**
- Missing: `_total_arrows_remaining_at_death`, `_total_keen_eyes_shots` (shots at range 5+), `_total_bow_found_floor` (which floor the bow was found on).

---

## 1.10 RANGER_STEALTH_ARCHER (Man/Dunedain, Wayfarer's Instinct)

**Build:** STR 1 / DEX 5 / CON 3 / GRA 4 (base 0/4/2/3 + Man +1/0/+1/0 + Dunedain 0/+1/0/+1)

**Build Assessment:** Hybrid stealth/archery. STR 1 gives minimal melee damage. GRA 4 = `20 * 1.2^4 = 41 voice` -- enough for Song of the Trees. This is the most point-spread build, with nothing above 5.

**Skill Priorities:** `["archery", "stealth", "evasion", "hunting"]`
- Good: Archery + stealth is the intended combo. Fire from stealth for Ambush crits.
- Fix: No changes.

**Ability Wishlist:** Fletchery (ARC 1), Disguise (STL 0), Point Blank (ARC 2), Dodging (EVN 0)
- Good: Fletchery + Disguise is the right combo for stealth archery.
- Problem: Missing Ambush (ARC 4, +1 crit die vs unwary/sleeping). This is the ability that makes stealth archery powerful -- guaranteed crits against unwary targets.
- Fix: Wishlist: Fletchery, Disguise, Point Blank, Ambush, Dodging, Song of Trees (LOR 16).

**Bot Behavior Issues:**
1. Falls through to the default `_decide_and_act()` rather than having a custom decision function. Should have its own `_stealth_archer_decide()` that: enter stealth -> find target -> shoot from stealth -> re-stealth if detected.
2. 0.5 avg ranged shots per run. Same bow-finding problem as RANGER_MARKSMAN.
3. No concept of "shoot from stealth" -- the bot drops stealth when it sees a monster (line 1254: `should_stealth = not _has_visible_monster()` for RANGER), then tries to shoot. It should KEEP stealth on and shoot while stealthed to trigger Ambush bonuses.
4. The `_manage_stealth()` function turns stealth OFF for RANGER archetypes when monsters are visible. This is backwards for a stealth archer -- stealth should stay ON until the monster is adjacent.

**Telemetry Gaps:**
- Missing: `_total_stealth_shots` (ranged attacks while stealthed), `_total_ambush_crits`.

---

# SECTION 2: MISSING ARCHETYPES

## 2.1 Systematic Coverage Analysis

The game design supports `4 races * 3 houses * 20 traits * (stat permutations)` character builds. The current 10 archetypes cover:

| Race | Houses Covered | Houses Missing |
|------|---------------|---------------|
| Elf | Lothlorien (1/3) | Rivendell, Greenwood |
| Man | Dunedain, Gondor (2/3) | Rohan |
| Dwarf | Iron Hills, Erebor (2/3) | Khazad-dum |
| Hobbit | Tooks (1/3) | Shire, Gamgees |

| Skill Focus | Archetypes | Missing |
|-------------|-----------|---------|
| Melee | WARRIOR, TANK | Polearm specialist, dual-wield (Subtlety + Swift Strikes) |
| Archery | RANGER, MARKSMAN, STEALTH_ARCHER | Sling specialist (Hobbit) |
| Evasion | (secondary in all) | Evasion-primary build (dodge-tank) |
| Stealth | STEALTH, STEALTH_PURE, STEALTH_ASSASSIN | (well covered) |
| Perception | (secondary in RANGER) | Perception-primary (hunter/tracker) |
| Will | (never primary) | Will-primary (willpower tank, anti-magic) |
| Smithing | SMITH | (covered, but single archetype) |
| Lore | LORE_MAGE | Lore-secondary hybrid, Banishment specialist |

## 2.2 Proposed New Archetypes

### POLEARM_MASTER (Man of Rohan, Defiance)

**Rationale:** Rohan is the only Man house not represented. Polearms (Spear, Glaive, Great Axe) have unique abilities: Polearm Mastery (free attacks on advancing enemies), Charge (+3 STR/DEX after movement). Rohan's Evasion affinity supports a mobile fighter. Defiance (+1 attack/damage vs out-of-depth monsters) rewards descending aggressively.

```gdscript
"POLEARM_MASTER": {
    "archetype_id": "POLEARM_MASTER",
    "name": "SurvivalBot-PolearmMaster",
    "race": "Man",
    "house": "Of Rohan",
    "trait": "Defiance",
    "gender": "male",
    # Cost: 6+3+3+1 = 13. Final with Man(+1/0/+1/0) + Rohan(+1/0/0/0): STR5 DEX2 CON3 GRA1
    "base_stats": {"str": 3, "dex": 2, "con": 2, "gra": 1},
}
```

**Skill priorities:** `["melee", "evasion", "hunting", "will"]`
**Ability wishlist:** Power (MEL 0), Polearm Mastery (MEL 3), Charge (MEL 4), Dodging (EVN 0), Follow-Through (MEL 5), Cleave (MEL 8)
**Unique bot behavior:** Seek corridors. Wait in doorways for monsters to approach (triggers Polearm Mastery free attack). Use Charge by moving toward distant visible monsters. When Cleave is learned, seek multi-monster engagements rather than avoiding them.

---

### ELF_SMITH (Elf of Rivendell, Forge Intuition)

**Rationale:** Rivendell's Smithing affinity makes it the best smithing house for Elves, and Elves have +4 total stats. Combined with Forge Intuition for auto-identification, this creates a smith who can identify everything and craft effectively while having reasonable Grace for Song of Aule.

```gdscript
"ELF_SMITH": {
    "archetype_id": "ELF_SMITH",
    "name": "SurvivalBot-ElfSmith",
    "race": "Elf",
    "house": "Of Rivendell",
    "trait": "Forge Intuition",
    "gender": "female",
    # Cost: 3+0+6+3 = 12... adjust: 3+1+6+3 = 13. Final with Elf(-1/+2/+1/+2) + Rivendell(0/0/+1/0): STR1 DEX3 CON5 GRA5
    "base_stats": {"str": 2, "dex": 1, "con": 3, "gra": 3},
}
```

**Skill priorities:** `["smithing", "evasion", "lore", "melee"]`
**Ability wishlist:** Weaponsmith (SMT 0), Armoursmith (SMT 1), Song of Aule (LOR 17), Dodging (EVN 0), Reforge (SMT 3), Expertise (SMT 4)
**Unique bot behavior:** Aggressively seek forges and materials. Start Song of Aule before forging. GRA 5 gives 50 voice -- enough to sustain Aule (2/turn) for 25 turns. Prioritize picking up all items (auto-identified by trait). Hoard smithing materials.

---

### WILL_TANK (Dwarf of Khazad-dum, Undying Resolve)

**Rationale:** Khazad-dum is the only Dwarf house not represented. Its Lore affinity is unusual for a Dwarf (GRA 0 normally), but combined with a Will-primary build, it creates a character that resists every mental effect in the game. Undying Resolve (survive lethal damage once per game at 50% HP) stacks with Defy Death (once per floor, Will save to survive at 1 HP).

```gdscript
"WILL_TANK": {
    "archetype_id": "WILL_TANK",
    "name": "SurvivalBot-WillTank",
    "race": "Dwarf",
    "house": "Of Khazad-dum",
    "trait": "Undying Resolve",
    "gender": "male",
    # Cost: 3+0+10+0 = 13. Final with Dwarf(+1/-1/+3/0) + Khazad-dum(0/0/0/+1): STR3 DEX-1 CON7 GRA1
    "base_stats": {"str": 2, "dex": 0, "con": 4, "gra": 0},
}
```

**Skill priorities:** `["will", "melee", "evasion", "hunting"]`
**Ability wishlist:** Curse Breaking (WIL 0), Strength in Adversity (WIL 2), Formidable (WIL 3), Defy Death (WIL 4), Power (MEL 0), Blocking (EVN 1)
**Unique bot behavior:** Intentionally absorb damage, relying on dual death-prevention (Undying Resolve at lethal, Defy Death per floor). Use Formidable (kills scare visible enemies) to generate morale pressure. Invest in Will to reach Indomitable (WIL 5, resist fear/confusion/stun, 1/3 hunger rate).

---

### STEALTH_ARCHER_HOBBIT (Hobbit of the Shire, Steady Aim)

**Rationale:** Hobbits have SLING_PROFICIENCY (+1 archery with slings) but no current archetype uses slings. Shire's Will affinity provides mental resistance. Steady Aim (+3 ranged attack, +1 crit die when stationary) creates a sniper who stands still and fires devastating shots.

```gdscript
"HOBBIT_SNIPER": {
    "archetype_id": "HOBBIT_SNIPER",
    "name": "SurvivalBot-HobbitSniper",
    "race": "Hobbit",
    "house": "Of the Shire",
    "trait": "Steady Aim",
    "gender": "male",
    # Cost: 0+6+3+3 = 12... adjust: -1+6+3+6 = 14... use: 0+6+1+6 = 13. Final with Hobbit(-2/+2/0/+2) + Shire(0/0/+1/0): STR-2 DEX6 CON2 GRA5
    "base_stats": {"str": 0, "dex": 4, "con": 1, "gra": 3},
}
```

**Skill priorities:** `["archery", "stealth", "evasion", "will"]`
**Ability wishlist:** Fletchery (ARC 1), Ambush (ARC 4), Keen Eyes (ARC 5), Disguise (STL 0), Dodging (EVN 0)
**Unique bot behavior:** Find sling (starting gear includes one). Stand still to charge Steady Aim, then fire. Stealth between shots. SLING_PROFICIENCY + Steady Aim + Ambush = massive ranged damage against unwary targets. Bot must track `_steady_aim_ready` and wait one turn before firing.

---

### GREENWOOD_RANGER (Elf of Greenwood, Patient Stalker)

**Rationale:** Greenwood is the only Elf house not represented. Its Stealth affinity makes it the best stealth Elf. Combined with Patient Stalker (+3 stealth when stealthing with no adjacent alert enemies, double damage after 3+ stealth turns), this creates a patient ambush predator with Elf stats (+4 total).

```gdscript
"GREENWOOD_RANGER": {
    "archetype_id": "GREENWOOD_RANGER",
    "name": "SurvivalBot-GreenwoodRanger",
    "race": "Elf",
    "house": "Of Greenwood",
    "trait": "Patient Stalker",
    "gender": "female",
    # Cost: 1+3+3+6 = 13. Final with Elf(-1/+2/+1/+2) + Greenwood(0/+1/0/0): STR0 DEX5 CON3 GRA6
    "base_stats": {"str": 1, "dex": 2, "con": 2, "gra": 4},
}
```

**Skill priorities:** `["stealth", "archery", "evasion", "lore"]`
**Ability wishlist:** Disguise (STL 0), Assassination (STL 1), Fletchery (ARC 1), Ambush (ARC 4), Dodging (EVN 0), Song of the Trees (LOR 16)
**Unique bot behavior:** Patient Stalker requires 3+ consecutive turns in stealth before the double-damage proc. The bot must track stealth turn count and delay engagement until the proc is ready. Combine with BOW_PROFICIENCY for stealth archery. Song of Trees (+5 stealth) + Patient Stalker (+3 stealth) + Stealth Mode (+5) + Disguise (+stealth/3) creates an absurdly high stealth score.

---

### HOBBIT_BURGLAR (Hobbit of the Gamgees, Shadow Step)

**Rationale:** Gamgees house (Smithing affinity) + Shadow Step (teleport adjacent to visible unaware enemy) creates a unique burglar archetype focused on Light Fingers (steal from unwary), Pilfer (25% extra drops), and Shadow Step for repositioning. This tests the theft and item acquisition mechanics.

```gdscript
"HOBBIT_BURGLAR": {
    "archetype_id": "HOBBIT_BURGLAR",
    "name": "SurvivalBot-HobbitBurglar",
    "race": "Hobbit",
    "house": "Of the Gamgees",
    "trait": "Shadow Step",
    "gender": "male",
    # Cost: 1+6+3+3 = 13. Final with Hobbit(-2/+2/0/+2) + Gamgees(+1/0/0/0): STR0 DEX6 CON2 GRA4
    "base_stats": {"str": 1, "dex": 4, "con": 2, "gra": 2},
}
```

**Skill priorities:** `["stealth", "evasion", "hunting", "melee"]`
**Ability wishlist:** Disguise (STL 0), Assassination (STL 1), Light Fingers (STL 4), Pilfer (STL 9), Dodging (EVN 0), Alchemy (PER 4)
**Unique bot behavior:** Shadow Step to teleport near unwary monsters, use Light Fingers to steal, use Pilfer for extra drops on kills. Alchemy (PER 4) identifies all herbs/potions, combining with Gamgees Smithing affinity for a treasure-hunter playstyle. Track stolen items as a new telemetry counter.

---

### BANISHMENT_MAGE (Elf of Lothlorien, Song of Banishment)

**Rationale:** Tests the Banishment victory path. Song of Banishment trait grants the ability regardless of Lore level. The build invests heavily in Lore + Will to meet Banishment requirements (Lore >= 12, Will >= 10). This is the only archetype that would attempt the Banishment victory condition.

```gdscript
"BANISHMENT_MAGE": {
    "archetype_id": "BANISHMENT_MAGE",
    "name": "SurvivalBot-BanishmentMage",
    "race": "Elf",
    "house": "Of Lothlorien",
    "trait": "Song of Banishment",
    "gender": "male",
    # Cost: 0+0+3+10 = 13. Final with Elf(-1/+2/+1/+2) + Lothlorien(0/0/0/+1): STR-1 DEX2 CON3 GRA7
    "base_stats": {"str": 0, "dex": 0, "con": 2, "gra": 4},
}
```

**Skill priorities:** `["lore", "will", "evasion", "stealth"]`
**Ability wishlist:** Word of Command (LOR 0), Deep Memory (LOR 2), Song of Banishment (LOR 14), Lore of Sleep (LOR 10), Curse Breaking (WIL 0), Defy Death (WIL 4)
**Unique bot behavior:** Collect Rod of Istari pieces at depths 10, 15, 18. Track rod pieces as telemetry. When rod is assembled and Lore >= 12 + Will >= 10, navigate to Throne Room (depth 19-20) and attempt Banishment. If Banishment fails, fall back to Escape victory behavior (ascend with Ring + Key).

---

### SHIELD_WALL (Man of Gondor, Shield Brother)

**Rationale:** Shield Brother (+1 melee, adjacent enemies -1 evasion, halve incoming ranged damage with Blocking) is the quintessential defensive trait. Combined with Gondor's Melee affinity and a shield-focused equipment strategy, this tests the defensive melee playstyle. Replaces the WARRIOR as the "beginner melee build."

```gdscript
"SHIELD_WALL": {
    "archetype_id": "SHIELD_WALL",
    "name": "SurvivalBot-ShieldWall",
    "race": "Man",
    "house": "Of Gondor",
    "trait": "Shield Brother",
    "gender": "male",
    # Cost: 6+0+6+1 = 13. Final with Man(+1/0/+1/0) + Gondor(0/0/+1/0): STR4 DEX0 CON5 GRA1
    "base_stats": {"str": 3, "dex": 0, "con": 3, "gra": 1},
}
```

**Skill priorities:** `["melee", "evasion", "will", "hunting"]`
**Ability wishlist:** Blocking (EVN 1), Power (MEL 0), Crowd Fighting (EVN 3), Heavy Armour Use (EVN 7), Dodging (EVN 0), Defensive Stance (MEL 11)
**Unique bot behavior:** Always equip a shield (prioritize shields in item scoring). Stand still when enemies are adjacent (enables Blocking). Shield Brother's -1 evasion debuff to adjacent enemies stacks with combat abilities. The bot must track whether it has a shield equipped and modify behavior accordingly: shield equipped = stand and fight, no shield = mobile combat.

---

# SECTION 3: BOT INTELLIGENCE UPGRADE PLAN (v3)

## 3.1 Universal Upgrades (All Archetypes)

### 3.1.1 Corridor/Doorway Fighting

This is the single most important tactical skill in roguelikes. In Sil-Q, experienced players fight in corridors 80%+ of the time because it limits exposure to one adjacent monster.

**Implementation:**

```gdscript
# New constants
const CORRIDOR_FIGHT_BONUS: float = 0.8   # Weight for corridor tiles in combat positioning
const DOORWAY_FIGHT_BONUS: float = 1.0    # Highest-priority fight position

# New function: evaluate tile for combat positioning
func _tile_combat_score(pos: Vector2i) -> float:
    ## Score a tile for how good it is to fight on. Higher = better.
    if not _level or not _level.is_passable(pos):
        return -999.0
    var score: float = 0.0
    var adjacent_walls: int = 0
    var adjacent_passable: int = 0
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if dx == 0 and dy == 0:
                continue
            var adj: Vector2i = pos + Vector2i(dx, dy)
            if _level.is_passable(adj):
                adjacent_passable += 1
            else:
                adjacent_walls += 1
    # Corridors (2-3 passable neighbors) are great for fighting
    if adjacent_passable <= 3:
        score += CORRIDOR_FIGHT_BONUS * (8 - adjacent_passable)
    # Doorway detection: tile is a door or adjacent to a door tile
    var tile_type: int = _level.get_tile(pos)
    if tile_type == Level.Tile.DOOR_OPEN or tile_type == Level.Tile.DOOR_CLOSED:
        score += DOORWAY_FIGHT_BONUS
    # Check if any adjacent tile is a door
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue
            var adj_tile: int = _level.get_tile(pos + Vector2i(dx, dy))
            if adj_tile == Level.Tile.DOOR_OPEN or adj_tile == Level.Tile.DOOR_CLOSED:
                score += DOORWAY_FIGHT_BONUS * 0.5
    return score

# New function: retreat to best nearby fighting position
func _retreat_to_corridor() -> bool:
    ## When threatened, move to the nearest tile with the best combat score.
    var pp: Vector2i = _player.grid_position
    var best_pos: Vector2i = pp
    var best_score: float = _tile_combat_score(pp)
    # Search within 3 tiles
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            var candidate: Vector2i = pp + Vector2i(dx, dy)
            if not _level.is_passable(candidate):
                continue
            var dist: int = _get_chebyshev_distance(pp, candidate)
            if dist == 0 or dist > 3:
                continue
            var entity_at: Entity = _level.get_entity_at(candidate)
            if entity_at != null and entity_at != _player:
                continue
            var score: float = _tile_combat_score(candidate)
            # Penalize distance
            score -= float(dist) * 0.3
            if score > best_score:
                best_score = score
                best_pos = candidate
    if best_pos != pp:
        return _move_toward_target(best_pos)
    return false
```

**Integration into decision engine:** Insert corridor-retreat as Priority 0.5 (between emergency and flee):

```gdscript
# Priority 0.5: REPOSITION — move to corridor/doorway if in open room with threats
if vis_count > 0 and not _has_adjacent_monster():
    var current_score: float = _tile_combat_score(_player.grid_position)
    if current_score < 2.0:  # We're in an open area
        if _retreat_to_corridor():
            _total_corridor_repositions += 1
            return true
```

### 3.1.2 Threat Assessment

The bot currently treats all monsters equally. A Mirkwood Spider and Sauron get the same response. The bot needs to evaluate whether it can win a fight before engaging.

```gdscript
func _assess_threat(monster: Monster) -> float:
    ## Return a threat score. > 1.0 = dangerous, < 1.0 = manageable.
    if not is_instance_valid(monster):
        return 0.0
    var player_att: int = _player.get_total_attack_bonus(monster)
    var player_evn: int = _player.get_total_evasion(monster)
    var monster_att: int = monster.get_total_attack_bonus(_player)
    var monster_evn: int = monster.get_total_evasion(_player)
    # Rough win probability: (att - evn) differential
    var player_advantage: float = float(player_att - monster_evn)
    var monster_advantage: float = float(monster_att - player_evn)
    # HP ratio
    var hp_ratio: float = float(monster.max_health) / float(maxi(_player.current_health, 1))
    # Threat = how many hits to kill us vs how many to kill them
    var threat: float = (monster_advantage + 10.0) / (player_advantage + 10.0) * hp_ratio
    # Adjust for resistances and flags
    if monster.has_flag("NO_SLEEP"):
        threat *= 1.2  # Can't be neutralized by Lore of Sleep
    if monster.has_flag("NO_FEAR"):
        threat *= 1.1  # Can't be feared by Word of Command
    if monster.has_flag("UNIQUE"):
        threat *= 2.0  # Unique monsters are always dangerous
    return threat

func _should_fight(monster: Monster) -> bool:
    ## Decide whether to engage a monster or avoid it.
    var threat: float = _assess_threat(monster)
    match _archetype_id:
        "STEALTH_PURE":
            return threat < 0.3  # Almost never fight
        "STEALTH_ASSASSIN":
            return threat < 0.8 or monster.alertness < Constants.ALERTNESS_ALERT
        "TANK", "WARRIOR", "SHIELD_WALL":
            return threat < 2.0  # Fight most things
        "LORE_MAGE", "BANISHMENT_MAGE":
            return threat < 1.5  # Fight with ability support
        _:
            return threat < 1.2  # Default: moderate caution
```

### 3.1.3 Door Tactics

Doors are one of the most powerful tactical tools in roguelikes. Closing a door behind you breaks LOS, prevents pursuit (monsters cannot open doors in this build), and allows stealth resets.

```gdscript
func _try_close_door_behind() -> bool:
    ## After moving, close any open door we just passed through.
    if not _level or not _player:
        return false
    # Check if our previous position was a door tile (open)
    if _last_position == Vector2i(-1, -1):
        return false
    var tile: int = _level.get_tile(_last_position)
    if tile != Level.Tile.DOOR_OPEN:
        return false
    # Close it if a monster is chasing us
    if _has_visible_monster():
        _level.set_tile(_last_position, Level.Tile.DOOR_CLOSED)
        _player.add_noise(Constants.NOISE_DOOR)
        _total_doors_closed += 1
        return true
    # Stealth archetypes close doors proactively
    if _is_stealth_archetype():
        _level.set_tile(_last_position, Level.Tile.DOOR_CLOSED)
        _player.add_noise(Constants.NOISE_DOOR)
        _total_doors_closed += 1
        return true
    return false
```

**Note:** Door closing generates noise (NOISE_DOOR = 5), so stealth characters must weigh the LOS break against the noise cost. In practice, the LOS break is almost always worth it since noise 5 is modest compared to combat noise.

### 3.1.4 Smart Item Usage

The bot currently uses potions only for HP healing. It should use all consumable types strategically.

```gdscript
func _try_use_strategic_consumable() -> bool:
    ## Use consumables beyond basic healing.
    if not _player:
        return false
    for item in _player.inventory:
        if item == null or "tval" not in item:
            continue
        if item.tval == 75:  # Potion
            # Quaff unidentified potions when safe and at full HP
            if not item.get("identified", false) and not _has_visible_monster():
                if float(_player.current_health) / float(_player.max_health) > 0.9:
                    _use_consumable_item(item)
                    _total_consumables_used += 1
                    return true
        elif item.tval == 80:  # Herbs
            # Eat unidentified herbs when safe
            if not item.get("identified", false) and not _has_visible_monster():
                _use_consumable_item(item)
                _total_consumables_used += 1
                return true
    return false
```

### 3.1.5 Food/Hunger Management

The bot has no hunger management. The hunger system counts down per turn; starvation causes HP loss and death.

```gdscript
func _check_hunger() -> bool:
    ## Eat food if hungry. Returns true if action taken.
    if not _player or not "hunger" in _player:
        return false
    if _player.hunger > 800:  # Above HUNGER_HUNGRY threshold
        return false
    # Eat any food item
    for item in _player.inventory:
        if item == null or "tval" not in item:
            continue
        if item.tval == 80:  # Food/herbs
            _use_consumable_item(item)
            _total_food_eaten += 1
            return true
    return false
```

**Integration:** Add hunger check as Priority 0.1 (before all combat decisions):

```gdscript
# Priority 0.1: HUNGER — eat if hungry
if _check_hunger():
    return true
```

### 3.1.6 Exploration Efficiency

The bot currently explores 70% of each floor before descending. This is wasteful for builds that should descend quickly (stealth, ranger) and too aggressive for builds that need floor-clearing XP (warrior, tank).

```gdscript
func _get_archetype_explore_threshold() -> float:
    ## How much of the floor to explore before descending.
    match _archetype_id:
        "STEALTH_PURE":
            return 0.30  # Beeline for stairs
        "STEALTH_ASSASSIN", "STEALTH", "RANGER_STEALTH_ARCHER":
            return 0.40  # Quick but grab items
        "LORE_MAGE", "BANISHMENT_MAGE":
            return 0.60  # Deep Memory reveals map, so explore less manually
        "WARRIOR", "TANK", "SHIELD_WALL", "POLEARM_MASTER":
            return 0.80  # Clear floor for XP
        "SMITH", "ELF_SMITH":
            return 0.90  # Find forges and materials
        _:
            return 0.70
```

## 3.2 Per-Archetype Upgrades

### 3.2.1 WARRIOR: Aggressive Melee AI

```gdscript
func _warrior_combat_upgrade() -> bool:
    ## Warrior-specific: seek corridor fights, exploit Last Stand.
    var hp_pct: float = float(_player.current_health) / float(maxi(_player.max_health, 1))

    # Last Stand zone: 15-25% HP = fight AGGRESSIVELY
    if _player.trait_effect_id == "last_stand" and hp_pct < 0.25 and hp_pct > 0.10:
        # +3 attack/damage/evasion active -- press the advantage
        if _has_adjacent_monster():
            return _attack_adjacent_monster()
        if _has_visible_monster():
            var target: Monster = _get_nearest_visible_monster()
            return _move_toward_target(target.grid_position)

    # Follow-Through: after a kill, check for adjacent living enemies and attack them
    # (The game system handles this automatically, but the bot should not flee after a kill
    # if Follow-Through might trigger)

    return false
```

### 3.2.2 STEALTH_PURE: LOS-Aware Pathfinding

```gdscript
func _stealth_pure_pathfind_avoiding_los(target: Vector2i) -> bool:
    ## Navigate to target while avoiding all monster LOS cones.
    ## This is the core stealth-pure upgrade.
    if not _level or not _player:
        return _move_toward_target(target)

    var pp: Vector2i = _player.grid_position
    var monsters: Array[Monster] = _get_visible_monsters()

    # Build "danger map" of tiles in monster LOS
    # (Simplified: tiles within perception range of any alert monster)
    var danger_tiles: Dictionary = {}  # Vector2i -> float danger score
    for m in monsters:
        if m.alertness >= Constants.ALERTNESS_ALERT:
            # Alert monsters have full perception range
            for dx in range(-8, 9):
                for dy in range(-8, 9):
                    var tile: Vector2i = m.grid_position + Vector2i(dx, dy)
                    if _level.has_los_to(m.grid_position, tile):
                        var dist: float = float(_get_chebyshev_distance(m.grid_position, tile))
                        danger_tiles[tile] = maxf(danger_tiles.get(tile, 0.0), 8.0 - dist)

    # Find adjacent tile that minimizes danger and moves toward target
    var best_dir: Vector2i = Vector2i.ZERO
    var best_score: float = -999.0
    for dir in [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,-1),Vector2i(-1,0),Vector2i(1,0),Vector2i(-1,1),Vector2i(0,1),Vector2i(1,1)]:
        var candidate: Vector2i = pp + dir
        if not _level.is_passable(candidate):
            continue
        var entity_at: Entity = _level.get_entity_at(candidate)
        if entity_at != null and entity_at != _player:
            continue
        var danger: float = danger_tiles.get(candidate, 0.0)
        var dist_to_target: float = float(_get_chebyshev_distance(candidate, target))
        var score: float = -danger * 3.0 - dist_to_target
        if score > best_score:
            best_score = score
            best_dir = dir

    if best_dir != Vector2i.ZERO:
        return _move_in_direction(best_dir)
    return _move_toward_target(target)
```

### 3.2.3 STEALTH_ASSASSIN: Kill Loop

The assassination loop is: stealth -> approach -> check alertness -> if sleeping/unwary: Throat Slit or melee with Assassination bonus -> check Fade -> if Fade active: invisible for 2 turns, reposition -> repeat.

```gdscript
func _stealth_assassin_decide_v3(hp_pct: float, adj_count: int, vis_count: int) -> bool:
    ## v3 Assassin: proper kill loop with alertness tracking.

    # Emergency handling (unchanged)
    if hp_pct < FLEE_HP_PCT:
        # ... same as current ...
        pass

    # Adjacent unwary/sleeping monster: ASSASSINATE
    if adj_count > 0:
        var target: Monster = _get_best_assassination_target()
        if target and target.alertness < Constants.ALERTNESS_ALERT:
            # This is an assassination attack
            _total_stealth_kills += 1  # INCREMENT THE COUNTER
            _try_start_combat_song()
            return _attack_adjacent_monster()
        elif target:
            # Alert target -- fight or flee based on threat
            if _should_fight(target):
                return _attack_adjacent_monster()
            else:
                return _try_multi_step_flee()

    # Visible unwary monster: APPROACH
    if vis_count > 0 and _player.stealth_mode:
        var target: Monster = _get_best_assassination_target_visible()
        if target and target.alertness < Constants.ALERTNESS_ALERT:
            var dist: int = _get_chebyshev_distance(_player.grid_position, target.grid_position)
            if dist <= 6:
                return _move_toward_target(target.grid_position)

    # Visible ALERT monster while stealthed: break LOS and wait
    if vis_count > 0 and _player.stealth_mode:
        _total_detections += 1  # They see us
        # Close door if possible
        _try_close_door_behind()
        # Move away to break LOS
        return _move_avoiding_monsters()

    # Visible monster, not stealthed: flee to re-stealth
    if vis_count > 0 and not _player.stealth_mode:
        return _try_multi_step_flee()  # Flee -> _manage_stealth will re-enable

    # Safe: explore, loot, rest
    # ... standard safe-mode behavior ...
    return false

func _get_best_assassination_target() -> Monster:
    ## Return the best adjacent assassination target (lowest alertness, then lowest HP).
    var best: Monster = null
    var best_alertness: int = 999
    var pp: Vector2i = _player.grid_position
    for entity in _level.entities:
        if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
            continue
        var dist: int = _get_chebyshev_distance(pp, entity.grid_position)
        if dist > 1:
            continue
        var mon: Monster = entity as Monster
        if mon.alertness < best_alertness:
            best_alertness = mon.alertness
            best = mon
        elif mon.alertness == best_alertness and best != null and mon.current_health < best.current_health:
            best = mon
    return best
```

### 3.2.4 LORE_MAGE: Voice Budget Optimization

```gdscript
func _lore_mage_voice_budget() -> Dictionary:
    ## Plan voice spending for the current floor.
    var voice: int = _player.voice_charges
    var max_voice: int = _player.max_voice
    var budget: Dictionary = {
        "emergency_reserve": int(max_voice * 0.20),  # 20% for Word of Command emergencies
        "exploration_song": int(max_voice * 0.30),    # 30% for Song of Trees/Freedom
        "offensive": int(max_voice * 0.30),            # 30% for Lore of Sleep, WoC
        "deep_memory": int(max_voice * 0.10),          # 10% for map reveals (1-2 uses)
        "surplus": int(max_voice * 0.10),              # 10% buffer
    }
    return budget

func _lore_mage_decide_ability(vis_count: int, voice_pct: float) -> bool:
    ## Smarter ability selection for Lore Mage.
    if not _ability_system:
        return false

    var budget: Dictionary = _lore_mage_voice_budget()
    var voice: int = _player.voice_charges

    # Emergency: Word of Command when overwhelmed (2+ adjacent)
    if _count_adjacent_monsters() >= 2 and voice >= 3:
        if _try_use_ability(140):  # Word of Command
            _total_word_of_command += 1
            return true

    # Pre-emptive: Lore of Sleep on strongest approaching monster
    if vis_count >= 1 and not _has_adjacent_monster():
        if voice > budget["emergency_reserve"] + 3:
            var target: Monster = _get_closest_visible_monster()
            if target:
                var dist: int = _get_chebyshev_distance(_player.grid_position, target.grid_position)
                if dist >= 2 and dist <= 5:
                    if _try_use_ability_on_target(150, target):  # Lore of Sleep
                        _total_lore_of_sleep += 1
                        return true

    # Utility: Deep Memory when stairs unknown (max 2 uses per floor)
    if _total_deep_memory < (_current_depth * 2):
        var stairs: Vector2i = _level.find_stairs_down()
        if stairs == Vector2i(-1, -1) or not _level.is_explored(stairs):
            if voice > budget["emergency_reserve"] + 2:
                if _try_use_ability(142):  # Deep Memory
                    _total_deep_memory += 1
                    return true

    return false
```

### 3.2.5 RANGER variants: Kiting Corridors

```gdscript
func _ranger_kite_in_corridor() -> bool:
    ## Optimal kiting: find a corridor, fire down it, retreat.
    var visible_monsters: Array[Monster] = _get_visible_monsters()
    if visible_monsters.is_empty():
        return false
    var pp: Vector2i = _player.grid_position
    var target: Monster = visible_monsters[0]
    var dist: int = _get_chebyshev_distance(pp, target.grid_position)

    # If we're in a corridor and target is approaching, shoot then retreat
    var combat_score: float = _tile_combat_score(pp)
    if combat_score > 3.0 and dist >= 2 and dist <= 6:
        # We're in a good corridor position
        if _player.can_fire_ranged() and _level.has_los_to(pp, target.grid_position):
            if _player.consume_arrow():
                _player.attacked_this_turn = true
                _player.ranged_attack(target, dist)
                _player.consume_energy()
                if _turn_system:
                    _turn_system._after_player_action()
                _total_ranged_attacks += 1
                _total_kite_shots += 1
                if not is_instance_valid(target) or not target.is_alive:
                    _floor_stats["monsters_killed"] += 1
                    _total_kills += 1
                return true

    # Not in a corridor -- retreat to one while maintaining range
    if dist < KITE_MIN_RANGE:
        return _retreat_to_corridor()

    return false
```

### 3.2.6 SMITH: Material Hoarding and Forge Planning

```gdscript
func _smith_should_seek_materials() -> bool:
    ## Check if the smith needs smithing materials.
    var material_count: int = 0
    for item in _player.inventory:
        if item == null:
            continue
        var name: String = item.get("name", "").to_lower()
        if "mithril" in name or "fragment" in name or "ore" in name or "metal" in name or "salvage" in name or "shard" in name or "remnant" in name:
            material_count += 1
    return material_count < 2  # Need at least 2 for most recipes

func _smith_material_item_score(item_data: Variant) -> int:
    ## Score an item for smithing material value. Higher = more valuable to pick up.
    if item_data == null or "name" not in item_data:
        return 0
    var name: String = item_data.name.to_lower()
    if "mithril" in name:
        return 20
    if "fragment" in name or "shard" in name:
        return 15
    if "ore" in name or "metal" in name:
        return 10
    if "salvage" in name or "remnant" in name:
        return 8
    return 0
```

### 3.2.7 TANK: Intentional Doorway Fighting

```gdscript
func _tank_doorway_decide() -> bool:
    ## TANK: find a doorway and stand in it.
    if not _has_visible_monster():
        return false

    var pp: Vector2i = _player.grid_position
    var combat_score: float = _tile_combat_score(pp)

    # Already in a great position? Stand and fight.
    if combat_score >= 4.0 and _has_adjacent_monster():
        # Blocking requires standing still. Don't move.
        return _attack_adjacent_monster()

    # Find nearest doorway and stand in it
    var best_door: Vector2i = Vector2i(-1, -1)
    var best_dist: int = 999
    for dx in range(-5, 6):
        for dy in range(-5, 6):
            var candidate: Vector2i = pp + Vector2i(dx, dy)
            var tile: int = _level.get_tile(candidate)
            if tile == Level.Tile.DOOR_OPEN or tile == Level.Tile.DOOR_CLOSED:
                var dist: int = _get_chebyshev_distance(pp, candidate)
                if dist < best_dist and dist > 0:
                    best_dist = dist
                    best_door = candidate

    if best_door != Vector2i(-1, -1) and best_dist <= 5:
        return _move_toward_target(best_door)

    # No doorway? Find a corridor instead.
    return _retreat_to_corridor()
```

## 3.3 Telemetry Fixes

### 3.3.1 Wire Up Existing Counters

The following counters are declared but never incremented:

**`_total_stealth_kills`** -- Increment when killing a monster whose alertness < ALERTNESS_ALERT:

```gdscript
# In _attack_adjacent_monster(), after the kill check:
if not is_instance_valid(monster) or not monster.is_alive:
    _floor_stats["monsters_killed"] += 1
    _total_kills += 1
    # NEW: track stealth kills
    if _was_monster_unwary:  # Set before the attack
        _total_stealth_kills += 1
```

Add pre-attack alertness capture:

```gdscript
var _was_monster_unwary: bool = false

func _attack_adjacent_monster() -> bool:
    var monster: Monster = _get_nearest_adjacent_monster()
    if not monster:
        return false
    # Capture alertness BEFORE the attack (combat noise will change it)
    _was_monster_unwary = monster.alertness < Constants.ALERTNESS_ALERT
    # ... rest of attack logic ...
```

**`_total_detections`** -- Increment when a monster transitions from unwary to alert while the player is stealthed. This requires per-turn tracking of monster alertness states:

```gdscript
var _monster_alertness_cache: Dictionary = {}  # entity_id -> previous alertness

func _update_detection_tracking() -> void:
    ## Call at start of each turn to detect alertness transitions.
    if not _level or not _player or not _player.stealth_mode:
        _monster_alertness_cache.clear()
        return
    for entity in _level.entities:
        if not is_instance_valid(entity) or not entity is Monster or not entity.is_alive:
            continue
        var mon: Monster = entity as Monster
        var eid: int = mon.get_instance_id()
        var prev_alertness: int = _monster_alertness_cache.get(eid, mon.alertness)
        if prev_alertness < Constants.ALERTNESS_ALERT and mon.alertness >= Constants.ALERTNESS_ALERT:
            _total_detections += 1
        _monster_alertness_cache[eid] = mon.alertness
```

**`_total_forge_successes`** -- Increment inside `_try_use_forge()` on successful forge:

```gdscript
# In the success branch of _try_use_forge():
_total_forge_successes += 1  # Already increments _total_forges_used, add this too
```

### 3.3.2 New Telemetry Counters

Add these counters to the telemetry block:

```gdscript
# v3 telemetry
var _total_corridor_fights: int = 0          # Fights in tiles with combat_score >= 3.0
var _total_corridor_repositions: int = 0     # Times bot moved to a corridor for combat
var _total_doorway_fights: int = 0           # Fights on/adjacent to door tiles
var _total_doors_closed: int = 0             # Doors closed for tactical advantage
var _total_threat_assessments: int = 0       # Times _assess_threat was called
var _total_threats_avoided: int = 0          # Times bot fled from assessed-dangerous monster
var _total_food_eaten: int = 0               # Food items consumed for hunger
var _total_last_stand_turns: int = 0         # Turns spent below 25% HP with Last Stand active
var _total_arrows_remaining: int = 0         # Arrows at time of death
var _total_materials_collected: int = 0      # Smithing materials picked up
var _total_assassination_attacks: int = 0    # Attacks against unwary targets
var _total_throat_slits: int = 0             # Throat Slit instant kills
var _total_song_switches: int = 0            # Times active song was changed
var _total_voice_at_death: int = 0           # Voice charges remaining when dying
var _total_nimble_striker_procs: int = 0     # Nimble Striker free moves
var _total_patient_stalker_procs: int = 0    # Patient Stalker double-damage attacks
var _total_steady_aim_procs: int = 0         # Steady Aim bonus shots
var _total_hobbit_luck_saves: int = 0        # Hobbit Luck rerolls triggered
var _total_abilities_by_id: Dictionary = {}  # {ability_id: use_count}
```

### 3.3.3 Per-Ability Usage Tracking

Replace the flat `_total_abilities_used` with per-ability tracking:

```gdscript
func _track_ability_use(ability_id: int) -> void:
    _total_abilities_used += 1
    if not _total_abilities_by_id.has(ability_id):
        _total_abilities_by_id[ability_id] = 0
    _total_abilities_by_id[ability_id] += 1
```

Add `_total_abilities_by_id` to the JSON output in `_finish_run()`.

---

# SECTION 4: EXPERIMENT DESIGN

## 4.1 Run Configuration

### Sample Size

- **40 runs per archetype** (up from 20-50)
- **18 archetypes** (10 existing + 8 new)
- **Total: 720 runs per experiment**
- At 4x parallelism, estimated wall time: ~90 minutes per experiment

### Why 40 Runs

At a 0% win rate, any sample size confirms 0%. The goal is to produce non-zero win rates with v3 bots, at which point:
- 40 runs gives 95% CI of +/- 15.5% for a 10% win rate
- 40 runs gives 95% CI of +/- 9.8% for a 5% win rate
- For depth distribution: 40 runs gives meaningful histogram bins (2-8 runs per bin for a 5-floor spread)

If v3 bots achieve > 5% win rates, increase to 100 runs per archetype (1,800 total) for tighter confidence intervals.

### Difficulty Modes

Run each experiment on two difficulty modes:
- **Normal**: Baseline comparison against v2
- **Easy**: Ceiling test (if bots cannot win on Easy, the bot AI is still fundamentally broken)

### Deterministic Seeding

Use seeds 1000-1039 for each archetype (same seeds for v2 and v3 comparison):

```bash
for archetype in WARRIOR STEALTH LORE_MAGE RANGER TANK SMITH STEALTH_PURE STEALTH_ASSASSIN RANGER_MARKSMAN RANGER_STEALTH_ARCHER POLEARM_MASTER ELF_SMITH WILL_TANK HOBBIT_SNIPER GREENWOOD_RANGER HOBBIT_BURGLAR BANISHMENT_MAGE SHIELD_WALL; do
    for i in $(seq 0 39); do
        seed=$((1000 + i))
        echo "$archetype $i $seed"
    done
done | xargs -P4 -I{} bash -c 'read arch idx seed <<< "{}"; timeout 120 /Applications/Godot.app/Contents/MacOS/Godot --path . --headless --script res://test_runner.gd -- --bot-only --archetype "$arch" --run "$idx" --seed "$seed" > "bot_results/${arch}_${idx}.log" 2>&1'
```

## 4.2 Metrics to Compare Against v2 Baseline

### Primary Metrics (Statistical Tests)

| Metric | v2 Baseline | v3 Target | Test |
|--------|-------------|-----------|------|
| Win rate | 0.0% | > 1% on Normal, > 5% on Easy | Fisher exact test (p < 0.05) |
| Mean depth | 1.8 | > 3.0 | Two-sample t-test (p < 0.05) |
| Max depth | 6 | > 10 | Mann-Whitney U (ordinal) |
| Floor 1 survival | 38-76% | > 80% | Chi-square (p < 0.05) |
| Floor 3 survival | 16-46% | > 40% | Chi-square |
| Floor 5 survival | 0-6% | > 15% | Fisher exact |

### Secondary Metrics (Descriptive)

| Metric | What It Tells Us |
|--------|-----------------|
| Avg kills per run | Combat effectiveness |
| Stealth kills (v3 only) | Assassination loop working |
| Detections (v3 only) | Stealth vs detection balance |
| Corridor fights (v3 only) | Positioning AI working |
| Doors closed (v3 only) | Tactical door use |
| Voice at death | Whether casters are spending voice or dying with full pools |
| Ranged shots per run | Whether archery is being used |
| Forge successes per run | Whether smithing is testable |
| Rest turns per run | Whether resting is appropriately balanced |

### Per-Archetype Metrics

For each archetype, compute:
1. **Survival curve**: Percentage alive at each floor (Kaplan-Meier estimator)
2. **DPS estimate**: (total kills * avg monster HP) / total turns alive
3. **Healing efficiency**: total healing / total damage taken
4. **System engagement**: percentage of archetype-specific abilities actually used (stealth kills for assassin, ranged shots for ranger, forges for smith)

## 4.3 Statistical Methodology

### Confidence Intervals

For proportions (win rate, survival rate): Wilson score interval with continuity correction.

```python
from scipy.stats import binom
def wilson_ci(successes, trials, alpha=0.05):
    """Wilson score interval for binomial proportion."""
    z = 1.96  # 95% CI
    p_hat = successes / trials
    denominator = 1 + z**2 / trials
    center = (p_hat + z**2 / (2 * trials)) / denominator
    half_width = z * ((p_hat * (1 - p_hat) / trials + z**2 / (4 * trials**2)) ** 0.5) / denominator
    return (max(0, center - half_width), min(1, center + half_width))
```

### Significance Tests

- **Win rate improvement**: Fisher exact test (small counts expected)
- **Mean depth improvement**: Welch's t-test (unequal variances expected)
- **Survival curves**: Log-rank test between v2 and v3 for each archetype
- **Multiple comparison correction**: Bonferroni correction across 18 archetypes (alpha = 0.05/18 = 0.0028)

### Effect Size

Report Cohen's d for depth comparisons:
- d = 0.2: small (detectable but not meaningful)
- d = 0.5: medium (clearly better)
- d = 0.8: large (dramatically better)

Expected v3 effect size: d >= 0.5 for corridor-fighting upgrade alone, based on the estimate that 40-60% of bot deaths are from being surrounded in open rooms.

## 4.4 Expected Outcomes and Interpretations

### Scenario A: v3 Normal Win Rate > 0%, < 5%

**Interpretation:** Bot intelligence improvements are working. The game's difficulty is in the correct range for a roguelike. The floor 1-3 kill zone is a skill check, not a design flaw.

**Next steps:** Focus on individual archetype tuning. Identify which archetypes benefit most from corridor fighting (expected: WARRIOR, TANK). Run targeted experiments on Easy difficulty to validate the upper bound.

### Scenario B: v3 Normal Win Rate >= 5%

**Interpretation:** The game may be easier than intended. The v2 0% win rate was primarily a bot intelligence problem, not a balance problem.

**Next steps:** Consider increasing monster stats on floors 1-3 by 10-20%. Run Hard and Ironman difficulty experiments. The game's projected 40-75% human win rate may be accurate.

### Scenario C: v3 Normal Win Rate = 0%, Mean Depth < 3.0

**Interpretation:** The v3 improvements are insufficient, OR the floor 1-3 difficulty is genuinely overtuned. Need to differentiate by checking Easy difficulty results.

**If Easy win rate > 0%:** Floor 1-3 Normal is overtuned. Reduce floor 1-2 monster stats.
**If Easy win rate = 0%:** Bot is still too stupid. Need v4 with multi-turn planning (retreat sequences, buff-before-engage). Consider implementing a simple minimax search for tactical combat.

### Scenario D: Archetype Divergence > 20 Percentage Points

**Interpretation:** Some playstyles are dramatically easier/harder than others. In Sil-Q, the spread between easiest (Noldor melee) and hardest (Sindar stealth) is approximately 3x in win rate. A spread of 20+ percentage points suggests a balance problem.

**Next steps:** Nerf the overperforming archetype's core mechanic or buff the underperforming one. The most likely imbalance: LORE_MAGE continues to outperform due to Word of Command being overpowered.

---

## APPENDIX: Implementation Priority

| Priority | Task | Impact | Effort |
|----------|------|--------|--------|
| **P0** | Wire up `_total_stealth_kills` and `_total_detections` | Fixes the core telemetry blind spot | 1 hour |
| **P0** | Fix Song of Trees ability ID bug (15 -> 16) in stealth wishlists | Wrong song being learned | 5 minutes |
| **P0** | Remove Song of Aule from SMITH wishlist (unreachable at GRA 0) | Wasted ability slot | 5 minutes |
| **P1** | Implement corridor/doorway fighting (`_tile_combat_score`, `_retreat_to_corridor`) | Largest expected survival improvement | 4 hours |
| **P1** | Implement threat assessment (`_assess_threat`, `_should_fight`) | Prevents suicidal engagements | 2 hours |
| **P1** | Implement door-closing tactics (`_try_close_door_behind`) | Critical for stealth resets | 1 hour |
| **P1** | Fix STEALTH_ASSASSIN to track and exploit monster alertness | Enables assassination loop | 3 hours |
| **P1** | Fix `_manage_stealth()` for RANGER archetypes (keep stealth ON with visible monsters) | Currently drops stealth when it should not | 30 minutes |
| **P2** | Add hunger management (`_check_hunger`) | Prevents starvation deaths | 1 hour |
| **P2** | Implement all 8 new archetypes in archetype_configs.gd | Expands coverage to all races/houses | 2 hours |
| **P2** | Per-archetype exploration thresholds | Stealth beelines, warriors clear | 30 minutes |
| **P2** | Add per-ability-ID tracking to telemetry | Fine-grained ability analysis | 1 hour |
| **P3** | Implement BANISHMENT_MAGE decision logic (Rod collection, Banishment attempt) | Tests second victory condition | 4 hours |
| **P3** | Implement Patient Stalker turn tracking | Tests the trait's 3-turn stealth proc | 2 hours |
| **P3** | Implement Steady Aim awareness for HOBBIT_SNIPER | Tests the stand-then-shoot loop | 1 hour |
| **P3** | Implement material hoarding for SMITH variants | Tests forge material economy | 2 hours |

**Total estimated effort:** 25-30 hours for full v3 implementation + new archetypes.

---

*This plan is implementable by a developer reading it. All function names reference existing codebase patterns. All ability IDs reference `scripts/core/constants.gd` enums and `data/ability.txt` entries. GDScript pseudocode follows the project's coding style.*
