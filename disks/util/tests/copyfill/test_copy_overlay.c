#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

// copy from vmem into overlay regs (color)
int test_copy_overlay(void)
{
  int n;
  POKE(VIDEO_MEM_1_IDX, 0x0);
  POKE(VIDEO_MEM_2_IDX, 0x0);
  POKE(VIDEO_MEM_FLAGS, 0);

  // Pattern at 0x0000
  for (n=0;n<64;n++) {
     POKE(VIDEO_MEM_1_LO, n & 0xff);
     POKE(VIDEO_MEM_1_HI, n >> 8);
     POKE(VIDEO_MEM_1_VAL, n % 256);
  }

  // Setup copy but into color regs
  POKE(VIDEO_MEM_FLAGS, 15 + 32);
  POKE(VIDEO_MEM_1_LO, 0x40); // dest
  POKE(VIDEO_MEM_1_HI, 0x00);
  POKE(VIDEO_MEM_2_LO, 0x00); // src
  POKE(VIDEO_MEM_2_HI, 0x00);

  POKE(VIDEO_MEM_1_IDX, 0x40); // 64 bytes
  POKE(VIDEO_MEM_2_IDX, 0x00);

  POKE(VIDEO_MEM_1_VAL, 1); // copy to overlay

  // Wait
  while (PEEK(VIDEO_MEM_2_IDX) != 0) {}

  // Verify the pattern got into colors
  POKE(VIDEO_MEM_FLAGS, 32);
  for (n=0;n<64;n++) {
      POKE(VIDEO_MEM_1_LO, n + 0x40);
      if (PEEK(VIDEO_MEM_1_VAL) != (n % 256)) { return 1; }
  }

  return 0;
}

