#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

static struct regs r;
static int next_model=0;
static int current_model=0;

static int next_display_flags=0;
static int current_display_flags=0;

static int version;
static char variant[16];

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

void show_chip_model(void)
{
    TOXY(17,6);
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
}

void show_raster_lines(void)
{
    int next_raster_lines = next_display_flags & DISPLAY_SHOW_RASTER_LINES_BIT;
    int current_raster_lines = current_display_flags & DISPLAY_SHOW_RASTER_LINES_BIT;
    TOXY(17,7);
    if (next_raster_lines) {
       printf ("ON ");
    } else {
       printf ("OFF");
    }

    if (current_raster_lines != next_raster_lines) {
       printf (" (changed)");
    } else {
       printf ("          ");
    }
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
    printf ("\n");

    get_chip_model();
    get_display_flags();

    printf ("NOTE: Any changes to chip model will\n");
    printf ("take effect on next cold boot.\n\n");

    printf ("Press M to change chip model\n");
    printf ("Press R to toggle raster lines\n");
    printf ("Press S to save changes\n");
    printf ("Press Q to quit\n");

    need_refresh = 1;
    for (;;) {
       if (need_refresh) {
          show_chip_model();
          show_raster_lines();
          need_refresh = 0;
       }

       WAITKEY;

       if (r.a == 'q') {
          CLRSCRN;
          return;
       } else if (r.a == 'm') {
          next_model=next_model+1;
          if (next_model > 3) next_model=0;
          show_chip_model();
       } else if (r.a == 'r') {
          next_display_flags ^= DISPLAY_SHOW_RASTER_LINES_BIT;
          show_raster_lines();
       } else if (r.a == 's') {
          save_changes();
          need_refresh=1;
       }
   }
}
