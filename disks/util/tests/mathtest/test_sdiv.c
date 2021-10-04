#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>

static signed short sdiv(signed short v1, signed short v2)
{
   signed short result;
   POKE(OP_1_HI, (v1&0xff00)>>8);
   POKE(OP_1_LO, v1&0xff);
   POKE(OP_2_HI, (v2&0xff00)>>8);
   POKE(OP_2_LO, v2&0xff);
   POKE(OPER, SDIV);
   // Result is 16 bits
   result = (PEEK(OP_2_HI) << 8) |
            (PEEK(OP_2_LO));
   return result;
}

int sdiv_1(void) {
   signed short o1;
   signed short o2;
   int t;

   EXPECT_EQ(sdiv(32767,2) , 32767/2);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(sdiv(0,1) , 0);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(sdiv(8,3) , 8/3);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(sdiv(-253,64) , (short)-253/(short)64);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(sdiv(-32767,64) , (short)-32767/(short)64);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   sdiv(5,0);
   EXPECT_EQ(PEEK(OPER) & DIVZ, DIVZ);

   for (t=0;t<NUM_RAND_RUNS;t++) {
      o1=(signed short) rand();
      o2=(signed short) rand();
      if (o2 == 0) o2 = 1;
      EXPECT_EQ(sdiv(o1,o2) , o1/o2);
      EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   }
}

