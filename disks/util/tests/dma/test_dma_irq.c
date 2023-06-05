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

int dma_irq(void) {
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

   POKE(53265L,PEEK(53265L) | 32); // standard bitmap
   POKE(56576L,(PEEK(56576L) & 0xfc) | 2); // VIC2 16k base
   POKE(53272L,29); // move bitmap to 16k+8192

   // Put bit pattern 01010101 into vmem @0
   fill(0, 8000, 85,1);
   // Put bit pattern 11111111 into vmem @8k
   fill(8192, 8000, 0xff,1);

   // Put color pattern 00010010 into vmem @16k
   fill(16384, 1000, 18,1);

   POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);

   // First color matrix
   // Vmem src 
   POKE(VIDEO_MEM_2_LO, 0x00);
   POKE(VIDEO_MEM_2_HI, 0x40);
   // DRAM dest (actually 0x4400 in bank 2)
   POKE(VIDEO_MEM_1_LO, 0x00);
   POKE(VIDEO_MEM_1_HI, 0x04);
   // 8000
   POKE(VIDEO_MEM_1_IDX, 0xe8);
   POKE(VIDEO_MEM_2_IDX, 0x03);
   POKE(VIDEO_MEM_1_VAL, DMA_VMEM_TO_DRAM);
   
   while (PEEK(VIDEO_MEM_2_IDX) != 0);

   // Reset shared flag
   asm ("lda #0\n");
   asm ("sta $fc\n");

   // Now pixel data
   // Vmem src 
   POKE(VIDEO_MEM_2_LO, 0);
   POKE(VIDEO_MEM_2_HI, 0);
   // DRAM dest (actually 0x6000 in bank 2)
   POKE(VIDEO_MEM_1_LO, 0x00);
   POKE(VIDEO_MEM_1_HI, 0x20);
   // 8000
   POKE(VIDEO_MEM_1_IDX, 0xe0);
   POKE(VIDEO_MEM_2_IDX, 0x1f);

   // Wait for raster line 53 so we have as few cycles that will
   // perform dma as possible for this frame....
   while(PEEK(0xd012L) != 53) { }
   while(PEEK(0xd012L) == 53) { }

   // initiate dma transfer
   POKE(VIDEO_MEM_1_VAL, DMA_VMEM_TO_DRAM);

   while (PEEK(0xfcL) == 0);

   // Now 2nd set of pixel data
   // Vmem src 

   POKE(VIDEO_MEM_2_LO, 0x00);
   POKE(VIDEO_MEM_2_HI, 0x20);
   // DRAM dest (actually 0x6000 in bank 2)
   POKE(VIDEO_MEM_1_LO, 0x00);
   POKE(VIDEO_MEM_1_HI, 0x20);
   // Only do 16 bytes so we can see the partial progress if no wait
   POKE(VIDEO_MEM_1_IDX, 0x10);
   POKE(VIDEO_MEM_2_IDX, 0x00);
   POKE(VIDEO_MEM_1_VAL, DMA_VMEM_TO_DRAM);

   while (PEEK(0xfcL) == 0);

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

   // Back to normal
   POKE(53265L,PEEK(53265L) & ~32); // bitmap off
   POKE(56576L,(PEEK(56576L) & 0xfc) | 3); // bank 0
   POKE(53272L,23); // back to normal screen

   asm ("lda #0\n");
   asm ("sta $fc\n");


   HIRES_OFF();

   return 0;
}
