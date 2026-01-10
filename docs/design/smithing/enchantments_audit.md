# Enchantment System Audit

## Document: AUDIT-005
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document catalogs all ego items (enchantments) available through the Smithing system in The Necromancer.

---

## Special.txt File Format

```
N: serial number : special type name
C: max att : plus damage dice : plus damage sides : max evn :
   plus prot dice: plus prot sides : pval
W: depth : rarity : max_depth : cost
T: tval : min_sval : max_sval
F: FLAG1 | FLAG2 | ...
B: skill/ability (grants ability)
```

---

## Enchantment Categories

### Armor Enchantments (11 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 1 | of Protection | 0 | +1d prot, IGNORE_ALL | Shields, Greaves, Mail, Leather |
| 2 | of Venom's End | 0 | RES_POIS | Leather, Mail |
| 3 | of Resilience | 10 | +1 CON, IGNORE_ALL | Mithril/Galvorn |
| 4 | of the Woodmen | 6 | FREE_ACT, IGNORE_ALL | Leather, Gloves, Boots |
| 5 | of Stealth | 0 | +3 STEALTH | Leather, Mail |
| 6 | of Nogrod | 0 | SUST_ALL, IGNORE_ALL | Shields, Heavy armor, Greaves |
| 7 | of the Iron Hills | 0 | STAND_FAST, RES_FEAR | Iron Greaves, Heavy armor |
| 8 | of Dale | 8 | RES_COLD, IGNORE_ALL | Iron Gauntlets, Greaves |
| 9 | of Blight | 0 | VUL_POIS (cursed) | Leather, Mail |
| 10 | of the Ranger | 4 | +2 STEALTH, PERCEPTION | Leather, Cloaks, Boots |
| 11 | of Gondor | 6 | WILL, RES_FEAR | Heavy Mail, Shields |

### Shield Enchantments (4 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 12 | of Deflection | 0 | +2 EVN, IGNORE_ALL | All Shields |
| 13 | of Frost | 10 | RES_FIRE | All Shields |
| 14 | with Many Runes | 20 | CHEAT_DEATH | Mithril Shields only |
| 15 | of Wrath | 0 | AGGRAVATE (cursed) | Non-mithril Shields |

### Weapon Enchantments (30 types)

#### Slaying Weapons

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 21 | of Gondolin | 0 | SLAY_ORC, SLAY_TROLL | Swords, Spears, Glaives, Arrows |
| 22 | of Doriath | 2 | SLAY_SPIDER, SLAY_WOLF | Axes, Swords, Spears, Arrows |
| 23 | of Dragon-bane | 9 | SLAY_RAUKO, SLAY_DRAGON | Swords, Spears, Glaives |
| 24 | of Final Rest | 7 | SLAY_UNDEAD, FREE_ACT | Most melee weapons |
| 25 | of Westernesse | 6 | SLAY_UNDEAD, LIGHT | Swords |

#### Branded Weapons

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 42 | of Morgul | 10 | BRAND_COLD, DARKNESS, LIGHT_CURSE | Swords, Spears |
| 46 | (Poisoned) | 0 | BRAND_POIS | Daggers, Hand Axes |

#### Stat/Skill Weapons

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 20 | of Rivendell | 0 | +3 SONG, LIGHT, SUST_GRA/DEX | Daggers |
| 26 | of the Firebeards | 4 | REGEN, RES_FIRE | Hammers, Axes, Shovels |
| 30 | of Lothlórien | 8 | +2 GRA, PERCEPTION, LIGHT | Bows, Swords |
| 31 | of the Noldor | 12 | +1 GRA, DEX, DANGER | Swords |
| 32 | of the Mark | 6 | +1 ATT, RES_FEAR, FREE_ACT | Spears, Swords |
| 33 | of Erebor | 8 | +1d dam, +1 STR, RES_FIRE | Hammers, Axes |
| 34 | of Murder | 0 | +3 STEALTH, Assassination | Daggers, Curved Swords |
| 44 | of the Deeps | 2 | +1d dam, +1 CON, CUMBERSOME | Hammers, Curved, Axes |

#### Ability-Granting Weapons

| ID | Name | Depth | Ability | Applies To |
|----|------|-------|---------|------------|
| 27 | of the Edain | 8 | Follow-Through (0/5) | Heavy weapons |
| 28 | of Fury | 10 | Whirlwind Attack (0/8), AGGRAVATE | Heavy weapons |
| 35 | of Accompaniment | 0 | Two Weapon Fighting (0/11) | Daggers |
| 36 | of the Eorlingas | 10 | +1 ATT, +1d, +1 STR, RES_FEAR | Spears |
| 39 | of Battering | 0 | Knock Back (0/2) | Warhammers |
| 41 | of Piercing | 4 | Impale (0/6), +1d dam | Polearms |

#### Special Effect Weapons

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 29 | of Mirkwood | 4 | SLAY_SPIDER, +2 STEALTH | Bows, Spears |
| 37 | of Lothlórien | 0 | +1 ATT, REGEN | Quarterstaves |
| 38 | of the North | 2 | +1 CON, RES_COLD | Quarterstaves |
| 40 | of Crushing | 10 | +1d dam, +1 STR | Warhammers |
| 43 | of Shadow | 12 | VAMPIRIC, DARKNESS, HUNGER | Curved, Great weapons |
| 45 | of Mordor | 0 | +1d dam, SLAY_MAN_OR_ELF, AGGRAVATE | Curved, Axes |
| 47 | (Balanced) | 14 | ACCURATE | Most weapons |
| 48 | (Defender) | 0 | +1 EVN, IGNORE_ALL | Swords, Glaives |
| 49 | (Vampiric) | 4 | VAMPIRIC, HUNGER, LIGHT_CURSE | Heavy blades, Axes |

### Helm Enchantments (6 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 71 | of Brilliance | 0 | LIGHT | All Helms |
| 72 | of Defiance | 0 | +3 WILL, RES_FEAR | All Helms |
| 73 | of True Sight | 0 | RES_BLIND, SEE_INVIS, RES_HALLU | Helms, Lights |
| 74 | of Clarity | 0 | RES_CONFU, RES_STUN, RES_HALLU | All Helms |
| 75 | of Grace | 0 | +1 GRA | Mithril Helms, Lesser Jewels |
| 76 | of the Dwarrowdelf | 8 | +1 CON, WILL | Iron/Steel Helms |
| 80 | of Terror | 0 | FEAR (cursed) | Non-mithril Helms |

### Cloak Enchantments (5 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 82 | of Stealth | 0 | +3 STEALTH | All Cloaks |
| 83 | of Warmth | 4 | RES_COLD | All Cloaks |
| 84 | of the Traveller | 0 | SLOW_DIGEST | All Cloaks |
| 86 | of Winter's Chill | 0 | VUL_COLD (cursed) | All Cloaks |
| 87 | of the Tower | 0 | RES_BLEED, SUST_CON | Fine Cloaks |
| 88 | of the Golden Wood | 0 | RES_FEAR, SUST_GRA | Fine Cloaks |

### Bow Enchantments (6 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 91 | of Black Yew | 6 | +1d dam, VUL_FIRE | Longbows |
| 92 | of the Wild | 4 | RES_POIS, DANGER, AGGRAVATE | Shortbows |
| 93 | of Radiance | 6 | RADIANCE | All Bows |
| 94 | of the Marchwardens | 6 | SEE_INVIS, RES_FEAR | All Bows |
| 95 | of the Grey Havens | 12 | +3 PERCEPTION, RES_COLD | All Bows |
| 96 | of the Galadhrim | 12 | ACCURATE | All Bows |

### Arrow Enchantments (2 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 101 | (Poisoned) | 6 | BRAND_POIS | All Arrows |
| 102 | of Piercing | 10 | SHARPNESS | All Arrows |

### Boot Enchantments (5 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 110 | of Ithil's Light | 0 | RADIANCE | Mithril Greaves |
| 111 | of Softest Tread | 0 | +3 STEALTH | Boots |
| 112 | of Snares Eluded | 10 | AVOID_TRAPS, FREE_ACT | Mithril Greaves |
| 113 | of Speed | 10 | Sprinting ability (2/5) | Boots |
| 114 | of Leaping | 7 | Leaping ability (2/4) | Boots |
| 116 | of Treacherous Paths | 5 | DANGER (cursed) | All Boots/Greaves |

### Glove Enchantments (5 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 120 | of Archery | 2 | +3 ARCHERY | Gloves |
| 121 | of Healing | 0 | MEDIC | All Gloves |
| 122 | of Swordplay | 4 | Parry ability (2/2) | All Gloves |
| 123 | of the Iron Hills | 4 | +1 CON, NEG_DEX | Gauntlets |
| 124 | of Might | 10 | +1 STR | Mithril Gauntlets |
| 126 | of Treachery | 4 | +1 STR, Opportunist, LIGHT_CURSE | Gloves/Gauntlets |

### Light Source Enchantments (2 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 130 | of Brightness | 0 | LIGHT | Lesser/Silmaril Jewels, Lanterns |
| 135 | of Flickering Shadow | 0 | DARKNESS, LIGHT_CURSE (cursed) | Lanterns |

### Digging Tool Enchantments (2 types)

| ID | Name | Depth | Flags/Effects | Applies To |
|----|------|-------|---------------|------------|
| 51 | of Belegost | 0 | +1 TUNNEL | Mattocks |
| 52 | of the Longbeards | 0 | STR | Mattocks |

---

## Enchantment Flag Summary

### Defensive Flags

| Flag | Count | Description |
|------|-------|-------------|
| IGNORE_ALL | 17 | Immune to elements |
| RES_POIS | 3 | Resist poison |
| RES_COLD | 5 | Resist cold |
| RES_FIRE | 4 | Resist fire |
| RES_FEAR | 9 | Resist fear |
| RES_BLIND | 1 | Resist blindness |
| RES_CONFU | 1 | Resist confusion |
| RES_STUN | 1 | Resist stunning |
| RES_HALLU | 2 | Resist hallucination |
| RES_BLEED | 1 | Resist bleeding |
| FREE_ACT | 5 | Resist paralysis |

### Offensive Flags

| Flag | Count | Description |
|------|-------|-------------|
| SLAY_ORC | 1 | Bonus vs orcs |
| SLAY_TROLL | 1 | Bonus vs trolls |
| SLAY_SPIDER | 3 | Bonus vs spiders |
| SLAY_WOLF | 1 | Bonus vs wolves |
| SLAY_DRAGON | 1 | Bonus vs dragons |
| SLAY_RAUKO | 1 | Bonus vs raukos |
| SLAY_UNDEAD | 2 | Bonus vs undead |
| SLAY_MAN_OR_ELF | 1 | Bonus vs men/elves |
| BRAND_POIS | 3 | Poison damage |
| BRAND_COLD | 1 | Cold damage |
| VAMPIRIC | 2 | Life steal |
| SHARPNESS | 1 | Armor piercing |
| ACCURATE | 2 | +1 accuracy |

### Stat Bonuses

| Flag | Count | Description |
|------|-------|-------------|
| STR | 5 | Strength bonus |
| DEX | 1 | Dexterity bonus |
| CON | 5 | Constitution bonus |
| GRA | 3 | Grace bonus |
| STEALTH | 6 | Stealth bonus |
| PERCEPTION | 3 | Perception bonus |
| WILL | 3 | Will bonus |
| ARCHERY | 1 | Archery bonus |
| SONG | 1 | Song bonus |
| TUNNEL | 1 | Digging bonus |

### Utility Flags

| Flag | Count | Description |
|------|-------|-------------|
| LIGHT | 5 | Glows |
| RADIANCE | 3 | Radiates light |
| SEE_INVIS | 2 | See invisible |
| REGEN | 3 | Regeneration |
| SUST_* | 5 | Sustain stats |
| AVOID_TRAPS | 1 | Trap avoidance |
| SLOW_DIGEST | 1 | Less food needed |
| STAND_FAST | 1 | Cannot be pushed |
| MEDIC | 1 | Better healing |
| CHEAT_DEATH | 1 | Survive killing blow |

### Negative Flags

| Flag | Count | Description |
|------|-------|-------------|
| AGGRAVATE | 5 | Wake/anger monsters |
| DANGER | 3 | More dangerous encounters |
| HUNGER | 2 | Increased food consumption |
| LIGHT_CURSE | 5 | Minor curse |
| VUL_* | 3 | Vulnerability |
| NEG_DEX | 1 | Dexterity penalty |
| CUMBERSOME | 1 | Movement penalty |
| FEAR | 1 | Causes fear |
| DARKNESS | 3 | Reduces light |

---

## Ability-Granting Enchantments

| Enchantment | Ability | Skill/Index |
|-------------|---------|-------------|
| of the Edain | Follow-Through | 0/5 (Melee) |
| of Fury | Whirlwind Attack | 0/8 (Melee) |
| of Accompaniment | Two Weapon Fighting | 0/11 (Melee) |
| of Battering | Knock Back | 0/2 (Melee) |
| of Piercing | Impale | 0/6 (Melee) |
| of Speed | Sprinting | 2/5 (Evasion) |
| of Leaping | Leaping | 2/4 (Evasion) |
| of Swordplay | Parry | 2/2 (Evasion) |
| of Murder | Assassination | 3/1 (Stealth) |
| of Treachery | Opportunist | 3/4 (Stealth) |

---

## The Necromancer Modifications

The following enchantments have been renamed for Third Age lore:

| Old Name (First Age) | New Name (Third Age) | Reason |
|----------------------|----------------------|--------|
| of Cuivienen | of Rivendell | Elven haven |
| of Brethil | of the Woodmen | Mirkwood settlers |
| of Nargothrond | of Dragon-bane | Generic |
| of the Feanorians | of the Noldor | Same elves, different name |
| of Hador's House | of the Edain | Generic term |
| of the Vanyar | of the Eorlingas | Rohirrim cavalry |
| of Mithrim | of Lothlórien | Third Age Elven realm |
| of Helcaraxe | of the North | Dúnedain reference |
| of Ladros | of Dale | Third Age city |
| of Udun | of Shadow | Generic dark |
| of Thangorodrim | of the Deeps | Generic dwarven |
| of Black Iron | of Mordor | Third Age enemy |
| of Scarlet Heart | of the Tower | Gondor reference |
| of Golden Flower | of the Golden Wood | Lothlórien |
| of Blackened Yew | of Black Yew | Neutral |
| of Lammoth | of the Wild | Generic wilderness |
| of Falas | of the Grey Havens | Third Age port |
| of Falmari | of the Galadhrim | Lothlórien archers |
| of Lorellin | of Healing | Generic |
| of Ironfists | of the Iron Hills | Dwarven kingdom |

**New Third Age Enchantments Added:**
- of the Ranger (Dúnedain)
- of Gondor (soldiers)
- of Mirkwood (spider hunters)
- of Westernesse (ancient Dúnedain)
- of the Mark (Rohirrim)
- of Erebor (Lonely Mountain dwarves)
- of Morgul (enemy cursed weapons)
- of the Dwarrowdelf (Khazad-dûm)

---

## Smithing Implications

### Enchant Menu Availability

The Enchant (b) menu in the forge allows applying any ego appropriate for the selected base item type.

**Excluded from Enchanting:**
- Rings
- Amulets
- Horns
- Shovels
- Already-enhanced arrows

### Difficulty Costs

Each enchantment adds to the base item's difficulty:
- Stat bonuses (+pval)
- Protection bonuses
- Attack bonuses
- Flag complexity

### Key Observations

1. **Cursed items available** - Players can intentionally create cursed items with powerful bonuses and drawbacks
2. **Ability grants** - 10 enchantments provide free abilities, very powerful
3. **Material restrictions** - Many best enchantments require mithril base items
4. **Depth restrictions** - Some enchantments only appear after certain depths
5. **Third Age theme** - Names updated but mechanics preserved from Sil-Q

---

## Recommendations

### For Balance Analysis

1. Ability-granting enchantments may be too powerful
2. Cursed items provide interesting tradeoffs
3. Mithril-exclusive enchantments reward material hunting

### For UI Clarity

1. Show enchantment requirements clearly in forge menu
2. Indicate cursed status before crafting
3. Display ability grants prominently
