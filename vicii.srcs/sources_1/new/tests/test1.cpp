#include <stdio.h>

#include "../test.h"
#include "../log.h"

static FILE* fp;
static bool enabled;

TEST_START(test1, "cycles_no_sprites_no_badlines");

// Tests rasterline 1 has expected xpos and vicCycles
// when no sprites and no badlines active.
int test1_run(Vvicii* top, int golden) {
   if (is_about_to_start_line(top, 1)) {
      enabled = true;
   } else if (is_about_to_start_line(top, 2)) {
      enabled = false;
      return TEST_END;
   }

   if (enabled) {
      int cycle = -1;
      int xpos = -1;
      if (golden) {
         fprintf (fp, "%3x %d\n", top->V_XPOS, top->vicCycle);
      } else {
         fscanf (fp, "%3x %d\n", &xpos, &cycle);
	 EXPECT("vicCycle", top->vicCycle, cycle);
	 EXPECT("xpos", top->V_XPOS, xpos);
      }
      return TEST_CONTINUE_CAPTURING;
   }
   return TEST_CONTINUE_NOT_CAPTURING;
}
