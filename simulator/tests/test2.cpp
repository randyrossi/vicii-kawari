#include <stdio.h>

#include "../test.h"
#include "../log.h"

static FILE* fp;
static bool enabled;

static void init(Vvicii*) {}
TEST_START_WITH_GOLDEN(test2, "cycles_all_sprites_no_badlines");

// Tests rasterline 1 has expected xpos and vicCycles
// when all sprites active and no badlines active.
int test2_run(Vvicii* top, int golden) {
   if (is_about_to_start_line(top, 1)) {
      top->V_DMAEN = 1;
      enabled = true;
   } else if (is_about_to_start_line(top, 2)) {
      enabled = false;
      return TEST_END;
   }

   if (enabled) {
      int cycle = -1;
      if (golden) {
         fprintf (fp, "%d\n", top->V_VIC_CYCLE);
      } else {
         fscanf (fp, "%d\n", &cycle);
	 EXPECT("vicCycle", top->V_VIC_CYCLE, cycle);
      }
      return TEST_CONTINUE_CAPTURING;
   }
   return TEST_CONTINUE_NOT_CAPTURING;
}
