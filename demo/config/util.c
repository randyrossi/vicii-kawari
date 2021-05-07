#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"

int detected(void) {
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

