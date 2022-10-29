#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// No inc or dec on port a
int noop_vmem_a(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 0);

  POKE(VIDEO_MEM_1_LO, 0x00);
  POKE(VIDEO_MEM_1_HI, 0x00);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_1_VAL, n);
  }

  // Check we didn't inc or dec
  EXPECT_EQ(PEEK(VIDEO_MEM_1_LO), 0);
  EXPECT_EQ(PEEK(VIDEO_MEM_1_LO), 0);

  return 0;
}

int noop_vmem_b(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 0);

  POKE(VIDEO_MEM_2_LO, 0x00);
  POKE(VIDEO_MEM_2_HI, 0x00);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Check we didn't inc or dec
  EXPECT_EQ(PEEK(VIDEO_MEM_1_LO), 0);
  EXPECT_EQ(PEEK(VIDEO_MEM_2_LO), 0);

  return 0;
}
