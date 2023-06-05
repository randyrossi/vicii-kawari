#include <6502.h>
#include <peekpoke.h>

#include "kawari.h"

#include "tests.h"

void fill(unsigned int addr,
          unsigned int size,
          unsigned int value ) {
  POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);
  POKE(VIDEO_MEM_1_LO, addr & 0xff);
  POKE(VIDEO_MEM_1_HI, addr >> 8);
  POKE(VIDEO_MEM_1_IDX, size & 0xff);
  POKE(VIDEO_MEM_2_IDX, size >> 8);
  POKE(VIDEO_MEM_2_LO, value); // fill byte
  POKE(VIDEO_MEM_1_VAL, 4); // do fill
  // Wait
  while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
}

void box(unsigned int addr, int width, int height, int stride, int pix_per_byte, int c) {
   int l;
   for (l=0;l<height;l++) {
      if (pix_per_byte == 2)
         fill(addr, width / pix_per_byte, c | ( c << 4));
      else
         fill(addr, width / pix_per_byte, c | c << 2 | c << 4 | c << 6);
      addr+=stride;
   }
}

void wait_blitter(void) {
   while (PEEK(0xd03d) != 0) {}
}

void blit(int width, int height, long src_ptr, int sx, int sy,
          int src_stride, long dst_ptr, int dx, int dy,
          int dst_stride, unsigned char raster_flags, int wait) {
   POKE(0xd02fL, width >> 8); POKE(0xd030L, width & 0xff);
   POKE(0xd031L, height >> 8); POKE(0xd032L, height & 0xff);
   POKE(0xd035L, src_ptr >> 8); POKE(0xd036L, src_ptr & 0xff);
   POKE(0xd039L, sx & 0xff); POKE(0xd03aL, sx >> 8);
   POKE(0xd03cL, sy & 0xff);
   POKE(0xd03dL, src_stride & 0xff);
   POKE(0xd03bL, 32); // set

   POKE(0xd02fL, raster_flags);
   POKE(0xd035L, dst_ptr >> 8); POKE(0xd036L, dst_ptr & 0xff);
   POKE(0xd039L, dx & 0xff); POKE(0xd03aL, dx >> 8);
   POKE(0xd03cL, dy & 0xff);
   POKE(0xd03dL, dst_stride & 0xff);
   POKE(0xd03bL, 64); // set

   // We could do work with the CPU here instead of waiting
   // but this demo has nothing else to do.
   if (wait) {
     wait_blitter();
   }
}

