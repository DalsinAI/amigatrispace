#!/bin/sh
# Builds TriSpace, the Elite-like space game, for GFOS (AmigaOS 3.2.3 with
# GFOpenUp) with a stove: a 68040 or 68060 with its FPU, TinyGL drawing the
# 3D in software into a 240x240 16-bit frame, shown, played and heard through
# GFOpenGPU's SDL 2 (the stove's SDL2, SDL2_mixer and SDL2_image link stubs;
# SDL2.module at run time), hard float as that kit is.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# TriSpace, its engine fk-engine-core and TinyGL are fetched at the commits
# trispace.lock gives; nothing third-party is kept here. The PC tests
# (tests/host-ts.sh: the same game played by timed keys on SDL 2's dummy
# drivers, and unit tests) run first when the PC has a compiler and SDL 2
# with SDL2_mixer and SDL2_image; HOST_TESTS=0 skips them.
# OUT gets Parts/TriSpace: a GFOpenUp part (its Part file and the drawer it
# puts in SYS:Games/TriSpace; it needs the GFOpenGPU part), installed with
#   GFOpenUpTool INSTALL Parts/TriSpace
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/trispace.lock"
. "$HERE/scripts/ts-common.sh"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/amigatrispace/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-8}
# the PC tests run on the PC's own PATH: the stove has an sdl2-config too (GFOS's)
HOST_PATH=$PATH
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# --- the PC tests first: the same sources, played by timed keys ---------------
if [ "${HOST_TESTS:-1}" != 0 ] && (PATH=$HOST_PATH; command -v "${HOST_CC:-cc}") > /dev/null 2>&1; then
    rc=0; PATH=$HOST_PATH WORK="$WORK/host" sh "$HERE/tests/host-ts.sh" > "$WORK/host-tests.log" 2>&1 || rc=$?
    case $rc in
        0) grep -E "checks passed" "$WORK/host-tests.log" ;;
        2) echo "PC tests skipped: $(tail -1 "$WORK/host-tests.log")" ;;
        *) tail -30 "$WORK/host-tests.log"; exit 1 ;;
    esac
fi

# --- SDL 2, SDL2_mixer and SDL2_image from the stove's SDK -----------------------
SDK="$TC/m68k-amigaos"
for f in include/SDL2/SDL.h include/SDL2/SDL_mixer.h include/SDL2/SDL_image.h \
         lib/libSDL2.a lib/libSDL2_mixer.a lib/libSDL2_image.a; do
    [ -f "$SDK/$f" ] || { echo "the stove has no $f"; exit 2; }
done

# --- TriSpace, fk-engine-core and TinyGL at their pinned commits, patches/ -----
SRC="$WORK/src"
ts_source "$SRC"
G="$SRC/TriSpace"

# --- compile -------------------------------------------------------------------
LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
CPU="-m68040 -m68881"
# no loops turned into memset/memcpy calls (GCC 16), address 0 is memory;
# stb_image's thread-local flip flag would pull in libgcc's emutls (pthreads,
# which libnix has not): the game loads images on one task only
CF="-noixemul $CPU -O2 -fomit-frame-pointer -fno-tree-loop-distribute-patterns -fno-delete-null-pointer-checks $LATE \
 -std=gnu99 -DSTBI_NO_THREAD_LOCALS -Werror=implicit-function-declaration -I$HERE/amiga/compat -I$HERE/amiga -I$SRC/tinygl/include -I$G/src \
 -I$SDK/include/SDL2 -DTS_VERSION=\\\"$TS_VERSION\\\" -DTS_DATE=\\\"$(date -u +%d.%m.%Y)\\\""
O="$WORK/obj"
# objects are remade when the sources or the flags change
STAMP="$(cat "$SRC/.patched") $(echo "$CF" | sha256sum | cut -c1-16)"
[ "$(cat "$O/.src" 2>/dev/null)" = "$STAMP" ] || { rm -rf "$O"; mkdir -p "$O"; echo "$STAMP" > "$O/.src"; }
M="$O/Makefile"
{
    echo "CF = $CF"
    A=""
    for f in $TGL_SRCS; do
        o="tgl_${f%.c}.o"; A="$A $o"
        printf '%s: %s\n\tm68k-amigaos-gcc $(CF) -w -MMD -c $< -o $@\n' "$o" "$SRC/tinygl/src/$f"
    done
    for f in $(ts_game_srcs "$SRC"); do
        o="$(echo "$f" | tr / _ | sed 's/\.c$/.o/')"; A="$A $o"
        extra=""; [ "$f" = src/main.c ] && extra="-Dmain=ts_game_main"
        printf '%s: %s\n\tm68k-amigaos-gcc $(CF) %s -w -MMD -c $< -o $@\n' "$o" "$G/$f" "$extra"
    done
    for f in ts_display amiga_start; do
        A="$A $f.o"
        printf '%s.o: %s\n\tm68k-amigaos-gcc $(CF) -Wall -MMD -c $< -o $@\n' "$f" "$HERE/amiga/$f.c"
    done
    echo "OBJS =$A"
    echo "all: \$(OBJS)"
    echo "-include *.d"
} > "$M"
(cd "$O" && nice -n 19 make -k -j"$JOBS" all > make.log 2>&1) || { grep -E 'error:' "$O/make.log" | sed 's#^.*/##' | sort | uniq -c | sort -rn | head -100; exit 1; }
echo "compile: $(( $(date +%s) - t0 )) s"

# --- link ------------------------------------------------------------------------
# -lpthread: the stove's libgcc and SDL 2 build on its pthreads
# shellcheck disable=SC2046
m68k-amigaos-gcc -noixemul $CPU -o "$O/TriSpace.debug" \
    $(cd "$O" && for f in $(sed -n 's/^OBJS =//p' Makefile); do echo "$O/$f"; done) \
    -L"$SDK/lib" -lSDL2_mixer -lSDL2_image -lSDL2 -lm -lpthread > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/TriSpace --------------------------------------------
P="$OUT/Parts/TriSpace"; D="$P/Games/TriSpace"; rm -rf "$P"; mkdir -p "$D"
m68k-amigaos-strip -o "$D/TriSpace" "$O/TriSpace.debug"
cp -R "$G/res" "$D/res"
cp "$HERE/README.md" "$D/ReadMe"
cp "$G/LICENSE" "$D/LICENSE"
cp "$SRC/tinygl/LICENSE" "$D/LICENSE.TinyGL"
sh "$HERE/scripts/write-part.sh" "$P" "$TS_VERSION"
ls -l "$D/TriSpace"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
