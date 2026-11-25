// Sprite to background collisions for mode 000 (80 column text).
//
// Policy: a pixel is foreground if the glyph bit is set, flipped by
// the reverse attribute, or if it is on the underline row of a cell
// with the underline attribute. Blink and the cursor are ignored.

#include "tests.h"
#include "macros.h"

#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <hires.h>

// Cell under test
#define COL 40
#define ROW 10
#define CELL (ROW * 80 + COL)
// Each 80 column cell is 4 sprite pixels wide
#define CX (SPR_X0 + COL * 4)
#define CY (SPR_Y0 + ROW * 8)

// Char 0 is blank, char 1 is solid. All cells show char 0 in white.
static void text_setup(void) {
   set_hires_mode(0);
   // CHAR_PIXEL_BASE = 0
   POKE(VIDEO_MODE1, PEEK(VIDEO_MODE1) & ~7);
   POKE(VIDEO_MODE2, (TXT_MATRIX >> 11) | ((TXT_COLOR >> 11) << 4));
   // The char set used depends on the upper/lower case bit of $d018
   // (cc65 programs start in lower case) so define both.
   fill(TXT_CHARS, 16, 0);
   fill(TXT_CHARS + 8, 8, 0xff);
   fill(TXT_CHARS + 0x800, 16, 0);
   fill(TXT_CHARS + 0x800 + 8, 8, 0xff);
   fill(TXT_MATRIX, 80 * 25, 0);
   fill(TXT_COLOR, 80 * 25, 1);
   POKE(0xd021L, 0);
}

int text_pos(void) {
   text_setup();
   vpoke(TXT_MATRIX + CELL, 1);
   // All four corners of the solid cell
   EXPECT_EQ(coll_at(CX, CY), 1);
   EXPECT_EQ(coll_at(CX + 3, CY), 1);
   EXPECT_EQ(coll_at(CX, CY + 7), 1);
   EXPECT_EQ(coll_at(CX + 3, CY + 7), 1);
   return 0;
}

int text_neg(void) {
   text_setup();
   // Nothing but blanks
   EXPECT_EQ(coll_at(CX, CY), 0);
   // Solid cell with the sprite just outside each edge
   vpoke(TXT_MATRIX + CELL, 1);
   EXPECT_EQ(coll_at(CX - 1, CY), 0);
   EXPECT_EQ(coll_at(CX + 4, CY), 0);
   EXPECT_EQ(coll_at(CX, CY - 1), 0);
   EXPECT_EQ(coll_at(CX, CY + 8), 0);
   // Sprite over the cell but disabled
   spr_pos(0, CX, CY);
   spr_on(0);
   EXPECT_EQ(coll(), 0);
   return 0;
}

int text_attr(void) {
   text_setup();

   // Reverse blank = solid
   vpoke(TXT_COLOR + CELL, 1 | ATTR_RVRS);
   EXPECT_EQ(coll_at(CX, CY + 3), 1);

   // Reverse solid = blank
   vpoke(TXT_MATRIX + CELL, 1);
   EXPECT_EQ(coll_at(CX, CY + 3), 0);

   // Underlined blank only collides on the last row of the cell
   vpoke(TXT_MATRIX + CELL, 0);
   vpoke(TXT_COLOR + CELL, 1 | ATTR_UNDER);
   EXPECT_EQ(coll_at(CX, CY + 6), 0);
   EXPECT_EQ(coll_at(CX, CY + 7), 1);

   // Blink is ignored. A solid cell collides whether it is currently
   // shown or not, so sample over more than one blink period (the
   // blink toggles every 32 frames, coll() takes 2 frames).
   vpoke(TXT_MATRIX + CELL, 1);
   vpoke(TXT_COLOR + CELL, 1 | ATTR_BLINK);
   {
      unsigned char i;
      for (i = 0; i < 40; i++) {
         EXPECT_EQ(coll_at(CX, CY + 3), 1);
      }
   }

   // And a blinking blank never collides
   vpoke(TXT_MATRIX + CELL, 0);
   {
      unsigned char i;
      for (i = 0; i < 40; i++) {
         EXPECT_EQ(coll_at(CX, CY + 3), 0);
      }
   }
   return 0;
}
