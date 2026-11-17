/* PC smoke test: the whole game (TriSpace, fk-engine-core, TinyGL,
 * patches/, amiga/ts_display.c) on SDL 2's dummy video and audio drivers,
 * driven by timed key events like a player:
 *   1.5 s  the title screen is up (state TITLE, a frame of many colours)
 *   2.0 s  Down, then A: "New game"
 *   3.0 s  X held (accelerate) for half a second
 *   4.5 s  the game is in space (state SPACE, many colours, a frame unlike
 *          the title's), then quit
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include "ts_display.h"

int ts_game_main(int argc, char** argv);
extern int state;               /* main.c's State (an enum) */
enum { ST_SPACE = 0, ST_TITLE = 8 };

static volatile int title_state = -1, space_state = -1;
static volatile unsigned long title_col, space_col, title_sum, space_sum, title_frames;

static void key(SDL_Keycode k, int down)
{
    SDL_Event e;
    SDL_memset(&e, 0, sizeof(e));
    e.type = down ? SDL_KEYDOWN : SDL_KEYUP;
    e.key.state = down ? SDL_PRESSED : SDL_RELEASED;
    e.key.keysym.sym = k;
    SDL_PushEvent(&e);
}

static Uint32 step(Uint32 interval, void* arg)
{
    (void)interval;
    switch ((int)(intptr_t)arg) {
    case 0: title_state = state; title_col = ts_display_colours(); title_sum = ts_display_sum(); title_frames = ts_display_frames(); break;
    case 1: key(SDLK_DOWN, 1); break;
    case 2: key(SDLK_DOWN, 0); break;
    case 3: key(SDLK_a, 1); break;
    case 4: key(SDLK_a, 0); break;
    case 5: key(SDLK_x, 1); break;
    case 6: key(SDLK_x, 0); break;
    case 7: space_state = state; space_col = ts_display_colours(); space_sum = ts_display_sum(); break;
    case 8: { SDL_Event e; SDL_memset(&e, 0, sizeof(e)); e.type = SDL_QUIT; SDL_PushEvent(&e); } break;
    }
    return 0;
}

int main(int argc, char** argv)
{
    static const int at[] = {1500, 2000, 2150, 2300, 2450, 3000, 3500, 4500, 4700};
    int fail = 0;
    setenv("SDL_VIDEODRIVER", "dummy", 1);
    setenv("SDL_AUDIODRIVER", "dummy", 1);
    ts_display_count = 1;
    if (SDL_Init(SDL_INIT_TIMER) != 0) { printf("FAIL: SDL timer: %s\n", SDL_GetError()); return 1; }
    for (int i = 0; i < (int)(sizeof(at) / sizeof(at[0])); i++)
        SDL_AddTimer(at[i], step, (void*)(intptr_t)i);
    int rc = ts_game_main(argc, argv);
    unsigned long frames = ts_display_frames();
#define CHECK(c, ...) do { if (!(c)) { printf("FAIL: " __VA_ARGS__); printf("\n"); fail = 1; } } while (0)
    CHECK(rc == 0, "game returned %d", rc);
    CHECK(title_state == ST_TITLE, "state at 1.5 s %d, want TITLE (%d)", title_state, ST_TITLE);
    CHECK(title_frames >= 20, "only %lu frames in 1.5 s", title_frames);
    CHECK(title_col >= 4, "title frame has %lu colours", title_col);
    CHECK(space_state == ST_SPACE, "state after New game %d, want SPACE (%d)", space_state, ST_SPACE);
    CHECK(space_col >= 4, "space frame has %lu colours", space_col);
    CHECK(space_sum != title_sum, "the space frame is the title frame");
    CHECK(frames >= 60, "only %lu frames in all", frames);
    if (!fail)
        printf("smoke: %lu frames; title %lu colours, space %lu: all checks passed\n", frames, title_col, space_col);
    return fail;
}
