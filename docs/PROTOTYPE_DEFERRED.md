# Prototype Deferred Items

Items flagged for post-prototype implementation due to architectural complexity.

---

## Deferred Abilities

### 8B.1.3: Deep Memory (Ability 142)

**What**: Reveal dungeon layout (show all rooms/corridors on map)

**Why Deferred**:
- Current implementation auto-reveals terrain when visited
- Level.gd `explored` array tracks what player has seen
- Implementing "reveal all" is trivial, but it creates a design problem:
  - If map is auto-revealed by walking, Deep Memory is useless
  - Proper implementation requires fog-of-war that HIDES unvisited areas
  - This is a fundamental change to the rendering pipeline

**Architectural Change Required**:
1. Add `revealed` array separate from `explored`
2. Terrain tiles only render if `revealed[x][y] == true` OR player has Deep Memory active
3. FOV updates `explored`, Deep Memory updates `revealed`
4. UI minimap would need to respect this distinction

**Effort Estimate**: Medium (2-4 hours)

**Post-Prototype Priority**: HIGH - Deep Memory is a signature Lore ability

---

### 8B.1.8: Inner Light (Ability 147)

**What**: +1 light radius per 5 Lore skill

**Why Deferred**:
- Current FOV system uses fixed `FOV_RADIUS = 8` constant
- Player has no `light_radius` property
- Monsters have `light_radius` in data but it's not used for dynamic lighting

**Architectural Change Required**:
1. Add `light_radius` property to Player
2. Make FOV calculation use `player.light_radius` instead of constant
3. Implement ability effect that modifies `light_radius`
4. Consider: Should this persist or require active maintenance?

**Effort Estimate**: Low-Medium (1-2 hours)

**Post-Prototype Priority**: MEDIUM - Nice-to-have but not core gameplay

---

## Other Deferred Items

### Dynamic Lighting System

**What**: Per-entity light sources (torches, glowing enemies, magic effects)

**Why Deferred**:
- Would require light accumulation shader
- Performance implications for many light sources
- Current FOV binary (visible/not visible) is simpler

**Post-Prototype Priority**: LOW - Visual polish, not gameplay

---

### Dungeon Memory Between Levels

**What**: Remember dungeon layouts when ascending/descending

**Current Behavior**: New dungeon generated each visit (roguelike standard)

**Why Deferred**:
- Requires storing level data in save file
- Memory implications for 20 levels of dungeon data
- Design question: Should monsters persist? Items?

**Post-Prototype Priority**: LOW - Traditional roguelikes don't do this

---

### Multi-tile Monsters

**What**: Large creatures (dragons, trolls) spanning 2x2 or larger

**Why Deferred**:
- Current entity system assumes 1 tile = 1 entity
- Pathfinding would need to account for entity size
- Combat targeting would need adjustment

**Post-Prototype Priority**: LOW - Can represent size through stats instead

---

## Review Checklist

When returning to deferred items post-prototype:

1. [ ] Re-evaluate priority based on player feedback
2. [ ] Check if architectural changes affect other systems
3. [ ] Estimate effort with current codebase knowledge
4. [ ] Consider if simpler alternatives exist
5. [ ] Document any new deferrals that arise

---

## Version History

| Date | Change |
|------|--------|
| 2026-02-05 | Initial creation with Deep Memory and Inner Light deferrals |
| 2026-02-05 | Phase 8B.1: Implemented 10/12 Lore abilities (142 & 147 deferred) |
