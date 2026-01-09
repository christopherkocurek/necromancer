# Alchemy Crafting Analysis
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Question**: Should Alchemy become a crafting system for combining food/herbs/potions?

---

## Current State

### Alchemy Ability
- **Current Effect**: Auto-identify herbs and potions
- **Skill Tree**: Perception
- **No crafting component**

### Smithing Comparison
Sil-Q already has a robust Smithing system:
- Uses forges found in dungeon
- Multiple skills (Weaponsmith, Armoursmith, Jeweller, Enchantment, etc.)
- Creates items from materials
- Balances power with skill investment

---

## Design Options

### Option A: Keep Current (No Crafting)
**Effort**: None
**Impact**: None

**Pros**:
- No development time
- System works as-is
- Simpler game

**Cons**:
- Alchemy feels underwhelming vs Smithing
- Herbs have no combining value
- Missed thematic opportunity

---

### Option B: Simple Herb Processing
**Effort**: Low-Medium
**Impact**: Medium

**Concept**: Combine 2 herbs of same type → 1 improved version

| Input | Output |
|-------|--------|
| 2x Herb of Healing | Concentrated Healing Herb |
| 2x Athelas | Potent Athelas |
| 2x Lembas | Full Lembas Cake |

**Implementation**:
- New command: "Combine" or "Process"
- Check for 2 of same herb in inventory
- Replace with 1 improved version
- No special location required

**Pros**:
- Simple to implement
- Adds value to duplicate herbs
- No major balance changes
- Works anywhere

**Cons**:
- Limited depth
- Doesn't feel like "alchemy"
- No cross-type combinations

---

### Option C: Recipe-Based Combining
**Effort**: Medium
**Impact**: High

**Concept**: Combine different ingredients → new consumables

**Sample Recipes**:

| Ingredient 1 | Ingredient 2 | Result | Effect |
|--------------|--------------|--------|--------|
| Athelas | Water (flask) | Athelas Tea | 50% Athelas effect |
| Athelas | Miruvor | Greater Miruvor | Full heal + cure all |
| Herb of Rage | Orcish Liquor | Berserker Draught | Rage + no fear + stun |
| Herb of Healing | Lembas | Healing Waybread | Heal 25% + nutrition |
| Poison potion | Arrow | Poisoned Arrow | Adds poison damage |

**Implementation**:
- Recipe table in data file
- "Combine" command with item selection
- Recipes discovered through play or items
- May require Alchemy ability to succeed

**Pros**:
- Rich gameplay
- Rewards experimentation
- Uses existing items
- Creates new consumables

**Cons**:
- Balance complexity
- Recipe discoverability
- Inventory management
- Significant development time

---

### Option D: Cauldron/Alembic Stations
**Effort**: High
**Impact**: Very High

**Concept**: Like Smithing forges, special locations for alchemy

**Features**:
- Cauldrons found in dungeon (rare)
- Full recipe system
- Can create any potion from ingredients
- Skill checks for success

**Pros**:
- Mirrors Smithing depth
- Creates exploration goals
- Maximum player agency
- Natural balance (limited stations)

**Cons**:
- Major development effort
- Requires dungeon generation changes
- Balance with found potions
- May obsolete potion drops

---

## Implementation Complexity Comparison

| Aspect | Option B | Option C | Option D |
|--------|----------|----------|----------|
| New Commands | 1 | 1 | 1 |
| Data Changes | Minimal | Recipe table | Stations + recipes |
| Code Changes | ~100 lines | ~500 lines | ~1500+ lines |
| Balance Work | Low | Medium | High |
| Testing | Simple | Moderate | Extensive |
| Content Creation | None | Recipes | Recipes + stations |
| Risk | Low | Medium | High |

---

## Smithing System Reference

### Current Smithing Structure
```
Forge Types: Enchanted Forge, Normal Forge
Skills Required: Weaponsmith, Armoursmith, etc.
Materials: Metal pieces, artefact materials
Process: Forge + Materials + Skill → Item
```

### Alchemy Could Mirror
```
Station Types: Cauldron (potions), Mortar (herbs)
Skills Required: Alchemy (Perception tree)
Materials: Herbs, Potions, Ingredients
Process: Station + Materials + Skill → Consumable
```

---

## Recommended Approach

### Phase 1: Simple Processing (Option B)
- Combine 2x same herb → improved herb
- No special location needed
- Immediate value from Alchemy ability
- Low risk, quick implementation

### Phase 2: Recipe Combining (Option C)
- Add cross-ingredient recipes
- Start with 5-10 recipes
- Recipes learned from lore items
- Build on Phase 1

### Phase 3 (Optional): Stations (Option D)
- Only if Phase 2 is successful
- Add rare cauldrons to dungeons
- Enable more powerful recipes
- Long-term goal

---

## Sample Phase 1 Implementation

### Data Format (object.txt extension)
```
# Herb processing
C:380:380:480  # 2x Rage → Concentrated Rage
C:383:383:483  # 2x Healing → Concentrated Healing
C:390:390:490  # 2x Athelas → Potent Athelas
```

### New Items Required
| ID | Name | Effect |
|----|------|--------|
| 480 | Concentrated Rage | +2 Str/Con, -2 Dex/Gra, 15d4 turns |
| 483 | Concentrated Healing | Heal 75% + cure cuts |
| 490 | Potent Athelas | Full Athelas + 50% heal |

### Code Changes
```c
// In cmd6.c or new alchemy.c
void do_cmd_combine(void)
{
    // Select first item
    // Find matching item in inventory
    // Check recipe table
    // Create new item
    // Consume ingredients
}
```

---

## Tolkien Thematic Fit

### Supported by Lore
- Aragorn preparing athelas (simple herb processing)
- Elves making cordials and potions
- Dwarves brewing (mentioned in Hobbit)

### Not Supported
- Complex laboratory alchemy
- Transmutation
- Magical chemistry

### Recommendation
Keep alchemy **practical and herbal**, not magical/scientific. Focus on:
- Herb combinations
- Teas and draughts
- Applied medicine

---

## Conclusion

**Recommended**: Start with Option B (Simple Processing), plan for Option C.

**Rationale**:
1. Low implementation risk
2. Immediate value for Alchemy ability
3. Foundation for future expansion
4. Maintains thematic consistency
5. Doesn't compete with Smithing

**Decision Points for Human**:
1. Implement alchemy crafting at all? (Y/N)
2. If yes, start with Option B or jump to C?
3. Require Alchemy ability for crafting?
4. Add new items or enhance existing?

---

*Analysis generated for ANALYSIS-001*
