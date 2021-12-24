#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "init.h"
#include "kawari.h"
#include "util.h"

static struct regs r;

// Global definitions for default registers:
//    colors
//    luma/chroma
//    blanking
//    burst amplitude
//    display flags

int colors[] = {0,0,0,0,
                63,63,63,0,
                43,10,10,0,
                24,54,51,0,
                44,15,45,0,
                18,49,18,0,
                13,14,49,0,
                57,59,19,0,
                45,22,7,0,
                26,14,2,0,
                58,29,27,0,
                19,19,19,0,
                33,33,33,0,
                41,62,39,0,
                28,31,57,0,
                45,45,45,0};

int luma_rev3[4][16] = {
    // 6567R8   - 9 levels
    {12,63,24,42,27,35,21,50,27,21,35,24,33,50,33,42},

    // 6569R3   - 9 levels
    {15,63,30,46,33,40,27,53,33,27,40,30,38,53,38,46},

    // 6567R56A - 5 levels
    {12,63,20,47,33,33,20,47,33,20,33,20,33,47,33,47},

    // 6569R1   - 5 levels
    {13,63,22,50,37,37,22,50,37,22,37,22,37,50,37,50},
};

int luma_rev4[4][16] = {
    // 6567R8   - 9 levels
    {0x18, 0x3f, 0x2f, 0x39, 0x32, 0x36, 0x2c, 0x3c, 0x32, 0x2c, 0x36, 0x2f, 0x35, 0x3c, 0x35, 0x39},

    // 6569R3   - 9 levels
    {0x08, 0x3f, 0x2a, 0x37, 0x2d, 0x33, 0x25, 0x3b, 0x2d, 0x25, 0x33, 0x2a, 0x32, 0x3b, 0x32, 0x37},

    // 6567R56A - 5 levels
    {0x18, 0x3f, 0x2b, 0x3b, 0x35, 0x35, 0x2b, 0x3b, 0x35, 0x2b, 0x35, 0x2b, 0x35, 0x3b, 0x35, 0x3b},

    // 6569R1   - 5 levels
    {0x08, 0x3f, 0x1f, 0x39, 0x30, 0x30, 0x1f, 0x39, 0x30, 0x1f, 0x30, 0x1f, 0x30, 0x39, 0x30, 0x39},
};

int phase[4][16] = {
   {0, 0, 80, 208, 32, 160, 241, 128, 96, 112, 80, 0, 0, 160, 241, 0},
   {0, 0, 80, 208, 32, 160, 241, 128, 96, 112, 80, 0, 0, 160, 241, 0},
   {0, 0, 80, 208, 32, 160, 241, 128, 96, 112, 80, 0, 0, 160, 241, 0},
   {0, 0, 80, 208, 32, 160, 241, 128, 96, 112, 80, 0, 0, 160, 241, 0},
};

int amplitude[4][16] = {
   {0, 0, 0xd, 0xa, 0xc, 0xb, 0xb, 0xf, 0xf, 0xb, 0xc, 0, 0, 0xd, 0xd, 0},
   {0, 0, 0xd, 0xa, 0xc, 0xb, 0xb, 0xf, 0xf, 0xb, 0xc, 0, 0, 0xd, 0xd, 0},
   {0, 0, 0xd, 0xa, 0xc, 0xb, 0xb, 0xf, 0xf, 0xb, 0xc, 0, 0, 0xd, 0xd, 0},
   {0, 0, 0xd, 0xa, 0xc, 0xb, 0xb, 0xf, 0xf, 0xb, 0xc, 0, 0, 0xd, 0xd, 0},
};

void set_lumas(unsigned int variant_num, int chip_model) {
   // Luma/Chroma
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xa0);
      if (variant_num == VARIANT_REV_3)
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

void do_init(unsigned int variant_num, int chip_model) {
   unsigned int reg;
   unsigned int chip;
   unsigned int bank;

   printf ("\nInitializing....");

   // Enable persistence
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);

   // Display flags
   POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_DISPLAY_FLAGS);

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

      // Colors - all chips get same RGB values
      for (reg=64;reg<128;reg++) {
         if (reg % 4 == 3) continue;
         POKE(VIDEO_MEM_1_LO, reg);
         SAFE_POKE(VIDEO_MEM_1_VAL, colors[reg-64]);
      }

      set_lumas(variant_num, chip);
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
   int variant_num;
   char variant[16];

   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

   get_variant(variant);
   variant_num = ascii_variant_to_int(variant);

   CLRSCRN;
   if (variant_num == VARIANT_UNKNOWN) {
      printf ("WARNING: Unrecognized board.\n");
   } else {
      printf ("Variant: %s\n", variant);
      printf ("Match  : %d\n", variant_num);
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
          do_init(variant_num, CHIP6569R3);
          printf ("complete\n\n");
	  break;
       }
       else if (r.a == 'n') {
          do_init(variant_num, CHIP6567R8);
          printf ("complete\n\n");
	  break;
       }
   }

   printf ("       Press any key to continue\n");

   WAITKEY;
   return 1;
}
