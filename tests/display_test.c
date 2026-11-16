/* PC unit test for amiga/ts_display.c's settings and pixel count.
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <stdio.h>
#include "ts_display.h"

static int fails, checks;
#define CHECK(c) do { checks++; if (!(c)) { printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #c); fails++; } } while (0)

int main(void)
{
    unsigned short px[4 * 3] = {0, 1, 0, 0,  0, 0, 0xf81f, 0,  9, 0, 0, 0};
    CHECK(ts_display_scale(NULL) == 2);
    CHECK(ts_display_scale("") == 2);
    CHECK(ts_display_scale("1") == 1);
    CHECK(ts_display_scale("6") == 6);
    CHECK(ts_display_scale("7") == 2);
    CHECK(ts_display_scale("0") == 2);
    CHECK(ts_display_scale("x") == 2);
    CHECK(!ts_display_fullscreen(NULL));
    CHECK(!ts_display_fullscreen("0"));
    CHECK(ts_display_fullscreen("1"));
    CHECK(ts_display_colour_count(px, 4, 3, 8) == 4);   /* 0, 1, 0xf81f, 9 */
    CHECK(ts_display_colour_count(px, 2, 3, 8) == 3);   /* a narrower window: 0, 1, 9 */
    CHECK(ts_display_colour_count(px, 4, 1, 8) == 2);
    CHECK(ts_display_colour_count(px, 1, 2, 8) == 1);
    if (!fails) printf("display: all %d checks passed\n", checks);
    return fails != 0;
}
