# Tower Objects Design - The Necromancer
## XP-003: Collectible Lore Items for Discovery XP

---

## Concept Overview

**Tower Objects** are collectible lore items scattered throughout Dol Guldur that grant XP when discovered. They tell the story of the fortress's dark history while providing a combat-independent progression path.

### Design Goals
1. Reward exploration over combat grinding
2. Provide thematic storytelling through gameplay
3. Create meaningful choices (search for objects vs speed-run)
4. Support stealth builds with alternative XP source
5. One-time per playthrough (no farming)

---

## OBJECT CATEGORIES

### 1. Thráin's Memories (Primary Collection)

**Concept:** Ghostly manifestations of Thráin II's fragmentary memories, left behind during his long imprisonment.

**Visual:** Pale blue wisps (`*:B`)

**XP Value:** 150 each

**Spawn Rules:**
- 1-2 per level in layers 3-7
- Always spawn in corners, alcoves, or hidden rooms
- Never spawn in direct line-of-sight from stairs

**Collection:**
| ID | Name | Layer | Flavor Text |
|----|------|-------|-------------|
| TM01 | Memory of Erebor | 3-4 | "Halls of stone... my father's throne... gone..." |
| TM02 | Memory of the Key | 3-4 | "The key... I hid the key... where did I hide it?" |
| TM03 | Memory of Capture | 4-5 | "Ambushed... Azanulbizar survivors... so few of us left..." |
| TM04 | Memory of the Ring | 5-6 | "The Ring! He took my Ring! Durin's heirloom!" |
| TM05 | Memory of Torment | 5-6 | "Questions... always questions... I told him nothing!" |
| TM06 | Memory of Defiance | 6-7 | "My name is Thráin! Son of Thrór! I am NOT broken!" |
| TM07 | Memory of Thorin | 6-7 | "My son... does Thorin still live? The line continues?" |
| TM08 | Memory of Hope | 7 | "Someone comes... I sense it... dwarf-friend... rescue?" |

**Narrative Integration:** Collecting all 8 memories grants a special bonus when meeting Thráin's Shade.

---

### 2. Shadow Fragments (Combat-Proximate)

**Concept:** Crystallized shadow-matter that forms where Sauron's power is concentrated. More dangerous to acquire, higher reward.

**Visual:** Dark crystals (`*:D`)

**XP Value:** 200 each

**Spawn Rules:**
- 0-1 per level
- Always spawn near (within 5 tiles of) a dangerous monster
- Require approaching combat to retrieve
- Cannot spawn if level has no monsters

**Collection:**
| ID | Name | Layer | Location Type |
|----|------|-------|---------------|
| SF01 | Umbral Shard | 2-3 | Near orc captain |
| SF02 | Void Sliver | 3-4 | Near dark sorcerer |
| SF03 | Night Crystal | 4-5 | Near necromancer |
| SF04 | Shadow Heart | 5-6 | Near wraith |
| SF05 | Darkness Made Solid | 6-7 | Near Khamûl or boss |
| SF06 | Sauron's Tear | 7 | Near Sauron's throne |

**Gameplay Note:** These reward calculated risk. A stealth player must carefully extract them without triggering combat.

---

### 3. Ancient Glyphs (Wall Markings)

**Concept:** Elvish warning glyphs carved into the walls by captives, or Black Speech inscriptions of power.

**Visual:** Wall feature (`;:y`)

**XP Value:** 75 each

**Spawn Rules:**
- 1-3 per level, all layers
- Always spawn on walls (not floor)
- Require adjacent position to read
- Can be searched for with successful Perception check

**Collection:**
| ID | Name | Layer | Content |
|----|------|-------|---------|
| AG01 | Captive's Warning | 1-2 | "Beware the watchers - they see in darkness" |
| AG02 | Elvish Lament | 2-3 | Tengwar script: "We are forgotten" |
| AG03 | Count of Days | 3-4 | Tally marks scratched deep - hundreds |
| AG04 | Map Fragment | 4-5 | Rough map showing escape route (flavor only) |
| AG05 | Black Speech Curse | 5-6 | Hurts to read - grants dark knowledge |
| AG06 | Name of Power | 6-7 | "Sauron" in Black Speech - chilling |
| AG07 | Final Message | 7 | "Tell my family I died fighting" |

**Gameplay Note:** Low XP but common. Rewards thorough exploration of every wall.

---

### 4. Palantír Shards (Rare Treasures)

**Concept:** Fragments of the palantír of Amon Sûl, shattered when Arvedui drowned. Some pieces drifted to dark places.

**Visual:** Gleaming crystal (`*:v`)

**XP Value:** 500 each

**Spawn Rules:**
- 0-1 per layer (not per level)
- Only spawn in vaults or special rooms
- Rarity: 20% chance when vault generates
- Maximum 3 per playthrough

**Collection:**
| ID | Name | Layer | Vision Granted |
|----|------|-------|----------------|
| PS01 | Northern Shard | 1-2 | Glimpse of Forochel's ice |
| PS02 | Eastern Shard | 3-4 | Glimpse of Rhûn's plains |
| PS03 | Southern Shard | 5-6 | Glimpse of Mordor's fires |
| PS04 | Western Shard | 7 | Glimpse of Valinor's light |

**Special Effect:** Each shard also grants temporary See Invisible (100 turns) when picked up.

---

### 5. Erebor Relics (Dwarf Heritage)

**Concept:** Items stolen from Erebor when Sauron's forces gathered tribute from the dragon's hoard.

**Visual:** Treasure object (`$:u`)

**XP Value:** 100 each

**Spawn Rules:**
- 0-2 per level in layers 2-6
- Only spawn in treasure rooms or on bodies of powerful enemies
- Dwarf characters get +50% XP from these

**Collection:**
| ID | Name | Layer | Description |
|----|------|-------|-------------|
| ER01 | Mithril Brooch | 2-3 | Bearing the Erebor sigil |
| ER02 | Thrór's Coin | 3-4 | Gold coin with dwarf-king's face |
| ER03 | Dragon-Touched Gem | 4-5 | Heat still radiates from it |
| ER04 | Dwarven Chronicle Page | 5-6 | Record of the fall |
| ER05 | Durin's Day Fragment | 6 | Piece of the throne-room calendar |

---

## IMPLEMENTATION DETAILS

### Object.txt Format

```
##### Tower Objects: Thráin's Memories #####

N:600:Thráin's Memory
G:*:B
I:TV_TOWER_OBJECT:1:0
W:6:100:1:0
F:INSTA_ART
D:A wisp of pale blue light, holding a fragment of a dwarf's tortured memories.

N:601:Shadow Fragment
G:*:D
I:TV_TOWER_OBJECT:2:0
W:6:100:1:0
F:INSTA_ART
D:Crystallized darkness, cold to the touch. Sauron's power made manifest.

N:602:Ancient Glyph
G:;:y
I:TV_TOWER_OBJECT:3:0
W:2:100:0:0
F:INSTA_ART
D:Scratched into the stone - a message from the past.

N:603:Palantír Shard
G:*:v
I:TV_TOWER_OBJECT:4:0
W:10:100:1:0
F:INSTA_ART
D:A fragment of the great seeing-stone, still holding visions within.

N:604:Erebor Relic
G:$:u
I:TV_TOWER_OBJECT:5:0
W:4:100:2:0
F:INSTA_ART
D:A piece of the dragon's hoard, stolen from the Lonely Mountain.
```

### TV_TOWER_OBJECT Tval

New tval constant needed:
```c
#define TV_TOWER_OBJECT  100  /* Tower Objects for discovery XP */
```

### Pickup Handler

In `cmd3.c` or appropriate location:
```c
// When picking up a Tower Object
if (o_ptr->tval == TV_TOWER_OBJECT) {
    int xp_value;

    switch (o_ptr->sval) {
        case 1: xp_value = 150; break;  // Memory
        case 2: xp_value = 200; break;  // Shadow Fragment
        case 3: xp_value = 75; break;   // Glyph
        case 4: xp_value = 500; break;  // Palantír Shard
        case 5: xp_value = 100; break;  // Erebor Relic
        default: xp_value = 50;
    }

    gain_exp(xp_value);
    p_ptr->discovery_exp += xp_value;

    // Display flavor text
    msg_format("You discover %s!", o_name);
    // Display description
    msg_print(k_text + k_ptr->text);

    // Delete the object (one-time discovery)
    delete_object_idx(item);
}
```

### Spawn Logic

In `dungeon.c` level generation:
```c
// After vault placement, scatter Tower Objects
void place_tower_objects(void) {
    int num_memories = (p_ptr->depth >= 6) ? rand_range(1, 2) : 0;
    int num_fragments = one_in_(3) ? 1 : 0;
    int num_glyphs = rand_range(1, 3);
    int num_relics = (p_ptr->depth >= 4 && p_ptr->depth <= 12) ? rand_range(0, 2) : 0;

    // Place each type according to rules
    place_tower_objects_type(TV_TOWER_OBJECT, 1, num_memories, PLACE_HIDDEN);
    place_tower_objects_type(TV_TOWER_OBJECT, 2, num_fragments, PLACE_NEAR_MONSTER);
    place_tower_objects_type(TV_TOWER_OBJECT, 3, num_glyphs, PLACE_ON_WALL);
    place_tower_objects_type(TV_TOWER_OBJECT, 5, num_relics, PLACE_IN_TREASURE);

    // Palantír shards handled separately at vault generation
}
```

---

## XP BALANCE

### Expected Discovery XP Per Playthrough

| Layer | Memories | Fragments | Glyphs | Relics | Palantír | Total |
|-------|----------|-----------|--------|--------|----------|-------|
| 1 | 0 | 0 | 150 | 0 | 100 | 250 |
| 2 | 0 | 100 | 150 | 100 | 0 | 350 |
| 3 | 150 | 100 | 150 | 100 | 0 | 500 |
| 4 | 150 | 100 | 150 | 100 | 100 | 600 |
| 5 | 300 | 200 | 150 | 100 | 0 | 750 |
| 6 | 300 | 200 | 150 | 100 | 100 | 850 |
| 7 | 300 | 200 | 150 | 0 | 100 | 750 |
| **Total** | **1200** | **900** | **1050** | **500** | **400** | **4050** |

### Comparison to Current XP Sources

Based on a typical playthrough to depth 20:
- **Descent XP:** ~10,500 (depth × 50 cumulative)
- **Encounter XP:** ~3,000-5,000 (varies by play)
- **Kill XP:** ~5,000-15,000 (combat-heavy vs stealth)
- **Ident XP:** ~2,000-3,000 (20-30 items)
- **Discovery XP (new):** ~4,000

Tower Objects add roughly **20-30% more XP** for thorough explorers, making stealth builds more competitive with combat builds.

---

## NARRATIVE INTEGRATION

### Thráin's Memory Completion Bonus

If player collects all 8 memories before meeting Thráin's Shade:
- Thráin recognizes the player as having "walked his path"
- Dialogue changes to acknowledge shared experience
- Bonus: +500 XP "Understanding Thráin's Suffering"
- Thráin more willingly gives the key

### Palantír Shard Collection

If player collects 3+ shards:
- Final boss fight includes brief vision of Gandalf's approach
- Gives hope to the player ("Help is coming")
- Purely narrative, no mechanical benefit

### Erebor Relic Collection (Dwarf Characters)

If dwarf character collects 4+ relics:
- Flavor text: "You feel the weight of your people's loss"
- +10% to all discovery XP for remainder of game
- Satisfies "reclaim heritage" fantasy

---

## ANTI-FARMING MEASURES

1. **One-time objects:** Each specific object ID only generates once per game
2. **No regeneration:** Objects don't respawn on level regeneration
3. **Flagged on pickup:** Object IDs tracked in save file
4. **No selling:** Tower Objects have 0 value, can't be sold
5. **Immediate XP:** XP granted on pickup, object destroyed

---

## SEARCH MECHANICS

### Passive Discovery
- Tower Objects visible to all characters within line-of-sight
- Glyphs require being adjacent (1 tile away)

### Active Search
- Search command reveals hidden objects within perception range
- Higher Perception = wider search radius
- Glyphs benefit most from active search

### Stealth Synergy
- High-Stealth characters often have high Perception
- Slow, careful exploration = more discoveries
- Speed-running = fewer discoveries

---

## IMPLEMENTATION PRIORITY

### Phase 1: Basic System
1. Add TV_TOWER_OBJECT tval
2. Add 5 base object types to object.txt
3. Implement pickup handler with XP grant
4. Add discovery_exp tracking to player struct

### Phase 2: Spawn Logic
1. Implement scatter function for level generation
2. Add placement rules (hidden, near monster, on wall, etc.)
3. Add palantír special handling in vault generation

### Phase 3: Flavor Text
1. Add full flavor text for each object instance
2. Implement memory sequence tracking
3. Add completion bonuses

### Phase 4: Polish
1. Add notes system integration
2. Add character dump section for discoveries
3. Balance XP values based on testing

---

## SUMMARY

Tower Objects provide:
- **4,000+ additional XP** for thorough exploration
- **5 thematic categories** tied to Dol Guldur's story
- **Combat-independent progression** supporting stealth builds
- **Narrative depth** through collectible lore
- **Risk/reward choices** (Shadow Fragments near dangerous enemies)
- **One-time discoveries** preventing farming
