#include <stdio.h>

#include "../test.h"
#include "../log.h"

static int high_cycle = -1;
static int high_line = -1;
static int low_cycle = -1;
static int low_line = -1;

static void init(Vvicii* top) {
	top->V_DEN = 1;
	top->V_ALLOW_BAD_LINES = 0;
}

TEST_START(test8, "raster_enable_30_F8");

// makes sure raster_enable rises on 0x30 and falls 0xf8
// when den is 1
int test8_run(Vvicii* top, int golden) {
   if (top->V_ALLOW_BAD_LINES & 1) {
	   if (high_cycle < 0) {
		   high_cycle = top->V_CYCLE_NUM;
		   high_line = top->V_RASTER_LINE;
	   }
   }
   if (high_cycle >=0 && !(top->V_ALLOW_BAD_LINES & 1)) {
	// If we were high once and now not...
	if (low_cycle < 0) {
	       low_cycle = top->V_CYCLE_NUM;
	       low_line = top->V_RASTER_LINE;
	       EXPECT("raster_enable rise line 0x30", high_line, 0x30);
	       EXPECT("raster_enable rise cycle 0", high_cycle, 0);
	       EXPECT("raster_enable fall line 0xF8", low_line, 0xF8);
	       EXPECT("raster_enable fall cycle 0", low_cycle, 0);
	       return TEST_END;
	}
   }

   return TEST_CONTINUE_NOT_CAPTURING;
}
