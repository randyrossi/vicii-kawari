// Sprite to background collision tests that are not specific to one
// hires mode: which sprite bits get set, the irq, raster splits
// between hires and legacy modes and legacy behavior.

#include "tests.h"
#include "macros.h"

#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <hires.h>

#define LINE 100
#define SY (SPR_Y0 + LINE)

// Counts irqs
#define IRQ_COUNT 0xfcL

// 40 column screen cells under a sprite at SPLIT_X on the two lines
// used by the split and legacy tests.
#define SPLIT_X (SPR_X0 + 37 * 8)
#define LORES_Y (SPR_Y0 + 3 * 8)
#define HIRES_Y (SPR_Y0 + 16 * 8)
#define LORES_CELL (1024L + 3 * 40 + 37)
#define HIRES_CELL (1024L + 16 * 40 + 37)
#define SPLIT_START 120
#define SPLIT_END 250

// 160x200x16 with a block of color 5 on LINE that is under sprite
// pixels 96-103. Everything else is color 0 = $d021 = background.
static void block_setup(void) {
   set_hires_mode(4);
   POKE(VIDEO_MODE2, 0);
   fill(0, 80 * 200, 0);
   fill(LINE * 80 + 24, 2, 0x55);
   POKE(0xd021L, 0);
}

int spr_bits(void) {
   block_setup();

   // Sprite 0 on the block, sprite 1 off it
   spr_pos(0, SPR_X0 + 100, SY);
   spr_pos(1, SPR_X0 + 200, SY);
   spr_on(3);
   EXPECT_EQ(coll(), 1);

   // Swap them
   spr_pos(0, SPR_X0 + 200, SY);
   spr_pos(1, SPR_X0 + 100, SY);
   EXPECT_EQ(coll(), 2);

   // Both on the block
   spr_pos(0, SPR_X0 + 98, SY);
   EXPECT_EQ(coll(), 3);

   // Neither
   spr_pos(0, SPR_X0 + 200, SY);
   spr_pos(1, SPR_X0 + 210, SY);
   EXPECT_EQ(coll(), 0);

   // The sprite to background priority bit has no effect
   POKE(0xd01bL, 1);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);
   POKE(0xd01bL, 0);

   // X expanded. The one sprite pixel is now two wide so it also
   // collides when it starts one to the left of the block.
   POKE(0xd01dL, 1);
   EXPECT_EQ(coll_at(SPR_X0 + 95, SY), 1);
   EXPECT_EQ(coll_at(SPR_X0 + 94, SY), 0);
   POKE(0xd01dL, 0);

   // Multicolor sprite. With data $40, a hires sprite has one pixel
   // at x+1 but a multicolor sprite has a double wide pixel (bit
   // pair 01) at x and x+1. Place it so only x is on the block.
   POKE(0x0340L, 0x40);
   EXPECT_EQ(coll_at(SPR_X0 + 103, SY), 0);
   POKE(0xd01cL, 1);
   EXPECT_EQ(coll_at(SPR_X0 + 103, SY), 1);
   POKE(0xd01cL, 0);
   POKE(0x0340L, 0x80);
   return 0;
}

// CIA irqs are off while this is installed so the only source is the
// sprite to background collision. Acks the irq but deliberately does
// not read $d01f.
static void mbc_irq(void) {
   asm("inc $fc\n"
       "lda #2\n"
       "sta $d019\n"
       "jmp $ea81\n");
}

static void wait_frames(unsigned char n) {
   while (n--) wait_frame();
}

static int irq_checks(void) {
   // Collision every frame but only one irq until $d01f is read
   spr_pos(0, SPR_X0 + 100, SY);
   spr_on(1);
   wait_frames(4);
   EXPECT_EQ(PEEK(IRQ_COUNT), 1);

   // Reading $d01f re-arms it
   EXPECT_EQ(PEEK(M2D_REG), 1);
   wait_frames(3);
   EXPECT_EQ(PEEK(IRQ_COUNT), 2);

   // No collision, no irq
   spr_pos(0, SPR_X0 + 200, SY);
   wait_frame();
   CLR_M2D();
   wait_frames(2); // may get one more from the frame in progress
   POKE(IRQ_COUNT, 0);
   CLR_M2D();
   wait_frames(3);
   EXPECT_EQ(PEEK(IRQ_COUNT), 0);

   // Masked. The status bit is still set but there is no irq.
   POKE(0xd01aL, 0);
   POKE(0xd019L, IRQ_MBC);
   spr_pos(0, SPR_X0 + 100, SY);
   CLR_M2D();
   wait_frames(3);
   EXPECT_EQ(PEEK(IRQ_COUNT), 0);
   EXPECT_EQ(PEEK(0xd019L) & IRQ_MBC, IRQ_MBC);
   EXPECT_EQ(PEEK(M2D_REG), 1);
   return 0;
}

int irq_once(void) {
   unsigned int addr;
   unsigned char lo;
   unsigned char hi;
   int res;

   block_setup();
   spr_on(0);

   lo = PEEK(0x0314L);
   hi = PEEK(0x0315L);
   addr = (unsigned int) mbc_irq;

   SEI();
   POKE(0xdc0dL, 0x7f); // CIA 1 irqs off
   reg_sink = PEEK(0xdc0dL);
   POKE(0x0314L, addr & 0xff);
   POKE(0x0315L, addr >> 8);
   POKE(IRQ_COUNT, 0);
   CLR_M2D();
   POKE(0xd019L, IRQ_MBC);
   POKE(0xd01aL, IRQ_MBC);
   CLI();

   res = irq_checks();

   SEI();
   POKE(0xd01aL, 0);
   POKE(0xd019L, IRQ_MBC);
   POKE(0x0314L, lo);
   POKE(0x0315L, hi);
   POKE(0xdc0dL, 0x81); // CIA 1 timer irq back on
   CLI();
   return res;
}

// Runs two frames with hires enabled only between raster lines
// SPLIT_START and SPLIT_END. Returns the collisions latched.
static unsigned char split_coll(unsigned int x, unsigned char y) {
   unsigned char on;
   unsigned char off;
   unsigned char f;
   unsigned char result;

   on = PEEK(VIDEO_MODE1) | 16;
   off = on & 239;
   spr_pos(0, x, y);
   spr_on(1);

   SEI();
   POKE(VIDEO_MODE1, off);
   wait_frame();
   CLR_M2D();
   for (f = 0; f < 2; f++) {
      while (PEEK(0xd012L) != SPLIT_START) {}
      POKE(VIDEO_MODE1, on);
      while (PEEK(0xd012L) != SPLIT_END) {}
      POKE(VIDEO_MODE1, off);
   }
   result = PEEK(M2D_REG);
   CLI();
   return result;
}

int split(void) {
   unsigned char lores_save;
   unsigned char hires_save;
   int res = 0;

   lores_save = PEEK(LORES_CELL);
   hires_save = PEEK(HIRES_CELL);

   set_hires_mode(2);
   POKE(VIDEO_MODE2, 0);
   fill(0, 160 * 200, 0x55);

   // Hires bitmap is all foreground, 40 column cells are blank.
   // Only the sprite in the hires part of the frame collides.
   POKE(0xd021L, 0);
   POKE(LORES_CELL, 32);
   POKE(HIRES_CELL, 32);
   if (split_coll(SPLIT_X, LORES_Y) != 0) { printf ("a"); res = 1; }
   if (split_coll(SPLIT_X, HIRES_Y) != 1) { printf ("b"); res = 1; }

   // Hires bitmap is all background, 40 column cells are solid.
   // Only the sprite in the legacy part of the frame collides.
   POKE(0xd021L, 5);
   POKE(LORES_CELL, 160);
   POKE(HIRES_CELL, 160);
   if (split_coll(SPLIT_X, LORES_Y) != 1) { printf ("c"); res = 1; }
   if (split_coll(SPLIT_X, HIRES_Y) != 0) { printf ("d"); res = 1; }

   POKE(LORES_CELL, lores_save);
   POKE(HIRES_CELL, hires_save);
   return res;
}

// With hires off, the contents of hires video memory must have no
// effect and the 40 column screen decides as it always did.
int legacy(void) {
   unsigned char save;
   int res = 0;

   save = PEEK(LORES_CELL);

   // All foreground as far as the hires mode is concerned
   set_hires_mode(2);
   POKE(VIDEO_MODE2, 0);
   fill(0, 160 * 200, 0x55);
   POKE(0xd021L, 0);
   EXPECT_EQ(coll_at(SPLIT_X, LORES_Y), 1);

   HIRES_OFF();
   POKE(LORES_CELL, 32);
   if (coll_at(SPLIT_X, LORES_Y) != 0) { printf ("a"); res = 1; }
   POKE(LORES_CELL, 160);
   if (coll_at(SPLIT_X, LORES_Y) != 1) { printf ("b"); res = 1; }
   // One pixel either side of the 8 pixel wide cell
   if (coll_at(SPLIT_X - 1, LORES_Y) != 0) { printf ("c"); res = 1; }
   if (coll_at(SPLIT_X + 8, LORES_Y) != 0) { printf ("d"); res = 1; }

   // All background as far as the hires mode is concerned
   POKE(0xd021L, 5);
   if (coll_at(SPLIT_X, LORES_Y) != 1) { printf ("e"); res = 1; }

   POKE(LORES_CELL, save);
   return res;
}
