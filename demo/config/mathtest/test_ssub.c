#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

static signed short ssub(signed short v1, signed short v2)
{
   signed short result;
   POKE(OP_1_HI, (v1&0xff00)>>8);
   POKE(OP_1_LO, v1&0xff);
   POKE(OP_2_HI, (v2&0xff00)>>8);
   POKE(OP_2_LO, v2&0xff);
   POKE(OPER, SSUB);
   // Result is 16 bits
   result = (PEEK(OP_2_HI) << 8) |
            (PEEK(OP_2_LO));
   return result;
}

int ssub_1(void) {
   signed short result;

   result = 32767; result=result-2;
   EXPECT_EQ(ssub(32767,2) , result);
   EXPECT_EQ(PEEK(OPER) & INF, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   result = -32767; result=result-2;
   EXPECT_EQ(ssub(-32767,2) , result);
   EXPECT_EQ(PEEK(OPER) & INF, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 1);

   EXPECT_EQ(ssub(8,3) , 8-3);
   EXPECT_EQ(PEEK(OPER) & INF, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   EXPECT_EQ(ssub(257,64) , 257-64);
   EXPECT_EQ(PEEK(OPER) & INF, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);

   result = 32767; result=result-64;
   EXPECT_EQ(ssub(32767u,64) , result);
   EXPECT_EQ(PEEK(OPER) & INF, 0);
   EXPECT_EQ(PEEK(OPER) & OVERFLOW, 0);
   EXPECT_EQ(PEEK(OPER) & UNDERFLOW, 0);
}

