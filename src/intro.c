/* File: intro.c */

/*
 * Copyright (c) 2026 The Necromancer Contributors
 *
 * This software may be copied and distributed for educational, research,
 * and not for profit purposes provided that this copyright and statement
 * are included in all such copies.
 */

/*
 * Animated ASCII intro sequence for The Necromancer
 * Inspired by Dwarf Fortress intro style
 */

#include "angband.h"

/*
 * Check if a key has been pressed (non-blocking)
 * Returns TRUE if key pressed, FALSE otherwise
 */
static bool intro_check_skip(void)
{
    char ch;

    /* Try to get a key without waiting */
    if (Term_inkey(&ch, FALSE, FALSE) == 0)
    {
        return TRUE;
    }

    return FALSE;
}

/*
 * Delay for specified milliseconds, checking for skip
 * Returns TRUE if skipped, FALSE if delay completed
 */
static bool intro_delay(int msec)
{
    /* Check for skip first */
    if (intro_check_skip()) return TRUE;

    /* Do the delay */
    Term_xtra(TERM_XTRA_DELAY, msec);

    return FALSE;
}

/*
 * Draw centered text at specified row
 */
static void intro_centered_text(int row, const char *text, byte color)
{
    int len = strlen(text);
    int col = (80 - len) / 2;

    Term_putstr(col, row, -1, color, text);
}

/*
 * Clear screen to black
 */
static void intro_clear(void)
{
    Term_clear();
}

/*
 * Refresh the display
 */
static void intro_refresh(void)
{
    Term_fresh();
}

/*
 * Color cycling for flame effect
 */
static byte flame_color(int frame)
{
    byte colors[] = {TERM_RED, TERM_ORANGE, TERM_YELLOW, TERM_ORANGE};
    return colors[frame % 4];
}

/* ========================================================================
 * SCENE 1: Title Fade
 * Duration: ~3 seconds
 * ======================================================================== */

static bool scene1_title(void)
{
    const char *title = "THE NECROMANCER";
    const char *subtitle = "A Tale of Dol Guldur";
    int title_row = 10;
    int sub_row = 13;
    int title_col, sub_col;
    int i, c;
    byte colors[] = {TERM_RED, TERM_ORANGE, TERM_YELLOW, TERM_ORANGE, TERM_RED};

    title_col = (80 - strlen(title)) / 2;
    sub_col = (80 - strlen(subtitle)) / 2;

    /* Black pause for drama */
    intro_clear();
    intro_refresh();
    if (intro_delay(500)) return TRUE;

    /* Type title letter by letter */
    for (i = 0; i < (int)strlen(title); i++)
    {
        Term_putch(title_col + i, title_row, TERM_ORANGE, title[i]);
        intro_refresh();
        if (intro_delay(80)) return TRUE;
    }

    /* Pulse title colors */
    for (c = 0; c < 5; c++)
    {
        Term_putstr(title_col, title_row, -1, colors[c], title);
        intro_refresh();
        if (intro_delay(100)) return TRUE;
    }

    /* Type subtitle */
    for (i = 0; i < (int)strlen(subtitle); i++)
    {
        Term_putch(sub_col + i, sub_row, TERM_SLATE, subtitle[i]);
        intro_refresh();
        if (intro_delay(40)) return TRUE;
    }

    /* Hold longer for dramatic effect */
    if (intro_delay(1500)) return TRUE;

    return FALSE;
}

/* ========================================================================
 * SCENE 2: Mirkwood Forest (simplified)
 * Duration: ~4 seconds
 * ======================================================================== */

static const char *forest_healthy[] = {
    "                                                                                ",
    "         ^     /\\      ^      /\\     ^     /\\      ^     /\\      ^            ",
    "        /|\\   /||\\    /|\\    //\\\\   /|\\   /||\\    /|\\   //\\\\    /|\\          ",
    "        /|\\   //\\\\    |||    //\\\\   /|\\   //\\\\    |||   //\\\\    /|\\          ",
    "         |     ||      |      ||     |     ||      |     ||      |            ",
    "    ___...___...___...___...___...___...___...___...___...___...___            ",
    NULL
};

static const char *forest_dark[] = {
    "                                                                                ",
    "        ~^    /~\\    `^`    ~^~    `~`   /~\\    ~^~    `^`   ~^~               ",
    "       /~\\   /~~\\   ~|~    ~~~    `~`   /~~\\   ~~~    ~|~   ~~~               ",
    "       |~|   |~~|   |~|    ~~~    ~~~   |~~|   ~~~    |~|   ~~~               ",
    "        |     ||     |      |      |     ||     |      |     |                ",
    "    ~~~___~~~___~~~___~~~___~~~___~~~___~~~___~~~___~~~___~~~___               ",
    "    . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .               ",
    NULL
};

static bool scene2_forest(void)
{
    int row, frame;
    const char **lines;
    byte color;

    /* Healthy forest */
    intro_clear();
    lines = forest_healthy;
    for (row = 0; lines[row] != NULL; row++)
    {
        Term_putstr(0, 6 + row, -1, TERM_GREEN, lines[row]);
    }
    intro_centered_text(3, "The shadow over Mirkwood deepens...", TERM_L_BLUE);
    intro_refresh();
    if (intro_delay(1500)) return TRUE;

    /* Transition - fog rolls in */
    for (frame = 0; frame < 10; frame++)
    {
        /* Darken progressively */
        color = (frame < 5) ? TERM_GREEN : TERM_L_DARK;
        intro_clear();

        lines = (frame < 5) ? forest_healthy : forest_dark;
        for (row = 0; lines[row] != NULL; row++)
        {
            Term_putstr(0, 6 + row, -1, color, lines[row]);
        }

        /* Add fog at bottom */
        if (frame > 3)
        {
            int fog_row;
            for (fog_row = 14; fog_row < 14 + (frame - 3); fog_row++)
            {
                Term_putstr(0, fog_row, -1, TERM_L_DARK,
                    ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .");
            }
        }

        intro_refresh();
        if (intro_delay(200)) return TRUE;
    }

    /* Fog engulfs */
    intro_clear();
    for (row = 0; row < 24; row++)
    {
        Term_putstr(0, row, -1, TERM_L_DARK,
            "................................................................");
    }
    intro_refresh();
    if (intro_delay(500)) return TRUE;

    return FALSE;
}

/* ========================================================================
 * SCENE 3: Dol Guldur Revealed
 * Duration: ~4 seconds
 * ======================================================================== */

static const char *fortress_art[] = {
    "                              .                                                ",
    "                             /|\\                                               ",
    "                            / | \\                                              ",
    "                           /  *  \\                                             ",
    "                          /   |   \\                                            ",
    "                         /____|____\\                                           ",
    "                        |    |||    |                                          ",
    "              .___      |    |||    |      ___.                                ",
    "             /    \\_____|____|||____|_____/    \\                               ",
    "            /     |                       |     \\                              ",
    "           /      |     ___________       |      \\                             ",
    "      ___/   _____|____|           |______|_____   \\___                        ",
    "     |      |          |___________|            |      |                       ",
    "   __|______|__________________________________|______|__                      ",
    NULL
};

static bool scene3_fortress(void)
{
    int row, frame;
    byte glow_color;

    /* Emerge from mist */
    for (frame = 0; frame < 20; frame++)
    {
        intro_clear();

        /* Draw fortress with progressive visibility */
        for (row = 0; fortress_art[row] != NULL; row++)
        {
            byte color = TERM_L_DARK;

            /* Top rows appear first */
            if (row <= frame / 2)
            {
                color = TERM_SLATE;
            }

            Term_putstr(0, 3 + row, -1, color, fortress_art[row]);
        }

        /* Mist at bottom */
        if (frame < 15)
        {
            int mist_start = 17 - frame / 3;
            for (row = mist_start; row < 20; row++)
            {
                Term_putstr(0, row, -1, TERM_L_DARK,
                    ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .");
            }
        }

        /* Red glow in window (pulsing) */
        glow_color = (frame % 2 == 0) ? TERM_RED : TERM_ORANGE;
        Term_putch(34, 6, glow_color, '*');

        intro_refresh();
        if (intro_delay(150)) return TRUE;
    }

    /* Date appears */
    intro_centered_text(20, "T.A. 2850", TERM_SLATE);
    intro_refresh();
    if (intro_delay(1000)) return TRUE;

    return FALSE;
}

/* ========================================================================
 * SCENE 4: The Descent
 * Duration: ~5 seconds
 * ======================================================================== */

static bool scene4_descent(void)
{
    int depth, frame;
    char depth_str[32];

    /* Quick cuts through dungeon layers */

    /* CUT 1: Orc Patrol (100-250ft) */
    for (frame = 0; frame < 15; frame++)
    {
        intro_clear();
        depth = 100 + (frame * 10);
        sprintf(depth_str, "Depth: %d ft", depth);
        Term_putstr(2, 1, -1, TERM_ORANGE, depth_str);

        /* Stone corridor */
        Term_putstr(10, 4, -1, TERM_SLATE,  "############################");
        Term_putstr(10, 5, -1, TERM_L_DARK, "#  .  .  .  .  .  .  .  .  #");
        Term_putstr(10, 6, -1, TERM_L_DARK, "#                          #");

        /* Marching orcs with torches */
        int orc_x = 12 + (frame % 6);
        Term_putch(orc_x, 7, TERM_UMBER, 'o');
        Term_putch(orc_x + 3, 7, TERM_UMBER, 'o');
        Term_putch(orc_x + 6, 7, TERM_UMBER, 'o');
        Term_putch(orc_x + 1, 6, TERM_YELLOW, '*'); /* torch */

        Term_putstr(10, 8, -1, TERM_L_DARK, "#                          #");
        Term_putstr(10, 9, -1, TERM_SLATE,  "############################");

        Term_putstr(15, 12, -1, TERM_UMBER, "-- Orc Patrols --");

        intro_refresh();
        if (intro_delay(80)) return TRUE;
    }

    /* Black flash */
    intro_clear();
    intro_refresh();
    if (intro_delay(150)) return TRUE;

    /* CUT 2: Warg Kennels (300-450ft) */
    for (frame = 0; frame < 12; frame++)
    {
        intro_clear();
        depth = 300 + (frame * 12);
        sprintf(depth_str, "Depth: %d ft", depth);
        Term_putstr(2, 1, -1, TERM_ORANGE, depth_str);

        /* Cages */
        Term_putstr(8, 5, -1, TERM_SLATE, "+---------+  +---------+  +---------+");
        Term_putstr(8, 6, -1, TERM_SLATE, "|         |  |         |  |         |");

        /* Wargs pacing */
        int warg_pos = frame % 4;
        Term_putch(10 + warg_pos, 7, TERM_UMBER, 'C');
        Term_putch(23 + warg_pos, 7, TERM_UMBER, 'C');
        Term_putch(36 + warg_pos, 7, TERM_UMBER, 'C');

        Term_putstr(8, 8, -1, TERM_SLATE, "|         |  |         |  |         |");
        Term_putstr(8, 9, -1, TERM_SLATE, "+---------+  +---------+  +---------+");

        Term_putstr(15, 12, -1, TERM_UMBER, "-- Warg Kennels --");

        intro_refresh();
        if (intro_delay(80)) return TRUE;
    }

    /* Black flash */
    intro_clear();
    intro_refresh();
    if (intro_delay(150)) return TRUE;

    /* CUT 3: Crypts (550-700ft) */
    for (frame = 0; frame < 12; frame++)
    {
        intro_clear();
        depth = 550 + (frame * 12);
        sprintf(depth_str, "Depth: %d ft", depth);
        Term_putstr(2, 1, -1, TERM_ORANGE, depth_str);

        /* Tombs */
        Term_putstr(10, 5, -1, TERM_SLATE, "+---+     +---+     +---+");
        Term_putstr(10, 6, -1, TERM_SLATE, "|RIP|     |RIP|     |RIP|");
        Term_putstr(10, 7, -1, TERM_SLATE, "+---+     +---+     +---+");

        /* Wight rising from middle tomb */
        if (frame > 6)
        {
            Term_putch(22, 6, TERM_L_BLUE, 'W');
            if (frame > 8)
            {
                Term_putstr(18, 4, -1, TERM_L_BLUE, "~  W  ~");
            }
        }

        /* Ghostly wisps float */
        int wisp_x = 12 + ((frame * 2) % 20);
        Term_putch(wisp_x, 10, TERM_L_DARK, '~');
        Term_putch(wisp_x + 8, 9, TERM_L_DARK, '~');

        Term_putstr(15, 13, -1, TERM_L_BLUE, "-- The Crypts --");

        intro_refresh();
        if (intro_delay(100)) return TRUE;
    }

    /* Black flash */
    intro_clear();
    intro_refresh();
    if (intro_delay(150)) return TRUE;

    /* CUT 4: The Pit (850-1000ft) */
    for (frame = 0; frame < 15; frame++)
    {
        intro_clear();
        depth = 850 + (frame * 10);
        sprintf(depth_str, "Depth: %d ft", depth);
        Term_putstr(2, 1, -1, TERM_ORANGE, depth_str);

        /* Darkness - almost nothing visible */
        Term_putstr(15, 6, -1, TERM_L_DARK, ". . . darkness . . .");

        /* Occasional glints */
        if (frame % 4 == 0)
        {
            Term_putch(25 + (frame % 8), 10, TERM_YELLOW, '*');
        }

        /* Chains appear in later frames */
        if (frame > 8)
        {
            Term_putstr(20, 8, -1, TERM_L_DARK, "|   |   |");
            Term_putstr(20, 9, -1, TERM_L_DARK, "|   |   |");
        }

        Term_putstr(12, 13, -1, TERM_L_DARK, "-- The Deepest Pit --");

        intro_refresh();
        if (intro_delay(100)) return TRUE;
    }

    return FALSE;
}

/* ========================================================================
 * SCENE 5: Thráin's Prison
 * Duration: ~4 seconds
 * ======================================================================== */

static bool scene5_pit(void)
{
    int frame, i;
    const char *whisper = "The last of the Seven...";
    int whisper_col;

    whisper_col = (80 - strlen(whisper)) / 2;

    /* Establish the pit */
    for (frame = 0; frame < 40; frame++)
    {
        intro_clear();

        /* Depth indicator */
        Term_putstr(2, 1, -1, TERM_ORANGE, "DEPTH: 1000ft");

        /* Pit walls */
        Term_putstr(10, 4, -1, TERM_L_DARK, "########################################");
        for (i = 5; i < 15; i++)
        {
            Term_putstr(10, i, -1, TERM_L_DARK, "#                                      #");
        }
        Term_putstr(10, 15, -1, TERM_L_DARK, "########################################");

        /* Thráin appears after frame 10 */
        if (frame >= 10)
        {
            /* Chains */
            Term_putstr(18, 8, -1, TERM_L_DARK, "-+-");
            Term_putstr(19, 9, -1, TERM_L_DARK, "|");

            /* Thráin - head raises after frame 25 */
            char thrain_char = (frame >= 25) ? 'H' : 'h';
            Term_putch(19, 10, TERM_UMBER, thrain_char);
            Term_putstr(18, 11, -1, TERM_L_DARK, "/|\\");
        }

        /* Gold glint appears after frame 15, pulses */
        if (frame >= 15)
        {
            byte gold_color = ((frame / 2) % 2 == 0) ? TERM_YELLOW : TERM_L_UMBER;
            Term_putch(30, 12, gold_color, '*');
        }

        /* Whispered text appears after frame 30, letter by letter */
        if (frame >= 30)
        {
            int chars_to_show = (frame - 30) + 1;
            if (chars_to_show > (int)strlen(whisper)) chars_to_show = strlen(whisper);

            for (i = 0; i < chars_to_show; i++)
            {
                Term_putch(whisper_col + i, 18, TERM_SLATE, whisper[i]);
            }
        }

        intro_refresh();
        if (intro_delay(100)) return TRUE;
    }

    return FALSE;
}

/* ========================================================================
 * SCENE 6: The Lidless Eye
 * Duration: ~4 seconds
 * ======================================================================== */

static const char *eye_closed[] = {
    "                            ------------                                       ",
    NULL
};

static const char *eye_opening[] = {
    "                           __----------__                                      ",
    "                           ''----------''                                      ",
    NULL
};

static const char *eye_half[] = {
    "                          _.-''------''-._                                     ",
    "                         (       ||       )                                    ",
    "                          '-._--------_.-'                                     ",
    NULL
};

static const char *eye_full[] = {
    "                                                                               ",
    "                        *  ~              ~  *                                 ",
    "                     ^       *    **    *       ^                              ",
    "                   *    _.--''        ''--._    *                              ",
    "                  ~  .-'                    '-.  ~                             ",
    "                 * .'    _.--''------''-._    '. *                             ",
    "                ~ /   .-'        ||        '-.   \\ ~                           ",
    "                */   /           ||           \\   \\*                           ",
    "                ~|  |            ||            |  |~                           ",
    "                *|  |            ||            |  |*                           ",
    "                ~|  |            ||            |  |~                           ",
    "                * \\   \\          ||          /   / *                           ",
    "                 ~ '.  '-.._     ||     _..-'  .' ~                            ",
    "                  *  '._    ''--....--''    _.' *                              ",
    "                   ~    '-._            _.-'    ~                              ",
    "                     ^      ''--....--''      ^                                ",
    "                        *  ~              ~  *                                 ",
    NULL
};

static bool scene6_eye(void)
{
    int frame, row;

    /* Rapid pullback (just fade to black) */
    for (frame = 0; frame < 5; frame++)
    {
        intro_clear();
        intro_refresh();
        if (intro_delay(100)) return TRUE;
    }

    /* The pause - pure black, dramatic tension */
    intro_clear();
    intro_refresh();
    if (intro_delay(1000)) return TRUE;

    /* Eye opening sequence */

    /* Closed slit */
    intro_clear();
    for (row = 0; eye_closed[row] != NULL; row++)
    {
        Term_putstr(0, 11 + row, -1, TERM_RED, eye_closed[row]);
    }
    intro_refresh();
    if (intro_delay(300)) return TRUE;

    /* Opening */
    intro_clear();
    for (row = 0; eye_opening[row] != NULL; row++)
    {
        Term_putstr(0, 10 + row, -1, TERM_RED, eye_opening[row]);
    }
    intro_refresh();
    if (intro_delay(300)) return TRUE;

    /* Half open */
    intro_clear();
    for (row = 0; eye_half[row] != NULL; row++)
    {
        Term_putstr(0, 9 + row, -1, TERM_ORANGE, eye_half[row]);
    }
    intro_refresh();
    if (intro_delay(300)) return TRUE;

    /* FULLY OPEN - with flames */
    for (frame = 0; frame < 25; frame++)
    {
        intro_clear();

        byte color = flame_color(frame);

        for (row = 0; eye_full[row] != NULL; row++)
        {
            /* Color flames differently from eye structure */
            const char *line = eye_full[row];
            int col;

            for (col = 0; col < 80 && line[col] != '\0'; col++)
            {
                char ch = line[col];
                byte char_color;

                if (ch == '*' || ch == '^' || ch == '~')
                {
                    char_color = color;  /* Flames cycle */
                }
                else if (ch == '|')
                {
                    char_color = TERM_L_DARK;  /* Pupil slit */
                }
                else if (ch == '.' || ch == '\'' || ch == '_' || ch == '-' ||
                         ch == '(' || ch == ')' || ch == '/' || ch == '\\')
                {
                    char_color = TERM_RED;  /* Eye structure */
                }
                else
                {
                    char_color = TERM_DARK;  /* Background */
                }

                if (ch != ' ')
                {
                    Term_putch(col, 3 + row, char_color, ch);
                }
            }
        }

        intro_refresh();
        if (intro_delay(100)) return TRUE;
    }

    return FALSE;
}

/* ========================================================================
 * SCENE 7: Title Redux / Finale
 * Loops until keypress
 * ======================================================================== */

static const char *eye_medium[] = {
    "            ~  *  ~             ",
    "         *   _---_   *         ",
    "        ~  .'  ||  '.  ~        ",
    "        * |    ||    | *        ",
    "        ~  '.  ||  .'  ~        ",
    "         *   '---'   *          ",
    "            ~  *  ~             ",
    NULL
};

static bool scene7_finale(void)
{
    int frame = 0;
    int row, col;
    bool prompt_bright;
    char ch;

    while (1)
    {
        /* Check for keypress (non-blocking) */
        if (Term_inkey(&ch, FALSE, FALSE) == 0)
        {
            /* Key was pressed - exit cleanly */
            return FALSE;
        }

        intro_clear();

        /* Title with flame color cycling */
        const char *title = "THE NECROMANCER";
        int title_col = (80 - (int)strlen(title)) / 2;
        byte title_color = flame_color(frame);
        Term_putstr(title_col, 5, -1, title_color, title);

        /* Medium eye with flame animation */
        byte color = flame_color(frame);
        int eye_start_col = (80 - 32) / 2;

        for (row = 0; eye_medium[row] != NULL; row++)
        {
            const char *line = eye_medium[row];

            for (col = 0; line[col] != '\0'; col++)
            {
                char c = line[col];
                byte char_color;

                if (c == '*' || c == '^' || c == '~')
                {
                    char_color = color;
                }
                else if (c == '|')
                {
                    char_color = TERM_L_DARK;
                }
                else if (c == '.' || c == '\'' || c == '_' || c == '-')
                {
                    char_color = TERM_RED;
                }
                else
                {
                    continue;  /* Skip spaces */
                }

                Term_putch(eye_start_col + col, 8 + row, char_color, c);
            }
        }

        /* Subtitle */
        intro_centered_text(17, "A Tale of Dol Guldur", TERM_SLATE);

        /* Pulsing prompt */
        prompt_bright = ((frame / 10) % 2 == 0);
        byte prompt_color = prompt_bright ? TERM_WHITE : TERM_L_DARK;
        intro_centered_text(21, "[ Press any key to begin ]", prompt_color);

        intro_refresh();

        /* Delay */
        Term_xtra(TERM_XTRA_DELAY, 100);

        /* Next frame */
        frame = (frame + 1) % 40;
    }

    return FALSE;
}

/* ========================================================================
 * MAIN INTRO FUNCTION
 * ======================================================================== */

/*
 * Play the full intro animation sequence
 * Returns when complete or when user presses a key to skip
 */
void play_intro_animation(void)
{
    /* Scene 1: Title Fade */
    if (scene1_title()) goto cleanup;

    /* Scene 2: Mirkwood Forest */
    if (scene2_forest()) goto cleanup;

    /* Scene 3: Dol Guldur Revealed */
    if (scene3_fortress()) goto cleanup;

    /* Scene 4: The Descent */
    if (scene4_descent()) goto cleanup;

    /* Scene 5: Thráin's Prison */
    if (scene5_pit()) goto cleanup;

    /* Scene 6: The Lidless Eye */
    if (scene6_eye()) goto cleanup;

    /* Scene 7: Title Redux (loops until keypress) */
    scene7_finale();

cleanup:
    /* Clear screen for game */
    intro_clear();
    intro_refresh();

    /* Flush any pending key events to prevent them affecting the menu */
    Term_flush();
}
