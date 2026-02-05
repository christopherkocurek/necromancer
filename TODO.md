# Necromancer Godot - Shared TODO

This file coordinates work between parallel Claude sessions.

**Main repo:** `~/dev/active/games/necromancer-godot` (master)
**Bugfix worktree:** `~/dev/worktrees/necromancer-bugfix` (bugfix branch)
**Features worktree:** `~/dev/worktrees/necromancer-features` (features branch)

---

## Coordination Rules

1. **Claim tasks before starting** - Add your initials and timestamp
2. **Mark completed tasks** - Move to Done section with commit hash
3. **Communicate blockers** - Note any dependencies between tasks
4. **Sync regularly** - Pull from master before starting new work

---

## Bugfix Agent Tasks

| Status | Priority | Task | Notes |
|--------|----------|------|-------|
| [ ] | HIGH | [BUG] Audit all .gd files for untyped `var err = ...` patterns | Type inference crashes |
| [ ] | MED | [BUG] Check sprite timing issues - pending values pattern | See skill.md |
| [ ] | LOW | [BUG] Review null checks on sprite references | Potential crashes |

---

## Features Agent Tasks

| Status | Priority | Task | Notes |
|--------|----------|------|-------|
| [ ] | HIGH | [FEATURE] Turn system with energy/speed | Phase 3 |
| [ ] | HIGH | [FEATURE] Visual feedback delays (show results before next turn) | Phase 3 |
| [ ] | HIGH | [FEATURE] Combat mechanics (attack rolls, defense, damage) | Phase 3 |
| [ ] | MED | [FEATURE] Basic monster AI (pathfinding, aggression) | Phase 3 |
| [ ] | MED | [FEATURE] FOV / visibility (line-of-sight) | Phase 3 |
| [ ] | MED | [FEATURE] Dungeon generation (rooms + corridors) | Phase 3 |
| [ ] | LOW | [FEATURE] Status effect indicators (buff/debuff icons) | Phase 4 |

---

## Shared/Blocked

Tasks that need coordination or are blocked:

| Task | Blocked By | Notes |
|------|------------|-------|
| | | |

---

## Done

| Task | Branch | Commit | Date |
|------|--------|--------|------|
| | | | |

---

## Notes

_Add any cross-agent communication here_

