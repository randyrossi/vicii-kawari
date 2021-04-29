#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "menu.h"

int detected(void);

void main()
{
    if (detected()) {
       HIRES_OFF();    
       INIT_COLORS();
       main_menu();
    } else {
       printf ("kawari not detected");
    }
}

int detected(void) {
    POKE(53301L,0);
    POKE(53302L,0);
    POKE(53305L,0);
    POKE(53306L,0);
    POKE(53311L,86);
    POKE(53311L,73);
    POKE(53311L,67);
    POKE(53311L,50);
    POKE(53311L,0);
    return PEEK(53311L) == 0;
}
