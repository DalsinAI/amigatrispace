/* TriSpace's screen on SDL 2 (see ts_display.h). On GFOS this is GFOpenGPU's
 * SDL2.module: a window on the Workbench screen, or the whole screen.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include "ts_display.h"

#include <SDL.h>
#include <stdlib.h>
#include <string.h>

static SDL_Window* window;
static SDL_Renderer* renderer;
static SDL_Texture* texture;
static unsigned short* frame;
static int fw, fh;
static unsigned long frames, colours, sum;
int ts_display_count;

int ts_display_scale(const char* env)
{
    if (env && *env) {
        int s = atoi(env);
        if (s >= 1 && s <= 6)
            return s;
    }
    return 2;
}

int ts_display_fullscreen(const char* env)
{
    return env && strcmp(env, "1") == 0;
}

int ts_display_open(int w, int h)
{
    int s = ts_display_scale(getenv("TRISPACE_SCALE"));
    Uint32 flags = SDL_WINDOW_RESIZABLE;
    if (ts_display_fullscreen(getenv("TRISPACE_FULLSCREEN")))
        flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
    fw = w; fh = h;
    frame = calloc((size_t)w * h, sizeof(*frame));
    if (!frame)
        return 0;
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
    window = SDL_CreateWindow("TriSpace", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                              w * s, h * s, flags);
    if (!window)
        return 0;
    renderer = SDL_CreateRenderer(window, -1, 0);
    if (!renderer)
        return 0;
    SDL_RenderSetLogicalSize(renderer, w, h);
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_STREAMING, w, h);
    if (!texture)
        return 0;
    SDL_ShowCursor(SDL_DISABLE);
    return 1;
}

void* ts_display_pixels(void) { return frame; }
int ts_display_pitch(void) { return fw * (int)sizeof(*frame); }

unsigned long ts_display_colour_count(const unsigned short* px, int w, int h, int pitch)
{
    static unsigned char seen[65536 / 8];
    unsigned long n = 0;
    memset(seen, 0, sizeof(seen));
    for (int y = 0; y < h; y++) {
        const unsigned short* row = (const unsigned short*)((const char*)px + (long)y * pitch);
        for (int x = 0; x < w; x++) {
            unsigned c = row[x];
            if (!(seen[c >> 3] & (1u << (c & 7)))) {
                seen[c >> 3] |= (unsigned char)(1u << (c & 7));
                n++;
            }
        }
    }
    return n;
}

void ts_display_present(void)
{
    SDL_UpdateTexture(texture, NULL, frame, ts_display_pitch());
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
    frames++;
    if (ts_display_count) {
        unsigned long h = 5381;
        for (long i = 0; i < (long)fw * fh; i++)
            h = h * 33 + frame[i];
        sum = h;
        colours = ts_display_colour_count(frame, fw, fh, ts_display_pitch());
    }
}

void ts_display_close(void)
{
    if (texture) SDL_DestroyTexture(texture);
    if (renderer) SDL_DestroyRenderer(renderer);
    if (window) SDL_DestroyWindow(window);
    texture = NULL; renderer = NULL; window = NULL;
    free(frame);
    frame = NULL;
}

unsigned long ts_display_frames(void) { return frames; }
unsigned long ts_display_colours(void) { return colours; }
unsigned long ts_display_sum(void) { return sum; }
