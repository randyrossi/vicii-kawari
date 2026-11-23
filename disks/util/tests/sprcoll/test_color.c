// Sprite to background collisions for the packed pixel modes.
//
// Policy: a pixel is foreground if its color is not the background
// color in $d021. Nothing outside the display window is foreground
// no matter what $d021 is set to.

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

// Fill the whole bitmap with color 5 and check $d021 selects whether
// it is background or foreground.
static int key_check(void) {
   POKE(0xd021L, 5);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 0);
   EXPECT_EQ(coll_at(SPR_X0, SPR_Y0), 0);
   EXPECT_EQ(coll_at(SPR_X0 + 319, SPR_Y0 + 199), 0);
   POKE(0xd021L, 0);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);
   EXPECT_EQ(coll_at(SPR_X0, SPR_Y0), 1);
   EXPECT_EQ(coll_at(SPR_X0 + 319, SPR_Y0 + 199), 1);
   // Only the low nibble of $d021 matters
   POKE(0xd021L, 0xf5);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 0);
   return 0;
}

int c16_320_key(void) {
   set_hires_mode(2); // 320x200x16
   POKE(VIDEO_MODE2, 0);
   fill(0, 160 * 200, 0);
   POKE(0xd021L, 0);

   // One pixel of color 5 at x=100. It is the same width as a sprite
   // pixel but pixels in this mode are drawn half a sprite pixel
   // (one 640 pixel) to the right. So it lies under the right half of
   // sprite pixel 100 and the left half of 101 and both collide.
   vpoke(LINE * 160 + 50, 0x50);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x0c);
   // Low nibble is the pixel to the right
   vpoke(LINE * 160 + 50, 0x05);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x18);

   fill(0, 160 * 200, 0x55);
   return key_check();
}

int c16_160_key(void) {
   set_hires_mode(4); // 160x200x16
   POKE(VIDEO_MODE2, 0);
   fill(0, 80 * 200, 0);
   POKE(0xd021L, 0);

   // One pixel of color 5 at x=50. Two sprite pixels wide.
   vpoke(LINE * 80 + 25, 0x50);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x0c);

   fill(0, 80 * 200, 0x55);
   return key_check();
}

int c4_key(void) {
   set_hires_mode(3); // 640x200x4
   POKE(VIDEO_MODE2, 0); // color bank 0
   fill(0, 160 * 200, 0x55); // every pixel is index 1

   // Bank 0 : index 1 is color 1
   POKE(0xd021L, 1);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 0);
   POKE(0xd021L, 0);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);

   // Bank 1 : index 1 is color 5. The color bank is part of the
   // color that gets compared with $d021.
   POKE(VIDEO_MODE2, 1 << 4);
   POKE(0xd021L, 1);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);
   POKE(0xd021L, 5);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 0);
   return 0;
}

int border_neg(void) {
   unsigned char mode;
   unsigned char shift;

   // Every pixel of the bitmap is foreground and so is the 'color 0'
   // seen when there is no pixel data, since $d021 is not 0.
   for (mode = 2; mode <= 4; mode++) {
      // The last pixel of a 320x200x16 line extends half a sprite
      // pixel past the window (see c16_320_key).
      shift = (mode == 2) ? 1 : 0;
      set_hires_mode(mode);
      POKE(VIDEO_MODE2, 0);
      fill(0, 160 * 200, 0x55);
      POKE(0xd021L, 2);

      // Sanity check. Inside the window does collide.
      EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);
      // Top and bottom borders
      EXPECT_EQ(coll_at(SPR_X0 + 100, SPR_Y0 - 1), 0);
      EXPECT_EQ(coll_at(SPR_X0 + 100, SPR_Y0 - 20), 0);
      EXPECT_EQ(coll_at(SPR_X0 + 100, SPR_Y0 + 200), 0);
      // Left and right borders
      EXPECT_EQ(coll_at(SPR_X0 - 1, SY), 0);
      EXPECT_EQ(coll_at(SPR_X0 - 14, SY), 0);
      EXPECT_EQ(coll_at(SPR_X0 + 320 + shift, SY), 0);
      EXPECT_EQ(coll_at(SPR_X0 + 326, SY), 0);
      // Edges of the window still collide
      EXPECT_EQ(coll_at(SPR_X0, SPR_Y0), 1);
      EXPECT_EQ(coll_at(SPR_X0 + 319, SPR_Y0 + 199), 1);
   }
   return 0;
}
