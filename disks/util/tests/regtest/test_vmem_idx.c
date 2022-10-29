#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// Write/Read vmem
int vmem_idx_a(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 0);

  POKE(VIDEO_MEM_1_LO, 0);
  POKE(VIDEO_MEM_1_HI, 0);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_1_IDX, n);
     POKE(VIDEO_MEM_1_VAL, n);
  }

  // Read back - without index
  POKE(VIDEO_MEM_1_IDX, 0);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_1_LO, n);
     POKE(VIDEO_MEM_1_HI, 0);
     EXPECT_EQ(PEEK(VIDEO_MEM_1_VAL), n);
  }

  // Read back - with index
  POKE(VIDEO_MEM_1_LO, 0);
  POKE(VIDEO_MEM_1_HI, 0);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_1_IDX, n);
     EXPECT_EQ(PEEK(VIDEO_MEM_1_VAL), n);
  }

  return 0;
}

int vmem_idx_b(void)
{
  int n;
  POKE(VIDEO_MEM_FLAGS, 0);

  POKE(VIDEO_MEM_2_LO, 0);
  POKE(VIDEO_MEM_2_HI, 0);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_IDX, n);
     POKE(VIDEO_MEM_2_VAL, n);
  }

  // Read back - without index
  POKE(VIDEO_MEM_2_IDX, 0);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_LO, n);
     POKE(VIDEO_MEM_2_HI, 0);
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  // Read back - with index
  POKE(VIDEO_MEM_2_LO, 0);
  POKE(VIDEO_MEM_2_HI, 0);
  for (n=0;n<16;n++) {
     POKE(VIDEO_MEM_2_IDX, n);
     EXPECT_EQ(PEEK(VIDEO_MEM_2_VAL), n);
  }

  return 0;
}
