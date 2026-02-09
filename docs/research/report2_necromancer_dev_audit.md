# Report 2: Necromancer-Dev Branch Enchantment Audit

## Executive Summary

The Necromancer C codebase is a fork of SilQ 1.5.0, re-themed from First Age Angband to Third Age Dol Guldur. Three copies exist on disk (`necromancer-linux-port`, `necromancer-master`, `necromancer-master-2-3-2026`); all share **identical data files** and nearly identical source code. The only source differences between linux-port and master are tile rendering additions (64x64 tileset system); master and master-2-3-2026 are source-identical (only compiled binaries differ).

Changes fall into five categories:
1. **Thematic renames** (First Age -> Third Age names)
2. **New enchantment types** (7 new ego item categories)
3. **New items** (wands, herbs, broken smithing materials, discovery items)
4. **Ability system overhaul** (melee, stealth, lore/song replacements)
5. **Artifact overhaul** (complete replacement of all ~80 artifacts)

---

## 1. Version Comparison: Three Necromancer Copies

### Summary Table

| Aspect | necromancer-linux-port | necromancer-master | necromancer-master-2-3-2026 |
|--------|----------------------|-------------------|---------------------------|
| Git repo | Yes (b65ce6c) | Yes (0d8d132) | No (snapshot copy) |
| Data files (lib/edit/) | Identical | Identical | Identical |
| C source files | Baseline | +tileset code, debug logging | Same as master |
| Extra files | x86_64 binary | Cocoa tile renderer (4 files), hardfork/, scripts/ | Same as master + x86_64 binary |
| Latest commit | "Add tile rendering fix prompt" | "fix: 64x64 tileset rendering" | N/A |

### Source Code Differences (linux-port vs master)

Only 4 C source files differ, all related to tile rendering:

1. **`cave.c`** -- Added `case GRAPHICS_NECROMANCER:` to 4 switch statements for the new tileset
2. **`defines.h`** -- Added comment to `GRAPHICS_NECROMANCER` constant
3. **`object1.c`** -- Added debug logging to `reset_visuals()` (temporary)
4. **`spells1.c`** -- Extended `GF_LIGHT` handling to include `GRAPHICS_NECROMANCER`

Master also adds 4 new Cocoa files: `NecroGameBridge`, `NecroMapViewport`, `NecroTestView`, `NecroTileRenderer` (all `.h/.m/.o`).

**Conclusion: All three are the same codebase. `necromancer-linux-port` is the most canonical (oldest, fewest debug artifacts). Use it as the reference.**

---

## 2. Necromancer Data Files vs SilQ: object.txt

### Item Renames (Thematic)

Every base item has been renamed from generic SilQ names to Third-Age-appropriate names. **No stat changes** were made to base items -- only names and descriptions.

| SilQ Name | Necromancer Name | Stats Changed? |
|-----------|-----------------|----------------|
| Lesser Jewel | Elven Light | No |
| Robe | Wanderer's Robe | No |
| Leather Armour | Ranger Leathers | No |
| Studded Leather | Scout's Armor | No |
| Galvorn Armour | Shadow-steel Armor | No |
| Mail Corslet | Gondor Corslet | No |
| Hauberk | Dwarven Hauberk | No |
| Round Shield | Buckler | No |
| Kite Shield | Tower Shield | No |
| Dagger | Ranger's Knife | No |
| Curved Sword | Orc-blade | No |
| Shortsword | Woodland Blade | No |
| Bastard Sword | Rohirrim Blade | No |
| Greatsword | Numenorean Blade | No |
| Mithril Longsword | Mithril Sword | No |
| Mithril Greatsword | Mithril Great-blade | No |
| Spear | Hunting Spear | No |
| Great Spear | Tower Guard Spear | No |
| Glaive | Morgul Glaive | No |
| Hand Axe | Woodsman's Axe | No |
| Battle Axe | Dwarven War-axe | No |
| Great Axe | Erebor Great-axe | No |
| Quarterstaff | Oak Staff | No |
| War Hammer | Dwarven Hammer | No |
| Shovel | Miner's Spade | No |
| Mattock | Dwarf Mattock | No |
| Helm | Iron Helm | No |
| Great Helm | Tower Helm | No |
| Cloak | Traveler's Cloak | No |
| Shortbow | Silvan Bow | No |
| Pair of Boots | Traveler's Boots | No |
| Pair of Greaves | Iron Greaves | No |
| Set of Gloves | Leather Gloves | No |
| Set of Gauntlets | Iron Gauntlets | No |
| Feanorian Lamp | Jewel-lamp | No |
| Silmaril | Star-glass | No |
| Rusty Helm | Rusted Helm | No |
| Pair of Shabby Boots | Worn Boots | No |
| Broken Shield | Shattered Shield | No |
| Dark Bread | Travel Bread | No |
| Bauglir's Vanguard | the Shadow's Vanguard | No |

### Consumable Renames

| SilQ Name | Necromancer Name | Stat Change |
|-----------|-----------------|-------------|
| Potion of Healing | Cordial of the Wise | No |
| Potion of Strength | Draught of Might | No |
| Potion of Dexterity | Nimble-wine | No |
| Potion of Constitution | Hardy-brew | No |
| Potion of Grace | Starlight Elixir | No |
| Herb of Rage | Orc-rage Mushroom | No |
| Herb of Sustenance | Waymeal | No |
| Herb of Healing | Healer's Herb | No |
| Horn of Warning | Horn of Challenge | **YES** (see below) |

### Consumable Stat Changes

**Horn of Challenge** (was Horn of Warning):
- Changed allocation from `A:7/12` to `A:7/6`
- Changed cost from 0 to 100
- Changed description to: "battle-fury (+1 Str/Con, -1 Dex/Gra) for 20 turns"
- **This is a completely new mechanic** -- SilQ's Warning horn just alerts enemies

### New Items Added to object.txt

#### Wands (TV_WAND = tval 56) -- ENTIRELY NEW ITEM TYPE

| ID | Name | Effect | Depth/Charges |
|----|------|--------|---------------|
| 220 | Wand of Frost | 2d4 cold damage, may slow | D6, 5-20 charges |
| 221 | Wand of Fire | 2d5 fire damage | D7, 4-16 charges |
| 222 | Wand of Slowing | Slows target | D5, 4-12 charges |
| 223 | Wand of Light | 1d6 damage to light-sensitive, illuminates | D4, 6-24 charges |
| 224 | Wand of Fear | Causes flee (Will save) | D8, 3-12 charges |
| 225 | Wand of Sleep | Puts target to sleep (Will save) | D9, 2-10 charges |

Wands required new C code in: `object2.c` (charge system), `cmd3.c` (use command), `cmd6.c` (targeting), `use-obj.c` (effects), `defines.h` (TV_WAND=56, sval constants), `types.h`, `birth.c`, `squelch.c`, `object1.c` (flavor assignment).

#### Flute of the Fairy (Horn slot)

| ID | Name | Effect |
|----|------|--------|
| 251 | Flute of the Fairy | Concealing mists in radius, blocks LoS. Quieter than horns. |

#### Potion of Shadows

| ID | Name | Effect |
|----|------|--------|
| 324 | Potion of Shadows | Temporary invisibility, dims light for 15d4 turns |

This is entirely new -- SilQ has no invisibility potion.

#### New Food Items

| ID | Name | Effect |
|----|------|--------|
| 390 | Athelas | Cures poison/fear/confusion/hallucination, heals 25% HP, cures shadow-sickness |
| 403 | Cake of Cram | 2000 turns nourishment |
| 404 | Pipe-weed | Cures fear, +3 Grace for 30 turns, creates smoke |

#### Improved Herbs (Alchemy Crafting System)

| ID | Name | Effect | Recipe |
|----|------|--------|--------|
| 412 | Concentrated Healer's Herb | Heals 75% HP | 2x Healer's Herb + Alchemy |
| 413 | Potent Athelas | Full cure + 50% HP | 2x Athelas + Alchemy |
| 414 | Concentrated Waymeal | 4000 turns nourishment | 2x Waymeal + Alchemy |
| 415 | Potent Orc-rage Mushroom | +2 Str/Con/-2 Dex/Gra for 15d4 turns | 2x Orc-rage + Alchemy |

**These require a new Alchemy crafting system that doesn't exist in SilQ.**

#### Broken Items for Smithing (Necromancer-exclusive)

| ID | Name | Type | Depth | Purpose |
|----|------|------|-------|---------|
| 491 | Broken Glowing Weapon | TVAL 23 sval 1 | D3+ | Reforge into enchanted weapon |
| 492 | Shattered Elven Mail | TVAL 37 sval 1 | D4+ | Reforge into enchanted armor |
| 493 | Broken Strange Weapon | TVAL 23 sval 2 | D8+ | Reclaim/Masterwork artifacts |
| 494 | Twisted Shadow-plate | TVAL 37 sval 2 | D10+ | Reclaim/Masterwork artifacts |
| 495 | Broken Strange Jewelry | TVAL 45 sval 99 | D12+ | Reclaim/Masterwork artifacts |

All have `DAMAGED | NO_SMITHING | EASY_KNOW` flags. C code in `object2.c` (`place_forge_items()`) spawns 3 broken items near each forge: Glowing before depth 10, Strange after.

#### Discovery Items (Stealth XP System -- Necromancer-exclusive)

| ID Range | Name | Count | XP Each | Description |
|----------|------|-------|---------|-------------|
| 500-507 | Thrain's Memory | 8 | 150 | Blue wisps, D6-D19 |
| 510-515 | Shadow Fragment | 6 | 200 | Dark crystals, D4-D20 |
| 520-526 | Ancient Glyph | 7 | 75 | Wall inscriptions, D2-D19 |
| 530-533 | Palantir Shard | 4 | 500 | Seeing-stone fragments, rare |
| 540-544 | Erebor Relic | 5 | 100 | Dwarven treasures, D4-D16 |
| 550-557 | Dol Guldur Record | 8 | 500 | Prisoner accounts, orc reports |

**Total: 38 discovery items granting combat-free XP for stealth builds.**

---

## 3. Necromancer Data Files vs SilQ: special.txt (Enchantments/Ego Items)

### Thematic Renames (No Mechanical Changes)

| SilQ Enchantment | Necromancer Enchantment | Slot | Stats Changed? |
|-----------------|------------------------|------|----------------|
| of Brethil | of the Woodmen | Armor | No |
| of Ladros | of Dale | Gauntlets/Greaves | No |
| of Cuivienen | of Rivendell | Daggers | No |
| of Nargothrond | of Dragon-bane | Swords/Polearms | No |
| of Hador's House | of the Edain | Heavy weapons | No |
| of the Feanorians | of the Noldor | Swords | No |
| of the Vanyar | of the Eorlingas | Spears | **YES** |
| of Mithrim | of Lothlórien | Quarterstaves | No |
| of the Helcaraxe | of the North | Quarterstaves | No |
| of Udun | of Shadow | Curved/Great swords | **YES** |
| of Thangorodrim | of the Deeps | Warhammers/swords | No |
| of Black Iron | of Mordor | Curved swords/axes | No |
| of the Scarlet Heart | of the Tower | Cloaks | No |
| of the Golden Flower | of the Golden Wood | Cloaks | No |
| of Blackened Yew | of Black Yew | Longbows | **YES** |
| of Lammoth | of the Wild | Shortbows | No |
| of Falas | of the Grey Havens | Bows | No |
| of the Falmari | of the Galadhrim | Bows | No |
| of Lorellin | of Healing | Gloves | No |
| of the Ironfists | of the Iron Hills | Gloves | No |

### Enchantments with Mechanical Changes

1. **of the Eorlingas** (was of the Vanyar, spears):
   - SilQ: `F:GRA | LIGHT` -- Gives Grace and Light
   - Necromancer: `F:STR | RES_FEAR` -- Gives Strength and Fear Resistance
   - **Major change**: Completely different bonuses. Shifted from elven grace theme to Rohirrim courage theme.

2. **of Shadow** (was of Udun, curved/great swords):
   - SilQ: `F:BRAND_FIRE | CUMBERSOME` -- Fire brand, cumbersome
   - Necromancer: `F:VAMPIRIC | DARKNESS | HUNGER` -- Vampiric, darkness, hunger
   - **Major change**: Completely different mechanic. Changed from fire brand to vampiric/darkness.

3. **of Black Yew** (was of Blackened Yew, longbows):
   - SilQ: `C:0:0:1:0:0:0:0` -- No pval bonus
   - Necromancer: `C:0:0:1:0:0:1:0` -- Adds +1 protection die side
   - **Minor buff**: Slightly better protection.

4. **of Accompaniment** (daggers):
   - SilQ: `C:0:0:0:2:0:0:0` -- +2 evasion max
   - Necromancer: `C:0:0:0:0:0:0:0` -- No evasion bonus
   - **Nerf**: Lost evasion bonus.

### New Enchantment Types (Necromancer-exclusive)

| ID | Name | Slot | Flags | Notes |
|----|------|------|-------|-------|
| 10 | of the Ranger | Leather/Cloaks/Boots | STEALTH + PERCEPTION, pval 2 | Dunedain stealth gear |
| 11 | of Gondor | Mail/Shields | WILL + RES_FEAR, IGNORE_ALL | Soldiers of Gondor |
| 25 | of Westernesse | Swords only | SLAY_UNDEAD + LIGHT | Dunedain anti-undead |
| 29 | of Mirkwood | Bows/Spears | SLAY_SPIDER + STEALTH, pval 2 | Wood-elf spider hunters |
| 30 | of Lothlórien | Bows/Swords | GRA + PERCEPTION + LIGHT, pval 2 | Elven grace |
| 32 | of the Mark | Spears/Swords | RES_FEAR + FREE_ACT, +1 attack | Rohirrim cavalry |
| 33 | of Erebor | Axes/Hammers | STR + RES_FIRE, IGNORE_ALL, +1 dam/pval | Dwarven forge-craft |
| 42 | of Morgul | Daggers/Swords/Spears | BRAND_COLD + DARKNESS + LIGHT_CURSE | Enemy cursed weapons |
| 76 | of the Dwarrowdelf | Helms (iron-mithril) | CON + WILL, IGNORE_ALL, pval 1 | Stubborn dwarves |

**9 entirely new enchantment categories.** These significantly expand the enchantment pool, particularly for thematic builds (Ranger, Gondorian, Rohirrim, Dwarven, Elven, Dark).

---

## 4. Necromancer Data Files vs SilQ: artefact.txt

### Complete Artifact Replacement

The Necromancer replaces **every artifact** with Third-Age-appropriate versions. The file is 2244 lines vs SilQ's 1953 lines. Key changes:

#### Special Artifacts (Indices 1-10)

| Index | SilQ | Necromancer | Mechanical Diff |
|-------|------|-------------|-----------------|
| 1 | Ring of Barahir | Ring of Barahir | Same flags, different lore |
| 2 | Ring of Melian (PERCEPTION, pval 7) | Vilya's Shard (PERCEPTION + CON + REGEN, pval 2) | **Major: lost pval 7, gained CON+REGEN** |
| 3 | Amulet of Tinfang Gelion | Amulet of the Woodland Realm | Same flags |
| 4 | Pearl Nimphelos | Nimrodel's Tear | Same flags |
| 5 | Jewel Elessar (CON + REGEN + Str in Adversity) | Evenstar (CON + REGEN + LIGHT) | **Lost ability grant, gained LIGHT** |
| 6 | Necklace (varies in SilQ) | Necklace of Girion (CON + GRA) | Different stats |
| 7 | (SilQ varies) | Ring of the Nazgul (STEALTH+WILL+DARKNESS+TRAITOR+SEE_INVIS) | **New: cursed ring** |
| 8 | (SilQ varies) | Crown of Gondor (WILL) | Simplified |
| 9 | (SilQ varies) | Crown of the Witch-King (WILL+RES_FEAR+SEE_INVIS+DARKNESS+AGGRAVATE+DANGER) | **New: powerful cursed crown** |
| 10 | (SilQ varies) | Crown of the Dwarrowdelf (WILL+RES_FEAR+CON+Majesty) | Different stats |

#### Weapon Artifacts -- Major Additions

The Necromancer adds many iconic Third-Age weapons:

| Name | Type | Key Flags | Notes |
|------|------|-----------|-------|
| Morgul-blade | Dagger | BRAND_COLD+VAMPIRIC+DARKNESS+CURSED | Nazgul weapon |
| Sting | Dagger | SLAY_ORC+SLAY_SPIDER+SEE_INVIS+LIGHT | Bilbo's blade |
| Narsil Shard | Dagger | LIGHT+SLAY_UNDEAD | Broken sword fragment |
| Narsil (whole) | Longsword | LIGHT+RES_FIRE+RES_COLD+SLAY_UNDEAD | Elendil's sword |
| Orcrist | Longsword | SLAY_ORC+SLAY_TROLL+PERCEPTION+LIGHT | Thorin's blade |
| Glamdring | Longsword | SLAY_ORC+SLAY_TROLL+WILL+LIGHT | Gandalf's blade |
| Guthwine | Bastard Sword | ACCURATE+RES_FEAR+FREE_ACT | Eomer's blade |
| Herugrim | Greatsword | STR+SUST_STR+RES_FEAR | Theoden's blade |
| Flame of the West | Greatsword | CON+BRAND_FIRE+LIGHT+CURSED | Fire sword |
| Ringil | Mithril Sword | BRAND_COLD+LIGHT | Fingolfin's blade |
| Aiglos | Mithril Sword | BRAND_COLD+LIGHT, 3d5 3/3 | Gil-galad's weapon |
| Aeglos | Spear | BRAND_COLD+RES_COLD+THROWING | Gil-galad's spear |
| Baruk Khazad | Great Axe | WILL+SLAY_ORC+Vengeance | Dwarven battle-cry |
| Spider-bane | Glaive | DEX+FREE_ACT+SLAY_SPIDER+RES_POIS | Anti-spider polearm |
| Hadhafang | Longsword | SLAY_ORC+SLAY_TROLL+FREE_ACT+PERCEPTION | Elrond's blade |
| Noldorin Knife | Dagger | SHARPNESS+SEE_INVIS+LIGHT+THROWING | High Elven blade |
| Bow of the Last Alliance | Longbow | SLAY_ORC+SLAY_TROLL+LIGHT+RES_FEAR | Legendary bow |
| Black Arrow | Arrow | +15 attack, SLAY_DRAGON | Bard's arrow |

#### Armor Artifacts -- Key Additions

| Name | Type | Key Flags |
|------|------|-----------|
| Robe of Radagast | Robe | PERCEPTION+RES_POIS |
| Robe of Galadriel | Robe | FREE_ACT+SUST_GRA+LIGHT |
| Robe of Rivendell | Robe | SPEED+FREE_ACT |
| Ranger Leathers of the Ranger | Leather | STEALTH+PERCEPTION+Exchange Places |
| Woodman's Leather | Leather | Flanking+Keen Senses |
| Armor of Eol | Galvorn | DEX+RES_POIS+HUNGER+DARKNESS |
| Mithril Shirt | Mail | RES_FIRE+RES_COLD+RES_POIS |
| Tower Guard Hauberk | Mail | STAND_FAST+WILL |
| Corslet Starlight | Mithril | RES_FEAR+RES_BLIND+PERCEPTION+WILL+Song of Elbereth |
| Wolf-Hame of the Werewolf | Cloak | STEALTH+Disguise |
| Bat-Fell of the Vampire | Cloak | STEALTH+Disguise |

#### New Artifact Additions (Indices 199-222)

These are entirely new, not replacing SilQ artifacts:

| Index | Name | Type | Key Flags |
|-------|------|------|-----------|
| 199 | Lamp of the Noldor | Jewel-lamp | PERCEPTION+LIGHT |
| 200 | Palantir | Lesser Jewel | SEE_INVIS+PERCEPTION+WILL+CURSED |
| 201 | Torch of Mordor | Torch | RES_FIRE+LIGHT+AGGRAVATE+CURSED |
| 202 | Elendilmir | Lesser Jewel | WILL+GRA+LIGHT+RES_FEAR |
| 203 | Shadow Cloak of Mordor | Cloak | STEALTH+DARKNESS+SEE_INVIS+CURSED |
| 204 | Mantle of Stars | Cloak | STEALTH+GRA+LIGHT+FREE_ACT |
| 205 | Corslet of Erebor | Mail | STR+RES_FIRE+SUST_STR |
| 206 | Iron Helm of Durin | Great Helm | WILL+RES_FEAR+CON+SUST_CON |
| 207 | Crown of the Smith | Great Helm | WILL+RES_FIRE+FREE_ACT+SUST_STR+SUST_DEX |
| 208 | Gauntlets of Erebor | Gauntlets | STR+RES_FIRE+SUST_STR |
| 209 | Gloves of Shadow | Gloves | STEALTH+SEE_INVIS+DARKNESS+CURSED |
| 210 | Boots of Lothlórien | Boots | GRA+FREE_ACT+STEALTH |
| 211 | Hadhafang | Longsword | SLAY_ORC+SLAY_TROLL+FREE_ACT+PERCEPTION |
| 212 | Noldorin Knife | Dagger | SHARPNESS+SEE_INVIS+LIGHT+THROWING |
| 213 | War-axe of Erebor | Battle Axe | STR+SLAY_ORC+RES_FIRE |
| 214 | Hammer of the Longbeards | Warhammer | STR+CON+SLAY_ORC+SLAY_TROLL+RES_FIRE+SUST_STR |
| 215 | Longbow of Mirkwood | Longbow | STEALTH+SLAY_SPIDER+RES_POIS |
| 216 | Black Bow of Mordor | Longbow | ACCURATE+DARKNESS+CURSED |
| 217 | Bow of the Last Alliance | Longbow | SLAY_ORC+SLAY_TROLL+LIGHT+RES_FEAR |
| 218 | Ring of the Noldor | Ring | GRA+SEE_INVIS+SUST_GRA |
| 219 | Ring of Mastery | Ring | STR+DEX+CON+GRA |
| 220 | Amulet of the Istari | Amulet | WILL+PERCEPTION+RES_FEAR |
| 221 | Black Necklace | Amulet | STR+VAMPIRIC+DARKNESS+CURSED |
| 222 | Star of the North | Amulet | WILL+GRA+LIGHT+RES_FEAR+RES_COLD |

#### Quest Artifacts (Indices 175-180)

SilQ quest: cut Silmaril from Morgoth's crown.
Necromancer quest: retrieve Ring of Thrain + Key to Erebor + Thror's Map.

| Index | Necromancer | Purpose |
|-------|-------------|---------|
| 175 | Ring of Thrain (normal) | Victory item 1 |
| 176 | Ring of Thrain (corrupted) | Escalation version |
| 177 | Ring of Thrain (burning) | Escalation version |
| 178 | Ring of Thrain (placeholder) | Compatibility |
| 179 | Key to Erebor | Victory item 2 |
| 180 | Thror's Map | Victory item 3 |

---

## 5. Ability System Changes

### Renamed/Reworked Melee Abilities

| SilQ Ability | Necromancer Ability | Change Type |
|-------------|-------------------|-------------|
| Impale | Opening Strike | **Complete redesign**: was pierce-through, now bonus die vs unwary |
| Whirlwind Attack | Cleave | **Nerfed**: SilQ hits ALL adjacent on any attack; Necro only on kill |
| Smite | Mighty Blow | **Changed**: SilQ = max damage; Necro = +STR bonus damage |
| Two Weapon Fighting | Defensive Stance | **Complete redesign**: SilQ = dual wield; Necro = +3 eva when stationary |
| Rapid Attack | Swift Strikes | Name change only, same mechanic |
| Versatility | Keen Eyes | **Complete redesign**: SilQ = melee bonus from archery; Necro = +2 archery at range |

### Renamed/Reworked Stealth Abilities

| SilQ Ability | Necromancer Ability | Change Type |
|-------------|-------------------|-------------|
| Cruel Blow | Disorienting Strike | Added confusion effect |
| Exchange Places | Escape Artist | **Complete redesign**: SilQ = swap with enemy; Necro = auto-break webs, half trap damage |
| Opportunist | Light Fingers | **Complete redesign**: SilQ = free attacks on fleeing; Necro = steal from unwary |

### New Stealth Abilities (Necromancer-exclusive)

| Ability | Prereqs | Effect |
|---------|---------|--------|
| Throat Slit | Stealth 7, Skill 4 | Instantly kill sleeping/unaware humanoids silently |
| Fade | Stealth 8, req Vanish | Kill unaware -> invisible for 2 turns |
| Pilfer | Stealth 9, Skill 10 | 25% chance kills drop extra items |
| Distraction | Stealth 10, Skill 6 | Alert enemies confused 1 turn on miss by 5+ |
| Silent Kill | Stealth 11, Skill 12 | Removes humanoid restriction from Throat Slit |

### Song -> Lore System Replacement

The entire Song skill tree has been renamed to "Lore" with thematic changes:

| SilQ Song | Necromancer Lore | Mechanical Change |
|-----------|-----------------|-------------------|
| Song of Elbereth | Word of Command | Name only |
| Song of Challenge | Lore of Battle | Name only |
| Song of Delvings | Deep Memory | Name only |
| Song of Freedom | Word of Opening | Name only |
| Song of Silence | Lore of Silence | Name only |
| Song of Staunching | Herbcraft | **Changed**: also "doubles herb effectiveness" |
| Song of Thresholds | Word of Shutting | Name only |
| Song of the Trees | Inner Light | **Changed**: "1 point per 5 Lore" (was per 5 Song) |
| Song of Slaying | Deadly Lore | Name only (uses Lore score) |
| Song of Staying | Lore of Endurance | Name only |
| Song of Lorien | Lore of Sleep | Name only |
| Song of Mastery | Word of Mastery | Name only |
| Woven Themes | Device Mastery | **Changed**: SilQ = two songs; Necro = "combine two lore effects" |

### Smithing Ability Changes

| SilQ Ability | Necromancer Ability | Mechanical Change |
|-------------|-------------------|-------------------|
| Enchantment | Reforge | **Complete redesign**: SilQ = create special items; Necro = combine 2 Broken Glowing items |
| Expertise | Expertise | **Changed**: SilQ = no XP cost; Necro = 50% discount at 6-9, 75% at 10+ |
| Artifice | Reclaim | **Complete redesign**: SilQ = custom artifacts; Necro = combine 2 Broken Strange items |
| Masterpiece | Masterwork | **Complete redesign**: SilQ = exceed difficulty; Necro = combine 4 Broken Strange items |

### New Smithing Abilities (Necromancer-exclusive)

| Ability | Effect |
|---------|--------|
| Reforge Mastery | Reject/reroll random enchantment result |
| Salvage | 50% chance to recover Broken Glowing from equipment destruction |
| Reclaim Mastery | Choose from 3 random artifacts |
| Master Smith | Masterwork with 2 Strange items instead of 4 |

### Other Ability Changes

| SilQ Ability | Necromancer Ability | Change |
|-------------|-------------------|--------|
| Quick Study | Natural Talent | Name change, same mechanic |
| Loremaster | Herbalist | **Changed**: SilQ = identify staves/horns too; Necro = only herbs/potions + alchemy crafting |
| Channeling | Force of Will | **Changed**: SilQ = auto-recognize; Necro = "mental strength lets you recognise" |
| Inner Light (Will tree) | Defy Death | **Complete redesign**: SilQ = +2 light intensity; Necro = once-per-floor survive at 0 HP |

---

## 6. C Source Code Changes

### New Systems (Code Added)

1. **Wand System** (`defines.h`, `object2.c`, `cmd3.c`, `cmd6.c`, `use-obj.c`):
   - New TV_WAND tval (56) with 6 sval types
   - `charge_wand()` function with per-type charge counts
   - `do_cmd_use_wand()` function for targeting and effects
   - Flavor text assignment for unidentified wands

2. **Broken Item Spawning** (`object2.c`):
   - `place_forge_items()` function spawns 3 broken items near each forge
   - Depth-based selection: Glowing before D10, Strange after D10

3. **Harmful Consumable Removal** (`object2.c`):
   - `kind_is_harmful_consumable_identified()` removes identified harmful potions/herbs from drop tables
   - Once player identifies a harmful item, it never spawns again

4. **Ring of Thrain Quest System** (`cmd3.c`):
   - Equipping Ring of Thrain forces Song of Delvings (Deep Memory)
   - Removing it stops the song
   - Ring escalation mechanics (normal -> corrupted -> burning)

5. **Discovery XP** (`cmd3.c`):
   - `IDENT_NOTE_READ` flag tracks first read of lore notes
   - Grants 500 XP on first read

6. **Death Recap Tracking** (`object2.c`):
   - `p_ptr->rarest_item_depth` tracks deepest item found
   - Ring of Thrain theft tracking

### Changed Systems (Code Modified)

1. **Boss References**: All `R_IDX_MORGOTH` changed to `R_IDX_SAURON`, all "Morgoth" strings to "the Necromancer"
2. **Victory Condition**: "Cut a Silmaril" changed to "Claimed a treasure from Dol Guldur"
3. **Silmaril mechanics** repurposed for Ring of Thrain

---

## 7. Test Status

### Documented Testing

- **TEST_CHECKLIST.md**: Linux platform testing checklist only (installation, terminal/X11 modes, save system). No gameplay balance testing.
- **KNOWN_ISSUES.md**: Lists "Consumables balance not finalized" and "Equipment damage values may have balance issues from Sil-Q"
- **No automated tests exist** in the C codebase
- **No enchantment-specific testing** documented

### What Was Tested
- Linux Mint installation and launch
- Terminal (ncurses) and X11 graphical modes
- Save/load system
- Basic gameplay (character creation, movement, inventory)

### What Was NOT Tested
- Enchantment balance
- Wand balance (charges, damage, effects)
- Broken item spawn rates
- Alchemy crafting system
- Discovery item XP values
- New ability balance
- Artifact power levels
- Harmful consumable removal system

---

## 8. Summary of All Necromancer-Specific Additions

### Entirely New Systems (Not in SilQ)
1. **Wand system** (6 wands, charge mechanics, targeting)
2. **Broken item smithing** (5 broken item types, Reforge/Reclaim/Masterwork)
3. **Discovery XP items** (38 items for combat-free progression)
4. **Alchemy crafting** (4 improved herb recipes)
5. **Harmful consumable removal** (identified bad items stop spawning)
6. **Ring of Thrain quest mechanics** (forced song, escalation)
7. **Pipe-weed** (+3 Grace for 30 turns consumable)
8. **Potion of Shadows** (invisibility)
9. **Flute of the Fairy** (concealment mists)
10. **Horn of Challenge** (battle-fury buff)

### New Enchantment Types (9)
of the Ranger, of Gondor, of Westernesse, of Mirkwood, of Lothlórien, of the Mark, of Erebor, of Morgul, of the Dwarrowdelf

### New Abilities (9)
Opening Strike, Defensive Stance, Keen Eyes, Escape Artist, Light Fingers, Throat Slit, Fade, Pilfer, Distraction, Silent Kill, Herbcraft (reworked), Defy Death (reworked), Reforge Mastery, Salvage, Reclaim Mastery, Master Smith

### Mechanically Changed Enchantments (3)
of the Eorlingas (GRA+LIGHT -> STR+RES_FEAR), of Shadow (BRAND_FIRE+CUMBERSOME -> VAMPIRIC+DARKNESS+HUNGER), of Black Yew (+1 prot die side)

### New Artifacts (24)
Indices 199-222, all Third-Age themed

### Total Artifact Count
- SilQ: ~80 artifacts
- Necromancer: ~100 artifacts (all replaced + 24 new)

---

## 9. Critical Observations for Godot Port

### Enchantment Data Integrity
- All 9 new enchantment types need to be ported to the Godot version
- The mechanical changes to existing enchantments (Eorlingas, Shadow, Black Yew) must be reflected
- Broken item system is already partially implemented in Godot (smithing overhaul)

### Missing from Godot (Likely)
- Wand system (TV_WAND) -- needs verification
- Alchemy crafting for improved herbs
- Discovery XP items (38 items)
- Harmful consumable removal
- Pipe-weed, Potion of Shadows, Flute of the Fairy, Horn of Challenge
- Ring of Thrain escalation mechanics

### Ability Discrepancies
- Many abilities were redesigned in Necromancer but may not match what's in Godot
- The Lore/Song rename may create confusion
- New stealth abilities (Throat Slit, Fade, Silent Kill) need verification

### Balance Concerns
- The 9 new enchantment types have no documented balance testing
- Wand charges may be too generous
- Discovery items grant massive XP (500 per Dol Guldur Record, 500 per Palantir Shard)
- New stealth abilities (Throat Slit -> Silent Kill chain) may trivialize combat

---

*Report generated 2026-02-08*
*Source: necromancer-linux-port (commit b65ce6c), SilQ 1.5.1 (/tmp/sil-q/)*
