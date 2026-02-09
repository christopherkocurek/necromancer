# Report 1: SilQ Enchantment System -- Full Analysis

**Source:** SilQ source code at `/tmp/sil-q/`
**Date:** 2026-02-08
**Purpose:** Reference document for Necromancer enchantment system design

---

## Table of Contents

1. [Item Types and Base Stats](#1-item-types-and-base-stats)
2. [Enchantments / Ego Items (special.txt)](#2-enchantments--ego-items)
3. [Artifacts (artefact.txt)](#3-artifacts)
4. [Smithing / Forging System](#4-smithing--forging-system)
5. [Item Generation System](#5-item-generation-system)
6. [Design Analysis: What Makes It Work](#6-design-analysis)

---

## 1. Item Types and Base Stats

### Stat Line Format
```
P: plus-to-hit : damage-dice : plus-to-evasion : protection-dice
W: depth : rarity : weight(tenths-lb) : cost
A: depth/rarity : depth/rarity : ...  (allocation table)
```

### 1.1 Body Armor (Soft Armor, tval 36)

| Item | Depth | Weight | Attack | Damage | Evasion | Protection | Flags |
|------|-------|--------|--------|--------|---------|------------|-------|
| Robe | 1 | 3.0 | +0 | 0d0 | +1 | 1d0 | ENCHANTABLE |
| Leather Armour | 1 | 7.0 | +0 | 0d0 | -1 | 1d4 | -- |
| Studded Leather | 2 | 13.0 | +0 | 0d0 | -2 | 1d6 | -- |
| Galvorn Armour | 17 | 7.0 | +0 | 0d0 | -1 | 1d8 | IGNORE_ALL, NO_SMITHING |

**Key insight:** Soft armor trades evasion for protection. Robe is unique -- it gives +1 evasion, 1d0 protection (no damage absorption), and is ENCHANTABLE (30% difficulty reduction for smithing). Galvorn is endgame soft armor: light as leather but protects like heavy mail.

### 1.2 Heavy Armor (Mail, tval 37)

| Item | Depth | Weight | Attack | Damage | Evasion | Protection |
|------|-------|--------|--------|--------|---------|------------|
| Mail Corslet | 5 | 27.0 | -1 | 0d0 | -3 | 2d4 |
| Hauberk | 7 | 35.0 | -2 | 0d0 | -4 | 2d5 |
| Mithril Corslet | 7 | 15.0 | +0 | 0d0 | -2 | 2d4 |

**Key insight:** Mail provides the best protection but cripples attack AND evasion. Mithril Corslet is strictly better than regular Mail Corslet -- same protection, no attack penalty, lighter, less evasion penalty. This creates a clear upgrade path.

### 1.3 Shields (tval 34)

| Item | Depth | Weight | Attack | Evasion | Protection |
|------|-------|--------|--------|---------|------------|
| Round Shield | 3 | 5.0 | +0 | +0 | 1d3 |
| Kite Shield | 6 | 8.0 | -2 | +0 | 1d6 |
| Mithril Shield | 8 | 4.0 | -1 | +0 | 1d6 |

### 1.4 Edged Weapons (Swords, tval 23)

| Item | Depth | Weight | Attack | Damage | Evasion | Flags |
|------|-------|--------|--------|--------|---------|-------|
| Dagger | 1 | 0.5 | +0 | 1d5 | +0 | THROWING, MORE_SPECIAL |
| Curved Sword | 2 | 4.0 | -1 | 2d5 | +1 | -- |
| Shortsword | 1 | 2.0 | +0 | 1d7 | +1 | -- |
| Longsword | 4 | 3.0 | +0 | 2d5 | +1 | -- |
| Bastard Sword | 6 | 4.0 | -2 | 3d3 | +1 | HAND_AND_A_HALF |
| Greatsword | 4 | 6.0 | -2 | 3d5 | +1 | TWO_HANDED |
| Mithril Longsword | 5 | 2.0 | +1 | 2d5 | +1 | MITHRIL |
| Mithril Greatsword | 6 | 4.0 | -2 | 3d6 | +1 | TWO_HANDED, MITHRIL |

**Key insight:** Weapon design uses clear tradeoffs: attack penalty for damage dice. Daggers have low damage but high versatility (THROWING, MORE_SPECIAL = 50% bonus chance of being ego). The curved sword is "crude" (-1 attack) but high raw damage. Weight matters for STR bonus -- you can only add +1 damage side per pound of weapon weight.

### 1.5 Axes & Polearms (tval 22)

| Item | Depth | Weight | Attack | Damage | Evasion | Flags |
|------|-------|--------|--------|--------|---------|-------|
| Spear | 1 | 3.0 | +0 | 1d9 | +0 | THROWING, HAND_AND_A_HALF, POLEARM |
| Great Spear | 4 | 6.0 | +1 | 1d13 | +1 | TWO_HANDED, POLEARM |
| Glaive | 8 | 7.0 | -1 | 2d9 | +1 | TWO_HANDED, POLEARM |
| Hand Axe | 2 | 1.0 | -1 | 4d2 | +0 | AXE |
| Battle Axe | 4 | 4.5 | -3 | 3d4 | +0 | HAND_AND_A_HALF, AXE |
| Great Axe | 8 | 8.0 | -4 | 4d4 | +0 | TWO_HANDED, AXE |

**Key insight:** Polearms have the highest raw damage per hit (1d13 great spear, 2d9 glaive). Axes have many small dice (4d2, 3d4, 4d4) -- different damage distribution (more consistent, benefits more from STR because each die gets the STR bonus). Spear is the starter weapon with HAND_AND_A_HALF (can use one or two handed).

### 1.6 Blunt Weapons (tval 21)

| Item | Depth | Weight | Attack | Damage | Evasion | Flags |
|------|-------|--------|--------|--------|---------|-------|
| Quarterstaff | 1 | 5.0 | +0 | 2d5 | +2 | TWO_HANDED, ENCHANTABLE, MORE_SPECIAL |
| War Hammer | 6 | 5.0 | -2 | 4d1 | +0 | HAND_AND_A_HALF |

**Key insight:** Quarterstaff is one of only two ENCHANTABLE items (with Robe). Gives +2 evasion -- it's a defensive weapon. War Hammer has unique 4d1 damage -- guaranteed minimum 4 damage, benefits enormously from STR (each die goes from d1 to d1+STR).

### 1.7 Digging Tools (tval 20)

| Item | Depth | Weight | Attack | Damage | Flags |
|------|-------|--------|--------|--------|-------|
| Shovel | 5 | 5.0 | -3 | 2d2 | TUNNEL, TWO_HANDED |
| Mattock | 10 | 10.0 | -5 | 5d2 | TUNNEL, TWO_HANDED |

### 1.8 Bows (tval 19)

| Item | Depth | Weight | Attack | Damage | Flags |
|------|-------|--------|--------|--------|-------|
| Shortbow | 1 | 1.5 | +0 | 1d7 | -- |
| Longbow | 6 | 3.0 | +0 | 2d4 | -- |
| Dragon-horn Bow | 15 | 4.5 | +0 | 4d2 | NO_SMITHING |

### 1.9 Arrows (tval 17)

| Item | Depth | Weight | Attack | Damage |
|------|-------|--------|--------|--------|
| Arrow | 1 | 0.1 | +0 | 0d0 |

Arrows have no inherent damage -- all damage comes from the bow. Arrows can be fine (+3 attack) or special (ego). Generated in stacks of 20+1d(10+depth_adjust).

### 1.10 Helms (tval 32)

| Item | Depth | Weight | Attack | Evasion | Protection | Flags |
|------|-------|--------|--------|---------|------------|-------|
| Helm | 3 | 5.0 | +0 | -1 | 1d2 | -- |
| Great Helm | 5 | 8.0 | +0 | -2 | 1d3 | -- |
| Dwarf Mask | 10 | 8.0 | +0 | -2 | 1d2 | RES_FIRE |
| Mithril Helm | 7 | 3.5 | +0 | -1 | 1d3 | MITHRIL |

### 1.11 Cloaks (tval 35)

| Item | Depth | Weight | Evasion | Protection | Flags |
|------|-------|--------|---------|------------|-------|
| Cloak | 2 | 2.0 | +1 | 1d0 | -- |
| Shadow Cloak | 12 | 1.0 | +3 | 1d0 | DARKNESS, STEALTH (pval 2) |

**Key insight:** Cloaks are pure evasion items. Shadow Cloak is powerful: +3 evasion, +2 stealth, but DARKNESS (reduces your light radius).

### 1.12 Boots (tval 30)

| Item | Depth | Weight | Evasion | Protection | Flags |
|------|-------|--------|---------|------------|-------|
| Boots | 1 | 2.0 | +0 | 1d1 | -- |
| Greaves | 4 | 8.0 | -1 | 1d2 | IGNORE_FIRE |
| Mithril Greaves | 6 | 4.0 | +0 | 1d2 | MITHRIL |

### 1.13 Gloves (tval 31)

| Item | Depth | Weight | Attack | Protection | Flags |
|------|-------|--------|--------|------------|-------|
| Gloves | 1 | 0.5 | +0 | 1d0 | -- |
| Gauntlets | 3 | 3.0 | -1 | 1d1 | IGNORE_FIRE |
| Mithril Gauntlets | 5 | 1.5 | +0 | 1d1 | MITHRIL |

### 1.14 Rings (tval 45)

| Item | Depth | Allocation | Key Effect |
|------|-------|------------|------------|
| Ring of Secrets | 15 | 15/30 | +Perception, grants Alchemy ability |
| Ring of Ered Luin | 8 | 8/10 | +Will, RES_FEAR, RES_CONFU |
| Ring of Evasion | 8 | 8/15 | +Evasion (variable, depth-based) |
| Ring of Protection | 7 | 7/4 | +Protection dice (variable) |
| Ring of Strength | 9 | 9/25 | +STR, SUST_STR |
| Ring of Dexterity | 10 | 10/25 | +DEX, SUST_DEX |
| Ring of Frost | 9 | 9/3 | RES_FIRE |
| Ring of Warmth | 10 | 10/3 | RES_COLD |
| Ring of Accuracy | 12 | 12/15 | +Attack (variable) |
| Ring of Free Action | 12 | 12/3 | FREE_ACT |
| Ring of Cowardice | 7 | 7/6 | FEAR, grants Dodging (cursed) |
| Ring of Bauglir's Vanguard | 6 | 6/2 | RES_STUN, SUST_STR, HUNGER |
| Ring of Venom's End | 6 | 6/4 | RES_POIS |
| Ring of the Laiquendi | 8 | 8/20 | +Stealth, +Archery |

**Key insight:** Ring values are DEPTH-DEPENDENT. Ring of Evasion = `(level + 1d10) / 9`. Found at depth 8 with 1d10: ranges from +1 to +2. Found at depth 20: ranges from +2 to +3. This makes the same ring type progressively better at deeper levels.

### 1.15 Amulets (tval 40)

| Item | Depth | Allocation | Key Effect |
|------|-------|------------|------------|
| Amulet of Last Chances | 7 | 12/40 | CHEAT_DEATH |
| Amulet of Constitution | 8 | 8/5 | +CON, SUST_CON |
| Amulet of Grace | 10 | 10/5 | +GRA, SUST_GRA |
| Amulet of Regeneration | 12 | 8/3 | REGEN |
| Amulet of Preservation | 14 | 6/3 | SUST_CON, SUST_GRA, SLOW_DIGEST |
| Amulet of the Blessed Realm | 16 | 16/6 | +GRA, SUST_GRA, LIGHT |
| Amulet of Haunted Dreams | 9 | 9/3 | HAUNTED, SEE_INVIS (cursed) |
| Amulet of the Vigilant Eye | 4 | 10/20 | +Perception, RES_HALLU, grants Keen Senses |

### 1.16 Light Sources (tval 39)

| Item | Depth | Radius | Duration | Flags |
|------|-------|--------|----------|-------|
| Wooden Torch | 1 | 1 | 3000 turns | NO_SMITHING |
| Mallorn Torch | 1 | 3 | 100 turns | NO_SMITHING |
| Brass Lantern | 5 | 2 | 7000 turns | -- |
| Lesser Jewel | 3 | 1 | Permanent | -- |
| Feanorian Lamp | 12 | 4 | Permanent | MITHRIL |
| Silmaril | 25 | 7 | Permanent | SEE_INVIS, SUST_GRA, NO_SMITHING |

### 1.17 Other Items

**Staves** (21 types): Imprisonment, Freedom, Light, Sanctity, Understanding, Revelations, Treasures, Foes, Slumber, Majesty, Self Knowledge, Warding, Dismay, Recharging, Summoning, Shadows. All are usable items with charges.

**Horns** (5 types): Terror, Thunder, Force, Blasting, Warning. Directional sound effects.

**Herbs** (10 types): Rage, Sustenance, Terror, Healing, Restoration, Emptiness, Visions, Entrancement, Weakness, Sickness. Mix of beneficial and harmful.

**Potions** (18 types): Miruvor, Orcish Liquor, Esgalduin, Clarity, Healing, Voice, True Sight, Antidote, Quickness, Elemental Resistance, Strength, Dexterity, Constitution, Grace, Slowness, Poison, Blindness, Confusion.

---

## 2. Enchantments / Ego Items

### Format
```
N: serial-number : name
C: max-att : plus-dd : plus-ds : max-evn : plus-pd : plus-ps : pval
W: depth : rarity : max_depth : cost
T: tval : min_sval : max_sval  (what items it can appear on)
F: flags
B: skill/ability  (granted ability)
```

### 2.1 Armor Enchantments

| # | Name | Items | Effect | Depth | Rarity | Cost |
|---|------|-------|--------|-------|--------|------|
| 1 | of Protection | Shields, Greaves, Soft/Hard Armor | +0d1 protection sides | 0 | 2 | Good |
| 2 | of Venom's End | Soft/Hard Armor | RES_POIS | 0 | 2 | Good |
| 3 | of Resilience | Galvorn/Mithril only | +1 CON, IGNORE_ALL | 10 | 6 | Good |
| 4 | of Brethil | Leather/Gloves/Boots | FREE_ACT, IGNORE_ALL | 6 | 10 | Good |
| 5 | of Stealth | Soft Armor | +3 Stealth (pval 3) | 0 | 1 | Good |
| 6 | of Nogrod | Shields/Greaves/Mail | SUST_STR/DEX/CON/GRA | 0 | 4 | Good |
| 7 | of the Iron Hills | Greaves(iron)/Mail(iron) | STAND_FAST, RES_FEAR | 0 | 1 | Good |
| 8 | of Ladros | Greaves(iron)/Gauntlets | RES_COLD | 8 | 10 | Good |
| 9 | of Blight | Soft/Hard Armor | VUL_POIS | 0 | 1 | **Cursed** |

### 2.2 Shield Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 12 | of Deflection | All Shields | +2 evasion | 0 | 1 |
| 13 | of Frost | All Shields | RES_FIRE | 10 | 1 |
| 14 | with Many Runes | Mithril Shield only | CHEAT_DEATH | 20 | 20 |
| 15 | of Wrath | Non-mithril shields | AGGRAVATE | 0 | 2 | **Cursed** (max depth 10) |

### 2.3 Weapon Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 20 | of Cuivienen | Daggers only | +3 pval: LIGHT, SUST_GRA, SUST_DEX, SONG | 0 | 1 |
| 21 | of Gondolin | Swords/Spears/Glaives/Arrows/Mithril swords | SLAY_ORC, SLAY_TROLL | 0 | 4 |
| 22 | of Doriath | Axes/Swords/Spears/Glaives/Arrows/Mithril | SLAY_SPIDER, SLAY_WOLF | 2 | 4 |
| 23 | of Nargothrond | Swords/Spears/Glaives/Mithril | SLAY_RAUKO, SLAY_DRAGON | 9 | 4 |
| 24 | of Final Rest | Warhammers/Axes/Swords | SLAY_UNDEAD, FREE_ACT | 7 | 6 |
| 26 | of the Firebeards | Warhammers/Axes/Mattocks | REGEN, RES_FIRE | 4 | 8 |
| 27 | of Hador's House | Warhammers/Axes/Glaives/Swords(long+) | +1ds, grants Follow-Through | 8 | 4 |
| 28 | of Fury | Warhammers/Axes/Glaives/Swords(bastard+) | +1ds, grants Whirlwind Attack, AGGRAVATE, CURSED | 10 | 4 |
| 31 | of the Feanorians | Swords only | +1 GRA, +1 DEX, DANGER | 12 | 10 |
| 34 | of Murder | Daggers/Curved Swords | +3 Stealth, grants Assassination | 0 | 1 |
| 35 | of Accompaniment | Daggers only | +2 evasion, grants Two Weapon Fighting | 0 | 1 |
| 36 | of the Vanyar | Spears only | +1 att, +1ds, +1 GRA, LIGHT | 10 | 4 |
| 37 | of Mithrim | Quarterstaves only | +1 att, REGEN | 0 | 1 |
| 38 | of the Helcaraxe | Quarterstaves only | +1 CON, RES_COLD | 2 | 6 |
| 39 | of Battering | Warhammers only | Grants Knock Back | 0 | 2 |
| 40 | of Crushing | Warhammers only | +1ds, +1 STR | 10 | 4 |
| 41 | of Piercing | Polearms only | +1ds, grants Impale | 4 | 8 |
| 43 | of Udun | Curved/Great swords, Great Axes | BRAND_FIRE, CUMBERSOME | 12 | 10 |
| 44 | of Thangorodrim | Warhammers/Curved/Great swords/Axes | +1ds, +1 CON, CUMBERSOME | 2 | 6 |
| 45 | of Black Iron | Curved/Great swords/Axes/Glaives | +1ds, SLAY_MAN_OR_ELF, AGGRAVATE | 0 | 3 |
| 46 | (Poisoned) | Daggers/Hand Axes | BRAND_POIS | 0 | 1 |
| 47 | (Balanced) | Axes/Spears/Swords/Daggers | ACCURATE | 14 | 20 |
| 48 | (Defender) | Non-curved Swords/Glaives | +1 evasion, IGNORE_ALL | 0 | 4 |
| 49 | (Vampiric) | Glaives/Great Axes/Curved Swords/Bastard Swords | VAMPIRIC, HUNGER, CURSED | 4 | 4 |

### 2.4 Digging Tool Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 51 | of Belegost | Mattocks only | +1 TUNNEL (pval) | 0 | 1 |
| 52 | of the Longbeards | Mattocks only | +STR | 0 | 20 |

### 2.5 Helm Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 71 | of Brilliance | All Helms | LIGHT | 0 | 1 |
| 72 | of Defiance | All Helms | +3 Will, RES_FEAR | 0 | 1 |
| 73 | of True Sight | All Helms + Light Sources | RES_BLIND, SEE_INVIS, RES_HALLU | 0 | 1 |
| 74 | of Clarity | All Helms | RES_CONFU, RES_STUN, RES_HALLU | 0 | 1 |
| 75 | of Grace | Mithril Helm + Lesser Jewel | +1 GRA | 0 | 1 |
| 80 | of Terror | Non-mithril Helms | FEAR | 0 | 4 | **Cursed** |

### 2.6 Cloak Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 82 | of Stealth | All Cloaks | +3 Stealth | 0 | 2 |
| 83 | of Warmth | All Cloaks | RES_COLD | 4 | 8 |
| 84 | of the Traveller | All Cloaks | SLOW_DIGEST | 0 | 1 |
| 86 | of Winter's Chill | All Cloaks | VUL_COLD | 0 | 1 | **Cursed** |
| 87 | of the Scarlet Heart | Cloaks only | RES_BLEED, SUST_CON | 0 | 4 |
| 88 | of the Golden Flower | Cloaks only | RES_FEAR, SUST_GRA | 0 | 4 |

### 2.7 Bow Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 91 | of Blackened Yew | Longbows only | +1ds, VUL_FIRE | 6 | 2 |
| 92 | of Lammoth | Shortbows only | RES_POIS, DANGER, AGGRAVATE | 4 | 8 |
| 93 | of Radiance | All Bows | RADIANCE | 6 | 4 |
| 94 | of the Marchwardens | All Bows | SEE_INVIS, RES_FEAR | 6 | 4 |
| 95 | of Falas | All Bows | +3 Perception, RES_COLD | 12 | 6 |
| 96 | of the Falmari | All Bows | ACCURATE | 12 | 10 |

### 2.8 Arrow Enchantments

| # | Name | Effect | Depth | Rarity |
|---|------|--------|-------|--------|
| 101 | (Poisoned) | BRAND_POIS | 6 | 6 |
| 102 | of Piercing | SHARPNESS | 10 | 10 |

### 2.9 Boot Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 110 | of Ithil's Light | Mithril Greaves only | RADIANCE | 0 | 2 |
| 111 | of Softest Tread | Boots only | +3 Stealth | 0 | 1 |
| 112 | of Snares Eluded | Mithril Greaves only | AVOID_TRAPS, FREE_ACT | 10 | 6 |
| 113 | of Speed | Boots only | Grants Sprinting | 10 | 4 |
| 114 | of Leaping | Boots only | Grants Leaping | 7 | 4 |
| 116 | of Treacherous Paths | Boots/Greaves | DANGER | 5 | 3 | **Cursed** (max depth 18) |

### 2.10 Glove Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 120 | of Archery | Gloves only | +3 Archery | 2 | 2 |
| 121 | of Lorellin | All Gloves | MEDIC | 0 | 4 |
| 122 | of Swordplay | All Gloves | Grants Parry | 4 | 2 |
| 123 | of the Ironfists | Gauntlets only | +1 CON, NEG_DEX | 4 | 6 |
| 124 | of Might | Mithril Gauntlets only | +1 STR | 10 | 4 |
| 126 | of Treachery | All Gloves | +1 STR, grants Opportunist, CURSED | 4 | 8 | **Cursed** (max depth 13) |

### 2.11 Light Source Enchantments

| # | Name | Items | Effect | Depth | Rarity |
|---|------|-------|--------|-------|--------|
| 130 | of Brightness | Lanterns/Lesser Jewels/Feanorian Lamps | LIGHT | 0 | 1 |
| 73 | of True Sight | (shared with helms) | RES_BLIND, SEE_INVIS, RES_HALLU | 0 | 1 |
| 75 | of Grace | Lesser Jewel only | +1 GRA | 0 | 1 |
| 135 | of Flickering Shadow | Lanterns only | DARKNESS, CURSED | 0 | 1 | **Cursed** (max depth 11) |

---

## 3. Artifacts

### 3.1 Special Artifacts (Indices 1-19: Rings, Amulets, Crowns, Light Sources)

| # | Name | Type | Depth | Key Properties |
|---|------|------|-------|----------------|
| 1 | Ring of Barahir | Ring | 10 | FREE_ACT, RES_POIS, MEDIC, Song of Staunching, +0/0d0/+0/1d1 |
| 2 | Ring of Melian | Ring | 14 | +7 pval, +Perception, grants Channeling |
| 3 | Amulet of Tinfang Gelion | Amulet | 12 | +2 Song, grants Woven Themes |
| 4 | Pearl 'Nimphelos' | Amulet | 12 | +2 GRA, SUST_GRA |
| 5 | Jewel 'Elessar' | Amulet | 14 | +1 CON, REGEN, grants Strength in Adversity |
| 6 | Necklace of the Dwarves | Amulet | 16 | +1 CON, +1 GRA |
| 7 | Ring of Mairon | Ring | 12 | +3 Stealth, +3 Song, DARKNESS, TRAITOR, SEE_INVIS, grants Vanish |
| 8 | Crown of Daeron | Crown | 14 | +4 Song |
| 9 | Crown of Feanor | Crown | 20 | +3 Will, RES_FIRE, SEE_INVIS, LIGHT, AGGRAVATE, grants Enchantment + Masterpiece |
| 10 | Crown of Maedhros | Crown | 8 | +3 Will, RES_FEAR, DANGER, grants Majesty |

### 3.2 Normal Artifacts (Indices 20+)

#### Soft Armor Artifacts

| # | Name | Base | Depth | Key Properties |
|---|------|------|-------|----------------|
| 20 | Robe of Andreth | Robe | 4 | +2 Song, SUST_GRA, [+2, 1d0] |
| 21 | Robe of Aredhel | Robe | 6 | FREE_ACT, SUST_GRA, [+3, 1d0] |
| 22 | Robe of Idril Celebrindal | Robe | 18 | SPEED, [+0, 1d0] |
| 24 | Leather of Gorlim | Leather | 3 | FEAR, grants Exchange Places, [-0, 1d5] |
| 25 | Leather of Haldad | Leather | 6 | +1 STR, RES_FEAR, FREE_ACT |
| 26 | Leather 'Catskin' | Leather | 10 | Grants Flanking + Keen Senses |
| 28 | Studded Leather of Beor | Studded | 8 | RES_POIS, SUST_GRA, grants Inner Light |
| 29 | Studded Leather of Aegnor | Studded | 4 | +1 Will, grants Concentration |
| 32 | Galvorn of Maeglin | Galvorn | 15 | +1 DEX, RES_POIS, HUNGER (auto-drop) |

#### Heavy Armor Artifacts

| # | Name | Base | Depth | Key Properties |
|---|------|------|-------|----------------|
| 34 | Mail Corslet of Fingon | Corslet | 8 | +1 CON, +1 GRA, RES_FEAR |
| 35 | Mail Corslet of Durin | Corslet | 13 | RES_FIRE, RES_COLD, REGEN, 3d3 prot |
| 36 | Hauberk of Maedhros | Hauberk | 13 | RES_FIRE, RES_POIS, 2d6 prot |
| 37 | Hauberk of Amon Rudh | Hauberk | 13 | +3 Will, STAND_FAST, 2d6 prot |
| 39 | Mail Corslet of Gundor | Corslet | 5 | +1 STR, grants Crowd Fighting |
| 40 | Hauberk of Nevrast | Hauberk | 11 | SUST_GRA, SUST_STR, 2d8 prot (heaviest at 50.0 lbs) |
| 41 | Mithril Corslet 'Starlight' | Mithril | 16 | +1 Perception, +1 Song, RES_FEAR, RES_BLIND, Song of Elbereth |

#### Shield Artifacts

| # | Name | Base | Depth | Key Properties |
|---|------|------|-------|----------------|
| 42 | Round Shield of Bloody Hand | Round | 6 | +1 STR, DAMAGE_SIDES, TRAITOR |
| 43 | Round Shield of Glorfindel | Round | 8 | Grants Charge, [+1, 1d4] |
| 44 | Round Shield 'Thandrach' | Round | 3 | +2 Will, grants Curse Breaking |
| 45 | Kite Shield of Hador | Kite | 8 | RES_FIRE, RES_COLD |
| 46 | Kite Shield of Fingolfin | Kite | 13 | +1 CON, SUST_CON, RES_FEAR, 1d8 prot |
| 47 | Mithril Shield of Valinor | Mithril | 18 | +1 GRA, LIGHT, [+1, 1d6] |
| 48 | Kite Shield of the Swan | Kite | 10 | +4 Will, SUST_CON, SUST_DEX, 1d7 prot |

#### Sword Artifacts

| # | Name | Base | Depth | Key Properties |
|---|------|------|-------|----------------|
| 52 | Dagger of Nargil | Dagger | 7 | (+5, 1d5), SHARPNESS, THROWING |
| 53 | Dagger 'Thorn' | Dagger | 0 | (+0, 1d6), BRAND_POIS, STEALTH, VAMPIRIC, HUNGER |
| 54 | Dagger 'Angrist' | Dagger | 14 | (+0, 1d5), SHARPNESS2 (double sharpness!) |
| 55 | Curved Sword 'Nakh' | Curved | 4 | +2 STR, NEG_GRA, SLAY_MAN_OR_ELF, AGGRAVATE |
| 56 | Curved Sword 'Agarlhang' | Curved | 8 | VAMPIRIC, WILL, PERCEPTION, NEG_CON, HUNGER |
| 58 | Shortsword of Amrod | Short | 8 | (+1, 1d7, +1), +2 Stealth, +2 Perception, FREE_ACT |
| 59 | Shortsword 'Dagmor' | Short | 12 | (+2, 1d8, +1), +1 GRA, RES_FEAR, LIGHT |
| 60 | Shortsword of Galadriel | Short | 9 | (+0, 1d8, +3), SUST_GRA, grants Riposte |
| 64 | Longsword 'Orcrist' | Long | 10 | (+2, 2d5, +2), +2 Perception, SLAY_ORC, SLAY_TROLL |
| 65 | Longsword 'Glamdring' | Long | 14 | (+2, 2d5, +2), +2 Will, SLAY_ORC/TROLL/DRAGON/RAUKO |
| 66 | Longsword 'Narsil' | Long | 12 | (+0, 2d6, +2), LIGHT, RES_FIRE, RES_COLD |
| 67 | Longsword 'Aranruth' | Long | 20 | (+3, 2d7, +1), +3 Will, RES_FEAR, DANGER |
| 71 | Bastard Sword 'Anguirel' | Bastard | 15 | (+1, 3d4, +1), SHARPNESS, TRAITOR |
| 72 | Bastard Sword 'Luinmegil' | Bastard | 11 | (-2, 3d4, +1), ACCURATE, RES_COLD, FREE_ACT |
| 74 | Greatsword 'Glend' | Great | 12 | (-1, 3d6, +1), +1 STR, SUST_STR (auto-drop) |
| 75 | Greatsword of Saithnar | Great | 17 | (+0, 3d5, +1), SHARPNESS, SLAY_UNDEAD, HAUNTED, SEE_INVIS |
| 76 | Greatsword 'Calris' | Great | 15 | (-5, 3d7, +1), +1 CON, BRAND_FIRE, LIGHT, VUL_COLD, CURSED |
| 80 | Mithril Longsword 'Celeg Aithorn' | MithLong | 20 | (+1, 2d5, +1), BRAND_ELEC, SHARPNESS |
| 81 | Mithril Longsword 'Ringil' | MithLong | 20 | (+3, 2d5, +3), +1 pval, BRAND_COLD, LIGHT |
| 83 | Mithril Greatsword 'Ungoliant's Lament' | MithGreat | 12 | (-2, 3d7, +2), SLAY_SPIDER, LIGHT, FREE_ACT, RES_POIS |

#### Polearm/Axe Artifacts

| # | Name | Base | Depth | Key Properties |
|---|------|------|-------|----------------|
| 85 | Spear 'Dugrakh' | Spear | 6 | (+1, 1d11), SLAY_RAUKO, SLAY_MAN_OR_ELF, SEE_INVIS, FREE_ACT, -1 GRA, AGGRAVATE |
| 86 | Spear of Boldog | Spear | 8 | (+0, 1d12), RES_FEAR, SLAY_WOLF (auto-drop) |
| 87 | Spear 'Aeglos' | Spear | 14 | (+1, 1d9), BRAND_COLD |
| 89 | Great Spear of Ogbar | Great Spear | 12 | (+2, 1d14, +2), SHARPNESS, SLAY_SPIDER |
| 90 | Great Spear of Melkor | Great Spear | 15 | (+1, 1d15, +1), -1 GRA, BRAND_POIS, FREE_ACT, VUL_POIS, CURSED |
| 92 | Hand Axe 'Binahkram' | Hand Axe | 6 | (+0, 4d3), +1 CON, SLAY_ORC, SLAY_SPIDER |
| 93 | Battle Axe 'Dramborleg' | Battle | 12 | (-2, 3d6), SLAY_RAUKO, SLAY_ORC, SLAY_TROLL |
| 94 | Battle Axe of Mothers' Woe | Battle | 15 | (-3, 3d5), +1 STR, +1 CON, HAUNTED, VAMPIRIC |
| 95 | Great Axe of Dolmed | Great | 18 | (-4, 4d5), +1 STR, SLAY_RAUKO, RES_FIRE |
| 96 | Great Axe 'Mazarbulbark' | Great | 14 | (-3, 4d4), +3 Will, SLAY_TROLL, grants Vengeance |
| 99 | Glaive of Gaurin | Glaive | 12 | (-1, 2d9, +1), +3 TUNNEL, SHARPNESS |
| 100 | Glaive of the Sirion | Glaive | 10 | (+0, 2d10, +1), grants Zone of Control + Opportunist |
| 101 | Glaive 'Celebrist' | Glaive | 8 | (+0, 2d10, +2), +1 DEX, FREE_ACT, NEG_CON |

#### Blunt Weapon Artifacts

| # | Name | Base | Depth | Key Properties |
|---|------|------|-------|----------------|
| 104 | Quarterstaff of Halmir | Staff | 2 | (+0, 2d4, +3), +3 pval, SUST_STR, SUST_CON, RES_POIS, Song of Freedom |
| 107 | War Hammer of Telchar | Hammer | 11 | (+0, 4d2), SUST_STR, RES_FIRE, grants Artifice |
| 108 | War Hammer of Aule's Wrath | Hammer | 20 | (+0, 4d2), +1 STR, +1 CON, SLAY_RAUKO, RES_FIRE, DANGER, AGGRAVATE |

#### Other Artifact Types

**Bows:** Shortbow of Celegorm (d7+1att, grants Ambush), 'Death's Sting' (d8+1att, grants Crippling Shot), 'Belthronding' (2d6+1att, +2 Perception), 'Tawarcun' (2d5+2att, FREE_ACT, ACCURATE), Dragon-horn of Avernien (4d3+1att, RADIANCE, RES multi)

**Arrows:** 'Dailir' (+11 attack, the unerring arrow of Beleg)

**Boots:** of Finrod ([+3, 1d1], FREE_ACT), of Taur-nu-Fuin (+2 Stealth, +2 Perception, grants Master Hunter), of the Mole (grants Vanish + Dodging, 1d2)

**Greaves:** of Orodreth (+1 DEX, RES_FIRE), of the Helcaraxe (RES_COLD, REGEN, all sustains)

**Gloves:** of the Swallow (+2 Archery, grants Fletchery), of Celebrimbor (grants Expertise, FREE_ACT), of Rumil (+1 GRA, grants Subtlety), 'Azdulag' (+1 STR, DARKNESS, grants Knockback), of Bregolas (+2 attack, RES_COLD), 'Silverhand' (+1 DEX, grants Jeweller)

**Helms:** of Angrod (RES_COLD, RES_FEAR, REGEN), of Curufin (+2 Perception, +2 Stealth, RES_CONFU, DANGER, grants Listen), of Dor-Lomin (+1 STR, RES_FEAR, RES_STUN, +1 Will), of the Dwarrowdelf (+2 Will, RES_FIRE, grants Strength in Adversity), of Ecthelion (+2 Song, RES_FIRE, RES_FEAR, grants Song of Staying)

**Cloaks:** of Maglor (+2 Song, grants Song of Trees), of Thingol (RES_FIRE, RES_COLD, FREE_ACT), of Luthien (pval 4 Stealth, DARKNESS, SUST_GRA, [+4, 1d0], grants Song of Lorien), of Draugluin (auto-drop, +2 Stealth, grants Disguise), of Thuringwethil (auto-drop, +2 Stealth, grants Disguise)

**Light Sources:** Lesser Jewel of Finwe (RES_FIRE, LIGHT, +2 pval)

### 3.3 Morgoth Artifacts

| # | Name | Properties |
|---|------|------------|
| 175-178 | Massive Iron Crown of Morgoth | 4 variants (0-3 Silmarils). Pval 0/4/5/6. Auto-drop. |
| 179 | Mighty Hammer 'Grond' | (-9, 6d5), +3 pval, TUNNEL. Auto-drop. |

### 3.4 Smithing Template Artifacts (182-198)

These define WHAT FLAGS can appear on self-made artifacts per item type. They are not real items. Key observations:

- **Swords/Polearms/Hafted** can have: All stats, all skills, TUNNEL, SHARPNESS, VAMPIRIC, CHEAT_DEATH, ACCURATE, all slays, all brands, all sustains, all resists, all misc abilities, all curses
- **Digging** tools: Limited -- no GRA, no SONG, no SHARPNESS, no CHEAT_DEATH
- **Bows**: No stats/slays/brands, but can have: RES multi, RADIANCE, PERCEPTION, STEALTH, ACCURATE
- **Arrows**: Only slays, brands, SHARPNESS
- **Rings**: STR, DEX, Archery, Stealth, Perception, all resists, SPEED, MEDIC, REGEN, SEE_INVIS, FREE_ACT
- **Amulets**: CON, GRA, Stealth, Perception, Will, Song, CHEAT_DEATH, MEDIC, all resists
- **Armor/Mail**: All stats, all skills, STAND_FAST, all sustains, all resists, SPEED
- **Cloaks**: DEX, CON, Stealth, Song, limited resists, FREE_ACT
- **Shields**: STR, CON, Will, CHEAT_DEATH, DAMAGE_SIDES, all sustains, most resists
- **Helms**: STR, CON, GRA, Perception, Will, Song, LIGHT, REGEN, SEE_INVIS, all resists
- **Boots**: DEX, Stealth, STAND_FAST, RADIANCE, FREE_ACT, SPEED, AVOID_TRAPS, some resists
- **Gloves**: STR, DEX, Archery, MEDIC, REGEN, FREE_ACT, RES_BLEED

---

## 4. Smithing / Forging System

### 4.1 Core Architecture (cmd4.c)

Smithing is SilQ's defining crafting system. Players stand on a forge and design items from scratch.

#### Smithing Menu Structure
1. **Create** -- Choose base item type (tval) and subtype (sval)
2. **Enchant** -- Apply ego/special item template (from special.txt)
3. **Artefact** -- Make it a custom artifact (fully customizable flags)
4. **Numbers** -- Adjust attack, damage dice/sides, evasion, protection dice/sides, pval, weight
5. **Melt** -- Melt mithril items down for material
6. **Accept** -- Finalize and create the item

#### Smithing Abilities (Skill Tree, ability.txt)
The Smithing skill tree has 8 abilities:

| Ability | Level | Effect |
|---------|-------|--------|
| Weaponsmith | 2 | Create weapons |
| Armoursmith | 3 | Create armor |
| Jeweller | 4 | Create rings, amulets, horns, light sources. Also identifies these on sight. |
| Enchantment | 5 | Create {special} ego items. Also identifies enchantments on sight. |
| Expertise | 6 | Halves forging time, negates ALL experience and stat costs. (Requires Enchantment) |
| Artifice | 7 | Create fully custom artifacts. (Requires Jeweller + Enchantment) |
| Masterpiece | 8 | Forge items above your skill level by permanently draining Smithing skill. (Requires Enchantment) |
| Grace | 10 | +1 Grace (capstone stat boost) |

### 4.2 Forge Types and Uses

Three forge tiers, determined when the forge is placed:

| Forge Type | Bonus | Uses | Generation |
|------------|-------|------|------------|
| Normal | +0 | 2+1d2 (3-4) | Default |
| Enchanted | +3 | 2+1d2 (3-4) | power >= 990 (1% per depth roll) |
| Unique (Orodruth) | +7 | 3 | power >= 1000 AND not yet made |

**Forge generation math:** Roll `dieroll(1000)` once per dungeon depth, keep max. At depth 1: one roll, need 990+ for enchanted = 1.1% chance. At depth 10: ten rolls, probability of at least one 990+ = ~10%. Unique requires exactly 1000 (0.1% per roll).

**Guaranteed forges:** At depths 2, 6, 10 (100ft, 300ft, 500ft). System tracks `fixed_forge_count` and forces vault placement with forge on these levels.

**Depth 1-2 forges:** Always Normal type with exactly 3 uses (anti-scumming).

### 4.3 Cost System (smithing_cost_type)

Each forged item has multiple simultaneous costs:

```c
typedef struct smithing_cost_type {
    int str;          // Strength drain
    int dex;          // Dexterity drain
    int con;          // Constitution drain
    int gra;          // Grace drain
    int exp;          // Experience cost
    int mithril;      // Mithril weight needed (for mithril items)
    int uses;         // Forge uses consumed (1 normal, 3 for artifacts)
    int drain;        // Permanent Smithing skill drain (Masterpiece ability)
    int weaponsmith;  // Requires Weaponsmith ability
    int armoursmith;  // Requires Armoursmith ability
    int jeweller;     // Requires Jeweller ability
    int enchantment;  // Requires Enchantment ability
    int artifice;     // Requires Artifice ability
} smithing_cost_type;
```

**Stat drain floor:** Stats can be drained to -5 minimum. If draining further would go below -5, the item is unaffordable.

**Expertise ability eliminates:** str, dex, con, gra, and exp costs entirely. This is the key high-level smithing ability.

### 4.4 Difficulty Calculation (object_difficulty)

The difficulty score determines whether you can make an item. Your effective skill = `smithing_skill + forge_bonus`. If difficulty > effective skill, the item fails UNLESS you have Masterpiece (which drains permanent smithing skill for the excess).

#### Base Difficulty
- **Base item:** `item_level / 2`
- **Horns:** `item_level - 1`
- **Rings/Amulets:** No base difficulty (they're pure flag items)

#### Stat Bonuses (per point)
- **Attack bonus (weapons):** base 3 per point, triangular scaling
- **Attack bonus (armor):** base 6 per point, -1 discount
- **Damage sides:** base `3 * sides + 2` per side (expensive, accelerating)
- **Protection (normal):** base 3 per point
- **Protection (hauberks):** base 1 per point + 2 (cheaper on heavy armor)
- **Protection (rings):** base 1 per point + 4 (expensive on rings)
- **Evasion:** base 6 per point, -1 discount

#### Flag Difficulty Costs
| Flag Category | Difficulty | Stat Cost |
|---------------|-----------|-----------|
| **Slays** | | |
| Slay Orc | +3 | -- |
| Slay Troll | +3 | -- |
| Slay Wolf | +3 | -- |
| Slay Undead | +3 | -- |
| Slay Spider | +4 | -- |
| Slay Rauko | +4 | -- |
| Slay Dragon | +4 | -- |
| Slay Man/Elf | +5 | -- |
| **Brands** | | |
| Brand Fire | +14 | 2 STR |
| Brand Poison | +16 / +12 (arrows) | 2 / 1 STR |
| Brand Cold | +18 | 2 STR |
| Multiple brands | +20 per extra brand | -- |
| **Melee Powers** | | |
| Sharpness | +24 / +14 (arrows) | 2 / 1 STR |
| Sharpness2 | +40 | 4 STR (not available in smithing) |
| Vampiric | +6 | 1 STR |
| Accurate | +15 | 1 DEX |
| **Stats (per pval)** | | |
| STR/DEX/CON/GRA bonus | base 14 | 1 per pval of same stat |
| Stat penalty | base 12 (reduces difficulty) | -- |
| **Skills (per pval)** | | |
| Archery/Stealth/Song | base 4 | -- |
| Perception/Will | base 3 | -- |
| Tunnel | base 8 | 1 STR per pval |
| Damage Sides (pval) | base 18 | 1 STR per pval |
| **Sustains** | | |
| Each sustain | +2 | -- |
| **Resistances** | | |
| Res Fire/Cold/Poison | +5 | -- |
| Res Bleed | +1 | -- |
| Res Blind | +2 | -- |
| Res Confusion | +2 | -- |
| Res Stun | +2 | -- |
| Res Fear | +2 | -- |
| Res Hallucination | +1 | -- |
| **Miscellaneous** | | |
| Slow Digest | +2 | -- |
| Radiance | +6 | 1 GRA |
| Light | +8 | 1 GRA |
| Regeneration | +4 | -- |
| See Invisible | +4 | -- |
| Free Action | +7 | -- |
| Speed | +40 | 5 CON |
| Cheat Death | +13 | -- |
| Stand Fast | +2 | -- |
| Avoid Traps | +6 | -- |
| Medic | +4 | -- |
| **Abilities (from ability.txt)** | | |
| Each ability | +5 + (ability_level / 3) | 50 * ability_level XP |
| **Penalties (reduce difficulty)** | | |
| Danger | -5 | -- |
| Darkness | -3 | -- |
| Aggravate | -3 | -- |
| Haunted | -5 | -- |
| Vul Cold/Fire/Poison | -4 each | -- |
| Traitor | -2 | -- |
| Light Curse | -2 | -- |
| Cumbersome | -3 | -- |

#### Difficulty Multipliers
- **Minor slots** (rings, light, cloak, gloves, boots, arrows): +20% difficulty
- **ENCHANTABLE items** (Robe, Quarterstaff): -30% difficulty
- **Artefact arrows** (single arrow): 50% difficulty

#### Artifact Cost
- Artifacts use **3 forge uses** (vs 1 for normal items)
- An enchanted/unique forge is almost required (need enough uses)

### 4.5 Mithril System

Mithril items (Mithril Corslet, Mithril Shield, Mithril Helm, Mithril Gauntlets, Mithril Greaves, Mithril Longsword, Mithril Greatsword, Feanorian Lamp) require mithril material to forge.

- **Cost:** Item weight in tenth-pounds of mithril
- **Source:** Pieces of Mithril (tval 4, "Small shining pieces of true silver") found at depth 15+
- **Melting:** Existing mithril items can be melted at a forge for material

### 4.6 Time Cost

Forging takes turns: `MAX(10, difficulty * turn_multiplier)`. Expertise halves the turn_multiplier. During forging, you are vulnerable.

---

## 5. Item Generation System

### 5.1 Object Allocation (A: lines in object.txt)

Each item has depth/rarity pairs. Example: Arrow at `A:2/1:6/1:11/1:17/1` means available starting at depth 2 with rarity 1, also at depths 6, 11, 17 (ensuring arrows appear throughout the game).

### 5.2 Fine and Special Rolls

When an item is generated:

1. **Fine roll:** `percent_chance(level * 2)` -- at depth 10, 20% chance
2. **Special roll:** `percent_chance(level)` -- at depth 10, 10% chance
3. **Good drops** guarantee: fine OR special (50/50)
4. **Great drops** guarantee: fine AND special

**Fine effects:**
- Weapons: +1 damage side OR +1 attack (50/50, small chance of both)
- Armor: +1 protection side OR fix a penalty (+att or +evn)
- Arrows: +3 attack

**Special effects:** Apply an ego item template (from special.txt)

### 5.3 Ego Item Selection

The `make_special_item()` function:
1. Takes current `object_level` (can be boosted by `GREAT_SPECIAL` = occasional deep boost)
2. Filters ego items by: depth <= level, tval match, sval range match
3. If `only_good`: excludes cursed and zero-cost egos
4. Weighted random selection by rarity

### 5.4 Artifact Generation

**Artifact rolls:** 0 normally, 1 if special, 3 if great, 8 if good+great

**Diminishing returns:** `too_many_artefacts()` -- for each artifact already generated, 10% chance to block the next one. After 7 artifacts: ~52% blocking chance.

**Depth enforcement:** Artifacts have minimum depth. Out-of-depth factor = `(art_level - depth) * 2`. Must pass a d100 roll against this.

### 5.5 Forge Generation in Dungeon

Forges are placed inside vault rooms (build_type6). Guaranteed forge levels at depths 2, 6, 10 (100ft, 300ft, 500ft). Additional forges may appear in random vaults. Forge type (Normal/Enchanted/Unique) is rolled at placement time based on depth.

---

## 6. Design Analysis: What Makes It Work

### 6.1 The Core Tension: Power vs. Cost

SilQ's item system creates meaningful choices through multiple simultaneous tradeoffs:

1. **Attack vs. Evasion vs. Protection:** Every piece of equipment pulls you in different directions. Mail Corslet gives 2d4 protection but costs -1 attack and -3 evasion. You can't stack everything.

2. **Stat bonuses vs. penalties:** The best ego items often come with curses. Fury gives Whirlwind Attack but AGGRAVATE. Feanorians give GRA+DEX but DANGER. Vampiric heals but causes HUNGER.

3. **Weight vs. power:** Heavier weapons do more damage but limit STR bonus per die. Heavier armor protects more but reduces evasion. This creates natural build divergence.

### 6.2 The Enchantment Ecosystem

Key design patterns:

**Thematic enchantments tied to lore:** "of Gondolin" (anti-orc/troll), "of Doriath" (anti-spider/wolf), "of Nargothrond" (anti-demon/dragon). Each name evokes the in-game faction and what they fought against.

**Enchantments solve specific problems:**
- Fire-breathing dragons? -> RES_FIRE (Frost ring, Dwarf Mask, Shield of Frost)
- Paralysis? -> FREE_ACT (Ring, Brethil armor, many artifacts)
- Fear effects? -> RES_FEAR (Ered Luin ring, Defiance helm, Iron Hills armor)
- Stealth builds? -> STEALTH on armor, boots, cloaks, daggers

**Item-specific enchantments create identity:** Murder daggers (+stealth, assassination), Battering hammers (knockback), Piercing spears (impale). These make weapon choices meaningful beyond raw numbers.

**Cursed items as risk-reward:** Every slot has at least one cursed ego. Helm of Terror, Cloak of Winter's Chill, Shield of Wrath, Boots of Treacherous Paths. They offer cheap difficulty reduction for smithing (penalties reduce difficulty) but carry real gameplay costs.

### 6.3 The Smithing System as Strategic Layer

SilQ's smithing transforms itemization from "find loot" to "plan your build":

1. **Forge scarcity:** Only ~3-5 forges per game, each with limited uses. You must plan what to make.

2. **Progressive unlocks:** Weaponsmith (level 2) -> Enchantment (level 5) -> Artifice (level 7). Early forges make basic items; later forges make masterworks.

3. **Stat drain as permanent cost:** Making a +2 STR ring costs 2 STR permanently. You're investing your CHARACTER's stats into your ITEM's stats. This is brilliant -- it means smithing is never free.

4. **Expertise as the master ability:** At level 6 Smithing, all stat/exp costs vanish. This is the inflection point where smithing becomes the dominant strategy.

5. **Forge types as treasure:** Finding an Enchanted forge (+3) or the Unique forge (+7) is as exciting as finding an artifact. It enables items you couldn't otherwise make.

### 6.4 The "Fine" vs "Special" Split

SilQ separates stat bonuses (fine) from enchantments (special). Items can be:
- Plain: Base stats only
- Fine: +1 to a stat (attack, damage, evasion, protection)
- Special: Has an ego enchantment
- Fine + Special: Both (requires great roll or high level)

This means a "fine shortsword" (+1 attack) and a "shortsword of Gondolin" (slay orc/troll) are different items that stack. A "fine shortsword of Gondolin" is the jackpot.

### 6.5 Depth-Scaling Item Power

Several items scale with depth:
- Ring of Evasion/Accuracy: `(level + 1d10) / 9`
- Ring of Protection: `(level + 1d10) / 14 + 1`
- Ring of Strength/Dexterity: `(level + 1d15) / 20`
- Amulet of Constitution/Grace: `(level + 1d15) / 20`

This means the same ring found at depth 5 vs depth 20 is significantly different. Deep exploration is rewarded with mechanically superior versions of familiar items.

### 6.6 Flag Categories and Their Roles

| Category | Purpose | Example |
|----------|---------|---------|
| Slays | Counter specific enemy types | SLAY_ORC (+1 damage die vs orcs) |
| Brands | Universal damage boost | BRAND_FIRE (+1d die, fire damage) |
| Resistances | Survive specific threats | RES_FIRE (halves fire damage) |
| Stat bonuses | Character improvement | +STR, +DEX, +CON, +GRA |
| Skill bonuses | Build specialization | +Stealth, +Perception, +Will, +Song |
| Sustains | Prevent stat drain | SUST_STR (immune to strength drain) |
| Abilities | Grant new game mechanics | Grants Dodging, Assassination, Parry, etc. |
| Curses | Risk-reward tradeoffs | DANGER, AGGRAVATE, HUNGER, FEAR |

### 6.7 What to Steal for Necromancer

1. **Protection dice, not flat numbers.** SilQ uses `XdY` for armor protection -- this creates variance and makes armor interesting. A 2d4 corslet blocks 2-8 damage; a 1d8 galvorn blocks 1-8. Same average, different distributions.

2. **Attack/evasion penalties on heavy items.** Mail should cost evasion AND attack. This forces real choice between offensive and defensive builds.

3. **Item-specific enchantment restrictions.** "of Gondolin" only on swords/spears/arrows, not axes. "of Murder" only on daggers/curved swords. This gives each weapon type a unique identity.

4. **Cursed ego items with real benefits.** Fury's Whirlwind Attack is amazing but AGGRAVATE makes stealth impossible. These are the most interesting loot decisions.

5. **Granted abilities on items.** Items that give you game abilities (Parry, Dodging, Assassination) are far more exciting than +1 to a stat. They change how you play.

6. **Depth-scaling ring/amulet values.** Same ring type, better deep. Simple but effective.

7. **Fine vs. Special as independent rolls.** Don't make all enchanted items also have stat bonuses. Let them be separate axes of quality.

8. **Smithing as permanent investment.** The stat drain mechanic (spend your stats to make items) is one of the best crafting costs in any roguelike.

---

## Appendix A: Flag Reference

### Positive Flags
- **STR/DEX/CON/GRA**: +pval to stat
- **ARCHERY/STEALTH/PERCEPTION/WILL/SONG**: +pval to skill
- **TUNNEL**: +pval to digging
- **DAMAGE_SIDES**: +pval to damage sides (shields only)
- **SLAY_ORC/TROLL/WOLF/SPIDER/UNDEAD/RAUKO/DRAGON/MAN_OR_ELF**: Extra damage die vs type
- **BRAND_FIRE/COLD/POIS/ELEC**: Extra damage die of element
- **SHARPNESS/SHARPNESS2**: Chance to bypass armor (1/sharpness or 2/sharpness)
- **VAMPIRIC**: Heal on hit
- **ACCURATE**: Extra die for critical hits
- **SUST_STR/DEX/CON/GRA**: Immune to stat drain
- **RES_FIRE/COLD/POIS**: Halve elemental damage
- **RES_FEAR/BLIND/CONFU/STUN/HALLU/BLEED**: Resist status effects
- **FREE_ACT**: Resist paralysis/slow
- **SEE_INVIS**: See invisible creatures
- **REGEN**: Faster HP regeneration
- **SLOW_DIGEST**: Slower hunger
- **LIGHT**: Increase light level
- **RADIANCE**: Light area effect
- **SPEED**: +1 movement speed (extremely rare)
- **CHEAT_DEATH**: Avoid one lethal blow
- **STAND_FAST**: Resist knockback
- **AVOID_TRAPS**: Don't trigger traps
- **MEDIC**: Bonus to healing herbs/potions
- **ENCHANTABLE**: -30% smithing difficulty
- **MITHRIL**: Requires mithril to forge, IGNORE_ALL

### Negative Flags
- **NEG_STR/DEX/CON/GRA**: -pval to stat
- **DANGER**: Monsters are more alert near you
- **AGGRAVATE**: All monsters wake up and become alert
- **HUNGER**: Faster hunger
- **DARKNESS**: Reduces light radius
- **HAUNTED**: Occasionally get confused/frightened
- **FEAR**: Permanently afraid
- **VUL_FIRE/COLD/POIS**: Take extra elemental damage
- **TRAITOR**: Occasionally attack allies
- **LIGHT_CURSE**: Item is cursed (can't remove without Curse Breaking)
- **CUMBERSOME**: Penalty to combat speed

### Item Type Flags
- **TWO_HANDED**: Requires both hands
- **HAND_AND_A_HALF**: Can be used one or two handed
- **THROWING**: Can be thrown
- **POLEARM**: Benefits from Polearm Mastery
- **AXE**: Axe-specific interactions
- **INSTA_ART**: Always generated as artifact (never as base item)
- **NO_SMITHING**: Cannot be forged
- **MORE_SPECIAL**: 50% bonus chance to become ego item
- **DAMAGED**: Damaged/broken item (floor loot only)
- **EASY_KNOW**: Automatically identified

---

## Appendix B: Smithing Ability Requirements Summary

To forge different item categories, you need:

| Item Category | Required Ability | Smithing Level |
|---------------|-----------------|----------------|
| Weapons (swords, axes, etc.) | Weaponsmith | 2 |
| Armor (mail, shields, etc.) | Armoursmith | 3 |
| Jewelry (rings, amulets, etc.) | Jeweller | 4 |
| Ego items ({special}) | Enchantment | 5 |
| Custom artifacts | Artifice | 7 |

Additional modifiers:
- **Expertise** (level 6): Eliminates ALL stat and XP costs
- **Masterpiece** (level 8): Allows exceeding difficulty cap by draining smithing skill permanently
