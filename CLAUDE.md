# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a fork of Sil-Q (a roguelike game derived from Angband) being converted into "The Necromancer" - a Third Age Middle-earth setting where players infiltrate Dol Guldur instead of Angband. See `THE_NECROMANCER_GDD.md` for the full game design document.

## Build Commands

### macOS (primary development platform)
```bash
cd src
make -f Makefile.cocoa install     # Build and install Sil.app to parent directory
make -f Makefile.cocoa clean       # Clean object files
```

For Apple Silicon native build:
```bash
make -f Makefile.cocoa ARCHS=arm64 install
```

For universal binary:
```bash
make -f Makefile.cocoa ARCHS='x86_64 arm64' install
```

### Linux
```bash
cd src
make -f Makefile.std install
```

### Windows (Cygwin)
```bash
cd src
make -f Makefile.cyg install
```

## Architecture

### Source Code (`src/`)
- **Core headers**: `angband.h` includes everything; `defines.h` has constants, `types.h` has structs, `externs.h` has declarations
- **Initialization**: `init1.c` parses text data files, `init2.c` loads/creates binary `.raw` files
- **Character creation**: `birth.c` handles race/house selection and character generation
- **Dungeon**: `generate.c` creates levels, `dungeon.c` is the main game loop
- **Combat**: `melee1.c`/`melee2.c` for melee, `spells1.c`/`spells2.c` for abilities/effects
- **Commands**: `cmd1.c` through `cmd6.c` handle player actions
- **UI**: `main-cocoa.m` (macOS), `main-gcu.c` (terminal), `main-x11.c` (X11)

### Data Files (`lib/edit/`)
Text files that define game content, compiled to `lib/data/*.raw` at runtime:
- `race.txt` - Player races (Elf, Man, Dwarf)
- `house.txt` - Player houses (3 per race, 9 total)
- `monster.txt` - All monsters with stats, attacks, flags
- `artefact.txt` - Unique artifacts
- `object.txt` - Item types and properties
- `ability.txt` - Skills and abilities
- `terrain.txt` - Dungeon features
- `vault.txt` - Special room templates
- `limits.txt` - Array size limits (M:P for races, M:C for houses, etc.)
- `flavor.txt` - Random item appearances (ring/potion colors)

### Data File Format
Each file uses a line-based format with type prefixes:
- `N:index:name` - Entry header
- `S:stat1:stat2:...` - Stats
- `F:FLAG1 | FLAG2` - Flags (pipe-separated)
- `D:description text` - Multi-line descriptions

### Important Caching Behavior
**Critical**: The game caches compiled data in `~/Documents/Sil/Sil-Q/data/*.raw`. After modifying `lib/edit/*.txt` files:
1. Delete the cached `.raw` files: `rm -rf ~/Documents/Sil/Sil-Q/data/*.raw`
2. Copy updated `.txt` files to app bundle: `cp lib/edit/*.txt Sil.app/Contents/Resources/lib/edit/`
3. Rebuild if source changed: `make -f Makefile.cocoa install`

The app bundle at `Sil.app/Contents/Resources/lib/edit/` contains its own copy of data files used at runtime.

### Key Defines (`src/defines.h`)
- `S_MEL`, `S_ARC`, `S_EVN`, `S_STL`, `S_PER`, `S_WIL`, `S_SMT`, `S_LOR` - Skill indices (0-7)
- `RHF_*` flags - Race/house flags for proficiencies and affinities
- `R_IDX_*` - Monster race indices for boss monsters
- Version info: `VERSION_NAME`, `VERSION_STRING`

### Adding New Flags
To add a new flag (e.g., `SWORD_PROFICIENCY`):
1. Add `#define RHF_FLAGNAME 0x00040000L` in `defines.h`
2. Add `{ "FLAGNAME", RHF, RHF_FLAGNAME }` to `info_flags[]` in `init1.c`
3. Use in data files: `F:FLAGNAME`

### Skill System
The game has 8 skills defined in `defines.h`:
- Melee (S_MEL), Archery (S_ARC), Evasion (S_EVN), Stealth (S_STL)
- Perception (S_PER), Will (S_WIL), Smithing (S_SMT), Lore (S_LOR)

Houses have skill affinities defined by flags like `MEL_AFFINITY`, `LOR_AFFINITY`, etc.
