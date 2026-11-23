// Sprite to background collisions for the 640 wide modes where there
// are two hires pixels under every sprite pixel.
//
//   mode 001 (640x200 color cells) : foreground if the pixel bit is set
//   mode 011 (640x200x4)           : foreground if color != $d021
//
// A sprite pixel collides if either hires pixel under it is foreground.

#include "tests.h"
#include "macros.h"

#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <hires.h>

// Line used for the single pixel tests
#define LINE 100
#define SY (SPR_Y0 + LINE)

static void cell_setup(void) {
   set_hires_mode(1);
   POKE(VIDEO_MODE2, 0 | (8 << 4)); // $0000 pixels, $4000 color cells
   fill(0, 80 * 200, 0);
   fill(0x4000, 80 * 25, 1);
   POKE(0xd021L, 0);
}

// Set (or clear) the only pixel on LINE in mode 001
static void cell_pixel(unsigned int hx, unsigned char on) {
   vpoke(LINE * 80 + (hx >> 3), on ? (0x80 >> (hx & 7)) : 0);
}

int cell_pos_neg(void) {
   cell_setup();

   // Empty bitmap
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 0);

   // A solid byte is 8 hires pixels = 4 sprite pixels wide
   vpoke(LINE * 80 + 25, 0xff); // hires x 200-207
   EXPECT_EQ(coll_at(SPR_X0 + 99, SY), 0);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);
   EXPECT_EQ(coll_at(SPR_X0 + 103, SY), 1);
   EXPECT_EQ(coll_at(SPR_X0 + 104, SY), 0);
   // Line above and below are empty
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY - 1), 0);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY + 1), 0);

   // The color of the cell makes no difference in this mode. A set
   // bit shown in the background color still collides.
   fill(0x4000, 80 * 25, 0);
   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 1);
   return 0;
}

int cell_halfpix(void) {
   cell_setup();

   // Left half of the sprite pixel at 100
   cell_pixel(200, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x04);
   cell_pixel(200, 0);

   // Right half of the sprite pixel at 100
   cell_pixel(201, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x04);
   cell_pixel(201, 0);

   // Left half of the next sprite pixel
   cell_pixel(202, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x08);
   cell_pixel(202, 0);

   // First and last pixels of the line
   cell_pixel(0, 1);
   EXPECT_EQ(sweep(SPR_X0, SY), 0x04);
   cell_pixel(0, 0);
   cell_pixel(639, 1);
   EXPECT_EQ(sweep(SPR_X0 + 319, SY), 0x04);
   cell_pixel(639, 0);
   return 0;
}

// Set (or clear) the only pixel on LINE in mode 011 to color index 1
static void c4_pixel(unsigned int hx, unsigned char on) {
   vpoke(LINE * 160 + (hx >> 2), on ? (0x40 >> ((hx & 3) * 2)) : 0);
}

int c4_halfpix(void) {
   set_hires_mode(3);
   POKE(VIDEO_MODE2, 0); // $0000, color bank 0
   fill(0, 160 * 200, 0);
   POKE(0xd021L, 0); // index 0 of bank 0 is the background

   EXPECT_EQ(coll_at(SPR_X0 + 100, SY), 0);

   c4_pixel(200, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x04);
   c4_pixel(200, 0);

   c4_pixel(201, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x04);
   c4_pixel(201, 0);

   c4_pixel(202, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x08);
   c4_pixel(202, 0);

   c4_pixel(203, 1);
   EXPECT_EQ(sweep(SPR_X0 + 100, SY), 0x08);
   c4_pixel(203, 0);
   return 0;
}
