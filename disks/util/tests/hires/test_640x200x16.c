#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <hires.h>

static struct regs r;

int test_640x200x16(void) {
   unsigned int c;
   unsigned int addr;
   unsigned int l;

   set_hires_mode(1); // 640x200x16
   POKE(53304L, 0 | (8 << 4)); // $0000 pixel, $4000 color
   fill(0, 80 * 200, 0); // clear pixels
   fill(0x4000, 80 * 25, 0); // clear color cells

   // Draw 20 lines pattern
   addr = 0;
   for (c=1; c< 20; c++) {
      fill(addr,80 * 8, c | ((c-1) << 2) | (c << 4) | ((c-1 << 6)));
      addr+=80*8;
   }

   POKE(53311L,1); // auto inc
   POKE(53301L,0);
   POKE(53305L,0x4000 & 0xff);
   POKE(53306L,0x4000 >> 8);
   for (l=0;l<80*20;l++) {
      POKE(53307L,l);
      if (l % 79 == 0) l=l+1;
   }

   WAITKEY;

   return 0;
}
