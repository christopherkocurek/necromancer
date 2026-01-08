# Layer 1 Vault Requirements

## Vault Symbol Extensions

### New Vault Symbols for Forest Terrain

Add to init1.c vault parsing:

| Symbol | Terrain | Notes |
|--------|---------|-------|
| p | FEAT_POISON_STREAM | Poison stream |
| v | FEAT_VINE_FLOOR | Vine floor |
| r | FEAT_TANGLED_ROOTS | Tangled roots |
| s | FEAT_SUNLIGHT | Sunlight patch |
| f | FEAT_FOREST_FLOOR | Forest floor (decorative) |

### Parsing Addition (init1.c)

In vault symbol parsing section:
```c
case 'p': feat = FEAT_POISON_STREAM; break;
case 'v': feat = FEAT_VINE_FLOOR; break;
case 'r': feat = FEAT_TANGLED_ROOTS; break;
case 's': feat = FEAT_SUNLIGHT; break;
case 'f': feat = FEAT_FOREST_FLOOR; break;
```

---

## Existing Vaults for Layer 1

### Suitable Existing Vaults (depth <= 3)

| N: | Name | Current Depth | Notes |
|----|------|---------------|-------|
| N:11 | Web Choke | 8 | Lower to 2, add vines |
| N:12 | Corrupted Grove | 6 | Lower to 1, already forest-themed |
| N:17 | Scout Camp | 4 | Lower to 2, add forest elements |
| N:23 | Warg Den | 4 | Lower to 1, forest predators |

### Vaults to Modify

These vaults should be updated to include Layer 1 terrain when spawning on depths 1-3.

---

## New Forest Vaults

### Vault 1: Overgrown Ruins

**Purpose**: Entry-level vault, introduces vine terrain
**Size**: 15x11
**Depth**: 1
**Rarity**: 2 (common)

```
N:90:Overgrown Ruins
X:7:1:2
D:###############
D:#vvvvvvvvvvvvv#
D:#v...........v#
D:#v.rrr...rrr.v#
D:#v.r.......r.v#
D:#v.....<....v#
D:#v.r.......r.v#
D:#v.rrr...rrr.v#
D:#v...........v#
D:#vvvvvvvvvvvvv#
D:###############
```

### Vault 2: Poison Pool Grove

**Purpose**: Introduces poison stream hazard
**Size**: 17x13
**Depth**: 2
**Rarity**: 3

```
N:91:Poison Pool Grove
X:7:2:3
D:#################
D:#vvvvvvvvvvvvvvv#
D:#v.............v#
D:#v..rrr~~~rrr..v#
D:#v..r..~~~..r..v#
D:#v.....~~~.....v#
D:#v..r..~~~..r..v#
D:#v..rrr~~~rrr..v#
D:#v.............v#
D:#vvvvvvvvvvvvvvv#
D:#################
```

### Vault 3: Sunlit Clearing

**Purpose**: Safe haven vault with sunlight
**Size**: 13x13
**Depth**: 1
**Rarity**: 4

```
N:92:Sunlit Clearing
X:7:1:4
D:#############
D:#vvvvvvvvvvv#
D:#v.........v#
D:#v..rrrrr..v#
D:#v..r...r..v#
D:#v..r.s.r..v#
D:#v..r...r..v#
D:#v..rrrrr..v#
D:#v.........v#
D:#vvvvvvvvvvv#
D:#############
```

### Vault 4: Spider's Forest Lair

**Purpose**: Combat vault with mixed terrain
**Size**: 19x15
**Depth**: 3
**Rarity**: 3

```
N:93:Spider's Forest Lair
X:7:3:3
D:###################
D:#vvvvvvvvvvvvvvvvv#
D:#v...............v#
D:#v.rrrr.....rrrr.v#
D:#v.r..........r..v#
D:#v.r..vvvvv...r.v#
D:#v....v...v.....v#
D:#v....v.S.v.....v#
D:#v....v...v.....v#
D:#v.r..vvvvv...r.v#
D:#v.r..........r..v#
D:#v.rrrr.....rrrr.v#
D:#v...............v#
D:#vvvvvvvvvvvvvvvvv#
D:###################
```

### Vault 5: Forest Stream Crossing

**Purpose**: Tactical vault with poison stream obstacle
**Size**: 21x11
**Depth**: 2
**Rarity**: 3

```
N:94:Forest Stream Crossing
X:7:2:3
D:#####################
D:#vvvvv~~~~~vvvvvvvvv#
D:#v....~~~~~........v#
D:#v.rr.~~~~~.....rr.v#
D:#v.r..~~~~~......r.v#
D:#v....~~~~~........v#
D:#v.r..~~~~~......r.v#
D:#v.rr.~~~~~.....rr.v#
D:#v....~~~~~........v#
D:#vvvvv~~~~~vvvvvvvvv#
D:#####################
```

---

## Vault Type Assignments

| Type | Purpose |
|------|---------|
| 7 | Lesser vault (small, common) |
| 8 | Greater vault (large, rare) |

All Layer 1 vaults should be type 7 (lesser).

---

## Monster Placement in Vaults

Layer 1 vaults should use these symbols for thematic monsters:

| Symbol | Monster Type | Examples |
|--------|--------------|----------|
| S | Spider (unique) | Ungoliant's spawn |
| s | spider (common) | Mirkwood spider |
| W | Wolf/Warg | Forest predators |
| O | Orc (patrol) | Scout orcs |
| T | Troll | Forest troll |

---

## vault.txt Format Reference

```
# N: vault number : vault name
# X: vault type (7=lesser, 8=greater) : min depth : rarity
# D: vault layout lines
```

Example:
```
N:90:Overgrown Ruins
X:7:1:2
D:#####
D:#...#
D:#####
```

---

## Implementation Checklist

1. [ ] Add vault symbol parsing in init1.c
2. [ ] Add 5 new vault entries to vault.txt
3. [ ] Update existing forest-appropriate vaults
4. [ ] Test vault generation at depths 1-3
5. [ ] Verify terrain effects work in vaults
