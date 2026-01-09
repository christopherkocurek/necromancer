# Known Issues - The Necromancer Beta 1.0.0

This document lists known issues and limitations in the current beta release.

## Critical Issues

None currently known.

## Gameplay Issues

### Balance
- **Consumables balance not finalized**: Wand charges and herb effects may need adjustment based on playtesting feedback
- **Equipment damage values**: Some renamed weapons may have balance issues from Sil-Q that persist

### Mechanics
- **Wand targeting**: Wands use standard item targeting; more intuitive aiming system planned for future
- **Poison streams**: Now always apply poison; difficulty tuning may be needed

## Technical Issues

### macOS
- **Gatekeeper warning**: First launch may require right-click > Open to bypass unsigned app warning
- **Documents folder access**: Game requests access to Documents for save files on macOS 10.15+
- **High DPI displays**: Some UI elements may appear small on Retina displays

### Windows
- **Windows Defender**: May flag executable as unknown; allow through if prompted
- **Path with spaces**: Installing in paths with spaces may cause issues

### Linux
- **Terminal compatibility**: GCU mode requires ncurses; some terminals may have color issues
- **X11 required**: Graphical mode requires X11 libraries

## Content Issues

### Documentation
- **Manual PDF**: Contains Sil-Q branding; full content update pending
- **In-game help**: Some help text still references Sil mechanics

### Assets
- **Application icon**: Using placeholder; custom Flaming Eye icon in development
- **Tiles**: Using MicroChasm tileset from Sil-Q

## Reporting New Issues

Please report bugs at: https://github.com/sil-quirk/sil-q/issues

Include:
1. Platform and version (Windows/macOS/Linux)
2. Steps to reproduce
3. Expected vs actual behavior
4. Character dump if applicable (press `|` then `f`)
5. Any error messages

## Version History

- **1.0.0-beta**: Initial beta release (January 2026)
