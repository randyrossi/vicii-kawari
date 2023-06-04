#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "init.h"

#include "tests.h"
#include "macros.h"

void main_menu(void)
{
    CLRSCRN;
    printf ("VIC-II Kawari Test Suite\n\n");
    RUN_TEST(dma);
}
