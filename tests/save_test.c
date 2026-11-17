/* PC unit test for patches/0002 (fk-engine-core's savegame.c): the folder is
 * made, a save is written and read back, a missing HOME falls back to ".".
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include "savegame.h"

static int fails, checks;
#define CHECK(c) do { checks++; if (!(c)) { printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #c); fails++; } } while (0)

int main(int argc, char** argv)
{
    char path[512];
    unsigned int v = 0x12345678, r = 0;
    struct stat st;
    if (argc < 2) return 2;
    setenv("HOME", argv[1], 1);
    CHECK(!openSave(".tstest", "none.sav", 0));          /* nothing saved yet */
    snprintf(path, sizeof(path), "%s/.tstest", argv[1]);
    CHECK(stat(path, &st) == 0 && S_ISDIR(st.st_mode));   /* the folder is made */
    CHECK(openSave(".tstest", "game.sav", 1));
    writeElement(&v, sizeof(v));
    closeSave();
    CHECK(openSave(".tstest", "game.sav", 0));
    readElement(&r, sizeof(r));
    closeSave();
    CHECK(r == v);
    snprintf(path, sizeof(path), "%s/.tstest/game.sav", argv[1]);
    CHECK(stat(path, &st) == 0 && st.st_size == 4);
    unsetenv("HOME");
    CHECK(chdir(argv[1]) == 0);
    CHECK(openSave("nohome", "x.sav", 1));
    closeSave();
    CHECK(access("nohome/x.sav", F_OK) == 0);
    if (!fails) printf("saves: all %d checks passed\n", checks);
    return fails != 0;
}
