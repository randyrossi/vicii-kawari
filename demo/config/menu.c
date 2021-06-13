#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "init.h"

static struct regs r;
static int next_model=0;
static int current_model=0;

static int next_display_flags=0;
static int current_display_flags=0;

static int version;
static char variant[16];

static int line = 0;

void get_chip_model(void)
{
   POKE(VIDEO_MEM_1_LO,CHIP_MODEL);
   current_model = PEEK(VIDEO_MEM_1_VAL);
   next_model = current_model;
}

void get_display_flags(void)
{
   POKE(VIDEO_MEM_1_LO,DISPLAY_FLAGS);
   current_display_flags = PEEK(VIDEO_MEM_1_VAL) & 1;
   next_display_flags = current_display_flags;
}

void get_version(void)
{
   POKE(VIDEO_MEM_1_LO,VERSION);
   version = PEEK(VIDEO_MEM_1_VAL);
}

void get_variant(void)
{
   int t=0;
   char v;
   while (t < 16) {
      POKE(VIDEO_MEM_1_LO,VARIANT+t);
      v = PEEK(VIDEO_MEM_1_VAL);
      if (v == 0) break;
      variant[t++] = v;
   }
   variant[t] = 0;
}

void show_chip_model()
{
    TOXY(17,6);
    if  (line == 0) printf ("%c",18);
    switch (next_model) {
        case 0:
            printf ("6567R8  ");   
            break;
        case 1:
            printf ("6569R5  ");   
            break;
        case 2:
            printf ("6567R56A");   
            break;
        default:
            printf ("6569R1  ");   
            break;
    }

    if (current_model != next_model) {
       printf (" (changed)");
    } else {
       printf ("          ");
    }
    if  (line == 0) printf ("%c",146);
}

void show_display_bit(int bit, int y)
{
    int next_val = next_display_flags & bit;
    int current_val = current_display_flags & bit;
    TOXY(17,y);
    if  (line == y-6) printf ("%c",18);
    if (next_val) {
       printf ("ON ");
    } else {
       printf ("OFF");
    }

    if (current_val != next_val) {
       printf (" (changed)");
    } else {
       printf ("          ");
    }
    if  (line == y-6) printf ("%c",146);
}

void save_changes(void)
{
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);
   if (current_display_flags != next_display_flags) {
      POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS);
      SAFE_POKE(VIDEO_MEM_1_VAL, next_display_flags);
      current_display_flags = next_display_flags;
   }
   if (current_model != next_model) {
      POKE(VIDEO_MEM_1_LO, CHIP_MODEL);
      SAFE_POKE(VIDEO_MEM_1_VAL, next_model);
      current_model = next_model;
   }
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) & ~VMEM_FLAG_PERSIST_BIT);
}

void main_menu(void)
{
    int need_refresh = 0;

    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
    get_version();
    get_variant();

    CLRSCRN;
    printf ("VIC-II Kawari Config Utility\n\n");
 
    printf ("Utility Version: %s\n",UTILITY_VERSION);
    printf ("Kawari Version : %d.%d\n",version >> 4, version & 15);
    printf ("Variant        : %s\n",variant);
    printf ("\n");
    printf ("Chip Model     :\n");
    printf ("Raster Lines   :\n");
    printf ("DVI/RGB 15khz  :\n");
    printf ("DVI/RGB 1xWidth:\n");
    printf ("RGB CSYNC      :\n");
    printf ("\n");

    get_chip_model();
    get_display_flags();

    printf ("NOTE: Any changes to chip model will\n");
    printf ("take effect on next cold boot.\n\n");

    printf ("Use CRSR to select a setting\n");
    printf ("Press SPACE to change setting\n");
    printf ("Press S to save\n");
    printf ("Press D for defaults\n");
    printf ("Press Q to quit\n");

    need_refresh = 1;
    for (;;) {
       if (need_refresh) {
          show_chip_model();
          show_display_bit(DISPLAY_SHOW_RASTER_LINES_BIT, 7);
          show_display_bit(DISPLAY_IS_NATIVE_Y_BIT, 8);
          show_display_bit(DISPLAY_IS_NATIVE_X_BIT, 9);
          show_display_bit(DISPLAY_ENABLE_CSYNC_BIT, 10);
          need_refresh = 0;
       }

       WAITKEY;

       if (r.a == 'q') {
          CLRSCRN;
          return;
       } else if (r.a == ' ') {
          if (line == 0) {
             next_model=next_model+1;
             if (next_model > 3) next_model=0;
             show_chip_model();
	  }
          else if (line == 1) {
             next_display_flags ^= DISPLAY_SHOW_RASTER_LINES_BIT;
             show_display_bit(DISPLAY_SHOW_RASTER_LINES_BIT, 7);
	  }
          else if (line == 2) {
             next_display_flags ^= DISPLAY_IS_NATIVE_Y_BIT;
             show_display_bit(DISPLAY_IS_NATIVE_Y_BIT, 8);
	  }
          else if (line == 3) {
             next_display_flags ^= DISPLAY_IS_NATIVE_X_BIT;
             show_display_bit(DISPLAY_IS_NATIVE_X_BIT, 9);
	  }
          else if (line == 4) {
             next_display_flags ^= DISPLAY_ENABLE_CSYNC_BIT;
             show_display_bit(DISPLAY_ENABLE_CSYNC_BIT, 10);
	  }
       } else if (r.a == 's') {
          save_changes();
          need_refresh=1;
       } else if (r.a == CRSR_DOWN) {
          line++; if (line > 4) line = 4;
          need_refresh=1;
       } else if (r.a == CRSR_UP) {
          line--; if (line < 0) line = 0;
          need_refresh=1;
       } else if (r.a == 'd') {
          next_display_flags = DEFAULT_DISPLAY_FLAGS;
          need_refresh=1;
       }
   }
}
