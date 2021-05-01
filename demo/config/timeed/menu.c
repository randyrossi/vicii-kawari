#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

#define SL 4   // start line
#define NUM_PRESETS 2

struct regs r;

int current_start[4];
int current_fp[4];
int current_sync[4];
int current_bp[4];

int defaults[] = {
	// ntsc
        0,  // start   0
        10,  // fporch  10
        60,  // sync  60
        10,  // bporch  10
        11,  // start  11
        8,  // fporch   8
        3,  // sync   3
        2,  // bporch   2

	// pal
        0,  // start   0
        10,  // fporch  10
        60,  // sync  60
        20,  // bporch  20
        29,  // start  29 (+256)
        5,  // fporch   5
        2,  // sync   2
        20,  // bporch  20
};

void save_changes(void)
{
   int reg;
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);
   for (reg=0xd0;reg<0xd0+16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, PEEK(VIDEO_MEM_1_VAL));
   }
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) & ~VMEM_FLAG_PERSIST_BIT);
}

void main_menu(void)
{
    int key;
    int side = 0;
    int res_cursor = 0;
    int start, fp, sync, bp;
    int v;
    int refresh_all = 1;
    int store_current = 1;
    int res;
    int timing_changed = 0;

    CLRSCRN;
    printf ("VIC-II Kawari HDMI/VGA Timing Editor\n\n");
 
    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

    POKE(646,1);
    printf ("             Start  Front  Sync   Back\n");
    printf ("                    Porch  Pulse  Porch\n");
    printf ("NTSC Horiz\n");
    printf ("NTSC Vert\n");
    printf ("PAL  Horiz\n");
    printf ("PAL  Vert\n");

    printf ("\n");
    printf ("S to save changes\n");
    printf ("A to apply new timing\n");
    printf ("R to revert changes\n");
    printf ("D for defaults\n");
    printf ("Q to quit changes\n\n");
    printf ("If applying a change makes the display\n");
    printf ("drop out, press R to revert to last\n");
    printf ("saved values and then A to apply them\n");
    printf ("Or press D for defaults, then A.\n");

    for (;;) {

        if (refresh_all) {
            for (res=0; res < 4; res++) {
	        POKE(VIDEO_MEM_1_LO, 0xd0 + res*4);
	        start = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, 0xd0 + res*4+1);
	        fp = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, 0xd0 + res*4+2);
	        sync = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, 0xd0 + res*4+3);
	        bp = PEEK(VIDEO_MEM_1_VAL);
                TOXY(13,SL+res);
	        printf ("%03d    %03d    %03d    %03d", start, fp, sync, bp);
		if (store_current) {
	           current_start[res] = start;
	           current_fp[res] = fp;
	           current_sync[res] = sync;
	           current_bp[res] = bp;
		}
            }

	    refresh_all = 0;
	    store_current = 0;
       }

       // Hi-lite cursor
       POKE(VIDEO_MEM_1_LO, 0xd0 + res_cursor);
       v = PEEK(VIDEO_MEM_1_VAL);
       TOXY(13+(res_cursor%4)*7,SL+res_cursor/4);
       printf ("%c%03d%c",18,v,146);

       WAITKEY;
       key = r.a;

       // un-hi-lite cursor
       TOXY(13+(res_cursor%4)*7,SL+res_cursor/4);
       printf ("%03d",v);

       if (key == CRSR_DOWN) {
	    res_cursor+=4;
	    if (res_cursor > 15) res_cursor=15;
       }
       else if (key == CRSR_UP)  {
	    res_cursor-=4;
	    if (res_cursor < 0) res_cursor=0;
       }
       else if (key == CRSR_LEFT)  {
	    res_cursor-=1;
	    if (res_cursor < 0) res_cursor = 0;
       }
       else if (key == CRSR_RIGHT)  {
	    res_cursor+=1;
	    if (res_cursor > 15) res_cursor = 15;
       }
       else if (key == '+')  {
	    v=v+1;
	    if (v > 255) v=0;
	    POKE(VIDEO_MEM_1_VAL, v);
       }
       else if (key == '-')  {
	    v=v-1;
	    if (v < 0) v=0;
	    POKE(VIDEO_MEM_1_VAL, v);
       }
       else if (key == 'r')  {
            for (res=0; res < 8; res++) {
	        POKE(VIDEO_MEM_1_LO, 0xd0+res*4);
	        POKE(VIDEO_MEM_1_VAL, current_start[res]);
	        POKE(VIDEO_MEM_1_LO, 0xd0+res*4+1);
	        POKE(VIDEO_MEM_1_VAL, current_fp[res]);
	        POKE(VIDEO_MEM_1_LO, 0xd0+res*4+2);
	        POKE(VIDEO_MEM_1_VAL, current_sync[res]);
	        POKE(VIDEO_MEM_1_LO, 0xd0+res*4+3);
	        POKE(VIDEO_MEM_1_VAL, current_bp[res]);
            }
	    refresh_all = 1;
       }
       else if (key == 's')  {
	    save_changes();
	    store_current = 1;
	    refresh_all = 1;
       }
       else if (key == 'a')  {
	    POKE(VIDEO_MEM_1_LO, TIMING_CHANGE);
	    POKE(VIDEO_MEM_1_VAL, timing_changed);
	    timing_changed = 1-timing_changed;
       }
       else if (key == 'd')  {
            for (res=0; res < 16; res++) {
	        POKE(VIDEO_MEM_1_LO, 0xd0+res);
	        POKE(VIDEO_MEM_1_VAL, defaults[res]);
	        refresh_all = 1;
	    }
       }
       else if (key == 'q')  {
            CLRSCRN;
	    return;
       }
    }
}
