#!/bin/sh
# TriSpace built for the PC the way build-amiga.sh builds it for GFOS (the
# same sources, patches/, TinyGL settings, amiga/compat and ts_display.c),
# then:
#   smoke.c: the whole game on SDL 2's dummy drivers, played by timed keys
#            (title screen, New game, flying in space; frames really drawn)
#   display_test.c: ts_display.c's settings and pixel count
#   save_test.c: patches/0002's save folder and a save written and read back
#   sh tests/host-ts.sh     (WORK=... keeps the build somewhere else)
# Exit 2: no PC SDL 2 with SDL2_mixer and SDL2_image to build against.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$HERE/trispace.lock"
. "$HERE/scripts/ts-common.sh"
WORK=${WORK:-"$HERE/build-host"}; CC=${HOST_CC:-cc}
mkdir -p "$WORK"; WORK=$(cd "$WORK" && pwd)
# a PC SDL 2 with SDL2_mixer and SDL2_image: the first sdl2-config whose
# flags build and link a PC program (a stove's would give -noixemul ...)
SDL2_CONFIG=""
printf '#include <SDL.h>\n#include <SDL_mixer.h>\n#include <SDL_image.h>\nint main(int c, char **v) { (void)c; (void)v; return SDL_Init(0) < 0 || !Mix_Linked_Version() || !IMG_Linked_Version(); }\n' > "$WORK/sdlprobe.c"
for s in ${HOST_SDL2_CONFIG:-} /usr/bin/sdl2-config /usr/local/bin/sdl2-config "$(command -v sdl2-config || true)"; do
    [ -n "$s" ] && [ -x "$s" ] || continue
    # shellcheck disable=SC2046
    if $CC $("$s" --cflags) -o "$WORK/sdlprobe" "$WORK/sdlprobe.c" $("$s" --libs) -lSDL2_mixer -lSDL2_image > /dev/null 2>&1; then SDL2_CONFIG=$s; break; fi
done
[ -n "$SDL2_CONFIG" ] || { echo "no PC SDL 2 with SDL2_mixer and SDL2_image: the PC tests need their development files"; exit 2; }

SRC="$WORK/src"
ts_source "$SRC"
G="$SRC/TriSpace"
INC="-I$HERE/amiga/compat -I$HERE/amiga -I$SRC/tinygl/include -I$G/src $($SDL2_CONFIG --cflags)"
O="$WORK/obj"; rm -rf "$O"; mkdir -p "$O"
objs=""
for f in $TGL_SRCS; do
    # shellcheck disable=SC2086
    $CC -O2 -w -std=gnu99 $INC -c "$SRC/tinygl/src/$f" -o "$O/tgl_${f%.c}.o" & objs="$objs $O/tgl_${f%.c}.o"
done
for f in $(ts_game_srcs "$SRC"); do
    o="$O/$(echo "$f" | tr / _ | sed 's/\.c$/.o/')"
    extra=""; [ "$f" = src/main.c ] && extra="-Dmain=ts_game_main"
    # shellcheck disable=SC2086
    $CC -O2 -w -std=gnu99 -Werror=implicit-function-declaration $extra $INC -c "$G/$f" -o "$o" & objs="$objs $o"
done
wait
# shellcheck disable=SC2086
$CC -O2 -Wall $INC -c "$HERE/amiga/ts_display.c" -o "$O/ts_display.o"
# shellcheck disable=SC2086
$CC -O2 -Wall $INC -o "$WORK/smoke" "$HERE/tests/smoke.c" $objs "$O/ts_display.o" \
    $($SDL2_CONFIG --libs) -lSDL2_mixer -lSDL2_image -lm

fail=0
# the game opens res/... from its own directory, as from its drawer on GFOS
(cd "$G" && HOME="$WORK" "$WORK/smoke") || fail=1
# shellcheck disable=SC2086
$CC -Wall -I"$HERE/amiga" -o "$WORK/display_test" "$HERE/tests/display_test.c" "$HERE/amiga/ts_display.c" \
    $($SDL2_CONFIG --cflags) $($SDL2_CONFIG --libs) && "$WORK/display_test" || fail=1
T=$(mktemp -d)
$CC -Wall -I"$G/src/fk-engine-core" -o "$WORK/save_test" "$HERE/tests/save_test.c" "$G/src/fk-engine-core/savegame.c" \
    && "$WORK/save_test" "$T" || fail=1
rm -rf "$T"
exit $fail
