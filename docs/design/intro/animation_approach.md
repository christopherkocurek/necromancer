# ASCII Animation Approach

## Chosen Implementation Strategy

### Frame-Based Animation with Embedded C Arrays

After analyzing the codebase and requirements, the best approach is:

1. **Store frames as C string arrays** embedded directly in source code
2. **One frame = array of 24 strings** (one per screen row)
3. **Color data stored alongside** as parallel array or encoded in frame
4. **Simple playback loop** with configurable frame timing

### Why This Approach

| Approach | Pros | Cons |
|----------|------|------|
| **Embedded C arrays** | No file I/O, fast, self-contained | Larger binary, harder to edit |
| External text files | Easy to edit, small binary | Requires file loading, path issues |
| Procedural generation | Small code, flexible | Complex, harder to design |

**Decision**: Embedded arrays for reliability. Frame design can be done in text files, then converted to C code.

## Frame Data Structure

```c
// Single frame: 24 rows of 80 characters + colors
typedef struct {
    char text[24][81];      // Screen content (null-terminated)
    byte attr[24][80];      // Color per character
} intro_frame;

// Scene: collection of frames with timing
typedef struct {
    intro_frame *frames;
    int frame_count;
    int frame_delay_ms;     // Milliseconds per frame
} intro_scene;
```

### Simplified Alternative (Color Per Row)

For simpler scenes, use single color per row:
```c
typedef struct {
    char text[24][81];
    byte row_color[24];     // One color per row
} intro_frame_simple;
```

## Animation Playback Algorithm

```c
void play_intro_animation(void)
{
    int scene, frame;
    char ch;

    for (scene = 0; scene < NUM_SCENES; scene++) {
        for (frame = 0; frame < scenes[scene].frame_count; frame++) {

            // Check for skip
            if (check_for_keypress()) {
                return;  // Skip to menu
            }

            // Clear and draw frame
            Term_clear();
            draw_frame(&scenes[scene].frames[frame]);
            Term_fresh();

            // Delay
            Term_xtra(TERM_XTRA_DELAY, scenes[scene].frame_delay_ms);
        }
    }
}
```

## Color Encoding for Flames

Flame effect uses cycling colors:
- Frame 0: `TERM_RED`
- Frame 1: `TERM_ORANGE`
- Frame 2: `TERM_YELLOW`
- Frame 3: `TERM_ORANGE`
- Repeat...

For flame characters (`*`, `^`, `~`), cycle colors based on frame number.

## Scene Breakdown

| Scene | Frames | FPS | Duration | Technique |
|-------|--------|-----|----------|-----------|
| 1. Title Fade | 30 | 10 | 3.0s | Letter-by-letter reveal |
| 2. Forest Pan | 40 | 10 | 4.0s | Horizontal scroll |
| 3. Fortress | 40 | 10 | 4.0s | Fade from mist |
| 4. Descent | 50 | 10 | 5.0s | Quick cuts with depth counter |
| 5. Prison | 40 | 10 | 4.0s | Static with glint animation |
| 6. Eye Reveal | 40 | 10 | 4.0s | Dramatic reveal |
| 7. Finale | 30 | 10 | 3.0s | Loop until keypress |

**Total**: ~270 frames, ~27 seconds

## Optimization: Procedural Elements

Some effects can be procedural to reduce frame count:

### Flame Flicker
```c
void animate_flames(int frame_num) {
    byte colors[] = {TERM_RED, TERM_ORANGE, TERM_YELLOW, TERM_ORANGE};
    byte flame_color = colors[frame_num % 4];
    // Apply to all flame characters
}
```

### Fog Effect
```c
void draw_fog(int density, int drift) {
    for (int i = 0; i < density; i++) {
        int x = (fog_positions[i] + drift) % 80;
        int y = fog_rows[i];
        Term_putch(x, y, TERM_L_DARK, '.');
    }
}
```

### Text Fade-In
```c
void fade_in_text(const char *text, int row, int col, int progress) {
    int chars_visible = (strlen(text) * progress) / 100;
    for (int i = 0; i < chars_visible; i++) {
        Term_putch(col + i, row, TERM_ORANGE, text[i]);
    }
}
```

## File Organization

```
src/
  intro.c          - Animation playback code
  intro.h          - Frame data structures
  intro_frames.c   - Embedded frame data (generated)

docs/design/intro/
  frames/          - Design files (text format for editing)
    scene1_title.txt
    scene2_forest.txt
    ...
  eye_art.txt      - The iconic Eye design
```

## Skip Detection Implementation

```c
// Check if any key pressed (non-blocking)
static bool check_for_keypress(void)
{
    char ch;
    // Try to get a key without blocking
    if (Term_inkey(&ch, FALSE, FALSE) == 0) {
        return TRUE;  // Key was pressed
    }
    return FALSE;
}
```

## Config Option

Add to user preferences:
```c
// In variables.c or similar
bool intro_movie = TRUE;  // Default: show intro

// Check at startup
if (intro_movie) {
    play_intro_animation();
}
```

## Implementation Order

1. Create `intro.c` with basic playback framework
2. Design the Eye (key visual asset)
3. Create title scene (simplest)
4. Add scenes incrementally
5. Test and tune timing
6. Add skip detection
7. Add config option
