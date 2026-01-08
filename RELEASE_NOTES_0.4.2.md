# The Necromancer - Alpha 0.4.2
## Release Notes

**Date:** January 8, 2026
**Build:** Alpha 0.4.2 - Threat Indicator & Bugfixes
**Base:** SIL-Q fork, Third Age Dol Guldur setting

---

## What's New in Alpha 0.4.2

### TOWER THREAT INDICATOR

A new UI element in the left sidebar shows the current danger level based on dungeon depth.

#### Display Location
- Row 12 (between Spirit and Melee stats)
- Format: "Threat:Label" with color coding

#### Threat Levels

| Level | Depth Range | Label | Color |
|-------|-------------|-------|-------|
| LOW | 50-150ft (Depths 1-3) | Low | Green |
| GUARDED | 150-300ft (Depths 4-6) | Guard | Yellow |
| ELEVATED | 300-450ft (Depths 7-9) | Elev | Orange |
| HIGH | 450-600ft (Depths 10-12) | High | Light Red |
| SEVERE | 600-750ft (Depths 13-15) | Severe | Red |
| CRITICAL | 750-900ft (Depths 16-18) | Crit | Brown |
| DOOM | 900-1000ft (Depths 19-20) | Doom | Violet |
| HUNTED | Any (Pursuit Mode) | HUNTED! | Flashing Red/White |

#### Pursuit Mode
When the player has the Silmaril and Key and escapes the throne room, the threat indicator switches to "HUNTED!" with a flashing red/white animation. This persists until escape or death.

---

### BUGFIXES (from 0.4.1)

#### Smithing System
- **Masterwork XP/Turn Display**: Masterwork menu now shows XP cost and turns required for each ability
- **Reforge Key Conflict**: Fixed 'h' key conflict between hafted and shield - shield now uses 'i'
- **Reclaim Type Selection**: Added submenu to select specific item types when reclaiming artifacts
- **Masterwork Type Selection**: Added submenu to select specific item types when adding abilities

#### Dungeon Generation
- **Sauron's Lair Escape**: Fixed glitch where staircases could be missed during throne room escape; now searches entire map and creates fallback staircase if needed
- **Double Forge Vaults**: Fixed Scout Camp (2→1 forge) and Orc Forge (3→1 forge) having excessive forges

#### Balance
- **Supply Cache Vault**: Increased minimum depth from 4 to 8, reduced treasures from 8→4 amulets and 8→4 rings

#### Text Corrections
- **Tolkien Accents**: Added proper accents to Lothlórien and Dúnedain
- **Spirit Rename**: Changed "Voice" to "Spirit" throughout UI (matches in-game terminology)

#### New Content
- **Istari Starting Equipment**: Istari now start with Feanorian Lamp, Horn of Blasting, and 10 Lembas

---

## Technical Details

### Files Modified

#### Threat Indicator
- `src/defines.h` - Added THREAT_* constants (1-8), ROW_THREAT (12), COL_THREAT (0)
- `src/xtra1.c` - Added prt_threat() and helper functions, integrated into prt_frame_basic()

#### Bugfixes
- `src/cmd4.c` - Smithing submenu improvements
- `src/generate.c` - Throne room staircase search fix
- `src/files.c` - Spirit rename
- `lib/edit/vault.txt` - Forge count fixes, Supply Cache balance
- `lib/edit/artefact.txt` - Tolkien accent corrections
- `lib/edit/object.txt` - Tolkien accent corrections
- `lib/edit/race.txt` - Istari starting equipment

### Design Documents Created
- `docs/design/threat_ui/ui_audit.md` - Current UI layout analysis
- `docs/design/threat_ui/research.md` - Roguelike threat indicator research
- `docs/design/threat_ui/threat_levels.md` - Threat level system design
- `docs/design/threat_ui/placement_options.md` - UI placement evaluation
- `docs/design/threat_ui/escalation_behavior.md` - Alert behavior specification
- `docs/design/threat_ui/FINAL_SPEC.md` - Consolidated implementation spec

---

## Known Issues

- Build requires compatible macOS/Linux environment with appropriate development tools
- QuickTime.h deprecation on modern macOS affects legacy Carbon build

---

## Credits

Development assisted by Claude Code (Anthropic)
