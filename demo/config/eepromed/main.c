#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "menu.h"

void main()
{
    if (enable_kawari()) {
       HIRES_OFF();    
       INIT_COLORS();

       main_menu();
    } else {
       printf ("kawari not detected");
    }
}
