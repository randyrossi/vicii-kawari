#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <hires.h>

static struct regs r;
static const int stride = 160;

static void iirq_handler(void) {

   asm("pha\n"
       "txa\n"
       "pha\n"
       "tya\n"
       "pha\n"
   );

   POKE (0xfcL,1);
   POKE (0xD019,16); // clear dma interrupt
   asm ("inc $d020");

   asm("pla\n"
       "tay\n"
       "pla\n"
       "tax\n"
       "pla\n"
   );
   asm("JMP $ea31");
}

int test_blit_irq(void) {
   int c;
   unsigned int addr;

   // Setup dma interrupt handler
   asm(
      "sei\n"                  // set interrupt bit, make the CPU ignore interrupt requests
      "lda #$7f\n"             // switch off interrupt signals from CIA-1
      "sta $DC0D\n"
      "lda $DC0D\n"            // acknowledge pending interrupts from CIA-1
      "lda $DD0D\n"            // acknowledge pending interrupts from CIA-2
);

   addr = (unsigned int) iirq_handler;
   POKE(0x0314L, addr & 0xff);
   POKE(0x0315L, (addr >> 8) & 0xff);

   asm ("lda #$10\n"            // enable DMA interrupt signals from VIC
        "sta $D01A\n"
        "cli\n"                 // clear interrupt flag
       );


   set_hires_mode(3); // 640x200x4
   POKE(53304L, 0); // $0000
   fill(0, stride * 200, 0); // clear

   // Draw colored boxes in a row at the top (full width of screen)
   for (c=0;c<=15;c++) {
      box(c*10, 40,40,stride,4,c&3);
   }
   // Perform multiple blits. Since there is a lot of data, if we don't
   // wait until the blt is complete, the next blit will interrupt the
   // in progress one and result in bad render.  This test makes sure
   // we wait using an irq handler to signal done instead of polling.
   for (c=0;c<=15;c++) {
   
      // Clear our shared 'done' variable
      asm ("lda #0\n");
      asm ("sta $fc\n");

      blit(640-c*2, //width
        40-c*2, //height
        0,    //src_ptr
        0, //sx
        0, //sy
        stride, // stride
        0, // dest_ptr
        0, // dx
        100, // dy
        stride, // stride
        0, // flags
        0); // don't poll wait
 
      // Wait for interrupt handler to signal done
      while (PEEK(0xfcL) == 0) {}
   }

   asm (
      "sei\n"
      "lda #$81\n"       // turn CIA1 interrupts back on
      "sta $DC0D\n"
      "lda #$00\n"       // turn off all interrupts
      "sta $D01A\n"
   );
   POKE(0x0314L, 0x31);
   POKE(0x0315L, 0xea);
   asm ("cli\n");

   WAITKEY;

   return 0;
}
