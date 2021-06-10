#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "init.h"
#include "menu.h"

void main()
{
    if (enable_kawari()) {
       HIRES_OFF();    
       INIT_COLORS();

       while (1) {
          if (have_magic())
             main_menu();
          else
             if (!first_init())
                break;
       }
    } else {
       printf ("kawari not detected");
    }
}
