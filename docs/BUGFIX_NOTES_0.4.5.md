# The Necromancer - Alpha 0.4.5 Bugfix Notes

**Release Date**: 2026-01-09

---

## Bug Fixes

### BUG-001: Poison Stream Effect Fixed
**Issue**: Poison streams were not consistently applying poison to players.

**Root Cause**: The original code only applied poison if the player was NOT already poisoned, preventing additional poison from wading through multiple streams.

**Fix**: Poison now properly stacks when walking through poison streams. Each failed CON check (vs DC 10) adds 5+1d10 poison duration. Messages now distinguish between initial poisoning ("The tainted water sickens you!") and worsening ("The poison worsens!").

**File Changed**: `src/cmd1.c` (lines 5289-5314)

---

### BUG-002: Palantír Spelling Corrected
**Issue**: "Palantir" was missing the accent in some places.

**Fix**: Corrected to "Palantír" (with accent) for consistency with Tolkien's spelling.

**Files Changed**:
- `lib/edit/artefact.txt` - The Palantír of Dol Guldur
- `lib/edit/names.txt` - Name list entry

---

## New Features

### FEAT-001: Lore Notes Now Grant XP
**Feature**: Reading lore notes and Palantír shards now grants 500 XP on first read.

**Details**:
- Message displayed: "You gain insight from reading this lore."
- Each note can only grant XP once (tracked via IDENT_NOTE_READ flag)
- Works for both inventory reading and walking over notes on the ground
- Encourages exploration and reading the worldbuilding content

**Files Changed**:
- `src/defines.h` - Added IDENT_NOTE_READ flag
- `src/cmd1.c` - XP grant when stepping on notes
- `src/cmd3.c` - XP grant when reading from inventory

---

### FEAT-002: Palantír Shards Grant XP
**Status**: Already handled by FEAT-001 (shards are TV_NOTE items).

Palantír Shards now grant 500 XP when first examined, as originally intended.

---

### FEAT-003: New Lore Note Variety
**Feature**: Added 8 new lore notes about Dol Guldur.

**New Items** (sval 100-107):
| Item | Depth | Description |
|------|-------|-------------|
| Prisoner's Account (x2) | 3-11 | Haunting records from captives |
| Orc Report (x2) | 7-15 | Enemy communications mentioning Thráin |
| Historical Fragment (x2) | 11-18 | Elvish chronicles and wizard notes |
| Necromancer Sighting (x2) | 15-19 | First-hand accounts of Sauron |

**Themes Covered**:
- Dol Guldur history (built on Amon Lanc)
- Prisoner experiences and shadow corruption
- Orc intelligence reports about Thráin
- White Council inaction
- Sauron's search for the Ring
- The terror of the Necromancer

**File Changed**: `lib/edit/object.txt` (N:550-557)

---

## Summary

This bugfix release addresses playtest feedback from the "Goondalf" session:
- Poison streams now work reliably
- Spelling consistency improved
- Exploration rewarded with XP
- More worldbuilding content added

---

*The Necromancer - Alpha 0.4.5*
