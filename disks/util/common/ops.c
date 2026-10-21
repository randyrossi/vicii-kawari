#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>

#include "ops.h"

void copy_dram_to_vmem(unsigned int src, unsigned int dest, unsigned int size)
{
  POKE(VIDEO_MEM_FLAGS, 0b1111); // DMA both ports

  POKE(VIDEO_MEM_1_LO, dest & 0xff); // dest
  POKE(VIDEO_MEM_1_HI, (dest >> 8) & 0xff);
  POKE(VIDEO_MEM_2_LO, src & 0xff); // src
  POKE(VIDEO_MEM_2_HI, (src >> 8) & 0xff);
  POKE(VIDEO_MEM_1_IDX, size & 0xff);
  POKE(VIDEO_MEM_2_IDX, (size >> 8) & 0xff);

  POKE(VIDEO_MEM_1_VAL, 8); // do copy

  while (PEEK(VIDEO_MEM_1_IDX) != 0 || PEEK(VIDEO_MEM_2_IDX) != 0) {}

}
