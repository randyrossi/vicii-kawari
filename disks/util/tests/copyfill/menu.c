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
    RUN_TEST1(vmem_copy, 1);
    RUN_TEST1(vmem_copy, 2);
    RUN_TEST(vmem_copy_overlap);
    RUN_TEST(vmem_fill);
    if (is_version_min(1,16)) {
       RUN_TEST(test_copy_irq);
       RUN_TEST(test_fill_irq);
       RUN_TEST(test_copy_overlay);
    }
}
