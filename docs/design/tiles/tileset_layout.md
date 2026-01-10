# The Necromancer - Tileset Sheet Layout

Version 1.0 | DESIGN-003

## Sheet Specifications

| Property | Value |
|----------|-------|
| Tile Size | 32x32 pixels |
| Columns | 32 |
| Rows | 16 |
| Total Tiles | 512 |
| Image Width | 1024 pixels |
| Image Height | 512 pixels |
| Format | PNG with alpha |
| File | lib/tiles/necromancer/32x32.png |

---

## Row Assignments

| Row | Index Range | Category | Contents |
|-----|-------------|----------|----------|
| 0 | 0x80/0x80-0x9F | Terrain | Floors, darkness |
| 1 | 0x81/0x80-0x9F | Terrain | Walls, doors |
| 2 | 0x82/0x80-0x9F | Terrain | Stairs, traps, features |
| 3 | 0x83/0x80-0x9F | Items | Potions (29 colors) |
| 4 | 0x84/0x80-0x9F | Items | Amulets, staves |
| 5 | 0x85/0x80-0x9F | Items | Armor, boots, gloves |
| 6 | 0x86/0x80-0x9F | Items | Weapons |
| 7 | 0x87/0x80-0x9F | Monsters | Spiders, undead low |
| 8 | 0x88/0x80-0x9F | Monsters | Orcs, humanoids |
| 9 | 0x89/0x80-0x9F | Monsters | Trolls, beasts |
| 10 | 0x8A/0x80-0x9F | Monsters | Wraiths, vampires, bosses |
| 11 | 0x8B/0x80-0x9F | Effects | Projectiles, UI, special |
| 12 | 0x8C/0x80-0x9F | UI | Numbers, icons |
| 13 | 0x8D/0x80-0x9F | Players | Elf race variants |
| 14 | 0x8E/0x80-0x9F | Players | Man race variants |
| 15 | 0x8F/0x80-0x9F | Players | Dwarf race, forges |

---

## Detailed Tile Mapping

### Row 0 (0x80): Floors & Basic Terrain

| Col | Index | ID | Name |
|-----|-------|-----|------|
| 0 | 0x80/0x80 | F:0 | Darkness (void) |
| 1 | 0x80/0x81 | F:1 | Stone floor |
| 2 | 0x80/0x82 | F:9 | Fading daylight |
| 3 | 0x80/0x83 | F:86 | Vine floor |
| 4 | 0x80/0x84 | F:87 | Forest floor |
| 5 | 0x80/0x85 | F:31 | Bloodstain |
| 6 | 0x80/0x86 | F:12 | Dark pool |
| 7 | 0x80/0x87 | F:49 | Rubble/masonry |
| 8-31 | 0x80/0x88-9F | - | Reserved |

### Row 1 (0x81): Walls & Doors

| Col | Index | ID | Name |
|-----|-------|-----|------|
| 0 | 0x81/0x80 | F:56 | Dark stone wall |
| 1 | 0x81/0x81 | F:48 | Hidden passage |
| 2 | 0x81/0x82 | F:85 | Tangled roots |
| 3 | 0x81/0x83 | F:29 | Prison bars |
| 4 | 0x81/0x84 | F:51 | Quartz vein |
| 5 | 0x81/0x85 | F:32 | Iron door (closed) |
| 6 | 0x81/0x86 | F:4 | Open door |
| 7 | 0x81/0x87 | F:5 | Shattered door |
| 8 | 0x81/0x88 | F:6 | Warded door (green) |
| 9 | 0x81/0x89 | F:7 | Warded door (blue) |
| 10 | 0x81/0x8A | F:8 | Warded door (violet) |
| 11-31 | 0x81/0x8B-9F | - | Reserved |

### Row 2 (0x82): Stairs, Traps, Features

| Col | Index | ID | Name |
|-----|-------|-----|------|
| 0 | 0x82/0x80 | F:80 | Stairs up |
| 1 | 0x82/0x81 | F:81 | Stairs down |
| 2 | 0x82/0x82 | F:82 | Shaft up |
| 3 | 0x82/0x83 | F:83 | Shaft down |
| 4 | 0x82/0x84 | F:16 | Trap: weakened floor |
| 5 | 0x82/0x85 | F:17 | Trap: jagged pit |
| 6 | 0x82/0x86 | F:20 | Trap: noxious fumes |
| 7 | 0x82/0x87 | F:22 | Trap: orc alarm |
| 8 | 0x82/0x88 | F:26 | Trap: thick web |
| 9 | 0x82/0x89 | F:27 | Trap: falling stones |
| 10 | 0x82/0x8A | F:3 | Protective rune |
| 11 | 0x82/0x8B | F:13 | Morgul runes |
| 12 | 0x82/0x8C | F:14 | Shadow brazier |
| 13 | 0x82/0x8D | F:15 | Torture rack |
| 14 | 0x82/0x8E | F:30 | Chains |
| 15-31 | 0x82/0x8F-9F | - | Reserved |

### Row 3 (0x83): Potions

| Col | Index | Flavor ID | Color |
|-----|-------|-----------|-------|
| 0 | 0x83/0x80 | L:193 | Clear |
| 1 | 0x83/0x81 | L:195 | Murky Brown |
| 2 | 0x83/0x82 | L:196 | Limpid |
| 3 | 0x83/0x83 | L:197 | Dark Blue |
| 4 | 0x83/0x84 | L:198 | Brilliant Blue |
| 5 | 0x83/0x85 | L:199 | Black |
| 6 | 0x83/0x86 | L:200 | Brown |
| 7 | 0x83/0x87 | L:201 | Sparkling |
| 8 | 0x83/0x88 | L:202 | Milky White |
| 9 | 0x83/0x89 | L:203 | Copper Speckled |
| 10 | 0x83/0x8A | L:204 | Crimson |
| 11 | 0x83/0x8B | L:205 | Green |
| 12 | 0x83/0x8C | L:206 | Dark Green |
| 13 | 0x83/0x8D | L:207 | Grey |
| 14 | 0x83/0x8E | L:208 | Emerald |
| 15 | 0x83/0x8F | L:209 | Bright Orange |
| 16-31 | 0x83/0x90-9F | - | More potions/reserved |

### Row 7 (0x87): Spiders & Low Undead

| Col | Index | Monster ID | Name |
|-----|-------|------------|------|
| 0 | 0x87/0x80 | R:11 | Mirkwood Spider |
| 1 | 0x87/0x81 | R:17 | Web Spinner |
| 2 | 0x87/0x82 | R:20 | Great Spider |
| 3 | 0x87/0x83 | R:22 | Broodmother |
| 4 | 0x87/0x84 | R:52 | Ghoul |
| 5 | 0x87/0x85 | R:58 | Ghast |
| 6 | 0x87/0x86 | R:71 | Skeleton |
| 7 | 0x87/0x87 | R:72 | Skeleton Warrior |
| 8 | 0x87/0x88 | R:73 | Zombie |
| 9 | 0x87/0x89 | R:75 | Corpse-candle |
| 10-31 | 0x87/0x8A-9F | - | Reserved |

### Row 8 (0x88): Orcs & Humanoids

| Col | Index | Monster ID | Name |
|-----|-------|------------|------|
| 0 | 0x88/0x80 | R:18 | Orc Scout |
| 1 | 0x88/0x81 | R:31 | Orc Slave |
| 2 | 0x88/0x82 | R:32 | Orc Soldier |
| 3 | 0x88/0x83 | R:33 | Orc Crossbowman |
| 4 | 0x88/0x84 | R:35 | Orc Thrallmaster |
| 5 | 0x88/0x85 | R:36 | Orc Captain |
| 6 | 0x88/0x86 | R:37 | Warg Rider |
| 7 | 0x88/0x87 | R:40 | Orc Warchief |
| 8 | 0x88/0x88 | R:51 | Dark Acolyte |
| 9 | 0x88/0x89 | R:54 | Easterling Warrior |
| 10 | 0x88/0x8A | R:55 | Dark Sorcerer |
| 11 | 0x88/0x8B | R:56 | Tortured Wretch |
| 12 | 0x88/0x8C | R:57 | Easterling Champion |
| 13 | 0x88/0x8D | R:76 | Necromancer Adept |
| 14 | 0x88/0x8E | R:111 | Black Númenórean |
| 15-31 | 0x88/0x8F-9F | - | Reserved |

### Row 9 (0x89): Trolls, Beasts & More

| Col | Index | Monster ID | Name |
|-----|-------|------------|------|
| 0 | 0x89/0x80 | R:12 | Giant Rat |
| 1 | 0x89/0x81 | R:13 | Black Squirrel |
| 2 | 0x89/0x82 | R:14 | Crebain |
| 3 | 0x89/0x83 | R:16 | Giant Bat |
| 4 | 0x89/0x84 | R:19 | Swamp Adder |
| 5 | 0x89/0x85 | R:21 | Warg Pup |
| 6 | 0x89/0x86 | R:34 | Warg |
| 7 | 0x89/0x87 | R:39 | Gashnak |
| 8 | 0x89/0x88 | R:38 | Hill Troll |
| 9 | 0x89/0x89 | R:53 | Mirk-troll |
| 10 | 0x89/0x8A | R:59 | Karvag |
| 11 | 0x89/0x8B | R:112 | Olog-hai |
| 12 | 0x89/0x8C | R:131 | Elite Olog-hai |
| 13 | 0x89/0x8D | R:15 | Tanglethorn |
| 14-31 | 0x89/0x8E-9F | - | Reserved |

### Row 10 (0x8A): Wraiths, Vampires, Bosses

| Col | Index | Monster ID | Name |
|-----|-------|------------|------|
| 0 | 0x8A/0x80 | R:74 | Wight |
| 1 | 0x8A/0x81 | R:77 | Barrow-wight |
| 2 | 0x8A/0x82 | R:78 | Bone Golem |
| 3 | 0x8A/0x83 | R:79 | Grishnákh |
| 4 | 0x8A/0x84 | R:91 | Phantom |
| 5 | 0x8A/0x85 | R:92 | Shadow |
| 6 | 0x8A/0x86 | R:93 | Whispering Shade |
| 7 | 0x8A/0x87 | R:94 | Wraith |
| 8 | 0x8A/0x88 | R:96 | Spectre |
| 9 | 0x8A/0x89 | R:97 | Vampire Thrall |
| 10 | 0x8A/0x8A | R:98 | Wailing Horror |
| 11 | 0x8A/0x8B | R:99 | Úvatha (Nazgûl) |
| 12 | 0x8A/0x8C | R:113 | Vampire |
| 13 | 0x8A/0x8D | R:115 | Vampire Lord |
| 14 | 0x8A/0x8E | R:118 | Khamûl (Nazgûl) |
| 15 | 0x8A/0x8F | R:60 | Master Sorcerer |
| 16 | 0x8A/0x90 | R:114 | Greater Wraith |
| 17 | 0x8A/0x91 | R:134 | Thráin's Shade |
| 18 | 0x8A/0x92 | R:135 | **Sauron** |
| 19-31 | 0x8A/0x93-9F | - | Reserved |

### Row 13-15: Player Characters

| Row | Index | Race | Notes |
|-----|-------|------|-------|
| 13 (0x8D) | 0x8D/0x80 | R:0 Elf | Primary sprite |
| 14 (0x8E) | 0x8E/0x80 | R:1 Man | Primary sprite |
| 15 (0x8F) | 0x8F/0x80 | R:2 Dwarf | Primary sprite |

### Row 15 (0x8F) Also: Forges

| Col | Index | Feature ID | Name |
|-----|-------|------------|------|
| 0-15 | 0x8F/0x80-8F | F:64-79 | Forge variants |

---

## PRF File Coordinate Format

Coordinates use hexadecimal: `0xRR/0xCC`
- RR = Row (0x80 = row 0, 0x8F = row 15)
- CC = Column (0x80 = col 0, 0x9F = col 31)

Example mappings:
```
# Sauron at row 10, col 18
R:135:0x8A/0x92

# Stone floor at row 0, col 1
F:1:0x80/0x81

# Orc soldier at row 8, col 2
R:32:0x88/0x82
```

---

## Empty Template

Create a 1024x512 transparent PNG as the base template.
Fill with magenta (#FF00FF) error color initially.
Replace each tile as sprites are generated.

---

## Validation Checklist

- [ ] All 82 required sprites have assigned coordinates
- [ ] No coordinate conflicts (same tile used twice)
- [ ] Monster IDs match monster.txt
- [ ] Feature IDs match terrain.txt
- [ ] Object IDs match object.txt
- [ ] Reserved space for future expansion
