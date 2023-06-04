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
static const int stride = 80;

int test_blit_op(void) {
   int c,l;

   set_hires_mode(4); // 160x200x16
   POKE(53304L, 0); // $0000
   fill(0, stride * 200, 0); // clear

   for (l=0;l<2;l++) {
      c = l == 0 ? 1 : 0;
      box(0, 40,40,stride,2,c);
      blit(40-l*2, //width
        40-l*2, //height
        0,    //src_ptr
        l, //sx
        l, //sy
        stride, // stride
        0, // dest_ptr
        30+l, // dx
        100+l, // dy
        stride, // stride
        0, // flags
        1); // wait
   }

   box(0, 40,40,stride,2, 0); // what to write over top of
   for (l=0;l<30;l=l+2) {
      blit(40, //width
        40, //height
        0,    //src_ptr
        30, //sx
        100, //sy
        stride, // stride
        0, // dest_ptr
        l, // dx
        l, // dy
        stride, // stride
        3, // XOR
        1); // wait
   }

   WAITKEY;

   return 0;
}
