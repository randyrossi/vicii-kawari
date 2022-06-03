#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <string.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "color.h"

static struct regs r;

void delay(long v) { long t; for (t=0;t<v;t++) { } }

void clear_bitmap() {
   // Fill 32k @ 0x0000 
   POKE(VIDEO_MEM_1_LO, 0x00);
   POKE(VIDEO_MEM_1_HI, 0x00);
   POKE(VIDEO_MEM_1_IDX, 0);
   POKE(VIDEO_MEM_2_IDX, 0x80); // 32k
   POKE(VIDEO_MEM_2_LO, 0); // fill 0
   POKE(VIDEO_MEM_1_VAL, 4); // execute

   // Wait for fill
   while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
/*
asm ("wait5:\n"
     " lda $d012\n"
     " cmp #247\n"
     " bne wait5\n");
*/
}

void wait_frame() {
   asm ("wait_frame:\n"
     " lda $d012\n"
     " cmp #250\n"
     " bne wait_frame\n");
}

// Blitter is done when d03d is 0
void wait_blitter() {
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

int main(void)
{
   int ball_x=0,ball_y=100;
   int back_x=100; int back_y=40;
   int delta_x=1,delta_y=1,delta_back_x=1;
   int stage = 0;
   long frame = 0;

   CLRSCRN;
   POKE (VIDEO_MODE1, 0);
   POKE (53269L, 0);
   POKE (646L, 1);

   printf ("a hires graphics blitter is available\n");
   printf ("that makes copying and/or modifying\n");
   printf ("rectangular bitmaps fast.\n\n");
   printf ("the blitter supports source pixel\n");
   printf ("copy, 'and', 'or' and 'xor'\n");
   printf ("operations. there is also an option to\n");
   printf ("make one color in the source bitmap\n");
   printf ("transparent when applied to the\n");
   printf ("destination.\n\n");
   printf ("the moving objects in the next\n");
   printf ("segment are not sprites. they are\n");
   printf ("drawn each frame using the blitter.\n");

   // load bitmap data to 0x8000
   asm( "lda #1\n"
        "sta $816\n" // directVmem yes
        "lda #0\n"
        "sta $d035\n"  // idx
        "lda #1\n" // auto inc to vmem
        "sta $d03f\n"
        "ldx #$44\n" // D
        "ldy #$33\n" // 3
        "jsr $810\n"); // fastload

   // Stuff these at very last row of memory so it doesn't interfere with
   // the offscreen bitmap data
   save_colors_vmem(0xFFFFL - 160); // stuff 

   // load colors
   asm( "lda #0\n"
        "sta $816\n" // directVmem no
        "lda #0\n"
        "sta $d035\n"  // idx
        "lda #1\n" // auto inc to vmem
        "sta $d03f\n"
        "ldx #$44\n" // D
        "ldy #$34\n" // 4
        "jsr $810\n" // fastload
        "jsr $813\n"); // install colors we just read

/*
// For testing in simulator
asm ("wait:\n"
     " lda $d012\n"
     " cmp #247\n"
     " bne wait\n"
"wait4:\n"
     " lda $d012\n"
     " cmp #247\n"
     " beq wait4\n"
     " lda #1\n"
     " sta $d3ff\n"
"wait2:\n"
     " lda $d012\n"
     " cmp #247\n"
     " bne wait2\n"
"wait3:\n"
     " lda $d012\n"
     " cmp #247\n"
     " beq wait3\n"
);
*/

   POKE (VIDEO_MODE1, 16+64); // 320x200
   POKE (VIDEO_MODE2, 0); // 0x0000 base
   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);

   for (;;) {
      // Wait for rasterline to hit bottom of screen
      wait_frame();

      // Draw next frame
      clear_bitmap();

      blit(120,120,
        0x8000,0,0,160,
        0x0000,back_x,back_y,160,
        0,1 /* wait*/);
      blit(100,59,
        0x8000,220,0,160,
        0x0000,ball_x,ball_y,160,
        16+8, 0 /* no wait */); // transparency on for index 1

      // We can use the CPU while the blitter works
      // Always bounce the ball
      ball_x = ball_x + delta_x;
      ball_y = ball_y + delta_y;
      if (ball_x < 0 | ball_x >= 220) {
          ball_x = ball_x - delta_x; delta_x = -delta_x;
      }
      // We can't go too high for the ball because
      // there wasn't enough bandwidth to clear the screen, 
      // copy the large background bitmap and the ball before the
      // raster line hits the top.  We might be able to squeeze more
      // by starting the frame slightly before the last visible line
      // but I'm keeping it this way since its just a demo.
      if (ball_y < 50 | ball_y >= 140) {
          ball_y = ball_y - delta_y; delta_y = -delta_y;
      }
      if (stage > 0) {
          // Move the background gfx now
          back_x = back_x + delta_back_x;
          if (back_x < 0 || back_x >=200) {
            back_x = back_x - delta_back_x;
            delta_back_x = -delta_back_x;
          }
      }
      frame++;
      if (frame > 360)
         stage = 1;
      if (frame > 2400)
         break;
      // Wait for blitter to be done
      wait_blitter();
   }

   restore_colors_vmem(0xFFFFL - 160); // stuff 

   POKE (VIDEO_MODE1, 0);
   POKE (53280,0);
   POKE (53281,0);
   POKE (646L, 1);
   CLRSCRN;

   printf ("thanks for watching!\n\n");

   printf ("goto www.accentual.com/vicii-kawari\n");
   printf ("for the latest news on vicii-kawari\n");
   printf ("boards\n");

   for (;;) { }

   return 0;
}
