#!/usr/bin/env python3
"""
Necromancer Item Sprite Generator
Generates item sprites using DALL-E 3, organized by item category.

Architecture: Same proven pipeline as monster_gen.py / player_gen.py
- Front-loaded magenta background constraint (THE #1 RULE)
- style="vivid" for readable silhouettes at 64x64
- Auto-generates visual descriptions from item name + category templates
- Deduplicates identical items (shares one sprite across multiple IDs)

Usage:
    python item_gen.py --all              # Generate all unique item sprites
    python item_gen.py --category sword   # Generate one category
    python item_gen.py --test             # 1 item per category for review
    python item_gen.py --status           # Show progress
    python item_gen.py --single 64        # Generate one item by ID
    python item_gen.py --darken           # Regenerate dark variants only
    python item_gen.py --list             # List all items and categories
"""

import os
import sys
import json
import time
import re
import base64
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from collections import defaultdict
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
PROJECT_DIR = BASE_DIR.parent
DATA_DIR = PROJECT_DIR / "data"
OUTPUT_DIR = BASE_DIR / "item_v2"
PROGRESS_PATH = BASE_DIR / "item_v2_progress.json"

# ============================================================================
# CATEGORY DEFINITIONS - determines framing and base descriptions
# ============================================================================

CATEGORIES = {
    # Weapons
    23: {
        "name": "sword",
        "pose": "A single weapon lying diagonally across the frame, blade gleaming",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "steel blade, leather grip, metallic sheen",
    },
    22: {
        "name": "polearm",
        "pose": "A single weapon standing vertically, point upward",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark wood shaft, steel head, iron bands",
    },
    21: {
        "name": "hafted",
        "pose": "A single weapon lying diagonally, heavy end prominent",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "oak wood, iron head, leather wrap",
    },
    20: {
        "name": "digging",
        "pose": "A single tool lying diagonally, working end prominent",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "iron head, wooden handle, worn leather grip",
    },
    19: {
        "name": "bow",
        "pose": "A single bow standing vertically, string taut",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark wood, bowstring, carved details",
    },
    18: {
        "name": "sling",
        "pose": "A single sling coiled neatly, pouch visible",
        "base_template": "a {material} sling with {detail}",
        "default_colors": "dark leather, braided cord",
    },
    17: {
        "name": "arrow",
        "pose": "A bundle of arrows lying diagonally, fletching visible",
        "base_template": "a bundle of {material} arrows with {detail}",
        "default_colors": "wooden shafts, steel tips, feather fletching",
    },
    16: {
        "name": "sling_stone",
        "pose": "A small pile of smooth rounded stones",
        "base_template": "a pile of {material} sling stones",
        "default_colors": "gray smooth stone, river-polished",
    },
    # Armor
    37: {
        "name": "body_armor",
        "pose": "A single piece of armor displayed front-facing, as if on an invisible stand",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark metal, leather straps, chain links",
    },
    36: {
        "name": "soft_armor",
        "pose": "A garment displayed front-facing, as if worn by an invisible figure",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark fabric, leather panels, stitched details",
    },
    32: {
        "name": "helm",
        "pose": "A single helmet seen from the front, slightly elevated angle",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark metal, leather interior, rivets",
    },
    33: {
        "name": "crown",
        "pose": "A single crown floating slightly above center, regal and imposing",
        "base_template": "a {material} crown with {detail}",
        "default_colors": "dark metal, gemstones, ornate engravings",
    },
    34: {
        "name": "shield",
        "pose": "A single shield displayed front-facing, slightly angled",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "wood and iron, leather rim, metal boss",
    },
    35: {
        "name": "cloak",
        "pose": "A cloak draped as if hanging, slightly billowing",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark fabric, clasp, flowing folds",
    },
    30: {
        "name": "boots",
        "pose": "A pair of boots seen from the front, slightly angled",
        "base_template": "a pair of {material} {subtype} with {detail}",
        "default_colors": "dark leather, iron buckles, worn soles",
    },
    31: {
        "name": "gloves",
        "pose": "A pair of gloves displayed palms-down, slightly overlapping",
        "base_template": "a pair of {material} {subtype} with {detail}",
        "default_colors": "dark leather, reinforced knuckles",
    },
    # Jewelry
    45: {
        "name": "ring",
        "pose": "A single ring floating at center, slightly tilted to show detail",
        "base_template": "a {material} ring with {detail}",
        "default_colors": "gold band, gemstone, inner glow",
    },
    40: {
        "name": "amulet",
        "pose": "A single pendant or amulet hanging from a chain, centered",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "gold chain, pendant, gemstone center",
    },
    # Consumables
    75: {
        "name": "potion",
        "pose": "A single glass flask standing upright, liquid glowing within",
        "base_template": "a glass flask filled with {color} glowing liquid, {detail}",
        "default_colors": "glass flask, colored liquid, cork stopper",
    },
    80: {
        "name": "herb",
        "pose": "A small bundle or portion of the item, seen from slightly above",
        "base_template": "a {subtype} of {detail}",
        "default_colors": "natural greens, earthy tones",
    },
    55: {
        "name": "scroll",
        "pose": "A single scroll partially unrolled, mystical writing visible",
        "base_template": "a parchment scroll with {color} mystical writing, {detail}",
        "default_colors": "aged parchment, glowing runes, wax seal",
    },
    56: {
        "name": "wand",
        "pose": "A single wand lying diagonally, tip glowing with magical energy",
        "base_template": "a {material} wand tipped with {detail}",
        "default_colors": "dark wood, crystal tip, magical glow",
    },
    66: {
        "name": "horn",
        "pose": "A single horn or instrument lying at a slight angle",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark material, metallic accents, carved details",
    },
    77: {
        "name": "oil",
        "pose": "A small flask or vial standing upright",
        "base_template": "a small {material} container of {detail}",
        "default_colors": "dark glass, amber liquid, metal cap",
    },
    # Light sources
    39: {
        "name": "light",
        "pose": "A single light source, glowing warmly",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "warm glow, metallic body, flame or crystal light",
    },
    # Containers
    7: {
        "name": "chest",
        "pose": "A single chest seen from slightly above and to the side",
        "base_template": "a {material} {subtype} with {detail}",
        "default_colors": "dark wood or metal, iron bands, lock or clasp",
    },
    # Misc
    3: {
        "name": "skeleton",
        "pose": "A pile of old bones and skull seen from above",
        "base_template": "a pile of {subtype} bones with {detail}",
        "default_colors": "yellowed bone, dark shadows, ancient remains",
    },
    4: {
        "name": "special_material",
        "pose": "A gleaming chunk of precious material",
        "base_template": "a gleaming piece of {detail}",
        "default_colors": "silvery gleam, precious metal, inner light",
    },
    2: {
        "name": "document",
        "pose": "A single piece of parchment or document, slightly worn",
        "base_template": "a {subtype} with {detail}",
        "default_colors": "aged parchment, dark ink, worn edges",
    },
}

# ============================================================================
# CUSTOM VISUAL DESCRIPTIONS - Override auto-generation for special items
# ============================================================================

CUSTOM_DESCS = {
    # === SWORDS (tval=23) ===
    56: ("a ranger's short knife with a leaf-shaped elven blade, wrapped leather grip, and a faint green shimmer",
         "leaf-green blade, brown leather, elven silver"),
    57: ("a crude black orcish blade with a jagged serrated edge, rough iron hilt wrapped in dark hide, and dark runes scratched into the flat",
         "black iron, dark hide grip, crude red runes"),
    60: ("an elegant woodland elf sword with a gently curved green-tinged blade, vine-carved crossguard, and living wood grip",
         "green-tinged blade, vine crossguard, living wood grip"),
    64: ("a fine steel longsword with a straight double-edged blade, leather-wrapped cruciform hilt, and polished pommel",
         "bright steel blade, leather grip, polished pommel"),
    67: ("a broad Rohirric cavalry sword with horse-head pommel, wide single-edged blade, and gold inlaid hilt",
         "bright steel, gold horse pommel, wide blade"),
    68: ("a magnificent Númenórean longsword with ancient sea-steel blade etched with star patterns, ornate silver crossguard",
         "sea-steel blade, silver crossguard, star etchings"),
    69: ("a gleaming mithril sword with an impossibly sharp silvery blade that seems to glow with inner light, elegant proportions",
         "gleaming mithril, inner silver glow, perfect edge"),
    70: ("a massive mithril great-blade, a two-handed sword of gleaming silver-white metal with runes running the length of the blade",
         "massive mithril blade, silver runes, two-handed"),
    491: ("a broken glowing magical weapon, shattered blade still pulsing with faint blue arcane energy, hilt intact",
          "broken blade, blue arcane glow, shattered steel"),
    493: ("a broken strange weapon of alien dark metal, twisted and warped, faint purple energy leaking from cracks",
          "broken dark metal, purple energy, twisted form"),
    # === POLEARMS/AXES (tval=22) ===
    71: ("a simple hunting spear with a leaf-shaped iron head on a long ash wood shaft, leather grip wrapping",
         "iron spearhead, ash wood shaft, leather grip"),
    72: ("an ornate tower guard's spear with a long steel blade, silver-banded shaft, and white tree of Gondor etched near the head",
         "steel spearhead, silver bands, white tree emblem"),
    74: ("a sinister Morgul glaive with a curved sickly-green blade, black iron shaft, and dark runes that seem to writhe",
         "sickly green blade, black iron, writhing dark runes"),
    76: ("a sturdy woodsman's axe with a broad steel head, long hickory handle, and well-worn leather wrap",
         "broad steel head, hickory handle, worn leather"),
    77: ("a heavy dwarven war-axe with a double-headed steel blade etched with geometric patterns, short iron-banded handle",
         "double-headed steel, geometric etchings, iron bands"),
    81: ("a massive Erebor great-axe with a huge rune-carved mithril-edged blade, thick oak shaft banded in gold",
         "massive blade, mithril edge, gold-banded oak shaft"),
    # === HAFTED (tval=21) ===
    19: ("a massive war hammer with a heavy iron head and long oak shaft, brutal and powerful",
         "heavy iron head, oak shaft, brutal weight"),
    86: ("a tall oak quarterstaff with iron-capped ends and carved spiral patterns, a versatile weapon",
         "oak wood, iron caps, carved spirals"),
    89: ("a heavy dwarven war hammer with a square mithril head etched with runes, short iron handle wrapped in leather",
         "mithril hammer head, rune etchings, iron handle"),
    # === DIGGING (tval=20) ===
    96: ("a well-used miner's spade with a flat iron blade and wooden handle, practical and sturdy",
         "iron blade, wooden handle, mine dust"),
    98: ("a heavy dwarven mattock with a pick on one side and axe blade on the other, iron-banded handle",
         "iron pick and axe head, banded handle"),
    # === BOWS (tval=19) ===
    110: ("a graceful silvan elf bow of pale wood with leaf-carved limbs, silver-wound string, elegant curve",
          "pale wood, leaf carvings, silver string"),
    111: ("a tall yew longbow with a simple but powerful design, dark wood with subtle grain, linen string",
          "dark yew wood, tall limbs, linen string"),
    112: ("a magnificent bow made from a dragon's horn, dark curved limbs with an amber sheen, impossibly powerful",
          "dark amber dragon horn, powerful curve, golden sheen"),
    # === SLINGS (tval=18) ===
    118: ("a simple leather sling with a woven cord and worn leather pouch",
          "brown leather, braided cord, worn pouch"),
    119: ("a fine leather sling of supple dark leather with reinforced stitching and a perfectly shaped pouch",
          "fine dark leather, reinforced stitching"),
    # === BODY ARMOR (tval=37) ===
    30: ("a Gondorian corslet of overlapping steel scales with the white tree emblem on the breast, leather-backed",
         "steel scales, white tree emblem, leather backing"),
    31: ("a heavy dwarven hauberk of interlocking iron rings, thick and protective, with geometric border patterns",
         "iron chain rings, geometric borders, heavy build"),
    38: ("a legendary mithril corslet, a shirt of tiny interlocking rings that gleams like moonlit silver, impossibly light",
         "gleaming mithril rings, moonlight silver, impossibly light"),
    492: ("shattered elven chain mail, broken mithril links still gleaming, torn but still beautiful",
          "broken mithril links, elven craftsmanship, shattered"),
    494: ("twisted dark plate armor corrupted by shadow magic, black metal warped into disturbing organic shapes",
          "twisted black metal, shadow corruption, organic shapes"),
    # === SOFT ARMOR (tval=36) ===
    22: ("a simple wanderer's robe of brown homespun cloth, practical and unremarkable, with a rope belt",
         "brown homespun, rope belt, practical"),
    23: ("ranger's leathers of dark green and brown, supple and quiet, with many small pockets and buckles",
         "dark green-brown leather, buckles, many pockets"),
    26: ("a scout's lightweight dark armor of hardened leather with metal studs at the shoulders",
         "hardened dark leather, metal studs, lightweight"),
    27: ("shadow-steel armor of dark black metal plates over dark leather, absorbing light, nearly invisible in darkness",
         "black steel plates, dark leather, light-absorbing"),
    # === HELMS (tval=32) ===
    100: ("a simple iron helm with a nasal guard, functional military design, dark metal",
          "dark iron, nasal guard, simple military"),
    101: ("a tall tower guard helm of polished steel with cheek guards and a white plume",
          "polished steel, cheek guards, white plume"),
    102: ("a dwarven mask-helm of dark iron covering the full face, with geometric eye slits and a braided beard guard",
          "dark iron, full face cover, beard guard"),
    103: ("a magnificent mithril helm with a winged crest, gleaming silver-white, elven craftsmanship",
          "gleaming mithril, winged crest, elven design"),
    420: ("a battered rusted helm with dents and corrosion, barely functional",
          "rusted iron, dented, corroded"),
    # === CROWNS (tval=33) ===
    20: ("a massive iron crown of dark metal with sharp spikes, heavy and oppressive, symbol of dark authority",
         "dark iron, sharp spikes, heavy, oppressive"),
    104: ("an ornate golden crown set with gemstones, radiating authority and ancient power",
          "gold, gemstones, radiant authority"),
    # === SHIELDS (tval=34) ===
    43: ("a small round buckler of dark wood with an iron rim and central boss, quick and maneuverable",
         "dark wood, iron rim, central boss"),
    44: ("a large rectangular tower shield of iron-banded oak with a white tree painted on the face",
         "iron-banded oak, white tree emblem, large"),
    46: ("a gleaming mithril shield, impossibly light yet indestructible, with flowing elven engravings",
         "gleaming mithril, elven engravings, impossibly light"),
    422: ("a shattered broken shield, split down the middle, iron bands twisted and wood splintered",
          "split wood, twisted iron, broken"),
    # === CLOAKS (tval=35) ===
    106: ("a simple traveler's cloak of brown wool with a tarnished bronze clasp",
          "brown wool, bronze clasp, travel-worn"),
    107: ("a dark shadow cloak that seems to absorb light, edges blurring into darkness, silver clasp",
          "shadow-dark, light-absorbing, blurred edges"),
    108: ("a fearsome wolf-skin cloak with the wolf's head as a hood, thick gray fur, primal and wild",
          "gray wolf fur, wolf head hood, primal"),
    109: ("a sinister bat-fell cloak of dark leathery material resembling bat wings, with a bone clasp",
          "dark leathery bat-wing, bone clasp, sinister"),
    418: ("a nightshade cloak of deep purple-black fabric that seems to shimmer with toxic iridescence",
          "purple-black fabric, toxic iridescence, shimmer"),
    # === BOOTS (tval=30) ===
    122: ("a pair of sturdy traveler's boots of worn brown leather, practical and comfortable",
          "worn brown leather, practical, comfortable"),
    123: ("a pair of iron greaves and sabatons, heavy dark metal leg armor with leather straps",
          "dark iron, heavy metal, leather straps"),
    124: ("a pair of gleaming mithril greaves, silvery leg armor impossibly light and strong",
          "gleaming mithril, silver, impossibly light"),
    421: ("a pair of worn and battered boots, scuffed leather, nearly falling apart",
          "worn scuffed leather, battered, falling apart"),
    # === GLOVES (tval=31) ===
    125: ("a pair of simple leather gloves, supple dark brown leather with reinforced palms",
          "dark brown leather, reinforced palms"),
    126: ("a pair of iron gauntlets with articulated fingers, heavy dark metal with leather padding",
          "dark iron, articulated fingers, leather padding"),
    127: ("a set of gleaming mithril gauntlets, silvery metal perfectly fitted with intricate finger joints",
          "gleaming mithril, intricate joints, silver"),
    # === LIGHTS (tval=39) ===
    21: ("a radiant elven light crystal floating and glowing with soft white starlight, ethereal and beautiful",
         "soft white starlight, crystal, ethereal glow"),
    128: ("a simple wooden torch, oiled cloth wrapped around a sturdy branch, flickering flame",
          "wooden shaft, oiled cloth, orange flame"),
    129: ("a brass lantern with glass panes and a warm yellow flame inside, handle on top, well-crafted",
          "brass body, glass panes, warm yellow flame"),
    130: ("an ornate jewel-lamp with a faceted crystal that radiates steady white magical light",
          "faceted crystal, white magical light, ornate setting"),
    131: ("a star-glass phial of Galadriel glowing with the captured light of Earendil's star, brilliantly white",
          "crystal phial, brilliant white starlight, sacred glow"),
    411: ("a mallorn torch of golden mallorn wood that burns with a steady silver-white flame, elven-made",
          "golden mallorn wood, silver-white flame, elven"),
    # === CHESTS (tval=7) ===
    372: ("a small wooden treasure chest with iron hinges and a simple latch, dark oak",
          "dark oak, iron hinges, simple latch"),
    373: ("a small steel chest with heavy rivets and a sturdy lock, polished dark metal",
          "dark polished steel, heavy rivets, sturdy lock"),
    374: ("a small chest encrusted with jewels and gold filigree, precious and ornate",
          "gold filigree, jewel-encrusted, ornate"),
    375: ("a large wooden chest bound with iron bands, heavy oak with a complex lock",
          "heavy oak, iron bands, large, complex lock"),
    376: ("a large steel chest reinforced with thick iron plates and multiple locks",
          "thick steel plates, multiple locks, large"),
    377: ("a large jewelled chest of exquisite craftsmanship, gold trim and precious gems embedded in the lid",
          "exquisite gold, precious gems, large, ornate"),
    378: ("a finely wrapped present with dark ribbon and ornate paper, mysterious and enticing",
          "ornate wrapping, dark ribbon, mysterious"),
    # === SKELETONS (tval=3) ===
    40: ("a pile of orc bones, a crude orcish skull with jutting tusks among scattered dark bones",
         "dark bones, orcish skull, tusks, scattered"),
    41: ("a pile of ancient weathered bones with a clean skull resting among them, old and dry",
         "white skull, scattered bones, human remains"),
    42: ("a pile of elven bones, slender elegant skull among delicate bones with a faint ethereal shimmer",
         "slender bones, elegant skull, ethereal shimmer"),
    # === MITHRIL (tval=4) ===
    410: ("a gleaming chunk of raw mithril ore, silver-white with an inner radiance, the most precious metal in Middle-earth",
          "silver-white ore, inner radiance, precious"),
    # === OILS (tval=77) ===
    402: ("a small dark flask of lamp oil, glass bottle with a narrow neck and cork stopper, amber liquid inside",
          "dark glass, amber oil, cork stopper"),
    417: ("a small vial of concentrated torch oil, thick dark glass with a drip nozzle, viscous golden liquid",
          "thick dark glass, golden oil, drip nozzle"),

    # === POTIONS (tval=75) - Each gets a distinct color ===
    313: ("a crystal flask of miruvor, the cordial of Imladris, filled with radiant golden liquid that seems to glow with warmth",
          "crystal flask, radiant golden liquid, warm glow"),
    315: ("a crude dark bottle of orcish liquor, thick cloudy green liquid sloshing inside, cork sealed with wax",
          "crude dark bottle, cloudy green liquid, wax seal"),
    316: ("a delicate elven vial of Esgalduin water, clear blue liquid that shimmers like a mountain stream",
          "delicate glass, shimmering blue liquid, elven crafted"),
    317: ("a smooth glass flask of clarity potion, crystal-clear luminous white liquid",
          "smooth glass, luminous white liquid, clear"),
    318: ("a ornate flask of the Cordial of the Wise, deep sapphire blue liquid with swirling silver motes",
          "ornate flask, sapphire blue liquid, silver motes"),
    319: ("a slim vial of voice-restoring potion, soft lavender liquid that hums faintly when shaken",
          "slim vial, soft lavender liquid, faint hum"),
    320: ("a triangular flask of true sight potion, pale amber liquid with a floating eye-shaped inclusion",
          "triangular flask, amber liquid, eye inclusion"),
    321: ("a small green glass bottle of antidote, bright emerald green liquid with herbal sediment",
          "green glass, emerald liquid, herbal sediment"),
    322: ("a narrow flask of quickness potion, quicksilver-like liquid that shifts and moves on its own",
          "narrow flask, quicksilver liquid, self-moving"),
    323: ("a sturdy flask of elemental resistance potion, swirling liquid shifting between red orange blue and white",
          "sturdy flask, color-shifting liquid, elemental"),
    324: ("a dark smoky flask of shadow potion, inky black liquid with purple depth, absorbs light",
          "dark flask, inky black liquid, light-absorbing"),
    327: ("a reinforced flask of Draught of Might, thick crimson liquid like concentrated blood, radiating power",
          "reinforced flask, thick crimson liquid, powerful"),
    328: ("a slender flask of nimble-wine, pale pink effervescent liquid with tiny bubbles rising",
          "slender flask, pale pink, effervescent bubbles"),
    329: ("a squat flask of hardy-brew, thick dark brown liquid like stout ale, heavy and substantial",
          "squat flask, dark brown liquid, heavy and thick"),
    330: ("a luminous flask of starlight elixir, liquid that literally glows with captured starlight, white-silver",
          "luminous flask, starlight glow, white-silver"),
    343: ("a murky flask of slowness poison, thick gray sludge-like liquid with a skull etched on the glass",
          "murky flask, gray sludge, skull marking"),
    344: ("a flask of poison, sickly yellow-green liquid with dark sediment at the bottom",
          "sickly yellow-green liquid, dark sediment"),
    345: ("a flask of blinding potion, pure stark white opaque liquid that reflects all light",
          "white opaque liquid, blinding reflections"),
    346: ("a flask of confusion potion, constantly swirling multi-colored liquid that never settles",
          "multi-colored swirling liquid, chaotic"),
    348: ("a flask of awkwardness, murky orange liquid with lumpy consistency",
          "murky orange, lumpy consistency"),
    350: ("a flask of disconnection, static-filled clear liquid with tiny lightning arcs visible inside",
          "clear liquid, static arcs, disconnecting"),

    # === WANDS (tval=56) ===
    220: ("a slender wand of frost, pale blue-white wood tipped with an ice crystal, frost mist curling from the tip",
          "pale blue wood, ice crystal tip, frost mist"),
    221: ("a wand of fire, dark reddish wood tipped with a flickering ember crystal, warm glow",
          "red-dark wood, ember crystal, warm glow"),
    222: ("a wand of slowing, gray wood tipped with a dull amber crystal that pulses slowly",
          "gray wood, amber crystal, slow pulse"),
    223: ("a wand of light, bright white wood tipped with a radiant clear crystal, steady white glow",
          "white wood, clear crystal, bright glow"),
    224: ("a wand of fear, twisted black wood tipped with a dark purple crystal, shadowy aura",
          "twisted black wood, purple crystal, shadow aura"),
    225: ("a wand of sleep, smooth lavender wood tipped with a softly pulsing blue crystal",
          "lavender wood, soft blue crystal, gentle pulse"),

    # === HORNS (tval=66) ===
    240: ("a war horn carved from dark bone, etched with runes of terror, a cruel instrument of fear",
          "dark bone, terror runes, cruel design"),
    241: ("a great bronze war horn with silver bands, resonating with thunderous power",
          "bronze body, silver bands, thunderous"),
    242: ("a horn of force carved from pale ivory with iron banding, concussive power",
          "pale ivory, iron bands, concussive"),
    243: ("a horn of blasting, dark red metal with gold trim, devastating sound waves visible around it",
          "dark red metal, gold trim, sound waves"),
    250: ("a horn of challenge, ornate silver with a lion's head bell, commanding and regal",
          "ornate silver, lion head bell, regal"),
    251: ("a delicate flute carved from pale wood with silver keys, enchanting fairy music",
          "pale wood, silver keys, enchanting, delicate"),

    # === SPECIAL BROKEN ITEMS ===
    495: ("broken strange jewelry of alien dark metal twisted into an unnatural ring shape, faint dark energy",
          "twisted dark metal, unnatural shape, dark energy"),

    # === HERBS/FOOD (tval=80) - Each gets distinct appearance ===
    380: ("a cluster of dark red mushrooms with an aggressive veined texture, orc-rage mushrooms, dangerous",
          "dark red mushrooms, veined, aggressive"),
    381: ("a small wrapped portion of waymeal, pale travel bread wrapped in wax cloth, nutritious",
          "pale bread, wax cloth wrap, travel food"),
    382: ("a sprig of terror herb, dark purple-black leaves that seem to tremble and shift, unsettling",
          "dark purple-black leaves, trembling, unsettling"),
    383: ("a bundle of healer's herbs, fresh bright green leaves tied with twine, fragrant and soothing",
          "bright green leaves, twine bundle, fragrant"),
    384: ("a pouch of restoration herbs, golden dried leaves and small berries, wrapped in cloth",
          "golden dried leaves, small berries, cloth pouch"),
    385: ("a withered emptiness herb, desiccated gray-white leaves that crumble at a touch",
          "desiccated gray leaves, crumbling, withered"),
    386: ("a luminous vision herb, iridescent purple-blue petals that seem to show tiny images within",
          "iridescent purple-blue petals, visions within"),
    387: ("a swirling entrancement herb, hypnotic spiral-patterned leaves of green and gold",
          "spiral-patterned leaves, green and gold, hypnotic"),
    388: ("a drooping weakness herb, limp pale yellow leaves that drain energy from the air around them",
          "limp pale yellow leaves, draining aura"),
    389: ("a sickly sickness herb, mottled brown and green leaves covered in tiny dark spots",
          "mottled brown-green, dark spots, sickly"),
    390: ("a sacred sprig of athelas, silver-green leaves with a sweet fragrance, king's foil, healing herb of the Dunedain",
          "silver-green leaves, sweet fragrance, sacred healing"),
    399: ("a piece of dry travel bread, dense brown bread wrapped in cloth, sustaining but plain",
          "dense brown bread, cloth wrapping, plain"),
    400: ("a strip of dried meat, dark brown jerky tied with twine, tough but nutritious",
          "dark brown jerky, twine-tied, tough"),
    401: ("a fragment of golden lembas, elven waybread wrapped in a mallorn leaf, glowing faintly",
          "golden waybread, mallorn leaf, faint glow"),
    403: ("a cake of cram, dense pale dwarven travel bread in a wax-paper wrapping",
          "pale dense cake, wax-paper, dwarven"),
    404: ("a pouch of pipe-weed, dried brown-green leaf in a small leather pouch, aromatic",
          "dried brown-green leaf, leather pouch, aromatic"),
    412: ("a bundle of concentrated healer's herbs, vivid green leaves tightly compressed, potent",
          "vivid green, tightly compressed, potent"),
    413: ("a sprig of potent athelas, larger and more luminous than common athelas, deeply fragrant",
          "luminous silver-green, deeply fragrant, potent"),
    414: ("a packet of concentrated waymeal, dense golden travel food in oiled wrapping",
          "dense golden meal, oiled wrapping, concentrated"),
    415: ("a potent orc-rage mushroom, large dark crimson with pulsing veins, dangerously powerful",
          "large dark crimson, pulsing veins, dangerous"),
    416: ("a clump of phosphorescent moss, softly glowing blue-green bioluminescent plant matter",
          "glowing blue-green, bioluminescent, soft light"),

    # === SCROLLS (tval=55) ===
    191: ("a scroll of imprisonment, dark iron-colored parchment with binding runes glowing red",
          "dark parchment, red binding runes"),
    192: ("a scroll of freedom, bright white parchment with golden liberating runes",
          "bright parchment, golden liberation runes"),
    193: ("a scroll of light, pale golden parchment radiating warm white light from sun-runes",
          "golden parchment, sun runes, radiating light"),
    195: ("a scroll of sanctity, pristine white parchment with silver holy runes and a wax seal",
          "pristine white, silver holy runes, wax seal"),
    196: ("a scroll of understanding, cream parchment with blue scholarly runes and margin notes",
          "cream parchment, blue runes, scholarly"),
    197: ("a scroll of revelations, aged dark parchment with glowing violet mystical runes that shift",
          "aged dark parchment, violet shifting runes"),
    198: ("a scroll of treasures, gold-edged parchment with amber runes pointing to hidden wealth",
          "gold-edged parchment, amber runes"),
    199: ("a scroll of foes, blood-red parchment with dark runes revealing enemy positions",
          "blood-red parchment, dark revealing runes"),
    200: ("a scroll of slumber, pale lavender parchment with softly pulsing indigo sleep runes",
          "lavender parchment, indigo sleep runes"),
    201: ("a scroll of majesty, royal purple parchment with gold commanding runes",
          "royal purple, gold commanding runes"),
    202: ("a scroll of self knowledge, mirror-silver parchment with reflective runes",
          "mirror-silver parchment, reflective runes"),
    203: ("a scroll of warding, dark blue parchment with bright white protective runes forming a circle",
          "dark blue, white protective circle runes"),
    204: ("a scroll of dismay, charcoal gray parchment with sickly green demoralizing runes",
          "charcoal gray, sickly green runes"),
    206: ("a scroll of recharging, copper-toned parchment with electric blue runes crackling with energy",
          "copper parchment, electric blue, crackling"),
    210: ("a scroll of summoning, dark violet parchment with swirling golden portal runes",
          "dark violet, golden portal runes, swirling"),
    211: ("a scroll of shadows, nearly black parchment with barely visible dark purple shadow runes",
          "near-black, barely visible shadow runes"),

    # === RINGS (tval=45) - Named rings get unique descriptions ===
    1: ("a serpentine ring of intertwining silver snakes with tiny emerald eyes",
        "silver snakes, emerald eyes, serpentine"),
    150: ("a ring of secrets, dark metal band with a hidden compartment, subtle and mysterious",
          "dark metal, hidden compartment, subtle"),
    151: ("a ring of Ered Luin, blue-steel dwarven ring with mountain rune engravings",
          "blue-steel, mountain runes, dwarven"),
    152: ("a ring of evasion, thin mithril band that seems to shimmer and blur, hard to focus on",
          "thin mithril, shimmering blur, elusive"),
    153: ("a ring of protection, thick gold band with a bright white gemstone ward",
          "thick gold, white gemstone, protective ward"),
    154: ("a ring of strength, heavy iron band with a blood-red garnet, pulsing with power",
          "heavy iron, blood-red garnet, power pulse"),
    155: ("a ring of dexterity, slim silver band with a sparkling yellow citrine, nimble and quick",
          "slim silver, yellow citrine, nimble"),
    156: ("a ring of frost, pale blue crystalline band with frost patterns, cold to the touch",
          "pale blue crystal, frost patterns, cold"),
    157: ("a ring of warmth, burnished copper band with an orange fire opal, radiating gentle heat",
          "burnished copper, fire opal, gentle heat"),
    158: ("a ring of accuracy, steel band with a clear diamond that focuses light to a sharp point",
          "steel band, clear diamond, focused light"),
    159: ("a ring of free action, braided gold and silver band, light and unrestricted",
          "braided gold-silver, light, unrestricted"),
    160: ("a ring of cowardice, tarnished dark band with a sickly yellow stone, cursed",
          "tarnished dark metal, sickly yellow, cursed"),
    161: ("a ring of the Shadow's Vanguard, jet black band with a burning red eye sigil",
          "jet black, burning red eye, dark lord's sigil"),
    162: ("a ring of Venom's End, bright green band with an emerald antidote gemstone",
          "bright green band, emerald, antidote"),
    171: ("a ring of the Laiquendi, living green band of intertwined vines with tiny white flowers",
          "living green vines, white flowers, elven"),

    # === AMULETS (tval=40) - Named amulets ===
    4: ("a smooth pearl pendant on a fine silver chain, soft lunar glow",
        "pearl, silver chain, lunar glow"),
    5: ("an ornate jewel pendant with a large multi-faceted gem on a gold chain",
        "large faceted gem, gold chain, ornate"),
    6: ("an elegant necklace of linked silver and gold, with small gemstones spaced along its length",
        "silver-gold links, small gemstones, elegant"),
    132: ("an amulet of last chances, dark iron pendant with a cracked hourglass design, final hope",
          "dark iron, cracked hourglass, desperate"),
    133: ("an amulet of constitution, sturdy bronze pendant with a mountain-heart ruby, enduring",
          "bronze, mountain-heart ruby, enduring"),
    134: ("an amulet of grace, delicate mithril pendant with a star sapphire, divine favor",
          "mithril, star sapphire, divine grace"),
    135: ("an amulet of regeneration, living green pendant with an amber life-force gem pulsing",
          "living green, amber life gem, pulsing"),
    136: ("an amulet of preservation, golden pendant with a clear crystal sphere, protective stasis",
          "golden, clear crystal sphere, preservation"),
    137: ("an amulet of the Blessed Realm, radiant white pendant with Valinor starlight trapped within",
          "radiant white, Valinor starlight, blessed"),
    138: ("an amulet of haunted dreams, dark silver pendant with a smoky black onyx that shows shifting nightmares",
          "dark silver, smoky onyx, nightmare visions"),
    139: ("an amulet of the Vigilant Eye, dark pendant with a lidless eye design in red and gold",
          "dark pendant, red-gold eye design, watching"),

    # === DOCUMENT/LORE ITEMS (tval=2) ===
    # Generic notes (one sprite for all 40)
    451: ("a worn piece of parchment with scrawled handwriting, old dungeon notes left by a previous explorer",
          "aged parchment, scrawled ink, worn edges"),
    # Thráin's Memories (one sprite for all 8)
    500: ("a glowing golden memory crystal in the shape of a dwarf rune, containing Thráin's trapped memories",
          "golden crystal, dwarf rune shape, memory glow"),
    # Shadow Fragments (one sprite for all 6)
    510: ("a shard of crystallized shadow, dark purple-black with swirling void energy trapped inside",
          "dark purple-black crystal, swirling void, shadow"),
    # Ancient Glyphs (one sprite for all 7)
    520: ("a stone tablet fragment with an ancient glowing runic glyph carved deep into the surface",
          "stone fragment, glowing rune, ancient carving"),
    # Palantír Shards (one sprite for all 4)
    530: ("a shard of a broken palantír, dark crystal reflecting impossible distant scenes within",
          "dark crystal shard, impossible reflections, seeing"),
    # Misc collectibles
    540: ("a silver mithril brooch shaped like a dwarf axe, ornate and valuable",
          "silver mithril, axe shape, ornate"),
    541: ("an ancient gold coin stamped with Thrór's face, valuable dwarven treasure",
          "ancient gold coin, Thrór's face, dwarven"),
    542: ("a gemstone with swirling fire trapped within, touched by dragon flame, warm to hold",
          "swirling fire gem, dragon flame, warm"),
    543: ("a torn page from an ancient dwarven chronicle, runic script on aged vellum",
          "torn vellum page, runic script, ancient"),
    544: ("a fragment of carved stone with part of a date inscription, related to Durin's Day",
          "carved stone fragment, date inscription, dwarven"),
    # Prisoner/Orc/History documents
    550: ("a crumpled letter written in a shaking hand, a prisoner's desperate account, stained with tears",
          "crumpled letter, shaking handwriting, tear-stained"),
    552: ("a crude orc report written in dark ink on rough hide, military orders in black speech",
          "rough hide scroll, dark ink, orcish script"),
    554: ("a fragment of historical text on fine vellum with illuminated borders, scholarly and ancient",
          "fine vellum, illuminated borders, scholarly"),
    556: ("a disturbing report of a necromancer sighting, written urgently on fresh parchment with a wax seal",
          "fresh parchment, urgent writing, wax seal"),
}


# ============================================================================
# AUTO-GENERATION for items without custom descriptions
# ============================================================================

def clean_name(name: str) -> str:
    """Remove Angband formatting from item names."""
    name = name.replace("&", "").replace("~", "").strip()
    name = re.sub(r"\s+", " ", name)
    return name


def detect_material(name: str) -> str:
    """Detect material/quality from item name for prompt generation."""
    name_lower = name.lower()
    if "mithril" in name_lower:
        return "gleaming mithril"
    if "iron" in name_lower:
        return "dark iron"
    if "steel" in name_lower:
        return "polished steel"
    if "dwarven" in name_lower or "dwarf" in name_lower:
        return "heavy dwarven-forged iron"
    if "elven" in name_lower or "silvan" in name_lower:
        return "elegant elven-crafted"
    if "orc" in name_lower:
        return "crude orcish dark iron"
    if "leather" in name_lower:
        return "supple dark leather"
    if "wooden" in name_lower or "wood" in name_lower or "oak" in name_lower:
        return "dark carved wood"
    if "brass" in name_lower:
        return "burnished brass"
    if "gold" in name_lower:
        return "ornate gold"
    if "silver" in name_lower:
        return "fine silver"
    if "crystal" in name_lower or "jewel" in name_lower:
        return "faceted crystal"
    return "sturdy"


def auto_generate_desc(item_id: int, name: str, tval: int) -> Tuple[str, str]:
    """Auto-generate visual description from item name and category."""
    clean = clean_name(name)
    material = detect_material(name)
    category = CATEGORIES.get(tval)

    if not category:
        return (f"a mysterious fantasy item: {clean}, with magical energy", "magical, mysterious, fantasy")

    cat_name = category["name"]

    # Build description based on category
    if cat_name == "ring" and "Ring" in name:
        return (f"a {material} fantasy ring, simple band design", f"{material}, simple band")
    elif cat_name == "amulet" and "Amulet" in name:
        return (f"a {material} amulet pendant on a chain", f"{material}, pendant, chain")
    elif cat_name == "document":
        return (f"a piece of aged parchment document with writing, {clean}", "aged parchment, writing, worn")
    else:
        return (f"a {material} {clean.lower()} from Middle-earth, detailed fantasy design",
                f"{material}, detailed, fantasy crafted")


# ============================================================================
# PARSE OBJECT.TXT AND BUILD ITEM REGISTRY
# ============================================================================

def parse_items() -> Dict[int, Dict]:
    """Parse object.txt and build complete item registry with visual descriptions."""
    items = {}
    current = None
    object_path = DATA_DIR / "object.txt"

    if not object_path.exists():
        print(f"ERROR: {object_path} not found")
        return {}

    with open(object_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("N:"):
                parts = line[2:].split(":", 1)
                item_id = int(parts[0])
                name = parts[1] if len(parts) > 1 else ""
                current = {"id": item_id, "name": name}
                items[item_id] = current
            elif line.startswith("G:") and current:
                parts = line[2:].split(":")
                current["char"] = parts[0] if parts else ""
                current["color"] = parts[1] if len(parts) > 1 else ""
            elif line.startswith("I:") and current:
                parts = line[2:].split(":")
                current["tval"] = int(parts[0]) if parts else 0

    # Build dedup map: (name, tval) -> list of IDs
    dedup = defaultdict(list)
    for item_id, item in items.items():
        key = (item["name"], item.get("tval", 0))
        dedup[key].append(item_id)

    # Assign visual descriptions and dedup groups
    for (name, tval), ids in dedup.items():
        canonical_id = ids[0]  # First ID is the canonical one

        # Check for custom description
        custom_id = None
        for cid in ids:
            if cid in CUSTOM_DESCS:
                custom_id = cid
                break

        if custom_id is not None:
            desc, colors = CUSTOM_DESCS[custom_id]
        else:
            desc, colors = auto_generate_desc(canonical_id, name, tval)

        for item_id in ids:
            items[item_id]["visual_desc"] = desc
            items[item_id]["colors"] = colors
            items[item_id]["canonical_id"] = canonical_id
            items[item_id]["is_duplicate"] = (item_id != canonical_id)
            items[item_id]["duplicate_ids"] = ids if len(ids) > 1 else []

    return items


# ============================================================================
# DALL-E PROMPT GENERATION
# ============================================================================

def get_item_prompt(item: Dict) -> str:
    """Build a DALL-E 3 prompt for an item sprite."""
    tval = item.get("tval", 0)
    category = CATEGORIES.get(tval, {})
    pose = category.get("pose", "A single fantasy item centered in the frame")

    prompt = (
        f"On a completely solid flat hot magenta background (hex FF00FF), "
        f"a vivid fantasy illustration of {item['visual_desc']}. "
        f"{pose}. "
        f"Vivid striking colors: {item['colors']}. "
        f"Strong readable silhouette against the magenta. "
        f"The background must be entirely uniform solid magenta with absolutely nothing else. "
        f"A single item only, no hands, no characters, no other elements. "
        f"Painted in a clean illustrative style."
    )
    return prompt


# ============================================================================
# IMAGE PROCESSING (shared with monster_gen.py)
# ============================================================================

def auto_crop_and_resize(img: Image.Image, target_size: int = TILE_SIZE) -> Image.Image:
    """Detect content area, crop out white/light borders, resize to target_size."""
    img_array = np.array(img.convert("RGBA"))
    h, w = img_array.shape[:2]

    r, g, b = img_array[:, :, 0], img_array[:, :, 1], img_array[:, :, 2]
    brightness = (r.astype(int) + g.astype(int) + b.astype(int)) / 3
    content_mask = brightness < WHITE_THRESHOLD

    rows_with_content = np.any(content_mask, axis=1)
    cols_with_content = np.any(content_mask, axis=0)

    if not np.any(rows_with_content) or not np.any(cols_with_content):
        return img.resize((target_size, target_size), Image.Resampling.NEAREST)

    row_start = np.argmax(rows_with_content)
    row_end = h - np.argmax(rows_with_content[::-1])
    col_start = np.argmax(cols_with_content)
    col_end = w - np.argmax(cols_with_content[::-1])

    border_top = row_start
    border_bottom = h - row_end
    border_left = col_start
    border_right = w - col_end

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

        if crop_w != crop_h:
            max_dim = max(crop_w, crop_h)
            square = Image.new("RGBA", (max_dim, max_dim), (255, 0, 255, 255))
            paste_x = (max_dim - crop_w) // 2
            paste_y = (max_dim - crop_h) // 2
            square.paste(cropped, (paste_x, paste_y))
            cropped = square

        return cropped.resize((target_size, target_size), Image.Resampling.NEAREST)
    else:
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
    """Validate a generated item tile."""
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


# ============================================================================
# GENERATOR CLASS
# ============================================================================

class ItemGenerator:
    def __init__(self, api_key: str):
        self.client = OpenAI(api_key=api_key)
        self.output_dir = OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.progress = self._load_progress()
        self.items = parse_items()

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

    def _sprite_key(self, item_id: int) -> str:
        return f"item_{item_id}"

    def get_unique_items(self) -> Dict[int, Dict]:
        """Get only canonical (non-duplicate) items that need generation."""
        unique = {}
        for item_id, item in self.items.items():
            if not item.get("is_duplicate", False):
                unique[item_id] = item
        return unique

    def generate_single(self, item_id: int, retry: int = 0) -> Optional[Path]:
        """Generate a single item sprite."""
        if item_id not in self.items:
            print(f"  ERROR: Unknown item ID {item_id}")
            return None

        item = self.items[item_id]

        # If this is a duplicate, use the canonical sprite
        canonical = item.get("canonical_id", item_id)
        if canonical != item_id:
            canonical_key = self._sprite_key(canonical)
            if canonical_key in self.progress["sprites"]:
                info = self.progress["sprites"][canonical_key]
                if info.get("status") == "completed":
                    print(f"  DEDUP: item_{item_id} -> {canonical_key} ({clean_name(item['name'])})")
                    return Path(info["path"])
            # Generate the canonical instead
            return self.generate_single(canonical, retry)

        key = self._sprite_key(item_id)

        # Skip if already completed
        if key in self.progress["sprites"]:
            info = self.progress["sprites"][key]
            if info.get("status") == "completed":
                existing = Path(info["path"])
                if existing.exists():
                    print(f"  SKIP: {key} ({clean_name(item['name'])}) already completed")
                    return existing

        prompt = get_item_prompt(item)
        tval = item.get("tval", 0)
        cat = CATEGORIES.get(tval, {})
        cat_name = cat.get("name", "unknown")
        label = f"[{cat_name}] {clean_name(item['name'])}"

        print(f"\n{'=' * 60}")
        print(f"Generating: {label} (ID: {item_id})")
        print(f"Key: {key} | Category: {cat_name} | tval: {tval}")
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
                    return self.generate_single(item_id, retry + 1)

            # Save light variant
            cat_dir = self.output_dir / cat_name
            cat_dir.mkdir(exist_ok=True)
            light_path = cat_dir / f"{key}_light.png"
            img_64.save(light_path)
            print(f"  Saved light: {light_path.name}")

            # Generate and save dark variant
            img_dark = generate_dark_variant(img_64)
            dark_path = cat_dir / f"{key}_dark.png"
            img_dark.save(dark_path)
            print(f"  Saved dark: {dark_path.name}")

            # Update progress
            self.progress["sprites"][key] = {
                "status": "completed",
                "path": str(light_path),
                "dark_path": str(dark_path),
                "item_id": item_id,
                "name": clean_name(item["name"]),
                "tval": tval,
                "category": cat_name,
                "valid": is_valid,
                "validation_msg": reason,
                "completed_at": datetime.now().isoformat(),
            }

            # Also record duplicates pointing to this sprite
            for dup_id in item.get("duplicate_ids", []):
                if dup_id != item_id:
                    dup_key = self._sprite_key(dup_id)
                    self.progress["sprites"][dup_key] = {
                        "status": "completed",
                        "path": str(light_path),
                        "dark_path": str(dark_path),
                        "item_id": dup_id,
                        "canonical_id": item_id,
                        "name": clean_name(item["name"]),
                        "tval": tval,
                        "category": cat_name,
                        "is_duplicate": True,
                        "completed_at": datetime.now().isoformat(),
                    }

            self._save_progress()
            return light_path

        except Exception as e:
            print(f"  ERROR: {e}")
            if retry < MAX_RETRIES:
                print(f"  Retrying ({retry + 1}/{MAX_RETRIES})...")
                time.sleep(RATE_LIMIT_DELAY * 2)
                return self.generate_single(item_id, retry + 1)

            self.progress["sprites"][key] = {
                "status": "failed",
                "error": str(e),
                "item_id": item_id,
                "name": clean_name(item["name"]),
                "failed_at": datetime.now().isoformat(),
            }
            self._save_progress()
            return None

    def generate_category(self, category_name: str) -> Dict[str, bool]:
        """Generate all items in a specific category."""
        # Find tval for category name
        target_tval = None
        for tval, cat in CATEGORIES.items():
            if cat["name"] == category_name:
                target_tval = tval
                break

        if target_tval is None:
            print(f"Unknown category: {category_name}")
            print(f"Available: {', '.join(c['name'] for c in CATEGORIES.values())}")
            return {}

        unique = self.get_unique_items()
        cat_items = {iid: i for iid, i in unique.items() if i.get("tval") == target_tval}

        results = {}
        cat = CATEGORIES[target_tval]
        print(f"\n{'=' * 60}")
        print(f"CATEGORY: {cat['name'].upper()} (tval={target_tval})")
        print(f"Items: {len(cat_items)} unique | Est. cost: ${len(cat_items) * COST_PER_IMAGE:.2f}")
        print(f"{'=' * 60}")

        for item_id in sorted(cat_items.keys()):
            key = self._sprite_key(item_id)
            path = self.generate_single(item_id)
            results[key] = path is not None
            time.sleep(RATE_LIMIT_DELAY)

        return results

    def generate_test(self) -> Dict[str, bool]:
        """Generate 1 item per category for review."""
        unique = self.get_unique_items()
        seen_cats = set()
        test_items = {}

        for item_id in sorted(unique.keys()):
            tval = unique[item_id].get("tval", 0)
            cat = CATEGORIES.get(tval, {}).get("name", "unknown")
            if cat not in seen_cats:
                seen_cats.add(cat)
                test_items[item_id] = unique[item_id]

        results = {}
        print(f"\n{'=' * 60}")
        print(f"ITEM TEST GENERATION - 1 per category ({len(test_items)} sprites)")
        print(f"{'=' * 60}")

        for item_id in sorted(test_items.keys()):
            key = self._sprite_key(item_id)
            path = self.generate_single(item_id)
            results[key] = path is not None
            time.sleep(RATE_LIMIT_DELAY)

        return results

    def generate_all(self) -> Dict[str, bool]:
        """Generate all unique item sprites."""
        unique = self.get_unique_items()

        results = {}
        print(f"\n{'=' * 60}")
        print(f"FULL ITEM GENERATION - {len(unique)} unique sprites ({len(self.items)} total items)")
        print(f"Est. cost: ${len(unique) * COST_PER_IMAGE:.2f}")
        print(f"{'=' * 60}")

        # Group by category for organized output
        by_cat = defaultdict(list)
        for item_id, item in unique.items():
            tval = item.get("tval", 0)
            cat_name = CATEGORIES.get(tval, {}).get("name", "unknown")
            by_cat[cat_name].append(item_id)

        for cat_name in sorted(by_cat.keys()):
            ids = sorted(by_cat[cat_name])
            print(f"\n--- {cat_name.upper()} ({len(ids)} items) ---")
            for item_id in ids:
                key = self._sprite_key(item_id)
                path = self.generate_single(item_id)
                results[key] = path is not None
                time.sleep(RATE_LIMIT_DELAY)

        print(f"\n{'=' * 60}")
        print(f"ALL ITEMS COMPLETE")
        self._print_summary(results)
        return results

    def generate_dark_variants_only(self):
        """Generate dark variants for all existing light sprites."""
        count = 0
        for key, info in self.progress["sprites"].items():
            if info.get("status") != "completed" or info.get("is_duplicate"):
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
            print(f"  Dark variant: {dark_path.name}")
        self._save_progress()
        print(f"Generated {count} dark variants")

    def print_status(self):
        """Print generation status."""
        unique = self.get_unique_items()
        by_cat = defaultdict(lambda: {"total": 0, "done": 0})

        for item_id, item in unique.items():
            tval = item.get("tval", 0)
            cat_name = CATEGORIES.get(tval, {}).get("name", "unknown")
            by_cat[cat_name]["total"] += 1
            key = self._sprite_key(item_id)
            if key in self.progress["sprites"] and self.progress["sprites"][key].get("status") == "completed":
                by_cat[cat_name]["done"] += 1

        total = sum(c["total"] for c in by_cat.values())
        done = sum(c["done"] for c in by_cat.values())

        print(f"\n{'=' * 60}")
        print(f"ITEM SPRITE GENERATION STATUS")
        print(f"{'=' * 60}")

        for cat_name in sorted(by_cat.keys()):
            info = by_cat[cat_name]
            pct = info["done"] / info["total"] if info["total"] > 0 else 0
            bar = "#" * int(pct * 20) + "-" * (20 - int(pct * 20))
            print(f"  {cat_name:<20s} [{bar}] {info['done']:3d}/{info['total']:3d}")

        print(f"\n  Total: {done}/{total} unique sprites ({len(self.items)} items with dedup)")
        print(f"  API calls: {self.progress.get('api_calls', 0)}")
        print(f"  Est. cost: ${self.progress.get('cost_total', 0):.2f}")
        print(f"  Output: {self.output_dir}")

    def list_items(self):
        """List all items by category."""
        unique = self.get_unique_items()
        by_cat = defaultdict(list)
        for item_id, item in unique.items():
            tval = item.get("tval", 0)
            cat_name = CATEGORIES.get(tval, {}).get("name", "unknown")
            by_cat[cat_name].append((item_id, item))

        for cat_name in sorted(by_cat.keys()):
            items_list = sorted(by_cat[cat_name])
            print(f"\n=== {cat_name.upper()} ({len(items_list)} items) ===")
            for item_id, item in items_list:
                name = clean_name(item["name"])
                dupes = item.get("duplicate_ids", [])
                dupe_str = f" [+{len(dupes)-1} dupes]" if len(dupes) > 1 else ""
                custom = " *" if item_id in CUSTOM_DESCS else ""
                print(f"  {item_id:4d}  {name:<35s}{dupe_str}{custom}")

    def _print_summary(self, results: Dict[str, bool], category: str = None):
        """Print generation summary."""
        success = sum(1 for v in results.values() if v)
        failed = sum(1 for v in results.values() if not v)
        total_cost = self.progress.get("cost_total", 0)
        total_calls = self.progress.get("api_calls", 0)

        print(f"\n  Results: {success} success, {failed} failed")
        print(f"  Total API calls: {total_calls}")
        print(f"  Total cost: ${total_cost:.2f}")


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Generate item sprites via DALL-E 3")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all", action="store_true", help="Generate all unique items")
    group.add_argument("--category", type=str, help="Generate one category")
    group.add_argument("--test", action="store_true", help="1 item per category")
    group.add_argument("--status", action="store_true", help="Show progress")
    group.add_argument("--single", type=int, help="Generate one item by ID")
    group.add_argument("--darken", action="store_true", help="Regenerate dark variants")
    group.add_argument("--list", action="store_true", help="List all items")

    args = parser.parse_args()

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key and not (args.status or args.list):
        print("ERROR: OPENAI_API_KEY not set")
        sys.exit(1)

    gen = ItemGenerator(api_key or "dummy")

    if args.status:
        gen.print_status()
    elif args.list:
        gen.list_items()
    elif args.test:
        gen.generate_test()
    elif args.all:
        gen.generate_all()
    elif args.category:
        gen.generate_category(args.category)
    elif args.single is not None:
        gen.generate_single(args.single)
    elif args.darken:
        gen.generate_dark_variants_only()


if __name__ == "__main__":
    main()
