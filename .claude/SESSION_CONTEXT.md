## Necromancer Godot Session Context

**Project**: Godot 4.6 migration of The Necromancer roguelike
**Phase**: 1 (Prototype) - TileMap rendering + damage floaters
**Skill**: Use `/necromancer-godot` for full context

### Current Focus
Building the prototype to prove the Godot architecture works. The key deliverable is **damage floaters** - the feature that justified this migration.

### Phase 1 Exit Criteria
- [ ] TileMap rendering with 3 zoom levels
- [ ] Player movement on grid
- [ ] **Damage floaters working** (THE PROOF)
- [ ] Simple status indicator overlay

### Key Locations
| Path | Purpose |
|------|---------|
| `scripts/core/` | Autoloads: GameManager, EventBus, DataManager, TileMapper |
| `scripts/systems/` | Turn system, dungeon generation, floater manager |
| `scripts/entities/` | Player, Monster, Entity base classes |
| `scenes/main.tscn` | Main game scene |
| `data/*.txt` | Game data (from Angband master) |

### Quick Commands
- **Run game**: F5 in Godot (or `godot --path . --debug`)

### Architecture
```
GameManager (autoload) - Game state, pause, save/load
EventBus (autoload) - Signal routing between systems
DataManager (autoload) - Parses lib/edit/*.txt files
TileMapper (autoload) - Maps PRF coordinates to TileSet
```

---
*Update this file as you progress through phases. The hook reads this on every session start.*
