# What build-amiga.sh (the stove) and tests/host-ts.sh (the PC) share:
# fetching TriSpace, its engine and TinyGL at trispace.lock's commits with
# patches/, TinyGL's feature settings, and the list of sources.
# Sourced; needs HERE (the repo) and trispace.lock's settings.
# MIT, Copyright (c) 2026 AmiCradle Team.

# a repository at one commit, fetched once: fetch_at DIR URL COMMIT
fetch_at() {
    if [ "$(git -C "$1" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${1:?}"; mkdir -p "$1"
        git -C "$1" init -q
        git -C "$1" fetch -q --depth 1 "$2" "$3"
        git -C "$1" checkout -q FETCH_HEAD
        [ "$(git -C "$1" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# TriSpace with fk-engine-core in src/fk-engine-core and TinyGL beside it
# (DIR/tinygl), patches/ applied, into $1 (redone when anything changes)
ts_source() {
    PSUM=$( (cat "$HERE"/patches/*.patch; echo "$TS_COMMIT $FKC_COMMIT $TGL_COMMIT") | sha256sum | cut -c1-16)
    if [ "$(cat "$1/.patched" 2>/dev/null)" != "$PSUM" ]; then
        rm -rf "$1"; mkdir -p "$1"
        fetch_at "$1/.dl/trispace" "$TS_GIT" "$TS_COMMIT"
        fetch_at "$1/.dl/fkcore" "$FKC_GIT" "$FKC_COMMIT"
        fetch_at "$1/.dl/tinygl" "$TGL_GIT" "$TGL_COMMIT"
        mkdir -p "$1/TriSpace" "$1/tinygl"
        (cd "$1/.dl/trispace" && git archive HEAD) | tar -x -C "$1/TriSpace"
        rm -rf "$1/TriSpace/src/fk-engine-core"; mkdir -p "$1/TriSpace/src/fk-engine-core"
        (cd "$1/.dl/fkcore" && git archive HEAD) | tar -x -C "$1/TriSpace/src/fk-engine-core"
        (cd "$1/.dl/tinygl" && git archive HEAD) | tar -x -C "$1/tinygl"
        for p in "$HERE"/patches/*.patch; do
            patch -s -d "$1" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
        done
        ts_tinygl_features "$1/tinygl/include/zfeatures.h"
        echo "$PSUM" > "$1/.patched"
    fi
}

# TinyGL's zfeatures.h as TriSpace needs it (its README): 16-bit RGB565
# frame buffer, 0xf81f (magenta) the texture colour not drawn; no threads
# (no OpenMP on GFOS) and no runtime self-test abort
ts_tinygl_features() {
    sed -i \
        -e 's/^#define TGL_FEATURE_16_BITS .*/#define TGL_FEATURE_16_BITS        1/' \
        -e 's/^#define TGL_FEATURE_32_BITS .*/#define TGL_FEATURE_32_BITS        0/' \
        -e 's/^#define TGL_NO_DRAW_COLOR .*/#define TGL_NO_DRAW_COLOR 0xf81f/' \
        -e 's/^#define TGL_FEATURE_MULTITHREADED_DRAWPIXELS.*/#define TGL_FEATURE_MULTITHREADED_DRAWPIXELS 0/' \
        -e 's/^#define TGL_FEATURE_MULTITHREADED_COPY_TEXIMAGE_2D.*/#define TGL_FEATURE_MULTITHREADED_COPY_TEXIMAGE_2D 0/' \
        "$1"
    for want in 'TGL_FEATURE_16_BITS        1' 'TGL_FEATURE_32_BITS        0' 'TGL_NO_DRAW_COLOR 0xf81f' \
                'TGL_FEATURE_MULTITHREADED_DRAWPIXELS 0' 'TGL_FEATURE_MULTITHREADED_COPY_TEXIMAGE_2D 0'; do
        grep -q "^#define $want\$" "$1" || { echo "zfeatures.h: no '$want'"; exit 1; }
    done
}

# the game's C files (its Makefile's SRCDIR list, fk-engine-core in it)
# and TinyGL's (its src/Makefile's OBJS), relative to the source tree
ts_game_srcs() {
    (cd "$1/TriSpace" && find src -name '*.c' | LC_ALL=C sort)
}
TGL_SRCS="api.c list.c vertex.c init.c matrix.c texture.c misc.c clear.c light.c clip.c
 select.c get.c zbuffer.c zline.c ztriangle.c zmath.c image_util.c msghandling.c
 arrays.c specbuf.c memory.c ztext.c zraster.c accum.c zpostprocess.c"
