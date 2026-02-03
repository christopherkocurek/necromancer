# The Necromancer - Complete Sprite Master List

**Generated:** February 3, 2026
**Purpose:** Authoritative reference for all game tiles requiring sprites

---

## Summary

| Category | Count |
|----------|-------|
| Terrain Features | 88 |
| Monsters/Creatures | 73 |
| Objects/Items | 254 |
| **Total Unique Sprites** | **415** |

**Note:** The game uses a column-offset darkness system. Each terrain tile needs a DARK version placed one column to the right in the tileset.

---

## Critical: Darkness System

The hardfork renderer uses `*c += 1` to find dark versions of tiles. This means:
- Lit floor at column 1 → Dark floor expected at column 2
- Lit wall at column 3 → Dark wall expected at column 4

**Tileset must be organized as pairs: [LIT][DARK][LIT][DARK]...**

---

## Section 1: Terrain Features (88 entries)

### Floors
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 0 | Darkness/Void | No (is darkness) |
| 1 | Open Floor | YES |
| 9 | Fading Daylight | YES |
| 10 | Open Floor (rage) | YES |
| 31 | Bloodstain | YES |
| 84 | Poison Stream | YES |
| 86 | Vine Floor | YES |
| 87 | Forest Floor | YES |

### Walls
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 11 | Wall (rage) | YES |
| 51 | Quartz Vein | YES |
| 56 | Dark Stone Wall (basic) | YES |
| 57 | Dark Stone Wall (inner) | YES |
| 58 | Dark Stone Wall (outer) | YES |
| 59 | Dark Stone Wall (solid) | YES |
| 63 | Dark Stone Wall (permanent) | YES |
| 85 | Tangled Roots | YES |

### Doors
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 4 | Open Door | YES |
| 5 | Shattered Door | YES |
| 6 | Warded Door (power 1) | YES |
| 7 | Warded Door (power 2) | YES |
| 8 | Warded Door (power 3) | YES |
| 32 | Iron Door (closed) | YES |
| 33-39 | Locked Iron Door (powers 1-7) | YES (7 variants) |
| 40-47 | Jammed Door (powers 0-7) | YES (8 variants) |
| 48 | Hidden Passage | YES |

### Stairs
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 80 | Stairs Up | YES |
| 81 | Stairs Down | YES |
| 82 | Shaft Up | YES |
| 83 | Shaft Down | YES |

### Hazards & Special
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 2 | Bottomless Pit | YES |
| 3 | Protective Rune | YES |
| 12 | Dark Pool | YES |
| 13 | Morgul Runes | YES |
| 14 | Shadow Brazier | YES |
| 15 | Torture Rack | YES |
| 29 | Prison Bars | YES |
| 30 | Chains | YES |
| 49 | Fallen Masonry/Rubble | YES |

### Traps
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 16 | Weakened Floor | YES |
| 17 | Jagged Pit | YES |
| 18 | Poisoned Spike Pit | YES |
| 19 | Poison Needle Trap | YES |
| 20 | Noxious Fumes | YES |
| 21 | Mind Fog | YES |
| 22 | Orc Alarm | YES |
| 23 | Blinding Glyph | YES |
| 24 | Rusted Caltrops | YES |
| 25 | Bat Roost | YES |
| 26 | Thick Web | YES |
| 27 | Falling Stones | YES |
| 28 | Pool of Filth | YES |

### Forges (with usage states)
| ID | Name | Needs Dark Version |
|----|------|-------------------|
| 64-69 | Orc Forge (0-5 uses) | YES (6 variants) |
| 70-75 | Shadow Forge (0-5 uses) | YES (6 variants) |
| 76-79 | Forge Angdur (0-3 uses) | YES (4 variants) |

---

## Section 2: Monsters & Creatures (73 entries)

### Layer 1: Forest Breach (Depths 1-3)
| ID | Name | Type |
|----|------|------|
| 11 | Mirkwood Spider | Spider |
| 12 | Giant Rat | Rodent |
| 13 | Black Squirrel | Rodent |
| 14 | Crebain | Bird |
| 15 | Tanglethorn | Plant |
| 16 | Giant Bat | Bat |
| 17 | Web Spinner | Spider |
| 18 | Orc Scout | Humanoid |
| 19 | Swamp Adder | Serpent |
| 20 | Great Spider | Spider |
| 21 | Warg Pup | Beast |
| 22 | Broodmother | Spider (Boss) |

### Layer 2: Orc Warrens (Depths 3-6)
| ID | Name | Type |
|----|------|------|
| 31 | Orc Slave | Humanoid |
| 32 | Orc Soldier | Humanoid |
| 33 | Orc Crossbowman | Humanoid |
| 34 | Warg | Beast |
| 35 | Orc Thrallmaster | Humanoid |
| 36 | Orc Captain | Humanoid |
| 37 | Warg Rider | Humanoid |
| 38 | Hill Troll | Giant |
| 39 | Gashnak, Warg-lord | Unique |
| 40 | Orc Warchief | Unique |

### Layer 3: Torture Halls (Depths 6-9)
| ID | Name | Type |
|----|------|------|
| 51 | Dark Acolyte | Humanoid |
| 52 | Ghoul | Undead |
| 53 | Mirk-troll | Giant |
| 54 | Easterling Warrior | Humanoid |
| 55 | Dark Sorcerer | Humanoid |
| 56 | Tortured Wretch | Humanoid |
| 57 | Easterling Champion | Humanoid |
| 58 | Ghast | Undead |
| 59 | Karvag the Torturer | Unique |
| 60 | Master Sorcerer | Unique |

### Layer 4: Necropolis (Depths 9-12)
| ID | Name | Type |
|----|------|------|
| 71 | Skeleton | Undead |
| 72 | Skeleton Warrior | Undead |
| 73 | Zombie | Undead |
| 74 | Wight | Undead |
| 75 | Corpse-candle | Undead |
| 76 | Necromancer Adept | Humanoid |
| 77 | Barrow-wight | Undead |
| 78 | Bone Golem | Undead |
| 79 | Grishnákh, Crypt Lord | Unique |

### Layer 5: Wraith Domain (Depths 12-15)
| ID | Name | Type |
|----|------|------|
| 91 | Phantom | Undead |
| 92 | Shadow | Undead |
| 93 | Whispering Shade | Undead |
| 94 | Wraith | Undead |
| 95 | Fell Spirit | Undead |
| 96 | Spectre | Undead |
| 97 | Vampire Thrall | Undead |
| 98 | The Wailing Horror | Unique |
| 99 | Úvatha the Horseman | Unique |

### Layer 6: Inner Sanctum (Depths 15-18)
| ID | Name | Type |
|----|------|------|
| 111 | Black Númenórean | Humanoid |
| 112 | Olog-hai | Giant |
| 113 | Vampire | Undead |
| 114 | Greater Wraith | Undead |
| 115 | Vampire Lord | Undead |
| 116 | Shadow Lord | Undead |
| 117 | Maia Thrall | Supernatural |
| 118 | Khamûl, Shadow of the East | Unique |

### Layer 7: Pits of Despair (Depths 18-20)
| ID | Name | Type |
|----|------|------|
| 131 | Elite Olog-hai | Giant |
| 132 | Greater Shadow | Undead |
| 133 | Void Wraith | Undead |
| 134 | Thráin's Shade | Humanoid |
| 135 | Sauron, the Necromancer | FINAL BOSS |

### Special/Hallucinatory NPCs
| ID | Name | Type |
|----|------|------|
| 301 | Gandalf the Grey | Wizard |
| 302 | Thranduil, Elvenking | Elf |
| 303 | Galadriel, Lady of Light | Elf |
| 304 | Elrond Half-elven | Elf |
| 305 | Thorin Oakenshield | Dwarf |
| 306 | Beorn the Skinchanger | Humanoid |
| 307 | Radagast the Brown | Wizard |
| 308 | Eagle of the Misty Mountains | Bird |
| 309 | Great Elk of Mirkwood | Beast |
| 310 | Ent of Fangorn | Treant |

---

## Section 3: Objects/Items (254 entries)

### Light Sources
| ID | Name |
|----|------|
| 21 | Elven Light |
| 128 | Wooden Torch |
| 129 | Brass Lantern |
| 130 | Jewel-lamp |
| 131 | Star-glass |
| 411 | Mallorn Torch |

### Weapons - Blades
| ID | Name |
|----|------|
| 56 | Ranger's Knife |
| 57 | Orc-blade |
| 60 | Woodland Blade |
| 64 | Longsword |
| 67 | Rohirrim Blade |
| 68 | Númenórean Blade |
| 69 | Mithril Sword |
| 70 | Mithril Great-blade |

### Weapons - Polearms & Axes
| ID | Name |
|----|------|
| 71 | Hunting Spear |
| 72 | Tower Guard Spear |
| 74 | Morgul Glaive |
| 76 | Woodsman's Axe |
| 77 | Dwarven War-axe |
| 81 | Erebor Great-axe |

### Weapons - Blunt
| ID | Name |
|----|------|
| 86 | Oak Staff |
| 89 | Dwarven Hammer |

### Weapons - Ranged
| ID | Name |
|----|------|
| 110 | Silvan Bow |
| 111 | Longbow |
| 112 | Dragon-horn Bow |
| 116 | Arrow |

### Armor - Body
| ID | Name |
|----|------|
| 22 | Wanderer's Robe |
| 23 | Ranger Leathers |
| 26 | Scout's Armor |
| 27 | Shadow-steel Armor |
| 30 | Gondor Corslet |
| 31 | Dwarven Hauberk |
| 38 | Mithril Corslet |

### Armor - Shields
| ID | Name |
|----|------|
| 43 | Buckler |
| 44 | Tower Shield |
| 46 | Mithril Shield |

### Armor - Headgear
| ID | Name |
|----|------|
| 100 | Iron Helm |
| 101 | Tower Helm |
| 102 | Dwarf Mask |
| 103 | Mithril Helm |
| 104 | Crown |

### Armor - Cloaks
| ID | Name |
|----|------|
| 106 | Traveler's Cloak |
| 107 | Shadow Cloak |
| 108 | Wolf-Hame |
| 109 | Bat-Fell |

### Armor - Footwear
| ID | Name |
|----|------|
| 122 | Traveler's Boots |
| 123 | Iron Greaves |
| 124 | Mithril Greaves |

### Armor - Handgear
| ID | Name |
|----|------|
| 125 | Leather Gloves |
| 126 | Iron Gauntlets |
| 127 | Mithril Gauntlets |

### Jewelry - Rings
| ID | Name |
|----|------|
| 1 | Ring of Barahir |
| 2 | Ring of Melian |
| 7 | Ring of Mairon |
| 10 | Generic Ring |
| 150-171 | Special Property Rings (22 types) |

### Jewelry - Amulets
| ID | Name |
|----|------|
| 3 | Amulet of Tinfang |
| 4 | Nimphelos (Pearl) |
| 5 | Elessar (Jewel) |
| 6 | Necklace of the Dwarves |
| 11 | Generic Amulet |
| 132-139 | Special Property Amulets (8 types) |

### Staves (Magical)
| ID | Name |
|----|------|
| 191-211 | Various magical staves (21 types) |

### Wands
| ID | Name |
|----|------|
| 220-225 | Elemental wands (6 types) |

### Horns & Instruments
| ID | Name |
|----|------|
| 240-251 | Various horns and instruments (8 types) |

### Potions
| ID | Name |
|----|------|
| 313-350 | Various potions (38 types) |

### Containers
| ID | Name |
|----|------|
| 372 | Small Wooden Chest |
| 373 | Small Steel Chest |
| 374 | Small Jewelled Chest |
| 375 | Large Wooden Chest |
| 376 | Large Steel Chest |
| 377 | Large Jewelled Chest |
| 378 | Finely Wrapped Present |

### Herbs & Food
| ID | Name |
|----|------|
| 380-404 | Various herbs and food (25 types) |

### Tools
| ID | Name |
|----|------|
| 96 | Miner's Spade |
| 98 | Dwarf Mattock |

### Crafting Materials
| ID | Name |
|----|------|
| 410 | Piece of Mithril |
| 412-415 | Alchemical items (4 types) |
| 420-422 | Damaged items (3 types) |
| 491-495 | Broken enchanted items (5 types) |

### Discovery Items (Collectibles)
| ID | Name |
|----|------|
| 500-507 | Thráin's Memories (8 types) |
| 510-515 | Shadow Fragments (6 types) |
| 520-526 | Ancient Glyphs (7 types) |
| 530-533 | Palantír Shards (4 types) |
| 540-544 | Erebor Relics (5 types) |
| 550-557 | Dol Guldur Records (8 types) |

### Artifacts (Unique)
| ID | Name |
|----|------|
| 19 | Mighty Hammer 'Grond' |
| 20 | Iron Crown of Morgoth |

---

## Tileset Layout Requirements

The game expects this column arrangement for terrain:
```
Col 0: Darkness (F:0)
Col 1: Floor LIT (F:1)
Col 2: Floor DARK
Col 3: Wall LIT (F:56)
Col 4: Wall DARK
...etc
```

Each terrain feature needs its dark version immediately to the right.

---

## Files Reference

- **Terrain data:** `lib/edit/terrain.txt`
- **Monster data:** `lib/edit/monster.txt`
- **Object data:** `lib/edit/object.txt`
- **PRF mapping:** `lib/pref/graf-necromancer-corrected.prf`
- **Tileset:** `lib/xtra/graf/64x64_necromancer.png`

---

*This document is the authoritative reference for The Necromancer sprite requirements.*
