# Melee Proposal: Reworked Ability Tree

## Design Goals
1. Ground all abilities in Third Age precedents
2. Add stealth synergy (Opening Strike)
3. Remove non-Tolkien elements (dual wielding)
4. Keep interesting choices and trade-offs

## Proposed Ability Tree

### N:0 Power
**Effect**: +1 damage sides to melee attacks, increases crit base by 1
**Level**: 1
**Prereqs**: None
**Tolkien**: Boromir, Gimli - raw strength in combat
**Rationale**: UNCHANGED - solid foundation with meaningful trade-off

---

### N:1 Finesse
**Effect**: Lowers crit base from 7 to 5
**Level**: 2
**Prereqs**: None
**Tolkien**: Aragorn's precise swordwork
**Rationale**: UNCHANGED - good Power alternative

---

### N:2 Knock Back
**Effect**: Chance to push enemies back based on Str vs Con
**Level**: 3
**Prereqs**: None
**Tolkien**: Shield combat, driving back foes
**Rationale**: UNCHANGED - tactical utility

---

### N:3 Polearm Mastery
**Effect**: +2 attack with polearms, can set to receive advancing enemies
**Level**: 4
**Prereqs**: None
**Tolkien**: Gondorian spearmen, guards
**Rationale**: UNCHANGED - weapon specialization

---

### N:4 Charge
**Effect**: +3 Str/Dex when attacking after moving toward enemy
**Level**: 5
**Prereqs**: None
**Tolkien**: Theoden's death charge, Rohirrim tactics
**Rationale**: UNCHANGED - iconic tactic

---

### N:5 Follow-Through
**Effect**: Continue attack onto next adjacent enemy after kill
**Level**: 6
**Prereqs**: Power OR Finesse
**Tolkien**: Aragorn clearing through orcs at Amon Hen
**Rationale**: UNCHANGED - classic ability

---

### N:6 Opening Strike (NEW)
**Effect**: +1 damage die on first melee attack against unwary or sleeping enemy
**Level**: 7
**Prereqs**: Finesse
**Tolkien**: Ranger ambush tactics, Faramir's Ithilien ambushes
**Rationale**: NEW - Creates stealth synergy for melee builds. Rangers approach unseen, then strike decisively.
**Stealth Hook**: Major synergy - rewards stealth investment for warriors

---

### N:7 Subtlety
**Effect**: -2 to crit base when wielding one-handed weapon with other hand free
**Level**: 8
**Prereqs**: Finesse
**Tolkien**: Aragorn's Ranger fighting style, light and mobile
**Rationale**: UNCHANGED - excellent Ranger-style ability

---

### N:8 Controlled Fury (was Whirlwind Attack)
**Effect**: When you kill an enemy, get a free attack on ONE adjacent enemy
**Level**: 9
**Prereqs**: Polearm Mastery, Follow-Through
**Tolkien**: Battle momentum, pressing advantage
**Rationale**: MODIFIED - Reduced from "all adjacent" to "one adjacent". Still powerful but not mythic.

---

### N:9 Zone of Control
**Effect**: Free attack when enemy moves between two adjacent squares
**Level**: 10
**Prereqs**: Finesse, Polearm Mastery
**Tolkien**: Master swordsman controlling space
**Rationale**: UNCHANGED - good tactical depth

---

### N:10 Mighty Blow (was Smite)
**Effect**: First 2H attack each turn deals +Str bonus damage. If you use this, lose a turn to recover.
**Level**: 11
**Prereqs**: Knock Back, Charge
**Tolkien**: Desperate powerful strikes, last stands
**Rationale**: MODIFIED - Changed from "maximum damage" to "+Str". Still powerful but not guaranteed max.

---

### N:11 Defensive Stance (was Two Weapon Fighting)
**Effect**: When you don't move, gain +3 evasion and enemies don't get flanking bonuses against you
**Level**: 12
**Prereqs**: Finesse, Evasion:Blocking
**Tolkien**: Helm's Deep wall defenders, holding the line
**Rationale**: REPLACED - Two Weapon Fighting has no Tolkien precedent. Defensive Stance represents disciplined defenders like Gondorian soldiers.

---

### N:12 Swift Strikes (was Rapid Attack)
**Effect**: Extra melee attack at -3 Str/Dex when wielding a one-handed weapon
**Level**: 13
**Prereqs**: Subtlety, Stealth:Opportunist
**Tolkien**: Quick, light fighting style
**Rationale**: MODIFIED - Now requires one-handed weapon and has stealth prereq, tying it to mobile fighting style.

---

### N:13 Strength
**Effect**: +1 Strength
**Level**: 20
**Prereqs**: None
**Tolkien**: N/A - stat capstone
**Rationale**: UNCHANGED - standard capstone

---

## Removed Abilities

### Two Weapon Fighting
**Reason**: No Tolkien precedent. No notable dual-wielders in Third Age Middle-earth.
**Replacement**: Defensive Stance - represents disciplined Gondorian fighting

### Impale
**Reason**: Moved concept into Polearm Mastery as part of set-to-receive. Attacking "through" enemies too powerful.
**Alternative**: Could add back later as high-level polearm-only ability if needed.

---

## Ability Tree Structure

```
Level 1:  Power -------- Finesse
             |              |
Level 3:  Knock Back       |
             |              |
Level 4:  Polearm Mstr     |
             |    \        |
Level 5:  Charge   \       |
             |      \      |
Level 6:        Follow-Through
                    |
Level 7:            |------- Opening Strike (NEW, stealth synergy)
                    |              |
Level 8:            |          Subtlety
                    |              |
Level 9:    Controlled Fury        |
                    |              |
Level 10:   Zone of Control        |
                    |              |
Level 11:   Mighty Blow            |
                    |              |
Level 12:   Defensive Stance   Swift Strikes

Level 20:       Strength (capstone)
```

---

## Stealth Synergies Summary

1. **Opening Strike (NEW)**: Direct synergy - bonus damage vs unwary enemies
2. **Subtlety**: Indirect - light fighting style compatible with stealth approach
3. **Swift Strikes**: Has Stealth prereq, designed for mobile stealth fighters
4. **Charge**: Can be used after breaking stealth for powerful opener

---

## Changes from Current

| Slot | Current | Proposed | Change Type |
|------|---------|----------|-------------|
| 0 | Power | Power | KEEP |
| 1 | Finesse | Finesse | KEEP |
| 2 | Knock Back | Knock Back | KEEP |
| 3 | Polearm Mastery | Polearm Mastery | KEEP |
| 4 | Charge | Charge | KEEP |
| 5 | Follow-Through | Follow-Through | KEEP |
| 6 | Impale | Opening Strike | REPLACE |
| 7 | Subtlety | Subtlety | KEEP |
| 8 | Whirlwind Attack | Controlled Fury | MODIFY |
| 9 | Zone of Control | Zone of Control | KEEP |
| 10 | Smite | Mighty Blow | MODIFY |
| 11 | Two Weapon Fighting | Defensive Stance | REPLACE |
| 12 | Rapid Attack | Swift Strikes | MODIFY |
| 13 | Strength | Strength | KEEP |

**Summary**: 8 KEEP, 3 MODIFY, 2 REPLACE, 1 NEW ability concept (Opening Strike replaces Impale)
