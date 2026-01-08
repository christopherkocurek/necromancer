# UI Placement Options for Threat Indicator

## Option A: Bottom Status Bar (Near Depth)

**Position**: Between TERRAIN (col 61) and DEPTH (col 72)

```
+------------------------------------------------------------------+
|                         MAP AREA                                  |
+------------------------------------------------------------------+
| Hungry  Blind Confused  Stun    Afraid  Resting  Fast  Web  HIGH 500ft |
                                                           ^^^^
                                                        Threat here
```

**Pros**:
- Logical grouping with depth display
- Single line, non-intrusive

**Cons**:
- Very limited space (~6 chars)
- May overlap on narrow terminals
- Bottom bar already crowded

---

## Option B: Left Sidebar (Row 12)

**Position**: Row 12, Columns 0-12 (between SP and combat stats)

```
+------------+----------------------------------------+
| Name       |                                        |
| ------     |                                        |
| STR:  10   |              MAP AREA                  |
| DEX:  10   |                                        |
| CON:  10   |                                        |
| GRA:  10   |                                        |
| EXP: 1000  |                                        |
|            |                                        |
| HP: 50:50  |                                        |
| Spirit: 20 |                                        |
| Threat:LOW |  <-- NEW ROW 12                        |
| Mel: +5,2d4|                                        |
| Arc: +3,8  |                                        |
| Evn: [+2,3]|                                        |
+------------+----------------------------------------+
```

**Pros**:
- Dedicated space (12 chars)
- Doesn't affect bottom bar
- Logical position between stats and combat

**Cons**:
- May feel disconnected from depth display
- Uses empty row that could serve other purposes

---

## Option C: Color-Coded Map Border

**Position**: Single-character border around map area

```
+GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG+
G                                               G
G                 MAP AREA                      G
G               (danger: LOW)                   G
G                                               G
+GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG+
```

Border color changes: Green -> Yellow -> Orange -> Red -> Violet

**Pros**:
- Highly visible, ambient danger feeling
- No text clutter
- Immersive

**Cons**:
- Complex implementation
- May conflict with existing border drawing
- Reduces map space

---

## Recommendation: Option B (Left Sidebar Row 12)

**Rationale**:
1. Clear, dedicated space for threat indicator
2. 12 characters allows "Threat: HIGH" format
3. Positioned between resource stats (HP/SP) and combat stats
4. Does not affect the already-crowded bottom status bar
5. Simple implementation - just add a new prt_threat() function

**Final ASCII Mockup**:
```
+------------+
| Gondor Man |
|            |
| STR:   3   |
| DEX:   4   |
| CON:   3   |
| GRA:   2   |
|            |
| Exp: 500   |
|            |
| HP:  45:45 |
| Spirit:20:2|
| Threat:DOOM| <-- Color-coded (violet for DOOM)
| Mel:(+3,2d5|
| Arc:(+2, 6)|
| Evn:[+4,1-4|
```
