#include <6502.h>
#include <peekpoke.h>

#include "kawari.h"
#include "tests.h"

void fill(unsigned int addr,
          unsigned int size,
          unsigned int value,
          int poll_wait ) {
  POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);
  POKE(VIDEO_MEM_1_LO, addr & 0xff);
  POKE(VIDEO_MEM_1_HI, addr >> 8);
  POKE(VIDEO_MEM_1_IDX, size & 0xff);
  POKE(VIDEO_MEM_2_IDX, size >> 8);
  POKE(VIDEO_MEM_2_LO, value); // fill byte
  POKE(VIDEO_MEM_1_VAL, 4); // do fill
  // Wait
  if (poll_wait) {
     while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
  }
}

void box(unsigned int addr, int width, int height, int stride, int pix_per_byte, int c, int poll_wait) {
   int l;
   for (l=0;l<height;l++) {
      if (pix_per_byte == 2)
         fill(addr, width / pix_per_byte, c | ( c << 4), poll_wait);
      else
         fill(addr, width / pix_per_byte, c | c << 2 | c << 4 | c << 6, poll_wait);
      addr+=stride;
   }
}

void copy(int offset)
{
  unsigned short dest = 0x3840 +offset;

  // Setup copy
  POKE(VIDEO_MEM_1_LO, dest & 0xff); // dest
  POKE(VIDEO_MEM_1_HI, (dest >> 8) & 0xff);
  POKE(VIDEO_MEM_2_LO, 0x00); // src
  POKE(VIDEO_MEM_2_HI, 0x00);

  POKE(VIDEO_MEM_1_IDX, 0x00); // 6400 bytes
  POKE(VIDEO_MEM_2_IDX, 0x19);

  POKE(VIDEO_MEM_1_VAL, 1); // copy
}

