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
   int t,r;

   restore_colors_vmem(0x8000L);

   CLRSCRN;
   POKE (VIDEO_MODE1, 0);
   POKE (646L, 1);

   printf ("\n\n\n\n\n\n\n");
   printf ("the next video mode is a 640x200\n");
   printf ("resolution with 4 colors...\n\n");

   return 0;
}
