#!/bin/sh
# PC test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
D="$T/Games/TriSpace"; mkdir -p "$D/res/obj/ships" "$D/res/music"
: > "$D/TriSpace"; : > "$D/ReadMe"; : > "$D/res/obj/ships/Ship.obj"; : > "$D/res/music/Blue_Danube.ogg"
sh "$HERE/../scripts/write-part.sh" "$T" 1.1.2
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part TriSpace 1.1.2'
expect 'needs 68040'
expect 'needs part GFOpenGPU'
expect 'copy "Games/TriSpace/TriSpace" "SYS:Games/TriSpace/TriSpace"'
expect 'copy "Games/TriSpace/res/obj/ships/Ship.obj" "SYS:Games/TriSpace/res/obj/ships/Ship.obj"'
expect 'copy "Games/TriSpace/res/music/Blue_Danube.ogg" "SYS:Games/TriSpace/res/music/Blue_Danube.ogg"'
[ "$(head -1 "$T/Part")" = 'part TriSpace 1.1.2' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 4 ] || { echo "FAIL: file count"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 1.1.2
[ "$(grep -c '^copy' "$T/Part")" = 4 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
