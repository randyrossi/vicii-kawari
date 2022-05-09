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

void show_col(unsigned char rv, unsigned char gv, unsigned char bv) {
   static char first_show = 1;
   static char cr = 0;
   static char cg = 0;
   static char cb = 0;
   unsigned char rv2,gv2,bv2;
   int i;

   if (first_show) {
     first_show = 0;
     // Use printf to get color set as well
     TOXY(0,22); printf ("r                                     ");
     TOXY(0,23); printf ("g                                     ");
     TOXY(0,24); printf ("b                                     ");
   }

   rv2=rv>>1;
   gv2=gv>>1;
   bv2=bv>>1;

   if (rv2 > cr) {
      for (i=cr;i<=rv2;i++) {
         POKE(1906+i,65);
      }
   } else if (rv2 < cr) {
      for (i=cr;i>=rv2;i--) {
         POKE(1906+i,32);
      }
   }

   if (gv2 > cg) {
      for (i=cg;i<=gv2;i++) {
         POKE(1946+i,65);
      }
   } else if (gv2 < cg) {
      for (i=cg;i>=gv2;i--) {
         POKE(1946+i,32);
      }
   }

   if (bv2 > cb) {
      for (i=cb;i<=bv2;i++) {
         POKE(1986+i,65);
      }
   } else if (bv2 < cb) {
      for (i=cb;i>=bv2;i--) {
         POKE(1986+i,32);
      }
   }

   cr=rv2;
   cg=gv2;
   cb=bv2;
}

void slide(int color) {
   unsigned char r,g,b;
   unsigned char rreg,greg,breg;
   unsigned char hreg,sreg,vreg;
   unsigned char h,s,v;
   int dr,dg,db;
   int i;

   dr=2;dg=-1;db=1;

   get_col(color, &r, &g, &b);

   for (i=0;i<64;i++) {
      r=r+dr;
      if (r>63) { r = 63; dr=-dr;}
      if (r>=255) { r = 0; dr=-dr;}
      g=g-dg;
      if (g>63) { g = 63; dg=-dg;}
      if (g>=255) { g = 0; dg=-dg;}
      b=b+db;
      if (b>63) { b = 63; db=-db;}
      if (b>=255) { b = 0; db=-db;}

      show_col(r,g,b);
      prep_col(color, &rreg, &greg, &breg, r, g, b,
                   &hreg, &sreg, &vreg, &h, &s, &v, black_level);
      set_col(rreg,greg,breg,r,g,b,hreg,sreg,vreg,h,s,v);
   }
}

void sweep() {
   unsigned char r,g,b;
   unsigned char rreg,greg,breg;
   unsigned char hreg,sreg,vreg;
   unsigned char h,s,v;
   int dr,dg,db;
   int i,j;

   static int ir[7] = { 20,20,20,8,8,8,8 };
   static int ig[7] = { 20,8,8,20,20,8,8 };
   static int ib[7] = { 8,20,8,20,8,20,8 };

   static int wr[7] = { 0,0,0,3,3,3,3 };
   static int wg[7] = { 0,3,3,0,0,3,3 };
   static int wb[7] = { 3,0,3,0,3,0,3 };

   POKE(1904,32);
   POKE(1944,32);
   POKE(1984,32);
   show_col(0,0,0);

   for (j=0;j<7;j++) {
      r=8;g=8;b=8;
      dr=wr[j];dg=wg[j];db=wb[j];
      for (i=1;i<16;i++) {
        //show_col(r,g,b);
        prep_col(i, &rreg, &greg, &breg, r, g, b,
                  &hreg, &sreg, &vreg, &h, &s, &v, black_level);
        set_col(rreg,greg,breg,r,g,b,hreg,sreg,vreg,h,s,v);
        r=r+dr;g=g+dg;b=b+db;
        delay(20);
      }
   }
}

int main(void)
{
   int color;
   CLRSCRN;

   printf ("\n\n\n\n\n\n\n\n\nyour vic-ii kawari adds some\n");
   printf ("extra features never before available\n");
   printf ("on the commodore 64.\n\n");

   printf ("let's start with the basics...\n");

   POKE (53303L,0); // turn off hires

   restore_colors_vmem(0x8000L);

   delay(15000L);

   CLRSCRN;
   POKE(646L,15);
   printf ("              color palette\n\n");
   printf ("the 16 color palette is configurable!\n\n");
   for (color=0;color < 15;color++) {
      POKE(646L,color);
      printf ("     %c                              \n",18);
   }

   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);

   // Grab blanking level
   POKE(VIDEO_MEM_1_LO, 0x80);
   black_level = PEEK(VIDEO_MEM_1_VAL);
   
   for (color=1;color<15;color++) {
      slide(color);
   }

   sweep();

   delay(2000L);

   CLRSCRN;

   restore_colors_vmem(0x8000L);

   POKE(646L,1);
   printf ("\n\n\n\n\n\n\n\nvic-ii kawari has an additional\n");
   printf ("64k of video ram. this ram can be used for\n");
   printf ("new hires graphics modes...\n");

   return 0;
}
