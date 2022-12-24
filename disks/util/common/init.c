#include <stdio.h>

#include <6502.h>
#include <peekpoke.h>

#include "init.h"
#include "kawari.h"
#include "util.h"
#include "flash.h"

#define MY_CFG_VERSION 0xfe

static struct regs r;
static unsigned char version_major = 0;
static unsigned char version_minor = 0;
static unsigned short version_short = 0;

void set_rgb(void) {
   int reg;
   // Colors - all chips get same RGB values
   for (reg=64;reg<128;reg++) {
     if (reg % 4 == 3) continue;
     POKE(VIDEO_MEM_1_LO, reg);
     SAFE_POKE(VIDEO_MEM_1_VAL, colors[reg-64]);
   }
}

void set_lumas(unsigned int board_int, int chip_model) {
   // Luma/Chroma
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xa0);
      if (board_int == BOARD_REV_3T)
         SAFE_POKE(VIDEO_MEM_1_VAL, luma_rev3[chip_model][reg]);
      else
         SAFE_POKE(VIDEO_MEM_1_VAL, luma_rev4[chip_model][reg]);
   }
}

void set_phases(int chip_model) {
   // Phases
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xb0);
      SAFE_POKE(VIDEO_MEM_1_VAL, phase[chip_model][reg]);
   }
}

void set_amplitudes(int chip_model) {
   // Amplitudes
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xc0);
      SAFE_POKE(VIDEO_MEM_1_VAL, amplitude[chip_model][reg]);
   }
}

void do_init(unsigned int board_int, int chip_model) {
   unsigned int reg;
   unsigned int chip;
   unsigned int bank;
   unsigned char current_cfg_version;

   // 1.12+ = 1*256+12 = 268
   // It's still possible we get here with valid
   // magic if we are forcing an init. So read
   // the current cfg version.
   current_cfg_version = 0xff;
   if (version_short >= 268) {
      POKE(VIDEO_MEM_1_LO, CFG_VERSION);
      current_cfg_version = PEEK(VIDEO_MEM_1_VAL);
   }
   printf ("Cfg=0x%02x ",current_cfg_version);

   printf ("\nInitializing....");

   // Enable persistence
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);

   if (version_short >= 268) {
      // Never make a cfg version go backwards
      if (current_cfg_version > MY_CFG_VERSION) {
         POKE(VIDEO_MEM_1_LO, CFG_VERSION);
         SAFE_POKE(VIDEO_MEM_1_VAL, MY_CFG_VERSION);
         printf ("w0x%02x ",MY_CFG_VERSION);
      }
   }

   // Display flags
   POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_DISPLAY_FLAGS);
   POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS2);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_DISPLAY_FLAGS2);

   // Chip model
   POKE(VIDEO_MEM_1_LO, CHIP_MODEL);
   SAFE_POKE(VIDEO_MEM_1_VAL, chip_model);

   POKE(VIDEO_MEM_1_LO, EEPROM_BANK);
   bank =  PEEK(VIDEO_MEM_1_VAL);

   // Init colors and other regs for each chip
   for (chip = 0; chip < 4; chip++) {
      // Tell kawari which settings bank we want
      POKE(VIDEO_MEM_1_LO, EEPROM_BANK);
      POKE(VIDEO_MEM_1_VAL, chip);

      set_rgb();
      set_lumas(board_int, chip);
      set_phases(chip);
      set_amplitudes(chip);

      // Black level
      reg = BLACK_LEVEL;
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_BLANKING_LEVEL);

      // Burst amplitude
      reg = BURST_AMPLITUDE;
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_BURST_AMPLITUDE);

      // Turn off vic roll register
      reg = 0xfb;
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, 0);
   }

   // Put bank back
   POKE(VIDEO_MEM_1_LO, EEPROM_BANK);
   POKE(VIDEO_MEM_1_VAL, bank);

   // Install magic bytes indicating we have good data
   reg = MAGIC_0;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 86);
   reg = MAGIC_1;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 73);
   reg = MAGIC_2;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 67);
   reg = MAGIC_3;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 50);

   // Turn off persistence
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) & ~VMEM_FLAG_PERSIST_BIT);
}

int first_init()
{
   int board_int;
   char variant[16];

   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

   get_variant(variant);
   board_int = ascii_variant_to_board_int(variant);
   version_major = get_version_major();
   version_minor = get_version_minor();
   version_short = version_minor + version_major * 256;

   CLRSCRN;
   if (board_int == BOARD_UNKNOWN) {
      printf ("WARNING: Unrecognized board.\n");
   } else {
      printf ("Variant: %s\n", variant);
      printf ("Match  : %d\n", board_int);
   }

   printf ("--------------------------------------\n");
   printf ("Your VICII-Kawari EEPROM must be\n");
   printf ("initialized to factory defaults before\n");
   printf ("settings can be changed.\n");
   printf ("--------------------------------------\n\n");

   printf ("Press P to initialize as PAL\n");
   printf ("Press N to initialize as NTSC\n");
   printf ("Press Q to quit\n");

   WAITKEY;

   for (;;) {
       if (r.a == 'q') {
          CLRSCRN;
	  return 0;
       }
       else if (r.a == 'p') {
          do_init(board_int, CHIP6569R3);
          printf ("complete\n\n");
	  break;
       }
       else if (r.a == 'n') {
          do_init(board_int, CHIP6567R8);
          printf ("complete\n\n");
	  break;
       }
   }

   printf ("       Press any key to continue\n");

   WAITKEY;
   return 1;
}

void init(int initPal)
{
   int board_int;
   char variant[16];

   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

   get_variant(variant);
   board_int = ascii_variant_to_board_int(variant);
   version_major = get_version_major();
   version_minor = get_version_minor();
   version_short = version_minor + version_major * 256;

   CLRSCRN;
   if (board_int == BOARD_UNKNOWN) {
      printf ("WARNING: Unrecognized board.\n");
   } else {
      printf ("Variant: %s\n", variant);
      printf ("Match  : %d\n", board_int);
   }

   if (initPal) {
      do_init(board_int, CHIP6569R3);
      printf ("Init to PAL\n\n");
   }
   else {
      do_init(board_int, CHIP6567R8);
      printf ("Init to NTSC\n\n");
   }
}
