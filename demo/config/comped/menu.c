#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

#define SL 3   // start line
#define NUM_PRESETS 2

struct regs r;

char* color_name[16];

int current_luma[16];
int current_phase[16];
int current_amplitude[16];
int current_black_level;
int current_color_burst;
int preset_num = 0;

void save_changes(void)
{
   int reg;
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);
   for (reg=0xa0;reg<=0xcf;reg++) {
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, PEEK(VIDEO_MEM_1_VAL));
   }
   reg = BLACK_LEVEL;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, PEEK(VIDEO_MEM_1_VAL));
   reg = BURST_AMPLITUDE;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, PEEK(VIDEO_MEM_1_VAL));
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) & ~VMEM_FLAG_PERSIST_BIT);
}

void main_menu(void)
{
    int key;
    int side = 0;
    int color;
    int color_cursor = 0;
    int other_cursor = 0;
    int cursor_mod_4;
    int luma, phase, amplitude;
    int v;
    int refresh_all = 1;
    int store_current = 1;
    int border = PEEK(53280L);
    int background = PEEK(53281L);

    color_name[0] = "black  ";
    color_name[1] = "white  ";
    color_name[2] = "red    ";
    color_name[3] = "cyan   ";
    color_name[4] = "purple ";
    color_name[5] = "green  ";
    color_name[6] = "blue   ";
    color_name[7] = "yellow ";
    color_name[8] = "orange ";
    color_name[9] = "brown  ";
    color_name[10] = "pink   ";
    color_name[11] = "d. gray";
    color_name[12] = "gray   ";
    color_name[13] = "l.green";
    color_name[14] = "l.blue ";
    color_name[15] = "l.gray ";

    if (SAVES_LOCKED) {
        printf ("\nWARNING: Lock bit is set on PCB!\n");
        printf ("Changes cannot be saved.\n");
        printf ("Press any key to continue.\n");
        WAITKEY;
    }

    CLRSCRN;
    printf ("VIC-II Kawari Composite Settings Editor\n\n");
 
    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

    printf ("                Lu PH Amp  Black Color\n");
    for (color=0; color < 16; color++) {
        POKE(646,1);
	printf ("%s ", color_name[color]);
        POKE(646,color);
	printf ("%c      %c", 18, 146);
        POKE(646,1);
	if (color == 0)
           printf ("             Level Burst");
	printf ("\n");
    }

    printf ("\n");
    printf ("S to save changes    %c to switch sides\n",95);
    printf ("R to revert changes  B inc brd color\n");
    printf ("N for next preset    G inc bg color\n");
    printf ("Q to quit\n");

    for (;;) {

        if (refresh_all) {
            for (color=0; color < 16; color++) {
	        POKE(VIDEO_MEM_1_LO, 0xa0 + color);
	        luma = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, 0xb0 + color);
	        phase = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, 0xc0 + color);
	        amplitude = PEEK(VIDEO_MEM_1_VAL);
                TOXY(16,SL+color);
	        printf ("%02x %02x %02x", luma, phase, amplitude);
		if (store_current) {
	           current_luma[color] = luma;
	           current_phase[color] = phase;
	           current_amplitude[color] = amplitude;
		}
            }

            POKE(VIDEO_MEM_1_LO, BLACK_LEVEL);
            v = PEEK(VIDEO_MEM_1_VAL);
            if (store_current)
               current_black_level = v;
            TOXY(27,4);
            printf ("%02x",v);

            POKE(VIDEO_MEM_1_LO, BURST_AMPLITUDE);
            v = PEEK(VIDEO_MEM_1_VAL);
            if (store_current)
               current_color_burst = v;
            TOXY(34,4);
            printf ("%02x",v);

	    refresh_all = 0;
	    store_current = 0;
       }

       // Hi-lite cursor
       if (side == 0) {
          POKE(VIDEO_MEM_1_LO, 0xa0 + 16*(color_cursor%4) + color_cursor/4);
          v = PEEK(VIDEO_MEM_1_VAL);
          TOXY(16+(color_cursor%4)*3,SL+color_cursor/4);
       } else {
          POKE(VIDEO_MEM_1_LO, BLACK_LEVEL + other_cursor);
          v = PEEK(VIDEO_MEM_1_VAL);
          TOXY(27+other_cursor*7,4);
       }
       printf ("%c%02x%c",18,v,146);

       WAITKEY;
       key = r.a;

       // un-hi-lite cursor
       if (side == 0) {
          TOXY(16+(color_cursor%4)*3,SL+color_cursor/4);
       } else {
          TOXY(27+other_cursor*7,4);
       }
       printf ("%02x",v);

       if (key == CRSR_DOWN) {
            if (side == 0) {
	       color_cursor+=4;
	       if (color_cursor > 62) color_cursor=62;
	    }
       }
       else if (key == CRSR_UP)  {
            if (side == 0) {
	       color_cursor-=4;
	       if (color_cursor < 0) color_cursor=0;
	    }
       }
       else if (key == CRSR_LEFT)  {
            if (side == 0) {
	       color_cursor-=1;
	       if (color_cursor % 4 == 3) color_cursor+=1;
	       if (color_cursor < 0) color_cursor = 0;
	    } else {
               other_cursor = 1- other_cursor;
	    }
       }
       else if (key == CRSR_RIGHT)  {
            if (side == 0) {
	       color_cursor+=1;
	       if (color_cursor % 4 == 3) color_cursor-=1;
	       if (color_cursor > 62) color_cursor = 62;
	    } else {
               other_cursor = 1- other_cursor;
	    }
       }
       else if (key == '+')  {
	    v=v+1;
	    if (side == 0) {
	       cursor_mod_4 = color_cursor % 4;
	       if (cursor_mod_4 == 0 && v > 63) v=63;
	       else if (cursor_mod_4 == 1 && v > 255) v=255;
	       else if (cursor_mod_4 == 2 && v > 15) v=15;
	    } else {
               if (other_cursor == 0) {
                    if (v > 63) v = 63;
	       }
	       else {
                    if (v > 15) v = 15;
	       }
	    }
	    POKE(VIDEO_MEM_1_VAL, v);
       }
       else if (key == '-')  {
	    v=v-1;
	    if (v < 0) v=0;
	    POKE(VIDEO_MEM_1_VAL, v);
       }
       else if (key == 'r')  {
            for (color=0; color < 16; color++) {
	        POKE(VIDEO_MEM_1_LO, 0xa0+color);
	        POKE(VIDEO_MEM_1_VAL, current_luma[color]);
	        POKE(VIDEO_MEM_1_LO, 0xb0+color);
	        POKE(VIDEO_MEM_1_VAL, current_phase[color]);
	        POKE(VIDEO_MEM_1_LO, 0xc0+color);
	        POKE(VIDEO_MEM_1_VAL, current_amplitude[color]);
            }
            POKE(VIDEO_MEM_1_LO, BLACK_LEVEL);
	    POKE(VIDEO_MEM_1_VAL, current_black_level);
            POKE(VIDEO_MEM_1_LO, BURST_AMPLITUDE);
	    POKE(VIDEO_MEM_1_VAL, current_color_burst);
	    refresh_all = 1;
       }
       else if (key == 'n')  {
            for (color=0; color < 16; color++) {
	        POKE(VIDEO_MEM_1_LO, 0xa0+color);
	        //POKE(VIDEO_MEM_1_VAL, preset_luma[preset_num][color];
	        POKE(VIDEO_MEM_1_LO, 0xb0+color);
	        //POKE(VIDEO_MEM_1_VAL, preset_phase[preset_num][color];
	        POKE(VIDEO_MEM_1_LO, 0xc0+color);
	        //POKE(VIDEO_MEM_1_VAL, preset_amplitude[preset_num][color];
            }
	    preset_num = (preset_num + 1) % NUM_PRESETS;
	    refresh_all = 1;
       }
       else if (key == 's')  {
	    save_changes();
	    store_current = 1;
	    refresh_all = 1;
       }
       else if (key == 95)  {
            side = 1 - side;
       }
       else if (key == 'q')  {
            CLRSCRN;
	    return;
       }
       else if (key == 'b')  {
	    border = (border + 1 ) % 16;
            POKE(53280L, border);
       }
       else if (key == 'g')  {
	    background = (background + 1 ) % 16;
            POKE(53281L, background);
       }
    }
}
