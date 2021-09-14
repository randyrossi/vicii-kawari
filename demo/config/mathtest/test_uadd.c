#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>

static unsigned short uadd(unsigned short v1, unsigned short v2)
{
   unsigned short result;
   POKE(OP_1_HI, (v1&0xff00)>>8);
   POKE(OP_1_LO, v1&0xff);
   POKE(OP_2_HI, (v2&0xff00)>>8);
   POKE(OP_2_LO, v2&0xff);
   POKE(OPER, UADD);
   // Result is 16 bits
   result = (PEEK(OP_2_HI) << 8) |
            (PEEK(OP_2_LO));
   return result;
}

int uadd_1(void) {
   unsigned short o1;
   unsigned short o2;
   unsigned long p1;
   unsigned long p2;
   int t;

   EXPECT_EQ(uadd(65535u,2) , (unsigned short)(65535u+2u));
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, OVERFLOW);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   EXPECT_EQ(uadd(1u,2u) , 1u+2u);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   EXPECT_EQ(uadd(8u,3u) , 8u+3u);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   EXPECT_EQ(uadd(257u,64u) , 257u+64u);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   EXPECT_EQ(uadd(32767u,64u) , 32767u+64u);
   EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   for (t=0;t<NUM_RAND_RUNS;t++) {
      o1=(unsigned short) rand();
      o2=(unsigned short) rand();
      EXPECT_EQ(uadd(o1,o2) , o1+o2);
      EXPECT_EQ(PEEK(OPER) & DIVZ, 0);
      p1=(unsigned long)o1;
      p2=(unsigned long)o2;
      if ((p1 + p2) > 65535L) {
          EXPECT_EQ(PEEK(OPER) & OVERFLOW, OVERFLOW);
      } else {
          EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
      }
      EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);
   }
}

