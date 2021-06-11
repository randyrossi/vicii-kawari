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

#define DEFAULT_BLANKING_LEVEL 12
#define DEFAULT_BURST_AMPLITUDE 12
#define DEFAULT_DISPLAY_FLAGS 0

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

int luma[] = {
   12,0,0,
   58,0,0,
   19,80,10,
   36,208,10,
   22,32,12,
   30,160,12,
   14,0,10,
   43,128,14,
   22,96,14,
   14,112,10,
   30,80,10,
   19,0,0,
   28,0,0,
   43,160,10,
   28,0,10,
   36,0,0,
};

void do_init(int chip_model) {
   int reg;

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

   // Luma/Chroma
   for (reg=0;reg<16;reg++) {
      POKE(VIDEO_MEM_1_LO, reg+0xa0);
      SAFE_POKE(VIDEO_MEM_1_VAL, luma[reg*3]); // luma
      POKE(VIDEO_MEM_1_LO, reg+0xb0);
      SAFE_POKE(VIDEO_MEM_1_VAL, luma[reg*3+1]); // phase
      POKE(VIDEO_MEM_1_LO, reg+0xc0);
      SAFE_POKE(VIDEO_MEM_1_VAL, luma[reg*3+2]); // amplitude
   }

   // Black level
   reg = BLACK_LEVEL;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_BLANKING_LEVEL);

   // Burst amplitude
   reg = BLACK_LEVEL;
   reg = BURST_AMPLITUDE;
   POKE(VIDEO_MEM_1_LO, reg);
   SAFE_POKE(VIDEO_MEM_1_VAL, DEFAULT_BURST_AMPLITUDE);

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
   printf ("Kawari config must be initialized.\n");

   printf ("Press P to initialize for PAL\n");
   printf ("Press N to initialize for NTSC\n");
   printf ("Press Q to quit\n");

   WAITKEY;    

   for (;;) {
       if (r.a == 'q') {
          CLRSCRN;
	  return 0;
       }
       else if (r.a == 'p') {
          do_init(1);
	  return 1;
       }
       else if (r.a == 'n') {
          do_init(0);
	  return 1;
       }
   }
}
