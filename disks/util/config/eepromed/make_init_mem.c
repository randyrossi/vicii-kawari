#include <stdio.h>

#include "../../include/kawari.h"
#include "../../include/data.h"

// Utility to make what the 1k eeprom
// data should look like after init.
// Used for comparison in eeprom util

unsigned char mem[1024];

// Assumes REV_4 since we are unlikely to run this
// on REV_3.
void set_lumas_mem(int chip_model) {
   // Luma/Chroma
   int reg;
   for (reg=0;reg<16;reg++) {
      mem[reg+0xa0+chip_model*256] = luma_rev4[chip_model][reg];
   }
}

void set_phases_mem(int chip_model) {
   // Phases
   int reg;
   for (reg=0;reg<16;reg++) {
      mem[reg+0xb0+chip_model*256] = phase[chip_model][reg];
   }
}

void set_amplitudes_mem(int chip_model) {
   // Amplitudes
   int reg;
   for (reg=0;reg<16;reg++) {
      mem[reg+0xc0+chip_model*256] = amplitude[chip_model][reg];
   }
}

void do_init() {
   unsigned int reg;
   unsigned int chip;
   unsigned int bank;

   // Display flags
   mem[DISPLAY_FLAGS] = DEFAULT_DISPLAY_FLAGS;

   // Init colors and other regs for each chip
   for (chip = 0; chip < 4; chip++) {
      // Colors - all chips get same RGB values
      for (reg=64;reg<128;reg++) {
         if (reg % 4 == 3) continue;
         mem[reg+chip*256] = colors[reg-64];
      }

      set_lumas_mem(chip);
      set_phases_mem(chip);
      set_amplitudes_mem(chip);

      mem[chip*256+BLACK_LEVEL] = black_levels[chip];
      mem[chip*256+BURST_AMPLITUDE] = burst_levels[chip];
   }

   mem[MAGIC_0] = 86;
   mem[MAGIC_1] = 73;
   mem[MAGIC_2] = 67;
   mem[MAGIC_3] = 50;
}

int main() {
   for (int i=0;i<1024;i++) {
      mem[i] = 0xff;
   }
   do_init();
   for (int i=0;i<1024;i++) {
      if (i%8==0) printf ("\n");
      printf ("0x%02x,",mem[i]);
   }
}
