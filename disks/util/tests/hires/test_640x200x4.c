#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <hires.h>

static struct regs r;

int test_640x200x4(void) {
   unsigned int c;
   unsigned int addr;

   set_hires_mode(3); // 640x200x4
   POKE(53304L, 0); // $0000
   fill(0, 160 * 200, 0); // clear

   // Draw 10 lines of pattern
   addr = 0;
   for (c=0; c< 4; c++) {
      //fill(addr, 160 * 10, c | ((c-1) << 2) | (c << 4) | ((c-1 << 6)));
      fill(addr, 160 * 10, c | (c<< 2) | (c << 4) | (c<< 6));
      addr+=160*10;
   }

   WAITKEY;

   for (c=1;c<4;c++) {
      POKE(53304L, 0 | (c << 4)); // color bank
      WAITKEY;
   }


   return 0;
}
