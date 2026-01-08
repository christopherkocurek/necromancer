# Threat Level System Design

## 7 Threat Levels Mapped to Dungeon Layers

| Level | Layer | Depth Range | Name | Color Constant | Short Label | ASCII |
|-------|-------|-------------|------|----------------|-------------|-------|
| 1 | Forest Breach | 50-150ft | LOW | TERM_GREEN | "Low" | [!] |
| 2 | Orc Warrens | 150-300ft | GUARDED | TERM_YELLOW | "Guarded" | [!!] |
| 3 | Torture Halls | 300-450ft | ELEVATED | TERM_ORANGE | "Elevated" | [!!!] |
| 4 | Necropolis | 450-600ft | HIGH | TERM_L_RED | "High" | [!!!!] |
| 5 | Wraith Domain | 600-750ft | SEVERE | TERM_RED | "Severe" | [!!!!!] |
| 6 | Inner Sanctum | 750-900ft | CRITICAL | TERM_UMBER | "Critical" | [!!!!!!] |
| 7 | Pits of Despair | 900-1000ft | DOOM | TERM_VIOLET | "Doom" | [!!!!!!!] |
| 8 | Pursuit Mode | Any | HUNTED | TERM_L_RED (flash) | "HUNTED!" | [X!X] |

## Depth-to-Threat Mapping Function

```c
int get_threat_level(int depth)
{
    if (p_ptr->on_the_run) return THREAT_HUNTED;  /* Pursuit mode override */

    if (depth <= 3)  return THREAT_LOW;       /* 50-150ft */
    if (depth <= 6)  return THREAT_GUARDED;   /* 150-300ft */
    if (depth <= 9)  return THREAT_ELEVATED;  /* 300-450ft */
    if (depth <= 12) return THREAT_HIGH;      /* 450-600ft */
    if (depth <= 15) return THREAT_SEVERE;    /* 600-750ft */
    if (depth <= 18) return THREAT_CRITICAL;  /* 750-900ft */
    return THREAT_DOOM;                        /* 900-1000ft */
}
```

## Color Rationale

- **GREEN (5)**: Safe, nature, early game
- **YELLOW (11)**: Caution, alertness
- **ORANGE (3)**: Warning, increasing danger
- **LIGHT RED (12)**: Danger, approaching critical
- **RED (4)**: Severe danger, high mortality
- **UMBER (7)**: Dark brown - grim, despair
- **VIOLET (10)**: Otherworldly, ultimate doom, Sauron's domain

## Display Format Options

### Option 1: Full Label
```
Threat: Low
Threat: Guarded
Threat: HUNTED!
```

### Option 2: Abbreviated
```
[!] Low
[!!!] Elevated
[X!X] HUNTED!
```

### Option 3: Bar Style
```
Threat [====------]
Threat [========--]
Threat [==========] DOOM
```

**Recommendation**: Option 1 (Full Label) - clearest, fits 12-char sidebar
