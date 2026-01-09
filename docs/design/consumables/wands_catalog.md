# Wands Catalog
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: lib/edit/object.txt, src/defines.h

---

## Status: NOT IMPLEMENTED

**Wands do not exist in Sil-Q.**

### Evidence
1. No `TV_WAND` constant in defines.h
2. No wand entries in object.txt
3. No wand handling code in use-obj.c or cmd6.c
4. Object.txt comment references "wand, staff or rod" but only staves exist

### Historical Note
The object.txt header comments mention wands alongside staves and rods, suggesting the codebase may have inherited from an earlier Angband variant that had wands, but they were removed or never implemented in Sil/Sil-Q.

---

## Design Space Analysis

### Why Wands Might Be Absent
1. **Simplification**: Sil-Q streamlines item types vs Angband
2. **Staff sufficiency**: Staves provide charge-based magic
3. **Thematic fit**: Wands are less Tolkien-appropriate than staves
4. **Tactical horns**: Horns fill the single-use slot

### Potential Role for Wands (if added)

| Attribute | Staff (current) | Wand (potential) |
|-----------|-----------------|------------------|
| Form | Walking stick | Small rod/pointer |
| Weight | 50 | 5-10 |
| Charges | 3-10 | 10-30 |
| Power | Strong effects | Weaker, many uses |
| Range | Line of Sight | Beam/targeted |
| Theme | Wizard's tool | Focused magic |

### Tolkien Wand References
- Very limited in Tolkien's works
- Gandalf carries a staff, not a wand
- Saruman has a staff
- No significant wand-wielders in LotR/Hobbit
- "Wand" in Tolkien usually means staff (archaic usage)

---

## Recommendation

**Low priority for implementation.**

Wands would overlap with staves without clear differentiation. If added, consider:
1. **Elf-crafted focus items** - Small, light, single-school effects
2. **Dark wands** - Morgul artifacts with corrupting effects
3. **One-use wands** - Disposable spell batteries (non-rechargeable)

---

## Comparison with Other Roguelikes

| Game | Wands | Staves | Notes |
|------|-------|--------|-------|
| Angband | Yes | Yes | Wands = targeted, Staves = AoE |
| DCSS | Yes | Yes | Similar split |
| Brogue | No | Staves only | Simplified |
| Sil-Q | No | Yes | Simplified like Brogue |

---

*Catalog generated for AUDIT-005*
