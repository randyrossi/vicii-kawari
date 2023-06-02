#include <6502.h>
#include <peekpoke.h>

#include "kawari.h"

#include "tests.h"

void fill(unsigned int addr,
          unsigned int size,
          unsigned int value ) {
  POKE(53311L, 3); // fill port 1
  POKE(VIDEO_MEM_1_LO, addr & 0xff);
  POKE(VIDEO_MEM_1_HI, addr >> 8);
  POKE(VIDEO_MEM_1_IDX, size & 0xff);
  POKE(VIDEO_MEM_2_IDX, size >> 8);
  POKE(VIDEO_MEM_2_LO, value); // fill byte
  POKE(VIDEO_MEM_1_VAL, 4); // do fill
  // Wait
  while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
}
