#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

#include "tests.h"
#include "macros.h"

// NOTE: The split and legacy tests poke the 40 column screen at
// column 37 on rows 3 and 16. Keep the text printed here short enough
// to stay clear of that column.
void main_menu(void)
{
    int res;

    CLRSCRN;
    printf ("Kawari Hires Sprite Collision Tests\n\n");

    RUN_TEST(text_pos);
    RUN_TEST(text_neg);
    RUN_TEST(text_attr);
    RUN_TEST(cell_pos_neg);
    RUN_TEST(cell_halfpix);
    RUN_TEST(c4_halfpix);
    RUN_TEST(c16_320_key);
    RUN_TEST(c16_160_key);
    RUN_TEST(c4_key);
    RUN_TEST(border_neg);
    RUN_TEST(spr_bits);
    RUN_TEST(irq_once);
    RUN_TEST(split);
    RUN_TEST(legacy);
}
