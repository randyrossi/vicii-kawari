#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"


#define SL 3   // start line
#define NUM_PRESETS 3

static struct regs r;

static char* color_name[16];

static int current_colors[64];
static int preset_num = 0;

static unsigned int preset[NUM_PRESETS][64] = {
{
  0x00,0x00,0x00,0x00, 0xff,0xff,0xff,0x00, 0xaf,0x2a,0x29,0x00, 0x62,0xd8,0xcc,0x00,
  0xb0,0x3f,0xb6,0x00, 0x4a,0xc6,0x4a,0x00, 0x37,0x39,0xc4,0x00, 0xe4,0xed,0x4e,0x00,
  0xb6,0x59,0x1c,0x00, 0x68,0x38,0x08,0x00, 0xea,0x74,0x6c,0x00, 0x4d,0x4d,0x4d,0x00,
  0x84,0x84,0x84,0x00, 0xa6,0xfa,0x9e,0x00, 0x70,0x7c,0xe6,0x00, 0xb6,0xb6,0xb5,0x00,
},
{
  0x00,0x00,0x00,0x00, 0xFF,0xFF,0xFF,0x00, 0x67,0x37,0x2B,0x00, 0x70,0xA3,0xB1,0x00,
  0x6F,0x3D,0x86,0x00, 0x58,0x8C,0x42,0x00, 0x34,0x28,0x79,0x00, 0xB7,0xC6,0x6E,0x00,
  0x6F,0x4E,0x25,0x00, 0x42,0x38,0x00,0x00, 0x99,0x66,0x59,0x00, 0x43,0x43,0x43,0x00,
  0x6B,0x6B,0x6B,0x00, 0x9A,0xD1,0x83,0x00, 0x6B,0x5E,0xB5,0x00, 0x95,0x95,0x95,0x00,
},
{
  0x00,0x00,0x00,0x00, 0xFF,0xFF,0xFF,0x00, 0x68,0x37,0x2b,0x00, 0x70,0xa4,0xb2,0x00,
  0x6f,0x3d,0x86,0x00, 0x58,0x8d,0x43,0x00, 0x35,0x28,0x79,0x00, 0xb8,0xc7,0x6f,0x00,
  0x6f,0x4f,0x25,0x00, 0x43,0x39,0x00,0x00, 0x9a,0x67,0x59,0x00, 0x44,0x44,0x44,0x00,
  0x6c,0x6c,0x6c,0x00, 0x9a,0xd2,0x84,0x00, 0x6c,0x5e,0xb5,0x00, 0x95,0x95,0x95,0x00,
}
};

void save_changes(void)
{
   int reg;
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);
   for (reg=64;reg<128;reg++) {
      if (reg % 4 == 3) continue;
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, PEEK(VIDEO_MEM_1_VAL));
   }
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) & ~VMEM_FLAG_PERSIST_BIT);
}

void main_menu(void)
{
    int key;
    int color;
    int color_cursor = 0;
    int red, green, blue;
    int v;
    int refresh_all = 1;
    int store_current = 1;

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
        printf ("\nWARNING: Save lock bit is set on PCB!\n");
        printf ("Changes cannot be saved.\n");
        printf ("Press any key to continue.\n");
        WAITKEY;
    }

    CLRSCRN;
    printf ("VIC-II Kawari RGB Color Editor\n\n");
 
    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

    printf ("                R  G  B\n");
    for (color=0; color < 16; color++) {
        POKE(646,1);
	printf ("%s ", color_name[color]);
        POKE(646,color);
	printf ("%c      %c", 18, 146);
        POKE(646,1);
	printf ("\n");
    }

    printf ("\n");
    printf ("Press S to save changes\n");
    printf ("Press R to revert changes\n");
    printf ("Press N for next preset\n");
    printf ("Press Q to quit\n");

    for (;;) {

        if (refresh_all) {
            for (color=0; color < 16; color++) {
	        POKE(VIDEO_MEM_1_LO, color*4+64);
	        red = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, color*4+1+64);
	        green = PEEK(VIDEO_MEM_1_VAL);
	        POKE(VIDEO_MEM_1_LO, color*4+2+64);
	        blue = PEEK(VIDEO_MEM_1_VAL);
                TOXY(16,SL+color);
	        printf ("%02x %02x %02x", red, green, blue);
		if (store_current) {
	           current_colors[color*4] = red;
	           current_colors[color*4+1] = green;
	           current_colors[color*4+2] = blue;
		}
            }
	    refresh_all = 0;
	    store_current = 0;
       }

       POKE(VIDEO_MEM_1_LO, color_cursor+64);
       v = PEEK(VIDEO_MEM_1_VAL);

       // Hi-lite cursor
       TOXY(16+(color_cursor%4)*3,SL+color_cursor/4);
       printf ("%c%02x%c",18,v,146);

       WAITKEY;
       key = r.a;

       // Un-hi-lite cursor
       TOXY(16+(color_cursor%4)*3,SL+color_cursor/4);
       printf ("%02x",v);

       if (key == CRSR_DOWN) {
	    color_cursor+=4;
	    if (color_cursor > 62) color_cursor=62;
       }
       else if (key == CRSR_UP)  {
	    color_cursor-=4;
	    if (color_cursor < 0) color_cursor=0;
       }
       else if (key == CRSR_LEFT)  {
	    color_cursor-=1;
	    if (color_cursor % 4 == 3) color_cursor+=1;
	    if (color_cursor < 0) color_cursor = 0;
       }
       else if (key == CRSR_RIGHT)  {
	    color_cursor+=1;
	    if (color_cursor % 4 == 3) color_cursor-=1;
	    if (color_cursor > 62) color_cursor = 62;
       }
       else if (key == '+')  {
	    v=v+1;
	    if (v > 63) v=63;
	    POKE(VIDEO_MEM_1_VAL, v);
       }
       else if (key == '-')  {
	    v=v-1;
	    if (v < 0) v=0;
	    POKE(VIDEO_MEM_1_VAL, v);
       }
       else if (key == 'r')  {
            for (color=0; color < 16; color++) {
	        POKE(VIDEO_MEM_1_LO, color*4+64);
	        POKE(VIDEO_MEM_1_VAL, current_colors[color*4]);
	        POKE(VIDEO_MEM_1_LO, color*4+1+64);
	        POKE(VIDEO_MEM_1_VAL, current_colors[color*4+1]);
	        POKE(VIDEO_MEM_1_LO, color*4+2+64);
	        POKE(VIDEO_MEM_1_VAL, current_colors[color*4+2]);
            }
	    refresh_all = 1;
       }
       else if (key == 'n')  {
            for (color=0; color < 16; color++) {
	        POKE(VIDEO_MEM_1_LO, color*4+64);
	        POKE(VIDEO_MEM_1_VAL, preset[preset_num][color*4]>>2); // top6
	        POKE(VIDEO_MEM_1_LO, color*4+1+64);
	        POKE(VIDEO_MEM_1_VAL, preset[preset_num][color*4+1]>>2); // top6
	        POKE(VIDEO_MEM_1_LO, color*4+2+64);
	        POKE(VIDEO_MEM_1_VAL, preset[preset_num][color*4+2]>>2); // top6
            }
	    preset_num = (preset_num + 1) % NUM_PRESETS;
	    refresh_all = 1;
       }
       else if (key == 's')  {
	    save_changes();
	    store_current = 1;
	    refresh_all = 1;
       }
       else if (key == 'q')  {
            CLRSCRN;
	    return;
       }
    }
}
