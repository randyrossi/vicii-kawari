#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "init.h"
#include "kawari.h"
#include "util.h"

static struct regs r;

// TODO: Move these to a place that can be shared
// with MCU loader.
//
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
                45,45,45,0 };

int luma[4][16] = {
    // 6567R8   - 9 levels
    {12,58,19,35,22,28,16,43,22,16,28,19,26,43,26,35},

    // 6569R3   - 9 levels
    {12,59,24,40,27,33,21,46,27,21,33,24,32,46,32,40},

    // 6567R56A - 5 levels
    {12,58,16,41,27,27,16,41,27,16,27,16,27,41,27,41},

    // 6569R1   - 5 levels
    {12,59,18,43,30,30,18,43,30,18,30,18,30,43,30,43},
};

int phase[4][16] = {
   {0, 0, 80, 208, 32, 160, 0, 128, 96, 112, 80, 0, 0, 160, 0, 0},
   {0, 0, 80, 208, 32, 160, 0, 128, 96, 112, 80, 0, 0, 160, 0, 0},
   {0, 0, 80, 208, 32, 160, 0, 128, 96, 112, 80, 0, 0, 160, 0, 0},
   {0, 0, 80, 208, 32, 160, 0, 128, 96, 112, 80, 0, 0, 160, 0, 0},
};

int amplitude[4][16] = {
   {0, 0, 10, 10, 12, 12, 10, 14, 14, 10, 10, 0, 0, 10, 10, 0},
   {0, 0, 10, 10, 12, 12, 10, 14, 14, 10, 10, 0, 0, 10, 10, 0},
   {0, 0, 10, 10, 12, 12, 10, 14, 14, 10, 10, 0, 0, 10, 10, 0},
   {0, 0, 10, 10, 12, 12, 10, 14, 14, 10, 10, 0, 0, 10, 10, 0},
};

void set_lumas(int chip_model) {
   // Luma/Chroma
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xa0);
      SAFE_POKE(VIDEO_MEM_1_VAL, luma[chip_model][reg*3]);
   }
}

void set_phases(int chip_model) {
   // Phases
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xb0);
      SAFE_POKE(VIDEO_MEM_1_VAL, phase[chip_model][reg*3]);
   }
}

void set_amplitudes(int chip_model) {
   // Amplitudes
   int reg;
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xc0);
      SAFE_POKE(VIDEO_MEM_1_VAL, amplitude[chip_model][reg*3]);
   }
}

void do_init(int chip_model) {
   int reg;

   printf ("\nInitializing....");

   // Enable persistence
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_PERSIST_BIT);

   // Display flags
   POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_DISPLAY_FLAGS);

   // Chip model
   POKE(VIDEO_MEM_1_LO, CHIP_MODEL);
   SAFE_POKE(VIDEO_MEM_1_VAL, chip_model);

   // Colors
   for (reg=0;reg<64;reg++) {
      if (reg % 4 == 3) continue;
      POKE(VIDEO_MEM_1_LO, reg);
      SAFE_POKE(VIDEO_MEM_1_VAL, colors[reg]);
   }

   set_lumas(chip_model);
   set_phases(chip_model);
   set_amplitudes(chip_model);

   // Black level
   reg = BLACK_LEVEL;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_BLANKING_LEVEL);

   // Burst amplitude
   reg = BLACK_LEVEL;
   reg = BURST_AMPLITUDE;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_BURST_AMPLITUDE);

   // Turn off vic roll register
   reg = 0xfb;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 0);

   // Install magic bytes indicating we have good data
   reg = 0xfc;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 86);
   reg = 0xfd;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 73);
   reg = 0xfe;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 67);
   reg = 0xff;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, 50);

   // Turn off persistence
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) & ~VMEM_FLAG_PERSIST_BIT);
}

int first_init()
{
   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

   CLRSCRN;
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
          do_init(CHIP6569R3);
	  break;
       }
       else if (r.a == 'n') {
          do_init(CHIP6567R8);
	  break;
       }
   }
   printf ("complete\n\n");
   printf ("       Press any key to continue\n");

   WAITKEY;
   return 1;
}
