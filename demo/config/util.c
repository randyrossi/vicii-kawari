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
    int m1 = PEEK(53500L);
    int m2 = PEEK(53500L);
    int m3 = PEEK(53500L);
    int m4 = PEEK(53500L);

    return m1 == 86 && m2 == 73 && m3 == 67 && m4 == 50;
}
