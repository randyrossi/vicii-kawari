#include <stdio.h>

#include "../test.h"
#include "../log.h"

static FILE* fp;
static bool enabled;

TEST_START(test2, "cycles_all_sprites_no_badlines");

int test2_post(Vvicii* top, int golden) {
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
         fprintf (fp, "%d\n", top->vicCycle);
      } else {
         fscanf (fp, "%d\n", &cycle);
         if (top->vicCycle != cycle) {
            LOG(LOG_ERROR,"Expected vicCycle=%d but got %d\n", cycle, top->vicCycle);
            return TEST_FAIL;
         }
      }
      return TEST_CONTINUE_CAPTURING;
   }
   return TEST_CONTINUE_NOT_CAPTURING;
}
