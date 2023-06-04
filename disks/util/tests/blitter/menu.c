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

    HIRES_ON();

    RUN_TEST(test_160x200x16_blit);
    RUN_TEST(test_320x200x16_blit);
    RUN_TEST(test_640x200x4_blit);
    RUN_TEST(test_blit_irq);
    RUN_TEST(test_blit_op);

    HIRES_OFF();
}
