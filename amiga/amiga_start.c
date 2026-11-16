/* TriSpace on GFOS: the stack, the $VER string, and the game's drawer as
 * its current directory while it runs (it opens res/... and saves in
 * PROGDIR:Saves, wherever the Shell is), given back when it ends, by exit()
 * too. The game's main() is built as ts_game_main (-Dmain=ts_game_main on
 * the game's main.c only).
 * MIT, Copyright (c) 2026 AmiCradle Team. */
#include <proto/dos.h>
#include <stdlib.h>

unsigned long __stack = 256 * 1024;
static const char version[] __attribute__((used)) =
	"$VER: TriSpace " TS_VERSION " (" TS_DATE ") GFOS";

int ts_game_main(int argc, char** argv);

static BPTR old_dir, prog_dir;

static void ts_leave_progdir(void)
{
	if (prog_dir) {
		CurrentDir(old_dir);
		UnLock(prog_dir);
		prog_dir = 0;
	}
}

int main(int argc, char** argv)
{
	prog_dir = Lock((CONST_STRPTR)"PROGDIR:", SHARED_LOCK);
	if (prog_dir) {
		old_dir = CurrentDir(prog_dir);
		atexit(ts_leave_progdir);
	}
	return ts_game_main(argc, argv);
}
