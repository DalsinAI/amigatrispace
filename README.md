# TriSpace for GFOS

TriSpace 1.1.2, an Elite-like space game by robbi-blechdose (trading,
contracts, ship upgrades, space combat, procedurally generated star
systems), for GFOS (AmigaOS 3.2.3 with GFOpenUp), as a GFOpenUp part:

    GFOpenUpTool INSTALL Parts/TriSpace

gives the drawer `SYS:Games/TriSpace` (the game, its models, textures, sound
and music, this ReadMe and the licences). It needs the GFOpenGPU part.

## Playing

| Key | Does |
|---|---|
| Cursor keys | Pitch and roll; move in menus |
| A | Fire; choose |
| S | Fire a missile; back |
| X / Y | Faster / slower |
| U / I | Previous / next tab in a station |
| M | Star map (Start) |
| N | Autodock (Select) |
| Q | Menu |

Saves go in the game's drawer (`PROGDIR:Saves`).

The game draws a 240x240 frame. Its window opens at twice that size;
`SetEnv TRISPACE_SCALE 3` (1 to 6) picks another size, and
`SetEnv TRISPACE_FULLSCREEN 1` fills the screen.

## What it is

- TriSpace, its engine fk-engine-core and TinyGL (the software OpenGL subset
  it draws with) are fetched at the commits in trispace.lock at build time;
  nothing third-party is kept here.
- TinyGL is set as TriSpace's README asks: 16-bit RGB565 frame, 0xf81f as the
  colour not drawn; no threads.
- SDL 1.2 calls go to our SDL 2 (GFOpenGPU's SDL2.module): the frame goes into
  a window through `amiga/ts_display.c` (patches/0001), sound and music through
  SDL2_mixer, images through SDL2_image (`amiga/compat/SDL/`).
- patches/0002: saves in `PROGDIR:Saves` (there is no `$HOME` on AmigaOS).
- 68040 or 68060 with an FPU, hard float as GFOpenGPU's SDL kit is; 256 KB
  stack; the game's drawer is its current directory while it runs.

## Build

    STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

## Tests

    make -C tests test

- `test-part.sh`: the Part file.
- `host-ts.sh`: the game built for the PC from the same sources, patches and
  settings, then:
  - `smoke.c`: the whole game on SDL 2's dummy drivers, played by timed key
    presses: the title screen, New game, flying in space; each checked by the
    game's state and the frames really drawn.
  - `display_test.c`: `ts_display.c`'s settings and colour count.
  - `save_test.c`: the save folder, and a save written and read back.

## Licences and source

This repository is MIT. TriSpace and fk-engine-core are AGPL-3 (LICENSE in
the drawer); their source is at github.com/robbi-blechdose/TriSpace and
github.com/robbi-blechdose/fk-engine-core, at the commits in trispace.lock,
and this repository holds every change made to them (patches/). TinyGL is
under its own zlib-style licence (LICENSE.TinyGL). The game's sounds and
music are from OpenGameArt and Wikimedia Commons as res/credits.txt lists.

Team 3
