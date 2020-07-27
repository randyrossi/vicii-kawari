#include <stdio.h>

#include "../test.h"
#include "../log.h"

static void init(Vtop* top) {
   top->V_ERST = 1;
   top->V_RASTERCMP = 1;
}

TEST_START(test3, "raster_irq_high_line_1_cycle_0");

// Tests irq goes high on cycle 0 for lines > 0
int test3_run(Vtop* top, int golden) {
   if (top->irq) {
      EXPECT("line", top->V_RASTER_LINE, 1);
      EXPECT("cycle_num", top->V_CYCLE_NUM, 0);
      EXPECT("cycle_bit", top->V_CYCLE_BIT, 0);
      return TEST_END;
   }
   return TEST_CONTINUE_CAPTURING;
}
