#!/usr/bin/env python3
"""
Necromancer Monster Sprite Generator
Generates monster sprites using DALL-E 3, organized by dungeon tier.

Architecture: Same proven pipeline as player_gen.py
- Front-loaded magenta background constraint (THE #1 RULE)
- style="vivid" for readable silhouettes at 64x64
- 3-pass bg removal pipeline
- Dark variants for FOV system

Usage:
    python monster_gen.py --tier 1          # Tier 1: Outer Pits (13 monsters)
    python monster_gen.py --tier 2          # Tier 2: Lower Halls (10 monsters)
    python monster_gen.py --all             # All tiers (77 monsters)
    python monster_gen.py --test            # 1 monster per tier for review
    python monster_gen.py --status          # Show progress
    python monster_gen.py --darken          # Regenerate dark variants only
    python monster_gen.py --single 11       # Generate one monster by ID
"""

import os
import sys
import json
import time
import base64
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import io

from dotenv import load_dotenv
load_dotenv(Path(__file__).parent / ".env")

try:
    from openai import OpenAI
    from PIL import Image, ImageFilter, ImageEnhance
    import numpy as np
except ImportError:
    print("Required packages not installed. Run:")
    print("  pip install openai pillow python-dotenv numpy")
    sys.exit(1)

# Constants
TILE_SIZE = 64
MAX_RETRIES = 3
RATE_LIMIT_DELAY = 2.5
COST_PER_IMAGE = 0.04
WHITE_THRESHOLD = 240

# Paths
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "monster_v2"
PROGRESS_PATH = BASE_DIR / "monster_v2_progress.json"

# ============================================================================
# CREATURE TYPE POSES - determines framing in prompt
# ============================================================================

POSES = {
    "beast": "Seen from a slightly elevated angle, crouching aggressively",
    "spider": "Seen from above, legs splayed outward in a threatening pose",
    "serpent": "Coiled with head reared up, ready to strike",
    "bird": "In flight with wings fully spread wide",
    "bat": "In flight with leathery wings spread wide, mouth open",
    "humanoid": "Standing centered facing the viewer, full body head to toe",
    "undead_humanoid": "Standing centered facing the viewer, full body head to toe, eerie and unsettling",
    "spirit": "Floating ethereally, translucent and ghostly, wisps trailing off the form",
    "plant": "Seen from a slightly elevated angle, rooted to the ground",
    "construct": "Standing imposingly, towering and massive, facing the viewer",
    "troll": "Standing hunched and massive, facing the viewer, brutish power",
    "mounted": "A rider atop a mount, both facing the viewer, seen from slightly below",
    "worm": "Massive segmented body erupting from below, seen from the side",
    "light": "A floating ethereal orb of flickering energy",
    "shadow": "A dark amorphous shape with barely visible features, tendrils of darkness",
    "majestic": "Standing noble and tall, radiating power, facing the viewer",
    "tree": "A massive living tree with a face in its bark, ancient and towering",
}

# ============================================================================
# TIER DEFINITIONS
# ============================================================================

TIERS = {
    1: {"name": "Outer Pits", "depths": "1-3", "tint": "none"},
    2: {"name": "Lower Halls", "depths": "4-6", "tint": "green"},
    3: {"name": "Dark Halls", "depths": "7-9", "tint": "blue"},
    4: {"name": "Necropolis", "depths": "10-12", "tint": "purple"},
    5: {"name": "Pits of Despair", "depths": "13-15", "tint": "red"},
    6: {"name": "Inner Sanctum", "depths": "16-18", "tint": "dark gold"},
    7: {"name": "Throne Room", "depths": "19-20", "tint": "bright gold"},
    8: {"name": "Hallucinations", "depths": "special", "tint": "none"},
}

# ============================================================================
# MONSTER DEFINITIONS - All 77 monsters
# Each needs: id, name, tier, creature_type, visual_desc, colors, boss flag
# ============================================================================

MONSTERS = {
    # ========================================================================
    # TIER 1: OUTER PITS (Depths 1-3) - 13 monsters
    # ========================================================================
    11: {
        "name": "Mirkwood Spider",
        "tier": 1,
        "creature_type": "spider",
        "visual_desc": "a large brown spider the size of a dog with bristled hairy legs, dripping venomous fangs, and multiple gleaming red eyes",
        "colors": "dark brown, bristle tan, venom green, red eyes",
        "boss": False,
    },
    12: {
        "name": "Giant Rat",
        "tier": 1,
        "creature_type": "beast",
        "visual_desc": "a bloated rat the size of a cat with matted dark brown fur, a long naked pink tail, yellowed teeth bared, and beady red eyes gleaming with disease",
        "colors": "dark brown fur, pink tail, yellow teeth, red eyes",
        "boss": False,
    },
    13: {
        "name": "Black Squirrel",
        "tier": 1,
        "creature_type": "beast",
        "visual_desc": "a corrupted black squirrel with unnaturally dark fur, glowing red eyes, sharp claws, and a bushy tail raised in aggression",
        "colors": "jet black fur, glowing red eyes, dark claws",
        "boss": False,
    },
    14: {
        "name": "Crebain",
        "tier": 1,
        "creature_type": "bird",
        "visual_desc": "a large sinister black crow with glossy dark feathers, a cruel sharp beak, and malevolent intelligent eyes, a spy of the Dark Lord",
        "colors": "glossy black feathers, dark purple sheen, orange-yellow eyes",
        "boss": False,
    },
    15: {
        "name": "Tanglethorn",
        "tier": 1,
        "creature_type": "plant",
        "visual_desc": "a living animated rosebush creature with coiling woody vine arms, covered in small spines, glowing green magical eyes peering from within the foliage, a whimsical but menacing fantasy plant being",
        "colors": "dark woody brown, deep green leaves, glowing green eyes, vine tendrils",
        "boss": False,
    },
    16: {
        "name": "Giant Bat",
        "tier": 1,
        "creature_type": "bat",
        "visual_desc": "a bat the size of a large dog with enormous leathery dark gray wings, large pointed ears, a screeching open mouth showing sharp teeth, and beady black eyes",
        "colors": "dark gray-brown wings, pale underbelly, pink inner ears",
        "boss": False,
    },
    17: {
        "name": "Web Spinner",
        "tier": 1,
        "creature_type": "spider",
        "visual_desc": "a pale ghostly white spider constantly trailing silk threads from its spinnerets, delicate translucent legs, and milky white eyes",
        "colors": "pale white, translucent legs, silver silk threads, milky eyes",
        "boss": False,
    },
    18: {
        "name": "Orc Scout",
        "tier": 1,
        "creature_type": "humanoid",
        "visual_desc": "a small wiry orc in worn leather scout armor with a crude short sword at its belt and a signal horn slung over its shoulder, yellowish-green skin, pointed ears, and suspicious darting eyes",
        "colors": "yellow-green skin, worn brown leather, dull iron blade",
        "boss": False,
    },
    19: {
        "name": "Swamp Adder",
        "tier": 1,
        "creature_type": "serpent",
        "visual_desc": "a thick venomous green snake with dark diamond patterns along its body, hood flared wide, dripping fangs exposed, ready to strike",
        "colors": "dark green scales, black diamond pattern, pale belly, venom yellow fangs",
        "boss": False,
    },
    20: {
        "name": "Great Spider",
        "tier": 1,
        "creature_type": "spider",
        "visual_desc": "a massive dark spider of Shelob's brood, black and purple carapace gleaming, mandibles wide open dripping venom, eight thick hairy legs spread wide, terrifyingly large",
        "colors": "black carapace, dark purple sheen, venom green, red eyes",
        "boss": False,
    },
    21: {
        "name": "Warg Pup",
        "tier": 1,
        "creature_type": "beast",
        "visual_desc": "a young warg wolf cub with dark brown shaggy fur, oversized paws, bared teeth in a snarl, and cruel yellow eyes already full of malice",
        "colors": "dark brown fur, yellow eyes, white teeth, gray underbelly",
        "boss": False,
    },
    22: {
        "name": "Broodmother",
        "tier": 1,
        "creature_type": "spider",
        "visual_desc": "a grotesquely bloated giant spider with a massive swollen egg sac for an abdomen, thick armored legs, a crown of glowing red eyes, and mandibles dripping acidic venom, horrifying matriarch of a spider nest",
        "colors": "mottled brown-black, bloated pale abdomen, glowing red eyes, acid green venom",
        "boss": True,
    },
    31: {
        "name": "Orc Slave",
        "tier": 1,
        "creature_type": "humanoid",
        "visual_desc": "a wretched emaciated orc in ragged filthy clothing, hunched posture, visible whip scars on gray-green skin, hollow fearful eyes, clutching a rusty pickaxe",
        "colors": "gray-green skin, filthy rags, rust brown, hollow dark eyes",
        "boss": False,
    },

    # ========================================================================
    # TIER 2: LOWER HALLS (Depths 4-6) - 10 monsters
    # ========================================================================
    32: {
        "name": "Orc Soldier",
        "tier": 2,
        "creature_type": "humanoid",
        "visual_desc": "an orc warrior in black leather armor with iron studs, carrying a notched scimitar in one hand and a round wooden shield in the other, dark green skin, a snarling battle-ready face",
        "colors": "dark green skin, black leather armor, iron studs, dull steel blade",
        "boss": False,
    },
    33: {
        "name": "Orc Crossbowman",
        "tier": 2,
        "creature_type": "humanoid",
        "visual_desc": "an orc in dark leather armor aiming a heavy iron crossbow, a quiver of cruel barbed bolts on its hip, one eye squinted shut taking aim, dark green skin",
        "colors": "dark green skin, brown leather, iron crossbow, black bolts",
        "boss": False,
    },
    34: {
        "name": "Warg",
        "tier": 2,
        "creature_type": "beast",
        "visual_desc": "a great wolf the size of a horse with dark gray fur, massive jaws full of fangs, baleful yellow eyes full of cunning intelligence, powerful muscled shoulders",
        "colors": "dark gray fur, yellow eyes, white fangs, black claws",
        "boss": False,
    },
    35: {
        "name": "Orc Thrallmaster",
        "tier": 2,
        "creature_type": "humanoid",
        "visual_desc": "a cruel stocky orc in studded leather armor cracking a long barbed whip in one hand, iron manacles hanging from his belt, a sadistic grin on his scarred dark green face",
        "colors": "dark green skin, brown studded leather, black whip, iron manacles",
        "boss": False,
    },
    36: {
        "name": "Orc Captain",
        "tier": 2,
        "creature_type": "humanoid",
        "visual_desc": "a large imposing orc officer in heavy iron plate armor with a red-plumed helmet, wielding a jagged iron sword, dark green skin covered in ritual scars, commanding presence",
        "colors": "dark green skin, iron plate armor, red plume, jagged steel sword",
        "boss": False,
    },
    37: {
        "name": "Warg Rider",
        "tier": 2,
        "creature_type": "mounted",
        "visual_desc": "a fierce orc warrior riding atop a massive dark gray warg wolf, the orc brandishing a curved sword overhead, the warg snarling with bared fangs, both charging forward",
        "colors": "green orc skin, gray warg fur, black leather, steel blade",
        "boss": False,
    },
    38: {
        "name": "Hill Troll",
        "tier": 2,
        "creature_type": "troll",
        "visual_desc": "a massive stupid brute of a troll with thick gray rocky skin, a huge gut, tiny mean eyes, wielding a crude wooden club the size of a tree trunk, towering and immensely strong",
        "colors": "gray rocky skin, brown loincloth, wooden club, dull eyes",
        "boss": False,
    },
    39: {
        "name": "Gashnak Warg-lord",
        "tier": 2,
        "creature_type": "beast",
        "visual_desc": "the largest and most fearsome warg, pure white fur streaked with old battle scars, massive jaws, burning intelligent amber eyes, a crown of bone fragments around its neck like trophies",
        "colors": "white fur, battle scars, amber eyes, bone trophies",
        "boss": True,
    },
    40: {
        "name": "Orc Warchief",
        "tier": 2,
        "creature_type": "humanoid",
        "visual_desc": "a massive scarred orc warlord in heavy black iron armor decorated with crude skulls, wielding a brutal double-headed battle axe, a torn red war banner on his back, one eye missing replaced by a jagged scar",
        "colors": "dark green skin, black iron armor, red war banner, bone decorations",
        "boss": True,
    },
    51: {
        "name": "Dark Acolyte",
        "tier": 2,
        "creature_type": "humanoid",
        "visual_desc": "a human cultist in dark violet robes with a cowl shadowing their face, pale sickly skin, hands raised with dark purple magical energy crackling between the fingers, arcane symbols on the robes",
        "colors": "dark violet robes, pale skin, purple magic energy, arcane gold symbols",
        "boss": False,
    },

    # ========================================================================
    # TIER 3: DARK HALLS (Depths 7-9) - 13 monsters
    # ========================================================================
    52: {
        "name": "Ghoul",
        "tier": 3,
        "creature_type": "undead_humanoid",
        "visual_desc": "a hunched emaciated ghoul with gray rotting flesh, long clawed fingers, a wide mouth full of jagged teeth, hollow eye sockets with pinpoints of cold blue light, crouching to feed",
        "colors": "gray rotting flesh, cold blue eye-glow, dark claws, tattered rags",
        "boss": False,
    },
    53: {
        "name": "Mirk-troll",
        "tier": 3,
        "creature_type": "troll",
        "visual_desc": "a dark-skinned troll bred in Dol Guldur's pits, mottled black and green hide, weapons dripping with green poison, eyes adapted to darkness glowing faintly yellow, tusks jutting from its jaw",
        "colors": "black-green hide, poison green drip, yellow eyes, dark tusks",
        "boss": False,
    },
    54: {
        "name": "Easterling Warrior",
        "tier": 3,
        "creature_type": "humanoid",
        "visual_desc": "a disciplined warrior from the East in ornate bronze lamellar armor, wearing a spiked helm with a red face guard, wielding a curved scimitar and a small round buckler, dark eyes full of determination",
        "colors": "bronze armor, red face guard, dark steel blade, olive skin",
        "boss": False,
    },
    55: {
        "name": "Dark Sorcerer",
        "tier": 3,
        "creature_type": "humanoid",
        "visual_desc": "a sinister sorcerer in layered black robes with dark runes embroidered in silver, a staff topped with a smoky black crystal in one hand, shadows coiling around their feet, gaunt pale face with burning dark eyes",
        "colors": "black robes, silver runes, smoky dark crystal, pale skin",
        "boss": False,
    },
    56: {
        "name": "Tortured Wretch",
        "tier": 3,
        "creature_type": "undead_humanoid",
        "visual_desc": "a wild-eyed prisoner driven mad by torment, torn bloody clothing, wild matted hair, brandishing broken chains as weapons, mouth open in a silent scream, covered in scars and wounds",
        "colors": "pale skin, bloody rags, rusty chain, wild white eyes",
        "boss": False,
    },
    57: {
        "name": "Easterling Champion",
        "tier": 3,
        "creature_type": "humanoid",
        "visual_desc": "an elite heavily-armored warrior from the East in ornate gold and red plate armor, a tall plumed war helm, wielding a massive two-handed curved great sword, imposing and battle-scarred",
        "colors": "gold and red plate armor, tall plume, dark steel blade, olive skin",
        "boss": False,
    },
    58: {
        "name": "Ghast",
        "tier": 3,
        "creature_type": "undead_humanoid",
        "visual_desc": "a bloated powerful ghoul with sickly green-tinged rotting flesh, distended belly, long razor claws, a visible cloud of putrid green stench around it, glowing yellow eyes",
        "colors": "sickly green flesh, putrid green cloud, yellow eyes, dark claws",
        "boss": False,
    },
    59: {
        "name": "Karvag the Torturer",
        "tier": 3,
        "creature_type": "troll",
        "visual_desc": "a blood-red skinned troll wearing a leather torturer's apron stained with gore, carrying cruel iron implements of pain in both hands, a necklace of finger bones, sadistic grin showing iron-capped teeth",
        "colors": "blood-red skin, gore-stained leather, iron torture tools, bone necklace",
        "boss": True,
    },
    60: {
        "name": "Master Sorcerer",
        "tier": 3,
        "creature_type": "humanoid",
        "visual_desc": "a powerful sorcerer in ornate dark violet robes with golden arcane patterns, eyes blazing with purple fire, both hands raised channeling swirling dark magical energy overhead, an aura of malevolent power",
        "colors": "dark violet robes, golden patterns, purple fire eyes, dark energy",
        "boss": True,
    },
    71: {
        "name": "Skeleton",
        "tier": 3,
        "creature_type": "undead_humanoid",
        "visual_desc": "an animated human skeleton held together by dark magic, empty eye sockets glowing with faint blue light, wielding a rusted sword in one bony hand, jaw hanging open in a silent rattling moan",
        "colors": "yellowed bone white, faint blue eye-glow, rusted blade, dark joints",
        "boss": False,
    },
    73: {
        "name": "Zombie",
        "tier": 3,
        "creature_type": "undead_humanoid",
        "visual_desc": "a shambling rotting corpse in tattered burial clothes, gray-green decaying flesh hanging from exposed bones, arms outstretched reaching forward, milky dead white eyes, relentless and slow",
        "colors": "gray-green flesh, tattered brown rags, exposed bone white, milky eyes",
        "boss": False,
    },
    80: {
        "name": "Easterling Infiltrator",
        "tier": 3,
        "creature_type": "humanoid",
        "visual_desc": "a stealthy eastern scout in dark blue-black lightweight armor, a dark cloth mask covering the lower face, gripping a curved dagger in each hand, crouching in a ready stance",
        "colors": "dark blue-black armor, dark mask, steel daggers, olive skin",
        "boss": False,
    },
    85: {
        "name": "Tunnel Crawler",
        "tier": 3,
        "creature_type": "worm",
        "visual_desc": "a massive centipede-like creature with a segmented brown armored carapace, dozens of sharp legs, large mandibles dripping venom, antennae twitching, erupting from a tunnel",
        "colors": "brown armored carapace, dark legs, venom green mandibles, red antennae",
        "boss": False,
    },

    # ========================================================================
    # TIER 4: NECROPOLIS (Depths 10-12) - 14 monsters
    # ========================================================================
    72: {
        "name": "Skeleton Warrior",
        "tier": 4,
        "creature_type": "undead_humanoid",
        "visual_desc": "a skeleton clad in rusted ancient armor wielding a notched blade in one hand and a battered shield in the other, blue fire burning in its eye sockets, standing in a combat stance it held in life",
        "colors": "yellowed bone, rusted iron armor, blue fire eyes, dark blade",
        "boss": False,
    },
    74: {
        "name": "Wight",
        "tier": 4,
        "creature_type": "spirit",
        "visual_desc": "a spectral figure bound to a decaying corpse in ancient burial wrappings, cold blue light emanating from hollow eyes, skeletal hands reaching out with an aura of life-draining frost",
        "colors": "pale blue glow, dark burial wrappings, frost white hands, cold light",
        "boss": False,
    },
    75: {
        "name": "Corpse-candle",
        "tier": 4,
        "creature_type": "light",
        "visual_desc": "a flickering ghostly orb of sickly yellow-green light floating in the air, wisps of spectral energy trailing behind it, mesmerizing and luring, a will-o-the-wisp of the deep",
        "colors": "sickly yellow-green glow, pale wisp trails, eerie light",
        "boss": False,
    },
    76: {
        "name": "Necromancer Adept",
        "tier": 4,
        "creature_type": "humanoid",
        "visual_desc": "a gaunt sorcerer in dark hooded robes with bone decorations, one hand raised summoning a swirl of ghostly green necromantic energy, corpses stirring at their feet, skull staff in the other hand",
        "colors": "dark robes, bone white decorations, ghostly green energy, pale skin",
        "boss": False,
    },
    77: {
        "name": "Barrow-wight",
        "tier": 4,
        "creature_type": "spirit",
        "visual_desc": "a towering ancient evil spirit in rotting kingly burial robes, a corroded iron crown on its skeletal head, burning white eyes of pure malice, radiating waves of supernatural cold, a dark blade in one hand",
        "colors": "dark rotting robes, corroded iron crown, burning white eyes, frost aura",
        "boss": False,
    },
    78: {
        "name": "Bone Golem",
        "tier": 4,
        "creature_type": "construct",
        "visual_desc": "a towering hulking construct assembled from hundreds of fused bones, arms ending in massive bone-blade weapons, a skull-like head with glowing red eyes, animated by visible dark purple necromantic energy in the joints",
        "colors": "bone white, dark purple energy in joints, red eye-glow, massive",
        "boss": False,
    },
    79: {
        "name": "Grishnakh Crypt Lord",
        "tier": 4,
        "creature_type": "spirit",
        "visual_desc": "a wight of terrible power in ornate dark burial armor, a crown of black iron and amethyst on its skull, blazing violet eyes, commanding the dead with outstretched clawed hands, an aura of dread",
        "colors": "dark burial armor, black iron crown, violet amethyst, blazing violet eyes",
        "boss": True,
    },
    81: {
        "name": "Cave Troll",
        "tier": 4,
        "creature_type": "troll",
        "visual_desc": "a massive troll with thick gray stone-like skin covered in cave fungus, tiny furious eyes, wielding a huge iron-banded war hammer, far larger and stronger than a hill troll, filling the passage",
        "colors": "gray stone skin, cave fungus green, iron war hammer, tiny red eyes",
        "boss": False,
    },
    82: {
        "name": "Dark Ritualist",
        "tier": 4,
        "creature_type": "humanoid",
        "visual_desc": "a sorcerer in dark violet ceremonial robes covered in necromantic sigils, drawing a glowing ritual circle in the air with one hand, holding a bloody sacrificial dagger in the other, eyes glowing violet",
        "colors": "dark violet robes, glowing ritual sigils, blood-red dagger, violet eyes",
        "boss": False,
    },
    83: {
        "name": "Corsair of Umbar",
        "tier": 4,
        "creature_type": "humanoid",
        "visual_desc": "a swarthy pirate from Umbar in sea-stained blue and black leather armor, wielding twin curved cutlasses, gold earrings, a scarred grinning face, salt-crusted boots, dangerous and cunning",
        "colors": "dark blue-black leather, gold earrings, steel cutlasses, tanned skin",
        "boss": False,
    },
    84: {
        "name": "Dunlending Berserker",
        "tier": 4,
        "creature_type": "humanoid",
        "visual_desc": "a fierce wildman from Dunland with blue woad war paint on bare muscled arms and face, wild tangled hair, swinging a massive two-handed war axe overhead, screaming in berserker rage",
        "colors": "blue woad paint, pale skin, wild dark hair, iron war axe, fur pelts",
        "boss": False,
    },
    86: {
        "name": "Pale Crawler",
        "tier": 4,
        "creature_type": "beast",
        "visual_desc": "a blind pallid cave creature with smooth white skin, eyeless face with a wide mouth of needle teeth, long spindly limbs with suction-cup fingers, adapted to absolute darkness, unsettling and alien",
        "colors": "chalk white skin, pale pink mouth, translucent limbs, needle teeth",
        "boss": False,
    },
    91: {
        "name": "Phantom",
        "tier": 4,
        "creature_type": "spirit",
        "visual_desc": "a faded translucent ghostly figure barely visible, a wispy humanoid shape made of gray mist with hollow dark eye holes, flickering in and out of visibility, trailing ectoplasmic wisps",
        "colors": "translucent gray, misty white, dark hollow eyes, fading edges",
        "boss": False,
    },
    100: {
        "name": "Black Numenorean Acolyte",
        "tier": 4,
        "creature_type": "humanoid",
        "visual_desc": "a tall pale human in dark layered robes with silver Numenorean patterns, a circlet of dark iron on their brow, one hand crackling with dark sorcery, aristocratic cruel features",
        "colors": "dark robes, silver Numenorean patterns, dark iron circlet, pale skin",
        "boss": False,
    },

    # ========================================================================
    # TIER 5: PITS OF DESPAIR (Depths 13-15) - 13 monsters
    # ========================================================================
    92: {
        "name": "Shadow",
        "tier": 5,
        "creature_type": "shadow",
        "visual_desc": "a living patch of absolute darkness in a vaguely humanoid shape, tendrils of shadow reaching outward, where it passes the light dims, barely visible dark claws at the edges of its form",
        "colors": "pure black, dark purple edges, void darkness, faint outline",
        "boss": False,
    },
    93: {
        "name": "Whispering Shade",
        "tier": 5,
        "creature_type": "shadow",
        "visual_desc": "a flickering dark wraith-like shade made of wisps of black smoke, a vague face with an open mouth frozen in a whisper, spreading darkness around it, tendrils of shadow like tattered robes",
        "colors": "black smoke, dark purple wisps, faint face outline, shadow tendrils",
        "boss": False,
    },
    94: {
        "name": "Wraith",
        "tier": 5,
        "creature_type": "spirit",
        "visual_desc": "a tall spectral figure in flowing tattered dark gray robes, no visible face beneath its hood except two burning cold blue points of light, skeletal hands gripping a ghostly blade, a mantled shape of void and dread",
        "colors": "dark gray robes, cold blue eye-points, ghostly blade, spectral mist",
        "boss": False,
    },
    95: {
        "name": "Fell Spirit",
        "tier": 5,
        "creature_type": "spirit",
        "visual_desc": "a formless malevolent spirit of pure dark violet energy, barely humanoid, radiating waves of fear, spectral claws of dark energy, passing through solid matter, an entity of pure hatred",
        "colors": "dark violet energy, spectral purple, ghostly wisps, malevolent glow",
        "boss": False,
    },
    96: {
        "name": "Spectre",
        "tier": 5,
        "creature_type": "spirit",
        "visual_desc": "an insubstantial barely-visible ghostly figure of pale white mist in the shape of a robed person, spectral hands reaching out, bringing the cold of the grave, fading into transparency at the edges",
        "colors": "pale white mist, translucent, frost blue edges, barely visible",
        "boss": False,
    },
    97: {
        "name": "Vampire Thrall",
        "tier": 5,
        "creature_type": "undead_humanoid",
        "visual_desc": "a gaunt vampire with ashen gray skin, sunken red eyes burning with hunger, elongated fangs, wearing tattered noble clothing, clawed hands reaching forward, a creature of eternal thirst",
        "colors": "ashen gray skin, burning red eyes, tattered dark clothing, white fangs",
        "boss": False,
    },
    98: {
        "name": "The Wailing Horror",
        "tier": 5,
        "creature_type": "spirit",
        "visual_desc": "a massive amorphous horror from beyond the world, pale white and translucent, multiple screaming ghostly faces merged into one writhing form, tendrils of spectral energy lashing outward, freezing all it touches",
        "colors": "pale white, ghostly blue, screaming faces, spectral energy tendrils",
        "boss": True,
    },
    99: {
        "name": "Uvatha the Horseman",
        "tier": 5,
        "creature_type": "spirit",
        "visual_desc": "a Nazgul Ringwraith in flowing black robes and a dark iron crown, a tall menacing figure of pure darkness, one gauntleted hand gripping a long Morgul blade glowing with cold pale light, an aura of supernatural terror",
        "colors": "pitch black robes, dark iron crown, pale Morgul blade glow, void darkness",
        "boss": True,
    },
    101: {
        "name": "Haradrim Assassin",
        "tier": 5,
        "creature_type": "humanoid",
        "visual_desc": "a deadly assassin from the south wrapped in dark flowing desert robes, a curved poisoned dagger in each hand with green-tinged blades, dark kohl-lined eyes visible above a black face wrap, crouching to strike",
        "colors": "dark desert robes, dark skin, green-tinged blades, kohl-black eyes",
        "boss": False,
    },
    102: {
        "name": "Cave Worm",
        "tier": 5,
        "creature_type": "worm",
        "visual_desc": "a massive armored worm erupting from the ground with a segmented blue-gray body, a circular maw ringed with rows of grinding teeth, tough armored plates along its length, debris falling from around it",
        "colors": "blue-gray armored plates, dark maw, grinding white teeth, earth debris",
        "boss": False,
    },
    103: {
        "name": "Oathbreaker Captain",
        "tier": 5,
        "creature_type": "spirit",
        "visual_desc": "a spectral ghostly warrior in ancient Gondorian plate armor now corroded and translucent, a ghostly longsword raised, the faded white tree of Gondor still visible on his spectral breastplate, a cursed soldier bound by a broken oath",
        "colors": "translucent green-white, corroded spectral armor, faded white tree emblem",
        "boss": False,
    },
    104: {
        "name": "Morgul Sorcerer",
        "tier": 5,
        "creature_type": "humanoid",
        "visual_desc": "a sorcerer trained in the arts of Morgul wearing dark layered robes with sickly green magical runes, wielding a staff topped with a pale glowing orb, gaunt face half-hidden by a dark cowl, eyes burning with Morgul fire",
        "colors": "dark robes, sickly green runes, pale orb glow, Morgul-fire eyes",
        "boss": False,
    },
    111: {
        "name": "Black Numenorean",
        "tier": 5,
        "creature_type": "humanoid",
        "visual_desc": "a tall imposing warrior-sorcerer in dark ornate Numenorean plate armor with silver inlay, a dark cloak, holding a long dark sword in one hand, dark energy flickering around the other hand, pale noble but corrupted features",
        "colors": "dark plate armor, silver Numenorean inlay, dark sword, pale corrupted features",
        "boss": False,
    },

    # ========================================================================
    # TIER 6: INNER SANCTUM (Depths 16-18) - 9 monsters
    # ========================================================================
    112: {
        "name": "Olog-hai",
        "tier": 6,
        "creature_type": "troll",
        "visual_desc": "a massive battle-troll bred by Sauron with dark gray armored hide, wearing crude black iron plate armor, wielding a huge spiked iron mace, intelligent cruel eyes unlike lesser trolls, bred to fight in daylight",
        "colors": "dark gray hide, black iron armor, spiked mace, cruel red eyes",
        "boss": False,
    },
    113: {
        "name": "Vampire",
        "tier": 6,
        "creature_type": "bat",
        "visual_desc": "a nightmarish vampire in its true bat-like form the size of a man, enormous dark leathery wings spread wide, a bestial fanged face with burning red eyes, clawed hands reaching forward, a creature of the night",
        "colors": "dark leathery wings, burning red eyes, pale fanged face, black claws",
        "boss": False,
    },
    114: {
        "name": "Greater Wraith",
        "tier": 6,
        "creature_type": "spirit",
        "visual_desc": "a wraith of immense power in flowing dark violet spectral robes, perhaps once a king, a dark crown hovering above its hooded head, the very air darkening around it, twin points of baleful violet light for eyes",
        "colors": "dark violet spectral robes, dark crown, violet eye-lights, darkened air",
        "boss": False,
    },
    115: {
        "name": "Vampire Lord",
        "tier": 6,
        "creature_type": "humanoid",
        "visual_desc": "an ancient vampire lord in ornate dark noble clothing with a high collar and crimson-lined cloak, pale aristocratic face with burning crimson eyes and elongated fangs, one clawed hand raised commanding, regal and terrifying",
        "colors": "dark noble clothing, crimson cloak lining, pale skin, burning crimson eyes",
        "boss": False,
    },
    116: {
        "name": "Shadow Lord",
        "tier": 6,
        "creature_type": "shadow",
        "visual_desc": "a lord among shadows, a towering figure of absolute impenetrable darkness with a vague crown-like shape atop its head, extinguishing all light around it, darker than dark with tendrils of void reaching outward",
        "colors": "absolute black, void darkness, faint crown outline, light-devouring aura",
        "boss": False,
    },
    117: {
        "name": "Maia Thrall",
        "tier": 6,
        "creature_type": "spirit",
        "visual_desc": "a corrupted lesser Maia spirit, a being of stolen fire wrapped in dark chains, burning with orange-red flames beneath a shell of dark corruption, anguished face visible in the flames, enslaved divine power",
        "colors": "orange-red fire, dark corruption chains, burning amber, anguished face",
        "boss": False,
    },
    118: {
        "name": "Khamul Shadow of the East",
        "tier": 6,
        "creature_type": "spirit",
        "visual_desc": "a Nazgul Ringwraith in magnificent dark flowing robes, the second most powerful of the Nine, a dark iron spiked crown, one hand raising a Morgul blade glowing with sickly pale light, an overwhelming aura of dread and shadow, taller and more terrible than other wraiths",
        "colors": "pitch black robes, dark iron crown, pale Morgul glow, absolute dread",
        "boss": True,
    },
    131: {
        "name": "Elite Olog-hai",
        "tier": 6,
        "creature_type": "troll",
        "visual_desc": "the finest of Sauron's battle-trolls, massive and clad head to toe in heavy black iron plate armor with the red eye of Sauron emblazoned on its breastplate, wielding an enormous black iron war hammer, elite and deadly",
        "colors": "black iron armor, red eye emblem, massive war hammer, dark steel",
        "boss": False,
    },
    136: {
        "name": "Black Numenorean Lord",
        "tier": 6,
        "creature_type": "humanoid",
        "visual_desc": "a lord of the Black Numenoreans in magnificent dark ornate armor with purple-glowing runes, a dark crown of sorcery, wielding a long dark blade wreathed in shadow, dark sorcery rivaling the lesser Nazgul, imposing and ancient",
        "colors": "dark ornate armor, purple-glowing runes, dark crown, shadow-wreathed blade",
        "boss": False,
    },

    # ========================================================================
    # TIER 7: THRONE ROOM (Depths 19-20) - 5 monsters
    # ========================================================================
    132: {
        "name": "Greater Shadow",
        "tier": 7,
        "creature_type": "shadow",
        "visual_desc": "an immense shadow of devastating power drawn from the void, a towering amorphous mass of absolute darkness that devours all light and matter it touches, vague clawed appendages reaching from the darkness, the void given form",
        "colors": "absolute void black, devouring darkness, faint purple edges, cosmic horror",
        "boss": False,
    },
    133: {
        "name": "Void Wraith",
        "tier": 7,
        "creature_type": "spirit",
        "visual_desc": "a wraith from beyond the circles of the world, robes of swirling void-black and deep violet, multiple ghostly arms reaching outward, a face that is a window into the void between stars, guarding the innermost chambers",
        "colors": "void-black robes, deep violet, multiple ghostly arms, starless void face",
        "boss": False,
    },
    134: {
        "name": "Thrain's Shade",
        "tier": 7,
        "creature_type": "spirit",
        "visual_desc": "the broken translucent shade of a once-great dwarven king, spectral dwarven armor and a ghostly crown, clutching something precious in withered spectral hands, an expression of torment and madness, a tragic figure",
        "colors": "translucent blue-white, spectral dwarven armor, ghostly crown, tragic glow",
        "boss": False,
    },
    135: {
        "name": "Sauron the Necromancer",
        "tier": 7,
        "creature_type": "majestic",
        "visual_desc": "the Dark Lord Sauron in his Necromancer form, a towering figure in magnificent dark armor of black and burning gold, a great spiked crown, one hand wreathed in sorcerous flame, eyes of molten fire, radiating overwhelming dark majesty and terrible power",
        "colors": "black armor, burning gold, molten fire eyes, sorcerous flame, dark majesty",
        "boss": True,
    },
    137: {
        "name": "Mouth of Sauron",
        "tier": 7,
        "creature_type": "humanoid",
        "visual_desc": "the lieutenant of Barad-dur, a tall figure in black Numenorean plate armor with a great helm that hides the upper face, only a cruel wide grinning mouth visible below, holding a dark herald's staff, speaking with Sauron's voice",
        "colors": "black plate armor, great dark helm, cruel grinning mouth, dark herald staff",
        "boss": True,
    },

    # ========================================================================
    # TIER 8: HALLUCINATIONS (Special - depth 30) - 10 monsters
    # ========================================================================
    301: {
        "name": "Gandalf the Grey",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "a wise old wizard in long gray robes and a tall pointed gray hat, a long white beard, leaning on a gnarled wooden staff, kind but piercing blue eyes, a warm gentle presence with hidden immense power",
        "colors": "gray robes, gray pointed hat, white beard, wooden staff, blue eyes",
        "boss": False,
    },
    302: {
        "name": "Thranduil Elvenking",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "a tall regal elf king in magnificent silver and green woodland armor with a crown of autumn leaves and berries, long platinum blond hair, holding an elegant elven sword, cold proud handsome elven features",
        "colors": "silver armor, forest green, autumn leaf crown, platinum blond hair",
        "boss": False,
    },
    303: {
        "name": "Galadriel Lady of Light",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "a luminous elven queen in flowing white robes that seem to glow with inner starlight, long golden hair, a ring of power on one hand, radiating serene wisdom and ancient power, the most beautiful of all elves",
        "colors": "glowing white robes, golden hair, starlight aura, inner radiance",
        "boss": False,
    },
    304: {
        "name": "Elrond Half-elven",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "a noble elven lord in rich dark blue and silver robes with a circlet of silver on his dark hair, wise ancient eyes, holding a hand raised in a gesture of healing light, lord of a hidden valley",
        "colors": "dark blue robes, silver circlet, dark hair, healing light, wise eyes",
        "boss": False,
    },
    305: {
        "name": "Thorin Oakenshield",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "a proud dwarven king in heavy blue and silver armor with a fur-lined cloak, a magnificent dark braided beard with silver clasps, wielding an ancient dwarven war axe, regal and unyielding determination",
        "colors": "blue and silver armor, fur cloak, dark beard, silver clasps, dwarven axe",
        "boss": False,
    },
    306: {
        "name": "Beorn the Skinchanger",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "an enormous powerful man with wild dark hair and beard, massive bare muscled arms, wearing simple rough-spun clothing and a bear-skin cloak, amber eyes with a bestial intensity, half-man half-bear in spirit",
        "colors": "bear-brown cloak, wild dark hair, amber eyes, rough clothing, massive build",
        "boss": False,
    },
    307: {
        "name": "Radagast the Brown",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "an eccentric wizard in patched brown robes with leaves and twigs caught in his wild brown hair and beard, a small bird perched on his shoulder, kind bewildered eyes, carrying a crooked staff wrapped in vines",
        "colors": "patched brown robes, wild hair with leaves, vine-wrapped staff, warm brown",
        "boss": False,
    },
    308: {
        "name": "Eagle of the Misty Mountains",
        "tier": 8,
        "creature_type": "bird",
        "visual_desc": "a colossal great eagle with an enormous wingspan, golden-brown feathers gleaming in sunlight, a sharp curved golden beak, fierce intelligent golden eyes, the greatest of all birds, majestic and powerful in flight",
        "colors": "golden-brown feathers, golden beak, fierce golden eyes, white underbelly",
        "boss": False,
    },
    309: {
        "name": "Great Elk of Mirkwood",
        "tier": 8,
        "creature_type": "majestic",
        "visual_desc": "a magnificent enormous elk with a towering crown of silver antlers, deep blue-gray fur, wise ancient dark eyes, standing noble and proud, an ancient spirit of the forest made flesh",
        "colors": "deep blue-gray fur, silver antlers, wise dark eyes, forest spirit",
        "boss": False,
    },
    310: {
        "name": "Ent of Fangorn",
        "tier": 8,
        "creature_type": "tree",
        "visual_desc": "a massive ancient living tree creature with a face formed in its gnarled bark, deep wise slow eyes, branch-like arms with twig fingers, moss and lichen covering its trunk-body, an ancient shepherd of the forest",
        "colors": "dark brown bark, moss green, lichen gray, deep amber eyes, ancient wood",
        "boss": False,
    },
}


def get_monster_prompt(monster: Dict) -> str:
    """
    Build a DALL-E 3 prompt for a monster sprite.

    Applies ALL learnings from player sprite generation:
    - Front-load magenta bg constraint as FIRST clause (#1 RULE)
    - style="vivid" for readable silhouettes
    - "A single creature only" to prevent duplicates
    - "vivid fantasy illustration" framing
    - Include hex code for precision
    - NEVER use "pixel art", "sprite", "game tile", "texture"
    """
    pose = POSES.get(monster["creature_type"], POSES["humanoid"])

    prompt = (
        f"On a completely solid flat hot magenta background (hex FF00FF), "
        f"a vivid fantasy illustration of {monster['visual_desc']}. "
        f"{pose}. "
        f"Vivid striking colors: {monster['colors']}. "
        f"Strong readable silhouette against the magenta. "
        f"The background must be entirely uniform solid magenta with absolutely nothing else. "
        f"A single creature only, no other elements. "
        f"Painted in a clean illustrative style."
    )

    return prompt


def auto_crop_and_resize(img: Image.Image, target_size: int = TILE_SIZE) -> Image.Image:
    """
    Detect content area, crop out white/light borders, resize to target_size.
    Same proven algorithm as player_gen.py.
    """
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]

    r, g, b = img_array[:, :, 0], img_array[:, :, 1], img_array[:, :, 2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD

    rows_with_content = np.any(content_mask, axis=1)
    cols_with_content = np.any(content_mask, axis=0)

    if not np.any(rows_with_content) or not np.any(cols_with_content):
        print("  WARNING: Image appears entirely white/blank")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)

    row_start = np.argmax(rows_with_content)
    row_end = h - np.argmax(rows_with_content[::-1])
    col_start = np.argmax(cols_with_content)
    col_end = w - np.argmax(cols_with_content[::-1])

    border_top = row_start
    border_bottom = h - row_end
    border_left = col_start
    border_right = w - col_end

    print(f"  Border: top={border_top} bot={border_bottom} "
          f"left={border_left} right={border_right}")

    min_border = int(h * 0.02)
    if (border_top > min_border or border_bottom > min_border or
            border_left > min_border or border_right > min_border):

        padding = 2
        row_start = max(0, row_start - padding)
        row_end = min(h, row_end + padding)
        col_start = max(0, col_start - padding)
        col_end = min(w, col_end + padding)

        cropped = img.crop((col_start, row_start, col_end, row_end))
        crop_w, crop_h = cropped.size
        print(f"  Cropped: {w}x{h} -> {crop_w}x{crop_h}")

        if crop_w != crop_h:
            max_dim = max(crop_w, crop_h)
            square = Image.new("RGBA", (max_dim, max_dim), (255, 0, 255, 255))
            paste_x = (max_dim - crop_w) // 2
            paste_y = (max_dim - crop_h) // 2
            square.paste(cropped, (paste_x, paste_y))
            cropped = square
            print(f"  Squared: {max_dim}x{max_dim}")

        result = cropped.resize((target_size, target_size), Image.Resampling.NEAREST)
        print(f"  Resized to {target_size}x{target_size}")
        return result
    else:
        print(f"  No significant border - direct resize")
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)


def generate_dark_variant(img: Image.Image) -> Image.Image:
    """Generate dark/FOV variant: desaturate 60%, darken 40%, cool blue tint."""
    if img.mode == "RGBA":
        alpha = img.split()[3]
        rgb = img.convert("RGB")
    else:
        alpha = None
        rgb = img.convert("RGB")

    gray = rgb.convert("L").convert("RGB")
    desaturated = Image.blend(rgb, gray, 0.6)

    darkener = ImageEnhance.Brightness(desaturated)
    darkened = darkener.enhance(0.6)

    arr = np.array(darkened).astype(np.float32)
    arr[:, :, 0] *= 0.85
    arr[:, :, 1] *= 0.90
    arr[:, :, 2] = np.minimum(arr[:, :, 2] * 1.15, 255)
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, "RGB")

    if alpha is not None:
        result = result.convert("RGBA")
        result.putalpha(alpha)

    return result


def validate_tile(img: Image.Image) -> Tuple[bool, str]:
    """Validate a generated monster tile."""
    w, h = img.size
    if w != TILE_SIZE or h != TILE_SIZE:
        return False, f"Wrong size: {w}x{h}"

    arr = np.array(img.convert("RGB"))
    brightness = arr.mean()
    if brightness > 200:
        return False, f"Too bright (avg {brightness:.0f})"

    std = arr.std()
    if std < 8:
        return False, f"Too uniform (std {std:.1f})"

    return True, "OK"


class MonsterGenerator:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.progress = self._load_progress()

    def _load_progress(self) -> Dict:
        if PROGRESS_PATH.exists():
            with open(PROGRESS_PATH, "r") as f:
                return json.load(f)
        return {
            "started_at": datetime.now().isoformat(),
            "last_updated": datetime.now().isoformat(),
            "sprites": {},
            "cost_total": 0.0,
            "api_calls": 0,
        }

    def _save_progress(self):
        self.progress["last_updated"] = datetime.now().isoformat()
        with open(PROGRESS_PATH, "w") as f:
            json.dump(self.progress, f, indent=2)

    def _sprite_key(self, monster_id: int) -> str:
        return f"monster_{monster_id}"

    def generate_single(self, monster_id: int, retry: int = 0) -> Optional[Path]:
        """Generate a single monster sprite."""
        if monster_id not in MONSTERS:
            print(f"  ERROR: Unknown monster ID {monster_id}")
            return None

        monster = MONSTERS[monster_id]
        key = self._sprite_key(monster_id)

        # Skip if already completed
        if key in self.progress["sprites"]:
            info = self.progress["sprites"][key]
            if info.get("status") == "completed":
                existing = Path(info["path"])
                if existing.exists():
                    print(f"  SKIP: {key} ({monster['name']}) already completed")
                    return existing

        prompt = get_monster_prompt(monster)
        tier_info = TIERS[monster["tier"]]
        boss_tag = " [BOSS]" if monster["boss"] else ""
        label = f"[T{monster['tier']}] {monster['name']}{boss_tag}"

        print(f"\n{'=' * 60}")
        print(f"Generating: {label}")
        print(f"Key: {key} | Tier: {tier_info['name']} | Type: {monster['creature_type']}")
        print(f"Prompt: {prompt[:150]}...")

        try:
            response = self.client.images.generate(
                model="dall-e-3",
                prompt=prompt,
                size="1024x1024",
                quality="standard",
                style="vivid",
                n=1,
                response_format="b64_json",
            )

            self.progress["api_calls"] = self.progress.get("api_calls", 0) + 1
            self.progress["cost_total"] = self.progress.get("cost_total", 0) + COST_PER_IMAGE

            img_data = base64.b64decode(response.data[0].b64_json)
            img_1024 = Image.open(io.BytesIO(img_data)).convert("RGBA")

            revised = getattr(response.data[0], "revised_prompt", None)
            if revised:
                print(f"  DALL-E revised: {revised[:120]}...")

            # Save raw 1024x1024
            raw_dir = self.output_dir / "raw"
            raw_dir.mkdir(exist_ok=True)
            raw_path = raw_dir / f"{key}_1024.png"
            img_1024.save(raw_path)
            print(f"  Saved raw: {raw_path.name}")

            # Auto-crop and resize to 64x64
            img_64 = auto_crop_and_resize(img_1024, TILE_SIZE)

            # Validate
            is_valid, reason = validate_tile(img_64)
            if not is_valid:
                print(f"  VALIDATION FAILED: {reason}")
                if retry < MAX_RETRIES:
                    print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                    time.sleep(RATE_LIMIT_DELAY)
                    return self.generate_single(monster_id, retry + 1)
                else:
                    print(f"  MAX RETRIES - saving for manual review")

            # Save light variant
            tier_dir = self.output_dir / f"tier_{monster['tier']}"
            tier_dir.mkdir(exist_ok=True)
            light_path = tier_dir / f"{key}_light.png"
            img_64.save(light_path)
            print(f"  Saved light: {light_path.name}")

            # Generate and save dark variant
            img_dark = generate_dark_variant(img_64)
            dark_path = tier_dir / f"{key}_dark.png"
            img_dark.save(dark_path)
            print(f"  Saved dark: {dark_path.name}")

            # Update progress
            self.progress["sprites"][key] = {
                "status": "completed",
                "path": str(light_path),
                "dark_path": str(dark_path),
                "monster_id": monster_id,
                "name": monster["name"],
                "tier": monster["tier"],
                "creature_type": monster["creature_type"],
                "boss": monster["boss"],
                "valid": is_valid,
                "validation_msg": reason,
                "completed_at": datetime.now().isoformat(),
            }
            self._save_progress()

            return light_path

        except Exception as e:
            print(f"  ERROR: {e}")
            if retry < MAX_RETRIES:
                print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                time.sleep(RATE_LIMIT_DELAY * 2)
                return self.generate_single(monster_id, retry + 1)

            self.progress["sprites"][key] = {
                "status": "failed",
                "error": str(e),
                "monster_id": monster_id,
                "name": monster["name"],
                "tier": monster["tier"],
                "failed_at": datetime.now().isoformat(),
            }
            self._save_progress()
            return None

    def generate_tier(self, tier: int) -> Dict[str, bool]:
        """Generate all monsters in a specific tier."""
        tier_monsters = {mid: m for mid, m in MONSTERS.items() if m["tier"] == tier}
        if not tier_monsters:
            print(f"No monsters found for tier {tier}")
            return {}

        tier_info = TIERS[tier]
        results = {}
        print(f"\n{'=' * 60}")
        print(f"TIER {tier}: {tier_info['name'].upper()} (Depths {tier_info['depths']})")
        print(f"Monsters: {len(tier_monsters)} | Est. cost: ${len(tier_monsters) * COST_PER_IMAGE:.2f}")
        print(f"{'=' * 60}")

        for monster_id in sorted(tier_monsters.keys()):
            monster = tier_monsters[monster_id]
            key = self._sprite_key(monster_id)
            path = self.generate_single(monster_id)
            results[key] = path is not None
            time.sleep(RATE_LIMIT_DELAY)

        self._print_summary(results, tier)
        return results

    def generate_test(self) -> Dict[str, bool]:
        """Generate 1 monster per tier for review (8 sprites)."""
        # Pick a representative monster per tier
        test_picks = {
            1: 11,   # Mirkwood Spider
            2: 38,   # Hill Troll
            3: 71,   # Skeleton
            4: 78,   # Bone Golem
            5: 99,   # Uvatha the Horseman
            6: 112,  # Olog-hai
            7: 135,  # Sauron
            8: 301,  # Gandalf
        }

        results = {}
        print(f"\n{'=' * 60}")
        print(f"MONSTER TEST GENERATION - 1 per tier ({len(test_picks)} sprites)")
        print(f"{'=' * 60}")

        for tier, monster_id in sorted(test_picks.items()):
            key = self._sprite_key(monster_id)
            path = self.generate_single(monster_id)
            results[key] = path is not None
            time.sleep(RATE_LIMIT_DELAY)

        self._print_summary(results)
        return results

    def generate_all(self) -> Dict[str, bool]:
        """Generate all monsters across all tiers."""
        results = {}
        print(f"\n{'=' * 60}")
        print(f"FULL MONSTER GENERATION - {len(MONSTERS)} monsters across {len(TIERS)} tiers")
        print(f"Est. cost: ${len(MONSTERS) * COST_PER_IMAGE:.2f}")
        print(f"{'=' * 60}")

        for tier in sorted(TIERS.keys()):
            tier_results = self.generate_tier(tier)
            results.update(tier_results)

        print(f"\n{'=' * 60}")
        print(f"ALL MONSTERS COMPLETE")
        self._print_summary(results)
        return results

    def generate_dark_variants_only(self):
        """Generate dark variants for all existing light sprites."""
        count = 0
        for key, info in self.progress["sprites"].items():
            if info.get("status") != "completed":
                continue
            light_path = Path(info["path"])
            if not light_path.exists():
                continue
            dark_path = light_path.parent / light_path.name.replace("_light.", "_dark.")
            if dark_path.exists():
                continue

            img = Image.open(light_path).convert("RGBA")
            dark = generate_dark_variant(img)
            dark.save(dark_path)
            info["dark_path"] = str(dark_path)
            count += 1
            print(f"  Generated dark: {dark_path.name}")

        self._save_progress()
        print(f"\nGenerated {count} dark variants")

    def show_status(self):
        """Display generation progress by tier."""
        print(f"\n{'=' * 60}")
        print("MONSTER SPRITE GENERATION STATUS")
        print(f"{'=' * 60}")

        grand_total = 0
        grand_done = 0

        for tier in sorted(TIERS.keys()):
            tier_info = TIERS[tier]
            tier_monsters = {mid: m for mid, m in MONSTERS.items() if m["tier"] == tier}
            total = len(tier_monsters)
            done = 0
            bosses_done = 0
            bosses_total = sum(1 for m in tier_monsters.values() if m["boss"])

            for mid in tier_monsters:
                key = self._sprite_key(mid)
                if key in self.progress["sprites"]:
                    if self.progress["sprites"][key].get("status") == "completed":
                        done += 1
                        if tier_monsters[mid]["boss"]:
                            bosses_done += 1

            grand_total += total
            grand_done += done

            bar_len = 20
            filled = int(bar_len * done / total) if total > 0 else 0
            bar = "#" * filled + "-" * (bar_len - filled)
            boss_str = f" (bosses: {bosses_done}/{bosses_total})" if bosses_total > 0 else ""
            print(f"  T{tier} {tier_info['name']:20s} [{bar}] {done:2d}/{total:2d}{boss_str}")

        print(f"\n  Total: {grand_done}/{grand_total}")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Est. cost: ${self.progress.get('cost_total', 0):.2f}")
        print(f"  Output: {self.output_dir}/")

    def _print_summary(self, results: Dict[str, bool], tier: int = None):
        print(f"\n{'=' * 60}")
        if tier:
            print(f"TIER {tier} GENERATION SUMMARY")
        else:
            print("GENERATION SUMMARY")
        print(f"{'=' * 60}")
        succeeded = sum(1 for v in results.values() if v)
        failed = sum(1 for v in results.values() if not v)
        for key, success in results.items():
            mid = int(key.split("_")[1])
            name = MONSTERS[mid]["name"] if mid in MONSTERS else "?"
            status = "OK" if success else "FAILED"
            print(f"  {key} ({name}): {status}")
        print(f"\n  Succeeded: {succeeded}, Failed: {failed}")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Est. cost: ${self.progress.get('cost_total', 0):.2f}")
        print(f"\n  Review sprites at: {self.output_dir}/")
        print(f"  Raw 1024x1024 at: {self.output_dir}/raw/")


def main():
    parser = argparse.ArgumentParser(description="Necromancer Monster Sprite Generator")
    parser.add_argument("--tier", type=int,
                        help="Generate all monsters for a tier (1-8)")
    parser.add_argument("--all", action="store_true",
                        help="Generate all monsters across all tiers")
    parser.add_argument("--test", action="store_true",
                        help="Generate 1 test monster per tier (8 sprites)")
    parser.add_argument("--status", action="store_true",
                        help="Show progress status")
    parser.add_argument("--darken", action="store_true",
                        help="Generate dark variants from existing light sprites")
    parser.add_argument("--single", type=int,
                        help="Generate a single monster by ID")
    args = parser.parse_args()

    if args.status:
        gen = MonsterGenerator("dummy")
        gen.show_status()
        return

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY not found in environment or .env file")
        sys.exit(1)

    gen = MonsterGenerator(api_key)

    if args.darken:
        gen.generate_dark_variants_only()
    elif args.test:
        gen.generate_test()
    elif args.all:
        gen.generate_all()
    elif args.tier:
        gen.generate_tier(args.tier)
    elif args.single:
        gen.generate_single(args.single)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
