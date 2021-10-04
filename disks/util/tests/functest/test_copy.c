#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// copy region, no overlap
int vmem_copy(int dir)
{
  int n;
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x00);
  POKE(VIDEO_MEM_FLAGS, 0);

  // Pattern at 0x0000
  for (n=0;n<0x800;n++) {
     POKE(VIDEO_MEM_1_LO, n & 0xff);
     POKE(VIDEO_MEM_1_HI, n >> 8);
     POKE(VIDEO_MEM_1_VAL, n % 256);
  }

  // Setup copy
  POKE(VIDEO_MEM_FLAGS, 15);
  POKE(VIDEO_MEM_1_LO, 0x00); // dest
  POKE(VIDEO_MEM_1_HI, 0x10);
  POKE(VIDEO_MEM_2_LO, 0x00); // src
  POKE(VIDEO_MEM_2_HI, 0x00);

  POKE(VIDEO_MEM_1_IDX, 0x00); // 2k
  POKE(VIDEO_MEM_2_IDX, 0x08);

  POKE(VIDEO_MEM_1_VAL, dir); // copy

  // Wait
  while (PEEK(VIDEO_MEM_2_IDX) != 0) {}

  POKE(VIDEO_MEM_FLAGS, 0);
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x00);
  // Read back from 0x1000
  for (n=0x1000;n<0x1000+0x800;n++) {
     POKE(VIDEO_MEM_1_LO, n & 0xff);
     POKE(VIDEO_MEM_1_HI, n >> 8);
     EXPECT_EQ(PEEK(VIDEO_MEM_1_VAL), n % 256);
     POKE(VIDEO_MEM_1_VAL, 0); // clear for another run
  }

  return 0;
}

// copy overlap
// 0x0000-0x0800 to 0x040d-0x0c0d
// must be done high to low or else we clobber src bytes
int vmem_copy_overlap(void)
{
  int n;
  int b;
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x00);
  POKE(VIDEO_MEM_FLAGS, 0);

  // Pattern at 0x0000
  for (n=0;n<0x800;n++) {
     POKE(VIDEO_MEM_1_LO, n & 0xff);
     POKE(VIDEO_MEM_1_HI, n >> 8);
     POKE(VIDEO_MEM_1_VAL, n % 256);
  }

  // Setup copy
  POKE(VIDEO_MEM_FLAGS, 15);
  POKE(VIDEO_MEM_1_LO, 0x0d); // dest
  POKE(VIDEO_MEM_1_HI, 0x04);
  POKE(VIDEO_MEM_2_LO, 0x00); // src
  POKE(VIDEO_MEM_2_HI, 0x00);

  POKE(VIDEO_MEM_1_IDX, 0x00); // 2k
  POKE(VIDEO_MEM_2_IDX, 0x08);

  POKE(VIDEO_MEM_1_VAL, 2); // high to low

  // Wait
  while (PEEK(VIDEO_MEM_2_IDX) != 0) {}

  POKE(VIDEO_MEM_FLAGS, 0);
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x00);
  // Read back from 0x1000
  b = 0;
  for (n=0x40d;n<0x40d+0x800;n++) {
     POKE(VIDEO_MEM_1_LO, n & 0xff);
     POKE(VIDEO_MEM_1_HI, n >> 8);
     EXPECT_EQ(PEEK(VIDEO_MEM_1_VAL), b % 256);
     POKE(VIDEO_MEM_1_VAL, 0); // clear for another run
     b++;
  }

  return 0;
}

