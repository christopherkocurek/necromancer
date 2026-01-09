# Staff vs Wand Analysis
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Question**: Should staves be Gandalf-style polearms and wands be disposable spell batteries?

---

## Current State

### Staves
- **Type**: Utility devices (NOT weapons)
- **tval**: TV_STAFF (55)
- **Usage**: Charge-based, from inventory
- **Combat**: Cannot be wielded
- **Count**: 16 types

### Wands
- **Type**: NOT IMPLEMENTED
- **Status**: No TV_WAND, no wand items

---

## The Gandalf Problem

### Tolkien's Wizards
Gandalf's staff is:
1. A walking stick / travel aid
2. A weapon (he fights with it)
3. A magical focus (casts spells)
4. A light source
5. A symbol of his order

### Current Gap
Sil-Q staves don't fulfill the "wizard with a staff" fantasy. They're more like scrolls with charges.

---

## Design Options

### Option A: Status Quo
Keep staves as utility devices, don't add wands.

**Pros**:
- No development needed
- System works
- Simple

**Cons**:
- No Gandalf archetype
- Wand niche unfilled
- Limited playstyle variety

---

### Option B: Add Wands Only
Add wands as targeted spell batteries. Keep staves as-is.

**Wand Concept**:
| Attribute | Value |
|-----------|-------|
| Type | Targeted ranged magic |
| Weight | 5-10 (light) |
| Charges | 10-30 (many) |
| Power | Low per charge |
| Range | Beam/bolt |
| Skill | Grace or Perception |

**Sample Wands**:
| Wand | Effect | Charges |
|------|--------|---------|
| Wand of Frost | 2d4 cold damage | 15 |
| Wand of Fire | 2d4 fire damage | 15 |
| Wand of Slowing | Slow target | 10 |
| Wand of Light | Light beam | 20 |
| Wand of Confusion | Confuse target | 8 |

**Pros**:
- Fills ranged magic gap
- Distinct from staves
- Moderate implementation

**Cons**:
- Weak Tolkien fit (wands aren't prominent)
- Adds complexity
- Balance with bows

---

### Option C: Combat Staves (Gandalf-Style)
Transform staves into weapon + casting tool hybrids.

**Combat Staff Concept**:
| Attribute | Value |
|-----------|-------|
| Slot | Main hand (or 2-handed) |
| Damage | 2d4 to 3d5 |
| Weight | 50 (heavy) |
| Charges | 3-6 (limited, powerful) |
| Special | Spell effects |
| Skill | Will for casting, Melee for fighting |

**Sample Combat Staves**:
| Staff | Damage | Spell | Charges |
|-------|--------|-------|---------|
| Staff of Light | 2d4 | Blinding Flash (AoE) | 4 |
| Staff of the Wise | 2d5 | Identify + Insight | 5 |
| Staff of Shadows | 2d4 | Darkness (room) | 3 |
| Staff of Majesty | 2d6 | Mass Fear | 3 |
| Staff of the Istari | 3d5 | Various (artifact) | ∞ |

**Implementation**:
```
Wield staff as weapon
- Normal melee attacks use damage dice
- "Invoke" command uses charges
- Charges don't regenerate (or slow regen)
- Skill checks for spell success
```

**Pros**:
- Gandalf fantasy fulfilled
- Unique playstyle
- Strong thematic fit
- Cool power fantasy

**Cons**:
- Major implementation effort
- Balance with other weapons
- Requires new weapon category
- Combat system changes

---

### Option D: Both (Combat Staves + Wands)
Implement combat staves AND add wands as different tools.

**Distinction**:
| Attribute | Combat Staff | Wand |
|-----------|--------------|------|
| Slot | Weapon | Inventory |
| Weight | Heavy (50+) | Light (5-10) |
| Charges | Few (3-6) | Many (15-30) |
| Power | Strong effects | Weak effects |
| Range | Self/AoE | Targeted |
| Skill | Will | Grace |
| Theme | Wizard's tool | Focus item |

**Pros**:
- Maximum variety
- Multiple playstyles
- Full magic item system

**Cons**:
- Major development scope
- Balance complexity
- May overwhelm game

---

## Tolkien Thematic Analysis

### Staff References
| Source | Reference |
|--------|-----------|
| LotR | Gandalf fights with staff, casts with it |
| Hobbit | Gandalf's light |
| Silmarillion | Wizard staves as authority |

### Wand References
| Source | Reference |
|--------|-----------|
| LotR | None significant |
| Hobbit | None |
| Silmarillion | None |

**Conclusion**: Staves are very Tolkien. Wands are not.

---

## Implementation Complexity

| Feature | Effort | Risk |
|---------|--------|------|
| Utility staves (current) | Done | None |
| Add wands only | Medium | Low |
| Combat staves | High | Medium |
| Combat staves + wands | Very High | High |

### Combat Staff Implementation Steps
1. Create new tval (TV_COMBAT_STAFF?)
2. Allow wielding as weapon
3. Add damage dice to data
4. Create "Invoke" command for spells
5. Implement charge system on weapons
6. Add skill checks for casting
7. Balance with existing weapons
8. Create 5-10 staff types
9. Add to drop tables
10. Test extensively

**Estimated Effort**: 40-80 hours

---

## Stealth Considerations

### Current Staves
Many are stealth-positive (Shadows, Slumber, etc.)

### Combat Staves
- Melee combat = anti-stealth
- But spells could support stealth
- Staff of Shadows = combat + stealth tool

### Wands
- Ranged = can maintain distance
- Quiet? (unlike horns)
- Could be stealth-neutral

---

## Recommendation

### Short Term: Option B (Wands Only)
1. Add 5-7 wands as targeted effects
2. Distinct from staves (targeted vs AoE)
3. Use Grace skill for accuracy
4. Fills ranged magic gap
5. Moderate implementation

### Medium Term: Evaluate Combat Staves
1. After wands are stable
2. Prototype one combat staff
3. Get player feedback
4. Decide on full implementation

### Long Term: Full Option D
Only if both systems prove fun and balanced.

---

## Sample Wand Implementation

### Data Format
```
##### Wands #####

N:500:& Wand~ of Frost
G:-:w
I:56:0:15
W:6:0:10:100
P:0:0d0:0:0d0
A:6/4:12/2
D:A thin rod that shoots a beam of cold, dealing 2d4 damage.

N:501:& Wand~ of Fire
G:-:r
I:56:1:15
W:7:0:10:100
P:0:0d0:0:0d0
A:7/4:13/2
D:A thin rod that shoots a bolt of fire, dealing 2d4 damage.
```

### Code Changes
```c
// defines.h
#define TV_WAND 56

// use-obj.c
case TV_WAND:
    return use_wand(o_ptr, ident);

// New function
static bool use_wand(object_type *o_ptr, bool *ident)
{
    int dir;

    // Get direction
    if (!get_aim_dir(&dir)) return FALSE;

    switch (o_ptr->sval)
    {
        case SV_WAND_FROST:
            fire_bolt(GF_COLD, dir, damroll(2, 4));
            break;
        // etc.
    }
    return TRUE;
}
```

---

## Decision Points for Human

1. **Add wands?** (Y/N)
   - If yes: Targeted ranged magic
   - Trade: Adds complexity

2. **Combat staves?** (Y/N)
   - If yes: Major feature, Gandalf fantasy
   - Trade: High development cost

3. **Skill for wands?**
   - Option A: Grace (fits dexterity)
   - Option B: Will (matches staves)
   - Option C: New skill "Sorcery"

4. **Wand theme?**
   - Option A: Generic fantasy (frost, fire, etc.)
   - Option B: Tolkien-ish (light, shadow, fear)
   - Option C: Mix

---

*Analysis generated for ANALYSIS-002*
