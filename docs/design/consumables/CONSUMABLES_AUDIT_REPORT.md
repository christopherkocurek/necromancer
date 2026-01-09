# Consumables Audit Report
## The Necromancer - Alpha 0.5.0 Design Review

**Generated**: 2026-01-09
**Version**: FINAL
**Status**: Ready for Human Review

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total Consumables Audited | 53 |
| Potions | 18 |
| Horns | 5 |
| Food/Herbs | 14 |
| Staves | 16 |
| Wands | 0 (not implemented) |
| High-Scoring Items (15+) | 24 |
| Flagged for Rework | 12 |
| Major Design Questions | 3 |

---

## Current State Assessment

### What's Working Well

1. **Horns replace scrolls** - Excellent thematic choice for Tolkien setting
2. **Stealth-staff synergy** - Staves of Shadows/Slumber support stealth gameplay
3. **Channeling ability** - Force of Will creates meaningful skill investment
4. **Canonical items** - Miruvor, Athelas, Lembas are well-implemented
5. **Charge system** - Staff charges create resource decisions

### What Needs Work

1. **Harmful consumables** - Permanent stat loss is anti-fun
2. **Generic names** - Stat potions lack Tolkien flavor
3. **Alchemy is passive** - No crafting component
4. **Limited variety** - Only 5 horns vs 16 staves
5. **No stealth potions** - Gap in consumable support for stealth

---

## Detailed Findings

### Potions (18 total)

| Rating | Count | Examples |
|--------|-------|----------|
| Excellent (17+) | 4 | Miruvor, Quickness, Esgalduin, True Sight |
| Good (13-16) | 6 | Healing, Orcish Liquor, Clarity, Elem Resist |
| Needs Work (10-12) | 4 | Stat potions (Str, Dex, Con, Gra) |
| Poor (<10) | 6 | All harmful potions |

**Recommendations**:
- Rename stat potions for theme
- Remove or rework harmful potions
- Add Potion of Shadows for stealth

### Horns (5 total)

| Rating | Count | Examples |
|--------|-------|----------|
| Good (14+) | 4 | Terror, Thunder, Force, Blasting |
| Needs Work | 1 | Warning (mostly harmful) |

**Recommendations**:
- Keep all combat horns
- Rework Warning to Horn of Challenge (buff on use)
- Add Horn of Mist (stealth escape)
- Add Horn of Rallying (cure fear)

### Food/Herbs (14 total)

| Rating | Count | Examples |
|--------|-------|----------|
| Excellent (17+) | 2 | Lembas, Athelas |
| Good (13-16) | 5 | Healing, Restoration, Sustenance, Rage |
| Needs Work | 3 | Terror, Visions, Mixed herbs |
| Poor (<10) | 4 | Weakness, Sickness, Emptiness, Entrancement |

**Recommendations**:
- Keep Athelas, Lembas as-is (canonical perfection)
- Add Cram (Dale waybread) and Pipe-weed (Old Toby)
- Remove permanent stat loss herbs or add use case
- Consider herb combining in Alchemy

### Staves (16 total)

| Rating | Count | Examples |
|--------|-------|----------|
| Excellent (17+) | 5 | Slumber, Shadows, Revelations, Foes, Understanding |
| Good (13-16) | 9 | Most utility staves |
| Needs Work (<10) | 2 | Summoning, Self Knowledge |

**Recommendations**:
- Keep most staves as-is
- Rework Summoning (make beneficial or remove)
- Consider adding Staff of Speed, Staff of Healing

---

## Design Questions for Human Review

### Q1: Alchemy Crafting System?

**Current**: Alchemy only provides auto-identification.

**Options**:
| Option | Effort | Impact |
|--------|--------|--------|
| A: Keep current | None | None |
| B: Simple herb combining | Low | Medium |
| C: Recipe-based crafting | Medium | High |
| D: Full station-based (like Smithing) | High | Very High |

**Recommendation**: Start with Option B, plan for Option C.

**Sample Recipe** (if approved):
```
2x Herb of Healing → Concentrated Healing Herb
Athelas + Miruvor → Greater Healing Potion
```

---

### Q2: Gandalf-Style Combat Staves?

**Current**: Staves are utility devices, not weapons.

**Options**:
| Option | Description | Effort |
|--------|-------------|--------|
| A: Status quo | Keep staves as devices | None |
| B: Add wands only | Targeted ranged magic | Medium |
| C: Combat staves | Gandalf-style weapon + casting | High |
| D: Both | Full magic item system | Very High |

**Recommendation**: Evaluate Option B (wands) first, then consider Option C.

**Trade-off**: Combat staves fulfill the wizard fantasy but require major development.

---

### Q3: Harmful Consumable Policy?

**Current**: Harmful potions/herbs exist with permanent stat loss.

**Options**:
| Option | Description | Impact |
|--------|-------------|--------|
| A: Keep as-is | Purist approach | Anti-fun for most |
| B: Remove after ID | Brogue Lite approach | Simpler, more fun |
| C: Add use case | Make throwable/craftable | More complex |
| D: Rename as Morgul | Stronger evil theme | Cosmetic |

**Recommendation**: Option B (remove from drop pools after identification) or Option C (add tactical use).

---

## Item Recommendations Summary

### Add (High Priority)
| Item | Type | Rationale |
|------|------|-----------|
| Potion of Shadows | Potion | Stealth gap |
| Cram | Food | Tolkien canonical |
| Pipe-weed / Old Toby | Herb | Tolkien canonical, +Will |
| Horn of Mist | Horn | Stealth escape |
| Horn of Rallying | Horn | Fear counter |

### Rename (Medium Priority)
| Current | Proposed | Rationale |
|---------|----------|-----------|
| Healing (potion) | Cordial of the Wise | Theme |
| Healing (herb) | Healer's Herb | Clarity |
| Strength | Draught of Might | Theme |
| Dark Bread | Travel Bread | Cleaner |

### Remove/Rework (Low Priority)
| Item | Action | Rationale |
|------|--------|-----------|
| Weakness | Remove or add use | Anti-fun |
| Sickness | Remove or add use | Anti-fun |
| Summoning (staff) | Rework to beneficial | Harmful |
| Warning (horn) | Rework to buff | Harmful |

---

## Stealth Synergy Analysis

### Current Stealth-Positive Items
- **Potions**: Esgalduin, True Sight, Quickness
- **Staves**: Shadows, Slumber, Imprisonment, Revelations, Foes
- **Herbs**: Athelas, Healing, Sustenance

### Stealth Gaps
1. **No stealth-boost potion** → Add Potion of Shadows
2. **All horns are anti-stealth** → Add Horn of Mist
3. **No darkness food/herb** → Consider Nightshade herb

### Intentional Anti-Stealth
- Horns (by design - emergency buttons)
- Herb of Rage (by design - berserker option)
- Staff of Light (by design - illumination)

---

## Implementation Roadmap

### Phase 1: Quick Wins (Low Effort)
- Rename generic items for theme
- Remove harmful consumables after ID
- Add 2-3 new Tolkien items (Cram, Pipe-weed)
- Rework Horn of Warning

### Phase 2: Alchemy Foundation (Medium Effort)
- Add simple herb combining (2x → improved)
- Add 3-5 new combined consumables
- Link to Alchemy ability

### Phase 3: Expanded System (High Effort)
- Recipe-based alchemy
- Consider wands
- Consider combat staves (requires separate PRD)

---

## Appendices

### A: Full Scoring Tables
See individual evaluation files:
- potions_evaluation.md
- scrolls_evaluation.md (horns)
- food_herbs_evaluation.md
- staves_evaluation.md

### B: Research Sources
- roguelike_research.md (Brogue, DCSS, CoQ, Cogmind)
- tolkien_research.md (Athelas, Miruvor, Lembas, etc.)

### C: Technical Details
- device_system_audit.md
- alchemy_audit.md

### D: Design Analysis
- alchemy_crafting_analysis.md
- staff_wand_analysis.md

---

## Approval Requested

**To proceed with Phase 1**:
Reply with approval of item changes.

**For Alchemy crafting**:
Confirm Option B (simple combining) or Option C (recipes).

**For Combat staves/wands**:
Indicate interest level for separate design PRD.

---

*Generated by: Consumables Audit PRD*
*All 17 tasks completed. No code changes made.*
