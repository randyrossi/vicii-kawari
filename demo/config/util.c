#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"

int enable_kawari(void) {
    POKE(53311L,86);
    POKE(53311L,73);
    POKE(53311L,67);
    POKE(53311L,50);
    POKE(53311L,0);
    // Zero out IDX regs
    POKE(53301L,0);
    POKE(53302L,0);
    return PEEK(53311L) == 0;
}

int have_magic(void) {
    int m1,m2,m3,m4;

    POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_REGS_BIT);

    POKE(53305L,0xfc);
    m1 = PEEK(53307L);
    POKE(53305L,0xfd);
    m2 = PEEK(53307L);
    POKE(53305L,0xfe);
    m3 = PEEK(53307L);
    POKE(53305L,0xff);
    m4 = PEEK(53307L);

    return m1 == 86 && m2 == 73 && m3 == 67 && m4 == 50;
}

// Poll persist busy bit and don't perform poke
// until it is 0
void safe_poke(long addr, char value)
{
    while (PEEK(53311L) & 16) { }
    POKE(addr,value);
}
