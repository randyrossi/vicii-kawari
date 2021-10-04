#include "tests.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// Write/Read vmem
int vmem_a(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 0);

  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_1_LO, n);
     POKE(VIDEO_MEM_1_HI, n);
     POKE(VIDEO_MEM_1_VAL, n);
  }

  // Read back
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_1_LO, n);
     POKE(VIDEO_MEM_1_HI, n);
     EXPECT_EQ(PEEK(VIDEO_MEM_1_VAL), n);
  }

  return 0;
}

int vmem_b(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 0);

  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_LO, n);
     POKE(VIDEO_MEM_2_HI, n);
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Read back
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_LO, n);
     POKE(VIDEO_MEM_2_HI, n);
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  return 0;
}
