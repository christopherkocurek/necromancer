# Implementation Impact Analysis - The Necromancer
## IMPACT-001: Effort Estimate for Item Renames

---

## Summary

| Metric | Value |
|--------|-------|
| Total Items to Rename | 38 |
| Total Items to Keep | 22 |
| Data Files to Modify | 3 |
| Code Files to Modify | 1-2 |
| Estimated Line Changes | ~200-250 |
| Risk Level | LOW-MEDIUM |

---

## File-by-File Impact

### PRIMARY DATA FILES (Required)

#### lib/edit/object.txt
- **Changes**: 38 N: lines (names), 47 D: lines (descriptions)
- **Line Changes**: ~85 lines
- **Risk**: LOW - Pure data, no logic
- **Validation**: Load game, check items appear correctly

#### lib/edit/artefact.txt
- **Changes**: ~40-50 base item references
- **Line Changes**: ~50 lines
- **Risk**: LOW - Pure data
- **Validation**: Artifacts generate with correct base types

### SECONDARY DATA FILES (Recommended)

#### lib/edit/ability.txt
- **Changes**: Comment updates for item type references
- **Line Changes**: ~30-50 lines (cosmetic)
- **Risk**: VERY LOW - Comments only
- **Note**: Optional but improves maintainability

#### lib/edit/special.txt (ego items)
- **Changes**: Comment updates for item type references
- **Line Changes**: ~10-20 lines (cosmetic)
- **Risk**: VERY LOW - Comments only
- **Note**: Optional

#### lib/edit/changes.txt
- **Changes**: None required (historical record)
- **Note**: Add changelog entry for rename

### CODE FILES (Required for some items)

#### src/xtra2.c
- **Changes**: 3 hardcoded artifact base names
  - Line ~2110: "Galvorn Armour" → "Shadow-steel Armor"
  - Line ~2116: "Spear" → "Hunting Spear" (if renamed)
  - Line ~2125: "Greatsword" → "Númenórean Blade"
- **Line Changes**: 3 lines
- **Risk**: MEDIUM - Must test artifact generation
- **Validation**: Create characters, verify artifacts work

#### src/wizard1.c, wizard2.c, squelch.c, cmd4.c
- **Changes**: UI category strings (optional)
- **Line Changes**: ~10 lines total
- **Risk**: LOW - UI display only
- **Note**: Category names like "Boots" stay as categories; only item names change

---

## Change Breakdown by Risk Level

### HIGH RISK (0 items)
No items require architectural changes.

### MEDIUM RISK (4 items)
| Item | Issue | Mitigation |
|------|-------|------------|
| Greatsword → Númenórean Blade | Hardcoded in xtra2.c | Test Glend artifact |
| Spear → Hunting Spear | Hardcoded in xtra2.c | Test Boldog artifact |
| Galvorn Armour → Shadow-steel Armor | Hardcoded in xtra2.c | Test Maeglin artifact |
| Feanorian Lamp → Jewel-lamp | First Age reference removal | Verify lamp functions |

### LOW RISK (34 items)
All other renames only affect data files (object.txt, artefact.txt).

---

## Implementation Order

### Phase 1: Object Definitions (LOW RISK)
1. Update object.txt N: lines with new names
2. Update object.txt D: lines with new descriptions
3. Test: Items appear with correct names in-game

### Phase 2: Artifact References (LOW RISK)
1. Update artefact.txt base item names
2. Test: Artifacts generate correctly

### Phase 3: Code Updates (MEDIUM RISK)
1. Update xtra2.c hardcoded strings
2. Test: Special artifacts (Glend, Boldog, Maeglin) generate correctly

### Phase 4: Polish (VERY LOW RISK)
1. Update ability.txt comments (optional)
2. Update special.txt comments (optional)
3. Add changelog entry

---

## Testing Checklist

### Basic Functionality
- [ ] Game loads without errors
- [ ] Items appear in inventory with correct names
- [ ] Item descriptions display correctly
- [ ] Items can be equipped/used

### Artifact Generation
- [ ] Random artifacts generate with correct bases
- [ ] Glend (Greatsword base) generates correctly
- [ ] Boldog's Spear generates correctly
- [ ] Maeglin's Armor generates correctly

### UI Display
- [ ] Squelch menus show correct categories
- [ ] Wizard mode lists items correctly
- [ ] Object browser displays correctly

### Save/Load
- [ ] Existing saves load without errors
- [ ] Items in saves display correct names
- [ ] New items in saves persist correctly

---

## Effort Estimate

### Optimistic (Experienced Developer)
- Data file changes: 2 hours
- Code changes: 30 minutes
- Testing: 1 hour
- **Total: 3.5 hours**

### Realistic (Careful Implementation)
- Data file changes: 3-4 hours
- Code changes: 1 hour
- Testing: 2 hours
- Documentation: 1 hour
- **Total: 7-8 hours**

### Pessimistic (Issues Encountered)
- Data file changes: 4-5 hours
- Code changes: 2 hours
- Testing/debugging: 4 hours
- Documentation: 1 hour
- **Total: 11-12 hours**

---

## Rollback Plan

If issues are encountered:

1. **Git revert**: All changes should be in a single commit for easy revert
2. **Backup files**: Keep original object.txt, artefact.txt, xtra2.c
3. **Save compatibility**: Test with existing saves before committing

---

## Recommendation

**Proceed with implementation.** The risk is LOW-MEDIUM with:
- 95% of changes in data files only
- 3 code lines requiring careful testing
- No architectural changes needed
- Easy rollback via git

**Suggested approach:**
1. Create feature branch
2. Make all changes in one session
3. Test thoroughly
4. Merge to master
5. Tag as alpha-0.4.1 or similar
