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
| `Shift+F` | Defensive stance |
| `Shift+P` | Ready parry |
| `Shift+H` | Mark quarry (Hunting) |
| `Shift+X` | Expose weakness (Hunting) |
| `Shift+E` | Exploit opening (Hunting) |
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
  docs/             # Slim beta docs for internal test distribution
```

## Development Status

**Beta v1.1 internal build** -- slim tester distribution.

- 88 monsters, 214 items, 104 artifacts, 93 abilities across 8 skill trees
- 7 dungeon layers with distinct themes (Outer Pits through Throne Room)
- Full smithing system with 5 recipe types and ego enchantments
- Sustained song system (Song of Freedom, Song of the Trees, Song of Aule)
- 4 difficulty modes (Easy, Normal, Hard, Ironman)
- Named Tolkien bosses at layer transitions
- Includes gameplay/UI fixes through the latest Beta v1.1 pass.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) -- System architecture and dependency graph
- [tutorial.md](tutorial.md) -- Tester-facing tutorial notes
- [docs/GAME_DESIGN_DOCUMENT_BETA_V1_1.md](docs/GAME_DESIGN_DOCUMENT_BETA_V1_1.md) -- Canonical Beta v1.1 game design document
- [docs/pdf/GAME_DESIGN_DOCUMENT_BETA_V1_1.pdf](docs/pdf/GAME_DESIGN_DOCUMENT_BETA_V1_1.pdf) -- PDF export of the Beta v1.1 game design document
- [docs/manual/THE_NECROMANCER_MANUAL_BETA_V1_1.md](docs/manual/THE_NECROMANCER_MANUAL_BETA_V1_1.md) -- Canonical Beta v1.1 player's manual
- [docs/pdf/THE_NECROMANCER_MANUAL_BETA_V1_1.pdf](docs/pdf/THE_NECROMANCER_MANUAL_BETA_V1_1.pdf) -- PDF export of the Beta v1.1 player's manual

## Credits

Based on [Sil-Q](https://github.com/sil-quirk/sil-q) by half and others, itself derived from Sil by Necklace of the Eye and Pacauri. Set in Tolkien's Middle-earth. Tileset from [DCSS](https://crawl.develz.org/) (GPL v2+). Custom sprites generated with DALL-E.

## License

This project uses the DCSS tileset which is licensed under GPL v2+. Any distribution of the game must comply with that license.
