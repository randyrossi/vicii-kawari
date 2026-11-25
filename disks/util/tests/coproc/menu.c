#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <hires.h>
#include <ops.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "init.h"

#include "tests.h"
#include "macros.h"
#include "cpu2.h"

#define COPROC_PROG_LO 0x00
#define COPROC_PROG_HI 0x02

#define CPU_START_LO  0x20
#define CPU_START_HI  0x21
#define CPU_CTRL      0x22
#define CPU_SPEED     0x2b

static struct regs r;

void main_menu(void)
{
    unsigned int dest;
    int reg;

    CLRSCRN;
    printf ("VIC-II Kawari Test Suite\n\n");

    dest = (unsigned int) &cpu2_o[0];
    if (dest > 16383) {
       POKE (53280L,2);
       POKE (53281L,2);
       printf ("ERROR: CPU2 code must be located in 1st 16k DRAM bank\n");
       return;
    }

#ifdef DEBUG_COPROC
    printf ("%x\n", dest);
    printf ("\n");
    for (reg=dest;reg<=dest+32;reg++) {
       printf ("%0x ", PEEK(reg));
    }
    printf ("\n");
#endif

    // 6502 Co-Processor code starts @$200.
    // NOT $100: $0100-$01ff is the co-processor's stack page, so code placed
    // there gets overwritten by its own stack on the first BRK or JSR.

    HIRES_ON();
    set_hires_mode(4); 
    POKE(53304L, 0b10); // gfx at $8000

    // Hold the co-processor in reset while we set it up.  Never rely on the
    // power-up state: if it comes up out of reset the core runs from $0000 and
    // its stack trashes page $0100-$01ff before we can load anything.
    POKE(VIDEO_MEM_FLAGS, 0x20); // overlay on (bit 5), no auto-increment
    POKE(VIDEO_MEM_1_HI, 0x00);
    POKE(VIDEO_MEM_1_LO, CPU_CTRL);
    POKE(VIDEO_MEM_1_VAL, 0x01); // RESET asserted

    // Copy our program to VMEM $200
    // This works because our cpu2 code is inside the first 16k so
    // we don't have to change VIC2 banks
    copy_dram_to_vmem(dest, 0x200, cpu2_o_len);

    // copy_dram_to_vmem() leaves the overlay off and the port config changed
    POKE(VIDEO_MEM_FLAGS, 0x20); // overlay on (bit 5), no auto-increment
    POKE(VIDEO_MEM_1_HI, 0x00); 

    POKE(VIDEO_MEM_1_LO, CPU_START_LO);
    POKE(VIDEO_MEM_1_VAL, COPROC_PROG_LO);

    POKE(VIDEO_MEM_1_LO, CPU_START_HI);
    POKE(VIDEO_MEM_1_VAL, COPROC_PROG_HI);

    POKE(VIDEO_MEM_1_LO, CPU_SPEED);
    POKE(VIDEO_MEM_1_VAL, 0x00);

    POKE(VIDEO_MEM_1_LO, CPU_CTRL);
    POKE(VIDEO_MEM_1_VAL, 0x00); // release RESET: co-processor starts at $200

    WAITKEY;

    POKE(VIDEO_MEM_1_LO, CPU_SPEED);
    POKE(VIDEO_MEM_1_VAL, 0x01);

    WAITKEY;

    POKE(VIDEO_MEM_1_LO, CPU_SPEED);
    POKE(VIDEO_MEM_1_VAL, 0x02);

    WAITKEY;

    POKE(VIDEO_MEM_1_LO, CPU_SPEED);
    POKE(VIDEO_MEM_1_VAL, 0x03);

    WAITKEY;

#ifdef DEBUG_COPROC
    for (reg=0x22;reg<=0x2a;reg++) {
       POKE(VIDEO_MEM_1_LO, reg);
       printf ("%0x %0x\n", reg, PEEK(VIDEO_MEM_1_VAL));
    }

    POKE(VIDEO_MEM_FLAGS, 0x0);
    POKE(VIDEO_MEM_1_HI, COPROC_PROG_HI);
    POKE(VIDEO_MEM_1_LO, COPROC_PROG_LO);
    for (reg=0x0;reg<=32;reg++) {
       POKE(VIDEO_MEM_1_LO, reg);
       printf ("%0x ", PEEK(VIDEO_MEM_1_VAL));
    }
    printf ("\n");
#endif

    HIRES_OFF();
}
