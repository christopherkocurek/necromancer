# Roguelike Threat Indicator Research

## Overview

Research into how various roguelikes communicate danger/threat levels to players.

## DCSS (Dungeon Crawl Stone Soup)

**Approach**: Depth-based with Danger Colors

DCSS uses several threat communication methods:
- **Depth Display**: Shows current dungeon branch and depth (e.g., "D:5", "Lair:3")
- **Monster Threat Colors**: Monsters are color-coded based on relative danger
  - Trivial (dark gray)
  - Easy (light gray)
  - Dangerous (yellow)
  - Very Dangerous (light red)
  - Extremely Dangerous (red)
- **Level Feelings**: Occasional messages like "You feel a terrible chill" for dangerous levels
- **Noise Meter**: Shows current noise level affecting monster awareness

**Takeaway**: Implicit threat via depth + explicit monster coloring

## Cogmind

**Approach**: Alert Level System

Cogmind features an explicit alert/danger level that:
- Increases when the player is detected or causes damage
- Decreases when advancing to new maps
- Affects enemy spawning and pursuit intensity
- Displayed prominently in the HUD
- Uses color progression to show escalation

**Takeaway**: Explicit numerical/visual alert that responds to player actions

## Brogue

**Approach**: Ambient and Implicit

Brogue communicates danger through:
- **Lighting**: Areas transition from lit to dark as danger increases
- **Message Colors**: Warning messages use progressively alarming colors
- **Monster Memory**: Remembered dangerous creatures shown in red
- **Depth Counter**: Simple depth display, player learns danger association

**Takeaway**: Atmospheric/implicit rather than explicit indicator

## Caves of Qud

**Approach**: Zone Difficulty Ratings

Caves of Qud uses:
- **Zone Tier Display**: Each region has a difficulty tier (1-8)
- **Reputation System**: Faction hostility shown via reputation meters
- **Color-coded Zone Names**: Zone names change color based on relative danger
- **Procedural Warning Messages**: NPCs warn about dangerous areas

**Takeaway**: Explicit zone ratings combined with reputation feedback

## Common Patterns Identified

### Color Progression (Most Common)
```
Safe     -> Low      -> Medium   -> High     -> Critical -> Doom
Green    -> Yellow   -> Orange   -> L.Red    -> Red      -> Violet
```

### Display Approaches
1. **Text Label**: "THREAT: HIGH" or "DANGER: SEVERE"
2. **Color Bar**: Gradient bar from green to red
3. **Icon**: Skull icons, warning symbols
4. **Border/Frame**: Map border changes color
5. **Ambient**: Background music/color shifts

### Trigger Mechanisms
1. **Static by Depth**: Fixed threat per floor (simplest)
2. **Dynamic by Enemies**: Adjusts based on nearby monster strength
3. **Event-based**: Spikes during pursuits or boss encounters
4. **Cumulative**: Increases over time, resets on floor change

## Recommendation for The Necromancer

Given the 7-layer dungeon structure and the "Pursuit Mode" mechanic after obtaining quest items:

**Primary Approach**: Static by Layer + Pursuit Override
- Base threat level determined by current layer (1-7)
- Override to maximum ("DOOM") when Pursuit Mode active
- Color-coded text label in left sidebar
- Flash/pulse animation on layer transitions

**Display Format**:
```
Layer 1: [GREEN]  "LOW"
Layer 2: [YELLOW] "GUARDED"
Layer 3: [ORANGE] "ELEVATED"
Layer 4: [L.RED]  "HIGH"
Layer 5: [RED]    "SEVERE"
Layer 6: [D.RED]  "CRITICAL"
Layer 7: [VIOLET] "DOOM"
Pursuit: [FLASH]  "HUNTED!"
```

This approach:
- Provides at-a-glance threat awareness
- Aligns with the layer-based dungeon design
- Supports the dramatic Pursuit Mode escalation
- Uses familiar roguelike color conventions

## Sources
- [DCSS Official](https://crawl.develz.org/)
- [Cogmind Official](https://www.gridsagegames.com/cogmind/)
- [Cogmind Genre Innovation](https://www.gridsagegames.com/cogmind/innovation.html)
