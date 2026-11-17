/* TriSpace's screen on SDL 2: TinyGL draws a WxH RGB565 frame into
 * ts_display_pixels(); ts_display_present() shows it in a window scaled to
 * fit (nearest pixel, aspect kept). MIT, Copyright (c) 2026 AmiCradle Team. */
#ifndef TS_DISPLAY_H
#define TS_DISPLAY_H

/* 1 when the window, renderer and texture are up */
int ts_display_open(int w, int h);
void* ts_display_pixels(void);
int ts_display_pitch(void);
void ts_display_present(void);
void ts_display_close(void);

/* the window's scale from the frame size: TRISPACE_SCALE (1 to 6) if set,
   else 2; and whether TRISPACE_FULLSCREEN=1 asks for the whole screen */
int ts_display_scale(const char* env);
int ts_display_fullscreen(const char* env);

/* for the tests: frames shown, and when ts_display_count is set, the last
   frame's number of distinct colours and a checksum of it */
extern int ts_display_count;
unsigned long ts_display_frames(void);
unsigned long ts_display_colours(void);
unsigned long ts_display_sum(void);
unsigned long ts_display_colour_count(const unsigned short* px, int w, int h, int pitch);
#endif
