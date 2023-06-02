#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <hires.h>

static struct regs r;

int test_160x200x16(void) {
   unsigned int c;
   unsigned int addr;

   set_hires_mode(4); // 160x200x16
   POKE(53304L, 0); // $0000
   fill(0, 80 * 200, 0); // clear

   // Draw 10 lines of pattern
   addr = 0;
   for (c=1; c< 17; c++) {
      fill(addr, 80 * 10, c | ((c-1) << 4));
      addr+=80*10;
   }

   WAITKEY;

   return 0;
}
