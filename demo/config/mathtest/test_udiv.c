#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>

static unsigned short udiv(unsigned short v1, unsigned short v2)
{
   unsigned short result;
   POKE(OP_1_HI, (v1&0xff00)>>8);
   POKE(OP_1_LO, v1&0xff);
   POKE(OP_2_HI, (v2&0xff00)>>8);
   POKE(OP_2_LO, v2&0xff);
   POKE(OPER, UDIV);
   // Result is 16 bits
   result = (PEEK(OP_2_HI) << 8) |
            (PEEK(OP_2_LO));
   return result;
}

int udiv_1(void) {
   unsigned short o1;
   unsigned short o2;
   int t;

   EXPECT_EQ(udiv(65535u,2) , 65535u/2);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(udiv(0,1) , 0);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(udiv(8,3) , 8/3);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(udiv(253,64) , 253/64);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(udiv(65535u,64) , 65535u/64);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   udiv(5,0);
   EXPECT_EQ(PEEK(OPER) & DIVZ, DIVZ);

   for (t=0;t<NUM_RAND_RUNS;t++) {
      o1=(unsigned short) rand();
      o2=(unsigned short) rand();
      if (o2 == 0) o2 = 1;
      EXPECT_EQ(udiv(o1,o2) , o1/o2);
      EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   }
}

