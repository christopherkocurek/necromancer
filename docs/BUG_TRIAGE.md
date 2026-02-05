# Bug Triage Log

Track bugs discovered during Phase 8 implementation.

---

## Format

```
## BUG-XXX: [Short Description]

**Severity**: CRITICAL / HIGH / MEDIUM / LOW
**Found**: [Date]
**Status**: OPEN / FIXING / FIXED / WONTFIX
**File(s)**: [Affected files]

**Description**:
[What happens]

**Steps to Reproduce**:
1. ...
2. ...

**Root Cause**:
[If known]

**Fix**:
[If implemented]
```

---

## Known Issues (Pre-Phase 8)

### BUG-001: DataManager Validation Warnings

**Severity**: LOW
**Found**: 2026-02-05
**Status**: WONTFIX (cosmetic)
**File(s)**: scripts/core/data_manager.gd

**Description**:
DataManager reports missing monsters (Morgoth, Orc, Troll, Spider) and races (Noldor, Sindar) during validation. These are naming mismatches between validation list and actual data files.

**Root Cause**:
Validation arrays contain generic names like "Orc" but data files use specific names like "Orc Scout", "Orc Soldier".

**Fix**:
Not blocking - warnings only. Can update validation arrays post-prototype if desired.

---

### BUG-002: test_turn_flow.gd Parse Error

**Severity**: MEDIUM
**Found**: 2026-02-05
**Status**: OPEN
**File(s)**: tests/integration/test_turn_flow.gd:146

**Description**:
Test script has a parse error that prevents running integration tests.

**Root Cause**:
Unknown - needs investigation.

**Fix**:
TBD

---

## Phase 8 Bugs

### BUG-003: RID/ObjectDB Leak on Exit

**Severity**: LOW
**Found**: 2026-02-05
**Status**: OPEN
**File(s)**: Various (cleanup on exit)

**Description**:
When exiting headless mode (and likely normal exit), 1 RID of type "CanvasItem" and ObjectDB instances are leaked. This is a cleanup issue on shutdown.

**Root Cause**:
Likely a node not being properly queue_free'd before engine shutdown.

**Fix**:
Not blocking - only appears on exit. Can investigate post-prototype.

---

### BUG-004: Class_name Load Order Issues (RESOLVED)

**Severity**: HIGH
**Found**: 2026-02-05
**Status**: FIXED
**File(s)**: Multiple (npc.gd, thrain_npc.gd, dialogue_panel.gd, main.gd)

**Description**:
GDScript class_name declarations caused cyclic dependency and load-order issues when scripts referenced each other.

**Root Cause**:
GDScript resolves class_name at compile time. Cross-references between scripts using class_name caused resolution failures.

**Fix**:
- Changed explicit type declarations (e.g., `var npc: NPC`) to duck-typed Node/RefCounted
- Used preload() constants for script references
- Used load() at runtime for scripts that would cause cycles
- Example: `var current_npc: Node = null  # NPC - using Node to avoid cyclic dependency`

---

### BUG-005: Traps Not Triggering (RESOLVED)

**Severity**: MEDIUM
**Found**: 2026-02-05
**Status**: FIXED
**File(s)**: level.gd, dungeon_generator.gd, tile_mapper.gd, entity.gd

**Description**:
Traps were visible in vaults but did nothing when stepped on.

**Root Cause**:
1. TRAP tile type not defined in Level.Tile enum
2. Vault parser converted `^` symbols to FLOOR instead of TRAP
3. No trap trigger logic existed in movement system

**Fix**:
1. Added TRAP and TRAP_TRIGGERED to Level.Tile enum
2. Added on_entity_step() and _trigger_trap() functions to level.gd
3. Updated dungeon_generator to place actual TRAP tiles
4. Added tile_mapper coords for trap sprites
5. Wired entity.move_to() to call on_entity_step()

**Trap Mechanics**:
- Damage: 1d4 + depth/3
- Avoid chance: 50% + Perception×5%
- Triggers once per trap (tracked in triggered_traps dict)

---

## Statistics

| Severity | Open | Fixed | Won't Fix |
|----------|------|-------|-----------|
| CRITICAL | 0 | 0 | 0 |
| HIGH | 0 | 1 | 0 |
| MEDIUM | 0 | 1 | 0 |
| LOW | 1 | 0 | 1 |
