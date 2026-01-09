# The Necromancer Changelog

## Version 1.0.0-beta (January 2026)

Initial beta release of The Necromancer, forked from Sil-Q 1.5.0.

### Major Changes

#### New Setting: Dol Guldur
- Game now set in Dol Guldur during the Third Age
- New welcome screen with thematic introduction
- Victory condition: Retrieve Thrain's ring, the key, and the map

#### Equipment Renames
- All weapons renamed to fit Necromancer theme
  - Daggers, swords, axes, and polearms with new names
  - Examples: "Blade of Shadows", "Morgul-knife", etc.
- All armor renamed to fit setting
  - Leather, mail, and plate armor variants
- Artefacts updated with lore-appropriate names

#### Consumables Rework
- Added wands as new item type (TV_WAND)
  - Wand of Sleep
  - Wand of Confusion
  - Wand of Slowing
  - Wand of Fear
  - Wand of Fire
  - Wand of Cold
  - Wand of Lightning
- Added new food/herb items
  - Various herbs with beneficial effects
- Removed harmful consumables (confused scrolls, bad potions)

#### Gameplay Changes
- Poison streams now always apply poison (no Con check to avoid)
  - Con check determines severity: pass = 2-6 turns, fail = 5-15 turns
- Istari class updated with new starting equipment

### Technical Changes

#### Rebranding
- Renamed executable from `sil` to `necromancer`
- Updated window titles and menu items
- New application icons (placeholder - custom Flaming Eye icon pending)
- Updated Info.plist and project files

#### Build System
- Updated MSVC 2022 project files
- Updated macOS Cocoa build
- Renamed resource files to necromancer.rc, necromancer.ico, etc.

#### Cleanup
- Removed 100+ internal design documents
- Removed old launcher scripts
- Cleaned up unused lib/edit files
- Removed development artifacts

### Known Issues
See KNOWN_ISSUES.md for current beta limitations.

### Credits
Based on Sil by Scatha and Fingolfin, and Sil-Q by the Sil-Q community.

---

For full Sil-Q history, see lib/docs/changes.txt and lib/docs/early-changes.txt.
