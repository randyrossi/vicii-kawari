#include <stdio.h>

#include <6502.h>
#include <peekpoke.h>

#include "init.h"
#include "kawari.h"
#include "util.h"

static struct regs r;

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
