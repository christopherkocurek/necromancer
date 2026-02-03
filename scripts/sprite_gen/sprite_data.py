"""
Complete sprite data for The Necromancer - 82 sprites at 64x64
"""

# Base prompt template for character/item sprites (with magenta background)
BASE_TEMPLATE = """{description}

CRITICAL REQUIREMENTS:
- Single sprite only, perfectly centered in frame
- Solid magenta background (#FF00FF) for easy removal
- NO color palette swatches or UI elements
- NO text, labels, watermarks, or borders
- Character/object fills 80% of the frame
- Clear silhouette readable at small size
- Dark fantasy pixel art style
- Top-left lighting, consistent shadows
- 64x64 pixel game sprite aesthetic"""

# =============================================================================
# ENVIRONMENT TILE TEMPLATES (for floors, walls, doors - NO magenta, 100% fill)
# =============================================================================
ENVIRONMENT_FLOOR_TEMPLATE = """A seamless tileable dungeon floor texture for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders, padding, or empty space around edges
- Seamless tiling pattern (edges must match for infinite tiling)
- Top-down orthographic view
- Dark fantasy dungeon aesthetic (Dol Guldur style)
- Subtle texture variation, not flat color
- Must look good at 32x32 and 64x64 display sizes
- No characters, objects, or UI elements
- Consistent medieval/fantasy dungeon style
- Muted earth tones with occasional accent"""

ENVIRONMENT_WALL_TEMPLATE = """A dungeon wall tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders, padding, or empty space
- Dark stone/brick aesthetic
- Top-down or hybrid view showing wall face
- Should visually block and look solid
- Must look good at 32x32 and 64x64 display sizes
- DARKER than floor tiles for clear contrast
- No characters or UI elements
- Dark fantasy style (Dol Guldur)"""

ENVIRONMENT_DOOR_TEMPLATE = """A dungeon door tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders or empty space
- Shows door from top-down dungeon view
- Must be clearly recognizable as a door
- Medieval iron and wood aesthetic
- Stone frame visible around door
- Must look good at 32x32 and 64x64 display sizes
- No characters or UI elements"""

ENVIRONMENT_STAIRS_TEMPLATE = """Dungeon stairs tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders or empty space
- Top-down view showing stairs
- Clear directional indication (up or down)
- Stone construction
- Must look good at 32x32 and 64x64 display sizes
- No characters or UI elements
- Dark fantasy style"""

ENVIRONMENT_SPECIAL_TEMPLATE = """A dungeon special feature tile for a roguelike game.
{description}

CRITICAL REQUIREMENTS:
- Fills ENTIRE 64x64 frame edge-to-edge
- NO borders or empty space
- Top-down or hybrid dungeon view
- Must be clearly identifiable
- Dark fantasy dungeon aesthetic
- Must look good at 32x32 and 64x64 display sizes
- No characters or UI elements"""

# =============================================================================
# PLAYER SPRITES (4)
# =============================================================================
PLAYERS = [
    {
        "id": "R:0",
        "name": "Player Elf",
        "filename": "player/p_0_elf",
        "description": """An elven ranger hero, the player character.
Slender athletic build, pointed ears, wearing forest green hooded cloak.
Carries an elegant longbow, quiver of arrows on back.
Noble determined expression, heroic stance facing slightly right.
Must look distinct as the protagonist - lighter, more noble than enemies."""
    },
    {
        "id": "R:1",
        "name": "Player Man",
        "filename": "player/p_1_man",
        "description": """A human warrior hero, the player character.
Strong build, short dark hair, wearing practical leather armor.
Carries a sword at hip, shield on back.
Determined brave expression, heroic stance facing slightly right.
Must look distinct as the protagonist - human ranger/fighter type."""
    },
    {
        "id": "R:2",
        "name": "Player Dwarf",
        "filename": "player/p_2_dwarf",
        "description": """A dwarven warrior hero, the player character.
Stocky powerful build, thick braided beard, wearing chainmail.
Carries an axe, sturdy and grounded stance.
Fierce determined expression, facing slightly right.
Must look distinct as the protagonist - shorter but powerful."""
    },
    {
        "id": "R:3",
        "name": "Player Alternate",
        "filename": "player/p_3_alt",
        "description": """A hooded mysterious hero, alternate player character.
Cloaked figure in dark traveling clothes, face partially hidden.
Carries a staff, scholarly adventurer appearance.
Enigmatic but heroic stance facing slightly right.
Could be any race - a wandering sage or ranger."""
    },
]

# =============================================================================
# MONSTER SPRITES (45)
# =============================================================================
MONSTERS = [
    # Layer 1: Forest Breach (8)
    {
        "id": "R:11",
        "name": "Mirkwood Spider",
        "filename": "monsters/m_011_mirkwood_spider",
        "description": """A giant spider from Mirkwood forest.
Dog-sized arachnid with eight hairy legs, bristled body.
Multiple gleaming eyes, dripping fangs, venomous appearance.
Dark brown coloring with lighter markings. Aggressive hunting pose."""
    },
    {
        "id": "R:12",
        "name": "Giant Rat",
        "filename": "monsters/m_012_giant_rat",
        "description": """A diseased giant rat from the dungeon.
Cat-sized rodent with matted brown fur, long naked tail.
Red beady eyes, yellow teeth bared, hunched aggressive stance.
Mangy and feral appearance, clearly hostile vermin."""
    },
    {
        "id": "R:13",
        "name": "Black Squirrel",
        "filename": "monsters/m_013_black_squirrel",
        "description": """A corrupted black squirrel, spy of darkness.
Small but sinister rodent with jet black fur.
Unnaturally intelligent eyes, watching and alert.
Perched ready to flee, darker than normal squirrel."""
    },
    {
        "id": "R:14",
        "name": "Crebain",
        "filename": "monsters/m_014_crebain",
        "description": """A crebain crow, evil spy bird of Mordor.
Large black crow with glossy dark feathers.
Sharp beak, malevolent intelligent eyes.
Wings partially spread, perched and watching."""
    },
    {
        "id": "R:15",
        "name": "Tanglethorn",
        "filename": "monsters/m_015_tanglethorn",
        "description": """A living thornbush creature, corrupted plant.
Mass of twisted vines and sharp thorns animated by dark magic.
Grasping tendrils, no clear face but malevolent presence.
Dark green and brown, thorns tipped with poison."""
    },
    {
        "id": "R:16",
        "name": "Giant Bat",
        "filename": "monsters/m_016_giant_bat",
        "description": """A giant bat from the dark caves.
Wingspan of a large dog, leathery gray wings spread.
Ugly face with large ears, sharp teeth, echolocation screech pose.
Flying or swooping attack position."""
    },
    {
        "id": "R:17",
        "name": "Web Spinner",
        "filename": "monsters/m_017_web_spinner",
        "description": """A pale web-spinning spider.
White/cream colored spider variant, spinnerets visible.
Creating or surrounded by web strands.
Ghostly pale compared to brown Mirkwood spider."""
    },
    {
        "id": "R:18",
        "name": "Orc Scout",
        "filename": "monsters/m_018_orc_scout",
        "description": """An orc scout, advance warrior of the dark forces.
Lean wiry orc with gray-green skin, pointed ears, yellow eyes.
Light leather armor, carrying short bow or spear.
Crouching alert pose, sneaky and watchful."""
    },

    # Layer 2: Orc Warrens (10)
    {
        "id": "R:31",
        "name": "Orc Slave",
        "filename": "monsters/m_031_orc_slave",
        "description": """A beaten orc slave, lowest rank of orcs.
Scrawny weak orc with gray skin, bruised and scarred.
Ragged clothing, no armor, maybe a crude club.
Hunched submissive but still dangerous pose."""
    },
    {
        "id": "R:32",
        "name": "Orc Soldier",
        "filename": "monsters/m_032_orc_soldier",
        "description": """An orc soldier, standard warrior of Dol Guldur.
Muscular orc with gray-green skin, tusks, red eyes.
Dark iron armor, crude but effective sword and shield.
Aggressive combat stance, disciplined warrior."""
    },
    {
        "id": "R:33",
        "name": "Orc Crossbowman",
        "filename": "monsters/m_033_orc_crossbowman",
        "description": """An orc crossbowman, ranged fighter.
Orc with gray skin, one eye squinting, aiming pose.
Leather armor, heavy crossbow raised and ready to fire.
Quiver of bolts visible."""
    },
    {
        "id": "R:34",
        "name": "Warg",
        "filename": "monsters/m_034_warg",
        "description": """A warg, evil wolf of Mordor.
Massive wolf-like beast, larger than normal wolf.
Gray-black fur, yellow eyes, slavering jaws with huge fangs.
Snarling aggressive pose, hunched to pounce."""
    },
    {
        "id": "R:35",
        "name": "Orc Thrallmaster",
        "filename": "monsters/m_035_orc_thrallmaster",
        "description": """An orc thrallmaster, slave driver with whip.
Burly orc with cruel expression, ritual scars on face.
Carrying a barbed whip, wearing red-tinted armor.
Domineering stance, clearly a brutal overseer."""
    },
    {
        "id": "R:36",
        "name": "Orc Captain",
        "filename": "monsters/m_036_orc_captain",
        "description": """An orc captain, officer of the orc forces.
Large powerful orc with better armor than soldiers.
Red cloak or banner, commanding presence.
Scimitar raised, shouting orders pose."""
    },
    {
        "id": "R:37",
        "name": "Warg Rider",
        "filename": "monsters/m_037_warg_rider",
        "description": """An orc mounted on a warg.
Orc warrior riding a massive wolf, both in motion.
The orc carries a spear or bow, the warg snarls.
Dynamic mounted combat pose."""
    },
    {
        "id": "R:38",
        "name": "Hill Troll",
        "filename": "monsters/m_038_hill_troll",
        "description": """A hill troll, massive stupid brute.
Huge humanoid twice the size of a man, gray rocky skin.
Tiny eyes, large nose, carrying a tree trunk as club.
Lumbering but dangerous, wearing crude hide."""
    },
    {
        "id": "R:39",
        "name": "Gashnak Warg-lord",
        "filename": "monsters/m_039_gashnak",
        "description": """Gashnak, the Warg-lord - a boss monster.
Enormous alpha warg, bigger and fiercer than normal wargs.
Battle scars, one torn ear, glowing red eyes.
Snarling with huge fangs, clearly the pack leader."""
    },
    {
        "id": "R:40",
        "name": "Orc Warchief",
        "filename": "monsters/m_040_orc_warchief",
        "description": """Orc Warchief - boss of the orc warrens.
Massive orc leader in ornate dark armor with red accents.
Crown or helm of authority, great sword or axe.
Commanding powerful presence, clearly the boss."""
    },

    # Layer 3: Torture Halls (10)
    {
        "id": "R:51",
        "name": "Dark Acolyte",
        "filename": "monsters/m_051_dark_acolyte",
        "description": """A dark acolyte, apprentice of evil magic.
Human or corrupted elf in violet robes.
Pale skin, dark circles under eyes, holding ritual dagger.
Sinister scholarly appearance, dark magic user."""
    },
    {
        "id": "R:52",
        "name": "Ghoul",
        "filename": "monsters/m_052_ghoul",
        "description": """A ghoul, undead corpse eater.
Hunched humanoid with gray dead flesh, long claws.
Hollow hungry eyes, sharp teeth for eating flesh.
Crouching predatory pose, clearly undead horror."""
    },
    {
        "id": "R:53",
        "name": "Mirk-troll",
        "filename": "monsters/m_053_mirk_troll",
        "description": """A Mirk-troll, dark forest troll variant.
Large troll with dark greenish-black skin.
Adapted to darkness, larger eyes, more cunning look.
More dangerous than hill trolls, carries crude weapon."""
    },
    {
        "id": "R:54",
        "name": "Easterling Warrior",
        "filename": "monsters/m_054_easterling_warrior",
        "description": """An Easterling warrior, human servant of Sauron.
Human warrior in bronze-tinted eastern armor.
Dark hair, fierce expression, exotic curved sword.
Foreign warrior style, clearly enemy human."""
    },
    {
        "id": "R:55",
        "name": "Dark Sorcerer",
        "filename": "monsters/m_055_dark_sorcerer",
        "description": """A dark sorcerer, evil magic user.
Robed figure in black with purple accents.
Pale gaunt face, hands crackling with dark energy.
Casting pose with staff, clearly dangerous spellcaster."""
    },
    {
        "id": "R:56",
        "name": "Tortured Wretch",
        "filename": "monsters/m_056_tortured_wretch",
        "description": """A tortured wretch, broken prisoner gone mad.
Emaciated human covered in scars and wounds.
Wild eyes, ragged remains of clothes, feral and insane.
Pitiable but dangerous, attacks on sight."""
    },
    {
        "id": "R:57",
        "name": "Easterling Champion",
        "filename": "monsters/m_057_easterling_champion",
        "description": """An Easterling champion, elite eastern warrior.
Powerful human in ornate bronze armor with orange accents.
Two curved swords, confident elite warrior stance.
More decorated and dangerous than regular Easterlings."""
    },
    {
        "id": "R:58",
        "name": "Ghast",
        "filename": "monsters/m_058_ghast",
        "description": """A ghast, evolved ghoul with paralyzing touch.
Similar to ghoul but larger, with sickly green tinge.
Emits visible stench vapors, longer claws.
More intelligent predatory look than basic ghoul."""
    },
    {
        "id": "R:59",
        "name": "Karvag the Torturer",
        "filename": "monsters/m_059_karvag",
        "description": """Karvag the Torturer - boss of the torture halls.
Massive troll specialized in causing pain.
Red-stained apron, carrying torture implements.
Cruel intelligent eyes unlike normal trolls, very dangerous."""
    },
    {
        "id": "R:60",
        "name": "Master Sorcerer",
        "filename": "monsters/m_060_master_sorcerer",
        "description": """Master Sorcerer - boss dark magic user.
Powerful mage in elaborate dark violet robes.
Glowing eyes, surrounded by dark magical aura.
Staff of power, clearly a major threat."""
    },

    # Layer 4: Necropolis (8)
    {
        "id": "R:71",
        "name": "Skeleton",
        "filename": "monsters/m_071_skeleton",
        "description": """An animated skeleton, basic undead warrior.
Human skeleton held together by dark magic.
Empty eye sockets with faint glow, rusty sword.
Standing ready to fight, bones yellowed with age."""
    },
    {
        "id": "R:72",
        "name": "Skeleton Warrior",
        "filename": "monsters/m_072_skeleton_warrior",
        "description": """A skeleton warrior, armored undead fighter.
Skeleton wearing ancient rusted armor pieces.
Better equipped than basic skeleton, shield and sword.
More intact, clearly a warrior in life."""
    },
    {
        "id": "R:73",
        "name": "Zombie",
        "filename": "monsters/m_073_zombie",
        "description": """A shambling zombie, reanimated corpse.
Rotting humanoid with gray-green decaying flesh.
Blank dead eyes, arms outstretched, lurching pose.
Torn clothing, clearly decomposing but still moving."""
    },
    {
        "id": "R:74",
        "name": "Wight",
        "filename": "monsters/m_074_wight",
        "description": """A wight, intelligent undead spirit in corpse.
Corpse with more presence than zombie, glowing eyes.
Ancient armor or burial clothes, carries weapon.
More dangerous and aware than mindless undead."""
    },
    {
        "id": "R:75",
        "name": "Corpse-candle",
        "filename": "monsters/m_075_corpse_candle",
        "description": """A corpse-candle, ghostly will-o-wisp.
Floating orb of pale yellow ghostly flame.
Wispy ethereal appearance, no solid form.
Lures victims to their death, eerie glow."""
    },
    {
        "id": "R:76",
        "name": "Necromancer Adept",
        "filename": "monsters/m_076_necromancer_adept",
        "description": """A necromancer adept, practitioner of death magic.
Robed figure in dark clothes with bone decorations.
Pale skin, dark eyes, holding skull or bone wand.
Surrounded by faint aura of death magic."""
    },
    {
        "id": "R:77",
        "name": "Barrow-wight",
        "filename": "monsters/m_077_barrow_wight",
        "description": """A barrow-wight, ancient tomb spirit.
Tall spectral figure in ancient royal burial clothes.
Glowing eyes, carries ancient blade, kingly bearing.
More powerful and regal than common wights."""
    },
    {
        "id": "R:79",
        "name": "Grishnakh Crypt Lord",
        "filename": "monsters/m_079_grishnakh",
        "description": """Grishnákh, Crypt Lord - boss of the necropolis.
Powerful undead lord in dark violet burial robes.
Crown of bones, wielding staff of necromancy.
Commands the undead, surrounded by death aura."""
    },

    # Layer 5: Wraith Domain (6)
    {
        "id": "R:91",
        "name": "Phantom",
        "filename": "monsters/m_091_phantom",
        "description": """A phantom, lesser ghost.
Translucent gray humanoid shape, barely visible.
Anguished expression, wispy trailing edges.
Floating, partially transparent, sorrowful."""
    },
    {
        "id": "R:92",
        "name": "Shadow",
        "filename": "monsters/m_092_shadow",
        "description": """A shadow, living darkness creature.
Humanoid shape made of solid darkness.
No features except two dim eyes, absorbs light.
Creeping menacing pose, darker than surroundings."""
    },
    {
        "id": "R:94",
        "name": "Wraith",
        "filename": "monsters/m_094_wraith",
        "description": """A wraith, powerful undead spirit.
Hooded spectral figure in tattered dark robes.
Glowing eyes under hood, skeletal hands visible.
Floating, ethereal, radiating cold and fear."""
    },
    {
        "id": "R:97",
        "name": "Vampire Thrall",
        "filename": "monsters/m_097_vampire_thrall",
        "description": """A vampire thrall, servant of vampires.
Pale human with sunken features, red-tinged eyes.
Subservient posture, fangs visible, bloodstained.
Not a full vampire but clearly corrupted."""
    },
    {
        "id": "R:98",
        "name": "Wailing Horror",
        "filename": "monsters/m_098_wailing_horror",
        "description": """Wailing Horror - boss spectral creature.
Massive ghostly form with gaping screaming mouth.
Multiple wispy tendrils, emitting visible sound waves.
Terrifying apparition, clearly a major threat."""
    },
    {
        "id": "R:99",
        "name": "Uvatha the Horseman",
        "filename": "monsters/m_099_uvatha",
        "description": """Úvatha the Horseman - a Nazgûl boss.
Tall dark robed figure, one of the Nine.
Black robes, crown of shadow, long pale sword.
Mounted or standing, radiating terror and power."""
    },

    # Layer 6: Inner Sanctum (5)
    {
        "id": "R:111",
        "name": "Black Numenorean",
        "filename": "monsters/m_111_black_numenorean",
        "description": """A Black Númenórean, corrupted human noble.
Tall dark human in black armor with fell runes.
Pale skin, dark hair, cruel intelligent face.
Carries dark blade, clearly evil nobility."""
    },
    {
        "id": "R:112",
        "name": "Olog-hai",
        "filename": "monsters/m_112_olog_hai",
        "description": """An Olog-hai, elite battle troll.
Massive armored troll bred by Sauron.
Gray skin, can endure sunlight, intelligent eyes.
Heavy plate armor, huge weapon, disciplined warrior."""
    },
    {
        "id": "R:113",
        "name": "Vampire",
        "filename": "monsters/m_113_vampire",
        "description": """A vampire, undead blood drinker.
Pale elegant humanoid with noble bearing.
Red eyes, visible fangs, dark cloak.
Aristocratic but clearly predatory and evil."""
    },
    {
        "id": "R:115",
        "name": "Vampire Lord",
        "filename": "monsters/m_115_vampire_lord",
        "description": """A Vampire Lord, ancient master vampire.
Regal undead figure in violet and black finery.
Glowing red eyes, commanding presence.
More powerful and ancient than regular vampires."""
    },
    {
        "id": "R:118",
        "name": "Khamul",
        "filename": "monsters/m_118_khamul",
        "description": """Khamûl - the Shadow of the East, a Nazgûl.
Tall terrifying Ringwraith in flowing black robes.
No visible face, crown of shadow, red aura.
Second only to the Witch-King, incredibly menacing."""
    },

    # Layer 7: Final (3)
    {
        "id": "R:131",
        "name": "Elite Olog-hai",
        "filename": "monsters/m_131_elite_olog_hai",
        "description": """An Elite Olog-hai, Sauron's personal guard.
Massive armored troll in black plate with red eye symbol.
Even larger and better equipped than normal Olog-hai.
Elite warrior, final dungeon enemy."""
    },
    {
        "id": "R:134",
        "name": "Thrains Shade",
        "filename": "monsters/m_134_thrains_shade",
        "description": """Thráin's Shade - ghost of the dwarf king.
Spectral dwarf figure in royal ghostly robes.
Crown, long beard, sorrowful expression.
Story character, tragic figure, may be ally or enemy."""
    },
    {
        "id": "R:135",
        "name": "Sauron",
        "filename": "monsters/m_135_sauron",
        "description": """Sauron, the Necromancer - FINAL BOSS.
Tall dark figure of immense power and menace.
Black armor, burning red-orange eyes, crown.
The Dark Lord himself, radiating evil power.
MUST be the most impressive and terrifying sprite."""
    },
]

# =============================================================================
# TERRAIN SPRITES (20)
# =============================================================================
TERRAIN = [
    # Floors (5)
    {
        "id": "F:0",
        "name": "Darkness",
        "filename": "terrain/t_00_darkness",
        "description": """Pure darkness tile, unexplored area.
Completely black or very dark void.
No features, just impenetrable darkness.
Top-down dungeon tile."""
    },
    {
        "id": "F:1",
        "name": "Stone Floor",
        "filename": "terrain/t_01_stone_floor",
        "description": """Basic dungeon stone floor tile.
Gray cracked flagstone, worn by ages.
Subtle texture, occasional moss in cracks.
Top-down view, tileable pattern. Neutral background for characters."""
    },
    {
        "id": "F:9",
        "name": "Fading Daylight",
        "filename": "terrain/t_09_fading_daylight",
        "description": """Floor tile with fading daylight.
Stone floor with subtle yellow-orange tint.
Represents area near entrance with some light.
Top-down view, slightly warmer than normal floor."""
    },
    {
        "id": "F:31",
        "name": "Bloodstain",
        "filename": "terrain/t_31_bloodstain",
        "description": """Floor tile with bloodstain.
Stone floor with dark red dried blood.
Signs of violence, ominous atmosphere.
Top-down view, blood pattern on stone."""
    },
    {
        "id": "F:86",
        "name": "Vine Floor",
        "filename": "terrain/t_86_vine_floor",
        "description": """Floor tile with creeping vines.
Stone floor partially covered by dark green vines.
Forest breach area aesthetic.
Top-down view, organic growth over stone."""
    },

    # Walls (4)
    {
        "id": "F:56",
        "name": "Dark Stone Wall",
        "filename": "terrain/t_56_dark_stone_wall",
        "description": """Dark dungeon wall tile.
Solid dark gray stone blocks.
Ancient masonry, slightly irregular blocks.
Front/top hybrid view typical for roguelikes."""
    },
    {
        "id": "F:48",
        "name": "Hidden Passage",
        "filename": "terrain/t_48_hidden_passage",
        "description": """Secret door disguised as wall.
Looks like wall but with subtle crack/seam.
Player might notice it's different if looking closely.
Same style as wall but with hidden door hint."""
    },
    {
        "id": "F:85",
        "name": "Tangled Roots",
        "filename": "terrain/t_85_tangled_roots",
        "description": """Wall of tangled roots.
Thick brown roots forming a barrier.
Forest breach area, organic wall type.
Impassable root mass, dark brown and green."""
    },
    {
        "id": "F:29",
        "name": "Prison Bars",
        "filename": "terrain/t_29_prison_bars",
        "description": """Iron prison bars tile.
Vertical iron bars with gaps between.
Can see through but not pass.
Dark iron, some rust, dungeon prison style."""
    },

    # Doors (4)
    {
        "id": "F:32",
        "name": "Iron Door",
        "filename": "terrain/t_32_iron_door",
        "description": """Heavy iron dungeon door, closed.
Solid iron door with rivets and bands.
Set in stone frame, clearly locked/closed.
Dark metal, imposing and heavy."""
    },
    {
        "id": "F:4",
        "name": "Open Door",
        "filename": "terrain/t_04_open_door",
        "description": """Wooden door standing open.
Door swung aside, passage visible.
Wooden with iron fittings, worn.
Shows doorway is passable."""
    },
    {
        "id": "F:5",
        "name": "Shattered Door",
        "filename": "terrain/t_05_shattered_door",
        "description": """Broken destroyed door.
Door smashed to pieces, debris on ground.
Signs of violence, splintered wood.
Passage is open through destruction."""
    },
    {
        "id": "F:6",
        "name": "Warded Door",
        "filename": "terrain/t_06_warded_door",
        "description": """Magically warded door, closed.
Door with glowing magical runes.
Green/blue magical glow, clearly enchanted.
Protected by magic, special door."""
    },

    # Stairs (4)
    {
        "id": "F:80",
        "name": "Stairs Up",
        "filename": "terrain/t_80_stairs_up",
        "description": """Stone stairs going up.
Carved stone steps ascending.
< symbol in ASCII, shows way up.
Top-down view showing steps going up."""
    },
    {
        "id": "F:81",
        "name": "Stairs Down",
        "filename": "terrain/t_81_stairs_down",
        "description": """Stone stairs going down.
Carved stone steps descending into darkness.
> symbol in ASCII, shows way down.
Top-down view showing steps going down."""
    },
    {
        "id": "F:82",
        "name": "Shaft Up",
        "filename": "terrain/t_82_shaft_up",
        "description": """Narrow shaft going up.
Rough narrow passage upward.
More cramped than stairs, vertical climb.
Top-down view of narrow upward shaft."""
    },
    {
        "id": "F:83",
        "name": "Shaft Down",
        "filename": "terrain/t_83_shaft_down",
        "description": """Narrow shaft going down.
Dark narrow hole descending.
More cramped than stairs, vertical descent.
Top-down view of narrow downward shaft."""
    },

    # Special (3)
    {
        "id": "F:64",
        "name": "Orc Forge",
        "filename": "terrain/t_64_orc_forge",
        "description": """Orc forge for crafting.
Crude but functional forge with anvil.
Glowing embers, iron tools around.
Interactive crafting location."""
    },
    {
        "id": "F:12",
        "name": "Dark Pool",
        "filename": "terrain/t_12_dark_pool",
        "description": """Pool of dark water.
Still black water in stone basin.
Reflective surface, ominous depth.
Top-down view of dark water feature."""
    },
    {
        "id": "F:13",
        "name": "Morgul Runes",
        "filename": "terrain/t_13_morgul_runes",
        "description": """Floor with glowing Morgul runes.
Stone floor with carved magical runes.
Violet/purple glow, evil magic.
Top-down view, clearly magical hazard."""
    },
]

# =============================================================================
# TRAP SPRITES (6)
# =============================================================================
TRAPS = [
    {
        "id": "F:16",
        "name": "Weakened Floor",
        "filename": "terrain/t_16_weakened_floor",
        "description": """Trap: weakened floor that may collapse.
Cracked stone floor looking unstable.
Visible stress lines, dangerous to step on.
Top-down view, subtle trap indicator."""
    },
    {
        "id": "F:17",
        "name": "Jagged Pit",
        "filename": "terrain/t_17_jagged_pit",
        "description": """Trap: pit with jagged spikes.
Hole in floor revealing deadly spikes below.
Sharp metal or stone spikes visible.
Top-down view of open pit trap."""
    },
    {
        "id": "F:20",
        "name": "Noxious Fumes",
        "filename": "terrain/t_20_noxious_fumes",
        "description": """Trap: vent releasing poison gas.
Floor vent with green toxic gas rising.
Sickly green vapors, clearly dangerous.
Top-down view with visible gas effect."""
    },
    {
        "id": "F:22",
        "name": "Orc Alarm",
        "filename": "terrain/t_22_orc_alarm",
        "description": """Trap: orc alarm mechanism.
Crude tripwire or pressure plate.
Connected to alarm bell or horn.
Top-down view, triggers orc response."""
    },
    {
        "id": "F:26",
        "name": "Thick Web",
        "filename": "terrain/t_26_thick_web",
        "description": """Trap: thick spider web.
Dense sticky web covering floor area.
White/gray strands, slows movement.
Top-down view of web trap."""
    },
    {
        "id": "F:27",
        "name": "Falling Stones",
        "filename": "terrain/t_27_falling_stones",
        "description": """Trap: unstable ceiling dropping rocks.
Floor with rocks/debris, cracked ceiling above.
Red danger indication, falling hazard.
Top-down view with debris."""
    },
]

# =============================================================================
# ITEM SPRITES (12)
# =============================================================================
ITEMS = [
    # Weapons (4)
    {
        "id": "I:sword",
        "name": "Sword",
        "filename": "items/i_sword",
        "description": """A sword weapon.
Generic medieval longsword.
Steel blade, crossguard, wrapped handle.
Lying on ground or floating item view."""
    },
    {
        "id": "I:polearm",
        "name": "Polearm",
        "filename": "items/i_polearm",
        "description": """A polearm weapon.
Spear or glaive with long shaft.
Metal head, wooden pole.
Lying on ground or floating item view."""
    },
    {
        "id": "I:blunt",
        "name": "Blunt Weapon",
        "filename": "items/i_blunt",
        "description": """A blunt weapon.
Mace, hammer, or staff.
Heavy head for crushing.
Lying on ground or floating item view."""
    },
    {
        "id": "I:bow",
        "name": "Bow",
        "filename": "items/i_bow",
        "description": """A bow weapon.
Wooden longbow with string.
Curved elegant design.
Lying on ground or floating item view."""
    },

    # Armor (4)
    {
        "id": "I:armor",
        "name": "Body Armor",
        "filename": "items/i_armor",
        "description": """Body armor.
Chainmail shirt or leather armor.
Protective torso gear.
Lying on ground or floating item view."""
    },
    {
        "id": "I:shield",
        "name": "Shield",
        "filename": "items/i_shield",
        "description": """A shield.
Round or kite shield.
Wood and metal construction.
Lying on ground or floating item view."""
    },
    {
        "id": "I:helm",
        "name": "Helmet",
        "filename": "items/i_helm",
        "description": """A helmet.
Iron or steel helm.
Head protection, medieval style.
Lying on ground or floating item view."""
    },
    {
        "id": "I:misc_armor",
        "name": "Miscellaneous Armor",
        "filename": "items/i_misc_armor",
        "description": """Boots, gloves, or cloak.
Leather boots or traveling cloak.
Miscellaneous protective gear.
Lying on ground or floating item view."""
    },

    # Consumables (2)
    {
        "id": "I:potion",
        "name": "Potion",
        "filename": "items/i_potion",
        "description": """A potion bottle.
Glass flask with colored liquid.
Cork stopper, magical glow.
Generic potion, color can be tinted."""
    },
    {
        "id": "I:herb",
        "name": "Herb/Food",
        "filename": "items/i_herb",
        "description": """Herbs or food item.
Bundle of dried herbs or bread.
Consumable natural item.
Lying on ground or floating item view."""
    },

    # Magic Items (2)
    {
        "id": "I:ring",
        "name": "Ring",
        "filename": "items/i_ring",
        "description": """A magical ring.
Gold or silver ring with gem.
Small circular band, magical aura.
Lying on ground or floating item view."""
    },
    {
        "id": "I:staff",
        "name": "Staff",
        "filename": "items/i_staff",
        "description": """A magical staff.
Wooden staff with crystal or orb.
Wizard's implement, magical glow.
Lying on ground or floating item view."""
    },
]

# =============================================================================
# EFFECT SPRITES (4)
# =============================================================================
EFFECTS = [
    {
        "id": "E:arrow",
        "name": "Arrow Projectile",
        "filename": "effects/e_arrow",
        "description": """Flying arrow projectile.
Arrow in flight, motion blur.
Feathered shaft, metal tip.
Diagonal flying pose."""
    },
    {
        "id": "E:fire",
        "name": "Fire Effect",
        "filename": "effects/e_fire",
        "description": """Fire breath or flame effect.
Burst of orange-red flames.
Dragon breath or fire spell.
Dramatic fire burst."""
    },
    {
        "id": "E:darkness",
        "name": "Darkness Effect",
        "filename": "effects/e_darkness",
        "description": """Shadow or darkness magic effect.
Swirling dark purple/black energy.
Dark spell visual effect.
Ominous shadow magic."""
    },
    {
        "id": "E:impact",
        "name": "Impact Effect",
        "filename": "effects/e_impact",
        "description": """Hit or damage impact effect.
Starburst or slash mark.
Shows where damage occurred.
White/yellow impact flash."""
    },
]

# =============================================================================
# UI SPRITES (5)
# =============================================================================
UI = [
    {
        "id": "U:pile",
        "name": "Item Pile",
        "filename": "ui/u_item_pile",
        "description": """Multiple items on ground.
Stack of various items overlapping.
Indicates many items in one spot.
Mixed items pile."""
    },
    {
        "id": "U:light",
        "name": "Light Source",
        "filename": "ui/u_light_source",
        "description": """Torch or lantern light.
Glowing warm light effect.
Indicates light radius center.
Yellow-orange glow."""
    },
    {
        "id": "U:cursor",
        "name": "Cursor",
        "filename": "ui/u_cursor",
        "description": """Targeting cursor.
Square or crosshair selection.
Shows player targeting location.
Clear UI indicator."""
    },
    {
        "id": "U:poison",
        "name": "Poisoned Status",
        "filename": "ui/u_status_poison",
        "description": """Poisoned status icon.
Green skull or poison drop.
Indicates poison effect active.
Negative status indicator."""
    },
    {
        "id": "U:wounded",
        "name": "Wounded Status",
        "filename": "ui/u_status_wounded",
        "description": """Wounded/low health status icon.
Red heart or blood drop.
Indicates low health warning.
Negative status indicator."""
    },
]

# =============================================================================
# ADDITIONAL TERRAIN (missing from original set)
# =============================================================================
TERRAIN_EXTRA = [
    {
        "id": "F:2",
        "name": "Bottomless Pit",
        "filename": "terrain/t_02_bottomless_pit",
        "description": """A bottomless pit tile, deadly fall trap.
Dark gaping hole in the floor leading to infinite darkness.
Jagged rocky edges, pure black void in center.
Top-down view, clearly dangerous drop."""
    },
    {
        "id": "F:3",
        "name": "Protective Rune",
        "filename": "terrain/t_03_protective_rune",
        "description": """Floor tile with protective magical rune.
Stone floor with glowing green protective symbol.
Circular ward pattern, safe haven indicator.
Top-down view, magical protection effect."""
    },
    {
        "id": "F:7",
        "name": "Warded Door Power 2",
        "filename": "terrain/t_07_warded_door_2",
        "description": """Magically warded door, medium power.
Wooden door with glowing blue magical runes.
More intense glow than basic warded door.
Stronger magical protection visible."""
    },
    {
        "id": "F:8",
        "name": "Warded Door Power 3",
        "filename": "terrain/t_08_warded_door_3",
        "description": """Magically warded door, high power.
Door with intense violet/purple magical runes.
Most powerful ward, swirling magical energy.
Nearly impenetrable magical barrier."""
    },
    {
        "id": "F:14",
        "name": "Shadow Brazier",
        "filename": "terrain/t_14_shadow_brazier",
        "description": """A shadow brazier, source of dark magic.
Iron brazier with dark purple flames.
Emits shadowy wisps, evil light source.
Top-down or hybrid view, ominous glow."""
    },
    {
        "id": "F:15",
        "name": "Torture Rack",
        "filename": "terrain/t_15_torture_rack",
        "description": """A torture rack, dungeon horror.
Wooden torture device with chains and straps.
Dark stained wood, rusty metal parts.
Top-down view, clearly sinister device."""
    },
    {
        "id": "F:18",
        "name": "Poisoned Spike Pit",
        "filename": "terrain/t_18_poisoned_spikes",
        "description": """Trap: pit with poisoned spikes.
Hole in floor with green-tipped metal spikes.
Poison dripping from spike tips.
Top-down view, deadly trap with venom."""
    },
    {
        "id": "F:19",
        "name": "Poison Needle Trap",
        "filename": "terrain/t_19_poison_needle",
        "description": """Trap: hidden poison needle.
Floor tile with tiny hole, needle visible.
Subtle trap, green poison residue.
Top-down view, nearly hidden danger."""
    },
    {
        "id": "F:21",
        "name": "Mind Fog",
        "filename": "terrain/t_21_mind_fog",
        "description": """Trap: mind-affecting fog vent.
Floor vent releasing blue-purple misty fog.
Swirling psychedelic vapors, confusion effect.
Top-down view with visible fog effect."""
    },
    {
        "id": "F:23",
        "name": "Blinding Glyph",
        "filename": "terrain/t_23_blinding_glyph",
        "description": """Trap: blinding light glyph.
Floor with bright yellow magical symbol.
Sun-like rune, radiates intense light.
Top-down view, dangerous if triggered."""
    },
    {
        "id": "F:24",
        "name": "Rusted Caltrops",
        "filename": "terrain/t_24_caltrops",
        "description": """Trap: scattered rusted caltrops.
Floor covered with small spiked metal objects.
Rusty brown, tetanus danger, slows movement.
Top-down view of scattered spikes."""
    },
    {
        "id": "F:25",
        "name": "Bat Roost",
        "filename": "terrain/t_25_bat_roost",
        "description": """Trap: bat roost on ceiling.
Dark ceiling area with sleeping bats visible.
Will disturb and swarm if approached.
Top-down view showing roosting bats."""
    },
    {
        "id": "F:28",
        "name": "Pool of Filth",
        "filename": "terrain/t_28_pool_filth",
        "description": """Trap: disgusting pool of filth.
Stagnant brown-green sewage pool.
Disease hazard, bubbling nastiness.
Top-down view of gross liquid."""
    },
    {
        "id": "F:30",
        "name": "Chains",
        "filename": "terrain/t_30_chains",
        "description": """Hanging chains, dungeon decoration.
Heavy iron chains hanging from ceiling.
Rusty links, clanking hazard.
Top-down or hybrid view of chain pattern."""
    },
    {
        "id": "F:84",
        "name": "Poison Stream",
        "filename": "terrain/t_84_poison_stream",
        "description": """A flowing stream of poison.
Bright green toxic liquid flowing.
Bubbling, steaming poisonous water.
Top-down view of poison river/stream."""
    },
    {
        "id": "F:87",
        "name": "Forest Floor",
        "filename": "terrain/t_87_forest_floor",
        "description": """Natural forest floor tile.
Brown earth with fallen leaves and twigs.
Organic natural ground, outdoor area.
Top-down view, tileable forest ground."""
    },
]

# =============================================================================
# ADDITIONAL ITEMS (to complement existing set)
# =============================================================================
ITEMS_EXTRA = [
    {
        "id": "I:arrow",
        "name": "Arrow Bundle",
        "filename": "items/i_arrow",
        "description": """A bundle of arrows, ammunition.
Several arrows bundled together.
Wooden shafts, feathered fletching, metal tips.
Lying on ground or floating item view."""
    },
    {
        "id": "I:torch",
        "name": "Torch",
        "filename": "items/i_torch",
        "description": """A burning wooden torch.
Wooden handle wrapped in cloth, burning flame.
Primary light source, warm orange glow.
Item view with visible flame."""
    },
    {
        "id": "I:lantern",
        "name": "Lantern",
        "filename": "items/i_lantern",
        "description": """A brass lantern, light source.
Metal lantern with glass panels, warm glow.
Portable light, handle visible.
Item view with warm light effect."""
    },
    {
        "id": "I:amulet",
        "name": "Amulet",
        "filename": "items/i_amulet",
        "description": """A magical amulet necklace.
Gold chain with gemstone pendant.
Magical glow around gem.
Item view of neck jewelry."""
    },
    {
        "id": "I:cloak",
        "name": "Cloak",
        "filename": "items/i_cloak",
        "description": """A traveler's cloak.
Folded dark cloth cloak with clasp.
Protective outer garment.
Item view of folded cloak."""
    },
    {
        "id": "I:boots",
        "name": "Boots",
        "filename": "items/i_boots",
        "description": """A pair of leather boots.
Sturdy brown leather boots.
Travel footwear, worn but serviceable.
Item view of boot pair."""
    },
    {
        "id": "I:gloves",
        "name": "Gloves",
        "filename": "items/i_gloves",
        "description": """A pair of leather gloves.
Brown leather hand protection.
Gauntlets or simple gloves.
Item view of glove pair."""
    },
    {
        "id": "I:chest",
        "name": "Chest",
        "filename": "items/i_chest",
        "description": """A treasure chest container.
Wooden chest with metal bands and lock.
May contain treasure or danger.
Item view of closed chest."""
    },
    {
        "id": "I:horn",
        "name": "Horn",
        "filename": "items/i_horn",
        "description": """A horn instrument.
Curved animal horn with mouthpiece.
Can be blown for signal or magic.
Item view of horn instrument."""
    },
    {
        "id": "I:wand",
        "name": "Wand",
        "filename": "items/i_wand",
        "description": """A magical wand.
Short wooden wand with crystal tip.
Magical implement, glowing faintly.
Item view of wand."""
    },
]

# =============================================================================
# COMBINED LIST
# =============================================================================
ALL_SPRITES = PLAYERS + MONSTERS + TERRAIN + TRAPS + ITEMS + EFFECTS + UI + TERRAIN_EXTRA + ITEMS_EXTRA

def get_all_sprites():
    """Return all 82 sprite definitions"""
    return ALL_SPRITES

def get_sprite_by_id(sprite_id):
    """Find a sprite by its ID"""
    for sprite in ALL_SPRITES:
        if sprite["id"] == sprite_id:
            return sprite
    return None

if __name__ == "__main__":
    print(f"Total sprites defined: {len(ALL_SPRITES)}")
    print(f"  Players: {len(PLAYERS)}")
    print(f"  Monsters: {len(MONSTERS)}")
    print(f"  Terrain: {len(TERRAIN)}")
    print(f"  Traps: {len(TRAPS)}")
    print(f"  Items: {len(ITEMS)}")
    print(f"  Effects: {len(EFFECTS)}")
    print(f"  UI: {len(UI)}")
