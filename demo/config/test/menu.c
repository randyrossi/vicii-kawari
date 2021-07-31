#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "init.h"

#include "tests.h"

void main_menu(void)
{
    CLRSCRN;
    printf ("VIC-II Kawari Test Suite\n\n");
    RUN_TEST(auto_inc_vmem_a_16);
    RUN_TEST(auto_inc_vmem_a_wrap);
    RUN_TEST(auto_inc_vmem_b_16);
    RUN_TEST(auto_inc_vmem_b_wrap);
    RUN_TEST(auto_dec_vmem_a_16);
    RUN_TEST(auto_dec_vmem_a_wrap);
    RUN_TEST(auto_dec_vmem_b_16);
    RUN_TEST(auto_dec_vmem_b_wrap);
    RUN_TEST(noop_vmem_a);
    RUN_TEST(noop_vmem_b);
    RUN_TEST(vmem_a);
    RUN_TEST(vmem_b);
    RUN_TEST(vmem_idx_a);
    RUN_TEST(vmem_idx_b);
    RUN_TEST1(vmem_copy, 1);
    RUN_TEST1(vmem_copy, 2);
    RUN_TEST(vmem_copy_overlap);
    RUN_TEST(vmem_fill);
}
