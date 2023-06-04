#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <hires.h>

static struct regs r;
static const int stride = 160;
static const int pix_per_byte = 4;

int test_640x200x4_blit(void) {
   int c,l;
   int dx,dy;
   int dirx,diry;
   int need_wait;

   set_hires_mode(3); // 320x200x16
   POKE(53304L, 0 | 2 << 4); // $0000 color bank 1
   fill(0, stride * 200, 0); // clear

   // Draw series of solid boxes 40x40 in top left corner.
   // Each time, take a smaller section of the box and blit it
   // onto 200,100 creating a multi colored border
   for (c=0;c<=15;c=c+1) {
      box(0,40,40,stride,pix_per_byte,(c+1)%4);
   
      blit(40-c*2, //width
        40-c*2, //height
        0,    //src_ptr
        c, //sx
        c, //sy
        stride, // stride
        0, // dest_ptr
        300+c, // dx
        100+c, // dy
        stride, // stride
        0, // flags
        1); // wait
   }

   box(0,40,40,stride,pix_per_byte,0); // clear dest area first

   // The lst color was 15 and is in the center of the box. Test
   // transparency by clearing the original box area to 0 and
   // blit our multicolored box back to dx,dx but with index 15 as
   // transparent. So the center should appear black.  Do this for
   // dx,dy up to 15,15, then grab a smaller section each time and repeat.
   // Should leave a colored trail across the screen.
   dx=0;dy=0;
   need_wait =1;
   dirx=1;diry=1;
   for (l=0;l<15;l++) {
    for (c=0;c<15;c++) {
      blit(40-l*2, //width
        40-l*2, //height
        0,    //src_ptr
        300+l, //sx
        100+l, //sy
        stride, // stride
        0, // dest_ptr
        dx, // dx
        dy, // dy
        stride, // stride
        need_wait ? 8+(3<<4) : 0, // transparent color 3 on first draw
        1); // wait

      if (need_wait) {
         need_wait = 0;
         WAITKEY;
      }
      dx=dx+=dirx;
      dy=dy+=diry;
      if (dx >= 160-(40-l*2)) { dirx=-dirx; }
      if (dy >= 200-(40-l*2)) { diry=-diry; }
    }
   }

   WAITKEY;

   return 0;
}
