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
