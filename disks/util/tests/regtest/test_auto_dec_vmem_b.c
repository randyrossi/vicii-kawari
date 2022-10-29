#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// Auto dec 16 positions from 0
int auto_dec_vmem_b_16(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 8);

  POKE(VIDEO_MEM_2_LO, 0x10);
  POKE(VIDEO_MEM_2_HI, 0x00);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Check we decremented properly
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0);

  // Read back
  POKE(VIDEO_MEM_2_LO, 0x10);
  POKE(VIDEO_MEM_2_HI, 0x00);
  for (n=0;n<16;n++) {
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  // Check we advanced properly
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0);

  return 0;
}

// Auto dec 
int auto_dec_vmem_b_wrap(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 8);

  POKE(VIDEO_MEM_2_LO, 0x13);
  POKE(VIDEO_MEM_2_HI, 0x20);
  for (n=0;n<255;n++) {
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Check we advanced properly over page boundary
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0x14);
  EXPECT_EQ(PEEK(VIDEO_MEM_2_HI), 0x1f);

  // Read back
  POKE(VIDEO_MEM_2_LO, 0x13);
  POKE(VIDEO_MEM_2_HI, 0x20);
  for (n=0;n<255;n++) {
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  // Check we advanced properly over page boundary
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0x14);
  EXPECT_EQ(PEEK(VIDEO_MEM_2_HI), 0x1f);
  return 0;
}
