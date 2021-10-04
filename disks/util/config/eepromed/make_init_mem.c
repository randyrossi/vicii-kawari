#include <stdio.h>

#include "../../common/kawari.h"
#include "../../common/init.h"

// Utility to make what the 1k eeprom
// data should look like after init.
// Used for comparison in eeprom util

unsigned char mem[1024];

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

int luma[4][16] = {
    // 6567R8   - 9 levels
    {12,63,24,42,27,35,21,50,27,21,35,24,33,50,33,42},

    // 6569R3   - 9 levels
    {15,63,30,46,33,40,27,53,33,27,40,30,38,53,38,46},

    // 6567R56A - 5 levels
    {12,63,20,47,33,33,20,47,33,20,33,20,33,47,33,47},

    // 6569R1   - 5 levels
    {13,63,22,50,37,37,22,50,37,22,37,22,37,50,37,50},
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

void set_lumas(int chip_model) {
   // Luma/Chroma
   int reg;
   for (reg=0;reg<16;reg++) {
      mem[reg+0xa0+chip_model*256] = luma[chip_model][reg];
   }
}

void set_phases(int chip_model) {
   // Phases
   int reg;
   for (reg=0;reg<16;reg++) {
      mem[reg+0xb0+chip_model*256] = phase[chip_model][reg];
   }
}

void set_amplitudes(int chip_model) {
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

      set_lumas(chip);
      set_phases(chip);
      set_amplitudes(chip);

      mem[chip*256+BLACK_LEVEL] = DEFAULT_BLANKING_LEVEL;
      mem[chip*256+BURST_AMPLITUDE] = DEFAULT_BURST_AMPLITUDE;
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
