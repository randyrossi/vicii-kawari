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

int test_copy_irq(void) {
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


   HIRES_ON();
   set_hires_mode(3); // 640x200x4
   POKE(53304L, 0); // $0000

   fill(0, stride * 200, 0,1); // clear

   // Draw colored boxes in a row at the top (full width of screen)
   for (c=0;c<=15;c++) {
      box(c*10, 40,40,stride,4,c&3,1);
   }

   POKE(VIDEO_MEM_1_IDX, 0x00);
   POKE(VIDEO_MEM_2_IDX, 0x00);
   POKE(VIDEO_MEM_FLAGS, 0);
   POKE(VIDEO_MEM_FLAGS, 15);

   // Perform two copies back to back on to different areas of memory
   // Without the irq handler, the 2nd copy would interrupt the first

   // Clear our shared 'done' variable
   asm ("lda #0\n");
   asm ("sta $fc\n");
   copy(0);
   while (PEEK(0xfcL) == 0) {}
   // NOTE: If we didn't wait via irq, the next copy interrupts the first
   
   asm ("lda #0\n");
   asm ("sta $fc\n");
   copy(14400);
   while (PEEK(0xfcL) == 0) {}

   // Done
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
   HIRES_OFF();

   return 0;
}
