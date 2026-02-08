# The Necromancer

**A Tolkien Roguelike**

A turn-based roguelike set in Dol Guldur, the Hill of Dark Sorcery, inspired by [Sil-Q](https://github.com/sil-quirk/sil-q). You play a hero descending through seven layers of Sauron's fortress -- navigating procedural dungeons, fighting Tolkien creatures, forging weapons at ancient smithies, and wielding the voice abilities of the Eldar. Reach the depths to find the Ring of Thrain and escape alive, or challenge the Necromancer himself.

Built in Godot 4.6 with GDScript. All game data ported from the Sil-Q C source (monsters, items, abilities, races, vaults).

## Quick Start

**Requirements:** [Godot 4.6](https://godotengine.org/download) or later

```bash
git clone <repo-url>
cd necromancer-godot
# Open in Godot editor, then press F5 to run
# Or run from command line:
/path/to/Godot --path .
```

## Controls

### Movement
| Key | Action |
|-----|--------|
| `W/A/S/D` | Move cardinal directions |
| `H/J/K/L` | Move cardinal (vi-keys) |
| `Y/U/B/N` | Move diagonal |
| Arrow keys | Move cardinal |
| `.` / Numpad `5` | Wait one turn |
| `Enter` | Use stairs (up or down) |
| `O` | Auto-explore |
| `Z` | Rest until full HP/voice |
| `Shift+Z` | Rest for 20 turns |

### Combat & Abilities
| Key | Action |
|-----|--------|
| Bump | Melee attack (move into enemy) |
| `F` | Fire ranged weapon (if bow equipped) / Use forge |
| `V` | Voice ability menu |
| `1-4` | Ability hotkey quick-cast |
| `Shift+1-4` | Bind ability to hotkey (in voice menu) |
| `;` | Toggle stealth mode |
| `D` | Disarm trap |

### Items & Consumables
| Key | Action |
|-----|--------|
| `G` | Pick up item |
| `E` | Equip from floor |
| `I` | Open inventory |
| `Shift+D` | Drop item |
| `Q` | Quaff potion |
| `R` | Read scroll |
| `,` | Eat food/herb |
| `P` | Blow horn/flute |

### UI & Information
| Key | Action |
|-----|--------|
| `T` | Open Tome (skills + abilities) |
| `@` | Open Tome (alternate) |
| `X` | Look mode (inspect tiles/monsters) |
| `M` | Toggle minimap |
| `Tab` | Expand/collapse bottom bar |
| `?` | Help overlay |
| `Esc` | Settings panel |
| Mouse wheel | Zoom in/out |

## Project Structure

```
necromancer-godot/
  scripts/
    core/           # Singletons: GameManager, EventBus, DataManager, TileMapper,
                    #   ThemeColors, AudioManager
    entities/       # Entity, Player, Monster, Item, NPC, Thrain
    systems/        # DungeonGenerator, TurnSystem, AbilitySystem, SmithingSystem,
                    #   ConsumableSystem, HornSystem, StatusEffects, Level,
                    #   StealthSystem, DescriptionGenerator, QuestSystem
    ui/             # HUD, InventoryPanel, TomePanel, CharacterCreation,
                    #   DeathScreen, VictoryScreen, SmithingPanel, LookPanel,
                    #   TargetPanel, BestiaryPanel, SettingsPanel, HelpOverlay
  data/             # Sil-Q data files: monster.txt, object.txt, ability.txt,
                    #   artefact.txt, race.txt, house.txt, terrain.txt, vault.txt
  assets/
    sprites/        # DCSS tileset + DALL-E custom sprites
    audio/          # Sound effects and ambient audio
  scenes/           # Godot .tscn scene files
  tests/
    unit/           # GUT unit tests (combat, FOV, energy, status effects)
    gameplay/       # Scenario tests (abilities, inventory, dungeon gen, transitions)
    integration/    # Turn flow integration tests
    bot/            # Fuzz bot, survival bot, archetype configs
  docs/             # Design documents, gap analysis, balance reports
```

## Development Status

**Alpha build** -- 46 commits, 58k lines, 162 files. All core systems implemented. Validated with 120 automated bot playthroughs across 6 archetypes.

- 88 monsters, 214 items, 104 artifacts, 93 abilities across 8 skill trees
- 7 dungeon layers with distinct themes (Outer Pits through Throne Room)
- Full smithing system with 5 recipe types and ego enchantments
- Sustained song system (Song of Freedom, Song of the Trees, Song of Aule)
- 4 difficulty modes (Easy, Normal, Hard, Ironman)
- Named Tolkien bosses at layer transitions
- 125/130 automated tests passing, 684 assertions
- 120 bot playthroughs: 0% win rate confirms difficulty is balanced for skilled play

See [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) for current limitations and [docs/CHANGELOG.md](docs/CHANGELOG.md) for version history.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) -- System architecture and dependency graph
- [docs/GAME_DESIGN_DOCUMENT.md](docs/GAME_DESIGN_DOCUMENT.md) -- Complete game design document
- [docs/BALANCE_REPORT.md](docs/BALANCE_REPORT.md) -- 120-run bot playthrough analysis
- [docs/CHANGELOG.md](docs/CHANGELOG.md) -- Full development history
- [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) -- Known bugs and unimplemented features
- [docs/PARITY_ANALYSIS.md](docs/PARITY_ANALYSIS.md) -- C source vs Godot feature comparison

## Credits

Based on [Sil-Q](https://github.com/sil-quirk/sil-q) by half and others, itself derived from Sil by Necklace of the Eye and Pacauri. Set in Tolkien's Middle-earth. Tileset from [DCSS](https://crawl.develz.org/) (GPL v2+). Custom sprites generated with DALL-E.

## License

This project uses the DCSS tileset which is licensed under GPL v2+. Any distribution of the game must comply with that license.
