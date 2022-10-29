#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// fill
int vmem_fill(void)
{
  int n;
  int n2;
  int b;
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x00);
  POKE(VIDEO_MEM_FLAGS, 0);

  // Setup fill
  POKE(VIDEO_MEM_FLAGS, 15);
  b=1;
  for (n=0x0000;n<0x1000;n+=0x400) {
     POKE(VIDEO_MEM_1_LO, n & 0xff); // dest
     POKE(VIDEO_MEM_1_HI, n >> 8);
     POKE(VIDEO_MEM_1_IDX, 0x00); // 1k
     POKE(VIDEO_MEM_2_IDX, 0x04);

     POKE(VIDEO_MEM_2_LO, b); // fill byte
     POKE(VIDEO_MEM_1_VAL, 4); // fill

     // Wait
     while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
     b++;
  }

  // Verify
  POKE(VIDEO_MEM_FLAGS, 0);
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x00);

  b=1;
  for (n=0x0000;n<0x1000;n+=0x400) {
     for (n2=n;n2<n+0x400;n2++) {
       POKE(VIDEO_MEM_1_LO, n2 & 0xff);
       POKE(VIDEO_MEM_1_HI, n2 >> 8);
       EXPECT_EQ(PEEK(VIDEO_MEM_1_VAL), b);
     }
     b++;
  }

  return 0;
}

