#include <6502.h>
#include <peekpoke.h>

#include "kawari.h"

void set_hires_mode(unsigned int mode) {
   POKE(53303L,PEEK(53303L) & ~(128+64+32));
   POKE(53303L,PEEK(53303L) | (mode << 5));
}

