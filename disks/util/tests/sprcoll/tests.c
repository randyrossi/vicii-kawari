#include <6502.h>
#include <peekpoke.h>

#include "kawari.h"
#include "util.h"
#include "hires.h"

#include "tests.h"

// Sprite data blocks 13 and 14 live in the cassette buffer. Sprites are
// always fetched from DRAM so they are not affected by hires video mem.
#define SPR0_DATA 0x0340
#define SPR1_DATA 0x0380

unsigned char reg_sink;

static unsigned char saved_d021;
static unsigned char saved_mode1;
static unsigned char saved_mode2;

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
  // Wait. Fill is finished when both counters reach 0. Checking both
  // matters for the small fills (< 256 bytes) these tests do.
  while (PEEK(VIDEO_MEM_2_IDX) != 0 || PEEK(VIDEO_MEM_1_IDX) != 0) {}
}

// Write one byte to video memory
void vpoke(unsigned int addr, unsigned char value) {
  POKE(VIDEO_MEM_FLAGS, 0);
  POKE(VIDEO_MEM_1_IDX, 0);
  POKE(VIDEO_MEM_1_LO, addr & 0xff);
  POKE(VIDEO_MEM_1_HI, addr >> 8);
  POKE(VIDEO_MEM_1_VAL, value);
}

// Returns just after the raster wraps to line 0
void wait_frame(void) {
  while (!(PEEK(0xd011L) & 0x80)) {}
  while (PEEK(0xd011L) & 0x80) {}
}

void test_begin(void) {
  unsigned char i;

  saved_d021 = PEEK(0xd021L);
  saved_mode1 = PEEK(VIDEO_MODE1);
  saved_mode2 = PEEK(VIDEO_MODE2);

  // Two sprites, each with a single pixel in the top left corner so
  // the sprite position is the position of the one pixel that can
  // collide.
  POKE(0xd015L, 0);
  for (i = 0; i < 63; i++) {
     POKE(SPR0_DATA + i, 0);
     POKE(SPR1_DATA + i, 0);
  }
  POKE(SPR0_DATA, 0x80);
  POKE(SPR1_DATA, 0x80);
  POKE(0x07f8L, SPR0_DATA / 64);
  POKE(0x07f9L, SPR1_DATA / 64);
  POKE(0xd010L, 0);
  POKE(0xd017L, 0); // no y expand
  POKE(0xd01bL, 0); // sprites in front
  POKE(0xd01cL, 0); // no multicolor
  POKE(0xd01dL, 0); // no x expand
  POKE(0xd027L, 1);
  POKE(0xd028L, 7);

  HIRES_ON();
}

void test_end(void) {
  POKE(0xd015L, 0);
  POKE(0xd010L, 0);
  POKE(0xd01cL, 0);
  POKE(VIDEO_MODE1, saved_mode1 & 239); // also turns hires off
  POKE(VIDEO_MODE2, saved_mode2);
  POKE(0xd021L, saved_d021);
  CLR_M2D();
}

void spr_pos(unsigned char n, unsigned int x, unsigned char y) {
  unsigned char bit = 1 << n;
  POKE(0xd000L + n * 2, x & 0xff);
  POKE(0xd001L + n * 2, y);
  if (x > 255)
     POKE(0xd010L, PEEK(0xd010L) | bit);
  else
     POKE(0xd010L, PEEK(0xd010L) & ~bit);
}

void spr_on(unsigned char mask) {
  POKE(0xd015L, mask);
}

// Clear the collision latch at the top of a frame, let one whole
// frame go by and return what was latched.
unsigned char coll(void) {
  wait_frame();
  CLR_M2D();
  wait_frame();
  return PEEK(M2D_REG);
}

// Collision result for sprite 0 alone at x,y
unsigned char coll_at(unsigned int x, unsigned char y) {
  spr_pos(0, x, y);
  spr_on(1);
  return coll();
}

// Try sprite 0 at x-2 .. x+3. Bit n of the result is set if there was
// a collision at x-2+n. So 0x04 means 'only at x' and 0x0c means 'only
// at x and x+1'. This catches any misalignment between the sprite and
// the hires pixel under it.
unsigned char sweep(unsigned int x, unsigned char y) {
  unsigned char i;
  unsigned char result = 0;
  for (i = 0; i < 6; i++) {
     if (coll_at(x - 2 + i, y) & 1)
        result |= (1 << i);
  }
  return result;
}
