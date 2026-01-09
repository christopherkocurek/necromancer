/* File: death.c */

/*
 * Death sequence animation and epitaph generation for The Necromancer.
 *
 * This file handles:
 * - Procedural epitaph generation based on player's run
 * - Death animation sequence (The Fall, Consumed, Epitaph, Tombstone)
 * - Stats recap screen ("Your Tale")
 *
 * Copyright (c) 2026 The Necromancer contributors
 */

#include "angband.h"

/*
 * Epitaph strings organized by condition and tone.
 * These are embedded directly rather than loaded from file for simplicity.
 */

/* Conditional epitaphs - checked first based on how player died/played */
static cptr epitaph_killed_by_sauron[] = {
    "Sauron remembers every face. He will forget this one.",
    "Stood before the Necromancer. Briefly.",
    "The Lord of the Tower does not suffer trespassers.",
    "Looked upon the Lidless Eye. It was the last thing he saw.",
    "The Necromancer's power brooks no resistance.",
    NULL
};

static cptr epitaph_killed_by_nazgul[] = {
    "The wraith's blade was cold. Then nothing was.",
    "Nine there were. One was enough.",
    "Felt the Black Breath. Then felt nothing.",
    "The Shadow of the East claims another.",
    "No mortal can stand before the Nine.",
    NULL
};

static cptr epitaph_died_deep[] = {
    "Reached the bottom. It was waiting.",
    "So close to Thrain. So far from escape.",
    "The Pits of Despair earned their name.",
    "The deeper you go, the darker it gets.",
    "Found what lies beneath. It found him too.",
    NULL
};

static cptr epitaph_died_shallow[] = {
    "Barely past the threshold.",
    "Mirkwood claimed another.",
    "The forest was hungry today.",
    "A brief candle in an endless dark.",
    "The journey ended before it began.",
    NULL
};

static cptr epitaph_high_stealth[] = {
    "Moved like a shadow. Died like everyone else.",
    "Unseen until the end.",
    "The perfect ghost, finally caught.",
    "Silent footsteps. Silenced forever.",
    "Avoided a hundred. Missed one.",
    NULL
};

static cptr epitaph_high_kills[] = {
    "Left a trail of bodies. Added one more.",
    "Warrior's heart. Warrior's death.",
    "Killed many. Not enough.",
    "The blade that slew a hundred found its match.",
    "Fought like a demon. Died like a man.",
    NULL
};

static cptr epitaph_found_thrain[] = {
    "Held the Key. Couldn't use it.",
    "Thrain's last hope died with him.",
    "So close to the Lonely Mountain.",
    "Found the lost king. Joined him in death.",
    "Thrain waits no longer.",
    NULL
};

static cptr epitaph_saw_sauron[] = {
    "Looked upon the Necromancer. A privilege and a curse.",
    "The Eye sees all. Including the end.",
    "Met the master of the Tower. Briefly.",
    "Glimpsed the Lidless Eye and lived. Then died.",
    "Sauron remembers every face.",
    NULL
};

static cptr epitaph_stole_ring[] = {
    "Held a Ring of Power. It was not enough.",
    "The Ring betrayed another bearer.",
    "Thrain's Ring found a new corpse to adorn.",
    "One Ring to bind him. Bound unto death.",
    "The Ring takes. It does not give.",
    NULL
};

static cptr epitaph_long_run[] = {
    "Survived longer than most. Still died.",
    "Ten thousand turns. One fatal mistake.",
    "Endurance counts for nothing in the end.",
    "The Tower is patient. It always wins.",
    "Outlasted many. Outlasted by one.",
    NULL
};

static cptr epitaph_short_run[] = {
    "Blinked and missed it.",
    "The Tower makes quick work of the unwary.",
    "A brief candle in an endless dark.",
    "Hardly worth noting.",
    "In and out. Mostly out.",
    NULL
};

static cptr epitaph_pacifist[] = {
    "Killed nothing. Died anyway.",
    "Mercy is not rewarded here.",
    "The peaceful path ends the same.",
    "Raised no blade. Still fell.",
    "Gentle soul. Gentle death.",
    NULL
};

/* Generic epitaphs by tone - used when no conditions match */
static cptr epitaph_laconic[] = {
    "He came. He saw. He died.",
    "Not deep enough.",
    "The shadows were patient.",
    "One door too many.",
    "Should have run.",
    "Happens to everyone.",
    "So it goes.",
    "Next.",
    "Expected better.",
    "Close, but no.",
    NULL
};

static cptr epitaph_descriptive[] = {
    "Fell to an orc's blade, gold still clutched in hand.",
    "The last thing she saw was the Eye, and it saw her too.",
    "Died in the dark, alone, the sound of drums growing closer.",
    "Reached for the key. The Nazgul reached faster.",
    "The torch guttered out. So did hope.",
    "Backed into a corner. There was nowhere left to go.",
    "The arrow came from the darkness. He never saw the archer.",
    "Slipped on the wet stone. The fall was not survivable.",
    NULL
};

static cptr epitaph_ironic[] = {
    "Survived Sauron. Killed by a rat.",
    "Found the greatest treasure of the age. Couldn't find the stairs.",
    "Master of stealth. Tripped on a bone.",
    "Killed forty orcs. Forgot to eat.",
    "The door he closed behind him was the last one he'd ever see.",
    "Escaped a hundred traps. Missed one.",
    "Found the cure. Couldn't reach it in time.",
    "The armor held. The heart did not.",
    "Won the fight. Lost the war.",
    "Dodged the sword. Caught the arrow.",
    NULL
};

static cptr epitaph_bleak[] = {
    "Another soul for the pit.",
    "The Tower keeps what it takes.",
    "No song will remember this name.",
    "Even the stones forgot him.",
    "The darkness was always going to win.",
    "One more name for the forgotten list.",
    "The shadows do not mourn.",
    "Bones join bones. Nothing more.",
    "The pit grows deeper every day.",
    "No rescue comes. It never does.",
    NULL
};

static cptr epitaph_aspirational[] = {
    "Dreamed of Erebor. Almost made it.",
    "Carried hope deeper than any before.",
    "Sought the Ring. Found only death.",
    "Believed the old tales. Became one.",
    "Went further than wisdom allowed.",
    "Dared to enter. Dared to dream.",
    "Reached for glory. Touched the void.",
    "Braver than most. Just as dead.",
    "The road goes ever on. This one stopped.",
    "Had a plan. The Tower had other ideas.",
    NULL
};

static cptr epitaph_grim[] = {
    "The wights picked the bones clean.",
    "Screamed once. No one heard.",
    "Bled out in a forgotten corridor.",
    "The Necromancer added another servant.",
    "Died on his knees, begging.",
    "The last sound was crunching bone.",
    "Fed to the spiders. All of him.",
    "Left a stain on the stones.",
    "The wolves finished what the orcs started.",
    "No burial. No marker. No memory.",
    NULL
};

static cptr epitaph_heroic[] = {
    "Slew a Nazgul before the end.",
    "Looked into the Eye and did not flinch.",
    "Died fighting, as was fitting.",
    "Bought time for others who will never know.",
    "Found Thrain. That was enough.",
    "Stood alone against the dark.",
    "Fell with sword in hand.",
    "Made them pay for every step.",
    "The last charge was glorious.",
    "Died as he lived: defiant.",
    NULL
};


/*
 * Count entries in a NULL-terminated string array
 */
static int count_epitaphs(cptr *list)
{
    int count = 0;
    while (list[count] != NULL) count++;
    return count;
}

/*
 * Pick a random epitaph from a list
 */
static cptr pick_random_epitaph(cptr *list)
{
    int count = count_epitaphs(list);
    if (count == 0) return "The darkness claims another.";
    return list[rand_int(count)];
}

/*
 * Calculate total kills from monster lore
 */
static int calculate_total_kills(void)
{
    int i, total = 0;
    for (i = 0; i < z_info->r_max; i++)
    {
        total += l_list[i].pkills;
    }
    return total;
}

/*
 * Analyze the run profile to determine epitaph tone
 */
typedef enum {
    TONE_LACONIC,
    TONE_DESCRIPTIVE,
    TONE_IRONIC,
    TONE_BLEAK,
    TONE_ASPIRATIONAL,
    TONE_GRIM,
    TONE_HEROIC
} epitaph_tone;

static epitaph_tone analyze_run_profile(void)
{
    int total_kills = calculate_total_kills();
    int stealth_ratio = 0;
    int depth = p_ptr->depth;

    /* Calculate stealth ratio if possible */
    if (p_ptr->times_detected > 0 || p_ptr->enemies_avoided > 0)
    {
        stealth_ratio = (p_ptr->enemies_avoided * 100) /
                        (p_ptr->enemies_avoided + p_ptr->times_detected + 1);
    }

    /* Heroic: killed nazgul or had high kills with deep depth */
    if (p_ptr->killed_nazgul || (total_kills > 50 && depth > 8))
    {
        return TONE_HEROIC;
    }

    /* Grim: died on high stealth run (caught despite sneaking) */
    if (stealth_ratio > 70 && p_ptr->times_detected > 5)
    {
        return TONE_GRIM;
    }

    /* Ironic: high kills but died to weak enemy, or stealth expert detected */
    if (total_kills > 30 && p_ptr->biggest_enemy_killed > 50 &&
        p_ptr->killer_idx > 0 && r_info[p_ptr->killer_idx].level < 5)
    {
        return TONE_IRONIC;
    }

    /* Aspirational: got deep but died */
    if (depth > 10)
    {
        return TONE_ASPIRATIONAL;
    }

    /* Bleak: died without accomplishing much */
    if (total_kills < 10 && depth < 5 && playerturn < 2000)
    {
        return TONE_BLEAK;
    }

    /* Descriptive: mid-range run with some story */
    if (depth > 5 && total_kills > 15)
    {
        return TONE_DESCRIPTIVE;
    }

    /* Default to laconic */
    return TONE_LACONIC;
}

/*
 * Get epitaph list for a given tone
 */
static cptr* get_tone_epitaphs(epitaph_tone tone)
{
    switch (tone)
    {
        case TONE_LACONIC:     return (cptr*)epitaph_laconic;
        case TONE_DESCRIPTIVE: return (cptr*)epitaph_descriptive;
        case TONE_IRONIC:      return (cptr*)epitaph_ironic;
        case TONE_BLEAK:       return (cptr*)epitaph_bleak;
        case TONE_ASPIRATIONAL:return (cptr*)epitaph_aspirational;
        case TONE_GRIM:        return (cptr*)epitaph_grim;
        case TONE_HEROIC:      return (cptr*)epitaph_heroic;
        default:               return (cptr*)epitaph_bleak;
    }
}

/*
 * Generate a procedural epitaph based on the player's run.
 * Returns a static string - do not free.
 */
cptr generate_epitaph(void)
{
    /* Step 1: Check conditional triggers (highest priority) */

    /* Killed by Sauron */
    if (p_ptr->killer_idx == R_IDX_SAURON)
    {
        return pick_random_epitaph((cptr*)epitaph_killed_by_sauron);
    }

    /* Killed by Nazgul (Khamul) */
    if (p_ptr->killer_idx == R_IDX_KHAMUL)
    {
        return pick_random_epitaph((cptr*)epitaph_killed_by_nazgul);
    }

    /* Stole the Ring (very rare achievement) */
    if (p_ptr->stole_ring)
    {
        return pick_random_epitaph((cptr*)epitaph_stole_ring);
    }

    /* Found Thrain */
    if (p_ptr->found_thrain)
    {
        return pick_random_epitaph((cptr*)epitaph_found_thrain);
    }

    /* Saw Sauron (but wasn't killed by him) */
    if (p_ptr->saw_sauron && p_ptr->killer_idx != R_IDX_SAURON)
    {
        return pick_random_epitaph((cptr*)epitaph_saw_sauron);
    }

    /* Very long run */
    if (playerturn > 10000)
    {
        return pick_random_epitaph((cptr*)epitaph_long_run);
    }

    /* Very short run */
    if (playerturn < 500)
    {
        return pick_random_epitaph((cptr*)epitaph_short_run);
    }

    /* Died deep (layer 7 = depth 13) */
    if (p_ptr->depth >= 12)
    {
        return pick_random_epitaph((cptr*)epitaph_died_deep);
    }

    /* Died shallow (first few levels) */
    if (p_ptr->depth <= 3)
    {
        return pick_random_epitaph((cptr*)epitaph_died_shallow);
    }

    /* High stealth ratio */
    if (p_ptr->enemies_avoided > 20 &&
        p_ptr->enemies_avoided > p_ptr->times_detected * 2)
    {
        return pick_random_epitaph((cptr*)epitaph_high_stealth);
    }

    /* High kill count */
    if (calculate_total_kills() > 50)
    {
        return pick_random_epitaph((cptr*)epitaph_high_kills);
    }

    /* Pacifist run */
    if (calculate_total_kills() == 0)
    {
        return pick_random_epitaph((cptr*)epitaph_pacifist);
    }

    /* Step 2: No conditions matched, analyze run profile and pick by tone */
    epitaph_tone tone = analyze_run_profile();
    cptr *list = get_tone_epitaphs(tone);
    return pick_random_epitaph(list);
}


/*
 * Display the tombstone with epitaph
 */
void show_tombstone(void)
{
    int row = 2;
    cptr epitaph = generate_epitaph();
    char buf[120];

    /* Clear screen */
    Term_clear();

    /* Draw tombstone ASCII art */
    c_put_str(TERM_SLATE, "                              .-------------------.", row++, 10);
    c_put_str(TERM_SLATE, "                             /                     \\", row++, 10);
    c_put_str(TERM_SLATE, "                            /       R. I. P.        \\", row++, 10);
    c_put_str(TERM_SLATE, "                           |                         |", row++, 10);

    /* Epitaph in quotes, centered */
    row++;
    strnfmt(buf, sizeof(buf), "\"%s\"", epitaph);
    c_put_str(TERM_L_BLUE, buf, row++, 40 - strlen(buf)/2);
    row++;

    /* Character name */
    c_put_str(TERM_WHITE, op_ptr->full_name, row++, 40 - strlen(op_ptr->full_name)/2);

    /* Race and House */
    strnfmt(buf, sizeof(buf), "%s of %s",
            p_name + p_info[p_ptr->prace].name,
            c_name + c_info[p_ptr->phouse].alt_name);
    c_put_str(TERM_SLATE, buf, row++, 40 - strlen(buf)/2);

    row++;

    /* Depth */
    strnfmt(buf, sizeof(buf), "Depth: %d feet", p_ptr->depth * 50);
    c_put_str(TERM_SLATE, buf, row++, 40 - strlen(buf)/2);

    row++;
    c_put_str(TERM_SLATE, "                           |___________________________|", row++, 10);
    c_put_str(TERM_SLATE, "                          |___________________________|", row++, 10);

    row += 2;

    /* Transition text */
    c_put_str(TERM_L_DARK, "But your tale is not forgotten...", row++, 24);

    row += 2;
    c_put_str(TERM_SLATE, "[Press any key to continue]", row, 27);

    /* Wait for keypress */
    Term_fresh();
    inkey();
}


/*
 * Display the stats recap screen
 */
void display_death_recap(void)
{
    int row = 0;
    int total_kills = calculate_total_kills();
    char buf[120];
    cptr epitaph = generate_epitaph();

    /* Clear screen */
    Term_clear();

    /* Title */
    c_put_str(TERM_L_BLUE, "========================================================================", row++, 1);
    c_put_str(TERM_WHITE, "                           Y O U R   T A L E", row++, 1);
    c_put_str(TERM_L_BLUE, "========================================================================", row++, 1);

    /* Epitaph */
    row++;
    strnfmt(buf, sizeof(buf), "\"%s\"", epitaph);
    c_put_str(TERM_YELLOW, buf, row++, 40 - strlen(buf)/2);
    row++;

    c_put_str(TERM_L_BLUE, "------------------------------------------------------------------------", row++, 1);

    /* THE FALLEN - left column */
    c_put_str(TERM_WHITE, "  THE FALLEN", row, 1);
    c_put_str(TERM_WHITE, "  BLOOD SPILLED", row++, 42);
    c_put_str(TERM_L_DARK, "  ----------", row, 1);
    c_put_str(TERM_L_DARK, "  --------------", row++, 42);

    /* Character name */
    c_put_str(TERM_SLATE, format("  %s", op_ptr->full_name), row, 1);
    /* Enemies slain */
    c_put_str(TERM_SLATE, format("  Enemies slain: %d", total_kills), row++, 42);

    /* Race/House */
    c_put_str(TERM_SLATE, format("  %s of %s",
        p_name + p_info[p_ptr->prace].name,
        c_name + c_info[p_ptr->phouse].alt_name), row, 1);
    /* Biggest kill */
    if (p_ptr->biggest_enemy_killed > 0)
    {
        c_put_str(TERM_SLATE, format("  Biggest kill: %s",
            r_name + r_info[p_ptr->biggest_enemy_killed].name), row++, 42);
    }
    else
    {
        c_put_str(TERM_SLATE, "  Biggest kill: None", row++, 42);
    }

    /* Slain by */
    c_put_str(TERM_SLATE, format("  Slain by: %s", p_ptr->died_from), row, 1);
    /* Damage dealt */
    c_put_str(TERM_SLATE, format("  Damage dealt: %ld", (long)p_ptr->damage_dealt_total), row++, 42);

    /* Depth */
    c_put_str(TERM_SLATE, format("  Depth: %d feet", p_ptr->depth * 50), row, 1);
    /* Biggest hit */
    c_put_str(TERM_SLATE, format("  Biggest hit: %d", p_ptr->biggest_hit), row++, 42);

    /* Turns */
    c_put_str(TERM_SLATE, format("  Turns: %ld", (long)playerturn), row++, 1);

    row++;
    c_put_str(TERM_L_BLUE, "------------------------------------------------------------------------", row++, 1);

    /* SHADOWS WALKED - left column */
    c_put_str(TERM_WHITE, "  SHADOWS WALKED", row, 1);
    c_put_str(TERM_WHITE, "  THE JOURNEY", row++, 42);
    c_put_str(TERM_L_DARK, "  --------------", row, 1);
    c_put_str(TERM_L_DARK, "  ------------", row++, 42);

    /* Enemies avoided */
    c_put_str(TERM_SLATE, format("  Enemies avoided: %d", p_ptr->enemies_avoided), row, 1);
    /* Stairs descended */
    c_put_str(TERM_SLATE, format("  Stairs descended: %d", p_ptr->stairs_descended), row++, 42);

    /* Times detected */
    c_put_str(TERM_SLATE, format("  Times detected: %d", p_ptr->times_detected), row, 1);
    /* Stairs ascended */
    c_put_str(TERM_SLATE, format("  Stairs ascended: %d", p_ptr->stairs_ascended), row++, 42);

    /* Longest stealth */
    c_put_str(TERM_SLATE, format("  Longest stealth: %d turns", p_ptr->stealth_streak_max), row, 1);
    /* Potions quaffed */
    c_put_str(TERM_SLATE, format("  Potions quaffed: %d", p_ptr->potions_quaffed), row++, 42);

    /* Silent kills */
    c_put_str(TERM_SLATE, format("  Silent kills: %d", p_ptr->silent_kills), row, 1);
    /* Herbs consumed */
    c_put_str(TERM_SLATE, format("  Herbs consumed: %d", p_ptr->herbs_consumed), row++, 42);

    /* Doors closed */
    c_put_str(TERM_SLATE, format("  Doors closed: %d", p_ptr->doors_closed), row++, 1);

    row++;
    c_put_str(TERM_L_BLUE, "------------------------------------------------------------------------", row++, 1);

    /* MOMENTS OF NOTE */
    c_put_str(TERM_WHITE, "  MOMENTS OF NOTE:", row++, 1);

    /* Build achievement string */
    buf[0] = '\0';
    if (p_ptr->saw_sauron)
        my_strcat(buf, "  * Glimpsed the Necromancer", sizeof(buf));
    if (p_ptr->found_thrain)
        my_strcat(buf, "  * Found Thrain", sizeof(buf));
    if (p_ptr->killed_nazgul)
        my_strcat(buf, "  * Slew a Nazgul", sizeof(buf));
    if (p_ptr->stole_ring)
        my_strcat(buf, "  * Stole the Ring", sizeof(buf));

    if (strlen(buf) > 0)
    {
        c_put_str(TERM_YELLOW, buf, row++, 1);
    }
    else
    {
        c_put_str(TERM_L_DARK, "  None to speak of...", row++, 1);
    }

    row++;
    c_put_str(TERM_L_BLUE, "========================================================================", row++, 1);

    /* Footer */
    row++;
    c_put_str(TERM_SLATE, "        [Enter] New Game      [M] Menu      [Esc] Quit", row, 1);

    /* Wait for input */
    Term_fresh();
}


/*
 * Handle the death recap screen input
 * Returns: 'n' for new game, 'm' for menu, 'q' for quit
 */
char death_recap_input(void)
{
    char ch;

    while (TRUE)
    {
        ch = inkey();

        switch (ch)
        {
            case '\r':
            case '\n':
            case 'n':
            case 'N':
                return 'n';  /* New game */

            case 'm':
            case 'M':
                return 'm';  /* Menu */

            case ESCAPE:
            case 'q':
            case 'Q':
                return 'q';  /* Quit */
        }
    }
}


/*
 * Play the full death sequence.
 * This is the main entry point called when player dies.
 */
void play_death_sequence(void)
{
    /* Skip animation if disabled (could add config option) */
    /* For now, go straight to tombstone and recap */

    /* Show the tombstone with epitaph */
    show_tombstone();

    /* Show the stats recap */
    display_death_recap();

    /* Handle input (new game, menu, or quit) */
    /* Note: The actual handling of the choice is done by the caller */
}
