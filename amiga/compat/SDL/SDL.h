/* <SDL/SDL.h> for fk-engine-core, which was written for SDL 1.2: our SDL 2
 * (GFOpenGPU's SDL2.module on GFOS, the system's SDL 2 on the PC) and the
 * one SDL 1.2 call still left after patches/0001.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#ifndef TS_COMPAT_SDL_H
#define TS_COMPAT_SDL_H
#include <SDL.h>

/* SDL 1.2's "convert to the screen's format with alpha": with no screen
   surface in SDL 2, 32-bit ARGB is the format every blit takes */
static inline SDL_Surface* SDL_DisplayFormatAlpha(SDL_Surface* s)
{
    return SDL_ConvertSurfaceFormat(s, SDL_PIXELFORMAT_ARGB8888, 0);
}
#endif
