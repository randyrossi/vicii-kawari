#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>

static signed long smult(signed short v1, signed short v2)
{
   signed long result;
   unsigned long r;
   POKE(OP_1_HI, (v1&0xff00)>>8);
   POKE(OP_1_LO, v1&0xff);
   POKE(OP_2_HI, (v2&0xff00)>>8);
   POKE(OP_2_LO, v2&0xff);
   POKE(OPER, SMULT);
   // Result is 32 bits
   r = ((unsigned long)PEEK(OP_1_HI) << 24) |
       ((unsigned long)PEEK(OP_1_LO) << 16) |
       ((unsigned long)PEEK(OP_2_HI) << 8) |
       (unsigned long)PEEK(OP_2_LO);
   result = (signed long) r;
   return result;
}

int smult_1(void) {
   signed short o1;
   signed short o2;
   signed long a;
   int t;

   EXPECT_EQ(smult(-32767,32767), -32767*32767);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(smult(0,0) , 0);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(smult(1,0) , 0);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(smult(-8,3) , -8*3);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(smult(253,-64) , 253*-64);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   EXPECT_EQ(smult(32767,64) , 32767*64);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);

   for (t=0;t<NUM_RAND_RUNS;t++) {
      o1=(signed short) rand();
      o2=(signed short) rand();
      a = (signed long)(o1)*(signed long)(o2);
      EXPECT_EQ(smult(o1,o2) , a);
      EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   }

   return 0;
}

