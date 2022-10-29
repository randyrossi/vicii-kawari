#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "init.h"

static struct regs r;
static unsigned int next_model = 0;
static unsigned int current_model = 0;

static unsigned int next_display_flags = 0;
static unsigned int current_display_flags = 0;
static unsigned int current_switch_val = 0;
static unsigned char current_lock_bits = 0;

static unsigned char version_major = 0;
static unsigned char version_minor = 0;
static unsigned char variant[16];

static int line = 0;

void get_display_flags(void)
{
   POKE(VIDEO_MEM_1_LO,DISPLAY_FLAGS);
   current_display_flags = PEEK(VIDEO_MEM_1_VAL);
   next_display_flags = current_display_flags;
   current_switch_val = current_display_flags & DISPLAY_CHIP_INVERT_SWITCH;
}

void show_chip_model()
{
    int flip;
    TOXY(17,6);
    if (line == 0) printf ("%c",18);
    switch (next_model) {
        case 0:
            printf ("6567R8  ");
            break;
        case 1:
            printf ("6569R3  ");
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
    POKE(VIDEO_MEM_1_LO,DISPLAY_FLAGS);
    flip=current_switch_val;

    if (flip)
	    printf ("INV");
    else
	    printf ("   ");

    if (line == 0) printf ("%c",146);
}

void show_display_bit(unsigned int bit, int y, int label)
{
    int next_val = next_display_flags & bit;
    int current_val = current_display_flags & bit;

    // Always show actual value of switch
    if (bit == DISPLAY_CHIP_INVERT_SWITCH)
        next_val = current_display_flags & bit;

    TOXY(17,y);
    if (line == y-6) printf ("%c",18);
    if (next_val) {
       if (label) printf ("HI "); else printf ("ON ");
    } else {
       if (label) printf ("LO "); else printf ("OFF");
    }

    if (bit != DISPLAY_CHIP_INVERT_SWITCH && (current_lock_bits & 32)) {
       printf (" (locked) ");
    } else {
       if (current_val != next_val) {
              printf (" (changed)");
           } else {
              printf ("          ");
           }
    }
    if (line == y-6) printf ("%c",146);
}

void show_lock_bits(int y)
{
    if (line == 9) printf ("%c",18);
    TOXY(17,y);
    if (FLASH_LOCKED)
       printf ("FLASH ");
    else
       printf ("      ");
    if (EXTRA_LOCKED)
       printf ("EXTRA ");
    else
       printf ("      ");
    if (SAVES_LOCKED)
       printf ("SAVES ");
    else
       printf ("      ");
    if (line == 9) printf ("%c",146);
}

void show_info_line(void) {
    TOXY(0,21);
    printf ("----------------------------------------");
    if (line == 0) {
        printf ("A change to this setting will take      ");
        printf ("effect on the next cold boot.           ");
    }
    else if (line == 1) {
        printf ("Simulates raster lines for RGB based    ");
        printf ("video. Has no effect on composite video ");
    }
    else if (line == 2) {
        printf ("Change vertical refresh to 15khz. NOTE  ");
        printf ("your monitor must accept this frequency.");
    }
    else if (line == 3) {
        printf ("Use native horizontal resolution. NOTE  ");
        printf ("hires modes will not work if set.       ");
    }
    else if (line == 4) {
        printf ("Put CSYNC on the HSYNC analog RGB pin.  ");
        printf ("NOTE: Your monitor must support this.   ");
    }
    else if (line == 5) {
        printf ("Set polarity on H pin of analog RGB     ");
        printf ("header. Active LO or Active HI.         ");
    }
    else if (line == 6) {
        printf ("Set polarity on V pin of analog RGB     ");
        printf ("header. Active LO or Active HI.         ");
    }
    else if (line == 7) {
        printf ("Turn on/off white burst pixel at start  ");
        printf ("of each raster line on S/LUM pin.       ");
    }
    else if (line == 8) {
        printf ("Physical switch indicator. If ON, chip  ");
        printf ("is opposite of saved video standard.    ");
    }
    else if (line == 9) {
        printf ("Lock bits indicator. Shows locked funcs ");
        printf ("according to jumper settings.           ");
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
    unsigned char can_save = 1;
    unsigned char new_switch_val;
    unsigned char new_lock_bits;

    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
    version_major = get_version_major();
    version_minor = get_version_minor();
    get_variant(variant);

    CLRSCRN;
    printf ("VIC-II Kawari Config Utility\n\n");

    printf ("Utility Version: %s\n",UTILITY_VERSION);
    printf ("Kawari Version : %d.%d\n",version_major, version_minor);
    printf ("Variant        : %s\n",variant);
    printf ("\n");
    printf ("Chip Model     :\n");
    printf ("Raster Lines   :\n");
    printf ("RGB 15khz      :\n");
    printf ("DVI/RGB 1xWidth:\n");
    printf ("RGB CSYNC      :\n");
    printf ("VSync polarity :\n");
    printf ("HSync polarity :\n");
    printf ("S/LUM burst    :\n");
    printf ("External Switch:\n");
    printf ("Locked Func    :\n");
    printf ("\n");

    current_model = next_model = get_chip_model();
    get_display_flags();
    current_lock_bits = get_lock_bits();

    printf ("CRSR to navigate | SPACE to change\n");
    printf ("S to save        | D for defaults\n");
    printf ("Q to quit\n");

    need_refresh = 1;
    for (;;) {
       if (need_refresh) {
          show_chip_model();
          show_display_bit(DISPLAY_SHOW_RASTER_LINES_BIT, 7, 0);
          show_display_bit(DISPLAY_IS_NATIVE_Y_BIT, 8, 0);
          show_display_bit(DISPLAY_IS_NATIVE_X_BIT, 9, 0);
          show_display_bit(DISPLAY_ENABLE_CSYNC_BIT, 10, 0);
          show_display_bit(DISPLAY_VPOLARITY_BIT, 11, 1);
          show_display_bit(DISPLAY_HPOLARITY_BIT, 12, 1);
          show_display_bit(DISPLAY_WHITE_LINE_BIT, 13, 0);
          show_display_bit(DISPLAY_CHIP_INVERT_SWITCH, 14, 0);
          show_lock_bits(15);
	  show_info_line();
          need_refresh = 0;
       }

       r.a = wait_key_or_change(
          current_switch_val,
          current_lock_bits,
          &new_switch_val, &new_lock_bits);

       if (r.a == 'q') {
          CLRSCRN;
          return;
       } else if (r.a == ' ') {
          can_save = !(SAVES_LOCKED);
          if (line == 0) {
             next_model=next_model+1;
             if (next_model > 3) next_model=0;
             show_chip_model();
	  }
          else if (line == 1 && can_save) {
             next_display_flags ^= DISPLAY_SHOW_RASTER_LINES_BIT;
             show_display_bit(DISPLAY_SHOW_RASTER_LINES_BIT, 7, 0);
	  }
          else if (line == 2 && can_save) {
             next_display_flags ^= DISPLAY_IS_NATIVE_Y_BIT;
             show_display_bit(DISPLAY_IS_NATIVE_Y_BIT, 8, 0);
	  }
          else if (line == 3 && can_save) {
             next_display_flags ^= DISPLAY_IS_NATIVE_X_BIT;
             show_display_bit(DISPLAY_IS_NATIVE_X_BIT, 9, 0);
	  }
          else if (line == 4 && can_save) {
             next_display_flags ^= DISPLAY_ENABLE_CSYNC_BIT;
             show_display_bit(DISPLAY_ENABLE_CSYNC_BIT, 10, 0);
	  }
          else if (line == 5 && can_save) {
             next_display_flags ^= DISPLAY_VPOLARITY_BIT;
             show_display_bit(DISPLAY_VPOLARITY_BIT, 11, 1);
	  }
          else if (line == 6 && can_save) {
             next_display_flags ^= DISPLAY_HPOLARITY_BIT;
             show_display_bit(DISPLAY_HPOLARITY_BIT, 12, 1);
	  }
          else if (line == 7 && can_save) {
             next_display_flags ^= DISPLAY_WHITE_LINE_BIT;
             show_display_bit(DISPLAY_WHITE_LINE_BIT, 13, 0);
	  }
       } else if (r.a == 's') {
          save_changes();
          need_refresh=1;
       } else if (r.a == CRSR_DOWN) {
          line++; if (line > 9) line = 9;
          need_refresh=1;
       } else if (r.a == CRSR_UP) {
          line--; if (line < 0) line = 0;
          need_refresh=1;
       } else if (r.a == 'd') {
          next_display_flags = DEFAULT_DISPLAY_FLAGS;
          need_refresh=1;
       } else if (r.a == '*') {
          // external switch has changed
          current_switch_val = new_switch_val;
          current_display_flags &= ~DISPLAY_CHIP_INVERT_SWITCH;
          current_display_flags |= new_switch_val;
          need_refresh=1;
       } else if (r.a == '%') {
          // lock bits changed
          current_lock_bits = new_lock_bits;
          need_refresh=1;
       }
   }
}
