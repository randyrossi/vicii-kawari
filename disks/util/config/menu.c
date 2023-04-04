#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <string.h>

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
static unsigned short version_short = 0;
static unsigned char variant[16];

static int line = 0;

static int has_rgb = 0;
static int has_dvi = 0;
static int has_comp= 0;

static int chip_line = -1;
static int is_native_y_line = -1;
static int is_native_x_line = -1;
static int csync_line = -1;
static int hpolarity_line = -1;
static int vpolarity_line = -1;
static int white_line_line = -1;
static int switch_line = -1;
static int locks_line = -1;
static int raster_lines_line = -1;
static int ntsc_50_line = -1;
//static int pal_60_line = -1;
static int max_line = -1;

#define FIRST_CONFIG_LINE 4
#define LABEL_ON_OFF 0
#define LABEL_HI_LO 1

static char* label_true_string[] = {"ON ","HI"};
static char* label_false_string[] = {"OFF","LO"};

static char* blank_line = "                                       ";

void get_display_flags(void)
{
   POKE(VIDEO_MEM_1_LO,DISPLAY_FLAGS);
   current_display_flags = PEEK(VIDEO_MEM_1_VAL);
   POKE(VIDEO_MEM_1_LO,DISPLAY_FLAGS2);
   current_display_flags = current_display_flags | (PEEK(VIDEO_MEM_1_VAL) << 8);
   next_display_flags = current_display_flags;
   current_switch_val = current_display_flags & DISPLAY_CHIP_INVERT_SWITCH;
}

void show_chip_model(int y)
{
    int flip;
    TOXY(17,y+FIRST_CONFIG_LINE);
    if (line == chip_line) printf ("%c",18);
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

    if (line == chip_line) printf ("%c",146);
}

void show_display_bit(unsigned int bit, int y, int label)
{
    int next_val = next_display_flags & bit;
    int current_val = current_display_flags & bit;

    // Always show actual value of switch
    if (bit == DISPLAY_CHIP_INVERT_SWITCH)
        next_val = current_display_flags & bit;

    TOXY(17,y + FIRST_CONFIG_LINE);
    if (line == y) printf ("%c",18);
    if (next_val) {
       printf (label_true_string[label]);
    } else {
       printf (label_false_string[label]);
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
    if (line == y) printf ("%c",146);
}

void show_lock_bits(int y)
{
    if (line == locks_line) printf ("%c",18);
    TOXY(17,y+FIRST_CONFIG_LINE);
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
    if (line == locks_line) printf ("%c",146);
}

void show_info_line(void) {
    TOXY(0,21);
    printf ("----------------------------------------");
    if (line == chip_line) {
        printf ("A change to this setting will take      ");
        printf ("effect on the next cold boot.           ");
        printf ("%s",blank_line);
    }
    else if (line == raster_lines_line) {
        printf ("Simulates raster lines for RGB based    ");
        printf ("video. Has no effect on composite video ");
        printf ("%s",blank_line);
    }
    else if (line == is_native_y_line) {
        printf ("Change vertical refresh to 15khz. NOTE  ");
        printf ("your monitor must accept this frequency.");
        printf ("%s",blank_line);
    }
    else if (line == is_native_x_line) {
        printf ("Use native horizontal resolution. NOTE  ");
        printf ("hires modes will not work if set.       ");
        printf ("%s",blank_line);
    }
    else if (line == csync_line) {
        printf ("Put CSYNC on the HSYNC analog RGB pin.  ");
        printf ("NOTE: Your monitor must support this.   ");
        printf ("%s",blank_line);
    }
    else if (line == hpolarity_line) {
        printf ("Set polarity on H pin of analog RGB     ");
        printf ("header. Active LO or Active HI.         ");
        printf ("%s",blank_line);
    }
    else if (line == vpolarity_line) {
        printf ("Set polarity on V pin of analog RGB     ");
        printf ("header. Active LO or Active HI.         ");
        printf ("%s",blank_line);
    }
    else if (line == white_line_line) {
        printf ("Turn on/off white burst pixel at start  ");
        printf ("of each raster line on S/LUM pin.       ");
        printf ("%s",blank_line);
    }
    else if (line == switch_line) {
        printf ("Physical switch indicator. If ON, chip  ");
        printf ("is opposite of saved video standard.    ");
        printf ("%s",blank_line);
    }
    else if (line == locks_line) {
        printf ("Lock bits indicator. Shows locked funcs ");
        printf ("according to jumper settings.           ");
        printf ("%s",blank_line);
    }
    else if (line == ntsc_50_line) {
        printf ("Uses NTSC color encoding for PAL chips. ");
        printf ("Makes using some NTSC monitors possible.");
        printf ("%s",blank_line);
    }
    //else if (line == pal_60_line) {
    //    printf ("Uses PAL color encoding for NTSC chips. ");
    //    printf ("Makes using some PAL monitors possible. ");
    //    printf ("%s",blank_line);
    //}
}

void save_changes(void)
{
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);
   if (current_display_flags != next_display_flags) {
      POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS);
      SAFE_POKE(VIDEO_MEM_1_VAL, next_display_flags & 0xff);
      POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS2);
      SAFE_POKE(VIDEO_MEM_1_VAL, next_display_flags >> 8);
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
    unsigned short caps;
    unsigned int ln;

    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
    version_major = get_version_major();
    version_minor = get_version_minor();
    version_short = version_minor + version_major * 256;
    get_variant(variant);

    caps = get_capability_bits();
    has_rgb = caps & CAP_RGB_BIT;
    has_dvi = caps & CAP_DVI_BIT;
    has_comp = caps & CAP_COMP_BIT;

    if (strcmp(variant,"sim") ==0) {
       has_rgb = 1;
       has_dvi = 1;
       has_comp = 1;
    }

    CLRSCRN;
    printf ("VIC-II Kawari Config Utility %s\n\n", UTILITY_VERSION);

    printf ("Kawari Version : %d.%d (%s)\n",version_major,
        version_minor, variant);
    printf ("\n");

    printf ("Chip Model     :\n");
    if (has_rgb | has_dvi) {
       printf ("Raster Lines   :\n");
       printf ("RGB 15khz      :\n");
       printf ("DVI/RGB 1xWidth:\n");
    }
    if (has_rgb) {
       printf ("RGB CSYNC      :\n");
       printf ("VSync polarity :\n");
       printf ("HSync polarity :\n");
    }
    if (has_comp) {
       printf ("S/LUM burst    :\n");
       if (version_short >= 267) {
          printf ("NTSC 50        :\n");
          //printf ("PAL  60        :\n");
       }
    }
    printf ("External Switch:\n");
    printf ("Locked Func    :\n");
    printf ("\n");

    current_model = next_model = get_chip_model();
    get_display_flags();
    current_lock_bits = get_lock_bits();

    printf ("SPACE = Alter | S = Save | D = Defaults\n");

    need_refresh = 1;
    for (;;) {
       if (need_refresh) {
          ln = 0;
          chip_line = ln; ln++;
          show_chip_model(chip_line);

          if (has_rgb | has_dvi) {
             raster_lines_line = ln; ln++;
             show_display_bit(DISPLAY_SHOW_RASTER_LINES_BIT, raster_lines_line, LABEL_ON_OFF);
             is_native_y_line = ln; ln++;
             show_display_bit(DISPLAY_IS_NATIVE_Y_BIT, is_native_y_line, LABEL_ON_OFF);
             is_native_x_line = ln; ln++;
             show_display_bit(DISPLAY_IS_NATIVE_X_BIT, is_native_x_line, LABEL_ON_OFF);
          }
          if (has_rgb) {
             csync_line = ln; ln++;
             show_display_bit(DISPLAY_ENABLE_CSYNC_BIT, csync_line, LABEL_ON_OFF);
             vpolarity_line = ln; ln++;
             show_display_bit(DISPLAY_VPOLARITY_BIT, vpolarity_line, LABEL_HI_LO);
             hpolarity_line = ln; ln++;
             show_display_bit(DISPLAY_HPOLARITY_BIT, hpolarity_line, LABEL_HI_LO);
          }
          if (has_comp) {
             white_line_line = ln; ln++;
             show_display_bit(DISPLAY_WHITE_LINE_BIT, white_line_line, LABEL_ON_OFF);
             // Only available since 1.11(267)
             if (version_short >= 267) {
                ntsc_50_line = ln; ln++;
                show_display_bit(DISPLAY_NTSC_50_BIT, ntsc_50_line, LABEL_ON_OFF);
                //pal_60_line = ln; ln++;
                //show_display_bit(DISPLAY_PAL_60_BIT, pal_60_line, LABEL_ON_OFF);
             }
          }
          switch_line = ln; ln++;
          show_display_bit(DISPLAY_CHIP_INVERT_SWITCH, switch_line, LABEL_ON_OFF);
          locks_line = ln; ln++;
          show_lock_bits(locks_line);

          max_line = locks_line;

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
          if (line == chip_line) {
             next_model=next_model+1;
             if (next_model > 3) next_model=0;
             show_chip_model(chip_line);
	  }
          else if (line == raster_lines_line && can_save) {
             next_display_flags ^= DISPLAY_SHOW_RASTER_LINES_BIT;
             show_display_bit(DISPLAY_SHOW_RASTER_LINES_BIT, raster_lines_line, 0);
	  }
          else if (line == is_native_y_line && can_save) {
             next_display_flags ^= DISPLAY_IS_NATIVE_Y_BIT;
             show_display_bit(DISPLAY_IS_NATIVE_Y_BIT, is_native_y_line, LABEL_ON_OFF);
	  }
          else if (line == is_native_x_line && can_save) {
             next_display_flags ^= DISPLAY_IS_NATIVE_X_BIT;
             show_display_bit(DISPLAY_IS_NATIVE_X_BIT, is_native_x_line, LABEL_ON_OFF);
	  }
          else if (line == csync_line && can_save) {
             next_display_flags ^= DISPLAY_ENABLE_CSYNC_BIT;
             show_display_bit(DISPLAY_ENABLE_CSYNC_BIT, csync_line, LABEL_ON_OFF);
	  }
          else if (line == vpolarity_line && can_save) {
             next_display_flags ^= DISPLAY_VPOLARITY_BIT;
             show_display_bit(DISPLAY_VPOLARITY_BIT, vpolarity_line, LABEL_HI_LO);
	  }
          else if (line == hpolarity_line && can_save) {
             next_display_flags ^= DISPLAY_HPOLARITY_BIT;
             show_display_bit(DISPLAY_HPOLARITY_BIT, hpolarity_line, LABEL_HI_LO);
	  }
          else if (line == white_line_line && can_save) {
             next_display_flags ^= DISPLAY_WHITE_LINE_BIT;
             show_display_bit(DISPLAY_WHITE_LINE_BIT, white_line_line, LABEL_ON_OFF);
	  }
          else if (line == ntsc_50_line && can_save) {
             next_display_flags ^= DISPLAY_NTSC_50_BIT;
             show_display_bit(DISPLAY_NTSC_50_BIT, ntsc_50_line, LABEL_ON_OFF);
	  }
          //else if (line == pal_60_line && can_save) {
          //   next_display_flags ^= DISPLAY_PAL_60_BIT;
          //   show_display_bit(DISPLAY_PAL_60_BIT, pal_60_line, LABEL_ON_OFF);
	  //}
       } else if (r.a == 's') {
          save_changes();
          need_refresh=1;
       } else if (r.a == CRSR_DOWN) {
          line++; if (line > max_line) line = max_line;
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
