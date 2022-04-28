#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <string.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "color.h"

static struct regs r;

unsigned char black_level;

void delay(long v) { long t; for (t=0;t<v;t++) { } }

// Fill vmem
void fill(long addr, long size, char value) {
   POKE(VIDEO_MEM_1_IDX, 0x00);
   POKE(VIDEO_MEM_2_IDX, 0x00);
   POKE(VIDEO_MEM_FLAGS, 0);

   POKE(VIDEO_MEM_FLAGS, 15);

   POKE(VIDEO_MEM_1_LO, addr & 0xff); // dest
   POKE(VIDEO_MEM_1_HI, (addr >> 8) & 0xff);
   POKE(VIDEO_MEM_1_IDX, size & 0xff);
   POKE(VIDEO_MEM_2_IDX, (size >> 8) & 0xff);

   POKE(VIDEO_MEM_2_LO, value); // fill byte
   POKE(VIDEO_MEM_1_VAL, 4); // do fill

   // Wait for fill to be done
   while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
}

void copy_char_rom(void) {
  asm(" sei\n"
      " lda $01\n"
      " sta $fe\n"
      " lda #$d0\n"
      " sta $fc\n"
      " ldy #$00\n"
      " sty $fb\n"
      " lda #$00\n"
      " sta 53301\n"
      " sta 53302\n"
      " sta 53305\n"
      " sta 53306\n"
      " lda #1\n"
      " sta 53311\n"
      " ldx #$10\n"
"loop:\n"
      " lda #$33\n"
      " sta $01\n"
      " lda ($fb),y\n"
      " sta $fd\n"
      " lda #$37\n"
      " sta $01\n"
      " lda $fd\n"
      " sta 53307\n"
      " iny\n"
      " bne loop\n"
      " inc $fc\n"
      " dex\n"
      " bne loop\n"
      " lda $fe\n"
      " sta $01\n"
      " cli\n");
}

void prnt(char *str) {
   static int cx=0,cy=0;
   static unsigned char cur_col=1;
   long matrix;
   long color;
   int t;
   char escape;
   int ch;

   for (t=0;t<strlen(str);t++) {
      ch = str[t];
      if (ch == '<') {
         escape=1;
      }
      else if (escape && ch >= '0' && ch <='9') {
         cur_col = (cur_col & 0xf0) | (ch-'0'); // keep attrib
         escape=0;
      }
      else if (escape && ch == 'l') {
         cur_col |= 16; escape = 0;
      }
      else if (escape && ch == 'r') {
         cur_col |= 64; escape = 0;
      }
      else if (escape && ch == 'u') {
         cur_col |= 32; escape = 0;
      }
      else if (escape && ch == 's') {
         cur_col |= 128; escape = 0;
      }
      else if (escape && ch == '>') {
         cur_col = cur_col & 0xf; // turn off all attrib
         escape=0;
      }
      else if (ch == '\n') {
         cy++; cx = 0;
      }
      else { 
        matrix = 0x1000 + 80*cy+cx;
        color = 0x1800 + 80*cy+cx;
        POKE(VIDEO_MEM_1_LO,matrix & 0xff);
        POKE(VIDEO_MEM_1_HI,matrix >> 8);
        POKE(VIDEO_MEM_1_VAL,str[t]);
        POKE(VIDEO_MEM_1_LO,color & 0xff);
        POKE(VIDEO_MEM_1_HI,color >> 8);
        POKE(VIDEO_MEM_1_VAL,cur_col);
        cx++;
        if(cx>=80) { cy++; cx = 0; }
      }
   }
}

void scroll_up(void) {
   POKE(VIDEO_MEM_FLAGS,15);
   POKE(VIDEO_MEM_1_LO,0x00); // dest
   POKE(VIDEO_MEM_1_HI,0x10);
   POKE(VIDEO_MEM_2_LO,0x50); // src
   POKE(VIDEO_MEM_2_HI,0x10);
   POKE(VIDEO_MEM_1_IDX,0xb0); // 2k -80
   POKE(VIDEO_MEM_2_IDX,0x07); // 2k -80
   POKE(VIDEO_MEM_1_VAL,1); // copy
   while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
   POKE(VIDEO_MEM_1_LO,0x00); // dest
   POKE(VIDEO_MEM_1_HI,0x18);
   POKE(VIDEO_MEM_2_LO,0x50); // src
   POKE(VIDEO_MEM_2_HI,0x18);
   POKE(VIDEO_MEM_1_IDX,0xb0); // 2k -80
   POKE(VIDEO_MEM_2_IDX,0x07); // 2k -80
   POKE(VIDEO_MEM_1_VAL,1); // copy
   while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
   POKE(VIDEO_MEM_FLAGS,0);
}

void scroll_down(void) {
   POKE(VIDEO_MEM_FLAGS,15);
   POKE(VIDEO_MEM_1_LO,0x50); // dest
   POKE(VIDEO_MEM_1_HI,0x10);
   POKE(VIDEO_MEM_2_LO,0x00); // src
   POKE(VIDEO_MEM_2_HI,0x10);
   POKE(VIDEO_MEM_1_IDX,0xb0); // 2k -80
   POKE(VIDEO_MEM_2_IDX,0x07); // 2k -80
   POKE(VIDEO_MEM_1_VAL,2); // copy
   while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
   POKE(VIDEO_MEM_1_LO,0x50); // dest
   POKE(VIDEO_MEM_1_HI,0x18);
   POKE(VIDEO_MEM_2_LO,0x00); // src
   POKE(VIDEO_MEM_2_HI,0x18);
   POKE(VIDEO_MEM_1_IDX,0xb0); // 2k -80
   POKE(VIDEO_MEM_2_IDX,0x07); // 2k -80
   POKE(VIDEO_MEM_1_VAL,2); // copy
   while (PEEK(VIDEO_MEM_2_IDX) != 0) {}
   POKE(VIDEO_MEM_FLAGS,0);
}

void wait_frame(void) {
   while(PEEK(0xd012L) != 240) { }
   while(PEEK(0xd012L) == 240) { }
}

int main(void)
{
   int t,r;

enable_kawari();

   fill(0x1000,2048,32);
   fill(0x1800,2048,0);
   copy_char_rom();

   POKE (VIDEO_MODE1, 16);
   POKE (VIDEO_MODE2, 50);

   POKE (0xd018L, 23); // switch case

   prnt("\n<1this is a new 80 column video mode!\n\n");
   prnt("unlike soft-80 solutions which use hi-res graphics modes,\n"); 
   prnt("this mode is a true 80 column text mode.\n\n");
   prnt("each character cell is a full 8x8 bitmap with independent ");
   prnt("<3c<4o<5l<7o<8r\n");
   prnt("<1memory for each cell. the upper four bits of the color memory\n");
   prnt("are also used to control attributes like <lblink<>, <uunderline<>, \n");
   prnt("<rreverse<> and alternate character set (which allows all 512.\n");
   prnt("characters to be displayed at the same time).\n");
   prnt("\nalso, there are hardware supported memory move routines that make\n");
   prnt("scrolling very fast. try out the 80col-51200 wedge on the demo\n");
   prnt("disk or the novaterm 80 column driver!");

   delay(20000L);

   for (t=0;t<10;t++) {
    for (r=0;r<8;r++) {
      scroll_down(); wait_frame();
    }
    for (r=0;r<8;r++) {
      scroll_up(); wait_frame();
    }
   }

   delay(5000L);

   CLRSCRN;
   POKE (VIDEO_MODE1, 0);

   POKE(646L,1);
   POKE(53272L,21); // upper case

   printf ("\n\n\n\n\n\n\n\n\nthis next mode demonstrates a new\n");
   printf ("320x200 mode with 16 colors. each\n");
   printf ("pixel can have an independent color\n");
   printf ("and since the palette is configurable,\n");
   printf ("we can install custom colors for\n");
   printf ("a better image.\n");
 
   return 0;
}
