# Will Proposal: Mental Fortitude Tree

## Design Goals
1. Emphasize mental fortitude and endurance
2. Remove duplicate with Lore (Inner Light)
3. Strengthen "I will not break" fantasy

## Proposed Ability Tree

### N:100 Curse Breaking
**Effect**: Break curses when attempting to remove items
**Level**: 1
**Prereqs**: None
**Tolkien**: Theoden freed from Saruman's spell
**Rationale**: UNCHANGED - Essential utility

---

### N:101 Force of Will (was Channeling)
**Effect**: Automatically recognize staves/horns, use them twice as efficiently
**Level**: 2
**Prereqs**: None
**Tolkien**: Gandalf powering his staff through sheer will
**Rationale**: RENAMED - "Channeling" was generic. "Force of Will" emphasizes mental power driving magical devices.

---

### N:102 Strength in Adversity
**Effect**: +1 Str/Dex/Gra at ≤50% HP, +3 at ≤25% HP
**Level**: 3
**Prereqs**: None
**Tolkien**: Sam carrying Frodo, desperate courage
**Rationale**: UNCHANGED - Excellent "last stand" ability

---

### N:103 Formidable
**Effect**: Killing enemies scares others who see it. Enemies don't gain morale from your injuries.
**Level**: 4
**Prereqs**: None
**Tolkien**: Aragorn's warrior presence
**Rationale**: UNCHANGED - Good intimidation ability

---

### N:104 Defy Death (was Inner Light)
**Effect**: Once per floor, when reduced to 0 HP, make a Will save to survive with 1 HP instead. Your determination keeps you fighting.
**Level**: 5
**Prereqs**: Strength in Adversity
**Tolkien**: Boromir's last stand, fighting on despite mortal wounds. Theoden's final charge.
**Rationale**: REPLACED - Inner Light was duplicate of Lore ability. Defy Death embodies the core Will fantasy of refusing to fall.

---

### N:105 Indomitable
**Effect**: Resist fear, confusion, stunning, hallucination. Hunger slows to 1/3 rate.
**Level**: 5
**Prereqs**: None
**Tolkien**: Eowyn facing the Witch-King without flinching
**Rationale**: UNCHANGED - Core Will ability

**Stealth Hook**: Stay calm when hiding from terrifying enemies

---

### N:106 Oath
**Effect**: Swear a great oath and be rewarded for keeping it
**Level**: 6
**Prereqs**: None
**Tolkien**: Feanor's oath, the Dead Men's oath - oaths have power in Middle-earth
**Rationale**: UNCHANGED - Very Tolkien, unique mechanic

---

### N:107 Poison Resistance
**Effect**: Resist poison
**Level**: 7
**Prereqs**: None
**Tolkien**: Hardy constitution, physical endurance
**Rationale**: UNCHANGED - Simple defensive utility

---

### N:108 Vengeance
**Effect**: After being damaged in melee, your next successful strike deals an extra damage die
**Level**: 8
**Prereqs**: Strength in Adversity
**Tolkien**: Pain fueling determination, righteous anger
**Rationale**: UNCHANGED - Good synergy with adversity theme

---

### N:109 Majesty
**Effect**: Lower enemy morale by half the difference between your Will and theirs
**Level**: 9
**Prereqs**: Curse Breaking, Inner Light (now Defy Death)
**Tolkien**: Aragorn's kingly presence, commanding aura
**Rationale**: UNCHANGED - Capstone leadership ability

---

### N:110 Constitution
**Effect**: +1 Constitution
**Level**: 12
**Prereqs**: None
**Tolkien**: N/A - stat capstone
**Rationale**: UNCHANGED

---

## Ability Tree Structure

```
Level 1:  Curse Breaking
             |
Level 2:  Force of Will (renamed)
             |
Level 3:  Strength in Adversity ----+
             |                       |
Level 4:  Formidable                |
             |                       |
Level 5:  Indomitable     Defy Death (NEW)
             |                       |
Level 6:       Oath                  |
                  \                  |
Level 7:    Poison Resistance        |
                     \               |
Level 8:              Vengeance -----+
                           |
Level 9:               Majesty

Level 12:          Constitution (capstone)
```

---

## Core Fantasy

**"I will not break. I will not fall. I will endure."**

The Will tree is about:
- Mental resistance (Indomitable, Curse Breaking)
- Physical endurance (Strength in Adversity, Defy Death, Poison Resistance)
- Leadership presence (Formidable, Majesty)
- Sacred commitment (Oath)
- Righteous fury (Vengeance)

---

## Changes from Current

| Slot | Current | Proposed | Change Type |
|------|---------|----------|-------------|
| 0 | Curse Breaking | Curse Breaking | KEEP |
| 1 | Channeling | Force of Will | MODIFY (rename) |
| 2 | Strength in Adversity | Strength in Adversity | KEEP |
| 3 | Formidable | Formidable | KEEP |
| 4 | Inner Light | Defy Death | REPLACE |
| 5 | Indomitable | Indomitable | KEEP |
| 6 | Oath | Oath | KEEP |
| 7 | Poison Resistance | Poison Resistance | KEEP |
| 8 | Vengeance | Vengeance | KEEP |
| 9 | Majesty | Majesty | KEEP |
| 10 | Constitution | Constitution | KEEP |

**Summary**: 9 KEEP, 1 MODIFY (rename), 1 REPLACE
