#include <stdio.h>

#include "../test.h"
#include "../log.h"

static bool first_entry = true;
static int phi;
static int phic;
static int num_checks;

static void init(Vvicii* top) {
}

TEST_START(test7, "cas_ras_mux");

// makes sure cas/ras start at expected values
int test7_run(Vvicii* top, int golden) {
   int cmp;
   if (first_entry) {
       phi = top->clk_phi;
       phic = -1;
       first_entry = false;
       return TEST_CONTINUE_NOT_CAPTURING;
   }
   if (top->clk_phi != phi && top->V_XPOS % 4 == 0) {
      phi = top->clk_phi;
      phic = 0;
   }
   if (phic == 0) {
         switch (top->V_VIC_CYCLE) {
	      case VIC_LPI2:
	      case VIC_LI:
		      EXPECTSTR("ras",toBin(16, top->V_RASR),"1111111111111111");
		      EXPECTSTR("cas",toBin(16, top->V_CASR),"1111111111111111");
		      break;
	      default:
		      EXPECTSTR("ras",toBin(16, top->V_RASR),"1111100000000000");
		      EXPECTSTR("cas",toBin(16, top->V_CASR),"1111111000000000");
		      break;
         }
       num_checks++;
       // Check about 1 frame's worth of phi changes
       if (num_checks == 65*2*311) return TEST_END;
       phic++;
    }

   return TEST_CONTINUE_NOT_CAPTURING;
}
