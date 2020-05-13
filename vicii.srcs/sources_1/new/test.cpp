#include <stdio.h>

#include "log.h"
#include "test.h"
#include "tests/test1.h"

typedef int (*test_func)(Vvicii*, int);

static int tickCount;

test_func test_start[] = {
   test1_start,
};

test_func test_pre[] = {
   test1_pre,
};

test_func test_post[] = {
   test1_post,
};

test_func test_end[] = {
   test1_end,
};

int do_test_start(int driver, Vvicii* top, int golden) {
   return test_start[driver-1](top, golden);
}

int do_test_pre(int driver, Vvicii* top, int golden) {
   if (top->clk_dot4x)
      return test_pre[driver-1](top, golden);
   return TEST_OK;
}

int do_test_post(int driver, Vvicii* top, int golden) {
   if (top->clk_dot4x)
      return test_post[driver-1](top, golden);
   return TEST_OK;
}

int do_test_end(int driver, Vvicii* top, int golden) {
   if (top->clk_dot4x)
      return test_end[driver-1](top, golden);
   return TEST_OK;
}

FILE* do_start_file(const char* name, int golden) {
   FILE* fp;
   if (golden) {
      fp = fopen(name,"w");
      if (!fp) LOG(LOG_ERROR,"Can't open goden for write"); 
   } else {
      fp = fopen(name,"r");
      if (!fp) LOG(LOG_ERROR,"Can't open golden data");
   }
   return fp;
}

// Canned end tester for capturing one whole frame
int do_frame_end(Vvicii* top, int golden) {
     if (top->V_BIT_CYCLE == 0 &&
            top->V_RASTER_X == 0 &&
               top->V_RASTER_LINE == 0 &&
                  top->V_PPS & 1)
         return TEST_END;
     
   return TEST_OK;
}
