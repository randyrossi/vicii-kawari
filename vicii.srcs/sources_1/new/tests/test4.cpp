#include <stdio.h>

#include "../test.h"
#include "../log.h"

static void init(Vvicii* top) {
   top->V_ERST = 1;
   top->V_RASTERCMP = 0;
}

TEST_START(test4, "raster_irq_high_line_0_cycle_1");

// Tests irq goes high on cycle 1 for line = 0
int test4_run(Vvicii* top, int golden) {
   if (top->irq) {
      EXPECT("line", top->V_RASTER_LINE, 0);
      EXPECT("cycle_num", top->V_CYCLE_NUM, 1);
      EXPECT("bit_cycle", top->V_BIT_CYCLE, 0);
      return TEST_END;
   }
   return TEST_CONTINUE_CAPTURING;
}
