#include <stdio.h>

#include "../test.h"
#include "../log.h"

static int state = 0;
static bool saw_6 = false;

static void init(Vtop* top) {
   top->V_ERST = 1;
   top->V_RASTERCMP = 5;
}

TEST_START(test6, "raster_irq_once_per_line");

// should only get 1 irq per line
int test6_run(Vtop* top, int golden) {
   if (state == 0 && top->irq) {
      EXPECT("line", top->V_RASTER_LINE, 5);
      EXPECT("cycle_num", top->V_CYCLE_NUM, 0);
      EXPECT("cycle_bit", top->V_CYCLE_BIT, 0);
      state++;
   } else if (state == 1 && top->clk_phi) {
      EXPECT("irq", (top->irq&1), 1);
      top->V_IRST_CLR = 1;
      state++;
   } else if (state >=2 && state < 8) {
      state++;
   } else if (state >= 8) {
      if (top->irq && top->V_RASTER_LINE == 5) {
	 if (!saw_6) {
            EXPECT("one_irq_per_line",0,1);
	 } else
            return TEST_END;
      }
      // if we get to 5 and saw 6 we're on the next frame
      if (top->V_RASTER_LINE == 6)
	 saw_6 = true;
      if (state > 2000000) {
         EXPECT("too_long",1,0);
	 return TEST_FAIL;
      }
      state++;
   }
   return TEST_CONTINUE_NOT_CAPTURING; // too much data or log
}
