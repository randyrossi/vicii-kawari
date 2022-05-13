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

int main(void)
{
   unsigned long src;
   unsigned int loop;
   unsigned char oldv;

// For testing standalone
//enable_kawari();
//save_colors_vmem(0x8000L);

   // This is about to get blown away by animation data.
   // So after we're done, should re-save it here.
   restore_colors_vmem(0x8000L);

   CLRSCRN;
   POKE (VIDEO_MODE1, 0);
   POKE (646L, 1);

   printf ("insert disk 2 and press a key\n\n");
   WAITKEY;

   printf ("the extra video ram can also be used to\n");
   printf ("to store data. a dma transfer is\n");
   printf ("available to quicky transfer up to 16k\n");
   printf ("of data from vram into dram.\n\n");

   printf ("this next sequence demonstrates how the\n");
   printf ("dma transfer can be used to show an\n");
   printf ("animation of 64 frames using very\n");
   printf ("little cpu. each frame is 1000 bytes\n");
   printf ("copied from vram into the screen memory\n");
   printf ("at 0x400 with only a few intructions.\n\n");

   printf ("this animation renders at 30 fps but\n");
   printf ("60 fps is also possible.\n\n");

   printf ("the next segment takes a while to load\n");
   printf ("please be patient\n\n");

   // falcon.char to 0x3000 dram
   asm( "lda #0\n"
        "sta $813\n" // directVmem no
        "lda #0\n"
        "sta $d035\n"  // idx
        "lda #1\n" // auto inc to vmem
        "sta $d03f\n" 
        "ldx #$44\n" // D
        "ldy #$31\n" // 1
        "jsr $810\n"); // fastload

   // falcon.lut to 0x0000 vmem
   asm( "lda #1\n"
        "sta $813\n" // directVmem yes
        "lda #0\n"
        "sta $d035\n"  // idx
        "lda #1\n" // auto inc to vmem
        "sta $d03f\n" 
        "ldx #$44\n" // D
        "ldy #$32\n" // 2
        "jsr $810\n"); // fastload

   // Now do the animation using DMA

   // Switch to custom char set
   CLRSCRN;
   oldv = PEEK(53272);
   POKE (53272L,PEEK(53272L) & 240 | 12);

   POKE (53280L,0);
   POKE (53281L,0);

   // Play frames

   // Set fg color for screen to light gray
   for (src=0xd800;src<0xdc00;src++) {
      POKE(src, 15);
   }
   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);

   src = 0L;
   // 64 frames, 6 x
   for (loop=0;loop < 6*64;loop++) {
      // Vmem src 
      POKE(VIDEO_MEM_2_LO, src & 0xff);
      POKE(VIDEO_MEM_2_HI, (src >> 8) & 0xff);
      // Dram dest @ 0x0400
      POKE(VIDEO_MEM_1_LO, 0x00);
      POKE(VIDEO_MEM_1_HI, 0x04);
      // 1000 bytes
      POKE(VIDEO_MEM_1_IDX, 0xe8);
      POKE(VIDEO_MEM_2_IDX, 0x03);

      // Do DMA
      POKE(VIDEO_MEM_1_VAL, DMA_VMEM_TO_DRAM);

      // Advance frame
      src=src+1024L;

      // wait for dma to be completed
      while (PEEK(VIDEO_MEM_2_IDX) != 0 || PEEK(VIDEO_MEM_1_IDX) != 0) { }

      // cheap way to wait for a frame
      while(PEEK(0xd012L) != 240) { }
      while(PEEK(0xd012L) == 240) { }

      // wait again, so we render 30 fps instead of 60
      while(PEEK(0xd012L) != 240) { }
      while(PEEK(0xd012L) == 240) { }
   }

   CLRSCRN;
   POKE (53272L,oldv);

   printf ("\n\n\n\n");
   printf ("vic-ii kawari also makes available\n");
   printf ("some hardware math operations for\n");
   printf ("16-bit signed and unsigned division\n");
   printf ("and multiplication\n");
   printf ("");
   printf ("the next example shows the mandelbrot\n");
   printf ("set being computed (in low resolution).\n");
   printf ("first using the 6510 CPU to perform\n");
   printf ("multiplications, then using vicii-kawari\n\n");

   printf ("press any key to continue\n");

   WAITKEY;

   return 0;
}
