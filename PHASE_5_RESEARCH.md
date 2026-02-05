# Phase 5 Research Results - Verified Formulas

## R1 - Stat Allocation (birth.c:1555-1558)

**Total Points:** 13
**Stat Range:** -4 to +6 (after race/house bonuses applied)

**Cost Curve:**
```gdscript
const STAT_COSTS: Array[int] = [-4, -3, -2, -1, 0, 1, 3, 6, 10, 15, 21]
# Index = stat_value + 4
# Example: stat of +3 costs STAT_COSTS[3+4] = STAT_COSTS[7] = 6 points
```

| Stat Value | Point Cost |
|------------|------------|
| -4 | -4 (refund) |
| -3 | -3 (refund) |
| -2 | -2 (refund) |
| -1 | -1 (refund) |
| 0 | 0 |
| +1 | 1 |
| +2 | 3 |
| +3 | 6 |
| +4 | 10 |
| +5 | 15 |
| +6 | 21 |

---

## R3 - Skill XP Cost (birth.c:1735-1745)

**Formula:** Triangular number × 100
```gdscript
func skill_cost(current_level: int, points_to_buy: int) -> int:
    var total: int = (current_level + points_to_buy) * (current_level + points_to_buy + 1) / 2
    var prev: int = current_level * (current_level + 1) / 2
    return (total - prev) * 100
```

**Simplified:** nth skill point costs `100 * n` XP

| From → To | XP Cost |
|-----------|---------|
| 0 → 1 | 100 |
| 1 → 2 | 200 |
| 2 → 3 | 300 |
| 5 → 6 | 600 |
| 0 → 3 | 600 (100+200+300) |

**Starting XP:** 5000

---

## R6 - Combat Opposed Rolls (cmd1.c:800-850)

**Hit Roll:**
```gdscript
func hit_roll(attack_mod: int, evasion_mod: int) -> int:
    var attack_score: int = randi_range(1, 20) + attack_mod
    var evasion_score: int = randi_range(1, 20) + evasion_mod
    return attack_score - evasion_score
# Positive = hit, negative = miss
# Margin used for criticals
```

**Critical Bonus Dice (cmd1.c:1184-1236):**
```gdscript
func crit_bonus(hit_result: int, weapon_weight: int) -> int:
    var crit_separation: int = 70
    # Abilities modify crit_separation:
    # MEL_FINESSE: -20 (easier crits)
    # MEL_CONTROL: -20 (one-handed weapons)
    # MEL_POWER: +10 (harder crits, more damage)

    var crit_dice: int = (hit_result * 10 + 4) / (crit_separation + weapon_weight)
    return max(0, crit_dice)
```

---

## R2 - Item P: Line Format (object.txt)

**Correct Format:**
```
P: attack_bonus : damage_dice : evasion_bonus : protection_dice
```

**Examples:**
- `P:0:1d5:0:0d0` - Dagger: +0 att, 1d5 dmg, +0 evn, 0 prot
- `P:-7:6d5:0:0d0` - Grond: -7 att, 6d5 dmg, +0 evn, 0 prot
- `P:-2:0d0:-4:2d5` - Heavy Mail: -2 att, 0 dmg, -4 evn, 2d5 prot

**Current parsing is WRONG - fields misnamed as ac, to_hit, to_dam, to_ac**

---

## R4 - Race.txt Line Types

| Line | Format | Example |
|------|--------|---------|
| N | `N:index:name` | `N:0:Elf` |
| S | `S:str:dex:con:gra` | `S:-1:2:1:2` |
| I | `I:history:agebase:agemax` | `I:1:100:3000` |
| H | `H:base:mod` | `H:72:3` |
| W | `W:base:mod` | `W:140:8` |
| C | `C:house1\|house2\|...` | `C:0\|1\|2` |
| F | `F:flag1 \| flag2` | `F:BOW_PROFICIENCY` |
| E | `E:tval:sval:min:max` | `E:23:7:1:1` |
| D | `D:text` | `D:The Elves...` |

**Racial Flags:**
- BOW_PROFICIENCY, SWORD_PROFICIENCY, AXE_PROFICIENCY
- ARC_PENALTY

---

## R5 - House.txt Line Types

| Line | Format | Example |
|------|--------|---------|
| N | `N:index:name` | `N:0:Of Lothlorien` |
| A | `A:alternate` | `A:Lothlorien` |
| B | `B:short` | `B:Lorien` |
| F | `F:affinity` | `F:LOR_AFFINITY` |
| S | `S:str:dex:con:gra` | `S:0:0:0:1` |
| D | `D:text` | `D:The Galadhrim...` |

**Skill Affinities:**
- MEL_AFFINITY, ARC_AFFINITY, EVN_AFFINITY, STL_AFFINITY
- PER_AFFINITY, WIL_AFFINITY, SMT_AFFINITY, LOR_AFFINITY

---

## R7 - TVAL to Equipment Slot

| TVAL | Type | Slot |
|------|------|------|
| 17 | TV_ARROW | QUIVER |
| 19 | TV_BOW | BOW |
| 20 | TV_DIGGING | WEAPON |
| 21 | TV_HAFTED | WEAPON |
| 22 | TV_POLEARM | WEAPON |
| 23 | TV_SWORD | WEAPON |
| 30 | TV_BOOTS | FEET |
| 31 | TV_GLOVES | HANDS |
| 32 | TV_HELM | HEAD |
| 33 | TV_CROWN | HEAD |
| 34 | TV_SHIELD | OFF_HAND |
| 35 | TV_CLOAK | CLOAK |
| 36 | TV_SOFT_ARMOR | BODY |
| 37 | TV_MAIL | BODY |
| 39 | TV_LIGHT | LIGHT |
| 40 | TV_AMULET | NECK |
| 45 | TV_RING | RING_L / RING_R |

**Non-equippable:** 55 (staff), 56 (wand), 66 (horn), 75 (potion), 77 (flask), 80 (food)
