# Controls and Interface

## Movement

### Basic Movement

Move using the numpad or vi-keys:

```
Numpad:          Vi-keys:
7  8  9          y  k  u
 \ | /            \ | /
4 -5- 6          h -.- l
 / | \            / | \
1  2  3          b  j  n
```

**5** or **.** - Wait one turn (pass)

### Running

**Shift + direction** - Run in that direction until interrupted

Running continues until you:
- See an enemy
- Reach an intersection
- Hit an obstacle

Running generates more noise than walking.

### Stairs

**<** - Go up stairs (when standing on up stairs)
**>** - Go down stairs (when standing on down stairs)

## Combat

**Direction toward enemy** - Attack in melee
**f** - Fire ranged weapon
**t** - Throw an item

### Targeting

When using ranged attacks:
- Use direction keys to select target
- **Enter** or **f** again to confirm
- **Escape** to cancel

## Inventory

**i** - View inventory
**e** - Equipment screen
**d** - Drop item
**w** - Wield weapon
**W** - Wear armor
**T** - Take off armor

### Using Items

**a** - Activate (use wands, staves, special items)
**q** - Quaff potion
**r** - Read scroll
**E** - Eat (herbs, food)

### Item Management

**I** - Inspect item (detailed information)
**{** - Inscribe item (add note)
**k** - Destroy item

## Abilities

**m** - View/use abilities
**A** - Auto-abilities toggle

Abilities cost turns and sometimes have additional costs or requirements.

## Magic Items

### Wands and Staves

**a** then select item - Activate wand or staff
- Wands fire at a target (must aim)
- Staves often affect area around you

### Combining Items

When you have two identical wands or staves:
**a** - Select one, then select the other to combine

Higher Lore skill = more charges recovered.

## Information Commands

**C** - Character screen (stats, skills)
**@** - Detailed character info
**%** - Knowledge (identified items)
**~** - Identified monster list
**M** - Full dungeon map
**L** - Look around (examine terrain/items)

### The Look Command

**L** - Enter look mode
- Move cursor with direction keys
- **Enter** - Get info about what's under cursor
- **Escape** - Exit look mode

## Display

### The Main Screen

```
+--------------------------------------------------+
|  Map Area                                        |
|                                                  |
|                @                                 |
|                                                  |
|                                                  |
+--------------------------------------------------+
| HP: 45/50  Voice: 3/5  Depth: 200'               |
| [Status Effects]                                 |
+--------------------------------------------------+
```

### Status Line

- **HP**: Current / Maximum health
- **Voice**: Current / Maximum (for Lore abilities)
- **Depth**: Current dungeon depth in feet

### Status Effects

Status effects appear as abbreviated tags:
- **Psn** - Poisoned
- **Blnd** - Blinded
- **Conf** - Confused
- **Fear** - Frightened
- **Slow** - Slowed
- **Haste** - Hasted

### The Sidebar

The sidebar shows:
- Nearby monsters and their status
- Equipment readout
- Other contextual information

### Messages

Recent game messages appear at the top of the screen. Press **Ctrl+P** to view message history.

## Options and Settings

**=** - Options menu
**?** - Help

### Useful Options

- **Auto-pickup** - Automatically pick up certain items
- **Run-cut-corners** - Running behavior at corners
- **Disturb options** - What interrupts resting/running

## Saving and Quitting

**Ctrl+S** - Save game
**Ctrl+Q** or **Q** - Save and quit
**Ctrl+X** - Quit without saving (suicide)

**Warning**: Quitting without saving destroys your character permanently. This is intentional—no save scumming.

## Quick Reference

| Key | Action |
|-----|--------|
| Direction | Move/Attack |
| 5 or . | Wait |
| < | Go up stairs |
| > | Go down stairs |
| f | Fire ranged |
| i | Inventory |
| e | Equipment |
| a | Activate item |
| q | Quaff potion |
| r | Read scroll |
| E | Eat |
| m | Abilities |
| C | Character |
| M | Map |
| L | Look |
| ? | Help |
| = | Options |

## Mouse Support

Some versions support mouse input:
- **Click** to move
- **Click enemy** to attack
- **Right-click** to examine
