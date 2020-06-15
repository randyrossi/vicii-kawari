#include <stdio.h>

#include "../test.h"
#include "../log.h"

static int state = 0;

static void init(Vvicii* top) {
   top->V_ERST = 1;
   top->V_RASTERCMP = 2;
}

TEST_START(test5, "raster_irq_set_again_next_line");

// set raster irq, get it, clear it, set it again on next line
int test5_run(Vvicii* top, int golden) {
   if (state == 0 && top->irq) {
      EXPECT("line", top->V_RASTER_LINE, 2);
      EXPECT("cycle_num", top->V_CYCLE_NUM, 0);
      EXPECT("cycle_bit", top->V_CYCLE_BIT, 0);
      state++;
   } else if (state == 1 && top->clk_phi) {
      EXPECT("irq", (top->irq&1), 1);
      top->V_IRST_CLR = 1;
      top->V_RASTERCMP = 3;
      state++;
   } else if (state >=2 && state < 8) {
      state++;
   } else if (state >= 8 && top->irq) {
      EXPECT("line", top->V_RASTER_LINE, 3);
      EXPECT("cycle_num", top->V_CYCLE_NUM, 0);
      EXPECT("cycle_bit", top->V_CYCLE_BIT, 0);
      return TEST_END;
   }
   return TEST_CONTINUE_CAPTURING;
}
