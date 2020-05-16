#include <stdio.h>

#include "../test.h"
#include "../log.h"

static void init(Vvicii* top) {
   top->V_ERST = 1;
   top->V_RASTERCMP = 1;
}

TEST_START(test3, "raster_irq_high_line_1_cycle_0");

// Tests irq goes high on cycle 0 for lines > 0
int test3_run(Vvicii* top, int golden) {
   if (top->irq) {
      EXPECT("cycle_num", top->V_CYCLE_NUM, 0);
      EXPECT("bit_cycle", top->V_BIT_CYCLE, 0);
      return TEST_END;
   }
   return TEST_CONTINUE_CAPTURING;
}
