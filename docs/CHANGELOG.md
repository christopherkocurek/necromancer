# Changelog

All notable changes to The Necromancer are documented in this file. Commits are grouped by development session.

---

## Session S: Ralph Loop (2026-02-08)

Eight-tier implementation pass focused on closing the largest remaining gaps between the Godot build and the Sil-Q C source. Named "Ralph Loop" after the iterative test-fix-improve cycle.

### Tier 8: Victory Path Balance + Difficulty Modes
`a7ef179`

- Added 4 selectable difficulty modes: Easy, Normal, Hard, Ironman
- Easy: +50% XP, -25% monster damage, +25% item spawns, revealed traps
- Hard: -20% item spawns, +25% monster perception, no pity spawns
- Ironman: Hard mode plus no rest healing
- Scaled monster XP rewards by depth and rarity
- Difficulty selection integrated into character creation

### Tier 7: Map Generation Enrichment
`ae2fa1e`

- Added cave rooms (cellular automata irregular shapes) for Outer Pits layer
- Added alcove rooms (rectangle with wall alcoves) for Necropolis layer
- Environmental storytelling: inscriptions, bone piles, scattered items
- Layer-themed decorative features
- Improved corridor generation variety

### Tier 6: Procedural Description Depth
`49e64d7`

- DescriptionGenerator system: 500+ templates with state-aware variations
- Monster descriptions based on display character, color, and knowledge tier
- Health-aware descriptions ("It looks badly wounded")
- Morale-aware descriptions ("It seems ready to flee")
- Layer-aware environmental context
- Ego enchantment descriptions on items
- Used by MonsterMemory, LookPanel, and DeathScreen

### Test Infrastructure Fix
`cb6cbf2`

- Fixed test_runner.gd argument parsing for GUT test isolation
- Tests can now run individually without conflicting with each other

### Tier 5: Custom Tolkien Bosses
`e010a90`

- 3 named Tolkien bosses per layer transition (depths 3, 6, 9, 12, 15, 18, 20)
- Boss pool with random selection each run for replayability
- Bosses get HP multiplier, XP multiplier, unique flag
- Boss rooms generated at layer transition depths
- Final boss at depth 20

### Tier 4: Sustained Song System
`1631b23`

- Implemented Sil-Q singing mechanic as sustained songs
- Song of Freedom: +3 evasion while singing (1 voice/turn)
- Song of the Trees: +5 stealth while singing (1 voice/turn)
- Song of Aule: +2 melee, +1 smithing while singing (2 voice/turn)
- Toggle on/off via voice menu (V key)
- Song ends automatically when voice is depleted
- Voice regeneration reduced while singing

### Tier 3: Game Balance -- Monster Drops, Ego Enchantments
`98adeb2`

- Monster drops scaled by depth and monster rarity
- 6 ego enchantment types on random weapon/armor drops
- HP bump for early-game survivability
- Ego types: Flaming, Frost, Venom, Sharpness, Warding, Speed

### Tier 2: Stealth Overhaul
`740d81a`

- Detection eye indicator in HUD (shows monster awareness state)
- Switched stealth checks to d10 (from d20) for more impactful skill investment
- Floor-wide alertness system: noise raises global alertness, decays over time
- Stealth distance bonus: max(0, 6 - distance)
- Assassination attack bonus: +STL vs unwary/sleeping targets
- Noise generation per action type

### Tier 1: Smithing System Overhaul
`aeb9278`

- 5 recipe types: Create Weapon, Create Armor, Create Jewelry, Reforge, Reclaim
- Mithril as forge material (found in dungeon)
- Broken Glowing items for Reforge, Broken Strange items for Reclaim
- Smithing success formula: min(smithing * 8, 95)
- Fixed Parry mechanic (was not applying weapon-based block)
- Forge material drops from appropriate depth ranges

---

## Session S: Automated Testing Mega-Pass (2026-02-07)

Four parallel test streams to establish a comprehensive test suite.

### Stream C: Dungeon Generation Validator
`203fea7`

- Dungeon generation validation tests
- BFS connectivity checks post-generation
- Room placement and overlap verification
- Stair placement validation
- Integration with test runner

### Stream B: Gameplay Scenario Tests
`b573885`

- 5 new test files covering abilities, status effects, combat, inventory, dungeon generation, and level transitions
- 154 tests, 1214 assertions
- Scenario-based testing for complex multi-system interactions

### Stream D: Survival Bot
`4cf0214`

- Intelligent 20-floor auto-play bot with telemetry
- Tests full game loop from character creation to depth 20
- Collects statistics: damage taken, monsters killed, items used, floors cleared
- Archetype configurations for different playstyles

### Stream A: Fuzz Bot
`ea0950e`

- Random action crash finder running 500+ turns
- Tests that no combination of random inputs causes a crash
- Catches freed instance references, null pointer exceptions, edge cases

---

## Session R: Tileset Quality Pass (2026-02-06)
`1602723`

- Layer tile kits: distinct visual themes for each of 7 dungeon layers
- Tileset quality pass: sprite cleanup, color consistency, edge fixing
- Auto-explore through doors (doors open automatically during auto-explore)
- Misc bug fixes from quality testing

---

## Session Q: Bugfix + Polish Mega-Pass (2026-02-05)
`2245123`

- 6 parallel bugfix streams targeting the highest-impact issues
- Polish pass across all UI panels
- Message log improvements
- Combat feedback clarity
- Various crash fixes

---

## Sessions L-O: Scroll UI, Tile Cleanup, Window Scaling (2026-02-04)
`0dc5da6`

- Session L: Ability XP cost system overhaul to match Sil-Q economy
- Session M: Tome panel redesign, scroll UI overhaul
- Session N: Tile cleanup pass, fixing damaged sprites
- Session O: Gamma correction fix, SCROLL_INK color, window scaling
- Parse fixes for edge cases in data files

### Ability XP Cost Overhaul
`80e89dc`

- Skill cost formula: 100 * (level + 1) per point
- Affinity discount: -100 per level for house-affiliated skills
- XP economy rebalanced to match Sil-Q progression curve

---

## Session K: Bug Fix Mega-Pass (2026-02-03)
`555031b`

- 6 parallel streams fixing highest-priority bugs
- Tileset repair pass: edge-only background removal fixes 206 damaged sprites
  (`ada4cc6`)
- Crash fixes, null reference guards, freed instance protections
- Combat formula corrections
- UI responsiveness improvements

---

## Session J: Procedural Map Overhaul (2026-02-02)
`dd9fdfd`

- 7 distinct dungeon layers with unique generation parameters
- Vault transforms (rotation, mirroring) for variety
- Themed monster spawning per layer
- Layer-specific room count, size, and corridor width
- Layer tint colors and atmospheric messages

---

## Session I: Mega Improvement (2026-02-01)
`94da7fe`

- 9 bug fixes across core systems
- Audio system: ambient sounds, combat SFX, UI feedback
- 15 new rings and amulets with effects
- Terrain overhaul: new tile types, visual variety
- Backstory generator for character creation

---

## Sessions F-H: All Sprites (2026-01-30 - 2026-01-31)

### All DALL-E Sprites + Sil-Q Systems
`9dec0e5`

- Complete sprite set: all monsters, items, artifacts, terrain
- 7 Sil-Q systems implemented (consumables, horns, staves, wands, herbs)
- Artifact pipeline: data parsing, sprite generation, gameplay effects
- Multiple bug fixes

### DALL-E Monster Sprites Tier 1
`5a10da7`

- 13 custom monster sprites generated with DALL-E
- HSV magenta correction pipeline for background removal

---

## Sessions D-E: Bug Fixes, Balance, VFX (2026-01-28 - 2026-01-29)

### Tome Panel + DALL-E Terrain
`3164a74`

- Tome panel combining skills and abilities into unified UI
- DALL-E terrain and player sprites
- Hunger system implementation
- Light ecology (torch/lantern/lamp hierarchy)
- Combat VFX improvements

### Diablo-Inspired UI Reskin
`d85c295`

- Dark fantasy UI theme
- Trait archetypes for character variety
- Voice/Grace scaling system

### HP Formula Fix
`53a1d4f`

- Fixed HP formula to match Sil-Q: 24 * 1.2^CON

### Stealth, FOV, Regen Bugs
`66c715b`

- Fixed stealth calculation bugs
- Fixed FOV edge cases
- Fixed regeneration timing
- Added voice ability menu (V key)

### Hero Traits + Combat VFX
`3a11658`

- 10 hero traits with unique gameplay effects
- 6 combat VFX types (hit flash, crit flash, miss, dodge, block, heal)
- Starting equipment fixes

---

## Sessions A-C: Core Implementation (2026-01-24 - 2026-01-27)

### Phase 4: Core Ability Implementation
`0752153`

- Passive abilities, archery abilities, lore powers
- Ability activation framework

### Phase 3: Unlock Broken Heroes
`80ed3b9`

- Hobbit race added
- Archery system foundation
- Racial mechanics (stat modifiers, proficiencies)

### Phase 2: Systemic Fixes
`0aa5b85`

- Status effects behavioral integration
- Stat drain mechanics
- Affinity discount system

### Phase 1: Hero Trait System
`ce3a9f7`

- 10 hero traits integrated into character creation
- Trait effects on gameplay mechanics

### Phase 0: Fix the Two Games Problem
`5ce508d`

- Diversified monster spawns across Layers 4-7
- Fixed monster type monotony at mid-depths

### UI/UX Overhaul
`a3c13ae`

- HUD redesign with health bars, status indicators
- Color migration to ThemeColors system
- Minimap implementation
- Entity health bar system

### Phase 9: FOV/Lighting
`cd36d23`

- FOV/lighting separation (geometry vs light radius)
- Room glow system
- UI polish pass
- Tileset tooling

### Phase 8: Feature Parity
`b77ecb0`

- Code review fixes
- Test suite foundation
- Feature parity audit

### Phase 7: DCSS Tileset Integration
`915cb5c`

- DCSS tileset rendering with TileMapper
- Monster sprite fix pipeline

### Phase 6: Skills Panel + Abilities Browser
`21852e6`

- Skills panel UI
- Abilities browser with XP cost display
- Test framework foundation

### Phase 5A/5B: Character Creation + Inventory UI
`a924807`

- Character creation flow (race, house, stats, name)
- Inventory panel with equip/unequip/drop

### Phase 5 Blockers
`40e7cdb`

- Fixed Sil-Q mechanics foundation issues blocking Phase 5

### Phase 4: Sil-Q Data Layer Foundation
`ca01cd9`

- Complete data parser for Sil-Q format files
- Monster, item, ability, race, house data loading

---

## Initial Development (2026-01-22 - 2026-01-23)

### First Playable Prototype
`c88caed`

- Dungeon rendering with basic room-and-corridor generation
- Player movement, bump-to-attack combat
- Turn system with energy-based timing

### Architecture Diagram
`a2a1f17`

- Initial ARCHITECTURE.md with system diagrams

### Data Parser Fix
`b69c273`

- Fixed Sil-Q data format parsing edge cases

### Initial Project Setup
`4997fc5`

- Godot 4.6 project scaffolding
- Directory structure, main scene, initial scripts
