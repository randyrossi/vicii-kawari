#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// Auto inc 16 positions from 0
int auto_inc_vmem_b_16(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 4);

  POKE(VIDEO_MEM_2_LO, 0x00);
  POKE(VIDEO_MEM_2_HI, 0x00);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Check we advanced properly
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 16);

  // Read back
  POKE(VIDEO_MEM_2_LO, 0x00);
  POKE(VIDEO_MEM_2_HI, 0x00);
  for (n=0;n<16;n++) {
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  // Check we advanced properly
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 16);

  return 0;
}

// Auto inc 
int auto_inc_vmem_b_wrap(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 4);

  POKE(VIDEO_MEM_2_LO, 0x13);
  POKE(VIDEO_MEM_2_HI, 0x20);
  for (n=0;n<255;n++) {
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Check we advanced properly over page boundary
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0x12);
  EXPECT_EQ(PEEK(VIDEO_MEM_2_HI), 0x21);

  // Read back
  POKE(VIDEO_MEM_2_LO, 0x13);
  POKE(VIDEO_MEM_2_HI, 0x20);
  for (n=0;n<255;n++) {
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  // Check we advanced properly over page boundary
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0x12);
  EXPECT_EQ(PEEK(VIDEO_MEM_2_HI), 0x21);
  return 0;
}
