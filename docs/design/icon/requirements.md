# Icon Requirements for The Necromancer

## Platform Requirements

### Windows (.ico)
Required sizes in single .ico file:
- 16x16 - Taskbar, small icon view
- 32x32 - Desktop, medium icon view
- 48x48 - Large icon view
- 256x256 - Extra large icon view, Windows Vista+

Location: `src/necromancer.ico`
Referenced in: `src/necromancer.rc`

### macOS (.icns)
Required sizes for .icns bundle:
- 16x16 (icon_16x16.png)
- 32x32 (icon_16x16@2x.png, icon_32x32.png)
- 64x64 (icon_32x32@2x.png)
- 128x128 (icon_128x128.png)
- 256x256 (icon_128x128@2x.png, icon_256x256.png)
- 512x512 (icon_256x256@2x.png, icon_512x512.png)
- 1024x1024 (icon_512x512@2x.png)

Location: `src/cocoa/Necromancer_Icons.icns` and `Necromancer.app/Contents/Resources/Necromancer_Icons.icns`
Referenced in: `Necromancer.app/Contents/Info.plist` (CFBundleIconFile)

### Linux (.png)
Standard sizes:
- 16x16
- 32x32
- 48x48
- 128x128
- 256x256

Location: Various, typically alongside executable or in hicolor theme directories

## Current Icon Files

```
src/necromancer.ico          - Windows icon (currently old Sil icon)
src/Necromancer.icns         - macOS icon (currently old Sil icon)
src/cocoa/Necromancer_Icons.icns - Cocoa build icon
Necromancer.app/Contents/Resources/Necromancer_Icons.icns - App bundle icon
```

## Design Specification

- **Concept**: The Lidless Eye / Flaming Eye of Sauron
- **Style**: Clean, ominous, recognizable at small sizes
- **Palette**: Fiery orange/red/yellow with dark background
- **Key Elements**:
  - Vertical cat-eye pupil (black)
  - Fiery iris with gradient
  - Flame tendrils emanating outward
  - Dark/black background for contrast
